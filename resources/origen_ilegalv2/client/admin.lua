-- Admin Panel Client
local adminPanelOpen = false
local openedFromHub = false

local dbg = Debug:new({
    enabled = Config.Debug
})

-- Open Admin Panel
RegisterCommand('gangadmin', function()
    -- Abierto a mano, no desde el hub: una marca vieja le quitaba el raton
    -- 2,8 s y al cerrar mandaba de vuelta al admin.
    openedFromHub = false
    TriggerServerEvent('origen_gang:server:requestAdminPanel')
end, false)

-- Hub Integration
exports('IsOpenedFromHub', function() return openedFromHub end)
exports('ResetHubFlag', function() openedFromHub = false end)

exports('openManagement', function()
    
    openedFromHub = true
    
    CreateThread(function()
        -- Solicitar apertura del panel
        TriggerServerEvent('origen_gang:server:requestAdminPanel')
        
        -- Esperar 2.8 segundos antes de activar el focus
        
        Wait(2800)
        
        -- El focus se activa en el evento origen_gang:client:openAdminPanel
        -- pero solo si NO fue abierto desde el hub
        
    end)
end)

-- NUI Callbacks for Admin Panel
RegisterNUICallback('closeAdminPanel', function(data, cb)
    
    adminPanelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
    
    if openedFromHub then
        
        openedFromHub = false
        exports['origen_admin']:ReturnToScripts()
    else
        
    end
end)

-- Si el raton se suelta a la fuerza (`soltarraton`, pagina vacia o colgada;
-- ver origen_map/shared/foco.lua), el panel se cierra de verdad: con la marca
-- en true la pagina se quedaria pintada sin raton. No se vuelve al admin: eso
-- cogeria el raton otra vez.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not adminPanelOpen then return end
        adminPanelOpen = false
        openedFromHub = false
        SendNUIMessage({ action = 'closeAdminPanel' })
    end)
end

-- Stats
RegisterNUICallback('admin:getStats', function(data, cb)
    local stats = lib.callback.await('origen_gang:admin:getStats', false)
    cb(stats)
end)

-- Gangs Management
RegisterNUICallback('admin:getGangs', function(data, cb)
    local gangs = lib.callback.await('origen_gang:admin:getGangs', false)
    cb(gangs)
end)

RegisterNUICallback('admin:createGang', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:createGang', false, data.label, data.leader)
    cb(success)
end)

RegisterNUICallback('admin:deleteGang', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:deleteGang', false, data.gangId)
    cb(success)
end)

RegisterNUICallback('admin:updateGang', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:updateGang', false, data.gangId, data.data)
    cb(success)
end)

RegisterNUICallback('admin:setGangMoney', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:setGangMoney', false, data.gangId, data.amount)
    cb(success)
end)

RegisterNUICallback('admin:setGangLevel', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:setGangLevel', false, data.gangId, data.level)
    cb(success)
end)

RegisterNUICallback('admin:addMemberToGang', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:addMemberToGang', false, data.gangId, data.identifier)
    cb(success)
end)

RegisterNUICallback('admin:removeMemberFromGang', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:removeMemberFromGang', false, data.gangId, data.identifier)
    cb(success)
end)

RegisterNUICallback('admin:setMemberRank', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:setMemberRank', false, data.gangId, data.identifier, data.rankId)
    cb(success)
end)

RegisterNUICallback('admin:getGangMembers', function(data, cb)
    local members = lib.callback.await('origen_gang:admin:getGangMembers', false, data.gangId)
    cb(members)
end)

RegisterNUICallback('admin:getGangRanks', function(data, cb)
    local ranks = lib.callback.await('origen_gang:admin:getGangRanks', false, data.gangId)
    cb(ranks)
end)

RegisterNUICallback('admin:getGangLocations', function(data, cb)
    local locations = lib.callback.await('origen_gang:admin:getGangLocations', false, data.gangId)
    cb(locations)
end)

