
-- OAI MIZUSHIMA YR-02
-- MC 07: TELEMETRY
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Flight monitoring and HTTP telemetry transmission


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    SEQUENCE_STATE = 1,
    SEQUENCE_TIMER = 2,

    ALTITUDE = 3,
    ALTITUDE_TARGET = 4,

    VERTICAL_SPEED = 5,
    DESIRED_VERTICAL_SPEED = 6,

    REAL_RPS = 7,
    TARGET_RPS = 8,

    TILT_ROLL_HORIZ = 9,
    TILT_PITCH = 10,

    AP_DISTANCE = 11,
    AP_YAW = 12,

    AP_MY_X = 13,
    AP_MY_Y = 14,

    AP_TARGET_X = 15,
    AP_TARGET_Y = 16,

    SPOILER = 17,

    ABSOLUTE_SPEED = 18,

    RUNNING = 1,
    COMPLETED = 2,

    AUTOPILOT = 3,
    MAIN_BOOSTER = 4,

    ALTITUDE_HOLD = 5,
    ROLL_STABILIZER = 6,

    ACCELERATION_BOOSTERS = 7,

    BOOSTER_NORTH = 8,
    BOOSTER_EAST = 9,
    BOOSTER_SOUTH = 10,
    BOOSTER_WEST = 11

}


--------------------------------------------------
-- 02. TELEMETRY CONFIGURATION
--------------------------------------------------

local TELEMETRY = {

    ENABLED = true,

    PORT = 8080,

    INTERVAL = 6,

    tick = 0

}


--------------------------------------------------
-- 03. FLIGHT PROGRAM NAMES
--------------------------------------------------

local FLIGHT_STAGES = {

    [1] = "ENGINE_CHECK",

    [2] = "ROLL_STABILIZER",

    [3] = "MAIN_BOOSTER",

    [4] = "DIRECTIONAL_BOOSTER",

    [5] = "BOTTOM_BOOSTER_SYSTEM",

    [6] = "ACCELERATION_BOOSTERS",

    [7] = "ROLL_STABILITY_CHECK",

    [8] = "ALTITUDE_HOLD",

    [9] = "AUTOPILOT",

    [10] = "AUTOPILOT_COMPLETE"

}


--------------------------------------------------
-- 04. TELEMETRY TRANSMISSION
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
    -- FLIGHT STAGE
    --------------------------------------------------

    local stage =

        FLIGHT_STAGES[data.sequenceState] or "STANDBY"


    --------------------------------------------------
    -- FLIGHT STATUS
    --------------------------------------------------

    local status = "IDLE"

    if data.running then

        status = "RUNNING"

    elseif data.completed then

        status = "COMPLETED"

    end


    --------------------------------------------------
    -- FLIGHT ERRORS
    --------------------------------------------------

    local altitudeError =

        data.altitudeTarget - data.altitude


    local speedError =

        data.desiredVerticalSpeed - data.verticalSpeed

        
    --------------------------------------------------
    -- TELEMETRY URL
    --------------------------------------------------

    local url = string.format(

        "/telemetry?"
        .. "stage=%s&state=%d&status=%s&timer=%d"

        -- ALTITUDE
        .. "&alt=%.2f&alt_target=%.2f&alt_error=%.2f"

        -- VERTICAL SPEED
        .. "&vs=%.2f&vs_target=%.2f&vs_error=%.2f"

        -- ENGINE
        .. "&rps=%.2f&rps_target=%.2f"

        -- ATTITUDE
        .. "&roll=%.4f&pitch=%.4f"

        -- AUTOPILOT
        .. "&ap=%d&ap_distance=%.2f&yaw=%.4f"
        .. "&my_x=%.2f&my_y=%.2f"
        .. "&target_x=%.2f&target_y=%.2f"

        -- SYSTEMS
        .. "&main=%d&alt_hold=%d&roll_stab=%d&accel=%d"

        -- DIRECTIONAL BOOSTERS
        .. "&north=%d&east=%d&south=%d&west=%d"

        -- FLIGHT CONTROL
        .. "&spoiler=%.2f&absolute_speed=%.2f",

        stage,
        data.sequenceState,
        status,
        data.sequenceTimer,

        data.altitude,
        data.altitudeTarget,
        altitudeError,

        data.verticalSpeed,
        data.desiredVerticalSpeed,
        speedError,

        data.realRPS,
        data.targetRPS,

        data.tiltRollHoriz,
        data.tiltPitch,

        data.autopilot and 1 or 0,
        data.apDistance,
        data.apYaw,
        data.myX,
        data.myY,
        data.targetX,
        data.targetY,

        data.mainBooster and 1 or 0,
        data.altitudeHold and 1 or 0,
        data.rollStabilizer and 1 or 0,
        data.accelerationBoosters and 1 or 0,

        data.boosterNorth and 1 or 0,
        data.boosterEast and 1 or 0,
        data.boosterSouth and 1 or 0,
        data.boosterWest and 1 or 0,

        data.spoiler,
        data.absoluteSpeed

    )


    --------------------------------------------------
    -- HTTP TRANSMISSION
    --------------------------------------------------

    async.httpGet(

        TELEMETRY.PORT,

        url

    )

end


--------------------------------------------------
-- 05. MAIN TICK
--------------------------------------------------

function onTick()

    --------------------------------------------------
    -- READ NUMERIC INPUTS
    --------------------------------------------------

    local data = {

        sequenceState =
            input.getNumber(INPUT.SEQUENCE_STATE),

        sequenceTimer =
            input.getNumber(INPUT.SEQUENCE_TIMER),

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        altitudeTarget =
            input.getNumber(INPUT.ALTITUDE_TARGET),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        desiredVerticalSpeed =
            input.getNumber(INPUT.DESIRED_VERTICAL_SPEED),

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

        myX =
            input.getNumber(INPUT.AP_MY_X),

        myY =
            input.getNumber(INPUT.AP_MY_Y),

        targetX =
            input.getNumber(INPUT.AP_TARGET_X),

        targetY =
            input.getNumber(INPUT.AP_TARGET_Y),

        spoiler =
            input.getNumber(INPUT.SPOILER),

        absoluteSpeed =
            input.getNumber(INPUT.ABSOLUTE_SPEED)

    }


    --------------------------------------------------
    -- READ BOOLEAN INPUTS
    --------------------------------------------------

    data.running =

        input.getBool(INPUT.RUNNING)


    data.completed =

        input.getBool(INPUT.COMPLETED)


    data.autopilot =

        input.getBool(INPUT.AUTOPILOT)


    data.mainBooster =

        input.getBool(INPUT.MAIN_BOOSTER)


    data.altitudeHold =

        input.getBool(INPUT.ALTITUDE_HOLD)


    data.rollStabilizer =

        input.getBool(INPUT.ROLL_STABILIZER)


    data.accelerationBoosters =

        input.getBool(INPUT.ACCELERATION_BOOSTERS)


    data.boosterNorth =

        input.getBool(INPUT.BOOSTER_NORTH)


    data.boosterEast =

        input.getBool(INPUT.BOOSTER_EAST)


    data.boosterSouth =

        input.getBool(INPUT.BOOSTER_SOUTH)


    data.boosterWest =

        input.getBool(INPUT.BOOSTER_WEST)


    --------------------------------------------------
    -- SEND TELEMETRY
    --------------------------------------------------

    sendTelemetry(data)

end


-- END OF MC 07
