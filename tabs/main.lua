local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

local function loadFunction(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or type(content) ~= "string" or content == "" 
        or content:match("<!DOCTYPE html>") or content:match("<html>") then
        return false
    end
    
    local func, err = loadstring(content)
    if not func then
        return false
    end
    
    return func
end

-- Weapon Selector (executa imediatamente)
local weaponFunc = loadFunction(githubBase .. "WeaponSelector.lua")
if weaponFunc then
    pcall(weaponFunc)
end

task.wait(0.1)

-- Auto Level
local levelFunc = loadFunction(githubBase .. "AutoLevel.lua")
if levelFunc then
    task.spawn(function()
        pcall(levelFunc)
    end)
end

task.wait(0.2)

-- Auto Farm Selected Mob
local mobFunc = loadFunction(githubBase .. "AutoFarmSelectedMob.lua")
if mobFunc then
    task.spawn(function()
        pcall(mobFunc)
    end)
end

task.wait(0.2)

-- Auto Dungeon
local dungeonFunc = loadFunction(githubBase .. "AutoDungeon.lua")
if dungeonFunc then
    task.spawn(function()
        pcall(dungeonFunc)
    end)
end

_G.SlowHub.MainTabReady = true
