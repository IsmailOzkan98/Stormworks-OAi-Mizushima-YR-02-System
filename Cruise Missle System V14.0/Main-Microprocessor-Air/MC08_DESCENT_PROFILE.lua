
-- OAI MIZUSHIMA YR-02
-- MC 08: DESCENT PROFILE
-- VERSION: 1.2.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Predictive helicopter descent profile generation
--   Altitude and vertical speed reference generation


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    -- Numerical Inputs

    ALTITUDE = 1,
    AP_DISTANCE = 2,

    HORIZONTAL_SPEED = 3,
    MAX_DESCENT_SPEED = 4,

    DESTINATION_ALTITUDE = 5,

    -- Boolean Inputs

    DESCENT_ENABLE = 1

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    DESCENT_TARGET = 1,

    DESCENT_SPEED_TARGET = 2

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    PROFILE_EXPONENT = 3,

    ARRIVAL_RADIUS = 20

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    previousEnable = false,

    descentStarted = false,

    descentCompleted = false,

    initialAltitude = 0,

    destinationAltitude = 0,

    initialHorizontalSpeed = 0,

    profileMaxDescentSpeed = 0,

    startDistance = 0,

    descentTarget = 0,

    descentSpeedTarget = 0

}


--------------------------------------------------
-- 05. GENERAL UTILITIES
--------------------------------------------------

local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end


--------------------------------------------------
-- 06. DESCENT DISTANCE CALCULATION
--------------------------------------------------

local function calculateStartDistance(

    altitudeDifference,

    horizontalSpeed,

    maxDescentSpeed

)

    if altitudeDifference <= 0

        or horizontalSpeed <= 0

        or maxDescentSpeed <= 0 then

        return 0

    end


    return

        CONFIG.PROFILE_EXPONENT *

        altitudeDifference *

        horizontalSpeed /

        maxDescentSpeed

end


--------------------------------------------------
-- 07. DESCENT PROFILE
--------------------------------------------------

