
local UILibrary = {}

function UILibrary:Create()
    cloneref = cloneref or function(i) return i end
    protect_gui = protect_gui or function() end
    getgenv = getgenv or function() return _G end
    getcustomasset = getcustomasset or getsynasset
    
cloneref = cloneref or function(i) return i end
protect_gui = protect_gui or function() end
getgenv = getgenv or function() return _G end
getcustomasset = getcustomasset or getsynasset

local Players = game:GetService("Players")
local UIS     = game:GetService("UserInputService")
local TS      = game:GetService("TweenService")
local RS      = game:GetService("RunService")

local player = Players.LocalPlayer
local pgui   = player:WaitForChild("PlayerGui")

local C = {
    bg          = Color3.fromRGB(10, 10, 18),
    bg2         = Color3.fromRGB(14, 14, 24),
    bg3         = Color3.fromRGB(20, 20, 32),
    surface     = Color3.fromRGB(24, 24, 36),
    surfHover   = Color3.fromRGB(30, 30, 45),
    surfActive  = Color3.fromRGB(38, 38, 55),
    accent      = Color3.fromRGB(100, 100, 255),
    accentLight = Color3.fromRGB(140, 140, 255),
    accentDark  = Color3.fromRGB(80, 80, 200),
    accentSoft  = Color3.fromRGB(120, 120, 240),
    accent2     = Color3.fromRGB(147, 51, 234),
    accent2Dark = Color3.fromRGB(120, 40, 190),
    gradEnd     = Color3.fromRGB(147, 51, 234),
    text        = Color3.fromRGB(255, 255, 255),
    textSec     = Color3.fromRGB(200, 200, 220),
    textDim     = Color3.fromRGB(140, 140, 160),
    border      = Color3.fromRGB(40, 40, 60),
    borderLight = Color3.fromRGB(60, 60, 85),
    toggleOff   = Color3.fromRGB(24, 24, 36),
    toggleOn    = Color3.fromRGB(100, 100, 255),
    sliderBg    = Color3.fromRGB(20, 20, 32),
    green       = Color3.fromRGB(100, 255, 150),
    rowHover    = Color3.fromRGB(18, 18, 28),
}

local LucideFont = Font.new(
    'rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json',
    Enum.FontWeight.Bold,
    Enum.FontStyle.Normal
)

local Icons = {
    ["crosshairs"] = "crosshairs",
    ["shield-check"] = "shield-check",
    ["person"] = "person",
    ["globe-detailed"] = "globe-detailed",
    ["gear"] = "gear",
    ["file-box"] = "file-box",
    ["three-sliders-horizontal"] = "three-sliders-horizontal",
    ["chevron-down"] = "chevron-small-down",
    ["chevron-right"] = "chevron-small-right",
    ["check"] = "check",
    ["x"] = "x",
    ["search"] = "magnifying-glass",
}

local panelOpen    = false
local activeTab    = 0
local dragging     = false
local dragStart, frameStart
local activeSlider = nil
local openDropdown = nil
local listeningBind = nil
local kbEntries = {}
local searchItems = {}
local refreshKB
local switchTab
local openColorPicker

local tabs = {}

local function new(cls, props)
    local inst = Instance.new(cls)
    for k, v in pairs(props) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

local function tw(inst, goal, dur, style, dir)
    local t = TS:Create(inst,
        TweenInfo.new(dur or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out),
        goal)
    t:Play()
    return t
end

local closeColorPicker

local function closeActiveDropdown()
    if openDropdown then
        openDropdown.close()
        openDropdown = nil
    end
    if closeColorPicker then closeColorPicker() end
end

UIS.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    if not openDropdown then return end

    local pos = input.Position
    local function isInside(frame)
        if not frame or not frame.Visible then return false end
        local ap = frame.AbsolutePosition
        local sz = frame.AbsoluteSize
        return pos.X >= ap.X and pos.X <= ap.X + sz.X
            and pos.Y >= ap.Y and pos.Y <= ap.Y + sz.Y
    end

    if openDropdown.frame and isInside(openDropdown.frame) then return end
    if openDropdown.btn and isInside(openDropdown.btn) then return end

    openDropdown.close()
    openDropdown = nil
end)

local function kname(k)
    local m = {
        [Enum.KeyCode.LeftShift] = "LSHIFT", [Enum.KeyCode.RightShift] = "RSHIFT",
        [Enum.KeyCode.LeftControl] = "LCTRL", [Enum.KeyCode.RightControl] = "RCTRL",
        [Enum.KeyCode.LeftAlt] = "LALT", [Enum.KeyCode.RightAlt] = "RALT",
        [Enum.KeyCode.CapsLock] = "CAPS", [Enum.KeyCode.Space] = "SPACE",
        [Enum.KeyCode.Tab] = "TAB", [Enum.KeyCode.Backspace] = "BKSP",
    }
    if typeof(k) == "EnumItem" then return m[k] or k.Name end
    return "—"
end

local function hexColor(c3)
    return string.format("%02x%02x%02x",
        math.floor(c3.R * 255), math.floor(c3.G * 255), math.floor(c3.B * 255))
end

local guiRoot = pgui
local useHighZIndex = true
pcall(function()
    if gethui then
        guiRoot = gethui()
    end
end)

pcall(function()
    for _, g in pairs(guiRoot:GetChildren()) do
        if g.Name == "NixwareUI" or g.Name == "NixwareWM" or g.Name == "NixwareMB" then
            pcall(function() g:Destroy() end)
        end
    end
end)
for _, g in pairs(pgui:GetChildren()) do
    if g.Name == "NixwareUI" or g.Name == "NixwareWM" or g.Name == "NixwareMB" then
        pcall(function() g:Destroy() end)
    end
end

local gui = Instance.new("ScreenGui")
gui.Name = "NixwareUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
pcall(protect_gui, gui)
gui.Parent = guiRoot

local preLoadBg = new("Frame", {
    Name = "PreLoadBg", Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(8, 8, 10),
    ZIndex = 99, Parent = gui,
})
local preLoadImg = new("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Image = bgPatternImage,
    ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 99, Parent = preLoadBg,
})

local loadScr = new("Frame", {
    Name = "LoadScreen", Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(8, 8, 10),
    BackgroundTransparency = 0,
    ZIndex = 100, Parent = gui,
})

local loadBgGradient = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.98,
    BorderSizePixel = 0, ZIndex = 100,
    Parent = loadScr,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, C.accent),
    }),
    Rotation = 45,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0.9),
    }),
    Parent = loadBgGradient,
})

local ldLogoImg = new("ImageLabel", {
    Size = UDim2.new(0, 80, 0, 80),
    Position = UDim2.new(0.5, -40, 0.5, -100),
    BackgroundTransparency = 1,
    Image = logoImage,
    ImageTransparency = 1,
    ZIndex = 101, Parent = loadScr,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = ldLogoImg })

local loadLogoStroke = new("UIStroke", {
    Color = C.accent,
    Thickness = 2,
    Transparency = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = ldLogoImg,
})
local loadLogoGradient = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 0)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
    }),
    Rotation = 0,
    Parent = loadLogoStroke,
})

local ldLogo = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 100),
    Position = UDim2.new(0, 0, 0.5, -10),
    BackgroundTransparency = 1, Text = "NIXWARE",
    Font = Enum.Font.GothamBold, TextSize = 80,
    TextColor3 = Color3.new(1, 1, 1), TextTransparency = 1,
    ZIndex = 101, Parent = loadScr,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
    }),
    Parent = ldLogo,
})
local ldLogoScale = new("UIScale", { Scale = 0.65, Parent = ldLogo })

local ldLine = new("Frame", {
    Size = UDim2.new(0, 200, 0, 2),
    Position = UDim2.new(0.5, -100, 0.5, 64),
    BackgroundColor3 = C.accent,
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ZIndex = 101, Parent = loadScr,
})
new("UICorner", { CornerRadius = UDim.new(0, 1), Parent = ldLine })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.5, C.accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
    }),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 0.9),
    }),
    Parent = ldLine,
})

local ldSub = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 18),
    Position = UDim2.new(0, 0, 0.5, 66),
    BackgroundTransparency = 1, Text = "initializing...",
    Font = Enum.Font.Gotham, TextSize = 11,
    TextColor3 = C.textDim, TextTransparency = 1,
    ZIndex = 101, Parent = loadScr,
})

local ldBarBg = new("Frame", {
    Size = UDim2.new(0, 220, 0, 4),
    Position = UDim2.new(0.5, -110, 0.5, 96),
    BackgroundColor3 = Color3.fromRGB(20, 20, 25), BackgroundTransparency = 1,
    BorderSizePixel = 0, ZIndex = 101, Parent = loadScr,
})
new("UICorner", { CornerRadius = UDim.new(0, 2), Parent = ldBarBg })
new("UIStroke", {
    Color = C.accent,
    Thickness = 1,
    Transparency = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = ldBarBg,
})

local ldFill = new("Frame", {
    Size = UDim2.new(0, 0, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 102, Parent = ldBarBg,
})
new("UICorner", { CornerRadius = UDim.new(0, 2), Parent = ldFill })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.5, C.accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 50)),
    }),
    Parent = ldFill,
})

local ldVer = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 0.5, 108),
    BackgroundTransparency = 1, Text = "Beta",
    Font = Enum.Font.Gotham, TextSize = 9,
    TextColor3 = C.textDim, TextTransparency = 1,
    ZIndex = 101, Parent = loadScr,
})

local useCG = true
local holder
pcall(function()
    holder = new("CanvasGroup", {
        Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 700, 0, 490),
        BackgroundTransparency = 1, GroupTransparency = 1,
        Visible = false, Parent = gui,
    })
