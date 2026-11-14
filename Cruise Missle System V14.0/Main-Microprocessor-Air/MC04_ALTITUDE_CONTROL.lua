
-- OAI MIZUSHIMA YR-02
-- MC 04: ALTITUDE CONTROL
-- VERSION: 1.5.1
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Altitude PID control and elevator management
--   Independent descent vertical speed control


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    -- Numerical Inputs

    ALTITUDE = 1,
    ALTITUDE_SETPOINT = 2,

    ALT_PID_P = 3,
    ALT_PID_I = 4,
    ALT_PID_D = 5,

    VERTICAL_SPEED = 6,
    MAX_CLIMB_SPEED = 7,
    MAX_DESCENT_SPEED = 8,

    ALTITUDE_GAIN = 9,

    DESCENT_TARGET = 10,
    DESCENT_SPEED_TARGET = 11,

    -- Boolean Inputs

    ALTITUDE_HOLD = 8,
    DESCENT_MODE = 9

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    ELEVATOR_RIGHT = 3,
    ELEVATOR_LEFT = 4,

    DESIRED_VERTICAL_SPEED = 5,

    ALTITUDE_TARGET = 6

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    TICK_RATE = 60,

    CONTROL_MIN = -1,
    CONTROL_MAX = 0.45,

    INTEGRAL_LIMIT = 10,

    CLIMB_CONTROL_RATE = 0.005,

    DESCENT_CONTROL_RATE = 0.020

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    -- NORMAL ALTITUDE PID

    integral = 0,

    previousVerticalSpeed = 0,

    -- INDEPENDENT DESCENT PID

    descentIntegral = 0,

    descentPreviousVerticalSpeed = 0,

    -- COMMON ELEVATOR OUTPUT

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

local function updateAltitudeController(data, enabled, descentMode)

    local dt = 1 / CONFIG.TICK_RATE

    local altitudeError =

        data.altitudeTarget - data.altitude

    local desiredVerticalSpeed = 0

    local speedError = 0

    local altitudeControl = 0


    if enabled then

        --------------------------------------------------
        -- OUTER LOOP
        --------------------------------------------------

        if descentMode then

            -- DESCENT SPEED REFERENCE FROM MC08

            desiredVerticalSpeed = data.descentSpeedTarget

        else

            -- ORIGINAL ALTITUDE HOLD LOGIC
            -- CLIMB BEHAVIOUR PRESERVED

            desiredVerticalSpeed = clamp(

                altitudeError * data.altitudeGain,

                -data.maxDescentSpeed,

                data.maxClimbSpeed

            )

        end


        --------------------------------------------------
        -- INNER VERTICAL SPEED PID
        --------------------------------------------------

        speedError =

            desiredVerticalSpeed - data.verticalSpeed


        -- SELECT INDEPENDENT PID MEMORY

        local integral

        local previousVerticalSpeed

        if descentMode then

            integral = SYSTEM.descentIntegral

            previousVerticalSpeed =
                SYSTEM.descentPreviousVerticalSpeed

        else

            integral = SYSTEM.integral

            previousVerticalSpeed =
                SYSTEM.previousVerticalSpeed

        end


        local proportional =

            data.P * speedError


        local verticalAcceleration =

            (data.verticalSpeed -
            previousVerticalSpeed) / dt


        local derivativeTerm =

            -data.D * verticalAcceleration


        --------------------------------------------------
        -- INTEGRAL / ANTI-WINDUP
        --------------------------------------------------

        local candidateIntegral = clamp(

            integral + speedError * dt,

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

            integral = candidateIntegral

        end


        -- SAVE PID MEMORY SEPARATELY

        if descentMode then

            SYSTEM.descentIntegral = integral

        else

            SYSTEM.integral = integral

        end


        altitudeControl = clamp(

            outputWithoutIntegral +
            data.I * integral,

            CONFIG.CONTROL_MIN,

            CONFIG.CONTROL_MAX

        )


        -- UPDATE DERIVATIVE MEMORY

        if descentMode then

            SYSTEM.descentPreviousVerticalSpeed =
                data.verticalSpeed

        else

            SYSTEM.previousVerticalSpeed =
                data.verticalSpeed

        end


    else

        SYSTEM.integral = 0

        SYSTEM.previousVerticalSpeed =
            data.verticalSpeed

        SYSTEM.descentIntegral = 0

        SYSTEM.descentPreviousVerticalSpeed =
            data.verticalSpeed

        SYSTEM.altitudeControlSmooth = 0

    end


    --------------------------------------------------
    -- 07. ELEVATOR SMOOTHING
    --------------------------------------------------

    local controlRate


    if descentMode then

        -- INDEPENDENT DESCENT RESPONSE

        controlRate = CONFIG.DESCENT_CONTROL_RATE

    else

        -- ORIGINAL NORMAL RESPONSE
        -- CLIMB LOGIC UNCHANGED

        if altitudeControl > SYSTEM.altitudeControlSmooth then

            controlRate = CONFIG.CLIMB_CONTROL_RATE

        else

            controlRate = CONFIG.DESCENT_CONTROL_RATE

        end

    end


    local difference =

        altitudeControl -
        SYSTEM.altitudeControlSmooth


    SYSTEM.altitudeControlSmooth =

        SYSTEM.altitudeControlSmooth +

        clamp(

            difference,

            -controlRate,
            controlRate

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
-- 08. MAIN TICK
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
            input.getNumber(INPUT.ALTITUDE_SETPOINT)

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
            input.getNumber(INPUT.ALTITUDE_GAIN),

        descentSpeedTarget =
            input.getNumber(INPUT.DESCENT_SPEED_TARGET)

    }


    -- READ MASTER COMMAND

    local altitudeHoldEnabled =

        input.getBool(INPUT.ALTITUDE_HOLD)


    -- ALTITUDE CONTROLLER

    local altitude = updateAltitudeController(

        data,

        altitudeHoldEnabled,

        descentMode

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

    output.setNumber(

        OUTPUT.ALTITUDE_TARGET,

        selectedAltitudeTarget

    )

end


-- END OF MC 04
