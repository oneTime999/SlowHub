local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.BossesTab

_G.SlowHub.MiniBossFarmDistance = _G.SlowHub.MiniBossFarmDistance or 6
_G.SlowHub.MiniBossFarmHeight = _G.SlowHub.MiniBossFarmHeight or 4
_G.SlowHub.MiniBossFarmCooldown = _G.SlowHub.MiniBossFarmCooldown or 0.15
_G.SlowHub.QuestInterval = _G.SlowHub.QuestInterval or 2

local MiniBossConfig = {
    ["ThiefBoss"] = {quest = "QuestNPC2"},
    ["MonkeyBoss"] = {quest = "QuestNPC4"},
    ["DesertBoss"] = {quest = "QuestNPC6"},
    ["SnowBoss"] = {quest = "QuestNPC8"},
    ["PandaMiniBoss"] = {quest = "QuestNPC10"}
}

local miniBossList = {"ThiefBoss", "MonkeyBoss", "DesertBoss", "SnowBoss", "PandaMiniBoss"}

local MiniBossSafeZones = {
    ["ThiefBoss"] = CFrame.new(-66.633, -2.584, -162.471),
    ["MonkeyBoss"] = CFrame.new(-494.757, 49.211, 496.788),
    ["DesertBoss"] = CFrame.new(-972.217, 2.346, -475.585),
    ["SnowBoss"] = CFrame.new(-584.578, 29.429, -1143.482),
    ["PandaMiniBoss"] = CFrame.new(1697.134, 9.572, 518.390)
}

local State = {
    FarmConnection = nil,
    QuestConnection = nil,
    IsFarming = false,
    IsQuesting = false,
    SelectedMiniBoss = nil,
    LastTargetName = nil,
    HasVisitedSafeZone = false,
    WasAttackingBoss = false,
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

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        if not State.Character then return false end
        if not State.Humanoid then return false end
        local hasEquipped = State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if hasEquipped then return true end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return false end
        local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if tool then
            State.Humanoid:EquipTool(tool)
            return true
        end
        return false
    end)
    return success
end

local function TeleportToSafeZone(miniBossName)
    if not State.HumanoidRootPart then return false end
    local safeCFrame = MiniBossSafeZones[miniBossName]
    if not safeCFrame then
        State.HasVisitedSafeZone = true
        return true
    end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    State.HumanoidRootPart.CFrame = safeCFrame
    return true
end

local function TeleportToMiniBoss(miniBoss)
    if not State.HumanoidRootPart then return false end
    local bossRoot = miniBoss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return false end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.MiniBossFarmHeight, _G.SlowHub.MiniBossFarmDistance)
    State.HumanoidRootPart.CFrame = bossRoot.CFrame * offset
    return true
end

local function PerformAttack()
    local currentTime = tick()
    local cooldown = _G.SlowHub.MiniBossFarmCooldown
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
    if not State.SelectedMiniBoss then return end
    if not MiniBossConfig[State.SelectedMiniBoss] then return end
    if _G.SlowHub.IsAttackingBoss then return end
    local config = MiniBossConfig[State.SelectedMiniBoss]
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then
            questAccept:FireServer(config.quest)
        end
    end)
end

local function ResetFarmState()
    State.LastTargetName = nil
    State.HasVisitedSafeZone = false
    State.WasAttackingBoss = false
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
        while State.IsQuesting and _G.SlowHub.AutoFarmMiniBosses do
            AcceptQuest()
            task.wait(_G.SlowHub.QuestInterval)
        end
    end)
end

local function StopAutoFarmMiniBoss()
    if not State.IsFarming then return end
    State.IsFarming = false
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end
    StopQuestLoop()
    ResetFarmState()
    _G.SlowHub.AutoFarmMiniBosses = false
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmMiniBosses then
        StopAutoFarmMiniBoss()
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
    if not State.SelectedMiniBoss then return end
    if State.SelectedMiniBoss ~= State.LastTargetName then
        State.LastTargetName = State.SelectedMiniBoss
        State.HasVisitedSafeZone = false
    end
    if not State.HasVisitedSafeZone then
        local success = TeleportToSafeZone(State.SelectedMiniBoss)
        if success then
            State.HasVisitedSafeZone = true
        end
        task.wait(0.1)
        return
    end
    if not State.NPCsFolder then return end
    local miniBoss = State.NPCsFolder:FindFirstChild(State.SelectedMiniBoss)
    if not miniBoss then return end
    local humanoid = miniBoss:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local success = TeleportToMiniBoss(miniBoss)
    if success then
        EquipWeapon()
        PerformAttack()
    end
end

local function StartAutoFarmMiniBoss()
    if State.IsFarming then
        StopAutoFarmMiniBoss()
        task.wait(0.3)
    end
    if not State.SelectedMiniBoss then return false end
    if not MiniBossConfig[State.SelectedMiniBoss] then return false end
    InitializeState()
    if not State.NPCsFolder then return false end
    State.IsFarming = true
    _G.SlowHub.AutoFarmMiniBosses = true
    ResetFarmState()
    StartQuestLoop()
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
    return true
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

Tab:Section({Title = "Mini Bosses"})

Tab:Dropdown({
    Title = "Select Mini Boss",
    Values = miniBossList,
    Default = State.SelectedMiniBoss or "",
    Callback = function(Value)
        local wasRunning = State.IsFarming
        if wasRunning then
            StopAutoFarmMiniBoss()
        end
        State.SelectedMiniBoss = type(Value) == "table" and Value[1] or Value
        if wasRunning then
            task.wait(0.3)
            StartAutoFarmMiniBoss()
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Toggle({
    Title = "Auto Farm Mini Boss",
    Default = false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Notify("Error", "Please select a weapon!", 3)
                return
            end
            if not State.SelectedMiniBoss or State.SelectedMiniBoss == "" then
                Notify("Error", "Please select a Mini Boss!", 3)
                return
            end
            StartAutoFarmMiniBoss()
        else
            StopAutoFarmMiniBoss()
        end
        _G.SlowHub.AutoFarmMiniBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Mini Boss Distance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmDistance,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Mini Boss Height",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.MiniBossFarmHeight,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Attack Cooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.MiniBossFarmCooldown,
    },
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmCooldown = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
