local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tab = _G.MiscTab

local AscendState = {
    LoopConnection = nil,
    IsRunning = false
}

local function PerformAscend()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local requestAscend = remoteEvents:FindFirstChild("RequestAscend")
        if not requestAscend then return end
        requestAscend:FireServer()
    end)
end

local function AscendLoop()
    if not _G.SlowHub.AutoAscend then
        StopAutoAscend()
        return
    end
    PerformAscend()
    task.wait(_G.SlowHub.AscendInterval)
end

function StopAutoAscend()
    AscendState.IsRunning = false
    if AscendState.LoopConnection then
        AscendState.LoopConnection = nil
    end
    getgenv().AutoAscend = false
end

function StartAutoAscend()
    if AscendState.IsRunning then return end
    AscendState.IsRunning = true
    getgenv().AutoAscend = true
    AscendState.LoopConnection = task.spawn(function()
        while AscendState.IsRunning and _G.SlowHub.AutoAscend do
            AscendLoop()
        end
    end)
end

Tab:Section({Title = "Ascend"})

Tab:Slider({
    Title = "Ascend Interval",
    Flag = "AscendInterval",
    Step = 5,
    Value = {
        Min = 5,
        Max = 60,
        Default = 10,
    },
    Callback = function(Value)
    end
})

Tab:Toggle({
    Title = "Auto Ascend",
    Flag = "AutoAscend",
    Default = false,
    Callback = function(Value)
        getgenv().AutoAscend = Value
        if Value then
            StartAutoAscend()
        else
            StopAutoAscend()
        end
    end
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoAscend then
        StartAutoAscend()
    end
end)
