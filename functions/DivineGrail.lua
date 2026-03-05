local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoCraftDivineGrail = _G.SlowHub.AutoCraftDivineGrail or false
_G.SlowHub.CraftInterval = _G.SlowHub.CraftInterval or 2

local CraftState = {
    Connection = nil,
    IsRunning = false,
    LastCraftTime = 0
}

local function CraftDivineGrail()
    local success = pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local requestGrailCraft = remotes:FindFirstChild("RequestGrailCraft")
        if not requestGrailCraft then return end
        
        local args = {
            "DivineGrail",
            1
        }
        
        requestGrailCraft:InvokeServer(unpack(args))
    end)
    
    return success
end

local function CraftLoop()
    if not _G.SlowHub.AutoCraftDivineGrail then
        StopAutoCraft()
        return
    end
    
    local currentTime = tick()
    local interval = _G.SlowHub.CraftInterval
    
    if currentTime - CraftState.LastCraftTime < interval then
        return
    end
    
    CraftState.LastCraftTime = currentTime
    CraftDivineGrail()
end

local function StopAutoCraft()
    CraftState.IsRunning = false
    CraftState.LastCraftTime = 0
    
    if CraftState.Connection then
        CraftState.Connection:Disconnect()
        CraftState.Connection = nil
    end
    
    _G.SlowHub.AutoCraftDivineGrail = false
end

local function StartAutoCraft()
    if CraftState.IsRunning then
        StopAutoCraft()
        task.wait(0.2)
    end
    
    CraftState.IsRunning = true
    _G.SlowHub.AutoCraftDivineGrail = true
    CraftState.LastCraftTime = 0
    
    CraftState.Connection = RunService.Heartbeat:Connect(CraftLoop)
end

Tab:CreateSection("Crafting")

Tab:CreateSlider({
    Name = "Craft Interval",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.CraftInterval,
    Flag = "CraftInterval",
    Callback = function(Value)
        _G.SlowHub.CraftInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Craft Divine Grail",
    CurrentValue = _G.SlowHub.AutoCraftDivineGrail,
    Flag = "AutoCraftDivineGrail",
    Callback = function(Value)
        if Value then
            StartAutoCraft()
        else
            StopAutoCraft()
        end
        
        _G.SlowHub.AutoCraftDivineGrail = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoCraftDivineGrail then
    task.spawn(function()
        task.wait(2)
        StartAutoCraft()
    end)
end
