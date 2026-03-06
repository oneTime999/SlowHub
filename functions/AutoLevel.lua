local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 5999, quest = "QuestNPC11", npc = "Hollow", count = 5},
    {minLevel = 6000, maxLevel = 6999, quest = "QuestNPC12", npc = "StrongSorcerer", count = 5},
    {minLevel = 7000, maxLevel = 7999, quest = "QuestNPC13", npc = "Curse", count = 5},
    {minLevel = 8000, maxLevel = 8999, quest = "QuestNPC14", npc = "Slime", count = 5},
    {minLevel = 9000, maxLevel = 99999, quest = "QuestNPC15", npc = "AcademyTeacher", count = 5},
}

local NPCSafeZones = {
    ["Thief"] = CFrame.new(177.723145, 11.2069092, -157.246826),
    ["Monkey"] = CFrame.new(-567.758667, -0.8746683, 399.302979),
    ["DesertBandit"] = CFrame.new(-867.638245, -4.22272682, -446.67868),
    ["FrostRogue"] = CFrame.new(-398.725769, -1.13884699, -1071.56885),
    ["Sorcerer"] = CFrame.new(1398.2594, 8.48633194, 488.058838),
    ["Hollow"] = CFrame.new(-365.12628173828125, -0.44140613079071045, 1097.683349609375),
    ["StrongSorcerer"] = CFrame.new(637.979126, 2.375789, -1669.440186),
    ["Curse"] = CFrame.new(-69.846375, 1.907236, -1857.250244),
    ["Slime"] = CFrame.new(-1124.753173828125, 19.703411102294922, 371.2305908203125),
    ["AcademyTeacher"] = CFrame.new(1072.5455322265625, 1.7783551216125488, 1275.641845703125),
}

local farmConnection = nil
local questLoop = nil
local isFarming = false
local isQuesting = false
local currentNPCIndex = 1
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false
local lastAttackTime = 0
local lastNPCSwitch = 0
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
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then npcsFolder = child end
end)

local function getPlayerLevel()
    local ok, result = pcall(function()
        local data = Player:FindFirstChild("Data")
        if not data then return 1 end
        local levelValue = data:FindFirstChild("Level")
        if not levelValue then return 1 end
        return levelValue.Value
    end)
    return ok and result or 1
end

local function getCurrentConfig()
    local level = getPlayerLevel()
    for _, config in ipairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then return config end
    end
    return LevelConfig[1]
end

local function getNextIndex(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
end

local function getNPC(npcName, index)
    if not npcsFolder then return nil end
    return npcsFolder:FindFirstChild(npcName .. index)
end

local function isNPCAlive(npc)
    if not npc or not npc.Parent then return false end
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    return pcall(function()
        if not character or not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then humanoid:EquipTool(weapon) end
    end)
end

local function teleportToSafeZone(npcName)
    if not humanoidRootPart then return false end
    local safeCFrame = NPCSafeZones[npcName]
    if not safeCFrame then hasVisitedSafeZone = true; return true end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.CFrame = safeCFrame
    return true
end

local function teleportToNPC(npc)
    if not humanoidRootPart then return false end
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return false end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.FarmHeight or 4, _G.SlowHub.FarmDistance or 8)
    local targetCFrame = npcRoot.CFrame * offset
    if (humanoidRootPart.Position - targetCFrame.Position).Magnitude > 2 then
        humanoidRootPart.CFrame = targetCFrame
    end
    return true
end

local function performAttack()
    local currentTime = tick()
    if currentTime - lastAttackTime < (_G.SlowHub.FarmCooldown or 0.15) then return end
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
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local config = getCurrentConfig()
        if not config then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(config.quest) end
    end)
end

local function resetFarmState()
    currentNPCIndex = 1
    lastTargetName = nil
    hasVisitedSafeZone = false
    wasAttackingBoss = false
    lastAttackTime = 0
    lastNPCSwitch = 0
end

local function stopQuestLoop()
    isQuesting = false
end

local function startQuestLoop()
    if isQuesting then return end
    isQuesting = true
    questLoop = task.spawn(function()
        while isQuesting and _G.SlowHub.AutoFarmLevel do
            acceptQuest()
            task.wait(_G.SlowHub.QuestInterval or 2)
        end
    end)
end

local function stopAutoLevel()
    if not isFarming then return end
    isFarming = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    stopQuestLoop()
    resetFarmState()
    pcall(function()
        if humanoidRootPart then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function farmLoop()
    if not _G.SlowHub.AutoFarmLevel then stopAutoLevel(); return end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
    end
    if _G.SlowHub.IsAttackingBoss then wasAttackingBoss = true; return end
    if wasAttackingBoss then
        hasVisitedSafeZone = false
        wasAttackingBoss = false
    end
    local now = tick()
    local config = getCurrentConfig()
    if not config then return end
    if lastTargetName ~= config.npc then
        lastTargetName = config.npc
        hasVisitedSafeZone = false
    end
    if not hasVisitedSafeZone then
        if teleportToSafeZone(config.npc) then hasVisitedSafeZone = true end
        task.wait(0.1)
        return
    end
    local npc = getNPC(config.npc, currentNPCIndex)
    local alive = isNPCAlive(npc)
    if not alive then
        if (now - lastNPCSwitch) > 0 then
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
            lastNPCSwitch = now
        end
    else
        lastNPCSwitch = now
        local success = teleportToNPC(npc)
        if success then
            equipWeapon()
            performAttack()
        else
            currentNPCIndex = getNextIndex(currentNPCIndex, config.count)
        end
    end
end

local function startAutoLevel()
    if isFarming then stopAutoLevel(); task.wait(0.2) end
    initialize()
    if not npcsFolder then return false end
    isFarming = true
    resetFarmState()
    startQuestLoop()
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

Tab:Section({Title = "Auto Level"})

Tab:Toggle({
    Title = "Auto Farm Level",
    Default = _G.SlowHub.AutoFarmLevel or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoLevel()
        else
            stopAutoLevel()
        end
    end,
})

Tab:Section({Title = "Farm Settings"})

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
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
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
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
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
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Quest Interval",
    Flag = "QuestInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 5,
        Default = _G.SlowHub.QuestInterval or 2,
    },
    Callback = function(Value)
        _G.SlowHub.QuestInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    startAutoLevel()
end
