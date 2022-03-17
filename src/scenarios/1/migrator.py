from flask import Flask, request

# Flask app(s)
app = Flask(__name__)
# Callback
cb = None


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

    # Notify callback
    if cb:
        cb(dpid, mac, port)

    return ("", 200)


def start(port: int, callback):
    global cb
    cb = callback
    app.run(port=port)
