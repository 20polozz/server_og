--[[ ── Autoescuela · Panel de Administración y Creador de Rutas IC ───────────────
     Permite a los administradores:
       · Ver todas las rutas existentes en la base de datos (filtradas por carnet).
       · Activar / desactivar y eliminar rutas.
       · Crear nuevas rutas conduciendo en tiempo real (IC) con checkpoints
         configurables: STOP, GIRO IZQ/DER (intermitentes), SEMÁFORO, EMERGENCIA,
         APARCAMIENTO y límite de velocidad por tramo.
       · Conectar directamente con el Hub de origen_admin mediante openManagement().
   ───────────────────────────────────────────────────────────────────────────── ]]

local adminAbierto = false
local grabando = false
local datosRuta = nil
local checkpoints = {}
local blipsGrabacion = {}
local accionActual = 'normal'
local limiteActual = 50.0
local radioActual = 12.0
local plazaAparcamiento = nil

local ACCIONES = {
    { id = 'normal',     label = 'PASO NORMAL',           desc = 'Punto de paso sin parada obligatoria',      color = { 220, 221, 224 } },
    { id = 'stop',       label = 'STOP (DETENCIÓN)',      desc = 'Detención obligatoria antes de la línea',    color = { 216, 27, 85 } },
    { id = 'giro_izq',   label = 'GIRO A LA IZQUIERDA',   desc = 'Intermitente izquierdo obligatorio',        color = { 216, 27, 85 } },
    { id = 'giro_der',   label = 'GIRO A LA DERECHA',     desc = 'Intermitente derecho obligatorio',          color = { 216, 27, 85 } },
    { id = 'semaforo',   label = 'SEMÁFORO / CRUCE',      desc = 'Precaución y moderación de velocidad',      color = { 216, 27, 85 } },
    { id = 'emergencia', label = 'FRENADA EMERGENCIA',    desc = 'Frenazo en seco ordenado por examinador',   color = { 216, 27, 85 } },
    { id = 'aparcar',    label = 'PLAZA APARCAMIENTO',    desc = 'Estacionamiento final de la prueba',        color = { 216, 27, 85 } },
}

local LIMITES = { 30.0, 40.0, 50.0, 60.0, 80.0, 100.0, 120.0 }

local function EsStaff()
    local ok, r = pcall(function() return lib.callback.await('origen_autoescuela:esStaff', false) end)
    return ok and r == true
end

-- =========================================================================
-- APERTURA Y CIERRE DEL PANEL DE GESTIÓN (HUB / EXPORTS)
-- =========================================================================

local function AbrirAdmin()
    if adminAbierto or grabando then return end
    adminAbierto = true
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'autoescuela:abrirAdmin' })
end

exports('openManagement', AbrirAdmin)

RegisterCommand('autoescuela_admin', function()
    if not EsStaff() then
        A.Aviso('No tienes permisos de administración.', 'error')
        return
    end
    AbrirAdmin()
end, false)

local function CerrarAdmin()
    if not adminAbierto then return end
    adminAbierto = false
    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'autoescuela:cerrarAdmin' })
end

--- Cerrar y, si el panel se abrió desde la pestaña Scripts del admin, volver
--- a ella. Ya no hay botón: es lo que hacen ESC y el aspa. origen_admin
--- decide si vuelve (solo si este panel salió de su lista); con el comando
--- /autoescuela_admin, ESC cierra y nada más.
local function CerrarYVolver()
    CerrarAdmin()
    if GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end

RegisterNUICallback('adminVolver', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminCerrar', function(_, cb)
    cb({})
    CerrarYVolver()
end)

--[[ Si el vigilante suelta el raton a la fuerza, el panel se da por cerrado:
     sin esto `adminAbierto` seguia en true y AbrirAdmin no volvia a abrirlo
     nunca. La grabacion de ruta no se toca: va sin foco. ]]
OrigenFoco.AlSoltar(function()
    adminAbierto = false
    SendNUIMessage({ accion = 'autoescuela:cerrarAdmin' })
end)

-- =========================================================================
-- CALLBACKS RPC DE LA NUI
-- =========================================================================

