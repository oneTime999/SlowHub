local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoCraftSlime = _G.SlowHub.AutoCraftSlime or false
_G.SlowHub.SlimeCraftInterval = _G.SlowHub.SlimeCraftInterval or 2

local CraftState = {
    Connection = nil,
    IsRunning = false,
    LastCraftTime = 0
}

local function CraftSlimeKey()
    local success = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local requestSlimeCraft = remotes:FindFirstChild("RequestSlimeCraft")
        if not requestSlimeCraft then return end
        
        local args = {
            "SlimeKey"
        }
        
        requestSlimeCraft:InvokeServer(unpack(args))
    end)
    
    return success
end

local function CraftLoop()
    if not _G.SlowHub.AutoCraftSlime then
        StopAutoCraft()
        return
    end
    
    local currentTime = tick()
    local interval = _G.SlowHub.SlimeCraftInterval
    
    if currentTime - CraftState.LastCraftTime < interval then
        return
    end
    
    CraftState.LastCraftTime = currentTime
    CraftSlimeKey()
end

local function StopAutoCraft()
    CraftState.IsRunning = false
    CraftState.LastCraftTime = 0
    
    if CraftState.Connection then
        CraftState.Connection:Disconnect()
        CraftState.Connection = nil
    end
    
    _G.SlowHub.AutoCraftSlime = false
end

local function StartAutoCraft()
    if CraftState.IsRunning then
        StopAutoCraft()
        task.wait(0.2)
    end
    
    CraftState.IsRunning = true
    _G.SlowHub.AutoCraftSlime = true
    CraftState.LastCraftTime = 0
    
    CraftState.Connection = RunService.Heartbeat:Connect(CraftLoop)
end

Tab:CreateSection("Crafting")

Tab:CreateSlider({
    Name = "Craft Interval",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.SlimeCraftInterval,
    Flag = "SlimeCraftInterval",
    Callback = function(Value)
        _G.SlowHub.SlimeCraftInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Craft Slime Key",
    CurrentValue = _G.SlowHub.AutoCraftSlime,
    Flag = "AutoCraftSlimeKey",
    Callback = function(Value)
        if Value then
            StartAutoCraft()
        else
            StopAutoCraft()
        end
        
        _G.SlowHub.AutoCraftSlime = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoCraftSlime then
    task.spawn(function()
        task.wait(2)
        StartAutoCraft()
    end)
end
