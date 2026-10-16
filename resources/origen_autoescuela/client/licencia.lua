--[[ ── Enseñar la licencia y volar sin ella ────────────────────────────────────

     Usar la tarjeta desde el inventario: el personaje la saca, la ve en
     pequeño y, si hay alguien a menos de 3 m, se la enseña (el servidor
     comprueba la distancia y le manda la tarjeta que armó él). La tarjeta
     sale sola en la pantalla y se va sola, sin coger el ratón.

     Al ponerse a los mandos de un avión o un helicóptero se pregunta al
     servidor si lleva encima una licencia que cubra ese aparato. ]]

local PROP = 'prop_franklin_dl'

local function Animacion()
    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) then return end
    lib.requestAnimDict('paper_1_rcm_alt1-8')
    local hash = GetHashKey(PROP)
    local prop
    if A.Cargar(hash) then
        prop = CreateObject(hash, 0.0, 0.0, 0.0, true, true, false)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005), 0.1, 0.02, -0.03, -90.0, 170.0, 78.999, true, true, false, true, 1, true)
        SetModelAsNoLongerNeeded(hash)
    end
    TaskPlayAnim(ped, 'paper_1_rcm_alt1-8', 'player_one_dual-8', 8.0, -8.0, 4500, 49, 0, false, false, false)
    SetTimeout(4500, function()
        if prop and DoesEntityExist(prop) then DeleteEntity(prop) end
        StopAnimTask(ped, 'paper_1_rcm_alt1-8', 'player_one_dual-8', 1.0)
    end)
end

local function MasCercano()
    local yo = GetEntityCoords(cache.ped)
    local mejor, dMejor = nil, 3.0
    for _, id in ipairs(GetActivePlayers()) do
        if id ~= cache.playerId then
            local ped = GetPlayerPed(id)
            local d = #(GetEntityCoords(ped) - yo)
            if d < dMejor then mejor, dMejor = GetPlayerServerId(id), d end
        end
    end
    return mejor
end

RegisterNetEvent('origen_autoescuela:ensenar', function(tarjeta)
    Animacion()
    A.Nui('tarjeta', { tarjeta = tarjeta, propia = true })
    local otro = MasCercano()
    if otro then
        TriggerServerEvent('origen_autoescuela:mostrarA', otro)
    else
        A.Aviso('No hay nadie cerca para enseñársela: la miras tú.', 'inform', 4000)
    end
end)

RegisterNetEvent('origen_autoescuela:ver', function(tarjeta)
    A.Nui('tarjeta', { tarjeta = tarjeta, propia = false })
end)

-- ── Volar sin licencia ────────────────────────────────────────────────────

CreateThread(function()
    if not Config.Control.activo then return end
    local avisado = nil
    while true do
        Wait(1000)
        local veh = cache.vehicle
        if veh and cache.seat == -1 then
            local clase = GetVehicleClass(veh)
            if Auto.NivelQuePide(clase) and avisado ~= veh
                and not (Entity(veh).state.autoescuelaExamen) then
                avisado = veh
                local r = lib.callback.await('origen_autoescuela:puedoConducir', false, clase)
                if r and not r.ok then
                    A.Aviso(r.mensaje, 'error', 9000)
                    if r.bloquear then
                        CreateThread(function()
                            while cache.vehicle == veh and cache.seat == -1 do
                                SetVehicleEngineOn(veh, false, true, true)
                                Wait(0)
                            end
                        end)
                    end
                end
            end
        elseif not veh then
            avisado = nil
        end
    end
end)
