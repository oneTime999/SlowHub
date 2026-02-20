local Tab = _G.MainTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Settings Section
Tab:CreateLabel("Settings")

-- CORREÇÃO: Carregar WeaponSelector e esperar completar
local weaponScript = game:HttpGet(githubBase .. "WeaponSelector.lua")
if weaponScript and weaponScript ~= "" then
    local func, err = loadstring(weaponScript)
    if func then
        local success, result = pcall(func)
        if not success then
            warn("SlowHub WeaponSelector Error: " .. tostring(result))
        end
    else
        warn("SlowHub WeaponSelector Load Error: " .. tostring(err))
    end
end

task.wait(0.1) -- Pequeno delay para garantir inicialização

-- Auto Farm Section
Tab:CreateLabel("Auto Farm")

-- CORREÇÃO: Carregar AutoLevel com verificação de erro
local levelScript = game:HttpGet(githubBase .. "AutoLevel.lua")
if levelScript and levelScript ~= "" then
    local func, err = loadstring(levelScript)
    if func then
        -- CORREÇÃO: Executar em task.spawn mas com controle de ordem
        task.spawn(function()
            local success, result = pcall(func)
            if not success then
                warn("SlowHub AutoLevel Error: " .. tostring(result))
            else
                print("SlowHub: AutoLevel loaded")
            end
        end)
    else
        warn("SlowHub AutoLevel Load Error: " .. tostring(err))
    end
end

task.wait(0.2) -- Delay para AutoLevel inicializar antes do próximo

-- Auto Farm Selected Section
Tab:CreateLabel("Auto Farm Selected")

-- CORREÇÃO: Carregar AutoFarmSelectedMob com verificação
local mobScript = game:HttpGet(githubBase .. "AutoFarmSelectedMob.lua")
if mobScript and mobScript ~= "" then
    local func, err = loadstring(mobScript)
    if func then
        task.spawn(function()
            local success, result = pcall(func)
            if not success then
                warn("SlowHub AutoFarmSelectedMob Error: " .. tostring(result))
            else
                print("SlowHub: AutoFarmSelectedMob loaded")
            end
        end)
    else
        warn("SlowHub AutoFarmSelectedMob Load Error: " .. tostring(err))
    end
end

task.wait(0.2)

-- Auto Dungeon Section
Tab:CreateLabel("Auto Dungeon")

local dungeonScript = game:HttpGet(githubBase .. "AutoDungeon.lua")
if dungeonScript and dungeonScript ~= "" then
    local func, err = loadstring(dungeonScript)
    if func then
        task.spawn(function()
            local success, result = pcall(func)
            if not success then
                warn("SlowHub AutoDungeon Error: " .. tostring(result))
            end
        end)
    else
        warn("SlowHub AutoDungeon Load Error: " .. tostring(err))
    end
end

-- CORREÇÃO: Marcar que MainTab terminou de carregar
_G.SlowHub.MainTabReady = true
print("SlowHub: Main tab fully loaded")
