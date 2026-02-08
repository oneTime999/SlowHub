local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local hakiConnection = nil
local lastExecution = 0
local WAIT_TIME = 3 -- Tempo em segundos

-- Inicializa a variável no SlowHub caso não exista
if _G.SlowHub.AutoHaki == nil then
    _G.SlowHub.AutoHaki = false
end

local function stopAutoHaki()
    if hakiConnection then
        hakiConnection:Disconnect()
        hakiConnection = nil
    end
    _G.SlowHub.AutoHaki = false
end

local function startAutoHaki()
    if hakiConnection then stopAutoHaki() end

    _G.SlowHub.AutoHaki = true
    
    hakiConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoHaki then
            stopAutoHaki()
            return
        end

        -- Verifica se já se passaram 3 segundos desde a última execução
        if tick() - lastExecution >= WAIT_TIME then
            lastExecution = tick()
            
            local remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("ConquerorHakiRemote")
            if remote then
                remote:FireServer("Activate")
            end
        end
    end)
end

-- Criação do Toggle na aba Misc
local HakiToggle = _G.MiscTab:CreateToggle({
    Name = "Auto Conqueror Haki",
    CurrentValue = _G.SlowHub.AutoHaki,
    Flag = "AutoHaki",
    Callback = function(Value)
        if Value then
            startAutoHaki()
        else
            stopAutoHaki()
        end
        
        _G.SlowHub.AutoHaki = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

-- Auto-execução caso a config esteja salva como ligada
if _G.SlowHub.AutoHaki then
    task.wait(2)
    startAutoHaki()
end
