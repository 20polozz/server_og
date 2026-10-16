--[[ ── El trabajo a pie ───────────────────────────────────────────────────────

     Lo que tienes delante (y lo que llevas) decide qué puedes hacer:
       roca                 E picar · Y poner una carga (nivel 4)
       marca de un bloque   E poner la carga de la voladura (nivel 5)
       pedrusco             E cogerlo (a los brazos, o a la carretilla si la
                            empujas)
       carretilla           H empujarla / dejarla · E meter el pedrusco que
                            llevas en brazos
       trasera del vehículo E echar el pedrusco · E volcar la carretilla
       borde de la tolva    E echar el pedrusco · E volcar la carretilla
       en cualquier sitio   X soltar el pedrusco · G detonar las cargas
     La descarga en la tolva la lleva client/vehiculos.lua.

     Cada paso: el servidor dice si se puede y cuánto dura, se hace la
     animación y el servidor lo vuelve a comprobar al terminar. ]]

Trabajo = {}

local R = Config.Roca
local P = Config.Pedrusco
local CR = Config.Carretilla
local TECLA_E, TECLA_H, TECLA_X, TECLA_G, TECLA_Y = 38, 74, 73, 47, 246

local TEXTOS = {
    picar = 'Picando la roca', coger = 'Cogiendo el pedrusco', meter = 'A la carretilla', echar = 'Echando a la caja',
    volcar = 'Volcando la carretilla', cargaRoca = 'Poniendo la carga', cargaBloque = 'Poniendo la carga',
    descargar = 'Descargando en la tolva', tolva = 'A la tolva',
}

-- ── Ejecutar un paso ──────────────────────────────────────────────────────

--- El martillo neumático lo pone el escenario de GTA; al cortar la tarea se
--- queda tirado en el suelo: se borra.
local function RecogerMartillo()
    local pos = GetEntityCoords(cache.ped)
    local hash = GetHashKey('prop_tool_jackham')
    for _, ent in ipairs(GetGamePool('CObject')) do
        if GetEntityModel(ent) == hash and #(GetEntityCoords(ent) - pos) < 4.0 and not IsEntityAttached(ent) then
            SetEntityAsMissionEntity(ent, true, true)
            DeleteEntity(ent)
        end
    end
end

--- Pide el paso al servidor, anima y lo termina. `mirar` = punto al que girarse.
function Trabajo.Ejecutar(paso, datos, mirar, opciones)
    if L.ocupado then return false end
    opciones = opciones or {}
    L.ocupado = true
    local r = lib.callback.await('origen_mining:empezar', false, paso, datos or {})
    if not r or not r.ok then
        L.ocupado = false
        if r and r.mensaje then L.Aviso(r.mensaje, 'error') end
        return false
    end
    -- Ponerse a la distancia justa: el pico cae ~1,3 m por delante del
    -- cuerpo; más lejos pega en el suelo, delante de la roca (foto, 27/09).
    if opciones.acercar and mirar then
        local ped = cache.ped
        local p = GetEntityCoords(ped)
        local dx, dy = p.x - mirar.x, p.y - mirar.y
        local d = math.sqrt(dx * dx + dy * dy)
        if d > 0.01 and math.abs(d - opciones.acercar) > 0.15 then
            local x, y = mirar.x + dx / d * opciones.acercar, mirar.y + dy / d * opciones.acercar
            local rumbo = math.deg(math.atan(-(mirar.x - x), mirar.y - y))
            TaskGoStraightToCoord(ped, x, y, p.z, 1.0, 3000, rumbo, 0.05)
            local fin = GetGameTimer() + 3000
            while GetGameTimer() < fin and #(GetEntityCoords(ped).xy - vec2(x, y)) > 0.2 do Wait(50) end
        end
        -- Y de cara a la roca, sin depender de que el giro termine a tiempo.
        ClearPedTasks(ped)
        SetEntityHeading(ped, math.deg(math.atan(-(mirar.x - GetEntityCoords(ped).x), mirar.y - GetEntityCoords(ped).y)) + 0.0)
    end
    if mirar then
        TaskTurnPedToFaceCoord(cache.ped, mirar.x + 0.0, mirar.y + 0.0, mirar.z + 0.0, 500)
        Wait(450)
    end

    local anim = opciones.anim
    local escenario
    local h = L.Herramienta()
    if opciones.herramienta and h then
        local hc = Config.Herramientas[h]
        if hc.escenario then escenario = hc.escenario else anim = hc.anim end
        -- Los demás ven el pico en las manos mientras dura.
        if not escenario then LocalPlayer.state:set('minaPicando', true, true) end
    end

    -- Chispas y cascotes a cada golpe.
    local trabajando = true
    -- Con el pico, los cascotes salen en el golpe de la animación (lo pinta
    -- client/cantera.lua para todos). El martillo no tiene golpe: vibra, y
    -- echa polvo seguido mientras dura.
    if opciones.golpes and mirar and escenario then
        CreateThread(function()
            Wait(500)
            while trabajando do
                Cantera.Efecto('core', 'ent_anim_pneumatic_drill', mirar.x, mirar.y, mirar.z + 0.2, 1.0)
                Wait(420)
            end
        end)
    end

    local hecho = lib.progressCircle({
        duration = r.ms,
        label = TEXTOS[paso] or opciones.texto or 'Trabajando',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, sprint = true },
        anim = escenario and { scenario = escenario } or (anim and { dict = anim.dict, clip = anim.clip, flag = anim.flag or 1 }) or nil,
        prop = opciones.prop and { model = opciones.prop.modelo, bone = opciones.prop.hueso, pos = opciones.prop.pos, rot = opciones.prop.rot } or nil,
    })
    trabajando = false
    if LocalPlayer.state.minaPicando then LocalPlayer.state:set('minaPicando', false, true) end
    if escenario then
        ClearPedTasksImmediately(cache.ped)
        RecogerMartillo()
    end

    if not hecho then
        lib.callback.await('origen_mining:cancelar', false)
        L.ocupado = false
        return false
    end
    local fin = lib.callback.await('origen_mining:terminar', false, paso)
    if not escenario then ClearPedTasks(cache.ped) end
    L.ocupado = false
    if not fin or not fin.ok then
        if fin and fin.mensaje then L.Aviso(fin.mensaje, 'error') end
        return false
    end
    if fin.mensaje then L.Aviso(fin.mensaje, 'success') end
    CreateThread(L.PedirYo)
    return true, fin
