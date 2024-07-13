local RSGCore = exports['rsg-core']:GetCoreObject()

-- Mission variables
local horses = {}
local bandits = {}
local horseBlips = {}
local missionStarted = false
local ishorsesAttached = false
local rustlingPlayer = nil
local sellPointMarker = nil



-- Utility functions
local function GetRandomHeading()
    return math.random() * 360.0
end

local function AddBlipForhorse(horse)
    local blip = Citizen.InvokeNative(0x23f74c2fda6e7c61, 1664425300, horse)
    SetBlipSprite(blip, Config.horseBlipSprite)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.horseBlipText)
    return blip
end

local function NotifyRustlingPlayer(title, message)
    if rustlingPlayer == PlayerId() then
        TriggerEvent('rNotify:NotifyLeft', title, message, "generic_textures", "tick", 4000)
    end
end

-- Entity spawning functions
local function Spawnhorse()
    for i = 1, Config.NumberOfhorse do
        local randomModelIndex = math.random(1, #Config.HorseModels)
        local horseModel = Config.HorseModels[randomModelIndex]
        local horseHash = GetHashKey(horseModel)
        
        RequestModel(horseHash)
        while not HasModelLoaded(horseHash) do
            Citizen.Wait(10)
        end

        local x = Config.horseSpawnLocation.x + (math.random() - 0.5) * 10.0
        local y = Config.horseSpawnLocation.y + (math.random() - 0.5) * 10.0
        local z = Config.horseSpawnLocation.z
        local heading = GetRandomHeading()
        
        local horse = CreatePed(horseHash, x, y, z, heading, true, false)
        table.insert(horses, horse)
        Citizen.InvokeNative(0x283978A15512B2FE, horse, true)
		
		Citizen.InvokeNative(0xAEB97D84CDF3C00B, horse, true)
        
        local blip = AddBlipForhorse(horse)
        table.insert(horseBlips, blip)

        SetModelAsNoLongerNeeded(horseHash)
    end
end

local function SpawnBandits()
    local banditHash = GetHashKey(Config.BanditModel)
    local horseHash = GetHashKey(Config.HorseModel)
    
    RequestModel(banditHash)
    RequestModel(horseHash)
    
    while not HasModelLoaded(banditHash) or not HasModelLoaded(horseHash) do
        Citizen.Wait(100)
    end

    for i = 1, Config.NumberOfBandits do
        local x = Config.BanditSpawnLocation.x + (math.random() - 0.5) * 15.0
        local y = Config.BanditSpawnLocation.y + (math.random() - 0.5) * 15.0
        local z = Config.BanditSpawnLocation.z
        local heading = GetRandomHeading()
        
        local horse = CreatePed(horseHash, x, y, z, heading, true, false)
        local bandit = CreatePed(banditHash, x, y, z, heading, true, false)
        
        Citizen.InvokeNative(0x283978A15512B2FE, horse, true)
        Citizen.InvokeNative(0x283978A15512B2FE, bandit, true)
        
        Citizen.InvokeNative(0x028F76B6E78246EB, bandit, horse, -1)  -- Set bandit on horse
        
        table.insert(bandits, bandit)
    end
    
    SetModelAsNoLongerNeeded(banditHash)
    SetModelAsNoLongerNeeded(horseHash)
end

-- Mission logic functions
local function AreBanditsDead()
    for _, bandit in ipairs(bandits) do
        if DoesEntityExist(bandit) and not IsEntityDead(bandit) then
            return false
        end
    end
    return true
end

local function MakehorseFollow(horse, player)
    Citizen.CreateThread(function()
        while DoesEntityExist(horse) and not IsEntityDead(horse) do
            local playerCoords = GetEntityCoords(player)
            local horseCoords = GetEntityCoords(horse)
            local distance = #(playerCoords - horseCoords)
            
            if distance > 3.0 then
                TaskGoToEntity(horse, player, -1, 2.0, 2.0, 0, 0)
            else
                ClearPedTasks(horse)
            end
            
            -- Add some unpredictable behavior
            if math.random() < 0.05 then  -- 5% chance each second
                local behavior = math.random(1, 3)
                if behavior == 1 then
                    TaskStartScenarioInPlace(horse, GetHashKey("WORLD_ANIMAL_HORSE_GRAZING"), -1, true)
                elseif behavior == 2 then
                    TaskStartScenarioInPlace(horse, GetHashKey("WORLD_ANIMAL_HORSE_STANDING"), -1, true)
                else
                    TaskWanderStandard(horse, 10.0, 10)
                end
                Citizen.Wait(5000)  -- Wait 5 seconds before resuming following
            end
            
            Citizen.Wait(1000)
        end
    end)
end

local function AttachhorseToNearestPlayer()
    local playerPed = PlayerPedId()
    rustlingPlayer = PlayerId()
    
    for _, currentHorse in ipairs(horses) do
        if DoesEntityExist(currentHorse) and not IsEntityDead(currentHorse) then
            -- Keep the horse wild
            Citizen.InvokeNative(0xAEB97D84CDF3C00B, currentHorse, true)
            
            -- Temporarily calm the horse for leading
            Citizen.InvokeNative(0x76B58A23BCD2D2C1, currentHorse, true)
            
            -- Set animal as being led
            Citizen.InvokeNative(0x3AD51CAB001A6108, currentHorse, true)
            
            -- Make the horse ignore events to follow the player
            SetBlockingOfNonTemporaryEvents(currentHorse, true)
            
            -- Make the horse follow the player
            TaskFollowToOffsetOfEntity(currentHorse, playerPed, 0.0, -3.0, 0.0, 1.0, -1, 1.0, true)
            
            -- Start the custom follow behavior
            MakehorseFollow(currentHorse, playerPed)
        end
    end
    
    ishorseAttached = true 
    TriggerEvent('rNotify:NotifyLeft', "The wild horses are now following you", "Lead them carefully to the selling point.", "generic_textures", "tick", 4000)
    
    -- Add a slight delay before showing the caution message
    Citizen.SetTimeout(4500, function()
        TriggerEvent('rNotify:NotifyLeft', "Caution", "These horses are still wild and may be unpredictable!", "generic_textures", "warning", 4000)
    end)

    -- Notify server that horses are attached
    TriggerServerEvent("horse:SetRustlingPlayer", GetPlayerServerId(rustlingPlayer))
end



local function IsNearSellingPoint()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local sellPointDistance = #(playerCoords - Config.SellNPCLocation)
    
    if sellPointDistance <= Config.SellingRadius then
        
        local allhorseNear = true
        for _, horse in ipairs(horse) do
            if DoesEntityExist(horse) and not IsEntityDead(horse) then
                local horseCoords = GetEntityCoords(horse)
                local horseDistance = #(horseCoords - Config.SellNPCLocation)
                if horseDistance > Config.horseSellDistance then
                    allhorseNear = false
                    break
                end
            end
        end
        return allhorseNear
    end
    return false
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if missionStarted and ishorseAttached then
            DrawMarker(1, Config.SellNPCLocation.x, Config.SellNPCLocation.y, Config.SellNPCLocation.z - 1.0, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                Config.horseSellDistance * 2, Config.horseSellDistance * 2, 1.0, 
                255, 255, 0, 100, false, true, 2, false, nil, nil, false)
        end
    end
end)

