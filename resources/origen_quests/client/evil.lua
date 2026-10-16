local QBCore = exports['qb-core']:GetCoreObject()

RegisterNUICallback('ChangeEvilNpcClothes', function(data, cb)
    QBCore.Functions.TriggerCallback('origen_quests:server:GetEvilNPCClothes', function(result)
        if result then
            local pcoords = GetEntityCoords(PlayerPedId())

            if #(pcoords - vector3(result.coords.x, result.coords.y, result.coords.z)) < 20 then
                cb(true)
                ChangeNPClothes(result)
            else
                cb('Debes estar cerca del area de spawn del NPC')
            end
        else
            cb('No se ha encontrado el NPC')
        end
    end, data.id)
end)

function ChangeNPClothes(data)
    local coords = vector4(data.coords.x, data.coords.y, data.coords.z - 1, data.coords.w)
    local model = GetHashKey(data.model)

    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local npc = CreatePed(5, model, coords.x, coords.y, coords.z, coords.w, false, false)
    SetEntityAsMissionEntity(npc, true, true)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(model)
    FreezeEntityPosition(npc, true)

    if type(data.weapon) == 'string' and data.weapon ~= '' then
        local rawWeapon = data.weapon:gsub('^%s+', ''):gsub('%s+$', '')
        local normalized = string.upper(rawWeapon)
        if normalized == 'BATE' then normalized = 'WEAPON_BAT' end
        if not normalized:find('^WEAPON_') then
            normalized = 'WEAPON_' .. normalized
        end

        local weaponHash = GetHashKey(normalized)
        if IsWeaponValid(weaponHash) then
            GiveWeaponToPed(npc, weaponHash, 1000, false, true)
            SetCurrentPedWeapon(npc, weaponHash, true)
        end
    end

    SetNPCSkin(npc, data.skin)

    exports.origen_clothing:startPedCreation(true, 0, npc, true, function(skin)
        DeleteEntity(npc)
        
        if skin then
            TriggerServerEvent('origen_quests:server:SaveEvilNPCClothes', data.id, skin)
        end
    end)
end

EnabledToSpawn = {}
local spawnedEvilNPCsById = {}
local trackedEvilNPCs = {}
local rewardThreadRunning = false
local npcTable = {}
local lootingPromptNpc = nil

local weaponAliases = {
    bate = 'WEAPON_BAT',
    bat = 'WEAPON_BAT',
    knife = 'WEAPON_KNIFE',
    cuchillo = 'WEAPON_KNIFE',
    pistol = 'WEAPON_PISTOL',
    combatpistol = 'WEAPON_COMBATPISTOL'
}

local function normalizeWeapon(weaponName)
    if type(weaponName) ~= 'string' then return nil, nil end
    local trimmed = weaponName:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmed == '' then return nil, nil end

    local normalized = string.upper(trimmed)
    if not normalized:find('^WEAPON_') then
        normalized = weaponAliases[string.lower(trimmed)] or ('WEAPON_' .. normalized)
    end

    local weaponHash = GetHashKey(normalized)
    if not IsWeaponValid(weaponHash) then
        return nil, nil
    end

    return normalized, weaponHash
end

local function decodeSkinData(skin)
    if type(skin) == 'table' then
        return skin
    end

    if type(skin) ~= 'string' or skin == '' then
        return {}
    end

    local ok, decoded = pcall(json.decode, skin)
    if ok and type(decoded) == 'table' then
        return decoded
    end

    return {}
end

local function registerSpawnedNpc(id, npc)
    if not id or not npc then return end
    spawnedEvilNPCsById[id] = spawnedEvilNPCsById[id] or {}
    spawnedEvilNPCsById[id][npc] = true
    trackedEvilNPCs[npc] = id
end

local function unregisterSpawnedNpc(npc)
    local id = trackedEvilNPCs[npc]
    if id and spawnedEvilNPCsById[id] then
        spawnedEvilNPCsById[id][npc] = nil
        if not next(spawnedEvilNPCsById[id]) then
            spawnedEvilNPCsById[id] = nil
        end
    end
    trackedEvilNPCs[npc] = nil
    npcTable[npc] = nil
end

local function deleteSpawnedNpcsById(id)
    local list = spawnedEvilNPCsById[id]
    if not list then return end
    for npc, _ in pairs(list) do
        unregisterSpawnedNpc(npc)
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    spawnedEvilNPCsById[id] = nil
end

