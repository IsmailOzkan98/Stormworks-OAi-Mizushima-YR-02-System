
-- OAI MIZUSHIMA YR-02
-- MC 08: ADAPTIVE DESCENT PROFILE
-- VERSION: 1.7.1
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
--   Dynamic geometric descent profile
--   Moving platform tracking
--   Adaptive vertical speed reference
--   Distance-based altitude targeting
--
-- CHANGES v1.7.0:
--   Direct altitude reference from AP_DISTANCE
--   Mathematical vertical speed calculation
--   Horizontal speed validation
--   Dynamic destination altitude
--   Removed accumulated altitude integration
--   Removed arrival completion lock
--   Removed final approach gain
--   Removed artificial minimum descent speed
--
-- INPUTS AND OUTPUTS:
--   Original channel assignments preserved


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

    TICK_RATE = 60

}


--------------------------------------------------
-- 04. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    previousEnable = false,

    descentStarted = false,

    previousDistance = 0,

    distanceInitialized = false,

    initialAltitude = 0,

    initialDistance = 0,

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

    SYSTEM.distanceInitialized = false

    SYSTEM.previousDistance = data.distance

    SYSTEM.initialAltitude = data.altitude

    SYSTEM.initialDistance = data.distance

    SYSTEM.closingSpeed = 0

    SYSTEM.descentTarget = data.altitude

    SYSTEM.descentSpeedTarget = 0

end


--------------------------------------------------
-- 07. DISTANCE TRACKING
--------------------------------------------------

local function updateClosingSpeed(

    distance,

    horizontalSpeed,

    filter

)

    if not SYSTEM.distanceInitialized then

        SYSTEM.previousDistance = distance

        SYSTEM.distanceInitialized = true

        SYSTEM.closingSpeed = 0

        return 0

    end


    --------------------------------------------------
    -- RAW CLOSING SPEED
    --------------------------------------------------

    local rawClosingSpeed =

        (SYSTEM.previousDistance - distance) *
        CONFIG.TICK_RATE


    SYSTEM.previousDistance = distance


    --------------------------------------------------
    -- NO APPROACH
    --------------------------------------------------

    if rawClosingSpeed <= 0 then

        SYSTEM.closingSpeed = 0

        return 0

    end


    --------------------------------------------------
    -- HORIZONTAL SPEED VALIDATION
    --------------------------------------------------

    if horizontalSpeed > 0 then

        rawClosingSpeed = math.min(

            rawClosingSpeed,

            horizontalSpeed

        )

    end


    --------------------------------------------------
    -- FILTER
    --------------------------------------------------

    SYSTEM.closingSpeed = lerp(

        SYSTEM.closingSpeed,

        rawClosingSpeed,

        clamp(filter, 0, 1)

    )


    return SYSTEM.closingSpeed

end


--------------------------------------------------
-- 08. DYNAMIC GEOMETRIC PROFILE
--------------------------------------------------

local function calculateAltitudeTarget(data)

    --------------------------------------------------
    -- PROFILE PARAMETERS
    --------------------------------------------------

    local destinationAltitude =

        data.destinationAltitude


    local altitudeDifference =

        SYSTEM.initialAltitude -
        destinationAltitude


    local arrivalRadius = math.max(

        0,

        data.arrivalRadius

    )


    local profileExponent = math.max(

        1,

        data.profileExponent

    )


    --------------------------------------------------
    -- DESCENT ONLY
    --------------------------------------------------

    if altitudeDifference <= 0 then

        return SYSTEM.initialAltitude, 0

    end


    --------------------------------------------------
    -- AVAILABLE PROFILE DISTANCE
    --------------------------------------------------

    local profileDistance = math.max(

        0,

        SYSTEM.initialDistance -
        arrivalRadius

    )


    --------------------------------------------------
    -- PROFILE ALREADY INSIDE ARRIVAL RADIUS
    --------------------------------------------------

    if profileDistance <= 0 then

        return destinationAltitude, 0

    end


    --------------------------------------------------
    -- NORMALIZED DISTANCE
    --------------------------------------------------

    local remainingDistance = clamp(

        data.distance - arrivalRadius,

        0,

        profileDistance

    )


    local progress =

        remainingDistance / profileDistance


    --------------------------------------------------
    -- GEOMETRIC ALTITUDE PROFILE
    --------------------------------------------------

    local profileValue =

        1 - ((1 - progress) ^ profileExponent)


    local altitudeTarget =

        destinationAltitude +

        altitudeDifference * profileValue


    return altitudeTarget, progress

end


--------------------------------------------------
-- 09. ADAPTIVE DESCENT SPEED
--------------------------------------------------

