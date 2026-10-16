Nui = {}

Nui.OpenMenu = function(state, delayFocus)
    if state and IsNuiFocused() and not delayFocus then
        return
    end

    Nui.abierto = state == true

    SendNUIMessage({
        action = 'openMenu',
        state = state
    })

    -- Solo activar focus si no se especifica delayFocus
    if not delayFocus then
        SetNuiFocus(state, state)
    end
end

local state = false
RegisterNetEvent('origen_doorlock:client:OpenMenu', function()
    state = not state
    Nui.OpenMenu(state)
end)

-- Variable para rastrear si fue abierto desde el hub
Nui.openedFromHub = false

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): el panel se cierra. Sin esto `state` se quedaba en true
     y el siguiente /doorlock lo "cerraba" en vez de abrirlo. No se vuelve al
     hub: eso cogeria el foco de origen_admin. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not state and not Nui.abierto then return end
        state = false
        Nui.abierto = false
        Nui.openedFromHub = false
        SendNUIMessage({ action = 'openMenu', state = false })
    end)
end

-- Export para abrir el panel de administración desde el hub
exports('openManagement', function()
    -- Marcar que fue abierto desde el hub
    Nui.openedFromHub = true
    
    CreateThread(function()
        state = true
        
        -- Abrir el panel pero SIN activar el focus todavía
        Nui.OpenMenu(true, true)  -- true = state, true = delayFocus
        
        -- Esperar 200ms
        Wait(200)
        
        -- AHORA activar el focus
        SetNuiFocus(true, true)
        
    end)
end)

--[[ La lista del panel sale del servidor y solo para quien tenga permiso: la
     tabla Doors del cliente ya no lleva códigos ni jugadores (y antes el panel
     los leía de ahí, así que cualquiera los tenía en memoria). ]]
RegisterNUICallback('getDoors', function(data, cb)
    cb(lib.callback.await('origen_doorlock:server:GetAdminDoors', false) or {})
end)

RegisterNUICallback('closeMenu', function(data, cb)
    
    state = false
    Nui.abierto = false
    SetNuiFocus(false, false)
    
    -- Si fue abierto desde el hub, volver al hub con pantalla de carga
    if Nui.openedFromHub then
        Nui.openedFromHub = false  -- Reset
        exports['origen_admin']:ReturnToScripts()
    end
end)

RegisterNUICallback('markPosition', function(data, cb)
    local id = data.id
    local door = Doors[id]
    if not door then return cb(false) end
    local coord = door.point.coords
    SetNewWaypoint(coord.x, coord.y)
    Custom.Notify('Puerta marcada en el GPS', 'success')
    cb(true)
end)

RegisterNUICallback('getTraslations', function(data, cb)
    cb({
        translations = Translations.nui,
    })
end)

RegisterNUICallback('TriggerCallback', function(data, cb)
    local trigger = data.trigger
    local retval = lib.callback.await(trigger, false, data)
    cb(retval)
end)