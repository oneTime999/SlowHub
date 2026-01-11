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

-- Criando a janela com tema escuro personalizado
local Window = Fluent:CreateWindow({
    Title = "Slow Hub",
    SubTitle = "by oneTime and Vagner",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false, -- Desativa efeito acrílico para preto sólido
    Theme = "Darker",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Customização adicional para preto forte
pcall(function()
    local gui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ScreenGui", 5)
    if gui then
        -- Deixa o fundo preto forte
        local mainFrame = gui:FindFirstChild("Frame")
        if mainFrame then
            mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15) -- Preto muito escuro
            
            -- Aumenta o tamanho da fonte das tabs
            for _, obj in pairs(mainFrame:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    if obj.Name:find("Tab") or obj.Parent and obj.Parent.Name:find("Tab") then
                        obj.TextSize = 16 -- Fonte maior para tabs
                        obj.Font = Enum.Font.GothamBold -- Fonte em negrito
                    end
                end
            end
        end
    end
end)

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
