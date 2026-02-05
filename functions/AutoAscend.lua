local Tab = _G.MiscTab
local ReplicatedStorage = game:GetService("ReplicatedStorage")

getgenv().AutoAscend = false

Tab:CreateToggle({
    Name = "Auto Ascend",
    CurrentValue = false,
    Callback = function(Value)
        getgenv().AutoAscend = Value
        
        if Value then
            task.spawn(function()
                while getgenv().AutoAscend do
                    pcall(function()
                        ReplicatedStorage.RemoteEvents.RequestAscend:FireServer()
                    end)
                    task.wait(10)
                end
            end)
        end
    end
})
