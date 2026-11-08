--// kotik_hub main (v21)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local FILE = "kotik_hub.json"
local IMAGE_FILE = "kotik.png"
local IMAGE_ID = ""
local MENU_KEY = Enum.KeyCode.RightShift
local CHINESE_CHARS = {"龙","虎","猫","狗","水","火","木","金","土","风","雨","云","山","海","星","月","日","光","暗","心","力","剑","刀","弓","箭","血","魂","神","魔","道"}

--// ============================================
--// НАСТРОЙКИ
--// ============================================
local DEFAULTS = {
    esp = false, espBox = false, espName = false, espTracer = false, espDist = false, espTeam = false,
    espRainbow = false, espRainSpeed = 3,
    espR = 255, espG = 255, espB = 255,
    espThick = 2, boxThick = 2,
    fovOn = false, fov = 90,
    fullbright = false, clockTime = false, timeValue = 14, fogOff = false,
    fpsBoost = false,
    speedOn = false, speed = 32,
    jumpOn = false, jump = 100,
    noAnim = false,
    spin = false, spinSpeed = 20, spinMode = 1,
    fastRespawn = false,
    hitboxOn = false, hitboxMul = 10,
    flingOn = false, flingPower = 1000, flingMode = 1, flingRange = 3,
    aimbot = false, aimKey = 1, aimPart = 2, aimSmooth = 5, aimFov = 150,
    aimDraw = true, aimTeam = true, aimTarget = "",
    dodgeOn = false, dodgeSpeed = 60, dodgeDist = 8, dodgeKey = 1,
    ghost = false, ghostHeight = 500,
    antiTp = false, antiTpDist = 40,
    fly = false, flySpeed = 60, noclip = false, infJump = false, bhop = false,
    gravityOn = false, gravityValue = 100,
    tpLook = false, clickTp = false,
    savedX = 0, savedY = 0, savedZ = 0, tpToPoint = false,
    musicOn = false, musicId = "1837879082", musicVol = 5, musicLoop = true,
    musicSpeed = 1, musicPitch = 1, musicLocal = true,
    accRecolor = false, accR = 255, accG = 0, accB = 255, accNeon = false,
    bodyRecolor = false, bodyR = 0, bodyG = 255, bodyB = 255,
    shiftLock = false, shiftLockAngle = 90, shiftLockMode = 1, shiftLockSmooth = 1,
    hvhOn = false, hvhMode = 1, hvhRange = 50, hvhSmooth = 1,
    menuOpen = true, tab = 1,
}

local cfg = {}
for k, v in pairs(DEFAULTS) do cfg[k] = v end

local saveQueued = false
local function save()
    if saveQueued then return end
    saveQueued = true
    task.delay(0.5, function()
        saveQueued = false
        pcall(function()
            if writefile then writefile(FILE, HttpService:JSONEncode(cfg)) end
        end)
    end)
end

pcall(function()
    if isfile and isfile(FILE) then
        local data = HttpService:JSONDecode(readfile(FILE))
        for k, v in pairs(data) do
            if cfg[k] ~= nil and type(v) == type(cfg[k]) then cfg[k] = v end
        end
    end
end)

local env = (getgenv and getgenv()) or _G
if env.kotik_unload then pcall(env.kotik_unload) end

