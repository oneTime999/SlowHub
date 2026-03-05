local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.MiscTab

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

Tab:Section({Title = "Auto Skills"})

Tab:Toggle({
    Title = "Auto Skill Z",
    Default = _G.SlowHub.AutoSkillZ or false,
    Callback = function(value)
        OnToggleChange("AutoSkillZ", value)
    end
})

Tab:Toggle({
    Title = "Auto Skill X",
    Default = _G.SlowHub.AutoSkillX or false,
    Callback = function(value)
        OnToggleChange("AutoSkillX", value)
    end
})

Tab:Toggle({
    Title = "Auto Skill C",
    Default = _G.SlowHub.AutoSkillC or false,
    Callback = function(value)
        OnToggleChange("AutoSkillC", value)
    end
})

Tab:Toggle({
    Title = "Auto Skill V",
    Default = _G.SlowHub.AutoSkillV or false,
    Callback = function(value)
        OnToggleChange("AutoSkillV", value)
    end
})

Tab:Toggle({
    Title = "Auto Skill F",
    Default = _G.SlowHub.AutoSkillF or false,
    Callback = function(value)
        OnToggleChange("AutoSkillF", value)
    end
})

Tab:Slider({
    Title = "Skill Interval",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 1,
        Default = _G.SlowHub.SkillInterval,
    },
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
