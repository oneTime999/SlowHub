local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local function loadFunction(url)
    local success, content = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success or type(content) ~= "string" or content == "" 
        or content:match("<!DOCTYPE html>") or content:match("<html>") then
        return nil
    end
    
    local func, err = loadstring(content)
    if not func then
        return nil
    end
    
    return func
end

local function loadAndSpawn(url)
    local func = loadFunction(url)
    if func then
        task.spawn(function()
            pcall(func)
        end)
    end
end

-- Auto Haki
loadAndSpawn(githubBase .. "AutoHaki.lua")
task.wait(0.05)

-- Auto Observation
loadAndSpawn(githubBase .. "AutoObservation.lua")
task.wait(0.05)

-- Auto Conqueror Haki
loadAndSpawn(githubBase .. "AutoConq.lua")
task.wait(0.05)

-- Auto Ascend
loadAndSpawn(githubBase .. "AutoAscend.lua")
task.wait(0.1)

-- Auto Skill
loadAndSpawn(githubBase .. "AutoSkill.lua")
task.wait(0.05)

-- Slime Key
loadAndSpawn(githubBase .. "SlimeKey.lua")
task.wait(0.05)

-- Divine Grail
loadAndSpawn(githubBase .. "DivineGrail.lua")
task.wait(0.1)

-- Codes
loadAndSpawn(githubBase .. "Codes.lua")
task.wait(0.1)

-- Anti AFK
loadAndSpawn(githubBase .. "AntiAFK.lua")
task.wait(0.05)

-- Rejoin
loadAndSpawn(githubBase .. "Rejoin.lua")
task.wait(0.05)

-- Server Hop
loadAndSpawn(githubBase .. "ServerHop.lua")
