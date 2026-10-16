--[[ El panel de admin de las tiendas de tatuajes (/tattooconfig o la tarjeta
     de la pestaña Scripts de origen_admin), a pantalla completa.

     Desde el se sale al juego a dos cosas, y se vuelve solo:
       MOVER un punto   un doble tuyo hace de cliente y el tatuador de la
                        tienda hace de tatuador, cada uno en su sitio, y el
                        que se mueve sigue las teclas. Asi se ve como queda
                        antes de guardar.
       VISTA PREVIA     la escena entera montada, con la camara que vera el
                        jugador mientras le tatuan.

     Las instrucciones van en la barra de teclas de abajo (origen_hud), y
     mientras tanto no queda nada del panel en pantalla. ]]

TiendasGuardadas = {}        -- [id] = la fila tal como la manda el servidor

local panel = false
local desdeElHub = false     -- se abrio desde la pestaña Scripts del panel de admin
local enElJuego = false      -- moviendo un punto o en la vista previa
local sobrantes = {}         -- entidades de la escena, por si el recurso se para

local NOMBRES = {
    entrada = 'Entrada',
    silla = 'Camino a la camilla',
    cliente = 'Cliente tumbado',
    espera = 'Tatuador en espera',
    tatuando = 'Tatuador tatuando',
}

local function Aviso(texto, tipo)
    TriggerEvent('origen_notify:client:Notify', tipo or 'info', 'Tatuajes', texto)
end

-- ---------------------------------------------------------------------------
--  La escena: el doble y el tatuador
-- ---------------------------------------------------------------------------

