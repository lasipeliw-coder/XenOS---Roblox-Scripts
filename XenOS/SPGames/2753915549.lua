--[[
    ============================================================
                    XenOS - Blox Fruits
    ============================================================

    Version: 0.3.0

    Current Features:
        - Auto Farm Chest

    Controls:
        RightShift = Show / Hide XenOS

    Auto Farm Chest:
        Workspace
        └── Map
            └── <Model Name>
                └── Chests
                    ├── Chest1
                    ├── Chest2
                    ├── Chest3
                    └── ...

    The farmer:
        1. Finds the nearest chest.
        2. Tweens toward it.
        3. Watches the chest that was selected.
        4. Detects when its original children are deleted.
        5. Cancels the tween.
        6. Moves to the next chest.
]]

------------------------------------------------------------
-- Services
------------------------------------------------------------

local Players =
    game:GetService("Players")

local Workspace =
    game:GetService("Workspace")

local UserInputService =
    game:GetService("UserInputService")

local TweenService =
    game:GetService("TweenService")

local RunService =
    game:GetService("RunService")

local CoreGui =
    game:GetService("CoreGui")

------------------------------------------------------------
-- Player
------------------------------------------------------------

local Player =
    Players.LocalPlayer

if not Player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    Player = Players.LocalPlayer
end

------------------------------------------------------------
-- Global XenOS environment
------------------------------------------------------------

local ENV =
    (getgenv and getgenv())
    or _G

ENV.XenOS =
    ENV.XenOS
    or {}

------------------------------------------------------------
-- Remove previous Blox Fruits XenOS instance
------------------------------------------------------------

if ENV.XenOS.BloxFruitsUI then

    local old =
        ENV.XenOS.BloxFruitsUI

    if type(old.Destroy) == "function" then

        pcall(function()
            old:Destroy()
        end)

    end

end

ENV.XenOS.BloxFruitsUI =
    nil

------------------------------------------------------------
-- Connections
------------------------------------------------------------

local Connections =
    {}

local function Connect(
    signal,
    callback
)

    local connection =
        signal:Connect(callback)

    table.insert(
        Connections,
        connection
    )

    return connection
end

------------------------------------------------------------
-- Module state
------------------------------------------------------------

local Destroyed =
    false

local AutoFarmChest =
    false

local CurrentChest =
    nil

local CurrentTween =
    nil

local FarmGeneration =
    0

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local Config = {

    --------------------------------------------------------
    -- Studs traveled per second
    --------------------------------------------------------

    ChestTweenSpeed =
        260,

    --------------------------------------------------------
    -- Position relative to chest
    --------------------------------------------------------

    ChestOffset =
        Vector3.new(
            0,
            1.5,
            0
        ),

    --------------------------------------------------------
    -- Delay before rescanning after chest collection
    --------------------------------------------------------

    RescanDelay =
        0.10,
}

------------------------------------------------------------
-- Sea detection
------------------------------------------------------------

local SEA_NAMES = {

    [2753915549] =
        "FIRST SEA",

    [4442272183] =
        "SECOND SEA",

    [7449423635] =
        "THIRD SEA",
}

local CurrentSea =
    SEA_NAMES[game.PlaceId]
    or "BLOX FRUITS"

------------------------------------------------------------
-- Theme
------------------------------------------------------------

local Theme = {

    Background =
        Color3.fromRGB(
            13,
            23,
            34
        ),

    Surface =
        Color3.fromRGB(
            18,
            32,
            46
        ),

    SurfaceRaised =
        Color3.fromRGB(
            24,
            43,
            60
        ),

    SurfaceHover =
        Color3.fromRGB(
            31,
            54,
            74
        ),

    Gold =
        Color3.fromRGB(
            224,
            179,
            78
        ),

    GoldSoft =
        Color3.fromRGB(
            165,
            126,
            56
        ),

    Ocean =
        Color3.fromRGB(
            46,
            105,
            155
        ),

    OceanBright =
        Color3.fromRGB(
            69,
            137,
            191
        ),

    Green =
        Color3.fromRGB(
            83,
            184,
            116
        ),

    Red =
        Color3.fromRGB(
            171,
            57,
            53
        ),

    RedHover =
        Color3.fromRGB(
            204,
            70,
            64
        ),

    Text =
        Color3.fromRGB(
            243,
            239,
            226
        ),

    TextMuted =
        Color3.fromRGB(
            145,
            160,
            172
        ),

    TextDark =
        Color3.fromRGB(
            20,
            23,
            27
        ),
}

