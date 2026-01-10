local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local bossList = {
    "QinShiBoss",
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss",
    "SaberBoss"
}

local autoFarmBossConnection = nil
local selectedBoss = "QinShiBoss"
local isRunning = false

if not _G.SlowHub.BossFarmDistance then
    _G.SlowHub.BossFarmDistance = 8
end

if not _G.SlowHub.BossFarmHeight then
    _G.SlowHub.BossFarmHeight = 5
end

local function getBoss()
    local bossName = tostring(selectedBoss)
    return workspace.NPCs:FindFirstChild(bossName)
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
                wait(0.1)
            end
        end
    end)
    
    return success
end

local function stopAutoFarmBoss()
    isRunning = false
    
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
        wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBosses = true
    
    EquipWeapon()
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBosses or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getBoss()
        
        if boss and boss.Parent then
            local bossHumanoid = boss:FindFirstChild("Humanoid")
            
            if bossHumanoid and bossHumanoid.Health <= 0 then
                return
            end
            
            local bossRoot = getBossRootPart(boss)
            
            if bossRoot and bossRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
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
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Boss",
    Options = bossList,
    CurrentOption = "QinShiBoss",
    Flag = "SelectedBoss",
    Callback = function(Option)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmBoss()
            wait(0.3)
        end
        
        if type(Option) == "table" then
            selectedBoss = Option[1] or "QinShiBoss"
        else
            selectedBoss = tostring(Option)
        end
        
        if wasRunning then
            startAutoFarmBoss()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Boss changed to: " .. selectedBoss,
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Boss",
    CurrentValue = _G.SlowHub.AutoFarmBosses,
    Flag = "AutoFarmBossToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Please select a weapon first!",
                        Duration = 5,
                        Image = 105026320884681
                    })
                end)
                return
            end
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming Boss: " .. selectedBoss,
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
            
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
    Suffix = "studs",
    CurrentValue = _G.SlowHub.BossFarmDistance,
    Flag = "BossFarmDistanceSlider",
    Callback = function(Value)
        _G.SlowHub.BossFarmDistance = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Boss Distance: " .. Value .. " studs",
                Duration = 2,
                Image = 105026320884681
            })
        end)
    end,
})

Tab:CreateSlider({
    Name = "Boss Farm Height",
    Range = {1, 10},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.BossFarmHeight,
    Flag = "BossFarmHeightSlider",
    Callback = function(Value)
        _G.SlowHub.BossFarmHeight = Value
        
        if _G.SaveConfig then
            _G.SaveConfig()
        end
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Boss Height: " .. Value .. " studs",
                Duration = 2,
                Image = 105026320884681
            })
        end)
    end,
})

if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
