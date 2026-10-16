--[[ ── El trabajo a pie ───────────────────────────────────────────────────────

     Lo que tienes delante decide qué puedes hacer:
       árbol en pie       E hacer la muesca (← → eliges hacia dónde cae; la
                          franja verde es la recomendada)
       árbol con muesca   E corte de caída
       árbol caído        E desramar el tramo más cercano
       tronco limpio      E trocear por la marca más cercana
       tronco suelto      E engancharlo al cable de tu camión
     El hacha (o la motosierra, al subir de nivel) la da el encargado del
     aserradero al empezar la jornada.

     Cada paso: el servidor dice si se puede y cuánto dura, se hace la
     animación con la herramienta en la mano, y el servidor lo vuelve a
     comprobar al terminar. ]]

Trabajo = {}

local A = Config.Arbol
local T = Config.Tronco
local TECLA_E, TECLA_G, IZQ, DER = 38, 47, 174, 175

local TEXTOS = {
    muesca = 'Haciendo la muesca', tumbar = 'Corte de caída', rama = 'Desramando', corte = 'Troceando',
    enganchar = 'Enganchando el cable',
}

local RUMBOS = { [0] = 'el norte', [45] = 'el noroeste', [90] = 'el oeste', [135] = 'el suroeste', [180] = 'el sur',
    [225] = 'el sureste', [270] = 'el este', [315] = 'el noreste' }

-- ── Ejecutar un paso ──────────────────────────────────────────────────────

--- Pide el paso al servidor, anima y lo termina. `mirar` = punto al que girarse.
function Trabajo.Ejecutar(paso, datos, mirar, opciones)
    if L.ocupado then return false end
    opciones = opciones or {}
    L.ocupado = true
    local r = lib.callback.await('origen_lumber:empezar', false, paso, datos or {})
    if not r or not r.ok then
        L.ocupado = false
        if r and r.mensaje then L.Aviso(r.mensaje, 'error') end
        return false
    end
    if mirar then
        TaskTurnPedToFaceCoord(cache.ped, mirar.x + 0.0, mirar.y + 0.0, mirar.z + 0.0, 500)
        Wait(450)
    end

    local anim, prop = opciones.anim, opciones.prop
    local h = L.Herramienta()
    local hc = opciones.herramienta and h and Config.Herramientas[h] or nil
    if hc then
        anim = anim or (paso == 'rama' and hc.animRama) or hc.anim
    end

    -- Astillas y serrín mientras se trabaja.
    local trabajando = true

    if opciones.astillas and mirar then
        CreateThread(function()
            Wait(700)
            while trabajando do
                Monte.Astillas(mirar.x, mirar.y, mirar.z + (opciones.alturaAstillas or 0.8))
                Wait(h == 'motosierra' and 450 or 1100)
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
        anim = anim and { dict = anim.dict, clip = anim.clip, flag = anim.flag or 1 } or nil,
        prop = prop and { model = prop.modelo, bone = prop.hueso, pos = prop.pos, rot = prop.rot } or nil,
    })
    trabajando = false

    if not hecho then
        lib.callback.await('origen_lumber:cancelar', false)
        L.ocupado = false
        return false
    end
    local fin = lib.callback.await('origen_lumber:terminar', false, paso)
    ClearPedTasks(cache.ped)
    L.ocupado = false
    if not fin or not fin.ok then
        if fin and fin.mensaje then L.Aviso(fin.mensaje, 'error') end
        return false
    end
    if fin.mensaje then L.Aviso(fin.mensaje, 'success') end
    CreateThread(L.PedirYo)
    return true, fin
end

-- ── La herramienta en la mano ─────────────────────────────────────────────

--[[ El hacha y la motosierra son objetos del inventario, no armas: mientras
     llevas una, le atamos su prop a la mano para que se vea. ]]
local enMano = { que = nil, ent = nil }

local function SoltarHerramienta()
    if enMano.ent and DoesEntityExist(enMano.ent) then DeleteEntity(enMano.ent) end
    enMano.que, enMano.ent = nil, nil
end

--- Las weapon_hatchet de antes: al quitárselas hay que quitar también el
--- arma del personaje, o se queda colgada de la cadera.
RegisterNetEvent('origen_lumber:sinArma', function(item)
    if GetInvokingResource() then return end
    if type(item) ~= 'string' then return end
    local hash = GetHashKey(item)
    if HasPedGotWeapon(cache.ped, hash, false) then
        RemoveWeaponFromPed(cache.ped, hash)
        SetCurrentPedWeapon(cache.ped, GetHashKey('weapon_unarmed'), true)
    end
    pcall(function() exports.origen_inventory:unarmedPed() end)
end)

