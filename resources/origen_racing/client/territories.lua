-- ========================================
-- ORIGEN RACING - TERRITORIOS CLIENTE
-- ========================================

local territories = {}
local territoryBlips = {}
local territoryZones = {}
local isInTerritory = false
local currentTerritory = nil

-- ========================================
-- FUNCIONES
-- ========================================

--[[ Aqui vivian dos ayudantes que ya no hacen falta: uno que partia un
     #RRGGBB en tres numeros y otro que buscaba a cual de los treinta colores
     de blip de GTA se parecia mas.

     Los dos existian por la misma razon: un blip no admite un color, admite un
     numero de una lista corta, asi que el color que una crew habia elegido
     habia que redondearlo al mas parecido. En el mapa de origen_map el color
     viaja en hexadecimal y llega tal cual, asi que el redondeo sobra. ]]

local function CreateTerritoryBlip(territory)
    -- Eliminar blip existente
    if territoryBlips[territory.id] then
        OrigenMapa.Quitar(territoryBlips[territory.id])
        territoryBlips[territory.id] = nil
    end

    --[[ LOS TERRITORIOS YA NO SALEN EN EL MAPA (14/09/2026).

         Se ponian los 75 para todo el servidor nada mas entrar, y con la
         bandera de «Carreras» el mapa se llenaba de carreras que no existian.
         Lo que el usuario quiere ver en el mapa es una carrera LANZADA, y solo
         quien lleva la tablet: eso lo hace CreateCircuitBlips en main.lua.

         Los territorios siguen existiendo —se disputan, se conquistan, se ven
         en el Racing Hub—; solo dejan de pintarse aqui. Lo de arriba (quitar
         el punto que hubiera) se queda, para que un reinicio con el codigo
         viejo cargado no deje ninguno colgado. El pintado (un punto de
         origen_map con el color de la crew duena) esta en el git si se quiere
         volver a poner. ]]
end

local function NormalizeTerritoryStatus(territory)
    if not territory then return territory end
    -- FIX LÓGICA: NO sobreescribir 'contested' en el cliente.
    -- El servidor es la fuente de verdad; si dice 'contested' hay una carrera activa.
    -- Sobrescribirlo a 'protected' ocultaba disputas reales al jugador y al mapa.
    -- La limpieza del estado la realiza el servidor al finalizar FinishTerritoryContest.
    return territory
end

local function HasValidCrew()
    local crewId = tonumber(LocalPlayer.state.crew_id)
    return crewId and crewId > 0
end

local function ClearTerritoryBlips()
    for id, blip in pairs(territoryBlips) do
                    OrigenMapa.Quitar(blip)
    end
    territoryBlips = {}
end

local function LoadTerritories()
    lib.callback('racing:territories:getAll', false, function(response)
        if response.success then
            territories = response.territories
            
            -- Limpiar blips existentes
            ClearTerritoryBlips()
            
            -- Crear blips para cada territorio
            for i = 1, #territories do
                CreateTerritoryBlip(territories[i])
            end
        end
    end)
end

local function IsPlayerInZone(coords, polygon)
    if not polygon or #polygon < 3 then return false end
    
    local x, y = coords.x, coords.y
    local inside = false
    
    local j = #polygon
    for i = 1, #polygon do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y
        
        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end
    
    return inside
end

-- ========================================
-- THREAD DE DETECCIÓN DE ZONA
-- ========================================

