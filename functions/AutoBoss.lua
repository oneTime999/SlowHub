local Tab = _G.MainTab

Tab:AddToggle({
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
                        print("Auto Farm Boss ativo")
                    end)
                end
            end)
        end
    end    
})
