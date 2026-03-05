local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoFarmLevel = _G.SlowHub.AutoFarmLevel or false
_G.SlowHub.FarmDistance = _G.SlowHub.FarmDistance or 8
_G.SlowHub.FarmHeight = _G.SlowHub.FarmHeight or 4
_G.SlowHub.FarmCooldown = _G.SlowHub.FarmCooldown or 0.15
_G.SlowHub.QuestInterval = _G.SlowHub.QuestInterval or 2
_G.SlowHub.IsAttackingBoss = false

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(current)) end)
end

local saved = loadConfig()
if saved["AutoFarmLevel"] ~= nil then _G.SlowHub.AutoFarmLevel = saved["AutoFarmLevel"] end
if saved["FarmDistance"] ~= nil then _G.SlowHub.FarmDistance = saved["FarmDistance"] end
if saved["FarmHeight"] ~= nil then _G.SlowHub.FarmHeight = saved["FarmHeight"] end
if saved["FarmCooldown"] ~= nil then _G.SlowHub.FarmCooldown = saved["FarmCooldown"] end
if saved["QuestInterval"] ~= nil then _G.SlowHub.QuestInterval = saved["QuestInterval"] end

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
    {minLevel = 9000, maxLevel = 99999, quest = "QuestNPC15", npc = "AcademyTeacher", count = 5},
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
    ["AcademyTeacher"] = CFrame.new(1072.5455322265625, 1.7783551216125488, 1275.641845703125),
}

local State = {
    FarmConnection = nil, QuestConnection = nil, IsFarming = false, IsQuesting = false,
    CurrentNPCIndex = 1, LastTargetName = nil, HasVisitedSafeZone = false,
    WasAttackingBoss = false, LastAttackTime = 0, LastNPCSwitch = 0,
    Character = nil, HumanoidRootPart = nil, Humanoid = nil, NPCsFolder = nil,
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
    if child.Name == "NPCs" then State.NPCsFolder = child end
end)

local function GetPlayerLevel()
    local ok, result = pcall(function()
        local data = Player:FindFirstChild("Data")
        if not data then return 1 end
        local levelValue = data:FindFirstChild("Level")
        if not levelValue then return 1 end
        return levelValue.Value
    end)
    return ok and result or 1
end

local function GetCurrentConfig()
    local level = GetPlayerLevel()
    for _, config in ipairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then return config end
    end
    return LevelConfig[1]
end

local function GetNextIndex(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
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
    return pcall(function()
        if not State.Character or not State.Humanoid then return end
        if State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then State.Humanoid:EquipTool(weapon) end
    end)
end

local function TeleportToSafeZone(npcName)
    if not State.HumanoidRootPart then return false end
    local safeCFrame = NPCSafeZones[npcName]
    if not safeCFrame then State.HasVisitedSafeZone = true; return true end
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
    if currentTime - State.LastAttackTime < _G.SlowHub.FarmCooldown then return end
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

local function AcceptQuest()
    if _G.SlowHub.IsAttackingBoss then return end
    pcall(function()
        local config = GetCurrentConfig()
        if not config then return end
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local questAccept = remoteEvents:FindFirstChild("QuestAccept")
        if questAccept then questAccept:FireServer(config.quest) end
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
    if not _G.SlowHub.AutoFarmLevel then StopAutoLevel(); return end
    if not State.Character or not State.Character.Parent then return end
    if not State.HumanoidRootPart then
        State.HumanoidRootPart = State.Character:FindFirstChild("HumanoidRootPart")
        if not State.HumanoidRootPart then return end
    end
    if not State.Humanoid then
        State.Humanoid = State.Character:FindFirstChildOfClass("Humanoid")
        if not State.Humanoid or State.Humanoid.Health <= 0 then return end
    end
    if _G.SlowHub.IsAttackingBoss then State.WasAttackingBoss = true; return end
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
        if TeleportToSafeZone(config.npc) then State.HasVisitedSafeZone = true end
        task.wait(0.1)
        return
    end
    local npc = GetNPC(config.npc, State.CurrentNPCIndex)
    local alive = IsNPCAlive(npc)
    if not alive then
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
    if State.IsFarming then StopAutoLevel(); task.wait(0.2) end
    InitializeState()
    if not State.NPCsFolder then return false end
    State.IsFarming = true
    _G.SlowHub.AutoFarmLevel = true
    ResetFarmState()
    StartQuestLoop()
    State.FarmConnection = RunService.Heartbeat:Connect(FarmLoop)
    return true
end

local MainTab = _G.MainTab

MainTab:CreateSection({ Title = "Auto Level" })

MainTab:CreateToggle({
    Name = "Auto Farm Level",
    Flag = "AutoFarmLevel",
    CurrentValue = _G.SlowHub.AutoFarmLevel,
    Callback = function(value)
        _G.SlowHub.AutoFarmLevel = value
        saveConfig("AutoFarmLevel", value)
        if value then
            StartAutoLevel()
        else
            StopAutoLevel()
        end
    end,
})

MainTab:CreateSection({ Title = "Farm Settings" })

MainTab:CreateSlider({
    Name = "Farm Distance",
    Flag = "FarmDistance",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmDistance,
    Callback = function(value)
        _G.SlowHub.FarmDistance = value
        saveConfig("FarmDistance", value)
    end,
})

MainTab:CreateSlider({
    Name = "Farm Height",
    Flag = "FarmHeight",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmHeight,
    Callback = function(value)
        _G.SlowHub.FarmHeight = value
        saveConfig("FarmHeight", value)
    end,
})

MainTab:CreateSlider({
    Name = "Attack Cooldown",
    Flag = "FarmCooldown",
    Range = { 0.05, 0.5 },
    Increment = 0.05,
    CurrentValue = _G.SlowHub.FarmCooldown,
    Callback = function(value)
        _G.SlowHub.FarmCooldown = value
        saveConfig("FarmCooldown", value)
    end,
})

MainTab:CreateSlider({
    Name = "Quest Interval",
    Flag = "QuestInterval",
    Range = { 1, 5 },
    Increment = 0.5,
    CurrentValue = _G.SlowHub.QuestInterval,
    Callback = function(value)
        _G.SlowHub.QuestInterval = value
        saveConfig("QuestInterval", value)
    end,
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    StartAutoLevel()
end
