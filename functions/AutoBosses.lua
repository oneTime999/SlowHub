local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AnosBoss", "GilgameshBoss", "RimuruBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss",
    "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss",
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["AnosBoss"] = CFrame.new(950.0978393554688, -0.23529791831970215, 1378.4510498046875),
    ["GilgameshBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["RimuruBoss"] = CFrame.new(-1363.4713134765625, 30.04159164428711, 221.3505859375),
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30),
    ["IchigoBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["AizenBoss"] = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"] = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"] = CFrame.new(1537.92, 12.98, 226.10),
}

for _, bossBaseName in ipairs(bossList) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

local farmConnection = nil
local isRunning = false
local isFarmLoopRunning = false
local currentBoss = nil
local lastTarget = nil
local hasVisitedSafeZone = false
local lastHitTime = 0
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
        if _G.SlowHub.AutoFarmBosses and not isRunning then
            startAutoFarm()
        end
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "NPCs" then
        npcsFolder = nil
        resetState()
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

local function getSafeZone(bossName)
    local direct = BossSafeZones[bossName]
    if direct then return direct end
    local baseName = getBossBaseName(bossName)
    if baseName then return BossSafeZones[baseName] end
    return nil
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

local function teleportToSafeZone(boss)
    if not humanoidRootPart then return false end
    local safeCFrame = getSafeZone(boss.Name)
    if not safeCFrame then return true end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.CFrame = safeCFrame
    return true
end

local function teleportToBoss(boss)
    if not humanoidRootPart then return false end
    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return false end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.BossFarmHeight or 5, _G.SlowHub.BossFarmDistance or 8)
    humanoidRootPart.CFrame = bossRoot.CFrame * offset
    return true
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

local function resetState()
    currentBoss = nil
    lastTarget = nil
    hasVisitedSafeZone = false
    isFarmLoopRunning = false
    _G.SlowHub.IsAttackingBoss = false
end

local function stopAutoFarm()
    if not isRunning then return end
    isRunning = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    resetState()
end

local function farmLoop()
    if isFarmLoopRunning then return end
    isFarmLoopRunning = true

    if not _G.SlowHub.AutoFarmBosses or not isRunning then
        isFarmLoopRunning = false
        stopAutoFarm()
        return
    end
    if not character or not character.Parent then
        isFarmLoopRunning = false
        return
    end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then
            isFarmLoopRunning = false
            return
        end
    end
    if currentBoss and shouldSwitchBoss(currentBoss) then
        resetState()
        return
    end
    if not currentBoss then
        currentBoss = findValidBoss()
        if not currentBoss then
            _G.SlowHub.IsAttackingBoss = false
            isFarmLoopRunning = false
            return
        end
        hasVisitedSafeZone = false
        lastTarget = currentBoss
        equipWeapon()
    end
    local boss = currentBoss
    _G.SlowHub.IsAttackingBoss = true
    if boss ~= lastTarget then
        lastTarget = boss
        hasVisitedSafeZone = false
        equipWeapon()
    end
    if not hasVisitedSafeZone then
        local success = teleportToSafeZone(boss)
        if success then hasVisitedSafeZone = true end
        isFarmLoopRunning = false
        return
    end
    local success = teleportToBoss(boss)
    if success then
        performAttack()
    end
    isFarmLoopRunning = false
end

local function startAutoFarm()
    if isRunning then
        stopAutoFarm()
        task.wait(0.2)
    end
    initialize()
    if not npcsFolder then return false end
    isRunning = true
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
            startAutoFarm()
        else
            stopAutoFarm()
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
