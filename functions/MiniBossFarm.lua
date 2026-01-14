local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Tab = _G.BossesTab

local MiniBossConfig = {
    ["ThiefBoss"] = {quest = "QuestNPC2"},
    ["MonkeyBoss"] = {quest = "QuestNPC4"},
    ["DesertBoss"] = {quest = "QuestNPC6"},
    ["SnowBoss"] = {quest = "QuestNPC8"},
    ["PandaMiniBoss"] = {quest = "QuestNPC10"}
}

local miniBossList = {"ThiefBoss", "MonkeyBoss", "DesertBoss", "SnowBoss", "PandaMiniBoss"}

local MiniBossSafeZones = {
    ["ThiefBoss"]     = CFrame.new(-94.74494171142578, -1.985839605331421, -244.80184936523438),
    ["MonkeyBoss"]    = CFrame.new(-446.5873107910156, -3.560742139816284, 368.79754638671875),
    ["DesertBoss"]    = CFrame.new(-768.9750366210938, -2.1328823566436768, -361.69775390625),
    ["SnowBoss"]      = CFrame.new(-223.8474884033203, -1.8019909858703613, -1062.9384765625),
    ["PandaMiniBoss"] = CFrame.new(1359.4720458984375, 10.515644073486328, 249.58221435546875)
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

local autoFarmMiniBossConnection = nil
local questConnection = nil
local selectedMiniBoss = nil
local isRunning = false
local lastTargetName = nil
local hasVisitedSafeZone = false
local activeBoss = nil
local isBossMode = false

if not _G.SlowHub.MiniBossFarmDistance then _G.SlowHub.MiniBossFarmDistance = 6 end
if not _G.SlowHub.MiniBossFarmHeight then _G.SlowHub.MiniBossFarmHeight = 4 end
if not _G.SlowHub.SelectedBosses then _G.SlowHub.SelectedBosses = {} end

local function getConfig()
    if not selectedMiniBoss then return nil end
    return MiniBossConfig[selectedMiniBoss]
end

local function getMiniBoss()
    if not selectedMiniBoss then return nil end
    return workspace.NPCs:FindFirstChild(selectedMiniBoss)
end

local function getMiniBossRootPart(miniBoss)
    if miniBoss and miniBoss:FindFirstChild("HumanoidRootPart") then
        return miniBoss.HumanoidRootPart
    end
    return nil
end

local function getNewBossTarget()
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

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    local success = pcall(function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = Player.Character
        
        if not character or not character:FindFirstChild("Humanoid") then return false end
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then return true end
        
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

local function stopAutoFarmMiniBoss()
    isRunning = false
    lastTargetName = nil
    hasVisitedSafeZone = false
    activeBoss = nil
    isBossMode = false
    
    if autoFarmMiniBossConnection then
        autoFarmMiniBossConnection:Disconnect()
        autoFarmMiniBossConnection = nil
    end
    
    if questConnection then
        questConnection:Disconnect()
        questConnection = nil
    end
    
    _G.SlowHub.AutoFarmMiniBosses = false
    
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

local function startAutoFarmMiniBoss()
    if isRunning then
        stopAutoFarmMiniBoss()
        task.wait(0.3)
    end
    
    local config = getConfig()
    if not config then return end

    isRunning = true
    _G.SlowHub.AutoFarmMiniBosses = true
    activeBoss = nil
    
    questConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then return end
        
        if not isBossMode then
            pcall(function()
                ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
            end)
        end
    end)
    
    EquipWeapon()
    
    local lastAttack = 0
    
    autoFarmMiniBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then
            stopAutoFarmMiniBoss()
            return
        end
        
        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end
        
        local now = tick()
        
        if activeBoss then
            if not activeBoss.Parent or not activeBoss:FindFirstChild("Humanoid") or activeBoss.Humanoid.Health <= 0 then
                activeBoss = nil
            end
        end
        
        if not activeBoss then
            activeBoss = getNewBossTarget()
            if activeBoss then
                hasVisitedSafeZone = false
            end
        end
        
        if activeBoss then
            isBossMode = true
            
            if lastTargetName ~= activeBoss.Name then
                lastTargetName = activeBoss.Name
                hasVisitedSafeZone = false
            end
            
            if not hasVisitedSafeZone then
                local safeCFrame = BossSafeZones[activeBoss.Name]
                if safeCFrame then
                    playerRoot.CFrame = safeCFrame
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                    hasVisitedSafeZone = true
                    return
                else
                    hasVisitedSafeZone = true
                end
            end
            
            local bossRoot = activeBoss:FindFirstChild("HumanoidRootPart")
            if bossRoot then
                local targetCFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.MiniBossFarmHeight, _G.SlowHub.MiniBossFarmDistance)
                playerRoot.CFrame = targetCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0,0,0)
                
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
        
        if selectedMiniBoss ~= lastTargetName then
            lastTargetName = selectedMiniBoss
            hasVisitedSafeZone = false
        end

        if not hasVisitedSafeZone then
            local safeCFrame = MiniBossSafeZones[selectedMiniBoss]
            if safeCFrame and safeCFrame.Position ~= Vector3.new(0,0,0) then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    playerRoot.CFrame = safeCFrame
                end)
                hasVisitedSafeZone = true
                return
            else
                hasVisitedSafeZone = true
            end
        end

        local miniBoss = getMiniBoss()
        
        if miniBoss and miniBoss.Parent then
            local bossHumanoid = miniBoss:FindFirstChild("Humanoid")
            
            if bossHumanoid and bossHumanoid.Health <= 0 then return end
            
            local bossRoot = getMiniBossRootPart(miniBoss)
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if bossRoot and bossRoot.Parent and humanoid and humanoid.Health > 0 then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    
                    local targetCFrame = bossRoot.CFrame
                    local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.MiniBossFarmHeight, _G.SlowHub.MiniBossFarmDistance)
                    
                    local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                    if distance > 3 or distance < 1 then
                        playerRoot.CFrame = offsetPosition
                    end
                    
                    EquipWeapon()
                    
                    if (now - lastAttack) > 0.15 then
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                        lastAttack = now
                    end
                end)
            end
        end
    end)
