-- Entradas (ver config/entradas.lua y custom/server/entradas.lua).
--  · Entrada a pie: dónde aparece quien entra y hacia dónde mira; ahí mismo
--    queda el punto de salir. Se elige andando hasta el sitio.
--  · Entrada de garaje (casas de modalidad libre que admiten vehículos): un
--    sitio dentro para el coche y un punto en la calle. Al volante, E.
--    El garaje se abre y se cierra aparte de la puerta principal (a pie junto
--    al punto de la calle con la E, en el menú de la casa o con /entradas):
--    cerrado, con coche entra quien tiene llave; abierto, cualquiera con su
--    vehículo. La puerta principal solo decide quién entra a pie.
-- Se ponen desde el menú de la casa (apartado «Entradas»), con las
-- herramientas «Entrada» y «Entrada de garaje» de la cinta, o con /entradas.
-- Aquí no se decide nada: el sitio lo mide el servidor en el personaje.
local C = Config.Entradas

Entradas = {}           -- lo que llama el resto del housing (client/shell.lua, client/classes/house.lua, custom/client/obra.lua)

local Estados = {}      -- id de casa → { d = lo que manda el servidor, t = cuándo }
local colocando = false -- 'pie' | 'coche' | 'calle' mientras se elige el sitio con la barra de abajo
local enTransito = false

-- ── Lo que sabe el cliente de cada casa ─────────────────────────────────
local function Pedir(id, fresco, conCuenta)
    id = tonumber(id)
    if not id then return nil end
    local e = Estados[id]
    if e and not fresco and GetGameTimer() - e.t < 60000 then return e.d end
    local d = lib.callback.await('origen_housing:entradas:estado', false, id, conCuenta == true)
    if d then
        Estados[id] = { d = d, t = GetGameTimer() }
        return d
    end
    return e and e.d or nil
end

local function Sabido(id)
    local e = Estados[tonumber(id) or -1]
    return e and e.d or nil
end

local function EsLibre(house)
    return Obra ~= nil and Obra.EsLibre(house.houseData) == true
end

local function DentroDe(house)
    return currentInteriorHouseID and tonumber(currentInteriorHouseID) == tonumber(house.id)
end

local function Avisar(texto, tipo)
    Custom.Notify(texto, tipo or 'error', 4500)
end

-- ── El punto de entrar y de salir a pie ─────────────────────────────────
-- El housing guarda el punto como un desplazamiento desde su módulo
-- (Shell.exitCoords): con él coloca a quien entra y pone el punto de salir.
local function AplicarPie(shell, d, rehacer)
    if not shell or not shell.entity or not DoesEntityExist(shell.entity) then return end
    local nuevo
    if d and d.pie then
        local o = GetEntityCoords(shell.entity)
        nuevo = GetOffsetFromEntityGivenWorldCoords(shell.entity, o.x + d.pie.x, o.y + d.pie.y, o.z + d.pie.z)
        shell.rumboEntrada = d.pie.h + 0.0
    else
        local modulo = shell.shellData and shell.shellData.data and __indexShells[shell.shellData.data.model]
        nuevo = modulo and modulo.offset or shell.exitCoords
        shell.rumboEntrada = nil
    end
    if not nuevo then return end
    local antes = shell.exitCoords
    local cambia = not antes or #(vector3(nuevo.x, nuevo.y, nuevo.z) - vector3(antes.x, antes.y, antes.z)) > 0.01
    shell.exitCoords = vector3(nuevo.x, nuevo.y, nuevo.z)
    -- con la casa ya montada, el punto de salir se lleva a su sitio nuevo
    if rehacer and cambia and shell.inside and not Config.ExternalInteractionSystem then
        if shell.exitPoint and shell.exitPoint.remove then shell.exitPoint:remove() end
        shell.exitPoint = nil
        Internal.HideText()
        shell:CreateExitPoint()
    end
end

--- Lo llama Shell:CreateShell con el módulo ya puesto y antes de llevar al
--- jugador dentro: deja el punto de entrada donde lo eligió el dueño.
function Entradas.AlCrear(shell)
    local data = shell and shell.shellData
    if not data or not data.data or data.data.type ~= 'shell' then return end
    AplicarPie(shell, Pedir(data.id, true), false)
    local rumbo = shell.rumboEntrada
    if not rumbo then return end
    CreateThread(function()
        local limite = GetGameTimer() + 8000
        while not shell.inside and GetGameTimer() < limite do Wait(50) end
        local ped = PlayerPedId()
        if shell.inside and not shell.force and not IsPedInAnyVehicle(ped, false) then
            SetEntityHeading(ped, rumbo)
            SetGameplayCamRelativeHeading(0.0)
        end
    end)
end

RegisterNetEvent('origen_housing:entradas:cambio', function(id, d)
    id = tonumber(id)
    if not id or type(d) ~= 'table' then return end
    Estados[id] = { d = d, t = GetGameTimer() }
    if currentInteriorHouseID and tonumber(currentInteriorHouseID) == id then
        local house = House.get(id)
        if house and house.shellData then AplicarPie(house.shellData, d, true) end
    end
end)

