
-- OAI MIZUSHIMA YR-02
-- MC04: FLIGHT CONTROL
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

-- =========================================
-- 01. INPUT CONFIGURATION
-- =========================================

local INPUT = {
    TILT_ROLL_HORIZ = 1,
    TILT_PITCH      = 2,

    ALTITUDE        = 3,
    ALTITUDE_TARGET = 4,

    VERTICAL_SPEED        = 5,
    VERTICAL_SPEED_TARGET = 6,

    MULTIPLIER = 7,

    PID_P = 8,
    PID_I = 9,
    PID_D = 10,

    ROLL_STABILIZER_ENABLE = 1,
    ALTITUDE_HOLD_ENABLE   = 2,
    SYSTEM_AUTHORIZED     = 3
}

-- =========================================
-- 02. OUTPUT CONFIGURATION
-- =========================================

local OUTPUT = {
    -- NUMBER
    ROLL_LEFT              = 1,
    ROLL_RIGHT             = 2,
    ELEVATOR_LEFT          = 3,
    ELEVATOR_RIGHT         = 4,
    ALTITUDE_ERROR         = 5,
    DESIRED_VERTICAL_SPEED = 6,
    VERTICAL_SPEED_ERROR   = 7,
    ALTITUDE_CONTROL       = 8,

    -- BOOLEAN
    FLIGHT_CONTROL_READY = 1,
    ROLL_STABILIZER_ACTIVE = 2,
    ALTITUDE_HOLD_ACTIVE = 3,
    FLIGHT_CONTROL_FAULT = 4
}

-- =========================================
-- 03. SYSTEM CONFIGURATION
-- =========================================

local CONFIG = {
    TICK_RATE = 60,

    ALTITUDE_GAIN = 0.35,

    MAX_CLIMB_SPEED = 105,
    MAX_DESCENT_SPEED = 125,

    CONTROL_MIN = -0.45,
    CONTROL_MAX = 0.45,

    INTEGRAL_LIMIT = 10,

    CONTROL_RATE = 0.005
}

-- =========================================
-- 04. SYSTEM STATE
-- =========================================

local SYSTEM = {
    integral = 0,
    previousVerticalSpeed = 0,
    altitudeControlSmooth = 0
}

-- =========================================
-- 05. GENERAL UTILITIES
-- =========================================

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

-- =========================================
-- 06. INPUT PROCESSING
-- =========================================

local function readInputs()

    return {
        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltPitch =
            input.getNumber(INPUT.TILT_PITCH),

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        altitudeTarget =
            input.getNumber(INPUT.ALTITUDE_TARGET),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        verticalSpeedTarget =
            input.getNumber(INPUT.VERTICAL_SPEED_TARGET),

        multiplier =
            input.getNumber(INPUT.MULTIPLIER),

        P = input.getNumber(INPUT.PID_P),
        I = input.getNumber(INPUT.PID_I),
        D = input.getNumber(INPUT.PID_D),

        rollEnable =
            input.getBool(INPUT.ROLL_STABILIZER_ENABLE),

        altitudeEnable =
            input.getBool(INPUT.ALTITUDE_HOLD_ENABLE),

        authorized =
            input.getBool(INPUT.SYSTEM_AUTHORIZED)
    }

end

-- =========================================
-- 07. ROLL STABILIZER
-- =========================================

local function updateRollController(data, enabled)

    if not enabled then
        return {
            rollLeft = 0,
            rollRight = 0
        }
    end

    local rollControl =
        data.tiltRollHoriz * data.multiplier

    return {
        rollLeft = rollControl,
        rollRight = -rollControl
    }

end

-- =========================================
-- 08. ALTITUDE HOLD
-- =========================================

