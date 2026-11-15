
import os

BASE_DIR = "/app"

LOG_DIR = os.path.join(BASE_DIR, "logs")

RECORDER_CONFIG_FILE = os.path.join(
    BASE_DIR,
    "recorder",
    "recorder_config.json"
)

TELEMETRY_CONFIG_FILE = os.path.join(
    BASE_DIR,
    "core",
    "telemetry_config.json"
)

HOST = "0.0.0.0"
PORT = 8080

os.makedirs(LOG_DIR, exist_ok=True)
