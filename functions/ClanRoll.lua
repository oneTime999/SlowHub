local Tab = _G.RollsTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local ClansData = {
    ["Voldigoat"] = {rarity="Legendary", order=5},
    ["Monarch"]   = {rarity="Legendary", order=5},
    ["Pride"]     = {rarity="Legendary", order=5},
    ["Mugetsu"]   = {rarity="Epic",      order=4},
    ["Yamato"]    = {rarity="Epic",      order=4},
    ["Zoldyck"]   = {rarity="Rare",      order=3},
    ["Raikage"]   = {rarity="Uncommon",  order=2},
    ["Sasaki"]    = {rarity="Common",    order=1},
    ["None"]      = {rarity="Common",    order=1},
}

local ClanRollState = {
    IsRolling = false,
    Connection = nil,
    LastRollTime = 0,
    CurrentClan = nil
}

local function ParseClanText(text)
    if not text then return nil end
    local clan = text:gsub("Clan: ",""):gsub("Clan:",""):match("^%s*(.-)%s*$")
    return clan ~= "" and clan or nil
end

local function GetCurrentClan()
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
    if ok and clanText then return ParseClanText(clanText) end
    return nil
end

local function GetClanRarity(clanName)
    local data = ClansData[clanName]
    return data and data.rarity or "Common"
end

local function IsTargetClan(clanName)
    if not clanName then return false end
    if _G.SlowHub.StopOnLegendaryClan and GetClanRarity(clanName) == "Legendary" then return true end
    if _G.SlowHub.StopOnEpicClan and GetClanRarity(clanName) == "Epic" then return true end
    for _, target in ipairs(_G.SlowHub.TargetClans) do
        if target == clanName then return true end
    end
    return false
end

local function FireClanRoll()
    pcall(function()
        ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use", "Clan Reroll", 1)
    end)
end

local function StopClanRolling()
    ClanRollState.IsRolling = false
    if ClanRollState.Connection then
        ClanRollState.Connection:Disconnect()
        ClanRollState.Connection = nil
    end
    if _G.SlowHub.AutoClanRoll then
        _G.SlowHub.AutoClanRoll = false
        if _G.SaveConfig then _G.SaveConfig() end
    end
end

local function StartClanRolling()
    if ClanRollState.IsRolling then return end
    ClanRollState.IsRolling = true
    ClanRollState.CurrentClan = GetCurrentClan()
    ClanRollState.LastRollTime = 0
    ClanRollState.Connection = RunService.Heartbeat:Connect(function()
        if not ClanRollState.IsRolling then return end
        local currentTime = tick()
        if currentTime - ClanRollState.LastRollTime < (_G.SlowHub.ClanRollDelay or 0.25) then return end
        local currentClan = GetCurrentClan()
        if currentClan and currentClan ~= ClanRollState.CurrentClan then
            ClanRollState.CurrentClan = currentClan
            if IsTargetClan(currentClan) then
                StopClanRolling()
                return
            end
        end
        FireClanRoll()
        ClanRollState.LastRollTime = currentTime
    end)
end

local AllClans = {}
for clanName, data in pairs(ClansData) do
    if clanName ~= "None" then
        table.insert(AllClans, {name = clanName, rarity = data.rarity, order = data.order})
    end
end
table.sort(AllClans, function(a, b)
    if a.order ~= b.order then return a.order > b.order end
    return a.name < b.name
end)

local clanOptions = {}
for _, info in ipairs(AllClans) do
    table.insert(clanOptions, info.name)
end

local Tab = _G.RollsTab

Tab:Section({ Title = "Auto Clan Roll" })

Tab:Dropdown({
    Title = "Target Clans",
    Flag = "TargetClans",
    Values = clanOptions,
    Multi = true,
    Value = _G.SlowHub.TargetClans or {},
    Callback = function(value)
        _G.SlowHub.TargetClans = type(value) == "table" and value or {}
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Toggle({
    Title = "Stop on Legendary",
    Flag = "StopOnLegendaryClan",
    Value = _G.SlowHub.StopOnLegendaryClan or true,
    Callback = function(value)
        _G.SlowHub.StopOnLegendaryClan = value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Toggle({
    Title = "Stop on Epic",
    Flag = "StopOnEpicClan",
    Value = _G.SlowHub.StopOnEpicClan or false,
    Callback = function(value)
        _G.SlowHub.StopOnEpicClan = value
        if _G.SaveConfig then _G.SaveConfig() end
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
    Callback = function(value)
        _G.SlowHub.ClanRollDelay = value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:Toggle({
    Title = "Auto Clan Roll",
    Flag = "AutoClanRoll",
    Value = _G.SlowHub.AutoClanRoll or false,
    Callback = function(value)
        _G.SlowHub.AutoClanRoll = value
        if _G.SaveConfig then _G.SaveConfig() end
        if value then
            StartClanRolling()
        else
            StopClanRolling()
        end
    end,
})

if _G.SlowHub.AutoClanRoll then
    task.spawn(function()
        task.wait(2)
        StartClanRolling()
    end)
end
