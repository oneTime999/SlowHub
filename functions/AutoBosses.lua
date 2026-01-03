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
    -- Garantir que selectedBoss é string
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
        
        -- Verificar se a arma já está equipada
        if character:FindFirstChild(_G.SlowHub.SelectedWeapon) then
            return true
        end
        
        -- Equipar da backpack
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
    
    _G.SlowHub.AutoFarmBoss = false
    
    -- Stop player movement and unanchor
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
    -- Parar qualquer instância anterior
    if isRunning then
        stopAutoFarmBoss()
        wait(0.3)
    end
    
    isRunning = true
    _G.SlowHub.AutoFarmBoss = true
    
    -- Equipar arma ao iniciar
    EquipWeapon()
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBoss or not isRunning then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getBoss()
        
        if boss and boss.Parent then
            local bossHumanoid = boss:FindFirstChild("Humanoid")
            
            -- Verificar se o Boss está morto
            if bossHumanoid and bossHumanoid.Health <= 0 then
                -- Boss morto, NÃO fazer nada (não teleportar, não flutuar)
                return
            end
            
            -- Boss está vivo, farmar
            local bossRoot = getBossRootPart(boss)
            
            if bossRoot and bossRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
                    pcall(function()
                        -- Remove any unwanted velocity
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                        
                        -- Keep player near Boss (5 studs above, 8 studs forward)
                        local targetCFrame = bossRoot.CFrame
                        local offsetPosition = targetCFrame * CFrame.new(0, 5, 8)
                        
                        -- Only teleport if distance is reasonable
                        local distance = (playerRoot.Position - offsetPosition.Position).Magnitude
                        if distance > 3 or distance < 1 then
                            playerRoot.CFrame = offsetPosition
                        end
                        
                        -- Equipar arma
                        EquipWeapon()
                        
                        -- Attack Boss
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        end
        -- Boss não encontrado = NÃO fazer nada (removido o código de flutuar)
    end)
end

-- Dropdown para selecionar o boss (CORRIGIDO)
Tab:CreateDropdown({
    Name = "Selecionar Boss",
    Options = bossList,
    CurrentOption = "RagnaBoss",
    Flag = "SelectedBoss",
    Callback = function(Option)
        local wasRunning = isRunning
        
        -- Parar o farm atual
        if wasRunning then
            stopAutoFarmBoss()
            wait(0.3)
        end
        
        -- Garantir que Option é string (CORREÇÃO DO BUG)
        if type(Option) == "table" then
            selectedBoss = Option[1] or "RagnaBoss"
        else
            selectedBoss = tostring(Option)
        end
        
        -- Reiniciar se estava rodando
        if wasRunning then
            startAutoFarmBoss()
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Boss alterado para: " .. selectedBoss,
                    Duration = 3,
                    Image = 4483345998
                })
            end)
        end
    end
})

-- Toggle Auto Farm Boss
Tab:CreateToggle({
    Name = "Auto Farm Boss",
    CurrentValue = false,
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
    end
})
