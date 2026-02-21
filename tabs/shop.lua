local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

Tab:CreateLabel("Merchant")

local merchantScript = game:HttpGet(githubBase .. "Merchant.lua")
if merchantScript and merchantScript ~= "" then
    local func = loadstring(merchantScript)
    if func then pcall(func) end
end