local function calculateDescentSpeed(

    data,

    progress

)

    --------------------------------------------------
    -- SPEED LIMIT
    --------------------------------------------------

    local maxDescentSpeed = math.abs(

        data.maxDescentSpeed

    )


    if maxDescentSpeed <= 0 then

        return 0

    end


    --------------------------------------------------
    -- PROFILE PARAMETERS
    --------------------------------------------------

    local altitudeDifference = math.max(

        0,

        SYSTEM.initialAltitude -
        data.destinationAltitude

    )


    local profileDistance = math.max(

        0,

        SYSTEM.initialDistance -
        math.max(0, data.arrivalRadius)

    )


    local profileExponent = math.max(

        1,

        data.profileExponent

    )


    if altitudeDifference <= 0
        or profileDistance <= 0 then

        return 0

    end


    --------------------------------------------------
    -- EFFECTIVE HORIZONTAL CLOSING SPEED
    --------------------------------------------------

    local closingSpeed = SYSTEM.closingSpeed


    --------------------------------------------------
    -- PROFILE DERIVATIVE
    --------------------------------------------------

    local profileSlope =

        altitudeDifference *
        profileExponent /
        profileDistance


    if profileExponent > 1 then

        profileSlope =

            profileSlope *
            ((1 - progress) ^ (profileExponent - 1))

    end


    --------------------------------------------------
    -- REQUIRED VERTICAL SPEED
    --------------------------------------------------

    local requiredDescentSpeed =

        profileSlope *
        closingSpeed


    --------------------------------------------------
    -- MAXIMUM DESCENT LIMIT
    --------------------------------------------------

    requiredDescentSpeed = clamp(

        requiredDescentSpeed,

        0,

        maxDescentSpeed

    )


    return -requiredDescentSpeed

end


--------------------------------------------------
-- 10. ADAPTIVE DESCENT SYSTEM
--------------------------------------------------

local function updateDescent(data, enabled)

    --------------------------------------------------
    -- ENABLE EDGE
    --------------------------------------------------

    local risingEdge =

        enabled and not SYSTEM.previousEnable


    SYSTEM.previousEnable = enabled


    --------------------------------------------------
    -- DISABLED
    --------------------------------------------------

    if not enabled then

        resetSystem(data)

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- INITIALIZATION
    --------------------------------------------------

    if risingEdge then

        resetSystem(data)

        SYSTEM.descentStarted = true

    end


    if not SYSTEM.descentStarted then

        return data.altitude, 0

    end


    --------------------------------------------------
    -- UPDATE CLOSING SPEED
    --------------------------------------------------

    updateClosingSpeed(

        data.distance,

        data.horizontalSpeed,

        data.closingSpeedFilter

    )


    --------------------------------------------------
    -- CURRENT ALTITUDE RELATION
    --------------------------------------------------

    local altitudeDifference =

        data.altitude -
        data.destinationAltitude


    --------------------------------------------------
    -- CALCULATE GEOMETRIC TARGET
    --------------------------------------------------

    local altitudeTarget, progress =

        calculateAltitudeTarget(data)


    --------------------------------------------------
    -- ARRIVAL RADIUS
    --------------------------------------------------

    if data.distance <= data.arrivalRadius then

        altitudeTarget = data.destinationAltitude

        if altitudeDifference > 0 then

            SYSTEM.descentSpeedTarget =

                -math.abs(data.maxDescentSpeed)

        else

            SYSTEM.descentSpeedTarget = 0

        end

        SYSTEM.descentTarget = altitudeTarget

        return

            SYSTEM.descentTarget,

            SYSTEM.descentSpeedTarget

    end


    --------------------------------------------------
    -- CALCULATE REQUIRED DESCENT SPEED
    --------------------------------------------------

    local desiredDescentSpeed =

        calculateDescentSpeed(

            data,

            progress

        )


    --------------------------------------------------
    -- SPEED STABILIZATION
    --------------------------------------------------

    SYSTEM.descentSpeedTarget = lerp(

        SYSTEM.descentSpeedTarget,

        desiredDescentSpeed,

        clamp(data.descentSpeedFilter, 0, 1)

    )


    --------------------------------------------------
    -- UPDATE DIRECT ALTITUDE REFERENCE
    --------------------------------------------------

    SYSTEM.descentTarget = altitudeTarget


    --------------------------------------------------
    -- RETURN
    --------------------------------------------------

    return

        SYSTEM.descentTarget,

        SYSTEM.descentSpeedTarget

end


--------------------------------------------------
-- 11. MAIN TICK
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

        closingSpeedFilter =
            input.getNumber(INPUT.CLOSING_SPEED_FILTER),

        descentSpeedFilter =
            input.getNumber(INPUT.DESCENT_SPEED_FILTER)

    }


    local descentEnabled =

        input.getBool(INPUT.DESCENT_ENABLE)


    --------------------------------------------------
    -- UPDATE SYSTEM
    --------------------------------------------------

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


-- END OF MC08 v1.7.0
