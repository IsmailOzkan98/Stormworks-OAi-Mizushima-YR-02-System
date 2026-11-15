
/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT TELEMETRY MONITOR

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
let systemEventDetectorModule = null;
let cardsModule = null;

let pendingMissionData = null;


/* ============================================================
   02. SYSTEM CONFIGURATION
   ============================================================ */

const CONFIG = Object.freeze({

    CONFIG_ENDPOINT: "/static/config.json"

});


/* ============================================================
   03. APPLICATION STATE
   ============================================================ */

const state = {

    previousConnection: null,

    latestTelemetryTimestamp: 0,

    logEvent(message, type = "normal") {

        console.log(`[${type.toUpperCase()}]`, message);

    }

};


/* ============================================================
   04. COMMON UTILITIES
   ============================================================ */


/* ------------------------------------------------------------
   04.1 UPDATE DOM TEXT
   ------------------------------------------------------------ */

function setValue(id, value) {

    const element = document.getElementById(id);

    if (!element) return;

    element.textContent = value;

}


/* ============================================================
   05. CONNECTION MANAGEMENT
   ============================================================ */


/* ------------------------------------------------------------
   05.1 UPDATE CONNECTION STATE
   ------------------------------------------------------------ */

function setConnection(online, detail) {

    const light = document.getElementById("onlineLight");

    if (light) {

        light.classList.toggle("online", online);

    }

    setValue("onlineText", online ? "ONLINE" : "OFFLINE");

    setValue("connectionDetail", detail);

    if (missionMonitorModule) {

        missionMonitorModule.updateMissionMonitorConnectionData(
            online
        );

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


/* ------------------------------------------------------------
   05.2 INITIALIZE CONNECTION MANAGER
   ------------------------------------------------------------ */

async function initializeConnectionManager() {

    try {

        const { initConnectionManager } = await import(
            "./modules/connectionManager/connectionManager.js"
        );

        connectionManagerModule = initConnectionManager({

            onTelemetry(data) {

                state.latestTelemetryTimestamp =
                    Number(data.timestamp);

                // PROCESS SYSTEM EVENTS

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


/* ============================================================
   06. TELEMETRY DATA MANAGEMENT
   ============================================================ */


/* ------------------------------------------------------------
   06.1 UPDATE APPLICATION DATA
   ------------------------------------------------------------ */

function updateInterface(data) {

    pendingMissionData = data;

    renderModules(data);

}


/* ------------------------------------------------------------
   06.2 RENDER MODULE DATA
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


/* ============================================================
   07. MODULE CONFIGURATION
   ============================================================ */


/* ------------------------------------------------------------
   07.1 LOAD CONFIGURATION
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


/* ============================================================
   08. EVENT SYSTEM INITIALIZATION
   ============================================================ */


/* ------------------------------------------------------------
   08.1 INITIALIZE EVENT LOG
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
   08.2 INITIALIZE SYSTEM EVENT DETECTOR
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


/* ============================================================
   09. GENERIC MODULE INITIALIZATION
   ============================================================ */


/* ------------------------------------------------------------
   09.1 GENERIC MODULE INITIALIZER
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


/* ============================================================
   10. APPLICATION MODULE INITIALIZERS
   ============================================================ */


/* ------------------------------------------------------------
   10.1 MISSION BAR
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
   10.2 MISSION MONITOR
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
   10.3 FLIGHT RECORDER
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
   10.4 SYSTEM DIAGNOSTICS
   ------------------------------------------------------------ */

async function initializeSystemDiagnostics(enabled) {

    systemDiagnosticsModule = await initializeModule({

        name: "SYSTEM DIAGNOSTICS",

        enabled,

        path: "./modules/systemDiagnostics/systemDiagnostics.js",

        containerId: "systemDiagnosticsContainer",

        initFunction: "initSystemDiagnostics",

        onReady(module) {

            if (pendingMissionData) {

                module.updateSystemDiagnostics(
                    pendingMissionData
                );

            }

        }

    });

}


/* ------------------------------------------------------------
   10.5 TELEMETRY GRAPHS
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
   10.6 CARDS
   ------------------------------------------------------------ */

async function initializeCards(enabled) {

    cardsModule = await initializeModule({

        name: "CARDS",

        enabled,

        path: "./modules/cards/cards.js",

        containerId: "cardsContainer",

        initFunction: "initCards",

        onReady(module) {

            if (pendingMissionData) {

                module.updateCards(
                    pendingMissionData
                );

            }

        }

    });

}


/* ------------------------------------------------------------
   10.7 PROJECT DATA
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


/* ============================================================
   11. APPLICATION MODULE ORCHESTRATION
   ============================================================ */



/* ------------------------------------------------------------
   11.1 INITIALIZE ALL MODULES
   ------------------------------------------------------------ */

async function initializeModules() {

    const configuration =
        await loadModuleConfiguration();


    // DASHBOARD ASSEMBLER

    if (configuration.dashboard) {

        try {

            const { initializeDashboardAssembler } = await import(
                "./core/dashboardAssembler.js"
            );

            await initializeDashboardAssembler(
                configuration.dashboard
            );

            console.info(
                "[DASHBOARD ASSEMBLER] Initialized successfully."
            );

        } catch (error) {

            console.error(
                "[DASHBOARD ASSEMBLER] Initialization failed:",
                error
            );

        }

    }


    const modules =
        configuration.modules || {};


    // EVENT SYSTEM MUST INITIALIZE FIRST

    await initializeEventLog(
        modules.eventLog === true
    );

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
   12. SYSTEM EVENT HANDLERS
   ============================================================ */


/* ------------------------------------------------------------
   12.1 GRAPH RESIZE HANDLER
   ------------------------------------------------------------ */

function initializeResizeHandler() {

    window.addEventListener("resize", () => {

        if (telemetryGraphsModule) {

            telemetryGraphsModule
                .drawTelemetryGraphsOnResize();

        }

    });

}


/* ============================================================
   13. APPLICATION STARTUP
   ============================================================ */


/* ------------------------------------------------------------
   13.1 APPLICATION INITIALIZATION
   ------------------------------------------------------------ */

async function initializeApplication() {

    console.info(
        "[SYSTEM] Initializing OAI MIZUSHIMA YR-02..."
    );

    // INITIALIZE APPLICATION MODULES

    await initializeModules();

    // INITIALIZE CONNECTION SERVICES

    await initializeConnectionManager();

    // INITIALIZE EVENT HANDLERS

    initializeResizeHandler();

    console.info(
        "[SYSTEM] Flight Telemetry Monitor initialized."
    );

}


/* ------------------------------------------------------------
   13.2 START APPLICATION
   ------------------------------------------------------------ */

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
