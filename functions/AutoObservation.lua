local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub.AutoObservation = _G.SlowHub.AutoObservation or false
_G.SlowHub.ObservationInterval = _G.SlowHub.ObservationInterval or 3

local ObservationState = {
    Connection = nil,
    IsRunning = false,
    LastToggleTime = 0,
    PlayerGui = nil
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

local function ObservationLoop()
    if not _G.SlowHub.AutoObservation then
        StopAutoObservation()
        return
    end
    local currentTime = tick()
    local interval = _G.SlowHub.ObservationInterval
    if currentTime - ObservationState.LastToggleTime < interval then
        return
    end
    if not IsObservationActive() then
        ToggleObservation()
        ObservationState.LastToggleTime = currentTime
    end
end

local function StopAutoObservation()
    ObservationState.IsRunning = false
    ObservationState.LastToggleTime = 0
    if ObservationState.Connection then
        ObservationState.Connection:Disconnect()
        ObservationState.Connection = nil
    end
    _G.SlowHub.AutoObservation = false
end

local function StartAutoObservation()
    if ObservationState.IsRunning then
        StopAutoObservation()
        task.wait(0.2)
    end
    InitializeObservationState()
    ObservationState.IsRunning = true
    _G.SlowHub.AutoObservation = true
    ObservationState.LastToggleTime = 0
    ObservationState.Connection = RunService.Heartbeat:Connect(ObservationLoop)
end

Tab:Section({Title = "Observation Haki"})

Tab:Toggle({
    Title = "Auto Observation Haki",
    Default = _G.SlowHub.AutoObservation or false,
    Callback = function(Value)
        if Value then
            StartAutoObservation()
        else
            StopAutoObservation()
        end
        _G.SlowHub.AutoObservation = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Slider({
    Title = "Observation Check Interval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.ObservationInterval,
    },
    Callback = function(Value)
        _G.SlowHub.ObservationInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoObservation then
    task.spawn(function()
        task.wait(2)
        StartAutoObservation()
    end)
end
