
-- ============================================================
-- OAI MIZUSHIMA YR-02
-- MC02: UNIVERSAL LINK DIAGNOSTIC DISPLAY
-- VERSION: 3.0
-- SYSTEM VERSION: 14.0
-- STORMWORKS LUA
--
-- DISPLAY: 9x5 (288x160)
--
-- VISUAL STYLE:
-- MONOCHROME MILITARY TERMINAL
-- INSPIRED BY NIER:AUTOMATA
--
-- MC ARCHITECTURE STANDARD v1.0
-- ============================================================


-- ============================================================
-- 1. INPUT MAP
-- ============================================================

local IN_PROTOCOL       = 1
local IN_MY_ID          = 2
local IN_TX_COUNTER     = 3
local IN_VERSION        = 4

local IN_STATE          = 5
local IN_RX_AGE         = 6
local IN_TX_DIAGNOSTIC  = 7

local IN_FREQUENCY_TX   = 8
local IN_FREQUENCY_RX   = 9

local IN_CONFIG_PROTOCOL = 10
local IN_CONFIG_VERSION  = 11
local IN_CONFIG_MY_ID    = 12
local IN_CONFIG_REMOTE   = 13
local IN_TIMEOUT         = 14

local IN_BASE_FREQUENCY = 15
local IN_FREQUENCY_DISTANCE = 16

local IN_RX_PROTOCOL = 17
local IN_RX_REMOTE_ID = 18
local IN_RX_COUNTER = 19
local IN_RX_VERSION = 20

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

local lastRxCounter = -1
local pulseTimer = 0
local tick = 0

local scanPosition = 5
local warningBlink = false


-- ============================================================
-- 3. COLOR PALETTE
-- ============================================================

