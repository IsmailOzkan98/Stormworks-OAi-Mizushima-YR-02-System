-- OAI MIZUSHIMA YR-02
-- MC01: SYSTEM AUTHORITY
-- Stormworks
-- Migrated from v13.1.0
-- Version v1.0.0

--------------------------------------------------
-- INPUTS
--------------------------------------------------

-- Boolean 1: AUTHORITY_ENABLE

--------------------------------------------------
-- OUTPUTS
--------------------------------------------------

-- Boolean 1: SYSTEM_AUTHORIZED
-- Boolean 2: AUTHORITY_READY
-- Boolean 3: AUTHORITY_DENIED

--------------------------------------------------
-- STATE
--------------------------------------------------

local authority = {
    enabled = false,
    authorized = false,
    ready = false,
    denied = true
}

--------------------------------------------------
-- SYSTEM AUTHORITY
--------------------------------------------------

local function updateAuthority()

    authority.authorized = authority.enabled
    authority.ready = authority.authorized
    authority.denied = not authority.authorized

end

--------------------------------------------------
-- INPUT
--------------------------------------------------

local function readInputs()

    authority.enabled = input.getBool(1)

end

--------------------------------------------------
-- OUTPUT
--------------------------------------------------

local function writeOutputs()

    output.setBool(1, authority.authorized)
    output.setBool(2, authority.ready)
    output.setBool(3, authority.denied)

end

--------------------------------------------------
-- MAIN
--------------------------------------------------

function onTick()

    readInputs()
    updateAuthority()
    writeOutputs()

end