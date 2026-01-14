local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 99999, quest = "QuestNPC11", npc = "Hollow", count = 5}
}

local NPCSafeZones = {
    ["Thief"] = CFrame.new(-94.74494171142578, -1.985839605331421, -244.80184936523438),
    ["Monkey"] = CFrame.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["DesertBandit"] = CFrame.new(-768.9750366210938, -2.1328823566436768, -361.69775390625),
    ["FrostRogue"] = CFrame.new(-223.8474884033203, -1.8019909858703613, -1062.9384765625),
    ["Sorcerer"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["Hollow"] = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875)
}

local autoLevelConnection = nil
local questLoopActive = false
local currentNPCIndex = 1
local lastTargetNPCName = nil
local hasVisitedSafeZone = false
local farmPausedByBoss = false

if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local function GetPlayerLevel()
    local success, level = pcall(function()
        return Player.Data.Level.Value
    end)
    return success and level or 1
end

local function GetCurrentConfig()
    local level = GetPlayerLevel()
    for _, config in pairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then
            return config
        end
    end
    return LevelConfig[1]
end

local function getNextNPC(current, maxCount)
    local next = current + 1
    if next > maxCount then return 1 end
    return next
end

local function getNPC(npcName, index)
    return workspace.NPCs:FindFirstChild(npcName .. index)
end

local function getNPCRootPart(npc)
    if npc and npc:FindFirstChild("HumanoidRootPart") then
        return npc.HumanoidRootPart
    end
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        if character and character:FindFirstChild("Humanoid") then
            if not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
                local weapon = backpack and backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if weapon then
                    character.Humanoid:EquipTool(weapon)
                end
            end
        end
    end)
end

local function IsAnyBossAlive()
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local boss = workspace.NPCs:FindFirstChild(bossName)
            if boss then
                local hum = boss:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    return true
                end
            end
        end
    end
    return false
end

local function stopAutoLevel()
    if autoLevelConnection then
        autoLevelConnection:Disconnect()
        autoLevelConnection = nil
    end
    questLoopActive = false
    currentNPCIndex = 1
    lastTargetNPCName = nil
    hasVisitedSafeZone = false
    pcall(function()
        if Player.Character then
            local root = Player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.new(0,0,0)
                root.Anchored = false
            end
        end
    end)
end

local function startQuestLoop()
    if questLoopActive then return end
    questLoopActive = true
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmLevel do
            local config = GetCurrentConfig()
            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
            task.wait(2)
        end
    end)
end

local function startAutoLevel()
    if autoLevelConnection then stopAutoLevel() end
    _G.SlowHub.AutoFarmLevel = true
    currentNPCIndex = 1
    startQuestLoop()
    EquipWeapon()
    local lastNPCSwitch = 0
    local lastAttack = 0

    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then
            stopAutoLevel()
            return
        end

        if _G.SlowHub.AutoFarmBosses and IsAnyBossAlive() then
            farmPausedByBoss = true
            stopAutoLevel()
            return
        end

        local config = GetCurrentConfig()
        local now = tick()

        if config.npc ~= lastTargetNPCName then
            lastTargetNPCName = config.npc
            hasVisitedSafeZone = false
        end

        local root = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        if not hasVisitedSafeZone then
            local safe = NPCSafeZones[config.npc]
            if safe then
                root.CFrame = safe
                hasVisitedSafeZone = true
                return
            end
            hasVisitedSafeZone = true
        end

        local npc = getNPC(config.npc, currentNPCIndex)
        local alive = npc and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0

        if not alive then
            if now - lastNPCSwitch > 0 then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
            end
            return
        end

        local npcRoot = getNPCRootPart(npc)
        local humanoid = Player.Character:FindFirstChild("Humanoid")

        if npcRoot and humanoid and humanoid.Health > 0 then
            local target = npcRoot.CFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
            root.CFrame = target
            EquipWeapon()
            if now - lastAttack > 0.15 then
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                lastAttack = now
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if farmPausedByBoss and _G.SlowHub.AutoFarmBosses and not IsAnyBossAlive() then
        farmPausedByBoss = false
        if _G.SlowHub.AutoFarmLevel then
            startAutoLevel()
        end
    end
end)

local Toggle = Tab:AddToggle("AutoFarmLevel", {
    Title = "Auto Farm Level",
    Default = _G.SlowHub.AutoFarmLevel,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Fluent:Notify({Title="Error",Content="Select a weapon first",Duration=3})
                Toggle:SetValue(false)
                return
            end
            startAutoLevel()
        else
            stopAutoLevel()
        end
        _G.SlowHub.AutoFarmLevel = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

local DistanceSlider = Tab:AddSlider("FarmDistance", {
    Title = "Farm Distance",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.FarmDistance,
    Callback = function(v)
        _G.SlowHub.FarmDistance = v
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

local HeightSlider = Tab:AddSlider("FarmHeight", {
    Title = "Farm Height",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.FarmHeight,
    Callback = function(v)
        _G.SlowHub.FarmHeight = v
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoLevel()
end