------------------------------------------------------------
-- UI utilities
------------------------------------------------------------

local function New(
    className,
    properties
)

    local object =
        Instance.new(className)

    for property, value
        in pairs(properties or {})
    do

        object[property] =
            value

    end

    return object
end

local function Corner(
    object,
    radius
)

    local corner =
        Instance.new("UICorner")

    corner.CornerRadius =
        UDim.new(
            0,
            radius or 7
        )

    corner.Parent =
        object

    return corner
end

local function Stroke(
    object,
    color,
    thickness,
    transparency
)

    local stroke =
        Instance.new("UIStroke")

    stroke.Color =
        color
        or Theme.GoldSoft

    stroke.Thickness =
        thickness
        or 1

    stroke.Transparency =
        transparency
        or 0

    stroke.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    stroke.Parent =
        object

    return stroke
end

------------------------------------------------------------
-- Character helpers
------------------------------------------------------------

local function GetCharacter()

    local character =
        Player.Character

    if not character then
        return nil
    end

    return character
end

local function GetRootPart()

    local character =
        GetCharacter()

    if not character then
        return nil
    end

    return character:FindFirstChild(
        "HumanoidRootPart"
    )
end

------------------------------------------------------------
-- UI Parent
------------------------------------------------------------

local function ResolveUIParent()

    if type(gethui) == "function" then

        local success, result =
            pcall(gethui)

        if
            success
            and typeof(result) == "Instance"
        then

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

    return Player:WaitForChild(
        "PlayerGui"
    )
end

local UIParent =
    ResolveUIParent()

------------------------------------------------------------
-- Hard remove duplicate ScreenGui
------------------------------------------------------------

for _, child
    in ipairs(UIParent:GetChildren())
do

    if
        child:IsA("ScreenGui")
        and child.Name == "XenOS_BloxFruits"
    then

        child:Destroy()

    end

end

------------------------------------------------------------
-- ScreenGui
------------------------------------------------------------

local ScreenGui =
    New(
        "ScreenGui",
        {
            Name =
                "XenOS_BloxFruits",

            ResetOnSpawn =
                false,

            IgnoreGuiInset =
                false,

            DisplayOrder =
                1000000,

            ZIndexBehavior =
                Enum.ZIndexBehavior.Sibling,

            Enabled =
                true,
        }
    )

ScreenGui.Parent =
    UIParent

------------------------------------------------------------
-- Main Window
------------------------------------------------------------

local Main =
    New(
        "Frame",
        {
            Name =
                "Main",

            AnchorPoint =
                Vector2.new(
                    0.5,
                    0.5
                ),

            Position =
                UDim2.fromScale(
                    0.5,
                    0.5
                ),

            Size =
                UDim2.fromOffset(
                    520,
                    310
                ),

            BackgroundColor3 =
                Theme.Background,

            BorderSizePixel =
                0,

            ClipsDescendants =
                true,
        }
    )

Main.Parent =
    ScreenGui

Corner(
    Main,
    10
)

Stroke(
    Main,
    Theme.GoldSoft,
    1,
    0.25
)

------------------------------------------------------------
-- Gold accent
------------------------------------------------------------

local Accent =
    New(
        "Frame",
        {
            Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    3
                ),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

Accent.Parent =
    Main

local AccentGradient =
    New(
        "UIGradient",
        {
            Color =
                ColorSequence.new({

                    ColorSequenceKeypoint.new(
                        0,
                        Theme.GoldSoft
                    ),

                    ColorSequenceKeypoint.new(
                        0.55,
                        Theme.Gold
                    ),

                    ColorSequenceKeypoint.new(
                        1,
                        Theme.OceanBright
                    ),
                })
        }
    )

AccentGradient.Parent =
    Accent

------------------------------------------------------------
-- Topbar
------------------------------------------------------------

local Topbar =
    New(
        "Frame",
        {
            Name =
                "Topbar",

            Position =
                UDim2.fromOffset(
                    0,
                    3
                ),

            Size =
                UDim2.new(
                    1,
                    0,
                    0,
                    46
                ),

            BackgroundColor3 =
                Theme.Surface,

            BorderSizePixel =
                0,

            Active =
                true,
        }
    )

Topbar.Parent =
    Main

------------------------------------------------------------
-- Logo
------------------------------------------------------------

local Logo =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    12,
                    9
                ),

            Size =
                UDim2.fromOffset(
                    28,
                    28
                ),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

