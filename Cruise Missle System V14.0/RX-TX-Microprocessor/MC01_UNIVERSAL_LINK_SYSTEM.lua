
-- ============================================================
-- OAI MIZUSHIMA YR-02
-- MC01: UNIVERSAL LINK SYSTEM
-- VERSION: 5.1.1
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
-- Universal communication controller for AIR and GROUND.
-- Manages heartbeat, connection monitoring and frequency
-- assignment according to the selected operational role.
--
-- MC ARCHITECTURE STANDARD v1.0
-- ============================================================


-- ============================================================
-- 1. HEADER & DOCUMENTATION
-- ============================================================

-- AVAILABLE ROLES:
-- AIR
-- GROUND
--
-- ROLE SELECTION:
-- BOOL 4 = ROLE SELECTOR
--
-- CONNECTION STATE:
-- 0 = SEARCHING
-- 1 = CONNECTED
-- 2 = LINK_LOST
--
-- HEARTBEAT:
-- Internal integer representation.
-- 10 = 1.0
--
-- FREQUENCY:
-- AIR:
-- TX = BASE + DISTANCE
-- RX = BASE
--
-- GROUND:
-- TX = BASE
-- RX = BASE + DISTANCE



-- ============================================================
-- 2. INPUT CONFIGURATION
-- ============================================================

-- REMOTE HEARTBEAT RECEPTION

local INPUT_RX_PROTOCOL = 1
local INPUT_RX_REMOTE_ID = 2
local INPUT_RX_COUNTER = 3
local INPUT_RX_VERSION = 4

-- SYSTEM CONFIGURATION

local INPUT_TIMEOUT = 5

-- FREQUENCY CONFIGURATION

local INPUT_FREQUENCY = 6
local INPUT_FREQUENCY_DISTANCE = 7

-- EXTERNAL SYSTEM CONFIGURATION

local INPUT_PROTOCOL = 8
local INPUT_VERSION = 9
local INPUT_MY_ID = 10
local INPUT_REMOTE_ID = 11
local INPUT_ROLE = 12

-- ADAPTIVE FREQUENCY HOPPING

local INPUT_AFH_ENABLE = 13


-- ============================================================
-- 3. OUTPUT CONFIGURATION
-- ============================================================

-- NUMBER OUTPUTS

local OUTPUT_PROTOCOL = 1
local OUTPUT_MY_ID = 2
local OUTPUT_COUNTER = 3
local OUTPUT_VERSION = 4

local OUTPUT_STATE = 5
local OUTPUT_RX_AGE = 6
local OUTPUT_TX_COUNTER = 7

local OUTPUT_FREQUENCY_TX = 8
local OUTPUT_FREQUENCY_RX = 9

-- BOOL OUTPUTS

local OUTPUT_CONNECTED = 1
local OUTPUT_SEARCHING = 2
local OUTPUT_LINK_LOST = 3

-- DIAGNOSTIC OUTPUTS

local OUTPUT_TIMEOUT = 10
local OUTPUT_RX_COUNTER = 11
local OUTPUT_AFH_ACTIVE = 6


-- ============================================================
-- 4. SYSTEM CONFIGURATION
-- ============================================================

-- HEARTBEAT CONFIGURATION

local COUNTER_MIN = 10
local COUNTER_MAX = 999

local COUNTER_SCALE = 10
local DECIMAL_TOLERANCE = 0.1

-- ROLE CONFIGURATION

local ROLE_AIR = "AIR"
local ROLE_GROUND = "GROUND"

-- AFH CONFIGURATION

local INPUT_AFH_MIN_FREQUENCY = 12
local INPUT_AFH_MAX_FREQUENCY = 13

-- SYSTEM CONFIGURATION

local config = {
    protocol = 0,
    version = 0,
    myID = 0,
    remoteID = 0,
    timeout = 180,

    frequency = 0,
    frequencyDistance = 100,

    afhMinFrequency = 0,
    afhMaxFrequency = 0
}


-- ============================================================
-- 5. SYSTEM STATE
-- ============================================================

local STATE_SEARCHING = 0
local STATE_CONNECTED = 1
local STATE_LINK_LOST = 2

