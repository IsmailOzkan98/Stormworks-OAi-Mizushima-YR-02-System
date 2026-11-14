const CONFIG_URL = new URL("./missionBar.json", import.meta.url);

let config = null;
let container = null;
let latestData = null;

async function loadConfiguration() {
    const response = await fetch(CONFIG_URL, { cache: "no-store" });

    if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
    }

    config = await response.json();
}

function createMissionBar() {

    container = document.querySelector(".mission-status-bar");

    if (!container) return;

    container.hidden = config.enabled === false;

    if (config.enabled === false) return;

    container.replaceChildren();

    const stage = document.createElement("div");
    stage.className = "mission-stage";

    const data = document.createElement("div");
    data.className = "mission-data";

    config.items.forEach(item => {

        if (item.enabled === false) return;

        const label = document.createElement("span");
        label.className = "micro-label";
        label.textContent = item.label ?? "";

        const value = document.createElement("strong");
        value.id = `mission-${item.id}`;
        value.textContent = item.default ?? "--";

        if (item.class === "mission-stage") {

            stage.append(label, value);

        } else {

            const block = document.createElement("div");

            block.append(label, value);

            if (item.type === "status") {
                value.classList.add("state-pill", "idle");
            }

            data.appendChild(block);

        }

    });

    container.append(stage, data);
}

function formatValue(item, data) {
    const rawValue = data[item.source];

    if (rawValue === null || rawValue === undefined || rawValue === "") {
        return item.default ?? "--";
    }

    switch (item.type) {
        case "number": {
            const number = Number(rawValue);

            return Number.isFinite(number)
                ? number.toFixed(item.decimals ?? 1)
                : item.default ?? "--";
        }

        case "rxTxState": {
            const states = config.states?.rxTxState ?? {};

            return states[String(rawValue)] ?? states.unknown ?? "UNKNOWN";
        }

        case "status": {
            const status = String(rawValue).toLowerCase();
            const statuses = config.states?.flightStatus ?? {};
            return statuses[status] ?? String(rawValue).toUpperCase();
        }

        default:
            return String(rawValue);
    }
}

function updateMissionBar(data) {
    if (!config || !container || config.enabled === false) return;

    config.items.forEach(item => {
        if (item.enabled === false) return;

        const element = document.getElementById(`mission-${item.id}`);

        if (!element) return;

        element.textContent = formatValue(item, data);

        if (item.type === "status") {
            const status = String(data[item.source] ?? "idle").toLowerCase();
            const validStatuses = config.states?.flightStatus ?? {};

            element.className = "state-pill";

            element.classList.add(
                Object.hasOwn(validStatuses, status) ? status : "idle"
            );
        }
    });
}

export function updateMissionBarData(data) {
    if (!data) return;

    latestData = data;

    if (config) {
        updateMissionBar(data);
    }
}

export async function initMissionBar() {
    try {
        await loadConfiguration();

        createMissionBar();

        if (latestData) {
            updateMissionBar(latestData);
        }

        console.info("[MISSION BAR] Configuration loaded.");

    } catch (error) {
        console.error("[MISSION BAR] Configuration error:", error);
    }
}