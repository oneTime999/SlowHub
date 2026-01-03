local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Mapeamento das espadas para os NPCs
local SwordNPCs = {
    ["Ragna"] = function() return workspace.ServiceNPCs:FindFirstChild("RagnaBuyer") end,
    ["Jinwoo"] = function() return workspace:FindFirstChild("JinwooMovesetNPC") end,
    ["Saber"] = function() return workspace.ServiceNPCs:FindFirstChild("ExchangeNPC") end,
    ["Dark Blade"] = function() return workspace.ServiceNPCs:FindFirstChild("DarkBladeNPC") end,
    ["Katana"] = function() return workspace.ServiceNPCs:FindFirstChild("Katana") end
}

-- Variável para armazenar a espada selecionada
_G.SlowHub.SelectedSwordNPC = _G.SlowHub.SelectedSwordNPC or "Ragna"

-- Função para normalizar o valor do dropdown
local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

-- Função para teleportar para o NPC
local function teleportToNPC()
    local selectedSword = _G.SlowHub.SelectedSwordNPC
    
    if not selectedSword or selectedSword == "" then
        Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Please select a sword first!",
            Duration = 3,
            Image = 105026320884681
        })
        return
    end
    
    local getNPC = SwordNPCs[selectedSword]
    if not getNPC then
        Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Invalid sword selection!",
            Duration = 3,
            Image = 105026320884681
        })
        return
    end
    
    local npc = getNPC()
    
    if npc then
        local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso") or npc:FindFirstChild("Head")
        
        if npcRoot and Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if playerRoot then
                -- Teleporta o player para frente do NPC
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
                
                Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Teleported to " .. selectedSword .. " NPC!",
                    Duration = 2,
                    Image = 105026320884681
                })
            else
                Rayfield:Notify({
                    Title = "Slow Hub",
                    Content = "Character not found!",
                    Duration = 3,
                    Image = 105026320884681
                })
            end
        else
            Rayfield:Notify({
                Title = "Slow Hub",
                Content = "NPC Root not found!",
                Duration = 3,
                Image = 105026320884681
            })
        end
    else
        Rayfield:Notify({
            Title = "Slow Hub",
            Content = "NPC " .. selectedSword .. " not found in workspace!",
            Duration = 3,
            Image = 105026320884681
        })
    end
end

-- Dropdown para selecionar a espada
Tab:CreateDropdown({
    Name = "Select Sword NPC",
    Options = {"Ragna", "Jinwoo", "Saber", "Dark Blade", "Katana"},
    CurrentOption = {_G.SlowHub.SelectedSwordNPC},
    Flag = "SwordNPCDropdown",
    Callback = function(Option)
        _G.SlowHub.SelectedSwordNPC = normalizeValue(Option)
        
        Rayfield:Notify({
            Title = "Slow Hub",
            Content = "Selected: " .. _G.SlowHub.SelectedSwordNPC,
            Duration = 2,
            Image = 105026320884681
        })
    end
})

-- Botão para teleportar para o NPC selecionado
Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
