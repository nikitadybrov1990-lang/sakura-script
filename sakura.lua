-- language: Luau, target: Roblox PC (Executor)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- НАСТРОЙКИ
local AimEnabled = true
local WallhackEnabled = true
local DayEnabled = true
local NoRecoilEnabled = true
local NoSpreadEnabled = true
local FOV = 200
local Smoothness = 0.15
local Unloaded = false
local MenuOpen = true

local oldLightingTime = Lighting.ClockTime
local oldIndex

-- 1. ВХ + Инфо
local highlights = {}
local infos = {}

local function update_info(plr)
    if plr == LocalPlayer or not plr.Character or Unloaded then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    local head = plr.Character:FindFirstChild("Head")
    if hum and head then
        local info = infos[plr]
        if not info or not info.Parent then
            info = Instance.new("BillboardGui")
            info.Name = "SakuraInfo"
            info.Adornee = head
            info.Size = UDim2.new(0, 200, 0, 50)
            info.StudsOffset = Vector3.new(0, 2.5, 0)
            info.AlwaysOnTop = true
            info.Parent = head
            infos[plr] = info
            local text = Instance.new("TextLabel")
            text.Name = "InfoText"
            text.Size = UDim2.new(1, 0, 1, 0)
            text.BackgroundTransparency = 1
            text.TextColor3 = Color3.fromRGB(255, 255, 255)
            text.TextStrokeTransparency = 0
            text.Font = Enum.Font.GothamBold
            text.TextSize = 14
            text.Parent = info
        end
        local health = math.floor(hum.Health)
        local maxHealth = math.floor(hum.MaxHealth)
        local weapon = "Unarmed"
        local tool = plr.Character:FindFirstChildOfClass("Tool")
        if tool then weapon = tool.Name end
        local textLabel = info:FindFirstChild("InfoText")
        if textLabel then
            textLabel.Text = string.format("[%d/%d HP] | %s", health, maxHealth, weapon)
        end
    end
end

local function apply_esp(plr)
    if plr == LocalPlayer or not plr.Character or Unloaded then return end
    if highlights[plr] then return end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        local hl = Instance.new("Highlight")
        hl.Name = "SakuraESP"
        hl.Adornee = plr.Character
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.OutlineColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.4
        hl.Parent = plr.Character
        highlights[plr] = hl
    end
end

local function remove_esp()
    for plr, hl in pairs(highlights) do
        if hl then hl:Destroy() end
        highlights[plr] = nil
    end
    for plr, info in pairs(infos) do
        if info then info:Destroy() end
        infos[plr] = nil
    end
end

local function update_esp()
    if WallhackEnabled and not Unloaded then
        for _, p in pairs(Players:GetPlayers()) do 
            apply_esp(p)
            update_info(p)
        end
    else
        remove_esp()
    end
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if WallhackEnabled and not Unloaded then 
            apply_esp(p)
            update_info(p)
        end
    end)
end)
update_esp()

-- 2. Поиск цели (В ГОЛОВУ)
local function get_target()
    local closest = nil
    local shortest = FOV
    local center = Camera.ViewportSize / 2
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum and hum.Health > 0 then
                local pos, on_screen = Camera:WorldToViewportPoint(head.Position)
                if on_screen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

-- 3. UI
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local oldGui = playerGui:FindFirstChild("SakuraUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SakuraUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui
ScreenGui.IgnoreGuiInset = true -- Важно для кликов

-- Круг FOV
local FovFrame = Instance.new("Frame")
FovFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
FovFrame.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
FovFrame.BackgroundTransparency = 1
FovFrame.Parent = ScreenGui
Instance.new("UICorner", FovFrame).CornerRadius = UDim.new(1, 0)
local FovStroke = Instance.new("UIStroke", FovFrame)
FovStroke.Color = Color3.fromRGB(0, 255, 0)
FovStroke.Thickness = 2

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 400)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 228, 235)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true -- Таскается за заголовок
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(255, 105, 180)
UIStroke.Thickness = 2

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
Title.Text = "🌸 Sakura Menu"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.Parent = MainFrame
Title.Active = true
Title.Draggable = true -- Таскается за заголовок
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

