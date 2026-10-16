-- ========================================
-- CLIENTE: SISTEMA DE CARRERAS
-- ========================================

local currentRaceData = nil
local currentCheckpoint = 0
local currentLap = 1
local raceStartTime = 0
local lapStartTime = 0
local checkpointTimes = {}
local isRacing = false
local raceCheckpoints = {}
local raceCheckpointsByOrder = {}  -- Fix F: índice O(1) por checkpoint_order
local checkpointBlips = {}
local checkpointMarkerIds = {} -- IDs de origen_markers (máximo 3 a la vez)
local vehicleFrozen = false
local ghostModeActive = false -- Sistema de Ghost para sin colisiones
local alreadyInGhostZone = false

--[[ EL COCHE DE LA CARRERA: el que llevabas al volante en la salida.

     Los checkpoints solo cuentan con el. Antes contaban con cualquier coche
     que condujeras: te bajabas, cogias otro mas rapido (o uno aparcado en
     mitad del circuito) y seguias sumando. Se guarda la entidad y su netId:
     la entidad cambia si el coche sale y vuelve a entrar en tu alcance; el
     netId no. ]]
local cocheDeCarrera = nil
local cocheDeCarreraNet = 0
local cocheCongelado = nil       -- el que se congelo en la cuenta atras: se descongela ESE
local cocheFantasmaNet = 0       -- el que se apunto sin colisiones en el servidor
local tandaCarrera = 0           -- cambia en cada salida: un hilo viejo no toca la nueva

--[[ La vuelta CERRADA: en un circuito de varias vueltas, la vuelta se cierra
     al volver a cruzar la salida (el checkpoint 1), no al pasar el ultimo.
     Antes la vuelta 1 iba de la salida al ultimo punto y las demas del ultimo
     al ultimo: a la primera le faltaba el tramo del ultimo a la salida, y era
     la mas corta (y la de los records). `cierraVuelta` dice que ya se ha
     pasado el ultimo y lo que toca es la linea de salida para cerrar. ]]
local vueltaCerrada = false
local cierraVuelta = false

-- Volver al ultimo checkpoint (VolverAlCheckpoint)
local volviendo = false           -- en pleno fundido: el hilo de checkpoints no mira
local reiniciarTramo = false      -- el coche ha saltado: el tramo barrido no vale
local ultimaVuelta = 0            -- GetGameTimer() de la ultima vez (enfriamiento)
local vueltaTocada = false        -- la vuelta en curso tiene un salto: no vale de fantasma

-- El panel de resultados (AbrirResultados): uno solo y un solo hilo de Retroceso
local resultadosAbiertos = false
local resultadosTanda = 0

-- Variables para almacenar últimos datos del servidor
local lastServerData = {
    position = 1,
    totalRacers = 1,
    gapToFirst = 0,
    intervalToAhead = 0,
    leaderboard = {},
    bestLapOverall = 0,
    bestLap = 0
}

-- Variable para sync de distancia (av_racing style)
local serverSync = 0
local hudSucio = true   -- hay datos del servidor sin mandar al HUD

-- Modo fantasma (récord): grabación de trayectoria
local ghostRecordingActive = false
local currentLapFrames = {} -- { {t, x, y, z, h}, ... }
local bestLapGhostData = nil -- frames de la mejor vuelta
local bestLapTimeMs = 999999999

-- Modo fantasma (récord): reproducción del fantasma
local ghostVehicleEntity = nil
local ghostPlaybackActive = false

-- Función para resetear datos del servidor
--- ¿Hay carrera en marcha? Lo miran los hilos de los modos (client/modos.lua)
--- para recoger solos cuando se acaba, se acabe como se acabe.
function EnCarrera() return isRacing end

local function ResetServerData()
    lastServerData = {
        position = 1,
        totalRacers = 1,
        gapToFirst = 0,
        intervalToAhead = 0,
        leaderboard = {},
        bestLapOverall = 0,
        bestLap = 0
    }
end

-- ========================================
-- SISTEMA DE GHOST (Sin Colisiones)
-- ========================================

function GhostLoop()
    if ghostModeActive then return end
    ghostModeActive = true
    alreadyInGhostZone = false

    while ghostModeActive do
        local inZone = false
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local myVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

            -- Verificar que estamos en el asiento del conductor
            if GetPedInVehicleSeat(myVehicle, -1) == PlayerPedId() then
                -- Fix C: GetActivePlayers() en vez de GetGamePool('CPed') — solo jugadores, no NPCs
                local myRacing = Entity(myVehicle).state['racing']
                if myRacing then
                    for _, pid in ipairs(GetActivePlayers()) do
                        if pid ~= PlayerId() then
                            local ped = GetPlayerPed(pid)
                            local vehicle = GetVehiclePedIsIn(ped, false)
                            if vehicle and vehicle ~= 0 and Entity(vehicle).state['racing'] then
                                inZone = true
                                if not alreadyInGhostZone then
                                    SetGhostedEntityAlpha(254)
                                    SetLocalPlayerAsGhost(true)
                                end
                                break
                            end
                        end
                    end
                end
                if inZone and not alreadyInGhostZone then
                    alreadyInGhostZone = true
                end
                if not inZone and alreadyInGhostZone then
                    alreadyInGhostZone = false
                    SetGhostedEntityAlpha(254)
                    SetLocalPlayerAsGhost(false)
                end
            end
        else
            if not inZone and alreadyInGhostZone then
                alreadyInGhostZone = false
                SetGhostedEntityAlpha(254)
                SetLocalPlayerAsGhost(false)
            end
        end
        Wait(200)
    end
    -- El coche se desapunta en LimpiarCarrera, el de la carrera y no el que
    -- se lleve en ese momento.
end

function EndGhostLoop()
    ghostModeActive = false
    alreadyInGhostZone = false
    SetGhostedEntityAlpha(254)
    SetLocalPlayerAsGhost(false)
end

-- ========================================
-- GRABACIÓN GHOST (récord para modo fantasma)
-- ========================================

--- Dos decimales: un centimetro y una centesima de grado. Es lo que acaba
--- guardado en la base (JSON) y lo que se ve, y sin redondear cada numero
--- llevaba quince cifras.
local function dosDecimales(v)
    return math.floor(v * 100 + 0.5) / 100
end

function GhostRecordThread()
    currentLapFrames = {}
    bestLapGhostData = nil
    bestLapTimeMs = 999999999

    while ghostRecordingActive and isRacing do
        --[[ 10 fotogramas por segundo. La reproduccion interpola entre uno y
             otro por su tiempo (`t`), asi que se ve igual de suave; y es la
             mitad de lo que viaja al servidor y se guarda con el record. ]]
        Wait(100)

        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
            -- Tope de 3600 fotogramas (6 min por vuelta a 10 fps); el servidor admite 4000.
            if #currentLapFrames < 3600 then
                local coords = GetEntityCoords(veh)
                currentLapFrames[#currentLapFrames + 1] = {
                    t = GetGameTimer() - lapStartTime,
                    x = dosDecimales(coords.x), y = dosDecimales(coords.y), z = dosDecimales(coords.z),
                    h = dosDecimales(GetEntityHeading(veh)),
                    p = dosDecimales(GetEntityPitch(veh)),
                    r = dosDecimales(GetEntityRoll(veh)),
                }
            end
        end
    end

    ghostRecordingActive = false
end

