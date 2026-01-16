local Tab = _G.ShopTab
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local MeeleNPCs = {
    ["Qin Shi"] = function() return workspace:FindFirstChild("SukunaMovesetNPC") end,
    ["Sukuna"] = function() return workspace:FindFirstChild("GojoMovesetNPC") end,
    ["Gojo"] = function() return workspace.ServiceNPCs:FindFirstChild("ExchangeNPC") end,
    ["Yuji"] = function() return workspace.ServiceNPCs:FindFirstChild("YujiBuyerNPC") end -- Adicionado
}

_G.SlowHub.SelectedMeeleNPC = nil

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
                playerRoot.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 5)
            end
        end
    end)
end

local Dropdown = Tab:AddDropdown("SelectMeeleNPC", {
    Title = "Select Meele NPC",
    Values = {"Qin Shi", "Sukuna", "Gojo", "Yuji"}, -- Adicionado na lista
    Default = nil,
    Callback = function(Value)
        pcall(function()
            _G.SlowHub.SelectedMeeleNPC = tostring(Value)
        end)
    end
})

local Button = Tab:AddButton({
    Title = "Teleport to NPC",
    Callback = function()
        teleportToNPC()
    end
})
