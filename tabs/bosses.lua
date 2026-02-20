local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- CORREÇÃO: Esperar MainTab carregar primeiro (garante que flags existam)
if not _G.SlowHub then
    warn("SlowHub: SlowHub not initialized! Waiting...")
    repeat task.wait(0.1) until _G.SlowHub
end

-- CORREÇÃO: Esperar AutoLevel e AutoFarmSelectedMob carregarem para evitar corrida
local waitCount = 0
while not (_G.SlowHub.MainTabReady or _G.SlowHub.TabsLoaded) and waitCount < 50 do
    task.wait(0.1)
    waitCount = waitCount + 1
end

if waitCount >= 50 then
    warn("SlowHub: Timeout waiting for MainTab, proceeding anyway...")
end

Tab:CreateLabel("Boss Farm")

-- CORREÇÃO: Carregar AutoBosses com tratamento de erro
local bossScript = game:HttpGet(githubBase .. "AutoBosses.lua")
if bossScript and bossScript ~= "" then
    local func, err = loadstring(bossScript)
    if func then
        -- CORREÇÃO: Executar síncrono para garantir que boss respeite flags existentes
        local success, result = pcall(func)
        if not success then
            warn("SlowHub AutoBosses Error: " .. tostring(result))
        else
            print("SlowHub: AutoBosses loaded successfully")
        end
    else
        warn("SlowHub AutoBosses Load Error: " .. tostring(err))
    end
else
    warn("SlowHub: Failed to download AutoBosses.lua")
end

task.wait(0.1)

Tab:CreateLabel("Summon")

local summonScript = game:HttpGet(githubBase .. "AutoSummon.lua")
if summonScript and summonScript ~= "" then
    local func, err = loadstring(summonScript)
    if func then
        task.spawn(function()
            local success, result = pcall(func)
            if not success then
                warn("SlowHub AutoSummon Error: " .. tostring(result))
            end
        end)
    else
        warn("SlowHub AutoSummon Load Error: " .. tostring(err))
    end
end

task.wait(0.1)

Tab:CreateLabel("Mini Boss Farm")

local miniBossScript = game:HttpGet(githubBase .. "MiniBossFarm.lua")
if miniBossScript and miniBossScript ~= "" then
    local func, err = loadstring(miniBossScript)
    if func then
        task.spawn(function()
            local success, result = pcall(func)
            if not success then
                warn("SlowHub MiniBossFarm Error: " .. tostring(result))
            end
        end)
    else
        warn("SlowHub MiniBossFarm Load Error: " .. tostring(err))
    end
end

-- CORREÇÃO: Marcar que BossesTab terminou
_G.SlowHub.BossesTabReady = true
print("SlowHub: Bosses tab fully loaded")