end)
if not holder then
    useCG = false
    holder = new("Frame", {
        Name = "Holder", AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 700, 0, 490),
        BackgroundTransparency = 1, Visible = false, Parent = gui,
    })
end

local uiScale = new("UIScale", { Scale = 0.94, Parent = holder })

new("ImageLabel", {
    Size = UDim2.new(1, 50, 1, 50), Position = UDim2.new(0, -25, 0, -25),
    BackgroundTransparency = 1, Image = "rbxassetid://5554236805",
    ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.3,
    ScaleType = Enum.ScaleType.Slice, SliceCenter = Rect.new(23, 23, 277, 277),
    Parent = holder,
})

local assetDir = 'NixwareAssets'
local logoImage = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local wingImage = "rbxasset://textures/ui/GuiImagePlaceholder.png"
local bgPatternImage = "rbxasset://textures/ui/GuiImagePlaceholder.png"

if getcustomasset then
    if not isfolder(assetDir) then
        makefolder(assetDir)
    end
    
    pcall(function()
        if not isfile(assetDir..'/logo.png') then
            local byte = game:HttpGet("https://raw.githubusercontent.com/bsfkdu218/.vd-msajiaicmmdiurninmmdjuzneicisot/main/asz%2Cests/logo%20(5).png")
            writefile(assetDir..'/logo.png', byte)
            task.wait()
        end
        if isfile(assetDir..'/logo.png') then
            logoImage = getcustomasset(assetDir..'/logo.png')
        end
    end)
    
    pcall(function()
        if not isfile(assetDir..'/wing2.png') then
            local byte = game:HttpGet("https://raw.githubusercontent.com/bsfkdu218/.vd-msajiaicmmdiurninmmdjuzneicisot/main/asz%2Cests/wing.png")
            writefile(assetDir..'/wing2.png', byte)
            task.wait()
        end
        if isfile(assetDir..'/wing2.png') then
            wingImage = getcustomasset(assetDir..'/wing2.png')
        end
    end)
    
    pcall(function()
        if not isfile(assetDir..'/nixware.jpg') then
            local byte = game:HttpGet("https://raw.githubusercontent.com/bsfkdu218/.vd-msajiaicmmdiurninmmdjuzneicisot/main/asz%2Cests/nixware.jpg")
            writefile(assetDir..'/nixware.jpg', byte)
            task.wait()
        end
        if isfile(assetDir..'/nixware.jpg') then
            bgPatternImage = getcustomasset(assetDir..'/nixware.jpg')
        end
    end)
end

local main = new("Frame", {
    Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = C.bg, BackgroundTransparency = 0.1, BorderSizePixel = 0,
    ClipsDescendants = false, ZIndex = 2, Parent = holder,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = main })

local bgPattern = new("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundTransparency = 1,
    Image = bgPatternImage,
    ImageTransparency = 0.85,
    ScaleType = Enum.ScaleType.Crop,
    ZIndex = 0, Parent = main,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = bgPattern })

local wingGui = Instance.new("ScreenGui")
wingGui.Name = "NixwareWing"
wingGui.ResetOnSpawn = false
wingGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
wingGui.IgnoreGuiInset = true
wingGui.DisplayOrder = 999999
-- wing removed
pcall(protect_gui, wingGui)
wingGui.Parent = guiRoot

local leftWing = new("ImageLabel", {
    Size = UDim2.new(0, 400, 0, 400),
    Position = UDim2.new(0.5, -700, 0.5, -50),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Image = wingImage,
    ImageTransparency = 0.3,
    ImageColor3 = Color3.fromRGB(180, 100, 40),
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 1, Parent = wingGui,
})

new("UIStroke", { 
    Color = C.accent, 
    Thickness = 1, 
    Transparency = 0.7,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = main 
})

local topLine = new("Frame", {
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 15,
    Parent = main,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = topLine })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.2, C.accentDark),
        ColorSequenceKeypoint.new(0.5, C.accent),
        ColorSequenceKeypoint.new(0.8, C.accentDark),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    }),
    Parent = topLine,
})

task.spawn(function()
    local gradient = topLine:FindFirstChildOfClass("UIGradient")
    if gradient then
        while true do
            tw(gradient, { Offset = Vector2.new(1, 0) }, 3, Enum.EasingStyle.Linear)
            task.wait(3)
            gradient.Offset = Vector2.new(-1, 0)
            tw(gradient, { Offset = Vector2.new(0, 0) }, 3, Enum.EasingStyle.Linear)
            task.wait(3)
        end
    end
end)

local bgGradient = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.97,
    BorderSizePixel = 0, ZIndex = 0,
    Parent = main,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, C.accent),
    }),
    Rotation = 45,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.95),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0.95),
    }),
    Parent = bgGradient,
})

local topAccentLine = new("Frame", {
    Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0, ZIndex = 15, Parent = main,
})
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.3, 0.15),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.7, 0.15),
        NumberSequenceKeypoint.new(1, 0.85),
    }),
    Parent = topAccentLine,
})

local titleBar = new("Frame", {
    Name = "TitleBar", Position = UDim2.new(0, 0, 0, 2),
    Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.bg2,
    BorderSizePixel = 0, ZIndex = 10, Parent = main,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 15, 10)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 14, 17)),
    }),
    Rotation = 90,
    Parent = titleBar,
})

local nixwareLogo = new("ImageLabel", {
    Name = "Logo", Position = UDim2.new(0, 10, 0, 4),
    Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1,
    Image = logoImage,
    ZIndex = 12, Parent = titleBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = nixwareLogo })

local fireStroke = new("UIStroke", {
    Color = C.accent,
    Thickness = 1.5,
    Transparency = 0.5,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = nixwareLogo,
})
local fireGradient = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 0)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 200, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 0)),
    }),
    Rotation = 0,
    Parent = fireStroke,
})

task.spawn(function()
    while true do
        tw(fireGradient, { Rotation = 360 }, 2, Enum.EasingStyle.Linear)
        task.wait(2)
        fireGradient.Rotation = 0
    end
end)

local titleLabel = new("TextLabel", {
    Name = "Title", Position = UDim2.new(0, 38, 0, 0),
    Size = UDim2.new(0, 200, 1, 0), BackgroundTransparency = 1,
    Text = "NIXWARE", TextColor3 = Color3.new(1, 1, 1),
    TextSize = 15, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12,
    Parent = titleBar,
})
local titleGradient = new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 180, 50)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(255, 140, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0)),
    }),
    Offset = Vector2.new(-1, 0),
    Parent = titleLabel,
})

task.spawn(function()
    while true do
        tw(titleGradient, { Offset = Vector2.new(1, 0) }, 2, Enum.EasingStyle.Linear)
        task.wait(2)
        titleGradient.Offset = Vector2.new(-1, 0)
    end
end)

local accentLine = new("Frame", {
    Position = UDim2.new(0, 0, 1, -2),
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 11,
    Parent = titleBar,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.2, C.accent),
        ColorSequenceKeypoint.new(0.5, C.accentLight),
        ColorSequenceKeypoint.new(0.8, C.accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0)),
    }),
    Parent = accentLine,
})

task.spawn(function()
    local gradient = accentLine:FindFirstChildOfClass("UIGradient")
    if gradient then
        while true do
            tw(gradient, { Offset = Vector2.new(1, 0) }, 4, Enum.EasingStyle.Linear)
            task.wait(4)
            gradient.Offset = Vector2.new(-1, 0)
            tw(gradient, { Offset = Vector2.new(0, 0) }, 4, Enum.EasingStyle.Linear)
            task.wait(4)
        end
    end
end)

local minimizeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -36, 0.5, 0),
    Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = C.surface,
    BackgroundTransparency = 1, Text = "-", TextColor3 = C.textDim,
    TextSize = 12, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    ZIndex = 12, Parent = titleBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = minimizeBtn })
new("UIStroke", {
    Color = C.accent, Transparency = 1, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = minimizeBtn,
})
minimizeBtn.MouseEnter:Connect(function()
    tw(minimizeBtn, { BackgroundTransparency = 0.7, BackgroundColor3 = C.accent, TextColor3 = Color3.new(0, 0, 0) }, 0.15)
    tw(minimizeBtn:FindFirstChildOfClass("UIStroke"), { Transparency = 0 }, 0.15)
end)
minimizeBtn.MouseLeave:Connect(function()
    tw(minimizeBtn, { BackgroundTransparency = 1, BackgroundColor3 = C.surface, TextColor3 = C.textDim }, 0.15)
    tw(minimizeBtn:FindFirstChildOfClass("UIStroke"), { Transparency = 1 }, 0.15)
end)

local closeBtn = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = C.surface,
    BackgroundTransparency = 1, Text = "?", TextColor3 = C.textDim,
    TextSize = 16, Font = Enum.Font.GothamBold, AutoButtonColor = false,
    ZIndex = 12, Parent = titleBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = closeBtn })
new("UIStroke", {
    Color = C.accent, Transparency = 1, Thickness = 1,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = closeBtn,
})
closeBtn.MouseEnter:Connect(function()
    tw(closeBtn, { BackgroundTransparency = 0.6, BackgroundColor3 = C.accent, TextColor3 = Color3.new(0, 0, 0) }, 0.15)
    tw(closeBtn:FindFirstChildOfClass("UIStroke"), { Transparency = 0 }, 0.15)
end)
closeBtn.MouseLeave:Connect(function()
    tw(closeBtn, { BackgroundTransparency = 1, BackgroundColor3 = C.surface, TextColor3 = C.textDim }, 0.15)
    tw(closeBtn:FindFirstChildOfClass("UIStroke"), { Transparency = 1 }, 0.15)
end)

local TAB_Y      = 2 + 36
local TAB_WIDTH  = 144
local TAB_HEIGHT = 36
local STATUS_H   = 28

