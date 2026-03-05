local Tab = _G.RollsTab
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

-- Race Roll
loadAndSpawn(githubBase .. "RaceRoll.lua")
task.wait(0.05)

-- Trait Roll
loadAndSpawn(githubBase .. "TraitRoll.lua")
task.wait(0.05)

-- Clan Roll
loadAndSpawn(githubBase .. "ClanRoll.lua")
