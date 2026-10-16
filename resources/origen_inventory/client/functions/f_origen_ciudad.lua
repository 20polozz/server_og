--[[
    La pestaña de Ciudad, lado cliente.

    Hasta el 11/09/2026 era un cable hacia origen_pausemenu, que tenia los
    datos y las acciones. El menu de pausa se va a quitar, asi que ahora es
    todo del inventario: el servidor esta en server/functions/f_origen_ciudad.lua
    y aqui va lo que solo sabe el cliente (la hora, el tiempo, los barrios, como
    esta el personaje) y la lista de locales, que se guarda y se mantiene al dia.

    Los reportes siguen siendo de origen_admin: se crean y se contestan con sus
    eventos, y la lista se le pide a su callback.
]]

-- ══ Los barrios ════════════════════════════════════════════════════════
--[[ GetNameOfZone devuelve un codigo corto —VESP, DELPE, STRAW— que no se le
     puede enseñar a nadie. Esta es la traduccion, COMPLETA a proposito: si
     falta una entrada el sitio sale con el codigo crudo. ]]
local BARRIOS = {
    AIRP = 'Aeropuerto', ALAMO = 'Alamo Sea', ALTA = 'Alta',
    ARMYB = 'Fuerte Zancudo', BANHAMC = 'Banham Canyon', BANNING = 'Banning',
    BEACH = 'Vespucci Beach', BHAMCA = 'Banham Canyon', BRADP = 'Braddock Pass',
    BRADT = 'Braddock Tunnel', BURTON = 'Burton', CALAFB = 'Calafia Bridge',
    CANNY = 'Raton Canyon', CCREAK = 'Cassidy Creek', CHAMH = 'Chamberlain Hills',
    CHIL = 'Vinewood Hills', CHU = 'Chumash', CMSW = 'Chiliad Mountain',
    CYPRE = 'Cypress Flats', DAVIS = 'Davis', DELBE = 'Del Perro Beach',
    DELPE = 'Del Perro', DELSOL = 'La Puerta', DESRT = 'Desierto',
    DOWNT = 'Centro', DTVINE = 'Downtown Vinewood', EAST_V = 'East Vinewood',
    EBURO = 'El Burro Heights', ELGORL = 'El Gordo Lighthouse', ELYSIAN = 'Elysian Island',
    GALFISH = 'Galilee', GOLF = 'Club de golf', GRAPES = 'Grapeseed',
    GREATC = 'Great Chaparral', HARMO = 'Harmony', HAWICK = 'Hawick',
    HORS = 'Vinewood Racetrack', HUMLAB = 'Humane Labs', JAIL = 'Bolingbroke',
    KOREAT = 'Little Seoul', LACT = 'Land Act Reservoir', LAGO = 'Lago Zancudo',
    LDAM = 'Land Act Dam', LEGSQU = 'Legion Square', LMESA = 'La Mesa',
    LOSPUER = 'La Puerta', MIRR = 'Mirror Park', MORN = 'Morningwood',
    MOVIE = 'Richards Majestic', MTCHIL = 'Monte Chiliad', MTGORDO = 'Mount Gordo',
    MTJOSE = 'Mount Josiah', MURRI = 'Murrieta Heights', NCHU = 'North Chumash',
    NOOSE = 'N.O.O.S.E.', OCEANA = 'Océano Pacífico', PALCOV = 'Paleto Cove',
    PALETO = 'Paleto Bay', PALFOR = 'Paleto Forest', PALHIGH = 'Palomino Highlands',
    PALMPOW = 'Palmer-Taylor', PBBEACH = 'Pacific Bluffs', PBLUFF = 'Pacific Bluffs',
    PBOX = 'Pillbox Hill', PROCOB = 'Procopio Beach', RANCHO = 'Rancho',
    RGLEN = 'Richman Glen', RICHM = 'Richman', ROCKF = 'Rockford Hills',
    RTRAK = 'Redwood Lights', SANAND = 'San Andreas', SANCHIA = 'San Chianski',
    SANDY = 'Sandy Shores', SKID = 'Mission Row', SLAB = 'Stab City',
    STAD = 'Maze Bank Arena', STRAW = 'Strawberry', TATAMO = 'Tataviam Mountains',
    TERMINA = 'Terminal', TEXTI = 'Textile City', TONGVAH = 'Tongva Hills',
    TONGVAV = 'Tongva Valley', VCANA = 'Vespucci Canals', VESP = 'Vespucci',
    VINE = 'Vinewood', WINDF = 'Ron Alternates Wind Farm', WVINE = 'West Vinewood',
    ZANCUDO = 'Río Zancudo', ZP_ORT = 'Puerto de Los Santos', ZQ_UAR = 'Davis Quartz',
}