Logo.Parent =
    Topbar

Corner(
    Logo,
    7
)

local LogoText =
    New(
        "TextLabel",
        {
            Size =
                UDim2.fromScale(
                    1,
                    1
                ),

            BackgroundTransparency =
                1,

            Text =
                "X",

            TextColor3 =
                Theme.TextDark,

            TextSize =
                17,

            Font =
                Enum.Font.GothamBlack,
        }
    )

LogoText.Parent =
    Logo

------------------------------------------------------------
-- Title
------------------------------------------------------------

local Title =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    50,
                    6
                ),

            Size =
                UDim2.new(
                    1,
                    -110,
                    0,
                    19
                ),

            BackgroundTransparency =
                1,

            Text =
                "XenOS",

            TextColor3 =
                Theme.Text,

            TextSize =
                15,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Title.Parent =
    Topbar

local Subtitle =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    50,
                    24
                ),

            Size =
                UDim2.new(
                    1,
                    -110,
                    0,
                    13
                ),

            BackgroundTransparency =
                1,

            Text =
                "BLOX FRUITS • "
                .. CurrentSea,

            TextColor3 =
                Theme.Gold,

            TextSize =
                8,

            Font =
                Enum.Font.GothamMedium,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Subtitle.Parent =
    Topbar

------------------------------------------------------------
-- Close button
------------------------------------------------------------

local Close =
    New(
        "TextButton",
        {
            AnchorPoint =
                Vector2.new(
                    1,
                    0.5
                ),

            Position =
                UDim2.new(
                    1,
                    -10,
                    0.5,
                    0
                ),

            Size =
                UDim2.fromOffset(
                    27,
                    27
                ),

            BackgroundColor3 =
                Theme.Red,

            BorderSizePixel =
                0,

            AutoButtonColor =
                false,

            Text =
                "×",

            TextColor3 =
                Theme.Text,

            TextSize =
                18,

            Font =
                Enum.Font.GothamBold,
        }
    )

Close.Parent =
    Topbar

Corner(
    Close,
    7
)

------------------------------------------------------------
-- Body
------------------------------------------------------------

local Body =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    0,
                    49
                ),

            Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    -49
                ),

            BackgroundTransparency =
                1,
        }
    )

Body.Parent =
    Main

------------------------------------------------------------
-- Sidebar
------------------------------------------------------------

local SidebarWidth =
    125

local Sidebar =
    New(
        "Frame",
        {
            Name =
                "Sidebar",

            Size =
                UDim2.new(
                    0,
                    SidebarWidth,
                    1,
                    0
                ),

            BackgroundColor3 =
                Theme.Surface,

            BorderSizePixel =
                0,
        }
    )

Sidebar.Parent =
    Body

local Divider =
    New(
        "Frame",
        {
            AnchorPoint =
                Vector2.new(
                    1,
                    0
                ),

            Position =
                UDim2.new(
                    1,
                    0,
                    0,
                    0
                ),

            Size =
                UDim2.new(
                    0,
                    1,
                    1,
                    0
                ),

            BackgroundColor3 =
                Theme.GoldSoft,

            BackgroundTransparency =
                0.68,

            BorderSizePixel =
                0,
        }
    )

Divider.Parent =
    Sidebar

------------------------------------------------------------
-- Navigation header
------------------------------------------------------------

local NavHeader =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    12,
                    12
                ),

            Size =
                UDim2.new(
                    1,
                    -24,
                    0,
                    14
                ),

            BackgroundTransparency =
                1,

            Text =
                "NAVIGATION",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                8,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

NavHeader.Parent =
    Sidebar

------------------------------------------------------------
-- Home tab
------------------------------------------------------------

local Home =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    8,
                    35
                ),

            Size =
                UDim2.new(
                    1,
                    -16,
                    0,
                    33
                ),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,
        }
    )

Home.Parent =
    Sidebar

Corner(
    Home,
    7
)

local HomeAccent =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    0,
                    7
                ),

            Size =
                UDim2.fromOffset(
                    3,
                    19
                ),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

HomeAccent.Parent =
    Home

Corner(
    HomeAccent,
    3
)

