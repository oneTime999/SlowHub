local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

if not _G.SlowHub then _G.SlowHub = {} end
if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local MobList = {"Thief", "Monkey", "DesertBandit", "FrostRogue", "Sorcerer", "Hollow"}
local QuestConfig = {
    ["Thief"] = "QuestNPC1",
    ["Monkey"] = "QuestNPC3", 
    ["DesertBandit"] = "QuestNPC5",
    ["FrostRogue"] = "QuestNPC7",
    ["Sorcerer"] = "QuestNPC9",
    ["Hollow"] = "QuestNPC11"
}

local MobSafeZones = {
    ["Thief"]        = CFrame.new(177.723, 11.206, -157.246),
    ["Monkey"]       = CFrame.new(-567.758, -0.874, 399.302),
    ["DesertBandit"] = CFrame.new(-867.638, -4.222, -446.678),
    ["FrostRogue"]   = CFrame.new(-398.725, -1.138, -1071.568),
    ["Sorcerer"]     = CFrame.new(1398.259, 8.486, 488.058),
    ["Hollow"]       = CFrame.new(-482.868, -2.058, 936.237)
}

local autoFarmSelectedConnection = nil
local questLoopActive = false
local selectedMob = nil
local currentNPCIndex = 1
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false

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

local function getQuestForMob(mobName)
    return QuestConfig[mobName] or "QuestNPC1"
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

local function stopAutoFarmSelectedMob()
    if autoFarmSelectedConnection then
        autoFarmSelectedConnection:Disconnect()
        autoFarmSelectedConnection = nil
    end
    questLoopActive = false
    _G.SlowHub.AutoFarmSelectedMob = false
    currentNPCIndex = 1
    lastTargetName = nil
    hasVisitedSafeZone = false
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

local function startQuestLoop(questName)
    if questLoopActive then return end
    questLoopActive = true
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmSelectedMob do
            if _G.SlowHub.AutoQuestSelectedMob and not _G.SlowHub.IsAttackingBoss then
                pcall(function()
                    ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(questName)
                end)
            end
            task.wait(2)
        end
    end)
end

local function startAutoFarmSelectedMob()
    if autoFarmSelectedConnection then stopAutoFarmSelectedMob() end
    _G.SlowHub.AutoFarmSelectedMob = true
    local config = getMobConfig(selectedMob)
    startQuestLoop(config.quest)
    local lastAttack = 0
    
    autoFarmSelectedConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmSelectedMob then stopAutoFarmSelectedMob() return end
        if _G.SlowHub.IsAttackingBoss then wasAttackingBoss = true return end
        
        if wasAttackingBoss then
            hasVisitedSafeZone = false
            wasAttackingBoss = false
        end

        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        if not playerRoot or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then return end
        
        local now = tick()
        local config = getMobConfig(selectedMob)

        if selectedMob ~= lastTargetName then
            lastTargetName = selectedMob
            hasVisitedSafeZone = false
        end

        if not hasVisitedSafeZone then
            local safeCFrame = MobSafeZones[selectedMob]
            if safeCFrame then
                playerRoot.CFrame = safeCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                task.wait(0.5)
            end
            hasVisitedSafeZone = true
        end

        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0

        if not npcAlive then
            currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
        else
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
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
            end
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Mob",
    Options = MobList,
    CurrentOption = "",
    Flag = "SelectMob",
    Callback = function(Option)
        local Value = Option[1] or Option
        selectedMob = tostring(Value)
        currentNPCIndex = 1
        hasVisitedSafeZone = false
        if _G.SlowHub.AutoFarmSelectedMob then
            startAutoFarmSelectedMob()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Selected Mob",
    CurrentValue = false,
    Flag = "AutoFarmSelectedMob",
    Callback = function(Value)
        _G.SlowHub.AutoFarmSelectedMob = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                return
            end
            if not selectedMob or selectedMob == "" then
                return
            end
            startAutoFarmSelectedMob()
        else
            stopAutoFarmSelectedMob()
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
