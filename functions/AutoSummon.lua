local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoSummonBoss = false
_G.SlowHub.SummonInterval = _G.SlowHub.SummonInterval or 0.5

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
if saved["SummonInterval"] ~= nil then _G.SlowHub.SummonInterval = saved["SummonInterval"] end

local BossConfigs = {
    ["Anos"] = {Method="AnosSpecific", InternalName="Anos"},
    ["RimuruBoss"] = {Method="RimuruSpecific", InternalName="Rimuru"},
    ["GilgameshBoss"] = {Method="Gilgamesh", InternalName="GilgameshBoss"},
    ["StrongestofTodayBoss"] = {Method="New", InternalName="StrongestToday"},
    ["StrongestinHistoryBoss"] = {Method="New", InternalName="StrongestHistory"},
    ["IchigoBoss"] = {Method="Old", InternalName="IchigoBoss"},
    ["QinShiBoss"] = {Method="Old", InternalName="QinShiBoss"},
    ["SaberBoss"] = {Method="Old", InternalName="SaberBoss"},
}

local BossList = {}
for name in pairs(BossConfigs) do table.insert(BossList, name) end
table.sort(BossList)

local DifficultyList = {"Normal","Medium","Hard","Extreme"}

local SummonState = {
    Connection = nil, IsSummoning = false,
    SelectedBosses = {}, SelectedDifficulty = "Normal",
}

local function IsBossAlive(bossName)
    local found = false
    pcall(function()
        if not workspace:FindFirstChild("NPCs") then return end
        local boss = workspace.NPCs:FindFirstChild(bossName)
        if not boss then return end
        local humanoid = boss:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 then found = true end
    end)
    return found
end

local function IsPitySystemEnabled()
    return _G.SlowHub and _G.SlowHub.PriorityPityEnabled == true
end

local function GetPityTargetBoss()
    return _G.SlowHub and _G.SlowHub.PityTargetBoss or ""
end

local function IsPityTargetTime()
    if _G.SlowHub and _G.SlowHub.IsPityTargetTime then
        return _G.SlowHub.IsPityTargetTime()
    end
    return false
end

local function GetFilteredBossesToSummon()
    local bossesToSummon = {}
    local pityEnabled = IsPitySystemEnabled()
    local pityTargetTime = IsPityTargetTime()
    local pityTarget = GetPityTargetBoss()
    for _, selectedBoss in ipairs(SummonState.SelectedBosses) do
        if not BossConfigs[selectedBoss] then continue end
        if pityEnabled then
            if selectedBoss == pityTarget then
                if pityTargetTime then table.insert(bossesToSummon, selectedBoss) end
            else
                if not pityTargetTime then table.insert(bossesToSummon, selectedBoss) end
            end
        else
            table.insert(bossesToSummon, selectedBoss)
        end
    end
    return bossesToSummon
end

local function SummonBoss(currentBossName, config)
    pcall(function()
        if config.Method == "RimuruSpecific" then
            local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remoteEvents and remoteEvents:FindFirstChild("RequestSpawnRimuru") then
                remoteEvents.RequestSpawnRimuru:FireServer(SummonState.SelectedDifficulty)
            elseif remotes and remotes:FindFirstChild("RequestSpawnRimuru") then
                remotes.RequestSpawnRimuru:FireServer(SummonState.SelectedDifficulty)
            end
        elseif config.Method == "Gilgamesh" then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(config.InternalName, SummonState.SelectedDifficulty)
            end
        elseif config.Method == "New" then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSpawnStrongestBoss") then
                remotes.RequestSpawnStrongestBoss:FireServer(config.InternalName, SummonState.SelectedDifficulty)
            end
        elseif config.Method == "AnosSpecific" then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSpawnAnosBoss") then
                remotes.RequestSpawnAnosBoss:FireServer(config.InternalName, SummonState.SelectedDifficulty)
            end
        else
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("RequestSummonBoss") then
                remotes.RequestSummonBoss:FireServer(currentBossName)
            end
        end
    end)
end

local function ProcessBossSummon(currentBossName)
    local config = BossConfigs[currentBossName]
    if not config then return end
    local namesToCheck = {}
    if config.Method == "New" or config.Method == "RimuruSpecific" or config.Method == "Gilgamesh" or config.Method == "AnosSpecific" then
        table.insert(namesToCheck, config.InternalName .. "_" .. SummonState.SelectedDifficulty)
        table.insert(namesToCheck, currentBossName .. "_" .. SummonState.SelectedDifficulty)
    else
        table.insert(namesToCheck, currentBossName)
        table.insert(namesToCheck, config.InternalName)
    end
    for _, name in ipairs(namesToCheck) do
        if IsBossAlive(name) then return end
    end
    SummonBoss(currentBossName, config)
end

function StopAutoSummonBoss()
    SummonState.IsSummoning = false
    if SummonState.Connection then
        SummonState.Connection:Disconnect()
        SummonState.Connection = nil
    end
    _G.SlowHub.AutoSummonBoss = false
end

function StartAutoSummonBoss()
    if SummonState.IsSummoning then StopAutoSummonBoss(); task.wait(0.2) end
    SummonState.IsSummoning = true
    _G.SlowHub.AutoSummonBoss = true
    SummonState.Connection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoSummonBoss then StopAutoSummonBoss(); return end
        local bossesToSummon = GetFilteredBossesToSummon()
        for _, bossName in ipairs(bossesToSummon) do
            ProcessBossSummon(bossName)
        end
        task.wait(_G.SlowHub.SummonInterval)
    end)
end

local BossesTab = _G.BossesTab

BossesTab:CreateSection({ Title = "Summon Settings" })

BossesTab:CreateDropdown({
    Name = "Select Bosses to Summon",
    Flag = "SelectBossSummon",
    Options = BossList,
    CurrentOption = {},
    MultipleOptions = true,
    Callback = function(value)
        SummonState.SelectedBosses = {}
        if type(value) == "table" then
            for _, boss in ipairs(value) do table.insert(SummonState.SelectedBosses, boss) end
        end
        saveConfig("SelectBossSummon", SummonState.SelectedBosses)
    end,
})

BossesTab:CreateDropdown({
    Name = "Select Difficulty",
    Flag = "SelectBossDifficulty",
    Options = DifficultyList,
    CurrentOption = "Normal",
    MultipleOptions = false,
    Callback = function(value)
        SummonState.SelectedDifficulty = type(value) == "table" and value[1] or value
        saveConfig("SelectBossDifficulty", SummonState.SelectedDifficulty)
    end,
})

BossesTab:CreateSlider({
    Name = "Summon Interval",
    Flag = "SummonInterval",
    Range = { 0.1, 2 },
    Increment = 0.1,
    CurrentValue = _G.SlowHub.SummonInterval,
    Callback = function(value)
        _G.SlowHub.SummonInterval = value
        saveConfig("SummonInterval", value)
    end,
})

BossesTab:CreateToggle({
    Name = "Auto Summon Boss",
    Flag = "AutoSummonBoss",
    CurrentValue = false,
    Callback = function(value)
        _G.SlowHub.AutoSummonBoss = value
        if value then
            StartAutoSummonBoss()
        else
            StopAutoSummonBoss()
        end
    end,
})
