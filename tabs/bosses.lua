local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateLabel("Boss Farm")
loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()

Tab:CreateLabel("Summon")
loadstring(game:HttpGet(githubBase .. "AutoSummon.lua"))()

Tab:CreateLabel("Mini Boss Farm")
loadstring(game:HttpGet(githubBase .. "MiniBossFarm.lua"))()
