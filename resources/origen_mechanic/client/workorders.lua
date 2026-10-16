--[[
    ÓRDENES DE TRABAJO — EL LADO DEL JUGADOR

    Dos papeles distintos en el mismo archivo, y no se mezclan:

      · El MECÁNICO, que convierte un presupuesto en una orden desde la pantalla
        de diagnóstico y luego la cierra y la factura.
      · El CLIENTE, que ve el presupuesto, lo acepta y paga.

    Nada de lo que hay aquí decide un precio ni un estado: todo va y vuelve del
    servidor, que es quien tiene la orden.
]]

local function Notify(description, notifyType)
    Custom.Notify({
        title = 'Taller',
        description = description,
        type = notifyType or 'error'
    })
end

--[[ Un grupo de filas con las lineas de la orden, que es lo unico que cambia
     entre el presupuesto y la factura. ]]
local function Lineas(order, vacio)
    local filas = {}
    local lines = order.lines or {}

    for i = 1, #lines do
        local line = lines[i]
        local pieza = tonumber(line.partPrice) or 0
        local mano = tonumber(line.laborPrice) or 0

        filas[#filas + 1] = {
            titulo = tostring(line.label),
            detalle = ('pieza $%d · mano de obra $%d'):format(pieza, mano),
            valor = ('$%d'):format(tonumber(line.total) or (pieza + mano))
        }
    end

    return {
        id = 'lineas',
        titulo = 'Líneas',
        icono = 'lucide:list',
        vacio = vacio,
        filas = filas
    }
end

--- La fila del descuento, si lo hay: el cliente ve cuánto se le rebaja y por qué.
local function Rebaja(order)
    local subtotal = (tonumber(order.parts) or 0) + (tonumber(order.labor) or 0)
    if order.free then
        return { etiqueta = 'Sin cobro', valor = ('-$%d'):format(subtotal), tono = 'ok' }
    end
    local pct = tonumber(order.discount) or 0
    if pct > 0 then
        return { etiqueta = ('Descuento %d %%'):format(pct), valor = ('-$%d'):format(subtotal - (tonumber(order.total) or 0)), tono = 'ok' }
    end
end

-- ── El cliente ───────────────────────────────────────────────────────────

--[[ El `lib.alertDialog` de antes BLOQUEABA: se preguntaba, se esperaba la
     respuesta y se seguia en la misma linea. Una NUI no puede hacer eso, asi
     que el flujo va del reves: la pantalla se abre, esta funcion vuelve, y lo
     que sigue vive en el `alResponder`, que corre cuando el jugador cierra.

     Cerrar sin elegir cuenta como RECHAZO, que es lo que hacia el Escape del
     alertDialog: el taller tiene que enterarse de que la orden no sigue. ]]
