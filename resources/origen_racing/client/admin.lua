-- ========================================
-- CLIENTE: ADMIN PANEL
-- ========================================

local adminPanelOpen = false
local drawingMode = false

--- Para que el hub y el panel de crew no se abran a mitad de grabar un
--- circuito: cogerian el raton encima de la grabacion (main.lua, crews.lua).
function GrabandoCircuito()
    return drawingMode == true
end
local drawingCheckpoints = {}
local checkpointBlips = {} -- Blips en el minimapa
local checkpointRadius = 10.0 -- Radio del checkpoint (ajustable)

-- ========================================
-- VARS PARA PREVIEW DE PROPS DELIMITADORES
-- ========================================
--[[ La decoracion de muestra de la grabacion, checkpoint a checkpoint
     ([indice] = lista de Decoracion). Solo de los ultimos VENTANA_GRABACION:
     grabando se esta siempre junto al ultimo, y antes se quitaba y se volvia
     a poner la de TODOS los checkpoints en cada tecla —en un circuito de 60
     puntos, 120 props borrados y creados por pulsar E—. ]]
local previewPorCp = {}
local VENTANA_GRABACION = 6
--[[ Editar puntos mientras se graba (14/10):
       seleccionado   el punto en el que esta el coche (dentro de su radio)
       recienMarcado  el que se acaba de marcar: no cuenta como seleccionado
                      hasta salir de el, o las flechas cambiarian ese en vez
                      del radio del siguiente
       insertarTras   modo «añadir detras»: cada E mete el punto despues de
                      este indice en vez de al final ]]
local seleccionado, recienMarcado, insertarTras = nil, nil, nil
local PREVIEW_CERCA, PREVIEW_LEJOS = 150.0, 220.0   -- la vista previa, en los puntos que hay cerca
local checkpointDeco = nil  -- id del estilo de decoracion con el que se marca (Config.CheckpointDelimiters.Estilos)
local DISTANCIA_DIBUJO = 300.0   -- los cilindros y numeros, solo de los cercanos

-- ========================================
-- ABRIR PANEL ADMIN
-- ========================================

-- Abre el panel admin desde evento de red (ej. comando /racingadmin si quedara alguno)
RegisterNetEvent('racing:openAdminPanel', function()
    if adminPanelOpen then return end
    adminPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdminPanel' })
end)

-- Export para origen_hub — se llama como exports['origen_racing']:openManagement()
-- El hub ya validó permisos antes de llamar al export
exports('openManagement', function()
    if adminPanelOpen then return end
    adminPanelOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openAdminPanel' })
end)

-- ========================================
-- CALLBACKS NUI
-- ========================================

RegisterNUICallback('closeAdminPanel', function(data, cb)
    local estabaAbierto = adminPanelOpen
    adminPanelOpen = false
    -- Al entrar a amueblar el panel se cierra, pero el raton se lo queda el
    -- editor: soltarlo aqui lo dejaria sin poder pulsar nada.
    if not (Amueblar and Amueblar.Activo()) then
        SetNuiFocus(false, false)
    end

    -- Solo resetear si NO está grabando
    if not drawingMode then
        drawingCheckpoints = {}
    end

    cb('ok')

    --[[ ESC (o el aspa): si el panel se abrió desde la pestaña Scripts del
         admin, se vuelve a ella. No al esconderse para grabar un circuito o
         amueblarlo, ni cuando ya estaba cerrado (ratón soltado a la fuerza).
         origen_admin solo vuelve si este panel salió de su lista. ]]
    if estabaAbierto and not drawingMode and not (Amueblar and Amueblar.Activo())
        and GetResourceState('origen_admin') == 'started' then
        SetTimeout(80, function()
            pcall(function() exports['origen_admin']:ReturnToScripts() end)
        end)
    end
end)

--[[ Si el vigilante comun suelta el raton a la fuerza con el panel delante,
     el panel se va con el: si no, quedaba pintado sin raton y con
     adminPanelOpen en true, y no se volvia a abrir. ]]
OrigenFoco.AlSoltar(function()
    if not adminPanelOpen then return end
    adminPanelOpen = false
    SendNUIMessage({ action = 'closeAdminPanel' })
end)

RegisterNUICallback('reopenAdminPanel', function(data, cb)
    adminPanelOpen = true
    SetNuiFocus(true, true)
    cb('ok')
end)

RegisterNUICallback('admin:getCircuits', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:getCircuits')
end)

RegisterNUICallback('admin:createCircuit', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:createCircuit', data)
end)

RegisterNUICallback('admin:updateCircuit', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:updateCircuit', data)
end)

RegisterNUICallback('admin:deleteCircuit', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:deleteCircuit', data and data.id)
end)

RegisterNUICallback('admin:toggleCircuit', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:toggleCircuit', data and data.id, data and data.enabled)
end)

RegisterNUICallback('admin:getCircuitStats', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:getCircuitStats', data and data.id)
end)

-- ========================================
-- SISTEMA DE GRABACIÓN DE CIRCUITO (CONDUCIENDO)
-- ========================================

-- Variables para datos del circuito
local circuitName = nil
local circuitDescription = nil
local editCircuitId = nil  -- Cuando se re-graban checkpoints de un circuito existente

RegisterNUICallback('admin:renameCircuit', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:renameCircuit', data)
end)