CreateThread(function()
    AddRelationshipGroup('EvilNPCs')
    SetRelationshipBetweenGroups(0, GetHashKey('EvilNPCs'), GetHashKey('EvilNPCs'))
    SetRelationshipBetweenGroups(5, GetHashKey('EvilNPCs'), GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('EvilNPCs'))

    QBCore.Functions.TriggerCallback('origen_quests:server:GetEvilNPCsToSpawn', function(result)
        EnabledToSpawn = result
    end)

    while true do
        Wait(1000)

        local pcoords = GetEntityCoords(PlayerPedId())

        for k, v in pairs(EnabledToSpawn) do
            -- Flag anti-spam: solo hacemos el callback una vez hasta que se procese
            if not v.requesting and #(pcoords - v.coords) < 150 then
                v.requesting = true
                QBCore.Functions.TriggerCallback('origen_quests:server:TryToSpawnEvilNPC', function(result)
                    v.requesting = false
                    if result then
                        SpawnEvilNPC(result)
                        EnabledToSpawn[k] = nil
                    end
                end, v.id)
            end
        end
    end
end)

RegisterNetEvent('origen_quests:client:EnableToSpawnEvilNPC', function(id, coords)
    for _, npcData in pairs(EnabledToSpawn) do
        if npcData.id == id then
            return
        end
    end

    EnabledToSpawn[#EnabledToSpawn+1] = {
        id = id,
        coords = vector3(coords.x, coords.y, coords.z)
    }
end)

RegisterNetEvent('origen_quests:client:DisableToSpawnEvilNPC', function(id)
    for k, v in pairs(EnabledToSpawn) do
        if v.id == id then
            EnabledToSpawn[k] = nil
        end
    end
end)

RegisterNetEvent('origen_quests:client:DeleteEvilNPC', function(id)
    for k, v in pairs(EnabledToSpawn) do
        if v.id == id then
            EnabledToSpawn[k] = nil
        end
    end
    deleteSpawnedNpcsById(id)
end)

local giveitem = {
    {item = 'ognphone', amount = 1},
    {item = 'pistol_ammo', amount = 12},
}

local rewwardItemsNPC = {}

local function saquearNPC(items, npc, npcId)
    local wait = true
    QBCore.Functions.Progressbar('saqueando_npc', 'Saqueando...', 3000, false, false, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
        anim = 'machinic_loop_mechandplayer',
        flags = 49,
    }, {}, {}, function() -- Done
        wait = false
        unregisterSpawnedNpc(npc)
        DeleteEntity(npc)
        TriggerServerEvent('origen_quests:server:GiveRewardItems', npcId)

        -- Notificación local con los items robados
        if type(items) == 'table' and next(items) then
            local lines = {}
            for itemName, amount in pairs(items) do
                local label = itemName
                local shared = QBCore.Shared and QBCore.Shared.Items and QBCore.Shared.Items[itemName]
                if shared and shared.label then
                    label = shared.label
                end
                lines[#lines + 1] = '+' .. tostring(amount) .. 'x ' .. label
            end
            if #lines > 0 then
                exports['origen_notify']:Notify({
                    title = 'Origen Quest',
                    description = table.concat(lines, '\n'),
                    type = 'success',
                    duration = 5000,
                })
            end
        end
    end, function() -- Cancel
        wait = false
    end)

    while wait do
        Wait(500)
    end
end

local function checkRewardItemsNPC()
    if rewardThreadRunning then
        return
    end
    rewardThreadRunning = true

    CreateThread(function()
        while true do
            local _s = 500
            if not next(npcTable) then
                if lootingPromptNpc then
                    exports.origen_notify:HideText()
                    lootingPromptNpc = nil
                end
                rewardThreadRunning = false
                break
            end

            local closestNpc, closestDistance = nil, 99999.0
            for npc, _ in pairs(npcTable) do
                if not DoesEntityExist(npc) then
                    unregisterSpawnedNpc(npc)
                    goto continue
                end

                local isDead = IsPedDeadOrDying(npc, true) or IsPedFatallyInjured(npc) or GetEntityHealth(npc) <= 0
                if isDead then
                    local distance = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(npc))
                    if distance < closestDistance then
                        closestDistance = distance
                        closestNpc = npc
                    end
                end

                ::continue::
            end

            if closestNpc and closestDistance < 2.5 then
                _s = 0
                if lootingPromptNpc ~= closestNpc then
                    exports.origen_notify:DrawText('E', 'Robar')
                    lootingPromptNpc = closestNpc
                end

                if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38)
                    or IsControlJustPressed(0, 51) or IsDisabledControlJustPressed(0, 51) then
                    local lootData = npcTable[closestNpc]
                    if lootData and lootData.items then
                        exports.origen_notify:HideText()
                        lootingPromptNpc = nil
                        saquearNPC(lootData.items, closestNpc, lootData.npcId)
                    end
                end
            elseif lootingPromptNpc then
                exports.origen_notify:HideText()
                lootingPromptNpc = nil
            end
            Wait(_s)
        end
    end)
