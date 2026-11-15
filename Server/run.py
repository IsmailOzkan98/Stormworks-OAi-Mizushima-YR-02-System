
from app import create_app
from config import HOST, PORT

app = create_app()


if __name__ == "__main__":

    print("====================================")
    print("      OAI MIZUSHIMA YR-02")
    print("         FLIGHT MONITOR")
    print("====================================")
    print(f"Dashboard: http://127.0.0.1:{PORT}")
    print("Telemetry: /telemetry")
    print("API:       /api/telemetry")
    print("Waiting for vehicle connection...")
    print("====================================")

    app.run(
        host=HOST,
        port=PORT,
        debug=False,
        threaded=True
    )
