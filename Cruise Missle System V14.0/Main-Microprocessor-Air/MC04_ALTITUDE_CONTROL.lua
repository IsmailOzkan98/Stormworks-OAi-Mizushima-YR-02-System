
-- OAI MIZUSHIMA YR-02
-- MC 04: ALTITUDE CONTROL
-- VERSION: 1.4.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Altitude PID control and elevator management


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    -- Numerical Inputs

    ALTITUDE        = 1,
    ALTITUDE_TARGET = 2,

    ALT_PID_P       = 3,
    ALT_PID_I       = 4,
    ALT_PID_D       = 5,

    VERTICAL_SPEED  = 6,
    MAX_CLIMB_SPEED = 7,
    MAX_DESCENT_SPEED = 8,

    ALTITUDE_GAIN = 9,

    DESCENT_TARGET = 10,

    -- Boolean Inputs

    ALTITUDE_HOLD   = 8,
    DESCENT_MODE = 9

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    ELEVATOR_RIGHT  = 3,
    ELEVATOR_LEFT = 4,

    DESIRED_VERTICAL_SPEED  = 5,

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    TICK_RATE = 60,

    CONTROL_MIN = -0.45,
    CONTROL_MAX = 0.45,

    INTEGRAL_LIMIT = 10,

    CONTROL_RATE = 0.005

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    integral = 0,

    previousVerticalSpeed = 0,

    altitudeControlSmooth = 0

}


--------------------------------------------------
-- 05. GENERAL UTILITIES
--------------------------------------------------

local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end


--------------------------------------------------
-- 06. ALTITUDE HOLD PID CONTROLLER
--------------------------------------------------

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

            altitudeError * data.altitudeGain,

            -data.maxDescentSpeed,

            data.maxClimbSpeed

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

        altitudeControl -
        SYSTEM.altitudeControlSmooth


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


--------------------------------------------------
-- 07. MAIN TICK
--------------------------------------------------

function onTick()

    local descentMode =

    input.getBool(INPUT.DESCENT_MODE)


    local selectedAltitudeTarget

    if descentMode then

        selectedAltitudeTarget =
            input.getNumber(INPUT.DESCENT_TARGET)

    else

        selectedAltitudeTarget =
            input.getNumber(INPUT.ALTITUDE_TARGET)

    end

    -- READ PHYSICAL SENSORS AND PID PARAMETERS

    local data = {

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        altitudeTarget = 
            selectedAltitudeTarget,

        P =
            input.getNumber(INPUT.ALT_PID_P),

        I =
            input.getNumber(INPUT.ALT_PID_I),

        D =
            input.getNumber(INPUT.ALT_PID_D),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        maxClimbSpeed =
            input.getNumber(INPUT.MAX_CLIMB_SPEED),

        maxDescentSpeed =
            input.getNumber(INPUT.MAX_DESCENT_SPEED),

        altitudeGain =
            input.getNumber(INPUT.ALTITUDE_GAIN)

    }


    -- READ MASTER COMMAND

    local altitudeHoldEnabled =

        input.getBool(INPUT.ALTITUDE_HOLD)


    -- ALTITUDE CONTROLLER

    local altitude = updateAltitudeController(

        data,

        altitudeHoldEnabled

    )


    -- ELEVATOR OUTPUTS

    output.setNumber(

        OUTPUT.ELEVATOR_RIGHT,

        altitude.elevatorOutput

    )


    output.setNumber(

        OUTPUT.ELEVATOR_LEFT,

        altitude.elevatorOutput

    )


    -- DESIRED VERTICAL SPEED OUTPUT

    output.setNumber(

        OUTPUT.DESIRED_VERTICAL_SPEED,

        altitude.desiredVerticalSpeed

    )


end


-- END OF MC 04
