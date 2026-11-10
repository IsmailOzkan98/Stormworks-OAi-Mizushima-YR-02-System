-- OAI MIZUSHIMA YR-02
-- MC06: PROPULSION
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

--------------------------------------------------
-- CONFIGURATION
--------------------------------------------------

local CONFIG = {
    TICK_RATE = 60,

    DIRECTIONAL_BOOSTER_PULSE = 0.2,

    BOTTOM_BOOSTERS = {
        ENABLED = true,
        ZONE = 25 / 360,
        MIN_SENSOR_MAGNITUDE = 0.001
    }
}

--------------------------------------------------
-- INPUT CHANNELS
--------------------------------------------------

local INPUT = {
    NUMBER = {
        TILT_ROLL_HORIZ = 1,
        TILT_ROLL_VERT = 2,
        AP_TARGET_HEADING = 3,
        SPOILER_COMMAND = 4
    },

    BOOL = {
        SYSTEM_AUTHORIZED = 1,
        MAIN_BOOSTER_COMMAND = 2,
        BOTTOM_BOOSTERS_ENABLE = 3,
        ACCELERATION_BOOSTERS_COMMAND = 4,
        DIRECTIONAL_BOOSTER_REQUEST = 5
    }
}

--------------------------------------------------
-- OUTPUT CHANNELS
--------------------------------------------------

local OUTPUT = {
    NUMBER = {
        SPOILER = 1
    },

    BOOL = {
        MAIN_BOOSTER = 1,
        BOOSTER_NORTH = 2,
        BOOSTER_EAST = 3,
        BOOSTER_SOUTH = 4,
        BOOSTER_WEST = 5,
        ACCELERATION_BOOSTER = 6,

        PROPULSION_READY = 7,
        PROPULSION_ACTIVE = 8,
        AUTHORITY_LOST = 9
    }
}

--------------------------------------------------
-- INTERNAL STATE
--------------------------------------------------

local state = {
    previousDirectionalRequest = false,

    directionalHeading = 0,
    directionalPulseTicks = 0,

    directionalNorth = false,
    directionalEast = false,
    directionalSouth = false,
    directionalWest = false
}

--------------------------------------------------
-- CONFIGURATION VALUES
--------------------------------------------------

local DIRECTIONAL_PULSE_TICKS =
    math.max(
        1,
        math.ceil(
            CONFIG.DIRECTIONAL_BOOSTER_PULSE
            * CONFIG.TICK_RATE
        )
    )

--------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function normalizeTurns(value)
    return value % 1
end

local function angleDifference(a, b)
    local difference = math.abs(a - b)

    if difference > 0.5 then
        difference = 1 - difference
    end

    return difference
end

--------------------------------------------------
-- DIRECTIONAL BOOSTERS
--------------------------------------------------

local function captureDirectionalHeading(heading)

    state.directionalHeading = normalizeTurns(heading)

    state.directionalPulseTicks =
        DIRECTIONAL_PULSE_TICKS

    local headingValue = state.directionalHeading

    state.directionalNorth = false
    state.directionalEast = false
    state.directionalSouth = false
    state.directionalWest = false

    -- Directional boosters use the opposite
    -- quadrant of the captured target heading.

    if headingValue < 0.125 or headingValue >= 0.875 then

        state.directionalSouth = true

    elseif headingValue < 0.375 then

        state.directionalWest = true

    elseif headingValue < 0.625 then

        state.directionalNorth = true

    else

        state.directionalEast = true

    end
end

local function updateDirectionalBoosters(
    request,
    heading
)

    local requestRising =
        request and not state.previousDirectionalRequest

    state.previousDirectionalRequest = request

    if requestRising then
        captureDirectionalHeading(heading)
    end

    local active = state.directionalPulseTicks > 0

    if active then
        state.directionalPulseTicks =
            state.directionalPulseTicks - 1
    end

    if not active then
        state.directionalNorth = false
        state.directionalEast = false
        state.directionalSouth = false
        state.directionalWest = false
    end

    return
        active and state.directionalNorth,
        active and state.directionalEast,
        active and state.directionalSouth,
        active and state.directionalWest
end

--------------------------------------------------
-- BOTTOM BOOSTER DETECTION
--------------------------------------------------

local function updateBottomBoosters(
    tiltRollHoriz,
    tiltRollVert,
    enabled
)

    local bottomNorth = false
    local bottomEast = false
    local bottomSouth = false
    local bottomWest = false

    if not CONFIG.BOTTOM_BOOSTERS.ENABLED
        or not enabled then

        return
            bottomNorth,
            bottomEast,
            bottomSouth,
            bottomWest
    end

    local magnitude =
        math.sqrt(
            tiltRollHoriz * tiltRollHoriz
            + tiltRollVert * tiltRollVert
        )

    if magnitude <
        CONFIG.BOTTOM_BOOSTERS.MIN_SENSOR_MAGNITUDE then

        return
            bottomNorth,
            bottomEast,
            bottomSouth,
            bottomWest
    end

    local rollAngle =
        math.atan(tiltRollHoriz, tiltRollVert)

    local bottomAngle =
        (rollAngle + math.pi) % (2 * math.pi)

    local bottomTurns =
        bottomAngle / (2 * math.pi)

    local zone = CONFIG.BOTTOM_BOOSTERS.ZONE

    -- Original bottom direction sectors.

    local bottomUno =
        angleDifference(bottomTurns, 0.25) <= zone

    local bottomDos =
        angleDifference(bottomTurns, 0.00) <= zone

    local bottomTres =
        angleDifference(bottomTurns, 0.75) <= zone

    local bottomCuatro =
        angleDifference(bottomTurns, 0.50) <= zone

    -- Original output mapping.

    bottomNorth = bottomCuatro
    bottomEast = bottomTres
    bottomSouth = bottomDos
    bottomWest = bottomUno

    return
        bottomNorth,
        bottomEast,
        bottomSouth,
        bottomWest
