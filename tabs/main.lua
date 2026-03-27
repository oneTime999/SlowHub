local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

local weaponScript = game:HttpGet(githubBase .. "WeaponSelector.lua")
if weaponScript and weaponScript ~= "" then
    local func = loadstring(weaponScript)
    if func then pcall(func) end
end

task.wait(0.2)

local mobScript = game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua")
if mobScript and mobScript ~= "" then
    local func = loadstring(mobScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

task.wait(0.2)

local dungeonScript = game:HttpGet(githubBase .. "AutoDungeon.lua")
if dungeonScript and dungeonScript ~= "" then
    local func = loadstring(dungeonScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

_G.SlowHub.MainTabReady = true
