from ryu.base import app_manager
from ryu.controller import ofp_event
from ryu.topology import event
from ryu.controller.handler import MAIN_DISPATCHER, CONFIG_DISPATCHER, DEAD_DISPATCHER
from ryu.controller.handler import set_ev_cls
from ryu.ofproto import ofproto_v1_0
from ryu.lib.packet import packet
from ryu.lib.packet import ethernet
from ryu.lib.packet import ether_types
from ryu import cfg
import migrator
import threading


class Controller(app_manager.RyuApp):
    OFP_VERSIONS = [ofproto_v1_0.OFP_VERSION]

    def __init__(self, *args, **kwargs):
        super(Controller, self).__init__(*args, **kwargs)
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
        migrator.start(port, self.migration_cb)

    def migration_cb(self, dpid: int, mac: str, port: int):
        self.mac_to_port[dpid][mac] = port

    @set_ev_cls(ofp_event.EventOFPSwitchFeatures, CONFIG_DISPATCHER)
    def _switch_features_handler(self, ev):
        msg = ev.msg

        s = f"OFPSwitchFeatures: {{ dpid: {msg.datapath_id}, buffers: {msg.n_buffers}, tables: {msg.n_tables}, capabilities: {msg.capabilities}, ports: ["
        for index, port in enumerate(msg.ports.values()):
            s += f"{{ port: {port.port_no}, name: {port.name.decode('UTF-8')}, hw_addr: {port.hw_addr} }}"
            if index != len(msg.ports) - 1:
                s += ", "
        s += f"] }}"

        self.logger.info(s)

    @set_ev_cls(event.EventSwitchEnter)
    def _switch_enter_handler(self, ev):
        self.logger.info(f"SwitchEnter: {{ dpid: {ev.switch.dp.id} }}")

    @set_ev_cls(
        event.EventSwitchLeave, [MAIN_DISPATCHER, CONFIG_DISPATCHER, DEAD_DISPATCHER]
    )
    def _switch_leave_handler(self, ev):
        self.logger.info(f"SwitchLeave: {{ dpid: {ev.switch.dp.id} }}")

    @set_ev_cls(ofp_event.EventOFPPacketIn, MAIN_DISPATCHER)
    def _packet_in_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto
        parser = datapath.ofproto_parser
        in_port = msg.in_port

        pkt = packet.Packet(msg.data)
        eth = pkt.get_protocols(ethernet.ethernet)[0]

        # Ignore LLDP packet
        if eth.ethertype == ether_types.ETH_TYPE_LLDP:
            return

        src = eth.src
        dst = eth.dst
        dpid = datapath.id

        self.logger.info(
            f"OFPPacketIn: {{ dpid: {dpid}, src: {src}, dst: {dst}, in_port: {in_port} }}"
        )
        if msg.msg_len < msg.total_len:
            self.logger.warn(
                f"OFPPacketIn packet truncated: {{ dpid: {dpid}, msg_len: {msg.msg_len}, total_len: {msg.total_len} }}"
            )

        # Learn mac address
        self.mac_to_port.setdefault(dpid, {})
        self.mac_to_port[dpid][src] = in_port

        # Find out_port
        if dst in self.mac_to_port[dpid]:
            out_port = self.mac_to_port[dpid][dst]
        else:
            out_port = ofproto.OFPP_FLOOD

        actions = [parser.OFPActionOutput(out_port)]

        data = None
        if msg.buffer_id == ofproto.OFP_NO_BUFFER:
            data = msg.data

        out = parser.OFPPacketOut(
            datapath=datapath,
            buffer_id=msg.buffer_id,
            in_port=in_port,
            actions=actions,
            data=data,
        )

        datapath.send_msg(out)

    @set_ev_cls(ofp_event.EventOFPPortStatus, MAIN_DISPATCHER)
    def _port_status_handler(self, ev):
        msg = ev.msg
        datapath = msg.datapath
        ofproto = datapath.ofproto

        if msg.reason == ofproto.OFPPR_ADD:
            reason = "ADD"
        elif msg.reason == ofproto.OFPPR_DELETE:
            reason = "DELETE"
        elif msg.reason == ofproto.OFPPR_MODIFY:
            reason = "MODIFY"
        else:
            reason = "UNKNOWN"

        self.logger.info(
            f"OFPPortStatus: {{ dpid: {datapath.id}, port: {msg.desc.port_no}, reason: {reason} }}"
        )