local tabBar = new("Frame", {
    Name = "TabBar", Position = UDim2.new(0, 0, 0, TAB_Y),
    Size = UDim2.new(0, TAB_WIDTH, 1, -TAB_Y - 60),
    BackgroundColor3 = C.bg2,
    BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 8, Parent = main,
})
new("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.border, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 9, Parent = tabBar,
})

local tabContainer = new("ScrollingFrame", {
    Position = UDim2.new(0, 0, 0, 8), Size = UDim2.new(1, 0, 1, -8),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent,
    ScrollBarImageTransparency = 0.5, ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0), ZIndex = 8, Parent = tabBar,
})
local tabLayout = new("UIListLayout", {
    FillDirection = Enum.FillDirection.Vertical,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 4), Parent = tabContainer,
})

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 8)
end)

local tabIndicator = new("Frame", {
    Name = "Indicator", Position = UDim2.new(1, -2, 0, 0),
    Size = UDim2.new(0, 2, 0, 0), BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 10, Parent = tabBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 1), Parent = tabIndicator })

local tabIndicatorGlow = new("Frame", {
    Name = "IndicatorGlow", Position = UDim2.new(1, -6, 0, 0),
    Size = UDim2.new(0, 8, 0, 0), BackgroundColor3 = C.accent,
    BackgroundTransparency = 0.65, BorderSizePixel = 0, ZIndex = 9, Parent = tabBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tabIndicatorGlow })
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 0.9),
    }),
    Rotation = 90,
    Parent = tabIndicatorGlow,
})

tabContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if activeTab > 0 and tabs[activeTab] then
        local btn = tabs[activeTab].button
        if btn then
            local relY = btn.AbsolutePosition.Y - tabContainer.AbsolutePosition.Y
            tabIndicator.Position = UDim2.new(1, -2, 0, relY)
            tabIndicatorGlow.Position = UDim2.new(1, -6, 0, relY)
        end
    end
end)

local profileContainer = new("Frame", {
    Name = "Profile", Position = UDim2.new(0, 0, 1, -60),
    Size = UDim2.new(0, TAB_WIDTH, 0, 60), BackgroundColor3 = C.bg2,
    BackgroundTransparency = 0.3, BorderSizePixel = 0, ZIndex = 11, Parent = main,
})

new("Frame", {
    Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0),
    BackgroundColor3 = C.border, BackgroundTransparency = 0.3,
    BorderSizePixel = 0, ZIndex = 12, Parent = profileContainer,
})

local avatarFrame = new("Frame", {
    Position = UDim2.new(0, 10, 0, 8), Size = UDim2.new(0, 44, 0, 44),
    BackgroundColor3 = C.surface, BorderSizePixel = 0, ZIndex = 12, Parent = profileContainer,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatarFrame })
new("UIStroke", {
    Color = C.border, Thickness = 2,
    Transparency = 0.3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = avatarFrame,
})

local avatarImg = new("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150),
    ZIndex = 13, Parent = avatarFrame,
})
new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = avatarImg })

local usernameLabel = new("TextLabel", {
    Position = UDim2.new(0, 62, 0, 12), Size = UDim2.new(1, -70, 0, 16),
    BackgroundTransparency = 1, Text = player.Name,
    Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 13, Parent = profileContainer,
})

local premiumLabel = new("TextLabel", {
    Position = UDim2.new(0, 62, 0, 32), Size = UDim2.new(0, 60, 0, 16),
    BackgroundColor3 = C.accent, BackgroundTransparency = 0.85,
    Text = "PREMIUM", Font = Enum.Font.GothamBold, TextSize = 8,
    TextColor3 = C.accent, ZIndex = 13, Parent = profileContainer,
})
new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = premiumLabel })

local CONTENT_X = TAB_WIDTH + 1
local CONTENT_Y = TAB_Y

local contentArea = new("Frame", {
    Name = "Content", Position = UDim2.new(0, CONTENT_X, 0, CONTENT_Y),
    Size = UDim2.new(1, -CONTENT_X, 1, -CONTENT_Y - STATUS_H),
    BackgroundTransparency = 1, ClipsDescendants = true,
    ZIndex = 2, Parent = main,
})
local dropLayer = new("Frame", {
    Name = "DropLayer", Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1, ZIndex = 80, Parent = gui,
})

new("Frame", {
    Position = UDim2.new(0, TAB_WIDTH, 1, -STATUS_H), Size = UDim2.new(1, -TAB_WIDTH, 0, 1),
    BackgroundColor3 = C.border, BorderSizePixel = 0, ZIndex = 7, Parent = main,
})

local statusBar = new("Frame", {
    Position = UDim2.new(0, TAB_WIDTH, 1, -STATUS_H), Size = UDim2.new(1, -TAB_WIDTH, 0, STATUS_H),
    BackgroundColor3 = C.bg2, BorderSizePixel = 0, ZIndex = 7, Parent = main,
})
new("Frame", {
    Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.border,
    BorderSizePixel = 0, ZIndex = 8, Parent = statusBar,
})

local sR = new("TextLabel", {
    Position = UDim2.new(0, 14, 0, 0), Size = UDim2.new(1, -28, 1, 0),
    BackgroundTransparency = 1, RichText = true,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.textDim,
    TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 8, Parent = statusBar,
})
new("UIPadding", {
    PaddingRight = UDim.new(0, 14), Parent = sR,
})

local sFpsBuf, sLastUpd = {}, 0
RS.Heartbeat:Connect(function(dt)
    table.insert(sFpsBuf, 1 / dt)
    if #sFpsBuf > 60 then table.remove(sFpsBuf, 1) end
    local now = tick()
    if now - sLastUpd < 0.4 then return end
    sLastUpd = now
    local avg = 0
    for _, v in ipairs(sFpsBuf) do avg = avg + v end
    avg = math.floor(avg / math.max(#sFpsBuf, 1))
    local ping = 0
    pcall(function() ping = math.floor(player:GetNetworkPing() * 1000) end)
    sR.Text = string.format(
        '<font color="#%s">%d</font> fps <font color="#%s">|</font> <font color="#%s">%d</font>ms',
        hexColor(C.text), avg, hexColor(C.textDim), hexColor(C.text), ping
    )
end)

local searchTrig = new("TextButton", {
    Position = UDim2.new(0.5, -55, 0.5, -9),
    Size = UDim2.new(0, 110, 0, 18),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22), 
    Text = "   search...",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham, TextSize = 10, TextColor3 = C.textDim,
    AutoButtonColor = false, ZIndex = 9, Parent = statusBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = searchTrig })
new("UIStroke", { 
    Color = C.accent, 
    Thickness = 1, 
    Transparency = 0.7,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
    Parent = searchTrig 
})
searchTrig.MouseEnter:Connect(function() 
    tw(searchTrig, { BackgroundColor3 = Color3.fromRGB(22, 22, 26) }, 0.12)
    tw(searchTrig:FindFirstChildOfClass("UIStroke"), { Transparency = 0.3 }, 0.12)
end)
searchTrig.MouseLeave:Connect(function() 
    tw(searchTrig, { BackgroundColor3 = Color3.fromRGB(18, 18, 22) }, 0.12)
    tw(searchTrig:FindFirstChildOfClass("UIStroke"), { Transparency = 0.7 }, 0.12)
end)

local searchOpen = false
local searchBG = new("TextButton", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 60, Parent = gui,
})
local searchModal = new("Frame", {
    Size = UDim2.new(0, 450, 0, 380),
    Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(14, 14, 18), 
    BackgroundTransparency = 0,
    Visible = false, ZIndex = 61, Parent = gui,
})
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = searchModal })

new("UIStroke", { 
    Color = C.accent, 
    Thickness = 1.5, 
    Transparency = 0.5,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
    Parent = searchModal 
})

local searchBgPattern = new("ImageLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Image = "",
    ImageTransparency = 0.92,
    ScaleType = Enum.ScaleType.Tile,
    TileSize = UDim2.new(0, 200, 0, 200),
    ZIndex = 61,
    Parent = searchModal,
})
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = searchBgPattern })

pcall(function()
    local assetDir = "NixwareAssets"
    if not isfolder(assetDir) then makefolder(assetDir) end
    if not isfile(assetDir..'/pattern.jpg') then
        local byte = game:HttpGet("https://raw.githubusercontent.com/bsfkdu218/.vd-msajiaicmmdiurninmmdjuzneicisot/main/asz%2Cests/nixware.jpg")
        writefile(assetDir..'/pattern.jpg', byte)
        task.wait()
    end
    if isfile(assetDir..'/pattern.jpg') then
        searchBgPattern.Image = getcustomasset(assetDir..'/pattern.jpg')
    end
end)

local smAcc = new("Frame", {
    Size = UDim2.new(1, 0, 0, 2), 
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 62, Parent = searchModal,
})
new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = smAcc })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
        ColorSequenceKeypoint.new(0.5, C.accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 50)),
    }),
    Parent = smAcc,
})

local searchTitle = new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 20, 0, 12),
    BackgroundTransparency = 1, Text = "SEARCH", Font = Enum.Font.GothamBold,
    TextSize = 14, TextColor3 = C.accent,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 62, Parent = searchModal,
})
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 50)),
    }),
    Parent = searchTitle,
})

local searchInput = new("TextBox", {
    Size = UDim2.new(1, -40, 0, 40), Position = UDim2.new(0, 20, 0, 52),
    BackgroundColor3 = Color3.fromRGB(18, 18, 22), 
    BackgroundTransparency = 0,
    PlaceholderText = "Type to search...",
    PlaceholderColor3 = C.textDim, Text = "",
    Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
    ClearTextOnFocus = true, ZIndex = 62, Parent = searchModal,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = searchInput })
new("UIStroke", { 
    Color = C.accent, 
    Thickness = 1, 
    Transparency = 0.7,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border, 
    Parent = searchInput 
})
new("UIPadding", {
    PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = searchInput,
})

