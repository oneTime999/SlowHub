local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- CORREÇÃO: Verificar inicialização
if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

Tab:CreateLabel("Merchant")

local merchantScript = game:HttpGet(githubBase .. "Merchant.lua")
if merchantScript and merchantScript ~= "" then
    local func, err = loadstring(merchantScript)
    if func then
        local success, result = pcall(func)
        if not success then
            warn("SlowHub Merchant Error: " .. tostring(result))
        else
            print("SlowHub: Merchant loaded")
        end
    else
        warn("SlowHub Merchant Load Error: " .. tostring(err))
    end
else
    warn("SlowHub: Failed to download Merchant.lua")
end

print("SlowHub: Shop tab fully loaded")
