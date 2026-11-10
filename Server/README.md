# PART 07 — SERVER & TELEMETRY SYSTEM

**Project:** OAI MIZUSHIMA YR-02  
**Subsystem:** External Server & Flight Monitoring  
**Part:** 07  
**Status:** Implemented  
**Architecture:** HTTP Telemetry Server + Web Dashboard  
**Platform:** Python / Flask / Docker  
**Default Port:** 8080  
**Data Mode:** READ ONLY

---

## 1. OVERVIEW

PART 07 is the external server and telemetry monitoring subsystem of the OAI MIZUSHIMA YR-02 project.

Its purpose is to receive flight telemetry from the Stormworks vehicle, process and temporarily store the latest received values, and make this information available through a web dashboard.

The subsystem operates independently from the vehicle's flight-control logic.

It provides:

- HTTP telemetry reception.
- Real-time telemetry storage.
- Web-based flight monitoring.
- Flight sequence monitoring.
- Engine and propulsion diagnostics.
- Navigation and autopilot monitoring.
- System activation indicators.
- Flight event logging.
- Server and vehicle connection monitoring.
- Docker-based deployment.

PART 07 is a monitoring subsystem. It does not issue flight commands or directly control vehicle systems.

## 2. SYSTEM ARCHITECTURE

The server architecture consists of three main components.

### 2.1 Stormworks Vehicle

The Stormworks Lua controller sends telemetry using HTTP requests.

**Destination:**
- Host: Server IP address.
- Port: 8080.
- Endpoint: `/telemetry`.
- Method: HTTP GET.

The vehicle transmits flight and system information as URL query parameters.

### 2.2 Flask Server

The Python application receives incoming telemetry and updates the latest stored snapshot.

Responsibilities:

- Receive HTTP requests.
- Extract telemetry parameters.
- Validate and convert numeric values.
- Update the telemetry data structure.
- Generate timestamps.
- Provide telemetry through a JSON API.
- Report server and vehicle connection status.

### 2.3 Web Dashboard

The dashboard is a read-only monitoring interface.

It retrieves telemetry from the Flask API and updates its interface automatically.

The browser does not communicate directly with Stormworks.

### 2.4 Data Flow

```text
STORMWORKS VEHICLE
        |
        | HTTP GET
        | Port 8080
        v
FLASK TELEMETRY SERVER
        |
        | Update latest snapshot
        v
TELEMETRY STORAGE
        |
        | JSON API
        v
WEB DASHBOARD
        |
        v
FLIGHT MONITORING
```

## 3. DIRECTORY STRUCTURE

```text
PART_07_SERVER/
│
├── app.py
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
│
├── static/
│   ├── script.js
│   └── style.css
│
└── templates/
    └── index.html
```

### File responsibilities

| File | Responsibility |
|---|---|
| `app.py` | Flask application and HTTP endpoints |
| `docker-compose.yml` | Container deployment configuration |
| `Dockerfile` | Python container image definition |
| `requirements.txt` | Python dependencies |
| `static/script.js` | Dashboard logic and telemetry updates |
| `static/style.css` | Dashboard visual design |
| `templates/index.html` | Dashboard HTML structure |

## 4. SERVER APPLICATION — APP.PY

The server is implemented using Python and Flask.

### 4.1 Telemetry Storage

The application maintains a shared telemetry dictionary containing the latest received values.

The stored data includes:

- Flight sequence.
- Flight status.
- Sequence timer.
- Altitude and altitude target.
- Vertical speed and vertical speed target.
- Altitude and vertical speed errors.
- Engine output and target.
- Aircraft roll and pitch.
- Autopilot status.
- Navigation coordinates.
- Target coordinates.
- Autopilot distance and yaw.
- Main propulsion status.
- Altitude hold status.
- Roll stabilizer status.
- Acceleration booster status.
- Directional booster statuses.
- Spoiler value.
- Server-generated timestamp.

A threading lock protects access to the shared telemetry data.

This prevents simultaneous HTTP requests from accessing or modifying the stored snapshot without synchronization.

### 4.2 HTTP Endpoints

| Endpoint | Method | Function |
|---|---|---|
| `/` | GET | Serves the web dashboard |
| `/telemetry` | GET | Receives Stormworks telemetry |
| `/api/telemetry` | GET | Returns the latest telemetry as JSON |
| `/health` | GET | Reports server and vehicle connection status |

### 4.3 Telemetry Reception

**Endpoint:** `/telemetry`

**Method:** GET

The server reads incoming URL parameters using Flask's request interface.

The application:

1. Receives the HTTP request.
2. Extracts query parameters.
3. Checks whether each parameter exists in the telemetry structure.
4. Converts numeric values to floating-point numbers.
5. Stores `stage` and `status` as strings.
6. Updates the server timestamp.
7. Returns HTTP 200 when reception succeeds.

Unknown parameters are ignored.

Invalid numeric values are skipped.

The server generates its own timestamp using `time.time()`. Therefore, the timestamp exposed by the API represents the server's reception time, not a timestamp supplied by the vehicle.

### 4.4 Telemetry API

**Endpoint:** `/api/telemetry`

**Method:** GET

