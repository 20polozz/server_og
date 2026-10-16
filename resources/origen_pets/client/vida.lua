--[[ ── Mascotas · lo que hace por su cuenta y lo que haces con ella ─────────

     Lo que traia murderface-pets y aqui no habia: acariciarla, tirarle la
     pelota, la correa, rastrear y que no vaya detras de ti
     como un mueble. La experiencia la da el servidor (server/progreso.lua);
     desde aqui solo se le cuenta lo que ha pasado. ]]

local P = Config.Progreso

local function Aviso(texto, tipo)
    TriggerEvent('QBCore:Notify', texto, tipo or 'primary')
end

local function Hecho(motivo)
    lib.callback('origen_pets:progreso:hecho', false, function() end, motivo)
end

--- El nivel de la que esta fuera.
function Mascotas.Nivel()
    return Mascotas.fuera and tonumber(Mascotas.fuera.nivel) or 0
end

--- Si ya sabe hacer `que` (ver Config.Progreso.desde). Avisa si no.
function Mascotas.Sabe(que)
    local hace = P.desde[que]
    if not hace or Mascotas.Nivel() >= hace then return true end
    Aviso(('%s aún no sabe hacer eso: nivel %d.'):format(Mascotas.fuera.nombre, hace), 'error')
    return false
end

RegisterNetEvent('origen_pets:client:nivel', function(d)
    if Mascotas.fuera and Mascotas.fuera.id == d.id then
        Mascotas.fuera.nivel = d.nivel
        Mascotas.fuera.titulo = d.titulo
        Aviso(('%s sube a nivel %d · %s'):format(Mascotas.fuera.nombre, d.nivel, d.titulo), 'success')
        if d.especialidad then Aviso('Ya puede elegir especialidad: ábrelo en el panel de mascotas.', 'primary') end
        if Mascotas.orden == 'seguir' and not (CaballoMontado() == Mascotas.ped) then Mascotas.Aplicar() end
    end
    Mascotas.Avisar()
end)

local function Dict(nombre)
    if not DoesAnimDictExist(nombre) then return false end
    RequestAnimDict(nombre)
    local hasta = GetGameTimer() + 3000
    while not HasAnimDictLoaded(nombre) and GetGameTimer() < hasta do Wait(0) end
    return HasAnimDictLoaded(nombre)
end

local ocupada = false

--- Que la mascota vaya hasta `x, y, z` corriendo. Devuelve si llego.
local function IrA(x, y, z, cerca, maximo)
    local ped = Mascotas.ped
    ClearPedTasks(ped)
    TaskGoToCoordAnyMeans(ped, x, y, z, 3.0, 0, false, 786603, 0.0)
    local hasta = GetGameTimer() + maximo
    while GetGameTimer() < hasta do
        Wait(200)
        if not Mascotas.EnLaCalle() then return false end
        if #(GetEntityCoords(ped) - vector3(x, y, z)) <= cerca then return true end
    end
    return false
end

-- ── Acariciar ─────────────────────────────────────────────────────────────

function Mascotas.Acariciar()
    if not Mascotas.EnLaCalle() or ocupada then return end
    local ped, yo = Mascotas.ped, cache.ped

    if #(GetEntityCoords(ped) - GetEntityCoords(yo)) > 3.0 then
        return Aviso(('%s está demasiado lejos.'):format(Mascotas.fuera.nombre), 'error')
    end

    ocupada = true
    TaskTurnPedToFaceEntity(yo, ped, 800)
    TaskTurnPedToFaceEntity(ped, yo, 800)
    Wait(800)

    local dict = 'creatures@rottweiler@tricks@'
    if Dict(dict) then
        TaskPlayAnim(yo, dict, 'petting_franklin', 4.0, -4.0, 4500, 0, 0.0, false, false, false)
        -- La del perro solo le vale a un perro grande; los demas se dejan hacer.
        if GetEntityModel(ped) == `a_c_rottweiler` or GetEntityModel(ped) == `a_c_shepherd`
            or GetEntityModel(ped) == `a_c_husky` or GetEntityModel(ped) == `a_c_retriever` or GetEntityModel(ped) == `a_c_chop` then
            TaskPlayAnim(ped, dict, 'petting_chop', 4.0, -4.0, 4500, 0, 0.0, false, false, false)
        else
            ClearPedTasks(ped)
            TaskStandStill(ped, 4500)
        end
        Wait(4500)
    end

    ocupada = false
    Hecho('acariciar')
    if Mascotas.EnLaCalle() then Mascotas.Aplicar() end
end

-- ── La pelota ─────────────────────────────────────────────────────────────

