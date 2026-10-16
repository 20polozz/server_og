local GetPlayerServerId            = GetPlayerServerId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local PlayerPedId                  = PlayerPedId
local GetEntityHeading             = GetEntityHeading
local GetEntityForwardVector       = GetEntityForwardVector
local GetGameTimer                 = GetGameTimer
local GetEntityCoords              = GetEntityCoords
local GetStreetNameAtCoord         = GetStreetNameAtCoord
local GetStreetNameFromHashKey     = GetStreetNameFromHashKey
local TriggerServerEvent           = TriggerServerEvent
local CreateThread                 = CreateThread
local CreateObject                 = CreateObject
local AttachEntityToEntity         = AttachEntityToEntity
local SetNewWaypoint               = SetNewWaypoint
local ClearPedTasks                = ClearPedTasks
local DeleteEntity                 = DeleteEntity
local TaskPlayAnim                 = TaskPlayAnim
local PlaySound                    = PlaySound
local SetEntityVisible             = SetEntityVisible
local SetEntityInvincible          = SetEntityInvincible
local TriggerEvent                 = TriggerEvent
local SetCurrentPedWeapon          = SetCurrentPedWeapon

local weapons                      = lib.load("data.weapons")
local useOxInventory               = lib.load("config").useOxInventory
local consumeItemPerUse            = lib.load("config").consumeItemPerUse

local currentExamPatient = nil

--[[ La ficha del paciente y la pantalla de muerte son la misma pagina y el
     mismo foco. Si el sanitario cae con la ficha abierta, soltar el foco al
     cerrarla dejaba la pantalla de muerte sin raton: tirado solo se esconde. ]]
local function soltarFicha()
    if not player.isDead then SetNuiFocus(false, false) end
    SendNUIMessage({ action = "closeDiagnosis" })
end

-- Las causas que tienen nombre en locales (las mismas que el parte del herido).
local causasConNombre = { shot = true, beaten = true, stabbed = true, burn = true }

-- El modelo de la camilla (ver modules/stretcher). Con una a menos de esto se
-- puede subir al paciente desde el diagnostico.
local MODELO_CAMILLA = `prop_ld_binbag_01`
local RADIO_CAMILLA = 5.0

-- Lo que se enseña en "Tu botiquin": los objetos del trabajo.
local OBJETOS_BOTIQUIN = { "defibrillator", "bandage", "icepack", "suturekit", "tweezers", "burncream", "medikit" }

--- Cuantos lleva el sanitario de un objeto. Con origen_inventory se cuenta la
--- cache del cliente (lo mismo que mira Framework.hasItem); si no, se cae a
--- ox_inventory, y si tampoco, a si lo tiene o no.
local function contarObjeto(item)
    if GetResourceState('origen_inventory') == 'started' then
        local ok, inv = pcall(function() return exports['origen_inventory']:GetInventory() end)
        if ok and type(inv) == "table" then
            local total = 0
            for _, v in pairs(inv) do
                if v and (v.name == item or v.item == item) then
                    total = total + (tonumber(v.amount or v.count) or 1)
                end
            end
            return total
        end
    end

    if GetResourceState('ox_inventory') == 'started' then
        local ok, total = pcall(function() return exports.ox_inventory:Search('count', item) end)
        if ok and type(total) == "number" then return total end
    end

    return Framework.hasItem(item) and 1 or 0
end

local function botiquin()
    local kit = {}
    for _, item in ipairs(OBJETOS_BOTIQUIN) do
        local total = contarObjeto(item)
        -- Si el recuento no lo ve pero hasItem si (HasItem de origen_inventory
        -- mira mas sitios que la cache), se da por uno: los botones de la NUI
        -- se deciden con esto y no pueden llevar la contraria a Lua.
        if total <= 0 and Framework.hasItem(item) then total = 1 end
        kit[item] = total
    end
    return kit
end

local function hayCamillaCerca()
    local c = GetEntityCoords(cache.ped or PlayerPedId())
    return GetClosestObjectOfType(c.x, c.y, c.z, RADIO_CAMILLA, MODELO_CAMILLA, false) ~= 0
end

--[[ Lo que el herido cuenta de si mismo, por su state bag (lo pone
     modules/death): desde cuando esta en el suelo y la nota que escribio al
     pedir auxilio. Es texto del jugador, asi que se recorta aqui otra vez. ]]
local NOTA_MAX = 120

