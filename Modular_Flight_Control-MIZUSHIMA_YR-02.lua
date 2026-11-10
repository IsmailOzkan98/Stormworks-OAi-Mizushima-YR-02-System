
-- OAI MIZUSHIMA YR-02
-- MODULAR FLIGHT CONTROL
-- Stormworks
-- Version: 13.1.0
--
-- Single File
--
-- FUNCTIONS:
--   1. Roll Stabilizer
--   2. Altitude Hold
--   3. Autopilot
--
-- ACTUATORS:
--   Main Booster
--   Directional Boosters
--   Acceleration Boosters
--   Trust Spoiler
--   Ailerons
--   Elevators
--
-- FLIGHT SEQUENCE:
--  1. ENGINE CHECK
--  2. ROLL STABILIZER
--  3. MAIN BOOSTER
--  4. DIRECTIONAL BOOSTER
--  5. BOTTOM BOOSTER SYSTEM
--  6. ACCELERATION BOOSTERS
--  7. ROLL STABILITY CHECK
--  8. ALTITUDE HOLD
--  9. AUTOPILOT
--  10. AUTOPILOT COMPLETE
--
-- NO ABORT
-- NO TIMEOUT
-- CONFIGURABLE MARGINS


-- 01. INPUT CONFIGURATION


local INPUT = {

    MULTIPLIER      = 1,
    TILT_ROLL_HORIZ = 2,
    TILT_PITCH      = 3,

    TARGET_RPS      = 4,
    REAL_RPS        = 5,

    ALTITUDE        = 6,
    ALTITUDE_TARGET = 7,

    PID_P           = 8,
    PID_I           = 9,
    PID_D           = 10,

    ALT_HOLD_DELAY  = 11,
    VERTICAL_SPEED  = 12,

    AP_KEYBOARD_X   = 13,
    AP_KEYBOARD_Y   = 14,

    AP_SENSOR_X     = 15,
    AP_SENSOR_Y     = 16,

    AP_COMPASS      = 17,

    AP_STEERING     = 18,
    AP_CUTOFF       = 19,
    AP_DEADZONE     = 20,
    AP_SMOOTHING    = 21,

    VERTICAL_SPEED_TARGET = 22,

    TILT_ROLL_VERT = 23,

    START = 1
}



-- 02. OUTPUT CONFIGURATION


local OUTPUT = {

    -- NUMBER OUTPUTS

    ROLL_LEFT       = 1,
    ROLL_RIGHT      = 2,

    ELEVATOR_LEFT   = 3,
    ELEVATOR_RIGHT  = 4,

    SPOILER         = 5,

    AP_YAW          = 6,
    AP_DISTANCE     = 7,

    AP_MY_X         = 8,
    AP_MY_Y         = 9,
    AP_TARGET_X     = 10,
    AP_TARGET_Y     = 11,

    -- BOOLEAN OUTPUTS

    MAIN_BOOSTER    = 1,

    BOOSTER_NORTH   = 5,
    BOOSTER_EAST    = 6,
    BOOSTER_SOUTH   = 7,
    BOOSTER_WEST    = 8,

    ACCELERATION_BOOSTER  = 9,

    START_STATUS    = 32
}



-- 03. SYSTEM CONFIGURATION


local CONFIG = {

    TICK_RATE = 60,

    ALTITUDE_GAIN = 0.35,

    MAX_CLIMB_SPEED = 105,
    MAX_DESCENT_SPEED = 125,

    CONTROL_MIN = -0.45,
    CONTROL_MAX = 0.45,

    INTEGRAL_LIMIT = 10,

    CONTROL_RATE = 0.005,

    ALTITUDE_STABLE_TIME = 2,

    ROLL_STABLE_TIME = 0.2,

    DIRECTIONAL_BOOSTER_PULSE = 0.2

}



-- 03.1 TELEMETRY CONFIGURATION


local TELEMETRY = {

    ENABLED = true,

    PORT = 8080,

    INTERVAL = 6,

    tick = 0

}



-- 04. CONDITION MARGINS


