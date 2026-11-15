
/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT TELEMETRY MONITOR
   MAIN APPLICATION ENTRY POINT
   ============================================================ */

import { state, modules } from "./core/state.js";

import {
    initializeModules
} from "./core/moduleManager.js";

import {
    initializeTelemetry
} from "./core/telemetryManager.js";


/* ============================================================
   01. SYSTEM EVENT HANDLERS
   ============================================================ */

function initializeResizeHandler() {

    window.addEventListener("resize", () => {

        if (modules.telemetryGraphs) {

            modules.telemetryGraphs
                .drawTelemetryGraphsOnResize();

        }

    });

}


/* ============================================================
   02. APPLICATION STARTUP
   ============================================================ */

async function initializeApplication() {

    console.info(
        "[SYSTEM] Initializing OAI MIZUSHIMA YR-02..."
    );

    // INITIALIZE APPLICATION MODULES

    await initializeModules();

    // INITIALIZE CONNECTION SERVICES

    await initializeTelemetry();

    // INITIALIZE EVENT HANDLERS

    initializeResizeHandler();

    console.info(
        "[SYSTEM] Flight Telemetry Monitor initialized."
    );

}


/* ============================================================
   03. START APPLICATION
   ============================================================ */

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
