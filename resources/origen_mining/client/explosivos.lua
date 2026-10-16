--[[ ── Explosivos en el cliente ───────────────────────────────────────────────

     Lo que se ve:
       · las cargas puestas (el C4 pegado a la roca o en su marca del bloque),
         con su lucecita roja que parpadea;
       · las marcas del bloque donde van las cargas (aros en el suelo), para
         quien tiene nivel de voladura;
       · la sirena y la cuenta atrás de una voladura, con la zona en rojo;
       · la explosión: fogonazo, humo, polvo, cascotes, sonido y temblor. No es
         una explosión de GTA (no rompe nada ni mata): el golpe a la gente lo
         decide el servidor y llega aparte (`golpe`). ]]

local E = Config.Explosivos
local VO = Config.Voladura

local props = {}        -- [cargaId] = ent

local function PintarCarga(id, v)
    local ent = props[id]
    if not v or v.borrada then
        if ent then Cantera.Borrar(ent) props[id] = nil end
        return
    end
    if ent and DoesEntityExist(ent) then return end
    local p = v.pos
    local z = p.z
    if v.tipo == 'bloque' then
        z = (Cantera.Suelo(p.x, p.y, p.z) or p.z) + 0.05
    end
    local e = Cantera.Objeto(E.modelo, p.x, p.y, z, false)
    if e then
        -- Pegada a la roca, de pie y mirando hacia fuera.
        SetEntityRotation(e, -90.0, 0.0, math.random(0, 359) + 0.0, 2, true)
        props[id] = e
    end
end

AddEventHandler('origen_mining:c:carga', function(id, v)
    PintarCarga(id, v and not v.borrada and L.cargas[id] or nil)
end)

