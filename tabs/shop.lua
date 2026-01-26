local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateLabel("Merchant")

loadstring(game:HttpGet(githubBase .. "Merchant.lua"))()
