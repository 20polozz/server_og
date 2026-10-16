local config = lib.loadJson('qbx_teleports.config')
local zones = {}
local destinations
local currentPassage -- Para guardar el pasaje actual y su contraseña

local function initTeleports()
    -- Limpiar estado anterior
    lib.hideTextUI()
    destinations = nil
    
    for _, zone in ipairs(zones) do
        zone:remove()
    end
    zones = {}
    
    if not config.passages or #config.passages == 0 then return end
    
    for _, passage in ipairs(config.passages) do
        if passage.enabled then
            for i = 1, #passage.points do
                local entrance = passage.points[i]
                local coords = vec3(entrance.coords[1], entrance.coords[2], entrance.coords[3])
                zones[#zones+1] = lib.zones.sphere({
                    coords = coords,
                    radius = 2,
                    onEnter = function ()
                        lib.showTextUI(entrance.drawText)
                        local others = {}
                        for j = 1, #passage.points do
                            if j ~= i then
                                table.insert(others, passage.points[j])
                            end
                        end
                        destinations = others
                        currentPassage = passage -- Guardamos el pasaje actual
                    end,
                    onExit = function ()
                        lib.hideTextUI()
                        destinations = nil
                        currentPassage = nil
                    end
                })
            end
        end
    end
end

RegisterNetEvent('qbx_teleports:client:reloadConfig', function(newConfig)
    config = newConfig
    initTeleports()
    SendNUIMessage({
        action = 'refresh',
        passages = config.passages
    })
end)

local function teleportTo(dest)
    -- Verificar contraseña si existe
    -- Al jugador solo le llega hasPassword; el admin tiene además la clave
    -- (password) para el panel.
    local conClave = currentPassage and (currentPassage.hasPassword or (currentPassage.password and currentPassage.password ~= ""))
    if conClave then
        local input = exports["org-input"]:ShowInput({
            header = 'ACCESO PROTEGIDO',
            submitText = 'ACEPTAR',
            icon = 'fa-solid fa-lock',
            inputs = {
                {
                    type = "password",
                    name = "pass",
                    text = "Introduce la contraseña",
                    isRequired = true
                }
            }
        })

        if not input then
            return
        end

        -- ORIGEN: la clave la comprueba el servidor (antes se comparaba aquí y
        -- además se imprimía en F8, a la vista de cualquiera).
        local ok = lib.callback.await('qbx_teleports:server:checkPassword', false, currentPassage.id, tostring(input.pass or ''))
        if not ok then
            lib.notify({type = 'error', description = 'Contraseña incorrecta'})
            return
        end
    end

    -- Fade out (fundido a negro)
    DoScreenFadeOut(500)
    
    -- Esperar a que termine el fade out
    while not IsScreenFadedOut() do
        Wait(0)
    end
    
    -- Pequeña pausa en negro
    Wait(100)
    
    local coords = vec(dest.coords)
    local coordZ = coords.z

    if not dest.ignoreGround then
        local isSafe, z = GetGroundZFor_3dCoord(
            coords.x,
            coords.y,
            coords.z,
            false
        )

        if isSafe then coordZ = z end
    end

    if dest.allowVehicle and cache.vehicle then
        SetPedCoordsKeepVehicle(
            cache.ped,
            coords.x,
            coords.y,
            coordZ
        )

        SetVehicleOnGroundProperly(cache.vehicle)
    else
        SetEntityCoords(
            cache.ped,
            coords.x,
            coords.y,
            coordZ,
            true, false, false, false
        )
    end

    if #dest.coords >= 4 then
        SetEntityHeading(cache.ped, dest.coords[4])
    end
    
    -- Pequeña pausa después del teleport
    Wait(100)
    
    -- Fade in (volver desde negro)
    DoScreenFadeIn(500)
end

