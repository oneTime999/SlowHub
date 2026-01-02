local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variáveis globais
_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBoss = false,
    AutoHaki = false,
    SelectedWeapon = nil
}

-- Criar janela
local Window = Rayfield:CreateWindow({
    Name = "Slow Hub",
    LoadingTitle = "Slow Hub",
    LoadingSubtitle = "by oneTime999",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SlowHub",
        FileName = "SlowHubConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false
})

-- Criar Tab Main e salvar globalmente
_G.MainTab = Window:CreateTab("Main", 4483345998)

-- Salvar Rayfield globalmente para notificações
_G.Rayfield = Rayfield

-- Carregar Tab Main
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()

-- Notificação de boas-vindas
Rayfield:Notify({
    Title = "Slow Hub",
    Content = "Carregado com sucesso!",
    Duration = 5,
    Image = 4483345998
})
