local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local ascendScript = game:HttpGet(githubBase .. "AutoAscend.lua")
if ascendScript and ascendScript ~= "" then
    local func = loadstring(ascendScript)
    if func then task.spawn(function() pcall(func) end) end
end

task.wait(0.05)

local antiAFKScript = game:HttpGet(githubBase .. "AntiAFK.lua")
if antiAFKScript and antiAFKScript ~= "" then
    local func = loadstring(antiAFKScript)
    if func then task.spawn(function() pcall(func) end) end
end

task.wait(0.05)

local rejoinScript = game:HttpGet(githubBase .. "Rejoin.lua")
if rejoinScript and rejoinScript ~= "" then
    local func = loadstring(rejoinScript)
    if func then task.spawn(function() pcall(func) end) end
end

task.wait(0.05)

local hopScript = game:HttpGet(githubBase .. "ServerHop.lua")
if hopScript and hopScript ~= "" then
    local func = loadstring(hopScript)
    if func then task.spawn(function() pcall(func) end) end
end
