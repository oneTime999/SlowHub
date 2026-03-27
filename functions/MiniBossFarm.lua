local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- NOVO
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local miniBossConfig = {
    ["ThiefBoss"]={quest="QuestNPC2"},["MonkeyBoss"]={quest="QuestNPC4"},
    ["DesertBoss"]={quest="QuestNPC6"},["SnowBoss"]={quest="QuestNPC8"},
    ["PandaMiniBoss"]={quest="QuestNPC10"},
}
local miniBossList = {"ThiefBoss","MonkeyBoss","DesertBoss","SnowBoss","PandaMiniBoss"}

-- NOVO: Portais para cada Mini Boss (ajuste conforme seu jogo)
local MiniBossPortals = {
    ["ThiefBoss"] = "Starter",
    ["MonkeyBoss"] = "Jungle",
    ["DesertBoss"] = "Desert",
    ["SnowBoss"] = "Snow",
    ["PandaMiniBoss"] = "Shibuya",
}

-- NOVO: Variáveis de controle de estado (igual aos códigos anteriores)
local currentTween = nil
local lastTweenTarget = nil
local lastPortaledMiniBoss = nil
local waitingForSpawn = false
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 12 -- Mini bosses demoram um pouco para spawnar

local farmConnection = nil
local questConnection = nil
local isFarming = false
local isQuesting = false
local selectedMiniBoss = nil
local lastTargetName = nil
local wasAttackingBoss = false
local lastAttackTime = 0
local character = nil
local humanoidRootPart = nil
local humanoid = nil
local npcsFolder = nil

local function initialize()
    character = Player.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    npcsFolder = workspace:FindFirstChild("NPCs")
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = nil
    humanoidRootPart = nil
    task.wait(0.1)
    humanoid = char:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then npcsFolder = child end
end)

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    return pcall(function()
        if not character or not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if tool then humanoid:EquipTool(tool) end
    end)
end

-- NOVO: Sistema de Cancelar Tween (igual aos códigos anteriores)
local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

-- NOVO: Sistema de Movimentação com Tween (igual aos códigos anteriores)
local function moveToTarget(targetCFrame)
    if not humanoidRootPart then return false end

    local currentFarmDist = _G.SlowHub.MiniBossFarmDistance or 6
    local currentSpeed = _G.SlowHub.TweenSpeed or 500

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude

    -- Se já está perto, teleporta direto
    if distance <= currentFarmDist + 2 then
        cancelTween()
        humanoidRootPart.CFrame = targetCFrame
        return true
    end

    -- Se o alvo mudou, cancela tween anterior
    if lastTweenTarget then
        local posDiff = (lastTweenTarget.Position - targetCFrame.Position).Magnitude
        if posDiff > 1 then
            cancelTween()
        elseif currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
            return false -- Já está em movimento para o mesmo alvo
        end
    end

    lastTweenTarget = targetCFrame
    if currentSpeed <= 0 then currentSpeed = 500 end
    local timeToReach = distance / currentSpeed
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()

    return false
end

local function performAttack()
    local currentTime = tick()
    if currentTime - lastAttackTime < (_G.SlowHub.MiniBossFarmCooldown or 0.15) then return end
    lastAttackTime = currentTime
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then requestHit:FireServer() end
    end)
end

local function acceptQuest()
    if not selectedMiniBoss then return end
    if not miniBossConfig[selectedMiniBoss] then return end
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(miniBossConfig[selectedMiniBoss].quest) end
    end)
end

-- NOVO: Reset completo do estado (igual aos códigos anteriores)
local function resetFarmState()
    lastTargetName = nil
    lastPortaledMiniBoss = nil
    waitingForSpawn = false
    spawnWaitStart = 0
    wasAttackingBoss = false
    lastAttackTime = 0
    cancelTween()
end

local function stopQuestLoop()
    isQuesting = false
end

local function startQuestLoop()
    if isQuesting then return end
    isQuesting = true
    questConnection = task.spawn(function()
        while isQuesting and _G.SlowHub.AutoFarmMiniBosses do
            acceptQuest()
            task.wait(_G.SlowHub.QuestInterval or 2)
        end
    end)
end

local function stopAutoFarmMiniBoss()
    if not isFarming then return end
    isFarming = false
    cancelTween() -- NOVO
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    stopQuestLoop()
    resetFarmState()
    _G.SlowHub.AutoFarmMiniBosses = false
end

