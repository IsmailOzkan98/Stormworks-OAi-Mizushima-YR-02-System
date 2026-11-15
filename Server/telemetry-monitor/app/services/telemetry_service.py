
import json
import time

from threading import Lock

from app.config import TELEMETRY_SCHEMA_FILE


telemetry_lock = Lock()


def load_telemetry_schema():

    try:
        with open(TELEMETRY_SCHEMA_FILE, "r", encoding="utf-8") as file:
            return json.load(file)

    except Exception as error:
        print(f"Error loading telemetry schema: {error}")
        return {}


telemetry = load_telemetry_schema()


def update_telemetry(received):

    with telemetry_lock:

        for key, value in received.items():

            if key in telemetry and key not in ("stage", "status"):

                try:
                    telemetry[key] = float(value)

                except (ValueError, TypeError):
                    continue

            elif key in ("stage", "status") and key in telemetry:

                telemetry[key] = value

        telemetry["timestamp"] = time.time()

        return telemetry.copy()


def get_telemetry():

    with telemetry_lock:
        return telemetry.copy()


def get_last_update():

    with telemetry_lock:
        return telemetry["timestamp"]
