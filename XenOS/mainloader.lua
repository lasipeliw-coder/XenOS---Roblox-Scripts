--============================================================
-- XenOS Universal Loader
-- v0.5.0
--============================================================

if not game:IsLoaded() then
    game.Loaded:Wait()
end

------------------------------------------------------------
-- Services
------------------------------------------------------------

local Players =
    game:GetService("Players")

local CoreGui =
    game:GetService("CoreGui")

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local BASE_URL =
    "https://raw.githubusercontent.com/" ..
    "lasipeliw-coder/" ..
    "XenOS---Roblox-Scripts/" ..
    "main/XenOS/SPGames/"

------------------------------------------------------------
-- Logging
------------------------------------------------------------

local function log(...)
    print("[XenOS]", ...)
end

local function fail(...)
    warn("[XenOS ERROR]", ...)
end

------------------------------------------------------------
-- Global state
------------------------------------------------------------

local ENV =
    (getgenv and getgenv())
    or _G

ENV.XenOS =
    ENV.XenOS or {}

local XenOS =
    ENV.XenOS

XenOS.Version =
    "0.5.0"

XenOS.PlaceId =
    game.PlaceId

XenOS.GameId =
    game.GameId

XenOS.Loaded =
    false

XenOS.ActiveModule =
    nil

------------------------------------------------------------
-- Loading screen helpers
------------------------------------------------------------

local function New(className, properties)

    local object =
        Instance.new(className)

    for property, value
        in pairs(properties or {})
    do
        object[property] = value
    end

    return object
end

local function Corner(object, radius)

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(0, radius or 8)

    corner.Parent =
        object
end

local function ResolveUIParent()

    if type(gethui) == "function" then

        local success, result =
            pcall(gethui)

        if success and typeof(result) == "Instance" then
            return result
        end
    end

    local success, result =
        pcall(function()
            return CoreGui
        end)

    if success and result then
        return result
    end

    local player =
        Players.LocalPlayer

    if not player then
        player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = Players.LocalPlayer
    end

    return player:WaitForChild("PlayerGui")
end

local LoadingScreen =
    nil

local LoadingStatus =
    nil

local LoadingBar =
    nil

local function UpdateLoading(text, progress)

    if LoadingStatus and LoadingStatus.Parent then
        LoadingStatus.Text =
            tostring(text)
    end

    if LoadingBar and LoadingBar.Parent then

        LoadingBar.Size =
            UDim2.new(
                math.clamp(progress or 0, 0, 1),
                0,
                1,
                0
            )
    end
end

local function DestroyLoadingScreen()

    if LoadingScreen then

        pcall(function()
            LoadingScreen:Destroy()
        end)
    end

    LoadingScreen = nil
    LoadingStatus = nil
    LoadingBar = nil
end

local function CreateLoadingScreen()

    local parent =
        ResolveUIParent()

    local old =
        parent:FindFirstChild("XenOS_Loading")

    if old then
        old:Destroy()
    end

    LoadingScreen =
        New(
            "ScreenGui",
            {
                Name = "XenOS_Loading",
                ResetOnSpawn = false,
                IgnoreGuiInset = false,
                DisplayOrder = 999999,
                ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            }
        )

    LoadingScreen.Parent =
        parent

    local card =
        New(
            "Frame",
            {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromOffset(360, 154),
                BackgroundColor3 = Color3.fromRGB(13, 23, 34),
                BorderSizePixel = 0,
            }
        )

    card.Parent =
        LoadingScreen

    Corner(card, 10)

    local cardStroke =
        New(
            "UIStroke",
            {
                Color = Color3.fromRGB(165, 126, 56),
                Thickness = 1,
                Transparency = 0.2,
            }
        )

    cardStroke.Parent =
        card

    local accent =
        New(
            "Frame",
            {
                Size = UDim2.new(1, 0, 0, 3),
                BackgroundColor3 = Color3.fromRGB(224, 179, 78),
                BorderSizePixel = 0,
            }
        )

    accent.Parent =
        card

    local gradient =
        New(
            "UIGradient",
            {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(
                        0,
                        Color3.fromRGB(165, 126, 56)
                    ),
                    ColorSequenceKeypoint.new(
                        0.55,
                        Color3.fromRGB(224, 179, 78)
                    ),
                    ColorSequenceKeypoint.new(
                        1,
                        Color3.fromRGB(69, 137, 191)
                    ),
                })
            }
        )

    gradient.Parent =
        accent

    local title =
        New(
            "TextLabel",
            {
                Position = UDim2.fromOffset(24, 25),
                Size = UDim2.new(1, -48, 0, 27),
                BackgroundTransparency = 1,
                Text = "XenOS",
                TextColor3 = Color3.fromRGB(243, 239, 226),
                TextSize = 22,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }
        )

    title.Parent =
        card

    local subtitle =
        New(
            "TextLabel",
            {
                Position = UDim2.fromOffset(25, 54),
                Size = UDim2.new(1, -50, 0, 17),
                BackgroundTransparency = 1,
                Text = "UNIVERSAL LOADER",
                TextColor3 = Color3.fromRGB(224, 179, 78),
                TextSize = 9,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }
        )

    subtitle.Parent =
        card

    LoadingStatus =
        New(
            "TextLabel",
            {
                Position = UDim2.fromOffset(25, 84),
                Size = UDim2.new(1, -50, 0, 18),
                BackgroundTransparency = 1,
                Text = "Preparing XenOS...",
                TextColor3 = Color3.fromRGB(145, 160, 172),
                TextSize = 11,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }
        )

    LoadingStatus.Parent =
        card

    local barBackground =
        New(
            "Frame",
            {
                Position = UDim2.fromOffset(25, 116),
                Size = UDim2.new(1, -50, 0, 8),
                BackgroundColor3 = Color3.fromRGB(24, 43, 60),
                BorderSizePixel = 0,
            }
        )

    barBackground.Parent =
        card

    Corner(barBackground, 8)

    LoadingBar =
        New(
            "Frame",
            {
                Size = UDim2.new(0, 0, 1, 0),
                BackgroundColor3 = Color3.fromRGB(69, 137, 191),
                BorderSizePixel = 0,
            }
        )

    LoadingBar.Parent =
        barBackground

    Corner(LoadingBar, 8)

    pcall(function()

        if syn and syn.protect_gui then
            syn.protect_gui(LoadingScreen)
        end
    end)

    UpdateLoading(
        "Preparing XenOS...",
        0.1
    )
