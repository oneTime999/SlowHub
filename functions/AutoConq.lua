local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hakiConnection = nil
local lastExecution = 0
local WAIT_TIME = 3

if _G.SlowHub.AutoConq == nil then
    _G.SlowHub.AutoConq = false
end

local function stopAutoConq()
    if hakiConnection then
        hakiConnection:Disconnect()
        hakiConnection = nil
    end
    _G.SlowHub.AutoConq = false
end

local function startAutoConq()
    if hakiConnection then stopAutoConq() end

    _G.SlowHub.AutoConq = true
    
    hakiConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoConq then
            stopAutoConq()
            return
        end

        if tick() - lastExecution >= WAIT_TIME then
            lastExecution = tick()
            
            local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ConquerorHakiRemote")
            if remote then
                remote:FireServer("Activate")
            end
        end
    end)
end

local HakiToggle = _G.MiscTab:CreateToggle({
    Name = "Auto Conqueror Haki",
    CurrentValue = _G.SlowHub.AutoConq,
    Flag = "AutoConq",
    Callback = function(Value)
        if Value then
            startAutoConq()
        else
            stopAutoConq()
        end
        
        _G.SlowHub.AutoConq = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoConq then
    task.wait(2)
    startAutoConq()
end
