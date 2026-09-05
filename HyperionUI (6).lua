--[[
    ╦ ╦╦ ╦╔═╗╔═╗╦═╗╦╔═╗╔╗╔
    ╠═╣╚╦╝╠═╝║╣ ╠╦╝║║ ║║║║
    ╩ ╩ ╩ ╩  ╚═╝╩╚═╩╚═╝╝╚╝
    
    Hyperion UI Library v3.0
    Premium Roblox Interface System
    
    Dark Purple Theme | Modern & Clean
    
    License: MIT
--]]

-- No LPH macro shims here: the UI library is left unobfuscated / light, so it uses
-- zero LPH_* macros. Keeps it clean under Luraph v15's rewritten macro parser.

local MAINTENANCE = false
if MAINTENANCE and not (getgenv and getgenv()._HyperionDev) then
    local cg = (gethui and gethui()) or game:GetService("CoreGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "_HyperionMaintenance"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647
    pcall(function() gui.Parent = cg end)
    if not gui.Parent then gui.Parent = game:GetService("CoreGui") end

    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0.5, 0.5)
    card.Position = UDim2.new(0.5, 0, 0.5, 0)
    card.Size = UDim2.new(0, 380, 0, 150)
    card.BackgroundColor3 = Color3.fromRGB(18, 16, 24)
    card.BorderSizePixel = 0
    card.Parent = gui
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(140, 100, 240)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.15

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -28, 0, 3)
    bar.Position = UDim2.new(0, 14, 0, 16)
    bar.BackgroundColor3 = Color3.fromRGB(155, 115, 255)
    bar.BorderSizePixel = 0
    bar.Parent = card
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 0, 0, 40)
    title.Size = UDim2.new(1, 0, 0, 32)
    title.Text = "Under Maintenance"
    title.TextColor3 = Color3.fromRGB(242, 238, 252)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 23
    title.Parent = card

    local sub = Instance.new("TextLabel")
    sub.BackgroundTransparency = 1
    sub.Position = UDim2.new(0, 18, 0, 80)
    sub.Size = UDim2.new(1, -36, 0, 54)
    sub.Text = "Hyperion is temporarily down for updates.\nPlease check back soon."
    sub.TextColor3 = Color3.fromRGB(172, 162, 192)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 13
    sub.TextWrapped = true
    sub.Parent = card

    pcall(function()
        Instance.new("UIGradient", bar).Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(110, 80, 220)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 140, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 80, 220)),
        })
    end)

    while true do task.wait(1) end
end

----------------------------------------------------------------
-- ENVIRONMENT COMPATIBILITY
----------------------------------------------------------------
cloneref = cloneref or function(i) return i end
clonefunction = clonefunction or function(f) return f end
getgenv = getgenv or getfenv
protect_gui = protect_gui or (syn and syn.protect_gui) or function() end
isfile = isfile or function() return false end
readfile = readfile or function() return "" end
writefile = writefile or function() end
makefolder = makefolder or function() end
isfolder = isfolder or function() return false end
listfiles = listfiles or function() return {} end

-- Capture pristine copies of the filesystem functions at library load time.
-- If a consuming script later installs a buggy hook on `writefile` (e.g. an
-- anti-tamper hook that infinite-recurses), our saves still work because
-- we call these captured clones directly instead of going through the hook.
-- clonefunction is no-op on executors that lack it, but that's fine — in
-- that environment nobody can hook writefile either.
local _rawWritefile  = clonefunction(writefile)
local _rawReadfile   = clonefunction(readfile)
local _rawIsfile     = clonefunction(isfile)
local _rawIsfolder   = clonefunction(isfolder)
local _rawMakefolder = clonefunction(makefolder)
local _rawListfiles  = clonefunction(listfiles)

----------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------
local Players        = cloneref(game:GetService("Players"))
local TweenService   = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService     = cloneref(game:GetService("RunService"))
local TextService    = cloneref(game:GetService("TextService"))
local HttpService    = cloneref(game:GetService("HttpService"))

-- Anti-detection: do NOT use gethui(). Anti-cheats scan the executor's hidden
-- gethui container for exploit UIs. Parenting to the real CoreGui (or PlayerGui)
-- blends in with normal game UI and avoids that scan.
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Anti-detection: ScreenGuis must not carry identifiable names. Anti-cheats
-- scan CoreGui children for known library names, so every ScreenGui this
-- library parents to CoreGui gets a randomized, system-looking name instead.
local _SAFE_GUI_POOL = {
    "CoreEffects","BubbleChat","TopbarPlus","EmoteWheel","SettingsHud",
    "CaptureUi","BackpackHud","ChatWindow","NotificationHud","PlayerHud",
}
local function _SafeGuiName()
    return _SAFE_GUI_POOL[math.random(1, #_SAFE_GUI_POOL)]
        .. tostring(math.random(1000, 9999))
end

----------------------------------------------------------------
-- LIBRARY ROOT
----------------------------------------------------------------
local Hyperion = {}
Hyperion.Windows      = {}
Hyperion.Flags        = {}
Hyperion.FlagCallbacks = {}
Hyperion.Connections  = {}
Hyperion.ThemeListeners = {}  -- functions called whenever SetTheme fires
Hyperion.Keybinds       = {}  -- registry of every AddKeybind entry (for the keybind HUD)
Hyperion.KeybindListeners = {} -- functions called whenever a keybind is added or changed
Hyperion._SearchIndex   = {}  -- registry of every UI element (for feature search)
Hyperion.FlagAPIs       = {}  -- registry of element APIs by flag (for AI actions / scripting)
Hyperion.Version      = "3.0.0"
Hyperion.Unloaded     = false

----------------------------------------------------------------
-- THEME
----------------------------------------------------------------
Hyperion.Theme = {
    -- Accent (Purple defaults)
    Accent          = Color3.fromRGB(140, 80, 220),
    AccentDark      = Color3.fromRGB(100, 50, 180),
    AccentLight     = Color3.fromRGB(170, 110, 255),
    AccentGlow      = Color3.fromRGB(160, 90, 240),
    AccentSub       = Color3.fromRGB(90, 45, 160),

    -- Backgrounds
    Background      = Color3.fromRGB(12, 10, 18),
    Surface         = Color3.fromRGB(18, 15, 26),
    SurfaceLight    = Color3.fromRGB(26, 22, 38),
    SurfaceHover    = Color3.fromRGB(34, 28, 50),
    SurfaceActive   = Color3.fromRGB(40, 33, 58),

    -- Sidebar
    Sidebar         = Color3.fromRGB(14, 12, 22),
    SidebarActive   = Color3.fromRGB(28, 23, 44),

    -- Text
    Text            = Color3.fromRGB(230, 225, 245),
    TextDim         = Color3.fromRGB(145, 135, 170),
    TextMuted       = Color3.fromRGB(80, 72, 105),

    -- Borders
    Border          = Color3.fromRGB(38, 32, 56),
    BorderLight     = Color3.fromRGB(52, 44, 75),

    -- States
    Success         = Color3.fromRGB(75, 210, 115),
    Warning         = Color3.fromRGB(245, 185, 55),
    Error           = Color3.fromRGB(225, 65, 75),
    Info            = Color3.fromRGB(100, 160, 255),

    -- Element specific
    ToggleOff       = Color3.fromRGB(40, 35, 58),
    SliderBg        = Color3.fromRGB(28, 24, 42),
    InputBg         = Color3.fromRGB(16, 13, 24),

    -- Radii
    CornerRadius    = UDim.new(0, 6),
    CornerSmall     = UDim.new(0, 4),
    CornerLarge     = UDim.new(0, 8),

    -- Fonts
    Font            = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Regular,  Enum.FontStyle.Normal),
    FontMedium      = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium,   Enum.FontStyle.Normal),
    FontSemiBold    = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal),
    FontBold        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold,     Enum.FontStyle.Normal),
}
Hyperion._currentThemeName = "Purple"
Hyperion.AnimatedEffects = true

Hyperion.Lucide = {
    Save       = "rbxassetid://10734941499",  -- lucide-save
    Download   = "rbxassetid://10723344270",  -- lucide-download
    Upload     = "rbxassetid://10747366434",  -- lucide-upload
    Trash      = "rbxassetid://10747362393",  -- lucide-trash
    Trash2     = "rbxassetid://10747362241",  -- lucide-trash-2
    Plus       = "rbxassetid://10734924532",  -- lucide-plus
    Minus      = "rbxassetid://10734896206",  -- lucide-minus
    Edit       = "rbxassetid://10734883598",  -- lucide-edit
    Edit2      = "rbxassetid://10723344885",  -- lucide-edit-2
    Pencil     = "rbxassetid://10734919691",  -- lucide-pencil
    RefreshCw  = "rbxassetid://10734933222",  -- lucide-refresh-cw
    RefreshCcw = "rbxassetid://10734933056",  -- lucide-refresh-ccw
    List       = "rbxassetid://10723433811",  -- lucide-list
    ListChecks = "rbxassetid://10734884548",  -- lucide-list-checks
    Check      = "rbxassetid://10709790644",  -- lucide-check
    X          = "rbxassetid://10747384394",  -- lucide-x
    XCircle    = "rbxassetid://10747383819",  -- lucide-x-circle
    Search     = "rbxassetid://10734943674",  -- lucide-search
    Settings   = "rbxassetid://10734950309",  -- lucide-settings
    Folder     = "rbxassetid://10723387563",  -- lucide-folder
    FolderOpen = "rbxassetid://10723386277",  -- lucide-folder-open
    FolderPlus = "rbxassetid://10723386531",  -- lucide-folder-plus
    File       = "rbxassetid://10723374641",  -- lucide-file
    FilePlus   = "rbxassetid://10723365877",  -- lucide-file-plus
    FileText   = "rbxassetid://10723367380",  -- lucide-file-text
    Copy       = "rbxassetid://10709812159",  -- lucide-copy
    Clipboard  = "rbxassetid://10709799288",  -- lucide-clipboard
    Eye        = "rbxassetid://10723346959",  -- lucide-eye
    EyeOff     = "rbxassetid://10723346871",  -- lucide-eye-off
    Lock       = "rbxassetid://10723434711",  -- lucide-lock
    Unlock     = "rbxassetid://10747366027",  -- lucide-unlock
    Info       = "rbxassetid://10723415903",  -- lucide-info
    AlertCircle = "rbxassetid://10709752996", -- lucide-alert-circle
    ChevronDown = "rbxassetid://10709790948", -- lucide-chevron-down
    ChevronUp   = "rbxassetid://10709791523", -- lucide-chevron-up
    Home       = "rbxassetid://10723407389",  -- lucide-home
    Star       = "rbxassetid://10734966248",  -- lucide-star
    Heart      = "rbxassetid://10723406885",  -- lucide-heart
    Gamepad    = "rbxassetid://10723395215",  -- lucide-gamepad-2
    Shield     = "rbxassetid://10734951847",  -- lucide-shield
    Zap        = "rbxassetid://10723345749",  -- lucide-electricity
    Target     = "rbxassetid://10734977012",  -- lucide-target
    Globe      = "rbxassetid://10723404337",  -- lucide-globe
    User       = "rbxassetid://10747373176",  -- lucide-user
    Users      = "rbxassetid://10747373426",  -- lucide-users
    Power      = "rbxassetid://10734930466",  -- lucide-power
    Terminal   = "rbxassetid://10734982144",  -- lucide-terminal
    Code       = "rbxassetid://10709810463",  -- lucide-code
    Bug        = "rbxassetid://10709782845",  -- lucide-bug
    Wrench     = "rbxassetid://10747383470",  -- lucide-wrench
    Sliders    = "rbxassetid://10734963400",  -- lucide-sliders
    Palette    = "rbxassetid://10734910430",  -- lucide-palette
}

-- ── External icon set (Nebula Icon Library) ──────────────────────────
-- Loaded through its published loader, which is how the library is meant to be
-- consumed. Fetched async and pcall-guarded so a blocked HTTP request or a dead
-- URL can never stop the UI from loading; until it resolves (or if it never
-- does) Hyperion:GetIcon just falls back to the built-in Lucide table above.
Hyperion.Icons = nil
Hyperion.IconsReady = false
task.spawn(function()
    pcall(function()
        local src = game:HttpGet("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader")
        local chunk = loadstring(src)
        if chunk then
            local lib = chunk()
            if type(lib) == "table" then
                Hyperion.Icons = lib
                Hyperion.IconsReady = true
            end
        end
    end)
end)

-- Hyperion:GetIcon("check", "Material") -> "rbxassetid://..."
-- `name` may also be a Lucide key ("Shield", "Eye") for the built-in set.
function Hyperion:GetIcon(name, set)
    if type(name) == "number" then return "rbxassetid://" .. tostring(name) end
    if type(name) ~= "string" or name == "" then return Hyperion.Lucide.Info end

    if Hyperion.Icons then
        local ok, res = pcall(function()
            return Hyperion.Icons:GetIcon(name, set or "Material")
        end)
        if ok and res then
            if type(res) == "number" then return "rbxassetid://" .. tostring(res) end
            if type(res) == "string" and res ~= "" then
                -- some sets return a bare id string
                if res:match("^%d+$") then return "rbxassetid://" .. res end
                return res
            end
        end
    end

    -- fallback: built-in Lucide, tolerant of casing ("shield" -> "Shield")
    if Hyperion.Lucide[name] then return Hyperion.Lucide[name] end
    local cap = name:sub(1, 1):upper() .. name:sub(2)
    return Hyperion.Lucide[cap] or Hyperion.Lucide.Info
end

-- Preload icons + common textures once, off the main path, so the first
-- hover / panel-open doesn't pop-in while Roblox fetches the asset.
Hyperion._preloaded = false
function Hyperion:PreloadAssets(extra)
    if Hyperion._preloaded then return end
    Hyperion._preloaded = true
    task.spawn(function()
        local list = {}
        for _, id in pairs(Hyperion.Lucide) do
            if type(id) == "string" then list[#list + 1] = id end
        end
        for _, id in ipairs({
            "rbxassetid://6014261993", -- window drop shadow
            "rbxassetid://1316045217", -- soft glow
            "rbxassetid://4155801252", -- saturation/value picker
            "rbxassetid://10747384394", -- close (x)
            "rbxassetid://10734941499", -- notification default
        }) do list[#list + 1] = id end
        for _, id in ipairs(extra or {}) do list[#list + 1] = id end

        local objs = {}
        for _, id in ipairs(list) do
            local ok, img = pcall(function()
                local i = Instance.new("ImageLabel")
                i.Image = id
                return i
            end)
            if ok and img then objs[#objs + 1] = img end
        end
        pcall(function() game:GetService("ContentProvider"):PreloadAsync(objs) end)
        for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
    end)
end

----------------------------------------------------------------
-- THEME PRESETS
----------------------------------------------------------------
Hyperion.Themes = {
    Hyperion = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(185, 140, 255),
        ParticleStyle = "stars",
        GradientStops = {
            {0,    Color3.fromRGB(10, 7, 20)},
            {0.3,  Color3.fromRGB(28, 14, 56)},
            {0.5,  Color3.fromRGB(48, 24, 96)},
            {0.7,  Color3.fromRGB(28, 14, 56)},
            {1,    Color3.fromRGB(10, 7, 20)},
        },
        Accent       = Color3.fromRGB(150, 90, 235),
        AccentDark   = Color3.fromRGB(105, 55, 185),
        AccentLight  = Color3.fromRGB(178, 120, 255),
        AccentGlow   = Color3.fromRGB(165, 100, 245),
        AccentSub    = Color3.fromRGB(95, 50, 170),
        Background   = Color3.fromRGB(10, 7, 20),
        Surface      = Color3.fromRGB(18, 14, 30),
        SurfaceLight = Color3.fromRGB(28, 22, 44),
        SurfaceHover = Color3.fromRGB(38, 30, 58),
        SurfaceActive= Color3.fromRGB(46, 36, 70),
        Sidebar      = Color3.fromRGB(13, 10, 24),
        SidebarActive= Color3.fromRGB(30, 24, 50),
        Text         = Color3.fromRGB(232, 226, 248),
        TextDim      = Color3.fromRGB(150, 138, 178),
        TextMuted    = Color3.fromRGB(85, 75, 112),
        Border       = Color3.fromRGB(42, 34, 64),
        BorderLight  = Color3.fromRGB(58, 48, 86),
        ToggleOff    = Color3.fromRGB(42, 35, 62),
        SliderBg     = Color3.fromRGB(30, 24, 46),
        InputBg      = Color3.fromRGB(15, 11, 26),
    },
    Bunny = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(245, 165, 195),
        ParticleStyle = "paws",
        GradientStops = {
            {0,    Color3.fromRGB(240, 230, 214)},
            {0.5,  Color3.fromRGB(244, 218, 220)},
            {1,    Color3.fromRGB(240, 230, 214)},
        },
        Accent       = Color3.fromRGB(238, 138, 172),
        AccentDark   = Color3.fromRGB(208, 108, 145),
        AccentLight  = Color3.fromRGB(248, 172, 198),
        AccentGlow   = Color3.fromRGB(244, 156, 186),
        AccentSub    = Color3.fromRGB(216, 124, 158),
        Background   = Color3.fromRGB(242, 232, 216),
        Surface      = Color3.fromRGB(248, 240, 226),
        SurfaceLight = Color3.fromRGB(244, 232, 219),
        SurfaceHover = Color3.fromRGB(240, 225, 212),
        SurfaceActive= Color3.fromRGB(236, 219, 206),
        Sidebar      = Color3.fromRGB(245, 235, 220),
        SidebarActive= Color3.fromRGB(241, 226, 214),
        Text         = Color3.fromRGB(82, 60, 52),
        TextDim      = Color3.fromRGB(154, 122, 110),
        TextMuted    = Color3.fromRGB(198, 172, 156),
        Border       = Color3.fromRGB(228, 210, 192),
        BorderLight  = Color3.fromRGB(236, 220, 204),
        ToggleOff    = Color3.fromRGB(228, 212, 196),
        SliderBg     = Color3.fromRGB(234, 218, 202),
        InputBg      = Color3.fromRGB(248, 240, 226),
    },
    Matcha = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(190, 230, 150),
        ParticleStyle = "petals",
        GradientStops = {
            {0,    Color3.fromRGB(10, 16, 11)},
            {0.3,  Color3.fromRGB(22, 40, 24)},
            {0.5,  Color3.fromRGB(42, 74, 44)},
            {0.7,  Color3.fromRGB(22, 40, 24)},
            {1,    Color3.fromRGB(10, 16, 11)},
        },
        Accent       = Color3.fromRGB(130, 200, 110),
        AccentDark   = Color3.fromRGB(90, 155, 75),
        AccentLight  = Color3.fromRGB(172, 226, 150),
        AccentGlow   = Color3.fromRGB(150, 215, 130),
        AccentSub    = Color3.fromRGB(80, 140, 70),
        Background   = Color3.fromRGB(11, 16, 11),
        Surface      = Color3.fromRGB(17, 24, 17),
        SurfaceLight = Color3.fromRGB(25, 36, 26),
        SurfaceHover = Color3.fromRGB(34, 48, 35),
        SurfaceActive= Color3.fromRGB(42, 58, 42),
        Sidebar      = Color3.fromRGB(13, 19, 13),
        SidebarActive= Color3.fromRGB(27, 40, 28),
        Text         = Color3.fromRGB(232, 244, 226),
        TextDim      = Color3.fromRGB(150, 175, 142),
        TextMuted    = Color3.fromRGB(85, 105, 80),
        Border       = Color3.fromRGB(36, 52, 36),
        BorderLight  = Color3.fromRGB(50, 70, 50),
        ToggleOff    = Color3.fromRGB(36, 50, 36),
        SliderBg     = Color3.fromRGB(24, 36, 25),
        InputBg      = Color3.fromRGB(13, 19, 13),
    },
    Dracula = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(189, 147, 249),
        ParticleStyle = "stars",
        GradientStops = {
            {0,    Color3.fromRGB(20, 21, 30)},
            {0.3,  Color3.fromRGB(40, 42, 54)},
            {0.5,  Color3.fromRGB(70, 60, 106)},
            {0.7,  Color3.fromRGB(40, 42, 54)},
            {1,    Color3.fromRGB(20, 21, 30)},
        },
        Accent       = Color3.fromRGB(189, 147, 249),
        AccentDark   = Color3.fromRGB(140, 100, 200),
        AccentLight  = Color3.fromRGB(255, 121, 198),
        AccentGlow   = Color3.fromRGB(210, 130, 240),
        AccentSub    = Color3.fromRGB(98, 114, 164),
        Background   = Color3.fromRGB(30, 31, 42),
        Surface      = Color3.fromRGB(40, 42, 54),
        SurfaceLight = Color3.fromRGB(52, 55, 70),
        SurfaceHover = Color3.fromRGB(68, 71, 90),
        SurfaceActive= Color3.fromRGB(80, 83, 104),
        Sidebar      = Color3.fromRGB(33, 34, 46),
        SidebarActive= Color3.fromRGB(54, 57, 74),
        Text         = Color3.fromRGB(248, 248, 242),
        TextDim      = Color3.fromRGB(160, 165, 195),
        TextMuted    = Color3.fromRGB(98, 114, 164),
        Border       = Color3.fromRGB(60, 63, 82),
        BorderLight  = Color3.fromRGB(80, 84, 108),
        ToggleOff    = Color3.fromRGB(58, 61, 80),
        SliderBg     = Color3.fromRGB(48, 50, 66),
        InputBg      = Color3.fromRGB(33, 34, 46),
    },
    Halloween = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 150, 40),
        ParticleStyle = "halloween",
        GradientStops = {
            {0,    Color3.fromRGB(14, 8, 4)},
            {0.3,  Color3.fromRGB(40, 18, 6)},
            {0.5,  Color3.fromRGB(70, 32, 8)},
            {0.7,  Color3.fromRGB(40, 18, 6)},
            {1,    Color3.fromRGB(14, 8, 4)},
        },
        Accent       = Color3.fromRGB(255, 140, 30),
        AccentDark   = Color3.fromRGB(205, 100, 20),
        AccentLight  = Color3.fromRGB(255, 175, 80),
        AccentGlow   = Color3.fromRGB(255, 155, 55),
        AccentSub    = Color3.fromRGB(150, 70, 200),
        Background   = Color3.fromRGB(14, 8, 4),
        Surface      = Color3.fromRGB(24, 15, 8),
        SurfaceLight = Color3.fromRGB(36, 23, 12),
        SurfaceHover = Color3.fromRGB(48, 31, 16),
        SurfaceActive= Color3.fromRGB(58, 38, 20),
        Sidebar      = Color3.fromRGB(18, 11, 6),
        SidebarActive= Color3.fromRGB(40, 26, 14),
        Text         = Color3.fromRGB(248, 236, 222),
        TextDim      = Color3.fromRGB(190, 150, 110),
        TextMuted    = Color3.fromRGB(120, 90, 60),
        Border       = Color3.fromRGB(52, 34, 18),
        BorderLight  = Color3.fromRGB(72, 48, 26),
        ToggleOff    = Color3.fromRGB(50, 33, 18),
        SliderBg     = Color3.fromRGB(36, 23, 12),
        InputBg      = Color3.fromRGB(16, 10, 5),
    },
    Lavender = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(210, 185, 255),
        ParticleStyle = "petals",
        GradientStops = {
            {0,    Color3.fromRGB(16, 13, 24)},
            {0.3,  Color3.fromRGB(34, 28, 56)},
            {0.5,  Color3.fromRGB(58, 48, 96)},
            {0.7,  Color3.fromRGB(34, 28, 56)},
            {1,    Color3.fromRGB(16, 13, 24)},
        },
        Accent       = Color3.fromRGB(187, 160, 255),
        AccentDark   = Color3.fromRGB(145, 118, 215),
        AccentLight  = Color3.fromRGB(210, 190, 255),
        AccentGlow   = Color3.fromRGB(198, 172, 255),
        AccentSub    = Color3.fromRGB(120, 98, 185),
        Background   = Color3.fromRGB(16, 13, 24),
        Surface      = Color3.fromRGB(24, 20, 36),
        SurfaceLight = Color3.fromRGB(34, 28, 50),
        SurfaceHover = Color3.fromRGB(44, 37, 64),
        SurfaceActive= Color3.fromRGB(52, 44, 74),
        Sidebar      = Color3.fromRGB(19, 15, 28),
        SidebarActive= Color3.fromRGB(36, 30, 54),
        Text         = Color3.fromRGB(238, 232, 250),
        TextDim      = Color3.fromRGB(170, 158, 200),
        TextMuted    = Color3.fromRGB(100, 90, 130),
        Border       = Color3.fromRGB(46, 38, 68),
        BorderLight  = Color3.fromRGB(64, 54, 92),
        ToggleOff    = Color3.fromRGB(44, 37, 64),
        SliderBg     = Color3.fromRGB(32, 26, 48),
        InputBg      = Color3.fromRGB(17, 13, 26),
    },
    ["Strawberry Milk"] = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 130, 160),
        ParticleStyle = "strawberry",
        GradientStops = {
            {0,    Color3.fromRGB(26, 16, 20)},
            {0.3,  Color3.fromRGB(54, 28, 38)},
            {0.5,  Color3.fromRGB(92, 48, 64)},
            {0.7,  Color3.fromRGB(54, 28, 38)},
            {1,    Color3.fromRGB(26, 16, 20)},
        },
        Accent       = Color3.fromRGB(255, 150, 175),
        AccentDark   = Color3.fromRGB(220, 110, 140),
        AccentLight  = Color3.fromRGB(255, 195, 210),
        AccentGlow   = Color3.fromRGB(255, 170, 190),
        AccentSub    = Color3.fromRGB(190, 90, 120),
        Background   = Color3.fromRGB(26, 16, 20),
        Surface      = Color3.fromRGB(38, 24, 30),
        SurfaceLight = Color3.fromRGB(52, 34, 42),
        SurfaceHover = Color3.fromRGB(64, 42, 52),
        SurfaceActive= Color3.fromRGB(74, 50, 60),
        Sidebar      = Color3.fromRGB(30, 19, 24),
        SidebarActive= Color3.fromRGB(54, 36, 44),
        Text         = Color3.fromRGB(252, 240, 244),
        TextDim      = Color3.fromRGB(206, 160, 175),
        TextMuted    = Color3.fromRGB(130, 92, 104),
        Border       = Color3.fromRGB(66, 44, 54),
        BorderLight  = Color3.fromRGB(88, 60, 72),
        ToggleOff    = Color3.fromRGB(62, 42, 50),
        SliderBg     = Color3.fromRGB(46, 30, 38),
        InputBg      = Color3.fromRGB(24, 15, 19),
    },
    Coffee = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(210, 180, 140),
        ParticleStyle = "bubbles",
        GradientStops = {
            {0,    Color3.fromRGB(18, 12, 8)},
            {0.3,  Color3.fromRGB(40, 27, 18)},
            {0.5,  Color3.fromRGB(66, 45, 30)},
            {0.7,  Color3.fromRGB(40, 27, 18)},
            {1,    Color3.fromRGB(18, 12, 8)},
        },
        Accent       = Color3.fromRGB(198, 150, 100),
        AccentDark   = Color3.fromRGB(150, 110, 70),
        AccentLight  = Color3.fromRGB(222, 184, 140),
        AccentGlow   = Color3.fromRGB(210, 165, 115),
        AccentSub    = Color3.fromRGB(150, 108, 72),
        Background   = Color3.fromRGB(18, 12, 8),
        Surface      = Color3.fromRGB(30, 21, 14),
        SurfaceLight = Color3.fromRGB(44, 31, 21),
        SurfaceHover = Color3.fromRGB(56, 40, 27),
        SurfaceActive= Color3.fromRGB(66, 48, 32),
        Sidebar      = Color3.fromRGB(22, 15, 10),
        SidebarActive= Color3.fromRGB(46, 33, 22),
        Text         = Color3.fromRGB(244, 234, 222),
        TextDim      = Color3.fromRGB(188, 162, 136),
        TextMuted    = Color3.fromRGB(120, 98, 78),
        Border       = Color3.fromRGB(58, 42, 28),
        BorderLight  = Color3.fromRGB(80, 58, 40),
        ToggleOff    = Color3.fromRGB(54, 39, 26),
        SliderBg     = Color3.fromRGB(40, 29, 19),
        InputBg      = Color3.fromRGB(20, 13, 9),
    },
    Nord = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(160, 200, 220),
        ParticleStyle = "snowflakes",
        GradientStops = {
            {0,    Color3.fromRGB(30, 34, 42)},
            {0.3,  Color3.fromRGB(40, 46, 58)},
            {0.5,  Color3.fromRGB(56, 66, 84)},
            {0.7,  Color3.fromRGB(40, 46, 58)},
            {1,    Color3.fromRGB(30, 34, 42)},
        },
        Accent       = Color3.fromRGB(136, 192, 208),
        AccentDark   = Color3.fromRGB(94, 129, 172),
        AccentLight  = Color3.fromRGB(170, 215, 228),
        AccentGlow   = Color3.fromRGB(143, 188, 187),
        AccentSub    = Color3.fromRGB(94, 129, 172),
        Background   = Color3.fromRGB(46, 52, 64),
        Surface      = Color3.fromRGB(54, 62, 76),
        SurfaceLight = Color3.fromRGB(64, 73, 89),
        SurfaceHover = Color3.fromRGB(74, 84, 102),
        SurfaceActive= Color3.fromRGB(84, 95, 115),
        Sidebar      = Color3.fromRGB(50, 57, 70),
        SidebarActive= Color3.fromRGB(67, 76, 94),
        Text         = Color3.fromRGB(236, 239, 244),
        TextDim      = Color3.fromRGB(180, 190, 205),
        TextMuted    = Color3.fromRGB(110, 122, 140),
        Border       = Color3.fromRGB(67, 76, 94),
        BorderLight  = Color3.fromRGB(86, 97, 117),
        ToggleOff    = Color3.fromRGB(64, 73, 89),
        SliderBg     = Color3.fromRGB(59, 66, 82),
        InputBg      = Color3.fromRGB(46, 52, 64),
    },
    Mint = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(150, 240, 200),
        ParticleStyle = "bubbles",
        GradientStops = {
            {0,    Color3.fromRGB(8, 18, 15)},
            {0.3,  Color3.fromRGB(14, 36, 30)},
            {0.5,  Color3.fromRGB(22, 62, 50)},
            {0.7,  Color3.fromRGB(14, 36, 30)},
            {1,    Color3.fromRGB(8, 18, 15)},
        },
        Accent       = Color3.fromRGB(110, 225, 180),
        AccentDark   = Color3.fromRGB(70, 175, 135),
        AccentLight  = Color3.fromRGB(160, 240, 205),
        AccentGlow   = Color3.fromRGB(130, 232, 192),
        AccentSub    = Color3.fromRGB(70, 165, 130),
        Background   = Color3.fromRGB(8, 18, 15),
        Surface      = Color3.fromRGB(14, 26, 22),
        SurfaceLight = Color3.fromRGB(20, 38, 32),
        SurfaceHover = Color3.fromRGB(28, 50, 42),
        SurfaceActive= Color3.fromRGB(34, 60, 50),
        Sidebar      = Color3.fromRGB(10, 21, 17),
        SidebarActive= Color3.fromRGB(22, 42, 35),
        Text         = Color3.fromRGB(226, 246, 238),
        TextDim      = Color3.fromRGB(150, 190, 176),
        TextMuted    = Color3.fromRGB(84, 118, 106),
        Border       = Color3.fromRGB(34, 56, 48),
        BorderLight  = Color3.fromRGB(48, 74, 64),
        ToggleOff    = Color3.fromRGB(32, 54, 46),
        SliderBg     = Color3.fromRGB(22, 40, 34),
        InputBg      = Color3.fromRGB(9, 19, 16),
    },
    ["Royal Gold"] = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 215, 120),
        ParticleStyle = "orbs",
        GradientStops = {
            {0,    Color3.fromRGB(12, 10, 4)},
            {0.3,  Color3.fromRGB(30, 24, 8)},
            {0.5,  Color3.fromRGB(54, 42, 12)},
            {0.7,  Color3.fromRGB(30, 24, 8)},
            {1,    Color3.fromRGB(12, 10, 4)},
        },
        Accent       = Color3.fromRGB(230, 190, 90),
        AccentDark   = Color3.fromRGB(185, 145, 55),
        AccentLight  = Color3.fromRGB(255, 220, 130),
        AccentGlow   = Color3.fromRGB(245, 205, 110),
        AccentSub    = Color3.fromRGB(170, 135, 60),
        Background   = Color3.fromRGB(12, 10, 4),
        Surface      = Color3.fromRGB(22, 18, 9),
        SurfaceLight = Color3.fromRGB(34, 28, 14),
        SurfaceHover = Color3.fromRGB(46, 38, 19),
        SurfaceActive= Color3.fromRGB(56, 46, 23),
        Sidebar      = Color3.fromRGB(16, 13, 6),
        SidebarActive= Color3.fromRGB(38, 31, 15),
        Text         = Color3.fromRGB(248, 240, 220),
        TextDim      = Color3.fromRGB(196, 174, 124),
        TextMuted    = Color3.fromRGB(128, 110, 70),
        Border       = Color3.fromRGB(56, 46, 22),
        BorderLight  = Color3.fromRGB(80, 66, 32),
        ToggleOff    = Color3.fromRGB(52, 43, 21),
        SliderBg     = Color3.fromRGB(38, 31, 15),
        InputBg      = Color3.fromRGB(14, 11, 5),
    },
    Purple = {
        Logo         = nil,  -- uses the default/base logo: rbxassetid://74070104523360
        Accent       = Color3.fromRGB(140, 80, 220),
        AccentDark   = Color3.fromRGB(100, 50, 180),
        AccentLight  = Color3.fromRGB(170, 110, 255),
        AccentGlow   = Color3.fromRGB(160, 90, 240),
        AccentSub    = Color3.fromRGB(90, 45, 160),
        Background   = Color3.fromRGB(12, 10, 18),
        Surface      = Color3.fromRGB(18, 15, 26),
        SurfaceLight = Color3.fromRGB(26, 22, 38),
        SurfaceHover = Color3.fromRGB(34, 28, 50),
        SurfaceActive= Color3.fromRGB(40, 33, 58),
        Sidebar      = Color3.fromRGB(14, 12, 22),
        SidebarActive= Color3.fromRGB(28, 23, 44),
        Text         = Color3.fromRGB(230, 225, 245),
        TextDim      = Color3.fromRGB(145, 135, 170),
        TextMuted    = Color3.fromRGB(80, 72, 105),
        Border       = Color3.fromRGB(38, 32, 56),
        BorderLight  = Color3.fromRGB(52, 44, 75),
        ToggleOff    = Color3.fromRGB(40, 35, 58),
        SliderBg     = Color3.fromRGB(28, 24, 42),
        InputBg      = Color3.fromRGB(16, 13, 24),
    },
    Midnight = {
        Logo         = nil, -- uses the default/base logo
        Accent       = Color3.fromRGB(80, 120, 255),
        AccentDark   = Color3.fromRGB(50, 85, 200),
        AccentLight  = Color3.fromRGB(110, 150, 255),
        AccentGlow   = Color3.fromRGB(90, 130, 255),
        AccentSub    = Color3.fromRGB(45, 75, 175),
        Background   = Color3.fromRGB(8, 10, 18),
        Surface      = Color3.fromRGB(13, 16, 28),
        SurfaceLight = Color3.fromRGB(20, 24, 42),
        SurfaceHover = Color3.fromRGB(28, 33, 56),
        SurfaceActive= Color3.fromRGB(34, 40, 66),
        Sidebar      = Color3.fromRGB(10, 13, 22),
        SidebarActive= Color3.fromRGB(22, 28, 48),
        Text         = Color3.fromRGB(220, 228, 255),
        TextDim      = Color3.fromRGB(130, 145, 185),
        TextMuted    = Color3.fromRGB(65, 76, 110),
        Border       = Color3.fromRGB(28, 35, 60),
        BorderLight  = Color3.fromRGB(40, 50, 85),
        ToggleOff    = Color3.fromRGB(30, 37, 62),
        SliderBg     = Color3.fromRGB(20, 26, 48),
        InputBg      = Color3.fromRGB(10, 13, 24),
    },
    Rose = {
        Logo         = nil, -- uses the default/base logo
        Accent       = Color3.fromRGB(220, 80, 120),
        AccentDark   = Color3.fromRGB(175, 50, 90),
        AccentLight  = Color3.fromRGB(245, 110, 150),
        AccentGlow   = Color3.fromRGB(230, 90, 130),
        AccentSub    = Color3.fromRGB(145, 40, 75),
        Background   = Color3.fromRGB(14, 8, 10),
        Surface      = Color3.fromRGB(22, 13, 17),
        SurfaceLight = Color3.fromRGB(32, 20, 26),
        SurfaceHover = Color3.fromRGB(42, 27, 34),
        SurfaceActive= Color3.fromRGB(50, 33, 41),
        Sidebar      = Color3.fromRGB(16, 10, 13),
        SidebarActive= Color3.fromRGB(34, 21, 28),
        Text         = Color3.fromRGB(245, 228, 232),
        TextDim      = Color3.fromRGB(170, 140, 152),
        TextMuted    = Color3.fromRGB(90, 68, 76),
        Border       = Color3.fromRGB(50, 28, 36),
        BorderLight  = Color3.fromRGB(68, 40, 52),
        ToggleOff    = Color3.fromRGB(48, 30, 38),
        SliderBg     = Color3.fromRGB(30, 18, 24),
        InputBg      = Color3.fromRGB(16, 9, 12),
    },
    StarryNight = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(180, 210, 255),
        ParticleStyle = "stars",
        -- Multi-stop gradient: deep navy → dark blue → hint of indigo → dark blue → navy
        GradientStops = {
            {0,    Color3.fromRGB(4, 7, 20)},
            {0.3,  Color3.fromRGB(10, 18, 55)},
            {0.5,  Color3.fromRGB(20, 30, 90)},
            {0.7,  Color3.fromRGB(10, 18, 55)},
            {1,    Color3.fromRGB(4, 7, 20)},
        },
        Accent       = Color3.fromRGB(100, 160, 255),
        AccentDark   = Color3.fromRGB(65, 110, 210),
        AccentLight  = Color3.fromRGB(135, 185, 255),
        AccentGlow   = Color3.fromRGB(115, 170, 255),
        AccentSub    = Color3.fromRGB(50, 90, 180),
        Background   = Color3.fromRGB(4, 7, 20),        -- near-black deep navy
        Surface      = Color3.fromRGB(8, 12, 32),
        SurfaceLight = Color3.fromRGB(13, 19, 48),
        SurfaceHover = Color3.fromRGB(18, 27, 62),
        SurfaceActive= Color3.fromRGB(24, 35, 76),
        Sidebar      = Color3.fromRGB(6, 9, 24),
        SidebarActive= Color3.fromRGB(16, 24, 52),
        Text         = Color3.fromRGB(215, 228, 255),
        TextDim      = Color3.fromRGB(120, 148, 205),
        TextMuted    = Color3.fromRGB(55, 72, 120),
        Border       = Color3.fromRGB(22, 34, 72),
        BorderLight  = Color3.fromRGB(34, 50, 100),
        ToggleOff    = Color3.fromRGB(18, 28, 60),
        SliderBg     = Color3.fromRGB(11, 18, 44),
        InputBg      = Color3.fromRGB(5, 8, 24),
    },
    Aurora = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(140, 255, 200),
        ParticleStyle = "stars",
        -- Aurora: dark sky with subtle green/teal glow, keeps panels readable
        GradientStops = {
            {0,    Color3.fromRGB(3, 8, 12)},
            {0.2,  Color3.fromRGB(4, 20, 18)},
            {0.35, Color3.fromRGB(8, 45, 32)},
            {0.5,  Color3.fromRGB(6, 35, 40)},
            {0.65, Color3.fromRGB(8, 42, 30)},
            {0.8,  Color3.fromRGB(4, 18, 16)},
            {1,    Color3.fromRGB(3, 8, 12)},
        },
        Accent       = Color3.fromRGB(50, 230, 150),
        AccentDark   = Color3.fromRGB(28, 175, 110),
        AccentLight  = Color3.fromRGB(80, 255, 180),
        AccentGlow   = Color3.fromRGB(60, 240, 165),
        AccentSub    = Color3.fromRGB(22, 145, 95),
        Background   = Color3.fromRGB(3, 10, 12),       -- deep cold dark teal-black
        Surface      = Color3.fromRGB(5, 16, 20),
        SurfaceLight = Color3.fromRGB(8, 24, 30),
        SurfaceHover = Color3.fromRGB(12, 34, 42),
        SurfaceActive= Color3.fromRGB(16, 44, 54),
        Sidebar      = Color3.fromRGB(4, 12, 15),
        SidebarActive= Color3.fromRGB(12, 30, 38),
        Text         = Color3.fromRGB(200, 248, 230),
        TextDim      = Color3.fromRGB(105, 185, 155),
        TextMuted    = Color3.fromRGB(45, 95, 78),
        Border       = Color3.fromRGB(16, 50, 46),
        BorderLight  = Color3.fromRGB(25, 72, 65),
        ToggleOff    = Color3.fromRGB(12, 40, 37),
        SliderBg     = Color3.fromRGB(8, 26, 24),
        InputBg      = Color3.fromRGB(4, 12, 11),
    },
    Nebula = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 160, 220),
        ParticleStyle = "stars",
        -- Nebula: deep space with subtle magenta/purple haze
        GradientStops = {
            {0,    Color3.fromRGB(8, 4, 16)},
            {0.2,  Color3.fromRGB(20, 6, 30)},
            {0.35, Color3.fromRGB(38, 10, 42)},
            {0.5,  Color3.fromRGB(28, 8, 48)},
            {0.65, Color3.fromRGB(40, 12, 38)},
            {0.8,  Color3.fromRGB(18, 5, 28)},
            {1,    Color3.fromRGB(8, 4, 16)},
        },
        Accent       = Color3.fromRGB(210, 80, 255),
        AccentDark   = Color3.fromRGB(160, 50, 205),
        AccentLight  = Color3.fromRGB(230, 115, 255),
        AccentGlow   = Color3.fromRGB(220, 95, 255),
        AccentSub    = Color3.fromRGB(130, 38, 170),
        Background   = Color3.fromRGB(8, 4, 16),        -- deep space purple-black
        Surface      = Color3.fromRGB(13, 7, 25),
        SurfaceLight = Color3.fromRGB(21, 12, 40),
        SurfaceHover = Color3.fromRGB(30, 17, 55),
        SurfaceActive= Color3.fromRGB(38, 22, 68),
        Sidebar      = Color3.fromRGB(10, 5, 19),
        SidebarActive= Color3.fromRGB(26, 14, 46),
        Text         = Color3.fromRGB(245, 218, 255),
        TextDim      = Color3.fromRGB(168, 120, 195),
        TextMuted    = Color3.fromRGB(82, 52, 105),
        Border       = Color3.fromRGB(42, 18, 62),
        BorderLight  = Color3.fromRGB(60, 28, 88),
        ToggleOff    = Color3.fromRGB(36, 16, 54),
        SliderBg     = Color3.fromRGB(22, 10, 36),
        InputBg      = Color3.fromRGB(9, 4, 17),
    },
    Sunset = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 200, 120),
        ParticleStyle = "embers",
        GradientStops = {
            {0,    Color3.fromRGB(12, 6, 4)},
            {0.2,  Color3.fromRGB(35, 12, 8)},
            {0.4,  Color3.fromRGB(55, 20, 10)},
            {0.5,  Color3.fromRGB(50, 18, 14)},
            {0.6,  Color3.fromRGB(45, 15, 18)},
            {0.8,  Color3.fromRGB(28, 8, 12)},
            {1,    Color3.fromRGB(12, 6, 4)},
        },
        Accent       = Color3.fromRGB(245, 150, 50),
        AccentDark   = Color3.fromRGB(200, 110, 30),
        AccentLight  = Color3.fromRGB(255, 180, 80),
        AccentGlow   = Color3.fromRGB(250, 160, 60),
        AccentSub    = Color3.fromRGB(170, 90, 25),
        Background   = Color3.fromRGB(12, 6, 4),
        Surface      = Color3.fromRGB(20, 11, 8),
        SurfaceLight = Color3.fromRGB(32, 18, 14),
        SurfaceHover = Color3.fromRGB(44, 26, 20),
        SurfaceActive= Color3.fromRGB(54, 32, 25),
        Sidebar      = Color3.fromRGB(15, 8, 6),
        SidebarActive= Color3.fromRGB(36, 20, 16),
        Text         = Color3.fromRGB(255, 235, 215),
        TextDim      = Color3.fromRGB(190, 150, 120),
        TextMuted    = Color3.fromRGB(100, 72, 55),
        Border       = Color3.fromRGB(52, 30, 22),
        BorderLight  = Color3.fromRGB(72, 42, 30),
        ToggleOff    = Color3.fromRGB(42, 25, 18),
        SliderBg     = Color3.fromRGB(28, 16, 12),
        InputBg      = Color3.fromRGB(14, 7, 5),
    },
    Ocean = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(120, 200, 255),
        ParticleStyle = "bubbles",
        GradientStops = {
            {0,    Color3.fromRGB(2, 8, 16)},
            {0.2,  Color3.fromRGB(4, 18, 35)},
            {0.4,  Color3.fromRGB(6, 30, 55)},
            {0.5,  Color3.fromRGB(5, 25, 50)},
            {0.6,  Color3.fromRGB(4, 20, 45)},
            {0.8,  Color3.fromRGB(3, 12, 28)},
            {1,    Color3.fromRGB(2, 8, 16)},
        },
        Accent       = Color3.fromRGB(40, 160, 220),
        AccentDark   = Color3.fromRGB(25, 115, 175),
        AccentLight  = Color3.fromRGB(70, 190, 245),
        AccentGlow   = Color3.fromRGB(50, 170, 230),
        AccentSub    = Color3.fromRGB(20, 95, 150),
        Background   = Color3.fromRGB(2, 8, 16),
        Surface      = Color3.fromRGB(4, 14, 26),
        SurfaceLight = Color3.fromRGB(8, 22, 40),
        SurfaceHover = Color3.fromRGB(12, 30, 54),
        SurfaceActive= Color3.fromRGB(16, 38, 66),
        Sidebar      = Color3.fromRGB(3, 10, 20),
        SidebarActive= Color3.fromRGB(10, 26, 48),
        Text         = Color3.fromRGB(210, 235, 255),
        TextDim      = Color3.fromRGB(110, 158, 200),
        TextMuted    = Color3.fromRGB(48, 78, 115),
        Border       = Color3.fromRGB(14, 36, 62),
        BorderLight  = Color3.fromRGB(22, 52, 88),
        ToggleOff    = Color3.fromRGB(10, 28, 50),
        SliderBg     = Color3.fromRGB(6, 18, 36),
        InputBg      = Color3.fromRGB(3, 9, 18),
    },
    Crimson = {
        Logo         = nil,
        Accent       = Color3.fromRGB(200, 40, 50),
        AccentDark   = Color3.fromRGB(155, 25, 35),
        AccentLight  = Color3.fromRGB(235, 70, 80),
        AccentGlow   = Color3.fromRGB(215, 50, 60),
        AccentSub    = Color3.fromRGB(130, 20, 28),
        Background   = Color3.fromRGB(10, 4, 5),
        Surface      = Color3.fromRGB(18, 8, 10),
        SurfaceLight = Color3.fromRGB(28, 14, 17),
        SurfaceHover = Color3.fromRGB(40, 20, 24),
        SurfaceActive= Color3.fromRGB(50, 26, 30),
        Sidebar      = Color3.fromRGB(13, 5, 7),
        SidebarActive= Color3.fromRGB(34, 16, 20),
        Text         = Color3.fromRGB(250, 228, 230),
        TextDim      = Color3.fromRGB(175, 130, 138),
        TextMuted    = Color3.fromRGB(95, 60, 66),
        Border       = Color3.fromRGB(48, 20, 25),
        BorderLight  = Color3.fromRGB(68, 30, 38),
        ToggleOff    = Color3.fromRGB(40, 18, 22),
        SliderBg     = Color3.fromRGB(24, 10, 14),
        InputBg      = Color3.fromRGB(12, 5, 7),
    },
    Sakura = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(255, 190, 210),
        ParticleStyle = "petals",
        GradientStops = {
            {0,    Color3.fromRGB(14, 8, 12)},
            {0.2,  Color3.fromRGB(28, 12, 22)},
            {0.4,  Color3.fromRGB(42, 16, 32)},
            {0.5,  Color3.fromRGB(38, 14, 28)},
            {0.6,  Color3.fromRGB(35, 12, 26)},
            {0.8,  Color3.fromRGB(22, 10, 18)},
            {1,    Color3.fromRGB(14, 8, 12)},
        },
        Accent       = Color3.fromRGB(235, 120, 160),
        AccentDark   = Color3.fromRGB(190, 80, 120),
        AccentLight  = Color3.fromRGB(255, 155, 190),
        AccentGlow   = Color3.fromRGB(245, 135, 175),
        AccentSub    = Color3.fromRGB(160, 65, 100),
        Background   = Color3.fromRGB(14, 8, 12),
        Surface      = Color3.fromRGB(22, 13, 18),
        SurfaceLight = Color3.fromRGB(34, 20, 28),
        SurfaceHover = Color3.fromRGB(46, 28, 38),
        SurfaceActive= Color3.fromRGB(56, 34, 46),
        Sidebar      = Color3.fromRGB(16, 9, 13),
        SidebarActive= Color3.fromRGB(38, 22, 30),
        Text         = Color3.fromRGB(255, 235, 242),
        TextDim      = Color3.fromRGB(185, 145, 162),
        TextMuted    = Color3.fromRGB(100, 70, 82),
        Border       = Color3.fromRGB(50, 28, 38),
        BorderLight  = Color3.fromRGB(70, 40, 54),
        ToggleOff    = Color3.fromRGB(44, 24, 34),
        SliderBg     = Color3.fromRGB(28, 15, 22),
        InputBg      = Color3.fromRGB(16, 9, 13),
    },
    Vaporwave = {
        Logo         = nil,
        Animated     = true,
        -- Cyan gridlines — the iconic vaporwave grid floor color
        StarColor    = Color3.fromRGB(100, 255, 255),
        ParticleStyle = "gridlines",
        -- Reference-accurate vaporwave sunset gradient:
        --   top     : hot magenta-pink sky
        --   mid-top : pink → orange sun band
        --   middle  : warm orange/yellow (sun core)
        --   mid-low : magenta → deep purple transition (horizon haze)
        --   bottom  : deep indigo-navy ground (where the cyan grid sits)
        GradientStops = {
            {0,    Color3.fromRGB(255, 40, 185)},   -- hot pink sky
            {0.18, Color3.fromRGB(255, 80, 200)},
            {0.32, Color3.fromRGB(255, 140, 120)},  -- pink-orange sun halo
            {0.42, Color3.fromRGB(255, 200, 60)},   -- yellow sun core
            {0.52, Color3.fromRGB(255, 95, 140)},   -- orange-pink band
            {0.62, Color3.fromRGB(200, 50, 180)},   -- magenta horizon
            {0.78, Color3.fromRGB(70, 30, 120)},    -- deep purple ground
            {1,    Color3.fromRGB(20, 10, 55)},     -- indigo floor
        },
        Accent       = Color3.fromRGB(255, 95, 205),   -- hot pink UI accent
        AccentDark   = Color3.fromRGB(200, 55, 160),
        AccentLight  = Color3.fromRGB(255, 150, 225),
        AccentGlow   = Color3.fromRGB(255, 110, 215),
        AccentSub    = Color3.fromRGB(100, 230, 240),  -- cyan secondary (grid color)
        Background   = Color3.fromRGB(18, 10, 36),     -- deep indigo for panels
        Surface      = Color3.fromRGB(28, 14, 50),
        SurfaceLight = Color3.fromRGB(42, 22, 70),
        SurfaceHover = Color3.fromRGB(58, 32, 92),
        SurfaceActive= Color3.fromRGB(72, 42, 110),
        Sidebar      = Color3.fromRGB(20, 10, 40),
        SidebarActive= Color3.fromRGB(48, 26, 80),
        Text         = Color3.fromRGB(250, 225, 255),
        TextDim      = Color3.fromRGB(200, 155, 225),
        TextMuted    = Color3.fromRGB(120, 90, 165),
        Border       = Color3.fromRGB(95, 45, 145),
        BorderLight  = Color3.fromRGB(140, 70, 200),
        ToggleOff    = Color3.fromRGB(52, 26, 80),
        SliderBg     = Color3.fromRGB(34, 16, 58),
        InputBg      = Color3.fromRGB(20, 10, 38),
    },
    Love = {
        Logo         = nil,
        Animated     = true,
        -- Soft pink hearts falling against the deep red sky
        StarColor    = Color3.fromRGB(255, 140, 185),
        ParticleStyle = "hearts",
        -- Romantic red/pink gradient:
        --   top     : deep crimson sky
        --   mid-top : blood red
        --   middle  : hot pink / coral highlight
        --   mid-low : magenta-wine
        --   bottom  : dark burgundy ground
        GradientStops = {
            {0,    Color3.fromRGB(110, 8, 40)},      -- deep crimson
            {0.18, Color3.fromRGB(180, 20, 55)},     -- blood red
            {0.32, Color3.fromRGB(240, 60, 90)},     -- red highlight
            {0.45, Color3.fromRGB(255, 110, 155)},   -- hot pink core
            {0.58, Color3.fromRGB(220, 50, 115)},    -- pink band
            {0.72, Color3.fromRGB(135, 20, 70)},     -- magenta-wine
            {0.88, Color3.fromRGB(55, 8, 30)},       -- dark wine
            {1,    Color3.fromRGB(22, 4, 15)},       -- near-black burgundy
        },
        Accent       = Color3.fromRGB(255, 70, 115),   -- hot pink-red accent
        AccentDark   = Color3.fromRGB(205, 35, 75),
        AccentLight  = Color3.fromRGB(255, 125, 160),
        AccentGlow   = Color3.fromRGB(255, 90, 135),
        AccentSub    = Color3.fromRGB(255, 170, 200),  -- soft pink secondary
        Background   = Color3.fromRGB(22, 6, 14),
        Surface      = Color3.fromRGB(34, 10, 22),
        SurfaceLight = Color3.fromRGB(52, 16, 32),
        SurfaceHover = Color3.fromRGB(70, 22, 44),
        SurfaceActive= Color3.fromRGB(88, 30, 56),
        Sidebar      = Color3.fromRGB(26, 7, 16),
        SidebarActive= Color3.fromRGB(60, 18, 36),
        Text         = Color3.fromRGB(255, 228, 232),
        TextDim      = Color3.fromRGB(210, 150, 165),
        TextMuted    = Color3.fromRGB(120, 72, 85),
        Border       = Color3.fromRGB(110, 32, 55),
        BorderLight  = Color3.fromRGB(155, 50, 80),
        ToggleOff    = Color3.fromRGB(60, 18, 32),
        SliderBg     = Color3.fromRGB(38, 12, 24),
        InputBg      = Color3.fromRGB(22, 6, 14),
    },
    Christmas = {
        Logo         = nil,
        Animated     = true,
        StarColor    = Color3.fromRGB(220, 240, 255),
        StarColors   = {
            Color3.fromRGB(255, 255, 255),   -- pure white
            Color3.fromRGB(200, 235, 255),   -- icy light blue
            Color3.fromRGB(180, 220, 255),   -- soft blue
            Color3.fromRGB(220, 240, 255),   -- blueish white
        },
        ParticleStyle = "christmaslights",
        TitleGradient = {
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(140, 210, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(230, 245, 255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(140, 210, 255)),
        },
        LogoGradient = {
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 235, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140, 210, 255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 235, 255)),
        },
        GradientStops = {
            {0,    Color3.fromRGB(6,  10, 20)},
            {0.18, Color3.fromRGB(10, 16, 30)},
            {0.32, Color3.fromRGB(16, 25, 45)},
            {0.5,  Color3.fromRGB(22, 35, 58)},
            {0.65, Color3.fromRGB(16, 24, 44)},
            {0.82, Color3.fromRGB(10, 16, 30)},
            {1,    Color3.fromRGB(6,  10, 20)},
        },
        Accent       = Color3.fromRGB(140, 210, 255),   -- icy blue
        AccentDark   = Color3.fromRGB(90,  160, 220),
        AccentLight  = Color3.fromRGB(200, 235, 255),
        AccentGlow   = Color3.fromRGB(160, 220, 255),
        AccentSub    = Color3.fromRGB(180, 230, 255),
        Background   = Color3.fromRGB(8,  12, 22),
        Surface      = Color3.fromRGB(14, 20, 36),
        SurfaceLight = Color3.fromRGB(22, 32, 52),
        SurfaceHover = Color3.fromRGB(30, 45, 68),
        SurfaceActive= Color3.fromRGB(38, 56, 82),
        Sidebar      = Color3.fromRGB(10, 15, 26),
        SidebarActive= Color3.fromRGB(26, 40, 62),
        Text         = Color3.fromRGB(230, 245, 255),
        TextDim      = Color3.fromRGB(170, 200, 225),
        TextMuted    = Color3.fromRGB(100, 135, 165),
        Border       = Color3.fromRGB(55,  85, 120),
        BorderLight  = Color3.fromRGB(90,  130, 175),
        ToggleOff    = Color3.fromRGB(20,  32,  50),
        SliderBg     = Color3.fromRGB(12,  20,  36),
        InputBg      = Color3.fromRGB(8,   14,  24),
    },
    Neko = {
        Logo            = nil,
        Animated        = true,
        TitleText       = "∧ Hyperion ∧",
        BackgroundImage = "rbxassetid://76774789",
        BackgroundTint  = 0.05,
        StarColor     = Color3.fromRGB(255, 182, 210),
        StarColors    = {
            Color3.fromRGB(255, 182, 210),  -- bright pink
            Color3.fromRGB(255, 220, 235),  -- soft blush
            Color3.fromRGB(255, 200, 225),  -- medium pink
            Color3.fromRGB(255, 240, 248),  -- near-white
        },
        ParticleStyle = "paws",
        TitleGradient = {
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 182, 210)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 240, 248)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 160, 200)),
        },
        GradientStops = {
            {0,    Color3.fromRGB(18,  6,  12)},
            {0.12, Color3.fromRGB(34, 10,  22)},
            {0.28, Color3.fromRGB(52, 16,  34)},
            {0.42, Color3.fromRGB(62, 20,  42)},
            {0.55, Color3.fromRGB(52, 16,  34)},
            {0.7,  Color3.fromRGB(36, 10,  24)},
            {0.86, Color3.fromRGB(22,  6,  14)},
            {1,    Color3.fromRGB(18,  6,  12)},
        },
        Accent       = Color3.fromRGB(255, 130, 180),
        AccentDark   = Color3.fromRGB(200,  80, 130),
        AccentLight  = Color3.fromRGB(255, 200, 225),
        AccentGlow   = Color3.fromRGB(255, 160, 205),
        AccentSub    = Color3.fromRGB(220, 150, 190),
        Background   = Color3.fromRGB(18,   6,  12),
        Surface      = Color3.fromRGB(38,  12,  24),
        SurfaceLight = Color3.fromRGB(55,  18,  36),
        SurfaceHover = Color3.fromRGB(72,  24,  48),
        SurfaceActive= Color3.fromRGB(88,  30,  60),
        Sidebar      = Color3.fromRGB(24,   7,  15),
        SidebarActive= Color3.fromRGB(58,  18,  38),
        Text         = Color3.fromRGB(255, 240, 248),
        TextDim      = Color3.fromRGB(220, 190, 210),
        TextMuted    = Color3.fromRGB(150, 110, 135),
        Border       = Color3.fromRGB(120,  48,  80),
        BorderLight  = Color3.fromRGB(180,  80, 125),
        ToggleOff    = Color3.fromRGB(55,  16,  34),
        SliderBg     = Color3.fromRGB(30,   8,  18),
        InputBg      = Color3.fromRGB(20,   5,  12),
    },
}

-- Apply a named theme or a custom table of color overrides.
function Hyperion:SetTheme(nameOrTable)
    local preset = type(nameOrTable) == "string"
        and Hyperion.Themes[nameOrTable]
        or nameOrTable
    if not preset then
        warn("Hyperion:SetTheme — unknown theme: " .. tostring(nameOrTable))
        return
    end
    -- Store the logo override so windows can read it
    Hyperion._themeLogo = preset.Logo or nil
    for k, v in pairs(preset) do
        if k ~= "Logo" and k ~= "GradientStops" and k ~= "GradientMid" and k ~= "Animated" and k ~= "StarColor" and k ~= "ParticleStyle" and k ~= "StarColors" and k ~= "TitleGradient" and k ~= "LogoGradient" and k ~= "BackgroundImage" and k ~= "BackgroundTint" and k ~= "TitleText" then
            Hyperion.Theme[k] = v
        end
    end
    for _, fn in ipairs(Hyperion.ThemeListeners) do
        pcall(fn, Hyperion.Theme)
    end
end

function Hyperion:OnThemeChanged(fn)
    table.insert(Hyperion.ThemeListeners, fn)
    return function()
        for i, v in ipairs(Hyperion.ThemeListeners) do
            if v == fn then table.remove(Hyperion.ThemeListeners, i); break end
        end
    end
end

function Hyperion:_RegisterKeybind(entry)
    table.insert(Hyperion.Keybinds, entry)
    for _, fn in ipairs(Hyperion.KeybindListeners) do pcall(fn, "added", entry) end
    return entry
end

function Hyperion:_FireKeybindChanged(entry)
    for _, fn in ipairs(Hyperion.KeybindListeners) do pcall(fn, "changed", entry) end
end

function Hyperion:OnKeybindEvent(fn)
    table.insert(Hyperion.KeybindListeners, fn)
    return function()
        for i, v in ipairs(Hyperion.KeybindListeners) do
            if v == fn then table.remove(Hyperion.KeybindListeners, i); break end
        end
    end
end

----------------------------------------------------------------
-- STARFIELD ANIMATION
----------------------------------------------------------------
Hyperion._starConn = nil   -- RunService connection for active star loop
Hyperion._starFrames = {}  -- live star Frame instances
Hyperion._starGen = 0      -- generation counter to kill stale cycles

local function _stopStarfield()
    Hyperion._starGen = Hyperion._starGen + 1
    if Hyperion._starActive then
        Hyperion._starActive()
        Hyperion._starActive = nil
    end
    if Hyperion._starConn then
        Hyperion._starConn:Disconnect()
        Hyperion._starConn = nil
    end
    for _, f in ipairs(Hyperion._starFrames) do
        if f and f.Parent then f:Destroy() end
    end
    Hyperion._starFrames = {}
end

local function _startStarfield(parent, starColor, meteorParent, particleStyle, starColors)
    _stopStarfield()
    local ts = game:GetService("TweenService")
    local active = true
    local gen = Hyperion._starGen  -- capture generation
    local color = starColor or Color3.fromRGB(200, 220, 255)
    local mParent = meteorParent or parent
    local pStyle = particleStyle or "stars"

    local _palette = (type(starColors) == "table" and #starColors > 0) and starColors or nil
    local function getParticleColor()
        if _palette then
            return _palette[math.random(1, #_palette)]
        end
        return color
    end

    local function isAlive()
        return active and gen == Hyperion._starGen and parent and parent.Parent
    end

    -- ── Twinkling ambient stars ──────────────────────────────────
    local AMBIENT = 65
    local function spawnAmbient()
        if not isAlive() then return end

        local hasGlow  = math.random(1, 5) ~= 1  -- 80% have glow rings, 20% bare dot
        local coreSize = math.random(1, 2)
        local px = math.random(3, 96) / 100
        local py = math.random(3, 96) / 100
        local fadeIn  = math.random(10, 22) / 10
        local hold    = math.random(15, 45) / 10
        local fadeOut = math.random(12, 28) / 10
        local pause   = math.random(5,  30) / 10

        local ambColor = getParticleColor()
        local ringFrames = {}
        if hasGlow then
            local rings = {
                { mult = 6,   tr = 0.86 },
                { mult = 2.8, tr = 0.68 },
            }
            for _, def in ipairs(rings) do
                local rSize = math.max(1, coreSize * def.mult)
                local r = Instance.new("Frame")
                r.BackgroundColor3 = ambColor
                r.BackgroundTransparency = 1
                r.BorderSizePixel = 0
                r.Size = UDim2.new(0, rSize, 0, rSize)
                r.Position = UDim2.new(px, -rSize/2, py, -rSize/2)
                r.ZIndex = 1
                r.Parent = parent
                local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(1,0); rc.Parent = r
                table.insert(ringFrames, { frame = r, peakTr = def.tr, size = rSize })
                table.insert(Hyperion._starFrames, r)
            end
        end

        local core = Instance.new("Frame")
        core.BackgroundColor3 = Color3.new(1,1,1)
        core.BackgroundTransparency = 1
        core.BorderSizePixel = 0
        core.Size = UDim2.new(0, coreSize, 0, coreSize)
        core.Position = UDim2.new(px, -coreSize/2, py, -coreSize/2)
        core.ZIndex = 3
        core.Parent = parent
        local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(1,0); cc.Parent = core
        table.insert(Hyperion._starFrames, core)

        local function cleanup()
            for _, rf in ipairs(ringFrames) do
                if rf.frame and rf.frame.Parent then rf.frame:Destroy() end
            end
            if core and core.Parent then core:Destroy() end
        end

        local function cycle()
            if not isAlive() then cleanup(); return end
            for _, rf in ipairs(ringFrames) do
                ts:Create(rf.frame, TweenInfo.new(fadeIn, Enum.EasingStyle.Sine), {BackgroundTransparency = rf.peakTr}):Play()
            end
            ts:Create(core, TweenInfo.new(fadeIn * 0.7, Enum.EasingStyle.Sine), {BackgroundTransparency = 0}):Play()

            task.delay(fadeIn + hold, function()
                if not isAlive() then cleanup(); return end
                for _, rf in ipairs(ringFrames) do
                    ts:Create(rf.frame, TweenInfo.new(fadeOut, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()
                end
                ts:Create(core, TweenInfo.new(fadeOut, Enum.EasingStyle.Sine), {BackgroundTransparency = 1}):Play()

                task.delay(fadeOut + pause, function()
                    if not isAlive() then cleanup(); return end
                    local nx = math.random(3, 96) / 100
                    local ny = math.random(3, 96) / 100
                    core.Position = UDim2.new(nx, -coreSize/2, ny, -coreSize/2)
                    for _, rf in ipairs(ringFrames) do
                        rf.frame.Position = UDim2.new(nx, -rf.size/2, ny, -rf.size/2)
                    end
                    cycle()
                end)
            end)
        end

        task.delay(math.random(0, 60) / 10, cycle)
    end

    -- Only spawn ambient twinkling stars for space-themed styles
    local hasAmbientStars = (pStyle == "stars" or pStyle == "wisps" or pStyle == "orbs")

    if hasAmbientStars then
        for i = 1, AMBIENT do
            task.delay(i * 0.08, function()
                if isAlive() then spawnAmbient() end
            end)
        end
    end

    -- ── Theme-specific particles ─────────────────────────────────
    local activeParticles = {}

    local function getCanvasSize()
        local W = mParent.AbsoluteSize.X
        local H = mParent.AbsoluteSize.Y
        if W < 10 then W = 880 end
        if H < 10 then H = 600 end
        return W, H
    end

    -- STARS: falling star with tail (StarryNight)
    local function spawnStar()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local startX = math.random(10, math.max(20, W - 10))
        local speed = math.random(180, 320)
        local tailLen = math.random(35, 70)
        local headSz = math.random(2, 3)
        local starC = getParticleColor()

        local tail = Instance.new("Frame")
        tail.BackgroundColor3 = starC; tail.BorderSizePixel = 0
        tail.Size = UDim2.fromOffset(1, tailLen)
        tail.Position = UDim2.fromOffset(startX, -tailLen - 10)
        tail.ZIndex = 2; tail.Parent = mParent
        local tg = Instance.new("UIGradient"); tg.Parent = tail
        tg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.7), NumberSequenceKeypoint.new(1, 0.05),
        })
        table.insert(Hyperion._starFrames, tail)

        local gSz = headSz * 4
        local glow = Instance.new("Frame")
        glow.BackgroundColor3 = starC; glow.BackgroundTransparency = 0.7; glow.BorderSizePixel = 0
        glow.Size = UDim2.fromOffset(gSz, gSz); glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = UDim2.fromOffset(startX, -10); glow.ZIndex = 3; glow.Parent = mParent
        Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
        table.insert(Hyperion._starFrames, glow)

        local head = Instance.new("Frame")
        head.BackgroundColor3 = Color3.new(1, 1, 1); head.BorderSizePixel = 0
        head.Size = UDim2.fromOffset(headSz, headSz); head.AnchorPoint = Vector2.new(0.5, 0.5)
        head.Position = UDim2.fromOffset(startX, -10); head.ZIndex = 5; head.Parent = mParent
        Instance.new("UICorner", head).CornerRadius = UDim.new(1, 0)
        table.insert(Hyperion._starFrames, head)

        table.insert(activeParticles, {
            type = "star", x = startX, y = -tailLen - 10, speed = speed,
            tailLen = tailLen, tail = tail, glow = glow, head = head,
            alive = true, maxY = H + tailLen + 20, fadeStart = H * 0.65,
        })
    end

    -- PETALS: sakura leaves that sway side to side (Sakura)
    local function spawnPetal()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(4, 8)
        local petal = Instance.new("Frame")
        petal.BackgroundColor3 = color; petal.BackgroundTransparency = math.random(15, 40) / 100
        petal.BorderSizePixel = 0; petal.Rotation = math.random(0, 360)
        petal.Size = UDim2.fromOffset(sz, math.floor(sz * 0.6))
        petal.AnchorPoint = Vector2.new(0.5, 0.5)
        petal.Position = UDim2.fromOffset(math.random(10, W - 10), -sz)
        petal.ZIndex = 4; petal.Parent = mParent
        Instance.new("UICorner", petal).CornerRadius = UDim.new(0, 2)
        table.insert(Hyperion._starFrames, petal)

        table.insert(activeParticles, {
            type = "petal", frame = petal, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(30, 70), swayAmp = math.random(20, 50),
            swaySpeed = math.random(8, 18) / 10, rotSpeed = math.random(20, 60),
            phase = math.random(0, 628) / 100, time = 0,
            maxY = H + 20, fadeStart = H * 0.7,
        })
    end

    -- BUBBLES: circles floating upward (Ocean)
    local function spawnBubble()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(3, 8)
        local bubble = Instance.new("Frame")
        bubble.BackgroundColor3 = color; bubble.BackgroundTransparency = math.random(50, 75) / 100
        bubble.BorderSizePixel = 0
        bubble.Size = UDim2.fromOffset(sz, sz)
        bubble.AnchorPoint = Vector2.new(0.5, 0.5)
        bubble.Position = UDim2.fromOffset(math.random(10, W - 10), H + sz)
        bubble.ZIndex = 4; bubble.Parent = mParent
        Instance.new("UICorner", bubble).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke"); stroke.Color = color
        stroke.Thickness = 1; stroke.Transparency = 0.5; stroke.Parent = bubble
        table.insert(Hyperion._starFrames, bubble)

        table.insert(activeParticles, {
            type = "bubble", frame = bubble, alive = true,
            x = math.random(10, W - 10), y = H + sz,
            speed = math.random(25, 60), swayAmp = math.random(8, 20),
            swaySpeed = math.random(10, 22) / 10, phase = math.random(0, 628) / 100,
            time = 0, minY = -20,
        })
    end

    -- EMBERS: warm dots drifting down slowly (Sunset)
    local function spawnEmber()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(2, 4)
        local ember = Instance.new("Frame")
        ember.BackgroundColor3 = color; ember.BackgroundTransparency = math.random(20, 50) / 100
        ember.BorderSizePixel = 0
        ember.Size = UDim2.fromOffset(sz, sz)
        ember.AnchorPoint = Vector2.new(0.5, 0.5)
        ember.Position = UDim2.fromOffset(math.random(10, W - 10), -sz)
        ember.ZIndex = 4; ember.Parent = mParent
        Instance.new("UICorner", ember).CornerRadius = UDim.new(1, 0)
        table.insert(Hyperion._starFrames, ember)

        table.insert(activeParticles, {
            type = "ember", frame = ember, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(20, 50), driftX = math.random(-15, 15),
            swayAmp = math.random(5, 15), swaySpeed = math.random(8, 16) / 10,
            phase = math.random(0, 628) / 100, time = 0,
            maxY = H + 20, fadeStart = H * 0.7,
        })
    end

    -- WISPS: slow vertical light streaks (Aurora)
    local function spawnWisp()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local wispH = math.random(30, 80)
        local wispW = math.random(2, 4)
        local wisp = Instance.new("Frame")
        wisp.BackgroundColor3 = color; wisp.BackgroundTransparency = math.random(55, 80) / 100
        wisp.BorderSizePixel = 0
        wisp.Size = UDim2.fromOffset(wispW, wispH)
        wisp.AnchorPoint = Vector2.new(0.5, 0.5)
        wisp.Position = UDim2.fromOffset(math.random(10, W - 10), -wispH)
        wisp.ZIndex = 2; wisp.Parent = mParent
        local wg = Instance.new("UIGradient"); wg.Parent = wisp
        wg.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0.9),
        })
        Instance.new("UICorner", wisp).CornerRadius = UDim.new(0, 2)
        table.insert(Hyperion._starFrames, wisp)

        table.insert(activeParticles, {
            type = "wisp", frame = wisp, alive = true,
            x = math.random(10, W - 10), y = -wispH,
            speed = math.random(15, 40), swayAmp = math.random(3, 10),
            swaySpeed = math.random(5, 12) / 10, phase = math.random(0, 628) / 100,
            time = 0, maxY = H + wispH + 20, fadeStart = H * 0.6,
        })
    end

    -- ORBS: soft glowing circles that drift slowly (Nebula)
    local function spawnOrb()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(5, 14)
        local orb = Instance.new("Frame")
        orb.BackgroundColor3 = color; orb.BackgroundTransparency = math.random(60, 82) / 100
        orb.BorderSizePixel = 0
        orb.Size = UDim2.fromOffset(sz, sz)
        orb.AnchorPoint = Vector2.new(0.5, 0.5)
        orb.Position = UDim2.fromOffset(math.random(10, W - 10), -sz)
        orb.ZIndex = 3; orb.Parent = mParent
        Instance.new("UICorner", orb).CornerRadius = UDim.new(1, 0)
        table.insert(Hyperion._starFrames, orb)

        table.insert(activeParticles, {
            type = "orb", frame = orb, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(12, 35), driftX = math.random(-10, 10),
            swayAmp = math.random(10, 30), swaySpeed = math.random(4, 10) / 10,
            phase = math.random(0, 628) / 100, time = 0,
            maxY = H + sz + 20, fadeStart = H * 0.6,
        })
    end

    -- HEARTS: pink heart icons that drift down with sway and slow rotation (Love)
    local function spawnHeart()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(10, 18)
        local heart = Instance.new("ImageLabel")
        heart.BackgroundTransparency = 1
        heart.Image = "rbxassetid://10723406885"   -- lucide-heart
        heart.ImageColor3 = color
        heart.ImageTransparency = math.random(20, 45) / 100
        heart.Size = UDim2.fromOffset(sz, sz)
        heart.AnchorPoint = Vector2.new(0.5, 0.5)
        heart.Position = UDim2.fromOffset(math.random(10, W - 10), -sz)
        heart.Rotation = math.random(-20, 20)
        heart.ZIndex = 4
        heart.Parent = mParent
        table.insert(Hyperion._starFrames, heart)

        table.insert(activeParticles, {
            type = "heart", frame = heart, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(25, 55),
            swayAmp = math.random(15, 35), swaySpeed = math.random(6, 12) / 10,
            rotSpeed = math.random(-30, 30),
            phase = math.random(0, 628) / 100, time = 0,
            maxY = H + sz + 20, fadeStart = H * 0.65,
        })
    end

    -- PAWS: cute paw prints that drift down with sway and rotation (Neko)
    local function spawnPaw()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(10, 18)
        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.Size = UDim2.fromOffset(sz, sz)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromOffset(math.random(20, W - 20), -sz)
        container.Rotation = math.random(-30, 30)
        container.ZIndex = 4
        container.Parent = mParent

        local pawColor = getParticleColor()
        local transp = math.random(4, 18) / 100  -- 82-96% opaque

        local function makePiece(ax, ay, sx, sy)
            local f = Instance.new("Frame")
            f.BackgroundColor3 = pawColor
            f.BackgroundTransparency = transp
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Size = UDim2.new(sx, 0, sy, 0)
            f.Position = UDim2.new(ax, 0, ay, 0)
            f.ZIndex = 4
            f.Parent = container
            Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
        end

        -- Palm pad: wide oval at the bottom-center
        makePiece(0.5, 0.72, 0.54, 0.46)

        -- 4 toe beans in arc above palm (all within [0,1] bounds)
        makePiece(0.18, 0.33, 0.23, 0.27)  -- outer left
        makePiece(0.38, 0.14, 0.23, 0.27)  -- inner left
        makePiece(0.62, 0.14, 0.23, 0.27)  -- inner right
        makePiece(0.82, 0.33, 0.23, 0.27)  -- outer right

        table.insert(Hyperion._starFrames, container)
        table.insert(activeParticles, {
            type = "paw", frame = container, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(28, 52),
            swayAmp = math.random(10, 24), swaySpeed = math.random(4, 9) / 10,
            rotSpeed = math.random(-15, 15),
            phase = math.random(0, 628) / 100, time = 0,
            alpha = transp,
            maxY = H + sz + 20, fadeStart = H * 0.70,
        })
    end

    -- SNOWFLAKES: drifting 6-pointed snowflakes that fall with gentle sway and slow spin
    local function spawnSnowflake()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        local sz = math.random(14, 26)
        local container = Instance.new("Frame")
        container.BackgroundTransparency = 1
        container.ClipsDescendants = false
        container.Size = UDim2.fromOffset(sz, sz)
        container.AnchorPoint = Vector2.new(0.5, 0.5)
        container.Position = UDim2.fromOffset(math.random(10, W - 10), -sz)
        container.Rotation = math.random(0, 59)
        container.ZIndex = 4
        container.Parent = mParent

        local col = getParticleColor()
        local transp = math.random(5, 20) / 100

        local function makeArm(rot)
            local f = Instance.new("Frame")
            f.BackgroundColor3 = col
            f.BackgroundTransparency = transp
            f.BorderSizePixel = 0
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Size = UDim2.new(0.14, 0, 0.88, 0)
            f.Position = UDim2.new(0.5, 0, 0.5, 0)
            f.Rotation = rot
            f.ZIndex = 4
            f.Parent = container
            Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
        end

        makeArm(0) makeArm(60) makeArm(120)

        local dot = Instance.new("Frame")
        dot.BackgroundColor3 = col
        dot.BackgroundTransparency = transp
        dot.BorderSizePixel = 0
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Size = UDim2.new(0.28, 0, 0.28, 0)
        dot.Position = UDim2.new(0.5, 0, 0.5, 0)
        dot.ZIndex = 4
        dot.Parent = container
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

        table.insert(Hyperion._starFrames, container)
        table.insert(activeParticles, {
            type = "snowflake", frame = container, alive = true,
            x = math.random(10, W - 10), y = -sz,
            speed = math.random(20, 42),
            swayAmp = math.random(8, 20), swaySpeed = math.random(3, 8) / 10,
            rotSpeed = math.random(-20, 20),
            phase = math.random(0, 628) / 100, time = 0,
            alpha = transp,
            maxY = H + sz + 20, fadeStart = H * 0.72,
        })
    end

    -- GRIDLINES: horizontal cyan perspective lines that scroll up from the
    -- bottom and scale wider as they rise — the signature "vaporwave grid
    -- floor receding into the horizon" effect. (Vaporwave)
    local function spawnGridline()
        if not isAlive() then return end
        local W, H = getCanvasSize()
        -- Lines start near bottom (the "near" edge of the floor) and move UP.
        -- As they move up, they shrink in width and fade — giving the
        -- illusion of perspective receding toward a vanishing point.
        local startY = H - 4
        local endY   = H * 0.55  -- horizon line: top of the "floor"
        local line = Instance.new("Frame")
        line.BackgroundColor3 = color
        line.BackgroundTransparency = 0.25
        line.BorderSizePixel = 0
        -- Start wide, spanning most of the screen
        line.Size = UDim2.fromOffset(W + 40, 2)
        line.AnchorPoint = Vector2.new(0.5, 0.5)
        line.Position = UDim2.fromOffset(W * 0.5, startY)
        line.ZIndex = 2
        line.Parent = mParent
        -- Horizontal gradient so the line is brightest in the center and
        -- fades at the edges (looks more like a real light grid).
        local grad = Instance.new("UIGradient")
        grad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0,    0.85),
            NumberSequenceKeypoint.new(0.18, 0.15),
            NumberSequenceKeypoint.new(0.5,  0),
            NumberSequenceKeypoint.new(0.82, 0.15),
            NumberSequenceKeypoint.new(1,    0.85),
        })
        grad.Parent = line
        table.insert(Hyperion._starFrames, line)

        table.insert(activeParticles, {
            type = "gridline", frame = line, alive = true,
            y = startY, endY = endY, startY = startY,
            speed = math.random(38, 62),  -- px/sec upward
            startW = W + 40,
        })
    end

    -- DRAWN SHAPES (replaces the old emoji glyphs): built from Frames so they
    -- stay crisp at any size and match the rest of the particle set. They reuse
    -- the "snowflake" physics type, which drifts a container and fades its
    -- Frame children.
    local function _shape(parent2, col, transp, sx, sy, px, py, rot, corner)
        local f = Instance.new("Frame")
        f.BackgroundColor3 = col
        f.BackgroundTransparency = transp
        f.BorderSizePixel = 0
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Size = UDim2.new(sx, 0, sy, 0)
        f.Position = UDim2.new(px, 0, py, 0)
        f.Rotation = rot or 0
        f.ZIndex = 4
        f.Parent = parent2
        if corner then Instance.new("UICorner", f).CornerRadius = UDim.new(corner, 0) end
        return f
    end

    local function _shapeContainer(sz)
        local W, H = getCanvasSize()
        local c = Instance.new("Frame")
        c.BackgroundTransparency = 1
        c.ClipsDescendants = false
        c.Size = UDim2.fromOffset(sz, sz)
        c.AnchorPoint = Vector2.new(0.5, 0.5)
        c.Position = UDim2.fromOffset(math.random(10, math.max(11, W - 10)), -sz)
        c.Rotation = math.random(-14, 14)
        c.ZIndex = 4
        c.Parent = mParent
        return c, W, H
    end

    local function _shapeDrift(c, sz, H, transp, lo, hi)
        table.insert(Hyperion._starFrames, c)
        table.insert(activeParticles, {
            type = "snowflake", frame = c, alive = true,
            x = c.Position.X.Offset, y = -sz,
            speed = math.random(lo, hi),
            swayAmp = math.random(8, 22), swaySpeed = math.random(3, 9) / 10,
            rotSpeed = math.random(-18, 18),
            phase = math.random(0, 628) / 100, time = 0,
            alpha = transp,
            maxY = H + sz + 20, fadeStart = H * 0.72,
        })
    end

    -- HALLOWEEN: drawn pumpkin / ghost / bat
    local function spawnHalloween()
        if not isAlive() then return end
        local sz = math.random(18, 30)
        local c, _, H = _shapeContainer(sz)
        local tr = math.random(4, 16) / 100
        local pick = math.random(1, 3)
        if pick == 1 then
            local orange, dark = Color3.fromRGB(255, 140, 30), Color3.fromRGB(38, 16, 6)
            _shape(c, Color3.fromRGB(90, 160, 60), tr, 0.14, 0.22, 0.5, 0.12, 0, 0.4)
            _shape(c, orange, tr, 0.9, 0.76, 0.5, 0.58, 0, 0.5)
            _shape(c, dark, tr, 0.16, 0.16, 0.34, 0.5, 45, 0.15)
            _shape(c, dark, tr, 0.16, 0.16, 0.66, 0.5, 45, 0.15)
            _shape(c, dark, tr, 0.44, 0.1, 0.5, 0.72, 0, 0.4)
        elseif pick == 2 then
            local pale, dark = Color3.fromRGB(238, 242, 255), Color3.fromRGB(30, 20, 40)
            _shape(c, pale, tr, 0.72, 0.62, 0.5, 0.42, 0, 0.5)
            _shape(c, pale, tr, 0.72, 0.44, 0.5, 0.66, 0, 0.18)
            _shape(c, dark, tr, 0.13, 0.17, 0.38, 0.4, 0, 0.5)
            _shape(c, dark, tr, 0.13, 0.17, 0.62, 0.4, 0, 0.5)
        else
            local body = Color3.fromRGB(48, 32, 64)
            _shape(c, body, tr, 0.34, 0.4, 0.5, 0.5, 0, 0.5)
            _shape(c, body, tr, 0.42, 0.2, 0.2, 0.46, -18, 0.35)
            _shape(c, body, tr, 0.42, 0.2, 0.8, 0.46, 18, 0.35)
            _shape(c, body, tr, 0.1, 0.15, 0.42, 0.28, -20, 0.3)
            _shape(c, body, tr, 0.1, 0.15, 0.58, 0.28, 20, 0.3)
        end
        _shapeDrift(c, sz, H, tr, 24, 46)
    end

    -- STRAWBERRY: drawn berry with leaves + seeds
    local function spawnStrawberry()
        if not isAlive() then return end
        local sz = math.random(16, 26)
        local c, _, H = _shapeContainer(sz)
        local tr = math.random(4, 14) / 100
        local red   = Color3.fromRGB(240, 70, 95)
        local redDk = Color3.fromRGB(203, 42, 74)
        local leaf  = Color3.fromRGB(95, 175, 85)
        local seed  = Color3.fromRGB(255, 228, 175)
        _shape(c, red,   tr, 0.78, 0.66, 0.5, 0.5,  0, 0.5)
        _shape(c, redDk, tr, 0.46, 0.42, 0.5, 0.72, 0, 0.5)
        _shape(c, leaf,  tr, 0.5,  0.16, 0.5, 0.22, 0, 0.4)
        _shape(c, leaf,  tr, 0.34, 0.14, 0.38, 0.26, -28, 0.4)
        _shape(c, leaf,  tr, 0.34, 0.14, 0.62, 0.26,  28, 0.4)
        _shape(c, leaf,  tr, 0.08, 0.16, 0.5, 0.13, 0, 0.3)
        for _ = 1, 4 do
            _shape(c, seed, tr + 0.08, 0.07, 0.07,
                math.random(32, 68) / 100, math.random(42, 70) / 100, 0, 0.5)
        end
        _shapeDrift(c, sz, H, tr, 22, 40)
    end

    -- CHRISTMAS LIGHTS: strung wire with bulbs that glow and flicker.
    -- Built once as a decoration (not spawned on the particle timer); snow
    -- keeps falling underneath it.
    local function buildChristmasLights()
        if not isAlive() then return end
        local W = getCanvasSize()
        local COLORS = {
            Color3.fromRGB(255, 70, 70),  Color3.fromRGB(90, 200, 255),
            Color3.fromRGB(120, 230, 120), Color3.fromRGB(255, 200, 70),
            Color3.fromRGB(190, 120, 255),
        }
        for s = 1, 2 do
            local baseY = 4 + (s - 1) * 24
            local sag   = 24 + (s - 1) * 6
            local bulbs = math.max(6, math.floor(W / 64))
            local segs  = bulbs * 4
            local prevX, prevY
            for i = 0, segs do
                local t = i / segs
                local x = t * W
                local y = baseY + math.sin(t * math.pi) * sag
                if prevX then
                    local dx, dy = x - prevX, y - prevY
                    local wire = Instance.new("Frame")
                    wire.BackgroundColor3 = Color3.fromRGB(42, 46, 54)
                    wire.BackgroundTransparency = 0.15
                    wire.BorderSizePixel = 0
                    wire.AnchorPoint = Vector2.new(0.5, 0.5)
                    wire.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy) + 1, 2)
                    wire.Position = UDim2.fromOffset((prevX + x) / 2, (prevY + y) / 2)
                    wire.Rotation = math.deg(math.atan2(dy, dx))
                    wire.ZIndex = 3
                    wire.Parent = parent
                    table.insert(Hyperion._starFrames, wire)
                end
                prevX, prevY = x, y
            end
            for b = 1, bulbs do
                local t = (b - 0.5) / bulbs
                local x = t * W
                local y = baseY + math.sin(t * math.pi) * sag
                local col = COLORS[((b + s) % #COLORS) + 1]

                local cap = Instance.new("Frame")
                cap.BackgroundColor3 = Color3.fromRGB(72, 78, 88)
                cap.BorderSizePixel = 0
                cap.AnchorPoint = Vector2.new(0.5, 0)
                cap.Size = UDim2.fromOffset(4, 4)
                cap.Position = UDim2.fromOffset(x, y)
                cap.ZIndex = 4
                cap.Parent = parent
                Instance.new("UICorner", cap).CornerRadius = UDim.new(0, 1)
                table.insert(Hyperion._starFrames, cap)

                local glow = Instance.new("Frame")
                glow.BackgroundColor3 = col
                glow.BackgroundTransparency = 0.72
                glow.BorderSizePixel = 0
                glow.AnchorPoint = Vector2.new(0.5, 0)
                glow.Size = UDim2.fromOffset(22, 22)
                glow.Position = UDim2.fromOffset(x, y - 2)
                glow.ZIndex = 3
                glow.Parent = parent
                Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)
                table.insert(Hyperion._starFrames, glow)

                local bulb = Instance.new("Frame")
                bulb.BackgroundColor3 = col
                bulb.BackgroundTransparency = 0.05
                bulb.BorderSizePixel = 0
                bulb.AnchorPoint = Vector2.new(0.5, 0)
                bulb.Size = UDim2.fromOffset(8, 11)
                bulb.Position = UDim2.fromOffset(x, y + 3)
                bulb.ZIndex = 5
                bulb.Parent = parent
                Instance.new("UICorner", bulb).CornerRadius = UDim.new(0.5, 0)
                table.insert(Hyperion._starFrames, bulb)

                -- each bulb breathes on its own offset schedule
                task.spawn(function()
                    task.wait(math.random(0, 240) / 100)
                    while isAlive() and bulb.Parent do
                        local d1  = math.random(60, 170) / 100
                        local dim = math.random(35, 85) / 100
                        ts:Create(glow, TweenInfo.new(d1, Enum.EasingStyle.Sine),
                            { BackgroundTransparency = 0.55 + dim * 0.35 }):Play()
                        ts:Create(bulb, TweenInfo.new(d1, Enum.EasingStyle.Sine),
                            { BackgroundTransparency = dim * 0.45 }):Play()
                        task.wait(d1)
                        if not (isAlive() and bulb.Parent) then break end
                        local d2 = math.random(50, 140) / 100
                        ts:Create(glow, TweenInfo.new(d2, Enum.EasingStyle.Sine),
                            { BackgroundTransparency = 0.6 }):Play()
                        ts:Create(bulb, TweenInfo.new(d2, Enum.EasingStyle.Sine),
                            { BackgroundTransparency = 0.05 }):Play()
                        task.wait(d2)
                    end
                end)
            end
        end
    end

    -- Spawn function map
    local spawnFn = {
        stars = spawnStar, petals = spawnPetal, bubbles = spawnBubble,
        embers = spawnEmber, wisps = spawnWisp, orbs = spawnOrb,
        gridlines = spawnGridline, hearts = spawnHeart, paws = spawnPaw,
        snowflakes = spawnSnowflake,
        halloween = spawnHalloween, strawberry = spawnStrawberry,
        christmaslights = spawnSnowflake, -- snow falls under the light string
    }
    local spawnFunc = spawnFn[pStyle] or spawnStar

    -- One-time decorations (drawn once, not on the spawn timer)
    if pStyle == "christmaslights" then
        task.defer(function()
            task.wait(0.15) -- let the canvas resolve its AbsoluteSize first
            if isAlive() then buildChristmasLights() end
        end)
    end

    -- Spawn intervals per style
    local intervalRange = {
        stars = {14, 28}, petals = {3, 8}, bubbles = {4, 10},
        embers = {3, 7}, wisps = {10, 22}, orbs = {8, 18},
        gridlines = {6, 11},
        hearts = {4, 9},
        paws   = {5, 11},
        snowflakes = {4, 9},
        halloween = {6, 13},
        strawberry = {4, 9},
        christmaslights = {4, 9},
    }
    local iRange = intervalRange[pStyle] or {14, 28}

    -- Single Heartbeat drives all particles
    Hyperion._starConn = game:GetService("RunService").Heartbeat:Connect(function(dt)
        if not isAlive() then return end

        for i = #activeParticles, 1, -1 do
            local p = activeParticles[i]
            if not p.alive then table.remove(activeParticles, i); continue end

            if p.type == "star" then
                -- Falling star with tail
                if not p.tail or not p.tail.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.y = p.y + p.speed * dt
                p.tail.Position = UDim2.fromOffset(p.x, p.y)
                local headY = p.y + p.tailLen
                p.head.Position = UDim2.fromOffset(p.x, headY)
                p.glow.Position = UDim2.fromOffset(p.x, headY)
                if headY > p.fadeStart then
                    local t = math.clamp((headY - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.head.BackgroundTransparency = t
                    p.glow.BackgroundTransparency = 0.7 + t * 0.3
                    p.tail.BackgroundTransparency = t * 0.8
                end
                if headY > p.maxY then
                    p.alive = false
                    if p.tail.Parent then p.tail:Destroy() end
                    if p.glow.Parent then p.glow:Destroy() end
                    if p.head.Parent then p.head:Destroy() end
                end

            elseif p.type == "petal" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                p.frame.Rotation = p.frame.Rotation + p.rotSpeed * dt
                if p.y > p.fadeStart then
                    local t = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.frame.BackgroundTransparency = math.max(p.frame.BackgroundTransparency, t)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "bubble" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y - p.speed * dt  -- float UP
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                if p.y < p.minY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "ember" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                p.x = p.x + p.driftX * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                if p.y > p.fadeStart then
                    local t = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.frame.BackgroundTransparency = math.max(p.frame.BackgroundTransparency, t)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "wisp" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                if p.y > p.fadeStart then
                    local t = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.frame.BackgroundTransparency = math.min(0.95, 0.55 + t * 0.4)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "orb" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                p.x = p.x + p.driftX * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                if p.y > p.fadeStart then
                    local t = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.frame.BackgroundTransparency = math.min(0.95, 0.6 + t * 0.35)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "gridline" then
                -- Travel upward. Compute progress 0..1 from startY to endY,
                -- then shrink width + increase transparency so the line looks
                -- like it's receding into a vanishing point on the horizon.
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.y = p.y - p.speed * dt
                local W = mParent.AbsoluteSize.X
                if W < 10 then W = 880 end
                local t = math.clamp((p.startY - p.y) / math.max(1, p.startY - p.endY), 0, 1)
                -- At t=0 the line is at full width; at t=1 it's a pinprick at center
                local curW = math.max(2, (p.startW) * (1 - t * 0.92))
                p.frame.Size = UDim2.fromOffset(curW, 2)
                p.frame.Position = UDim2.fromOffset(W * 0.5, p.y)
                p.frame.BackgroundTransparency = math.min(0.95, 0.25 + t * 0.7)
                if p.y <= p.endY then
                    p.alive = false
                    if p.frame.Parent then p.frame:Destroy() end
                end

            elseif p.type == "heart" then
                -- Falling heart with sway + slow rotation (ImageLabel, so we
                -- use ImageTransparency, not BackgroundTransparency).
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                p.frame.Rotation = p.frame.Rotation + p.rotSpeed * dt
                if p.y > p.fadeStart then
                    local ft = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    p.frame.ImageTransparency = math.max(p.frame.ImageTransparency, ft)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "paw" then
                -- Falling paw print (Frame container) with sway + rotation.
                -- Children are Frames, so we fade via BackgroundTransparency on each.
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                p.frame.Rotation = p.frame.Rotation + p.rotSpeed * dt
                if p.y > p.fadeStart then
                    local ft = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    local newAlpha = math.max(p.alpha, ft)
                    for _, child in ipairs(p.frame:GetChildren()) do
                        if child:IsA("Frame") then
                            child.BackgroundTransparency = newAlpha
                        end
                    end
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "snowflake" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                p.frame.Rotation = p.frame.Rotation + p.rotSpeed * dt
                if p.y > p.fadeStart then
                    local ft = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                    local newAlpha = math.max(p.alpha, ft)
                    for _, child in ipairs(p.frame:GetChildren()) do
                        if child:IsA("Frame") then
                            child.BackgroundTransparency = newAlpha
                        end
                    end
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end

            elseif p.type == "emoji" then
                if not p.frame or not p.frame.Parent then p.alive = false; table.remove(activeParticles, i); continue end
                p.time = p.time + dt
                p.y = p.y + p.speed * dt
                local sx = p.x + math.sin(p.time * p.swaySpeed + p.phase) * p.swayAmp
                p.frame.Position = UDim2.fromOffset(sx, p.y)
                p.frame.Rotation = p.frame.Rotation + p.rotSpeed * dt
                if p.y > p.fadeStart then
                    p.frame.TextTransparency = math.clamp((p.y - p.fadeStart) / (p.maxY - p.fadeStart), 0, 1)
                end
                if p.y > p.maxY then p.alive = false; if p.frame.Parent then p.frame:Destroy() end end
            end
        end

        -- Spawn timing
        if not Hyperion._rainTimer then Hyperion._rainTimer = 0 end
        Hyperion._rainTimer = Hyperion._rainTimer + dt
        if not Hyperion._rainInterval then Hyperion._rainInterval = math.random(iRange[1], iRange[2]) / 10 end
        if Hyperion._rainTimer >= Hyperion._rainInterval then
            Hyperion._rainTimer = 0
            Hyperion._rainInterval = math.random(iRange[1], iRange[2]) / 10
            if parent and parent.Parent then
                spawnFunc()
                if math.random(1, 3) == 1 then
                    task.delay(math.random(1, 5) / 10, function()
                        if isAlive() then spawnFunc() end
                    end)
                end
            end
        end
    end)

    Hyperion._starActive = function()
        active = false
        activeParticles = {}
        Hyperion._rainTimer = 0
    end
end

-- Hook into SetTheme to start/stop animation
local _originalSetTheme = Hyperion.SetTheme
function Hyperion:SetTheme(nameOrTable)
    -- Resolve preset and stamp extras onto Hyperion.Theme BEFORE _originalSetTheme
    -- fires ThemeListeners, so every callback (ApplyWindowLogo, _titleGradient, etc.)
    -- already sees the new theme's values rather than the previous theme's stale ones.
    local preset = type(nameOrTable) == "string" and Hyperion.Themes[nameOrTable] or nameOrTable
    Hyperion.Theme.TitleGradient = preset and preset.TitleGradient or nil
    Hyperion.Theme.LogoGradient  = preset and preset.LogoGradient  or nil
    Hyperion.Theme.StarColors    = preset and preset.StarColors     or nil
    _originalSetTheme(self, nameOrTable)
    Hyperion._currentThemeName = type(nameOrTable) == "string" and nameOrTable or nil
    Hyperion._currentPreset = preset
    -- Update title text (e.g. cat ears for Neko)
    if Hyperion._titleLabel then
        local _tt = preset and preset.TitleText
        Hyperion._titleLabel.Text = _tt or (Hyperion._windowConfigTitle or "Hyperion")
    end
    -- Apply / clear background image
    local _bgImg  = preset and preset.BackgroundImage or nil
    local _bgTint = preset and preset.BackgroundTint
    if Hyperion._bgImageLabel then
        if _bgImg and _bgImg ~= "" then
            local imgId
            if type(_bgImg) == "number" then
                imgId = "rbxthumb://type=Asset&id=" .. _bgImg .. "&w=420&h=420"
            else
                local _id = tostring(_bgImg):match("rbxassetid://(%d+)")
                imgId = _id and ("rbxthumb://type=Asset&id=" .. _id .. "&w=420&h=420") or _bgImg
            end
            Hyperion._bgImageLabel.Image             = imgId
            Hyperion._bgImageLabel.ImageTransparency = 0
            Hyperion._bgImageLabel.ImageColor3       = Color3.new(1, 1, 1)
            Hyperion._bgImageLabel.Visible           = true
            if Hyperion._bgTintFrame then
                local ta = (_bgTint ~= nil) and _bgTint or 0.45
                Hyperion._bgTintFrame.BackgroundTransparency = 1 - ta
                Hyperion._bgTintFrame.Visible = ta > 0
            end
        else
            Hyperion._bgImageLabel.Visible = false
            if Hyperion._bgTintFrame then Hyperion._bgTintFrame.Visible = false end
        end
    end
    -- Apply gradient directly onto MainFrame's UIGradient
    if Hyperion._bgGradient then
        if preset and preset.Animated then
            -- UIGradient Color multiplies BackgroundColor3, so set BG to white
            -- and let the gradient provide ALL the color
            if Hyperion._mainFrame then
                Hyperion._mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            end
            if preset.GradientStops then
                -- Use custom multi-stop gradient
                local stops = {}
                for _, s in ipairs(preset.GradientStops) do
                    table.insert(stops, ColorSequenceKeypoint.new(s[1], s[2]))
                end
                Hyperion._bgGradient.Color = ColorSequence.new(stops)
            else
                -- Fallback: derive from GradientMid or Accent
                local bg  = preset.Background
                local mid = preset.GradientMid or preset.Accent
                local cx = math.clamp(bg.R * 0.2 + mid.R * 0.8, 0, 1)
                local cy = math.clamp(bg.G * 0.2 + mid.G * 0.8, 0, 1)
                local cz = math.clamp(bg.B * 0.2 + mid.B * 0.8, 0, 1)
                local ex = math.clamp(bg.R * 0.5 + mid.R * 0.5, 0, 1)
                local ey = math.clamp(bg.G * 0.5 + mid.G * 0.5, 0, 1)
                local ez = math.clamp(bg.B * 0.5 + mid.B * 0.5, 0, 1)
                Hyperion._bgGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    bg),
                    ColorSequenceKeypoint.new(0.2,  Color3.new(ex, ey, ez)),
                    ColorSequenceKeypoint.new(0.5,  Color3.new(cx, cy, cz)),
                    ColorSequenceKeypoint.new(0.8,  Color3.new(ex, ey, ez)),
                    ColorSequenceKeypoint.new(1,    bg),
                })
            end
        else
            local bg = Hyperion.Theme.Background
            -- Restore normal background color for non-animated themes
            if Hyperion._mainFrame then
                Hyperion._mainFrame.BackgroundColor3 = bg
            end
            Hyperion._bgGradient.Color = ColorSequence.new(bg, bg)
        end
    end
    -- Start/stop gradient rotation
    local fxOn = Hyperion.AnimatedEffects ~= false
    if Hyperion._startGradRot then
        if preset and preset.Animated and fxOn then
            Hyperion._startGradRot()
        else
            Hyperion._stopGradRot()
        end
    end
    if preset and preset.Animated and fxOn and Hyperion._starParent then
        _startStarfield(Hyperion._starParent, preset.StarColor, Hyperion._meteorParent, preset.ParticleStyle, preset.StarColors)
    else
        _stopStarfield()
    end
end

function Hyperion:SetAnimatedEffects(v)
    Hyperion.AnimatedEffects = v and true or false
    local cp = Hyperion._currentPreset
    if not cp then return end
    if v and cp.Animated then
        if Hyperion._startGradRot then Hyperion._startGradRot() end
        if Hyperion._starParent then _startStarfield(Hyperion._starParent, cp.StarColor, Hyperion._meteorParent, cp.ParticleStyle, cp.StarColors) end
    else
        if Hyperion._stopGradRot then Hyperion._stopGradRot() end
        _stopStarfield()
    end
end

----------------------------------------------------------------
-- UTILITY MODULE
----------------------------------------------------------------
local Util = {}

function Util.Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

function Util.Tween(obj, duration, props, style, direction)
    if not obj or not obj.Parent then return end
    local tween = TweenService:Create(
        obj,
        TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out),
        props
    )
    tween:Play()
    return tween
end

function Util.TweenFast(obj, props)
    return Util.Tween(obj, 0.12, props)
end

function Util.TweenSmooth(obj, props)
    return Util.Tween(obj, 0.28, props, Enum.EasingStyle.Quint)
end

-- Overshoot ("pop") for things that appear: cards, notifications, badges.
function Util.TweenPop(obj, props, duration)
    return Util.Tween(obj, duration or 0.22, props, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Fade a set of {instance, property} pairs in sequence, `gap` apart.
-- Used to cascade a panel's contents in instead of snapping them all at once.
function Util.Cascade(items, gap, duration)
    gap = gap or 0.045
    for i, it in ipairs(items) do
        local inst, prop, to = it[1], it[2], it[3] or 0
        if inst then
            task.delay((i - 1) * gap, function()
                if inst and inst.Parent then
                    Util.Tween(inst, duration or 0.22, { [prop] = to }, Enum.EasingStyle.Quint)
                end
            end)
        end
    end
end

----------------------------------------------------------------
-- TOOLTIPS
-- One shared bubble per ScreenGui. Sits above the hovered element,
-- flips below when there's no headroom, and clamps to the viewport.
-- Kept on Util (not new locals) to stay clear of the register budget.
----------------------------------------------------------------
Util._tip = { frame = nil, label = nil, stroke = nil, target = nil }

function Util._tipBuild(host)
    local t = Util._tip
    if t.frame and t.frame.Parent then return end
    local f = Util.Create("Frame", {
        Name = "HyperionTooltip",
        BackgroundColor3 = Hyperion.Theme.Surface,
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 900,
        Parent = host,
    })
    Util.AddCorner(f, Hyperion.Theme.CornerSmall)
    t.stroke = Util.AddStroke(f, Hyperion.Theme.BorderLight, 1, 0.35)
    Util.AddPadding(f, 5, 8, 5, 8)
    t.label = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.XY,
        Size = UDim2.new(0, 0, 0, 0),
        Text = "",
        TextColor3 = Hyperion.Theme.Text,
        TextTransparency = 1,
        FontFace = Hyperion.Theme.Font,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 901,
        Parent = f,
    })
    Util.Create("UISizeConstraint", { MaxSize = Vector2.new(190, math.huge), Parent = t.label })
    t.frame = f
end

Util._cp = { frame=nil, h=0, s=0, v=1, a=0, useAlpha=false,
             set=nil, setA=nil, owner=nil, onClose=nil, openedAt=0,
             svDrag=false, hueDrag=false, aDrag=false,
             awayConn=nil, posConn=nil }

function Util._cpBuild(host)
    local c = Util._cp
    if c.frame and c.frame.Parent then return end

    local T = Hyperion.Theme

    local f = Util.Create("Frame", {
        Name = "HyperionColorPopup", BackgroundColor3 = T.Surface,
        Size = UDim2.fromOffset(240, 186), Visible = false, BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 950, Parent = host,
    })
    Util.AddCorner(f, T.CornerSmall)
    c.stroke = Util.AddStroke(f, T.BorderLight, 1, 0.15)
    c.frame = f

    c.title = Util.Create("TextLabel", {
        Name = "Title", BackgroundTransparency = 1,
        Size = UDim2.new(1, -38, 0, 16), Position = UDim2.fromOffset(9, 8),
        Text = "Colour", TextColor3 = T.Text, FontFace = T.FontMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 952, Parent = f,
    })

    c.closeBtn = Util.Create("ImageButton", {
        Name = "Close", BackgroundTransparency = 1, Image = "rbxassetid://10747384394",
        ImageColor3 = T.TextMuted, ImageTransparency = 0.2,
        Size = UDim2.fromOffset(13, 13), Position = UDim2.new(1, -21, 0, 9),
        ScaleType = Enum.ScaleType.Fit, ZIndex = 953, Parent = f,
    })

    c.sv = Util.Create("ImageLabel", {
        Name = "SV", BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        Size = UDim2.fromOffset(202, 118), Position = UDim2.fromOffset(8, 30),
        Image = "rbxassetid://4155801252", BorderSizePixel = 0,
        ZIndex = 951, Parent = f,
    })
    Util.AddCorner(c.sv, UDim.new(0, 5))

    c.svPoint = Util.Create("Frame", {
        Name = "Point", BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromOffset(9, 9), AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0, ZIndex = 953, Parent = c.sv,
    })
    Util.AddCorner(c.svPoint, UDim.new(1, 0))
    c.svStroke = Util.AddStroke(c.svPoint, Color3.new(1, 1, 1), 2, 0)

    c.svHit = Util.Create("Frame", {
        Name = "SVHit", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        ZIndex = 954, Parent = c.sv,
    })

    c.hue = Util.Create("Frame", {
        Name = "Hue", BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromOffset(14, 118), Position = UDim2.fromOffset(218, 30),
        BorderSizePixel = 0, ZIndex = 951, Parent = f,
    })
    Util.AddCorner(c.hue, UDim.new(0, 4))
    Util.Create("UIGradient", { Rotation = 90, Parent = c.hue,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0,     Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,   Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,     Color3.fromRGB(255,0,0)),
        }),
    })
    c.hueKnob = Util.Create("Frame", {
        Name = "Knob", BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(1, 6, 0, 5), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 0), BorderSizePixel = 0,
        ZIndex = 953, Parent = c.hue,
    })
    Util.AddCorner(c.hueKnob, UDim.new(1, 0))
    Util.AddStroke(c.hueKnob, Color3.fromRGB(28, 28, 32), 1, 0.35)
    c.hueHit = Util.Create("Frame", {
        Name = "HueHit", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        ZIndex = 954, Parent = c.hue,
    })

    c.alphaBg = Util.Create("Frame", {
        Name = "AlphaBg", BackgroundColor3 = Color3.fromRGB(196, 196, 202),
        Size = UDim2.fromOffset(224, 12), Position = UDim2.fromOffset(8, 156),
        Visible = false, BorderSizePixel = 0, ZIndex = 951, Parent = f,
    })
    Util.AddCorner(c.alphaBg, UDim.new(0, 3))
    c.alphaFill = Util.Create("Frame", {
        Name = "Fill", BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.fromScale(1, 1), BorderSizePixel = 0,
        ZIndex = 952, Parent = c.alphaBg,
    })
    Util.AddCorner(c.alphaFill, UDim.new(0, 3))
    Util.Create("UIGradient", { Parent = c.alphaFill,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
    c.alphaKnob = Util.Create("Frame", {
        Name = "Knob", BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(0, 5, 1, 6), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0), BorderSizePixel = 0,
        ZIndex = 953, Parent = c.alphaBg,
    })
    Util.AddCorner(c.alphaKnob, UDim.new(1, 0))
    Util.AddStroke(c.alphaKnob, Color3.fromRGB(28, 28, 32), 1, 0.35)
    c.alphaHit = Util.Create("Frame", {
        Name = "AlphaHit", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
        ZIndex = 954, Parent = c.alphaBg,
    })

    c.hex = Util.Create("TextBox", {
        Name = "Hex", BackgroundColor3 = T.InputBg,
        Size = UDim2.fromOffset(224, 22), Position = UDim2.fromOffset(8, 156),
        Text = "", PlaceholderText = "#RRGGBB",
        TextColor3 = T.Text, PlaceholderColor3 = T.TextMuted,
        FontFace = T.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false, BorderSizePixel = 0, ZIndex = 952, Parent = f,
    })
    Util.AddCorner(c.hex, UDim.new(0, 4))
    c.hexStroke = Util.AddStroke(c.hex, T.Border, 1, 0.35)

    function c.layout(useAlpha)
        c.alphaBg.Visible = useAlpha
        local hexY = useAlpha and 176 or 156
        c.hex.Position = UDim2.fromOffset(8, hexY)
        c.frame.Size = UDim2.fromOffset(240, hexY + 30)
    end

    function c.sync()
        local t = Hyperion.Theme
        c.frame.BackgroundColor3 = t.Surface
        if c.stroke then c.stroke.Color = t.BorderLight end
        c.title.TextColor3 = t.Text
        c.title.FontFace = t.FontMedium
        c.closeBtn.ImageColor3 = t.TextMuted
        c.hex.BackgroundColor3 = t.InputBg
        c.hex.TextColor3 = t.Text
        c.hex.PlaceholderColor3 = t.TextMuted
        if c.hexStroke then c.hexStroke.Color = t.Border end
    end

    function c.commit(skipHex)
        local col = Color3.fromHSV(c.h, c.s, c.v)
        c.sv.BackgroundColor3 = Color3.fromHSV(c.h, 1, 1)
        c.svPoint.Position = UDim2.new(c.s, 0, 1 - c.v, 0)
        c.svPoint.BackgroundColor3 = col
        c.hueKnob.Position = UDim2.new(0.5, 0, c.h, 0)
        c.alphaFill.BackgroundColor3 = col
        c.alphaKnob.Position = UDim2.new(c.a, 0, 0.5, 0)

        local lum = 0.299 * col.R + 0.587 * col.G + 0.114 * col.B
        c.svStroke.Color = (lum > 0.55) and Color3.fromRGB(26, 26, 30) or Color3.new(1, 1, 1)

        if not skipHex then
            c.hex.Text = string.format("#%02X%02X%02X",
                math.floor(col.R * 255 + 0.5),
                math.floor(col.G * 255 + 0.5),
                math.floor(col.B * 255 + 0.5))
        end
        if c.set then c.set(col) end
    end

    function c.close()
        if not c.frame.Visible then return end
        c.svDrag, c.hueDrag, c.aDrag = false, false, false
        if c.awayConn then c.awayConn:Disconnect(); c.awayConn = nil end
        if c.posConn then c.posConn:Disconnect(); c.posConn = nil end
        local oc = c.onClose
        c.owner, c.onClose, c.set, c.setA = nil, nil, nil, nil
        Util.Tween(c.frame, 0.12, { Size = UDim2.fromOffset(0, 0) }, Enum.EasingStyle.Quint)
        task.delay(0.14, function()
            if not c.owner and c.frame then c.frame.Visible = false end
        end)
        if oc then task.spawn(oc) end
    end

    c.closeBtn.MouseButton1Click:Connect(function() c.close() end)

    c.hex.FocusLost:Connect(function()
        local str = tostring(c.hex.Text):gsub("%s", ""):gsub("^#", "")
        if #str == 3 then
            str = str:sub(1,1):rep(2) .. str:sub(2,2):rep(2) .. str:sub(3,3):rep(2)
        end
        if str:match("^%x%x%x%x%x%x$") then
            local nh, ns, nv = Color3.toHSV(Color3.fromRGB(
                tonumber(str:sub(1,2), 16), tonumber(str:sub(3,4), 16), tonumber(str:sub(5,6), 16)))
            if ns > 0.0001 then c.h = nh end
            c.s, c.v = ns, nv
        end
        c.commit()
    end)

    local function applySV(px, py)
        c.s = math.clamp((px - c.sv.AbsolutePosition.X) / math.max(c.sv.AbsoluteSize.X, 1), 0, 1)
        c.v = 1 - math.clamp((py - c.sv.AbsolutePosition.Y) / math.max(c.sv.AbsoluteSize.Y, 1), 0, 1)
        c.commit()
    end
    local function applyHue(py)
        c.h = math.clamp((py - c.hue.AbsolutePosition.Y) / math.max(c.hue.AbsoluteSize.Y, 1), 0, 1)
        c.commit()
    end
    local function applyAlpha(px)
        c.a = math.clamp((px - c.alphaBg.AbsolutePosition.X) / math.max(c.alphaBg.AbsoluteSize.X, 1), 0, 1)
        c.alphaKnob.Position = UDim2.new(c.a, 0, 0.5, 0)
        if c.setA then c.setA(c.a) end
    end

    c.svHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            c.svDrag = true
            applySV(i.Position.X, i.Position.Y)
        end
    end)
    c.hueHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            c.hueDrag = true
            applyHue(i.Position.Y)
        end
    end)
    c.alphaHit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            c.aDrag = true
            applyAlpha(i.Position.X)
        end
    end)

    if c.uisChanged then c.uisChanged:Disconnect() end
    if c.uisEnded then c.uisEnded:Disconnect() end

    c.uisChanged = UserInputService.InputChanged:Connect(function(i)
        if not c.frame.Visible then return end
        if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
        if c.svDrag then applySV(i.Position.X, i.Position.Y)
        elseif c.hueDrag then applyHue(i.Position.Y)
        elseif c.aDrag then applyAlpha(i.Position.X) end
    end)
    c.uisEnded = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            c.svDrag, c.hueDrag, c.aDrag = false, false, false
        end
    end)

    Hyperion:OnThemeChanged(function()
        if c.frame and c.frame.Parent then c.sync() end
    end)
end

function Util.AttachColorSwatch(swatch, getColor, setColor, opts)
    opts = opts or {}
    swatch.MouseButton1Click:Connect(function()
        local host = swatch:FindFirstAncestorWhichIsA("ScreenGui")
        if not host then return end
        Util._cpBuild(host)
        local c = Util._cp
        if not c.frame then return end
        if c.frame.Visible and c.owner == swatch then c.close() return end
        if c.frame.Visible then c.close() end

        c.owner    = swatch
        c.set      = setColor
        c.setA     = opts.SetAlpha
        c.onClose  = opts.OnClose
        c.useAlpha = opts.Alpha and true or false
        c.title.Text = opts.Title or "Colour"
        c.a = (opts.GetAlpha and opts.GetAlpha()) or 0

        local nh, ns, nv = Color3.toHSV(getColor() or Color3.new(1, 1, 1))
        if ns > 0.0001 then c.h = nh end
        c.s, c.v = ns, nv

        c.sync()
        c.layout(c.useAlpha)

        local hgt = c.frame.Size.Y.Offset
        local ap, asz = swatch.AbsolutePosition, swatch.AbsoluteSize
        local hp = host.AbsolutePosition
        local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
        local x = math.clamp(ap.X + asz.X - 240, 4, math.max(4, vp.X - 244))
        local y = ap.Y + asz.Y + 6
        if y + hgt > vp.Y - 4 then y = ap.Y - hgt - 6 end
        y = math.clamp(y, 4, math.max(4, vp.Y - hgt - 4))

        c.frame.Position = UDim2.fromOffset(x - hp.X, y - hp.Y)
        c.frame.Size = UDim2.fromOffset(0, 0)
        c.openedAt = os.clock()
        c.frame.Visible = true
        c.commit()
        if opts.OnOpen then task.spawn(opts.OnOpen) end
        Util.Tween(c.frame, 0.16, { Size = UDim2.fromOffset(240, hgt) }, Enum.EasingStyle.Quint)

        c.posConn = swatch:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if os.clock() - c.openedAt < 0.25 then return end
            c.close()
        end)
        c.awayConn = UserInputService.InputBegan:Connect(function(i)
            if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
            if not c.frame.Visible then return end
            if os.clock() - c.openedAt < 0.25 then return end
            local p = i.Position
            local fp, fs = c.frame.AbsolutePosition, c.frame.AbsoluteSize
            if p.X >= fp.X and p.X <= fp.X + fs.X and p.Y >= fp.Y and p.Y <= fp.Y + fs.Y then return end
            if c.owner then
                local op, os2 = c.owner.AbsolutePosition, c.owner.AbsoluteSize
                if p.X >= op.X and p.X <= op.X + os2.X and p.Y >= op.Y and p.Y <= op.Y + os2.Y then return end
            end
            c.close()
        end)
    end)
end

function Util.AttachTooltip(obj, text)
    if not obj or type(text) ~= "string" or text == "" then return end
    local hovering = false

    obj.MouseEnter:Connect(function()
        hovering = true
        task.delay(0.4, function()
            if not hovering or not obj.Parent then return end
            local host = obj:FindFirstAncestorWhichIsA("ScreenGui")
            if not host then return end
            Util._tipBuild(host)
            local t = Util._tip
            local f, l = t.frame, t.label
            if not f or not l then return end
            t.target = obj
            f.Parent = host
            l.Text = text
            -- resync to the live theme (bubble is created once, themes change)
            f.BackgroundColor3 = Hyperion.Theme.Surface
            l.TextColor3       = Hyperion.Theme.Text
            if t.stroke then t.stroke.Color = Hyperion.Theme.BorderLight end
            f.BackgroundTransparency = 1
            l.TextTransparency = 1
            f.Visible = true
            task.wait() -- let AutomaticSize resolve before measuring
            if t.target ~= obj or not obj.Parent then return end
            local ap, as = obj.AbsolutePosition, obj.AbsoluteSize
            local fs, hp = f.AbsoluteSize, host.AbsolutePosition
            local vp = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
            local x = ap.X + as.X / 2 - fs.X / 2
            local y = ap.Y - fs.Y - 6
            if y < 4 then y = ap.Y + as.Y + 6 end
            x = math.clamp(x, 4, math.max(4, vp.X - fs.X - 4))
            f.Position = UDim2.fromOffset(x - hp.X, (y - hp.Y) + 4)
            Util.Tween(f, 0.14, { BackgroundTransparency = 0.04 })
            Util.Tween(l, 0.14, { TextTransparency = 0 })
            Util.Tween(f, 0.18, { Position = UDim2.fromOffset(x - hp.X, y - hp.Y) }, Enum.EasingStyle.Quint)
        end)
    end)

    obj.MouseLeave:Connect(function()
        hovering = false
        local t = Util._tip
        if t.target ~= obj then return end
        t.target = nil
        local f, l = t.frame, t.label
        if not f or not l then return end
        Util.Tween(f, 0.1, { BackgroundTransparency = 1 })
        Util.Tween(l, 0.1, { TextTransparency = 1 })
        task.delay(0.12, function()
            if Util._tip.target == nil and f and f.Parent then f.Visible = false end
        end)
    end)
end

function Util.AddCorner(parent, radius)
    return Util.Create("UICorner", {CornerRadius = radius or Hyperion.Theme.CornerRadius, Parent = parent})
end

function Util.AddStroke(parent, color, thickness, transparency)
    return Util.Create("UIStroke", {
        Color = color or Hyperion.Theme.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

function Util.AddPadding(parent, t, r, b, l)
    return Util.Create("UIPadding", {
        PaddingTop    = UDim.new(0, t or 0),
        PaddingRight  = UDim.new(0, r or t or 0),
        PaddingBottom = UDim.new(0, b or t or 0),
        PaddingLeft   = UDim.new(0, l or r or t or 0),
        Parent = parent
    })
end

function Util.AddList(parent, dir, padding, hAlign, vAlign, sortOrder)
    return Util.Create("UIListLayout", {
        FillDirection       = dir or Enum.FillDirection.Vertical,
        Padding             = UDim.new(0, padding or 4),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = vAlign or Enum.VerticalAlignment.Top,
        SortOrder           = sortOrder or Enum.SortOrder.LayoutOrder,
        Parent = parent
    })
end

function Util.Ripple(button, color)
    local ripple = Util.Create("Frame", {
        Name = "Ripple",
        BackgroundColor3 = color or Hyperion.Theme.AccentLight,
        BackgroundTransparency = 0.65,
        Size = UDim2.new(0, 0, 0, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        ZIndex = button.ZIndex + 1,
        Parent = button
    })
    Util.AddCorner(ripple, UDim.new(1, 0))
    local maxSize = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.2
    Util.Tween(ripple, 0.45, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1})
    task.delay(0.5, function()
        if ripple and ripple.Parent then ripple:Destroy() end
    end)
end

-- Safe connection tracking
function Util.Connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(Hyperion.Connections, conn)
    return conn
end

----------------------------------------------------------------
-- NOTIFICATION SYSTEM
----------------------------------------------------------------
local NotifHolder

function Hyperion:_InitNotifications(parent)
    NotifHolder = Util.Create("Frame", {
        Name = _SafeGuiName(),
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 240, 1, 0),
        Position = UDim2.new(1, -252, 0, 0),
        ZIndex = 100,
        Parent = parent
    })
    Util.AddList(NotifHolder, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
    Util.AddPadding(NotifHolder, 0, 0, 20, 0)
end

Hyperion._notifIcons = {
    Info    = "rbxassetid://10723415903",
    Success = "rbxassetid://10709790644",
    Warning = "rbxassetid://10709752996",
    Error   = "rbxassetid://10747383819",
}
Hyperion._notifStack = {}

function Hyperion:Notify(config)
    config = config or {}
    local title    = config.Title or "Hyperion"
    local content  = config.Content or ""
    local nType    = config.Type or "Info"
    local duration = config.Duration
    if not duration then
        duration = math.clamp(2.2 + (#tostring(content) + #tostring(title)) / 26, 3, 10)
    end

    if not NotifHolder then return end

    local stack = Hyperion._notifStack
    while #stack >= 5 do
        local old = table.remove(stack, 1)
        if old then task.spawn(old) end
    end

    local Theme = Hyperion.Theme
    local accent = Theme.Accent
    if nType == "Info" then accent = Theme.Info
    elseif nType == "Success" then accent = Theme.Success
    elseif nType == "Warning" then accent = Theme.Warning
    elseif nType == "Error" then accent = Theme.Error end

    local notif = Util.Create("Frame", {
        Name             = "Notif",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        BorderSizePixel  = 0,
        ClipsDescendants = false,
        Parent           = NotifHolder,
    })

    local Card = Util.Create("Frame", {
        Name             = "Card",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        Position         = UDim2.new(0, 264, 0, 0),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = notif,
    })
    Util.AddCorner(Card, Theme.CornerSmall)
    Util.AddStroke(Card, Theme.BorderLight, 1, 0.25)
    Util.AddList(Card, Enum.FillDirection.Vertical, 0)

    local Row = Util.Create("TextButton", {
        Name             = "Row",
        BackgroundTransparency = 1,
        Text             = "",
        AutoButtonColor  = false,
        Size             = UDim2.new(1, 0, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        LayoutOrder      = 1,
        Parent           = Card,
    })
    Util.AddList(Row, Enum.FillDirection.Horizontal, 10)
    Util.AddPadding(Row, 10, 12, 10, 12)

    local IconCircle = Util.Create("Frame", {
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.82,
        Size             = UDim2.new(0, 28, 0, 28),
        BorderSizePixel  = 0,
        LayoutOrder      = 1,
        Parent           = Row,
    })
    Util.AddCorner(IconCircle, UDim.new(1, 0))
    Util.AddStroke(IconCircle, accent, 1, 0.6)

    local IconImg = Util.Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(0, 15, 0, 15),
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Image            = config.Image or Hyperion._notifIcons[nType] or Hyperion._notifIcons.Info,
        ImageColor3      = accent,
        ScaleType        = Enum.ScaleType.Fit,
        ZIndex           = 2,
        Parent           = IconCircle,
    })

    local TextStack = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -86, 0, 0),
        AutomaticSize    = Enum.AutomaticSize.Y,
        LayoutOrder      = 2,
        Parent           = Row,
    })
    Util.AddList(TextStack, Enum.FillDirection.Vertical, 2)

    local TitleLbl = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 16),
        Text             = title,
        TextColor3       = accent,
        FontFace         = Theme.FontBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        LayoutOrder      = 1,
        Parent           = TextStack,
    })

    local BodyLbl
    if content ~= "" then
        BodyLbl = Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size             = UDim2.new(1, 0, 0, 0),
            AutomaticSize    = Enum.AutomaticSize.Y,
            Text             = content,
            TextColor3       = Theme.TextDim,
            FontFace         = Theme.Font,
            TextSize         = 12,
            TextXAlignment   = Enum.TextXAlignment.Left,
            TextWrapped      = true,
            LayoutOrder      = 2,
            Parent           = TextStack,
        })
    end

    local CloseBtn = Util.Create("ImageButton", {
        Name             = "Close",
        BackgroundTransparency = 1,
        Image            = "rbxassetid://10747384394",
        ImageColor3      = Theme.TextMuted,
        ImageTransparency = 0.35,
        Size             = UDim2.new(0, 14, 0, 14),
        ScaleType        = Enum.ScaleType.Fit,
        LayoutOrder      = 3,
        Parent           = Row,
    })

    local BarTrack = Util.Create("Frame", {
        Name             = "Bar",
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.86,
        Size             = UDim2.new(1, 0, 0, 2),
        BorderSizePixel  = 0,
        LayoutOrder      = 2,
        Parent           = Card,
    })
    local BarFill = Util.Create("Frame", {
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.1,
        Size             = UDim2.new(1, 0, 1, 0),
        BorderSizePixel  = 0,
        Parent           = BarTrack,
    })

    local dead = false
    local barTween
    local dismiss
    dismiss = function()
        if dead then return end
        dead = true
        if barTween then pcall(function() barTween:Cancel() end) end
        for i = #stack, 1, -1 do
            if stack[i] == dismiss then table.remove(stack, i) break end
        end
        Util.Tween(Card, 0.26, {
            Position = UDim2.new(0, 264, 0, 0),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quint)
        Util.Tween(TitleLbl, 0.18, { TextTransparency = 1 })
        if BodyLbl then Util.Tween(BodyLbl, 0.18, { TextTransparency = 1 }) end
        Util.Tween(IconImg, 0.18, { ImageTransparency = 1 })
        Util.Tween(IconCircle, 0.18, { BackgroundTransparency = 1 })
        Util.Tween(CloseBtn, 0.18, { ImageTransparency = 1 })
        Util.Tween(BarFill, 0.18, { BackgroundTransparency = 1 })
        Util.Tween(BarTrack, 0.18, { BackgroundTransparency = 1 })
        task.delay(0.32, function()
            if notif and notif.Parent then notif:Destroy() end
        end)
    end
    stack[#stack + 1] = dismiss

    Card.BackgroundTransparency = 1
    IconCircle.BackgroundTransparency = 1
    IconImg.ImageTransparency = 1
    TitleLbl.TextTransparency = 1
    if BodyLbl then BodyLbl.TextTransparency = 1 end
    CloseBtn.ImageTransparency = 1
    BarTrack.BackgroundTransparency = 1
    BarFill.BackgroundTransparency = 1

    Util.Tween(Card, 0.34, { Position = UDim2.new(0, 0, 0, 0) },
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Util.Tween(Card, 0.22, { BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)

    local cascade = { { IconCircle, "BackgroundTransparency", 0.82 } }
    cascade[#cascade + 1] = { IconImg, "ImageTransparency", 0 }
    cascade[#cascade + 1] = { TitleLbl, "TextTransparency", 0 }
    if BodyLbl then cascade[#cascade + 1] = { BodyLbl, "TextTransparency", 0 } end
    cascade[#cascade + 1] = { CloseBtn, "ImageTransparency", 0.35 }
    cascade[#cascade + 1] = { BarTrack, "BackgroundTransparency", 0.86 }
    cascade[#cascade + 1] = { BarFill, "BackgroundTransparency", 0.1 }
    Util.Cascade(cascade, 0.05, 0.2)

    if duration > 0 then
        barTween = TweenService:Create(BarFill,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { Size = UDim2.new(0, 0, 1, 0) })
        barTween.Completed:Connect(function(state)
            if state == Enum.PlaybackState.Completed then dismiss() end
        end)
        task.delay(0.36, function()
            if not dead and barTween then barTween:Play() end
        end)
    else
        BarTrack.Visible = false
    end

    Row.MouseEnter:Connect(function()
        if dead then return end
        if barTween and barTween.PlaybackState == Enum.PlaybackState.Playing then
            barTween:Pause()
        end
        Util.TweenFast(CloseBtn, { ImageTransparency = 0 })
        Util.TweenFast(Card, { BackgroundColor3 = Hyperion.Theme.Surface })
    end)
    Row.MouseLeave:Connect(function()
        if dead then return end
        if barTween and barTween.PlaybackState == Enum.PlaybackState.Paused then
            barTween:Play()
        end
        Util.TweenFast(CloseBtn, { ImageTransparency = 0.35 })
        Util.TweenFast(Card, { BackgroundColor3 = Hyperion.Theme.Background })
    end)
    Row.MouseButton1Click:Connect(function()
        if config.Callback then task.spawn(config.Callback) end
        dismiss()
    end)
    CloseBtn.MouseButton1Click:Connect(dismiss)

    return { Dismiss = dismiss }
end

----------------------------------------------------------------
-- CONFIG SYSTEM
----------------------------------------------------------------
local Config = {}

function Config.EnsureFolder()
    if not _rawIsfolder("Hyperion") then pcall(_rawMakefolder, "Hyperion") end
    if not _rawIsfolder("Hyperion/Configs") then pcall(_rawMakefolder, "Hyperion/Configs") end
end

function Config.Save(name, flags)
    Config.EnsureFolder()
    local data = {}
    for flag, value in pairs(flags) do
        local t = typeof(value)
        if t == "Color3" then
            data[flag] = {_t = "Color3", R = value.R, G = value.G, B = value.B}
        elseif t == "EnumItem" then
            data[flag] = {_t = "Enum", V = tostring(value)}
        elseif type(value) == "table" then
            data[flag] = {_t = "Table", V = value}
        elseif type(value) == "boolean" or type(value) == "number" or type(value) == "string" then
            data[flag] = {_t = type(value), V = value}
        end
    end
    local okEnc, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if not okEnc then
        return false, "encode failed: " .. tostring(encoded)
    end
    local path = "Hyperion/Configs/" .. name .. ".json"
    -- Retry folder creation immediately before write, in case an earlier
    -- makefolder silently failed or the folder was removed.
    if not _rawIsfolder("Hyperion") then pcall(_rawMakefolder, "Hyperion") end
    if not _rawIsfolder("Hyperion/Configs") then pcall(_rawMakefolder, "Hyperion/Configs") end
    -- Use the raw (pre-hook) writefile clone. This means even if the
    -- consuming script has installed a broken writefile hook, our save
    -- bypasses it and writes directly.
    local okWrite, writeErr = pcall(_rawWritefile, path, encoded)
    if not okWrite then
        return false, "write failed: " .. tostring(writeErr)
    end
    -- Verify the file actually landed on disk. Some executors silently no-op
    -- writefile when the target path contains characters they don't handle,
    -- or when workspace resolution fails.
    if not _rawIsfile(path) then
        return false, "file not present after write"
    end
    return true
end

function Config.Load(name, flags, callbacks)
    Config.EnsureFolder()
    local path = "Hyperion/Configs/" .. name .. ".json"
    if not _rawIsfile(path) then return false end
    local ok, raw = pcall(_rawReadfile, path)
    if not ok then return false end
    local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
    if not ok2 or type(data) ~= "table" then return false end
    for flag, info in pairs(data) do
        if type(info) ~= "table" then continue end
        if info._t == "Color3" then
            flags[flag] = Color3.new(info.R or 1, info.G or 1, info.B or 1)
        elseif info._t == "Enum" and info.V then
            -- Restore EnumItem from its string representation
            local ok3, enumVal = pcall(function()
                local parts = string.split(tostring(info.V), ".")
                if #parts == 3 then
                    return Enum[parts[2]][parts[3]]
                end
            end)
            if ok3 and enumVal then flags[flag] = enumVal end
        elseif info._t == "Table" then
            flags[flag] = info.V
        elseif info._t == "boolean" or info._t == "number" or info._t == "string" then
            flags[flag] = info.V
        end
        -- Fire callbacks to update UI visuals
        if callbacks and callbacks[flag] then
            task.spawn(callbacks[flag], flags[flag])
        end
    end
    return true
end

function Config.List()
    Config.EnsureFolder()
    local out = {}
    local ok, files = pcall(_rawListfiles, "Hyperion/Configs")
    if ok then
        for _, f in ipairs(files) do
            local n = string.match(f, "([^/\\]+)%.json$")
            if n then table.insert(out, n) end
        end
    end
    return out
end

function Config.Delete(name)
    Config.EnsureFolder()
    local path = "Hyperion/Configs/" .. name .. ".json"
    if not _rawIsfile(path) then return false end
    local removeFn = (typeof(delfile) == "function" and delfile)
        or (typeof(fremovefile) == "function" and fremovefile)
        or nil
    if removeFn then
        pcall(removeFn, path)
    end
    return true
end

----------------------------------------------------------------
-- GLOBAL INPUT POOLING (avoids hundreds of InputChanged connections)
----------------------------------------------------------------

-- AutoLoad: call after all elements are built to restore a config silently.
-- Respects the ConfigSystem toggle: if disabled, this is a no-op.
function Hyperion:AutoLoad(name)
    name = name or "default"
    if Hyperion._configEnabled == false then return false end
    if _rawIsfile("Hyperion/Configs/" .. name .. ".json") then
        Config.Load(name, Hyperion.Flags, Hyperion.FlagCallbacks)
        return true
    end
    return false
end

-- AutoSave: saves current flags under the given name (default "default").
-- Respects the ConfigSystem toggle: if disabled, this is a no-op.
function Hyperion:AutoSave(name)
    if Hyperion._configEnabled == false then return false end
    return Config.Save(name or "default", Hyperion.Flags)
end

-- Manually load a config by name (also respects the ConfigSystem toggle).
function Hyperion:LoadConfig(name)
    if Hyperion._configEnabled == false then return false end
    return Config.Load(name or "default", Hyperion.Flags, Hyperion.FlagCallbacks)
end

-- Manually save a config by name (also respects the ConfigSystem toggle).
function Hyperion:SaveConfig(name)
    if Hyperion._configEnabled == false then return false end
    return Config.Save(name or "default", Hyperion.Flags)
end

-- Return the list of saved config names.
function Hyperion:ListConfigs()
    return Config.List()
end

-- Delete a saved config by name.
function Hyperion:DeleteConfig(name)
    if not name or name == "" then return false end
    return Config.Delete(name)
end

-- Toggle the config system on/off at runtime. When disabled:
--   • The in-window "Config" (folder) button is hidden.
--   • Hyperion:SaveConfig / :LoadConfig / :AutoLoad / :AutoSave become no-ops.
-- All listeners registered via Hyperion:OnConfigEnabledChanged are notified.
Hyperion._configListeners = Hyperion._configListeners or {}

function Hyperion:SetConfigEnabled(enabled)
    enabled = enabled and true or false
    if Hyperion._configEnabled == enabled then return end
    Hyperion._configEnabled = enabled
    for _, fn in ipairs(Hyperion._configListeners) do
        pcall(fn, enabled)
    end
end

function Hyperion:EnableConfig()  self:SetConfigEnabled(true)  end
function Hyperion:DisableConfig() self:SetConfigEnabled(false) end

function Hyperion:IsConfigEnabled()
    return Hyperion._configEnabled ~= false
end

function Hyperion:OnConfigEnabledChanged(fn)
    table.insert(Hyperion._configListeners, fn)
    return function()
        for i, v in ipairs(Hyperion._configListeners) do
            if v == fn then table.remove(Hyperion._configListeners, i); break end
        end
    end
end

local InputPool = {
    SliderCallbacks = {},
    ColorCallbacks  = {},
}

Util.Connect(UserInputService.InputChanged, function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        for _, cb in ipairs(InputPool.SliderCallbacks) do
            cb(input)
        end
        for _, cb in ipairs(InputPool.ColorCallbacks) do
            cb(input)
        end
    end
end)

----------------------------------------------------------------
-- CREATE WINDOW
----------------------------------------------------------------
function Hyperion:CreateWindow(config)
    config = config or {}
    pcall(function() Hyperion:PreloadAssets(config.PreloadAssets) end)
    local windowConfig = {
        Title    = config.Title or "Hyperion",
        Logo     = config.Logo or "rbxassetid://134963728913547",
        Size     = config.Size or UDim2.new(0, 880, 0, 600),
        Keybind  = config.Keybind or Enum.KeyCode.RightControl,
        Theme    = config.Theme or {},
        -- Key system
        Key      = config.Key,        -- string or table of valid keys
        KeySave  = config.KeySave ~= false, -- save key to file so user only enters once (default true)
        KeyTitle = config.KeyTitle or "Key Required",
        KeySub   = config.KeySub   or "Enter your access key to continue.",
        -- Config system
        -- ConfigSystem:  true (default)  -> config panel + button available
        --                false           -> config button hidden, UI config panel disabled
        -- ConfigAutoLoad: true (default) -> automatically load the AutoLoadName config after
        --                                   all tabs/elements are built
        --                 false          -> do not restore saved flags on startup
        -- AutoLoadName:  file name to load/save for autoload ("default" if omitted)
        ConfigSystem   = config.ConfigSystem ~= false,
        ConfigAutoLoad = config.ConfigAutoLoad ~= false,
        AutoLoadName   = config.AutoLoadName or config.ConfigName or "default",
    }
    -- Expose the current ConfigSystem state library-wide so Save/Load/AutoLoad
    -- can honor it even if called externally.
    Hyperion._configEnabled = windowConfig.ConfigSystem

    -- Apply theme overrides
    for k, v in pairs(windowConfig.Theme) do
        Hyperion.Theme[k] = v
    end
    local Theme = Hyperion.Theme

    -- Window object
    local WindowObj = {}
    local _px = {}
    WindowObj.Tabs      = {}
    WindowObj.ActiveTab = nil
    WindowObj.Flags     = Hyperion.Flags
    WindowObj.Visible   = true
    WindowObj.MinSize   = config.MinSize or UDim2.new(0, 560, 0, 380)
    WindowObj.CurrentSize = windowConfig.Size

    -- Themed(instance, propMap) — registers an instance so its properties
    -- are updated automatically whenever SetTheme() is called.
    -- propMap: { PropertyName = function(theme) return value end }
    -- Example: Themed(frame, { BackgroundColor3 = function(t) return t.Surface end })
    local function Themed(instance, propMap)
        Hyperion:OnThemeChanged(function(t)
            if not instance or not instance.Parent then return end
            for prop, fn in pairs(propMap) do
                pcall(function() instance[prop] = fn(t) end)
            end
        end)
    end

    local function ApplyThemeNow(instance, propMap)
        if not instance or not instance.Parent then return end
        local t = Hyperion.Theme
        for prop, fn in pairs(propMap) do
            pcall(function() instance[prop] = fn(t) end)
        end
    end

    -- ScreenGui
    local ScreenGui = Util.Create("ScreenGui", {
        Name = _SafeGuiName(),
        ResetOnSpawn    = false,
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        DisplayOrder    = 0,
        IgnoreGuiInset  = true,
    })
    pcall(protect_gui, ScreenGui)
    ScreenGui.Parent = CoreGui

    local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    local MobileToggleButton = Util.Create("TextButton", {
        Name = "MobileToggleButton",
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.08,
        Size = UDim2.new(0, 46, 0, 46),
        Position = UDim2.new(0, 14, 1, -60),
        BorderSizePixel = 0,
        Text = "H",
        TextColor3 = Theme.Text,
        FontFace = Theme.FontBold,
        TextSize = 16,
        AutoButtonColor = false,
        Visible = true,
        ZIndex = 150,
        Parent = ScreenGui
    })
    Util.AddCorner(MobileToggleButton, UDim.new(1, 0))
    local _mobileStroke = Util.AddStroke(MobileToggleButton, Theme.BorderLight, 1, 0.1)
    Themed(MobileToggleButton, {
        BackgroundColor3 = function(t) return t.Surface end,
        TextColor3 = function(t) return t.Text end,
    })
    Themed(_mobileStroke, { Color = function(t) return t.BorderLight end })

    local MobileAccent = Util.Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.15,
        Size = UDim2.new(0, 14, 0, 3),
        Position = UDim2.new(0.5, -7, 1, -9),
        BorderSizePixel = 0,
        ZIndex = 151,
        Parent = MobileToggleButton
    })
    Util.AddCorner(MobileAccent, UDim.new(1, 0))
    Themed(MobileAccent, { BackgroundColor3 = function(t) return t.Accent end })

    -- Notifications
    Hyperion:_InitNotifications(ScreenGui)

    -- Loading screen
    -- ============================================================
    -- LOADING SCREEN
    -- ============================================================
    local LoadingOverlay = Util.Create("Frame", {
        Name             = "LoadingOverlay",
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0,
        Size             = UDim2.new(1, 0, 1, 0),
        BorderSizePixel  = 0,
        ZIndex           = 200,
        Parent           = ScreenGui,
    })
    local LoadingOverlayGradient = Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 8, 36)),
            ColorSequenceKeypoint.new(0.45, Color3.fromRGB(42, 16, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 50, 190)),
        }),
        Rotation = 35,
        Parent = LoadingOverlay,
    })

    -- Radial vignette
    local LoadingVignette = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(0,0,0),
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        BorderSizePixel = 0,
        ZIndex = 201,
        Parent = LoadingOverlay,
    })
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(0.6, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.55, 0.6),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent = LoadingVignette,
    })

    local hasLogo = windowConfig.Logo ~= nil

    -- Center card
    local LoadingPanel = Util.Create("Frame", {
        BackgroundColor3 = Theme.Surface,
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, 0, 0.52, 0),
        Size             = UDim2.new(0, 340, 0, 150),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ZIndex           = 202,
        Parent           = LoadingOverlay,
    })
    Util.AddCorner(LoadingPanel, Theme.CornerLarge)
    Util.AddStroke(LoadingPanel, Theme.BorderLight, 1, 0.15)

    -- Bottom accent gradient line
    local AccentBar = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(0, 0, 0, 1),   -- animates width in
        Position = UDim2.new(0.5, 0, 1, -1),
        AnchorPoint = Vector2.new(0.5, 0),
        BorderSizePixel = 0, ZIndex = 204,
        Parent = LoadingPanel,
    })
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentDark),
            ColorSequenceKeypoint.new(0.5, Theme.AccentLight),
            ColorSequenceKeypoint.new(1, Theme.AccentDark),
        }),
        Parent = AccentBar,
    })

    -- Logo (large, centered above title)
    local LoadingLogo = Util.Create("ImageLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position    = UDim2.new(0.5, 0, 0.34, 0),
        Size        = UDim2.new(0, 78, 0, 78),
        Image       = windowConfig.Logo or "",
        ImageColor3 = Theme.Accent,
        ImageTransparency = 1,
        ScaleType   = Enum.ScaleType.Fit,
        Visible     = hasLogo,
        ZIndex      = 203,
        Parent      = LoadingPanel,
    })

    local LoadingPulseActive = true
    task.spawn(function()
        if not hasLogo then return end
        while LoadingPulseActive and LoadingLogo and LoadingLogo.Parent do
            Util.Tween(LoadingLogo, 0.9, {
                Size = UDim2.new(0, 84, 0, 84),
                ImageTransparency = 0.08,
            }, Enum.EasingStyle.Sine)
            task.wait(0.95)
            if not LoadingPulseActive then break end
            Util.Tween(LoadingLogo, 0.9, {
                Size = UDim2.new(0, 78, 0, 78),
                ImageTransparency = 0.18,
            }, Enum.EasingStyle.Sine)
            task.wait(0.95)
        end
    end)

    local titleX = 0

    local LoadingTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position  = UDim2.new(0.5, 0, 0, 74),
        Size      = UDim2.new(1, -24, 0, 24),
        Text      = windowConfig.Title,
        TextColor3 = Theme.Text,
        FontFace  = Theme.FontBold,
        TextSize  = 22,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 203,
        Parent    = LoadingPanel,
    })

    local LoadingSub = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(0.5, 0),
        Position  = UDim2.new(0.5, 0, 0, 100),
        Size      = UDim2.new(1, -24, 0, 14),
        Text      = "Loading interface...",
        TextColor3 = Theme.TextMuted,
        FontFace  = Theme.Font,
        TextSize  = 11,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex    = 203,
        Parent    = LoadingPanel,
    })

    local LoadingTrack = Util.Create("Frame", {
        BackgroundColor3 = Theme.InputBg,
        Position  = UDim2.new(0, 22, 1, -24),
        Size      = UDim2.new(1, -44, 0, 4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex    = 203,
        Parent    = LoadingPanel,
    })
    Util.AddCorner(LoadingTrack, UDim.new(1, 0))

    local LoadingFill = Util.Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        Size      = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex    = 204,
        Parent    = LoadingTrack,
    })
    Util.AddCorner(LoadingFill, UDim.new(1, 0))
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentDark),
            ColorSequenceKeypoint.new(1, Theme.AccentLight),
        }),
        Parent = LoadingFill,
    })

    -- ============================================================
    -- KEY SYSTEM (optional)
    -- ============================================================
    -- Validate a key attempt against config.Key (string or table)
    local function IsValidKey(attempt)
        local k = windowConfig.Key
        if type(k) == "string" then
            return attempt == k
        elseif type(k) == "table" then
            for _, v in ipairs(k) do
                if attempt == v then return true end
            end
        end
        return false
    end

    -- Check if key was already saved to disk
    local keyFile = "Hyperion/key.dat"
    local keyAlreadySaved = false
    if windowConfig.Key and windowConfig.KeySave then
        local ok, saved = pcall(readfile, keyFile)
        if ok and saved ~= "" and IsValidKey(saved) then
            keyAlreadySaved = true
        end
    end

    -- Key UI elements (only built when needed)
    local KeyInput, KeyVerifyBtn, KeyStatusLbl, KeyBox
    local keyVerified = (not windowConfig.Key) or keyAlreadySaved
    local keyResolved = false  -- signals the loader to continue

    if windowConfig.Key and not keyAlreadySaved then
        -- Resize panel to fit key input
        LoadingPanel.Size = UDim2.new(0, 340, 0, 200)

        KeyBox = Util.Create("Frame", {
            BackgroundColor3 = Theme.InputBg,
            Position = UDim2.new(0, 18, 1, -80),
            Size = UDim2.new(1, -36, 0, 34),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 205,
            Visible = false,
            Parent = LoadingPanel,
        })
        Util.AddCorner(KeyBox, Theme.CornerSmall)
        Util.AddStroke(KeyBox, Theme.Border, 1, 0.3)

        KeyInput = Util.Create("TextBox", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -44, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            Text = "",
            PlaceholderText = "Enter key...",
            TextColor3 = Theme.Text,
            PlaceholderColor3 = Theme.TextMuted,
            FontFace = Theme.Font,
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 206,
            Parent = KeyBox,
        })

        KeyVerifyBtn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 34, 0, 34),
            Position = UDim2.new(1, 0, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = "→",
            TextColor3 = Color3.new(1,1,1),
            FontFace = Theme.FontBold,
            TextSize = 14,
            AutoButtonColor = false,
            ZIndex = 206,
            Parent = KeyBox,
        })
        Util.AddCorner(KeyVerifyBtn, Theme.CornerSmall)

        KeyStatusLbl = Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 18, 1, -40),
            Size = UDim2.new(1, -36, 0, 14),
            Text = "",
            TextColor3 = Theme.Error,
            FontFace = Theme.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextTransparency = 1,
            ZIndex = 205,
            Parent = LoadingPanel,
        })

        -- Shake animation on wrong key
        local function ShakePanel()
            local orig = LoadingPanel.Position
            for i = 1, 4 do
                local dir = (i % 2 == 0) and 8 or -8
                Util.Tween(LoadingPanel, 0.04, {Position = UDim2.new(orig.X.Scale, orig.X.Offset + dir, orig.Y.Scale, orig.Y.Offset)}, Enum.EasingStyle.Linear)
                task.wait(0.05)
            end
            Util.Tween(LoadingPanel, 0.08, {Position = orig}, Enum.EasingStyle.Linear)
        end

        local function TryKey()
            local attempt = KeyInput.Text
            if IsValidKey(attempt) then
                -- Save to disk if KeySave enabled
                if windowConfig.KeySave then
                    pcall(makefolder, "Hyperion")
                    pcall(writefile, keyFile, attempt)
                end
                keyVerified = true
                keyResolved = true
                -- Green flash
                KeyStatusLbl.Text = "✓ Access granted"
                KeyStatusLbl.TextColor3 = Theme.Success
                Util.Tween(KeyStatusLbl, 0.2, {TextTransparency = 0}, Enum.EasingStyle.Quint)
                Util.Tween(KeyBox, 0.2, {BackgroundColor3 = Color3.fromRGB(30, 60, 35)})
            else
                -- Red flash + shake
                task.spawn(ShakePanel)
                KeyStatusLbl.Text = "✗ Invalid key"
                KeyStatusLbl.TextColor3 = Theme.Error
                Util.Tween(KeyStatusLbl, 0.15, {TextTransparency = 0}, Enum.EasingStyle.Quint)
                task.delay(1.8, function()
                    Util.Tween(KeyStatusLbl, 0.3, {TextTransparency = 1}, Enum.EasingStyle.Quint)
                end)
                Util.Tween(KeyBox, 0.15, {BackgroundColor3 = Color3.fromRGB(50, 20, 22)})
                task.delay(0.6, function()
                    Util.Tween(KeyBox, 0.3, {BackgroundColor3 = Theme.InputBg})
                end)
            end
        end

        KeyVerifyBtn.MouseButton1Click:Connect(TryKey)
        KeyInput.FocusLost:Connect(function(enterPressed)
            if enterPressed then TryKey() end
        end)
    end

    -- ============================================================
    -- LOADING ANIMATION
    -- ============================================================
    task.spawn(function()
        -- Phase 1: card rises and fades in
        Util.Tween(LoadingPanel, 0.5, {
            BackgroundTransparency = 0,
            Position = UDim2.new(0.5, 0, 0.5, 0),
        }, Enum.EasingStyle.Quint)
        task.wait(0.08)
        if hasLogo then
            Util.Tween(LoadingLogo, 0.5, {
                ImageTransparency = 0.12,
                Size = UDim2.new(0, 82, 0, 82)
            }, Enum.EasingStyle.Quint)
        end
        task.wait(0.08)
        Util.Tween(LoadingTitle, 0.4, {TextTransparency = 0}, Enum.EasingStyle.Quint)
        task.wait(0.08)

        if windowConfig.Key and not keyAlreadySaved then
            -- Show key prompt instead of "Loading interface..."
            LoadingSub.Text = windowConfig.KeyTitle
            LoadingSub.TextColor3 = Theme.TextDim
            Util.Tween(LoadingSub, 0.35, {TextTransparency = 0}, Enum.EasingStyle.Quint)
            task.wait(0.25)
            -- Reveal key input box
            if KeyBox then
                KeyBox.Visible = true
                KeyBox.BackgroundTransparency = 1
                Util.Tween(KeyBox, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint)
            end
            -- Wait for the player to enter a valid key
            while not keyResolved do
                task.wait(0.05)
            end
            task.wait(0.4)  -- brief pause after success
            -- Hide key UI
            if KeyBox then Util.Tween(KeyBox, 0.2, {BackgroundTransparency = 1}) end
            if KeyStatusLbl then Util.Tween(KeyStatusLbl, 0.2, {TextTransparency = 1}) end
            task.wait(0.15)
            -- Switch sub label to loading
            LoadingSub.Text = "Loading interface..."
            LoadingSub.TextColor3 = Theme.TextMuted
        else
            Util.Tween(LoadingSub, 0.35, {TextTransparency = 0.15}, Enum.EasingStyle.Quint)
        end
        task.wait(0.3)

        -- Phase 2: accent bar + progress
        Util.Tween(AccentBar, 0.75, {Size = UDim2.new(0.92, 0, 0, 1)}, Enum.EasingStyle.Quint)
        task.wait(0.2)
        Util.Tween(LoadingTrack, 0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint)
        Util.Tween(LoadingFill,  0.3, {BackgroundTransparency = 0}, Enum.EasingStyle.Quint)
        task.wait(0.15)
        Util.Tween(LoadingFill, 1.8, {Size = UDim2.new(1, 0, 1, 0)}, Enum.EasingStyle.Quint)
        task.wait(2.0)

        -- Phase 3: smooth exit
        LoadingPulseActive = false
        Util.Tween(LoadingPanel, 0.5, {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.46, 0),
        }, Enum.EasingStyle.Quint)
        Util.Tween(LoadingTitle, 0.35, {TextTransparency = 1}, Enum.EasingStyle.Quint)
        Util.Tween(LoadingSub,   0.28, {TextTransparency = 1}, Enum.EasingStyle.Quint)
        Util.Tween(LoadingTrack, 0.28, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
        Util.Tween(LoadingFill,  0.28, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
        if hasLogo then
            Util.Tween(LoadingLogo, 0.35, {ImageTransparency = 1}, Enum.EasingStyle.Quint)
        end
        task.wait(0.12)
        Util.Tween(LoadingOverlay, 0.5, {BackgroundTransparency = 1}, Enum.EasingStyle.Quint)
        task.wait(0.7)
        if LoadingOverlay and LoadingOverlay.Parent then
            LoadingOverlay:Destroy()
        end
    end)

    -- ============================================================
    -- MAIN FRAME
    -- ============================================================
    local MainFrame = Util.Create("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        Size = windowConfig.Size,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        ClipsDescendants = false,
        Parent = ScreenGui
    })
    Util.AddCorner(MainFrame, Theme.CornerLarge)
    local _mfStroke = Util.AddStroke(MainFrame, Theme.Border, 1, 0.2)
    Themed(MainFrame, { BackgroundColor3 = function(t)
        -- If animated theme, gradient provides color; MainFrame needs white bg
        local preset = Hyperion._currentThemeName and Hyperion.Themes[Hyperion._currentThemeName]
        if preset and preset.Animated then
            return Color3.new(1, 1, 1)
        end
        return t.Background
    end })
    Themed(_mfStroke, { Color = function(t) return t.Border end })

    -- Register this window's background as the star canvas
    -- Use a clipping frame so stars don't bleed outside the window rounded corners
    local StarCanvas = Util.Create("Frame", {
        Name = "StarCanvas",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 1,
        ClipsDescendants = true,
        Parent = MainFrame,
    })
    Util.AddCorner(StarCanvas, Theme.CornerLarge)

    -- Separate high-ZIndex canvas for falling meteors so they appear in front of all UI
    local MeteorCanvas = Util.Create("Frame", {
        Name = "MeteorCanvas",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        ZIndex = 50,
        ClipsDescendants = true,
        Parent = MainFrame,
    })
    Util.AddCorner(MeteorCanvas, Theme.CornerLarge)

    Hyperion._starParent  = StarCanvas
    Hyperion._meteorParent = MeteorCanvas

    -- Gradient applied directly to MainFrame via UIGradient
    local _bgGradient = Instance.new("UIGradient")
    _bgGradient.Rotation = 125
    _bgGradient.Color = ColorSequence.new(Theme.Background, Theme.Background)
    _bgGradient.Parent = MainFrame

    Hyperion._bgGradient = _bgGradient
    Hyperion._mainFrame  = MainFrame

    -- Apply gradient immediately if an animated theme is already active
    do
        local currentPreset = Hyperion._currentThemeName and Hyperion.Themes[Hyperion._currentThemeName]
        if currentPreset and currentPreset.Animated then
            MainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
            if currentPreset.GradientStops then
                local stops = {}
                for _, s in ipairs(currentPreset.GradientStops) do
                    table.insert(stops, ColorSequenceKeypoint.new(s[1], s[2]))
                end
                _bgGradient.Color = ColorSequence.new(stops)
            else
                local bg  = currentPreset.Background
                local mid = currentPreset.GradientMid or currentPreset.Accent
                local cx = math.clamp(bg.R * 0.2 + mid.R * 0.8, 0, 1)
                local cy = math.clamp(bg.G * 0.2 + mid.G * 0.8, 0, 1)
                local cz = math.clamp(bg.B * 0.2 + mid.B * 0.8, 0, 1)
                local ex = math.clamp(bg.R * 0.5 + mid.R * 0.5, 0, 1)
                local ey = math.clamp(bg.G * 0.5 + mid.G * 0.5, 0, 1)
                local ez = math.clamp(bg.B * 0.5 + mid.B * 0.5, 0, 1)
                _bgGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    bg),
                    ColorSequenceKeypoint.new(0.2,  Color3.new(ex, ey, ez)),
                    ColorSequenceKeypoint.new(0.5,  Color3.new(cx, cy, cz)),
                    ColorSequenceKeypoint.new(0.8,  Color3.new(ex, ey, ez)),
                    ColorSequenceKeypoint.new(1,    bg),
                })
            end
        end
    end

    -- Slow gradient rotation for animated themes
    local _gradRotConn = nil
    local function _startGradientRotation()
        if _gradRotConn then _gradRotConn:Disconnect() end
        _gradRotConn = RunService.Heartbeat:Connect(function(dt)
            if not _bgGradient or not _bgGradient.Parent then return end
            _bgGradient.Rotation = (_bgGradient.Rotation + dt * 3) % 360
        end)
        table.insert(Hyperion.Connections, _gradRotConn)
    end
    local function _stopGradientRotation()
        if _gradRotConn then
            _gradRotConn:Disconnect()
            _gradRotConn = nil
        end
        if _bgGradient and _bgGradient.Parent then
            _bgGradient.Rotation = 125
        end
    end

    -- Start rotation if animated theme already active
    if Hyperion._currentThemeName then
        local cp = Hyperion.Themes[Hyperion._currentThemeName]
        if cp and cp.Animated then _startGradientRotation() end
    end

    -- Expose to SetTheme override
    Hyperion._startGradRot = _startGradientRotation
    Hyperion._stopGradRot  = _stopGradientRotation

    Hyperion:OnThemeChanged(function()
        -- gradient driven by SetTheme override
    end)

    -- Background image layer (sits behind all content, optional)
    local BgImage = Util.Create("ImageLabel", {
        Name             = "BgImage",
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Image            = "",
        ImageTransparency = 0,
        ScaleType        = Enum.ScaleType.Crop,
        ZIndex           = 0,
        Visible          = false,
        Parent           = MainFrame,
    })
    Util.AddCorner(BgImage, Theme.CornerLarge)

    -- Dark tint over bg image so text stays readable
    local BgTint = Util.Create("Frame", {
        Name             = "BgTint",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        Size             = UDim2.new(1, 0, 1, 0),
        BorderSizePixel  = 0,
        ZIndex           = 1,
        Visible          = false,
        Parent           = MainFrame,
    })
    Util.AddCorner(BgTint, Theme.CornerLarge)

    -- Expose to SetTheme override so theme-driven backgrounds work
    Hyperion._bgImageLabel = BgImage
    Hyperion._bgTintFrame  = BgTint

    -- Apply background image if the active theme already has one
    do
        local _cpNow = Hyperion._currentThemeName and Hyperion.Themes[Hyperion._currentThemeName]
        if _cpNow and _cpNow.BackgroundImage and _cpNow.BackgroundImage ~= "" then
            local _imgId = (type(_cpNow.BackgroundImage) == "number")
                and ("rbxassetid://" .. _cpNow.BackgroundImage)
                or _cpNow.BackgroundImage
            BgImage.Image   = _imgId
            BgImage.Visible = true
            local _ta = (_cpNow.BackgroundTint ~= nil) and _cpNow.BackgroundTint or 0.45
            BgTint.BackgroundTransparency = 1 - _ta
            BgTint.Visible = _ta > 0
        end
    end

    -- Layered drop shadow: umbra (tight/dark) -> penumbra (mid) -> antumbra (wide/faint).
    -- Three passes at different spreads read as real depth; one flat pass reads as a halo.
    local function _shadowLayer(name, spread, transparency, z)
        return Util.Create("ImageLabel", {
            Name = name,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, spread, 1, spread),
            Position = UDim2.new(0.5, 0, 0.5, 2 + spread * 0.05),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image = "rbxassetid://6014261993",
            ImageColor3 = Color3.fromRGB(0, 0, 0),
            ImageTransparency = transparency,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = Rect.new(49, 49, 450, 450),
            ZIndex = z,
            Parent = MainFrame
        })
    end
    _shadowLayer("ShadowUmbra",   24, 0.62, -3)
    _shadowLayer("ShadowAntumbra", 96, 0.90, -1)
    local Shadow = _shadowLayer("ShadowPenumbra", 56, 0.74, -2)

    -- ============================================================
    -- HEADER (48px)
    -- ============================================================
    local HeaderHeight = 52
    local SidebarWidth = 144
    local Header = Util.Create("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, -SidebarWidth, 0, HeaderHeight),
        Position = UDim2.new(0, SidebarWidth, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = MainFrame
    })
    Util.AddCorner(Header, Theme.CornerLarge)
    local _headerBottomFix = Util.Create("Frame", {
        Name = "BottomFix",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = Header
    })
    Themed(Util.Create("Frame", {
        Name = "LeftFix",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(0, 14, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = Header
    }), { BackgroundColor3 = function(t) return t.Surface end })
    Themed(Header, { BackgroundColor3 = function(t) return t.Surface end })
    Themed(_headerBottomFix, { BackgroundColor3 = function(t) return t.Surface end })

    -- Accent gradient line at bottom of header
    local AccentLine = Util.Create("Frame", {
        Name = "AccentLine",
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = Header
    })
    local _accentGradient = Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentDark),
            ColorSequenceKeypoint.new(0.5, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentDark),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0.7),
        }),
        Parent = AccentLine
    })
    Themed(_accentGradient, {
        Color = function(t)
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.AccentDark),
                ColorSequenceKeypoint.new(0.5, t.Accent),
                ColorSequenceKeypoint.new(1, t.AccentDark),
            })
        end
    })

    -- Logo + Title container
    local LogoContainer = Util.Create("Frame", {
        Name = "LogoContainer",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, HeaderHeight),
        Position = UDim2.new(0, 12, 0, 0),
        ZIndex = 6,
        Parent = Header
    })

    local hasLogo = windowConfig.Logo ~= nil
    local LogoImage = Util.Create("ImageLabel", {
        Name = "Logo",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = "",
        ImageColor3 = Theme.Accent,
        Visible = false,
        ZIndex = 6,
        Parent = LogoContainer
    })

    local function ApplyWindowLogo(themeObj)
        local activeLogo = Hyperion._themeLogo or windowConfig.Logo

        if typeof(activeLogo) == "number" then
            activeLogo = "rbxassetid://" .. tostring(activeLogo)
        elseif type(activeLogo) == "string" and activeLogo ~= "" and not string.find(activeLogo, "rbxassetid://", 1, true) then
            if string.match(activeLogo, "^%d+$") then
                activeLogo = "rbxassetid://" .. activeLogo
            end
        end

        LogoImage.Image = activeLogo or ""
        local existingLogoGrad = LogoImage:FindFirstChildWhichIsA("UIGradient")
        if existingLogoGrad then existingLogoGrad:Destroy() end
        if themeObj.LogoGradient then
            local lg = Instance.new("UIGradient")
            lg.Color = ColorSequence.new(themeObj.LogoGradient)
            lg.Rotation = 90
            lg.Parent = LogoImage
            LogoImage.ImageColor3 = Color3.new(1, 1, 1)
        else
            LogoImage.ImageColor3 = themeObj.Accent
        end
        LogoImage.Visible = (activeLogo ~= nil and activeLogo ~= "")
    end

    Hyperion:OnThemeChanged(function(t)
        ApplyWindowLogo(t)
    end)

    ApplyWindowLogo(Theme)

    local TitleLabel = Util.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(hasLogo and 32 or 0), 1, 0),
        Position = UDim2.new(0, hasLogo and 32 or 0, 0, 0),
        Text = windowConfig.Title,
        TextColor3 = Color3.new(1, 1, 1),
        FontFace = Theme.FontBold,
        TextSize = 16,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
        Parent = LogoContainer
    })
    Hyperion._titleLabel = TitleLabel
    if not Hyperion._windowConfigTitle then
        Hyperion._windowConfigTitle = windowConfig.Title
    end
    local _titleGradient = Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Text),
            ColorSequenceKeypoint.new(0.5, Theme.AccentLight),
            ColorSequenceKeypoint.new(1, Theme.Text),
        }),
        Parent = TitleLabel
    })
    Themed(_titleGradient, {
        Color = function(t)
            if t.TitleGradient then
                return ColorSequence.new(t.TitleGradient)
            end
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.Text),
                ColorSequenceKeypoint.new(0.5, t.AccentLight),
                ColorSequenceKeypoint.new(1, t.Text),
            })
        end
    })

    local SubtitleLabel = Util.Create("TextLabel", {
        Name = "Subtitle",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 1, 0, 1),
        Position = UDim2.new(0, 0, 0, 0),
        Text = "",
        TextTransparency = 1,
        ZIndex = 6,
        Parent = LogoContainer
    })

    local TopRightInfo = Util.Create("Frame", {
        Name = "TopRightInfo",
        BackgroundColor3 = Theme.SurfaceLight,
        BackgroundTransparency = 0.18,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -46, 0.5, 0),
        Size = UDim2.new(0, 200, 0, 36),
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = Header
    })
    Util.AddCorner(TopRightInfo, Theme.CornerSmall)
    local _topInfoStroke = Util.AddStroke(TopRightInfo, Theme.BorderLight, 1, 0.18)
    Themed(TopRightInfo, { BackgroundColor3 = function(t) return t.SurfaceLight end })
    Themed(_topInfoStroke, { Color = function(t) return t.BorderLight end })

    local executorName = "Unknown"
    pcall(function()
        if identifyexecutor then
            executorName = tostring(identifyexecutor())
        elseif getexecutorname then
            executorName = tostring(getexecutorname())
        end
    end)

    local thumb = ""
    pcall(function()
        thumb = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size48x48
        )
    end)

    local PlayerIcon = Util.Create("ImageLabel", {
        Name = "PlayerIcon",
        BackgroundColor3 = Theme.Surface,
        Size = UDim2.new(0, 26, 0, 26),
        Position = UDim2.new(0, 5, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = thumb,
        ScaleType = Enum.ScaleType.Crop,
        ZIndex = 7,
        Parent = TopRightInfo
    })
    Util.AddCorner(PlayerIcon, UDim.new(1, 0))
    local _playerIconStroke = Util.AddStroke(PlayerIcon, Theme.BorderLight, 1, 0.1)
    Themed(PlayerIcon, { BackgroundColor3 = function(t) return t.Surface end })
    Themed(_playerIconStroke, { Color = function(t) return t.BorderLight end })

    local UserInfo = Util.Create("TextLabel", {
        Name = "UserInfo",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 3),
        Size = UDim2.new(1, -44, 0, 12),
        Text = "User: " .. LocalPlayer.Name,
        TextColor3 = Theme.Text,
        FontFace = Theme.FontSemiBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = TopRightInfo
    })
    Hyperion._userInfoLabel = UserInfo
    Themed(UserInfo, { TextColor3 = function(t) return t.Text end })

    local ExecutorInfo = Util.Create("TextLabel", {
        Name = "ExecutorInfo",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 14),
        Size = UDim2.new(1, -44, 0, 11),
        Text = "Executor: " .. executorName,
        TextColor3 = Theme.TextDim,
        FontFace = Theme.FontMedium,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = TopRightInfo
    })
    Themed(ExecutorInfo, { TextColor3 = function(t) return t.TextDim end })

    local ExpiresInfo = Util.Create("TextLabel", {
        Name = "ExpiresInfo",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 38, 0, 24),
        Size = UDim2.new(1, -44, 0, 11),
        Text = "Expires: Never",
        TextColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
        Parent = TopRightInfo
    })
    Themed(ExpiresInfo, { TextColor3 = function(t) return t.TextMuted end })

    WindowObj._isFullscreen = false
    WindowObj._collapsed = false

    ;(function()
        local function MakeDot(dotName, xOff, hotColor, tip, fn)
            local d = Util.Create("TextButton", {
                Name = dotName,
                BackgroundColor3 = Theme.TextMuted,
                BackgroundTransparency = 0.15,
                Size = UDim2.fromOffset(12, 12),
                Position = UDim2.new(1, xOff, 0.5, 0),
                AnchorPoint = Vector2.new(1, 0.5),
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                ZIndex = 7,
                Parent = Header,
            })
            Util.AddCorner(d, UDim.new(1, 0))
            Themed(d, { BackgroundColor3 = function(t) return t.TextMuted end })
            d.MouseEnter:Connect(function()
                Util.TweenFast(d, { BackgroundColor3 = hotColor, BackgroundTransparency = 0 })
            end)
            d.MouseLeave:Connect(function()
                Util.TweenFast(d, { BackgroundColor3 = Hyperion.Theme.TextMuted, BackgroundTransparency = 0.15 })
            end)
            d.MouseButton1Click:Connect(fn)
            pcall(Util.AttachTooltip, d, tip)
            return d
        end

        local function ToggleCollapse()
            if not WindowObj._collapsed then
                WindowObj._collapsed = true
                WindowObj._preCollapseSize = MainFrame.Size
                MainFrame.ClipsDescendants = true
                Util.Tween(MainFrame, 0.26, {
                    Size = UDim2.new(0, WindowObj._preCollapseSize.X.Offset, 0, HeaderHeight),
                }, Enum.EasingStyle.Quint)
            else
                WindowObj._collapsed = false
                Util.Tween(MainFrame, 0.26, {
                    Size = WindowObj._preCollapseSize or windowConfig.Size,
                }, Enum.EasingStyle.Quint)
                task.delay(0.3, function()
                    if not WindowObj._collapsed and MainFrame and MainFrame.Parent then
                        MainFrame.ClipsDescendants = false
                    end
                end)
            end
        end

        MakeDot("DotClose", -14, Color3.fromRGB(255, 95, 86), "Hide (Right Shift to reopen)", function()
            WindowObj:Toggle()
        end)

        MakeDot("DotMax", -32, Color3.fromRGB(39, 201, 63), "Fullscreen", function()
            local vpSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            if WindowObj._collapsed then ToggleCollapse() end
            if not WindowObj._isFullscreen then
                WindowObj._preFullscreenSize = WindowObj.CurrentSize
                WindowObj._preFullscreenPos  = MainFrame.Position
                WindowObj._isFullscreen = true
                local fullSize = UDim2.new(0, math.floor(vpSize.X - 20), 0, math.floor(vpSize.Y - 20))
                WindowObj.CurrentSize = fullSize
                Util.Tween(MainFrame, 0.3, {
                    Size = fullSize,
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                }, Enum.EasingStyle.Quint)
            else
                WindowObj._isFullscreen = false
                WindowObj.CurrentSize = WindowObj._preFullscreenSize or windowConfig.Size
                Util.Tween(MainFrame, 0.3, {
                    Size = WindowObj.CurrentSize,
                    Position = WindowObj._preFullscreenPos or UDim2.new(0.5, 0, 0.5, 0),
                }, Enum.EasingStyle.Quint)
            end
        end)

        MakeDot("DotMin", -50, Color3.fromRGB(255, 189, 46), "Collapse", ToggleCollapse)
    end)()

    TopRightInfo.Position = UDim2.new(1, -74, 0.5, 0)

    -- ============================================================
    -- SIDEBAR
    -- ============================================================
    local Sidebar = Util.Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, SidebarWidth, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = MainFrame
    })
    Util.AddCorner(Sidebar, Theme.CornerLarge)
    Themed(Sidebar, { BackgroundColor3 = function(t) return t.Sidebar end })

    Themed(Util.Create("Frame", {
        Name = "RightFix",
        BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, 14, 1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = Sidebar
    }), { BackgroundColor3 = function(t) return t.Sidebar end })

    LogoContainer.Parent = Sidebar
    LogoContainer.ZIndex = 5

    Themed(Util.Create("Frame", {
        Name = "TopSep",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.55,
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.new(0, 10, 0, HeaderHeight - 1),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = Sidebar
    }), { BackgroundColor3 = function(t) return t.Border end })

    -- Right border line
    local _sidebarBorder = Util.Create("Frame", {
        Name = "Border",
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.4,
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = Sidebar
    })
    Themed(_sidebarBorder, { BackgroundColor3 = function(t) return t.Border end })

    -- ── Tabs scroll (leaves 40px at bottom for folder button) ──────────────
    local TabContainer = Util.Create("ScrollingFrame", {
        Name = "Tabs",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -1, 1, -(HeaderHeight + 48)),
        Position = UDim2.new(0, 0, 0, HeaderHeight + 5),
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 3,
        Parent = Sidebar
    })
    Util.AddList(TabContainer, Enum.FillDirection.Vertical, 2)
    Util.AddPadding(TabContainer, 6, 8, 6, 8)

    -- ================================================================
    -- BOTTOM BAR (Search | Config | Info) — row of 3 icon buttons
    -- ================================================================
    local BottomBar = Util.Create("Frame", {
        Name             = "BottomBar",
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, 32),
        Position         = UDim2.new(0, 0, 1, -36),
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = Sidebar,
    })
    -- Separator above bar
    local _bottomSep = Util.Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.5,
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 6,
        Parent = BottomBar,
    })
    Themed(_bottomSep, { BackgroundColor3 = function(t) return t.Border end })

    local BottomRow = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 5),
        ZIndex = 6,
        Parent = BottomBar,
    })
    Util.AddList(BottomRow, Enum.FillDirection.Horizontal, 3,
        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    Util.AddPadding(BottomRow, 0, 0, 0, 6)

    -- Helper to create bottom bar buttons
    local function MakeBottomBtn(icon, name)
        local btn = Util.Create("ImageButton", {
            Name             = "BottomBtn_" .. name,
            BackgroundColor3 = Theme.SurfaceLight,
            BackgroundTransparency = 0.5,
            Size             = UDim2.new(0, 16, 0, 16),
            BorderSizePixel  = 0,
            Image            = icon,
            ImageColor3      = Theme.TextMuted,
            ScaleType        = Enum.ScaleType.Fit,
            AutoButtonColor  = false,
            ZIndex           = 7,
            Parent           = BottomRow,
        })
        Util.AddCorner(btn, UDim.new(0, 3))
        Themed(btn, {
            ImageColor3 = function(t) return t.TextMuted end,
        })

        btn.MouseEnter:Connect(function()
            Util.TweenFast(btn, {
                BackgroundTransparency = 0.1,
                ImageColor3            = Hyperion.Theme.Accent,
            })
        end)
        btn.MouseLeave:Connect(function()
            Util.TweenFast(btn, {
                BackgroundTransparency = 0.5,
                ImageColor3            = Hyperion.Theme.TextMuted,
            })
        end)
        return btn
    end

    local SearchBtn = MakeBottomBtn("rbxassetid://10734943674", "Search")   -- lucide-search
    local FolderOpenBtn = MakeBottomBtn("rbxassetid://10723387563", "Config") -- lucide-folder
    local PlayersBtn = MakeBottomBtn("rbxassetid://10747373426", "Players")  -- lucide-users
    local ChatBtn   = MakeBottomBtn("rbxassetid://10734982144", "Chat")      -- lucide-terminal
    local ThemeBtn  = MakeBottomBtn("rbxassetid://10734910430", "Theme")     -- lucide-palette
    local KeybindBtn = MakeBottomBtn("rbxassetid://10723395215", "Keybinds") -- lucide-gamepad
    local InfoBtn   = MakeBottomBtn("rbxassetid://10723415903", "Info")      -- lucide-info

    -- If the config system is disabled, hide the folder button entirely.
    if not windowConfig.ConfigSystem then
        FolderOpenBtn.Visible = false
    end

    -- ── Feature search popup ───────────────────────────────────────────────
    local searchOpen = false
    local SearchOverlay = Util.Create("Frame", {
        Name             = "SearchOverlay",
        BackgroundColor3 = Theme.Sidebar,
        Size             = UDim2.new(0, SidebarWidth - 16, 0, 34),
        Position         = UDim2.new(0, 8, 1, -72),
        ClipsDescendants = true,
        Visible          = false,
        ZIndex           = 8,
        Parent           = Sidebar,
    })
    Util.AddCorner(SearchOverlay, Theme.CornerSmall)
    Util.AddStroke(SearchOverlay, Theme.BorderLight, 1, 0.2)
    Themed(SearchOverlay, { BackgroundColor3 = function(t) return t.SurfaceLight end })

    local SearchBox = Util.Create("TextBox", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, -12, 1, 0),
        Position         = UDim2.new(0, 8, 0, 0),
        Text             = "",
        PlaceholderText  = "Search features...",
        TextColor3       = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted,
        FontFace         = Theme.Font,
        TextSize         = 12,
        ClearTextOnFocus = false,
        ZIndex           = 9,
        Parent           = SearchOverlay,
    })
    Themed(SearchBox, {
        TextColor3        = function(t) return t.Text end,
        PlaceholderColor3 = function(t) return t.TextMuted end,
    })

    local SearchResults = Util.Create("ScrollingFrame", {
        Name = "SearchResults",
        BackgroundColor3 = Theme.Sidebar,
        AnchorPoint = Vector2.new(0, 1),
        Size = UDim2.new(0, SidebarWidth - 16, 0, 0),
        Position = UDim2.new(0, 8, 1, -76),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 9,
        Parent = Sidebar,
    })
    Util.AddCorner(SearchResults, Theme.CornerSmall)
    Util.AddStroke(SearchResults, Theme.BorderLight, 1, 0.2)
    Util.AddList(SearchResults, Enum.FillDirection.Vertical, 2)
    Util.AddPadding(SearchResults, 4, 4, 4, 4)
    Themed(SearchResults, {
        BackgroundColor3 = function(t) return t.SurfaceLight end,
        ScrollBarImageColor3 = function(t) return t.Accent end,
    })

    local function closeSearch()
        searchOpen = false
        SearchOverlay.Visible = false
        SearchResults.Visible = false
        SearchBox.Text = ""
        Util.TweenFast(SearchBtn, {ImageColor3 = Hyperion.Theme.TextDim, BackgroundTransparency = 0.35})
    end

    local function goToFeature(entry)
        closeSearch()
        if entry.tab and entry.tab.Activate then pcall(entry.tab.Activate) end
        if entry.tab and entry.tab.ActivateGroup and entry.groupData then pcall(entry.tab.ActivateGroup, entry.groupData) end
        task.defer(function()
            local frame, page = entry.frame, entry.page
            if frame and frame.Parent and page then
                local relY = frame.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
                page.CanvasPosition = Vector2.new(0, math.max(0, relY - 24))
                local hl = Util.Create("UIStroke", { Color = Hyperion.Theme.Accent, Thickness = 0, Transparency = 0, Parent = frame })
                Util.TweenFast(hl, { Thickness = 2 })
                task.delay(0.9, function()
                    Util.Tween(hl, 0.4, { Transparency = 1 }, Enum.EasingStyle.Quad)
                    task.delay(0.45, function() pcall(function() hl:Destroy() end) end)
                end)
            end
        end)
    end

    local function RefreshResults(q)
        for _, c in ipairs(SearchResults:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        q = (q or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if q == "" then SearchResults.Visible = false return end
        local lq = string.lower(q)
        local count = 0
        for _, e in ipairs(Hyperion._SearchIndex) do
            if e.lname:find(lq, 1, true) or e.ltab:find(lq, 1, true)
                or (e.group and string.lower(e.group):find(lq, 1, true)) then
                count = count + 1
                local ee = e
                local Row = Util.Create("TextButton", {
                    BackgroundColor3 = Theme.Surface, BackgroundTransparency = 0.3,
                    Size = UDim2.new(1, 0, 0, 32), Text = "", AutoButtonColor = false,
                    ZIndex = 10, Parent = SearchResults,
                })
                Util.AddCorner(Row, Theme.CornerSmall)
                local NameL = Util.Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 3),
                    Size = UDim2.new(1, -12, 0, 15), Text = e.name,
                    TextColor3 = Theme.Text, FontFace = Theme.FontMedium, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 11, Parent = Row,
                })
                Themed(NameL, { TextColor3 = function(t) return t.Text end })
                local PathL = Util.Create("TextLabel", {
                    BackgroundTransparency = 1, Position = UDim2.new(0, 8, 0, 17),
                    Size = UDim2.new(1, -12, 0, 12), Text = e.tabName .. "  ›  " .. e.group,
                    TextColor3 = Theme.TextMuted, FontFace = Theme.Font, TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 11, Parent = Row,
                })
                Themed(PathL, { TextColor3 = function(t) return t.TextMuted end })
                Row.MouseEnter:Connect(function() Util.TweenFast(Row, { BackgroundTransparency = 0, BackgroundColor3 = Hyperion.Theme.SurfaceHover }) end)
                Row.MouseLeave:Connect(function() Util.TweenFast(Row, { BackgroundTransparency = 0.3, BackgroundColor3 = Hyperion.Theme.Surface }) end)
                Row.MouseButton1Click:Connect(function() goToFeature(ee) end)
                if count >= 40 then break end
            end
        end
        if count == 0 then SearchResults.Visible = false return end
        SearchResults.Size = UDim2.new(0, SidebarWidth - 16, 0, math.min(count * 34 + 8, 240))
        SearchResults.Visible = true
    end

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        RefreshResults(SearchBox.Text)
    end)

    SearchBtn.MouseButton1Click:Connect(function()
        searchOpen = not searchOpen
        if searchOpen then
            SearchOverlay.Visible = true
            SearchBox:CaptureFocus()
            Util.TweenFast(SearchBtn, {ImageColor3 = Hyperion.Theme.Accent, BackgroundTransparency = 0})
        else
            closeSearch()
        end
    end)

    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not searchOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local function inside(o)
            if not o.Visible then return false end
            local p, s = o.AbsolutePosition, o.AbsoluteSize
            return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
        end
        local btnPos, btnSize = SearchBtn.AbsolutePosition, SearchBtn.AbsoluteSize
        local insideBtn = pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X
            and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y
        if not inside(SearchOverlay) and not inside(SearchResults) and not insideBtn then
            closeSearch()
        end
    end)

    -- ── Info popup ────────────────────────────────────────────────────────
    local infoOpen = false
    local InfoOverlay = Util.Create("Frame", {
        Name             = "InfoOverlay",
        BackgroundColor3 = Theme.Surface,
        Size             = UDim2.new(0, SidebarWidth - 16, 0, 0),
        Position         = UDim2.new(0, 8, 1, -72),
        ClipsDescendants = true,
        Visible          = false,
        ZIndex           = 8,
        Parent           = Sidebar,
    })
    Util.AddCorner(InfoOverlay, Theme.CornerSmall)
    Util.AddStroke(InfoOverlay, Theme.BorderLight, 1, 0.2)
    Themed(InfoOverlay, { BackgroundColor3 = function(t) return t.Surface end })

    local InfoContent = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 80),
        ZIndex = 9,
        Parent = InfoOverlay,
    })
    Util.AddList(InfoContent, Enum.FillDirection.Vertical, 3)
    Util.AddPadding(InfoContent, 8, 10, 8, 10)

    local function InfoLine(text, color, font)
        return Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 13),
            Text = text,
            TextColor3 = color or Theme.TextDim,
            FontFace = font or Theme.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 10,
            Parent = InfoContent,
        })
    end

    InfoLine("Hyperion UI v" .. Hyperion.Version, Theme.Accent, Theme.FontSemiBold)
    InfoLine("by Phobia", Theme.TextDim, Theme.Font)
    InfoLine("", Theme.TextMuted, Theme.Font) -- spacer
    InfoLine("RightCtrl — Toggle UI", Theme.TextMuted, Theme.Font)
    InfoLine("Folder icon — Configs", Theme.TextMuted, Theme.Font)

    InfoBtn.MouseButton1Click:Connect(function()
        infoOpen = not infoOpen
        if infoOpen then
            InfoOverlay.Visible = true
            Util.TweenSmooth(InfoOverlay, {Size = UDim2.new(0, SidebarWidth - 16, 0, 86)})
            Util.TweenFast(InfoBtn, {ImageColor3 = Hyperion.Theme.Accent, BackgroundTransparency = 0})
        else
            Util.TweenSmooth(InfoOverlay, {Size = UDim2.new(0, SidebarWidth - 16, 0, 0)})
            Util.TweenFast(InfoBtn, {ImageColor3 = Hyperion.Theme.TextDim, BackgroundTransparency = 0.35})
            task.delay(0.28, function()
                if not infoOpen then InfoOverlay.Visible = false end
            end)
        end
    end)

    -- Config folder button uses same logic as before
    local FolderOpenStroke = FolderOpenBtn:FindFirstChildOfClass("UIStroke")
    Themed(FolderOpenBtn, {
        BackgroundColor3 = function(t)
            return _G._HyperionCfgOpen and t.SurfaceActive or t.SurfaceLight
        end,
        ImageColor3 = function(t)
            return _G._HyperionCfgOpen and t.Accent or t.TextDim
        end,
    })
    if FolderOpenStroke then
        Themed(FolderOpenStroke, {
            Color = function(t)
                return _G._HyperionCfgOpen and t.Accent or t.Border
            end
        })
    end

    -- ================================================================
    -- CONFIG PANEL
    -- Opens to the RIGHT of the sidebar, full content-area height.
    -- Slides in/out horizontally.
    -- ================================================================
    local CFG_W         = 260   -- panel width
    local cfgPanelOpen  = false
    local selectedCfgName = nil
    _G._HyperionCfgOpen = false

    -- Parent to MainFrame with negative X offset so it sits flush to the left.
    -- Because MainFrame has ClipsDescendants=false it renders outside the frame.
    -- No absolute position math needed — UDim2 handles it automatically.
    local ConfigOverlay = Util.Create("Frame", {
        Name             = "ConfigOverlay",
        BackgroundColor3 = Theme.Sidebar,
        Size             = UDim2.new(0, CFG_W, 1, -HeaderHeight),
        Position         = UDim2.new(0, -CFG_W, 0, HeaderHeight),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 50,
        Parent           = MainFrame,
    })
    Util.AddCorner(ConfigOverlay, Theme.CornerRadius)
    local _cfgStroke = Util.AddStroke(ConfigOverlay, Theme.BorderLight, 1, 0.12)
    Themed(ConfigOverlay, { BackgroundColor3 = function(t) return t.Sidebar end })
    Themed(_cfgStroke, { Color = function(t) return t.BorderLight end })

    -- Scrollable inner so content never gets clipped vertically
    local CfgScroll = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        BorderSizePixel  = 0,
        ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize       = UDim2.new(0, 0, 0, 0),
        ZIndex           = 31,
        Parent           = ConfigOverlay,
    })
    Util.AddList(CfgScroll, Enum.FillDirection.Vertical, 0)
    Util.AddPadding(CfgScroll, 0, 8, 6, 8)

    -- ── Header strip ─────────────────────────────────────────────────────
    local CfgHeaderStrip = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive,
        Size             = UDim2.new(1, 0, 0, 42),
        BorderSizePixel  = 0,
        ZIndex           = 32,
        Parent           = CfgScroll,
    })
    Themed(CfgHeaderStrip, { BackgroundColor3 = function(t) return t.SidebarActive end })

    -- top accent gradient line
    do
        local al = Util.Create("Frame", {
            BackgroundColor3 = Color3.new(1,1,1),
            Size = UDim2.new(1,0,0,1),
            BorderSizePixel = 0, ZIndex = 33, Parent = CfgHeaderStrip,
        })
        local _cfgHdrGrad = Util.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.AccentDark),
                ColorSequenceKeypoint.new(0.5, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentDark),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.5),
            }),
            Parent = al,
        })
        Themed(_cfgHdrGrad, { Color = function(t)
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.AccentDark),
                ColorSequenceKeypoint.new(0.5, t.Accent),
                ColorSequenceKeypoint.new(1, t.AccentDark),
            })
        end })
    end

    local _cfgTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 7),
        Size     = UDim2.new(1, -52, 0, 16),
        Text     = "Config",
        TextColor3 = Theme.Text,
        FontFace = Theme.FontBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 33,
        Parent   = CfgHeaderStrip,
    })
    Themed(_cfgTitle, { TextColor3 = function(t) return t.Text end })

    local CfgStatusLbl = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 25),
        Size     = UDim2.new(1, -52, 0, 12),
        Text     = "No config selected",
        TextColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 33,
        Parent   = CfgHeaderStrip,
    })
    Themed(CfgStatusLbl, { TextColor3 = function(t) return t.TextMuted end })

    -- Close × icon button (top-right)
    local CfgCloseBtn = Util.Create("ImageButton", {
        BackgroundColor3 = Theme.SurfaceActive,
        BackgroundTransparency = 0.4,
        Size     = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image    = "rbxassetid://10747384394",  -- lucide-x
        ImageColor3 = Theme.TextDim,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        ZIndex   = 34,
        Parent   = CfgHeaderStrip,
    })
    Util.AddCorner(CfgCloseBtn, Theme.CornerSmall)
    Themed(CfgCloseBtn, {
        BackgroundColor3 = function(t) return t.SurfaceActive end,
        ImageColor3      = function(t) return t.TextDim end,
    })
    CfgCloseBtn.MouseEnter:Connect(function()
        Util.TweenFast(CfgCloseBtn, {BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Error})
    end)
    CfgCloseBtn.MouseLeave:Connect(function()
        Util.TweenFast(CfgCloseBtn, {BackgroundTransparency = 0.4, ImageColor3 = Hyperion.Theme.TextDim})
    end)

    -- ── Name textbox ──────────────────────────────────────────────────────
    local CfgNameWrap = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 42),
        ZIndex   = 32,
        Parent   = CfgScroll,
    })
    local CfgNameBox = Util.Create("TextBox", {
        BackgroundColor3 = Theme.InputBg,
        Size     = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Text     = "",
        PlaceholderText = "config name...",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted,
        FontFace = Theme.FontMedium,
        TextSize = 12,
        ClearTextOnFocus = false,
        BorderSizePixel  = 0,
        ZIndex   = 33,
        Parent   = CfgNameWrap,
    })
    Util.AddCorner(CfgNameBox, Theme.CornerSmall)
    local _nameStroke = Util.AddStroke(CfgNameBox, Theme.Border, 1, 0.3)
    Themed(CfgNameBox, {
        BackgroundColor3  = function(t) return t.InputBg end,
        TextColor3        = function(t) return t.Text end,
        PlaceholderColor3 = function(t) return t.TextMuted end,
    })
    Themed(_nameStroke, { Color = function(t) return t.Border end })
    CfgNameBox.Focused:Connect(function()
        Util.TweenFast(CfgNameBox, {BackgroundColor3 = Hyperion.Theme.SurfaceLight})
    end)
    CfgNameBox.FocusLost:Connect(function()
        Util.TweenFast(CfgNameBox, {BackgroundColor3 = Hyperion.Theme.InputBg})
    end)

    -- ── Config list ───────────────────────────────────────────────────────
    local CfgListOuter = Util.Create("Frame", {
        BackgroundColor3 = Theme.Background,
        Size     = UDim2.new(1, 0, 0, 132),
        ZIndex   = 32,
        Parent   = CfgScroll,
    })
    Util.AddPadding(CfgListOuter, 6, 6, 6, 6)
    Util.AddCorner(CfgListOuter, Theme.CornerSmall)
    local _listOuterStroke = Util.AddStroke(CfgListOuter, Theme.Border, 1, 0.3)
    Themed(CfgListOuter, { BackgroundColor3 = function(t) return t.Background end })
    Themed(_listOuterStroke, { Color = function(t) return t.Border end })

    local CfgList = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, -8, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.3,
        
        
        
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        ZIndex   = 33,
        Parent   = CfgListOuter,
    })
    Util.AddList(CfgList, Enum.FillDirection.Vertical, 3)
    Util.AddPadding(CfgList, 2)
    Themed(CfgList, { ScrollBarImageColor3 = function(t) return t.Accent end })

    -- ── Icon action rail ──────────────────────────────────────────────────
    local ICON_IDS = {
        Save    = "rbxassetid://10734941499",  -- lucide-save
        Load    = "rbxassetid://10723344270",  -- lucide-download
        Rename  = "rbxassetid://10734919691",  -- lucide-pencil
        New     = "rbxassetid://10723365877",  -- lucide-file-plus
        Refresh = "rbxassetid://10734933222",  -- lucide-refresh-cw
        Delete  = "rbxassetid://10747362241",  -- lucide-trash-2
    }

    local CfgActionDivider = Util.Create("Frame", {
        BackgroundColor3 = Theme.Border,
        BackgroundTransparency = 0.3,
        Size     = UDim2.new(1, 0, 0, 1),
        ZIndex   = 32,
        Parent   = CfgScroll,
    })
    Themed(CfgActionDivider, { BackgroundColor3 = function(t) return t.Border end })

    local CfgRail = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 34),
        ZIndex   = 32,
        Parent   = CfgScroll,
    })
    Util.AddList(CfgRail, Enum.FillDirection.Horizontal, 0,
        Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local function MakeIconBtn(icon, tooltip, danger)
        local wrap = Util.Create("Frame", {
            BackgroundTransparency = 1,
            Size     = UDim2.new(0, 26, 0, 30),
            ZIndex   = 33,
            Parent   = CfgRail,
        })
        local btn = Util.Create("ImageButton", {
            BackgroundColor3 = danger and Color3.fromRGB(55,18,22) or Theme.SurfaceLight,
            BackgroundTransparency = danger and 0 or 0.4,
            Size     = UDim2.new(0, 18, 0, 18),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Image    = icon,
            ImageColor3 = danger and Theme.Error or Theme.TextDim,
            ScaleType = Enum.ScaleType.Fit,
            AutoButtonColor = false,
            ZIndex   = 34,
            Parent   = wrap,
        })
        Util.AddCorner(btn, Theme.CornerSmall)
        local _btnStroke = Util.AddStroke(btn, danger and Theme.Error or Theme.Border, 1, danger and 0.5 or 0.4)

        if not danger then
            Themed(btn, {
                BackgroundColor3 = function(t) return t.SurfaceLight end,
                ImageColor3      = function(t) return t.TextDim end,
            })
            Themed(_btnStroke, { Color = function(t) return t.Border end })
        else
            Themed(_btnStroke, { Color = function(t) return t.Error end })
        end

        -- Tooltip fades in above the button on hover
        local tip = Util.Create("TextLabel", {
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            Size     = UDim2.new(0, 0, 0, 14),
            AutomaticSize = Enum.AutomaticSize.X,
            Position = UDim2.new(0.5, 0, 0, -2),
            AnchorPoint = Vector2.new(0.5, 1),
            Text     = tooltip,
            TextColor3 = Theme.TextDim,
            FontFace = Theme.Font,
            TextSize = 10,
            TextTransparency = 1,
            ZIndex   = 42,
            Parent   = wrap,
        })
        Util.AddCorner(tip, Theme.CornerSmall)
        Util.AddPadding(tip, 1, 5, 1, 5)
        Themed(tip, {
            BackgroundColor3 = function(t) return t.Background end,
            TextColor3       = function(t) return t.TextDim end,
        })

        local normalBg = danger and Color3.fromRGB(55,18,22) or Theme.SurfaceLight
        local hoverBg  = danger and Color3.fromRGB(80,25,30)  or Theme.SurfaceHover

        btn.MouseEnter:Connect(function()
            Util.TweenFast(btn, {
                BackgroundColor3 = hoverBg,
                BackgroundTransparency = 0,
                ImageColor3 = danger and Hyperion.Theme.Error or Hyperion.Theme.Accent,
            })
            Util.TweenFast(tip, {TextTransparency = 0, BackgroundTransparency = 0.15})
        end)
        btn.MouseLeave:Connect(function()
            Util.TweenFast(btn, {
                BackgroundColor3 = normalBg,
                BackgroundTransparency = danger and 0 or 0.4,
                ImageColor3 = danger and Hyperion.Theme.Error or Hyperion.Theme.TextDim,
            })
            Util.TweenFast(tip, {TextTransparency = 1, BackgroundTransparency = 1})
        end)
        btn.MouseButton1Click:Connect(function()
            Util.TweenFast(btn, {BackgroundColor3 = danger and Hyperion.Theme.Error or Hyperion.Theme.AccentDark})
            task.delay(0.1, function()
                Util.TweenFast(btn, {BackgroundColor3 = normalBg})
            end)
        end)
        return btn
    end

    local BtnSave    = MakeIconBtn(ICON_IDS.Save,    "Save",    false)
    local BtnLoad    = MakeIconBtn(ICON_IDS.Load,    "Load",    false)
    local BtnRename  = MakeIconBtn(ICON_IDS.Rename,  "Rename",  false)
    local BtnNew     = MakeIconBtn(ICON_IDS.New,     "New",     false)
    local BtnRefresh = MakeIconBtn(ICON_IDS.Refresh, "Refresh", false)
    local BtnDelete  = MakeIconBtn(ICON_IDS.Delete,  "Delete",  true)

    -- ── Delete confirm bar (slides in at bottom) ──────────────────────────
    local DeleteConfirmBar = Util.Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(40, 14, 18),
        Size     = UDim2.new(1, 0, 0, 0),
        ZIndex   = 35,
        ClipsDescendants = true,
        Visible  = false,
        Parent   = CfgScroll,
    })
    Util.AddCorner(DeleteConfirmBar, Theme.CornerSmall)
    Util.AddStroke(DeleteConfirmBar, Theme.Error, 1, 0.5)

    local DeleteConfirmInner = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 64),
        ZIndex   = 36,
        Parent   = DeleteConfirmBar,
    })
    Util.AddList(DeleteConfirmInner, Enum.FillDirection.Vertical, 4)
    Util.AddPadding(DeleteConfirmInner, 8, 10, 8, 10)

    Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 14),
        Text     = "Delete this config?",
        TextColor3 = Theme.Error,
        FontFace = Theme.FontSemiBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 37,
        Parent   = DeleteConfirmInner,
    })
    local DeleteConfirmSub = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 11),
        Text     = "",
        TextColor3 = Theme.TextDim,
        FontFace = Theme.Font,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 37,
        Parent   = DeleteConfirmInner,
    })
    local DeleteBtnRow = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 24),
        ZIndex   = 37,
        Parent   = DeleteConfirmInner,
    })
    Util.AddList(DeleteBtnRow, Enum.FillDirection.Horizontal, 6)

    local BtnConfirmDelete = Util.Create("TextButton", {
        BackgroundColor3 = Color3.fromRGB(70, 22, 26),
        Size     = UDim2.new(0.5, -3, 1, 0),
        Text     = "Confirm",
        TextColor3 = Theme.Error,
        FontFace = Theme.FontSemiBold,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex   = 38,
        Parent   = DeleteBtnRow,
    })
    Util.AddCorner(BtnConfirmDelete, Theme.CornerSmall)
    Util.AddStroke(BtnConfirmDelete, Theme.Error, 1, 0.5)

    local BtnCancelDelete = Util.Create("TextButton", {
        BackgroundColor3 = Theme.SurfaceLight,
        Size     = UDim2.new(0.5, -3, 1, 0),
        Text     = "Cancel",
        TextColor3 = Theme.TextDim,
        FontFace = Theme.FontMedium,
        TextSize = 11,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        ZIndex   = 38,
        Parent   = DeleteBtnRow,
    })
    Util.AddCorner(BtnCancelDelete, Theme.CornerSmall)
    Util.AddStroke(BtnCancelDelete, Theme.Border, 1, 0.4)

    BtnConfirmDelete.MouseEnter:Connect(function() Util.TweenFast(BtnConfirmDelete, {BackgroundColor3 = Color3.fromRGB(100,28,34)}) end)
    BtnConfirmDelete.MouseLeave:Connect(function() Util.TweenFast(BtnConfirmDelete, {BackgroundColor3 = Color3.fromRGB(70,22,26)}) end)
    BtnCancelDelete.MouseEnter:Connect(function()  Util.TweenFast(BtnCancelDelete,  {BackgroundColor3 = Hyperion.Theme.SurfaceHover}) end)
    BtnCancelDelete.MouseLeave:Connect(function()  Util.TweenFast(BtnCancelDelete,  {BackgroundColor3 = Hyperion.Theme.SurfaceLight}) end)

    -- ── Auto-load button ──────────────────────────────────────────────────
    local function _readAutoLoadFile()
        local ok, v = pcall(_rawReadfile, "Hyperion/autoload.dat")
        return (ok and v and v ~= "") and v or nil
    end

    local AL_ICON_STAR  = "rbxassetid://10734966248" -- lucide-star
    local AL_ICON_CHECK = "rbxassetid://10709790644" -- lucide-check

    local AutoLoadBtn = Util.Create("Frame", {
        Name                   = "AutoLoadBtn",
        BackgroundColor3       = Theme.Surface,
        BackgroundTransparency = 0.3,
        Size                   = UDim2.new(1, -24, 0, 30),
        ZIndex                 = 32,
        Parent                 = CfgScroll,
    })
    Util.AddCorner(AutoLoadBtn, Theme.CornerSmall)
    local _alStroke = Util.AddStroke(AutoLoadBtn, Theme.Border, 1, 0.4)
    Themed(AutoLoadBtn, { BackgroundColor3 = function(t) return t.Surface end })
    Themed(_alStroke,   { Color = function(t) return t.Border end })

    local ALIcon = Util.Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size        = UDim2.new(0, 12, 0, 12),
        Position    = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image       = AL_ICON_STAR,
        ImageColor3 = Theme.TextMuted,
        ScaleType   = Enum.ScaleType.Fit,
        ZIndex      = 33,
        Parent      = AutoLoadBtn,
    })

    local ALLabel = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, -90, 1, 0),
        Position       = UDim2.new(0, 28, 0, 0),
        Text           = "Set as auto-load",
        TextColor3     = Theme.TextMuted,
        FontFace       = Theme.FontMedium,
        TextSize       = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 33,
        Parent         = AutoLoadBtn,
    })
    Themed(ALLabel, { FontFace = function(t) return t.FontMedium end })

    -- Status badge on the right
    local ALBadge = Util.Create("Frame", {
        BackgroundColor3       = Theme.SurfaceLight,
        BackgroundTransparency = 0.2,
        Size        = UDim2.new(0, 34, 0, 18),
        Position    = UDim2.new(1, -42, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        ZIndex      = 33,
        Parent      = AutoLoadBtn,
    })
    Util.AddCorner(ALBadge, UDim.new(1, 0))
    Themed(ALBadge, { BackgroundColor3 = function(t) return t.SurfaceLight end })

    local ALBadgeTxt = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size       = UDim2.new(1, 0, 1, 0),
        Text       = "Off",
        TextColor3 = Theme.TextMuted,
        FontFace   = Theme.FontSemiBold,
        TextSize   = 10,
        ZIndex     = 34,
        Parent     = ALBadge,
    })
    Themed(ALBadgeTxt, { FontFace = function(t) return t.FontSemiBold end })

    local ALHit = Util.Create("TextButton", {
        BackgroundTransparency = 1, Text = "",
        Size = UDim2.new(1, 0, 1, 0), ZIndex = 35,
        Parent = AutoLoadBtn,
    })

    local function UpdateAutoLoadRow()
        local saved    = _readAutoLoadFile()
        local isActive = (saved ~= nil and selectedCfgName ~= nil and saved == selectedCfgName)
        if isActive then
            ALIcon.Image       = AL_ICON_CHECK
            ALIcon.ImageColor3 = Hyperion.Theme.Accent
            ALLabel.Text       = "Auto-loading: " .. saved
            ALLabel.TextColor3 = Hyperion.Theme.Accent
            AutoLoadBtn.BackgroundTransparency = 0.15
            Util.TweenFast(AutoLoadBtn, { BackgroundColor3 = Hyperion.Theme.AccentDark })
            Util.TweenFast(_alStroke, { Color = Hyperion.Theme.Accent, Transparency = 0.1 })
            ALBadgeTxt.Text       = "On"
            ALBadgeTxt.TextColor3 = Hyperion.Theme.Accent
            Util.TweenFast(ALBadge, { BackgroundColor3 = Hyperion.Theme.AccentDark })
        else
            ALIcon.Image       = AL_ICON_STAR
            ALIcon.ImageColor3 = Hyperion.Theme.TextMuted
            ALLabel.Text       = selectedCfgName and "Set as auto-load" or "Select a config first"
            ALLabel.TextColor3 = selectedCfgName and Hyperion.Theme.TextDim or Hyperion.Theme.TextMuted
            AutoLoadBtn.BackgroundTransparency = 0.3
            Util.TweenFast(AutoLoadBtn, { BackgroundColor3 = Hyperion.Theme.Surface })
            Util.TweenFast(_alStroke, { Color = Hyperion.Theme.Border, Transparency = 0.4 })
            ALBadgeTxt.Text       = saved and "On" or "Off"
            ALBadgeTxt.TextColor3 = saved and Hyperion.Theme.Success or Hyperion.Theme.TextMuted
            Util.TweenFast(ALBadge, { BackgroundColor3 = Hyperion.Theme.SurfaceLight })
        end
    end
    pcall(function() Hyperion:OnThemeChanged(function() UpdateAutoLoadRow() end) end)

    ALHit.MouseEnter:Connect(function()
        if not ((_readAutoLoadFile() ~= nil) and (selectedCfgName ~= nil) and (_readAutoLoadFile() == selectedCfgName)) then
            Util.TweenFast(AutoLoadBtn, { BackgroundColor3 = Hyperion.Theme.SurfaceHover, BackgroundTransparency = 0 })
        end
    end)
    ALHit.MouseLeave:Connect(function() UpdateAutoLoadRow() end)

    ALHit.MouseButton1Click:Connect(function()
        if not selectedCfgName or selectedCfgName == "" then
            Hyperion:Notify({ Title="Auto-load", Content="Select a config first.", Type="Warning", Duration=2 })
            return
        end
        local saved = _readAutoLoadFile()
        if saved == selectedCfgName then
            pcall(_rawWritefile, "Hyperion/autoload.dat", "")
            Hyperion:Notify({ Title="Auto-load", Content="Disabled.", Type="Warning", Duration=2 })
        else
            Config.EnsureFolder()
            pcall(_rawWritefile, "Hyperion/autoload.dat", selectedCfgName)
            Hyperion:Notify({ Title="Auto-load", Content='"'..selectedCfgName..'" will load on start.', Type="Success", Duration=3 })
        end
        UpdateAutoLoadRow()
    end)

    -- ── Panel keybind row ─────────────────────────────────────────────────
    local KbRow = Util.Create("Frame", {
        Name                   = "CfgKbRow",
        BackgroundColor3       = Theme.Surface,
        BackgroundTransparency = 0.3,
        Size                   = UDim2.new(1, -24, 0, 30),
        ZIndex                 = 32,
        Parent                 = CfgScroll,
    })
    Util.AddCorner(KbRow, Theme.CornerSmall)
    local _kbRowStroke = Util.AddStroke(KbRow, Theme.Border, 1, 0.4)
    Themed(KbRow, { BackgroundColor3 = function(t) return t.Surface end })
    Themed(_kbRowStroke, { Color = function(t) return t.Border end })

    local KbRowLabel = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size           = UDim2.new(1, -90, 1, 0),
        Position       = UDim2.new(0, 10, 0, 0),
        Text           = "Panel shortcut",
        TextColor3     = Theme.TextDim,
        FontFace       = Theme.FontMedium,
        TextSize       = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex         = 33,
        Parent         = KbRow,
    })
    Themed(KbRowLabel, {
        TextColor3 = function(t) return t.TextDim end,
        FontFace   = function(t) return t.FontMedium end,
    })

    -- Restore saved keybind
    local _cfgKbValue  = Enum.KeyCode.Unknown
    local _cfgKbListen = false
    do
        local ok, raw = pcall(_rawReadfile, "Hyperion/kb_cfgpanel.dat")
        if ok and raw and raw ~= "" then
            local kc = Enum.KeyCode[raw]
            if kc then _cfgKbValue = kc end
        end
    end

    local function _cfgKbName(kc)
        if kc == Enum.KeyCode.Unknown then return "None" end
        return string.gsub(tostring(kc), "Enum.KeyCode.", "")
    end

    local KbBtn = Util.Create("TextButton", {
        Name             = "KbBtn",
        BackgroundColor3 = Theme.SurfaceLight,
        Size             = UDim2.new(0, 72, 0, 22),
        Position         = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint      = Vector2.new(1, 0.5),
        Text             = _cfgKbName(_cfgKbValue),
        TextColor3       = Theme.TextDim,
        FontFace         = Theme.FontMedium,
        TextSize         = 11,
        AutoButtonColor  = false,
        ZIndex           = 33,
        Parent           = KbRow,
    })
    Util.AddCorner(KbBtn, Theme.CornerSmall)
    local _kbBtnStroke = Util.AddStroke(KbBtn, Theme.BorderLight, 1, 0.25)
    Themed(KbBtn, {
        BackgroundColor3 = function(t) return t.SurfaceLight end,
        TextColor3       = function(t) return _cfgKbListen and t.Accent or t.TextDim end,
        FontFace         = function(t) return t.FontMedium end,
    })
    Themed(_kbBtnStroke, { Color = function(t) return _cfgKbListen and t.Accent or t.BorderLight end })

    KbBtn.MouseButton1Click:Connect(function()
        _cfgKbListen = true
        KbBtn.Text = "..."
        Util.TweenFast(_kbBtnStroke, { Color = Hyperion.Theme.Accent, Transparency = 0 })
        Util.TweenFast(KbBtn, { TextColor3 = Hyperion.Theme.Accent })
    end)

    -- Forward ref: assigned after OpenConfigPanel/CloseConfigPanel are defined below.
    local _cfgPanelToggle = nil

    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if _cfgKbListen then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                _cfgKbListen = false
                _cfgKbValue  = (input.KeyCode == Enum.KeyCode.Escape)
                               and Enum.KeyCode.Unknown or input.KeyCode
                KbBtn.Text   = _cfgKbName(_cfgKbValue)
                Util.TweenFast(_kbBtnStroke, { Color = Hyperion.Theme.Border, Transparency = 0.4 })
                Util.TweenFast(KbBtn, { TextColor3 = Hyperion.Theme.TextDim })
                Config.EnsureFolder()
                pcall(_rawWritefile, "Hyperion/kb_cfgpanel.dat", _cfgKbName(_cfgKbValue))
            end
        elseif not processed
            and _cfgKbValue ~= Enum.KeyCode.Unknown
            and input.KeyCode == _cfgKbValue
            and _cfgPanelToggle
        then
            _cfgPanelToggle()
        end
    end)

    -- ── Bottom spacer so scrollable area has breathing room ───────────────
    Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 0, 8),
        ZIndex   = 32,
        Parent   = CfgScroll,
    })

    -- ── Padding wrapper for list & divider ────────────────────────────────
    -- (CfgListOuter and CfgActionDivider need horizontal padding since they
    --  are direct children of CfgScroll which uses a UIListLayout)
    -- Apply horizontal offset via Position since UIListLayout doesn't support
    -- per-item padding on the cross-axis.
    CfgListOuter.Position         = UDim2.new(0, 12, 0, 0)
    CfgListOuter.Size             = UDim2.new(1, -24, 0, 150)
    CfgActionDivider.Position     = UDim2.new(0, 12, 0, 0)
    CfgActionDivider.Size         = UDim2.new(1, -24, 0, 1)

    -- ── Helpers ───────────────────────────────────────────────────────────
    local function SetStatus(text, color)
        CfgStatusLbl.Text      = text
        CfgStatusLbl.TextColor3 = color or Hyperion.Theme.TextMuted
    end

    local function ShowDeleteConfirm(name)
        DeleteConfirmSub.Text    = '"' .. name .. '" cannot be recovered.'
        DeleteConfirmBar.Visible = true
        Util.Tween(DeleteConfirmBar, 0.18, {Size = UDim2.new(1, -24, 0, 64 + 8)}, Enum.EasingStyle.Quint)
    end
    local function HideDeleteConfirm()
        Util.Tween(DeleteConfirmBar, 0.14, {Size = UDim2.new(1, -24, 0, 0)}, Enum.EasingStyle.Quint)
        task.delay(0.15, function()
            if DeleteConfirmBar and DeleteConfirmBar.Parent then
                DeleteConfirmBar.Visible = false
            end
        end)
    end

    local function RefreshConfigList()
        for _, ch in ipairs(CfgList:GetChildren()) do
            if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then ch:Destroy() end
        end
        local configs = Config.List()
        table.sort(configs)
        if #configs == 0 then
            Util.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size     = UDim2.new(1, 0, 0, 22),
                Text     = "No configs saved yet",
                TextColor3 = Theme.TextMuted,
                FontFace = Theme.Font,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                ZIndex   = 34,
                Parent   = CfgList,
            })
            return
        end
        for _, cfgName in ipairs(configs) do
            local isSel = (cfgName == selectedCfgName)
            local Row = Util.Create("TextButton", {
                Name             = "Row_" .. cfgName,
                BackgroundColor3 = isSel and Theme.SidebarActive or Theme.SurfaceLight,
                BackgroundTransparency = isSel and 0 or 0.5,
                Size             = UDim2.new(1, 0, 0, 26),
                Text             = "",
                AutoButtonColor  = false,
                BorderSizePixel  = 0,
                ZIndex           = 34,
                Parent           = CfgList,
            })
            Util.AddCorner(Row, Theme.CornerSmall)
            if isSel then
                Util.AddStroke(Row, Theme.Accent, 1, 0.45)
            end
            -- Accent pip
            local Pip = Util.Create("Frame", {
                BackgroundColor3 = Theme.Accent,
                Size     = UDim2.new(0, 2, 0.55, 0),
                Position = UDim2.new(0, 0, 0.225, 0),
                BorderSizePixel = 0,
                Visible  = isSel,
                ZIndex   = 35,
                Parent   = Row,
            })
            Util.AddCorner(Pip, UDim.new(1, 0))
            Util.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size     = UDim2.new(1, -14, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                Text     = cfgName,
                TextColor3 = isSel and Theme.Text or Theme.TextDim,
                FontFace = isSel and Theme.FontMedium or Theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex   = 35,
                Parent   = Row,
            })
            Row.MouseEnter:Connect(function()
                if cfgName ~= selectedCfgName then
                    Util.TweenFast(Row, {BackgroundTransparency = 0.2, BackgroundColor3 = Hyperion.Theme.SurfaceHover})
                end
            end)
            Row.MouseLeave:Connect(function()
                if cfgName ~= selectedCfgName then
                    Util.TweenFast(Row, {BackgroundTransparency = 0.5, BackgroundColor3 = Hyperion.Theme.SurfaceLight})
                end
            end)
            Row.MouseButton1Click:Connect(function()
                selectedCfgName = cfgName
                CfgNameBox.Text = cfgName
                SetStatus("Selected: " .. cfgName, Hyperion.Theme.TextDim)
                RefreshConfigList()
                UpdateAutoLoadRow()
            end)
        end
    end

    -- ── Open / close ──────────────────────────────────────────────────────
    local OPEN_POS   = UDim2.new(0, 0, 0, HeaderHeight)
    local CLOSED_POS = UDim2.new(0, -CFG_W - 14, 0, HeaderHeight)

    local CfgSlideClip = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, -20, 0, 0),
        ClipsDescendants = false,
        ZIndex   = 51,
        Parent   = ConfigOverlay,
    })
    CfgScroll.Parent = CfgSlideClip


    local function OpenConfigPanel()
        if cfgPanelOpen then return end
        cfgPanelOpen = true
        _G._HyperionCfgOpen = true
        if _px._closeChat then _px._closeChat() end
        if _px._closeTheme then _px._closeTheme() end
        if _px._closePlayers then _px._closePlayers() end
        HideDeleteConfirm()
        RefreshConfigList()

        ConfigOverlay.Position = CLOSED_POS
        ConfigOverlay.BackgroundTransparency = 1
        ConfigOverlay.Visible = true
        CfgSlideClip.Position = UDim2.new(0, -20, 0, 0)

        Util.Tween(ConfigOverlay, 0.30, {
            Position = OPEN_POS,
            BackgroundTransparency = 0,
        }, Enum.EasingStyle.Quint)
        Util.Tween(CfgSlideClip, 0.30, {Position = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Quint)

        Util.TweenFast(FolderOpenBtn, {
            BackgroundColor3       = Hyperion.Theme.SurfaceActive,
            BackgroundTransparency = 0,
            ImageColor3            = Hyperion.Theme.Accent,
        })
    end

    local function CloseConfigPanel()
        if not cfgPanelOpen then return end
        cfgPanelOpen = false
        _G._HyperionCfgOpen = false
        HideDeleteConfirm()

        Util.Tween(ConfigOverlay, 0.22, {
            Position = CLOSED_POS,
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quint)
        Util.Tween(CfgSlideClip, 0.22, {Position = UDim2.new(0, -20, 0, 0)}, Enum.EasingStyle.Quint)

        Util.TweenFast(FolderOpenBtn, {
            BackgroundColor3       = Hyperion.Theme.SurfaceLight,
            BackgroundTransparency = 0.35,
            ImageColor3            = Hyperion.Theme.TextDim,
        })
        task.delay(0.25, function()
            if not cfgPanelOpen and ConfigOverlay and ConfigOverlay.Parent then
                ConfigOverlay.Visible = false
            end
        end)
    end

    -- Wire up the keybind toggle now that both functions exist
    _cfgPanelToggle = function()
        if Hyperion._configEnabled == false then return end
        if cfgPanelOpen then CloseConfigPanel() else OpenConfigPanel() end
    end

    FolderOpenBtn.MouseButton1Click:Connect(function()
        if Hyperion._configEnabled == false then return end
        if cfgPanelOpen then CloseConfigPanel() else OpenConfigPanel() end
    end)
    CfgCloseBtn.MouseButton1Click:Connect(CloseConfigPanel)

    -- Runtime listener: react to Hyperion:EnableConfig / :DisableConfig so the
    -- folder button appears/disappears live and an open panel closes when
    -- the system is disabled.
    Hyperion:OnConfigEnabledChanged(function(enabled)
        if FolderOpenBtn and FolderOpenBtn.Parent then
            FolderOpenBtn.Visible = enabled
        end
        if not enabled and cfgPanelOpen then
            CloseConfigPanel()
        end
    end)

    -- Click anywhere outside config panel to close it
    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not cfgPanelOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        -- Check if click is inside config overlay
        local cfgPos = ConfigOverlay.AbsolutePosition
        local cfgSize = ConfigOverlay.AbsoluteSize
        local insideCfg = pos.X >= cfgPos.X and pos.X <= cfgPos.X + cfgSize.X
            and pos.Y >= cfgPos.Y and pos.Y <= cfgPos.Y + cfgSize.Y
        -- Check if click is on the folder button
        local btnPos = FolderOpenBtn.AbsolutePosition
        local btnSize = FolderOpenBtn.AbsoluteSize
        local insideBtn = pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X
            and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y
        if not insideCfg and not insideBtn then
            CloseConfigPanel()
        end
    end)

    -- Click anywhere outside info panel to close it
    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not infoOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local infoPos = InfoOverlay.AbsolutePosition
        local infoSize = InfoOverlay.AbsoluteSize
        local insideInfo = pos.X >= infoPos.X and pos.X <= infoPos.X + infoSize.X
            and pos.Y >= infoPos.Y and pos.Y <= infoPos.Y + infoSize.Y
        local btnPos = InfoBtn.AbsolutePosition
        local btnSize = InfoBtn.AbsoluteSize
        local insideBtn = pos.X >= btnPos.X and pos.X <= btnPos.X + btnSize.X
            and pos.Y >= btnPos.Y and pos.Y <= btnPos.Y + btnSize.Y
        if not insideInfo and not insideBtn then
            infoOpen = false
            Util.TweenSmooth(InfoOverlay, {Size = UDim2.new(0, SidebarWidth - 16, 0, 0)})
            Util.TweenFast(InfoBtn, {ImageColor3 = Hyperion.Theme.TextDim, BackgroundTransparency = 0.35})
            task.delay(0.28, function()
                if not infoOpen then InfoOverlay.Visible = false end
            end)
        end
    end)

    -- ── Button logic ──────────────────────────────────────────────────────
    BtnSave.MouseButton1Click:Connect(function()
        local name = (CfgNameBox.Text ~= "" and CfgNameBox.Text) or "default"
        -- Reject names with characters that break filesystems on any executor
        if name:find("[<>:\"/\\|%?%*]") or name:match("^%s*$") then
            SetStatus("Invalid name", Hyperion.Theme.Error)
            Hyperion:Notify({Title="Config", Content="Name contains invalid characters.", Type="Error", Duration=3})
            return
        end
        local overwrite = _rawIsfile("Hyperion/Configs/" .. name .. ".json")
        local ok, err = Config.Save(name, Hyperion.Flags)
        if ok then
            selectedCfgName = name
            RefreshConfigList()
            UpdateAutoLoadRow()
            SetStatus((overwrite and "Overwritten: " or "Saved: ") .. name, Hyperion.Theme.Success)
            Hyperion:Notify({Title = "Config", Content = (overwrite and "Overwritten: " or "Saved: ") .. name, Type = "Success", Duration = 3})
        else
            SetStatus("Save failed", Hyperion.Theme.Error)
            Hyperion:Notify({Title="Config", Content="Save failed: " .. tostring(err or "unknown error"), Type="Error", Duration=5})
        end
    end)

    BtnLoad.MouseButton1Click:Connect(function()
        local name = selectedCfgName or (CfgNameBox.Text ~= "" and CfgNameBox.Text) or nil
        if not name then SetStatus("Select a config first", Theme.Warning); return end
        local ok = Config.Load(name, Hyperion.Flags, Hyperion.FlagCallbacks)
        if ok then
            SetStatus("Loaded: " .. name, Theme.Success)
            Hyperion:Notify({Title = "Config", Content = "Loaded: " .. name, Type = "Success", Duration = 3})
        else
            SetStatus("Not found: " .. name, Theme.Error)
            Hyperion:Notify({Title = "Config", Content = "Not found: " .. name, Type = "Warning", Duration = 3})
        end
    end)

    BtnRename.MouseButton1Click:Connect(function()
        local oldName = selectedCfgName
        local newName = CfgNameBox.Text
        if not oldName or newName == "" or oldName == newName then
            SetStatus(not oldName and "Select a config first" or "Enter a new name", Hyperion.Theme.Warning)
            return
        end
        local path = "Hyperion/Configs/" .. oldName .. ".json"
        if not _rawIsfile(path) then SetStatus("Config not found", Theme.Error); return end
        local ok, raw = pcall(_rawReadfile, path)
        if ok then
            pcall(_rawWritefile, "Hyperion/Configs/" .. newName .. ".json", raw)
            Config.Delete(oldName)
            selectedCfgName = newName
            RefreshConfigList()
            SetStatus("Renamed to: " .. newName, Theme.Success)
            Hyperion:Notify({Title = "Config", Content = "Renamed to: " .. newName, Type = "Success", Duration = 3})
        else
            SetStatus("Rename failed", Theme.Error)
        end
    end)

    BtnNew.MouseButton1Click:Connect(function()
        local base, name, i = "new_config", "new_config", 1
        while _rawIsfile("Hyperion/Configs/" .. name .. ".json") do
            name = base .. "_" .. i; i = i + 1
        end
        CfgNameBox.Text = name
        SetStatus("Name ready: " .. name, Theme.TextDim)
    end)

    BtnRefresh.MouseButton1Click:Connect(function()
        RefreshConfigList()
        SetStatus("Refreshed", Hyperion.Theme.TextDim)
    end)

    BtnDelete.MouseButton1Click:Connect(function()
        local name = selectedCfgName or (CfgNameBox.Text ~= "" and CfgNameBox.Text) or nil
        if not name then SetStatus("Select a config first", Theme.Warning); return end
        ShowDeleteConfirm(name)
    end)

    BtnConfirmDelete.MouseButton1Click:Connect(function()
        local name = selectedCfgName or (CfgNameBox.Text ~= "" and CfgNameBox.Text) or nil
        if not name then HideDeleteConfirm(); return end
        local ok = Config.Delete(name)
        HideDeleteConfirm()
        if ok then
            if selectedCfgName == name then selectedCfgName = nil; CfgNameBox.Text = "" end
            RefreshConfigList()
            SetStatus("Deleted: " .. name, Theme.TextDim)
            Hyperion:Notify({Title = "Config", Content = "Deleted: " .. name, Type = "Info", Duration = 3})
        else
            SetStatus("Not found: " .. name, Theme.Error)
        end
    end)

    BtnCancelDelete.MouseButton1Click:Connect(HideDeleteConfirm)

    RefreshConfigList()

    -- ================================================================
    -- AI CHAT PANEL
    -- Mirrors the config panel: slides in from the left over the sidebar.
    -- ================================================================
    ;(function()
    local CHAT_W          = 300
    local CHAT_INPUT_H    = 46
    local CHAT_HEADER_H   = 42
    local CHAT_BAR_H      = 36
    local chatPanelOpen   = false
    local chatSendHandler = nil
    local personaHandler  = nil
    local newChatHandler  = nil
    local currentPersona  = ""
    _G._HyperionChatOpen  = false

    local ChatOverlay = Util.Create("Frame", {
        Name             = "ChatOverlay",
        BackgroundColor3 = Theme.Sidebar,
        Size             = UDim2.new(0, CHAT_W, 1, -HeaderHeight),
        Position         = UDim2.new(0, -CHAT_W - 14, 0, HeaderHeight),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 50,
        Parent           = MainFrame,
    })
    Util.AddCorner(ChatOverlay, Theme.CornerRadius)
    local _chatStroke = Util.AddStroke(ChatOverlay, Theme.BorderLight, 1, 0.12)
    Themed(ChatOverlay, { BackgroundColor3 = function(t) return t.Sidebar end })
    Themed(_chatStroke, { Color = function(t) return t.BorderLight end })

    local ChatClip = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size     = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, -20, 0, 0),
        ClipsDescendants = false,
        ZIndex   = 51,
        Parent   = ChatOverlay,
    })

    -- ── Header strip ──────────────────────────────────────────────────────
    local ChatHeader = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive,
        Size     = UDim2.new(1, 0, 0, CHAT_HEADER_H),
        BorderSizePixel = 0,
        ZIndex   = 52,
        Parent   = ChatClip,
    })
    Themed(ChatHeader, { BackgroundColor3 = function(t) return t.SidebarActive end })
    do
        local al = Util.Create("Frame", {
            BackgroundColor3 = Color3.new(1,1,1),
            Size = UDim2.new(1,0,0,1),
            BorderSizePixel = 0, ZIndex = 53, Parent = ChatHeader,
        })
        local g = Util.Create("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.AccentDark),
                ColorSequenceKeypoint.new(0.5, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentDark),
            }),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.5),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 0.5),
            }),
            Parent = al,
        })
        Themed(g, { Color = function(t)
            return ColorSequence.new({
                ColorSequenceKeypoint.new(0, t.AccentDark),
                ColorSequenceKeypoint.new(0.5, t.Accent),
                ColorSequenceKeypoint.new(1, t.AccentDark),
            })
        end })
    end

    local ChatTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 7),
        Size     = UDim2.new(1, -52, 0, 16),
        Text     = "AI Assistant",
        TextColor3 = Theme.Text,
        FontFace = Theme.FontBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 53,
        Parent   = ChatHeader,
    })
    Themed(ChatTitle, { TextColor3 = function(t) return t.Text end })

    local ChatStatus = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 25),
        Size     = UDim2.new(1, -52, 0, 12),
        Text     = "Ready",
        TextColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex   = 53,
        Parent   = ChatHeader,
    })
    Themed(ChatStatus, { TextColor3 = function(t) return t.TextMuted end })

    local ChatCloseBtn = Util.Create("ImageButton", {
        BackgroundColor3 = Theme.SurfaceActive,
        BackgroundTransparency = 0.4,
        Size     = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image    = "rbxassetid://10747384394",
        ImageColor3 = Theme.TextDim,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        ZIndex   = 54,
        Parent   = ChatHeader,
    })
    Util.AddCorner(ChatCloseBtn, Theme.CornerSmall)
    Themed(ChatCloseBtn, {
        BackgroundColor3 = function(t) return t.SurfaceActive end,
        ImageColor3      = function(t) return t.TextDim end,
    })
    ChatCloseBtn.MouseEnter:Connect(function()
        Util.TweenFast(ChatCloseBtn, {BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Error})
    end)
    ChatCloseBtn.MouseLeave:Connect(function()
        Util.TweenFast(ChatCloseBtn, {BackgroundTransparency = 0.4, ImageColor3 = Hyperion.Theme.TextDim})
    end)

    local PersonaBar = Util.Create("Frame", {
        BackgroundColor3 = Theme.Sidebar,
        Position = UDim2.new(0, 0, 0, CHAT_HEADER_H),
        Size     = UDim2.new(1, 0, 0, CHAT_BAR_H),
        BorderSizePixel = 0,
        ZIndex   = 52,
        Parent   = ChatClip,
    })
    Themed(PersonaBar, { BackgroundColor3 = function(t) return t.Sidebar end })

    local PersonaBtn = Util.Create("TextButton", {
        BackgroundColor3 = Theme.SurfaceLight,
        BackgroundTransparency = 0.2,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size     = UDim2.new(1, -104, 0, 26),
        Text     = "Select persona",
        TextColor3 = Theme.Text,
        FontFace = Theme.FontMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        ZIndex   = 53,
        Parent   = PersonaBar,
    })
    Util.AddCorner(PersonaBtn, Theme.CornerSmall)
    Util.AddPadding(PersonaBtn, 0, 24, 0, 10)
    local _pbStroke = Util.AddStroke(PersonaBtn, Theme.Border, 1, 0.4)
    Themed(PersonaBtn, { BackgroundColor3 = function(t) return t.SurfaceLight end, TextColor3 = function(t) return t.Text end })
    Themed(_pbStroke, { Color = function(t) return t.Border end })
    local PersonaArrow = Util.Create("ImageLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 14, 0, 14),
        Image = "rbxassetid://134387593103194",
        ImageColor3 = Theme.TextMuted,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 54,
        Parent = PersonaBtn,
    })
    Themed(PersonaArrow, { ImageColor3 = function(t) return t.TextMuted end })

    local NewChatBtn = Util.Create("TextButton", {
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.85,
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size     = UDim2.new(0, 80, 0, 26),
        Text     = "New Chat",
        TextColor3 = Theme.Accent,
        FontFace = Theme.FontMedium,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex   = 53,
        Parent   = PersonaBar,
    })
    Util.AddCorner(NewChatBtn, Theme.CornerSmall)
    local _ncStroke = Util.AddStroke(NewChatBtn, Theme.Accent, 1, 0.5)
    Themed(NewChatBtn, { TextColor3 = function(t) return t.Accent end, BackgroundColor3 = function(t) return t.Accent end })
    Themed(_ncStroke, { Color = function(t) return t.Accent end })
    NewChatBtn.MouseEnter:Connect(function() Util.TweenFast(NewChatBtn, {BackgroundTransparency = 0.7}) end)
    NewChatBtn.MouseLeave:Connect(function() Util.TweenFast(NewChatBtn, {BackgroundTransparency = 0.85}) end)

    local PersonaList = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive,
        Position = UDim2.new(0, 10, 0, CHAT_HEADER_H + CHAT_BAR_H - 4),
        Size     = UDim2.new(1, -104, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Visible  = false,
        ClipsDescendants = true,
        ZIndex   = 60,
        Parent   = ChatClip,
    })
    Util.AddCorner(PersonaList, Theme.CornerSmall)
    local _plStroke = Util.AddStroke(PersonaList, Theme.BorderLight, 1, 0.1)
    Themed(PersonaList, { BackgroundColor3 = function(t) return t.SidebarActive end })
    Themed(_plStroke, { Color = function(t) return t.BorderLight end })
    local PersonaListInner = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 61,
        Parent = PersonaList,
    })
    Util.AddList(PersonaListInner, Enum.FillDirection.Vertical, 2)
    Util.AddPadding(PersonaListInner, 4, 4, 4, 4)

    local personaListOpen = false
    local function ClosePersonaList()
        if not personaListOpen then return end
        personaListOpen = false
        Util.TweenFast(PersonaArrow, { Rotation = 0 })
        task.delay(0.02, function() PersonaList.Visible = false end)
    end
    local function OpenPersonaList()
        if personaListOpen then return end
        personaListOpen = true
        PersonaList.Visible = true
        Util.TweenFast(PersonaArrow, { Rotation = 180 })
    end
    local function SetPersonaText(name)
        currentPersona = name
        PersonaBtn.Text = name
    end
    local function BuildPersonaList(list)
        for _, c in ipairs(PersonaListInner:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, name in ipairs(list) do
            local Item = Util.Create("TextButton", {
                BackgroundColor3 = Theme.SurfaceLight,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 26),
                Text = name,
                TextColor3 = Theme.Text,
                FontFace = Theme.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 62,
                Parent = PersonaListInner,
            })
            Util.AddCorner(Item, Theme.CornerSmall)
            Util.AddPadding(Item, 0, 8, 0, 8)
            Themed(Item, { TextColor3 = function(t) return t.Text end })
            Item.MouseEnter:Connect(function() Util.TweenFast(Item, {BackgroundTransparency = 0.4, BackgroundColor3 = Hyperion.Theme.SurfaceHover}) end)
            Item.MouseLeave:Connect(function() Util.TweenFast(Item, {BackgroundTransparency = 1}) end)
            Item.MouseButton1Click:Connect(function()
                SetPersonaText(name)
                ClosePersonaList()
                if personaHandler then task.spawn(personaHandler, name) end
            end)
        end
        if currentPersona == "" and list[1] then SetPersonaText(list[1]) end
    end

    PersonaBtn.MouseButton1Click:Connect(function()
        if personaListOpen then ClosePersonaList() else OpenPersonaList() end
    end)

    -- ── Message log ─────────────────────────────────────────────────────────
    local ChatLog = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, CHAT_HEADER_H + CHAT_BAR_H),
        Size     = UDim2.new(1, 0, 1, -(CHAT_HEADER_H + CHAT_BAR_H + CHAT_INPUT_H)),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        ZIndex   = 52,
        Parent   = ChatClip,
    })
    Util.AddList(ChatLog, Enum.FillDirection.Vertical, 8)
    Util.AddPadding(ChatLog, 10, 10, 10, 10)
    Themed(ChatLog, { ScrollBarImageColor3 = function(t) return t.Accent end })

    local ChatHint = nil
    local function ShowChatHint()
        if ChatHint and ChatHint.Parent then return end
        ChatHint = Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Text = "Ask the assistant anything.",
            TextColor3 = Theme.TextMuted,
            FontFace = Theme.Font,
            TextSize = 12,
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 52,
            Parent = ChatLog,
        })
        Themed(ChatHint, { TextColor3 = function(t) return t.TextMuted end })
    end
    ShowChatHint()

    local function AddChatBubble(role, text)
        if ChatHint and ChatHint.Parent then ChatHint:Destroy() end
        ChatHint = nil
        local isUser = (role == "user")
        local maxW = math.floor(CHAT_W * 0.74)

        local Row = Util.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 52,
            Parent = ChatLog,
        })
        local Bubble = Util.Create("Frame", {
            BackgroundColor3 = isUser and Theme.Accent or Theme.SurfaceLight,
            AnchorPoint = Vector2.new(isUser and 1 or 0, 0),
            Position = UDim2.new(isUser and 1 or 0, 0, 0, 0),
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            ZIndex = 53,
            Parent = Row,
        })
        Util.AddCorner(Bubble, Theme.CornerRadius)
        Util.AddPadding(Bubble, 7, 10, 7, 10)
        Util.Create("UISizeConstraint", { MaxSize = Vector2.new(maxW, math.huge), Parent = Bubble })

        local Msg = Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.XY,
            Text = text,
            TextColor3 = isUser and Color3.fromRGB(255,255,255) or Theme.Text,
            FontFace = Theme.Font,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 54,
            Parent = Bubble,
        })
        Util.Create("UISizeConstraint", { MaxSize = Vector2.new(maxW - 20, math.huge), Parent = Msg })
        if not isUser then
            Themed(Bubble, { BackgroundColor3 = function(t) return t.SurfaceLight end })
            Themed(Msg, { TextColor3 = function(t) return t.Text end })
        else
            Themed(Bubble, { BackgroundColor3 = function(t) return t.Accent end })
        end

        task.defer(function()
            if ChatLog and ChatLog.Parent then
                ChatLog.CanvasPosition = Vector2.new(0, ChatLog.AbsoluteCanvasSize.Y)
            end
        end)
        return Msg
    end

    local function SetChatStatus(t) ChatStatus.Text = t or "Ready" end
    local function ClearChatLog()
        for _, c in ipairs(ChatLog:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
        ChatHint = nil
        ShowChatHint()
        SetChatStatus("Ready")
    end

    NewChatBtn.MouseButton1Click:Connect(function()
        ClearChatLog()
        if newChatHandler then task.spawn(newChatHandler) end
    end)

    -- ── Input bar ─────────────────────────────────────────────────────────
    local ChatInputBar = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive,
        Position = UDim2.new(0, 0, 1, -CHAT_INPUT_H),
        Size = UDim2.new(1, 0, 0, CHAT_INPUT_H),
        BorderSizePixel = 0,
        ZIndex = 52,
        Parent = ChatClip,
    })
    Themed(ChatInputBar, { BackgroundColor3 = function(t) return t.SidebarActive end })
    local _chatInputSep = Util.Create("Frame", {
        BackgroundColor3 = Theme.Border, BackgroundTransparency = 0.4,
        Size = UDim2.new(1,0,0,1), BorderSizePixel = 0, ZIndex = 53, Parent = ChatInputBar,
    })
    Themed(_chatInputSep, { BackgroundColor3 = function(t) return t.Border end })

    local ChatInput = Util.Create("TextBox", {
        BackgroundColor3 = Theme.InputBg,
        Position = UDim2.new(0, 10, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(1, -54, 0, 30),
        Text = "",
        PlaceholderText = "Message...",
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        ZIndex = 53,
        Parent = ChatInputBar,
    })
    Util.AddCorner(ChatInput, Theme.CornerSmall)
    Util.AddPadding(ChatInput, 0, 8, 0, 8)
    local _chatInStroke = Util.AddStroke(ChatInput, Theme.Border, 1, 0.3)
    Themed(ChatInput, {
        BackgroundColor3 = function(t) return t.InputBg end,
        TextColor3 = function(t) return t.Text end,
        PlaceholderColor3 = function(t) return t.TextMuted end,
    })
    Themed(_chatInStroke, { Color = function(t) return t.Border end })
    ChatInput.Focused:Connect(function()
        Util.TweenFast(_chatInStroke, {Color = Hyperion.Theme.Accent, Transparency = 0})
    end)
    ChatInput.FocusLost:Connect(function()
        Util.TweenFast(_chatInStroke, {Color = Hyperion.Theme.Border, Transparency = 0.3})
    end)

    local ChatSendBtn = Util.Create("TextButton", {
        BackgroundColor3 = Theme.Accent,
        Position = UDim2.new(1, -10, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        Size = UDim2.new(0, 34, 0, 30),
        Text = "→",
        TextColor3 = Color3.fromRGB(255,255,255),
        FontFace = Theme.FontBold,
        TextSize = 18,
        AutoButtonColor = false,
        ZIndex = 53,
        Parent = ChatInputBar,
    })
    Util.AddCorner(ChatSendBtn, Theme.CornerSmall)
    Themed(ChatSendBtn, { BackgroundColor3 = function(t) return t.Accent end })
    ChatSendBtn.MouseEnter:Connect(function() Util.TweenFast(ChatSendBtn, {BackgroundColor3 = Hyperion.Theme.AccentLight}) end)
    ChatSendBtn.MouseLeave:Connect(function() Util.TweenFast(ChatSendBtn, {BackgroundColor3 = Hyperion.Theme.Accent}) end)

    local function DoChatSend()
        local txt = ChatInput.Text or ""
        txt = txt:gsub("^%s+", ""):gsub("%s+$", "")
        if txt == "" then return end
        ChatInput.Text = ""
        AddChatBubble("user", txt)
        if chatSendHandler then task.spawn(chatSendHandler, txt) end
    end
    ChatSendBtn.MouseButton1Click:Connect(DoChatSend)
    ChatInput.FocusLost:Connect(function(enter) if enter then DoChatSend() end end)

    -- ── Open / close ──────────────────────────────────────────────────────
    local CHAT_OPEN   = UDim2.new(0, 0, 0, HeaderHeight)
    local CHAT_CLOSED = UDim2.new(0, -CHAT_W - 14, 0, HeaderHeight)

    local function OpenChatPanel()
        if chatPanelOpen then return end
        chatPanelOpen = true
        _G._HyperionChatOpen = true
        if cfgPanelOpen then CloseConfigPanel() end
        if _px._closeTheme then _px._closeTheme() end
        if _px._closePlayers then _px._closePlayers() end
        ChatOverlay.Position = CHAT_CLOSED
        ChatOverlay.BackgroundTransparency = 1
        ChatOverlay.Visible = true
        ChatClip.Position = UDim2.new(0, -20, 0, 0)
        Util.Tween(ChatOverlay, 0.30, { Position = CHAT_OPEN, BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        Util.Tween(ChatClip, 0.30, { Position = UDim2.new(0,0,0,0) }, Enum.EasingStyle.Quint)
        Util.TweenFast(ChatBtn, { BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Accent })
    end

    local function CloseChatPanel()
        if not chatPanelOpen then return end
        chatPanelOpen = false
        _G._HyperionChatOpen = false
        ClosePersonaList()
        Util.Tween(ChatOverlay, 0.22, { Position = CHAT_CLOSED, BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        Util.Tween(ChatClip, 0.22, { Position = UDim2.new(0,-20,0,0) }, Enum.EasingStyle.Quint)
        Util.TweenFast(ChatBtn, { BackgroundTransparency = 0.5, ImageColor3 = Hyperion.Theme.TextMuted })
        task.delay(0.25, function()
            if not chatPanelOpen and ChatOverlay and ChatOverlay.Parent then ChatOverlay.Visible = false end
        end)
    end

    _px._closeChat = CloseChatPanel

    ChatBtn.MouseButton1Click:Connect(function()
        if chatPanelOpen then CloseChatPanel() else OpenChatPanel() end
    end)
    ChatCloseBtn.MouseButton1Click:Connect(CloseChatPanel)

    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not chatPanelOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local oPos, oSize = ChatOverlay.AbsolutePosition, ChatOverlay.AbsoluteSize
        local insidePanel = pos.X >= oPos.X and pos.X <= oPos.X + oSize.X
            and pos.Y >= oPos.Y and pos.Y <= oPos.Y + oSize.Y
        local bPos, bSize = ChatBtn.AbsolutePosition, ChatBtn.AbsoluteSize
        local insideBtn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X
            and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
        if not insidePanel and not insideBtn then CloseChatPanel() end
    end)

    -- Themed accent state for the bottom Chat button
    Themed(ChatBtn, {
        ImageColor3 = function(t)
            return _G._HyperionChatOpen and t.Accent or t.TextMuted
        end,
    })

    _px._openChat      = OpenChatPanel
    _px._toggleChat    = function() if chatPanelOpen then CloseChatPanel() else OpenChatPanel() end end
    _px._addChatMsg    = function(role, text) AddChatBubble(role == "user" and "user" or "ai", tostring(text)) end
    _px._setChatStatus = SetChatStatus
    _px._clearChat     = ClearChatLog
    _px._setChatSend   = function(fn) chatSendHandler = fn end
    _px._setChatPersonas = function(list) BuildPersonaList(list) end
    _px._onPersonaChange = function(fn) personaHandler = fn end
    _px._onNewChat       = function(fn) newChatHandler = fn end
    _px._getPersona      = function() return currentPersona end
    end)() -- AI CHAT PANEL scope


    -- ================================================================
    -- KEYBIND HUD  (on-screen list, left side; click a key to rebind)
    -- ================================================================
    ;(function()
    local kbHudVisible = false
    local KbHud = Util.Create("Frame", {
        Name = "KeybindHUD",
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 0.05,
        Size = UDim2.new(0, 198, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Position = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Visible = false,
        ZIndex = 60,
        Parent = ScreenGui,
    })
    Util.AddCorner(KbHud, Theme.CornerLarge)
    local _kbHudStroke = Util.AddStroke(KbHud, Theme.BorderLight, 1, 0.15)
    Themed(KbHud, { BackgroundColor3 = function(t) return t.Sidebar end })
    Themed(_kbHudStroke, { Color = function(t) return t.BorderLight end })

    local _kbAccent = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        Size = UDim2.new(1, -16, 0, 2),
        Position = UDim2.new(0, 8, 0, 6),
        BorderSizePixel = 0, ZIndex = 62, Parent = KbHud,
    })
    Util.AddCorner(_kbAccent, UDim.new(1, 0))
    local _kbAccentGrad = Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.AccentDark),
            ColorSequenceKeypoint.new(0.5, Theme.Accent),
            ColorSequenceKeypoint.new(1, Theme.AccentDark),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.5),
        }),
        Parent = _kbAccent,
    })
    Themed(_kbAccentGrad, { Color = function(t)
        return ColorSequence.new({
            ColorSequenceKeypoint.new(0, t.AccentDark),
            ColorSequenceKeypoint.new(0.5, t.Accent),
            ColorSequenceKeypoint.new(1, t.AccentDark),
        })
    end })

    local KbHudInner = Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 61,
        Parent = KbHud,
    })
    Util.AddList(KbHudInner, Enum.FillDirection.Vertical, 5)
    Util.AddPadding(KbHudInner, 12, 11, 11, 11)

    local KbHudTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = "KEYBINDS",
        TextColor3 = Theme.TextDim,
        FontFace = Theme.FontBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 0,
        ZIndex = 62,
        Parent = KbHudInner,
    })
    Themed(KbHudTitle, { TextColor3 = function(t) return t.TextDim end })

    local KbEmpty = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 16),
        Text = "No keybinds set.",
        TextColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 1,
        ZIndex = 62,
        Parent = KbHudInner,
    })
    Themed(KbEmpty, { TextColor3 = function(t) return t.TextMuted end })

    local kbRows = {}
    local kbRowOrder = 1

    local function MakeKbRow(entry)
        if kbRows[entry] then return end
        KbEmpty.Visible = false
        kbRowOrder = kbRowOrder + 1
        local Row = Util.Create("Frame", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = kbRowOrder,
            ZIndex = 62,
            Parent = KbHudInner,
        })
        local NameLbl = Util.Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -78, 1, 0),
            Text = entry.Name,
            TextColor3 = Theme.Text,
            FontFace = Theme.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 62,
            Parent = Row,
        })
        Themed(NameLbl, { TextColor3 = function(t) return t.Text end })
        local Btn = Util.Create("TextButton", {
            BackgroundColor3 = Theme.SurfaceLight,
            Size = UDim2.new(0, 72, 0, 20),
            Position = UDim2.new(1, 0, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            Text = entry.KeyName and entry.KeyName() or "None",
            TextColor3 = Theme.TextDim,
            FontFace = Theme.FontMedium,
            TextSize = 11,
            AutoButtonColor = false,
            ZIndex = 63,
            Parent = Row,
        })
        Util.AddCorner(Btn, Theme.CornerSmall)
        local bStroke = Util.AddStroke(Btn, Theme.BorderLight, 1, 0.3)
        Themed(Btn, { BackgroundColor3 = function(t) return t.SurfaceLight end, TextColor3 = function(t) return t.TextDim end })
        Themed(bStroke, { Color = function(t) return t.BorderLight end })
        Btn.MouseEnter:Connect(function() Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.SurfaceHover}) end)
        Btn.MouseLeave:Connect(function() Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.SurfaceLight}) end)
        Btn.MouseButton1Click:Connect(function()
            Btn.Text = "..."
            Util.TweenFast(bStroke, {Color = Hyperion.Theme.Accent, Transparency = 0})
            if entry.StartRebind then entry.StartRebind() end
        end)
        kbRows[entry] = { Btn = Btn, Stroke = bStroke }
    end

    local function UpdateKbRow(entry)
        local r = kbRows[entry]
        if not r then return end
        r.Btn.Text = entry.KeyName and entry.KeyName() or "None"
        Util.TweenFast(r.Stroke, {Color = Hyperion.Theme.BorderLight, Transparency = 0.3})
    end

    Hyperion:OnKeybindEvent(function(kind, entry)
        if kind == "added" then MakeKbRow(entry)
        elseif kind == "changed" then UpdateKbRow(entry)
        elseif kind == "listening" then
            local r = kbRows[entry]
            if r then
                r.Btn.Text = "..."
                Util.TweenFast(r.Stroke, {Color = Hyperion.Theme.Accent, Transparency = 0})
            end
        end
    end)
    for _, e in ipairs(Hyperion.Keybinds) do MakeKbRow(e) end

    local function SetKbHud(vis)
        kbHudVisible = vis
        KbHud.Visible = vis
        Util.TweenFast(KeybindBtn, { ImageColor3 = vis and Hyperion.Theme.Accent or Hyperion.Theme.TextMuted })
    end
    KeybindBtn.MouseButton1Click:Connect(function() SetKbHud(not kbHudVisible) end)
    Themed(KeybindBtn, { ImageColor3 = function(t) return kbHudVisible and t.Accent or t.TextMuted end })

    _px._showKb   = function() SetKbHud(true)  end
    _px._hideKb   = function() SetKbHud(false) end
    _px._toggleKb = function() SetKbHud(not kbHudVisible) end
    end)() -- KEYBIND HUD scope

    -- ================================================================
    -- THEME CREATOR PANEL  (slides in from the left, like Config/Chat)
    -- ================================================================
    ;(function()
    local THEME_W        = 280
    local themePanelOpen = false

    local function _lighten(c, f) return Color3.new(
        math.clamp(c.R + (1 - c.R) * f, 0, 1),
        math.clamp(c.G + (1 - c.G) * f, 0, 1),
        math.clamp(c.B + (1 - c.B) * f, 0, 1)) end
    local function _darken(c, f) return Color3.new(
        math.clamp(c.R * (1 - f), 0, 1),
        math.clamp(c.G * (1 - f), 0, 1),
        math.clamp(c.B * (1 - f), 0, 1)) end

    local function BuildTheme(w)
        local t = {
            Accent = w.Accent, AccentDark = _darken(w.Accent, 0.25), AccentLight = _lighten(w.Accent, 0.25),
            AccentGlow = w.Accent, AccentSub = _darken(w.Accent, 0.4),
            Background = w.Background, Surface = w.Surface,
            SurfaceLight = w.SurfaceLight, SurfaceHover = _lighten(w.SurfaceLight, 0.12), SurfaceActive = _lighten(w.SurfaceLight, 0.2),
            Sidebar = w.Sidebar, SidebarActive = _lighten(w.Sidebar, 0.18),
            Text = w.Text, TextDim = _darken(w.Text, 0.32), TextMuted = _darken(w.Text, 0.58),
            Border = w.Border, BorderLight = _lighten(w.Border, 0.3),
            ToggleOff = w.SurfaceLight, SliderBg = _darken(w.SurfaceLight, 0.2), InputBg = _darken(w.Background, 0.15),
        }
        if w.Animated then
            local a = w.GradA or w.Background
            local b = w.GradB or w.Accent
            t.Animated = true
            t.ParticleStyle = w.Particle or "stars"
            t.StarColor = w.StarColor or Color3.fromRGB(180, 205, 255)
            t.GradientStops = {
                {0,   a},
                {0.3, b},
                {0.5, _lighten(b, 0.12)},
                {0.7, b},
                {1,   a},
            }
        end
        return t
    end

    local THEME_FIELDS = {
        {key="Accent",       label="Accent"},
        {key="Background",   label="Background"},
        {key="Surface",      label="Surface"},
        {key="SurfaceLight", label="Surface 2"},
        {key="Sidebar",      label="Sidebar"},
        {key="Text",         label="Text"},
        {key="Border",       label="Border"},
        {key="GradA",        label="Grad 1", anim=true, default=Color3.fromRGB(8, 10, 26)},
        {key="GradB",        label="Grad 2", anim=true, default=Color3.fromRGB(30, 42, 96)},
        {key="StarColor",    label="Stars",  anim=true, default=Color3.fromRGB(180, 205, 255)},
    }
    local THEME_STYLES = { "stars", "petals", "hearts", "snowflakes", "embers", "bubbles", "paws", "wisps", "orbs", "gridlines", "halloween", "strawberry", "christmaslights" }
    local working = {}
    for _, f in ipairs(THEME_FIELDS) do working[f.key] = Theme[f.key] or f.default end
    working.Animated = Theme.Animated == true
    working.Particle = Theme.ParticleStyle or "stars"

    -- ThemeStore: persistence parallel to Config
    local ThemeStore = {}
    function ThemeStore.EnsureFolder()
        if not _rawIsfolder("Hyperion") then pcall(_rawMakefolder, "Hyperion") end
        if not _rawIsfolder("Hyperion/Themes") then pcall(_rawMakefolder, "Hyperion/Themes") end
    end
    function ThemeStore.Save(name, w)
        ThemeStore.EnsureFolder()
        local data = { Animated = w.Animated == true, Particle = w.Particle or "stars" }
        for _, f in ipairs(THEME_FIELDS) do
            local c = w[f.key]
            if c then data[f.key] = { R = c.R, G = c.G, B = c.B } end
        end
        local okEnc, enc = pcall(HttpService.JSONEncode, HttpService, data)
        if not okEnc then return false end
        local okW = pcall(_rawWritefile, "Hyperion/Themes/" .. name .. ".json", enc)
        return okW and _rawIsfile("Hyperion/Themes/" .. name .. ".json")
    end
    function ThemeStore.Load(name)
        local path = "Hyperion/Themes/" .. name .. ".json"
        if not _rawIsfile(path) then return nil end
        local ok, raw = pcall(_rawReadfile, path)
        if not ok then return nil end
        local ok2, data = pcall(HttpService.JSONDecode, HttpService, raw)
        if not ok2 or type(data) ~= "table" then return nil end
        local w = {}
        for _, f in ipairs(THEME_FIELDS) do
            local c = data[f.key]
            if type(c) == "table" then w[f.key] = Color3.new(c.R or 0, c.G or 0, c.B or 0) end
            if w[f.key] == nil and f.default then w[f.key] = f.default end
        end
        w.Animated = data.Animated == true
        w.Particle = data.Particle or "stars"
        return w
    end
    function ThemeStore.List()
        ThemeStore.EnsureFolder()
        local out = {}
        local ok, files = pcall(_rawListfiles, "Hyperion/Themes")
        if ok then
            for _, fl in ipairs(files) do
                local n = string.match(fl, "([^/\\]+)%.json$")
                if n then table.insert(out, n) end
            end
        end
        return out
    end
    function ThemeStore.Delete(name)
        local path = "Hyperion/Themes/" .. name .. ".json"
        if not _rawIsfile(path) then return true end
        local removeFn = (typeof(delfile) == "function" and delfile)
            or (typeof(fremovefile) == "function" and fremovefile)
            or nil
        if removeFn then pcall(removeFn, path) end
        return not _rawIsfile(path)
    end

    -- Register any saved themes so they are known to Hyperion.Themes
    for _, n in ipairs(ThemeStore.List()) do
        local w = ThemeStore.Load(n)
        if w then Hyperion.Themes[n] = BuildTheme(w) end
    end

    local ThemeOverlay = Util.Create("Frame", {
        Name             = "ThemeOverlay",
        BackgroundColor3 = Theme.Sidebar,
        Size             = UDim2.new(0, THEME_W, 1, -HeaderHeight),
        Position         = UDim2.new(0, -THEME_W - 14, 0, HeaderHeight),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 50,
        Parent           = MainFrame,
    })
    Util.AddCorner(ThemeOverlay, Theme.CornerRadius)
    local _thStroke = Util.AddStroke(ThemeOverlay, Theme.BorderLight, 1, 0.12)
    Themed(ThemeOverlay, { BackgroundColor3 = function(t) return t.Sidebar end })
    Themed(_thStroke, { Color = function(t) return t.BorderLight end })

    local ThemeScroll = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.Accent,
        ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0),
        ZIndex = 51,
        Parent = ThemeOverlay,
    })
    Util.AddList(ThemeScroll, Enum.FillDirection.Vertical, 8)
    Util.AddPadding(ThemeScroll, 0, 10, 10, 10)
    Themed(ThemeScroll, { ScrollBarImageColor3 = function(t) return t.Accent end })

    -- Header strip
    local ThHeader = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive,
        Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0,
        LayoutOrder = 0,
        ZIndex = 52,
        Parent = ThemeScroll,
    })
    Themed(ThHeader, { BackgroundColor3 = function(t) return t.SidebarActive end })
    local ThTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 7),
        Size = UDim2.new(1, -52, 0, 16),
        Text = "Theme Creator",
        TextColor3 = Theme.Text,
        FontFace = Theme.FontBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53,
        Parent = ThHeader,
    })
    Themed(ThTitle, { TextColor3 = function(t) return t.Text end })
    local ThStatus = Util.Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 25),
        Size = UDim2.new(1, -52, 0, 12),
        Text = "Editing: Accent",
        TextColor3 = Theme.TextMuted,
        FontFace = Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53,
        Parent = ThHeader,
    })
    Themed(ThStatus, { TextColor3 = function(t) return t.TextMuted end })
    local ThCloseBtn = Util.Create("ImageButton", {
        BackgroundColor3 = Theme.SurfaceActive,
        BackgroundTransparency = 0.4,
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Image = "rbxassetid://10747384394",
        ImageColor3 = Theme.TextDim,
        ScaleType = Enum.ScaleType.Fit,
        AutoButtonColor = false,
        ZIndex = 54,
        Parent = ThHeader,
    })
    Util.AddCorner(ThCloseBtn, Theme.CornerSmall)
    Themed(ThCloseBtn, { BackgroundColor3 = function(t) return t.SurfaceActive end, ImageColor3 = function(t) return t.TextDim end })
    ThCloseBtn.MouseEnter:Connect(function() Util.TweenFast(ThCloseBtn, {BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Error}) end)
    ThCloseBtn.MouseLeave:Connect(function() Util.TweenFast(ThCloseBtn, {BackgroundTransparency = 0.4, ImageColor3 = Hyperion.Theme.TextDim}) end)

    -- Name box
    local ThNameWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 1, ZIndex = 52, Parent = ThemeScroll })
    local ThNameBox = Util.Create("TextBox", {
        BackgroundColor3 = Theme.InputBg,
        Size = UDim2.new(1, 0, 1, 0),
        Text = "", PlaceholderText = "theme name...",
        TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted,
        FontFace = Theme.FontMedium, TextSize = 12,
        ClearTextOnFocus = false, BorderSizePixel = 0,
        ZIndex = 53, Parent = ThNameWrap,
    })
    Util.AddCorner(ThNameBox, Theme.CornerSmall)
    Util.AddPadding(ThNameBox, 0, 8, 0, 8)
    local _thNameStroke = Util.AddStroke(ThNameBox, Theme.Border, 1, 0.3)
    Themed(ThNameBox, { BackgroundColor3 = function(t) return t.InputBg end, TextColor3 = function(t) return t.Text end, PlaceholderColor3 = function(t) return t.TextMuted end })
    Themed(_thNameStroke, { Color = function(t) return t.Border end })

    -- Swatch row
    local ThSwatchWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 2, ZIndex = 52, Parent = ThemeScroll })
    Util.AddList(ThSwatchWrap, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local selectedField = "Accent"
    local swatches = {}
    local hueState = { h = 0, s = 0, v = 0 }

    -- forward declares
    local SVBox, SVCursor, HueBar, HueCur, HexLabel
    local _applyLast, _applyQueued = 0, false
    local function ApplyLive()
        local now = os.clock()
        if now - _applyLast >= 0.05 then
            _applyLast = now
            Hyperion:SetTheme(BuildTheme(working))
        elseif not _applyQueued then
            _applyQueued = true
            task.delay(0.05, function()
                _applyQueued = false
                _applyLast = os.clock()
                Hyperion:SetTheme(BuildTheme(working))
            end)
        end
    end
    local function ToHex(c) return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5)) end

    local function LoadFieldIntoPicker()
        local c = working[selectedField]
        hueState.h, hueState.s, hueState.v = Color3.toHSV(c)
        Util.TweenFast(SVBox, { BackgroundColor3 = Color3.fromHSV(hueState.h, 1, 1) })
        Util.TweenFast(SVCursor, { Position = UDim2.new(hueState.s, 0, 1 - hueState.v, 0) })
        Util.TweenFast(HueCur, { Position = UDim2.new(0.5, 0, hueState.h, 0) })
        HexLabel.Text = ToHex(c)
        ThStatus.Text = "Editing: " .. selectedField
    end

    local function SelectField(key)
        selectedField = key
        for k, sw in pairs(swatches) do
            local sel = (k == key)
            Util.TweenFast(sw.Stroke, {
                Color = sel and Hyperion.Theme.Accent or Hyperion.Theme.BorderLight,
                Thickness = sel and 2.5 or 1,
                Transparency = sel and 0 or 0.1,
            })
        end
        LoadFieldIntoPicker()
    end

    local ThAnimToggleWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 5, ZIndex = 52, Parent = ThemeScroll })
    local ThAnimLabel = Util.Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0, 2, 0, 0),
        Text = "Animated Background", TextColor3 = Theme.Text,
        FontFace = Theme.FontMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53, Parent = ThAnimToggleWrap,
    })
    Themed(ThAnimLabel, { TextColor3 = function(t) return t.Text end })
    local ThAnimToggle = Util.Create("TextButton", {
        BackgroundColor3 = Theme.ToggleOff, Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, 0, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5),
        Text = "", AutoButtonColor = false, ZIndex = 53, Parent = ThAnimToggleWrap,
    })
    Util.AddCorner(ThAnimToggle, UDim.new(1, 0))
    Themed(ThAnimToggle, { BackgroundColor3 = function(t) return working.Animated and t.Accent or t.ToggleOff end })
    local ThAnimKnob = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 2, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        ZIndex = 54, Parent = ThAnimToggle,
    })
    Util.AddCorner(ThAnimKnob, UDim.new(1, 0))

    local ThEffectWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 6, Visible = false, ZIndex = 52, Parent = ThemeScroll })
    local ThEffectLabel = Util.Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(0, 50, 1, 0), Position = UDim2.new(0, 2, 0, 0),
        Text = "Effect", TextColor3 = Theme.TextDim,
        FontFace = Theme.FontMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 53, Parent = ThEffectWrap,
    })
    Themed(ThEffectLabel, { TextColor3 = function(t) return t.TextDim end })
    local ThEffectBtn = Util.Create("TextButton", {
        BackgroundColor3 = Theme.SurfaceLight, BackgroundTransparency = 0.2,
        Size = UDim2.new(1, -56, 1, 0), Position = UDim2.new(0, 54, 0, 0),
        Text = "Stars", TextColor3 = Theme.Text,
        FontFace = Theme.FontMedium, TextSize = 12,
        AutoButtonColor = false, ZIndex = 53, Parent = ThEffectWrap,
    })
    Util.AddCorner(ThEffectBtn, Theme.CornerSmall)
    local _thEffStroke = Util.AddStroke(ThEffectBtn, Theme.Border, 1, 0.4)
    Themed(ThEffectBtn, { BackgroundColor3 = function(t) return t.SurfaceLight end, TextColor3 = function(t) return t.Text end })
    Themed(_thEffStroke, { Color = function(t) return t.Border end })
    local function _styleLabel(s) return s:sub(1,1):upper() .. s:sub(2) end
    local function SetEffectText() ThEffectBtn.Text = _styleLabel(working.Particle) .. "  ›" end
    SetEffectText()
    ThEffectBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for i = 1, #THEME_STYLES do if THEME_STYLES[i] == working.Particle then idx = i break end end
        working.Particle = THEME_STYLES[(idx % #THEME_STYLES) + 1]
        SetEffectText()
        if working.Animated then ApplyLive() end
    end)

    local ThAnimWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = 7, Visible = false, ZIndex = 52, Parent = ThemeScroll })
    Util.AddList(ThAnimWrap, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function SetAnimVisual(on)
        Util.TweenFast(ThAnimToggle, { BackgroundColor3 = on and Hyperion.Theme.Accent or Hyperion.Theme.ToggleOff })
        Util.TweenFast(ThAnimKnob, { Position = on and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0) })
        ThAnimWrap.Visible = on
        ThEffectWrap.Visible = on
    end
    ThAnimToggle.MouseButton1Click:Connect(function()
        working.Animated = not working.Animated
        SetAnimVisual(working.Animated)
        ApplyLive()
    end)
    SetAnimVisual(working.Animated)

    for _, f in ipairs(THEME_FIELDS) do
        local Sw = Util.Create("TextButton", {
            BackgroundColor3 = working[f.key],
            Size = UDim2.new(0, 26, 0, 26),
            Text = "",
            AutoButtonColor = false,
            ZIndex = 53,
            Parent = f.anim and ThAnimWrap or ThSwatchWrap,
        })
        Util.AddCorner(Sw, Theme.CornerSmall)
        local swStroke = Util.AddStroke(Sw, Theme.BorderLight, 1, 0.1)
        swatches[f.key] = { Btn = Sw, Stroke = swStroke }
        Themed(swStroke, { Color = function(t) return (selectedField == f.key) and t.Accent or t.BorderLight end })
        Sw.MouseEnter:Connect(function()
            if selectedField ~= f.key then Util.TweenFast(swStroke, { Transparency = 0, Color = Hyperion.Theme.TextMuted }) end
        end)
        Sw.MouseLeave:Connect(function()
            if selectedField ~= f.key then Util.TweenFast(swStroke, { Transparency = 0.1, Color = Hyperion.Theme.BorderLight }) end
        end)
        Sw.MouseButton1Click:Connect(function() SelectField(f.key) end)
    end

    -- Picker (SV + Hue)
    local ThPicker = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 110), LayoutOrder = 3, ZIndex = 52, Parent = ThemeScroll })
    SVBox = Util.Create("ImageLabel", {
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        Size = UDim2.new(1, -34, 0, 100),
        Position = UDim2.new(0, 0, 0, 4),
        Image = "rbxassetid://4155801252",
        ZIndex = 53, Parent = ThPicker,
    })
    Util.AddCorner(SVBox, Theme.CornerSmall)
    SVCursor = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.15,
        Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 1, 0), ZIndex = 54, Parent = SVBox,
    })
    Util.AddCorner(SVCursor, UDim.new(1, 0))
    Util.AddStroke(SVCursor, Color3.new(0,0,0), 1, 0.4)
    HueBar = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1,1,1),
        Size = UDim2.new(0, 18, 0, 100), Position = UDim2.new(1, -18, 0, 4),
        ZIndex = 53, Parent = ThPicker,
    })
    Util.AddCorner(HueBar, Theme.CornerSmall)
    Util.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0)),
        }),
        Rotation = 90, Parent = HueBar,
    })
    HueCur = Util.Create("Frame", {
        BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1, 4, 0, 4),
        Position = UDim2.new(0.5, 0, 0, 0), AnchorPoint = Vector2.new(0.5, 0.5),
        ZIndex = 54, Parent = HueBar,
    })
    Util.AddCorner(HueCur, UDim.new(1, 0))

    local ThHexWrap = Util.Create("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 4, ZIndex = 52, Parent = ThemeScroll })
    HexLabel = Util.Create("TextBox", {
        BackgroundColor3 = Theme.InputBg, Size = UDim2.new(1, 0, 1, 0),
        Text = "#000000", PlaceholderText = "#RRGGBB",
        TextColor3 = Theme.Text, PlaceholderColor3 = Theme.TextMuted,
        FontFace = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false, BorderSizePixel = 0,
        ZIndex = 53, Parent = ThHexWrap,
    })
    Util.AddCorner(HexLabel, Theme.CornerSmall)
    Util.AddPadding(HexLabel, 0, 8, 0, 8)
    local _thHexStroke = Util.AddStroke(HexLabel, Theme.Border, 1, 0.3)
    Themed(HexLabel, { BackgroundColor3 = function(t) return t.InputBg end, TextColor3 = function(t) return t.Text end, PlaceholderColor3 = function(t) return t.TextMuted end })
    Themed(_thHexStroke, { Color = function(t) return t.Border end })
    HexLabel.Focused:Connect(function() Util.TweenFast(_thHexStroke, { Color = Hyperion.Theme.Accent, Transparency = 0 }) end)

    local function CommitPickerColor()
        local c = Color3.fromHSV(hueState.h, hueState.s, hueState.v)
        working[selectedField] = c
        SVBox.BackgroundColor3 = Color3.fromHSV(hueState.h, 1, 1)
        SVCursor.Position = UDim2.new(hueState.s, 0, 1 - hueState.v, 0)
        HueCur.Position = UDim2.new(0.5, 0, hueState.h, 0)
        HexLabel.Text = ToHex(c)
        if swatches[selectedField] then swatches[selectedField].Btn.BackgroundColor3 = c end
        ApplyLive()
    end

    local function ApplyHexInput(str)
        str = tostring(str):gsub("%s", ""):gsub("^#", "")
        if #str == 3 then str = str:sub(1,1):rep(2) .. str:sub(2,2):rep(2) .. str:sub(3,3):rep(2) end
        if not str:match("^%x%x%x%x%x%x$") then return false end
        local r, g, b = tonumber(str:sub(1,2), 16), tonumber(str:sub(3,4), 16), tonumber(str:sub(5,6), 16)
        hueState.h, hueState.s, hueState.v = Color3.toHSV(Color3.fromRGB(r, g, b))
        CommitPickerColor()
        return true
    end
    HexLabel.FocusLost:Connect(function()
        Util.TweenFast(_thHexStroke, { Color = Hyperion.Theme.Border, Transparency = 0.3 })
        if not ApplyHexInput(HexLabel.Text) then HexLabel.Text = ToHex(working[selectedField]) end
    end)

    local thSvDrag, thHueDrag = false, false
    SVBox.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then thSvDrag = true end end)
    SVBox.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then thSvDrag = false end end)
    HueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then thHueDrag = true end end)
    HueBar.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then thHueDrag = false end end)
    table.insert(InputPool.ColorCallbacks, function(input)
        if thSvDrag then
            hueState.s = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / math.max(SVBox.AbsoluteSize.X, 1), 0, 1)
            hueState.v = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / math.max(SVBox.AbsoluteSize.Y, 1), 0, 1)
            CommitPickerColor()
        end
        if thHueDrag then
            hueState.h = math.clamp((input.Position.Y - HueBar.AbsolutePosition.Y) / math.max(HueBar.AbsoluteSize.Y, 1), 0, 1)
            CommitPickerColor()
        end
    end)

    -- Action buttons
    local function ThemeActionBtn(text, order, danger)
        local Btn = Util.Create("TextButton", {
            BackgroundColor3 = danger and Color3.fromRGB(55,18,22) or Theme.SurfaceLight,
            BackgroundTransparency = danger and 0 or 0.2,
            Size = UDim2.new(1, 0, 0, 30),
            Text = text,
            TextColor3 = danger and Theme.Error or Theme.Text,
            FontFace = Theme.FontMedium, TextSize = 12,
            AutoButtonColor = false, LayoutOrder = order, ZIndex = 52, Parent = ThemeScroll,
        })
        Util.AddCorner(Btn, Theme.CornerSmall)
        local st = Util.AddStroke(Btn, danger and Theme.Error or Theme.Border, 1, danger and 0.5 or 0.4)
        if not danger then
            Themed(Btn, { BackgroundColor3 = function(t) return t.SurfaceLight end, TextColor3 = function(t) return t.Text end })
            Themed(st, { Color = function(t) return t.Border end })
        else
            Themed(st, { Color = function(t) return t.Error end })
        end
        local nbg = danger and Color3.fromRGB(55,18,22) or Theme.SurfaceLight
        local hbg = danger and Color3.fromRGB(80,25,30) or Theme.SurfaceHover
        Btn.MouseEnter:Connect(function() Util.TweenFast(Btn, {BackgroundColor3 = hbg, BackgroundTransparency = 0}) end)
        Btn.MouseLeave:Connect(function() Util.TweenFast(Btn, {BackgroundColor3 = nbg, BackgroundTransparency = danger and 0 or 0.2}) end)
        return Btn
    end

    local ThSaveBtn  = ThemeActionBtn("Save Theme", 8, false)
    local ThResetBtn = ThemeActionBtn("Reset to Current", 9, false)

    -- Saved themes list
    local ThListLabel = Util.Create("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16),
        Text = "SAVED THEMES", TextColor3 = Theme.TextMuted,
        FontFace = Theme.FontSemiBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = 10, ZIndex = 52, Parent = ThemeScroll,
    })
    Themed(ThListLabel, { TextColor3 = function(t) return t.TextMuted end })

    local ThListOuter = Util.Create("Frame", {
        BackgroundColor3 = Theme.Background, Size = UDim2.new(1, 0, 0, 120),
        LayoutOrder = 11, ZIndex = 52, Parent = ThemeScroll,
    })
    Util.AddPadding(ThListOuter, 6, 6, 6, 6)
    Util.AddCorner(ThListOuter, Theme.CornerSmall)
    local _thListStroke = Util.AddStroke(ThListOuter, Theme.Border, 1, 0.3)
    Themed(ThListOuter, { BackgroundColor3 = function(t) return t.Background end })
    Themed(_thListStroke, { Color = function(t) return t.Border end })
    local ThList = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.new(0, 4, 0, 4),
        BorderSizePixel = 0, ScrollBarThickness = 0,
        ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0,0,0,0), ZIndex = 53, Parent = ThListOuter,
    })
    Util.AddList(ThList, Enum.FillDirection.Vertical, 3)

    local function RefreshThemeList()
        for _, c in ipairs(ThList:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
        local names = ThemeStore.List()
        if #names == 0 then
            local Empty = Util.Create("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20),
                Text = "No saved themes", TextColor3 = Theme.TextMuted,
                FontFace = Theme.Font, TextSize = 11, ZIndex = 54, Parent = ThList,
            })
            return
        end
        for _, n in ipairs(names) do
            local Row = Util.Create("Frame", {
                BackgroundColor3 = Theme.SurfaceLight, BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 26), ZIndex = 54, Parent = ThList,
            })
            Util.AddCorner(Row, Theme.CornerSmall)
            local Load = Util.Create("TextButton", {
                BackgroundTransparency = 1, Size = UDim2.new(1, -28, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                Text = n, TextColor3 = Theme.Text, FontFace = Theme.Font, TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 55, Parent = Row,
            })
            Themed(Load, { TextColor3 = function(t) return t.Text end })
            Load.MouseButton1Click:Connect(function()
                local w = ThemeStore.Load(n)
                if not w then return end
                for _, f in ipairs(THEME_FIELDS) do if w[f.key] then working[f.key] = w[f.key] end end
                working.Animated = w.Animated == true
                working.Particle = w.Particle or "stars"
                SetEffectText()
                SetAnimVisual(working.Animated)
                for k, sw in pairs(swatches) do sw.Btn.BackgroundColor3 = working[k] end
                ApplyLive()
                LoadFieldIntoPicker()
                ThNameBox.Text = n
                ThStatus.Text = "Loaded: " .. n
            end)
            local Del = Util.Create("TextButton", {
                BackgroundTransparency = 1, Size = UDim2.new(0, 22, 1, 0), Position = UDim2.new(1, -22, 0, 0),
                Text = "✕", TextColor3 = Theme.TextMuted, FontFace = Theme.FontBold, TextSize = 12,
                AutoButtonColor = false, ZIndex = 55, Parent = Row,
            })
            Del.MouseEnter:Connect(function() Del.TextColor3 = Hyperion.Theme.Error end)
            Del.MouseLeave:Connect(function() Del.TextColor3 = Hyperion.Theme.TextMuted end)
            Del.MouseButton1Click:Connect(function()
                ThemeStore.Delete(n)
                Hyperion.Themes[n] = nil
                RefreshThemeList()
                ThStatus.Text = "Deleted: " .. n
            end)
        end
    end

    ThSaveBtn.MouseButton1Click:Connect(function()
        local nm = ThNameBox.Text
        nm = (nm or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if nm == "" then ThStatus.Text = "Enter a name first"; return end
        local ok = ThemeStore.Save(nm, working)
        if ok then
            Hyperion.Themes[nm] = BuildTheme(working)
            RefreshThemeList()
            ThStatus.Text = "Saved: " .. nm
            Hyperion:Notify({ Title = "Theme", Content = "Saved: " .. nm, Type = "Success", Duration = 3 })
            ThSaveBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
            ThSaveBtn.BackgroundTransparency = 0
            Util.Tween(ThSaveBtn, 0.45, { BackgroundColor3 = Hyperion.Theme.SurfaceLight, BackgroundTransparency = 0.2 }, Enum.EasingStyle.Quad)
        else
            ThStatus.Text = "Save failed"
        end
    end)
    ThResetBtn.MouseButton1Click:Connect(function()
        for _, f in ipairs(THEME_FIELDS) do working[f.key] = Hyperion.Theme[f.key] or f.default end
        working.Animated = Hyperion.Theme.Animated == true
        working.Particle = Hyperion.Theme.ParticleStyle or "stars"
        SetEffectText()
        SetAnimVisual(working.Animated)
        for k, sw in pairs(swatches) do sw.Btn.BackgroundColor3 = working[k] end
        LoadFieldIntoPicker()
        ThStatus.Text = "Reset to current theme"
    end)

    local function AnimateThemeOpen()
        local i = 0
        for _, f in ipairs(THEME_FIELDS) do
            local sw = swatches[f.key]
            if sw then
                i = i + 1
                sw.Btn.BackgroundTransparency = 1
                task.delay(i * 0.035, function()
                    if sw.Btn and sw.Btn.Parent then Util.Tween(sw.Btn, 0.25, { BackgroundTransparency = 0 }, Enum.EasingStyle.Back) end
                end)
            end
        end
    end

    -- Open / close
    local TH_OPEN   = UDim2.new(0, 0, 0, HeaderHeight)
    local TH_CLOSED = UDim2.new(0, -THEME_W - 14, 0, HeaderHeight)
    local function OpenThemePanel()
        if themePanelOpen then return end
        themePanelOpen = true
        if cfgPanelOpen then CloseConfigPanel() end
        if _px._closeChat then _px._closeChat() end
        if _px._closePlayers then _px._closePlayers() end
        SelectField(selectedField)
        RefreshThemeList()
        AnimateThemeOpen()
        ThemeOverlay.Position = TH_CLOSED
        ThemeOverlay.BackgroundTransparency = 1
        ThemeOverlay.Visible = true
        Util.Tween(ThemeOverlay, 0.30, { Position = TH_OPEN, BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        Util.TweenFast(ThemeBtn, { BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Accent })
    end
    local function CloseThemePanel()
        if not themePanelOpen then return end
        themePanelOpen = false
        Util.Tween(ThemeOverlay, 0.22, { Position = TH_CLOSED, BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        Util.TweenFast(ThemeBtn, { BackgroundTransparency = 0.5, ImageColor3 = Hyperion.Theme.TextMuted })
        task.delay(0.25, function()
            if not themePanelOpen and ThemeOverlay and ThemeOverlay.Parent then ThemeOverlay.Visible = false end
        end)
    end
    _px._closeTheme = CloseThemePanel

    ThemeBtn.MouseButton1Click:Connect(function()
        if themePanelOpen then CloseThemePanel() else OpenThemePanel() end
    end)
    ThCloseBtn.MouseButton1Click:Connect(CloseThemePanel)

    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not themePanelOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if thSvDrag or thHueDrag then return end
        local pos = input.Position
        local oPos, oSize = ThemeOverlay.AbsolutePosition, ThemeOverlay.AbsoluteSize
        local insidePanel = pos.X >= oPos.X and pos.X <= oPos.X + oSize.X and pos.Y >= oPos.Y and pos.Y <= oPos.Y + oSize.Y
        local bPos, bSize = ThemeBtn.AbsolutePosition, ThemeBtn.AbsoluteSize
        local insideBtn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
        if not insidePanel and not insideBtn then CloseThemePanel() end
    end)

    Themed(ThemeBtn, { ImageColor3 = function(t) return themePanelOpen and t.Accent or t.TextMuted end })

    _px._openTheme   = OpenThemePanel
    _px._toggleTheme = function() if themePanelOpen then CloseThemePanel() else OpenThemePanel() end end
    end)() -- THEME CREATOR scope

    -- ================================================================
    -- PLAYERS PANEL  (slides in from the left, like Config/Theme)
    -- ================================================================
    ;(function()
    local PLAYERS_W = 300
    local playersPanelOpen = false
    local refreshHandler = nil

    local PlayersOverlay = Util.Create("Frame", {
        Name = "PlayersOverlay",
        BackgroundColor3 = Theme.Sidebar,
        Size = UDim2.new(0, PLAYERS_W, 1, -HeaderHeight),
        Position = UDim2.new(0, -PLAYERS_W - 14, 0, HeaderHeight),
        ClipsDescendants = true, BorderSizePixel = 0, Visible = false, ZIndex = 50, Parent = MainFrame,
    })
    Util.AddCorner(PlayersOverlay, Theme.CornerRadius)
    local _plStroke = Util.AddStroke(PlayersOverlay, Theme.BorderLight, 1, 0.12)
    Themed(PlayersOverlay, { BackgroundColor3 = function(t) return t.Sidebar end })
    Themed(_plStroke, { Color = function(t) return t.BorderLight end })

    local PlHeader = Util.Create("Frame", {
        BackgroundColor3 = Theme.SidebarActive, Size = UDim2.new(1, 0, 0, 42),
        BorderSizePixel = 0, ZIndex = 52, Parent = PlayersOverlay,
    })
    Themed(PlHeader, { BackgroundColor3 = function(t) return t.SidebarActive end })
    do
        local al = Util.Create("Frame", { BackgroundColor3 = Color3.new(1,1,1), Size = UDim2.new(1,0,0,1), BorderSizePixel = 0, ZIndex = 53, Parent = PlHeader })
        local g = Util.Create("UIGradient", {
            Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.AccentDark), ColorSequenceKeypoint.new(0.5, Theme.Accent), ColorSequenceKeypoint.new(1, Theme.AccentDark) }),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0,0.5), NumberSequenceKeypoint.new(0.5,0), NumberSequenceKeypoint.new(1,0.5) }),
            Parent = al,
        })
        Themed(g, { Color = function(t) return ColorSequence.new({ ColorSequenceKeypoint.new(0,t.AccentDark), ColorSequenceKeypoint.new(0.5,t.Accent), ColorSequenceKeypoint.new(1,t.AccentDark) }) end })
    end
    local PlTitle = Util.Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 7), Size = UDim2.new(1, -84, 0, 16),
        Text = "Players", TextColor3 = Theme.Text, FontFace = Theme.FontBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53, Parent = PlHeader,
    })
    Themed(PlTitle, { TextColor3 = function(t) return t.Text end })
    local PlCount = Util.Create("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 14, 0, 25), Size = UDim2.new(1, -84, 0, 12),
        Text = "0 players", TextColor3 = Theme.TextMuted, FontFace = Theme.Font, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 53, Parent = PlHeader,
    })
    Themed(PlCount, { TextColor3 = function(t) return t.TextMuted end })

    local PlRefreshBtn = Util.Create("ImageButton", {
        BackgroundColor3 = Theme.SurfaceActive, BackgroundTransparency = 0.4, Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -60, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Image = Hyperion.Lucide.RefreshCw,
        ImageColor3 = Theme.TextDim, ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, ZIndex = 54, Parent = PlHeader,
    })
    Util.AddCorner(PlRefreshBtn, Theme.CornerSmall)
    Themed(PlRefreshBtn, { BackgroundColor3 = function(t) return t.SurfaceActive end, ImageColor3 = function(t) return t.TextDim end })
    PlRefreshBtn.MouseEnter:Connect(function() Util.TweenFast(PlRefreshBtn, {BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Accent}) end)
    PlRefreshBtn.MouseLeave:Connect(function() Util.TweenFast(PlRefreshBtn, {BackgroundTransparency = 0.4, ImageColor3 = Hyperion.Theme.TextDim}) end)

    local PlCloseBtn = Util.Create("ImageButton", {
        BackgroundColor3 = Theme.SurfaceActive, BackgroundTransparency = 0.4, Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Image = "rbxassetid://10747384394",
        ImageColor3 = Theme.TextDim, ScaleType = Enum.ScaleType.Fit, AutoButtonColor = false, ZIndex = 54, Parent = PlHeader,
    })
    Util.AddCorner(PlCloseBtn, Theme.CornerSmall)
    Themed(PlCloseBtn, { BackgroundColor3 = function(t) return t.SurfaceActive end, ImageColor3 = function(t) return t.TextDim end })
    PlCloseBtn.MouseEnter:Connect(function() Util.TweenFast(PlCloseBtn, {BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Error}) end)
    PlCloseBtn.MouseLeave:Connect(function() Util.TweenFast(PlCloseBtn, {BackgroundTransparency = 0.4, ImageColor3 = Hyperion.Theme.TextDim}) end)

    local PlScroll = Util.Create("ScrollingFrame", {
        BackgroundTransparency = 1, Position = UDim2.new(0, 0, 0, 42), Size = UDim2.new(1, 0, 1, -42),
        BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.4,
        ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(0,0,0,0),
        ZIndex = 51, Parent = PlayersOverlay,
    })
    Util.AddList(PlScroll, Enum.FillDirection.Vertical, 5)
    Util.AddPadding(PlScroll, 8, 8, 8, 8)
    Themed(PlScroll, { ScrollBarImageColor3 = function(t) return t.Accent end })

    local function doRefresh() if refreshHandler then task.spawn(refreshHandler, PlScroll, PlCount) end end

    local PL_OPEN   = UDim2.new(0, 0, 0, HeaderHeight)
    local PL_CLOSED = UDim2.new(0, -PLAYERS_W - 14, 0, HeaderHeight)
    local function OpenPlayersPanel()
        if playersPanelOpen then return end
        playersPanelOpen = true
        if cfgPanelOpen then CloseConfigPanel() end
        if _px._closeChat then _px._closeChat() end
        if _px._closeTheme then _px._closeTheme() end
        doRefresh()
        PlayersOverlay.Position = PL_CLOSED
        PlayersOverlay.BackgroundTransparency = 1
        PlayersOverlay.Visible = true
        Util.Tween(PlayersOverlay, 0.30, { Position = PL_OPEN, BackgroundTransparency = 0 }, Enum.EasingStyle.Quint)
        Util.TweenFast(PlayersBtn, { BackgroundTransparency = 0, ImageColor3 = Hyperion.Theme.Accent })
    end
    local function ClosePlayersPanel()
        if not playersPanelOpen then return end
        playersPanelOpen = false
        Util.Tween(PlayersOverlay, 0.22, { Position = PL_CLOSED, BackgroundTransparency = 1 }, Enum.EasingStyle.Quint)
        Util.TweenFast(PlayersBtn, { BackgroundTransparency = 0.5, ImageColor3 = Hyperion.Theme.TextMuted })
        task.delay(0.25, function()
            if not playersPanelOpen and PlayersOverlay and PlayersOverlay.Parent then PlayersOverlay.Visible = false end
        end)
    end
    _px._closePlayers = ClosePlayersPanel

    PlayersBtn.MouseButton1Click:Connect(function()
        if playersPanelOpen then ClosePlayersPanel() else OpenPlayersPanel() end
    end)
    PlCloseBtn.MouseButton1Click:Connect(ClosePlayersPanel)
    PlRefreshBtn.MouseButton1Click:Connect(doRefresh)

    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if not playersPanelOpen then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos = input.Position
        local oPos, oSize = PlayersOverlay.AbsolutePosition, PlayersOverlay.AbsoluteSize
        local insidePanel = pos.X >= oPos.X and pos.X <= oPos.X + oSize.X and pos.Y >= oPos.Y and pos.Y <= oPos.Y + oSize.Y
        local bPos, bSize = PlayersBtn.AbsolutePosition, PlayersBtn.AbsoluteSize
        local insideBtn = pos.X >= bPos.X and pos.X <= bPos.X + bSize.X and pos.Y >= bPos.Y and pos.Y <= bPos.Y + bSize.Y
        if not insidePanel and not insideBtn then ClosePlayersPanel() end
    end)
    Themed(PlayersBtn, { ImageColor3 = function(t) return playersPanelOpen and t.Accent or t.TextMuted end })

    _px._openPlayers      = OpenPlayersPanel
    _px._togglePlayers    = function() if playersPanelOpen then ClosePlayersPanel() else OpenPlayersPanel() end end
    _px._onPlayersRefresh = function(fn) refreshHandler = fn end
    _px._playersScroll    = PlScroll
    end)() -- PLAYERS PANEL scope

    -- ============================================================
    -- CONTENT AREA
    -- ============================================================
    local ContentArea = Util.Create("Frame", {
        Name = "Content",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -(SidebarWidth + 24), 1, -(HeaderHeight + 6)),
        Position = UDim2.new(0, SidebarWidth + 14, 0, HeaderHeight + 6),
        ClipsDescendants = false,
        ZIndex = 2,
        Parent = MainFrame
    })

    -- ============================================================
    -- RESIZE HELPERS
    -- ============================================================
    ;(function()
    local function ClampWindowSize(size)
        local viewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)

        local minW = WindowObj.MinSize.X.Offset
        local minH = WindowObj.MinSize.Y.Offset

        local maxW = math.max(minW, viewportSize.X - 80)
        local maxH = math.max(minH, viewportSize.Y - 80)

        local width = math.clamp(size.X.Offset, minW, maxW)
        local height = math.clamp(size.Y.Offset, minH, maxH)

        return UDim2.new(0, width, 0, height)
    end

    WindowObj.CurrentSize = ClampWindowSize(WindowObj.CurrentSize)
    MainFrame.Size = WindowObj.CurrentSize

    local function ApplyWindowSize(size)
        local clamped = ClampWindowSize(size)
        WindowObj.CurrentSize = clamped
        MainFrame.Size = clamped
    end

    local ResizeHandle = Util.Create("TextButton", {
        Name = "ResizeHandle",
        BackgroundTransparency = 1,
        Text = "",
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -18, 1, -18),
        ZIndex = 25,
        Parent = MainFrame
    })

    local ResizeGrip1 = Util.Create("Frame", {
        Name = "Grip1",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.new(0, 8, 0, 2),
        BackgroundColor3 = Theme.TextMuted,
        BorderSizePixel = 0,
        Rotation = -45,
        ZIndex = 26,
        Parent = ResizeHandle
    })
    local ResizeGrip2 = Util.Create("Frame", {
        Name = "Grip2",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -6, 1, -6),
        Size = UDim2.new(0, 8, 0, 2),
        BackgroundColor3 = Theme.TextMuted,
        BorderSizePixel = 0,
        Rotation = -45,
        ZIndex = 26,
        Parent = ResizeHandle
    })
    Util.AddCorner(ResizeGrip1, UDim.new(0, 1))
    Util.AddCorner(ResizeGrip2, UDim.new(0, 1))
    Themed(ResizeGrip1, { BackgroundColor3 = function(t) return t.TextMuted end })
    Themed(ResizeGrip2, { BackgroundColor3 = function(t) return t.TextMuted end })

    local Resizing = false
    local ResizeStart = Vector3.new()
    local StartSize = WindowObj.CurrentSize

    ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Resizing = true
            ResizeStart = input.Position
            StartSize = WindowObj.CurrentSize
        end
    end)
    ResizeHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Resizing = false
        end
    end)

    Util.Connect(UserInputService.InputChanged, function(input)
        if Resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - ResizeStart
            ApplyWindowSize(UDim2.new(
                0, StartSize.X.Offset + delta.X,
                0, StartSize.Y.Offset + delta.Y
            ))
        end
    end)

    function WindowObj:SetSize(size)
        ApplyWindowSize(size)
    end
    end)()

    -- Set a custom background image. Pass nil or "" to clear.
    -- tintAlpha: 0=no tint, 1=fully opaque tint (default 0.45)
    function WindowObj:SetBackground(imageId, tintAlpha)
        if not imageId or imageId == "" then
            BgImage.Visible = false
            BgTint.Visible  = false
            return
        end
        if type(imageId) == "number" then
            imageId = "rbxthumb://type=Asset&id=" .. imageId .. "&w=420&h=420"
        elseif type(imageId) == "string" then
            -- Convert plain rbxassetid to a thumbnail URL so it works for any asset type
            local id = imageId:match("rbxassetid://(%d+)")
            if id then
                imageId = "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
            end
        end
        BgImage.Image             = imageId
        BgImage.ImageTransparency = 0
        BgImage.ImageColor3       = Color3.new(1, 1, 1)
        BgImage.Visible           = true
        BgTint.BackgroundTransparency = 1 - (tintAlpha or 0.45)
        BgTint.Visible  = (tintAlpha or 0.45) > 0
    end

    -- Set overall UI transparency (0 = fully opaque, 1 = invisible).
    -- Values around 0.08-0.15 give a nice frosted glass effect.
    function WindowObj:SetTransparency(alpha)
        alpha = math.clamp(alpha or 0, 0, 0.95)
        Util.Tween(MainFrame, 0.22, {BackgroundTransparency = alpha}, Enum.EasingStyle.Quint)
        Util.Tween(Header,    0.22, {BackgroundTransparency = alpha}, Enum.EasingStyle.Quint)
        Util.Tween(Sidebar,   0.22, {BackgroundTransparency = alpha}, Enum.EasingStyle.Quint)
        -- Register new base transparency in Theme so listeners know
        Hyperion.Theme._uiAlpha = alpha
    end

    -- ============================================================
    -- DRAGGING (with viewport bounds clamping)
    -- ============================================================
    ;(function()
    local Dragging, DragStart, StartPos = false, Vector3.new(), UDim2.new()
    local _dragTarget = nil

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPos = MainFrame.Position
        end
    end)
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
        end
    end)

    Util.Connect(UserInputService.InputChanged, function(input)
        if Dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - DragStart
            local viewportSize = workspace.CurrentCamera.ViewportSize
            local winSize = MainFrame.AbsoluteSize

            local newX = StartPos.X.Offset + delta.X
            local newY = StartPos.Y.Offset + delta.Y

            -- Clamp so window stays at least partially on screen
            local halfW = winSize.X * 0.5
            local halfH = winSize.Y * 0.5
            newX = math.clamp(newX, -halfW + 60, viewportSize.X - halfW - 60)
            newY = math.clamp(newY, -halfH + 30, viewportSize.Y - halfH - 30)

            -- Store the target; a RenderStepped loop eases the frame toward it
            -- so the window trails the cursor smoothly instead of snapping.
            _dragTarget = UDim2.new(StartPos.X.Scale, newX, StartPos.Y.Scale, newY)
        end
    end)

    -- Frame-rate independent smoothing toward the drag target.
    Util.Connect(RunService.RenderStepped, function(dt)
        if not _dragTarget then return end
        local cur = MainFrame.Position
        if not Dragging then
            -- settle the last few pixels, then release
            local dx = _dragTarget.X.Offset - cur.X.Offset
            local dy = _dragTarget.Y.Offset - cur.Y.Offset
            if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
                MainFrame.Position = _dragTarget
                _dragTarget = nil
                return
            end
        end
        local a = 1 - math.exp(-16 * dt) -- ~16/sec convergence, dt-independent
        MainFrame.Position = UDim2.new(
            _dragTarget.X.Scale, cur.X.Offset + (_dragTarget.X.Offset - cur.X.Offset) * a,
            _dragTarget.Y.Scale, cur.Y.Offset + (_dragTarget.Y.Offset - cur.Y.Offset) * a
        )
    end)
    end)()

    -- ============================================================
    -- KEYBIND TOGGLE
    -- ============================================================
    Util.Connect(UserInputService.InputBegan, function(input, processed)
        if processed then return end
        if input.KeyCode == windowConfig.Keybind then
            WindowObj:Toggle()
        end
    end)

    -- ============================================================
    -- OPEN ANIMATION
    -- ============================================================
    MainFrame.BackgroundTransparency = 1
    MainFrame.Size = UDim2.new(
        0, WindowObj.CurrentSize.X.Offset * 0.92,
        0, WindowObj.CurrentSize.Y.Offset * 0.92
    )
    task.defer(function()
        Util.Tween(MainFrame, 0.5, {
            BackgroundTransparency = 0,
            Size = WindowObj.CurrentSize
        }, Enum.EasingStyle.Quint)
    end)

    -- ============================================================
    -- WINDOW API
    -- ============================================================
    function WindowObj:SetLogo(assetId)
        if assetId == nil or assetId == "" then
            LogoImage.Image = ""
            LogoImage.Visible = false
            TitleLabel.Position = UDim2.new(0, 0, 0, 0)
            TitleLabel.Size = UDim2.new(1, 0, 1, 0)
            SubtitleLabel.Position = UDim2.new(0, 0, 0, 0)
            SubtitleLabel.Size = UDim2.new(0, 1, 0, 1)
            return
        end

        if typeof(assetId) == "number" then
            assetId = "rbxassetid://" .. tostring(assetId)
        elseif type(assetId) == "string" and not string.find(assetId, "rbxassetid://", 1, true) then
            if string.match(assetId, "^%d+$") then
                assetId = "rbxassetid://" .. assetId
            end
        end

        LogoImage.Image = assetId
        LogoImage.Visible = true
        TitleLabel.Position = UDim2.new(0, 72, 0, 0)
        TitleLabel.Size = UDim2.new(1, -72, 1, 0)
        SubtitleLabel.Position = UDim2.new(0, 46, 0, 0)
        SubtitleLabel.Size = UDim2.new(0, 1, 0, 1)
    end

    function WindowObj:SetTitle(text)
        TitleLabel.Text = text
    end

    function WindowObj:SetSubtitle(text)
        SubtitleLabel.Text = text
    end

    function WindowObj:Toggle()
        WindowObj.Visible = not WindowObj.Visible
        if WindowObj.Visible then
            ScreenGui.Enabled = true
            MainFrame.Visible = true
            -- If was fullscreen, restore before showing
            if WindowObj._isFullscreen then
                WindowObj._isFullscreen = false
                WindowObj.CurrentSize = WindowObj._preFullscreenSize or windowConfig.Size
            end
            if WindowObj._collapsed then
                WindowObj._collapsed = false
                MainFrame.ClipsDescendants = false
            end
            MainFrame.Size = UDim2.new(
                0, math.floor(WindowObj.CurrentSize.X.Offset * 0.97),
                0, math.floor(WindowObj.CurrentSize.Y.Offset * 0.97)
            )
            MainFrame.BackgroundTransparency = 0.25
            MainFrame.Position = UDim2.new(0.5, 0, 0.5, 8)
            Util.Tween(MainFrame, 0.28, {
                BackgroundTransparency = 0,
                Size = WindowObj.CurrentSize,
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, Enum.EasingStyle.Quint)
            if MobileToggleButton then
                Util.TweenFast(MobileToggleButton, {BackgroundColor3 = Hyperion.Theme.Surface})
            end
        else
            Util.Tween(MainFrame, 0.22, {
                BackgroundTransparency = 0.4,
                Size = UDim2.new(
                    0, math.floor(WindowObj.CurrentSize.X.Offset * 0.985),
                    0, math.floor(WindowObj.CurrentSize.Y.Offset * 0.985)
                ),
                Position = UDim2.new(0.5, 0, 0.5, 6)
            }, Enum.EasingStyle.Quint)
            if MobileToggleButton then
                Util.TweenFast(MobileToggleButton, {BackgroundColor3 = Hyperion.Theme.SidebarActive})
            end
            task.delay(0.22, function()
                if not WindowObj.Visible then
                    MainFrame.Visible = false
                end
            end)
        end
    end

    if MobileToggleButton then
        MobileToggleButton.MouseButton1Click:Connect(function()
            WindowObj:Toggle()
        end)
    end

    function WindowObj:Destroy()
        Hyperion.Unloaded = true
        _stopStarfield()
        _stopGradientRotation()
        for _, conn in pairs(Hyperion.Connections) do
            pcall(function() conn:Disconnect() end)
        end
        Hyperion.Connections = {}
        InputPool.SliderCallbacks = {}
        InputPool.ColorCallbacks = {}
        ScreenGui:Destroy()
    end

    function WindowObj:SaveConfig(name)
        local ok = Config.Save(name or "default", Hyperion.Flags)
        RefreshConfigList()
        return ok
    end

    function WindowObj:LoadConfig(name)
        return Config.Load(name or "default", Hyperion.Flags, Hyperion.FlagCallbacks)
    end

    -- AutoLoad: silently restore a config if it exists on disk.
    -- Mirrors Hyperion:AutoLoad so scripts can call it on the window instance.
    function WindowObj:AutoLoad(name)
        name = name or "default"
        if Hyperion._configEnabled == false then return false end
        if _rawIsfile("Hyperion/Configs/" .. name .. ".json") then
            return Config.Load(name, Hyperion.Flags, Hyperion.FlagCallbacks)
        end
        return false
    end

    -- AutoSave: save the current flag values under `name` (default "default").
    function WindowObj:AutoSave(name)
        if Hyperion._configEnabled == false then return false end
        local ok = Config.Save(name or "default", Hyperion.Flags)
        RefreshConfigList()
        return ok
    end

    function WindowObj:ListConfigs()
        return Config.List()
    end

    function WindowObj:DeleteConfig(name)
        local ok = Config.Delete(name or "default")
        RefreshConfigList()
        return ok
    end

    function WindowObj:OpenConfigPanel()
        OpenConfigPanel()
    end

    function WindowObj:CloseConfigPanel()
        CloseConfigPanel()
    end

    function WindowObj:RefreshConfigList()
        RefreshConfigList()
    end

    function WindowObj:OpenChatPanel()  if _px._openChat then _px._openChat() end end
    function WindowObj:CloseChatPanel() if _px._closeChat then _px._closeChat() end end
    function WindowObj:ToggleChatPanel() if _px._toggleChat then _px._toggleChat() end end
    function WindowObj:AddChatMessage(role, text) if _px._addChatMsg then _px._addChatMsg(role, text) end end
    function WindowObj:SetChatStatus(text) if _px._setChatStatus then _px._setChatStatus(text) end end
    function WindowObj:ClearChat()         if _px._clearChat then _px._clearChat() end end
    function WindowObj:OnChatSend(fn)      if _px._setChatSend then _px._setChatSend(fn) end end
    function WindowObj:SetChatPersonas(list) if _px._setChatPersonas then _px._setChatPersonas(list) end end
    function WindowObj:OnPersonaChange(fn) if _px._onPersonaChange then _px._onPersonaChange(fn) end end
    function WindowObj:OnNewChat(fn)       if _px._onNewChat then _px._onNewChat(fn) end end
    function WindowObj:GetPersona()        if _px._getPersona then return _px._getPersona() end end

    function WindowObj:OpenThemePanel()  if _px._openTheme then _px._openTheme() end end
    function WindowObj:CloseThemePanel() if _px._closeTheme then _px._closeTheme() end end
    function WindowObj:ToggleThemePanel() if _px._toggleTheme then _px._toggleTheme() end end
    function WindowObj:OpenPlayersPanel()  if _px._openPlayers then _px._openPlayers() end end
    function WindowObj:ClosePlayersPanel() if _px._closePlayers then _px._closePlayers() end end
    function WindowObj:TogglePlayersPanel() if _px._togglePlayers then _px._togglePlayers() end end
    function WindowObj:OnPlayersRefresh(fn) if _px._onPlayersRefresh then _px._onPlayersRefresh(fn) end end
    function WindowObj:GetPlayersContainer() return _px._playersScroll end
    function WindowObj:ShowKeybindList()   if _px._showKb then _px._showKb() end end
    function WindowObj:HideKeybindList()   if _px._hideKb then _px._hideKb() end end
    function WindowObj:ToggleKeybindList() if _px._toggleKb then _px._toggleKb() end end

    -- ============================================================
    -- THEME PICKER  (call from any section: Section:AddThemePicker())
    -- Adds a grid of theme swatches. Clicking one applies the theme live.
    -- Because Theme is a shared reference, UI elements already using
    -- Theme.X will not auto-update — but newly opened dropdowns/sections
    -- will. For a full live-reload call Window:Destroy() and rebuild.
    -- ============================================================
    function WindowObj:AddThemePicker(section, callback)
        -- section must be a SectionObj returned by Tab:AddSection()
        local cb = callback or function() end
        local themeOrder = {"Purple", "Midnight", "Rose", "Crimson", "Sunset", "Sakura", "StarryNight", "Aurora", "Nebula", "Ocean"}
        local themeColors = {
            Purple      = Color3.fromRGB(140, 80, 220),
            Midnight    = Color3.fromRGB(80, 120, 255),
            Rose        = Color3.fromRGB(220, 80, 120),
            Crimson     = Color3.fromRGB(200, 40, 50),
            Sunset      = Color3.fromRGB(245, 150, 50),
            Sakura      = Color3.fromRGB(235, 120, 160),
            StarryNight = Color3.fromRGB(80, 200, 240),
            Aurora      = Color3.fromRGB(60, 220, 160),
            Nebula      = Color3.fromRGB(255, 100, 180),
            Ocean       = Color3.fromRGB(40, 160, 220),
        }

        -- Find the Elements frame inside the section's frame
        local sectionFrame = nil
        for _, child in ipairs(MainFrame:GetDescendants()) do
            if child:IsA("Frame") and child.Name:find("^Sec_") then
                local elemFrame = child:FindFirstChild("Elements")
                if elemFrame then
                    sectionFrame = elemFrame
                end
            end
        end

        -- Better: expose Elements via section object if possible,
        -- otherwise build directly as a standalone widget returned to caller
        local container = Util.Create("Frame", {
            Name = "ThemePicker",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
        })
        Util.AddList(container, Enum.FillDirection.Vertical, 6)
        Util.AddPadding(container, 4, 0, 4, 0)

        local currentTheme = "Purple"
        local swatches = {}

        for _, name in ipairs(themeOrder) do
            local accent = themeColors[name]
            local row = Util.Create("TextButton", {
                BackgroundColor3 = Theme.SurfaceLight,
                BackgroundTransparency = 0.4,
                Size = UDim2.new(1, 0, 0, 38),
                Text = "",
                AutoButtonColor = false,
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = container,
            })
            Util.AddCorner(row, Theme.CornerSmall)
            local stroke = Util.AddStroke(row, Theme.Border, 1, 0.5)

            -- Color swatch circle
            local swatch = Util.Create("Frame", {
                BackgroundColor3 = accent,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 8, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = row,
            })
            Util.AddCorner(swatch, UDim.new(1, 0))

            -- Inner glow ring
            Util.AddStroke(swatch, accent, 1, 0.5)

            -- Theme name label
            local lbl = Util.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -50, 1, 0),
                Position = UDim2.new(0, 34, 0, 0),
                Text = name,
                TextColor3 = Theme.Text,
                FontFace = Theme.FontMedium,
                TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3,
                Parent = row,
            })

            -- Active checkmark
            local check = Util.Create("TextLabel", {
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 20, 1, 0),
                Position = UDim2.new(1, -26, 0, 0),
                Text = "✓",
                TextColor3 = accent,
                FontFace = Theme.FontBold,
                TextSize = 14,
                TextTransparency = name == currentTheme and 0 or 1,
                ZIndex = 3,
                Parent = row,
            })

            Themed(row, {
                BackgroundColor3 = function(t)
                    return (currentTheme == name) and t.SurfaceActive or t.SurfaceLight
                end
            })
            Themed(stroke, {
                Color = function(t)
                    return (currentTheme == name) and accent or t.Border
                end
            })
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") and child ~= check then
                    Themed(child, { TextColor3 = function(t) return t.Text end })
                end
            end
            Themed(check, { TextColor3 = function(_) return accent end })

            
            swatches[name] = {row = row, check = check, stroke = stroke, accent = accent}

            row.MouseEnter:Connect(function()
                if currentTheme ~= name then
                    Util.TweenFast(row, {BackgroundTransparency = 0.2, BackgroundColor3 = Hyperion.Theme.SurfaceHover})
                end
            end)
            row.MouseLeave:Connect(function()
                if currentTheme ~= name then
                    Util.TweenFast(row, {BackgroundTransparency = 0.4, BackgroundColor3 = Hyperion.Theme.SurfaceLight})
                end
            end)

            row.MouseButton1Click:Connect(function()
                if currentTheme == name then return end
                -- Deselect old
                local old = swatches[currentTheme]
                if old then
                    Util.TweenFast(old.row, {BackgroundTransparency = 0.4, BackgroundColor3 = Theme.SurfaceLight})
                    Util.TweenFast(old.stroke, {Color = Theme.Border, Transparency = 0.5})
                    Util.TweenFast(old.check, {TextTransparency = 1})
                end
                -- Select new
                currentTheme = name
                Hyperion:SetTheme(name)
                Util.TweenFast(row, {BackgroundTransparency = 0.1, BackgroundColor3 = Theme.SurfaceActive})
                Util.TweenFast(stroke, {Color = accent, Transparency = 0.3})
                Util.TweenFast(check, {TextTransparency = 0})
                -- Refresh config list rows so they pick up new theme colors
                RefreshConfigList()
                Hyperion:Notify({
                    Title   = "Theme",
                    Content = name .. " theme applied.",
                    Type    = "Info",
                    Duration = 2,
                })
                cb(name)
            end)
        end

        -- Mark initial selection
        local initSwatch = swatches["Purple"]
        if initSwatch then
            Util.TweenFast(initSwatch.row, {BackgroundTransparency = 0.1, BackgroundColor3 = Theme.SurfaceActive})
            Util.TweenFast(initSwatch.stroke, {Color = themeColors["Purple"], Transparency = 0.3})
        end

        -- Return the container so the caller can parent it wherever needed
        return container
    end
    -- ============================================================
    -- ADD CATEGORY (sidebar section label like "MAIN", "COMBAT")
    -- ============================================================
    function WindowObj:AddCategory(name)
        local catOrder = #WindowObj.Tabs + 1

        local CatLabel = Util.Create("Frame", {
            Name = "Cat_" .. name,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 22),
            LayoutOrder = catOrder * 100 - 1,
            ZIndex = 3,
            Parent = TabContainer
        })

        Util.Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            Text = string.upper(name),
            TextColor3 = Theme.TextMuted,
            FontFace = Theme.FontSemiBold,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Bottom,
            ZIndex = 4,
            Parent = CatLabel
        })

        -- Thin separator line at top (skip for first category)
        if #TabContainer:GetChildren() > 3 then -- list + padding + this
            local sep = Util.Create("Frame", {
                Name = "Sep",
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, -16, 0, 1),
                Position = UDim2.new(0, 8, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 3,
                Parent = CatLabel
            })
            Themed(sep, { BackgroundColor3 = function(t) return t.Border end })
        end

        return CatLabel
    end

    -- ============================================================
    function WindowObj:AddTab(tabCfg)
        tabCfg = tabCfg or {}
        local tabName  = tabCfg.Name or "Tab"
        local tabIcon  = tabCfg.Icon or nil
        local tabOrder = #WindowObj.Tabs + 1

        local TabObj = {}
        TabObj.Sections = {}
        TabObj.Name = tabName

        -- Tab button in sidebar
        local TabButton = Util.Create("TextButton", {
            Name = "Tab_" .. tabName,
            BackgroundColor3 = Theme.Sidebar,
            BackgroundTransparency = 0,
            Size = UDim2.new(1, 0, 0, 36),
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = tabOrder,
            ZIndex = 3,
            Parent = TabContainer
        })
        Util.AddCorner(TabButton, Theme.CornerSmall)
        local _tabStroke = Util.AddStroke(TabButton, Theme.Border, 1, 0.35)
        Themed(TabButton, { BackgroundColor3 = function(t) return t.Sidebar end })
        Themed(_tabStroke, { Color = function(t) return t.Border end })

        -- Active indicator bar (left edge)
        local ActiveBar = Util.Create("Frame", {
            Name = "Bar",
            BackgroundColor3 = Theme.Accent,
            Size = UDim2.new(0, 3, 0, 0),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BorderSizePixel = 0,
            ZIndex = 4,
            Parent = TabButton
        })
        Util.AddCorner(ActiveBar, UDim.new(0, 2))
        Themed(ActiveBar, { BackgroundColor3 = function(t) return t.Accent end })

        local iconOffset = 0
        local IconLabel = nil
        if tabIcon then
            IconLabel = Util.Create("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 12, 0.5, 0),
                AnchorPoint = Vector2.new(0, 0.5),
                Image = tabIcon,
                ImageColor3 = Theme.TextDim,
                ZIndex = 4,
                Parent = TabButton
            })
            Themed(IconLabel, { ImageColor3 = function(t) return t.TextDim end })
            iconOffset = 22
        end

        local TabLabel = Util.Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -(18 + iconOffset), 1, 0),
            Position = UDim2.new(0, 12 + iconOffset, 0, 0),
            Text = tabName,
            TextColor3 = Theme.TextDim,
            FontFace = Theme.FontMedium,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 4,
            Parent = TabButton
        })
        Themed(TabLabel, { TextColor3 = function(t) return t.TextDim end })

        -- Content page
        local TabPage = Util.Create("ScrollingFrame", {
            Name = "Page_" .. tabName,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -4, 1, 0),  -- leave 4px right margin for custom scrollbar
            ScrollBarThickness = 0,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Visible = false,
            ClipsDescendants = true,
            ZIndex = 2,
            Parent = ContentArea
        })
        Util.AddPadding(TabPage, 0, 0, 12, 0)

        -- Custom scrollbar thumb (no track line)
        local ScrollThumb = Util.Create("Frame", {
            Name = "ScrollThumb",
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 0.45,
            Size = UDim2.new(0, 3, 0, 40),
            Position = UDim2.new(1, -3, 0, 0),
            BorderSizePixel = 0,
            ZIndex = 10,
            Visible = false,
            Parent = ContentArea,
        })
        Util.AddCorner(ScrollThumb, UDim.new(1, 0))
        Themed(ScrollThumb, { BackgroundColor3 = function(t) return t.Accent end })

        local function UpdateScrollThumb()
            if not TabPage.Visible then return end
            local canvasY = TabPage.AbsoluteCanvasSize.Y
            local frameH = TabPage.AbsoluteSize.Y
            if canvasY <= frameH then
                ScrollThumb.Visible = false
                return
            end
            ScrollThumb.Visible = true
            local ratio = frameH / canvasY
            local thumbH = math.max(20, math.floor(frameH * ratio))
            local scrollPct = TabPage.CanvasPosition.Y / (canvasY - frameH)
            local trackH = frameH - thumbH
            ScrollThumb.Size = UDim2.new(0, 3, 0, thumbH)
            ScrollThumb.Position = UDim2.new(1, -3, 0, math.floor(scrollPct * trackH))
        end

        TabPage:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateScrollThumb)
        TabPage:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(UpdateScrollThumb)
        TabPage:GetPropertyChangedSignal("Visible"):Connect(function()
            if TabPage.Visible then
                task.defer(UpdateScrollThumb)
            else
                ScrollThumb.Visible = false
            end
        end)

        local GroupBar = Util.Create("Frame", {
            Name = "GroupBar",
            BackgroundColor3 = Theme.Surface,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 40),
            Visible = false,
            ZIndex = 3,
            Parent = TabPage
        })
        Util.AddCorner(GroupBar, Theme.CornerSmall)
        local GroupBarStroke = Util.AddStroke(GroupBar, Theme.Border, 1, 0.6)
        Themed(GroupBar, { BackgroundColor3 = function(t) return t.Surface end })
        Themed(GroupBarStroke, { Color = function(t) return t.Border end })

        local GroupList = Util.AddList(GroupBar, Enum.FillDirection.Horizontal, 8)
        GroupList.VerticalAlignment = Enum.VerticalAlignment.Center
        Util.AddPadding(GroupBar, 6, 10, 6, 10)

        local GroupPages = Util.Create("Frame", {
            Name = "GroupPages",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
            Parent = TabPage
        })

        TabObj.Groups = {}
        TabObj.GroupOrder = {}
        TabObj.ActiveGroup = nil

        local function UpdateGroupPagesPosition()
            if GroupBar.Visible then
                GroupPages.Position = UDim2.new(0, 0, 0, 54)
            else
                GroupPages.Position = UDim2.new(0, 0, 0, 0)
            end
        end

        local function CreateGroup(groupName)
            local GroupPage = Util.Create("Frame", {
                Name = "Group_" .. tostring(groupName),
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Visible = false,
                ZIndex = 2,
                Parent = GroupPages
            })

            local Columns = Util.Create("Frame", {
                Name = "Columns",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 2,
                Parent = GroupPage
            })

            local LeftColumn = Util.Create("Frame", {
                Name = "Left",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 100, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 0, 0, 0),
                ZIndex = 2,
                Parent = Columns
            })
            Util.AddList(LeftColumn, Enum.FillDirection.Vertical, 8)

            local RightColumn = Util.Create("Frame", {
                Name = "Right",
                BackgroundTransparency = 1,
                Size = UDim2.new(0, 100, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 112, 0, 0),
                ZIndex = 2,
                Parent = Columns
            })
            Util.AddList(RightColumn, Enum.FillDirection.Vertical, 8)

            local GroupButton = nil
            if groupName ~= "__default" then
                GroupBar.Visible = true
                UpdateGroupPagesPosition()

                GroupButton = Util.Create("TextButton", {
                    Name = "GroupBtn_" .. tostring(groupName),
                    BackgroundColor3 = Theme.SurfaceLight,
                    BackgroundTransparency = 0.12,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 0, 28),
                    Text = tostring(groupName),
                    TextColor3 = Theme.Text,
                    FontFace = Theme.FontBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 4,
                    Parent = GroupBar
                })
                Util.AddCorner(GroupButton, Theme.CornerSmall)
                Util.AddPadding(GroupButton, 0, 14, 0, 14)
                local GroupButtonStroke = Util.AddStroke(GroupButton, Theme.BorderLight, 1, 0.28)
                Themed(GroupButton, {
                    BackgroundColor3 = function(t)
                        if TabObj.ActiveGroup and TabObj.ActiveGroup.Button == GroupButton then
                            return t.SurfaceHover
                        end
                        return t.SurfaceLight
                    end,
                    TextColor3 = function(t)
                        if TabObj.ActiveGroup and TabObj.ActiveGroup.Button == GroupButton then
                            return t.Text
                        end
                        return t.TextDim
                    end,
                })
                Themed(GroupButtonStroke, {
                    Color = function(t)
                        if TabObj.ActiveGroup and TabObj.ActiveGroup.Button == GroupButton then
                            return t.Accent
                        end
                        return t.BorderLight
                    end
                })

            end

            local function UpdateColumns()
                local width = GroupPages.AbsoluteSize.X
                if width <= 0 then
                    return
                end

                local function CountSections(column)
                    local total = 0
                    for _, child in ipairs(column:GetChildren()) do
                        if child:IsA("Frame") and child.Name:find("^Sec_") then
                            total = total + 1
                        end
                    end
                    return total
                end

                local gap = 12
                local usable = math.max(220, width - 28)
                local leftCount = CountSections(LeftColumn)
                local rightCount = CountSections(RightColumn)

                if leftCount > 0 and rightCount == 0 then
                    LeftColumn.Size = UDim2.new(1, 0, 0, 0)
                    RightColumn.Visible = false
                    RightColumn.Size = UDim2.new(0, 0, 0, 0)
                    return
                elseif rightCount > 0 and leftCount == 0 then
                    LeftColumn.Size = UDim2.new(0, 0, 0, 0)
                    RightColumn.Visible = true
                    RightColumn.Position = UDim2.new(0, 0, 0, 0)
                    RightColumn.Size = UDim2.new(1, 0, 0, 0)
                    return
                end

                RightColumn.Visible = true
                local colWidth = math.floor((usable - gap) / 2)
                LeftColumn.Size = UDim2.new(0, colWidth, 0, 0)
                RightColumn.Position = UDim2.new(0, colWidth + gap, 0, 0)
                RightColumn.Size = UDim2.new(0, colWidth, 0, 0)
            end

            UpdateColumns()
            Util.Connect(GroupPages:GetPropertyChangedSignal("AbsoluteSize"), UpdateColumns)

            local groupData = {
                Name = groupName,
                Page = GroupPage,
                Columns = Columns,
                Left = LeftColumn,
                Right = RightColumn,
                Button = GroupButton,
                UpdateColumns = UpdateColumns,
            }

            table.insert(TabObj.GroupOrder, groupData)
            TabObj.Groups[groupName] = groupData

            if GroupButton then
                GroupButton.MouseEnter:Connect(function()
                    if TabObj.ActiveGroup ~= groupData then
                        Util.TweenFast(GroupButton, {TextColor3 = Hyperion.Theme.Text, BackgroundTransparency = 0, BackgroundColor3 = Hyperion.Theme.SurfaceHover})
                    end
                end)
                GroupButton.MouseLeave:Connect(function()
                    if TabObj.ActiveGroup ~= groupData then
                        Util.TweenFast(GroupButton, {TextColor3 = Hyperion.Theme.TextDim, BackgroundTransparency = 0.08, BackgroundColor3 = Hyperion.Theme.SurfaceLight})
                    end
                end)
            end

            return groupData
        end

        local function EnsureGroup(groupName)
            return TabObj.Groups[groupName] or CreateGroup(groupName)
        end

        local function ActivateGroup(groupData)
            TabObj.ActiveGroup = groupData

            for _, grp in ipairs(TabObj.GroupOrder) do
                grp.Page.Visible = false
                if grp.Button then
                    local isActive = (grp == groupData)
                    Util.TweenFast(grp.Button, {
                        BackgroundColor3 = isActive and Theme.SurfaceHover or Theme.SurfaceLight,
                        TextColor3 = isActive and Theme.Text or Theme.TextDim
                    })
                    if grp.Button:FindFirstChild("Underline") then
                        grp.Button.Underline.Visible = false
                    end
                    local grpStroke = grp.Button:FindFirstChildOfClass("UIStroke")
                    if grpStroke then
                        Util.TweenFast(grpStroke, {
                            Color = isActive and Theme.Accent or Theme.BorderLight,
                            Transparency = isActive and 0.08 or 0.28
                        })
                    end
                end
            end

            groupData.Page.Visible = true
        end

        TabObj.ActivateGroup = ActivateGroup

        -- Tab switching
        local function ActivateTab()
            for _, tab in ipairs(WindowObj.Tabs) do
                tab.Page.Visible = false
                Util.TweenFast(tab.Button, {BackgroundColor3 = Theme.Sidebar})
                Util.TweenFast(tab.Label, {TextColor3 = Theme.TextDim})
                Util.TweenSmooth(tab.ActiveBar, {Size = UDim2.new(0, 3, 0, 0)})
                if tab.IconLabel then
                    Util.TweenFast(tab.IconLabel, {ImageColor3 = Theme.TextDim})
                end
            end

            TabPage.Visible = true
            TabPage.CanvasPosition = Vector2.new(0, 0)
            if TabObj.ActiveGroup then
                ActivateGroup(TabObj.ActiveGroup)
            elseif TabObj.Groups["__default"] then
                ActivateGroup(TabObj.Groups["__default"])
            elseif TabObj.GroupOrder[1] then
                ActivateGroup(TabObj.GroupOrder[1])
            end
            Util.TweenFast(TabButton, {BackgroundColor3 = Theme.SidebarActive})
            Util.TweenFast(TabLabel, {TextColor3 = Theme.Text})
            Util.TweenSmooth(ActiveBar, {Size = UDim2.new(0, 3, 0, 22)})
            if IconLabel then
                Util.TweenFast(IconLabel, {ImageColor3 = Theme.Accent})
            end
            WindowObj.ActiveTab = TabObj
        end
        TabObj.Activate = ActivateTab

        -- Hover
        TabButton.MouseEnter:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Util.TweenFast(TabButton, {BackgroundColor3 = Hyperion.Theme.SurfaceHover})
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if WindowObj.ActiveTab ~= TabObj then
                Util.TweenFast(TabButton, {BackgroundColor3 = Hyperion.Theme.Sidebar})
            end
        end)
        TabButton.MouseButton1Click:Connect(ActivateTab)

        -- Store
        local tabData = {
            Object    = TabObj,
            Button    = TabButton,
            Label     = TabLabel,
            Page      = TabPage,
            ActiveBar = ActiveBar,
            IconLabel = IconLabel,
        }
        table.insert(WindowObj.Tabs, tabData)

        -- Activate first
        if #WindowObj.Tabs == 1 then
            ActivateTab()
        end

        -- ============================================================
        -- ADD SECTION
        -- ============================================================
        function TabObj:AddSection(secCfg)
            secCfg = secCfg or {}
            local secName = secCfg.Name or "Section"
            local side    = string.lower(secCfg.Side or secCfg.Position or "Left")
            local groupName = secCfg.Group or "__default"
            local groupData = EnsureGroup(groupName)
            local parentCol = (side == "right") and groupData.Right or groupData.Left
            local _grpDisplay = (groupName ~= "__default") and groupName or secName
            local function _regSearch(elName, elFrame, kind, elCfg)
                -- Any element passing a Tooltip = "..." in its config gets a
                -- hover bubble; every element type already routes through here.
                if elCfg and elCfg.Tooltip and elFrame then
                    pcall(Util.AttachTooltip, elFrame, elCfg.Tooltip)
                end
                if not elName or elName == "" then return end
                table.insert(Hyperion._SearchIndex, {
                    name = elName, lname = string.lower(elName),
                    section = secName, group = _grpDisplay, kind = kind or "",
                    tabName = (TabObj.Name or ""), ltab = string.lower(TabObj.Name or ""),
                    frame = elFrame, tab = TabObj, groupData = groupData, page = TabPage,
                })
            end

            if not TabObj.ActiveGroup then
                if groupName == "__default" then
                    ActivateGroup(groupData)
                elseif TabObj.Groups["__default"] then
                    ActivateGroup(TabObj.Groups["__default"])
                else
                    ActivateGroup(groupData)
                end
            end

            if groupData.Button then
                groupData.Button.MouseButton1Click:Connect(function()
                    ActivateGroup(groupData)
                end)
            end

            local SectionObj = {}

            local SectionFrame = Util.Create("Frame", {
                Name = "Sec_" .. secName,
                BackgroundColor3 = Theme.Surface,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                ZIndex = 2,
                Parent = parentCol
            })
            task.defer(function()
                if groupData.UpdateColumns then
                    groupData.UpdateColumns()
                end
            end)
            Util.AddCorner(SectionFrame, Theme.CornerRadius)
            local _secStroke = Util.AddStroke(SectionFrame, Theme.Border, 1, 0.62)
            Themed(SectionFrame, { BackgroundColor3 = function(t) return t.Surface end })
            Themed(_secStroke, { Color = function(t) return t.Border end })

            -- Section header
            local SecHeader = Util.Create("Frame", {
                Name = "SecHeader",
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 34),
                ClipsDescendants = true,
                ZIndex = 2,
                Parent = SectionFrame
            })
            Util.AddCorner(SecHeader, Theme.CornerRadius)
            Themed(SecHeader, { BackgroundColor3 = function(t) return t.Surface end })

            local _secBottomFix = Util.Create("Frame", {
                Name = "BottomFix",
                BackgroundColor3 = Theme.Surface,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1, 0, 0, 10),
                Position = UDim2.new(0, 0, 1, -10),
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = SecHeader
            })
            Themed(_secBottomFix, { BackgroundColor3 = function(t) return t.Surface end })

            local _secTitle = Util.Create("TextLabel", {
                Name = "Title",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -24, 1, 0),
                Position = UDim2.new(0, 12, 0, 1),
                Text = string.upper(secName),
                TextColor3 = Theme.Text,
                FontFace = Theme.FontBold,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 3,
                Parent = SecHeader
            })
            Themed(_secTitle, { TextColor3 = function(t) return t.Text end })

            local _secDivider = Util.Create("Frame", {
                Name = "Divider",
                BackgroundColor3 = Theme.Border,
                BackgroundTransparency = 0.35,
                Size = UDim2.new(1, 0, 0, 1),
                Position = UDim2.new(0, 0, 1, -1),
                BorderSizePixel = 0,
                ZIndex = 2,
                Parent = SecHeader
            })
            Themed(_secDivider, { BackgroundColor3 = function(t) return t.Border end })

            -- Element container
            local Elements = Util.Create("Frame", {
                Name = "Elements",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Position = UDim2.new(0, 0, 0, 31),
                ZIndex = 2,
                Parent = SectionFrame
            })
            Util.AddList(Elements, Enum.FillDirection.Vertical, 2)
            Util.AddPadding(Elements, 6, 10, 10, 10)

            -- ==============================================
            -- TOGGLE
            -- ==============================================
            function SectionObj:AddToggle(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Toggle"
                local default  = cfg.Default or false
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local value    = default

                if flag then
                    Hyperion.Flags[flag] = value
                end

                local Frame = Util.Create("Frame", {
                    Name = "Toggle_" .. name,
                    BackgroundColor3 = Theme.SurfaceLight,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Toggle", cfg)
                Util.AddCorner(Frame, Theme.CornerSmall)

                local ToggleLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -52, 1, 0),
                    Position = UDim2.new(0, 0, 0, 0),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(ToggleLabel, { TextColor3 = function(t) return t.Text end })

                -- Toggle track
                local Track = Util.Create("Frame", {
                    Name = "Track",
                    BackgroundColor3 = value and Theme.Accent or Theme.ToggleOff,
                    Size = UDim2.new(0, 34, 0, 18),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    ZIndex = 3,
                    Parent = Frame
                })
                Util.AddCorner(Track, UDim.new(1, 0))
                Themed(Track, { BackgroundColor3 = function(t) return value and t.Accent or t.ToggleOff end })

                -- Accent gradient across the track while active; disabled when
                -- off so the flat ToggleOff colour shows through.
                local TrackGrad = Util.Create("UIGradient", {
                    Color = ColorSequence.new(Theme.AccentDark, Theme.AccentLight),
                    Enabled = value,
                    Parent = Track
                })
                Themed(TrackGrad, { Color = function(t) return ColorSequence.new(t.AccentDark, t.AccentLight) end })

                -- Glow behind track when active
                local TrackGlow = Util.Create("UIStroke", {
                    Color = Theme.AccentGlow,
                    Thickness = value and 1 or 0,
                    Transparency = 0.6,
                    Parent = Track
                })
                Themed(TrackGlow, { Color = function(t) return t.AccentGlow end })

                local Knob = Util.Create("Frame", {
                    Name = "Knob",
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = value and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                    AnchorPoint = value and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
                    ZIndex = 4,
                    Parent = Track
                })
                Util.AddCorner(Knob, UDim.new(1, 0))

                local Hitbox = Util.Create("TextButton", {
                    Name = "Hit",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, 0),
                    Text = "",
                    ZIndex = 5,
                    Parent = Frame
                })

                -- Inline accessories: a colour swatch and/or keybind chip ride on
                -- the same row as the toggle they belong to, so one feature costs
                -- one row instead of three. Both are optional; omit them and the
                -- toggle renders exactly as before. ZIndex 6 keeps them above the
                -- full-row hitbox so their own clicks land.
                local accOffset = -48
                if type(cfg.Color) == "table" then
                    local ccfg = cfg.Color
                    local ccol = ccfg.Default or Color3.fromRGB(255, 255, 255)
                    if ccfg.Flag then Hyperion.Flags[ccfg.Flag] = ccol end
                    local Sw = Util.Create("TextButton", {
                        Name = "Swatch", BackgroundColor3 = ccol, Text = "",
                        Size = UDim2.fromOffset(22, 22),
                        Position = UDim2.new(1, accOffset, 0.5, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        AutoButtonColor = false, ZIndex = 6, Parent = Frame,
                    })
                    Util.AddCorner(Sw, UDim.new(0, 4))
                    local _swStroke = Util.AddStroke(Sw, Theme.BorderLight, 1, 0.3)
                    Themed(_swStroke, { Color = function(t) return t.BorderLight end })
                    local function applyCol(c2)
                        Sw.BackgroundColor3 = c2
                        if ccfg.Flag then Hyperion.Flags[ccfg.Flag] = c2 end
                        if ccfg.Callback then task.spawn(ccfg.Callback, c2) end
                    end
                    Util.AttachColorSwatch(Sw, function() return Sw.BackgroundColor3 end, applyCol)
                    if ccfg.Flag then
                        Hyperion.FlagCallbacks[ccfg.Flag] = applyCol
                        local cAPI = { Kind = "color" }
                        function cAPI:Set(v2) applyCol(v2) end
                        function cAPI:Get() return Sw.BackgroundColor3 end
                        Hyperion.FlagAPIs[ccfg.Flag] = cAPI
                    end
                    accOffset = accOffset - 28
                end
                if type(cfg.Keybind) == "table" then
                    local kcfg = cfg.Keybind
                    local key = kcfg.Default
                    if kcfg.Flag then Hyperion.Flags[kcfg.Flag] = key end
                    local Chip = Util.Create("TextButton", {
                        Name = "KeyChip", BackgroundColor3 = Theme.SurfaceActive,
                        BackgroundTransparency = 0.25,
                        Size = UDim2.fromOffset(42, 20),
                        Position = UDim2.new(1, accOffset, 0.5, 0),
                        AnchorPoint = Vector2.new(1, 0.5),
                        Text = (typeof(key) == "EnumItem") and key.Name or "None",
                        TextColor3 = Theme.TextDim, FontFace = Theme.FontMedium,
                        TextSize = 10, AutoButtonColor = false, ZIndex = 6, Parent = Frame,
                    })
                    Util.AddCorner(Chip, UDim.new(0, 4))
                    Themed(Chip, { BackgroundColor3 = function(t) return t.SurfaceActive end })
                    local listening = false
                    Chip.MouseButton1Click:Connect(function()
                        listening = true
                        Chip.Text = "..."
                        Chip.TextColor3 = Hyperion.Theme.Accent
                    end)
                    UserInputService.InputBegan:Connect(function(input, gp)
                        if not listening or gp then return end
                        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                        listening = false
                        key = input.KeyCode
                        Chip.Text = key.Name
                        Chip.TextColor3 = Hyperion.Theme.TextDim
                        if kcfg.Flag then Hyperion.Flags[kcfg.Flag] = key end
                        if kcfg.Callback then task.spawn(kcfg.Callback, key) end
                    end)
                    accOffset = accOffset - 48
                end
                ToggleLabel.Size = UDim2.new(1, accOffset - 6, 1, 0)

                local function UpdateVisual(state)
                    TrackGrad.Enabled = state
                    Util.TweenSmooth(Track, {BackgroundColor3 = state and Hyperion.Theme.Accent or Hyperion.Theme.ToggleOff})
                    Util.TweenSmooth(TrackGlow, {Thickness = state and 1 or 0})
                    Util.TweenSmooth(Knob, {
                        Position = state and UDim2.new(1, -3, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                        AnchorPoint = state and Vector2.new(1, 0.5) or Vector2.new(0, 0.5),
                    })
                end

                -- Register callback for config loading
                if flag then
                    Hyperion.FlagCallbacks[flag] = function(v)
                        value = v
                        Hyperion.Flags[flag] = v
                        UpdateVisual(v)
                        task.spawn(callback, v)
                    end
                end

                Hitbox.MouseButton1Click:Connect(function()
                    value = not value
                    if flag then Hyperion.Flags[flag] = value end
                    UpdateVisual(value)
                    task.spawn(callback, value)
                end)

                -- Hover effect on row
                Hitbox.MouseEnter:Connect(function()
                    Util.TweenFast(Frame, {BackgroundTransparency = 0.5})
                end)
                Hitbox.MouseLeave:Connect(function()
                    Util.TweenFast(Frame, {BackgroundTransparency = 1})
                end)

                local API = {}
                function API:Set(v) value = v; if flag then Hyperion.Flags[flag] = v end; UpdateVisual(v); task.spawn(callback, v) end
                function API:Get() return value end
                API.Kind = "toggle"
                if flag then Hyperion.FlagAPIs[flag] = API end
                return API
            end

            -- ==============================================
            -- SLIDER
            -- ==============================================
            function SectionObj:AddSlider(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Slider"
                local min      = cfg.Min or 0
                local max      = cfg.Max or 100
                local default  = math.clamp(cfg.Default or min, min, max)
                local round    = cfg.Round or 1
                local suffix   = cfg.Suffix or ""
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local value    = default

                if flag then Hyperion.Flags[flag] = value end

                local hideMax = cfg.HideMax or false
                local _setVal

                local Frame = Util.Create("Frame", {
                    Name = "Slider_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 38),
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Slider", cfg)

                -- Label + Value row
                local Row = Util.Create("Frame", {
                    Name = "Row",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    ZIndex = 2,
                    Parent = Frame
                })

                local SliderLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.65, 0, 1, 0),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Row
                })
                Themed(SliderLabel, { TextColor3 = function(t) return t.Text end })

                local ValBox = Util.Create("Frame", {
                    Name = "ValBox",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.35, 0, 1, 0),
                    Position = UDim2.new(0.65, 0, 0, 0),
                    ZIndex = 2,
                    Parent = Row
                })
                Util.AddList(ValBox, Enum.FillDirection.Horizontal, 0,
                    Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

                local ValLabel = Util.Create("TextLabel", {
                    Name = "Val",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "",
                    TextColor3 = Theme.Accent,
                    FontFace = Theme.FontMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    LayoutOrder = 1,
                    ZIndex = 2,
                    Parent = ValBox
                })
                Themed(ValLabel, { TextColor3 = function(t) return t.Accent end })

                local MaxLabel = Util.Create("TextLabel", {
                    Name = "Max",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text = "/" .. string.format("%.10g", max) .. suffix,
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.FontMedium,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Visible = not hideMax,
                    LayoutOrder = 2,
                    ZIndex = 2,
                    Parent = ValBox
                })
                Themed(MaxLabel, { TextColor3 = function(t) return t.TextDim end })

                _setVal = function()
                    ValLabel.Text = string.format("%.10g", value) .. (hideMax and suffix or "")
                end
                _setVal()

                -- Track
                local Track = Util.Create("Frame", {
                    Name = "Track",
                    BackgroundColor3 = Theme.SliderBg,
                    Size = UDim2.new(1, 0, 0, 5),
                    Position = UDim2.new(0, 0, 0, 24),
                    ZIndex = 2,
                    Parent = Frame
                })
                Util.AddCorner(Track, UDim.new(1, 0))
                Themed(Track, { BackgroundColor3 = function(t) return t.SliderBg end })

                local ratio = (value - min) / math.max(max - min, 0.001)

                local Fill = Util.Create("Frame", {
                    Name = "Fill",
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(ratio, 0, 1, 0),
                    ZIndex = 3,
                    Parent = Track
                })
                Util.AddCorner(Fill, UDim.new(1, 0))
                Themed(Fill, { BackgroundColor3 = function(t) return t.Accent end })

                -- Fill glow gradient
                local _fillGrad = Util.Create("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Theme.AccentDark),
                        ColorSequenceKeypoint.new(0.5, Theme.Accent),
                        ColorSequenceKeypoint.new(1, Theme.AccentLight),
                    }),
                    Parent = Fill
                })
                Themed(_fillGrad, {
                    Color = function(t)
                        return ColorSequence.new({
                            ColorSequenceKeypoint.new(0, t.AccentDark),
                            ColorSequenceKeypoint.new(0.5, t.Accent),
                            ColorSequenceKeypoint.new(1, t.AccentLight),
                        })
                    end
                })

                local KnobObj = Util.Create("Frame", {
                    Name = "Knob",
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    Size = UDim2.new(0, 11, 0, 11),
                    Position = UDim2.new(ratio, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ZIndex = 5,
                    Parent = Track
                })
                Util.AddCorner(KnobObj, UDim.new(1, 0))

                local KnobGlow = Util.Create("UIStroke", {
                    Color = Theme.Accent,
                    Thickness = 0,
                    Transparency = 0.4,
                    Parent = KnobObj
                })
                Themed(KnobGlow, { Color = function(t) return t.Accent end })

                -- Hitbox
                local Hitbox = Util.Create("TextButton", {
                    Name = "Hit",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 10, 0, 22),
                    Position = UDim2.new(0, -5, 0, 18),
                    Text = "",
                    ZIndex = 6,
                    Parent = Frame
                })

                local dragging = false

                local function UpdateSlider(input)
                    local pos = math.clamp(
                        (input.Position.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1),
                        0, 1
                    )
                    local rawVal = min + (max - min) * pos
                    value = math.clamp(math.floor(rawVal / round + 0.5) * round, min, max)
                    if flag then Hyperion.Flags[flag] = value end
                    _setVal()
                    local r = (value - min) / math.max(max - min, 0.001)
                    Fill.Size = UDim2.new(r, 0, 1, 0)
                    KnobObj.Position = UDim2.new(r, 0, 0.5, 0)
                    task.spawn(callback, value)
                end

                Hitbox.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Util.TweenFast(KnobGlow, {Thickness = 3})
                        Util.TweenFast(KnobObj, {Size = UDim2.new(0, 13, 0, 13)})
                        UpdateSlider(input)
                    end
                end)
                Hitbox.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                        Util.TweenFast(KnobGlow, {Thickness = 0})
                        Util.TweenFast(KnobObj, {Size = UDim2.new(0, 11, 0, 11)})
                    end
                end)

                -- Pooled input
                table.insert(InputPool.SliderCallbacks, function(input)
                    if dragging then UpdateSlider(input) end
                end)

                if flag then
                    Hyperion.FlagCallbacks[flag] = function(v)
                        value = math.clamp(v, min, max)
                        Hyperion.Flags[flag] = value
                        _setVal()
                        local r = (value - min) / math.max(max - min, 0.001)
                        Fill.Size = UDim2.new(r, 0, 1, 0)
                        KnobObj.Position = UDim2.new(r, 0, 0.5, 0)
                        task.spawn(callback, value)
                    end
                end

                local API = {}
                function API:Set(v) value = math.clamp(v, min, max); if flag then Hyperion.Flags[flag] = value end; _setVal(); local r = (value - min) / math.max(max - min, 0.001); Fill.Size = UDim2.new(r, 0, 1, 0); KnobObj.Position = UDim2.new(r, 0, 0.5, 0); task.spawn(callback, value) end
                function API:Get() return value end
                API.Kind = "slider"; API.Min = min; API.Max = max
                if flag then Hyperion.FlagAPIs[flag] = API end
                return API
            end

            -- ==============================================
            -- BUTTON
            -- ==============================================
            function SectionObj:AddButton(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Button"
                local callback = cfg.Callback or function() end
                local icon     = cfg.Icon or nil

                local Btn = Util.Create("TextButton", {
                    Name = "Btn_" .. name,
                    BackgroundColor3 = Theme.SurfaceLight,
                    Size = UDim2.new(1, 0, 0, 30),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Btn, "Button", cfg)
                Util.AddCorner(Btn, Theme.CornerSmall)
                local _btnStroke = Util.AddStroke(Btn, Theme.Border, 1, 0.45)
                Themed(Btn, { BackgroundColor3 = function(t) return t.SurfaceLight end })
                Themed(_btnStroke, { Color = function(t) return t.Border end })

                -- Left accent bar
                local BtnAccent = Util.Create("Frame", {
                    Name = "Accent",
                    BackgroundColor3 = Theme.Accent,
                    BackgroundTransparency = 0.55,
                    Size = UDim2.new(0, 2, 0.6, 0),
                    Position = UDim2.new(0, 0, 0.2, 0),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Parent = Btn
                })
                Util.AddCorner(BtnAccent, UDim.new(1, 0))
                Themed(BtnAccent, { BackgroundColor3 = function(t) return t.Accent end })

                local xOffset = 10
                if icon then
                    local BtnIcon = Util.Create("ImageLabel", {
                        Name = "Icon",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = UDim2.new(0, 10, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = icon,
                        ImageColor3 = Theme.TextDim,
                        ZIndex = 3,
                        Parent = Btn
                    })
                    Themed(BtnIcon, { ImageColor3 = function(t) return t.TextDim end })
                    xOffset = 28
                end

                local BtnLabel = Util.Create("TextLabel", {
                    Name = "Lbl",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -(xOffset + 8), 1, 0),
                    Position = UDim2.new(0, xOffset, 0, 0),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.FontMedium,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 3,
                    Parent = Btn
                })
                Themed(BtnLabel, { TextColor3 = function(t) return t.Text end })

                Btn.MouseEnter:Connect(function()
                    Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.SurfaceHover})
                    Util.TweenFast(BtnAccent, {BackgroundTransparency = 0.2})
                end)
                Btn.MouseLeave:Connect(function()
                    Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.SurfaceLight})
                    Util.TweenFast(BtnAccent, {BackgroundTransparency = 0.55})
                end)
                Btn.MouseButton1Click:Connect(function()
                    Util.Ripple(Btn, Hyperion.Theme.Accent)
                    Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.AccentDark})
                    task.delay(0.12, function()
                        Util.TweenFast(Btn, {BackgroundColor3 = Hyperion.Theme.SurfaceLight})
                    end)
                    task.spawn(callback)
                end)

                local API = {}
                function API:SetLabel(t)
                    local lbl = Btn:FindFirstChild("Lbl")
                    if lbl then lbl.Text = t end
                end
                return API
            end

            -- ==============================================
            -- DROPDOWN
            -- ==============================================
            function SectionObj:AddDropdown(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Dropdown"
                local values   = cfg.Values or {}
                local multi    = cfg.Multi or false
                local default  = cfg.Default or (multi and {} or values[1])
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local maxRows  = cfg.MaxRows or 6
                local searchable = cfg.Search
                if searchable == nil then searchable = #values > 8 end

                local selected = default
                if multi and type(selected) ~= "table" then selected = {} end
                local opened, filter = false, ""
                local rows = {}
                local Choose

                local optsY = 54 + (searchable and 30 or 0)

                if flag then Hyperion.Flags[flag] = selected end

                local Frame = Util.Create("Frame", {
                    Name = "Drop_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 58),
                    ClipsDescendants = false,
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Dropdown", cfg)

                local DropLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(DropLabel, { TextColor3 = function(t) return t.Text end })

                local DropBtn = Util.Create("TextButton", {
                    Name = "DropBtn",
                    BackgroundColor3 = Theme.SurfaceLight,
                    Size = UDim2.new(1, 0, 0, 30),
                    Position = UDim2.new(0, 0, 0, 22),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 3,
                    Parent = Frame
                })
                Util.AddCorner(DropBtn, Theme.CornerSmall)
                local dropStroke = Util.AddStroke(DropBtn, Theme.BorderLight, 1, 0.25)
                Themed(DropBtn, { BackgroundColor3 = function(t) return t.SurfaceLight end })
                Themed(dropStroke, { Color = function(t) return opened and t.Accent or t.BorderLight end })

                local DropText = Util.Create("TextLabel", {
                    Name = "Text",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -34, 1, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    Text = "",
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 4,
                    Parent = DropBtn
                })
                Themed(DropText, { TextColor3 = function(t) return t.TextDim end })

                local ChipHolder
                if multi then
                    ChipHolder = Util.Create("Frame", {
                        Name = "Chips",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -36, 1, 0),
                        Position = UDim2.new(0, 8, 0, 0),
                        ClipsDescendants = true,
                        Visible = false,
                        ZIndex = 4,
                        Parent = DropBtn
                    })
                    Util.AddList(ChipHolder, Enum.FillDirection.Horizontal, 4,
                        Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
                end

                local Arrow = Util.Create("ImageLabel", {
                    Name = "Arrow",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 16, 0, 16),
                    Position = UDim2.new(1, -20, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Image = "rbxassetid://10709790948",
                    ImageColor3 = Theme.TextMuted,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 4,
                    Parent = DropBtn
                })
                Themed(Arrow, { ImageColor3 = function(t) return opened and t.Accent or t.TextMuted end })

                local SearchBox, SearchIcon
                if searchable then
                    SearchBox = Util.Create("TextBox", {
                        Name = "Search",
                        BackgroundColor3 = Theme.InputBg,
                        Size = UDim2.new(1, 0, 0, 26),
                        Position = UDim2.new(0, 0, 0, 54),
                        Text = "",
                        PlaceholderText = "Search...",
                        TextColor3 = Theme.Text,
                        PlaceholderColor3 = Theme.TextMuted,
                        FontFace = Theme.Font,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ClearTextOnFocus = false,
                        BorderSizePixel = 0,
                        Visible = false,
                        ZIndex = 20,
                        Parent = Frame
                    })
                    Util.AddCorner(SearchBox, Theme.CornerSmall)
                    local sStroke = Util.AddStroke(SearchBox, Theme.Border, 1, 0.35)
                    Util.AddPadding(SearchBox, 0, 8, 0, 26)
                    Themed(SearchBox, {
                        BackgroundColor3 = function(t) return t.InputBg end,
                        TextColor3 = function(t) return t.Text end,
                        PlaceholderColor3 = function(t) return t.TextMuted end,
                    })
                    Themed(sStroke, { Color = function(t) return t.Border end })

                    SearchIcon = Util.Create("ImageLabel", {
                        Name = "SearchIcon",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 8, 0, 61),
                        Image = "rbxassetid://10734943674",
                        ImageColor3 = Theme.TextMuted,
                        ScaleType = Enum.ScaleType.Fit,
                        Visible = false,
                        ZIndex = 21,
                        Parent = Frame
                    })
                    Themed(SearchIcon, { ImageColor3 = function(t) return t.TextMuted end })
                end

                local OptsFrame = Util.Create("ScrollingFrame", {
                    Name = "Opts",
                    BackgroundColor3 = Theme.Surface,
                    Size = UDim2.new(1, 0, 0, 0),
                    Position = UDim2.new(0, 0, 0, optsY),
                    ClipsDescendants = true,
                    Visible = false,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Theme.Accent,
                    ScrollBarImageTransparency = 0.35,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    ZIndex = 20,
                    Parent = Frame
                })
                Util.AddCorner(OptsFrame, Theme.CornerSmall)
                local OptsStroke = Util.AddStroke(OptsFrame, Theme.Border, 1, 0.3)
                Util.AddPadding(OptsFrame, 3, 3, 3, 3)
                Util.AddList(OptsFrame, Enum.FillDirection.Vertical, 1)
                Themed(OptsFrame, {
                    BackgroundColor3 = function(t) return t.Surface end,
                    ScrollBarImageColor3 = function(t) return t.Accent end,
                })
                Themed(OptsStroke, { Color = function(t) return t.Border end })

                local EmptyLbl = Util.Create("TextLabel", {
                    Name = "Empty",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 26),
                    Text = "No matches",
                    TextColor3 = Theme.TextMuted,
                    FontFace = Theme.Font,
                    TextSize = 12,
                    Visible = false,
                    LayoutOrder = 1000000,
                    ZIndex = 21,
                    Parent = OptsFrame
                })
                Themed(EmptyLbl, { TextColor3 = function(t) return t.TextMuted end })

                local function IsSel(val)
                    if multi then return table.find(selected, val) ~= nil end
                    return selected == val
                end

                local function PaintRow(r)
                    local T = Hyperion.Theme
                    local sel = IsSel(r.val)
                    r.sel = sel
                    r.btn.BackgroundColor3 = sel and T.SurfaceActive or T.Surface
                    r.btn.BackgroundTransparency = sel and 0 or 1
                    r.lbl.TextColor3 = sel and T.Text or T.TextDim
                    r.lbl.FontFace = sel and T.FontMedium or T.Font
                    if r.box then
                        r.box.BackgroundColor3 = sel and T.Accent or T.ToggleOff
                        r.tick.ImageTransparency = sel and 0 or 1
                    end
                end

                local function RenderChips()
                    for _, ch in ipairs(ChipHolder:GetChildren()) do
                        if ch:IsA("Frame") then ch:Destroy() end
                    end
                    local T = Hyperion.Theme
                    local total = #selected
                    local shown = math.min(total, 3)
                    for i = 1, shown do
                        local chip = Util.Create("Frame", {
                            BackgroundColor3 = T.Accent,
                            BackgroundTransparency = 0.82,
                            Size = UDim2.new(0, 0, 0, 18),
                            AutomaticSize = Enum.AutomaticSize.X,
                            BorderSizePixel = 0,
                            LayoutOrder = i,
                            ZIndex = 5,
                            Parent = ChipHolder
                        })
                        Util.AddCorner(chip, UDim.new(0, 4))
                        Util.AddStroke(chip, T.Accent, 1, 0.55)
                        Util.AddPadding(chip, 0, 6, 0, 6)
                        Util.Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0, 0, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = tostring(selected[i]),
                            TextColor3 = T.Text,
                            FontFace = T.FontMedium,
                            TextSize = 11,
                            ZIndex = 6,
                            Parent = chip
                        })
                    end
                    if total > shown then
                        local more = Util.Create("Frame", {
                            BackgroundColor3 = T.SurfaceActive,
                            Size = UDim2.new(0, 0, 0, 18),
                            AutomaticSize = Enum.AutomaticSize.X,
                            BorderSizePixel = 0,
                            LayoutOrder = 999,
                            ZIndex = 5,
                            Parent = ChipHolder
                        })
                        Util.AddCorner(more, UDim.new(0, 4))
                        Util.AddPadding(more, 0, 5, 0, 5)
                        Util.Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2.new(0, 0, 1, 0),
                            AutomaticSize = Enum.AutomaticSize.X,
                            Text = "+" .. (total - shown),
                            TextColor3 = T.TextDim,
                            FontFace = T.FontMedium,
                            TextSize = 11,
                            ZIndex = 6,
                            Parent = more
                        })
                    end
                end

                local function UpdateDisplay()
                    if multi then
                        local n = #selected
                        DropText.Visible = (n == 0)
                        ChipHolder.Visible = (n > 0)
                        if n == 0 then
                            DropText.Text = cfg.Placeholder or "None"
                        else
                            RenderChips()
                        end
                    else
                        DropText.Text = tostring(selected or cfg.Placeholder or "Select...")
                    end
                end

                local function BuildRows()
                    for i = 1, #rows do
                        if rows[i].btn then rows[i].btn:Destroy() end
                    end
                    table.clear(rows)
                    for i = 1, #values do
                        local val = values[i]
                        local btn = Util.Create("TextButton", {
                            Name = "O_" .. tostring(val),
                            BackgroundColor3 = Theme.Surface,
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                            Text = "",
                            AutoButtonColor = false,
                            BorderSizePixel = 0,
                            LayoutOrder = i,
                            ZIndex = 21,
                            Parent = OptsFrame
                        })
                        Util.AddCorner(btn, Theme.CornerSmall)

                        local box, tick
                        if multi then
                            box = Util.Create("Frame", {
                                Name = "Box",
                                BackgroundColor3 = Theme.ToggleOff,
                                Size = UDim2.new(0, 14, 0, 14),
                                Position = UDim2.new(0, 7, 0.5, 0),
                                AnchorPoint = Vector2.new(0, 0.5),
                                BorderSizePixel = 0,
                                ZIndex = 22,
                                Parent = btn
                            })
                            Util.AddCorner(box, UDim.new(0, 3))
                            tick = Util.Create("ImageLabel", {
                                Name = "Tick",
                                BackgroundTransparency = 1,
                                Size = UDim2.new(0, 10, 0, 10),
                                Position = UDim2.new(0.5, 0, 0.5, 0),
                                AnchorPoint = Vector2.new(0.5, 0.5),
                                Image = "rbxassetid://10709790644",
                                ImageColor3 = Color3.new(1, 1, 1),
                                ImageTransparency = 1,
                                ScaleType = Enum.ScaleType.Fit,
                                ZIndex = 23,
                                Parent = box
                            })
                        end

                        local lbl = Util.Create("TextLabel", {
                            Name = "Lbl",
                            BackgroundTransparency = 1,
                            Size = UDim2.new(1, -(multi and 34 or 18), 1, 0),
                            Position = UDim2.new(0, multi and 27 or 9, 0, 0),
                            Text = tostring(val),
                            TextColor3 = Theme.TextDim,
                            FontFace = Theme.Font,
                            TextSize = 12,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            TextTruncate = Enum.TextTruncate.AtEnd,
                            ZIndex = 22,
                            Parent = btn
                        })

                        local r = { btn = btn, lbl = lbl, box = box, tick = tick, val = val, sel = false }
                        rows[i] = r

                        btn.MouseEnter:Connect(function()
                            btn.BackgroundColor3 = Hyperion.Theme.SurfaceHover
                            Util.TweenFast(btn, { BackgroundTransparency = 0 })
                        end)
                        btn.MouseLeave:Connect(function()
                            local T = Hyperion.Theme
                            btn.BackgroundColor3 = r.sel and T.SurfaceActive or T.Surface
                            Util.TweenFast(btn, { BackgroundTransparency = r.sel and 0 or 1 })
                        end)
                        btn.MouseButton1Click:Connect(function() Choose(val) end)
                    end
                end

                local function ApplyFilter()
                    local shown = 0
                    for i = 1, #rows do
                        local r = rows[i]
                        local ok = (filter == "")
                            or (string.find(string.lower(tostring(r.val)), filter, 1, true) ~= nil)
                        r.btn.Visible = ok
                        if ok then shown = shown + 1 end
                    end
                    EmptyLbl.Visible = (shown == 0)
                    return shown
                end

                local function Resize()
                    local shown = ApplyFilter()
                    if shown < 1 then shown = 1 end
                    local h = math.min(shown, maxRows) * 27 + 6
                    Util.TweenSmooth(OptsFrame, { Size = UDim2.new(1, 0, 0, h) })
                    Util.TweenSmooth(Frame, { Size = UDim2.new(1, 0, 0, optsY + h + 4) })
                end

                local function Close()
                    if not opened then return end
                    opened = false
                    filter = ""
                    Util.TweenSmooth(OptsFrame, { Size = UDim2.new(1, 0, 0, 0) })
                    Util.TweenSmooth(Frame, { Size = UDim2.new(1, 0, 0, 58) })
                    Util.TweenFast(dropStroke, { Color = Hyperion.Theme.BorderLight, Transparency = 0.25 })
                    Util.TweenFast(Arrow, { ImageColor3 = Hyperion.Theme.TextMuted })
                    Util.Tween(Arrow, 0.2, { Rotation = 0 }, Enum.EasingStyle.Quint)
                    if SearchBox then
                        SearchBox.Visible = false
                        SearchIcon.Visible = false
                    end
                    task.delay(0.3, function()
                        if not opened and OptsFrame and OptsFrame.Parent then
                            OptsFrame.Visible = false
                        end
                    end)
                end

                local function Open()
                    if opened then return end
                    opened = true
                    filter = ""
                    if SearchBox then
                        SearchBox.Text = ""
                        SearchBox.Visible = true
                        SearchIcon.Visible = true
                    end
                    OptsFrame.Visible = true
                    OptsFrame.CanvasPosition = Vector2.new(0, 0)
                    Resize()
                    Util.TweenFast(dropStroke, { Color = Hyperion.Theme.Accent, Transparency = 0.1 })
                    Util.TweenFast(Arrow, { ImageColor3 = Hyperion.Theme.Accent })
                    Util.Tween(Arrow, 0.2, { Rotation = 180 }, Enum.EasingStyle.Quint)
                end

                Choose = function(val)
                    if multi then
                        local idx = table.find(selected, val)
                        if idx then table.remove(selected, idx) else selected[#selected + 1] = val end
                    else
                        selected = val
                    end
                    if flag then Hyperion.Flags[flag] = selected end
                    UpdateDisplay()
                    for i = 1, #rows do PaintRow(rows[i]) end
                    task.spawn(callback, selected)
                    if not multi then Close() end
                end

                BuildRows()
                for i = 1, #rows do PaintRow(rows[i]) end
                UpdateDisplay()

                DropBtn.MouseButton1Click:Connect(function()
                    if opened then Close() else Open() end
                end)
                DropBtn.MouseEnter:Connect(function()
                    if not opened then Util.TweenFast(dropStroke, { Transparency = 0.05 }) end
                end)
                DropBtn.MouseLeave:Connect(function()
                    if not opened then Util.TweenFast(dropStroke, { Transparency = 0.25 }) end
                end)

                if SearchBox then
                    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
                        if not opened then return end
                        filter = string.lower(SearchBox.Text)
                        Resize()
                    end)
                end

                Util.Connect(UserInputService.InputBegan, function(input)
                    if not opened then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1
                       and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local p = input.Position
                    local fp, fs = Frame.AbsolutePosition, Frame.AbsoluteSize
                    if p.X < fp.X or p.X > fp.X + fs.X or p.Y < fp.Y or p.Y > fp.Y + fs.Y then
                        Close()
                    end
                end)

                Hyperion:OnThemeChanged(function()
                    if not Frame or not Frame.Parent then return end
                    for i = 1, #rows do PaintRow(rows[i]) end
                    if multi and #selected > 0 then RenderChips() end
                end)

                if flag then
                    Hyperion.FlagCallbacks[flag] = function(v)
                        if multi and type(v) ~= "table" then return end
                        selected = v
                        Hyperion.Flags[flag] = v
                        UpdateDisplay()
                        for i = 1, #rows do PaintRow(rows[i]) end
                        task.spawn(callback, v)
                    end
                end

                local API = {}
                function API:Set(v)
                    if multi and type(v) ~= "table" then v = { v } end
                    selected = v
                    if flag then Hyperion.Flags[flag] = v end
                    UpdateDisplay()
                    for i = 1, #rows do PaintRow(rows[i]) end
                    task.spawn(callback, selected)
                end
                function API:Get() return selected end
                function API:Refresh(newVals)
                    values = newVals or {}
                    API.Values = values
                    BuildRows()
                    for i = 1, #rows do PaintRow(rows[i]) end
                    UpdateDisplay()
                    if opened then Resize() end
                end
                API.Kind = "dropdown"; API.Values = values
                if flag then Hyperion.FlagAPIs[flag] = API end
                return API
            end

            -- ==============================================
            -- MULTI-DROPDOWN (alias)
            -- ==============================================
            function SectionObj:AddMultiDropdown(cfg)
                cfg = cfg or {}; cfg.Multi = true
                return SectionObj:AddDropdown(cfg)
            end

            -- ==============================================
            -- TEXTBOX
            -- ==============================================
            function SectionObj:AddTextbox(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Textbox"
                local default  = cfg.Default or ""
                local placeholder = cfg.Placeholder or "Type here..."
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local value    = default

                if flag then Hyperion.Flags[flag] = value end

                local Frame = Util.Create("Frame", {
                    Name = "Tb_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 52),
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Textbox", cfg)

                local TbLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 16),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(TbLabel, { TextColor3 = function(t) return t.Text end })

                local Input = Util.Create("TextBox", {
                    Name = "Input",
                    BackgroundColor3 = Theme.SurfaceLight,
                    Size = UDim2.new(1, 0, 0, 28),
                    Position = UDim2.new(0, 0, 0, 22),
                    Text = default,
                    PlaceholderText = placeholder,
                    PlaceholderColor3 = Theme.TextMuted,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 12,
                    ClearTextOnFocus = false,
                    ZIndex = 3,
                    Parent = Frame
                })
                Util.AddCorner(Input, Theme.CornerSmall)
                local inputStroke = Util.AddStroke(Input, Theme.BorderLight, 1, 0.25)
                Util.AddPadding(Input, 0, 8, 0, 8)
                Themed(Input, {
                    BackgroundColor3 = function(t) return t.SurfaceLight end,
                    PlaceholderColor3 = function(t) return t.TextMuted end,
                    TextColor3 = function(t) return t.Text end,
                })
                Themed(inputStroke, { Color = function(t) return t.BorderLight end })

                Input.Focused:Connect(function()
                    Util.TweenFast(inputStroke, {Color = Hyperion.Theme.Accent, Transparency = 0})
                end)
                Input.FocusLost:Connect(function(enter)
                    Util.TweenFast(inputStroke, {Color = Hyperion.Theme.Border, Transparency = 0.4})
                    value = Input.Text
                    if flag then Hyperion.Flags[flag] = value end
                    task.spawn(callback, value, enter)
                end)

                local API = {}
                function API:Set(v) Input.Text = v; value = v; if flag then Hyperion.Flags[flag] = v end end
                function API:Get() return value end
                return API
            end

            -- ==============================================
            -- KEYBIND
            -- ==============================================
            function SectionObj:AddKeybind(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Keybind"
                local default  = cfg.Default or Enum.KeyCode.Unknown
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local value    = default
                local listening = false

                if flag then Hyperion.Flags[flag] = value end

                local Frame = Util.Create("Frame", {
                    Name = "Kb_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Keybind", cfg)

                local KbLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -80, 1, 0),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(KbLabel, { TextColor3 = function(t) return t.Text end })

                local function KeyName(key)
                    if key == Enum.KeyCode.Unknown then return "None" end
                    return string.gsub(tostring(key), "Enum.KeyCode.", "")
                end

                local KbBtn = Util.Create("TextButton", {
                    Name = "KbBtn",
                    BackgroundColor3 = Theme.SurfaceLight,
                    Size = UDim2.new(0, 72, 0, 24),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Text = KeyName(value),
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.FontMedium,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 3,
                    Parent = Frame
                })
                Util.AddCorner(KbBtn, Theme.CornerSmall)
                local kbStroke = Util.AddStroke(KbBtn, Theme.BorderLight, 1, 0.25)
                Themed(KbBtn, {
                    BackgroundColor3 = function(t) return t.SurfaceLight end,
                    TextColor3 = function(t) return listening and t.Accent or t.TextDim end,
                })
                Themed(kbStroke, { Color = function(t) return listening and t.Accent or t.BorderLight end })

                local entry = { Name = name, Flag = flag }

                local function BeginListen()
                    listening = true
                    KbBtn.Text = "..."
                    Util.TweenFast(kbStroke, {Color = Hyperion.Theme.Accent, Transparency = 0})
                    for _, fn in ipairs(Hyperion.KeybindListeners) do pcall(fn, "listening", entry) end
                end

                KbBtn.MouseButton1Click:Connect(BeginListen)

                Util.Connect(UserInputService.InputBegan, function(input, processed)
                    if listening then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            listening = false
                            value = (input.KeyCode == Enum.KeyCode.Escape) and Enum.KeyCode.Unknown or input.KeyCode
                            if flag then Hyperion.Flags[flag] = value end
                            KbBtn.Text = KeyName(value)
                            Util.TweenFast(kbStroke, {Color = Theme.Border, Transparency = 0.4})
                            Hyperion:_FireKeybindChanged(entry)
                        end
                    else
                        if not processed and input.KeyCode == value and value ~= Enum.KeyCode.Unknown then
                            task.spawn(callback, value)
                        end
                    end
                end)

                if flag then
                    Hyperion.FlagCallbacks[flag] = function(v)
                        value = v
                        Hyperion.Flags[flag] = v
                        KbBtn.Text = KeyName(v)
                        Hyperion:_FireKeybindChanged(entry)
                    end
                end

                local API = {}
                function API:Set(v) value = v; if flag then Hyperion.Flags[flag] = v end; KbBtn.Text = KeyName(v); Hyperion:_FireKeybindChanged(entry) end
                function API:Get() return value end

                entry.GetKey     = function() return value end
                entry.KeyName    = function() return KeyName(value) end
                entry.StartRebind = BeginListen
                Hyperion:_RegisterKeybind(entry)

                return API
            end

            -- ==============================================
            -- COLOR PICKER
            -- ==============================================
            function SectionObj:AddColorPicker(cfg)
                cfg = cfg or {}
                local name     = cfg.Name or "Color"
                local default  = cfg.Default or Theme.Accent
                local hasTrans = cfg.Transparency ~= nil
                local callback = cfg.Callback or function() end
                local flag     = cfg.Flag
                local color    = default
                local alpha    = cfg.Transparency or 0

                if flag then Hyperion.Flags[flag] = color end

                local Frame = Util.Create("Frame", {
                    Name = "Cp_" .. name,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 32),
                    ClipsDescendants = false,
                    ZIndex = 2,
                    Parent = Elements
                })
                _regSearch(name, Frame, "Color", cfg)

                local CpLabel = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -104, 1, 0),
                    Text = name,
                    TextColor3 = Theme.Text,
                    FontFace = Theme.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(CpLabel, { TextColor3 = function(t) return t.Text end })

                local HexTag = Util.Create("TextLabel", {
                    Name = "HexTag",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 64, 1, 0),
                    Position = UDim2.new(1, -32, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Text = "",
                    TextColor3 = Theme.TextMuted,
                    FontFace = Theme.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 2,
                    Parent = Frame
                })
                Themed(HexTag, { TextColor3 = function(t) return t.TextMuted end })

                local Preview = Util.Create("Frame", {
                    Name = "Preview",
                    BackgroundColor3 = color,
                    Size = UDim2.new(0, 26, 0, 26),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Parent = Frame
                })
                Util.AddCorner(Preview, Theme.CornerSmall)
                local PreviewEdge = Util.AddStroke(Preview, Theme.BorderLight, 1, 0.1)
                Themed(PreviewEdge, { Color = function(t) return t.BorderLight end })

                local PreviewGlow = Util.Create("UIStroke", {
                    Color = Theme.Accent,
                    Thickness = 0,
                    Transparency = 0.35,
                    Parent = Preview
                })
                Themed(PreviewGlow, { Color = function(t) return t.Accent end })

                local PreviewBtn = Util.Create("TextButton", {
                    Name = "Hit",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 26, 0, 26),
                    Position = UDim2.new(1, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(1, 0.5),
                    Text = "",
                    AutoButtonColor = false,
                    ZIndex = 4,
                    Parent = Frame
                })

                local function Paint()
                    Preview.BackgroundColor3 = color
                    HexTag.Text = string.format("#%02X%02X%02X",
                        math.floor(color.R * 255 + 0.5),
                        math.floor(color.G * 255 + 0.5),
                        math.floor(color.B * 255 + 0.5))
                end
                Paint()

                local function Emit()
                    if flag then Hyperion.Flags[flag] = color end
                    task.spawn(callback, color, alpha)
                end

                PreviewBtn.MouseEnter:Connect(function()
                    Util.TweenFast(PreviewGlow, { Thickness = 2 })
                end)
                PreviewBtn.MouseLeave:Connect(function()
                    if Util._cp.owner ~= PreviewBtn then
                        Util.TweenFast(PreviewGlow, { Thickness = 0 })
                    end
                end)

                Util.AttachColorSwatch(PreviewBtn,
                    function() return color end,
                    function(c) color = c; Paint(); Emit() end,
                    {
                        Title    = name,
                        Alpha    = hasTrans,
                        GetAlpha = function() return alpha end,
                        SetAlpha = function(a) alpha = a; Emit() end,
                        OnOpen   = function() Util.TweenFast(PreviewGlow, { Thickness = 2 }) end,
                        OnClose  = function() Util.TweenFast(PreviewGlow, { Thickness = 0 }) end,
                    })

                if flag then
                    Hyperion.FlagCallbacks[flag] = function(v)
                        if typeof(v) ~= "Color3" then return end
                        color = v
                        Hyperion.Flags[flag] = v
                        Paint()
                        task.spawn(callback, color, alpha)
                    end
                end

                local API = {}
                function API:Set(c, a)
                    if typeof(c) == "Color3" then color = c end
                    if a then alpha = a end
                    Paint()
                    Emit()
                end
                function API:Get() return color, alpha end
                API.Kind = "color"
                if flag then Hyperion.FlagAPIs[flag] = API end
                return API
            end

            -- ==============================================
            -- LABEL
            -- ==============================================
            function SectionObj:AddLabel(cfg)
                cfg = cfg or {}
                local text = cfg.Text or cfg.Name or "Label"
                local Lbl = Util.Create("TextLabel", {
                    Name = "Label",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 20),
                    Text = text,
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.Font,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2,
                    Parent = Elements
                })
                local API = {}
                function API:Set(t) Lbl.Text = t end
                return API
            end

            function SectionObj:AddCanvas(cfg)
                cfg = cfg or {}
                local Canvas = Util.Create("Frame", {
                    Name = "Canvas",
                    BackgroundColor3 = cfg.Background or Theme.Background,
                    BackgroundTransparency = cfg.Transparency or 0,
                    Size = UDim2.new(1, 0, 0, cfg.Height or 160),
                    ClipsDescendants = cfg.Clip ~= false,
                    ZIndex = 2,
                    Parent = Elements
                })
                Util.AddCorner(Canvas, Theme.CornerSmall)
                if cfg.Background == nil then
                    Themed(Canvas, { BackgroundColor3 = function(t) return t.Background end })
                end
                if cfg.Stroke ~= false then
                    local st = Util.AddStroke(Canvas, Theme.BorderLight, 1, 0.3)
                    Themed(st, { Color = function(t) return t.BorderLight end })
                end
                return Canvas
            end

            -- ==============================================
            -- DIVIDER
            -- ==============================================
            function SectionObj:AddDivider(cfg)
                cfg = cfg or {}
                local title = cfg.Title or cfg.Name or nil
                local DivFrame = Util.Create("Frame", {
                    Name = "Div",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, title and 24 or 10),
                    ZIndex = 2,
                    Parent = Elements
                })
                if title then
                    Util.Create("TextLabel", {
                        Name = "T",
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 0, 14),
                        Text = string.upper(title),
                        TextColor3 = Theme.TextMuted,
                        FontFace = Theme.FontSemiBold,
                        TextSize = 10,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 2,
                        Parent = DivFrame
                    })
                end
                Util.Create("Frame", {
                    Name = "Line",
                    BackgroundColor3 = Theme.Border,
                    BackgroundTransparency = 0.4,
                    Size = UDim2.new(1, 0, 0, 1),
                    Position = UDim2.new(0, 0, 1, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = DivFrame
                })
            end

            -- ==============================================
            -- THEME PICKER
            -- ==============================================
            function SectionObj:AddThemePicker(cfg)
                cfg = cfg or {}
                local callback = cfg.Callback or function() end

                local themeOrder  = {"Purple","Midnight","Rose","StarryNight","Aurora","Nebula","Sunset","Ocean","Crimson","Sakura","Vaporwave","Love","Christmas","Neko"}
                local themeAccents = {
                    Purple      = Color3.fromRGB(140, 80,  220),
                    Midnight    = Color3.fromRGB(80,  120, 255),
                    Rose        = Color3.fromRGB(220, 80,  120),
                    StarryNight = Color3.fromRGB(80,  200, 240),
                    Aurora      = Color3.fromRGB(60,  220, 160),
                    Nebula      = Color3.fromRGB(255, 100, 180),
                    Sunset      = Color3.fromRGB(245, 150, 50),
                    Ocean       = Color3.fromRGB(40,  160, 220),
                    Crimson     = Color3.fromRGB(200, 40,  50),
                    Sakura      = Color3.fromRGB(235, 120, 160),
                    Vaporwave   = Color3.fromRGB(255, 95,  205),
                    Love        = Color3.fromRGB(255, 70,  115),
                    Christmas   = Color3.fromRGB(140, 210, 255),
                    Neko        = Color3.fromRGB(255, 130, 180),
                }

                local currentTheme = "Purple"
                local swatches = {}

                for _, name in ipairs(themeOrder) do
                    local accent = themeAccents[name]

                    local Row = Util.Create("TextButton", {
                        Name = "Theme_" .. name,
                        BackgroundColor3 = Theme.SurfaceLight,
                        BackgroundTransparency = 0.4,
                        Size = UDim2.new(1, 0, 0, 32),
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        ZIndex = 2,
                        Parent = Elements,
                    })
                    Util.AddCorner(Row, Theme.CornerSmall)
                    local RowStroke = Util.AddStroke(Row, Theme.Border, 1, 0.5)

                    -- Color dot
                    local Dot = Util.Create("Frame", {
                        BackgroundColor3 = accent,
                        Size = UDim2.new(0, 14, 0, 14),
                        Position = UDim2.new(0, 8, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        BorderSizePixel = 0,
                        ZIndex = 3,
                        Parent = Row,
                    })
                    Util.AddCorner(Dot, UDim.new(1, 0))
                    Util.AddStroke(Dot, accent, 1, 0.55)

                    Util.Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, -50, 1, 0),
                        Position = UDim2.new(0, 30, 0, 0),
                        Text = name,
                        TextColor3 = Theme.Text,
                        FontFace = Theme.FontMedium,
                        TextSize = 13,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 3,
                        Parent = Row,
                    })

                    local Check = Util.Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 20, 1, 0),
                        Position = UDim2.new(1, -24, 0, 0),
                        Text = "✓",
                        TextColor3 = accent,
                        FontFace = Theme.FontBold,
                        TextSize = 13,
                        TextTransparency = (name == currentTheme) and 0 or 1,
                        ZIndex = 3,
                        Parent = Row,
                    })

                    Themed(Row, {
                        BackgroundColor3 = function(t)
                            return (currentTheme == name) and t.SurfaceActive or t.SurfaceLight
                        end
                    })
                    Themed(RowStroke, {
                        Color = function(t)
                            return (currentTheme == name) and accent or t.Border
                        end
                    })
                    for _, child in ipairs(Row:GetChildren()) do
                        if child:IsA("TextLabel") and child ~= Check then
                            Themed(child, { TextColor3 = function(t) return t.Text end })
                        end
                    end
                    Themed(Check, { TextColor3 = function(_) return accent end })

                    
                    swatches[name] = {Row = Row, Stroke = RowStroke, Check = Check, Accent = accent}

                    Row.MouseEnter:Connect(function()
                        if currentTheme ~= name then
                            Util.TweenFast(Row, {BackgroundTransparency = 0.2})
                        end
                    end)
                    Row.MouseLeave:Connect(function()
                        if currentTheme ~= name then
                            Util.TweenFast(Row, {BackgroundTransparency = 0.4})
                        end
                    end)

                    Row.MouseButton1Click:Connect(function()
                        if currentTheme == name then return end
                        -- Deselect previous
                        local prev = swatches[currentTheme]
                        if prev then
                            Util.TweenFast(prev.Row, {BackgroundTransparency = 0.4})
                            Util.TweenFast(prev.Stroke, {Color = Theme.Border, Transparency = 0.5})
                            Util.TweenFast(prev.Check, {TextTransparency = 1})
                        end
                        currentTheme = name
                        Hyperion:SetTheme(name)
                        -- Select new
                        Util.TweenFast(Row, {BackgroundTransparency = 0.1})
                        Util.TweenFast(RowStroke, {Color = accent, Transparency = 0.3})
                        Util.TweenFast(Check, {TextTransparency = 0})
                        -- Refresh config list rows
                        RefreshConfigList()
                        Hyperion:Notify({
                            Title   = "Theme",
                            Content = name .. " theme applied.",
                            Type    = "Info",
                            Duration = 2,
                        })
                        callback(name)
                    end)
                end

                -- Highlight default
                local init = swatches["Purple"]
                if init then
                    Util.TweenFast(init.Row, {BackgroundTransparency = 0.1})
                    Util.TweenFast(init.Stroke, {Color = themeAccents["Purple"], Transparency = 0.3})
                end

                -- ── Transparency slider ───────────────────────────────────
                local _transDivider = Util.Create("Frame", {
                    BackgroundColor3 = Theme.Border,
                    BackgroundTransparency = 0.4,
                    Size = UDim2.new(1, 0, 0, 1),
                    BorderSizePixel = 0, ZIndex = 2,
                    Parent = Elements,
                })
                Themed(_transDivider, { BackgroundColor3 = function(t) return t.Border end })

                Util.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = "UI TRANSPARENCY",
                    TextColor3 = Theme.TextMuted,
                    FontFace = Theme.FontSemiBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2, Parent = Elements,
                })

                -- Slider track
                local transValue = 0
                local TransTrack = Util.Create("Frame", {
                    BackgroundColor3 = Theme.SliderBg,
                    Size = UDim2.new(1, 0, 0, 6),
                    ZIndex = 2, Parent = Elements,
                })
                Util.AddCorner(TransTrack, UDim.new(1, 0))
                Themed(TransTrack, { BackgroundColor3 = function(t) return t.SliderBg end })

                local TransFill = Util.Create("Frame", {
                    BackgroundColor3 = Theme.Accent,
                    Size = UDim2.new(0, 0, 1, 0),
                    ZIndex = 3, Parent = TransTrack,
                })
                Util.AddCorner(TransFill, UDim.new(1, 0))
                Themed(TransFill, { BackgroundColor3 = function(t) return t.Accent end })

                local TransKnob = Util.Create("Frame", {
                    BackgroundColor3 = Color3.new(1,1,1),
                    Size = UDim2.new(0, 12, 0, 12),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    ZIndex = 4, Parent = TransTrack,
                })
                Util.AddCorner(TransKnob, UDim.new(1, 0))

                local TransHit = Util.Create("TextButton", {
                    BackgroundTransparency = 1, Text = "",
                    Size = UDim2.new(1, 10, 0, 20),
                    Position = UDim2.new(0, -5, 0.5, 0),
                    AnchorPoint = Vector2.new(0, 0.5),
                    ZIndex = 5, Parent = TransTrack,
                })

                local transDragging = false
                TransHit.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        transDragging = true
                    end
                end)
                TransHit.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        transDragging = false
                    end
                end)
                table.insert(InputPool.SliderCallbacks, function(input)
                    if transDragging then
                        local ratio = math.clamp(
                            (input.Position.X - TransTrack.AbsolutePosition.X) / math.max(TransTrack.AbsoluteSize.X, 1),
                            0, 1
                        )
                        transValue = math.floor(ratio * 95 + 0.5) / 100
                        TransFill.Size = UDim2.new(ratio, 0, 1, 0)
                        TransKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
                        WindowObj:SetTransparency(transValue)
                    end
                end)

                -- ── Background image textbox ──────────────────────────────
                Util.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    Text = "BACKGROUND IMAGE",
                    TextColor3 = Theme.TextMuted,
                    FontFace = Theme.FontSemiBold,
                    TextSize = 10,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 2, Parent = Elements,
                })

                local BgRow = Util.Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 28),
                    ZIndex = 2, Parent = Elements,
                })

                local BgBox = Util.Create("TextBox", {
                    BackgroundColor3 = Theme.InputBg,
                    Size = UDim2.new(1, -36, 1, 0),
                    Text = "",
                    PlaceholderText = "rbxassetid://...",
                    TextColor3 = Theme.Text,
                    PlaceholderColor3 = Theme.TextMuted,
                    FontFace = Theme.Font,
                    TextSize = 11,
                    ClearTextOnFocus = false,
                    BorderSizePixel = 0,
                    ZIndex = 3, Parent = BgRow,
                })
                Util.AddCorner(BgBox, Theme.CornerSmall)
                Util.AddStroke(BgBox, Theme.Border, 1, 0.3)
                Themed(BgBox, {
                    BackgroundColor3  = function(t) return t.InputBg end,
                    TextColor3        = function(t) return t.Text end,
                    PlaceholderColor3 = function(t) return t.TextMuted end,
                })

                local BgApplyBtn = Util.Create("TextButton", {
                    BackgroundColor3 = Theme.SurfaceLight,
                    Size = UDim2.new(0, 28, 1, 0),
                    Position = UDim2.new(1, -28, 0, 0),
                    Text = "→",
                    TextColor3 = Theme.Accent,
                    FontFace = Theme.FontBold,
                    TextSize = 14,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    ZIndex = 3, Parent = BgRow,
                })
                Util.AddCorner(BgApplyBtn, Theme.CornerSmall)
                Util.AddStroke(BgApplyBtn, Theme.Border, 1, 0.4)
                Themed(BgApplyBtn, {
                    BackgroundColor3 = function(t) return t.SurfaceLight end,
                    TextColor3       = function(t) return t.Accent end,
                })

                BgApplyBtn.MouseButton1Click:Connect(function()
                    local id = BgBox.Text ~= "" and BgBox.Text or nil
                    WindowObj:SetBackground(id)
                end)

                -- Clear bg button
                local BgClearBtn = Util.Create("TextButton", {
                    BackgroundColor3 = Theme.SurfaceLight,
                    BackgroundTransparency = 0.4,
                    Size = UDim2.new(1, 0, 0, 24),
                    Text = "Clear Background",
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.Font,
                    TextSize = 11,
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    ZIndex = 2, Parent = Elements,
                })
                Util.AddCorner(BgClearBtn, Theme.CornerSmall)
                Themed(BgClearBtn, {
                    BackgroundColor3 = function(t) return t.SurfaceLight end,
                    TextColor3       = function(t) return t.TextDim end,
                })
                BgClearBtn.MouseEnter:Connect(function()
                    Util.TweenFast(BgClearBtn, {BackgroundTransparency = 0.1})
                end)
                BgClearBtn.MouseLeave:Connect(function()
                    Util.TweenFast(BgClearBtn, {BackgroundTransparency = 0.4})
                end)
                BgClearBtn.MouseButton1Click:Connect(function()
                    BgBox.Text = ""
                    WindowObj:SetBackground(nil)
                end)
            end

            -- ==============================================
            -- INFOBOX
            -- ==============================================
            function SectionObj:AddInfobox(cfg)
                cfg = cfg or {}
                local title   = cfg.Title or cfg.Name or "Info"
                local content = cfg.Text  or cfg.Content or ""
                local icon    = cfg.Icon
                local iType   = cfg.Type or "Info"

                local accentMap = {
                    Info    = Theme.Info,
                    Success = Theme.Success,
                    Warning = Theme.Warning,
                    Error   = Theme.Error,
                }
                local accent = accentMap[iType] or Theme.Accent

                local Card = Util.Create("Frame", {
                    Name = "Infobox",
                    BackgroundColor3 = Theme.Surface,
                    BackgroundTransparency = 0.25,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    Parent = Elements,
                })
                Util.AddCorner(Card, Theme.CornerSmall)
                local CardStroke = Util.AddStroke(Card, accent, 1, 0.5)
                Themed(Card, { BackgroundColor3 = function(t) return t.Surface end })

                -- Left accent stripe
                local Stripe = Util.Create("Frame", {
                    BackgroundColor3 = accent,
                    BackgroundTransparency = 0.3,
                    Size = UDim2.new(0, 2, 1, 0),
                    BorderSizePixel = 0,
                    ZIndex = 3,
                    Parent = Card,
                })
                Util.AddCorner(Stripe, UDim.new(1, 0))

                -- Inner padded content
                local Inner = Util.Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -10, 0, 0),
                    Position = UDim2.new(0, 10, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 3,
                    Parent = Card,
                })
                Util.AddList(Inner, Enum.FillDirection.Vertical, 3)
                Util.AddPadding(Inner, 7, 6, 7, 4)

                -- Title row
                local TitleRow = Util.Create("Frame", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 14),
                    ZIndex = 3,
                    Parent = Inner,
                })

                local iconOffset = 0
                if icon then
                    Util.Create("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0, 12, 0, 12),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        AnchorPoint = Vector2.new(0, 0.5),
                        Image = icon,
                        ImageColor3 = accent,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 4,
                        Parent = TitleRow,
                    })
                    iconOffset = 16
                end

                local TitleLbl = Util.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -iconOffset, 1, 0),
                    Position = UDim2.new(0, iconOffset, 0, 0),
                    Text = title,
                    TextColor3 = accent,
                    FontFace = Theme.FontSemiBold,
                    TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 4,
                    Parent = TitleRow,
                })
                Themed(TitleLbl, { FontFace = function(t) return t.FontSemiBold end })

                local ContentLbl = Util.Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Text = content,
                    TextColor3 = Theme.TextDim,
                    FontFace = Theme.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    ZIndex = 4,
                    Parent = Inner,
                })
                Themed(ContentLbl, {
                    TextColor3 = function(t) return t.TextDim end,
                    FontFace   = function(t) return t.Font end,
                })

                local API = {}

                function API:SetTitle(t)
                    TitleLbl.Text = tostring(t)
                end

                function API:SetContent(t)
                    ContentLbl.Text = tostring(t)
                end

                function API:SetType(newType)
                    local na = (newType == "Info"    and Theme.Info)
                            or (newType == "Success" and Theme.Success)
                            or (newType == "Warning" and Theme.Warning)
                            or (newType == "Error"   and Theme.Error)
                            or Theme.Accent
                    Util.TweenFast(CardStroke, { Color = na, Transparency = 0.5 })
                    Util.TweenFast(Stripe, { BackgroundColor3 = na })
                    Util.TweenFast(TitleLbl, { TextColor3 = na })
                end

                return API
            end

            return SectionObj
        end -- AddSection

        return TabObj
    end -- AddTab

    table.insert(Hyperion.Windows, WindowObj)

    -- Schedule config autoload: if enabled, restore saved flags after the
    -- calling script finishes building tabs/sections/elements. We defer twice
    -- (RunService.Heartbeat + task.defer) so every element's registered
    -- FlagCallback exists before Config.Load fires them.
    if windowConfig.ConfigSystem then
        task.defer(function()
            task.wait(0.05) -- small delay lets user's build code finish
            if Hyperion._configEnabled == false then return end
            -- Prefer the name written by the autoload toggle in the config panel
            local ok, dat = pcall(_rawReadfile, "Hyperion/autoload.dat")
            local loadName = (ok and dat and dat ~= "") and dat or
                             (windowConfig.ConfigAutoLoad and windowConfig.AutoLoadName or nil)
            if loadName and _rawIsfile("Hyperion/Configs/" .. loadName .. ".json") then
                Config.Load(loadName, Hyperion.Flags, Hyperion.FlagCallbacks)
            end
        end)
    end

    -- ================================================================
    -- THEMES GALLERY  (build into a section: Window:AddThemesGallery(sec))
    -- ================================================================
    function WindowObj:AddThemesGallery(sec)
        local cv = sec:AddCanvas({ Height = 40, Transparency = 1, Stroke = false })
        cv.AutomaticSize    = Enum.AutomaticSize.Y
        cv.Size             = UDim2.new(1, 0, 0, 0)
        cv.ClipsDescendants = false
        Util.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 9), Parent = cv,
        })

        local CATEGORIES = {
            { "Signature",   { "Hyperion", "Purple", "Midnight", "Nebula", "Dracula" } },
            { "Cool",        { "Ocean", "StarryNight", "Aurora", "Nord", "Mint", "Christmas" } },
            { "Warm",        { "Sunset", "Crimson", "Royal Gold", "Coffee", "Halloween" } },
            { "Pink & Soft", { "Rose", "Sakura", "Bunny", "Lavender", "Strawberry Milk", "Neko", "Love" } },
            { "Neon",        { "Vaporwave", "Matcha" } },
        }

        local cards = {}
        local function paint(active)
            for n, c in pairs(cards) do
                local sel = (n == active)
                c.stroke.Color        = sel and c.accent or Hyperion.Theme.BorderLight
                c.stroke.Thickness    = sel and 1.6 or 1
                c.stroke.Transparency = sel and 0 or 0.5
                c.check.TextTransparency = sel and 0 or 1
            end
        end

        local order = 0
        for _, cat in ipairs(CATEGORIES) do
            order = order + 1
            local block = Util.Create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, Parent = cv,
            })
            Util.Create("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5), Parent = block,
            })
            local ch = Util.Create("TextLabel", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 12), Text = string.upper(cat[1]),
                TextColor3 = Theme.TextMuted, FontFace = Theme.FontSemiBold, TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0, Parent = block,
            })
            Themed(ch, { TextColor3 = function(t) return t.TextMuted end })
            local grid = Util.Create("Frame", {
                BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, Parent = block,
            })
            Util.Create("UIGridLayout", {
                CellSize = UDim2.new(0, 94, 0, 50), CellPadding = UDim2.new(0, 6, 0, 6),
                SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Parent = grid,
            })

            for _, name in ipairs(cat[2]) do
                local preset = Hyperion.Themes[name]
                if preset then
                    local ac  = preset.Accent or Color3.fromRGB(150, 110, 255)
                    local acL = preset.AccentLight or ac
                    local card = Util.Create("TextButton", {
                        BackgroundColor3 = preset.Background or Theme.Background, Text = "",
                        AutoButtonColor = false, BorderSizePixel = 0, Parent = grid,
                    })
                    Util.AddCorner(card, UDim.new(0, 6))
                    local st = Util.AddStroke(card, Theme.BorderLight, 1, 0.5)
                    -- accent "titlebar" (mini-window look) with a soft gradient
                    local bar = Util.Create("Frame", {
                        BackgroundColor3 = ac, Size = UDim2.new(1, -12, 0, 13),
                        Position = UDim2.new(0, 6, 0, 6), BorderSizePixel = 0, Parent = card,
                    })
                    Util.AddCorner(bar, UDim.new(0, 3))
                    Util.Create("UIGradient", { Color = ColorSequence.new(ac, acL), Rotation = 12, Parent = bar })
                    -- content-line hint in the theme's surface color
                    local chip = Util.Create("Frame", {
                        BackgroundColor3 = preset.SurfaceLight or preset.Surface or Theme.Surface,
                        Size = UDim2.new(0.55, 0, 0, 4), Position = UDim2.new(0, 6, 0, 23),
                        BorderSizePixel = 0, Parent = card,
                    })
                    Util.AddCorner(chip, UDim.new(0, 2))
                    Util.Create("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 13),
                        Position = UDim2.new(0, 6, 1, -17), Text = name,
                        TextColor3 = preset.Text or Theme.Text, FontFace = Theme.FontMedium, TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = card,
                    })
                    local check = Util.Create("TextLabel", {
                        BackgroundTransparency = 1, Size = UDim2.new(0, 13, 0, 13),
                        Position = UDim2.new(1, -15, 1, -17), Text = "✓", TextColor3 = ac,
                        FontFace = Theme.FontBold, TextSize = 12, TextTransparency = 1, Parent = card,
                    })
                    cards[name] = { stroke = st, check = check, accent = ac }
                    card.MouseEnter:Connect(function()
                        if Hyperion._currentThemeName ~= name then Util.TweenFast(st, { Transparency = 0.05, Color = ac }) end
                    end)
                    card.MouseLeave:Connect(function()
                        if Hyperion._currentThemeName ~= name then Util.TweenFast(st, { Transparency = 0.5, Color = Hyperion.Theme.BorderLight }) end
                    end)
                    card.MouseButton1Click:Connect(function()
                        Hyperion:SetTheme(name)
                        paint(name)
                        Hyperion:Notify({ Title = "Theme", Content = name .. " applied.", Type = "Info", Duration = 2 })
                    end)
                end
            end
        end

        paint(Hyperion._currentThemeName or "Hyperion")
        pcall(function() Hyperion:OnThemeChanged(function() paint(Hyperion._currentThemeName) end) end)
        return sec
    end

    return WindowObj
end -- CreateWindow

----------------------------------------------------------------
-- WATERMARK OVERLAY
----------------------------------------------------------------
--[[
    Hyperion:CreateWatermark({
        Title    = "Hyperion",       -- script name shown on left
        Game     = "The Armory",     -- game name (optional)
        Position = UDim2.new(...),   -- default: top-right
        Keybind  = Enum.KeyCode.X,   -- hide/show keybind (optional)
    })
    Returns a WatermarkAPI with :SetTitle(s), :SetGame(s), :SetVisible(bool), :Destroy()
--]]
function Hyperion:CreateWatermark(cfg)
    cfg = cfg or {}
    local wmTitle   = cfg.Title or "Hyperion"
    local wmGame    = cfg.Game or game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown"
    local wmExpires = cfg.Expires or nil
    local wmKeybind = cfg.Keybind or nil
    local Theme     = Hyperion.Theme

    -- Find or create a ScreenGui to host the watermark
    local WmGui = Util.Create("ScreenGui", {
        Name           = _SafeGuiName(),
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder   = 0,
        IgnoreGuiInset = false,
    })
    pcall(protect_gui, WmGui)
    WmGui.Parent = CoreGui

    local visible = true

    -- Outer pill frame
    local WmFrame = Util.Create("Frame", {
        Name              = "Watermark",
        BackgroundColor3  = Theme.Surface,
        BackgroundTransparency = 0.08,
        AnchorPoint       = Vector2.new(1, 0),
        Position          = cfg.Position or UDim2.new(1, -16, 0, 16),
        Size              = UDim2.new(0, 10, 0, 28), -- auto-expands
        AutomaticSize     = Enum.AutomaticSize.X,
        BorderSizePixel   = 0,
        ZIndex            = 10,
        Parent            = WmGui,
    })
    Util.AddCorner(WmFrame, UDim.new(0, 7))
    local WmStroke = Util.AddStroke(WmFrame, Theme.BorderLight, 1, 0.15)

    -- Subtle top gradient accent
    local WmGrad = Util.Create("Frame", {
        Name             = "Grad",
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 0.82,
        Size             = UDim2.new(1, 0, 0, 1),
        BorderSizePixel  = 0,
        ZIndex           = 11,
        Parent           = WmFrame,
    })

    -- Layout
    local WmRow = Util.Create("Frame", {
        Name              = "Row",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        ZIndex            = 11,
        Parent            = WmFrame,
    })
    Util.AddList(WmRow, Enum.FillDirection.Horizontal, 0, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    Util.AddPadding(WmRow, 0, 10, 0, 10)

    -- Accent dot
    local WmDot = Util.Create("Frame", {
        Name             = "Dot",
        BackgroundColor3 = Theme.Accent,
        Size             = UDim2.new(0, 5, 0, 5),
        LayoutOrder      = 1,
        BorderSizePixel  = 0,
        ZIndex           = 12,
        Parent           = WmRow,
    })
    Util.AddCorner(WmDot, UDim.new(1, 0))

    local fpsColorOverride = nil
    Hyperion:OnThemeChanged(function(t)
        if not WmFrame or not WmFrame.Parent then return end
        WmFrame.BackgroundColor3 = t.Surface
        WmStroke.Color = t.BorderLight
        WmGrad.BackgroundColor3 = t.Accent
        WmDot.BackgroundColor3 = t.Accent
        WmTitleLbl.TextColor3 = t.Text
        WmSep1.TextColor3 = t.TextMuted
        WmGameLbl.TextColor3 = t.TextDim
        local sep2 = WmRow:FindFirstChild("Sep2")
        if sep2 then
            sep2.TextColor3 = t.TextMuted
        end
        if fpsColorOverride then
            WmFpsLbl.TextColor3 = fpsColorOverride
        else
            WmFpsLbl.TextColor3 = t.Accent
        end
        if WmExpiresLbl then
            WmExpiresLbl.TextColor3 = t.Accent
        end
        local sep3 = WmRow:FindFirstChild("Sep3")
        if sep3 then sep3.TextColor3 = t.TextMuted end
    end)

    -- Spacer after dot
    Util.Create("Frame", {
        BackgroundTransparency = 1,
        Size        = UDim2.new(0, 6, 0, 1),
        LayoutOrder = 2,
        Parent      = WmRow,
    })

    -- Title label
    local WmTitleLbl = Util.Create("TextLabel", {
        Name              = "Title",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        Text              = wmTitle,
        TextColor3        = Theme.Text,
        FontFace          = Theme.FontSemiBold,
        TextSize          = 12,
        TextXAlignment    = Enum.TextXAlignment.Left,
        LayoutOrder       = 3,
        ZIndex            = 12,
        Parent            = WmRow,
    })

    -- Separator " | "
    local WmSep1 = Util.Create("TextLabel", {
        Name              = "Sep1",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        Text              = "  |  ",
        TextColor3        = Theme.TextMuted,
        FontFace          = Theme.Font,
        TextSize          = 12,
        LayoutOrder       = 4,
        ZIndex            = 12,
        Parent            = WmRow,
    })

    -- Game label
    local WmGameLbl = Util.Create("TextLabel", {
        Name              = "Game",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        Text              = wmGame,
        TextColor3        = Theme.TextDim,
        FontFace          = Theme.Font,
        TextSize          = 12,
        TextXAlignment    = Enum.TextXAlignment.Left,
        LayoutOrder       = 5,
        ZIndex            = 12,
        Parent            = WmRow,
    })

    -- Separator
    Util.Create("TextLabel", {
        Name              = "Sep2",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        Text              = "  |  ",
        TextColor3        = Theme.TextMuted,
        FontFace          = Theme.Font,
        TextSize          = 12,
        LayoutOrder       = 6,
        ZIndex            = 12,
        Parent            = WmRow,
    })

    -- FPS label
    local WmFpsLbl = Util.Create("TextLabel", {
        Name              = "FPS",
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 0, 1, 0),
        AutomaticSize     = Enum.AutomaticSize.X,
        Text              = "-- fps",
        TextColor3        = Theme.Accent,
        FontFace          = Theme.FontMedium,
        TextSize          = 12,
        TextXAlignment    = Enum.TextXAlignment.Left,
        LayoutOrder       = 7,
        ZIndex            = 12,
        Parent            = WmRow,
    })

    -- Optional Expires label
    local WmExpiresLbl = nil
    if wmExpires then
        Util.Create("TextLabel", {
            Name              = "Sep3",
            BackgroundTransparency = 1,
            Size              = UDim2.new(0, 0, 1, 0),
            AutomaticSize     = Enum.AutomaticSize.X,
            Text              = "  |  ",
            TextColor3        = Theme.TextMuted,
            FontFace          = Theme.Font,
            TextSize          = 12,
            LayoutOrder       = 8,
            ZIndex            = 12,
            Parent            = WmRow,
        })
        WmExpiresLbl = Util.Create("TextLabel", {
            Name              = "Expires",
            BackgroundTransparency = 1,
            Size              = UDim2.new(0, 0, 1, 0),
            AutomaticSize     = Enum.AutomaticSize.X,
            Text              = "Expires: " .. wmExpires,
            TextColor3        = Theme.Accent,
            FontFace          = Theme.FontMedium,
            TextSize          = 12,
            TextXAlignment    = Enum.TextXAlignment.Left,
            LayoutOrder       = 9,
            ZIndex            = 12,
            Parent            = WmRow,
        })
    end

    -- FPS counter using RunService
    local fpsBuffer = {}
    local fpsConn = RunService.RenderStepped:Connect(function(dt)
        table.insert(fpsBuffer, dt)
        if #fpsBuffer > 15 then table.remove(fpsBuffer, 1) end
        local avg = 0
        for _, v in ipairs(fpsBuffer) do avg = avg + v end
        avg = avg / #fpsBuffer
        local fps = math.round(1 / math.max(avg, 0.001))
        local t = Hyperion.Theme
        local color = fps >= 55 and t.Success or (fps >= 30 and t.Warning or t.Error)
        fpsColorOverride = color
        WmFpsLbl.Text = fps .. " fps"
        WmFpsLbl.TextColor3 = color
    end)
    table.insert(Hyperion.Connections, fpsConn)

    -- Dragging
    local wmDrag, wmDragStart, wmStartPos = false, Vector3.new(), UDim2.new()
    WmFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            wmDrag = true
            wmDragStart = input.Position
            wmStartPos  = WmFrame.Position
        end
    end)
    WmFrame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            wmDrag = false
        end
    end)
    Util.Connect(UserInputService.InputChanged, function(input)
        if wmDrag and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - wmDragStart
            WmFrame.Position = UDim2.new(
                wmStartPos.X.Scale,
                wmStartPos.X.Offset + delta.X,
                wmStartPos.Y.Scale,
                wmStartPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Optional keybind toggle
    if wmKeybind then
        Util.Connect(UserInputService.InputBegan, function(input, gp)
            if gp then return end
            if input.KeyCode == wmKeybind then
                visible = not visible
                WmFrame.Visible = visible
            end
        end)
    end

    -- Public API
    local WatermarkAPI = {}

    function WatermarkAPI:SetTitle(t)
        WmTitleLbl.Text = t
    end

    function WatermarkAPI:SetGame(t)
        WmGameLbl.Text = t
    end

    function WatermarkAPI:SetVisible(v)
        visible = v
        WmFrame.Visible = v
    end

    function WatermarkAPI:Destroy()
        fpsConn:Disconnect()
        WmGui:Destroy()
    end

    return WatermarkAPI
end

----------------------------------------------------------------

return Hyperion
