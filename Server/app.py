
from flask import Flask

from routes.dashboard import dashboard_bp
from routes.telemetry_routes import telemetry_bp
from routes.recorder_routes import recorder_bp


def create_app():

    app = Flask(__name__)

    app.register_blueprint(dashboard_bp)
    app.register_blueprint(telemetry_bp)
    app.register_blueprint(recorder_bp)

    return app