local HomeText =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    13,
                    0
                ),

            Size =
                UDim2.new(
                    1,
                    -13,
                    1,
                    0
                ),

            BackgroundTransparency =
                1,

            Text =
                "Home",

            TextColor3 =
                Theme.Text,

            TextSize =
                10,

            Font =
                Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

HomeText.Parent =
    Home

------------------------------------------------------------
-- RightShift hint
------------------------------------------------------------

local KeyHint =
    New(
        "TextLabel",
        {
            AnchorPoint =
                Vector2.new(
                    0,
                    1
                ),

            Position =
                UDim2.new(
                    0,
                    12,
                    1,
                    -10
                ),

            Size =
                UDim2.new(
                    1,
                    -24,
                    0,
                    28
                ),

            BackgroundTransparency =
                1,

            Text =
                "RIGHT SHIFT\nShow / Hide",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                8,

            Font =
                Enum.Font.GothamMedium,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            TextYAlignment =
                Enum.TextYAlignment.Bottom,
        }
    )

KeyHint.Parent =
    Sidebar

------------------------------------------------------------
-- Content
------------------------------------------------------------

local Content =
    New(
        "Frame",
        {
            Name =
                "Content",

            Position =
                UDim2.fromOffset(
                    SidebarWidth,
                    0
                ),

            Size =
                UDim2.new(
                    1,
                    -SidebarWidth,
                    1,
                    0
                ),

            BackgroundTransparency =
                1,
        }
    )

Content.Parent =
    Body

------------------------------------------------------------
-- Content title
------------------------------------------------------------

local ContentTitle =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    18,
                    16
                ),

            Size =
                UDim2.new(
                    1,
                    -36,
                    0,
                    24
                ),

            BackgroundTransparency =
                1,

            Text =
                "Main",

            TextColor3 =
                Theme.Text,

            TextSize =
                17,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

ContentTitle.Parent =
    Content

local ContentSubtitle =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    19,
                    39
                ),

            Size =
                UDim2.new(
                    1,
                    -38,
                    0,
                    17
                ),

            BackgroundTransparency =
                1,

            Text =
                "Blox Fruits automation",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                9,

            Font =
                Enum.Font.Gotham,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

ContentSubtitle.Parent =
    Content

------------------------------------------------------------
-- Auto Chest feature card
------------------------------------------------------------

local ChestCard =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    18,
                    70
                ),

            Size =
                UDim2.new(
                    1,
                    -36,
                    0,
                    94
                ),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,
        }
    )

ChestCard.Parent =
    Content

Corner(
    ChestCard,
    8
)

Stroke(
    ChestCard,
    Theme.Ocean,
    1,
    0.6
)

------------------------------------------------------------
-- Feature title
------------------------------------------------------------

local ChestTitle =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    14,
                    10
                ),

            Size =
                UDim2.new(
                    1,
                    -75,
                    0,
                    20
                ),

            BackgroundTransparency =
                1,

            Text =
                "Auto Farm Chest",

            TextColor3 =
                Theme.Text,

            TextSize =
                12,

            Font =
                Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

ChestTitle.Parent =
    ChestCard

------------------------------------------------------------
-- Feature description
------------------------------------------------------------

local ChestDescription =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    14,
                    32
                ),

            Size =
                UDim2.new(
                    1,
                    -28,
                    0,
                    28
                ),

            BackgroundTransparency =
                1,

            Text =
                "Moves between available map chests automatically.",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                9,

            TextWrapped =
                true,

            Font =
                Enum.Font.Gotham,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            TextYAlignment =
                Enum.TextYAlignment.Top,
        }
    )

ChestDescription.Parent =
    ChestCard

------------------------------------------------------------
-- Farm status
------------------------------------------------------------

local FarmStatus =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    14,
                    68
                ),

            Size =
                UDim2.new(
                    1,
                    -28,
                    0,
                    15
                ),

            BackgroundTransparency =
                1,

            Text =
                "Status: Disabled",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                8,

            Font =
                Enum.Font.Code,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

FarmStatus.Parent =
    ChestCard

------------------------------------------------------------
-- Toggle
------------------------------------------------------------

local ToggleButton =
    New(
        "TextButton",
        {
            AnchorPoint =
                Vector2.new(
                    1,
                    0
                ),

            Position =
                UDim2.new(
                    1,
                    -12,
                    0,
                    11
                ),

            Size =
                UDim2.fromOffset(
                    42,
                    22
                ),

            BackgroundColor3 =
                Theme.Surface,

            BorderSizePixel =
                0,

            AutoButtonColor =
                false,

            Text =
                "",
        }
    )

