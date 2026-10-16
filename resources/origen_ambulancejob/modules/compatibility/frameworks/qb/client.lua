local QBCore = nil
if GetResourceState('qb-core'):find('start') then
    QBCore = exports['qb-core']:GetCoreObject()
elseif GetResourceState('qbx_core') == 'started' then
    QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject() or exports.qbx_core
end

if not QBCore then return end

Framework = {}
local ox_inventory = (GetResourceState('ox_inventory') == 'started') and exports.ox_inventory
local origen_inventory = (GetResourceState('origen_inventory') == 'started') and exports.origen_inventory

-- Los datos del jugador salen de QBX.PlayerData (@qbx_core/modules/playerdata.lua,
-- en el fxmanifest): el export copiaba el PlayerData entero en cada llamada y
-- hasJob va cada 500 ms en dos hilos. Sin datos cargados (sin job, p. ej. tras
-- salir del personaje) se pregunta como antes.
local function getPlayerData()
    local playerData = QBX and QBX.PlayerData
    if playerData and playerData.job then return playerData end
    return QBCore and QBCore.Functions and QBCore.Functions.GetPlayerData and QBCore.Functions.GetPlayerData()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(3000)
    onPlayerLoaded()
end)

RegisterNetEvent('qbx_core:client:playerLoaded', function()
    Wait(3000)
    onPlayerLoaded()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    player.isDead = false
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    player.isDead = false
end)

local clothingScript = lib.load("config").clothingScript
function Framework.toggleClothes(toggle, clothes)
    if toggle then
        utils.debug("Putting on clothes")

        if clothingScript == 'origen_clothing' and GetResourceState('origen_clothing') == 'started' then
            exports['origen_clothing']:openOutfitMenu(true)
            return
        end

        local playerData = getPlayerData()
        local gender = playerData.charinfo.gender
        local playerPed = cache.ped
        local jobGrade = Framework.getPlayerJobGrade()

        utils.debug("Job Grade " .. jobGrade)

        if clothingScript and clothingScript ~= 'core' and clothingScript ~= 'origen_clothing' then
            local model = exports[clothingScript]:getPedModel(playerPed)

            if model == 'mp_m_freemode_01' then
                data = clothes.male[jobGrade] or clothes.male[1]
            elseif model == 'mp_f_freemode_01' then
                data = clothes.female[jobGrade] or clothes.female[1]
            end

            local outfits = {}
            local selected = false

            for outfitName, outfit in pairs(data) do
                outfits[#outfits + 1] = {
                    title = outfitName,
                    icon = 'fa-solid fa-shirt',
                    onSelect = function()
                        data = outfit
                        selected = true
                    end,
                }
            end
            lib.registerContext({
                id = 'origen_ambulancejob:police_outfits',
                title = locale("police_outfits_title"),
                options = outfits
            })
            lib.showContext('origen_ambulancejob:police_outfits')

            while not selected do Wait(500) end
            utils.debug("Using " .. clothingScript)

            lib.progressBar({
                duration = 3000,
                label = locale("clothesmenu_job_use"),
                useWhileDead = false,
                allowCuffed = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
                anim = {
                    dict = 'clothingshirt',
                    clip = 'try_shirt_positive_d'
                },
            })

            utils.debug("Using " .. clothingScript)

            exports[clothingScript]:setPedProps(playerPed, {
                {
                    component_id = 0,
                    texture = data['helmet_2'],
                    drawable = data['helmet_1']
                },
            })

            exports[clothingScript]:setPedComponents(playerPed, {
                {
                    component_id = 1,
                    texture = data['mask_2'],
                    drawable = data['mask_1']
                },
                {
                    component_id = 3,
                    texture = 0,
                    drawable = data['arms']
                },
                {
                    component_id = 8,
                    texture = data['tshirt_2'],
                    drawable = data['tshirt_1']
                },
                {
                    component_id = 11,
                    texture = data['torso_2'],
                    drawable = data['torso_1']
                },
                {
                    component_id = 9,
                    texture = data['bproof_2'],
                    drawable = data['bproof_1']
                },
                {
                    component_id = 10,
                    texture = data['decals_2'],
                    drawable = data['decals_1']
                },
                {
                    component_id = 7,
                    texture = data['chain_2'],
                    drawable = data['chain_1']
                },
                {
                    component_id = 4,
                    texture = data['pants_2'],
                    drawable = data['pants_1']
                },
                {
                    component_id = 6,
                    texture = data['shoes_2'],
                    drawable = data['shoes_1']
                },
                {
                    component_id = 5,
                    texture = data['bag_color'],
                    drawable = data['bag']
                },
            })
        elseif clothingScript == 'core' then
            utils.debug("Using " .. clothingScript)

            if gender == 0 then
                data = clothes.male[jobGrade] or clothes.male[1]
            else
                data = clothes.female[jobGrade] or clothes.female[1]
            end

            local outfits = {}
            local selected = false

            for outfitName, outfit in pairs(data) do
                outfits[#outfits + 1] = {
                    title = outfitName,
                    icon = 'fa-solid fa-shirt',
                    onSelect = function()
                        data = outfit
                        selected = true
                    end,
                }
            end

            lib.registerContext({
                id = 'origen_ambulancejob:police_outfits',
                title = locale("police_outfits_title"),
                options = outfits
            })
            lib.showContext('origen_ambulancejob:police_outfits')

            while not selected do Wait(500) end

            lib.progressBar({
                duration = 3000,
                label = locale("clothesmenu_job_use"),
                useWhileDead = false,
                allowCuffed = false,
                canCancel = false,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
                anim = {
                    dict = 'clothingshirt',
                    clip = 'try_shirt_positive_d'
                },
            })

            TriggerEvent('qb-clothing:client:loadOutfit', { outfitData = data })
        end
    else
        utils.debug("Putting civil clothes")

        if clothingScript == 'origen_clothing' and GetResourceState('origen_clothing') == 'started' then
            exports['origen_clothing']:ReloadAppearanceData()
        else
            TriggerServerEvent('qb-clothes:loadPlayerSkin')
        end
    end
