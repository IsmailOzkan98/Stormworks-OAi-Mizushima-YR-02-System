
/* =========================================
   THEME MANAGER
   Modular Theme Management System
========================================= */


/* =========================================
   CONFIGURATION
========================================= */

const THEME_CONFIG = {

    CONFIG_PATH: "/api/themes-config",

    LOG_PREFIX: "[THEME]",

    SELECTED_PROPERTY: "SelectedTheme",

    THEMES_PROPERTY: "themes"

};


/* =========================================
   LOGGING
========================================= */

const ThemeLogger = {

    info(message) {

        console.info(
            `${THEME_CONFIG.LOG_PREFIX} ${message}`
        );

    },

    error(message, error = null) {

        console.error(
            `${THEME_CONFIG.LOG_PREFIX} ERROR: ${message}`,
            error ?? ""
        );

    }

};


/* =========================================
   CONFIGURATION LOADER
========================================= */

async function loadThemeConfiguration() {

    const response = await fetch(
        THEME_CONFIG.CONFIG_PATH,
        {
            cache: "no-cache"
        }
    );

    if (!response.ok) {

        throw new Error(
            `Configuration request failed: HTTP ${response.status}`
        );

    }

    const config = await response.json();

    if (
        !config ||
        !Array.isArray(config[THEME_CONFIG.THEMES_PROPERTY])
    ) {

        throw new Error(
            "Invalid theme configuration structure."
        );

    }

    return config;

}


/* =========================================
   THEME VALIDATION
========================================= */

function validateThemeConfiguration(config) {

    const selectedId = config[THEME_CONFIG.SELECTED_PROPERTY];

    if (
        !Number.isInteger(selectedId) ||
        selectedId < 1
    ) {

        throw new Error(
            "SelectedTheme must be a positive integer."
        );

    }

    const themes = config[THEME_CONFIG.THEMES_PROPERTY];

    const selectedTheme = themes.find(
        theme => theme.id === selectedId
    );

    if (!selectedTheme) {

        throw new Error(
            `Theme ID ${selectedId} does not exist.`
        );

    }

    if (
        typeof selectedTheme.name !== "string" ||
        !selectedTheme.name.trim()
    ) {

        throw new Error(
            "Selected theme name is invalid."
        );

    }

    if (
        typeof selectedTheme.path !== "string" ||
        !selectedTheme.path.trim()
    ) {

        throw new Error(
            "Selected theme CSS path is invalid."
        );

    }

    const duplicateIds = themes.filter(
        theme => theme.id === selectedId
    );

    if (duplicateIds.length !== 1) {

        throw new Error(
            `Theme ID ${selectedId} is duplicated.`
        );

    }

    return selectedTheme;

}


/* =========================================
   CSS LOADER
========================================= */

function loadThemeStylesheet(theme) {

    return new Promise((resolve, reject) => {

        const stylesheet = document.createElement("link");

        stylesheet.rel = "stylesheet";
        stylesheet.href = theme.path;
        stylesheet.dataset.themeManager = "active";

        stylesheet.onload = () => {

            resolve(stylesheet);

        };

        stylesheet.onerror = () => {

            stylesheet.remove();

            reject(
                new Error(
                    `Failed to load CSS: ${theme.path}`
                )
            );

        };

        document.head.appendChild(stylesheet);

    });

}


/* =========================================
   INITIALIZATION
========================================= */

async function initializeThemeManager() {

    try {

        // Load configuration
        const config = await loadThemeConfiguration();


        // Validate and retrieve selected theme
        const selectedTheme = validateThemeConfiguration(config);


        // Load selected stylesheet
        await loadThemeStylesheet(selectedTheme);


        // Initialization successful
        ThemeLogger.info("Initialized successfully.");

        ThemeLogger.info(
            `Active theme: ${selectedTheme.name} (ID: ${selectedTheme.id})`
        );

    }

    catch (error) {

        ThemeLogger.error(
            "Failed to initialize Theme Manager.",
            error
        );

    }

}


/* =========================================
   AUTOMATIC EXECUTION
========================================= */

initializeThemeManager();
