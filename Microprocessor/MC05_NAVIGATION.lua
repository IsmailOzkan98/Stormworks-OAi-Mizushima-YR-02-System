
-- OAI MIZUSHIMA YR-02
-- MC 05: NAVIGATION
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Autopilot navigation and yaw control


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    AP_KEYBOARD_X = 1,
    AP_KEYBOARD_Y = 2,

    AP_SENSOR_X = 3,
    AP_SENSOR_Y = 4,

    AP_COMPASS = 5,

    AP_STEERING = 6,
    AP_CUTOFF = 7,
    AP_DEADZONE = 8,
    AP_SMOOTHING = 9,

    AUTOPILOT = 9

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    AP_YAW = 1,
    AP_DISTANCE = 2,

    AP_MY_X = 3,
    AP_MY_Y = 4,

    AP_TARGET_X = 5,
    AP_TARGET_Y = 6,

    AP_TARGET_HEADING = 7

}


--------------------------------------------------
-- 03. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    autopilotYaw = 0

}


--------------------------------------------------
-- 04. GENERAL UTILITIES
--------------------------------------------------

local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end


--------------------------------------------------
-- 05. AUTOPILOT CONTROLLER
--------------------------------------------------

local function updateAutopilot(data, enabled)

    -- COORDINATE DIFFERENCE

    local x = data.keyboardX - data.sensorX

    local y = data.keyboardY - data.sensorY


    -- DISTANCE

    local distance = math.sqrt(x*x + y*y)


    -- ANGLE TO TARGET

    local angle = math.atan(x, y)


    -- ANGULAR NORMALIZATION

    local pi2 = math.pi * 2


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

    yawTarget = clamp(yawTarget, -1, 1)


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

        local smoothing = math.max(0, data.yawSmoothing)

        local difference =

            yawTarget - SYSTEM.autopilotYaw


        SYSTEM.autopilotYaw =

            SYSTEM.autopilotYaw +

            clamp(difference, -smoothing, smoothing)

    end


    return {

        yaw = SYSTEM.autopilotYaw,

        distance = distance,

        targetHeading = targetHeading,

        enabled = enabled

    }

end


--------------------------------------------------
-- 06. MAIN TICK
--------------------------------------------------

function onTick()

    -- READ PHYSICAL SENSORS AND PARAMETERS

    local data = {

        keyboardX =
            input.getNumber(INPUT.AP_KEYBOARD_X),

        keyboardY =
            input.getNumber(INPUT.AP_KEYBOARD_Y),

        sensorX =
            input.getNumber(INPUT.AP_SENSOR_X),

        sensorY =
            input.getNumber(INPUT.AP_SENSOR_Y),

        compass =
            input.getNumber(INPUT.AP_COMPASS),

        steeringPower =
            input.getNumber(INPUT.AP_STEERING),

        cutoffDistance =
            input.getNumber(INPUT.AP_CUTOFF),

        deadzone =
            input.getNumber(INPUT.AP_DEADZONE),

        yawSmoothing =
            input.getNumber(INPUT.AP_SMOOTHING) / 1000

    }


    -- READ MASTER COMMAND

    local autopilotEnabled =

        input.getBool(INPUT.AUTOPILOT)


    -- AUTOPILOT CALCULATION

    local autopilot = updateAutopilot(

        data,

        autopilotEnabled

    )


    -- YAW OUTPUT

    output.setNumber(

        OUTPUT.AP_YAW,

        autopilot.yaw

    )


    -- DISTANCE OUTPUT

    output.setNumber(

        OUTPUT.AP_DISTANCE,

        autopilot.distance

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

    -- TARGET HEADING OUTPUT

    output.setNumber(

        OUTPUT.AP_TARGET_HEADING,

        autopilot.targetHeading

    )

end


-- END OF MC 05