end

--------------------------------------------------
-- MAIN PROPULSION UPDATE
--------------------------------------------------

local function onTick()

    --------------------------------------------------
    -- READ INPUTS
    --------------------------------------------------

    local tiltRollHoriz =
        input.getNumber(INPUT.NUMBER.TILT_ROLL_HORIZ)

    local tiltRollVert =
        input.getNumber(INPUT.NUMBER.TILT_ROLL_VERT)

    local apTargetHeading =
        input.getNumber(INPUT.NUMBER.AP_TARGET_HEADING)

    local spoilerCommand =
        input.getNumber(INPUT.NUMBER.SPOILER_COMMAND)

    local systemAuthorized =
        input.getBool(INPUT.BOOL.SYSTEM_AUTHORIZED)

    local mainBoosterCommand =
        input.getBool(INPUT.BOOL.MAIN_BOOSTER_COMMAND)

    local bottomBoostersEnable =
        input.getBool(INPUT.BOOL.BOTTOM_BOOSTERS_ENABLE)

    local accelerationBoostersCommand =
        input.getBool(INPUT.BOOL.ACCELERATION_BOOSTERS_COMMAND)

    local directionalBoosterRequest =
        input.getBool(INPUT.BOOL.DIRECTIONAL_BOOSTER_REQUEST)

    --------------------------------------------------
    -- DEFAULT OUTPUT STATE
    --------------------------------------------------

    local mainBooster = false
    local accelerationBooster = false

    local boosterNorth = false
    local boosterEast = false
    local boosterSouth = false
    local boosterWest = false

    local spoiler = 0

    --------------------------------------------------
    -- AUTHORITY CHECK
    --------------------------------------------------

    if systemAuthorized then

        --------------------------------------------------
        -- MAIN BOOSTER
        --------------------------------------------------

        mainBooster = mainBoosterCommand

        --------------------------------------------------
        -- ACCELERATION BOOSTER
        --------------------------------------------------

        accelerationBooster =
            accelerationBoostersCommand

        --------------------------------------------------
        -- DIRECTIONAL BOOSTERS
        --------------------------------------------------

        local directionalNorth,
              directionalEast,
              directionalSouth,
              directionalWest =
            updateDirectionalBoosters(
                directionalBoosterRequest,
                apTargetHeading
            )

        --------------------------------------------------
        -- BOTTOM BOOSTERS
        --------------------------------------------------

        local bottomNorth,
              bottomEast,
              bottomSouth,
              bottomWest =
            updateBottomBoosters(
                tiltRollHoriz,
                tiltRollVert,
                bottomBoostersEnable
            )

        --------------------------------------------------
        -- COMBINE BOOSTER COMMANDS
        --------------------------------------------------

        boosterNorth =
            directionalNorth or bottomNorth

        boosterEast =
            directionalEast or bottomEast

        boosterSouth =
            directionalSouth or bottomSouth

        boosterWest =
            directionalWest or bottomWest

        --------------------------------------------------
        -- SPOILER
        --------------------------------------------------

        spoiler =
            clamp(spoilerCommand, 0, 1)

    else

        -- Prevent a held request from triggering
        -- unexpectedly when authority returns.

        state.previousDirectionalRequest =
            directionalBoosterRequest

        state.directionalPulseTicks = 0

        state.directionalNorth = false
        state.directionalEast = false
        state.directionalSouth = false
        state.directionalWest = false

    end

    --------------------------------------------------
    -- PROPULSION STATUS
    --------------------------------------------------

    local propulsionActive =
        mainBooster
        or accelerationBooster
        or boosterNorth
        or boosterEast
        or boosterSouth
        or boosterWest
        or spoiler > 0

    --------------------------------------------------
    -- WRITE NUMERIC OUTPUTS
    --------------------------------------------------

    output.setNumber(
        OUTPUT.NUMBER.SPOILER,
        spoiler
    )

    --------------------------------------------------
    -- WRITE BOOLEAN OUTPUTS
    --------------------------------------------------

    output.setBool(
        OUTPUT.BOOL.MAIN_BOOSTER,
        mainBooster
    )

    output.setBool(
        OUTPUT.BOOL.BOOSTER_NORTH,
        boosterNorth
    )

    output.setBool(
        OUTPUT.BOOL.BOOSTER_EAST,
        boosterEast
    )

    output.setBool(
        OUTPUT.BOOL.BOOSTER_SOUTH,
        boosterSouth
    )

    output.setBool(
        OUTPUT.BOOL.BOOSTER_WEST,
        boosterWest
    )

    output.setBool(
        OUTPUT.BOOL.ACCELERATION_BOOSTER,
        accelerationBooster
    )

    output.setBool(
        OUTPUT.BOOL.PROPULSION_READY,
        systemAuthorized
    )

    output.setBool(
        OUTPUT.BOOL.PROPULSION_ACTIVE,
        propulsionActive
    )

    output.setBool(
        OUTPUT.BOOL.AUTHORITY_LOST,
        not systemAuthorized
    )
end

--------------------------------------------------
-- MAIN CALLBACK
--------------------------------------------------

function onTick()
    onTick()
end