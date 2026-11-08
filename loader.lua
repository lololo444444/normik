--// kotik_hub loader (Key System)
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- ССЫЛКА НА ВТОРОЙ ФАЙЛ (замени на свою, когда загрузишь main.lua)
local MAIN_SCRIPT_URL = "https://raw.githubusercontent.com/lololo444444/normik/refs/heads/main/main.lua"

local CHINESE_CHARS = {"龙","虎","猫","狗","水","火","木","金","土","风","雨","云","山","海","星","月","日","光","暗","心","力","剑","刀","弓","箭","血","魂","神","魔","道"}

local keyGui = Instance.new("ScreenGui")
keyGui.Name = "kotik_key"
keyGui.ResetOnSpawn = false
keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
keyGui.DisplayOrder = 999
pcall(function() if syn and syn.protect_gui then syn.protect_gui(keyGui) end end)
keyGui.Parent = (gethui and gethui()) or game:GetService("CoreGui")

local keyBg = Instance.new("Frame")
keyBg.Size = UDim2.new(0, 400, 0, 400)
keyBg.Position = UDim2.new(0.5, -200, 0.5, -200)
keyBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
keyBg.BorderSizePixel = 0
keyBg.ClipsDescendants = true
keyBg.Parent = keyGui
Instance.new("UICorner", keyBg).CornerRadius = UDim.new(0, 12)

