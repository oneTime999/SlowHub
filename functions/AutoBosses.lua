local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
_G.SlowHub.PityTargetBoss = _G.SlowHub.PityTargetBoss or ""
_G.SlowHub.PriorityPityEnabled = _G.SlowHub.PriorityPityEnabled or false
_G.SlowHub.AutoFarmBosses = _G.SlowHub.AutoFarmBosses or false
_G.SlowHub.BossFarmDistance = _G.SlowHub.BossFarmDistance or 8
_G.SlowHub.BossFarmHeight = _G.SlowHub.BossFarmHeight or 5
_G.SlowHub.BossFarmCooldown = _G.SlowHub.BossFarmCooldown or 0.15
_G.SlowHub.IsAttackingBoss = false

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
if saved["SelectedBosses"] ~= nil then _G.SlowHub.SelectedBosses = saved["SelectedBosses"] end
if saved["PityTargetBoss"] ~= nil then _G.SlowHub.PityTargetBoss = saved["PityTargetBoss"] end
if saved["PriorityPityEnabled"] ~= nil then _G.SlowHub.PriorityPityEnabled = saved["PriorityPityEnabled"] end
if saved["AutoFarmBosses"] ~= nil then _G.SlowHub.AutoFarmBosses = saved["AutoFarmBosses"] end
if saved["BossFarmDistance"] ~= nil then _G.SlowHub.BossFarmDistance = saved["BossFarmDistance"] end
if saved["BossFarmHeight"] ~= nil then _G.SlowHub.BossFarmHeight = saved["BossFarmHeight"] end
if saved["BossFarmCooldown"] ~= nil then _G.SlowHub.BossFarmCooldown = saved["BossFarmCooldown"] end

local bossList = {
    "AnosBoss", "GilgameshBoss", "RimuruBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss",
    "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss",
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["AnosBoss"] = CFrame.new(950.0978393554688, -0.23529791831970215, 1378.4510498046875),
    ["GilgameshBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["RimuruBoss"] = CFrame.new(-1363.4713134765625, 30.04159164428711, 221.3505859375),
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30),
    ["IchigoBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["AizenBoss"] = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"] = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"] = CFrame.new(1537.92, 12.98, 226.10),
}

for _, bossBaseName in ipairs(bossList) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

local State = {
    Connection = nil,
    IsRunning = false,
    CurrentBoss = nil,
    LastTarget = nil,
    HasVisitedSafeZone = false,
    LastHitTime = 0,
    Character = nil,
    HumanoidRootPart = nil,
    NPCsFolder = nil,
}

local function InitializeState()
    State.Character = Player.Character
    State.HumanoidRootPart = State.Character and State.Character:FindFirstChild("HumanoidRootPart")
    State.NPCsFolder = workspace:FindFirstChild("NPCs")
end

InitializeState()

Player.CharacterAdded:Connect(function(char)
    State.Character = char
    State.HumanoidRootPart = nil
    task.wait(0.1)
    State.HumanoidRootPart = char:FindFirstChild("HumanoidRootPart")
end)

workspace.ChildAdded:Connect(function(child)
    if child.Name == "NPCs" then
        State.NPCsFolder = child
    end
end)

local function GetHumanoid(model)
    if not model or not model.Parent then return nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then return humanoid end
    return nil
end

local function IsAlive(model)
    return GetHumanoid(model) ~= nil
end

