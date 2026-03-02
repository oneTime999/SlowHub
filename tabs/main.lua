local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

Tab:CreateLabel("Settings")

local weaponScript = game:HttpGet(githubBase .. "WeaponSelector.lua")
if weaponScript and weaponScript ~= "" then
    local func = loadstring(weaponScript)
    if func then pcall(func) end
end

task.wait(0.1)

Tab:CreateLabel("Auto Farm")

local levelScript = game:HttpGet(githubBase .. "AutoLevel.lua")
if levelScript and levelScript ~= "" then
    local func = loadstring(levelScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

task.wait(0.2)

Tab:CreateLabel("Auto Farm Selected")

local mobScript = game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua")
if mobScript and mobScript ~= "" then
    local func = loadstring(mobScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

task.wait(0.2)

Tab:CreateLabel("Auto Dungeon or Boss Rush")

local dungeonScript = game:HttpGet(githubBase .. "AutoDungeon.lua")
if dungeonScript and dungeonScript ~= "" then
    local func = loadstring(dungeonScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

_G.SlowHub.MainTabReady = true
