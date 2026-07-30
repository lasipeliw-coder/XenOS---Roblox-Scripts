--[[
    XenOS - Universal Game Loader
    ------------------------------------
    Detects the current Roblox PlaceId,
    finds the matching XenOS game module,
    downloads it from GitHub, and runs it.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local REPOSITORY =
    "https://raw.githubusercontent.com/" ..
    "lasipeliw-coder/XenOS---Roblox-Scripts/main/"

local GAME_FOLDER = "SPGames/"

------------------------------------------------------------
-- XenOS global state
------------------------------------------------------------

local ENV = getgenv and getgenv() or _G

ENV.XenOS = ENV.XenOS or {}

local XenOS = ENV.XenOS

XenOS.Version = "0.1.0"
XenOS.PlaceId = game.PlaceId
XenOS.GameId = game.GameId
XenOS.Loaded = false
XenOS.ActiveModule = nil

------------------------------------------------------------
-- Prevent accidental double loading
------------------------------------------------------------

if XenOS.LoaderRunning then
    warn("[XenOS] Loader is already running.")
    return
end

XenOS.LoaderRunning = true

------------------------------------------------------------
-- Console helpers
------------------------------------------------------------

local function log(...)
    print("[XenOS]", ...)
end

local function warning(...)
    warn("[XenOS]", ...)
end

------------------------------------------------------------
-- Place aliases
------------------------------------------------------------

-- XenOS normally searches:
--
-- SPGames/<current PlaceId>.lua
--
-- Aliases allow multiple places belonging to the same game
-- to share ONE module.

local PLACE_ALIASES = {

    --------------------------------------------------------
    -- Blox Fruits
    --------------------------------------------------------

    -- First Sea is the primary module.
    [2753915549] = "2753915549",

    -- Second Sea
    [4442272183] = "2753915549",

    -- Third Sea
    [7449423635] = "2753915549",
}

------------------------------------------------------------
-- HTTP
------------------------------------------------------------

local function download(url)

    local success, response = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        return nil, tostring(response)
    end

    if type(response) ~= "string" or #response == 0 then
        return nil, "GitHub returned an empty response."
    end

    return response
end

------------------------------------------------------------
-- Compile
------------------------------------------------------------

local function compile(source, chunkName)

    if type(loadstring) ~= "function" then
        return nil, "Executor does not provide loadstring()."
    end

    local success, result = pcall(function()
        return loadstring(source, chunkName)
    end)

    if not success then
        return nil, tostring(result)
    end

    if type(result) ~= "function" then
        return nil, "loadstring() did not return a function."
    end

    return result
end

------------------------------------------------------------
-- Determine module
------------------------------------------------------------

local placeId = game.PlaceId

local moduleName =
    PLACE_ALIASES[placeId]
    or tostring(placeId)

local modulePath =
    GAME_FOLDER ..
    moduleName ..
    ".lua"

local moduleURL =
    REPOSITORY ..
    modulePath

------------------------------------------------------------
-- Startup output
------------------------------------------------------------

print("")
print("====================================================")
print("                     XenOS")
print("====================================================")

log("Version:", XenOS.Version)
log("PlaceId:", placeId)
log("GameId :", game.GameId)
log("Module :", modulePath)

if moduleName ~= tostring(placeId) then

    log(
        "Alias  :",
        tostring(placeId),
        "->",
        moduleName
    )

end

------------------------------------------------------------
-- Download game module
------------------------------------------------------------

log("Checking GitHub for supported game...")

local source, downloadError =
    download(moduleURL)

if not source then

    warning("Unsupported game or module unavailable.")
    warning("Expected:", modulePath)
    warning("Reason:", downloadError)

    XenOS.LoaderRunning = false

    return
end

log(
    "Downloaded",
    #source,
    "bytes."
)

------------------------------------------------------------
-- Compile module
------------------------------------------------------------

local chunk, compileError =
    compile(
        source,
        "@XenOS/" .. modulePath
    )

if not chunk then

    warning("Game module failed to compile.")
    warning(compileError)

    XenOS.LoaderRunning = false

    return
end

------------------------------------------------------------
-- Execute
------------------------------------------------------------

log("Starting game module...")

local success, module =
    pcall(chunk)

if not success then

    warning("Game module crashed:")
    warning(module)

    XenOS.LoaderRunning = false

    return
end

------------------------------------------------------------
-- Save module
------------------------------------------------------------

XenOS.ActiveModule = module
XenOS.Loaded = true
XenOS.LoaderRunning = false

log("Successfully loaded.")
print("====================================================")
print("")
