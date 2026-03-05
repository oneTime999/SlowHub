local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoObservation = _G.SlowHub.AutoObservation or false
_G.SlowHub.ObservationInterval = _G.SlowHub.ObservationInterval or 3

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
if saved["AutoObservation"] ~= nil then _G.SlowHub.AutoObservation = saved["AutoObservation"] end
if saved["ObservationInterval"] ~= nil then _G.SlowHub.ObservationInterval = saved["ObservationInterval"] end

local ObservationState = {
    Connection = nil,
    IsRunning = false,
    LastToggleTime = 0,
    PlayerGui = nil,
}

local function InitializeObservationState()
    ObservationState.PlayerGui = Player:FindFirstChild("PlayerGui")
end

InitializeObservationState()

Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    ObservationState.PlayerGui = Player:FindFirstChild("PlayerGui")
end)

local function IsObservationActive()
    if not ObservationState.PlayerGui then
        ObservationState.PlayerGui = Player:FindFirstChild("PlayerGui")
        if not ObservationState.PlayerGui then return false end
    end
    local dodgeUI = ObservationState.PlayerGui:FindFirstChild("DodgeCounterUI")
    if not dodgeUI then return false end
    local mainFrame = dodgeUI:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    return mainFrame.Visible == true
end

local function ToggleObservation()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local observationRemote = remoteEvents:FindFirstChild("ObservationHakiRemote")
        if not observationRemote then return end
        observationRemote:FireServer("Toggle")
    end)
end

function StopAutoObservation()
    ObservationState.IsRunning = false
    ObservationState.LastToggleTime = 0
    if ObservationState.Connection then
        ObservationState.Connection:Disconnect()
        ObservationState.Connection = nil
    end
    _G.SlowHub.AutoObservation = false
end

function StartAutoObservation()
    if ObservationState.IsRunning then
        StopAutoObservation()
        task.wait(0.2)
    end
    InitializeObservationState()
    ObservationState.IsRunning = true
    _G.SlowHub.AutoObservation = true
    ObservationState.LastToggleTime = 0
    ObservationState.Connection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoObservation then StopAutoObservation(); return end
        local currentTime = tick()
        if currentTime - ObservationState.LastToggleTime < _G.SlowHub.ObservationInterval then return end
        if not IsObservationActive() then
            ToggleObservation()
            ObservationState.LastToggleTime = currentTime
        end
    end)
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Observation Haki" })

MiscTab:CreateToggle({
    Name = "Auto Observation Haki",
    Flag = "AutoObservation",
    CurrentValue = _G.SlowHub.AutoObservation,
    Callback = function(value)
        _G.SlowHub.AutoObservation = value
        saveConfig("AutoObservation", value)
        if value then
            StartAutoObservation()
        else
            StopAutoObservation()
        end
    end,
})

MiscTab:CreateSlider({
    Name = "Observation Check Interval",
    Flag = "ObservationInterval",
    Range = { 1, 10 },
    Increment = 0.5,
    CurrentValue = _G.SlowHub.ObservationInterval,
    Callback = function(value)
        _G.SlowHub.ObservationInterval = value
        saveConfig("ObservationInterval", value)
    end,
})

if _G.SlowHub.AutoObservation then
    task.spawn(function()
        task.wait(2)
        StartAutoObservation()
    end)
end
