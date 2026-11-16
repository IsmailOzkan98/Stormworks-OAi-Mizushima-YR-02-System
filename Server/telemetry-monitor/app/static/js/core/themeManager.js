
"use strict";

/* =====================================================
   CONFIG
===================================================== */

const CONFIG = {
    API: "/api/themes-config",
    STORAGE_KEY: "ActiveDashboardTheme",
    TRIGGER_ID: "theme-selector-trigger",
    MODAL_ID: "theme-selector-modal"
};


/* =====================================================
   THEME MANAGER
===================================================== */

const ThemeManager = (() => {

    let configPromise = null;
    let activeStylesheet = null;

    const loadedScripts = new Map();


    // Get themes configuration
    async function getConfig() {

        if (!configPromise) {

            configPromise = fetch(CONFIG.API, {
                cache: "no-store"
            })
                .then(response => {
                    if (!response.ok) {
                        throw new Error(`HTTP ${response.status}`);
                    }

                    return response.json();
                })
                .then(config => {

                    if (!Array.isArray(config.themes)) {
                        throw new Error("Invalid themes configuration.");
                    }

                    return config;
                })
                .catch(error => {
                    configPromise = null;
                    throw error;
                });
        }

        return configPromise;
    }


    // Get selected theme
    function getSelectedTheme(config) {

        const storedId = localStorage.getItem(CONFIG.STORAGE_KEY);

        return config.themes.find(theme =>
            String(theme.id) === storedId
        ) || config.themes.find(theme =>
            theme.id === config.SelectedTheme
        ) || config.themes[0];
    }


    // Load stylesheet
    function loadStylesheet(theme) {

        return new Promise((resolve, reject) => {

            if (!theme?.path) {
                reject(new Error("Invalid theme stylesheet."));
                return;
            }

            const link = document.createElement("link");

            link.rel = "stylesheet";
            link.href = theme.path;

            link.onload = () => {

                activeStylesheet?.remove();
                activeStylesheet = link;

                console.info(`[THEME] Loaded: ${theme.name}`);

                resolve();
            };

            link.onerror = () => {
                link.remove();
                reject(new Error(`Failed to load: ${theme.path}`));
            };

            document.head.appendChild(link);
        });
    }


    // Load script only once
    function loadScript(path) {

        if (loadedScripts.has(path)) {
            return loadedScripts.get(path);
        }

        const promise = new Promise((resolve, reject) => {

            const script = document.createElement("script");

            script.src = path;
            script.async = false;

            script.onload = resolve;

            script.onerror = () => {
                script.remove();
                reject(new Error(`Failed to load script: ${path}`));
            };

            document.head.appendChild(script);
        });

        loadedScripts.set(path, promise);

        promise.catch(() => loadedScripts.delete(path));

        return promise;
    }


    // Initialize theme
    async function initialize() {

        try {

            const config = await getConfig();
            const theme = getSelectedTheme(config);

            if (!theme) {
                throw new Error("No themes available.");
            }

            await loadStylesheet(theme);

            for (const script of theme.scripts ?? []) {
                await loadScript(script);
            }

            console.info(`[THEME] Active: ${theme.name}`);

            return theme;

        } catch (error) {

            console.error("[THEME] Initialization failed:", error);

            return null;
        }
    }


    return {
        initialize,
        getConfig,
        getSelectedTheme
    };

})();


/* =====================================================
   THEME SELECTOR
===================================================== */

const ThemeSelector = (() => {

    let modal = null;


    function createElement(tag, text = "") {

        const element = document.createElement(tag);

        element.textContent = text;

        return element;
    }


    function close() {
        modal?.close();
    }


    function createModal() {

        if (modal) return modal;

        modal = document.createElement("dialog");
        modal.id = CONFIG.MODAL_ID;
        modal.style.background = "var(--panel)";

        const closeButton = createElement("button", "×");
        closeButton.type = "button";
        closeButton.addEventListener("click", close);

        const title = createElement("h1", "THEME SELECTOR");

        const description = createElement(
            "p",
            "Select your dashboard theme."
        );

        description.style.color = "var(--muted)";

        const list = createElement("div");
        list.id = "ts-theme-list";

        Object.assign(list.style, {
            display: "flex",
            flexDirection: "column",
            gap: "8px"
        });

        modal.append(closeButton, title, description, list);

        modal.addEventListener("click", event => {
            if (event.target === modal) close();
        });

        document.body.appendChild(modal);

        return modal;
    }


    async function renderThemes() {

        const list = modal.querySelector("#ts-theme-list");

        list.replaceChildren();

        try {

            const config = await ThemeManager.getConfig();
            const activeTheme = ThemeManager.getSelectedTheme(config);

            config.themes.forEach(theme => {

                const button = createElement(
                    "button",
                    `${theme.name}${theme.id === activeTheme?.id ? " ✓ ACTIVE" : ""}`
                );

                button.type = "button";

                button.addEventListener("click", () => selectTheme(theme));

                list.appendChild(button);
            });

        } catch (error) {

            list.appendChild(createElement("p", "Unable to load themes."));

            console.error("[THEME] Selector error:", error);
        }
    }


    function selectTheme(theme) {

        if (!window.confirm(`Apply "${theme.name}"?\n\nThe dashboard will reload.`)) {
            return;
        }

        try {

            localStorage.setItem(
                CONFIG.STORAGE_KEY,
                String(theme.id)
            );

            window.location.reload();

        } catch (error) {

            console.error("[THEME] Unable to save theme:", error);
            alert("Unable to save the selected theme.");
        }
    }


    async function open() {

        const dialog = createModal();

        if (!dialog.open) {
            dialog.showModal();
        }

        await renderThemes();
    }


    function initialize() {

        const trigger = document.getElementById(CONFIG.TRIGGER_ID);

        if (!trigger) {
            console.warn("[THEME] Theme selector button not found.");
            return;
        }

        trigger.addEventListener("click", open);
    }


    return {
        initialize,
        open,
        close
    };

})();


/* =====================================================
   START
===================================================== */

async function initializeThemeSystem() {

    ThemeSelector.initialize();

    await ThemeManager.initialize();

}

initializeThemeSystem();
