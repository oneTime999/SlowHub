local Tab = _G.RollsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local raceRollScript = game:HttpGet(githubBase .. "RaceRoll.lua")
if raceRollScript and raceRollScript ~= "" then
    local func = loadstring(raceRollScript)
    if func then task.spawn(function() pcall(func) end) end
end

task.wait(0.05)

local traitRollScript = game:HttpGet(githubBase .. "TraitRoll.lua")
if traitRollScript and traitRollScript ~= "" then
    local func = loadstring(traitRollScript)
    if func then task.spawn(function() pcall(func) end) end
end