local conns = {}
local function bind(signal, fn)
    local c = signal:Connect(fn)
    conns[#conns + 1] = c
    return c
end

--// ============ ОБЩЕЕ ============
local function getChar() return LocalPlayer.Character end
local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local lastPos
local ghostPart, ghostCF
local ghostRestore
local noclipOrig = {}
local bodyOrigColor = {}
local bodyOrigMat = {}

local function noclipRestore()
    for part, orig in pairs(noclipOrig) do
        if part.Parent then part.CanCollide = orig end
    end
    noclipOrig = {}
end

local function restore()
    local h, hrp, c = getHum(), getHRP(), getChar()
    if h then
        h.WalkSpeed = 16
        h.UseJumpPower = true
        h.JumpPower = 50
        h.AutoRotate = true
    end
    if hrp then hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end
    local a = c and c:FindFirstChild("Animate")
    if a then a.Disabled = false end
    noclipRestore()
    for part, orig in pairs(bodyOrigColor) do
        if part.Parent then
            part.Color = orig
            part.Material = bodyOrigMat[part] or Enum.Material.Plastic
        end
    end
    bodyOrigColor = {}
    bodyOrigMat = {}
    Camera.FieldOfView = 70
    pcall(function() workspace.Gravity = 196.2 end)
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    Lighting.Brightness = 1
end

--// ============ ТЕЛЕПОРТЫ ============
local function prepTp()
    if ghostRestore then ghostRestore() end
    return getHRP()
end

local function teleportTo(cf)
    local hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = cf
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    lastPos = cf.Position
end

local function tpOffset(x, y, z, world)
    local hrp = prepTp()
    if not hrp then return false end
    local cf = world and (hrp.CFrame + Vector3.new(x, y, z)) or (hrp.CFrame * CFrame.new(x, y, z))
    teleportTo(cf)
    return true
end

local function tpNearest()
    local hrp = prepTp()
    if not hrp then return false end
    local best, bestD
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local c = plr.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local hh = c and c:FindFirstChildOfClass("Humanoid")
            if r and hh and hh.Health > 0 then
                local d = (r.Position - hrp.Position).Magnitude
                if not bestD or d < bestD then best, bestD = r, d end
            end
        end
    end
    if best then
        teleportTo(best.CFrame * CFrame.new(0, 0, 4))
        return true
    end
    return false
end

local function tpSpawn()
    local hrp = prepTp()
    if not hrp then return false end
    local spawn = LocalPlayer.RespawnLocation
    if not spawn then
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("SpawnLocation") then spawn = d break end
        end
    end
    if spawn then
        teleportTo(spawn.CFrame + Vector3.new(0, 5, 0))
        return true
    end
    return false
end

--// ============ GUI ============
local guiParent = (gethui and gethui()) or game:GetService("CoreGui")
local gui = Instance.new("ScreenGui")
gui.Name = "kotik_hub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
gui.Parent = guiParent

local C_BG = Color3.fromRGB(0, 0, 0)
local C_PANEL = Color3.fromRGB(18, 18, 18)
local C_TAB_ON = Color3.fromRGB(45, 45, 45)
local C_WHITE = Color3.fromRGB(255, 255, 255)
local C_GREEN = Color3.fromRGB(80, 255, 120)

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
end
local function stroke(obj)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(70, 70, 70)
    s.Thickness = 1
    s.Parent = obj
end

local function makeDraggable(handle, target, onClick)
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    bind(handle.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragStart, startPos = true, false, i.Position, target.Position
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    bind(UIS.InputEnded, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved and onClick then onClick() end
        end
    end)
end

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 330, 0, 400)
main.Position = UDim2.new(0, 76, 0.5, -200)
main.BackgroundColor3 = C_BG
main.BorderSizePixel = 0
main.Visible = cfg.menuOpen
main.ClipsDescendants = true
main.Parent = gui
corner(main, 8)
stroke(main)

-- летающие китайские символы в основном меню
local menuFloating = {}
local menuFloatConn
local function spawnMenuChar()
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 26, 0, 26)
    lbl.BackgroundTransparency = 1
    lbl.Text = CHINESE_CHARS[math.random(#CHINESE_CHARS)]
    lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    lbl.TextTransparency = 0.8
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = math.random(12, 22)
    lbl.Position = UDim2.new(math.random(), 0, 1.1, 0)
    lbl.ZIndex = 0
    lbl.Parent = main
    menuFloating[#menuFloating + 1] = {label = lbl, speed = math.random(6, 15) / 100}
end
for i = 1, 8 do spawnMenuChar() end
menuFloatConn = RunService.RenderStepped:Connect(function(dt)
    if not main.Visible then return end
    for i = #menuFloating, 1, -1 do
        local d = menuFloating[i]
        local lbl = d.label
        if not lbl.Parent then
            table.remove(menuFloating, i)
        else
            local y = lbl.Position.Y.Scale - d.speed * dt
            if y < -0.1 then
                lbl.Position = UDim2.new(math.random(), 0, 1.1, 0)
                lbl.Text = CHINESE_CHARS[math.random(#CHINESE_CHARS)]
            else
                lbl.Position = UDim2.new(lbl.Position.X.Scale, 0, y, 0)
            end
        end
    end
end)

-- иконка-улыбашка
local headerIcon = Instance.new("TextLabel")
headerIcon.Size = UDim2.new(0, 24, 0, 24)
headerIcon.Position = UDim2.new(0, 6, 0, 4)
headerIcon.BackgroundColor3 = C_GREEN
headerIcon.Text = "☺"
headerIcon.TextColor3 = Color3.fromRGB(0, 0, 0)
headerIcon.Font = Enum.Font.GothamBold
headerIcon.TextSize = 20
headerIcon.BorderSizePixel = 0
headerIcon.ZIndex = 2
headerIcon.Parent = main
corner(headerIcon, 12)

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, -40, 0, 32)
header.Position = UDim2.new(0, 32, 0, 0)
header.BackgroundTransparency = 1
header.Text = "kotik_hub  v21"
header.TextColor3 = C_WHITE
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.ZIndex = 2
header.Parent = main

local function setMenu(v)
    main.Visible = v
    cfg.menuOpen = v
    save()
end

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -34, 0, 4)
closeBtn.BackgroundColor3 = C_PANEL
closeBtn.Text = "×"
closeBtn.TextColor3 = C_WHITE
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BorderSizePixel = 0
closeBtn.ZIndex = 2
closeBtn.Parent = main
corner(closeBtn, 6)
bind(closeBtn.MouseButton1Click, function() setMenu(false) end)

makeDraggable(header, main)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, -12, 0, 28)
tabBar.Position = UDim2.new(0, 6, 0, 34)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 2
tabBar.Parent = main
local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 4)
tabLayout.Parent = tabBar

local container = Instance.new("Frame")
container.Size = UDim2.new(1, -12, 1, -72)
container.Position = UDim2.new(0, 6, 0, 66)
container.BackgroundTransparency = 1
container.ZIndex = 2
container.Parent = main

local pageOrder = {}
local function newPage()
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, 0, 1, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 3
    p.CanvasSize = UDim2.new()
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.Visible = false
    p.ZIndex = 2
    p.Parent = container
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = p
    pageOrder[p] = 0
    return p
end
local function nextOrder(p)
    pageOrder[p] = pageOrder[p] + 1
    return pageOrder[p]
end

local tabNames = {"Визуал", "Игрок", "Бой", "HvH", "Защита", "Движ", "Внешка", "Ещё"}
local pages, tabBtns = {}, {}

local function setTab(i)
    cfg.tab = i
    for idx, p in ipairs(pages) do
        p.Visible = (idx == i)
        tabBtns[idx].BackgroundColor3 = (idx == i) and C_TAB_ON or C_PANEL
    end
    save()
end

for i, name in ipairs(tabNames) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1 / #tabNames, -3, 1, 0)
    b.BackgroundColor3 = C_PANEL
    b.Text = name
    b.TextColor3 = C_WHITE
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 9
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = tabBar
    corner(b, 6)
    tabBtns[i] = b
    pages[i] = newPage()
    bind(b.MouseButton1Click, function() setTab(i) end)
end

--// ============ ЭЛЕМЕНТЫ МЕНЮ ============
local uiRefresh = {}

local function addToggle(page, text, key, onChange)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 30)
    b.LayoutOrder = nextOrder(page)
    b.BackgroundColor3 = C_PANEL
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = page
    corner(b, 6)
    stroke(b)
    local function refresh()
        b.Text = text .. ": " .. (cfg[key] and "ON" or "OFF")
        b.TextColor3 = cfg[key] and C_GREEN or C_WHITE
    end
    refresh()
    uiRefresh[#uiRefresh + 1] = refresh
    bind(b.MouseButton1Click, function()
        cfg[key] = not cfg[key]
        refresh()
        if onChange then pcall(onChange, cfg[key]) end
        save()
    end)
    return b
end

local function addSlider(page, text, key, min, max)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -8, 0, 34)
    holder.LayoutOrder = nextOrder(page)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 2
    holder.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.62, -4, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text .. " (" .. min .. "–" .. max .. ")"
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 2
    lbl.Parent = holder

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.38, 0, 1, 0)
    box.Position = UDim2.new(0.62, 0, 0, 0)
    box.BackgroundColor3 = C_PANEL
    box.TextColor3 = C_WHITE
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 14
    box.ClearTextOnFocus = true
    box.BorderSizePixel = 0
    box.ZIndex = 2
    box.Parent = holder
    corner(box, 6)
    stroke(box)

    cfg[key] = math.clamp(tonumber(cfg[key]) or min, min, max)
    box.Text = tostring(cfg[key])
    uiRefresh[#uiRefresh + 1] = function() box.Text = tostring(cfg[key]) end

    bind(box.FocusLost, function()
        local n = tonumber((box.Text:gsub(",", ".")))
        if n then cfg[key] = math.clamp(math.floor(n + 0.5), min, max) end
        box.Text = tostring(cfg[key])
        save()
    end)
end

local function addTextInput(page, text, key, placeholder)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -8, 0, 34)
    holder.LayoutOrder = nextOrder(page)
    holder.BackgroundTransparency = 1
    holder.ZIndex = 2
    holder.Parent = page

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.38, -4, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 12
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 2
    lbl.Parent = holder

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.62, 0, 1, 0)
    box.Position = UDim2.new(0.38, 0, 0, 0)
    box.BackgroundColor3 = C_PANEL
    box.TextColor3 = C_WHITE
    box.Font = Enum.Font.GothamMedium
    box.TextSize = 13
    box.PlaceholderText = placeholder or ""
    box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    box.ClearTextOnFocus = false
    box.BorderSizePixel = 0
    box.Text = tostring(cfg[key] or "")
    box.ZIndex = 2
    box.Parent = holder
    corner(box, 6)
    stroke(box)

    uiRefresh[#uiRefresh + 1] = function() box.Text = tostring(cfg[key]) end
    bind(box.FocusLost, function()
        cfg[key] = box.Text
        save()
    end)
    return box
end

local function addButton(page, text, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 30)
    b.LayoutOrder = nextOrder(page)
    b.BackgroundColor3 = C_PANEL
    b.Text = text
    b.TextColor3 = C_WHITE
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = page
    corner(b, 6)
    stroke(b)
    bind(b.MouseButton1Click, fn)
    return b
end

local function addLabel(page, text, tall)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, tall or 28)
    l.LayoutOrder = nextOrder(page)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(130, 130, 130)
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextWrapped = true
    l.ZIndex = 2
    l.Parent = page
    return l
end

