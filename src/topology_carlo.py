#!/usr/bin/env python3

from distutils.command.build import build
from mininet import topo, net, node, link, cli

from comnetsemu.net import Containernet, VNFManager


if __name__ == "__main__":
    network = Containernet(
        switch=node.OVSKernelSwitch,
        autoSetMacs=True,
        autoStaticArp=True,
        link=link.TCLink,
        controller=node.Controller,
        xterms=False,
    )
    manager = VNFManager(network)

    network.addController("ctr0")

    network.addSwitch("sw0", **{"protocols": "OpenFlow10"})
    network.addDockerHost("c0", dimage="dev_test", docker_args={})
    network.addDockerHost("s0", dimage="dev_test", docker_args={})

    network.addLink("c0", "sw0")
    network.addLink("s0", "sw0")

    network.start()
    cli.CLI(network)
    network.stop()
