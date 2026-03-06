local Tab = _G.DungeonsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local farmConnection = nil
local voteLoop = nil
local replayLoop = nil
local isFarming = false
local isVoting = false
local isReplaying = false
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
    if child.Name == "NPCs" then
        npcsFolder = child
    end
end)

local function equipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    local success = pcall(function()
        if not character then return end
        if not humanoid then return end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then humanoid:EquipTool(weapon) end
    end)
    return success
end

local function getClosestEnemy()
    if not humanoidRootPart then return nil end
    if not npcsFolder then return nil end
    local closestEnemy = nil
    local shortestDistance = math.huge
    local playerPosition = humanoidRootPart.Position
    for _, npc in ipairs(npcsFolder:GetChildren()) do
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

local function teleportToEnemy(enemy)
    if not humanoidRootPart then return false end
    local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
    if not enemyRoot then return false end
    humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.DungeonFarmHeight or 9, _G.SlowHub.DungeonFarmDistance or 4)
    humanoidRootPart.CFrame = enemyRoot.CFrame * offset
    return true
end

local function performAttack()
    local currentTime = tick()
    if currentTime - lastAttackTime < (_G.SlowHub.DungeonFarmCooldown or 0.1) then return end
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

local function voteDifficulty()
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

local function voteReplay()
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

local function stopVoteLoop()
    isVoting = false
end

local function startVoteLoop()
    if isVoting then return end
    isVoting = true
    voteLoop = task.spawn(function()
        while isVoting and _G.SlowHub.AutoVoteDungeon do
            voteDifficulty()
            task.wait(2)
        end
    end)
end

local function stopReplayLoop()
    isReplaying = false
end

local function startReplayLoop()
    if isReplaying then return end
    isReplaying = true
    replayLoop = task.spawn(function()
        while isReplaying and _G.SlowHub.AutoReplayDungeon do
            voteReplay()
            task.wait(5)
        end
    end)
end

local function stopDungeonFarm()
    if not isFarming then return end
    isFarming = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
    pcall(function()
        if humanoidRootPart then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end)
end

local function farmLoop()
    if not _G.SlowHub.AutoFarmDungeon then
        stopDungeonFarm()
        return
    end
    if not character or not character.Parent then return end
    if not humanoidRootPart then
        humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
    end
    if not humanoid then
        humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then return end
    end
    local target = getClosestEnemy()
    if target then
        local success = teleportToEnemy(target)
        if success then
            equipWeapon()
            performAttack()
        end
    else
        if humanoidRootPart then
            humanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end

local function startDungeonFarm()
    if isFarming then
        stopDungeonFarm()
        task.wait(0.2)
    end
    initialize()
    isFarming = true
    lastAttackTime = 0
    farmConnection = RunService.Heartbeat:Connect(farmLoop)
end

Tab:Section({Title = "Dungeon Farm"})

Tab:Toggle({
    Title = "Auto Farm Dungeon or Boss Rush",
    Flag = "AutoFarmDungeon",
    Value = _G.SlowHub.AutoFarmDungeon or false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmDungeon = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            startDungeonFarm()
        else
            stopDungeonFarm()
        end
    end,
})

Tab:Slider({
    Title = "Farm Distance",
    Flag = "DungeonFarmDistance",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.DungeonFarmDistance or 4,
    },
    Callback = function(Value)
        _G.SlowHub.DungeonFarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Slider({
    Title = "Farm Height",
    Flag = "DungeonFarmHeight",
    Step = 1,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.DungeonFarmHeight or 9,
    },
    Callback = function(Value)
        _G.SlowHub.DungeonFarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Slider({
    Title = "Attack Cooldown",
    Flag = "DungeonFarmCooldown",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 0.5,
        Default = _G.SlowHub.DungeonFarmCooldown or 0.1,
    },
    Callback = function(Value)
        _G.SlowHub.DungeonFarmCooldown = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Section({Title = "Voting"})

Tab:Dropdown({
    Title = "Select Difficulty",
    Flag = "DungeonVoteDifficulty",
    Values = {"Easy", "Medium", "Hard", "Extreme"},
    Multi = false,
    Value = _G.SlowHub.DungeonVoteDifficulty or "Easy",
    Callback = function(option)
        _G.SlowHub.DungeonVoteDifficulty = type(option) == "table" and option[1] or option
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Toggle({
    Title = "Auto Vote Difficulty",
    Flag = "AutoVoteDungeon",
    Value = _G.SlowHub.AutoVoteDungeon or false,
    Callback = function(Value)
        _G.SlowHub.AutoVoteDungeon = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            startVoteLoop()
        else
            stopVoteLoop()
        end
    end,
})

Tab:Section({Title = "Replay"})

Tab:Toggle({
    Title = "Auto Replay Dungeon or Boss Rush",
    Flag = "AutoReplayDungeon",
    Value = _G.SlowHub.AutoReplayDungeon or false,
    Callback = function(Value)
        _G.SlowHub.AutoReplayDungeon = Value
        if _G.SaveConfig then _G.SaveConfig() end
        if Value then
            startReplayLoop()
        else
            stopReplayLoop()
        end
    end,
})