end

-- ── Llevar en brazos y empujar ────────────────────────────────────────────

--[[ Con un pedrusco en brazos se anda con la animación de llevar una caja
     (solo la parte de arriba del cuerpo: las piernas andan). Empujando la
     carretilla, la del carro de la compra. Sin correr ni saltar ni pegar. ]]
local function Cargar(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local fin = GetGameTimer() + 2000
    while not HasAnimDictLoaded(dict) and GetGameTimer() < fin do Wait(0) end
    return HasAnimDictLoaded(dict)
end

CreateThread(function()
    local sonando
    while true do
        local espera = 300
        local ped = cache.ped
        local quiere
        if not L.ocupado and not cache.vehicle and not IsPedDeadOrDying(ped, true) then
            if L.Mano() then quiere = P.anim elseif L.Empuja() then quiere = CR.anim end
        end
        if quiere then
            espera = 0
            if not IsEntityPlayingAnim(ped, quiere.dict, quiere.clip, 3) and Cargar(quiere.dict) then
                TaskPlayAnim(ped, quiere.dict, quiere.clip, 4.0, 4.0, -1, quiere.flag, 0, false, false, false)
            end
            sonando = quiere
            DisableControlAction(0, 21, true)   -- correr
            DisableControlAction(0, 22, true)   -- saltar
            DisableControlAction(0, 24, true)   -- disparar
            DisableControlAction(0, 25, true)   -- apuntar
            DisableControlAction(0, 140, true)  -- golpe
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 23, true)   -- subir a un vehículo
        elseif sonando then
            StopAnimTask(ped, sonando.dict, sonando.clip, 2.0)
            sonando = nil
        end
        Wait(espera)
    end
end)

--- ¿Está detrás del tope de la tolva, donde se echa a pie?
function Trabajo.EnBorde(pos)
    local b, r = Mina.Borde()
    return #(pos.xy - b.xy) <= r and math.abs(pos.z - b.z) < 3.0
end

-- ── Qué tienes delante ────────────────────────────────────────────────────

