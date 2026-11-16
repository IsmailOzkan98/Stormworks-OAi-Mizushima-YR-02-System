
"use strict";

/* =====================================================
   CONFIGURATION
===================================================== */

const THEME_CONFIG = Object.freeze({
    API: "/api/themes-config",
    STORAGE_KEY: "ActiveDashboardTheme",
    LOG_PREFIX: "[THEME]",
    TRIGGER_ID: "theme-selector-trigger",
    MODAL_ID: "theme-selector-modal"
});


/* =====================================================
   LOGGER
===================================================== */

const ThemeLogger = {

    info(message, ...details) {
        console.info(THEME_CONFIG.LOG_PREFIX, message, ...details);
    },

    error(message, error) {
        console.error(THEME_CONFIG.LOG_PREFIX, message, error ?? "");
    }

};


/* =====================================================
   THEME MANAGER
===================================================== */

const ThemeManager = (() => {

    let configurationPromise = null;
    let activeStylesheet = null;

    const loadedScripts = new Map();


    async function getConfiguration() {

        if (!configurationPromise) {

            configurationPromise = fetch(THEME_CONFIG.API, {
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

                    configurationPromise = null;
                    throw error;

                });

        }

        return configurationPromise;

    }


    function getSelectedTheme(config) {

        const storedId = Number(
            localStorage.getItem(THEME_CONFIG.STORAGE_KEY)
        );

        return config.themes.find(theme => theme.id === storedId)
            || config.themes.find(theme => theme.id === config.SelectedTheme);

    }


    function loadStylesheet(theme) {

        return new Promise((resolve, reject) => {

            const link = document.createElement("link");

            link.rel = "stylesheet";
            link.href = theme.path;

            link.onload = () => {

                activeStylesheet?.remove();

                activeStylesheet = link;

                ThemeLogger.info(`Theme loaded: ${theme.name}`);

                resolve();

            };

            link.onerror = () => {

                link.remove();

                reject(new Error(`Failed to load: ${theme.path}`));

            };

            document.head.appendChild(link);

        });

    }


    function loadScript(path) {

        if (loadedScripts.has(path)) {
            return loadedScripts.get(path);
        }

        const promise = new Promise((resolve, reject) => {

            const script = document.createElement("script");

            script.src = path;
            script.async = false;

            script.onload = () => resolve();
            script.onerror = () => reject(
                new Error(`Failed to load script: ${path}`)
            );

            document.head.appendChild(script);

        });

        loadedScripts.set(path, promise);

        promise.catch(() => loadedScripts.delete(path));

        return promise;

    }


    async function loadScripts(theme) {

        for (const path of theme.scripts ?? []) {
            await loadScript(path);
        }

    }


    async function initialize() {

        try {

            const config = await getConfiguration();
            const theme = getSelectedTheme(config);

            if (!theme) {
                throw new Error("Selected theme does not exist.");
            }

            await loadStylesheet(theme);
            await loadScripts(theme);

            ThemeLogger.info(`Active theme: ${theme.name}`);

            return theme;

        } catch (error) {

            ThemeLogger.error("Initialization failed.", error);

            return null;

        }

    }


    return Object.freeze({
        initialize,
        getConfiguration,
        getSelectedTheme
    });

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


    function initialize() {

        const trigger = document.getElementById(
            THEME_CONFIG.TRIGGER_ID
        );

        if (!trigger) {
            ThemeLogger.error("Theme button not found.");
            return;
        }

        trigger.addEventListener("click", open);

        ThemeLogger.info("Selector initialized.");

    }


    
    function createModal() {

        if (modal) return modal;

        modal = document.createElement("dialog");
        modal.style.background = "var(--panel)";
        modal.id = THEME_CONFIG.MODAL_ID;

        const title = createElement("h1", "THEME SELECTOR");

        const description = createElement(
            
            "p",
            "Select your dashboard theme."
        );

        description.style.color = "var(--muted)";

        const closeButton = createElement("button", "×");
        closeButton.type = "button";
        closeButton.addEventListener("click", close);

        const list = createElement("div");
        list.id = "ts-theme-list";

        // Vertical layout, without visual styling.
        list.style.display = "flex";
        list.style.flexDirection = "column";
        list.style.gap = "8px";

        modal.append(
            closeButton,
            title,
            description,
            list
        );

        modal.addEventListener("click", event => {
            if (event.target === modal) {
                close();
            }
        });

        document.body.appendChild(modal);

        return modal;
    }



    async function open() {

        const dialog = createModal();

        if (!dialog.open) {
            dialog.showModal();
        }

        await renderThemes();

    }


    function close() {

        modal?.close();

    }


    async function renderThemes() {

        const list = modal.querySelector("#ts-theme-list");

        list.replaceChildren();

        try {

            const config = await ThemeManager.getConfiguration();

            const activeTheme = ThemeManager.getSelectedTheme(config);

            for (const theme of config.themes) {

                const card = createElement(
                    "button",
                    `${theme.name}${theme.id === activeTheme.id ? " ✓ ACTIVE" : ""}`
                );

                card.type = "button";

                card.addEventListener("click", () => {
                    selectTheme(theme);
                });

                list.appendChild(card);

            }

        } catch (error) {

            list.appendChild(
                createElement("p", error.message)
            );

            ThemeLogger.error("Unable to render themes.", error);

        }

    }


    function selectTheme(theme) {

        if (!window.confirm(`Apply "${theme.name}"?\n\nThe dashboard will reload.`)) {
            return;
        }

        try {

            localStorage.setItem(
                THEME_CONFIG.STORAGE_KEY,
                String(theme.id)
            );

            window.location.reload();

        } catch (error) {

            ThemeLogger.error("Unable to save theme.", error);

        }

    }


    return Object.freeze({
        initialize,
        open,
        close
    });

})();


/* =====================================================
   START
===================================================== */

async function initializeThemeSystem() {

    ThemeSelector.initialize();

    await ThemeManager.initialize();

}

initializeThemeSystem();