searchInput.Focused:Connect(function()
    tw(searchInput:FindFirstChildOfClass("UIStroke"), { Transparency = 0.2 }, 0.15)
end)
searchInput.FocusLost:Connect(function()
    tw(searchInput:FindFirstChildOfClass("UIStroke"), { Transparency = 0.7 }, 0.15)
end)

local searchResults = new("ScrollingFrame", {
    Size = UDim2.new(1, -40, 1, -110), Position = UDim2.new(0, 20, 0, 100),
    BackgroundTransparency = 1, ScrollBarThickness = 4,
    ScrollBarImageColor3 = C.accent, ScrollBarImageTransparency = 0.4,
    CanvasSize = UDim2.new(0, 0, 0, 0), BorderSizePixel = 0,
    ZIndex = 62, Parent = searchModal,
})
local srLay = new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = searchResults,
})
srLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    searchResults.CanvasSize = UDim2.new(0, 0, 0, srLay.AbsoluteContentSize.Y + 8)
end)

local smScale = new("UIScale", { Scale = 0.92, Parent = searchModal })

local function openSearchModal()
    searchOpen = true; searchBG.Visible = true; searchModal.Visible = true
    searchInput.Text = ""
    tw(searchBG, { BackgroundTransparency = 0.5 }, 0.2)
    smScale.Scale = 0.92
    tw(smScale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    task.defer(function() searchInput:CaptureFocus() end)
end

local function closeSearchModal()
    searchOpen = false
    tw(searchBG, { BackgroundTransparency = 1 }, 0.15)
    tw(smScale, { Scale = 0.92 }, 0.15)
    task.delay(0.15, function()
        if not searchOpen then searchBG.Visible = false; searchModal.Visible = false end
    end)
end

local function showSearchResults(query)
    for _, ch in ipairs(searchResults:GetChildren()) do
        if ch:IsA("TextButton") then ch:Destroy() end
    end
    if #query == 0 then return end
    local ql = string.lower(query)
    local n = 0
    for _, it in ipairs(searchItems) do
        if string.find(string.lower(it.name), ql, 1, true) then
            n = n + 1
            local r = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 36), 
                BackgroundColor3 = Color3.fromRGB(18, 18, 22),
                BackgroundTransparency = 0.3, RichText = true,
                Text = string.format('  %s  <font color="#%s">· tab %s</font>', it.name, hexColor(C.textDim), tostring(it.tab)),
                TextXAlignment = Enum.TextXAlignment.Left,
                Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text,
                LayoutOrder = n, ZIndex = 63, Parent = searchResults,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = r })
            new("UIStroke", {
                Color = C.accent,
                Thickness = 1,
                Transparency = 0.9,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Parent = r,
            })
            r.MouseEnter:Connect(function() 
                tw(r, { BackgroundTransparency = 0 }, 0.1)
                tw(r:FindFirstChildOfClass("UIStroke"), { Transparency = 0.5 }, 0.1)
            end)
            r.MouseLeave:Connect(function() 
                tw(r, { BackgroundTransparency = 0.3 }, 0.1)
                tw(r:FindFirstChildOfClass("UIStroke"), { Transparency = 0.9 }, 0.1)
            end)
            r.MouseButton1Click:Connect(function()
                closeSearchModal()
                if it.tab and tabs[it.tab] then switchTab(it.tab) end
            end)
        end
    end
end

searchInput:GetPropertyChangedSignal("Text"):Connect(function() showSearchResults(searchInput.Text) end)
searchTrig.MouseButton1Click:Connect(openSearchModal)
searchBG.MouseButton1Click:Connect(closeSearchModal)

local function updateIndicator(index)
    task.spawn(function()
        task.wait()
        local btn = tabs[index].button
        local relY = btn.AbsolutePosition.Y - tabContainer.AbsolutePosition.Y
        pcall(function()
            tw(tabIndicator, {
                Position = UDim2.new(1, -2, 0, relY),
                Size = UDim2.new(0, 2, 0, btn.AbsoluteSize.Y),
            }, 0.25, Enum.EasingStyle.Quint)
        end)
        pcall(function()
            tw(tabIndicatorGlow, {
                Position = UDim2.new(1, -6, 0, relY),
                Size = UDim2.new(0, 8, 0, btn.AbsoluteSize.Y),
            }, 0.25, Enum.EasingStyle.Quint)
        end)
    end)
end

switchTab = function(index)
    if activeTab == index then return end
    closeActiveDropdown()

    if activeTab > 0 and tabs[activeTab] then
        local old = tabs[activeTab].button
        tw(old, { BackgroundTransparency = 1 }, 0.15)
        local oldIcon = old:FindFirstChild("TextLabel")
        if oldIcon then tw(oldIcon, { TextColor3 = Color3.fromRGB(120, 120, 130) }, 0.15) end
        for _, child in ipairs(old:GetChildren()) do
            if child:IsA("TextLabel") and child ~= oldIcon then
                tw(child, { TextColor3 = C.textSec }, 0.15)
            end
        end
        local oldAccent = old:FindFirstChild("Accent")
        if oldAccent then tw(oldAccent, { BackgroundTransparency = 1 }, 0.15) end
        tabs[activeTab].page.Visible = false
    end

    activeTab = index
    local btn = tabs[index].button
    tw(btn, { BackgroundTransparency = 0.5 }, 0.15)
    local tabIcon = btn:FindFirstChild("TextLabel")
    if tabIcon then tw(tabIcon, { TextColor3 = C.accent }, 0.15) end
    for _, child in ipairs(btn:GetChildren()) do
        if child:IsA("TextLabel") and child ~= tabIcon then
            tw(child, { TextColor3 = C.accent }, 0.15)
        end
    end
    local accentLine = btn:FindFirstChild("Accent")
    if accentLine then tw(accentLine, { BackgroundTransparency = 0 }, 0.15) end
    local pg = tabs[index].page
    pg.Visible = true
    pg.CanvasPosition = Vector2.new(0, 0)

    for _, child in ipairs(pg:GetDescendants()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            local orig = child.BackgroundTransparency
            if orig < 1 then
                child.BackgroundTransparency = 1
                tw(child, { BackgroundTransparency = orig }, 0.25)
            end
        end
    end

    updateIndicator(index)
end

local tabOrder = 0

local function addTab(name, icon)
    tabOrder = tabOrder + 1
    local idx = #tabs + 1
    icon = icon or "◆"

    local btn = new("TextButton", {
        Name = name, Size = UDim2.new(1, -12, 0, 38),
        BackgroundColor3 = C.bg3,
        BackgroundTransparency = 1,
        Text = "", TextColor3 = C.textSec, TextSize = 12,
        Font = Enum.Font.GothamBold, ZIndex = 9,
        AutoButtonColor = false, LayoutOrder = tabOrder, Parent = tabContainer,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = btn })
    
    local tabIcon = new("TextLabel", {
        Position = UDim2.new(0, 8, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.new(0, 20, 0, 20), BackgroundTransparency = 1,
        Text = icon, TextColor3 = Color3.fromRGB(120, 120, 130), TextSize = 16,
        FontFace = LucideFont, TextWrapped = true, ZIndex = 10, Parent = btn,
    })
    
    local tabLabel = new("TextLabel", {
        Position = UDim2.new(0, 32, 0, 0), Size = UDim2.new(1, -36, 1, 0),
        BackgroundTransparency = 1, Text = string.upper(name),
        TextColor3 = C.textSec, TextSize = 11, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10, Parent = btn,
    })
    
    local accentLine = new("Frame", {
        Name = "Accent", Size = UDim2.new(0, 2, 0, 20),
        Position = UDim2.new(0, 2, 0.5, -10),
        BackgroundColor3 = C.accent, BorderSizePixel = 0,
        BackgroundTransparency = 1, ZIndex = 10, Parent = btn,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = accentLine })

    btn.MouseEnter:Connect(function()
        if activeTab ~= idx then 
            tw(btn, { BackgroundTransparency = 0.6 }, 0.15)
            tw(tabIcon, { TextColor3 = Color3.fromRGB(180, 180, 190) }, 0.15)
            tw(tabLabel, { TextColor3 = C.text }, 0.15)
            tw(accentLine, { BackgroundTransparency = 0.7 }, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if activeTab ~= idx then 
            tw(btn, { BackgroundTransparency = 1 }, 0.15)
            tw(tabIcon, { TextColor3 = Color3.fromRGB(120, 120, 130) }, 0.15)
            tw(tabLabel, { TextColor3 = C.textSec }, 0.15)
            tw(accentLine, { BackgroundTransparency = 1 }, 0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function() switchTab(idx) end)

    local page = new("ScrollingFrame", {
        Name = name .. "Page", Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 4, ScrollBarImageColor3 = C.accent,
        ScrollBarImageTransparency = 0.3, ScrollingDirection = Enum.ScrollingDirection.Y,
        Visible = false, ZIndex = 2, Parent = contentArea,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14),
        Parent = page,
    })

    local GAP = 10

    local leftCol = new("Frame", {
        Size = UDim2.new(0.5, -GAP / 2, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1, Parent = page,
    })
    local leftLay = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = leftCol })

    local rightCol = new("Frame", {
        Size = UDim2.new(0.5, -GAP / 2, 0, 0),
        Position = UDim2.new(0.5, GAP / 2, 0, 0),
        BackgroundTransparency = 1, Parent = page,
    })
    local rightLay = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rightCol })

    local function updateCanvasSize()
        local lH = leftLay.AbsoluteContentSize.Y
        local rH = rightLay.AbsoluteContentSize.Y
        leftCol.Size = UDim2.new(0.5, -GAP / 2, 0, lH)
        rightCol.Size = UDim2.new(0.5, -GAP / 2, 0, rH)
        page.CanvasSize = UDim2.new(0, 0, 0, math.max(lH, rH) + 24)
    end

    leftLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    rightLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvasSize)
    page:GetPropertyChangedSignal("CanvasPosition"):Connect(closeActiveDropdown)

    tabs[idx] = { name = name, button = btn, page = page }
    return leftCol, rightCol
