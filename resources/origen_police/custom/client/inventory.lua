function OpenStash(id, label, slots, weight, owner, private)
    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory" or
        Config.Inventory == "codem-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", id, {
            maxweight = weight,
            slots = slots,
            label = label
        })
        TriggerEvent("inventory:client:SetCurrentStash", id)
    else
        FW_TriggerCallback("origen_police:server:OpenPoliceStash", function(data)
            if not owner then
                local PlayerData = FW_GetPlayerData(false)
                owner = PlayerData.citizenid
            end
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('stash', {id=id, owner = owner})
            elseif Config.Inventory == "tgiann-inventory" then
                exports["tgiann-inventory"]:OpenInventory('stash', id, nil, nil)
            elseif Config.Inventory == "origen_inventory" then
                -- Opened by server
            else
            end
        end, id, label, slots, weight, private)
    end
end

Config.JobArmories = Config.JobArmories or {}

RegisterNetEvent("origen_police:client:updateJobArmories", function(jobArmories)
    Config.JobArmories = jobArmories or {}
    
    -- Sync backwards compatibility
    local PlayerData = FW_GetPlayerData()
    local jobName = PlayerData and PlayerData.job and PlayerData.job.name or "police"
    if Config.JobArmories[jobName] then
        Config.Armory.items = Config.JobArmories[jobName].items
        Config.Armory.label = Config.JobArmories[jobName].label
    end
    if Config.JobArmories["ambulance"] then
        Config.AmbulanceArmory.items = Config.JobArmories["ambulance"].items
        Config.AmbulanceArmory.label = Config.JobArmories["ambulance"].label
    end
end)

local function HasLicense(playerLicenses, reqLic)
    if not reqLic or reqLic == "" or reqLic == "none" then return true end
    if not playerLicenses then return false end
    if type(playerLicenses) ~= "table" then return false end

    -- Direct key check (e.g. playerLicenses["weapon"] = true)
    local direct = playerLicenses[reqLic]
    if direct == true or direct == 1 then return true end
    if type(direct) == "table" and (direct.status == true or direct.active == true or direct.has == true) then return true end

    -- Value / array / object check
    for k, v in pairs(playerLicenses) do
        if v == reqLic or k == reqLic then
            return true
        end
        if type(v) == "table" and (v.name == reqLic or v.type == reqLic or v.id == reqLic or v.license_type == reqLic or v.license_name == reqLic) then
            if v.status == nil or v.status == true or v.active == true then
                return true
            end
        end
    end
    return false
end

local function PlayerHasArmoryLicense(PlayerData, reqLic)
    if not reqLic or reqLic == "" or reqLic == "none" then return true end
    if not PlayerData or not PlayerData.metadata then return false end
    if HasLicense(PlayerData.metadata.police_licenses, reqLic) then return true end
    if HasLicense(PlayerData.metadata.licences, reqLic) then return true end
    if HasLicense(PlayerData.metadata.licenses, reqLic) then return true end
    return false
end

