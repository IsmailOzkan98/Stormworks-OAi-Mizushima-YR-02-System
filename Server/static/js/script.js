/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT TELEMETRY MONITOR

   VERSION: 2.1.0

   RESPONSIBILITY:
   Flight telemetry reception, visualization, diagnostics,
   connection monitoring and event logging.

   ARCHITECTURE:
   - Centralized application state
   - Modular initialization
   - Separated interface rendering
   - Independent connection monitoring
   - Rolling telemetry updates
   - Dynamic module loading

   ============================================================ */


/* ============================================================
   01. MODULE REFERENCES
   ============================================================ */

let missionBarModule = null;
let missionMonitorModule = null;
let systemDiagnosticsModule = null;
let telemetryGraphsModule = null;
let connectionManagerModule = null;
let pendingMissionData = null;
let systemEventDetectorModule = null;
let cardsModule = null;


/* ============================================================
   02. SYSTEM CONFIGURATION
   ============================================================ */

const CONFIG = Object.freeze({

    DIRECTION_PULSE_MS: 1500,

    CONFIG_ENDPOINT: "/static/config.json"

});


/* ============================================================
   03. APPLICATION STATE
   ============================================================ */

const state = {

    previousConnection: null,

    latestTelemetryTimestamp: 0,

    directionTimers: {},

    logEvent(message, type = "normal") {
        console.log(`[${type.toUpperCase()}]`, message);
    }

};


/* ============================================================
   04. SYSTEM DEFINITIONS
   ============================================================ */

