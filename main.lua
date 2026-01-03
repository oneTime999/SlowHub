local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variáveis globais
_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBosses = false,
    AutoHaki = false,
    Codes = false,
    Shop = false,
    Stats = false,
    SelectedWeapon = nil
}

-- Sistema de salvamento de configurações
local HttpService = game:GetService("HttpService")
local configFolder = "SlowHub"
local configFile = configFolder .. "/config.json"

-- Cria a pasta se não existir
if not isfolder(configFolder) then
    makefolder(configFolder)
end

-- Função para salvar configurações (apenas Auto Farms e Auto Haki)
local function SaveConfig()
    pcall(function()
        local data = {
            AutoFarmLevel = _G.SlowHub.AutoFarmLevel,
            AutoFarmBosses = _G.SlowHub.AutoFarmBosses,
            AutoHaki = _G.SlowHub.AutoHaki
        }
        
        local json = HttpService:JSONEncode(data)
        writefile(configFile, json)
    end)
end

-- Função para carregar configurações
local function LoadConfig()
    if not isfile(configFile) then
        return
    end
    
    pcall(function()
        local json = readfile(configFile)
        local data = HttpService:JSONDecode(json)
        
        -- Aplicar apenas Auto Farms e Auto Haki
        _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
        _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
        _G.SlowHub.AutoHaki = data.AutoHaki or false
    end)
end

-- Salvar configuração automaticamente
_G.SaveConfig = SaveConfig

-- Carregar configurações antes de criar a janela
LoadConfig()

-- Criar janela
local Window = Rayfield:CreateWindow({
    Name = "Slow Hub",
    LoadingTitle = "Slow Hub",
    LoadingSubtitle = "by oneTime999",
    ConfigurationSaving = {
        Enabled = false
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- Criar tabs e salvar globalmente
_G.MainTab = Window:CreateTab("Main", 125686055318100)
_G.BossesTab = Window:CreateTab("Bosses", 105026320884681)
_G.ShopTab = Window:CreateTab("Shop", 77529802245049)
_G.StatsTab = Window:CreateTab("Stats", 125686055318100)
_G.MiscTab = Window:CreateTab("Misc", 106779103527235)

-- Salvar Rayfield globalmente
_G.Rayfield = Rayfield

-- Carregar conteúdo das tabs
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()

-- Salvar configurações ao fechar o jogo
game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("RayfieldLibrary", 10)
local RayfieldUI = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("RayfieldLibrary")

if RayfieldUI then
    game:GetService("RunService").Heartbeat:Connect(function()
        if not RayfieldUI.Parent then
            SaveConfig()
        end
    end)
end

-- Salvar periodicamente (a cada 30 segundos)
task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

-- Notificação
Rayfield:Notify({
    Title = "Slow Hub",
    Content = "Successfully loaded!",
    Duration = 5,
    Image = 125686055318100
})
