local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoConquerorHaki = _G.SlowHub.AutoConquerorHaki or false
_G.SlowHub.HakiInterval = _G.SlowHub.HakiInterval or 3

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
if saved["AutoConquerorHaki"] ~= nil then _G.SlowHub.AutoConquerorHaki = saved["AutoConquerorHaki"] end
if saved["HakiInterval"] ~= nil then _G.SlowHub.HakiInterval = saved["HakiInterval"] end

local HakiState = {
    Connection = nil,
    IsRunning = false,
    LastExecution = 0,
}

local function ActivateHaki()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local conquerorHaki = remotes:FindFirstChild("ConquerorHakiRemote")
        if not conquerorHaki then return end
        conquerorHaki:FireServer("Activate")
    end)
end

function StopAutoHaki()
    HakiState.IsRunning = false
    if HakiState.Connection then
        HakiState.Connection:Disconnect()
        HakiState.Connection = nil
    end
end

function StartAutoHaki()
    if HakiState.IsRunning then
        StopAutoHaki()
        task.wait(0.2)
    end
    HakiState.IsRunning = true
    HakiState.LastExecution = 0
    HakiState.Connection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoConquerorHaki then
            StopAutoHaki()
            return
        end
        local currentTime = tick()
        if currentTime - HakiState.LastExecution < _G.SlowHub.HakiInterval then return end
        HakiState.LastExecution = currentTime
        ActivateHaki()
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Conqueror Haki" })

MiscTab:CreateToggle({
    Name = "Auto Conqueror Haki",
    Flag = "AutoConquerorHaki",
    CurrentValue = _G.SlowHub.AutoConquerorHaki,
    Callback = function(value)
        _G.SlowHub.AutoConquerorHaki = value
        saveConfig("AutoConquerorHaki", value)
        if value then
            StartAutoHaki()
        else
            StopAutoHaki()
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Conqueror Haki Interval",
    Flag = "HakiInterval",
    Range = { 1, 10 },
    Increment = 0.5,
    CurrentValue = _G.SlowHub.HakiInterval,
    Callback = function(value)
        _G.SlowHub.HakiInterval = value
        saveConfig("HakiInterval", value)
    end,
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoConquerorHaki then
        StartAutoHaki()
    end
end)
