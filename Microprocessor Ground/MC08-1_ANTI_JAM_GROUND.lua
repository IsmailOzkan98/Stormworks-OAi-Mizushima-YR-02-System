
-- GROUND LINK SYSTEM
-- GROUND ID = 2
-- AIR ID = 1

local PROTOCOL = 7319
local VERSION = 1

local MY_ID = 2
local REMOTE_ID = 1

local TIMEOUT = 180

local state = 0
-- 0 SEARCHING
-- 1 CONNECTED
-- 2 LINK_LOST

-- HEARTBEAT
-- Internal integer: 10 = 1.0
local txCounter = 0
local expectedRx = 10

local rxAge = 0
local rxCounter = -1

local function nextCounter(value)
    if value >= 999 then
        return 10
    end

    return value + 1
end

function onTick()

    -- RECEIVE AIR HEARTBEAT
    rxAge = rxAge + 1

    local protocol = input.getNumber(1)
    local remoteID = input.getNumber(2)
    local counter = input.getNumber(3)
    local version = input.getNumber(4)

    -- VALIDATE PACKET
    local validHeader =
        protocol == PROTOCOL and
        remoteID == REMOTE_ID and
        version == VERSION and
        counter > 0

    if validHeader then

        -- Convert decimal to integer tenths
        local received = math.floor(counter * 10 + 0.5)

        local validDecimal =
            math.abs(counter * 10 - received) < 0.1

        -- Only accept the exact expected number
        if validDecimal and received == expectedRx then

            rxCounter = received
            rxAge = 0

            -- Respond with next number
            txCounter = nextCounter(received)
            expectedRx = nextCounter(txCounter)

            state = 1
        end
    end

    -- CONNECTION TIMEOUT
    if state == 1 and rxAge >= TIMEOUT then
        state = 2
    end

    -- TRANSMIT HEARTBEAT
    output.setNumber(1, PROTOCOL)
    output.setNumber(2, MY_ID)
    output.setNumber(3, txCounter / 10)
    output.setNumber(4, VERSION)

    -- OUTPUT DIAGNOSTICS
    output.setBool(1, state == 1)
    output.setBool(2, state == 0)
    output.setBool(3, state == 2)

    output.setNumber(5, state)
    output.setNumber(6, rxAge)
    output.setNumber(7, txCounter / 10)

end
