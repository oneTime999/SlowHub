local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MobList = {
    "Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer", 
    "Hollow", "StrongSorcerer", "Curse", "Slime", "AcademyTeacher",
    "Swordsman", "Quincy", "Ninja", "ArenaFighter"
}

local QuestConfig = {
    ["Thief"] = "QuestNPC1",
    ["Monkey"] = "QuestNPC3", 
    ["DesertBandit"] = "QuestNPC5",
    ["FrostRogue"] = "QuestNPC7",
    ["Sorcerer"] = "QuestNPC9",
    ["Hollow"] = "QuestNPC11",
    ["StrongSorcerer"] = "QuestNPC12",
    ["Curse"] = "QuestNPC13",
    ["Slime"] = "SlimeNPC14",
    ["AcademyTeacher"] = "QuestNPC15",
    -- Novas Quests
    ["Swordsman"] = "QuestNPC16",
    ["Quincy"] = "QuestNPC17",
    ["Ninja"] = "QuestNPC18",
    ["ArenaFighter"] = "QuestNPC19"
}

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
    -- Novos Portais
    ["Swordsman"] = "Judgement",
    ["Quincy"] = "SoulDominion",
    ["Ninja"] = "Ninja",
    ["ArenaFighter"] = "Lawless"
}

local questLoop = nil
local farmLoop = nil
local noclipConnection = nil
local isFarming = false
local isQuesting = false
local selectedMobs = {}
local currentMobIndex = 1
local currentNPCIndex = 1
local killCount = 0
local lastTargetName = nil
local wasAttackingBoss = false
local lastValidQuest = nil
local character = nil
local humanoidRootPart = nil
local humanoid = nil
local npcsFolder = nil

local currentTween = nil
local lastTweenTarget = nil

-- NOVO: Sistema de controle de portal por mob específico
local lastPortaledMob = nil  -- Nome do último mob que usou portal
local waitingForSpawn = false
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 10

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
    if child.Name == "NPCs" then
        npcsFolder = child
    end
end)

local function getNPC(npcName, index)
    if not npcsFolder then return nil end
    return npcsFolder:FindFirstChild(npcName .. index)
end

local function getNPCRootPart(npc)
    if not npc then return nil end
    return npc:FindFirstChild("HumanoidRootPart")
end

local function isNPCAlive(npc)
    if not npc or not npc.Parent then return false end
    local hum = npc:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

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

local function getNextIndex(current, maxCount)
    local nextIndex = current + 1
    if nextIndex > maxCount then return 1 end
    return nextIndex
end

local function getNextMobIndex()
    local nextIndex = currentMobIndex + 1
    if nextIndex > #selectedMobs then return 1 end
    return nextIndex
end

local function getQuestForMob(mobName)
    local quest = QuestConfig[mobName]
    if quest then
        lastValidQuest = quest
        return quest
    end
    return nil
end

local function getMobConfig(mobName)
    return {
        npc = mobName,
        quest = getQuestForMob(mobName),
        count = 5
    }
end

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        if not character or not humanoid then return false end
        local hasEquipped = character:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if hasEquipped then return true end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return false end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then
            humanoid:EquipTool(weapon)
            return true
        end
        return false
    end)
    return success
end

local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
end

local function moveToTarget(targetCFrame)
    if not humanoidRootPart then return false end

    local currentFarmDist = _G.SlowHub.FarmDistance or 8
    local currentSpeed = _G.SlowHub.TweenSpeed or 500

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude

    if distance <= currentFarmDist + 2 then
        cancelTween()
        humanoidRootPart.CFrame = targetCFrame
        return true
    end

    if lastTweenTarget then
        local posDiff = (lastTweenTarget.Position - targetCFrame.Position).Magnitude
        if posDiff > 1 then
            cancelTween()
        elseif currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
            return false
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
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if combatSystem then
            local remotes = combatSystem:FindFirstChild("Remotes")
            if remotes then
                local requestHit = remotes:FindFirstChild("RequestHit")
                if requestHit then 
                    requestHit:FireServer() 
                end
            end
        end
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end
    end)
end

local function acceptQuest()
    if not _G.SlowHub.AutoQuestSelectedMob or _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local currentMob = selectedMobs[currentMobIndex]
        if not currentMob then return end
        local questToAccept = getQuestForMob(currentMob)
        if not questToAccept then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then
            questAccept:FireServer(questToAccept)
        end
    end)
end

local function switchToNextMob()
    currentMobIndex = getNextMobIndex()
    currentNPCIndex = 1
    killCount = 0
    waitingForSpawn = false
    -- NÃO resetar lastPortaledMob aqui! Ele vai detectar mudança pelo currentMobName ~= lastPortaledMob
    cancelTween()
end

local function resetFarmState()
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount = 0
    lastTargetName = nil
    lastPortaledMob = nil  -- Reset completo
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
    task.spawn(function()
        while isQuesting do 
            acceptQuest()
            task.wait(0.2)
        end
    end)
end

