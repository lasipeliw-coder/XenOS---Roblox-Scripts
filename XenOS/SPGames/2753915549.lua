--[[
    ============================================================
                  XenOS - Blox Fruits
    ============================================================

    Place:
        Blox Fruits

    Primary PlaceId:
        2753915549

    Shared with:
        4442272183 - Second Sea
        7449423635 - Third Sea

    Current stage:
        UI Foundation
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
-- Determine Sea
------------------------------------------------------------

local SEA_NAMES = {

    [2753915549] = "FIRST SEA",

    [4442272183] = "SECOND SEA",

    [7449423635] = "THIRD SEA",
}

local CurrentSea =
    SEA_NAMES[game.PlaceId]
    or "BLOX FRUITS"

------------------------------------------------------------
-- Theme
------------------------------------------------------------

local Theme = {

    -- Main ocean tones

    Background =
        Color3.fromRGB(14, 25, 38),

    Surface =
        Color3.fromRGB(20, 36, 52),

    SurfaceRaised =
        Color3.fromRGB(27, 47, 67),

    SurfaceHover =
        Color3.fromRGB(36, 59, 80),

    --------------------------------------------------------
    -- Pirate / parchment accents
    --------------------------------------------------------

    Gold =
        Color3.fromRGB(222, 178, 80),

    GoldSoft =
        Color3.fromRGB(176, 137, 63),

    Cream =
        Color3.fromRGB(239, 228, 198),

    --------------------------------------------------------
    -- Blox Fruits inspired ocean blue
    --------------------------------------------------------

    Ocean =
        Color3.fromRGB(48, 111, 165),

    OceanBright =
        Color3.fromRGB(75, 145, 198),

    --------------------------------------------------------
    -- Pirate red accent
    --------------------------------------------------------

    Red =
        Color3.fromRGB(178, 61, 55),

    RedHover =
        Color3.fromRGB(211, 73, 65),

    --------------------------------------------------------
    -- Text
    --------------------------------------------------------

    Text =
        Color3.fromRGB(244, 240, 227),

    TextMuted =
        Color3.fromRGB(157, 170, 181),

    TextDark =
        Color3.fromRGB(20, 25, 30),
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

    local c =
        Instance.new("UICorner")

    c.CornerRadius =
        UDim.new(0, radius or 8)

    c.Parent =
        object

    return c
end

local function stroke(
    object,
    color,
    thickness,
    transparency
)

    local s =
        Instance.new("UIStroke")

    s.Color =
        color or Theme.GoldSoft

    s.Thickness =
        thickness or 1

    s.Transparency =
        transparency or 0

    s.ApplyStrokeMode =
        Enum.ApplyStrokeMode.Border

    s.Parent =
        object

    return s
end

------------------------------------------------------------
-- Resolve UI parent
------------------------------------------------------------

local function resolveUIParent()

    --------------------------------------------------------
    -- Preferred executor UI container
    --------------------------------------------------------

    if type(gethui) == "function" then

        local success, result =
            pcall(gethui)

        if success and typeof(result) == "Instance" then
            return result
        end

    end

    --------------------------------------------------------
    -- CoreGui fallback
    --------------------------------------------------------

    local success, result =
        pcall(function()
            return CoreGui
        end)

    if success and result then
        return result
    end

    --------------------------------------------------------
    -- PlayerGui fallback
    --------------------------------------------------------

    return Player:WaitForChild("PlayerGui")
end

local UIParent =
    resolveUIParent()

------------------------------------------------------------
-- Remove old XenOS UI
------------------------------------------------------------

local old =
    UIParent:FindFirstChild(
        "XenOS_BloxFruits"
    )

if old then
    old:Destroy()
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
        }
    )

ScreenGui.Parent =
    UIParent

------------------------------------------------------------
-- Executor GUI protection
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
                UDim2.fromOffset(680, 430),

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

corner(Main, 12)

local MainStroke =
    stroke(
        Main,
        Theme.GoldSoft,
        1,
        0.15
    )

------------------------------------------------------------
-- Top gold accent
------------------------------------------------------------

local Accent =
    new(
        "Frame",
        {
            Name =
                "Accent",

            Size =
                UDim2.new(1, 0, 0, 4),

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
            Rotation = 0,

            Color =
                ColorSequence.new({

                    ColorSequenceKeypoint.new(
                        0,
                        Theme.GoldSoft
                    ),

                    ColorSequenceKeypoint.new(
                        0.5,
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
                UDim2.fromOffset(0, 4),

            Size =
                UDim2.new(1, 0, 0, 62),

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
-- Logo block
------------------------------------------------------------

local Logo =
    new(
        "Frame",
        {
            Name =
                "Logo",

            Position =
                UDim2.fromOffset(16, 13),

            Size =
                UDim2.fromOffset(38, 38),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

Logo.Parent =
    Topbar

corner(Logo, 9)

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
                24,

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
            Name =
                "Title",

            Position =
                UDim2.fromOffset(67, 10),

            Size =
                UDim2.new(1, -180, 0, 25),

            BackgroundTransparency =
                1,

            Text =
                "XenOS",

            TextColor3 =
                Theme.Text,

            TextSize =
                20,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Font =
                Enum.Font.GothamBold,
        }
    )

Title.Parent =
    Topbar

------------------------------------------------------------
-- Subtitle
------------------------------------------------------------

local Subtitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(67, 33),

            Size =
                UDim2.new(1, -180, 0, 18),

            BackgroundTransparency =
                1,

            Text =
                "BLOX FRUITS  •  "
                .. CurrentSea,

            TextColor3 =
                Theme.Gold,

            TextSize =
                11,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Font =
                Enum.Font.GothamMedium,
        }
    )

Subtitle.Parent =
    Topbar

------------------------------------------------------------
-- Window controls
------------------------------------------------------------

local Minimize =
    new(
        "TextButton",
        {
            Name =
                "Minimize",

            AnchorPoint =
                Vector2.new(1, 0.5),

            Position =
                UDim2.new(1, -58, 0.5, 0),

            Size =
                UDim2.fromOffset(34, 34),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,

            AutoButtonColor =
                false,

            Text =
                "—",

            TextColor3 =
                Theme.Text,

            TextSize =
                17,

            Font =
                Enum.Font.GothamBold,
        }
    )

Minimize.Parent =
    Topbar

corner(Minimize, 7)

local Close =
    new(
        "TextButton",
        {
            Name =
                "Close",

            AnchorPoint =
                Vector2.new(1, 0.5),

            Position =
                UDim2.new(1, -16, 0.5, 0),

            Size =
                UDim2.fromOffset(34, 34),

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
                22,

            Font =
                Enum.Font.GothamBold,
        }
    )

Close.Parent =
    Topbar

corner(Close, 7)

------------------------------------------------------------
-- Window button hover
------------------------------------------------------------

local function buttonHover(
    button,
    normal,
    hover
)

    button.MouseEnter:Connect(function()

        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 = hover
            }
        ):Play()

    end)

    button.MouseLeave:Connect(function()

        TweenService:Create(
            button,
            TweenInfo.new(0.12),
            {
                BackgroundColor3 = normal
            }
        ):Play()

    end)

end

buttonHover(
    Minimize,
    Theme.SurfaceRaised,
    Theme.SurfaceHover
)

buttonHover(
    Close,
    Theme.Red,
    Theme.RedHover
)

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
                UDim2.fromOffset(0, 66),

            Size =
                UDim2.new(1, 0, 1, -66),

            BackgroundTransparency =
                1,
        }
    )