function OpenArmoury()
    local PlayerData = FW_GetPlayerData()
    local badge = PlayerData.metadata.police_badge or "0000"
    local jobLabel = PlayerData.job.label
    local jobName = PlayerData.job.name

    if PlayerData.job.name == "sheriff" then
        jobLabel = "BCSD"
    elseif PlayerData.job.name == "police" then
        jobLabel = "LSPD"
    elseif PlayerData.job.name == "sapd" then
        jobLabel = "SAPD"
    elseif PlayerData.job.name == "saspa" then
        jobLabel = "SASPA"
    end

    local serie = badge .. " | " .. jobLabel

    local armoryConfig = Config.JobArmories[jobName] or Config.Armory
    local tempArmory = {
        label = armoryConfig.label or "Equipamiento",
        items = json.decode(json.encode(armoryConfig.items or {}))
    }

    local filteredArmoryItems = {}
    local usedArmorySlots = {}
    local currentArmorySlot = 1
    for _, v in pairs(tempArmory.items) do
        local allowed = true
        local reqLic = v.requiredLicense or v.license
        if reqLic and not PlayerHasArmoryLicense(PlayerData, reqLic) then
            allowed = false
        end
        if v.licenses and type(v.licenses) == "table" and #v.licenses > 0 then
            for _, lic in ipairs(v.licenses) do
                if not PlayerHasArmoryLicense(PlayerData, lic) then
                    allowed = false
                    break
                end
            end
        end

        if allowed then
            if v.type == "weapon" then
                v.info = v.info or {}
                local randomSerial = string.format("%04X%04X", math.random(0x1000, 0xFFFF), math.random(0x1000, 0xFFFF))
                v.info.serie = randomSerial .. " | " .. jobLabel
            end

            local slot = tonumber(v.slot)
            if not slot or slot < 1 or usedArmorySlots[slot] then
                while usedArmorySlots[currentArmorySlot] do
                    currentArmorySlot = currentArmorySlot + 1
                end
                slot = currentArmorySlot
            end
            usedArmorySlots[slot] = true
            if slot >= currentArmorySlot then
                currentArmorySlot = slot + 1
            end
            v.slot = slot

            table.insert(filteredArmoryItems, v)
        end
    end
    tempArmory.items = filteredArmoryItems

    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "origen_inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "Equipment_" .. jobName, tempArmory)
    elseif Config.Inventory == "codem-inventory" then
        TriggerEvent('codem-inventory:OpenPlayerShop', tempArmory.items)
    else
        FW_TriggerCallback("origen_police:server:OpenPoliceArmoury", function(data)
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('shop', { type = 'OrigenPoliceArmoury_' .. jobName, id = 1})
            end
        end, jobName)
    end
end

