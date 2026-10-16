Config = Config or {}

Config.HandCuff = {
    BlockedInputs = {
        68, -- INPUT_VEH_AIM
        69, -- INPUT_VEH_ATTACK
        21, -- INPUT_SPRINT
        24, -- INPUT_ATTACK
        257,-- INPUT_ATTACK2
        25, -- INPUT_AIM
        263,-- INPUT_MELEE_ATTACK1
        45, -- INPUT_RELOAD
        22, -- INPUT_JUMP
        44, -- INPUT_COVER
        37, -- INPUT_SELECT_WEAPON
        23, -- INPUT_ENTER
        288,-- PHONE(F1)
        289,-- INVENTORY(F2)
        170,-- ANIMATIONS(F3)
        167,-- JOB(F6)
        0,  -- Disable changing view
        26, -- Disable looking behind
        73, -- Disable clearing animation
        59, -- Disable steering in vehicle
        71, -- Disable driving forward in vehicle
        72, -- Disable reversing in vehicle
        49, -- Disable Key F
        36, -- Disable going stealth
        47, -- Disable weapon
        264,-- Disable melee
        257,-- Disable melee
        140,-- Disable melee
        141,-- Disable melee
        142,-- Disable melee
        143,-- Disable melee
        75, -- Disable exit vehicle
        75, -- Disable exit vehicle (again)
        45, -- Disable key R
        80, -- Disable key R
        140,-- Disable key R
        250,-- Disable key R
        263,-- Disable key R
        310,-- Disable key R
    },
    Events = {
        OnCuff = function()
            -- When the player gets cuffed
        end,
        WhileCuff = function()
            -- Called while the player is cuffed
        end,
        OnUncuff = function()
            -- When the player gets uncuffed
        end
    },
    SkillCheck = {
        enabled = false, 
        WaitChance = 3500, 
        func = function(playerCufferId)
            if not lib then
                return 
            end
            return lib.skillCheck({'easy', 'easy', {areaSize = 60, speedMultiplier = 1}}, {'w', 'a', 's', 'd'})
        end
    },
    Anims = {
        Idle = {
            dict = "mp_arresting",
            anim = "idle"
        },
        Cuffing = {
            dict = "mp_arrest_paired",
            anim = "cop_p2_back_right"
        },
        Uncuffing = {
            dict = "mp_arresting",
            anim = "a_uncuff"
        },
        BeingCuffed = {
            dict = "mp_arrest_paired",
            anim = "crook_p2_back_right"
        },
        BeingUncuffed = {
            dict = "mp_arresting",
            anim = "b_uncuff"
        }
    }
}

local cuffed = false
local handCuffObject = nil
local dragged = false
local isDragging = false
local isAttached = false
local isEscorting = false

--[[ ── Borrar el prop de las esposas (16/09/2026) ─────────────────────────
     Antes se hacia un DeleteEntity a secas sobre la referencia guardada, y el
     prop se quedaba en la muñeca si el objeto (que es de red) habia pasado a
     ser de otro jugador, o si te esposaban dos veces y la referencia vieja se
     perdia. Ahora: se pide el control antes de borrar, se barren TODAS las
     esposas enganchadas al ped, y si aun asi no se puede, lo borra el
     servidor (que solo acepta esposas enganchadas a quien lo pide). ]]
local MODELO_ESPOSAS = GetHashKey("p_cs_cuffs_02_s")

local function BorrarPropEsposas(obj)
    if not obj or obj == 0 or not DoesEntityExist(obj) then return end
    if NetworkGetEntityIsNetworked(obj) and not NetworkHasControlOfEntity(obj) then
        local fin = GetGameTimer() + 1000
        NetworkRequestControlOfEntity(obj)
        while not NetworkHasControlOfEntity(obj) and GetGameTimer() < fin do
            Wait(0)
            NetworkRequestControlOfEntity(obj)
        end
    end
    DetachEntity(obj, true, true)
    SetEntityAsMissionEntity(obj, true, true)
    DeleteEntity(obj)
    if DoesEntityExist(obj) and NetworkGetEntityIsNetworked(obj) then
        TriggerServerEvent("origen_gang:server:borrarPropEsposas", ObjToNet(obj))
    end
end

