
/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT DATA RECORDER MODULE

   VERSION: 1.1.0
   ============================================================ */


/* ============================================================
   01. MODULE CONFIGURATION
   ============================================================ */

const RECORDER_API = "/api/recorder";


/* ============================================================
   02. MODULE STATE
   ============================================================ */

let initialized = false;
let recording = false;
let currentFilename = null;

let container = null;
let recorderButton = null;
let statusElement = null;

let onEvent = (message, type = "normal") => {
    console.log("[FLIGHT RECORDER]", message);
};


/* ============================================================
   03. EVENT NOTIFICATION
   ============================================================ */

function notify(message, type = "normal") {
    onEvent(message, type);
}


/* ============================================================
   04. RECORDER INTERFACE
   ============================================================ */

function updateRecorderInterface(isRecording, filename = null) {

    recording = Boolean(isRecording);
    currentFilename = filename || null;

    if (!recorderButton) return;

    recorderButton.disabled = false;

    if (recording) {

        recorderButton.innerHTML = `
            <span class="recorder-dot"></span>
            STOP
        `;

        recorderButton.className = "recorder-btn stop";

    } else {

        recorderButton.innerHTML = `
            <span class="recorder-dot"></span>
            START
        `;

        recorderButton.className = "recorder-btn start";

    }

    if (!statusElement) return;

    if (recording) {

        statusElement.textContent =
            "● RECORDING " + (currentFilename || "");

        statusElement.classList.add("recording");

    } else {

        statusElement.textContent = "RECORDER STANDBY";
        statusElement.classList.remove("recording");

    }
}


/* ============================================================
   05. START RECORDING
   ============================================================ */

export async function startFlightRecording() {

    if (recording) return;

    if (recorderButton) {
        recorderButton.disabled = true;
    }

    try {

        const response = await fetch(
            `${RECORDER_API}/start`,
            { method: "POST" }
        );

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || "Start failed");
        }

        updateRecorderInterface(true, result.filename);

        notify(
            "Flight data recording started: " + (result.filename || ""),
            "activation"
        );

    } catch (error) {

        updateRecorderInterface(false);

        notify(
            "Recorder start error: " + error.message,
            "error"
        );

    }
}


/* ============================================================
   06. STOP RECORDING
   ============================================================ */

export async function stopFlightRecording() {

    if (!recording) return;

    if (recorderButton) {
        recorderButton.disabled = true;
    }

    try {

        const response = await fetch(
            `${RECORDER_API}/stop`,
            { method: "POST" }
        );

        const result = await response.json();

        if (!response.ok) {
            throw new Error(result.message || "Stop failed");
        }

        updateRecorderInterface(false);

        notify(
            "Flight data recording saved: " + (result.filename || ""),
            "activation"
        );

    } catch (error) {

        notify(
            "Recorder stop error: " + error.message,
            "error"
        );

        await refreshRecorderStatus();

    }
}


/* ============================================================
   07. RECORDER STATUS
   ============================================================ */

export async function refreshRecorderStatus() {

    try {

        const response = await fetch(
            RECORDER_API,
            { cache: "no-store" }
        );

        if (!response.ok) return;

        const result = await response.json();

        updateRecorderInterface(
            result.recording,
            result.filename
        );

    } catch (error) {

        console.error(
            "[FLIGHT RECORDER] Status error:",
            error
        );

    }
}


/* ============================================================
   08. MODULE INTERFACE
   ============================================================ */

function createRecorderInterface() {

    container.innerHTML = `
        <section class="recorder-panel">

            <span class="section-header module-header">
                TELEMETRY RECORDER
            </span>

            <div class="recorder-buttons">

                <button
                    id="recorderToggle"
                    class="recorder-btn start"
                    type="button"
                >
                    <span class="recorder-dot"></span>
                    START
                </button>

            </div>

            <span
                id="recorderStatus"
                class="recorder-status"
            >
                RECORDER STANDBY
            </span>

        </section>
    `;

    recorderButton =
        container.querySelector("#recorderToggle");

    statusElement =
        container.querySelector("#recorderStatus");
}

async function toggleRecording() {

    if (recording) {
        await stopFlightRecording();
    } else {
        await startFlightRecording();
    }
}


/* ============================================================
   09. MODULE INITIALIZATION
   ============================================================ */

export async function initFlightRecorder(targetContainer, options = {}) {

    if (initialized) return true;

    if (!targetContainer) {

        console.error(
            "[FLIGHT RECORDER] Container not found."
        );

        return false;
    }

    container = targetContainer;

    if (typeof options.onEvent === "function") {
        onEvent = options.onEvent;
    }

    createRecorderInterface();

    if (!recorderButton || !statusElement) {

        console.error(
            "[FLIGHT RECORDER] Required DOM elements not found."
        );

        return false;
    }

    recorderButton.addEventListener(
        "click",
        toggleRecording
    );

    initialized = true;

    await refreshRecorderStatus();

    notify("Flight Recorder initialized.", "system-event");

    console.log("[FLIGHT RECORDER] Module initialized.");

    return true;
}


/* ============================================================
   END OF MODULE
   ============================================================ */
