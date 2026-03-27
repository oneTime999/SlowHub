local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

-- ============================================================
-- VERIFICAÇÃO DE DEPENDÊNCIAS
-- ============================================================

if not Tab then
    warn("SlowHub: MainTab não encontrado!")
    return
end

if not _G.SlowHub then
    _G.SlowHub = {}
end

-- ============================================================
-- CONFIGURAÇÕES DE MOBS
-- ============================================================

local MobList = {
    "Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer",
    "Hollow", "StrongSorcerer", "Curse", "Slime", "AcademyTeacher"
}

local QuestConfig = {
    ["Thief"]          = "QuestNPC1",
    ["Monkey"]         = "QuestNPC3",
    ["DesertBandit"]   = "QuestNPC5",
    ["FrostRogue"]     = "QuestNPC7",
    ["Sorcerer"]       = "QuestNPC9",
    ["Hollow"]         = "QuestNPC11",
    ["StrongSorcerer"] = "QuestNPC12",
    ["Curse"]          = "QuestNPC13",
    ["Slime"]          = "QuestNPC14",
    ["AcademyTeacher"] = "QuestNPC15"
}

local MobPortalArgs = {
    ["Thief"]          = "Starter",
    ["Monkey"]         = "Jungle",
    ["DesertBandit"]   = "Desert",
    ["FrostRogue"]     = "Frost",
    ["Sorcerer"]       = "Magic",
    ["Hollow"]         = "Dark",
    ["StrongSorcerer"] = "Ruins",
    ["Curse"]          = "Curse",
    ["Slime"]          = "Slime",
    ["AcademyTeacher"] = "Academy"
}

-- ============================================================
-- CONSTANTES
-- ============================================================

local TWEEN_SPEED    = 32
local MIN_TWEEN_DIST = 3
local KILLS_PER_MOB  = 5
local PORTAL_WAIT    = 1.5

-- ============================================================
-- ESTADO INTERNO
-- ============================================================

local farmConnection   = nil
local questLoop        = nil
local isFarming        = false
local isQuesting       = false
local selectedMobs     = {}
local currentMobIndex  = 1
local currentNPCIndex  = 1
local killCount        = 0
local lastTargetName   = nil
local hasPortalFired   = false
local isTweening       = false
local wasAttackingBoss = false
local lastAttackTime   = 0
local activeTween      = nil

local character        = nil
local humanoidRootPart = nil
local humanoid         = nil
local npcsFolder       = nil

-- ============================================================
-- INICIALIZAÇÃO
-- ============================================================

local function initialize()
    character        = Player.Character
    humanoid         = character and character:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    npcsFolder       = workspace:FindFirstChild("NPCs")
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character        = char
    humanoid         = nil
    humanoidRootPart = nil
    isTweening       = false
    if activeTween then activeTween:Cancel() end
    task.wait(0.1)
    humanoid         = char:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then npcsFolder = child end
end)

-- ============================================================
-- HELPERS NPC
-- ============================================================

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
    local h = npc:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getNextIndex(current, maxCount)
    local next = current + 1
    return next > maxCount and 1 or next
end

local function getNextMobIndex()
    return getNextIndex(currentMobIndex, #selectedMobs)
end

-- ============================================================
-- TWEEN DE MOVIMENTO
-- ============================================================

local function tweenTo(targetCFrame, callback)
    if not humanoidRootPart then
        if callback then callback(false) end
        return
    end

    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
    local duration = math.max(distance / TWEEN_SPEED, 0.05)

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)

    isTweening  = true
    local tween = TweenService:Create(humanoidRootPart, tweenInfo, {C {CFrame = targetCFrame})
    activeTween = tween

    tween.Completed:Connect(function(state)
        isTweening  = false
        activeTween = nil
        if callback then callback(state == Enum.PlaybackState.Completed) end
    end)

    tween:Play()
end

-- ============================================================
-- PORTAL DO JOGO
-- ============================================================

local function firePortalRemote(mobName)
    local arg = MobPortalArgs[mobName]
    if not arg then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local remote = remotes:FindFirstChild("TeleportToPortal")
        if remote then remote:FireServer(arg) end
    end)
end

-- ============================================================
-- EQUIPAR ARMA
-- ============================================================

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        if not character or not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then humanoid:EquipTool(weapon) end
    end)
end

