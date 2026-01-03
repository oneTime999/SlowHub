local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Stats")

loadstring(game:HttpGet(githubBase .. "Stats.lua"))()