local MARGINS = {

    RPS = 1,

    ALTITUDE = 15,

    ROLL = 0.005,

    PITCH = 0.08,

    PITCH_STABILITY_TRIGGER = 0.01

}



-- 04.1 BOTTOM BOOSTER CONFIGURATION


local BOTTOM_CONFIG = {

    ENABLED = true,

    ZONE = 25 / 360,

    MIN_SENSOR_MAGNITUDE = 0.001

}


-- 05. SYSTEM STATE


local SYSTEM = {

    integral = 0,

    previousVerticalSpeed = 0,

    altitudeControlSmooth = 0,

    autopilotYaw = 0

}



-- 06. GENERAL UTILITIES


local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end



-- ANGLE DIFFERENCE


local function angleDifference(a, b)

    return math.abs(
        (a - b + 0.5) % 1 - 0.5
    )

end



-- 07. INPUT PROCESSING


local function readInputs()

    return {

        multiplier = input.getNumber(INPUT.MULTIPLIER),

        tiltRollHoriz = input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltRollVert = input.getNumber(INPUT.TILT_ROLL_VERT),

        tiltPitch = input.getNumber(INPUT.TILT_PITCH),

        targetRPS = input.getNumber(INPUT.TARGET_RPS),

        realRPS = input.getNumber(INPUT.REAL_RPS),

        altitude = input.getNumber(INPUT.ALTITUDE),

        altitudeTarget = input.getNumber(INPUT.ALTITUDE_TARGET),

        P = input.getNumber(INPUT.PID_P),

        I = input.getNumber(INPUT.PID_I),

        D = input.getNumber(INPUT.PID_D),

        altHoldDelay = input.getNumber(INPUT.ALT_HOLD_DELAY),

        verticalSpeed = input.getNumber(INPUT.VERTICAL_SPEED),

        verticalSpeedTarget =
            input.getNumber(INPUT.VERTICAL_SPEED_TARGET),

        start = input.getBool(INPUT.START),

        -- AUTOPILOT

        keyboardX = input.getNumber(INPUT.AP_KEYBOARD_X),

        keyboardY = input.getNumber(INPUT.AP_KEYBOARD_Y),

        sensorX = input.getNumber(INPUT.AP_SENSOR_X),

        sensorY = input.getNumber(INPUT.AP_SENSOR_Y),

        compass = input.getNumber(INPUT.AP_COMPASS),

        steeringPower = input.getNumber(INPUT.AP_STEERING),

        cutoffDistance = input.getNumber(INPUT.AP_CUTOFF),

        deadzone = input.getNumber(INPUT.AP_DEADZONE),

        yawSmoothing =
            input.getNumber(INPUT.AP_SMOOTHING) / 1000

    }

end



-- 08. FUNCTION 1: ROLL STABILIZER


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



-- 08.1 FUNCTION: PITCH STABILITY TRIGGER


local function checkPitchStability(data)

    return math.abs(data.tiltPitch)
        <= MARGINS.PITCH_STABILITY_TRIGGER

end



-- 08.2 FUNCTION: BOTTOM BOOSTER DETECTION


local function updateBottomBoosters(data, enabled)

    -- DEFAULT OUTPUT

    local result = {

        bottomUno = false,

        bottomDos = false,

        bottomTres = false,

        bottomCuatro = false

    }


    -- ENABLE CHECK

    if not enabled or not BOTTOM_CONFIG.ENABLED then

        return result

    end


    -- SENSOR MAGNITUDE CHECK

    local magnitude = math.sqrt(

        data.tiltRollHoriz * data.tiltRollHoriz +

        data.tiltRollVert * data.tiltRollVert

    )


    if magnitude < BOTTOM_CONFIG.MIN_SENSOR_MAGNITUDE then

        return result

    end


    -- RECONSTRUCT ROLL ANGLE

    local rollAngle = math.atan(

        data.tiltRollVert,

        data.tiltRollHoriz

    )


    -- BOTTOM DIRECTION

    local bottomAngle =

        (rollAngle + math.pi) % (math.pi * 2)


    -- NORMALIZE TO TURNS

    bottomAngle = bottomAngle / (math.pi * 2)


    -- DETECTION ZONE

    local halfZone = BOTTOM_CONFIG.ZONE / 2


    -- BOTTOM UNO

    result.bottomUno =

        angleDifference(bottomAngle, 0.25)
        <= halfZone


    -- BOTTOM DOS

    result.bottomDos =

        angleDifference(bottomAngle, 0.00)
        <= halfZone


    -- BOTTOM TRES

    result.bottomTres =

        angleDifference(bottomAngle, 0.75)
        <= halfZone


    -- BOTTOM CUATRO

    result.bottomCuatro =

        angleDifference(bottomAngle, 0.50)
        <= halfZone


    return result

