local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- Variáveis de controle
local autoHakiConnection = nil
local lastToggleTime = 0
local COOLDOWN_TIME = 3 -- 3 segundos de cooldown após ativar

-- Partes dos braços para verificar
local armParts = {
    "LeftArm",
    "RightArm"
}

-- Função para verificar se há ParticleEmitter com nome "3" nos braços
local function hasHakiEffect()
    -- Buscar personagem do LocalPlayer no Workspace
    local character = Workspace:FindFirstChild(Player.Name)
    if not character then return false end
    
    for _, armPartName in pairs(armParts) do
        local armPart = character:FindFirstChild(armPartName)
        
        if armPart then
            -- Verificar se existe um ParticleEmitter chamado "3"
            local particleEffect = armPart:FindFirstChild("3")
            if particleEffect and particleEffect:IsA("ParticleEmitter") then
                return true -- Encontrou ParticleEmitter "3", Haki está ativo
            end
        end
    end
    
    return false -- Nenhum ParticleEmitter "3" encontrado, Haki está desativado
end

-- Função para ativar Haki UMA VEZ
local function toggleHaki()
    pcall(function()
        ReplicatedStorage.RemoteEvents.HakiRemote:FireServer("Toggle")
    end)
end

-- Função para parar Auto Haki
local function stopAutoHaki()
    if autoHakiConnection then
        autoHakiConnection:Disconnect()
        autoHakiConnection = nil
    end
    _G.SlowHub.AutoHaki = false
    lastToggleTime = 0
end

-- Função para iniciar Auto Haki
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
        
        -- Só verificar se passou o cooldown
        if now - lastToggleTime >= COOLDOWN_TIME then
            -- Verificar se Haki está ativo
            local hakiActive = hasHakiEffect()
            
            -- Se NÃO tiver efeito, ativar Haki UMA VEZ
            if not hakiActive then
                toggleHaki()
                lastToggleTime = now -- Resetar cooldown para não ativar novamente
            end
        end
    end)
end

-- Toggle Auto Haki
Tab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = false,
    Flag = "AutoHakiToggle",
    Callback = function(Value)
        if Value then
            startAutoHaki()
        else
            stopAutoHaki()
        end
    end
})
