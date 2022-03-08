#!/usr/bin/env python3

import subprocess
import argparse
from flask import Flask, request, jsonify

# Flask app(s)
app = Flask(__name__)


@app.route("/api/migrate", methods=["POST"])
def migrate():
    """
    Migrate service via Docker.
    """

    # Request body
    body = request.get_json(force=True)
    # From server
    from_server = body["from"]
    # To server
    to_server = body["to"]

    # Call Docker
    subprocess.call(
        f'docker exec m0 curl -X POST -H "Content-Type:application/json" -d \'{{ "server": "http://{from_server}" }}\' {to_server}/api/admin/migrate',
        shell=True,
    )

    return ("", 200)


if __name__ == "__main__":
    # Arguments
    parser = argparse.ArgumentParser(
        description="Docker migration",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=40),
    )
    parser.add_argument(
        "--port",
        help="Listening port",
        required=True,
        action="store",
        type=int,
    )

    args = parser.parse_args()
    app.run(debug=True, port=args.port)
