local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local craftConnection = nil
local isRunning = false
local lastCraftTime = 0

local function craftSlimeKey()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local requestSlimeCraft = remotes:FindFirstChild("RequestSlimeCraft")
        if not requestSlimeCraft then return end
        requestSlimeCraft:InvokeServer("SlimeKey")
    end)
end

local function stopAutoCraft()
    isRunning = false
    lastCraftTime = 0
    if craftConnection then
        craftConnection:Disconnect()
        craftConnection = nil
    end
    _G.SlowHub.AutoCraftSlime = false
end

local function startAutoCraft()
    if isRunning then stopAutoCraft(); task.wait(0.2) end
    isRunning = true
    _G.SlowHub.AutoCraftSlime = true
    lastCraftTime = 0
    craftConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftSlime then stopAutoCraft(); return end
        local currentTime = tick()
        if currentTime - lastCraftTime < (_G.SlowHub.SlimeCraftInterval or 2) then return end
        lastCraftTime = currentTime
        craftSlimeKey()
    end)
end

Tab:Section({Title = "Crafting"})

Tab:Slider({
    Title = "Craft Interval",
    Flag = "SlimeCraftInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.SlimeCraftInterval or 2,
    },
    Callback = function(Value)
        _G.SlowHub.SlimeCraftInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Craft Slime Key",
    Value = _G.SlowHub.AutoCraftSlime or false,
    Callback = function(Value)
        _G.SlowHub.AutoCraftSlime = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        if Value then
            startAutoCraft()
        else
            stopAutoCraft()
        end
    end,
})

if _G.SlowHub.AutoCraftSlime then
    task.spawn(function() task.wait(2); startAutoCraft() end)
end
