Intro = Intro or {}

Intro.activo   = false
Intro.progreso = 0.0
Intro.netId    = nil
Intro.ruta     = nil

local arrancando = false

local function Log(...)
    if Config.Debug then print('^5[origen_intro]^0', ...) end
end

local function Hud(visible)
    pcall(function() exports.origen_hud:toggleHud(visible) end)
end

--[[ Llama a una nativa solo si existe en este build.

     No es paranoia: TaskVehicleDriveToCoordLongRange esta documentada pero en
     este servidor no existe, y llamarla a ciegas mataba el hilo dejando al
     jugador con la pantalla en negro. Para lo accesorio -- encuadre,
     protecciones de adorno -- vale mas seguir sin ello que tumbar la intro. ]]
function Nativa(nombre, ...)
    local fn = _G[nombre]
    if type(fn) ~= 'function' then return nil end
    return fn(...)
end

--[[ SetEntityCoords te deja en el sitio en el acto, pero el mapa de alrededor
     tarda en llegar y el ped se queda flotando: no cae porque todavia no hay
     contra que caer. Se pide la colision y solo entonces se suelta.

     Copiado de origen_titlemenu/client/main.lua:657. El tope de 10 s es a
     proposito: en un sitio raro la colision puede no llegar nunca, y mas vale
     aparecer flotando un momento que no aparecer. ]]
function ColocarConSuelo(ped, x, y, z, heading)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, x, y, z, false, false, false, false)
    if heading then SetEntityHeading(ped, heading) end

    local hasta = GetGameTimer() + 10000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < hasta do
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
        Wait(0)
    end

    if GetEntityHeightAboveGround(ped) > 1.5 then
        local hay, sueloZ = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, z + 1.0, false)
        if hay then
            SetEntityCoords(ped, x, y, sueloZ, false, false, false, false)
        end
    end

    FreezeEntityPosition(ped, false)
end

--[[ El coche de la intro, siempre re-resuelto desde el netId: el handle local
     cambia al cruzar de routing bucket, y uno cacheado apuntaria a una entidad
     que ya no existe. ]]
function Intro.Coche()
    if not Intro.netId then return 0 end
    if not NetworkDoesEntityExistWithNetworkId(Intro.netId) then return 0 end
    local veh = NetToVeh(Intro.netId)
    if veh == 0 or not DoesEntityExist(veh) then return 0 end
    return veh
end

--[[ El bucket va sin poblacion para que el trayecto sea predecible, pero una
     ciudad del todo muerta se nota. Se devuelve algo de vida a mano. ]]
local function HiloDensidad()
    CreateThread(function()
        local d = Config.Densidad.intro
        while Intro.activo do
            SetPedDensityMultiplierThisFrame(d)
            SetScenarioPedDensityMultiplierThisFrame(d, d)
            SetVehicleDensityMultiplierThisFrame(d)
            SetRandomVehicleDensityMultiplierThisFrame(d)
            SetParkedVehicleDensityMultiplierThisFrame(d)
            Wait(0)
        end
    end)
end

--[[ Unos segundos de gracia al reaparecer en el mundo compartido.

     Dos mecanismos, y hacen falta los dos. `SetLocalPlayerAsGhost` es el modo
     fantasma de GTA, que solo existe entre JUGADORES en red -- es lo que usa
     origen_garages al cruzar buckets (client/classes/garage/interior.lua:62).
     Contra los NPC no hace absolutamente nada, y ahi toca quitar la colision
     entidad por entidad.

     Se usa el flag de "solo este frame" de SetEntityNoCollisionEntity: asi la
     colision vuelve sola en cuanto se deja de pedir, y no hay que acordarse de
     restaurar nada si el jugador se desconecta a medias. ]]