local function loQueCuentaElHerido(serverId)
    local st = Player(serverId).state
    local caido = tonumber(st and st.samsCaido)
    local abajo = caido and math.max(0, GetCloudTimeAsInt() - caido) or nil

    local nota = st and st.samsNota
    if type(nota) ~= "string" then nota = nil else nota = nota:sub(1, NOTA_MAX) end

    return abajo, nota
end

local function formatInjuriesList(rawInjuries)
    local injuriesList = {}
    if rawInjuries and type(rawInjuries) == "table" then
        for boneKey, v in pairs(rawInjuries) do
            local requiredItem = "bandage"
            local itemLabel = "Venda"
            if v.cause == "beaten" then
                requiredItem = "icepack"
                itemLabel = "Bolsa de hielo"
            elseif v.cause == "stabbed" then
                requiredItem = "suturekit"
                itemLabel = "Kit de sutura"
            elseif v.cause == "shot" then
                requiredItem = "tweezers"
                itemLabel = "Pinzas quirúrgicas"
            elseif v.cause == "burn" or v.cause == "fire" then
                requiredItem = "burncream"
                itemLabel = "Crema quemaduras"
            end

            table.insert(injuriesList, {
                bone = v.bone or boneKey,
                label = v.label or "Lesión",
                desc = v.desc or "Traumatismo detectado",
                value = tonumber(v.value) or 10,
                cause = v.cause or "Desconocida",
                causeLabel = causasConNombre[v.cause] and locale(v.cause) or nil,
                requiredItem = requiredItem,
                itemLabel = itemLabel
            })
        end
    end
    return injuriesList
end

--[[ La vida del paciente en % (100 = sano del todo). La salud de un ped de
     jugador va sincronizada, asi que se lee aqui mismo. El juego da por muerto
     por debajo de 100 y el tope suele ser 200, de ahi la cuenta. Antes el
     parte solo sabia "vivo / en el suelo": a quien le faltaba media vida y no
     tenia lesiones apuntadas le salia como sano. ]]
local function vidaDe(ped)
    if not ped or not DoesEntityExist(ped) then return nil end
    local vida, max = GetEntityHealth(ped), GetEntityMaxHealth(ped)
    if not max or max <= 100 then max = 200 end
    return math.max(0, math.min(100, math.floor((vida - 100) / (max - 100) * 100 + 0.5)))
end

--- El paciente mas cercano a 3,5 m (nunca uno mismo): ped y id de servidor.
local function pacienteCercano()
    local playerPed = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local mejor, mejorDist = nil, 3.5
    local jugadores = GetActivePlayers()
    for i = 1, #jugadores do
        local otro = GetPlayerPed(jugadores[i])
        if otro ~= playerPed and DoesEntityExist(otro) then
            local d = #(coords - GetEntityCoords(otro))
            if d < mejorDist then mejor, mejorDist = otro, d end
        end
    end
    if not mejor then return nil end
    return mejor, GetPlayerServerId(NetworkGetPlayerIndexFromPed(mejor))
end

function checkPatient(target)
    local targetServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(target))
    local data = lib.callback.await('origen_ambulancejob:getData', false, targetServerId)
    if not data then return utils.showNotification("No se pudo obtener la información del paciente", "error") end

    local isDead = false
    if type(data.status) == "table" then
        isDead = (data.status.isDead == true)
    else
        isDead = (data.status == true)
    end

    local weaponName = "Desconocida"
    if data.killedBy and weapons[data.killedBy] then
        weaponName = weapons[data.killedBy][1] or "Desconocida"
    end

    local injuriesList = formatInjuriesList(data.injuries)

    currentExamPatient = {
        targetId = targetServerId,
        targetPed = target
    }

    local kit = botiquin()
    local abajo, nota = loQueCuentaElHerido(targetServerId)

    -- El await de arriba tarda: si has caido mientras, la pantalla es la de muerte.
    if player.isDead then currentExamPatient = nil return end

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openDiagnosis",
        targetId = targetServerId,
        patientName = data.name or ("Ciudadano #" .. targetServerId),
        isDead = isDead,
        health = isDead and 0 or vidaDe(target),
        killedBy = isDead and weaponName or "",
        injuries = injuriesList,
        hasDefibrillator = (kit.defibrillator or 0) > 0 or Framework.hasItem("defibrillator"),
        hasFirstAid = (kit.bandage or 0) > 0 or (kit.medikit or 0) > 0 or Framework.hasItem("bandage") or Framework.hasItem("medikit"),
        hasStretcher = hayCamillaCerca(),
        downSeconds = isDead and abajo or nil,
        note = isDead and nota or nil,
        kit = kit
    })
