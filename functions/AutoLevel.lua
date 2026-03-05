local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MainTab = _G.MainTab

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
    {minLevel = 9000, maxLevel = 99999, quest = "QuestNPC15", npc = "AcademyTeacher", count = 5}
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
    ["AcademyTeacher"] = CFrame.new(1072.5455322265625, 1.7783551216125488, 1275.641845703125)
}

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.FarmDistance = _G.SlowHub.FarmDistance or 8
_G.SlowHub.FarmHeight = _G.SlowHub.FarmHeight or 4
_G.SlowHub.FarmCooldown = _G.SlowHub.FarmCooldown or 0.15
_G.SlowHub.QuestInterval = _G.SlowHub.QuestInterval or 2
_G.SlowHub.IsAttackingBoss = false

local State = {
    FarmConnection = nil,
    QuestConnection = nil,
    IsFarming = false,
    IsQuesting = false,
    CurrentNPCIndex = 1,
    LastTargetName = nil,
    HasVisitedSafeZone = false,
    WasAttackingBoss = false,
    LastAttackTime = 0,
    LastNPCSwitch = 0,
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

local function GetPlayerLevel()
    local success, result = pcall(function()
        local data = Player:FindFirstChild("Data")
        if not data then return 1 end
        
        local levelValue = data:FindFirstChild("Level")
        if not levelValue then return 1 end
        
        return levelValue.Value
    end)
    
    return success and result or 1
end

local function GetCurrentConfig()
    local level = GetPlayerLevel()
    
    for _, config in ipairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then
            return config
        end
    end
    
    return LevelConfig[1]
end

local function GetNextIndex(current, maxCount)
    local nextIndex = current + 1
    if nextIndex > maxCount then return 1 end
    return nextIndex
end

local function GetNPC(npcName, index)
    if not State.NPCsFolder then return nil end
    return State.NPCsFolder:FindFirstChild(npcName .. index)
end

local function IsNPCAlive(npc)
    if not npc or not npc.Parent then return false end
    local humanoid = npc:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
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

local function TeleportToSafeZone(npcName)
    if not State.HumanoidRootPart then return false end
    
    local safeCFrame = NPCSafeZones[npcName]
    if not safeCFrame then
        State.HasVisitedSafeZone = true
        return true
    end
    
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    State.HumanoidRootPart.CFrame = safeCFrame
    
    return true
end

local function TeleportToNPC(npc)
    if not State.HumanoidRootPart then return false end
    
    local npcRoot = npc:FindFirstChild("HumanoidRootPart")
    if not npcRoot then return false end
    
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    
    local offset = CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
    local targetCFrame = npcRoot.CFrame * offset
    
    if (State.HumanoidRootPart.Position - targetCFrame.Position).Magnitude > 2 then
        State.HumanoidRootPart.CFrame = targetCFrame
    end
    
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
    if _G.SlowHub.IsAttackingBoss then return end
    
    pcall(function()
        local config = GetCurrentConfig()
        if not config then return end
        
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then
            questAccept:FireServer(config.quest)
        end
    end)
end

local function ResetFarmState()
    State.CurrentNPCIndex = 1
    State.LastTargetName = nil
    State.HasVisitedSafeZone = false
    State.WasAttackingBoss = false
    State.LastAttackTime = 0
    State.LastNPCSwitch = 0
end

local function StopQuestLoop()
    State.IsQuesting = false
    
    if State.QuestConnection then
        State.QuestConnection:Disconnect()
        State.QuestConnection = nil
    end
end

local function StartQuestLoop()
    if State.IsQuesting then return end
    
    State.IsQuesting = true
    
    State.QuestConnection = task.spawn(function()
        while State.IsQuesting and _G.SlowHub.AutoFarmLevel do
            AcceptQuest()
            task.wait(_G.SlowHub.QuestInterval)
        end
    end)
end

local function StopAutoLevel()
    if not State.IsFarming then return end
    
    State.IsFarming = false
    
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end
    
    StopQuestLoop()
    ResetFarmState()
    
    _G.SlowHub.AutoFarmLevel = false
    
    pcall(function()
        if State.HumanoidRootPart then
            State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmLevel then
        StopAutoLevel()
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
    
    local now = tick()
    local config = GetCurrentConfig()
    
    if not config then return end
    
    if State.LastTargetName ~= config.npc then
        State.LastTargetName = config.npc
        State.HasVisitedSafeZone = false
    end
    
    if not State.HasVisitedSafeZone then
        local success = TeleportToSafeZone(config.npc)
        if success then
            State.HasVisitedSafeZone = true
        end
        task.wait(0.1)
        return
    end
    
    local npc = GetNPC(config.npc, State.CurrentNPCIndex)
    local isAlive = IsNPCAlive(npc)
    
    if not isAlive then
        if (now - State.LastNPCSwitch) > 0 then
            State.CurrentNPCIndex = GetNextIndex(State.CurrentNPCIndex, config.count)
            State.LastNPCSwitch = now
        end
    else
        State.LastNPCSwitch = now
        
        local success = TeleportToNPC(npc)
        if success then
            EquipWeapon()
            PerformAttack()
        else
            State.CurrentNPCIndex = GetNextIndex(State.CurrentNPCIndex, config.count)
        end
    end
end

local function StartAutoLevel()
    if State.IsFarming then
        StopAutoLevel()
        task.wait(0.2)
    end
    
    InitializeState()
    
    if not State.NPCsFolder then return false end
    
    State.IsFarming = true
    _G.SlowHub.AutoFarmLevel = true
    
    ResetFarmState()
    StartQuestLoop()
    
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
    
    return true
end

local function Notify(title, content, duration)
    duration = duration or 3
    
    pcall(function()
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration,
                Image = 4483362458
            })
        end
    end)
end

MainTab:CreateSection("Auto Level")

MainTab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = _G.SlowHub.AutoFarmLevel or false,
    Flag = "AutoFarmLevel",
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Notify("Error", "Select a weapon first!", 3)
                return
            end
            
            StartAutoLevel()
        else
            StopAutoLevel()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSection("Farm Settings")

MainTab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.FarmDistance,
    Flag = "FarmDistance",
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.FarmHeight,
    Flag = "FarmHeight",
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSlider({
    Name = "Attack Cooldown",
    Range = {0.05, 0.5},
    Increment = 0.05,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.FarmCooldown,
    Flag = "FarmCooldown",
    Callback = function(Value)
        _G.SlowHub.FarmCooldown = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSlider({
    Name = "Quest Interval",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.QuestInterval,
    Flag = "QuestInterval",
    Callback = function(Value)
        _G.SlowHub.QuestInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    StartAutoLevel()
end