end

local function addTabLabel(text)
    tabOrder = tabOrder + 1
    local label = new("TextLabel", {
        Name = "CategoryLabel", Size = UDim2.new(1, -12, 0, 24),
        BackgroundTransparency = 1,
        Text = string.upper(text), TextColor3 = C.textDim, TextSize = 10,
        Font = Enum.Font.GothamBold, ZIndex = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = tabOrder, Parent = tabContainer,
    })
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 6), Parent = label,
    })
end

local SEC_TITLE_H = 26

local function addSection(column, title)
    local group = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = C.bg2, BackgroundTransparency = 0.5,
        ClipsDescendants = true,
        LayoutOrder = #column:GetChildren(), Parent = column,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = group })
    new("UIStroke", { 
        Color = C.borderLight, 
        Thickness = 1, 
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = group 
    })

    local shadowGrad = new("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.9,
        BorderSizePixel = 0,
        ZIndex = 0,
        Parent = group,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = shadowGrad })
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent = shadowGrad,
    })

    new("TextLabel", {
        Size = UDim2.new(1, -16, 0, SEC_TITLE_H),
        Position = UDim2.new(0, 12, 0, 2),
        BackgroundTransparency = 1, Text = string.upper(title),
        Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = C.text, TextTransparency = 0.3,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = group,
    })

    new("Frame", {
        Size = UDim2.new(1, -20, 0, 1), Position = UDim2.new(0, 10, 0, SEC_TITLE_H),
        BackgroundColor3 = C.borderLight, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Parent = group,
    })

    local inner = new("Frame", {
        Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, SEC_TITLE_H + 6),
        BackgroundTransparency = 1, Parent = group,
    })

    local innerLay = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 3), Parent = inner,
    })

    innerLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        local h = innerLay.AbsoluteContentSize.Y
        inner.Size = UDim2.new(1, -20, 0, h)
        group.Size = UDim2.new(1, 0, 0, SEC_TITLE_H + 6 + h + 8)
    end)

    return inner
end

local function addToggle(section, name, default, callback, colorOpts)
    callback = callback or function() end
    local state = default or false
    local extraHook = nil
    local boundKey = nil
    
    local uiKey = "toggle_" .. name:gsub("%s", "_"):lower()

    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })

    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.textSec,
        TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })

    row.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then pcall(function() tw(lbl, { TextColor3 = C.text }, 0.08) end) end
    end)
    row.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then pcall(function() tw(lbl, { TextColor3 = C.textSec }, 0.08) end) end
    end)

    local kbBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -42, 0.5, 0),
        Size = UDim2.new(0, 30, 0, 18), BackgroundColor3 = C.bg3,
        BackgroundTransparency = 0.3,
        Text = "-", TextColor3 = C.textDim, TextSize = 9,
        Font = Enum.Font.Gotham, AutoButtonColor = false, Parent = row,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = kbBtn })
    new("UIStroke", { 
        Color = C.border, 
        Thickness = 1, 
        Transparency = 0.7,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = kbBtn 
    })

    local swBg = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 18), BackgroundColor3 = state and C.accent or C.toggleOff,
        BackgroundTransparency = state and 0 or 0.3,
        Parent = row,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = swBg })
    local swStroke = new("UIStroke", {
        Color = state and C.accentLight or C.border, Thickness = 1,
        Transparency = state and 0 or 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = swBg,
    })
    
    local toggleGlow = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(1.3, 0, 1.8, 0), BackgroundColor3 = C.accent,
        BackgroundTransparency = state and 0.85 or 1, BorderSizePixel = 0,
        ZIndex = -1, Parent = swBg,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 12), Parent = toggleGlow })

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 12, 0, 12),
        BackgroundColor3 = state and Color3.fromRGB(20, 20, 25) or C.accent,
        Parent = swBg,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knob })

    local toggleBg = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0, 36, 0, 18), BackgroundTransparency = 1,
        Text = "", Parent = row,
    })

    local entry = { name = name, key = nil, active = state, toggleFn = nil }
    table.insert(kbEntries, entry)
    table.insert(searchItems, { name = name, tab = activeTab })

    local function set(v)
        state = v
        entry.active = v
        pcall(function()
            tw(swBg, { 
                BackgroundColor3 = state and C.accent or C.toggleOff,
                BackgroundTransparency = state and 0 or 0.3,
            }, 0.15)
        end)
        pcall(function()
            tw(swStroke, { 
                Color = state and C.accentLight or C.border,
                Transparency = state and 0 or 0.6,
            }, 0.15)
        end)
        pcall(function()
            tw(toggleGlow, { 
                BackgroundTransparency = state and 0.85 or 1,
            }, 0.2)
        end)
        pcall(function()
            tw(knob, {
                Position = state and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
                BackgroundColor3 = state and Color3.fromRGB(20, 20, 25) or C.accent,
            }, 0.15, Enum.EasingStyle.Back)
        end)
        
        if not APPLYING_CONFIG then
            pcall(function() saveUIState(uiKey, state) end)
        end
        
        pcall(function() callback(state) end)
        if extraHook then pcall(function() extraHook(state) end) end
        pcall(refreshKB)
    end

    entry.toggleFn = function() set(not state) end

    toggleBg.MouseButton1Click:Connect(function() set(not state) end)

    kbBtn.MouseButton1Click:Connect(function()
        if listeningBind then return end
        listeningBind = kbBtn
        kbBtn.Text = ".."
        tw(kbBtn, { TextColor3 = C.accent }, 0.1)

        local cn
        cn = UIS.InputBegan:Connect(function(inp)
            if inp.KeyCode == Enum.KeyCode.Escape then
                boundKey = nil; entry.key = nil; kbBtn.Text = "-"
            elseif inp.KeyCode ~= Enum.KeyCode.Unknown and inp.KeyCode ~= Enum.KeyCode.Delete then
                boundKey = inp.KeyCode; entry.key = boundKey; kbBtn.Text = kname(boundKey)
            else
                return
            end
            tw(kbBtn, { TextColor3 = C.textDim }, 0.1)
            listeningBind = nil
            cn:Disconnect()
        end)
    end)

    local colorDotRef = nil
    if colorOpts then
        local currentColor = colorOpts.default or Color3.new(1, 1, 1)
        local colorDot = new("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -78, 0.5, 0),
            Size = UDim2.new(0, 18, 0, 14),
            BackgroundColor3 = currentColor,
            Text = "", AutoButtonColor = false, Parent = row,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = colorDot })
        new("UIStroke", { 
            Color = C.border, 
            Thickness = 1, 
            Transparency = 0.5,
            Parent = colorDot 
        })
        colorDotRef = colorDot

        colorDot.MouseButton1Click:Connect(function()
            openColorPicker(colorDot, colorDot.BackgroundColor3, function(c)
                colorDot.BackgroundColor3 = c
                if colorOpts.onChanged then colorOpts.onChanged(c) end
            end)
        end)
    end

    return {
        set = set,
        get = function() return state end,
        hook = function(fn) extraHook = fn end,
        colorDot = colorDotRef,
    }
end

