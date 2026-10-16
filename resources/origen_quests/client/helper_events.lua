if not lib then
    lib = exports.ox_lib:Default()
end

local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('origen_quest:client:EventAndTrade', function(event, location, mission_id, mission, allowed)
    local status = mission.Data.events[1].npcStatus
    local npcs = mission.Data.npcs
    local time = tonumber(mission.Data.events[1].spawnTime) or 1
    local radius = tonumber(mission.Data.events[1].spawnDistance) or Config.SpawnNPCsRadius
    local state = false
    local locCoords = false

    for i = 1, #Locations do
        if Locations[i].id == location then
            locCoords = vector3(Locations[i].location)
        end
    end
    
    --[[ Solo se vuelve a abrir el encargo tras el minijuego si estaba delante
         al empezar. Al aceptar, AcceptMission ya lo ha cerrado y quitado la
         camara: reabrirlo despues sacaba el dialogo con los datos viejos (el
         encargo recien hecho aun en la lista) y cogia el raton. ]]
    local reabrir = QuestAbierta and QuestAbierta()
    ToggleQuest(false)
    if status == 'onSpawn' or status == 'onBoth' then
        SetTimeout(time * 1000, function()
            SpawnNPCs(npcs, locCoords, radius)
        end)
    end

    TriggerEvent(event, function(result)
        if result then
            TriggerServerEvent('origen_quests:server:CompleteMissionOnEvent', location, mission_id, allowed)
            state = 'onSuccess'
        else
            QBCore.Functions.Notify('Has fallado!', 'error')
            state = 'onFail'
        end
        if reabrir and not QuestAbierta() then
            ToggleQuest(true)
        end
        if status == state then
            SetTimeout(time * 1000, function()
                SpawnNPCs(npcs, locCoords, radius)
            end)
        end
    end)
end)

RegisterNetEvent('origen_quest:client:SpawnOnTrade', function(location, mission)
    local status = mission.Data.events[1].npcStatus
    if status == 'none' then return end
    local npcs = mission.Data.npcs
    local time = tonumber(mission.Data.events[1].spawnTime) or 1
    local radius = tonumber(mission.Data.events[1].spawnDistance) or Config.SpawnNPCsRadius
    local locCoords = false
    
    for i = 1, #Locations do
        if Locations[i].id == location then
            locCoords = vector3(Locations[i].location)
        end
    end

    Wait(time * 1000)

    SpawnNPCs(npcs, locCoords, radius)
end)

RegisterNetEvent("origen_quests:c:heal_ilegal", function(cb)
    local illegalMedicCoords = vector4(-604.46, -1758.99, 23.19, 208.09)

    -- cb puede ser una función (EventAndTrade) o un número (TriggerEvent directo)
    local callback = type(cb) == 'function' and cb or nil

    CreateThread(function()
        local ped = cache.ped

        -- 1. Fade out
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(50) end

        -- 2. Sacar de estado muerto/laststand ANTES del TP
        if GetResourceState('origen_ambulancejob') == 'started' then
            pcall(function() exports.origen_ambulancejob:revive() end)
            Wait(100)
        elseif GetResourceState('qbx_medical') == 'started' then
            TriggerEvent('qbx_medical:client:playerRevived')
            Wait(100)
        elseif IsPedDeadOrDying(ped, true) then
            local pos = GetEntityCoords(ped)
            NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
            Wait(100)
        end

        -- 3. TP a la localización del médico
        ClearPedTasksImmediately(ped)
        SetEntityCoords(ped, illegalMedicCoords.x, illegalMedicCoords.y, illegalMedicCoords.z, false, false, false, false)
        SetEntityHeading(ped, illegalMedicCoords.w)
        Wait(100)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        LocalPlayer.state.invBusy = true

        -- 4. Animación passout4 (mismo dict que /e passout4 de origen_anims)
        lib.requestAnimDict('mini@cpr@char_b@cpr_def', 10000)
        TaskPlayAnim(ped, 'mini@cpr@char_b@cpr_def', 'cpr_pumpchest_idle', 8.0, 8.0, -1, 1, 0.0, false, false, false)

        -- 5. Fade in — el jugador ya está en el sitio
        DoScreenFadeIn(500)

        -- 6. Progressbar del tratamiento
        QBCore.Functions.Progressbar("hospital_checkin", "Revisando heridas", 20000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            -- Tratamiento completado: levantarse
            ClearPedTasksImmediately(ped)
            lib.requestAnimDict('switch@franklin@bed', 10000)
            TaskPlayAnim(ped, 'switch@franklin@bed', 'sleep_getup_rubeyes', 100.0, 1.0, 4000, 8, -1.0, false, false, false)
            Wait(4000)
            ClearPedTasks(ped)
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
            LocalPlayer.state.invBusy = false
            if callback then callback(true) end
        end, function()
            -- Cancelado
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(ped, false)
            SetEntityInvincible(ped, false)
            LocalPlayer.state.invBusy = false
            QBCore.Functions.Notify("Cancelado", "error")
            if callback then callback(false) end
        end)
    end)
end)

