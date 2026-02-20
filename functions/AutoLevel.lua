local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MainTab = _G.MainTab

local LevelConfig = {
    {minLevel = 1, maxLevel = 249, quest = "QuestNPC1", npc = "Thief", count = 5},
    {minLevel = 250, maxLevel = 749, quest = "QuestNPC3", npc = "Monkey", count = 5},
    {minLevel = 750, maxLevel = 1499, quest = "QuestNPC5", npc = "DesertBandit", count = 5},
    {minLevel = 1500, maxLevel = 2999, quest = "QuestNPC7", npc = "FrostRogue", count = 5},
    {minLevel = 3000, maxLevel = 5499, quest = "QuestNPC9", npc = "Sorcerer", count = 5},
    {minLevel = 5500, maxLevel = 5999, quest = "QuestNPC11", npc = "Hollow", count = 5},
    -- Novas Quests Adicionadas:
    {minLevel = 6000, maxLevel = 6999, quest = "QuestNPC12", npc = "StrongSorcerer", count = 5},
    {minLevel = 7000, maxLevel = 7999, quest = "QuestNPC13", npc = "Curse", count = 5},
    {minLevel = 8000, maxLevel = 99999, quest = "QuestNPC14", npc = "Slime", count = 5}
}

local NPCSafeZones = {
    ["Thief"]           = CFrame.new(177.723145, 11.2069092, -157.246826),
    ["Monkey"]          = CFrame.new(-567.758667, -0.8746683, 399.302979),
    ["DesertBandit"]    = CFrame.new(-867.638245, -4.22272682, -446.67868),
    ["FrostRogue"]      = CFrame.new(-398.725769, -1.13884699, -1071.56885),
    ["Sorcerer"]        = CFrame.new(1398.2594, 8.48633194, 488.058838),
    ["Hollow"]          = CFrame.new(-365.12628173828125, -0.44140613079071045, 1097.683349609375),
    -- Novas Coordenadas Adicionadas:
    ["StrongSorcerer"] = CFrame.new(637.979126, 2.375789, -1669.440186),
    ["Curse"]          = CFrame.new(-69.846375, 1.907236, -1857.250244),
    ["Slime"]          = CFrame.new(-1124.753173828125, 19.703411102294922, 371.2305908203125)
}

if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

_G.SlowHub.IsAttackingBoss = false

local autoLevelConnection = nil
local questLoopActive = false
local currentNPCIndex = 1
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false

local function GetPlayerLevel()
    local success, level = pcall(function() return Player.Data.Level.Value end)
    return success and level or 1
end

local function GetCurrentConfig()
    local level = GetPlayerLevel()
    for _, config in pairs(LevelConfig) do
        if level >= config.minLevel and level <= config.maxLevel then return config end
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

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    pcall(function()
        local character = Player.Character
        if character and character:FindFirstChild("Humanoid") and not character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            local backpack = Player:FindFirstChild("Backpack")
            if backpack then
                local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if weapon then character.Humanoid:EquipTool(weapon) end
            end
        end
    end)
end

local function stopAutoLevel()
    if autoLevelConnection then
        autoLevelConnection:Disconnect()
        autoLevelConnection = nil
    end
    questLoopActive = false
    _G.SlowHub.AutoFarmLevel = false
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function startQuestLoop()
    if questLoopActive then return end
    questLoopActive = true
    task.spawn(function()
        while questLoopActive and _G.SlowHub.AutoFarmLevel do
            if not _G.SlowHub.IsAttackingBoss then
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
    lastTargetName = nil
    hasVisitedSafeZone = false
    wasAttackingBoss = false
    
    startQuestLoop()
    
    local lastNPCSwitch = 0
    local lastAttack = 0
    
    autoLevelConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmLevel then stopAutoLevel() return end
        
        if _G.SlowHub.IsAttackingBoss then
            wasAttackingBoss = true
            return 
        end

        if wasAttackingBoss then
            hasVisitedSafeZone = false
            wasAttackingBoss = false
        end

        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        if not playerRoot or not humanoid or humanoid.Health <= 0 then return end
        
        local now = tick()
        local config = GetCurrentConfig()
        
        if lastTargetName ~= config.npc then
            lastTargetName = config.npc
            hasVisitedSafeZone = false
        end
        
        if not hasVisitedSafeZone then
            local safeCFrame = NPCSafeZones[config.npc]
            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true
                return
            else
                hasVisitedSafeZone = true
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

MainTab:CreateToggle({
    Name = "Auto Farm Level",
    CurrentValue = _G.SlowHub.AutoFarmLevel,
    Flag = "AutoFarmLevel",
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Select a weapon first!",
                    Duration = 3,
                    Image = 4483362458
                })
                return
            end
            startAutoLevel()
        else
            stopAutoLevel()
        end
    end
})

MainTab:CreateSlider({
    Name = "Farm Distance",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmDistance,
    Flag = "FarmDistance",
    Callback = function(Value)
        _G.SlowHub.FarmDistance = Value
    end
})

MainTab:CreateSlider({
    Name = "Farm Height",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = _G.SlowHub.FarmHeight,
    Flag = "FarmHeight",
    Callback = function(Value)
        _G.SlowHub.FarmHeight = Value
    end
})

if _G.SlowHub.AutoFarmLevel and _G.SlowHub.SelectedWeapon then
    task.wait(1)
    startAutoLevel()
end