function OpenAmbulanceArmoury()
    local armoryConfig = (Config.JobArmories and Config.JobArmories["ambulance"] and #Config.JobArmories["ambulance"].items > 0 and Config.JobArmories["ambulance"])
        or Config.AmbulanceArmory
        or {}
    local tempArmory = {
        label = armoryConfig.label or "Equipamiento EMS",
        items = json.decode(json.encode(armoryConfig.items or {}))
    }
    local PlayerData = FW_GetPlayerData()
    local filteredArmoryItems = {}
    local usedArmorySlots = {}
    local currentArmorySlot = 1
    for _, v in pairs(tempArmory.items) do
        local allowed = true
        local reqLic = v.requiredLicense or v.license
        if reqLic and not PlayerHasArmoryLicense(PlayerData, reqLic) then
            allowed = false
        end
        if v.licenses and type(v.licenses) == "table" and #v.licenses > 0 then
            for _, lic in ipairs(v.licenses) do
                if not PlayerHasArmoryLicense(PlayerData, lic) then
                    allowed = false
                    break
                end
            end
        end

        if allowed then
            local slot = tonumber(v.slot)
            if not slot or slot < 1 or usedArmorySlots[slot] then
                while usedArmorySlots[currentArmorySlot] do
                    currentArmorySlot = currentArmorySlot + 1
                end
                slot = currentArmorySlot
            end
            usedArmorySlots[slot] = true
            if slot >= currentArmorySlot then
                currentArmorySlot = slot + 1
            end
            v.slot = slot

            table.insert(filteredArmoryItems, v)
        end
    end
    tempArmory.items = filteredArmoryItems

    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "origen_inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "AmbulanceEquipment", tempArmory)
    elseif Config.Inventory == "codem-inventory" then
        TriggerEvent('codem-inventory:OpenPlayerShop', tempArmory.items)
    else
        FW_TriggerCallback("origen_police:server:OpenAmbulanceArmoury", function(data)
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('shop', { type = 'OrigenAmbulanceArmoury', id = 1})
            end
        end)
    end
end

-- Ambulance Armoury Interaction Point
--[[
CreateThread(function()
    if not Config.AmbulanceArmory or not Config.AmbulanceArmory.coords then return end

    local armoryCoords = Config.AmbulanceArmory.coords
    local point = lib.points.new({
        coords = vec3(armoryCoords.x, armoryCoords.y, armoryCoords.z),
        distance = 5.0,
    })

    function point:onExit()
        lib.hideTextUI()
    end

    function point:nearby()
        DrawMarker(20, armoryCoords.x, armoryCoords.y, armoryCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 150, 0, 200, false, true, 2, false, nil, nil, false)

        if self.currentDistance < 1.5 then
            local PlayerData = FW_GetPlayerData()
            if PlayerData and PlayerData.job and PlayerData.job.name == Config.AmbulanceArmory.job then
                if not lib.isTextUIOpen() then
                    lib.showTextUI('[E] - ' .. Config.AmbulanceArmory.label)
                end
                if IsControlJustPressed(0, 38) then
                    lib.hideTextUI()
                    OpenAmbulanceArmoury()
                end
            end
        elseif lib.isTextUIOpen() then
            lib.hideTextUI()
        end
    end
end)
]]

function OpenOtherPlayerInv(pID)
    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:openNearbyInventory()
    elseif  Config.Inventory == 'qb-inventory' or
            Config.Inventory == "origen_inventory" or
            Config.Inventory == 'qs-inventory'or
            Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", pID)
    elseif Config.Inventory == 'codem-inventory' then
        TriggerEvent('codem-inventory:client:openplayerinventory', pID)
        local isClose = true
        CreateThread(function()
            while isClose do
                local targetPed = GetPlayerPed(GetPlayerFromServerId(pID))
                if not targetPed then isClose = false return end
                local targetCoords = GetEntityCoords(targetPed)
                local playerCoords = GetEntityCoords(PlayerPedId())
                if #(targetCoords - playerCoords) >= 4.0 then
                    TriggerServerEvent('origen_police:server:SetInventoryRobStatus', pID, false)
                    isClose = false
                end
                Wait(3)
            end
        end)
    elseif Config.Inventory == 'core_inventory' then
        TriggerServerEvent('core_inventory:server:openInventory', pID, 'otherplayer', nil, nil, false)
    else
        TriggerServerEvent("origen_police:server:OpenOtherPlayerInv", pID)
    end
end

local animsToSearch = {
    { dict = 'missminuteman_1ig_2', anim = 'handsup_base', flag = 3 },
    { dict = 'mp_arresting', anim = 'idle', flag = 3 },
    { dict = 'random@mugging3', anim = 'handsup_standing_base', flag = 3},
    { dict = 'combat@damage@writhe', anim = 'writhe_loop', flag = 3 },
    { dict = 'veh@low@front_ps@idle_duck', anim = 'sit', flag = 3 },
    { dict = 'move_injured_ground', anim = 'front_loop', flag = 3 },
    { dict = 'dead', anim = 'dead_a', flag = 3 },
}

function CanSearchPlayer(player)
    -- Check if player can search another player
    -- Removed restrictions (hands up / cuffed) to allow searching anytime
    return true
end

function SearchClosestPlayer(playerId)
    local ped = PlayerPedId()
    local sId = tonumber(playerId)
    
    -- Get closest player in world for state detection (more reliable)
    local closestPlayer, closestDistance = FW_GetClosestPlayer()
    local targetPed = 0
    
    if closestPlayer ~= -1 and closestDistance <= 4.0 then
        targetPed = GetPlayerPed(closestPlayer)
    else
        -- Fallback to server ID if no one is physically close or detection fails
        local playerIdx = GetPlayerFromServerId(sId)
        if playerIdx ~= -1 then
            targetPed = GetPlayerPed(playerIdx)
        end
    end
    
    local animDict = "frisk@animation"
    local animName = "frisk_clip"
    
    -- Check if target is dead or injured to change police animation
    local isTargetDead = false
    if targetPed and targetPed ~= 0 and DoesEntityExist(targetPed) then
        local health = GetEntityHealth(targetPed)
        local isDeadNative = IsEntityDead(targetPed) or IsPedFatallyInjured(targetPed)
        local state = Entity(targetPed).state
        local stateIsDead = state.isDead or state.inLastStand or state.isdead or state.inlaststand
        
        -- Check for common downed/dead animations as fallback detection
        local isPlayingDeadAnim = IsEntityPlayingAnim(targetPed, "dead", "dead_a", 3) or 
                                IsEntityPlayingAnim(targetPed, "move_injured_ground", "front_loop", 3) or 
                                IsEntityPlayingAnim(targetPed, "combat@damage@writhe", "writhe_loop", 3) or
                                IsEntityPlayingAnim(targetPed, "veh@low@front_ps@idle_duck", "sit", 3)

        -- In many frameworks (like Qbox/QB), health 150 or 200 can be "downed" or "dead" 
        -- depending on the base health configuration (usually 100 base + 100 extra)
        isTargetDead = isDeadNative or stateIsDead or isPlayingDeadAnim or (health <= 150)
        
    end

    if isTargetDead then
        animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
        animName = "machinic_loop_mechandplayer"
    end
    
    -- Load dict
    RequestAnimDict(animDict)
    local timeout = 0
    while not HasAnimDictLoaded(animDict) and timeout < 100 do
        Wait(10)
        timeout = timeout + 1
    end

    ClearPedTasksImmediately(ped)
    Wait(100)
    
    -- Start animation manually before progress bar
    -- Flag 1 for searching on ground (full body), Flag 49 for standing frisk
    local flag = isTargetDead and 1 or 49
    TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, flag, 0, false, false, false)
    
    TriggerServerEvent("origen_police:server:SyncSearch", sId, true)
    
    ProgressBar("search_player_inv", Config.Translations.Searching or "Cacheando...", 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, nil, {}, {}, function() -- Done
        StopAnimTask(ped, animDict, animName, 1.0)
        ClearPedTasksImmediately(ped)
        TriggerServerEvent("origen_police:server:SyncSearch", sId, false)
        OpenOtherPlayerInv(sId)
        StartSearchDistance(sId)
    end, function() -- Cancel
        StopAnimTask(ped, animDict, animName, 1.0)
        ClearPedTasksImmediately(ped)
        TriggerServerEvent("origen_police:server:SyncSearch", sId, false)
    end)
