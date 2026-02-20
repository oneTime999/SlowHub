local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

if not _G.SlowHub.AutoSkillZ then _G.SlowHub.AutoSkillZ = false end
if not _G.SlowHub.AutoSkillX then _G.SlowHub.AutoSkillX = false end
if not _G.SlowHub.AutoSkillC then _G.SlowHub.AutoSkillC = false end
if not _G.SlowHub.AutoSkillV then _G.SlowHub.AutoSkillV = false end
if not _G.SlowHub.AutoSkillF then _G.SlowHub.AutoSkillF = false end

local autoSkillConnection = nil
local lastSkillTime = {Z = 0, X = 0, C = 0, V = 0, F = 0}
local SKILL_COOLDOWN = 0.5
local FRUIT_COOLDOWN = 1.0
local lastFruitTime = 0

local function updateAutoSkill()
    if autoSkillConnection then
        autoSkillConnection:Disconnect()
        autoSkillConnection = nil
    end
    
    if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
        autoSkillConnection = task.spawn(function()
            while _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF do
                local currentTime = tick()
                
                pcall(function()
                    if _G.SlowHub.AutoSkillZ and (currentTime - lastSkillTime.Z) >= SKILL_COOLDOWN then
                        ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(1)
                        lastSkillTime.Z = currentTime
                    end
                    
                    if _G.SlowHub.AutoSkillX and (currentTime - lastSkillTime.X) >= SKILL_COOLDOWN then
                        ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(2)
                        lastSkillTime.X = currentTime
                    end
                    
                    if _G.SlowHub.AutoSkillC and (currentTime - lastSkillTime.C) >= SKILL_COOLDOWN then
                        ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(3)
                        lastSkillTime.C = currentTime
                    end
                    
                    if _G.SlowHub.AutoSkillV and (currentTime - lastSkillTime.V) >= SKILL_COOLDOWN then
                        ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(4)
                        lastSkillTime.V = currentTime
                    end
                    
                    if _G.SlowHub.AutoSkillF and (currentTime - lastSkillTime.F) >= SKILL_COOLDOWN then
                        ReplicatedStorage.AbilitySystem.Remotes.RequestAbility:FireServer(5)
                        lastSkillTime.F = currentTime
                    end
                end)
                
                if (currentTime - lastFruitTime) >= FRUIT_COOLDOWN then
                    pcall(function()
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
                    lastFruitTime = currentTime
                end
                
                task.wait(0.1)
            end
        end)
    end
end

Tab:CreateToggle({
    Name = "Auto Skill Z",
    CurrentValue = _G.SlowHub.AutoSkillZ,
    Flag = "AutoSkillZ",
    Callback = function(value)
        _G.SlowHub.AutoSkillZ = value
        updateAutoSkill()
    end
})

Tab:CreateToggle({
    Name = "Auto Skill X",
    CurrentValue = _G.SlowHub.AutoSkillX,
    Flag = "AutoSkillX",
    Callback = function(value)
        _G.SlowHub.AutoSkillX = value
        updateAutoSkill()
    end
})

Tab:CreateToggle({
    Name = "Auto Skill C",
    CurrentValue = _G.SlowHub.AutoSkillC,
    Flag = "AutoSkillC",
    Callback = function(value)
        _G.SlowHub.AutoSkillC = value
        updateAutoSkill()
    end
})

Tab:CreateToggle({
    Name = "Auto Skill V",
    CurrentValue = _G.SlowHub.AutoSkillV,
    Flag = "AutoSkillV",
    Callback = function(value)
        _G.SlowHub.AutoSkillV = value
        updateAutoSkill()
    end
})

Tab:CreateToggle({
    Name = "Auto Skill F",
    CurrentValue = _G.SlowHub.AutoSkillF,
    Flag = "AutoSkillF",
    Callback = function(value)
        _G.SlowHub.AutoSkillF = value
        updateAutoSkill()
    end
})

if _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF then
    task.wait(2)
    updateAutoSkill()
end