--[[ Amueblar: colocar el lobby (muebles y plazas) y los potenciadores del
     modo arcade de un circuito que ya existe. El editor es client/amueblar.lua. ]]
RegisterNUICallback('admin:amueblar', function(data, cb)
    local id = tonumber(data and data.id)
    if not id or drawingMode then cb({ success = false }) return end

    adminPanelOpen = false
    SetNuiFocus(false, false)
    cb({ success = true })
    SendNUIMessage({ action = 'closeAdminPanel' })

    Amueblar.Empezar(id, data.name)
end)

local esPropuesta = false   -- la grabacion en curso es una propuesta de un jugador

--[[ Probar un circuito desde el panel: te lleva a la salida con tu coche y
     corre una vuelta en solitario, sin carrera de servidor. Sirve igual para
     uno en revision que para uno apagado. Lo que pasa en la prueba no cuenta
     para nada: el servidor ignora los eventos de una carrera que no existe. ]]
RegisterNUICallback('admin:probarCircuito', function(data, cb)
    local id = tonumber(data and data.id)
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if not id then cb({ success = false }) return end
    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= PlayerPedId() then
        lib.notify({ title = 'Racing', description = 'Súbete a un coche para probar el circuito', type = 'error' })
        cb({ success = false })
        return
    end

    local ok, r = pcall(lib.callback.await, 'racing:admin:getCircuitCheckpoints', false, { circuitId = id })
    if not ok then r = nil end
    if not r or not r.success or not r.checkpoints or #r.checkpoints == 0 then
        lib.notify({ title = 'Racing', description = 'Ese circuito no tiene checkpoints', type = 'error' })
        cb({ success = false })
        return
    end

    adminPanelOpen = false
    SetNuiFocus(false, false)
    cb({ success = true })
    SendNUIMessage({ action = 'closeAdminPanel' })

    local puntos = {}
    for i, cp in ipairs(r.checkpoints) do
        puntos[i] = {
            checkpoint_order = i - 1,
            coord_x = cp.x, coord_y = cp.y, coord_z = cp.z,
            heading = cp.heading, radius = cp.radius, deco = cp.deco,
        }
    end

    --[[ Llevarle a la salida antes de la cuenta atras. Puede estar en la otra
         punta del mapa: sin el suelo cargado ColocarEnParrilla no encuentra
         la altura y el coche cae o se queda en el aire. A negro mientras. ]]
    local salida = puntos[1]
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(0) end
    SetEntityCoordsNoOffset(veh, salida.coord_x, salida.coord_y, salida.coord_z + 1.0, false, false, false)
    FreezeEntityPosition(veh, true)
    local hasta = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(veh) and GetGameTimer() < hasta do
        RequestCollisionAtCoord(salida.coord_x, salida.coord_y, salida.coord_z)
        Wait(0)
    end
    DoScreenFadeIn(500)

    local yo = GetPlayerServerId(PlayerId())
    lib.notify({
        title = 'Prueba de circuito',
        description = 'Una vuelta en solitario. Para dejarlo a medias: /finprueba',
        type = 'inform', duration = 8000,
    })
    TriggerEvent('racing:startRaceCountdown', {
        raceId = -1,
        raceName = 'PRUEBA · ' .. tostring(data.name or 'Circuito'),
        circuitName = tostring(data.name or 'Circuito'),
        circuitId = id,
        totalLaps = 1,
        raceType = 'circuit',
        checkpoints = puntos,
        participants = { { serverId = yo, identifier = 'prueba', playerName = GetPlayerName(PlayerId()) } },
        totalParticipants = 1,
        collisionsEnabled = true,
        ghostMode = false,
        prueba = true,
    })
end)

-- Valoraciones y circuito de la semana (server/valoraciones.lua)
RegisterNUICallback('racing:valoraciones:ficha', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:valoraciones:ficha', data)
end)
RegisterNUICallback('racing:valoraciones:votar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:valoraciones:votar', data)
end)
-- Concesionario de crew (server/crew_nivel.lua)
RegisterNUICallback('admin:conce:lista', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:conce:lista', data)
end)
RegisterNUICallback('admin:conce:guardar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:conce:guardar', data)
end)
RegisterNUICallback('admin:conce:borrar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:conce:borrar', data)
end)
-- Soporte desde el admin (server/admin_soporte.lua): mismo nombre en la NUI sin «racing:»
for _, nombre in ipairs({
    'admin:piloto:buscar', 'admin:piloto:ficha', 'admin:piloto:respeto', 'admin:piloto:pase', 'admin:piloto:reto', 'admin:piloto:pago',
    'admin:carreras', 'admin:carrera:cancelar', 'admin:carrera:anular',
    'admin:territorio:historial', 'admin:territorio:dueno', 'admin:guerras', 'admin:guerra:cancelar',
    'admin:crew:ficha', 'admin:crew:caja', 'admin:crew:respeto', 'admin:resumen',
}) do
    RegisterNUICallback(nombre, function(data, cb)
        ContestarDesdeServidor(cb, 'racing:' .. nombre, data)
    end)
end

