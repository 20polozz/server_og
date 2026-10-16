---@diagnostic disable: missing-parameter, cast-local-type
QBCore = exports['qb-core']:GetCoreObject()


local Config = lib.require('shared.config')
-- local xSound = exports.xsound -- Recurso no disponible

local Peds = {}
local ZonePoints = {}
local Blips = {}

local soundUrl = "https://cfx-nui-origen_fishing/sounds/"
local IsGameStarted = false

local isFishing = false
local zoneName = false
local fishingObj = false

local timeLeft = 0
local fishCollected = 0

local tournament = false


local function hasWaterInFront()
    -- No permitir pescar desde vehículos
    if IsPedInAnyVehicle(cache.ped, true) then
        return false
    end
    
    -- Permitir pescar si está nadando O si está cerca del agua
    if IsPedSwimming(cache.ped) then
        return true
    end

    -- Revisar si hay agua o si el ped esta en el agua
    if IsEntityInWater(cache.ped) then
        return true
    end

    local pedCoords = GetEntityCoords(cache.ped)
    local forwardVector = GetEntityForwardVector(cache.ped)
    local checkCoords = pedCoords + (forwardVector * 3.0)

    local waterHeight, z = GetWaterHeight(checkCoords.x, checkCoords.y, checkCoords.z)
    
    return waterHeight
end

local function canFishing()
    return not isFishing and hasWaterInFront()
end

lib.callback.register('origen_fishing:canFishing', function()
    local can = canFishing()
    -- Only return zoneName if we are in a zone and can fish
    return can, zoneName
end)

