
-- OAI MIZUSHIMA YR-02
-- MC 08: DESCENT PROFILE
-- VERSION: 1.1.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Dynamic helicopter descent profile generation


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    -- Numerical Inputs

    ALTITUDE = 1,
    AP_DISTANCE = 2,

    HORIZONTAL_SPEED = 3,
    MAX_DESCENT_SPEED = 4,

    -- Boolean Inputs

    DESCENT_ENABLE = 1

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    DESCENT_TARGET = 1 

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    FINAL_ALTITUDE = 1,

    CURVE_EXPONENT = 3,

    DISTANCE_MARGIN = 1.20,

    ARRIVAL_RADIUS = 20

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    previousEnable = false,

    descentStarted = false,

    descentCompleted = false,

    initialAltitude = 100,

    startDistance = 0,

    descentTarget = 100

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

local function calculateStartDistance(data)

    local altitudeDifference = math.max(

        0,

        data.altitude - CONFIG.FINAL_ALTITUDE

    )

    local horizontalSpeed = math.abs(

        data.horizontalSpeed

    )

    local maxDescentSpeed = data.maxDescentSpeed


    if maxDescentSpeed <= 0 then

        return 0

    end


    local requiredDistance =

        altitudeDifference *

        horizontalSpeed *

        CONFIG.CURVE_EXPONENT /

        maxDescentSpeed


    return requiredDistance * CONFIG.DISTANCE_MARGIN

end


--------------------------------------------------
-- 07. DESCENT PROFILE
--------------------------------------------------

local function updateDescent(data, enabled)

    local risingEdge =

        enabled and not SYSTEM.previousEnable

    SYSTEM.previousEnable = enabled


    -- RESET WHEN DISABLED

    if not enabled then

        SYSTEM.descentStarted = false

        SYSTEM.descentCompleted = false

        SYSTEM.startDistance = 0

        SYSTEM.descentTarget = data.altitude

        return SYSTEM.descentTarget

    end


    -- CAPTURE INITIAL CONDITIONS

    if risingEdge then

        SYSTEM.initialAltitude = data.altitude

        SYSTEM.startDistance = calculateStartDistance(data)

        SYSTEM.descentStarted = true

        SYSTEM.descentCompleted = false

    end


    if not SYSTEM.descentStarted then

        return data.altitude

    end


    -- ARRIVAL DETECTION

    if data.distance <= CONFIG.ARRIVAL_RADIUS then

        SYSTEM.descentCompleted = true

    end


    -- HOLD FINAL ALTITUDE AFTER ARRIVAL

    if SYSTEM.descentCompleted then

        SYSTEM.descentTarget = CONFIG.FINAL_ALTITUDE

        return SYSTEM.descentTarget

    end


    -- WAIT FOR DESCENT START DISTANCE

    if SYSTEM.startDistance <= 0

        or data.distance >= SYSTEM.startDistance then

        SYSTEM.descentTarget = SYSTEM.initialAltitude

        return SYSTEM.descentTarget

    end


    -- PROGRESSIVE DESCENT CURVE

    local x = clamp(

        data.distance / SYSTEM.startDistance,

        0,

        1

    )


    local curve = 1 - (1 - x) ^ CONFIG.CURVE_EXPONENT


    SYSTEM.descentTarget =

        CONFIG.FINAL_ALTITUDE +

        (SYSTEM.initialAltitude - CONFIG.FINAL_ALTITUDE)
        * curve


    -- PREVENT TARGET FROM GOING BELOW FINAL ALTITUDE

    SYSTEM.descentTarget = math.max(

        CONFIG.FINAL_ALTITUDE,

        SYSTEM.descentTarget

    )


    return SYSTEM.descentTarget

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
            input.getNumber(INPUT.MAX_DESCENT_SPEED)

    }


    local descentEnabled =

        input.getBool(INPUT.DESCENT_ENABLE)


    local descentTarget = updateDescent(

        data,

        descentEnabled

    )


    output.setNumber(

        OUTPUT.DESCENT_TARGET,

        descentTarget

    )

end


-- END OF MC 08
