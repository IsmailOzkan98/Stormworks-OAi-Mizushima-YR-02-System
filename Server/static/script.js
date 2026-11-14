
/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT TELEMETRY MONITOR
   VERSION: 2.0.0

   RESPONSIBILITY:
   Flight telemetry reception, visualization, diagnostics,
   connection monitoring and event logging.

   GRAPH SYSTEM:
   - 60-second rolling history
   - Permanent session scale
   - Independent error scale
   - Live canvas rendering

   ============================================================ */


/* ============================================================
   01. SYSTEM CONFIGURATION
   ============================================================ */

const OFFLINE_AFTER_MS = 2000;
const REFRESH_RATE_MS = 250;
const DIRECTION_PULSE_MS = 1500;


/* ============================================================
   02. TELEMETRY STATE
   ============================================================ */

let latestTelemetryTimestamp = 0;

let requestInProgress = false;


/* ============================================================
   03. GRAPH CONFIGURATION
   ============================================================ */

// GRAPH HISTORY

const GRAPH_HISTORY_SECONDS = 60;
const MAX_GRAPH_POINTS = 1200;


// PERMANENT GRAPH SCALE HISTORY

// These values are maintained throughout the session.
// The scale can expand but never contracts.

const graphExtremes = {

    altitude: {
        min: Infinity,
        max: -Infinity
    },

    altitudeTarget: {
        min: Infinity,
        max: -Infinity
    },

    altitudeError: {
        min: Infinity,
        max: -Infinity
    },

    verticalSpeed: {
        min: Infinity,
        max: -Infinity
    },

    verticalSpeedTarget: {
        min: Infinity,
        max: -Infinity
    },

    verticalSpeedError: {
        min: Infinity,
        max: -Infinity
    }

};


// TELEMETRY HISTORY

const telemetryHistory = [];


/* ============================================================
   04. GENERAL STATE
   ============================================================ */

let previousConnection = null;
let previousSnapshot = {};
let previousStage = null;
let previousStatus = null;

const directionTimers = {};

const directions = [
    "north",
    "east",
    "south",
    "west"
];


/* ============================================================
   05. SYSTEM DEFINITIONS
   ============================================================ */

const systems = [

    ["main", "main", "MAIN PROPULSION"],
    ["alt_hold", "altHold", "ALTITUDE HOLD"],
    ["roll_stab", "rollStab", "ROLL STABILIZER"],
    ["accel", "accel", "THROTTLE CONTROL"],
    ["afterburner", "afterburner", "AFTERBURNER"],
    ["descent", "descent", "DESCENT ENABLE"],

    ["north", "north", "NORTH BOOSTER"],
    ["east", "east", "EAST BOOSTER"],
    ["south", "south", "SOUTH BOOSTER"],
    ["west", "west", "WEST BOOSTER"]

];


/* ============================================================
   06. NUMERICAL UTILITIES
   ============================================================ */

// Convert telemetry value into a valid number.
// Returns null when the value is unavailable.

function getNumericValue(data, key) {

    if (
        data[key] === null ||
        data[key] === undefined ||
        data[key] === ""
    ) {
        return null;
    }

    const value = Number(data[key]);

    return Number.isFinite(value)
        ? value
        : null;

}


// Format numerical values for interface display.

function number(data, key, decimals = 1) {

    const value = Number(data[key]);

    return Number.isFinite(value)
        ? value.toFixed(decimals)
        : "--";

}


// Convert RX/TX state into readable text.

function getRxTxState(state) {

    const states = {
        0: "SEARCHING",
        1: "CONNECTED",
        2: "LINK LOST"
    };

    return states[Number(state)] ?? "UNKNOWN";

}


// Read system activation state.

function isActive(data, key) {

    return data[key] === "1" ||
        data[key] === 1 ||
        data[key] === true ||
        data[key] === "true";

}


/* ============================================================
   07. GRAPH DATA MANAGEMENT
   ============================================================ */


/* ------------------------------------------------------------
   07.1 UPDATE PERMANENT GRAPH EXTREMES
   ------------------------------------------------------------ */

// Update historical minimum and maximum values.
//
// IMPORTANT:
// This function is called only after a new telemetry
// sample has been accepted.
//
// Historical extremes are never removed.

