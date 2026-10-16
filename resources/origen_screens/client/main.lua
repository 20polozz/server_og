-- ════════════════════════════════════════════════════════════════════
--  origen_screens · cliente: pantallas de admin y el mando
--
--  El motor (client/motor.lua) pinta; esto da de alta las pantallas que
--  colocan los admins, pone el aviso de [E] a su lado, abre el mando y lleva
--  la colocación (/screen_create) y la lista (/screen_admin).
-- ════════════════════════════════════════════════════════════════════

local pantallas = {}        -- id -> datos que manda el servidor
local mando = nil           -- { id, admin, casa, pantalla }
local colocando = false

-- ── Utilidades ──────────────────────────────────────────────────────
local function Notificar(texto, tipo)
    if GetResourceState('origen_notify') == 'started' then
        exports.origen_notify:Notify({ title = 'Teles', description = texto, type = tipo or 'primary', duration = 5000 })
    end
end

--- La barra de teclas del servidor (origen_hud); la de GTA solo si no esta.
local function Ayuda(texto)
    if GetResourceState('origen_hud') == 'started' then
        return exports.origen_hud:Ayuda(texto)
    end
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function vec(t)
    if type(t) ~= 'table' then return nil end
    local x, y, z = tonumber(t.x), tonumber(t.y), tonumber(t.z)
    if not x or not y or not z then return nil end
    return vector3(x, y, z)
end

-- Las cuatro esquinas de una pantalla de pared a partir de las dos que marcó
-- el admin y la normal de la pared.
local function Esquinas(p1, p2, normal)
    local N = normal
    local largo = #N
    N = largo > 0 and N / largo or vector3(0, 1, 0)
    local V = math.abs(N.z) > 0.99 and vector3(0, 1, 0) or vector3(0, 0, 1)
    local U = vector3(V.y * N.z - V.z * N.y, V.z * N.x - V.x * N.z, V.x * N.y - V.y * N.x)
    local lu = #U
    U = lu > 0 and U / lu or vector3(1, 0, 0)
    V = vector3(N.y * U.z - N.z * U.y, N.z * U.x - N.x * U.z, N.x * U.y - N.y * U.x)
    local d = p2 - p1
    local w = d.x * U.x + d.y * U.y + d.z * U.z
    local h = d.x * V.x + d.y * V.y + d.z * V.z
    local o = N * 0.02
    return p1 + o, p1 + U * w + o, p1 + V * h + o, p1 + U * w + V * h + o
end

local function Rayo(distancia, banderas)
    local cam = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local rx, rz = math.rad(rot.x), math.rad(rot.z)
    local c = math.abs(math.cos(rx))
    local dir = vector3(-math.sin(rz) * c, math.cos(rz) * c, math.sin(rx))
    local destino = cam + dir * distancia
    local rayo = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z, destino.x, destino.y, destino.z, banderas or -1, PlayerPedId(), 0)
    local _, golpe, fin, normal, entidad = GetShapeTestResult(rayo)
    return golpe == 1 or golpe == true, fin, normal, entidad
end

-- ── Alta de las pantallas en el motor ───────────────────────────────
local function IdTele(pid) return 'pantalla:' .. pid end

local function AltaEnMotor(p)
    local id = IdTele(p.id)
    Motor.Quitar(id)
    if p.modo == 'prop' then
        Motor.Registrar(id, { modelo = p.modelo, coords = p.ancla, nombre = p.name, oculta = p.hidden })
    else
        local p1, p2, n = vec(p.p1), vec(p.p2), vec(p.normal)
        if not p1 or not p2 or not n then return end
        local c1, c2, c3, c4 = Esquinas(p1, p2, n)
        Motor.Registrar(id, {
            esquinas = { c1 = c1, c2 = c2, c3 = c3, c4 = c4 },
            zona = p.polyzone, nombre = p.name, oculta = p.hidden,
        })
    end
end

RegisterNetEvent('origen_screens:client:pantallas', function(lista)
    if type(lista) ~= 'table' then return end
    for id in pairs(pantallas) do
        if not lista[id] then Motor.Quitar(IdTele(id)) end
    end
    pantallas = lista
    for _, p in pairs(pantallas) do AltaEnMotor(p) end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('origen_screens:server:pedirPantallas')
end)

