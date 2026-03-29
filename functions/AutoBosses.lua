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
    ["AizenBossBoss",
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

-- NOVO: Sistema anti-travamento
local AntiStuckSystem = {
    lastPosition = nil,
    stuckTimer = 0,
    lastMoveTime = 0,
    STUCK_THRESHOLD = 3, -- segundos sem mover = travado
    MIN_MOVE_DISTANCE = 0.5 -- distância mínima para considerar que moveu
}

local currentTween = nil
local lastTweenTarget = nil
local lastPortaledBoss = nil
local waitingForSpawn = false
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 15

local farmConnection = nil
local noclipConnection = nil  -- NOVO
local isRunning = false
local currentBoss = nil
local lastTarget = nil
local killCount = 0
local character = nil
local humanoid = nil  -- NOVO
local humanoidRootPart = nil
local npcsFolder = nil

local function initialize()
    character = Player.Character
    humanoid = character and character:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    npcsFolder = workspace:FindFirstChild("NPCs")
    AntiStuckSystem.lastPosition = humanoidRootPart and humanoidRootPart.Position
    AntiStuckSystem.lastMoveTime = tick()
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = nil
    humanoidRootPart = nil
    task.wait(0.1)
    humanoid = char:FindFirstChildOfClass("Humanoid")
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    AntiStuckSystem.lastPosition = humanoidRootPart and humanoidRootPart.Position
    AntiStuckSystem.lastMoveTime = tick()
    AntiStuckSystem.stuckTimer = 0
    
    -- NOVO: Reequipar e reiniciar se estiver farmando
    if isRunning and _G.SlowHub.SelectedWeapon then
        task.wait(1)
        if humanoid and humanoid.Health > 0 then
            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if tool then
                    pcall(function() humanoid:EquipTool(tool) end)
                end
            end
        end
    end
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        npcsFolder = child
    end
end)

local function getHumanoid(model)
    if not model or not model.Parent then return nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then return humanoid end
    return nil
end

local function isAlive(model)
    return getHumanoid(model) ~= nil
end

local function getBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName then return baseName end
        if string.sub(bossName, 1, #baseName) == baseName then return baseName end
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
    if not boss or not boss.Parent then return true end
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
    if not npcsFolder then return nil end
    local exactMatch = npcsFolder:FindFirstChild(bossName)
    if exactMatch and isAlive(exactMatch) then return exactMatch end
    for _, diff in ipairs(difficulties) do
        local variant = npcsFolder:FindFirstChild(bossName .. diff)
        if variant and isAlive(variant) then return variant end
    end
    return nil
end

local function findValidBoss()
    if not npcsFolder then return nil end
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    if pityEnabled and pityTarget and pityTarget ~= "" then
        if isPityTargetTime() then
            if isBossSelected(pityTarget) then return findBossByName(pityTarget) end
            return nil
        else
            for _, bossName in ipairs(bossList) do
                if bossName ~= pityTarget and isBossSelected(bossName) then
                    local found = findBossByName(bossName)
                    if found then return found end
                end
            end
            return nil
        end
    end
    if _G.SlowHub.SelectedBosses then
        for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
            if isSelected then
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
        if not character or not humanoid then return false end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return true end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return false end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then 
            humanoid:EquipTool(weapon)
            -- Aguarda equipar
            local start = tick()
            while tick() - start < 0.5 do
                if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return true end
                task.wait(0.05)
            end
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
    lastTweenTarget = nil
end

-- NOVO: Sistema anti-travamento
local function checkIfStuck()
    if not humanoidRootPart then return false end
    
    local currentPos = humanoidRootPart.Position
    local currentTime = tick()
    
    if not AntiStuckSystem.lastPosition then
        AntiStuckSystem.lastPosition = currentPos
        AntiStuckSystem.lastMoveTime = currentTime
        return false
    end
    
    local distanceMoved = (currentPos - AntiStuckSystem.lastPosition).Magnitude
    local timeSinceLastMove = currentTime - AntiStuckSystem.lastMoveTime
    
    if distanceMoved > AntiStuckSystem.MIN_MOVE_DISTANCE then
        -- Moveu, resetar timer
        AntiStuckSystem.lastPosition = currentPos
        AntiStuckSystem.lastMoveTime = currentTime
        AntiStuckSystem.stuckTimer = 0
        return false
    else
        -- Não moveu o suficiente
        if timeSinceLastMove > AntiStuckSystem.STUCK_THRESHOLD then
            return true -- Está travado
        end
    end
    
    return false
end

local function moveToTarget(targetCFrame)
    if not humanoidRootPart then return false end

    local currentFarmDist = _G.SlowHub.BossFarmDistance or 8
    local currentSpeed = _G.SlowHub.TweenSpeed or 250

    local distance = (humanoidRootPart.Position - targetCFrame.Position).Magnitude

    -- Já chegou?
    if distance <= currentFarmDist + 2 then
        cancelTween()
        humanoidRootPart.CFrame = targetCFrame
        return true
    end

    -- Verifica se target mudou muito
    if lastTweenTarget then
        local posDiff = (lastTweenTarget.Position - targetCFrame.Position).Magnitude
        if posDiff > 2 then
            cancelTween()
        end
    end

    -- Se já está indo, não cria outro
    if currentTween and currentTween.PlaybackState == Enum.PlaybackState.Playing then
        return false
    end

    lastTweenTarget = targetCFrame
    
    -- Velocidade mínima para evitar tween muito lento
    if currentSpeed < 50 then currentSpeed = 50 end
    
    local timeToReach = distance / currentSpeed
    if timeToReach > 10 then timeToReach = 10 end -- Máximo 10s de tween
    
    local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear)
    
    cancelTween()
    currentTween = TweenService:Create(humanoidRootPart, tweenInfo, {CFrame = targetCFrame})
    currentTween:Play()
    
    -- Timeout de segurança para o tween
    task.delay(timeToReach + 1, function()
        if currentTween and tick() - AntiStuckSystem.lastMoveTime > timeToReach + 1 then
            cancelTween()
        end
    end)

    return false
