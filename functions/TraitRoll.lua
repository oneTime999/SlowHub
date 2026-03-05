local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoTraitRoll = _G.SlowHub.AutoTraitRoll or false
_G.SlowHub.TargetTraits = _G.SlowHub.TargetTraits or {}
_G.SlowHub.TraitRollDelay = _G.SlowHub.TraitRollDelay or 0.35
_G.SlowHub.StopOnSecret = _G.SlowHub.StopOnSecret or true
_G.SlowHub.StopOnMythicalTrait = _G.SlowHub.StopOnMythicalTrait or true
_G.SlowHub.StopOnLegendaryTrait = _G.SlowHub.StopOnLegendaryTrait or false
_G.SlowHub.StopOnEpicTrait = _G.SlowHub.StopOnEpicTrait or false

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
local traitFlags = {"AutoTraitRoll","TargetTraits","TraitRollDelay","StopOnSecret","StopOnMythicalTrait","StopOnLegendaryTrait","StopOnEpicTrait"}
for _, flag in ipairs(traitFlags) do
    if saved[flag] ~= nil then _G.SlowHub[flag] = saved[flag] end
end

local TraitsData = {
    ["Celestial"]={rarity="Secret",order=7},["Singularity"]={rarity="Secret",order=7},
    ["Overlord"]={rarity="Secret",order=7},["Cataclysm"]={rarity="Secret",order=7},
    ["Malevolent"]={rarity="Mythical",order=6},["Infinity"]={rarity="Mythical",order=6},
    ["Godspeed"]={rarity="Mythical",order=6},["Sovereign"]={rarity="Mythical",order=6},
    ["Transcendent"]={rarity="Mythical",order=6},["Unstoppable"]={rarity="Legendary",order=5},
    ["Dominator"]={rarity="Legendary",order=5},["Genesis"]={rarity="Legendary",order=5},
    ["Ascended"]={rarity="Epic",order=4},["Overdrive"]={rarity="Epic",order=4},
    ["Breaker"]={rarity="Epic",order=4},["Predator"]={rarity="Rare",order=3},
    ["Vicious"]={rarity="Rare",order=3},["Sharpened"]={rarity="Rare",order=3},
    ["Balanced"]={rarity="Uncommon",order=2},["Steady"]={rarity="Uncommon",order=2},
    ["Driven"]={rarity="Uncommon",order=2},["Strong"]={rarity="Common",order=1},
    ["Tough"]={rarity="Common",order=1},["Agile"]={rarity="Common",order=1},
}

local TraitRollState = {IsRolling=false, Connection=nil, LastRollTime=0, CurrentTrait=nil}

local function ParseTraitText(text)
    if not text then return nil end
    local trait = text:gsub("Trait: ",""):gsub("Trait:",""):match("^%s*(.-)%s*$")
    return trait ~= "" and trait or nil
end

local function GetCurrentTrait()
    local ok, traitText = pcall(function()
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
        local traitEquipped = userStats:FindFirstChild("TraitEquipped")
        if not traitEquipped then return nil end
        local statName = traitEquipped:FindFirstChild("StatName")
        if not statName then return nil end
        return statName.Text
    end)
    if ok and traitText then return ParseTraitText(traitText) end
    return nil
end

local function GetTraitRarity(traitName)
    local data = TraitsData[traitName]
    return data and data.rarity or "Common"
end

local function IsTargetTrait(traitName)
    if not traitName then return false end
    if _G.SlowHub.StopOnSecret and GetTraitRarity(traitName) == "Secret" then return true end
    if _G.SlowHub.StopOnMythicalTrait and GetTraitRarity(traitName) == "Mythical" then return true end
    if _G.SlowHub.StopOnLegendaryTrait and GetTraitRarity(traitName) == "Legendary" then return true end
    if _G.SlowHub.StopOnEpicTrait and GetTraitRarity(traitName) == "Epic" then return true end
    for _, target in ipairs(_G.SlowHub.TargetTraits) do
        if target == traitName then return true end
    end
    return false
end

local function FireTraitRoll()
    pcall(function() ReplicatedStorage.RemoteEvents.TraitReroll:FireServer() end)