-- ── El mando ────────────────────────────────────────────────────────
local function EstadoParaNui(id)
    local st = Motor.Estado(id)
    if not st then return { encendida = false } end
    local url
    if st.tipo == 'youtube' then url = 'youtube.com/watch?v=' .. st.ref
    elseif st.clase == 'vod' then url = 'twitch.tv/videos/' .. st.ref
    else url = 'twitch.tv/' .. st.ref end
    return {
        encendida = true, tipo = st.tipo, clase = st.clase, ref = st.ref, url = url,
        pausado = st.pausa ~= nil, volumen = st.volumen,
    }
end

local function CerrarMando()
    if not mando then return end
    mando = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'cerrar' })
end

function AbrirMando(id)
    if mando or colocando or type(id) ~= 'string' then return end
    local r = lib.callback.await('origen_screens:server:mando', false, id)
    if not r or not r.ok then
        Notificar((r and r.motivo) or 'No puedes usar esta tele', 'error')
        return
    end
    mando = { id = id, admin = r.admin, casa = r.casa, pantalla = r.pantalla }
    SetNuiFocus(true, true)
    SendNUIMessage({
        accion = 'mando', id = id, nombre = r.nombre, admin = r.admin, casa = r.casa,
        estado = EstadoParaNui(id),
    })

    -- Si te alejas, se cierra (el servidor rechazaría las órdenes igualmente).
    CreateThread(function()
        while mando and mando.id == id do
            Wait(500)
            if not mando.admin then
                local reg = Motor.Registro(id)
                local centro = reg and Motor.Centro(reg)
                local pos = GetEntityCoords(PlayerPedId())
                if not centro or #(pos - centro) > Config.DistanciaMando + 4.0 then
                    CerrarMando()
                end
            end
        end
    end)
end
-- Desde otro recurso se llama sin esperar: AbrirMando espera al servidor, y
-- esperar dentro de una llamada a un export de otro recurso no es seguro.
exports('AbrirMando', function(id)
    CreateThread(function() AbrirMando(id) end)
end)

Motor.AlCambiar = function(id)
    if mando and mando.id == id then
        SendNUIMessage({ accion = 'estado', estado = EstadoParaNui(id) })
    end
end

RegisterNUICallback('mando', function(datos, cb)
    if not mando or type(datos) ~= 'table' then return cb({ ok = false }) end
    local r = lib.callback.await('origen_screens:server:tele', false, mando.id, datos.accion, datos.dato)
    cb(r or { ok = false })
end)

RegisterNUICallback('cerrar', function(_, cb)
    CerrarMando()
    cb('ok')
end)

-- ── Aviso de [E] junto a las pantallas ──────────────────────────────
local avisoPuesto = false

local function PuntoInteraccion(p)
    if p.modo == 'prop' then
        local reg = Motor.Registro(IdTele(p.id))
        return reg and Motor.Centro(reg) or vec(p.ancla)
    end
    return vec(p.interaction)
end

CreateThread(function()
    while true do
        local espera = 1000
        local cerca = nil

        if not mando and not colocando then
            local pos = GetEntityCoords(PlayerPedId())
            for _, p in pairs(pantallas) do
                local punto = PuntoInteraccion(p)
                if punto then
                    local d = #(pos - punto)
                    if d < 12.0 then
                        espera = 0
                        if p.modo ~= 'prop' and not p.hideMarker then
                            DrawMarker(20, punto.x, punto.y, punto.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 216, 27, 85, 180, false, false, 2, false, nil, nil, false)
                        end
                        local alcance = p.modo == 'prop' and Config.DistanciaInteraccion + 1.0 or 2.0
                        if d < alcance then cerca = p end
                    end
                end
            end
        end

        if cerca then
            if not avisoPuesto then
                exports.origen_notify:DrawText('E', 'Mando de la pantalla')
                avisoPuesto = true
            end
            if IsControlJustReleased(0, 38) then
                exports.origen_notify:HideText()
                avisoPuesto = false
                AbrirMando(IdTele(cerca.id))
            end
        elseif avisoPuesto then
            exports.origen_notify:HideText()
            avisoPuesto = false
        end

        Wait(espera)
    end
end)

-- ── Admin: ajustes, lista ───────────────────────────────────────────
local function AbrirAjustes(pid)
    local d = lib.callback.await('origen_screens:server:ajustesDe', false, pid)
    if not d then return end
    mando = mando or { id = IdTele(pid), admin = true }
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'ajustes', datos = d })
end

RegisterNUICallback('ajustes', function(datos, cb)
    if mando and mando.admin and mando.pantalla then
        CreateThread(function() AbrirAjustes(mando.pantalla) end)
    end
    cb('ok')
end)

