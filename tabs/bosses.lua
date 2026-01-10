local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Boss Farm")

loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()

Tab:CreateSection("Summon")

loadstring(game:HttpGet(githubBase .. "AutoSummon.lua"))()

Tab:CreateSection("Mini Boss Farm")

loadstring(game:HttpGet(githubBase .. "MiniBossFarm.lua"))()