--- En la puerta de la casa, dentro de un vehículo: true si por ahí no se pasa
--- (y ya se ha dicho por qué). Lo pregunta House:CreateEntryPoint.
function Entradas.PuertaConCoche(house)
    if not house or not house.houseData or not EsLibre(house) then return false end
    Avisar(house.houseData.data.allowVehicles and 'Con el vehículo se entra por la entrada de garaje de la casa'
        or Config.Translations.notify.error.vehicleNotAllowed)
    return true
end

--- En el punto de salir, dentro de un vehículo: true si por ahí no se sale.
function Entradas.SalidaConCoche(shell)
    if not IsPedInAnyVehicle(PlayerPedId(), false) then return false end
    if not shell or not shell.shellData or not Obra or not Obra.EsLibre(shell.shellData) then return false end
    Avisar('Con el vehículo se sale desde el sitio del coche, al volante')
    return true
end

-- ── Marcas en el suelo ──────────────────────────────────────────────────
local function Rosa()
    local r, g, b = 216, 27, 85
    if OrigenMarcaColor then r, g, b = OrigenMarcaColor(r, g, b) end
    return r, g, b
end

-- (el triángulo solo se ve por una cara: se pinta por las dos)
local function Tri(a, b, c, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, b.x, b.y, b.z, c.x, c.y, c.z, r, g, bl, al)
    DrawPoly(a.x, a.y, a.z, c.x, c.y, c.z, b.x, b.y, b.z, r, g, bl, al)
end

-- Hacia delante y a la derecha de un rumbo del juego
local function Ejes(h)
    local r = math.rad(h)
    return vector3(-math.sin(r), math.cos(r), 0.0), vector3(math.cos(r), math.sin(r), 0.0)
end

-- Un rectángulo tumbado en el suelo, con su canto negro y una flecha hacia el rumbo
local function Marca(centro, h, ancho, largo, r, g, b, alfa, fr, fg, fb)
    local f, d = Ejes(h)
    local p1, p2 = centro - d * (ancho / 2) - f * (largo / 2), centro + d * (ancho / 2) - f * (largo / 2)
    local p3, p4 = centro + d * (ancho / 2) + f * (largo / 2), centro - d * (ancho / 2) + f * (largo / 2)
    Tri(p1, p2, p3, r, g, b, alfa)
    Tri(p1, p3, p4, r, g, b, alfa)
    DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, 11, 11, 13, 255)
    DrawLine(p2.x, p2.y, p2.z, p3.x, p3.y, p3.z, 11, 11, 13, 255)
    DrawLine(p3.x, p3.y, p3.z, p4.x, p4.y, p4.z, 11, 11, 13, 255)
    DrawLine(p4.x, p4.y, p4.z, p1.x, p1.y, p1.z, 11, 11, 13, 255)
    local alto = vector3(0.0, 0.0, 0.012)
    local punta, cola = math.min(largo * 0.34, 1.6), math.min(ancho * 0.3, 1.0)
    Tri(centro + f * punta + alto, centro - f * (punta * 0.55) - d * cola + alto, centro - f * (punta * 0.55) + d * cola + alto, fr, fg, fb, 235)
end

-- El felpudo de la entrada a pie: `suelo` es el punto a ras de suelo
local function Felpudo(suelo, h, vale)
    local r, g, b = Rosa()
    if vale == false then
        Marca(suelo + vector3(0.0, 0.0, 0.03), h, C.felpudo[1], C.felpudo[2], 200, 40, 40, 190, 255, 255, 255)
    else
        Marca(suelo + vector3(0.0, 0.0, 0.03), h, C.felpudo[1], C.felpudo[2], 220, 221, 224, 215, r, g, b)
    end
end

-- El sitio del coche (2 por 3 celdas) o el punto de la calle
local function Plaza(suelo, h, ancho, largo, vale)
    local r, g, b = Rosa()
    if vale == false then
        Marca(suelo + vector3(0.0, 0.0, 0.03), h, ancho, largo, 200, 40, 40, 110, 255, 255, 255)
    else
        Marca(suelo + vector3(0.0, 0.0, 0.03), h, ancho, largo, r, g, b, 70, r, g, b)
    end
end

-- Lo que queda una vez puesto: solo la flecha, pequeña, para no llenar el suelo.
-- (el rectángulo entero se ve mientras se está eligiendo el sitio)
local function Senal(suelo, h)
    local r, g, b = Rosa()
    local f, d = Ejes(h)
    local c = suelo + vector3(0.0, 0.0, 0.04)
    Tri(c + f * 0.55, c - f * 0.30 - d * 0.38, c - f * 0.30 + d * 0.38, r, g, b, 200)
end

-- Centro (en el mundo, a ras de suelo) y rumbo de una huella de coche de la obra en la que se está
local function HuellaEnMundo(o, hu)
    local x, y, z, h = C.CentroDeHuella(hu)
    return o.o + o.X * x + o.Y * y + vector3(0.0, 0.0, z), h
end

local function AnchoLargo()
    return Config.Obra.celda * 2, Config.Obra.celda * 3
end

