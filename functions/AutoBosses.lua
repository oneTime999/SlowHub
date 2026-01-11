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

_G.SlowHub.BossFarmDistance = _G.SlowHub.BossFarmDistance or 8
_G.SlowHub.BossFarmHeight = _G.SlowHub.BossFarmHeight or 5

local function getAliveBoss()
    local possibleFolders = {"workspace.NPCs", "workspace", "workspace.Enemies"}
    
    for _, folderPath in ipairs(possibleFolders) do
        local folder = workspace:FindFirstChild(folderPath:match("([^.]+)$"), true)
        if folder then
            for bossName, isSelected in pairs(_G.SlowHub.SelectedBosses) do
                if isSelected then
                    local boss = folder:FindFirstChild(bossName, true)
                    if boss and boss.Parent then
                        local humanoid = boss:FindFirstChildOfClass("Humanoid")
                        if humanoid and humanoid.Health > 0 and humanoid.Health ~= humanoid.MaxHealth * 0 then
                            return boss
                        end
                    end
                end
            end
        end
    end
    
    for _, folderPath in ipairs(possibleFolders) do
        local folder = workspace:FindFirstChild(folderPath:match("([^.]+)$"), true)
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if obj:IsA("Model") and obj.Name:find("Boss") then
                    local humanoid = obj:FindFirstChildOfClass("Humanoid")
                    if humanoid and humanoid.Health > 0 and humanoid.Health ~= humanoid.MaxHealth * 0 then
                        return obj
                    end
                end
            end
        end
    end
    
    return nil
end

local function getBossRootPart(boss)
    if not boss then return nil end
    
    local rootPart = boss:FindFirstChild("HumanoidRootPart") or 
                     boss:FindFirstChild("Torso") or 
                     boss:FindFirstChild("UpperTorso") or 
                     boss.PrimaryPart
    
    return rootPart
end

local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
    pcall(function()
        local character = Player.Character
        if not character or not character:FindFirstChild("Humanoid") then return end
        
        local backpack = Player:FindFirstChild("Backpack")
        
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return true
        end
        
        if backpack then
            local weapon = backpack:FindFirstChild(_G.SlowHub.SelectedWeapon)
            if weapon then
                character.Humanoid:EquipTool(weapon)
                task.wait(0.2)
            end
        end
    end)
    
    return true
end

local function stopAutoFarmBoss()
    isRunning = false
    
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
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
    if isRunning then
        stopAutoFarmBoss()
        task.wait(0.5)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        pcall(function()
            if not _G.SlowHub.AutoFarmBosses or not isRunning then
                stopAutoFarmBoss()
                return
            end
            
            if not Player.Character or not Player.Character:FindFirstChild("Humanoid") then
                task.wait(1)
                return
            end
            
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then
                task.wait(1)
                return
            end
            
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if not playerRoot then return end
            
            local boss = getAliveBoss()
            
            if boss then
                local bossHumanoid = boss:FindFirstChildOfClass("Humanoid")
                if bossHumanoid and bossHumanoid.Health > 0 then
                    local bossRoot = getBossRootPart(boss)
                    
                    if bossRoot then
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        local targetCFrame = bossRoot.CFrame
                        local distanceOffset = _G.SlowHub.BossFarmDistance
                        local heightOffset = _G.SlowHub.BossFarmHeight
                        
                        local offsetCFrame = targetCFrame * CFrame.new(
                            math.random(-distanceOffset, distanceOffset) * 0.3,
                            heightOffset,
                            math.random(-distanceOffset, distanceOffset)
                        )
                        
                        local distance = (playerRoot.Position - offsetCFrame.Position).Magnitude
                        if distance > 5 or distance < 1 then
                            playerRoot.CFrame = offsetCFrame
                        end
                        
                        EquipWeapon()
                        task.wait(0.1)
                        
                        pcall(function()
                            if ReplicatedStorage:FindFirstChild("CombatSystem") then
                                ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                            end
                        end)
                        
                        pcall(function()
                            if ReplicatedStorage:FindFirstChild("Remotes") then
                                ReplicatedStorage.Remotes.Attack:FireServer(boss)
                            end
                        end)
                    end
                end
            end
        end)
    end)
end

Tab:AddParagraph({
    Title = "Select Bosses", 
    Content = "Choose which bosses to farm (farms all bosses if none selected)"
})

for _, bossName in ipairs(bossList) do
    Tab:AddToggle("SelectBoss_" .. bossName, {
        Title = bossName,
        Default = false,
        Callback = function(Value)
            _G.SlowHub.SelectedBosses[bossName] = Value
            if _G.SaveConfig then _G.SaveConfig() end
        end
    })
end

Tab:AddParagraph({
    Title = "Farm Control",
    Content = "Auto farm controls"
})

local FarmToggle = Tab:AddToggle("AutoFarmBoss", {
    Title = "Auto Farm Bosses",
    Default = false,
    Callback = function(Value)
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
            _G.SaveConfig()
        end
    end
})

Tab:AddSlider("BossFarmDistance", {
    Title = "Boss Distance",
    Min = 3,
    Max = 15,
    Default = _G.SlowHub.BossFarmDistance,
    Rounding = 1,
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

Tab:AddSlider("BossFarmHeight", {
    Title = "Farm Height",
    Min = 0,
    Max = 15,
    Default = _G.SlowHub.BossFarmHeight,
    Rounding = 1,
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end
})

spawn(function()
    if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
        task.wait(3)
        if FarmToggle then
            FarmToggle:SetValue(true)
        end
    end
end)
