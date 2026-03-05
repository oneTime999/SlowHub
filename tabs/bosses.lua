local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local waitCount = 0
while not (_G.SlowHub.MainTabReady or _G.SlowHub.TabsLoaded) and waitCount < 50 do
    task.wait(0.1)
    waitCount = waitCount + 1
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

-- Auto Bosses (executa imediatamente)
local bossFunc = loadFunction(githubBase .. "AutoBosses.lua")
if bossFunc then
    pcall(bossFunc)
end

task.wait(0.1)

-- Auto Summon
local summonFunc = loadFunction(githubBase .. "AutoSummon.lua")
if summonFunc then
    task.spawn(function()
        pcall(summonFunc)
    end)
end

task.wait(0.1)

-- Mini Boss Farm
local miniBossFunc = loadFunction(githubBase .. "MiniBossFarm.lua")
if miniBossFunc then
    task.spawn(function()
        pcall(miniBossFunc)
    end)
end

_G.SlowHub.BossesTabReady = true
