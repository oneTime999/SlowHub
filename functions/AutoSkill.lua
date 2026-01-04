local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- AUTO SKILL CONFIG
if not _G.SlowHub.AutoSkillZ then
    _G.SlowHub.AutoSkillZ = false
end
if not _G.SlowHub.AutoSkillX then
    _G.SlowHub.AutoSkillX = false
end
if not _G.SlowHub.AutoSkillC then
    _G.SlowHub.AutoSkillC = false
end
if not _G.SlowHub.AutoSkillV then
    _G.SlowHub.AutoSkillV = false
end

local autoSkillConnection = nil

-- FUNÇÕES AUTO SKILL
local function stopAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
        autoSkillConnection = nil
    end
end

local function startAutoSkill()
    if autoSkillConnection then
        stopAutoSkill()
    end
    
    autoSkillConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            -- RequestAbility (Z=1, X=2, C=3, V=4)
            if _G.SlowHub.AutoSkillZ then
                ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(1)
            end
            if _G.SlowHub.AutoSkillX then
                ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(2)
            end
            if _G.SlowHub.AutoSkillC then
                ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(3)
            end
            if _G.SlowHub.AutoSkillV then
                ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(4)
            end
            
            -- FruitPowerRemote (todos fruits + keys selecionados)
            local fruits = {"Light", "Flame", "Quake"}
            local keys = {}
            if _G.SlowHub.AutoSkillZ then table.insert(keys, "Z") end
            if _G.SlowHub.AutoSkillX then table.insert(keys, "X") end
            if _G.SlowHub.AutoSkillC then table.insert(keys, "C") end
            if _G.SlowHub.AutoSkillV then table.insert(keys, "V") end
            
            for _, fruit in ipairs(fruits) do
                for _, key in ipairs(keys) do
                    ReplicatedStorage.RemoteEvents.FruitPowerRemote:FireServer("UseAbility", {
                        KeyCode = Enum.KeyCode[key],
                        FruitPower = fruit
                    })
                end
            end
        end)
    end)
end

-- UI AUTO SKILL TOGGLES
Tab:CreateToggle({
    Name = "Auto Skill Z",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillZ = value
        if value or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Skill X",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillX = value
        if value or _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Skill C",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillC = value
        if value or _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillV then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Skill V",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillV = value
        if value or _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

Tab:CreateButton({
    Name = "Stop All Skills",
    Callback = function()
        _G.SlowHub.AutoSkillZ = false
        _G.SlowHub.AutoSkillX = false
        _G.SlowHub.AutoSkillC = false
        _G.SlowHub.AutoSkillV = false
        stopAutoSkill()
    end
})

-- AUTO-START
if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV then
    startAutoSkill()
end
