
/* =========================================
   THEME MANAGER
   Modular Theme Management System
========================================= */

/* =========================================
   CONFIGURATION
========================================= */

const THEME_CONFIG_PATH = "/api/themes-config";

const THEME_LOG_PREFIX = "[THEME]";


/* =========================================
   INITIALIZATION
========================================= */

async function initializeThemeManager() {

    try {

        // Load JSON configuration
        const response = await fetch(THEME_CONFIG_PATH);

        if (!response.ok) {
            throw new Error("Theme configuration file not found.");
        }

        const config = await response.json();

        // Validate configuration
        if (!config || !Array.isArray(config.themes)) {
            throw new Error("Invalid theme configuration.");
        }

        // Find enabled themes
        const enabledThemes = config.themes.filter(
            theme => theme.enabled === true
        );


        /* =====================================
           NO THEME SELECTED
        ===================================== */

        if (enabledThemes.length === 0) {

            console.error(
                `${THEME_LOG_PREFIX} ERROR: No theme has been selected.`
            );

            return;
        }


        /* =====================================
           MULTIPLE THEMES SELECTED
        ===================================== */

        if (enabledThemes.length > 1) {

            console.error(
                `${THEME_LOG_PREFIX} ERROR: Multiple themes are enabled. ` +
                `Only the first enabled theme will be applied.`
            );

        }


        /* =====================================
           SELECT THEME
        ===================================== */

        const selectedTheme = enabledThemes[0];


        /* =====================================
           VALIDATE CSS PATH
        ===================================== */

        if (
            typeof selectedTheme.path !== "string" ||
            !selectedTheme.path.trim()
        ) {

            console.error(
                `${THEME_LOG_PREFIX} ERROR: CSS file path is invalid.`
            );

            return;
        }


        /* =====================================
           LOAD CSS
        ===================================== */

        const stylesheet = document.createElement("link");

        stylesheet.rel = "stylesheet";
        stylesheet.href = selectedTheme.path;

        stylesheet.onload = () => {

            console.info(
                `${THEME_LOG_PREFIX} Initialized successfully.`
            );

            console.info(
                `${THEME_LOG_PREFIX} Active theme: ${selectedTheme.name}`
            );

        };

        stylesheet.onerror = () => {

            console.error(
                `${THEME_LOG_PREFIX} ERROR: CSS file not found: ` +
                selectedTheme.path
            );

            stylesheet.remove();

        };

        document.head.appendChild(stylesheet);

    }

    catch (error) {

        console.error(
            `${THEME_LOG_PREFIX} ERROR: Failed to load theme configuration JSON.`,
            error
        );

    }

}


/* =========================================
   AUTOMATIC EXECUTION
========================================= */

initializeThemeManager();
