--[[ ── La caja negra ──────────────────────────────────────────────────────────

     El camion sale volando cuando el conductor se baja y hay mas gente
     cerca. Eso huele a cambio de dueño de red: al bajarse, la fisica del
     camion pasa a la maquina de OTRO jugador, y es en esa maquina donde algo
     lo empuja. Desde fuera no se ve; asi que cada cliente vigila los camiones
     que tiene delante y, cuando uno pega un salto, manda al servidor la foto
     de lo que tenia alrededor en ESE momento: quien era el dueño, que habia
     solido tocandolo, como estaba la caja, como estaba el coche cargado.

     Se apaga con Config.CajaNegra = false. Mientras no salte nada no manda
     nada, y como mucho un parte cada 10 segundos por cliente. ]]

if Config.CajaNegra == false then return end

local ultimoParte = 0
local anterior = {}   -- [veh] = { v = vector3, t = ms }

local function Dueno(ent)
    local idx = NetworkGetEntityOwner(ent)
    if not idx or idx < 0 then return -1 end
    return GetPlayerServerId(idx)
end

local function Rel(grua, ent)
    local r = GetOffsetFromEntityGivenWorldCoords(grua, GetEntityCoords(ent))
    return ('%.1f,%.1f,%.1f'):format(r.x, r.y, r.z)
end

--- Todo lo solido que hay pegado al camion en esta maquina.
local function Alrededor(grua)
    local lista = {}
    local centro = GetEntityCoords(grua)

    local function Mira(pool, tipo)
        for _, e in ipairs(GetGamePool(pool)) do
            if e ~= grua and #(GetEntityCoords(e) - centro) < 9.0 then
                lista[#lista + 1] = ('%s m=%s rel=%s solido=%s pegadoAlCamion=%s enRed=%s dueno=%s'):format(
                    tipo, GetEntityModel(e), Rel(grua, e),
                    tostring(not GetEntityCollisionDisabled(e)),
                    tostring(IsEntityAttachedToEntity(e, grua)),
                    tostring(NetworkGetEntityIsNetworked(e)),
                    NetworkGetEntityIsNetworked(e) and Dueno(e) or '-')
            end
            if #lista >= 14 then return end
        end
    end

    Mira('CVehicle', 'VEH')
    Mira('CObject', 'OBJ')
    Mira('CPed', 'PED')
    return lista
end

local function Parte(grua, ficha, antes, ahora, motivo)
    local gruaNet = NetworkGetNetworkIdFromEntity(grua)
    local yo = GetPlayerServerId(PlayerId())
    local _, remolque = Estado.RemolqueDe(grua)
    local caja = Plataforma.Caja(gruaNet)

    local t = {
        ('MOTIVO %s | yo=%d duenoCamion=%s soyDueno=%s conductor=%s'):format(
            motivo, yo, Dueno(grua), tostring(NetworkHasControlOfEntity(grua)),
            tostring(GetPedInVehicleSeat(grua, -1) ~= 0)),
        ('VEL antes=%.1f,%.1f,%.1f ahora=%.1f,%.1f,%.1f | chocoConAlgo=%s'):format(
            antes.x, antes.y, antes.z, ahora.x, ahora.y, ahora.z,
            tostring(HasEntityCollidedWithAnything(grua))),
        ('CAMION net=%s extraCaja=%s congelado=%s'):format(
            gruaNet, ficha.caja and tostring(IsVehicleExtraTurnedOn(grua, ficha.caja.extra or 1)) or '-',
            tostring(IsEntityPositionFrozen(grua))),
        ('CAJA existe=%s pegada=%s solida=%s rel=%s ocupada=%s'):format(
            tostring(caja ~= nil),
            caja and tostring(IsEntityAttachedToEntity(caja, grua)) or '-',
            caja and tostring(not GetEntityCollisionDisabled(caja)) or '-',
            caja and Rel(grua, caja) or '-',
            tostring(Plataforma.Ocupada(gruaNet))),
    }

    if remolque then
        local coche = Estado.Ent(remolque.coche)
        t[#t + 1] = coche and ('COCHE net=%s pegadoAlCamion=%s solido=%s dueno=%s rel=%s'):format(
            remolque.coche, tostring(IsEntityAttachedToEntity(coche, grua)),
            tostring(not GetEntityCollisionDisabled(coche)), Dueno(coche), Rel(grua, coche))
            or ('COCHE net=%s NO ESTA en esta maquina'):format(remolque.coche)
    else
        t[#t + 1] = 'COCHE ninguno cargado'
    end

    for _, linea in ipairs(Alrededor(grua)) do t[#t + 1] = '  ' .. linea end

    TriggerServerEvent('origen_tow:cajanegra', table.concat(t, '\n'))
end

CreateThread(function()
    while true do
        local espera = 1000
        local ahoraMs = GetGameTimer()

        for _, veh in ipairs(GetGamePool('CVehicle')) do
            local ficha = Tow.Ficha(GetEntityModel(veh))
            if ficha then
                espera = 100
                local v = GetEntityVelocity(veh)
                local a = anterior[veh]

                --[[ SOLO el dueño de red del camion. En los demas clientes el
                     camion es una copia que la red recoloca a saltos, y su
                     velocidad pega brincos que no son de nadie: el primer
                     dia esto mando cientos de partes de camiones que iban
                     tan tranquilos por la autopista. Y con conductor solo
                     cuenta si SUBE: frenar y chocar es conducir. ]]
                local conConductor = GetPedInVehicleSeat(veh, -1) ~= 0
                if a and ahoraMs - a.t < 400 and ahoraMs - ultimoParte > 10000
                   and NetworkHasControlOfEntity(veh) then
                    local salto = #(v - a.v)
                    if v.z > 6.0 or (not conConductor and salto > 9.0) then
                        ultimoParte = ahoraMs
                        -- Con red: si el parte falla, que no se lleve el hilo por delante.
                        local motivo = salto > 9.0 and ('salto de %.1f m/s'):format(salto) or ('sube a %.1f m/s'):format(v.z)
                        local ok, err = pcall(Parte, veh, ficha, a.v, v, motivo)
                        if not ok then TriggerServerEvent('origen_tow:cajanegra', 'PARTE ROTO: ' .. tostring(err)) end
                    end
                end

                anterior[veh] = { v = v, t = ahoraMs }
            end
        end

        for veh in pairs(anterior) do
            if not DoesEntityExist(veh) then anterior[veh] = nil end
        end

        Wait(espera)
    end
end)