-- ── Elegir el sitio ─────────────────────────────────────────────────────
-- Lo que se pondría ahora mismo, dibujado; devuelve si vale y, si no, por qué.
-- Son las mismas cuentas que hace el servidor, para no llevarse un «no» al pulsar.
local function Previa(que, house)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local alVolante = veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped
    local d = Sabido(house.id) or {}

    if que == 'calle' then
        if veh ~= 0 and not alVolante then return false, 'Desde el coche, lo pone quien conduce' end
        local cosa = veh ~= 0 and veh or ped
        local pos, h = GetEntityCoords(cosa), GetEntityHeading(cosa)
        local e = house.houseData.positions.entry
        local vale = #(pos - vector3(e.x, e.y, e.z)) <= C.radioCalle
        local hay, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 0.5, false)
        Plaza(vector3(pos.x, pos.y, hay and z or (pos.z - 1.0)), h, 2.4, 5.0, vale)
        if not vale then return false, ('El punto de la calle va a menos de %d metros de la puerta de tu casa'):format(math.floor(C.radioCalle)) end
        return true
    end

    local o = Obra and Obra.Actual()
    if que == 'pie' then
        if veh ~= 0 then return false, 'La entrada a pie se pone andando hasta el sitio' end
        local pos, h = GetEntityCoords(ped), GetEntityHeading(ped)
        if not o then
            -- casa de módulo: vale donde se esté de pie
            Felpudo(pos - vector3(0.0, 0.0, 1.0), h, true)
            return true
        end
        local l = pos - o.o
        local i, j = C.Celda(l.x, l.y)
        local k = Config.Obra.PlantaDe(l.z)
        local vale, motivo = C.CeldaVale(o, i, j, k)
        if vale and d.coche and C.EnHuella(d.coche, i, j, k) then vale, motivo = false, 'Ahí llega el coche al entrar' end
        Felpudo(vector3(pos.x, pos.y, o.o.z + k * Config.Obra.planta), h, vale)
        if not vale then return false, motivo .. ': la entrada va en un sitio abierto y con suelo' end
        return true
    end

    -- que == 'coche'
    if not o then return false, 'La entrada de garaje es de las casas de diseño libre' end
    if veh ~= 0 and not alVolante then return false, 'Desde el coche, lo pone quien conduce' end
    local cosa = veh ~= 0 and veh or ped
    local l = GetEntityCoords(cosa) - o.o
    local hu = C.Huella(l.x, l.y, GetEntityHeading(cosa), Config.Obra.PlantaDe(l.z))
    local vale, motivo = C.HuellaVale(o, hu)
    if vale then
        local pi, pj, pk = 0, 0, 0
        if d.pie and d.pie.i then pi, pj, pk = d.pie.i, d.pie.j, d.pie.k end
        if C.EnHuella(hu, pi, pj, pk) or C.EnHuella(hu, 0, 0, 0) then
            vale, motivo = false, 'Ahí está la entrada a pie: el coche necesita su propio hueco de 2 por 3 celdas'
        end
    end
    local centro, h = HuellaEnMundo(o, hu)
    local ancho, largo = AnchoLargo()
    Plaza(centro, h, ancho, largo, vale)
    if not vale then return false, motivo end
    return true
end

local TITULO = { pie = 'Entrada a pie', coche = 'Sitio del coche', calle = 'Punto de la calle' }
local ultimoNo = 0

local function Poner(que, house, vale, motivo)
    if vale then
        TriggerServerEvent('origen_housing:entradas:poner', house.id, que)
        return true
    end
    if GetGameTimer() - ultimoNo > 1500 then
        ultimoNo = GetGameTimer()
        Avisar(motivo or 'Ahí no se puede', 'info')
    end
    return false
end

--- Elegir un sitio andando (o conduciendo) hasta él, con la barra de abajo:
--- Intro lo pone donde se está y hacia donde se mira; Esc lo deja.
function Entradas.Colocar(que, house)
    if colocando or not house or not TITULO[que] then return end
    if (que == 'calle') == (DentroDe(house) and true or false) then
        return Avisar(que == 'calle' and 'El punto de la calle se pone desde fuera, junto a tu casa' or 'Eso se pone desde dentro de la casa')
    end
    colocando = que
    CreateThread(function()
        Wait(300)       -- el menú suelta antes el ratón
        Nui.ControlsNotify({ title = TITULO[que], keys = {
            { key = 'enter', text = 'Poner aquí, mirando hacia donde miras' },
            { key = 'ESC', text = 'Cancelar' },
        } })
        while colocando do
            if (que == 'calle') == (DentroDe(house) and true or false) then break end
            local vale, motivo = Previa(que, house)
            DisableControlAction(0, 200, true)
            if IsControlJustPressed(0, 191) then
                if Poner(que, house, vale, motivo) then break end
            elseif IsControlJustPressed(0, 202) or IsDisabledControlJustPressed(0, 200) then
                break
            end
            Wait(0)
        end
        colocando = false
        Nui.ControlsNotify()
    end)
end

-- Las herramientas de la cinta (custom/client/obra.lua): «Entrada» y «Entrada de garaje»
local DE_LA_CINTA = { entrada = 'pie', cochera = 'coche' }
local enMano = { vale = false }

