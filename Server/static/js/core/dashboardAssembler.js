
/* ============================================================
   OAI MIZUSHIMA YR-02
   DASHBOARD ASSEMBLER

   VERSION: 1.0.0

   RESPONSIBILITY:
   Dynamic dashboard composition.

   ============================================================ */

export function initializeDashboardAssembler(config) {

    const dashboard = document.getElementById("dashboardGrid");

    if (!dashboard) {
        throw new Error("[DASHBOARD] Root container not found.");
    }

    if (!config || !Array.isArray(config.items)) {
        throw new Error("[DASHBOARD] Invalid configuration.");
    }

    const columns = Number(config.columns);

    if (!Number.isInteger(columns) || columns < 1) {
        throw new Error("[DASHBOARD] Invalid column count.");
    }

    const gap = Number(config.gap ?? 14);

    if (!Number.isFinite(gap) || gap < 0) {
        throw new Error("[DASHBOARD] Invalid column gap.");
    }

    // VALIDATE ITEMS

    const ids = new Set();

    const items = config.items.map(item => {

        if (
            !item.id ||
            !Number.isInteger(item.column) ||
            item.column < 1 ||
            item.column > columns ||
            !Number.isInteger(item.order) ||
            item.order < 1
        ) {
            throw new Error(
                `[DASHBOARD] Invalid item configuration: ${item.id}`
            );
        }

        if (ids.has(item.id)) {
            throw new Error(
                `[DASHBOARD] Duplicate item: ${item.id}`
            );
        }

        ids.add(item.id);

        return item;

    });

    // RESOLVE DOM ELEMENTS BEFORE REBUILDING

    const resolvedItems = items.map(item => ({

        ...item,

        element: document.getElementById(item.id)

    }));

    // CREATE COLUMNS

    const columnElements = [];

    for (let i = 0; i < columns; i++) {

        const column = document.createElement("section");

        column.className = "column";

        column.dataset.column = i + 1;

        columnElements.push(column);

    }

    // CONFIGURE DASHBOARD

    dashboard.replaceChildren();

    dashboard.style.setProperty(
        "--dashboard-columns",
        columns
    );

    dashboard.style.setProperty(
        "--dashboard-gap",
        `${gap}px`
    );

    // SORT AND DISTRIBUTE MODULES

    resolvedItems
        .sort((a, b) =>
            a.column - b.column ||
            a.order - b.order
        )
        .forEach(item => {

            if (!item.element) {

                console.warn(
                    `[DASHBOARD] Missing container: ${item.id}`
                );

                return;

            }

            columnElements[item.column - 1]
                .appendChild(item.element);

        });

    // MOUNT COLUMNS

    columnElements.forEach(column => {

        dashboard.appendChild(column);

    });

    console.info(
        `[DASHBOARD] Initialized with ${columns} columns.`
    );

}
