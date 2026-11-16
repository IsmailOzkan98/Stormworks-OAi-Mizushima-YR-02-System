
import json
import os

from datetime import datetime
from threading import Lock

from app.config import RECORDER_CONFIG_FILE, LOG_DIR


os.makedirs(LOG_DIR, exist_ok=True)

recording_lock = Lock()

recording = False
recording_file = None
recording_filename = None


def load_recorder_config():

    try:
        with open(RECORDER_CONFIG_FILE, "r", encoding="utf-8") as file:
            return json.load(file)

    except Exception as error:
        print(f"Error loading recorder config: {error}")
        return {"fields": {}}


recorder_config = load_recorder_config()


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

        fields = recorder_config.get("fields", {})

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


def get_recorder_status():

    with recording_lock:

        return {
            "recording": recording,
            "filename": (
                os.path.basename(recording_filename)
                if recording_filename else None
            )
        }
