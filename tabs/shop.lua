local Tab = _G.ShopTab
local githubBase = "https://raw.githubusercontent.com/oneTime999/SlowHub/main/functions/"

-- Verifica se a Tab existe
if not Tab then
    warn("❌ ShopTab não existe!")
    return
end

print("✅ ShopTab carregada com sucesso")

-- Seção: Sword
Tab:CreateSection("Sword")
print("✅ Seção Sword criada")

-- Carregar Sword com tratamento de erro
local success, err = pcall(function()
    loadstring(game:HttpGet(githubBase .. "Swords.lua"))()
end)

if success then
    print("✅ Swords.lua carregado com sucesso")
else
    warn("❌ Erro ao carregar Swords.lua:", err)
end
