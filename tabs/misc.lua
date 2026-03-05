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

loadScript(githubBase .. "AutoHaki.lua")
task.wait(0.05)
loadScript(githubBase .. "AutoObservation.lua")
task.wait(0.05)
loadScript(githubBase .. "AutoConq.lua")
task.wait(0.05)
loadScript(githubBase .. "AutoAscend.lua")
task.wait(0.05)
loadScript(githubBase .. "AutoSkill.lua")
task.wait(0.05)
loadScript(githubBase .. "SlimeKey.lua")
task.wait(0.05)
loadScript(githubBase .. "DivineGrail.lua")
task.wait(0.05)
loadScript(githubBase .. "Codes.lua")
task.wait(0.05)
loadScript(githubBase .. "AntiAFK.lua")
task.wait(0.05)
loadScript(githubBase .. "Rejoin.lua")
task.wait(0.05)
loadScript(githubBase .. "ServerHop.lua")
