-- language: Luau, target: Roblox PC (Executor)
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

local noclipEnabled = false
local connections = {}

-- Функция для отключения коллизий у всех частей персонажа
local function toggleNoclip()
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if noclipEnabled then
                part.CanCollide = false
            else
                part.CanCollide = true
            end
        end
    end
end

-- Следим за обновлением частей (когда персонаж респавнится или что-то меняется)
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    if noclipEnabled then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Основной цикл, чтобы держать NoClip включенным, даже если игра пытается вернуть коллизии
RunService.Stepped:Connect(function()
    if noclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- Обработка клавиши (Правый Shift)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        noclipEnabled = not noclipEnabled
        
        if noclipEnabled then
            print("[NoClip] Включен")
            toggleNoclip()
        else
            print("[NoClip] Выключен")
            toggleNoclip()
        end
    end
end)
