local territories = {}
local activeZones = {}
local playerPresenceData = {
    currentTerritory = nil,
    enteredAt = 0,
    isInTerritory = false
}

local dbg = Debug:new({ enabled = Config.Debug })

local function LoadTerritories()
    TriggerServerEvent('origen_gang:server:requestTerritoriesLatent')
end

RegisterNetEvent('origen_gang:client:receiveTerritoriesLatent', function(result)
    if not result or not result.success or not result.territories then 
        return 
    end
    
    local receivedIds = {}
    
    for i = 1, #result.territories do
        local territory = result.territories[i]
        receivedIds[territory.id] = true
        
        -- Decode JSON string from server if needed (if server sent it as string instead of object)
        if type(territory.zone_data) == 'string' then
            territory.zone_data = json.decode(territory.zone_data)
        end
        
        territories[territory.id] = territory
        CreateTerritoryZone(territory)
    end
    
    -- Cleanup deleted territories
    for tId, _ in pairs(territories) do
        if not receivedIds[tId] then
            if activeZones[tId] then
                activeZones[tId]:remove()
                activeZones[tId] = nil
            end
            territories[tId] = nil
        end
    end
end)

function CreateTerritoryZone(territory)
    if not territory.zone_data or not territory.zone_data.points then return end
    
    if activeZones[territory.id] then
        activeZones[territory.id]:remove()
    end

    local points = {}
    for i = 1, #territory.zone_data.points do
        local point = territory.zone_data.points[i]
        table.insert(points, vec3(point.x or point[1], point.y or point[2], 0))
    end

    --[[ Latido: reenviar enterTerritory cada 60 s mientras se esta dentro.
         Antes se contaban 60 llamadas a `inside`, pero ox_lib llama a `inside`
         CADA FRAME (SetInterval sin intervalo en imports/zones/shared.lua), asi
         que el latido salia cada segundo: en el perfil del 07/10 llegaban 57
         enterTerritory por segundo al servidor (5.743 en 101 s), que el
         servidor descartaba uno a uno por su cooldown de 15 s. Ahora va por
         reloj. ]]
    local LATIDO_MS = 60000
    local ultimoLatido = {}

    local zone = lib.zones.poly({
        points = points,
        thickness = 2000.0,
        debug = Config.Debug,
        onEnter = function()
            OnEnterTerritory(territory)
            ultimoLatido[territory.id] = GetGameTimer()
        end,
        onExit = function()
            ultimoLatido[territory.id] = nil
            OnExitTerritory(territory)
        end,
        inside = function()
            local ahora = GetGameTimer()
            if ahora - (ultimoLatido[territory.id] or ahora) >= LATIDO_MS then
                ultimoLatido[territory.id] = ahora
                TriggerServerEvent('origen_gang:server:enterTerritory', territory.id)
            end
        end
    })
    
    activeZones[territory.id] = zone

    -- If the player is already inside the zone when it is created (e.g. resource
    -- restart while standing in the zone), fire onEnter manually so the server
    -- registers presence immediately without waiting for a physical boundary cross.
    local playerCoords = GetEntityCoords(PlayerPedId())
    if zone:contains(playerCoords) then
        OnEnterTerritory(territory)
        ultimoLatido[territory.id] = GetGameTimer()
    end
end

-- Globals accesibles desde cualquier script del mismo recurso
_G.ActiveTerritoryId     = nil
_G.ActiveTerritoryGangId = nil

-- Cooldown cliente por territorio: evita que lib.zones dispare onEnter repetidamente
-- cuando el jugador oscila en el borde de una zona (comportamiento conocido de ox_lib).
-- El servidor ya tiene su propio cooldown de 2s, pero el coste real es la cantidad de
-- NetworkEvents enviados: 11 213 en 8 s = ~1 400/s llegaban al servidor. Con este
-- cooldown de 4s el flood se reduce >95% antes de salir del cliente.
local _clientEnterCooldown = {}
local CLIENT_ENTER_CD_MS  = 4000

function OnEnterTerritory(territory)
    local now = GetGameTimer()
    local last = _clientEnterCooldown[territory.id]
    if last and (now - last) < CLIENT_ENTER_CD_MS then return end
    _clientEnterCooldown[territory.id] = now

    playerPresenceData.currentTerritory = territory.id
    playerPresenceData.enteredAt = GetGameTimer()
    playerPresenceData.isInTerritory = true
    _G.ActiveTerritoryId     = territory.id
    _G.ActiveTerritoryGangId = territory.gang_id

    dbg:info('[Territory] Entered: ' .. territory.name)
    
    TriggerServerEvent('origen_gang:server:enterTerritory', territory.id)