-- Reto de habilidad genérico (ox_lib skillCheck), pensado para usarse como
-- "Evento a ejecutar" en cualquier misión clásica sin depender de ningún
-- minijuego externo — ox_lib ya es una dependencia de todo el resource.
RegisterNetEvent('origen_quests:c:skillcheck_easy', function(cb)
    local success = lib.skillCheck('easy', { 'w', 'a', 's', 'd' })
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:skillcheck_medium', function(cb)
    local success = lib.skillCheck({ 'easy', 'medium' }, { 'w', 'a', 's', 'd' })
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:skillcheck_hard', function(cb)
    local success = lib.skillCheck({ 'medium', 'hard', 'hard' }, { 'w', 'a', 's', 'd' })
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent("origen_quests:c:requestid", function()
	TriggerServerEvent("origen_quests:requestid", exports["origen_utils"]:UpdateMugShotDiscord(false, true, true))
end)

RegisterNetEvent("origen_quests:c:requestdriver", function()
	TriggerServerEvent("origen_quests:requestdriver", exports["origen_utils"]:UpdateMugShotDiscord(false, true, true))
end)

RegisterNetEvent('origen_quests:c:hacking-1', function(cb)
    TriggerEvent('ultra-keypadhack', 6, 600, 2, function(result, reason)
        if not cb then return end
        cb(result == 1 and true or false)
	end)
end)

RegisterNetEvent('origen_quests:c:hacking-2', function(cb)
    TriggerEvent("utk_fingerprint:Start", 1, 1, 1, function(result, reason)
        if not cb then return end
        cb(result)
    end)
end)

RegisterNetEvent('origen_quests:c:hacking-3', function(cb)
    local result = exports['origen_lockpick']:createGame(5, 2)
    if not cb then return end
    cb(result and true or false)
end)

RegisterNetEvent('origen_quests:c:hacking-4', function(cb)
    TriggerEvent("mhacking:seqstart", 4, 35, function(success, remainingtime)
        if not cb then return end
        cb(success and true or false)
    end)
end)

-- Glitch Minigames Implementation

RegisterNetEvent('origen_quests:c:firewall_pulse', function(cb)
    local success = exports['glitch-minigames']:StartFirewallPulse()
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:backdoor_sequence', function(cb)
    local success = exports['glitch-minigames']:StartBackdoorSequence(3, 20, 20, 3, 2.0, 3, 6, {'W', 'A', 'S', 'D'}, 'W, A, S, D solamente')
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:circuit_rhythm', function(cb)
    local success = exports['glitch-minigames']:StartCircuitRhythm()
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:surge_override', function(cb)
    local success = exports['glitch-minigames']:StartSurgeOverride()
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:circuit_breaker', function(cb)
    local success = exports['glitch-minigames']:StartCircuitBreaker(2, 1, 1000, 5000, 5000, 0, 10000, 3000, 30000)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:data_crack', function(cb)
    local success = exports['glitch-minigames']:StartDataCrack(3)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:brute_force', function(cb)
    local success = exports['glitch-minigames']:StartBruteForce(5)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:drilling', function(cb)
    local success = exports['glitch-minigames']:StartDrilling()
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:var_hack', function(cb)
    local success = exports['glitch-minigames']:StartVarHack(5, 5)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:plasma_drill', function(cb)
    local success = exports['glitch-minigames']:StartPlasmaDrilling()
    if not cb then return end
    cb(success and true or false)
end)

-- Versiones con dificultad personalizada

RegisterNetEvent('origen_quests:c:firewall_pulse_hard', function(cb)
    local success = exports['glitch-minigames']:StartFirewallPulse(5, 3, 15, 12, 25, 100, 35)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:circuit_rhythm_hard', function(cb)
    local success = exports['glitch-minigames']:StartCircuitRhythm(6, {'Q','W','E','R','T','Y'}, 180, 600, 20, "hard", 3, 5)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:surge_override_random', function(cb)
    local success = exports['glitch-minigames']:StartSurgeOverride({'E', 'F', 'G', 'H'}, 25, 3)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:plasma_drill_hard', function(cb)
    local success = exports['glitch-minigames']:StartPlasmaDrilling(10)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:data_crack_hard', function(cb)
    local success = exports['glitch-minigames']:StartDataCrack(5)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:brute_force_hard', function(cb)
    local success = exports['glitch-minigames']:StartBruteForce(8)
    if not cb then return end
    cb(success and true or false)
end)

RegisterNetEvent('origen_quests:c:var_hack_hard', function(cb)
    local success = exports['glitch-minigames']:StartVarHack(8, 8)
    if not cb then return end
    cb(success and true or false)
end)

-- Secadora 

RegisterNetEvent('origen_quests:c:secadora', function(location_id)
    local stash = '_stash_secadora_'..location_id
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', stash, {
        slots = 50,
        label = 'Secadora'
    })
    TriggerEvent('inventory:client:SetCurrentStash', stash)
end)

local function reviveAtNearestCamilla(cb)
    local callback = type(cb) == 'function' and cb or nil

    QBCore.Functions.Progressbar("hospital_checkin", "Registrándose en el hospital...", 2000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        -- Revive el servidor (OGNRevivir), con el pase que le dio la mision.
        TriggerServerEvent('origen_quests:server:reviveAtNearestCamilla')
        if callback then callback(true) end
    end, function()
        QBCore.Functions.Notify("Cancelado", "error")
        if callback then callback(false) end
    end)
end

RegisterNetEvent('qb-ambulancejob:reviveFromNPC', reviveAtNearestCamilla)
RegisterNetEvent('qb-ambulancejob:reviveFromNPC2', reviveAtNearestCamilla)
RegisterNetEvent('qb-ambulancejob:reviveFromNPC3', reviveAtNearestCamilla)