function updateGraphExtremes(data) {

    const keys = {

        altitude: "alt",
        altitudeTarget: "alt_target",
        altitudeError: "alt_error",

        verticalSpeed: "vs",
        verticalSpeedTarget: "vs_target",
        verticalSpeedError: "vs_error"

    };

    Object.keys(graphExtremes).forEach(key => {

        const value = getNumericValue(
            data,
            keys[key]
        );

        if (value === null) return;

        if (value > graphExtremes[key].max) {

            graphExtremes[key].max = value;

        }

        if (value < graphExtremes[key].min) {

            graphExtremes[key].min = value;

        }

    });

}


/* ------------------------------------------------------------
   07.2 RECORD TELEMETRY
   ------------------------------------------------------------ */

// Store accepted telemetry samples.
//
// History is limited to:
// - Last 60 seconds
// - Maximum 1200 samples
//
// Duplicate and older timestamps are rejected.

function recordTelemetry(data) {

    const timestamp = Number(data.timestamp);

    // VALIDATE TIMESTAMP

    if (
        !Number.isFinite(timestamp) ||
        timestamp <= 0
    ) {
        return;
    }


    // PREVENT DUPLICATE OR OLDER SAMPLES

    const lastPoint =
        telemetryHistory[telemetryHistory.length - 1];

    if (
        lastPoint &&
        timestamp <= lastPoint.timestamp
    ) {
        return;
    }


    // ACCEPT TELEMETRY SAMPLE

    const sample = {

        timestamp,

        altitude: getNumericValue(data, "alt"),
        altitudeTarget: getNumericValue(data, "alt_target"),
        altitudeError: getNumericValue(data, "alt_error"),

        verticalSpeed: getNumericValue(data, "vs"),
        verticalSpeedTarget: getNumericValue(data, "vs_target"),
        verticalSpeedError: getNumericValue(data, "vs_error")

    };


    // UPDATE PERMANENT SCALE

    updateGraphExtremes(data);


    // ADD SAMPLE TO HISTORY

    telemetryHistory.push(sample);


    // REMOVE SAMPLES OLDER THAN 60 SECONDS

    const cutoff =
        timestamp - GRAPH_HISTORY_SECONDS;

    while (
        telemetryHistory.length > 0 &&
        telemetryHistory[0].timestamp < cutoff
    ) {

        telemetryHistory.shift();

    }


    // ENFORCE MAXIMUM HISTORY SIZE

    while (
        telemetryHistory.length > MAX_GRAPH_POINTS
    ) {

        telemetryHistory.shift();

    }

}


/* ============================================================
   08. GRAPH SCALE ENGINE
   ============================================================ */


/* ------------------------------------------------------------
   08.1 CREATE PERMANENT RANGE
   ------------------------------------------------------------ */

// Create a scale using historical minimum and maximum.
//
// The scale expands when new extremes appear.
// The scale never contracts during the session.

function createFixedRange(min, max) {

    if (
        !Number.isFinite(min) ||
        !Number.isFinite(max)
    ) {

        return {
            min: -1,
            max: 1
        };

    }


    // PREVENT ZERO RANGE

    if (min === max) {

        min -= 1;
        max += 1;

    }


    // ADD 12% VISUAL PADDING

    const padding = (max - min) * 0.12;

    return {

        min: min - padding,
        max: max + padding

    };

}


/* ------------------------------------------------------------
   08.2 CALCULATE GRAPH SCALES
   ------------------------------------------------------------ */

function getGraphRanges(leftKeys, rightKey) {

    let leftMin = Infinity;
    let leftMax = -Infinity;


    // LEFT AXIS
    // Actual altitude / vertical speed
    // Target altitude / vertical speed

    leftKeys.forEach(key => {

        leftMin = Math.min(
            leftMin,
            graphExtremes[key].min
        );

        leftMax = Math.max(
            leftMax,
            graphExtremes[key].max
        );

    });


    // RIGHT AXIS
    // Error

    const rightMin =
        graphExtremes[rightKey].min;

    const rightMax =
        graphExtremes[rightKey].max;


    return {

        leftRange: createFixedRange(
            leftMin,
            leftMax
        ),

        rightRange: createFixedRange(
            rightMin,
            rightMax
        )

    };

}


/* ============================================================
   09. GRAPH RENDERING ENGINE
   ============================================================ */


/* ------------------------------------------------------------
   09.1 DRAW TELEMETRY CHART
   ------------------------------------------------------------ */

