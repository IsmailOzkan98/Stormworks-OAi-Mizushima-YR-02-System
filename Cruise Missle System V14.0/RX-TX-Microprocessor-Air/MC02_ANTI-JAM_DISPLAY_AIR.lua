
-- ============================================================
-- OAI MIZUSHIMA YR-02
-- MC02: UNIVERSAL LINK DIAGNOSTIC DISPLAY
-- VERSION: 2.0
-- SYSTEM VERSION: 14.0
-- STORMWORKS LUA
--
-- DISPLAY: 9x5 (288x160)
--
-- MC ARCHITECTURE STANDARD v1.0
-- ============================================================

-- ============================================================
-- 1. INPUT MAP
-- ============================================================

-- MC01 OUTPUTS

local IN_PROTOCOL       = 1
local IN_MY_ID          = 2
local IN_TX_COUNTER     = 3
local IN_VERSION        = 4

local IN_STATE          = 5
local IN_RX_AGE         = 6
local IN_TX_DIAGNOSTIC  = 7

local IN_FREQUENCY_TX   = 8
local IN_FREQUENCY_RX   = 9

-- CONFIGURATION MIRROR

local IN_CONFIG_PROTOCOL = 10
local IN_CONFIG_VERSION  = 11
local IN_CONFIG_MY_ID    = 12
local IN_CONFIG_REMOTE   = 13
local IN_TIMEOUT         = 14

-- FREQUENCY CONFIGURATION

local IN_BASE_FREQUENCY = 15
local IN_FREQUENCY_DISTANCE = 16

-- RECEIVED HEARTBEAT

local IN_RX_PROTOCOL = 17
local IN_RX_REMOTE_ID = 18
local IN_RX_COUNTER = 19
local IN_RX_VERSION = 20

-- BOOL INPUTS

local IN_CONNECTED = 1
local IN_SEARCHING = 2
local IN_LOST = 3
local IN_ROLE = 4

-- ============================================================
-- 2. SYSTEM VARIABLES
-- ============================================================

local protocol = 0
local version = 0

local myID = 0
local remoteID = 0

local state = 0
local rxAge = 0
local timeout = 180

local txCounter = 0
local rxCounter = 0

local frequencyTX = 0
local frequencyRX = 0

local baseFrequency = 0
local frequencyDistance = 0

local rxProtocol = 0
local rxRemoteID = 0
local rxVersion = 0

local connected = false
local searching = false
local lost = false

local role = "GROUND"

local headerValid = false
local decimalValid = false
local heartbeatValid = false

-- HEARTBEAT ANIMATION

local lastRxCounter = -1
local pulseTimer = 0
local tick = 0

-- ============================================================
-- 3. COLOR PALETTE
-- ============================================================

local C = {
    background = { 5, 10, 11 },
    panel      = { 11, 20, 20 },
    panel2     = { 15, 28, 27 },

    border     = { 35, 66, 59 },
    grid       = { 17, 32, 30 },

    green      = { 0, 230, 130 },
    greenDim   = { 0, 105, 70 },

    cyan       = { 40, 190, 210 },
    white      = { 220, 235, 225 },
    grey       = { 105, 130, 122 },

    amber      = { 255, 180, 40 },
    red        = { 255, 55, 45 },
    black      = { 0, 0, 0 }
}

-- ============================================================
-- 4. UTILITIES
-- ============================================================

local function setColor(c)
    screen.setColor(c[1], c[2], c[3])
end

local function txt(x, y, value, color)
    setColor(color)
    screen.drawText(x, y, tostring(value))
end

local function line(x1, y1, x2, y2, color)
    setColor(color)
    screen.drawLine(x1, y1, x2, y2)
end

local function rect(x, y, w, h, color)
    setColor(color)
    screen.drawRectF(x, y, w, h)
end

local function outline(x, y, w, h, color)
    setColor(color)
    screen.drawRect(x, y, w, h)
end

local function bar(x, y, w, h, ratio, color)

    ratio = math.max(0, math.min(1, ratio))

    rect(x, y, w, h, C.grid)

    if ratio > 0 then
        rect(x, y, math.max(1, w * ratio), h, color)
    end

end

local function formatCounter(value)
    return string.format("%.1f", value)
end

local function formatFrequency(value)
    return string.format("%.0f", value)
end

local function statusColor()

    if connected then
        return C.green
    elseif lost then
        return C.red
    end

    return C.amber

end

-- ============================================================
-- 5. DATA ACQUISITION
-- ============================================================

