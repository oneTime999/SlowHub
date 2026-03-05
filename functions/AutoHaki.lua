local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoHaki = _G.SlowHub.AutoHaki or true

local HakiState = {
    IsRunning = false,
    Connection = nil
}

local function FireHaki()
    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
        if not remotes then return end
        
        local hakiRemote = remotes:FindFirstChild("Haki")
        if hakiRemote and hakiRemote:IsA("RemoteEvent") then
            hakiRemote:FireServer("Enable")
        end
    end)
end

local function HakiLoop()
    if not _G.SlowHub.AutoHaki then
        return
    end
    
    FireHaki()
end

local function StartHakiLoop()
    if HakiState.IsRunning then return end
    
    HakiState.IsRunning = true
    
    HakiState.Connection = RunService.Heartbeat:Connect(function()
        if _G.SlowHub.AutoHaki then
            HakiLoop()
        end
        task.wait(2)
    end)
end

local function StopHakiLoop()
    HakiState.IsRunning = false
    
    if HakiState.Connection then
        HakiState.Connection:Disconnect()
        HakiState.Connection = nil
    end
end

local function OnToggleChange(value)
    _G.SlowHub.AutoHaki = value
    
    if value then
        if not HakiState.IsRunning then
            StartHakiLoop()
        end
    else
        StopHakiLoop()
    end
    
    if _G.SaveConfig then
        _G.SaveConfig()
    end
end

Tab:CreateSection("Haki")

Tab:CreateToggle({
    Name = "Auto Haki fix",
    CurrentValue = _G.SlowHub.AutoHaki,
    Flag = "AutoHaki",
    Callback = OnToggleChange
})

if _G.SlowHub.AutoHaki then
    task.spawn(function()
        task.wait(1)
        StartHakiLoop()
    end)
end
