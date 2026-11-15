
/* ============================================================
   OAI MIZUSHIMA YR-02
   MODULE MANAGER
   ============================================================ */

import { state, modules } from "./state.js";


/* ============================================================
   01. SYSTEM CONFIGURATION
   ============================================================ */

const CONFIG = Object.freeze({

    CONFIG_ENDPOINT: "/static/config.json"

});


/* ============================================================
   02. MODULE REGISTRY
   ============================================================ */

const MODULE_REGISTRY = [

    {
        name: "MISSION BAR",
        key: "missionBar",
        configKey: "missionBar",
        path: "../modules/missionBar/missionBar.js",
        container: "missionBarContainer",
        initializer: "initMissionBar",
        updater: "updateMissionBarData"
    },

    {
        name: "MISSION MONITOR",
        key: "missionMonitor",
        configKey: "missionMonitor",
        path: "../modules/missionMonitor/missionMonitor.js",
        container: "missionMonitorContainer",
        initializer: "initMissionMonitor",
        updater: "updateMissionMonitorData",

        onReady(module) {

            if (state.pendingMissionData) {

                module.updateMissionMonitorData(
                    state.pendingMissionData
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

    },

    {
        name: "FLIGHT RECORDER",
        key: null,
        configKey: "flightRecorder",
        path: "../modules/flightRecorder/flightRecorder.js",
        container: "flightRecorderContainer",
        initializer: "initFlightRecorder",

        getOptions() {

            return {
                onEvent: state.logEvent
            };

        }

    },

    {
        name: "SYSTEM DIAGNOSTICS",
        key: "systemDiagnostics",
        configKey: "systemDiagnostics",
        path: "../modules/systemDiagnostics/systemDiagnostics.js",
        container: "systemDiagnosticsContainer",
        initializer: "initSystemDiagnostics",
        updater: "updateSystemDiagnostics"
    },

    {
        name: "TELEMETRY GRAPHS",
        key: "telemetryGraphs",
        configKey: "telemetryGraphs",
        path: "../modules/telemetryGraphs/telemetryGraphs.js",
        container: "telemetryGraphsContainer",
        initializer: "initTelemetryGraphs",
        updater: "updateTelemetryGraphsData"
    },

    {
        name: "CARDS",
        key: "cards",
        configKey: "cardsModule",
        path: "../modules/cards/cards.js",
        container: "cardsContainer",
        initializer: "initCards",
        updater: "updateCards"
    }

];


/* ============================================================
   03. LOAD CONFIGURATION
   ============================================================ */

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
   04. GENERIC MODULE INITIALIZATION
   ============================================================ */


async function initializeModule(definition) {

    const {
        name,
        configKey,
        path,
        container,
        initializer
    } = definition;

    try {

        const module = await import(path);

        const element = document.getElementById(container);

        const options = definition.getOptions
            ? definition.getOptions()
            : undefined;

        const initialized = await module[initializer](
            element,
            options
        );

        if (!initialized) {

            console.warn(
                `[${name}] Initialization returned no instance.`
            );

            return null;

        }

        // RESOLVE MODULE API

        const api = (
            typeof initialized === "object" &&
            initialized !== null
        )
            ? initialized
            : module;

        // REGISTER MODULE

        if (definition.key) {

            modules[definition.key] = api;

        }

        // MODULE-SPECIFIC SETUP

        if (definition.onReady) {

            definition.onReady(api, initialized);

        } else if (
            definition.updater &&
            state.pendingMissionData
        ) {

            api[definition.updater](
                state.pendingMissionData
            );

        }

        state.logEvent(
            `${name} initialized.`,
            "system-event"
        );

        return api;

    } catch (error) {

        console.error(
            `[${name}] Initialization failed:`,
            error
        );

        return null;

    }

}



/* ============================================================
   05. INITIALIZE REGISTERED MODULES
   ============================================================ */

async function initializeRegisteredModules(configuration) {

    const config = configuration.modules || {};

    await Promise.all(

        MODULE_REGISTRY.map(definition => {

            if (config[definition.configKey] !== true) {

                console.info(
                    `[${definition.name}] Disabled by configuration.`
                );

                return null;

            }

            return initializeModule(definition);

        })

    );

}


/* ============================================================
   06. INITIALIZE EVENT SYSTEM
   ============================================================ */

async function initializeEventLog(enabled) {

    if (!enabled) {

        console.info(
            "[EVENT LOG] Disabled by configuration."
        );

        return;

    }

    try {

        const { initEventLog } = await import(
            "../modules/eventLog/eventLog.js"
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


/* ============================================================
   07. INITIALIZE SYSTEM EVENT DETECTOR
   ============================================================ */

async function initializeSystemEventDetector(enabled) {

    if (!enabled) {

        console.info(
            "[SYSTEM EVENT DETECTOR] Disabled."
        );

        return;

    }

    try {

        const { initSystemEventDetector } = await import(
            "../modules/systemEventDetector/systemEventDetector.js"
        );

        modules.systemEventDetector =
            initSystemEventDetector(state.logEvent);

        if (modules.systemEventDetector) {

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
   08. PROJECT DATA
   ============================================================ */

async function initializeProjectData(enabled) {

    try {

        const { initProjectData } = await import(
            "../modules/projectData/projectData.js"
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
   09. APPLICATION MODULE ORCHESTRATION
   ============================================================ */

export async function initializeModules() {

    const configuration =
        await loadModuleConfiguration();


    // DASHBOARD ASSEMBLER

    if (configuration.dashboard) {

        try {

            const { initializeDashboardAssembler } = await import(
                "./dashboardAssembler.js"
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


    const config = configuration.modules || {};


    // EVENT SYSTEM MUST INITIALIZE FIRST

    await initializeEventLog(
        config.eventLog === true
    );

    // PRESERVE ORIGINAL INITIALIZATION CONDITION

    await initializeSystemEventDetector(
        config.eventLog === true
    );


    // PROJECT DATA

    await initializeProjectData(
        config.systemInformation === true
    );


    // INDEPENDENT MODULES

    await initializeRegisteredModules(configuration);

}


/* ============================================================
   END OF MODULE MANAGER
   ============================================================ */
