local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MainTab = _G.MainTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.DungeonFarmDistance = _G.SlowHub.DungeonFarmDistance or 4
_G.SlowHub.DungeonFarmHeight = _G.SlowHub.DungeonFarmHeight or 9
_G.SlowHub.DungeonFarmCooldown = _G.SlowHub.DungeonFarmCooldown or 0.1
_G.SlowHub.VoteInterval = _G.SlowHub.VoteInterval or 2
_G.SlowHub.ReplayInterval = _G.SlowHub.ReplayInterval or 5

local State = {
    FarmConnection = nil,
    VoteConnection = nil,
    ReplayConnection = nil,
    IsFarming = false,
    IsVoting = false,
    IsReplaying = false,
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
        
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then
            State.Humanoid:EquipTool(weapon)
            return true
        end
        
        return false
    end)
    
    return success
end

local function GetClosestDungeonEnemy()
    if not State.HumanoidRootPart then return nil end
    if not State.NPCsFolder then return nil end
    
    local closestEnemy = nil
    local shortestDistance = math.huge
    local playerPosition = State.HumanoidRootPart.Position
    
    for _, npc in ipairs(State.NPCsFolder:GetChildren()) do
        if not npc:IsA("Model") then continue end
        
        local npcHumanoid = npc:FindFirstChildOfClass("Humanoid")
        if not npcHumanoid or npcHumanoid.Health <= 0 then continue end
        
        local npcRoot = npc:FindFirstChild("HumanoidRootPart")
        if not npcRoot then continue end
        
        local distance = (playerPosition - npcRoot.Position).Magnitude
        if distance < shortestDistance then
            shortestDistance = distance
            closestEnemy = npc
        end
    end
    
    return closestEnemy
end

local function TeleportToEnemy(enemy)
    if not State.HumanoidRootPart then return false end
    
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return false end
    
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    
    local offset = CFrame.new(0, _G.SlowHub.DungeonFarmHeight, _G.SlowHub.DungeonFarmDistance)
    State.HumanoidRootPart.CFrame = enemyRoot.CFrame * offset
    
    return true
end

local function PerformAttack()
    local currentTime = tick()
    local cooldown = _G.SlowHub.DungeonFarmCooldown
    
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

local function VoteDifficulty()
    if not _G.SlowHub.AutoVoteDungeon then return end
    if not _G.SlowHub.DungeonVoteDifficulty then return end
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local dungeonWaveVote = remotes:FindFirstChild("DungeonWaveVote")
        if dungeonWaveVote then
            dungeonWaveVote:FireServer(_G.SlowHub.DungeonVoteDifficulty)
        end
    end)
end

local function VoteReplay()
    if not _G.SlowHub.AutoReplayDungeon then return end
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local dungeonWaveReplayVote = remotes:FindFirstChild("DungeonWaveReplayVote")
        if dungeonWaveReplayVote then
            dungeonWaveReplayVote:FireServer("sponsor")
        end
    end)
end

local function StopVoteLoop()
    State.IsVoting = false
    
    if State.VoteConnection then
        State.VoteConnection:Disconnect()
        State.VoteConnection = nil
    end
end

local function StartVoteLoop()
    if State.IsVoting then return end
    
    State.IsVoting = true
    
    State.VoteConnection = task.spawn(function()
        while State.IsVoting and _G.SlowHub.AutoVoteDungeon do
            VoteDifficulty()
            task.wait(_G.SlowHub.VoteInterval)
        end
    end)
end

local function StopReplayLoop()
    State.IsReplaying = false
    
    if State.ReplayConnection then
        State.ReplayConnection:Disconnect()
        State.ReplayConnection = nil
    end
end

local function StartReplayLoop()
    if State.IsReplaying then return end
    
    State.IsReplaying = true
    
    State.ReplayConnection = task.spawn(function()
        while State.IsReplaying and _G.SlowHub.AutoReplayDungeon do
            VoteReplay()
            task.wait(_G.SlowHub.ReplayInterval)
        end
    end)
end

local function StopDungeonFarm()
    if not State.IsFarming then return end
    
    State.IsFarming = false
    
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end
    
    _G.SlowHub.AutoFarmDungeon = false
    
    pcall(function()
        if State.HumanoidRootPart then
            State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmDungeon then
        StopDungeonFarm()
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
    
    local target = GetClosestDungeonEnemy()
    
    if target then
        local success = TeleportToEnemy(target)
        if success then
            EquipWeapon()
            PerformAttack()
        end
    else
        if State.HumanoidRootPart then
            State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function StartDungeonFarm()
    if State.IsFarming then
        StopDungeonFarm()
        task.wait(0.2)
    end
    
    InitializeState()
    
    State.IsFarming = true
    _G.SlowHub.AutoFarmDungeon = true
    
    State.LastAttackTime = 0
    
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
end

local function Notify(title, content, duration)
    duration = duration or 3
    
    pcall(function()
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration
            })
        end
    end)
end

MainTab:CreateSection("Dungeon Farm")

MainTab:CreateToggle({
    Name = "Auto Farm Dungeon or Boss Rush",
    CurrentValue = false,
    Flag = "AutoFarmDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoFarmDungeon = Value
        
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Notify("Error", "Please select a weapon first!", 3)
                return
            end
            
            StartDungeonFarm()
        else
            StopDungeonFarm()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.DungeonFarmDistance,
    Flag = "DungeonFarmDistance",
    Callback = function(Value)
        _G.SlowHub.DungeonFarmDistance = Value
        
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
    CurrentValue = _G.SlowHub.DungeonFarmHeight,
    Flag = "DungeonFarmHeight",
    Callback = function(Value)
        _G.SlowHub.DungeonFarmHeight = Value
        
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
    CurrentValue = _G.SlowHub.DungeonFarmCooldown,
    Flag = "DungeonFarmCooldown",
    Callback = function(Value)
        _G.SlowHub.DungeonFarmCooldown = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSection("Voting")

MainTab:CreateDropdown({
    Name = "Select Difficulty",
    Options = {"Easy", "Medium", "Hard", "Extreme"},
    CurrentOption = "",
    Flag = "DungeonVoteDifficulty",
    Callback = function(Option)
        local selected = type(Option) == "table" and Option[1] or Option
        _G.SlowHub.DungeonVoteDifficulty = selected
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSlider({
    Name = "Vote Interval",
    Range = {1, 5},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.VoteInterval,
    Flag = "VoteInterval",
    Callback = function(Value)
        _G.SlowHub.VoteInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto Vote Difficulty",
    CurrentValue = false,
    Flag = "AutoVoteDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoVoteDungeon = Value
        
        if Value then
            StartVoteLoop()
        else
            StopVoteLoop()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateSection("Replay")

MainTab:CreateSlider({
    Name = "Replay Interval",
    Range = {3, 10},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.ReplayInterval,
    Flag = "ReplayInterval",
    Callback = function(Value)
        _G.SlowHub.ReplayInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto Replay Dungeon or Boss Rush",
    CurrentValue = false,
    Flag = "AutoReplayDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoReplayDungeon = Value
        
        if Value then
            StartReplayLoop()
        else
            StopReplayLoop()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
