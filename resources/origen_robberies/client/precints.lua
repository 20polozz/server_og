-- ┌─────────────────────────────────────────────────────────────────────────┐
-- │  origen_robberies — Polyzones de Comisarías                             │
-- │  Si un jugador con un atraco activo entra en una comisaría,             │
-- │  el atraco se marca como FALLIDO (sin XP).                              │
-- └─────────────────────────────────────────────────────────────────────────┘

local _precintZones = {}

local function onPlayerCaptured(label)
    local robberyId = LocalPlayer.state.activeRobbery
    if not robberyId then return end

    local robbery = Robberies.get(robberyId)
    if not robbery then
        LocalPlayer.state:set('activeRobbery', nil, true)
        return
    end

    -- Notificar al jugador
    lib.notify({
        title   = 'Atracos',
        description = string.format('Has sido detenido en %s. El atraco ha fallado.', label),
        type    = 'error',
        duration = 8000
    })

    -- Marcar como fallido en el servidor
    TriggerServerEvent('origen_robberies:updateStats', robberyId, 'failed')

    -- Se comenta la remoción de ítems para que el jugador conserve el botín aunque falle al entrar en comisaría.
    -- if robbery.robbedItems and #robbery.robbedItems > 0 then
    --     local robCoords = { x = robbery.start.coords.x, y = robbery.start.coords.y, z = robbery.start.coords.z }
    --     local robRadius = robbery.safeZoneRadius or ((robbery.radius or 30.0) + 15.0)
    --     TriggerServerEvent('origen_robberies:stripRobbedItems', robberyId, robCoords, robRadius)
    -- end

    -- Limpiar estado del cliente
    robbery.robberyActive = false

    if robbery.escape and robbery.escape.active then
        robbery:removeEscape()
    end

    for _, point in pairs(robbery.interactions or {}) do
        pcall(function() point:remove() end)
    end

    if robbery.bag and DoesEntityExist(robbery.bag) then
        DeleteEntity(robbery.bag)
    end

    LocalPlayer.state:set('activeRobbery', nil, true)
end

local function UpdatePrecinctZones(precincts)
    -- Limpiar zonas antiguas
    for _, zone in ipairs(_precintZones) do
        pcall(function() zone:remove() end)
    end
    _precintZones = {}

    if not precincts then return end

    for _, precinct in ipairs(precincts) do
        if precinct.points and #precinct.points > 0 then
            local pts = {}
            for _, pt in ipairs(precinct.points) do
                table.insert(pts, vector3(pt.x, pt.y, pt.z))
            end

            local zone = lib.zones.poly({
                points = pts,
                thickness = precinct.thickness or 50.0,
                debug = false,
                onEnter = function()
                    -- Solo actuar si hay un atraco activo
                    if LocalPlayer.state.activeRobbery then
                        onPlayerCaptured(precinct.label)
                    end
                end
            })
            table.insert(_precintZones, zone)
        end
    end
end

local function initPoliceZones()
    -- Cargar comisarías en el inicio
    lib.callback('origen_robberies:getPrecincts', false, function(precincts)
        UpdatePrecinctZones(precincts)
    end)
end

-- Escuchar evento de actualización del servidor
RegisterNetEvent('origen_robberies:client:updatePrecincts', function(precincts)
    UpdatePrecinctZones(precincts)
end)

-- Inicializar cuando el recurso arranca
Citizen.CreateThread(function()
    Citizen.Wait(1000)
    initPoliceZones()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, zone in ipairs(_precintZones) do
            pcall(function() zone:remove() end)
        end
        _precintZones = {}
    end
end)
