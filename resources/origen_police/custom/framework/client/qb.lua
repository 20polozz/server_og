if Config.Framework ~= "qbcore" then return end
if GetResourceState("qb-core") ~= "started" and GetResourceState("qbx_core") ~= "started" then
    while true do
        print("^0[^5Origen Police^0] qb-core is not started, please make sure to start origen_police after qb-core^0")
        Wait(2000)
    end
end
Framework = exports['qb-core']:GetCoreObject()

function FW_TriggerCallback(...)
    Framework.Functions.TriggerCallback(...)
end

--- Los datos del jugador, siempre con la forma completa.
---
--- qb-core devuelve la tabla vacia mientras el jugador no ha terminado de
--- cargar, y eso pasa cada vez que se reinicia el recurso: el cliente se queda
--- sin datos hasta que el framework se los vuelve a empujar. Quien lea `job` en
--- ese hueco revienta —"attempt to index a nil value (field 'job')" al abrir la
--- tablet—, y son media docena de sitios repartidos por el recurso.
---
--- Se rellena aqui, una sola vez, con un puesto vacio: sin nombre y fuera de
--- servicio. No se inventa nada, que es lo que hay mientras no llegan los
--- datos, y ademas deja a CanOpenTablet decir que no en vez de fallar.
function FW_GetPlayerData()
    local data = Framework.Functions.GetPlayerData() or {}

    if not data.job then
        data.job = {
            name = '',
            label = '',
            onduty = false,
            isboss = false,
            grade = { level = 0, name = '' },
        }
    end

    return data
end

function FW_GetClosestVehicle(coords)
    return Framework.Functions.GetClosestVehicle(coords)
end

function FW_GetPlayersFromCoords(coords, radius)
    return Framework.Functions.GetPlayersFromCoords(coords, radius)
end

function FW_GetClosestVehicle(coords)
    return Framework.Functions.GetClosestVehicle(coords)
end

function FW_GetObjects()
    return Framework.Functions.GetObjects()
end

function Fw_GetPeds()
    return Framework.Functions.GetPeds()
end

function FW_GetVehicles()
    return Framework.Functions.GetVehicles()
end

function FW_SpawnVehicle(model, cb, coords, isNetwork)
    Framework.Functions.SpawnVehicle(model, cb, coords, isNetwork)
end

function FW_DeleteVehicle(vehicle)
    Framework.Functions.DeleteVehicle(vehicle)
end

function FW_SetVehicleProperties(vehicle, props)
    Framework.Functions.SetVehicleProperties(vehicle, props)
end

function FW_GetClosestPlayer(coords)
    return Framework.Functions.GetClosestPlayer(coords)

end

function FW_Notify(text)
    Framework.Functions.Notify(text)
end

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    TriggerEvent("origen_police:client:OnPlayerLoaded")
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    TriggerEvent("origen_police:client:OnPlayerUnload")
end)

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(jobData)
    TriggerEvent("origen_police:client:OnJobUpdate", jobData)
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(duty)
    SetDuty(duty)
end)

RegisterNetEvent('QBCore:Client:OnMetaDataUpdate', function(metadata, value)
    if type(metadata) == 'table' then
        SendNUIMessage({
            action = 'updateMetadata',
            metadata = metadata
        })
    else
        SendNUIMessage({
            action = 'updateMetadata',
            key = metadata,
            value = value
        })
    end
end)

RegisterNetEvent("origen_police:client:OnJobUpdate", function(jobData)
    SendNUIMessage({
        action = 'updateJob',
        jobData = jobData
    })
end)

CreateThread(function()
    local Player = FW_GetPlayerData()
    if Player and Player.job and Player.job.name then
        TriggerEvent("origen_police:client:OnPlayerLoaded")
    end
end)

exports('FW_TriggerCallback', FW_TriggerCallback)
exports('FW_GetPlayerData', FW_GetPlayerData)
exports('FW_GetPlayersFromCoords', FW_GetPlayersFromCoords)
exports('FW_GetClosestVehicle', FW_GetClosestVehicle)
exports('FW_GetClosestVehicle', FW_GetClosestVehicle)
exports('FW_GetObjects', FW_GetObjects)
exports('Fw_GetPeds', Fw_GetPeds)
exports('FW_GetVehicles', FW_GetVehicles)
exports('FW_SpawnVehicle', FW_SpawnVehicle)
exports('FW_DeleteVehicle', FW_DeleteVehicle)
exports('FW_SetVehicleProperties', FW_SetVehicleProperties)
exports('FW_GetClosestPlayer', FW_GetClosestPlayer)
exports('FW_Notify', FW_Notify)

exports('GetCoreObject', function()
    return Framework
end)