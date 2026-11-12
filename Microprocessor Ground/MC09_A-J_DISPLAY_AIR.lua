-- AIR LINK DEBUG DISPLAY

local state = 0
local rxAge = 0
local txCounter = 0

function onTick()

    state = input.getNumber(5)
    rxAge = input.getNumber(6)
    txCounter = input.getNumber(7)

    local connected = input.getBool(1)
    local searching = input.getBool(2)
    local lost = input.getBool(3)

    -- STORE DEBUG DATA
    output.setNumber(1, state)
    output.setNumber(2, rxAge)
    output.setNumber(3, txCounter)

    output.setBool(1, connected)
    output.setBool(2, searching)
    output.setBool(3, lost)

end

function onDraw()

    local w = screen.getWidth()
    local h = screen.getHeight()

    screen.setColor(10, 15, 20)
    screen.drawClear()

    -- HEADER
    screen.setColor(0, 200, 255)
    screen.drawText(2, 2, "AIR LINK DEBUG")

    screen.setColor(80, 100, 110)
    screen.drawLine(2, 11, w-2, 11)

    -- CONNECTION STATUS
    if state == 1 then
        screen.setColor(0, 255, 80)
        screen.drawText(2, 15, "LINK: CONNECTED")
    elseif state == 0 then
        screen.setColor(255, 190, 0)
        screen.drawText(2, 15, "LINK: SEARCHING")
    else
        screen.setColor(255, 40, 40)
        screen.drawText(2, 15, "LINK: LOST")
    end

    -- TELEMETRY
    screen.setColor(200, 220, 230)
    screen.drawText(2, 27, "AIR ID: 1")
    screen.drawText(2, 36, "GROUND ID: 2")

    screen.drawText(2, 48, "TX COUNT:")
    screen.drawText(65, 48, tostring(txCounter))

    screen.drawText(2, 58, "RX AGE:")
    screen.drawText(65, 58, tostring(rxAge))

    -- SIGNAL AGE BAR
    screen.setColor(80, 80, 80)
    screen.drawRect(2, 73, w-4, 5)

    local bar = math.max(0, math.min(1, 1 - rxAge/180))

    if state == 1 then
        screen.setColor(0, 255, 80)
    else
        screen.setColor(255, 50, 30)
    end

    screen.drawRectF(2, 73, (w-4)*bar, 5)

    -- FOOTER
    screen.setColor(0, 180, 220)
    screen.drawText(2, h-9, "PROTOCOL: 7319  V1")

end