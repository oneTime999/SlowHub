local Tab = _G.MainTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

-- Configurações dos Bosses
local BossConfig = {
    {name = "SukunaBoss", respawnTime = 440, displayName = "Sukuna Boss (440s)"},
    {name = "GojoBoss", respawnTime = 440, displayName = "Gojo Boss (440s)"},
    {name = "RagnaBoss", respawnTime = 290, displayName = "Ragna Boss (290s)"},
    {name = "JinwooBoss", respawnTime = 590, displayName = "Jinwoo Boss (590s)"}
}

-- Variáveis de controle
local autoBossConnection = nil
local selectedBoss = nil
local lastBossKillTime = 0

-- Função para pegar o Boss selecionado
local function getSelectedBossConfig()
    for _, config in pairs(BossConfig) do
        if config.name == selectedBoss then
            return config
        end
    end
    return nil
end

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
            return true
        end
    end
    
    return false
end

-- Função para parar Auto Boss
local function stopAutoBoss()
    if autoBossConnection then
        autoBossConnection:Disconnect()
        autoBossConnection = nil
    end
    _G.SlowHub.AutoFarmBoss = false
    
    -- Stop player movement
    if Player.Character then
        local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
        if playerRoot then
            playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            playerRoot.Anchored = false
        end
    end
end

-- Função para iniciar Auto Boss
local function startAutoBoss()
    if autoBossConnection then
        stopAutoBoss()
    end
    
    if not selectedBoss then
        _G.Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Please select a boss first!",
            Duration = 5,
            Image = 4483345998
        })
        return
    end
    
    _G.SlowHub.AutoFarmBoss = true
    
    local config = getSelectedBossConfig()
    
    -- Equipar arma ao iniciar
    EquipWeapon()
    
    local waitingForRespawn = false
    local respawnStartTime = 0
    
    autoBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBoss then
            stopAutoBoss()
            return
        end
        
        local now = tick()
        local boss = getBoss(selectedBoss)
        
        if boss and boss.Parent then
            local bossHumanoid = boss:FindFirstChild("Humanoid")
            
            -- Verificar se o Boss está morto
            if bossHumanoid and bossHumanoid.Health <= 0 then
                -- Boss morto, começar contagem de respawn
                if not waitingForRespawn then
                    waitingForRespawn = true
                    respawnStartTime = now
                    lastBossKillTime = now
                    
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Boss killed! Waiting " .. config.respawnTime .. "s for respawn...",
                        Duration = 5,
                        Image = 4483345998
                    })
                end
                
                -- Ficar parado esperando respawn
                if Player.Character then
                    local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                    if playerRoot then
                        playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    end
                end
                
                return
            end
            
            -- Boss está vivo, resetar flag de espera
            waitingForRespawn = false
            
            -- Farm Boss
            local bossRoot = getBossRootPart(boss)
            
            if bossRoot and bossRoot.Parent and Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = Player.Character:FindFirstChild("Humanoid")
                
                if playerRoot and humanoid and humanoid.Health > 0 then
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
                    pcall(function()
                        ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    end)
                end
            end
        else
            -- Boss not found
            if Player.Character then
                local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
                if playerRoot then
                    playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                end
            end
            
            -- Mostrar tempo restante se estiver esperando respawn
            if waitingForRespawn then
                local elapsed = now - respawnStartTime
                local remaining = config.respawnTime - elapsed
                
                if remaining <= 0 then
                    waitingForRespawn = false
                end
            end
        end
    end)
end

-- Dropdown para selecionar Boss
local bossOptions = {}
for _, config in pairs(BossConfig) do
    table.insert(bossOptions, config.displayName)
end

Tab:CreateDropdown({
    Name = "Select Boss",
    Options = bossOptions,
    CurrentOption = "",
    Flag = "BossDropdown",
    Callback = function(Value)
        -- Extrair o nome do boss do display name
        for _, config in pairs(BossConfig) do
            if config.displayName == Value then
                selectedBoss = config.name
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Boss selected: " .. config.name,
                    Duration = 3,
                    Image = 4483345998
                })
                break
            end
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
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a weapon first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            if not selectedBoss then
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Please select a boss first!",
                    Duration = 5,
                    Image = 4483345998
                })
                return
            end
            
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Boss enabled! Farming: " .. selectedBoss,
                Duration = 3,
                Image = 4483345998
            })
            
            startAutoBoss()
        else
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Auto Farm Boss disabled!",
                Duration = 3,
                Image = 4483345998
            })
            
            stopAutoBoss()
        end
    end
})