RegisterNUICallback('admin:getLocationTypes', function(data, cb)
    local locationTypes = {}
    for typeKey, typeData in pairs(Config.Locations.Types) do
        table.insert(locationTypes, {
            value = typeKey,
            label = locale:t(typeData.label)
        })
    end
    cb(locationTypes)
end)

RegisterNUICallback('admin:addGangLocation', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:addGangLocation', false, data.gangId, data.locationName, data.locationType)
    cb(success)
end)

RegisterNUICallback('admin:removeGangLocation', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:removeGangLocation', false, data.gangId, data.locationId)
    cb(success)
end)

RegisterNUICallback('admin:getPermissions', function(data, cb)
    local permissions = lib.callback.await('origen_gang:admin:getPermissions', false)
    cb(permissions)
end)

RegisterNUICallback('admin:grantCreatePermission', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:grantCreatePermission', false, data)
    cb(success)
end)

RegisterNUICallback('admin:revokeCreatePermission', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:revokeCreatePermission', false, data.identifier)
    cb(success)
end)

-- Guardar nombre, color y territorio base de una banda. La ficha lo pedia y
-- no habia quien lo atendiera: el boton no hacia nada.
RegisterNUICallback('admin:updateGangInfo', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateGangInfo', false, data)
    cb(result or { success = false })
end)

-- Logs
RegisterNUICallback('admin:getLogs', function(data, cb)
    local logs = lib.callback.await('origen_gang:admin:getLogs', false, data.gangId)
    cb(logs or {})
end)

-- Gang Config
RegisterNUICallback('admin:getGangConfig', function(data, cb)
    local config = lib.callback.await('origen_gang:admin:getGangConfig', false, data.gangId)
    cb(config)
end)

RegisterNUICallback('admin:updateGangConfig', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:updateGangConfig', false, data.gangId, data.config)
    cb(success)
end)

-- Gang Sanctions
-- La banda cuya ficha de sanciones esta abierta: quitar y ampliar solo traen
-- el id de la sancion, y hay que saber de quien repintar la lista.
local bandaSanciones = nil

local function RepintarSanciones()
    if not bandaSanciones then return end
    local lista = lib.callback.await('origen_gang:admin:getGangSanctions', false, bandaSanciones)
    SendNUIMessage({ action = 'updateGangSanctions', data = lista or {} })
end

RegisterNUICallback('admin:getGangSanctions', function(data, cb)
    bandaSanciones = data.gangId
    local sanctions = lib.callback.await('origen_gang:admin:getGangSanctions', false, data.gangId)
    -- La ficha pinta lo que le llega por este mensaje, y no lo mandaba nadie:
    -- las sanciones no salian nunca.
    SendNUIMessage({ action = 'updateGangSanctions', data = sanctions or {} })
    cb(sanctions or {})
end)

RegisterNUICallback('admin:applySanction', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:applySanction', false, data.gangId, data.sanction)
    cb(success)
    bandaSanciones = data.gangId
    RepintarSanciones()
end)

RegisterNUICallback('admin:removeSanction', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:removeSanction', false, data.sanctionId)
    cb(success)
    RepintarSanciones()
end)

RegisterNUICallback('admin:extendSanction', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:extendSanction', false, data.sanctionId, data.hours)
    cb(success)
    RepintarSanciones()
end)

RegisterNUICallback('admin:setGangPoints', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:setGangPoints', false, data.gangId, data.points)
    cb(success)
end)

RegisterNUICallback('admin:setGangStatus', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:setGangStatus', false, data.gangId, data.isActive)
    cb(success)
end)

-- Announcements
RegisterNUICallback('admin:getAnnouncements', function(data, cb)
    dbg:info('Fetching announcements from server...')
    local announcements = lib.callback.await('origen_gang:admin:getAnnouncements', false)
    cb(announcements)
end)

RegisterNUICallback('admin:createAnnouncement', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:createAnnouncement', false, data)
    cb(success)
end)

RegisterNUICallback('admin:deleteAnnouncement', function(data, cb)
    local success = lib.callback.await('origen_gang:admin:deleteAnnouncement', false, data.announcementId)
    cb(success)
end)