CreateThread(function()
    while true do
        local h = L.Herramienta()
        local cfg = Config.Herramientas[h]
        local quiere = (cfg and cfg.prop) and h or nil
        if enMano.que ~= quiere or (enMano.ent and not DoesEntityExist(enMano.ent)) then
            SoltarHerramienta()
            if quiere then
                local p = cfg.prop
                local hash = GetHashKey(p.modelo)
                if Monte.Cargar(hash) then
                    local c = GetEntityCoords(cache.ped)
                    local ent = Rastro.Marcar(CreateObject(hash, c.x, c.y, c.z, false, false, false))
                    SetEntityCollision(ent, false, false)
                    AttachEntityToEntity(ent, cache.ped, GetPedBoneIndex(cache.ped, p.hueso),
                        p.pos.x, p.pos.y, p.pos.z, p.rot.x, p.rot.y, p.rot.z, true, true, false, true, 0, true)
                    enMano.que, enMano.ent = quiere, ent
                end
            end
        end
        Wait(600)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then SoltarHerramienta() end
end)

-- ── Qué tienes delante ────────────────────────────────────────────────────

local function DistanciaASegmento(px, py, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local l2 = dx * dx + dy * dy
    local t = l2 > 0 and math.max(0, math.min(1, ((px - ax) * dx + (py - ay) * dy) / l2)) or 0
    local cx, cy = ax + dx * t, ay + dy * t
    return math.sqrt((px - cx) ^ 2 + (py - cy) ^ 2)
end

--- Lo más cercano con lo que se puede trabajar.
local function Objetivo(pos)
    local mejor, dMejor
    local function Probar(o, d)
        if d and (not dMejor or d < dMejor) then mejor, dMejor = o, d end
    end
    for _, arbol in ipairs(Config.Arboles) do
        local d = #(pos.xy - arbol.pos.xy)
        if d < 40.0 then
            local v = L.Arbol(arbol.id)
            if v.e == 'pie' or v.e == 'talando' or v.e == 'tocon' or v.e == 'planton' then
                if d <= A.distancia + 0.6 then Probar({ tipo = 'arbol', arbol = arbol, v = v, punto = arbol.pos }, d) end
            elseif v.e == 'caido' or v.e == 'limpio' then
                local puntos = Lumber.Puntos(arbol, v.r)
                local lista = v.e == 'caido' and puntos.ramas or puntos.cortes
                local hechos = v.e == 'caido' and v.ramas or v.cortes
                for i, pto in ipairs(lista) do
                    if not (hechos and hechos[tostring(i)]) then
                        local di = #(pos.xy - pto.xy)
                        if di <= A.distancia then
                            Probar({ tipo = v.e == 'caido' and 'rama' or 'corte', arbol = arbol, v = v, i = i, punto = pto,
                                total = #lista, puntos = puntos }, di)
                        end
                    end
                end
            end
        end
    end
    for id, t in pairs(L.troncos) do
        if t.s == 'suelo' or t.s == 'cable' then
            local dx, dy = Lumber.Direccion(t.p.h or 0)
            local mitad = T.largo / 2
            local d = DistanciaASegmento(pos.x, pos.y, t.p.x - dx * mitad, t.p.y - dy * mitad, t.p.x + dx * mitad, t.p.y + dy * mitad)
            -- La altura, la del tronco PINTADO: t.p.z es la del pie del árbol
            -- (el servidor no sabe dónde está el suelo), y en ladera los troncos
            -- de la copa quedan varios metros más arriba o más abajo. Con t.p.z
            -- no salía la tarjeta y el tronco «no se podía coger».
            local ent = Monte.TroncoEnt(id)
            local tz = (ent and DoesEntityExist(ent)) and GetEntityCoords(ent).z or t.p.z
            if d <= 1.8 and math.abs(pos.z - tz) < 3.0 then
                Probar({ tipo = 'tronco', t = t, punto = vec3(t.p.x, t.p.y, t.p.z) }, d + 0.4)
            end
        end
    end
    return mejor
end

-- ── La muesca: hacia dónde cae ────────────────────────────────────────────

local elegido = {}      -- [arbolId] = rumbo elegido

local function CaeSobreOtro(arbol, rumbo)
    local esp = Lumber.Especie(arbol.especie)
    for _, otro in ipairs(Config.Arboles) do
        if otro.id ~= arbol.id and #(otro.pos.xy - arbol.pos.xy) < esp.altura then
            local e = L.arboles[otro.id]
            local enPie = not e or e.e == 'talando' or e.e == 'planton'
            if enPie and Lumber.EnFranja(arbol.pos, rumbo, esp.altura * 0.85, 2.0, otro.pos.x, otro.pos.y) then
                return true
            end
        end
    end
    return false
end

local function Recomendado(arbol)
    local mejor, puntos = 0, nil
    for r = 0, 315, A.paso do
        if not CaeSobreOtro(arbol, r) then
            local dx, dy = Lumber.Direccion(r)
            local libre = 0
            for _, otro in ipairs(Config.Arboles) do
                local ox, oy = otro.pos.x - arbol.pos.x, otro.pos.y - arbol.pos.y
                if ox * dx + oy * dy > 0 then libre = libre - 1 / math.max(1, math.sqrt(ox * ox + oy * oy)) end
            end
            if not puntos or libre > puntos then mejor, puntos = r, libre end
        end
    end
    return mejor
end

-- ── Tarjetas ──────────────────────────────────────────────────────────────

local ESTADOS = { pie = 'En pie', talando = 'Con la muesca', caido = 'En el suelo', limpio = 'Desramado', tocon = 'Tocón',
    planton = 'Plantón' }

local function HerramientaTarjeta()
    local h = L.Herramienta()
    if not h then return nil end
    return { nombre = Config.Herramientas[h].nombre }
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

CreateThread(function()
    while true do
        local espera = 500
        local ped = cache.ped
        local enPie = L.cerca and not L.panelAbierto and not cache.vehicle and not IsPedDeadOrDying(ped, true)
        local objetivo = enPie and not L.ocupado and Objetivo(GetEntityCoords(ped)) or nil
        ultimaAyuda = false

        if objetivo then
            espera = 0
            local jornada = L.Jornada()
            local h = L.Herramienta()
            local nivel = L.yo and L.yo.nivel or 1

            if objetivo.tipo == 'arbol' or objetivo.tipo == 'rama' or objetivo.tipo == 'corte' then
                local arbol, v = objetivo.arbol, objetivo.v
                local esp = Lumber.Especie(arbol.especie)
                local cuartel = Lumber.Cuartel(arbol.cuartel)
                local mio = v.c == nil or Equipo.Mismo(v.c, L.cid)
                local reservado = not mio and v.e ~= 'tocon' and v.e ~= 'planton'
                local acciones, aviso = {}, nil
                local datos = {
                    nombre = esp.nombre, cuartel = cuartel.nombre, estado = v.e, estadoTexto = ESTADOS[v.e],
                    dueno = (not mio and v.n) or nil, pasos = nil, rumbo = nil, crece = nil,
                    herramienta = HerramientaTarjeta(),
                }
                if v.e == 'caido' then datos.pasos = { hechos = Contar(v.ramas), total = objetivo.total or (esp.troncos + 1) } end
                if v.e == 'limpio' then datos.pasos = { hechos = Contar(v.cortes), total = objetivo.total or (esp.troncos - 1) } end
                if v.e == 'tocon' or v.e == 'planton' then
                    local total = v.e == 'tocon' and A.rebrote or A.crecePlanton
                    local t = (v.t or 0) + (GetGameTimer() - (v.recibida or GetGameTimer())) / 1000
                    datos.crece = math.min(1, t * Lumber.Velocidad() / total)
                end

                local paso, datosPaso, mirar
                if not jornada then
                    aviso = 'Empieza la jornada con el encargado del aserradero.'
                elseif nivel < esp.nivel and (v.e == 'pie' or v.e == 'talando') then
                    aviso = ('Para talar %s necesitas nivel %d.'):format(esp.nombre:lower(), esp.nivel)
                elseif v.e == 'pie' or (v.e == 'talando' and not mio) then
                    if reservado and v.e == 'talando' then
                        aviso = ('Lo está talando %s.'):format(v.n or 'otro leñador')
                    elseif not h then
                        aviso = 'No llevas herramienta: pídesela al encargado del aserradero.'
                    else
                        local rec = Recomendado(arbol)
                        local r = elegido[arbol.id] or rec
                        if IsControlJustReleased(0, IZQ) then r = (r + A.paso) % 360 end
                        if IsControlJustReleased(0, DER) then r = (r - A.paso + 360) % 360 end
                        elegido[arbol.id] = r
                        local buena = r == rec
                        datos.rumbo = { texto = 'Cae hacia ' .. (RUMBOS[r] or ''), recomendado = buena }
                        Monte.Franja(arbol.pos, r, 0.8, esp.altura, A.caida.ancho, buena and { 60, 200, 110, 70 } or { 240, 170, 40, 70 })
                        Monte.Flecha(arbol.pos, r, math.min(8.0, esp.altura * 0.5), buena and { 60, 220, 120, 190 } or { 250, 180, 50, 190 })
                        acciones = { { tecla = 'E', texto = 'Hacer la muesca' }, { tecla = '← →', texto = 'Hacia dónde cae' } }
                        paso, datosPaso, mirar = 'muesca', { arbol = arbol.id, rumbo = r }, arbol.pos
                        if not buena then aviso = 'Así caerá encima de otro árbol o sin sitio: mejor hacia la franja verde.' end
                    end
                elseif v.e == 'talando' then
                    if not h then
                        aviso = 'No llevas herramienta: pídesela al encargado del aserradero.'
                    else
                        Monte.Franja(arbol.pos, v.r, 0.8, esp.altura, A.caida.ancho, { 220, 60, 50, 80 })
                        acciones = { { tecla = 'E', texto = 'Corte de caída' } }
                        paso, datosPaso, mirar = 'tumbar', { arbol = arbol.id }, arbol.pos
                        aviso = 'Avisa: el árbol caerá sobre la zona roja.'
                    end
                elseif objetivo.tipo == 'rama' or objetivo.tipo == 'corte' then
                    if reservado then
                        aviso = ('Es de %s.'):format(v.n or 'otro leñador')
                    elseif not h then
                        aviso = 'No llevas herramienta: pídesela al encargado del aserradero.'
                    else
                        local col = objetivo.tipo == 'rama' and { 120, 220, 90, 150 } or { 255, 45, 106, 170 }
                        Monte.Marca(objetivo.punto, v.r, col, objetivo.tipo == 'rama' and 2.4 or 1.6)
                        local texto = objetivo.tipo == 'rama' and 'Desramar este tramo' or 'Trocear por la marca'
                        acciones = { { tecla = 'E', texto = texto } }
                        paso, datosPaso, mirar = objetivo.tipo, { arbol = arbol.id, i = objetivo.i }, objetivo.punto
                    end
                elseif v.e == 'tocon' or v.e == 'planton' then
                    aviso = 'Ya talado: vuelve a crecer solo.'
                end

                -- Las marcas del árbol caído se ven todas mientras estás cerca.
                if (v.e == 'caido' or v.e == 'limpio') and objetivo.puntos then
                    local lista = v.e == 'caido' and objetivo.puntos.ramas or objetivo.puntos.cortes
                    local hechos = v.e == 'caido' and v.ramas or v.cortes
                    for i, pto in ipairs(lista) do
                        if i ~= objetivo.i and not (hechos and hechos[tostring(i)]) then
                            Monte.Marca(pto, v.r, { 255, 255, 255, 90 }, v.e == 'caido' and 2.0 or 1.4)
                        end
                    end
                end

                datos.acciones, datos.aviso = acciones, aviso
                L.Tarjeta('arbol', datos)
                L.SinTarjeta('tronco')
                if paso then
                    Ayuda('E', acciones[1].texto, paso == 'muesca' and { '←→', 'Dirección' } or nil)
                    if IsControlJustReleased(0, TECLA_E) then
                        L.QuitarAyuda('trabajo')
                        local opciones = { herramienta = true, astillas = true,
                            alturaAstillas = (paso == 'muesca' or paso == 'tumbar') and 0.7 or 0.4 }
                        CreateThread(function() Trabajo.Ejecutar(paso, datosPaso, mirar, opciones) end)
                    end
                end
            elseif objetivo.tipo == 'tronco' then
                local t = objetivo.t
                local esp = Lumber.Especie(t.e)
                local mio = Equipo.Mismo(t.c, L.cid)
                local datos = {
                    nombre = 'Tronco de ' .. esp.nombre:lower(), pago = esp.pago,
                    dueno = (not mio and t.n) or nil, estado = t.s, acciones = {}, aviso = nil,
                }
                L.SinTarjeta('arbol')
                if not jornada then
                    datos.aviso = 'Empieza la jornada con el encargado del aserradero.'
                elseif t.s == 'cable' then
                    datos.aviso = 'Enganchado al cable: tira desde la palanca del camión.'
                else
                    local camion = Vehiculos and Vehiculos.MiCamion and Vehiculos.MiCamion()
                    local principal
                    if camion and mio then
                        datos.acciones[#datos.acciones + 1] = { tecla = 'E', texto = 'Enganchar al cable del camión' }
                        principal = { 'E', 'Enganchar al cable del camión' }
                    end
                    if not mio then
                        datos.aviso = ('Es de %s.'):format(t.n or 'otro leñador')
                    elseif not camion then
                        datos.aviso = 'Acerca el camión: el cable llega a 30 m, y con las cinchas quitadas.'
                    end
                    if principal then
                        Ayuda(principal[1], principal[2])
                        if IsControlJustReleased(0, TECLA_E) then
                            L.QuitarAyuda('trabajo')
                            CreateThread(function()
                                Trabajo.Ejecutar('enganchar', { tronco = t.id }, objetivo.punto, { anim = Config.Anims.enganchar })
                            end)
                        end
                    end
                end
                L.Tarjeta('tronco', datos)
            end
        else
            L.SinTarjeta('arbol')
            L.SinTarjeta('tronco')
        end
        if not ultimaAyuda then L.QuitarAyuda('trabajo') end
        Wait(espera)
    end
end)

Trabajo.Recomendado = Recomendado