--- El barrio de unas coordenadas, con nombre de persona. Lo usa tambien el mapa.
function BarrioDe(x, y, z)
    if not x or not y then return nil end
    local codigo = GetNameOfZone(x + 0.0, y + 0.0, (z or 0.0) + 0.0)
    return BARRIOS[codigo] or codigo
end

-- ══ El ambiente: hora, tiempo y temperatura ═════════════════════════════
--[[ El clima es un hash de texto. Los de transicion entre dos climas no estan
     en la lista y se quedan como el ultimo conocido, en vez de parpadear. La
     temperatura no existe en GTA: sale del clima y de la hora, y es solo de
     ambientacion. ]]
local CLIMAS = {
    [GetHashKey('CLEAR')] = { 'Despejado', 22 },
    [GetHashKey('EXTRASUNNY')] = { 'Soleado', 28 },
    [GetHashKey('CLOUDS')] = { 'Nublado', 18 },
    [GetHashKey('OVERCAST')] = { 'Cubierto', 15 },
    [GetHashKey('RAIN')] = { 'Lluvia', 12 },
    [GetHashKey('CLEARING')] = { 'Despejando', 14 },
    [GetHashKey('THUNDER')] = { 'Tormenta', 11 },
    [GetHashKey('SMOG')] = { 'Contaminación', 24 },
    [GetHashKey('FOGGY')] = { 'Niebla', 10 },
    [GetHashKey('XMAS')] = { 'Nieve', -2 },
    [GetHashKey('SNOW')] = { 'Nieve', -1 },
    [GetHashKey('SNOWLIGHT')] = { 'Nevada', 1 },
    [GetHashKey('BLIZZARD')] = { 'Ventisca', -5 },
    [GetHashKey('HALLOWEEN')] = { 'Neblina', 9 },
    [GetHashKey('NEUTRAL')] = { 'Templado', 20 },
}

local ultimoClima = { 'Despejado', 22 }

function AmbienteAhora()
    local hash = GetPrevWeatherTypeHashName()
    if CLIMAS[hash] then ultimoClima = CLIMAS[hash] end

    local horas, minutos = GetClockHours(), GetClockMinutes()
    -- Minimo sobre las 5 de la mañana, maximo sobre las 15.
    local desvio = math.cos((horas - 15) / 24 * 2 * math.pi)
    local c = GetEntityCoords(PlayerPedId())

    return {
        hora = ('%02d:%02d'):format(horas, minutos),
        clima = ultimoClima[1],
        temperatura = math.floor(ultimoClima[2] + desvio * 4 + 0.5),
        barrio = BarrioDe(c.x, c.y, c.z),
    }
end

--[[ Como esta el personaje. La vida del juego va de 100 a 200 —100 es estar
     muerto—, asi que se convierte. El hambre y la sed estan en el metadata. ]]
local function EstadoDelPersonaje()
    local ped = PlayerPedId()
    local comida, bebida = 100, 100
    local ok, datos = pcall(function() return exports.qbx_core:GetPlayerData() end)
    if ok and type(datos) == 'table' and type(datos.metadata) == 'table' then
        comida = math.floor(tonumber(datos.metadata.hunger) or 100)
        bebida = math.floor(tonumber(datos.metadata.thirst) or 100)
    end

    local voz = nil
    if GetResourceState('pma-voice') == 'started' then
        voz = LocalPlayer.state.proximity
        voz = type(voz) == 'table' and voz.distance or (tonumber(voz) or nil)
    end

    return {
        vida = math.max(0, math.min(100, math.floor(GetEntityHealth(ped) - 100))),
        chaleco = math.max(0, math.min(100, GetPedArmour(ped))),
        comida = comida,
        bebida = bebida,
        voz = voz and math.floor(voz) or nil,
    }
end

--[[ Todo el ambiente de una vez. La interfaz lo pide cada pocos segundos: son
     natives del cliente y no cuesta nada. La posicion va con el porque el mapa
     la usa para decir a cuanto queda la ruta. ]]
