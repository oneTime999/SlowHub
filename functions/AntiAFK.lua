local Tab = _G.MiscTab
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local antiAfkConnection = nil
local idledConnection = nil

local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
    
    if idledConnection then
        idledConnection:Disconnect()
        idledConnection = nil
    end
    
    _G.SlowHub.AntiAFK = false
end

local function startAntiAfk()
    if antiAfkConnection or idledConnection then
        stopAntiAfk()
    end

    _G.SlowHub.AntiAFK = true

    idledConnection = Player.Idled:Connect(function()
        if not _G.SlowHub.AntiAFK then
            stopAntiAfk()
            return
        end
        
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)

    antiAfkConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AntiAFK then
            stopAntiAfk()
            return
        end
    end)
end

Tab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = _G.SlowHub.AntiAFK,
    Flag = "AntiAFKToggle",
    Callback = function(Value)
        if Value then
            startAntiAfk()
        else
            stopAntiAfk()
        end
        
        _G.SlowHub.AntiAFK = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AntiAFK then
    task.wait(2)
    startAntiAfk()
end
