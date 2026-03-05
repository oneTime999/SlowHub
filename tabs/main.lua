local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

local function loadScript(url)
    local ok, content = pcall(game.HttpGet, game, url)
    if not ok or type(content) ~= "string" or content == "" then return end
    local func, _ = loadstring(content)
    if func then task.spawn(function() pcall(func) end) end
end

loadScript(githubBase .. "WeaponSelector.lua")
task.wait(0.1)
loadScript(githubBase .. "AutoLevel.lua")
task.wait(0.1)
loadScript(githubBase .. "AutoFarmSelectedMob.lua")

_G.SlowHub.MainTabReady = true