-- En el momento: hay que llamarla desde un hilo (espera al control del objeto).
function QuitarPropEsposasYa(obj)
    local ped = PlayerPedId()
    BorrarPropEsposas(obj)
    for _, o in ipairs(GetGamePool("CObject")) do
        if GetEntityModel(o) == MODELO_ESPOSAS and IsEntityAttachedToEntity(o, ped) then
            BorrarPropEsposas(o)
        end
    end
end

-- En segundo plano: se puede llamar desde un export o un evento sin hilo propio.
function QuitarPropEsposas(obj)
    CreateThread(function() QuitarPropEsposasYa(obj) end)
end

-- Helper to load anim dict
local RequestAnimDict = function(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(5)
    end
end

--------------------------------------
----------------ESPOSAR---------------
--------------------------------------

RegisterNetEvent("origen_gang:client:setcuffstate", function(otherid)
    cuffed = not cuffed

    Citizen.CreateThread(function()
        TriggerServerEvent("origen_gang:server:playcuffanim", otherid, cuffed)

        local tgtped = GetPlayerPed(GetPlayerFromServerId(otherid))
        
        -- Optional: Orient cuffed player towards cuffer? Police script does this:
        if tgtped ~= 0 then
            SetEntityCoords(PlayerPedId(), GetEntityCoords(tgtped) + GetEntityForwardVector(tgtped))
            SetEntityHeading(PlayerPedId(), GetEntityHeading(tgtped))
        end

        Citizen.Wait(5000)

        local ped = PlayerPedId()
        
        -- LockInventory(cuffed) -- Assuming Bridge or export handles this, or we need to add it. f_quick_actions had this? No.
        -- f_quick_actions used: SetEnableHandcuffs(playerPed, true), DisablePlayerFiring(playerPed, true), SetCurrentPedWeapon(playerPed, `WEAPON_UNARMED`, true)
        
        if cuffed then
            SetEnableHandcuffs(ped, true)
            DisablePlayerFiring(ped, true)
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
            Config.HandCuff.Events.OnCuff()
        else
            SetEnableHandcuffs(ped, false)
            DisablePlayerFiring(ped, false)
            -- Por si el aviso de la animacion no llego: las esposas, fuera.
            QuitarPropEsposasYa(handCuffObject)
            handCuffObject = nil
            Config.HandCuff.Events.OnUncuff()
        end

        while cuffed do
            Config.HandCuff.Events.WhileCuff()

            GiveWeaponToPed(ped, GetHashKey("WEAPON_UNARMED"), 0, false, true)
            
            for _, v in pairs(Config.HandCuff.BlockedInputs) do
                DisableControlAction(0, v, true)
            end

            if not IsEntityPlayingAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3) then
                RequestAnimDict(Config.HandCuff.Anims.Idle.dict)
                TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, 8.0, -1, 51, false, false, false)
            end

            Citizen.Wait(0)
        end
    end)
end)

RegisterNetEvent("origen_gang:client:playarrestanim", function(value)
    RequestAnimDict(Config.HandCuff.Anims.Cuffing.dict)
    RequestAnimDict(Config.HandCuff.Anims.Uncuffing.dict)

    if value then -- Cuffling
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Cuffing.dict, Config.HandCuff.Anims.Cuffing.anim, 8.0, -8.0, 3750 , 2, 0, 0, 0, 0)
    else -- Uncuffing
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Uncuffing.dict, Config.HandCuff.Anims.Uncuffing.anim, 8.0, -8.0,-1, 2, 0, 0, 0, 0)
    end
    Citizen.Wait(3500)
    ClearPedTasks(PlayerPedId())
end)

RegisterNetEvent("origen_gang:client:playarrestedanim", function(value, cufferId)
    RequestAnimDict(Config.HandCuff.Anims.BeingCuffed.dict)
    RequestAnimDict(Config.HandCuff.Anims.BeingUncuffed.dict)
    RequestAnimDict(Config.HandCuff.Anims.Idle.dict)

    local ped = PlayerPedId()
    if value then -- Being cuffed
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingCuffed.dict, Config.HandCuff.Anims.BeingCuffed.anim, 8.0, -8.0, 3750 , 2, 0, 0, 0, 0)
        
        if not Config.HandCuff.SkillCheck.enabled then
            Wait(3500)
            local coords = GetEntityCoords(ped, false)
            QuitarPropEsposasYa(handCuffObject)
            handCuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handCuffObject, ped, GetPedBoneIndex(ped, 60309), -0.020, 0.060, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
            return
        end

        local SkillSuccess = nil
        Citizen.CreateThread(function()
            SkillSuccess = Config.HandCuff.SkillCheck.func(cufferId)
        end)
        Citizen.Wait(Config.HandCuff.SkillCheck.WaitChance)
        
        if not SkillSuccess then
            local coords = GetEntityCoords(ped, false)
            QuitarPropEsposasYa(handCuffObject)
            handCuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handCuffObject, ped, GetPedBoneIndex(ped, 60309), -0.020, 0.060, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        else
            cuffed = false
            ClearPedTasks(PlayerPedId())
        end
    else -- Being uncuffed
        QuitarPropEsposas(handCuffObject)
        handCuffObject = nil
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingUncuffed.dict, Config.HandCuff.Anims.BeingUncuffed.anim, 8.0, -8.0,-1, 2, 0, 0, 0, 0)
        Citizen.Wait(3500)
        ClearPedTasks(PlayerPedId())
    end
