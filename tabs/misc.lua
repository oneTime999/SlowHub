local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Hakis")

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoObservation.lua"))()


Tab:CreateSection("Auto Skill")

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()

Tab:CreateSection("Codes")

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

Tab:CreateSection("AFK")

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