-- Контейнер для вкладок
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 30)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local function create_tab(text, x_pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.3, 0, 1, 0)
    btn.Position = UDim2.new(x_pos, 0, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 182, 193)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = TabContainer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local CurrentTab = "Aim"
local AimTab, VisualsTab, MiscTab, AimBtn, WHBtn, DayBtn, RecoilBtn, SpreadBtn, UnloadBtn
local FovSlider, FovValueLabel

local function switch_tab(tab_name)
    CurrentTab = tab_name
    AimTab.BackgroundColor3 = (tab_name == "Aim") and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(255, 182, 193)
    VisualsTab.BackgroundColor3 = (tab_name == "Visuals") and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(255, 182, 193)
    MiscTab.BackgroundColor3 = (tab_name == "Misc") and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(255, 182, 193)
    
    for _, child in pairs(MainFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") and child ~= TabContainer then
            child.Visible = false
        end
    end
    if FovSlider then FovSlider.Visible = false end
    if FovValueLabel then FovValueLabel.Visible = false end
    
    if tab_name == "Aim" then
        AimBtn.Visible = true
        FovSlider.Visible = true
        FovValueLabel.Visible = true
    elseif tab_name == "Visuals" then
        WHBtn.Visible = true
    elseif tab_name == "Misc" then
        DayBtn.Visible = true
        RecoilBtn.Visible = true
        SpreadBtn.Visible = true
        UnloadBtn.Visible = true
    end
end

AimTab = create_tab("Aim", 0.05, function() switch_tab("Aim") end)
VisualsTab = create_tab("Visuals", 0.35, function() switch_tab("Visuals") end)
MiscTab = create_tab("Misc", 0.65, function() switch_tab("Misc") end)

local function create_button(text, y_pos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.8, 0, 0, 35)
    btn.Position = UDim2.new(0.1, 0, y_pos, 0)
    btn.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = MainFrame
    btn.Visible = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

WHBtn = create_button("Wallhack: ON", 0.3, function()
    if Unloaded then return end
    WallhackEnabled = not WallhackEnabled
    WHBtn.Text = "Wallhack: " .. (WallhackEnabled and "ON" or "OFF")
    WHBtn.BackgroundColor3 = WallhackEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
    update_esp()
end)

AimBtn = create_button("Aim: ON", 0.3, function()
    if Unloaded then return end
    AimEnabled = not AimEnabled
    AimBtn.Text = "Aim: " .. (AimEnabled and "ON" or "OFF")
    AimBtn.BackgroundColor3 = AimEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

-- Слайдер FOV
FovValueLabel = Instance.new("TextLabel")
FovValueLabel.Size = UDim2.new(0.8, 0, 0, 20)
FovValueLabel.Position = UDim2.new(0.1, 0, 0.45, 0)
FovValueLabel.BackgroundTransparency = 1
FovValueLabel.Text = "FOV: " .. FOV
FovValueLabel.TextColor3 = Color3.fromRGB(200, 100, 150)
FovValueLabel.Font = Enum.Font.GothamBold
FovValueLabel.TextSize = 14
FovValueLabel.Parent = MainFrame
FovValueLabel.Visible = false

FovSlider = Instance.new("TextButton")
FovSlider.Size = UDim2.new(0.8, 0, 0, 20)
FovSlider.Position = UDim2.new(0.1, 0, 0.55, 0)
FovSlider.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
FovSlider.Text = ""
FovSlider.Parent = MainFrame
FovSlider.Visible = false
Instance.new("UICorner", FovSlider).CornerRadius = UDim.new(0, 4)

local sliderFill = Instance.new("Frame")
sliderFill.Size = UDim2.new(FOV / 500, 0, 1, 0)
sliderFill.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
sliderFill.Parent = FovSlider
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 4)

FovSlider.MouseButton1Down:Connect(function()
    local isDragging = true
    local connection
    connection = UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouseX = UserInputService:GetMouseLocation().X
            local sliderAbsolutePos = FovSlider.AbsolutePosition.X
            local sliderSize = FovSlider.AbsoluteSize.X
            local newFov = math.clamp((mouseX - sliderAbsolutePos) / sliderSize * 500, 50, 500)
            FOV = math.floor(newFov)
            FovValueLabel.Text = "FOV: " .. FOV
            sliderFill.Size = UDim2.new(FOV / 500, 0, 1, 0)
            FovFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
            FovFrame.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
            if connection then connection:Disconnect() end
        end
    end)
end)

