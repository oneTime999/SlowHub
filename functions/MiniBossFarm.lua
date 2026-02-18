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
    ["ThiefBoss"]     = CFrame.new(-66.633, -2.584, -162.471),
    ["MonkeyBoss"]    = CFrame.new(-494.757, 49.211, 496.788),
    ["DesertBoss"]    = CFrame.new(-972.217, 2.346, -475.585),
    ["SnowBoss"]      = CFrame.new(-584.578, 29.429, -1143.482),
    ["PandaMiniBoss"] = CFrame.new(1697.134, 9.572, 518.390)
}

if not _G.SlowHub.MiniBossFarmDistance then _G.SlowHub.MiniBossFarmDistance = 6 end
if not _G.SlowHub.MiniBossFarmHeight then _G.SlowHub.MiniBossFarmHeight = 4 end

local autoFarmMiniBossConnection = nil
local questConnection = nil
local selectedMiniBoss = _G.SlowHub.SelectedMiniBoss or nil
local isRunning = false
local lastTargetName = nil
local hasVisitedSafeZone = false
local wasAttackingBoss = false

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
    pcall(function()
        local character = Player.Character
        local backpack = Player:FindFirstChild("Backpack")
        if character and character:FindFirstChild("Humanoid") then
             if not character:FindFirstChild(_G.SlowHub.SelectedWeapon) and backpack then
                local tool = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
                if tool then character.Humanoid:EquipTool(tool) end
             end
        end
    end)
end

local function stopAutoFarmMiniBoss()
    isRunning = false
    lastTargetName = nil
    hasVisitedSafeZone = false
    wasAttackingBoss = false
    
    if autoFarmMiniBossConnection then
        autoFarmMiniBossConnection:Disconnect()
        autoFarmMiniBossConnection = nil
    end
    
    if questConnection then
        questConnection:Disconnect()
        questConnection = nil
    end
    
    _G.SlowHub.AutoFarmMiniBosses = false
end

local function startAutoFarmMiniBoss()
    if isRunning then stopAutoFarmMiniBoss() task.wait(0.3) end
    
    if not selectedMiniBoss or not MiniBossConfig[selectedMiniBoss] then return end
    local config = MiniBossConfig[selectedMiniBoss]

    isRunning = true
    _G.SlowHub.AutoFarmMiniBosses = true
    wasAttackingBoss = false
    
    questConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then return end
        if not _G.SlowHub.IsAttackingBoss then
            pcall(function()
                ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
            end)
        end
    end)
    
    local lastAttack = 0
    autoFarmMiniBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then
            stopAutoFarmMiniBoss()
            return
        end
        
        if _G.SlowHub.IsAttackingBoss then
            wasAttackingBoss = true
            return
        end

        if wasAttackingBoss then
            hasVisitedSafeZone = false
            wasAttackingBoss = false
        end
        
        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end
        
        if selectedMiniBoss ~= lastTargetName then
            lastTargetName = selectedMiniBoss
            hasVisitedSafeZone = false
        end

        if not hasVisitedSafeZone then
            local safeCFrame = MiniBossSafeZones[selectedMiniBoss]
            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true
                return
            else
                hasVisitedSafeZone = true
            end
        end

        local miniBoss = workspace.NPCs:FindFirstChild(selectedMiniBoss)
        if miniBoss and miniBoss:FindFirstChild("Humanoid") and miniBoss.Humanoid.Health > 0 then
             local bossRoot = miniBoss:FindFirstChild("HumanoidRootPart")
             if bossRoot then
                pcall(function()
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    local targetCFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.MiniBossFarmHeight, _G.SlowHub.MiniBossFarmDistance)
                    playerRoot.CFrame = targetCFrame
                    
                    EquipWeapon()
                    
                    if (tick() - lastAttack) > 0.15 then
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                        lastAttack = tick()
                    end
                end)
             end
        end
    end)
end

Tab:CreateSection("Mini Bosses")

Tab:CreateDropdown({
    Name = "Select Mini Boss",
    Options = miniBossList,
    CurrentOption = _G.SlowHub.SelectedMiniBoss or "",
    MultipleOptions = false,
    Flag = "SelectMiniBoss",
    Callback = function(Value)
        local wasRunning = isRunning
        if wasRunning then stopAutoFarmMiniBoss() end
        
        selectedMiniBoss = (type(Value) == "table" and Value[1]) or Value
        _G.SlowHub.SelectedMiniBoss = selectedMiniBoss
        
        if wasRunning then 
            task.wait(0.3)
            startAutoFarmMiniBoss() 
        end
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Mini Boss",
    CurrentValue = _G.SlowHub.AutoFarmMiniBosses or false,
    Flag = "AutoFarmMiniBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                Rayfield:Notify({Title = "Error", Content = "Please select a weapon!", Duration = 3, Image = 4483362458})
                return
            end
            if not selectedMiniBoss or selectedMiniBoss == "" then
                 Rayfield:Notify({Title = "Error", Content = "Please select a Mini Boss!", Duration = 3, Image = 4483362458})
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

Tab:CreateSlider({
    Name = "Mini Boss Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.MiniBossFarmDistance,
    Flag = "MiniBossDistance",
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSlider({
    Name = "Mini Boss Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.MiniBossFarmHeight,
    Flag = "MiniBossHeight",
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
