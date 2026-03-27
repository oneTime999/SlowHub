local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- ============================================================
-- CONFIGURAÇÃO
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

local MobPortals = {
    ["Thief"]          = "Starter",
    ["Monkey"]         = "Jungle",
    ["DesertBandit"]   = "Desert",
    ["FrostRogue"]     = "Snow",
    ["Sorcerer"]       = "Magic",
    ["Hollow"]         = "Hueco",
    ["StrongSorcerer"] = "Magic2",
    ["Curse"]          = "Cursed",
    ["Slime"]          = "SlimeForest",
    ["AcademyTeacher"] = "Academy"
}

-- Constantes de tempo
local PORTAL_WAIT_DURATION = 1.5   -- segundos aguardando área carregar após portal
local NPC_SPAWN_TIMEOUT    = 12    -- segundos antes de desistir e trocar de mob
local ATTACK_COOLDOWN      = 0.12  -- segundos entre ataques (evita spam de remotes)

-- ============================================================
-- ESTADO
-- ============================================================

local farmLoop            = nil
local noclipConnection    = nil
local characterDiedConn   = nil   -- FIX 10: rastrear conexão para desconectar

local isFarming           = false
local isQuesting          = false
local selectedMobs        = {}
local currentMobIndex     = 1
local currentNPCIndex     = 1
local killCount           = 0
local lastTargetName      = nil
local hasUsedPortal       = false
local wasAttackingBoss    = false
local lastValidQuest      = nil

-- Referências de personagem
local character           = nil
local humanoidRootPart    = nil
local humanoid            = nil
local npcsFolder          = nil

-- Estado do tween
local currentTween        = nil
local lastTweenTarget     = nil
local lastTweenNPCPos     = nil   -- FIX 4: detectar movimento do NPC

-- Temporização (sem task.wait dentro do Heartbeat — FIX 1)
local lastAttackTime      = 0
local portalTriggeredAt   = 0     -- tick() de quando o portal foi usado
local isPortalWaiting     = false  -- aguardando área carregar
local npcWaitStartTime    = 0      -- FIX 6: timeout de spawn

-- ============================================================
-- FUNÇÕES AUXILIARES
-- ============================================================

local function cancelTween()
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end
    lastTweenTarget = nil
    lastTweenNPCPos = nil
end

-- FIX 8: limpar BodyVelocity sem acumular instâncias
local function cleanupBodyVelocity()
    pcall(function()
        if humanoidRootPart then
            local bv = humanoidRootPart:FindFirstChild("SlowHubVelocity")
            if bv then bv:Destroy() end
        end
        -- Também verificar no personagem inteiro por segurança
        if character then
            for _, bv in ipairs(character:GetDescendants()) do
                if bv:IsA("BodyVelocity") and bv.Name == "SlowHubVelocity" then
                    bv:Destroy()
                end
            end
        end
    end)
end

local function createBodyVelocity()
    if not humanoidRootPart then return end
    cleanupBodyVelocity()  -- garantir que não há duplicata
    local bv = Instance.new("BodyVelocity")
    bv.Name     = "SlowHubVelocity"
    bv.Velocity  = Vector3.zero
    bv.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent    = humanoidRootPart
end

-- FIX 2: Configurar personagem com tratamento de morte
local function setupCharacter(char)
    character         = char
    humanoid          = nil
    humanoidRootPart  = nil

    -- FIX 10: desconectar conexão anterior antes de criar nova
    if characterDiedConn then
        characterDiedConn:Disconnect()
        characterDiedConn = nil
    end

    task.wait(0.1)
    humanoid         = char:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")

    if humanoid then
        characterDiedConn = humanoid.Died:Connect(function()
            -- Ao morrer: limpar tween e BV, resetar flags de portal
            cancelTween()
            cleanupBodyVelocity()
            hasUsedPortal    = false
            isPortalWaiting  = false
            npcWaitStartTime = 0
        end)
    end

    -- Se estava farmando, recriar BV após respawn
    if isFarming then
        task.wait(1.5)
        -- Reatualizar referências pós-respawn
        humanoid         = char:FindFirstChildOfClass("Humanoid")
        humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            createBodyVelocity()
        end
        -- Forçar retelporte na área correta
        hasUsedPortal    = false
        isPortalWaiting  = false
        npcWaitStartTime = 0
    end
end

local function initialize()
    character         = Player.Character
    humanoid          = character and character:FindFirstChildOfClass("Humanoid")
    humanoidRootPart  = character and character:FindFirstChild("HumanoidRootPart")
    npcsFolder        = workspace:FindFirstChild("NPCs")
end

initialize()

-- ============================================================
-- EVENTOS GLOBAIS
-- ============================================================

Player.CharacterAdded:Connect(function(char)
    setupCharacter(char)
end)

-- FIX 7: monitorar criação E remoção da pasta NPCs
workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        npcsFolder = child
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "NPCs" then
        npcsFolder = nil
    end
end)

