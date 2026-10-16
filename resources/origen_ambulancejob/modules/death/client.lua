local NetworkResurrectLocalPlayer  = NetworkResurrectLocalPlayer
local ShakeGameplayCam             = ShakeGameplayCam
local AnimpostfxPlay               = AnimpostfxPlay
local CreateThread                 = CreateThread
local Wait                         = Wait
local SetEntityCoords              = SetEntityCoords
local TaskPlayAnim                 = TaskPlayAnim
local FreezeEntityPosition         = FreezeEntityPosition
local ClearPedTasks                = ClearPedTasks
local SetEntityHealth              = SetEntityHealth
local SetEntityInvincible          = SetEntityInvincible
local SetEveryoneIgnorePlayer      = SetEveryoneIgnorePlayer
local GetGameTimer                 = GetGameTimer
local IsControlJustPressed         = IsControlJustPressed
local TriggerServerEvent           = TriggerServerEvent
local AddEventHandler              = AddEventHandler
local SetEntityHeading             = SetEntityHeading
local PlayerPedId                  = PlayerPedId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local IsPedAPlayer                 = IsPedAPlayer
local IsPedDeadOrDying             = IsPedDeadOrDying
local IsPedFatallyInjured          = IsPedFatallyInjured

local animations                   = lib.load("config").animations

--[[ ── El parte para el propio herido ──────────────────────────────────────

     Las lesiones ya se registraban (`player.injuries`, por hueso) pero solo
     las veia el sanitario al examinarte. El que estaba en el suelo miraba un
     reloj y nada mas, sin saber siquiera de que se estaba muriendo.

     Esto pasa esa misma tabla a la NUI. No añade informacion que el jugador no
     deba tener: es su cuerpo, y lo que sale es lo que cualquiera notaria de si
     mismo —donde le duele y cuanto—. ]]
local datosArmas = lib.load("data.weapons")

--- Las unicas causas que data/weapons registra. Cuando el arma no esta en esa
--- tabla, `updateInjuries` guarda la cadena "not found", y pasarsela a locale()
--- devuelve la propia clave: en pantalla se leeria "Torax superior · not
--- found". Sin causa reconocida, no se dice ninguna.
local causasConNombre = { shot = true, beaten = true, stabbed = true, burn = true }

--- La tabla de lesiones es un diccionario por hueso; el JSON de una NUI
--- necesita una lista, o llega como objeto y no se puede recorrer con v-for.
--- De paso van ordenadas de mas grave a menos: lo primero que se lee es lo
--- que mas importa.
local function parteDeLesiones()
    local lista = {}

    for _, lesion in pairs(player.injuries or {}) do
        lista[#lista + 1] = {
            bone = lesion.bone,
            label = lesion.label,
            desc = lesion.desc,
            value = lesion.value or 0,
            cause = lesion.cause,
            causeLabel = causasConNombre[lesion.cause] and locale(lesion.cause) or nil,
        }
    end

    table.sort(lista, function(a, b) return (a.value or 0) > (b.value or 0) end)

    return lista
end

--[[ ── La camara desde arriba ────────────────────────────────────────────

     Tumbado, la camara se quedaba pegada a la nuca del personaje y lo unico
     que veias era el suelo a un palmo de la cara. Desde arriba se ve el cuerpo,
     donde ha caido y si viene alguien, que es de lo que va estar inconsciente:
     esperar y mirar.

     No va recta hacia abajo —un cenital puro aplana la escena y no se sabe ni
     hacia donde miras—: se aparta un poco en horizontal y gira muy despacio
     alrededor del cuerpo. ]]
local ALTURA_CAMARA = 3.4  -- metros por encima del cuerpo
local RADIO_CAMARA = 2.6   -- cuanto se aparta en horizontal
local VUELTA_SEG = 90.0    -- segundos que tarda en dar la vuelta entera

--[[ ── La vista libre ────────────────────────────────────────────────────

     Con [V] la vuelta se para y la camara pasa al raton: mueves el raton para
     mirar y la rueda acerca o aleja. Otra vez [V] y vuelve a girar sola desde
     donde la habias dejado, sin saltos: los dos modos mueven la MISMA camara y
     comparten las mismas coordenadas (`orbita`), asi que cambiar de uno a otro
     no recoloca nada.

     Gira alrededor del cuerpo, no vuela. Tirado no puedes andar, y una camara
     suelta seria ver quien viene por detras de la esquina sin estar consciente
     para saberlo; por lo mismo se recoge contra lo que se cruce —una pared, un
     coche— en vez de atravesarlo.

     El raton no puede estar en dos sitios: mientras dura la vista libre se
     suelta el cursor, asi que el panel se aparta y [E] y [G] no responden hasta
     volver. ]]
local DIST_MIN, DIST_MAX = 1.4, 10.0   -- lo que puede acercarse y alejarse
local ELEV_MIN, ELEV_MAX = 2.0, 85.0   -- grados sobre el horizonte del cuerpo
local SENS_RATON = 8.0                 -- grados por unidad de raton
local PASO_RUEDA = 0.55                -- metros por diente de la rueda
local TECLA_VISTA = 0                  -- INPUT_NEXT_CAMERA, la [V] de cambiar de camara

local camaraMuerte = nil
local vistaLibre = false
local ultimoCambioVista = 0

-- Si el herido esta escribiendo la nota del panel (ver deathEscribiendo).
local escribiendoNota = false

