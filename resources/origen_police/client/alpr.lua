local alpr = false
--- El modo mover/escalar del radar tiene el raton cogido.
local moviendoRadar = false

--[[ Salir del modo mover. Lo llama el `closeMoveRadar` de la interfaz y
     tambien cada vez que el radar se esconde (hidealpr): antes, bajarse del
     coche o apagar el radar a mitad de moverlo quitaba el velo pero dejaba
     el raton cogido sin nada delante. Sin modo mover, no hace nada. ]]
local function DejarDeMoverRadar()
    if not moviendoRadar then return end
    moviendoRadar = false
    DevolverFocoTrasCapa()
end

local blocked = false
local bfplate = ""
local brplate = ""
local finfo = false
local rinfo = false
local invh = false

local cachedJobName = {time = GetGameTimer(), name = nil, duty = nil}

local checkedPlates = {}
local lastFrontPlate = ""
local lastRearPlate = ""
local radarThreshold = 0
local ticketCooldowns = {}

--[[ Las ultimas multas que ha puesto este radar. Se guardan aqui, en el
     cliente, porque el menu rapido las enseña de un vistazo y pedirselas al
     servidor seria una consulta por cada vez que se abre una pestaña. Cinco:
     esto es un vistazo, no un registro —el registro son los informes—. ]]
local ultimasMultas = {}

local function MandarMulta(datos)
    TriggerServerEvent("origen_police:server:radarTicket", datos)

    table.insert(ultimasMultas, 1, {
        plate = datos.targetPlate,
        speed = datos.targetSpeed,
        limit = datos.speedLimit,
        street = datos.street,
        at = GetGameTimer(),
    })

    while #ultimasMultas > 5 do table.remove(ultimasMultas) end
end

local function CheckPlateStatus(plate, currentFinfo, currentRinfo)
    if not plate or plate == "" then return end
    
    if checkedPlates[plate] ~= nil then
        if checkedPlates[plate] then
            blocked = true
            bfplate = currentFinfo and currentFinfo.plate or ""
            if finfo then finfo.wanted = true end
            SendNUIMessage({
                action = "alpr",
                finfo = finfo
            })
            SendNUIMessage({
                action = "balpr",
                block = blocked,
                wanted = true
            })
            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
            PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
        end
        return
    end

    FW_TriggerCallback("origen_police:server:IsPlateWanted", function(isWanted, reason)
        checkedPlates[plate] = isWanted
        if isWanted then
            blocked = true
            bfplate = currentFinfo and currentFinfo.plate or ""
            if finfo then finfo.wanted = true end
            SendNUIMessage({
                action = "alpr",
                finfo = finfo
            })
            SendNUIMessage({
                action = "balpr",
                block = blocked,
                wanted = true
            })
            PlaySoundFrontend(-1, "Beep_Red", "DLC_HEIST_HACKING_SNAKE_SOUNDS", 1)
            PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
            ShowNotification("¡ALERTA COD 9! Vehículo en búsqueda: " .. plate, "error")
        end
    end, plate)
end

local GTA_CLASSES = {
    [0] = "C",  -- Compacts
    [1] = "B",  -- Sedans
    [2] = "B",  -- SUVs
    [3] = "B",  -- Coupes
    [4] = "A",  -- Muscle
    [5] = "A",  -- Sports Classics
    [6] = "S",  -- Sports
    [7] = "S+", -- Super
    [8] = "M",  -- Motorcycles
    [9] = "C",  -- Off-road
    [10] = "D", -- Industrial
    [11] = "D", -- Utility
    [12] = "D", -- Vans
    [13] = "D", -- Cycles
    [14] = "D", -- Boats
    [15] = "H", -- Helicopters
    [16] = "P", -- Planes
    [17] = "D", -- Service
    [18] = "EM",-- Emergency
    [19] = "D", -- Military
    [20] = "D", -- Commercial
    [21] = "D", -- Trains
    [22] = "A", -- Open Wheel
}

local function GetCarClassAndColor(veh)
    local vehClass = "D"
    local vehColor = "#fff"

    if GetResourceState('origen_vehicleclasses') == 'started' then
        local ok, fStats = pcall(function()
            return exports['origen_vehicleclasses']:GetVehicleStats(veh)
        end)
        if ok and fStats and fStats.class then
            vehClass = fStats.class
            vehColor = (fStats.classData and fStats.classData.color) or "#fff"
            return vehClass, vehColor
        end
    end

    local gtaClass = GetVehicleClass(veh)
    vehClass = GTA_CLASSES[gtaClass] or "D"
    return vehClass, vehColor
