
-- OAI MIZUSHIMA YR-02
-- MC 03: FLIGHT CONTROL
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Roll stabilization control


--------------------------------------------------
-- 01. INPUT CONFIGURATION
--------------------------------------------------

local INPUT = {

    MULTIPLIER      = 1,
    TILT_ROLL_HORIZ = 2,

    ROLL_STABILIZER = 3

}


--------------------------------------------------
-- 02. OUTPUT CONFIGURATION
--------------------------------------------------

local OUTPUT = {

    ROLL_LEFT  = 1,
    ROLL_RIGHT = 2

}


--------------------------------------------------
-- 03. FLIGHT CONTROL
--------------------------------------------------

local function updateRollController(data, enabled)

    if not enabled then

        return {

            rollLeft = 0,

            rollRight = 0

        }

    end


    -- ORIGINAL V13.1.0 CALCULATION

    local rollControl =

        data.tiltRollHoriz * data.multiplier


    return {

        rollLeft = rollControl,

        rollRight = -rollControl

    }

end


--------------------------------------------------
-- 04. MAIN TICK
--------------------------------------------------

function onTick()

    -- READ PHYSICAL SENSORS

    local data = {

        multiplier =
            input.getNumber(INPUT.MULTIPLIER),

        tiltRollHoriz =
            input.getNumber(INPUT.TILT_ROLL_HORIZ)

    }


    -- READ MASTER COMMAND

    local rollStabilizerEnabled =

        input.getBool(INPUT.ROLL_STABILIZER)


    -- ROLL CONTROL

    local flight = updateRollController(

        data,

        rollStabilizerEnabled

    )


    -- AILERON OUTPUTS

    output.setNumber(

        OUTPUT.ROLL_LEFT,

        flight.rollLeft

    )


    output.setNumber(

        OUTPUT.ROLL_RIGHT,

        flight.rollRight

    )

end


-- END OF MC 03