end

RegisterNUICallback("closeDiagnosis", function(data, cb)
    -- Tirado en el suelo el foco es de la pantalla de muerte: no se suelta.
    if not player.isDead then SetNuiFocus(false, false) end
    currentExamPatient = nil
    cb("ok")
end)

--- Reanimar a `targetId` con el desfibrilador. Lo usan el parte (NUI) y el
--- /revivep del menu rapido de origen_police. El servidor vuelve a mirarlo todo.
local function reanimarPaciente(targetId)
    if not Framework.hasItem("defibrillator") then
        utils.showNotification(locale("not_enough_defibrillator") or "No tienes un desfibrilador", "error")
        return "no_item"
    end

    if useOxInventory then
        local itemDurability = utils.getItem("defibrillator")?.metadata?.durability
        if itemDurability and itemDurability < consumeItemPerUse then
            utils.showNotification(locale("no_durability") or "Desfibrilador sin carga", "error")
            return "no_durability"
        end
    end

    local playerPed = cache.ped or PlayerPedId()
    TriggerServerEvent("origen_ambulancejob:healPlayer", {
        targetServerId = targetId,
        injury = false,
        heading = GetEntityHeading(playerPed),
        location = GetEntityForwardVector(playerPed),
        coords = GetEntityCoords(playerPed),
    })
    return "ok"
end

--- Primeros auxilios a `targetId` (vendas o botiquin). Si el paciente esta
--- sano y sin lesiones no se gasta nada y se dice.
local function primerosAuxilios(targetId, targetPed)
    if not (Framework.hasItem("bandage") or Framework.hasItem("medikit")) then
        utils.showNotification("No tienes vendas ni botiquín médico", "error")
        return "no_item"
    end

    if Player(targetId).state.dead == true or (targetPed and DoesEntityExist(targetPed) and IsPedDeadOrDying(targetPed, true)) then
        utils.showNotification("El paciente está inconsciente: primero hay que reanimarlo.", "error")
        return "muerto"
    end

    local vida = vidaDe(targetPed)
    local lesiones = Player(targetId).state.injuries
    local conLesiones = type(lesiones) == "table" and next(lesiones) ~= nil
    if vida and vida >= 100 and not conLesiones then
        utils.showNotification("El paciente está sano: no necesita primeros auxilios.", "info")
        return "sano"
    end

    if lib.progressBar({
        duration = 3500,
        label = "Aplicando primeros auxilios...",
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true },
        anim = { scenario = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
    }) then
        TriggerServerEvent("origen_ambulancejob:healPlayer", { targetServerId = targetId, heal = true })
        utils.showNotification(("Primeros auxilios aplicados (tenía %s%% de vida)"):format(vida or "?"), "success")
    end
    return "ok"
end

RegisterNUICallback("revivePatient", function(data, cb)
    if not currentExamPatient or not currentExamPatient.targetId then
        cb("error")
        return
    end

    if not Framework.hasItem("defibrillator") then
        return cb(reanimarPaciente(currentExamPatient.targetId))
    end

    soltarFicha()
    cb(reanimarPaciente(currentExamPatient.targetId))
end)

RegisterNUICallback("healPatient", function(data, cb)
    if not currentExamPatient or not currentExamPatient.targetId then
        cb("error")
        return
    end

    -- Se contesta ya: la barra de progreso tarda 3,5 s y la NUI no espera.
    cb("ok")
    local paciente = currentExamPatient
    soltarFicha()
    primerosAuxilios(paciente.targetId, paciente.targetPed)
end)

--[[ Trasladar: subir al paciente a la camilla que hay al lado. Es lo mismo
     que la [G] de la cercania, con las mismas comprobaciones (el servidor
     vuelve a mirar que el paciente este muerto). ]]
RegisterNUICallback("transportPatient", function(_, cb)
    cb("ok")
    if not currentExamPatient or not currentExamPatient.targetPed then return end

    local ped = currentExamPatient.targetPed
    if not DoesEntityExist(ped) then return end

    if not hayCamillaCerca() then
        return utils.showNotification("Necesitas una camilla al lado del paciente (/camilla).", "error")
    end

    soltarFicha()
    putOnStretcher(true, ped)
    currentExamPatient = nil
end)

