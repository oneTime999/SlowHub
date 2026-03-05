local Tab = _G.DungeonsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local autoDungeonScript = game:HttpGet(githubBase .. "AutoDungeon.lua")
if autoDungeonScript and autoDungeonScript ~= "" then
    local func = loadstring(autoDungeonScript)
    if func then task.spawn(function() pcall(func) end) end
end
