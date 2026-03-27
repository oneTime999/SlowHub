local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ascendLoop = nil
local isRunning = false

local function performAscend()
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local requestAscend = remoteEvents:FindFirstChild("RequestAscend")
        if requestAscend then
            requestAscend:FireServer()
        end
    end)
end

local function stopAutoAscend()
    isRunning = false
    ascendLoop = nil
end

local function startAutoAscend()
    if isRunning then return end
    isRunning = true
    ascendLoop = task.spawn(function()
        while isRunning do
            performAscend()
            task.wait(_G.SlowHub.AscendInterval or 10)
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
        Default = _G.SlowHub.AscendInterval or 10,
    },
    Callback = function(Value)
        _G.SlowHub.AscendInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:Toggle({
    Title = "Auto Ascend",
    Value = _G.SlowHub.AutoAscend or false,
    Callback = function(Value)
        if Value then
            startAutoAscend()
        else
            stopAutoAscend()
        end
        _G.SlowHub.AutoAscend = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoAscend then
    task.wait(2)
    startAutoAscend()
end
