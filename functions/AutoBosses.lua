local Tab = _G.MiscTab
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Player = Players.LocalPlayer

-- Variáveis de controle
local autoFarmBossConnection = nil
local selectedBoss = "RagnaBoss"

-- Lista de bosses disponíveis
local bossList = {
    "RagnaBoss",
    "JinwooBoss",
    "SukunaBoss",
    "GojoBoss"
}

-- Função para obter o boss atual
local function getBoss()
    if not Workspace.NPCs then return nil end
    
    local bossModel = Workspace.NPCs:FindFirstChild(selectedBoss)
    if not bossModel then return nil end
    
    -- Verificar se o boss tem Humanoid e está vivo
    local humanoid = bossModel:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        return bossModel
    end
    
    return nil
end

-- Função para obter a parte principal do boss
local function getBossPart(bossModel)
    -- Tentar encontrar HumanoidRootPart primeiro
    local hrp = bossModel:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    
    -- Se não tiver HumanoidRootPart, tentar Torso
    local torso = bossModel:FindFirstChild("Torso") or bossModel:FindFirstChild("UpperTorso")
    if torso then return torso end
    
    -- Se não encontrar, pegar a primeira Part do Model
    for _, child in pairs(bossModel:GetDescendants()) do
        if child:IsA("BasePart") then
            return child
        end
    end
    
    return nil
end

-- Função para teleportar até o boss
local function teleportToBoss(bossModel)
    local character = Player.Character
    if not character then return false end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end
    
    local bossPart = getBossPart(bossModel)
    if not bossPart then return false end
    
    -- Teleportar próximo ao boss (15 studs de distância)
    humanoidRootPart.CFrame = bossPart.CFrame * CFrame.new(0, 0, 15)
    
    return true
end

-- Função para atacar o boss
local function attackBoss()
    pcall(function()
        -- Método 1: Usar Remote de ataque
        ReplicatedStorage.RemoteEvents.Combat:FireServer("Attack")
    end)
    
    pcall(function()
        -- Método 2: Usar Remote alternativo (caso o jogo use outro)
        ReplicatedStorage.RemoteEvents.AttackRemote:FireServer()
    end)
end

-- Função para parar Auto Farm Boss
local function stopAutoFarmBoss()
    if autoFarmBossConnection then
        autoFarmBossConnection:Disconnect()
        autoFarmBossConnection = nil
    end
    _G.SlowHub.AutoFarmBoss = false
end

-- Função para iniciar Auto Farm Boss
local function startAutoFarmBoss()
    if autoFarmBossConnection then
        stopAutoFarmBoss()
    end
    
    _G.SlowHub.AutoFarmBoss = true
    
    autoFarmBossConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoFarmBoss then
            stopAutoFarmBoss()
            return
        end
        
        local boss = getBoss()
        
        if boss then
            -- Boss existe e está vivo
            teleportToBoss(boss)
            attackBoss()
        else
            -- Boss morreu ou não existe, aguardar respawn
            wait(1)
        end
    end)
end

-- Dropdown para selecionar o boss
Tab:CreateDropdown({
    Name = "Selecionar Boss",
    Options = bossList,
    CurrentOption = selectedBoss,
    Flag = "SelectedBoss",
    Callback = function(Option)
        selectedBoss = Option
    end
})

-- Toggle Auto Farm Boss
Tab:CreateToggle({
    Name = "Auto Farm Boss",
    CurrentValue = false,
    Flag = "AutoFarmBossToggle",
    Callback = function(Value)
        if Value then
            startAutoFarmBoss()
        else
            stopAutoFarmBoss()
        end
    end
})
