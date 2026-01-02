local Tab = _G.MainTab

Tab:AddToggle({
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
                        print("Auto Farm Level ativo")
                    end)
                end
            end)
        end
    end    
})
