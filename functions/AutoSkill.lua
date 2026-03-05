local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.AutoSkillZ = _G.SlowHub.AutoSkillZ or false
_G.SlowHub.AutoSkillX = _G.SlowHub.AutoSkillX or false
_G.SlowHub.AutoSkillC = _G.SlowHub.AutoSkillC or false
_G.SlowHub.AutoSkillV = _G.SlowHub.AutoSkillV or false
_G.SlowHub.AutoSkillF = _G.SlowHub.AutoSkillF or false
_G.SlowHub.SkillInterval = _G.SlowHub.SkillInterval or 0.2

local CONFIG_FOLDER = "SlowHub"
local CONFIG_FILE = CONFIG_FOLDER .. "/config.json"

local function ensureFolder()
    if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
end

local function loadConfig()
    ensureFolder()
    if isfile(CONFIG_FILE) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
        if ok and type(data) == "table" then return data end
    end
    return {}
end

local function saveConfig(key, value)
    ensureFolder()
    local current = loadConfig()
    current[key] = value
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(current)) end)
end

local saved = loadConfig()
local skillFlags = {"AutoSkillZ","AutoSkillX","AutoSkillC","AutoSkillV","AutoSkillF","SkillInterval"}
for _, flag in ipairs(skillFlags) do
    if saved[flag] ~= nil then _G.SlowHub[flag] = saved[flag] end
end

local SkillMapping = {["AutoSkillZ"]=1,["AutoSkillX"]=2,["AutoSkillC"]=3,["AutoSkillV"]=4,["AutoSkillF"]=5}
local FruitKeys = {["AutoSkillZ"]="Z",["AutoSkillX"]="X",["AutoSkillC"]="C",["AutoSkillV"]="V"}
local FruitPowers = {"Light","Flame","Quake"}

local SkillState = {LoopConnection=nil, IsRunning=false, LastSkillTime=0}

local function IsAnySkillActive()
    return _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC
        or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF
end

local function FireAbilityRequest(index)
    pcall(function()
        local abilitySystem = ReplicatedStorage:FindFirstChild("AbilitySystem")
        if not abilitySystem then return end
        local remotes = abilitySystem:FindFirstChild("Remotes")
        if not remotes then return end
        local requestAbility = remotes:FindFirstChild("RequestAbility")
        if requestAbility then requestAbility:FireServer(index) end
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
        fruitPowerRemote:FireServer("UseAbility", {KeyCode=keyCode, FruitPower=fruit})
    end)
end

local function ProcessAbilities()
    local currentTime = tick()
    if currentTime - SkillState.LastSkillTime < _G.SlowHub.SkillInterval then return end
    SkillState.LastSkillTime = currentTime
    for flag, index in pairs(SkillMapping) do
        if _G.SlowHub[flag] then FireAbilityRequest(index) end
    end
    local fruitKeys = {}
    for flag, key in pairs(FruitKeys) do
        if _G.SlowHub[flag] then table.insert(fruitKeys, key) end
    end
    if #fruitKeys == 0 then return end
    for _, fruit in ipairs(FruitPowers) do
        for _, key in ipairs(fruitKeys) do
            FireFruitPower(key, fruit)
        end
    end
end

function StopSkillLoop()
    SkillState.IsRunning = false
    if SkillState.LoopConnection then
        SkillState.LoopConnection:Disconnect()
        SkillState.LoopConnection = nil
    end
end

function StartSkillLoop()
    if SkillState.IsRunning then return end
    if not IsAnySkillActive() then return end
    SkillState.IsRunning = true
    SkillState.LastSkillTime = 0
    SkillState.LoopConnection = RunService.Heartbeat:Connect(function()
        if not IsAnySkillActive() then StopSkillLoop(); return end
        ProcessAbilities()
    end)
end

local function OnToggleChange(flag, value)
    _G.SlowHub[flag] = value
    saveConfig(flag, value)
    if value then
        StartSkillLoop()
    elseif not IsAnySkillActive() then
        StopSkillLoop()
    end
end

local MiscTab = _G.MiscTab

MiscTab:CreateSection({ Title = "Auto Skills" })

MiscTab:CreateToggle({
    Name = "Auto Skill Z", Flag = "AutoSkillZ", CurrentValue = _G.SlowHub.AutoSkillZ,
    Callback = function(v) OnToggleChange("AutoSkillZ", v) end,
})
MiscTab:CreateToggle({
    Name = "Auto Skill X", Flag = "AutoSkillX", CurrentValue = _G.SlowHub.AutoSkillX,
    Callback = function(v) OnToggleChange("AutoSkillX", v) end,
})
MiscTab:CreateToggle({
    Name = "Auto Skill C", Flag = "AutoSkillC", CurrentValue = _G.SlowHub.AutoSkillC,
    Callback = function(v) OnToggleChange("AutoSkillC", v) end,
})
MiscTab:CreateToggle({
    Name = "Auto Skill V", Flag = "AutoSkillV", CurrentValue = _G.SlowHub.AutoSkillV,
    Callback = function(v) OnToggleChange("AutoSkillV", v) end,
})
MiscTab:CreateToggle({
    Name = "Auto Skill F", Flag = "AutoSkillF", CurrentValue = _G.SlowHub.AutoSkillF,
    Callback = function(v) OnToggleChange("AutoSkillF", v) end,
})

MiscTab:CreateSlider({
    Name = "Skill Interval", Flag = "SkillInterval",
    Range = { 0.05, 1 }, Increment = 0.05,
    CurrentValue = _G.SlowHub.SkillInterval,
    Callback = function(value)
        _G.SlowHub.SkillInterval = value
        saveConfig("SkillInterval", value)
    end,
})

if IsAnySkillActive() then
    task.spawn(function() task.wait(1); StartSkillLoop() end)
end
