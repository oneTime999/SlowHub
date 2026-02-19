local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MainTab = _G.MainTab

if not _G.SlowHub.DungeonFarmDistance then _G.SlowHub.DungeonFarmDistance = 4 end
if not _G.SlowHub.DungeonFarmHeight then _G.SlowHub.DungeonFarmHeight = 9 end

local dungeonConnection = nil
local voteLoopActive = false
local replayLoopActive = false

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    pcall(function()
        local character = Player.Character
        if character and character:FindFirstChild("Humanoid") and not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if weapon then character.Humanoid:EquipTool(weapon) end
            end
        end
    end)
end

local function GetClosestDungeonEnemy()
    local closestEnemy = nil
    local shortestDistance = math.huge
    local character = Player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return nil end

    local npcFolder = workspace:FindFirstChild("NPCs")
    if npcFolder then
        for _, npc in pairs(npcFolder:GetChildren()) do
            if npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
                local distance = (rootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = npc
                end
            end
        end
    end
    return closestEnemy
end

local function startVoteLoop()
    if voteLoopActive then return end
    voteLoopActive = true
    task.spawn(function()
        while voteLoopActive and _G.SlowHub.AutoVoteDungeon do
            if _G.SlowHub.DungeonVoteDifficulty then
                pcall(function()
                    ReplicatedStorage.Remotes.DungeonWaveVote:FireServer(_G.SlowHub.DungeonVoteDifficulty)
                end)
            end
            task.wait(2)
        end
    end)
end

local function stopVoteLoop()
    voteLoopActive = false
    _G.SlowHub.AutoVoteDungeon = false
end

local function startReplayLoop()
    if replayLoopActive then return end
    replayLoopActive = true
    task.spawn(function()
        while replayLoopActive and _G.SlowHub.AutoReplayDungeon do
            pcall(function()
                ReplicatedStorage.Remotes.DungeonWaveReplayVote:FireServer("sponsor")
            end)
            task.wait(5)
        end
    end)
end

local function stopReplayLoop()
    replayLoopActive = false
    _G.SlowHub.AutoReplayDungeon = false
end

local function stopDungeonFarm()
    if dungeonConnection then
        dungeonConnection:Disconnect()
        dungeonConnection = nil
    end
    _G.SlowHub.AutoFarmDungeon = false
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function startDungeonFarm()
    if dungeonConnection then stopDungeonFarm() end
    _G.SlowHub.AutoFarmDungeon = true
    
    local lastAttack = 0

    dungeonConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmDungeon then stopDungeonFarm() return end

        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if not playerRoot or not humanoid or humanoid.Health <= 0 then return end

        local target = GetClosestDungeonEnemy()

        if target then
            local targetRoot = target:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local now = tick()
                
                local targetCFrame = targetRoot.CFrame * CFrame.new(0, _G.SlowHub.DungeonFarmHeight, _G.SlowHub.DungeonFarmDistance)
                playerRoot.CFrame = targetCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

                EquipWeapon()
                
                if (now - lastAttack) > 0.1 then
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttack = now
                end
            end
        else
            playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

MainTab:CreateToggle({
    Name = "Auto Farm Dungeon",
    CurrentValue = false,
    Flag = "AutoFarmDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoFarmDungeon = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                return
            end
            startDungeonFarm()
        else
            stopDungeonFarm()
        end
    end
})

MainTab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.DungeonFarmDistance,
    Flag = "DungeonFarmDistance",
    Callback = function(Value)
        _G.SlowHub.DungeonFarmDistance = Value
    end
})

MainTab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.DungeonFarmHeight,
    Flag = "DungeonFarmHeight",
    Callback = function(Value)
        _G.SlowHub.DungeonFarmHeight = Value
    end
})

MainTab:CreateDropdown({
    Name = "Select Difficulty",
    Options = {"Easy", "Medium", "Hard", "Extreme"},
    CurrentOption = "",
    Flag = "DungeonVoteDifficulty",
    Callback = function(Option)
        _G.SlowHub.DungeonVoteDifficulty = Option[1] or Option
    end
})

MainTab:CreateToggle({
    Name = "Auto Vote Difficulty",
    CurrentValue = false,
    Flag = "AutoVoteDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoVoteDungeon = Value
        if Value then
            startVoteLoop()
        else
            stopVoteLoop()
        end
    end
})

MainTab:CreateToggle({
    Name = "Auto Replay Dungeon",
    CurrentValue = false,
    Flag = "AutoReplayDungeon",
    Callback = function(Value)
        _G.SlowHub.AutoReplayDungeon = Value
        if Value then
            startReplayLoop()
        else
            stopReplayLoop()
        end
    end
})
