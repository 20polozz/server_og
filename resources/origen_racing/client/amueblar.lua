-- ========================================
-- CLIENTE: AMUEBLAR UN CIRCUITO
-- ========================================
--[[ El editor del lobby y de los potenciadores, hecho como el de muebles de
     origen_housing: un menu lateral con el catalogo, el raton sobre el mundo
     para colocar y el gizmo para mover y girar lo ya colocado.

       · Se elige una pieza del catalogo y sigue al raton; clic la coloca
         (y se sigue colocando la misma), la rueda la gira, ESC la suelta.
       · Sin pieza elegida, clic sobre un mueble lo coge con el gizmo:
         R cambia entre mover y girar, ALT lo posa en el suelo, ENTER acaba,
         SUPR lo borra.
       · Boton derecho mantenido: mirar alrededor. WASD: andar, como siempre.

     La interfaz es ui-vue/src/components/admin/AmueblarPanel.vue. Lo que se
     coloca se guarda en racing_circuits.extras (server/modos.lua) y es lo que
     luego pinta client/modos.lua. ]]

Amueblar = {}

local activo = false
local circuitId, circuitNombre = nil, nil
local extras = { muebles = {}, plazas = {}, items = {} }
local objetos = {}            -- entidad de cada mueble, en el mismo orden que extras.muebles
local catalogo = {}           -- Config.Lobby.Catalogo sin lo que el juego no tenga
local porModelo = {}          -- model -> label

local pieza = nil             -- lo que se esta colocando: { tipo = 'mueble'|'plaza'|'item', id = model|tipo }
local giro = 0.0
local raton = { x = 0.5, y = 0.5 }
local mirando = false         -- boton derecho: el raton mueve la camara
local fantasma, fantasmaModelo = nil, nil
local encima = nil            -- indice del mueble bajo el raton
local gizmo = nil             -- { i = indice, antes = { pos, rot } } mientras el gizmo tiene un mueble

-- ── Utilidades ───────────────────────────────────────────────────────────────

local function quitarFantasma()
    if fantasma and DoesEntityExist(fantasma) then DeleteEntity(fantasma) end
    fantasma, fantasmaModelo = nil, nil
end

local function resaltar(i)
    if encima == i then return end
    if encima and objetos[encima] and DoesEntityExist(objetos[encima]) then
        SetEntityDrawOutline(objetos[encima], false)
    end
    encima = i
    if i and objetos[i] and DoesEntityExist(objetos[i]) then
        SetEntityDrawOutlineColor(216, 27, 85, 255)
        SetEntityDrawOutline(objetos[i], true)
    end
end

--- Del raton (0..1 en la pantalla) al mundo: el rayo que sale de la camara
--- por ese punto. Devuelve si ha dado, donde y contra que entidad.
local function rayoDelRaton(flags, ignorar)
    local cam = GetFinalRenderedCamCoord()
    local rot = GetFinalRenderedCamRot(2)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)

    local delante = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local derecha = vector3(math.cos(rz), math.sin(rz), 0.0)
    local arriba = vector3(math.sin(rz) * math.sin(rx), -math.cos(rz) * math.sin(rx), math.cos(rx))

    local t = math.tan(math.rad(GetFinalRenderedCamFov()) / 2.0)
    local dir = delante
        + derecha * (t * GetAspectRatio(false) * (raton.x * 2.0 - 1.0))
        + arriba * (t * (1.0 - raton.y * 2.0))

    local hasta = cam + dir * 180.0
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, hasta.x, hasta.y, hasta.z, flags, ignorar or PlayerPedId(), 4)
    local _, dio, donde, _, entidad = GetShapeTestResult(rayo)
    return dio == 1 or dio == true, donde, entidad
end

local function etiqueta(m) return porModelo[m] or m end

