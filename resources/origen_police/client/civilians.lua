local CurrentWeaponData = {}
local prevhlth = false
local vhhlth = false
local shootingdata = {}
local lastGSRRegister = 0

CreateThread(function()
    --[[ Las comisarias y demas sitios fijos, en el mapa.

         Ya no son blips del juego: se registran en origen_map y de ahi los
         leen los tres mapas del servidor. El nombre que se escribia en el
         rotulo del blip —y que los mapas de Leaflet no podian leer— ahora
         llega tal cual. ]]
    if Public.Blips then
        local puntos = {}

        for i, v in pairs(Public.Blips) do
            puntos[#puntos + 1] = {
                id = tostring(i),
                x = v.coords.x, y = v.coords.y, z = v.coords.z,
                cat = 'emergencias',
                --- Son sitios de policia: lo que no sepa traducir, con el escudo y no
                --- con la cruz de la categoria.
                icono = OrigenMapa.Icono(v.sprite) or 'escudo',
                nombre = v.name,
            }
        end

        OrigenMapa.PonerVarios('sitio', puntos)
    end
    CreateThread(function()
        if Public.TrafficZones then
            Wait(5000)
            for i = 1, #Public.TrafficZones do
                --[[ La zona de trafico: un circulo, y solo para quien esta
                     de servicio. Antes eran dos cosas —un blip de radio para
                     verla y una zona de velocidad para que hiciera algo—; la
                     de velocidad sigue igual, y la de verla es ahora un punto
                     de origen_map con `radio`.

                     El color dice de que tipo es: rojo para el alto, amarillo
                     para el limite. ]]
                local clave = 'trafico_' .. tostring(i)

                if onduty then
                    Public.TrafficZones[i].blip = clave
                end

                if Public.TrafficZones[i].type == "stop" then
                    Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 0.0, false)
                elseif Public.TrafficZones[i].type == "slow" then
                    Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 5.0, false)
                end

                if onduty then
                    OrigenMapa.Poner(clave, {
                        x = Public.TrafficZones[i].coords.x,
                        y = Public.TrafficZones[i].coords.y,
                        z = Public.TrafficZones[i].coords.z,
                        cat = 'emergencias',
                        nombre = Public.TrafficZones[i].type == "stop"
                            and 'Control de trafico' or 'Limitacion de velocidad',
                        radio = 50.0,
                        color = Public.TrafficZones[i].type == "stop"
                            and '#ff3355' or '#f0c33c',
                    })
                end
            end
        end
    end)
    while true do
        local w = 2000
    
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        if Public.Markers then
            for i = 1, #Public.Markers do
                local p = Public.Markers[i]
                local d = #(coords - p.coords.xyz)
                if d < 30 then
                    w = 0
                    if Config.MarkersDraw then
                        DrawMarker(p.sprite, p.coords.x, p.coords.y, p.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, p.rgba.r, p.rgba.g, p.rgba.b, p.rgba.a, false, false, 0, true)
                    end
                    if d < (p.radius or 1) then
                        if Config.CustomNotify then
                            ShowHelpNotification("E", p.text)
                            p.noty = true
                        else
                            if Config.Framework == "qbcore" then
                                if not p.noty then
                                    exports['qb-core']:DrawText("[E] " .. p.text, 'left')
                                    p.noty = true
                                end
                            elseif Config.Framework == "esx" then
                                Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. p.text, true)
                            end
                        end
                        if IsControlJustPressed(0, 38) then
                            TriggerEvent(p.event, i, p.station)
                        end
                    elseif p.noty then
                        HideHelpNotification()
                        p.noty = nil
                    end
                elseif p.noty then
                    HideHelpNotification()
                    p.noty = nil
                end
            end
        end
        Wait(w)
    end
end)

local function InRestrictedZone()
    local playerCoords = GetEntityCoords(PlayerPedId())
    for n = 1, #Config.RestrictedAlertZones do
        if isInside(Config.RestrictedAlertZones[n], playerCoords.x, playerCoords.y) then
            return true
        end
    end

    -- Zonas de Caza (origen_hunting) - Comprobación 2D (solo X,Y, sin altura)
    local huntingZones = {
        {coords = vector2(-662.5,   5256.67), radius = 350.0},  -- Paleto Forest
        {coords = vector2(-1189.74, 3857.12), radius = 600.0},  -- Josiah
        {coords = vector2(-695.3,   5809.53), radius = 200.0},  -- TEST
    }
    local playerCoords2D = vector2(playerCoords.x, playerCoords.y)
    for i = 1, #huntingZones do
        if #(playerCoords2D - huntingZones[i].coords) <= huntingZones[i].radius then
            return true
        end
    end

    -- Blackmarket active capture window:
    -- avoid dispatch gunshot alerts while fighting for market control.
    local okCapture, inCapture = pcall(function()
        if GetResourceState('origen_blackmarket') ~= 'started' then
            return false
        end
        local isInCapture = exports['origen_blackmarket']:IsInActiveCaptureZone()
        return isInCapture == true
    end)
    if okCapture and inCapture then
        return true
    end

    -- Dentro de una partida de Origen Games no hay avisos de disparos ni
    -- pruebas (el paintball, el cazador del escondite que dispara a props).
    if LocalPlayer.state.enJuego then
        return true
    end

    return false
