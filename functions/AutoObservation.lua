local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local autoObservationConnection = nil
local lastToggleTime = 0
local COOLDOWN_TIME = 3.5  -- ✅ Aumentado cooldown

local function isObservationActive()
    local playerGui = Player.PlayerGui
    if not playerGui then return false end
    
    local dodgeUI = playerGui:FindFirstChild("DodgeCounterUI")
    if not dodgeUI then return false end
    
    local mainFrame = dodgeUI:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    
    return mainFrame.Visible
end

local function toggleObservation()
    pcall(function()
        ReplicatedStorage.RemoteEvents.ObservationHakiRemote:FireServer("Toggle")
    end)
end

local function stopAutoObservation()
    if autoObservationConnection then
        autoObservationConnection:Disconnect()
        autoObservationConnection = nil
    end
    _G.SlowHub.AutoObservation = false
    lastToggleTime = 0
end

local function startAutoObservation()
    if autoObservationConnection then
        stopAutoObservation()
    end

    _G.SlowHub.AutoObservation = true
    lastToggleTime = 0

    autoObservationConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoObservation then
            stopAutoObservation()
            return
        end

        local now = tick()

        -- ✅ CORRIGIDO: Toggle sempre que cooldown permitir, independente do estado
        if now - lastToggleTime >= COOLDOWN_TIME then
            toggleObservation()
            lastToggleTime = now
        end
    end)
end

Tab:CreateToggle({
    Name = "Auto Observation Haki",
    CurrentValue = _G.SlowHub.AutoObservation,
    Flag = "AutoObservationToggle",
    Callback = function(Value)
        if Value then
            startAutoObservation()
        else
            stopAutoObservation()
        end
        
        _G.SlowHub.AutoObservation = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoObservation then
    task.wait(2)
    startAutoObservation()
end
