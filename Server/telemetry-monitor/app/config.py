
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

BACKEND_CONFIG_DIR = os.path.join(
    BASE_DIR, "config", "backend"
)

RECORDER_CONFIG_FILE = os.path.join(
    BACKEND_CONFIG_DIR, "recorder_config.json"
)

TELEMETRY_SCHEMA_FILE = os.path.join(
    BACKEND_CONFIG_DIR, "telemetry_schema.json"
)

LOG_DIR = os.path.join(BASE_DIR, "logs")

# Tiempo máximo sin telemetría para considerar
# que el vehículo está desconectado.
VEHICLE_TIMEOUT = 2
