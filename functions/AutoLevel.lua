local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

_G.SlowHub = _G.SlowHub or {}
_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end
if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local BossTab = _G.BossesTab
local MainTab = _G.MainTab

local bossList = {
    "AizenBoss",
    "QinShiBoss",
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss",
    "SaberBoss"
}

local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875),
    ["QinShiBoss"] = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["SaberBoss"]  = CFrame.new(667.6900024414062, -1.5378512144088745, -1125.218994140625),
    ["RagnaBoss"]  = CFrame.new(282.7808837890625, -2.7751426696777344, -1479.363525390625),
    ["JinwooBoss"] = CFrame.new(235.1376190185547, 3.1064343452453613, 659.7340698242188),
    ["SukunaBoss"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["GojoBoss"]   = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875)
}

local NPCSafeZones = {
    ["Thief"]        = CFrame.new(-94.74494171142578, -1.985839605331421, -244.80184936523438),
    ["Monkey"]       = CFrame.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["DesertBandit"] = CFrame.new(-768.9750366210938, -2.1328823566436768, -361.69775390625),
    ["FrostRogue"]   = CFrame.new(-223.8474884033203, -1.8019909858703613, -1062.9384765625),
    ["Sorcerer"]     = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875),
    ["Hollow"]       = CFrame.new(-482.868896484375, -2.0586609840393066, 936.237060546875)
}

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 99999, quest = "QuestNPC11", npc = "Hollow", count = 5}
}

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZoneBoss = false

local autoLevelConnection = nil
local questLoopActive = false
local currentNPCIndex = 1
local lastTargetName = nil
local hasVisitedSafeZoneLevel = false
local isBossMode = false
local activeBoss = nil

local function getAliveBoss()
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local boss = workspace.NPCs:FindFirstChild(bossName)
            if boss and boss.Parent then
                local humanoid = boss:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return boss
                end
            end
        end
    end
    return nil
end

local function getBossRootPart(boss)
    if boss and boss:FindFirstChild("HumanoidRootPart") then
        return boss.HumanoidRootPart
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local success = pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        
        if not character or not character:FindFirstChild("Humanoid") then
            return false
        end
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return true
        end
        
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
                task.wait(0.1)
            end
        end
    end)
    
    return success
end

local function stopAutoFarmBoss()
    isRunning = false
    lastTargetBoss = nil
    hasVisitedSafeZoneBoss = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    
    _G.SlowHub.AutoFarmBosses = false
    
    pcall(function()
        if Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.Anchored = false
            end
        end
    end)
end

local function startAutoFarmBoss()
    if isRunning then
        stopAutoFarmBoss()
        task.wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    EquipWeapon()
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getAliveBoss()
        
        if not boss then
            lastTargetBoss = nil
            hasVisitedSafeZoneBoss = false
            return 
        end
        
        local bossHumanoid = boss:FindFirstChild("Humanoid")
        if not bossHumanoid or bossHumanoid.Health <= 0 then
            return
        end
        
        if boss ~= lastTargetBoss then
            lastTargetBoss = boss
            hasVisitedSafeZoneBoss = false
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        if not hasVisitedSafeZoneBoss then
            local safeCFrame = BossSafeZones[boss.Name]
            if safeCFrame then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                hasVisitedSafeZoneBoss = true 
                return
            else
                hasVisitedSafeZoneBoss = true
            end
        end

        local bossRoot = getBossRootPart(boss)
        
        if bossRoot and bossRoot.Parent then
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    
                    local targetCFrame = bossRoot.CFrame
                    local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
                    
                    local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                    if distance > 3 or distance < 1 then
                        playerRoot.CFrame = offsetPosition
                    end
                    
                    EquipWeapon()
                    
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                end)
            end
        end
    end)
end

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

local function stopAutoLevel()
    if autoLevelConnection then
        autoLevelConnection:Disconnect()
        autoLevelConnection = nil
    end
    questLoopActive = false
    _G.SlowHub.AutoFarmLevel = false
    isBossMode = false
    activeBoss = nil
    lastTargetName = nil
    hasVisitedSafeZoneLevel = false
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
            Player.Character.HumanoidRootPart.Anchored = false
        end
    end)
end

local function startQuestLoop()
    if questLoopActive then return end
    questLoopActive = true
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmLevel do
            if not isBossMode then
                local config = GetCurrentConfig()
                pcall(function()
                    ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
                end)
            end
            task.wait(2)
        end
    end)
end