--- La lista de lo colocado, para el menu.
local function mandarLista()
    local muebles = {}
    for i, m in ipairs(extras.muebles) do
        muebles[i] = { i = i, label = etiqueta(m.m) }
    end
    local items = {}
    for i, it in ipairs(extras.items) do
        items[i] = { i = i, label = (Config.Arcade.Tipos[it.t] or {}).label or it.t, t = it.t }
    end
    SendNUIMessage({ action = 'amueblar:lista', data = {
        muebles = muebles, plazas = #extras.plazas, items = items,
        cogido = gizmo and gizmo.i or nil,
    } })
end

--- Los que flotan (la caja de luz): PlaceObjectOnGroundProperly baja el modelo
--- hasta que su punto mas bajo toca el suelo y los dejaba pegados a el. Su
--- origen ya va en el suelo: se quedan como estan.
local function flota(modelo)
    return type(modelo) == 'string' and modelo:find('^ocar_luzcaja') ~= nil
end

local function ponerFantasma(modelo, x, y, z)
    if fantasmaModelo ~= modelo then
        quitarFantasma()
        local hash = Lobby.CargarModelo(modelo)
        if not hash then return end
        fantasma = CreateObjectNoOffset(hash, x, y, z, false, false, false)
        if not fantasma or fantasma == 0 then fantasma = nil return end
        fantasmaModelo = modelo
        SetEntityAlpha(fantasma, 170, false)
        SetEntityCollision(fantasma, false, false)
        FreezeEntityPosition(fantasma, true)
        SetModelAsNoLongerNeeded(hash)
    end
    SetEntityCoordsNoOffset(fantasma, x, y, z, false, false, false)
    SetEntityHeading(fantasma, giro)
    if not flota(modelo) then PlaceObjectOnGroundProperly(fantasma) end
end

local function leerMueble(obj, modelo)
    local c = GetEntityCoords(obj)
    local r = GetEntityRotation(obj, 2)
    return { m = modelo, x = c.x, y = c.y, z = c.z, h = r.z, rx = r.x, ry = r.y }
end

-- ── El gizmo (ui/gizmo.js, el de origen_housing) ─────────────────────────────

local function soltarGizmo(deshacer)
    if not gizmo then return end
    local i = gizmo.i
    local obj = objetos[i]

    if obj and DoesEntityExist(obj) then
        if deshacer then
            SetEntityCoordsNoOffset(obj, gizmo.antes.pos.x, gizmo.antes.pos.y, gizmo.antes.pos.z, false, false, false)
            SetEntityRotation(obj, gizmo.antes.rot.x, gizmo.antes.rot.y, gizmo.antes.rot.z, 2, true)
        elseif extras.muebles[i] then
            extras.muebles[i] = leerMueble(obj, extras.muebles[i].m)
        end
        SetEntityCollision(obj, true, true)
        SetEntityDrawOutline(obj, false)
    end

    gizmo = nil
    SendNUIMessage({ action = 'setGizmoEntity', data = { handle = nil } })
    SendNUIMessage({ action = 'toggleState', data = { state = false } })
    SendNUIMessage({ action = 'amueblar:gizmo', data = { activo = false } })
    mandarLista()
end

local function cogerConGizmo(i)
    local obj = objetos[i]
    if not obj or not DoesEntityExist(obj) then return end
    if gizmo then soltarGizmo(false) end

    pieza = nil
    quitarFantasma()
    resaltar(nil)

    gizmo = { i = i, antes = { pos = GetEntityCoords(obj), rot = GetEntityRotation(obj, 2) } }
    SetEntityCollision(obj, false, false)   -- que el rayo y el piloto no choquen con lo que se mueve
    SetEntityDrawOutlineColor(216, 27, 85, 255)
    SetEntityDrawOutline(obj, true)

    SendNUIMessage({ action = 'toggleState', data = { state = true } })
    SendNUIMessage({ action = 'setGizmoEntity', data = {
        handle = obj, position = GetEntityCoords(obj), rotation = GetEntityRotation(obj),
    } })
    SendNUIMessage({ action = 'amueblar:gizmo', data = { activo = true } })
    SendNUIMessage({ action = 'amueblar:pieza', data = nil })
    mandarLista()