RegisterNUICallback('admin:getRutas', function(_, cb)
    local res = lib.callback.await('origen_autoescuela:admin:getRutas', false) or { ok = false, rutas = {} }
    cb(res)
end)

RegisterNUICallback('admin:toggleRuta', function(data, cb)
    local res = lib.callback.await('origen_autoescuela:admin:toggleRuta', false, data.id, data.activo) or { ok = false }
    cb(res)
end)

RegisterNUICallback('admin:borrarRuta', function(data, cb)
    local res = lib.callback.await('origen_autoescuela:admin:borrarRuta', false, data.id) or { ok = false }
    cb(res)
end)

RegisterNUICallback('admin:getJugadores', function(_, cb)
    local res = lib.callback.await('origen_autoescuela:admin:getJugadores', false) or { ok = false, jugadores = {} }
    cb(res)
end)

RegisterNUICallback('admin:entregarLicencia', function(data, cb)
    local res = lib.callback.await('origen_autoescuela:admin:entregarLicencia', false, data) or { ok = false, mensaje = 'Error de conexión con el servidor' }
    cb(res)
end)

-- =========================================================================
-- MODO DE GRABACIÓN DE RUTA IC (CONDUCIENDO)
-- =========================================================================

local function LimpiarBlipsGrabacion()
    for _, b in ipairs(blipsGrabacion) do
        OrigenMapa.Quitar(b)
    end
    blipsGrabacion = {}
end

local function ObtenerAccionInfo(id)
    for _, a in ipairs(ACCIONES) do
        if a.id == id then return a end
    end
    return ACCIONES[1]
end

local function EstablecerAccion(id)
    local info = ObtenerAccionInfo(id)
    if not info then return end
    accionActual = id
    PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
    ActualizarHudGrabacion()
    A.Aviso(('Acción: %s'):format(info.label), 'inform', 1600)
end

local function AbrirMenuAcciones()
    local opciones = {}
    for i, a in ipairs(ACCIONES) do
        local icono = 'circle'
        local color = '#0b0b0d'
        if a.id == 'stop' then
            icono = 'hand'
            color = '#d81b55'
        elseif a.id == 'giro_izq' then
            icono = 'arrow-left'
            color = '#d81b55'
        elseif a.id == 'giro_der' then
            icono = 'arrow-right'
            color = '#d81b55'
        elseif a.id == 'semaforo' then
            icono = 'traffic-light'
            color = '#d81b55'
        elseif a.id == 'emergencia' then
            icono = 'bolt'
            color = '#d81b55'
        elseif a.id == 'aparcar' then
            icono = 'square-parking'
            color = '#d81b55'
        end

        local esActual = a.id == accionActual
        opciones[#opciones + 1] = {
            title = ('[%d] %s%s'):format(i, a.label, esActual and ' · SELECCIONADA' or ''),
            description = a.desc,
            icon = icono,
            iconColor = color,
            onSelect = function()
                EstablecerAccion(a.id)
            end
        }
    end

    lib.registerContext({
        id = 'ae_selector_acciones',
        title = 'Seleccionar Acción',
        options = opciones
    })
    lib.showContext('ae_selector_acciones')
end

RegisterNUICallback('admin:setAccion', function(data, cb)
    if data and data.accion then
        EstablecerAccion(data.accion)
    end
    cb('ok')
end)

local function CalcularDistanciaRuta(cps)
    if #cps < 2 then return 0.0 end
    local d = 0.0
    for i = 1, #cps - 1 do
        local p1 = vec3(cps[i].x, cps[i].y, cps[i].z)
        local p2 = vec3(cps[i + 1].x, cps[i + 1].y, cps[i + 1].z)
        d = d + #(p2 - p1)
    end
    return d
end

local function ActualizarHudGrabacion()
    local info = ObtenerAccionInfo(accionActual)
    SendNUIMessage({
        accion = 'autoescuela:hudGrabacion:actualizar',
        datos = {
            carnet = datosRuta and datosRuta.carnet or 'coche',
            nombre = datosRuta and datosRuta.nombre or 'Ruta',
            totalPuntos = #checkpoints,
            accionId = accionActual,
            accionLabel = info.label,
            accionDesc = info.desc,
            limite = math.floor(limiteActual),
            radio = math.floor(radioActual),
            distancia = math.floor(CalcularDistanciaRuta(checkpoints))
        }
    })