Returns the latest stored telemetry snapshot in JSON format.

The dashboard uses this endpoint to retrieve updated information.

The API does not return a historical telemetry database. It returns the most recently stored snapshot.

### 4.5 Health Monitoring

**Endpoint:** `/health`

The endpoint reports:

- Server status.
- Vehicle connection status.
- Current server time.

The vehicle is considered online when telemetry has been received within the previous two seconds.

Example response:

```json
{
  "server": "online",
  "vehicle": "online",
  "time": "2026-01-01T12:00:00"
}
```

The example timestamp is illustrative.

## 5. TELEMETRY DATA CONTRACT

The server currently recognizes the following telemetry fields.

| Parameter | Type | Description |
|---|---|---|
| `stage` | String | Current flight sequence stage |
| `state` | Number | Current sequence state |
| `status` | String | Flight sequence status |
| `timer` | Number | Sequence execution timer |
| `alt` | Number | Current altitude |
| `alt_target` | Number | Target altitude |
| `alt_error` | Number | Altitude error |
| `vs` | Number | Current vertical speed |
| `vs_target` | Number | Target vertical speed |
| `vs_error` | Number | Vertical speed error |
| `rps` | Number | Current engine output |
| `rps_target` | Number | Target engine output |
| `roll` | Number | Aircraft roll |
| `pitch` | Number | Aircraft pitch |
| `ap` | Number | Autopilot status |
| `ap_distance` | Number | Distance to destination |
| `yaw` | Number | Autopilot yaw value |
| `my_x` | Number | Current X coordinate |
| `my_y` | Number | Current Y coordinate |
| `target_x` | Number | Target X coordinate |
| `target_y` | Number | Target Y coordinate |
| `main` | Number | Main propulsion status |
| `alt_hold` | Number | Altitude hold status |
| `roll_stab` | Number | Roll stabilizer status |
| `accel` | Number | Acceleration booster status |
| `north` | Number | North booster status |
| `east` | Number | East booster status |
| `south` | Number | South booster status |
| `west` | Number | West booster status |
| `spoiler` | Number | Spoiler control value |
| `timestamp` | Number | Server-generated reception timestamp |

**Important:** The `timestamp` field is generated by Flask. It is not an input parameter that should be supplied by the Stormworks controller.

Boolean-like system statuses are currently stored as numeric values. The dashboard interprets `1`, `"1"`, `true`, and `"true"` as active.

### Example HTTP request

```text
http://SERVER_IP:8080/telemetry?stage=ALTITUDE_HOLD&state=8&status=RUNNING&alt=120&alt_target=150&vs=5&vs_target=10&rps=25&main=1&alt_hold=1
```

This is an illustrative request. The actual vehicle sender must use the complete field mapping required by the dashboard.

## 6. WEB DASHBOARD — INDEX.HTML

The dashboard is served through Flask using the Jinja2 template system.

It is divided into seven monitoring sections.

### 01 — Flight Telemetry

Displays:

- Current altitude.
- Vertical speed.
- Target altitude.
- Target vertical speed.
- Altitude error.
- Vertical speed error.

### 02 — Engine & Control

Displays:

- Engine output.
- Engine target.
- Aircraft roll.
- Aircraft pitch.
- Yaw value.
- Spoiler control value.

### 03 — Navigation

Displays:

- Current X and Y coordinates.
- Destination X and Y coordinates.
- Distance to destination.
- Autopilot status.

### 04 — System Diagnostics

Displays the activation status of:

- Main propulsion.
- Altitude hold.
- Roll stabilizer.
- Throttle control.
- North booster.
- East booster.
- South booster.
- West booster.

Directional booster activations also produce a visual pulse effect.

### 05 — Mission Monitor

Displays:

- Telemetry connection.
- Autopilot status.
- Flight sequence status.
- Last telemetry update.
- Telemetry packet age.

### 06 — Event Recorder

Records dashboard events, including:

- Flight stage changes.
- Flight status changes.
- Subsystem activation.
- Subsystem deactivation.
- Telemetry connection loss.
- Telemetry connection restoration.

The browser maintains a maximum of 30 visible events.

The event log is stored in browser memory and is not a persistent server-side flight recorder.

### 07 — System Information

Displays basic platform and dashboard information.

The dashboard is designed for desktop monitoring and includes responsive layouts for smaller screens.

## 7. DASHBOARD LOGIC — SCRIPT.JS

The JavaScript application controls telemetry polling, dashboard updates, diagnostics and connection monitoring.

### 7.1 Update Rate

| Parameter | Value |
|---|---:|
| Refresh interval | 250 ms |
| Connection timeout | 2000 ms |
| Directional pulse duration | 1500 ms |
| Maximum event entries | 30 |

The dashboard requests the API four times per second under normal operation.

A request-in-progress flag prevents overlapping telemetry requests.

### 7.2 Connection Detection

The browser compares the latest server timestamp with the current browser time.

If the latest telemetry is less than two seconds old, the connection is considered online.

Otherwise, the dashboard displays offline status.

Connection monitoring runs independently every 100 ms.

### 7.3 Diagnostics

Subsystem states are translated into visual indicators.

