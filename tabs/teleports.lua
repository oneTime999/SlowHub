-- Teleports Tab
local Tab = _G.TeleportsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

local npcScript = game:HttpGet(githubBase .. "NPCsTeleport.lua")
if npcScript and npcScript ~= "" then
    local func = loadstring(npcScript)
    if func then pcall(func) end
end
