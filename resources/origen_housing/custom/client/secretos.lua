-- Pasos secretos (ver config/secretos.lua y custom/server/secretos.lua):
-- puertas ocultas y trampillas de las casas de modalidad libre.
--
-- La pieza la monta custom/client/obra.lua como cualquier otra (un objeto
-- local, suelto, nunca dentro de un paño): aquí esa pieza no se crea ni se
-- borra, solo se MUEVE según lo que diga el servidor —abierto o cerrado, y
-- cuánto lleva moviéndose, para que todos lo vean a la par—. La colisión va
-- con el objeto. Pegado a un paso y mirándolo, la E lo acciona.
--
-- Una puerta secreta con mueble (librería, chimenea…) son dos cosas: la PARED,
-- que es esa pieza de la obra (el tabique de su material, pintable), y el
-- MUEBLE, un objeto local aparte que se crea AQUÍ, con el mismo origen y los
-- mismos ejes que la pared, y que se lleva con ella fotograma a fotograma (no
-- va pegado con AttachEntityToEntity: un objeto pegado pierde o cambia su
-- colisión con los personajes, y recolocado es el mismo método que ya mueve la
-- pared). Se apunta en la tabla de la obra (claves[objeto] = clave) para que la
-- cinta lo tome por esa misma pieza al mirarlo.
--
-- Además: los disparadores (muebles que accionan un paso desde lejos, con la
-- E), el código que pide el servidor a quien no tiene llave, y la G: al dueño
-- le abre el menú del paso (código, cierre automático, alarma, cerrojo) o del
-- disparador (a qué paso va); a los demás, junto a un paso, les echa o les
-- quita el cerrojo si están en el lado de dentro. Todo lo decide el servidor.
--
-- De custom/client/obra.lua solo se usa lo público: Obra.Actual, Obra.Colocacion
-- y sus eventos.
local S = Config.Secretos
local O = Config.Obra

local casa = nil        -- id (texto) de la casa de obra en la que se está
local estados = {}      -- [clave] = { valor, abierto, modo, lado, sentido, inicio (GetGameTimer de este cliente) }
local moviendo = {}     -- [clave] = true: los que se están moviendo ahora
local lista = {}        -- los pasos de la casa: { clave, base, largo, suelo, nombre, k }
local gatillos = {}     -- los disparadores de la casa: { id, entidad, g (sus ajustes) }
local gestos = {}       -- entidad → true: el mueble que está haciendo su gesto
local pidiendo = false  -- con un menú o el diálogo del código abierto
local muebles = {}      -- [clave] = { modelo, ent, modeloAsa, asa }: el mueble (y el asa) de cada puerta secreta
local tanda = 0         -- cada vez que se rehacen los muebles; una tanda vieja que aún espera un modelo se deja
local puedo = false     -- ¿tiene llave de esta casa (o permiso para construir en ella)?
local menuAjeno = false
local conTexto = false
local ultima = 0

-- La cinta de decorar usa la E para cambiar de categoría y no se le puede
-- preguntar si está abierta; sí avisa, como todos los menús, de que aparta el HUD.
-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

-- El cartel y las teclas (la E y la G) los lleva el árbitro común
-- (custom/client/tecla_e.lua): aquí solo se ofrecen, o se retiran.
local function Texto(texto)
    if not texto then Tecla.Retirar('secretos') end
end

local function ObraActual()
    local o = Obra and Obra.Actual and Obra.Actual() or nil
    return o and casa and o.id == casa and o or nil
end

-- ── Mover la pieza ──────────────────────────────────────────────────────
-- Cuánto de abierto está ahora mismo (0 cerrado … 1 abierto), con arranque y
-- frenada suaves, y si ya ha terminado de moverse.
local function Abertura(e)
    local t = (GetGameTimer() - e.inicio) / e.ms
    if t >= 1.0 then return e.abierto and 1.0 or 0.0, true end
    if t < 0.0 then t = 0.0 end
    local s = t * t * (3.0 - 2.0 * t)
    return e.abierto and s or 1.0 - s, false
