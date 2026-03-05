local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoRoll = _G.SlowHub.AutoRoll or false
_G.SlowHub.TargetRaces = _G.SlowHub.TargetRaces or {}
_G.SlowHub.RollDelay = _G.SlowHub.RollDelay or 0.35
_G.SlowHub.StopOnMythical = _G.SlowHub.StopOnMythical or true
_G.SlowHub.StopOnLegendary = _G.SlowHub.StopOnLegendary or false

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
local raceFlags = {"AutoRoll","TargetRaces","RollDelay","StopOnMythical","StopOnLegendary"}
for _, flag in ipairs(raceFlags) do
    if saved[flag] ~= nil then _G.SlowHub[flag] = saved[flag] end
end

local RacesData = {
    ["Human"]={rarity="Common",order=1},["Fishman"]={rarity="Uncommon",order=2},
    ["Skypea"]={rarity="Uncommon",order=2},["Mink"]={rarity="Rare",order=3},
    ["Orc"]={rarity="Rare",order=3},["Vampire"]={rarity="Epic",order=4},
    ["Demon"]={rarity="Epic",order=4},["Vessel"]={rarity="Legendary",order=5},
    ["Limitless"]={rarity="Legendary",order=5},["Player"]={rarity="Legendary",order=5},
    ["Shinigami"]={rarity="Legendary",order=5},["Shadowborn"]={rarity="Legendary",order=5},
    ["Hollow"]={rarity="Legendary",order=5},["Oni"]={rarity="Mythical",order=6},
    ["Kitsune"]={rarity="Mythical",order=6},["Leviathan"]={rarity="Mythical",order=6},
    ["Slime"]={rarity="Mythical",order=6},["Servant"]={rarity="Mythical",order=6},
    ["Sunborn"]={rarity="Mythical",order=6},
}

local RollState = {IsRolling=false, Connection=nil, LastRollTime=0, CurrentRace=nil}

local function ParseRaceText(text)
    if not text then return nil end
    local race = text:gsub("Race: ",""):gsub("Race:",""):match("^%s*(.-)%s*$")
    return race ~= "" and race or nil
end

local function GetCurrentRace()
    local ok, raceText = pcall(function()
        local playerGui = Player:WaitForChild("PlayerGui", 5)
        if not playerGui then return nil end
        local statsPanel = playerGui:FindFirstChild("StatsPanelUI")
        if not statsPanel then return nil end
        local mainFrame = statsPanel:FindFirstChild("MainFrame")
        if not mainFrame then return nil end
        local frame = mainFrame:FindFirstChild("Frame")
        if not frame then return nil end
        local content = frame:FindFirstChild("Content")
        if not content then return nil end
        local sideFrame = content:FindFirstChild("SideFrame")
        if not sideFrame then return nil end
        local userStats = sideFrame:FindFirstChild("UserStats")
        if not userStats then return nil end
        local raceEquipped = userStats:FindFirstChild("RaceEquipped")
        if not raceEquipped then return nil end
        local statName = raceEquipped:FindFirstChild("StatName")
        if not statName then return nil end
        return statName.Text
    end)
    if ok and raceText then return ParseRaceText(raceText) end
    return nil
end

local function GetRaceRarity(raceName)
    local data = RacesData[raceName]
    return data and data.rarity or "Common"
end

local function IsTargetRace(raceName)
    if not raceName then return false end
    if _G.SlowHub.StopOnMythical and GetRaceRarity(raceName) == "Mythical" then return true end
    if _G.SlowHub.StopOnLegendary and GetRaceRarity(raceName) == "Legendary" then return true end
    for _, target in ipairs(_G.SlowHub.TargetRaces) do
        if target == raceName then return true end
    end
    return false
end

local function FireRoll()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Race Reroll",1)
    end)
end

local function StopRolling()
    RollState.IsRolling = false
    if RollState.Connection then RollState.Connection:Disconnect(); RollState.Connection = nil end
    if _G.SlowHub.AutoRoll then
        _G.SlowHub.AutoRoll = false
        saveConfig("AutoRoll", false)
    end
end

local function StartRolling()
    if RollState.IsRolling then return end
    RollState.IsRolling = true
    RollState.CurrentRace = GetCurrentRace()
    RollState.LastRollTime = 0
    RollState.Connection = RunService.Heartbeat:Connect(function()
        if not RollState.IsRolling then return end
        local currentTime = tick()
        if currentTime - RollState.LastRollTime < _G.SlowHub.RollDelay then return end
        local currentRace = GetCurrentRace()
        if currentRace and currentRace ~= RollState.CurrentRace then
            RollState.CurrentRace = currentRace
            if IsTargetRace(currentRace) then StopRolling(); return end
        end
        FireRoll()
        RollState.LastRollTime = currentTime
    end)
end

local AllRaces = {}
for raceName, data in pairs(RacesData) do
    table.insert(AllRaces, {name=raceName, rarity=data.rarity, order=data.order})
end
table.sort(AllRaces, function(a,b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local raceOptions = {}
for _, info in ipairs(AllRaces) do table.insert(raceOptions, info.name) end

local RollsTab = _G.RollsTab

RollsTab:CreateSection({ Title = "Auto Race Roll" })

RollsTab:CreateDropdown({
    Name = "Target Races", Flag = "TargetRaces",
    Options = raceOptions, CurrentOption = _G.SlowHub.TargetRaces, MultipleOptions = true,
    Callback = function(selectedOptions)
        _G.SlowHub.TargetRaces = selectedOptions or {}
        saveConfig("TargetRaces", _G.SlowHub.TargetRaces)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Mythical", Flag = "StopOnMythical",
    CurrentValue = _G.SlowHub.StopOnMythical,
    Callback = function(value)
        _G.SlowHub.StopOnMythical = value
        saveConfig("StopOnMythical", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Legendary", Flag = "StopOnLegendary",
    CurrentValue = _G.SlowHub.StopOnLegendary,
    Callback = function(value)
        _G.SlowHub.StopOnLegendary = value
        saveConfig("StopOnLegendary", value)
    end,
})

RollsTab:CreateSlider({
    Name = "Roll Delay", Flag = "RollDelay",
    Range = { 0.15, 1.0 }, Increment = 0.05,
    CurrentValue = _G.SlowHub.RollDelay,
    Callback = function(value)
        _G.SlowHub.RollDelay = value
        saveConfig("RollDelay", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Auto Roll", Flag = "AutoRoll",
    CurrentValue = _G.SlowHub.AutoRoll,
    Callback = function(value)
        _G.SlowHub.AutoRoll = value
        saveConfig("AutoRoll", value)
        if value then StartRolling() else StopRolling() end
    end,
})

if _G.SlowHub.AutoRoll then
    task.spawn(function() task.wait(2); StartRolling() end)
end
