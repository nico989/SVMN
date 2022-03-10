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


class MorphingSlices(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_0.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(MorphingSlices, self).__init__(*args, **kwargs)
        CONF = cfg.CONF
        CONF.register_opts(
            [
                cfg.IntOpt("port", default=None),
            ]
        )

        self.slice_to_port = {
            1: {1: 3, 2: 5, 3: 1, 4: 1, 5: 2, 6: 2},
        }
        if CONF.port:
            migrator_port = int(CONF.port)
            self.thread_migration = threading.Thread(
                target=self.thread_migration_cb,
                daemon=True,
                kwargs={"port": migrator_port},
            )
            self.thread_migration.start()

    def thread_migration_cb(self, port: int):
        migrator.start(port, mappings=self.slice_to_port)

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocol(ethernet.ethernet)

        # Ignore LLDP packet
        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return

        dst = eth.dst
        src = eth.src

        dpid = datapath.id

        self.logger.info(
            f"Packet in dpid {dpid}: {{ src: {src}, dst: {dst}, in_port: {msg.in_port} }}"
        )
        out_port = self.slice_to_port[dpid][msg.in_port]

        actions = [datapath.ofproto_parser.OFPActionOutput(out_port)]
        match = datapath.ofproto_parser.OFPMatch(in_port=msg.in_port)
        self.logger.info(
            f"Sending packet in dpid {dpid}: {{ src: {src}, dst: {dst}, in_port: {msg.in_port}, out_port: {out_port} }}"
        )

        self.add_flow(datapath, 2, match, actions)
        self._send_package(msg, datapath, msg.in_port, actions)

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

    def add_flow(self, datapath, priority, match, actions):
        # Construct flow mod
        mod = datapath.ofproto_parser.OFPFlowMod(
            datapath=datapath,
            match=match,
            cookie=0,
            command=datapath.ofproto.OFPFC_ADD,
            idle_timeout=20,
            hard_timeout=120,
            priority=priority,
            flags=datapath.ofproto.OFPFF_SEND_FLOW_REM,
            actions=actions,
        )
        # Send message
        datapath.send_msg(mod)

    def _send_package(self, msg, datapath, in_port, actions):
        data = None
        if msg.buffer_id == datapath.ofproto.OFP_NO_BUFFER:
            data = msg.data

        out = datapath.ofproto_parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=in_port,
            actions=actions,
            data=data,
        )
        datapath.send_msg(out)
