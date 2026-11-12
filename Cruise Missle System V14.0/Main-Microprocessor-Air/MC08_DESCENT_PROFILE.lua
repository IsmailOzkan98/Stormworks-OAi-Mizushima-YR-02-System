
-- OAI MIZUSHIMA YR-02
-- MC 08: DESCENT PROFILE
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Progressive descent profile generation


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    -- Numerical Inputs

    ALTITUDE = 1,    --sensor
    AP_DISTANCE = 2, --output MC05 Num 7

    -- Boolean Inputs

    DESCENT_ENABLE = 1

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    DESCENT_TARGET = 1 --output MC04 Num 10

}


--------------------------------------------------
-- 03. SYSTEM CONFIGURATION
--------------------------------------------------

local CONFIG = {

    FINAL_ALTITUDE = 1,

    START_DISTANCE = 1500,

    CURVE_EXPONENT = 3,

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

    descentTarget = 100

}


--------------------------------------------------
-- 05. GENERAL UTILITIES
--------------------------------------------------

local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end


--------------------------------------------------
-- 06. DESCENT PROFILE
--------------------------------------------------

local function updateDescent(data, enabled)

    local risingEdge =
        enabled and not SYSTEM.previousEnable

    SYSTEM.previousEnable = enabled


    -- RESET WHEN DISABLED

    if not enabled then

        SYSTEM.descentStarted = false

        SYSTEM.descentCompleted = false

        SYSTEM.descentTarget = data.altitude

        return SYSTEM.descentTarget

    end


    -- CAPTURE INITIAL ALTITUDE

    if risingEdge then

        SYSTEM.initialAltitude = data.altitude

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


    -- PROGRESSIVE DESCENT CURVE

    local x = clamp(

        data.distance / CONFIG.START_DISTANCE,

        0,

        1

    )


   local curve = (1 - x) ^ CONFIG.CURVE_EXPONENT


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
-- 07. MAIN TICK
--------------------------------------------------

function onTick()

    local data = {

        altitude =
            input.getNumber(INPUT.ALTITUDE),

        distance =
            input.getNumber(INPUT.AP_DISTANCE)

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
