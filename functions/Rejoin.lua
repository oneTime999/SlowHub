local Tab = _G.MiscTab
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Player = Players.LocalPlayer

Tab:CreateButton({
    Name = "Rejoin Server",
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