local C = {
    background = { 17, 17, 15 },
    panel      = { 29, 28, 24 },
    panel2     = { 42, 40, 34 },

    border     = { 104, 97, 77 },
    grid       = { 39, 37, 31 },

    green      = { 164, 177, 128 },
    greenDim   = { 91, 105, 69 },

    cyan       = { 190, 181, 151 },
    white      = { 225, 217, 193 },
    grey       = { 142, 134, 113 },

    amber      = { 207, 165, 91 },
    red        = { 183, 81, 69 },

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
        rect(x, y, math.max(1, math.floor(w * ratio)), h, color)
    end

end

-- FORMATTING WITHOUT STRING.FORMAT

local function formatCounter(value)

    local n = math.floor(value * 10 + 0.5) / 10

    return tostring(n)

end

local function formatFrequency(value)

    return tostring(math.floor(value + 0.5))

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
-- 5. GRAPHIC UTILITIES
-- ============================================================

local function cornerFrame(x, y, w, h, color)

    local s = 5

    line(x, y, x+s, y, color)
    line(x, y, x, y+s, color)

    line(x+w-s, y, x+w, y, color)
    line(x+w, y, x+w, y+s, color)

    line(x, y+h-s, x, y+h, color)
    line(x, y+h, x+s, y+h, color)

    line(x+w-s, y+h, x+w, y+h, color)
    line(x+w, y+h-s, x+w, y+h, color)

end

local function panel(x, y, w, h)

    rect(x, y, w, h, C.panel)
    outline(x, y, w, h, C.border)

    cornerFrame(x, y, w, h, C.cyan)

end

local function sectionTitle(x, y, number, title)

    txt(x, y, number, C.amber)
    txt(x+17, y, title, C.white)

end


-- ============================================================
-- 6. DATA ACQUISITION
-- ============================================================

local function readData()

    state = input.getNumber(IN_STATE)
    rxAge = input.getNumber(IN_RX_AGE)

    txCounter = input.getNumber(IN_TX_COUNTER)

    frequencyTX = input.getNumber(IN_FREQUENCY_TX)
    frequencyRX = input.getNumber(IN_FREQUENCY_RX)

    protocol = input.getNumber(IN_CONFIG_PROTOCOL)
    version = input.getNumber(IN_CONFIG_VERSION)

    myID = input.getNumber(IN_CONFIG_MY_ID)
    remoteID = input.getNumber(IN_CONFIG_REMOTE)

    timeout = input.getNumber(IN_TIMEOUT)

    baseFrequency = input.getNumber(IN_BASE_FREQUENCY)

    frequencyDistance =
        input.getNumber(IN_FREQUENCY_DISTANCE)

    rxProtocol = input.getNumber(IN_RX_PROTOCOL)
    rxRemoteID = input.getNumber(IN_RX_REMOTE_ID)

    rxCounter = input.getNumber(IN_RX_COUNTER)
    rxVersion = input.getNumber(IN_RX_VERSION)

    connected = input.getBool(IN_CONNECTED)
    searching = input.getBool(IN_SEARCHING)
    lost = input.getBool(IN_LOST)

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
-- 7. ANIMATION SYSTEM
-- ============================================================

local function updateHeartbeat()

    tick = tick + 1

    if pulseTimer > 0 then
        pulseTimer = pulseTimer - 1
    end

    -- NEW RECEIVED HEARTBEAT

    if rxCounter ~= lastRxCounter then

        if headerValid and decimalValid and rxCounter > 0 then
            pulseTimer = 20
        end

        lastRxCounter = rxCounter

    end

    -- SCAN ANIMATION

    scanPosition = scanPosition + 1

    if scanPosition > 283 then
        scanPosition = 5
    end

    -- WARNING ANIMATION

    warningBlink = math.floor(tick / 15) % 2 == 0

end


-- ============================================================
-- 8. MAIN TICK
-- ============================================================

function onTick()

    readData()
    updateHeartbeat()

end


-- ============================================================
-- 9. BACKGROUND
-- ============================================================

local function drawBackground()

    rect(0, 0, 288, 160, C.background)

    -- VERTICAL GRID

    for x = 0, 288, 24 do
        line(x, 0, x, 160, C.grid)
    end

    -- HORIZONTAL GRID

    for y = 20, 156, 16 do
        line(0, y, 288, y, C.grid)
    end

    -- OUTER FRAME

    outline(1, 1, 286, 158, C.border)

    -- SCAN LINE

    line(scanPosition, 19, scanPosition, 157, C.grid)

end


-- ============================================================
-- 10. HEADER
-- ============================================================

local function drawHeader()

    rect(3, 2, 282, 14, C.panel2)

    txt(7, 5, "OAI MIZUSHIMA", C.white)

    txt(88, 5, "YR-02", C.amber)

    txt(242, 5, "MC02", C.cyan)

    line(3, 17, 285, 17, C.border)

    -- SMALL DECORATIVE MARKERS

    rect(226, 6, 3, 3, C.grey)
    rect(231, 6, 3, 3, C.grey)

end


-- ============================================================
-- 11. CONNECTION STATUS
-- ============================================================

local function drawConnection()

    panel(5, 21, 278, 22)

    local color = statusColor()

    rect(10, 27, 5, 10, color)

    if connected then

        txt(21, 25, "LINK ESTABLISHED", C.green)

    elseif lost then

        txt(21, 25, "LINK LOST", C.red)

    else

        txt(21, 25, "SEARCHING", C.amber)

    end

    txt(213, 25, role, C.cyan)

    line(10, 39, 278, 39, C.grid)

    txt(11, 34, "UNIT STATUS", C.grey)

    txt(79, 34,
        connected and "OPERATIONAL" or "STANDBY",
        connected and C.green or C.amber)

    txt(246, 34, "SYS", color)

end


-- ============================================================
-- 12. HEARTBEAT MONITOR
-- ============================================================

local function drawHeartbeat()

    panel(5, 47, 278, 43)

    sectionTitle(10, 50, "01", "HEARTBEAT MONITOR")

    -- TRANSMISSION

    txt(11, 64, "TX", C.grey)
    txt(29, 63, formatCounter(txCounter), C.white)

    -- RECEPTION

    txt(105, 64, "RX", C.grey)
    txt(123, 63, formatCounter(rxCounter), C.white)

    -- PULSE INDICATOR

    rect(230, 60, 43, 14, C.background)

    local pulseColor = C.greenDim

    if pulseTimer > 0 then
        pulseColor = C.green
    elseif not heartbeatValid then
        pulseColor = C.red
    end

    if pulseTimer > 0 then

        rect(233, 63, 7, 7, pulseColor)
        rect(244, 63, 7, 7, pulseColor)
        rect(255, 63, 7, 7, pulseColor)

    else

        rect(233, 63, 7, 7, C.grid)
        rect(244, 63, 7, 7, pulseColor)
        rect(255, 63, 7, 7, C.grid)

    end

    -- SYNC STATUS

    line(10, 77, 278, 77, C.grid)

    txt(11, 79, "SYNC", C.grey)

    txt(43, 79,
        heartbeatValid and "LOCKED" or "NO SYNC",
        heartbeatValid and C.green or C.red)

    txt(165, 79, "SEQUENCE", C.grey)

    txt(225, 79,
        headerValid and decimalValid and "VALID" or "ERROR",
        headerValid and decimalValid and C.green or C.red)

end


-- ============================================================
-- 13. LINK HEALTH
-- ============================================================

local function drawLinkQuality()

    panel(5, 94, 137, 36)

    sectionTitle(10, 97, "02", "LINK HEALTH")

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

    txt(11, 109,
        tostring(math.floor(ratio * 100)) .. "%",
        color)

    bar(49, 113, 83, 5, ratio, color)

    txt(11, 120, "RX AGE", C.grey)

    txt(55, 120, formatCounter(rxAge / 60), C.white)

end


-- ============================================================
-- 14. TIMEOUT MONITOR
-- ============================================================

local function drawTimer()

    panel(147, 94, 136, 36)

    sectionTitle(152, 97, "03", "TIMEOUT")

    local remaining = math.max(0, timeout - rxAge)

    txt(153, 109, "LIMIT", C.grey)
    txt(190, 109, tostring(timeout), C.white)

    txt(153, 120, "AGE", C.grey)
    txt(190, 120, tostring(math.floor(rxAge)), C.white)

    txt(237, 109, "LEFT", C.grey)
    txt(237, 120, tostring(math.floor(remaining)), C.amber)

end


-- ============================================================
-- 15. FREQUENCY MONITOR
-- ============================================================

local function drawFrequency()

    panel(5, 134, 278, 21)

    txt(10, 137, "04", C.amber)

    txt(27, 137, "RF", C.white)

    txt(50, 137, "TX", C.grey)
    txt(66, 137, formatFrequency(frequencyTX), C.green)

    txt(112, 137, "RX", C.grey)
    txt(128, 137, formatFrequency(frequencyRX), C.cyan)

    txt(207, 137, role, C.white)

    txt(10, 147, "BASE", C.grey)
    txt(39, 147, formatFrequency(baseFrequency), C.white)

    txt(108, 147, "STEP", C.grey)
    txt(138, 147, formatFrequency(frequencyDistance), C.white)

    txt(225, 147, "YR-02", C.amber)

end


-- ============================================================
-- 16. WARNING INDICATOR
-- ============================================================

local function drawWarning()

    if lost and warningBlink then

        rect(0, 0, 288, 2, C.red)

    elseif searching and warningBlink then

        rect(0, 0, 288, 2, C.amber)

    end

end


-- ============================================================
-- 17. MAIN DRAW
-- ============================================================

function onDraw()

    drawBackground()

    drawHeader()

    drawConnection()

    drawHeartbeat()

    drawLinkQuality()

    drawTimer()

    drawFrequency()

    drawWarning()

end


-- ============================================================
-- END MC02
-- OAI MIZUSHIMA YR-02
-- ============================================================
