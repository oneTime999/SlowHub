local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Sword")

loadstring(game:HttpGet(githubBase .. "Swords.lua"))()
