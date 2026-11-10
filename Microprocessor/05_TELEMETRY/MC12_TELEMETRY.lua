
-- OAI MIZUSHIMA YR-02
-- MC12: TELEMETRY
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

--------------------------------------------------
-- TELEMETRY CONFIGURATION
--------------------------------------------------

local TELEMETRY = {

    ENABLED = true,

    PORT = 8080,

    INTERVAL = 6,

    tick = 0

}

--------------------------------------------------
-- FLIGHT STAGES
--------------------------------------------------

local FLIGHT_STAGES = {

    "ENGINE_CHECK",
    "ROLL_STABILIZER",
    "MAIN_BOOSTER",
    "DIRECTIONAL_BOOSTER",
    "BOTTOM_BOOSTER_SYSTEM",
    "ACCELERATION_BOOSTERS",
    "ROLL_STABILITY_CHECK",
    "ALTITUDE_HOLD",
    "AUTOPILOT",
    "AUTOPILOT_COMPLETE"

}

--------------------------------------------------
-- INPUT CONFIGURATION
--------------------------------------------------

-- NUMBER INPUTS

local INPUT = {

    ALTITUDE = 1,
    ALTITUDE_TARGET = 2,
    ALTITUDE_ERROR = 3,

    VERTICAL_SPEED = 4,
    DESIRED_VERTICAL_SPEED = 5,
    VERTICAL_SPEED_ERROR = 6,

    REAL_RPS = 7,
    TARGET_RPS = 8,

    TILT_ROLL_HORIZ = 9,
    TILT_PITCH = 10,

    AP_DISTANCE = 11,
    AP_YAW = 12,

    SENSOR_X = 13,
    SENSOR_Y = 14,

    KEYBOARD_X = 15,
    KEYBOARD_Y = 16,

    SPOILER = 17,

    SEQUENCE_STATE = 18,
    SEQUENCE_TIMER = 19

}

-- BOOLEAN INPUTS

local BOOL_INPUT = {

    SEQUENCE_RUNNING = 1,
    SEQUENCE_COMPLETED = 2,

    AUTOPILOT_ENABLE = 3,

    MAIN_BOOSTER = 4,
    ALTITUDE_HOLD = 5,
    ROLL_STABILIZER = 6,
    ACCELERATION_BOOSTERS = 7,

    NORTH = 8,
    EAST = 9,
    SOUTH = 10,
    WEST = 11

}

--------------------------------------------------
-- INPUT PROCESSING
--------------------------------------------------

local function readInputs()

    return {

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        altitudeTarget =
            input.getNumber(INPUT.ALTITUDE_TARGET),

        altitudeError =
            input.getNumber(INPUT.ALTITUDE_ERROR),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        desiredVerticalSpeed =
            input.getNumber(INPUT.DESIRED_VERTICAL_SPEED),

        speedError =
            input.getNumber(INPUT.VERTICAL_SPEED_ERROR),

        realRPS =
            input.getNumber(INPUT.REAL_RPS),

        targetRPS =
            input.getNumber(INPUT.TARGET_RPS),

        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltPitch =
            input.getNumber(INPUT.TILT_PITCH),

        apDistance =
            input.getNumber(INPUT.AP_DISTANCE),

        apYaw =
            input.getNumber(INPUT.AP_YAW),

        sensorX =
            input.getNumber(INPUT.SENSOR_X),

        sensorY =
            input.getNumber(INPUT.SENSOR_Y),

        keyboardX =
            input.getNumber(INPUT.KEYBOARD_X),

        keyboardY =
            input.getNumber(INPUT.KEYBOARD_Y),

        spoiler =
            input.getNumber(INPUT.SPOILER),

        sequenceState =
            input.getNumber(INPUT.SEQUENCE_STATE),

        sequenceTimer =
            input.getNumber(INPUT.SEQUENCE_TIMER),

        sequenceRunning =
            input.getBool(BOOL_INPUT.SEQUENCE_RUNNING),

        sequenceCompleted =
            input.getBool(BOOL_INPUT.SEQUENCE_COMPLETED),

        autopilot =
            input.getBool(BOOL_INPUT.AUTOPILOT_ENABLE),

        mainBooster =
            input.getBool(BOOL_INPUT.MAIN_BOOSTER),

        altitudeHold =
            input.getBool(BOOL_INPUT.ALTITUDE_HOLD),

        rollStabilizer =
            input.getBool(BOOL_INPUT.ROLL_STABILIZER),

        accelerationBoosters =
            input.getBool(BOOL_INPUT.ACCELERATION_BOOSTERS),

        north =
            input.getBool(BOOL_INPUT.NORTH),

        east =
            input.getBool(BOOL_INPUT.EAST),

        south =
            input.getBool(BOOL_INPUT.SOUTH),

        west =
            input.getBool(BOOL_INPUT.WEST)

    }

end

--------------------------------------------------
-- TELEMETRY TRANSMISSION
--------------------------------------------------

local function sendTelemetry(data)

    if not TELEMETRY.ENABLED then
        return
    end

    TELEMETRY.tick = TELEMETRY.tick + 1

    if TELEMETRY.tick < TELEMETRY.INTERVAL then
        return
    end

    TELEMETRY.tick = 0

    --------------------------------------------------
    -- STAGE
    --------------------------------------------------

    local stageIndex = data.sequenceState

    local step = FLIGHT_STAGES[stageIndex]

    local stage = step or "STANDBY"

    --------------------------------------------------
    -- STATUS
    --------------------------------------------------

    local status = "IDLE"

    if data.sequenceRunning then

        status = "RUNNING"

    elseif data.sequenceCompleted then

        status = "COMPLETED"

    end

    --------------------------------------------------
    -- ORIGINAL HTTP URL FORMAT
    --------------------------------------------------

    local url = string.format(

        "/telemetry?stage=%s&state=%d&status=%s&timer=%d&alt=%.2f&alt_target=%.2f&alt_error=%.2f&vs=%.2f&vs_target=%.2f&vs_error=%.2f&rps=%.2f&rps_target=%.2f&roll=%.4f&pitch=%.4f&ap=%d&ap_distance=%.2f&yaw=%.4f&my_x=%.2f&my_y=%.2f&target_x=%.2f&target_y=%.2f&main=%d&alt_hold=%d&roll_stab=%d&accel=%d&north=%d&east=%d&south=%d&west=%d&spoiler=%.2f",

        stage,

        data.sequenceState,

        status,

        data.sequenceTimer,

        data.altitude,

        data.altitudeTarget,

        data.altitudeError,

        data.verticalSpeed,

        data.desiredVerticalSpeed,

        data.speedError,

        data.realRPS,

        data.targetRPS,

        data.tiltRollHoriz,

        data.tiltPitch,

        data.autopilot and 1 or 0,

        data.apDistance,

        data.apYaw,

        data.sensorX,

        data.sensorY,

        data.keyboardX,

        data.keyboardY,

        data.mainBooster and 1 or 0,

        data.altitudeHold and 1 or 0,

        data.rollStabilizer and 1 or 0,

        data.accelerationBoosters and 1 or 0,

        data.north and 1 or 0,

        data.east and 1 or 0,

        data.south and 1 or 0,

        data.west and 1 or 0,

        data.spoiler

    )

    async.httpGet(TELEMETRY.PORT, url)

end

--------------------------------------------------
-- MAIN TICK
--------------------------------------------------

function onTick()

    local data = readInputs()

    sendTelemetry(data)

end

--------------------------------------------------
-- END MC12
--------------------------------------------------
