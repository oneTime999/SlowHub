local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Secao Configuracoes
Tab:CreateSection("Settings")

-- Carregar Seletor de Armas
loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

-- Secao Auto Farm
Tab:CreateSection("Auto Farm")

-- Carregar Auto Level
loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()