local function addSelector(page, text, key, options)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -8, 0, 30)
    b.LayoutOrder = nextOrder(page)
    b.BackgroundColor3 = C_PANEL
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.BorderSizePixel = 0
    b.ZIndex = 2
    b.Parent = page
    corner(b, 6)
    stroke(b)
    local function refresh()
        b.Text = text .. ": " .. (options[cfg[key]] or options[1])
        b.TextColor3 = C_WHITE
    end
    refresh()
    uiRefresh[#uiRefresh + 1] = refresh
    bind(b.MouseButton1Click, function()
        cfg[key] = (cfg[key] % #options) + 1
        refresh()
        save()
    end)
    return b
end

local function flash(btn, msg)
    local old = btn.Text
    btn.Text = msg
    task.delay(1.5, function()
        if btn.Parent then btn.Text = old end
    end)
end

--// ---- Вкладки ----
addLabel(pages[1], "— ESP —")
addToggle(pages[1], "ESP скелет", "esp")
addToggle(pages[1], "ESP коробка", "espBox")
addToggle(pages[1], "ESP имена и HP", "espName")
addToggle(pages[1], "ESP трассер", "espTracer")
addToggle(pages[1], "ESP дистанция", "espDist")
addToggle(pages[1], "ESP цвет по команде", "espTeam")
addToggle(pages[1], "Радужный ESP", "espRainbow")
addSlider(pages[1], "Скорость радуги", "espRainSpeed", 1, 10)
addSlider(pages[1], "Цвет ESP: красный", "espR", 0, 255)
addSlider(pages[1], "Цвет ESP: зелёный", "espG", 0, 255)
addSlider(pages[1], "Цвет ESP: синий", "espB", 0, 255)
addSlider(pages[1], "Толщина скелета", "espThick", 1, 8)
addSlider(pages[1], "Толщина коробки", "boxThick", 1, 8)
addLabel(pages[1], "— Камера и свет —")
addToggle(pages[1], "FOV", "fovOn", function(on) if not on then Camera.FieldOfView = 70 end end)
addSlider(pages[1], "Угол обзора", "fov", 30, 120)
addToggle(pages[1], "Fullbright", "fullbright")
addToggle(pages[1], "Своё время суток", "clockTime")
addSlider(pages[1], "Час (0-24)", "timeValue", 0, 24)
addToggle(pages[1], "Убрать туман", "fogOff")
addToggle(pages[1], "FPS Boost", "fpsBoost")

addToggle(pages[2], "Скорость", "speedOn", function(on)
    local h = getHum() if h and not on then h.WalkSpeed = 16 end
end)
addSlider(pages[2], "Скорость ходьбы", "speed", 16, 200)
addToggle(pages[2], "Прыжок", "jumpOn", function(on)
    local h = getHum() if h and not on then h.UseJumpPower = true h.JumpPower = 50 end
end)
addSlider(pages[2], "Сила прыжка", "jump", 50, 300)
addToggle(pages[2], "Без анимаций", "noAnim", function(on)
    local c = getChar() local a = c and c:FindFirstChild("Animate")
    if a and not on then a.Disabled = false end
end)
addToggle(pages[2], "Мгновенный респавн", "fastRespawn", function(on)
    if on then local h = getHum() if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Dead) end) end end
end)
addLabel(pages[2], "— Спин —")
addToggle(pages[2], "Спин", "spin", function(on)
    if not on then
        local hrp, h = getHRP(), getHum()
        if hrp then hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0) end
        if h then h.AutoRotate = true end
    end
end)
addSelector(pages[2], "Ось", "spinMode", {"Y", "X", "Z"})
addSlider(pages[2], "Скорость спина (об/сек)", "spinSpeed", 1, 10000)
addLabel(pages[2], "— SHIFT LOCK —")
addToggle(pages[2], "Shift Lock", "shiftLock", function(on)
    local h = getHum() if h then h.AutoRotate = not on end
end)
addSelector(pages[2], "Режим", "shiftLockMode", {"За камерой", "Фикс. угол", "Спиной"})
addSlider(pages[2], "Угол (градусы)", "shiftLockAngle", 0, 360)
addSlider(pages[2], "Плавность", "shiftLockSmooth", 1, 20)
addLabel(pages[2], "— Хитбоксы —")
addToggle(pages[2], "Расширить головы", "hitboxOn")
addSlider(pages[2], "Множитель", "hitboxMul", 2, 50)

addLabel(pages[3], "— Автонаводка —")
addToggle(pages[3], "Aimbot", "aimbot")
addSelector(pages[3], "Кнопка", "aimKey", {"ПКМ", "E", "Q", "Shift", "Всегда"})
addSelector(pages[3], "Часть", "aimPart", {"Head", "Torso", "HRP", "Ближайшая"})
addSlider(pages[3], "Плавность", "aimSmooth", 1, 20)
addSlider(pages[3], "Радиус (пикс.)", "aimFov", 30, 800)
addToggle(pages[3], "Кружок", "aimDraw")
addToggle(pages[3], "Игнор команды", "aimTeam")

local aimTargetBtn, aimDropdownList, aimDropdownOpen = nil, nil, false
local function refreshAimDropdown()
    if not aimDropdownList then return end
    for _, c in ipairs(aimDropdownList:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local autoBtn = Instance.new("TextButton")
    autoBtn.Size = UDim2.new(1, 0, 0, 26)
    autoBtn.BackgroundColor3 = C_PANEL
    autoBtn.Text = "Авто (ближайший)"
    autoBtn.TextColor3 = (cfg.aimTarget == "") and C_GREEN or C_WHITE
    autoBtn.Font = Enum.Font.Gotham
    autoBtn.TextSize = 13
    autoBtn.BorderSizePixel = 0
    autoBtn.ZIndex = 3
    autoBtn.Parent = aimDropdownList
    corner(autoBtn, 4)
    bind(autoBtn.MouseButton1Click, function()
        cfg.aimTarget = ""
        save()
        refreshAimDropdown()
        aimDropdownList.Visible = false
        aimDropdownOpen = false
        if aimTargetBtn then aimTargetBtn.Text = "Цель: Авто" end
    end)
    local count = 1
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 26)
            b.BackgroundColor3 = C_PANEL
            b.Text = plr.Name
            b.TextColor3 = (cfg.aimTarget == plr.Name) and C_GREEN or C_WHITE
            b.Font = Enum.Font.Gotham
            b.TextSize = 13
            b.BorderSizePixel = 0
            b.ZIndex = 3
            b.Parent = aimDropdownList
            corner(b, 4)
            bind(b.MouseButton1Click, function()
                cfg.aimTarget = plr.Name
                save()
                refreshAimDropdown()
                aimDropdownList.Visible = false
                aimDropdownOpen = false
                if aimTargetBtn then aimTargetBtn.Text = "Цель: " .. plr.Name end
            end)
            count = count + 1
        end
    end
    aimDropdownList.CanvasSize = UDim2.new(0, 0, 0, count * 28 + 4)