RegisterNUICallback('admin:getAnnouncementReaders', function(data, cb)
    local readers = lib.callback.await('origen_gang:admin:getAnnouncementReaders', false, data.announcementId)
    cb(readers)
end)

RegisterNUICallback('admin:getTerritories', function(data, cb)
    local territories = lib.callback.await('origen_gang:admin:getTerritories', false)
    cb(territories or { success = false, territories = {} })
end)

RegisterNUICallback('admin:createTerritory', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createTerritory', false, data)
    cb(result or { success = false, message = 'No response from server' })
end)

RegisterNUICallback('admin:updateTerritory', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateTerritory', false, data)
    cb(result or { success = false, message = 'No response from server' })
end)

RegisterNUICallback('admin:deleteTerritory', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteTerritory', false, data.territoryId)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:resetTerritory', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:resetTerritory', false, data.territoryId)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:getVehicleCatalog', function(data, cb)
    local result = lib.callback.await('origen_gangs:server:admin:getVehicleCatalog', false, data.gangId)
    cb(result or {})
end)

RegisterNUICallback('addVehicleToCatalog', function(data, cb)
    local success = lib.callback.await('origen_gangs:server:admin:addVehicleToCatalog', false, data.gangId, data.vehicleData)
    cb(success)
end)

RegisterNUICallback('updateVehicleCatalog', function(data, cb)
    local success = lib.callback.await('origen_gangs:server:admin:updateVehicleCatalog', false, data.catalogId, data.vehicleData)
    cb(success)
end)

RegisterNUICallback('deleteVehicleCatalog', function(data, cb)
    local success = lib.callback.await('origen_gangs:server:admin:deleteVehicleCatalog', false, data.catalogId)
    cb(success)
end)

-- ── Drug Editor ────────────────────────────────────────────────────────────────
RegisterNUICallback('admin:getDrugList', function(data, cb)
    local list = lib.callback.await('origen_gang:admin:getDrugList', false)
    cb(list or {})
end)

RegisterNUICallback('admin:drugs:getInventoryItems', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:getInventoryItemsForDrugs', false)
    cb(result or {})
end)

RegisterNUICallback('admin:createDrug', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:createDrug', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:updateDrug', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:updateDrug', false, data)
    cb(result or { success = false })
end)

RegisterNUICallback('admin:deleteDrug', function(data, cb)
    local result = lib.callback.await('origen_gang:admin:deleteDrug', false, data.name)
    cb(result or { success = false })
end)

-- Sync de DrugList enviado desde servidor cuando otro admin crea/edita/borra una droga
RegisterNetEvent('origen_gang:client:syncDrugList', function(newDrugList)
    if not newDrugList then return end
    Config.DrugSales.DrugList = newDrugList
end)

RegisterNetEvent('origen_gang:client:openAdminPanel', function()
    adminPanelOpen = true
    SendTranslationsToNUI()
    
    -- Solo activar focus inmediatamente si NO fue abierto desde el hub
    if not openedFromHub then
        SetNuiFocus(true, true)
    else
        -- Si fue abierto desde el hub, activar focus después de 2.8s
        CreateThread(function()
            Wait(2800)

            -- Si se cerro en esos 2,8 s, darle el raton dejaria el foco puesto
            -- sin ninguna pantalla delante.
            if adminPanelOpen then
                SetNuiFocus(true, true)
            end
        end)
    end
    
    SendNUIMessage({
        action = 'openAdminPanel'
    })
end)

RegisterNetEvent('origen_gang:client:closeAdminPanel', function()
    adminPanelOpen = false
    openedFromHub = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'closeAdminPanel'
    })
end)

RegisterNetEvent('origen_gang:client:admin:updateGangConfig', function(config)
    SendNUIMessage({
        action = 'updateGangConfig',
        data = config
    })
end)

RegisterNetEvent('origen_gang:client:admin:updateGangSanctions', function(sanctions)
    SendNUIMessage({
        action = 'updateGangSanctions',
        data = sanctions
    })
end)
