local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AnosBoss", "GilgameshBoss", "RimuruBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss",
    "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss",
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss",
    "AtomicBoss", "TrueAizenBoss", "SaberAlterBoss", "BlessedMaidenBoss", 
    "YamatoBoss", "StrongestShinobiBoss"
}

table.sort(bossList)

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossPortals = {
    ["AnosBoss"] = "Academy",
    ["GilgameshBoss"] = "Boss",
    ["RimuruBoss"] = "Slime",
    ["StrongestofTodayBoss"] = "Shinjuku",
    ["StrongestinHistoryBoss"] = "Shinjuku",
    ["IchigoBoss"] = "Boss",
    ["AizenBoss"] = "Hueco",
    ["AlucardBoss"] = "Sailor",
    ["QinShiBoss"] = "Boss",
    ["JinwooBoss"] = "Sailor",
    ["SukunaBoss"] = "Shibuya",
    ["GojoBoss"] = "Shibuya",
    ["SaberBoss"] = "Boss",
    ["YujiBoss"] = "Shibuya",
    ["AtomicBoss"] = "Lawless",
    ["TrueAizenBoss"] = "SoulDominion",
    ["SaberAlterBoss"] = "Boss",
    ["BlessedMaidenBoss"] = "Boss",
    ["YamatoBoss"] = "Judgement",
    ["StrongestShinobiBoss"] = "Ninja",
}

for _, bossBaseName in ipairs(bossList) do
    if BossPortals[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossPortals[bossBaseName .. diff] = BossPortals[bossBaseName]
        end
    end
end

-- Variáveis de controle
local currentTween = nil
local lastTweenTarget = nil
local lastPortaledBoss = nil
local waitingForSpawn = false
local spawnWaitStart = 0
local lastSearchTime = 0 -- NOVO: Para evitar spam de busca
local MAX_SPAWN_WAIT = 15
local SEARCH_COOLDOWN = 2 -- NOVO: Esperar 2s entre buscas quando não acha boss

local farmConnection = nil
local isRunning = false
local currentBoss = nil
local lastTarget = nil
local wasAttackingBoss = false
local killCount = 0
local character = nil
local humanoidRootPart = nil
local humanoid = nil -- NOVO: Track humanoid para verificar se está vivo
local npcsFolder = nil

local function initialize()
    character = Player.Character
    if character then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    end
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

local function isPlayerAlive()
    if not character or not character.Parent then return false end
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

local function getHumanoid(model)
    if not model or not model.Parent then return nil end
    local h = model:FindFirstChildOfClass("Humanoid")
    if h and h.Health > 0 then return h end
    return nil
end

local function isAlive(model)
    return getHumanoid(model) ~= nil
end

local function getBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName then return baseName end
        -- Verifica se começa com o nome base (para sufixos de dificuldade)
        if string.sub(bossName, 1, #baseName) == baseName then 
            return baseName 
        end
    end
    return nil
end

local function isBossSelected(bossName)
    local baseName = getBossBaseName(bossName)
    if not baseName then return false end
    return _G.SlowHub.SelectedBosses and _G.SlowHub.SelectedBosses[baseName] == true
end

local function getPityCount()
    local success, result = pcall(function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        local bossUI = playerGui:FindFirstChild("BossUI")
        if not bossUI then return nil end
        local mainFrame = bossUI:FindFirstChild("MainFrame")
        if not mainFrame then return nil end
        local bossHPBar = mainFrame:FindFirstChild("BossHPBar")
        if not bossHPBar then return nil end
        local pityLabel = bossHPBar:FindFirstChild("Pity")
        if not pityLabel then return nil end
        return pityLabel.Text
    end)
    if success and result then
        local currentPity = string.match(result, "Pity: (%d+)/25")
        if currentPity then return tonumber(currentPity) end
    end
    return 0
end

local function isPityTargetTime()
    if not _G.SlowHub.PriorityPityEnabled then return false end
    if not _G.SlowHub.PityTargetBoss or _G.SlowHub.PityTargetBoss == "" then return false end
    return getPityCount() >= 24
end

local function shouldSwitchBoss(boss)
    -- CORREÇÃO: Verificações mais robustas
    if not boss then return true end
    
    -- Verifica se o boss ainda existe no workspace
    local exists = pcall(function()
        return boss.Parent ~= nil
    end)
    if not exists or not boss.Parent then return true end
    
    if not isAlive(boss) then return true end
    
    local bossBaseName = getBossBaseName(boss.Name)
    if not bossBaseName then return true end
    if not isBossSelected(bossBaseName) then return true end
    
    if _G.SlowHub.PriorityPityEnabled and _G.SlowHub.PityTargetBoss and _G.SlowHub.PityTargetBoss ~= "" then
        local pityTime = isPityTargetTime()
        local pityTarget = _G.SlowHub.PityTargetBoss
        if pityTime then
            if bossBaseName ~= pityTarget then return true end
        else
            if bossBaseName == pityTarget then return true end
        end
    end
    return false
end

local function findBossByName(bossName)
    if not npcsFolder then 
        npcsFolder = workspace:FindFirstChild("NPCs")
        if not npcsFolder then return nil end
    end
    
    -- Tenta encontrar exato primeiro
    local exactMatch = npcsFolder:FindFirstChild(bossName)
    if exactMatch and isAlive(exactMatch) then return exactMatch end
    
    -- Tenta variações de dificuldade
    for _, diff in ipairs(difficulties) do
        local variant = npcsFolder:FindFirstChild(bossName .. diff)
        if variant and isAlive(variant) then return variant end
    end
    
    return nil
end

local function findValidBoss()
    if not npcsFolder then 
        npcsFolder = workspace:FindFirstChild("NPCs")
        if not npcsFolder then return nil end
    end
    
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    
    -- Se pity está ativo e é hora do target
    if pityEnabled and pityTarget and pityTarget ~= "" and isPityTargetTime() then
        if isBossSelected(pityTarget) then 
            return findBossByName(pityTarget) 
        end
        return nil
    end
    
    -- Procura qualquer boss selecionado que esteja vivo
    if _G.SlowHub.SelectedBosses then
        for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
            if isSelected then
                -- Se pity está ativo e não é hora do target, pula o target
                if pityEnabled and pityTarget and pityTarget ~= "" and bossName == pityTarget then
                    continue
                end
                
                local found = findBossByName(bossName)
                if found then return found end
            end
        end
    end
    
    return nil
end

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        if not character then return end
        if not humanoid then 
            humanoid = character:FindFirstChildOfClass("Humanoid")
        end
        if not humanoid then return end
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then 
            humanoid:EquipTool(weapon) 
        end
    end)
    return success
end

local function cancelTween()
    if currentTween then
        pcall(function()
            currentTween:Cancel()
        end)
        currentTween = nil
    end
end

local function moveToTarget(targetCFrame)
    if not humanoidRootPart then 
        humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return false end
    end

    local currentFarmDist = _G.SlowHub.BossFarmDistance or 8
    local currentSpeed = _G.SlowHub.TweenSpeed or 250

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude

    if distance <= currentFarmDist + 2 then
        cancelTween()
        pcall(function()
            humanoidRootPart.CFrame = targetCFrame
        end)
        return true
    end

    if lastTweenTarget then
        local posDiff = (lastTweenTarget.Position - targetCFrame.Position).Magnitude
        if posDiff > 1 then
            cancelTween()
        elseif currentTween then
            -- Verifica se tween ainda está rodando
            local status = pcall(function()
                return currentTween.PlaybackState == Enum.PlaybackState.Playing
            end)
            if status then return false end
        end
    end

    lastTweenTarget = targetCFrame
    if currentSpeed <= 0 then currentSpeed = 250 end
    local timeToReach = math.max(0.1, distance / currentSpeed) -- Mínimo 0.1s
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)

    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()

    return false