local function addSlider(section, name, min, max, default, callback, opts)
    callback = callback or function() end
    opts = opts or {}
    local decimals = opts.round or 0
    local suffix = opts.suffix or ""
    local mult = 10 ^ decimals
    local function roundVal(v)
        return math.floor(v * mult + 0.5) / mult
    end
    local value = roundVal(math.clamp(default or min, min, max))
    table.insert(searchItems, { name = name, tab = activeTab })
    
    local uiKey = "slider_" .. name:gsub("%s", "_"):lower()

    local function fmtVal(v)
        if decimals > 0 then return string.format("%." .. decimals .. "f", v) .. suffix
        else return tostring(math.floor(v)) .. suffix end
    end

    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.rowHover,
        BackgroundTransparency = 0.8, BorderSizePixel = 0,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 5), Parent = frame })

    frame.MouseEnter:Connect(function() pcall(function() tw(frame, { BackgroundTransparency = 0.5 }, 0.12) end) end)
    frame.MouseLeave:Connect(function() pcall(function() tw(frame, { BackgroundTransparency = 0.8 }, 0.12) end) end)

    new("TextLabel", {
        Position = UDim2.new(0, 6, 0, 2), Size = UDim2.new(0.65, 0, 0, 20),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.text,
        TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = frame,
    })

    local valLabel = new("TextLabel", {
        Position = UDim2.new(0.65, 0, 0, 2), Size = UDim2.new(0.35, -6, 0, 18),
        BackgroundTransparency = 1, Text = fmtVal(value),
        TextColor3 = C.accent, TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right, Parent = frame,
    })

    local barBg = new("Frame", {
        Position = UDim2.new(0, 6, 0, 24), Size = UDim2.new(1, -12, 0, 5),
        BackgroundColor3 = C.bg3, BackgroundTransparency = 0.3,
        Parent = frame,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 2.5), Parent = barBg })
    new("UIStroke", { 
        Color = C.border, 
        Thickness = 1, 
        Transparency = 0.7,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = barBg 
    })

    local pct = (value - min) / (max - min)

    local fill = new("Frame", {
        Size = UDim2.new(pct, 0, 1, 0), BackgroundColor3 = C.accent,
        BorderSizePixel = 0, Parent = barBg,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 2.5), Parent = fill })
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 80, 0)),
            ColorSequenceKeypoint.new(0.5, C.accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 180, 50)),
        }),
        Parent = fill,
    })

    local knb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(pct, 0, 0.5, 0),
        Size = UDim2.new(0, 11, 0, 11), BackgroundColor3 = C.accent,
        ZIndex = 2, Parent = barBg,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = knb })

    local function setValue(v)
        value = roundVal(math.clamp(v, min, max))
        local p = (value - min) / (max - min)
        fill.Size = UDim2.new(p, 0, 1, 0)
        knb.Position = UDim2.new(p, 0, 0.5, 0)
        valLabel.Text = fmtVal(value)
        
        if not APPLYING_CONFIG then
            pcall(function() saveUIState(uiKey, value) end)
        end
        
        pcall(function() callback(value) end)
    end

    local function onInput(input)
        local rx = math.clamp((input.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
        setValue(min + rx * (max - min))
    end

    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = onInput; onInput(input)
        end
    end)

    return { set = setValue, get = function() return value end }
end

local function addDropdown(section, name, options, default, callback)
    callback = callback or function() end
    local selected = default or options[1]
    local isOpen = false
    local myRef = {}
    table.insert(searchItems, { name = name, tab = activeTab })
    
    local uiKey = "dropdown_" .. name:gsub("%s", "_"):lower()

    local fr = new("Frame", {
        Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })

    new("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.textSec,
        TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = fr,
    })

    local ddBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.48, 0, 0, 20), BackgroundColor3 = C.bg3,
        BackgroundTransparency = 0.3,
        Text = selected .. "  ?", Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = C.textSec, TextXAlignment = Enum.TextXAlignment.Right,
        AutoButtonColor = false, Parent = fr,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ddBtn })
    new("UIStroke", { 
        Color = C.border, 
        Thickness = 1, 
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = ddBtn 
    })
    new("UIPadding", {
        PaddingRight = UDim.new(0, 6), Parent = ddBtn,
    })

    ddBtn.MouseEnter:Connect(function() pcall(function() tw(ddBtn, { TextColor3 = C.text, BackgroundTransparency = 0.1 }, 0.12) end) end)
    ddBtn.MouseLeave:Connect(function() pcall(function() tw(ddBtn, { TextColor3 = C.textSec, BackgroundTransparency = 0.3 }, 0.12) end) end)

    local optH = #options * 24 + 8
    local maxH = 220
    local needsScroll = optH > maxH

    local optionsFrame = new("Frame", {
        Size = UDim2.new(0, 150, 0, math.min(optH, maxH)), BackgroundColor3 = C.bg2,
        BackgroundTransparency = 0.1,
        Visible = false, ClipsDescendants = true, ZIndex = 81, Parent = dropLayer,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = optionsFrame })
    new("UIStroke", { 
        Color = C.borderLight, 
        Thickness = 1, 
        Transparency = 0.5,
        Parent = optionsFrame 
    })

    local itemParent = optionsFrame
    if needsScroll then
        local scroll = new("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
            ScrollBarThickness = 3, ScrollBarImageColor3 = C.textDim,
            CanvasSize = UDim2.new(0, 0, 0, optH),
            ZIndex = 82, Parent = optionsFrame,
        })
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = scroll })
        new("UIPadding", {
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            Parent = scroll,
        })
        itemParent = scroll
    else
        new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2), Parent = optionsFrame })
        new("UIPadding", {
            PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
            PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            Parent = optionsFrame,
        })
    end

    local function closeThis()
        isOpen = false
        optionsFrame.Visible = false
    end

    local optButtons = {}

    for i, opt in ipairs(options) do
        local ob = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = C.bg3,
            BackgroundTransparency = 0.5, Text = opt, Font = Enum.Font.Gotham,
            TextSize = 10, TextColor3 = opt == selected and C.accent or C.textSec,
            AutoButtonColor = false, LayoutOrder = i, ZIndex = 83, Parent = itemParent,
        })
        new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = ob })
        optButtons[i] = ob

        ob.MouseEnter:Connect(function() pcall(function() tw(ob, { BackgroundTransparency = 0.2, TextColor3 = C.text }, 0.08) end) end)
        ob.MouseLeave:Connect(function()
            pcall(function() tw(ob, { BackgroundTransparency = 0.5, TextColor3 = ob.Text == selected and C.accent or C.textSec }, 0.08) end)
        end)
        ob.MouseButton1Click:Connect(function()
            selected = opt
            ddBtn.Text = opt .. "  ?"
            
            if not APPLYING_CONFIG then
                pcall(function() saveUIState(uiKey, opt) end)
            end
            
            pcall(function() callback(opt) end)
            for _, btn in ipairs(optButtons) do
                btn.TextColor3 = btn.Text == opt and C.accent or C.textSec
                btn.BackgroundTransparency = 0.5
            end
            closeThis(); openDropdown = nil
        end)
    end

    ddBtn.MouseButton1Click:Connect(function()
        if closeColorPicker then closeColorPicker() end
        if openDropdown and openDropdown.ref ~= myRef then
            openDropdown.close(); openDropdown = nil
        end
        isOpen = not isOpen
        if isOpen then
            local ap, as = ddBtn.AbsolutePosition, ddBtn.AbsoluteSize
            optionsFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
            optionsFrame.Size = UDim2.new(0, as.X, 0, math.min(optH, maxH))
            optionsFrame.Visible = true
            openDropdown = { ref = myRef, close = closeThis, frame = optionsFrame, btn = ddBtn }
        else
            closeThis(); openDropdown = nil
        end
    end)

    return {
        set = function(v) ddBtn.Text = v .. "  ?"; selected = v end,
        get = function() return selected end,
    }
end

local function addMultiDropdown(section, name, getOptionsFn, callback)
    callback = callback or function() end
    local selected = {}
    local isOpen = false
    local myRef = {}
    table.insert(searchItems, { name = name, tab = activeTab })

    local fr = new("Frame", {
        Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })

    new("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1, Text = name, TextColor3 = C.textSec,
        TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = fr,
    })

    local ddBtn = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0.48, 0, 0, 18), BackgroundColor3 = C.bg3,
        Text = "None  ?", Font = Enum.Font.Gotham, TextSize = 10,
        TextColor3 = C.textSec, TextXAlignment = Enum.TextXAlignment.Right,
        AutoButtonColor = false, Parent = fr,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ddBtn })

    ddBtn.MouseEnter:Connect(function() tw(ddBtn, { TextColor3 = C.text }, 0.1) end)
    ddBtn.MouseLeave:Connect(function() tw(ddBtn, { TextColor3 = C.textSec }, 0.1) end)

    local optionsFrame = new("Frame", {
        Size = UDim2.new(0, 150, 0, 50), BackgroundColor3 = C.bg2,
        Visible = false, ClipsDescendants = true, ZIndex = 81, Parent = dropLayer,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = optionsFrame })
    new("UIStroke", { Color = C.border, Thickness = 1, Parent = optionsFrame })

    local scrollFrame = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.textDim,
        CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 82, Parent = optionsFrame,
    })
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = scrollFrame })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3),
        Parent = scrollFrame,
    })

    local function updateLabel()
        if #selected == 0 then
            ddBtn.Text = "None  ?"
        elseif #selected == 1 then
            ddBtn.Text = selected[1] .. "  ?"
        else
            ddBtn.Text = #selected .. " selected  ?"
        end
    end

    local function isSelected(name)
        for i, v in ipairs(selected) do
            if v == name then return true, i end
        end
        return false, nil
    end

    local function rebuildOptions()
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        local options = getOptionsFn()
        local newSelected = {}
        for _, s in ipairs(selected) do
            for _, o in ipairs(options) do
                if o == s then table.insert(newSelected, s); break end
            end
        end
        selected = newSelected
        updateLabel()

        for i, opt in ipairs(options) do
            local sel, _ = isSelected(opt)
            local ob = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = C.bg3,
                BackgroundTransparency = sel and 0.5 or 1,
                Text = (sel and "✓ " or "   ") .. opt,
                Font = Enum.Font.Gotham, TextSize = 10,
                TextColor3 = sel and C.accent or C.textSec,
                AutoButtonColor = false, LayoutOrder = i, ZIndex = 83,
                Parent = scrollFrame,
            })
            new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = ob })

            ob.MouseEnter:Connect(function() tw(ob, { BackgroundTransparency = 0.3, TextColor3 = C.text }, 0.06) end)
            ob.MouseLeave:Connect(function()
                local s2, _ = isSelected(opt)
                tw(ob, { BackgroundTransparency = s2 and 0.5 or 1, TextColor3 = s2 and C.accent or C.textSec }, 0.06)
            end)
            ob.MouseButton1Click:Connect(function()
                local s2, idx = isSelected(opt)
                if s2 then
                    table.remove(selected, idx)
                    ob.Text = "   " .. opt
                    ob.TextColor3 = C.textSec
                    ob.BackgroundTransparency = 1
                else
                    table.insert(selected, opt)
                    ob.Text = "[X] " .. opt
                    ob.TextColor3 = C.accent
                    ob.BackgroundTransparency = 0.5
                end
                updateLabel()
                callback(selected)
            end)
        end

        local count = #options
        optionsFrame.Size = UDim2.new(0, optionsFrame.AbsoluteSize.X, 0, math.clamp(count * 22 + 6, 28, 180))
    end

    local function closeThis()
        isOpen = false
        optionsFrame.Visible = false
    end

    ddBtn.MouseButton1Click:Connect(function()
        if closeColorPicker then closeColorPicker() end
        if openDropdown and openDropdown.ref ~= myRef then
            openDropdown.close(); openDropdown = nil
        end
        isOpen = not isOpen
        if isOpen then
            rebuildOptions()
            local ap, as = ddBtn.AbsolutePosition, ddBtn.AbsoluteSize
            optionsFrame.Position = UDim2.new(0, ap.X, 0, ap.Y + as.Y + 2)
            optionsFrame.Size = UDim2.new(0, as.X, 0, optionsFrame.AbsoluteSize.Y)
            optionsFrame.Visible = true
            openDropdown = { ref = myRef, close = closeThis, frame = optionsFrame, btn = ddBtn }
        else
            closeThis(); openDropdown = nil
        end
    end)

    return {
        getSelected = function() return selected end,
        setSelected = function(list) selected = list or {}; updateLabel() end,
        refresh = rebuildOptions,
    }