--- Con la herramienta en la mano: se enseña lo que se pondría, a los pies.
function Entradas.EnMano(o, id)
    local que = DE_LA_CINTA[id]
    local house = que and o and House.get(o.id)
    if not house then return end
    enMano.vale, enMano.motivo = Previa(que, house)
end

--- El clic con la herramienta en la mano.
function Entradas.Poner(o, id)
    local que = DE_LA_CINTA[id]
    local house = que and o and House.get(o.id)
    if not house then return end
    if que == 'coche' and not house.houseData.data.allowVehicles then return Avisar('Esta casa no admite vehículos') end
    Poner(que, house, enMano.vale, enMano.motivo)
end

-- ── Entrar y salir con el coche ─────────────────────────────────────────
local function EsperarNegro(ms)
    local t = GetGameTimer()
    while not IsScreenFadedOut() and GetGameTimer() - t < ms do Wait(0) end
end

-- Lleva el coche a un sitio y no lo suelta hasta que hay suelo debajo.
-- Devuelve si lo ha encontrado.
local function Posar(veh, x, y, z, h, espera)
    NetworkRequestControlOfEntity(veh)
    FreezeEntityPosition(veh, true)
    SetEntityVelocity(veh, 0.0, 0.0, 0.0)
    SetEntityCoordsNoOffset(veh, x + 0.0, y + 0.0, z + 1.0, false, false, false)
    SetEntityHeading(veh, h + 0.0)
    local limite, suelo = GetGameTimer() + (espera or 7000), nil
    while GetGameTimer() < limite do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        local rayo = StartExpensiveSynchronousShapeTestLosProbe(x + 0.0, y + 0.0, z + 1.6, x + 0.0, y + 0.0, z - 2.5, 17, veh, 4)
        local _, toca, donde = GetShapeTestResult(rayo)
        if (toca == true or toca == 1) and donde then
            suelo = donde.z
            break
        end
        Wait(100)
    end
    if suelo then
        SetEntityCoordsNoOffset(veh, x + 0.0, y + 0.0, suelo + 1.0, false, false, false)
        SetEntityHeading(veh, h + 0.0)
        SetVehicleOnGroundProperly(veh)
    end
    return suelo ~= nil
end

local function Cabe(veh)
    local min, max = GetModelDimensions(GetEntityModel(veh))
    local ancho, largo = AnchoLargo()
    return (max.x - min.x) <= ancho - 0.4 and (max.y - min.y) <= largo - 0.1
end

local function Volante()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

local function EntrarConCoche(house)
    local veh = Volante()
    if enTransito or not veh then return end
    if not Cabe(veh) then return Avisar('Ese vehículo es demasiado grande para la entrada de garaje') end
    enTransito = true
    FreezeEntityPosition(veh, true)
    local r = lib.callback.await('origen_housing:entradas:coche', false, house.id, 'entrar')
    if not r or not r.ok then
        FreezeEntityPosition(veh, false)
        enTransito = false
        return Avisar(r and r.motivo or 'No se ha podido entrar')
    end
    -- El servidor ya ha pasado el coche y a todos los que van dentro a la
    -- dimensión de la casa: se monta la casa sin moverse y se sube el coche.
    DoScreenFadeOut(400)
    EsperarNegro(900)
    local bien = pcall(function() house:EnterHouse(true) end)
    local shell = house.shellData
    local montada = bien and shell ~= nil and shell.entity ~= nil and DoesEntityExist(shell.entity) and Obra.Actual() ~= nil
    if montada and Posar(veh, r.x, r.y, r.z, r.h) then
        FreezeEntityPosition(veh, false)
        pcall(Custom.OnEnterHouse, house.id)
        SetGameplayCamRelativeHeading(0.0)
        DoScreenFadeIn(500)
        enTransito = false
        return
    end
    -- No hay casa o no hay suelo: de vuelta a la calle, con el coche
    local v = lib.callback.await('origen_housing:entradas:coche', false, house.id, 'volver')
    local calle = (v and v.ok and v) or (Sabido(house.id) or {}).calle
    currentInteriorHouseID = false
    if calle then Posar(veh, calle.x, calle.y, calle.z, calle.h) end
    FreezeEntityPosition(veh, false)
    if house.shellData then pcall(function() house.shellData:Exit(true) end) end
    DoScreenFadeIn(400)
    enTransito = false
    Avisar('No se ha podido entrar con el vehículo: inténtalo otra vez')
end

local function SalirConCoche(house)
    local veh = Volante()
    if enTransito or not veh then return end
    enTransito = true
    FreezeEntityPosition(veh, true)
    local r = lib.callback.await('origen_housing:entradas:coche', false, house.id, 'salir')
    if not r or not r.ok then
        FreezeEntityPosition(veh, false)
        enTransito = false
        return Avisar(r and r.motivo or 'No se ha podido salir')
    end
    DoScreenFadeOut(400)
    EsperarNegro(900)
    -- (la zona del módulo saca a pie a quien se aleja estando «dentro»: ya no lo está)
    currentInteriorHouseID = false
    Posar(veh, r.x, r.y, r.z, r.h)
    FreezeEntityPosition(veh, false)
    local shell = house.shellData
    if shell then
        pcall(function() shell:Exit(true) end)
    else
        pcall(function() house:ExitHouse(true) end)
    end
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(400) end
    enTransito = false
