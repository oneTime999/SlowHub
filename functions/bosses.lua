local Tab = _G.BossesTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Seção: Boss Farm
Tab:CreateSection("Boss Farm")

-- Carregar Auto Bosses
loadstring(game:HttpGet(githubBase .. "AutoBosses.lua"))()
