local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoHaki = _G.SlowHub.AutoHaki or false
_G.SlowHub.HakiInterval = _G.SlowHub.HakiInterval or 3

local HakiState = {
    Connection = nil,
    IsRunning = false,
    LastExecution = 0
}

local function ActivateHaki()
    local success = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local conquerorHaki = remotes:FindFirstChild("ConquerorHakiRemote")
        if not conquerorHaki then return end
        
        conquerorHaki:FireServer("Activate")
    end)
    
    return success
end

local function HakiLoop()
    if not _G.SlowHub.AutoHaki then
        StopAutoHaki()
        return
    end
    
    local currentTime = tick()
    local interval = _G.SlowHub.HakiInterval
    
    if currentTime - HakiState.LastExecution < interval then
        return
    end
    
    HakiState.LastExecution = currentTime
    ActivateHaki()
end

local function StopAutoHaki()
    HakiState.IsRunning = false
    
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
    
    HakiState.IsRunning = true
    _G.SlowHub.AutoHaki = true
    HakiState.LastExecution = 0
    
    HakiState.Connection = RunService.Heartbeat:Connect(function()
        HakiLoop()
    end)
end

Tab:CreateSection("Conqueror Haki")

Tab:CreateToggle({
    Name = "Auto Conqueror Haki",
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
    Name = "Conqueror Haki Interval",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.HakiInterval,
    Flag = "HakiInterval",
    Callback = function(Value)
        _G.SlowHub.HakiInterval = Value
        
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