-- El parpadeo de las cargas y las marcas de los bloques.
CreateThread(function()
    while true do
        local espera = 500
        if L.cerca then
            local pos = GetEntityCoords(cache.ped)
            local ahora = GetGameTimer()
            for id, v in pairs(L.cargas) do
                local ent = props[id]
                if not ent or not DoesEntityExist(ent) then PintarCarga(id, v) ent = props[id] end
                if ent and #(GetEntityCoords(ent) - pos) < 60.0 then
                    espera = 0
                    if (ahora // 500) % 2 == 0 then
                        local c = GetEntityCoords(ent)
                        DrawLightWithRange(c.x, c.y, c.z + 0.15, 255, 20, 20, 1.2, 6.0)
                    end
                end
            end
            for id, ent in pairs(props) do
                if not L.cargas[id] then Cantera.Borrar(ent) props[id] = nil end
            end
            -- Las marcas: solo de jornada y con el nivel de voladura.
            if L.Jornada() and L.Nivel() >= VO.nivel then
                for _, b in ipairs(Config.Bloques) do
                    local v = L.bloques[b.id]
                    if v and (v.e == 'bloque' or v.e == 'cargado') and #(pos.xy - b.pos.xy) < 30.0 then
                        espera = 0
                        local puestas = {}
                        for _, i in ipairs(v.cargas or {}) do puestas[i] = true end
                        for i, pto in ipairs(Mina.PuntosCarga(b)) do
                            local z = Cantera.Suelo(pto.x, pto.y, pto.z) or pto.z
                            Cantera.Aro(vec3(pto.x, pto.y, z), 0.7, 0.12,
                                puestas[i] and { 60, 200, 110, 170 } or { 255, 45, 106, 170 })
                        end
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- ── La sirena ─────────────────────────────────────────────────────────────

local sirenas = {}      -- [bloqueId] = { centro, radio, hasta, sonido }

RegisterNetEvent('origen_mining:sirena', function(d)
    if type(d) ~= 'table' then return end
    local centro = vec3(d.x + 0.0, d.y + 0.0, d.z + 0.0)
    local s = { centro = centro, radio = d.radio + 0.0, hasta = GetGameTimer() + (d.cuenta or 10) * 1000 }
    s.sonido = GetSoundId()
    PlaySoundFromCoord(s.sonido, 'Altitude_Warning', centro.x, centro.y, centro.z, 'EXILE_1', false, 120, false)
    sirenas[d.id] = s
    local pos = GetEntityCoords(cache.ped)
    if #(pos - centro) < d.radio + 40.0 then
        L.Aviso(('¡VOLADURA en %d segundos! Sal de la zona roja.'):format(d.cuenta or 10), 'warning', 6000)
        s.visto = d.cuenta or 10 -- ya avisado: la cuenta sigue cada 5 s
    end
end)

CreateThread(function()
    while true do
        local espera = 500
        if next(sirenas) then
            espera = 0
            local ahora = GetGameTimer()
            local pos = GetEntityCoords(cache.ped)
            for id, s in pairs(sirenas) do
                if ahora > s.hasta + 500 then
                    if s.sonido then StopSound(s.sonido) ReleaseSoundId(s.sonido) end
                    sirenas[id] = nil
                else
                    local latido = 90 + math.floor(80 * math.abs(math.sin(ahora / 160)))
                    Cantera.Aro(s.centro, s.radio, 0.6, { 230, 30, 30, latido })
                    Cantera.Aro(s.centro, s.radio * 0.5, 0.3, { 230, 30, 30, latido // 2 })
                    local falta = math.max(0, math.ceil((s.hasta - ahora) / 1000))
                    -- La cuenta atras va en avisos de origen_notify (tipo warning),
                    -- no en el aviso de tecla: no hay tecla que pulsar. Uno al
                    -- entrar en la zona y luego cada 5 s mientras sigas dentro.
                    if #(pos - s.centro) < s.radio + 30.0 then
                        if s.visto ~= falta then
                            local primero = s.visto == nil
                            s.visto = falta
                            if falta > 0 and (primero or falta % 5 == 0) then
                                L.Aviso(('Voladura en %d s. Sal de la zona roja.'):format(falta), 'warning', 4500)
                            end
                        end
                    else
                        s.visto = nil
                    end
                end
            end
        end
        Wait(espera)
    end
end)

-- ── La explosión ──────────────────────────────────────────────────────────

RegisterNetEvent('origen_mining:explosion', function(d)
    if type(d) ~= 'table' then return end
    local c = vec3(d.x + 0.0, d.y + 0.0, d.z + 0.0)
    local grande = d.grande == true
    local pos = GetEntityCoords(cache.ped)
    local dist = #(pos - c)
    Cantera.Efecto('core', 'exp_grd_grenade_lod', c.x, c.y, c.z + 0.6, grande and 3.0 or 1.4)
    Cantera.Efecto('core', 'ent_dst_rocks', c.x, c.y, c.z + 0.6, grande and 4.0 or 2.0)
    Cantera.Efecto('core', 'ent_dst_dust', c.x, c.y, c.z + 0.8, grande and 6.0 or 3.0)
    if grande then
        Cantera.Efecto('des_bigjobdrill', 'ent_ray_big_drill_cloud', c.x, c.y, c.z + 1.0, 1.5)
        Cantera.Efecto('cut_finale1', 'cs_finale2_dust_cloud', c.x, c.y, c.z + 0.5, 1.0)
        for i = 1, 6 do
            local a = math.rad(i * 60.0)
            Cantera.Efecto('core', 'ent_dst_concrete_large', c.x + math.cos(a) * 3.0, c.y + math.sin(a) * 3.0, c.z + 0.6, 1.2)
        end
    end
    PlaySoundFromCoord(-1, 'Jet_Explosions', c.x, c.y, c.z, 'exile_1', false, grande and 300 or 150, false)
    PlaySoundFromCoord(-1, 'MAIN_EXPLOSION_CHEAP', c.x, c.y, c.z, 0, false, grande and 300 or 150, false)
    if dist < (grande and 120.0 or 60.0) then
        local fuerza = math.max(0.05, (grande and 1.0 or 0.5) * (1.0 - dist / (grande and 120.0 or 60.0)))
        ShakeGameplayCam(grande and 'LARGE_EXPLOSION_SHAKE' or 'MEDIUM_EXPLOSION_SHAKE', fuerza)
    end
    -- La lluvia de polvo que queda después.
    SetTimeout(900, function()
        Cantera.Efecto('core', 'scr_fbi_falling_dust', c.x, c.y, c.z + 4.0, grande and 3.0 or 1.5)
        Cantera.Efecto('core', 'scr_fbi_ground_debris', c.x, c.y, c.z + 0.3, grande and 2.5 or 1.2)
    end)
end)

--- El golpe: lo manda el servidor a quien estaba dentro del radio.
RegisterNetEvent('origen_mining:golpe', function(dano, centro)
    if GetInvokingResource() then return end
    local ped = cache.ped
    SetPedToRagdoll(ped, 3500, 3500, 0, false, false, false)
    ApplyDamageToPed(ped, math.min(60, tonumber(dano) or 25), false)
    ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 0.6)
    L.Aviso('¡Te ha pillado la explosión! Aléjate antes de detonar.', 'error')
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for _, e in pairs(props) do Cantera.Borrar(e) end
    for _, s in pairs(sirenas) do if s.sonido then StopSound(s.sonido) ReleaseSoundId(s.sonido) end end
end)