end

function GiveVehicleKeys(vehicle)
    -- Your code here
end

function GetPlayerItems(PlayerData)
    if Config.Inventory == "qs-inventory" then
        return exports['qs-inventory']:getUserInventory() or {}
    elseif Config.Inventory == "ls-inventory" then
        return exports["ls-inventory"]:GetPlayerItems() or {}
    elseif Config.Inventory == "origen_inventory" then
        return exports.origen_inventory:GetInventory() or {}
    elseif Config.Inventory == "ox_inventory" then
        return exports.ox_inventory:GetPlayerItems() or {}
    elseif Config.Inventory == "codem-inventory" then
        return exports["codem-inventory"]:GetClientPlayerInventory() or {}
    elseif Config.Inventory == 'core_inventory' then
        local inventory = -1
        FW_TriggerCallback("core_inventory:server:getInventory", function(data)
            inventory = data
        end)
        while inventory == -1 do
            Wait(0)
        end
        return inventory or {}
    end

    if not PlayerData then
        PlayerData = FW_GetPlayerData()
    end
    return PlayerData.items or {}
end

function GetItemFromWeapon(PlayerData, weapon)
    if Config.Inventory == "core_inventory" then
        local data = exports["core_inventory"]:GetCurrentWeaponData()
        data.label = Config.WeaponsLabels[data.name] or "Unknown"
        return data
    end
    if not PlayerData or not PlayerData.job then
        Debuger("GetItemFromWeapon called without logged in player")
        return nil
    end
    local hashes = {}
    local saveHashes = Config.Debug
    for _, v in pairs(GetPlayerItems(PlayerData)) do
        if saveHashes then
            hashes[v.name] = GetHashKey(v.name)
        end
        if GetHashKey(v.name) == weapon then
            return v
        end
    end
    print("Couldn't find weapon in inventory with hash: " .. weapon .. (saveHashes and " hashes: " .. json.encode(hashes) or ""))
    return nil
end

exports("GetPlayerItems", GetPlayerItems)

