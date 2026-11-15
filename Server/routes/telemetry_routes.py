
from flask import Blueprint, request, jsonify

from core.telemetry import (
    update_telemetry,
    get_telemetry,
    get_vehicle_status
)

from recorder.recorder import save_flight_event


telemetry_bp = Blueprint("telemetry", __name__)


@telemetry_bp.route("/telemetry", methods=["GET"])
def receive_telemetry():

    received = request.args.to_dict()

    if not received:
        return "No telemetry data", 400

    try:

        snapshot = update_telemetry(received)

        save_flight_event(snapshot)

        return "OK", 200

    except Exception as error:

        return str(error), 500


@telemetry_bp.route("/api/telemetry")
def api_telemetry():

    return jsonify(get_telemetry())


@telemetry_bp.route("/health")
def health():

    return jsonify({
        "server": "online",
        "vehicle": (
            "online" if get_vehicle_status()
            else "offline"
        )
    })