local function updateAltitudeController(data, enabled)

    local dt = 1 / CONFIG.TICK_RATE

    local altitudeError =
        data.altitudeTarget - data.altitude

    local desiredVerticalSpeed = 0
    local speedError = 0
    local altitudeControl = 0

    if enabled then

        -- OUTER ALTITUDE LOOP

        desiredVerticalSpeed = clamp(
            altitudeError * CONFIG.ALTITUDE_GAIN,
            -CONFIG.MAX_DESCENT_SPEED,
            CONFIG.MAX_CLIMB_SPEED
        )

        -- INNER VERTICAL SPEED LOOP

        speedError =
            desiredVerticalSpeed - data.verticalSpeed

        local proportional =
            data.P * speedError

        local verticalAcceleration =
            (data.verticalSpeed -
            SYSTEM.previousVerticalSpeed) / dt

        local derivativeTerm =
            -data.D * verticalAcceleration

        -- INTEGRAL / ANTI-WINDUP

        local candidateIntegral = clamp(
            SYSTEM.integral + speedError * dt,
            -CONFIG.INTEGRAL_LIMIT,
            CONFIG.INTEGRAL_LIMIT
        )

        local outputWithoutIntegral =
            proportional + derivativeTerm

        local unsaturatedOutput =
            outputWithoutIntegral +
            data.I * candidateIntegral

        local saturatedOutput = clamp(
            unsaturatedOutput,
            CONFIG.CONTROL_MIN,
            CONFIG.CONTROL_MAX
        )

        if unsaturatedOutput == saturatedOutput

            or (
                unsaturatedOutput > CONFIG.CONTROL_MAX
                and speedError < 0
            )

            or (
                unsaturatedOutput < CONFIG.CONTROL_MIN
                and speedError > 0
            ) then

            SYSTEM.integral = candidateIntegral

        end

        altitudeControl = clamp(
            outputWithoutIntegral +
            data.I * SYSTEM.integral,
            CONFIG.CONTROL_MIN,
            CONFIG.CONTROL_MAX
        )

        SYSTEM.previousVerticalSpeed =
            data.verticalSpeed

    else

        SYSTEM.integral = 0

        SYSTEM.previousVerticalSpeed =
            data.verticalSpeed

        SYSTEM.altitudeControlSmooth = 0

    end

    -- ELEVATOR SMOOTHING

    local difference =
        altitudeControl - SYSTEM.altitudeControlSmooth

    SYSTEM.altitudeControlSmooth =
        SYSTEM.altitudeControlSmooth +
        clamp(
            difference,
            -CONFIG.CONTROL_RATE,
            CONFIG.CONTROL_RATE
        )

    return {
        altitudeError = altitudeError,
        desiredVerticalSpeed = desiredVerticalSpeed,
        speedError = speedError,
        altitudeControl = altitudeControl,
        elevatorOutput = SYSTEM.altitudeControlSmooth
    }

end

-- =========================================
-- 09. OUTPUT PROCESSING
-- =========================================

local function writeOutputs(flight, altitude, data, enabled)

    -- AILERONS

    output.setNumber(
        OUTPUT.ROLL_LEFT,
        flight.rollLeft
    )

    output.setNumber(
        OUTPUT.ROLL_RIGHT,
        flight.rollRight
    )

    -- ELEVATORS

    output.setNumber(
        OUTPUT.ELEVATOR_LEFT,
        altitude.elevatorOutput
    )

    output.setNumber(
        OUTPUT.ELEVATOR_RIGHT,
        altitude.elevatorOutput
    )

    -- DIAGNOSTICS

    output.setNumber(
        OUTPUT.ALTITUDE_ERROR,
        altitude.altitudeError
    )

    output.setNumber(
        OUTPUT.DESIRED_VERTICAL_SPEED,
        altitude.desiredVerticalSpeed
    )

    output.setNumber(
        OUTPUT.VERTICAL_SPEED_ERROR,
        altitude.speedError
    )

    output.setNumber(
        OUTPUT.ALTITUDE_CONTROL,
        altitude.altitudeControl
    )

    -- STATUS

    output.setBool(
        OUTPUT.FLIGHT_CONTROL_READY,
        enabled
    )

    output.setBool(
        OUTPUT.ROLL_STABILIZER_ACTIVE,
        enabled and data.rollEnable
    )

    output.setBool(
        OUTPUT.ALTITUDE_HOLD_ACTIVE,
        enabled and data.altitudeEnable
    )

    output.setBool(
        OUTPUT.FLIGHT_CONTROL_FAULT,
        not data.authorized
    )

end

-- =========================================
-- 10. MAIN TICK
-- =========================================

function onTick()

    local data = readInputs()

    -- AUTHORITY GATE

    local systemEnabled = data.authorized

    -- FUNCTION ENABLES

    local rollEnabled =
        systemEnabled and data.rollEnable

    local altitudeEnabled =
        systemEnabled and data.altitudeEnable

    -- ROLL STABILIZER

    local flight = updateRollController(
        data,
        rollEnabled
    )

    -- ALTITUDE HOLD

    local altitude = updateAltitudeController(
        data,
        altitudeEnabled
    )

    -- OUTPUTS

    writeOutputs(
        flight,
        altitude,
        data,
        systemEnabled
    )

end

-- END MC04 FLIGHT CONTROL
