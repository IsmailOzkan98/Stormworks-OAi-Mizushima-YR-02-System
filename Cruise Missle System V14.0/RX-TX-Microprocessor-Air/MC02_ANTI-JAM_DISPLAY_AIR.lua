
-- ============================================================
-- OAI MIZUSHIMA
-- MC02: DIAGNOSTIC DISPLAY
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
--
-- RESPONSIBILITY:
-- Visual monitoring of MC01 Universal Link System.
--
-- DISPLAY:
-- 9 x 5 BLOCKS (288 x 160)
--
-- ============================================================


-- ============================================================
-- 1. INPUT CONFIGURATION
-- ============================================================

-- NUMBER INPUTS

local IN_PROTOCOL    = 1
local IN_LOCAL_ID    = 2
local IN_TX_COUNTER  = 3
local IN_VERSION     = 4
local IN_STATE       = 5
local IN_RX_AGE      = 6
local IN_FREQ_TX     = 7
local IN_FREQ_RX     = 8

-- EXTERNAL NUMBER INPUTS

local IN_TIMEOUT     = 9
local IN_RX_COUNTER  = 10


-- BOOL INPUTS

local IN_CONNECTED   = 1
local IN_SEARCHING   = 2
local IN_LINK_LOST   = 3

-- EXTERNAL BOOL INPUTS

local IN_ROLE        = 4
local IN_AFH_ENABLED = 5
local IN_AFH_ACTIVE  = 6


-- ============================================================
-- 2. DISPLAY DATA
-- ============================================================

local data = {
    protocol = 0,
    localID = 0,
    txCounter = 0,
    rxCounter = 0,
    version = 0,

    state = 0,
    rxAge = 0,
    timeout = 0,

    frequencyTX = 0,
    frequencyRX = 0,

    connected = false,
    searching = true,
    linkLost = false,

    roleAir = false,

    afhEnabled = false,
    afhActive = false
}


-- ============================================================
-- 3. UTILITIES
-- ============================================================

local function integer(value)
    return math.floor(value + 0.5)
end


local function numberText(value, decimals)
    return string.format("%." .. decimals .. "f", value)
end


local function drawText(x, y, text, r, g, b)
    screen.setColor(r, g, b)
    screen.drawText(x, y, tostring(text))
end


local function drawPanel(x, y, w, h)

    screen.setColor(13, 19, 27)
    screen.drawRectF(x, y, w, h)

    screen.setColor(42, 55, 68)
    screen.drawRect(x, y, w, h)

end


-- ============================================================
-- 4. TICK PROCESSING
-- ============================================================

function onTick()

    -- MC01 DATA

    data.protocol =
        input.getNumber(IN_PROTOCOL)

    data.localID =
        input.getNumber(IN_LOCAL_ID)

    data.txCounter =
        input.getNumber(IN_TX_COUNTER)

    data.version =
        input.getNumber(IN_VERSION)

    data.state =
        input.getNumber(IN_STATE)

    data.rxAge =
        input.getNumber(IN_RX_AGE)

    data.frequencyTX =
        input.getNumber(IN_FREQ_TX)

    data.frequencyRX =
        input.getNumber(IN_FREQ_RX)


    -- EXTERNAL DATA

    data.timeout =
        input.getNumber(IN_TIMEOUT)

    data.rxCounter =
        input.getNumber(IN_RX_COUNTER)


    -- CONNECTION STATUS

    data.connected =
        input.getBool(IN_CONNECTED)

    data.searching =
        input.getBool(IN_SEARCHING)

    data.linkLost =
        input.getBool(IN_LINK_LOST)


    -- OPERATIONAL ROLE

    data.roleAir =
        input.getBool(IN_ROLE)


    -- AFH STATUS

    data.afhEnabled =
        input.getBool(IN_AFH_ENABLED)

    data.afhActive =
        input.getBool(IN_AFH_ACTIVE)

end


-- ============================================================
-- 5. DISPLAY RENDERING
-- ============================================================