local function stopAutoFarm()
    isFarming = false
    cancelTween()
    stopQuestLoop()
    resetFarmState()
    
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    if farmLoop then
        farmLoop:Disconnect()
        farmLoop = nil
    end

    pcall(function()
        if humanoidRootPart then
            humanoidRootPart.Anchored = false
            local velocityFix = humanoidRootPart:FindFirstChild("SlowHubVelocity")
            if velocityFix then velocityFix:Destroy() end
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function doFarmLogic()
    if not isFarming then return end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
    end
    
    if _G.SlowHub.IsAttackingBoss then
        wasAttackingBoss = true
        cancelTween()
        return
    end
    if wasAttackingBoss then
        lastPortaledMob = nil  -- Força re-teleporte após boss
        wasAttackingBoss = false
    end

    local currentMobName = selectedMobs[currentMobIndex]
    if not currentMobName then
        currentMobIndex = 1
        currentMobName = selectedMobs[1]
        if not currentMobName then
            stopAutoFarm()
            _G.SlowHub.AutoFarmSelectedMob = false
            return
        end
    end

    -- Sincronização: Se mudou de mob, garante que vai usar o portal do novo
    if currentMobName ~= lastTargetName then
        lastTargetName = currentMobName
        lastPortaledMob = nil  -- Força teleporte para o novo mob
        waitingForSpawn = false
        currentNPCIndex = 1
        killCount = 0
        cancelTween()
    end

    local config = getMobConfig(currentMobName)

    -- CORREÇÃO: Só pode farmar se já usou o portal deste mob específico
    if lastPortaledMob ~= currentMobName then
        local portalName = MobPortals[currentMobName]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Aumentado para garantir o teleporte
        end
        lastPortaledMob = currentMobName  -- Marca que tentou usar portal deste mob
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
            lastPortaledMob = nil  -- Isso vai forçar teleporte novamente na próxima iteração
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
    local isAlive = isNPCAlive(npc)

    if not isAlive then
        -- NPC morto, conta kill e tenta próximo
        killCount = killCount + 1
        
        if killCount >= config.count then
            -- Completou 5 kills, troca de mob
            -- Isso vai mudar currentMobIndex, e na próxima iteração 
            -- currentMobName será diferente, forçando teleporte
            switchToNextMob()
            return
        else
            -- Próximo NPC do mesmo mob
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    else
        -- NPC vivo, vai farmar
        local npcRoot = getNPCRootPart(npc)
        if npcRoot then
            local offset = CFrame.new(0, currentHeight, currentDist)
            local targetCFrame = npcRoot.CFrame * offset
            
            local hasArrived = moveToTarget(targetCFrame)
            
            if hasArrived then
                equipWeapon()
                performAttack()
            end
        end
    end
end

local function startAutoFarm()
    if isFarming then
        stopAutoFarm()
        task.wait(0.1)
    end
    initialize()
    if #selectedMobs == 0 then return false end
    if not npcsFolder then return false end
    
    isFarming = true
    resetFarmState()
    
    if _G.SlowHub.AutoQuestSelectedMob then
        startQuestLoop()
    end
    
    if humanoidRootPart then
        humanoidRootPart.Anchored = false
        local bv = Instance.new("BodyVelocity")
        bv.Name = "SlowHubVelocity"
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Parent = humanoidRootPart
    end

    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(function()
            if not isFarming then return end
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
    end

    if not farmLoop then
        farmLoop = RunService.Heartbeat:Connect(doFarmLogic)
    end
    
    return true
end

local function updateSelectedMobs(options)
    selectedMobs = {}
    if type(options) == "table" then
        for _, value in ipairs(options) do
            table.insert(selectedMobs, tostring(value))
        end
    end
    resetFarmState()
    if _G.SlowHub.AutoFarmSelectedMob and #selectedMobs > 0 then
        stopAutoFarm()
        task.wait(0.1)
        startAutoFarm()
    elseif #selectedMobs == 0 then
        stopAutoFarm()
        _G.SlowHub.AutoFarmSelectedMob = false
    end
end

Tab:Section({Title = "Mob Selection"})

Tab:Dropdown({
    Title = "Select Mobs (Multi Select)",
    Flag = "SelectedMobs",
    Values = MobList,
    Multi = true,
    Value = _G.SlowHub.SelectedMobs or {},
    Callback = function(Option)
        updateSelectedMobs(Option)
        _G.SlowHub.SelectedMobs = selectedMobs
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Section({Title = "Farm Control"})

Tab:Toggle({
    Title = "Auto Farm Selected Mobs",
    Value = _G.SlowHub.AutoFarmSelectedMob or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmSelectedMob = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon or #selectedMobs == 0 then
                _G.SlowHub.AutoFarmSelectedMob = false
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({
                        Title = "Error",
                        Content = "Check weapon and mobs!",
                        Duration = 3,
                    })
                end
                return
            end
            startAutoFarm()
        else
            stopAutoFarm()
        end
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Toggle({
    Title = "Auto Quest",
    Value = _G.SlowHub.AutoQuestSelectedMob or false,
    Callback = function(Value)
        _G.SlowHub.AutoQuestSelectedMob = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value and _G.SlowHub.AutoFarmSelectedMob then
            startQuestLoop()
        else
            stopQuestLoop()
        end
    end
})

Tab:Slider({
    Title = "Tween Speed",
    Flag = "TweenSpeed",
    Step = 10,
    Value = {
        Min = 150,
        Max = 500,
        Default = _G.SlowHub.TweenSpeed or 250,
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end
})

Tab:Slider({
    Title = "Farm Distance",
    Flag = "FarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.FarmDistance or 9,
    },
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end
})

Tab:Slider({
    Title = "Farm Height",
    Flag = "FarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.FarmHeight or 6,
    },
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.SelectedMobs then
        updateSelectedMobs(_G.SlowHub.SelectedMobs)
    end
    if _G.SlowHub.AutoFarmSelectedMob then
        startAutoFarm()
    end
    if _G.SlowHub.AutoQuestSelectedMob and _G.SlowHub.AutoFarmSelectedMob then
        startQuestLoop()
    end
end)
