local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoCraftSlime = _G.SlowHub.AutoCraftSlime or false
_G.SlowHub.SlimeCraftInterval = _G.SlowHub.SlimeCraftInterval or 2

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
if saved["AutoCraftSlime"] ~= nil then _G.SlowHub.AutoCraftSlime = saved["AutoCraftSlime"] end
if saved["SlimeCraftInterval"] ~= nil then _G.SlowHub.SlimeCraftInterval = saved["SlimeCraftInterval"] end

local CraftState = {Connection=nil, IsRunning=false, LastCraftTime=0}

local function CraftSlimeKey()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local requestSlimeCraft = remotes:FindFirstChild("RequestSlimeCraft")
        if not requestSlimeCraft then return end
        requestSlimeCraft:InvokeServer("SlimeKey")
    end)
end

function StopAutoCraftSlime()
    CraftState.IsRunning = false
    CraftState.LastCraftTime = 0
    if CraftState.Connection then
        CraftState.Connection:Disconnect()
        CraftState.Connection = nil
    end
    _G.SlowHub.AutoCraftSlime = false
end

function StartAutoCraftSlime()
    if CraftState.IsRunning then StopAutoCraftSlime(); task.wait(0.2) end
    CraftState.IsRunning = true
    _G.SlowHub.AutoCraftSlime = true
    CraftState.LastCraftTime = 0
    CraftState.Connection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftSlime then StopAutoCraftSlime(); return end
        local currentTime = tick()
        if currentTime - CraftState.LastCraftTime < _G.SlowHub.SlimeCraftInterval then return end
        CraftState.LastCraftTime = currentTime
        CraftSlimeKey()
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Crafting" })

MiscTab:CreateSlider({
    Name = "Craft Interval", Flag = "SlimeCraftInterval",
    Range = { 1, 10 }, Increment = 0.5,
    CurrentValue = _G.SlowHub.SlimeCraftInterval,
    Callback = function(value)
        _G.SlowHub.SlimeCraftInterval = value
        saveConfig("SlimeCraftInterval", value)
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Craft Slime Key", Flag = "AutoCraftSlimeKey",
    CurrentValue = _G.SlowHub.AutoCraftSlime,
    Callback = function(value)
        _G.SlowHub.AutoCraftSlime = value
        saveConfig("AutoCraftSlime", value)
        if value then StartAutoCraftSlime() else StopAutoCraftSlime() end
    end,
})

if _G.SlowHub.AutoCraftSlime then
    task.spawn(function() task.wait(2); StartAutoCraftSlime() end)
end