-- ============================================================
-- ATAQUE
-- ============================================================

local function performAttack()
    local now      = tick()
    local cooldown = _G.SlowHub.FarmCooldown or 0.15
    if now - lastAttackTime < cooldown then return end
    lastAttackTime = now
    pcall(function()
        local cs = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not cs then return end
        local remotes = cs:FindFirstChild("Remotes")
        if not remotes then return end
        local rh = remotes:FindFirstChild("RequestHit")
        if rh then rh:FireServer() end
    end)
end

-- ============================================================
-- QUEST
-- ============================================================

local function acceptQuest()
    if not _G.SlowHub.AutoQuestSelectedMob then return end
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local mob = selectedMobs[currentMobIndex]
        if not mob then return end
        local questName = QuestConfig[mob]
        if not questName then return end
        local re = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not re then return end
        local qa = re:FindFirstChild("QuestAccept")
        if qa then qa:FireServer(questName) end
    end)
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

-- ============================================================
-- CONTROLE DE MOB / RESET
-- ============================================================

local function switchToNextMob()
    currentMobIndex = getNextNextMobIndex()
    currentNPCIndex = 1
    killCount       = 0
    hasPortalFired  = false
    isTweening      = false
    if activeTween then activeTween:Cancel() end
end

local function resetFarmState()
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount       = 0
    lastTargetName  = nil
    hasPortalFired  = false
    isTweening      = false
    lastAttackTime  = 0
    if activeTween then activeTween:Cancel() activeTween = nil end
end

-- ============================================================
-- STOP / START
-- ============================================================

local function stopAutoFarm()
    if not isFarming then return end
    isFarming = false
    if farmConnection then farmConnection:Disconnect() farmConnection = nil end
    stopQuestLoop()
    resetFarmState()
    pcall(function()
        if humanoidRootPart then humanoidRootPart.AssemblyLinearVelocity = Vector3.zero end
    end)
end

-- ============================================================
-- FARM LOOP
-- ============================================================

local function farmLoop()
    if not _G.SlowHub.AutoFarmSelectedMob then stopAutoFarm() return end

    if isTweening then return end

    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then humanoid = character:FindFirstChildOfClass("Humanoid") end
    if not humanoid or humanoid.Health <= 0 then return end

    if _G.SlowHub.IsAttackingBoss then wasAttackingackingBoss = true return end
    if wasAttackingBoss then hasPortalFired = false wasAttackingBoss = false end

    if #selectedMobs == 0 then stopAutoFarm() return end

    local currentMobName = selectedMobs[currentMobIndex]
    if not currentMobName then
        currentMobIndex = 1
        currentMobName  = selectedMobs[1]
        if not currentMobName then stopAutoFarm() return end
    end

    -- ETAPA 1: TeleportToPortal
    if currentMobName ~= lastTargetName then
        lastTargetName = currentMobName
        hasPortalFired = false
    end

    if not hasPortalFired then
        hasPortalFired = true
        firePortalRemote(currentMobName)
        task.wait(PORTAL_WAIT)
        return
    end

    -- ETAPA 2: Persegue e ataca o NPC
    local npc = getNPC(currentMobName, currentNPCIndex)

    if not isNPCAlive(npc) then
        killCount = killCount + 1
        if killCount >= KILLS_PER_MOB then
            switchToNextMob()
        else
            currentNPCIndex = getNextIndex(currentNPCIndex, 5)
        end
        return
    end

    local npcRoot = getNPCRootPart(npc)
    if not npcRoot then
        currentNPCIndex = getNextIndex(currentNPCIndex, 5)
        return
    end

    local height   = _G.SlowHub.FarmHeight   or 4
    local farmDist = _G.SlowHub.FarmDistance or 8
    local targetCF = npcRoot.CFrame * CFrame.new(0, height, farmDist)
    local dist     = (humanoidRootPart.Position - targetCF.Position).Magnitude

    if dist > MIN_TWEEN_DIST then
        tweenTo(targetCF, function(ok)
            if ok then equipWeapon() performAttack() end
        end)
    else
        equipWeapon()
        performAttack()
    end
end

local function startAutoFarm()
    if isFarming then stopAutoFarm() task.wait(0.2) end
    initialize()
    if #selectedMobs == 0 then return false end
    if not npcsFolder then return then return false end
    isFarming = true
    resetFarmState()
    if _G.SlowHub.AutoQuestSelectedMob then startQuestLoop() end
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