Body.Parent =
    Main

------------------------------------------------------------
-- Sidebar
------------------------------------------------------------

local Sidebar =
    new(
        "Frame",
        {
            Name =
                "Sidebar",

            Position =
                UDim2.fromOffset(0, 0),

            Size =
                UDim2.new(0, 176, 1, 0),

            BackgroundColor3 =
                Theme.Surface,

            BorderSizePixel =
                0,
        }
    )

Sidebar.Parent =
    Body

------------------------------------------------------------
-- Sidebar separator
------------------------------------------------------------

local Separator =
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
                0.65,

            BorderSizePixel =
                0,
        }
    )

Separator.Parent =
    Sidebar

------------------------------------------------------------
-- Sidebar heading
------------------------------------------------------------

local MenuTitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(17, 20),

            Size =
                UDim2.new(1, -34, 0, 20),

            BackgroundTransparency =
                1,

            Text =
                "NAVIGATION",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                10,

            Font =
                Enum.Font.GothamBold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

MenuTitle.Parent =
    Sidebar

------------------------------------------------------------
-- Home placeholder
------------------------------------------------------------

local HomeButton =
    new(
        "TextButton",
        {
            Name =
                "Home",

            Position =
                UDim2.fromOffset(12, 51),

            Size =
                UDim2.new(1, -24, 0, 42),

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

HomeButton.Parent =
    Sidebar

corner(HomeButton, 8)

local HomeAccent =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(0, 8),

            Size =
                UDim2.fromOffset(3, 26),

            BackgroundColor3 =
                Theme.Gold,

            BorderSizePixel =
                0,
        }
    )