end

-- Quien va de pasajero: el servidor ya lo ha cambiado de dimensión junto al
-- coche; aquí solo se monta (o se desmonta) la casa. Si por lo que sea se
-- queda sin coche, acaba en un sitio con suelo: nunca en el aire.
RegisterNetEvent('origen_housing:entradas:acompanar', function(id, que, red)
    local house = House.get(id)
    if not house then return end
    local ped = PlayerPedId()
    if que == 'entrar' then
        if DentroDe(house) then return end
        local veh = GetVehiclePedIsIn(ped, false)
        local asiento
        if veh ~= 0 then
            for a = -1, GetVehicleModelNumberOfSeats(GetEntityModel(veh)) - 2 do
                if GetPedInVehicleSeat(veh, a) == ped then asiento = a end
            end
        end
        enTransito = true
        DoScreenFadeOut(300)
        pcall(function() house:EnterHouse(true) end)
        pcall(Custom.OnEnterHouse, house.id)
        local limite = GetGameTimer() + 10000
        while GetGameTimer() < limite and DentroDe(house) and GetEntityCoords(PlayerPedId()).z < 1500.0 do Wait(100) end
        Wait(400)
        ped = PlayerPedId()
        if DentroDe(house) and (not IsPedInAnyVehicle(ped, false) or GetEntityCoords(ped).z < 1500.0) then
            local shell = house.shellData
            local suyo = (red and NetworkDoesNetworkIdExist(red)) and NetworkGetEntityFromNetworkId(red) or 0
            if suyo ~= 0 and DoesEntityExist(suyo) and asiento and IsVehicleSeatFree(suyo, asiento) and GetEntityCoords(suyo).z > 1500.0 then
                TaskWarpPedIntoVehicle(ped, suyo, asiento)
            elseif shell and shell.entity and DoesEntityExist(shell.entity) and shell.exitCoords then
                local p = GetOffsetFromEntityInWorldCoords(shell.entity, shell.exitCoords.x, shell.exitCoords.y, shell.exitCoords.z)
                SetEntityCoordsNoOffset(ped, p.x, p.y, p.z, false, false, false)
            end
        end
        DoScreenFadeIn(500)
        enTransito = false
    elseif que == 'salir' then
        if not DentroDe(house) then return end
        enTransito = true
        DoScreenFadeOut(300)
        local limite = GetGameTimer() + 10000
        while GetGameTimer() < limite and GetEntityCoords(PlayerPedId()).z > 1500.0 do Wait(100) end
        ped = PlayerPedId()
        if GetEntityCoords(ped).z > 1500.0 then
            -- el coche no ha bajado: a la puerta de la casa, a pie
            local e = house.houseData.positions.entry
            SetEntityCoordsNoOffset(ped, e.x + 0.0, e.y + 0.0, e.z + 1.0, false, false, false)
        end
        local shell = house.shellData
        if shell then
            pcall(function() shell:Exit(true) end)
        else
            pcall(function() house:ExitHouse(true) end)
        end
        if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(400) end
        enTransito = false
    end
end)

-- ── Lo que se ve y la E ─────────────────────────────────────────────────
-- La casa con entrada de garaje más cercana, estando en la calle
local cerca, cercaVista = nil, 0
local function CasaCerca(pos)
    if GetGameTimer() - cercaVista < 1500 then return cerca end
    cercaVista = GetGameTimer()
    cerca = nil
    local mejor = 60.0
    for _, house in pairs(House.table) do
        local dato = house.houseData
        if house.owned and dato and dato.data and dato.data.allowVehicles and dato.positions and dato.positions.entry and EsLibre(house) then
            local e = dato.positions.entry
            local dist = #(pos - vector3(e.x, e.y, e.z))
            if dist < mejor then cerca, mejor = house, dist end
        end
    end
    return cerca
end

-- Los textos de la E, por acción
local TEXTOS = {
    entrar = 'Entrar con el vehículo', salir = 'Salir con el vehículo',
    abrir = 'Abrir garaje', cerrar = 'Cerrar garaje',
}

local function Hacer(que, house)
    if que == 'entrar' then return EntrarConCoche(house) end
    if que == 'salir' then return SalirConCoche(house) end
    -- abrir o cerrar el garaje: lo decide el servidor (quien tiene llave)
    TriggerServerEvent('origen_housing:entradas:garaje', house.id, que == 'abrir')
end

