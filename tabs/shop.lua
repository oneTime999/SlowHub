local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
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

-- Merchant
local merchantFunc = loadFunction(githubBase .. "Merchant.lua")
if merchantFunc then
    pcall(merchantFunc)
end