function LockInventory(value) -- To avoid the player to open the inventory
    if Config.Inventory == "ox_inventory" then
        return -- Looks like when searching other player inventory ox check if the inv is bussy, cause the player is cuffed agents can't search the inventory of cuffed players
    end
    if GetResourceState("qs-inventory") == "started" then
        exports['qs-inventory']:setInventoryDisabled(value)
    end
    LocalPlayer.state.invBusy = value
end

function OpenEmergencyBackpack(itemName)
    itemName = itemName or "emergency_backpack"
    local armoryKey = "backpack_" .. itemName
    
    -- Fallback for backward compatibility if the old key was configured directly
    if not Config.JobArmories[armoryKey] and Config.JobArmories[itemName] then
        armoryKey = itemName
    end

    local armoryConfig = Config.JobArmories[armoryKey]
    if not armoryConfig or not armoryConfig.items or #armoryConfig.items == 0 then
        exports['origen_notify']:Notify({
            title = 'Mochila',
            description = "Esta mochila no tiene ítems configurados por un administrador.",
            type = "error",
            duration = 3000
        })
        return
    end

    local PlayerData = FW_GetPlayerData()
    local jobName = PlayerData and PlayerData.job and PlayerData.job.name or ""
    if armoryConfig.allowedJobs and #armoryConfig.allowedJobs > 0 then
        local isAllowed = false
        for _, allowedJob in ipairs(armoryConfig.allowedJobs) do
            if allowedJob == jobName then
                isAllowed = true
                break
            end
        end
        if not isAllowed then
            exports['origen_notify']:Notify({
                title = 'Mochila',
                description = "No tienes el trabajo requerido para abrir esta mochila.",
                type = "error",
                duration = 3000
            })
            return
        end
    end

    local tempArmory = {
        label = armoryConfig.label or "Mochila de Emergencias",
        items = json.decode(json.encode(armoryConfig.items))
    }

    local filteredBackpackItems = {}
    local usedArmorySlots = {}
    local currentArmorySlot = 1
    for _, v in pairs(tempArmory.items) do
        local allowed = true
        local reqLic = v.requiredLicense or v.license
        if reqLic and not PlayerHasArmoryLicense(PlayerData, reqLic) then
            allowed = false
        end
        if v.licenses and type(v.licenses) == "table" and #v.licenses > 0 then
            for _, lic in ipairs(v.licenses) do
                if not PlayerHasArmoryLicense(PlayerData, lic) then
                    allowed = false
                    break
                end
            end
        end

        if allowed then
            if v.type == "weapon" then
                v.info = v.info or {}
                local randomSerial = string.format("%04X%04X", math.random(0x1000, 0xFFFF), math.random(0x1000, 0xFFFF))
                v.info.serie = randomSerial .. " | MOCHILA"
            end

            local slot = tonumber(v.slot)
            if not slot or slot < 1 or usedArmorySlots[slot] then
                while usedArmorySlots[currentArmorySlot] do
                    currentArmorySlot = currentArmorySlot + 1
                end
                slot = currentArmorySlot
            end
            usedArmorySlots[slot] = true
            if slot >= currentArmorySlot then
                currentArmorySlot = slot + 1
            end
            v.slot = slot

            table.insert(filteredBackpackItems, v)
        end
    end
    tempArmory.items = filteredBackpackItems

    local shopId = "Equipment_" .. armoryKey

    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "origen_inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", shopId, tempArmory)
    elseif Config.Inventory == "codem-inventory" then
        TriggerEvent('codem-inventory:OpenPlayerShop', tempArmory.items)
    else
        FW_TriggerCallback("origen_police:server:OpenPoliceArmoury", function(data)
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('shop', {id=shopId})
            end
        end, shopId, tempArmory)
    end
end

exports("OpenEmergencyBackpack", OpenEmergencyBackpack)

local currentBackpackProp = nil

