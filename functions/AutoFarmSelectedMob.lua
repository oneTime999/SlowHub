local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

if not _G.SlowHub then _G.SlowHub = {} end
if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local MobList = {
    "Thief", 
    "Monkey", 
    "DesertBandit", 
    "FrostRogue", 
    "Sorcerer", 
    "Hollow", 
    "StrongSorcerer", 
    "Curse",
    "Slime",
    "Valentine"
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
    ["Slime"] = "QuestNPC14"
}

local MobSafeZones = {
    ["Thief"] = CFrame.new(177.723, 11.206, -157.246),
    ["Monkey"] = CFrame.new(-567.758, -0.874, 399.302),
    ["DesertBandit"] = CFrame.new(-867.638, -4.222, -446.678),
    ["FrostRogue"] = CFrame.new(-398.725, -1.138, -1071.568),
    ["Sorcerer"] = CFrame.new(1398.259, 8.486, 488.058),
    ["Hollow"] = CFrame.new(-482.868, -2.058, 936.237),
    ["StrongSorcerer"] = CFrame.new(637.979, 2.376, -1669.440),
    ["Curse"] = CFrame.new(-69.846, 1.907, -1857.250),
    ["Slime"] = CFrame.new(-1124.753, 19.703, 371.231),
    ["Valentine"] = CFrame.new(-1159.370, 4.414, -1245.361)
}

local autoFarmConnection = nil
local questLoopActive = false
local selectedMobs = {}
local currentMobIndex = 1
local currentNPCIndex = 1
local killCount = 0
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false
local lastValidQuest = nil
local lastStateCheck = 0
local lastNPCSwitch = 0
local stuckCheckTime = 0
local lastPosition = nil

local function getNPC(npcName, index)
    if workspace:FindFirstChild("NPCs") then
        return workspace.NPCs:FindFirstChild(npcName .. index)
    end
    return nil
end

local function getNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
    return nil
end

local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
end

local function getNextMobIndex()
    local next = currentMobIndex + 1
    if next > #selectedMobs then return 1 end
    return next
end

local function getQuestForMob(mobName)
    local quest = QuestConfig[mobName]
    if quest then
        lastValidQuest = quest
        return quest
    end
    return nil
end

local function getMobConfig(mobName)
    return {
        npc = mobName,
        quest = getQuestForMob(mobName),
        count = 5 
    }
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        local character = Player.Character
        if not character or not character:FindFirstChild("Humanoid") then return false end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return true end
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
            end
        end
    end)
    return success
end

local function stopAutoFarm()
    if autoFarmConnection then
        autoFarmConnection:Disconnect()
        autoFarmConnection = nil
    end
    questLoopActive = false
    _G.SlowHub.AutoFarmSelectedMob = false
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount = 0
    lastTargetName = nil
    hasVisitedSafeZone = false
    lastValidQuest = nil
    lastNPCSwitch = 0
    stuckCheckTime = 0
    lastPosition = nil
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function startQuestLoop()
    if questLoopActive then return end
    questLoopActive = true
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmSelectedMob do
            if _G.SlowHub.AutoQuestSelectedMob and not _G.SlowHub.IsAttackingBoss then
                pcall(function()
                    local currentMob = selectedMobs[currentMobIndex]
                    if currentMob then
                        local questToAccept = getQuestForMob(currentMob)
                        if questToAccept then
                            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(questToAccept)
                        end
                    end
                end)
            end
            task.wait(2)
        end
    end)
end

local function switchToNextMob()
    currentMobIndex = getNextMobIndex()
    currentNPCIndex = 1
    killCount = 0
    hasVisitedSafeZone = false
    stuckCheckTime = 0
    lastPosition = nil
end

