local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "GilgameshBoss", "RimuruBoss", "MadokaBoss", "StrongestofTodayBoss", "StrongestinHistoryBoss", "IchigoBoss", "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local difficulties = {"_Normal", "_Medium", "_Hard", "_Extreme"}

local BossSafeZones = {
    ["GilgameshBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["RimuruBoss"] = CFrame.new(-1363.4713134765625, 30.04159164428711, 221.3505859375),
    ["MadokaBoss"] = CFrame.new(-1264.6318359375, -0.17221689224243164, -1116.2039794921875),
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

-- Global pity functions for access from other scripts
_G.SlowHub.GetPityCount = function()
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

_G.SlowHub.IsPityTargetTime = function()
    if not _G.SlowHub.PriorityPityEnabled or _G.SlowHub.PityTargetBoss == "" then
        return false
    end
    return _G.SlowHub.GetPityCount() >= 24
end

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false
local currentFarmingBoss = nil

local function checkHumanoid(model)
    if model and model.Parent then
        local humanoid = model:FindFirstChild("Humanoid")
        if humanoid and humanoid.Health > 0 then
            return true
        end
    end
    return false
end

local function getBossBaseName(bossName)
    for _, baseName in ipairs(bossList) do
        if bossName == baseName or string.find(bossName, baseName) == 1 then
            return baseName
        end
    end
    return bossName
end

local function isBossSelected(bossName)
    local baseName = getBossBaseName(bossName)
    if _G.SlowHub.SelectedBosses[baseName] then
        return true
    end
    return false
end

local function shouldStopFarmingCurrentBoss(boss)
    if not boss or not boss.Parent then return true end
    if not checkHumanoid(boss) then return true end
    
    local bossBaseName = getBossBaseName(boss.Name)
    
    if not isBossSelected(bossBaseName) then
        return true
    end
    
    -- Se for Pity Time, só para se não for o boss de pity
    if _G.SlowHub.IsPityTargetTime() then
        local pityTarget = _G.SlowHub.PityTargetBoss
        if bossBaseName ~= pityTarget then
            return true
        end
        return false
    end
    
    -- Se não for pity time, verifica se ainda deve farmar este boss
    if _G.SlowHub.PriorityPityEnabled and _G.SlowHub.PityTargetBoss ~= "" then
        local currentPity = _G.SlowHub.GetPityCount()
        local pityTarget = _G.SlowHub.PityTargetBoss
        
        if currentPity >= 24 then
            if bossBaseName ~= pityTarget then
                return true
            end
        else
            if bossBaseName == pityTarget then
                return true
            end
        end
    end
    
    return false
end

local function findValidBoss()
    local npcs = workspace:FindFirstChild("NPCs")
    if not npcs then return nil end
    
    local pityEnabled = _G.SlowHub.PriorityPityEnabled
    local pityTarget = _G.SlowHub.PityTargetBoss
    
    -- Se Pity Time, só procura o boss de pity
    if pityEnabled and pityTarget ~= "" and _G.SlowHub.IsPityTargetTime() then
        if isBossSelected(pityTarget) then
            local exactBoss = npcs:FindFirstChild(pityTarget)
            if exactBoss and checkHumanoid(exactBoss) then return exactBoss end
            
            for _, diff in ipairs(difficulties) do
                local variantName = pityTarget .. diff
                local variantBoss = npcs:FindFirstChild(variantName)
                if variantBoss and checkHumanoid(variantBoss) then return variantBoss end
            end
        end
        return nil
    end
    
    -- Procura qualquer boss selecionado
    for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
        if isSelected then
            -- Se pity está ativo mas não é pity time, pula o boss de pity
            if pityEnabled and pityTarget ~= "" and bossName == pityTarget then
                if _G.SlowHub.GetPityCount() < 24 then
                    continue
                end
            end
            
            local exactBoss = npcs:FindFirstChild(bossName)
            if exactBoss and checkHumanoid(exactBoss) then return exactBoss end

            for _, diff in ipairs(difficulties) do
                local variantName = bossName .. diff
                local variantBoss = npcs:FindFirstChild(variantName)
                if variantBoss and checkHumanoid(variantBoss) then return variantBoss end
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
    currentFarmingBoss = nil
    _G.SlowHub.IsAttackingBoss = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    _G.SlowHub.AutoFarmBosses = false
end

-- CORREÇÃO: Sistema de ataque rápido
local lastAttackTime = 0
local attackInterval = 0.05 -- 50ms entre ataques

local function startAutoFarmBoss()
    if isRunning then stopAutoFarmBoss() task.wait(0.2) end
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    lastAttackTime = 0
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        -- CORREÇÃO: Se o boss atual morreu ou não deve mais ser farmado, limpa
        if currentFarmingBoss and shouldStopFarmingCurrentBoss(currentFarmingBoss) then
            currentFarmingBoss = nil
            hasVisitedSafeZone = false
            lastTargetBoss = nil
            _G.SlowHub.IsAttackingBoss = false
            task.wait(0.1)
            return
        end
        
        -- Procura um boss válido
        if not currentFarmingBoss then
            currentFarmingBoss = findValidBoss()
            if not currentFarmingBoss then
                _G.SlowHub.IsAttackingBoss = false
                return
            end
            hasVisitedSafeZone = false
            lastTargetBoss = currentFarmingBoss
        end
        
        -- CORREÇÃO: Sempre marca como atacando boss quando tem um boss válido
        -- Isso força outros scripts (AutoFarmSelectedMob) a pararem
        local boss = currentFarmingBoss
        _G.SlowHub.IsAttackingBoss = true
        
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
                    if string.find(boss.Name, baseName) == 1 then
                        safeCFrame = BossSafeZones[baseName]
                        break
                    end
                end
            end
            
            if safeCFrame then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                playerRoot.CFrame = safeCFrame
                hasVisitedSafeZone = true 
                task.wait(0.1)
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
                
                -- CORREÇÃO: Ataque mais rápido baseado em tempo
                local now = tick()
                if (now - lastAttackTime) >= attackInterval then
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttackTime = now
                end
            end)
        end
    end)
end

Tab:CreateSection("Boss Selection")

Tab:CreateDropdown({
    Name = "Select Bosses to Farm",
    Options = bossList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "MultiBossSelector",
    Callback = function(Options)
        _G.SlowHub.SelectedBosses = {}
        for _, bossName in ipairs(Options) do
            _G.SlowHub.SelectedBosses[bossName] = true
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSection("Pity System (Optional)")

Tab:CreateDropdown({
    Name = "Pity Target Boss",
    Options = bossList,
    CurrentOption = "",
    Flag = "PityTargetBoss",
    Callback = function(Option)
        if type(Option) == "table" then
            _G.SlowHub.PityTargetBoss = Option[1] or ""
        else
            _G.SlowHub.PityTargetBoss = Option
        end
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateToggle({
    Name = "Enable Pity System",
    CurrentValue = false,
    Flag = "PriorityPityEnabled",
    Callback = function(Value)
        _G.SlowHub.PriorityPityEnabled = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

Tab:CreateSection("Farm Control")

Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                if Rayfield then
                    Rayfield:Notify({Title = "Error", Content = "Please select a weapon first!", Duration = 3})
                end
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

Tab:CreateSlider({
    Name = "Boss Farm Distance",
    Range = {1, 10},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Flag = "BossFarmDistance",
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
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
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})