function drawTelemetryChart(
    canvasId,
    leftKeys,
    rightKey
) {

    const canvas =
        document.getElementById(canvasId);

    if (!canvas) return;

    const ctx = canvas.getContext("2d");

    if (!ctx) return;


    // GRAPH COLORS

    const styles =
        getComputedStyle(document.documentElement);

    const colors = {

        altitude: styles
            .getPropertyValue("--graph-altitude")
            .trim(),

        target: styles
            .getPropertyValue("--graph-target")
            .trim(),

        altError: styles
            .getPropertyValue("--graph-alt-error")
            .trim(),

        vsError: styles
            .getPropertyValue("--graph-vs-error")
            .trim()

    };


    // CANVAS DIMENSIONS

    const width = canvas.clientWidth;
    const height = canvas.clientHeight;

    if (!width || !height) return;

    const dpr = window.devicePixelRatio || 1;


    // HIGH DPI RENDERING

    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);

    ctx.setTransform(
        dpr,
        0,
        0,
        dpr,
        0,
        0
    );

    ctx.clearRect(
        0,
        0,
        width,
        height
    );


    // GRAPH BOUNDARIES

    const left = 39;
    const right = width - 39;

    const top = 10;
    const bottom = height - 20;

    const plotWidth = right - left;
    const plotHeight = bottom - top;

    if (plotWidth <= 0 || plotHeight <= 0) return;


    // LATEST TELEMETRY SAMPLE

    const latest = telemetryHistory[
        telemetryHistory.length - 1
    ];

    if (!latest) return;


    // TIME WINDOW

    const startTime =
        latest.timestamp - GRAPH_HISTORY_SECONDS;


    // VERIFY THAT THE GRAPH HAS DATA

    const hasLeftData = telemetryHistory.some(point =>
        leftKeys.some(key => point[key] !== null)
    );

    if (!hasLeftData) return;


    /* --------------------------------------------------------
       09.1.1 PERMANENT GRAPH SCALE
       -------------------------------------------------------- */

    const ranges = getGraphRanges(
        leftKeys,
        rightKey
    );

    const leftRange = ranges.leftRange;
    const rightRange = ranges.rightRange;


    /* --------------------------------------------------------
       09.1.2 COORDINATE CONVERSION
       -------------------------------------------------------- */

    function getX(timestamp) {

        return left +
            (
                (timestamp - startTime) /
                GRAPH_HISTORY_SECONDS
            ) * plotWidth;

    }


    function getY(value, range) {

        return bottom -
            (
                (value - range.min) /
                (range.max - range.min)
            ) * plotHeight;

    }


    /* --------------------------------------------------------
       09.1.3 GRID
       -------------------------------------------------------- */

    ctx.lineWidth = 1;

    ctx.strokeStyle =
        "rgba(184,166,117,0.16)";

    ctx.setLineDash([3, 4]);


    // HORIZONTAL GRID

    for (let i = 0; i <= 4; i++) {

        const y =
            top + (plotHeight / 4) * i;

        ctx.beginPath();

        ctx.moveTo(left, y);
        ctx.lineTo(right, y);

        ctx.stroke();

    }


    // VERTICAL GRID

    for (let i = 0; i <= 4; i++) {

        const x =
            left + (plotWidth / 4) * i;

        ctx.beginPath();

        ctx.moveTo(x, top);
        ctx.lineTo(x, bottom);

        ctx.stroke();

    }

    ctx.setLineDash([]);


    /* --------------------------------------------------------
       09.1.4 AXIS LABELS
       -------------------------------------------------------- */

    ctx.fillStyle = "#aaa38f";

    ctx.font = "9px IBM Plex Mono";


    // LEFT AXIS

    ctx.textAlign = "right";

    ctx.fillText(
        leftRange.max.toFixed(1),
        left - 5,
        top + 3
    );

    ctx.fillText(
        leftRange.min.toFixed(1),
        left - 5,
        bottom
    );


    // RIGHT AXIS

    ctx.textAlign = "left";

    ctx.fillText(
        rightRange.max.toFixed(1),
        right + 5,
        top + 3
    );

    ctx.fillText(
        rightRange.min.toFixed(1),
        right + 5,
        bottom
    );


    // TIME LABELS

    ctx.textAlign = "center";

    ctx.fillText(
        "-60s",
        left,
        height - 4
    );

    ctx.fillText(
        "-30s",
        left + plotWidth / 2,
        height - 4
    );

    ctx.fillText(
        "NOW",
        right,
        height - 4
    );


    /* --------------------------------------------------------
       09.1.5 DRAW TELEMETRY CURVES
       -------------------------------------------------------- */

    function drawCurve(
        key,
        color,
        range,
        dashed = false
    ) {

        ctx.beginPath();

        ctx.strokeStyle = color;

        ctx.lineWidth = 2;

        ctx.lineJoin = "round";
        ctx.lineCap = "round";

        ctx.setLineDash(
            dashed ? [5, 3] : []
        );

        let started = false;


        telemetryHistory.forEach(point => {

            const value = point[key];


            // IGNORE INVALID VALUES AND OLD SAMPLES

            if (
                value === null ||
                point.timestamp < startTime
            ) {

                started = false;
                return;

            }


            const x = getX(point.timestamp);
            const y = getY(value, range);


            if (!started) {

                ctx.moveTo(x, y);
                started = true;

            } else {

                ctx.lineTo(x, y);

            }

        });


        ctx.stroke();

        ctx.setLineDash([]);

    }


    /* --------------------------------------------------------
       09.1.6 ACTUAL VALUE
       -------------------------------------------------------- */

    drawCurve(
        leftKeys[0],
        colors.altitude,
        leftRange
    );


    /* --------------------------------------------------------
       09.1.7 TARGET VALUE
       -------------------------------------------------------- */

    drawCurve(
        leftKeys[1],
        colors.target,
        leftRange,
        true
    );


    /* --------------------------------------------------------
       09.1.8 ERROR VALUE
       -------------------------------------------------------- */

    drawCurve(
        rightKey,

        canvasId === "altitudeChart"
            ? colors.altError
            : colors.vsError,

        rightRange
    );

}