end

function OnExitTerritory(territory)
    -- NO limpiar _clientEnterCooldown aquí: si se borra, lib.zones en boundary-bounce crea
    -- el ciclo enter→cooldown set→exit→cooldown NIL→enter→... que genera ~1 400 eventos/s.
    -- El cooldown expira solo tras CLIENT_ENTER_CD_MS ms (4s), suficiente para todo bounce.

    playerPresenceData.currentTerritory = nil
    playerPresenceData.enteredAt = 0
    playerPresenceData.isInTerritory = false
    _G.ActiveTerritoryId     = nil
    _G.ActiveTerritoryGangId = nil

    dbg:info('[Territory] Exited: ' .. territory.name)
    
    TriggerServerEvent('origen_gang:server:exitTerritory', territory.id)
end

function OnInsideTerritory(territory)
end

RegisterNetEvent('origen_ilegal:client:updateTerritories', function()
    for id, zone in pairs(activeZones) do
        zone:remove()
    end
    
    activeZones = {}
    territories = {}
    
    LoadTerritories()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if Framework.GetIsPlayerLoaded() then
        Wait(1000)
        LoadTerritories()
    end
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(1500)
    LoadTerritories()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    for id, zone in pairs(activeZones) do
        zone:remove()
    end
    
    activeZones = {}
    territories = {}
    _G.ActiveTerritoryId     = nil
    _G.ActiveTerritoryGangId = nil
    playerPresenceData = {
        currentTerritory = nil,
        enteredAt = 0,
        isInTerritory = false
    }
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for id, zone in pairs(activeZones) do
        zone:remove()
    end
end)

exports('GetTerritories', function()
    return territories
end)

exports('GetTerritoryById', function(territoryId)
    return territories[territoryId]
end)

exports('IsPlayerInTerritory', function(territoryId)
    local zone = activeZones[territoryId]
    if not zone then return false end
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    return zone:contains(playerCoords)
end)

exports('GetPlayerPresenceData', function()
    return playerPresenceData
end)

exports('GetCurrentTerritory', function()
    if not playerPresenceData.isInTerritory then
        return nil
    end
    
    return territories[playerPresenceData.currentTerritory]
end)

-- Acceso directo sin pasar por el export (mismo recurso).
-- Primero intenta el estado cacheado; si no, hace un check por coordenadas.
function GetCurrentTerritoryDirect()
    -- 1. Estado ya conocido
    if playerPresenceData.isInTerritory and playerPresenceData.currentTerritory then
        local t = territories[playerPresenceData.currentTerritory]
        if t then return t end
    end
    -- 2. Fallback: buscar la zona que contiene al jugador ahora mismo
    local coords = GetEntityCoords(PlayerPedId())
    for id, zone in pairs(activeZones) do
        if zone:contains(coords) then
            local t = territories[id]
            if t then
                -- Actualizar estado para la próxima vez
                playerPresenceData.currentTerritory = id
                playerPresenceData.isInTerritory    = true
                return t
            end
        end
    end
    return nil
end

-- ── Death detection: notify server when dying in a territory ─────────────────
-- The server verifies it's enemy territory before applying the penalty.

CreateThread(function()
    local wasDead = false
    while true do
        local ped    = PlayerPedId()
        local isDead = IsPedDeadOrDying(ped, true)

        if isDead and not wasDead then
            wasDead = true
            if playerPresenceData.isInTerritory and playerPresenceData.currentTerritory then
                TriggerServerEvent('origen_gang:server:diedInTerritory', playerPresenceData.currentTerritory)

                local killerServerId = nil
                local killerEntity = GetPedSourceOfDeath(ped)
                if killerEntity and killerEntity ~= 0 and IsEntityAPed(killerEntity) and IsPedAPlayer(killerEntity) then
                    local killerPlayer = NetworkGetPlayerIndexFromPed(killerEntity)
                    if killerPlayer and killerPlayer ~= -1 then
                        killerServerId = GetPlayerServerId(killerPlayer)
                    end
                end

                TriggerServerEvent('origen_gang:server:warPlayerKilled', {
                    territoryId = playerPresenceData.currentTerritory,
                    killerSrc = killerServerId
                })
            end
        elseif not isDead then
            wasDead = false
        end

        Wait(1000)
    end
end)
