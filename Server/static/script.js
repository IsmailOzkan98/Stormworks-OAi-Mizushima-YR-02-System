
const OFFLINE_AFTER_MS = 2000;
const REFRESH_RATE_MS = 250;
const DIRECTION_PULSE_MS = 1500;

let latestTelemetryTimestamp = 0;


/* FLIGHT TELEMETRY HISTORY */

const GRAPH_HISTORY_SECONDS = 60;

const telemetryHistory = [];

function getNumericValue(data, key) {
    if (
        data[key] === null ||
        data[key] === undefined ||
        data[key] === ""
    ) {
        return null;
    }

    const value = Number(data[key]);

    return Number.isFinite(value) ? value : null;
}

function recordTelemetry(data) {

    const timestamp = Number(data.timestamp);

    telemetryHistory.push({
        timestamp,

        altitude: getNumericValue(data, "alt"),
        altitudeTarget: getNumericValue(data, "alt_target"),
        altitudeError: getNumericValue(data, "alt_error"),

        verticalSpeed: getNumericValue(data, "vs"),
        verticalSpeedTarget: getNumericValue(data, "vs_target"),
        verticalSpeedError: getNumericValue(data, "vs_error")
    });

    const cutoff = timestamp - GRAPH_HISTORY_SECONDS;

    while (
        telemetryHistory.length > 0 &&
        telemetryHistory[0].timestamp < cutoff
    ) {
        telemetryHistory.shift();
    }
}



/* GRAPH RENDERING ENGINE */