local function createRodObject()
    local model = `prop_fishing_rod_01`

    lib.requestModel(model)

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, false, false)
    local boneIndex = GetPedBoneIndex(cache.ped, 18905)

    AttachEntityToEntity(object, cache.ped, boneIndex, 0.1, 0.05, 0.0, 70.0, 120.0, 160.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(model)

    return object
end



local playerStats = {}

local sendStatsToNui = function()
    SendNUIMessage({
        action = 'updateStats',
        stats = playerStats
    })
end

RegisterNetEvent('origen_fishing:client:updateStats', function(stats)
    if not stats then return end
    playerStats = stats
    sendStatsToNui()
end)

--[[ La tarjeta de «Pesca activa» cae en el mismo canto derecho que el
     rastreador de misiones de origen_quests, y se pintaban una encima de otra.
     Mientras la nuestra esta a la vista, el rastreador se aparta; cuando se va
     —al salir de la zona o al parar la partida—, vuelve solo.

     Evento LOCAL cross-recurso: lo escucha origen_quests con bandera propia. ]]
local function toggleFishing(state)
    TriggerEvent('origen_fishing:pescando', state == true)

    if state then
        -- Obtener estadísticas del jugador al abrir el HUD
        lib.callback('origen_fishing:getPlayerStats', false, function(stats)
            if stats then
                playerStats = stats
                sendStatsToNui()
            end
        end)
    end

    SendNUIMessage({
        action = 'toggleFishing',
        state = state,
        stats = playerStats
    })
end

local function sendLeaderboardToNui(board)
    SendNUIMessage({
        action = 'updateLeaderboard',
        board = board or false
    })
end

local function updateFishing(data)
    -- Agregar stats a la actualización
    data.stats = playerStats
    
    SendNUIMessage({
        action = 'updateFishing',
        data = data
    })
end

local scaleSubText = vec2(0.4, 0.4)
local colorText = vec4(255, 255, 255, 255)

local menuOpen = false

local createFishZones = function()
    local gameZones = Config.GameZone.zones

    for _, zone in pairs(gameZones) do
        if not zone then goto continue end

        local function inside(self)
            if self.inZone and menuOpen then
                -- Solo actualizar la información del NUI mientras está en la zona
                updateFishing({
                    fishes = fishCollected,
                    time = Utils.SecondsToClock(timeLeft),
                    tournament = tournament
                })
            end
            Wait(100)  -- Reducir carga de CPU
        end

        local function onEnter(self)
            self.inZone = true
            zoneName = self.name
            toggleFishing(true)
            menuOpen = true
            timeLeft = 0  -- Inicializar en 0
            CreateThread(function()
                local tick = 0
                local every = Config.Tournament.leaderboardInterval or 3

                while self.inZone do
                    timeLeft += 1  -- Contar hacia arriba

                    tick += 1
                    if tick >= every then
                        tick = 0
                        sendLeaderboardToNui(lib.callback.await('origen_fishing:GetLeaderboard', false))
                    end

                    Wait(1000)
                end
            end)
        end

        local function onExit(self)
            self.inZone = false
            zoneName = false
            toggleFishing(false)
            menuOpen = false
            sendLeaderboardToNui(false)
        end

        zone.debug = Config.Debug
        zone.inZone = false
        zone.isGameZone = false
        zone.inside = inside
        zone.onEnter = onEnter
        zone.onExit = onExit

        ZonePoints[zone.name] = lib.zones.poly(zone)

        ::continue::
    end
end

--[[ Los sitios de pesca, en el mapa.

     Ya no son blips del juego: se registran como puntos en origen_map y de ahi
     los leen los tres mapas del servidor.

     Antes una zona y un punto eran dos tipos de blip distintos —de radio y de
     coordenada— y habia que elegir. Aqui es el mismo punto: el que lleva
     `radio` se pinta como circulo y el que no, como chincheta. ]]
local CreateBlip = function(id, position, data)
    local clave = 'pesca_' .. tostring(id)

    OrigenMapa.Poner(clave, {
        x = position.x, y = position.y, z = position.z,
        cat = 'activities',
        icono = 'pesca',
        nombre = data.name,
        radio = (data.type == 'area') and 200.0 or nil,
    })

    Blips[id] = clave
end

local StartGameThread = function()
    if IsGameStarted then 
        return lib.notify({
            title = 'Pesca',
            description = 'Ya has iniciado esta actividad.',
            type = 'error'
        })
    end
    IsGameStarted = true

    timeLeft = 3600
    fishCollected = 0

    -- xSound:PlayUrl('fish_start_mission', ('%s%s'):format(soundUrl, 'mission_start.mp3'), 0.3, false) -- xsound no disponible
    Utils.DisplaySplashText(true, 'Actividad iniciada', '¡Vamos a la pesca!', 5, true)


    CreateThread(function()
        -- Utils.ShowNotification('Hemos dejado los puntos marcados en tu mapa, ve y consigue peces en el menor tiempo posible.', 'success', 8000)
        Wait(3000)
        Utils.ShowNotification('Luego, elige si vender o quedarte con los peces. ¡Suerte!', 'success', 8000)
        Wait(3000)
        -- Utils.ShowNotification('Dirígete a la zona de pesca marcada en tu mapa.', 'success', 8000)
    end)

    ---- Create Game Zone Point
    local gameZone = Config.GameZone
    local gameCoordsZone = gameZone.coords
    local rnd = math.random(75, 150)
    -- Randomize + or - random position 
    gameCoordsZone = vector3(gameCoordsZone.x + math.random(-rnd, rnd), gameCoordsZone.y + math.random(-rnd, rnd), gameCoordsZone.z)

    -- CreateBlip('gameZone', gameCoordsZone, {
    --     name = 'Zona de pesca',
    --     radius = gameZone.radius,
    --     color = 3,
    --     type = 'area'
    -- })

    -- Las zonas ya están creadas al inicio del recurso, no es necesario crearlas de nuevo

    local hasTournament = lib.callback.await('origen_fishing:GetTournament', false)
    local nextCheck = GetGameTimer() + (1000 * 10)

    if hasTournament and hasTournament.started then
        tournament = hasTournament
    end 

    CreateThread(function() 
        while IsGameStarted do
            if not hasTournament or not tournament or not tournament.started then
                if GetGameTimer() > nextCheck then
                    nextCheck = GetGameTimer() + (1000 * 10)
                    tournament = lib.callback.await('origen_fishing:GetTournament', false)
                end
            else
                tournament.timeLeft = tournament.timeLeft - 1
            end

            Wait(1000)
        end
    end)
end


-- RegisterCommand('sg', function()
--     StartGameThread()
-- end,false)

local function StopGame()
    IsGameStarted = false

    if Blips['gameZone'] then
        OrigenMapa.Quitar(Blips['gameZone'])
        Blips['gameZone'] = nil
    end

    -- Ocultar el HUD de pesca y limpiar estado
    toggleFishing(false)
    menuOpen = false
    fishCollected = 0
    timeLeft = 0
    tournament = false

    -- xSound:PlayUrl('fish_stop_mission', ('%s%s'):format(soundUrl, 'mission_cancel.mp3'), 0.3, false) -- xsound no disponible
    Utils.ShowNotification('Has cancelado la actividad.', 'error')
end

local OpenConfirmMenu = function()
    exports['org-menu']:openMenu({
        {
            header = "Pesca | Confirmación",
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = "",
            txt = "¿Estás seguro de que quieres ir a pescar?",
            icon = 'fa-solid fa-info',
        },
        {
            header = "Confirmar",
            txt = "Sí, quiero ir a pescar",
            icon = 'fa-solid fa-check',
            params = {
                handler = function()
                    StartGameThread()
                end
            }
        },
        {
            header = "Cancelar",
            txt = "No, me he arrepentido",
            icon = 'fa-solid fa-times',
        },
    })
end

local OpenInfoMenu = function()
    exports['org-menu']:openMenu({
        {
            header = "Pesca | Información",
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = "",
            txt = "Se te asignará una zona para ir a pescar, consigue la mayor cantidad de peces en el menor tiempo posible.",
            icon = 'fa-solid fa-info',
        },
    })
end

local modeBrief = function(mode, target)
    if not mode then return 'Suma puntos por cada pieza.' end

    if mode.id == 'volume' then
        return 'Gana quien saque más piezas, sin importar cuáles.'
    elseif mode.id == 'biggest' then
        return 'Gana la pieza más pesada del torneo.'
    elseif mode.id == 'species' then
        return ('Solo cuentan las capturas de %s.'):format(target or 'la especie objetivo')
    end

    return 'Suma puntos por cada pieza. Las raras valen más.'
end

local formatScore = function(score, mode)
    local unit = mode and mode.unit or 'pts'

    if unit == 'kg' then
        return ('%.2f kg'):format(score or 0)
    end

    return ('%d %s'):format(score or 0, unit)
end

local PODIO = { 'fa-solid fa-trophy', 'fa-solid fa-medal', 'fa-solid fa-award' }

local OpenTournamentMenu = function()
    local board = lib.callback.await('origen_fishing:GetLeaderboard', false)

    local elements = {
        {
            header = "Pesca | Torneo",
            isMenuHeader = true,
        }
    }

    if not board or not board.active then
        local faltan = board and board.nextIn or 0
        local comeTxt = faltan > 0 and ('Vuelve en %s'):format(Utils.SecondsToClock(faltan))
            or 'Iniciando evento...'

        table.insert(elements, {
            header = "Torneo no activo",
            txt = ('%s\nDuran %d minutos y se abren cada %d horas.'):format(
                comeTxt,
                math.floor(Config.Tournament.duration / 60),
                Config.Tournament.intervalHours),
            icon = 'fa-solid fa-hourglass-half',
        })

        exports['org-menu']:openMenu(elements)
        return
    end

    local mode = board.mode

    table.insert(elements, {
        header = ('Torneo activo: %s'):format(mode and mode.label or 'Puntuación'),
        txt = ('%s\nFinaliza en: %s'):format(
            modeBrief(mode, board.target), Utils.SecondsToClock(board.timeLeft or 0)),
        icon = 'fa-solid fa-trophy',
    })

    if board.top and #board.top > 0 then
        for _, row in ipairs(board.top) do
            table.insert(elements, {
                header = ('%d. %s'):format(row.position, row.isYou and 'Tú' or row.name),
                txt = formatScore(row.points, mode),
                icon = PODIO[row.position] or 'fa-solid fa-fish',
            })
        end
    else
        table.insert(elements, {
            header = "Todavía no pescó nadie",
            txt = "Sé el primero en marcar.",
            icon = 'fa-solid fa-fish',
        })
    end

    -- Solo si no aparece ya en el podio de arriba.
    local enPodio = false
    for _, row in ipairs(board.top or {}) do
        if row.isYou then
            enPodio = true
            break
        end
    end

    if board.you and not enPodio then
        table.insert(elements, {
            header = ('Tu posición: %d de %d'):format(board.you.position, board.total or 0),
            txt = formatScore(board.you.points, mode),
            icon = 'fa-solid fa-user',
        })
    end

    if board.biggest then
        table.insert(elements, {
            header = "Pieza mayor",
            txt = ('%s de %.2f kg\n%s'):format(
                board.biggest.fish, board.biggest.weight or 0, board.biggest.name),
            icon = 'fa-solid fa-fish-fins',
        })
    end

    exports['org-menu']:openMenu(elements)
end

local OpenFishingMenu = function()

    if IsGameStarted then
        exports['org-menu']:openMenu({
            {
                header = "Florindo | Pescador",
                isMenuHeader = true, -- Set to true to make a nonclickable title
            },
            {
                header = "",
                txt = "¿Estás seguro de cancelar la actividad?",
                icon = 'fa-solid fa-info',
            },
            {
                header = "Confirmar",
                txt = "Sí, quiero cancelar",
                icon = 'fa-solid fa-check',
                params = {
                    handler = function()
                        StopGame()
                    end
                }
            },
            {
                header = "Cancelar",
                txt = "No, me he arrepentido",
                icon = 'fa-solid fa-times',
            },
        })
        
        return
    end

    exports['org-menu']:openMenu({
        {
            header = "Florindo | Pescador",
            isMenuHeader = true, -- Set to true to make a nonclickable title
        },
        {
            header = "Información",
            txt = "¿De que va esto?",
            icon = 'fa-solid fa-info',
            params = {
                handler = function()
                    OpenInfoMenu()
                end
            }
        },
        {
            header = "Trabajar",
            txt = "Quiero ir a pescar",
            icon = 'fa-solid fa-fish',
            params = {
                handler = function()
                    OpenConfirmMenu()
                end
            }
        },
        {
            header = "Lonja",
            txt = "Vender la pesca y comprar aparejos",
            icon = 'fa-solid fa-scale-balanced',
            params = {
                handler = function()
                    AbrirLonja()
                end
            }
        },
        {
            header = "Torneo",
            txt = "¿Quien ha pescado más?",
            icon = 'fa-solid fa-trophy',
            params = {
                handler = function()
                    OpenTournamentMenu()
                end
            }
        },
    })
end

local DestroyNPC = function(id)
    local ped = Peds[id]

    if DoesEntityExist(ped) then
        SetEntityAsNoLongerNeeded(ped)
        DeleteEntity(ped)
    end

    Peds[id] = nil
end

local CreateNPC = function(id, data)
    local pedModel = data.model
    local pedCoord = data.position

    if not IsModelInCdimage(pedModel) or not IsModelValid(pedModel) then
        return
    end

    --[[ El NPC, solo con alguien cerca. Antes se creaba al arrancar y se
         hacia invisible al alejarte: invisible, pero seguia ocupando sitio en
         el pool de peds de GTA (256 para todo el servidor). Ahora se crea al
         entrar en el punto y se borra al salir. ]]
    local function crearPed()
        lib.requestModel(pedModel)

        local ped = CreatePed(4, pedModel, pedCoord.x, pedCoord.y, pedCoord.z, pedCoord.w, false, false)

        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedRandomComponentVariation(ped, 0)
        SetModelAsNoLongerNeeded(pedModel)

        Peds[id] = ped

        if data.scenario then
            TaskStartScenarioInPlace(ped, data.scenario, 0, true)
        end
    end

    -- Sistema de interacción con lib.points
    local point = lib.points.new({
        coords = vec3(pedCoord.x, pedCoord.y, pedCoord.z),
        distance = 50,
        menuType = data.menu,
        npcName = 'Florindo',
        showtext = false,
    })

    function point:onEnter()
        if not (Peds[id] and DoesEntityExist(Peds[id])) then crearPed() end
    end

    function point:onExit()
        DestroyNPC(id)
        lib.hideTextUI()
    end

    function point:nearby()
        if self.currentDistance < 2.5 then
            self.showtext = true
            lib.showTextUI('[E] Hablar con ' .. self.npcName, {
                position = "left-center",
                icon = 'fish',
                iconColor = '#2ecc71'
            })

            if IsControlJustPressed(0, 38) then -- E
                self.showtext = false
                lib.hideTextUI()
                
                if self.menuType == 'OpenFishingMenu' then
                    OpenFishingMenu()
                end
            end
        else
            if self.showtext then
                lib.hideTextUI()
                self.showtext = false
            end
        end
    end

    ZonePoints[id] = point

    if data.blip then
        CreateBlip(id, pedCoord, data.blip)
    end
end


local DestroyResourceAssets = function()
    if fishingObj then
        SetEntityAsNoLongerNeeded(fishingObj)
        DeleteEntity(fishingObj)
    end
    
    for id, _ in pairs(Peds) do
        DestroyNPC(id)
    end

    for id, _ in pairs(Blips) do
        OrigenMapa.Quitar(Blips[id])
    end

    for id, _ in pairs(ZonePoints) do
        ZonePoints[id]:remove()
    end
end

local function setCanRagdoll(state)
    SetPedCanRagdoll(cache.ped, state)
    SetPedCanRagdollFromPlayerImpact(cache.ped, state)
    SetPedRagdollOnCollision(cache.ped, state or false)
end


----- Callbacks
---
lib.callback.register('origen_fishing:itemUsed', function(bait, fishZone, fish, loosePoints, waitWindow)
    local obj = createRodObject()
    fishingObj = obj

    isFishing = true
    
    lib.requestAnimDict('mini@tennis')
    lib.requestAnimDict('amb@world_human_stand_fishing@idle_a')
    setCanRagdoll(false)

    -- Mostrar ayuda con ox_lib
    lib.showTextUI('[E] Cancelar pesca', {
        position = "right-center",
        icon = 'circle-xmark',
        iconColor = '#e74c3c'
    })

    local p = promise.new()

    local interval = SetInterval(function()
        if IsControlPressed(0, 38)
        or (not IsEntityPlayingAnim(cache.ped, 'mini@tennis', 'forehand_ts_md_far', 3)
        and not IsEntityPlayingAnim(cache.ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 3)) then
            lib.hideTextUI()
            p:resolve(false)
        end
    end, 100)

    local function wait(ms)
        Wait(ms)
        return p.state == 0
    end

    CreateThread(function() 
        TaskPlayAnim(cache.ped, 'mini@tennis', 'forehand_ts_md_far', 3.0, 3.0, 1.0, 16, 0, false, false, false)

        if not wait(1500) then return end

        TaskPlayAnim(cache.ped, 'amb@world_human_stand_fishing@idle_a', 'idle_c', 3.0, 3.0, -1, 11, 0, false, false, false)

        local window = waitWindow or fishZone.waitTime

        if not wait(math.floor(math.random(window.min, window.max) / bait.waitDivisor * 1000)) then return end
        
        Utils.ShowNotification("Un pez ha mordido el cebo, ¡prepárate para atraparlo!", 'warn')
        lib.hideTextUI()

        if interval then
            ClearInterval(interval)
            interval = nil
        end

        if not wait(math.random(2000, 4000)) then return end
        
        exports['origen_fishing']:Skillbar(function(result)

            if not result then
                local errorMsgs = Config.Messages.OnFail
                local rndMessage = errorMsgs[math.random(1, #errorMsgs)]
                Utils.ShowNotification(rndMessage, 'error')
            end

            p:resolve(result)
        end)
    end)

    local success = Citizen.Await(p)

    if interval then
        ClearInterval(interval)
        interval = nil
    end

    DetachEntity(obj, true, true)
    
    SetEntityAsMissionEntity(obj, true, true)

    Wait(100)

    DeleteEntity(obj)

    fishingObj = nil

    ClearPedTasks(cache.ped)
    setCanRagdoll(true)

    if success then
        fishCollected += 1
    end

    isFishing = false

    if tournament and tournament.started then
        if success then
            tournament.points = tournament.points + fish.tournamentPoints
        else
            tournament.points = tournament.points + loosePoints
        end
    end

    return success
end)

-------------- MAIN THREAD
---

-- RegisterCommand('sg', function()
--     StartGameThread()
-- end)


-- RegisterCommand('eg', function()
--     StopGame()
-- end)

CreateThread(function()
    local startPed = Config.InitiatorPed
    CreateNPC("startPed", startPed)

    createFishZones()
end)

-------------- EVENTS
---
RegisterNetEvent('origen_fishing:TournamentStart', function(data)
    tournament = false

    local mins = math.floor((data and data.timeLeft or Config.Tournament.duration) / 60)
    local mode = data and data.mode

    Utils.ShowNotification(
        ('¡Torneo de pesca: %s! %d minutos. %s'):format(
            mode and mode.label or 'Puntuación', mins, modeBrief(mode, data and data.target)),
        'success', 9000)
end)

RegisterNetEvent('origen_fishing:TournamentEnd', function(data)
    tournament = false

    if data and data.winnerName then
        Utils.ShowNotification(
            ('El torneo de pesca (%s) terminó. Ganó %s con %s.'):format(
                data.mode and data.mode.label or 'Puntuación',
                data.winnerName,
                formatScore(data.winnerPoints, data.mode)),
            'success', 9000)
    else
        Utils.ShowNotification('El torneo de pesca ha terminado!', 'success', 5000)
    end
end)

RegisterNetEvent('origen_fishing:client:showStatsPanel', function(data)
    local recordTxt = 'Todavía no tienes ninguna pieza registrada'

    if data.biggest_fish and (data.biggest_weight or 0) > 0 then
        recordTxt = ('%s de %.2f kg'):format(data.biggest_fish, data.biggest_weight)
    end

    exports['org-menu']:openMenu({
        {
            header = "Estadísticas de pesca",
            isMenuHeader = true,
        },
        {
            header = "Información del Ciudadano",
            txt = string.format('Nombre: %s', data.playerName),
            icon = 'fa-solid fa-user',
        },
        {
            header = string.format('Nivel Actual: %d - %s', data.level, data.levelName),
            txt = string.format('Progreso de Experiencia: %d / %d XP', data.current_xp, data.xpForNext),
            icon = 'fa-solid fa-star',
        },
        {
            header = "Rendimiento y Bonificaciones",
            txt = string.format('Bonus ventas: +%d%% | Total peces: %d | Ganancias: $%d', data.bonusPercent, data.total_fish, data.total_earned),
            icon = 'fa-solid fa-chart-line',
        },
        {
            header = "Pieza mayor",
            txt = recordTxt,
            icon = 'fa-solid fa-trophy',
        }
    })
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() == name then
        -- Si nos paramos con el HUD puesto, nadie devolveria el rastreador.
        TriggerEvent('origen_fishing:pescando', false)
        DestroyResourceAssets()
    end
end)
