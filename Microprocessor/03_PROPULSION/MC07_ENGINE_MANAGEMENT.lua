
-- OAI MIZUSHIMA YR-02
-- MC07: ENGINE MANAGEMENT
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

--------------------------------------------------
-- INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {
    TARGET_RPS = 1,
    REAL_RPS = 2
}

--------------------------------------------------
-- OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {
    ENGINE_RPS_READY = 1
}

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local MARGINS = {
    RPS = 1
}

--------------------------------------------------
-- ENGINE MANAGEMENT
--------------------------------------------------

local function checkEngineRPS(targetRPS, realRPS)

    return realRPS >= (targetRPS - MARGINS.RPS)

end

--------------------------------------------------
-- MAIN TICK
--------------------------------------------------

function onTick()

    -- READ INPUTS

    local targetRPS =
        input.getNumber(INPUT.TARGET_RPS)

    local realRPS =
        input.getNumber(INPUT.REAL_RPS)

    -- ENGINE CHECK

    local engineRPSReady =
        checkEngineRPS(targetRPS, realRPS)

    -- WRITE OUTPUT

    output.setBool(
        OUTPUT.ENGINE_RPS_READY,
        engineRPSReady
    )

end

-- END OF MC07