end

-- Deja el objeto del paso donde le toca con esa abertura
local function Poner(o, clave, e, f)
    local ent = o.objetos[clave]
    if not ent or not DoesEntityExist(ent) then return end
    local valor = o.piezas[clave]
    local estilo, _, tipo = S.Estilo(clave, valor)
    if not estilo then return end
    local _, base, rumbo = Obra.Colocacion(clave, valor)
    if not base then return end
    local pos, rx, ry, rz = base, 0.0, 0.0, rumbo
    if tipo == 'borde' then
        local enX = clave:sub(1, 1) == 'x'
        local largo = enX and o.Y or o.X        -- a lo largo de la pared
        if e.modo == 'corre' then
            -- se despega un pelo hacia su frente y se mete tras la pared de al lado
            local r = math.rad(rumbo)
            local frente = vector3(-math.sin(r), math.cos(r), 0.0)
            local separa = (estilo.separa or 0.02) * math.min(1.0, f * 10.0)
            pos = base + largo * (e.lado * (estilo.recorrido or 1.9) * f) + frente * separa
        else
            -- gira sobre el extremo de la bisagra, como una puerta
            local bisagra = base + largo * (e.lado * O.celda / 2)
            local a = (enX and 1 or -1) * e.lado * e.sentido * (estilo.angulo or 90.0) * f
            local ra = math.rad(a)
            local v = base - bisagra
            pos = bisagra + vector3(v.x * math.cos(ra) - v.y * math.sin(ra), v.x * math.sin(ra) + v.y * math.cos(ra), 0.0)
            rz = rumbo + a
        end
    else
        local d = O.giros[e.lado] or O.giros[0]
        local hacia = o.X * (d[1] + 0.0) + o.Y * (d[2] + 0.0)
        if e.modo == 'corre' then
            -- baja un pelo y se mete bajo el suelo de al lado
            local separa = (estilo.separa or 0.02) * math.min(1.0, f * 10.0)
            pos = base + hacia * ((estilo.recorrido or 1.9) * f) - vector3(0.0, 0.0, separa)
        else
            -- se levanta girando sobre el lado de la bisagra
            local a = (estilo.angulo or 85.0) * f
            local ra, medio = math.rad(a), O.celda / 2
            pos = base + hacia * (medio - medio * math.cos(ra)) + vector3(0.0, 0.0, medio * math.sin(ra))
            local signo = (S.giroSuelo == -1) and -1.0 or 1.0
            rx, ry = -d[2] * a * signo, d[1] * a * signo
        end
    end
    SetEntityCoordsNoOffset(ent, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(ent, rx, ry, rz, 2, true)
    -- su mueble y su asa, con ella
    local m = muebles[clave]
    if m then
        for _, otro in ipairs({ m.ent or 0, m.asa or 0 }) do
            if otro ~= 0 and DoesEntityExist(otro) then
                SetEntityCoordsNoOffset(otro, pos.x, pos.y, pos.z, false, false, false)
                SetEntityRotation(otro, rx, ry, rz, 2, true)
            end
        end
    end
end

-- ── El mueble de delante ────────────────────────────────────────────────
local function BorrarMueble(clave)
    local m = muebles[clave]
    if not m then return end
    muebles[clave] = nil
    local o = Obra and Obra.Actual and Obra.Actual() or nil
    for _, ent in ipairs({ m.ent or 0, m.asa or 0 }) do
        if ent ~= 0 then
            if o and o.claves[ent] == clave then o.claves[ent] = nil end
            if DoesEntityExist(ent) then DeleteEntity(ent) end
        end
    end
end

local function BorrarMuebles()
    tanda = tanda + 1
    for clave in pairs(muebles) do BorrarMueble(clave) end
end

local function CargarModelo(modelo)
    if HasModelLoaded(modelo) then return true end
    RequestModel(modelo)
    local t = GetGameTimer()
    while not HasModelLoaded(modelo) and GetGameTimer() - t < 6000 do Wait(10) end
    return HasModelLoaded(modelo)
end

-- Deja un objeto del mueble donde está ahora su pared (cerrada, o como la tenga el estado)
local function Arrimar(o, clave, ent)
    local pared = o.objetos[clave]
    local pos, rot
    if pared and DoesEntityExist(pared) then
        pos, rot = GetEntityCoords(pared), GetEntityRotation(pared, 2)
    else
        local _, base, rumbo = Obra.Colocacion(clave, o.piezas[clave])
        if not base then return end
        pos, rot = base, vector3(0.0, 0.0, rumbo)
    end
    SetEntityCoordsNoOffset(ent, pos.x, pos.y, pos.z, false, false, false)
    SetEntityRotation(ent, rot.x, rot.y, rot.z, 2, true)
end

-- Los muebles que tiene que haber: se llama cada vez que se monta la obra.
-- Sobra el de la pieza que ya no está (o cambió de estilo) y falta el de la nueva.
local function Amueblar(o)
    tanda = tanda + 1
    local esta = tanda
    local quiero = {}
    for clave, valor in pairs(o.piezas) do
        local mueble, asa = S.Mueble(clave, valor)
        if mueble then quiero[clave] = { mueble, asa } end
    end
    for clave, m in pairs(muebles) do
        local q = quiero[clave]
        if not q or q[1] ~= m.modelo or q[2] ~= m.modeloAsa or not m.ent or not DoesEntityExist(m.ent) then BorrarMueble(clave) end
    end
    local faltan = {}
    for clave, q in pairs(quiero) do
        local m = muebles[clave]
        if m then
            -- sigue valiendo: se vuelve a apuntar (la obra es la misma tabla) y a arrimar (la pared puede ser nueva)
            for _, ent in ipairs({ m.ent or 0, m.asa or 0 }) do
                if ent ~= 0 and DoesEntityExist(ent) then
                    o.claves[ent] = clave
                    Arrimar(o, clave, ent)
                end
            end
        else
            faltan[#faltan + 1] = { clave = clave, modelo = q[1], modeloAsa = q[2] }
        end
    end
    if #faltan == 0 then return end
    CreateThread(function()
        for _, f in ipairs(faltan) do
            local listo = CargarModelo(f.modelo)
            if esta ~= tanda or ObraActual() ~= o then return end
            if listo and not muebles[f.clave] and S.Mueble(f.clave, o.piezas[f.clave]) == f.modelo then
                local m = { modelo = f.modelo, modeloAsa = f.modeloAsa }
                local function crear(modelo)
                    local ent = CreateObjectNoOffset(modelo, o.o.x, o.o.y, o.o.z, false, false, false)
                    FreezeEntityPosition(ent, true)
                    o.claves[ent] = f.clave      -- para la cinta: mirar el mueble es mirar esa pieza
                    Arrimar(o, f.clave, ent)
                    return ent
                end
                m.ent = crear(f.modelo)
                if f.modeloAsa and CargarModelo(f.modeloAsa) then
                    if esta ~= tanda or ObraActual() ~= o then
                        DeleteEntity(m.ent)
                        o.claves[m.ent] = nil
                        return
                    end
                    m.asa = crear(f.modeloAsa)
                end
                muebles[f.clave] = m
                -- por si la pared se ha movido mientras cargaba
                local e = estados[f.clave]
                if e then Poner(o, f.clave, e, (Abertura(e))) end
            end
        end
    end)
end

-- Olvida el estado de un paso y deja su objeto (si sigue) en su sitio, cerrado
local function Soltar(clave)
    estados[clave], moviendo[clave] = nil, nil
    local o = ObraActual()
    local ent = o and o.objetos[clave]
    if ent and DoesEntityExist(ent) then
        local _, base, rumbo = Obra.Colocacion(clave, o.piezas[clave])
        if base then
            SetEntityCoordsNoOffset(ent, base.x, base.y, base.z, false, false, false)
            SetEntityRotation(ent, 0.0, 0.0, rumbo, 2, true)
            local m = muebles[clave]
            for _, otro in ipairs(m and { m.ent or 0, m.asa or 0 } or {}) do
                if otro ~= 0 and DoesEntityExist(otro) then Arrimar(o, clave, otro) end
            end
        end
    end
end

local function Sonar(o, clave, abrir)
    local s = type(S.sonido) == 'table' and S.sonido[abrir and 'abrir' or 'cerrar'] or nil
    if type(s) ~= 'table' or not s[1] then return end
    local _, base = Obra.Colocacion(clave, o.piezas[clave])
    if base then PlaySoundFromCoord(-1, s[1], base.x, base.y, base.z + 1.0, s[2], false, tonumber(S.sonido.alcance) or 12, false) end
end

-- Los pasos que hay en la casa y dónde están (se rehace cada vez que se monta la obra)
local function Repasar(o)
    lista = {}
    for clave, valor in pairs(o.piezas) do
        local estilo, _, tipo = S.Estilo(clave, valor)
        if estilo and not estilo.fijo then
            local _, base = Obra.Colocacion(clave, valor)
            if base then
                local t = clave:sub(1, 1)
                lista[#lista + 1] = { clave = clave, base = base, suelo = tipo == 'suelo', largo = t == 'x' and o.Y or o.X,
                    nombre = estilo.nombre, k = tonumber(clave:match(':(-?%d+)$')) or 0 }
            end
        end
    end
end

-- Todo en su sitio: lo llama la obra cada vez que se monta (un objeto recién
-- creado —un paso repintado— sale cerrado y hay que devolverlo a donde iba).
local function Recolocar(o)
    for clave, e in pairs(estados) do
        if o.piezas[clave] ~= e.valor then
            Soltar(clave)
        else
            local f, fin = Abertura(e)
            Poner(o, clave, e, f)
            if not fin then moviendo[clave] = true end
        end
    end
end

local function Recibir(clave, dato)
    return { valor = dato.valor, abierto = dato.abierto == true, modo = dato.modo, lado = tonumber(dato.lado) or 1,
        sentido = tonumber(dato.sentido) or 1, inicio = GetGameTimer() - (tonumber(dato.lleva) or 0),
        ms = S.Apertura(S.Estilo(clave, dato.valor)) }
end

AddEventHandler('origen_housing:obra:montada', function(id)
    id = tostring(id)
    local o = Obra.Actual()
    if not o or o.id ~= id then return end
    if casa ~= id then
        casa, estados, moviendo, puedo = id, {}, {}, false
        Repasar(o)
        Amueblar(o)
        -- la primera vez en esta casa: cómo están sus pasos y si se tiene llave
        CreateThread(function()
            local todos = lib.callback.await('origen_housing:secretos:estado', false, id)
            if casa ~= id then return end
            for clave, dato in pairs(type(todos) == 'table' and todos or {}) do
                if type(dato) == 'table' and not estados[clave] then estados[clave] = Recibir(clave, dato) end
            end
            local ahora = ObraActual()
            if ahora then Recolocar(ahora) end
            puedo = lib.callback.await('origen_housing:obra:puede', false, id) == true
        end)
        return
    end
    Repasar(o)
    Recolocar(o)
    Amueblar(o)
end)

AddEventHandler('origen_housing:obra:desmontada', function()
    casa, estados, moviendo, lista, gatillos, puedo = nil, {}, {}, {}, {}, false
    BorrarMuebles()
    Texto(nil)
end)

-- Una pieza que cambia (se quita, se sustituye, se deshace) vuelve a estar
-- cerrada; el servidor hace lo mismo con su cuenta (origen_housing:obra:cambiada).
AddEventHandler('origen_housing:obra:cambio', function(id, cam)
    if tostring(id) ~= casa or type(cam) ~= 'table' then return end
    for clave in pairs(cam.piezas or {}) do
        if estados[clave] then Soltar(clave) end
    end
end)

RegisterNetEvent('origen_housing:secretos:cambio', function(id, clave, dato)
    if tostring(id) ~= casa or type(clave) ~= 'string' then return end
    if type(dato) ~= 'table' then return Soltar(clave) end
    local e = Recibir(clave, dato)
    estados[clave], moviendo[clave] = e, true
    local o = ObraActual()
    if o then Sonar(o, clave, e.abierto) end
end)

-- Los que se mueven, cada fotograma
CreateThread(function()
    while true do
        local espera = 200
        local o = next(moviendo) and ObraActual() or nil
        if o then
            espera = 0
            for clave in pairs(moviendo) do
                local e = estados[clave]
                if not e then
                    moviendo[clave] = nil
                else
                    local f, fin = Abertura(e)
                    Poner(o, clave, e, f)
                    if fin then
                        moviendo[clave] = nil
                        if not e.abierto then estados[clave] = nil end      -- cerrado del todo: nada que recordar
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- ── La E ────────────────────────────────────────────────────────────────
-- El paso que se puede accionar ahora: a pie, pegado a él y mirando hacia él.
local function Elegido(o)
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end
    local yo = GetEntityCoords(ped)
    local d = yo - o.o
    local x, y, z = d.x * o.X.x + d.y * o.X.y, d.x * o.Y.x + d.y * o.Y.y, d.z
    local cam, rot = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local mejor, cuanto
    for _, p in ipairs(lista) do
        if S.Cerca(p.clave, x, y, z, S.radio) then
            local mirando, lejos
            if p.suelo then
                -- una trampilla: se mira hacia ella, desde arriba o desde abajo
                local v = p.base - cam
                lejos = #(vector3(yo.x - p.base.x, yo.y - p.base.y, 0.0))
                mirando = #v < 0.4 or (dir.x * v.x + dir.y * v.y + dir.z * v.z) / #v > 0.45
            else
                -- una pared: el punto de ella que queda más cerca, a la altura de los ojos
                local a = (yo.x - p.base.x) * p.largo.x + (yo.y - p.base.y) * p.largo.y
                a = math.max(-O.celda / 2, math.min(O.celda / 2, a))
                local q = p.base + p.largo * a
                local v = vector3(q.x - cam.x, q.y - cam.y, 0.0)
                local llano = vector3(dir.x, dir.y, 0.0)
                lejos = #(vector3(yo.x - q.x, yo.y - q.y, 0.0))
                mirando = #v < 0.3 or #llano < 0.05 or (llano.x * v.x + llano.y * v.y) / (#llano * #v) > 0.35
            end
            if mirando and (not cuanto or lejos < cuanto) then mejor, cuanto = p, lejos end
        end
    end
    return mejor
end

-- ── Los disparadores ────────────────────────────────────────────────────
-- Los muebles de la casa que son disparadores (se repasa cada segundo: los
-- muebles se ponen y se quitan sin avisar aquí)
CreateThread(function()
    while true do
        local nuevos = {}
        local house = casa and currentInteriorHouseID and House.get(currentInteriorHouseID) or nil
        if house and tostring(house.id) == casa then
            for mid, m in pairs(house.interiorFurniture or {}) do
                local _, g = S.Gatillo(type(m) == 'table' and m.model or nil)
                if g and m.entity and DoesEntityExist(m.entity) then
                    nuevos[#nuevos + 1] = { id = tostring(mid), entidad = m.entity, g = g }
                end
            end
        end
        gatillos = nuevos
        Wait(1000)
    end
end)

-- El gesto del mueble al usarlo (el libro se inclina, la palanca baja…): va y vuelve
RegisterNetEvent('origen_housing:secretos:gesto', function(id, mid)
    if tostring(id) ~= casa then return end
    for _, t in ipairs(gatillos) do
        local gesto = t.id == tostring(mid) and t.g.gesto or nil
        if gesto and not gestos[t.entidad] and DoesEntityExist(t.entidad) then
            local ent = t.entidad
            gestos[ent] = true
            CreateThread(function()
                local r0 = GetEntityRotation(ent, 2)
                local ms, t0 = math.max(100, tonumber(gesto.ms) or 700), GetGameTimer()
                while DoesEntityExist(ent) and GetGameTimer() - t0 < ms do
                    local a = (tonumber(gesto.grados) or 15.0) * math.sin(math.pi * (GetGameTimer() - t0) / ms)
                    SetEntityRotation(ent, r0.x + (gesto.eje == 'x' and a or 0.0), r0.y + (gesto.eje == 'y' and a or 0.0),
                        r0.z + (gesto.eje == 'z' and a or 0.0), 2, true)
                    Wait(0)
                end
                if DoesEntityExist(ent) then SetEntityRotation(ent, r0.x, r0.y, r0.z, 2, true) end
                gestos[ent] = nil
            end)
        end
    end
end)

-- El disparador que se puede usar ahora: a pie, a su lado y mirando hacia él
local function GatilloElegido()
    local ped = PlayerPedId()
    if GetVehiclePedIsIn(ped, false) ~= 0 then return nil end
    local yo = GetEntityCoords(ped)
    local cam, rot = GetFinalRenderedCamCoord(), GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local dir = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local mejor, cuanto
    for _, t in ipairs(gatillos) do
        if DoesEntityExist(t.entidad) then
            local q = GetEntityCoords(t.entidad)
            local lejos = #(vector3(yo.x - q.x, yo.y - q.y, 0.0))
            if lejos <= (t.g.radio or 1.4) and math.abs(yo.z - q.z) < 2.2 then
                local v = q - cam
                if (#v < 0.4 or (dir.x * v.x + dir.y * v.y + dir.z * v.z) / #v > 0.5) and (not cuanto or lejos < cuanto) then
                    mejor, cuanto = t, lejos
                end
            end
        end
    end
    return mejor
end

-- ── Menús y código ──────────────────────────────────────────────────────
-- El menú pequeño del servidor (org-menu); sin él, el de ox_lib.
--   opciones: { { texto, detalle, hacer } }
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
    lib.registerContext({ id = 'origen_housing_secretos', title = titulo, options = lineas })
    lib.showContext('origen_housing_secretos')
end

-- Pide un código (solo cifras). Devuelve el texto, o nil si se cancela.
local function PedirCodigo(titulo, texto)
    local dato
    if GetResourceState('org-input') == 'started' then
        local r = exports['org-input']:ShowInput({
            header = titulo, submitText = 'Aceptar', icon = 'fa-solid fa-lock',
            inputs = { { type = 'password', name = 'pin', text = texto, isRequired = true } },
        })
        dato = r and r.pin
    else
        local r = lib.inputDialog(titulo, { { type = 'input', label = texto, password = true, required = true } })
        dato = r and r[1]
    end
    if dato == nil then return nil end
    return (tostring(dato):gsub('%s', ''))
end

local function NombrePlanta(k)
    if k == 0 then return 'planta baja' end
    return k > 0 and ('planta ' .. k) or ('sótano ' .. -k)
end

-- El servidor pide el código de un paso (a quien no tiene llave). `remoto`:
-- el id del disparador desde el que se accionó, o false.
RegisterNetEvent('origen_housing:secretos:codigo', function(id, clave, remoto)
    if tostring(id) ~= casa or pidiendo or type(clave) ~= 'string' then return end
    pidiendo = true
    CreateThread(function()
        local pin = PedirCodigo('Código', ('De %d a %d cifras'):format(S.pin.min, S.pin.max))
        pidiendo = false
        if not pin or pin == '' or tostring(id) ~= casa then return end
        if type(remoto) == 'string' then
            TriggerServerEvent('origen_housing:secretos:gatillo', casa, remoto, pin)
        else
            TriggerServerEvent('origen_housing:secretos:accionar', casa, clave, pin)
        end
    end)
end)

RegisterNetEvent('origen_housing:secretos:dicho', function(texto, titulo)
    exports.origen_notify:Notify({ title = titulo or 'Paso secreto', description = tostring(texto), type = 'info', duration = 4500 })
end)

-- El menú del dueño junto a un paso
local function MenuPaso(p)
    local id = casa
    local d = lib.callback.await('origen_housing:secretos:ajustes', false, id, p.clave)
    if type(d) ~= 'table' or casa ~= id then return end
    local function ajustar(que, v) TriggerServerEvent('origen_housing:secretos:ajustar', id, p.clave, que, v) end
    local function codigo()
        CreateThread(function()
            local pin = PedirCodigo('Código del paso', ('De %d a %d cifras'):format(S.pin.min, S.pin.max))
            if not pin or casa ~= id then return end
            if not S.PinVale(pin) then
                return exports.origen_notify:Notify({ title = 'Paso secreto', type = 'error', duration = 4000,
                    description = ('El código son de %d a %d cifras'):format(S.pin.min, S.pin.max) })
            end
            ajustar('pin', pin)
        end)
    end
    local ops = {
        { texto = d.abierto and 'Cerrar' or 'Abrir', hacer = function() TriggerServerEvent('origen_housing:secretos:accionar', id, p.clave) end },
        { texto = d.pin and 'Cambiar el código' or 'Poner código', detalle = 'Se le pide a quien no tiene llave', hacer = codigo },
    }
    if d.pin then ops[#ops + 1] = { texto = 'Quitar el código', hacer = function() ajustar('pin', false) end } end
    -- el cierre automático va dando la vuelta por los que hay
    local siguiente = S.cierres[1]
    for n, seg in ipairs(S.cierres) do
        if seg == d.cierre then siguiente = S.cierres[n % #S.cierres + 1] end
    end
    ops[#ops + 1] = { texto = 'Cierre automático: ' .. (d.cierre > 0 and (d.cierre .. ' s') or 'no'),
        detalle = 'Pulsa para pasar a: ' .. (siguiente > 0 and (siguiente .. ' s') or 'no'), hacer = function() ajustar('cierre', siguiente) end }
    ops[#ops + 1] = { texto = 'Alarma silenciosa: ' .. (d.alarma and 'sí' or 'no'), detalle = 'Te avisa si lo abre alguien sin llave',
        hacer = function() ajustar('alarma', not d.alarma) end }
    if d.dentro then
        ops[#ops + 1] = { texto = d.cerrojo and 'Quitar el cerrojo' or 'Echar el cerrojo',
            detalle = 'Atrancado, desde fuera no lo abre nadie: ni con llave ni con código', hacer = function() ajustar('cerrojo', not d.cerrojo) end }
    else
        ops[#ops + 1] = { texto = 'Este lado es el de dentro', detalle = d.cerrojo and 'Ahora mismo está atrancado desde el otro lado'
            or 'Desde dentro se atranca y se sale sin código', hacer = function() ajustar('dentro', true) end }
    end
    Menu(d.nombre or p.nombre, 'Paso secreto', ops)
end

-- El menú del dueño junto a un disparador: a qué paso va
local function MenuGatillo(t)
    local id = casa
    local d = lib.callback.await('origen_housing:secretos:enlace', false, id, t.id)
    if type(d) ~= 'table' or casa ~= id then return end
    if #lista == 0 then
        return exports.origen_notify:Notify({ title = t.g.nombre or 'Disparador', type = 'info', duration = 4000,
            description = 'Esta casa aún no tiene ningún paso secreto: ponlo desde la cinta (Obra)' })
    end
    local aqui = DoesEntityExist(t.entidad) and GetEntityCoords(t.entidad) or GetEntityCoords(PlayerPedId())
    local orden = {}
    for _, p in ipairs(lista) do orden[#orden + 1] = { p = p, lejos = #(p.base - aqui) } end
    table.sort(orden, function(a, b) return a.lejos < b.lejos end)
    local ops = { { texto = 'El más cercano' .. (d.clave and '' or ' (ahora)'), detalle = 'Sin enlazar: acciona el paso que le quede más cerca',
        hacer = function() TriggerServerEvent('origen_housing:secretos:enlazar', id, t.id, false) end } }
    for n, q in ipairs(orden) do
        if n > 20 then break end
        local p = q.p
        ops[#ops + 1] = { texto = p.nombre .. (d.clave == p.clave and ' (ahora)' or ''),
            detalle = ('%s · a %d m'):format(NombrePlanta(p.k), math.floor(q.lejos + 0.5)),
            hacer = function() TriggerServerEvent('origen_housing:secretos:enlazar', id, t.id, p.clave) end }
    end
    Menu(t.g.nombre or 'Disparador', 'Qué paso acciona', ops)
end

-- ── La E y la G ─────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        local espera = 350
        local p, t = nil, nil
        if casa and (#lista > 0 or #gatillos > 0) and not menuAjeno and not pidiendo and (S.quien ~= 'llave' or puedo)
            and not (Furniture and Furniture.active) and not IsNuiFocused() and not IsPauseMenuActive() then
            local o = ObraActual()
            if o then
                espera = 100
                -- con un paso y un disparador a mano, el disparador (es más pequeño: si se le mira es a propósito)
                t = #gatillos > 0 and GatilloElegido() or nil
                p = not t and #lista > 0 and Elegido(o) or nil
            end
        end
        if p or t then
            -- (las teclas se miran en el árbitro: aquí se renueva la oferta unas veces por segundo)
            espera = 120
            local paso, gatillo, id = p, t, casa
            -- es secreto: el cartel solo lo ve quien diga la config. Sin cartel la E funciona
            -- igual, pero cede ante cualquier otra cosa que sí se anuncie (un interruptor al lado).
            local conCartel = S.cartel == 'todos' or (S.cartel == 'llave' and puedo)
            local e = paso and estados[paso.clave]
            local oferta = {
                texto = gatillo and 'Accionar' or (e and e.abierto and 'Cerrar' or 'Abrir'),
                oculto = not conCartel,
                prioridad = gatillo and 65 or 60, dist = 0.0,
                hacer = function()
                    if casa ~= id or GetGameTimer() - ultima <= S.ritmo then return end
                    ultima = GetGameTimer()
                    if gatillo then
                        TriggerServerEvent('origen_housing:secretos:gatillo', id, gatillo.id)
                    else
                        TriggerServerEvent('origen_housing:secretos:accionar', id, paso.clave)
                    end
                end,
            }
            -- la G: al dueño, su menú; a los demás junto a un paso, el cerrojo (que solo hace algo desde dentro)
            if puedo or paso then
                oferta.g = {
                    -- (a quien no tiene llave no se le anuncia: la G le funciona, sin cartel)
                    texto = puedo and (gatillo and 'Enlazar' or 'Ajustes') or nil,
                    hacer = function()
                        if casa ~= id or pidiendo or GetGameTimer() - ultima <= S.ritmo then return end
                        ultima = GetGameTimer()
                        if puedo then
                            pidiendo = true
                            local ok, err = pcall(function()
                                if gatillo then MenuGatillo(gatillo) else MenuPaso(paso) end
                            end)
                            pidiendo = false
                            if not ok then error(err, 0) end
                        elseif paso then
                            TriggerServerEvent('origen_housing:secretos:ajustar', id, paso.clave, 'cerrojo', 'cambia')
                        end
                    end,
                }
            end
            Tecla.Ofrecer('secretos', oferta)
        else
            Texto(nil)
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Texto(nil)
    BorrarMuebles()
end)
