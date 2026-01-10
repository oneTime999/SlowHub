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
    
    autoSummonBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoSummonBoss or not isSummoningBoss then
            stopAutoSummonBoss()
            return
        end
        
        -- Verifica se o boss já está vivo
        if isBossAlive(selectedBoss) then
            return -- Continua o loop, só para se desativar manualmente
        end
        
        -- Faz o summon continuamente
        pcall(function()
            ReplicatedStorage.Remotes.RequestSummonBoss:FireServer(selectedBoss)
        end)
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
                Content = "Selected: " .. selectedBoss,
                Duration = 2.5,
                Image = 105026320884681
            })
        end)
    end
})

-- Toggle Auto Summon Boss (LOOP CONTÍNUO)
Tab:CreateToggle({
    Name = "Auto Summon Boss",
    CurrentValue = false,
    Flag = "AutoSummonBossToggle",
    Callback = function(Value)
        if Value then
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Auto Summoning: " .. selectedBoss .. " (LOOP)",
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
            startAutoSummonBoss()
        else
            stopAutoSummonBoss()
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Auto Summon stopped",
                    Duration = 2,
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

-- Auto start se estava ativo
if _G.SlowHub.AutoSummonBoss then
    task.wait(2)
    startAutoSummonBoss()
end