local function Fantasmear(netId)
    CreateThread(function()
        local F = Config.Fantasma
        local hasta = GetGameTimer() + F.duracion

        local function Coche()
            if not netId or not NetworkDoesEntityExistWithNetworkId(netId) then return 0 end
            local v = NetToVeh(netId)
            return (v ~= 0 and DoesEntityExist(v)) and v or 0
        end

        Nativa('SetLocalPlayerAsGhost', true)

        local vecinos, refresco = {}, 0

        while GetGameTimer() < hasta do
            local veh = Coche()

            if veh ~= 0 then
                Nativa('SetNetworkVehicleAsGhost', veh, true)

                if GetGameTimer() >= refresco then
                    refresco = GetGameTimer() + F.refresco
                    vecinos = {}
                    local centro = GetEntityCoords(veh)

                    for _, otro in ipairs(GetGamePool('CVehicle')) do
                        if otro ~= veh and #(GetEntityCoords(otro) - centro) <= F.radio then
                            vecinos[#vecinos + 1] = otro
                        end
                    end

                    for _, ped in ipairs(GetGamePool('CPed')) do
                        if not IsPedAPlayer(ped) and #(GetEntityCoords(ped) - centro) <= F.radio then
                            vecinos[#vecinos + 1] = ped
                        end
                    end
                end

                for i = 1, #vecinos do
                    if DoesEntityExist(vecinos[i]) then
                        SetEntityNoCollisionEntity(veh, vecinos[i], true)
                    end
                end
            end

            Wait(0)
        end

        Nativa('SetLocalPlayerAsGhost', false)

        local veh = Coche()
        if veh ~= 0 then Nativa('SetNetworkVehicleAsGhost', veh, false) end
    end)
end

local function Limpiar()
    Aviso.Ocultar()
    Intro.activo   = false
    Intro.progreso = 0.0
    Intro.netId    = nil
    Intro.ruta     = nil
    arrancando     = false
    Hud(true)
    DisplayRadar(true)
end

--[[ Se acabo la paciencia: el coche no llega. Se cierra en negro, se pone en
     el destino y se entrega el control. Es feo, pero infinitamente mejor que
     un jugador nuevo mirando una camara que no baja. ]]
function Intro.ForzarLlegada()
    if not Intro.activo then return end
    Log('llegada forzada')

    TriggerServerEvent('origen_intro:server:gracia')
    Telon.Bajar()

    local ped     = PlayerPedId()
    local destino = Intro.ruta and Intro.ruta.destino or Config.SpawnFallback
    local veh     = Intro.Coche()

    Intro.activo = false
    Camara.Cortar()

    if veh ~= 0 then
        Conduccion.Soltar(ped, veh)
        SetEntityCoords(veh, destino.x, destino.y, destino.z, false, false, false, false)
        SetEntityHeading(veh, destino.w)
        SetVehicleOnGroundProperly(veh)
        SetPedIntoVehicle(ped, veh, -1)
    else
        Conduccion.Soltar(ped, 0)
        ColocarConSuelo(ped, destino.x, destino.y, destino.z, destino.w)
    end

    Wait(300)
    Telon.Subir()
    Limpiar()
    TriggerServerEvent('origen_intro:server:controlTomado')
end

--- La intro no se puede salvar. Se deja al jugador a pie en el punto de siempre.
function Intro.Abortar(motivo)
    if not Intro.activo and not arrancando then return end
    Log('abortada:', motivo)

    TriggerServerEvent('origen_intro:server:gracia')
    if motivo ~= 'muerte' then
        Telon.Bajar()
    end

    local ped = PlayerPedId()
    Intro.activo = false
    Camara.Cortar()
    Conduccion.Soltar(ped, Intro.Coche())

    local d = Config.SpawnFallback
    ColocarConSuelo(ped, d.x, d.y, d.z, d.w)

    Wait(300)
    Telon.Cortar()
    TriggerServerEvent('origen_intro:server:abortar', motivo or 'desconocido')
    Limpiar()
end

--[[ El vigilante. Detecta por comportamiento -- velocidad, distancia, tiempo --
     y no con GetScriptTaskStatus: el hash de la tarea de conduccion no esta
     verificado, y una constante equivocada haria reemitir la tarea en bucle,
     matandola de verdad. ]]
local function HiloVigilante()
    CreateThread(function()
        local T = Config.Tiempos
        local ritmo = Ritmo.De(Intro.ruta)
        local arranque = GetGameTimer()
        local paradoDesde, sinCoche, fueraAsiento
        local reintentos, resentado = 0, false

        while Intro.activo do
            Wait(250)
            if not Intro.activo then break end

            local ped = PlayerPedId()

            if IsEntityDead(ped) then
                Intro.Abortar('muerte')
                return
            end

            if GetGameTimer() - arranque > ritmo.cliente then
                Intro.ForzarLlegada()
                return
            end

            local veh = Intro.Coche()

            if veh == 0 then
                sinCoche = sinCoche or GetGameTimer()
                if GetGameTimer() - sinCoche > 1000 then
                    Intro.Abortar('coche')
                    return
                end

            elseif GetVehiclePedIsIn(ped, false) ~= veh then
                sinCoche = nil
                fueraAsiento = fueraAsiento or GetGameTimer()
                if GetGameTimer() - fueraAsiento > 1000 then
                    if resentado then
                        Intro.Abortar('asiento')
                        return
                    end
                    resentado    = true
                    fueraAsiento = nil
                    SetPedIntoVehicle(ped, veh, -1)
                    Conduccion.Tarea(ped, veh, Intro.ruta)
                end

            else
                sinCoche, fueraAsiento = nil, nil

                local pos   = GetEntityCoords(veh)
                local meta  = Intro.ruta.destino
                local resta = #(vector2(meta.x, meta.y) - vector2(pos.x, pos.y))

                if resta > Config.Conduccion.radioEntrega then
                    if math.abs(GetEntityRoll(veh)) > 75.0 then
                        SetVehicleOnGroundProperly(veh)
                        Conduccion.Tarea(ped, veh, Intro.ruta)

                    elseif not IsVehicleDriveable(veh, false) then
                        SetVehicleEngineHealth(veh, 1000.0)
                        SetVehicleUndriveable(veh, false)
                        SetVehicleEngineOn(veh, true, true, false)
                        Conduccion.Tarea(ped, veh, Intro.ruta)

                    elseif GetEntitySpeed(veh) < T.atascoVelocidad then
                        paradoDesde = paradoDesde or GetGameTimer()
                        if GetGameTimer() - paradoDesde > T.atascoMs then
                            paradoDesde = nil
                            reintentos  = reintentos + 1
                            if reintentos > T.reintentosTarea then
                                Intro.ForzarLlegada()
                                return
                            end
                            Log('atascado, reintento', reintentos)
                            SetVehicleOnGroundProperly(veh)
                            ClearPedTasks(ped)
                            Wait(200)
                            Conduccion.Tarea(ped, veh, Intro.ruta)
                        end
                    else
                        paradoDesde = nil
                    end
                end
            end
        end
    end)
end

--[[ Pregunta al servidor y devuelve la respuesta, o revienta con un motivo.

     lib.callback.await NO devuelve nil cuando algo va mal: LANZA. Si el
     callback no esta registrado en el servidor rechaza la promesa en el acto
     (ox_lib/imports/callback/client.lua:67), y si el servidor no contesta la
     rechaza a los cinco minutos del convar ox:callbackTimeout (:12, :82).
     Sin este pcall, cualquiera de los dos casos mata el hilo con la pantalla
     en negro puesta y sin nadie que la levante. ]]
local function Preguntar(nombre)
    local ok, respuesta = pcall(lib.callback.await, nombre, false)
    if not ok then
        error(('el callback %s ha fallado: %s'):format(nombre, tostring(respuesta)), 0)
    end
    --[[ Un callback que revienta en el servidor no llega como nil: ox_lib lo
         convierte en false y deja el error en la consola del servidor. ]]
    if type(respuesta) ~= 'table' then
        error(('el callback %s ha respondido %s; mira la consola del servidor')
            :format(nombre, tostring(respuesta)), 0)
    end
    return respuesta
end

--[[ La salida de emergencia. Pase lo que pase, el jugador recupera pantalla,
     controles y camara. Se puede llamar en cualquier punto y las veces que
     haga falta. ]]
local function Rescatar(motivo)
    print(('^1[origen_intro] intro abortada (%s); se devuelve el control.^0'):format(tostring(motivo)))

    Intro.activo = false
    pcall(Camara.Cortar)

    local ped = PlayerPedId()
    pcall(Conduccion.Soltar, ped, Intro.Coche())
    Nativa('EnableAllControlActions', 0)
    FreezeEntityPosition(ped, false)

    TriggerServerEvent('origen_intro:server:abortar', tostring(motivo))
    Limpiar()
    Telon.Cortar()
end

--- Se pone a true en cuanto la camara esta puesta y la pantalla se abre.
local despegado = false

local function Arrancar()
    despegado = false

    Telon.Bajar()
    Hud(false)
    DisplayRadar(false)

    --[[ Red de seguridad independiente del hilo principal: si en 25 s no se ha
         llegado a levantar el telon, algo se ha quedado colgado donde no
         llegan los pcall y hay que sacar al jugador del negro igual. ]]
    CreateThread(function()
        local hasta = GetGameTimer() + 25000
        while GetGameTimer() < hasta do
            Wait(500)
            if despegado or not (Intro.activo or arrancando) then return end
        end
        if not despegado then
            Rescatar('la intro no arranco en 25 s')
        end
    end)

    local reserva = Preguntar('origen_intro:pedirRuta')
    if not reserva.ok then
        Log('sin ruta:', reserva.motivo or 'sin motivo')
        arrancando = false
        Hud(true)
        DisplayRadar(true)
        Telon.Subir()
        return false
    end

    Intro.ruta = reserva.ruta
    Log('ruta', reserva.ruta.etiqueta, 'modelo', reserva.modelo)

    local ped = PlayerPedId()
    local sp  = reserva.ruta.spawn

    -- Con /testintro el jugador puede estar ya dentro de un coche, y mover el
    -- ped moveria el coche entero con el.
    if IsPedInAnyVehicle(ped, false) then
        local previo = GetVehiclePedIsIn(ped, false)
        TaskLeaveVehicle(ped, previo, 16)
        local topeSalida = GetGameTimer() + 1500
        while IsPedInAnyVehicle(ped, false) and GetGameTimer() < topeSalida do Wait(0) end
    end

    ColocarConSuelo(ped, sp.x, sp.y, sp.z, sp.w)

    --[[ Aqui NO se congela al ped, y ademas tiene que quedarse quieto EN estas
         coordenadas: el coche lo crea el servidor y necesita a este cliente
         cerca para instanciarlo. Un ped congelado tampoco se deja sentar bien.
         Lo que hace falta -- que no se mueva mientras la pantalla esta en
         negro -- lo da la supresion de controles, que ya se puede arrancar
         porque la intro se considera en marcha desde este punto. ]]
    Intro.activo   = true
    Intro.progreso = 0.0
    arrancando     = false
    Conduccion.Suprimir()
    HiloDensidad()

    local coche = Preguntar('origen_intro:spawnearCoche')
    if not coche.ok then
        Log('fallo el spawn del coche:', coche.motivo or 'sin motivo')
        Intro.Abortar('spawn')
        return false
    end

    Intro.netId = coche.netId

    local ok, veh = pcall(function()
        return lib.waitFor(function()
            if NetworkDoesEntityExistWithNetworkId(Intro.netId) then
                local v = NetToVeh(Intro.netId)
                if v ~= 0 and DoesEntityExist(v) then return v end
            end
        end, 'el coche de la intro nunca llego al cliente', 10000)
    end)

    if not ok or not veh or veh == 0 then
        Intro.Abortar('coche')
        return false
    end

    -- El servidor ya lo sienta al spawnear; esto solo cubre que no haya llegado.
    if GetVehiclePedIsIn(ped, false) ~= veh then
        SetPedIntoVehicle(ped, veh, -1)
    end

    Conduccion.Preparar(ped, veh)

    local topeColision = GetGameTimer() + 8000
    while not HasCollisionLoadedAroundEntity(veh) and GetGameTimer() < topeColision do
        RequestCollisionAtCoord(sp.x, sp.y, sp.z)
        Wait(0)
    end

    local cam = Camara.Preparar(veh)
    despegado = true

    -- Un respiro antes de dar gas: el coche acaba de materializarse y la fisica
    -- todavia se esta asentando.
    Wait(Config.Conduccion.retardoArranque)
    if not Intro.activo then return false end

    Conduccion.Tarea(PlayerPedId(), Intro.Coche(), Intro.ruta)
    HiloVigilante()

    --[[ El telon se levanta desde OTRO hilo, y hay dos razones.

         La primera es lo que se quiere ver: la pantalla se descubre con el
         coche ya rodando, no arrancando desde parado. De eso se encarga
         `marcha`.

         La segunda es lo que se quiere NO ver. Quien pega la camara al coche
         frame a frame es Camara.Volar; hasta que no corre, la camara sigue
         clavada donde la dejo Preparar, en el punto de spawn. Si el telon se
         levantara antes, se veria el coche alejandose de una camara quieta y
         luego el primer frame de Volar como un salto. Volar bloquea hasta la
         llegada, asi que el relevo no puede ir detras: va en paralelo. ]]
    CreateThread(function()
        Wait(Config.Telon.marcha)
        Telon.EsperarMinimo()
        if not Intro.activo then return end
        Telon.Subir()
    end)

    Camara.Volar(cam)
    if not Intro.activo then return false end

    --[[ El relevo, en marcha. El coche no frena ni se le echa el freno de mano:
         el jugador coge el volante con el coche rodando y la camara todavia
         puesta, y lo unico que le queda por recibir es la imagen.

         Se suelta TODO aqui y no despues del aterrizaje. Si la tarea de
         conduccion siguiera viva durante el fundido, el jugador y el motor se
         pelearian por el volante justo en el momento que tiene que ser
         invisible. ]]
    ped = PlayerPedId()
    veh = Intro.Coche()
    Conduccion.Soltar(ped, veh)
    Intro.activo = false

    TriggerServerEvent('origen_intro:server:llegado')
    if Config.Tiempos.momentoSalida == 'antes' then
        Wait(400)
    end

    Camara.Aterrizar(cam)

    Limpiar()
    TriggerServerEvent('origen_intro:server:controlTomado')
    return true
end

--[[ Todo el arranque va bajo pcall. Un error a mitad dejaria al jugador en
     negro, sin controles (la supresion corre en su propio hilo) y sin camara,
     y sin nadie que lo saque de ahi. Aqui cualquier fallo acaba en Rescatar. ]]
function Intro.Empezar()
    if Intro.activo or arrancando then
        Log('ya habia una intro en curso')
        return false
    end
    arrancando = true

    local ok, resultado = pcall(Arrancar)
    if not ok then
        Rescatar(resultado)
        return false
    end

    return resultado
end

RegisterNetEvent('origen_intro:client:arrancar', function()
    CreateThread(function() Intro.Empezar() end)
end)

RegisterNetEvent('origen_intro:client:abortar', function(motivo)
    CreateThread(function() Intro.Abortar(motivo) end)
end)

RegisterNetEvent('origen_intro:client:forzar', function()
    CreateThread(function() Intro.ForzarLlegada() end)
end)

RegisterNetEvent('origen_intro:client:bucketLibre', function(netId)
    Fantasmear(netId)

    --[[ Repoblar en rampa. Al volver al bucket 0 el cliente empieza a crear
         trafico y peatones de golpe alrededor; subiendo la densidad poco a
         poco el mundo se llena en vez de aparecer. ]]
    CreateThread(function()
        local t0, dur = GetGameTimer(), Config.Densidad.rampa
        local base = Config.Densidad.intro
        while GetGameTimer() - t0 < dur do
            local p = base + (1.0 - base) * ((GetGameTimer() - t0) / dur)
            SetPedDensityMultiplierThisFrame(p)
            SetScenarioPedDensityMultiplierThisFrame(p, p)
            SetVehicleDensityMultiplierThisFrame(p)
            SetRandomVehicleDensityMultiplierThisFrame(p)
            SetParkedVehicleDensityMultiplierThisFrame(p)
            Wait(0)
        end
    end)

    --[[ Y si el cambio de dimension le ha sacado del coche, volver a sentarlo.
         El handle local cambia con el bucket, asi que se re-resuelve en cada
         vuelta en vez de guardarlo. ]]
    if not netId then return end
    CreateThread(function()
        for _ = 1, 60 do
            Wait(16)
            if NetworkDoesEntityExistWithNetworkId(netId) then
                local v = NetToVeh(netId)
                if v ~= 0 and DoesEntityExist(v) then
                    local ped = PlayerPedId()
                    if GetVehiclePedIsIn(ped, false) ~= v
                        and #(GetEntityCoords(ped) - GetEntityCoords(v)) < 6.0 then
                        SetPedIntoVehicle(ped, v, -1)
                        return
                    end
                end
            end
        end
    end)
end)

--[[ Si se reinicia el resource en mitad de una intro, el jugador se quedaria
     sin controles, sin camara y congelado. El bucket no se puede arreglar
     desde aqui: de eso se encarga el onResourceStop del servidor. ]]
AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    Intro.activo = false
    Aviso.Ocultar()
    Camara.Cortar()

    local ped = PlayerPedId()
    Conduccion.Soltar(ped, Intro.Coche())
    Nativa('EnableAllControlActions', 0)
    FreezeEntityPosition(ped, false)
    DisplayRadar(true)
    Telon.Cortar()

    -- El fantasma no se apaga solo: si el resource cae durante esos segundos,
    -- el jugador se quedaria atravesando a todo el mundo indefinidamente.
    Nativa('SetLocalPlayerAsGhost', false)
    local veh = Intro.Coche()
    if veh ~= 0 then Nativa('SetNetworkVehicleAsGhost', veh, false) end
end)
