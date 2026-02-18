local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local autoCraftConnection = nil
local lastCraftTime = 0

local function stopAutoCraft()
    if autoCraftConnection then
        autoCraftConnection:Disconnect()
        autoCraftConnection = nil
    end
    _G.SlowHub.AutoCraftDivineGrail = false
end

local function startAutoCraft()
    if autoCraftConnection then
        stopAutoCraft()
    end

    _G.SlowHub.AutoCraftDivineGrail = true

    autoCraftConnection = RunService.Heartbeat:Connect(function()
        if not _G.SlowHub.AutoCraftDivineGrail then
            stopAutoCraft()
            return
        end

        if tick() - lastCraftTime >= 2 then
            lastCraftTime = tick()
            pcall(function()
                local args = {
                    [1] = "DivineGrail",
                    [2] = 1,
                }
                ReplicatedStorage.Remotes.RequestGrailCraft:InvokeServer(unpack(args))
            end)
        end
    end)
end

local Toggle = _G.MiscTab:CreateToggle({
    Name = "Auto Craft Divine Grail",
    CurrentValue = _G.SlowHub.AutoCraftDivineGrail or false,
    Flag = "AutoCraftDivineGrail",
    Callback = function(Value)
        if Value then
            startAutoCraft()
        else
            stopAutoCraft()
        end
        
        _G.SlowHub.AutoCraftDivineGrail = Value
        if _G.SaveConfig then
            _G.SaveConfig()
        end
    end
})

if _G.SlowHub.AutoCraftDivineGrail then
    task.wait(2)
    startAutoCraft()
end
