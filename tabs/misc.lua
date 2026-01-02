local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Haki
Tab:CreateSection("Haki")

-- Carregar Auto Haki
loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
