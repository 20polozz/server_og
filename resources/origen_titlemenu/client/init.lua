

if Config.Framework == "qbcore" then
    QBCore = exports["qb-core"]:GetCoreObject()
elseif Config.Framework == "esx" then
    ESX = exports["es_extended"]:getSharedObject()
end

function FW_TriggerCallback(nombre, ...)
    if Config.Framework == "qbcore" then
        QBCore.Functions.TriggerCallback(nombre, ...)
    elseif Config.Framework == "esx" then
        ESX.TriggerServerCallback(nombre, ...)
    else
        -- Ni qbcore ni esx: nadie responderia y la NUI se quedaria esperando.
        print(('^1[origen_titlemenu] FW_TriggerCallback sin framework soportado (%s) para %s^0')
            :format(tostring(Config.Framework), tostring(nombre)))
    end
end

function FW_GetPlayerData()
    if Config.Framework == "qbcore" then
        return QBCore.Functions.GetPlayerData()
    elseif Config.Framework == "esx" then
        if Custom.GetPlayerData then
            return Custom.GetPlayerData()
        end
        local PlayerData = ESX.GetPlayerData()
        return {
            citizenid = PlayerData.identifier,
            items = PlayerData.inventory,
            job = PlayerData.job and {
                name = PlayerData.job.name,
                label = PlayerData.job.label,
                grade = {
                    level = PlayerData.job.grade,
                    name = PlayerData.job.grade_label
                },
                isboss = PlayerData.job.grade_name == "boss",
                onduty = GetResourceState("origen_police") == "started" and exports["origen_police"]:GetPoliceDuty() or false
            } or false,
            charinfo = {
                firstname = PlayerData.firstName,
                lastname = PlayerData.lastName,
                account = "XXXXXXXXX",
                birthdate = PlayerData.dateofbirth,
                nationality = "XXXXXXXXX",
                gender = PlayerData.sex == "m" and 0 or 1,
            },
            metadata = PlayerData.metadata,
            position = PlayerData.coords,
        }
    end
end

RegisterNUICallback("GetDebug", function(data, cb)
    cb(Config.Debug)
end)
--[[ Reiniciar este recurso con la partida ya empezada dejaba la portada puesta
     encima del juego: la pagina arranca de cero y nadie la quita, porque solo
     se quita al elegir personaje. Si al arrancar ya hay personaje cargado, se
     esconde y se suelta el raton. En una entrada normal no hay personaje
     todavia y esto no hace nada. ]]
AddEventHandler('onClientResourceStart', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(1500)
        local cargado = LocalPlayer.state.isLoggedIn
        if not cargado then
            local ok, datos = pcall(FW_GetPlayerData)
            cargado = ok and datos and datos.citizenid ~= nil
        end
        if not cargado then return end
        SendNUIMessage({ action = 'ocultarEnPartida' })
        if GetResourceState('origen_map') == 'started' then exports.origen_map:Apartar(false) end
        SetNuiFocus(false, false)
        -- Y deshacer lo que la entrada hubiera llegado a hacer.
        if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(500) end
        DisplayRadar(true)
        TriggerServerEvent('origen_titlemenu:server:VolverAlMundo')

        --[[ Red de seguridad: si el reinicio llego a llevarse al jugador al
             escenario del menu —esta bajo el mapa—, se le devuelve al mundo.
             Sin esto se quedaba ahi abajo, invisible y sin control, viendo una
             sala gris. ]]
        local ped = PlayerPedId()
        local aqui = GetEntityCoords(ped)

        if #(aqui - vector3(Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)) < 80.0
            or #(aqui - vector3(Config.CreationCoords.x, Config.CreationCoords.y, Config.CreationCoords.z)) < 80.0 then

            local destino = Config.DefaultSpawn
            DoScreenFadeOut(300)
            Wait(400)

            SetEntityCoords(ped, destino.x, destino.y, destino.z, false, false, false, false)
            SetEntityHeading(ped, destino.w or 0.0)
            FreezeEntityPosition(ped, false)
            SetEntityVisible(ped, true, false)
            SetEntityInvincible(ped, false)
            SetPlayerControl(PlayerId(), true, 0)
            ClearPedTasksImmediately(ped)

            Wait(600)
            DoScreenFadeIn(500)
        end
    end)
end)