end
aimTargetBtn = addButton(pages[3], "Цель: Авто", function()
    if not aimDropdownList then
        aimDropdownList = Instance.new("ScrollingFrame")
        aimDropdownList.Size = UDim2.new(1, -8, 0, 150)
        aimDropdownList.LayoutOrder = nextOrder(pages[3])
        aimDropdownList.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        aimDropdownList.BorderSizePixel = 0
        aimDropdownList.ScrollBarThickness = 3
        aimDropdownList.CanvasSize = UDim2.new()
        aimDropdownList.Visible = false
        aimDropdownList.ZIndex = 3
        aimDropdownList.Parent = pages[3]
        corner(aimDropdownList, 6)
        stroke(aimDropdownList)
        local l = Instance.new("UIListLayout")
        l.Padding = UDim.new(0, 2)
        l.SortOrder = Enum.SortOrder.LayoutOrder
        l.Parent = aimDropdownList
    end
    aimDropdownOpen = not aimDropdownOpen
    aimDropdownList.Visible = aimDropdownOpen
    if aimDropdownOpen then refreshAimDropdown() end
end)

addLabel(pages[3], "— Флинг —")
addToggle(pages[3], "Флинг", "flingOn")
addSlider(pages[3], "Сила (1=671, 1000=671488)", "flingPower", 1, 1000)
addSelector(pages[3], "Режим", "flingMode", {"Всех", "Цель"})
addSlider(pages[3], "Радиус", "flingRange", 1, 20)
addLabel(pages[3], "— Уворот —")
addToggle(pages[3], "Уворот", "dodgeOn")
addSelector(pages[3], "Кнопка", "dodgeKey", {"Space+Shift", "Q", "E", "C"})
addSlider(pages[3], "Сила", "dodgeSpeed", 20, 300)
addSlider(pages[3], "Дистанция", "dodgeDist", 3, 50)

addLabel(pages[4], "— HvH —")
addToggle(pages[4], "HvH", "hvhOn", function(on)
    local h = getHum() if h then h.AutoRotate = not on end
end)
addSelector(pages[4], "Режим", "hvhMode", {"Спиной", "Лицом", "Боком +90", "Боком -90"})
addSlider(pages[4], "Дистанция", "hvhRange", 5, 300)
addSlider(pages[4], "Плавность", "hvhSmooth", 1, 30)
addButton(pages[4], "Включить всё для HvH", function()
    cfg.hvhOn = true cfg.aimbot = true cfg.aimKey = 5 cfg.aimPart = 1
    cfg.hitboxOn = true cfg.hitboxMul = 15 cfg.flingOn = true cfg.flingPower = 500
    for _, f in ipairs(uiRefresh) do f() end
    save()
end)
addButton(pages[4], "Выключить HvH", function()
    cfg.hvhOn = false cfg.flingOn = false cfg.hitboxOn = false
    local h = getHum() if h then h.AutoRotate = true end
    for _, f in ipairs(uiRefresh) do f() end
    save()
end)

addToggle(pages[5], "Неприкосайка", "ghost")
addSlider(pages[5], "Высота", "ghostHeight", 200, 1000)
addToggle(pages[5], "Антителепорт", "antiTp")
addSlider(pages[5], "Порог", "antiTpDist", 10, 200)

local function tpButton(text, fn)
    local b = addButton(pages[6], text, function()
        if not fn() then flash(b, "Не получилось") end
    end)
