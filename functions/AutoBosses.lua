local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "AizenBoss",
    "QinShiBoss",
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss",
    "SaberBoss"
}

_G.SlowHub.SelectedBosses = _G.SlowHub.SelectedBosses or {}

local autoFarmBossConnection = nil
local isRunning = false
local currentTargetBoss = nil

_G.SlowHub.BossFarmDistance = _G.SlowHub.BossFarmDistance or 8
_G.SlowHub.BossFarmHeight = _G.SlowHub.BossFarmHeight or 5

local function getAllAliveBosses()
    local aliveBosses = {}
    local possibleFolders = {"workspace.NPCs", "workspace", "workspace.Enemies"}
    
    pcall(function()
        for _, folderPath in ipairs(possibleFolders) do
            local folderName = folderPath:match("([^.]+)$")
            local folder = workspace:FindFirstChild(folderName, true)
            if folder and (folder:IsA("Folder") or folder:IsA("Model")) then
                for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
                    if isSelected then
                        local boss = folder:FindFirstChild(bossName, true)
                        if boss and boss.Parent then
                            local humanoid = boss:FindFirstChildOfClass("Humanoid")
                            if humanoid and humanoid.Health > 0 and humanoid.Health < humanoid.MaxHealth then
                                table.insert(aliveBosses, boss)
                            end
                        end
                    end
                end
            end
        end
    end)
    
    return aliveBosses
end

local function getNextTargetBoss(currentBoss)
    local aliveBosses = getAllAliveBosses()
    
    if #aliveBosses == 0 then
        return nil
    end
    
    if #aliveBosses == 1 then
        return aliveBosses[1]
    end
    
    if not currentBoss then
        return aliveBosses[1]
    end
    
    for i, boss in ipairs(aliveBosses) do
        if boss ~= currentBoss then
            return boss
        end
    end
    
    return aliveBosses[1]
end

local function getBossRootPart(boss)
    if not boss then return nil end
    
    pcall(function()
        return boss:FindFirstChild("HumanoidRootPart") or 
               boss:FindFirstChild("Torso") or 
               boss:FindFirstChild("UpperTorso") or 
               boss.PrimaryPart
    end)
    
    return nil
end

local function EquipWeapon()
    pcall(function()
        if not _G.SlowHub.SelectedWeapon then return end
        
        local character = Player.Character
        if not character or not character:FindFirstChild("Humanoid") then return end
        
        local backpack = Player:FindFirstChild("Backpack")
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return
        end
        
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
            end
        end
    end)
end

local function stopAutoFarmBoss()
    isRunning = false
    currentTargetBoss = nil
    
    if autoFarmBossConnection then
        pcall(function()
            autoFarmBossConnection:Disconnect()
        end)
        autoFarmBossConnection = nil
    end
    
    _G.SlowHub.AutoFarmBosses = false
    
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = Player.Character.HumanoidRootPart
            rootPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            rootPart.Anchored = false
        end
    end)
end

local function startAutoFarmBoss()
    stopAutoFarmBoss()
    task.wait(0.1)
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    currentTargetBoss = nil
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not _G.SlowHub.AutoFarmBosses or not isRunning then
                stopAutoFarmBoss()
                return
            end
            
            if not Player.Character then return end
            local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end
            
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if not playerRoot then return end
            
            local aliveBosses = getAllAliveBosses()
            
            if #aliveBosses > 0 then
                local targetBoss = getNextTargetBoss(currentTargetBoss)
                
                if targetBoss ~= currentTargetBoss then
                    currentTargetBoss = targetBoss
                end
                
                if currentTargetBoss then
                    local bossHumanoid = currentTargetBoss:FindFirstChildOfClass("Humanoid")
                    if bossHumanoid and bossHumanoid.Health > 0 then
                        local bossRoot = getBossRootPart(currentTargetBoss)
                        
                        if bossRoot and bossRoot.Parent then
                            pcall(function()
                                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                
                                local targetCFrame = bossRoot.CFrame
                                local distanceOffset = math.clamp(_G.SlowHub.BossFarmDistance or 8, 1, 10)
                                local heightOffset = math.clamp(_G.SlowHub.BossFarmHeight or 5, 1, 10)
                                
                                local offsetCFrame = targetCFrame * CFrame.new(
                                    math.random(-distanceOffset, distanceOffset) * 0.3,
                                    heightOffset,
                                    math.random(-distanceOffset, distanceOffset)
                                )
                                
                                local distance = (playerRoot.Position - offsetCFrame.Position).Magnitude
                                if distance > 5 then
                                    playerRoot.CFrame = offsetCFrame
                                end
                                
                                EquipWeapon()
                            end)
                            
                            task.wait(0.1)
                            
                            pcall(function()
                                local combatSystem = ReplicatedStorage:FindFirstChild("CombatSystem")
                                if combatSystem and combatSystem:FindFirstChild("Remotes") then
                                    combatSystem.Remotes.RequestHit:FireServer()
                                end
                            end)
                            
                            pcall(function()
                                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                                if remotes then
                                    remotes.Attack:FireServer(currentTargetBoss)
                                end
                            end)
                        end
                    else
                        currentTargetBoss = nil
                    end
                end
            end
        end)
    end)
end

Tab:AddParagraph({
    Title = "Select Bosses", 
    Content = "Select multiple bosses to farm. Cycles between alive ones automatically."
})

for _, bossName in ipairs(bossList) do
    pcall(function()
        Tab:AddToggle("SelectBoss_" .. bossName, {
            Title = bossName,
            Default = false,
            Callback = function(Value)
                _G.SlowHub.SelectedBosses[bossName] = Value
                if _G.SaveConfig then 
                    pcall(_G.SaveConfig) 
                end
            end
        })
    end)
end

Tab:AddParagraph({
    Title = "Farm Control",
    Content = "Multi-boss auto farm with automatic target switching"
})

pcall(function()
    local FarmToggle = Tab:AddToggle("AutoFarmBoss", {
        Title = "Multi Boss Farm",
        Default = false,
        Callback = function(Value)
            pcall(function()
                if Value then
                    if not _G.SlowHub.SelectedWeapon then
                        FarmToggle:SetValue(false)
                        return
                    end
                    
                    startAutoFarmBoss()
                else
                    stopAutoFarmBoss()
                end
                
                if _G.SaveConfig then
                    pcall(_G.SaveConfig)
                end
            end)
        end
    })
end)

pcall(function()
    Tab:AddSlider("BossFarmDistance", {
        Title = "Boss Distance",
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmDistance,
        Rounding = 0,
        Callback = function(Value)
            _G.SlowHub.BossFarmDistance = Value
            if _G.SaveConfig then pcall(_G.SaveConfig) end
        end
    })
    
    Tab:AddSlider("BossFarmHeight", {
        Title = "Farm Height",
        Min = 1,
        Max = 10,
        Default = _G.SlowHub.BossFarmHeight,
        Rounding = 0,
        Callback = function(Value)
            _G.SlowHub.BossFarmHeight = Value
            if _G.SaveConfig then pcall(_G.SaveConfig) end
        end
    })
end)

spawn(function()
    task.wait(3)
    if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
        pcall(function()
            local FarmToggle = Tab:FindFirstChild("AutoFarmBoss")
            if FarmToggle then
                FarmToggle:SetValue(true)
            end
        end)
    end
end)
