--[[ ── Lo que se hace con las manos ───────────────────────────────────────────

     Despellejar, cargar a hombros, echar al vehículo, poner cebo y llamar
     con el reclamo. Cada acción la confirma el servidor antes de que pase
     nada que importe. ]]

local CARGA_DICT, CARGA_ANIM = 'missfinale_c2mcs_1', 'fin_c2_mcs_1_camman'

local textoPuesto = nil

local function Texto(t, icono)
    if t == textoPuesto then return end
    textoPuesto = t
    if t then
        lib.showTextUI(t, { position = 'left-center', icon = icono or 'paw' })
    else
        lib.hideTextUI()
    end
end

local function Control(ent, ms)
    local hasta = GetGameTimer() + (ms or 1500)
    NetworkRequestControlOfEntity(ent)
    while not NetworkHasControlOfEntity(ent) and GetGameTimer() < hasta do
        Wait(50)
        NetworkRequestControlOfEntity(ent)
    end
    return NetworkHasControlOfEntity(ent)
end

-- ── A hombros ─────────────────────────────────────────────────────────────

local function Cargar(netId, ent)
    Caza.Miga('cargar', netId)
    if not Control(ent) then
        C.Aviso('Caza', 'No puedes mover esa pieza ahora mismo.', 'error')
        TriggerServerEvent('origen_hunting:soltar', netId)
        return
    end
    pcall(lib.requestAnimDict, CARGA_DICT)
    -- Con el arma en la mano la G (47) está bloqueada por el seguro del arma
    -- de caza y no habría forma de soltar la pieza. Se enfunda POR el
    -- inventario, igual que hace él al volver a usar el arma: cambiarla a
    -- pelo le dejaba creyendo que seguía en la mano, y el primer uso para
    -- sacarla solo la «guardaba» (había que usarla dos veces).
    local enfundada = GetResourceState('origen_inventory') == 'started' and pcall(function()
        exports.origen_inventory:SetCurrentWeapon(nil)
        exports.origen_inventory:unarmedPed()
    end)
    if not enfundada then SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true) end
    DetachEntity(ent, true, false)
    AttachEntityToEntity(ent, cache.ped, GetPedBoneIndex(cache.ped, 24818),
        0.25, 0.1, 0.0, 0.0, 90.0, 180.0, false, false, false, false, 2, true)
    TaskPlayAnim(cache.ped, CARGA_DICT, CARGA_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
    C.carga = netId
end

local function Soltar(avisar)
    local netId = C.carga
    if not netId then return end
    Caza.Miga('soltar', netId)
    C.carga = nil
    local ent = C.EntidadDe(netId)
    if ent then
        DetachEntity(ent, true, true)
        local delante = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.9, 0.0)
        SetEntityCoords(ent, delante.x, delante.y, delante.z, false, false, false, false)
        PlaceObjectOnGroundProperly(ent)
    end
    StopAnimTask(cache.ped, CARGA_DICT, CARGA_ANIM, 1.0)
    if avisar ~= false then TriggerServerEvent('origen_hunting:soltar', netId) end
end
C.Soltar = Soltar

