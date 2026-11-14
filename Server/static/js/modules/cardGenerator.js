
async function initializeCards() {
    const response = await fetch("/static/modules/cards.json");
    const cards = await response.json();

    // Ordenar cartas
    cards.sort((a, b) => a.order - b.order);

    cards.forEach(config => {
        if (config.type !== "card") return;

        const container = document.getElementById(
            config.group + "Cards"
        );

        if (!container) {
            console.warn("Container not found:", config.group);
            return;
        }

        const card = document.createElement("div");
        card.className = "card";

        if (config.highlight) {
            card.classList.add("highlight-card");
        }

        card.innerHTML = `
            <div class="card-label"></div>
            <div class="value" id="${config.id}">--</div>
            <div class="unit"></div>
        `;

        // Insertar textos de forma segura
        card.querySelector(".card-label").textContent = config.name;
        card.querySelector(".unit").textContent = config.unit;

        container.appendChild(card);
    });

    return cards;
}