end

local function checkExtraJob(extraJobs, myJob, myJobCat)
    if not extraJobs or #extraJobs == 0 then return true end
    for _, j in ipairs(extraJobs) do
        local jl = j:lower()
        if jl == myJob or (myJobCat and jl == myJobCat:lower()) then return true end
    end
    return false
end

function IsVehicleValid(category, model, checkType)
    if cachedJobName.name == nil or cachedJobName.time <= GetGameTimer() + 7000 then
        local PlayerData = FW_GetPlayerData(false)
        if PlayerData and PlayerData.job then
            cachedJobName.name = PlayerData.job.name
            cachedJobName.duty = PlayerData.job.onduty
            cachedJobName.time = GetGameTimer()
        end
    end
    if not cachedJobName.name then return nil end

    local job = cachedJobName.name:lower()
    local tabletInfo = CanOpenTablet(job)
    local canOpenTablet = tabletInfo[1]
    local jobCat = tabletInfo[2]

    if canOpenTablet == false or not cachedJobName.duty then return nil end

    local modelHash = GetEntityModel(model)
    local extraData = Config.ExtraVehiclesHashes and Config.ExtraVehiclesHashes[modelHash]

    if category == "any" then
        if not Config.Vehicles then return end
        local valid = false
        for vehType, _ in pairs(Config.Vehicles) do
            if (Config.Vehicles[vehType][job] and Config.Vehicles[vehType][job][modelHash]) or
               (jobCat and Config.Vehicles[vehType][jobCat] and Config.Vehicles[vehType][jobCat][modelHash]) then
                valid = true
                break
            end
        end
        if not valid and extraData then
            if not checkExtraJob(extraData.jobs, job, jobCat) then return false end
            if checkType == "sirens" then
                valid = (extraData.use_sirens ~= false)
            elseif checkType == "radar" then
                valid = (extraData.use_radar ~= false)
            else
                valid = true
            end
        end
        return valid
    end

    if not Config.Vehicles[category] then 
        if extraData then
            if not checkExtraJob(extraData.jobs, job, jobCat) then return false end
            if category == "heli" and not extraData.is_heli then return false end
            if category == "car" and extraData.is_heli then return false end
            
            if checkType == "sirens" then
                return (extraData.use_sirens ~= false)
            elseif checkType == "radar" then
                return (extraData.use_radar ~= false)
            else
                return true
            end
        end
        return false 
    end
    
    local configValid = (Config.Vehicles[category][job] and Config.Vehicles[category][job][modelHash]) or
                        (jobCat and Config.Vehicles[category][jobCat] and Config.Vehicles[category][jobCat][modelHash])
    
    if configValid then return true end

    if extraData then
        if not checkExtraJob(extraData.jobs, job, jobCat) then return false end
        if category == "heli" and not extraData.is_heli then return false end
        if category == "car" and extraData.is_heli then return false end
        
        if checkType == "sirens" then
            return (extraData.use_sirens ~= false)
        elseif checkType == "radar" then
            return (extraData.use_radar ~= false)
        else
            return true
        end
    end

    return false
end