end
tpButton("1. ТП вперёд на 5", function() return tpOffset(0, 0, -5) end)
tpButton("2. ТП вперёд на 10", function() return tpOffset(0, 0, -10) end)
tpButton("3. ТП вперёд на 25", function() return tpOffset(0, 0, -25) end)
tpButton("4. ТП назад на 10", function() return tpOffset(0, 0, 10) end)
tpButton("5. ТП влево на 10", function() return tpOffset(-10, 0, 0) end)
tpButton("6. ТП вправо на 10", function() return tpOffset(10, 0, 0) end)
tpButton("7. ТП вверх на 20", function() return tpOffset(0, 20, 0, true) end)
tpButton("8. ТП к игроку", tpNearest)
tpButton("9. ТП на спавн", tpSpawn)
addToggle(pages[6], "Полёт", "fly")
addSlider(pages[6], "Скорость полёта", "flySpeed", 10, 60000)
addToggle(pages[6], "Ноуклип", "noclip", function(on) if not on then noclipRestore() end end)
addToggle(pages[6], "Inf Jump", "infJump")
addToggle(pages[6], "Bhop", "bhop")
addToggle(pages[6], "Своя гравитация", "gravityOn", function(on)
    if not on then pcall(function() workspace.Gravity = 196.2 end) end
end)
addSlider(pages[6], "Гравитация", "gravityValue", 0, 500)
addToggle(pages[6], "ТП куда смотрю", "tpLook")
addToggle(pages[6], "ТП по клику", "clickTp")
addLabel(pages[6], "— Точка ТП —")
local savePointBtn = addButton(pages[6], "Сохранить точку", function()
    local hrp = getHRP()
    if hrp then
        cfg.savedX = math.floor(hrp.Position.X + 0.5)
        cfg.savedY = math.floor(hrp.Position.Y + 0.5)
        cfg.savedZ = math.floor(hrp.Position.Z + 0.5)
        save()
        flash(savePointBtn, string.format("%d,%d,%d", cfg.savedX, cfg.savedY, cfg.savedZ))
    end
end)
local tpPointBtn = addButton(pages[6], "ТП на точку", function()
    if prepTp() then
        teleportTo(CFrame.new(cfg.savedX, cfg.savedY + 3, cfg.savedZ))
        flash(tpPointBtn, "ТП!")
    end
end)
addToggle(pages[6], "ТП к точке (авто)", "tpToPoint")
local pointInfo = addLabel(pages[6], "", 24)
uiRefresh[#uiRefresh + 1] = function()
    pointInfo.Text = string.format("Точка: %d, %d, %d", cfg.savedX, cfg.savedY, cfg.savedZ)
end
pointInfo.Text = string.format("Точка: %d, %d, %d", cfg.savedX, cfg.savedY, cfg.savedZ)

addLabel(pages[7], "— Музыка —")
addToggle(pages[7], "Играть", "musicOn")
addTextInput(pages[7], "ID", "musicId", "1837879082")
addSlider(pages[7], "Громкость", "musicVol", 0, 10)
addSlider(pages[7], "Скорость", "musicSpeed", 1, 5)
addToggle(pages[7], "Цикл", "musicLoop")
addToggle(pages[7], "Локально", "musicLocal")
addButton(pages[7], "Перезапустить", function() stopMusic() updateMusic() end)
addLabel(pages[7], "— Аксессуары —")
addToggle(pages[7], "Перекрас", "accRecolor")
addSlider(pages[7], "R", "accR", 0, 255)
addSlider(pages[7], "G", "accG", 0, 255)
addSlider(pages[7], "B", "accB", 0, 255)
addToggle(pages[7], "Неон", "accNeon")
addLabel(pages[7], "— Тело —")
addToggle(pages[7], "Перекрас", "bodyRecolor")
addSlider(pages[7], "R", "bodyR", 0, 255)
addSlider(pages[7], "G", "bodyG", 0, 255)
addSlider(pages[7], "B", "bodyB", 0, 255)

addButton(pages[8], "Rejoin", function()
    pcall(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)
end)
addButton(pages[8], "Копировать Job ID", function()
    if setclipboard then setclipboard(tostring(game.JobId)) end
end)
addButton(pages[8], "Копировать позицию", function()
    local hrp = getHRP()
    if hrp and setclipboard then
        setclipboard(string.format("%d, %d, %d", hrp.Position.X, hrp.Position.Y, hrp.Position.Z))
    end
end)
addButton(pages[8], "Убить себя", function()
    local h = getHum() if h then h.Health = 0 end
end)
addButton(pages[8], "Сбросить настройки", function()
    for k, v in pairs(DEFAULTS) do
        if k ~= "menuOpen" and k ~= "tab" and k ~= "savedX" and k ~= "savedY" and k ~= "savedZ" then
            cfg[k] = v
        end
    end
    stopMusic()
    for part, orig in pairs(bodyOrigColor) do if part.Parent then part.Color = orig end end
    bodyOrigColor = {} bodyOrigMat = {}
    restore()
    for _, f in ipairs(uiRefresh) do f() end
    save()
end)
local unloadRef
addButton(pages[8], "Выгрузить", function() if unloadRef then unloadRef() end end)
addLabel(pages[8], "RightShift — меню.", 30)

setTab(math.clamp(cfg.tab, 1, #tabNames))

--// ---- кнопка-фото (улыбашка) ----
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 56, 0, 56)
toggleBtn.Position = UDim2.new(0, 10, 0.5, -28)
toggleBtn.BackgroundColor3 = C_BG
toggleBtn.Text = "☺"
toggleBtn.TextColor3 = C_GREEN
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 32
toggleBtn.BorderSizePixel = 0
toggleBtn.Parent = gui
corner(toggleBtn, 28)
stroke(toggleBtn)
makeDraggable(toggleBtn, toggleBtn, function() setMenu(not main.Visible) end)

bind(UIS.InputBegan, function(i, gp)
    if not gp and i.KeyCode == MENU_KEY then setMenu(not main.Visible) end
end)

--// ============ МУЗЫКА ============
local musicSound
local function stopMusic()
    if musicSound then
        pcall(function() musicSound:Stop() musicSound:Destroy() end)
        musicSound = nil
    end
end
local function updateMusic()
    if not cfg.musicOn then
        if musicSound then stopMusic() end
        return
    end
    local id = tostring(cfg.musicId):gsub("%D", "")
    if id == "" then return end
    local desiredParent = cfg.musicLocal and SoundService or workspace
    if not musicSound then
        musicSound = Instance.new("Sound")
        musicSound.Name = "kotik_music"
        musicSound.Parent = desiredParent
        musicSound.SoundId = "rbxassetid://" .. id
        musicSound.Looped = cfg.musicLoop
        musicSound.Volume = cfg.musicVol / 10
        musicSound.PlaybackSpeed = cfg.musicSpeed
        musicSound:Play()
    else
        if musicSound.Parent ~= desiredParent then musicSound.Parent = desiredParent end
        local newId = "rbxassetid://" .. id
        if musicSound.SoundId ~= newId then
            musicSound.SoundId = newId
            musicSound.TimePosition = 0
        end
        musicSound.Looped = cfg.musicLoop
        musicSound.Volume = cfg.musicVol / 10
        musicSound.PlaybackSpeed = cfg.musicSpeed
        if not musicSound.IsPlaying then pcall(function() musicSound:Play() end) end
    end
end

--// ============ ПЕРЕКРАС ============
local accOrigColor = {}
local accOrigMat = {}
local function updateAccessories()
    local char = getChar()
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Accessory") or d:IsA("Hat") then
            for _, p in ipairs(d:GetDescendants()) do
                if p:IsA("BasePart") then
                    if cfg.accRecolor then
                        if accOrigColor[p] == nil then
                            accOrigColor[p] = p.Color
                            accOrigMat[p] = p.Material
                        end
                        p.Color = Color3.fromRGB(cfg.accR, cfg.accG, cfg.accB)
                        p.Material = cfg.accNeon and Enum.Material.Neon or Enum.Material.SmoothPlastic
                    elseif accOrigColor[p] then
                        p.Color = accOrigColor[p]
                        p.Material = accOrigMat[p] or Enum.Material.SmoothPlastic
                        accOrigColor[p] = nil
                        accOrigMat[p] = nil
                    end
                end
            end
        end
    end
end

local function updateBodyColor()
    local char = getChar()
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
            local isAcc = false
            local parent = d.Parent
            while parent and parent ~= char do
                if parent:IsA("Accessory") or parent:IsA("Hat") then isAcc = true break end
                parent = parent.Parent
            end
            if not isAcc then
                if cfg.bodyRecolor then
                    if bodyOrigColor[d] == nil then
                        bodyOrigColor[d] = d.Color
                        bodyOrigMat[d] = d.Material
                    end
                    d.Color = Color3.fromRGB(cfg.bodyR, cfg.bodyG, cfg.bodyB)
                    d.Material = Enum.Material.Neon
                elseif bodyOrigColor[d] then
                    d.Color = bodyOrigColor[d]
                    d.Material = bodyOrigMat[d] or Enum.Material.Plastic
                    bodyOrigColor[d] = nil
                    bodyOrigMat[d] = nil
                end
            end
        end
    end
end

--// ============ SHIFT LOCK ============
local shiftLockCurrent = nil
local function updateShiftLock()
    if not cfg.shiftLock then shiftLockCurrent = nil return end
    local hrp, h = getHRP(), getHum()
    if not hrp or not h then return end
    h.AutoRotate = false
    local camLook = Camera.CFrame.LookVector
    local targetAngle
    if cfg.shiftLockMode == 1 then
        targetAngle = math.atan2(-camLook.X, -camLook.Z)
    elseif cfg.shiftLockMode == 2 then
        targetAngle = math.atan2(-camLook.X, -camLook.Z) + math.rad(cfg.shiftLockAngle)
    elseif cfg.shiftLockMode == 3 then
        targetAngle = math.atan2(-camLook.X, -camLook.Z) + math.pi
    end
    if targetAngle then
        local current = shiftLockCurrent or math.atan2(-hrp.CFrame.LookVector.X, -hrp.CFrame.LookVector.Z)
        local diff = targetAngle - current
        while diff > math.pi do diff = diff - 2 * math.pi end
        while diff < -math.pi do diff = diff + 2 * math.pi end
        local smooth = math.max(1, cfg.shiftLockSmooth)
        local newY = current + diff / smooth
        shiftLockCurrent = newY
        hrp.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, newY, 0)
    end
end

--// ============ HvH ============
local hvhCurrentAngle = nil
local function updateHvH()
    if not cfg.hvhOn then hvhCurrentAngle = nil return end
    local hrp, h = getHRP(), getHum()
    if not hrp or not h then return end
    h.AutoRotate = false
    local myPos = hrp.Position
    local nearest, nearestD
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not (cfg.aimTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
                local char = plr.Character
                local tHRP = char and char:FindFirstChild("HumanoidRootPart")
                local tHum = char and char:FindFirstChildOfClass("Humanoid")
                if tHRP and tHum and tHum.Health > 0 then
                    local d = (tHRP.Position - myPos).Magnitude
                    if not nearestD or d < nearestD then
                        nearest, nearestD = tHRP, d
                    end
                end
            end
        end
    end
    if not nearest or nearestD > cfg.hvhRange then return end
    local angleToEnemy = math.atan2(-(nearest.Position.X - myPos.X), -(nearest.Position.Z - myPos.Z))
    local targetAngle = angleToEnemy
    if cfg.hvhMode == 1 then
        targetAngle = angleToEnemy + math.pi
    elseif cfg.hvhMode == 3 then
        targetAngle = angleToEnemy + math.pi / 2
    elseif cfg.hvhMode == 4 then
        targetAngle = angleToEnemy - math.pi / 2
    end
    local current = hvhCurrentAngle or math.atan2(-hrp.CFrame.LookVector.X, -hrp.CFrame.LookVector.Z)
    local diff = targetAngle - current
    while diff > math.pi do diff = diff - 2 * math.pi end
    while diff < -math.pi do diff = diff + 2 * math.pi end
    local smooth = math.max(1, cfg.hvhSmooth)
    local newAngle = current + diff / smooth
    hvhCurrentAngle = newAngle
    hrp.CFrame = CFrame.new(hrp.CFrame.Position) * CFrame.Angles(0, newAngle, 0)
end

--// ============ ESP ============
local R15 = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
    {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
    {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"},
}
local R6 = {
    {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
    {"Torso", "Left Leg"}, {"Torso", "Right Leg"},
}
local hasDrawing = (Drawing ~= nil and Drawing.new ~= nil)
local drawings = {}

local function hidePlayer(plr)
    local t = drawings[plr]
    if t then
        for _, l in ipairs(t.lines) do l.Visible = false end
        if t.box then t.box.Visible = false end
        if t.text then t.text.Visible = false end
        if t.tracer then t.tracer.Visible = false end
        if t.dist then t.dist.Visible = false end
    end
end

local function clearPlayer(plr)
    local t = drawings[plr]
    if t then
        for _, l in ipairs(t.lines) do pcall(function() l:Remove() end) end
        if t.box then pcall(function() t.box:Remove() end) end
        if t.text then pcall(function() t.text:Remove() end) end
        if t.tracer then pcall(function() t.tracer:Remove() end) end
        if t.dist then pcall(function() t.dist:Remove() end) end
        drawings[plr] = nil
    end
end
bind(Players.PlayerRemoving, clearPlayer)

local function getEspColor()
    if cfg.espRainbow then
        return Color3.fromHSV((tick() * cfg.espRainSpeed * 0.1) % 1, 1, 1)
    end
    return Color3.fromRGB(cfg.espR, cfg.espG, cfg.espB)
end

local function getBox2D(char)
    local cf, size = char:GetBoundingBox()
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for ix = -1, 1, 2 do
        for iy = -1, 1, 2 do
            for iz = -1, 1, 2 do
                local c3 = cf * Vector3.new(size.X / 2 * ix, size.Y / 2 * iy, size.Z / 2 * iz)
                local p = Camera:WorldToViewportPoint(c3)
                if p.Z <= 0 then return nil end
                minX = math.min(minX, p.X) minY = math.min(minY, p.Y)
                maxX = math.max(maxX, p.X) maxY = math.max(maxY, p.Y)
            end
        end
    end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

local function updateESP()
    local anyEsp = cfg.esp or cfg.espBox or cfg.espName or cfg.espTracer or cfg.espDist
    local myHRP = getHRP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if anyEsp and hasDrawing and char and hum and hum.Health > 0 then
                drawings[plr] = drawings[plr] or {lines = {}}
                local t = drawings[plr]
                local color = getEspColor()
                if cfg.espTeam and LocalPlayer.Team then
                    color = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 50, 50)
                end
                if cfg.esp then
                    local bones = char:FindFirstChild("UpperTorso") and R15 or R6
                    for idx, pair in ipairs(bones) do
                        local line = t.lines[idx]
                        if not line then
                            line = Drawing.new("Line")
                            t.lines[idx] = line
                        end
                        line.Color = color
                        line.Thickness = cfg.espThick
                        local a, b = char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])
                        if a and b then
                            local pa, va = Camera:WorldToViewportPoint(a.Position)
                            local pb, vb = Camera:WorldToViewportPoint(b.Position)
                            if va and vb then
                                line.From = Vector2.new(pa.X, pa.Y)
                                line.To = Vector2.new(pb.X, pb.Y)
                                line.Visible = true
                            else
                                line.Visible = false
                            end
                        else
                            line.Visible = false
                        end
                    end
                    for idx = #bones + 1, #t.lines do t.lines[idx].Visible = false end
                else
                    for _, l in ipairs(t.lines) do l.Visible = false end
                end
                if cfg.espBox then
                    if not t.box then
                        local sq = Drawing.new("Square")
                        sq.Filled = false
                        t.box = sq
                    end
                    local pos, size = getBox2D(char)
                    if pos then
                        t.box.Position = pos
                        t.box.Size = size
                        t.box.Color = color
                        t.box.Thickness = cfg.boxThick
                        t.box.Visible = true
                    else
                        t.box.Visible = false
                    end
                elseif t.box then
                    t.box.Visible = false
                end
                if cfg.espName then
                    if not t.text then
                        local tx = Drawing.new("Text")
                        tx.Size = 14
                        tx.Center = true
                        tx.Outline = true
                        t.text = tx
                    end
                    t.text.Color = color
                    local head = char:FindFirstChild("Head")
                    if head then
                        local p, v = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.5, 0))
                        if v then
                            t.text.Text = plr.Name .. " [" .. math.floor(hum.Health) .. "]"
                            t.text.Position = Vector2.new(p.X, p.Y - 14)
                            t.text.Visible = true
                        else
                            t.text.Visible = false
                        end
                    else
                        t.text.Visible = false
                    end
                elseif t.text then
                    t.text.Visible = false
                end
                if cfg.espTracer then
                    if not t.tracer then
                        t.tracer = Drawing.new("Line")
                        t.tracer.Thickness = cfg.espThick
                    end
                    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
                    if hrp then
                        local p, v = Camera:WorldToViewportPoint(hrp.Position)
                        if v then
                            local scr = Camera.ViewportSize
                            t.tracer.From = Vector2.new(scr.X / 2, scr.Y)
                            t.tracer.To = Vector2.new(p.X, p.Y)
                            t.tracer.Color = color
                            t.tracer.Visible = true
                        else
                            t.tracer.Visible = false
                        end
                    else
                        t.tracer.Visible = false
                    end
                elseif t.tracer then
                    t.tracer.Visible = false
                end
                if cfg.espDist then
                    if not t.dist then
                        t.dist = Drawing.new("Text")
                        t.dist.Size = 12
                        t.dist.Center = true
                        t.dist.Outline = true
                    end
                    local head = char:FindFirstChild("Head")
                    if head and myHRP then
                        local p, v = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
                        if v then
                            t.dist.Text = string.format("[%d studs]", math.floor((head.Position - myHRP.Position).Magnitude))
                            t.dist.Position = Vector2.new(p.X, p.Y)
                            t.dist.Color = color
                            t.dist.Visible = true
                        else
                            t.dist.Visible = false
                        end
                    else
                        t.dist.Visible = false
                    end
                elseif t.dist then
                    t.dist.Visible = false
                end
            else
                hidePlayer(plr)
            end
        end
    end
