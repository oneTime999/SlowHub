local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoAscend = _G.SlowHub.AutoAscend or false
_G.SlowHub.AscendInterval = _G.SlowHub.AscendInterval or 10

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then
        makefolder(CONFIG_FOLDER)
    end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok and type(data) == "table" then
            return data
        end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(current))
    end)
end

local saved = loadConfig()
if saved["AutoAscend"] ~= nil then _G.SlowHub.AutoAscend = saved["AutoAscend"] end
if saved["AscendInterval"] ~= nil then _G.SlowHub.AscendInterval = saved["AscendInterval"] end

local AscendState = {
    LoopConnection = nil,
    IsRunning = false,
}

local function PerformAscend()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local requestAscend = remoteEvents:FindFirstChild("RequestAscend")
        if not requestAscend then return end
        requestAscend:FireServer()
    end)
end

function StopAutoAscend()
    AscendState.IsRunning = false
    AscendState.LoopConnection = nil
    _G.SlowHub.AutoAscend = false
    getgenv().AutoAscend = false
end

function StartAutoAscend()
    if AscendState.IsRunning then return end
    AscendState.IsRunning = true
    _G.SlowHub.AutoAscend = true
    getgenv().AutoAscend = true
    AscendState.LoopConnection = task.spawn(function()
        while AscendState.IsRunning and _G.SlowHub.AutoAscend do
            PerformAscend()
            task.wait(_G.SlowHub.AscendInterval)
        end
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Ascend" })

MiscTab:CreateSlider({
    Name = "Ascend Interval",
    Flag = "AscendInterval",
    Range = { 5, 60 },
    Increment = 5,
    CurrentValue = _G.SlowHub.AscendInterval,
    Callback = function(value)
        _G.SlowHub.AscendInterval = value
        saveConfig("AscendInterval", value)
    end,
})

MiscTab:CreateToggle({
    Name = "Auto Ascend",
    Flag = "AutoAscend",
    CurrentValue = _G.SlowHub.AutoAscend,
    Callback = function(value)
        _G.SlowHub.AutoAscend = value
        getgenv().AutoAscend = value
        if value then
            StartAutoAscend()
        else
            StopAutoAscend()
        end
        saveConfig("AutoAscend", value)
    end,
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoAscend then
        StartAutoAscend()
    end
end)
