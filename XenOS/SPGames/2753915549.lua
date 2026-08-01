--[[
    ============================================================
                    XenOS - Blox Fruits
    ============================================================

    Version: 0.4.1

    Feature:
        Auto Farm Chest

    Behavior:
        - Searches Workspace/Map/<Model>/Chests
        - Finds instances named Chest<number>
        - Moves to nearest available chest
        - Watches the EXACT selected chest
        - Tracks the selected chest's initial contents
        - The instant one of those contents is removed at any depth:
              * cancel tween
              * mark chest consumed
              * move to another chest
        - Already-consumed / empty chests are ignored

    Controls:
        RightShift = Show / Hide XenOS
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

local CoreGui =
    game:GetService("CoreGui")

------------------------------------------------------------
-- Player
------------------------------------------------------------

local Player =
    Players.LocalPlayer

while not Player do
    task.wait()
    Player = Players.LocalPlayer
end

------------------------------------------------------------
-- XenOS environment
------------------------------------------------------------

local ENV =
    (getgenv and getgenv())
    or _G

ENV.XenOS =
    ENV.XenOS
    or {}

------------------------------------------------------------
-- Destroy old XenOS instance
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

local Connections = {}

local function Connect(signal, callback)

    local connection =
        signal:Connect(callback)

    table.insert(
        Connections,
        connection
    )

    return connection
end

------------------------------------------------------------
-- State
------------------------------------------------------------

local Destroyed =
    false

local AutoFarmChest =
    false

local CurrentChest =
    nil

local CurrentTween =
    nil

local CurrentTargetCancel =
    nil

local FarmGeneration =
    0

------------------------------------------------------------
-- Consumed chests
------------------------------------------------------------

-- If a Chest# instance stays behind after its contents disappear,
-- this prevents XenOS from targeting it again.

local ConsumedChests =
    setmetatable(
        {},
        {
            __mode = "k"
        }
    )

------------------------------------------------------------
-- Configuration
------------------------------------------------------------

local Config = {

    TweenSpeed =
        275,

    ChestOffset =
        Vector3.new(
            0,
            1.5,
            0
        ),

    SearchDelay =
        0.12,

    NoChestDelay =
        0.5,
}

------------------------------------------------------------
-- Sea
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
-- Instance helper
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

    local c =
        Instance.new("UICorner")

    c.CornerRadius =
        UDim.new(
            0,
            radius or 7
        )

    c.Parent =
        object
end

local function Stroke(
    object,
    color,
    thickness,
    transparency
)

    local s =
        Instance.new("UIStroke")

    s.Color =
        color

    s.Thickness =
        thickness or 1

    s.Transparency =
        transparency or 0

    s.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    s.Parent =
        object
end

------------------------------------------------------------
-- Character
------------------------------------------------------------

local function GetCharacter()

    return Player.Character
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
-- UI parent
------------------------------------------------------------

local function GetUIParent()

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

    if success then
        return result
    end

    return Player:WaitForChild(
        "PlayerGui"
    )
end

local UIParent =
    GetUIParent()

------------------------------------------------------------
-- Remove duplicate GUI
------------------------------------------------------------

for _, object
    in ipairs(UIParent:GetChildren())
do

    if
        object:IsA("ScreenGui")
        and object.Name == "XenOS_BloxFruits"
    then

        object:Destroy()
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
-- Main window
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
                    500,
                    290
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

Corner(Main, 10)

Stroke(
    Main,
    Theme.GoldSoft,
    1,
    0.25
)

------------------------------------------------------------
-- Accent
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

------------------------------------------------------------
-- Accent gradient
------------------------------------------------------------

local AccentGradient =
    Instance.new("UIGradient")

AccentGradient.Color =
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
                    44
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
                    11,
                    8
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

Corner(Logo, 7)

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
                    48,
                    5
                ),

            Size =
                UDim2.new(
                    1,
                    -105,
                    0,
                    18
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
                    48,
                    22
                ),

            Size =
                UDim2.new(
                    1,
                    -105,
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
-- Close
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
                    -9,
                    0.5,
                    0
                ),

            Size =
                UDim2.fromOffset(
                    26,
                    26
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
                17,

            Font =
                Enum.Font.GothamBold,
        }
    )

Close.Parent =
    Topbar

Corner(Close, 7)

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
                    47
                ),

            Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    -47
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
    118

local Sidebar =
    New(
        "Frame",
        {
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

------------------------------------------------------------
-- Divider
------------------------------------------------------------

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
                0.7,

            BorderSizePixel =
                0,
        }
    )

