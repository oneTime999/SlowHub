local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoFarmDungeon = _G.SlowHub.AutoFarmDungeon or false
_G.SlowHub.DungeonFarmDistance = _G.SlowHub.DungeonFarmDistance or 4
_G.SlowHub.DungeonFarmHeight = _G.SlowHub.DungeonFarmHeight or 9
_G.SlowHub.DungeonFarmCooldown = _G.SlowHub.DungeonFarmCooldown or 0.1
_G.SlowHub.DungeonVoteDifficulty = _G.SlowHub.DungeonVoteDifficulty or "Easy"
_G.SlowHub.VoteInterval = _G.SlowHub.VoteInterval or 2
_G.SlowHub.AutoVoteDungeon = _G.SlowHub.AutoVoteDungeon or false
_G.SlowHub.ReplayInterval = _G.SlowHub.ReplayInterval or 5
_G.SlowHub.AutoReplayDungeon = _G.SlowHub.AutoReplayDungeon or false

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(current))
    end)
end

local saved = loadConfig()
if saved["AutoFarmDungeon"] ~= nil then _G.SlowHub.AutoFarmDungeon = saved["AutoFarmDungeon"] end
if saved["DungeonFarmDistance"] ~= nil then _G.SlowHub.DungeonFarmDistance = saved["DungeonFarmDistance"] end
if saved["DungeonFarmHeight"] ~= nil then _G.SlowHub.DungeonFarmHeight = saved["DungeonFarmHeight"] end
if saved["DungeonFarmCooldown"] ~= nil then _G.SlowHub.DungeonFarmCooldown = saved["DungeonFarmCooldown"] end
if saved["DungeonVoteDifficulty"] ~= nil then _G.SlowHub.DungeonVoteDifficulty = saved["DungeonVoteDifficulty"] end
if saved["VoteInterval"] ~= nil then _G.SlowHub.VoteInterval = saved["VoteInterval"] end
if saved["AutoVoteDungeon"] ~= nil then _G.SlowHub.AutoVoteDungeon = saved["AutoVoteDungeon"] end
if saved["ReplayInterval"] ~= nil then _G.SlowHub.ReplayInterval = saved["ReplayInterval"] end
if saved["AutoReplayDungeon"] ~= nil then _G.SlowHub.AutoReplayDungeon = saved["AutoReplayDungeon"] end

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
    NPCsFolder = nil,
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
        if not State.Character then return end
        if not State.Humanoid then return end
        if State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then State.Humanoid:EquipTool(weapon) end
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
    if currentTime - State.LastAttackTime < _G.SlowHub.DungeonFarmCooldown then return end
    State.LastAttackTime = currentTime
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then requestHit:FireServer() end
    end)
end

local function VoteDifficulty()
    if not _G.SlowHub.AutoVoteDungeon then return end
    if not _G.SlowHub.DungeonVoteDifficulty then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local dungeonWaveVote = remotes:FindFirstChild("DungeonWaveVote")
        if dungeonWaveVote then dungeonWaveVote:FireServer(_G.SlowHub.DungeonVoteDifficulty) end
    end)
end

local function VoteReplay()
    if not _G.SlowHub.AutoReplayDungeon then return end
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local dungeonWaveReplayVote = remotes:FindFirstChild("DungeonWaveReplayVote")
        if dungeonWaveReplayVote then dungeonWaveReplayVote:FireServer("sponsor") end
    end)
end

local function StopVoteLoop()
    State.IsVoting = false
    State.VoteConnection = nil
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
    State.ReplayConnection = nil
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

function StopDungeonFarm()
    if not State.IsFarming then return end
    State.IsFarming = false
    if State.FarmConnection then
        State.FarmConnection:Disconnect()
        State.FarmConnection = nil
    end
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
    if not State.Character or not State.Character.Parent then return end
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

function StartDungeonFarm()
    if State.IsFarming then
        StopDungeonFarm()
        task.wait(0.2)
    end
    InitializeState()
    State.IsFarming = true
    State.LastAttackTime = 0
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
end

