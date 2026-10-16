local function GetCoordZ(x, y)
    local groundCheckHeights = { 48.0, 49.0, 50.0, 51.0, 52.0, 53.0, 54.0, 55.0, 56.0, 57.0, 58.0 }
    for i, height in ipairs(groundCheckHeights) do
        local foundGround, z = GetGroundZFor_3dCoord(x, y, height)
        if foundGround then
            return z
        end
    end
    return nil
end

local function getSafeSpawnPoint(coords)
    local radius, maxAttempts = 5.0, 400

    for _ = 1, maxAttempts do
        local spawnPoint = coords + vector3(math.random(-radius, radius), math.random(-radius, radius), 0)

        local zCoords = GetCoordZ(spawnPoint.x, spawnPoint.y)
        if zCoords and math.abs(zCoords - coords.z) <= 2 then
            if GetSafeCoordForPed(spawnPoint.x, spawnPoint.y, zCoords, true, 16) then
                return vector3(spawnPoint.x, spawnPoint.y, zCoords)
            end
        end
    end

    return coords
end

RegisterNetEvent('origen_boosting:cl:spawnGuards', function(gData)
    local player = PlayerPedId()

    activeMission.spawneds = {}

    for i = 1, gData.amount do
        local safeCoords = getSafeSpawnPoint(gData.coords.xyz)
        local model = Config.Guards.model[math.random(1, #Config.Guards.model)] 
        RequestModel(GetHashKey(model))
        while not HasModelLoaded(GetHashKey(model)) do
            Citizen.Wait(0)
        end
        local ped = CreatePed(4, GetHashKey(model), safeCoords.x, safeCoords.y, safeCoords.z, 0.0, true, true)

        GiveWeaponToPed(ped, GetHashKey(gData.weapon), 250, false, true)
        SetCanAttackFriendly(ped, false, true)
        TaskCombatPed(ped, player, 0, 16)
        SetPedCombatAttributes(ped, 46, true)
        SetPedCombatAttributes(ped, 0, false)
        SetPedCombatAbility(ped, 100)
        SetPedDropsWeaponsWhenDead(ped, false)
        SetPedAsCop(ped, true)
        AddRelationshipGroup("GUARDS")
        SetPedRelationshipGroupHash(ped, GetHashKey("GUARDS"))
        SetRelationshipBetweenGroups(5, GetHashKey("GUARDS"), `PLAYER`)
        SetRelationshipBetweenGroups(5, `PLAYER`, GetHashKey("GUARDS"))
        SetPedSuffersCriticalHits(ped, false)
        SetPedFleeAttributes(ped, 0, 0)
        SetPedKeepTask(ped, true)
        SetPedAccuracy(ped, Config.Guards.difficulties[gData.difficulty].accuracy)
        SetEntityMaxHealth(ped, Config.Guards.difficulties[gData.difficulty].health)
        SetEntityHealth(ped, Config.Guards.difficulties[gData.difficulty].health)
        SetPedArmour(ped, Config.Guards.difficulties[gData.difficulty].armor)

        table.insert(activeMission.spawneds, NetworkGetNetworkIdFromEntity(ped))
    end

    TriggerServerEvent('origen_boosting:sv:spawnedGuards', activeMission)
end)

RegisterNetEvent('origen_boosting:cl:friendlyGuards', function()
    for _, ped in ipairs(activeMission.spawneds) do
        ped = NetworkGetEntityFromNetworkId(ped)
        SetPedKeepTask(ped, false)
        SetPedAsCop(ped, false)
        ClearPedTasks(ped)
        ClearRelationshipBetweenGroups(5, GetHashKey("GUARDS"), `PLAYER`)
        TaskWanderStandard(ped, 10.0, 10)
    end
end)