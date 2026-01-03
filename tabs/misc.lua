local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Secao Haki
Tab:CreateSection("Haki")

-- Carregar Auto Haki
loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()

-- Secao Codes
Tab:CreateSection("Codes")

-- Carregar Reedem All Codes
loadstring(game:HttpGet(githubBase .. "Codes.lua"))()