local function StartMission()
    if not missionStarted then
        missionStarted = true
        Spawnhorse()
        SpawnBandits()
        TriggerEvent('rNotify:NotifyLeft', "Rustling", "Mission started! Defeat the bandits and rustle the horse.", "generic_textures", "tick", 4000)
        TriggerServerEvent("horse:SetActiveMissionPlayer")
    end
end

RegisterNetEvent("horse:StartMission")
AddEventHandler("horse:StartMission", function()
    StartMission()
end)

local function ResetMission()
    for _, horse in ipairs(horses) do
        if DoesEntityExist(horse) then
            DeleteEntity(horse)
        end
    end
    for _, bandit in ipairs(bandits) do
        if DoesEntityExist(bandit) then
            DeleteEntity(bandit)
        end
    end
    for _, blip in ipairs(horseBlips) do
        RemoveBlip(blip)
    end
    horse = {}  
    bandits = {}
    horseBlips = {}
    ishorseAttached = false
    missionStarted = false
    rustlingPlayer = nil

    
    if Config.AddGPSRoute then
        ClearGpsMultiRoute()
    end
end



Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)  -- Changed to 0 for more responsive checks
        
        if missionStarted then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            if not ishorseAttached then
                if AreBanditsDead() then
                    local nearhorse = false
                    
                    for _, horse in ipairs(horses) do
                        if DoesEntityExist(horse) and not IsEntityDead(horse) then
                            local horseCoords = GetEntityCoords(horse)
                            local distance = #(playerCoords - horseCoords)
                            
                            if distance < 5.0 then
                                nearhorse = true
                                break
                            end
                        end
                    end
                    
                    if nearhorse then
                        AttachhorseToNearestPlayer()
                        TriggerServerEvent("horse:NotifyPolice")
                        TriggerEvent('rNotify:NotifyLeft', "All bandits are dead!", " Round up the horses and take them to the Auction Yard.", "generic_textures", "tick", 4000)
                        
                        
                        if Config.AddGPSRoute then
                            StartGpsMultiRoute(GetHashKey("COLOR_RED"), true, true)
                            AddPointToGpsMultiRoute(Config.SellNPCLocation.x, Config.SellNPCLocation.y, Config.SellNPCLocation.z)
                            SetGpsMultiRouteRender(true)
                        end
                    end
                else
                    -- Check if player is near bandits and trigger combat if necessary
                    for _, bandit in ipairs(bandits) do
                        if DoesEntityExist(bandit) and not IsEntityDead(bandit) then
                            local banditCoords = GetEntityCoords(bandit)
                            local distance = #(playerCoords - banditCoords)
                            
                            if distance < Config.BanditAggroRadius then
                                TaskCombatPed(bandit, playerPed, 0, 16)
                            end
                        end
                    end
                end
            else
                local sellPointDistance = #(playerCoords - Config.SellNPCLocation)
                
                if sellPointDistance <= Config.SellingRadius then
                    local allhorseNear = true
                    for _, currentHorse in ipairs(horses) do
                        if DoesEntityExist(currentHorse) and not IsEntityDead(currentHorse) then
                            local horseCoords = GetEntityCoords(currentHorse)
                            local horseDistance = #(horseCoords - Config.SellNPCLocation)
                            if horseDistance > Config.horseSellDistance then
                                allhorseNear = false
                                break
                            end
                        end
                    end

                    if allhorseNear then
                        TriggerServerEvent("horse:Sellhorse", #horses)
                        ResetMission()
                        TriggerEvent('rNotify:NotifyLeft', "COMPLETED!", " HORSES SOLD SUCCESSFULLY.", "generic_textures", "tick", 4000)
                        
                        -- Clear GPS route when mission is completed
                        if Config.AddGPSRoute then
                            ClearGpsMultiRoute()
                        end
                    else
                        TriggerEvent('rNotify:NotifyLeft', "Almost there!", "Make sure all horses are close to the sell point.", "generic_textures", "tick", 4000)
                    end
                else
                    
                    local allhorseFollowing = true
                    for _, currentHorse in ipairs(horses) do
                        if DoesEntityExist(currentHorse) and not IsEntityDead(currentHorse) then
                            local horseCoords = GetEntityCoords(currentHorse)
                            local distance = #(playerCoords - horseCoords)
                            
                            if distance > 10.0 then  -- Adjust this distance as needed
                                allhorseFollowing = false
                                break
                            end
                        end
                    end
                    
                 
                end
            end

           

            
        end
    end
end)

