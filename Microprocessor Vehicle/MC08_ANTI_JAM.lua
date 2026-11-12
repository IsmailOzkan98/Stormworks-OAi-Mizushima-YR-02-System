
-- OAI MIZUSHIMA YR-02
-- MC 08: ANTI-JAM VEHICLE
-- VERSION: 2.1.0
-- SYSTEM VERSION: 14.0
-- REWORKED FROM v2.0.0
--
-- RESPONSIBILITY:
--   Vehicle communication management
--   Triple receiver supervision
--   Independent channel validation
--   Heartbeat monitoring
--   Emergency link recovery
--   Ground status transmission


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    FREQUENCY_MIN = 1,
    FREQUENCY_MAX = 2,

    ENABLE = 1,

    RX_NUMBER_FIRST = {3, 11, 19},
    RX_BOOL_FIRST = {2, 4, 6}

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    STATUS_FIRST = 1,
    FREQUENCY_FIRST = 10

}


--------------------------------------------------
-- 03. SYSTEM STATE
--------------------------------------------------

local SYSTEM = {

    enabled = false,
    remoteEnabled = false,

    link = false,
    emergency = false,
    controlValid = false,

    statusHeartbeat = false,
    statusSequence = 0,

    lastControlSequence = -1,

    noLinkTimer = 0,

    frequencies = {0, 0, 0, 0},

    rxSequence = {-1, -1, -1},
    rxTimers = {60, 60, 60},
    rxState = {false, false, false},

    activeReceivers = 0,

    frequencyMin = 100,
    frequencyMax = 100000,

    tick = 0

}


--------------------------------------------------
-- 04. GENERAL UTILITIES
--------------------------------------------------

local MAGIC = 27183
local VERSION = 1

local SEND_RATE = 30
local LINK_TIMEOUT = 60

local SEQUENCE_MODULO = 1000000
local SEQUENCE_HALF = 500000


local function checksum(data, count)

    local sum = 0

    for i = 1, count do
        sum = sum + math.floor(data[i])
    end

    return sum % 65536

end


local function validSequence(sequence)

    return sequence >= 0
        and sequence < SEQUENCE_MODULO
        and sequence == math.floor(sequence)

end


local function isNewSequence(sequence, previous)

    if previous < 0 then
        return true
    end

    local difference =
        (sequence - previous) % SEQUENCE_MODULO

    return difference > 0
        and difference < SEQUENCE_HALF

end


--------------------------------------------------
-- 05. FREQUENCY MANAGEMENT
--------------------------------------------------

local function updateFrequencyPlan()

    local minimum = SYSTEM.frequencyMin
    local maximum = SYSTEM.frequencyMax

    if minimum < 100
        or minimum > 100000
        or maximum < 100
        or maximum > 100000
        or maximum - minimum < 4
        or minimum ~= math.floor(minimum)
        or maximum ~= math.floor(maximum) then

        for i = 1, 4 do
            SYSTEM.frequencies[i] = 0
        end

        return false

    end

    local span = maximum - minimum

    for i = 1, 4 do

        SYSTEM.frequencies[i] =
            minimum + math.floor(span * (i - 1) / 4)

    end

    return true

end


--------------------------------------------------
-- 06. COMMUNICATION PROTOCOL
--------------------------------------------------

local function readControl(receiver)

    local numberFirst =
        INPUT.RX_NUMBER_FIRST[receiver]

    local boolFirst =
        INPUT.RX_BOOL_FIRST[receiver]

    local packet = {}

    for i = 1, 8 do
        packet[i] = input.getNumber(numberFirst + i - 1)
    end

    local heartbeat = input.getBool(boolFirst)
    local remoteEnable = input.getBool(boolFirst + 1)


    -- PACKET IDENTIFICATION

    if packet[1] ~= MAGIC
        or packet[2] ~= VERSION then

        return false

    end


    -- PACKET INTEGRITY

    if packet[8] ~= checksum(packet, 7) then
        return false
    end


    -- SEQUENCE VALIDATION

    local sequence = packet[3]

    if not validSequence(sequence) then
        return false
    end

    if not isNewSequence(
        sequence,
        SYSTEM.rxSequence[receiver]
    ) then

        return false

    end


    -- GLOBAL SEQUENCE VALIDATION

    if SYSTEM.lastControlSequence >= 0 then

        local sameSequence =
            sequence == SYSTEM.lastControlSequence

        local newerSequence =
            isNewSequence(
                sequence,
                SYSTEM.lastControlSequence
            )

        if not sameSequence and not newerSequence then
            return false
        end

    end


    -- HEARTBEAT VALIDATION

    if heartbeat ~= (sequence % 2 == 1) then
        return false
    end


    -- FREQUENCY VALIDATION

    for i = 4, 7 do

        if packet[i] < SYSTEM.frequencyMin
            or packet[i] > SYSTEM.frequencyMax
            or packet[i] ~= math.floor(packet[i]) then

            return false

        end

    end


    -- UPDATE RECEIVER STATE

    SYSTEM.rxSequence[receiver] = sequence
    SYSTEM.rxTimers[receiver] = 0

    SYSTEM.remoteEnabled = remoteEnable


    -- UPDATE GLOBAL SEQUENCE

    if isNewSequence(
        sequence,
        SYSTEM.lastControlSequence
    ) then

        SYSTEM.lastControlSequence = sequence

    end


    -- UPDATE FREQUENCIES

    for i = 1, 4 do
        SYSTEM.frequencies[i] = packet[i + 3]
    end

    return true