-- Летающие китайские символы
local keyFloating = {}
local keyFloatConn
local function spawnKeyChar()
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 30, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Text = CHINESE_CHARS[math.random(#CHINESE_CHARS)]
    lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
    lbl.TextTransparency = 0.65
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = math.random(14, 28)
    lbl.Position = UDim2.new(math.random(), 0, 1.1, 0)
    lbl.ZIndex = 0
    lbl.Parent = keyBg
    keyFloating[#keyFloating + 1] = {label = lbl, speed = math.random(8, 20) / 100}
end
for i = 1, 12 do spawnKeyChar() end
keyFloatConn = RunService.RenderStepped:Connect(function(dt)
    for i = #keyFloating, 1, -1 do
        local d = keyFloating[i]
        local lbl = d.label
        if not lbl.Parent then
            table.remove(keyFloating, i)
        else
            local y = lbl.Position.Y.Scale - d.speed * dt
            if y < -0.1 then
                lbl.Position = UDim2.new(math.random(), 0, 1.1, 0)
                lbl.Text = CHINESE_CHARS[math.random(#CHINESE_CHARS)]
                lbl.TextSize = math.random(14, 28)
            else
                lbl.Position = UDim2.new(lbl.Position.X.Scale, 0, y, 0)
            end
        end
    end
end)

local keyTitle = Instance.new("TextLabel")
keyTitle.Size = UDim2.new(1, 0, 0, 40)
keyTitle.Position = UDim2.new(0, 0, 0, 15)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "KOTIK HUB — KEY"
keyTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
keyTitle.Font = Enum.Font.GothamBold
keyTitle.TextSize = 20
keyTitle.ZIndex = 2
keyTitle.Parent = keyBg

local keySub = Instance.new("TextLabel")
keySub.Size = UDim2.new(1, 0, 0, 20)
keySub.Position = UDim2.new(0, 0, 0, 55)
keySub.BackgroundTransparency = 1
keySub.Text = "Перетащи числа по порядку"
keySub.TextColor3 = Color3.fromRGB(180, 180, 180)
keySub.Font = Enum.Font.Gotham
keySub.TextSize = 13
keySub.ZIndex = 2
keySub.Parent = keyBg

local keySlots = {}
local slotOrder = {}
for i = 1, 3 do
    local slot = Instance.new("Frame")
    slot.Size = UDim2.new(0, 90, 0, 90)
    slot.Position = UDim2.new(0.5, -145 + (i - 1) * 100, 0.5, -45)
    slot.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    slot.BorderSizePixel = 0
    slot.ZIndex = 2
    slot.Parent = keyBg
    Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(80, 80, 80)
    s.Thickness = 2
    s.Parent = slot
    keySlots[i] = slot
end

local function generateKey()
    local nums = {}
    while #nums < 3 do
        local n = math.random(1, 9)
        local dup = false
        for _, v in ipairs(nums) do
            if v == n then dup = true break end
        end
        if not dup then nums[#nums + 1] = n end
    end
    return nums
end

local keyNums = generateKey()
local keySquares = {}

local function createKeySquare(value, startX, startY)
    local sq = Instance.new("TextButton")
    sq.Size = UDim2.new(0, 80, 0, 80)
    sq.Position = UDim2.new(0, startX, 0, startY)
    sq.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sq.BorderSizePixel = 0
    sq.Text = tostring(value)
    sq.TextColor3 = Color3.fromRGB(255, 255, 255)
    sq.Font = Enum.Font.GothamBold
    sq.TextSize = 32
    sq.ZIndex = 3
    sq.Parent = keyBg
    Instance.new("UICorner", sq).CornerRadius = UDim.new(0, 10)
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(80, 255, 120)
    s.Thickness = 2
    s.Parent = sq
    keySquares[#keySquares + 1] = sq

    local val = value
    local dragging = false
    local dragOffset = Vector2.new(0, 0)
    local slotIndex = nil
    local startPos = Vector2.new(startX, startY)

    local function getSlotUnder(pos)
        for i, slot in ipairs(keySlots) do
            local ap, asz = slot.AbsolutePosition, slot.AbsoluteSize
            local bgp = keyBg.AbsolutePosition
            local relX, relY = pos.X - bgp.X, pos.Y - bgp.Y
            local sx, sy = ap.X - bgp.X, ap.Y - bgp.Y
            if relX >= sx and relX <= sx + asz.X and relY >= sy and relY <= sy + asz.Y then
                return i
            end
        end
        return nil
    end

    local function checkCorrect()
        for i = 1, 3 do
            if not slotOrder[i] then return false end
        end
        return slotOrder[1] < slotOrder[2] and slotOrder[2] < slotOrder[3]
    end

    sq.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local mp = input.Position
            dragOffset = Vector2.new(mp.X - sq.AbsolutePosition.X, mp.Y - sq.AbsolutePosition.Y)
            if slotIndex then
                slotOrder[slotIndex] = nil
                slotIndex = nil
            end
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local mp = input.Position
            sq.Position = UDim2.new(0, mp.X - keyBg.AbsolutePosition.X - dragOffset.X, 0, mp.Y - keyBg.AbsolutePosition.Y - dragOffset.Y)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            local idx = getSlotUnder(input.Position)
            if idx and not slotOrder[idx] then
                slotOrder[idx] = val
                slotIndex = idx
                local slot = keySlots[idx]
                local bgp = keyBg.AbsolutePosition
                local sx = slot.AbsolutePosition.X - bgp.X
                local sy = slot.AbsolutePosition.Y - bgp.Y
                sq.Position = UDim2.new(0, sx + 5, 0, sy + 5)
                
                if checkCorrect() then
                    keyTitle.Text = "✓ ВЕРНО! Загрузка..."
                    keyTitle.TextColor3 = Color3.fromRGB(80, 255, 120)
                    task.delay(0.6, function()
                        if keyFloatConn then keyFloatConn:Disconnect() end
                        keyGui:Destroy()
                        
                        -- ЗАГРУЖАЕМ ОСНОВНОЙ СКРИПТ
                        local ok, src = pcall(game.HttpGet, game, MAIN_SCRIPT_URL)
                        if ok and src then
                            local fn = loadstring(src)
                            if fn then fn() end
                        else
                            print("[kotik_hub] Ошибка загрузки основного скрипта (проверь интернет)")
                        end
                    end)
                end
            else
                TweenService:Create(sq, TweenInfo.new(0.15), {Position = UDim2.new(0, startPos.X, 0, startPos.Y)}):Play()
            end
        end
    end)
end

for i, v in ipairs(keyNums) do
    createKeySquare(v, 40 + (i - 1) * 110, 280)
end

local shuffleBtn = Instance.new("TextButton")
shuffleBtn.Size = UDim2.new(0, 150, 0, 30)
shuffleBtn.Position = UDim2.new(0.5, -75, 1, -40)
shuffleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
shuffleBtn.Text = "Другая комбинация"
shuffleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
shuffleBtn.Font = Enum.Font.Gotham
shuffleBtn.TextSize = 12
shuffleBtn.BorderSizePixel = 0
shuffleBtn.ZIndex = 3
shuffleBtn.Parent = keyBg
Instance.new("UICorner", shuffleBtn).CornerRadius = UDim.new(0, 6)
shuffleBtn.MouseButton1Click:Connect(function()
    for _, sq in ipairs(keySquares) do sq:Destroy() end
    keySquares = {}
    slotOrder = {}
    keyNums = generateKey()
    for i, v in ipairs(keyNums) do
        createKeySquare(v, 40 + (i - 1) * 110, 280)
    end
end)
