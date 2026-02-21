local Tab = _G.TeleportsTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

if not _G.SlowHub then
    repeat task.wait(0.1) until _G.SlowHub
end

Tab:CreateLabel("Teleports")

local teleportScript = game:HttpGet(githubBase .. "IslandsTeleport.lua")
if teleportScript and teleportScript ~= "" then
    local func = loadstring(teleportScript)
    if func then pcall(func) end
end