/* ------------------------------------------------------------
   09.2 UPDATE BOTH GRAPHS
   ------------------------------------------------------------ */

function drawTelemetryGraphs() {

    drawTelemetryChart(
        "altitudeChart",

        [
            "altitude",
            "altitudeTarget"
        ],

        "altitudeError"
    );


    drawTelemetryChart(
        "verticalSpeedChart",

        [
            "verticalSpeed",
            "verticalSpeedTarget"
        ],

        "verticalSpeedError"
    );

}


/* ============================================================
   10. DOM INTERFACE UTILITIES
   ============================================================ */


/* ------------------------------------------------------------
   10.1 UPDATE TEXT VALUES
   ------------------------------------------------------------ */

function setValue(id, value) {

    const element =
        document.getElementById(id);

    if (element) {

        element.textContent = value;

    }

}


/* ------------------------------------------------------------
   10.2 UPDATE INDICATORS
   ------------------------------------------------------------ */

function setIndicator(id, active) {

    const element =
        document.getElementById(id);

    if (element) {

        element.classList.toggle(
            "active",
            active
        );

    }

}


/* ============================================================
   11. EVENT LOGGING
   ============================================================ */


/* ------------------------------------------------------------
   11.1 LOG EVENT
   ------------------------------------------------------------ */

function logEvent(
    message,
    type = "normal"
) {

    const log =
        document.getElementById("eventLog");

    if (!log) return;


    const entry =
        document.createElement("div");

    entry.className =
        `event-entry ${type}`;


    const time =
        document.createElement("span");

    time.className = "event-time";

    time.textContent =
        new Date().toLocaleTimeString();


    const content =
        document.createElement("span");

    content.textContent = message;


    entry.append(
        time,
        content
    );

    log.prepend(entry);


    // MAXIMUM 30 EVENTS

    while (log.children.length > 30) {

        log.lastElementChild.remove();

    }

}


/* ============================================================
   12. CONNECTION MANAGEMENT
   ============================================================ */


/* ------------------------------------------------------------
   12.1 CONNECTION STATE
   ------------------------------------------------------------ */

function setConnection(
    online,
    detail
) {

    const light =
        document.getElementById("onlineLight");


    if (light) {

        light.classList.toggle(
            "online",
            online
        );

    }


    setValue(
        "onlineText",
        online ? "ONLINE" : "OFFLINE"
    );

    setValue(
        "connectionDetail",
        detail
    );

    setValue(
        "monitorConnection",
        online ? "ONLINE" : "OFFLINE"
    );


    // CONNECTION CHANGE DETECTION

    if (
        previousConnection !== null &&
        previousConnection !== online
    ) {

        logEvent(

            online
                ? "Telemetry connection restored."
                : "Telemetry connection lost.",

            online
                ? "navigation-event"
                : "error"

        );

    }


    previousConnection = online;

}