function Mascotas.Pelota()
    if not Mascotas.EnLaCalle() or ocupada then return end
    if IsPedInAnyVehicle(cache.ped, false) then return end
    ocupada = true

    local yo, ped = cache.ped, Mascotas.ped
    local modelo = `prop_tennis_ball`
    RequestModel(modelo)
    local hasta = GetGameTimer() + 3000
    while not HasModelLoaded(modelo) and GetGameTimer() < hasta do Wait(0) end
    if not HasModelLoaded(modelo) then ocupada = false return end

    if Dict('anim@heists@narcotics@trash') then
        TaskPlayAnim(yo, 'anim@heists@narcotics@trash', 'throw_b', 4.0, -4.0, 1200, 48, 0.0, false, false, false)
        Wait(600)
    end

    local mano = GetPedBoneCoords(yo, 57005, 0.0, 0.0, 0.0)
    local bola = CreateObject(modelo, mano.x, mano.y, mano.z + 0.3, false, false, false)
    SetModelAsNoLongerNeeded(modelo)
    local f = GetEntityForwardVector(yo)
    SetEntityVelocity(bola, f.x * 13.0, f.y * 13.0, 6.0)

    -- Hasta que se pare, o dos segundos y medio.
    local t = GetGameTimer() + 2500
    Wait(600)
    while GetGameTimer() < t and GetEntitySpeed(bola) > 0.4 do Wait(100) end

    local d = GetEntityCoords(bola)
    if IrA(d.x, d.y, d.z, 1.6, 9000) and DoesEntityExist(bola) then
        AttachEntityToEntity(bola, ped, GetPedBoneIndex(ped, 31086), 0.18, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        local a = GetEntityCoords(yo)
        IrA(a.x, a.y, a.z, 2.2, 9000)
        Hecho('pelota')
    end

    if DoesEntityExist(bola) then DeleteEntity(bola) end
    ocupada = false
    if Mascotas.EnLaCalle() then Mascotas.Aplicar() end
end

-- ── Rastrear (solo la especialidad de rastreador) ─────────────────────────

local rastreando = 0

function Mascotas.Rastrear()
    if not Mascotas.EnLaCalle() then return end
    if Mascotas.fuera.especialidad ~= 'rastreador' then
        return Aviso(('%s no es rastreadora.'):format(Mascotas.fuera.nombre), 'error')
    end
    if rastreando > GetGameTimer() then return end

    local e = P.especialidades.rastreador
    rastreando = GetGameTimer() + e.dura
    PlayAnimalVocalization(Mascotas.ped, 3, 'BARK')
    Hecho('rastrear')

    CreateThread(function()
        local vistos, repaso = {}, 0
        while GetGameTimer() < rastreando and Mascotas.EnLaCalle() do
            local ahora = GetGameTimer()
            if ahora > repaso then
                repaso = ahora + 500
                vistos = {}
                local aqui = GetEntityCoords(Mascotas.ped)
                for _, ped in ipairs(GetGamePool('CPed')) do
                    if ped ~= cache.ped and ped ~= Mascotas.ped and not IsEntityDead(ped)
                        and #(GetEntityCoords(ped) - aqui) <= e.radio then
                        vistos[#vistos + 1] = ped
                    end
                end
            end
            for i = 1, #vistos do
                if DoesEntityExist(vistos[i]) then
                    local c = GetEntityCoords(vistos[i])
                    DrawMarker(2, c.x, c.y, c.z + 1.1, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.22, 0.22, 0.22, 216, 27, 85, 190, true, true, 2, false, nil, nil, false)
                end
            end
            Wait(0)
        end
    end)
end

-- ── La correa ─────────────────────────────────────────────────────────────

Mascotas.correa = false

function Mascotas.Correa(puesta)
    if puesta == nil then puesta = not Mascotas.correa end
    if puesta and not Mascotas.EnLaCalle() then return end
    Mascotas.correa = puesta

    if Mascotas.ped and DoesEntityExist(Mascotas.ped) then
        TriggerServerEvent('origen_pets:correa', NetworkGetNetworkIdFromEntity(Mascotas.ped), puesta)
        if puesta then Mascotas.Aplicar('seguir') end
    end
    Mascotas.Avisar()
end

--[[ Las correas de las mascotas que hay cerca, la propia y las de los demas:
     una cuerda del juego, de la mano del dueño al cuello. Aqui la cuerda con
     fisica SI viene bien: una correa cuelga. ]]
local cuerdas = {}   -- [ped] = { cuerda, dueno }

local function QuitarCuerda(ped)
    local c = cuerdas[ped]
    if c and DoesRopeExist(c.cuerda) then DeleteRope(c.cuerda) end
    cuerdas[ped] = nil
end

CreateThread(function()
    local repaso = 0
    while true do
        local ahora = GetGameTimer()
        if ahora > repaso then
            repaso = ahora + 1000
            local aqui = GetEntityCoords(cache.ped)
            local vistos = {}
            for _, ped in ipairs(GetGamePool('CPed')) do
                if not IsPedAPlayer(ped) and NetworkGetEntityIsNetworked(ped) then
                    local quien = Entity(ped).state.correa
                    local jug = quien and GetPlayerFromServerId(quien) or -1
                    local dueno = jug ~= -1 and GetPlayerPed(jug) or 0
                    if dueno ~= 0 and #(GetEntityCoords(ped) - aqui) < 60.0 and not IsEntityDead(ped) then
                        vistos[ped] = true
                        if not cuerdas[ped] then
                            RopeLoadTextures()
                            local c = GetEntityCoords(ped)
                            local cuerda = AddRope(c.x, c.y, c.z + 0.5, 0.0, 0.0, 0.0, P.correa.largo, 4, P.correa.largo * 0.5,
                                0.3, 1.0, false, false, false, 1.0, false, 0)
                            cuerdas[ped] = { cuerda = cuerda, dueno = dueno }
                        else
                            cuerdas[ped].dueno = dueno
                        end
                    end
                end
            end
            for ped in pairs(cuerdas) do
                if not vistos[ped] or not DoesEntityExist(ped) then QuitarCuerda(ped) end
            end
        end

        if next(cuerdas) then
            for ped, c in pairs(cuerdas) do
                if DoesEntityExist(ped) and DoesEntityExist(c.dueno) and DoesRopeExist(c.cuerda) then
                    local mano = GetPedBoneCoords(c.dueno, 57005, 0.08, 0.0, 0.0)
                    local cuello = GetPedBoneCoords(ped, 39317, 0.0, 0.0, 0.0)
                    PinRopeVertex(c.cuerda, 0, mano.x, mano.y, mano.z)
                    PinRopeVertex(c.cuerda, GetRopeVertexCount(c.cuerda) - 1, cuello.x, cuello.y, cuello.z)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ── Por su cuenta ─────────────────────────────────────────────────────────

--- Las pequeñas se asustan; las de pelea no.
local function EsAsustadiza()
    local raza = Mascotas.Raza(Mascotas.fuera.raza)
    return not raza.pelea and (raza.salud or 150) <= 130
end

CreateThread(function()
    local siguiente, extrano, regenera = 0, 0, 0
    while true do
        Wait(1000)
        if Mascotas.EnLaCalle() and not ocupada and CaballoMontado() ~= Mascotas.ped then
            local ped, ahora = Mascotas.ped, GetGameTimer()
            local aqui = GetEntityCoords(ped)

            -- Con correa no se separa mas de lo que mide.
            -- Solo si estaba sentada o quieta: si ya te sigue, volver a mandarselo
            -- cada segundo le quita la tarea y no te alcanza nunca.
            if Mascotas.correa and (Mascotas.orden == 'sentar' or Mascotas.orden == 'quieto') and not IsPedInAnyVehicle(ped, false)
                and #(aqui - GetEntityCoords(cache.ped)) > P.correa.largo then
                Mascotas.Aplicar('seguir')
            end

            -- La compañera se recupera sola, poco a poco.
            if Mascotas.fuera.especialidad == 'companero' and ahora > regenera then
                regenera = ahora + 60000
                local vida, techo = GetEntityHealth(ped), GetEntityMaxHealth(ped)
                if vida < techo then SetEntityHealth(ped, math.min(techo, vida + math.ceil((techo - 100) * 0.03))) end
            end

            if Mascotas.orden == 'seguir' or Mascotas.orden == 'guardia' then
                local a = P.ambiente

                -- Los tiros: la pequeña se encoge y luego vuelve contigo.
                if a.sustoDisparos > 0 and EsAsustadiza()
                    and IsAnyPedShootingInArea(aqui.x - a.sustoDisparos, aqui.y - a.sustoDisparos, aqui.z - 15.0,
                        aqui.x + a.sustoDisparos, aqui.y + a.sustoDisparos, aqui.z + 15.0, false, false) then
                    TaskCower(ped, 4000)
                    Wait(4000)
                    if Mascotas.EnLaCalle() then Mascotas.Aplicar() end

                -- Un extraño que se acerca demasiado: le ladra.
                elseif a.ladrarAExtranos > 0 and ahora > extrano then
                    for _, otro in ipairs(GetGamePool('CPed')) do
                        if otro ~= ped and otro ~= cache.ped and IsPedHuman(otro) and not IsEntityDead(otro)
                            and not IsPedInAnyVehicle(otro, false) and #(GetEntityCoords(otro) - aqui) < a.ladrarAExtranos then
                            extrano = ahora + 30000
                            PlayAnimalVocalization(ped, 3, 'BARK')
                            break
                        end
                    end
                end

                -- Y de vez en cuando, un ladrido porque si. Mas si vas corriendo.
                if ahora > siguiente then
                    local cada = a.cada * 1000
                    siguiente = ahora + cada + math.random(0, math.floor(cada / 3))
                    if IsPedSprinting(cache.ped) or math.random() < 0.5 then
                        PlayAnimalVocalization(ped, 3, 'BARK')
                    end
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    for ped in pairs(cuerdas) do QuitarCuerda(ped) end
end)
