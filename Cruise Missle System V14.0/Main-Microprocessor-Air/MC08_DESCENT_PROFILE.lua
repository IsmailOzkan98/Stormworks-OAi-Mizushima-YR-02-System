
-- OAI MIZUSHIMA YR-02
-- MC 08: ADAPTIVE DESCENT PROFILE
-- VERSION: 1.6.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Adaptive descent profile
--   Moving platform tracking
--   Dynamic altitude correction
--   Vertical speed monitoring


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

    PROFILE_EXPONENT = 6,
    ARRIVAL_RADIUS = 7,

    VERTICAL_SPEED = 8,

    CLOSING_SPEED_FILTER = 9,

    DESCENT_SPEED_FILTER = 10,

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

    TICK_RATE = 60,

    ARRIVAL_ALTITUDE_TOLERANCE = 2,

    ARRIVAL_VERTICAL_SPEED_TOLERANCE = 0.5,

    FINAL_APPROACH_GAIN = 0.15,

    MIN_FINAL_DESCENT_SPEED = 0.3

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    previousEnable = false,

    descentStarted = false,

    descentCompleted = false,

    previousDistance = 0,

    distanceInitialized = false,

    closingSpeed = 0,

    descentTarget = 0,

    descentSpeedTarget = 0

}


--------------------------------------------------
-- 05. GENERAL UTILITIES
--------------------------------------------------

local function clamp(value, min, max)

    return math.max(min, math.min(max, value))

end


local function lerp(current, target, factor)

    return current + (target - current) * factor

end


--------------------------------------------------
-- 06. RESET SYSTEM
--------------------------------------------------

local function resetSystem(data)

    SYSTEM.descentStarted = false

    SYSTEM.descentCompleted = false

    SYSTEM.distanceInitialized = false

    SYSTEM.previousDistance = data.distance

    SYSTEM.closingSpeed = 0

    SYSTEM.descentTarget = data.altitude

    SYSTEM.descentSpeedTarget = 0

end


--------------------------------------------------
-- 07. DISTANCE TRACKING
--------------------------------------------------

local function updateClosingSpeed(distance)

    if not SYSTEM.distanceInitialized then

        SYSTEM.previousDistance = distance

        SYSTEM.distanceInitialized = true

        SYSTEM.closingSpeed = 0

        return 0

    end


    -- Positive = approaching platform.
    -- Negative = moving away from platform.

    local rawClosingSpeed =

        (SYSTEM.previousDistance - distance) *
        CONFIG.TICK_RATE


    SYSTEM.previousDistance = distance


    if rawClosingSpeed <= 0 then

        SYSTEM.closingSpeed = 0

        return 0

    end


    SYSTEM.closingSpeed = lerp(

        SYSTEM.closingSpeed,

        rawClosingSpeed,

        data.closingSpeedFilter

    )


    return SYSTEM.closingSpeed

end


--------------------------------------------------
-- 08. DYNAMIC DESCENT DISTANCE
--------------------------------------------------

local function calculateStartDistance(

    altitudeDifference,

    closingSpeed,

    maxDescentSpeed,

    profileExponent

)

    if altitudeDifference <= 0
        or closingSpeed <= 0
        or maxDescentSpeed <= 0 then

        return 0

    end


    return

        profileExponent *
        altitudeDifference *
        closingSpeed /
        maxDescentSpeed

end


--------------------------------------------------
-- 09. ADAPTIVE DESCENT PROFILE
--------------------------------------------------

