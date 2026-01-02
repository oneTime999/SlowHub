_G.MainTab:AddToggle({
    Name = "Auto Farm Level",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoFarmLevel = Value
        
        if Value then
            spawn(function()
                while _G.SlowHub.AutoFarmLevel do
                    wait()
                    pcall(function()
                        -- Sua lógica de Auto Farm Level aqui
                        -- Exemplo:
                        -- local player = game.Players.LocalPlayer
                        -- local character = player.Character
                        -- -- Código de farm
                    end)
                end
            end)
        end
    end    
})