function onDraw()

    local W = screen.getWidth()
    local H = screen.getHeight()

    -- BACKGROUND

    screen.setColor(5, 9, 14)
    screen.drawClear()


    -- ========================================================
    -- 5.1 HEADER
    -- ========================================================

    screen.setColor(17, 29, 41)
    screen.drawRectF(0, 0, W, 19)

    drawText(
        5, 5,
        "OAI MIZUSHIMA / MC02",
        180, 200, 215
    )

    screen.setColor(42, 55, 68)
    screen.drawLine(0, 19, W, 19)


    -- ========================================================
    -- 5.2 CONNECTION STATUS
    -- ========================================================

    drawPanel(5, 23, 72, 27)
    drawPanel(82, 23, W - 87, 27)

    drawText(10, 26, "ROLE", 120, 145, 165)

    if data.roleAir then
        drawText(10, 36, "AIR", 70, 190, 255)
    else
        drawText(10, 36, "GROUND", 70, 190, 255)
    end


    drawText(88, 26, "LINK STATUS", 120, 145, 165)

    if data.connected then

        drawText(88, 36, "CONNECTED", 70, 235, 125)

    elseif data.linkLost then

        drawText(88, 36, "LINK LOST", 255, 65, 65)

    elseif data.searching then

        drawText(88, 36, "SEARCHING", 255, 190, 65)

    else

        drawText(88, 36, "UNKNOWN", 170, 170, 170)

    end


    -- ========================================================
    -- 5.3 COMMUNICATION
    -- ========================================================

    drawPanel(5, 54, 137, 46)
    drawPanel(147, 54, W - 152, 46)


    -- RX AGE

    drawText(10, 58, "RX AGE", 120, 145, 165)

    drawText(
        10, 69,
        integer(data.rxAge) .. " / " .. integer(data.timeout),
        230, 235, 245
    )

    -- RX AGE PROGRESS BAR

    local barX = 10
    local barY = 87
    local barW = 125
    local barH = 6

    screen.setColor(35, 45, 55)
    screen.drawRectF(barX, barY, barW, barH)

    local ratio = 0

    if data.timeout > 0 then
        ratio = math.min(
            math.max(data.rxAge / data.timeout, 0),
            1
        )
    end

    local barColorR = 65
    local barColorG = 210
    local barColorB = 115

    if ratio >= 0.75 then
        barColorR = 255
        barColorG = 170
        barColorB = 45
    end

    if data.linkLost then
        barColorR = 255
        barColorG = 55
        barColorB = 55
    end

    screen.setColor(barColorR, barColorG, barColorB)

    screen.drawRectF(
        barX,
        barY,
        math.floor(barW * ratio),
        barH
    )


    -- HEARTBEAT COUNTERS

    drawText(153, 58, "HEARTBEAT", 120, 145, 165)

    drawText(153, 71, "TX", 100, 175, 225)

    drawText(
        170, 71,
        numberText(data.txCounter, 1),
        230, 235, 245
    )

    drawText(215, 71, "RX", 100, 175, 225)

    drawText(
        232, 71,
        numberText(data.rxCounter, 1),
        230, 235, 245
    )


    -- ========================================================
    -- 5.4 FREQUENCY MONITOR
    -- ========================================================

    drawPanel(5, 104, 171, 45)

    drawText(10, 108, "FREQUENCY MONITOR", 120, 145, 165)

    drawText(10, 122, "TX", 100, 175, 225)

    drawText(
        35, 122,
        integer(data.frequencyTX),
        235, 235, 245
    )

    drawText(92, 122, "RX", 100, 175, 225)

    drawText(
        117, 122,
        integer(data.frequencyRX),
        235, 235, 245
    )


    -- ========================================================
    -- 5.5 AFH STATUS
    -- ========================================================

    drawPanel(181, 104, W - 186, 45)

    drawText(186, 108, "AFH STATUS", 120, 145, 165)

    if data.afhActive then

        drawText(186, 123, "ACTIVE", 70, 235, 125)

    elseif data.afhEnabled then

        drawText(186, 123, "STANDBY", 255, 190, 65)

    else

        drawText(186, 123, "DISABLED", 155, 165, 175)

    end


    -- ========================================================
    -- 5.6 SYSTEM IDENTIFICATION
    -- ========================================================

    screen.setColor(42, 55, 68)
    screen.drawLine(5, 154, W - 5, 154)

    drawText(
        5, 155,
        "ID " .. integer(data.localID),
        155, 175, 190
    )

    drawText(
        75, 155,
        "PROT " .. integer(data.protocol),
        155, 175, 190
    )

    drawText(
        170, 155,
        "VER " .. numberText(data.version, 1),
        155, 175, 190
    )

end