CreateThread(function()
    local conTexto = false
    local ofrecida = 0      -- cuándo se le ofreció la E al árbitro por última vez (0: no hay oferta)
    while true do
        local espera = 700
        local accion, casa
        if not enTransito and not IsScreenFadedOut() and House and House.table then
            local ped = PlayerPedId()
            local veh = Volante()
            if currentInteriorHouseID then
                local house = House.get(currentInteriorHouseID)
                local shell = house and house.shellData
                local d = house and Sabido(house.id)
                if d and shell and shell.inside and shell.entity and DoesEntityExist(shell.entity) then
                    local decorando = colocando or (Obra and Obra.CintaAbierta and Obra.CintaAbierta())
                    local o = Obra and Obra.Actual()
                    local centro, h
                    if d.coche and o then centro, h = HuellaEnMundo(o, d.coche) end
                    if decorando then
                        espera = 0
                        -- el felpudo, donde está el punto de salir
                        if shell.exitCoords then
                            local p = GetOffsetFromEntityInWorldCoords(shell.entity, shell.exitCoords.x, shell.exitCoords.y, shell.exitCoords.z)
                            local rumbo = shell.rumboEntrada or (d.pie and d.pie.h) or 0.0
                            if colocando then Felpudo(vector3(p.x, p.y, p.z - 1.0), rumbo) else Senal(vector3(p.x, p.y, p.z - 1.0), rumbo) end
                        end
                    end
                    if centro and (decorando or veh) then
                        espera = 0
                        local ancho, largo = AnchoLargo()
                        if colocando then Plaza(centro, h, ancho, largo) else Senal(centro, h) end
                        if veh and d.calle and not colocando and #(GetEntityCoords(veh) - centro) < C.usoDentro + 1.0 then
                            accion, casa = 'salir', house
                        end
                    end
                end
            else
                local pos = GetEntityCoords(ped)
                local house = CasaCerca(pos)
                local d = house and Pedir(house.id)
                if d and d.calle then
                    local punto = vector3(d.calle.x, d.calle.y, d.calle.z)
                    local dist = #(pos - punto)
                    local conLlave = house:hasKey()
                    -- con coche manda el garaje (d.abierto), no la puerta principal
                    if dist < 30.0 and (conLlave or (veh and d.coche and d.abierto)) and colocando ~= 'calle' then
                        espera = 0
                        Senal(punto, d.calle.h)
                    end
                    if veh and d.coche and dist < C.usoCalle and (conLlave or d.abierto) and not colocando then
                        accion, casa = 'entrar', house
                    elseif conLlave and d.coche and dist < C.usoCalle and not colocando and not IsPedInAnyVehicle(ped, true) then
                        -- a pie, con llave, en el punto de la calle: abrir o cerrar el garaje
                        accion, casa = d.abierto and 'cerrar' or 'abrir', house
                    end
                end
            end
        end
        if Tecla and Tecla.Ofrecer then
            -- La E la reparte el árbitro de la casa (custom/client/tecla_e.lua),
            -- para no pisarse con ascensores, montacoches y demás. La oferta
            -- caduca sola: se renueva cada poco mientras siga valiendo.
            if accion then
                espera = 0
                if GetGameTimer() - ofrecida > 400 then
                    ofrecida = GetGameTimer()
                    local que, donde = accion, casa
                    Tecla.Ofrecer('entradas', {
                        texto = TEXTOS[que],
                        prioridad = (que == 'entrar' or que == 'salir') and 60 or 40, dist = 0.0,
                        hacer = function() Hacer(que, donde) end,
                    })
                end
            elseif ofrecida ~= 0 then
                ofrecida = 0
                Tecla.Retirar('entradas')
            end
        elseif accion then
            espera = 0
            if conTexto ~= accion then
                Internal.DrawText(TEXTOS[accion], 'E')
                conTexto = accion
            end
            if IsControlJustPressed(0, 38) then
                Internal.HideText()
                conTexto = false
                Hacer(accion, casa)
            end
        elseif conTexto then
            Internal.HideText()
            conTexto = false
        end
        Wait(espera)
    end
end)

-- ── El menú ─────────────────────────────────────────────────────────────
local function Calle(p)
    local ok, nombre = pcall(function() return GetStreetNameFromHashKey((GetStreetNameAtCoord(p.x + 0.0, p.y + 0.0, p.z + 0.0))) end)
    return ok and nombre and nombre ~= '' and nombre or 'Puesto'
end

-- Lo que enseña el apartado «Entradas» del menú de la casa (ui/index.html)
local function Resumen(house)
    local d = Pedir(house.id, true, true) or {}
    local r = {
        dentro = DentroDe(house) and true or false,
        libre = d.libre == true, permite = d.permite == true,
        pie = { puesta = d.pie ~= nil, texto = 'En la puerta de siempre' },
        coche = { puesta = d.coche ~= nil, texto = 'Sin poner' },
        calle = { puesta = d.calle ~= nil, texto = 'Sin poner' },
        coches = d.coches, tope = d.tope,
        abierto = d.abierto == true,
    }
    if d.pie then r.pie.texto = d.pie.k and (C.NombrePlanta(d.pie.k) .. ' · elegida') or 'Elegida' end
    if d.coche then r.coche.texto = C.NombrePlanta(d.coche.k) .. ' · hueco de 2 por 3' end
    if d.calle then r.calle.texto = Calle(d.calle) end
    return r
end

local function Ir(p, h)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then return Avisar('Bájate del vehículo') end
    DoScreenFadeOut(200)
    EsperarNegro(700)
    SetEntityCoordsNoOffset(ped, p.x, p.y, p.z, false, false, false)
    if h then SetEntityHeading(ped, h + 0.0) end
    Wait(200)
    DoScreenFadeIn(250)
