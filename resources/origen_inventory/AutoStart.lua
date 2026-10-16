local GRS = GetResourceState
local GRMD = GetResourceMetadata
local version = GRMD(GetCurrentResourceName(), 'version', 0) or '1.0.0'
local ESXOverridesVersion = 4

Config.Framework = GRS('qb-core'):match('start') and 'qbcore' or GRS('es_extended'):match('start') and 'esx' or 'NONE'
Config.FrameworkProvide = GRS('qb-core'):match('start') and GRS('qbx_core'):match('start')

if Config.FrameworkProvide then
    Config.Framework = 'qbcore'
    GlobalState.orgInventoryProvided = true
end

--Config.MenuSystem = GRS('qb-menu'):match('start') and 'qb-menu' or GRS('esx_menu_default'):match('start') and 'esx_menu_default' or 'NONE'
local inventoryIntegrations = json.decode(GRMD(GetCurrentResourceName(), 'integrations', 0))

local frameVersion = GRMD(
        Config.Framework and (Config.Framework == 'qbcore' and 'qb-core' or 'es_extended') or Config.Framework, 'version',
        0) or
    'X'
local frameVersionTested = frameVersion ~= 'X' and inventoryIntegrations[(Config.Framework)] or "0"
-- Integrations
local integrations = {
    {
        label = "QS Smartphone PRO",
        active = Config.Phone.Resource == 'qs-smartphone-pro' and
            (GRS('qs-smartphone-pro') == 'started' or GRS('qs-smartphone-pro') == 'starting'),
        version = GRMD('qs-smartphone-pro', 'version', 0) or 'X',
        testedVersion = inventoryIntegrations['qs-smartphone-pro']
    },
    {
        label = "LB-Phone",
        active = Config.Phone.Resource == 'lb-phone' and (GRS('lb-phone') == 'started' or GRS('lb-phone') == 'starting'),
        version = GRMD('lb-phone', 'version', 0) or 'X',
        testedVersion = inventoryIntegrations['lb-phone']
    },
}


local rsn = GetCurrentResourceName()
if rsn ~= 'origen_inventory' then
    for i = 1, 15, 1 do
        debugger('^1[ERROR] ^4Please, rename the resource folder to "origen_inventory"')
    end
    return error('[ERROR] Please, rename the resource folder to "origen_inventory"', 2)
end

--[[ El cartel de arranque --version, framework, integraciones-- ya no se
     escribe. Eran ocho lineas por cliente en cada conexion para decir cosas
     que no cambian entre reinicios y que estan en el fxmanifest y en la
     config; el aviso de version del framework, que es lo unico que podia
     querer leerse, tampoco pedia accion. Las comprobaciones siguen
     haciendose: lo unico que se ha ido es el print. ]]


local context = IsDuplicityVersion()
if context then

    -- if not Config.Debug and GetResourceState("ox_inventory") ~= "missing" then
    --     print("")
    --     print("")
    --     print("^0[Integrations] ^1OX Inventory detected, please remove from your resource folder...")
    --     print("^0[Integrations] ^1OX Inventory detected, please remove from your resource folder...")
    --     print("^0[Integrations] ^1OX Inventory detected, please remove from your resource folder...^0")
    --     print("")
    --     print("")
    --     return
    -- end

    if Config.Framework == 'qbcore' then
        QBCore = exports['qb-core']:GetCoreObject()
        --- Wait for QBCore to be ready or cancel

        if not QBCore or not QBCore.Functions.SetMethod then
            debugger(
                "[QBCore-Integration] Dear user, QBCore is not loaded or is an outdated version. Please, check your version and try again.")
            return
        end

        QBCore.Functions.SetMethod('CreateUseableItem', function(item, data)
            CreateUseableItem(item, data)
        end)

        QBCore.Functions.SetMethod('UseItem', function(source, item)
            UseItem(source, item)
        end)

        QBCore.Functions.SetMethod('HasItem', function(source, items, amount)
            return HasItem(source, items, amount)
        end)

        RegisterNetEvent('QBCore:Server:PlayerLoaded', function(Player)
            QBCore.Functions.AddPlayerMethod(Player.PlayerData.source, "GetTotalWeight", function(items)
                return GetTotalWeightByItems(items)
            end)
        end)

    elseif Config.Framework == 'esx' then
        local esxExport = exports.es_extended
        local checkGetUseablesItemsFunc = pcall(function()
            local test = esxExport.GetUseablesItems
        end)

        if not checkGetUseablesItemsFunc then
            print(
                "[ESX-Integration] Dear user, missing GetUseablesItems function in es_extended. Please follow installations steps.")
            return
        end

        local esxOverrides = LoadResourceFile('es_extended', '/server/classes/overrides/origeninventory.lua')

        if esxOverrides then
            local matchVersion = esxOverrides:match('---- Origen_File_Version %- (%d+)')
            local matchGetPlayerInventory = esxOverrides:match('GetPlayerInventory')
            local matchSaveFunc = esxOverrides:match('Core%.SavePlayer%(self%)')
            if matchVersion and matchGetPlayerInventory and matchSaveFunc then
                if tonumber(matchVersion) and (tonumber(matchVersion) == ESXOverridesVersion) then
                    return
                end
                print("[Integrations ESX] [Version mismatch] OrigenInventory integration is outdated.")
            else
                if not matchVersion then
                    print("[Integrations ESX] [Version Not Found] OrigenInventory integration is outdated.")
                elseif not matchGetPlayerInventory then
                    print("[Integrations ESX] [GetInventory Outdated] OrigenInventory integration is not found.")
                elseif not matchSaveFunc then
                    print(
                        "[Integrations ESX] [SavePlayer] OrigenInventory integration is not found. Please, check your files.")
                end
            end
        else
            print("[Integrations] ^1OrigenInventory Overrides is not found. Please, check your files.^0")
        end
    end
end