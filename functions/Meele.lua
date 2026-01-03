local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

-- Mapeamento dos meeles para os NPCs
local MeeleNPCs = {
    ["Sukuna"] = function() return workspace:FindFirstChild("SukunaMovesetNPC") end,
    ["Gojo"] = function() return workspace:FindFirstChild("GojoMovesetNPC") end
}

-- Variável para armazenar o meele selecionado
_G.SlowHub.SelectedMeeleNPC = _G.SlowHub.SelectedMeeleNPC or "Sukuna"

-- Função para normalizar o valor do dropdown
local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
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
    pcall(function()
        local selectedMeele = _G.SlowHub.SelectedMeeleNPC
        
        if not selectedMeele or selectedMeele == "" then
            return
        end
        
        local getNPC = MeeleNPCs[selectedMeele]
        if not getNPC then
            return
        end
        
        local npc = getNPC()
        
        if npc and Player.Character then
            local npcRoot = getModelRoot(npc)
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if npcRoot and playerRoot then
                -- Teleporta o player para frente do NPC
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end)
end

-- Dropdown para selecionar o meele
Tab:CreateDropdown({
    Name = "Select Meele NPC",
    Options = {"Sukuna", "Gojo"},
    CurrentOption = {_G.SlowHub.SelectedMeeleNPC},
    Flag = "MeeleNPCDropdown",
    Callback = function(Option)
        pcall(function()
            _G.SlowHub.SelectedMeeleNPC = normalizeValue(Option)
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