ToggleButton.Parent =
    ChestCard

Corner(
    ToggleButton,
    20
)

local ToggleKnob =
    New(
        "Frame",
        {
            AnchorPoint =
                Vector2.new(
                    0,
                    0.5
                ),

            Position =
                UDim2.new(
                    0,
                    3,
                    0.5,
                    0
                ),

            Size =
                UDim2.fromOffset(
                    16,
                    16
                ),

            BackgroundColor3 =
                Theme.TextMuted,

            BorderSizePixel =
                0,
        }
    )

ToggleKnob.Parent =
    ToggleButton

Corner(
    ToggleKnob,
    20
)

------------------------------------------------------------
-- Footer
------------------------------------------------------------

local Footer =
    New(
        "TextLabel",
        {
            AnchorPoint =
                Vector2.new(
                    0,
                    1
                ),

            Position =
                UDim2.new(
                    0,
                    19,
                    1,
                    -11
                ),

            Size =
                UDim2.new(
                    1,
                    -38,
                    0,
                    15
                ),

            BackgroundTransparency =
                1,

            Text =
                "XenOS • Blox Fruits • v0.3",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                8,

            Font =
                Enum.Font.Code,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Footer.Parent =
    Content

------------------------------------------------------------
-- Status helper
------------------------------------------------------------

local function SetFarmStatus(text)

    FarmStatus.Text =
        "Status: "
        .. tostring(text)

end

------------------------------------------------------------
-- Chest helpers
------------------------------------------------------------

local function IsChestName(name)

    if type(name) ~= "string" then
        return false
    end

    return name:match(
        "^Chest%d+$"
    ) ~= nil
end

------------------------------------------------------------
-- Resolve chest position part
------------------------------------------------------------

local function GetChestPart(chest)

    if not chest then
        return nil
    end

    --------------------------------------------------------
    -- Direct BasePart
    ------------------------------------------------------------

    if chest:IsA("BasePart") then
        return chest
    end

    --------------------------------------------------------
    -- Model support
    ------------------------------------------------------------

    if chest:IsA("Model") then

        if chest.PrimaryPart then
            return chest.PrimaryPart
        end

        return chest:FindFirstChildWhichIsA(
            "BasePart",
            true
        )
    end

    --------------------------------------------------------
    -- Fallback for other containers
    ------------------------------------------------------------

    return chest:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end

------------------------------------------------------------
-- Find all chest objects
------------------------------------------------------------

local function FindChests()

    local results =
        {}

    local map =
        Workspace:FindFirstChild(
            "Map"
        )

    if not map then
        return results
    end

    --------------------------------------------------------
    -- Expected:
    --
    -- Map
    -- └── ModelName
    --     └── Chests
    ------------------------------------------------------------

    for _, model
        in ipairs(map:GetChildren())
    do

        local chestFolder =
            model:FindFirstChild(
                "Chests"
            )

        if chestFolder then

            for _, chest
                in ipairs(
                    chestFolder:GetChildren()
                )
            do

                if IsChestName(
                    chest.Name
                ) then

                    local part =
                        GetChestPart(
                            chest
                        )

                    if part then

                        table.insert(
                            results,
                            chest
                        )

                    end

                end
            end

        end
    end

    return results
end

------------------------------------------------------------
-- Find nearest chest
------------------------------------------------------------

local function FindNearestChest()

    local root =
        GetRootPart()

    if not root then
        return nil
    end

    local nearest =
        nil

    local nearestDistance =
        math.huge

    for _, chest
        in ipairs(FindChests())
    do

        if chest ~= CurrentChest then

            local chestPart =
                GetChestPart(
                    chest
                )

            if chestPart then

                local distance =
                    (
                        root.Position
                        - chestPart.Position
                    ).Magnitude

                if distance < nearestDistance then

                    nearestDistance =
                        distance

                    nearest =
                        chest

                end

            end

        end

    end

    return nearest
end

------------------------------------------------------------
-- Remember the chest's original children
------------------------------------------------------------

local function SnapshotChestChildren(
    chest
)

    local snapshot =
        {}

    if not chest then
        return snapshot
    end

    for _, child
        in ipairs(chest:GetChildren())
    do

        table.insert(
            snapshot,
            child
        )

    end

    return snapshot
end

------------------------------------------------------------
-- Determine whether selected chest has been collected
------------------------------------------------------------

local function ChestCollected(
    chest,
    originalChildren
)

    --------------------------------------------------------
    -- Chest itself disappeared
    ------------------------------------------------------------

    if not chest then
        return true
    end

    if not chest.Parent then
        return true
    end

    --------------------------------------------------------
    -- If the chest originally contained children,
    -- determine whether ALL original children have
    -- disappeared from that chest.
    ------------------------------------------------------------

    if #originalChildren > 0 then

        for _, child
            in ipairs(originalChildren)
        do

            if
                child
                and child.Parent
                and child:IsDescendantOf(chest)
            then

                return false
            end

        end

        return true
    end

    --------------------------------------------------------
    -- No original children existed.
    --
    -- In this case we can only positively identify
    -- collection if the chest object itself disappears.
    ------------------------------------------------------------

    return false
end

------------------------------------------------------------
-- Cancel active tween
------------------------------------------------------------

local function CancelCurrentTween()

    if CurrentTween then

        pcall(function()
            CurrentTween:Cancel()
        end)

        CurrentTween =
            nil

    end

end

------------------------------------------------------------
-- Move to chest and wait for collection
------------------------------------------------------------

local function TweenToChest(
    chest,
    generation
)

    if
        not AutoFarmChest
        or Destroyed
        or generation ~= FarmGeneration
    then

        return false
    end

    local root =
        GetRootPart()

    local chestPart =
        GetChestPart(
            chest
        )

    if
        not root
        or not chestPart
    then

        return false
    end

    --------------------------------------------------------
    -- Track exactly what this chest contained when
    -- we selected it.
    ------------------------------------------------------------

    local originalChildren =
        SnapshotChestChildren(
            chest
        )

    CurrentChest =
        chest

    SetFarmStatus(
        "Moving to "
        .. chest.Name
    )

    --------------------------------------------------------
    -- Destination
    ------------------------------------------------------------

    local targetCFrame =
        chestPart.CFrame
        + Config.ChestOffset

    local distance =
        (
            root.Position
            - targetCFrame.Position
        ).Magnitude

    local duration =
        distance
        / Config.ChestTweenSpeed

    duration =
        math.max(
            duration,
            0.05
        )

    --------------------------------------------------------
    -- Tween
    ------------------------------------------------------------

    local tween =
        TweenService:Create(
            root,

            TweenInfo.new(
                duration,
                Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out
            ),

            {
                CFrame =
                    targetCFrame
            }
        )

    CurrentTween =
        tween

    tween:Play()

    --------------------------------------------------------
    -- Watch chest while moving
    ------------------------------------------------------------

    while
        AutoFarmChest
        and not Destroyed
        and generation == FarmGeneration
    do

        ----------------------------------------------------
        -- Chest was collected during movement
        ----------------------------------------------------

        if ChestCollected(
            chest,
            originalChildren
        ) then

            CancelCurrentTween()

            SetFarmStatus(
                chest.Name
                .. " collected"
            )

            CurrentChest =
                nil

            return true
        end

        ----------------------------------------------------
        -- Target part itself vanished
        ----------------------------------------------------

        chestPart =
            GetChestPart(
                chest
            )

        if not chestPart then

            CancelCurrentTween()

            CurrentChest =
                nil

            return true
        end

        ----------------------------------------------------
        -- Check whether tween finished
        ----------------------------------------------------

        if
            tween.PlaybackState
                == Enum.PlaybackState.Completed
        then

            break
        end

        task.wait(
            0.05
        )
    end

    --------------------------------------------------------
    -- Feature disabled during tween
    ------------------------------------------------------------

    if
        not AutoFarmChest
        or Destroyed
        or generation ~= FarmGeneration
    then

        CancelCurrentTween()

        CurrentChest =
            nil

        return false
    end

    --------------------------------------------------------
    -- Tween finished.
    --
    -- Now remain on this chest until its children are
    -- deleted. We do NOT move to another chest early.
    ------------------------------------------------------------

    SetFarmStatus(
        "Waiting for "
        .. chest.Name
    )

    while
        AutoFarmChest
        and not Destroyed
        and generation == FarmGeneration
    do

        if ChestCollected(
            chest,
            originalChildren
        ) then

            CancelCurrentTween()

            SetFarmStatus(
                chest.Name
                .. " collected"
            )

            CurrentChest =
                nil

            return true
        end

        task.wait(
            0.05
        )
    end

    CancelCurrentTween()

    CurrentChest =
        nil

    return false
end

------------------------------------------------------------
-- Auto Farm loop
------------------------------------------------------------

local function StartAutoFarmChest()

    --------------------------------------------------------
    -- Increment generation so an older farm task cannot
    -- continue running after a restart.
    ------------------------------------------------------------

    FarmGeneration += 1

    local generation =
        FarmGeneration

    task.spawn(function()

        while
            AutoFarmChest
            and not Destroyed
            and generation == FarmGeneration
        do

            ------------------------------------------------
            -- Character may be respawning
            ------------------------------------------------

            local root =
                GetRootPart()

            if not root then

                SetFarmStatus(
                    "Waiting for character"
                )

                task.wait(
                    0.5
                )

                continue
            end

            ------------------------------------------------
            -- Find chest
            ------------------------------------------------

            local chest =
                FindNearestChest()

            if not chest then

                SetFarmStatus(
                    "Searching for chests"
                )

                task.wait(
                    0.5
                )

                continue
            end

            ------------------------------------------------
            -- Travel + wait for collection
            ------------------------------------------------

            TweenToChest(
                chest,
                generation
            )

            ------------------------------------------------
            -- Tiny delay before finding next chest
            ------------------------------------------------

            task.wait(
                Config.RescanDelay
            )
        end

        ----------------------------------------------------
        -- Only update UI if this is still the current farm
        ----------------------------------------------------

        if
            not Destroyed
            and generation == FarmGeneration
            and not AutoFarmChest
        then

            SetFarmStatus(
                "Disabled"
            )

        end

    end)
end

------------------------------------------------------------
-- Stop Auto Farm
------------------------------------------------------------

local function StopAutoFarmChest()

    AutoFarmChest =
        false

    FarmGeneration += 1

    CancelCurrentTween()

    CurrentChest =
        nil

    SetFarmStatus(
        "Disabled"
    )
end

------------------------------------------------------------
-- Update toggle visuals
------------------------------------------------------------

local function UpdateToggle()

    if AutoFarmChest then

        TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 =
                    Theme.Ocean
            }
        ):Play()

        TweenService:Create(
            ToggleKnob,
            TweenInfo.new(0.15),
            {
                Position =
                    UDim2.new(
                        1,
                        -19,
                        0.5,
                        0
                    ),

                BackgroundColor3 =
                    Theme.Text
            }
        ):Play()

    else

        TweenService:Create(
            ToggleButton,
            TweenInfo.new(0.15),
            {
                BackgroundColor3 =
                    Theme.Surface
            }
        ):Play()

        TweenService:Create(
            ToggleKnob,
            TweenInfo.new(0.15),
            {
                Position =
                    UDim2.new(
                        0,
                        3,
                        0.5,
                        0
                    ),

                BackgroundColor3 =
                    Theme.TextMuted
            }
        ):Play()

    end
