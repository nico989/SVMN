from flask import Flask, request, jsonify

# Flask app(s)
app = Flask(__name__)
# Mappings
mac_to_port = None


@app.route("/api/migrate", methods=["POST"])
def migrate():
    """
    Migrate service.
    """

    # Request body
    body = request.get_json(force=True)
    # Switch dpid
    dpid = int(body["dpid"])
    # Server mac
    mac = body["mac"]
    # Server port
    port = int(body["port"])

    # Redefine mappings
    if mac_to_port and mac_to_port[dpid] and mac_to_port[dpid][mac]:
        mac_to_port[dpid][mac] = port

    return ("", 200)


def start(port: int, mappings: dict):
    global mac_to_port
    mac_to_port = mappings
    app.run(port=port)
