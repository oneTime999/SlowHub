local Tab = _G.RollsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local racesData = {
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

local rollConnection = nil
local isRolling = false
local lastRollTime = 0
local currentRace = nil

local function parseRaceText(text)
    if not text then return nil end
    local race = text:gsub("Race: ",""):gsub("Race:",""):match("^%s*(.-)%s*$")
    return race ~= "" and race or nil
end

local function getCurrentRace()
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
    if ok and raceText then return parseRaceText(raceText) end
    return nil
end

local function getRaceRarity(raceName)
    local data = racesData[raceName]
    return data and data.rarity or "Common"
end

local function isTargetRace(raceName)
    if not raceName then return false end
    if _G.SlowHub.StopOnMythical and getRaceRarity(raceName) == "Mythical" then return true end
    if _G.SlowHub.StopOnLegendary and getRaceRarity(raceName) == "Legendary" then return true end
    if _G.SlowHub.TargetRaces then
        for _, target in ipairs(_G.SlowHub.TargetRaces) do
            if target == raceName then return true end
        end
    end
    return false
end

local function fireRoll()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Race Reroll",1)
    end)
end

local function stopRolling()
    isRolling = false
    if rollConnection then
        rollConnection:Disconnect()
        rollConnection = nil
    end
    if _G.SlowHub.AutoRoll then
        _G.SlowHub.AutoRoll = false
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
end

local function startRolling()
    if isRolling then return end
    isRolling = true
    currentRace = getCurrentRace()
    lastRollTime = 0
    rollConnection = RunService.Heartbeat:Connect(function()
        if not isRolling then return end
        local currentTime = tick()
        if currentTime - lastRollTime < (_G.SlowHub.RollDelay or 0.35) then return end
        local currentRaceNow = getCurrentRace()
        if currentRaceNow and currentRaceNow ~= currentRace then
            currentRace = currentRaceNow
            if isTargetRace(currentRace) then stopRolling(); return end
        end
        fireRoll()
        lastRollTime = currentTime
    end)
end

local allRaces = {}
for raceName, data in pairs(racesData) do
    table.insert(allRaces, {name=raceName, rarity=data.rarity, order=data.order})
end
table.sort(allRaces, function(a,b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local raceOptions = {}
for _, info in ipairs(allRaces) do table.insert(raceOptions, info.name) end

Tab:Section({Title = "Auto Race Roll"})

Tab:Dropdown({
    Title = "Target Races",
    Flag = "TargetRaces",
    Values = raceOptions,
    Multi = true,
    Value = _G.SlowHub.TargetRaces or {},
    Callback = function(selectedOptions)
        _G.SlowHub.TargetRaces = selectedOptions or {}
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Mythical",
    Value = _G.SlowHub.StopOnMythical or true,
    Callback = function(Value)
        _G.SlowHub.StopOnMythical = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Legendary",
    Value = _G.SlowHub.StopOnLegendary or false,
    Callback = function(Value)
        _G.SlowHub.StopOnLegendary = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Roll Delay",
    Flag = "RollDelay",
    Step = 0.05,
    Value = {
        Min = 0.15,
        Max = 1.0,
        Default = _G.SlowHub.RollDelay or 0.35,
    },
    Callback = function(Value)
        _G.SlowHub.RollDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Roll",
    Value = _G.SlowHub.AutoRoll or false,
    Callback = function(Value)
        _G.SlowHub.AutoRoll = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startRolling()
        else
            stopRolling()
        end
    end,
})

if _G.SlowHub.AutoRoll then
    task.spawn(function() task.wait(2); startRolling() end)
end