local function updateDescent(data, enabled)

    local risingEdge =

        enabled and not SYSTEM.previousEnable

    SYSTEM.previousEnable = enabled


    --------------------------------------------------
    -- RESET WHEN DISABLED
    --------------------------------------------------

    if not enabled then

        SYSTEM.descentStarted = false

        SYSTEM.descentCompleted = false

        SYSTEM.startDistance = 0

        SYSTEM.initialAltitude = data.altitude

        SYSTEM.destinationAltitude =
            data.destinationAltitude

        SYSTEM.descentTarget = data.altitude

        SYSTEM.descentSpeedTarget = 0

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- CAPTURE INITIAL CONDITIONS
    --------------------------------------------------

    if risingEdge then

        SYSTEM.initialAltitude = data.altitude

        SYSTEM.destinationAltitude =
            data.destinationAltitude

        SYSTEM.initialHorizontalSpeed =
            math.abs(data.horizontalSpeed)

        SYSTEM.profileMaxDescentSpeed =
            math.abs(data.maxDescentSpeed)

        local altitudeDifference = math.max(

            0,

            SYSTEM.initialAltitude -
            SYSTEM.destinationAltitude

        )


        SYSTEM.startDistance = calculateStartDistance(

            altitudeDifference,

            SYSTEM.initialHorizontalSpeed,

            SYSTEM.profileMaxDescentSpeed

        )


        SYSTEM.descentStarted = true

        SYSTEM.descentCompleted = false

    end


    if not SYSTEM.descentStarted then

        return data.altitude, 0

    end


    --------------------------------------------------
    -- WAIT FOR VALID INITIAL SPEED
    --------------------------------------------------

    if SYSTEM.startDistance <= 0

        and SYSTEM.initialAltitude >
            SYSTEM.destinationAltitude

        and SYSTEM.profileMaxDescentSpeed > 0

        and math.abs(data.horizontalSpeed) > 0 then

        SYSTEM.initialHorizontalSpeed =
            math.abs(data.horizontalSpeed)

        SYSTEM.startDistance = calculateStartDistance(

            SYSTEM.initialAltitude -
            SYSTEM.destinationAltitude,

            SYSTEM.initialHorizontalSpeed,

            SYSTEM.profileMaxDescentSpeed

        )

    end


    --------------------------------------------------
    -- ARRIVAL DETECTION
    --------------------------------------------------

    if data.distance <= CONFIG.ARRIVAL_RADIUS then

        SYSTEM.descentCompleted = true

    end


    --------------------------------------------------
    -- HOLD FINAL ALTITUDE AFTER ARRIVAL
    --------------------------------------------------

    if SYSTEM.descentCompleted then

        SYSTEM.descentTarget =
            SYSTEM.destinationAltitude

        SYSTEM.descentSpeedTarget = 0

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- WAIT FOR DESCENT START DISTANCE
    --------------------------------------------------

    if SYSTEM.startDistance <= 0

        or data.distance >= SYSTEM.startDistance then

        SYSTEM.descentTarget =
            SYSTEM.initialAltitude

        SYSTEM.descentSpeedTarget = 0

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- PREDICTIVE DESCENT PROFILE
    --------------------------------------------------

    local x = clamp(

        data.distance / SYSTEM.startDistance,

        0,

        1

    )


    local remainingFraction = 1 - x


    local altitudeDifference =

        SYSTEM.initialAltitude -
        SYSTEM.destinationAltitude


    --------------------------------------------------
    -- ALTITUDE REFERENCE
    --------------------------------------------------

    local descentProgress =
        remainingFraction ^ CONFIG.PROFILE_EXPONENT

    SYSTEM.descentTarget =
        SYSTEM.initialAltitude -
        altitudeDifference * descentProgress


    --------------------------------------------------
    -- VERTICAL SPEED REFERENCE
    --------------------------------------------------

    local horizontalSpeed = math.abs(data.horizontalSpeed)

    local speedRatio = 0

    if SYSTEM.initialHorizontalSpeed > 0 then
        speedRatio =
            horizontalSpeed / SYSTEM.initialHorizontalSpeed
    end

    local desiredDescentSpeed =
        SYSTEM.profileMaxDescentSpeed *
        speedRatio *
        remainingFraction ^ (CONFIG.PROFILE_EXPONENT - 1)

    desiredDescentSpeed = clamp(
        desiredDescentSpeed,
        0,
        SYSTEM.profileMaxDescentSpeed
    )

-- NEGATIVE VALUE: DESCENT COMMAND
SYSTEM.descentSpeedTarget = -desiredDescentSpeed


    -- DESCENT SPEED MUST BE NEGATIVE

    SYSTEM.descentSpeedTarget =

        -desiredDescentSpeed


    return

        SYSTEM.descentTarget,

        SYSTEM.descentSpeedTarget

end


--------------------------------------------------
-- 08. MAIN TICK
--------------------------------------------------

function onTick()

    local data = {

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        distance =
            input.getNumber(INPUT.AP_DISTANCE),

        horizontalSpeed =
            input.getNumber(INPUT.HORIZONTAL_SPEED),

        maxDescentSpeed =
            input.getNumber(INPUT.MAX_DESCENT_SPEED),

        destinationAltitude =
            input.getNumber(INPUT.DESTINATION_ALTITUDE)

    }


    local descentEnabled =

        input.getBool(INPUT.DESCENT_ENABLE)


    local descentTarget, descentSpeedTarget =

        updateDescent(

            data,

            descentEnabled

        )


    -- ALTITUDE TARGET OUTPUT

    output.setNumber(

        OUTPUT.DESCENT_TARGET,

        descentTarget

    )


    -- VERTICAL SPEED TARGET OUTPUT

    output.setNumber(

        OUTPUT.DESCENT_SPEED_TARGET,

        descentSpeedTarget

    )

end


-- END OF MC08