--[[ Donde esta la camara, en polares alrededor del cuerpo. La vuelta de
     siempre es este mismo punto con la altura y la distancia quietas: 2.6 m
     apartada y 3.4 m arriba son 4.28 m de distancia a 52.6 grados. ]]
local ORBITA_ELEV = math.deg(math.atan(ALTURA_CAMARA / RADIO_CAMARA))
local ORBITA_DIST = math.sqrt(ALTURA_CAMARA * ALTURA_CAMARA + RADIO_CAMARA * RADIO_CAMARA)

local orbita = { yaw = 0.0, elev = ORBITA_ELEV, dist = ORBITA_DIST }

--- Recoge la camara hasta lo primero que se cruce entre el cuerpo y ella. Sin
--- esto la vista libre se mete en las paredes: ademas de verse el ladrillo por
--- dentro, seria mirar desde donde no estas.
local function recogerCamara(mira, dx, dy, dz, ignorar)
    -- Desde un palmo por encima del cuerpo: al ras del suelo la sonda sale ya
    -- dentro de la acera y devuelve un choque en cada fotograma.
    local ox, oy, oz = mira.x, mira.y, mira.z + 0.3

    local sonda = StartExpensiveSynchronousShapeTestLosProbe(ox, oy, oz, dx, dy, dz, 1 + 16, ignorar, 4)
    local _, golpe, punto = GetShapeTestResult(sonda)

    if not golpe or golpe == 0 then return dx, dy, dz end

    local hx, hy, hz = punto.x - ox, punto.y - oy, punto.z - oz
    local largo = math.sqrt(hx * hx + hy * hy + hz * hz)

    -- Un palmo por delante de lo que se ha cruzado, o el plano de recorte de la
    -- camara deja ver el otro lado de la pared.
    if largo <= 0.35 then return ox, oy, oz end

    local recorte = (largo - 0.25) / largo
    return ox + hx * recorte, oy + hy * recorte, oz + hz * recorte
end

local function soltarCamaraMuerte()
    if not camaraMuerte then return end

    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(camaraMuerte, false)
    camaraMuerte = nil
    vistaLibre = false
end

--- Cambia entre la vuelta y la vista libre. Lo llaman dos sitios —la tecla
--- desde el juego y la misma tecla desde la NUI, que es quien tiene el teclado
--- mientras se ve el panel—, de ahi el margen de un cuarto de segundo: si
--- llegan las dos, la segunda no deshace lo que acaba de hacer la primera.
local function ponerVistaLibre(activa)
    -- Reapareciendo, la pantalla ya esta escondida: volver de la vista libre
    -- cogeria el foco sin nada delante.
    if not player.isDead or player.respawning or vistaLibre == activa then return end

    local ahora = GetGameTimer()
    if ahora - ultimoCambioVista < 250 then return end
    ultimoCambioVista = ahora

    vistaLibre = activa

    if activa then
        SetNuiFocus(false, false)
    else
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
    end

    SendNUIMessage({ action = "deathCamera", free = activa })
end

local function montarCamaraMuerte()
    if camaraMuerte then return end

    local ped = cache.ped or PlayerPedId()
    local c = GetEntityCoords(ped)

    vistaLibre = false
    orbita.yaw, orbita.elev, orbita.dist = 0.0, ORBITA_ELEV, ORBITA_DIST

    camaraMuerte = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(camaraMuerte, c.x, c.y + RADIO_CAMARA, c.z + ALTURA_CAMARA)
    PointCamAtCoord(camaraMuerte, c.x, c.y, c.z)
    SetCamActive(camaraMuerte, true)
    RenderScriptCams(true, true, 900, true, true)

    -- El giro. Sigue al cuerpo por si lo mueven —una camilla, un coche— para
    -- no quedarse mirando el sitio donde estabas.
    CreateThread(function()
        local ultimo = GetGameTimer()

        while camaraMuerte and player.isDead do
            local ahora = GetGameTimer()
            local dt = (ahora - ultimo) / 1000.0
            ultimo = ahora

            local vivo = cache.ped or PlayerPedId()
            local pos = GetEntityCoords(vivo)

            if vistaLibre then
                --[[ El raton va sin `dt`: lo que llega ya es lo que se ha
                     movido en este fotograma, no una velocidad. ]]
                orbita.yaw = (orbita.yaw - GetDisabledControlNormal(0, 1) * SENS_RATON) % 360.0
                orbita.elev = math.min(ELEV_MAX, math.max(ELEV_MIN,
                    orbita.elev - GetDisabledControlNormal(0, 2) * SENS_RATON))

                -- La rueda. 14/15 es la del juego y 241/242 la del cursor:
                -- llega por una o por otra segun quien tenga el raton.
                if IsDisabledControlJustPressed(0, 15) or IsDisabledControlJustPressed(0, 241) then
                    orbita.dist = math.max(DIST_MIN, orbita.dist - PASO_RUEDA)
                elseif IsDisabledControlJustPressed(0, 14) or IsDisabledControlJustPressed(0, 242) then
                    orbita.dist = math.min(DIST_MAX, orbita.dist + PASO_RUEDA)
                end
            else
                orbita.yaw = (orbita.yaw + (360.0 / VUELTA_SEG) * dt) % 360.0

                -- Al volver de la vista libre, la altura y la distancia
                -- regresan solas a las de la vuelta en vez de dar el salto.
                local vuelve = math.min(1.0, dt * 2.5)
                orbita.elev = orbita.elev + (ORBITA_ELEV - orbita.elev) * vuelve
                orbita.dist = orbita.dist + (ORBITA_DIST - orbita.dist) * vuelve
            end

            local yaw = math.rad(orbita.yaw)
            local elev = math.rad(orbita.elev)
            local plano = math.cos(elev) * orbita.dist

            local dx = pos.x + math.sin(yaw) * plano
            local dy = pos.y + math.cos(yaw) * plano
            local dz = pos.z + math.sin(elev) * orbita.dist

            -- La vuelta se queda como estaba: a 4.3 m del cuerpo y mirando
            -- desde arriba no se mete en nada, y la sonda solo se paga cuando
            -- de verdad se puede acabar dentro de una pared.
            if vistaLibre then
                dx, dy, dz = recogerCamara(pos, dx, dy, dz, vivo)
            end

            SetCamCoord(camaraMuerte, dx, dy, dz)
            PointCamAtCoord(camaraMuerte, pos.x, pos.y, pos.z)

            Wait(0)
        end

        soltarCamaraMuerte()
    end)
