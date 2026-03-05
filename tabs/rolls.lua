local Tab = _G.RollsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

Tab:CreateLabel("Race")

local autoRollScript = game:HttpGet(githubBase .. "RaceRoll.lua")
if autoRollScript and autoRollScript ~= "" then
    local func = loadstring(autoRollScript)
    if func then task.spawn(function() pcall(func) end) end
end