end

CreateThread(function()
    while true do
        local w = 500

        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        
        -- All systems that are using this thread are disabled, so exit the loop
        if not Config.EvidenceSystem and not Config.ShootAlert then
            break
        end

        if InRestrictedZone() then
            goto continue
        end

        if (IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(ped, 78)) then
            w = 0
            if IsPedShooting(ped) then
                local hit, coords, entity = GetScreenCoords()
                
                -- GSR Test registration with 10 seconds client-side cooldown
                local now = GetGameTimer()
                if now - lastGSRRegister > 10000 then
                    lastGSRRegister = now
                    TriggerServerEvent("origen_police:server:registerShot")
                end

                if hit then
                    CurrentWeaponData = GetItemFromWeapon(FW_GetPlayerData(false), GetSelectedPedWeapon(ped))
                    if not CurrentWeaponData then
                        Debuger("Can't find weapon data in the inventory, weapon: ", GetSelectedPedWeapon(ped))
                    else
                        if Config.EvidenceSystem and CurrentWeaponData and CurrentWeaponData.slot then
                            table.insert(shootingdata, { type = "Shoot", coords = pCoords, wp = CurrentWeaponData.slot })
                            if DoesEntityExist(entity) and not IsEntityPositionFrozen(entity) then
                                if entity and IsEntityAPed(entity) and not IsPedAPlayer(entity) then
                                    table.insert(shootingdata, { type = "NpcBlood", coords = coords, adn = IsPedHuman(entity) and "Generate" or "Animal" })
                                end
                            else
                                table.insert(shootingdata, { type = "Impact", coords = coords, wp = CurrentWeaponData.slot })
                            end
                        end
                        if Config.ShootAlert then
                            SendShootAlert(CurrentWeaponData)
                        end
                    end
                end
            end
        elseif #shootingdata > 0 then
            if Config.EvidenceSystem then
                local added = {}
                for i = 1, #shootingdata do
                    local fnd = false
                    for j = 1, #added do
                        if #(added[j].coords - shootingdata[i].coords) < 1.1 and added[j].type == shootingdata[i].type and ((shootingdata[i].npc and added[j].npc and shootingdata[i].npc == added[j].npc) or true) then
                            added[j].count = (added[j].count or 1) + 1
                            fnd = true
                        end
                    end
                    if not fnd then
                        table.insert(added, shootingdata[i])
                    end
                end
                TriggerServerEvent("origen_police:server:AddNewEvidence", added)
                shootingdata = {}
            end
        end
        if Config.EvidenceSystem then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                if vhhlth and vhhlth - GetVehicleBodyHealth(veh) > 5 then
                    TriggerServerEvent("origen_police:server:AddNewEvidence", {
                        type = "VehCrash",
                        model = Config.CustomCarLabels[GetEntityModel(veh)] and Config.CustomCarLabels[GetEntityModel(veh)] or GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
                        color = {GetVehicleColor(veh)},
                        coords = GetEntityCoords(veh)
                    })
                end
                vhhlth = GetVehicleBodyHealth(veh)
            elseif veh == 0 then
                if prevhlth and prevhlth - GetEntityHealth(ped) > 6 then
                    TriggerServerEvent("origen_police:server:AddNewEvidence", {
                        type = "BloodRest",
                        adn = true,
                        bloodType = GetSelfBloodType(),
                        coords = GetEntityCoords(ped)
                    })
                end
                prevhlth = GetEntityHealth(ped)
                vhhlth = false
            end
        end

        ::continue::

        Wait(w)
    end
end)

