
-- OAI MIZUSHIMA YR-02
-- MC 01: FLIGHT SEQUENCE
-- VERSION: 1.0.0
--
-- ORIGINAL LOGIC: V13.1.0
-- MODULAR EXTRACTION
--
-- RESPONSIBILITY:
--   Flight sequence management
--
-- NO ABORT
-- NO TIMEOUT
-- NO AUTOMATIC RESTART
-- ORIGINAL CONDITIONS PRESERVED


-- 01. INPUT CONFIGURATION

local INPUT = {

    TILT_ROLL_HORIZ = 2,
    TILT_PITCH = 3,

    TARGET_RPS = 4,
    REAL_RPS = 5,

    ALTITUDE = 6,
    ALTITUDE_TARGET = 7,

    ALT_HOLD_DELAY = 11,
    VERTICAL_SPEED = 12,

    AP_KEYBOARD_X = 13,
    AP_KEYBOARD_Y = 14,

    AP_SENSOR_X = 15,
    AP_SENSOR_Y = 16,

    AP_CUTOFF = 19,

    VERTICAL_SPEED_TARGET = 22,

    START = 1
}


-- 02. OUTPUT CONFIGURATION

local OUTPUT = {

    -- NUMBER OUTPUTS

    SEQUENCE_STATE = 1,
    SEQUENCE_TIMER = 2,
    SPOILER = 3,

    ALTITUDE_STABLE_TIMER = 4,
    ROLL_STABLE_TIMER = 5,

    -- BOOLEAN OUTPUTS

    RUNNING = 1,
    COMPLETED = 2,

    ROLL_STABILIZER = 3,
    MAIN_BOOSTER = 4,
    DIRECTIONAL_TRIGGER = 5,

    BOTTOM_BOOSTERS = 6,
    ACCELERATION_BOOSTERS = 7,

    ALTITUDE_HOLD = 8,
    AUTOPILOT = 9,

    START_STATUS = 10
}


-- 03. SYSTEM CONFIGURATION

local CONFIG = {

    TICK_RATE = 60,

    ALTITUDE_STABLE_TIME = 2,

    ROLL_STABLE_TIME = 0.2

}


-- 04. CONDITION MARGINS

local MARGINS = {

    RPS = 1,

    ALTITUDE = 15,

    ROLL = 0.005,

    PITCH = 0.08,

    PITCH_STABILITY_TRIGGER = 0.01

}


-- 05. INPUT PROCESSING

local function readInputs()

    return {

        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltPitch =
            input.getNumber(INPUT.TILT_PITCH),

        targetRPS =
            input.getNumber(INPUT.TARGET_RPS),

        realRPS =
            input.getNumber(INPUT.REAL_RPS),

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        altitudeTarget =
            input.getNumber(INPUT.ALTITUDE_TARGET),

        altHoldDelay =
            input.getNumber(INPUT.ALT_HOLD_DELAY),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        verticalSpeedTarget =
            input.getNumber(INPUT.VERTICAL_SPEED_TARGET),

        keyboardX =
            input.getNumber(INPUT.AP_KEYBOARD_X),

        keyboardY =
            input.getNumber(INPUT.AP_KEYBOARD_Y),

        sensorX =
            input.getNumber(INPUT.AP_SENSOR_X),

        sensorY =
            input.getNumber(INPUT.AP_SENSOR_Y),

        cutoffDistance =
            input.getNumber(INPUT.AP_CUTOFF),

        start =
            input.getBool(INPUT.START)

    }

end


-- 06. SEQUENCE STATE

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

    -- One-tick event for PROPULSION CONTROL

    directionalBoosterTrigger = false,

    commands = {

        rollStabilizer = false,

        altitudeHold = false,

        autopilot = false,

        mainBooster = false,

        spoiler = 0,

        accelerationBoosters = false,

        bottomBoosters = false

    }

}


