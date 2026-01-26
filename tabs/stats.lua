local Tab = _G.StatsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Stats Section
Tab:CreateLabel("Stats")

loadstring(game:HttpGet(githubBase .. "Stats.lua"))()
