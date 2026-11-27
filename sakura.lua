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

-- 1. ВХ (Wallhack)
local highlights = {}
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
end
local function update_esp()
    if WallhackEnabled and not Unloaded then
        for _, p in pairs(Players:GetPlayers()) do apply_esp(p) end
    else
        remove_esp()
    end
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if WallhackEnabled and not Unloaded then apply_esp(p) end
    end)
end)
update_esp()

-- 2. Поиск цели
local function get_target()
    local closest = nil
    local shortest = FOV
    local center = Camera.ViewportSize / 2
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pos, on_screen = Camera:WorldToViewportPoint(hrp.Position)
                if on_screen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = hrp
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
MainFrame.Size = UDim2.new(0, 300, 0, 420)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 228, 235)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true
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
Title.Draggable = true
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 12)

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
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local WHBtn = create_button("Wallhack: ON", 0.13, function()
    if Unloaded then return end
    WallhackEnabled = not WallhackEnabled
    WHBtn.Text = "Wallhack: " .. (WallhackEnabled and "ON" or "OFF")
    WHBtn.BackgroundColor3 = WallhackEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
    update_esp()
end)

local AimBtn = create_button("Aim: ON", 0.25, function()
    if Unloaded then return end
    AimEnabled = not AimEnabled
    AimBtn.Text = "Aim: " .. (AimEnabled and "ON" or "OFF")
    AimBtn.BackgroundColor3 = AimEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

local DayBtn = create_button("Always Day: ON", 0.37, function()
    if Unloaded then return end
    DayEnabled = not DayEnabled
    DayBtn.Text = "Always Day: " .. (DayEnabled and "ON" or "OFF")
    DayBtn.BackgroundColor3 = DayEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

local RecoilBtn = create_button("No Recoil: ON", 0.49, function()
    if Unloaded then return end
    NoRecoilEnabled = not NoRecoilEnabled
    RecoilBtn.Text = "No Recoil: " .. (NoRecoilEnabled and "ON" or "OFF")
    RecoilBtn.BackgroundColor3 = NoRecoilEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

local SpreadBtn = create_button("No Spread: ON", 0.61, function()
    if Unloaded then return end
    NoSpreadEnabled = not NoSpreadEnabled
    SpreadBtn.Text = "No Spread: " .. (NoSpreadEnabled and "ON" or "OFF")
    SpreadBtn.BackgroundColor3 = NoSpreadEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

local UnloadBtn = create_button("Выгрузить (Unload)", 0.73, function()
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

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, 0, 0, 20)
Hint.Position = UDim2.new(0, 0, 1, -25)
Hint.BackgroundTransparency = 1
Hint.Text = "Правый Shift — скрыть/показать"
Hint.TextColor3 = Color3.fromRGB(200, 100, 150)
Hint.Font = Enum.Font.Gotham
Hint.TextSize = 12
Hint.Parent = MainFrame

-- 4. Аим
RunService.RenderStepped:Connect(function()
    if Unloaded or not AimEnabled then return end
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = get_target()
        if target then
            local target_cf = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(target_cf, Smoothness)
        end
    end
end)

-- 5. No Recoil / No Spread (Хук на __index)
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
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    end
end)

-- 7. Правый Shift
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift and not Unloaded then
        MenuOpen = not MenuOpen
        MainFrame.Visible = MenuOpen
        FovFrame.Visible = MenuOpen
    end
end)
