local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MainTab

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
    "AcademyTeacher"
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
    ["Slime"] = "QuestNPC14",
    ["AcademyTeacher"] = "QuestNPC15"
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
    ["AcademyTeacher"] = CFrame.new(1072.5455322265625, 1.7783551216125488, 1275.641845703125)
}

local State = {
    FarmConnection = nil,
    QuestConnection = nil,
    IsFarming = false,
    IsQuesting = false,
    SelectedMobs = {},
    CurrentMobIndex = 1,
    CurrentNPCIndex = 1,
    KillCount = 0,
    LastTargetName = nil,
    HasVisitedSafeZone = false,
    WasAttackingBoss = false,
    LastValidQuest = nil,
    LastAttackTime = 0,
    Character = nil,
    HumanoidRootPart = nil,
    Humanoid = nil,
    NPCsFolder = nil
}

local function InitializeState()
    State.Character = Player.Character
    State.Humanoid = State.Character and State.Character:FindFirstChildOfClass("Humanoid")
    State.HumanoidRootPart = State.Character and State.Character:FindFirstChild("HumanoidRootPart")
    State.NPCsFolder = workspace:FindFirstChild("NPCs")
end

InitializeState()

Player.CharacterAdded:Connect(function(char)
    State.Character = char
    State.Humanoid = nil
    State.HumanoidRootPart = nil
    task.wait(0.1)
    State.Humanoid = char:FindFirstChildOfClass("Humanoid")
    State.HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        State.NPCsFolder = child
    end
end)

local function GetNPC(npcName, index)
    if not State.NPCsFolder then return nil end
    return State.NPCsFolder:FindFirstChild(npcName .. index)
end

local function GetNPCRootPart(npc)
    if not npc then return nil end
    return npc:FindFirstChild("HumanoidRootPart")
end

local function IsNPCAlive(npc)
    if not npc or not npc.Parent then return false end
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetNextIndex(current, maxCount)
    local nextIndex = current + 1
    if nextIndex > maxCount then return 1 end
    return nextIndex
end

local function GetNextMobIndex()
    return GetNextIndex(State.CurrentMobIndex, #State.SelectedMobs)
end

local function GetQuestForMob(mobName)
    local quest = QuestConfig[mobName]
    if quest then
        State.LastValidQuest = quest
        return quest
    end
    return nil
end

local function GetMobConfig(mobName)
    return {
        npc = mobName,
        quest = GetQuestForMob(mobName),
        count = 5
    }
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        if not State.Character then return false end
        if not State.Humanoid then return false end
        local hasEquipped = State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if hasEquipped then return true end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return false end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then
            State.Humanoid:EquipTool(weapon)
            return true
        end
        return false
    end)
    return success
end

local function TeleportToSafeZone(mobName)
    if not State.HumanoidRootPart then return false end
    local safeCFrame = MobSafeZones[mobName]
    if not safeCFrame then return true end
    State.HumanoidRootPart.CFrame = safeCFrame
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    return true
end

local function TeleportToNPC(npc)
    if not State.HumanoidRootPart then return false end
    local npcRoot = GetNPCRootPart(npc)
    if not npcRoot then return false end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
    State.HumanoidRootPart.CFrame = npcRoot.CFrame * offset
    return true
end

local function PerformAttack()
    local currentTime = tick()
    local cooldown = _G.SlowHub.FarmCooldown
    if currentTime - State.LastAttackTime < cooldown then
        return
    end
    State.LastAttackTime = currentTime
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

local function AcceptQuest()
    if not _G.SlowHub.AutoQuestSelectedMob then return end
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local currentMob = State.SelectedMobs[State.CurrentMobIndex]
        if not currentMob then return end
        local questToAccept = GetQuestForMob(currentMob)
        if not questToAccept then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then
            questAccept:FireServer(questToAccept)
        end
    end)
end

local function SwitchToNextMob()
    State.CurrentMobIndex = GetNextMobIndex()
    State.CurrentNPCIndex = 1
    State.KillCount = 0
    State.HasVisitedSafeZone = false
end

local function ResetFarmState()
    State.CurrentMobIndex = 1
    State.CurrentNPCIndex = 1
    State.KillCount = 0
    State.LastTargetName = nil
    State.HasVisitedSafeZone = false
    State.LastValidQuest = nil
    State.LastAttackTime = 0
end

local function StopQuestLoop()
    State.IsQuesting = false
    if State.QuestConnection then
        State.QuestConnection = nil
    end
end

local function StartQuestLoop()
    if State.IsQuesting then return end
    State.IsQuesting = true
    State.QuestConnection = task.spawn(function()
        while State.IsQuesting and _G.SlowHub.AutoFarmSelectedMob do
            AcceptQuest()
            task.wait(_G.SlowHub.AutoQuestInterval)
        end
    end)
end

