local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

if not _G.SlowHub.AutoSkillZ then _G.SlowHub.AutoSkillZ = false end
if not _G.SlowHub.AutoSkillX then _G.SlowHub.AutoSkillX = false end
if not _G.SlowHub.AutoSkillC then _G.SlowHub.AutoSkillC = false end
if not _G.SlowHub.AutoSkillV then _G.SlowHub.AutoSkillV = false end
if not _G.SlowHub.AutoSkillF then _G.SlowHub.AutoSkillF = false end

local skillLoopRunning = false

local function anySkillActive()
    return _G.SlowHub.AutoSkillZ or _G.SlowHub.AutoSkillX or _G.SlowHub.AutoSkillC
        or _G.SlowHub.AutoSkillV or _G.SlowHub.AutoSkillF
end

local function startSkillLoop()
    if skillLoopRunning then return end
    skillLoopRunning = true

    task.spawn(function()
        while skillLoopRunning and anySkillActive() do
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

                -- Fruit powers
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

            task.wait(0.2) -- Throttle: 5x por segundo, sem impacto nos outros scripts
        end

        skillLoopRunning = false
    end)
end

local function stopSkillLoop()
    skillLoopRunning = false
end

local function onToggleChange(flag, value)
    _G.SlowHub[flag] = value
    if value then
        startSkillLoop()
    elseif not anySkillActive() then
        stopSkillLoop()
    end
    if _G.SaveConfig then _G.SaveConfig() end
end

Tab:CreateToggle({
    Name = "Auto Skill Z",
    CurrentValue = _G.SlowHub.AutoSkillZ,
    Flag = "AutoSkillZ",
    Callback = function(value) onToggleChange("AutoSkillZ", value) end
})

Tab:CreateToggle({
    Name = "Auto Skill X",
    CurrentValue = _G.SlowHub.AutoSkillX,
    Flag = "AutoSkillX",
    Callback = function(value) onToggleChange("AutoSkillX", value) end
})

Tab:CreateToggle({
    Name = "Auto Skill C",
    CurrentValue = _G.SlowHub.AutoSkillC,
    Flag = "AutoSkillC",
    Callback = function(value) onToggleChange("AutoSkillC", value) end
})

Tab:CreateToggle({
    Name = "Auto Skill V",
    CurrentValue = _G.SlowHub.AutoSkillV,
    Flag = "AutoSkillV",
    Callback = function(value) onToggleChange("AutoSkillV", value) end
})

Tab:CreateToggle({
    Name = "Auto Skill F",
    CurrentValue = _G.SlowHub.AutoSkillF,
    Flag = "AutoSkillF",
    Callback = function(value) onToggleChange("AutoSkillF", value) end
})

-- Auto-start se configs salvas estiverem ativas
if anySkillActive() then
    startSkillLoop()
end
