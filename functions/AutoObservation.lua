local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local observationConnection = nil
local isRunning = false
local lastToggleTime = 0
local playerGui = nil

local function initialize()
    playerGui = Player:FindFirstChild("PlayerGui")
end

initialize()

Player.CharacterAdded:Connect(function()
    task.wait(0.5)
    playerGui = Player:FindFirstChild("PlayerGui")
end)

local function isObservationActive()
    if not playerGui then
        playerGui = Player:FindFirstChild("PlayerGui")
        if not playerGui then return false end
    end
    local dodgeUI = playerGui:FindFirstChild("DodgeCounterUI")
    if not dodgeUI then return false end
    local mainFrame = dodgeUI:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    return mainFrame.Visible == true
end

local function toggleObservation()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local observationRemote = remoteEvents:FindFirstChild("ObservationHakiRemote")
        if not observationRemote then return end
        observationRemote:FireServer("Toggle")
    end)
end

local function stopAutoObservation()
    isRunning = false
    lastToggleTime = 0
    if observationConnection then
        observationConnection:Disconnect()
        observationConnection = nil
    end
end

local function startAutoObservation()
    if isRunning then
        stopAutoObservation()
        task.wait(0.2)
    end
    initialize()
    isRunning = true
    lastToggleTime = 0
    observationConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoObservation then
            stopAutoObservation()
            return
        end
        local currentTime = tick()
        if currentTime - lastToggleTime < (_G.SlowHub.ObservationInterval or 3) then return end
        if not isObservationActive() then
            toggleObservation()
            lastToggleTime = currentTime
        end
    end)
end

Tab:Section({Title = "Observation Haki"})

Tab:Toggle({
    Title = "Auto Observation Haki",
    Value = _G.SlowHub.AutoObservation or false,
    Callback = function(Value)
        _G.SlowHub.AutoObservation = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoObservation()
        else
            stopAutoObservation()
        end
    end,
})

Tab:Slider({
    Title = "Observation Check Interval",
    Flag = "ObservationInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.ObservationInterval or 3,
    },
    Callback = function(Value)
        _G.SlowHub.ObservationInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

if _G.SlowHub.AutoObservation then
    task.spawn(function()
        task.wait(2)
        startAutoObservation()
    end)
end