/* ------------------------------------------------------------
   12.2 CONNECTION MONITORING
   ------------------------------------------------------------ */

function updateConnectionStatus() {


    // NO TELEMETRY RECEIVED

    if (!latestTelemetryTimestamp) {

        setConnection(
            false,
            "Esperando telemetría..."
        );

        setValue(
            "telemetryAge",
            "--"
        );

        return;

    }


    // CALCULATE TELEMETRY AGE

    const age =
        Date.now() -
        latestTelemetryTimestamp * 1000;


    // CONNECTION VALIDATION

    const online =
        age >= 0 &&
        age < OFFLINE_AFTER_MS;


    setConnection(

        online,

        online
            ? "Telemetría recibida"
            : "Telemetría detenida"

    );


    setValue(
        "telemetryAge",

        Math.max(
            0,
            Math.round(age)
        ) + " ms"

    );

}


/* ============================================================
   13. DIRECTIONAL BOOSTER EFFECTS
   ============================================================ */


/* ------------------------------------------------------------
   13.1 BOOSTER PULSE
   ------------------------------------------------------------ */

function pulseDirection(
    id,
    active
) {

    const indicator =
        document.getElementById(id);

    if (!indicator) return;


    const booster =
        indicator.closest(".booster");

    if (!booster) return;


    if (active) {

        booster.classList.add("pulse");


        // RESET PREVIOUS TIMER

        clearTimeout(
            directionTimers[id]
        );


        // REMOVE PULSE AFTER DURATION

        directionTimers[id] = setTimeout(() => {

            booster.classList.remove("pulse");

            delete directionTimers[id];

        }, DIRECTION_PULSE_MS);

    }

}


/* ============================================================
   14. SYSTEM DIAGNOSTICS
   ============================================================ */


/* ------------------------------------------------------------
   14.1 UPDATE DIAGNOSTICS
   ------------------------------------------------------------ */

function updateDiagnostics(data) {

    systems.forEach(([key, indicatorId, label]) => {


        // CURRENT STATE

        const active =
            isActive(data, key);


        // DIRECTIONAL BOOSTERS

        if (directions.includes(key)) {

            pulseDirection(
                indicatorId,
                active
            );

        } else {

            setIndicator(
                indicatorId,
                active
            );

        }


        // STATUS TEXT

        const statusElement =
            document.getElementById(
                indicatorId + "Status"
            );


        if (statusElement) {

            statusElement.textContent =
                active ? "ACTIVE" : "OFFLINE";

            statusElement.classList.toggle(
                "active-text",
                active
            );

        }


        // STATE CHANGE DETECTION

        const previous =
            previousSnapshot[key];


        if (
            previous !== undefined &&
            previous !== active
        ) {

            logEvent(

                `${label}: ${active ? "ACTIVATED" : "DEACTIVATED"}.`,

                active
                    ? "activation"
                    : "deactivation"

            );

        }


        previousSnapshot[key] = active;

    });

}


/* ============================================================
   15. MAIN INTERFACE UPDATE
   ============================================================ */


/* ------------------------------------------------------------
   15.1 FLIGHT SEQUENCE
   ------------------------------------------------------------ */