CreateThread(function()
    while true do
        Wait(1000)
        
        if #territories > 0 then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local wasInTerritory = isInTerritory
            local oldTerritory = currentTerritory
            
            isInTerritory = false
            currentTerritory = nil
            
            -- Verificar si está en algún territorio
            for i = 1, #territories do
                local territory = territories[i]
                if territory.zone_polygon then
                    if IsPlayerInZone(playerCoords, territory.zone_polygon) then
                        isInTerritory = true
                        currentTerritory = territory
                        break
                    end
                end
            end
            
            if isInTerritory and not wasInTerritory then
                SendNUIMessage({ action = 'territoryEntered', data = currentTerritory })

                -- Notificación sutil al entrar
                local ownerText = currentTerritory.owner_name
                    and ('Controlado por ' .. currentTerritory.owner_name)
                    or 'Libre — ¡sin dueño!'
                local notiType = currentTerritory.status == 'free' and 'success'
                             or currentTerritory.status == 'contested' and 'warning'
                             or 'info'

                if exports.origen_inventory:HasItem('tablet_racing') or exports.origen_inventory:HasItem('tablet_racingfull') then
                    lib.notify({
                        title = currentTerritory.name or 'Territorio',
                        description = ownerText,
                        type = notiType,
                        duration = 5000
                    })
                end
            elseif not isInTerritory and wasInTerritory then
                SendNUIMessage({ action = 'territoryExited' })
            end
        end
    end
end)

-- ========================================
-- THREAD DE MARCADORES
-- ========================================

-- DESHABILITADO - El texto de territorio se mostrará solo en el HUD, no aquí
-- CreateThread(function()
--     while true do
--         Wait(1000)
--     end
-- end)

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('racing:territories:updated', function(territory)
    -- Asegurar que zone_polygon esté decodificado (puede llegar como string JSON)
    if territory.zone_polygon and type(territory.zone_polygon) == 'string' then
        local ok, decoded = pcall(json.decode, territory.zone_polygon)
        if ok then territory.zone_polygon = decoded end
    end

    territory = NormalizeTerritoryStatus(territory)

    local found = false
    for i = 1, #territories do
        if territories[i].id == territory.id then
            -- Fusionar datos: preservar campos del territorio local que no vengan en el update parcial
            local existing = territories[i]
            for k, v in pairs(territory) do
                existing[k] = v
            end
            existing = NormalizeTerritoryStatus(existing)
            territories[i] = existing
            CreateTerritoryBlip(territories[i])
            found = true
            break
        end
    end
    -- Si el territorio no existe en la lista local (creado en runtime), añadirlo
    if not found then
        table.insert(territories, territory)
        CreateTerritoryBlip(territory)
    end

    SendNUIMessage({ action = 'territoriesUpdated' })
end)

RegisterNetEvent('racing:territories:contestStarted', function(data)
    if not HasValidCrew() then return end

    lib.notify({
        title = 'Disputa de Territorio',
        description = data.challenger.name .. ' [' .. data.challenger.tag .. '] desafía por ' .. data.territory.name,
        type = 'warning',
        duration = 10000
    })
    
    -- Actualizar territorio local
    for i = 1, #territories do
        if territories[i].id == data.territory.id then
            territories[i] = data.territory
            CreateTerritoryBlip(data.territory)
            break
        end
    end
end)

RegisterNetEvent('racing:territories:conquered', function(data)
    -- Solo notificar a jugadores que pertenecen a alguna crew
    if HasValidCrew() then
        local myCrewId = tonumber(LocalPlayer.state.crew_id)
        local ownerCrewId = data and data.territory and tonumber(data.territory.owner_crew_id) or nil
        local isWinnerCrew = myCrewId and ownerCrewId and myCrewId == ownerCrewId
        local description = data.winner.name .. ' [' .. data.winner.tag .. '] conquistó ' .. data.territory.name
        if isWinnerCrew then
            description = '¡ENHORABUENA! El territorio "' .. data.territory.name .. '" ahora pertenece a tu crew'
        end

        lib.notify({
            title = 'Territorio Conquistado',
            description = description,
            type = 'success',
            duration = 10000
        })
        -- Forzar refresh de territorios y crew en el NUI (solo si tiene crew abierto)
        SendNUIMessage({ action = 'territoriesUpdated' })
    end

    -- Actualizar blip local (aplica a todos)
    -- Forzar status correcto: un territorio recién conquistado NUNCA puede quedar en 'contested'
    if data.territory then
        if data.territory.status == 'contested' then
            data.territory.status = 'protected'
        end
        -- Si el territorio tiene dueño pero no tiene color asignado, usar el color del ganador
        if data.territory.owner_crew_id and not data.territory.owner_color then
            data.territory.owner_color = data.winner and data.winner.color or '#888888'
        end
    end

    data.territory = NormalizeTerritoryStatus(data.territory)

    for i = 1, #territories do
        if territories[i].id == data.territory.id then
            territories[i] = data.territory
            CreateTerritoryBlip(data.territory)
            break
        end
    end
end)

