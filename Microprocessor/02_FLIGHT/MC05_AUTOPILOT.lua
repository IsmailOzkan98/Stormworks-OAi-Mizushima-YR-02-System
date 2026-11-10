
-- OAI MIZUSHIMA YR-02
-- MC05: AUTOPILOT
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

-- =========================================
-- 01. INPUT CONFIGURATION
-- =========================================

local INPUT = {

    -- NAVIGATION

    KEYBOARD_X = 1,
    KEYBOARD_Y = 2,

    SENSOR_X = 3,
    SENSOR_Y = 4,

    COMPASS = 5,

    -- AUTOPILOT CONFIGURATION

    STEERING_POWER = 6,
    CUTOFF_DISTANCE = 7,
    DEADZONE = 8,
    SMOOTHING = 9,

    -- BOOLEAN INPUTS

    AUTOPILOT_ENABLE = 1,
    SYSTEM_AUTHORIZED = 2

}

-- =========================================
-- 02. OUTPUT CONFIGURATION
-- =========================================

local OUTPUT = {

    -- NUMBER OUTPUTS

    AP_YAW = 1,
    AP_DISTANCE = 2,

    AP_MY_X = 3,
    AP_MY_Y = 4,

    AP_TARGET_X = 5,
    AP_TARGET_Y = 6,

    AP_TARGET_HEADING = 7,
    AP_YAW_ERROR = 8,

    -- BOOLEAN OUTPUTS

    AUTOPILOT_READY = 1,
    AUTOPILOT_ACTIVE = 2,
    TARGET_REACHED = 3,
    AUTOPILOT_FAULT = 4

}

-- =========================================
-- 03. SYSTEM CONFIGURATION
-- =========================================

local CONFIG = {

    YAW_MIN = -1,
    YAW_MAX = 1

}

-- =========================================
-- 04. SYSTEM STATE
-- =========================================

local SYSTEM = {

    autopilotYaw = 0

}

-- =========================================
-- 05. GENERAL UTILITIES
-- =========================================

local function clamp(value, minValue, maxValue)

    return math.max(
        minValue,
        math.min(maxValue, value)
    )

end

-- =========================================
-- 06. INPUT PROCESSING
-- =========================================

local function readInputs()

    return {

        keyboardX =
            input.getNumber(INPUT.KEYBOARD_X),

        keyboardY =
            input.getNumber(INPUT.KEYBOARD_Y),

        sensorX =
            input.getNumber(INPUT.SENSOR_X),

        sensorY =
            input.getNumber(INPUT.SENSOR_Y),

        compass =
            input.getNumber(INPUT.COMPASS),

        steeringPower =
            input.getNumber(INPUT.STEERING_POWER),

        cutoffDistance =
            input.getNumber(INPUT.CUTOFF_DISTANCE),

        deadzone =
            input.getNumber(INPUT.DEADZONE),

        yawSmoothing =
            input.getNumber(INPUT.SMOOTHING) / 1000,

        enabled =
            input.getBool(INPUT.AUTOPILOT_ENABLE),

        authorized =
            input.getBool(INPUT.SYSTEM_AUTHORIZED)

    }

end

-- =========================================
-- 07. AUTOPILOT NAVIGATION
-- =========================================

local function updateAutopilot(data, enabled)

    -- COORDINATE DIFFERENCE

    local x =
        data.keyboardX - data.sensorX

    local y =
        data.keyboardY - data.sensorY

    -- DISTANCE

    local distance =
        math.sqrt(x * x + y * y)

    -- ANGLE TO TARGET

    local angle =
        math.atan(x, y)

    -- ANGULAR NORMALIZATION

    local pi2 =
        math.pi * 2

    -- NORMALIZED TARGET HEADING

    local targetHeading =
        (data.compass + angle / pi2) % 1

    -- ORIGINAL YAW CALCULATION

    local yawError =
        ((data.compass + angle / pi2) % 1 + 1.5) % 1 - 0.5

    -- DIRECTION CONTROL

    local yawTarget =
        yawError * data.steeringPower

    -- YAW LIMITER

    yawTarget = clamp(
        yawTarget,
        CONFIG.YAW_MIN,
        CONFIG.YAW_MAX
    )

    -- DEADZONE

    if math.abs(yawError) < data.deadzone then

        yawTarget = 0

    end

    -- CUTOFF

    local targetReached =
        distance < data.cutoffDistance

    if targetReached then

        yawTarget = 0

    end

    -- YAW SMOOTHING

    if not enabled then

        SYSTEM.autopilotYaw = 0

    else

        local smoothing =
            math.max(0, data.yawSmoothing)

        local difference =
            yawTarget - SYSTEM.autopilotYaw

        SYSTEM.autopilotYaw =
            SYSTEM.autopilotYaw +
            clamp(
                difference,
                -smoothing,
                smoothing
            )

    end

    return {

        yaw = SYSTEM.autopilotYaw,

        distance = distance,

        targetHeading = targetHeading,

        yawError = yawError,

        targetReached = targetReached,

        enabled = enabled

    }

end

-- =========================================
-- 08. OUTPUT PROCESSING
-- =========================================

local function writeOutputs(result, data, authorized)

    -- NAVIGATION OUTPUTS

    output.setNumber(
        OUTPUT.AP_YAW,
        result.yaw
    )

    output.setNumber(
        OUTPUT.AP_DISTANCE,
        result.distance
    )

    -- CURRENT POSITION

    output.setNumber(
        OUTPUT.AP_MY_X,
        data.sensorX
    )

    output.setNumber(
        OUTPUT.AP_MY_Y,
        data.sensorY
    )

    -- TARGET POSITION

    output.setNumber(
        OUTPUT.AP_TARGET_X,
        data.keyboardX
    )

    output.setNumber(
        OUTPUT.AP_TARGET_Y,
        data.keyboardY
    )

    -- NAVIGATION DIAGNOSTICS

    output.setNumber(
        OUTPUT.AP_TARGET_HEADING,
        result.targetHeading
    )

    output.setNumber(
        OUTPUT.AP_YAW_ERROR,
        result.yawError
    )

    -- STATUS

    output.setBool(
        OUTPUT.AUTOPILOT_READY,
        authorized
    )

    output.setBool(
        OUTPUT.AUTOPILOT_ACTIVE,
        result.enabled
    )

    output.setBool(
        OUTPUT.TARGET_REACHED,
        result.targetReached
    )

    output.setBool(
        OUTPUT.AUTOPILOT_FAULT,
        not authorized
    )

end

-- =========================================
-- 09. MAIN TICK
-- =========================================

function onTick()

    local data = readInputs()

    -- AUTHORITY GATE

    local authorized =
        data.authorized

    -- AUTOPILOT ENABLE

    local autopilotEnabled =
        data.enabled and authorized

    -- NAVIGATION

    local result = updateAutopilot(
        data,
        autopilotEnabled
    )

    -- OUTPUTS

    writeOutputs(
        result,
        data,
        authorized
    )

end

-- END MC05 AUTOPILOT
