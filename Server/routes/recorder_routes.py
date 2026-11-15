
from flask import Blueprint, jsonify

from recorder.recorder import (
    start_recording,
    stop_recording,
    get_recorder_status
)


recorder_bp = Blueprint("recorder", __name__)


@recorder_bp.route("/api/recorder/start", methods=["POST"])
def api_start_recording():

    success, result = start_recording()

    if not success:
        return jsonify({
            "recording": False,
            "message": result
        }), 409

    return jsonify({
        "recording": True,
        "filename": result.split("/")[-1]
    })


@recorder_bp.route("/api/recorder/stop", methods=["POST"])
def api_stop_recording():

    success, result = stop_recording()

    if not success:
        return jsonify({
            "recording": False,
            "message": result
        }), 409

    return jsonify({
        "recording": False,
        "filename": result.split("/")[-1]
    })


@recorder_bp.route("/api/recorder", methods=["GET"])
def api_recorder_status():

    return jsonify(get_recorder_status())