-- ============================================================
-- ATUALIZA LISTA DE MOBS
-- ============================================================

local function updateSelectedMobs(options)
    selectedMobs = {}
    if type(options) == "table" then
        for _, v in ipairs(options) do table.insert(selectedMobs, tostring(v)) end
    end
    resetFarmState()
    if _G.SlowHub.AutoFarmSelectedMob and #selectedMobs > 0 then
        stopAutoFarm() task.wait(0.1) startAutoFarm()
    elseif #selectedMobs == 0 then
        stopAutoFarm()
    end
end

-- ============================================================
-- UI COM PCALL DE PROTEÇÃO
-- ============================================================

local success, err = pcall(function()

    Tab:Section({Title = "Mob Selection"})

    Tab:Dropdown({
        Title    = "Select Mobs (Multi Select)",
        Flag     = "SelectedMobs",
        Values   = MobList,
        Multi    = true,
        Value    = _G.SlowHub.SelectedMobs or {},
        Callback = function(Option)
            updateSelectedMobs(Option)
            _G.SlowHub.SelectedMobs = selectedMobs
            if _G.SaveConfig then _G.SaveConfig() end
        end
    })

    Tab:Section({Title = "Farm Control"})

    Tab:Toggle({
        Title    = "Auto Farm Selected Mobs",
        Value    = _G.SlowHub.AutoFarmSelectedMob or false,
        Callback = function(Value)
            if Value then
                if not _G.SlowHub.SelectedWeapon then
                    if _G.WindUI and _G.WindUI.Notify then
                        _G.WindUI:Notify({Title = "Error", Content = "Please select a weapon first!", Duration = 3})
                    end
                    return
                end
                if #selectedMobs == 0 then
                    if _G.WindUI and _G.WindUI.Notify then
                        _G.WindUI:Notify({Title = "Error", Content = "Please select at least one mob!", Duration = 3})
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
        Title    = "Auto Quest",
        Value    = _G.SlowHub.AutoQuestSelectedMob or false,
        Callback = function(Value)
            _G.SlowHub.AutoQuestSelectedMob = Value
            if _G.SaveConfig then _G.SaveConfig() end
            if Value then startQuestLoop() else stopQuestLoop() end
        end
    })

    Tab:Slider({
        Title = "Farm Distance",  Flag = "FarmDistance",  Step = 1,
        Value = {Min = 1, Max = 10, Default = _G.SlowHub.FarmDistance or 8},
        Callback = function(Value) _G.SlowHub.FarmDistance = Value if _G.SaveConfig then _G.SaveConfig() end end
    })

    Tab:Slider({
        Title = "Farm Height",  Flag = "FarmHeight",  Step = 1,
        Value = {Min = 1, Max = 10, Default = _G.SlowHub.FarmHeight or 4},
        Callback = function(Value) _G.SlowHub.FarmHeight = Value if _G.SaveConfig then _G.SaveConfig() end end
    })

    Tab:Slider({
        Title = "Attack Cooldown",  Flag = "FarmCooldown",  Step = 0.05,
        Value = {Min = 0.05, Max = 0.5, Default = _G.SlowHub.FarmCooldown or 0.15},
        Callback = function(Value) _G.SlowHub.FarmCooldown = Value if _G.SaveConfig then _G.SaveConfig() end end
    })

    Tab:Slider({
        Title = "Quest Interval",  Flag = "AutoQuestInterval",  Step = 0.5,
        Value = {Min = 1, Max = 5, Default = _G.SlowHub.AutoQuestInterval or 2},
        Callback = function(Value) _G.SlowHub.AutoQuestInterval = Value if _G.SaveConfig then _G.SaveConfig() end end
    })

end)

if not success then
    warn("SlowHub Farm: Erro ao criar UI - " .. tostring(err))
end

-- ============================================================
-- RESTAURA ESTADO SALVO
-- ============================================================

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.SelectedMobs then updateSelectedMobs(_G.SlowHub.SelectedMobs) end
    if _G.SlowHub.AutoFarmSelectedMob then startAutoFarm() end
    if _G.SlowHub.AutoQuestSelectedMob then startQuestLoop() end
end)

print("SlowHub Farm Module carregado com sucesso!")
    