local function readData()

    -- MC01 DIAGNOSTICS

    state = input.getNumber(IN_STATE)
    rxAge = input.getNumber(IN_RX_AGE)

    txCounter = input.getNumber(IN_TX_COUNTER)

    frequencyTX = input.getNumber(IN_FREQUENCY_TX)
    frequencyRX = input.getNumber(IN_FREQUENCY_RX)

    -- CONFIGURATION MIRROR

    protocol = input.getNumber(IN_CONFIG_PROTOCOL)
    version = input.getNumber(IN_CONFIG_VERSION)

    myID = input.getNumber(IN_CONFIG_MY_ID)
    remoteID = input.getNumber(IN_CONFIG_REMOTE)

    timeout = input.getNumber(IN_TIMEOUT)

    -- FREQUENCY CONFIGURATION

    baseFrequency = input.getNumber(IN_BASE_FREQUENCY)

    frequencyDistance =
        input.getNumber(IN_FREQUENCY_DISTANCE)

    -- RECEIVED PACKET

    rxProtocol = input.getNumber(IN_RX_PROTOCOL)
    rxRemoteID = input.getNumber(IN_RX_REMOTE_ID)

    rxCounter = input.getNumber(IN_RX_COUNTER)
    rxVersion = input.getNumber(IN_RX_VERSION)

    -- CONNECTION FLAGS

    connected = input.getBool(IN_CONNECTED)
    searching = input.getBool(IN_SEARCHING)
    lost = input.getBool(IN_LOST)

    -- ROLE

    if input.getBool(IN_ROLE) then
        role = "AIR"
    else
        role = "GROUND"
    end

    -- HEADER VALIDATION

    headerValid =
        rxProtocol == protocol and
        rxRemoteID == remoteID and
        rxVersion == version and
        rxCounter > 0

    -- DECIMAL VALIDATION

    local converted =
        math.floor(rxCounter * 10 + 0.5)

    decimalValid =
        math.abs(rxCounter * 10 - converted) < 0.1

    -- HEARTBEAT VALIDATION

    heartbeatValid =
        connected and
        headerValid and
        decimalValid

end

-- ============================================================
-- 6. HEARTBEAT MONITOR
-- ============================================================

local function updateHeartbeat()

    tick = tick + 1

    if pulseTimer > 0 then
        pulseTimer = pulseTimer - 1
    end

    -- DETECT NEW RECEIVED HEARTBEAT

    if rxCounter ~= lastRxCounter then

        if headerValid and decimalValid and rxCounter > 0 then
            pulseTimer = 20
        end

        lastRxCounter = rxCounter

    end

end

-- ============================================================
-- 7. MAIN TICK
-- ============================================================

function onTick()

    readData()

    updateHeartbeat()

end

-- ============================================================
-- 8. DISPLAY COMPONENTS
-- ============================================================

-- ------------------------------------------------------------
-- HEADER
-- ------------------------------------------------------------

local function drawHeader()

    rect(0, 0, 288, 17, C.panel2)

    txt(5, 2, "OAI MIZUSHIMA", C.green)
    txt(88, 2, "YR-02", C.cyan)

    txt(242, 2, "MC02", C.white)

    line(3, 16, 285, 16, C.border)

end

-- ------------------------------------------------------------
-- CONNECTION STATUS
-- ------------------------------------------------------------

local function drawConnection()

    local color = statusColor()

    rect(4, 20, 280, 23, C.panel)
    outline(4, 20, 280, 23, C.border)

    -- STATUS INDICATOR

    if connected then

        rect(9, 26, 5, 11, C.green)

        txt(19, 24, "LINK ESTABLISHED", C.green)

    elseif lost then

        rect(9, 26, 5, 11, C.red)

        txt(19, 24, "LINK LOST", C.red)

    else

        rect(9, 26, 5, 11, C.amber)

        txt(19, 24, "SEARCHING", C.amber)

    end

    -- ROLE

    txt(213, 24, role, C.cyan)

    txt(19, 34,
        connected and "OPERATIONAL" or "STANDBY",
        C.grey)

    txt(246, 34, "SYS", color)

end

-- ------------------------------------------------------------
-- HEARTBEAT MONITOR
-- ------------------------------------------------------------