end

------------------------------------------------------------
-- Toggle Auto Chest
------------------------------------------------------------

Connect(
    ToggleButton.MouseButton1Click,

    function()

        AutoFarmChest =
            not AutoFarmChest

        UpdateToggle()

        if AutoFarmChest then

            SetFarmStatus(
                "Starting"
            )

            StartAutoFarmChest()

        else

            StopAutoFarmChest()

        end

    end
)

------------------------------------------------------------
-- Draggable UI
------------------------------------------------------------

local Dragging =
    false

local DragInput =
    nil

local DragStart =
    nil

local StartPosition =
    nil

Connect(
    Topbar.InputBegan,

    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseButton1

            or

            input.UserInputType
                == Enum.UserInputType.Touch
        then

            Dragging =
                true

            DragStart =
                input.Position

            StartPosition =
                Main.Position

        end

    end
)

Connect(
    Topbar.InputChanged,

    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseMovement

            or

            input.UserInputType
                == Enum.UserInputType.Touch
        then

            DragInput =
                input

        end

    end
)

Connect(
    UserInputService.InputChanged,

    function(input)

        if
            Dragging
            and input == DragInput
        then

            local delta =
                input.Position
                - DragStart

            Main.Position =
                UDim2.new(

                    StartPosition.X.Scale,
                    StartPosition.X.Offset
                        + delta.X,

                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset
                        + delta.Y
                )

        end

    end
)

