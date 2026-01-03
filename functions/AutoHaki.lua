local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- Variaveis de controle
local autoHakiConnection = nil
local lastToggleTime = 0
local COOLDOWN_TIME = 3 -- segundos

-- Nomes CORRETOS dos bracos (R6)
local armParts = {
    "Left Arm",
    "Right Arm"
}

-- Verifica se existe ParticleEmitter "3" em algum braco
local function hasHakiEffect()
    local character = Player.Character
    if not character then return false end

    for _, armName in ipairs(armParts) do
        local arm = character:FindFirstChild(armName)
        if arm then
            local effect = arm:FindFirstChild("3")
            if effect and effect:IsA("ParticleEmitter") then
                return true
            end
        end
    end

    return false
end

-- Ativa Haki uma unica vez
local function toggleHaki()
    pcall(function()
        ReplicatedStorage.RemoteEvents.HakiRemote:FireServer("Toggle")
    end)
end

-- Para Auto Haki
local function stopAutoHaki()
    if autoHakiConnection then
        autoHakiConnection:Disconnect()
        autoHakiConnection = nil
    end
    _G.SlowHub.AutoHaki = false
    lastToggleTime = 0
end

-- Inicia Auto Haki
local function startAutoHaki()
    if autoHakiConnection then
        stopAutoHaki()
    end

    _G.SlowHub.AutoHaki = true
    lastToggleTime = 0

    autoHakiConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoHaki then
            stopAutoHaki()
            return
        end

        local now = tick()

        if now - lastToggleTime >= COOLDOWN_TIME then
            if not hasHakiEffect() then
                toggleHaki()
                lastToggleTime = now
            end
        end
    end)
end

-- Toggle UI (COM SALVAMENTO)
Tab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = _G.SlowHub.AutoHaki,  -- Carrega valor salvo
    Flag = "AutoHakiToggle",
    Callback = function(Value)
        if Value then
            startAutoHaki()
        else
            stopAutoHaki()
        end
        
        -- Salva automaticamente
        _G.SlowHub.AutoHaki = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

-- Auto iniciar se estava ativado
if _G.SlowHub.AutoHaki then
    task.wait(2)
    startAutoHaki()
end