end

--- Donde estas, en palabras. Es lo que viaja en el aviso al 911, asi que
--- conviene verlo antes de mandarlo.
local function dondeEstas()
    local c = GetEntityCoords(cache.ped or PlayerPedId())
    local calleHash, cruceHash = GetStreetNameAtCoord(c.x, c.y, c.z)

    local calle = calleHash ~= 0 and GetStreetNameFromHashKey(calleHash) or nil
    local cruce = cruceHash ~= 0 and GetStreetNameFromHashKey(cruceHash) or nil
    local zona = GetLabelText(GetNameOfZone(c.x, c.y, c.z))

    -- GetLabelText devuelve "NULL" cuando la zona no tiene nombre traducido.
    if zona == "NULL" or zona == "" then zona = nil end

    local coords = ("%d, %d"):format(math.floor(c.x + 0.5), math.floor(c.y + 0.5))

    return calle, cruce, zona, coords
end

--- Una huella del parte para no reenviarlo cuatro veces por segundo. Vue
--- reemplaza la lista entera cada vez que llega y vuelve a pintar todas las
--- filas; con el reloj corriendo eso es un repintado constante de algo que no
--- ha cambiado.
local function firmaDelParte(lista)
    local trozos = {}
    for i = 1, #lista do
        trozos[#trozos + 1] = (lista[i].bone or "?") .. ":" .. (lista[i].value or 0)
    end
    return table.concat(trozos, "|")
end

--[[ Mientras dura la reanimacion el cuerpo sigue muerto para el juego: el
     NetworkResurrectLocalPlayer de mas abajo no llega hasta que termina el
     fundido, y eso son casi un segundo con `player.isDead` ya en false. En ese
     hueco el hilo de respaldo —que mira cada medio segundo si el ped esta
     muerto— volvia a dar por muerto al que se estaba levantando y montaba la
     pantalla otra vez. De ahi que hubiera que reanimar dos veces: la primera
     te dejaba vivo y con el panel delante.

     Tambien evita que la reanimacion se solape consigo misma: el comando manda
     `healPlayer` y ademas `hospital:client:Revive`, o sea stopPlayerDeath dos
     veces en el mismo fotograma. ]]
local reanimarCuerpo

function stopPlayerDeath()
    if player.reanimando then return end
    player.reanimando = true

    --[[ Si algo falla a mitad, el candado se quedaba puesto para siempre: a
         partir de ahi ningun /revive hacia nada y el hilo de respaldo dejaba
         de ver las muertes. Se suelta pase lo que pase. ]]
    local ok, err = pcall(reanimarCuerpo)
    player.reanimando = false
    if not ok then
        print(('^1[origen_ambulancejob]^0 La reanimacion fallo: %s'):format(err))
    end
end

reanimarCuerpo = function()

    player.isDead = false
    player.causaMuerte = nil

    -- Lo que veia el sanitario de ti: ya no estas en el suelo.
    LocalPlayer.state:set("samsCaido", nil, true)
    LocalPlayer.state:set("samsNota", nil, true)

    soltarCamaraMuerte()
    SetNuiFocus(false, false)
    -- El KeepInput de la pantalla de muerte es global: se apaga al salir.
    SetNuiFocusKeepInput(false)
    -- player.injuries = {}

    SendNUIMessage({
        action = "hideDeath"
    })
    AnimpostfxStopAll()

    local playerPed = cache.ped or PlayerPedId()

    -- Comprobar si el jugador está actualmente en un vehículo y en qué asiento
    local veh = GetVehiclePedIsIn(playerPed, false)
    local inVehicle = veh ~= 0 and DoesEntityExist(veh)
    local seat = -1
    if inVehicle then
        for s = -1, GetVehicleMaxNumberOfPassengers(veh) - 1 do
            if GetPedInVehicleSeat(veh, s) == playerPed then
                seat = s
                break
            end
        end
    end

    local estaMuerto = IsEntityDead(playerPed)

    -- Solo resucitar entidad en el motor si está muerta (evita desincronizaciones en vehículos)
    if estaMuerto then
        local coords = cache.coords or GetEntityCoords(playerPed)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(playerPed), false, false)
        playerPed = PlayerPedId()
    end

    local deathStatus = { isDead = false }
    TriggerServerEvent('origen_ambulancejob:updateDeathStatus', deathStatus)

    if inVehicle then
        -- Si está dentro del coche: detener la animación de muerte sin sacarlo del vehículo
        if animations and animations["death_car"] then
            StopAnimTask(playerPed, animations["death_car"].dict, animations["death_car"].clip, 1.0)
        end
        ClearPedSecondaryTask(playerPed)

        -- Si la resurrección lo desplazó fuera, devolverlo a su asiento
        if GetVehiclePedIsIn(playerPed, false) ~= veh then
            SetPedIntoVehicle(playerPed, veh, seat)
        end
    else
        -- Si estaba a pie: limpiar tareas para que se levante del suelo
        ClearPedTasksImmediately(playerPed)
    end

    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)
    SetEntityInvincible(playerPed, false)
    SetEveryoneIgnorePlayer(cache.playerId or PlayerId(), false)
    AnimpostfxStopAll()

    -- Asegurar que la pantalla no quede en negro ni haya fundidos
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(0)
    end

    LocalPlayer.state:set("dead", false, true)
    player.distressCallTime = nil

    Framework.playerSpawned()
    healPlayer()

    -- El cuerpo ya esta vivo y curado: el hilo de respaldo puede volver a
    -- vigilar sin confundir esto con una muerte nueva (stopPlayerDeath suelta
    -- el candado al volver de aqui).
