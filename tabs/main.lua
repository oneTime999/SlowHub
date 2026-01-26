local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Settings Section
Tab:CreateParagraph("SettingsSection", {
    Title = "Settings",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

-- Auto Farm Section
Tab:CreateParagraph("AutoFarmSection", {
    Title = "Auto Farm",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()

-- Auto Farm Selected Section
Tab:CreateParagraph("AutoFarmSelectedSection", {
    Title = "Auto Farm Selected",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua"))()

-- Auto Dungeon Section
Tab:CreateParagraph("AutoDungeonSection", {
    Title = "Auto Dungeon",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoDungeon.lua"))()

-- Auto Chest Section
Tab:CreateParagraph("AutoChestSection", {
    Title = "Auto Chest",
    Content = ""
})

loadstring(game:HttpGet(githubBase .. "AutoChest.lua"))()
