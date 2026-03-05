local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoSkillZ = _G.SlowHub.AutoSkillZ or false
_G.SlowHub.AutoSkillX = _G.SlowHub.AutoSkillX or false
_G.SlowHub.AutoSkillC = _G.SlowHub.AutoSkillC or false
_G.SlowHub.AutoSkillV = _G.SlowHub.AutoSkillV or false
_G.SlowHub.AutoSkillF = _G.SlowHub.AutoSkillF or false
_G.SlowHub.SkillInterval = _G.SlowHub.SkillInterval or 0.2

local SkillState = {
    LoopConnection = nil,
    IsRunning = false,
    LastSkillTime = 0
}

local SkillMapping = {
    ["AutoSkillZ"] = 1,
    ["AutoSkillX"] = 2,
    ["AutoSkillC"] = 3,
    ["AutoSkillV"] = 4,
    ["AutoSkillF"] = 5
}

local FruitKeys = {
    ["AutoSkillZ"] = "Z",
    ["AutoSkillX"] = "X",
    ["AutoSkillC"] = "C",
    ["AutoSkillV"] = "V"
}

local FruitPowers = {"Light", "Flame", "Quake"}

local function IsAnySkillActive()
    return _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC
        or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF
end

local function GetActiveAbilityIndices()
    local indices = {}
    
    for flag, index in pairs(SkillMapping) do
        if _G.SlowHub[flag] then
            table.insert(indices, index)
        end
    end
    
    return indices
end

local function GetActiveFruitKeys()
    local keys = {}
    
    for flag, key in pairs(FruitKeys) do
        if _G.SlowHub[flag] then
            table.insert(keys, key)
        end
    end
    
    return keys
end

local function FireAbilityRequest(index)
    pcall(function()
        local abilitySystem = ReplicatedStorage:FindFirstChild("AbilitySystem")
        if not abilitySystem then return end
        
        local remotes = abilitySystem:FindFirstChild("Remotes")
        if not remotes then return end
        
        local requestAbility = remotes:FindFirstChild("RequestAbility")
        if requestAbility then
            requestAbility:FireServer(index)
        end
    end)
end

local function FireFruitPower(key, fruit)
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        
        local fruitPowerRemote = remoteEvents:FindFirstChild("FruitPowerRemote")
        if not fruitPowerRemote then return end
        
        local keyCode = Enum.KeyCode[key]
        if not keyCode then return end
        
        fruitPowerRemote:FireServer("UseAbility", {
            KeyCode = keyCode,
            FruitPower = fruit
        })
    end)
end

local function ProcessAbilities()
    local currentTime = tick()
    local interval = _G.SlowHub.SkillInterval
    
    if currentTime - SkillState.LastSkillTime < interval then
        return
    end
    
    SkillState.LastSkillTime = currentTime
    
    local abilityIndices = GetActiveAbilityIndices()
    for _, index in ipairs(abilityIndices) do
        FireAbilityRequest(index)
    end
    
    local fruitKeys = GetActiveFruitKeys()
    if #fruitKeys == 0 then return end
    
    for _, fruit in ipairs(FruitPowers) do
        for _, key in ipairs(fruitKeys) do
            FireFruitPower(key, fruit)
        end
    end
end

local function SkillLoop()
    if not IsAnySkillActive() then
        StopSkillLoop()
        return
    end
    
    ProcessAbilities()
end

local function StopSkillLoop()
    SkillState.IsRunning = false
    
    if SkillState.LoopConnection then
        SkillState.LoopConnection:Disconnect()
        SkillState.LoopConnection = nil
    end
end

local function StartSkillLoop()
    if SkillState.IsRunning then return end
    
    if not IsAnySkillActive() then return end
    
    SkillState.IsRunning = true
    SkillState.LastSkillTime = 0
    
    SkillState.LoopConnection = RunService.Heartbeat:Connect(function()
        SkillLoop()
        task.wait(_G.SlowHub.SkillInterval)
    end)
end

local function OnToggleChange(flag, value)
    _G.SlowHub[flag] = value
    
    if value then
        StartSkillLoop()
    elseif not IsAnySkillActive() then
        StopSkillLoop()
    end
    
    if _G.SaveConfig then
        _G.SaveConfig()
    end
end

Tab:CreateSection("Auto Skills")

Tab:CreateToggle({
    Name = "Auto Skill Z",
    CurrentValue = _G.SlowHub.AutoSkillZ,
    Flag = "AutoSkillZ",
    Callback = function(value)
        OnToggleChange("AutoSkillZ", value)
    end
})

Tab:CreateToggle({
    Name = "Auto Skill X",
    CurrentValue = _G.SlowHub.AutoSkillX,
    Flag = "AutoSkillX",
    Callback = function(value)
        OnToggleChange("AutoSkillX", value)
    end
})

Tab:CreateToggle({
    Name = "Auto Skill C",
    CurrentValue = _G.SlowHub.AutoSkillC,
    Flag = "AutoSkillC",
    Callback = function(value)
        OnToggleChange("AutoSkillC", value)
    end
})

Tab:CreateToggle({
    Name = "Auto Skill V",
    CurrentValue = _G.SlowHub.AutoSkillV,
    Flag = "AutoSkillV",
    Callback = function(value)
        OnToggleChange("AutoSkillV", value)
    end
})

Tab:CreateToggle({
    Name = "Auto Skill F",
    CurrentValue = _G.SlowHub.AutoSkillF,
    Flag = "AutoSkillF",
    Callback = function(value)
        OnToggleChange("AutoSkillF", value)
    end
})

Tab:CreateSlider({
    Name = "Skill Interval",
    Range = {0.05, 1},
    Increment = 0.05,
    Suffix = "Seconds",
    CurrentValue = _G.SlowHub.SkillInterval,
    Flag = "SkillInterval",
    Callback = function(Value)
        _G.SlowHub.SkillInterval = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if IsAnySkillActive() then
    task.spawn(function()
        task.wait(1)
        StartSkillLoop()
    end)
end
