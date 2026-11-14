
/* ============================================================
   OAI MIZUSHIMA YR-02
   EVENT LOG MODULE

   RESPONSIBILITY:
   Event creation, formatting and display.
   ============================================================ */

let eventLogElement = null;

const MAX_EVENTS = 30;


/* ============================================================
   01. INITIALIZATION
   ============================================================ */

export function initEventLog() {

    eventLogElement =
        document.getElementById("eventLog");

    if (!eventLogElement) {

        console.warn(
            "[EVENT LOG] Event log element not found."
        );

        return false;

    }

    return true;

}


/* ============================================================
   02. LOG EVENT
   ============================================================ */

export function logEvent(
    message,
    type = "normal"
) {

    // GET EVENT LOG ELEMENT

    if (
        !eventLogElement ||
        !eventLogElement.isConnected
    ) {

        eventLogElement =
            document.getElementById("eventLog");

    }

    if (!eventLogElement) {

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

    eventLogElement.prepend(entry);


    // ENFORCE EVENT LIMIT

    while (
        eventLogElement.children.length > MAX_EVENTS
    ) {

        eventLogElement.lastElementChild.remove();

    }

}


