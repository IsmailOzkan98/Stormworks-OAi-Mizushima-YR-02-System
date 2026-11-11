
-- OAI MIZUSHIMA YR-02
-- MC 02: MASTER CONTROL
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Command distribution and general management


--------------------------------------------------
-- INPUT CHANNELS
--------------------------------------------------

local INPUT = {

    RUNNING = 1,

    COMPLETED = 2,

    ROLL_STABILIZER = 3,

    MAIN_BOOSTER = 4,

    DIRECTIONAL_BOOSTER_TRIGGER = 5,

    BOTTOM_BOOSTERS = 6,

    ACCELERATION_BOOSTERS = 7,

    ALTITUDE_HOLD = 8,

    AUTOPILOT = 9,
    
    START_STATUS = 10
}

local INPUT_NUM = {

    SEQUENCE_STATE = 1,
    SEQUENCE_TIMER = 2,

    SPOILER = 3,

    ALTITUDE_STABLE_TIMER = 4,
    ROLL_STABLE_TIMER = 5
}


--------------------------------------------------
-- OUTPUT CHANNELS
--------------------------------------------------

local OUTPUT = {
    RUNNING = 1,
    COMPLETED = 2,
    ROLL_STABILIZER = 3,
    MAIN_BOOSTER = 4,
    DIRECTIONAL_BOOSTER_TRIGGER = 5,
    BOTTOM_BOOSTERS = 6,
    ACCELERATION_BOOSTERS = 7,
    ALTITUDE_HOLD = 8,
    AUTOPILOT = 9,
    START_STATUS = 10
}

local OUTPUT_NUM = {
    SEQUENCE_STATE = 1,
    SEQUENCE_TIMER = 2,
    SPOILER = 3,
    ALTITUDE_STABLE_TIMER = 4,
    ROLL_STABLE_TIMER = 5
}


--------------------------------------------------
-- MASTER CONTROL
--------------------------------------------------

function onTick()

    -- Boolean commands

    for name, channel in pairs(INPUT) do
        output.setBool(
            OUTPUT[name],
            input.getBool(channel)
        )
    end

    -- Numeric commands

    for name, channel in pairs(INPUT_NUM) do
        output.setNumber(
            OUTPUT_NUM[name],
            input.getNumber(channel)
        )
    end

end