end

local function CompleteLoading(text)

    UpdateLoading(
        text,
        1
    )

    task.wait(0.25)

    DestroyLoadingScreen()
end

local function FailLoading(text)

    UpdateLoading(
        text,
        1
    )

    task.wait(1)

    DestroyLoadingScreen()
end

------------------------------------------------------------
-- Supported experiences
------------------------------------------------------------

-- Universe/GameId maps cover every place inside an experience.
-- PlaceId fallback maps cover a named root place directly.

local GAME_MODULES = {

    -- Blox Fruits
    [994732206] = "2753915549.lua",

    -- Brookhaven RP
    [1686885941] = "4924922222.lua",
}

local PLACE_MODULES = {

    -- Brookhaven RP root place
    [4924922222] = "4924922222.lua",
}

------------------------------------------------------------
-- Startup
------------------------------------------------------------

CreateLoadingScreen()

UpdateLoading(
    "Detecting supported experience...",
    0.2
)

local currentGameId =
    game.GameId

local currentPlaceId =
    game.PlaceId

print("")
print("====================================================")
print("                       XenOS")
print("====================================================")

log("Version :", XenOS.Version)
log("GameId  :", currentGameId)
log("PlaceId :", currentPlaceId)

local fileName =
    GAME_MODULES[currentGameId]
    or PLACE_MODULES[currentPlaceId]

if not fileName then

    fail("XenOS does not currently support this game.")
    fail("Unknown GameId:", currentGameId)
    fail("Current PlaceId:", currentPlaceId)

    FailLoading(
        "This experience is not supported yet."
    )

    return
end

log("Supported experience detected.")
log("Loading module:", fileName)

UpdateLoading(
    "Downloading everything...",
    0.4
)

local moduleURL =
    BASE_URL
    .. fileName
    .. "?nocache="
    .. tostring(os.time())

log("Downloading game module...")

local success, source =
    pcall(function()

        return game:HttpGet(
            moduleURL
        )
    end)

if not success then

    fail("Failed to download game module.")
    fail(source)

    FailLoading(
        "Download failed. Check F9 for details."
    )

    return
end

if type(source) ~= "string" then

    fail("Expected Lua source string.")

    FailLoading(
        "The module response was invalid."
    )

    return
end

if #source == 0 then

    fail("Downloaded module was empty.")

    FailLoading(
        "The downloaded module was empty."
    )

    return
end

if source:find(
    "404: Not Found",
    1,
    true
) then

    fail("Module does not exist on GitHub:", fileName)

    FailLoading(
        "The game module has not been uploaded yet."
    )

    return
end

log("Downloaded:", #source, "bytes")

UpdateLoading(
    "Compiling game module...",
    0.7
)

if type(loadstring) ~= "function" then

    fail("Executor does not support loadstring().")

    FailLoading(
        "This executor does not support loadstring."
    )

    return
end

local compiled, compileError =
    loadstring(source)

if not compiled then

    fail("Module failed to compile.")
    fail(compileError or "Unknown compiler error.")

    FailLoading(
        "The game module has a compile error."
    )

    return
end

log("Compilation successful.")

UpdateLoading(
    "Starting game module...",
    0.88
)

local ran, result =
    pcall(compiled)

if not ran then

    fail("Module runtime error.")
    fail(result)

    FailLoading(
        "The game module could not start."
    )

    return
end

XenOS.ActiveModule =
    result

XenOS.ModuleFile =
    fileName

XenOS.Loaded =
    true

log("Successfully loaded:", fileName)

CompleteLoading(
    "Everything is ready."
)

print("====================================================")
print("")
