local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoHaki = _G.SlowHub.AutoHaki or true

local HakiState = {
    IsRunning = false,
    Thread = nil
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

local function StartHakiLoop()
    if HakiState.IsRunning then return end

    HakiState.IsRunning = true

    HakiState.Thread = task.spawn(function()
        while HakiState.IsRunning do
            if _G.SlowHub.AutoHaki then
                FireHaki()
            end
            task.wait(2)
        end
    end)
end

local function StopHakiLoop()
    HakiState.IsRunning = false
    HakiState.Thread = nil
end

local function OnToggleChange(value)
    _G.SlowHub.AutoHaki = value

    if value then
        StartHakiLoop()
    else
        StopHakiLoop()
    end

    if _G.SaveConfig then
        _G.SaveConfig()
    end
end

Tab:CreateSection("Haki")

Tab:CreateToggle({
    Name = "Auto Haki",
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
