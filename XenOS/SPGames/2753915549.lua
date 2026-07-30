--[[
    ============================================================
                    XenOS - Blox Fruits
    ============================================================

    UI Foundation v0.2

    Controls:
        Right Shift = Show / Hide XenOS

    Re-executing:
        Automatically destroys the previous XenOS UI
        and disconnects its old event connections.
]]

------------------------------------------------------------
-- Services
------------------------------------------------------------

local Players =
    game:GetService("Players")

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

if not Player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    Player = Players.LocalPlayer
end

------------------------------------------------------------
-- Global XenOS state
------------------------------------------------------------

local ENV =
    (getgenv and getgenv())
    or _G

ENV.XenOS =
    ENV.XenOS or {}

------------------------------------------------------------
-- DELETE PREVIOUS VERSION
------------------------------------------------------------

-- This is important.
--
-- Merely destroying the old ScreenGui would NOT necessarily
-- remove UserInputService connections from an older execution.
--
-- So every XenOS game module stores its cleanup function here.

if ENV.XenOS.BloxFruitsUI then

    local old =
        ENV.XenOS.BloxFruitsUI

    if type(old.Destroy) == "function" then
        pcall(function()
            old:Destroy()
        end)
    end

    ENV.XenOS.BloxFruitsUI =
        nil
end

------------------------------------------------------------
-- Connection manager
------------------------------------------------------------

local Connections = {}

local function connect(signal, callback)

    local connection =
        signal:Connect(callback)

    table.insert(
        Connections,
        connection
    )

    return connection
end

------------------------------------------------------------
-- Determine Sea
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
        Color3.fromRGB(13, 23, 34),

    Surface =
        Color3.fromRGB(18, 32, 46),

    SurfaceRaised =
        Color3.fromRGB(24, 43, 60),

    SurfaceHover =
        Color3.fromRGB(32, 55, 75),

    Gold =
        Color3.fromRGB(224, 179, 78),

    GoldSoft =
        Color3.fromRGB(165, 126, 56),

    Ocean =
        Color3.fromRGB(46, 105, 155),

    OceanBright =
        Color3.fromRGB(69, 137, 191),

    Red =
        Color3.fromRGB(171, 57, 53),

    RedHover =
        Color3.fromRGB(204, 70, 64),

    Green =
        Color3.fromRGB(83, 184, 116),

    Text =
        Color3.fromRGB(243, 239, 226),

    TextMuted =
        Color3.fromRGB(145, 160, 172),

    TextDark =
        Color3.fromRGB(20, 23, 27),
}

------------------------------------------------------------
-- Utility
------------------------------------------------------------

local function new(className, properties)

    local object =
        Instance.new(className)

    for property, value in pairs(properties or {}) do
        object[property] = value
    end

    return object
end

local function corner(object, radius)

    local uiCorner =
        Instance.new("UICorner")

    uiCorner.CornerRadius =
        UDim.new(0, radius or 7)

    uiCorner.Parent =
        object

    return uiCorner
end

local function stroke(
    object,
    color,
    thickness,
    transparency
)

    local uiStroke =
        Instance.new("UIStroke")

    uiStroke.Color =
        color or Theme.GoldSoft

    uiStroke.Thickness =
        thickness or 1

    uiStroke.Transparency =
        transparency or 0

    uiStroke.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    uiStroke.Parent =
        object

    return uiStroke
end

------------------------------------------------------------
-- Resolve UI parent
------------------------------------------------------------

local function resolveUIParent()

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
    resolveUIParent()

------------------------------------------------------------
-- HARD DELETE DUPLICATE GUIs
------------------------------------------------------------

-- Handles older XenOS versions that weren't stored in
-- ENV.XenOS.BloxFruitsUI.

for _, child in ipairs(
    UIParent:GetChildren()
) do

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
    new(
        "ScreenGui",
        {
            Name =
                "XenOS_BloxFruits",

            ResetOnSpawn =
                false,

            IgnoreGuiInset =
                false,

            ZIndexBehavior =
                Enum.ZIndexBehavior.Sibling,

            DisplayOrder =
                1000000,

            Enabled =
                true,
        }
    )

ScreenGui.Parent =
    UIParent

------------------------------------------------------------
-- GUI protection if available
------------------------------------------------------------

pcall(function()

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
    end
end)

------------------------------------------------------------
-- Main window
------------------------------------------------------------

