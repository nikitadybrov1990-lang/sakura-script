-- language: Luau, target: Roblox PC (Executor)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- НАСТРОЙКИ
local AimEnabled = true
local WallhackEnabled = true
local FOV = 150
local Smoothness = 0.15
local Unloaded = false

-- Сохраняем оригинальный Raycast для Unload
local oldRaycast = workspace.Raycast

-- 1. ВХ
local highlights = {}
local function apply_esp(plr)
    if plr == LocalPlayer or highlights[plr] or not plr.Character or Unloaded then return end
    local hl = Instance.new("Highlight")
    hl.Name = "SakuraESP"
    hl.Adornee = plr.Character
    hl.FillColor = Color3.fromRGB(255, 182, 193)
    hl.OutlineColor = Color3.fromRGB(255, 105, 180)
    hl.FillTransparency = 0.5
    hl.Parent = plr.Character
    highlights[plr] = hl
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
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
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

-- Круг FOV (Зеленый)
local FovFrame = Instance.new("Frame")
FovFrame.Size = UDim2.new(0, FOV * 2, 0, FOV * 2)
FovFrame.Position = UDim2.new(0.5, -FOV, 0.5, -FOV)
FovFrame.BackgroundTransparency = 1
FovFrame.Parent = ScreenGui
Instance.new("UICorner", FovFrame).CornerRadius = UDim.new(1, 0)
local FovStroke = Instance.new("UIStroke", FovFrame)
FovStroke.Color = Color3.fromRGB(0, 255, 0)
FovStroke.Thickness = 2
FovStroke.Transparency = 0.2

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 300)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -150)
MainFrame.BackgroundColor3 = Color3.fromRGB(255, 228, 235)
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true -- ВАЖНО для перетаскивания
MainFrame.Draggable = true -- ВАЖНО для перетаскивания

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local UIStroke = Instance.new("UIStroke", MainFrame)
UIStroke.Color = Color3.fromRGB(255, 105, 180)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.3

-- Заголовок (за него тоже можно таскать)
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

-- Кнопка ВХ
local WHBtn = Instance.new("TextButton")
WHBtn.Size = UDim2.new(0.8, 0, 0, 35)
WHBtn.Position = UDim2.new(0.1, 0, 0.18, 0)
WHBtn.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
WHBtn.Text = "Wallhack: ON"
WHBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
WHBtn.Font = Enum.Font.GothamBold
WHBtn.TextSize = 14
WHBtn.Parent = MainFrame
Instance.new("UICorner", WHBtn).CornerRadius = UDim.new(0, 8)

WHBtn.MouseButton1Click:Connect(function()
    if Unloaded then return end
    WallhackEnabled = not WallhackEnabled
    WHBtn.Text = "Wallhack: " .. (WallhackEnabled and "ON" or "OFF")
    WHBtn.BackgroundColor3 = WallhackEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
    update_esp()
end)

-- Кнопка Аима
local AimBtn = Instance.new("TextButton")
AimBtn.Size = UDim2.new(0.8, 0, 0, 35)
AimBtn.Position = UDim2.new(0.1, 0, 0.40, 0)
AimBtn.BackgroundColor3 = Color3.fromRGB(255, 105, 180)
AimBtn.Text = "Full Bridge: ON"
AimBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
AimBtn.Font = Enum.Font.GothamBold
AimBtn.TextSize = 14
AimBtn.Parent = MainFrame
Instance.new("UICorner", AimBtn).CornerRadius = UDim.new(0, 8)

AimBtn.MouseButton1Click:Connect(function()
    if Unloaded then return end
    AimEnabled = not AimEnabled
    AimBtn.Text = "Full Bridge: " .. (AimEnabled and "ON" or "OFF")
    AimBtn.BackgroundColor3 = AimEnabled and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(150, 150, 150)
end)

-- Кнопка выгрузки
local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Size = UDim2.new(0.8, 0, 0, 35)
UnloadBtn.Position = UDim2.new(0.1, 0, 0.62, 0)
UnloadBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
UnloadBtn.Text = "Выгрузить (Unload)"
UnloadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
UnloadBtn.Font = Enum.Font.GothamBold
UnloadBtn.TextSize = 14
UnloadBtn.Parent = MainFrame
Instance.new("UICorner", UnloadBtn).CornerRadius = UDim.new(0, 8)

UnloadBtn.MouseButton1Click:Connect(function()
    Unloaded = true
    AimEnabled = false
    WallhackEnabled = false
    
    -- Восстанавливаем Raycast (убираем No Recoil)
    pcall(function()
        if oldRaycast then
            workspace.Raycast = oldRaycast
        end
    end)
    
    remove_esp()
    if ScreenGui then ScreenGui:Destroy() end
    print("[Sakura] Скрипт выгружен и Raycast восстановлен.")
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

-- 4. Бридж (Аим)
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

-- 5. No Recoil / No Spread
workspace.Raycast = function(self, origin, direction, params)
    if not Unloaded then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Head") then
            local cameraRay = Camera:ScreenPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            if (origin - char.Head.Position).Magnitude < 10 then
                return oldRaycast(self, origin, cameraRay.Direction * direction.Magnitude, params)
            end
        end
    end
    return oldRaycast(self, origin, direction, params)
end

-- 6. Правый Shift
UserInputService.InputBegan:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.RightShift and not Unloaded then
        MainFrame.Visible = not MainFrame.Visible
        FovFrame.Visible = MainFrame.Visible
    end
end)