local function drawHeartbeat()

    rect(4, 47, 280, 43, C.panel)
    outline(4, 47, 280, 43, C.border)

    txt(9, 50, "HEARTBEAT MONITOR", C.cyan)

    -- TX HEARTBEAT

    txt(10, 63, "TX", C.grey)

    txt(27, 62, formatCounter(txCounter), C.green)

    -- RX HEARTBEAT

    txt(104, 63, "RX", C.grey)

    txt(121, 62, formatCounter(rxCounter), C.white)

    -- HEARTBEAT PULSE

    local pulseColor = C.greenDim

    if pulseTimer > 0 then
        pulseColor = C.green
    elseif not heartbeatValid then
        pulseColor = C.red
    end

    rect(231, 59, 43, 16, C.grid)

    -- ANIMATED PULSE

    if pulseTimer > 0 then

        local radius = 2 + (pulseTimer % 5)

        setColor(pulseColor)
        screen.drawCircleF(244, 67, radius)

        rect(255, 65, 13, 3, C.green)

    else

        setColor(pulseColor)
        screen.drawCircleF(244, 67, 2)

    end

    -- SYNC STATUS

    txt(10, 78, "SYNC", C.grey)

    if heartbeatValid then

        txt(43, 78, "LOCKED", C.green)

    else

        txt(43, 78, "NO SYNC", C.red)

    end

    txt(170, 78, "SEQUENCE", C.grey)

    if headerValid and decimalValid then
        txt(226, 78, "VALID", C.green)
    else
        txt(226, 78, "ERROR", C.red)
    end

end

-- ------------------------------------------------------------
-- LINK QUALITY
-- ------------------------------------------------------------

local function drawLinkQuality()

    rect(4, 94, 137, 36, C.panel)
    outline(4, 94, 137, 36, C.border)

    txt(9, 97, "LINK HEALTH", C.cyan)

    local ratio = 0

    if timeout > 0 then
        ratio = 1 - rxAge / timeout
    end

    ratio = math.max(0, math.min(1, ratio))

    local color = C.green

    if ratio < 0.5 then
        color = C.amber
    end

    if lost or ratio <= 0 then
        color = C.red
    end

    txt(9, 108, string.format("%d%%", math.floor(ratio * 100)), color)

    bar(49, 113, 84, 6, ratio, color)

    txt(9, 120, "RX AGE", C.grey)

    txt(51, 120, string.format("%.1f", rxAge / 60), C.white)

end

-- ------------------------------------------------------------
-- CONNECTION TIMER
-- ------------------------------------------------------------

local function drawTimer()

    rect(147, 94, 137, 36, C.panel)
    outline(147, 94, 137, 36, C.border)

    txt(152, 97, "TIMEOUT MONITOR", C.cyan)

    txt(152, 109, "LIMIT", C.grey)

    txt(190, 109, tostring(timeout), C.white)

    txt(152, 120, "AGE", C.grey)

    txt(190, 120, tostring(math.floor(rxAge)), C.white)

    local remaining = timeout - rxAge

    if remaining < 0 then
        remaining = 0
    end

    txt(237, 109, "LEFT", C.grey)

    txt(237, 120, tostring(math.floor(remaining)), C.amber)

end

-- ------------------------------------------------------------
-- FREQUENCY MONITOR
-- ------------------------------------------------------------

local function drawFrequency()

    rect(4, 134, 280, 22, C.panel)
    outline(4, 134, 280, 22, C.border)

    txt(9, 137, "RF", C.cyan)

    txt(30, 137, "TX", C.grey)

    txt(44, 137, formatFrequency(frequencyTX), C.green)

    txt(108, 137, "RX", C.grey)

    txt(122, 137, formatFrequency(frequencyRX), C.cyan)

    -- ROLE INDICATOR

    txt(208, 137, role, C.white)

    txt(9, 147, "BASE", C.grey)

    txt(39, 147, formatFrequency(baseFrequency), C.white)

    txt(108, 147, "STEP", C.grey)

    txt(138, 147, formatFrequency(frequencyDistance), C.white)

    txt(224, 147, "YR-02", C.green)

end

-- ============================================================
-- 9. MAIN DRAW
-- ============================================================

function onDraw()

    -- BACKGROUND

    rect(0, 0, 288, 160, C.background)

    -- SUBTLE GRID

    for x = 0, 288, 16 do
        line(x, 0, x, 160, C.grid)
    end

    -- DISPLAY FRAME

    outline(1, 1, 286, 158, C.border)

    -- DISPLAY COMPONENTS

    drawHeader()

    drawConnection()

    drawHeartbeat()

    drawLinkQuality()

    drawTimer()

    drawFrequency()

    -- BOTTOM STATUS LINE

    line(4, 159, 284, 159, C.greenDim)

end

-- ============================================================
-- END MC02
-- ============================================================