local Main =
    new(
        "Frame",
        {
            Name =
                "Main",

            AnchorPoint =
                Vector2.new(0.5, 0.5),

            Position =
                UDim2.fromScale(0.5, 0.5),

            Size =
                UDim2.fromOffset(540, 330),

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

corner(Main, 10)

stroke(
    Main,
    Theme.GoldSoft,
    1,
    0.25
)

------------------------------------------------------------
-- Top accent
------------------------------------------------------------

local Accent =
    new(
        "Frame",
        {
            Size =
                UDim2.new(1, 0, 0, 3),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

Accent.Parent =
    Main

local AccentGradient =
    new(
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
    new(
        "Frame",
        {
            Name =
                "Topbar",

            Position =
                UDim2.fromOffset(0, 3),

            Size =
                UDim2.new(1, 0, 0, 49),

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
-- Small logo
------------------------------------------------------------

local Logo =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(13, 10),

            Size =
                UDim2.fromOffset(29, 29),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

Logo.Parent =
    Topbar

corner(Logo, 7)

local LogoText =
    new(
        "TextLabel",
        {
            Size =
                UDim2.fromScale(1, 1),

            BackgroundTransparency =
                1,

            Text =
                "X",

            TextColor3 =
                Theme.TextDark,

            TextSize =
                18,

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
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(53, 7),

            Size =
                UDim2.new(1, -115, 0, 20),

            BackgroundTransparency =
                1,

            Text =
                "XenOS",

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

Title.Parent =
    Topbar

local Subtitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(53, 26),

            Size =
                UDim2.new(1, -115, 0, 14),

            BackgroundTransparency =
                1,

            Text =
                "BLOX FRUITS  •  "
                .. CurrentSea,

            TextColor3 =
                Theme.Gold,

            TextSize =
                9,

            Font =
                Enum.Font.GothamMedium,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Subtitle.Parent =
    Topbar

------------------------------------------------------------
-- Close / Hide button
------------------------------------------------------------

local Close =
    new(
        "TextButton",
        {
            AnchorPoint =
                Vector2.new(1, 0.5),

            Position =
                UDim2.new(1, -12, 0.5, 0),

            Size =
                UDim2.fromOffset(28, 28),

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

corner(Close, 7)

------------------------------------------------------------
-- Body
------------------------------------------------------------

local Body =
    new(
        "Frame",
        {
            Name =
                "Body",

            Position =
                UDim2.fromOffset(0, 52),

            Size =
                UDim2.new(1, 0, 1, -52),

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
    132

local Sidebar =
    new(
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

------------------------------------------------------------
-- Sidebar divider
------------------------------------------------------------

local Divider =
    new(
        "Frame",
        {
            AnchorPoint =
                Vector2.new(1, 0),

            Position =
                UDim2.new(1, 0, 0, 0),

            Size =
                UDim2.new(0, 1, 1, 0),

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
-- Navigation title
------------------------------------------------------------

local NavTitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(13, 14),

            Size =
                UDim2.new(1, -26, 0, 14),

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

NavTitle.Parent =
    Sidebar

------------------------------------------------------------
-- Home tab placeholder
------------------------------------------------------------

local Home =
    new(
        "TextButton",
        {
            Position =
                UDim2.fromOffset(9, 37),

            Size =
                UDim2.new(1, -18, 0, 34),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,

            AutoButtonColor =
                false,

            Text =
                "",
        }
    )

Home.Parent =
    Sidebar

corner(Home, 7)

local HomeAccent =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(0, 7),

            Size =
                UDim2.fromOffset(3, 20),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

HomeAccent.Parent =
    Home

corner(HomeAccent, 3)

local HomeLabel =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(14, 0),

            Size =
                UDim2.new(1, -14, 1, 0),

            BackgroundTransparency =
                1,

            Text =
                "Home",

            TextColor3 =
                Theme.Text,

            TextSize =
                11,

            Font =
                Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

HomeLabel.Parent =
    Home

------------------------------------------------------------
-- Key hint
------------------------------------------------------------

local KeyHint =
    new(
        "TextLabel",
        {
            AnchorPoint =
                Vector2.new(0, 1),

            Position =
                UDim2.new(0, 13, 1, -12),

            Size =
                UDim2.new(1, -26, 0, 30),

            BackgroundTransparency =
                1,

            Text =
                "RIGHT SHIFT\nToggle XenOS",

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
    new(
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
-- Header
------------------------------------------------------------

local Welcome =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(20, 19),

            Size =
                UDim2.new(1, -40, 0, 24),

            BackgroundTransparency =
                1,

            Text =
                "Welcome aboard.",

            TextColor3 =
                Theme.Text,

            TextSize =
                18,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

Welcome.Parent =
    Content

local WelcomeSub =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(21, 45),

            Size =
                UDim2.new(1, -42, 0, 18),

            BackgroundTransparency =
                1,

            Text =
                CurrentSea
                .. " connected successfully.",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                10,

            Font =
                Enum.Font.Gotham,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

WelcomeSub.Parent =
    Content

------------------------------------------------------------
-- Compact status card
------------------------------------------------------------

local StatusCard =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(20, 80),

            Size =
                UDim2.new(1, -40, 0, 91),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,
        }
    )

StatusCard.Parent =
    Content

corner(StatusCard, 8)

stroke(
    StatusCard,
    Theme.Ocean,
    1,
    0.55
)

------------------------------------------------------------
-- Status side accent
------------------------------------------------------------

local StatusAccent =
    new(
        "Frame",
        {
            Size =
                UDim2.new(0, 4, 1, 0),

            BackgroundColor3 =
                Theme.OceanBright,

            BorderSizePixel =
                0,
        }
    )

StatusAccent.Parent =
    StatusCard

------------------------------------------------------------
-- Status dot
------------------------------------------------------------

local StatusDot =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(17, 17),

            Size =
                UDim2.fromOffset(8, 8),

            BackgroundColor3 =
                Theme.Green,

            BorderSizePixel =
                0,
        }
    )

StatusDot.Parent =
    StatusCard

corner(StatusDot, 8)

------------------------------------------------------------
-- Status title
------------------------------------------------------------

local StatusTitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(34, 10),

            Size =
                UDim2.new(1, -45, 0, 22),

            BackgroundTransparency =
                1,

            Text =
                "Game module ready",

            TextColor3 =
                Theme.Text,

            TextSize =
                13,

            Font =
                Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

StatusTitle.Parent =
    StatusCard

------------------------------------------------------------
-- Status description
------------------------------------------------------------

local StatusText =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(17, 38),

            Size =
                UDim2.new(1, -34, 0, 38),

            BackgroundTransparency =
                1,

            Text =
                "XenOS is ready. Features will appear here.",

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

StatusText.Parent =
    StatusCard

------------------------------------------------------------
-- Footer status
------------------------------------------------------------

local Footer =
    new(
        "TextLabel",
        {
            AnchorPoint =
                Vector2.new(0, 1),

            Position =
                UDim2.new(0, 21, 1, -13),

            Size =
                UDim2.new(1, -42, 0, 17),

            BackgroundTransparency =
                1,

            Text =
                "XenOS v0.2  •  "
                .. tostring(game.PlaceId),

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
-- Draggable window
------------------------------------------------------------

local dragging =
    false

local dragInput

local dragStart

local startPosition

connect(
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

            local endConnection

            endConnection =
                input.Changed:Connect(function()

                    if
                        input.UserInputState
                            == Enum.UserInputState.End
                    then

                        dragging =
                            false

                        if endConnection then
                            endConnection:Disconnect()
                        end
                    end
                end)
        end
    end
)

connect(
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

connect(
    UserInputService.InputChanged,

    function(input)

        if
            input == dragInput
            and dragging
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

------------------------------------------------------------
-- Toggle state
------------------------------------------------------------

local visible =
    true

local function SetVisible(state)

    visible =
        state

    ScreenGui.Enabled =
        state
end

local function Toggle()

    SetVisible(
        not visible
    )
end

------------------------------------------------------------
-- RIGHT SHIFT TOGGLE
------------------------------------------------------------

connect(
    UserInputService.InputBegan,

    function(input)

        if
            input.KeyCode
                == Enum.KeyCode.RightShift
        then

            Toggle()
        end
    end
)

------------------------------------------------------------
-- Close button = hide
------------------------------------------------------------

connect(
    Close.MouseButton1Click,

    function()

        SetVisible(false)
    end
)

------------------------------------------------------------
-- Close hover
------------------------------------------------------------

connect(
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

connect(
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
-- Public UI API
------------------------------------------------------------

local UI = {}

UI.ScreenGui =
    ScreenGui

UI.Main =
    Main

UI.Topbar =
    Topbar

UI.Sidebar =
    Sidebar

UI.Content =
    Content

UI.Theme =
    Theme

UI.Sea =
    CurrentSea

------------------------------------------------------------
-- Toggle
------------------------------------------------------------

function UI:Toggle()

    Toggle()
end

------------------------------------------------------------
-- Show
------------------------------------------------------------

function UI:Show()

    SetVisible(true)
end

------------------------------------------------------------
-- Hide
------------------------------------------------------------

function UI:Hide()

    SetVisible(false)
end

------------------------------------------------------------
-- IsVisible
------------------------------------------------------------

function UI:IsVisible()

    return visible
end

------------------------------------------------------------
-- Status update
------------------------------------------------------------

function UI:SetStatus(
    title,
    description,
    color
)

    if title ~= nil then
        StatusTitle.Text =
            tostring(title)
    end

    if description ~= nil then
        StatusText.Text =
            tostring(description)
    end

    if color ~= nil then
        StatusDot.BackgroundColor3 =
            color
    end
end

------------------------------------------------------------
-- Destroy
------------------------------------------------------------

function UI:Destroy()

    --------------------------------------------------------
    -- Disconnect EVERY event connection created by
    -- this execution.
    --------------------------------------------------------

    for _, connection in ipairs(
        Connections
    ) do

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
    -- Remove global reference
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
-- Register current instance
------------------------------------------------------------

ENV.XenOS.BloxFruitsUI =
    UI

------------------------------------------------------------
-- Loaded
------------------------------------------------------------

print(
    "[XenOS/BloxFruits]",
    "Compact UI loaded |",
    CurrentSea,
    "| RightShift = Toggle"
)

return UI
