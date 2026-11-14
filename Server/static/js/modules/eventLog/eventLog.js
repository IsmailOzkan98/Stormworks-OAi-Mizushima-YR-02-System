
/* ============================================================
   OAI MIZUSHIMA YR-02
   EVENT LOG MODULE

   VERSION: 1.1.0

   RESPONSIBILITY:
   Event creation, formatting and display.

   API:
   - initEventLog(container)
   - Returns logEvent(message, type)
   ============================================================ */


/* ============================================================
   01. MODULE CONFIGURATION
   ============================================================ */

const MAX_EVENTS = 30;


/* ============================================================
   02. MODULE INITIALIZATION
   ============================================================ */

export function initEventLog(container) {

    if (!container) {

        console.warn(
            "[EVENT LOG] Container not found."
        );

        return null;
    }


    /* --------------------------------------------------------
       CREATE MODULE INTERFACE
       -------------------------------------------------------- */

    container.innerHTML = `
        <div class="section-heading">
            <span>01</span> EVENT RECORDER
        </div>

        <div class="event-panel">

            <div class="event-header">
                <span>FLIGHT EVENT LOG</span>
                <span>LIVE</span>
            </div>

            <div class="event-list" id="eventLog">

                <div class="event-entry system-event">
                    <span class="event-time">SYSTEM</span>
                    <span>Monitoring system initialized.</span>
                </div>

                <div class="event-entry">
                    <span class="event-time">SYSTEM</span>
                    <span>Waiting for telemetry packets...</span>
                </div>

            </div>

        </div>
    `;


    /* --------------------------------------------------------
       DOM REFERENCES
       -------------------------------------------------------- */

    const eventLogElement =
        container.querySelector("#eventLog");


    if (!eventLogElement) {

        console.error(
            "[EVENT LOG] Interface creation failed."
        );

        return null;
    }


    /* ========================================================
       03. LOG EVENT
       ======================================================== */

    function logEvent(message, type = "normal") {

        if (!eventLogElement.isConnected) {

            console.warn(
                "[EVENT LOG]",
                message
            );

            return;
        }


        // CREATE EVENT ENTRY

        const entry =
            document.createElement("div");

        entry.className =
            `event-entry ${type}`;


        // EVENT TIME

        const time =
            document.createElement("span");

        time.className = "event-time";

        time.textContent =
            new Date().toLocaleTimeString();


        // EVENT MESSAGE

        const content =
            document.createElement("span");

        content.textContent = message;


        // ADD CONTENT

        entry.append(
            time,
            content
        );


        // INSERT NEW EVENT

        eventLogElement.prepend(entry);


        // ENFORCE EVENT LIMIT

        while (
            eventLogElement.children.length > MAX_EVENTS
        ) {

            eventLogElement.lastElementChild.remove();

        }

    }


    /* ========================================================
       04. MODULE READY
       ======================================================== */

    console.info(
        "[EVENT LOG] Module initialized."
    );


    return logEvent;

}


/* ============================================================
   END OF MODULE
   ============================================================ */
