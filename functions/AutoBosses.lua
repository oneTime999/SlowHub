local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Lista de bosses disponíveis
local bossList = {
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss"
}

-- Variáveis de controle
local autoFarmBossConnection = nil
local selectedBoss = "RagnaBoss"
local isRunning = false

-- Função para pegar o Boss
local function getBoss()
    local bossName = tostring(selectedBoss)
    return workspace.NPCs:FindFirstChild(bossName)
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

-- Função para parar Auto Farm Boss
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

-- Função para iniciar Auto Farm Boss
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
                        local offsetPosition = targetCFrame * CFrame.new(0, 5, 8)
                        
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

-- Dropdown para selecionar o boss
Tab:CreateDropdown({
    Name = "Selecionar Boss",
    Options = bossList,
    CurrentOption = "RagnaBoss",
    Flag = "SelectedBoss",
    Callback = function(Option)
        local wasRunning = isRunning
        
        if wasRunning then
            stopAutoFarmBoss()
            wait(0.3)
        end
        
        if type(Option) == "table" then
            selectedBoss = Option[1] or "RagnaBoss"
        else
            selectedBoss = tostring(Option)
        end
        
        if wasRunning then
            startAutoFarmBoss()
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Boss alterado para: " .. selectedBoss,
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
        end
    end
})

-- Toggle Auto Farm Boss (COM SALVAMENTO)
Tab:CreateToggle({
    Name = "Auto Farm Boss",
    CurrentValue = _G.SlowHub.AutoFarmBosses,  -- Carrega valor salvo
    Flag = "AutoFarmBossToggle",
    Callback = function(Value)
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Please select a weapon first!",
                        Duration = 5,
                        Image = 4483345998
                    })
                end)
                return
            end
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Farming Boss: " .. selectedBoss,
                    Duration = 3,
                    Image = 4483345998
                })
            end)
            
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
        
        -- Salva automaticamente
        _G.SlowHub.AutoFarmBosses = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

-- Auto iniciar se estava ativado
if _G.SlowHub.AutoFarmBosses and _G.SlowHub.SelectedWeapon then
    task.wait(2)
    startAutoFarmBoss()
end