-- Mientras cargas: despacio, sin saltar ni disparar, y la animación puesta.
CreateThread(function()
    while true do
        if C.carga then
            local ent = C.EntidadDe(C.carga)
            if not ent or IsEntityDead(cache.ped) or IsPedInAnyVehicle(cache.ped, true) or IsPedRagdoll(cache.ped) then
                Soltar()
            else
                DisableControlAction(0, 21, true)   -- correr
                DisableControlAction(0, 22, true)   -- saltar
                DisableControlAction(0, 24, true)   -- disparar
                DisableControlAction(0, 25, true)   -- apuntar
                DisableControlAction(0, 23, true)   -- subir a un vehículo
                if not IsEntityPlayingAnim(cache.ped, CARGA_DICT, CARGA_ANIM, 3) then
                    TaskPlayAnim(cache.ped, CARGA_DICT, CARGA_ANIM, 8.0, -8.0, -1, 49, 0, false, false, false)
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- ── Vehículos ─────────────────────────────────────────────────────────────

local function VehiculoCerca()
    local veh = lib.getClosestVehicle(GetEntityCoords(cache.ped), 5.0, false)
    if not veh or not Config.Carga.clases[GetVehicleClass(veh)] then return nil end
    -- Hay que estar en la parte de atrás.
    local detras = GetOffsetFromEntityGivenWorldCoords(veh, GetEntityCoords(cache.ped))
    local min = GetModelDimensions(GetEntityModel(veh))
    if detras.y > min.y + 1.8 then return nil end
    return veh
end

local function PiezaEnVehiculo(veh)
    for netId in pairs(C.presas) do
        local ent = C.EntidadDe(netId)
        if ent and GetEntityAttachedTo(ent) == veh then return netId, ent end
    end
    return nil
end

local function AlVehiculo(veh)
    local netId = C.carga
    local ent = netId and C.EntidadDe(netId)
    if not ent then return end
    local ok, motivo = lib.callback.await('origen_hunting:alVehiculo', false, netId, VehToNet(veh))
    if not ok then
        C.Aviso('Caza', motivo or 'No se puede cargar ahí.', 'error')
        return
    end
    C.carga = nil
    Caza.Miga('al vehiculo', netId, GetVehicleClass(veh))
    StopAnimTask(cache.ped, CARGA_DICT, CARGA_ANIM, 1.0)
    local min, max = GetModelDimensions(GetEntityModel(veh))
    DetachEntity(ent, true, false)
    AttachEntityToEntity(ent, veh, 0, 0.0, min.y + 1.1, max.z * 0.25 + 0.2,
        0.0, 0.0, 90.0, false, false, false, false, 2, true)
    C.Aviso('Caza', 'Pieza cargada. Llévala al comprador del campamento.', 'success')
end

local function DelVehiculo(netId, ent)
    local ok = lib.callback.await('origen_hunting:delVehiculo', false, netId)
    if not ok then
        C.Aviso('Caza', 'No puedes bajar esa pieza.', 'error')
        return
    end
    Cargar(netId, ent)
end

-- ── Despellejar ───────────────────────────────────────────────────────────

local function Despellejar(netId, ent, info)
    Caza.Miga('despellejar', netId)
    TaskTurnPedToFaceEntity(cache.ped, ent, 800)
    Wait(800)

    local legendaria = info and info.legendaria
    local hecho = lib.progressCircle({
        duration = legendaria and 12000 or 7000,
        label = 'Despellejando…',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search' },
        prop = { model = `prop_cs_bowie_knife`, bone = 57005, pos = vec3(0.11, 0.02, -0.02), rot = vec3(-90.0, 0.0, 0.0) },
    })
    if not hecho then return end

    local r = lib.callback.await('origen_hunting:despellejar', false, netId)
    if not r or not r.ok then
        C.Aviso('Caza', r and r.mensaje or 'No se pudo despellejar.', 'error')
        return
    end

    local carne = r.carne > 0 and (' y %d de carne'):format(r.carne) or ''
    C.Aviso(r.legendaria and '¡Trofeo legendario!' or 'Pieza lista',
        ('Piel de %s %s%s · +%d XP'):format(r.especie:lower(), Caza.Estrellas(r.calidad), carne, r.xp),
        'success', 6000)
end

-- ── El bucle de las manos ─────────────────────────────────────────────────

local function PiezaCerca(yo)
    local mejor, dMejor, entMejor
    for netId, p in pairs(C.presas) do
        if p.muerte and netId ~= C.carga then
            local ent = C.EntidadDe(netId)
            if ent and IsEntityDead(ent) and not IsEntityAttached(ent) then
                local d = #(GetEntityCoords(ent) - yo)
                if d < 2.4 and (not dMejor or d < dMejor) then mejor, dMejor, entMejor = netId, d, ent end
            end
        end
    end
    return mejor, entMejor
end

local function Tocable(p)
    local m = p.muerte
    if not m then return false, nil end
    if GetCloudTimeAsInt() >= (m.exclusivaHasta or 0) then return true end
    if m.abatidaPor == cache.serverId or (p.info and p.info.cazador == cache.serverId) then return true end
    if C.MiGrupo(m.abatidaPor) or (p.info and C.MiGrupo(p.info.cazador)) then return true end
    return false, 'La pieza es de quien la abatió. Espera un poco.'
end

CreateThread(function()
    while true do
        local espera = 400
        local texto = nil

        if C.activa and not C.panelAbierto and not IsPedInAnyVehicle(cache.ped, false) and not IsEntityDead(cache.ped) then
            local yo = GetEntityCoords(cache.ped)

            if C.carga then
                espera = 0
                local veh = VehiculoCerca()
                if veh and not PiezaEnVehiculo(veh) then
                    texto = '[E] Cargar en el vehículo  \n[G] Soltar'
                    if IsControlJustPressed(0, 38) then AlVehiculo(veh) end
                else
                    texto = '[G] Soltar la pieza'
                end
                if IsControlJustPressed(0, 47) then Soltar() end
            else
                local netId, ent = PiezaCerca(yo)
                if netId then
                    espera = 0
                    local p = C.presas[netId]
                    local ficha = p.info or {}
                    local puede, motivo = Tocable(p)
                    local calidad = Caza.Estrellas(p.muerte.calidad)
                    local cargable = not Config.Carga.noSeCargan[ficha.especie or '']
                    texto = ('%s %s  \n[E] Despellejar%s'):format(ficha.nombre or 'Pieza', calidad,
                        cargable and '  \n[G] Cargar a hombros' or '')

                    if IsControlJustPressed(0, 38) or (cargable and IsControlJustPressed(0, 47)) then
                        local cargar = not IsControlJustPressed(0, 38)
                        Texto(nil)
                        if not puede then
                            C.Aviso('Caza', motivo, 'error')
                        elseif cargar then
                            local ok, m = lib.callback.await('origen_hunting:cargar', false, netId)
                            if ok then Cargar(netId, ent) else C.Aviso('Caza', m or 'No puedes cargarla.', 'error') end
                        else
                            Despellejar(netId, ent, ficha)
                        end
                    end
                else
                    local veh = VehiculoCerca()
                    local enVeh, entVeh = nil, nil
                    if veh then enVeh, entVeh = PiezaEnVehiculo(veh) end
                    if enVeh then
                        espera = 0
                        texto = '[E] Bajar la pieza del vehículo'
                        if IsControlJustPressed(0, 38) then
                            Texto(nil)
                            DelVehiculo(enVeh, entVeh)
                        end
                    end
                end
            end
        end

        Texto(texto, C.carga and 'hand' or 'paw')
        Wait(espera)
    end
end)

-- ── Cebo ──────────────────────────────────────────────────────────────────

local function QuitarCebo()
    if C.cebo and C.cebo.prop and DoesEntityExist(C.cebo.prop) then DeleteEntity(C.cebo.prop) end
    C.cebo = nil
end

RegisterNetEvent('origen_hunting:ponerCebo', function()
    if not C.activa or not C.zona then return end

    local hecho = lib.progressCircle({
        duration = Config.Cebo.duracionColocar,
        label = 'Colocando el cebo…',
        position = 'bottom',
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { scenario = 'WORLD_HUMAN_GARDENER_PLANT' },
    })
    ClearPedTasks(cache.ped)
    if not hecho then return end

    if not lib.callback.await('origen_hunting:gastarCebo', false) then
        C.Aviso('Cebo', 'No te queda cebo.', 'error')
        return
    end

    QuitarCebo()
    local pos = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 0.7, 0.0)
    local ok, z = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 1.0, false)
    local coords = vec3(pos.x, pos.y, ok and z or pos.z - 1.0)

    local modelo = `prop_feed_sack_01`
    local prop
    if pcall(lib.requestModel, modelo, 3000) then
        -- Local: el saco solo lo ve quien caza. El de antes era de red y se
        -- quedaba en el mundo para todos si el jugador se iba.
        prop = CreateObject(modelo, coords.x, coords.y, coords.z, false, false, false)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)
        SetModelAsNoLongerNeeded(modelo)
    end

    local hasta = GetGameTimer() + Config.Cebo.dura * 1000
    C.cebo = { coords = coords, hasta = hasta, prop = prop }

    local n = C.Atraer(coords, Config.Cebo.alcance, Config.Cebo.dura, true)
    Caza.Miga('cebo', n)
    C.Aviso('Cebo colocado', n > 0
        and 'Una presa ha captado el olor y viene hacia aquí. Aléjate y espera agachado.'
        or 'El olor atraerá a la próxima presa hacia aquí.', 'success', 6000)

    SetTimeout(Config.Cebo.dura * 1000, function()
        if C.cebo and C.cebo.hasta == hasta then QuitarCebo() end
    end)
