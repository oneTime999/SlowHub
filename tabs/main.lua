local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Settings Section
Tab:CreateLabel("Settings")

loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

-- Auto Farm Section
Tab:CreateLabel("Auto Farm")

loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()

-- Auto Farm Selected Section
Tab:CreateLabel("Auto Farm Selected")

loadstring(game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua"))()

-- Auto Dungeon Section
Tab:CreateLabel("Auto Dungeon")

loadstring(game:HttpGet(githubBase .. "AutoDungeon.lua"))()