end

local function performAttack()
    pcall(function()
        -- Só ataca se tiver arma equipada
        if not character or not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if combatSystem then
            local remotes = combatSystem:FindFirstChild("Remotes")
            if remotes then
                local requestHit = remotes:FindFirstChild("RequestHit")
                if requestHit then requestHit:FireServer() end
            end
        end
        
        -- Ativa a tool específica
        local tool = character:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if tool and tool:IsA("Tool") then
            tool:Activate()
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
    _G.SlowHub.IsAttackingBoss = false
    cancelTween()
    AntiStuckSystem.lastPosition = humanoidRootPart and humanoidRootPart.Position
    AntiStuckSystem.lastMoveTime = tick()
    AntiStuckSystem.stuckTimer = 0
end

local function stopAutoFarm()
    if not isRunning then return end
    isRunning = false
    cancelTween()
    
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    
    -- NOVO: Desligar noclip
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    
    -- NOVO: Limpar BodyVelocity se existir
    pcall(function()
        if humanoidRootPart then
            local bv = humanoidRootPart:FindFirstChild("SlowHubVelocity")
            if bv then bv:Destroy() end
            humanoidRootPart.Anchored = false
        end
    end)
    
    resetState()
    _G.SlowHub.IsAttackingBoss = false
end

local function farmLoop()
    if not _G.SlowHub.AutoFarmBosses or not isRunning then
        stopAutoFarm()
        return
    end
    
    -- Proteção contra erros
    local success, err = pcall(function()
        if not character or not character.Parent then 
            character = Player.Character
            return 
        end
        
        if not humanoidRootPart or not humanoid then
            humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoidRootPart or not humanoid or humanoid.Health <= 0 then 
                return 
            end
        end
        
        -- NOVO: Verificar se está travado
        if checkIfStuck() then
            AntiStuckSystem.stuckTimer = AntiStuckSystem.stuckTimer + 1
            
            if AntiStuckSystem.stuckTimer >= 2 then
                -- Forçar reset completo se travar 2 vezes seguidas
                cancelTween()
                lastPortaledBoss = nil
                waitingForSpawn = false
                currentBoss = nil
                AntiStuckSystem.stuckTimer = 0
                
                -- Tentar "desancorar" e resetar física
                if humanoidRootPart then
                    humanoidRootPart.Anchored = false
                    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                    humanoidRootPart.AssemblyAngularVelocity = Vector3.zero
                end
                
                task.wait(0.5)
                return
            else
                -- Primeira detecção de travamento, só cancela tween
                cancelTween()
                task.wait(0.3)
            end
        end
        
        if currentBoss and shouldSwitchBoss(currentBoss) then
            killCount = killCount + 1
            currentBoss = nil
            lastTarget = nil
            waitingForSpawn = false
            cancelTween()
            task.wait(0.2)
            return
        end
        
        if not currentBoss then
            currentBoss = findValidBoss()
            if not currentBoss then
                _G.SlowHub.IsAttackingBoss = false
                return
            end
            lastPortaledBoss = nil
            waitingForSpawn = false
            killCount = 0
            lastTarget = currentBoss
        end
        
        local boss = currentBoss
        local bossBaseName = getBossBaseName(boss.Name)
        _G.SlowHub.IsAttackingBoss = true
        
        if boss ~= lastTarget then
            lastTarget = boss
            lastPortaledBoss = nil
            waitingForSpawn = false
            cancelTween()
        end
        
        -- Portal logic com cooldown
        if lastPortaledBoss ~= bossBaseName then
            local portalName = BossPortals[bossBaseName]
            if portalName then
                pcall(function()
                    ReplicatedStorage.Remotes.TeleportToPortal:FireServer(portalName)
                end)
                task.wait(0.8) -- Aumentado para garantir teleporte
            end
            lastPortaledBoss = bossBaseName
            waitingForSpawn = true
            spawnWaitStart = tick()
            cancelTween()
            return
        end
        
        if waitingForSpawn then
            local elapsed = tick() - spawnWaitStart
            
            if isAlive(boss) then
                waitingForSpawn = false
            elseif elapsed > MAX_SPAWN_WAIT then
                lastPortaledBoss = nil
                waitingForSpawn = false
                task.wait(0.5)
            else
                cancelTween()
            end
            return
        end
        
        -- Farm logic
        local currentHeight = _G.SlowHub.BossFarmHeight or 5
        local currentDist = _G.SlowHub.BossFarmDistance or 8
        
        local bossRoot = boss:FindFirstChild("HumanoidRootPart") or boss:FindFirstChild("Torso") or boss:FindFirstChild("UpperTorso")
        if not bossRoot then
            currentBoss = nil
            return
        end
        
        -- Verifica se boss mudou de posição drasticamente (teleportou?)
        if lastTweenTarget then
            local distToLast = (bossRoot.Position - lastTweenTarget.Position).Magnitude
            if distToLast > 50 then
                cancelTween() -- Boss se moveu muito, recalcula
            end
        end
        
        local offset = CFrame.new(0, currentHeight, currentDist)
        local targetCFrame = bossRoot.CFrame * offset
        
        local hasArrived = moveToTarget(targetCFrame)
        
        if hasArrived then
            equipWeapon()
            performAttack()
        end
    end)
    
    if not success then
        warn("FarmLoop Error:", err)
        task.wait(1) -- Espera antes de tentar novamente se deu erro
    end
end

local function startAutoFarm()
    if isRunning then
        stopAutoFarm()
        task.wait(0.5)
    end
    
    initialize()
    if not npcsFolder then return false end
    
    isRunning = true
    resetState()
    
    -- NOVO: Noclip connection
    noclipConnection = RunService.Stepped:Connect(function()
        if not isRunning or not character then return end
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
    
    -- NOVO: BodyVelocity para evitar queda/flutuação estranha
    if humanoidRootPart then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "SlowHubVelocity"
        bv.Velocity = Vector3.zero
        bv.MaxForce = Vector3.new(0, math.huge, 0) -- Só no eixo Y para não cair
        bv.Parent = humanoidRootPart
    end
    
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

-- UI Elements (mantidos iguais)
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
        if _G.SaveConfig then _G.SaveConfig() end
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
        if _G.SaveConfig then _G.SaveConfig() end
        if _G.SlowHub.AutoFarmBosses and isRunning then resetState() end
    end,
})

