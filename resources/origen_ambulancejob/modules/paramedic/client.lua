local GetEntityCoords         = GetEntityCoords
local GetEntityMaxHealth      = GetEntityMaxHealth
local SetEntityCoords         = SetEntityCoords
local SetEntityHeading        = SetEntityHeading
local SetEntityHealth         = SetEntityHealth
local TaskPlayAnim            = TaskPlayAnim
local Wait                    = Wait

--[[ El tratamiento del medico del hospital, ya cobrado.

     Si llegas inconsciente (te han traido en brazos o en camilla), primero te
     levanta: antes, con `shouldRevive = false` (lo que hay en config), solo te
     subia la vida y seguias muerto en el suelo, y ademas la barra de progreso
     con `useWhileDead = false` se cortaba al instante. ]]
local tratando = false
--- Mientras se pregunta y se cobra, para que dos pulsaciones no pidan dos veces.
local pidiendoMedico = false
--- Declarada aqui porque el punto (initParamedic) la usa y se crea antes.
local AtenderInconsciente

local function tratarEnHospital(ped, hospital)
    if tratando then return end
    tratando = true

    local shouldRevive = GetEMSConfigVal("shouldRevive", false)
    local estabaInconsciente = player.isDead == true

    local dict = lib.requestAnimDict("anim@gangops@morgue@table@")
    local playerPed = cache.ped or PlayerPedId()
    local previousCoords = GetEntityCoords(playerPed)
    local bed = nil

    if estabaInconsciente then
        stopPlayerDeath()
        playerPed = PlayerPedId()
    end

    utils.doScreenFadeOut(500, true)
    Wait(1000)
    utils.doScreenFadeIn(300)

    for i = 1, #hospital.respawn do
        local _bed = hospital.respawn[i]
        local isBedOccupied = utils.isBedOccupied(_bed.bedPoint)
        if not isBedOccupied then
            bed = _bed
            break
        end
    end

    if not bed then bed = hospital.respawn[1] end

    SetEntityCoords(playerPed, bed.bedPoint)
    SetEntityHeading(playerPed, bed.bedPoint.w)
    TaskPlayAnim(playerPed, dict, "body_search", 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(playerPed, true)

    SetEntityCoords(ped, bed.spawnPoint)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CLIPBOARD", -1, true)

    lib.progressBar({ duration = 15000, label = locale("getting_treated") or "Recibiendo tratamiento...", useWhileDead = true, canCancel = true, disable = { car = true, move = true }, })

    FreezeEntityPosition(playerPed, false)
    SetEntityCoords(ped, hospital.paramedic.pos.xyz)
    SetEntityHeading(ped, hospital.paramedic.pos.w)
    if shouldRevive and not estabaInconsciente then
        stopPlayerDeath()
    else
        utils.doScreenFadeOut(500, true)
        Wait(1000)
        utils.doScreenFadeIn(300)
        SetEntityHealth(playerPed, GetEntityMaxHealth(playerPed))
        player.injuries = {}
        LocalPlayer.state:set("injuries", {}, true)
    end

    -- Quien llego inconsciente se queda en el hospital, junto a la camilla.
    if estabaInconsciente and bed.spawnPoint then
        SetEntityCoords(playerPed, bed.spawnPoint.x, bed.spawnPoint.y, bed.spawnPoint.z)
        if bed.spawnPoint.w then SetEntityHeading(playerPed, bed.spawnPoint.w) end
    else
        SetEntityCoords(playerPed, previousCoords)
    end
    ClearPedTasks(playerPed)
    utils.showNotification(locale("treated_by_paramedic") or "Has sido tratado con éxito", "success")
    ClearPedTasks(ped)
    ClearAreaOfObjects(hospital.paramedic.pos.xyz, 2.0, 0)
    tratando = false
end

--- ¿Puede atender el NPC ahora? (con allowAlways = false, solo sin sanitarios)
local function npcPuedeAtender()
    if GetEMSConfigVal("allowAlways", true) then return true end
    local medicsOnline = lib.callback.await('origen_ambulancejob:getMedicsOniline', false)
    if (tonumber(medicsOnline) or 0) <= 0 then return true end
    utils.showNotification(locale("medics_online"))
    return false
end

local function openParamedicMenu(ped, hospital)
    local paramedicTreatmentPrice = tonumber(GetEMSConfigVal("paramedicTreatmentPrice", 4000)) or 4000

    local menu = {
        {
            header = locale("paramedic_menu_title") or "Atención Médica SAMS",
            isMenuHeader = true,
            icon = "fas fa-user-doctor",
        },
        {
            header = locale("get_treated_paramedic") or "Recibir Tratamiento",
            txt = "Precio de la consulta médica: $" .. (paramedicTreatmentPrice or 0),
            icon = "fas fa-hand-holding-dollar",
            params = {
                isAction = true,
                event = function()
                    -- Cobra el servidor, con su precio y del banco (preguntando con qué
                    -- cuenta si hay varias). Sin cobro no hay tratamiento; el aviso de
                    -- falta de dinero ya lo manda el servidor.
                    if not lib.callback.await('origen_ambulancejob:server:pagarParamedico', false) then return end
                    tratarEnHospital(ped, hospital)
                end,
            }
        },
        {
            header = "Cerrar",
            txt = "Cerrar menú",
            icon = "fas fa-xmark",
            params = {
                isAction = true,
                event = function()
                    utils.closeMenu()
                end
            }
        }
    }

    utils.openMenu(menu)
end

local function createAmbulance()
    local vehicleModel = "ambulance"
    lib.requestModel(vehicleModel)

    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)

    local _, vector = GetNthClosestVehicleNode(playerCoords.x, playerCoords.y, playerCoords.z, math.random(50, 70), 0, 0, 0)
    local sX, sY, sZ = table.unpack(vector)

    ambulance = CreateVehicle(vehicleModel, sX, sY, sZ, 0, false, true)


    SetEntityAsMissionEntity(ambulance, true, true)
    SetVehicleEngineOn(ambulance, true, true, false)

    SetModelAsNoLongerNeeded(ambulance)

    SetVehicleSiren(ambulance, true)

    return ambulance