end



-- 09. FUNCTION 2: AUTOPILOT


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



-- 10. FUNCTION 3: ALTITUDE HOLD


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



-- 11. SEQUENCE STATE


local SEQUENCE = {

    state = 0,

    timer = 0,

    altitudeStableTimer = 0,

    rollStableTimer = 0,

    running = false,

    completed = false,

    previousStart = false,

    verticalSpeedExceeded = false,

    directionalBoosterUsed = false,

    directionalBoosterPending = false,

    directionalBoosterPulseTicks = 0,

    directionalBoosterSelection = {
        north = false,
        east = false,
        south = false,
        west = false
    },

    commands = {

        -- FUNCTIONS

        rollStabilizer = false,

        altitudeHold = false,

        autopilot = false,

        -- ACTUATORS

        mainBooster = false,

        spoiler = 0,

        accelerationBoosters = false,

        bottomBoosters = false

    }

}



-- 12. FLIGHT PROGRAM


local FLIGHT_PROGRAM = {

    -- STEP 1: ENGINE CHECK

    {
        name = "ENGINE_CHECK",

        set = {

            spoiler = 1

        },

        wait = {

            type = "rps_min"

        }
    },


    -- STEP 2: ROLL STABILIZER

    {
        name = "ROLL_STABILIZER",

        set = {

            rollStabilizer = true

        },

        wait = {

            type = "rps_min"

        }
    },


    -- STEP 3: MAIN BOOSTER

    {
        name = "MAIN_BOOSTER",

        set = {

            mainBooster = true

        },

        wait = {

            type = "vertical_speed_max"

        }
    },


    -- STEP 4: DIRECTIONAL BOOSTER

    {
        name = "DIRECTIONAL_BOOSTER",

        wait = {
            type = "pitch"
        }
    },


    -- STEP 5: ACCELERATION BOOSTERS

    {
        name = "ACCELERATION_BOOSTERS",

        set = {

            accelerationBoosters = true,

            spoiler = 0

        },

        wait = {

            type = "alt_hold_delay"

        }
    },


    -- STEP 6: ROLL STABILITY CHECK

    {
        name = "ROLL_STABILITY_CHECK",

        wait = {

            type = "roll"

        }
    },


    -- STEP 7: ALTITUDE HOLD

    {
        name = "ALTITUDE_HOLD",

        set = {

            altitudeHold = true

        },

        wait = {

            type = "altitude"

        }
    },


    -- STEP 8: AUTOPILOT ON

    {
        name = "AUTOPILOT",

        set = {

            autopilot = true

        },

        wait = {

            type = "autopilot_target"

        }
    },


    -- STEP 9: AUTOPILOT OFF

    {
        name = "AUTOPILOT_COMPLETE",

        set = {

            autopilot = false

        },

        hold = true

    }

}



-- 13. SEQUENCE STEP MANAGEMENT