end

local function addTextInput(section, placeholder, callback)
    callback = callback or function() end
    local frame = new("Frame", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.bg3,
        BackgroundTransparency = 0.3, LayoutOrder = #section:GetChildren(), Parent = section,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
    new("UIStroke", { 
        Color = C.border, 
        Thickness = 1, 
        Transparency = 0.6,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = frame 
    })
    local tb = new("TextBox", {
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = "", PlaceholderText = placeholder,
        PlaceholderColor3 = C.textDim, TextColor3 = C.text, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
        Parent = frame,
    })
    tb.FocusLost:Connect(function(enterPressed)
        if enterPressed and tb.Text ~= "" then
            callback(tb.Text)
            tb.Text = ""
        end
    end)
    return {
        getText = function() return tb.Text end,
        setText = function(v) tb.Text = v end,
        frame = frame,
    }
end

local function addButton(section, name, callback)
    callback = callback or function() end
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.accent,
        BackgroundTransparency = 0.88, Text = name,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = C.text,
        AutoButtonColor = false, LayoutOrder = #section:GetChildren(), Parent = section,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })
    new("UIStroke", {
        Color = C.accent, Thickness = 1, Transparency = 0.4,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = btn,
    })
    btn.MouseEnter:Connect(function() 
        tw(btn, { BackgroundTransparency = 0.75 }, 0.12) 
    end)
    btn.MouseLeave:Connect(function() 
        tw(btn, { BackgroundTransparency = 0.88 }, 0.12) 
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function addLabel(section, text)
    return new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1,
        Text = text, TextColor3 = C.textDim, TextSize = 10,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })
end

local function addSeparator(section)
    local sep = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0, BorderSizePixel = 0,
        LayoutOrder = #section:GetChildren(), Parent = section,
    })
    new("UIGradient", {
        Color = ColorSequence.new(C.border, C.border),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.7),
            NumberSequenceKeypoint.new(0.5, 0.3),
            NumberSequenceKeypoint.new(1, 0.7),
        }),
        Parent = sep,
    })
end

do
    local SQ = 120
    local BARW = 18
    local PAD = 8
    local PW = SQ + BARW + PAD * 3
    local PH = SQ + PAD * 2

    local cpHue, cpSat, cpVal = 0, 1, 1
    local cpCallback = nil
    local cpDotRef = nil

    local cpPanel = new("Frame", {
        Name = "ColorPickerPanel",
        Size = UDim2.new(0, PW, 0, PH),
        BackgroundColor3 = C.bg2, Visible = false,
        ZIndex = 90, Parent = dropLayer,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = cpPanel })
    new("UIStroke", { Color = C.border, Thickness = 1, Parent = cpPanel })

    local svBox = new("Frame", {
        Position = UDim2.new(0, PAD, 0, PAD), Size = UDim2.new(0, SQ, 0, SQ),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1), ClipsDescendants = true,
        ZIndex = 91, Parent = cpPanel,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 4), Parent = svBox })

    local whiteOL = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1),
        ZIndex = 92, Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = whiteOL,
    })
    local blackOL = new("Frame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 93, Parent = svBox,
    })
    new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90, Parent = blackOL,
    })

    local svThumb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 12, 0, 12), BackgroundTransparency = 1,
        ZIndex = 95, Parent = svBox,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = svThumb })
    new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = svThumb })

    local hueBar = new("Frame", {
        Position = UDim2.new(0, PAD + SQ + PAD, 0, PAD),
        Size = UDim2.new(0, BARW, 0, SQ), ClipsDescendants = true,
        ZIndex = 91, Parent = cpPanel,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 9), Parent = hueBar })
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
            ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1, 1)),
            ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1, 1)),
            ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1, 1)),
            ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1, 1)),
            ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1, 1)),
        }),
        Rotation = 90, Parent = hueBar,
    })

    local hueThumb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, BARW + 4, 0, 10), BackgroundTransparency = 1,
        ZIndex = 95, Parent = hueBar,
    })
    new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueThumb })
    new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = hueThumb })

    local function cpUpdateVisuals()
        svBox.BackgroundColor3 = Color3.fromHSV(cpHue, 1, 1)
        svThumb.Position = UDim2.new(cpSat, 0, 1 - cpVal, 0)
        hueThumb.Position = UDim2.new(0.5, 0, cpHue, 0)
    end

    local function cpFireColor()
        local c = Color3.fromHSV(cpHue, cpSat, cpVal)
        if cpCallback then cpCallback(c) end
        if cpDotRef then cpDotRef.BackgroundColor3 = c end
    end

    svBox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local function onMove(inp)
                local ax, ay = svBox.AbsolutePosition.X, svBox.AbsolutePosition.Y
                local aw, ah = svBox.AbsoluteSize.X, svBox.AbsoluteSize.Y
                cpSat = math.clamp((inp.Position.X - ax) / aw, 0, 1)
                cpVal = 1 - math.clamp((inp.Position.Y - ay) / ah, 0, 1)
                cpUpdateVisuals()
                cpFireColor()
            end
            activeSlider = onMove
            onMove(input)
        end
    end)

    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local function onMove(inp)
                local ay = hueBar.AbsolutePosition.Y
                local ah = hueBar.AbsoluteSize.Y
                cpHue = math.clamp((inp.Position.Y - ay) / ah, 0, 0.999)
                cpUpdateVisuals()
                cpFireColor()
            end
            activeSlider = onMove
            onMove(input)
        end
    end)

    local function cpClose()
        cpPanel.Visible = false
        cpCallback = nil
        cpDotRef = nil
    end
    closeColorPicker = cpClose

    openColorPicker = function(dotBtn, currentColor, onChange)
        if cpPanel.Visible and cpDotRef == dotBtn then
            cpClose()
            return
        end

        if openDropdown then openDropdown.close(); openDropdown = nil end

        cpCallback = onChange
        cpDotRef = dotBtn
        cpHue, cpSat, cpVal = Color3.toHSV(currentColor)
        cpUpdateVisuals()

        local ap = dotBtn.AbsolutePosition
        cpPanel.Position = UDim2.new(0, ap.X - PW - 4, 0, ap.Y - PH / 2 + 7)
        cpPanel.Visible = true
    end
end

local wmGui = Instance.new("ScreenGui")
wmGui.Name = "NixwareWM"
wmGui.ResetOnSpawn = false
wmGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
wmGui.DisplayOrder = 999998
wmGui.IgnoreGuiInset = true
wmGui.Enabled = false
pcall(protect_gui, wmGui)
wmGui.Parent = guiRoot

local wmDragging = false
local wmDragStart, wmFrameStart

local wmHolder = new("Frame", {
    Name = "WmHolder", Position = UDim2.new(0, 10, 0, 48),
    Size = UDim2.new(0, 260, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Parent = wmGui,
})

local wmBar = new("Frame", {
    Name = "WmBar", Size = UDim2.new(1, 0, 0, 32),
    BackgroundColor3 = Color3.fromRGB(14, 14, 18), 
    BackgroundTransparency = 0,
    BorderSizePixel = 0, Parent = wmHolder,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = wmBar })

new("UIStroke", { 
    Color = C.accent, 
    Thickness = 1.5, 
    Transparency = 0.4,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = wmBar 
})

local wmGradient = new("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.97,
    BorderSizePixel = 0, ZIndex = 1,
    Parent = wmBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = wmGradient })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, C.accent),
    }),
    Rotation = 90,
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.5, 1),
        NumberSequenceKeypoint.new(1, 0.85),
    }),
    Parent = wmGradient,
})

local wmAccent = new("Frame", {
    Size = UDim2.new(0, 4, 1, 0),
    BackgroundColor3 = C.accent,
    BorderSizePixel = 0, ZIndex = 3,
    Parent = wmBar,
})
new("UICorner", { CornerRadius = UDim.new(0, 8), Parent = wmAccent })
new("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accentDark),
        ColorSequenceKeypoint.new(0.5, C.accent),
        ColorSequenceKeypoint.new(1, C.accentDark),
    }),
    Rotation = 90,
    Parent = wmAccent,
})

local wmLabel = new("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1, RichText = true,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.text,
    ZIndex = 2, Parent = wmBar,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 5), PaddingRight = UDim.new(0, 14),
    PaddingBottom = UDim.new(0, 5), PaddingLeft = UDim.new(0, 12),
    Parent = wmLabel,
})

local wmFpsBuf, wmLastUpdate = {}, 0
local acHex = hexColor(C.accent)
local dimHex = hexColor(C.textDim)

RS.Heartbeat:Connect(function(dt)
    table.insert(wmFpsBuf, 1 / dt)
    if #wmFpsBuf > 60 then table.remove(wmFpsBuf, 1) end
    local now = tick()
    if now - wmLastUpdate < 0.4 then return end
    wmLastUpdate = now

    local avg = 0
    for _, v in ipairs(wmFpsBuf) do avg = avg + v end
    avg = math.floor(avg / math.max(#wmFpsBuf, 1))

    local ping = 0
    pcall(function() ping = math.floor(player:GetNetworkPing() * 1000) end)

    wmLabel.Text = string.format(
        '<font color="#%s">NIXWARE</font> <font color="#%s">�</font> %s <font color="#%s">�</font> %d fps <font color="#%s">�</font> %dms',
        acHex, dimHex, player.Name, dimHex, avg, dimHex, ping
    )
end)

wmBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        wmDragging = true
        wmDragStart = input.Position
        wmFrameStart = wmHolder.Position
    end
end)

local kbFrame = new("Frame", {
    Name = "KB", Size = UDim2.new(0, 180, 0, 0),
    Position = UDim2.new(0, 0, 0, 38),
    BackgroundColor3 = C.bg, BackgroundTransparency = 0.05,
    ClipsDescendants = true, Parent = wmHolder,
})
new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = kbFrame })
new("UIStroke", { 
    Color = C.borderLight, 
    Thickness = 1, 
    Transparency = 0.4,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Parent = kbFrame 
})

