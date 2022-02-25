from crypt import methods
import requests
from flask import Flask, request, jsonify

# Config
APP_HOST = "0.0.0.0"
APP_PORT = 8080

# Flask app(s)
app = Flask(__name__)

# Counter
counter = 0

# APP
@app.route("/api/counter", methods=["GET"])
def get_counter():
    """
    Return counter.
    """

    global counter
    return jsonify(counter)


@app.route("/api/counter", methods=["POST"])
def post_counter():
    """
    Increment and return counter.
    """

    global counter
    counter += 1
    return jsonify(counter)


# APPMGR
@app.route("/api/migrate", methods=["POST"])
def migrate():
    """
    Migrate service and return counter.
    """

    global counter

    # Request body
    body = request.get_json(force=True)
    # Server
    server = body.server
    # Obtain counter value
    response = requests.get(f"{server}/api/counter").json()
    # Set counter value
    counter = response.counter
    # Stop server
    requests.get(f"{server}/api/stop")

    return jsonify(counter)


@app.route("/api/stop")
def stop():
    return "OK"


if __name__ == "__main__":
    app.run(debug=True, host=APP_HOST, port=APP_PORT)