local function enterSequenceStep(index)

    local step = FLIGHT_PROGRAM[index]

    if not step then

        return

    end


    SEQUENCE.state = index

    SEQUENCE.timer = 0

    SEQUENCE.altitudeStableTimer = 0

    SEQUENCE.rollStableTimer = 0

    -- RESET DIRECTIONAL BOOSTER FOR NEW FLIGHT

    if index == 1 then

        SEQUENCE.directionalBoosterUsed = false

        SEQUENCE.directionalBoosterPending = false

        SEQUENCE.directionalBoosterPulseTicks = 0

    end


    -- SINGLE DIRECTIONAL BOOSTER ACTIVATION

    if index == 4 and not SEQUENCE.directionalBoosterUsed then

        SEQUENCE.directionalBoosterUsed = true

        SEQUENCE.directionalBoosterPending = true

    end


    if index == 3 then
        SEQUENCE.verticalSpeedExceeded = false
    end


    if step.set then

        for key, value in pairs(step.set) do

            SEQUENCE.commands[key] = value

        end

    end

end



-- 14. SEQUENCE CONDITIONS


local function checkSequenceCondition(data, wait)

    if not wait then

        return true

    end


    -- RPS CHECK

    if wait.type == "rps_min" then

        return data.realRPS >=

            (data.targetRPS - MARGINS.RPS)


    -- VERTICAL SPEED THRESHOLD

    elseif wait.type == "vertical_speed_max" then

        if data.verticalSpeed > data.verticalSpeedTarget then

            SEQUENCE.verticalSpeedExceeded = true

        end

        return SEQUENCE.verticalSpeedExceeded
            and data.verticalSpeed <= data.verticalSpeedTarget


    -- PITCH CHECK

    elseif wait.type == "pitch" then

        return math.abs(data.tiltPitch) <=
            MARGINS.PITCH


    -- ALTITUDE HOLD DELAY

    elseif wait.type == "alt_hold_delay" then

        local delayTicks =

            math.max(0, data.altHoldDelay) *
            CONFIG.TICK_RATE

        return SEQUENCE.timer >= delayTicks


    -- ALTITUDE STABILITY

    elseif wait.type == "altitude" then

        local altitudeStable =

            math.abs(data.altitudeTarget - data.altitude)
            <= MARGINS.ALTITUDE


        if altitudeStable then

            SEQUENCE.altitudeStableTimer =

                SEQUENCE.altitudeStableTimer + 1

        else

            SEQUENCE.altitudeStableTimer = 0

        end


        local requiredTicks =

            CONFIG.ALTITUDE_STABLE_TIME *
            CONFIG.TICK_RATE


        return altitudeStable and

            SEQUENCE.altitudeStableTimer >= requiredTicks


    -- ROLL STABILITY CHECK

elseif wait.type == "roll" then

    local rollStable =

        math.abs(data.tiltRollHoriz) <= MARGINS.ROLL


    if rollStable then

        SEQUENCE.rollStableTimer =
            SEQUENCE.rollStableTimer + 1

    else

        SEQUENCE.rollStableTimer = 0

    end


    local requiredTicks =

        CONFIG.ROLL_STABLE_TIME *
        CONFIG.TICK_RATE


    return SEQUENCE.rollStableTimer >= requiredTicks


    -- AUTOPILOT TARGET

    elseif wait.type == "autopilot_target" then

        local x = data.keyboardX - data.sensorX

        local y = data.keyboardY - data.sensorY

        local distance = math.sqrt(x*x + y*y)

        return distance < data.cutoffDistance

    end


    return false

end



-- 15. SEQUENCE EXECUTION


local function updateSequence(data)

    -- START BUTTON EDGE

    local startEdge =

        data.start and
        not SEQUENCE.previousStart


    SEQUENCE.previousStart = data.start


    -- START SEQUENCE

    if startEdge

        and not SEQUENCE.running

        and not SEQUENCE.completed then

        SEQUENCE.running = true

        enterSequenceStep(1)

    end


    if not SEQUENCE.running then

        return

    end


    local step =

        FLIGHT_PROGRAM[SEQUENCE.state]


    if not step then

        SEQUENCE.running = false

        return

    end


    -- FINAL STEP

    if step.hold then

        SEQUENCE.completed = true

        SEQUENCE.running = false

        return

    end


    -- STEP TIMER

    SEQUENCE.timer =

        SEQUENCE.timer + 1


    -- CHECK CONDITION

    if checkSequenceCondition(data, step.wait) then

        local nextStep =

            SEQUENCE.state + 1


        if nextStep > #FLIGHT_PROGRAM then

            SEQUENCE.completed = true

            SEQUENCE.running = false

        else

            enterSequenceStep(nextStep)

        end

    end