local kbAccLine = new("Frame", {
    Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0, ZIndex = 2, Parent = kbFrame,
})
new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = kbAccLine })
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.85),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 0.85),
    }),
    Parent = kbAccLine,
})

new("TextLabel", {
    Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 14, 0, 4),
    BackgroundTransparency = 1, Text = "keybinds",
    Font = Enum.Font.GothamBold, TextSize = 10,
    TextColor3 = C.textDim, TextTransparency = 0.3,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = kbFrame,
})

local kbList = new("Frame", {
    Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 28),
    BackgroundTransparency = 1, Parent = kbFrame,
})
new("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 0), Parent = kbList,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 0), PaddingRight = UDim.new(0, 12),
    PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 12),
    Parent = kbList,
})

refreshKB = function()
    for _, ch in ipairs(kbList:GetChildren()) do
        if ch:IsA("TextLabel") then ch:Destroy() end
    end
    local n = 0
    for _, e in ipairs(kbEntries) do
        if e.active and e.key then
            n = n + 1
            new("TextLabel", {
                Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1,
                RichText = true,
                Text = string.format('<font color="#%s">[%s]</font>  %s', hexColor(C.accent), kname(e.key), e.name),
                Font = Enum.Font.GothamMedium, TextSize = 11,
                TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder = n, Parent = kbList,
            })
        end
    end
    kbList.Size = UDim2.new(1, 0, 0, n * 20)
    local totalH = n > 0 and (28 + n * 20 + 8) or 0
    tw(kbFrame, { Size = UDim2.new(0, 180, 0, totalH) }, 0.15)
    kbFrame.Visible = n > 0
end

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local flags = ReplicatedStorage:FindFirstChild("QuantumMovementFlags")
if not flags then
    flags = Instance.new("Folder")
    flags.Name = "QuantumMovementFlags"
    flags.Parent = ReplicatedStorage
end
do
    local function getString(name, default)
        local v = flags:FindFirstChild(name)
        if not v then
            v = Instance.new("StringValue")
            v.Name = name
            v.Value = default or ""
            v.Parent = flags
        end
        return v
    end
    getString("MenuBind", "Delete")
end

local NotificationSystem = {}
NotificationSystem.__index = NotificationSystem

function NotificationSystem.new()
    local self = setmetatable({}, NotificationSystem)
    
    self.notifications = {}
    self.container = new("Frame", {
        Name = "NotificationContainer",
        Position = UDim2.new(1, -320, 0, 10),
        Size = UDim2.new(0, 310, 1, -20),
        BackgroundTransparency = 1,
        ZIndex = 100,
        Parent = guiRoot,
    })
    
    self.layout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        Parent = self.container,
    })
    
    return self
end

function NotificationSystem:Notify(config)
    local title = config.title or "Notification"
    local message = config.message or ""
    local duration = config.duration or 3
    local type = config.type or "info"
    
    local notif = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.bg2,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = #self.notifications + 1,
        Parent = self.container,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = notif })
    
    local accentColor = C.accent
    if type == "success" then accentColor = Color3.fromRGB(100, 255, 150)
    elseif type == "warning" then accentColor = Color3.fromRGB(255, 200, 100)
    elseif type == "error" then accentColor = Color3.fromRGB(255, 100, 100)
    end
    
    local accentBar = new("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accentColor,
        BorderSizePixel = 0,
        Parent = notif,
    })
    new("UICorner", { CornerRadius = UDim.new(0, 3), Parent = accentBar })
    
    local content = new("Frame", {
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -20, 1, -16),
        BackgroundTransparency = 1,
        Parent = notif,
    })
    
    local titleLabel = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = content,
    })
    
    local messageLabel = new("TextLabel", {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 1, -18),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = C.textSec,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Parent = content,
    })
    
    local textHeight = 0
    pcall(function()
        local textService = game:GetService("TextService")
        local textSize = textService:GetTextSize(
            message,
            10,
            Enum.Font.Gotham,
            Vector2.new(content.AbsoluteSize.X, 1000)
        )
        textHeight = math.max(textSize.Y, 16)
    end)
    
    local totalHeight = math.min(math.max(textHeight + 34, 60), 120)
    
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.BackgroundTransparency = 1
    
    pcall(function()
        tw(notif, {
            Size = UDim2.new(1, 0, 0, totalHeight),
            BackgroundTransparency = 0.05,
        }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    
    table.insert(self.notifications, notif)
    
    task.delay(duration, function()
        pcall(function()
            tw(notif, {
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
            }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        end)
        
        task.wait(0.3)
        pcall(function()
            notif:Destroy()
            for i, n in ipairs(self.notifications) do
                if n == notif then
                    table.remove(self.notifications, i)
                    break
                end
            end
        end)
    end)
end

local Notification = NotificationSystem.new()

do
    local _origPrint = print
    local _origWarn = warn
    local blocked = {"Sent", "EPO", "sent"}
    local blockedPatterns = {"KeyframeSequence", "deprecated", "CurveAnimation"}
    print = function(...)
        local args = {...}
        if #args > 0 then
            local first = tostring(args[1])
            for _, b in ipairs(blocked) do
                if first == b then return end
            end
            for _, p in ipairs(blockedPatterns) do
                if first:find(p) then return end
            end
        end
    end
    warn = function(...)
        local args = {...}
        if #args > 0 then
            local first = tostring(args[1])
            for _, b in ipairs(blocked) do
                if first == b then return end
            end
            for _, p in ipairs(blockedPatterns) do
                if first:find(p) then return end
            end
        end
    end
end

pcall(function()
    local RS = game:GetService("ReplicatedStorage")
    
    local inf1 = RS:FindFirstChild("inf1")
    if inf1 and inf1:IsA("RemoteEvent") then
        inf1.OnClientEvent:Connect(function(...) 
        end)
    end
    
    local inf2 = RS:FindFirstChild("inf2")
    if inf2 and inf2:IsA("RemoteEvent") then
        inf2.OnClientEvent:Connect(function(...) 
        end)
    end
    
    RS.ChildAdded:Connect(function(child)
        if (child.Name == "inf1" or child.Name == "inf2") and child:IsA("RemoteEvent") then
            task.wait(0.1)
            pcall(function()
                child.OnClientEvent:Connect(function(...) 
                end)
            end)
        end
    end)
    
    for _, remote in ipairs(RS:GetDescendants()) do
        if remote:IsA("RemoteEvent") then
            pcall(function()
                remote.OnClientEvent:Connect(function(...) end)
            end)
        end
    end
    
    RS.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("RemoteEvent") then
            task.wait(0.1)
            pcall(function()
                descendant.OnClientEvent:Connect(function(...) end)
            end)
        end
    end)
end)

local function safeLoad(url, name)
    local src
    local ok, err = pcall(function()
        src = game:HttpGet(url)
    end)
    if not ok or not src or src == "" then
        return nil
    end
    local fn, loadErr = loadstring(src)
    if not fn then
        return nil
    end
    local success, result = pcall(fn)
    if not success then
        return nil
    end
    return result
end

UIS.InputChanged:Connect(function(input)
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        pcall(function() activeSlider(input) end)
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        activeSlider = nil
    end
end)

    return {
        GUI = gui,
        Holder = holder,
        Main = main,
        TitleBar = titleBar,
        CloseBtn = closeBtn,
        MinimizeBtn = minimizeBtn,
        CloseSearchModal = closeSearchModal,
        CloseActiveDropdown = closeActiveDropdown,
        WatermarkGUI = wmGui,
        WatermarkHolder = wmHolder,
        WingGUI = wingGui,
        WingImage = leftWing,
        UIScale = uiScale,
        UseCG = useCG,
        LoadingLogo = ldLogo,
        LoadingLogoScale = ldLogoScale,
        LoadingLine = ldLine,
        LoadingSub = ldSub,
        LoadingVer = ldVer,
        LoadingBarBg = ldBarBg,
        LoadingFill = ldFill,
        AddTab = addTab,
        AddTabLabel = addTabLabel,
        AddSection = addSection,
        AddToggle = addToggle,
        AddSlider = addSlider,
        AddDropdown = addDropdown,
        AddMultiDropdown = addMultiDropdown,
        AddTextInput = addTextInput,
        AddButton = addButton,
        AddLabel = addLabel,
        AddSeparator = addSeparator,
        SwitchTab = switchTab,
        KeybindEntries = kbEntries,
        RefreshKeybinds = refreshKB,
        Theme = C,
        Icons = Icons,
        Notification = Notification,
        New = new,
        Tween = tw,
        KeyName = kname,
        Show = function()
            panelOpen = true
            holder.Visible = true
            wmGui.Enabled = true
            -- wing removed
            if useCG then tw(holder, { GroupTransparency = 0 }, 0.3) end
        end,
        Hide = function()
            panelOpen = false
            if useCG then tw(holder, { GroupTransparency = 1 }, 0.25); task.wait(0.25) end
            holder.Visible = false
            wmGui.Enabled = false
            -- wing removed
        end,
        Toggle = function()
            if panelOpen then self.Hide() else self.Show() end
        end,
    }
end

return UILibrary
