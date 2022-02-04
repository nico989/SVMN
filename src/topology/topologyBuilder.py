from typing import Dict, Union
from comnetsemu.node import DockerHost
from comnetsemu.net import Containernet
from mininet import node, link as mnlink
from .topologyParser import ControllerLocal, ControllerRemote, Host, Topology
from logger import logger
from serde.json import to_json


def controllerType(controller: Union[ControllerLocal, ControllerRemote]):
    if isinstance(controller, ControllerLocal):
        return node.Controller
    elif isinstance(controller, ControllerRemote):
        return node.RemoteController
    else:
        raise Exception(f"Unknown class instance {type(controller)}")


def buildControllers(network: Containernet, topology: Topology) -> None:
    for controller in topology.controllers:
        logger.info(f"Controller {controller.name}: {to_json(controller)}")
        params = {}

        if isinstance(controller, ControllerRemote):
            params["ip"] = str(controller.ip)
            params["port"] = controller.port

        network.addController(
            controller.name, controller=controllerType(controller), **params
        )


def buildSwitches(network: Containernet, topology: Topology) -> None:
    for index, switch in enumerate(topology.switches):
        logger.info(f"Switch {switch.name}: {to_json(switch)}")
        switchParams = {"protocols": "OpenFlow10", "dpid": "%016x" % (index + 1)}

        network.addSwitch(switch.name, **switchParams)

        # Build links
        for link in switch.links:
            linkParams = {}

            if link.bandwidth:
                linkParams["bw"] = link.bandwidth
            if link.delay:
                linkParams["delay"] = link.delay
            if link.fromInterface and link.toInterface:
                linkParams["intfName1"] = link.fromInterface
                linkParams["intfName2"] = link.toInterface

            network.addLink(switch.name, link.node, **linkParams)


def buildHosts(network: Containernet, topology: Topology) -> Dict[DockerHost, Host]:
    hostInstances: Dict[DockerHost, Host] = {}

    for host in topology.hosts:
        logger.info(f"Host {host.name}: {to_json(host)}")
        docker_args = {"hostname": host.name, "pid_mode": "host"}
        params = {
            "ip": host.ip.with_prefixlen,
            "dimage": host.image,
            "inNamespace": True,
            "docker_args": docker_args,
        }

        if host.mac:
            params["mac"] = host.mac

        instance = network.addDockerHost(host.name, **params)

        # Add instance
        hostInstances[instance] = host

    return hostInstances


def buildHostsNetworkInterfaces(hostInstances: Dict[DockerHost, Host]) -> None:
    for instance, host in hostInstances.items():
        for interface in host.interfaces:
            instance.cmd(f"ip addr add {interface.ip} dev {interface.name}")


def buildTopology(topology: Topology) -> Containernet:
    network = Containernet(
        switch=node.OVSKernelSwitch,
        autoSetMacs=True,
        autoStaticArp=False,
        build=False,
        link=mnlink.TCLink,
        xterms=False,
    )

    logger.info("=== CONTROLLERS ===")
    buildControllers(network, topology)
    logger.info("=== HOSTS ===")
    hostInstances = buildHosts(network, topology)
    logger.info("=== SWITCHES ===")
    buildSwitches(network, topology)
    buildHostsNetworkInterfaces(hostInstances)

    return network
