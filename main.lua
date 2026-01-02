local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variáveis globais
_G.SlowHub = {
    AutoFarmLevel = false,
    AutoFarmBoss = false,
    AutoHaki = false,
    Codes = false,
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

-- Criar tabs e salvar globalmente
_G.MainTab = Window:CreateTab("Main", 4483345998)
_G.BossesTab = Window:CreateTab("Bosses", 4483345998)
_G.MiscTab = Window:CreateTab("Misc", 4483345998)

-- Salvar Rayfield globalmente
_G.Rayfield = Rayfield

-- Carregar conteúdo das tabs
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/main.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/bosses.lua"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/oneTime999/SlowHub/main/tabs/misc.lua"))()

-- Notificação
Rayfield:Notify({
    Title = "Slow Hub",
    Content = "Successfully loaded!",
    Duration = 5,
    Image = 4483345998
})