end

-- que: ponerPie · quitarPie · irPie · ponerCoche · irCoche · ponerCalle · irCalle · quitarGaraje · garaje (abrir/cerrar)
local function Accion(house, que)
    if not house or not house.houseData or house.houseData.data.type ~= 'shell' then return end
    if not house:hasKey() then return Avisar(Config.Translations.notify.error.noKey) end
    local dentro = DentroDe(house)
    local d = Sabido(house.id) or {}
    if que == 'ponerPie' then
        Entradas.Colocar('pie', house)
    elseif que == 'ponerCoche' then
        Entradas.Colocar('coche', house)
    elseif que == 'ponerCalle' then
        Entradas.Colocar('calle', house)
    elseif que == 'quitarPie' then
        TriggerServerEvent('origen_housing:entradas:quitar', house.id, 'pie')
    elseif que == 'quitarGaraje' then
        TriggerServerEvent('origen_housing:entradas:quitar', house.id, 'garaje')
    elseif que == 'garaje' then
        TriggerServerEvent('origen_housing:entradas:garaje', house.id)
    elseif que == 'irPie' or que == 'irCoche' then
        local shell = house.shellData
        if not dentro or not shell or not shell.entity or not DoesEntityExist(shell.entity) then return Avisar('Eso, desde dentro de la casa') end
        if que == 'irPie' then
            if not shell.exitCoords then return end
            Ir(GetOffsetFromEntityInWorldCoords(shell.entity, shell.exitCoords.x, shell.exitCoords.y, shell.exitCoords.z), shell.rumboEntrada)
        else
            local o = Obra and Obra.Actual()
            if not o or not d.coche then return Avisar('El sitio del coche está sin poner') end
            local centro, h = HuellaEnMundo(o, d.coche)
            Ir(centro + vector3(0.0, 0.0, 1.0), h)
        end
    elseif que == 'irCalle' then
        if not d.calle then return Avisar('El punto de la calle está sin poner') end
        SetNewWaypoint(d.calle.x + 0.0, d.calle.y + 0.0)
        Avisar('Punto de la calle marcado en el GPS', 'info')
    end
end

RegisterNUICallback('entradasAccion', function(data, cb)
    cb({})
    if type(data) ~= 'table' then return end
    local house = House.get(data.id)
    if not house then return end
    Nui.CloseHouseMenu()
    CreateThread(function() Accion(house, tostring(data.que)) end)
end)

-- El menú de la casa lleva el estado de sus entradas (house.data.entradas)
CreateThread(function()
    while not Nui or not Nui.OpenHouseMenu do Wait(200) end
    local deSiempre = Nui.OpenHouseMenu
    Nui.OpenHouseMenu = function(data, ...)
        if type(data) == 'table' then
            data.entradas = nil
            if data.id and data.data and data.data.type == 'shell' then
                local house = House.get(data.id)
                local ok, r = pcall(Resumen, house or { id = data.id })
                data.entradas = ok and r or nil
            end
        end
        return deSiempre(data, ...)
    end
end)

-- /entradas: lo mismo, en el menú pequeño. Sirve también en la calle, junto a
-- la puerta, que es donde se pone el punto de fuera.
local function CasaAMano()
    if currentInteriorHouseID then return House.get(currentInteriorHouseID) or nil end
    local pos = GetEntityCoords(PlayerPedId())
    local mejor, cual = C.radioCalle + 10.0, nil
    for _, house in pairs(House.table) do
        local dato = house.houseData
        if house.owned and dato and dato.data and dato.data.type == 'shell' and dato.positions and dato.positions.entry and house:hasKey() then
            local e = dato.positions.entry
            local dist = #(pos - vector3(e.x, e.y, e.z))
            if dist < mejor then cual, mejor = house, dist end
        end
    end
    return cual
end

