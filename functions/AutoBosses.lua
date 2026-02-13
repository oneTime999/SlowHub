local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "StrongestofTodayBoss", "StrongestinHistoryBoss", "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["StrongestofTodayBoss"] = CFrame.new(181.69, 5.24, -2446.61),
    ["StrongestinHistoryBoss"] = CFrame.new(639.29, 3.67, -2273.30),
    ["IchigoBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["AizenBoss"]  = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"]  = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"]   = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"]   = CFrame.new(1537.92, 12.98, 226.10)
}

for _, bossBaseName in ipairs({"StrongestofTodayBoss", "StrongestinHistoryBoss"}) do
    if BossSafeZones[bossBaseName] then
        for _, diff in ipairs(difficulties) do
            BossSafeZones[bossBaseName .. diff] = BossSafeZones[bossBaseName]
        end
    end
end

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
_G.SlowHub.PityTargetBoss = _G.SlowHub.PityTargetBoss or ""
_G.SlowHub.PriorityPityEnabled = _G.SlowHub.PriorityPityEnabled or false
if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false

local function getPityCount()
    local success, pityText = pcall(function()
        local pityLabel = Player:WaitForChild("PlayerGui", 5):WaitForChild("BossUI", 5):WaitForChild("MainFrame", 5):WaitForChild("BossHPBar", 5):WaitForChild("Pity", 5)
        return pityLabel.Text
    end)
    
    if success and pityText then
        local currentPity = pityText:match("Pity: (%d+)/25")
        if currentPity then
            return tonumber(currentPity)
        end
    end
    return 0
end

local function checkHumanoid(model)
    if model and model.Parent then
        local humanoid = model:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return true
        end
    end
    return false
end

local function getAliveBoss()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return nil end
    
    local currentPity = getPityCount()
    local isPityTargetTime = (currentPity >= 24)
    
    if _G.SlowHub.PriorityPityEnabled and isPityTargetTime and _G.SlowHub.PityTargetBoss ~= "" then
        local targetBossName = _G.SlowHub.PityTargetBoss
        
        local exactBoss = npcs:FindFirstChild(targetBossName)
        if exactBoss and checkHumanoid(exactBoss) then
            return exactBoss
        end
        
        for _, diff in ipairs(difficulties) do
            local variantName = targetBossName .. diff
            local variantBoss = npcs:FindFirstChild(variantName)
            if variantBoss and checkHumanoid(variantBoss) then
                return variantBoss
            end
        end
        
        return nil
    end
    
    if _G.SlowHub.PriorityPityEnabled and not isPityTargetTime then
        for _, bossName in ipairs(bossList) do
            if bossName ~= _G.SlowHub.PityTargetBoss then
                local exactBoss = npcs:FindFirstChild(bossName)
                if exactBoss and checkHumanoid(exactBoss) then
                    return exactBoss
                end
                
                for _, diff in ipairs(difficulties) do
                    local variantName = bossName .. diff
                    local variantBoss = npcs:FindFirstChild(variantName)
                    if variantBoss and checkHumanoid(variantBoss) then
                        return variantBoss
                    end
                end
            end
        end
    end
    
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            local exactBoss = npcs:FindFirstChild(bossName)
            if exactBoss and checkHumanoid(exactBoss) then
                return exactBoss
            end

            for _, diff in ipairs(difficulties) do
                local variantName = bossName .. diff
                local variantBoss = npcs:FindFirstChild(variantName)
                if variantBoss and checkHumanoid(variantBoss) then
                    return variantBoss
                end
            end
        end
    end
    return nil
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return end
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

local function stopAutoFarmBoss()
    isRunning = false
    lastTargetBoss = nil
    hasVisitedSafeZone = false
    _G.SlowHub.IsAttackingBoss = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    _G.SlowHub.AutoFarmBosses = false
end

local function startAutoFarmBoss()
    if isRunning then stopAutoFarmBoss() task.wait(0.2) end
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getAliveBoss()
        
        if boss then
            _G.SlowHub.IsAttackingBoss = true
        else
            _G.SlowHub.IsAttackingBoss = false
            lastTargetBoss = nil
            hasVisitedSafeZone = false
            return 
        end

        if boss ~= lastTargetBoss then
            lastTargetBoss = boss
            hasVisitedSafeZone = false
        end

        local playerRoot = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        if not hasVisitedSafeZone then
            local safeCFrame = BossSafeZones[boss.Name]
            
            if not safeCFrame then
                for baseName, _ in pairs(_G.SlowHub.SelectedBosses) do
                    if string.find(boss.Name, baseName) then
                        safeCFrame = BossSafeZones[baseName]
                        break
                    end
                end
            end
            
            if not safeCFrame and _G.SlowHub.PityTargetBoss ~= "" then
                if string.find(boss.Name, _G.SlowHub.PityTargetBoss) then
                    safeCFrame = BossSafeZones[_G.SlowHub.PityTargetBoss]
                end
            end

            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true 
                return
            else
                hasVisitedSafeZone = true
            end
        end

        local bossRoot = boss:FindFirstChild("HumanoidRootPart")
        if bossRoot then
            pcall(function()
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                local targetCFrame = bossRoot.CFrame * CFrame.new(0, _G.SlowHub.BossFarmHeight, _G.SlowHub.BossFarmDistance)
                playerRoot.CFrame = targetCFrame
                
                EquipWeapon()
                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
            end)
        end
    end)
end

Tab:CreateParagraph({Title = "Select Bosses", Content = "Select which bosses to prioritize over Level Farm."})

for _, bossName in ipairs(bossList) do
    Tab:CreateToggle({
        Name = bossName,
        CurrentValue = false,
        Flag = "SelectBoss_" .. bossName,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
        end
    })
end

Tab:CreateSection("Pity System")

Tab:CreateDropdown({
    Name = "Pity Target Boss",
    Options = bossList,
    CurrentOption = _G.SlowHub.PityTargetBoss or "",
    Flag = "PityTargetBoss",
    Callback = function(Option)
        _G.SlowHub.PityTargetBoss = Option
    end
})

Tab:CreateToggle({
    Name = "Priority Pity System",
    CurrentValue = false,
    Flag = "PriorityPityEnabled",
    Callback = function(Value)
        _G.SlowHub.PriorityPityEnabled = Value
    end
})

Tab:CreateParagraph({
    Title = "Pity System Info", 
    Content = "When enabled, the script will kill random bosses until pity reaches 24/25. At 24/25, it will only target the selected Pity Target Boss for the guaranteed drop."
})

Tab:CreateSection("Farm Control")

local FarmToggle = Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses (Priority)",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                if Rayfield then
                    Rayfield:Notify({
                        Title = "Error",
                        Content = "Please select a weapon first!",
                        Duration = 3,
                        Image = 4483362458,
                    })
                end
                _G.SlowHub.AutoFarmBosses = false
                return
            end
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
        _G.SlowHub.AutoFarmBosses = Value
    end
})

Tab:CreateSlider({
    Name = "Boss Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Flag = "BossFarmDistance",
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
    end
})

Tab:CreateSlider({
    Name = "Boss Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Flag = "BossFarmHeight",
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
    end
})