--[[ Pedir refuerzo: un aviso al SAMS con tu posicion, por el mismo canal que
     el auxilio de los heridos. Con un minuto de espera: la NUI lo cuenta, pero
     quien manda es esto. ]]
local REFUERZO_MS = 60000
local ultimoRefuerzo = nil

RegisterNUICallback("requestBackup", function(_, cb)
    cb("ok")
    -- `emsJobs` se declara mas abajo en este fichero: aqui aun no existe.
    if not Framework.hasJob(lib.load("config").emsJobs) then return end

    local ahora = GetGameTimer()
    if ultimoRefuerzo and ahora - ultimoRefuerzo < REFUERZO_MS then
        local falta = math.ceil((REFUERZO_MS - (ahora - ultimoRefuerzo)) / 1000)
        return utils.showNotification("Espera " .. falta .. "s para pedir otro refuerzo.", "error")
    end
    ultimoRefuerzo = ahora

    local c = GetEntityCoords(cache.ped or PlayerPedId())
    local calle = GetStreetNameFromHashKey((GetStreetNameAtCoord(c.x, c.y, c.z)))

    TriggerServerEvent("SendAlert:police", {
        coords = c,
        title = "Refuerzo SAMS",
        message = "Un sanitario pide refuerzo con un paciente" .. ((calle and calle ~= "") and (" en " .. calle) or ""),
        job = "ambulance",
        type = "ambulance",
        playerID = GetPlayerServerId(PlayerId())
    })
    utils.showNotification("Refuerzo pedido al SAMS.", "success")
end)

RegisterNUICallback("treatInjury", function(data, cb)
    if not currentExamPatient or not currentExamPatient.targetId then
        cb("error")
        return
    end

    local bone = data.bone
    local cause = data.cause

    if checkInjuryCause(cause) then
        soltarFicha()

        if lib.progressBar({
            duration = 3000,
            label = locale("treating_injury") or "Tratando lesión...",
            useWhileDead = false,
            canCancel = true,
            disable = { car = true, move = true },
            anim = { scenario = "CODE_HUMAN_MEDIC_TEND_TO_DEAD" }
        }) then
            local dataToSend = {}
            dataToSend.targetServerId = currentExamPatient.targetId
            dataToSend.injury = true
            dataToSend.bone = bone
            TriggerServerEvent("origen_ambulancejob:healPlayer", dataToSend)

            -- El plus lo paga el servidor en healPlayer. Aqui se sumaba otra vez
            -- desde el cliente y se cobraba doble.
            utils.showNotification(locale("injury_treated") or "Lesión tratada correctamente", "success")
        else
            utils.showNotification(locale("operation_canceled") or "Operación cancelada", "error")
        end
    end

    cb("ok")
end)

local sendDistressCall = lib.load("config").sendDistressCall

function createDistressCall(customMsg)
    if player.distressCallTime then
        local waitMinutes = tonumber(GetEMSConfigVal and GetEMSConfigVal("waitTimeForNewCall", 1) or 1) or 1
        if waitMinutes <= 0 then waitMinutes = 1 end
        local waitSeconds = math.floor(waitMinutes * 60)
        local passedSeconds = math.floor((GetGameTimer() - player.distressCallTime) / 1000)
        if passedSeconds < waitSeconds then
            local restante = waitSeconds - passedSeconds
            utils.showNotification(("Debes esperar %d segundos para volver a solicitar auxilio."):format(restante), "error")
            return
        end
    end

    local msg = customMsg or "Ciudadano inconsciente requiere asistencia médica urgente"

    sendDistressCall(msg)

    local playerCoords = cache.coords or GetEntityCoords(cache.ped or PlayerPedId())
    local current, crossing = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)

    local data = {}
    data.msg = msg
    data.gps = playerCoords
    data.location = GetStreetNameFromHashKey(current)

    TriggerServerEvent("origen_ambulancejob:createDistressCall", data)
    player.distressCallTime = GetGameTimer()

    utils.showNotification("Aviso de auxilio enviado a los servicios de emergencias (SAMS).", "success")
end

local helpCommandName = lib.load("config").helpCommand

