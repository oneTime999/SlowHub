local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Haki")

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()

Tab:CreateSection("Codes")

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()