local DungeonsTab = _G.DungeonsTab

DungeonsTab:CreateSection({ Title = "Dungeon Farm" })

DungeonsTab:CreateToggle({
    Name = "Auto Farm Dungeon or Boss Rush",
    Flag = "AutoFarmDungeon",
    CurrentValue = _G.SlowHub.AutoFarmDungeon,
    Callback = function(value)
        _G.SlowHub.AutoFarmDungeon = value
        saveConfig("AutoFarmDungeon", value)
        if value then
            StartDungeonFarm()
        else
            StopDungeonFarm()
        end
    end,
})

DungeonsTab:CreateSlider({
    Name = "Farm Distance",
    Flag = "DungeonFarmDistance",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.DungeonFarmDistance,
    Callback = function(value)
        _G.SlowHub.DungeonFarmDistance = value
        saveConfig("DungeonFarmDistance", value)
    end,
})

DungeonsTab:CreateSlider({
    Name = "Farm Height",
    Flag = "DungeonFarmHeight",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.DungeonFarmHeight,
    Callback = function(value)
        _G.SlowHub.DungeonFarmHeight = value
        saveConfig("DungeonFarmHeight", value)
    end,
})

DungeonsTab:CreateSlider({
    Name = "Attack Cooldown",
    Flag = "DungeonFarmCooldown",
    Range = { 0.05, 0.5 },
    Increment = 0.05,
    CurrentValue = _G.SlowHub.DungeonFarmCooldown,
    Callback = function(value)
        _G.SlowHub.DungeonFarmCooldown = value
        saveConfig("DungeonFarmCooldown", value)
    end,
})

DungeonsTab:CreateSection({ Title = "Voting" })

DungeonsTab:CreateDropdown({
    Name = "Select Difficulty",
    Flag = "DungeonVoteDifficulty",
    Options = { "Easy", "Medium", "Hard", "Extreme" },
    CurrentOption = _G.SlowHub.DungeonVoteDifficulty,
    MultipleOptions = false,
    Callback = function(option)
        _G.SlowHub.DungeonVoteDifficulty = option
        saveConfig("DungeonVoteDifficulty", option)
    end,
})

DungeonsTab:CreateSlider({
    Name = "Vote Interval",
    Flag = "VoteInterval",
    Range = { 1, 5 },
    Increment = 0.5,
    CurrentValue = _G.SlowHub.VoteInterval,
    Callback = function(value)
        _G.SlowHub.VoteInterval = value
        saveConfig("VoteInterval", value)
    end,
})

DungeonsTab:CreateToggle({
    Name = "Auto Vote Difficulty",
    Flag = "AutoVoteDungeon",
    CurrentValue = _G.SlowHub.AutoVoteDungeon,
    Callback = function(value)
        _G.SlowHub.AutoVoteDungeon = value
        saveConfig("AutoVoteDungeon", value)
        if value then
            StartVoteLoop()
        else
            StopVoteLoop()
        end
    end,
})

DungeonsTab:CreateSection({ Title = "Replay" })

DungeonsTab:CreateSlider({
    Name = "Replay Interval",
    Flag = "ReplayInterval",
    Range = { 3, 10 },
    Increment = 0.5,
    CurrentValue = _G.SlowHub.ReplayInterval,
    Callback = function(value)
        _G.SlowHub.ReplayInterval = value
        saveConfig("ReplayInterval", value)
    end,
})

DungeonsTab:CreateToggle({
    Name = "Auto Replay Dungeon or Boss Rush",
    Flag = "AutoReplayDungeon",
    CurrentValue = _G.SlowHub.AutoReplayDungeon,
    Callback = function(value)
        _G.SlowHub.AutoReplayDungeon = value
        saveConfig("AutoReplayDungeon", value)
        if value then
            StartReplayLoop()
        else
            StopReplayLoop()
        end
    end,
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoFarmDungeon then StartDungeonFarm() end
    if _G.SlowHub.AutoVoteDungeon then StartVoteLoop() end
    if _G.SlowHub.AutoReplayDungeon then StartReplayLoop() end
end)
