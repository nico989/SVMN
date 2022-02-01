#!/usr/bin/env python3

from mininet import topo, net, node, link, cli


class Topology(topo.Topo):
    def __init__(self):
        super().__init__()

        self.addSwitch("sw0", **{"protocols": "OpenFlow10"})
        self.addHost("c0")
        self.addHost("s0")

        self.addLink("c0", "sw0")
        self.addLink("s0", "sw0")


if __name__ == "__main__":
    network = net.Mininet(
        topo=Topology(),
        switch=node.OVSKernelSwitch,
        autoSetMacs=True,
        autoStaticArp=True,
        link=link.TCLink,
        controller=node.Controller,
    )

    network.start()

    cli.CLI(network)

    network.stop()
