local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoCraftDivineGrail = _G.SlowHub.AutoCraftDivineGrail or false
_G.SlowHub.CraftInterval = _G.SlowHub.CraftInterval or 2

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
if saved["AutoCraftDivineGrail"] ~= nil then _G.SlowHub.AutoCraftDivineGrail = saved["AutoCraftDivineGrail"] end
if saved["CraftInterval"] ~= nil then _G.SlowHub.CraftInterval = saved["CraftInterval"] end

local CraftState = {Connection=nil, IsRunning=false, LastCraftTime=0}

local function CraftDivineGrail()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local requestGrailCraft = remotes:FindFirstChild("RequestGrailCraft")
        if not requestGrailCraft then return end
        requestGrailCraft:InvokeServer("DivineGrail", 1)
    end)
end

function StopAutoCraft()
    CraftState.IsRunning = false
    CraftState.LastCraftTime = 0
    if CraftState.Connection then
        CraftState.Connection:Disconnect()
        CraftState.Connection = nil
    end
    _G.SlowHub.AutoCraftDivineGrail = false
end

function StartAutoCraft()
    if CraftState.IsRunning then StopAutoCraft(); task.wait(0.2) end
    CraftState.IsRunning = true
    _G.SlowHub.AutoCraftDivineGrail = true
    CraftState.LastCraftTime = 0
    CraftState.Connection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftDivineGrail then StopAutoCraft(); return end
        local currentTime = tick()
        if currentTime - CraftState.LastCraftTime < _G.SlowHub.CraftInterval then return end
        CraftState.LastCraftTime = currentTime
        CraftDivineGrail()
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Crafting" })

MiscTab:CreateSlider({
    Name = "Craft Interval", Flag = "CraftInterval",
    Range = { 1, 10 }, Increment = 0.5,
    CurrentValue = _G.SlowHub.CraftInterval,
    Callback = function(value)
        _G.SlowHub.CraftInterval = value
        saveConfig("CraftInterval", value)
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Craft Divine Grail", Flag = "AutoCraftDivineGrail",
    CurrentValue = _G.SlowHub.AutoCraftDivineGrail,
    Callback = function(value)
        _G.SlowHub.AutoCraftDivineGrail = value
        saveConfig("AutoCraftDivineGrail", value)
        if value then StartAutoCraft() else StopAutoCraft() end
    end,
})

if _G.SlowHub.AutoCraftDivineGrail then
    task.spawn(function() task.wait(2); StartAutoCraft() end)
end