end)

function RemoveHandCuff()
    cuffed = false
    QuitarPropEsposas(handCuffObject)
    handCuffObject = nil
    ClearPedTasks(PlayerPedId())
    SetEnableHandcuffs(PlayerPedId(), false)
    DisablePlayerFiring(PlayerPedId(), false)
end

exports("RemoveHandCuff", RemoveHandCuff)
exports("IsHandcuffed", function() return cuffed end)

RegisterNetEvent("origen_gang:client:cuffuncuff", function(targetId)
    local playerPed = PlayerPedId()
    if IsPedInAnyVehicle(playerPed, false) then return end

    -- Logic for closest player if targetId is not provided
    local player, distance
    if targetId then
         -- If targetId provided (from menu), we assume validation is done but checking distance is good practice
         -- Converting server ID to player index for distance check
         local targetPlayer = GetPlayerFromServerId(targetId)
         if targetPlayer ~= -1 then
             player = targetPlayer
             distance = #(GetEntityCoords(playerPed) - GetEntityCoords(GetPlayerPed(targetPlayer)))
         else
             player = -1
             distance = 100.0
         end
    else
         -- Use lib or custom function to get closest player
         if lib and lib.getClosestPlayer then
             player, distance = lib.getClosestPlayer(GetEntityCoords(playerPed), 3.0, false)
         else
             -- Fallback or reuse FW_GetClosestPlayer logic if available, or simple loop
             -- Since we don't have FW_GetClosestPlayer here, we rely on targetId being passed from menu usually
             -- Or implement a simple closest player check
             local players = GetActivePlayers()
             local closestDistance = -1
             local closestPlayer = -1
             local plyCoords = GetEntityCoords(playerPed)
             for _, p in ipairs(players) do
                 if p ~= PlayerId() then
                     local targetCoords = GetEntityCoords(GetPlayerPed(p))
                     local dist = #(plyCoords - targetCoords)
                     if closestDistance == -1 or dist < closestDistance then
                         closestPlayer = p
                         closestDistance = dist
                     end
                 end
             end
             player = closestPlayer
             distance = closestDistance
         end
    end

    if player ~= -1 and distance <= 3.0 and distance > 0 then
        -- Trigger server event
        local targetServerId = GetPlayerServerId(player)
        TriggerServerEvent("origen_gang:server:cuffuncuffplayer", targetServerId)
    else
        Notify.SendNotify(locale:t('notify.no_player_nearby') or "No player nearby", "error")
    end
end)

---------------------------------------
----------------ESCOLTAR---------------
---------------------------------------

