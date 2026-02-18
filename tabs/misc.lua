local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateLabel("Hakis and Ascend")

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoObservation.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoConq.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoAscend.lua"))()

Tab:CreateLabel("Auto Skill and Key Craft")

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()
loadstring(game:HttpGet(githubBase .. "SlimeKey.lua"))()
loadstring(game:HttpGet(githubBase .. "DivineGrail.lua"))()

Tab:CreateLabel("Codes")

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

Tab:CreateLabel("Config")

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
loadstring(game:HttpGet(githubBase .. "Rejoin.lua"))()
loadstring(game:HttpGet(githubBase .. "ServerHop.lua"))()