RegisterCommand(Config.Commands.VehicleRadar.cmd, function()
    if IsNuiFocused() then return end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local multiplier = Config.SpeedType == 'kmh' and 3.6 or 2.23694
    if veh ~= 0 then
        if IsVehicleValid("car", veh, "radar") then
            alpr = not alpr
            invh = true
            if alpr then
                CreateThread(function()
                    SendNUIMessage({
                        action = "showalpr",
                        metric = Config.SpeedType
                    })
                    while alpr do
                        Wait(250)
                        veh = GetVehiclePedIsIn(PlayerPedId(), false)
                        if veh ~= 0 then
                            if not invh and IsVehicleValid("car", veh, "radar") then
                                invh = true
                                SendNUIMessage({
                                    action = "showalpr"
                                })
                            end
                            local coordA = GetOffsetFromEntityInWorldCoords(veh, 0.0, 1.0, 1.0)
                            local coordB = GetOffsetFromEntityInWorldCoords(veh, 0.0, 105.0, 0.0)
                            local _, _, _, _, frontcar = GetShapeTestResult(StartShapeTestCapsule(coordA, coordB, 3.0, 10, veh, 7))
                            
                            if IsEntityAVehicle(frontcar) then
                                local entityModel = GetEntityModel(frontcar)
                                local label = Config.CustomCarLabels[entityModel] and Config.CustomCarLabels[entityModel] or GetLabelText(GetDisplayNameFromVehicleModel(entityModel))
                                if label == "NULL" or not label or label == "" then
                                    label = GetDisplayNameFromVehicleModel(entityModel)
                                end
                                local plate = GetVehiclePlate(frontcar)
                                local vehClass, vehColor = GetCarClassAndColor(frontcar)
                                
                                finfo = {
                                    name = label,
                                    plate = plate,
                                    kmh = math.floor(GetEntitySpeed(frontcar)*multiplier),
                                    wanted = checkedPlates[plate] or false,
                                    class = vehClass,
                                    color = vehColor
                                }

                                if finfo.plate ~= lastFrontPlate then
                                    lastFrontPlate = finfo.plate
                                    CheckPlateStatus(finfo.plate, finfo, nil)
                                end
                            else
                                if not blocked then
                                    finfo = false
                                    lastFrontPlate = ""
                                end
                            end

                            if not blocked then
                                SendNUIMessage({
                                    action = "alpr",
                                    finfo = finfo
                                })
                            end

                            -- Speed Limit Detection
                            if radarThreshold > 0 then
                                if IsEntityAVehicle(frontcar) and finfo and finfo.kmh > radarThreshold and GetVehicleClass(frontcar) ~= 18 then
                                    local currentPlate = finfo.plate
                                    if not ticketCooldowns[currentPlate] or GetGameTimer() > ticketCooldowns[currentPlate] then
                                        ticketCooldowns[currentPlate] = GetGameTimer() + Config.Radar.Cooldown
                                        
                                        local playerCoords = GetEntityCoords(PlayerPedId())
                                        local streetHash, crossingHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
                                        local streetName = GetStreetNameFromHashKey(streetHash)
                                        if crossingHash ~= 0 then
                                            streetName = streetName .. " / " .. GetStreetNameFromHashKey(crossingHash)
                                        end
                                        
                                        local policePlate = GetVehicleNumberPlateText(veh)
                                        
                                        MandarMulta({
                                            targetPlate = currentPlate,
                                            targetSpeed = finfo.kmh,
                                            policePlate = policePlate,
                                            street = streetName,
                                            speedLimit = radarThreshold
                                        })
                                    end
                                end

                                if rinfo and rinfo.kmh > radarThreshold then
                                    local currentPlate = rinfo.plate
                                    if not ticketCooldowns[currentPlate] or GetGameTimer() > ticketCooldowns[currentPlate] then
                                        ticketCooldowns[currentPlate] = GetGameTimer() + Config.Radar.Cooldown
           
                                        local playerCoords = GetEntityCoords(PlayerPedId())
                                        local streetHash, crossingHash = GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z)
                                        local streetName = GetStreetNameFromHashKey(streetHash)
                                        if crossingHash ~= 0 then
                                            streetName = streetName .. " / " .. GetStreetNameFromHashKey(crossingHash)
                                        end
                                        
                                        local policePlate = GetVehicleNumberPlateText(veh)
                                        
                                        MandarMulta({
                                            targetPlate = currentPlate,
                                            targetSpeed = rinfo.kmh,
                                            policePlate = policePlate,
                                            street = streetName,
                                            speedLimit = radarThreshold
                                        })
                                    end
                                end
                            end
                            
                            if blocked then
                                local lockedWanted = false
                                if (bfplate ~= "" and checkedPlates[bfplate]) or (brplate ~= "" and checkedPlates[brplate]) then
                                    lockedWanted = true
                                end

                                if finfo and finfo.plate == bfplate then
                                    SendNUIMessage({
                                        action = "alpr",
                                        finfo = finfo
                                    })
                                elseif rinfo and rinfo.plate == brplate then
                                    SendNUIMessage({
                                        action = "alpr",
                                        rinfo = rinfo
                                    })
                                end
                                SendNUIMessage({
                                    action = "balpr",
                                    block = blocked,
                                    wanted = lockedWanted
                                })
                            end
                        else
                            alpr = false
                            invh = false
                            finfo = false
                            blocked = false
                            lastFrontPlate = ""
                            SendNUIMessage({
                                action = "hidealpr"
                            })
                            DejarDeMoverRadar()
                            break
                        end
                    end
                    alpr = false
                    invh = false
                    finfo = false
                    blocked = false
                    lastFrontPlate = ""
                    SendNUIMessage({
                        action = "hidealpr"
                    })
                    DejarDeMoverRadar()
                end)
            end
        end
    end
end)

HandlerManager:AddCallback("vehicle_sit", function(current, previous)
    if not current then
        if alpr or invh then
            alpr = false
            invh = false
            finfo = false
            blocked = false
            lastFrontPlate = ""
            SendNUIMessage({
                action = "hidealpr"
            })
            DejarDeMoverRadar()
        end
    end
end)