CreateThread(function()
    local inradar = false
    while not Public.Radars or #Public.Radars == 0 do
        Wait(5000)
    end
    while true do
        local w = 1500
        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
        
        if #Public.Radars > 0 and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
            local vcoords = GetEntityCoords(veh)
            w = 150
            if not inradar then
                for i = 1, #Public.Radars do
                    if #(vcoords - Public.Radars[i].coords) < 22 then
                        inradar = Public.Radars[i].coords
                        if Public.Radars[i].type == 1 then
                            local multiplier = (Config.SpeedType and Config.SpeedType:lower() == 'kmh') and 3.6 or 2.23694
                            local speed = GetEntitySpeed(veh) * multiplier
                            if speed > Public.Radars[i].value and GetVehicleClass(veh) ~= 18 then
                                speed = FW_Round(speed)
                                TriggerServerEvent("SendAlert:police", {
                                    coords = Public.Radars[i].coords,
                                    title = Config.Translations.Speeding,
                                    type = "RADARES",
                                    metadata = {
                                        model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
                                        color = {GetVehicleColor(veh)},
                                        plate = GetVehiclePlate(veh),
                                        speed = speed .. " kmh / ^" .. speed - Public.Radars[i].value .. " kmh"
                                    },
                                    job = {"police", "fib"},
                                    ignoreCooldown = true
                                })
                                SendNUIMessage({
                                    action = "RadarFlash"
                                })
                                -- Add Automatic Ticket for Prop Radars
                                TriggerServerEvent("origen_police:server:radarTicket", {
                                    targetPlate = GetVehiclePlate(veh),
                                    targetSpeed = speed,
                                    policePlate = "RADAR FIJO",
                                    street = GetStreetName(Public.Radars[i].coords),
                                    speedLimit = Public.Radars[i].value,
                                    placerId = Public.Radars[i].source
                                })
                            end
                        elseif Public.Radars[i].type == 2 then
                            if GetVehiclePlate(veh):find(Public.Radars[i].value) then
                                TriggerServerEvent("SendAlert:police", {
                                    coords = Public.Radars[i].coords,
                                    title = Config.Translations.PlateCod9,
                                    type = "RADARES",
                                    metadata = {
                                        model = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(veh))),
                                        color = {GetVehicleColor(veh)},
                                        plate = GetVehiclePlate(veh),
                                    },
                                    job = {"police", "fib"},
                                    ignoreCooldown = true
                                })
                                SendNUIMessage({
                                    action = "RadarFlash"
                                })
                                -- Add Automatic Ticket for Prop Radars (Plate detection)
                                TriggerServerEvent("origen_police:server:radarTicket", {
                                    targetPlate = GetVehiclePlate(veh),
                                    targetSpeed = FW_Round(GetEntitySpeed(veh) * ((Config.SpeedType and Config.SpeedType:lower() == 'kmh') and 3.6 or 2.23694)),
                                    policePlate = "DETECCIÓN MATRÍCULA",
                                    street = GetStreetName(Public.Radars[i].coords),
                                    speedLimit = "ALERTA PLACA",
                                    placerId = Public.Radars[i].source
                                })
                            end
                        end
                    end
                end
            else
                if #(vcoords - inradar) > 22 then
                    inradar = false
                end
            end
        end

        Wait(w)
    end
end)

CreateThread(function()
    local Wheels = {
        {
            name = "wheel_lf",
            index = 0
        },
        {
            name = "wheel_lr",
            index = 4
        },
        {
            name = "wheel_rf",
            index = 1
        },
        {
            name = "wheel_lm1",
            index = 2
        },
        {
            name = "wheel_rm1",
            index = 3
        },
        {
            name = "wheel_rr",
            index = 5
        },
        {
            name = "wheel_lm2",
            index = 45
        },
        {
            name = "wheel_rm2",
            index = 47
        },
    }
    while true do
        local w = 1500

        if IsPedInAnyVehicle(PlayerPedId()) then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)

            if GetPedInVehicleSeat(veh, -1) == PlayerPedId() then
                w = 500
                local stg = GetClosestObjectOfType(GetEntityCoords(veh), 50.0, GetHashKey("p_ld_stinger_s"), false, false, false)
                if stg ~= 0 then
                    w = 10
                    local stg_coords = GetEntityCoords(stg)

                    if GetEntitySpeed(veh) > 15 then
                        if #(stg_coords - GetEntityCoords(veh)) < 5 then
                            for i = 1, GetVehicleNumberOfWheels(veh) do
                                if not IsVehicleTyreBurst(veh, Wheels[i].index, false) then
                                    SetVehicleTyreBurst(veh, Wheels[i].index, true, 0)
                                end
                            end
                        end
                    else
                        for i = 1, GetVehicleNumberOfWheels(veh) do
                            if #(stg_coords - GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, Wheels[i].name))) < 1 then
                                if not IsVehicleTyreBurst(veh, Wheels[i].index, false) then
                                    SetVehicleTyreBurst(veh, Wheels[i].index, true, 0)
                                end
                            end
                        end
                    end
                end
            end
        end

        Wait(w)
    end