DayBtn = create_button("Always Day: ON", 0.3, function()
    if Unloaded then return end
    DayEnabled = not DayEnabled
    DayBtn.Text = "Always Day: " .. (DayEnabled and "ON" or "OFF")
    DayBtn.BackgroundColor3 = DayEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

RecoilBtn = create_button("No Recoil: ON", 0.42, function()
    if Unloaded then return end
    NoRecoilEnabled = not NoRecoilEnabled
    RecoilBtn.Text = "No Recoil: " .. (NoRecoilEnabled and "ON" or "OFF")
    RecoilBtn.BackgroundColor3 = NoRecoilEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

SpreadBtn = create_button("No Spread: ON", 0.54, function()
    if Unloaded then return end
    NoSpreadEnabled = not NoSpreadEnabled
    SpreadBtn.Text = "No Spread: " .. (NoSpreadEnabled and "ON" or "OFF")
    SpreadBtn.BackgroundColor3 = NoSpreadEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

UnloadBtn = create_button("Выгрузить (Unload)", 0.66, function()
    Unloaded = true
    AimEnabled = false
    WallhackEnabled = false
    DayEnabled = false
    NoRecoilEnabled = false
    NoSpreadEnabled = false
    
    pcall(function()
        if oldLightingTime then Lighting.ClockTime = oldLightingTime end
        if oldIndex then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__index = oldIndex
            setreadonly(mt, true)
        end
    end)
    
    remove_esp()
    if ScreenGui then ScreenGui:Destroy() end
    print("[Sakura] Скрипт выгружен.")
end)

switch_tab("Aim")

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, 0, 0, 20)
Hint.Position = UDim2.new(0, 0, 1, -25)
Hint.BackgroundTransparency = 1
Hint.Text = "Правый Shift — скрыть/показать (Курсор освобождается)"
Hint.TextColor3 = Color3.fromRGB(200, 100, 150)
Hint.Font = Enum.Font.Gotham
Hint.TextSize = 12
Hint.Parent = MainFrame

-- 4. Аим
RunService.RenderStepped:Connect(function()
    if Unloaded or not AimEnabled then return end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and not MenuOpen then -- Аим работает только когда меню закрыто
        local target = get_target()
        if target then
            local target_cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(target_cf, Smoothness)
        end
    end
end)

-- 5. No Recoil / No Spread
if getrawmetatable then
    local mt = getrawmetatable(game)
    oldIndex = mt.__index
    setreadonly(mt, false)
    
    mt.__index = newcclosure(function(t, k)
        if Unloaded then return oldIndex(t, k) end
        
        if NoSpreadEnabled and t:IsA("Mouse") and (k == "Hit" or k == "Target") then
            return (k == "Hit" and CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + Camera.CFrame.LookVector * 1000) or nil)
        end
        
        if NoRecoilEnabled and t == Camera and k == "CFrame" then
            return oldIndex(t, k)
        end
        
        return oldIndex(t, k)
    end)
    setreadonly(mt, true)
end

-- 6. Всегда День
RunService.Heartbeat:Connect(function()
    if not Unloaded and DayEnabled then
        if Lighting.ClockTime ~= 14 then
            Lighting.ClockTime = 14
            Lighting.Brightness = 2
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
            Lighting.GlobalShadows = false
        end
    end
    
    if WallhackEnabled and not Unloaded then
        for _, p in pairs(Players:GetPlayers()) do
            update_info(p)
        end
    end
end)

-- 7. Правый Shift (Освобождение мыши)
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift and not Unloaded then
        MenuOpen = not MenuOpen
        MainFrame.Visible = MenuOpen
        
        if MenuOpen then
            -- Освобождаем курсор для кликов
            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            UserInputService.MouseIconEnabled = true
        else
            -- Возвращаем блокировку курсора для игры
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end
end)