--- Lo más cercano con lo que se puede trabajar.
local function Objetivo(pos)
    local mejor, dMejor
    local function Probar(o, d)
        if d and (not dMejor or d < dMejor) then mejor, dMejor = o, d end
    end
    for _, roca in ipairs(Config.Rocas) do
        local d = #(pos.xy - roca.pos.xy)
        if d <= R.distancia + 0.4 and math.abs(pos.z - roca.pos.z) < 5.0 then
            local v = L.rocas[roca.id]
            -- Una roca partida no se ve: no se apunta a ella.
            if v and v.e ~= 'escombro' then Probar({ tipo = 'roca', roca = roca, v = v, punto = roca.pos }, d) end
        end
    end
    for id, t in pairs(L.pedruscos) do
        if t.s == 'suelo' and t.p then
            local ent = Cantera.PedruscoEnt(id)
            local c = (ent and DoesEntityExist(ent)) and GetEntityCoords(ent) or vec3(t.p.x, t.p.y, t.p.z)
            local d = #(pos.xy - c.xy)
            if d <= P.distancia and math.abs(pos.z - c.z) < 2.5 then
                Probar({ tipo = 'pedrusco', t = t, punto = c }, d - 0.6)
            end
        end
    end
    if L.Nivel() >= Config.Voladura.nivel then
        for _, b in ipairs(Config.Bloques) do
            local v = L.bloques[b.id]
            if v and (v.e == 'bloque' or v.e == 'cargado') and #(pos.xy - b.pos.xy) < 8.0 then
                local puestas = {}
                for _, i in ipairs(v.cargas or {}) do puestas[i] = true end
                for i, pto in ipairs(Mina.PuntosCarga(b)) do
                    local d = #(pos.xy - pto.xy)
                    if not puestas[i] and d <= 1.6 then
                        Probar({ tipo = 'marca', bloque = b, v = v, i = i, punto = pto }, d)
                    end
                end
            end
        end
    end
    return mejor
end

--- La carretilla aparcada del equipo más cercana (a menos de `metros`).
local function CarretillaCerca(pos, metros)
    local mejor, dMejor
    for cid, v in pairs(L.carretillas) do
        if not v.empuja and v.p and Equipo.Mismo(cid, L.cid) then
            local ent = Cantera.CarretillaEnt(cid)
            local c = (ent and DoesEntityExist(ent)) and GetEntityCoords(ent) or vec3(v.p.x, v.p.y, v.p.z)
            local d = #(pos.xy - c.xy)
            if d <= metros and (not dMejor or d < dMejor) then mejor, dMejor = { cid = cid, v = v, punto = c }, d end
        end
    end
    return mejor
end

--- La carretilla del equipo que va en la caja de ese vehículo, si hay.
function CarretillaEnCaja(veh)
    if not veh or veh == 0 or not DoesEntityExist(veh) then return nil end
    local net = NetworkGetNetworkIdFromEntity(veh)
    for cid, v in pairs(L.carretillas) do
        if v.veh == net then return v, cid end
    end
    return nil
end

--- La carretilla que empujas (su vista), si empujas alguna.
local function MiCarretilla()
    local cid = L.Empuja()
    return cid and L.carretillas[cid] or nil, cid
end

local function Contar(t)
    local n = 0
    for _ in pairs(t or {}) do n = n + 1 end
    return n
end

-- ── El bucle ──────────────────────────────────────────────────────────────

local ultimaAyuda
local function Ayuda(tecla, texto, alt)
    ultimaAyuda = true
    L.Ayuda('trabajo', tecla, texto, alt)
end

local function Pedir(nombre)
    local r = lib.callback.await('origen_mining:' .. nombre, false)
    if r and r.mensaje then L.Aviso(r.mensaje, r.ok and 'success' or 'error') end
    return r
end

--- Lo que vale una veta vendida (el triturado, lo que vale su lingote).
local function Valor(veta)
    local prod = Config.Productos[Mina.Triturado(veta) or veta]
    return prod and prod.precio or 0
end

--- ¿Está junto al horno de la fundición?
local function EnHorno(pos)
    local h, r = Mina.Horno()
    return #(pos.xy - h.xy) <= r and math.abs(pos.z - h.z) < 4.0
end

local function Lanzar(paso, datos, mirar, opciones)
    L.QuitarAyuda('trabajo')
    CreateThread(function() Trabajo.Ejecutar(paso, datos, mirar, opciones) end)
end

