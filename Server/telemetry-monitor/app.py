
from app import create_app

application = create_app()

if __name__ == "__main__":

    print("====================================")
    print("      OAI MIZUSHIMA YR-02")
    print("         FLIGHT MONITOR")
    print("====================================")
    print("Dashboard: http://127.0.0.1:8080")
    print("Telemetry: /telemetry")
    print("API:       /api/telemetry")
    print("Waiting for vehicle connection...")

    application.run(
        host="0.0.0.0",
        port=8080,
        debug=False,
        threaded=True
    )