local function SpawnBackpackProp(modelName)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = coords + (forward * 0.8)
    
    local model = modelName or "xm_prop_x17_bag_med_01a"
    local modelHash = GetHashKey(model)
    
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        model = "xm_prop_x17_bag_med_01a"
        modelHash = GetHashKey(model)
    end
    
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(0)
    end
    
    local retval, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z, false)
    local zVal = retval and groundZ or (spawnCoords.z - 0.98)
    
    local prop = CreateObject(modelHash, spawnCoords.x, spawnCoords.y, zVal, true, true, false)
    PlaceObjectOnGroundProperly(prop)
    SetEntityHeading(prop, heading)
    FreezeEntityPosition(prop, true)
    
    return prop
end

local function OpenBackpackStash(stashId, stashLabel, itemName)
    local armoryKey = itemName and ("backpack_" .. itemName) or nil
    if armoryKey and not Config.JobArmories[armoryKey] and Config.JobArmories[itemName] then
        armoryKey = itemName
    end
    local armoryConfig = armoryKey and Config.JobArmories[armoryKey] or nil

    local slots = (armoryConfig and tonumber(armoryConfig.stashSlots)) or 40
    local weight = (armoryConfig and tonumber(armoryConfig.stashWeight)) or 100000 -- 100 kg
    
    if Config.Inventory == "ox_inventory" then
        TriggerServerEvent("origen_police:server:OpenBackpackStash", stashId, stashLabel, itemName)
        Wait(150)
        exports.ox_inventory:openInventory('stash', stashId)
    elseif Config.Inventory == "origen_inventory" then
        TriggerServerEvent("origen_police:server:OpenBackpackStash", stashId, stashLabel, itemName)
    elseif Config.Inventory == "qb-inventory" or Config.Inventory == "new-qb-inventory" or Config.Inventory == "qs-inventory" or Config.Inventory == "ls-inventory" then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", stashId, {
            maxweight = weight,
            slots = slots,
            label = stashLabel
        })
        TriggerEvent("inventory:client:SetCurrentStash", stashId)
    end
end

RegisterNetEvent("origen_police:client:openBackpackShopOption", function(data)
    OpenEmergencyBackpack(data.itemName)
end)

RegisterNetEvent("origen_police:client:openBackpackStashOption", function(data)
    OpenBackpackStash(data.stashId, data.label, data.itemName)
end)

RegisterNetEvent("origen_police:client:pickupBackpackOption", function()
    if currentBackpackProp and DoesEntityExist(currentBackpackProp) then
        DeleteEntity(currentBackpackProp)
        currentBackpackProp = nil
        exports['origen_notify']:Notify({
            title = 'Mochila',
            description = "Mochila recogida.",
            type = "success",
            duration = 3000
        })
    end
end)

local function OpenBackpackMenu(itemName, label, stashId, backpackType)
    backpackType = backpackType or "both"
    local menuData = {
        {
            header = label or "Mochila de Emergencias",
            icon = "fa-solid fa-briefcase",
            isMenuHeader = true
        }
    }

    if backpackType == "both" or backpackType == "shop" then
        menuData[#menuData + 1] = {
            header = "🛒 Tienda de la Mochila",
            txt = "Obtener suministros configurados",
            icon = "fa-solid fa-cart-shopping",
            params = {
                event = "origen_police:client:openBackpackShopOption",
                args = { itemName = itemName }
            }
        }
    end

    if backpackType == "both" or backpackType == "stash" then
        menuData[#menuData + 1] = {
            header = "📦 Almacén de la Mochila",
            txt = "Abrir compartimento de almacenamiento único",
            icon = "fa-solid fa-box-open",
            params = {
                event = "origen_police:client:openBackpackStashOption",
                args = { stashId = stashId, label = label, itemName = itemName }
            }
        }
    end

    menuData[#menuData + 1] = {
        header = "🎒 Recoger Mochila",
        txt = "Guardar mochila en el inventario",
        icon = "fa-solid fa-hand-holding",
        params = {
            event = "origen_police:client:pickupBackpackOption"
        }
    }
    exports['org-menu']:openMenu(menuData)
end

