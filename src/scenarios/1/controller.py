from email.policy import default
from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.controller.handler import MAIN_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_0
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.lib.packet import ether_types
from ryu import cfg
import migrator
import threading


class SimpleSwitch(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_0.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(SimpleSwitch, self).__init__(*args, **kwargs)
        CONF = cfg.CONF
        CONF.register_opts(
            [
                cfg.IntOpt("port", default=None),
            ]
        )

        self.mac_to_port = {}
        if CONF.port:
            migrator_port = int(CONF.port)
            self.thread_migration = threading.Thread(
                target=self.thread_migration_cb,
                daemon=True,
                kwargs={"port": migrator_port},
            )
            self.thread_migration.start()

    def thread_migration_cb(self, port: int):
        migrator.start(port, mappings=self.mac_to_port)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)

        # Ignore LLDP packet
        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return

        dst = eth.dst
        src = eth.src

        dpid = datapath.id
        self.mac_to_port.setdefault(dpid, {})
        # Learn mac address
        self.mac_to_port[dpid][src] = msg.in_port

        self.logger.info(
            f"Packet in dpid {dpid}: {{ src: {src}, dst: {dst}, in_port: {msg.in_port} }}"
        )

        if dst in self.mac_to_port[dpid]:
            out_port = self.mac_to_port[dpid][dst]
        else:
            out_port = ofproto.OFPP_FLOOD

        actions = [datapath.ofproto_parser.OFPActionOutput(out_port)]

        data = None
        if msg.buffer_id == ofproto.OFP_NO_BUFFER:
            data = msg.data

        out = datapath.ofproto_parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=msg.in_port,
            actions=actions,
            data=data,
        )

        datapath.send_msg(out)

    @set_ev_cls(ofp_event.EventOFPPortStatus, MAIN_DISPATCHER)
    def _port_status_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        reason = msg.reason
        port_no = msg.desc.port_no
        ofproto = datapath.ofproto
        dpid = datapath.id

        if reason == ofproto.OFPPR_ADD:
            self.logger.info(f"Port added in dpid {dpid}: {port_no}")
        elif reason == ofproto.OFPPR_DELETE:
            self.logger.info(f"Port deleted in dpid {dpid}: {port_no}")
        elif reason == ofproto.OFPPR_MODIFY:
            self.logger.info(f"Port modified in dpid {dpid}: {port_no}")
        else:
            self.logger.warning(
                f"Illeagal port state in dpid {dpid}: {{ reason: {reason}, port_no: {port_no} }}"
            )