local function GetBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName then return baseName end
        if string.sub(bossName, 1, #baseName) == baseName then return baseName end
    end
    return nil
end

local function IsBossSelected(bossName)
    local baseName = GetBossBaseName(bossName)
    if not baseName then return false end
    return _G.SlowHub.SelectedBosses[baseName] == true
end

local function GetSafeZone(bossName)
    local direct = BossSafeZones[bossName]
    if direct then return direct end
    local baseName = GetBossBaseName(bossName)
    if baseName then return BossSafeZones[baseName] end
    return nil
end

local function GetPityCount()
    local success, result = pcall(function()
        local playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return nil end
        local bossUI = playerGui:FindFirstChild("BossUI")
        if not bossUI then return nil end
        local mainFrame = bossUI:FindFirstChild("MainFrame")
        if not mainFrame then return nil end
        local bossHPBar = mainFrame:FindFirstChild("BossHPBar")
        if not bossHPBar then return nil end
        local pityLabel = bossHPBar:FindFirstChild("Pity")
        if not pityLabel then return nil end
        return pityLabel.Text
    end)
    if success and result then
        local currentPity = string.match(result, "Pity: (%d+)/25")
        if currentPity then return tonumber(currentPity) end
    end
    return 0
end

local function IsPityTargetTime()
    if not _G.SlowHub.PriorityPityEnabled then return false end
    if _G.SlowHub.PityTargetBoss == "" then return false end
    return GetPityCount() >= 24
end

local function ShouldSwitchBoss(currentBoss)
    if not currentBoss or not currentBoss.Parent then return true end
    if not IsAlive(currentBoss) then return true end
    local bossBaseName = GetBossBaseName(currentBoss.Name)
    if not bossBaseName then return true end
    if not IsBossSelected(bossBaseName) then return true end
    if _G.SlowHub.PriorityPityEnabled and _G.SlowHub.PityTargetBoss ~= "" then
        local isPityTime = IsPityTargetTime()
        local pityTarget = _G.SlowHub.PityTargetBoss
        if isPityTime then
            if bossBaseName ~= pityTarget then return true end
        else
            if bossBaseName == pityTarget then return true end
        end
    end
    return false
end

local function FindBossByName(bossName)
    if not State.NPCsFolder then return nil end
    local exactMatch = State.NPCsFolder:FindFirstChild(bossName)
    if exactMatch and IsAlive(exactMatch) then return exactMatch end
    for _, diff in ipairs(difficulties) do
        local variant = State.NPCsFolder:FindFirstChild(bossName .. diff)
        if variant and IsAlive(variant) then return variant end
    end
    return nil
end

local function FindValidBoss()
    if not State.NPCsFolder then return nil end
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    if pityEnabled and pityTarget ~= "" then
        if IsPityTargetTime() then
            if IsBossSelected(pityTarget) then return FindBossByName(pityTarget) end
            return nil
        else
            for _, bossName in ipairs(bossList) do
                if bossName ~= pityTarget and IsBossSelected(bossName) then
                    local found = FindBossByName(bossName)
                    if found then return found end
                end
            end
            return nil
        end
    end
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local found = FindBossByName(bossName)
            if found then return found end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        if not State.Character then return end
        local humanoid = State.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        if State.Character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return end
        local backpack = Player:FindFirstChild("Backpack")
        if not backpack then return end
        local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
        if weapon then humanoid:EquipTool(weapon) end
    end)
end

local function TeleportToSafeZone(boss)
    if not State.HumanoidRootPart then return false end
    local safeCFrame = GetSafeZone(boss.Name)
    if not safeCFrame then return true end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    State.HumanoidRootPart.CFrame = safeCFrame
    return true
end

local function TeleportToBoss(boss)
    if not State.HumanoidRootPart then return false end
    local bossRoot = boss:FindFirstChild("HumanoidRootPart")
    if not bossRoot then return false end
    State.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
    local offset = CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
    State.HumanoidRootPart.CFrame = bossRoot.CFrame * offset
    return true
end

local function PerformAttack()
    local currentTime = tick()
    if currentTime - State.LastHitTime < _G.SlowHub.BossFarmCooldown then return end
    State.LastHitTime = currentTime
    pcall(function()
        local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
        if not combatSystem then return end
        local remotes = combatSystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestHit = remotes:FindFirstChild("RequestHit")
        if requestHit then requestHit:FireServer() end
    end)
end

local function ResetState()
    State.CurrentBoss = nil
    State.LastTarget = nil
    State.HasVisitedSafeZone = false
    _G.SlowHub.IsAttackingBoss = false
end

function StopAutoFarm()
    if not State.IsRunning then return end
    State.IsRunning = false
    if State.Connection then
        State.Connection:Disconnect()
        State.Connection = nil
    end
    ResetState()
end