-- NOVO: Função principal de farm adaptada
local function farmLoop()
    if not _G.SlowHub.AutoFarmMiniBosses then stopAutoFarmMiniBoss(); return end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
    end
    
    -- Verificação de Boss global (pausa se estiver atacando boss normal)
    if _G.SlowHub.IsAttackingBoss then 
        wasAttackingBoss = true
        cancelTween()
        return 
    end
    
    if wasAttackingBoss then
        lastPortaledMiniBoss = nil -- Força re-teleporte após boss
        wasAttackingBoss = false
    end
    
    if not selectedMiniBoss then return end
    
    -- Sincronização: Se mudou de mini boss, força novo teleporte
    if selectedMiniBoss ~= lastTargetName then
        lastTargetName = selectedMiniBoss
        lastPortaledMiniBoss = nil -- Força teleporte para nova área
        waitingForSpawn = false
        cancelTween()
    end
    
    -- CORREÇÃO: Só pode farmar se já usou o portal deste mini boss específico
    if lastPortaledMiniBoss ~= selectedMiniBoss then
        local portalName = MiniBossPortals[selectedMiniBoss]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Garante o teleporte
        end
        lastPortaledMiniBoss = selectedMiniBoss -- Marca que tentou usar portal deste mini boss
        waitingForSpawn = true
        spawnWaitStart = tick()
        return -- Sai e espera spawn na próxima iteração
    end
    
    -- Se está esperando spawn, verifica se mini boss apareceu
    if waitingForSpawn then
        local elapsed = tick() - spawnWaitStart
        
        if not npcsFolder then 
            cancelTween()
            return 
        end
        
        local miniBoss = npcsFolder:FindFirstChild(selectedMiniBoss)
        local isAlive = miniBoss and miniBoss:FindFirstChildOfClass("Humanoid") and 
                       miniBoss:FindFirstChildOfClass("Humanoid").Health > 0
        
        if isAlive then
            -- Mini Boss spawnou! Pode começar a farmar
            waitingForSpawn = false
        elseif elapsed > MAX_SPAWN_WAIT then
            -- Timeout: força re-teleporte
            lastPortaledMiniBoss = nil -- Isso vai forçar teleporte novamente na próxima iteração
            waitingForSpawn = false
            task.wait(0.5)
        else
            -- Ainda esperando, fica parado
            cancelTween()
        end
        return -- Sai da função até confirmar spawn ou timeout
    end
    
    -- Só chega aqui se: já usou o portal deste mini boss E ele já spawnou
    if not npcsFolder then return end
    local miniBoss = npcsFolder:FindFirstChild(selectedMiniBoss)
    if not miniBoss then return end
    
    local bossHumanoid = miniBoss:FindFirstChildOfClass("Humanoid")
    if not bossHumanoid or bossHumanoid.Health <= 0 then 
        -- Mini Boss morreu, aguarda respawn
        waitingForSpawn = true
        spawnWaitStart = tick()
        return 
    end
    
    local bossRoot = miniBoss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return end
    
    local currentHeight = _G.SlowHub.MiniBossFarmHeight or 4
    local currentDist = _G.SlowHub.MiniBossFarmDistance or 6
    
    local offset = CFrame.new(0, currentHeight, currentDist)
    local targetCFrame = bossRoot.CFrame * offset
    
    local hasArrived = moveToTarget(targetCFrame)
    
    if hasArrived then
        equipWeapon()
        performAttack()
    end
end

local function startAutoFarmMiniBoss()
    if isFarming then stopAutoFarmMiniBoss(); task.wait(0.3) end
    if not selectedMiniBoss then return false end
    if not miniBossConfig[selectedMiniBoss] then return false end
    initialize()
    if not npcsFolder then return false end
    isFarming = true
    _G.SlowHub.AutoFarmMiniBosses = true
    resetFarmState()
    startQuestLoop()
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

Tab:Section({Title = "Mini Bosses"})

Tab:Dropdown({
    Title = "Select Mini Boss",
    Flag = "SelectMiniBoss",
    Values = miniBossList,
    Multi = false,
    Value = _G.SlowHub.SelectMiniBoss or miniBossList[1],
    Callback = function(value)
        local wasRunning = isFarming
        if wasRunning then stopAutoFarmMiniBoss() end
        selectedMiniBoss = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectMiniBoss = selectedMiniBoss
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if wasRunning then task.wait(0.3); startAutoFarmMiniBoss() end
    end,
})

Tab:Toggle({
    Title = "Auto Farm Mini Boss",
    Value = _G.SlowHub.AutoFarmMiniBosses or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmMiniBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoFarmMiniBoss()
        else
            stopAutoFarmMiniBoss()
        end
    end,
})

-- NOVO: Slider de Tween Speed (igual aos outros códigos)
Tab:Slider({
    Title = "Tween Speed",
    Flag = "MiniBossTweenSpeed",
    Step = 10,
    Value = {
        Min = 150,
        Max = 500,
        Default = _G.SlowHub.TweenSpeed or 500,
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Mini Boss Distance",
    Flag = "MiniBossDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmDistance or 6,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Mini Boss Height",
    Flag = "MiniBossHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmHeight or 4,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "MiniBossCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.MiniBossFarmCooldown or 0.15,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmCooldown = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})
