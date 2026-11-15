const CONFIG_URL = new URL("./cards.json", import.meta.url);

export async function initCards(container) {
    if (!container) {
        console.error("[CARDS] Container not found.");
        return null;
    }

    let config;

    try {
        const response = await fetch(CONFIG_URL);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }

        config = await response.json();
    } catch (error) {
        console.error("[CARDS] Failed to load configuration:", error);
        return null;
    }

    const cardElements = new Map();

    // ----------------------------------------
    // GENERATE HTML
    // ----------------------------------------

    function renderCards() {
        container.innerHTML = "";
        cardElements.clear();

        if (!Array.isArray(config.sections)) {
            console.error("[CARDS] Invalid sections configuration.");
            return;
        }

        config.sections.forEach(section => {
            const sectionElement = document.createElement("section");
            sectionElement.className = "dashboard-section";
            sectionElement.id = `section-${section.id}`;

            // Section heading
            const heading = document.createElement("div");
            heading.className = "section-heading";

            const number = document.createElement("span");
            number.textContent = section.title?.number ?? "";

            heading.appendChild(number);
            heading.append(
                document.createTextNode(` ${section.title?.name ?? ""}`)
            );

            sectionElement.appendChild(heading);

            // Metric grid
            const grid = document.createElement("div");
            grid.className = "metric-grid";

            (section.cards ?? []).forEach(card => {
                const cardElement = document.createElement("div");
                cardElement.className = "card";

                if (card.style === "highlight") {
                    cardElement.classList.add("highlight");
                } else if (card.style === "cyan") {
                    cardElement.classList.add("cyan");
                }

                const label = document.createElement("div");
                label.className = "card-label";
                label.textContent = card.label ?? "";

                const value = document.createElement("div");
                value.className = "value";
                value.id = card.id;
                value.textContent = "--";

                const unit = document.createElement("div");
                unit.className = "unit";
                unit.textContent = card.unit ?? "";

                cardElement.append(label, value, unit);
                grid.appendChild(cardElement);

                cardElements.set(card.id, {
                    element: value,
                    config: card
                });
            });

            sectionElement.appendChild(grid);
            container.appendChild(sectionElement);
        });
    }

    // ----------------------------------------
    // VALUE FORMATTING
    // ----------------------------------------

    function isActive(value) {
        return (
            value === true ||
            value === 1 ||
            value === "1" ||
            value === "true"
        );
    }

    function formatValue(value, card) {
        if (value === undefined || value === null || value === "") {
            return "--";
        }

        if (card.type === "status") {
            return isActive(value) ? "ACTIVE" : "OFFLINE";
        }

        const numericValue = Number(value);

        if (!Number.isFinite(numericValue)) {
            return "--";
        }

        const decimals = Number.isInteger(card.decimals)
            ? card.decimals
            : 0;

        return numericValue.toFixed(decimals);
    }

    // ----------------------------------------
    // UPDATE CARDS
    // ----------------------------------------

    function updateCards(data) {
        if (!data || typeof data !== "object") {
            return;
        }

        cardElements.forEach(({ element, config: card }) => {
            const value = data[card.dataKey];

            element.textContent = formatValue(value, card);
        });
    }

    // ----------------------------------------
    // INITIALIZATION
    // ----------------------------------------

    renderCards();

    console.log("[CARDS] Initialized successfully.");

    return {
        updateCards
    };
}