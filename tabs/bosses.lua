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

Tab:CreateLabel("Boss Farm")

local bossScript = game:HttpGet(githubBase .. "AutoBosses.lua")
if bossScript and bossScript ~= "" then
    local func = loadstring(bossScript)
    if func then
        pcall(func)
    end
end

task.wait(0.1)

Tab:CreateLabel("Summon")

local summonScript = game:HttpGet(githubBase .. "AutoSummon.lua")
if summonScript and summonScript ~= "" then
    local func = loadstring(summonScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

task.wait(0.1)

Tab:CreateLabel("Mini Boss Farm")

local miniBossScript = game:HttpGet(githubBase .. "MiniBossFarm.lua")
if miniBossScript and miniBossScript ~= "" then
    local func = loadstring(miniBossScript)
    if func then
        task.spawn(function() pcall(func) end)
    end
end

_G.SlowHub.BossesTabReady = true