function updateInterface(data) {

    const stage =
        data.stage || "UNKNOWN";

    const status =
        (data.status || "IDLE").toUpperCase();


    setValue(
        "stage",
        stage
    );

    setValue(
        "state",
        data.state ?? "--"
    );

    setValue(
        "timer",
        data.timer ?? "--"
    );


    // RX-TX LINK STATUS

    setValue(
        "rxTxState",
        getRxTxState(data.rx_tx_state)
    );


    setValue(
        "rxTxFrequencyTX",
        number(data, "rx_tx_frequency_tx", 2)
    );

    setValue(
        "rxTxFrequencyRX",
        number(data, "rx_tx_frequency_rx", 2)
    );


    // FLIGHT STATUS

    const statusElement =
        document.getElementById("flightStatus");


    if (statusElement) {

        statusElement.textContent = status;

        statusElement.className =
            "state-pill " +

            (
                status === "RUNNING"
                    ? "running"

                    : status === "COMPLETED"
                        ? "completed"

                        : "idle"
            );

    }


    setValue(
        "monitorFlight",
        status
    );


    // STAGE CHANGE

    if (
        previousStage !== null &&
        previousStage !== stage
    ) {

        logEvent(
            `Flight stage changed: ${stage}`,
            "phase-event"
        );

    }


    // STATUS CHANGE

    if (
        previousStatus !== null &&
        previousStatus !== status
    ) {

        logEvent(
            `Flight status changed: ${status}`,
            "phase-event"
        );

    }


    previousStage = stage;
    previousStatus = status;


    /* --------------------------------------------------------
       15.2 FLIGHT TELEMETRY
       -------------------------------------------------------- */

    setValue(
        "altitude",
        number(data, "alt")
    );

    setValue(
        "altTarget",
        number(data, "alt_target")
    );

    setValue(
        "altError",
        number(data, "alt_error")
    );


    setValue(
        "verticalSpeed",
        number(data, "vs")
    );

    setValue(
        "vsTarget",
        number(data, "vs_target")
    );

    setValue(
        "vsError",
        number(data, "vs_error")
    );


    // RECORD TELEMETRY

    recordTelemetry(data);


    // DRAW LIVE GRAPHS

    drawTelemetryGraphs();


    /* --------------------------------------------------------
       15.3 ENGINE
       -------------------------------------------------------- */

    setValue(
        "rpm",
        number(data, "rps")
    );

    setValue(
        "rpmTarget",
        number(data, "rps_target")
    );


    /* --------------------------------------------------------
       15.4 AIRCRAFT ATTITUDE
       -------------------------------------------------------- */

    setValue(
        "roll",
        number(data, "roll", 2)
    );

    setValue(
        "pitch",
        number(data, "pitch", 2)
    );

    setValue(
        "yaw",
        number(data, "yaw", 2)
    );


    /* --------------------------------------------------------
       15.5 AIRCRAFT SPEED
       -------------------------------------------------------- */

    setValue(
        "absoluteSpeed",
        number(data, "absolute_speed", 1)
    );


    /* --------------------------------------------------------
       15.6 NAVIGATION
       -------------------------------------------------------- */

    setValue(
        "gpsX",
        number(data, "my_x", 2)
    );

    setValue(
        "gpsY",
        number(data, "my_y", 2)
    );

    setValue(
        "targetX",
        number(data, "target_x", 2)
    );

    setValue(
        "targetY",
        number(data, "target_y", 2)
    );

    setValue(
        "distance",
        number(data, "ap_distance", 1)
    );


    /* --------------------------------------------------------
       15.7 AUTOPILOT
       -------------------------------------------------------- */

    const autopilot =
        isActive(data, "ap");


    setValue(
        "autopilot",
        autopilot ? "ACTIVE" : "OFFLINE"
    );

    setValue(
        "monitorAutopilot",
        autopilot ? "ACTIVE" : "OFFLINE"
    );


    /* --------------------------------------------------------
       15.8 CONTROL SYSTEMS
       -------------------------------------------------------- */

    setValue(
        "spoiler",
        number(data, "spoiler", 2)
    );


    /* --------------------------------------------------------
       15.9 DIAGNOSTICS
       -------------------------------------------------------- */

    updateDiagnostics(data);


    /* --------------------------------------------------------
       15.10 LAST UPDATE
       -------------------------------------------------------- */

    setValue(
        "lastUpdate",

        new Date(
            latestTelemetryTimestamp * 1000
        ).toLocaleTimeString()

    );

}


/* ============================================================
   16. TELEMETRY COMMUNICATION
   ============================================================ */


/* ------------------------------------------------------------
   16.1 REQUEST TELEMETRY
   ------------------------------------------------------------ */

async function updateTelemetry() {

    // PREVENT SIMULTANEOUS REQUESTS

    if (requestInProgress) return;

    requestInProgress = true;


    try {

        // REQUEST SERVER TELEMETRY

        const response = await fetch(
            "/api/telemetry",
            {
                cache: "no-store"
            }
        );


        // HTTP VALIDATION

        if (!response.ok) {

            throw new Error(
                "HTTP " + response.status
            );

        }


        // READ TELEMETRY

        const data =
            await response.json();

        const timestamp =
            Number(data.timestamp);


        // TIMESTAMP VALIDATION

        if (
            Number.isFinite(timestamp) &&
            timestamp > 0 &&
            timestamp <= Date.now() / 1000
        ) {


            // ACCEPT ONLY NEW TELEMETRY

            if (
                timestamp > latestTelemetryTimestamp
            ) {

                latestTelemetryTimestamp =
                    timestamp;


                // UPDATE COMPLETE INTERFACE

                updateInterface(data);

            }

        }


        // UPDATE CONNECTION STATE

        updateConnectionStatus();


    } catch (error) {

        // SERVER CONNECTION ERROR

        setConnection(
            false,
            "Servidor no disponible"
        );


    } finally {

        // RELEASE REQUEST LOCK

        requestInProgress = false;

    }

}