-- Registro de cambios de admin (server/registro_admin.lua)
RegisterNUICallback('admin:registro:lista', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:registro:lista', data)
end)
-- Ajustes del juego (server/ajustes.lua)
RegisterNUICallback('admin:ajustes:leer', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ajustes:leer', data)
end)
RegisterNUICallback('admin:ajustes:guardar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ajustes:guardar', data)
end)
RegisterNUICallback('admin:ajustes:restaurar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:ajustes:restaurar', data)
end)
RegisterNUICallback('admin:conce:importar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:conce:importar', data)
end)
RegisterNUICallback('admin:clases:porDefecto', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:classes:porDefecto', data)
end)
RegisterNUICallback('admin:temporada:cerrar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:temporada:cerrar', data)
end)
RegisterNUICallback('admin:semana', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:semana', data)
end)
RegisterNUICallback('admin:semana:fijar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:semana:fijar', data)
end)

RegisterCommand('finprueba', function()
    TriggerEvent('racing:finPrueba')
end, false)

RegisterNUICallback('startRecording', function(data, cb)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    if vehicle == 0 then
        lib.notify({
            title = 'Racing',
            description = 'Necesitas estar en un vehículo para crear un circuito',
            type = 'error'
        })
        cb({ success = false, message = 'No estás en un vehículo' })
        return
    end

    -- Guardar datos del circuito
    circuitName = data.name or "Circuito Sin Nombre"
    circuitDescription = data.description or ""
    editCircuitId = data.editCircuitId or nil  -- nil = crear nuevo, número = actualizar existente
    -- Grabado desde la tablet por un jugador: al acabar no se publica, se
    -- manda a revision (server/admin.lua, racing:proponer:guardar).
    esPropuesta = data.propuesta == true
    if esPropuesta then
        editCircuitId = nil
        CloseTabletAnimation()
        SendNUIMessage({ action = 'closeRacingHub' })
    end

    -- Activar modo grabación
    drawingMode = true
    drawingCheckpoints = {}
    checkpointRadius = 10.0
    ClearCheckpointBlips()
    ClearDelimiterPreviewProps() -- limpiar cualquier preview anterior

    -- La decoracion con la que se empieza: la de serie.
    checkpointDeco = Decoracion.PorDefecto()
    seleccionado, recienMarcado, insertarTras = nil, nil, nil

    --[[ Editar un circuito que ya existe: antes se empezaba de cero y habia
         que regrabarlo entero para tocar un punto. Ahora salen sus puntos y se
         editan (mover, quitar, meter otros: mas abajo). ]]
    if editCircuitId then
        local ok, r = pcall(lib.callback.await, 'racing:admin:getCircuitCheckpoints', false, { circuitId = editCircuitId })
        if ok and r and r.success and type(r.checkpoints) == 'table' then
            for _, cp in ipairs(r.checkpoints) do
                drawingCheckpoints[#drawingCheckpoints + 1] = {
                    x = cp.x, y = cp.y, z = cp.z, heading = tonumber(cp.heading) or 0.0,
                    radius = tonumber(cp.radius) or 10.0, deco = cp.deco,
                }
            end
            local ultimo = drawingCheckpoints[#drawingCheckpoints]
            if ultimo and ultimo.deco then checkpointDeco = ultimo.deco end
            RehacerBlips()
        end
    end

    -- Cerrar NUI y liberar controles
    adminPanelOpen = false
    SetNuiFocus(false, false)

    -- Responder al NUI
    cb({ success = true })

    -- Enviar al NUI para mostrar los controles
    SendNUIMessage({
        action = 'startRecording',
        data = {
            maxCheckpoints = Config.Circuits.MaxCheckpoints,
            currentRadius = checkpointRadius,
            currentDeco = Decoracion.Estilo(checkpointDeco) and Decoracion.Estilo(checkpointDeco).label or '',
            checkpointCount = #drawingCheckpoints
        }
    })

    -- Cerrar panel admin en el siguiente frame
    CreateThread(function()
        Wait(100)
        SendNUIMessage({ action = 'closeAdminPanel' })
    end)

    lib.notify({
        title = '🎬 Grabando: ' .. circuitName,
        description = 'Presiona E para marcar checkpoints',
        type = 'success',
        duration = 5000
    })
end)

RegisterNUICallback('cancelRecording', function(data, cb)
    drawingMode = false
    drawingCheckpoints = {}
    circuitName = nil
    circuitDescription = nil
    editCircuitId = nil
    ClearCheckpointBlips()
    ClearDelimiterPreviewProps()
    SetNuiFocus(false, false)

    SendNUIMessage({ action = 'recordingCancelled' })

    cb('ok')
end)

RegisterNUICallback('finishRecording', function(data, cb)
    if #drawingCheckpoints < Config.Circuits.MinCheckpoints then
        lib.notify({
            title = 'Racing',
            description = 'Necesitas al menos ' .. Config.Circuits.MinCheckpoints .. ' checkpoints',
            type = 'error'
        })
        cb({ success = false })
        return
    end

    -- Enviar checkpoints al NUI
    local totalDistance = CalculateCircuitDistance(drawingCheckpoints)

    cb({
        success = true,
        checkpoints = drawingCheckpoints,
        distance = totalDistance
    })

    drawingMode = false
    drawingCheckpoints = {}
    ClearDelimiterPreviewProps()
end)

local xPulsadaDesde = 0   -- la X de descartar, mantenida desde

--[[ El modo creador: mientras se graba un circuito no se ve el minimapa
     (origen_map, que lo devuelve solo si este recurso se para) ni el panel de
     misiones (origen_quests escucha 'origen_racing:enCreador'). Se mira el
     cambio de drawingMode en el hilo de abajo: la grabacion se acaba por
     cinco caminos (meta, X, salir del coche, cancelar y finalizar desde la
     NUI) y asi no hay que acordarse de ninguno. Al acabar se quitan tambien
     los props fantasma. ]]
--[[ La camara de la grabacion: con la del juego, a pegada al coche, los
     props de los lados (a radio + medio metro) se quedaban fuera de cuadro.
     La rueda del raton (o RePag / AvPag) la aleja y la acerca; del todo
     cerca es la del juego otra vez. Va detras y por encima, siguiendo el
     rumbo del coche con suavidad. ]]
local CAM_MAX, CAM_PASO = 42.0, 3.0
local camGrab, camDist = nil, 0.0
local camPos, camMira = nil, nil

local function QuitarCamaraGrabacion()
    if camGrab then
        RenderScriptCams(false, true, 400, true, false)
        DestroyCam(camGrab, false)
        camGrab = nil
    end
    camPos, camMira = nil, nil
end

local function CamaraGrabacion(vehicle)
    -- La rueda: en coche es tambien la de armas y la radio; grabando, no.
    for _, c in ipairs({ 14, 15, 16, 17, 81, 82, 99, 100, 261, 262 }) do DisableControlAction(0, c, true) end
    local alejar = IsDisabledControlJustPressed(0, 14) or IsDisabledControlJustPressed(0, 242) or IsControlJustPressed(0, 11)
    local acercar = IsDisabledControlJustPressed(0, 15) or IsDisabledControlJustPressed(0, 241) or IsControlJustPressed(0, 10)
    if alejar then camDist = math.min(CAM_MAX, camDist + CAM_PASO) end
    if acercar then camDist = math.max(0.0, camDist - CAM_PASO) end
    if camDist < CAM_PASO then
        camDist = 0.0
        QuitarCamaraGrabacion()
        return
    end

    local p = GetEntityCoords(vehicle)
    local h = math.rad(GetEntityHeading(vehicle))
    local f = vector3(-math.sin(h), math.cos(h), 0.0)
    local quiero = p - f * camDist + vector3(0.0, 0.0, 1.8 + camDist * 0.55)
    local mira = p + f * (camDist * 0.3) + vector3(0.0, 0.0, 0.6)
    -- Nunca por debajo del suelo (cuestas, curvas en un desnivel)
    local hay, suelo = GetGroundZFor_3dCoord(quiero.x, quiero.y, quiero.z + 10.0, false)
    if hay and quiero.z < suelo + 1.5 then quiero = vector3(quiero.x, quiero.y, suelo + 1.5) end

    if not camGrab then
        camGrab = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamFov(camGrab, 55.0)
        camPos, camMira = quiero, mira
        SetCamCoord(camGrab, camPos.x, camPos.y, camPos.z)
        RenderScriptCams(true, true, 400, true, false)
    end
    camPos = camPos + (quiero - camPos) * 0.12
    camMira = camMira + (mira - camMira) * 0.2
    SetCamCoord(camGrab, camPos.x, camPos.y, camPos.z)
    PointCamAtCoord(camGrab, camMira.x, camMira.y, camMira.z)
end

local enCreador = false
local function ModoCreador(si)
    if enCreador == si then return end
    enCreador = si
    pcall(function() exports.origen_map:Apartar(si) end)
    TriggerEvent('origen_racing:enCreador', si)
    if not si then
        Decoracion.Fantasma(nil)
        QuitarCamaraGrabacion()
        camDist = 0.0
        seleccionado, recienMarcado, insertarTras = nil, nil, nil
    end
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then QuitarCamaraGrabacion() end
end)

