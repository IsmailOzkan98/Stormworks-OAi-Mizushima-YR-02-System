
-- OAI MIZUSHIMA YR-02
-- MC 06: PROPULSION
-- VERSION: 1.1.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Booster and spoiler management


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    SPOILER = 1,
    TARGET_HEADING = 2,

    TILT_ROLL_HORIZ = 3,
    TILT_ROLL_VERT = 4,

    MAIN_BOOSTER = 1,
    DIRECTIONAL_BOOSTER_TRIGGER = 2,
    BOTTOM_BOOSTERS = 3,
    ACCELERATION_BOOSTERS = 4,

    AFTERBURNER = 5

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    SPOILER = 5,

    MAIN_BOOSTER = 1,

    ACCELERATION_BOOSTER = 9,

    BOOSTER_NORTH = 5,
    BOOSTER_EAST = 6,
    BOOSTER_SOUTH = 7,
    BOOSTER_WEST = 8,

    AFTERBURNER = 10

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    TICK_RATE = 60,

    DIRECTIONAL_BOOSTER_PULSE = 0.2

}


--------------------------------------------------
-- 04. BOTTOM BOOSTER CONFIGURATION
--------------------------------------------------

local BOTTOM_CONFIG = {

    ENABLED = true,

    ZONE = 25 / 360,

    MIN_SENSOR_MAGNITUDE = 0.001

}


--------------------------------------------------
-- 05. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    directionalBoosterPulseTicks = 0,

    directionalBoosterSelection = {

        north = false,
        east = false,
        south = false,
        west = false

    },

    previousDirectionalTrigger = false

}


--------------------------------------------------
-- 06. GENERAL UTILITIES
--------------------------------------------------

local function angleDifference(a, b)

    return math.abs(

        (a - b + 0.5) % 1 - 0.5

    )

end


--------------------------------------------------
-- 07. DIRECTIONAL BOOSTER SELECTION
--------------------------------------------------

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


--------------------------------------------------
-- 08. BOTTOM BOOSTER DETECTION
--------------------------------------------------

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

        data.tiltRollHoriz,

        data.tiltRollVert

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


--------------------------------------------------
-- 09. DIRECTIONAL BOOSTER PULSE
--------------------------------------------------

local function updateDirectionalBooster(data, trigger)

    local directional = {

        north = false,
        east = false,
        south = false,
        west = false

    }


    -- DETECT TRIGGER RISING EDGE

    local triggerEdge =

        trigger and
        not SYSTEM.previousDirectionalTrigger


    SYSTEM.previousDirectionalTrigger = trigger


    -- CAPTURE DIRECTION AT ACTIVATION

    if triggerEdge then

        SYSTEM.directionalBoosterSelection =

            getDirectionalBoosters(

                data.targetHeading,

                true

            )


        SYSTEM.directionalBoosterPulseTicks = math.max(

            1,

            math.ceil(

                CONFIG.DIRECTIONAL_BOOSTER_PULSE *
                CONFIG.TICK_RATE

            )

        )

    end


    -- OUTPUT PULSE

    if SYSTEM.directionalBoosterPulseTicks > 0 then

        directional = SYSTEM.directionalBoosterSelection

        SYSTEM.directionalBoosterPulseTicks =

            SYSTEM.directionalBoosterPulseTicks - 1

    end


    return directional

end


--------------------------------------------------
-- 10. MAIN TICK
--------------------------------------------------

function onTick()

    -- READ PHYSICAL SENSORS

    local data = {

        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ),

        tiltRollVert =
            input.getNumber(INPUT.TILT_ROLL_VERT),

        targetHeading =
            input.getNumber(INPUT.TARGET_HEADING)

    }


    -- READ MASTER COMMANDS

    local spoiler =

        input.getNumber(INPUT.SPOILER)


    local mainBooster =

        input.getBool(INPUT.MAIN_BOOSTER)


    local directionalTrigger =

        input.getBool(INPUT.DIRECTIONAL_BOOSTER_TRIGGER)


    local bottomBoostersEnabled =

        input.getBool(INPUT.BOTTOM_BOOSTERS)


    local accelerationBoosters =

        input.getBool(INPUT.ACCELERATION_BOOSTERS)

    local afterburner =
        input.getBool(INPUT.AFTERBURNER)


    -- DIRECTIONAL BOOSTERS

    local directional = updateDirectionalBooster(

        data,

        directionalTrigger

    )


    -- BOTTOM BOOSTER DETECTION

    local bottom = updateBottomBoosters(

        data,

        bottomBoostersEnabled

    )


    -- COMBINE DIRECTIONAL AND BOTTOM BOOSTERS

    local boosterOutputs = {

        north = directional.north or bottom.bottomCuatro,

        east = directional.east or bottom.bottomTres,

        south = directional.south or bottom.bottomDos,

        west = directional.west or bottom.bottomUno

    }


    --------------------------------------------------
    -- OUTPUTS
    --------------------------------------------------

    -- SPOILER

    output.setNumber(

        OUTPUT.SPOILER,

        spoiler

    )


    -- MAIN BOOSTER

    output.setBool(

        OUTPUT.MAIN_BOOSTER,

        mainBooster

    )


    -- ACCELERATION BOOSTER

    output.setBool(

        OUTPUT.ACCELERATION_BOOSTER,

        accelerationBoosters

    )


    -- DIRECTIONAL / BOTTOM BOOSTERS

    output.setBool(

        OUTPUT.BOOSTER_NORTH,

        boosterOutputs.north

    )


    output.setBool(

        OUTPUT.BOOSTER_EAST,

        boosterOutputs.east

    )


    output.setBool(

        OUTPUT.BOOSTER_SOUTH,

        boosterOutputs.south

    )


    output.setBool(

        OUTPUT.BOOSTER_WEST,

        boosterOutputs.west

    )


    -- AFTERBURNER

    output.setBool(
        OUTPUT.AFTERBURNER,
        afterburner
    )

end


-- END OF MC 06
