--[[ Lo que el reparto necesita del juego: saber donde ir.

     Un envio tiene dos sitios —donde se recoge y donde se deja— y el
     repartidor tiene que poder llegar a ellos sin abrir el telefono cada dos
     esquinas. Asi que se marcan en el mapa y se pone la ruta, como haria
     cualquier aplicacion de estas.

     Lo que **no** esta aqui es la comprobacion de si esta lo bastante cerca
     para recoger o entregar. Esa la hace el servidor mirando donde esta de
     verdad el jugador: si la hiciera el cliente, bastaria con decir que si
     desde la otra punta del mapa.
]]

--[[ Las marcas y la lectura del camino son las mismas que las de los viajes:
     un envio y una carrera son, vistos desde el mapa, ir a por algo y llevarlo.
     Viven en client/modules/ruta.lua y aqui solo se dice que es cada cosa. ]]

--[[ Marca el envio que se lleva entre manos.

     Su estado decide a donde hay que ir: antes de recogerlo, al sitio de
     recogida; despues, al de entrega. Sin estado, se limpia todo.

     Devuelve el camino por carretera para que el mapa de la aplicacion lo
     pinte en vez de una recta.

     Lo manda la interfaz cada vez que el envio cambia de paso. ]]
--[[ LA MARCA EN EL SUELO

     El GPS te deja en la calle, pero el sitio exacto —el muelle donde se
     recoge, el Almacen de un negocio metido dentro de un local— no se ve desde
     la calle. Asi que se pinta en el mundo: un circulo en el suelo y una flecha
     encima, ambar donde se recoge y rosa donde se entrega.

     En el Almacen de un negocio, ademas, se entrega con la E sin sacar el
     telefono. Es lo mismo que pulsar el boton de la aplicacion: lo pide al
     servidor, que mira que estes de verdad al lado. ]]

--- Lo que se pinta ahora mismo, o nil.
local Marca = nil
local hiloMarca = false
local avisoPuesto = false

--- Hasta donde se pinta. Mas lejos no se ve y es trabajo por nada.
local VISTA = 120.0

local function QuitarAviso()
    if not avisoPuesto then return end
    lib.hideTextUI()
    avisoPuesto = false
end

--[[ Entregar con la E.

     El servidor no avisa a quien confirma —se entera por la respuesta—, asi
     que aqui se le pasa a la aplicacion lo mismo que le llegaria de fuera, y
     el telefono se pone al dia como si se hubiera pulsado el boton. ]]
local function Entregar(id)
    QuitarAviso()

    local sobre = lib.callback.await('origen_phone:rpc', false, 'delivery:arrive', { id = id })
    local r = sobre and sobre.ok and sobre.data or nil

    if r and r.ok and r.delivery and r.delivery.status == 'done' then
        Marca = nil
        Ruta.Limpiar('reparto')
        Nui.Send('delivery:finished', r.delivery)
        return
    end

    lib.notify({ description = Locale.Say((r and r.error) or 'err_something_failed'), type = 'error' })
end

local function VigilarMarca()
    if hiloMarca then return end
    hiloMarca = true

    CreateThread(function()
        local alcance = (Config and Config.Delivery and Config.Delivery.Reach) or 8.0

        while Marca do
            local m = Marca
            local d = #(GetEntityCoords(PlayerPedId()) - vector3(m.x, m.y, m.z))

            if d > VISTA then
                QuitarAviso()
                Wait(500)
            else
                DrawMarker(1, m.x, m.y, m.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.8, 1.8, 0.5, m.r, m.g, m.b, 120, false, false, 2, false, nil, nil, false)
                DrawMarker(2, m.x, m.y, m.z + 0.8, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0,
                    0.4, 0.4, 0.3, m.r, m.g, m.b, 210, true, true, 2, false, nil, nil, false)

                if d <= alcance and m.texto then
                    if not avisoPuesto then
                        lib.showTextUI(m.texto, { position = 'left-center' })
                        avisoPuesto = true
                    end

                    -- Cada fotograma: la E solo se ve en el que se suelta.
                    if m.entregar and IsControlJustReleased(0, 38) then Entregar(m.entregar) end
                else
                    QuitarAviso()
                end

                Wait(0)
            end
        end

        QuitarAviso()
        hiloMarca = false
    end)
