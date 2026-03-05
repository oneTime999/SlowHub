local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.RollsTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoRoll = _G.SlowHub.AutoRoll or false
_G.SlowHub.TargetRaces = _G.SlowHub.TargetRaces or {}
_G.SlowHub.RollDelay = _G.SlowHub.RollDelay or 0.35
_G.SlowHub.StopOnMythical = _G.SlowHub.StopOnMythical or true
_G.SlowHub.StopOnLegendary = _G.SlowHub.StopOnLegendary or false

local RollState = {
    IsRolling = false,
    Thread = nil,
    LastServerRace = nil
}

local RacesData = {
    ["Human"] = {rarity = "Common", order = 1},
    ["Fishman"] = {rarity = "Uncommon", order = 2},
    ["Skypea"] = {rarity = "Uncommon", order = 2},
    ["Mink"] = {rarity = "Rare", order = 3},
    ["Orc"] = {rarity = "Rare", order = 3},
    ["Vampire"] = {rarity = "Epic", order = 4},
    ["Demon"] = {rarity = "Epic", order = 4},
    ["Vessel"] = {rarity = "Legendary", order = 5},
    ["Limitless"] = {rarity = "Legendary", order = 5},
    ["Player"] = {rarity = "Legendary", order = 5},
    ["Shinigami"] = {rarity = "Legendary", order = 5},
    ["Shadowborn"] = {rarity = "Legendary", order = 5},
    ["Hollow"] = {rarity = "Legendary", order = 5},
    ["Oni"] = {rarity = "Mythical", order = 6},
    ["Kitsune"] = {rarity = "Mythical", order = 6},
    ["Leviathan"] = {rarity = "Mythical", order = 6},
    ["Slime"] = {rarity = "Mythical", order = 6},
    ["Servant"] = {rarity = "Mythical", order = 6},
    ["Sunborn"] = {rarity = "Mythical", order = 6}
}

local function GetRaceRarity(raceName)
    local data = RacesData[raceName]
    return data and data.rarity or "Common"
end

local function IsTargetRace(raceName)
    if not raceName then return false end

    if _G.SlowHub.StopOnMythical and GetRaceRarity(raceName) == "Mythical" then
        return true
    end

    if _G.SlowHub.StopOnLegendary and GetRaceRarity(raceName) == "Legendary" then
        return true
    end

    for _, target in ipairs(_G.SlowHub.TargetRaces) do
        if target == raceName then
            return true
        end
    end

    return false
end

local function FireRoll()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use", "Race Reroll", 1)
    end)
end

local function GetCurrentRace()
    local raceValue = nil

    pcall(function()
        local dataFolder = Player:FindFirstChild("Data") or Player:WaitForChild("Data", 1)
        if dataFolder then
            local raceObj = dataFolder:FindFirstChild("Race")
            if raceObj then
                raceValue = raceObj.Value
            end
        end
    end)

    if not raceValue then
        pcall(function()
            raceValue = Player:GetAttribute("Race")
        end)
    end

    return raceValue
end

local function StopRolling()
    RollState.IsRolling = false
    RollState.Thread = nil

    if _G.SlowHub.AutoRoll then
        _G.SlowHub.AutoRoll = false

        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
end

local function StartRolling()
    if RollState.IsRolling then return end

    RollState.IsRolling = true
    RollState.LastServerRace = GetCurrentRace()

    RollState.Thread = task.spawn(function()
        while RollState.IsRolling do
            local currentRace = GetCurrentRace()

            if currentRace and currentRace ~= RollState.LastServerRace then
                RollState.LastServerRace = currentRace

                if IsTargetRace(currentRace) then
                    StopRolling()
                    break
                end
            end

            FireRoll()
            task.wait(_G.SlowHub.RollDelay)
        end
    end)
end

local function OnToggleChange(value)
    _G.SlowHub.AutoRoll = value

    if value then
        StartRolling()
    else
        StopRolling()
    end

    if _G.SaveConfig then
        _G.SaveConfig()
    end
end

local AllRaces = {}
for raceName, data in pairs(RacesData) do
    table.insert(AllRaces, {
        name = raceName,
        rarity = data.rarity,
        order = data.order
    })
end

table.sort(AllRaces, function(a, b)
    if a.order ~= b.order then
        return a.order > b.order
    end
    return a.name < b.name
end)

Tab:CreateSection("Auto Race Roll")

local raceOptions = {}
for _, raceInfo in ipairs(AllRaces) do
    table.insert(raceOptions, raceInfo.name)
end

Tab:CreateDropdown({
    Name = "Target Races",
    Options = raceOptions,
    CurrentOption = _G.SlowHub.TargetRaces,
    MultipleOptions = true,
    Flag = "TargetRaces",
    Callback = function(selectedOptions)
        _G.SlowHub.TargetRaces = selectedOptions or {}

        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Stop on Mythical",
    CurrentValue = _G.SlowHub.StopOnMythical,
    Flag = "StopOnMythical",
    Callback = function(value)
        _G.SlowHub.StopOnMythical = value

        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Stop on Legendary",
    CurrentValue = _G.SlowHub.StopOnLegendary,
    Flag = "StopOnLegendary",
    Callback = function(value)
        _G.SlowHub.StopOnLegendary = value

        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSlider({
    Name = "Roll Delay",
    Range = {0.15, 1.0},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = _G.SlowHub.RollDelay,
    Flag = "RollDelay",
    Callback = function(value)
        _G.SlowHub.RollDelay = value

        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Roll",
    CurrentValue = _G.SlowHub.AutoRoll,
    Flag = "AutoRoll",
    Callback = OnToggleChange
})

if _G.SlowHub.AutoRoll then
    task.spawn(function()
        task.wait(2)
        StartRolling()
    end)
end
