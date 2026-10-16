-- client/main.lua
-- Gestión del panel NUI: abrir/cerrar, reenvío de eventos del servidor a la NUI.

local isOpen = false

local function sendUiMessage(payload)
    SendNUIMessage(payload)
end

local function openUI(mode, view)
    isOpen = true
    SetNuiFocus(true, true)
    sendUiMessage({ action = 'open', mode = mode or 'admin', view = view })
end

local desdeElHub = false   -- abierto desde la pestaña Scripts de origen_admin

local function volverAlHub()
    if not desdeElHub then return end
    desdeElHub = false
    if GetResourceState('origen_admin') == 'started' then
        exports['origen_admin']:ReturnToScripts()
    end
end

local function closeUI()
    isOpen = false
    Escaparate.Cerrar()
    SetNuiFocus(false, false)
    sendUiMessage({ action = 'close' })
    volverAlHub()
end

-- Abre el panel admin cuando el servidor lo ordena
-- (`pestana`: la pestaña en la que se abre; /tatuajesadmin manda 'tattoos')
RegisterNetEvent('origen_vipsystem:client:openMenu', function(pestana)
    if not isOpen then openUI('admin', type(pestana) == 'string' and pestana or nil) end
end)

-- Abre el panel de usuario
RegisterNetEvent('origen_vipsystem:client:openUserMenu', function()
    if not isOpen then openUI('user') end
end)

-- Notificaciones del servidor
RegisterNetEvent('origen_vipsystem:client:notify', function(text, notifType)
    notify(text, notifType)
end)

-- Cierre desde otro fichero del cliente (probar un vehículo de la tienda)
AddEventHandler('origen_vipsystem:client:cerrarPanel', function()
    if isOpen then closeUI() end
end)

-- Cierre desde la NUI
RegisterNUICallback('closeUI', function(_, cb)
    closeUI()
    cb({})
end)

--[[ La pestaña «Mis cosas» de la tienda (09/10).

     Lo que se gestiona (objetos, peds, mascotas, patentes) eran un panel aparte
     del HUD, solo en Nacion. Ahora vive dentro de la tienda: mismos recursos y
     mismo servidor (los callbacks `origen_hud:miscosas…` de
     origen_hud/server/miscosas.lua), pedidos desde aqui. Donde no existen, la
     pestaña se queda con las compras.

     Lo que pasa en el mundo (colocar, vestirse, llamar a la mascota) cierra la
     tienda primero: con ella puesta no llegaria ninguna tecla ni se veria. ]]
-- (las mascotas son las de origen_pets desde el 13/10: murderface-pets se ha retirado, y origen_hud/server/miscosas.lua ya pregunta a origen_pets)
local PROPS, PEDS, PETS, PATENTES = 'origen_props', 'origen_peds', 'origen_pets', 'origen_patentevip'

local function enMarcha(recurso)
    return GetResourceState(recurso) == 'started'
end

local function hayMisCosas()
    if not enMarcha('origen_hud') or GetConvar('origen:marca', 'origen') ~= 'nacion' then return false end
    return enMarcha(PROPS) or enMarcha(PEDS) or enMarcha(PETS) or enMarcha(PATENTES)
end

local function avisar(res, fallo)
    notify((res and res.msg) or fallo, (res and res.ok) and 'success' or 'error')
end

RegisterNUICallback('user:miscosas', function(_, cb)
    if not hayMisCosas() then return cb({ disponible = false }) end
    local datos = lib.callback.await('origen_hud:miscosas', 5000)
    if type(datos) ~= 'table' then return cb({ disponible = false }) end
    datos.disponible = true
    cb(datos)
end)

RegisterNUICallback('user:miscosas:colocar', function(data, cb)
    cb({})
    local id = tonumber(data and data.id)
    if not id or not enMarcha(PROPS) then return end
    closeUI()
    SetTimeout(300, function()
        local ok, err = pcall(function() exports[PROPS]:PlaceOwnedProp(id) end)
        if not ok then print(('^1[origen_vipsystem]^0 No se pudo colocar el objeto %s: %s'):format(id, err)) end
    end)
end)

--- «Colocar mi casa» (un vale de casa de la tienda de fichero, server/tienda/tienda.lua):
--- se cierra la tienda y el housing abre su configurador, con la barra de teclas abajo.
--- Aquí no se decide nada: el vale, el sitio y el alta los comprueba el servidor del housing.
RegisterNUICallback('user:miscosas:casa', function(data, cb)
    cb({})
    local vale = type(data) == 'table' and data.vale
    if type(vale) ~= 'string' or #vale > 20 then return end
    closeUI()
    if not enMarcha('origen_housing') then return notify('El sistema de viviendas no está disponible ahora mismo.', 'error') end
    SetTimeout(300, function()
        local ok, err = pcall(function() exports.origen_housing:ColocarCasa(vale) end)
        if not ok then
            print(('^1[origen_vipsystem]^0 No se pudo abrir el configurador de la casa %s: %s'):format(vale, err))
            notify('No se ha podido abrir el configurador de la casa.', 'error')
        end
    end)
end)

RegisterNUICallback('user:miscosas:recoger', function(data, cb)
    local id = tonumber(data and data.id)
    if not id or not enMarcha(PROPS) then return cb({ ok = false, msg = 'El sistema de objetos no está disponible.' }) end

    local ok, recogido, msg = pcall(function() return exports[PROPS]:PickupOwnedProp(id) end)
    if not ok then return cb({ ok = false, msg = 'No se pudo recoger el objeto.' }) end
    cb({ ok = recogido == true, msg = msg })
end)

