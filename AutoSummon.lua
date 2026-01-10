local Tab = _G.BossesTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local BossList = {
    "QinShiBoss",
    "SaberBoss"
}

local autoSummonBossConnection = nil
local isSummoningBoss = false
local selectedBoss = "QinShiBoss"

-- Função para verificar se o boss está vivo
local function isBossAlive(bossName)
    pcall(function()
        -- Procura o boss no workspace
        for _, obj in pairs(workspace:GetChildren()) do
            if obj.Name:find(bossName) or obj.Name == bossName then
                local humanoid = obj:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    return true
                end
            end
        end
    end)
    return false
end

local function stopAutoSummonBoss()
    isSummoningBoss = false
    if autoSummonBossConnection then
        autoSummonBossConnection:Disconnect()
        autoSummonBossConnection = nil
    end
    _G.SlowHub.AutoSummonBoss = false
end

local function startAutoSummonBoss()
    if autoSummonBossConnection then
        stopAutoSummonBoss()
    end
    
    isSummoningBoss = true
    _G.SlowHub.AutoSummonBoss = true
    
    local summonAttempts = 0
    local MAX_ATTEMPTS = 50  -- Máximo de tentativas antes de parar
    
    autoSummonBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoSummonBoss or not isSummoningBoss then
            stopAutoSummonBoss()
            return
        end
        
        -- Verifica se o boss já está vivo
        if isBossAlive(selectedBoss) then
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = selectedBoss .. " is already alive! Stopping summon.",
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            stopAutoSummonBoss()
            return
        end
        
        -- Faz o summon
        pcall(function()
            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
            summonAttempts = summonAttempts + 1
        end)
        
        -- Para após muitas tentativas sem sucesso ou se boss apareceu
        if summonAttempts >= MAX_ATTEMPTS then
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Max summon attempts reached for " .. selectedBoss,
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            stopAutoSummonBoss()
        end
        
        -- Pequeno delay entre tentativas
        task.wait(0.1)
    end)
end

-- Dropdown para selecionar Boss
Tab:CreateDropdown({
    Name = "Select Boss",
    Options = BossList,
    CurrentOption = "QinShiBoss",
    Flag = "BossDropdown",
    Callback = function(Option)
        if type(Option) == "table" then
            selectedBoss = Option[1] or "QinShiBoss"
        else
            selectedBoss = tostring(Option)
        end
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Selected Boss: " .. selectedBoss,
                Duration = 3,
                Image = 105026320884681
            })
        end)
    end
})

-- Toggle principal Auto Summon Boss
Tab:CreateToggle({
    Name = "Auto Summon Boss (Loop)",
    CurrentValue = false,
    Flag = "AutoSummonBossToggle",
    Callback = function(Value)
        if Value then
            if isSummoningBoss then
                stopAutoSummonBoss()
            end
            
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Starting Auto Summon Loop: " .. selectedBoss,
                    Duration = 4,
                    Image = 105026320884681
                })
            end)
            
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Auto Summon Boss stopped",
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
        end
        
        _G.SlowHub.AutoSummonBoss = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

-- Botão Manual Summon (20x spam)
Tab:CreateButton({
    Name = "Manual Summon Boss (20x)",
    Callback = function()
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Manual summoning " .. selectedBoss .. " 20x...",
                Duration = 3,
                Image = 105026320884681
            })
        end)
        
        for i = 1, 20 do
            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
            task.wait(0.05)  -- Delay rápido entre spams
        end
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Manual summon complete! (" .. selectedBoss .. ")",
                Duration = 3,
                Image = 105026320884681
            })
        end)
    end
})

-- Auto start se estava ativo
if _G.SlowHub.AutoSummonBoss then
    task.wait(2)
    startAutoSummonBoss()
end
