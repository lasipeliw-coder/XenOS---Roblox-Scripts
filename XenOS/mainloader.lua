--============================================================
-- XenOS Universal Loader
-- v0.2.0
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

local function errorLog(...)
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
    "0.2.0"

XenOS.PlaceId =
    game.PlaceId

XenOS.GameId =
    game.GameId

XenOS.Loaded =
    false

XenOS.ActiveModule =
    nil

------------------------------------------------------------
-- PLACE ALIASES
------------------------------------------------------------

-- Normally XenOS loads:
--
-- SPGames/<PlaceId>.lua
--
-- Some Roblox games use multiple PlaceIds.
-- Those can point to one shared module here.

local PlaceAliases = {

    --------------------------------------------------------
    -- Blox Fruits
    --------------------------------------------------------

    -- First Sea
    [2753915549] = 2753915549,

    -- Second Sea
    [4442272183] = 2753915549,

    -- Third Sea
    [7449423635] = 2753915549,
}

------------------------------------------------------------
-- DETECT CURRENT GAME
------------------------------------------------------------

local currentPlaceId =
    game.PlaceId

local moduleId =
    PlaceAliases[currentPlaceId]
    or currentPlaceId

------------------------------------------------------------
-- BUILD URL
------------------------------------------------------------

local moduleURL =
    BASE_URL
    .. tostring(moduleId)
    .. ".lua"
    .. "?nocache="
    .. tostring(os.time())

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

print("")
print("==================================================")
print("                    XenOS")
print("==================================================")

log("Version :", XenOS.Version)
log("PlaceId :", currentPlaceId)
log("GameId  :", game.GameId)
log("Module  :", tostring(moduleId) .. ".lua")

if moduleId ~= currentPlaceId then

    log(
        "Alias   :",
        currentPlaceId,
        "->",
        moduleId
    )

end

------------------------------------------------------------
-- DOWNLOAD MODULE
------------------------------------------------------------

log("Downloading game module...")

local success, source =
    pcall(function()

        return game:HttpGet(
            moduleURL
        )

    end)

if not success then

    errorLog(
        "Failed to download game module."
    )

    errorLog(source)

    return
end

------------------------------------------------------------
-- RESPONSE VALIDATION
------------------------------------------------------------

if type(source) ~= "string" then

    errorLog(
        "Expected Lua source, got:",
        typeof(source)
    )

    return
end

if #source == 0 then

    errorLog(
        "Downloaded module was empty."
    )

    return
end

------------------------------------------------------------
-- DETECT GITHUB ERROR
------------------------------------------------------------

if source:find(
    "404: Not Found",
    1,
    true
) then

    errorLog(
        "XenOS does not currently support this game."
    )

    errorLog(
        "Missing module:",
        tostring(moduleId) .. ".lua"
    )

    return
end

------------------------------------------------------------
-- DEBUG OUTPUT
------------------------------------------------------------

log(
    "Downloaded:",
    #source,
    "bytes"
)

------------------------------------------------------------
-- CHECK LOADSTRING
------------------------------------------------------------

if type(loadstring) ~= "function" then

    errorLog(
        "Executor does not support loadstring()."
    )

    return
end

------------------------------------------------------------
-- COMPILE
------------------------------------------------------------

local compiled, compileError =
    loadstring(source)

if not compiled then

    errorLog(
        "Game module failed to compile."
    )

    errorLog(
        compileError
        or "Unknown compilation error."
    )

    return
end

log(
    "Module compiled successfully."
)

------------------------------------------------------------
-- EXECUTE
------------------------------------------------------------

local ran, result =
    pcall(compiled)

if not ran then

    errorLog(
        "Game module crashed."
    )

    errorLog(result)

    return
end

------------------------------------------------------------
-- STORE MODULE
------------------------------------------------------------

XenOS.ActiveModule =
    result

XenOS.Loaded =
    true

------------------------------------------------------------
-- COMPLETE
------------------------------------------------------------

log(
    "Game module loaded successfully."
)

print("==================================================")
print("")
