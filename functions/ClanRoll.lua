local Tab = _G.RollsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local clansData = {
    ["Voldigoat"]={rarity="Legendary",order=5},["Monarch"]={rarity="Legendary",order=5},
    ["Pride"]={rarity="Legendary",order=5},["Mugetsu"]={rarity="Epic",order=4},
    ["Yamato"]={rarity="Epic",order=4},["Zoldyck"]={rarity="Rare",order=3},
    ["Raikage"]={rarity="Uncommon",order=2},["Sasaki"]={rarity="Common",order=1},
    ["None"]={rarity="Common",order=1},
}

local rollConnection = nil
local isRolling = false
local lastRollTime = 0
local currentClan = nil

local function parseClanText(text)
    if not text then return nil end
    local clan = text:gsub("Clan: ",""):gsub("Clan:",""):match("^%s*(.-)%s*$")
    return clan ~= "" and clan or nil
end

local function getCurrentClan()
    local ok, clanText = pcall(function()
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
        local clanEquipped = userStats:FindFirstChild("ClanEquipped")
        if not clanEquipped then return nil end
        local statName = clanEquipped:FindFirstChild("StatName")
        if not statName then return nil end
        return statName.Text
    end)
    if ok and clanText then return parseClanText(clanText) end
    return nil
end

local function getClanRarity(clanName)
    local data = clansData[clanName]
    return data and data.rarity or "Common"
end

local function isTargetClan(clanName)
    if not clanName then return false end
    if _G.SlowHub.StopOnLegendaryClan and getClanRarity(clanName) == "Legendary" then return true end
    if _G.SlowHub.StopOnEpicClan and getClanRarity(clanName) == "Epic" then return true end
    if _G.SlowHub.TargetClans then
        for _, target in ipairs(_G.SlowHub.TargetClans) do
            if target == clanName then return true end
        end
    end
    return false
end

local function fireClanRoll()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Clan Reroll",1)
    end)
end

local function stopClanRolling()
    isRolling = false
    if rollConnection then
        rollConnection:Disconnect()
        rollConnection = nil
    end
    if _G.SlowHub.AutoClanRoll then
        _G.SlowHub.AutoClanRoll = false
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
end

local function startClanRolling()
    if isRolling then return end
    isRolling = true
    currentClan = getCurrentClan()
    lastRollTime = 0
    rollConnection = RunService.Heartbeat:Connect(function()
        if not isRolling then return end
        local currentTime = tick()
        if currentTime - lastRollTime < (_G.SlowHub.ClanRollDelay or 0.25) then return end
        local currentClanNow = getCurrentClan()
        if currentClanNow and currentClanNow ~= currentClan then
            currentClan = currentClanNow
            if isTargetClan(currentClan) then stopClanRolling(); return end
        end
        fireClanRoll()
        lastRollTime = currentTime
    end)
end

local allClans = {}
for clanName, data in pairs(clansData) do
    if clanName ~= "None" then
        table.insert(allClans, {name=clanName, rarity=data.rarity, order=data.order})
    end
end
table.sort(allClans, function(a,b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local clanOptions = {}
for _, info in ipairs(allClans) do table.insert(clanOptions, info.name) end

Tab:Section({Title = "Auto Clan Roll"})

Tab:Dropdown({
    Title = "Target Clans",
    Flag = "TargetClans",
    Values = clanOptions,
    Multi = true,
    Default = _G.SlowHub.TargetClans or {},
    Callback = function(selectedOptions)
        _G.SlowHub.TargetClans = selectedOptions or {}
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Legendary",
    Default = _G.SlowHub.StopOnLegendaryClan or true,
    Callback = function(Value)
        _G.SlowHub.StopOnLegendaryClan = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Stop on Epic",
    Default = _G.SlowHub.StopOnEpicClan or false,
    Callback = function(Value)
        _G.SlowHub.StopOnEpicClan = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Slider({
    Title = "Clan Roll Delay",
    Flag = "ClanRollDelay",
    Step = 0.05,
    Value = {
        Min = 0.15,
        Max = 1.0,
        Default = _G.SlowHub.ClanRollDelay or 0.25,
    },
    Callback = function(Value)
        _G.SlowHub.ClanRollDelay = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Clan Roll",
    Default = _G.SlowHub.AutoClanRoll or false,
    Callback = function(Value)
        _G.SlowHub.AutoClanRoll = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startClanRolling()
        else
            stopClanRolling()
        end
    end,
})

if _G.SlowHub.AutoClanRoll then
    task.spawn(function() task.wait(2); startClanRolling() end)
end