local state = STATE_SEARCHING

-- ROLE STATE

local activeRole = nil
local roleValid = false

-- TRANSMISSION STATE

local txCounter = 0
local expectedRx = 0

-- RECEPTION STATE

local rxAge = 0
local rxCounter = -1

-- FREQUENCY STATE

local frequencyTX = 0
local frequencyRX = 0

-- ADAPTIVE FREQUENCY HOPPING STATE

local afhEnabled = false
local afhActive = false

local afhSeed = 0
local afhHopIndex = 0

local afhFrequencyA = 0
local afhFrequencyB = 0


-- ============================================================
-- 6. GENERAL UTILITIES
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 COUNTER MANAGEMENT
-- ------------------------------------------------------------

local function nextCounter(value)

    if value >= COUNTER_MAX then
        return COUNTER_MIN
    end

    return value + 1

end


-- ------------------------------------------------------------
-- 6.2 DECIMAL CONVERSION
-- ------------------------------------------------------------

local function convertToIntegerTenths(value)

    return math.floor(value * COUNTER_SCALE + 0.5)

end


-- ------------------------------------------------------------
-- 6.3 DECIMAL VALIDATION
-- ------------------------------------------------------------

local function isValidDecimal(value, converted)

    return math.abs(value * COUNTER_SCALE - converted)
        < DECIMAL_TOLERANCE

end


-- ------------------------------------------------------------
-- 6.4 AFH SEED GENERATION
-- ------------------------------------------------------------

local function generateAFHSeed()

    return math.floor(
        (config.protocol / 2) +
        config.version +
        config.frequencyDistance
    )

end


-- ------------------------------------------------------------
-- 6.5 AFH FREQUENCY GENERATOR
-- ------------------------------------------------------------

