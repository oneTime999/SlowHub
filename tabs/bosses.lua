local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Boss Farm")

loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()
