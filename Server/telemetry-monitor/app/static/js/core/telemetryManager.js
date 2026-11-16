
/* ============================================================
   OAI MIZUSHIMA YR-02
   TELEMETRY MANAGER
   ============================================================ */

import { state, modules} from "./state.js";


/* ============================================================
   01. CONNECTION MANAGEMENT
   ============================================================ */

export function setConnection(online, detail) {

    const light = document.getElementById("onlineLight");

    if (light) {

        light.classList.toggle("online", online);

    }

    setValue("onlineText", online ? "ONLINE" : "OFFLINE");

    setValue("connectionDetail", detail);

    if (modules.missionMonitor) {

        modules.missionMonitor.updateMissionMonitorConnectionData(
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


/* ============================================================
   02. TELEMETRY DATA MANAGEMENT
   ============================================================ */

export function updateInterface(data) {

    state.pendingMissionData = data;

    renderModules(data);

}


/* ============================================================
   03. MODULE DATA DISTRIBUTION
   ============================================================ */

function renderModules(data) {

    if (modules.missionBar) {

        modules.missionBar.updateMissionBarData(data);

    }

    if (modules.missionMonitor) {

        modules.missionMonitor.updateMissionMonitorData(data);

    }

    if (modules.systemDiagnostics) {

        modules.systemDiagnostics.updateSystemDiagnostics(data);

    }

    if (modules.telemetryGraphs) {

        modules.telemetryGraphs.updateTelemetryGraphsData(data);

    }

    if (modules.cards) {

        modules.cards.updateCards(data);

    }

}


/* ============================================================
   04. CONNECTION MANAGER INITIALIZATION
   ============================================================ */

export async function initializeTelemetry() {

    try {

        const { initConnectionManager } = await import(
            "../modules/connectionManager/connectionManager.js"
        );

        modules.connectionManager = initConnectionManager({

            onTelemetry(data) {

                state.latestTelemetryTimestamp =
                    Number(data.timestamp);

                // PROCESS SYSTEM EVENTS

                try {

                    modules.systemEventDetector?.processTelemetry(data);

                } catch (error) {

                    console.error(
                        "[SYSTEM EVENT DETECTOR] Processing failed:",
                        error
                    );

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

                if (modules.missionMonitor) {

                    modules.missionMonitor
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
   05. COMMON UTILITIES
   ============================================================ */

function setValue(id, value) {

    const element = document.getElementById(id);

    if (!element) return;

    element.textContent = value;

}


/* ============================================================
   END OF TELEMETRY MANAGER
   ============================================================ */