end

local function createAmbulanceDriver(vehicle)
    local pedModel = "s_m_m_paramedic_01"
    lib.requestModel(pedModel)

    local ped = CreatePedInsideVehicle(vehicle, 26, pedModel, -1, false, true)
    SetAmbientVoiceName(ped, "A_M_M_EASTSA_02_LATINO_FULL_01")
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityAsMissionEntity(ped, true, true)

    SetModelAsNoLongerNeeded(pedModel)
    return ped
end

local hospitals = lib.load("data.hospitals")

local paramedicPoints = {}

function initParamedic()
    for index, hospital in pairs(hospitals) do
        local ped = utils.createPed(hospital.paramedic.model, hospital.paramedic.pos)

        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        local point = lib.points.new({
            coords = hospital.paramedic.pos.xyz,
            distance = 2.5,
            onEnter = function(self)
                self.etiqueta = nil
            end,
            onExit = function(self)
                if self.etiqueta then lib.hideTextUI() end
                self.etiqueta = nil
            end,
            nearby = function(self)
                --[[ Inconsciente, [E] es de la pantalla de muerte (pedir
                     auxilio) y el juego la tiene apagada: se atiende con [H],
                     que escucha esa misma pantalla (deathParamedico, abajo). ]]
                local etiqueta = nil
                if player.isDead then
                    etiqueta = '[H] - ' .. (locale('paramedic_interact_label') or 'Atención médica') .. ' (inconsciente)'
                elseif not cache.vehicle then
                    etiqueta = '[E] - ' .. locale('paramedic_interact_label')
                end
                if etiqueta ~= self.etiqueta then
                    if etiqueta then lib.showTextUI(etiqueta) else lib.hideTextUI() end
                    if etiqueta and player.isDead then
                        utils.showNotification("Estás junto al médico del hospital: pulsa [H] para que te atienda.", "info")
                    end
                    self.etiqueta = etiqueta
                end

                --[[ [H] en Lua. El control 74 es la H, y estando
                     inconsciente no hace nada mas. Es el camino que no depende
                     de que la pantalla de muerte tenga el teclado. ]]
                if player.isDead and IsControlJustReleased(0, 74) then
                    AtenderInconsciente(false)
                    return
                end

                if not cache.vehicle and not player.isDead then
                    if self.currentDistance < 2.0 and IsControlJustReleased(0, 38) then
                        local allowAlwaysTreatment = GetEMSConfigVal("allowAlways", true)
                        if not allowAlwaysTreatment then
                            local medicsOnline = lib.callback.await('origen_ambulancejob:getMedicsOniline', false)
                            if medicsOnline <= 0 then
                                openParamedicMenu(ped, hospital)
                            else
                                utils.showNotification(locale("medics_online"))
                            end
                        else
                            openParamedicMenu(ped, hospital)
                        end
                    end
                end
            end
        })

        point.pedMedico = ped
        point.hospital = hospital
        table.insert(paramedicPoints, point)
    end
