local Tab = _G.MiscTab

Tab:CreateToggle({
    Name = "Auto Haki",
    CurrentValue = false,
    Flag = "AutoHakiToggle",
    Callback = function(Value)
        _G.SlowHub.AutoHaki = Value
        
        if Value then
            spawn(function()
                while _G.SlowHub.AutoHaki do
                    wait(0.1)
                    pcall(function()
                        -- Your Auto Haki logic here
                    end)
                end
            end)
        end
    end
})
