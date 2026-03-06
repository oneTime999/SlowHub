local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local craftConnection = nil
local isRunning = false
local lastCraftTime = 0

local function craftDivineGrail()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        local requestGrailCraft = remotes:FindFirstChild("RequestGrailCraft")
        if not requestGrailCraft then return end
        requestGrailCraft:InvokeServer("DivineGrail", 1)
    end)
end

local function stopAutoCraft()
    isRunning = false
    lastCraftTime = 0
    if craftConnection then
        craftConnection:Disconnect()
        craftConnection = nil
    end
    _G.SlowHub.AutoCraftDivineGrail = false
end

local function startAutoCraft()
    if isRunning then stopAutoCraft(); task.wait(0.2) end
    isRunning = true
    _G.SlowHub.AutoCraftDivineGrail = true
    lastCraftTime = 0
    craftConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftDivineGrail then stopAutoCraft(); return end
        local currentTime = tick()
        if currentTime - lastCraftTime < (_G.SlowHub.CraftInterval or 2) then return end
        lastCraftTime = currentTime
        craftDivineGrail()
    end)
end

Tab:Section({Title = "Crafting"})

Tab:Slider({
    Title = "Craft Interval",
    Flag = "CraftInterval",
    Step = 0.5,
    Value = {
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.CraftInterval or 2,
    },
    Callback = function(Value)
        _G.SlowHub.CraftInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

Tab:Toggle({
    Title = "Auto Craft Divine Grail",
    Default = _G.SlowHub.AutoCraftDivineGrail or false,
    Callback = function(Value)
        _G.SlowHub.AutoCraftDivineGrail = Value
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

if _G.SlowHub.AutoCraftDivineGrail then
    task.spawn(function() task.wait(2); startAutoCraft() end)
end
