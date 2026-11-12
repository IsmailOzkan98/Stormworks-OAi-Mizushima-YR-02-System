-- ============================================================
-- OAI MIZUSHIMA YR-02
-- MC08: AIR LINK SYSTEM
-- VERSION: 4.0.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
-- Establish and monitor the communication link between
-- AIR and GROUND controllers through a heartbeat protocol.
--
-- MC ARCHITECTURE STANDARD v1.0
-- ============================================================


-- ============================================================
-- 1. HEADER & DOCUMENTATION
-- ============================================================

-- AIR ID = 1
-- GROUND ID = 2
--
-- STATE:
-- 0 = SEARCHING
-- 1 = CONNECTED
-- 2 = LINK_LOST
--
-- HEARTBEAT:
-- Internal integer representation.
-- 10 = 1.0


-- ============================================================
-- 2. INPUT CONFIGURATION
-- ============================================================

local INPUT_PROTOCOL = 1
local INPUT_REMOTE_ID = 2
local INPUT_COUNTER = 3
local INPUT_VERSION = 4


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

-- BOOL OUTPUTS

local OUTPUT_CONNECTED = 1
local OUTPUT_SEARCHING = 2
local OUTPUT_LINK_LOST = 3


-- ============================================================
-- 4. SYSTEM CONFIGURATION
-- ============================================================

local PROTOCOL = 7319
local VERSION = 1

local MY_ID = 1
local REMOTE_ID = 2

local TIMEOUT = 180

local COUNTER_MIN = 10
local COUNTER_MAX = 999

local COUNTER_SCALE = 10
local DECIMAL_TOLERANCE = 0.1


-- ============================================================
-- 5. SYSTEM STATE
-- ============================================================

local STATE_SEARCHING = 0
local STATE_CONNECTED = 1
local STATE_LINK_LOST = 2

local state = STATE_SEARCHING

-- TRANSMISSION STATE

local txCounter = COUNTER_MIN
local expectedRx = 11

-- RECEPTION STATE

local rxAge = 0
local rxCounter = -1


-- ============================================================
-- 6. GENERAL UTILITIES
-- ============================================================

local function nextCounter(value)

    if value >= COUNTER_MAX then
        return COUNTER_MIN
    end

    return value + 1

end


local function convertToIntegerTenths(value)

    return math.floor(value * COUNTER_SCALE + 0.5)

end


local function isValidDecimal(value, converted)

    return math.abs(value * COUNTER_SCALE - converted)
        < DECIMAL_TOLERANCE

end


-- ============================================================
-- 7. SYSTEM FUNCTIONS
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 RECEIVE HEARTBEAT
-- ------------------------------------------------------------

local function receiveHeartbeat()

    local protocol = input.getNumber(INPUT_PROTOCOL)
    local remoteID = input.getNumber(INPUT_REMOTE_ID)
    local counter = input.getNumber(INPUT_COUNTER)
    local version = input.getNumber(INPUT_VERSION)

    local validHeader =
        protocol == PROTOCOL and
        remoteID == REMOTE_ID and
        version == VERSION and
        counter > 0

    if not validHeader then
        return
    end

    local received = convertToIntegerTenths(counter)

    local validDecimal =
        isValidDecimal(counter, received)

    if not validDecimal then
        return
    end

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
-- 7.2 CONNECTION MONITORING
-- ------------------------------------------------------------

local function monitorConnection()

    if state == STATE_CONNECTED and rxAge >= TIMEOUT then
        state = STATE_LINK_LOST
    end

end


-- ------------------------------------------------------------
-- 7.3 HEARTBEAT TRANSMISSION
-- ------------------------------------------------------------

local function prepareHeartbeat()

    -- Transmission values are processed
    -- in OUTPUT PROCESSING.

end


-- ============================================================
-- 8. MAIN TICK
-- ============================================================

function onTick()

    -- UPDATE RECEPTION AGE

    rxAge = rxAge + 1

    -- RECEIVE GROUND HEARTBEAT

    receiveHeartbeat()

    -- MONITOR CONNECTION

    monitorConnection()

    -- PREPARE TRANSMISSION

    prepareHeartbeat()

    -- PROCESS OUTPUTS

    processOutputs()

end


-- ============================================================
-- 9. OUTPUT PROCESSING
-- ============================================================

function processOutputs()

    -- HEARTBEAT TRANSMISSION

    output.setNumber(OUTPUT_PROTOCOL, PROTOCOL)
    output.setNumber(OUTPUT_MY_ID, MY_ID)
    output.setNumber(OUTPUT_COUNTER, txCounter / COUNTER_SCALE)
    output.setNumber(OUTPUT_VERSION, VERSION)

    -- CONNECTION DIAGNOSTICS

    output.setBool(OUTPUT_CONNECTED, state == STATE_CONNECTED)
    output.setBool(OUTPUT_SEARCHING, state == STATE_SEARCHING)
    output.setBool(OUTPUT_LINK_LOST, state == STATE_LINK_LOST)

    -- NUMERICAL DIAGNOSTICS

    output.setNumber(OUTPUT_STATE, state)
    output.setNumber(OUTPUT_RX_AGE, rxAge)
    output.setNumber(OUTPUT_TX_COUNTER, txCounter / COUNTER_SCALE)

end


-- ============================================================
-- 10. END OF MC
-- ============================================================