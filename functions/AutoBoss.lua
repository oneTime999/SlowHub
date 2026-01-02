_G.MainTab:AddToggle({
    Name = "Auto Farm Bosses",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmBoss = Value
        
        if Value then
            spawn(function()
                while _G.SlowHub.AutoFarmBoss do
                    wait()
                    pcall(function()
                        -- Sua lógica de Auto Farm Boss aqui
                        -- Exemplo:
                        -- local bosses = workspace.Enemies:GetChildren()
                        -- for _, boss in pairs(bosses) do
                        --     if boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
                        --         -- Atacar boss
                        --     end
                        -- end
                    end)
                end
            end)
        end
    end    
})
