local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Merchant Section
Tab:CreateParagraph("MerchantSection", {
    Title = "Merchant",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Merchant.lua"))()

-- NPCs Section
Tab:CreateParagraph("NPCsSection", {
    Title = "NPCs",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "NPC.lua"))()

-- Sword Section
Tab:CreateParagraph("SwordSection", {
    Title = "Sword",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Swords.lua"))()

-- Meele Section
Tab:CreateParagraph("MeeleSection", {
    Title = "Meele",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "Meele.lua"))()
