
-- ============================================================
-- OAI MIZUSHIMA YR-02
-- MC02: UNIVERSAL LINK DIAGNOSTIC DISPLAY
-- VERSION: 1.0
-- STORMWORKS LUA
-- ============================================================

-- INPUT MAP
-- NUMBER 1-9  = MC01 OUTPUTS 1-9
-- NUMBER 10   = CONFIG PROTOCOL
-- NUMBER 11   = CONFIG VERSION
-- NUMBER 12   = MY ID
-- NUMBER 13   = REMOTE ID
-- NUMBER 14   = TIMEOUT
-- NUMBER 15   = BASE FREQUENCY
-- NUMBER 16   = FREQUENCY DISTANCE
-- NUMBER 17   = RX PROTOCOL
-- NUMBER 18   = RX REMOTE ID
-- NUMBER 19   = RX COUNTER
-- NUMBER 20   = RX VERSION
--
-- BOOL 1 = CONNECTED
-- BOOL 2 = SEARCHING
-- BOOL 3 = LINK LOST
--
-- PROPERTY:
-- MyText = AIR or GROUND

local state = 0
local rxAge = 0
local txCounter = 0

local protocol = 0
local version = 0
local myID = 0
local remoteID = 0
local timeout = 180

local frequencyTX = 0
local frequencyRX = 0

local rxProtocol = 0
local rxRemoteID = 0
local rxCounter = 0
local rxVersion = 0

local connected = false
local searching = false
local lost = false

local role = "UNKNOWN"
local roleValid = false

local headerValid = false
local decimalValid = false

local function readData()

    -- MC01 OUTPUTS

    state = input.getNumber(5)
    rxAge = input.getNumber(6)
    txCounter = input.getNumber(7)

    frequencyTX = input.getNumber(12)
    frequencyRX = input.getNumber(13)

    -- CONFIGURATION MIRROR

    protocol = input.getNumber(8)
    version = input.getNumber(9)
    myID = input.getNumber(10)
    remoteID = input.getNumber(11)

    -- FREQUENCY CONFIGURATION

    local baseFrequency = input.getNumber(15)
    local frequencyDistance = input.getNumber(16)

    -- RECEIVED PACKET

    rxProtocol = input.getNumber(17)
    rxRemoteID = input.getNumber(18)
    rxCounter = input.getNumber(19)
    rxVersion = input.getNumber(20)

    -- CONNECTION FLAGS

    connected = input.getBool(1)
    searching = input.getBool(2)
    lost = input.getBool(3)

    -- ROLE

    role = string.upper(property.getText("MyText") or "")

    roleValid = role == "AIR" or role == "GROUND"

    -- PACKET HEADER VALIDATION

    headerValid =
        rxProtocol == protocol and
        rxRemoteID == remoteID and
        rxVersion == version and
        rxCounter > 0

    -- DECIMAL VALIDATION

    local converted = math.floor(rxCounter * 10 + 0.5)

    decimalValid =
        math.abs(rxCounter * 10 - converted) < 0.1

end

function onTick()
    readData()
end

-- ============================================================
-- DISPLAY FUNCTIONS
-- ============================================================

local function text(x, y, value, r, g, b)

    screen.setColor(r, g, b)
    screen.drawText(x, y, tostring(value))

end

local function separator(y, w)

    screen.setColor(45, 75, 65)
    screen.drawLine(2, y, w-2, y)

end

local function statusColor()

    if connected then
        return 0, 255, 80
    elseif lost then
        return 255, 40, 30
    else
        return 255, 190, 0
    end

end

-- ============================================================
-- MAIN DISPLAY
-- ============================================================

function onDraw()

    local w = screen.getWidth()
    local h = screen.getHeight()

    -- BACKGROUND

    screen.setColor(5, 10, 9)
    screen.drawRectF(0, 0, w, h)

    -- HEADER

    text(3, 2, "OAI MIZUSHIMA YR-02", 0, 220, 150)
    text(w-48, 2, "MC02", 100, 170, 160)

    separator(10, w)

    -- SYSTEM STATUS

    local r, g, b = statusColor()

    if connected then
        text(3, 14, "LINK: CONNECTED", r, g, b)
    elseif lost then
        text(3, 14, "LINK: LOST", r, g, b)
    else
        text(3, 14, "LINK: SEARCHING", r, g, b)
    end

    -- ROLE

    if roleValid then
        text(3, 24, "ROLE: "..role, 180, 220, 190)
    else
        text(3, 24, "ROLE: INVALID", 255, 50, 30)
    end

    separator(33, w)

    -- CONFIGURATION

    text(3, 37, "SYSTEM CONFIG", 0, 220, 150)

    text(3, 47, "MY ID:", 170, 190, 180)
    text(40, 47, myID, 255, 255, 255)

    text(75, 47, "REMOTE:", 170, 190, 180)
    text(117, 47, remoteID, 255, 255, 255)

    text(3, 57, "PROTOCOL:", 170, 190, 180)
    text(58, 57, protocol, 255, 255, 255)

    text(3, 67, "VERSION:", 170, 190, 180)
    text(48, 67, version, 255, 255, 255)

    separator(77, w)

    -- CONNECTION DIAGNOSTICS

    text(3, 81, "LINK DIAGNOSTICS", 0, 220, 150)

    text(3, 91, "RX AGE:", 170, 190, 180)
    text(45, 91, rxAge, 255, 255, 255)

    text(85, 91, "TIMEOUT:", 170, 190, 180)
    text(130, 91, timeout, 255, 255, 255)

    -- RX AGE BAR

    local ratio = 0

    if timeout > 0 then
        ratio = math.max(0, math.min(1, 1-rxAge/timeout))
    end

    screen.setColor(40, 50, 45)
    screen.drawRectF(3, 103, w-6, 4)

    if connected then
        screen.setColor(0, 255, 80)
    else
        screen.setColor(255, 100, 20)
    end

    screen.drawRectF(3, 103, (w-6)*ratio, 4)

    separator(111, w)

    -- FREQUENCY

    text(3, 115, "FREQUENCY", 0, 220, 150)

    text(3, 125, "TX:", 170, 190, 180)
    text(22, 125, frequencyTX, 255, 255, 255)

    text(85, 125, "RX:", 170, 190, 180)
    text(105, 125, frequencyRX, 255, 255, 255)

    separator(135, w)

    -- PACKET VALIDATION

    text(3, 139, "PACKET CHECK", 0, 220, 150)

    if headerValid then
        text(3, 149, "HEADER: OK", 0, 255, 80)
    else
        text(3, 149, "HEADER: ERROR", 255, 50, 30)
    end

    if decimalValid then
        text(90, 149, "DECIMAL: OK", 0, 255, 80)
    else
        text(90, 149, "DECIMAL: ERROR", 255, 50, 30)
    end

end
