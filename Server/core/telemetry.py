import time
import json

from threading import Lock
from config import TELEMETRY_CONFIG_FILE


telemetry_lock = Lock()


def load_telemetry_config():

    try:
        with open(
            TELEMETRY_CONFIG_FILE,
            "r",
            encoding="utf-8"
        ) as file:

            return json.load(file)

    except Exception as error:

        raise RuntimeError(
            f"Error loading telemetry config: {error}"
        ) from error


def update_telemetry(received):

    with telemetry_lock:

        for key, value in received.items():

            if key not in telemetry:
                continue

            if key in ("stage", "status"):
                telemetry[key] = value

            else:
                try:
                    telemetry[key] = float(value)
                except (ValueError, TypeError):
                    continue

        telemetry["timestamp"] = time.time()

        return telemetry.copy()


def get_telemetry():

    with telemetry_lock:
        return telemetry.copy()


def get_vehicle_status():

    with telemetry_lock:
        last_update = telemetry["timestamp"]

    return (
        last_update > 0 and
        time.time() - last_update < 2
    )
