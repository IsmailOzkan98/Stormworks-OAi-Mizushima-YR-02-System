
/* ============================================================
   OAI MIZUSHIMA YR-02
   FLIGHT DATA RECORDER MODULE

   VERSION: 1.0.0

   RESPONSIBILITY:
   Flight data recording control, status monitoring,
   recorder interface and event notifications.

   API:
   - initFlightRecorder()
   - startFlightRecording()
   - stopFlightRecording()
   - refreshRecorderStatus()

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

let startButton = null;
let stopButton = null;
let statusElement = null;


/* ============================================================
   03. EVENT NOTIFICATION
   ============================================================ */

function notify(message, type = "normal") {

    if (typeof window.logEvent === "function") {

        window.logEvent(message, type);

    } else {

        console.log("[FLIGHT RECORDER]", message);

    }

}


/* ============================================================
   04. RECORDER INTERFACE
   ============================================================ */

function updateRecorderInterface(
    isRecording,
    filename = null
) {

    recording = Boolean(isRecording);

    currentFilename = filename || null;


    // BUTTON STATES

    if (startButton) {

        startButton.disabled = recording;

    }

    if (stopButton) {

        stopButton.disabled = !recording;

    }


    // STATUS DISPLAY

    if (!statusElement) return;


    if (recording) {

        statusElement.textContent =
            "● RECORDING " + (currentFilename || "");

        statusElement.classList.add("recording");

    } else {

        statusElement.textContent =
            "RECORDER STANDBY";

        statusElement.classList.remove("recording");

    }

}


/* ============================================================
   05. START RECORDING
   ============================================================ */

export async function startFlightRecording() {

    if (recording) return;

    if (startButton) {

        startButton.disabled = true;

    }


    try {

        const response = await fetch(
            `${RECORDER_API}/start`,
            {
                method: "POST"
            }
        );


        const result = await response.json();


        if (!response.ok) {

            throw new Error(
                result.message || "Start failed"
            );

        }


        updateRecorderInterface(
            true,
            result.filename
        );


        notify(
            "Flight data recording started: " + result.filename,
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

    if (stopButton) {

        stopButton.disabled = true;

    }


    try {

        const response = await fetch(
            `${RECORDER_API}/stop`,
            {
                method: "POST"
            }
        );


        const result = await response.json();


        if (!response.ok) {

            throw new Error(
                result.message || "Stop failed"
            );

        }


        updateRecorderInterface(false);


        notify(
            "Flight data recording saved: " + result.filename,
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
            "[FLIGHT RECORDER] Status error:",
            error
        );

    }

}


/* ============================================================
   08. MODULE INITIALIZATION
   ============================================================ */

export async function initFlightRecorder() {

    if (initialized) return;

    initialized = true;


    // DOM REFERENCES

    startButton =
        document.getElementById("startRecording");

    stopButton =
        document.getElementById("stopRecording");

    statusElement =
        document.getElementById("recorderStatus");


    // VALIDATE INTERFACE

    if (
        !startButton ||
        !stopButton ||
        !statusElement
    ) {

        console.error(
            "[FLIGHT RECORDER] Required DOM elements not found."
        );

        initialized = false;

        return;

    }


    // BUTTON EVENTS

    startButton.addEventListener(
        "click",
        startFlightRecording
    );

    stopButton.addEventListener(
        "click",
        stopFlightRecording
    );


    // INITIAL STATUS

    await refreshRecorderStatus();


    console.log(
        "[FLIGHT RECORDER] Module initialized."
    );

}


/* ============================================================
   END OF FLIGHT RECORDER MODULE
   ============================================================ */