RegisterNUICallback('guardarAjustes', function(datos, cb)
    if type(datos) == 'table' and type(datos.id) == 'string' then
        TriggerServerEvent('origen_screens:server:ajustar', datos.id, {
            name = datos.name, job = datos.job, negocio = datos.negocio, hideMarker = datos.hideMarker == true,
        })
    end
    CerrarMando()
    cb('ok')
end)

RegisterNUICallback('ocultar', function(datos, cb)
    if type(datos) == 'table' and type(datos.id) == 'string' then
        TriggerServerEvent('origen_screens:server:ocultar', datos.id)
    end
    cb('ok')
end)

RegisterNUICallback('borrar', function(datos, cb)
    if type(datos) == 'table' and type(datos.id) == 'string' then
        TriggerServerEvent('origen_screens:server:borrar', datos.id)
    end
    cb('ok')
end)

RegisterNetEvent('origen_screens:client:admin', function()
    local lista = lib.callback.await('origen_screens:server:listaAdmin', false)
    if not lista then return end
    mando = { id = '', admin = true }
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'admin', lista = lista })
end)

-- El riel de la gestión vuelve a la lista: la pide otra vez al servidor, que
-- es quien decide si eres admin (listaAdmin).
RegisterNUICallback('adminLista', function(_, cb)
    cb('ok')
    if not (mando and mando.admin) then return end
    CreateThread(function()
        local lista = lib.callback.await('origen_screens:server:listaAdmin', false)
        if lista then SendNUIMessage({ accion = 'admin', lista = lista }) end
    end)
end)

RegisterNUICallback('adminMando', function(datos, cb)
    cb('ok')
    if type(datos) ~= 'table' or type(datos.id) ~= 'string' then return end
    mando = nil
    SetNuiFocus(false, false)
    CreateThread(function() AbrirMando(IdTele(datos.id)) end)
end)

RegisterNUICallback('adminAjustes', function(datos, cb)
    cb('ok')
    if type(datos) ~= 'table' or type(datos.id) ~= 'string' then return end
    CreateThread(function() AbrirAjustes(datos.id) end)
end)

RegisterNUICallback('adminIr', function(datos, cb)
    cb('ok')
    local p = type(datos) == 'table' and pantallas[datos.id]
    if not p then return end
    CerrarMando()
    local punto = p.modo == 'prop' and vec(p.ancla) or vec(p.interaction)
    if not punto then return end
    -- El servidor ya dejó abrir la lista solo a admins; ir es solo moverse.
    SetEntityCoords(PlayerPedId(), punto.x, punto.y, punto.z, false, false, false, true)
end)

-- ── Colocación (/screen_create) ─────────────────────────────────────
RegisterNetEvent('origen_screens:client:crear', function()
    if colocando or mando then return end
    mando = { id = '', admin = true }
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'crear' })
end)

local function Enviar(datos)
    colocando = false
    TriggerServerEvent('origen_screens:server:crear', datos)
end

local function ColocarProp(conf)
    Notificar('Apunta a la tele del mapa y pulsa [E]. [Retroceso] para cancelar.')
    while colocando do
        Wait(0)
        local golpe, fin, _, entidad = Rayo(25.0, 16)
        local info = golpe and entidad and entidad ~= 0 and GetEntityType(entidad) == 3 and Config.ModelosPorHash[GetEntityModel(entidad)]
        if info then
            local c = GetEntityCoords(entidad)
            DrawMarker(0, c.x, c.y, c.z + 0.6, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.25, 0.25, 0.25, 216, 27, 85, 220, true, false, 2, false, nil, nil, false)
            Ayuda(('~INPUT_PICKUP~ Usar esta tele (%s)~n~~INPUT_CELLPHONE_CANCEL~ Cancelar'):format(info.nombre))
            if IsControlJustPressed(0, 38) then
                PlaySoundFrontend(-1, 'SELECT', 'HUD_FRONTEND_DEFAULT_SOUNDS', true)
                conf.modo, conf.modelo = 'prop', GetEntityModel(entidad)
                conf.ancla = { x = c.x, y = c.y, z = c.z }
                return Enviar(conf)
            end
        else
            if golpe then DrawMarker(28, fin.x, fin.y, fin.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.08, 0.08, 0.08, 255, 255, 255, 150, false, false, 2, false, nil, nil, false) end
            Ayuda('Apunta a una tele compatible~n~~INPUT_CELLPHONE_CANCEL~ Cancelar')
        end
        if IsControlJustPressed(0, 177) then
            colocando = false
            Notificar('Colocación cancelada.', 'error')
        end
    end