InventoryUI.On('CiudadAmbiente', function()
    local c = GetEntityCoords(PlayerPedId())
    return {
        ambiente = AmbienteAhora(),
        estado = EstadoDelPersonaje(),
        yo = { x = math.floor(c.x * 10) / 10, y = math.floor(c.y * 10) / 10 },
    }
end)

-- ══ Los locales ═════════════════════════════════════════════════════════
--[[ Se piden una vez por sesion y luego se mantienen con los avisos de
     origen_businesses: si se quedara con lo que habia al entrar, la pestaña
     enseñaria abiertos los que cerraron hace media hora. El barrio de cada uno
     se calcula aqui porque GetNameOfZone es del cliente. ]]
local locales = nil

local function ConBarrio(n)
    local c = n.coords
    if type(c) == 'table' and c.x and c.y then n.barrio = BarrioDe(c.x, c.y, c.z) end
    return n
end

--- La lista de locales de la ciudad. La usan esta pestaña y el mapa.
function CiudadLocales()
    if not locales then
        local lista = lib.callback.await('origen_inventory:ciudad:locales', false)
        if type(lista) ~= 'table' then return {} end
        for _, n in ipairs(lista) do ConBarrio(n) end
        locales = lista
    end
    return locales
end

RegisterNetEvent('origen_businesses:client:pausemenuBusinessDelta', function(payload)
    if not locales or type(payload) ~= 'table' or not payload.id then return end
    local id = tostring(payload.id)

    for i = #locales, 1, -1 do
        local n = locales[i]
        if tostring(n.id or '') == id then
            if payload.removed == true then table.remove(locales, i); return end
            if payload.isOpen ~= nil then n.isOpen = payload.isOpen == true end
            if payload.name ~= nil then n.name = tostring(payload.name) end
            if payload.type ~= nil then n.type = payload.type end
            if payload.coords ~= nil then n.coords = payload.coords; ConBarrio(n) end
            -- Cadena vacia es «se lo ha quitado»; nil es «el aviso no habla del logo».
            if payload.logo ~= nil then n.logo = payload.logo ~= '' and payload.logo or nil end
            return
        end
    end

    if payload.removed ~= true and payload.name then
        locales[#locales + 1] = ConBarrio({
            id = id, name = tostring(payload.name), type = tostring(payload.type or 'service'),
            isOpen = payload.isOpen == true, employees = 0, coords = payload.coords,
            logo = type(payload.logo) == 'string' and payload.logo ~= '' and payload.logo or nil,
        })
    end
end)

-- ══ La portada ══════════════════════════════════════════════════════════
InventoryUI.On('GetCiudad', function()
    local datos = lib.callback.await('origen_inventory:ciudad:datos', false)
    if type(datos) ~= 'table' then return { hay = false } end

    --[[ El banco lo lleva el recurso de banca en un statebag y el del jugador
         puede ir por detras: si esta, manda el statebag. ]]
    local banco = tonumber(LocalPlayer.state.bankBalance)
    if banco then datos.jugador.bank = banco end

    datos.negocios = CiudadLocales()
    datos.hay = true
    return datos
end)

--- Las listas de dentro. Solo se piden al entrar en cada una.
InventoryUI.On('GetCiudadLista', function(datos)
    local cual = datos and datos.cual

    if cual == 'reportes' then
        -- El callback es de origen_admin (server/reports.lua).
        local p = promise.new()
        Bridge.TriggerCallback('origen_inventory:reportes:mios', function(r) p:resolve(r) end)
        return Citizen.Await(p) or {}
    end

    if cual == 'facturas' then
        return lib.callback.await('origen_inventory:ciudad:facturas', false) or {}
    end

    if cual == 'negocios' then return CiudadLocales() end

    -- Vehiculos y propiedades viven en el movil; la pestaña ya no los enseña.
    return {}
end)

--[[ Las estadisticas de verdad: oficios, lo ganado y las multas. Van aparte
     porque son varias consultas a la base y no hace falta pagarlas cada vez
     que alguien entra solo para mirar quien esta de servicio. ]]
InventoryUI.On('GetCiudadEstadisticas', function()
    return lib.callback.await('origen_inventory:ciudad:estadisticas', false) or {}
end)