end

--[[ Rótulo «pegatina» en pantalla, centrado en (sx, sy): sombra dura,
     canto negro fino, pieza gris claro (rosa si acento) y tinta negra. ]]
local function Chapa(sx, sy, texto, escala, acento)
    texto = (tostring(texto or ''):gsub('~', ''))
    escala = escala or 0.35
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(texto)
    SetTextFont(4)
    SetTextScale(escala, escala)
    local w = EndTextCommandGetWidth(true) + 0.012
    local alto = GetRenderedCharacterHeight(escala, 4)
    local h = alto + 0.012
    DrawRect(sx + 0.0022, sy + 0.0040, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(sx, sy, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    if acento then
        DrawRect(sx, sy, w, h, 216, 27, 85, 255)
    else
        DrawRect(sx, sy, w, h, 220, 221, 224, 255)
    end
    SetTextFont(4)
    SetTextScale(escala, escala)
    SetTextColour(11, 11, 13, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(sx, sy - alto * 0.62)
end

--- Rótulo sobre el mundo. r/g/b se ignoran (antes teñían el texto): la
--- chapa va en gris; acento si el color pedido era el rosa.
local function DibujarTexto3D(x, y, z, texto, r, g, b, escala)
    local on, sx, sy = World3dToScreen2d(x, y, z)
    if on then
        Chapa(sx, sy, texto, escala or 0.35, r == 216 and g == 27)
    end
end

local function CancelarGrabacion(motivo)
    grabando = false
    datosRuta = nil
    checkpoints = {}
    plazaAparcamiento = nil
    LimpiarBlipsGrabacion()
    SendNUIMessage({ accion = 'autoescuela:hudGrabacion:ocultar' })
    A.Aviso(motivo or 'Grabación cancelada.', 'inform')
end

RegisterNUICallback('admin:startRecording', function(data, cb)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= ped then
        A.Aviso('Debes estar sentado al volante de un vehículo para trazar la ruta.', 'error')
        cb({ ok = false, mensaje = 'No estás al volante de un vehículo' })
        return
    end

    CerrarAdmin()

    datosRuta = {
        carnet = data.carnet or 'coche',
        nombre = data.nombre and data.nombre:gsub('^%s*(.-)%s*$', '%1') or 'Ruta Nueva',
        descripcion = data.descripcion or ''
    }

    checkpoints = {}
    plazaAparcamiento = nil
    accionActual = 'normal'
    limiteActual = 50.0
    radioActual = 12.0
    LimpiarBlipsGrabacion()

    grabando = true
    cb({ ok = true })

    local infoInicial = ObtenerAccionInfo(accionActual)
    SendNUIMessage({
        accion = 'autoescuela:hudGrabacion:mostrar',
        datos = {
            carnet = datosRuta.carnet,
            nombre = datosRuta.nombre,
            totalPuntos = 0,
            accionId = accionActual,
            accionLabel = infoInicial.label,
            accionDesc = infoInicial.desc,
            limite = math.floor(limiteActual),
            radio = math.floor(radioActual),
            distancia = 0
        }
    })
    ActualizarHudGrabacion()

    A.Aviso(('Grabando ruta [%s] · %s. Pulsa [E] para colocar checkpoints.'):format(datosRuta.carnet:upper(), datosRuta.nombre), 'success', 6000)

    -- Hilo de controles y renderizado 3D
    CreateThread(function()
        while grabando do
            local sleep = 0
            local p = PlayerPedId()
            local v = GetVehiclePedIsIn(p, false)

            if v == 0 then
                CancelarGrabacion('Te has bajado del vehículo.')
                break
            end

            -- Deshabilitar teclas 1 a 7 para capturar la acción directamente
            DisableControlAction(0, 157, true) -- Tecla 1 (Paso Normal)
            DisableControlAction(0, 158, true) -- Tecla 2 (Stop)
            DisableControlAction(0, 160, true) -- Tecla 3 (Giro Izq)
            DisableControlAction(0, 164, true) -- Tecla 4 (Giro Der)
            DisableControlAction(0, 165, true) -- Tecla 5 (Semáforo)
            DisableControlAction(0, 159, true) -- Tecla 6 (Emergencia)
            DisableControlAction(0, 161, true) -- Tecla 7 (Aparcar)

            -- Selección Directa con Teclas 1 a 7
            if IsDisabledControlJustPressed(0, 157) then
                EstablecerAccion('normal')
            elseif IsDisabledControlJustPressed(0, 158) then
                EstablecerAccion('stop')
            elseif IsDisabledControlJustPressed(0, 160) then
                EstablecerAccion('giro_izq')
            elseif IsDisabledControlJustPressed(0, 164) then
                EstablecerAccion('giro_der')
            elseif IsDisabledControlJustPressed(0, 165) then
                EstablecerAccion('semaforo')
            elseif IsDisabledControlJustPressed(0, 159) then
                EstablecerAccion('emergencia')
            elseif IsDisabledControlJustPressed(0, 161) then
                EstablecerAccion('aparcar')
            end

            -- [G] Abrir Menú Interactivo de Acciones
            if IsControlJustPressed(0, 47) then
                AbrirMenuAcciones()
            end

            -- [FLECHA ARRIBA] Subir Límite de Velocidad
            if IsControlJustPressed(0, 172) then
                for i, lim in ipairs(LIMITES) do
                    if lim > limiteActual then
                        limiteActual = lim
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                        ActualizarHudGrabacion()
                        break
                    end
                end
            end

            -- [FLECHA ABAJO] Bajar Límite de Velocidad
            if IsControlJustPressed(0, 173) then
                for i = #LIMITES, 1, -1 do
                    if LIMITES[i] < limiteActual then
                        limiteActual = LIMITES[i]
                        PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                        ActualizarHudGrabacion()
                        break
                    end
                end
            end

            -- [FLECHA IZQUIERDA] Reducir Radio
            if IsControlJustPressed(0, 174) then
                radioActual = math.max(6.0, radioActual - 1.0)
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                ActualizarHudGrabacion()
            end

            -- [FLECHA DERECHA] Aumentar Radio
            if IsControlJustPressed(0, 175) then
                radioActual = math.min(25.0, radioActual + 1.0)
                PlaySoundFrontend(-1, 'NAV_UP_DOWN', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                ActualizarHudGrabacion()
            end

            -- [E] Colocar Checkpoint
            if IsControlJustPressed(0, 38) then
                local coords = GetEntityCoords(v)
                local heading = GetEntityHeading(v)
                local zSuelo = A.Suelo(coords.x, coords.y, coords.z + 2.0) or coords.z

                local punto = {
                    x = coords.x,
                    y = coords.y,
                    z = zSuelo,
                    heading = heading,
                    radio = radioActual,
                    limite = limiteActual,
                    accion = accionActual,
                    stop = accionActual == 'stop',
                    giro = accionActual == 'giro_izq' and 'izq' or (accionActual == 'giro_der' and 'der' or nil)
                }

                if accionActual == 'aparcar' then
                    local mn, mx = GetModelDimensions(GetEntityModel(v))
                    plazaAparcamiento = {
                        x = coords.x,
                        y = coords.y,
                        z = zSuelo,
                        w = heading,
                        largo = math.max(6.5, (mx.y - mn.y) + 1.2),
                        ancho = math.max(3.2, (mx.x - mn.x) + 1.0)
                    }
                end

                checkpoints[#checkpoints + 1] = punto

                -- Poner blip en el mapa
                local blipId = 'ae_cp_' .. #checkpoints
                OrigenMapa.Poner(blipId, {
                    x = coords.x, y = coords.y, z = zSuelo,
                    cat = 'eventos',
                    icono = accionActual == 'aparcar' and 'bandera' or 'cono',
                    nombre = ('#%d %s (%d km/h)'):format(#checkpoints, ObtenerAccionInfo(accionActual).label, math.floor(limiteActual)),
                    pulso = false
                })
                blipsGrabacion[#blipsGrabacion + 1] = blipId

                PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
                A.Aviso(('Checkpoint #%d colocado: %s.'):format(#checkpoints, ObtenerAccionInfo(accionActual).label), 'success', 2500)
                ActualizarHudGrabacion()
            end

            -- [BACKSPACE] Deshacer último checkpoint
            if IsControlJustPressed(0, 194) then
                if #checkpoints > 0 then
                    local ultimoBlip = blipsGrabacion[#blipsGrabacion]
                    if ultimoBlip then OrigenMapa.Quitar(ultimoBlip) end
                    table.remove(blipsGrabacion)
                    table.remove(checkpoints)

                    PlaySoundFrontend(-1, 'CANCEL', 'HUD_FREEMODE_SOUNDSET', true)
                    A.Aviso('Último checkpoint eliminado.', 'inform', 2000)
                    ActualizarHudGrabacion()
                end
            end

            -- [X] Cancelar Grabación
            if IsControlJustPressed(0, 73) then
                CancelarGrabacion('Grabación cancelada por el usuario.')
                break
            end

            -- [ENTER] Guardar y Finalizar
            if IsControlJustPressed(0, 191) then
                if #checkpoints < 2 then
                    A.Aviso('Necesitas al menos 2 checkpoints para crear una ruta válida.', 'error', 4000)
                else
                    local distanciaTotal = CalcularDistanciaRuta(checkpoints)
                    local payload = {
                        carnet = datosRuta.carnet,
                        nombre = datosRuta.nombre,
                        descripcion = datosRuta.descripcion,
                        puntos = checkpoints,
                        plaza = plazaAparcamiento,
                        distancia = math.floor(distanciaTotal)
                    }

                    local resp = lib.callback.await('origen_autoescuela:admin:guardarRuta', false, payload)
                    if resp and resp.ok then
                        A.Aviso(('¡Ruta "%s" guardada con éxito (%d checkpoints)!'):format(datosRuta.nombre, #checkpoints), 'success', 6000)
                        PlaySoundFrontend(-1, 'RANK_UP', 'HUD_AWARDS', true)
                    else
                        A.Aviso('Error al guardar la ruta en base de datos: ' .. (resp and resp.mensaje or 'desconocido'), 'error', 5000)
                    end

                    grabando = false
                    datosRuta = nil
                    checkpoints = {}
                    plazaAparcamiento = nil
                    LimpiarBlipsGrabacion()
                    SendNUIMessage({ accion = 'autoescuela:hudGrabacion:ocultar' })
                    break
                end
            end

            -- Renderizado 3D de checkpoints colocados
            for i = 1, #checkpoints do
                local cp = checkpoints[i]
                local info = ObtenerAccionInfo(cp.accion)
                local col = info.color
                local rad = cp.radio or 12.0

                -- Cilindro de radio
                DrawMarker(1, cp.x, cp.y, cp.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    rad * 2.0, rad * 2.0, 2.5,
                    col[1], col[2], col[3], 90,
                    false, false, 2, false, nil, nil, false)

                -- Aro a ras de suelo
                DrawMarker(25, cp.x, cp.y, cp.z + 0.04,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    rad * 2.0, rad * 2.0, 0.5,
                    col[1], col[2], col[3], 180,
                    false, false, 2, false, nil, nil, false)

                -- Flecha indicadora flotante
                DrawMarker(2, cp.x, cp.y, cp.z + 2.8,
                    0.0, 0.0, 0.0,
                    180.0, 0.0, 0.0,
                    1.4, 1.4, 1.4,
                    col[1], col[2], col[3], 220,
                    true, true, 2, false, nil, nil, false)

                -- Textos flotantes
                DibujarTexto3D(cp.x, cp.y, cp.z + 3.8, ('#%d · %s'):format(i, info.label), col[1], col[2], col[3], 0.38)
                DibujarTexto3D(cp.x, cp.y, cp.z + 3.4, ('LÍMITE: %d KM/H · R: %.0fM'):format(math.floor(cp.limite or 50), rad), 220, 221, 224, 0.30)
            end

            -- Líneas conectoras entre checkpoints
            if #checkpoints > 1 then
                for i = 1, #checkpoints - 1 do
                    local p1 = checkpoints[i]
                    local p2 = checkpoints[i + 1]
                    DrawLine(p1.x, p1.y, p1.z + 0.5, p2.x, p2.y, p2.z + 0.5, 220, 221, 224, 180)
                end
            end

            -- Previsualización bajo el vehículo actual
            local vPos = GetEntityCoords(v)
            local vZ = A.Suelo(vPos.x, vPos.y, vPos.z + 2.0) or vPos.z
            local infoAct = ObtenerAccionInfo(accionActual)
            local colAct = infoAct.color
            DrawMarker(25, vPos.x, vPos.y, vZ + 0.04,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                radioActual * 2.0, radioActual * 2.0, 0.3,
                colAct[1], colAct[2], colAct[3], 70,
                false, false, 2, false, nil, nil, false)

            Wait(sleep)
        end
    end)
end)

-- =========================================================================
-- SINCRONIZACIÓN DE RUTAS EN EL CLIENTE
-- =========================================================================

RegisterNetEvent('origen_autoescuela:client:syncRutas', function(rutasPorCarnet)
    if not rutasPorCarnet then return end
    Auto.RutasActivas = Auto.RutasActivas or {}
    for carnet, lista in pairs(rutasPorCarnet) do
        Auto.RutasActivas[carnet] = lista
        local ex = Config.Examenes[carnet]
        if ex then
            if #lista > 0 then
                -- Prevalecen las rutas de BD configuradas por el usuario
                if Config.RutaDe then
                    Config.RutaDe[carnet] = nil
                end
                ex.variantes = {}
                ex.recorridos = {}
                for _, r in ipairs(lista) do
                    local puntosRuta = {}
                    for _, p in ipairs(r.puntos or {}) do
                        puntosRuta[#puntosRuta + 1] = {
                            pos = vec3(p.x + 0.0, p.y + 0.0, p.z + 0.0),
                            heading = p.heading or 0.0,
                            radio = p.radio or 12.0,
                            limite = p.limite or Config.Limite,
                            accion = p.accion or (p.stop and 'stop') or 'normal',
                            stop = p.accion == 'stop' or p.stop == true,
                            giro = p.accion == 'giro_izq' and 'izq' or (p.accion == 'giro_der' and 'der' or nil)
                        }
                    end

                    local varId = r.varId or ('db_' .. tostring(r.id))
                    if carnet == 'coche' then
                        ex.variantes[varId] = Auto.Circuito({
                            ruta = puntosRuta,
                            cinturon = true,
                            emergenciaEn = math.max(1, math.floor(#puntosRuta * 0.6)),
                            hola = 'Buenas, {nombre}. Soy tu examinador. Cinturón, espejos y arranca cuando estés. Si tienes que dejarlo, pulsa F9 y lo cancelamos.',
                            plaza = r.plaza
                        })
                    elseif carnet == 'moto' then
                        ex.variantes[varId] = Auto.Circuito({
                            ruta = puntosRuta,
                            cinturon = false,
                            hasta = #puntosRuta,
                            emergenciaEn = math.max(1, math.floor(#puntosRuta * 0.35)),
                            marchaAtras = false,
                            hola = '{nombre}, en moto se mira dos veces antes de cada cambio. Arranca cuando quieras. Si tienes que dejarlo, pulsa F9.',
                            plaza = r.plaza
                        })
                    elseif carnet == 'camion' then
                        ex.variantes[varId] = Auto.Circuito({
                            ruta = puntosRuta,
                            cinturon = true,
                            limite = 40.0,
                            emergenciaEn = math.max(1, math.floor(#puntosRuta * 0.5)),
                            hola = '{nombre}, esto pesa diez veces más que un coche: anticipa y abre los giros. Si tienes que dejarlo, pulsa F9.',
                            plaza = r.plaza
                        })
                    end

                    ex.recorridos[#ex.recorridos + 1] = varId
                end
                ex.etapas = ex.recorridos[1] and ex.variantes[ex.recorridos[1]] or {}
            else
                Auto.ArmarCarnetDefault(carnet, true)
            end
        end
    end
end)

CreateThread(function()
    Wait(2000)
    local ok, rutas = pcall(function() return lib.callback.await('origen_autoescuela:admin:getRutasActivas', false) end)
    if ok and rutas then
        TriggerEvent('origen_autoescuela:client:syncRutas', rutas)
    end
end)