CreateThread(function ()
    while true do
        local sleep = 1000
        if config.passages then
            local playerCoords = GetEntityCoords(cache.ped)
            for _, passage in ipairs(config.passages) do
                if passage.enabled then
                    for _, entrance in ipairs(passage.points) do
                        local coords = vec3(entrance.coords[1], entrance.coords[2], entrance.coords[3])
                        local dist = #(playerCoords - coords)
                        
                        if dist < 3.0 then
                            sleep = 0
                            DrawMarker(20, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 216, 27, 85, 255, false, true, 2, true, nil, nil, false)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

CreateThread(function ()
    -- Pedir configuración al servidor al iniciar
    lib.callback('qbx_teleports:server:getConfig', false, function(serverConfig)
        if serverConfig then
            config = serverConfig
            initTeleports()
        end
    end)
end)

local keybind

local function onPressed()
    keybind:disable(true)
    if destinations and #destinations > 0 then
        if #destinations == 1 then
            teleportTo(destinations[1])
        else
            local opciones = {
                {
                    header = "Ascensor",
                    icon = "fa-solid fa-elevator",
                    isMenuHeader = true,
                }
            }
            for _, dest in ipairs(destinations) do
                table.insert(opciones, {
                    header = dest._name or "Destino",
                    txt = "Presiona para teletransportarte",
                    icon = "fa-solid fa-location-dot",
                    params = {
                        isAction = true,
                        event = function()
                            teleportTo(dest)
                        end
                    }
                })
            end
            exports["org-menu"]:openMenu(opciones)
        end
    end
    keybind:disable(false)
end

keybind = lib.addKeybind({
    name = 'passage',
    description = 'Cruzar el pasadizo',
    defaultKey = 'E',
    secondaryMapper = 'PAD_DIGITALBUTTONANY',
    secondaryKey = 'LRIGHT_INDEX',
    onPressed = onPressed
})

-- Management (NUI Callbacks)
RegisterNUICallback('closeApp', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    exports['origen_admin']:ReturnToScripts()
    cb('ok')
end)

RegisterNUICallback('ready', function(data, cb)
    SendNUIMessage({
        action = 'refresh',
        passages = config.passages
    })
    cb('ok')
end)

RegisterNUICallback('getCurrentCoords', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({ coords = {coords.x, coords.y, coords.z, heading} })
end)

RegisterNUICallback('saveTeleport', function(data, cb)
    local pIdx = data.passageIndex
    local ptIdx = data.pointIndex
    local payload = data.data
    
    local finalPIdx = (pIdx ~= nil) and (pIdx + 1) or nil
    local finalPtIdx = (ptIdx ~= nil) and (ptIdx + 1) or nil
    
    TriggerServerEvent('qbx_teleports:server:saveTeleport', finalPIdx, finalPtIdx, payload)
    lib.notify({type = 'success', description = 'Configuración guardada'})
    cb('ok')
end)

RegisterNUICallback('deletePoint', function(data, cb)
    local pIdx = (data.pIdx ~= nil) and (data.pIdx + 1) or nil
    local ptIdx = (data.ptIdx ~= nil) and (data.ptIdx + 1) or nil
    
    if pIdx and ptIdx then
        TriggerServerEvent('qbx_teleports:server:deletePoint', pIdx, ptIdx)
        lib.notify({type = 'success', description = 'Punto eliminado'})
    end
    cb('ok')
end)

RegisterNUICallback('deletePassage', function(data, cb)
    local index = (data.index ~= nil) and (data.index + 1) or nil
    if index and config.passages[index] then
        TriggerServerEvent('qbx_teleports:server:deletePassage', index)
        lib.notify({type = 'success', description = 'Pasaje eliminado'})
    end
    cb('ok')
end)

RegisterNUICallback('updatePassageMetadata', function(data, cb)
    local index = (data.index ~= nil) and (data.index + 1) or nil
    if index and data.name then
        TriggerServerEvent('qbx_teleports:server:updatePassageMetadata', index, data)
        lib.notify({type = 'success', description = 'Configuración actualizada'})
    end
    cb('ok')
end)

RegisterNUICallback('togglePassage', function(data, cb)
    local index = (data.index ~= nil) and (data.index + 1) or nil
    if index then
        TriggerServerEvent('qbx_teleports:server:togglePassage', index)
    end
    cb('ok')
end)

-- Management Export
function openManagement()
    -- Solicitar configuración actualizada del servidor
    lib.callback('qbx_teleports:server:getConfig', false, function(freshConfig)
        if freshConfig then
            config = freshConfig
        end
        
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'show' })
        SendNUIMessage({
            action = 'refresh',
            passages = config.passages
        })
    end)
end

exports('openManagement', openManagement)