Connect(
    UserInputService.InputEnded,

    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseButton1

            or

            input.UserInputType
                == Enum.UserInputType.Touch
        then

            Dragging =
                false

        end

    end
)

------------------------------------------------------------
-- Show / Hide
------------------------------------------------------------

local Visible =
    true

local function SetVisible(state)

    Visible =
        state

    ScreenGui.Enabled =
        state

end

local function ToggleVisible()

    SetVisible(
        not Visible
    )
end

------------------------------------------------------------
-- Right Shift
------------------------------------------------------------

Connect(
    UserInputService.InputBegan,

    function(
        input,
        gameProcessed
    )

        if
            input.KeyCode
                == Enum.KeyCode.RightShift
        then

            ToggleVisible()

        end

    end
)

------------------------------------------------------------
-- Close = Hide
------------------------------------------------------------

Connect(
    Close.MouseButton1Click,

    function()

        SetVisible(
            false
        )

    end
)

------------------------------------------------------------
-- Close hover
------------------------------------------------------------

Connect(
    Close.MouseEnter,

    function()

        TweenService:Create(
            Close,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 =
                    Theme.RedHover
            }
        ):Play()

    end
)

Connect(
    Close.MouseLeave,

    function()

        TweenService:Create(
            Close,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 =
                    Theme.Red
            }
        ):Play()

    end
)

