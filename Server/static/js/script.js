
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
   MODULE MANAGEMENT
   ============================================================ */

let missionBarModule = null;
let pendingMissionData = null;
let systemDiagnosticsModule = null;
let missionMonitorModule = null;
let telemetryGraphsModule = null;

// Event Log estará disponible cuando se inicialice.
// Mientras tanto, los eventos se mostrarán en consola.

let logEvent = (message, type = "normal") => {

    console.log(`[${type.toUpperCase()}]`, message);

};

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



// Read system activation state.

function isActive(data, key) {

    return data[key] === "1" ||
        data[key] === 1 ||
        data[key] === true ||
        data[key] === "true";

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

    if (missionMonitorModule) {

    missionMonitorModule.updateMissionMonitorConnectionData(
        online
    );

}


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

        if (missionMonitorModule) {
            missionMonitorModule.updateMissionMonitorPacketAge(null);
        }

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


    if (missionMonitorModule) {

        missionMonitorModule.updateMissionMonitorPacketAge(
            Math.max(0, Math.round(age))
        );

    }

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


    pendingMissionData = data;

    if (missionBarModule) {
        missionBarModule.updateMissionBarData(data);
    }

    if (missionMonitorModule) {
        missionMonitorModule.updateMissionMonitorData(data);
    }

    if (systemDiagnosticsModule) {
        systemDiagnosticsModule.updateSystemDiagnostics(data);
    }


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


    if (telemetryGraphsModule) {
        telemetryGraphsModule.updateTelemetryGraphsData(data);
    }

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
   17. MODULE INITIALIZATION SYSTEM
   ============================================================ */


/* ------------------------------------------------------------
   17.1 LOAD GLOBAL CONFIGURATION
   ------------------------------------------------------------ */

async function loadModuleConfiguration() {

    try {

        const response = await fetch(
            "/static/config.json",
            { cache: "no-store" }
        );

        if (!response.ok) {
            throw new Error(
                `Configuration HTTP ${response.status}`
            );
        }

        return await response.json();

    } catch (error) {

        console.error(
            "[MODULE MANAGER] Configuration error:",
            error
        );

        // Safe fallback: all modules disabled.
        return {
            modules: {
                eventLog: false,
                flightRecorder: false,
                missionBar: false,
                missionMonitor: false,
                systemDiagnostics: false,
                telemetryGraphs: false,
            }
        };

    }

}


/* ------------------------------------------------------------
   17.2 INITIALIZE EVENT LOG
   ------------------------------------------------------------ */

async function initializeEventLog(enabled) {

    if (!enabled) {

        console.info("[EVENT LOG] Disabled by configuration.");
        return;

    }

    try {

        const { initEventLog } = await import(
            "./modules/eventLog/eventLog.js"
        );

        const container = document.getElementById(
            "eventLogContainer"
        );

        const eventLogger = initEventLog(container);

        if (typeof eventLogger === "function") {

            logEvent = eventLogger;

            logEvent(
                "Flight monitoring initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[EVENT LOG] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   17.3 INITIALIZE MISSION BAR
   ------------------------------------------------------------ */

async function initializeMissionBar(enabled) {

    if (!enabled) {

        console.info("[MISSION BAR] Disabled by configuration.");
        return;

    }

    try {

        const module = await import(
            "./modules/missionBar/missionBar.js"
        );

        const container = document.getElementById(
            "missionBarContainer"
        );

        const initialized = await module.initMissionBar(
            container
        );

        if (initialized) {

            missionBarModule = module;

            if (pendingMissionData) {

                module.updateMissionBarData(
                    pendingMissionData
                );

            }

            logEvent(
                "Mission Bar initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[MISSION BAR] Initialization failed:",
            error
        );

    }

}

/* ------------------------------------------------------------
   INITIALIZE TELEMETRY GRAPHS
   ------------------------------------------------------------ */

async function initializeTelemetryGraphs(enabled) {

    if (!enabled) {

        console.info("[TELEMETRY GRAPHS] Disabled by configuration.");
        return;

    }

    try {

        const module = await import(
            "./modules/telemetryGraphs/telemetryGraphs.js"
        );

        const container = document.getElementById(
            "telemetryGraphsContainer"
        );

        const initialized = await module.initTelemetryGraphs(
            container
        );

        if (initialized) {

            telemetryGraphsModule = module;

            if (pendingMissionData) {

                module.updateTelemetryGraphsData(
                    pendingMissionData
                );

            }

            logEvent(
                "Telemetry Graphs initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[TELEMETRY GRAPHS] Initialization failed:",
            error
        );

    }

}

/* ------------------------------------------------------------
   INITIALIZE MISSION MONITOR
   ------------------------------------------------------------ */

async function initializeMissionMonitor(enabled) {

    if (!enabled) {

        console.info("[MISSION MONITOR] Disabled by configuration.");
        return;

    }

    try {

        const module = await import(
            "./modules/missionMonitor/missionMonitor.js"
        );

        const container = document.getElementById(
            "missionMonitorContainer"
        );

        const initialized = await module.initMissionMonitor(
            container
        );

        if (initialized) {

            missionMonitorModule = module;

            if (pendingMissionData) {

                module.updateMissionMonitorData(
                    pendingMissionData
                );

            }

            module.updateMissionMonitorConnectionData(
                previousConnection === true
            );

            logEvent(
                "Mission Monitor initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[MISSION MONITOR] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   17.4 INITIALIZE FLIGHT RECORDER
   ------------------------------------------------------------ */

async function initializeFlightRecorder(enabled) {

    if (!enabled) {

        console.info(
            "[FLIGHT RECORDER] Disabled by configuration."
        );

        return;

    }

    try {

        const module = await import(
            "./modules/flightRecorder/flightRecorder.js"
        );

        const container = document.getElementById(
            "flightRecorderContainer"
        );

        const initialized = await module.initFlightRecorder(
            container,
            {
                onEvent: logEvent
            }
        );

        if (initialized) {

            logEvent(
                "Flight Recorder initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[FLIGHT RECORDER] Initialization failed:",
            error
        );

    }

}

/* ------------------------------------------------------------
   INITIALIZE PROJECT DATA
   ------------------------------------------------------------ */

async function initializeProjectData(enabled) {

    try {

        const { initProjectData } = await import(
            "./modules/projectData/projectData.js"
        );

        await initProjectData({
            systemInformationEnabled: enabled
        });

    } catch (error) {

        console.error(
            "[PROJECT DATA] Initialization failed:",
            error
        );

    }

}

/* ------------------------------------------------------------
   initialize System Diagnostics
   ------------------------------------------------------------ */

async function initializeSystemDiagnostics(enabled) {
    if (!enabled) return;

    try {
        const { initSystemDiagnostics } = await import(
            "./modules/systemDiagnostics/systemDiagnostics.js"
        );

        const container = document.getElementById(
            "systemDiagnosticsContainer"
        );

        systemDiagnosticsModule = await initSystemDiagnostics(container);

        if (systemDiagnosticsModule) {
            logEvent("System Diagnostics module initialized.", "success");
        }

    } catch (error) {
        console.error("[SYSTEM DIAGNOSTICS] Initialization failed:", error);
    }
}

/* ------------------------------------------------------------
   17.5 INITIALIZE ALL MODULES
   ------------------------------------------------------------ */

async function initializeModules() {

    const configuration =
        await loadModuleConfiguration();

    const modules =
        configuration.modules || {};

    // Initialize Event Log first so other modules
    // can send notifications to it.

    await initializeEventLog(
        modules.eventLog === true
    );

    await initializeProjectData(
        modules.systemInformation === true
    );

    await initializeMissionBar(
        modules.missionBar === true
    );

    await initializeMissionMonitor(
        modules.missionMonitor === true
    );

    await initializeFlightRecorder(
        modules.flightRecorder === true
    );

    await initializeSystemDiagnostics(
        modules.systemDiagnostics === true
    );

    await initializeTelemetryGraphs(
        modules.telemetryGraphs === true
    );

}


/* ============================================================
   18. APPLICATION INITIALIZATION
   ============================================================ */

// INITIALIZE MODULES

initializeModules();


// START TELEMETRY

updateTelemetry();


// START REFRESH LOOP

setInterval(
    updateTelemetry,
    REFRESH_RATE_MS
);


// START CONNECTION MONITOR

setInterval(
    updateConnectionStatus,
    100
);


// GRAPH RESIZE HANDLER

window.addEventListener(
    "resize",
    () => {
        if (telemetryGraphsModule) {
            telemetryGraphsModule.drawTelemetryGraphsOnResize();
        }
    }
);

/* ============================================================
   END OF FLIGHT TELEMETRY MONITOR
   ============================================================ */