end

local Dropdown = Tab:AddDropdown("SelectMiniBoss", {
    Title = "Select Mini Boss",
    Values = miniBossList,
    Default = nil,
    Callback = function(Value)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmMiniBoss()
            task.wait(0.3)
        end
        
        selectedMiniBoss = tostring(Value)
        
        if wasRunning then
            startAutoFarmMiniBoss()
        end
    end
})

local Toggle = Tab:AddToggle("AutoFarmMiniBoss", {
    Title = "Auto Farm Mini Boss",
    Default = _G.SlowHub.AutoFarmMiniBosses or false,
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Fluent:Notify({Title = "Error", Content = "Select a weapon!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end

            if not selectedMiniBoss then
                _G.Fluent:Notify({Title = "Error", Content = "Select a Mini Boss first!", Duration = 3})
                if Toggle then Toggle:SetValue(false) end
                return
            end
            
            startAutoFarmMiniBoss()
        else
            stopAutoFarmMiniBoss()
        end
        
        _G.SlowHub.AutoFarmMiniBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

local DistanceSlider = Tab:AddSlider("MiniBossDistance", {
    Title = "Mini Boss Distance (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.MiniBossFarmDistance,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

local HeightSlider = Tab:AddSlider("MiniBossHeight", {
    Title = "Mini Boss Height (studs)",
    Min = 1,
    Max = 10,
    Default = _G.SlowHub.MiniBossFarmHeight,
    Rounding = 0,
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

if _G.SlowHub.AutoFarmMiniBosses and _G.SlowHub.SelectedWeapon and selectedMiniBoss then
    task.wait(2)
    startAutoFarmMiniBoss()
end
