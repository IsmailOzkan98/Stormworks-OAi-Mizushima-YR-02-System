from flask import Flask, render_template, jsonify, request
from datetime import datetime
from threading import Lock
import time
import json
import os

app = Flask(__name__)

import json
import os

CONFIG_FILE = "/app/recorder_config.json"

def load_recorder_config():
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as file:
            return json.load(file)
    except Exception as e:
        app.logger.error(f"Error loading recorder config: {e}")
        return {"fields": {}}

recorder_config = load_recorder_config()

# ==========================================
# FLIGHT DATA RECORDER
# ==========================================

LOG_DIR = "/app/logs"
os.makedirs(LOG_DIR, exist_ok=True)

recording_lock = Lock()

recording = False
recording_file = None
recording_filename = None


def start_recording():

    global recording
    global recording_file
    global recording_filename

    with recording_lock:

        if recording:
            return False, "Already recording"

        recording_filename = os.path.join(
            LOG_DIR,
            f"flight_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        )

        recording_file = open(
            recording_filename,
            "w",
            encoding="utf-8"
        )

        # JSON array
        recording_file.write("[\n")
        recording_file.flush()

        recording = True

        return True, recording_filename


def stop_recording():

    global recording
    global recording_file
    global recording_filename

    with recording_lock:

        if not recording:
            return False, "Not recording"

        recording_file.write("\n]\n")
        recording_file.flush()
        recording_file.close()

        filename = recording_filename

        recording = False
        recording_file = None
        recording_filename = None

        return True, filename


def save_flight_event(data):

    with recording_lock:

        if not recording or recording_file is None:
            return

        # Leer los campos permitidos en el CFG
        fields = recorder_config.get("fields", {})
        

        # Filtrar la telemetría
        filtered_data = {
            key: value
            for key, value in data.items()
            if fields.get(key, False)
        }

        event = {
            "recorded_at": datetime.now().astimezone().isoformat(
                timespec="milliseconds"
            ),
            "telemetry": filtered_data
        }

        line = json.dumps(
            event,
            ensure_ascii=False
        )

        if recording_file.tell() > 2:
            recording_file.write(",\n")

        recording_file.write(line)
        recording_file.flush()

# ==========================================
# OAI MIZUSHIMA YR-02 - TELEMETRY SERVER
# ==========================================

telemetry_lock = Lock()

telemetry = {
    "stage": "WAITING",
    "state": 0,
    "status": "IDLE",
    "timer": 0,

    "alt": 0,
    "alt_target": 0,
    "alt_error": 0,

    "vs": 0,
    "vs_target": 0,
    "vs_error": 0,

    "rps": 0,
    "rps_target": 0,

    "roll": 0,
    "pitch": 0,

    "ap": 0,
    "ap_distance": 0,
    "yaw": 0,

    "my_x": 0,
    "my_y": 0,
    "target_x": 0,
    "target_y": 0,

    "main": 0,
    "alt_hold": 0,
    "roll_stab": 0,
    "accel": 0,
    "descent": 0,

    "north": 0,
    "east": 0,
    "south": 0,
    "west": 0,

    "afterburner": 0,

    "spoiler": 0,

    "absolute_speed": 0,

    "rx_tx_state": 0,
    "rx_tx_frequency_tx": 0,
    "rx_tx_frequency_rx": 0,

    "timestamp": 0
}

# ==========================================
# DASHBOARD
# ==========================================

@app.route("/")
def home():
    return render_template("index.html")


# ==========================================
# RECEIVE STORMWORKS TELEMETRY
# ==========================================

@app.route("/telemetry", methods=["GET"])
def receive_telemetry():

    global telemetry

    received = request.args.to_dict()

    if not received:
        return "No telemetry data", 400

    try:
        with telemetry_lock:

            # Convertir valores numéricos
            for key, value in received.items():

                if key in telemetry and key != "stage" and key != "status":
                    try:
                        telemetry[key] = float(value)
                    except (ValueError, TypeError):
                        continue

                elif key in ("stage", "status"):
                    telemetry[key] = value

            telemetry["timestamp"] = time.time()
            recording_snapshot = telemetry.copy()

        save_flight_event(recording_snapshot)

        return "OK", 200

    except Exception as error:
        app.logger.exception("Telemetry reception error")
        return str(error), 500


# ==========================================
# API FOR HTML DASHBOARD
# ==========================================

@app.route("/api/telemetry")
def get_telemetry():

    with telemetry_lock:
        data = telemetry.copy()

    return jsonify(data)


# ==========================================
# SERVER HEALTH
# ==========================================

@app.route("/health")
def health():

    with telemetry_lock:
        last_update = telemetry["timestamp"]

    online = (
        last_update > 0 and
        time.time() - last_update < 2
    )

    return jsonify({
        "server": "online",
        "vehicle": "online" if online else "offline",
        "time": datetime.now().isoformat()
    })


# ==========================================
# RECORDER API
# ==========================================

@app.route("/api/recorder/start", methods=["POST"])
def api_start_recording():

    success, result = start_recording()

    if not success:
        return jsonify({
            "recording": recording,
            "message": result
        }), 409

    return jsonify({
        "recording": True,
        "filename": os.path.basename(result)
    })


@app.route("/api/recorder/stop", methods=["POST"])
def api_stop_recording():

    success, result = stop_recording()

    if not success:
        return jsonify({
            "recording": False,
            "message": result
        }), 409

    return jsonify({
        "recording": False,
        "filename": os.path.basename(result)
    })


@app.route("/api/recorder", methods=["GET"])
def api_recorder_status():

    with recording_lock:
        return jsonify({
            "recording": recording,
            "filename": (
                os.path.basename(recording_filename)
                if recording_filename else None
            )
        })

# ==========================================
# START SERVER
# ==========================================

if __name__ == "__main__":

    print("====================================")
    print("      OAI MIZUSHIMA YR-02")
    print("         FLIGHT MONITOR")
    print("====================================")
    print("Dashboard: http://127.0.0.1:8080")
    print("Telemetry: /telemetry")
    print("API:       /api/telemetry")
    print("Waiting for vehicle connection...")

    app.run(
        host="0.0.0.0",
        port=8080,
        debug=False,
        threaded=True
    )