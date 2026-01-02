local Tab = _G.MainTab

Tab:CreateToggle({
    Name = "Auto Farm Bosses",
    CurrentValue = false,
    Flag = "AutoFarmBossToggle",
    Callback = function(Value)
        _G.SlowHub.AutoFarmBoss = Value
        
        if Value then
            spawn(function()
                while _G.SlowHub.AutoFarmBoss do
                    wait()
                    pcall(function()
                        -- Your Auto Farm Boss logic here
                    end)
                end
            end)
        end
    end
})
