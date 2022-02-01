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
    c0 = net.addDockerHost(
        "c0",
        dimage="dev_test",
        ip="192.168.0.9/24",
        docker_args={"hostname": "c0", "pid_mode": "host"},
    )

    # Main server
    log.info("Server 0\n")
    s0 = net.addDockerHost(
        "s0",
        dimage="dev_test",
        ip="192.168.0.10/24",
        docker_args={"hostname": "s0", "pid_mode": "host"},
    )

    # Backup server
    log.info("Server 1\n")
    s1 = net.addDockerHost(
        "s1",
        dimage="dev_test",
        ip="192.168.0.10/24",
        docker_args={"hostname": "s1", "pid_mode": "host"},
    )

    # === Networking
    log.info("=== Networking ===\n")

    # Switch
    log.info("Switch 0\n")
    sw0 = net.addSwitch("sw0")
    # Service traffic
    net.addLinkNamedIfce
    net.addLink(
        sw0,
        c0,
        intfName1="sw0-c0",
        intfName2="c0-sw0",
        bw=1000,
        delay="5ms",
    )
    net.addLink(
        sw0,
        s0,
        intfName1="sw0-s0",
        intfName2="s0-sw0",
        bw=1000,
        delay="5ms",
    )
    net.addLink(
        sw0,
        s1,
        intfName1="sw0-s1",
        intfName2="s1-sw0",
        bw=1000,
        delay="5ms",
    )
    # Internal traffic
    net.addLink(
        sw0,
        s0,
        intfName1="sw0-s0-int",
        intfName2="s0-sw0-int",
        bw=1000,
        delay="1ms",
    )
    net.addLink(
        sw0,
        s1,
        intfName1="sw0-s1-int",
        intfName2="s1-sw0-int",
        bw=1000,
        delay="1ms",
    )

    # === Start network
    log.info("=== Start network ===\n")
    net.start()


if __name__ == "__main__":
    main()
