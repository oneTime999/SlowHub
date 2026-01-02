_G.MainTab:AddToggle({
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
                        -- Exemplo:
                        -- game:GetService("VirtualInputManager"):SendKeyEvent(true, "T", false, game)
                        -- wait(0.1)
                        -- game:GetService("VirtualInputManager"):SendKeyEvent(false, "T", false, game)
                    end)
                end
            end)
        end
    end    
})