end

--// ============ ХИТБОКСЫ ============
local function updateHitboxes()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            local head = char and char:FindFirstChild("Head")
            if head then
                if cfg.hitboxOn then
                    if not head:GetAttribute("kotik_origSize") then
                        head:SetAttribute("kotik_origSize", head.Size)
                        head:SetAttribute("kotik_origTrans", head.Transparency)
                    end
                    local orig = head:GetAttribute("kotik_origSize")
                    if orig then
                        head.Size = orig * cfg.hitboxMul
                        head.Transparency = 0.5
                        head.CanCollide = false
                        head.Massless = true
                    end
                elseif head:GetAttribute("kotik_origSize") then
                    head.Size = head:GetAttribute("kotik_origSize")
                    head.Transparency = head:GetAttribute("kotik_origTrans") or 0
                    head.CanCollide = true
                    head.Massless = false
                    head:SetAttribute("kotik_origSize", nil)
                    head:SetAttribute("kotik_origTrans", nil)
                end
            end
        end
    end
end

--// ============ АВТОНАВОДКА ============
local aimCircle
if hasDrawing then
    aimCircle = Drawing.new("Circle")
    aimCircle.Thickness = 1
    aimCircle.NumSides = 60
    aimCircle.Filled = false
    aimCircle.Color = Color3.fromRGB(255, 255, 255)
    aimCircle.Transparency = 0.7
    aimCircle.Visible = false