function StopAutoFarm()
    if not State.IsFarming then return end
    State.IsFarming = false
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end
    StopQuestLoop()
    ResetFarmState()
    pcall(function()
        if State.HumanoidRootPart then
            State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmSelectedMob then
        StopAutoFarm()
        return
    end
    if not State.Character or not State.Character.Parent then
        return
    end
    if not State.HumanoidRootPart then
        State.HumanoidRootPart = State.Character:FindFirstChild("HumanoidRootPart")
        if not State.HumanoidRootPart then return end
    end
    if not State.Humanoid then
        State.Humanoid = State.Character:FindFirstChildOfClass("Humanoid")
        if not State.Humanoid or State.Humanoid.Health <= 0 then return end
    end
    if _G.SlowHub.IsAttackingBoss then
        State.WasAttackingBoss = true
        return
    end
    if State.WasAttackingBoss then
        State.HasVisitedSafeZone = false
        State.WasAttackingBoss = false
    end
    if #State.SelectedMobs == 0 then
        StopAutoFarm()
        return
    end
    local currentMobName = State.SelectedMobs[State.CurrentMobIndex]
    if not currentMobName then
        State.CurrentMobIndex = 1
        currentMobName = State.SelectedMobs[1]
        if not currentMobName then
            StopAutoFarm()
            return
        end
    end
    local config = GetMobConfig(currentMobName)
    if currentMobName ~= State.LastTargetName then
        State.LastTargetName = currentMobName
        State.HasVisitedSafeZone = false
    end
    if not State.HasVisitedSafeZone then
        local success = TeleportToSafeZone(currentMobName)
        if success then
            State.HasVisitedSafeZone = true
        end
        task.wait(0.1)
        return
    end
    local npc = GetNPC(config.npc, State.CurrentNPCIndex)
    local isAlive = IsNPCAlive(npc)
    if not isAlive then
        State.KillCount = State.KillCount + 1
        if State.KillCount >= 5 then
            SwitchToNextMob()
            return
        else
            State.CurrentNPCIndex = GetNextIndex(State.CurrentNPCIndex, config.count)
        end
    else
        local success = TeleportToNPC(npc)
        if success then
            EquipWeapon()
            PerformAttack()
        else
            State.CurrentNPCIndex = GetNextIndex(State.CurrentNPCIndex, config.count)
        end
    end
end

function StartAutoFarm()
    if State.IsFarming then
        StopAutoFarm()
        task.wait(0.2)
    end
    InitializeState()
    if #State.SelectedMobs == 0 then return false end
    if not State.NPCsFolder then return false end
    State.IsFarming = true
    ResetFarmState()
    StartQuestLoop()
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
    return true
end

local function UpdateSelectedMobs(options)
    State.SelectedMobs = {}
    if type(options) == "table" then
        for _, value in ipairs(options) do
            table.insert(State.SelectedMobs, tostring(value))
        end
    end
    ResetFarmState()
    if _G.SlowHub.AutoFarmSelectedMob and #State.SelectedMobs > 0 then
        StopAutoFarm()
        task.wait(0.1)
        StartAutoFarm()
    elseif #State.SelectedMobs == 0 then
        StopAutoFarm()
    end
end

local function Notify(title, content, duration)
    duration = duration or 3
    pcall(function()
        if _G.WindUI and _G.WindUI.Notify then
            _G.WindUI:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Icon = "rbxassetid://4483362458"
            })
        end
    end)
end

Tab:Section({Title = "Mob Selection"})

Tab:Dropdown({
    Title = "Select Mobs (Multi Select)",
    Flag = "SelectedMobs",
    Values = MobList,
    Multi = true,
    Default = {},
    Callback = function(Option)
        UpdateSelectedMobs(Option)
    end
})

Tab:Section({Title = "Farm Control"})

Tab:Toggle({
    Title = "Auto Farm Selected Mobs",
    Flag = "AutoFarmSelectedMob",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Notify("Error", "Please select a weapon first!", 3)
                return
            end
            if #State.SelectedMobs == 0 then
                Notify("Error", "Please select at least one mob!", 3)
                return
            end
            StartAutoFarm()
        else
            StopAutoFarm()
        end
    end
})

Tab:Toggle({
    Title = "Auto Quest",
    Flag = "AutoQuestSelectedMob",
    Default = false,
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Farm Distance",
    Flag = "FarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 8,
    },
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Farm Height",
    Flag = "FarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = 4,
    },
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "FarmCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = 0.15,
    },
    Callback = function(Value)
    end
})

Tab:Slider({
    Title = "Quest Interval",
    Flag = "AutoQuestInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 5,
        Default = 2,
    },
    Callback = function(Value)
    end
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.SelectedMobs then
        UpdateSelectedMobs(_G.SlowHub.SelectedMobs)
    end
    if _G.SlowHub.AutoFarmSelectedMob then
        StartAutoFarm()
    end
end)
