#!/usr/bin/env python3

import argparse
import os
from topologyBuilder import buildTopology
from topologyParser import Format, Topology, parseTopology
from mininet import cli
from comnetsemu.net import VNFManager


def fileFormat(file: str) -> Format:
    _, file_extension = os.path.splitext(file)
    if file_extension == ".yaml" or file_extension == ".yml":
        return Format.YAML
    elif file_extension == "json":
        return Format.JSON
    else:
        raise ValueError(f"Unknown file extension {file_extension}")


def getTopology(file: str) -> Topology:
    topology = None
    format = fileFormat(args.file)

    with open(args.file) as file:
        topology = file.read()

    return parseTopology(topology, format)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Topology builder",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=40),
    )
    parser.add_argument(
        "-f", "--file", help="Topology file", required=True, action="store", type=str
    )
    args = parser.parse_args()

    topology = getTopology(args.file)
    network = buildTopology(topology)

    mgr = VNFManager(network)
    network.start()
    cli.CLI(network)
    network.stop()
