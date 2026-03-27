local Tab = _G.TeleportsTab
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

-- [Mantém a tabela npcs completa aqui...]
local npcs = {
    ["AlucardBuyer"] = Vector3.new(476.08, 2.80, 1037.77),
    ["AnosBossSummonerNPC"] = Vector3.new(901.43, 1.46, 1293.14),
    -- ... resto dos npcs em ordem alfabética
}

local npcList = {}
for name in pairs(npcs) do table.insert(npcList, name) end
table.sort(npcList)

local currentTween = nil
local lastTweenTarget = nil
local character = nil
local humanoidRootPart = nil
local flyConnection = nil -- NOVO: Conexão do loop de voo

local function initialize()
    character = Player.Character
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.1)
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    -- NOVO: Parar o fly quando cancelar o tween
    if flyConnection then
        flyConnection:Disconnect()
        flyConnection = nil
    end
end

-- NOVO: Função para manter o voo ativo (bypass do anti-cheat)
local function startFlyBypass()
    local LightFlightEvent = ReplicatedStorage:WaitForChild("Light"):WaitForChild("LightFlightEvent")
    
    -- Loop constante mantendo o voo ativo
    flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
        pcall(function()
            local args = {
                [1] = "updateDirection",
                [2] = {
                    Direction = Vector3.new(0, 0, 0) -- Direção neutra, só para manter o estado
                },
            }
            LightFlightEvent:FireServer(unpack(args))
        end)
    end)
end

local function moveToTarget(targetPosition)
    if not humanoidRootPart then
        humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
    end

    local currentSpeed = _G.SlowHub.TeleportTweenSpeed or 500
    local distance = (humanoidRootPart.Position - targetPosition).Magnitude

    -- Se já está perto, teleporta direto
    if distance <= 5 then
        cancelTween()
        humanoidRootPart.CFrame = CFrame.new(targetPosition)
        return true
    end

    -- Se o alvo mudou, cancela tween anterior
    if lastTweenTarget then
        local posDiff = (lastTweenTarget - targetPosition).Magnitude
        if posDiff > 1 then
            cancelTween()
        elseif currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
            return false
        end
    end

    lastTweenTarget = targetPosition
    if currentSpeed <= 0 then currentSpeed = 500 end
    local timeToReach = distance / currentSpeed
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    -- NOVO: Iniciar fly bypass antes do movimento
    startFlyBypass()
    
    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = CFrame.new(targetPosition)})
    
    -- NOVO: Quando o tween completar, parar o fly
    currentTween.Completed:Connect(function()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
    end)
    
    currentTween:Play()
    return false
end

Tab:Section({Title = "NPC Teleport"})

Tab:Dropdown({
    Title = "Select NPC (Alphabetical)",
    Flag = "SelectNPCTeleport",
    Values = npcList,
    Multi = false,
    Value = _G.SlowHub.SelectedNPC or npcList[1],
    Callback = function(value)
        local selected = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectedNPC = selected
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Slider({
    Title = "Tween Speed",
    Flag = "TeleportTweenSpeed",
    Step = 10,
    Value = {
        Min = 150,
        Max = 2000, -- Aumentado porque o fly permite velocidades maiores
        Default = _G.SlowHub.TeleportTweenSpeed or 800,
    },
    Callback = function(Value)
        _G.SlowHub.TeleportTweenSpeed = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Button({
    Title = "Teleport to NPC (Fly Bypass)",
    Callback = function()
        local targetNPC = _G.SlowHub.SelectedNPC
        if not targetNPC or targetNPC == "" then return end
        local targetPosition = npcs[targetNPC]
        if not targetPosition then return end
        
        pcall(function()
            moveToTarget(targetPosition)
        end)
    end,
})

-- Botão para parar emergencialmente
Tab:Button({
    Title = "Stop/Cancel",
    Callback = function()
        cancelTween()
    end,
})
