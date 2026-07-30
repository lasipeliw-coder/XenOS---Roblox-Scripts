--============================================================
-- XenOS Universal Loader
-- v0.4.0
--============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

------------------------------------------------------------
-- CONFIG
------------------------------------------------------------

local BASE_URL =
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
-- GLOBAL STATE
------------------------------------------------------------

local ENV =
    (getgenv and getgenv())
    or _G

ENV.XenOS =
    ENV.XenOS or {}

local XenOS =
    ENV.XenOS

XenOS.Version =
    "0.4.0"

XenOS.PlaceId =
    game.PlaceId

XenOS.GameId =
    game.GameId

XenOS.Loaded =
    false

XenOS.ActiveModule =
    nil

------------------------------------------------------------
-- SUPPORTED EXPERIENCES
------------------------------------------------------------

-- IMPORTANT:
--
-- Use Universe/GameId here.
--
-- This remains the same even if Roblox places the player
-- inside another sub-place belonging to the same experience.
--
-- value = filename inside SPGames

local GAME_MODULES = {

    --------------------------------------------------------
    -- Blox Fruits
    --------------------------------------------------------

    [994732206] = "2753915549.lua",

}

------------------------------------------------------------
-- CURRENT EXPERIENCE
------------------------------------------------------------

local currentGameId =
    game.GameId

local currentPlaceId =
    game.PlaceId

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

print("")
print("====================================================")
print("                       XenOS")
print("====================================================")

log("Version :", XenOS.Version)
log("GameId  :", currentGameId)
log("PlaceId :", currentPlaceId)

------------------------------------------------------------
-- RESOLVE GAME
------------------------------------------------------------

local fileName =
    GAME_MODULES[currentGameId]

if not fileName then

    fail("XenOS does not currently support this game.")

    fail(
        "Unknown GameId:",
        currentGameId
    )

    fail(
        "Current PlaceId:",
        currentPlaceId
    )

    return
end

------------------------------------------------------------
-- MATCH FOUND
------------------------------------------------------------

log(
    "Supported experience detected."
)

log(
    "GameId:",
    currentGameId
)

log(
    "Loading module:",
    fileName
)

------------------------------------------------------------
-- BUILD URL
------------------------------------------------------------

local moduleURL =
    BASE_URL
    .. fileName
    .. "?nocache="
    .. tostring(os.time())

log("Downloading game module...")

------------------------------------------------------------
-- DOWNLOAD
------------------------------------------------------------

local success, source =
    pcall(function()

        return game:HttpGet(
            moduleURL
        )

    end)

if not success then

    fail(
        "Failed to download module."
    )

    fail(source)

    return
end

------------------------------------------------------------
-- VALIDATE SOURCE
------------------------------------------------------------

if type(source) ~= "string" then

    fail(
        "Expected Lua source string."
    )

    return
end

if #source == 0 then

    fail(
        "Downloaded module was empty."
    )

    return
end

if source:find(
    "404: Not Found",
    1,
    true
) then

    fail(
        "Module does not exist on GitHub:",
        fileName
    )

    return
end

------------------------------------------------------------
-- DOWNLOAD SUCCESS
------------------------------------------------------------

log(
    "Downloaded:",
    #source,
    "bytes"
)

------------------------------------------------------------
-- COMPILE
------------------------------------------------------------

if type(loadstring) ~= "function" then

    fail(
        "Executor does not support loadstring()."
    )

    return
end

local compiled, compileError =
    loadstring(source)

if not compiled then

    fail(
        "Module failed to compile."
    )

    fail(
        compileError
        or "Unknown compiler error."
    )

    return
end

log(
    "Compilation successful."
)

------------------------------------------------------------
-- EXECUTE
------------------------------------------------------------

local ran, result =
    pcall(compiled)

if not ran then

    fail(
        "Module runtime error."
    )

    fail(result)

    return
end

------------------------------------------------------------
-- STORE MODULE
------------------------------------------------------------

XenOS.ActiveModule =
    result

XenOS.ModuleFile =
    fileName

XenOS.Loaded =
    true

------------------------------------------------------------
-- SUCCESS
------------------------------------------------------------

log(
    "Successfully loaded:",
    fileName
)

print("====================================================")
print("")