HomeAccent.Parent =
    HomeButton

corner(HomeAccent, 3)

local HomeText =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(17, 0),

            Size =
                UDim2.new(1, -17, 1, 0),

            BackgroundTransparency =
                1,

            Text =
                "Home",

            TextColor3 =
                Theme.Text,

            TextSize =
                13,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Font =
                Enum.Font.GothamSemibold,
        }
    )

HomeText.Parent =
    HomeButton

------------------------------------------------------------
-- Future tabs placeholder
------------------------------------------------------------

local ComingSoon =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(17, 111),

            Size =
                UDim2.new(1, -34, 0, 50),

            BackgroundTransparency =
                1,

            Text =
                "More sections will appear\nas features are added.",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                10,

            TextWrapped =
                true,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            TextYAlignment =
                Enum.TextYAlignment.Top,

            Font =
                Enum.Font.Gotham,
        }
    )

ComingSoon.Parent =
    Sidebar

------------------------------------------------------------
-- Sidebar footer
------------------------------------------------------------

local Version =
    new(
        "TextLabel",
        {
            AnchorPoint =
                Vector2.new(0, 1),

            Position =
                UDim2.new(0, 17, 1, -14),

            Size =
                UDim2.new(1, -34, 0, 20),

            BackgroundTransparency =
                1,

            Text =
                "XenOS  •  v0.1.0",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                9,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            Font =
                Enum.Font.GothamMedium,
        }
    )

Version.Parent =
    Sidebar

------------------------------------------------------------
-- Content area
------------------------------------------------------------

local Content =
    new(
        "Frame",
        {
            Name =
                "Content",

            Position =
                UDim2.fromOffset(176, 0),

            Size =
                UDim2.new(1, -176, 1, 0),

            BackgroundTransparency =
                1,
        }
    )

Content.Parent =
    Body

------------------------------------------------------------
-- Welcome
------------------------------------------------------------

local Welcome =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(28, 27),

            Size =
                UDim2.new(1, -56, 0, 32),

            BackgroundTransparency =
                1,

            Text =
                "Welcome aboard.",

            TextColor3 =
                Theme.Text,

            TextSize =
                24,

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
                UDim2.fromOffset(29, 62),

            Size =
                UDim2.new(1, -58, 0, 40),

            BackgroundTransparency =
                1,

            Text =
                "XenOS has successfully connected to "
                .. CurrentSea
                .. ".",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                12,

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

WelcomeSub.Parent =
    Content

------------------------------------------------------------
-- Main status card
------------------------------------------------------------

local StatusCard =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(28, 119),

            Size =
                UDim2.new(1, -56, 0, 128),

            BackgroundColor3 =
                Theme.SurfaceRaised,

            BorderSizePixel =
                0,
        }
    )

StatusCard.Parent =
    Content

corner(StatusCard, 10)

stroke(
    StatusCard,
    Theme.Ocean,
    1,
    0.45
)

------------------------------------------------------------
-- Card accent
------------------------------------------------------------

local CardAccent =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(0, 0),

            Size =
                UDim2.fromOffset(5, 128),

            BackgroundColor3 =
                Theme.OceanBright,

            BorderSizePixel =
                0,
        }
    )

CardAccent.Parent =
    StatusCard

------------------------------------------------------------
-- Status indicator
------------------------------------------------------------

local StatusDot =
    new(
        "Frame",
        {
            Position =
                UDim2.fromOffset(22, 25),

            Size =
                UDim2.fromOffset(10, 10),

            BackgroundColor3 =
                Color3.fromRGB(92, 194, 123),

            BorderSizePixel =
                0,
        }
    )

StatusDot.Parent =
    StatusCard

corner(StatusDot, 10)

------------------------------------------------------------
-- Status title
------------------------------------------------------------

local StatusTitle =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(44, 17),

            Size =
                UDim2.new(1, -60, 0, 27),

            BackgroundTransparency =
                1,

            Text =
                "Game module loaded",

            TextColor3 =
                Theme.Text,

            TextSize =
                16,

            Font =
                Enum.Font.GothamSemibold,

            TextXAlignment =
                Enum.TextXAlignment.Left,
        }
    )