end



-- 16. DIRECTIONAL BOOSTER SELECTION


local function getDirectionalBoosters(targetHeading, enabled)

    -- OPPOSITE HEADING

    local oppositeBoosters =

        (targetHeading + 0.5) % 1


    oppositeBoosters =

        (oppositeBoosters + 0.5) % 1 - 0.5


    -- NORTH

    local north = enabled and

        (
            oppositeBoosters >= -0.125
            and oppositeBoosters < 0.125
        )


    -- EAST

    local east = enabled and

        (
            oppositeBoosters >= 0.125
            and oppositeBoosters < 0.375
        )


    -- SOUTH

    local south = enabled and

        (
            oppositeBoosters >= 0.375
            or oppositeBoosters < -0.375
        )


    -- WEST

    local west = enabled and

        (
            oppositeBoosters >= -0.375
            and oppositeBoosters < -0.125
        )


    return {

        north = north,

        east = east,

        south = south,

        west = west

    }

end




-- 18. OUTPUT PROCESSING


local function writeOutputs(
    flight,
    altitude,
    autopilot,
    directional,
    data
)

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


    -- SPOILER

    output.setNumber(

        OUTPUT.SPOILER,

        SEQUENCE.commands.spoiler

    )


    -- MAIN BOOSTER

    output.setBool(

        OUTPUT.MAIN_BOOSTER,

        SEQUENCE.commands.mainBooster

    )


    -- DIRECTIONAL BOOSTERS

    output.setBool(

        OUTPUT.BOOSTER_NORTH,

        directional.north

    )


    output.setBool(

        OUTPUT.BOOSTER_EAST,

        directional.east

    )


    output.setBool(

        OUTPUT.BOOSTER_SOUTH,

        directional.south

    )


    output.setBool(

        OUTPUT.BOOSTER_WEST,

        directional.west

    )


   -- ACCELERATION BOOSTER

    output.setBool(
        OUTPUT.ACCELERATION_BOOSTER,
        SEQUENCE.commands.accelerationBoosters
    )


    -- START STATUS

    output.setBool(

        OUTPUT.START_STATUS,

        data.start

    )


    -- AUTOPILOT

    output.setNumber(

        OUTPUT.AP_YAW,

        autopilot.yaw

    )


    output.setNumber(

        OUTPUT.AP_DISTANCE,

        autopilot.distance

    )


    -- AUTOPILOT: CURRENT POSITION

    output.setNumber(

        OUTPUT.AP_MY_X,

        data.sensorX

    )


    output.setNumber(

        OUTPUT.AP_MY_Y,

        data.sensorY

    )


    -- AUTOPILOT: TARGET POSITION

    output.setNumber(

        OUTPUT.AP_TARGET_X,

        data.keyboardX

    )


    output.setNumber(

        OUTPUT.AP_TARGET_Y,

        data.keyboardY

    )

end



-- TELEMETRY TRANSMISSION


