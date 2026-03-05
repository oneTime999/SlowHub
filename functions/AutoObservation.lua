local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

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

function StopAutoObservation()
    ObservationState.IsRunning = false
    ObservationState.LastToggleTime = 0
    if ObservationState.Connection then
        ObservationState.Connection:Disconnect()
        ObservationState.Connection = nil
    end
end

function StartAutoObservation()
    if ObservationState.IsRunning then
        StopAutoObservation()
        task.wait(0.2)
    end
    InitializeObservationState()
    ObservationState.IsRunning = true
    ObservationState.LastToggleTime = 0
    ObservationState.Connection = RunService.Heartbeat:Connect(ObservationLoop)
end

Tab:Section({Title = "Observation Haki"})

Tab:Toggle({
    Title = "Auto Observation Haki",
    Flag = "AutoObservation",
    Default = false,
    Callback = function(Value)
        if Value then
            StartAutoObservation()
        else
            StopAutoObservation()
        end
    end
})

Tab:Slider({
    Title = "Observation Check Interval",
    Flag = "ObservationInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = 3,
    },
    Callback = function(Value)
    end
})