-- ============================================================
-- HELPERS DE NPC / CONFIG
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
    local hum = npc:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getNextIndex(current, maxCount)
    local next = current + 1
    return next > maxCount and 1 or next
end

local function getNextMobIndex()
    local next = currentMobIndex + 1
    return next > #selectedMobs and 1 or next
end

local function getQuestForMob(mobName)
    local quest = QuestConfig[mobName]
    if quest then lastValidQuest = quest end
    return quest or nil
end

local function getMobConfig(mobName)
    return {
        npc   = mobName,
        quest = getQuestForMob(mobName),
        count = 5
    }
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
-- MOVIMENTO (FIX 4 + FIX 5)
-- ============================================================

local function moveToTarget(targetCFrame, npcRoot)
    if not humanoidRootPart then return false end

    local dist     = (humanoidRootPart.Position - targetCFrame.Position).Magnitude
    local farmDist = _G.SlowHub.FarmDistance or 8

    -- Já chegou
    if dist <= farmDist + 2 then
        cancelTween()
        humanoidRootPart.CFrame = targetCFrame
        return true
    end

    -- FIX 4: NPC se moveu muito → tween antigo é inválido
    if npcRoot and lastTweenNPCPos then
        if (npcRoot.Position - lastTweenNPCPos).Magnitude > 8 then
            cancelTween()
        end
    end

    -- Tween ainda válido e tocando
    if lastTweenTarget and currentTween
        and currentTween.PlaybackState == Enum.PlaybackState.Playing
        and (lastTweenTarget.Position - targetCFrame.Position).Magnitude < 5 then
        return false
    end

    -- FIX 5: criar tween limpo sem duplo-cancelamento
    cancelTween()

    local speed       = math.max(_G.SlowHub.TweenSpeed or 500, 1)
    local timeToReach = dist / speed
    local tweenInfo   = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    lastTweenTarget = targetCFrame
    if npcRoot then lastTweenNPCPos = npcRoot.Position end

    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()

    return false
end

-- ============================================================
-- ATAQUE (FIX 3: cooldown)
-- ============================================================

local function performAttack()
    local now = tick()
    if now - lastAttackTime < ATTACK_COOLDOWN then return end
    lastAttackTime = now

    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if combatSystem then
            local remotes    = combatSystem:FindFirstChild("Remotes")
            local requestHit = remotes and remotes:FindFirstChild("RequestHit")
            if requestHit then requestHit:FireServer() end
        end
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool then tool:Activate() end
        end
    end)
end

-- ============================================================
-- QUEST
-- ============================================================

local function acceptQuest()
    if not _G.SlowHub.AutoQuestSelectedMob or _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local currentMob = selectedMobs[currentMobIndex]
        if not currentMob then return end
        local questToAccept = getQuestForMob(currentMob)
        if not questToAccept then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        local questAccept  = remoteEvents and remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(questToAccept) end
    end)
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

-- ============================================================
-- CONTROLE DO FARM
-- ============================================================

local function resetFarmState()
    currentMobIndex  = 1
    currentNPCIndex  = 1
    killCount        = 0
    lastTargetName   = nil
    hasUsedPortal    = false
    isPortalWaiting  = false
    portalTriggeredAt = 0
    npcWaitStartTime = 0
    lastValidQuest   = nil
    cancelTween()
end

local function switchToNextMob()
    currentMobIndex  = getNextMobIndex()
    currentNPCIndex  = 1
    killCount        = 0
    hasUsedPortal    = false
    isPortalWaiting  = false
    npcWaitStartTime = 0
    cancelTween()
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
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
    cleanupBodyVelocity()
end

-- ============================================================
-- LÓGICA PRINCIPAL DO FARM (Heartbeat — sem task.wait! FIX 1)
-- ============================================================