end

local function StopTraitRolling()
    TraitRollState.IsRolling = false
    if TraitRollState.Connection then
        TraitRollState.Connection:Disconnect()
        TraitRollState.Connection = nil
    end
    if _G.SlowHub.AutoTraitRoll then
        _G.SlowHub.AutoTraitRoll = false
        saveConfig("AutoTraitRoll", false)
    end
end

local function StartTraitRolling()
    if TraitRollState.IsRolling then return end
    TraitRollState.IsRolling = true
    TraitRollState.CurrentTrait = GetCurrentTrait()
    TraitRollState.LastRollTime = 0
    TraitRollState.Connection = RunService.Heartbeat:Connect(function()
        if not TraitRollState.IsRolling then return end
        local currentTime = tick()
        if currentTime - TraitRollState.LastRollTime < _G.SlowHub.TraitRollDelay then return end
        local currentTrait = GetCurrentTrait()
        if currentTrait and currentTrait ~= TraitRollState.CurrentTrait then
            TraitRollState.CurrentTrait = currentTrait
            if IsTargetTrait(currentTrait) then StopTraitRolling(); return end
        end
        FireTraitRoll()
        TraitRollState.LastRollTime = currentTime
    end)
end

local AllTraits = {}
for traitName, data in pairs(TraitsData) do
    table.insert(AllTraits, {name=traitName, rarity=data.rarity, order=data.order})
end
table.sort(AllTraits, function(a,b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local traitOptions = {}
for _, info in ipairs(AllTraits) do table.insert(traitOptions, info.name) end

local RollsTab = _G.RollsTab

RollsTab:CreateSection({ Title = "Auto Trait Roll" })

RollsTab:CreateDropdown({
    Name = "Target Traits", Flag = "TargetTraits",
    Options = traitOptions, CurrentOption = _G.SlowHub.TargetTraits, MultipleOptions = true,
    Callback = function(selectedOptions)
        _G.SlowHub.TargetTraits = selectedOptions or {}
        saveConfig("TargetTraits", _G.SlowHub.TargetTraits)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Secret", Flag = "StopOnSecret",
    CurrentValue = _G.SlowHub.StopOnSecret,
    Callback = function(value)
        _G.SlowHub.StopOnSecret = value
        saveConfig("StopOnSecret", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Mythical", Flag = "StopOnMythicalTrait",
    CurrentValue = _G.SlowHub.StopOnMythicalTrait,
    Callback = function(value)
        _G.SlowHub.StopOnMythicalTrait = value
        saveConfig("StopOnMythicalTrait", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Legendary", Flag = "StopOnLegendaryTrait",
    CurrentValue = _G.SlowHub.StopOnLegendaryTrait,
    Callback = function(value)
        _G.SlowHub.StopOnLegendaryTrait = value
        saveConfig("StopOnLegendaryTrait", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Stop on Epic", Flag = "StopOnEpicTrait",
    CurrentValue = _G.SlowHub.StopOnEpicTrait,
    Callback = function(value)
        _G.SlowHub.StopOnEpicTrait = value
        saveConfig("StopOnEpicTrait", value)
    end,
})

RollsTab:CreateSlider({
    Name = "Trait Roll Delay", Flag = "TraitRollDelay",
    Range = { 0.15, 1.0 }, Increment = 0.05,
    CurrentValue = _G.SlowHub.TraitRollDelay,
    Callback = function(value)
        _G.SlowHub.TraitRollDelay = value
        saveConfig("TraitRollDelay", value)
    end,
})

RollsTab:CreateToggle({
    Name = "Auto Trait Roll", Flag = "AutoTraitRoll",
    CurrentValue = _G.SlowHub.AutoTraitRoll,
    Callback = function(value)
        _G.SlowHub.AutoTraitRoll = value
        saveConfig("AutoTraitRoll", value)
        if value then StartTraitRolling() else StopTraitRolling() end
    end,
})

if _G.SlowHub.AutoTraitRoll then
    task.spawn(function() task.wait(2); StartTraitRolling() end)
end