RegisterNetEvent("origen_gang:client:drag", function(targetId)
    local playerPed = PlayerPedId()
    local player, distance
    
    if targetId then
         local targetPlayer = GetPlayerFromServerId(targetId)
         if targetPlayer ~= -1 then
             player = targetPlayer
             distance = #(GetEntityCoords(playerPed) - GetEntityCoords(GetPlayerPed(targetPlayer)))
         else
            player = -1
            distance = 100.0
         end
    else
        -- Fallback closest
         local players = GetActivePlayers()
         local closestDistance = -1
         local closestPlayer = -1
         local plyCoords = GetEntityCoords(playerPed)
         for _, p in ipairs(players) do
             if p ~= PlayerId() then
                 local targetCoords = GetEntityCoords(GetPlayerPed(p))
                 local dist = #(plyCoords - targetCoords)
                 if closestDistance == -1 or dist < closestDistance then
                     closestPlayer = p
                     closestDistance = dist
                 end
             end
         end
         player = closestPlayer
         distance = closestDistance
    end

    if player ~= -1 and distance <= 3.0 and distance > 0 then
        local tgtped = GetPlayerPed(player)
        local state = not IsEntityAttachedToEntity(tgtped, playerPed)

        -- Check if player is cuffed or if we want to allow dragging without cuffs?
        -- Police script checks if playing idle anim (cuffed). We might want to enforce it.
        -- "Has to be cuffed" check:
        if (state and IsEntityPlayingAnim(tgtped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3)) or dragged then
            TriggerServerEvent("origen_gang:server:dragplayer", GetPlayerServerId(player), state)
            dragged = state and GetPlayerServerId(player) or false
            
            Citizen.CreateThread(function()
                RequestAnimDict("amb@world_human_drinking@coffee@male@base")
                while dragged and DoesEntityExist(tgtped) and IsPedOnFoot(tgtped) and not IsPedDeadOrDying(tgtped, true) do
                    Citizen.Wait(100)
                    if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 3) then
                         TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 8.0, 8.0, -1, 49, false, false, false)
                    end
                end
                dragged = false
                ClearPedTasks(PlayerPedId())
            end)
        else
            Notify.SendNotify(locale:t('notify.must_be_cuffed_to_escort'), "error")
        end
    else
        Notify.SendNotify(locale:t('notify.no_player_nearby') or "No player nearby", "error")
    end
end)

RegisterNetEvent("origen_gang:client:setdragstate", function(state, otherid)
    isDragging = state
    local ped = PlayerPedId()

    if isDragging then
        local target = GetPlayerFromServerId(otherid)
        local tgtped = GetPlayerPed(target)

        AttachEntityToEntity(ped, tgtped, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)

        Citizen.CreateThread(function()
            while isDragging and DoesEntityExist(tgtped) and IsPedOnFoot(tgtped) and not IsPedDeadOrDying(tgtped, true) do
                Citizen.Wait(100)
                ped = PlayerPedId()
                tgtped = GetPlayerPed(target)
                if not IsEntityAttachedToEntity(ped, tgtped) then
                    AttachEntityToEntity(ped, tgtped, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                end
                -- Sync walking animation/movement if needed?
                -- The police script has a complex loop here with `TaskGoStraightToCoord` but typically attaching entity handles movement.
                -- Police script used:
                -- if GetEntitySpeed(tgtped) > 0.1 then 
                --      TaskGoStraightToCoord(...) 
                -- end
                -- We will stick to attachment for now.
            end
            isDragging = false
            DetachEntity(PlayerPedId(), true, false)
            ClearPedTasks(ped)
        end)
    else
        DetachEntity(PlayerPedId(), true, false)
    end
end)

-- Additional event compatibility for dragging
RegisterNetEvent('origen_gang:client:getDragged',function(entToAttach,anim)
    local curAttachedPed = GetPlayerPed(GetPlayerFromServerId(entToAttach))
    local ped = PlayerPedId()
    if anim == 'escort' then
        if not isAttached then
            ClearPedTasks(ped)
            isAttached = true
            RequestAnimDict(Config.HandCuff.Anims.Cuffing.dict)
            RequestAnimDict('move_m@generic_variations@walk')
            TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8, -1, 49, 0.0, false, false, false)
            AttachEntityToEntity(ped,curAttachedPed, 1816,0.25, 0.49, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        else
            isAttached = false
            DetachEntity(ped)
            ClearPedTasks(ped)
        end
    elseif anim == "stopdrag" then
        isAttached = false
        DetachEntity(ped)
        ClearPedTasks(ped)
    else
        -- Unused for now
    end
end)

RegisterNetEvent('origen_gang:client:doAnimation',function(anim)
    local ped = PlayerPedId()
    if anim == 'escort' then
        if isEscorting then
            ClearPedTasks(ped)
            isEscorting = false
        else
            isEscorting = true
            RequestAnimDict('amb@world_human_drinking@coffee@male@base')
            if IsEntityPlayingAnim(ped, 'amb@world_human_drinking@coffee@male@base','base', 3) ~= 1 then
                TaskPlayAnim(ped, 'amb@world_human_drinking@coffee@male@base','base' ,8.0, -8, -1, 51, 0, false, false, false)
            end
        end
    elseif anim == "stopdrag" then
        ClearPedTasks(ped)
    end
end)
