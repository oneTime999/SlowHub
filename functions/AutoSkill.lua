local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

if not _G.SlowHub.AutoSkillZ then _G.SlowHub.AutoSkillZ = false end
if not _G.SlowHub.AutoSkillX then _G.SlowHub.AutoSkillX = false end
if not _G.SlowHub.AutoSkillC then _G.SlowHub.AutoSkillC = false end
if not _G.SlowHub.AutoSkillV then _G.SlowHub.AutoSkillV = false end
if not _G.SlowHub.AutoSkillF then _G.SlowHub.AutoSkillF = false end

local autoSkillConnection = nil

local function updateAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
    end
    
    if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
        autoSkillConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
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
                if _G.SlowHub.AutoSkillF then
                    ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(5)
                end
                
                local fruits = {"Light", "Flame", "Quake"}
                local keys = {}
                if _G.SlowHub.AutoSkillZ then table.insert(keys, "Z") end
                if _G.SlowHub.AutoSkillX then table.insert(keys, "X") end
                if _G.SlowHub.AutoSkillC then table.insert(keys, "C") end
                if _G.SlowHub.AutoSkillV then table.insert(keys, "V") end
                
                if #keys > 0 then
                    for _, fruit in ipairs(fruits) do
                        for _, key in ipairs(keys) do
                            ReplicatedStorage.RemoteEvents.FruitPowerRemote:FireServer("UseAbility", {
                                KeyCode = Enum.KeyCode[key],
                                FruitPower = fruit
                            })
                        end
                    end
                end
            end)
        end)
    end
end

local ToggleZ = Tab:CreateToggle({
    Name = "Auto Skill Z",
    CurrentValue = false,
    Flag = "AutoSkillZ",
    Callback = function(value)
        _G.SlowHub.AutoSkillZ = value
        updateAutoSkill()
    end
})

local ToggleX = Tab:CreateToggle({
    Name = "Auto Skill X",
    CurrentValue = false,
    Flag = "AutoSkillX",
    Callback = function(value)
        _G.SlowHub.AutoSkillX = value
        updateAutoSkill()
    end
})

local ToggleC = Tab:CreateToggle({
    Name = "Auto Skill C",
    CurrentValue = false,
    Flag = "AutoSkillC",
    Callback = function(value)
        _G.SlowHub.AutoSkillC = value
        updateAutoSkill()
    end
})

local ToggleV = Tab:CreateToggle({
    Name = "Auto Skill V",
    CurrentValue = false,
    Flag = "AutoSkillV",
    Callback = function(value)
        _G.SlowHub.AutoSkillV = value
        updateAutoSkill()
    end
})

local ToggleF = Tab:CreateToggle({
    Name = "Auto Skill F",
    CurrentValue = false,
    Flag = "AutoSkillF",
    Callback = function(value)
        _G.SlowHub.AutoSkillF = value
        updateAutoSkill()
    end
})

if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
    updateAutoSkill()
end
