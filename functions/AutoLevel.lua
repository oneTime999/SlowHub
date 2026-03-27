local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- NOVO
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 5999, quest = "QuestNPC11", npc = "Hollow", count = 5},
    {minLevel = 6000, maxLevel = 6999, quest = "QuestNPC12", npc = "StrongSorcerer", count = 5},
    {minLevel = 7000, maxLevel = 7999, quest = "QuestNPC13", npc = "Curse", count = 5},
    {minLevel = 8000, maxLevel = 8999, quest = "QuestNPC14", npc = "Slime", count = 5},
    {minLevel = 9000, maxLevel = 9999, quest = "QuestNPC15", npc = "AcademyTeacher", count = 5},
    -- Novos NPCs adicionados abaixo:
    {minLevel = 10000, maxLevel = 10749, quest = "QuestNPC16", npc = "Swordsman", count = 5},
    {minLevel = 10750, maxLevel = 11499, quest = "QuestNPC17", npc = "Quincy", count = 5},
    {minLevel = 11500, maxLevel = 11999, quest = "QuestNPC18", npc = "Ninja", count = 5},
    {minLevel = 12000, maxLevel = 99999, quest = "QuestNPC19", npc = "ArenaFighter", count = 5},
}

-- NOVO: Portais para cada área (mesmo do primeiro código)
local MobPortals = {
    ["Thief"] = "Starter",
    ["Monkey"] = "Jungle", 
    ["DesertBandit"] = "Desert",
    ["FrostRogue"] = "Snow",
    ["Sorcerer"] = "Shibuya",
    ["Hollow"] = "Hueco",
    ["StrongSorcerer"] = "Shinjuku",
    ["Curse"] = "Shinjuku",
    ["Slime"] = "Slime",
    ["AcademyTeacher"] = "Academy",
    ["Swordsman"] = "Judgement",
    ["Quincy"] = "SoulDominion",
    ["Ninja"] = "Ninja",
    ["ArenaFighter"] = "Lawless"
}
-- NOVO: Variáveis de controle de estado (igual ao primeiro código)
local currentTween = nil
local lastTweenTarget = nil
local lastPortaledMob = nil
local waitingForSpawn = false
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 10

local farmConnection = nil
local questLoop = nil
local isFarming = false
local isQuesting = false
local currentNPCIndex = 1
local killCount = 0 -- NOVO
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

local function getPlayerLevel()
    local ok, result = pcall(function()
        local data = Player:FindFirstChild("Data")
        if not data then return 1 end
        local levelValue = data:FindFirstChild("Level")
        if not levelValue then return 1 end
        return levelValue.Value
    end)
    return ok and result or 1
end

local function getCurrentConfig()
    local level = getPlayerLevel()
    for _, config in ipairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then return config end
    end
    return LevelConfig[1]
end

local function getNextIndex(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
end

local function getNPC(npcName, index)
    if not npcsFolder then return nil end
    return npcsFolder:FindFirstChild(npcName .. index)
end

local function isNPCAlive(npc)
    if not npc or not npc.Parent then return false end
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

-- NOVO: Verifica se algum NPC deste tipo está vivo (para detectar spawn)
local function isAnyNPCAlive(mobName, count)
    if not npcsFolder then return false end
    for i = 1, count do
        local npc = npcsFolder:FindFirstChild(mobName .. i)
        if isNPCAlive(npc) then
            return true
        end
    end
    return false
end

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    return pcall(function()
        if not character or not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then humanoid:EquipTool(weapon) end
    end)
end

-- NOVO: Sistema de Cancelar Tween (igual ao primeiro código)
local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

-- NOVO: Sistema de Movimentação com Tween (igual ao primeiro código)
local function moveToTarget(targetCFrame)
    if not humanoidRootPart then return false end

    local currentFarmDist = _G.SlowHub.FarmDistance or 8
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
    if currentTime - lastAttackTime < (_G.SlowHub.FarmCooldown or 0.15) then return end
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
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local config = getCurrentConfig()
        if not config then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(config.quest) end
    end)
end

-- NOVO: Reset completo do estado (igual ao primeiro código)
local function resetFarmState()
    currentNPCIndex = 1
    killCount = 0
    lastTargetName = nil
    lastPortaledMob = nil
    waitingForSpawn = false
    spawnWaitStart = 0
    cancelTween()
end

local function stopQuestLoop()
    isQuesting = false
end

local function startQuestLoop()
    if isQuesting then return end
    isQuesting = true
    questLoop = task.spawn(function()
        while isQuesting and _G.SlowHub.AutoFarmLevel do
            acceptQuest()
            task.wait(_G.SlowHub.QuestInterval or 2)
        end
    end)
end

