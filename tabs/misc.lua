local Tab = _G.MiscTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- CORREÇÃO: Verificar inicialização
if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

-- Hakis Section
Tab:CreateLabel("Hakis and Ascend")

local hakiScript = game:HttpGet(githubBase .. "AutoHaki.lua")
if hakiScript and hakiScript ~= "" then
    local func = loadstring(hakiScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AutoHaki Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local obsScript = game:HttpGet(githubBase .. "AutoObservation.lua")
if obsScript and obsScript ~= "" then
    local func = loadstring(obsScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AutoObservation Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local conqScript = game:HttpGet(githubBase .. "AutoConq.lua")
if conqScript and conqScript ~= "" then
    local func = loadstring(conqScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AutoConq Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local ascendScript = game:HttpGet(githubBase .. "AutoAscend.lua")
if ascendScript and ascendScript ~= "" then
    local func = loadstring(ascendScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AutoAscend Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.1)

-- Auto Skill Section
Tab:CreateLabel("Auto Skill and Key Craft")

local skillScript = game:HttpGet(githubBase .. "AutoSkill.lua")
if skillScript and skillScript ~= "" then
    local func = loadstring(skillScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AutoSkill Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local slimeScript = game:HttpGet(githubBase .. "SlimeKey.lua")
if slimeScript and slimeScript ~= "" then
    local func = loadstring(slimeScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub SlimeKey Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local grailScript = game:HttpGet(githubBase .. "DivineGrail.lua")
if grailScript and grailScript ~= "" then
    local func = loadstring(grailScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub DivineGrail Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.1)

-- Codes Section
Tab:CreateLabel("Codes")

local codesScript = game:HttpGet(githubBase .. "Codes.lua")
if codesScript and codesScript ~= "" then
    local func = loadstring(codesScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub Codes Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.1)

-- Config Section
Tab:CreateLabel("Config")

local antiAFKScript = game:HttpGet(githubBase .. "AntiAFK.lua")
if antiAFKScript and antiAFKScript ~= "" then
    local func = loadstring(antiAFKScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub AntiAFK Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local rejoinScript = game:HttpGet(githubBase .. "Rejoin.lua")
if rejoinScript and rejoinScript ~= "" then
    local func = loadstring(rejoinScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub Rejoin Error: " .. tostring(err)) end
        end)
    end
end

task.wait(0.05)

local hopScript = game:HttpGet(githubBase .. "ServerHop.lua")
if hopScript and hopScript ~= "" then
    local func = loadstring(hopScript)
    if func then
        task.spawn(function()
            local success, err = pcall(func)
            if not success then warn("SlowHub ServerHop Error: " .. tostring(err)) end
        end)
    end
end

print("SlowHub: Misc tab fully loaded")