end

function Framework.getPlayerJobGrade()
    local playerData = getPlayerData()
    local jobGrade = playerData.job.grade

    return type(jobGrade) == "table" and jobGrade.level or jobGrade
end

function Framework.playerJob()
    local playerData = getPlayerData()

    return playerData.job.name
end

function Framework.hasJob(jobs)
    local playerData = getPlayerData()
    if not playerData or not playerData.job then return false end

    local jobName = playerData.job.name
    if type(jobs) == "table" then
        for _, name in pairs(jobs) do
            if jobName == name then return true end
        end
    else
        return jobName == jobs
    end

    return false
end

function Framework.openBossMenu(job)
    if GetResourceState('qbx_management') == 'started' then
        exports.qbx_management:OpenBossMenu(job or 'ambulance')
    else
        TriggerEvent("qb-bossmenu:client:OpenMenu")
    end
end

function Framework.healStatus()
    TriggerServerEvent('consumables:server:setHunger', 100)
    TriggerServerEvent('consumables:server:setThirst', 100)
    TriggerServerEvent('consumables:server:addHunger', 100)
    TriggerServerEvent('consumables:server:addThirst', 100)
    TriggerServerEvent('origen_ambulancejob:server:restoreNeeds')
end

function Framework.hasItem(item, _quantity)
    local quantity = _quantity or 1

    -- Check ox_inventory if running
    if GetResourceState('ox_inventory') == 'started' and exports.ox_inventory then
        local ok, count = pcall(function() return exports.ox_inventory:Search('count', item) end)
        if ok and type(count) == "number" then return count >= quantity end
    end

    -- Check origen_inventory client memory cache (instant & synchronous)
    if GetResourceState('origen_inventory') == 'started' then
        local ok, inv = pcall(function() return exports['origen_inventory']:GetInventory() end)
        if ok and inv and type(inv) == "table" then
            local count = 0
            for _, v in pairs(inv) do
                if v and (v.name == item or v.item == item) then
                    count = count + (v.amount or v.count or 1)
                    if count >= quantity then return true end
                end
            end
        end

        local ok2, has = pcall(function() return exports['origen_inventory']:HasItem(item, quantity) end)
        if ok2 and has == true then return true end
    end

    -- Fallback to QBCore PlayerData items
    local playerData = getPlayerData()
    if playerData then
        if item == "money" or item == "cash" or item == "bank" then
            local playerAccounts = playerData.money
            local total = (playerAccounts and ((playerAccounts["bank"] or 0) + (playerAccounts["cash"] or 0))) or 0
            return total >= quantity
        end
        local playerInventory = playerData.items
        if playerInventory and type(playerInventory) == "table" then
            local count = 0
            for _, v in pairs(playerInventory) do
                if v and (v.name == item or v.item == item) then
                    count = count + (v.amount or v.count or 1)
                    if count >= quantity then return true end
                end
            end
        end
    end

    return false
end

function Framework.playerSpawned()
end