end)

AddEventHandler('origen_hunting:finJornada', QuitarCebo)

-- ── Reclamo ───────────────────────────────────────────────────────────────

RegisterNetEvent('origen_hunting:usarReclamo', function()
    if not C.activa then return end
    pcall(lib.requestAnimDict, 'rcmnigel1c')
    TaskPlayAnim(cache.ped, 'rcmnigel1c', 'hailing_whistle_waive_a', 8.0, -8.0, 2500, 48, 0, false, false, false)

    local n = C.Atraer(GetEntityCoords(cache.ped), Config.Reclamo.alcance, 40, false)
    Caza.Miga('reclamo', n)
    C.Aviso('Reclamo', n > 0
        and 'La presa te ha oído y se acerca. Prepárate.'
        or 'No hay ninguna presa a tiro. La próxima saldrá antes.', n > 0 and 'success' or 'inform', 5000)
end)

-- ── El arma de caza ───────────────────────────────────────────────────────

local ARMAS = Caza.ArmaPorHash
local avisado = 0

local function Bloquear()
    DisableControlAction(0, 24, true)
    DisableControlAction(0, 47, true)
    DisableControlAction(0, 58, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 143, true)
    DisablePlayerFiring(cache.playerId, true)
end

local function Avisar(texto)
    if not IsDisabledControlJustPressed(0, 24) or GetGameTimer() < avisado then return end
    avisado = GetGameTimer() + 3000
    lib.notify({ id = 'caza_arma', title = 'Caza', description = texto, type = 'error', duration = 2000 })