end

local function performAttack()
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then 
            requestHit:FireServer() 
        end
    end)
end

local function resetState()
    currentBoss = nil
    lastTarget = nil
    killCount = 0
    lastPortaledBoss = nil
    waitingForSpawn = false
    spawnWaitStart = 0
    lastSearchTime = 0
    _G.SlowHub.IsAttackingBoss = false
    cancelTween()
end

local function stopAutoFarm()
    if not isRunning then return end
    isRunning = false
    cancelTween()
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    resetState()
end

local function farmLoop()
    if not _G.SlowHub.AutoFarmBosses or not isRunning then
        stopAutoFarm()
        return
    end
    
    -- CORREÇÃO: Verifica se jogador está vivo
    if not isPlayerAlive() then
        task.wait(1)
        return
    end
    
    -- CORREÇÃO: Se estava atacando boss mas morreu/resetou
    if wasAttackingBoss and not isRunning then
        wasAttackingBoss = false
        return
    end
    
    -- Se não tem boss atual ou precisa trocar
    if currentBoss and shouldSwitchBoss(currentBoss) then
        killCount = killCount + 1
        currentBoss = nil
        lastTarget = nil
        waitingForSpawn = false
        cancelTween()
        task.wait(0.5) -- Espera um pouco antes de procurar próximo
        return
    end
    
    -- Se não tem boss, procura um válido
    if not currentBoss then
        -- CORREÇÃO: Cooldown entre buscas para evitar lag/spam
        local now = tick()
        if now - lastSearchTime < SEARCH_COOLDOWN then
            return
        end
        lastSearchTime = now
        
        currentBoss = findValidBoss()
        
        if not currentBoss then
            -- Nenhum boss válido encontrado
            _G.SlowHub.IsAttackingBoss = false
            wasAttackingBoss = false
            -- Se ficou muito tempo sem achar, reseta tudo
            if now - spawnWaitStart > 30 then
                resetState()
            end
            return
        end
        
        -- Novo boss encontrado, reseta estado de spawn
        lastPortaledBoss = nil
        waitingForSpawn = false
        killCount = 0
        lastTarget = currentBoss
        spawnWaitStart = now -- Reset do timer de spawn
    end
    
    -- Verifica se o boss ainda é válido
    if not currentBoss or not currentBoss.Parent then
        currentBoss = nil
        return
    end
    
    local boss = currentBoss
    local bossBaseName = getBossBaseName(boss.Name)
    if not bossBaseName then
        currentBoss = nil
        return
    end
    
    _G.SlowHub.IsAttackingBoss = true
    wasAttackingBoss = true
    
    -- Se mudou de boss, reseta portal
    if boss ~= lastTarget then
        lastTarget = boss
        lastPortaledBoss = nil
        waitingForSpawn = false
        cancelTween()
    end
    
    -- Sistema de portal
    if lastPortaledBoss ~= bossBaseName then
        local portalName = BossPortals[bossBaseName]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(0.8) -- Aumentado para garantir teleporte
        end
        lastPortaledBoss = bossBaseName
        waitingForSpawn = true
        spawnWaitStart = tick()
        return
    end
    
    -- Espera spawn
    if waitingForSpawn then
        local elapsed = tick() - spawnWaitStart
        
        -- Verifica se boss já está vivo
        if isAlive(boss) then
            waitingForSpawn = false
        elseif elapsed > MAX_SPAWN_WAIT then
            -- Timeout: força re-teleporte na próxima vez
            lastPortaledBoss = nil
            waitingForSpawn = false
            task.wait(0.5)
        else
            -- Ainda esperando, cancela tween para ficar parado
            cancelTween()
        end
        return
    end
    
    -- Boss está vivo e pronto para farmar
    if not isAlive(boss) then
        -- Boss morreu durante o processo
        waitingForSpawn = true
        spawnWaitStart = tick()
        return
    end
    
    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then
        -- Boss sem root part, tenta reencontrar
        currentBoss = nil
        return
    end
    
    local currentHeight = _G.SlowHub.BossFarmHeight or 5
    local currentDist = _G.SlowHub.BossFarmDistance or 8
    
    local offset = CFrame.new(0, currentHeight, currentDist)
    local targetCFrame = bossRoot.CFrame * offset
    
    local success, hasArrived = pcall(function()
        return moveToTarget(targetCFrame)
    end)
    
    if success and hasArrived then
        equipWeapon()
        performAttack()
    elseif not success then
        -- Erro no movimento, reseta tween
        cancelTween()
    end
