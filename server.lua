local RSGCore = exports['rsg-core']:GetCoreObject()
local missionActive = false
local rustlingPlayer = nil
local resetTimerId = nil

RegisterServerEvent("horse:SetActiveMissionPlayer")
AddEventHandler("horse:SetActiveMissionPlayer", function()
    rustlingPlayer = source
end)

RegisterServerEvent("horse:RequestMissionStart")
AddEventHandler("horse:RequestMissionStart", function()
    if not missionActive then
        missionActive = true
        TriggerClientEvent("horse:StartMission", -1) -- Broadcast to all clients
        TriggerEvent("horse:StartMission") -- Trigger the reset timer
    else
        TriggerClientEvent('RSGCore:Notify', source, "A rustling mission is already in progress.", "error")
    end
end)

RegisterServerEvent("horse:MissionComplete")
AddEventHandler("horse:MissionComplete", function()
    missionActive = false
    rustlingPlayer = nil
    if resetTimerId then
        clearTimeout(resetTimerId)
        resetTimerId = nil
    end

end)

RegisterNetEvent("horse:NotifyRustlingPlayer")
AddEventHandler("horse:NotifyRustlingPlayer", function(title, message)
    if source == rustlingPlayer then
        TriggerClientEvent('rNotify:NotifyLeft', source, title, message, "generic_textures", "tick", 4000)
    end
end)

-- Event to notify police
RegisterServerEvent("horse:NotifyPolice")
AddEventHandler("horse:NotifyPolice", function()
    local Players = RSGCore.Functions.GetPlayers()
    for _, playerId in ipairs(Players) do
        local Player = RSGCore.Functions.GetPlayer(playerId)
        if Player.PlayerData.job.type == Config.PoliceJobName then
            TriggerClientEvent('rNotify:ShowObjective', playerId, "Rustlers are in the Area", 4000)
        end
    end
end)

-- Remove the ResetMission function and the SetTimeout call

RegisterServerEvent("horse:Sellhorse")
AddEventHandler("horse:Sellhorse", function(horseCount)
    local src = source
    if src ~= rustlingPlayer then
        TriggerClientEvent('RSGCore:Notify', src, "You didn't rustle these horses!", "error")
        return
    end
    local Player = RSGCore.Functions.GetPlayer(src)
    if Player then
        local reward = horseCount * Config.PricePerhorse
        Player.Functions.AddMoney("cash", reward, "Sold rustled horses")
        TriggerClientEvent("horse:SaleComplete", src, reward)
        missionActive = false
        rustlingPlayer = nil  -- Reset after successful sale
    end
end)

RegisterServerEvent("horse:SetRustlingPlayer")
AddEventHandler("horse:SetRustlingPlayer", function(playerId)
    rustlingPlayer = playerId
end)

RegisterServerEvent("horse:ResetRustlingPlayer")
AddEventHandler("horse:ResetRustlingPlayer", function()
    rustlingPlayer = nil
end)

RegisterServerEvent("horse:RequestMissionStart")
AddEventHandler("horse:RequestMissionStart", function()
    if not missionActive then
        missionActive = true
        rustlingPlayer = source
        TriggerClientEvent("horse:StartMission", source) -- Send only to the triggering player
        TriggerEvent("horse:StartMission") -- Trigger the reset timer
        TriggerClientEvent('rNotify:NotifyLeft', source, "Rustling", "Mission started! Defeat the bandits and rustle the horses.", "generic_textures", "tick", 4000)
    else
        TriggerClientEvent('RSGCore:Notify', source, "A rustling mission is already in progress.", "error")
    end
end)