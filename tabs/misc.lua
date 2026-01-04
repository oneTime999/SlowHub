local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Haki")

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()

Tab:CreateSection("Auto Skill")

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()

Tab:CreateSection("Codes")

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

Tab:CreateSection("AFK")

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