exports("createDistressCall", createDistressCall)
if helpCommandName and helpCommandName ~= "" then
    RegisterCommand(helpCommandName, function(_, args)
        local customMsg = (args and #args > 0) and table.concat(args, " ") or nil
        createDistressCall(customMsg)
    end)
end

local emsJobs = lib.load("config").emsJobs

function openDistressCalls()
    if not Framework.hasJob(emsJobs) then return end

    if lib.load("config").useOrigenPoliceCad then
        TriggerEvent("origen_police:client:OpenPoliceCad")
        return
    end

    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    local distressCalls = lib.callback.await('origen_ambulancejob:getDistressCalls', false)

    local calls = {
        {
            header = "Llamadas de Emergencia",
            isMenuHeader = true,
            icon = "fas fa-truck-medical",
        }
    }

    local dict = lib.requestAnimDict("amb@world_human_tourist_map@male@base")
    local model = lib.requestModel("prop_cs_tablet")

    TaskPlayAnim(playerPed, dict, "base", 2.0, 2.0, -1, 51, 0, false, false, false)

    local tablet = CreateObject(model, playerCoords.x, playerCoords.y, playerCoords.z + 0.2, true, true, true)
    AttachEntityToEntity(tablet, playerPed, GetPedBoneIndex(playerPed, 28422), 0.0, -0.03, 0.0, 20.0, -90.0, 0.0, true, true, false, true, 1, true)

    if not distressCalls or #distressCalls == 0 then
        calls[#calls + 1] = {
            header = "No hay llamadas activas",
            txt = "No se registran avisos de emergencia pendientes",
            icon = "fas fa-check-circle",
            isMenuHeader = true,
        }
    else
        for i = 1, #distressCalls do
            local call = distressCalls[i]

            calls[#calls + 1] = {
                header = call.name or "Aviso 911",
                txt = (call.msg or "") .. " | " .. (call.location or "Ubicación desconocida"),
                icon = "fas fa-bell",
                params = {
                    isAction = true,
                    event = function()
                        local callDetails = {
                            {
                                header = call.name or "Detalles de Llamada",
                                isMenuHeader = true,
                                icon = "fas fa-info-circle",
                            },
                            {
                                header = "Mensaje: " .. (call.msg or ""),
                                txt = "Descripción del incidente",
                                icon = "fas fa-comment-medical",
                                isMenuHeader = true,
                            },
                            {
                                header = "Ubicación: " .. (call.location or ""),
                                txt = "Calle / Zona del aviso",
                                icon = "fas fa-location-dot",
                                isMenuHeader = true,
                            },
                            {
                                header = locale("tablet_call_waypoint_title") or "Establecer GPS",
                                txt = locale("tablet_call_waypoint_desc") or "Marcar ruta en el mapa hacia el aviso",
                                icon = "fas fa-map-location-dot",
                                params = {
                                    isAction = true,
                                    event = function()
                                        SetNewWaypoint(call.gps.x, call.gps.y)
                                        utils.showNotification(locale("tablet_call_waypoint_notification") or "Ruta GPS establecida")
                                        ClearPedTasks(playerPed)
                                        DeleteEntity(tablet)
                                        utils.closeMenu()
                                    end
                                }
                            },
                            {
                                header = locale("tablet_call_resolved_title") or "Finalizar Llamada",
                                txt = locale("tablet_call_resolved_desc") or "Marcar aviso como completado",
                                icon = "fas fa-check",
                                params = {
                                    isAction = true,
                                    event = function()
                                        TriggerServerEvent("origen_ambulancejob:callCompleted", call)
                                        utils.showNotification(locale("tablet_call_resolved_notification") or "Llamada finalizada")
                                        ClearPedTasks(playerPed)
                                        DeleteEntity(tablet)
                                        utils.closeMenu()
                                    end
                                }
                            },
                            {
                                header = "Volver",
                                txt = "Regresar a lista de avisos",
                                icon = "fas fa-arrow-left",
                                params = {
                                    isAction = true,
                                    event = function()
                                        openDistressCalls()
                                    end
                                }
                            }
                        }
                        utils.openMenu(callDetails)
                    end
                }
            }
        end
    end

    calls[#calls + 1] = {
        header = "Cerrar",
        txt = "Guardar tablet",
        icon = "fas fa-xmark",
        params = {
            isAction = true,
            event = function()
                ClearPedTasks(playerPed)
                DeleteEntity(tablet)
                utils.closeMenu()
            end
        }
    }

    utils.openMenu(calls)
end

RegisterNetEvent("origen_ambulancejob:openDistressCalls", openDistressCalls)
exports("openDistressCalls", openDistressCalls)


function checkClosestPatient()
    if not Framework.hasJob(emsJobs) then return end
    local playerPed = cache.ped or PlayerPedId()
    local coords = cache.coords or GetEntityCoords(playerPed)
    local playerId, targetPed, targetCoords = lib.getClosestPlayer(coords, 3.5, false)

    if not targetPed or not DoesEntityExist(targetPed) then
        local players = GetActivePlayers()
        local closestDist = 3.5
        for i = 1, #players do
            local otherPlayer = players[i]
            local otherPed = GetPlayerPed(otherPlayer)
            if otherPed ~= playerPed and DoesEntityExist(otherPed) then
                local dist = #(coords - GetEntityCoords(otherPed))
                if dist < closestDist then
                    closestDist = dist
                    targetPed = otherPed
                end
            end
        end
    end

    if targetPed and DoesEntityExist(targetPed) then
        checkPatient(targetPed)
    else
        utils.showNotification(locale("patient_not_found") or "No hay ningún paciente cerca", "error")
    end
end

exports("checkPatient", checkPatient)
exports("checkClosestPatient", checkClosestPatient)

RegisterNetEvent("origen_ambulancejob:client:checkPatient", checkClosestPatient)
RegisterNetEvent("origen_police:client:checkstatus", checkClosestPatient)
RegisterNetEvent("origen_ambulancejob:checkPatient", checkClosestPatient)

--[[ «CURAR HERIDAS» y «Reanimar» del menu rapido (F7) de origen_police.

     Ese menu lanza el comando `heal` (con qbx) o `healp`, y `revivep`. `heal`
     es el comando de ADMIN de este recurso, que sin id cura a quien lo
     escribe: el sanitario se curaba a si mismo en vez de al paciente que tenia
     delante. `healp` y `revivep` no los registraba nadie. Ahora los tres acaban
     aqui, sobre el paciente mas cercano, con el material y el plus de siempre
     (lo valida el servidor en healPlayer). ]]
local function curarPacienteCercano()
    if not Framework.hasJob(emsJobs) then return end
    local ped, id = pacienteCercano()
    if not ped or not id or id < 1 then
        return utils.showNotification(locale("patient_not_found") or "No hay ningún paciente cerca", "error")
    end
    if IsPedDeadOrDying(ped, true) or Player(id).state.dead == true then
        return utils.showNotification("El paciente está inconsciente: primero hay que reanimarlo.", "error")
    end
    primerosAuxilios(id, ped)
end

local function reanimarPacienteCercano()
    if not Framework.hasJob(emsJobs) then return end
    local ped, id = pacienteCercano()
    if not ped or not id or id < 1 then
        return utils.showNotification(locale("patient_not_found") or "No hay ningún paciente cerca", "error")
    end
    if not (IsPedDeadOrDying(ped, true) or Player(id).state.dead == true) then
        return utils.showNotification("El paciente está consciente: no necesita reanimación.", "info")
    end
    reanimarPaciente(id)
end

RegisterCommand("healp", curarPacienteCercano)
RegisterCommand("revivep", reanimarPacienteCercano)
-- `/heal` sin id escrito por un sanitario: lo manda el servidor (commands).
RegisterNetEvent("origen_ambulancejob:client:curarCercano", function()
    if source == '' then return end
    curarPacienteCercano()
end)

RegisterCommand("checkpatient", checkClosestPatient)
RegisterCommand("revisar", checkClosestPatient)
RegisterCommand("status", checkClosestPatient)

-- Patient Proximity Check Thread for EMS
CreateThread(function()
    local patientPromptShown = false

    while true do
        local sleep = 500
        local playerPed = cache.ped or PlayerPedId()
        -- Este hilo corre para todo el mundo: quien no es sanitario mira cada 1,5 s.
        local esSanitario = Framework.hasJob(emsJobs)

        if not player.isDead and esSanitario and not cache.vehicle then
            local coords = cache.coords or GetEntityCoords(playerPed)
            local playerId, closestPed, targetCoords = lib.getClosestPlayer(coords, 2.5, false)

            if closestPed and DoesEntityExist(closestPed) and closestPed ~= playerPed then
                local isDead = IsPedDeadOrDying(closestPed, true) or IsPedFatallyInjured(closestPed) or (Player(GetPlayerServerId(NetworkGetPlayerIndexFromPed(closestPed))).state.dead == true)

                if isDead then
                    sleep = 0
                    local closestStretcher = GetClosestObjectOfType(coords.x, coords.y, coords.z, 5.0, `prop_ld_binbag_01`, false)

                    if closestStretcher ~= 0 and DoesEntityExist(closestStretcher) then
                        if not patientPromptShown then
                            patientPromptShown = true
                            lib.showTextUI('[E] - ' .. locale('check_patient') .. '  |  [G] - ' .. locale('put_on_stretcher'))
                        end

                        if IsControlJustReleased(0, 38) then -- [E]
                            checkPatient(closestPed)
                        elseif IsControlJustReleased(0, 47) then -- [G]
                            putOnStretcher(true, closestPed)
                            Wait(500)
                        end
                    else
                        if not patientPromptShown then
                            patientPromptShown = true
                            lib.showTextUI('[E] - ' .. locale('check_patient'))
                        end

                        if IsControlJustReleased(0, 38) then -- [E]
                            checkPatient(closestPed)
                        end
                    end
                else
                    if patientPromptShown then
                        patientPromptShown = false
                        lib.hideTextUI()
                    end
                end
            else
                if patientPromptShown then
                    patientPromptShown = false
                    lib.hideTextUI()
                end
            end
        else
            if patientPromptShown then
                patientPromptShown = false
                lib.hideTextUI()
            end
        end

        if not esSanitario then sleep = 1500 end
        Wait(sleep)
    end
end)

local animations = lib.load("config").animations
local reviveReward = lib.load("config").reviveReward
RegisterNetEvent("origen_ambulancejob:playHealAnim", function(data)
    local playerPed = cache.ped or PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    if data.anim == "medic" then
        utils.showNotification(locale("action_revive_notification"))

        CreateThread(function()
            lib.progressBar({
                duration = 14900 + (900 * 15) + 1000,
                label = locale("reviving_patient"),
                useWhileDead = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                },
            })
        end)

        lib.requestAnimDict("mini@cpr@char_a@cpr_def")
        lib.requestAnimDict("mini@cpr@char_a@cpr_str")

        TaskPlayAnim(playerPed, 'mini@cpr@char_a@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)

        Wait(14900)

        for i = 1, 15 do
            Wait(900)
            TaskPlayAnim(playerPed, 'mini@cpr@char_a@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
        end

        Wait(1000)

        ClearPedTasksImmediately(playerPed)

        utils.useItem("defibrillator", consumeItemPerUse)
        -- El plus de la reanimacion lo paga el servidor en healPlayer; aqui se
        -- sumaba otra vez y se cobraba doble.
    elseif data.anim == "dead" then
        utils.showNotification(locale("action_revived_notification"))

        player.gettingRevived = true

        lib.requestAnimDict('mini@cpr@char_b@cpr_str')
        lib.requestAnimDict('mini@cpr@char_b@cpr_def')

        SetEntityVisible(playerPed, false)
        Wait(250)
        SetEntityVisible(playerPed, true)

        SetEntityInvincible(playerPed, false)
        TriggerEvent('playerSpawned', coords.x, coords.y, coords.z)
        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true)

        local x, y, z = table.unpack(data.coords + data.location)

        SetEntityCoords(playerPed, x, y, z - 0.50)
        SetEntityHeading(playerPed, data.heading - 270.0)

        TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_def', 'cpr_intro', 8.0, 8.0, -1, 0, 0, false, false, false)

        Wait(14900)

        TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)

        for i = 1, 15 do
            Wait(900)
            TaskPlayAnim(playerPed, 'mini@cpr@char_b@cpr_str', 'cpr_pumpchest', 8.0, 8.0, -1, 0, 0, false, false, false)
        end

        Wait(800)

        player.gettingRevived = false
        stopPlayerDeath()
    end
end)


RegisterNetEvent("origen_ambulancejob:createDistressCall", function(name)
    if not Framework.hasJob(emsJobs) then return end

    -- Un aviso normal de la casa (origen_notify), sin estilo propio.
    local aviso = {
        title = locale("notification_new_call_title"),
        description = (locale("notification_new_call_desc")):format(name),
        type = 'info',
        duration = 8000,
    }
    if GetResourceState('origen_notify') == 'started' then
        exports['origen_notify']:Notify(aviso)
    else
        lib.notify(aviso)
    end
    PlaySound(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset")
end)