-- Thread de grabación (conduciendo)
CreateThread(function()
    while true do
        local sleep = 500

        ModoCreador(drawingMode == true)

        if drawingMode then
            sleep = 0

            -- (Aqui se soltaba el foco en cada fotograma. Ya se suelta al
            -- empezar a grabar, y cada fotograma le quitaba el raton a
            -- cualquier otra pantalla del recurso sin cerrarla. Ahora el hub
            -- y la crew no se abren mientras se graba: GrabandoCircuito.)

            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            -- Verificar que sigue en vehículo
            if vehicle == 0 then
                lib.notify({
                    title = 'Grabación Cancelada',
                    description = 'Has salido del vehículo',
                    type = 'error'
                })
                drawingMode = false
                drawingCheckpoints = {}
                circuitName = nil
                circuitDescription = nil
                editCircuitId = nil

                -- Limpiar blips y props
                ClearCheckpointBlips()
                ClearDelimiterPreviewProps()

                SetNuiFocus(false, false)
                SendNUIMessage({ action = 'recordingCancelled' })
                goto continue
            end

            -- La camara: la rueda la aleja y la acerca
            CamaraGrabacion(vehicle)

            --[[ EDITAR PUNTOS. El punto en el que esta el coche queda
                 seleccionado (en blanco): las flechas cambian SU radio y SU
                 decoracion, G lo mueve aqui, Supr lo quita e Ins abre el modo
                 «añadir detras» (cada E mete un punto despues de el). ]]
            do
                local c = GetEntityCoords(vehicle)
                local function dist(cp) return #(vector2(cp.x, cp.y) - vector2(c.x, c.y)) end
                if recienMarcado then
                    local cp = drawingCheckpoints[recienMarcado]
                    if not cp or dist(cp) > math.max(cp.radius or 10.0, 4.0) then recienMarcado = nil end
                end
                local sel, mejor = nil, math.huge
                for i, cp in ipairs(drawingCheckpoints) do
                    if i ~= recienMarcado then
                        local d = dist(cp)
                        if d < math.max(cp.radius or 10.0, 4.0) and d < mejor then sel, mejor = i, d end
                    end
                end
                if sel ~= seleccionado then
                    seleccionado = sel
                    SendNUIMessage({ action = 'updateRecording', data = {
                        seleccionado = sel or 0,
                        currentRadius = sel and drawingCheckpoints[sel].radius or checkpointRadius,
                    } })
                end

                -- G, Supr e Ins: grabando no hacen lo suyo del juego
                DisableControlAction(0, 47, true)
                DisableControlAction(0, 178, true)
                DisableControlAction(0, 121, true)

                if seleccionado and IsDisabledControlJustPressed(0, 47) then
                    -- Mover el punto aqui, con el rumbo del coche
                    local cp = drawingCheckpoints[seleccionado]
                    cp.x, cp.y, cp.z, cp.heading = c.x, c.y, c.z, GetEntityHeading(vehicle)
                    recienMarcado = seleccionado
                    QuitarPreviewDe(seleccionado)
                    RehacerBlips()
                    CreateThread(RepasarPreviews)
                    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
                    lib.notify({ title = 'Punto #' .. seleccionado, description = 'Movido aquí', type = 'success', duration = 2000 })
                elseif seleccionado and IsDisabledControlJustPressed(0, 178) then
                    -- Quitar el punto
                    local quitado = seleccionado
                    table.remove(drawingCheckpoints, quitado)
                    if insertarTras and insertarTras >= quitado then
                        insertarTras = insertarTras > 1 and insertarTras - 1 or nil
                    end
                    seleccionado, recienMarcado = nil, nil
                    ClearDelimiterPreviewProps()
                    RehacerBlips()
                    CreateThread(RepasarPreviews)
                    PlaySoundFrontend(-1, "CANCEL", "HUD_FREEMODE_SOUNDSET", 1)
                    lib.notify({ title = 'Punto #' .. quitado, description = 'Quitado', type = 'inform', duration = 2000 })
                    SendNUIMessage({ action = 'updateRecording', data = {
                        checkpointCount = #drawingCheckpoints, seleccionado = 0, insertando = insertarTras or 0,
                        currentRadius = checkpointRadius,
                    } })
                elseif IsDisabledControlJustPressed(0, 121) then
                    -- Modo «añadir detras»: se abre en el seleccionado y se cierra con otra Ins
                    if insertarTras then
                        insertarTras = nil
                    elseif seleccionado then
                        insertarTras = seleccionado
                    end
                    PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                    SendNUIMessage({ action = 'updateRecording', data = { insertando = insertarTras or 0 } })
                end
            end

            --[[ Flechas arriba / abajo: el radio del PROXIMO checkpoint.

                 Antes cambiaban el del ultimo ya marcado: ponias uno a 20 m,
                 bajabas el radio pensando en el siguiente y el de 20 m se
                 encogia por detras. Ahora lo puesto no se toca; las guias de
                 delante del coche ya enseñan el ancho que va a tener el
                 siguiente. Para corregir uno: RETROCESO y volver a marcarlo. ]]
            do
                local paso = (IsControlJustPressed(0, 172) and 1.0) or (IsControlJustPressed(0, 173) and -1.0) or 0.0
                if paso ~= 0.0 and seleccionado then
                    -- Con un punto seleccionado, su radio
                    local cp = drawingCheckpoints[seleccionado]
                    cp.radius = math.max(3.0, math.min(30.0, (cp.radius or 10.0) + paso))
                    QuitarPreviewDe(seleccionado)
                    CreateThread(RepasarPreviews)
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                    SendNUIMessage({ action = 'updateRecording', data = { currentRadius = cp.radius } })
                elseif paso ~= 0.0 then
                    checkpointRadius = math.max(3.0, math.min(30.0, checkpointRadius + paso))
                    PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                    SendNUIMessage({
                        action = 'updateRecording',
                        data = {
                            currentRadius = checkpointRadius,
                            checkpointCount = #drawingCheckpoints
                        }
                    })
                end
            end

            --[[ Flechas izquierda / derecha: la decoracion.

                 Cambia la del ULTIMO checkpoint —igual que las de arriba y
                 abajo cambian su radio— y es la que llevaran los siguientes
                 hasta que se cambie otra vez. Asi se graba un tramo entero con
                 conos sin tocar nada y se pone humo solo en la meta. ]]
            local paso = (IsControlJustPressed(0, 175) and 1) or (IsControlJustPressed(0, 174) and -1) or 0
            if paso ~= 0 then
                local base = seleccionado and drawingCheckpoints[seleccionado].deco or checkpointDeco
                checkpointDeco = Decoracion.Siguiente(base, paso)
                local estilo = Decoracion.Estilo(checkpointDeco)

                -- La del punto seleccionado o, sin ninguno, la del ultimo
                local cual = seleccionado or #drawingCheckpoints
                if cual > 0 then
                    drawingCheckpoints[cual].deco = checkpointDeco
                    QuitarPreviewDe(cual)
                    PonerPreviewDe(cual)
                end

                PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
                SendNUIMessage({
                    action = 'updateRecording',
                    data = { currentDeco = estilo and estilo.label or '' }
                })
            end

            --[[ Las guias: por donde quedarian los lados del checkpoint si se
                 marcase AHORA, pegadas al coche. Antes el ancho solo se veia
                 despues de marcar. 14/10: a los lados van los props del estilo
                 elegido, de verdad y algo transparentes, con su humo si lo
                 lleva (Decoracion.Fantasma). Ya no hay postes rosas: desde que
                 no existe «Sin nada» todo estilo tiene props. La linea del
                 ancho se queda. ]]
            do
                local c = GetEntityCoords(vehicle)
                local rumbo = GetEntityHeading(vehicle)
                local lx, ly, rx, ry = Decoracion.Lados({ x = c.x, y = c.y, heading = rumbo, radius = checkpointRadius })
                Decoracion.Fantasma({
                    x = c.x, y = c.y, z = c.z, heading = rumbo, radius = checkpointRadius, deco = checkpointDeco,
                })
                DrawLine(lx, ly, c.z - 0.3, rx, ry, c.z - 0.3, 216, 27, 85, 220)
            end

            -- E para colocar checkpoint. En coche la E es tambien el claxon:
            -- grabando, el claxon calla.
            DisableControlAction(0, 86, true)
            if IsControlJustPressed(0, 38) then
                if vehicle == 0 then
                    lib.notify({
                        title = 'Racing',
                        description = 'Debes estar en un vehículo',
                        type = 'error'
                    })
                elseif #drawingCheckpoints >= Config.Circuits.MaxCheckpoints then
                    lib.notify({
                        title = 'Límite Alcanzado',
                        description = 'Máximo ' .. Config.Circuits.MaxCheckpoints .. ' checkpoints',
                        type = 'error'
                    })
                else
                    local coords = GetEntityCoords(vehicle)
                    local heading = GetEntityHeading(vehicle)

                    if insertarTras then
                        -- Modo «añadir detras»: va despues de ese punto, y el
                        -- siguiente E despues de este (se meten en orden)
                        insertarTras = math.min(insertarTras, #drawingCheckpoints) + 1
                        table.insert(drawingCheckpoints, insertarTras, {
                            x = coords.x, y = coords.y, z = coords.z, heading = heading,
                            radius = checkpointRadius, deco = checkpointDeco,
                        })
                        recienMarcado = insertarTras
                        ClearDelimiterPreviewProps()
                        RehacerBlips()
                        CreateThread(RepasarPreviews)
                        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
                        lib.notify({ title = '✅ Checkpoint #' .. insertarTras, description = 'Metido detrás del #' .. (insertarTras - 1), type = 'success', duration = 2000 })
                        SendNUIMessage({ action = 'updateRecording', data = {
                            checkpointCount = #drawingCheckpoints, insertando = insertarTras,
                        } })
                        goto marcado
                    end

                    table.insert(drawingCheckpoints, {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                        heading = heading,
                        radius = checkpointRadius,
                        deco = checkpointDeco
                    })

                    -- Crear blip enumerado
                    local blip = 'checkpoint_' .. #drawingCheckpoints
                    OrigenMapa.Poner(blip, {
                        x = coords.x, y = coords.y, z = coords.z,
                        cat = 'racing',
                        nombre = "Checkpoint #" .. #drawingCheckpoints,
                    })
                    table.insert(checkpointBlips, blip)

                    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)

                    -- La decoracion del nuevo (la de los demas la pone y la quita
                    -- RepasarPreviews segun lo cerca que esten)
                    PonerPreviewDe(#drawingCheckpoints)
                    recienMarcado = #drawingCheckpoints

                    lib.notify({
                        title = '✅ Checkpoint #' .. #drawingCheckpoints,
                        description = 'Radio: ' .. checkpointRadius .. 'm',
                        type = 'success',
                        duration = 2000
                    })

                    SendNUIMessage({
                        action = 'updateRecording',
                        data = {
                            checkpointCount = #drawingCheckpoints,
                            currentRadius = checkpointRadius
                        }
                    })
                    ::marcado::
                end
            end

            -- BACKSPACE para eliminar último checkpoint (en el modo «añadir
            -- detras», solo cierra ese modo: no borra el ultimo del circuito)
            if IsControlJustPressed(0, 194) and insertarTras then
                insertarTras = nil
                PlaySoundFrontend(-1, "CANCEL", "HUD_FREEMODE_SOUNDSET", 1)
                SendNUIMessage({ action = 'updateRecording', data = { insertando = 0 } })
            elseif IsControlJustPressed(0, 194) then
                if #drawingCheckpoints > 0 then
                    -- Eliminar blip
                    local lastBlip = checkpointBlips[#checkpointBlips]
                    if lastBlip then
                        OrigenMapa.Quitar(lastBlip)
                    end
                    table.remove(checkpointBlips)

                    -- Eliminar checkpoint (y su decoracion)
                    QuitarPreviewDe(#drawingCheckpoints)
                    table.remove(drawingCheckpoints)

                    -- El radio elegido se queda como esta: es el del siguiente.
                    if #drawingCheckpoints > 0 and drawingCheckpoints[#drawingCheckpoints].deco then
                        checkpointDeco = drawingCheckpoints[#drawingCheckpoints].deco
                    end

                    if recienMarcado and recienMarcado > #drawingCheckpoints then recienMarcado = nil end

                    PlaySoundFrontend(-1, "CANCEL", "HUD_FREEMODE_SOUNDSET", 1)

                    SendNUIMessage({
                        action = 'updateRecording',
                        data = {
                            checkpointCount = #drawingCheckpoints,
                            currentRadius = checkpointRadius
                        }
                    })
                end
            end

            --[[ X para tirar la grabacion: MANTENIDA un segundo. De un toque
                 se perdia el circuito entero sin preguntar (la X esta al lado
                 de la Z y la C). ]]
            if IsControlJustPressed(0, 73) then
                xPulsadaDesde = GetGameTimer()
                lib.notify({ title = 'Grabación', description = 'Mantén X para descartar el circuito', type = 'inform', duration = 2000 })
            elseif not IsControlPressed(0, 73) then
                xPulsadaDesde = 0
            end
            if xPulsadaDesde > 0 and GetGameTimer() - xPulsadaDesde >= 1000 then
                xPulsadaDesde = 0
                drawingMode = false
                drawingCheckpoints = {}
                circuitName = nil
                circuitDescription = nil
                editCircuitId = nil
                ClearCheckpointBlips()
                ClearDelimiterPreviewProps()

                SendNUIMessage({ action = 'recordingCancelled' })

                lib.notify({
                    title = 'Grabación Cancelada',
                    description = 'Circuito descartado',
                    type = 'error',
                    duration = 3000
                })
            end

            -- ENTER para finalizar
            if IsControlJustPressed(0, 191) then
                if #drawingCheckpoints < Config.Circuits.MinCheckpoints then
                    lib.notify({
                        title = 'Racing',
                        description = 'Necesitas al menos ' .. Config.Circuits.MinCheckpoints .. ' checkpoints',
                        type = 'error'
                    })
                else
                    local totalDistance = CalculateCircuitDistance(drawingCheckpoints)

                    SendNUIMessage({
                        action = 'recordingFinished',
                        data = {
                            name = circuitName,
                            description = circuitDescription,
                            checkpoints = drawingCheckpoints,
                            distance = totalDistance,
                            editCircuitId = editCircuitId,
                            propuesta = esPropuesta
                        }
                    })

                    lib.notify({
                        title = '✅ ' .. circuitName,
                        description = #drawingCheckpoints .. ' checkpoints | ' .. math.floor(totalDistance) .. 'm',
                        type = 'success',
                        duration = 5000
                    })

                    ClearCheckpointBlips()
                    ClearDelimiterPreviewProps()
                    drawingMode = false
                    circuitName = nil
                    circuitDescription = nil
                    editCircuitId = nil
                end
            end

            -- Dibujar checkpoints colocados con los colores del admin (los cercanos)
            local aqui = GetEntityCoords(playerPed)
            for i = 1, #drawingCheckpoints do
                local cp = drawingCheckpoints[i]
                if math.abs(cp.x - aqui.x) < DISTANCIA_DIBUJO and math.abs(cp.y - aqui.y) < DISTANCIA_DIBUJO then
                local radius = cp.radius or 10.0
                -- Rosa pegatina; el de salida, más opaco que el resto. El
                -- seleccionado (el que se esta editando), en blanco.
                local color = {216, 27, 85}
                local alfa = i == 1 and 190 or 130
                if i == seleccionado then color, alfa = {235, 235, 235}, 170 end

                DrawMarker(
                    1, -- Cilindro
                    cp.x, cp.y, cp.z - 1.0,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    radius * 2, radius * 2, 3.0, -- Usar el radio del checkpoint
                    color[1], color[2], color[3], alfa,
                    false, true, 2, false, nil, nil, false
                )

                -- Número del checkpoint: chapa pegatina (rosa la salida)
                DrawText3D(cp.x, cp.y, cp.z + 2.0, '#' .. tostring(i) .. (i == seleccionado and ' · EDITAR' or ''), i == 1)
                end
            end

            -- (la decoracion se pone y se quita checkpoint a checkpoint, al
            --  añadir, quitar o cambiar uno: PonerPreviewDe / QuitarPreviewDe)
            -- No hay nada que dibujar aquí cada frame para los delimitadores.

            -- Modo «añadir detras»: el hueco donde va el punto nuevo, en blanco
            if insertarTras and drawingCheckpoints[insertarTras] then
                local c = GetEntityCoords(vehicle)
                local a = drawingCheckpoints[insertarTras]
                local b = drawingCheckpoints[insertarTras + 1]
                DrawLine(a.x, a.y, a.z + 0.5, c.x, c.y, c.z + 0.5, 255, 255, 255, 230)
                if b then DrawLine(c.x, c.y, c.z + 0.5, b.x, b.y, b.z + 0.5, 255, 255, 255, 230) end
            end

            -- Dibujar líneas entre checkpoints (rosa)
            if #drawingCheckpoints > 1 then
                for i = 1, #drawingCheckpoints - 1 do
                    local cp1 = drawingCheckpoints[i]
                    local cp2 = drawingCheckpoints[i + 1]

                    DrawLine(
                        cp1.x, cp1.y, cp1.z,
                        cp2.x, cp2.y, cp2.z,
                        216, 27, 85, 200 -- Rosa pegatina
                    )
                end

                -- Línea de regreso al inicio (para circuito) - rosa oscuro
                local firstCp = drawingCheckpoints[1]
                local lastCp = drawingCheckpoints[#drawingCheckpoints]
                DrawLine(
                    lastCp.x, lastCp.y, lastCp.z,
                    firstCp.x, firstCp.y, firstCp.z,
                    216, 27, 85, 120 -- Rosa pegatina, más tenue (cierre)
                )
            end
        end

        ::continue::
        Wait(sleep)
    end
end)

-- ========================================
-- FUNCIONES AUXILIARES
-- ========================================

-- Quita la decoracion de muestra de la grabacion (client/decoracion.lua).
function ClearDelimiterPreviewProps()
    for i, lista in pairs(previewPorCp) do
        Decoracion.Quitar(lista)
        previewPorCp[i] = nil
    end
end

--- Pone la decoracion del checkpoint `i` de la grabacion, translucida para
--- que se distinga de la de una carrera. Carga modelos: desde un hilo.
function PonerPreviewDe(i)
    if not Config.CheckpointDelimiters or not Config.CheckpointDelimiters.Enabled then return end
    local cp = drawingCheckpoints[i]
    if not cp or previewPorCp[i] then return end
    local lista = {}
    previewPorCp[i] = lista
    -- La grabación enseña lo mismo que se verá en carrera (Forzar).
    local f = Config.CheckpointDelimiters.Forzar
    local muestra = cp
    if f then
        muestra = {}
        for k, v in pairs(cp) do muestra[k] = v end
        muestra.deco = (i == 1) and (f.salida or cp.deco) or (f.normal or cp.deco)
    end
    Decoracion.Poner(lista, muestra, { alpha = 200 })
end

function QuitarPreviewDe(i)
    local lista = previewPorCp[i]
    if not lista then return end
    Decoracion.Quitar(lista)
    previewPorCp[i] = nil
end

function CalculateCircuitDistance(checkpoints)
    if #checkpoints < 2 then return 0 end

    local totalDistance = 0

    for i = 1, #checkpoints - 1 do
        local cp1 = vector3(checkpoints[i].x, checkpoints[i].y, checkpoints[i].z)
        local cp2 = vector3(checkpoints[i + 1].x, checkpoints[i + 1].y, checkpoints[i + 1].z)
        totalDistance = totalDistance + #(cp1 - cp2)
    end

    -- Cerrar el circuito (volver al inicio)
    local firstCp = vector3(checkpoints[1].x, checkpoints[1].y, checkpoints[1].z)
    local lastCp = vector3(checkpoints[#checkpoints].x, checkpoints[#checkpoints].y, checkpoints[#checkpoints].z)
    totalDistance = totalDistance + #(lastCp - firstCp)

    return math.floor(totalDistance)
end

--[[ Rótulo sobre el mundo en «pegatina»: sombra dura, canto negro fino,
     pieza gris claro (o rosa si acento) y tinta negra. ]]
function DrawText3D(x, y, z, text, acento)
    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(x, y, z)
    if not onScreen then return end
    text = (tostring(text or ''):gsub('~', ''))
    local escala = 0.42
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(text)
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
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(sx, sy - alto * 0.62)
end

function ClearCheckpointBlips()
    for _, blip in ipairs(checkpointBlips) do
                    OrigenMapa.Quitar(blip)
    end
    checkpointBlips = {}
end

--- Los blips de la grabacion otra vez, con la numeracion de ahora (al meter,
--- quitar o mover un punto cambian los numeros de los de detras).
function RehacerBlips()
    ClearCheckpointBlips()
    for i, cp in ipairs(drawingCheckpoints) do
        local blip = 'checkpoint_' .. i
        OrigenMapa.Poner(blip, { x = cp.x, y = cp.y, z = cp.z, cat = 'racing', nombre = 'Checkpoint #' .. i })
        checkpointBlips[#checkpointBlips + 1] = blip
    end
end

--[[ La vista previa de la grabacion va en los puntos que hay cerca (antes, en
     los ultimos seis: editando uno del principio no se veia). Carga modelos:
     desde un hilo. ]]
local repasando = false
function RepasarPreviews()
    if repasando or not drawingMode then return end
    repasando = true
    local aqui = GetEntityCoords(PlayerPedId())
    for i, cp in ipairs(drawingCheckpoints) do
        if not drawingMode then break end
        local d = #(vector2(cp.x, cp.y) - vector2(aqui.x, aqui.y))
        if d < PREVIEW_CERCA and not previewPorCp[i] then
            PonerPreviewDe(i)
        elseif d > PREVIEW_LEJOS and previewPorCp[i] then
            QuitarPreviewDe(i)
        end
    end
    -- Los de numeros que ya no existen (se ha quitado un punto)
    for i in pairs(previewPorCp) do
        if not drawingCheckpoints[i] then QuitarPreviewDe(i) end
    end
    repasando = false
end

CreateThread(function()
    while true do
        Wait(1000)
        if drawingMode then RepasarPreviews() end
    end
end)

-- Evento para actualizar circuitos cuando se elimina uno
RegisterNetEvent('racing:circuits:deleted', function(circuitId)
    SendNUIMessage({
        action = 'reloadCircuits'
    })
end)

-- Reiniciar los rankings del hub (server/admin.lua): el estado, reiniciar y deshacer
RegisterNUICallback('admin:rankings:estado', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:rankings:estado', data)
end)

RegisterNUICallback('admin:rankings:reiniciar', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:rankings:reiniciar', data)
end)

RegisterNUICallback('admin:rankings:deshacer', function(data, cb)
    ContestarDesdeServidor(cb, 'racing:admin:rankings:deshacer', data)
end)