/* ============================================================
   17. APPLICATION INITIALIZATION
   ============================================================ */


/* ------------------------------------------------------------
   17.1 INITIALIZATION EVENT
   ------------------------------------------------------------ */

logEvent(
    "Flight monitoring initialized.",
    "system-event"
);


/* ------------------------------------------------------------
   17.2 INITIAL TELEMETRY REQUEST
   ------------------------------------------------------------ */

updateTelemetry();


/* ------------------------------------------------------------
   17.3 TELEMETRY REFRESH LOOP
   ------------------------------------------------------------ */

setInterval(
    updateTelemetry,
    REFRESH_RATE_MS
);


/* ------------------------------------------------------------
   17.4 CONNECTION MONITOR LOOP
   ------------------------------------------------------------ */

setInterval(
    updateConnectionStatus,
    100
);


/* ------------------------------------------------------------
   17.5 GRAPH RESIZE HANDLER
   ------------------------------------------------------------ */

window.addEventListener(
    "resize",
    drawTelemetryGraphs
);


/* ============================================================
   19. FLIGHT DATA RECORDER CONTROL
   ============================================================ */

const recorderStartButton =
    document.getElementById("startRecording");

const recorderStopButton =
    document.getElementById("stopRecording");

const recorderStatusElement =
    document.getElementById("recorderStatus");


/* ------------------------------------------------------------
   UPDATE RECORDER INTERFACE
   ------------------------------------------------------------ */

function updateRecorderInterface(recording, filename = null) {

    recorderStartButton.disabled = recording;
    recorderStopButton.disabled = !recording;

    if (recording) {

        recorderStatusElement.textContent =
            "● RECORDING " + (filename || "");

        recorderStatusElement.classList.add("recording");

    } else {

        recorderStatusElement.textContent =
            "RECORDER STANDBY";

        recorderStatusElement.classList.remove("recording");

    }

}


/* ------------------------------------------------------------
   START RECORDING
   ------------------------------------------------------------ */

async function startFlightRecording() {

    recorderStartButton.disabled = true;

    try {

        const response = await fetch(
            "/api/recorder/start",
            {
                method: "POST"
            }
        );

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || "Start failed");
        }

        updateRecorderInterface(
            true,
            result.filename
        );

        logEvent(
            "Flight data recording started: " + result.filename,
            "activation"
        );

    } catch (error) {

        updateRecorderInterface(false);

        logEvent(
            "Recorder start error: " + error.message,
            "error"
        );

    }

}


/* ------------------------------------------------------------
   STOP RECORDING
   ------------------------------------------------------------ */

async function stopFlightRecording() {

    recorderStopButton.disabled = true;

    try {

        const response = await fetch(
            "/api/recorder/stop",
            {
                method: "POST"
            }
        );

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || "Stop failed");
        }

        updateRecorderInterface(false);

        logEvent(
            "Flight data recording saved: " + result.filename,
            "activation"
        );

    } catch (error) {

        logEvent(
            "Recorder stop error: " + error.message,
            "error"
        );

        await refreshRecorderStatus();

    }

}


/* ------------------------------------------------------------
   GET CURRENT RECORDER STATUS
   ------------------------------------------------------------ */

async function refreshRecorderStatus() {

    try {

        const response = await fetch(
            "/api/recorder",
            {
                cache: "no-store"
            }
        );

        if (!response.ok) return;

        const result = await response.json();

        updateRecorderInterface(
            result.recording,
            result.filename
        );

    } catch (error) {

        console.error(
            "Recorder status error:",
            error
        );

    }

}


/* ------------------------------------------------------------
   BUTTON EVENTS
   ------------------------------------------------------------ */

recorderStartButton.addEventListener(
    "click",
    startFlightRecording
);

recorderStopButton.addEventListener(
    "click",
    stopFlightRecording
);


/* ------------------------------------------------------------
   INITIAL RECORDER STATUS
   ------------------------------------------------------------ */

refreshRecorderStatus();

/* ============================================================
   18. END OF FLIGHT TELEMETRY MONITOR
   ============================================================ */
