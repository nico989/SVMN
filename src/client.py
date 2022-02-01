#!/usr/bin/env python3

import socket
import time
import argparse


def runClient(ip, port, timeout):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    data = b"Show me the counter, please!"
    while True:
        sock.sendto(data, (ip, port))
        counter, _ = sock.recvfrom(1024)
        print("Current counter: {}".format(counter.decode("utf-8")))
        time.sleep(timeout)


def main():
    parser = argparse.ArgumentParser(
        description="Simple client pinging server",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=40),
    )
    parser.add_argument(
        "-i", "--ip", help="Server IP", required=True, action="store", type=str
    )
    parser.add_argument(
        "-p",
        "--port",
        help="Server Port",
        required=True,
        action="store",
        type=int,
    )
    parser.add_argument(
        "-t",
        "--timeout",
        help="Interval time to send data",
        required=True,
        action="store",
        type=int,
    )
    args = parser.parse_args()
    runClient(args.ip, args.port, args.timeout)


if __name__ == "__main__":
    main()