local function startAutoFarm()
    if autoFarmConnection then stopAutoFarm() end
    if #selectedMobs == 0 then return end
    
    _G.SlowHub.IsAttackingBoss = false
    _G.SlowHub.AutoFarmSelectedMob = true
    currentMobIndex = 1
    currentNPCIndex = 1
    killCount = 0
    lastNPCSwitch = 0
    stuckCheckTime = tick()
    lastPosition = nil
    
    startQuestLoop()
    local lastAttack = 0
    
    autoFarmConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob then stopAutoFarm() return end
        
        local now = tick()
        
        if now - lastStateCheck >= 1 then
            lastStateCheck = now
            if not _G.SlowHub.AutoFarmBosses then
                _G.SlowHub.IsAttackingBoss = false
            end
        end
        
        if _G.SlowHub.IsAttackingBoss then 
            wasAttackingBoss = true 
            return 
        end
        
        if wasAttackingBoss then
            hasVisitedSafeZone = false
            wasAttackingBoss = false
            stuckCheckTime = now
            lastPosition = nil
        end

        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not playerRoot or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return end
        
        if #selectedMobs == 0 then stopAutoFarm() return end
        
        local currentMobName = selectedMobs[currentMobIndex]
        if not currentMobName then 
            currentMobIndex = 1
            currentMobName = selectedMobs[1]
            if not currentMobName then stopAutoFarm() return end
        end
        
        local config = getMobConfig(currentMobName)

        if currentMobName ~= lastTargetName then
            lastTargetName = currentMobName
            hasVisitedSafeZone = false
            stuckCheckTime = now
            lastPosition = nil
        end

        if not hasVisitedSafeZone then
            local safeCFrame = MobSafeZones[currentMobName]
            if safeCFrame then
                playerRoot.CFrame = safeCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.wait(0.5)
            end
            hasVisitedSafeZone = true
            stuckCheckTime = now
            lastPosition = playerRoot.Position
        end

        if now - stuckCheckTime > 10 then
            if lastPosition and (playerRoot.Position - lastPosition).Magnitude < 5 then
                currentNPCIndex = getNextNPC(currentNPCIndex, 10)
                stuckCheckTime = now
                lastPosition = playerRoot.Position
            else
                stuckCheckTime = now
                lastPosition = playerRoot.Position
            end
        end

        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0

        if not npcAlive then
            if now - lastNPCSwitch > 0.5 then
                killCount = killCount + 1
                if killCount >= 25 then
                    switchToNextMob()
                    return
                else
                    currentNPCIndex = getNextNPC(currentNPCIndex, 10)
                    lastNPCSwitch = now
                end
            end
        else
            lastNPCSwitch = now
            killCount = 0
            local npcRoot = getNPCRootPart(npc)
            if npcRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                local targetCFrame = npcRoot.CFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                playerRoot.CFrame = targetCFrame
                
                EquipWeapon()
                
                if (now - lastAttack) > 0.15 then
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttack = now
                end
            else
                if now - lastNPCSwitch > 0.5 then
                    currentNPCIndex = getNextNPC(currentNPCIndex, 10)
                    lastNPCSwitch = now
                end
            end
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Mobs (Multi Select)",
    Options = MobList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "SelectMobs",
    Callback = function(Option)
        selectedMobs = {}
        if type(Option) == "table" then
            for _, value in ipairs(Option) do
                table.insert(selectedMobs, tostring(value))
            end
        end
        
        currentMobIndex = 1
        currentNPCIndex = 1
        killCount = 0
        hasVisitedSafeZone = false
        lastValidQuest = nil
        lastNPCSwitch = 0
        stuckCheckTime = 0
        lastPosition = nil
        
        if _G.SlowHub.AutoFarmSelectedMob and #selectedMobs > 0 then
            stopAutoFarm()
            task.wait(0.1)
            startAutoFarm()
        elseif #selectedMobs == 0 then
            stopAutoFarm()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Selected Mobs",
    CurrentValue = false,
    Flag = "AutoFarmSelectedMob",
    Callback = function(Value)
        _G.SlowHub.AutoFarmSelectedMob = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                return
            end
            if #selectedMobs == 0 then
                return
            end
            startAutoFarm()
        else
            stopAutoFarm()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Quest",
    CurrentValue = false,
    Flag = "AutoQuestSelectedMob",
    Callback = function(Value)
        _G.SlowHub.AutoQuestSelectedMob = Value
    end
})

Tab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmDistance,
    Flag = "FarmDistance",
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
    end
})

Tab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmHeight,
    Flag = "FarmHeight",
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
    end
})