end

function SpawnEvilNPC(data, radius)
    if not data or type(data) ~= 'table' then return end
    local modelHash = GetHashKey(data.model)
    if IsModelInCdimage(modelHash) then
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(0)
        end

        local amount = tonumber(data.amount) or 1
        amount = math.max(1, math.min(amount, 20))
        local skinData = decodeSkinData(data.skin)
        local _, weaponHash = normalizeWeapon(data.weapon)
        local rewardItems = data.itemsreward
        if type(rewardItems) == 'string' and rewardItems ~= '' then
            local ok, decoded = pcall(json.decode, rewardItems)
            rewardItems = ok and decoded or {}
        end
        rewardItems = type(rewardItems) == 'table' and rewardItems or {}
        local originCoords = vector3(data.coords.x, data.coords.y, data.coords.z)

        for i = 1, amount do
            local coords = data.coords
            
            if i > 1 then
                coords = data.coords + vector4(math.random(-5, 5), math.random(-5, 5), 0, 0)
            end
            
            local npc = CreatePed(5, modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
            registerSpawnedNpc(data.id, npc)
            
            if next(rewardItems) then
                npcTable[npc] = {
                    netID = PedToNet(npc),
                    items = rewardItems,
                    npcId = data.id,
                }
                checkRewardItemsNPC()
            end
            
            SetNPCSkin(npc, skinData)

            if weaponHash then
                GiveWeaponToPed(npc, weaponHash, 250, false, true)
                SetCurrentPedWeapon(npc, weaponHash, true)
            end

            SetPedRelationshipGroupHash(npc, GetHashKey('EvilNPCs'))
            SetPedAsEnemy(npc, true)

            SetCanAttackFriendly(npc, false, false)

            radius = radius or 20.0

            TaskWanderInArea(npc, originCoords.x, originCoords.y, originCoords.z, radius, 2, 10.0)
            TaskCombatHatedTargetsAroundPed(npc, radius * 2.0, 0)

            RequestAnimSet('move_m@muscle@a')
            while not HasAnimSetLoaded('move_m@muscle@a') do
                Wait(0)
            end

            SetPedMovementClipset(npc, 'move_m@muscle@a', 1.0)

            SetPedCombatRange(npc, 0)
            SetPedAlertness(npc, 0)
            SetPedCombatAttributes(npc, 46, true)
            SetPedCombatAttributes(npc, 5, true)

            if data.respawn == 'distance' then
                SetEntityAsMissionEntity(npc, false, false)
            end
        end
        SetModelAsNoLongerNeeded(modelHash)
    else
        return
    end
end

---

function SpawnNPCs(npcs, locationCoords, spawnRadius)
    if not npcs then return end

    local function getSecureSpawn(coords)
        local pCoords = GetEntityCoords(PlayerPedId())
        local sCoords = nil
        local radius = spawnRadius
        while sCoords == nil do
            local spawnX = math.random(-radius, radius)
            local spawnY = math.random(-radius, radius)
            local spawnZ = coords.z
            local vec = vector3(coords.x + spawnX, coords.y + spawnY, spawnZ)
            if #(pCoords - vec) > radius then
                sCoords = vec
            end
        end

        local heading = math.deg(math.atan2(pCoords.y - sCoords.y, pCoords.x - sCoords.x))
        if heading < 0 then
            heading = heading + 360
        end
    
        local success, groundZ, normal = GetGroundZAndNormalFor_3dCoord(sCoords.x, sCoords.y, pCoords.z)
        sCoords = vector4(sCoords.x, sCoords.y, groundZ, heading)
        return sCoords
    end

    local nData = GetNPCsData(npcs)
    if nData then
        for i = 1, #nData do
            nData[i].coords = getSecureSpawn(locationCoords)
            SpawnEvilNPC(nData[i], spawnRadius)
        end
    end
end

function GetNPCsData(ids)
    local p = promise:new()
    QBCore.Functions.TriggerCallback('origen_quests:server:TryToSpawnNPCOnEvent', function(result)
        p:resolve(result)
    end, ids)
    return Citizen.Await(p)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if lootingPromptNpc then
        exports.origen_notify:HideText()
        lootingPromptNpc = nil
    end
    local toDelete = {}
    for npc, _ in pairs(trackedEvilNPCs) do
        toDelete[#toDelete + 1] = npc
    end
    for i = 1, #toDelete do
        local npc = toDelete[i]
        unregisterSpawnedNpc(npc)
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
        end
    end
    npcTable = {}
    trackedEvilNPCs = {}
    spawnedEvilNPCsById = {}
end)