-- 07. FLIGHT PROGRAM
-- ORIGINAL V13.1.0 ORDER AND CONDITIONS

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


    -- STEP 5: BOTTOM BOOSTER SYSTEM

    {
        name = "BOTTOM_BOOSTER_SYSTEM",

        set = {
            bottomBoosters = true
        }

    },


    -- STEP 6: ACCELERATION BOOSTERS

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


    -- STEP 7: ROLL STABILITY CHECK

    {
        name = "ROLL_STABILITY_CHECK",

        set = {
            bottomBoosters = false
        },

        wait = {
            type = "roll"
        }
    },


    -- STEP 8: ALTITUDE HOLD

    {
        name = "ALTITUDE_HOLD",

        set = {
            altitudeHold = true
        },

        wait = {
            type = "altitude"
        }
    },


    -- STEP 9: AUTOPILOT ON

    {
        name = "AUTOPILOT",

        set = {
            autopilot = true
        },

        wait = {
            type = "autopilot_target"
        }
    },


    -- STEP 10: AUTOPILOT OFF

    {
        name = "AUTOPILOT_COMPLETE",

        set = {
            autopilot = false
        },

        hold = true

    }

}


-- 08. SEQUENCE STEP MANAGEMENT

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

    end


    -- SINGLE DIRECTIONAL BOOSTER ACTIVATION

    if index == 4
        and not SEQUENCE.directionalBoosterUsed then

        SEQUENCE.directionalBoosterUsed = true

        SEQUENCE.directionalBoosterTrigger = true

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


-- 09. SEQUENCE CONDITIONS

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

        return math.abs(data.tiltPitch) <= MARGINS.PITCH


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


-- 10. SEQUENCE EXECUTION

local function updateSequence(data)

    -- RESET ONE-TICK EVENT

    SEQUENCE.directionalBoosterTrigger = false


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


    local step = FLIGHT_PROGRAM[SEQUENCE.state]


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

    SEQUENCE.timer = SEQUENCE.timer + 1


    -- CHECK CONDITION

    if checkSequenceCondition(data, step.wait) then

        local nextStep = SEQUENCE.state + 1


        if nextStep > #FLIGHT_PROGRAM then

            SEQUENCE.completed = true

            SEQUENCE.running = false

        else

            enterSequenceStep(nextStep)

        end

    end

end


-- 11. OUTPUT PROCESSING

local function writeOutputs(data)

    -- NUMBER OUTPUTS

    output.setNumber(
        OUTPUT.SEQUENCE_STATE,
        SEQUENCE.state
    )

    output.setNumber(
        OUTPUT.SEQUENCE_TIMER,
        SEQUENCE.timer
    )

    output.setNumber(
        OUTPUT.SPOILER,
        SEQUENCE.commands.spoiler
    )

    output.setNumber(
        OUTPUT.ALTITUDE_STABLE_TIMER,
        SEQUENCE.altitudeStableTimer
    )

    output.setNumber(
        OUTPUT.ROLL_STABLE_TIMER,
        SEQUENCE.rollStableTimer
    )


    -- BOOLEAN OUTPUTS

    output.setBool(
        OUTPUT.RUNNING,
        SEQUENCE.running
    )

    output.setBool(
        OUTPUT.COMPLETED,
        SEQUENCE.completed
    )

    output.setBool(
        OUTPUT.ROLL_STABILIZER,
        SEQUENCE.commands.rollStabilizer
    )

    output.setBool(
        OUTPUT.MAIN_BOOSTER,
        SEQUENCE.commands.mainBooster
    )

    output.setBool(
        OUTPUT.DIRECTIONAL_TRIGGER,
        SEQUENCE.directionalBoosterTrigger
    )

    output.setBool(
        OUTPUT.BOTTOM_BOOSTERS,
        SEQUENCE.commands.bottomBoosters
    )

    output.setBool(
        OUTPUT.ACCELERATION_BOOSTERS,
        SEQUENCE.commands.accelerationBoosters
    )

    output.setBool(
        OUTPUT.ALTITUDE_HOLD,
        SEQUENCE.commands.altitudeHold
    )

    output.setBool(
        OUTPUT.AUTOPILOT,
        SEQUENCE.commands.autopilot
    )

    output.setBool(
        OUTPUT.START_STATUS,
        data.start
    )

end


-- 12. MAIN TICK

function onTick()

    local data = readInputs()

    updateSequence(data)

    writeOutputs(data)

end


-- END OF MC 01
-- OAI MIZUSHIMA YR-02