end

RegisterNUICallback('moveEntity', function(data, cb)
    cb('ok')
    if not gizmo or data.handle ~= objetos[gizmo.i] then return end
    local p, r = data.position, data.rotation
    SetEntityCoordsNoOffset(data.handle, p.x + 0.0, p.y + 0.0, p.z + 0.0, false, false, false)
    SetEntityRotation(data.handle, r.x + 0.0, r.y + 0.0, r.z + 0.0)
end)

RegisterNUICallback('placeOnGround', function(data, cb)
    local obj = gizmo and objetos[gizmo.i]
    if not obj or not DoesEntityExist(obj) then return cb(json.encode({ position = { x = 0, y = 0, z = 0 }, rotation = { x = 0, y = 0, z = 0 } })) end
    if not flota(extras.muebles[gizmo.i] and extras.muebles[gizmo.i].m) then PlaceObjectOnGroundProperly(obj) end
    cb(json.encode({ position = GetEntityCoords(obj), rotation = GetEntityRotation(obj) }))
end)

RegisterNUICallback('finishEdit', function(_, cb) cb('ok') soltarGizmo(false) end)
RegisterNUICallback('cancelEdit', function(_, cb) cb('ok') soltarGizmo(true) end)
RegisterNUICallback('swapMode', function(_, cb) cb('ok') end)

-- ── Lo que manda el menu ─────────────────────────────────────────────────────

RegisterNUICallback('amueblar:raton', function(data, cb)
    cb('ok')
    raton.x = tonumber(data.x) or raton.x
    raton.y = tonumber(data.y) or raton.y
end)

RegisterNUICallback('amueblar:mirar', function(data, cb)
    cb('ok')
    mirando = data.on == true
end)

RegisterNUICallback('amueblar:girar', function(data, cb)
    cb('ok')
    local paso = data.fino and 1.0 or 7.5
    giro = (giro + (tonumber(data.d) or 0) * paso) % 360.0
end)

--- Elegir pieza del catalogo (o ninguna).
RegisterNUICallback('amueblar:pieza', function(data, cb)
    cb('ok')
    if not activo then return end
    if gizmo then soltarGizmo(false) end
    quitarFantasma()
    resaltar(nil)
    if type(data) == 'table' and data.tipo and data.id then
        pieza = { tipo = data.tipo, id = data.id }
    else
        pieza = nil
    end
end)