local function doFarmLogic()
    if not isFarming then return end
    if not character or not character.Parent then return end

    -- Reatualizar referências se perdidas
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
    end

    -- Aguardar respawn se morto
    if humanoid.Health <= 0 then return end

    -- Pausa quando atacando boss
    if _G.SlowHub.IsAttackingBoss then
        wasAttackingBoss = true
        cancelTween()
        return
    end
    if wasAttackingBoss then
        hasUsedPortal    = false
        isPortalWaiting  = false
        wasAttackingBoss = false
    end

    -- Validar mob selecionado
    local currentMobName = selectedMobs[currentMobIndex]
    if not currentMobName then
        currentMobIndex = 1
        currentMobName  = selectedMobs[1]
        if not currentMobName then
            stopAutoFarm()
            _G.SlowHub.AutoFarmSelectedMob = false
            return
        end
    end

    -- Detectar troca de mob → resetar estado da área
    if currentMobName ~= lastTargetName then
        lastTargetName   = currentMobName
        hasUsedPortal    = false
        isPortalWaiting  = false
        npcWaitStartTime = 0
        currentNPCIndex  = 1
        killCount        = 0
        cancelTween()
    end

    local config = getMobConfig(currentMobName)

    -- ── ETAPA 1: Teleportar para o portal ──────────────────────
    if not hasUsedPortal then
        local portalName = MobPortals[currentMobName]
        if portalName then
            pcall(function()
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(portalName)
            end)
            portalTriggeredAt = tick()
            isPortalWaiting   = true
        end
        hasUsedPortal = true
        return
    end

    -- ── ETAPA 2: Aguardar área carregar (tick-based, sem yield) ──
    if isPortalWaiting then
        if tick() - portalTriggeredAt < PORTAL_WAIT_DURATION then
            return  -- área ainda carregando
        end
        isPortalWaiting  = false
        npcWaitStartTime = tick()  -- iniciar contador de spawn timeout
    end

    -- ── ETAPA 3: Aguardar NPC spawnar ─────────────────────────
    local npc = getNPC(config.npc, currentNPCIndex)

    if npc == nil then
        -- FIX 6: timeout — se NPC não spawna, trocar de mob
        if npcWaitStartTime == 0 then
            npcWaitStartTime = tick()
        elseif tick() - npcWaitStartTime > NPC_SPAWN_TIMEOUT then
            warn("[SlowHub] NPC '" .. config.npc .. currentNPCIndex .. "' não spawnou em "
                .. NPC_SPAWN_TIMEOUT .. "s. Trocando de mob.")
            switchToNextMob()
        end
        return  -- aguardar sem fazer nada
    end

    -- NPC existe: resetar timer de spawn
    npcWaitStartTime = 0

    -- ── ETAPA 4: Atacar ou avançar ────────────────────────────
    local isAlive = isNPCAlive(npc)

    if not isAlive then
        killCount = killCount + 1
        if killCount >= config.count then
            switchToNextMob()
        else
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    else
        local npcRoot = getNPCRootPart(npc)
        if npcRoot then
            local offset      = CFrame.new(0, _G.SlowHub.FarmHeight or 4, _G.SlowHub.FarmDistance or 8)
            local targetCFrame = npcRoot.CFrame * offset

            local hasArrived = moveToTarget(targetCFrame, npcRoot)
            if hasArrived then
                equipWeapon()
                performAttack()
            end
        end
    end
end

-- ============================================================
-- INICIAR FARM
-- ============================================================

local function startAutoFarm()
    if isFarming then
        stopAutoFarm()
        task.wait(0.1)
    end

    initialize()
    if #selectedMobs == 0 then return false end

    -- FIX 7: tentar achar npcsFolder se perdida
    if not npcsFolder then
        npcsFolder = workspace:FindFirstChild("NPCs")
        if not npcsFolder then return false end
    end

    isFarming = true
    resetFarmState()

    if _G.SlowHub.AutoQuestSelectedMob then
        startQuestLoop()
    end

    -- FIX 8: criar BV via função centralizada (sem duplicatas)
    if humanoidRootPart then
        humanoidRootPart.Anchored = false
        createBodyVelocity()
    end

    -- Noclip loop
    if not noclipConnection then
        noclipConnection = RunService.Stepped:Connect(function()
            if not isFarming then return end
            if not character then return end
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end

    -- Farm loop
    if not farmLoop then
        farmLoop = RunService.Heartbeat:Connect(doFarmLogic)
    end

    return true
end

-- ============================================================
-- ATUALIZAR LISTA DE MOBS SELECIONADOS (FIX 9)
-- ============================================================

local function updateSelectedMobs(options)
    selectedMobs = {}
    if type(options) == "table" then
        for _, value in ipairs(options) do
            table.insert(selectedMobs, tostring(value))
        end
    end

    if _G.SlowHub.AutoFarmSelectedMob then
        if #selectedMobs > 0 then
            -- FIX 9: apenas resetar estado, não parar/reiniciar o loop inteiro
            resetFarmState()
        else
            stopAutoFarm()
            _G.SlowHub.AutoFarmSelectedMob = false
        end
    end
end

-- ============================================================
-- INTERFACE
-- ============================================================

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
        _G.SlowHub.AutoFarmSelectedMob = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon or #selectedMobs == 0 then
                _G.SlowHub.AutoFarmSelectedMob = false
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({
                        Title   = "Error",
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
    Title    = "Auto Quest",
    Value    = _G.SlowHub.AutoQuestSelectedMob or false,
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
    Flag  = "TweenSpeed",
    Step  = 10,
    Value = {
        Min     = 16,
        Max     = 1000,
        Default = _G.SlowHub.TweenSpeed or 500,
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        cancelTween()
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Slider({
    Title = "Farm Distance",
    Flag  = "FarmDistance",
    Step  = 1,
    Value = {
        Min     = 1,
        Max     = 10,
        Default = _G.SlowHub.FarmDistance or 8,
    },
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        cancelTween()
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:Slider({
    Title = "Farm Height",
    Flag  = "FarmHeight",
    Step  = 1,
    Value = {
        Min     = 1,
        Max     = 10,
        Default = _G.SlowHub.FarmHeight or 4,
    },
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        cancelTween()
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

-- ============================================================
-- RESTAURAR ESTADO SALVO
-- ============================================================

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
