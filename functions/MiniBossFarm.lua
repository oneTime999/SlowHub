local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MiniBossConfig = {
    ["ThiefBoss"] = {quest = "QuestNPC2"},
    ["MonkeyBoss"] = {quest = "QuestNPC4"},
    ["DesertBoss"] = {quest = "QuestNPC6"},
    ["SnowBoss"] = {quest = "QuestNPC8"},
    ["PandaMiniBoss"] = {quest = "QuestNPC10"}
}

local miniBossList = {"ThiefBoss", "MonkeyBoss", "DesertBoss", "SnowBoss", "PandaMiniBoss"}
local autoFarmMiniBossConnection = nil
local questConnection = nil
local selectedMiniBoss = "ThiefBoss"
local isRunning = false

if not _G.SlowHub.MiniBossFarmDistance then
    _G.SlowHub.MiniBossFarmDistance = 6
end

if not _G.SlowHub.MiniBossFarmHeight then
    _G.SlowHub.MiniBossFarmHeight = 4
end

local function getConfig()
    return MiniBossConfig[selectedMiniBoss] or MiniBossConfig["ThiefBoss"]
end

local function getMiniBoss()
    return workspace.NPCs:FindFirstChild(selectedMiniBoss)
end

local function getMiniBossRootPart(miniBoss)
    if miniBoss and miniBoss:FindFirstChild("HumanoidRootPart") then
        return miniBoss.HumanoidRootPart
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

local function stopAutoFarmMiniBoss()
    isRunning = false
    
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
            end
        end
    end)
end

local function startAutoFarmMiniBoss()
    if isRunning then
        stopAutoFarmMiniBoss()
        task.wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmMiniBosses = true
    
    local config = getConfig()
    
    -- Loop de aceitar missão
    questConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then
            return
        end
        
        pcall(function()
            ReplicatedStorage.RemoteEvents.QuestAccept:FireServer(config.quest)
        end)
    end)
    
    EquipWeapon()
    
    autoFarmMiniBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmMiniBosses or not isRunning then
            stopAutoFarmMiniBoss()
            return
        end
        
        local miniBoss = getMiniBoss()
        
        if miniBoss and miniBoss.Parent then
            local bossHumanoid = miniBoss:FindFirstChild("Humanoid")
            
            if bossHumanoid and bossHumanoid.Health <= 0 then
                task.wait(1) -- Espera respawn
                return
            end
            
            local bossRoot = getMiniBossRootPart(miniBoss)
            
            if bossRoot and bossRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    pcall(function()
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        local targetCFrame = bossRoot.CFrame
                        local offsetPosition = targetCFrame * CFrame.new(0, _G.SlowHub.MiniBossFarmHeight, _G.SlowHub.MiniBossFarmDistance)
                        
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
    Name = "Select Mini Boss",
    Options = miniBossList,
    CurrentOption = "ThiefBoss",
    Flag = "SelectedMiniBoss",
    Callback = function(Option)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmMiniBoss()
            task.wait(0.3)
        end
        
        if type(Option) == "table" then
            selectedMiniBoss = Option[1] or "ThiefBoss"
        else
            selectedMiniBoss = tostring(Option)
        end
        
        if wasRunning then
            startAutoFarmMiniBoss()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Mini Boss: " .. selectedMiniBoss .. " (Quest: " .. getConfig().quest .. ")",
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
        end
    end
})

Tab:CreateToggle({
    Name = "Auto Farm Mini Boss",
    CurrentValue = _G.SlowHub.AutoFarmMiniBosses or false,
    Flag = "AutoFarmMiniBossToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Selecione uma arma primeiro!",
                        Duration = 5,
                        Image = 105026320884681
                    })
                end)
                return
            end
            
            local config = getConfig()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming: " .. selectedMiniBoss .. " (Quest: " .. config.quest .. ")",
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            
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
    Range = {3, 12},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.MiniBossFarmDistance,
    Flag = "MiniBossFarmDistanceSlider",
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmDistance = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

Tab:CreateSlider({
    Name = "Mini Boss Height",
    Range = {2, 8},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = _G.SlowHub.MiniBossFarmHeight,
    Flag = "MiniBossFarmHeightSlider",
    Callback = function(Value)
        _G.SlowHub.MiniBossFarmHeight = Value
        if _G.SaveConfig then _G.SaveConfig() end
    end,
})

if _G.SlowHub.AutoFarmMiniBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmMiniBoss()
end
