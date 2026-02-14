local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not _G.SlowHub then _G.SlowHub = {} end
_G.SlowHub.AutoCraftSlime = false

Tab:CreateSection("Crafting Settings")

Tab:CreateToggle({
    Name = "Auto Craft Slime Key",
    CurrentValue = false,
    Flag = "AutoCraftSlimeKey",
    Callback = function(Value)
        _G.SlowHub.AutoCraftSlime = Value
        
        if Value then
            task.spawn(function()
                while _G.SlowHub.AutoCraftSlime do
                    pcall(function()
                        local args = {
                            [1] = "SlimeKey",
                        }
                        ReplicatedStorage.Remotes.RequestSlimeCraft:InvokeServer(unpack(args))
                    end)
                    
                    task.wait(2)
                end
            end)
        end
    end
})