When a subsystem changes state, the dashboard generates an event entry.

Directional boosters use a temporary pulse animation to highlight their activation.

### 7.4 Interface Updates

The JavaScript updates dashboard values using element IDs defined in `index.html`.

Numeric values are formatted for readability.

Invalid or unavailable values are displayed as `--`.

The browser ignores telemetry snapshots whose timestamp is not newer than the latest accepted snapshot.

## 8. VISUAL INTERFACE — STYLE.CSS

The dashboard uses a custom industrial aerospace visual design.

### Design characteristics

- Dark background.
- Gold and ivory primary colors.
- Cyan navigation and attitude indicators.
- Green active system indicators.
- Yellow warning indicators.
- Red connection and error indicators.
- IBM Plex Mono typography.
- Barlow Condensed display typography.
- Responsive three-column dashboard.
- Animated connection indicator.
- Directional booster activation effects.
- Event recorder color coding.

The layout supports:

- Desktop monitoring.
- 1920 × 1080 displays.
- Compact desktop screens.
- Tablet layouts.
- Mobile layouts.

External fonts are loaded from Google Fonts when network access is available.

## 9. DOCKER DEPLOYMENT

PART 07 uses Docker for deployment and portability.

### 9.1 Dockerfile

The container uses:

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates ./templates
COPY static ./static

EXPOSE 8080

CMD ["python", "app.py"]
```

### 9.2 Requirements

The current `requirements.txt` contains:

```text
flask
```

Flask is the only explicitly declared Python dependency.

### 9.3 Docker Compose

The current deployment configuration:

```yaml
services:
  stormworks-test:
    build: .
    container_name: stormworks-test
    ports:
      - "8080:8080"
    restart: unless-stopped
```

### 9.4 Starting the Server

Build and start:

```bash
docker compose up -d --build
```

Stop:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f
```

Restart:

```bash
docker compose restart
```

### 9.5 Access

Dashboard:

```text
http://SERVER_IP:8080/
```

Telemetry API:

```text
http://SERVER_IP:8080/api/telemetry
```

Health check:

```text
http://SERVER_IP:8080/health
```

Telemetry reception:

```text
http://SERVER_IP:8080/telemetry
```

The server listens on `0.0.0.0:8080` inside the container.

The Docker configuration publishes port 8080 to the host.

## 10. OPERATIONAL CHARACTERISTICS

The current implementation has the following characteristics:

| Feature | Implementation |
|---|---|
| HTTP reception | Implemented |
| Telemetry storage | Latest snapshot in memory |
| JSON API | Implemented |
| Web dashboard | Implemented |
| Connection detection | Implemented |
| Event logging | Browser-side, temporary |
| Health endpoint | Implemented |
| Docker deployment | Implemented |
| Authentication | Not implemented |
| Historical database | Not implemented |
| Persistent event recording | Not implemented |
| Remote vehicle control | Not implemented |
| Telemetry encryption | Not implemented |

### Important limitations

The server currently uses HTTP GET query parameters for telemetry reception.

It does not implement authentication, authorization or encrypted transport.

The application stores only the latest telemetry snapshot in memory. Restarting the container resets the stored values.

The current event recorder is a browser-side visual log, not a permanent flight-data recorder.

The `/health` endpoint reports the server as online when it responds, while vehicle status is determined separately using the age of the latest received telemetry.

The current Flask application is configured with the built-in development server. For a public or production deployment, a production WSGI server and appropriate network security configuration should be considered.

## 11. INTEGRATION WITH THE FLIGHT CONTROLLER

PART 07 is connected to the Stormworks control system through HTTP telemetry.

The vehicle remains responsible for:

- Flight sequence execution.
- Roll stabilization.
- Altitude hold.
- Autopilot.
- Propulsion.
- Directional boosters.
- Acceleration boosters.
- Flight-control safety logic.

PART 07 receives information about these systems but does not participate in their control loops.

The telemetry server must remain non-critical to flight operation.

If the server becomes unavailable, the vehicle must continue operating according to its own onboard control logic.

The server connection must never be a prerequisite for safe flight-control execution.

## 12. FUTURE DEVELOPMENT

Potential future improvements:

- Persistent telemetry database.
- Historical flight graphs.
- Flight session recording.
- Exportable flight reports.
- Authentication and access control.
- HTTPS support.
- Telemetry packet validation.
- Sequence and subsystem fault reporting.
- Communication diagnostics.
- Support for the future distributed microcontroller architecture.
- Individual subsystem monitoring.
- Heartbeat monitoring for distributed controllers.
- Server-side event history.

These features are planned possibilities and are not part of the current implementation.

## 13. PART 07 STATUS

**Current status: IMPLEMENTED**

PART 07 currently provides an operational HTTP telemetry server and web-based flight monitoring interface.

It is an external monitoring component of the MIZUSHIMA YR-02 architecture.

It is designed to remain independent of the vehicle's real-time control systems and can later be extended to monitor the distributed microcontroller architecture.

---

**OAI AEROSPACE SYSTEMS**  
**MIZUSHIMA YR-02**  
**PART 07 — SERVER & TELEMETRY SYSTEM**