local function updateDescent(data, enabled)

    local risingEdge =

        enabled and not SYSTEM.previousEnable


    SYSTEM.previousEnable = enabled


    --------------------------------------------------
    -- RESET WHEN DISABLED
    --------------------------------------------------

    if not enabled then

        resetSystem(data)

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- INITIALIZE DESCENT
    --------------------------------------------------

    if risingEdge then

        resetSystem(data)

        SYSTEM.descentStarted = true

    end


    if not SYSTEM.descentStarted then

        return data.altitude, 0

    end


    --------------------------------------------------
    -- UPDATE DYNAMIC DISTANCE
    --------------------------------------------------

    local closingSpeed = updateClosingSpeed(

        data.distance

    )


    --------------------------------------------------
    -- READ CURRENT CONDITIONS
    --------------------------------------------------

    local altitudeDifference = math.max(

        0,

        data.altitude -
        data.destinationAltitude

    )


    local maxDescentSpeed = math.abs(

        data.maxDescentSpeed

    )


    local profileExponent = math.max(

        1,

        data.profileExponent

    )


    local arrivalRadius = math.max(

        0,

        data.arrivalRadius

    )


    -- Negative vertical speed means descent.

    local verticalSpeed = data.verticalSpeed


    local altitudeError =

        data.altitude -
        data.destinationAltitude


    --------------------------------------------------
    -- ARRIVAL DETECTION
    --------------------------------------------------

    if data.distance <= arrivalRadius

        and math.abs(altitudeError) <=
            CONFIG.ARRIVAL_ALTITUDE_TOLERANCE

        and math.abs(verticalSpeed) <=
            CONFIG.ARRIVAL_VERTICAL_SPEED_TOLERANCE then

        SYSTEM.descentCompleted = true

    end


    --------------------------------------------------
    -- FINAL ALTITUDE HOLD
    --------------------------------------------------

    if SYSTEM.descentCompleted then

        SYSTEM.descentTarget =
            data.destinationAltitude

        SYSTEM.descentSpeedTarget = 0

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- DYNAMIC START DISTANCE
    --------------------------------------------------

    local startDistance = calculateStartDistance(

        altitudeDifference,

        closingSpeed,

        maxDescentSpeed,

        profileExponent

    )


    --------------------------------------------------
    -- DESCENT SPEED CALCULATION
    --------------------------------------------------

    local desiredDescentSpeed = 0


    --------------------------------------------------
    -- NORMAL APPROACH
    --------------------------------------------------

    if data.distance > arrivalRadius

        and startDistance > 0

        and data.distance < startDistance then


        local progress = clamp(

            1 - data.distance / startDistance,

            0,

            1

        )


        local profileRamp =

            progress ^ (profileExponent - 1)


        local effectiveDistance = math.max(

            data.distance,

            arrivalRadius

        )


        local requiredDescentSpeed =

            altitudeDifference *
            closingSpeed /
            effectiveDistance


        desiredDescentSpeed =

            requiredDescentSpeed *
            profileRamp

    end


    --------------------------------------------------
    -- FINAL APPROACH
    --------------------------------------------------

    if data.distance <= arrivalRadius

        and altitudeDifference >
            CONFIG.ARRIVAL_ALTITUDE_TOLERANCE then


        desiredDescentSpeed = math.max(

            CONFIG.MIN_FINAL_DESCENT_SPEED,

            altitudeDifference *
            CONFIG.FINAL_APPROACH_GAIN

        )

    end


    --------------------------------------------------
    -- VERTICAL SPEED SAFETY
    --------------------------------------------------

    -- If already close to destination altitude,
    -- stop requesting further descent.

    if altitudeError <=
        CONFIG.ARRIVAL_ALTITUDE_TOLERANCE then

        desiredDescentSpeed = 0

    end


    --------------------------------------------------
    -- SPEED LIMIT
    --------------------------------------------------

    desiredDescentSpeed = clamp(

        desiredDescentSpeed,

        0,

        maxDescentSpeed

    )


    --------------------------------------------------
    -- DESCENT SPEED STABILIZATION
    --------------------------------------------------

    if closingSpeed <= 0

        and data.distance > arrivalRadius then

        SYSTEM.descentSpeedTarget = 0

    else

        SYSTEM.descentSpeedTarget = lerp(

            SYSTEM.descentSpeedTarget,

            -desiredDescentSpeed,

            data.descentSpeedFilter

        )

    end


    --------------------------------------------------
    -- DYNAMIC ALTITUDE REFERENCE
    --------------------------------------------------

    local dt = 1 / CONFIG.TICK_RATE


    SYSTEM.descentTarget =

        SYSTEM.descentTarget +
        SYSTEM.descentSpeedTarget * dt


    --------------------------------------------------
    -- ALTITUDE LIMITS
    --------------------------------------------------

    if SYSTEM.descentTarget <
        data.destinationAltitude then

        SYSTEM.descentTarget =
            data.destinationAltitude

    end


    if SYSTEM.descentTarget > data.altitude then

        SYSTEM.descentTarget = data.altitude

    end


    return

        SYSTEM.descentTarget,

        SYSTEM.descentSpeedTarget

end


--------------------------------------------------
-- 10. MAIN TICK
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
            input.getNumber(INPUT.DESTINATION_ALTITUDE),

        profileExponent =
            input.getNumber(INPUT.PROFILE_EXPONENT),

        arrivalRadius =
            input.getNumber(INPUT.ARRIVAL_RADIUS),

        verticalSpeed =
            input.getNumber(INPUT.VERTICAL_SPEED),

        closingSpeedFilter =
            input.getNumber(INPUT.CLOSING_SPEED_FILTER),
        
        descentSpeedFilter =
            input.getNumber(INPUT.DESCENT_SPEED_FILTER)

    }


    local descentEnabled =

        input.getBool(INPUT.DESCENT_ENABLE)


    local descentTarget, descentSpeedTarget =

        updateDescent(

            data,

            descentEnabled

        )


    --------------------------------------------------
    -- OUTPUTS
    --------------------------------------------------

    output.setNumber(

        OUTPUT.DESCENT_TARGET,

        descentTarget

    )


    output.setNumber(

        OUTPUT.DESCENT_SPEED_TARGET,

        descentSpeedTarget

    )

end


-- END OF MC08 v1.6.0
