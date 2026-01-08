local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("NPCs")

loadstring(game:HttpGet(githubBase .. "NPC.lua"))()

Tab:CreateSection("Sword")

loadstring(game:HttpGet(githubBase .. "Swords.lua"))()

Tab:CreateSection("Meele")

loadstring(game:HttpGet(githubBase .. "Meele.lua"))()