Divider.Parent =
    Sidebar

------------------------------------------------------------
-- Navigation label
------------------------------------------------------------

local Navigation =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    11,
                    12
                ),

            Size =
                UDim2.new(
                    1,
                    -22,
                    0,
                    13
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

Navigation.Parent =
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
                    34
                ),

            Size =
                UDim2.new(
                    1,
                    -16,
                    0,
                    32
                ),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,
        }
    )

Home.Parent =
    Sidebar

Corner(Home, 7)

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
                    18
                ),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

HomeAccent.Parent =
    Home

Corner(HomeAccent, 3)

local HomeText =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    12,
                    0
                ),

            Size =
                UDim2.new(
                    1,
                    -12,
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
-- Keyboard hint
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
                    11,
                    1,
                    -9
                ),

            Size =
                UDim2.new(
                    1,
                    -22,
                    0,
                    27
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
-- Main heading
------------------------------------------------------------

local Heading =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    17,
                    14
                ),

            Size =
                UDim2.new(
                    1,
                    -34,
                    0,
                    22
                ),

            BackgroundTransparency =
                1,

            Text =
                "Main",

            TextColor3 =
                Theme.Text,

            TextSize =
                16,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Heading.Parent =
    Content

local HeadingSub =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    18,
                    36
                ),

            Size =
                UDim2.new(
                    1,
                    -36,
                    0,
                    15
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

HeadingSub.Parent =
    Content

------------------------------------------------------------
-- Auto Chest Card
------------------------------------------------------------

local ChestCard =
    New(
        "Frame",
        {
            Position =
                UDim2.fromOffset(
                    17,
                    64
                ),

            Size =
                UDim2.new(
                    1,
                    -34,
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

Corner(ChestCard, 8)

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
                    13,
                    9
                ),

            Size =
                UDim2.new(
                    1,
                    -70,
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
-- Description
------------------------------------------------------------

local Description =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    13,
                    30
                ),

            Size =
                UDim2.new(
                    1,
                    -26,
                    0,
                    28
                ),

            BackgroundTransparency =
                1,

            Text =
                "Moves to each available chest automatically.",

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

Description.Parent =
    ChestCard

------------------------------------------------------------
-- Status
------------------------------------------------------------

local FarmStatus =
    New(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(
                    13,
                    67
                ),

            Size =
                UDim2.new(
                    1,
                    -26,
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
                    -11,
                    0,
                    10
                ),

            Size =
                UDim2.fromOffset(
                    41,
                    21
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

Corner(ToggleButton, 20)

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
                    15,
                    15
                ),

            BackgroundColor3 =
                Theme.TextMuted,

            BorderSizePixel =
                0,
        }
    )

ToggleKnob.Parent =
    ToggleButton

Corner(ToggleKnob, 20)

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
                    18,
                    1,
                    -10
                ),

            Size =
                UDim2.new(
                    1,
                    -36,
                    0,
                    15
                ),

            BackgroundTransparency =
                1,

            Text =
                "XenOS • v0.4.1",

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
-- Status function
------------------------------------------------------------

local function SetStatus(text)

    if
        FarmStatus
        and FarmStatus.Parent
    then

        FarmStatus.Text =
            "Status: "
            .. tostring(text)
    end
end

------------------------------------------------------------
-- Chest naming
------------------------------------------------------------

local function IsChest(instance)

    if not instance then
        return false
    end

    return
        instance.Name:match(
            "^Chest%d+$"
        )
        ~= nil
end

------------------------------------------------------------
-- IMPORTANT:
-- Determine whether chest can still be collected
------------------------------------------------------------

local function ChestAvailable(chest)

    if not chest then
        return false
    end

    if not chest.Parent then
        return false
    end

    if ConsumedChests[chest] then
        return false
    end

    --------------------------------------------------------
    -- User specifically said collection deletes the chest's
    -- children.
    --
    -- Therefore an empty Chest# should NEVER be targeted.
    --------------------------------------------------------

    if #chest:GetChildren() == 0 then
        return false
    end

    return true
end

------------------------------------------------------------
-- Get chest BasePart
------------------------------------------------------------

local function GetChestPart(chest)

    if not chest then
        return nil
    end

    --------------------------------------------------------
    -- Your chest objects are parts named Chest<number>
    ------------------------------------------------------------

    if chest:IsA("BasePart") then
        return chest
    end

    --------------------------------------------------------
    -- Safety for alternate structures
    ------------------------------------------------------------

    if
        chest:IsA("Model")
        and chest.PrimaryPart
    then

        return chest.PrimaryPart
    end

    return chest:FindFirstChildWhichIsA(
        "BasePart",
        true
    )
end

------------------------------------------------------------
-- Scan map
------------------------------------------------------------

local function GetAllChests()

    local chests = {}

    local Map =
        Workspace:FindFirstChild(
            "Map"
        )

    if not Map then
        return chests
    end

    --------------------------------------------------------
    -- Workspace
    -- └── Map
    --     └── <Model>
    --         └── Chests
    ------------------------------------------------------------

    for _, model
        in ipairs(Map:GetChildren())
    do

        local folder =
            model:FindFirstChild(
                "Chests"
            )

        if folder then

            for _, chest
                in ipairs(folder:GetChildren())
            do

                if
                    IsChest(chest)
                    and ChestAvailable(chest)
                    and GetChestPart(chest)
                then

                    table.insert(
                        chests,
                        chest
                    )
                end
            end
        end
    end

    return chests
end

------------------------------------------------------------
-- Find nearest available chest
------------------------------------------------------------

local function GetNearestChest()

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
        in ipairs(GetAllChests())
    do

        local part =
            GetChestPart(chest)

        if part then

            local distance =
                (
                    root.Position
                    - part.Position
                ).Magnitude

            if distance < nearestDistance then

                nearestDistance =
                    distance

                nearest =
                    chest
            end
        end
    end

    return nearest
end

------------------------------------------------------------
-- Tween cancellation
------------------------------------------------------------

local function CancelTween(tween)

    local tweenToCancel =
        tween
        or CurrentTween

    if not tweenToCancel then
        return
    end

    pcall(function()
        tweenToCancel:Cancel()
    end)

    if CurrentTween == tweenToCancel then
        CurrentTween =
            nil
    end
end

------------------------------------------------------------
-- Move to selected chest
------------------------------------------------------------

local function MoveToChest(
    chest,
    generation
)

    if
        not AutoFarmChest
        or Destroyed
        or generation ~= FarmGeneration
    then

        return
    end

    if not ChestAvailable(chest) then
        return
    end

    local root =
        GetRootPart()

    local chestPart =
        GetChestPart(chest)

    if
        not root
        or not chestPart
    then

        return
    end

    CurrentChest =
        chest

    --------------------------------------------------------
    -- Snapshot the contents that made this chest valid.
    --------------------------------------------------------

    local trackedContents =
        {}

    for _, descendant
        in ipairs(chest:GetDescendants())
    do

        trackedContents[descendant] =
            true
    end

    if next(trackedContents) == nil then

        ConsumedChests[chest] =
            true

        CurrentChest =
            nil

        return
    end

    local targetFinished =
        false

    local targetTween =
        nil

    local targetConnections =
        {}

    local function DisconnectTargetConnections()

        for _, connection
            in ipairs(targetConnections)
        do

            pcall(function()

                if connection.Connected then
                    connection:Disconnect()
                end
            end)
        end

        table.clear(
            targetConnections
        )
    end

    local function FinishTarget(consumed)

        if targetFinished then
            return
        end

        targetFinished =
            true

        if consumed then

            ConsumedChests[chest] =
                true

            SetStatus(
                chest.Name
                .. " collected"
            )
        end

        CancelTween(
            targetTween
        )
    end

    local cancelThisTarget =
        function()

            FinishTarget(
                false
            )
        end

    CurrentTargetCancel =
        cancelThisTarget

    --------------------------------------------------------
    -- Stop this target immediately when one of the contents
    -- that existed at selection time begins leaving it.
    --------------------------------------------------------

    table.insert(
        targetConnections,

        chest.DescendantRemoving:Connect(
            function(descendant)

                if
                    targetFinished
                    or not trackedContents[descendant]
                then

                    return
                end

                FinishTarget(
                    true
                )
            end
        )
    )

    --------------------------------------------------------
    -- Also catch entire chest deletion
    --------------------------------------------------------

    table.insert(
        targetConnections,

        chest.AncestryChanged:Connect(
            function()

                if targetFinished then
                    return
                end

                if not chest.Parent then

                    FinishTarget(
                        true
                    )
                end
            end
        )
    )

    --------------------------------------------------------
    -- Close the small race between the snapshot and listeners.
    -- Every tracked item must still be inside this chest.
    --------------------------------------------------------

    for content
        in pairs(trackedContents)
    do

        if
            not content.Parent
            or not content:IsDescendantOf(chest)
        then

            FinishTarget(
                true
            )

            break
        end
    end

    --------------------------------------------------------
    -- Tween
    --------------------------------------------------------

    if not targetFinished then

        local destination =
            chestPart.CFrame
            + Config.ChestOffset

        local distance =
            (
                root.Position
                - destination.Position
            ).Magnitude

        local duration =
            distance
            / Config.TweenSpeed

        duration =
            math.max(
                duration,
                0.03
            )

        SetStatus(
            "Moving to "
            .. chest.Name
        )

        targetTween =
            TweenService:Create(
                root,

                TweenInfo.new(
                    duration,
                    Enum.EasingStyle.Linear,
                    Enum.EasingDirection.Out
                ),

                {
                    CFrame =
                        destination
                }
            )

        CurrentTween =
            targetTween

        targetTween:Play()

        --------------------------------------------------------
        -- Wait while tweening.
        --
        -- DescendantRemoving can interrupt this immediately.
        --------------------------------------------------------

        while
            AutoFarmChest
            and not Destroyed
            and generation == FarmGeneration
            and not targetFinished
        do

            ----------------------------------------------------
            -- Fallback for executors that miss an instance
            -- signal: detect a tracked item that has left.
            ----------------------------------------------------

            if not chest.Parent then

                FinishTarget(
                    true
                )

            else

                for content
                    in pairs(trackedContents)
                do

                    if
                        not content.Parent
                        or not content:IsDescendantOf(chest)
                    then

                        FinishTarget(
                            true
                        )

                        break
                    end
                end
            end

            ----------------------------------------------------
            -- Tween reached chest, but we haven't collected it
            -- yet. Stay targeted on this chest.
            ----------------------------------------------------

            if
                targetTween
                and targetTween.PlaybackState
                    == Enum.PlaybackState.Completed
            then

                if CurrentTween == targetTween then
                    CurrentTween =
                        nil
                end

                targetTween =
                    nil

                SetStatus(
                    "Waiting on "
                    .. chest.Name
                )

                break
            end

            task.wait(
                0.03
            )
        end
    end

    ------------------------------------------------------------
    -- If we arrived but chest children haven't disappeared yet,
    -- wait for the collection event.
    ------------------------------------------------------------

    while
        AutoFarmChest
        and not Destroyed
        and generation == FarmGeneration
        and not targetFinished
    do

        if not chest.Parent then

            FinishTarget(
                true
            )

        else

            for content
                in pairs(trackedContents)
            do

                if
                    not content.Parent
                    or not content:IsDescendantOf(chest)
                then

                    FinishTarget(
                        true
                    )

                    break
                end
            end
        end

        task.wait(
            0.03
        )
    end

    ------------------------------------------------------------
    -- Cleanup per-chest listeners
    ------------------------------------------------------------

    DisconnectTargetConnections()

    CancelTween(
        targetTween
    )

    if CurrentTargetCancel == cancelThisTarget then
        CurrentTargetCancel =
            nil
    end

    CurrentChest =
        nil
end

------------------------------------------------------------
-- Main farm loop
------------------------------------------------------------

local function StartChestFarm()

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
            -- Character check
            ------------------------------------------------

            if not GetRootPart() then

                SetStatus(
                    "Waiting for character"
                )

                task.wait(
                    0.5
                )

                continue
            end

            ------------------------------------------------
            -- Find next chest
            ------------------------------------------------

            local chest =
                GetNearestChest()

            if not chest then

                SetStatus(
                    "Searching for chest"
                )

                task.wait(
                    Config.NoChestDelay
                )

                continue
            end

            ------------------------------------------------
            -- Move to it.
            --
            -- This function does NOT return until that chest
            -- has been collected or Auto Farm is stopped.
            ------------------------------------------------

            MoveToChest(
                chest,
                generation
            )

            ------------------------------------------------
            -- Immediately rescan for another chest
            ------------------------------------------------

            if
                AutoFarmChest
                and generation == FarmGeneration
            then

                SetStatus(
                    "Finding next chest"
                )

                task.wait(
                    Config.SearchDelay
                )
            end
        end
    end)
