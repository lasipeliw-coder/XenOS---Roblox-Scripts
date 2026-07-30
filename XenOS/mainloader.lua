-- XenOS Universal Loader

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local BASE_URL =
    "https://raw.githubusercontent.com/" ..
    "lasipeliw-coder/XenOS---Roblox-Scripts/" ..
    "refs/heads/main/XenOS/"

local ENV = getgenv and getgenv() or _G

ENV.XenOS = ENV.XenOS or {}

local XenOS = ENV.XenOS

XenOS.Version = "0.1.1"
XenOS.PlaceId = game.PlaceId
XenOS.GameId = game.GameId
XenOS.Loaded = false
XenOS.ActiveModule = nil

------------------------------------------------------------
-- Prevent duplicate loader
------------------------------------------------------------

if XenOS.LoaderRunning then
    warn("[XenOS] Loader is already running.")
    return
end

XenOS.LoaderRunning = true

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function log(...)
    print("[XenOS]", ...)
end

local function warning(...)
    warn("[XenOS]", ...)
end

------------------------------------------------------------
-- Game aliases
------------------------------------------------------------

local PLACE_ALIASES = {

    -- Blox Fruits First Sea
    [2753915549] = "2753915549",

    -- Blox Fruits Second Sea
    [4442272183] = "2753915549",

    -- Blox Fruits Third Sea
    [7449423635] = "2753915549",
}

------------------------------------------------------------
-- Determine module
------------------------------------------------------------

local currentPlaceId = game.PlaceId

local moduleName =
    PLACE_ALIASES[currentPlaceId]
    or tostring(currentPlaceId)

local modulePath =
    "SPGames/" .. moduleName .. ".lua"

local moduleURL =
    BASE_URL .. modulePath

------------------------------------------------------------
-- Header
------------------------------------------------------------

print("")
print("====================================================")
print("                     XenOS")
print("====================================================")

log("Version :", XenOS.Version)
log("PlaceId :", currentPlaceId)
log("GameId  :", game.GameId)
log("Module  :", modulePath)
log("URL     :", moduleURL)

if moduleName ~= tostring(currentPlaceId) then
    log(
        "Alias   :",
        tostring(currentPlaceId),
        "->",
        moduleName
    )
end

------------------------------------------------------------
-- Download
------------------------------------------------------------

local function download(url)

    local success, response =
        pcall(function()
            return game:HttpGet(url)
        end)

    if not success then
        return nil, tostring(response)
    end

    if type(response) ~= "string" then
        return nil, "HTTP response wasn't a string."
    end

    if #response == 0 then
        return nil, "GitHub returned an empty response."
    end

    --------------------------------------------------------
    -- Detect obvious GitHub error responses
    --------------------------------------------------------

    if response:find("404: Not Found", 1, true) then
        return nil, "GitHub returned 404: Not Found"
    end

    if response:find("<!DOCTYPE html>", 1, true) then
        return nil, "GitHub returned HTML instead of Lua."
    end

    return response
end

------------------------------------------------------------
-- Compile
------------------------------------------------------------

local function compile(source, chunkName)

    if type(loadstring) ~= "function" then
        return nil, "Executor does not support loadstring()."
    end

    --------------------------------------------------------
    -- Capture BOTH return values from loadstring.
    --
    -- loadstring normally returns:
    --
    -- function
    --
    -- OR
    --
    -- nil, "syntax error..."
    --------------------------------------------------------

    local success, chunk, compileError =
        pcall(
            loadstring,
            source,
            chunkName
        )

    if not success then
        return nil, tostring(chunk)
    end

    if type(chunk) ~= "function" then

        return nil,
            tostring(
                compileError
                or "loadstring returned nil."
            )
    end

    return chunk
end

------------------------------------------------------------
-- Download module
------------------------------------------------------------

log("Looking for supported game module...")

local source, downloadError =
    download(moduleURL)

if not source then

    warning("Game module could not be downloaded.")
    warning("Expected:", modulePath)
    warning("Reason:", downloadError)

    XenOS.LoaderRunning = false
    return
end

log(
    "Downloaded:",
    #source,
    "bytes"
)

------------------------------------------------------------
-- Small source sanity check
------------------------------------------------------------

log(
    "Source preview:",
    source:sub(1, 60):gsub("\n", " ")
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
    warning("Compiler error:")
    warning(compileError)

    XenOS.LoaderRunning = false
    return
end

log("Compilation successful.")

------------------------------------------------------------
-- Execute
------------------------------------------------------------

local success, moduleResult =
    pcall(chunk)

if not success then

    warning("Game module crashed while running.")
    warning(moduleResult)

    XenOS.LoaderRunning = false
    return
end

------------------------------------------------------------
-- Success
------------------------------------------------------------

XenOS.ActiveModule = moduleResult
XenOS.Loaded = true
XenOS.LoaderRunning = false

log("Blox Fruits module successfully loaded.")

print("====================================================")
print("")
