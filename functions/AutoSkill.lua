local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- AUTO SKILL CONFIG
if not _G.SlowHub.AutoSkillEnabled then
    _G.SlowHub.AutoSkillEnabled = false
end

if not _G.SlowHub.SkillDelay then
    _G.SlowHub.SkillDelay = 0.1
end

if not _G.SlowHub.SelectedAbilities then
    _G.SlowHub.SelectedAbilities = {1,2,3,4}
end

local autoSkillConnection = nil

-- FUNÇÕES AUTO SKILL
local function stopAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
        autoSkillConnection = nil
    end
    _G.SlowHub.AutoSkillEnabled = false
end

local function startAutoSkill()
    if autoSkillConnection then
        stopAutoSkill()
    end
    
    _G.SlowHub.AutoSkillEnabled = true
    
    autoSkillConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoSkillEnabled then
            stopAutoSkill()
            return
        end
        
        pcall(function()
            -- RequestAbility (Z=1, X=2, C=3, V=4)
            for _, abilityId in ipairs(_G.SlowHub.SelectedAbilities) do
                ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(abilityId)
            end
            
            -- FruitPowerRemote (Light/Flame/Quake - todos keys)
            local fruits = {"Light", "Flame", "Quake"}
            local keys = {"Z", "X", "C", "V"}
            
            for _, fruit in ipairs(fruits) do
                for _, key in ipairs(keys) do
                    local keyCode = Enum.KeyCode[key]
                    ReplicatedStorage.RemoteEvents.FruitPowerRemote:FireServer("UseAbility", {
                        KeyCode = keyCode,
                        FruitPower = fruit
                    })
                end
            end
        end)
        task.wait(_G.SlowHub.SkillDelay)
    end)
end

-- UI AUTO SKILL
Tab:CreateToggle({
    Name = "Auto Skill",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillEnabled = value
        if value then
            startAutoSkill()
        else
            stopAutoSkill()
        end
    end
})

Tab:CreateDropdown({
    Name = "Abilities",
    Default = "1",
    Options = {"1", "2", "3", "4"},
    Multi = true,
    Callback = function(value)
        _G.SlowHub.SelectedAbilities = value
    end
})

Tab:CreateSlider({
    Name = "Skill Delay",
    Min = 0,
    Max = 1,
    Default = 0.1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.01,
    Callback = function(value)
        _G.SlowHub.SkillDelay = value
    end
})

Tab:CreateButton({
    Name = "Stop Auto Skill",
    Callback = function()
        stopAutoSkill()
    end
})

-- AUTO-START
if _G.SlowHub.AutoSkillEnabled then
    startAutoSkill()
end
