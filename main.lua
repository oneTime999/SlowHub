-- Carregando Fluent
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Configurações globais
_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBosses = false,
    AutoSummon = false,
    AutoFarmMiniBosses = false,
    AutoFarmSelectedMob = false,
    AutoSkill = false,
    AutoChest = false,
    AutoHaki = false,
    AutoObservation = false,
    Codes = false,
    Shop = false,
    NPC = false,
    Stats = false,
    AntiAFK = false,
    SelectedWeapon = nil
}

-- Sistema de salvamento
local HttpService = game:GetService("HttpService")
local configFolder = "SlowHub"
local configFile = configFolder .. "/config.json"

if not isfolder(configFolder) then
    makefolder(configFolder)
end

local function SaveConfig()
    pcall(function()
        local data = {
            AutoFarmLevel = _G.SlowHub.AutoFarmLevel,
            AutoFarmBosses = _G.SlowHub.AutoFarmBosses,
            AutoHaki = _G.SlowHub.AutoHaki,
            AntiAFK = _G.SlowHub.AntiAFK,
            AutoSkill = _G.SlowHub.AutoSkill,
            AutoObservation = _G.SlowHub.AutoObservation
        }
        
        local json = HttpService:JSONEncode(data)
        writefile(configFile, json)
    end)
end

local function LoadConfig()
    if not isfile(configFile) then
        return
    end
    
    pcall(function()
        local json = readfile(configFile)
        local data = HttpService:JSONDecode(json)
        
        _G.SlowHub.AutoFarmLevel = data.AutoFarmLevel or false
        _G.SlowHub.AutoFarmBosses = data.AutoFarmBosses or false
        _G.SlowHub.AutoHaki = data.AutoHaki or false
        _G.SlowHub.AntiAFK = data.AntiAFK or false
        _G.SlowHub.AutoSkill = data.AutoSkill or false
        _G.SlowHub.AutoObservation = data.AutoObservation or false
    end)
end

_G.SaveConfig = SaveConfig

LoadConfig()

-- Criando a janela
local Window = Fluent:CreateWindow({
    Title = "Slow Hub",
    SubTitle = "by oneTime and Vagner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Criando as tabs
local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Bosses = Window:AddTab({ Title = "Bosses", Icon = "skull" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "settings" })
}

-- Salvando referências globais para uso nos outros scripts
_G.MainTab = Tabs.Main
_G.BossesTab = Tabs.Bosses
_G.ShopTab = Tabs.Shop
_G.StatsTab = Tabs.Stats
_G.MiscTab = Tabs.Misc
_G.Fluent = Fluent
_G.Options = Fluent.Options

-- Carregando os scripts das tabs
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/shop.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/stats.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()

-- Auto-save a cada 30 segundos
task.spawn(function()
    while task.wait(30) do
        SaveConfig()
    end
end)

-- Salvar quando a UI for fechada
local GUI = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ScreenGui", 10)
if GUI then
    game:GetService("RunService").Heartbeat:Connect(function()
        if not GUI.Parent then
            SaveConfig()
        end
    end)
end

-- Notificação de carregamento
Fluent:Notify({
    Title = "Slow Hub",
    Content = "Successfully loaded!",
    Duration = 5
})