local function Menu(titulo, detalle, opciones)
    if GetResourceState('org-menu') == 'started' then
        local menu = { { header = titulo, txt = detalle, isMenuHeader = true } }
        for _, op in ipairs(opciones) do
            menu[#menu + 1] = { header = op.texto, txt = op.detalle, params = { handler = function() op.hacer() end } }
        end
        exports['org-menu']:openMenu(menu)
        return
    end
    local lineas = {}
    for n, op in ipairs(opciones) do
        lineas[n] = { title = op.texto, description = op.detalle, onSelect = function() op.hacer() end }
    end
    lib.registerContext({ id = 'origen_housing_entradas', title = titulo, options = lineas })
    lib.showContext('origen_housing_entradas')
end

RegisterCommand('entradas', function()
    local house = CasaAMano()
    if not house then return Avisar('Las entradas se configuran dentro de tu casa o junto a su puerta') end
    if not house:hasKey() then return Avisar(Config.Translations.notify.error.noKey) end
    local r = Resumen(house)
    local ops = {}
    local function op(texto, detalle, que)
        ops[#ops + 1] = { texto = texto, detalle = detalle, hacer = function() CreateThread(function() Accion(house, que) end) end }
    end
    if r.dentro then
        op('Poner aquí la entrada a pie', 'Ahora: ' .. r.pie.texto .. '. Ve andando al sitio y confirma', 'ponerPie')
        if r.pie.puesta then op('Entrada a pie: volver a la puerta de siempre', nil, 'quitarPie') end
        if r.libre and r.permite then
            op('Poner aquí el sitio del coche', 'Ahora: ' .. r.coche.texto .. '. Donde aparece el vehículo al entrar', 'ponerCoche')
        end
    elseif r.libre and r.permite then
        op('Poner aquí el punto de la calle', 'Ahora: ' .. r.calle.texto .. '. Desde aquí se entra con el coche y aquí se sale', 'ponerCalle')
    end
    if r.libre and r.permite and r.coche.puesta and r.calle.puesta then
        op(r.abierto and 'Cerrar garaje' or 'Abrir garaje', r.abierto and 'Ahora cualquiera puede entrar con su vehículo'
            or 'Ahora con vehículo solo entra quien tiene llave. Abierto, entra cualquiera con el suyo', 'garaje')
    end
    if r.libre and r.permite and (r.coche.puesta or r.calle.puesta) then
        op('Quitar la entrada de garaje', ('Vehículos dentro: %s de %s'):format(r.coches or '?', r.tope or '?'), 'quitarGaraje')
    end
    if #ops == 0 then
        return Avisar(r.libre and 'Esta casa no admite vehículos: la entrada a pie se pone desde dentro' or 'La entrada se pone desde dentro de la casa', 'info')
    end
    Menu('Entradas de la casa', r.permite and 'A pie y con vehículo' or 'A pie', ops)
end, false)

TriggerEvent('chat:addSuggestion', '/entradas', 'Configura por dónde se entra a tu casa (a pie y con vehículo)')

-- ── Reinicio del recurso con el jugador dentro ──────────────────────────
-- (custom/server/a_datos.lua) Si origen_housing se reinicia con uno dentro de
-- una casa, este cliente arranca sin casa montada y el jugador sigue en la
-- dimensión de la casa: se le pide al servidor que le saque a la puerta. El
-- servidor solo lo hace si de verdad está en la dimensión de una casa sin
-- constar dentro; a quien acaba de conectarse no le hace nada.
-- El salto lo da ESTE cliente: el ped es suyo y el SetEntityCoords del servidor
-- no le llegaba (cambiaba de dimensión y caía 2.000 m hasta la calle). El
-- servidor deja el destino en el statebag `origenCasaRescate`, que sobrevive al
-- reinicio del recurso.
local function LlevarA(d)
    if type(d) ~= 'table' or not (tonumber(d.x) and tonumber(d.y) and tonumber(d.z)) then return false end
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) ~= ped then return true end    -- le lleva quien conduce
    local cosa = veh ~= 0 and veh or ped
    SetEntityVelocity(cosa, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(d.x + 0.0, d.y + 0.0, d.z + 0.0)
    SetEntityCoordsNoOffset(cosa, d.x + 0.0, d.y + 0.0, d.z + (veh ~= 0 and 0.8 or 1.0), false, false, false)
    if tonumber(d.h) then SetEntityHeading(cosa, d.h + 0.0) end
    SetEntityVelocity(cosa, 0.0, 0.0, 0.0)
    return true
end

-- Al parar: sin esperar a que el recurso vuelva (la casa se desmonta ahora mismo)
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() or not currentInteriorHouseID then return end
    local house
    for _, h in pairs(House and House.table or {}) do
        if tostring(h.id) == tostring(currentInteriorHouseID) then house = h break end
    end
    local e = house and house.houseData and house.houseData.positions and house.houseData.positions.entry
    if not e then return end
    local calle = (Sabido(currentInteriorHouseID) or {}).calle
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 and type(calle) == 'table' then
        LlevarA(calle)
    else
        LlevarA({ x = e.x, y = e.y, z = e.z })
    end
end)

CreateThread(function()
    -- lo que dejó apuntado el servidor al parar
    local d = LocalPlayer.state.origenCasaRescate
    if d and not currentInteriorHouseID then
        -- solo si sigue en el aire de la casa (el salto de onResourceStop pudo llegar ya)
        if GetEntityCoords(PlayerPedId()).z > (tonumber(d.z) or 0.0) + 30.0 then LlevarA(d) end
        TriggerServerEvent('origen_housing:server:rescatado')
    end
    Wait(2500)
    if not currentInteriorHouseID then TriggerServerEvent('origen_housing:server:rescate') end
end)

RegisterNetEvent('origen_housing:client:rescatado', function(_, destino)
    local ped = PlayerPedId()
    if not currentInteriorHouseID then LlevarA(destino) end
    -- por si el reinicio le pilló a media entrada: ni congelado ni en negro
    FreezeEntityPosition(ped, false)
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then FreezeEntityPosition(veh, false) end
    local c = GetEntityCoords(ped)
    RequestCollisionAtCoord(c.x, c.y, c.z)
    TriggerServerEvent('origen_housing:server:rescatado')
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(500) end
    if Custom and Custom.Notify then
        pcall(Custom.Notify, 'Las viviendas se han reiniciado: estás en la puerta de la casa en la que estabas', 'info', 6000)
    end
end)
