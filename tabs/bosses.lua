local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Boss Farm Section
Tab:AddParagraph({
    Title = "Boss Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()

-- Summon Section
Tab:AddParagraph({
    Title = "Summon",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoSummon.lua"))()

-- Mini Boss Farm Section
Tab:AddParagraph({
    Title = "Mini Boss Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "MiniBossFarm.lua"))()