--- Lo que dura la vuelta del record que se esta viendo de fantasma (el
--- tiempo de su ultimo fotograma), o nil si no hay fantasma.
local function TiempoDelFantasma(ghost)
    if type(ghost) == 'string' then
        local ok, dec = pcall(json.decode, ghost)
        ghost = ok and dec or nil
    end
    local frames = type(ghost) == 'table' and ghost.frames
    if type(frames) ~= 'table' or #frames == 0 then return nil end
    return tonumber(frames[#frames].t)
end

--[[ ¿Merece la pena mandar el fantasma? Solo se guarda si la vuelta es record
     del circuito (server/main.lua, UpdateRaceRecords), asi que se manda solo
     si la mejor vuelta de esta carrera baja del record que se conoce (el del
     fantasma que se ha corrido) y no hay en esta carrera otra mas rapida.
     Sin fantasma no se sabe el record: se manda y decide el servidor. El
     margen es porque el tiempo del servidor y el del cliente no son el mismo
     reloj. ]]
local function FantasmaMejora()
    if not bestLapGhostData or #bestLapGhostData == 0 then return false end
    -- Si baja de TU mejor vuelta tambien vale: el servidor guarda el fantasma
    -- de cada piloto (client/contrarreloj.lua, server/contrarreloj.lua).
    local mia = MiMejorVueltaEn and MiMejorVueltaEn(currentRaceData and currentRaceData.circuitId)
    if mia == false or (mia and bestLapTimeMs < mia + 1500) then return true end
    local record = currentRaceData and TiempoDelFantasma(currentRaceData.ghost)
    if record and bestLapTimeMs >= record then return false end
    local mejorDeLaCarrera = tonumber(lastServerData.bestLapOverall) or 0
    if mejorDeLaCarrera > 0 and bestLapTimeMs > mejorDeLaCarrera + 1500 then return false end
    return true
end

function StartGhostRecording()
    ghostRecordingActive = true
    currentLapFrames = {}
    CreateThread(GhostRecordThread)
end

function StopGhostRecording()
    ghostRecordingActive = false
end

function InterpolarAngulo(a, b, t)
    local d = (b - a + 180.0) % 360.0 - 180.0
    return a + d * t
end

--[[ La reproduccion va por el TIEMPO de cada fotograma (`t`), no por su
     numero: da igual que el fantasma se grabase a 20 fps (los viejos) o a 10
     (los de ahora). ]]
function StartGhostPlayback(ghostData)
    if type(ghostData) == "string" then
        ghostData = json.decode(ghostData)
    end
    if not ghostData or not ghostData.frames or #ghostData.frames == 0 then return end

    local modelName = ghostData.vehicle or 'adder'
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then
        modelHash = GetHashKey('adder')
    end

    lib.requestModel(modelHash, 5000)

    local frames = ghostData.frames
    local firstFrame = frames[1]
    local spawnCoords = vector3(firstFrame.x or firstFrame[2], firstFrame.y or firstFrame[3], firstFrame.z or firstFrame[4])
    local spawnHeading = firstFrame.h or firstFrame[5] or 0.0
    local spawnPitch = firstFrame.p or 0.0
    local spawnRoll = firstFrame.r or 0.0

    ghostVehicleEntity = CreateVehicle(modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, false, false)
    if not ghostVehicleEntity or ghostVehicleEntity == 0 then return end

    SetEntityAsMissionEntity(ghostVehicleEntity, true, true)
    SetEntityRotation(ghostVehicleEntity, spawnPitch, spawnRoll, spawnHeading, 2)
    SetEntityAlpha(ghostVehicleEntity, 120)
    SetEntityCollision(ghostVehicleEntity, false, false)
    FreezeEntityPosition(ghostVehicleEntity, true)
    SetVehicleDoorsLocked(ghostVehicleEntity, 2)
    SetEntityInvincible(ghostVehicleEntity, true)

    ghostPlaybackActive = true
    CreateThread(function()
        local ghostOculto = false
        -- Por donde va el fantasma en sus fotogramas. Antes se buscaba desde
        -- el primero en CADA fotograma del juego: hasta 3.600 comparaciones
        -- sesenta veces por segundo. El tiempo solo avanza, asi que basta con
        -- seguir desde donde se quedo, y volver al principio al cambiar de vuelta.
        local idx, ultimoElapsed = 1, 0
        while ghostPlaybackActive and isRacing and DoesEntityExist(ghostVehicleEntity) do
            --[[ El fantasma es UNA vuelta —la del record—, asi que corre
                 contra el reloj de la vuelta, no el de la carrera, y vuelve a
                 empezar en cada una. Antes solo valia la primera: al acabarla
                 el hilo se paraba y el coche fantasma se quedaba plantado en
                 la pista el resto de la carrera. Ahora, cuando se le acaban
                 los fotogramas, se esconde hasta que empieces la siguiente. ]]
            local elapsed = GetGameTimer() - lapStartTime
            local acabado = elapsed > (frames[#frames].t or 999999)
            if acabado ~= ghostOculto then
                ghostOculto = acabado
                SetEntityVisible(ghostVehicleEntity, not acabado, false)
            end
            if elapsed < ultimoElapsed then idx = 1 end   -- vuelta nueva
            ultimoElapsed = elapsed
            while idx < #frames and frames[idx + 1].t <= elapsed do
                idx = idx + 1
            end

            local fa, fb = frames[idx], frames[math.min(idx + 1, #frames)]
            local ta, tb = fa.t or 0, fb.t or fa.t or 0
            local t = (tb > ta) and (elapsed - ta) / (tb - ta) or 1.0
            t = math.max(0, math.min(1, t))

            local x = (fa.x or fa[2]) + ((fb.x or fb[2]) - (fa.x or fa[2])) * t
            local y = (fa.y or fa[3]) + ((fb.y or fb[3]) - (fa.y or fa[3])) * t
            local z = (fa.z or fa[4]) + ((fb.z or fb[4]) - (fa.z or fa[4])) * t
            -- Los angulos por el lado corto: de 359 a 1 son dos grados, no
            -- una vuelta entera. A 10 fps (los fantasmas nuevos) se notaba.
            local h = InterpolarAngulo(fa.h or fa[5] or 0, fb.h or fb[5] or 0, t)
            local p = InterpolarAngulo(fa.p or 0, fb.p or 0, t)
            local r = InterpolarAngulo(fa.r or 0, fb.r or 0, t)

            SetEntityCoords(ghostVehicleEntity, x, y, z, false, false, false, false)
            SetEntityRotation(ghostVehicleEntity, p, r, h, 2)

            Wait(acabado and 250 or 0)
        end
        ghostPlaybackActive = false
        -- Y al acabar la carrera, fuera: no se queda en el mundo.
        if ghostVehicleEntity and DoesEntityExist(ghostVehicleEntity) then
            DeleteEntity(ghostVehicleEntity)
            ghostVehicleEntity = nil
        end
    end)

end

function StopGhostPlayback()
    ghostPlaybackActive = false
    if ghostVehicleEntity and DoesEntityExist(ghostVehicleEntity) then
        DeleteEntity(ghostVehicleEntity)
        ghostVehicleEntity = nil
    end
end

-- ========================================
-- EL DRIFT
-- ========================================

--[[ Una carrera de tipo «drift» ya no es una carrera normal con otro nombre:
     se puntua derrapar, y gana quien mas puntos hace (el servidor ordena por
     puntos al cerrar la carrera).

     Se puntua mientras el coche va DE LADO: el angulo entre hacia donde mira
     y hacia donde se mueve. Cuanto mas angulo y mas velocidad, mas puntos por
     segundo. Encadenar sin enderezar sube el multiplicador (hasta x5). Lo
     ganado en un derrape queda «en el aire» hasta que lo cierras limpio:
     si te das un golpe antes, lo pierdes. ]]
local drift = { total = 0, enJuego = 0, combo = 1, activo = false }

function PuntosDeDrift()
    -- Lo que hay en juego cuenta ya multiplicado: es lo que se cobraria al
    -- cerrar el derrape ahora mismo (y la carrera puede acabar a medio derrape).
    return math.floor(drift.total + drift.enJuego * drift.combo)
end

function DriftLoop()
    drift = { total = 0, enJuego = 0, combo = 1, activo = false }

    local cfg = Config.Drift or {}
    local anguloMin = cfg.AnguloMinimo or 12.0
    local velMin = (cfg.VelocidadMinima or 30.0) / 3.6
    local porSegundo = cfg.PuntosPorSegundo or 60.0
    local gracia = cfg.Gracia or 1500

    local ultimo = GetGameTimer()
    local ultimoDerrape, inicioCombo, ultimoAviso = 0, 0, 0

    while isRacing do
        Wait(0)
        local ahora = GetGameTimer()
        local dt = (ahora - ultimo) / 1000.0
        ultimo = ahora

        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        local derrapando = false

        if veh ~= 0 and not vehicleFrozen then
            local v = GetEntityVelocity(veh)
            local vel = math.sqrt(v.x * v.x + v.y * v.y)

            if vel > velMin and IsVehicleOnAllWheels(veh) then
                local f = GetEntityForwardVector(veh)
                local cos = (v.x * f.x + v.y * f.y) / vel
                local angulo = math.deg(math.acos(math.max(-1.0, math.min(1.0, cos))))

                -- Por debajo es conducir recto; por encima de 100 es ir marcha atras.
                if angulo > anguloMin and angulo < 100.0 then
                    derrapando = true
                    if not drift.activo then
                        drift.activo = true
                        if inicioCombo == 0 then inicioCombo = ahora end
                    end
                    ultimoDerrape = ahora
                    -- El multiplicador sube cada dos segundos y medio encadenados.
                    drift.combo = 1 + math.min(4, math.floor((ahora - inicioCombo) / 2500))
                    -- En juego se guarda SIN multiplicar: el multiplicador se aplica a
                    -- todo el derrape al cobrarlo, que es lo que dice el HUD (+1234 x5).
                    -- Antes solo multiplicaba lo que se iba sumando en cada instante,
                    -- asi que un «1234 x5» dejaba 1234 puntos (09/10).
                    drift.enJuego = drift.enJuego + (angulo / 45.0) * (vel / 15.0) * porSegundo * dt
                end
            end

            -- Un golpe se lleva lo que habia en juego.
            if drift.enJuego > 0 and HasEntityCollidedWithAnything(veh) then
                drift.enJuego, drift.combo, drift.activo, inicioCombo = 0, 1, false, 0
                PlaySoundFrontend(-1, 'CANCEL', 'HUD_FREEMODE_SOUNDSET', true)
            end
        end

        if not derrapando then
            drift.activo = false
            -- Pasado el margen sin derrapar, el derrape se cierra y se cobra.
            if drift.enJuego > 0 and ahora - ultimoDerrape > gracia then
                drift.total = drift.total + drift.enJuego * drift.combo
                drift.enJuego, drift.combo, inicioCombo = 0, 1, 0
            end
        end

        if ahora - ultimoAviso > 150 then
            ultimoAviso = ahora
            SendNUIMessage({ action = 'updateRaceHUD', data = {
                drift = { total = math.floor(drift.total), enJuego = math.floor(drift.enJuego), combo = drift.combo },
            } })
        end
    end
end

-- ========================================
-- LA PARRILLA DE SALIDA
-- ========================================

--[[ Antes cada coche se congelaba donde estuviera: amontonados, cruzados o a
     cuarenta metros de la linea. Ahora, al empezar la cuenta atras, cada
     piloto va a su cajon: dos columnas escalonadas detras del primer
     checkpoint, mirando hacia donde sale el trazado.

     El orden es el de inscripcion —la lista de participantes que manda el
     servidor—, asi que todos los clientes calculan la misma parrilla sin
     tener que preguntarle nada.

     La parrilla sale de la POSICION y el RUMBO del primer checkpoint, que es
     donde el que grabo el circuito paro el coche: por eso conviene marcar ese
     primer punto en una recta, mirando en el sentido de la carrera. ]]
function ColocarEnParrilla(vehicle, data)
    --[[ La prueba de un circuito (client/admin.lua) va a la salida siempre:
         se lanza desde cualquier punto del mapa, y con la parrilla apagada
         empezaba donde estuviera el admin. ]]
    local cfg = Config.Parrilla or {}
    if not cfg.Enabled and not data.prueba then return end

    local salida = raceCheckpointsByOrder[0]
    if not salida then return end

    -- Mi puesto: mi sitio en la lista de participantes.
    local yo = GetPlayerServerId(PlayerId())
    local puesto = nil
    for i, p in ipairs(data.participants or {}) do
        if tonumber(p.serverId) == yo then puesto = i - 1; break end
    end
    if not puesto then return end

    -- El rumbo de la salida. Un circuito viejo no lo trae: se saca de hacia
    -- donde cae el segundo checkpoint.
    local rumbo = tonumber(salida.heading)
    if not rumbo then
        local segundo = raceCheckpointsByOrder[1]
        if not segundo then return end
        rumbo = math.deg(math.atan(-(segundo.coord_x - salida.coord_x), segundo.coord_y - salida.coord_y))
    end

    local h = math.rad(rumbo)
    local fx, fy = -math.sin(h), math.cos(h)      -- hacia delante
    local dx, dy = math.cos(h), math.sin(h)       -- hacia la derecha

    local fila = math.floor(puesto / 2)
    local derecha = puesto % 2 == 1
    -- El de la derecha sale medio cajon mas atras: parrilla escalonada.
    local atras = (cfg.PrimeraFila or 6.0) + fila * (cfg.EntreFilas or 9.0) + (derecha and (cfg.EntreFilas or 9.0) / 2 or 0.0)
    -- Sin salirse del ancho del propio checkpoint.
    local lado = math.min(cfg.Separacion or 2.4, math.max(1.2, (tonumber(salida.radius) or 10.0) - 1.5))
    if not derecha then lado = -lado end

    local x = salida.coord_x - fx * atras + dx * lado
    local y = salida.coord_y - fy * atras + dy * lado
    local z = salida.coord_z

    local hay, suelo = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
    if hay and math.abs(suelo - z) < 6.0 then z = suelo end

    SetEntityCoordsNoOffset(vehicle, x, y, z + 0.6, false, false, false)
    SetEntityHeading(vehicle, rumbo)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleForwardSpeed(vehicle, 0.0)
    SetGameplayCamRelativeHeading(0.0)
end

-- ========================================
-- EVENTO: INICIAR CUENTA ATRÁS
-- ========================================

RegisterNetEvent('racing:startRaceCountdown', function(data)
    if isRacing then return end

    currentRaceData = data
    raceCheckpoints = data.checkpoints or {}
    -- Fix F: construir índice O(1) una sola vez al inicio de la carrera
    raceCheckpointsByOrder = {}
    for _, cp in ipairs(raceCheckpoints) do
        raceCheckpointsByOrder[cp.checkpoint_order] = cp
    end
    currentCheckpoint = 1
    currentLap = 1
    isRacing = true
    hudSucio = true
    tandaCarrera = tandaCarrera + 1
    -- La vuelta se cierra en la salida en lo que da vueltas; un sprint (o
    -- una carrera de una sola vuelta) acaba en el ultimo punto.
    -- La contrarreloj cierra la vuelta aunque sea una: su tiempo va a la tabla.
    vueltaCerrada = data.raceType ~= 'sprint' and ((tonumber(data.totalLaps) or 1) > 1 or data.contrarreloj == true)
    cierraVuelta = false
    volviendo, reiniciarTramo, vueltaTocada = false, false, false
    ultimaVuelta = 0
    cocheDeCarrera, cocheDeCarreraNet, cocheCongelado, cocheFantasmaNet = nil, 0, nil, 0

    CreateThread(function()
        SpawnCheckpointDelimiters()
    end)

    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)

    --[[ De copiloto se VE la carrera (checkpoints, ruta, HUD) y nada mas: ni
         se toca el coche, que es del piloto, ni se puntua, ni se manda nada
         al servidor. `soyPiloto` cubre ademas al corredor de verdad que en el
         momento de la salida no esta al volante: tampoco puede recolocar ni
         congelar un coche que conduce otro. ]]
    local copiloto = data.copiloto == true
    local soyPiloto = not copiloto and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == playerPed
    if copiloto then
        CreateThread(HiloCopiloto)
        lib.notify({ title = 'Copiloto', description = 'Ves la carrera de tu piloto. No puntúas ni cobras.', type = 'inform', duration = 6000 })
    end

    if soyPiloto and data.raceType == 'drift' then
        CreateThread(DriftLoop)
    end

    -- Lo propio de cada modo: ruedas de drift, potenciadores del arcade.
    if soyPiloto then Modos.Empezar(data) end
    -- Tráfico, rebufo, hora y clima (client/ambiente.lua). La hora y el clima
    -- también los ve el copiloto.
    Ambiente.Empezar(data, soyPiloto)

    if soyPiloto then
        ApuntarCocheDeCarrera(vehicle)
    end

    if soyPiloto and (data.ghostMode == true or not data.collisionsEnabled) and vehicle ~= 0 then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        if netId and netId ~= 0 then
            TriggerServerEvent('racing:registerVehicleGhost', netId, true)
            cocheFantasmaNet = netId
        end
        CreateThread(function() GhostLoop() end)
        --[[ Con colisiones activadas, el fantasma es solo para la salida
             (15/10): lo que dice la sala, «primeros 10 s sin colisión». Antes
             duraba toda la carrera y, como venía activado por defecto, nunca
             había choques aunque se eligiera «Con colisiones». ]]
        if data.collisionsEnabled then
            local net = cocheFantasmaNet
            SetTimeout(5000 + 10000, function()
                if cocheFantasmaNet ~= net or net == 0 then return end
                EndGhostLoop()
                TriggerServerEvent('racing:registerVehicleGhost', net, false)
                cocheFantasmaNet = 0
            end)
        end
    end

    -- A la parrilla, y congelado hasta la salida. Se apunta CUAL: al soltarlo
    -- se suelta ese, este donde este el piloto.
    if soyPiloto then
        ColocarEnParrilla(vehicle, data)
        FreezeEntityPosition(vehicle, true)
        cocheCongelado = vehicle
        vehicleFrozen = true
    end

    -- Muerto o con el coche reventado (VigilarCaida).
    if not copiloto then CreateThread(VigilarCaida) end

    -- Iniciar HUD
    SendNUIMessage({
        action = 'initRaceHUD',
        data = {
            raceName = data.raceName,
            circuitName = data.circuitName,
            currentLap = 1,
            totalLaps = data.totalLaps,
            position = 1,
            totalRacers = data.totalParticipants,
            nextCheckpoint = 1,
            totalCheckpoints = #raceCheckpoints,
            esDrift = data.raceType == 'drift',
            modo = data.raceType,
            papeles = data.papeles == true,
            estilo = Config.HudCarrera or 0,
            salida = Config.SalidaEstilo or 1,
            bestLap = 0,
            leaderboard = {}
        }
    })

    -- Iniciar countdown visual
    StartCountdown()
end)

-- ========================================
-- CUENTA ATRÁS VISUAL
-- ========================================

function StartCountdown()
    local tanda = tandaCarrera
    --- La carrera se ha acabado (cancelada, expulsado, abandono) o ya es otra:
    --- fuera la cuenta atras y no se arranca nada.
    local function sigue()
        if isRacing and tanda == tandaCarrera then return true end
        SendNUIMessage({ action = 'hideCountdown' })
        return false
    end

    CreateThread(function()
        -- Countdown de 3, 2, 1
        for i = 3, 1, -1 do
            -- Mostrar número en pantalla
            SendNUIMessage({
                action = 'showCountdown',
                data = {
                    number = i,
                    text = tostring(i)
                }
            })

            PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
            Wait(1000)
            if not sigue() then return end
        end

        -- GO!
        SendNUIMessage({
            action = 'showCountdown',
            data = {
                number = 0,
                text = '¡YA!'
            }
        })

        PlaySoundFrontend(-1, "RACE_PLACED", "HUD_AWARDS", 1)
        Wait(1000)
        if not sigue() then return end

        -- Ocultar countdown
        SendNUIMessage({
            action = 'hideCountdown'
        })

        -- Descongelar el coche que se congelo (no el que se lleve ahora)
        SoltarCocheCongelado()

        -- Quien no estaba al volante en la salida: su coche es el primero que conduzca.
        if not cocheDeCarrera and currentRaceData and not currentRaceData.copiloto then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                ApuntarCocheDeCarrera(veh)
            end
        end

        if currentRaceData and currentRaceData.circuitId then
            TriggerEvent('racing:convertStartMarkerToFinish', currentRaceData.circuitId)
        end

        -- Iniciar fantasma del récord (si hay)
        if currentRaceData and currentRaceData.ghost then
            CreateThread(function()
                StartGhostPlayback(currentRaceData.ghost)
            end)
        end

        -- Iniciar cronómetros
        raceStartTime = GetGameTimer()
        lapStartTime = GetGameTimer()

        -- Resetear serverSync para el thread de distancia
        serverSync = 0

        -- Iniciar grabación ghost (récord para modo fantasma)
        StartGhostRecording()

        -- Se elimina el grace-period fijo de 10s.
        -- El ghosting ahora es binario por carrera: activo toda la carrera o desactivado.

        -- Iniciar threads de la carrera
        CreateThread(CheckpointThread)
        CreateThread(RaceHUDUpdateThread)
        CreateThread(RaceProgressUpdateThread)
        -- El tope de FPS se enciende y se apaga en el config (Config.LimiteFps).
        if Config.LimiteFps and Config.LimiteFps.Enabled then
            StartFpsMonitorThread()
        end

        -- Crear marcadores de checkpoints
        CreateCheckpointMarkers()
    end)
end

--- El coche con el que se corre (ver cocheDeCarrera arriba).
function ApuntarCocheDeCarrera(veh)
    if not veh or veh == 0 then return end
    cocheDeCarrera = veh
    cocheDeCarreraNet = NetworkGetEntityIsNetworked(veh) and NetworkGetNetworkIdFromEntity(veh) or 0
end

--- ¿Es `veh` el coche de la carrera? Por la entidad o por su netId.
local function EsCocheDeCarrera(veh)
    if not veh or veh == 0 then return false end
    if veh == cocheDeCarrera then return true end
    if cocheDeCarreraNet ~= 0 and NetworkGetEntityIsNetworked(veh)
        and NetworkGetNetworkIdFromEntity(veh) == cocheDeCarreraNet then
        cocheDeCarrera = veh   -- ha vuelto a entrar en alcance con otra entidad
        return true
    end
    return false
end

--- El coche de la carrera, si existe en este cliente.
local function CocheDeCarrera()
    if cocheDeCarrera and DoesEntityExist(cocheDeCarrera) then return cocheDeCarrera end
    if cocheDeCarreraNet ~= 0 and NetworkDoesNetworkIdExist(cocheDeCarreraNet) then
        local veh = NetToVeh(cocheDeCarreraNet)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            cocheDeCarrera = veh
            return veh
        end
    end
    return nil
end

--- Suelta el coche que se congelo en la cuenta atras. Siempre deja
--- vehicleFrozen en false, este o no el coche.
function SoltarCocheCongelado()
    if cocheCongelado and DoesEntityExist(cocheCongelado) then
        FreezeEntityPosition(cocheCongelado, false)
    end
    cocheCongelado = nil
    vehicleFrozen = false
end

-- ========================================
-- CREAR MARCADORES DE CHECKPOINTS
-- ========================================

--[[ Los proximos checkpoints que quedan por pasar, en orden y sin pasarse de
     la meta: en el ultimo tramo de la ultima vuelta la lista ya no da la
     vuelta al principio del circuito. Antes el GPS y los puntos del mapa
     seguian hacia el checkpoint 1 y 2 de una vuelta que no se iba a correr.

     Cada uno es { orden = checkpoint_order, meta = es la meta }. ]]
local function ProximosOrdenes(cuantos)
    local lista = {}
    local n = raceCheckpoints and #raceCheckpoints or 0
    if n == 0 or not currentRaceData or (currentCheckpoint or 0) < 1 then return lista end

    local vueltas = tonumber(currentRaceData.totalLaps) or 1
    local orden, cierra, vuelta = currentCheckpoint - 1, cierraVuelta, currentLap

    while #lista < cuantos do
        -- La meta: con vuelta cerrada, la salida al cerrar la ultima vuelta;
        -- si no, el ultimo punto de la ultima vuelta.
        local meta
        if vueltaCerrada then
            meta = cierra and vuelta >= vueltas
        else
            meta = orden == n - 1 and vuelta >= vueltas
        end
        lista[#lista + 1] = { orden = orden, meta = meta }
        if meta then break end

        if cierra then
            -- Cruzar la salida cierra la vuelta y es el checkpoint 1 de la siguiente.
            cierra, vuelta, orden = false, vuelta + 1, 1 % n
        elseif orden >= n - 1 then
            if vueltaCerrada then
                cierra, orden = true, 0
            else
                vuelta, orden = vuelta + 1, 0
            end
        else
            orden = orden + 1
        end
    end
    return lista
end

--[[ El GPS, por los tres proximos checkpoints y en orden. Con la ruta solo
     hasta el siguiente, al llegar a un cruce no se sabia hacia que lado
     seguia el circuito hasta haber pasado el punto. ]]
function RutaPorLosProximos()
    ClearGpsMultiRoute()
    local n = raceCheckpoints and #raceCheckpoints or 0
    if n == 0 or not isRacing then
        SetGpsMultiRouteRender(false)
        return
    end

    StartGpsMultiRoute(24, true, true)   -- 24: el rosa del HUD del juego
    for _, p in ipairs(ProximosOrdenes(3)) do
        local cp = raceCheckpointsByOrder[p.orden]
        if cp then
            AddPointToGpsMultiRoute(cp.coord_x + 0.0, cp.coord_y + 0.0, cp.coord_z + 0.0)
        end
    end
    SetGpsMultiRouteRender(true)
end

function CreateCheckpointMarkers()
    -- Limpiar marcadores anteriores
    ClearCheckpointMarkers()

    if not raceCheckpoints or #raceCheckpoints == 0 then return end

    -- Los puntos del mapa y el GPS (UpdateCheckpointBlip) y el cartel del siguiente.
    UpdateCheckpointBlip()
    UpdateNext3Markers()
end

--- El giro que hace el trazado en `cp`, llegando desde `prevCp` y saliendo
--- hacia `nextCp`, como flecha vista desde el coche.
function GetTurnIcon(prevCp, cp, nextCp)
    if not prevCp or not nextCp or prevCp == cp or nextCp == cp then return '↑' end

    local ex, ey = cp.coord_x - prevCp.coord_x, cp.coord_y - prevCp.coord_y        -- como se llega
    local sx, sy = nextCp.coord_x - cp.coord_x, nextCp.coord_y - cp.coord_y        -- como se sale

    -- El angulo con signo entre los dos: positivo es a la IZQUIERDA (en GTA
    -- la x crece al este y la y al norte).
    local giro = math.deg(math.atan(ex * sy - ey * sx, ex * sx + ey * sy))
    local a = math.abs(giro)
    local izquierda = giro > 0

    if a < 20 then return '↑' end
    if a < 65 then return izquierda and '↖' or '↗' end
    if a < 115 then return izquierda and '←' or '→' end
    if a < 160 then return izquierda and '↙' or '↘' end
    return '↓'
end

--[[ El cartel del SIGUIENTE checkpoint, y solo ese. Antes se pintaban los
     tres proximos y en una recta quedaban uno detras de otro, con los
     carteles pisados y sin saber cual era el que tocaba. ]]
function UpdateNext3Markers()
    -- Limpiar markers actuales
    for _, markerId in ipairs(checkpointMarkerIds) do
        pcall(function() exports.origen_markers:Remove(markerId) end)
    end
    checkpointMarkerIds = {}

    local total = raceCheckpoints and #raceCheckpoints or 0
    if total == 0 then return end

    local siguiente = ProximosOrdenes(1)[1]
    if not siguiente then return end
    local orden = siguiente.orden
    local cp = raceCheckpointsByOrder[orden]
    if not cp then return end

    --[[ La flecha dice hacia donde GIRA el trazado al pasar por este punto,
         vista por quien llega conduciendo: recto, a la derecha, a la
         izquierda. En un circuito el anterior al primero es el ultimo, y el
         siguiente al ultimo, el primero. ]]
    local prevCp = raceCheckpointsByOrder[(orden - 1) % total]
    local nextCp = raceCheckpointsByOrder[(orden + 1) % total]

    --[[ La meta es donde se ACABA (ProximosOrdenes): la salida al cerrar la
         ultima vuelta, o el ultimo punto de la ultima vuelta si la vuelta no
         se cierra. ]]
    local label
    if siguiente.meta then
        label = '🏁 META\nVuelta ' .. currentLap .. '/' .. tostring(currentRaceData and currentRaceData.totalLaps or 1)
    else
        label = GetTurnIcon(prevCp, cp, nextCp) .. ' Checkpoint ' .. (orden + 1)
    end

    local ok, markerId = pcall(function()
        return exports.origen_markers:Create({
            coords = vector3(cp.coord_x, cp.coord_y, cp.coord_z),
            type = 'checkpoint',
            label = label,
            size = 2.5,
            drawDistance = 300.0,
            removeDistance = nil -- No auto-eliminar
        })
    end)
    if ok and markerId then
        checkpointMarkerIds[#checkpointMarkerIds + 1] = markerId
    end
end

function ClearCheckpointMarkers()
    --- Quitar el punto se lleva tambien su ruta: el blip invisible que la
    --- sostiene lo crea y lo borra el propio registro.
    for _, blip in ipairs(checkpointBlips) do
        OrigenMapa.Quitar(blip)
    end
    checkpointBlips = {}
    SetWaypointOff() -- Quitar waypoint del mapa
    -- Y la ruta por los tres proximos checkpoints
    ClearGpsMultiRoute()
    SetGpsMultiRouteRender(false)

    -- Remover markers de origen_markers (el "25M" y "SIGUE EL CAMINO")
    for _, markerId in ipairs(checkpointMarkerIds) do
        if markerId then
            pcall(function() exports.origen_markers:Remove(markerId) end)
        end
    end
    checkpointMarkerIds = {}
end

-- ========================================
-- FUNCIONES PARA DELIMITADORES FISICOS
-- ========================================

--[[ La decoracion (props con luz, humo) se pone solo en los checkpoints que
     vienen, no en todo el circuito. Antes se creaban los dos props de CADA
     checkpoint al dar la salida: en un circuito de 40 puntos eran 80 objetos
     con luz vivos toda la carrera, casi todos a kilometros. Ahora hay una
     ventana —el que acabas de pasar y los cuatro siguientes— que avanza con
     cada checkpoint. ]]
local decoPorCp = {}      -- [checkpoint_order] = lista de Decoracion
local decoTanda = 0       -- cambia al limpiar: un hilo viejo no pone nada
local decoPasado = nil    -- checkpoint_order del ultimo que ha pasado el corredor: sus props, en verde
local DECO_DELANTE, DECO_DETRAS = 4, 1

local function rumboDe(cp)
    --[[ El rumbo con el que se grabo el punto. Si no lo trae —un circuito
         viejo—, se saca de donde cae el checkpoint siguiente. ]]
    local rumbo = tonumber(cp.heading)
    if rumbo then return rumbo end

    local n = #raceCheckpoints
    local otro = raceCheckpointsByOrder[(cp.checkpoint_order + 1) % n]
    local dx, dy = 0.0, 1.0
    if otro and otro ~= cp then
        dx, dy = otro.coord_x - cp.coord_x, otro.coord_y - cp.coord_y
    else
        local antes = raceCheckpointsByOrder[(cp.checkpoint_order - 1) % n]
        if antes and antes ~= cp then
            dx, dy = cp.coord_x - antes.coord_x, cp.coord_y - antes.coord_y
        end
    end
    return math.deg(math.atan(-dx, dy))
end

--- Deja puesta la decoracion de la ventana y quita la que ha quedado atras.
--- Carga modelos: hay que llamarla desde un hilo.
--- El estilo que lleva un punto en carrera (Config.CheckpointDelimiters.Forzar):
--- bandera a cuadros en la salida y en la meta de un sprint, el resto la
--- pancarta luminosa. Sin Forzar, el que se grabó.
function DecoDeCarrera(orden, total, grabado)
    local f = Config.CheckpointDelimiters and Config.CheckpointDelimiters.Forzar
    if not f then return grabado end
    local tipo = currentRaceData and (currentRaceData.raceType or currentRaceData.race_type)
    local esMeta = tipo == 'sprint' and orden == (total - 1)
    if orden == 0 or esMeta then return f.salida or grabado end
    return f.normal or grabado
end

function SpawnCheckpointDelimiters()
    if not Config.CheckpointDelimiters or not Config.CheckpointDelimiters.Enabled then return end
    local n = raceCheckpoints and #raceCheckpoints or 0
    if n == 0 then return end

    local tanda = decoTanda
    local siguiente = math.max(0, (currentCheckpoint or 1) - 1)   -- checkpoint_order del proximo

    local quiero = {}
    for d = -DECO_DETRAS, DECO_DELANTE do
        quiero[(siguiente + d) % n] = true
    end

    for orden, lista in pairs(decoPorCp) do
        if not quiero[orden] then
            Decoracion.Quitar(lista)
            decoPorCp[orden] = nil
        end
    end

    for orden in pairs(quiero) do
        local cp = raceCheckpointsByOrder[orden]
        if cp and not decoPorCp[orden] then
            local lista = {}
            decoPorCp[orden] = lista
            -- La misma pieza que pinta la grabacion (client/decoracion.lua):
            -- lo que se vio al grabar es lo que se corre.
            Decoracion.Poner(lista, {
                x = cp.coord_x, y = cp.coord_y, z = cp.coord_z,
                heading = rumboDe(cp),
                radius = cp.radius or Config.Circuits.CheckpointRadius or 15.0,
                deco = DecoDeCarrera(orden, n, cp.deco),
            })
            -- Se ha limpiado mientras cargaba el modelo, o la ventana ya ha
            -- pasado de largo: esto ya no pinta nada.
            if tanda ~= decoTanda then
                Decoracion.Quitar(lista)
                return
            end
            if decoPorCp[orden] ~= lista then
                Decoracion.Quitar(lista)
            end
        end
    end

    -- El que se acaba de pasar, en verde (los props propios; los demas no cambian)
    local pasado = decoPasado and decoPorCp[decoPasado]
    if pasado then
        Decoracion.Pasar(pasado)
        if tanda ~= decoTanda then Decoracion.Quitar(pasado) end
    end
end

function ClearCheckpointDelimiters()
    decoTanda = decoTanda + 1
    decoPasado = nil
    for orden, lista in pairs(decoPorCp) do
        Decoracion.Quitar(lista)
        decoPorCp[orden] = nil
    end
end

-- ========================================
-- THREAD: VERIFICAR CHECKPOINTS
-- ========================================

--[[ El copiloto deja de ver la carrera cuando se baja del coche o cuando su
     piloto deja de correr (meta, abandono, expulsion). Lo segundo se sabe por
     el estado `enCarrera` del piloto, que va replicado. ]]
function HiloCopiloto()
    local sinPiloto = 0
    Wait(6000)   -- la cuenta atras: el piloto aun no «corre»
    while isRacing and currentRaceData and currentRaceData.copiloto do
        Wait(1000)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)
        local corre = false
        if veh ~= 0 then
            local piloto = GetPedInVehicleSeat(veh, -1)
            if piloto ~= 0 and piloto ~= ped and IsPedAPlayer(piloto) then
                local sid = GetPlayerServerId(NetworkGetPlayerIndexFromPed(piloto))
                corre = sid and sid > 0 and Player(sid).state.enCarrera == true
            end
        end
        sinPiloto = corre and 0 or sinPiloto + 1
        if sinPiloto >= 3 then
            TriggerEvent('racing:playerDnf', { raceId = currentRaceData.raceId, copiloto = true })
            return
        end
    end
end

--[[ ¿Ha pasado el coche por el checkpoint entre la vuelta anterior y esta?

     Antes se miraba, diez veces por segundo, si el coche estaba DENTRO de la
     esfera del checkpoint. A 250 km/h son siete metros entre mirada y mirada:
     pasando por el borde —o por el centro de uno de 4 m de radio— el coche
     podia estar fuera antes y fuera despues, y el punto no contaba. Ademas la
     esfera era en 3D: un bache o un salto la acortaban.

     Ahora el checkpoint es una PUERTA: la linea que va de un prop al otro,
     cruzada a la carretera. Cuenta si
       · el coche esta dentro del circulo (como antes, pero en planta), o
       · el TRAMO recorrido desde la mirada anterior cruza la puerta, o
       · ese tramo pasa a menos de un radio del centro.
     Con margen de medio coche a cada lado: rozar el prop tambien es pasar. ]]
local MARGEN_PUERTA = 1.6      -- metros de mas a cada lado
local ALTO_PUERTA = 14.0       -- por encima o por debajo no cuenta (puentes, tuneles)

local function PasaPorCheckpoint(cp, antes, ahora)
    local cx, cy, cz = cp.coord_x, cp.coord_y, cp.coord_z
    if math.abs(ahora.z - cz) > ALTO_PUERTA then return false end

    local r = ((tonumber(cp.radius) or Config.Circuits.CheckpointRadius) or 15.0) + MARGEN_PUERTA
    local bx, by = ahora.x - cx, ahora.y - cy
    if bx * bx + by * by <= r * r then return true end

    if not antes then return false end
    local ax, ay = antes.x - cx, antes.y - cy
    local sx, sy = bx - ax, by - ay
    local largo2 = sx * sx + sy * sy
    -- Un salto de mas de 80 m en una mirada no es conducir: es un teletransporte.
    if largo2 < 0.0001 or largo2 > 6400.0 then return false end

    -- El punto del tramo mas cercano al centro
    local t = math.max(0.0, math.min(1.0, -(ax * sx + ay * sy) / largo2))
    local px, py = ax + sx * t, ay + sy * t
    if px * px + py * py <= r * r then return true end

    -- La puerta: la linea cruzada a la carretera
    local h = math.rad(rumboDe(cp))
    local fx, fy = -math.sin(h), math.cos(h)     -- a lo largo de la carretera
    local da, db = ax * fx + ay * fy, bx * fx + by * fy
    if (da < 0.0) ~= (db < 0.0) then
        local k = da / (da - db)
        local ix, iy = ax + sx * k, ay + sy * k
        local lado = ix * math.cos(h) + iy * math.sin(h)
        if math.abs(lado) <= r then return true end
    end
    return false
end

function CheckpointThread()
    local antes = nil
    local tanda = tandaCarrera
    local avisoOtroCoche = 0

    while isRacing and currentRaceData and tanda == tandaCarrera do
        -- Cada 30 ms: con el tramo barrido ya no hace falta cada fotograma,
        -- y es la mitad de lo que tardaba antes en volver a mirar.
        Wait(30)
        if not isRacing or not currentRaceData or tanda ~= tandaCarrera then break end

        if not raceCheckpoints or #raceCheckpoints == 0 then
            break
        end

        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local copiloto = currentRaceData.copiloto

        -- Un corredor solo avanza AL VOLANTE: de acompañante en el coche de
        -- otro no pasa checkpoints (el servidor tampoco se los cuenta).
        if vehicle ~= 0 and not copiloto and GetPedInVehicleSeat(vehicle, -1) ~= playerPed then
            vehicle = 0
        end

        -- Y solo en el coche de la carrera.
        if vehicle ~= 0 and not copiloto then
            if not cocheDeCarrera and cocheDeCarreraNet == 0 then
                ApuntarCocheDeCarrera(vehicle)   -- no lo llevaba en la salida: este
            elseif not EsCocheDeCarrera(vehicle) then
                if GetGameTimer() > avisoOtroCoche then
                    avisoOtroCoche = GetGameTimer() + 15000
                    lib.notify({
                        title = 'Carrera',
                        description = 'Ese no es tu coche de carrera: los checkpoints no cuentan',
                        type = 'error', duration = 5000,
                    })
                end
                vehicle = 0
            end
        end

        if volviendo then
            -- En pleno salto al checkpoint anterior: no se mira nada.
            antes = nil
        elseif vehicle == 0 then
            -- Jugador salió del vehículo, pausar
            antes = nil
            Wait(1000)
        else
            local ahora = GetEntityCoords(vehicle)

            if reiniciarTramo then
                -- El coche acaba de saltar: el tramo de antes a ahora no se ha
                -- recorrido y podria cruzar una puerta que no se ha pasado.
                reiniciarTramo = false
            else
                -- Fix F: lookup O(1) — checkpoint_order empieza en 0, currentCheckpoint en 1
                local nextCp = raceCheckpointsByOrder[currentCheckpoint - 1]

                if nextCp and PasaPorCheckpoint(nextCp, antes, ahora) then
                    OnCheckpointPassed(currentCheckpoint)
                end
            end
            antes = ahora
        end
    end

end

-- ========================================
-- VOLVER AL ULTIMO CHECKPOINT
-- ========================================

--[[ Te sales de la carretera, vuelcas o te quedas encajado: se mantiene la
     tecla (Config.VolverCheckpoint, por defecto R un segundo) o se escribe el
     comando, y el coche de la carrera vuelve al ultimo checkpoint que has
     pasado, en el suelo, mirando hacia el siguiente y arreglado si estaba
     destrozado.

     No toca la cuenta de la carrera: el siguiente sigue siendo el mismo, y al
     servidor no se le manda nada. Volver a un punto ya pasado no lo vuelve a
     contar (el hilo solo mira el SIGUIENTE) y el salto no cuenta como tramo
     recorrido (reiniciarTramo). Muerto no se vuelve: eso es del sistema
     medico. ]]
local CFG_VOLVER = Config.VolverCheckpoint or {}

--- El ultimo checkpoint pasado, o el de salida si aun no se ha pasado ninguno.
local function UltimoPasado()
    local n = #raceCheckpoints
    if n == 0 then return nil end
    if cierraVuelta then return raceCheckpointsByOrder[n - 1] end
    if currentCheckpoint >= 2 then return raceCheckpointsByOrder[currentCheckpoint - 2] end
    -- El siguiente es el primero: en la vuelta 1 aun no hay nada pasado (la
    -- salida); en las demas (vuelta sin cerrar), el ultimo de la anterior.
    if currentLap > 1 and not vueltaCerrada then return raceCheckpointsByOrder[n - 1] end
    return raceCheckpointsByOrder[0]
end

local function avisarVolver(texto)
    lib.notify({ title = 'Carrera', description = texto, type = 'error', duration = 4000 })
end

function VolverAlCheckpoint()
    if not isRacing or not currentRaceData then return end
    if currentRaceData.copiloto then return avisarVolver('De copiloto no conduces tú') end
    if vehicleFrozen then return avisarVolver('Espera a la salida') end
    if volviendo then return end

    local enfriamiento = (tonumber(CFG_VOLVER.Enfriamiento) or 10) * 1000
    local falta = ultimaVuelta + enfriamiento - GetGameTimer()
    if ultimaVuelta > 0 and falta > 0 then
        return avisarVolver(('Espera %d s para volver otra vez'):format(math.ceil(falta / 1000)))
    end

    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedDeadOrDying(ped, true) then
        return avisarVolver('Estás herido: no puedes volver a la pista')
    end

    local veh = CocheDeCarrera()
    if not veh then return avisarVolver('No encuentro tu coche de carrera') end
    if IsEntityDead(veh) then return avisarVolver('Tu coche está destrozado del todo') end

    local conductor = GetPedInVehicleSeat(veh, -1)
    if conductor ~= 0 and conductor ~= ped then
        return avisarVolver('Otro conduce tu coche de carrera')
    end

    local cp = UltimoPasado()
    local destino = raceCheckpointsByOrder[currentCheckpoint - 1]
    if not cp then return end

    -- Mirando hacia el siguiente (el que toca pasar). Si es el mismo punto
    -- (la salida en la vuelta 1), con el rumbo con el que se grabo.
    local rumbo
    if destino and destino ~= cp then
        rumbo = math.deg(math.atan(-(destino.coord_x - cp.coord_x), destino.coord_y - cp.coord_y))
    else
        rumbo = rumboDe(cp)
    end

    volviendo = true
    ultimaVuelta = GetGameTimer()
    local tanda = tandaCarrera

    CreateThread(function()
        local fundido = tonumber(CFG_VOLVER.Fundido) or 400
        DoScreenFadeOut(fundido)
        local hasta = GetGameTimer() + fundido + 1000
        while not IsScreenFadedOut() and GetGameTimer() < hasta do Wait(0) end

        -- Puede haberse acabado la carrera durante el fundido.
        if isRacing and tanda == tandaCarrera and DoesEntityExist(veh) then
            -- Hace falta mandar en el coche para moverlo (si ibas fuera de el).
            if not NetworkHasControlOfEntity(veh) then
                NetworkRequestControlOfEntity(veh)
                local t = GetGameTimer() + 1000
                while not NetworkHasControlOfEntity(veh) and GetGameTimer() < t do
                    Wait(0)
                    NetworkRequestControlOfEntity(veh)
                end
            end

            if NetworkHasControlOfEntity(veh) then
                local x, y, z = cp.coord_x + 0.0, cp.coord_y + 0.0, cp.coord_z + 0.0
                local hay, suelo = GetGroundZFor_3dCoord(x, y, z + 3.0, false)
                if hay and math.abs(suelo - z) < 6.0 then z = suelo end

                SetEntityVelocity(veh, 0.0, 0.0, 0.0)
                SetEntityCoordsNoOffset(veh, x, y, z + 0.6, false, false, false)
                SetEntityHeading(veh, rumbo + 0.0)
                SetVehicleOnGroundProperly(veh)
                SetVehicleForwardSpeed(veh, 0.0)

                -- Destrozado (motor o carroceria por los suelos, o sin poder
                -- andar): se arregla. Con algun golpe, no: no es un taller.
                if GetVehicleEngineHealth(veh) < 300.0 or GetVehicleBodyHealth(veh) < 300.0
                    or not IsVehicleDriveable(veh, false) then
                    SetVehicleFixed(veh)
                    SetVehicleDeformationFixed(veh)
                    SetVehicleEngineHealth(veh, 1000.0)
                    SetVehicleBodyHealth(veh, 1000.0)
                    SetVehicleUndriveable(veh, false)
                    SetVehicleEngineOn(veh, true, true, false)
                end

                if GetVehiclePedIsIn(ped, false) ~= veh then
                    TaskWarpPedIntoVehicle(ped, veh, -1)
                end
                SetGameplayCamRelativeHeading(0.0)

                reiniciarTramo = true
                vueltaTocada = true
            else
                avisarVolver('No se ha podido mover tu coche')
            end
        end

        Wait(150)
        volviendo = false
        DoScreenFadeIn(fundido)
    end)
end

--[[ Muerto, o con el coche reventado: aqui no se reaparece (el medico es del
     sistema medico). Con Config.VolverCheckpoint.DnfAlMorir se abandona la
     carrera solo; si no, se avisa una vez y la carrera sigue esperando: el
     hilo de checkpoints se queda parado sin romperse hasta que vuelvas al
     volante. ]]
function VigilarCaida()
    local tanda = tandaCarrera
    local avisado = false
    Wait(5000)   -- la cuenta atras
    while isRacing and tanda == tandaCarrera do
        Wait(1000)
        if not isRacing or tanda ~= tandaCarrera or not currentRaceData then return end

        local ped = PlayerPedId()
        local muerto = IsEntityDead(ped) or IsPedDeadOrDying(ped, true)
        local veh = CocheDeCarrera()
        local reventado = veh ~= nil and IsEntityDead(veh)

        if muerto or reventado then
            if CFG_VOLVER.DnfAlMorir then
                lib.notify({
                    title = 'Carrera',
                    description = muerto and 'Has caído: quedas fuera de la carrera'
                        or 'Tu coche ha reventado: quedas fuera de la carrera',
                    type = 'error', duration = 6000,
                })
                AbandonarCarrera()
                return
            elseif not avisado then
                avisado = true
                lib.notify({
                    title = 'Carrera',
                    description = muerto and 'Has caído. La carrera sigue: si te levantan a tiempo, vuelve al volante'
                        or 'Tu coche ha reventado. Puedes abandonar desde la tablet',
                    type = 'error', duration = 7000,
                })
            end
        else
            avisado = false
        end
    end
end

--- Dejar la carrera por cuenta propia, como el boton «Abandonar» de la tablet.
function AbandonarCarrera()
    if not isRacing or not currentRaceData then return end
    if currentRaceData.prueba then
        TriggerEvent('racing:playerDnf', { raceId = -1, voluntary = true, position = 1 })
        return
    end
    if currentRaceData.contrarreloj then
        TriggerEvent('racing:contrarreloj:abandonar')   -- client/contrarreloj.lua
        return
    end
    local raceId = currentRaceData.raceId
    CreateThread(function()
        local ok, r = pcall(lib.callback.await, 'racing:hub:leaveRace', false, { raceId = raceId })
        if ok and r and r.success then
            -- El servidor manda racing:playerDnf; esto es lo del hub (nui_callbacks).
            TriggerEvent('racing:localRaceFinished')
            TriggerEvent('racing:cleanupStartMarkers')
        end
    end)
end

-- La tecla: se mantiene pulsada (Config.VolverCheckpoint.Mantener).
if CFG_VOLVER.Enabled ~= false then
    local pulsada = 0

    RegisterCommand('+racing_volvercp', function()
        if not isRacing then return end
        local mia = GetGameTimer()
        pulsada = mia
        CreateThread(function()
            local hasta = mia + (tonumber(CFG_VOLVER.Mantener) or 1000)
            while pulsada == mia and GetGameTimer() < hasta do Wait(0) end
            if pulsada == mia then
                pulsada = 0
                VolverAlCheckpoint()
            end
        end)
    end, false)

    RegisterCommand('-racing_volvercp', function()
        pulsada = 0
    end, false)

    RegisterKeyMapping('+racing_volvercp', 'Carreras: volver al último checkpoint (mantener)', 'keyboard', CFG_VOLVER.Tecla or 'R')

    RegisterCommand(CFG_VOLVER.Comando or 'volvercp', function()
        VolverAlCheckpoint()
    end, false)
end

-- ========================================
-- EVENTO: CHECKPOINT PASADO
-- ========================================

function OnCheckpointPassed(checkpointIndex)

    -- Reproducir sonido
    PlaySoundFrontend(-1, "CHECKPOINT_NORMAL", "HUD_MINI_GAME_SOUNDSET", 1)

    local n = #raceCheckpoints

    --[[ Vuelta cerrada: se acaba de cruzar la salida despues del ultimo
         punto. Eso cierra la vuelta, y la salida es a la vez el checkpoint 1
         de la siguiente: el servidor la recibe en ese orden (vuelta y luego
         checkpoint 1), que es lo que espera (server/main.lua, lapCompleted y
         checkpointPassed). ]]
    if cierraVuelta then
        cierraVuelta = false
        decoPasado = 0    -- la salida
        OnLapCompleted()
        if not isRacing or not currentRaceData then return end   -- era la ultima: meta

        if not currentRaceData.copiloto then
            TriggerServerEvent('racing:checkpointPassed', {
                raceId = currentRaceData.raceId,
                checkpoint = 1,
                totalTime = GetGameTimer() - raceStartTime
            })
        end
        currentCheckpoint = math.min(2, n)
        UpdateCheckpointBlip()
        UpdateNext3Markers()
        if isRacing then CreateThread(SpawnCheckpointDelimiters) end
        UpdateRaceHUD()
        return
    end

    -- Notificar al servidor (el copiloto no: solo mira)
    if not currentRaceData.copiloto then
        TriggerServerEvent('racing:checkpointPassed', {
            raceId = currentRaceData.raceId,
            checkpoint = checkpointIndex,
            totalTime = GetGameTimer() - raceStartTime
        })
    end

    -- El que se acaba de pasar (checkpoint_order es 0-based): sus props, en verde
    decoPasado = currentCheckpoint - 1

    -- Avanzar al siguiente checkpoint
    currentCheckpoint = currentCheckpoint + 1

    if currentCheckpoint > n then
        currentCheckpoint = 1
        if vueltaCerrada then
            -- Pasado el ultimo: falta volver a la salida para cerrar la vuelta.
            cierraVuelta = true
            UpdateCheckpointBlip()
            UpdateNext3Markers()
        else
            -- Sin vuelta cerrada (sprint, una sola vuelta) el ultimo es el final.
            OnLapCompleted()
        end
    else
        -- Actualizar blip al siguiente checkpoint
        UpdateCheckpointBlip()
        UpdateNext3Markers()
    end

    -- La decoracion avanza con el corredor.
    if isRacing then CreateThread(SpawnCheckpointDelimiters) end

    -- Actualizar HUD
    UpdateRaceHUD()
end

-- ========================================
-- EVENTO: VUELTA COMPLETADA
-- ========================================

function OnLapCompleted()
    local lapTime = GetGameTimer() - lapStartTime

    -- Guardar ghost de mejor vuelta (no la que lleva un salto al checkpoint)
    if lapTime < bestLapTimeMs and #currentLapFrames > 0 and not vueltaTocada then
        bestLapTimeMs = lapTime
        bestLapGhostData = currentLapFrames
    end
    currentLapFrames = {}
    vueltaTocada = false

    -- Notificar al servidor (el copiloto no: solo mira)
    if not currentRaceData.copiloto then
        TriggerServerEvent('racing:lapCompleted', {
            raceId = currentRaceData.raceId,
            lap = currentLap,
            lapTime = lapTime,
            totalTime = GetGameTimer() - raceStartTime
        })
    end

    -- Incrementar vuelta
    currentLap = currentLap + 1

    -- Verificar si completó todas las vueltas
    if currentLap > currentRaceData.totalLaps then
        OnRaceFinished()
        return
    end

    -- Resetear checkpoint para la nueva vuelta
    currentCheckpoint = 1
    lapStartTime = GetGameTimer()
    UpdateCheckpointBlip()
    UpdateNext3Markers() -- Actualizar markers para la nueva vuelta

    -- Actualizar HUD
    UpdateRaceHUD()
end

-- ========================================
-- EVENTO: CARRERA FINALIZADA
-- ========================================

--- Bytes por segundo del envio latente con el fantasma: unos 90 KB una
--- vuelta de dos minutos, en medio segundo.
local FANTASMA_BPS = 200000

function OnRaceFinished()
    local totalTime = GetGameTimer() - raceStartTime
    local datos = currentRaceData
    if not datos then return end

    -- Lo que se manda, antes de limpiar (LimpiarCarrera borra los datos del servidor).
    StopGhostRecording()
    local mandarFantasma = not datos.copiloto and not datos.prueba
        and ((tonumber(datos.raceId) or -1) > 0 or datos.contrarreloj == true)
        and FantasmaMejora()

    -- Obtener modelo del vehículo para el récord
    local vehicleModel = nil
    local vehicle = CocheDeCarrera() or GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle and vehicle ~= 0 then
        vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
    end

    local pago = {
        raceId = datos.raceId,
        totalTime = totalTime,
        laps = datos.totalLaps,
        ghostData = mandarFantasma and bestLapGhostData or nil,
        vehicleModel = vehicleModel or 'unknown',
        -- Lo que estuviera en juego al cruzar la meta cuenta.
        driftScore = datos.raceType == 'drift' and PuntosDeDrift() or nil,
    }

    --[[ Notificar al servidor. Con fantasma va LATENTE: son decenas de KB y
         por un evento normal se atascaba la red un momento. Sin fantasma,
         normal. La prueba de un circuito (raceId -1) no se manda: el servidor
         no tiene esa carrera. ]]
    if not datos.copiloto and not datos.prueba then
        if pago.ghostData then
            TriggerLatentServerEvent('racing:raceFinished', FANTASMA_BPS, pago)
        else
            TriggerServerEvent('racing:raceFinished', pago)
        end
    end

    -- Todo lo de la carrera fuera (marcadores, GPS, decoracion, fantasma, HUD)
    LimpiarCarrera()

    -- Disparar evento para actualizar estado global (main.lua)
    TriggerEvent('racing:localRaceFinished')

    -- Mostrar resultados (se hará desde el servidor)
    lib.notify({
        title = '🏁 ¡Carrera Finalizada!',
        description = 'Tiempo total: ' .. FormatTime(totalTime),
        type = 'success',
        duration = 5000
    })
end

--- /finprueba: deja a medias la prueba de un circuito (client/admin.lua).
AddEventHandler('racing:finPrueba', function()
    if not isRacing or not currentRaceData or not currentRaceData.prueba then return end
    TriggerEvent('racing:playerDnf', { raceId = -1, voluntary = true, position = 1 })
end)

--[[ Eliminacion: eres el unico que queda. El servidor da tu carrera por
     terminada en la vuelta que llevas; aqui se cierra como una meta normal. ]]
RegisterNetEvent('racing:eliminacion:ganas', function(data)
    if not isRacing or not currentRaceData then return end
    if data and data.raceId ~= currentRaceData.raceId then return end
    lib.notify({ title = 'Eliminación', description = 'Eres el último en pie: has ganado', type = 'success', duration = 6000 })
    OnRaceFinished()
end)

-- ========================================
-- ACTUALIZAR BLIP DEL CHECKPOINT
-- ========================================

function UpdateCheckpointBlip()
    -- Remover blips anteriores
    for _, blip in ipairs(checkpointBlips) do
        OrigenMapa.Quitar(blip)
    end
    checkpointBlips = {}

    -- Los próximos 3 checkpoints, sin pasarse de la meta (ProximosOrdenes)
    for i, p in ipairs(ProximosOrdenes(3)) do
        local cp = raceCheckpointsByOrder[p.orden]

        if cp then
            --[[ La meta va verde y con bandera; los checkpoints normales,
                 rosas. La ruta no la lleva ningun punto: la traza
                 RutaPorLosProximos por los tres, en orden. ]]
            local blip = 'checkpoint_' .. (i - 1)

            OrigenMapa.Poner(blip, {
                x = cp.coord_x, y = cp.coord_y, z = cp.coord_z,
                cat = 'racing',
                icono = p.meta and 'bandera' or nil,
                nombre = p.meta and 'Meta' or ('Checkpoint ' .. (p.orden + 1)),
                color = p.meta and '#2ee6a8' or '#d81b55',
                ruta = false,
                prioridad = 10,
            })

            table.insert(checkpointBlips, blip)
        end
    end

    RutaPorLosProximos()
end

-- ========================================
-- THREAD: ENVIAR DISTANCIA AL SERVIDOR
-- ========================================

--[[ Una vez por segundo: es lo que se le manda al servidor. Antes el hilo
     daba veinte vueltas por segundo calculando la distancia para tirar
     diecinueve de cada veinte. ]]
function RaceProgressUpdateThread()
    while isRacing and currentRaceData do
        Wait(1000)
        if not isRacing or not currentRaceData then break end

        local distancia = 999999
        if raceCheckpoints and #raceCheckpoints > 0 and currentCheckpoint then
            local orden = currentCheckpoint - 1   -- checkpoint_order empieza en 0
            if orden >= #raceCheckpoints then orden = 0 end
            local cp = raceCheckpointsByOrder[orden]
            if cp and cp.coord_x then
                distancia = #(GetEntityCoords(PlayerPedId()) - vector3(cp.coord_x, cp.coord_y, cp.coord_z))
            end
        end

        if currentRaceData and currentRaceData.raceId and not currentRaceData.copiloto then
            TriggerServerEvent('racing:syncDistance', {
                raceId = currentRaceData.raceId,
                distance = distancia
            })
        end
    end
end

-- ========================================
-- THREAD: ACTUALIZAR HUD EN TIEMPO REAL
-- ========================================

function RaceHUDUpdateThread()
    while isRacing and currentRaceData do
        Wait(250) -- 4 fps es suficiente para el HUD; era 10/s (100ms) → -60% SendNUIMessage
        UpdateRaceHUD()
    end
end

function UpdateRaceHUD()
    if not isRacing or not currentRaceData then return end

    local currentTime = GetGameTimer() - raceStartTime
    local currentLapTime = GetGameTimer() - lapStartTime

    --[[ Cuatro veces por segundo solo van los relojes. La clasificacion, los
         huecos y las mejores vueltas viajan cuando el servidor manda algo
         nuevo (hudSucio): antes iba la tabla entera en cada envio, y la
         interfaz la volvia a pintar entera cuatro veces por segundo. ]]
    local data = {
        currentLap = currentLap,
        totalLaps = currentRaceData.totalLaps,
        nextCheckpoint = currentCheckpoint,
        totalCheckpoints = #raceCheckpoints,
        currentTime = currentTime,
        currentLapTime = currentLapTime,
    }
    if hudSucio then
        hudSucio = false
        data.position = lastServerData.position
        data.totalRacers = lastServerData.totalRacers or currentRaceData.totalParticipants
        data.gapToFirst = lastServerData.gapToFirst
        data.intervalToAhead = lastServerData.intervalToAhead
        data.leaderboard = lastServerData.leaderboard
        data.bestLapOverall = lastServerData.bestLapOverall
        data.bestLap = lastServerData.bestLap
    end
    SendNUIMessage({ action = 'updateRaceHUD', data = data })
end

--[[ RECOGER LA CARRERA: lo mismo para TODAS las salidas —meta, abandono,
     DNF, expulsion, cancelacion, parar el recurso—. Antes cada una limpiaba
     a su manera y siempre se olvidaba algo: el GPS en una, los props en
     otra, el coche congelado en la de mas alla.

     Se puede llamar sin carrera (en el lobby, o dos veces): solo quita lo
     que haya. ]]
function LimpiarCarrera()
    local estabaVolviendo = volviendo
    isRacing             = false
    currentRaceData      = nil
    raceCheckpoints      = {}
    raceCheckpointsByOrder = {}
    currentCheckpoint    = 0
    currentLap           = 1
    cierraVuelta         = false
    volviendo            = false
    reiniciarTramo       = false
    tandaCarrera         = tandaCarrera + 1   -- los hilos de esta carrera se paran
    ResetServerData()

    -- El fantasma: grabacion, reproduccion y el modo sin colisiones.
    StopGhostRecording()
    StopGhostPlayback()
    EndGhostLoop()
    if cocheFantasmaNet ~= 0 then
        -- El coche que se apunto, no el que se lleve ahora.
        TriggerServerEvent('racing:registerVehicleGhost', cocheFantasmaNet, false)
        cocheFantasmaNet = 0
    end

    -- El coche de la cuenta atras, suelto (y vehicleFrozen en false siempre).
    SoltarCocheCongelado()
    cocheDeCarrera, cocheDeCarreraNet = nil, 0

    -- Puntos del mapa, GPS (ClearGpsMultiRoute + SetGpsMultiRouteRender) y
    -- carteles; y la decoracion de los checkpoints.
    ClearCheckpointMarkers()
    ClearCheckpointDelimiters()

    -- Si el fundido de volver al checkpoint quedo a medias (su hilo lo
    -- deshace solo, salvo que se pare el recurso). Un fundido ajeno —el del
    -- sistema medico— no se toca.
    if estabaVolviendo then DoScreenFadeIn(250) end

    -- El HUD y la cuenta atras.
    SendNUIMessage({ action = 'closeRaceHUD' })
    SendNUIMessage({ action = 'hideCountdown' })

    -- Para quien pregunte ya (el hilo de abajo lanza el evento a los 500 ms).
    LocalPlayer.state:set('enCarrera', false, true)
end

--- Lo comun de quedar fuera por el servidor (expulsado o carrera cancelada).
local function FueraDeLaCarrera()
    -- Resetear estado en main.lua (isInRace, isActivelyRacing, currentRace, markers)
    TriggerEvent('racing:localRaceFinished')

    -- Siempre: el jugador puede estar en el lobby con la decoracion puesta
    -- y sin carrera en marcha.
    LimpiarCarrera()

    -- Limpiar marker de punto de inicio (delega en main.lua que tiene los IDs numéricos)
    TriggerEvent('racing:cleanupStartMarkers')

    -- Cerrar lobby y hub
    SendNUIMessage({ action = 'closeRaceLobby' })
    SendNUIMessage({ action = 'closeRacingHub' })

    -- Liberar mouse y teclado (sin dejar el panel de crew sin raton)
    SoltarFocoCarreras(false)
end

-- ========================================
-- EVENTO: JUGADOR REMOVIDO DE CARRERA
-- ========================================

RegisterNetEvent('racing:removedFromRace', function(data)
    lib.notify({
        title = 'Removido de la Carrera',
        description = data and data.reason or nil,
        type = 'error',
        duration = 5000
    })

    FueraDeLaCarrera()
end)

-- ========================================
-- EVENTO: CARRERA CANCELADA
-- ========================================

--- El aviso de «Carrera cancelada» lo da main.lua (su mismo evento): aqui
--- salian dos, uno encima del otro.
RegisterNetEvent('racing:raceCancelled', function(data)
    FueraDeLaCarrera()
end)

-- ========================================
-- EVENTO: ACTUALIZACIÓN DE DATOS DE CARRERA (desde servidor)
-- ========================================

-- 🔄 COMPATIBILIDAD: Evento tradicional
RegisterNetEvent('racing:updateRaceData', function(data)
    if not isRacing or not currentRaceData then return end

    -- Actualizar lastServerData con los datos recibidos del servidor
    -- Usar ~= nil en vez de truthiness: position==0 (aunque improbable) no debe bloquearse
    if data.position ~= nil then
        lastServerData.position = data.position
        lastServerData.totalRacers = data.totalRacers or currentRaceData.totalParticipants
        lastServerData.gapToFirst = data.gapToFirst or 0
        lastServerData.intervalToAhead = data.intervalToAhead or 0
        lastServerData.leaderboard = data.leaderboard or {}
        lastServerData.bestLapOverall = data.bestLapOverall or 0
        -- bestLap: mejor vuelta personal del jugador local (rastreada en raceTracking del servidor)
        if data.bestLap then
            lastServerData.bestLap = data.bestLap
        end
    end

    -- El thread RaceHUDUpdateThread se encargará de enviar los datos combinados
    hudSucio = true
end)

-- NOTA: El state bag 'raceProgress' fue eliminado (Fix A). Los datos de carrera
-- llegan exclusivamente por TriggerClientEvent('racing:updateRaceData') arriba.

-- ========================================
-- EVENTO: POSICIÓN FINAL
-- ========================================

RegisterNetEvent('racing:finalPosition', function(data)

    -- Mostrar notificación de posición final
    local positionText = data.position .. 'º'
    local notifType = 'info'

    if data.position == 1 then
        positionText = '🏆 ' .. positionText .. ' - ¡GANASTE!'
        notifType = 'success'
    elseif data.position == 2 then
        positionText = '🥈 ' .. positionText .. ' - ¡Segundo lugar!'
        notifType = 'success'
    elseif data.position == 3 then
        positionText = '🥉 ' .. positionText .. ' - ¡Tercer lugar!'
        notifType = 'success'
    end

    lib.notify({
        title = '🏁 Posición Final: ' .. positionText,
        description = 'Tiempo total: ' .. FormatTime(data.totalTime),
        type = notifType,
        duration = 8000
    })
end)

-- ========================================
-- EVENTO: MOSTRAR RESULTADOS
-- ========================================

--[[ El panel de resultados, y UN solo hilo que lo cierra con Retroceso.

     Antes cada sitio que lo abria (meta, DNF, resultados completos, el
     espectador) lanzaba su propio hilo de Retroceso: con dos o tres abiertos a
     la vez, y si se cerraba con el raton (racing:hub:closeResults) se quedaban
     vivos para siempre esperando la tecla. Ahora hay una marca
     —resultadosAbiertos— que cierra cualquiera de los caminos.

     NO coge el foco de la NUI: los controles del juego siguen funcionando y
     el Retroceso se lee desde aqui. ]]
function AbrirResultados(datos)
    SoltarFocoCarreras(false)
    SendNUIMessage({ action = 'showRaceResults', data = datos })

    if resultadosAbiertos then return end   -- ya hay hilo
    resultadosAbiertos = true
    resultadosTanda = resultadosTanda + 1
    local mia = resultadosTanda

    CreateThread(function()
        while resultadosAbiertos and mia == resultadosTanda do
            Wait(0)
            if IsControlJustPressed(0, 194) then -- Backspace
                SendNUIMessage({ action = 'closeRaceResults' })
                resultadosAbiertos = false
            end
        end
    end)
end

--- Lo llaman los cierres que no pasan por Retroceso (el boton de la
--- interfaz, abandonar): el hilo se va solo.
function CerrarResultados()
    resultadosAbiertos = false
    resultadosTanda = resultadosTanda + 1
end

-- ✅ Evento cuando el jugador termina (INMEDIATO)
RegisterNetEvent('racing:playerFinished', function(data)

    -- ✅ LIMPIAR markers y blips (por si no se limpiaron localmente)
    ClearCheckpointMarkers()
    TriggerEvent('racing:localRaceFinished')

    AbrirResultados({ raceId = data.raceId })
end)

-- Evento DNF: abandono voluntario (leaveRace) o timer de 3 min expirado
RegisterNetEvent('racing:playerDnf', function(data)
    data = data or {}

    -- Todo lo de la carrera fuera, igual que en cualquier otra salida.
    LimpiarCarrera()
    TriggerEvent('racing:localRaceFinished')

    SoltarFocoCarreras(false)

    if data.copiloto then
        -- El copiloto: su piloto ha dejado de correr o se ha bajado del coche.
        lib.notify({ title = 'Copiloto', description = 'Has dejado de seguir la carrera', type = 'inform', duration = 4000 })
    elseif data.eliminado then
        -- Eliminacion: has sido el ultimo de la vuelta.
        lib.notify({
            title = 'Eliminado',
            description = 'Has sido el último en cruzar la línea — puesto final: ' .. (data.position or '?'),
            type = 'error',
            duration = 7000
        })
    elseif data.voluntary then
        -- Abandono voluntario: cerrar el hub completamente y mostrar solo una notificación
        CloseTabletAnimation()
        SendNUIMessage({ action = 'closeRacingHub' })
        SendNUIMessage({ action = 'closeRaceResults' })
        CerrarResultados()
        -- `detenido`: te ha esposado la policia corriendo (server/policia.lua)
        lib.notify({
            title = data.detenido and 'Detenido' or 'Carrera abandonada',
            description = data.detenido and 'Te ha detenido la policía: quedas fuera de la carrera y pierdes la entrada'
                or ('Has abandonado la carrera — posición final: ' .. (data.position or '?')),
            type = 'error',
            duration = 5000
        })
    else
        -- DNF por timer: mostrar panel de resultados completo
        lib.notify({
            title = '⏱ DNF',
            description = 'El tiempo límite expiró — no has terminado la carrera a tiempo.',
            type = 'error',
            duration = 6000
        })

        AbrirResultados({ raceId = data.raceId })
    end
end)

-- Evento cuando TODOS terminan (RESULTADOS COMPLETOS)
RegisterNetEvent('racing:showResults', function(data)
    AbrirResultados({
        raceId = data.raceId,
        isTerritory = data.isTerritory or false
    })
end)

-- ========================================
-- SISTEMA DE CONTROL DE FPS (Máximo 60 FPS)
-- ========================================

local fpsWarningActive = false  -- True cuando hay cuenta atrás activa por FPS alto

--[[ Se mide cada 250 ms con el contador de fotogramas del juego, no en cada
     fotograma: antes el hilo corria con Wait(0) toda la carrera solo para
     contar. ]]
function StartFpsMonitorThread()
    fpsWarningActive = false
    local tanda = tandaCarrera

    CreateThread(function()
        local lastFrames = GetFrameCount()
        local lastTime = GetGameTimer()

        local warningTimer = 0   -- segundos que quedan con FPS altos
        local lastWarningSecond = -1

        while isRacing and currentRaceData and tanda == tandaCarrera do
            Wait(250)
            if not isRacing or not currentRaceData or tanda ~= tandaCarrera then break end

            local now = GetGameTimer()
            local frames = GetFrameCount()
            local elapsed = now - lastTime
            local currentFps = elapsed > 0 and math.floor((frames - lastFrames) / elapsed * 1000) or 0
            lastFrames, lastTime = frames, now

            -- El umbral real lleva margen sobre los 60 que se le dicen al
            -- jugador (Config.LimiteFps.Umbral, en config.lua).
            if currentFps > (Config.LimiteFps.Umbral or 65) then
                if not fpsWarningActive then
                    fpsWarningActive = true
                    warningTimer = 10
                    lastWarningSecond = 10

                    -- Mostrar UI centrada (estado inicial)
                    SendNUIMessage({
                        action = 'fps:warning:show',
                        data   = { seconds = 10 }
                    })
                end

                -- Cuenta atrás cada segundo
                warningTimer = warningTimer - elapsed / 1000
                local secondsLeft = math.ceil(warningTimer)

                if secondsLeft ~= lastWarningSecond and secondsLeft > 0 and secondsLeft <= 10 then
                    lastWarningSecond = secondsLeft

                    -- Actualizar número en la UI
                    SendNUIMessage({
                        action = 'fps:warning:tick',
                        data   = { seconds = secondsLeft }
                    })
                end

                -- Tiempo agotado → DNF
                if warningTimer <= 0 then
                    fpsWarningActive = false

                    -- Mostrar pantalla de expulsión
                    SendNUIMessage({
                        action = 'fps:warning:kicked',
                        data   = {}
                    })

                    -- Notificar al servidor para tramitar el DNF (la prueba,
                    -- que el servidor no conoce, se deja aqui mismo).
                    if currentRaceData and currentRaceData.prueba then
                        TriggerEvent('racing:playerDnf', { raceId = -1, position = 1 })
                    elseif currentRaceData and currentRaceData.raceId then
                        TriggerServerEvent('racing:playerFpsDnf', {
                            raceId = currentRaceData.raceId
                        })
                    end
                    break
                end
            else
                -- FPS aceptable: resetear advertencia
                if fpsWarningActive then
                    fpsWarningActive = false
                    warningTimer = 0
                    lastWarningSecond = -1

                    -- Mostrar estado OK y auto-ocultar desde la UI
                    SendNUIMessage({
                        action = 'fps:warning:ok',
                        data   = {}
                    })
                end
            end
        end

        -- Al terminar la carrera (loop roto), ocultar UI si sigue visible
        fpsWarningActive = false
        SendNUIMessage({ action = 'fps:warning:hide', data = {} })
    end)
end


-- ========================================
-- DNF TIMER
-- ========================================

-- El primer clasificado cruzó la meta: mostrar countdown en el HUD
RegisterNetEvent('racing:dnfTimerStarted', function(data)
    SendNUIMessage({
        action = 'dnfTimerStarted',
        data   = { duration = data.duration }
    })
end)

-- La carrera terminó de forma natural antes del timer: ocultar el countdown
RegisterNetEvent('racing:dnfTimerStopped', function()
    SendNUIMessage({ action = 'dnfTimerStopped', data = {} })
end)

-- ========================================
-- UTILIDADES
-- ========================================

function FormatTime(ms)
    local totalSeconds = math.floor(ms / 1000)
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60
    local milliseconds = ms % 1000
    return string.format('%02d:%02d.%03d', minutes, seconds, milliseconds)
end

-- Al parar o reiniciar el recurso: lo mismo que cualquier otra salida
-- (marcadores, GPS, decoracion, fantasma, coche congelado, HUD).
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    LimpiarCarrera()
    CerrarResultados()
end)

--- Lo que se ve en el HUD de carrera ahora mismo (los exports de hud.lua).
function DatosHudCarrera()
    if not isRacing or not currentRaceData then return nil end
    return {
        position = lastServerData.position,
        totalRacers = lastServerData.totalRacers or currentRaceData.totalParticipants,
        currentLap = currentLap,
        totalLaps = currentRaceData.totalLaps,
        currentTime = GetGameTimer() - raceStartTime,
        currentLapTime = GetGameTimer() - lapStartTime,
        bestLap = lastServerData.bestLap,
        nextCheckpoint = currentCheckpoint,
        totalCheckpoints = #raceCheckpoints,
        leaderboard = lastServerData.leaderboard,
    }
end

--[[ El aviso de «estoy corriendo» para los demas recursos.

     Lo escucha origen_notify para esconder el logo de la esquina, que cae
     justo donde el HUD de carrera pone la clasificacion.

     Se vigila la variable en vez de lanzar el evento en cada sitio donde
     empieza o acaba una carrera: se acaba por una docena de caminos —meta,
     abandono, expulsion, cancelacion, reinicio— y el que se olvidase dejaria
     el logo escondido para siempre. ]]
CreateThread(function()
    local antes = false
    LocalPlayer.state:set('enCarrera', false, true)
    while true do
        Wait(500)
        local ahora = isRacing == true
        if ahora ~= antes then
            antes = ahora
            -- El estado, para quien pregunte (origen_notify lo mira cada
            -- 150 ms), y el evento, para quien prefiera enterarse al momento.
            LocalPlayer.state:set('enCarrera', ahora, true)   -- replicado: lo mira su copiloto
            TriggerEvent('origen_racing:enCarrera', ahora)
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then
        LocalPlayer.state:set('enCarrera', false, false)
        TriggerEvent('origen_racing:enCarrera', false)
    end
end)
