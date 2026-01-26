local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Boss Farm Section
Tab:CreateParagraph("BossFarmSection", {
    Title = "Boss Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()

-- Summon Section
Tab:CreateParagraph("SummonSection", {
    Title = "Summon",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoSummon.lua"))()

-- Mini Boss Farm Section
Tab:CreateParagraph("MiniBossFarmSection", {
    Title = "Mini Boss Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "MiniBossFarm.lua"))()
