local pState = LocalPlayer.state
local visible = true
local forcingHide = false
local voiceModes = {
    ['Whisper'] = 33,
    ['whisper'] = 33,
    ['Susurro'] = 33,
    ['susurro'] = 33,
    ['Normal'] = 66,
    ['normal'] = 66,
    ['Shouting'] = 100,
    ['shouting'] = 100,
    ['Shout'] = 100,
    ['shout'] = 100,
    ['Gritar'] = 100,
    ['gritar'] = 100,
}

local function getVoiceLevelFromMode(mode)
    if not mode then return 66 end
    return voiceModes[mode] or voiceModes[tostring(mode):lower()] or 66
end

function toggleHud(state)
    SendNUIMessage({
        action = 'toggleHud',
        data = {
            show = state,
        }
    })
end

exports('toggleHud', toggleHud)

--? StateBags Handlers
local function updateState(key, value)
    SendNUIMessage({
        action = 'updateState',
        key = key,
        value = value,
    })
end

AddStateBagChangeHandler('hunger', ('player:%s'):format(cache.serverId), function(_, _, value)
    updateState('hunger', value)
end)

AddStateBagChangeHandler('thirst', ('player:%s'):format(cache.serverId), function(_, _, value)
    updateState('thirst', value)
end)

AddStateBagChangeHandler('radio', ('player:%s'):format(cache.serverId), function(_, _, value)
    updateState('radio', value)
end)

AddStateBagChangeHandler('proximity', ('player:%s'):format(cache.serverId), function(_, _, value)
    updateState('voice', getVoiceLevelFromMode(value.mode))
end)


--? Event Handlers
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    initialize()
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    toggleHud(false)
end)

-- Onresourcestart
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        if pState.isLoggedIn then
            initialize()
        end
    end
end)

AddEventHandler('origen_pausemenu:client:openMenu', function()
    toggleHud(false)
end)

AddEventHandler('origen_pausemenu:client:closeMenu', function()
    toggleHud(true)
end)

-- Sistema de eventos para mostrar HUD solo cuando el inventario está abierto
AddEventHandler('origen_inventory:client:inventoryOpened', function()
    -- Ya no necesitamos toggleHud porque el HUD del jugador no se muestra
    -- toggleHud(true)
    
    -- Enviar stats actuales al inventario
    SendNUIMessage({
        resource = 'origen_inventory',
        action = 'updatePlayerStats',
        stats = {
            health = GetEntityHealth(cache.ped) - 100,
            armour = GetPedArmour(cache.ped),
            stamina = IsEntityInWater(cache.ped) and GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10 or 100 - GetPlayerSprintStaminaRemaining(cache.playerId),
            hunger = pState.hunger or 100,
            thirst = pState.thirst or 100,
            voice = voiceModes[pState.proximity and pState.proximity.mode or 'Normal'] or 66,
        }
    })
end)

AddEventHandler('origen_inventory:client:inventoryClosed', function()
    -- Ya no necesitamos toggleHud
    -- toggleHud(false)
end)

function initialize()
    Wait(500)

    -- Ya no ocultamos el HUD porque necesitamos que el VehicleHud funcione
    -- El HUD del jugador está integrado en el inventario de todas formas
    -- toggleHud(false)
    
    updateState('hunger', pState.hunger or 100)
    updateState('thirst', pState.thirst or 100)
    updateState('voice', getVoiceLevelFromMode(pState.proximity and pState.proximity.mode))
    
    CreateThread(function()
        -- Lo último que se mandó. Estando quieto no cambia nada y no hace
        -- falta repetirlo cada medio segundo; cada 5 s se manda igual por si la
        -- interfaz se ha recargado.
        local ultimo, repetir = nil, 0
        while pState.isLoggedIn do
            local playerData = {
                health = GetEntityHealth(cache.ped) - 100,
                armour = GetPedArmour(cache.ped),
                stamina = IsEntityInWater(cache.ped) and GetPlayerUnderwaterTimeRemaining(cache.playerId) * 10 or 100 - GetPlayerSprintStaminaRemaining(cache.playerId),
                talking = NetworkIsPlayerTalking(cache.playerId),
            }

            repetir = repetir - 1
            if not ultimo or repetir <= 0
                or ultimo.health ~= playerData.health or ultimo.armour ~= playerData.armour
                or ultimo.stamina ~= playerData.stamina or ultimo.talking ~= playerData.talking then
                ultimo, repetir = playerData, 10

                -- Actualizar HUD normal
                SendNUIMessage({
                    action = 'updatePlayer',
                    data = playerData
                })
            end
            
            -- Actualizar stats en el inventario si está abierto
            local inventoryOpen = exports['origen_inventory']:IsInventoryOpen()
            if inventoryOpen then
                SendNUIMessage({
                    resource = 'origen_inventory',
                    action = 'updatePlayerStats',
                    stats = {
                        health = playerData.health,
                        armour = playerData.armour,
                        stamina = playerData.stamina,
                        hunger = pState.hunger or 100,
                        thirst = pState.thirst or 100,
                        voice = getVoiceLevelFromMode(pState.proximity and pState.proximity.mode),
                    }
                })
            end
            
            Wait(500)
        end
    end)

    loadMinimap()
end