from flask import Flask, request, jsonify
import requests

app = Flask(__name__)
counter = 0


@app.route("/")
def index():
    global counter

    counter += 1
    return jsonify(counter)


@app.route("/api/counter")
def get_counter():
    global counter

    return jsonify(counter)


@app.route("/api/migrate", methods=["POST"])
def migrate():
    global counter

    body = request.get_json(force=True)
    response = requests.get(f"{body.server}/api/counter").json()
    counter = response.counter
    requests.get(f"{body.server}/api/stop")

    return jsonify(counter)


@app.route("/api/stop")
def stop():
    return "OK"


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=80)
