local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Boss Farm Section
Tab:CreateLabel("Boss Farm")

loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()

-- Summon Section
Tab:CreateLabel("Summon")

loadstring(game:HttpGet(githubBase .. "AutoSummon.lua"))()

-- Mini Boss Farm Section
Tab:CreateLabel("Mini Boss Farm")

loadstring(game:HttpGet(githubBase .. "MiniBossFarm.lua"))()