local function Apuntar(e)
    sobrantes[#sobrantes + 1] = e
    return e
end

local function Limpiar()
    for _, e in ipairs(sobrantes) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    sobrantes = {}
end

local function Preparar(ped)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityCollision(ped, false, false)
    return Apuntar(ped)
end

local function CrearDoble()
    local doble = ClonePed(PlayerPedId(), false, false, true)
    SetEntityAlpha(doble, 225, false)
    return Preparar(doble)
end

local function CrearTatuador(modelo)
    local hash = joaat(modelo)
    if not IsModelInCdimage(hash) or not IsModelAPed(hash) then hash = joaat(Config.ModeloTatuador) end
    RequestModel(hash)
    local n = 0
    while not HasModelLoaded(hash) and n < 100 do Wait(50) n = n + 1 end
    if not HasModelLoaded(hash) then return nil end
    local ped = CreatePed(4, hash, 0.0, 0.0, 0.0, 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    return Preparar(ped)
end

local function Animar(ped, cual)
    local a = Config.Anim[cual]
    LoadDict(a.dict)
    TaskPlayAnim(ped, a.dict, a.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
end

--- Los mismos sitios y las mismas cuentas que usa la tienda de verdad
--- (SetupTattooShop y StartNPCSequence): el cliente va tal cual, y al
--- tatuador se le resta el metro.
local function Colocar(ped, cual, p)
    if not ped or not DoesEntityExist(ped) then return end
    local z = (cual == 'cliente') and p.z or (p.z - 1.0)
    SetEntityCoords(ped, p.x + 0.0, p.y + 0.0, z + 0.0, false, false, false, false)
    SetEntityHeading(ped, (p.h or 0.0) + 0.0)
end

local function DarMaquina(tatuador)
    local i = Config.Prop
    local hash = joaat(i.model)
    RequestModel(hash)
    local n = 0
    while not HasModelLoaded(hash) and n < 60 do Wait(50) n = n + 1 end
    if not HasModelLoaded(hash) then return nil end
    local c = GetEntityCoords(tatuador)
    local prop = CreateObject(hash, c.x, c.y, c.z + 0.2, false, true, true)
    AttachEntityToEntity(prop, tatuador, GetPedBoneIndex(tatuador, i.bone), i.xPos, i.yPos, i.zPos, i.xRot, i.yRot, i.zRot, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
    return Apuntar(prop)
end

--- Monta la escena de una tienda. `donde` dice en cual de sus dos sitios va
--- el tatuador ('tatuando' o 'espera').
local function Escena(t, donde)
    local e = { doble = CrearDoble(), tatuador = CrearTatuador(t.modelo) }
    Colocar(e.doble, 'cliente', t.puntos.cliente)
    Animar(e.doble, 'cliente')
    if e.tatuador then
        Colocar(e.tatuador, donde, t.puntos[donde])
        Animar(e.tatuador, donde)
        if donde == 'tatuando' then e.maquina = DarMaquina(e.tatuador) end
        SetEntityNoCollisionEntity(e.tatuador, e.doble, false)
    end
    return e
end

--- El tatuador de verdad de la tienda estorba: estaria de pie donde se prueba.
local function EsconderElDeVerdad(id, fuera)
    local npc = createdNpcs[id]
    if npc and DoesEntityExist(npc) then SetEntityVisible(npc, not fuera, false) end
end

local function Marca(p, r, g, b, conRumbo)
    DrawMarker(1, p.x, p.y, p.z - 0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.25, r, g, b, 170, false, false, 2, false, nil, nil, false)
    if conRumbo and p.h then
        local a = math.rad(p.h)
        DrawLine(p.x, p.y, p.z - 0.7, p.x - math.sin(a) * 0.8, p.y + math.cos(a) * 0.8, p.z - 0.7, r, g, b, 255)
    end
end

--- A donde mira la camara: el suelo o lo que haya delante, hasta 15 m.
local function Apuntado()
    local c, r = GetGameplayCamCoord(), GetGameplayCamRot(2)
    local rx, rz = math.rad(r.x), math.rad(r.z)
    local d = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local f = c + d * 15.0
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(c.x, c.y, c.z, f.x, f.y, f.z, 17, PlayerPedId(), 7)
    local _, dio, donde = GetShapeTestResult(rayo)
    if dio == 1 then return donde end
end

-- Lo que se le quita al jugador mientras coloca: las teclas que se usan aqui.
local TECLAS = { 14, 15, 16, 17, 24, 25, 26, 37, 38, 44, 47, 73, 140, 141, 142, 172, 173, 174, 175, 10, 11, 45 }

local function Pulsa(c) return IsDisabledControlJustPressed(0, c) end

-- ---------------------------------------------------------------------------
--  Mover un punto
-- ---------------------------------------------------------------------------

--- Devuelve el punto nuevo, o nil si se sale sin guardar.
local function MoverPunto(t, cual)
    local P = { x = t.puntos[cual].x + 0.0, y = t.puntos[cual].y + 0.0, z = t.puntos[cual].z + 0.0, h = (t.puntos[cual].h or 0.0) + 0.0 }
    local conRumbo = cual ~= 'entrada'

    local escena = Escena(t, cual == 'espera' and 'espera' or 'tatuando')
    local movido = (cual == 'cliente' and escena.doble) or ((cual == 'tatuando' or cual == 'espera') and escena.tatuador) or nil
    -- Donde apunta la mira es suelo: el cliente se guarda a ras, el resto a un metro.
    local alza = (cual == 'cliente') and 0.0 or 1.0
    local libre = false

    local function Controles()
        local lista = { { key = 'Moviendo', text = NOMBRES[cual] } }
        lista[#lista + 1] = { key = 'G', text = libre and 'Fijar aquí y afinar' or 'Llevarlo a donde miro' }
        if not libre then lista[#lista + 1] = { key = '←↑↓→', text = 'Mover 1 cm' } end
        lista[#lista + 1] = { key = 'RePág/AvPág', text = 'Subir / bajar' }
        if conRumbo then lista[#lista + 1] = { key = 'Rueda', text = 'Girar' } end
        lista[#lista + 1] = { key = 'Shift', text = 'Pasos grandes' }
        lista[#lista + 1] = { key = 'E', text = 'Guardar' }
        lista[#lista + 1] = { key = 'X', text = 'Salir sin guardar' }
        pcall(function() exports.origen_hud:setupControls(lista) end)
    end
    Controles()

    local resultado = nil
    while true do
        Wait(0)
        for _, c in ipairs(TECLAS) do DisableControlAction(0, c, true) end

        local grande = IsControlPressed(0, 21) or IsDisabledControlPressed(0, 21)
        local paso = grande and 0.05 or 0.01
        local giro = grande and 15.0 or 2.0
        local sucio = false

        if Pulsa(47) then
            libre = not libre
            Controles()
        end

        if libre then
            local donde = Apuntado()
            if donde then
                P.x, P.y, P.z = donde.x, donde.y, donde.z + alza
                sucio = true
            end
        else
            -- Las flechas, respecto de la camara: arriba es alejar, derecha es derecha.
            local rz = math.rad(GetGameplayCamRot(2).z)
            local ax, ay = -math.sin(rz), math.cos(rz)
            if Pulsa(172) then P.x, P.y, sucio = P.x + ax * paso, P.y + ay * paso, true end
            if Pulsa(173) then P.x, P.y, sucio = P.x - ax * paso, P.y - ay * paso, true end
            if Pulsa(175) then P.x, P.y, sucio = P.x + ay * paso, P.y - ax * paso, true end
            if Pulsa(174) then P.x, P.y, sucio = P.x - ay * paso, P.y + ax * paso, true end
        end

        if Pulsa(10) then P.z, sucio = P.z + paso, true end
        if Pulsa(11) then P.z, sucio = P.z - paso, true end
        if conRumbo then
            if Pulsa(15) or Pulsa(17) then P.h, sucio = (P.h + giro) % 360, true end
            if Pulsa(14) or Pulsa(16) then P.h, sucio = (P.h - giro) % 360, true end
        end

        if sucio and movido then Colocar(movido, cual, P) end

        -- Los puntos que no tienen figura, y el que se mueve en rosa.
        for _, c in ipairs({ 'entrada', 'silla', 'espera' }) do
            if c == cual then
                Marca(P, 216, 27, 85, c ~= 'entrada')
            else
                Marca(t.puntos[c], 235, 235, 235, c ~= 'entrada')
            end
        end

        if Pulsa(38) then resultado = P break end
        if Pulsa(73) then break end
    end

    pcall(function() exports.origen_hud:hideControls() end)
    Limpiar()
    return resultado
end

-- ---------------------------------------------------------------------------
--  La vista previa
-- ---------------------------------------------------------------------------

local function VistaPrevia(t)
    local donde = 'tatuando'
    local escena = Escena(t, donde)
    local camara = nil

    local function Controles()
        pcall(function() exports.origen_hud:setupControls({
            { key = 'Vista previa', text = t.nombre },
            { key = 'C', text = camara and 'Volver a mi vista' or 'La cámara del jugador' },
            { key = 'R', text = donde == 'tatuando' and 'Ver al tatuador en espera' or 'Ver al tatuador tatuando' },
            { key = 'X', text = 'Volver al panel' },
        }) end)
    end

    local function QuitarCamara()
        if not camara then return end
        RenderScriptCams(false, true, 400, true, true)
        DestroyCam(camara, false)
        camara = nil
    end

    --- La misma que ve el jugador en la camilla: Config.Cameras.tattoo, medida
    --- desde el cliente.
    local function PonerCamara()
        local desde, hacia = table.unpack(Config.Cameras['tattoo'])
        local c = GetOffsetFromEntityInWorldCoords(escena.doble, desde.x, desde.y, desde.z)
        local m = GetOffsetFromEntityInWorldCoords(escena.doble, hacia.x, hacia.y, hacia.z)
        camara = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', c.x, c.y, c.z, 0.0, 0.0, 0.0, 49.0, false, 0)
        PointCamAtCoord(camara, m.x, m.y, m.z)
        SetCamActive(camara, true)
        RenderScriptCams(true, true, 400, true, true)
    end

    Controles()
    while true do
        Wait(0)
        for _, c in ipairs(TECLAS) do DisableControlAction(0, c, true) end

        if Pulsa(26) then
            if camara then QuitarCamara() else PonerCamara() end
            Controles()
        end

        if Pulsa(45) and escena.tatuador then
            donde = (donde == 'tatuando') and 'espera' or 'tatuando'
            if escena.maquina and DoesEntityExist(escena.maquina) then DeleteEntity(escena.maquina) end
            escena.maquina = nil
            ClearPedTasksImmediately(escena.tatuador)
            Colocar(escena.tatuador, donde, t.puntos[donde])
            Animar(escena.tatuador, donde)
            if donde == 'tatuando' then escena.maquina = DarMaquina(escena.tatuador) end
            Controles()
        end

        if not camara then
            Marca(t.puntos.entrada, 216, 27, 85, false)
            Marca(t.puntos.silla, 235, 235, 235, true)
            if donde ~= 'espera' then Marca(t.puntos.espera, 235, 235, 235, true) end
        end

        if Pulsa(73) then break end
    end

    QuitarCamara()
    pcall(function() exports.origen_hud:hideControls() end)
    Limpiar()
end

-- ---------------------------------------------------------------------------
--  El panel
-- ---------------------------------------------------------------------------

local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

local function Datos()
    local yo = GetEntityCoords(PlayerPedId())
    local lista = {}
    for _, t in pairs(TiendasGuardadas) do
        local e = t.puntos.entrada
        lista[#lista + 1] = {
            id = t.id, nombre = t.nombre, blip = t.blip, modelo = t.modelo, puntos = t.puntos,
            dist = #(yo - vector3(e.x, e.y, e.z)),
        }
    end
    table.sort(lista, function(a, b) return a.id < b.id end)
    return { tiendas = lista, radio = Config.RadioTienda, tope = Config.TopeTiendas, comando = Config.Comando }
end

--- `seccion`: en cual se abre (de vuelta de ver tatuajes, en «tatuajes»).
local function AbrirPanel(tienda, tarde, seccion)
    if panel then return end
    panel = true
    HudFuera(true)
    SendNUIMessage({ action = 'admin:abrir', datos = Datos(), tienda = tienda, seccion = seccion })
    if tarde then
        -- Desde la pestaña Scripts: el panel de admin tarda en soltar el raton.
        CreateThread(function()
            Wait(2800)
            if panel then SetNuiFocus(true, true) end
        end)
    else
        SetNuiFocus(true, true)
    end
end

--- `sigue`: no es un cierre de verdad, se sale al juego a colocar algo y se
--- vuelve. Solo el cierre de verdad devuelve al panel de admin.
local function CerrarPanel(sigue)
    if not panel then return end
    panel = false

    SetNuiFocus(false, false)             -- primero, siempre
    HudFuera(false)

    SetTimeout(280, function()            -- 280 > los 260 de la transicion
        if not panel then SendNUIMessage({ action = 'admin:cerrar' }) end
    end)

    if desdeElHub and not sigue then
        desdeElHub = false
        if GetResourceState('origen_admin') == 'started' then
            exports['origen_admin']:ReturnToScripts()
        end
    end
end

--- Lo llama main.lua cada vez que el servidor reparte las tiendas.
function AdminTiendasCambiadas()
    if panel then SendNUIMessage({ action = 'admin:datos', datos = Datos() }) end
end

--- Sale al juego, hace `que` y vuelve al panel en la misma tienda.
local function AlJuego(id, que)
    local t = TiendasGuardadas[tonumber(id)]
    if not t or enElJuego then return end
    local e = t.puntos.entrada
    if #(GetEntityCoords(PlayerPedId()) - vector3(e.x, e.y, e.z)) > 40.0 then
        return Aviso('Estás lejos de esa tienda. Acércate, o usa «Ir allí».', 'error')
    end

    enElJuego = true
    CerrarPanel(true)
    CreateThread(function()
        Wait(300)
        EsconderElDeVerdad(t.id, true)
        local ok, err = pcall(que, t)
        Limpiar()
        EsconderElDeVerdad(t.id, false)
        enElJuego = false
        if not ok then print(('^1[origen_tattoos]^0 %s'):format(err)) end
        AbrirPanel(t.id)
    end)
end

RegisterNUICallback('admin:cerrar', function(_, cb)
    cb({})
    CerrarPanel()
end)

RegisterNUICallback('admin:crear', function(d, cb)
    cb(lib.callback.await('origen_tattoos:admin:crear', false, d and d.nombre) or { ok = false, motivo = 'El servidor no contesta.' })
end)

RegisterNUICallback('admin:guardar', function(d, cb)
    local modelo = d and d.modelo
    if type(modelo) == 'string' then
        local hash = joaat(modelo)
        if not IsModelInCdimage(hash) or not IsModelAPed(hash) then
            return cb({ ok = false, motivo = 'Ese modelo de personaje no existe en el juego.' })
        end
    end
    cb(lib.callback.await('origen_tattoos:admin:guardar', false, d) or { ok = false, motivo = 'El servidor no contesta.' })
end)

RegisterNUICallback('admin:borrar', function(d, cb)
    cb(lib.callback.await('origen_tattoos:admin:borrar', false, d and d.id) or { ok = false, motivo = 'El servidor no contesta.' })
end)

RegisterNUICallback('admin:ubicar', function(d, cb)
    cb({})
    local t = TiendasGuardadas[tonumber(d and d.id)]
    if t then
        SetNewWaypoint(t.puntos.entrada.x + 0.0, t.puntos.entrada.y + 0.0)
        Aviso('Marcada en el mapa: ' .. t.nombre .. '.')
    end
end)

RegisterNUICallback('admin:ir', function(d, cb)
    local ok = lib.callback.await('origen_tattoos:admin:ir', false, d and d.id)
    cb({ ok = ok == true, motivo = not ok and 'No se pudo ir.' or nil })
    if ok then
        -- La distancia de las fichas ha cambiado.
        SetTimeout(600, AdminTiendasCambiadas)
    end
end)

RegisterNUICallback('admin:mover', function(d, cb)
    cb({})
    local cual = d and d.cual
    if not NOMBRES[cual] then return end
    AlJuego(d.id, function(t)
        local nuevo = MoverPunto(t, cual)
        if not nuevo then return end
        local r = lib.callback.await('origen_tattoos:admin:punto', false, {
            id = t.id, cual = cual, x = nuevo.x, y = nuevo.y, z = nuevo.z, h = nuevo.h,
        })
        if r and r.ok then
            Aviso(NOMBRES[cual] .. ': guardado.', 'success')
        else
            Aviso(r and r.motivo or 'No se pudo guardar.', 'error')
        end
        Wait(250)   -- que llegue el reparto antes de volver a pintar el panel
    end)
end)

RegisterNUICallback('admin:previa', function(d, cb)
    cb({})
    AlJuego(d and d.id, VistaPrevia)
end)

-- ---------------------------------------------------------------------------
--  Ver tatuajes
-- ---------------------------------------------------------------------------

--[[ El catalogo no trae fotos: para saber cual es cual se ven PUESTOS. Un
     doble tuyo, desvestido, delante de ti; cada tatuaje de la lista que se
     estaba mirando en el panel, uno a uno, con la camara en su zona. Se gira
     al doble para verle la espalda. ]]
local CAMARA_DE = {
    ZONE_HEAD = 'head', ZONE_HAIR = 'degradado', ZONE_TORSO = 'torso',
    ZONE_LEFT_ARM = 'arms', ZONE_RIGHT_ARM = 'arms', ZONE_LEFT_LEG = 'legs', ZONE_RIGHT_LEG = 'legs',
}

local function VerTatuajes(lista, indice)
    local yo = PlayerPedId()
    local mujer = GetEntityModel(yo) == `mp_f_freemode_01`

    local doble = CrearDoble()
    ResetEntityAlpha(doble)
    local sitio = GetOffsetFromEntityInWorldCoords(yo, 0.0, 1.8, 0.0)
    local rumbo = (GetEntityHeading(yo) + 180.0) % 360.0
    SetEntityCoordsNoOffset(doble, sitio.x, sitio.y, sitio.z, false, false, false)
    SetEntityHeading(doble, rumbo)

    -- Sin ropa que tape: la misma de la camilla (Config.Clothes).
    local ropa = Config.Clothes and Config.Clothes[GetGender()]
    for componente, v in pairs(ropa or {}) do SetPedComponentVariation(doble, componente, v[1], v[2], 0) end
    for _, prop in ipairs({ 0, 1, 2, 6, 7 }) do ClearPedProp(doble, prop) end

    local i = math.max(1, math.min(#lista, tonumber(indice) or 1))
    local camara, zonaPuesta, foco = nil, nil, sitio

    local function Camara(zona)
        local cual = CAMARA_DE[zona] or 'default'
        if camara and zonaPuesta == cual then return end
        zonaPuesta = cual
        local desde, hacia = table.unpack(Config.Cameras[cual] or Config.Cameras['default'])
        -- Medida desde donde esta el doble, pero sin girar con el: asi al
        -- girarlo se le ve la espalda en vez de dar la vuelta la camara.
        local r = math.rad(rumbo)
        local function Punto(o)
            return vector3(sitio.x - math.sin(r) * o.y + math.cos(r) * o.x, sitio.y + math.cos(r) * o.y + math.sin(r) * o.x, sitio.z + o.z)
        end
        local c, m = Punto(desde), Punto(hacia)
        foco = c
        local nueva = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', c.x, c.y, c.z, 0.0, 0.0, 0.0, 45.0, false, 0)
        PointCamAtCoord(nueva, m.x, m.y, m.z)
        if camara then
            SetCamActiveWithInterp(nueva, camara, 350, 1, 1)
            local vieja = camara
            SetTimeout(400, function() DestroyCam(vieja, false) end)
        else
            SetCamActive(nueva, true)
            RenderScriptCams(true, true, 350, true, true)
        end
        camara = nueva
    end

    local function Pintar()
        local t = lista[i]
        ClearPedDecorations(doble)
        if type(t.deco) == 'table' then
            -- Una figura del pack propio: varias decoraciones y, a veces, varias pasadas.
            for _, d in ipairs(t.deco) do
                for _ = 1, math.max(1, math.min(4, math.floor(tonumber(d.n) or 1))) do
                    SetPedDecoration(doble, d.c, d.b .. (mujer and '_f' or '_m'))
                end
            end
            -- De cara al sitio donde va: una espalda se enseña de espaldas.
            SetEntityHeading(doble, (rumbo + (tonumber(t.giro) or 0) + 0.0) % 360.0)
        else
            local hash = mujer and t.f or t.m
            if not hash or hash == '' then hash = (t.m ~= '' and t.m) or t.f end
            if hash and hash ~= '' then SetPedDecoration(doble, t.c, hash) end
            SetEntityHeading(doble, rumbo)
        end
        Camara(t.z)
        pcall(function() exports.origen_hud:setupControls({
            { key = ('%d / %d'):format(i, #lista), text = t.n .. ' · ' .. (t.origen or 'del juego') },
            { key = '←  →', text = 'Anterior / siguiente' },
            { key = 'Q  E', text = 'Girar' },
            { key = 'X', text = 'Volver al panel' },
        }) end)
    end

    Pintar()
    while true do
        Wait(0)
        for _, c in ipairs(TECLAS) do DisableControlAction(0, c, true) end

        -- Tu personaje no se pinta mientras miras: en el plano de cuerpo entero
        -- la camara cae justo donde estas y solo se veia tu espalda.
        SetEntityLocallyInvisible(yo)

        -- Un foco desde la camara: de noche no se veia nada.
        DrawLightWithRange(foco.x, foco.y, foco.z + 0.25, 255, 250, 240, 5.0, 2.2)

        if Pulsa(175) then i = i % #lista + 1 Pintar() end
        if Pulsa(174) then i = (i - 2) % #lista + 1 Pintar() end

        -- Girar mientras se mantiene: Q a un lado, E al otro.
        local giro = (IsDisabledControlPressed(0, 44) and -2.5 or 0.0) + (IsDisabledControlPressed(0, 38) and 2.5 or 0.0)
        if giro ~= 0.0 then SetEntityHeading(doble, (GetEntityHeading(doble) + giro) % 360.0) end

        if Pulsa(73) then break end
    end

    if camara then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(camara, false)
    end
    pcall(function() exports.origen_hud:hideControls() end)
    Limpiar()
    return i
end

--- Sale al juego a ver esos tatuajes y vuelve al panel, en su seccion.
local function SalirAVer(lista, indice)
    if type(lista) ~= 'table' or #lista == 0 or enElJuego then return end

    enElJuego = true
    CerrarPanel(true)
    CreateThread(function()
        Wait(300)
        local ok, err = pcall(VerTatuajes, lista, indice)
        Limpiar()
        enElJuego = false
        if not ok then print(('^1[origen_tattoos]^0 %s'):format(err)) end
        AbrirPanel(nil, false, 'tatuajes')
    end)
end

RegisterNUICallback('admin:ver', function(d, cb)
    cb({})
    SalirAVer(type(d) == 'table' and d.lista, type(d) == 'table' and d.indice)
end)

-- Lo mismo desde otro recurso: solo crea un doble en la pantalla de quien lo
-- llama, no toca a nadie ni guarda nada.
exports('VerTatuajes', SalirAVer)

RegisterCommand(Config.Comando, function()
    if panel or enElJuego or openedMenu then return end
    if not lib.callback.await('origen_tattoos:admin:puede', false) then return end
    desdeElHub = false
    AbrirPanel()
end, false)

--- Como lo abre la pestaña Scripts del panel de administracion. Si no se
--- puede, el panel de admin ya se aparto: que vuelva, o el jugador se queda
--- sin nada delante.
exports('openManagement', function()
    CreateThread(function()
        local puede = not panel and not enElJuego and not openedMenu
            and lib.callback.await('origen_tattoos:admin:puede', false)
        if not puede then
            if GetResourceState('origen_admin') == 'started' then
                exports['origen_admin']:ReturnToScripts()
            end
            return
        end
        desdeElHub = true
        AbrirPanel(nil, true)
    end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Limpiar()
    if enElJuego then
        RenderScriptCams(false, false, 0, true, true)
        pcall(function() exports.origen_hud:hideControls() end)
    end
    if panel then
        SetNuiFocus(false, false)
        HudFuera(false)
    end
end)