end

--[[ Donde toca ir ahora: el muelle antes de recoger, el destino despues.

     La E solo en el Almacen de un negocio y con la mercancia encima. En un
     envio a una persona quien confirma es ella, asi que ahi se pinta el sitio
     pero no hay nada que pulsar. ]]
local function PonerMarca(params, yaRecogido)
    QuitarAviso()

    local sitio = yaRecogido and params.drop or params.pickup
    if not sitio or not tonumber(sitio.x) then Marca = nil return end

    local entregaAqui = yaRecogido and params.kind == 'supply' and params.status == 'picked'

    local texto
    if not yaRecogido then texto = Locale.Say('delivery_marker_pickup')
    elseif entregaAqui then texto = Locale.Say('delivery_marker_drop') end

    Marca = {
        x = tonumber(sitio.x) + 0.0,
        y = tonumber(sitio.y) + 0.0,
        z = (tonumber(sitio.z) or 0.0) + 0.0,
        -- Recoger en gris de pieza; entregar en el rosa de la casa.
        r = yaRecogido and 216 or 220,
        g = yaRecogido and 27 or 221,
        b = yaRecogido and 85 or 224,
        texto = texto,
        entregar = entregaAqui and tonumber(params.id) or nil,
    }

    VigilarMarca()
end

Nui.OnAsync('deliveryRoute', function(params, listo)
    if not params or not params.status then
        Marca = nil
        Ruta.Limpiar('reparto')
        return listo({ puntos = nil })
    end

    local yaRecogido = params.status == 'picked' or params.status == 'arrived'

    PonerMarca(params, yaRecogido)

    listo({
        puntos = Ruta.DosParadas('reparto',
            params.pickup, params.drop, not yaRecogido,
            Locale.Say('delivery_map_pickup'), Locale.Say('delivery_map_drop')),
    })
end)

--- Y al cerrar el telefono o soltar el envio, fuera.
Nui.On('deliveryClearRoute', function()
    Marca = nil
    Ruta.Limpiar('reparto')
    return true
end)

--[[ Si el recurso se para con las marcas puestas, se quedan pegadas en el mapa
     hasta reconectar: los blips no son del recurso, son del jugador. ]]
AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    Marca = nil
    QuitarAviso()
    Ruta.Limpiar('reparto')
end)

--[[ Lo mismo para una carrera: se va a por el pasajero y luego a donde va.

     `accepted` es camino de recogerle; a partir de `arrived` ya se le lleva. ]]
Nui.OnAsync('ridesRoute', function(params, listo)
    if not params or not params.status then
        Ruta.Limpiar('viajes')
        return listo({ puntos = nil })
    end

    local yaSubido = params.status == 'arrived' or params.status == 'onboard'

    listo({
        puntos = Ruta.DosParadas('viajes',
            params.pickup, params.drop, not yaSubido,
            Locale.Say('ride_map_pickup'), Locale.Say('ride_map_drop')),
    })
end)

--[[ Donde estoy y por donde se va, para el mapa de la aplicacion.

     Lo pide cada segundo y medio mientras se conduce o se reparte, igual que
     el minimapa rehace su ruta: sin esto el mapa de la aplicacion enseñaba el
     camino tal como estaba al aceptar, y no te veias moverte por el.

     Una lectura a la vez: si la anterior todavia esta andando la ruta, esta se
     salta en vez de amontonarse. ]]
local leyendoRuta = false

Nui.OnAsync('rutaAhora', function(_, listo)
    if leyendoRuta then return listo({ ocupado = true }) end
    leyendoRuta = true

    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    local ok, puntos = pcall(Ruta.Trazado)

    leyendoRuta = false

    listo({
        yo = { x = c.x, y = c.y, h = GetEntityHeading(ped) },
        puntos = ok and puntos or nil,
    })
end)

Nui.On('ridesClearRoute', function()
    Ruta.Limpiar('viajes')
    return true
end)

AddEventHandler('onResourceStop', function(nombre)
    if nombre ~= GetCurrentResourceName() then return end
    Ruta.Limpiar('viajes')
end)
