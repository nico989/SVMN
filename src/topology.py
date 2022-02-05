#!/usr/bin/env python3

import argparse
import os
from logger import logger
from topology import topologyBuilder, topologyParser
from mininet import cli
from comnetsemu.net import VNFManager


def fileFormat(file: str) -> topologyParser.Format:
    _, file_extension = os.path.splitext(file)
    if file_extension == ".yaml" or file_extension == ".yml":
        return topologyParser.Format.YAML
    elif file_extension == "json":
        return topologyParser.Format.JSON
    else:
        raise ValueError(f"Unknown file extension {file_extension}")


def getTopology(file: str) -> topologyBuilder.Topology:
    topology = None
    format = fileFormat(file)

    with open(file) as f:
        topology = f.read()

    return topologyParser.parseTopology(topology, format)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Topology builder",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=40),
    )
    parser.add_argument(
        "-f", "--file", help="Topology file", required=True, action="store", type=str
    )
    args = parser.parse_args()

    logger.info(f"Analyzing topology {args.file}")
    topology = getTopology(args.file)
    network = topologyBuilder.buildTopology(topology)

    mgr = VNFManager(network)
    network.start()
    cli.CLI(network)
    network.stop()