end

local function isAimKeyDown()
    if cfg.aimKey == 5 then return true end
    if cfg.aimKey == 1 then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
    if cfg.aimKey == 2 then return UIS:IsKeyDown(Enum.KeyCode.E) end
    if cfg.aimKey == 3 then return UIS:IsKeyDown(Enum.KeyCode.Q) end
    if cfg.aimKey == 4 then return UIS:IsKeyDown(Enum.KeyCode.LeftShift) end
    return false
end

local function getAimPartOf(plr)
    local char = plr.Character
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    if cfg.aimTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team then return nil end
    if cfg.aimPart == 1 then return char:FindFirstChild("Head") end
    if cfg.aimPart == 2 then
        return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
    end
    if cfg.aimPart == 3 then return char:FindFirstChild("HumanoidRootPart") end
    if cfg.aimPart == 4 then
        local center = Camera.ViewportSize / 2
        local best, bestD
        for _, name in ipairs({"Head", "Torso", "UpperTorso", "LowerTorso", "HumanoidRootPart"}) do
            local p = char:FindFirstChild(name)
            if p then
                local sp, v = Camera:WorldToViewportPoint(p.Position)
                if v then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if not bestD or d < bestD then best, bestD = p, d end
                end
            end
        end
        return best
    end
end

local function isInAimFov(part)
    if not part then return false, nil end
    local sp, visible = Camera:WorldToViewportPoint(part.Position)
    if not visible then return false, nil end
    local center = Camera.ViewportSize / 2
    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
    return d <= cfg.aimFov, d
end

local function updateAim()
    if aimCircle then
        if cfg.aimbot and cfg.aimDraw then
            aimCircle.Position = Camera.ViewportSize / 2
            aimCircle.Radius = cfg.aimFov
            aimCircle.Visible = true
        else
            aimCircle.Visible = false
        end
    end
    if not (cfg.aimbot and isAimKeyDown()) then return end
    local targetPart
    if cfg.aimTarget ~= "" then
        local plr = Players:FindFirstChild(cfg.aimTarget)
        if plr and plr ~= LocalPlayer then
            targetPart = getAimPartOf(plr)
            local inFov = isInAimFov(targetPart)
            if not inFov then targetPart = nil end
        end
    else
        local bestD
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local part = getAimPartOf(plr)
                local inFov, d = isInAimFov(part)
                if inFov and (not bestD or d < bestD) then
                    targetPart, bestD = part, d
                end
            end
        end
    end
    if targetPart then
        local targetCF = CFrame.new(Camera.CFrame.Position, targetPart.Position)
        if cfg.aimSmooth <= 1 then
            Camera.CFrame = targetCF
        else
            Camera.CFrame = Camera.CFrame:Lerp(targetCF, 1 / cfg.aimSmooth)
        end
    end
end

--// ============ ФЛИНГ ============
local function updateFling()
    if not cfg.flingOn then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local myPos = myHRP.Position
    local power = cfg.flingPower * 671.488
    local range = cfg.flingRange
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local allowed = true
            if cfg.flingMode == 2 and cfg.aimTarget ~= "" and plr.Name ~= cfg.aimTarget then allowed = false end
            if cfg.aimTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team then allowed = false end
            if allowed then
                local char = plr.Character
                local targetHRP = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if targetHRP and hum and hum.Health > 0 then
                    local bestD = (targetHRP.Position - myPos).Magnitude
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part ~= targetHRP then
                            local d = (part.Position - myPos).Magnitude
                            if d < bestD then bestD = d end
                        end
                    end
                    if bestD <= range then
                        pcall(function() targetHRP:SetNetworkOwner(LocalPlayer) end)
                        local dir = targetHRP.Position - myPos
                        if dir.Magnitude < 0.5 then dir = Camera.CFrame.LookVector end
                        dir = dir.Unit
                        targetHRP.AssemblyLinearVelocity = dir * power
                        targetHRP.AssemblyAngularVelocity = Vector3.new(
                            (math.random() - 0.5) * power,
                            (math.random() - 0.5) * power,
                            (math.random() - 0.5) * power
                        )
                        myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    end
                end
            end
        end
    end
end

--// ============ УВОРОТ ============
local function isDodgeKeyDown()
    if cfg.dodgeKey == 1 then return UIS:IsKeyDown(Enum.KeyCode.Space) and UIS:IsKeyDown(Enum.KeyCode.LeftShift) end
    if cfg.dodgeKey == 2 then return UIS:IsKeyDown(Enum.KeyCode.Q) end
    if cfg.dodgeKey == 3 then return UIS:IsKeyDown(Enum.KeyCode.E) end
    if cfg.dodgeKey == 4 then return UIS:IsKeyDown(Enum.KeyCode.C) end
    return false
end

local function updateDodge()
    if not cfg.dodgeOn or not isDodgeKeyDown() then return end
    local myHRP = getHRP()
    if not myHRP then return end
    local myPos = myHRP.Position
    local nearest, nearestD
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and not (cfg.aimTeam and LocalPlayer.Team and plr.Team == LocalPlayer.Team) then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local d = (hrp.Position - myPos).Magnitude
                if not nearestD or d < nearestD then nearest, nearestD = hrp, d end
            end
        end
    end
    local dodgeDir
    if nearest and nearestD <= cfg.dodgeDist then
        local away = myPos - nearest.Position
        away = Vector3.new(away.X, 0, away.Z)
        dodgeDir = away.Magnitude > 0.01 and away.Unit or Vector3.new(1, 0, 0)
    else
        dodgeDir = Camera.CFrame.RightVector
        dodgeDir = Vector3.new(dodgeDir.X, 0, dodgeDir.Z).Unit
    end
    myHRP.AssemblyLinearVelocity = dodgeDir * cfg.dodgeSpeed + Vector3.new(0, myHRP.AssemblyLinearVelocity.Y, 0)
end

--// ============ СПИН ============
local function updateSpin()
    if not cfg.spin then return end
    local hrp, h = getHRP(), getHum()
    if not hrp then return end
    if h then h.AutoRotate = false end
    local s = cfg.spinSpeed * math.pi * 2
    if cfg.spinMode == 1 then
        hrp.AssemblyAngularVelocity = Vector3.new(0, s, 0)
    elseif cfg.spinMode == 2 then
        hrp.AssemblyAngularVelocity = Vector3.new(s, 0, 0)
    elseif cfg.spinMode == 3 then
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, s)
    end
end

--// ============ НЕПРИКОСАЙКА ============
ghostRestore = function()
    if ghostPart then
        if ghostPart.Parent then ghostPart.CFrame = ghostCF end
        ghostPart, ghostCF = nil, nil
    end
end
RunService:BindToRenderStep("kotik_ghost_restore", Enum.RenderPriority.First.Value, ghostRestore)
RunService:BindToRenderStep("kotik_ghost_cam", Enum.RenderPriority.Camera.Value + 1, function()
    if not cfg.ghost then return end
    local hrp = getHRP()
    if not hrp then return end
    local cam = Camera
    if cam.CFrame.Position.Y - hrp.Position.Y > cfg.ghostHeight * 0.8 then
        cam.CFrame = cam.CFrame - Vector3.new(0, cfg.ghostHeight, 0)
    end
end)