end

local function ColocarPared(conf)
    local paso, p1, n1, p2, inter = 1, nil, nil, nil, nil
    local zona = {}
    Notificar('Mira a la pared y pulsa [E] en la esquina inferior izquierda.')
    while colocando do
        Wait(0)
        local golpe, fin, normal = Rayo(30.0, -1)

        if paso <= 2 and golpe then
            DrawMarker(28, fin.x, fin.y, fin.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.1, 0.1, 255, 255, 255, 150, false, false, 2, false, nil, nil, false)
            if paso == 1 then
                Ayuda('~INPUT_PICKUP~ Esquina inferior izquierda~n~~INPUT_CELLPHONE_CANCEL~ Cancelar')
                if IsControlJustPressed(0, 38) then p1, n1, paso = fin, normal, 2 end
            else
                local c1, c2, c3, c4 = Esquinas(p1, fin, n1)
                DrawLine(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, 216, 27, 85, 255)
                DrawLine(c2.x, c2.y, c2.z, c4.x, c4.y, c4.z, 216, 27, 85, 255)
                DrawLine(c4.x, c4.y, c4.z, c3.x, c3.y, c3.z, 216, 27, 85, 255)
                DrawLine(c3.x, c3.y, c3.z, c1.x, c1.y, c1.z, 216, 27, 85, 255)
                Ayuda('~INPUT_PICKUP~ Esquina superior derecha~n~~INPUT_CELLPHONE_CANCEL~ Cancelar')
                if IsControlJustPressed(0, 38) then p2, paso = fin, 3 end
            end
        elseif paso == 3 then
            local ped = PlayerPedId()
            local c = GetEntityCoords(ped)
            DrawMarker(1, c.x, c.y, c.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.5, 216, 27, 85, 100, false, false, 2, false, nil, nil, false)
            Ayuda('~INPUT_PICKUP~ Fijar aquí el punto del mando~n~~INPUT_CELLPHONE_CANCEL~ Cancelar')
            if IsControlJustPressed(0, 38) then
                inter = { x = c.x, y = c.y, z = c.z, w = GetEntityHeading(ped) }
                paso = conf.usePolyzone and 4 or 5
                if paso == 4 then Notificar('Marca la zona de sonido: [E] añade un punto, [Intro] termina.') end
            end
        elseif paso == 4 then
            local punto = golpe and fin or GetEntityCoords(PlayerPedId())
            DrawLine(punto.x, punto.y, punto.z - 15.0, punto.x, punto.y, punto.z + 15.0, 216, 27, 85, 255)
            for i = 1, #zona do
                local a, b = zona[i], zona[i % #zona + 1]
                DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 20, 180, 90, 255)
            end
            Ayuda(('~INPUT_PICKUP~ Añadir punto (%d)~n~~INPUT_FRONTEND_ACCEPT~ Terminar~n~~INPUT_CELLPHONE_CANCEL~ Cancelar'):format(#zona))
            if IsControlJustPressed(0, 38) and #zona < 40 then
                zona[#zona + 1] = { x = punto.x, y = punto.y, z = punto.z }
            end
            if IsControlJustPressed(0, 201) then
                if #zona < 3 then Notificar('Hacen falta al menos 3 puntos.', 'error') else paso = 5 end
            end
        end

        if paso == 5 then
            conf.modo = 'pared'
            conf.p1 = { x = p1.x, y = p1.y, z = p1.z }
            conf.p2 = { x = p2.x, y = p2.y, z = p2.z }
            conf.normal = { x = n1.x, y = n1.y, z = n1.z }
            conf.interaction = inter
            conf.polyzone = #zona >= 3 and zona or nil
            return Enviar(conf)
        end

        if IsControlJustPressed(0, 177) then
            colocando = false
            Notificar('Colocación cancelada.', 'error')
        end
    end
end

RegisterNUICallback('empezarColocacion', function(datos, cb)
    cb('ok')
    mando = nil
    SetNuiFocus(false, false)
    if colocando or type(datos) ~= 'table' then return end
    colocando = true
    local conf = {
        name = datos.name, job = datos.job, negocio = datos.negocio,
        volume = tonumber(datos.volume) or 50, hideMarker = datos.hideMarker == true,
        usePolyzone = datos.usePolyzone == true,
    }
    CreateThread(function()
        if datos.modo == 'prop' then ColocarProp(conf) else ColocarPared(conf) end
    end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if avisoPuesto then exports.origen_notify:HideText() end
end)