end

function healPlayer()
    local playerPed = cache.ped or PlayerPedId()
    local maxHealth = GetEntityMaxHealth(playerPed)
    if not maxHealth or maxHealth < 100 then maxHealth = 200 end

    SetEntityHealth(playerPed, maxHealth)
    ClearPedBloodDamage(playerPed)
    ResetPedVisibleDamage(playerPed)
    ClearPedLastWeaponDamage(playerPed)

    -- Subir comida y bebida (hambre y sed) al 100%
    TriggerServerEvent('consumables:server:setHunger', 100)
    TriggerServerEvent('consumables:server:setThirst', 100)
    TriggerServerEvent('consumables:server:addHunger', 100)
    TriggerServerEvent('consumables:server:addThirst', 100)
    TriggerServerEvent('origen_ambulancejob:server:restoreNeeds')

    Framework.healStatus()
end

RegisterNetEvent("origen_ambulancejob:healPlayer", function(data)
    if data and data.revive then
        stopPlayerDeath()
    elseif data and data.injury then
        treatInjury(data.bone)
    elseif data and data.heal then
        healPlayer()
    else
        stopPlayerDeath()
    end
end)

RegisterNetEvent("hospital:client:Revive", function()
    stopPlayerDeath()
end)

RegisterNetEvent("hospital:client:KillPlayer", function()
    local ped = cache.ped or PlayerPedId()
    SetEntityHealth(ped, 0)
end)

RegisterNetEvent("hospital:client:Heal", function()
    healPlayer()
end)

RegisterNetEvent("qb-ambulancejob:client:revive", function()
    stopPlayerDeath()
end)

RegisterNetEvent("esx_ambulancejob:revive", function()
    stopPlayerDeath()
end)

RegisterNetEvent("qbx_medical:client:playerRevived", function()
    stopPlayerDeath()
end)

RegisterNetEvent("origen_ambulancejob:client:revive", function()
    stopPlayerDeath()
end)

--[[ `opciones.conservarObjetos`: no se quita el inventario aunque la config lo
     diga. Lo usa el ingreso por mision (evento aCamilla, mas abajo): alli no
     se ha muerto nadie, solo se le atiende. ]]