function drawTelemetryChart(canvasId, leftKeys, rightKey) {

    const canvas = document.getElementById(canvasId);

    if (!canvas) return;

    const ctx = canvas.getContext("2d");

    const styles = getComputedStyle(document.documentElement);

    const colors = {
        altitude: styles.getPropertyValue("--graph-altitude").trim(),
        target: styles.getPropertyValue("--graph-target").trim(),
        altError: styles.getPropertyValue("--graph-alt-error").trim(),
        vsError: styles.getPropertyValue("--graph-vs-error").trim()
    };

    const width = canvas.clientWidth;
    const height = canvas.clientHeight;

    if (!width || !height) return;

    const dpr = window.devicePixelRatio || 1;

    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);

    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    ctx.clearRect(0, 0, width, height);

    const left = 39;
    const right = width - 39;
    const top = 10;
    const bottom = height - 20;

    const plotWidth = right - left;
    const plotHeight = bottom - top;

    const latest = telemetryHistory[
        telemetryHistory.length - 1
    ];

    if (!latest) return;

    const startTime =
        latest.timestamp - GRAPH_HISTORY_SECONDS;

    const leftValues = telemetryHistory.flatMap(point =>
        leftKeys
            .map(key => point[key])
            .filter(value => value !== null)
    );

    const rightValues = telemetryHistory
        .map(point => point[rightKey])
        .filter(value => value !== null);

    if (!leftValues.length) return;

    function getRange(values) {

        let min = Math.min(...values);
        let max = Math.max(...values);

        if (min === max) {
            min -= 1;
            max += 1;
        }

        const padding = (max - min) * 0.12;

        return {
            min: min - padding,
            max: max + padding
        };
    }

    const leftRange = getRange(leftValues);

    const rightRange = rightValues.length
        ? getRange(rightValues)
        : { min: -1, max: 1 };

    function getX(timestamp) {
        return left +
            ((timestamp - startTime) /
            GRAPH_HISTORY_SECONDS) * plotWidth;
    }

    function getY(value, range) {
        return bottom -
            ((value - range.min) /
            (range.max - range.min)) * plotHeight;
    }

    /* GRID */

    ctx.lineWidth = 1;
    ctx.strokeStyle = "rgba(184,166,117,0.16)";
    ctx.setLineDash([3, 4]);

    for (let i = 0; i <= 4; i++) {

        const y = top + (plotHeight / 4) * i;

        ctx.beginPath();
        ctx.moveTo(left, y);
        ctx.lineTo(right, y);
        ctx.stroke();
    }

    for (let i = 0; i <= 4; i++) {

        const x = left + (plotWidth / 4) * i;

        ctx.beginPath();
        ctx.moveTo(x, top);
        ctx.lineTo(x, bottom);
        ctx.stroke();
    }

    ctx.setLineDash([]);

    /* AXIS LABELS */

    ctx.fillStyle = "#aaa38f";
    ctx.font = "9px IBM Plex Mono";
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

    ctx.textAlign = "center";

    ctx.fillText("-60s", left, height - 4);
    ctx.fillText("-30s", left + plotWidth / 2, height - 4);
    ctx.fillText("NOW", right, height - 4);

    /* DRAW CURVES */

    function drawCurve(key, color, range, dashed = false) {

        ctx.beginPath();

        ctx.strokeStyle = color;
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";

        ctx.setLineDash(dashed ? [5, 3] : []);

        let started = false;

        telemetryHistory.forEach(point => {

            const value = point[key];

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

    // ACTUAL VALUE
    drawCurve(
        leftKeys[0],
        colors.altitude,
        leftRange
    );

    // TARGET VALUE
    drawCurve(
        leftKeys[1],
        colors.target,
        leftRange,
        true
    );

    // ERROR VALUE - SECONDARY SCALE
    drawCurve(
        rightKey,
        canvasId === "altitudeChart"
            ? colors.altError
            : colors.vsError,
        rightRange
    );
}

/* UPDATE BOTH GRAPHS */

function drawTelemetryGraphs() {

    drawTelemetryChart(
        "altitudeChart",
        ["altitude", "altitudeTarget"],
        "altitudeError"
    );

    drawTelemetryChart(
        "verticalSpeedChart",
        ["verticalSpeed", "verticalSpeedTarget"],
        "verticalSpeedError"
    );
}


let previousConnection = null;
let previousSnapshot = {};
let previousStage = null;
let previousStatus = null;

const directionTimers = {};

const directions = ["north", "east", "south", "west"];

const systems = [
    ["main", "main", "MAIN PROPULSION"],
    ["alt_hold", "altHold", "ALTITUDE HOLD"],
    ["roll_stab", "rollStab", "ROLL STABILIZER"],
    ["accel", "accel", "THROTTLE CONTROL"],
    ["afterburner", "afterburner", "AFTERBURNER"],
    ["north", "north", "NORTH BOOSTER"],
    ["east", "east", "EAST BOOSTER"],
    ["south", "south", "SOUTH BOOSTER"],
    ["west", "west", "WEST BOOSTER"]
];

function number(data, key, decimals = 1) {
    const value = Number(data[key]);

    return Number.isFinite(value)
        ? value.toFixed(decimals)
        : "--";
}

function isActive(data, key) {
    return data[key] === "1" ||
        data[key] === 1 ||
        data[key] === true ||
        data[key] === "true";
}

function setValue(id, value) {
    const element = document.getElementById(id);

    if (element) {
        element.textContent = value;
    }
}

function setIndicator(id, active) {
    const element = document.getElementById(id);

    if (element) {
        element.classList.toggle("active", active);
    }
}


function logEvent(message, type = "normal") {
    const log = document.getElementById("eventLog");

    if (!log) return;

    const entry = document.createElement("div");
    entry.className = `event-entry ${type}`;

    const time = document.createElement("span");
    time.className = "event-time";
    time.textContent = new Date().toLocaleTimeString();

    const content = document.createElement("span");
    content.textContent = message;

    entry.append(time, content);
    log.prepend(entry);

    // Máximo 30 eventos
    while (log.children.length > 30) {
        log.lastElementChild.remove();
    }
}


function setConnection(online, detail) {
    const light = document.getElementById("onlineLight");

    if (light) {
        light.classList.toggle("online", online);
    }

    setValue("onlineText", online ? "ONLINE" : "OFFLINE");
    setValue("connectionDetail", detail);
    setValue("monitorConnection", online ? "ONLINE" : "OFFLINE");

    if (
        previousConnection !== null &&
        previousConnection !== online
    ) {
        logEvent(
        online
            ? "Telemetry connection restored."
            : "Telemetry connection lost.",
        online ? "navigation-event" : "error"
    );
    }

    previousConnection = online;
}

/* DIRECTIONAL BOOSTER EFFECT */

function pulseDirection(id, active) {
    const indicator = document.getElementById(id);

    if (!indicator) return;

    const booster = indicator.closest(".booster");

    if (!booster) return;

    if (active) {
        booster.classList.add("pulse");

        clearTimeout(directionTimers[id]);

        directionTimers[id] = setTimeout(() => {
            booster.classList.remove("pulse");
            delete directionTimers[id];
        }, DIRECTION_PULSE_MS);
    }
}

/* DIAGNOSTICS */

function updateDiagnostics(data) {
    systems.forEach(([key, indicatorId, label]) => {

        const active = isActive(data, key);

        if (directions.includes(key)) {
            pulseDirection(indicatorId, active);
        } else {
            setIndicator(indicatorId, active);
        }

        const statusElement =
            document.getElementById(indicatorId + "Status");

        if (statusElement) {
            statusElement.textContent =
                active ? "ACTIVE" : "OFFLINE";

            statusElement.classList.toggle(
                "active-text",
                active
            );
        }

        const previous = previousSnapshot[key];

        if (previous !== undefined && previous !== active) {
            logEvent(
                `${label}: ${active ? "ACTIVATED" : "DEACTIVATED"}.`,
                active ? "activation" : "deactivation"
            );
        }

        previousSnapshot[key] = active;
    });
}

/* INTERFACE */

function updateInterface(data) {

    // FLIGHT SEQUENCE

    const stage = data.stage || "UNKNOWN";
    const status = (data.status || "IDLE").toUpperCase();

    setValue("stage", stage);
    setValue("state", data.state ?? "--");
    setValue("timer", data.timer ?? "--");

    const statusElement = document.getElementById("flightStatus");

    if (statusElement) {
        statusElement.textContent = status;

        statusElement.className =
            "state-pill " +
            (status === "RUNNING" ? "running" :
             status === "COMPLETED" ? "completed" : "idle");
    }

    setValue("monitorFlight", status);

    if (previousStage !== null && previousStage !== stage) {
        logEvent(
            `Flight stage changed: ${stage}`,
            "phase-event"
        );
    }

    if (previousStatus !== null && previousStatus !== status) {
        logEvent(
            `Flight status changed: ${status}`,
            "phase-event"
        );
    }

    previousStage = stage;
    previousStatus = status;

    
    // FLIGHT TELEMETRY

    setValue("altitude", number(data, "alt"));
    setValue("altTarget", number(data, "alt_target"));
    setValue("altError", number(data, "alt_error"));

    setValue("verticalSpeed", number(data, "vs"));
    setValue("vsTarget", number(data, "vs_target"));
    setValue("vsError", number(data, "vs_error"));

    // RECORD GRAPH HISTORY

    recordTelemetry(data);

    // DRAW LIVE GRAPHS

    drawTelemetryGraphs();


    // ENGINE

    setValue("rpm", number(data, "rps"));
    setValue("rpmTarget", number(data, "rps_target"));

    // AIRCRAFT ATTITUDE

    setValue("roll", number(data, "roll", 2));
    setValue("pitch", number(data, "pitch", 2));
    setValue("yaw", number(data, "yaw", 2));

    // AIRCRAFT SPEED

    setValue("absoluteSpeed", number(data, "absolute_speed", 1));

    // NAVIGATION

    setValue("gpsX", number(data, "my_x", 2));
    setValue("gpsY", number(data, "my_y", 2));

    setValue("targetX", number(data, "target_x", 2));
    setValue("targetY", number(data, "target_y", 2));

    setValue("distance", number(data, "ap_distance", 1));

    // AUTOPILOT

    const autopilot = isActive(data, "ap");

    setValue(
        "autopilot",
        autopilot ? "ACTIVE" : "OFFLINE"
    );

    setValue(
        "monitorAutopilot",
        autopilot ? "ACTIVE" : "OFFLINE"
    );

    // CONTROL SYSTEMS

    setValue("spoiler", number(data, "spoiler", 2));

    // DIAGNOSTICS

    updateDiagnostics(data);

    // LAST UPDATE

    setValue(
        "lastUpdate",
        new Date(latestTelemetryTimestamp * 1000)
            .toLocaleTimeString()
    );
}

/* CONNECTION STATUS */

function updateConnectionStatus() {

    if (!latestTelemetryTimestamp) {
        setConnection(false, "Esperando telemetría...");
        setValue("telemetryAge", "--");
        return;
    }

    const age =
        Date.now() - latestTelemetryTimestamp * 1000;

    const online =
        age >= 0 && age < OFFLINE_AFTER_MS;

    setConnection(
        online,
        online ? "Telemetría recibida" : "Telemetría detenida"
    );

    setValue(
        "telemetryAge",
        Math.max(0, Math.round(age)) + " ms"
    );
}

/* TELEMETRY REQUEST */

let requestInProgress = false;

async function updateTelemetry() {

    if (requestInProgress) return;

    requestInProgress = true;

    try {
        const response = await fetch("/api/telemetry", {
            cache: "no-store"
        });

        if (!response.ok) {
            throw new Error("HTTP " + response.status);
        }

        const data = await response.json();
        const timestamp = Number(data.timestamp);

        if (
            Number.isFinite(timestamp) &&
            timestamp > 0 &&
            timestamp <= Date.now() / 1000
        ) {
            if (timestamp > latestTelemetryTimestamp) {
                latestTelemetryTimestamp = timestamp;
                updateInterface(data);
            }
        }

        updateConnectionStatus();

    } catch (error) {
        setConnection(false, "Servidor no disponible");

    } finally {
        requestInProgress = false;
    }
}

/* INITIALIZATION */

logEvent("Flight monitoring initialized.", "system-event");

updateTelemetry();

setInterval(updateTelemetry, REFRESH_RATE_MS);

setInterval(updateConnectionStatus, 100);

window.addEventListener("resize", drawTelemetryGraphs);