RegisterNetEvent('racing:territories:created', function(territory)
    table.insert(territories, territory)
    CreateTerritoryBlip(territory)
    -- Solo notificar a admins/crews, no a todo el servidor
    if HasValidCrew() then
        lib.notify({
            title = 'Nuevo Territorio',
            description = territory.name .. ' ha sido creado',
            type = 'info',
            duration = 5000
        })
    end
end)

RegisterNetEvent('racing:territories:deleted', function(territoryId)
    -- Eliminar de la lista local
    for i = #territories, 1, -1 do
        if territories[i].id == territoryId then
            -- Eliminar blip y zona
            if territoryBlips[territoryId] then
                OrigenMapa.Quitar(territoryBlips[territoryId])
                territoryBlips[territoryId] = nil
            end
            if territoryZones[territoryId] then
                territoryZones[territoryId] = nil
            end
            
            table.remove(territories, i)
            break
        end
    end
    -- No notificar a jugadores sin crew (acción de admin)
end)

-- ¡Tu territorio está siendo atacado! (solo para la crew dueña)
RegisterNetEvent('racing:territories:underAttack', function(data)
    -- No depender del state bag local aquí:
    -- el servidor ya filtra este evento solo a miembros de crew.
    -- Así evitamos falsos negativos cuando crew_id aún no sincronizó en cliente.

    local territory = data.territory
    if not territory then return end

    lib.notify({
        title = 'TERRITORIO BAJO ATAQUE',
        description = string.format(
            '**%s** está siendo disputado\n' ..
            'Tienes **%d min** para inscribirte\n' ..
            'Busca el marker de la carrera y defiéndelo',
            territory.name,
            data.timeRemaining or 2
        ),
        type = 'error',
        duration = 20000,
        position = 'top'
    })

    -- Sonido de alerta
    PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', 1)

    -- Actualizar territorio local
    for i = 1, #territories do
        if territories[i].id == territory.id then
            territories[i] = territory
            CreateTerritoryBlip(territory)
            break
        end
    end
end)

RegisterNetEvent('racing:territories:scheduledContest', function(data)
    -- Igual que underAttack: filtrado por servidor, no por estado local del cliente.
    -- Permite notificar siempre a la crew aunque no cumpla prerrequisitos (se valida al unirse).

    local territory = data.territory
    local timeRemaining = data.timeRemaining or 2
    
    -- Solo mostrar notificación
    -- El marker y blip los crea automáticamente el sistema de carreras (client/main.lua)
    lib.notify({
        title = 'DISPUTA DE TERRITORIO',
        description = string.format(
            '**%s**\n' ..
            'Tiempo: **%d min** | Entrada: $%s\n' ..
            'Premio: $%s + %s REP\n' ..
            'Busca el marker en el punto de inicio de la carrera',
            territory.name,
            timeRemaining,
            territory.buy_in or 0,
            territory.reward_money or 0,
            territory.reward_reputation or 0
        ),
        type = 'warning',
        duration = 15000,
        position = 'top'
    })
    
    -- Actualizar territorio local
    for i = 1, #territories do
        if territories[i].id == territory.id then
            territories[i] = territory
            CreateTerritoryBlip(territory)
            break
        end
    end
end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    -- Jitter para distribuir la carga de queries al reiniciar
    local jitter = (GetPlayerServerId(PlayerId()) % 20) * 150  -- 0-2850ms
    Wait(2000 + jitter)
    LoadTerritories()
end)

