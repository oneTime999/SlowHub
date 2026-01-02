local Tab = _G.MainTab

Tab:AddToggle({
    Name = "Auto Haki",
    Default = false,
    Callback = function(Value)
        _G.SlowHub.AutoHaki = Value
        
        if Value then
            spawn(function()
                while _G.SlowHub.AutoHaki do
                    wait(0.1)
                    pcall(function()
                        -- Sua lógica de Auto Haki aqui
                        print("Auto Haki ativo")
                    end)
                end
            end)
        end
    end    
})
