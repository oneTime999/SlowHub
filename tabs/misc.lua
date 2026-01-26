local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Hakis Section
Tab:CreateParagraph("HakisSection", {
    Title = "Hakis",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoObservation.lua"))()

-- Auto Skill Section
Tab:CreateParagraph("AutoSkillSection", {
    Title = "Auto Skill",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()

-- Codes Section
Tab:CreateParagraph("CodesSection", {
    Title = "Codes",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

-- Config Section
Tab:CreateParagraph("ConfigSection", {
    Title = "Config",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
loadstring(game:HttpGet(githubBase .. "Rejoin.lua"))()
loadstring(game:HttpGet(githubBase .. "ServerHop.lua"))()
