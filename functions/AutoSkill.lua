local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local skillMapping = {["AutoSkillZ"]=1,["AutoSkillX"]=2,["AutoSkillC"]=3,["AutoSkillV"]=4,["AutoSkillF"]=5}
local fruitKeys = {["AutoSkillZ"]="Z",["AutoSkillX"]="X",["AutoSkillC"]="C",["AutoSkillV"]="V"}
local fruitPowers = {"Light","Flame","Quake"}

local skillConnection = nil
local isRunning = false
local lastSkillTime = 0

local function isAnySkillActive()
    return _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC
        or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF
end

local function fireAbilityRequest(index)
    pcall(function()
        local abilitySystem = ReplicatedStorage:FindFirstChild("AbilitySystem")
        if not abilitySystem then return end
        local remotes = abilitySystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestAbility = remotes:FindFirstChild("RequestAbility")
        if requestAbility then requestAbility:FireServer(index) end
    end)
end

local function fireFruitPower(key, fruit)
    pcall(function()
        local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
        if not remoteEvents then return end
        local fruitPowerRemote = remoteEvents:FindFirstChild("FruitPowerRemote")
        if not fruitPowerRemote then return end
        local keyCode = Enum.KeyCode[key]
        if not keyCode then return end
        fruitPowerRemote:FireServer("UseAbility", {KeyCode=keyCode, FruitPower=fruit})
    end)
end

local function processAbilities()
    local currentTime = tick()
    if currentTime - lastSkillTime < (_G.SlowHub.SkillInterval or 0.2) then return end
    lastSkillTime = currentTime
    for flag, index in pairs(skillMapping) do
        if _G.SlowHub[flag] then fireAbilityRequest(index) end
    end
    local activeFruitKeys = {}
    for flag, key in pairs(fruitKeys) do
        if _G.SlowHub[flag] then table.insert(activeFruitKeys, key) end
    end
    if #activeFruitKeys == 0 then return end
    for _, fruit in ipairs(fruitPowers) do
        for _, key in ipairs(activeFruitKeys) do
            fireFruitPower(key, fruit)
        end
    end
end

local function stopSkillLoop()
    isRunning = false
    if skillConnection then
        skillConnection:Disconnect()
        skillConnection = nil
    end
end

local function startSkillLoop()
    if isRunning then return end
    if not isAnySkillActive() then return end
    isRunning = true
    lastSkillTime = 0
    skillConnection = RunService.Heartbeat:Connect(function()
        if not isAnySkillActive() then stopSkillLoop(); return end
        processAbilities()
    end)
end

local function onToggleChange(flag, value)
    _G.SlowHub[flag] = value
    if _G.SaveConfig then
        _G.SaveConfig()
    end
    if value then
        startSkillLoop()
    elseif not isAnySkillActive() then
        stopSkillLoop()
    end
end

Tab:Section({Title = "Auto Skills"})

Tab:Toggle({
    Title = "Auto Skill Z",
    Value = _G.SlowHub.AutoSkillZ or false,
    Callback = function(v) onToggleChange("AutoSkillZ", v) end,
})

Tab:Toggle({
    Title = "Auto Skill X",
    Value = _G.SlowHub.AutoSkillX or false,
    Callback = function(v) onToggleChange("AutoSkillX", v) end,
})

Tab:Toggle({
    Title = "Auto Skill C",
    Value = _G.SlowHub.AutoSkillC or false,
    Callback = function(v) onToggleChange("AutoSkillC", v) end,
})

Tab:Toggle({
    Title = "Auto Skill V",
    Value = _G.SlowHub.AutoSkillV or false,
    Callback = function(v) onToggleChange("AutoSkillV", v) end,
})

Tab:Toggle({
    Title = "Auto Skill F",
    Value = _G.SlowHub.AutoSkillF or false,
    Callback = function(v) onToggleChange("AutoSkillF", v) end,
})

Tab:Slider({
    Title = "Skill Interval",
    Flag = "SkillInterval",
    Step = 0.05,
    Value = {
        Min = 0.05,
        Max = 1,
        Default = _G.SlowHub.SkillInterval or 0.2,
    },
    Callback = function(Value)
        _G.SlowHub.SkillInterval = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end,
})

if isAnySkillActive() then
    task.spawn(function() task.wait(1); startSkillLoop() end)
end
