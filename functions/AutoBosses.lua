local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Configurações dos Bosses
local BossConnections = {
    Ragna = nil,
    Jinwoo = nil,
    Sukuna = nil,
    Gojo = nil
}

-- Função para pegar Boss no workspace
local function getBoss(bossName)
    return workspace.Bosses:FindFirstChild(bossName)
end

-- Função para pegar RootPart do Boss
local function getBossRootPart(boss)
    if boss and boss:FindFirstChild("HumanoidRootPart") then
        return boss.HumanoidRootPart
    end
    return nil
end

-- Função para equipar arma
local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
    
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
            return true
        end
    end
    
    return false
end

-- Função genérica para farmar boss
local function farmBoss(bossName, flagName)
    local boss = getBoss(bossName)
    
    if boss and boss.Parent then
        local bossHumanoid = boss:FindFirstChild("Humanoid")
        
        -- Boss morto, esperar
        if bossHumanoid and bossHumanoid.Health <= 0 then
            if Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
            return
        end
        
        -- Farm Boss
        local bossRoot = getBossRootPart(boss)
        
        if bossRoot and bossRoot.Parent and Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = Player.Character:FindFirstChild("Humanoid")
            
            if playerRoot and humanoid and humanoid.Health > 0 then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                
                local targetCFrame = bossRoot.CFrame
                local offsetPosition = targetCFrame * CFrame.new(0, 5, 8)
                
                local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                if distance > 3 or distance < 1 then
                    playerRoot.CFrame = offsetPosition
                end
                
                EquipWeapon()
                
                pcall(function()
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                end)
            end
        end
    else
        -- Boss não encontrado
        if Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            if playerRoot then
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end
        end
    end
end

-- Função para parar farm de um boss específico
local function stopBossFarm(bossKey, flagName)
    if BossConnections[bossKey] then
        BossConnections[bossKey]:Disconnect()
        BossConnections[bossKey] = nil
    end
    _G.SlowHub[flagName] = false
    
    if Player.Character then
        local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
        if playerRoot then
            playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            playerRoot.Anchored = false
        end
    end
end

-- Função para iniciar farm de um boss específico
local function startBossFarm(bossKey, bossName, flagName)
    if BossConnections[bossKey] then
        stopBossFarm(bossKey, flagName)
    end
    
    _G.SlowHub[flagName] = true
    EquipWeapon()
    
    BossConnections[bossKey] = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub[flagName] then
            stopBossFarm(bossKey, flagName)
            return
        end
        
        pcall(function()
            farmBoss(bossName, flagName)
        end)
    end)
end

-- Toggle Auto Farm Ragna
Tab:CreateToggle({
    Name = "Auto Farm Ragna",
    CurrentValue = false,
    Flag = "AutoFarmRagnaToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Ragna enabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            startBossFarm("Ragna", "RagnaBoss", "AutoFarmRagna")
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Ragna disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopBossFarm("Ragna", "AutoFarmRagna")
        end
    end
})

-- Toggle Auto Farm Jinwoo
Tab:CreateToggle({
    Name = "Auto Farm Jinwoo",
    CurrentValue = false,
    Flag = "AutoFarmJinwooToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Jinwoo enabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            startBossFarm("Jinwoo", "JinwooBoss", "AutoFarmJinwoo")
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Jinwoo disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopBossFarm("Jinwoo", "AutoFarmJinwoo")
        end
    end
})

-- Toggle Auto Farm Sukuna
Tab:CreateToggle({
    Name = "Auto Farm Sukuna",
    CurrentValue = false,
    Flag = "AutoFarmSukunaToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Sukuna enabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            startBossFarm("Sukuna", "SukunaBoss", "AutoFarmSukuna")
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Sukuna disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopBossFarm("Sukuna", "AutoFarmSukuna")
        end
    end
})

-- Toggle Auto Farm Gojo
Tab:CreateToggle({
    Name = "Auto Farm Gojo",
    CurrentValue = false,
    Flag = "AutoFarmGojoToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Gojo enabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            startBossFarm("Gojo", "GojoBoss", "AutoFarmGojo")
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Gojo disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopBossFarm("Gojo", "AutoFarmGojo")
        end
    end
})