local function avisoLleno()
    PlaySoundFrontend(-1, 'ERROR', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    lib.notify({ title = 'Racing', description = 'No cabe más de esto en el circuito', type = 'error' })
end

--- Clic sobre el mundo.
RegisterNUICallback('amueblar:clic', function(_, cb)
    cb('ok')
    if not activo or gizmo then return end

    if not pieza then
        if encima then cogerConGizmo(encima) end
        return
    end

    local dio, punto = rayoDelRaton(17, fantasma)
    if not dio then return end

    if pieza.tipo == 'mueble' then
        if #extras.muebles >= Config.Lobby.MaxMuebles then return avisoLleno() end
        if not fantasma then return end
        local m = leerMueble(fantasma, pieza.id)
        local obj = Lobby.PonerMueble(m)
        if not obj then return end
        extras.muebles[#extras.muebles + 1] = m
        objetos[#objetos + 1] = obj
    elseif pieza.tipo == 'plaza' then
        if #extras.plazas >= Config.Lobby.MaxPlazas then return avisoLleno() end
        extras.plazas[#extras.plazas + 1] = { x = punto.x, y = punto.y, z = punto.z, h = giro }
    elseif pieza.tipo == 'item' then
        if #extras.items >= Config.Lobby.MaxItems then return avisoLleno() end
        extras.items[#extras.items + 1] = { t = pieza.id, x = punto.x, y = punto.y, z = punto.z + 0.5 }
    end

    PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    mandarLista()
end)

--- Coger con el gizmo un mueble de la lista.
RegisterNUICallback('amueblar:coger', function(data, cb)
    cb('ok')
    if activo then cogerConGizmo(tonumber(data.i)) end
end)

RegisterNUICallback('amueblar:borrar', function(data, cb)
    cb('ok')
    if not activo then return end
    local i = tonumber(data.i)

    if data.tipo == 'mueble' then
        -- Sin indice: el que tiene el gizmo.
        if not i and gizmo then i = gizmo.i end
        if not i or not extras.muebles[i] then return end
        if gizmo then soltarGizmo(false) end
        resaltar(nil)
        table.remove(extras.muebles, i)
        local obj = table.remove(objetos, i)
        if obj and DoesEntityExist(obj) then DeleteEntity(obj) end
    elseif data.tipo == 'plaza' then
        table.remove(extras.plazas)          -- la ultima
    elseif data.tipo == 'item' and i then
        table.remove(extras.items, i)
    end

    PlaySoundFrontend(-1, 'CANCEL', 'HUD_FREEMODE_SOUNDSET', true)
    mandarLista()
end)

-- ── Entrar y salir ───────────────────────────────────────────────────────────

local function cerrar()
    if not activo then return end
    activo = false
    if gizmo then soltarGizmo(false) end
    quitarFantasma()
    resaltar(nil)
    for _, obj in ipairs(objetos) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    objetos = {}
    pieza = nil
    mirando = false

    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'amueblar:cerrar' })
    Lobby.Pausar(false)
end

RegisterNUICallback('amueblar:guardar', function(_, cb)
    if not activo then return cb({ success = false }) end
    if gizmo then soltarGizmo(false) end

    local ok, r = pcall(lib.callback.await, 'racing:admin:saveExtras', false, {
        circuitId = circuitId,
        muebles = extras.muebles, plazas = extras.plazas, items = extras.items,
    })
    if not ok then r = nil end
    if r and r.success then
        lib.notify({
            title = 'Circuito amueblado',
            description = ('%d muebles · %d plazas · %d potenciadores'):format(r.muebles or 0, r.plazas or 0, r.items or 0),
            type = 'success', duration = 5000,
        })
        cb({ success = true })
        cerrar()
    else
        lib.notify({ title = 'Racing', description = (r and r.message) or 'No se ha podido guardar', type = 'error' })
        cb({ success = false })
    end
end)

RegisterNUICallback('amueblar:salir', function(_, cb)
    cb('ok')
    cerrar()
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza con el editor delante, el editor se cierra con el: si no, se
     quedaba pintado sin raton, con los muebles a medio poner y `activo` en
     true (y no se podia volver a entrar). ]]
OrigenFoco.AlSoltar(function()
    if activo then cerrar() end
end)

-- El bucle: lo que hay que hacer cada fotograma mientras se amuebla.
local function bucle()
    -- Con el menu delante el juego sigue recibiendo teclas (se puede andar y
    -- conducir); lo que no puede recibir es el raton, salvo para mirar.
    local QUIETOS = { 24, 25, 14, 15, 16, 17, 37, 44, 140, 141, 142, 257, 199, 200, 322, 18, 191, 201, 68, 69, 70, 91, 92, 114, 99, 100 }

    while activo do
        Wait(0)

        for _, c in ipairs(QUIETOS) do DisableControlAction(0, c, true) end
        if not mirando then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
        end

        -- Lo que no es un objeto: plazas y potenciadores
        for _, p in ipairs(extras.plazas) do Lobby.PintarPlaza(p) end
        for _, it in ipairs(extras.items) do Modos.PintarItem(it.t, it.x, it.y, it.z, false) end

        if gizmo then
            SendNUIMessage({ action = 'setCameraPosition', data = {
                position = GetFinalRenderedCamCoord(), rotation = GetFinalRenderedCamRot(),
            } })
        elseif not mirando then
            if pieza then
                local dio, punto = rayoDelRaton(17, fantasma)
                if dio then
                    if pieza.tipo == 'mueble' then
                        ponerFantasma(pieza.id, punto.x, punto.y, punto.z)
                    elseif pieza.tipo == 'plaza' then
                        Lobby.PintarPlaza({ x = punto.x, y = punto.y, z = punto.z, h = giro }, 220, 221, 224)   -- pieza pegatina
                    elseif pieza.tipo == 'item' then
                        Modos.PintarItem(pieza.id, punto.x, punto.y, punto.z + 0.5, false)
                    end
                end
            else
                -- Sin pieza: que mueble hay bajo el raton
                local dio, _, entidad = rayoDelRaton(16)
                local i = nil
                if dio and entidad and entidad ~= 0 then
                    for k, obj in ipairs(objetos) do
                        if obj == entidad then i = k break end
                    end
                end
                resaltar(i)
            end
        end
    end
end

function Amueblar.Activo() return activo end

function Amueblar.Empezar(id, nombre)
    if activo then return end

    local ok, r = pcall(lib.callback.await, 'racing:admin:getExtras', false, id)
    if not ok then r = nil end
    if not r or not r.success then
        lib.notify({ title = 'Racing', description = 'No se ha podido abrir el circuito', type = 'error' })
        return
    end

    circuitId, circuitNombre = id, nombre
    extras = {
        muebles = r.extras.muebles or {},
        plazas  = r.extras.plazas or {},
        items   = r.extras.items or {},
    }

    -- El catalogo, sin lo que este juego no tenga.
    catalogo, porModelo = {}, {}
    for _, c in ipairs(Config.Lobby.Catalogo) do
        if IsModelInCdimage(joaat(c.model)) then
            catalogo[#catalogo + 1] = { tipo = 'mueble', id = c.model, label = c.label, cat = c.cat }
            porModelo[c.model] = c.label
        else
            print(('^3[Racing]^7 Amueblar: el modelo %s no existe en este juego, se salta'):format(c.model))
        end
    end
    local tipos = {}
    for _, t in ipairs(Config.Arcade.Orden) do
        tipos[#tipos + 1] = { tipo = 'item', id = t, label = Config.Arcade.Tipos[t].label, cat = 'potenciadores' }
    end

    pieza, giro, mirando, gizmo, encima = nil, 0.0, false, nil, nil
    activo = true
    Lobby.Pausar(true)

    -- Lo que ya habia, a la vista y editable.
    objetos = {}
    for i, m in ipairs(extras.muebles) do
        objetos[i] = Lobby.PonerMueble(m) or 0
    end

    if r.salida then
        local d = #(GetEntityCoords(PlayerPedId()) - vector3(r.salida.coord_x, r.salida.coord_y, r.salida.coord_z))
        if d > 60.0 then
            SetNewWaypoint(r.salida.coord_x + 0.0, r.salida.coord_y + 0.0)
            lib.notify({
                title = 'Amueblar',
                description = ('La salida está a %d m: te la he marcado en el GPS'):format(math.floor(d)),
                type = 'inform', duration = 7000,
            })
        end
    end

    SendNUIMessage({ action = 'amueblar:abrir', data = {
        nombre = circuitNombre or 'Circuito',
        categorias = Config.Lobby.Categorias,
        catalogo = catalogo,
        potenciadores = tipos,
        limites = { muebles = Config.Lobby.MaxMuebles, plazas = Config.Lobby.MaxPlazas, items = Config.Lobby.MaxItems },
    } })
    mandarLista()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    CreateThread(bucle)
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() or not activo then return end
    quitarFantasma()
    for _, obj in ipairs(objetos) do
        if DoesEntityExist(obj) then DeleteEntity(obj) end
    end
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end)