CreateThread(function()
    while true do
        local espera = 400
        local ped = cache.ped
        local libre = L.cerca and L.Jornada() and not L.panelAbierto and not cache.vehicle
            and not IsPedDeadOrDying(ped, true) and not L.ocupado
        ultimaAyuda = false
        local tarjeta = nil

        if libre then
            local pos = GetEntityCoords(ped)
            local mano = L.Mano()
            local carre, cidCarre = MiCarretilla()
            local trasera, traseraVeh = nil, nil
            if Vehiculos.TraseraCerca then trasera, traseraVeh = Vehiculos.TraseraCerca(3.0) end
            espera = 0

            -- G: detonar, si hay cargas puestas del equipo.
            local hayCargas = false
            for _, c in pairs(L.cargas) do
                if Equipo.Mismo(c.c, L.cid) then hayCargas = true break end
            end
            if hayCargas and IsControlJustReleased(0, TECLA_G) then
                CreateThread(function()
                    local r = Pedir('detonar')
                    if r and r.ok and r.animar then
                        local d = Config.Explosivos.detonar
                        if Cargar(d.dict) then TaskPlayAnim(ped, d.dict, d.clip, 8.0, 4.0, 1500, d.flag, 0, false, false, false) end
                    end
                end)
            end

            if mano then
                -- Con un pedrusco en brazos (de roca, o triturado de la planta).
                local m = Config.Materiales[mano]
                local trit = Mina.Triturado(mano)
                local carreSuelo = CarretillaCerca(pos, CR.distancia)
                tarjeta = { tipo = 'pedrusco', datos = { nombre = trit and m.nombre or ('Pedrusco de ' .. m.nombre:lower()), veta = mano,
                    pago = Valor(mano), enBrazos = true, acciones = {}, aviso = nil } }
                local acc = tarjeta.datos.acciones
                if trit and EnHorno(pos) then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Echar al horno' }
                    Ayuda('E', 'Echar al horno', { 'X', 'Soltar' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('horno', {}, (Mina.Horno()), { anim = Config.Anims.echar }) end
                elseif trit and carreSuelo then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Meter en la carretilla' }
                    Ayuda('E', 'Meter en la carretilla', { 'X', 'Soltar' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('meter', {}, carreSuelo.punto, { anim = Config.Anims.echar }) end
                elseif trit then
                    tarjeta.datos.aviso = 'Llévalo al horno de la fundición (o a la carretilla).'
                    Ayuda('X', 'Soltarlo')
                elseif Trabajo.EnBorde(pos) then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Echar a la tolva' }
                    Ayuda('E', 'Echar a la tolva', { 'X', 'Soltar' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('tolva', {}, Config.Planta.boca, { anim = Config.Anims.echar }) end
                elseif trasera then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Echar a la caja' }
                    Ayuda('E', 'Echar a la caja', { 'X', 'Soltar' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('echar', {}, trasera, { anim = Config.Anims.echar }) end
                elseif carreSuelo then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Meter en la carretilla' }
                    Ayuda('E', 'Meter en la carretilla', { 'X', 'Soltar' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('meter', {}, carreSuelo.punto, { anim = Config.Anims.echar }) end
                else
                    tarjeta.datos.aviso = 'Llévalo a la trasera de tu vehículo (o a la carretilla).'
                    Ayuda('X', 'Soltar el pedrusco')
                end
                acc[#acc + 1] = { tecla = 'X', texto = 'Soltarlo aquí' }
                if IsControlJustReleased(0, TECLA_X) then
                    L.QuitarAyuda('trabajo')
                    CreateThread(function() Pedir('soltar') end)
                end
            elseif carre then
                -- Empujando la carretilla.
                local n = Contar(carre.carga)
                local obj = Objetivo(pos)
                tarjeta = { tipo = 'carretilla', datos = { carga = n, max = CR.capacidad, vetas = {}, acciones = {}, aviso = nil } }
                local cuenta = {}
                for _, veta in pairs(carre.carga or {}) do cuenta[veta] = (cuenta[veta] or 0) + 1 end
                for _, id in ipairs(Config.OrdenMateriales) do
                    if cuenta[id] then tarjeta.datos.vetas[#tarjeta.datos.vetas + 1] = { nombre = Config.Materiales[id].nombre, n = cuenta[id] } end
                    if cuenta[id .. '_t'] then
                        tarjeta.datos.vetas[#tarjeta.datos.vetas + 1] = { nombre = Config.Materiales[id .. '_t'].nombre, n = cuenta[id .. '_t'] }
                    end
                end
                local acc = tarjeta.datos.acciones
                local trits = 0
                for _, veta in pairs(carre.carga or {}) do
                    if Mina.Triturado(veta) then trits = trits + 1 end
                end
                if trits > 0 and EnHorno(pos) then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Echar al horno' }
                    Ayuda('E', ('Echar al horno (%d)'):format(trits), { 'H', 'Dejarla' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('horno', {}, (Mina.Horno()), { anim = Config.Anims.echar }) end
                elseif trits > 0 and trits == n then
                    tarjeta.datos.aviso = 'Llévala al horno de la fundición.'
                    Ayuda('H', 'Dejar la carretilla')
                elseif n > 0 and Trabajo.EnBorde(pos) then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Volcar en la tolva' }
                    Ayuda('E', ('Volcar en la tolva (%d)'):format(n), { 'H', 'Dejarla' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('tolva', {}, Config.Planta.boca, { anim = Config.Anims.echar }) end
                -- Coger el pedrusco va antes que las acciones de la trasera: al aparcar
                -- junto a la roca, E tiene que cargar la piedra (visto el 28/09).
                elseif obj and obj.tipo == 'pedrusco' and n < CR.capacidad then
                    local mio = Equipo.Mismo(obj.t.c, L.cid)
                    if mio then
                        acc[#acc + 1] = { tecla = 'E', texto = 'Echarlo a la carretilla' }
                        Ayuda('E', 'Echar el pedrusco a la carretilla', { 'H', 'Dejarla' })
                        if IsControlJustReleased(0, TECLA_E) then Lanzar('coger', { pedrusco = obj.t.id }, obj.punto, { anim = P.coger }) end
                    else
                        tarjeta.datos.aviso = ('Ese pedrusco es de %s.'):format(obj.t.n or 'otro minero')
                        Ayuda('H', 'Dejar la carretilla')
                    end
                elseif trasera and n == 0 and not CarretillaEnCaja(traseraVeh) then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Subirla a la caja' }
                    Ayuda('E', 'Subir la carretilla a la caja', { 'H', 'Dejarla' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('subirCarretilla', {}, trasera, { anim = Config.Anims.echar }) end
                elseif trasera and n > 0 then
                    acc[#acc + 1] = { tecla = 'E', texto = 'Volcar en la caja' }
                    Ayuda('E', ('Volcar la carretilla (%d)'):format(n), { 'H', 'Dejarla' })
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('volcar', {}, trasera, { anim = Config.Anims.echar }) end
                else
                    if n >= CR.capacidad then tarjeta.datos.aviso = 'Llena: vuélcala en la caja del vehículo.' end
                    Ayuda('H', 'Dejar la carretilla')
                end
                acc[#acc + 1] = { tecla = 'H', texto = 'Dejarla aquí' }
                if IsControlJustReleased(0, TECLA_H) then
                    L.QuitarAyuda('trabajo')
                    CreateThread(function() Pedir('carretilla') end)
                end
            else
                -- Con las manos libres.
                local obj = Objetivo(pos)
                local carreSuelo = CarretillaCerca(pos, CR.distancia)
                local h = L.Herramienta()
                local nivel = L.Nivel()
                if obj and obj.tipo == 'roca' then
                    local v = obj.v
                    local m = Config.Materiales[v.v]
                    local mio = v.c == nil or Equipo.Mismo(v.c, L.cid)
                    local datos = {
                        frente = Mina.Frente(obj.roca.frente).nombre, veta = v.v, vetaNombre = m and m.nombre or '',
                        pago = m and m.pago or 0, estado = v.e, golpes = v.g or 0, total = R.golpes,
                        dueno = (not mio and v.n) or nil, carga = v.k ~= nil,
                        herramienta = h and { nombre = Config.Herramientas[h].nombre } or nil,
                        acciones = {}, aviso = nil,
                    }
                    if v.e == 'escombro' then
                        datos.aviso = 'Partida: la cantera la repone con el tiempo.'
                    elseif m and nivel < m.nivel then
                        datos.aviso = ('Las vetas de %s se pican desde el nivel %d.'):format(m.nombre:lower(), m.nivel)
                    elseif v.k then
                        datos.aviso = ('Lleva una carga: aléjate %d m y pulsa G.'):format(math.floor(Config.Explosivos.lejos))
                    elseif not mio then
                        datos.aviso = ('La está picando %s.'):format(v.n or 'otro minero')
                    elseif not h then
                        datos.aviso = 'No llevas herramienta: pídesela al capataz.'
                    else
                        datos.acciones[#datos.acciones + 1] = { tecla = 'E', texto = 'Picar' }
                        local conCarga = nivel >= Config.Explosivos.nivel and L.Cargas() > 0
                        if conCarga then datos.acciones[#datos.acciones + 1] = { tecla = 'Y', texto = ('Poner una carga (%d)'):format(L.Cargas()) } end
                        Ayuda('E', 'Picar la roca', conCarga and { 'Y', 'Carga' } or nil)
                        if IsControlJustReleased(0, TECLA_E) then
                            Lanzar('picar', { roca = obj.roca.id }, obj.punto, { herramienta = true, golpes = true, acercar = 1.35 })
                        elseif conCarga and IsControlJustReleased(0, TECLA_Y) then
                            local pc = Config.Explosivos
                            Lanzar('cargaRoca', { roca = obj.roca.id }, obj.punto, {
                                anim = pc.poner, prop = { modelo = pc.modelo, hueso = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } })
                        end
                    end
                    tarjeta = { tipo = 'roca', datos = datos }
                elseif obj and obj.tipo == 'marca' then
                    local E = Config.Explosivos
                    local datos = { nombre = obj.bloque.nombre, cargas = #(obj.v.cargas or {}), total = Config.Voladura.cargas,
                        llevas = L.Cargas(), acciones = {}, aviso = nil }
                    if L.Cargas() < 1 then
                        datos.aviso = 'No te quedan cargas: cómpralas al capataz.'
                    else
                        datos.acciones[#datos.acciones + 1] = { tecla = 'E', texto = 'Poner la carga aquí' }
                        Ayuda('E', ('Poner la carga (%d de %d)'):format(datos.cargas + 1, datos.total))
                        if IsControlJustReleased(0, TECLA_E) then
                            Lanzar('cargaBloque', { bloque = obj.bloque.id, i = obj.i }, obj.bloque.pos.xyz, {
                                anim = E.poner, prop = { modelo = E.modelo, hueso = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) } })
                        end
                    end
                    tarjeta = { tipo = 'bloque', datos = datos }
                elseif obj and obj.tipo == 'pedrusco' then
                    local t = obj.t
                    local m = Config.Materiales[t.m]
                    local mio = Equipo.Mismo(t.c, L.cid)
                    local datos = { nombre = Mina.Triturado(t.m) and m.nombre or ('Pedrusco de ' .. m.nombre:lower()), veta = t.m,
                        pago = Valor(t.m), enBrazos = false,
                        dueno = (not mio and t.n) or nil, acciones = {}, aviso = nil }
                    if mio then
                        datos.acciones[#datos.acciones + 1] = { tecla = 'E', texto = 'Cogerlo' }
                        Ayuda('E', 'Coger el pedrusco', carreSuelo and { 'H', 'Carretilla' } or nil)
                        if IsControlJustReleased(0, TECLA_E) then Lanzar('coger', { pedrusco = t.id }, obj.punto, { anim = P.coger }) end
                    else
                        datos.aviso = ('Es de %s.'):format(t.n or 'otro minero')
                    end
                    tarjeta = { tipo = 'pedrusco', datos = datos }
                end
                -- En la trasera, con la carretilla del equipo en la caja: bajarla.
                local enCaja = not obj and trasera and CarretillaEnCaja(traseraVeh)
                if enCaja then
                    Ayuda('E', 'Bajar la carretilla')
                    if IsControlJustReleased(0, TECLA_E) then Lanzar('bajarCarretilla', {}, trasera, { anim = Config.Anims.echar }) end
                end
                if carreSuelo then
                    if not ultimaAyuda then Ayuda('H', 'Empujar la carretilla') end
                    if IsControlJustReleased(0, TECLA_H) then
                        L.QuitarAyuda('trabajo')
                        CreateThread(function() Pedir('carretilla') end)
                    end
                    if not tarjeta then
                        local n = Contar(carreSuelo.v.carga)
                        tarjeta = { tipo = 'carretilla', datos = { carga = n, max = CR.capacidad, vetas = {},
                            acciones = { { tecla = 'H', texto = 'Empujarla' } }, aviso = nil } }
                    end
                end
            end
        end

        -- Solo una tarjeta: la de lo que toca, y las demás fuera.
        for _, tipo in ipairs({ 'roca', 'pedrusco', 'carretilla', 'bloque' }) do
            if not tarjeta or tarjeta.tipo ~= tipo then L.SinTarjeta(tipo) end
        end
        if tarjeta then L.Tarjeta(tarjeta.tipo, tarjeta.datos) end
        if not ultimaAyuda then L.QuitarAyuda('trabajo') end
        Wait(espera)
    end
end)
