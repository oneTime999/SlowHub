local Tab = _G.SettingsTab
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

Tab:AddButton({
    Title = "Rejoin Server",
    Description = "Reconnects you to the current server",
    Callback = function()
        if #Players:GetPlayers() <= 1 then
            Player:Kick("\nRejoining...")
            task.wait()
            TeleportService:Teleport(game.PlaceId, Player)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        end
    end
})
