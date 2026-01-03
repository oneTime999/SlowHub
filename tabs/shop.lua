local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Sword
Tab:CreateSection("Sword")

-- Carregar Sword
loadstring(game:HttpGet(githubBase .. "Swords.lua"))()
