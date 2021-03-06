from typing import Dict, Tuple, Union
from comnetsemu.node import DockerHost
from comnetsemu.net import Containernet, VNFManager
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
        params = {"protocols": "OpenFlow10", "dpid": "%016x" % (index + 1)}

        network.addSwitch(switch.name, **params)


def buildHosts(network: Containernet, topology: Topology) -> Dict[DockerHost, Host]:
    hostInstances: Dict[DockerHost, Host] = {}

    for host in topology.hosts:
        logger.info(f"Host {host.name}: {to_json(host)}")
        docker_args = {"hostname": host.name, "pid_mode": "host"}
        params = {
            "ip": host.ip.with_prefixlen,
            "dimage": host.image if host.image else "dev_host:latest",
            "inNamespace": True,
            "docker_args": docker_args,
        }

        if host.mac:
            params["mac"] = host.mac

        instance = network.addDockerHost(host.name, **params)

        # Add instance
        hostInstances[instance] = host

    return hostInstances


def buildNetworkLinks(network: Containernet, topology: Topology) -> None:
    for switch in topology.switches:
        logger.info(f"Switch {switch.name}:")

        for link in switch.links:
            logger.info(f" {to_json(link)}")
            params = {}

            if link.bandwidth:
                params["bw"] = link.bandwidth
            if link.delay:
                params["delay"] = link.delay
            if link.fromInterface and link.toInterface:
                params["intfName1"] = link.fromInterface
                params["intfName2"] = link.toInterface

            network.addLink(switch.name, link.node, **params)


def buildNetworkInterfaces(hostInstances: Dict[DockerHost, Host]) -> None:
    for instance, host in hostInstances.items():
        logger.info(f"Host {host.name}:")

        for interface in host.interfaces:
            logger.info(f" {to_json(interface)}")

            instance.cmd(f"ip addr add {interface.ip} dev {interface.name}")
            if interface.mac:
                instance.cmd(f"macchanger -m {interface.mac} {interface.name}")


def buildContainers(manager: VNFManager, topology: Topology) -> None:
    for host in topology.hosts:
        logger.info(f"Host {host.name}:")

        for container in host.containers:
            logger.info(f" {to_json(container)}")

            manager.addContainer(
                name=container.name,
                dhost=host.name,
                dimage=container.image,
                dcmd=container.cmd if container.cmd else "",
                wait=container.wait if container.wait else False,
            )


def buildTopology(topology: Topology) -> Tuple[Containernet, VNFManager]:
    logger.info("=== NETWORK ===")
    logger.info(f"Network: {to_json(topology.network)}")
    network = Containernet(
        switch=node.OVSKernelSwitch,
        autoSetMacs=topology.network.autoMac,
        autoStaticArp=topology.network.autoArp,
        link=mnlink.TCLink,
    )

    logger.info("=== CONTROLLERS ===")
    buildControllers(network, topology)
    logger.info("=== SWITCHES ===")
    buildSwitches(network, topology)
    logger.info("=== HOSTS ===")
    hostInstances = buildHosts(network, topology)

    logger.info("=== NETWORK LINKS ===")
    buildNetworkLinks(network, topology)
    logger.info("=== NETWORK INTERFACES ===")
    buildNetworkInterfaces(hostInstances)

    # Manager
    manager = VNFManager(network)

    logger.info("=== CONTAINERS ===")
    buildContainers(manager, topology)

    return (network, manager)


def cleanTopology(
    topology: Topology, network: Containernet, manager: VNFManager
) -> None:
    logger.info("=== CLEANING ===")
    # Container
    for host in topology.hosts:
        for container in host.containers:
            logger.info(f"Container: {container.name}")
            manager.removeContainer(container.name, True)
    # Stop network
    network.stop()
    manager.stop()
