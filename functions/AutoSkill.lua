local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- AUTO SKILL CONFIG
if not _G.SlowHub.AutoSkillZ then _G.SlowHub.AutoSkillZ = false end
if not _G.SlowHub.AutoSkillX then _G.SlowHub.AutoSkillX = false end
if not _G.SlowHub.AutoSkillC then _G.SlowHub.AutoSkillC = false end
if not _G.SlowHub.AutoSkillV then _G.SlowHub.AutoSkillV = false end
-- Adicionado Skill F
if not _G.SlowHub.AutoSkillF then _G.SlowHub.AutoSkillF = false end

local autoSkillConnection = nil

local function updateAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
    end
    
    -- Verifica se qualquer skill (incluindo F) está ativa
    if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
        autoSkillConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
                -- RequestAbility (Z=1, X=2, C=3, V=4, F=5)
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
                -- Adicionado disparo da Skill F (Somente RequestAbility)
                if _G.SlowHub.AutoSkillF then
                    ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(5)
                end
                
                -- FruitPowerRemote (Z, X, C, V apenas, F ignorado aqui conforme pedido)
                local fruits = {"Light", "Flame", "Quake"}
                local keys = {}
                if _G.SlowHub.AutoSkillZ then table.insert(keys, "Z") end
                if _G.SlowHub.AutoSkillX then table.insert(keys, "X") end
                if _G.SlowHub.AutoSkillC then table.insert(keys, "C") end
                if _G.SlowHub.AutoSkillV then table.insert(keys, "V") end
                
                -- Loop apenas para frutas (F não entra aqui)
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

-- UI AUTO SKILL TOGGLES
local ToggleZ = Tab:AddToggle("AutoSkillZ", {
    Title = "Auto Skill Z",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillZ = value
        updateAutoSkill()
    end
})

local ToggleX = Tab:AddToggle("AutoSkillX", {
    Title = "Auto Skill X",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillX = value
        updateAutoSkill()
    end
})

local ToggleC = Tab:AddToggle("AutoSkillC", {
    Title = "Auto Skill C",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillC = value
        updateAutoSkill()
    end
})

local ToggleV = Tab:AddToggle("AutoSkillV", {
    Title = "Auto Skill V",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillV = value
        updateAutoSkill()
    end
})

-- Adicionado Toggle Skill F
local ToggleF = Tab:AddToggle("AutoSkillF", {
    Title = "Auto Skill F",
    Default = false,
    Callback = function(value)
        _G.SlowHub.AutoSkillF = value
        updateAutoSkill()
    end
})

-- AUTO-START CHECK
if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
    updateAutoSkill()
end
