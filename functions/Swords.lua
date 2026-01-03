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

-- Função para notificar com segurança
local function SafeNotify(title, content, duration)
    pcall(function()
        if _G.Rayfield then
            _G.Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = duration or 3,
                Image = 105026320884681
            })
        end
    end)
end

-- Função para pegar o HumanoidRootPart de um Model
local function getModelRoot(model)
    if not model then return nil end
    
    -- Se for um Model, procura dentro dele
    if model:IsA("Model") then
        return model:FindFirstChild("HumanoidRootPart") or 
               model:FindFirstChild("Torso") or 
               model:FindFirstChild("Head") or
               model.PrimaryPart
    end
    
    -- Se for uma Part diretamente
    return model
end

-- Função para teleportar para o NPC
local function teleportToNPC()
    local selectedSword = _G.SlowHub.SelectedSwordNPC
    
    if not selectedSword or selectedSword == "" then
        SafeNotify("Slow Hub", "Please select a sword first!")
        return
    end
    
    local getNPC = SwordNPCs[selectedSword]
    if not getNPC then
        SafeNotify("Slow Hub", "Invalid sword selection!")
        return
    end
    
    local npc = getNPC()
    
    if npc then
        local npcRoot = getModelRoot(npc)
        
        if npcRoot and Player.Character then
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if playerRoot then
                -- Teleporta o player para frente do NPC
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
                
                SafeNotify("Slow Hub", "Teleported to " .. selectedSword .. " NPC!", 2)
            else
                SafeNotify("Slow Hub", "Character not found!")
            end
        else
            SafeNotify("Slow Hub", "NPC Root not found!")
        end
    else
        SafeNotify("Slow Hub", "NPC " .. selectedSword .. " not found in workspace!")
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
        SafeNotify("Slow Hub", "Selected: " .. _G.SlowHub.SelectedSwordNPC, 2)
    end
})

-- Botão para teleportar para o NPC selecionado
Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