--[[ Donde estas y que hora es, para adjuntarlo al reporte: uno que dice "el
     cajero no me deja pagar" sin decir que cajero obliga al staff a preguntar. ]]
InventoryUI.On('GetCiudadContexto', function()
    local coords = GetEntityCoords(PlayerPedId())
    local calle = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
    local zona = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    -- GetLocalTime, no os.date: la biblioteca `os` no existe en el cliente.
    local _, _, _, hora, minuto = GetLocalTime()

    return {
        zona = (zona ~= nil and zona ~= 'NULL' and zona ~= '') and zona or nil,
        calle = (calle ~= nil and calle ~= '') and calle or nil,
        hora = ('%02d:%02d'):format(hora or 0, minuto or 0),
        coords = ('%d, %d'):format(math.floor(coords.x), math.floor(coords.y)),
    }
end)

--[[ El staff contesta cuando le viene bien, y el jugador puede estar con la
     pestaña abierta. Lo manda origen_admin (server/reports.lua) con el reporte
     entero, tambien cuando se atiende o se cierra: pasa a «Atendido» y no
     desaparece, para poder valorarlo. ]]
RegisterNetEvent('origen_inventory:reportes:actualizado', function(reporte)
    InventoryUI.Emit({ action = 'reporteActualizado', data = reporte })
end)

RegisterNetEvent('origen_inventory:reportes:rechazado', function(motivo)
    exports['origen_notify']:Notify({ description = tostring(motivo), type = 'error', duration = 5000 })
end)

--[[ La captura del juego para adjuntar al reporte.

     Se hace aqui y se queda aqui hasta que se envia el reporte: el servidor
     solo guarda una imagen un minuto (origen_uploader), y escribir el reporte
     puede llevar mas. A la interfaz se le devuelve para enseñar la miniatura;
     de la NUI al cliente no hay red, asi que el tamaño da igual. ]]
local capturaPendiente = nil

InventoryUI.On('ReporteCaptura', function(datos)
    if datos and datos.quitar then capturaPendiente = nil return true end
    if GetResourceState('screenshot-basic') ~= 'started' then return false end

    local p = promise.new()
    exports['screenshot-basic']:requestScreenshot({ encoding = 'jpg', quality = 0.7 }, function(imagen)
        p:resolve(imagen)
    end)
    local imagen = Citizen.Await(p)

    if type(imagen) ~= 'string' or imagen == '' then return false end
    capturaPendiente = imagen
    return imagen
end)

--- Crear un reporte, contestar, cerrarlo o valorarlo. Son eventos de origen_admin.
InventoryUI.On('CiudadReporte', function(datos)
    if not datos or not datos.que then return false end

    if datos.que == 'crear' then
        if not datos.mensaje or datos.mensaje == '' then return false end

        --[[ La captura viaja al servidor por origen_uploader (evento latente:
             una imagen no cabe en uno normal) y el servidor de origen_admin
             la recoge con el resguardo y la sube. Si algo falla, el reporte
             se manda igual, sin captura. ]]
        local resguardo = nil
        if datos.captura and capturaPendiente and GetResourceState('origen_uploader') == 'started' then
            local base64 = capturaPendiente:gsub('^data:image/%w+;base64,', '')
            local ok, r = pcall(function() return exports['origen_uploader']:PrepararSubida('reporte.jpg', base64) end)
            if ok then resguardo = r end
        end
        capturaPendiente = nil

        TriggerServerEvent('origen_admin:server:sendReport', datos.tipo or 'general', datos.mensaje, {
            prioridad = datos.prioridad,
            resguardo = resguardo,
        })
        return true
    end

    if datos.que == 'contestar' then
        if not datos.id or not datos.mensaje or datos.mensaje == '' then return false end
        TriggerServerEvent('origen_admin:server:sendReportMessage', datos.id, datos.mensaje)
        return true
    end

    if datos.que == 'cerrar' and datos.id then
        TriggerServerEvent('origen_admin:server:closeOwnReport', datos.id)
        return true
    end

    if datos.que == 'valorar' and datos.id and (datos.valor == 'up' or datos.valor == 'down') then
        TriggerServerEvent('origen_admin:server:rateReport', datos.id, datos.valor)
        return true
    end

    return false
end)

--- Pagar una factura. Devuelve lo que diga el servidor para poder avisar.
InventoryUI.On('CiudadPagarFactura', function(datos)
    if not datos or not tonumber(datos.id) then return { success = false } end
    local r = lib.callback.await('origen_inventory:ciudad:pagarFactura', false, tonumber(datos.id))
    return type(r) == 'table' and r or { success = false }
end)

--[[ Las acciones que sacan al jugador del inventario. De la pestaña solo
     queda una: los ajustes DEL JUEGO (graficos, sonido, teclas), que no tienen
     otra puerta. Se cierra el inventario antes: dejarlo abierto detras dejaria
     el raton atrapado en el. ]]
InventoryUI.On('CiudadAccion', function(datos)
    local accion = datos and datos.accion
    if accion ~= 'ajustes' then return false end

    if Player and Player.isOpen then
        Player:CloseInventory(false, false)
    end

    SetTimeout(250, function()
        ActivateFrontendMenu(GetHashKey('FE_MENU_VERSION_LANDING_MENU'), false, -1)
    end)

    return true
end)

--[[ Marcar un local en el GPS (boton «Marcar» de la lista de locales). Sin x
     ni y se entiende que es desmarcar. ]]
InventoryUI.On('CiudadMarcar', function(datos)
    local x = datos and tonumber(datos.x)
    local y = datos and tonumber(datos.y)
    if not x or not y then
        SetWaypointOff()
        return true
    end
    -- Con comprobacion, no a secas: ver MapaPonerWaypoint en f_origen_mapa.lua.
    CreateThread(function() MapaPonerWaypoint(x, y) end)
    return true
end)

--[[ ══ Las llamadas de un administrador ═════════════════════════════════════

     Estaban en origen_pausemenu y solo se podian contestar con su mapa abierto.
     Ahora el aviso llega a la interfaz del inventario siempre
     (components/admin/LlamadaAdmin.vue), tengas el inventario abierto o no; si
     esta cerrado, ademas una notificacion dice que se abra para contestar. Los
     eventos los manda origen_admin (server/actions.lua). ]]
RegisterNetEvent('origen_inventory:admin:llamadaEntrante', function(targetId, callerName)
    InventoryUI.Emit({ action = 'callRequested', targetId = targetId, callerName = callerName })

    if not (Player and Player.isOpen) then
        exports['origen_notify']:Notify({
            description = ('Llamada entrante de %s. Abre el inventario para contestar'):format(tostring(callerName)),
            type = 'info',
            duration = 8000,
        })
    end
end)

RegisterNetEvent('origen_inventory:admin:llamadaEmpezada', function(targetId, _, participantes)
    InventoryUI.Emit({ action = 'callStarted', targetId = targetId, participants = participantes })
end)

RegisterNetEvent('origen_inventory:admin:llamadaAcabada', function()
    InventoryUI.Emit({ action = 'callEnded' })
end)

RegisterNUICallback('AcceptCall', function(datos, cb)
    TriggerServerEvent('origen_admin:server:AcceptCall', datos and datos.targetId)
    cb('ok')
end)

RegisterNUICallback('EndCall', function(datos, cb)
    TriggerServerEvent('origen_admin:server:EndCall', datos and datos.targetId)
    cb('ok')
end)

--- Hablar mientras se mantiene el boton: el mismo canal que la radio.
RegisterNUICallback('HoldTalk', function(datos, cb)
    local hablando = datos and datos.pressed == true
    ExecuteCommand(hablando and '+radiotalk' or '-radiotalk')
    if GetResourceState('pma-voice') == 'started' then
        exports['pma-voice']:setRadioSpeaking(hablando)
    end
    cb('ok')
end)

--[[ ══ Los avisos de los reportes ═══════════════════════════════════════════

     Son para el jugador y no para una pantalla: le llegan este donde este.
     Los manda origen_admin (server/reports.lua). ]]
local function Avisar(texto, tipo)
    exports['origen_notify']:Notify({ description = texto, type = tipo or 'info', duration = 6000 })
end

RegisterNetEvent('origen_inventory:reportes:respondido', function(_, id)
    Avisar(('Un administrador ha respondido a tu reporte #%s'):format(tostring(id)), 'primary')
end)

RegisterNetEvent('origen_inventory:reportes:asignado', function(nombreAdmin)
    Avisar(('Tu reporte está siendo atendido por %s'):format(tostring(nombreAdmin)), 'primary')
end)

RegisterNetEvent('origen_inventory:reportes:resuelto', function(nombreAdmin)
    Avisar(('Tu reporte ha sido resuelto por %s'):format(tostring(nombreAdmin)), 'success')
end)