local function FarmLoop()
    if not _G.SlowHub.AutoFarmBosses or not State.IsRunning then
        StopAutoFarm()
        return
    end
    if not State.Character or not State.Character.Parent then return end
    if not State.HumanoidRootPart then
        State.HumanoidRootPart = State.Character:FindFirstChild("HumanoidRootPart")
        if not State.HumanoidRootPart then return end
    end
    if State.CurrentBoss and ShouldSwitchBoss(State.CurrentBoss) then
        ResetState()
        task.wait(0.1)
        return
    end
    if not State.CurrentBoss then
        State.CurrentBoss = FindValidBoss()
        if not State.CurrentBoss then
            _G.SlowHub.IsAttackingBoss = false
            return
        end
        State.HasVisitedSafeZone = false
        State.LastTarget = State.CurrentBoss
    end
    local boss = State.CurrentBoss
    _G.SlowHub.IsAttackingBoss = true
    if boss ~= State.LastTarget then
        State.LastTarget = boss
        State.HasVisitedSafeZone = false
    end
    if not State.HasVisitedSafeZone then
        local success = TeleportToSafeZone(boss)
        if success then State.HasVisitedSafeZone = true end
        task.wait(0.1)
        return
    end
    local success = TeleportToBoss(boss)
    if success then
        EquipWeapon()
        PerformAttack()
    end
end

function StartAutoFarm()
    if State.IsRunning then
        StopAutoFarm()
        task.wait(0.2)
    end
    InitializeState()
    if not State.NPCsFolder then return false end
    State.IsRunning = true
    State.Connection = RunService.Heartbeat:Connect(FarmLoop)
    return true
end

local BossesTab = _G.BossesTab

BossesTab:CreateSection({ Title = "Boss Selection" })

BossesTab:CreateDropdown({
    Name = "Select Bosses to Farm",
    Flag = "SelectedBosses",
    Options = bossList,
    CurrentOption = (function()
        local selected = {}
        for _, name in ipairs(bossList) do
            if _G.SlowHub.SelectedBosses[name] then
                table.insert(selected, name)
            end
        end
        return selected
    end)(),
    MultipleOptions = true,
    Callback = function(options)
        local map = {}
        for _, v in ipairs(options) do
            map[v] = true
        end
        _G.SlowHub.SelectedBosses = map
        saveConfig("SelectedBosses", map)
    end,
})

BossesTab:CreateSection({ Title = "Pity System (Optional)" })

BossesTab:CreateDropdown({
    Name = "Pity Target Boss",
    Flag = "PityTargetBoss",
    Options = bossList,
    CurrentOption = _G.SlowHub.PityTargetBoss ~= "" and _G.SlowHub.PityTargetBoss or bossList[1],
    MultipleOptions = false,
    Callback = function(option)
        _G.SlowHub.PityTargetBoss = option
        saveConfig("PityTargetBoss", option)
        if _G.SlowHub.AutoFarmBosses and State.IsRunning then
            ResetState()
        end
    end,
})

BossesTab:CreateToggle({
    Name = "Enable Pity System",
    Flag = "PriorityPityEnabled",
    CurrentValue = _G.SlowHub.PriorityPityEnabled,
    Callback = function(value)
        _G.SlowHub.PriorityPityEnabled = value
        saveConfig("PriorityPityEnabled", value)
        if _G.SlowHub.AutoFarmBosses and State.IsRunning then
            ResetState()
        end
    end,
})

BossesTab:CreateSection({ Title = "Farm Control" })

BossesTab:CreateToggle({
    Name = "Auto Farm Selected Bosses",
    Flag = "AutoFarmBosses",
    CurrentValue = _G.SlowHub.AutoFarmBosses,
    Callback = function(value)
        _G.SlowHub.AutoFarmBosses = value
        saveConfig("AutoFarmBosses", value)
        if value then
            StartAutoFarm()
        else
            StopAutoFarm()
        end
    end,
})

BossesTab:CreateSlider({
    Name = "Boss Farm Distance",
    Flag = "BossFarmDistance",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Callback = function(value)
        _G.SlowHub.BossFarmDistance = value
        saveConfig("BossFarmDistance", value)
    end,
})

BossesTab:CreateSlider({
    Name = "Boss Farm Height",
    Flag = "BossFarmHeight",
    Range = { 1, 10 },
    Increment = 1,
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Callback = function(value)
        _G.SlowHub.BossFarmHeight = value
        saveConfig("BossFarmHeight", value)
    end,
})

BossesTab:CreateSlider({
    Name = "Attack Cooldown",
    Flag = "BossFarmCooldown",
    Range = { 0.05, 0.5 },
    Increment = 0.05,
    CurrentValue = _G.SlowHub.BossFarmCooldown,
    Callback = function(value)
        _G.SlowHub.BossFarmCooldown = value
        saveConfig("BossFarmCooldown", value)
    end,
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoFarmBosses then
        StartAutoFarm()
    end
end)
