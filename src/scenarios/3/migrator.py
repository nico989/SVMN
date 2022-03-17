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
    # Mode
    mode = int(body["mode"])
    # Switch dpid
    dpid = int(body["dpid"])
    # In port
    in_port = int(body["in_port"])
    # Out port
    out_port = int(body["out_port"])

    # Notify callback
    if cb:
        cb(mode, dpid, in_port, out_port)

    return ("", 200)


def start(port: int, callback):
    global cb
    cb = callback
    app.run(port=port)
