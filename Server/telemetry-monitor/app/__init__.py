
from flask import Flask

from app.routes.dashboard import dashboard_bp
from app.routes.telemetry import telemetry_bp
from app.routes.recorder import recorder_bp
from app.routes.health import health_bp


def create_app():

    app = Flask(__name__)

    # Registrar rutas
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(telemetry_bp)
    app.register_blueprint(recorder_bp)
    app.register_blueprint(health_bp)

    return app
