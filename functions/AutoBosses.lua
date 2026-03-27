local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- NOVO
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AnosBoss", "GilgameshBoss", "RimuruBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss",
    "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss",
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

-- NOVO: Portais para cada boss (ajuste os nomes conforme seu jogo)
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
}

-- Propagar portais para todas as dificuldades
for _, bossBaseName in ipairs(bossList) do
    if BossPortals[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossPortals[bossBaseName .. diff] = BossPortals[bossBaseName]
        end
    end
end

-- NOVO: Variáveis de controle de estado (igual ao primeiro código)
local currentTween = nil
local lastTweenTarget = nil
local lastPortaledBoss = nil
local waitingForSpawn = false
local spawnWaitStart = 0
local MAX_SPAWN_WAIT = 15 -- Bosses demoram mais para spawnar

local farmConnection = nil
local isRunning = false
local currentBoss = nil
local lastTarget = nil
local wasAttackingBoss = false
local lastHitTime = 0
local killCount = 0 -- NOVO: Contador de kills (útil para bosses que respawnam rápido)
local character = nil
local humanoidRootPart = nil
local npcsFolder = nil

local function initialize()
    character = Player.Character
    humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    npcsFolder = workspace:FindFirstChild("NPCs")
end

initialize()

Player.CharacterAdded:Connect(function(char)
    character = char
    humanoidRootPart = nil
    task.wait(0.1)
    humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
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
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
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

    local currentFarmDist = _G.SlowHub.BossFarmDistance or 8
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
    if currentTime - lastHitTime < (_G.SlowHub.BossFarmCooldown or 0.15) then return end
    lastHitTime = currentTime
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then requestHit:FireServer() end
    end)
end

-- NOVO: Reset completo do estado (igual ao primeiro código)
local function resetState()
    currentBoss = nil
    lastTarget = nil
    killCount = 0
    lastPortaledBoss = nil
    waitingForSpawn = false
    spawnWaitStart = 0
    _G.SlowHub.IsAttackingBoss = false
    cancelTween()
end

local function stopAutoFarm()
    if not isRunning then return end
    isRunning = false
    cancelTween() -- NOVO
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    resetState()
end

-- NOVO: Função principal de farm adaptada do primeiro código
local function farmLoop()
    if not _G.SlowHub.AutoFarmBosses or not isRunning then
        stopAutoFarm()
        return
    end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    
    -- Verifica se precisa trocar de boss (morreu, não está selecionado, ou mudou prioridade de pity)
    if currentBoss and shouldSwitchBoss(currentBoss) then
        killCount = killCount + 1 -- NOVO: Conta kill quando boss morre
        currentBoss = nil
        lastTarget = nil
        waitingForSpawn = false
        cancelTween()
        task.wait(0.1)
        return
    end
    
    -- Procura novo boss válido
    if not currentBoss then
        currentBoss = findValidBoss()
        if not currentBoss then
            _G.SlowHub.IsAttackingBoss = false
            return
        end
        -- NOVO: Reset de estado quando muda de boss
        lastPortaledBoss = nil
        waitingForSpawn = false
        killCount = 0
        lastTarget = currentBoss
    end
    
    local boss = currentBoss
    local bossBaseName = getBossBaseName(boss.Name)
    _G.SlowHub.IsAttackingBoss = true
    
    -- NOVO: Sincronização - Se mudou de boss, força novo teleporte
    if boss ~= lastTarget then
        lastTarget = boss
        lastPortaledBoss = nil
        waitingForSpawn = false
        cancelTween()
    end
    
    -- CORREÇÃO: Só pode farmar se já usou o portal deste boss específico
    if lastPortaledBoss ~= bossBaseName then
        local portalName = BossPortals[bossBaseName]
        if portalName then
            pcall(function()
                local args = { [1] = portalName }
                ReplicatedStorage.Remotes.TeleportToPortal:FireServer(unpack(args))
            end)
            task.wait(0.5) -- Garante o teleporte
        end
        lastPortaledBoss = bossBaseName -- Marca que tentou usar portal deste boss
        waitingForSpawn = true
        spawnWaitStart = tick()
        return -- Sai e espera spawn na próxima iteração
    end
    
    -- Se está esperando spawn, verifica se boss apareceu
    if waitingForSpawn then
        local elapsed = tick() - spawnWaitStart
        
        -- Verifica se boss está vivo (spawnou)
        if isAlive(boss) then
            -- Boss spawnou! Pode começar a farmar
            waitingForSpawn = false
        elseif elapsed > MAX_SPAWN_WAIT then
            -- Timeout: força re-teleporte
            lastPortaledBoss = nil -- Isso vai forçar teleporte novamente na próxima iteração
            waitingForSpawn = false
            task.wait(0.5)
        else
            -- Ainda esperando, fica parado
            cancelTween()
        end
        return -- Sai da função até confirmar spawn ou timeout
    end
    
    -- Só chega aqui se: já usou o portal deste boss E o boss já spawnou
    local currentHeight = _G.SlowHub.BossFarmHeight or 5
    local currentDist = _G.SlowHub.BossFarmDistance or 8
    
    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then
        -- Boss sem HumanoidRootPart, tenta reencontrar
        currentBoss = nil
        return
    end
    
    local offset = CFrame.new(0, currentHeight, currentDist)
    local targetCFrame = bossRoot.CFrame * offset
    
    local hasArrived = moveToTarget(targetCFrame)
    
    if hasArrived then
        equipWeapon()
        performAttack()
    end
end

local function startAutoFarm()
    if isRunning then
        stopAutoFarm()
        task.wait(0.2)
    end
    initialize()
    if not npcsFolder then return false end
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
        if _G.SlowHub.AutoFarmBosses and isRunning then
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
        if _G.SlowHub.AutoFarmBosses and isRunning then
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

-- NOVO: Slider de Tween Speed (igual ao primeiro código)
Tab:Slider({
    Title = "Tween Speed",
    Flag = "BossTweenSpeed",
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
        cancelTween()
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
        cancelTween()
    end,
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "BossFarmCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.BossFarmCooldown or 0.15,
    },
    Callback = function(Value)
        _G.SlowHub.BossFarmCooldown = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

if _G.SlowHub.AutoFarmBosses then
    task.wait(2)
    startAutoFarm()
end
