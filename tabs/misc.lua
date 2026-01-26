local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Hakis Section
Tab:CreateLabel("Hakis")

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoObservation.lua"))()

-- Auto Skill Section
Tab:CreateLabel("Auto Skill")

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()

-- Codes Section
Tab:CreateLabel("Codes")

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

-- Config Section
Tab:CreateLabel("Config")

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
loadstring(game:HttpGet(githubBase .. "Rejoin.lua"))()
loadstring(game:HttpGet(githubBase .. "ServerHop.lua"))()