--- Con `id` se viste ese ped; sin el, se vuelve a la ropa de siempre.
RegisterNUICallback('user:miscosas:ped', function(data, cb)
    cb({})
    closeUI()
    local id = data and tonumber(data.id)
    CreateThread(function()
        avisar(lib.callback.await('origen_hud:miscosas:ped', 10000, id),
            id and 'No se pudo equipar el ped.' or 'No se pudo quitar el ped.')
    end)
end)

RegisterNUICallback('user:miscosas:mascota', function(data, cb)
    cb({})
    closeUI()
    local hash = data and data.hash
    CreateThread(function()
        avisar(lib.callback.await('origen_hud:miscosas:mascota', 10000, hash), 'No se pudo llamar a tu mascota.')
    end)
end)

RegisterNUICallback('user:miscosas:mascota:configurar', function(data, cb)
    cb({})
    closeUI()
    CreateThread(function()
        avisar(lib.callback.await('origen_hud:miscosas:mascota:configurar', 10000, data), 'No se pudo guardar tu mascota.')
    end)
end)

RegisterNUICallback('user:miscosas:mascota:borrar', function(data, cb)
    cb(lib.callback.await('origen_hud:miscosas:mascota:borrar', 10000, data and data.hash)
        or { ok = false, msg = 'No se pudo liberar a tu mascota.' })
end)

local SIN_PATENTES = { ok = false, msg = 'El sistema de patentes no está disponible.' }

RegisterNUICallback('user:miscosas:patente:preparar', function(data, cb)
    if not enMarcha(PATENTES) then return cb(SIN_PATENTES) end
    cb(lib.callback.await('origen_patentevip:preparar', false, data and data.id) or SIN_PATENTES)
end)

RegisterNUICallback('user:miscosas:patente:comprobar', function(data, cb)
    if not enMarcha(PATENTES) then return cb(SIN_PATENTES) end
    cb(lib.callback.await('origen_patentevip:comprobar', false, data and data.patente) or SIN_PATENTES)
end)

RegisterNUICallback('user:miscosas:patente:usar', function(data, cb)
    if not enMarcha(PATENTES) then return cb(SIN_PATENTES) end

    local res = lib.callback.await('origen_patentevip:usar', false, data and data.id, data and data.patente)
        or { ok = false, msg = 'No se pudo cambiar la patente.' }
    cb(res)
    if not res.ok then return end

    local vehiculo = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehiculo ~= 0 then SetVehicleNumberPlateText(vehiculo, res.patente) end
end)

-- Notificaciones pedidas por la NUI
RegisterNUICallback('notify', function(data, cb)
    local text = data and data.message
    if text and text ~= '' then
        notify(text, data.type or 'inform')
    end
    cb({})
end)

-- Export cliente: obtiene el tipo VIP del jugador actual
exports('getVip', function()
    return lib.callback.await('origen_vipsystem:server:getvip', 250)
end)

exports('getCoins', function(currency)
    return lib.callback.await('origen_vipsystem:server:getCoins', 500, currency)
end)

exports('getVipData', function()
    return lib.callback.await('origen_vipsystem:server:getVipData', 500)
end)

exports('getDaysRemaining', function()
    return lib.callback.await('origen_vipsystem:server:getDaysRemaining', 500)
end)

exports('getUserPanelData', function()
    return lib.callback.await('origen_vipsystem:server:userInit', 2000)
end)

exports('redeemCode', function(code)
    return lib.callback.await('origen_vipsystem:server:userRedeemCode', 2000, { code = code })
end)

exports('convertCurrency', function(amount)
    return lib.callback.await('origen_vipsystem:server:userConvertCurrency', 2000, { amount = amount })
end)

-- La tarjeta «Origen VIP» de la pestaña Scripts de origen_admin.
-- (`panel`: 'tatuajes' abre el panel en su pestaña «Tatuajes»: la tarjeta «Origen Tatuajes · Asignar»)
exports('openManagement', function(panel)
    if isOpen then return end
    desdeElHub = true
    local pestana = panel == 'tatuajes' and 'tattoos' or nil
    CreateThread(function()
        if not lib.callback.await('origen_vipsystem:server:puedeAdmin', false) then
            notify('No tienes permiso para el panel VIP.', 'error')
            return volverAlHub()
        end
        openUI('admin', pestana)
    end)
end)

-- Abre el panel de usuario cuando Config.EnableUserCommand está desactivado
exports('openUserMenu', function()
    if not isOpen then openUI('user') end
end)

-- Abre el panel de usuario directamente en la vista de tienda
exports('openUserStore', function()
    if isOpen then return end
    -- En las dos marcas solo se abre si esta encendido en el panel de admin
    -- (o eres staff).
    if GlobalState.origenCosmeticosAbiertos ~= true then
        CreateThread(function()
            if lib.callback.await('origen_vipsystem:server:puedeVerCosmeticos', false) then
                openUI('user', 'store')
            else
                notify('Cosméticos no está disponible todavía.', 'error')
            end
        end)
        return
    end
    openUI('user', 'store')
end)

-- Para el staff: ver «Cosméticos» aunque este apagado para los jugadores.
-- El permiso lo decide el servidor, no el comando.
RegisterCommand('cosmeticos', function()
    exports[GetCurrentResourceName()]:openUserStore()
end, false)