end

--[[ [H] en la pantalla de muerte, junto al medico del hospital. Llega de la
     NUI porque mientras estas en el suelo el teclado lo tiene ella. Sin menu
     (su foco chocaria con el de la pantalla de muerte): cobra y atiende. ]]
local ultimoAvisoH = 0
--[[ Que el médico del hospital te atienda estando inconsciente.

     Lo llaman dos sitios y a propósito:

       - La pantalla de muerte, cuando pulsas [H] con el teclado dentro de la
         NUI.
       - El propio punto, en Lua, mirando el control de [H].

     Hacía falta el segundo. Inconsciente, el teclado no siempre está en la
     pantalla de muerte —según cómo se haya abierto y qué tenga el foco—, así
     que el `keydown` de la NUI no llegaba nunca: el cartel decía "pulsa [H]" y
     al pulsar no pasaba nada. Eso es el "el npc del hospi no me cura estando
     en pk". El control de Lua no depende del foco de ninguna pantalla.

     Llamarlo dos veces no cobra dos veces: `tratando` lo corta mientras hay un
     tratamiento en marcha.  ]]
function AtenderInconsciente(avisarSiLejos)
    if not player.isDead or player.respawning or tratando or pidiendoMedico then return end

    local c = GetEntityCoords(cache.ped or PlayerPedId())
    local cerca = nil
    for _, point in pairs(paramedicPoints) do
        if point.hospital and #(c - point.hospital.paramedic.pos.xyz) < 3.0 then
            cerca = point
            break
        end
    end

    if not cerca then
        -- [H] suelta en cualquier otro sitio: se dice, pero sin repetirlo.
        if avisarSiLejos and GetGameTimer() - ultimoAvisoH > 5000 then
            ultimoAvisoH = GetGameTimer()
            utils.showNotification("No hay ningún médico del hospital a tu lado.", "error")
        end
        return
    end

    --[[ Cerrojo propio, no `tratando`: ese lo pone `tratarEnHospital` y si se
         deja puesto antes, la llamada de abajo se da media vuelta sola. Este
         solo cubre el rato de preguntar y cobrar. ]]
    pidiendoMedico = true

    CreateThread(function()
        if not npcPuedeAtender() then
            pidiendoMedico = false
            return
        end

        local precio = tonumber(GetEMSConfigVal("paramedicTreatmentPrice", 4000)) or 4000
        utils.showNotification(("El médico te atiende (consulta: $%d)."):format(precio), "info")

        if not lib.callback.await('origen_ambulancejob:server:pagarParamedico', false) then
            pidiendoMedico = false
            return
        end

        tratarEnHospital(cerca.pedMedico, cerca.hospital)
        pidiendoMedico = false
    end)
