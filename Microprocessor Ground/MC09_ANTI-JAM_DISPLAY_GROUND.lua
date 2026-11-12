
-- GROUND LINK DEBUG DISPLAY
-- STORMWORKS LUA

local state = 0
local rxAge = 0
local txCounter = 0

local connected = false
local searching = true
local lost = false

function onTick()

    state = input.getNumber(5)
    rxAge = input.getNumber(6)
    txCounter = input.getNumber(7)

    connected = input.getBool(1)
    searching = input.getBool(2)
    lost = input.getBool(3)

end

function onDraw()

    local w = screen.getWidth()
    local h = screen.getHeight()

    -- BACKGROUND
    screen.setColor(5, 10, 8)
    screen.drawRectF(0, 0, w, h)

    -- HEADER
    screen.setColor(0, 220, 120)
    screen.drawText(2, 2, "GROUND LINK DEBUG")

    screen.setColor(50, 100, 70)
    screen.drawLine(2, 11, w-2, 11)

    -- STATUS
    if connected then
        screen.setColor(0, 255, 80)
        screen.drawText(2, 15, "LINK: CONNECTED")

    elseif searching then
        screen.setColor(255, 190, 0)
        screen.drawText(2, 15, "LINK: SEARCHING")

    elseif lost then
        screen.setColor(255, 40, 40)
        screen.drawText(2, 15, "LINK: LOST")
    end

    -- DEVICE INFO
    screen.setColor(180, 220, 190)
    screen.drawText(2, 27, "GROUND ID: 2")
    screen.drawText(2, 36, "AIR ID: 1")

    -- TELEMETRY
    screen.setColor(200, 255, 200)

    screen.drawText(2, 48, "TX COUNT:")
    screen.drawText(65, 48, tostring(txCounter))

    screen.drawText(2, 58, "RX AGE:")
    screen.drawText(65, 58, tostring(rxAge))

    -- SIGNAL AGE BAR
    screen.setColor(60, 60, 60)
    screen.drawRect(2, 73, w-4, 5)

    local bar = math.max(0, math.min(1, 1-rxAge/180))

    if connected then
        screen.setColor(0, 255, 80)
    else
        screen.setColor(255, 50, 30)
    end

    screen.drawRectF(2, 73, (w-4)*bar, 5)

    -- FOOTER
    screen.setColor(0, 220, 120)
    screen.drawText(2, h-9, "PROTOCOL: 7319 V1")

end