StatusTitle.Parent =
    StatusCard

------------------------------------------------------------
-- Status text
------------------------------------------------------------

local StatusText =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(22, 54),

            Size =
                UDim2.new(1, -44, 0, 51),

            BackgroundTransparency =
                1,

            Text =
                "The XenOS Blox Fruits interface is ready. "
                .. "Feature modules and tabs will be installed "
                .. "here next.",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                11,

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
-- Environment information
------------------------------------------------------------

local Info =
    new(
        "TextLabel",
        {
            Position =
                UDim2.fromOffset(29, 267),

            Size =
                UDim2.new(1, -58, 0, 65),

            BackgroundTransparency =
                1,

            Text =
                "PLACE ID   "
                .. tostring(game.PlaceId)
                .. "\n"
                .. "SEA        "
                .. CurrentSea
                .. "\n"
                .. "STATUS     READY",

            TextColor3 =
                Theme.TextMuted,

            TextSize =
                10,

            Font =
                Enum.Font.Code,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            TextYAlignment =
                Enum.TextYAlignment.Top,
        }
    )

Info.Parent =
    Content

------------------------------------------------------------
-- Draggable window
------------------------------------------------------------

local dragging =
    false

local dragInput =
    nil

local dragStart =
    nil

local startPosition =
    nil

Topbar.InputBegan:Connect(function(input)

    if
        input.UserInputType
            == Enum.UserInputType.MouseButton1

        or

        input.UserInputType
            == Enum.UserInputType.Touch
    then

        dragging = true

        dragStart =
            input.Position

        startPosition =
            Main.Position

        input.Changed:Connect(function()

            if
                input.UserInputState
                    == Enum.UserInputState.End
            then
                dragging = false
            end

        end)

    end

end)

Topbar.InputChanged:Connect(function(input)

    if
        input.UserInputType
            == Enum.UserInputType.MouseMovement

        or

        input.UserInputType
            == Enum.UserInputType.Touch
    then

        dragInput =
            input
    end

end)

UserInputService.InputChanged:Connect(function(input)

    if
        input == dragInput
        and dragging
    then

        local delta =
            input.Position - dragStart

        Main.Position =
            UDim2.new(
                startPosition.X.Scale,
                startPosition.X.Offset + delta.X,

                startPosition.Y.Scale,
                startPosition.Y.Offset + delta.Y
            )

    end

end)

------------------------------------------------------------
-- Minimize
------------------------------------------------------------

local minimized =
    false

local NORMAL_SIZE =
    UDim2.fromOffset(680, 430)

local MINIMIZED_SIZE =
    UDim2.fromOffset(680, 66)

Minimize.MouseButton1Click:Connect(function()

    minimized =
        not minimized

    Body.Visible =
        not minimized

    Minimize.Text =
        minimized and "+"
        or "—"

    TweenService:Create(
        Main,

        TweenInfo.new(
            0.2,
            Enum.EasingStyle.Quart,
            Enum.EasingDirection.Out
        ),

        {
            Size =
                minimized
                and MINIMIZED_SIZE
                or NORMAL_SIZE
        }

    ):Play()

end)

------------------------------------------------------------
-- Close
------------------------------------------------------------

Close.MouseButton1Click:Connect(function()

    ScreenGui:Destroy()

end)

------------------------------------------------------------
-- XenOS Blox Fruits API
------------------------------------------------------------

local UI = {}

UI.ScreenGui =
    ScreenGui

UI.Main =
    Main

UI.Body =
    Body

UI.Sidebar =
    Sidebar

UI.Content =
    Content

UI.Theme =
    Theme

UI.Sea =
    CurrentSea

------------------------------------------------------------
-- SetStatus
------------------------------------------------------------

function UI:SetStatus(
    title,
    description,
    statusColor
)

    if title then
        StatusTitle.Text =
            tostring(title)
    end

    if description then
        StatusText.Text =
            tostring(description)
    end

    if statusColor then
        StatusDot.BackgroundColor3 =
            statusColor
    end

end

------------------------------------------------------------
-- Destroy
------------------------------------------------------------

function UI:Destroy()

    if ScreenGui then
        ScreenGui:Destroy()
    end

end

------------------------------------------------------------
-- Finished
------------------------------------------------------------

print(
    "[XenOS/BloxFruits]",
    "UI loaded for",
    CurrentSea
)

return UI
