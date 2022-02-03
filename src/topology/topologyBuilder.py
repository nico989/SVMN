from typing import Union
from topologyParser import ControllerLocal, ControllerRemote, Topology
from comnetsemu.net import Containernet
from mininet import node, link as mnlink


def controllerType(controller: Union[ControllerLocal, ControllerRemote]):
    if isinstance(controller, ControllerLocal):
        return node.Controller
    elif isinstance(controller, ControllerRemote):
        return node.RemoteController
    else:
        raise Exception(f"Unknown class instance {type(controller)}")


def buildControllers(network: Containernet, topology: Topology) -> None:
    for controller in topology.controllers:
        params = {}

        if isinstance(network.controller, ControllerRemote):
            params["ip"] = controller.ip
            params["port"] = controller.port

        network.addController(
            controller.name, controller=controllerType(controller), **params
        )


def buildSwitches(network: Containernet, topology: Topology) -> None:
    for switch in topology.switches:
        params = {}

        network.addSwitch(switch.name, **params)


def buildHosts(network: Containernet, topology: Topology) -> None:
    for host in topology.hosts:
        docker_args = {"hostname": host.name, "pid_mode": "host"}
        params = {
            "ip": host.ip.with_prefixlen,
            "dimage": host.image,
            "docker_args": docker_args,
        }

        if host.mac:
            params["mac"] = host.mac

        node = network.addDockerHost(host.name, **params)

        # Build links
        for link in host.links:
            params = {}

            if link.bandwidth:
                params["bw"] = link.bandwidth
            if link.delay:
                params["delay"] = link.delay
            if link.fromInterface and link.toInterface:
                params["intfName1"] = link.fromInterface
                params["intfName2"] = link.toInterface

            network.addLink(host.name, link.node, **params)

        # Build interfaces
        for interface in host.interfaces:
            node.cmd(f"ip addr add {interface.ip} dev {interface.name}")


def buildTopology(topology: Topology) -> Containernet:
    network = Containernet(
        switch=node.OVSKernelSwitch,
        autoSetMacs=True,
        autoStaticArp=True,
        link=mnlink.TCLink,
        xterms=False,
    )

    buildControllers(network, topology)
    buildSwitches(network, topology)
    # Always last!
    buildHosts(network, topology)

    return network