RegisterCommand(Config.Commands.LockRadar.cmd, function()
    if IsNuiFocused() then return end
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)

    if veh ~= 0 and alpr then
        blocked = not blocked
        bfplate = finfo and finfo.plate or ""
        brplate = rinfo and rinfo.plate or ""
        local lockedWanted = false
        if finfo and finfo.plate == bfplate then
            lockedWanted = finfo.wanted
        elseif rinfo and rinfo.plate == brplate then
            lockedWanted = rinfo.wanted
        end
        SendNUIMessage({
            action = "balpr",
            block = blocked,
            wanted = lockedWanted
        })
    end
end)

RegisterCommand(Config.Commands.MoveRadar.cmd, function()
    if not alpr then return end
    -- Con otra pantalla delante (la tablet, el panel F7) no se le quita el
    -- raton: al acabar de mover se soltaria y la dejaria sin cursor.
    if IsNuiFocused() then return end
    moviendoRadar = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "movealpr",
        moving = true
    })
end)

RegisterNUICallback("closeMoveRadar", function(data, cb)
    DejarDeMoverRadar()
    if cb then cb("ok") end
end)

-- Raton soltado a la fuerza: fuera el modo mover (el velo de edicion se
-- quedaria tapando la pantalla). Sin modo mover, no hace nada.
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not moviendoRadar then return end
        moviendoRadar = false
        SendNUIMessage({
            action = "movealpr",
            moving = false
        })
    end)
end

RegisterKeyMapping(Config.Commands.VehicleRadar.cmd, Config.Commands.VehicleRadar.description, 'keyboard', Config.Commands.VehicleRadar.key)
RegisterKeyMapping(Config.Commands.LockRadar.cmd, Config.Commands.LockRadar.description, 'keyboard', Config.Commands.LockRadar.key)
RegisterKeyMapping(Config.Commands.MoveRadar.cmd, Config.Commands.MoveRadar.description, 'keyboard', Config.Commands.MoveRadar.key)
RegisterKeyMapping(Config.Commands.RadarLimit.cmd, Config.Commands.RadarLimit.description, 'keyboard', Config.Commands.RadarLimit.key)

RegisterCommand(Config.Commands.RadarLimit.cmd, function(source, args)
    local job = FW_GetPlayerData(false).job.name:lower()
    if not CanOpenTablet(job)[1] then return end
    
    OpenMenu('dialog', GetCurrentResourceName(), 'veh-radar-limit', {
        title = "ESTABLECER LÍMITE DE RADAR",
    }, function(data, menu)
        local newLimit = tonumber(data.value)
        if newLimit then
            radarThreshold = newLimit
            TriggerEvent("origen_police:client:CustomNotify", "RADAR", "Límite de velocidad establecido a " .. newLimit .. " " .. Config.SpeedType, "info")
            menu.close()
        else
            ShowNotification(Config.Translations.MustEnterNumber or "Debes introducir un número")
        end
    end, function(data, menu)
        menu.close()
    end)
end)


--[[ ── El radar, para el menu rapido del riel ────────────────────────────

     La pestaña de interaccion enseña como esta el radar sin tener que subirse
     al coche a mirarlo: si esta puesto, con que limite, que matriculas esta
     leyendo ahora mismo y a quien ha multado.

     Todo esto ya estaba aqui dentro; lo unico que faltaba era una puerta.
     Globales porque las llama custom/client/acceso_inventario.lua, que es
     quien habla con la NUI. ]]

function EstadoDelRadar()
    local ahora = GetGameTimer()

    local multas = {}
    for i = 1, #ultimasMultas do
        local m = ultimasMultas[i]
        multas[i] = {
            plate = m.plate,
            speed = m.speed,
            limit = m.limit,
            street = m.street,
            -- Segundos, que es lo que la pantalla sabe redondear a "hace X".
            ago = math.floor((ahora - m.at) / 1000),
        }
    end

    return {
        on = alpr,
        blocked = blocked,
        limit = radarThreshold,
        -- El de delante y el de detras, tal como los lee el propio radar.
        front = finfo or nil,
        rear = rinfo or nil,
        tickets = multas,
    }
end

--- Devuelve el limite que queda puesto, o false si el numero no valia.
function PonerLimiteRadar(valor)
    local n = tonumber(valor)
    if not n or n < 0 then return false end

    radarThreshold = math.floor(n)
    return radarThreshold
end
