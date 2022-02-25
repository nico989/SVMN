#!/usr/bin/env python3

import requests, argparse, re
from flask import Flask, request, jsonify, g

# Flask app(s)
app = Flask(__name__)

# Counter
counter = 0
enable = False


@app.before_request
def before_request_func():
    global enable

    # Check URL admin request
    admin = re.search(r"\badmin\b", request.url)

    # Return 503 if disabled
    if not enable and not admin:
        return "Service Unavailable", 503


# APP
@app.route("/api/counter", methods=["GET"])
def get_counter():
    """
    Return counter.
    """

    global counter
    return jsonify(counter=counter)


@app.route("/api/counter", methods=["POST"])
def post_counter():
    """
    Increment and return counter.
    """

    global counter
    counter += 1
    return jsonify(counter=counter)


# APPMGR
@app.route("/api/admin/migrate", methods=["POST"])
def migrate():
    """
    Migrate service and return counter.
    """

    global counter, enable

    # Request body
    body = request.get_json(force=True)
    # Server
    server = body["server"]
    # Disable other server & obtain counter
    response = requests.post(f"{server}/api/admin/disable").json()
    # Set counter value
    counter = response["counter"]
    # Enable this server
    enable = True

    return jsonify(counter=counter)


@app.route("/api/admin/disable", methods=["POST"])
def disable():
    """
    Disable service.
    """

    global enable
    enable = False
    return jsonify(counter=counter)


if __name__ == "__main__":
    # Arguments
    parser = argparse.ArgumentParser(
        description="Flask server",
        formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=40),
    )
    parser.add_argument(
        "--host",
        help="Flask server host",
        required=True,
        action="store",
        type=str,
    )
    parser.add_argument(
        "--port",
        help="Flask server port",
        required=True,
        action="store",
        type=str,
    )
    parser.add_argument(
        "--enable",
        help="Enable Flask server",
        required=False,
        action="store_true",
        default=False,
    )
    args = parser.parse_args()

    enable = args.enable
    app.run(debug=True, host=args.host, port=args.port)