local function stopAutoLevel()
    if not isFarming then return end
    isFarming = false
    cancelTween() -- NOVO
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    stopQuestLoop()
    resetFarmState()
    pcall(function()
        if humanoidRootPart then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

-- NOVO: Função principal de farm adaptada do primeiro código
local function farmLoop()
    if not _G.SlowHub.AutoFarmLevel then stopAutoLevel(); return end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
    end
    
    -- Verificação de Boss
    if _G.SlowHub.IsAttackingBoss then 
        wasAttackingBoss = true
        cancelTween()
        return 
    end
    
    if wasAttackingBoss then
        lastPortaledMob = nil -- Força re-teleporte após boss
        wasAttackingBoss = false
    end
    
    local config = getCurrentConfig()
    if not config then return end
    
    -- Sincronização: Se mudou de mob (level upou), reseta estado
    if config.npc ~= lastTargetName then
        lastTargetName = config.npc
        lastPortaledMob = nil -- Força teleporte para nova área
        waitingForSpawn = false
        currentNPCIndex = 1
        killCount = 0
        cancelTween()
    end
    
    -- CORREÇÃO: Só pode farmar se já usou o portal deste mob específico
    if lastPortaledMob ~= config.npc then
        local portalName = MobPortals[config.npc]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Garante o teleporte
        end
        lastPortaledMob = config.npc -- Marca que tentou usar portal deste mob
        waitingForSpawn = true
        spawnWaitStart = tick()
        return -- Sai e espera spawn na próxima iteração
    end
    
    -- Se está esperando spawn, verifica se NPCs apareceram
    if waitingForSpawn then
        local elapsed = tick() - spawnWaitStart
        
        -- Verifica se algum NPC deste mob específico está vivo
        local anyAlive = isAnyNPCAlive(config.npc, config.count)
        
        if anyAlive then
            -- NPCs spawnaram! Pode começar a farmar
            waitingForSpawn = false
            currentNPCIndex = 1 -- Começa do primeiro
        elseif elapsed > MAX_SPAWN_WAIT then
            -- Timeout: força re-teleporte
            lastPortaledMob = nil -- Isso vai forçar teleporte novamente na próxima iteração
            waitingForSpawn = false
            task.wait(0.5)
        else
            -- Ainda esperando, fica parado
            cancelTween()
        end
        return -- Sai da função até confirmar spawn ou timeout
    end
    
    -- Só chega aqui se: já usou o portal deste mob E os NPCs já spawnaram
    local currentHeight = _G.SlowHub.FarmHeight or 4
    local currentDist = _G.SlowHub.FarmDistance or 8
    
    local npc = getNPC(config.npc, currentNPCIndex)
    local alive = isNPCAlive(npc)
    
    if not alive then
        -- NPC morto, conta kill e tenta próximo
        killCount = killCount + 1
        
        if killCount >= config.count then
            -- Completou ciclo de kills, verifica se upou de level
            killCount = 0
            currentNPCIndex = 1
            
            -- Verifica se o level mudou (pegando config novamente)
            local newConfig = getCurrentConfig()
            if newConfig.npc ~= config.npc then
                -- Level upou! Vai mudar de mob automaticamente na próxima iteração
                lastPortaledMob = nil
            end
            return
        else
            -- Próximo NPC do mesmo mob
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    else
        -- NPC vivo, vai farmar usando Tween
        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        if npcRoot then
            local offset = CFrame.new(0, currentHeight, currentDist)
            local targetCFrame = npcRoot.CFrame * offset
            
            local hasArrived = moveToTarget(targetCFrame)
            
            if hasArrived then
                equipWeapon()
                performAttack()
            end
        else
            -- Sem HumanoidRootPart, pula para próximo
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    end
end

local function startAutoLevel()
    if isFarming then stopAutoLevel(); task.wait(0.2) end
    initialize()
    if not npcsFolder then return false end
    isFarming = true
    resetFarmState()
    startQuestLoop()
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

Tab:Section({Title = "Auto Level"})

Tab:Toggle({
    Title = "Auto Farm Level",
    Value = _G.SlowHub.AutoFarmLevel or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmLevel = false
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({
                        Title = "Error",
                        Content = "Select a weapon first!",
                        Duration = 3,
                    })
                end
                return
            end
            startAutoLevel()
        else
            stopAutoLevel()
        end
    end,
})

Tab:Section({Title = "Farm Settings"})

-- NOVO: Slider de Tween Speed (igual ao primeiro código)
Tab:Slider({
    Title = "Tween Speed",
    Flag = "TweenSpeed",
    Step = 10,
    Value = {
        Min = 150,
        Max = 500,
        Default = _G.SlowHub.TweenSpeed or 500,
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Farm Distance",
    Flag = "FarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.FarmDistance or 8,
    },
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Farm Height",
    Flag = "FarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.FarmHeight or 4,
    },
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "FarmCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.FarmCooldown or 0.15,
    },
    Callback = function(Value)
        _G.SlowHub.FarmCooldown = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Slider({
    Title = "Quest Interval",
    Flag = "QuestInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 5,
        Default = _G.SlowHub.QuestInterval or 2,
    },
    Callback = function(Value)
        _G.SlowHub.QuestInterval = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

-- Auto-start
if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    startAutoLevel()
end
