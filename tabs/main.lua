local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Settings Section
Tab:AddParagraph({
    Title = "Settings",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

-- Auto Farm Section
Tab:AddParagraph({
    Title = "Auto Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()

-- Auto Farm Selected Section
Tab:AddParagraph({
    Title = "Auto Farm Selected",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua"))()

-- Auto Chest Section
Tab:AddParagraph({
    Title = "Auto Chest",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoChest.lua"))()
