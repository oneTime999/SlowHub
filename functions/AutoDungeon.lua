local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local MainTab = _G.MainTab -- Certifique-se que sua UI Library usa isso

-- Configurações padrão se não existirem
if not _G.SlowHub.FarmDistance then _G.SlowHub.FarmDistance = 8 end
if not _G.SlowHub.FarmHeight then _G.SlowHub.FarmHeight = 4 end

local dungeonConnection = nil

-- Função para Equipar Arma (Mesma do seu script original)
local function EquipWeapon()
    if not _G.SlowHub.SelectedWeapon then return false end
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

-- Função para encontrar o NPC mais próximo dentro da Dungeon
local function GetClosestDungeonEnemy()
    local closestEnemy = nil
    local shortestDistance = math.huge
    local character = Player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if not rootPart then return nil end

    local npcFolder = workspace:FindFirstChild("NPCs")
    if npcFolder then
        for _, npc in pairs(npcFolder:GetChildren()) do
            -- Verifica se o NPC é valido (tem vida e Humanoid)
            if npc:FindFirstChild("Humanoid") and npc:FindFirstChild("HumanoidRootPart") and npc.Humanoid.Health > 0 then
                local distance = (rootPart.Position - npc.HumanoidRootPart.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = npc
                end
            end
        end
    end
    return closestEnemy
end

local function stopDungeonFarm()
    if dungeonConnection then
        dungeonConnection:Disconnect()
        dungeonConnection = nil
    end
    _G.SlowHub.AutoFarmDungeon = false
    -- Para o boneco ao desligar
    pcall(function()
        if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
            Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
    end)
end

local function startDungeonFarm()
    if dungeonConnection then stopDungeonFarm() end
    _G.SlowHub.AutoFarmDungeon = true
    
    local lastAttack = 0

    dungeonConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmDungeon then stopDungeonFarm() return end

        local character = Player.Character
        local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChild("Humanoid")

        if not playerRoot or not humanoid or humanoid.Health <= 0 then return end

        -- Busca o alvo
        local target = GetClosestDungeonEnemy()

        if target then
            local targetRoot = target:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                -- Teleporta para Perto (Cima/Trás)
                local targetCFrame = targetRoot.CFrame * CFrame.new(0, _G.SlowHub.FarmHeight, _G.SlowHub.FarmDistance)
                
                -- Movimentação
                playerRoot.CFrame = targetCFrame
                playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0) -- Tira a gravidade/inércia

                -- Ataque
                EquipWeapon()
                local now = tick()
                if (now - lastAttack) > 0.15 then -- Delay de ataque igual ao original
                    ReplicatedStorage.CombatSystem.Remotes.RequestHit:FireServer()
                    lastAttack = now
                end
            end
        else
            -- (Opcional) Se não tiver NPC vivo, fica parado esperando spawnar
            playerRoot.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end
    end)
end

-- Adiciona o Toggle na Interface
MainTab:AddToggle("AutoFarmDungeon", {
    Title = "Auto Farm Dungeon (Activate only inside the Dungeon)",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmDungeon = Value
        if Value then
            if not _G.SlowHub.SelectedWeapon then
                -- Assumindo que você tem o Fluent UI carregado baseado no script anterior
                if _G.Fluent then
                    _G.Fluent:Notify({Title = "Error", Content = "Select a weapon first!", Duration = 3})
                end
                return
            end
            startDungeonFarm()
        else
            stopDungeonFarm()
        end
    end
})
