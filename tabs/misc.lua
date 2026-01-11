local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Hakis Section
Tab:AddParagraph({
    Title = "Hakis",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoHaki.lua"))()
loadstring(game:HttpGet(githubBase .. "AutoObservation.lua"))()

-- Auto Skill Section
Tab:AddParagraph({
    Title = "Auto Skill",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoSkill.lua"))()

-- Codes Section
Tab:AddParagraph({
    Title = "Codes",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Codes.lua"))()

-- AFK Section
Tab:AddParagraph({
    Title = "AFK",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AntiAFK.lua"))()
