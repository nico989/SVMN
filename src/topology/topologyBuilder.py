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


def buildHosts(network: Containernet, topology: Topology) -> None:
    for host in topology.hosts:
        docker_args = {"hostname": host.name, "pid_mode": "host"}
        params = {
            "ip": host.ip.with_prefixlen,
            "dimage": host.image,
            "docker_args": docker_args,
        }

        network.addDockerHost(host.name, **params)


def buildSwitches(network: Containernet, topology: Topology) -> None:
    for switch in topology.switches:
        switchParams = {}

        network.addSwitch(switch.name, **switchParams)

        for link in switch.links:
            linkParams = {}
            if link.bandwidth:
                linkParams["bw"] = link.bandwidth
            if link.delay:
                linkParams["delay"] = link.delay

            network.addLink(switch.name, link.node, **linkParams)


def buildTopology(topology: Topology) -> Containernet:
    network = Containernet(
        switch=node.OVSKernelSwitch,
        autoSetMacs=True,
        autoStaticArp=True,
        link=mnlink.TCLink,
        xterms=False,
    )

    buildControllers(network, topology)
    buildHosts(network, topology)
    # Always last due to addLink
    buildSwitches(network, topology)

    return network
