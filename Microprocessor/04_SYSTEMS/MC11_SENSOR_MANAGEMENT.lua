
-- OAI MIZUSHIMA YR-02
-- MC11: SENSOR MANAGEMENT
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

-- =========================================
-- 01. INPUT CONFIGURATION
-- =========================================

local INPUT = {

    TILT_ROLL_HORIZ = 1,
    TILT_ROLL_VERT  = 2,
    TILT_PITCH      = 3,

    REAL_RPS        = 4,

    ALTITUDE        = 5,
    VERTICAL_SPEED  = 6,

    SENSOR_X        = 7,
    SENSOR_Y        = 8,

    COMPASS         = 9

}

-- =========================================
-- 02. OUTPUT CONFIGURATION
-- =========================================

local OUTPUT = {

    -- NUMBER OUTPUTS

    TILT_ROLL_HORIZ = 1,
    TILT_ROLL_VERT  = 2,
    TILT_PITCH      = 3,

    REAL_RPS        = 4,

    ALTITUDE        = 5,
    VERTICAL_SPEED  = 6,

    SENSOR_X        = 7,
    SENSOR_Y        = 8,

    COMPASS         = 9,

    -- BOOLEAN OUTPUTS

    SENSOR_DATA_VALID    = 1,

    ROLL_HORIZ_VALID     = 2,
    ROLL_VERT_VALID      = 3,
    PITCH_VALID          = 4,

    RPS_VALID            = 5,

    ALTITUDE_VALID       = 6,
    VERTICAL_SPEED_VALID = 7,

    POSITION_VALID       = 8,
    COMPASS_VALID        = 9

}

-- =========================================
-- 03. SYSTEM CONFIGURATION
-- =========================================

local CONFIG = {

    -- MINIMUM / MAXIMUM ACCEPTED VALUES

    TILT_MIN = -1,
    TILT_MAX = 1,

    PITCH_MIN = -1,
    PITCH_MAX = 1,

    RPS_MIN = 0,
    RPS_MAX = 1000,

    ALTITUDE_MIN = -10000,
    ALTITUDE_MAX = 100000,

    VERTICAL_SPEED_MIN = -1000,
    VERTICAL_SPEED_MAX = 1000,

    POSITION_MIN = -1000000,
    POSITION_MAX = 1000000,

    COMPASS_MIN = 0,
    COMPASS_MAX = 1

}

-- =========================================
-- 04. SENSOR STATE
-- =========================================

local SYSTEM = {

    sensorDataValid = false

}

-- =========================================
-- 05. GENERAL UTILITIES
-- =========================================

local function isValid(value, minimum, maximum)

    return value >= minimum
        and value <= maximum

end

-- =========================================
-- 06. INPUT PROCESSING
-- =========================================

local function readSensors()

    return {

        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltRollVert =
            input.getNumber(INPUT.TILT_ROLL_VERT),

        tiltPitch =
            input.getNumber(INPUT.TILT_PITCH),

        realRPS =
            input.getNumber(INPUT.REAL_RPS),

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        sensorX =
            input.getNumber(INPUT.SENSOR_X),

        sensorY =
            input.getNumber(INPUT.SENSOR_Y),

        compass =
            input.getNumber(INPUT.COMPASS)

    }

end

-- =========================================
-- 07. SENSOR VALIDATION
-- =========================================

local function validateSensors(data)

    local valid = {

        rollHoriz = isValid(
            data.tiltRollHoriz,
            CONFIG.TILT_MIN,
            CONFIG.TILT_MAX
        ),

        rollVert = isValid(
            data.tiltRollVert,
            CONFIG.TILT_MIN,
            CONFIG.TILT_MAX
        ),

        pitch = isValid(
            data.tiltPitch,
            CONFIG.PITCH_MIN,
            CONFIG.PITCH_MAX
        ),

        rps = isValid(
            data.realRPS,
            CONFIG.RPS_MIN,
            CONFIG.RPS_MAX
        ),

        altitude = isValid(
            data.altitude,
            CONFIG.ALTITUDE_MIN,
            CONFIG.ALTITUDE_MAX
        ),

        verticalSpeed = isValid(
            data.verticalSpeed,
            CONFIG.VERTICAL_SPEED_MIN,
            CONFIG.VERTICAL_SPEED_MAX
        ),

        position =

            isValid(
                data.sensorX,
                CONFIG.POSITION_MIN,
                CONFIG.POSITION_MAX
            )

            and

            isValid(
                data.sensorY,
                CONFIG.POSITION_MIN,
                CONFIG.POSITION_MAX
            ),

        compass = isValid(
            data.compass,
            CONFIG.COMPASS_MIN,
            CONFIG.COMPASS_MAX
        )

    }

    valid.all =

        valid.rollHoriz
        and valid.rollVert
        and valid.pitch
        and valid.rps
        and valid.altitude
        and valid.verticalSpeed
        and valid.position
        and valid.compass

    return valid

end

-- =========================================
-- 08. OUTPUT PROCESSING
-- =========================================

local function writeOutputs(data, valid)

    -- NUMBER OUTPUTS
    -- Original measurements are preserved.

    output.setNumber(
        OUTPUT.TILT_ROLL_HORIZ,
        data.tiltRollHoriz
    )

    output.setNumber(
        OUTPUT.TILT_ROLL_VERT,
        data.tiltRollVert
    )

    output.setNumber(
        OUTPUT.TILT_PITCH,
        data.tiltPitch
    )

    output.setNumber(
        OUTPUT.REAL_RPS,
        data.realRPS
    )

    output.setNumber(
        OUTPUT.ALTITUDE,
        data.altitude
    )

    output.setNumber(
        OUTPUT.VERTICAL_SPEED,
        data.verticalSpeed
    )

    output.setNumber(
        OUTPUT.SENSOR_X,
        data.sensorX
    )

    output.setNumber(
        OUTPUT.SENSOR_Y,
        data.sensorY
    )

    output.setNumber(
        OUTPUT.COMPASS,
        data.compass
    )

    -- BOOLEAN OUTPUTS

    output.setBool(
        OUTPUT.SENSOR_DATA_VALID,
        valid.all
    )

    output.setBool(
        OUTPUT.ROLL_HORIZ_VALID,
        valid.rollHoriz
    )

    output.setBool(
        OUTPUT.ROLL_VERT_VALID,
        valid.rollVert
    )

    output.setBool(
        OUTPUT.PITCH_VALID,
        valid.pitch
    )

    output.setBool(
        OUTPUT.RPS_VALID,
        valid.rps
    )

    output.setBool(
        OUTPUT.ALTITUDE_VALID,
        valid.altitude
    )

    output.setBool(
        OUTPUT.VERTICAL_SPEED_VALID,
        valid.verticalSpeed
    )

    output.setBool(
        OUTPUT.POSITION_VALID,
        valid.position
    )

    output.setBool(
        OUTPUT.COMPASS_VALID,
        valid.compass
    )

end

-- =========================================
-- 09. MAIN TICK
-- =========================================

function onTick()

    -- READ SENSORS

    local data = readSensors()

    -- VALIDATE SENSORS

    local valid = validateSensors(data)

    SYSTEM.sensorDataValid = valid.all

    -- DISTRIBUTE DATA

    writeOutputs(data, valid)

end

-- END MC11 SENSOR MANAGEMENT