-- Add this function for drawing 3D text
function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFontForCurrentCommand(1)
        SetTextColor(255, 255, 255, 215)
        SetTextCentre(1)
        DisplayText(CreateVarString(10, "LITERAL_STRING", text), _x, _y)
    end
end

Citizen.CreateThread(function()
    local blip = N_0x554d9d53f696d002(1664425300, Config.SellPointBlip.x, Config.SellPointBlip.y, Config.SellPointBlip.z)
    SetBlipSprite(blip, Config.SellPointBlip.sprite, 1)
    SetBlipScale(blip, 0.2)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.SellPointBlip.name)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if missionStarted and ishorseAttached then
            DrawMarker(1, Config.SellPointBlip.x, Config.SellPointBlip.y, Config.SellPointBlip.z - 1.0, 
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 
                2.0, 2.0, 1.0, 255, 0, 0, 200, false, true, 2, false, nil, nil, false)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)  -- Check every second
        if not missionStarted then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distanceToBanditArea = #(playerCoords - Config.BanditSpawnLocation)
            
            if distanceToBanditArea <= Config.MissionTriggerRadius then
                TriggerServerEvent("horse:RequestMissionStart")
            end
        end
    end
end)


RegisterNetEvent("horse:SaleComplete")
AddEventHandler("horse:SaleComplete", function(reward)
    TriggerEvent('rNotify:NotifyLeft', "COMPLETED!", string.format("HORSES SOLD SUCCESSFULLY FOR $%d", reward), "generic_textures", "tick", 4000)
    ResetMission()
    
    -- Clear GPS route when mission is completed
    if Config.AddGPSRoute then
        ClearGpsMultiRoute()
    end
    
    TriggerServerEvent("horse:MissionComplete")
end)






-- Event handler for respawning (if needed)
RegisterNetEvent("horse:Respawn")
AddEventHandler("horse:Respawn", function()
    if not missionStarted then
        StartMission()
    end
end)

RegisterNetEvent("horse:ResetMission")
AddEventHandler("horse:ResetMission", function()
    if missionStarted then
        ResetMission()
        TriggerEvent('rNotify:NotifyLeft', "Mission Failed", "The rustling mission has timed out.", "generic_textures", "cross", 4000)
    end
end)

