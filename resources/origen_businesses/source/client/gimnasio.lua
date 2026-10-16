--[[ Las maquinas de un negocio de tipo gimnasio: el puente entre el panel del
     negocio (Ajustes) y origen_gym.

     Colocar y mover se hacen mirando al juego, con el modo de colocar de
     origen_gym (el fantasma del aparato y un doble haciendo el ejercicio). El
     panel se aparta mientras tanto, igual que al colocar un punto: la llamada
     de la NUI no contesta hasta que se ha puesto la maquina o se ha salido. ]]

local GYM = 'origen_gym'
local esperando = nil   -- la promesa del sitio que se esta eligiendo

local SIN_GYM = { success = false, message = 'El gimnasio no está disponible ahora mismo.' }

--- origen_gym contesta por aqui con el sitio elegido, o nil si se sale.
AddEventHandler('origen_businesses:client:gimnasioSitio', function(sitio)
    if not esperando then return end
    local p = esperando
    esperando = nil
    p:resolve(sitio or false)
end)

--- Sale al juego a elegir un sitio y vuelve con el (o nil). El foco se suelta
--- antes y se recoge despues, pase lo que pase.
local function ElegirSitio(pedido)
    if esperando or GetResourceState(GYM) ~= 'started' then return nil end

    SetNuiFocus(false, false)
    esperando = promise.new()
    local p = esperando
    TriggerEvent('origen_gym:cl:negocio', pedido)

    local ok, sitio = pcall(Citizen.Await, p)
    esperando = nil
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    return ok and sitio or nil
end

RegisterNUICallback('gimnasioDatos', function(data, cb)
    if GetResourceState(GYM) ~= 'started' then return cb(SIN_GYM) end
    cb(lib.callback.await('origen_businesses:cb:gimnasio:datos', false, { business = data and data.business }) or SIN_GYM)
end)

RegisterNUICallback('gimnasioColocar', function(data, cb)
    local sitio = ElegirSitio({ tipo = data.tipo, prop = data.prop == true })
    if not sitio then return cb({ success = false, cancelado = true }) end
    cb(lib.callback.await('origen_businesses:cb:gimnasio:poner', false, {
        business = data.business, tipo = data.tipo, prop = data.prop == true, sitio = sitio,
    }) or SIN_GYM)
end)

RegisterNUICallback('gimnasioMover', function(data, cb)
    local sitio = ElegirSitio({ id = data.id })
    if not sitio then return cb({ success = false, cancelado = true }) end
    cb(lib.callback.await('origen_businesses:cb:gimnasio:mover', false, {
        business = data.business, id = data.id, sitio = sitio,
    }) or SIN_GYM)
end)

RegisterNUICallback('gimnasioQuitar', function(data, cb)
    cb(lib.callback.await('origen_businesses:cb:gimnasio:quitar', false, { business = data.business, id = data.id }) or SIN_GYM)
end)

RegisterNUICallback('gimnasioAjustes', function(data, cb)
    cb(lib.callback.await('origen_businesses:cb:gimnasio:ajustes', false, {
        business = data.business, precio = data.precio, dias = data.dias,
    }) or SIN_GYM)
end)

AddEventHandler('onResourceStop', function(recurso)
    -- Si origen_gym se para a medias, la llamada de la NUI no se queda colgada.
    if recurso == GYM and esperando then
        local p = esperando
        esperando = nil
        p:resolve(false)
    end
end)
