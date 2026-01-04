local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateSection("Settings")

loadstring(game:HttpGet(githubBase .. "WeaponSelector.lua"))()

Tab:CreateSection("Auto Farm")

loadstring(game:HttpGet(githubBase .. "AutoLevel.lua"))()