------------------------------------------------------------
-- Public XenOS API
------------------------------------------------------------

local UI =
    {}

UI.ScreenGui =
    ScreenGui

UI.Main =
    Main

UI.Content =
    Content

UI.Theme =
    Theme

UI.Sea =
    CurrentSea

------------------------------------------------------------
-- Show
------------------------------------------------------------

function UI:Show()

    SetVisible(
        true
    )

end

------------------------------------------------------------
-- Hide
------------------------------------------------------------

function UI:Hide()

    SetVisible(
        false
    )

end

------------------------------------------------------------
-- Toggle
------------------------------------------------------------

function UI:Toggle()

    ToggleVisible()

end

------------------------------------------------------------
-- IsVisible
------------------------------------------------------------

function UI:IsVisible()

    return Visible

end

------------------------------------------------------------
-- Auto Farm Chest API
------------------------------------------------------------

function UI:SetAutoFarmChest(state)

    state =
        state == true

    if
        state
        == AutoFarmChest
    then

        return

    end

    AutoFarmChest =
        state

    UpdateToggle()

    if AutoFarmChest then

        StartAutoFarmChest()

    else

        StopAutoFarmChest()

    end

end

------------------------------------------------------------
-- Get selected chest
------------------------------------------------------------

function UI:GetCurrentChest()

    return CurrentChest

end

------------------------------------------------------------
-- Destroy
------------------------------------------------------------

function UI:Destroy()

    if Destroyed then
        return
    end

    Destroyed =
        true

    --------------------------------------------------------
    -- Stop feature
    --------------------------------------------------------

    StopAutoFarmChest()

    --------------------------------------------------------
    -- Cancel tween
    --------------------------------------------------------

    CancelCurrentTween()

    --------------------------------------------------------
    -- Disconnect events
    --------------------------------------------------------

    for _, connection
        in ipairs(Connections)
    do

        pcall(function()

            if connection.Connected then
                connection:Disconnect()
            end

        end)

    end

    table.clear(
        Connections
    )

    --------------------------------------------------------
    -- Destroy UI
    --------------------------------------------------------

    if ScreenGui then

        pcall(function()
            ScreenGui:Destroy()
        end)

    end

    --------------------------------------------------------
    -- Remove global pointer
    --------------------------------------------------------

    if
        ENV.XenOS.BloxFruitsUI
        == UI
    then

        ENV.XenOS.BloxFruitsUI =
            nil

    end

end

------------------------------------------------------------
-- Register current XenOS instance
------------------------------------------------------------

ENV.XenOS.BloxFruitsUI =
    UI

------------------------------------------------------------
-- Initial UI state
------------------------------------------------------------

UpdateToggle()

SetFarmStatus(
    "Disabled"
)

------------------------------------------------------------
-- Loaded
------------------------------------------------------------

print(
    "[XenOS/BloxFruits]",
    "v0.3 loaded |",
    CurrentSea,
    "| Auto Farm Chest ready |",
    "RightShift = Toggle UI"
)

return UI