end

------------------------------------------------------------
-- Stop farm
------------------------------------------------------------

local function StopChestFarm()

    AutoFarmChest =
        false

    FarmGeneration += 1

    if CurrentTargetCancel then

        CurrentTargetCancel()

        CurrentTargetCancel =
            nil
    end

    CancelTween()

    CurrentChest =
        nil

    SetStatus(
        "Disabled"
    )
end

------------------------------------------------------------
-- Toggle visuals
------------------------------------------------------------

local function UpdateToggle()

    if AutoFarmChest then

        TweenService:Create(
            ToggleButton,

            TweenInfo.new(
                0.15
            ),

            {
                BackgroundColor3 =
                    Theme.Ocean
            }
        ):Play()

        TweenService:Create(
            ToggleKnob,

            TweenInfo.new(
                0.15
            ),

            {
                Position =
                    UDim2.new(
                        1,
                        -18,
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

            TweenInfo.new(
                0.15
            ),

            {
                BackgroundColor3 =
                    Theme.Surface
            }
        ):Play()

        TweenService:Create(
            ToggleKnob,

            TweenInfo.new(
                0.15
            ),

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
-- Toggle click
------------------------------------------------------------

Connect(
    ToggleButton.MouseButton1Click,

    function()

        AutoFarmChest =
            not AutoFarmChest

        UpdateToggle()

        if AutoFarmChest then

            SetStatus(
                "Starting"
            )

            StartChestFarm()

        else

            StopChestFarm()
        end
    end
)

------------------------------------------------------------
-- Draggable UI
------------------------------------------------------------

local dragging =
    false

local dragInput =
    nil

local dragStart =
    nil

local startPosition =
    nil

Connect(
    Topbar.InputBegan,

    function(input)

        if
            input.UserInputType
                == Enum.UserInputType.MouseButton1

            or input.UserInputType
                == Enum.UserInputType.Touch
        then

            dragging =
                true

            dragStart =
                input.Position

            startPosition =
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

            or input.UserInputType
                == Enum.UserInputType.Touch
        then

            dragInput =
                input
        end
    end
)

Connect(
    UserInputService.InputChanged,

    function(input)

        if
            dragging
            and input == dragInput
        then

            local delta =
                input.Position
                - dragStart

            Main.Position =
                UDim2.new(

                    startPosition.X.Scale,
                    startPosition.X.Offset
                        + delta.X,

                    startPosition.Y.Scale,
                    startPosition.Y.Offset
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

            or input.UserInputType
                == Enum.UserInputType.Touch
        then

            dragging =
                false
        end
    end
)

------------------------------------------------------------
-- UI visibility
------------------------------------------------------------

local Visible =
    true

local function SetVisible(state)

    Visible =
        state

    ScreenGui.Enabled =
        state
end

------------------------------------------------------------
-- Right Shift
------------------------------------------------------------

Connect(
    UserInputService.InputBegan,

    function(input)

        if
            input.KeyCode
                == Enum.KeyCode.RightShift
        then

            SetVisible(
                not Visible
            )
        end
    end
)

------------------------------------------------------------
-- Close hides UI
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

            TweenInfo.new(
                0.12
            ),

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

            TweenInfo.new(
                0.12
            ),

            {
                BackgroundColor3 =
                    Theme.Red
            }
        ):Play()
    end
)

------------------------------------------------------------
-- Public API
------------------------------------------------------------

local UI = {}

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
-- Toggle UI
------------------------------------------------------------

function UI:Toggle()

    SetVisible(
        not Visible
    )
end

------------------------------------------------------------
-- Farm control
------------------------------------------------------------

function UI:SetAutoFarmChest(state)

    state =
        state == true

    if state == AutoFarmChest then
        return
    end

    AutoFarmChest =
        state

    UpdateToggle()

    if state then

        StartChestFarm()

    else

        StopChestFarm()
    end
end

------------------------------------------------------------
-- Get target
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
    -- Stop farming first
    --------------------------------------------------------

    AutoFarmChest =
        false

    FarmGeneration += 1

    if CurrentTargetCancel then

        CurrentTargetCancel()

        CurrentTargetCancel =
            nil
    end

    CancelTween()

    --------------------------------------------------------
    -- Disconnect global UI connections
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
    -- Destroy GUI
    --------------------------------------------------------

    if ScreenGui then

        pcall(function()
            ScreenGui:Destroy()
        end)
    end

    --------------------------------------------------------
    -- Remove current reference
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
-- Register
------------------------------------------------------------

ENV.XenOS.BloxFruitsUI =
    UI

------------------------------------------------------------
-- Initial state
------------------------------------------------------------

UpdateToggle()

SetStatus(
    "Disabled"
)

------------------------------------------------------------
-- Loaded
------------------------------------------------------------

print(
    "[XenOS/BloxFruits]",
    "v0.4.1 loaded |",
    CurrentSea,
    "| Auto Farm Chest ready |",
    "RightShift = UI"
)

return UI
