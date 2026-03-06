local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local miniBossConfig = {
    ["ThiefBoss"]={quest="QuestNPC2"},["MonkeyBoss"]={quest="QuestNPC4"},
    ["DesertBoss"]={quest="QuestNPC6"},["SnowBoss"]={quest="QuestNPC8"},
    ["PandaMiniBoss"]={quest="QuestNPC10"},
}
local miniBossList = {"ThiefBoss","MonkeyBoss","DesertBoss","SnowBoss","PandaMiniBoss"}

local miniBossSafeZones = {
    ["ThiefBoss"]=CFrame.new(-66.633,-2.584,-162.471),
    ["MonkeyBoss"]=CFrame.new(-494.757,49.211,496.788),
    ["DesertBoss"]=CFrame.new(-972.217,2.346,-475.585),
    ["SnowBoss"]=CFrame.new(-584.578,29.429,-1143.482),
    ["PandaMiniBoss"]=CFrame.new(1697.134,9.572,518.390),
}

local farmConnection = nil
local questConnection = nil
local isFarming = false
local isQuesting = false
local selectedMiniBoss = nil
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false
local lastAttackTime = 0
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

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    return pcall(function()
        if not character or not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if tool then humanoid:EquipTool(tool) end
    end)
end

local function teleportToSafeZone(miniBossName)
    if not humanoidRootPart then return false end
    local safeCFrame = miniBossSafeZones[miniBossName]
    if not safeCFrame then hasVisitedSafeZone = true; return true end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    humanoidRootPart.CFrame = safeCFrame
    return true
end

local function teleportToMiniBoss(miniBoss)
    if not humanoidRootPart then return false end
    local bossRoot = miniBoss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return false end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.MiniBossFarmHeight or 4, _G.SlowHub.MiniBossFarmDistance or 6)
    humanoidRootPart.CFrame = bossRoot.CFrame * offset
    return true
end

local function performAttack()
    local currentTime = tick()
    if currentTime - lastAttackTime < (_G.SlowHub.MiniBossFarmCooldown or 0.15) then return end
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
    if not selectedMiniBoss then return end
    if not miniBossConfig[selectedMiniBoss] then return end
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(miniBossConfig[selectedMiniBoss].quest) end
    end)
end

local function resetFarmState()
    lastTargetName = nil
    hasVisitedSafeZone = false
    wasAttackingBoss = false
    lastAttackTime = 0
end

local function stopQuestLoop()
    isQuesting = false
end

local function startQuestLoop()
    if isQuesting then return end
    isQuesting = true
    questConnection = task.spawn(function()
        while isQuesting and _G.SlowHub.AutoFarmMiniBosses do
            acceptQuest()
            task.wait(_G.SlowHub.QuestInterval or 2)
        end
    end)
end

local function stopAutoFarmMiniBoss()
    if not isFarming then return end
    isFarming = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    stopQuestLoop()
    resetFarmState()
    _G.SlowHub.AutoFarmMiniBosses = false
end

local function farmLoop()
    if not _G.SlowHub.AutoFarmMiniBosses then stopAutoFarmMiniBoss(); return end
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
    if wasAttackingBoss then hasVisitedSafeZone = false; wasAttackingBoss = false end
    if not selectedMiniBoss then return end
    if selectedMiniBoss ~= lastTargetName then
        lastTargetName = selectedMiniBoss
        hasVisitedSafeZone = false
    end
    if not hasVisitedSafeZone then
        if teleportToSafeZone(selectedMiniBoss) then hasVisitedSafeZone = true end
        task.wait(0.1)
        return
    end
    if not npcsFolder then return end
    local miniBoss = npcsFolder:FindFirstChild(selectedMiniBoss)
    if not miniBoss then return end
    local bossHumanoid = miniBoss:FindFirstChildOfClass("Humanoid")
    if not bossHumanoid or bossHumanoid.Health <= 0 then return end
    local success = teleportToMiniBoss(miniBoss)
    if success then equipWeapon(); performAttack() end
end

local function startAutoFarmMiniBoss()
    if isFarming then stopAutoFarmMiniBoss(); task.wait(0.3) end
    if not selectedMiniBoss then return false end
    if not miniBossConfig[selectedMiniBoss] then return false end
    initialize()
    if not npcsFolder then return false end
    isFarming = true
    _G.SlowHub.AutoFarmMiniBosses = true
    resetFarmState()
    startQuestLoop()
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
    return true
end

Tab:Section({Title = "Mini Bosses"})

Tab:Dropdown({
    Title = "Select Mini Boss",
    Flag = "SelectMiniBoss",
    Values = miniBossList,
    Multi = false,
    Default = _G.SlowHub.SelectMiniBoss or miniBossList[1],
    Callback = function(value)
        local wasRunning = isFarming
        if wasRunning then stopAutoFarmMiniBoss() end
        selectedMiniBoss = type(value) == "table" and value[1] or value
        _G.SlowHub.SelectMiniBoss = selectedMiniBoss
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if wasRunning then task.wait(0.3); startAutoFarmMiniBoss() end
    end,
})

Tab:Toggle({
    Title = "Auto Farm Mini Boss",
    Default = _G.SlowHub.AutoFarmMiniBosses or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmMiniBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoFarmMiniBoss()
        else
            stopAutoFarmMiniBoss()
        end
    end,
})

Tab:Slider({
    Title = "Mini Boss Distance",
    Flag = "MiniBossDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmDistance or 6,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Mini Boss Height",
    Flag = "MiniBossHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmHeight or 4,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "MiniBossCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.MiniBossFarmCooldown or 0.15,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmCooldown = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})