end


--------------------------------------------------
-- 07. LINK MANAGEMENT
--------------------------------------------------

local function resetReceivers()

    SYSTEM.lastControlSequence = -1
    SYSTEM.remoteEnabled = false

    SYSTEM.activeReceivers = 0

    SYSTEM.link = false
    SYSTEM.emergency = false
    SYSTEM.controlValid = false

    SYSTEM.noLinkTimer = 0

    for i = 1, 3 do

        SYSTEM.rxSequence[i] = -1
        SYSTEM.rxTimers[i] = LINK_TIMEOUT
        SYSTEM.rxState[i] = false

    end

end


local function updateReceivers()

    SYSTEM.activeReceivers = 0


    -- UPDATE RECEIVER TIMERS

    for i = 1, 3 do

        SYSTEM.rxTimers[i] =
            math.min(
                SYSTEM.rxTimers[i] + 1,
                LINK_TIMEOUT
            )

    end


    -- PROCESS THREE RECEIVERS

    for i = 1, 3 do
        readControl(i)
    end


    -- RECEIVER AVAILABILITY

    for i = 1, 3 do

        SYSTEM.rxState[i] =
            SYSTEM.rxTimers[i] < LINK_TIMEOUT

        if SYSTEM.rxState[i] then

            SYSTEM.activeReceivers =
                SYSTEM.activeReceivers + 1

        end

    end


    -- LINK STATUS

    SYSTEM.controlValid =
        SYSTEM.activeReceivers > 0
        and SYSTEM.remoteEnabled

    SYSTEM.link =
        SYSTEM.controlValid


    -- GLOBAL LINK TIMER

    if SYSTEM.link then

        SYSTEM.noLinkTimer = 0

    else

        SYSTEM.noLinkTimer =
            math.min(
                SYSTEM.noLinkTimer + 1,
                LINK_TIMEOUT
            )

    end


    -- EMERGENCY STATUS

    SYSTEM.emergency =
        SYSTEM.remoteEnabled
        and SYSTEM.noLinkTimer >= LINK_TIMEOUT

end


--------------------------------------------------
-- 08. STATUS TRANSMISSION
--------------------------------------------------

local function writeStatus()

    local packet = {

        MAGIC,
        VERSION,

        SYSTEM.statusSequence,

        math.max(0, SYSTEM.lastControlSequence),

        SYSTEM.frequencies[1],
        SYSTEM.frequencies[2],
        SYSTEM.frequencies[3],
        SYSTEM.frequencies[4]

    }


    -- NUMBER CHANNELS

    for i = 1, 8 do
        output.setNumber(OUTPUT.STATUS_FIRST + i - 1, packet[i])
    end

    output.setNumber(
        OUTPUT.STATUS_FIRST + 8,
        checksum(packet, 8)
    )


    -- BOOLEAN CHANNELS

    output.setBool(1, SYSTEM.statusHeartbeat)
    output.setBool(2, SYSTEM.link)
    output.setBool(3, SYSTEM.emergency)
    output.setBool(4, SYSTEM.controlValid)

end


--------------------------------------------------
-- 09. OUTPUT MANAGEMENT
--------------------------------------------------

local function writeFrequencies()

    for i = 1, 4 do

        output.setNumber(
            OUTPUT.FREQUENCY_FIRST + i - 1,
            SYSTEM.frequencies[i]
        )

    end

end


--------------------------------------------------
-- 10. MAIN TICK
--------------------------------------------------

function onTick()

    SYSTEM.tick = SYSTEM.tick + 1


    -- READ INPUTS

    SYSTEM.frequencyMin =
        input.getNumber(INPUT.FREQUENCY_MIN)

    SYSTEM.frequencyMax =
        input.getNumber(INPUT.FREQUENCY_MAX)

    SYSTEM.enabled =
        input.getBool(INPUT.ENABLE)


    -- FREQUENCY VALIDATION

    local rangeValid = updateFrequencyPlan()


    -- SYSTEM DISABLED / INVALID RANGE

    if not SYSTEM.enabled or not rangeValid then

        resetReceivers()

    else

        -- RECEIVER PROCESSING

        updateReceivers()

    end


    -- STATUS SEQUENCE

    if SYSTEM.tick % SEND_RATE == 0 then

        SYSTEM.statusSequence =
            (SYSTEM.statusSequence + 1) % SEQUENCE_MODULO

        SYSTEM.statusHeartbeat =
            SYSTEM.statusSequence % 2 == 1

    end


    -- FREQUENCY OUTPUTS

    writeFrequencies()


    -- STATUS TRANSMISSION

    writeStatus()

end


-- END OF MC 08
