local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Configurações
Tab:CreateSection("Configurações")

-- Carregar Seletor de Armas
loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

-- Seção: Auto Farm
Tab:CreateSection("Auto Farm")

-- Carregar Auto Level
loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()
