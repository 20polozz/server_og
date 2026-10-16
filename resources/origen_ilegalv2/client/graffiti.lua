-- ── Guard: si el sistema interno de graffiti está desactivado, no registrar nada ──
if not Config.Graffiti or not Config.Graffiti.Enable then return end

local isGraffitiOpen = false
local graffitis = {}
local playerGangId = nil

local dbg = Debug:new({ enabled = Config.Debug })

local function getPlayerGang()
    local gangData = lib.callback.await('origen_gang:server:getPlayerGang', false)
    return gangData
end

RegisterNUICallback('graffiti:close', function(data, cb)
    isGraffitiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('graffiti:getApiKey', function(data, cb)
    local apiKey = lib.callback.await('origen_gang:server:getFivemanageToken', false)
    cb(apiKey)
end)

RegisterNUICallback('graffiti:apply', function(data, cb)
    if not data.imageUrl then
        cb({ error = 'No image URL provided' })
        return
    end

    local gangData = getPlayerGang()
    if not gangData or not gangData.id then
        Notify.SendNotification('Error', 'Debes estar en una banda para usar graffitis', 'error')
        cb({ error = 'No gang' })
        return
    end

    isGraffitiOpen = false
    SetNuiFocus(false, false)
    cb('ok')
    
    Wait(100)
    TriggerEvent('origen_gang:client:startGraffitiPlacement', data.imageUrl)
end)

RegisterNUICallback('graffiti:save', function(data, cb)
    if not data.imageUrl or not data.name then
        cb({ error = 'Faltan datos' })
        return
    end

    local gangData = getPlayerGang()
    
    if data.isShared and (not gangData or not gangData.id) then
        Notify.SendNotification('Error', 'Debes estar en una banda para compartir graffitis', 'error')
        cb({ error = 'No gang' })
        return
    end

    TriggerServerEvent('origen_gang:server:saveGraffiti', {
        imageUrl = data.imageUrl,
        name = data.name,
        isShared = data.isShared,
        gangId = (data.isShared and gangData) and gangData.id or nil
    })
    
    Notify.SendNotification('Grafiti', 'Grafiti guardado', 'success')
    
    cb('ok')
end)

RegisterNUICallback('graffiti:startSpray', function(data, cb)
    if not data.imageUrl then
        cb({ error = 'No image URL provided' })
        return
    end

    local gangData = getPlayerGang()
    if not gangData or not gangData.id then
        Notify.SendNotification('Error', 'Debes estar en una banda para grafitear', 'error')
        cb({ error = 'No gang' })
        return
    end

    cb('ok')
    
    Wait(50)
    
    isGraffitiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'setVisible',
        data = { visible = false }
    })
    
    Wait(100)
    TriggerEvent('origen_gang:client:startGraffitiPlacement', data.imageUrl)
end)

RegisterNUICallback('graffiti:getAll', function(data, cb)
    local gangData = getPlayerGang()
    if not gangData or not gangData.id then
        cb({})
        return
    end

    TriggerServerEvent('origen_gang:server:getGraffitis', gangData.id)
    
    local timeout = 0
    while graffitis == nil and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
    
    cb(graffitis or {})
    graffitis = {}
end)

RegisterNUICallback('graffiti:delete', function(data, cb)
    if not data.id then
        cb({ error = 'No ID provided' })
        return
    end

    TriggerServerEvent('origen_gang:server:deleteGraffiti', data.id)
    cb('ok')
end)

RegisterNetEvent('origen_gang:client:receiveGraffitis', function(data)
    graffitis = data
end)

RegisterNetEvent('origen_gang:client:openGraffiti', function()
    if isGraffitiOpen then dbg:info('NUI already open') return end
    
    local gangData = getPlayerGang()
    if not gangData or not gangData.id then
        Notify.SendNotification('Error', 'Debes estar en una banda para usar el editor de graffiti', 'error')
        return
    end

    playerGangId = gangData.id
    isGraffitiOpen = true
    SendTranslationsToNUI()
    SetNuiFocus(true, true)
    dbg:success('Opening NUI')
    SendNUIMessage({
        action = 'openGraffiti'
    })
end)

RegisterNetEvent('origen_gang:client:closeGraffiti', function()
    if not isGraffitiOpen then return end
    
    isGraffitiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeGraffiti'
    })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if isGraffitiOpen then
        SetNuiFocus(false, false)
    end
end)

exports('GetPlayerGang', getPlayerGang)
