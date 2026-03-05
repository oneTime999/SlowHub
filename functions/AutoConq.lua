local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tab = _G.MiscTab

local HakiState = {
    Connection = nil,
    IsRunning = false,
    LastExecution = 0
}

local function ActivateHaki()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local conquerorHaki = remotes:FindFirstChild("ConquerorHakiRemote")
        if not conquerorHaki then return end
        conquerorHaki:FireServer("Activate")
    end)
end

local function HakiLoop()
    if not _G.SlowHub.AutoConquerorHaki then
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

function StopAutoHaki()
    HakiState.IsRunning = false
    if HakiState.Connection then
        HakiState.Connection:Disconnect()
        HakiState.Connection = nil
    end
end

function StartAutoHaki()
    if HakiState.IsRunning then
        StopAutoHaki()
        task.wait(0.2)
    end
    HakiState.IsRunning = true
    HakiState.LastExecution = 0
    HakiState.Connection = RunService.Heartbeat:Connect(HakiLoop)
end

Tab:Section({Title = "Conqueror Haki"})

Tab:Toggle({
    Title = "Auto Conqueror Haki",
    Flag = "AutoConquerorHaki",
    Default = false,
    Callback = function(Value)
        if Value then
            StartAutoHaki()
        else
            StopAutoHaki()
        end
    end
})

Tab:Slider({
    Title = "Conqueror Haki Interval",
    Flag = "HakiInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = 3,
    },
    Callback = function(Value)
    end
})

task.spawn(function()
    task.wait(2)
    if _G.SlowHub.AutoConquerorHaki then
        StartAutoHaki()
    end
end)