local function generateAFHNumbers(hopIndex)

    local MODULO = 4294967296
    local MULTIPLIER = 1664525
    local INCREMENT = 1013904223

    -- VALIDATE FREQUENCY RANGE

    local minimum = config.afhMinFrequency
    local maximum = config.afhMaxFrequency

    if minimum < 0 or maximum < minimum then
        return nil, nil
    end

    -- EACH RANDOM NUMBER USES HALF THE FREQUENCY RANGE

    local partMin = math.ceil(minimum / 2)
    local partMax = math.floor(maximum / 2)

    local partRange = partMax - partMin + 1

    if partRange <= 0 then
        return nil, nil
    end

    -- INITIALIZE GENERATOR

    local randomState = afhSeed % MODULO

    local values = {}

    local firstPosition = (hopIndex - 1) * 4
    local lastPosition = hopIndex * 4

    -- GENERATE DETERMINISTIC SEQUENCE

    for position = 1, lastPosition do

        randomState = (
            MULTIPLIER * randomState + INCREMENT
        ) % MODULO

        if position > firstPosition then

            local randomValue =
                partMin + (randomState % partRange)

            values[#values + 1] = randomValue

        end

    end

    -- GENERATE TWO FREQUENCIES

    local frequencyA = values[1] + values[2]
    local frequencyB = values[3] + values[4]

    return frequencyA, frequencyB

end


-- ============================================================
-- 7. SYSTEM FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 READ EXTERNAL CONFIGURATION
-- ------------------------------------------------------------

local function readConfiguration()

    config.protocol = 
      input.getNumber(INPUT_PROTOCOL)

    config.version = 
       input.getNumber(INPUT_VERSION)

    config.myID = 
        input.getNumber(INPUT_MY_ID)

    config.remoteID = 
        input.getNumber(INPUT_REMOTE_ID)

    config.timeout = 
        input.getNumber(INPUT_TIMEOUT)

    config.frequency = input.getNumber(INPUT_FREQUENCY)

    config.frequencyDistance =
        input.getNumber(INPUT_FREQUENCY_DISTANCE)

    config.afhMinFrequency = 
    input.getNumber(INPUT_AFH_MIN_FREQUENCY)

    config.afhMaxFrequency = 
        input.getNumber(INPUT_AFH_MAX_FREQUENCY)

        -- AFH ENABLE SWITCH

    afhEnabled = 
        input.getBool(INPUT_AFH_ENABLE)


end


-- ------------------------------------------------------------
-- 7.2 ROLE INITIALIZATION
-- ------------------------------------------------------------

local function initializeRole(newRole)

    activeRole = newRole

    -- RESET CONNECTION STATE

    state = STATE_SEARCHING

    rxAge = 0
    rxCounter = -1

    -- RESET AFH STATE

    afhActive = false
    afhHopIndex = 0

    -- INITIALIZE HEARTBEAT SEQUENCE

    if newRole == ROLE_AIR then

        txCounter = COUNTER_MIN
        expectedRx = 11

        roleValid = true

    elseif newRole == ROLE_GROUND then

        txCounter = 0
        expectedRx = COUNTER_MIN

        roleValid = true

    else

        txCounter = 0
        expectedRx = 0

        roleValid = false

    end

end


-- ------------------------------------------------------------
-- 7.3 ROLE MANAGEMENT
-- ------------------------------------------------------------

local function updateRole()

    local roleSwitch = input.getBool(INPUT_ROLE)

    local newRole

    if roleSwitch then

        newRole = ROLE_AIR

    else

        newRole = ROLE_GROUND

    end

    -- DETECT ROLE CHANGE

    if newRole ~= activeRole then
        initializeRole(newRole)
    end

end


-- ------------------------------------------------------------
-- 7.4 FREQUENCY MANAGEMENT
-- ------------------------------------------------------------

local function updateFrequencies()

    if not roleValid then

        frequencyTX = 0
        frequencyRX = 0

        return

    end

    -- AFH DISABLED

    if not afhEnabled then

        afhActive = false
        afhHopIndex = 0

        if activeRole == ROLE_AIR then

            frequencyTX =
                config.frequency + config.frequencyDistance

            frequencyRX =
                config.frequency

        else

            frequencyTX =
                config.frequency

            frequencyRX =
                config.frequency + config.frequencyDistance

        end

        return

    end

    -- AFH HAS NOT BEEN ACTIVATED YET

    if not afhActive then

        if activeRole == ROLE_AIR then

            frequencyTX =
                config.frequency + config.frequencyDistance

            frequencyRX =
                config.frequency

        else

            frequencyTX =
                config.frequency

            frequencyRX =
                config.frequency + config.frequencyDistance

        end

    end

    -- WAIT FOR CONNECTION LOSS

    if state ~= STATE_LINK_LOST then
        return
    end

    if config.timeout <= 0 then
        return
    end

    -- CALCULATE HOP INDEX

    local currentHop =
        math.floor(rxAge / config.timeout)

    if currentHop <= 0 then
        return
    end

    -- GENERATE NEXT FREQUENCY PAIR

    if currentHop ~= afhHopIndex then

        afhSeed = generateAFHSeed()

        local frequencyA, frequencyB =
            generateAFHNumbers(currentHop)

        if frequencyA == nil or frequencyB == nil then
            return
        end

        afhFrequencyA = frequencyA
        afhFrequencyB = frequencyB

        afhHopIndex = currentHop
        afhActive = true

    end

    -- ASSIGN PERSISTENT AFH FREQUENCIES

    if activeRole == ROLE_AIR then

        frequencyTX = afhFrequencyA
        frequencyRX = afhFrequencyB

    else

        frequencyTX = afhFrequencyB
        frequencyRX = afhFrequencyA

    end

end


-- ------------------------------------------------------------
-- 7.5 RECEIVE HEARTBEAT
-- ------------------------------------------------------------

local function receiveHeartbeat()

    if not roleValid then
        return
    end

    local protocol =
        input.getNumber(INPUT_RX_PROTOCOL)

    local remoteID =
        input.getNumber(INPUT_RX_REMOTE_ID)

    local counter =
        input.getNumber(INPUT_RX_COUNTER)

    local version =
        input.getNumber(INPUT_RX_VERSION)

    -- VALIDATE PACKET HEADER

    local validHeader =
        protocol == config.protocol and
        remoteID == config.remoteID and
        version == config.version and
        counter > 0

    if not validHeader then
        return
    end

    -- CONVERT DECIMAL TO INTEGER TENTHS

    local received =
        convertToIntegerTenths(counter)

    local validDecimal =
        isValidDecimal(counter, received)

    if not validDecimal then
        return
    end

    -- VALIDATE EXPECTED COUNTER

    if received ~= expectedRx then
        return
    end

    -- ACCEPT HEARTBEAT

    rxCounter = received
    rxAge = 0

    -- UPDATE TRANSMISSION SEQUENCE

    txCounter = nextCounter(received)
    expectedRx = nextCounter(txCounter)

    state = STATE_CONNECTED

end


-- ------------------------------------------------------------
-- 7.6 CONNECTION MONITORING
-- ------------------------------------------------------------

local function monitorConnection()

    if not roleValid then
        return
    end

    if state == STATE_CONNECTED and rxAge >= config.timeout then

        state = STATE_LINK_LOST

    end

end


-- ------------------------------------------------------------
-- 7.7 HEARTBEAT TRANSMISSION
-- ------------------------------------------------------------

local function prepareHeartbeat()

    -- HEARTBEAT VALUES ARE PROCESSED
    -- IN OUTPUT PROCESSING.

end


-- ============================================================
-- 8. MAIN TICK
-- ============================================================

local processOutputs

function onTick()

    -- READ EXTERNAL CONFIGURATION

    readConfiguration()

    -- DETECT AND UPDATE ROLE

    updateRole()

    -- UPDATE FREQUENCIES

    updateFrequencies()

    -- UPDATE RECEPTION AGE

    rxAge = rxAge + 1

    -- RECEIVE REMOTE HEARTBEAT

    receiveHeartbeat()

    -- MONITOR CONNECTION

    monitorConnection()

    -- UPDATE FREQUENCIES

    updateFrequencies()  

    -- PREPARE HEARTBEAT

    prepareHeartbeat()

    -- PROCESS OUTPUTS

    processOutputs()

end


-- ============================================================
-- 9. OUTPUT PROCESSING
-- ============================================================

processOutputs = function()

    -- --------------------------------------------------------
    -- 9.1 HEARTBEAT TRANSMISSION
    -- --------------------------------------------------------

    output.setNumber(
        OUTPUT_PROTOCOL,
        config.protocol
    )

    output.setNumber(
        OUTPUT_MY_ID,
        config.myID
    )

    output.setNumber(
        OUTPUT_COUNTER,
        txCounter / COUNTER_SCALE
    )

    output.setNumber(
        OUTPUT_VERSION,
        config.version
    )


    -- --------------------------------------------------------
    -- 9.2 CONNECTION DIAGNOSTICS
    -- --------------------------------------------------------

    output.setBool(
        OUTPUT_CONNECTED,
        state == STATE_CONNECTED
    )

    output.setBool(
        OUTPUT_SEARCHING,
        state == STATE_SEARCHING
    )

    output.setBool(
        OUTPUT_LINK_LOST,
        state == STATE_LINK_LOST
    )

    output.setBool(
        OUTPUT_AFH_ACTIVE,
        afhActive
    )


    -- --------------------------------------------------------
    -- 9.3 NUMERICAL DIAGNOSTICS
    -- --------------------------------------------------------

    output.setNumber(
        OUTPUT_STATE,
        state
    )

    output.setNumber(
        OUTPUT_RX_AGE,
        rxAge
    )

    output.setNumber(
        OUTPUT_TX_COUNTER,
        txCounter / COUNTER_SCALE
    )

    output.setNumber(
        OUTPUT_TIMEOUT,
        config.timeout
    )

    output.setNumber(
        OUTPUT_RX_COUNTER,
        rxCounter / COUNTER_SCALE
    )


    -- --------------------------------------------------------
    -- 9.4 FREQUENCY OUTPUTS
    -- --------------------------------------------------------

    output.setNumber(
        OUTPUT_FREQUENCY_TX,
        frequencyTX
    )

    output.setNumber(
        OUTPUT_FREQUENCY_RX,
        frequencyRX
    )

end


-- ============================================================
-- 10. END OF MC
-- ============================================================