--// ============ FPS BOOST ============
local fpsBoosted = false
local function applyFpsBoost()
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Decal") or d:IsA("Texture") then
            d.Transparency = 1
        elseif d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Smoke") or d:IsA("Fire") then
            d.Enabled = false
        elseif d:IsA("BasePart") then
            d.CastShadow = false
        end
    end
    fpsBoosted = true
end

--// ============ ОСНОВНЫЕ ЦИКЛЫ ============
bind(RunService.RenderStepped, function()
    Camera = workspace.CurrentCamera
    if cfg.fovOn then Camera.FieldOfView = cfg.fov end
    if cfg.fullbright then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 3
    end
    if cfg.clockTime then pcall(function() Lighting.ClockTime = cfg.timeValue end) end
    if cfg.fogOff then
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
    end
    if cfg.fpsBoost and not fpsBoosted then pcall(applyFpsBoost) elseif not cfg.fpsBoost then fpsBoosted = false end
    local h = getHum()
    if h then
        if cfg.speedOn then h.WalkSpeed = cfg.speed end
        if cfg.jumpOn then h.UseJumpPower = true h.JumpPower = cfg.jump end
        if cfg.noAnim then
            local c = getChar()
            local a = c and c:FindFirstChild("Animate")
            if a then a.Disabled = true end
            local animator = h:FindFirstChildOfClass("Animator")
            if animator then
                for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop(0) end
            end
        end
    end
    pcall(updateESP)
    pcall(updateHitboxes)
    pcall(updateAim)
    pcall(updateMusic)
    pcall(updateAccessories)
    pcall(updateBodyColor)
end)

bind(RunService.Heartbeat, function()
    local hrp, h = getHRP(), getHum()
    if not hrp then return end
    pcall(updateSpin)
    pcall(updateDodge)
    pcall(updateFling)
    if cfg.hvhOn then pcall(updateHvH) elseif cfg.shiftLock then pcall(updateShiftLock) end
    if cfg.fly and h then
        local md = h.MoveDirection
        local vel = Vector3.new(0, 0, 0)
        if md.Magnitude > 0 then
            local rel = Camera.CFrame:VectorToObjectSpace(md)
            vel = Camera.CFrame.LookVector * (-rel.Z) + Camera.CFrame.RightVector * rel.X
            if vel.Magnitude > 0 then vel = vel.Unit * cfg.flySpeed * math.min(1, md.Magnitude) end
        end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, cfg.flySpeed, 0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, cfg.flySpeed, 0) end
        hrp.AssemblyLinearVelocity = vel
    end
    if cfg.bhop and h and h.MoveDirection.Magnitude > 0 then
        if h:GetState() == Enum.HumanoidStateType.Landed or h:GetState() == Enum.HumanoidStateType.Running then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
    if cfg.gravityOn then pcall(function() workspace.Gravity = cfg.gravityValue end) end
    if cfg.tpLook then
        local target = Camera.CFrame.Position + Camera.CFrame.LookVector * 30
        teleportTo(CFrame.new(target))
    end
    if cfg.tpToPoint then
        local target = Vector3.new(cfg.savedX, cfg.savedY + 3, cfg.savedZ)
        if (hrp.Position - target).Magnitude > 3 then teleportTo(CFrame.new(target)) end
    end
    if cfg.ghost and not ghostPart then
        ghostPart = hrp
        ghostCF = hrp.CFrame
        hrp.CFrame = ghostCF + Vector3.new(0, cfg.ghostHeight, 0)
    end
end)

bind(UIS.JumpRequest, function()
    if cfg.infJump then
        local h = getHum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

bind(UIS.InputBegan, function(i, gp)
    if gp then return end
    if cfg.clickTp and i.UserInputType == Enum.UserInputType.MouseButton1 then
        local objs = gui:GetGuiObjectsAtPosition(i.Position.X, i.Position.Y)
        if #objs > 0 then return end
        local unitRay = Camera:ScreenPointToRay(i.Position.X, i.Position.Y)
        local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
        local hit, pos = workspace:FindPartOnRay(ray, getChar())
        if pos then teleportTo(CFrame.new(pos + Vector3.new(0, 3, 0))) end
    end
end)

local function hookFastRespawn(plr)
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.Died:Connect(function()
            if cfg.fastRespawn then
                task.wait(0.05)
                pcall(function() LocalPlayer:LoadCharacter() end)
            end
        end)
    end
    if plr.Character then onChar(plr.Character) end
    plr.CharacterAdded:Connect(onChar)
end
hookFastRespawn(LocalPlayer)

bind(Players.PlayerAdded, function()
    if aimDropdownOpen and aimDropdownList then refreshAimDropdown() end
end)
bind(Players.PlayerRemoving, function(plr)
    if cfg.aimTarget == plr.Name then
        cfg.aimTarget = ""
        save()
        if aimTargetBtn then aimTargetBtn.Text = "Цель: Авто" end
    end
    if aimDropdownOpen and aimDropdownList then refreshAimDropdown() end
end)

bind(LocalPlayer.CharacterAdded, function()
    lastPos = nil
    noclipOrig = {}
    accOrigColor = {}
    accOrigMat = {}
    bodyOrigColor = {}
    bodyOrigMat = {}
    shiftLockCurrent = nil
    hvhCurrentAngle = nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head and head:GetAttribute("kotik_origSize") then
                head.Size = head:GetAttribute("kotik_origSize")
                head:SetAttribute("kotik_origSize", nil)
                head:SetAttribute("kotik_origTrans", nil)
            end
        end
    end
end)

bind(RunService.Stepped, function()
    ghostRestore()
    if cfg.noclip then
        local c = getChar()
        if c then
            for _, d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") then
                    if noclipOrig[d] == nil then noclipOrig[d] = d.CanCollide end
                    d.CanCollide = false
                end
            end
        end
    end
    local hrp = getHRP()
    if not hrp then lastPos = nil return end
    local pos = hrp.Position
    if cfg.antiTp and lastPos and (pos - lastPos).Magnitude > cfg.antiTpDist then
        hrp.CFrame = CFrame.new(lastPos) * (hrp.CFrame - hrp.CFrame.Position)
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    else
        lastPos = pos
    end
end)

--// ============ ВЫГРУЗКА ============
local function unload()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("kotik_ghost_restore") end)
    pcall(function() RunService:UnbindFromRenderStep("kotik_ghost_cam") end)
    if menuFloatConn then pcall(function() menuFloatConn:Disconnect() end) end
    ghostRestore()
    stopMusic()
    if aimCircle then pcall(function() aimCircle:Remove() end) end
    for plr in pairs(drawings) do clearPlayer(plr) end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head and head:GetAttribute("kotik_origSize") then
                head.Size = head:GetAttribute("kotik_origSize")
                head.Transparency = head:GetAttribute("kotik_origTrans") or 0
                head.CanCollide = true
                head.Massless = false
            end
        end
    end
    for part, orig in pairs(bodyOrigColor) do if part.Parent then part.Color = orig end end
    bodyOrigColor = {}
    bodyOrigMat = {}
    restore()
    gui:Destroy()
    env.kotik_unload = nil
end
unloadRef = unload
env.kotik_unload = unload

print("[kotik_hub] Меню загружено.")
