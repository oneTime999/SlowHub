local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hakiConnection = nil
local isRunning = false
local lastExecution = 0

local function activateHaki()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local conquerorHaki = remotes:FindFirstChild("ConquerorHakiRemote")
        if conquerorHaki then
            conquerorHaki:FireServer("Activate")
        end
    end)
end

local function stopAutoHaki()
    isRunning = false
    if hakiConnection then
        hakiConnection:Disconnect()
        hakiConnection = nil
    end
end

local function startAutoHaki()
    if isRunning then
        stopAutoHaki()
        task.wait(0.2)
    end
    isRunning = true
    lastExecution = 0
    hakiConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoConquerorHaki then
            stopAutoHaki()
            return
        end
        local currentTime = tick()
        if currentTime - lastExecution < (_G.SlowHub.HakiInterval or 3) then return end
        lastExecution = currentTime
        activateHaki()
    end)
end

Tab:Section({Title = "Conqueror Haki"})

Tab:Toggle({
    Title = "Auto Conqueror Haki",
    Value = _G.SlowHub.AutoConquerorHaki or false,
    Callback = function(Value)
        _G.SlowHub.AutoConquerorHaki = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoHaki()
        else
            stopAutoHaki()
        end
    end,
})

Tab:Slider({
    Title = "Conqueror Haki Interval",
    Flag = "HakiInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.HakiInterval or 3,
    },
    Callback = function(Value)
        _G.SlowHub.HakiInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

if _G.SlowHub.AutoConquerorHaki then
    task.wait(2)
    startAutoHaki()
end
