local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- NPCs Section
Tab:AddParagraph({
    Title = "NPCs",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "NPC.lua"))()

-- Sword Section
Tab:AddParagraph({
    Title = "Sword",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Swords.lua"))()

-- Meele Section
Tab:AddParagraph({
    Title = "Meele",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Meele.lua"))()