local function respawnPlayer(opciones)
    local playerPed = cache.ped or PlayerPedId()

    local hospitalKey, hospital = utils.getClosestHospital()
    if not hospitalKey or not hospital then
        hospitalKey = "pillbox"
        local hospitals = lib.load("data.hospitals") or {}
        hospital = hospitals["pillbox"]
    end

    -- Solicitar camilla disponible en el servidor (gestión de concurrencia y camas ocupadas)
    local bedIndex, bed = nil, nil
    local ok, resIdx, resBed = pcall(function()
        return lib.callback.await('origen_ambulancejob:server:requestRespawnBed', false, hospitalKey)
    end)

    if ok and resIdx and resBed then
        bedIndex, bed = resIdx, resBed
    else
        -- Fallback de seguridad si el callback del servidor no responde o está reiniciándose
        local dynBeds = nil
        if GetResourceState('origen_police') == 'started' then
            pcall(function()
                dynBeds = exports['origen_police']:GetHospitalBeds(hospitalKey)
            end)
        end
        if dynBeds and #dynBeds > 0 then
            bedIndex = 1
            bed = dynBeds[1]
        elseif hospital and hospital.respawn and #hospital.respawn > 0 then
            bedIndex = 1
            bed = hospital.respawn[1]
        else
            bedIndex = 1
            bed = {
                bedPoint = vector4(349.76, -583.44, 43.0, 150.04),
                spawnPoint = vector4(348.84, -583.36, 42.32, 68.24)
            }
        end
    end

    if not bed or not bedIndex then
        utils.showNotification(locale("all_beds_occupied") or "Todas las camillas del hospital están ocupadas. Por favor, espera un momento.", "error")
        player.respawning = false
        return false
    end

    player.respawning = true

    soltarCamaraMuerte()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = "hideDeath"
    })
    AnimpostfxStopAll()

    local shouldRemove = not (opciones and opciones.conservarObjetos) and GetEMSConfigVal("removeItemsOnRespawn", true)
    if shouldRemove then
        TriggerServerEvent("origen_ambulancejob:removeInventory")
    end

    lib.requestAnimDict("timetable@tracy@sleep@")
    lib.requestAnimDict("switch@franklin@bed")

    local bX = bed.bedPoint.x or bed.bedPoint[1] or 0.0
    local bY = bed.bedPoint.y or bed.bedPoint[2] or 0.0
    local bZ = bed.bedPoint.z or bed.bedPoint[3] or 0.0
    local bH = bed.bedPoint.w or bed.bedPoint.h or bed.bedPoint[4] or 0.0

    local sX = bed.spawnPoint.x or bed.spawnPoint[1] or bX
    local sY = bed.spawnPoint.y or bed.spawnPoint[2] or bY
    local sZ = bed.spawnPoint.z or bed.spawnPoint[3] or bZ
    local sH = bed.spawnPoint.w or bed.spawnPoint.h or bed.spawnPoint[4] or bH

    utils.doScreenFadeOut(800, true)

    SetEntityCoords(playerPed, bX, bY, bZ)
    SetEntityHeading(playerPed, bH)
    TaskPlayAnim(playerPed, "timetable@tracy@sleep@", "base", 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(playerPed, true)

    utils.doScreenFadeIn(400)
    Wait(4500)

    SetEntityCoords(playerPed, bX, bY, bZ - 1.0)
    FreezeEntityPosition(playerPed, false)
    SetEntityHeading(playerPed, bH + 90.0)
    TaskPlayAnim(playerPed, "switch@franklin@bed", "sleep_getup_rubeyes", 1.0, 1.0, -1, 8, -1, 0, 0, 0)

    Wait(4000)

    stopPlayerDeath()
    ClearPedTasks(playerPed)
    SetEntityCoords(playerPed, sX, sY, sZ)
    SetEntityHeading(playerPed, sH)
    player.respawning = false

    -- Liberar la camilla en el servidor
    TriggerServerEvent("origen_ambulancejob:server:releaseRespawnBed", hospitalKey, bedIndex)
    return true
end

--[[ Las dos acciones llegan de la NUI y no del juego.

     Con el raton puesto en la interfaz el juego deja de recibir teclas, asi
     que `IsControlJustPressed` ya no se enteraba de nada. Ahora [E] y [G] los
     escucha la propia pantalla, igual que el clic en los botones, y el aguante
     de los cinco segundos se cuenta alli: un solo contador para el raton y
     para el teclado. ]]
--[[ La nota que escribe el herido en el panel viaja dentro del aviso. Se
     vuelve a limpiar aqui aunque la NUI ya la corte: es texto del jugador
     camino de las pantallas de otros. ]]
local NOTA_MAX = 120

local function limpiarNota(nota)
    if type(nota) ~= "string" then return nil end
    nota = nota:gsub("[%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$")
    if nota == "" then return nil end
    return nota:sub(1, NOTA_MAX)
end

RegisterNUICallback("deathCall", function(data, cb)
    cb({})
    if not player.isDead then return end

    if player.distressCallTime then
        local waitMinutes = tonumber(GetEMSConfigVal("waitTimeForNewCall", 1)) or 1
        if waitMinutes <= 0 then waitMinutes = 1 end
        local waitSeconds = math.floor(waitMinutes * 60)
        local passedSeconds = math.floor((GetGameTimer() - player.distressCallTime) / 1000)
        if passedSeconds < waitSeconds then
            local restante = waitSeconds - passedSeconds
            utils.showNotification(("Debes esperar %d segundos para volver a solicitar auxilio."):format(restante), "error")
            return
        end
    end

    local nota = limpiarNota(data and data.nota)
    createDistressCall(nota and ("Ciudadano inconsciente: " .. nota) or nil)

    -- La nota tambien la ve el sanitario al examinarte (modules/job).
    LocalPlayer.state:set("samsNota", nota, true)
end)

--[[ Escribiendo la nota. Aqui KeepInput va encendido (ver initPlayerDeath),
     asi que cada letra llegaria tambien al juego: la T abriria el chat y los
     numeros cambiarian de arma. Mientras el campo tiene el foco se apaga, y al
     soltarlo vuelve. ]]
RegisterNUICallback("deathEscribiendo", function(data, cb)
    cb({})
    -- Se apunta antes de la guarda: el repaso de initPlayerDeath lo mira para
    -- no volver a encender KeepInput en mitad de la nota.
    escribiendoNota = (data and data.activo) == true
    if not player.isDead or vistaLibre then return end
    SetNuiFocusKeepInput(not (data and data.activo))
end)

--[[ La misma [V], pero llegando desde la NUI.

     Mientras se ve el panel el teclado lo tiene la interfaz, asi que la tecla
     se escucha en los dos sitios y gana la que llegue antes (ver el margen de
     `ponerVistaLibre`). Para volver solo vale la del juego: en vista libre la
     NUI ya no tiene foco. ]]
RegisterNUICallback("deathFreeCam", function(_, cb)
    cb({})
    if player.isDead then ponerVistaLibre(not vistaLibre) end
end)

--[[ Ingreso en la camilla libre mas cercana (las que se colocan desde el panel
     de origen_police), igual que al reaparecer pero sin quitar objetos. Lo
     manda el SERVIDOR: el NPC de hospital de las misiones (origen_quests, con
     su pase). Un TriggerEvent local llega con source '' y no vale. ]]
RegisterNetEvent("origen_ambulancejob:client:aCamilla", function()
    if source == '' then return end
    if player.respawning then return end
    CreateThread(function()
        respawnPlayer({ conservarObjetos = true })
    end)
end)

RegisterNUICallback("deathRespawn", function(_, cb)
    cb({})
    if player.isDead and not player.respawning then respawnPlayer() end
end)

local function initPlayerDeath(logged_dead)
    if player.isDead then return end

    player.isDead = true
    player.distressCallTime = nil
    escribiendoNota = false
    startCommandTimer()

    for _, anim in pairs(animations) do
        lib.requestAnimDict(anim.dict)
    end

    AnimpostfxStopAll()

    local playerPed = PlayerPedId()

    --[[ Con las teclas del juego encendidas (ver el KeepInput de mas abajo) hay
         que apagar a mano lo que estorba, o pasan dos cosas: el clic en un
         boton llega tambien al juego como un golpe, y [E] y [G] los recogen a
         la vez la pantalla y cualquier otro recurso que los escuche.

         Lo que NO se toca es hablar: es lo unico que puedes hacer tirado. ]]
    CreateThread(function()
        local ultimoRepaso = 0

        while player.isDead do
            DisableFirstPersonCamThisFrame()

            --[[ KeepInput es un interruptor global, y la red de seguridad
                 (origen_map/shared/foco.lua) lo apaga cada vez que otro recurso
                 coge el foco. Al cerrarse ese otro panel, esta pantalla sigue con
                 su foco pero sin KeepInput: mudo en el suelo. Se repasa cada
                 medio segundo. Sin foco nuestro (vista libre, la caida antes de
                 montar la pantalla) el envoltorio no deja encenderlo. ]]
            local ahora = GetGameTimer()
            if ahora - ultimoRepaso >= 500 then
                ultimoRepaso = ahora
                -- Con otro panel encima (el chat), no: lo que se escribe ahi
                -- llegaria tambien al juego. Lo sabe el vigilante del foco.
                local otroEncima = OrigenFoco and OrigenFoco.OtroConFoco()
                if not vistaLibre and not player.respawning and not escribiendoNota
                    and not otroEncima and not IsNuiFocusKeepingInput() then
                    SetNuiFocusKeepInput(true)
                end
            end

            DisableControlAction(0, 24, true)  -- atacar
            DisableControlAction(0, 25, true)  -- apuntar
            DisableControlAction(0, 140, true) -- golpe corto
            DisableControlAction(0, 141, true) -- golpe fuerte
            DisableControlAction(0, 142, true) -- golpe alterno
            DisableControlAction(0, 257, true) -- atacar (secundario)
            DisableControlAction(0, 263, true) -- cuerpo a cuerpo
            DisableControlAction(0, 22, true)  -- saltar
            DisableControlAction(0, 38, true)  -- [E], lo escucha la pantalla
            DisableControlAction(0, 47, true)  -- [G], lo escucha la pantalla

            -- [V] y la rueda son de la camara mientras estas en el suelo: sin
            -- apagarlas, [V] cambiaria ademas la vista del juego y la rueda
            -- sacaria el selector de armas por debajo del panel.
            DisableControlAction(0, TECLA_VISTA, true)
            DisableControlAction(0, 14, true)
            DisableControlAction(0, 15, true)
            DisableControlAction(0, 37, true)

            if IsDisabledControlJustPressed(0, TECLA_VISTA) then
                ponerVistaLibre(not vistaLibre)
            end

            Wait(0)
        end
    end)

    if not logged_dead then
        local inVehicle = IsPedInAnyVehicle(playerPed, false)

        if inVehicle then
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            local seat = -1
            for i = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
                if GetPedInVehicleSeat(vehicle, i) == playerPed then
                    seat = i
                    break
                end
            end

            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, false, false)
            playerPed = PlayerPedId()

            if vehicle and DoesEntityExist(vehicle) then
                SetPedIntoVehicle(playerPed, vehicle, seat)
            end
        else
            -- Permitir la física natural de caída y ragdoll al recibir daño mortal
            SetPedToRagdoll(playerPed, 2500, 2500, 0, false, false, false)

            local startFall = GetGameTimer()
            while (GetGameTimer() - startFall < 2500) and player.isDead do
                Wait(100)
                if not IsPedRagdoll(playerPed) and GetEntitySpeed(playerPed) < 0.1 then
                    break
                end
            end
            Wait(300)

            if not player.isDead then return end

            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)
            NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, false, false)
            playerPed = PlayerPedId()
        end
    else
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, false, false)
        playerPed = PlayerPedId()

        if cache.vehicle then
            SetPedIntoVehicle(playerPed, cache.vehicle, cache.seat)
        end
    end

    SetEntityInvincible(playerPed, true)
    SetEntityHealth(playerPed, 100)

    -- Desde cuando estas en el suelo, para el diagnostico del sanitario. Hora
    -- de red: la del juego de cada cliente no se parece a la de los demas.
    LocalPlayer.state:set("samsCaido", GetCloudTimeAsInt(), true)
    LocalPlayer.state:set("samsNota", nil, true)
    SetEveryoneIgnorePlayer(cache.playerId or PlayerId(), true)

    local currentRespawnMin = tonumber(GetEMSConfigVal("respawnTime", 0)) or 0
    local totalRespawnSeconds = math.floor(currentRespawnMin * 60)
    local deathTime = GetGameTimer()

    -- El camino del coche y el de entrar ya muerto no vuelven a mirar: si te
    -- han revivido mientras cargaba, la pantalla saldria estando vivo.
    if not player.isDead then return end

    montarCamaraMuerte()

    --[[ El raton, para poder pulsar los botones.

         Y KeepInput encendido, al reves que en los paneles del riel. Alli se
         apaga porque el raton movia la camara por detras y al pulsar un boton
         el personaje soltaba un puñetazo. Aqui no puede pasar: la camara la
         llevamos nosotros —un scripted cam no atiende al raton— y el cuerpo
         esta invencible y retomando su animacion en cada vuelta del bucle.

         Lo que si haria falta apagarlo es la voz: sin KeepInput el juego deja
         de recibir teclas y te quedas mudo en el suelo, que es justo cuando
         mas falta hace poder decir algo. Lo que estorba se apaga control a
         control, mas abajo. ]]
    -- La ficha del paciente es la misma pagina: si caes con ella abierta, se
    -- cierra, o su Escape soltaria el raton de esta pantalla.
    SendNUIMessage({ action = "closeDiagnosis" })
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)

    local parteInicial = parteDeLesiones()
    local calle, cruce, zona, coords = dondeEstas()

    SendNUIMessage({
        action = "showDeath",
        remainingSeconds = totalRespawnSeconds,
        totalSeconds = math.max(1, totalRespawnSeconds),
        canRespawn = (totalRespawnSeconds <= 0),
        callCooldown = 0,
        downSeconds = 0,
        medics = 0,
        distressSent = false,
        street = calle,
        crossing = cruce,
        zone = zona,
        coords = coords,
        injuries = parteInicial,
        killedBy = player.causaMuerte
    })

    CreateThread(function()
        local lastUpdate = 0
        --[[ El hueso que te mata se registra DESPUES de esta pantalla: el
             manejador del evento llama primero a initPlayerDeath y luego a
             updateInjuries. Por eso el parte se vigila aqui en vez de darlo
             por cerrado arriba. ]]
        local ultimaFirma = firmaDelParte(parteInicial)

        -- Cuantos sanitarios hay de guardia. Es una vuelta al servidor, asi que
        -- se pregunta cada diez segundos y no cuatro veces por segundo.
        local sanitarios = 0
        local ultimoRecuento = 0

        -- La calle solo cambia si te mueven: no hace falta mirarla mas a menudo.
        local calleAhora, cruceAhora, zonaAhora, coordsAhora = dondeEstas()
        local ultimoSitio = 0

        while player.isDead do
            local sleep = 500

            if not player.gettingRevived and not player.respawning then
                sleep = 0
                local currentPed = PlayerPedId()
                local inVeh = IsPedInAnyVehicle(currentPed, false)
                local anim = inVeh and animations["death_car"] or animations["death_normal"]

                --[[ A hombros (cargar de origen_inventory) la animacion es la
                     suya: reponer la de tirado cada fotograma lo dejaba tieso
                     en el hombro. Se mira tambien que siga enganchado, por si
                     el estado se quedo puesto. Al soltarlo se vuelve a tumbar. ]]
                local aHombros = LocalPlayer.state.cargadoPor and IsEntityAttachedToAnyPed(currentPed)

                if not aHombros and not IsEntityPlayingAnim(currentPed, anim.dict, anim.clip, 3) then
                    TaskPlayAnim(currentPed, anim.dict, anim.clip, 2.0, 2.0, -1, 1, 0.0, false, false, false)
                end

                local liveRespawnMin = tonumber(GetEMSConfigVal("respawnTime", 0)) or 0
                local liveTotalRespawnSec = math.floor(liveRespawnMin * 60)

                local currentTime = GetGameTimer()
                local elapsedSeconds = math.floor((currentTime - deathTime) / 1000)
                local elapsedDown = elapsedSeconds
                local remainingSeconds = math.max(0, liveTotalRespawnSec - elapsedSeconds)
                local canRespawn = (elapsedSeconds >= liveTotalRespawnSec)

                local callCooldown = 0
                if player.distressCallTime then
                    local waitMinutes = tonumber(GetEMSConfigVal("waitTimeForNewCall", 1)) or 1
                    if waitMinutes <= 0 then waitMinutes = 1 end
                    local waitSeconds = math.floor(waitMinutes * 60)
                    local passedSeconds = math.floor((currentTime - player.distressCallTime) / 1000)
                    if passedSeconds < waitSeconds then
                        callCooldown = waitSeconds - passedSeconds
                    else
                        callCooldown = 0
                    end
                end

                if currentTime - ultimoRecuento >= 10000 then
                    ultimoRecuento = currentTime
                    CreateThread(function()
                        local ok, cuenta = pcall(function()
                            return lib.callback.await("origen_ambulancejob:getMedicsOniline", false)
                        end)
                        if ok and cuenta then sanitarios = cuenta end
                    end)
                end

                if currentTime - ultimoSitio >= 3000 then
                    ultimoSitio = currentTime
                    calleAhora, cruceAhora, zonaAhora, coordsAhora = dondeEstas()
                end

                if currentTime - lastUpdate >= 250 then
                    lastUpdate = currentTime

                    local aviso = {
                        action = "updateDeath",
                        remainingSeconds = remainingSeconds,
                        totalSeconds = math.max(1, liveTotalRespawnSec),
                        canRespawn = canRespawn,
                        callCooldown = callCooldown,
                        downSeconds = elapsedDown,
                        medics = sanitarios,
                        distressSent = player.distressCallTime ~= nil,
                        street = calleAhora,
                        crossing = cruceAhora,
                        zone = zonaAhora,
                        coords = coordsAhora
                    }

                    local parte = parteDeLesiones()
                    local firma = firmaDelParte(parte)
                    if firma ~= ultimaFirma then
                        ultimaFirma = firma
                        aviso.injuries = parte
                        aviso.killedBy = player.causaMuerte
                    end

                    SendNUIMessage(aviso)
                end

                -- Las teclas las escucha la NUI (ver los RegisterNUICallback de
                -- mas arriba): con el raton puesto, el juego ya no las recibe.
            end

            Wait(sleep)
        end
    end)