end

CreateThread(function()
    while true do
        local espera = 800
        local arma = GetSelectedPedWeapon(cache.ped)
        if ARMAS[arma] then
            espera = 0
            if not C.activa then
                Bloquear()
                Avisar('Inicia tu jornada en el campamento para usar el arma de caza.')
            elseif not C.zona then
                Bloquear()
                Avisar('El arma de caza solo se usa dentro de una zona de caza.')
            else
                local apuntando = IsPlayerFreeAiming(cache.playerId)
                local _, ent = GetEntityPlayerIsFreeAimingAt(cache.playerId)
                if not apuntando then
                    Bloquear()
                    Avisar('Apunta (clic derecho) antes de disparar.')
                elseif ent and ent ~= 0 and IsEntityAPed(ent) and IsPedAPlayer(ent) then
                    Bloquear()
                    Avisar('No se dispara a personas con un arma de caza.')
                end
            end
        end
        Wait(espera)
    end
end)

-- ── El HUD ────────────────────────────────────────────────────────────────

local function Viento(desde, hasta)
    local v = GetWindDirection()
    local dir = hasta - desde
    local largo = #dir
    if largo < 0.1 then return 'cruzado' end
    local dot = (v.x * dir.x + v.y * dir.y) / largo
    if dot > 0.5 then return 'contra' end
    if dot < -0.5 then return 'favor' end
    return 'cruzado'
end

CreateThread(function()
    local mostrado = false
    while true do
        Wait(500)
        local ver = C.activa and not C.panelAbierto and not C.adminAbierto and not IsPauseMenuActive()
        if ver then
            mostrado = true
            local e = C.estado
            local yo = GetEntityCoords(cache.ped)
            local presa = nil
            local cerca = C.PresaCercana()
            if cerca then
                local ent, p = cerca.ent, cerca.p
                local muerta = IsEntityDead(ent)
                local d = cerca.d
                presa = {
                    nombre = p.info and p.info.nombre or 'Presa',
                    legendaria = p.info and p.info.legendaria or false,
                    propia = p.propia == true,
                    estado = muerta and 'abatida' or (GetEntityHealth(ent) < GetEntityMaxHealth(ent) and 'herida' or 'viva'),
                    metros = math.floor(d / 10 + 0.5) * 10,
                    calidad = p.muerte and p.muerte.calidad or nil,
                    viento = not muerta and Viento(yo, GetEntityCoords(ent)) or nil,
                }
            end

            local torneo = e.torneo
            if torneo and torneo.activo then
                local pasado = math.floor((GetGameTimer() - C.estadoRecibido) / 1000)
                torneo = {
                    nombre = torneo.nombre,
                    modo = torneo.modo, unidad = torneo.unidad, objetivo = torneo.objetivo,
                    puesto = torneo.puesto, puntos = torneo.puntos, total = torneo.total,
                    quedan = math.max(0, (torneo.quedan or 0) - pasado),
                }
            else
                torneo = nil
            end

            SendNUIMessage({
                accion = 'hud',
                datos = {
                    visible = true,
                    zona = C.zona and C.zona.nombre or nil,
                    nivel = e.nivel or 1,
                    nivelNombre = e.nivelNombre or 'Novato',
                    xp = e.xp or 0,
                    xpDesde = e.xpDesde or 0,
                    xpHasta = e.xpHasta,
                    licencia = e.licencia == true,
                    encargos = { hechos = e.encargosHechos or 0, total = e.encargosTotal or 0 },
                    presa = presa,
                    sigilo = GetPedStealthMovement(cache.ped),
                    cebo = C.cebo and math.max(0, math.floor((C.cebo.hasta - GetGameTimer()) / 1000)) or nil,
                    carga = C.carga ~= nil,
                    grupo = C.grupo and #(C.grupo.miembros or {}) or 0,
                    torneo = torneo,
                },
            })
        elseif mostrado then
            mostrado = false
            SendNUIMessage({ accion = 'hud', datos = { visible = false } })
        end
    end
end)

-- ── Al terminar ───────────────────────────────────────────────────────────

AddEventHandler('origen_hunting:finJornada', function()
    if C.carga then Soltar() end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if textoPuesto then lib.hideTextUI() end
    if C.carga then Soltar(false) end
    QuitarCebo()
end)