local function sendTelemetry(data, altitude, autopilot, directional)

    if not TELEMETRY.ENABLED then
        return
    end

    TELEMETRY.tick = TELEMETRY.tick + 1

    if TELEMETRY.tick < TELEMETRY.INTERVAL then
        return
    end

    TELEMETRY.tick = 0

    local step = FLIGHT_PROGRAM[SEQUENCE.state]

    local stage = step and step.name or "STANDBY"

    local status = "IDLE"

    if SEQUENCE.running then
        status = "RUNNING"
    elseif SEQUENCE.completed then
        status = "COMPLETED"
    end

    local url = string.format(
        "/telemetry?stage=%s&state=%d&status=%s&timer=%d&alt=%.2f&alt_target=%.2f&alt_error=%.2f&vs=%.2f&vs_target=%.2f&vs_error=%.2f&rps=%.2f&rps_target=%.2f&roll=%.4f&pitch=%.4f&ap=%d&ap_distance=%.2f&yaw=%.4f&my_x=%.2f&my_y=%.2f&target_x=%.2f&target_y=%.2f&main=%d&alt_hold=%d&roll_stab=%d&accel=%d&north=%d&east=%d&south=%d&west=%d&spoiler=%.2f",

        stage,
        SEQUENCE.state,
        status,
        SEQUENCE.timer,
        data.altitude,
        data.altitudeTarget,
        altitude.altitudeError,
        data.verticalSpeed,
        altitude.desiredVerticalSpeed,
        altitude.speedError,
        data.realRPS,
        data.targetRPS,
        data.tiltRollHoriz,
        data.tiltPitch,
        autopilot.enabled and 1 or 0,
        autopilot.distance,
        autopilot.yaw,
        data.sensorX,
        data.sensorY,
        data.keyboardX,
        data.keyboardY,
        SEQUENCE.commands.mainBooster and 1 or 0,
        SEQUENCE.commands.altitudeHold and 1 or 0,
        SEQUENCE.commands.rollStabilizer and 1 or 0,
        SEQUENCE.commands.accelerationBoosters and 1 or 0,
        directional.north and 1 or 0,
        directional.east and 1 or 0,
        directional.south and 1 or 0,
        directional.west and 1 or 0,
        SEQUENCE.commands.spoiler
    )

    async.httpGet(TELEMETRY.PORT, url)

end



-- 19. MAIN TICK


function onTick()

    local data = readInputs()
    

    -- FLIGHT SEQUENCE

    updateSequence(data)


    -- AUTOPILOT NAVIGATION CALCULATION
    -- Calculated even when Autopilot is disabled.

    local autopilot = updateAutopilot(

        data,

        SEQUENCE.commands.autopilot

    )


    -- DIRECTIONAL BOOSTER PULSE SYSTEM

    local directional = getDirectionalBoosters(
        autopilot.targetHeading,
        false
    )


    -- CAPTURE DIRECTION AT ACTIVATION

    if SEQUENCE.directionalBoosterPending then

        SEQUENCE.directionalBoosterSelection =
            getDirectionalBoosters(
                autopilot.targetHeading,
                true
            )

        SEQUENCE.directionalBoosterPulseTicks = math.max(
            1,
            math.ceil(
                CONFIG.DIRECTIONAL_BOOSTER_PULSE *
                CONFIG.TICK_RATE
            )
        )

        SEQUENCE.directionalBoosterPending = false

    end


    -- OUTPUT PULSE

    if SEQUENCE.directionalBoosterPulseTicks > 0 then

        directional = SEQUENCE.directionalBoosterSelection

        SEQUENCE.directionalBoosterPulseTicks =
            SEQUENCE.directionalBoosterPulseTicks - 1

    end


    -- FUNCTION 1: ROLL STABILIZER

    local flight = updateRollController(

        data,

        SEQUENCE.commands.rollStabilizer

    )


    -- FUNCTION 2: ALTITUDE HOLD

    local altitude = updateAltitudeController(

        data,

        SEQUENCE.commands.altitudeHold

    )


    
    -- BOTTOM BOOSTER DETECTION
    

    local bottom = updateBottomBoosters(

        data,

        SEQUENCE.commands.bottomBoosters

    )

    -- COMBINE DIRECTIONAL AND BOTTOM BOOSTERS

    local boosterOutputs = {

        north = directional.north or bottom.bottomDos,

        east = directional.east or bottom.bottomTres,

        south = directional.south or bottom.bottomCuatro,

        west = directional.west or bottom.bottomUno

    }


    -- OUTPUTS

    writeOutputs(

        flight,

        altitude,

        autopilot,

        boosterOutputs,

        data

    )


    -- TELEMETRY

    sendTelemetry(
        data,
        altitude,
        autopilot,
        boosterOutputs
    )

end



-- END OF YR-02