end

local function isPlayerInMinigame()
    if LocalPlayer.state.inGames or LocalPlayer.state.inMinigame or LocalPlayer.state.inPaintball then
        return true
    end
    if GetResourceState('origen_games') == 'started' then
        local ok, jugando = pcall(function() return exports.origen_games:EstaJugando() end)
        if ok and jugando then return true end
    end
    return false
end

function onPlayerLoaded()
    exports.spawnmanager:setAutoSpawn(false) -- for qbcore

    if isPlayerInMinigame() then return end

    local data = lib.callback.await('origen_ambulancejob:getDeathStatus', false)

    if data?.isDead then
        initPlayerDeath(true)
        -- Con locale(): sin el salia la clave cruda en pantalla ("logged_dead").
        utils.showNotification(locale("logged_dead"))
    end
end

AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end

    local victim, victimDied, weapon = data[1], data[4], data[7]
    utils.debug(weapon)


    if not IsPedAPlayer(victim) then return end

    local playerPed = cache.playerId or PlayerId()

    if NetworkGetPlayerIndexFromPed(victim) ~= playerPed then return end

    -- Si el jugador está dentro de una partida de minijuegos (como paintball), no entra la ambulancia
    if isPlayerInMinigame() then return end

    local victimDiedAndPlayer = victimDied and NetworkGetPlayerIndexFromPed(victim) == playerPed and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim))

    if victimDiedAndPlayer then
        local deathData = {}

        deathData.isDead = true
        deathData.weapon = weapon

        -- Lo que te ha matado, dicho en corto: "Herida de bala", "Contusiones".
        -- El texto largo del arma es el del parte del sanitario y esta escrito
        -- en tercera persona ("La persona presenta..."), que en tu propia
        -- pantalla suena a que hablan de otro.
        local ficha = datosArmas[weapon]
        player.causaMuerte = (ficha and causasConNombre[ficha[2]]) and locale(ficha[2]) or nil

        TriggerServerEvent('origen_ambulancejob:updateDeathStatus', deathData)
        LocalPlayer.state:set("dead", true, true)
        initPlayerDeath()
    end

    updateInjuries(victim, weapon)

    utils.debug(LocalPlayer.state.injuries)
