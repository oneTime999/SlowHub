local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AizenBoss", "AlucardBoss", "QinShiBoss", "JinwooBoss", 
    "SukunaBoss", "GojoBoss", "SaberBoss", "YujiBoss"
}

local BossSafeZones = {
    ["AizenBoss"]  = CFrame.new(-567.22, 2.57, 1228.49),
    ["AlucardBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["QinShiBoss"] = CFrame.new(828.11, -0.39, -1130.76),
    ["SaberBoss"]  = CFrame.new(828.11, -0.39, -1130.76),
    ["JinwooBoss"] = CFrame.new(248.74, 12.09, 927.54),
    ["SukunaBoss"] = CFrame.new(1571.26, 77.22, -34.11),
    ["GojoBoss"]   = CFrame.new(1858.32, 12.98, 338.14),
    ["YujiBoss"]   = CFrame.new(1537.92, 12.98, 226.10)
}

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}
if not _G.SlowHub.BossFarmDistance then _G.SlowHub.BossFarmDistance = 8 end
if not _G.SlowHub.BossFarmHeight then _G.SlowHub.BossFarmHeight = 5 end

local autoFarmBossConnection = nil
local isRunning = false
local lastTargetBoss = nil
local hasVisitedSafeZone = false

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

-- === RAYFIELD UI === --

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

Tab:CreateSection("Farm Control")

local FarmToggle = Tab:CreateToggle({
    Name = "Auto Farm Selected Bosses (Priority)",
    CurrentValue = false,
    Flag = "AutoFarmBoss",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                -- Rayfield Notification
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please select a weapon first!",
                    Duration = 3,
                    Image = 4483362458,
                })
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