end

local function startAutoFarm()
    if isRunning then
        stopAutoFarm()
        task.wait(0.5)
    end
    
    initialize()
    if not npcsFolder then 
        -- Tenta encontrar novamente
        npcsFolder = workspace:FindFirstChild("NPCs")
        if not npcsFolder then 
            warn("NPCs folder not found")
            return false 
        end
    end
    
    isRunning = true
    resetState()
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

Tab:Section({Title = "Boss Selection"})

Tab:Dropdown({
    Title = "Select Bosses to Farm",
    Flag = "SelectedBosses",
    Values = bossList,
    Multi = true,
    Value = (function()
        local selected = {}
        if _G.SlowHub.SelectedBosses then
            for name, isSelected in pairs(_G.SlowHub.SelectedBosses) do
                if isSelected then
                    table.insert(selected, name)
                end
            end
        end
        return selected
    end)(),
    Callback = function(options)
        local map = {}
        if type(options) == "table" then
            for _, v in ipairs(options) do
                map[v] = true
            end
        end
        _G.SlowHub.SelectedBosses = map
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        -- Se estava rodando, reseta para aplicar nova seleção
        if isRunning then
            resetState()
        end
    end,
})

Tab:Section({Title = "Pity System (Optional)"})

Tab:Dropdown({
    Title = "Pity Target Boss",
    Flag = "PityTargetBoss",
    Values = bossList,
    Multi = false,
    Value = _G.SlowHub.PityTargetBoss or bossList[1],
    Callback = function(option)
        _G.SlowHub.PityTargetBoss = type(option) == "table" and option[1] or option
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if isRunning then
            resetState()
        end
    end,
})

Tab:Toggle({
    Title = "Enable Pity System",
    Value = _G.SlowHub.PriorityPityEnabled or false,
    Callback = function(Value)
        _G.SlowHub.PriorityPityEnabled = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if isRunning then
            resetState()
        end
    end,
})

Tab:Section({Title = "Farm Control"})

Tab:Toggle({
    Title = "Auto Farm Selected Bosses",
    Value = _G.SlowHub.AutoFarmBosses or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({
                        Title = "Error",
                        Content = "Select a weapon first!",
                        Duration = 3,
                    })
                end
                return
            end
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end,
})

Tab:Slider({
    Title = "Tween Speed",
    Flag = "BossTweenSpeed",
    Step = 10,
    Value = {
        Min = 150,
        Max = 500,
        Default = _G.SlowHub.TweenSpeed or 250,
    },
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Boss Farm Distance",
    Flag = "BossFarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmDistance or 8,
    },
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Boss Farm Height",
    Flag = "BossFarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmHeight or 5,
    },
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

-- Auto-start
if _G.SlowHub.AutoFarmBosses then
    task.wait(2)
    startAutoFarm()
end