end)

-- Hilo de respaldo para detección de muerte (caídas, ahogamiento, explosiones, etc.)
CreateThread(function()
    while true do
        Wait(500)
        local currentPed = PlayerPedId()
        if not isPlayerInMinigame() and not player.isDead and not player.reanimando and (IsEntityDead(currentPed) or IsPedDeadOrDying(currentPed, true) or IsPedFatallyInjured(currentPed)) then
            local deathData = { isDead = true, weapon = 0 }
            TriggerServerEvent('origen_ambulancejob:updateDeathStatus', deathData)
            LocalPlayer.state:set("dead", true, true)
            initPlayerDeath()
        end
    end
end)

exports("isDead", function()
    return player.isDead
end)

exports("RevivePlayer", function()
    stopPlayerDeath()
end)

exports("revive", function()
    stopPlayerDeath()
end)

exports("stopPlayerDeath", function()
    stopPlayerDeath()
end)


--[[ El radial de origen_hud se abre en el mismo canto derecho: mientras esta
     abierto el panel se aparta (como en vista libre, pero sin tocar el foco ni
     la camara). Asi se puede reportar desde el suelo. ]]
AddEventHandler('origen_hud:radial', function(abierto)
    abierto = abierto == true

    --[[ Apartada, la pagina deja de pintar el panel y el vigilante del foco
         soltaba el raton a los 3 s: al cerrar el radial la pantalla de muerte
         volvia sin raton y con [E]/[G] muertos. Mientras el radial este
         abierto no se le pregunta. ]]
    if OrigenFoco then OrigenFoco.SinPantalla(abierto and player.isDead) end

    if not player.isDead then return end
    SendNUIMessage({ action = "deathApartar", apartado = abierto })

    -- Si aun asi se perdio el foco (soltarraton, otro recurso), se repone al
    -- volver el panel. El repaso de initPlayerDeath enciende KeepInput.
    if not abierto and not vistaLibre and not player.respawning
        and OrigenFoco and not OrigenFoco.Tiene() then
        SetNuiFocus(true, true)
    end
end)

--[[ El raton soltado a la fuerza estando en el suelo: sin foco, el panel se
     quedaria delante sin poder pulsarse. Se pasa a la vista libre, que es lo
     mismo que hace [V] (camara con el raton y el aviso de «[V] vuelve al
     panel»), sin volver a coger el foco aqui. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if player.isDead and not player.respawning and not vistaLibre then
            vistaLibre = true
            SendNUIMessage({ action = "deathCamera", free = true })
        end
    end)
end
