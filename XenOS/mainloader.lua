--============================================================
-- XenOS Universal Loader
-- v0.3.0
--============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local RAW_BASE =
    "https://raw.githubusercontent.com/" ..
    "lasipeliw-coder/" ..
    "XenOS---Roblox-Scripts/" ..
    "main/XenOS/SPGames/"

------------------------------------------------------------
-- LOGGING
------------------------------------------------------------

local function log(...)
    print("[XenOS]", ...)
end

local function fail(...)
    warn("[XenOS ERROR]", ...)
end

------------------------------------------------------------
-- XENOS STATE
------------------------------------------------------------

local env =
    (getgenv and getgenv())
    or _G

env.XenOS =
    env.XenOS or {}

local XenOS =
    env.XenOS

XenOS.Version = "0.3.0"
XenOS.PlaceId = game.PlaceId
XenOS.GameId = game.GameId
XenOS.Loaded = false
XenOS.ActiveModule = nil

------------------------------------------------------------
-- SUPPORTED PLACE ALIASES
------------------------------------------------------------

-- key   = place currently being played
-- value = filename inside XenOS/SPGames

local PLACE_MODULES = {

    --------------------------------------------------------
    -- BLOX FRUITS
    --------------------------------------------------------

    -- First Sea
    [2753915549] = "2753915549.lua",

    -- Second Sea
    [4442272183] = "2753915549.lua",

    -- Third Sea
    [7449423635] = "2753915549.lua",
}

------------------------------------------------------------
-- CURRENT PLACE
------------------------------------------------------------

local placeId =
    game.PlaceId

print("")
print("====================================================")
print("                       XenOS")
print("====================================================")

log("Loader Version :", XenOS.Version)
log("PlaceId        :", placeId)
log("Universe/GameId:", game.GameId)

------------------------------------------------------------
-- RESOLVE FILE
------------------------------------------------------------

local fileName =
    PLACE_MODULES[placeId]

------------------------------------------------------------
-- FUTURE GAME FALLBACK
------------------------------------------------------------

-- If the place isn't explicitly aliased above,
-- try <PlaceId>.lua automatically.

if not fileName then
    fileName =
        tostring(placeId) .. ".lua"

    log(
        "No alias found; trying automatic filename:",
        fileName
    )
else
    log(
        "Matched module:",
        fileName
    )
end

------------------------------------------------------------
-- CREATE EXACT GITHUB URL
------------------------------------------------------------

local moduleURL =
    RAW_BASE
    .. fileName
    .. "?nocache="
    .. tostring(os.time())

log("Module URL:")
print(moduleURL)

------------------------------------------------------------
-- DOWNLOAD
------------------------------------------------------------

log("Downloading module...")

local success, source =
    pcall(function()

        return game:HttpGet(
            moduleURL
        )

    end)

if not success then

    fail("HTTP request failed:")
    fail(source)

    return
end

------------------------------------------------------------
-- RESPONSE CHECK
------------------------------------------------------------

if type(source) ~= "string" then

    fail(
        "Expected string source, received:",
        typeof(source)
    )

    return
end

log(
    "Received",
    #source,
    "bytes"
)

------------------------------------------------------------
-- DEBUG PREVIEW
------------------------------------------------------------

print("")
log("SOURCE PREVIEW:")

print(
    source:sub(
        1,
        math.min(#source, 120)
    )
)

print("")

------------------------------------------------------------
-- GITHUB 404 CHECK
------------------------------------------------------------

if
    source:find(
        "404: Not Found",
        1,
        true
    )
then

    fail(
        "GitHub says this file doesn't exist:"
    )

    fail(fileName)

    fail(
        "Requested URL:"
    )

    fail(moduleURL)

    return
end

------------------------------------------------------------
-- HTML CHECK
------------------------------------------------------------

if
    source:find(
        "<!DOCTYPE",
        1,
        true
    )
then

    fail(
        "GitHub returned HTML instead of Lua."
    )

    return
end

------------------------------------------------------------
-- LOADSTRING CHECK
------------------------------------------------------------

if type(loadstring) ~= "function" then

    fail(
        "Executor does not support loadstring()."
    )

    return
end

------------------------------------------------------------
-- COMPILE
------------------------------------------------------------

log("Compiling", fileName)

local compiled, compileError =
    loadstring(source)

if not compiled then

    fail(
        "Failed to compile:",
        fileName
    )

    fail(
        compileError
        or "Unknown compiler error"
    )

    return
end

log("Compilation successful.")

------------------------------------------------------------
-- EXECUTE
------------------------------------------------------------

log("Executing", fileName)

local ran, result =
    pcall(compiled)

if not ran then

    fail(
        "Module runtime error:"
    )

    fail(result)

    return
end

------------------------------------------------------------
-- SUCCESS
------------------------------------------------------------

XenOS.ActiveModule =
    result

XenOS.Loaded =
    true

XenOS.ModuleFile =
    fileName

log(
    "Successfully loaded:",
    fileName
)

print("====================================================")
print("")