local function startAutoLevel()
    if autoLevelConnection then stopAutoLevel() end
    _G.SlowHub.AutoFarmLevel = true
    currentNPCIndex = 1
    activeBoss = nil
    lastTargetName = nil
    hasVisitedSafeZoneLevel = false
    startQuestLoop()
    local lastNPCSwitch = 0
    local lastAttack = 0
    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then stopAutoLevel() return end
        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        if not playerRoot or not humanoid or humanoid.Health <= 0 then return end
        local now = tick()
        
        if activeBoss then
            if not activeBoss.Parent or not activeBoss:FindFirstChild("Humanoid") or activeBoss.Humanoid.Health <= 0 then
                activeBoss = nil
            end
        end
        
        if not activeBoss then
            activeBoss = getAliveBoss()
        end
        
        if activeBoss then
            isBossMode = true
            if lastTargetName ~= activeBoss.Name then
                lastTargetName = activeBoss.Name
                hasVisitedSafeZoneLevel = false
            end
            if not hasVisitedSafeZoneLevel then
                local safeCFrame = BossSafeZones[activeBoss.Name]
                if safeCFrame then
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                    hasVisitedSafeZoneLevel = true
                    return
                else
                    hasVisitedSafeZoneLevel = true
                end
            end
            local bossRoot = activeBoss:FindFirstChild("HumanoidRootPart")
            if bossRoot then
                local targetCFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                playerRoot.CFrame = targetCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                EquipWeapon()
                if (now - lastAttack) > 0.15 then
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttack = now
                end
            end
            return
        else
            isBossMode = false
        end
        
        local config = GetCurrentConfig()
        if lastTargetName ~= config.npc then
            lastTargetName = config.npc
            hasVisitedSafeZoneLevel = false
        end
        if not hasVisitedSafeZoneLevel then
            local safeCFrame = NPCSafeZones[config.npc]
            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZoneLevel = true
                return
            else
                hasVisitedSafeZoneLevel = true
            end
        end
        local npc = getNPC(config.npc, currentNPCIndex)
        local npcAlive = npc and npc.Parent and npc:FindFirstChild("Humanoid") and npc.Humanoid.Health > 0
        if not npcAlive then
            if (now - lastNPCSwitch) > 0 then
                currentNPCIndex = getNextNPC(currentNPCIndex, config.count)
                lastNPCSwitch = now
            end
        else
            lastNPCSwitch = now
            local npcRoot = npc:FindFirstChild("HumanoidRootPart")
            if npcRoot then
                local targetCFrame = npcRoot.CFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                if (playerRoot.Position - targetCFrame.Position).Magnitude > 2 then
                    playerRoot.CFrame = targetCFrame
                end
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                EquipWeapon()
                if (now - lastAttack) > 0.15 then
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttack = now
                end
            end
        end
    end)
end

if BossTab then
    BossTab:AddParagraph({
        Title = "Select Bosses",
        Content = "Choose which bosses to farm"
    })

    for _, bossName in ipairs(bossList) do
        BossTab:AddToggle("SelectBoss_" .. bossName, {
            Title = bossName,
            Default = false,
            Callback = function(Value)
                _G.SlowHub.SelectedBosses[bossName] = Value
                
                if _G.SaveConfig then
                    _G.SaveConfig()
                end
            end
        })
    end

    BossTab:AddParagraph({
        Title = "Farm Control",
        Content = ""
    })

    local FarmToggle = BossTab:AddToggle("AutoFarmBoss", {
        Title = "Auto Farm Selected Bosses",
        Default = false,
        Callback = function(Value)
            if Value then
                if not _G.SlowHub.SelectedWeapon then
                    _G.SlowHub.AutoFarmBosses = false
                    if FarmToggle then
                        FarmToggle:SetValue(false)
                    end
                    _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                    return
                end
                
                local hasSelected = false
                for _, selected in pairs(_G.SlowHub.SelectedBosses) do
                    if selected then
                        hasSelected = true
                        break
                    end
                end
                
                if not hasSelected then
                    _G.SlowHub.AutoFarmBosses = false
                    if FarmToggle then
                        FarmToggle:SetValue(false)
                    end
                    _G.Fluent:Notify({Title = "Error", Content = "Select at least one Boss!", Duration = 3})
                    return
                end
                
                startAutoFarmBoss()
            else
                stopAutoFarmBoss()
            end
            
            _G.SlowHub.AutoFarmBosses = Value
            if _G.SaveConfig then
                _G.SaveConfig()
            end
        end
    })

    BossTab:AddSlider("BossFarmDistance", {
        Title = "Boss Farm Distance (studs)",
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmDistance,
        Rounding = 0,
        Callback = function(Value)
            _G.SlowHub.BossFarmDistance = Value
            
            if _G.SaveConfig then
                _G.SaveConfig()
            end
        end
    })

    BossTab:AddSlider("BossFarmHeight", {
        Title = "Boss Farm Height (studs)",
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmHeight,
        Rounding = 0,
        Callback = function(Value)
            _G.SlowHub.BossFarmHeight = Value
            
            if _G.SaveConfig then
                _G.SaveConfig()
            end
        end
    })
end

if MainTab then
    MainTab:AddToggle("AutoFarmLevel", {
        Title = "Auto Farm Level",
        Default = _G.SlowHub.AutoFarmLevel,
        Callback = function(Value)
            _G.SlowHub.AutoFarmLevel = Value
            if Value then
                if not _G.SlowHub.SelectedWeapon then
                    _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                    return
                end
                startAutoLevel()
            else
                stopAutoLevel()
            end
        end
    })

    MainTab:AddSlider("FarmDistance", {
        Title = "Farm Distance",
        Min = 1, Max = 10, Default = 8, Rounding = 0,
        Callback = function(Value) _G.SlowHub.FarmDistance = Value end
    })

    MainTab:AddSlider("FarmHeight", {
        Title = "Farm Height",
        Min = 1, Max = 10, Default = 4, Rounding = 0,
        Callback = function(Value) _G.SlowHub.FarmHeight = Value end
    })
end

if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    startAutoLevel()
end
