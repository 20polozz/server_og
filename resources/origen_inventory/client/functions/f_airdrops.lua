local Thread = CreateThread
local HasNamedPtfxAssetLoaded = HasNamedPtfxAssetLoaded
local airdropConfig = Config.Airdrop
local Airdrop = {}

local teleportPlayerToOutsideBox = function(playerPed, coords)
    local offset = 2.0
    local angle = math.rad(math.random(0, 360))
    local newX = coords.x + math.cos(angle) * offset
    local newY = coords.y + math.sin(angle) * offset
    local newZ = coords.z

    SetEntityCoords(playerPed, newX, newY, newZ, false, false, false, true)
    debugger("[Airdrop] Teleported player to outside box at:", newX, newY, newZ)
end

Airdrop.smokeLoaded = false

Airdrop.loadSmoke = function()
    local smokeConfig = airdropConfig.Smoke
    local particleConfig = smokeConfig.particle

    if not smokeConfig.enable then return false end
    debugger("[Airdrops] Loading particle dictionary:", particleConfig.dict)

    Thread(function()
        RequestNamedPtfxAsset(particleConfig.dict)
        while not HasNamedPtfxAssetLoaded(particleConfig.dict) do
            Wait(5)
        end

        Airdrop.smokeLoaded = true
        debugger("[Airdrops] Particle dictionary loaded:", particleConfig.dict)
    end)

    return true
end

------------------------------------------------------
--- .............................................. ---
---                  Airdrop Smoke                 ---
--- .............................................. ---

--- Generate drop smoke on landing
--- @param coords vector3
--- @param smokeData? table
--- @return false | number
Airdrop.generateSmoke = function(coords, smokeData)
    local smokeConfig = airdropConfig.Smoke

    if not Airdrop.smokeLoaded then
        debugger("[Airdrops] Particle dictionary not loaded, cannot draw smoke.")
        return false
    end

    if not coords then
        debugger("[Airdrops] No coordinates provided for smoke effect.")
        return false
    end

    if not smokeConfig.enable then
        debugger("[Airdrops] Smoke effect is disabled in configuration.")
        return false
    end

    local smokeDict = smokeData and smokeData.particle?.dict or smokeConfig.particle.dict
    local smokeName = smokeData and smokeData.particle?.name or smokeConfig.particle.name
    local scale = smokeData and smokeData.scale or smokeConfig.scale or 1.0
    local color = smokeData and smokeData.color or smokeConfig.color or { r = 255, g = 0, b = 0 }

    UseParticleFxAssetNextCall(smokeDict)
    local particleHandle = StartParticleFxLoopedAtCoord(
        smokeName,
        coords.x, coords.y, coords.z + 2.5,
        0.0, 0.0, 0.0,
        scale,
        false, false, false, false
    )

    if particleHandle == 0 then
        debugger("[Airdrops] Failed to start particle effect:", smokeDict)
        return false
    end

    SetParticleFxLoopedScale(particleHandle, scale + 0.0)
    SetParticleFxLoopedColour(particleHandle, (color.r / 255) + 0.0, (color.g / 255) + 0.0, (color.b / 255) + 0.0, false)

    debugger("[Airdrops] Started smoke particle effect:", smokeDict, "at", coords)

    return particleHandle
end

--- Stop handle smoke
--- @param particleHandle number
--- @return boolean
Airdrop.stopSmoke = function(particleHandle)
    if not particleHandle or particleHandle == 0 then
        debugger("[Airdrops] Invalid particle handle for stopping smoke.")
        return false
    end

    StopParticleFxLooped(particleHandle, false)
    debugger("[Airdrops] Stopped smoke particle effect with handle:", particleHandle)
    return true
end

--- .............................................. ---
------------------------------------------------------

Airdrop.create = function(airdropData)

end

Airdrop.hasAccess = function(groups)
    if not groups or #groups == 0 then
        return true
    end

    for _, group in pairs(groups) do
        if group == 'all' then
            return true
        end
    end

    local jobData, gangData, _ = Bridge.GetPlayerInfo()
    local playerJob = jobData and jobData.name or nil
    local playerGang = gangData and gangData.name or nil

    for _, group in pairs(groups) do
        if playerJob and playerJob == group then
            return true
        end
        if playerGang and playerGang == group then
            return true
        end
    end
    
    if GetResourceState('origen_businesses') == 'started' then
        local pState = LocalPlayer.state
        local bizPermissions = pState and pState.permissions or {}
        for _, group in pairs(groups) do
            if bizPermissions[group] then
                return true
            end
        end
    end

    return false
end


---@diagnostic disable: missing-fields
-- Client Airdrops

local AirdropCrates = {}


local function removeAirdropCrate(stashId)
    local crateData = AirdropCrates[stashId]
    if not crateData then
        debugger('[Airdrops] Crate not found for removal:', stashId)
        return
    end

    debugger('[Airdrops] Removing airdrop crate:', stashId)

    -- Desactivar interacción primero
    if crateData.interactionActive ~= nil then
        crateData.interactionActive = false
    end

    -- Remove point first
    if crateData.point then
        crateData.point:remove()
        Wait(50)
    end

    -- Remove crate object
    if crateData.crate and DoesEntityExist(crateData.crate) then
        DeleteEntity(crateData.crate)
    end

    -- Remove blip
    if crateData.blip then
        OrigenMapa.Quitar(crateData.blip)
    end

    AirdropCrates[stashId] = nil
    debugger('[Airdrops] Airdrop crate removed successfully:', stashId)
end

