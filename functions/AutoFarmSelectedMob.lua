local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local MobList = {
    "Thief", 
    "Monkey", 
    "DesertBandit", 
    "FrostRogue", 
    "Sorcerer", 
    "Hollow", 
    "StrongSorcerer", 
    "Curse",
    "Slime",
    "AcademyTeacher"
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
    ["Slime"] = "QuestNPC14",
    ["AcademyTeacher"] = "QuestNPC15"
}

-- [!] IMPORTANTE: Altere os nomes das strings para os exatos nomes dos portais no jogo!
local MobPortals = {
    ["Thief"] = "Starter",
    ["Monkey"] = "Jungle", 
    ["DesertBandit"] = "Desert",
    ["FrostRogue"] = "Snow",
    ["Sorcerer"] = "Magic",
    ["Hollow"] = "Hueco",
    ["StrongSorcerer"] = "Magic2",
    ["Curse"] = "Cursed",
    ["Slime"] = "SlimeForest",
    ["AcademyTeacher"] = "Academy"
}

local questLoop = nil
local isFarming = false
local isQuesting = false
local selectedMobs = {}
local currentMobIndex = 1
local currentNPCIndex = 1
local killCount = 0
local lastTargetName = nil
local hasUsedPortal = false
local wasAttackingBoss = false
local lastValidQuest = nil
local lastAttackTime = 0
local character = nil
local humanoidRootPart = nil
local humanoid = nil
local npcsFolder = nil

-- Variáveis para o Tween
local currentTween = nil
local lastTweenTarget = nil

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

local function getNextIndex(current, maxCount)
    local nextIndex = current + 1
    if nextIndex > maxCount then return 1 end
    return nextIndex
end

local function getNextMobIndex()
    return getNextIndex(currentMobIndex, #selectedMobs)
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

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
    local farmDist = _G.SlowHub.FarmDistance or 8

    -- Se estiver perto o suficiente (dentro do range de ataque + margem), apenas ajusta CFrame
    if distance <= farmDist + 2 then
        cancelTween()
        humanoidRootPart.CFrame = targetCFrame
        return true
    end

    -- Evita recriar o Tween a cada loop se o alvo não se moveu muito (evita engasgos)
    if lastTweenTarget and (lastTweenTarget.Position - targetCFrame.Position).Magnitude < 5 then
        if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
            return false
        end
    end

    lastTweenTarget = targetCFrame
    local speed = _G.SlowHub.TweenSpeed or 40 -- Velocidade padrão de andar é 16, 40 é mais que o dobro
    local timeToReach = distance / speed
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()

    return false
end

local function performAttack()
    local currentTime = tick()
    local cooldown = _G.SlowHub.FarmCooldown or 0.15
    if currentTime - lastAttackTime < cooldown then return end
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
    local oldTarget = selectedMobs[currentMobIndex]
    currentMobIndex = getNextMobIndex()
    local newTarget = selectedMobs[currentMobIndex]
    
    currentNPCIndex = 1
    killCount = 0
    
    -- Só reseta o teleporte se realmente formos para um Mob diferente.
    -- Se você selecionou só 1 mob, ele não vai teleportar de novo pra mesma área.
    if oldTarget ~= newTarget then
        hasUsedPortal = false
    end
end

local function resetFarmState()
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount = 0
    lastTargetName = nil
    hasUsedPortal = false
    lastValidQuest = nil
    lastAttackTime = 0
    cancelTween()
end

local function stopQuestLoop()
    isQuesting = false
end

local function startQuestLoop()
    if isQuesting then return end
    isQuesting = true
    questLoop = task.spawn(function()
        while isQuesting and _G.SlowHub.AutoQuestSelectedMob do 
            acceptQuest()
            task.wait(_G.SlowHub.AutoQuestInterval or 2)
        end
        isQuesting = false
    end)
end

local function stopAutoFarm()
    if not isFarming then return end
    isFarming = false
    cancelTween()
    stopQuestLoop()
    resetFarmState()
    pcall(function()
        if humanoidRootPart then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function farmLoop()
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
        hasUsedPortal = false -- Força usar o portal novamente após matar o Boss
        wasAttackingBoss = false
    end

    local currentMobName = selectedMobs[currentMobIndex]
    if not currentMobName then
        currentMobIndex = 1
        currentMobName = selectedMobs[1]
        if not currentMobName then
            stopAutoFarm()
            return
        end
    end

    if currentMobName ~= lastTargetName then
        lastTargetName = currentMobName
        hasUsedPortal = false
    end

    local config = getMobConfig(currentMobName)

    -- Lógica do Portal Integrada
    if not hasUsedPortal then
        local portalName = MobPortals[currentMobName]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(1.5) -- Pausa rápida para o mapa e o personagem carregarem pós-tp
        end
        hasUsedPortal = true
        return
    end

    local npc = getNPC(config.npc, currentNPCIndex)
    local isAlive = isNPCAlive(npc)

    if not isAlive then
        killCount = killCount + 1
        if killCount >= config.count then
            switchToNextMob()
            return
        else
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    else
        local npcRoot = getNPCRootPart(npc)
        if npcRoot then
            local offset = CFrame.new(0, _G.SlowHub.FarmHeight or 4, _G.SlowHub.FarmDistance or 8)
            local targetCFrame = npcRoot.CFrame * offset
            
            -- Move via Tween, e retorna "true" apenas quando já colou no NPC
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
        task.wait(0.2)
    end
    initialize()
    if #selectedMobs == 0 then return false end
    if not npcsFolder then return false end
    
    isFarming = true
    resetFarmState()
    
    if _G.SlowHub.AutoQuestSelectedMob then
        startQuestLoop()
    end
    
    -- Agora usamos um while loop em vez de Heartbeat. 
    -- É muito mais estável para evitar conflitos com o TweenService.
    task.spawn(function()
        while isFarming and _G.SlowHub.AutoFarmSelectedMob do
            farmLoop()
            task.wait(0.1) -- Delay pequeno para evitar crash e verificar movimento de forma suave
        end
    end)
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
    end
end

-- =====================================
-- UI (Menus)
-- =====================================

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
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({ Title = "Error", Content = "Please select a weapon first!", Duration = 3 })
                end
                return
            end
            if #selectedMobs == 0 then
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({ Title = "Error", Content = "Please select at least one mob!", Duration = 3 })
                end
                return
            end
            startAutoFarm()
        else
            stopAutoFarm()
        end
        _G.SlowHub.AutoFarmSelectedMob = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Toggle({
    Title = "Auto Quest",
    Value = _G.SlowHub.AutoQuestSelectedMob or false,
    Callback = function(Value)
        _G.SlowHub.AutoQuestSelectedMob = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            startQuestLoop()
        else
            stopQuestLoop()
        end
    end
})

Tab:Slider({
    Title = "Tween Speed",
    Flag = "TweenSpeed",
    Step = 1,
    Value = {
        Min = 16, -- Velocidade padrão de andar no Roblox
        Max = 150,
        Default = _G.SlowHub.TweenSpeed or 40, -- Cerca de 2x mais rápido que o padrão
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
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
    end
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
    end
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
    end
})

Tab:Slider({
    Title = "Quest Interval",
    Flag = "AutoQuestInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 5,
        Default = _G.SlowHub.AutoQuestInterval or 2,
    },
    Callback = function(Value)
        _G.SlowHub.AutoQuestInterval = Value
        if _G.SaveConfig then _G.SaveConfig() end
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
    if _G.SlowHub.AutoQuestSelectedMob then
        startQuestLoop()
    end
end)
