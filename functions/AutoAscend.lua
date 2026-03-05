local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoAscend = _G.SlowHub.AutoAscend or false
_G.SlowHub.AscendInterval = _G.SlowHub.AscendInterval or 10

local AscendState = {
    LoopConnection = nil,
    IsRunning = false
}

local function PerformAscend()
    local success = pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        
        local requestAscend = remoteEvents:FindFirstChild("RequestAscend")
        if not requestAscend then return end
        
        requestAscend:FireServer()
    end)
    
    return success
end

local function AscendLoop()
    if not _G.SlowHub.AutoAscend then
        StopAutoAscend()
        return
    end
    
    PerformAscend()
    task.wait(_G.SlowHub.AscendInterval)
end

local function StopAutoAscend()
    AscendState.IsRunning = false
    
    if AscendState.LoopConnection then
        AscendState.LoopConnection = nil
    end
    
    _G.SlowHub.AutoAscend = false
    getgenv().AutoAscend = false
end

local function StartAutoAscend()
    if AscendState.IsRunning then return end
    
    AscendState.IsRunning = true
    _G.SlowHub.AutoAscend = true
    getgenv().AutoAscend = true
    
    AscendState.LoopConnection = task.spawn(function()
        while AscendState.IsRunning and _G.SlowHub.AutoAscend do
            AscendLoop()
        end
    end)
end

Tab:CreateSection("Ascend")

Tab:CreateSlider({
    Name = "Ascend Interval",
    Range = {5, 60},
    Increment = 5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.AscendInterval,
    Flag = "AscendInterval",
    Callback = function(Value)
        _G.SlowHub.AscendInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Ascend",
    CurrentValue = _G.SlowHub.AutoAscend,
    Flag = "AutoAscend",
    Callback = function(Value)
        _G.SlowHub.AutoAscend = Value
        getgenv().AutoAscend = Value
        
        if Value then
            StartAutoAscend()
        else
            StopAutoAscend()
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoAscend then
    task.spawn(function()
        task.wait(2)
        StartAutoAscend()
    end)
end