const SYSTEMS = [

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

const DIRECTIONS = [

    "north",
    "east",
    "south",
    "west"

];


/* ============================================================
   05. TELEMETRY UTILITIES
   ============================================================ */


/* ------------------------------------------------------------
   05.1 NUMERICAL VALIDATION
   ------------------------------------------------------------ */

function getNumericValue(data, key) {

    const rawValue = data?.[key];

    if (
        rawValue === null ||
        rawValue === undefined ||
        rawValue === ""
    ) {
        return null;
    }

    const value = Number(rawValue);

    return Number.isFinite(value)
        ? value
        : null;

}


/* ------------------------------------------------------------
   05.2 NUMBER FORMATTING
   ------------------------------------------------------------ */

function number(data, key, decimals = 1) {

    const value = getNumericValue(data, key);

    return value !== null
        ? value.toFixed(decimals)
        : "--";

}


/* ------------------------------------------------------------
   05.3 SYSTEM ACTIVATION
   ------------------------------------------------------------ */

function isActive(data, key) {

    const value = data?.[key];

    return (
        value === "1" ||
        value === 1 ||
        value === true ||
        value === "true"
    );

}


/* ============================================================
   06. DOM HELPERS
   ============================================================ */


/* ------------------------------------------------------------
   06.1 UPDATE TEXT
   ------------------------------------------------------------ */

function setValue(id, value) {

    const element = document.getElementById(id);

    if (!element) return;

    element.textContent = value;

}


/* ------------------------------------------------------------
   06.2 UPDATE INDICATORS
   ------------------------------------------------------------ */

function setIndicator(id, active) {

    const element = document.getElementById(id);

    if (!element) return;

    element.classList.toggle("active", active);

}


/* ============================================================
   07. CONNECTION MANAGER
   ============================================================ */
async function initializeConnectionManager() {

    try {

        const { initConnectionManager } = await import(
            "./modules/connectionManager/connectionManager.js"
        );

        connectionManagerModule = initConnectionManager({

            onTelemetry(data) {

                state.latestTelemetryTimestamp =
                    Number(data.timestamp);

                // DETECT SYSTEM EVENTS
                if (systemEventDetectorModule) {

                    systemEventDetectorModule.processTelemetry(data);

                }

                // UPDATE INTERFACE
                updateInterface(data);

            },

            onTelemetryConnectionChange(online) {

                setConnection(
                    online,
                    online
                        ? "Telemetría recibida"
                        : "Telemetría detenida"
                );

            },

            onPacketAge(age) {

                if (missionMonitorModule) {

                    missionMonitorModule
                        .updateMissionMonitorPacketAge(age);

                }

            }

        });

    } catch (error) {

        console.error(
            "[CONNECTION MANAGER] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   07.1 UPDATE CONNECTION STATE
   ------------------------------------------------------------ */

function setConnection(online, detail) {

    const light = document.getElementById("onlineLight");

    if (light) {
        light.classList.toggle("online", online);
    }

    setValue("onlineText", online ? "ONLINE" : "OFFLINE");
    setValue("connectionDetail", detail);

    if (missionMonitorModule) {
        missionMonitorModule.updateMissionMonitorConnectionData(online);
    }

    if (
        state.previousConnection !== null &&
        state.previousConnection !== online
    ) {
        state.logEvent(
            online
                ? "Telemetry connection restored."
                : "Telemetry connection lost.",
            online ? "navigation-event" : "error"
        );
    }

    state.previousConnection = online;
}


/* ============================================================
   08. DIRECTIONAL BOOSTER EFFECTS
   ============================================================ */


/* ------------------------------------------------------------
   08.1 BOOSTER PULSE
   ------------------------------------------------------------ */

function pulseDirection(id, active) {

    if (!active) return;

    const indicator = document.getElementById(id);

    if (!indicator) return;

    const booster = indicator.closest(".booster");

    if (!booster) return;


    booster.classList.add("pulse");


    // CLEAR PREVIOUS TIMER

    clearTimeout(state.directionTimers[id]);


    // REMOVE PULSE

    state.directionTimers[id] = setTimeout(() => {

        booster.classList.remove("pulse");

        delete state.directionTimers[id];

    }, CONFIG.DIRECTION_PULSE_MS);

}


/* ------------------------------------------------------------
   09.8 MODULE DATA
   ------------------------------------------------------------ */

function renderModules(data) {

    if (missionBarModule) {

        missionBarModule.updateMissionBarData(data);

    }

    if (missionMonitorModule) {

        missionMonitorModule.updateMissionMonitorData(data);

    }

    if (systemDiagnosticsModule) {

        systemDiagnosticsModule.updateSystemDiagnostics(data);

    }

    if (telemetryGraphsModule) {

        telemetryGraphsModule.updateTelemetryGraphsData(data);

    }

    if (cardsModule) {

        cardsModule.updateCards(data);

    }

}


/* ------------------------------------------------------------
   09.9 LAST UPDATE
   ------------------------------------------------------------ */

function renderLastUpdate() {

    setValue(

        "lastUpdate",

        new Date(
            state.latestTelemetryTimestamp * 1000
        ).toLocaleTimeString()

    );

}


/* ------------------------------------------------------------
   09.10 COMPLETE INTERFACE UPDATE
   ------------------------------------------------------------ */

function updateInterface(data) {

    pendingMissionData = data;


    renderModules(data);

    renderEngine(data);

    renderAttitude(data);

    renderSpeed(data);

    renderNavigation(data);

    renderAutopilot(data);

    renderControls(data);

    renderDiagnostics(data);

    renderLastUpdate();

}



/* ============================================================
   11. MODULE INITIALIZATION
   ============================================================ */


/* ------------------------------------------------------------
   11.1 LOAD CONFIGURATION
   ------------------------------------------------------------ */

async function loadModuleConfiguration() {

    try {

        const response = await fetch(

            CONFIG.CONFIG_ENDPOINT,

            {
                cache: "no-store"
            }

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


        // SAFE FALLBACK

        return {

            modules: {

                eventLog: false,
                flightRecorder: false,
                missionBar: false,
                missionMonitor: false,
                systemDiagnostics: false,
                telemetryGraphs: false,
                systemInformation: false,
                cardsModule: false

            }

        };

    }

}


/* ------------------------------------------------------------
   11.2 INITIALIZE EVENT LOG
   ------------------------------------------------------------ */

async function initializeEventLog(enabled) {

    if (!enabled) {

        console.info(
            "[EVENT LOG] Disabled by configuration."
        );

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

            state.logEvent = eventLogger;

            state.logEvent(
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
   11.2.1 INITIALIZE SYSTEM EVENT DETECTOR
   ------------------------------------------------------------ */

async function initializeSystemEventDetector(enabled) {

    if (!enabled) {

        console.info(
            "[SYSTEM EVENT DETECTOR] Disabled."
        );

        return;

    }

    try {

        const { initSystemEventDetector } = await import(
            "./modules/systemEventDetector/systemEventDetector.js"
        );

        systemEventDetectorModule =
            initSystemEventDetector(state.logEvent);

        if (systemEventDetectorModule) {

            state.logEvent(
                "System Event Detector initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[SYSTEM EVENT DETECTOR] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   11.3 GENERIC MODULE INITIALIZER
   ------------------------------------------------------------ */

async function initializeModule({

    name,

    enabled,

    path,

    containerId,

    initFunction,

    initOptions = undefined,

    onReady

}) {

    if (!enabled) {

        console.info(
            `[${name}] Disabled by configuration.`
        );

        return null;

    }


    try {

        const module = await import(path);


        const container = document.getElementById(
            containerId
        );


        const initialized = await module[initFunction](
            container,
            initOptions
        );


        if (!initialized) {

            console.warn(
                `[${name}] Initialization returned no instance.`
            );

            return null;

        }


        // EXECUTE MODULE-SPECIFIC SETUP

        if (onReady) {

            onReady(module, initialized);

        }


        state.logEvent(
            `${name} initialized.`,
            "system-event"
        );


        return module;


    } catch (error) {

        console.error(
            `[${name}] Initialization failed:`,
            error
        );

        return null;

    }

}


/* ------------------------------------------------------------
   11.4 MISSION BAR
   ------------------------------------------------------------ */

async function initializeMissionBar(enabled) {

    missionBarModule = await initializeModule({

        name: "MISSION BAR",

        enabled,

        path: "./modules/missionBar/missionBar.js",

        containerId: "missionBarContainer",

        initFunction: "initMissionBar",

        onReady(module) {

            if (pendingMissionData) {

                module.updateMissionBarData(
                    pendingMissionData
                );

            }

        }

    });

}


/* ------------------------------------------------------------
   11.5 MISSION MONITOR
   ------------------------------------------------------------ */

async function initializeMissionMonitor(enabled) {

    missionMonitorModule = await initializeModule({

        name: "MISSION MONITOR",

        enabled,

        path: "./modules/missionMonitor/missionMonitor.js",

        containerId: "missionMonitorContainer",

        initFunction: "initMissionMonitor",

        onReady(module) {

            if (pendingMissionData) {

                module.updateMissionMonitorData(
                    pendingMissionData
                );

            }

            module.updateMissionMonitorConnectionData(
                state.previousConnection === true
            );

            if (state.latestTelemetryTimestamp) {

                const age = Date.now() -
                    state.latestTelemetryTimestamp * 1000;

                module.updateMissionMonitorPacketAge(
                    Math.max(0, Math.round(age))
                );

            }

        }

    });

}


/* ------------------------------------------------------------
   11.6 TELEMETRY GRAPHS
   ------------------------------------------------------------ */

async function initializeTelemetryGraphs(enabled) {

    telemetryGraphsModule = await initializeModule({

        name: "TELEMETRY GRAPHS",

        enabled,

        path: "./modules/telemetryGraphs/telemetryGraphs.js",

        containerId: "telemetryGraphsContainer",

        initFunction: "initTelemetryGraphs",

        onReady(module) {

            if (pendingMissionData) {

                module.updateTelemetryGraphsData(
                    pendingMissionData
                );

            }

        }

    });

}


/* ------------------------------------------------------------
   11.7 FLIGHT RECORDER
   ------------------------------------------------------------ */

async function initializeFlightRecorder(enabled) {

    await initializeModule({

        name: "FLIGHT RECORDER",

        enabled,

        path: "./modules/flightRecorder/flightRecorder.js",

        containerId: "flightRecorderContainer",

        initFunction: "initFlightRecorder",

        initOptions: {
            onEvent: state.logEvent
        }

    });

}


/* ------------------------------------------------------------
   11.8 SYSTEM DIAGNOSTICS
   ------------------------------------------------------------ */

async function initializeSystemDiagnostics(enabled) {

    if (!enabled) {

        console.info(
            "[SYSTEM DIAGNOSTICS] Disabled by configuration."
        );

        return;

    }


    try {

        const { initSystemDiagnostics } = await import(

            "./modules/systemDiagnostics/systemDiagnostics.js"

        );


        const container = document.getElementById(
            "systemDiagnosticsContainer"
        );


        systemDiagnosticsModule =
            await initSystemDiagnostics(container);


        if (systemDiagnosticsModule) {

            if (pendingMissionData) {

                systemDiagnosticsModule.updateSystemDiagnostics(
                    pendingMissionData
                );

            }

            state.logEvent(
                "System Diagnostics initialized.",
                "success"
            );

        }


    } catch (error) {

        console.error(
            "[SYSTEM DIAGNOSTICS] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   11.9 PROJECT DATA
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
   11.10 INITIALIZE CARDS
   ------------------------------------------------------------ */

async function initializeCards(enabled) {

    if (!enabled) {

        console.info(
            "[CARDS] Disabled by configuration."
        );

        return;

    }

    try {

        const { initCards } = await import(
            "./modules/cards/cards.js"
        );

        const container = document.getElementById(
            "cardsContainer"
        );

        if (!container) {

            throw new Error(
                "cardsContainer element not found."
            );

        }

        cardsModule = await initCards(container);

        if (cardsModule) {

            if (pendingMissionData) {

                cardsModule.updateCards(
                    pendingMissionData
                );

            }

            state.logEvent(
                "Cards initialized.",
                "system-event"
            );

        }

    } catch (error) {

        console.error(
            "[CARDS] Initialization failed:",
            error
        );

    }

}


/* ------------------------------------------------------------
   11.11 INITIALIZE ALL MODULES
   ------------------------------------------------------------ */

async function initializeModules() {

    const configuration =
        await loadModuleConfiguration();


    // DASHBOARD ASSEMBLER

    if (configuration.dashboard) {

        const { initializeDashboardAssembler } = await import(
            "./core/dashboardAssembler.js"
        );

        initializeDashboardAssembler(
            configuration.dashboard
        );

    }


    const modules =
        configuration.modules || {};


    // EVENT LOG MUST INITIALIZE FIRST

    await initializeEventLog(
        modules.eventLog === true
    );

    // SYSTEM EVENT DETECTOR

    await initializeSystemEventDetector(
        modules.eventLog === true
    );


    // PROJECT DATA

    await initializeProjectData(
        modules.systemInformation === true
    );


    // INITIALIZE INDEPENDENT MODULES

    await Promise.all([

        initializeMissionBar(
            modules.missionBar === true
        ),

        initializeMissionMonitor(
            modules.missionMonitor === true
        ),

        initializeFlightRecorder(
            modules.flightRecorder === true
        ),

        initializeSystemDiagnostics(
            modules.systemDiagnostics === true
        ),

        initializeTelemetryGraphs(
            modules.telemetryGraphs === true
        ),

        initializeCards(
            modules.cardsModule === true
        )

    ]);

}


/* ============================================================
   12. APPLICATION STARTUP
   ============================================================ */


/* ------------------------------------------------------------
   12.1 GRAPH RESIZE HANDLER
   ------------------------------------------------------------ */

function initializeResizeHandler() {

    window.addEventListener("resize", () => {

        if (telemetryGraphsModule) {

            telemetryGraphsModule.drawTelemetryGraphsOnResize();

        }

    });

}


/* ------------------------------------------------------------
   12.3 APPLICATION INITIALIZATION
   ------------------------------------------------------------ */


async function initializeApplication() {

    console.info(
        "[SYSTEM] Initializing OAI MIZUSHIMA YR-02..."
    );

    // Initialize application modules
    await initializeModules();

    // Initialize independent connection services
    await initializeConnectionManager();

    // Initialize graph resize handling
    initializeResizeHandler();

    console.info(
        "[SYSTEM] Flight Telemetry Monitor initialized."
    );

}

initializeApplication().catch(error => {

    console.error(
        "[SYSTEM] Application initialization failed:",
        error
    );

});



/* ============================================================
   END OF OAI MIZUSHIMA YR-02
   FLIGHT TELEMETRY MONITOR
   ============================================================ */