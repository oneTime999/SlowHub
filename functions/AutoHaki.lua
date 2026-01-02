local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Variáveis de controle
local autoHakiConnection = nil

-- Partes dos braços para verificar
local armParts = {
    "LeftUpperArm",
    "RightUpperArm",
    "LeftLowerArm",
    "RightLowerArm",
    "LeftHand",
    "RightHand"
}

-- Tipos de efeitos que indicam Haki ativo
local effectTypes = {
    "ParticleEmitter",
    "Beam",
    "Trail",
    "Fire",
    "Smoke",
    "Sparkles",
    "PointLight",
    "SpotLight",
    "SurfaceLight"
}

-- Função para verificar se há efeitos nos braços
local function hasHakiEffect()
    local character = Player.Character
    if not character then return false end
    
    for _, armPartName in pairs(armParts) do
        local armPart = character:FindFirstChild(armPartName)
        
        if armPart then
            -- Verificar cada tipo de efeito
            for _, effectType in pairs(effectTypes) do
                local effect = armPart:FindFirstChildOfClass(effectType)
                if effect then
                    return true -- Encontrou efeito, Haki está ativo
                end
            end
        end
    end
    
    return false -- Nenhum efeito encontrado, Haki está desativado
end

-- Função para ativar Haki
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
end

-- Função para iniciar Auto Haki
local function startAutoHaki()
    if autoHakiConnection then
        stopAutoHaki()
    end
    
    _G.SlowHub.AutoHaki = true
    
    local lastToggleTime = 0
    
    autoHakiConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoHaki then
            stopAutoHaki()
            return
        end
        
        local now = tick()
        
        -- Só tentar ativar a cada 0.5 segundos para evitar spam
        if now - lastToggleTime >= 0.5 then
            -- Verificar se Haki está ativo
            local hakiActive = hasHakiEffect()
            
            -- Se NÃO tiver efeito, ativar Haki
            if not hakiActive then
                toggleHaki()
                lastToggleTime = now
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
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Haki enabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            startAutoHaki()
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Haki disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopAutoHaki()
        end
    end
})