end)

-- La linterna de las evidencias vive ahora en client/evidencias.lua.

-- (Aqui iba DrawText3D, texto nativo en 3D al que ya nadie llamaba.)

local lastshootalert = false
function SendShootAlert(weaponData)
    if Config.WeaponSilencierBlockShootAlert and IsPedCurrentWeaponSilenced(PlayerPedId()) then
        Debuger("Weapon has a silencier, not sending shoot alert")
        return
    end
    if IsWeaponBlacklisted(weaponData.name) then
        Debuger("Weapon is blacklisted, not sending shoot alert")
        return
    end
    if Config.ShootAlertRequireSeen and not IsBeingSeen() then
        Debuger("Player is not being seen by any player or ambient peds, not sending shoot alert, you can disable this in Config.ShootAlertRequireSeen")
        return
    end
    if Config.ShootAlertDisablePolice and CanOpenTablet(FW_GetPlayerData(false).job.name)[1] then
        Debuger("Player has a job listed in config/jobs.lua, not sending shoot alert, you can disable this in Config.ShootAlertDisablePolice")
        return
    end
    if lastshootalert and (GetGameTimer() - lastshootalert < Config.ShootAlertCooldown) then
        Debuger("Shoot alert cooldown("..((Config.ShootAlertCooldown - (GetGameTimer() - lastshootalert)) / 1000).." sec), not sending shoot alert")
        return
    end
    lastshootalert = GetGameTimer()
    local ammotype = GetPedAmmoTypeFromWeapon(PlayerPedId(), GetHashKey(weaponData.name))
    if ammotype and IsAmmoBlacklisted(ammotype) then
        Debuger("Ammo type is blacklisted("..ammotype.."), not sending shoot alert")
        return
    end

    math.randomseed(GetGameTimer())
    local weaponChance = math.random(0, 100) <= Config.ShootAlertWeaponChance
    local ammoChance = math.random(0, 100) <= Config.ShootAlertAmmoChance

    Debuger("Shoot alert data: ", json.encode({
        weaponChance = weaponChance,
        ammoChance = ammoChance,
        lastshootalert = lastshootalert,
        weaponData = weaponData,
        ammotype = ammotype,
        weaponName = weaponData.name or "Unknown",
        weaponLabel = weaponData.label or "Unknown",
    }, {indent = true}))

    TriggerServerEvent("SendAlert:police", {
        coords = GetLocalPlayerPosition(),
        title = Config.Translations["215"],
        type = "215",
        metadata = {
            weapon = weaponChance and weaponData.label or nil,
            ammotype = ammoChance and GetCaliberTranslation(ammotype) or nil
        },
        job = {"police", "fib"},
        ignoreCooldown = true
    })
end

RegisterNetEvent("origen_police:client:robVehicle", function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local playerPos = GetLocalPlayerPosition()
        local streetA, streetB = Citizen.InvokeNative(0x2EB41072B4C1E4C0, playerPos.x, playerPos.y, playerPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
        local street = {}
        
        if streetA ~= 0 then
            table.insert(street, GetStreetNameFromHashKey(streetA))
        end
        
        if streetB ~= 0 then
            table.insert(street, GetStreetNameFromHashKey(streetB))
        end

        local vehicle = GetVehiclePedIsIn(ped, false)
        local vehicleLabel = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        
        TriggerServerEvent("SendAlert:police", {
            coords = playerPos,
            title = Config.Translations.VehicleRob,
            type = "FORZAR",
            message = Config.Translations.VehicleRobDesc,
            metadata = {
                model = vehicleLabel,
                color = {GetVehicleColor(GetVehiclePedIsIn(PlayerPedId()))},
                plate = GetVehiclePlate(GetVehiclePedIsIn(PlayerPedId())),
            },
            job = {"police", "sheriff", "fib"},
            ignoreCooldown = true
        })
    end
end)

if Config.Commands.ForceVehicle and Config.Commands.ForceVehicle.cmd ~= '' then
    RegisterCommand(Config.Commands.ForceVehicle.cmd, function()
        TriggerEvent("origen_police:client:robVehicle")
    end)
end

exports("RobVehicle", function()
    TriggerEvent("origen_police:client:robVehicle")
end)