local function spawnAirdropCrate(data)
    if not data or not data.location or not data.stashId then
        debugger('[Airdrops] Invalid airdrop data:', data)
        return
    end

    if not Airdrop.hasAccess(data.groups) then
        debugger('[Airdrops] Player does not have access to this airdrop')
        return
    end

    -- Si ya existe un airdrop con este ID, eliminarlo primero
    if AirdropCrates[data.stashId] then
        debugger('[Airdrops] Removing existing airdrop with same ID:', data.stashId)
        removeAirdropCrate(data.stashId)
        Wait(100)
    end

    local location = vec3(data.location.x, data.location.y, data.location.z)
    local propModel = data.propModel and data.propModel ~= '' and data.propModel or 'hei_prop_carrier_cargo_03a'
    local crateModel = GetHashKey(propModel)
    local stashId = data.stashId
    local label = data.label or 'Airdrop'

    RequestModel(crateModel)
    while not HasModelLoaded(crateModel) do
        Wait(100)
    end

    local crate = CreateObject(crateModel, location.x, location.y, location.z, false, false, false)
    PlaceObjectOnGroundProperly(crate)
    FreezeEntityPosition(crate, true)
    SetEntityAsMissionEntity(crate, true, true)

    -- Player Distance Check
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local distanceToCrate = #(playerCoords - location)
    if distanceToCrate < 3.0 then
        teleportPlayerToOutsideBox(playerPed, location)
    end

    --[[ La caja, en el mapa, si el ajuste lo pide.

         Ya no es un blip del juego: es un punto de origen_map. Va con
         prioridad alta —que es lo que antes decia SetBlipAsShortRange(false)—
         porque un airdrop se anuncia para toda la ciudad y no puede quedarse
         fuera del minimapa por estar lejos. ]]
    local blip = nil
    if data.markOnMap then
        blip = 'airdrop_' .. tostring(stashId)

        OrigenMapa.Poner(blip, {
            x = location.x, y = location.y, z = location.z,
            cat = 'eventos',
            icono = 'paquete',
            nombre = label,
            color = '#2ee6a8',
            prioridad = 10,
        })
    end

    -- Store crate data with interaction control
    AirdropCrates[stashId] = {
        crate = crate,
        blip = blip,
        location = location,
        stashId = stashId,
        label = label,
        interactionActive = true
    }

    -- Create interaction point
    local onZone = false

    local onKeyInteract = function()
        CreateThread(function()
            while onZone and DoesEntityExist(crate) and AirdropCrates[stashId] and AirdropCrates[stashId].interactionActive do
                Wait(0)
                if IsControlJustReleased(0, 38) then
                    debugger('[Airdrops] Opening airdrop:', stashId)
                    -- Open stash
                    Inventory.open('stash', stashId, {
                        label = label,
                        slots = 20,
                        maxweight = 50000,
                    })
                    Wait(100)
                end
            end
        end)
    end

    local markerProperties = {
        size = vector3(0.3, 0.3, 0.3),
        color = vector4(216, 27, 85, 200), -- Rosa de la pegatina
    }

    local drawMarker = function(loc)
        ---@diagnostic disable-next-line: param-type-mismatch, trailing-space, missing-parameter
        DrawMarker(20,
            loc.x,
            loc.y,
            loc.z + 1.0,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            markerProperties.size.x, markerProperties.size.y, markerProperties.size.z,
            markerProperties.color.x, markerProperties.color.y, markerProperties.color.z,
            markerProperties.color.w,
            false, false, 0, true
        )
    end

    local cratePoint = Points.new({
        id = stashId,
        coords = location,
        radius = 1.5,
        label = label,
        type = 'airdrop',
        distance = 3.0,
        onEnter = function()
            onZone = true
            onKeyInteract()
            Sprite.loadDict()
            Sprite.update('lucide:package')
        end,
        onExit = function()
            onZone = false
            Sprite.unload()
        end,
        nearby = function()
            if DoesEntityExist(crate) then
                drawMarker(location)
                Sprite.draw(location + vec3(0, 0, 1.5))

                if AirdropCrates[stashId].smoke then
                    Airdrop.stopSmoke(AirdropCrates[stashId].smoke)
                    AirdropCrates[stashId].smoke = nil
                end
            end
        end
    })

    AirdropCrates[stashId].point = cratePoint
    AirdropCrates[stashId].smoke = Airdrop.generateSmoke(location)

    debugger('[Airdrops] Spawned airdrop crate:', stashId, 'at', location)
end

local function notifyAirdrop(data)
    if not data or not data.label then return end

    if not Airdrop.hasAccess(data.groups) then
        return
    end

    -- Un solo aviso (antes eran dos y otro por el chat).
    Bridge.Notify(string.format('Ha caído un airdrop: %s. ¡Búscalo!', data.label), 'info', 7000)
end

-- Event Handlers
RegisterNetEvent('origen_inventory:client:spawnAirdropCrate', function(data)
    spawnAirdropCrate(data)
end)

RegisterNetEvent('origen_inventory:client:removeAirdropCrate', function(stashId)
    removeAirdropCrate(stashId)
end)

RegisterNetEvent('origen_inventory:client:notifyAirdrop', function(data)
    notifyAirdrop(data)
end)


Thread(function()
    Wait(200)
    Inventory.__Internal_AddTask('onResourceStop', function(resourceName)
        if GetCurrentResourceName() ~= resourceName then return end

        for stashId, _ in pairs(AirdropCrates) do
            removeAirdropCrate(stashId)
        end
    end)
end)


Airdrop.loadSmoke()
