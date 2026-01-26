local Tab = _G.StatsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Stats Section
Tab:CreateParagraph("StatsSection", {
    Title = "Stats",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Stats.lua"))()
