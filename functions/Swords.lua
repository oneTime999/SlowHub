local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Mapeamento das espadas para os NPCs
local SwordNPCs = {
    ["Ragna"] = "workspace.ServiceNPCs.RagnaBuyer",
    ["Jinwoo"] = "workspace.JinwooMovesetNPC",
    ["Saber"] = "workspace.ServiceNPCs.ExchangeNPC",
    ["Dark Blade"] = "workspace.ServiceNPCs.DarkBladeNPC",
    ["Katana"] = "workspace.ServiceNPCs.Katana"
}

-- Variável para armazenar a espada selecionada
local selectedSword = "Ragna"

-- Função para normalizar o valor do dropdown
local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

-- Função para pegar o NPC pela espada selecionada
local function getNPCFromPath(path)
    local npc = nil
    
    pcall(function()
        -- Separa o caminho
        local parts = {}
        for part in string.gmatch(path, "[^.]+") do
            table.insert(parts, part)
        end
        
        -- Navega pelo workspace
        local current = game
        for _, part in ipairs(parts) do
            if current then
                current = current:FindFirstChild(part)
            end
        end
        
        npc = current
    end)
    
    return npc
end

-- Função para teleportar para o NPC
local function teleportToNPC()
    if not selectedSword or selectedSword == "" then
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Please select a sword first!",
                Duration = 3,
                Image = 105026320884681
            })
        end)
        return
    end
    
    local npcPath = SwordNPCs[selectedSword]
    if not npcPath then
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Invalid sword selection!",
                Duration = 3,
                Image = 105026320884681
            })
        end)
        return
    end
    
    local npc = getNPCFromPath(npcPath)
    
    if npc then
        local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
        
        if npcRoot and Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if playerRoot then
                pcall(function()
                    -- Teleporta o player para frente do NPC
                    playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
                    
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Teleported to " .. selectedSword .. " NPC!",
                        Duration = 2,
                        Image = 105026320884681
                    })
                end)
            else
                pcall(function()
                    _G.Rayfield:Notify({
                        Title = "Slow Hub",
                        Content = "Character not found!",
                        Duration = 3,
                        Image = 105026320884681
                    })
                end)
            end
        else
            pcall(function()
                _G.Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "NPC not found or invalid!",
                    Duration = 3,
                    Image = 105026320884681
                })
            end)
        end
    else
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "NPC " .. selectedSword .. " not found in workspace!",
                Duration = 3,
                Image = 105026320884681
            })
        end)
    end
end

-- Dropdown para selecionar a espada
Tab:CreateDropdown({
    Name = "Select Sword NPC",
    Options = {"Ragna", "Jinwoo", "Saber", "Dark Blade", "Katana"},
    CurrentOption = {"Ragna"},
    Flag = "SwordNPCDropdown",
    Callback = function(Option)
        selectedSword = normalizeValue(Option)
        
        pcall(function()
            _G.Rayfield:Notify({
                Title = "Slow Hub",
                Content = "Selected: " .. selectedSword,
                Duration = 2,
                Image = 105026320884681
            })
        end)
    end
})

-- Botão para teleportar para o NPC selecionado
Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
