local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local autoObservationConnection = nil
local lastToggleTime = 0
local COOLDOWN_TIME = 3

local function isObservationActive()
    local playerGui = Player.PlayerGui
    if not playerGui then return false end
    
    local dodgeUI = playerGui:FindFirstChild("DodgeCounterUI")
    if not dodgeUI then return false end
    
    local mainFrame = dodgeUI:FindFirstChild("MainFrame")
    if not mainFrame then return false end
    
    return mainFrame.Visible  -- ✅ true = ATIVADO, false = DESATIVADO
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

        -- ✅ CORRETO: Só ativa SE não estiver ativo (Visible=false ou UI não existe)
        if now - lastToggleTime >= COOLDOWN_TIME then
            if not isObservationActive() then  -- Visible=false OU UI não existe
                toggleObservation()
                lastToggleTime = now
            end
        end
    end)
end

local Toggle = Tab:AddToggle("AutoObservation", {
    Title = "Auto Observation Haki",
    Default = _G.SlowHub.AutoObservation,
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
