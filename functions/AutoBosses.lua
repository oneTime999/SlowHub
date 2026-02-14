local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "RimuruBoss", "MadokaBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss", "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["RimuruBoss"] = CFrame.new(-1363.4713134765625, 30.04159164428711, 221.3505859375),
    ["MadokaBoss"] = CFrame.new(-1264.6318359375, -0.17221689224243164, -1116.2039794921875),
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30),
    ["IchigoBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["AizenBoss"]  = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"]  = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"]   = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"]   = CFrame.new(1537.92, 12.98, 226.10)
}

for _, bossBaseName in ipairs({"StrongestofTodayBoss", "StrongestinHistoryBoss"}) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
_G.SlowHub.PityTargetBoss = _G.SlowHub.PityTargetBoss or ""
_G.SlowHub.PriorityPityEnabled = _G.SlowHub.PriorityPityEnabled or false
_G.SlowHub.BossFarmDistance = _G.SlowHub.BossFarmDistance or 8
_G.SlowHub.BossFarmHeight = _G.SlowHub.BossFarmHeight or 5

local autoFarmBossConnection = nil
local isRunning = false
local currentFarmingBoss = nil
local hasVisitedSafeZone = false

local function getPityCount()
    local success, pityText = pcall(function()
        local pityLabel = Player:WaitForChild("PlayerGui"):WaitForChild("BossUI"):WaitForChild("MainFrame"):WaitForChild("BossHPBar"):WaitForChild("Pity")
        return pityLabel.Text
    end)
    if success and pityText then
        local currentPity = pityText:match("Pity: (%d+)/25")
        return tonumber(currentPity) or 0
    end
    return 0
end

local function checkHumanoid(model)
    return model and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0
end

local function getBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName or string.find(bossName, baseName) == 1 then
            return baseName
        end
    end
    return bossName
end

local function isBossSelected(bossName)
    local baseName = getBossBaseName(bossName)
    return _G.SlowHub.SelectedBosses[baseName] == true
end

local function findValidBoss()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return nil end
    
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    local currentPity = getPityCount()
    
    if pityEnabled and pityTarget ~= "" and currentPity >= 24 then
        if isBossSelected(pityTarget) then
            local exactBoss = npcs:FindFirstChild(pityTarget)
            if exactBoss and checkHumanoid(exactBoss) then return exactBoss end
            for _, diff in ipairs(difficulties) do
                local variant = npcs:FindFirstChild(pityTarget .. diff)
                if variant and checkHumanoid(variant) then return variant end
            end
        end
        return nil
    end
    
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            if pityEnabled and bossName == pityTarget and currentPity < 24 then
                continue
            end
            local exactBoss = npcs:FindFirstChild(bossName)
            if exactBoss and checkHumanoid(exactBoss) then return exactBoss end
            for _, diff in ipairs(difficulties) do
                local variant = npcs:FindFirstChild(bossName .. diff)
                if variant and checkHumanoid(variant) then return variant end
            end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        local character = Player.Character
        if character and not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            local tool = Player.Backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if tool then character.Humanoid:EquipTool(tool) end
        end
    end)
end

local function stopAutoFarmBoss()
    isRunning = false
    currentFarmingBoss = nil
    _G.SlowHub.IsAttackingBoss = false
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
end

local function startAutoFarmBoss()
    if isRunning then stopAutoFarmBoss() task.wait(0.1) end
    isRunning = true
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses then stopAutoFarmBoss() return end
        
        if not currentFarmingBoss or not currentFarmingBoss.Parent or not checkHumanoid(currentFarmingBoss) then
            currentFarmingBoss = findValidBoss()
            hasVisitedSafeZone = false
            if not currentFarmingBoss then 
                _G.SlowHub.IsAttackingBoss = false
                return 
            end
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local bossRoot = currentFarmingBoss:FindFirstChild("HumanoidRootPart")
        if not playerRoot or not bossRoot then return end

        _G.SlowHub.IsAttackingBoss = true

        if not hasVisitedSafeZone then
            local baseName = getBossBaseName(currentFarmingBoss.Name)
            local safeCFrame = BossSafeZones[currentFarmingBoss.Name] or BossSafeZones[baseName]
            if safeCFrame then
                playerRoot.CFrame = safeCFrame
                task.wait(0.1)
            end
            hasVisitedSafeZone = true
        end

        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        playerRoot.CFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
        
        EquipWeapon()
        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
    end)
end

Tab:CreateSection("Boss Selection")

Tab:CreateDropdown({
    Name = "Select Bosses",
    Options = bossList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectedBossesDropdown",
    Callback = function(Options)
        table.clear(_G.SlowHub.SelectedBosses)
        for _, v in ipairs(Options) do
            _G.SlowHub.SelectedBosses[v] = true
        end
    end
})

Tab:CreateSection("Pity System")

Tab:CreateDropdown({
    Name = "Pity Target Boss",
    Options = bossList,
    CurrentOption = "",
    Flag = "PityTarget",
    Callback = function(Option)
        _G.SlowHub.PityTargetBoss = type(Option) == "table" and Option[1] or Option
    end
})

Tab:CreateToggle({
    Name = "Enable Pity System",
    CurrentValue = _G.SlowHub.PriorityPityEnabled,
    Flag = "PityToggle",
    Callback = function(Value)
        _G.SlowHub.PriorityPityEnabled = Value
    end
})

Tab:CreateSection("Farm Control")

Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        _G.SlowHub.AutoFarmBosses = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.SlowHub.AutoFarmBosses = false
                return
            end
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
    end
})

Tab:CreateSlider({
    Name = "Distance",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Callback = function(Value) _G.SlowHub.BossFarmDistance = Value end
})

Tab:CreateSlider({
    Name = "Height",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Callback = function(Value) _G.SlowHub.BossFarmHeight = Value end
})
