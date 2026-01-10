local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local SwordNPCs = {
    ["Aizen"] = function() return workspace:FindFirstChild("AizenMovesetNPC") end,
    ["Ragna"] = function() return workspace.ServiceNPCs:FindFirstChild("RagnaBuyer") end,
    ["Jinwoo"] = function() return workspace:FindFirstChild("JinwooMovesetNPC") end,
    ["Saber"] = function() return workspace.ServiceNPCs:FindFirstChild("ExchangeNPC") end,
    ["Dark Blade"] = function() return workspace.ServiceNPCs:FindFirstChild("DarkBladeNPC") end,
    ["Katana"] = function() return workspace.ServiceNPCs:FindFirstChild("Katana") end
}

_G.SlowHub.SelectedSwordNPC = _G.SlowHub.SelectedSwordNPC or "Ragna"

local function normalizeValue(Value)
    if type(Value) == "table" then
        return tostring(Value[1] or "")
    end
    return tostring(Value or "")
end

local function getModelRoot(model)
    if not model then return nil end
    
    if model:IsA("Model") then
        return model:FindFirstChild("HumanoidRootPart") or 
               model:FindFirstChild("Torso") or 
               model:FindFirstChild("Head") or
               model.PrimaryPart
    end
    
    return model
end

local function teleportToNPC()
    pcall(function()
        local selectedSword = _G.SlowHub.SelectedSwordNPC
        
        if not selectedSword or selectedSword == "" then  -- ✅ CORRIGIDO
            return
        end
        
        local getNPC = SwordNPCs[selectedSword]
        if not getNPC then
            return
        end
        
        local npc = getNPC()
        
        if npc and Player.Character then
            local npcRoot = getModelRoot(npc)
            local playerRoot = Player.Character:FindFirstChild("HumanoidRootPart")
            
            if npcRoot and playerRoot then
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end)
end

Tab:CreateDropdown({
    Name = "Select Sword NPC",
    Options = {"Aizen", "Ragna", "Jinwoo", "Saber", "Dark Blade", "Katana"},
    CurrentOption = {_G.SlowHub.SelectedSwordNPC},
    Flag = "SwordNPCDropdown",
    Callback = function(Option)
        pcall(function()
            _G.SlowHub.SelectedSwordNPC = normalizeValue(Option)
        end)
    end
})

Tab:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end,
})
