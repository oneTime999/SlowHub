local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/jensonhirst/Orion/main/source')))()

-- Variáveis globais
_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBoss = false,
    AutoHaki = false
}

-- Criar janela
local Window = OrionLib:MakeWindow({
    Name = "Slow Hub",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "SlowHub"
})

-- Criar Tab Main
_G.MainTab = Window:MakeTab({
    Name = "Main",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Carregar Tab Main
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()

-- Inicializar
OrionLib:Init()

-- Notificação
OrionLib:MakeNotification({
    Name = "Slow Hub",
    Content = "Carregado com sucesso!",
    Image = "rbxassetid://4483345998",
    Time = 5
})
