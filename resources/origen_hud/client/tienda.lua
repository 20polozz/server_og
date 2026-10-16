local VIP = 'origen_vipsystem'

local panel = PanelLateral('tienda')

local function Servidor(nombre, espera, datos)
    return lib.callback.await(('%s:server:%s'):format(VIP, nombre), espera, datos)
end

--[[ userInit va limitado a 700 ms y, si no tiene nada guardado, contesta con
     un panel vacio en vez de esperar: eso no se puede pintar, se reintenta. ]]
local function Datos()
    for _ = 1, 3 do
        local d = Servidor('userInit', 5000)
        if d and not d.failed and not d.rateLimited and d.settings then return d end
        Wait(math.min(((d and tonumber(d.retryAfter)) or 750) + 50, 800))
    end
end

function AbrirTienda()
    if GetResourceState(VIP) ~= 'started' then return end
    if not panel.Empezar() then return end

    local datos = Datos()
    if not datos then return panel.Fallar(OrigenMarca == 'nacion'
        and 'No se pudo cargar la tienda. Intentalo en un momento.'
        or 'No se pudieron cargar los cosméticos. Intentalo en un momento.') end

    panel.Mostrar({
        playerName = datos.playerName,
        tebexUrl = datos.tebexUrl,
        vip = datos.vip,
        storeEnabled = datos.storeEnabled,
        storeItemCount = type(datos.storeItems) == 'table' and #datos.storeItems or 0,
        subscriptions = datos.subscriptions,
        currencies = datos.settings.currencies,
        balances = datos.balances,
    })
end

--- El catalogo es la NUI del vipsystem: entra cuando este panel ya ha salido.
RegisterNUICallback('tienda:abrirVip', function(_, cb)
    cb({})
    panel.Cerrar()
    SetTimeout(300, function()
        local ok, err = pcall(function() exports[VIP]:openUserStore() end)
        if not ok then print(('^1[origen_hud]^0 No se pudo abrir la tienda del vip: %s'):format(err)) end
    end)
end)

RegisterNUICallback('tienda:canjear', function(data, cb)
    cb(Servidor('userRedeemCode', 3000, { code = data and data.code }) or { success = false })
end)

RegisterNUICallback('tienda:convertir', function(data, cb)
    cb(Servidor('userConvertCurrency', 3000, { amount = data and data.amount }) or { success = false })
end)

RegisterNUICallback('tienda:suscripciones', function(_, cb)
    cb(Servidor('userGetSubscriptions', 3000) or { success = false, subscriptions = {} })
end)

RegisterNUICallback('tienda:cancelarSub', function(data, cb)
    cb(Servidor('userCancelSubscription', 3000, { id = data and data.id }) or { success = false })
end)

RegisterNUICallback('tienda:reanudarSub', function(data, cb)
    cb(Servidor('userResumeSubscription', 3000, { id = data and data.id }) or { success = false })
end)

--- Pagar mueve el saldo: vuelve con los saldos nuevos para que el panel no mienta.
RegisterNUICallback('tienda:pagarSub', function(data, cb)
    local res = Servidor('userPaySubscriptionNow', 5000, { id = data and data.id }) or { success = false }
    if res.success then
        local d = Datos()
        res.balances = d and d.balances
    end
    cb(res)
end)

exports('AbrirTienda', function() AbrirTienda() end)
exports('TiendaAbierta', function() return panel.abierto end)
