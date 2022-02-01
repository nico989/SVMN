#!/usr/bin/env python3

from mininet import log, link, node

from comnetsemu.net import Containernet


def main():
    # Log level
    log.setLogLevel("info")

    # Network environment
    net = Containernet(controller=node.Controller, link=link.TCLink, xterms=False)

    # === Hosts
    log.info("=== Hosts ===\n")

    # Default Controller
    log.info("Controller 0\n")
    net.addController("controller0")

    # Client
    log.info("Client 0\n")
    client0 = net.addDockerHost(
        "client0",
        dimage="dev_test",
        ip="192.168.0.9/24",
        docker_args={"hostname": "client0", "pid_mode": "host"},
    )

    # Main server
    log.info("Server 0\n")
    server0 = net.addDockerHost(
        "server0",
        dimage="dev_test",
        ip="192.168.0.10/24",
        docker_args={"hostname": "server0", "pid_mode": "host"},
    )

    # Backup server
    log.info("Server 1\n")
    server1 = net.addDockerHost(
        "server1",
        dimage="dev_test",
        ip="192.168.0.10/24",
        docker_args={"hostname": "server1", "pid_mode": "host"},
    )

    # === Networking
    log.info("=== Networking ===\n")

    # Switch
    log.info("Switch 0\n")
    switch0 = net.addSwitch("switch0")
    # Service traffic
    net.addLinkNamedIfce(switch0, client0, bw=1000, delay="5ms")
    net.addLinkNamedIfce(switch0, server0, bw=1000, delay="5ms")
    net.addLinkNamedIfce(switch0, server1, bw=1000, delay="5ms")
    # Internal traffic
    net.addLink(switch0, server0, bw=1000, delay="1ms")
    net.addLink(switch0, server1, bw=1000, delay="1ms")

    # === Start network
    log.info("=== Start network ===\n")
    net.start()


if __name__ == "__main__":
    main()
