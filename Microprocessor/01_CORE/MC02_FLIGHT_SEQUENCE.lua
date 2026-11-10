
-- OAI MIZUSHIMA YR-02
-- MC02: FLIGHT SEQUENCE
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    NUMBER = {
        TARGET_RPS = 1,
        REAL_RPS = 2,

        ALTITUDE = 3,
        ALTITUDE_TARGET = 4,

        ALT_HOLD_DELAY = 5,
        VERTICAL_SPEED = 6,
        VERTICAL_SPEED_TARGET = 7,

        TILT_PITCH = 8,
        TILT_ROLL_HORIZ = 9,

        AP_KEYBOARD_X = 10,
        AP_KEYBOARD_Y = 11,

        AP_SENSOR_X = 12,
        AP_SENSOR_Y = 13,

        AP_CUTOFF = 14
    },

    BOOL = {
        START = 1
    }
}

--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    NUMBER = {
        SPOILER_COMMAND = 1,
        SEQUENCE_STATE = 2,
        SEQUENCE_TIMER = 3
    },

    BOOL = {
        ROLL_STABILIZER_ENABLE = 1,
        ALTITUDE_HOLD_ENABLE = 2,
        AUTOPILOT_ENABLE = 3,

        MAIN_BOOSTER_COMMAND = 4,
        BOTTOM_BOOSTERS_ENABLE = 5,
        ACCELERATION_BOOSTERS_COMMAND = 6,

        DIRECTIONAL_BOOSTER_REQUEST = 7,

        SEQUENCE_RUNNING = 8,
        SEQUENCE_COMPLETED = 9,
        START_STATUS = 10
    }
}

--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    TICK_RATE = 60,

    ALTITUDE_STABLE_TIME = 2,

    ROLL_STABLE_TIME = 0.2
}

--------------------------------------------------
-- 04. CONDITION MARGINS
--------------------------------------------------

local MARGINS = {

    RPS = 1,

    ALTITUDE = 15,

    ROLL = 0.005,

    PITCH = 0.08
}

--------------------------------------------------
-- 05. INPUT PROCESSING
--------------------------------------------------

local function readInputs()

    return {

        targetRPS =
            input.getNumber(INPUT.NUMBER.TARGET_RPS),

        realRPS =
            input.getNumber(INPUT.NUMBER.REAL_RPS),

        altitude =
            input.getNumber(INPUT.NUMBER.ALTITUDE),

        altitudeTarget =
            input.getNumber(INPUT.NUMBER.ALTITUDE_TARGET),

        altHoldDelay =
            input.getNumber(INPUT.NUMBER.ALT_HOLD_DELAY),

        verticalSpeed =
            input.getNumber(INPUT.NUMBER.VERTICAL_SPEED),

        verticalSpeedTarget =
            input.getNumber(INPUT.NUMBER.VERTICAL_SPEED_TARGET),

        tiltPitch =
            input.getNumber(INPUT.NUMBER.TILT_PITCH),

        tiltRollHoriz =
            input.getNumber(INPUT.NUMBER.TILT_ROLL_HORIZ),

        keyboardX =
            input.getNumber(INPUT.NUMBER.AP_KEYBOARD_X),

        keyboardY =
            input.getNumber(INPUT.NUMBER.AP_KEYBOARD_Y),

        sensorX =
            input.getNumber(INPUT.NUMBER.AP_SENSOR_X),

        sensorY =
            input.getNumber(INPUT.NUMBER.AP_SENSOR_Y),

        cutoffDistance =
            input.getNumber(INPUT.NUMBER.AP_CUTOFF),

        start =
            input.getBool(INPUT.BOOL.START)
    }

end

--------------------------------------------------
-- 06. SEQUENCE STATE
--------------------------------------------------

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

    commands = {

        -- FUNCTIONS

        rollStabilizer = false,

        altitudeHold = false,

        autopilot = false,

        -- PROPULSION

        mainBooster = false,

        spoiler = 0,

        accelerationBoosters = false,

        bottomBoosters = false
    }
}

--------------------------------------------------
-- 07. FLIGHT PROGRAM
--------------------------------------------------

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

--------------------------------------------------
-- 08. SEQUENCE STEP MANAGEMENT
--------------------------------------------------

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

    end

    -- SINGLE DIRECTIONAL BOOSTER ACTIVATION

    if index == 4
        and not SEQUENCE.directionalBoosterUsed then

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

--------------------------------------------------
-- 09. SEQUENCE CONDITIONS
--------------------------------------------------

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

            math.max(0, data.altHoldDelay)
            * CONFIG.TICK_RATE

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

            CONFIG.ALTITUDE_STABLE_TIME
            * CONFIG.TICK_RATE

        return altitudeStable
            and SEQUENCE.altitudeStableTimer >= requiredTicks

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

            CONFIG.ROLL_STABLE_TIME
            * CONFIG.TICK_RATE

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

--------------------------------------------------
-- 10. SEQUENCE EXECUTION
--------------------------------------------------

local function updateSequence(data)

    -- START BUTTON EDGE

    local startEdge =

        data.start
        and not SEQUENCE.previousStart

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

--------------------------------------------------
-- 11. OUTPUT PROCESSING
--------------------------------------------------

local function writeOutputs(data)

    -- NUMERIC OUTPUTS

    output.setNumber(
        OUTPUT.NUMBER.SPOILER_COMMAND,
        SEQUENCE.commands.spoiler
    )

    output.setNumber(
        OUTPUT.NUMBER.SEQUENCE_STATE,
        SEQUENCE.state
    )

    output.setNumber(
        OUTPUT.NUMBER.SEQUENCE_TIMER,
        SEQUENCE.timer
    )

    -- FUNCTION COMMANDS

    output.setBool(
        OUTPUT.BOOL.ROLL_STABILIZER_ENABLE,
        SEQUENCE.commands.rollStabilizer
    )

    output.setBool(
        OUTPUT.BOOL.ALTITUDE_HOLD_ENABLE,
        SEQUENCE.commands.altitudeHold
    )

    output.setBool(
        OUTPUT.BOOL.AUTOPILOT_ENABLE,
        SEQUENCE.commands.autopilot
    )

    -- PROPULSION COMMANDS

    output.setBool(
        OUTPUT.BOOL.MAIN_BOOSTER_COMMAND,
        SEQUENCE.commands.mainBooster
    )

    output.setBool(
        OUTPUT.BOOL.BOTTOM_BOOSTERS_ENABLE,
        SEQUENCE.commands.bottomBoosters
    )

    output.setBool(
        OUTPUT.BOOL.ACCELERATION_BOOSTERS_COMMAND,
        SEQUENCE.commands.accelerationBoosters
    )

    -- DIRECTIONAL BOOSTER REQUEST
    -- One-tick request for MC06.

    output.setBool(
        OUTPUT.BOOL.DIRECTIONAL_BOOSTER_REQUEST,
        SEQUENCE.directionalBoosterPending
    )

    SEQUENCE.directionalBoosterPending = false

    -- SEQUENCE STATUS

    output.setBool(
        OUTPUT.BOOL.SEQUENCE_RUNNING,
        SEQUENCE.running
    )

    output.setBool(
        OUTPUT.BOOL.SEQUENCE_COMPLETED,
        SEQUENCE.completed
    )

    output.setBool(
        OUTPUT.BOOL.START_STATUS,
        data.start
    )

end

--------------------------------------------------
-- 12. MAIN TICK
--------------------------------------------------

function onTick()

    local data = readInputs()

    -- FLIGHT SEQUENCE

    updateSequence(data)

    -- OUTPUTS

    writeOutputs(data)

end

-- END OF MC02
