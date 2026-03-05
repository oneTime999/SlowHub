local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local function loadScript(url)
    local ok, content = pcall(game.HttpGet, game, url)
    if not ok or type(content) ~= "string" or content == "" then return end
    local func, _ = loadstring(content)
    if func then task.spawn(function() pcall(func) end) end
end

loadScript(githubBase .. "IslandsTeleport.lua")
task.wait(0.1)
loadScript(githubBase .. "NPCsTeleport.lua")
