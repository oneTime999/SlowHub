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
    ["Swordsman"] = "Judgement",
    ["Quincy"] = "SoulDominion",
    ["Ninja"] = "Ninja",
    ["ArenaFighter"] = "Lawless"
}

-- Contadores de NPCs por mob (ajuste se necessário)
local MobCounts = {
    ["Thief"] = 5, ["Monkey"] = 5, ["DesertBandit"] = 5,
    ["FrostRogue"] = 5, ["Sorcerer"] = 5, ["Hollow"] = 5,
    ["StrongSorcerer"] = 5, ["Curse"] = 5, ["Slime"] = 5,
    ["AcademyTeacher"] = 5, ["Swordsman"] = 5, ["Quincy"] = 5,
    ["Ninja"] = 5, ["ArenaFighter"] = 5
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

-- NOVO: Sistema de estado claro
local FarmState = {
    NEED_PORTAL = "NEED_PORTAL",    -- Precisa teleportar para o portal do mob atual
    WAITING_SPAWN = "WAITING_SPAWN", -- Teleportou, aguardando NPCs spawnarem
    FARMING = "FARMING",             -- Farmando NPCs normalmente
    WAITING_KILL = "WAITING_KILL"    -- Matou NPC, aguardando confirmação de morte
}

local currentState = FarmState.NEED_PORTAL
local currentMobInPortal = nil  -- Qual mob estamos atualmente no portal (pode ser diferente do selecionado se ainda não teleportou)
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 8
local lastPortalUse = 0
local PORTAL_COOLDOWN = 2  -- Segundos entre usos de portal para evitar spam

local currentTween = nil
local lastTweenTarget = nil
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
    -- Resetar estado ao morrer/respawnar
    currentState = FarmState.NEED_PORTAL
    currentMobInPortal = nil
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

local function countAliveNPCs(mobName)
    if not npcsFolder then return 0 end
    local count = 0
    local maxCount = MobCounts[mobName] or 5
    for i = 1, maxCount do
        local npc = npcsFolder:FindFirstChild(mobName .. i)
        if isNPCAlive(npc) then
            count = count + 1
        end
    end
    return count
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
    return QuestConfig[mobName]
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

local function usePortal(mobName)
    local portalName = MobPortals[mobName]
    if not portalName then return false end
    
    local timeSinceLastPortal = tick() - lastPortalUse
    if timeSinceLastPortal < PORTAL_COOLDOWN then
        task.wait(PORTAL_COOLDOWN - timeSinceLastPortal)
    end
    
    local success = pcall(function()
        local args = { [1] = portalName }
        ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
    end)
    
    if success then
        lastPortalUse = tick()
        currentMobInPortal = mobName
        currentState = FarmState.WAITING_SPAWN
        spawnWaitStart = tick()
        currentNPCIndex = 1
        killCount = 0
        cancelTween()
    end
    
    return success
end

local function resetFarmState()
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount = 0
    currentState = FarmState.NEED_PORTAL
    currentMobInPortal = nil
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
            task.wait(0.3)
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
    
    -- Se estiver atacando boss, pausa tudo
    if _G.SlowHub.IsAttackingBoss then
        cancelTween()
        return
    end

    -- Verifica mob atual selecionado
    local targetMobName = selectedMobs[currentMobIndex]
    if not targetMobName then
        -- Tenta ir para o primeiro ou para
        currentMobIndex = 1
        targetMobName = selectedMobs[1]
        if not targetMobName then
            stopAutoFarm()
            _G.SlowHub.AutoFarmSelectedMob = false
            return
        end
    end

    local maxCount = MobCounts[targetMobName] or 5
    
    -- ESTADO 1: PRECISA USAR PORTAL (mudou de mob ou primeira vez)
    if currentState == FarmState.NEED_PORTAL then
        -- Só usa portal se não estiver no portal correto
        if currentMobInPortal ~= targetMobName then
            usePortal(targetMobName)
            task.wait(0.5) -- Aguarda teleporte iniciar
            return
        else
            -- Já está no portal correto, vai para farmar
            currentState = FarmState.FARMING
        end
    end
    
    -- ESTADO 2: AGUARDANDO SPAWN APÓS PORTAL
    if currentState == FarmState.WAITING_SPAWN then
        -- Verifica se algum NPC do mob alvo está vivo
        local aliveCount = countAliveNPCs(targetMobName)
        
        if aliveCount > 0 then
            -- NPCs spawnaram! Começar farm
            currentState = FarmState.FARMING
            currentNPCIndex = 1
            killCount = 0
        else
            -- Ainda esperando
            local elapsed = tick() - spawnWaitStart
            if elapsed > MAX_SPAWN_WAIT then
                -- Timeout, força novo portal
                currentState = FarmState.NEED_PORTAL
                currentMobInPortal = nil
            end
            -- Fica parado esperando
            cancelTween()
        end
        return
    end
    
    -- ESTADO 3: FARMANDO
    if currentState == FarmState.FARMING then
        -- Verifica se ainda estamos no portal correto (segurança)
        if currentMobInPortal ~= targetMobName then
            currentState = FarmState.NEED_PORTAL
            return
        end
        
        -- Verifica quantos NPCs estão vivos
        local aliveCount = countAliveNPCs(targetMobName)
        
        -- Se nenhum vivo, espera (não muda de mob automaticamente)
        if aliveCount == 0 then
            -- Verifica se já matamos algum (killCount > 0) - se sim, talvez estejam respawnando
            if killCount > 0 then
                -- Espera respawn no mesmo lugar
                currentState = FarmState.WAITING_SPAWN
                spawnWaitStart = tick()
            else
                -- Nunca viu NPCs vivos, algo errado, força portal
                currentState = FarmState.NEED_PORTAL
            end
            cancelTween()
            return
        end
        
        -- Procura o próximo NPC vivo na sequência
        local npc = nil
        local npcRoot = nil
        local attempts = 0
        
        while attempts < maxCount do
            local tempNpc = getNPC(targetMobName, currentNPCIndex)
            if isNPCAlive(tempNpc) then
                npc = tempNpc
                npcRoot = getNPCRootPart(npc)
                break
            end
            -- Próximo índice
            currentNPCIndex = getNextIndex(currentNPCIndex, maxCount)
            attempts = attempts + 1
        end
        
        if npc and npcRoot then
            -- Farmar este NPC
            local currentHeight = _G.SlowHub.FarmHeight or 4
            local currentDist = _G.SlowHub.FarmDistance or 8
            
            local offset = CFrame.new(0, currentHeight, currentDist)
            local targetCFrame = npcRoot.CFrame * offset
            
            local hasArrived = moveToTarget(targetCFrame)
            
            if hasArrived then
                equipWeapon()
                performAttack()
                
                -- Verifica se matou
                if not isNPCAlive(npc) then
                    killCount = killCount + 1
                    -- Próximo índice para próximo frame
                    currentNPCIndex = getNextIndex(currentNPCIndex, maxCount)
                end
            end
        else
            -- Não encontrou NPC vivo apesar de count > 0 (inconsistência)
            -- Volta a esperar
            currentState = FarmState.WAITING_SPAWN
            spawnWaitStart = tick()
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

-- UI Elements
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
        Default = _G.SlowHub.TweenSpeed or 500,
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

-- Adicionar botão para trocar manualmente de mob (opcional)
Tab:Button({
    Title = "Next Mob (Manual)",
    Callback = function()
        if #selectedMobs > 1 then
            currentMobIndex = getNextMobIndex()
            currentState = FarmState.NEED_PORTAL
            if _G.WindUI and _G.WindUI.Notify then
                _G.WindUI:Notify({
                    Title = "Switched",
                    Content = "Now targeting: " .. selectedMobs[currentMobIndex],
                    Duration = 2,
                })
            end
        end
    end
})

-- Inicialização
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