end

RegisterNUICallback("deathParamedico", function(_, cb)
    cb({})
    AtenderInconsciente(true)
end)

function unloadParamedic()
    for _, point in pairs(paramedicPoints) do
        point:remove()
    end
    paramedicPoints = {}
end

local function offlineRevive()
    if not player.isDead then return end
    local medicsOnline = lib.callback.await('origen_ambulancejob:getMedicsOniline', false)
    if medicsOnline > 0 then return utils.showNotification(locale("medics_online")) end
    if player.timePassedForCommand and player.timePassedForCommand > 0 then return utils.showNotification(locale("wait_time"):format(player.timePassedForCommand)) end

    utils.showNotification(locale("medic_coming"))

    local tpToPed = false
    local dict = lib.requestAnimDict("mini@cpr@char_a@cpr_str")
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = cache.coords or GetEntityCoords(playerPed)
    local startTime = GetGameTimer()

    local ambulance = createAmbulance()
    local ambulanceDriver = createAmbulanceDriver(ambulance)
    while not DoesEntityExist(ambulanceDriver) do Wait(1) end

    TaskVehicleDriveToCoord(ambulanceDriver, ambulance, playerCoords.x, playerCoords.y, playerCoords.z, 40.0, 0, GetEntityModel(ambulance), 2146958335, 10.0)
    SetPedKeepTask(ambulanceDriver, true)

    while true do
        local driverCoords = GetEntityCoords(ambulanceDriver)
        playerCoords = GetEntityCoords(playerPed)
        local dist = #(driverCoords - playerCoords)


        utils.debug(GetGameTimer() - startTime)
        if (GetGameTimer() - startTime) > 35000 then
            break
        end

        utils.debug(dist)

        if dist < 30 then
            break
        end
        Wait(1)
    end

    TaskLeaveVehicle(ambulanceDriver, ambulance, 64)
    TaskGoToCoordAnyMeans(ambulanceDriver, playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 0, 786603)

    startTime = GetGameTimer()

    while true do
        local driverCoords = GetEntityCoords(ambulanceDriver)
        playerCoords = GetEntityCoords(playerPed)
        local dist = #(driverCoords - playerCoords)

        utils.debug(dist)
        utils.debug(GetGameTimer() - startTime)

        if (GetGameTimer() - startTime) > 5000 then
            tpToPed = true
            break
        end

        if dist < 2 then
            break
        end
        Wait(1)
    end
    if tpToPed then
        SetEntityCoords(ambulanceDriver, cache.coords)
        TaskGoToCoordAnyMeans(ambulanceDriver, playerCoords.x, playerCoords.y, playerCoords.z, 10.0, 0, 0, 786603)
        Wait(1000)
    end

    Wait(1000)

    TaskPlayAnim(ambulanceDriver, dict, "cpr_pumpchest", 1.0, 1.0, -1, 9, 1.0, false, false, false)

    Wait(1000 * 15)

    stopPlayerDeath()
    DeleteEntity(ambulance)
    DeleteEntity(ambulanceDriver)
end

function startCommandTimer()
    CreateThread(function()
        local deathTime = GetGameTimer()

        while player.isDead do
            local waitMinutes = tonumber(GetEMSConfigVal("timeToWaitForCommand", 2)) or 2
            local timeToWaitForCommand = waitMinutes * 60000
            local currentTime = GetGameTimer()
            local timePassed = currentTime - deathTime
            player.timePassedForCommand = math.max(0, math.ceil((timeToWaitForCommand - timePassed) / 1000))
            utils.debug(player.timePassedForCommand)

            Wait(1000)
        end
    end)
end

local npcReviveCommand = lib.load("config").npcReviveCommand
RegisterCommand(npcReviveCommand, offlineRevive)