RegisterNetEvent('origen_mechanic:client:workOrderOffer', function(order)
    if type(order) ~= 'table' then return end

    local abrio = MecRiel.Abrir({
        marca = 'lucide:receipt-text',
        kicker = 'Taller',
        titulo = 'Presupuesto',
        renglon = ('Matrícula %s'):format(tostring(order.plate)),
        rotulo = MecMarcaTaller,
        grupos = { Lineas(order, 'El presupuesto llegó vacío') },
        datos = (function()
            local d = {
                { etiqueta = 'Piezas', valor = ('$%d'):format(tonumber(order.parts) or 0) },
                { etiqueta = 'Mano de obra', valor = ('$%d'):format(tonumber(order.labor) or 0) },
            }
            d[#d + 1] = Rebaja(order)
            d[#d + 1] = { etiqueta = 'Total', valor = ('$%d'):format(tonumber(order.total) or 0), tono = 'warn' }
            return d
        end)(),
        acciones = {
            { id = 'aceptar', texto = 'Aceptar', tipo = 'principal' },
            { id = 'rechazar', texto = 'Rechazar', tipo = 'secundaria' }
        }
    }, function(elegido)
        local acepta = type(elegido) == 'table' and elegido.accion == 'aceptar'

        local result = lib.callback.await('origen_mechanic:cb:respondWorkOrder', false, {
            orderId = order.id,
            accept = acepta
        })

        if type(result) ~= 'table' or not result.success then
            return Notify(type(result) == 'table' and result.message or 'No se pudo responder al presupuesto')
        end

        Notify(result.message, acepta and 'success' or 'inform')
    end)

    if not abrio then
        Notify('Cierra lo que tienes abierto para ver el presupuesto', 'inform')
    end
end)

--[[ La factura. Cerrarla no obliga a nada raro: la orden se queda `terminada`
     y el taller la puede volver a pasar. Quien tiene el coche es el taller, y
     esa es toda la presión que hace falta. ]]
RegisterNetEvent('origen_mechanic:client:workOrderBill', function(order)
    if type(order) ~= 'table' then return end

    local abrio = MecRiel.Abrir({
        marca = 'lucide:banknote',
        kicker = 'Taller',
        titulo = 'Factura',
        renglon = ('Matrícula %s'):format(tostring(order.plate)),
        rotulo = MecMarcaTaller,
        grupos = { Lineas(order, 'La factura llegó vacía') },
        datos = (function()
            local d = {}
            d[#d + 1] = Rebaja(order)
            d[#d + 1] = { etiqueta = 'A pagar', valor = ('$%d'):format(tonumber(order.total) or 0), tono = 'warn' }
            return d
        end)(),
        acciones = {
            { id = 'pagar', texto = (tonumber(order.total) or 0) > 0 and 'Pagar' or 'Recoger sin cargo', tipo = 'principal' },
            { id = 'luego', texto = 'Ahora no', tipo = 'secundaria' }
        }
    }, function(elegido)
        if type(elegido) ~= 'table' or elegido.accion ~= 'pagar' then return end

        local result = lib.callback.await('origen_mechanic:cb:payWorkOrder', false, { orderId = order.id })

        if type(result) ~= 'table' or not result.success then
            return Notify(type(result) == 'table' and result.message or 'No se pudo pagar la factura')
        end

        Notify(result.message, 'success')
    end)

    if not abrio then
        Notify('Cierra lo que tienes abierto para ver la factura', 'inform')
    end
end)

-- ── El mecánico ──────────────────────────────────────────────────────────

--[[ Los jugadores que el mecánico tiene delante, para elegir cliente. Es una
     PROPUESTA: el servidor vuelve a medir la distancia antes de crear la orden,
     así que una lista inventada no sirve de nada. ]]
local function JugadoresCerca()
    local coords = GetEntityCoords(cache.ped)
    local propio = GetPlayerServerId(PlayerId())
    local lista = {}

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if ped and ped ~= 0 and ped ~= cache.ped and DoesEntityExist(ped) then
            local distance = #(coords - GetEntityCoords(ped))

            if distance <= Config.WorkOrders.ClientDistance then
                local id = GetPlayerServerId(player)

                if id ~= propio then
                    lista[#lista + 1] = {
                        id = id,
                        -- El nombre IC lo pone el servidor (abajo): aqui el
                        -- unico a mano es el de Steam, y ese no sale en juego.
                        name = ('Ciudadano #%s'):format(id),
                        distance = math.floor(distance * 10) / 10
                    }
                end
            end
        end
    end

    table.sort(lista, function(a, b) return a.distance < b.distance end)
    return lista
end

--- Los nombres IC, puestos sobre la lista que arma el cliente.
local function ConNombreIC(lista)
    if #lista == 0 then return lista end

    local ids = {}
    for i = 1, #lista do ids[i] = lista[i].id end

    local ok, nombres = pcall(lib.callback.await, 'origen_mechanic:cb:nombresIC', false, ids)
    if not ok or type(nombres) ~= 'table' then return lista end

    for i = 1, #lista do
        local nombre = nombres[tostring(lista[i].id)]
        if nombre then lista[i].name = nombre end
    end

    return lista
end

RegisterNUICallback('nearbyPlayers', function(_, cb)
    cb({ success = true, players = ConNombreIC(JugadoresCerca()) })
end)

RegisterNUICallback('createWorkOrder', function(data, cb)
    if type(data) ~= 'table' or type(data.parts) ~= 'table' or type(data.netId) ~= 'number' then
        return cb({ success = false, message = 'Petición no válida' })
    end

    local vehicle = NetToVeh(data.netId)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return cb({ success = false, message = 'El vehículo ya no está' })
    end

    local result = lib.callback.await('origen_mechanic:cb:createWorkOrder', false, {
        netId = data.netId,
        class = GetVehicleClass(vehicle),
        parts = data.parts,
        clientId = tonumber(data.clientId),
        discount = tonumber(data.discount) or 0,
        free = data.free == true
    })

    cb(type(result) == 'table' and result or { success = false, message = 'Sin respuesta del servidor' })
end)

RegisterNUICallback('listWorkOrders', function(data, cb)
    local result = lib.callback.await('origen_mechanic:cb:listWorkOrders', false, {
        plate = type(data) == 'table' and data.plate or nil
    })

    cb(type(result) == 'table' and result or { success = false, message = 'Sin respuesta del servidor' })
end)

local function LlamarSobreOrden(nombre, data, cb)
    if type(data) ~= 'table' or type(data.orderId) ~= 'number' then
        return cb({ success = false, message = 'Orden no válida' })
    end

    local result = lib.callback.await(nombre, false, { orderId = data.orderId })
    cb(type(result) == 'table' and result or { success = false, message = 'Sin respuesta del servidor' })
end

RegisterNUICallback('finishWorkOrder', function(data, cb)
    LlamarSobreOrden('origen_mechanic:cb:finishWorkOrder', data, cb)
end)

RegisterNUICallback('billWorkOrder', function(data, cb)
    LlamarSobreOrden('origen_mechanic:cb:billWorkOrder', data, cb)
end)

RegisterNUICallback('cancelWorkOrder', function(data, cb)
    LlamarSobreOrden('origen_mechanic:cb:cancelWorkOrder', data, cb)
end)