Tab:Toggle({
    Title = "Enable Pity System",
    Value = _G.SlowHub.PriorityPityEnabled or false,
    Callback = function(Value)
        _G.SlowHub.PriorityPityEnabled = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if _G.SlowHub.AutoFarmBosses and isRunning then resetState() end
    end,
})

Tab:Section({Title = "Farm Control"})

Tab:Toggle({
    Title = "Auto Farm Selected Bosses",
    Value = _G.SlowHub.AutoFarmBosses or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmBosses = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                if _G.WindUI and _G.WindUI.Notify then
                    _G.WindUI:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
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
    Value = {Min = 150, Max = 500, Default = _G.SlowHub.TweenSpeed or 250},
    Callback = function(Value)
        _G.SlowHub.TweenSpeed = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Boss Farm Distance",
    Flag = "BossFarmDistance",
    Step = 1,
    Value = {Min = 1, Max = 10, Default = _G.SlowHub.BossFarmDistance or 8},
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Boss Farm Height",
    Flag = "BossFarmHeight",
    Step = 1,
    Value = {Min = 1, Max = 10, Default = _G.SlowHub.BossFarmHeight or 5},
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
        cancelTween()
    end,
})

if _G.SlowHub.AutoFarmBosses then
    task.wait(2)
    startAutoFarm()
end