exports('UseEmergencyBackpack', function(slot, item)
    if not item or not item.name then return end
    
    local itemLabel = item.label or "Mochila de Emergencias"
    local armoryKey = "backpack_" .. item.name
    if not Config.JobArmories[armoryKey] and Config.JobArmories[item.name] then
        armoryKey = item.name
    end
    local armoryConfig = Config.JobArmories[armoryKey]
    local backpackType = armoryConfig and armoryConfig.backpackType or "both"
    
    -- Determine the correct prop to spawn
    local propModel = "xm_prop_x17_bag_med_01a" -- Default fallback
    local itemData = exports.origen_inventory:Items(item.name)
    if itemData then
        if itemData.prop then
            propModel = itemData.prop
        elseif itemData.client and itemData.client.prop then
            propModel = itemData.client.prop
        end
    end
    
    if armoryConfig and armoryConfig.backpackProp and armoryConfig.backpackProp ~= "" then
        propModel = armoryConfig.backpackProp
    end
    
    -- If already deployed, open the menu immediately without progress bar!
    if currentBackpackProp and DoesEntityExist(currentBackpackProp) then
        FW_TriggerCallback("origen_police:server:getBackpackStashId", function(stashId)
            if stashId then
                OpenBackpackMenu(item.name, itemLabel, stashId, backpackType)
            else
                exports['origen_notify']:Notify({
                    title = 'Mochila',
                    description = "Error al iniciar almacenamiento de la mochila.",
                    type = "error",
                    duration = 3000
                })
            end
        end, slot, item)
        return
    end
    
    local ped = cache.ped or PlayerPedId()
    TaskStartScenarioInPlace(ped, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
    
    local success = lib.progressCircle({
        duration = 3000,
        position = 'bottom',
        label = "Desplegando mochila...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = true,
            car = true,
            combat = true,
        }
    })
    
    ClearPedTasks(ped)
    
    if success then
        currentBackpackProp = SpawnBackpackProp(propModel)
        
        FW_TriggerCallback("origen_police:server:getBackpackStashId", function(stashId)
            if stashId then
                OpenBackpackMenu(item.name, itemLabel, stashId, backpackType)
                
                -- Check distance to automatically clean up, and listen to keypress to reopen
                local propToCheck = currentBackpackProp
                CreateThread(function()
                    local hasTextShown = false
                    while currentBackpackProp == propToCheck and DoesEntityExist(propToCheck) do
                        local playerPed = PlayerPedId()
                        local playerCoords = GetEntityCoords(playerPed)
                        local propCoords = GetEntityCoords(propToCheck)
                        local dist = #(playerCoords - propCoords)
                        
                        if dist > 3.0 then
                            if currentBackpackProp == propToCheck then
                                DeleteEntity(propToCheck)
                                currentBackpackProp = nil
                                if hasTextShown then
                                    exports['origen_notify']:HideText()
                                    hasTextShown = false
                                end
                                exports['origen_notify']:Notify({
                                    title = 'Mochila',
                                    description = "Te has alejado demasiado. Mochila recogida.",
                                    type = "error",
                                    duration = 3000
                                })
                            end
                            break
                        elseif dist < 1.8 then
                            if not hasTextShown then
                                exports['origen_notify']:DrawText('E', 'Interactuar con Mochila')
                                hasTextShown = true
                            end
                            if IsControlJustPressed(0, 38) then -- E key
                                OpenBackpackMenu(item.name, itemLabel, stashId, backpackType)
                            end
                        else
                            if hasTextShown then
                                exports['origen_notify']:HideText()
                                hasTextShown = false
                            end
                        end
                        Wait(0)
                    end
                    if hasTextShown then
                        exports['origen_notify']:HideText()
                    end
                end)
            else
                if currentBackpackProp and DoesEntityExist(currentBackpackProp) then
                    DeleteEntity(currentBackpackProp)
                    currentBackpackProp = nil
                end
                exports['origen_notify']:Notify({
                    title = 'Mochila',
                    description = "Error al iniciar almacenamiento de la mochila.",
                    type = "error",
                    duration = 3000
                })
            end
        end, slot, item)
    end
end)