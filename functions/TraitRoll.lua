local Tab = _G.RollsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local traitsData = {
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

local rollConnection = nil
local isRolling = false
local lastRollTime = 0
local currentTrait = nil

local function parseTraitText(text)
    if not text then return nil end
    local trait = text:gsub("Trait: ",""):gsub("Trait:",""):match("^%s*(.-)%s*$")
    return trait ~= "" and trait or nil
end

local function getCurrentTrait()
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
    if ok and traitText then return parseTraitText(traitText) end
    return nil
end

local function getTraitRarity(traitName)
    local data = traitsData[traitName]
    return data and data.rarity or "Common"
end

local function isTargetTrait(traitName)
    if not traitName then return false end
    if _G.SlowHub.StopOnSecret and getTraitRarity(traitName) == "Secret" then return true end
    if _G.SlowHub.StopOnMythicalTrait and getTraitRarity(traitName) == "Mythical" then return true end
    if _G.SlowHub.StopOnLegendaryTrait and getTraitRarity(traitName) == "Legendary" then return true end
    if _G.SlowHub.StopOnEpicTrait and getTraitRarity(traitName) == "Epic" then return true end
    if _G.SlowHub.TargetTraits then
        for _, target in ipairs(_G.SlowHub.TargetTraits) do
            if target == traitName then return true end
        end
    end
    return false
end

local function fireTraitRoll()
    pcall(function() ReplicatedStorage.RemoteEvents.TraitReroll:FireServer() end)
end

local function stopTraitRolling()
    isRolling = false
    if rollConnection then
        rollConnection:Disconnect()
        rollConnection = nil
    end
    if _G.SlowHub.AutoTraitRoll then
        _G.SlowHub.AutoTraitRoll = false
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
end

local function startTraitRolling()
    if isRolling then return end
    isRolling = true
    currentTrait = getCurrentTrait()
    lastRollTime = 0
    rollConnection = RunService.Heartbeat:Connect(function()
        if not isRolling then return end
        local currentTime = tick()
        if currentTime - lastRollTime < (_G.SlowHub.TraitRollDelay or 0.35) then return end
        local currentTraitNow = getCurrentTrait()
        if currentTraitNow and currentTraitNow ~= currentTrait then
            currentTrait = currentTraitNow
            if isTargetTrait(currentTrait) then stopTraitRolling(); return end
        end
        fireTraitRoll()
        lastRollTime = currentTime
    end)
end

local allTraits = {}
for traitName, data in pairs(traitsData) do
    table.insert(allTraits, {name=traitName, rarity=data.rarity, order=data.order})
end
table.sort(allTraits, function(a,b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local traitOptions = {}
for _, info in ipairs(allTraits) do table.insert(traitOptions, info.name) end

Tab:Section({Title = "Auto Trait Roll"})

Tab:Dropdown({
    Title = "Target Traits",
    Flag = "TargetTraits",
    Values = traitOptions,
    Multi = true,
    Value = _G.SlowHub.TargetTraits or {},
    Callback = function(selectedOptions)
        _G.SlowHub.TargetTraits = selectedOptions or {}
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Secret",
    Value = _G.SlowHub.StopOnSecret or true,
    Callback = function(Value)
        _G.SlowHub.StopOnSecret = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Mythical",
    Value = _G.SlowHub.StopOnMythicalTrait or true,
    Callback = function(Value)
        _G.SlowHub.StopOnMythicalTrait = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Legendary",
    Value = _G.SlowHub.StopOnLegendaryTrait or false,
    Callback = function(Value)
        _G.SlowHub.StopOnLegendaryTrait = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Epic",
    Value = _G.SlowHub.StopOnEpicTrait or false,
    Callback = function(Value)
        _G.SlowHub.StopOnEpicTrait = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Trait Roll Delay",
    Flag = "TraitRollDelay",
    Step = 0.05,
    Value = {
        Min = 0.15,
        Max = 1.0,
        Default = _G.SlowHub.TraitRollDelay or 0.35,
    },
    Callback = function(Value)
        _G.SlowHub.TraitRollDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Trait Roll",
    Value = _G.SlowHub.AutoTraitRoll or false,
    Callback = function(Value)
        _G.SlowHub.AutoTraitRoll = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startTraitRolling()
        else
            stopTraitRolling()
        end
    end,
})

if _G.SlowHub.AutoTraitRoll then
    task.spawn(function() task.wait(2); startTraitRolling() end)
end
