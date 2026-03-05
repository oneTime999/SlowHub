local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoHaki = _G.SlowHub.AutoHaki or false
_G.SlowHub.HakiCheckInterval = _G.SlowHub.HakiCheckInterval or 3

local HakiState = {
    Connection = nil,
    IsRunning = false,
    LastToggleTime = 0,
    Character = nil,
    Humanoid = nil
}

local ArmParts = {
    "Left Arm",
    "Right Arm"
}

local function InitializeHakiState()
    HakiState.Character = Player.Character
    HakiState.Humanoid = HakiState.Character and HakiState.Character:FindFirstChildOfClass("Humanoid")
end

InitializeHakiState()

Player.CharacterAdded:Connect(function(char)
    HakiState.Character = char
    HakiState.Humanoid = nil
    
    task.wait(0.1)
    
    HakiState.Humanoid = char:FindFirstChildOfClass("Humanoid")
end)

local function IsAlive()
    if not HakiState.Humanoid then
        HakiState.Humanoid = HakiState.Character and HakiState.Character:FindFirstChildOfClass("Humanoid")
    end
    
    return HakiState.Humanoid and HakiState.Humanoid.Health > 0
end

local function HasHakiEffect()
    if not HakiState.Character then return false end
    
    for _, armName in ipairs(ArmParts) do
        local arm = HakiState.Character:FindFirstChild(armName)
        if not arm then continue end
        
        local effect = arm:FindFirstChild("3")
        if effect and effect:IsA("ParticleEmitter") then
            return true
        end
    end
    
    return false
end

local function ToggleHaki()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        
        local hakiRemote = remoteEvents:FindFirstChild("HakiRemote")
        if not hakiRemote then return end
        
        hakiRemote:FireServer("Toggle")
    end)
end

local function HakiLoop()
    if not _G.SlowHub.AutoHaki then
        StopAutoHaki()
        return
    end
    
    if not IsAlive() then return end
    
    local currentTime = tick()
    local interval = _G.SlowHub.HakiCheckInterval
    
    if currentTime - HakiState.LastToggleTime < interval then
        return
    end
    
    if not HasHakiEffect() then
        ToggleHaki()
        HakiState.LastToggleTime = currentTime
    end
end

local function StopAutoHaki()
    HakiState.IsRunning = false
    HakiState.LastToggleTime = 0
    
    if HakiState.Connection then
        HakiState.Connection:Disconnect()
        HakiState.Connection = nil
    end
    
    _G.SlowHub.AutoHaki = false
end

local function StartAutoHaki()
    if HakiState.IsRunning then
        StopAutoHaki()
        task.wait(0.2)
    end
    
    InitializeHakiState()
    
    HakiState.IsRunning = true
    _G.SlowHub.AutoHaki = true
    HakiState.LastToggleTime = 0
    
    HakiState.Connection = RunService.Heartbeat:Connect(HakiLoop)
end

Tab:CreateSection("Haki")

Tab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = _G.SlowHub.AutoHaki,
    Flag = "AutoHaki",
    Callback = function(Value)
        if Value then
            StartAutoHaki()
        else
            StopAutoHaki()
        end
        
        _G.SlowHub.AutoHaki = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSlider({
    Name = "Haki Check Interval",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.HakiCheckInterval,
    Flag = "HakiCheckInterval",
    Callback = function(Value)
        _G.SlowHub.HakiCheckInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoHaki then
    task.spawn(function()
        task.wait(2)
        StartAutoHaki()
    end)
end
