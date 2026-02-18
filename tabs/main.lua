local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateLabel("Settings")

loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

Tab:CreateLabel("Auto Farm")

loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()

Tab:CreateLabel("Auto Farm Selected")

loadstring(game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua"))()

Tab:CreateLabel("Auto Dungeon")

loadstring(game:HttpGet(githubBase .. "AutoDungeon.lua"))()
