-- Muebles especiales de guarida (ver config/especiales.lua y
-- custom/server/especiales.lua). Junto a uno de ellos, la E:
--   · sienta en las sillas y taburetes, o tumba en los colchones (es una
--     animación del propio personaje: no hay nada que pedir al servidor);
--   · en la silla de interrogatorio, con un esposado al lado, lo deja atado a
--     ella; y con alguien ya atado, lo suelta. Eso lo decide el servidor.
-- Al atado se le sienta, se le deja quieto y no puede levantarse: no se le
-- hace daño ni se le toca la vida.
local C = Config.Especiales
local T = C.textos

local piezas = {}       -- los de la casa en la que se está: { id, zona, clave, entidad, datos }
local ajenas = {}       -- muebles de esa casa que ya tienen su propia E: { entidad, radio }
local casaActual = nil
local pedida = nil      -- casa de la que ya se ha preguntado quién está atado
local atados = {}       -- ['zona:id'] = id de servidor del que está atado ahí
local uso = nil         -- sentado o tumbado por su cuenta: { modo, pieza, desde }
local atadoEn = nil     -- atado a una silla: { clave, desde }
local menuAjeno = false
local conTexto = false
local ocupado = false

-- (el árbitro lo suelta si se queda enganchado: custom/client/tecla_e.lua)
AddEventHandler('origen_housing:sinMenuAjeno', function() menuAjeno = false end)

AddEventHandler('qv2:suppressHud', function(fuera)
    menuAjeno = fuera == true
end)

-- El cartel y la tecla los lleva el árbitro común (custom/client/tecla_e.lua):
-- aquí solo se ofrece la E, o se retira.
local function Texto(texto)
    if not texto then Tecla.Retirar('especiales') end
end

local function Muerto(ped)
    -- (Qbox apunta la muerte en `isDead`; `dead` es de otros núcleos)
    return IsEntityDead(ped) or LocalPlayer.state.dead == true or LocalPlayer.state.isDead == true
end

-- ── Los muebles de la casa ──────────────────────────────────────────────

-- Si otro módulo ya da una E a ese mueble (plataformas, ascensores, almacenes,
-- armarios, teles), a qué distancia la da. Junto a uno de esos, este calla.
local function RadioAjeno(modelo, entidad)
    local min, max = GetModelDimensions(GetEntityModel(entidad))
    local medio = math.max(max.x - min.x, max.y - min.y) / 2
    local G, S = Config.Giratoria, Config.Ascensores
    local gira = G and G.Es(modelo)
    if gira then return (G.modelos[gira].radio or medio) + (G.margen or 1.5) end
    local clase = S and S.Clase and S.Clase(modelo)
    if clase then
        local a = S.modelos and S.modelos[modelo]
        return (a and a.radio) or (S[clase] and S[clase].radio) or medio + 1.5
    end
    local item = type(modelo) == 'string' and __indexFurniture[modelo] or nil
    local tipo = item and item.type
    if tipo == 'stash' or tipo == 'wardrobe' or tipo == 'tv' then return math.max(1.3, medio + 1.2) end
    return nil
end

local function Recoger()
    local id = currentInteriorHouseID or currentExteriorHouseID
    local house = id and House.get(id) or nil
    local casa = house and tostring(house.id) or nil
    if casa ~= casaActual then
        casaActual, atados, pedida = casa, {}, nil
    end
    local lista, otras = {}, {}
    if house then
        for zona, muebles in pairs({ interior = house.interiorFurniture, exterior = house.exteriorFurniture }) do
            for mid, m in pairs(muebles or {}) do
                if type(m) == 'table' and m.entity and DoesEntityExist(m.entity) then
                    local nombre = C.Es(m.model)
                    if nombre then
                        lista[#lista + 1] = {
                            id = tostring(mid), zona = zona, clave = zona .. ':' .. tostring(mid),
                            entidad = m.entity, datos = C.modelos[nombre],
                        }
                    else
                        local radio = RadioAjeno(m.model, m.entity)
                        if radio then otras[#otras + 1] = { entidad = m.entity, radio = radio } end
                    end
                end
            end
        end
    end
    piezas, ajenas = lista, otras

    -- quién está atado en esta casa: se pregunta una vez, al ver su primera silla
    if casa and pedida ~= casa and #lista > 0 then
        pedida = casa
        local todas = lib.callback.await('origen_housing:especiales:todas', false, casa)
        if casaActual ~= casa then return end
        for clave, sujeto in pairs(type(todas) == 'table' and todas or {}) do
            if atados[clave] == nil then atados[clave] = tonumber(sujeto) end
        end
    end
end

local function PiezaDe(clave)
    for _, p in ipairs(piezas) do
        if p.clave == clave and DoesEntityExist(p.entidad) then return p end
    end
    return nil
end

-- Dónde va el cuerpo en ese mueble y mirando a dónde
local function Punto(p, modo)
    local a = (modo == 'tumbado' and p.datos.cama) or p.datos.asiento or {}
    local min, max = GetModelDimensions(GetEntityModel(p.entidad))
    local x = (min.x + max.x) / 2 + (a.x or 0.0)
    local y = (min.y + max.y) / 2 + (a.y or 0.0)
    local z
    if modo == 'tumbado' then
        z = max.z + (a.z or 0.0)
    else
        z = min.z + (a.z or C.altoAsiento)
    end
    local c = GetOffsetFromEntityInWorldCoords(p.entidad, x + 0.0, y + 0.0, z + 0.0)
    return c, (GetEntityHeading(p.entidad) + (a.giro or 180.0)) % 360.0
end

local function JuntoAAjena(yo)
    for _, o in ipairs(ajenas) do
        if DoesEntityExist(o.entidad) then
            local c = GetEntityCoords(o.entidad)
            if #(vector3(yo.x - c.x, yo.y - c.y, 0.0)) <= o.radio and math.abs(yo.z - c.z) < 3.0 then return true end
        end
    end
    return false
end

local function Ocupado(c, ped)
    for _, otro in ipairs(GetGamePool('CPed')) do
        if otro ~= ped then
            local q = GetEntityCoords(otro)
            if math.abs(q.z - c.z) < 1.6 and #(vector3(q.x - c.x, q.y - c.y, 0.0)) < C.ocupado then return true end
        end
    end
    return false
end

-- ── Sentarse y tumbarse (por su cuenta) ─────────────────────────────────

local function Sentar(ped, p)
    local c, h = Punto(p, 'sentado')
    TaskStartScenarioAtPosition(ped, C.escenario, c.x, c.y, c.z, h, 0, true, true)
end

local function Usar(p, modo)
    local ped = PlayerPedId()
    local c, h = Punto(p, modo)
    if Ocupado(c, ped) then
        Custom.Notify('Está ocupado', 'error', 3000)
        return
    end
    if modo == 'tumbado' then
        if not pcall(lib.requestAnimDict, C.tumbado.dict) then return end
        ClearPedTasksImmediately(ped)
        SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
        SetEntityHeading(ped, h)
        TaskPlayAnim(ped, C.tumbado.dict, C.tumbado.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
        FreezeEntityPosition(ped, true)
    else
        Sentar(ped, p)
    end
    uso = { modo = modo, pieza = p, desde = GetGameTimer() }
end

local function Levantar()
    if not uso then return end
    local ped = PlayerPedId()
    if uso.modo == 'tumbado' then FreezeEntityPosition(ped, false) end
    ClearPedTasks(ped)
    uso = nil
end

-- Un fotograma sentado o tumbado: si algo le saca de ahí (otro script, un
-- golpe, que quiten el mueble), se da por levantado sin más.
local function Mantener()
    local ped = PlayerPedId()
    local p = uso.pieza
    if Muerto(ped) or IsPedInAnyVehicle(ped, false) or not DoesEntityExist(p.entidad) then
        if uso.modo == 'tumbado' then FreezeEntityPosition(ped, false) end
        uso = nil
        return
    end
    if uso.modo == 'tumbado' then
        if not IsEntityPlayingAnim(ped, C.tumbado.dict, C.tumbado.clip, 3) then
            TaskPlayAnim(ped, C.tumbado.dict, C.tumbado.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
        end
    elseif GetGameTimer() - uso.desde > 2500 and not IsPedUsingScenario(ped, C.escenario) then
        uso = nil       -- se ha levantado andando
    end
end

-- ── Atado a la silla ────────────────────────────────────────────────────

local function Desatarme()
    if not atadoEn then return end
    atadoEn = nil
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    if IsPedUsingScenario(ped, C.escenario) then ClearPedTasks(ped) end
end

local function Atarme(clave)
    if atadoEn then return end
    if uso then Levantar() end
    local yo = { clave = clave, desde = GetGameTimer() }
    atadoEn = yo
    CreateThread(function()
        local mirado, sentadoEn, fijo, visto = 0, nil, false, false
        while atadoEn == yo do
            local ped = PlayerPedId()
            local ahora = GetGameTimer()
            if ahora - mirado > 1000 then
                mirado = ahora
                local p = PiezaDe(clave)
                if p then
                    visto = true
                    if Muerto(ped) then
                        -- de eso se ocupa quien lleva las muertes; el servidor le suelta
                        if fijo then FreezeEntityPosition(ped, false) fijo = false end
                    elseif not IsPedUsingScenario(ped, C.escenario) and (not sentadoEn or ahora - sentadoEn > 3000) then
                        if fijo then FreezeEntityPosition(ped, false) fijo = false end
                        if IsEntityAttached(ped) then DetachEntity(ped, true, false) end
                        Sentar(ped, p)
                        sentadoEn = ahora
                    elseif not fijo and sentadoEn and ahora - sentadoEn > 1500 and IsPedUsingScenario(ped, C.escenario) then
                        FreezeEntityPosition(ped, true)
                        fijo = true
                    end
                elseif not visto and ahora - yo.desde > C.atar.esperaPieza then
                    TriggerServerEvent('origen_housing:especiales:noPuedo')
                    break
                end
            end
            for _, control in ipairs(C.bloqueados) do
                DisableControlAction(0, control, true)
            end
            Wait(0)
        end
        if atadoEn == yo then Desatarme() end
    end)
end

RegisterNetEvent('origen_housing:especiales:atado', function(casa, clave, sujeto)
    if type(clave) ~= 'string' then return end
    local yo = GetPlayerServerId(PlayerId())
    sujeto = tonumber(sujeto)
    if sujeto == yo then
        atados[clave] = sujeto
        Atarme(clave)
        return
    end
    if atadoEn and atadoEn.clave == clave then Desatarme() end
    if tostring(casa) == casaActual then atados[clave] = sujeto end
end)

-- El servidor pregunta si este jugador está esposado (para dejar que le aten)
lib.callback.register('origen_housing:especiales:esposado', function()
    local ped = PlayerPedId()
    if IsPedCuffed(ped) or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) then return true end
    for _, recurso in ipairs({ 'origen_police', 'origen_ilegalv2' }) do
        if GetResourceState(recurso) == 'started' then
            local ok, si = pcall(function() return exports[recurso]:IsHandcuffed() end)
            if ok and si == true then return true end
        end
    end
    return false
end)

-- Un esposado al lado, para ofrecer «Atar» (quien lo decide es el servidor)
local function EsposadoCerca(ped, yo)
    local mejor, cuanto = nil, nil
    for _, jugador in ipairs(GetActivePlayers()) do
        local otro = GetPlayerPed(jugador)
        if otro ~= ped and otro ~= 0 then
            local d = #(GetEntityCoords(otro) - yo)
            if d <= C.atar.vistazo and (not cuanto or d < cuanto)
                and (IsPedCuffed(otro) or IsEntityPlayingAnim(otro, 'mp_arresting', 'idle', 3)) then
                mejor, cuanto = GetPlayerServerId(jugador), d
            end
        end
    end
    return mejor
end

local function Pedir(nombre, aviso, ...)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local res = lib.callback.await(nombre, false, ...)
    if type(res) ~= 'table' or not res.ok then
        Custom.Notify(type(res) == 'table' and res.aviso or aviso, 'error', 4000)
    end
    SetTimeout(C.atar.ritmo, function() ocupado = false end)
end

-- ── Bucles ──────────────────────────────────────────────────────────────

CreateThread(function()
    while true do
        Recoger()
        -- fuera de la casa nadie sigue atado (el servidor también le suelta)
        if atadoEn and not casaActual and GetGameTimer() - atadoEn.desde > C.atar.esperaPieza then Desatarme() end
        Wait(1000)
    end
end)

-- Qué ofrece la E ahora mismo: { texto, hacer }. Se mira tres veces por segundo.
local function Oferta()
    if #piezas == 0 or ocupado or menuAjeno or (Furniture and Furniture.active) or currentDoorID
        or IsNuiFocused() or IsPauseMenuActive() then return nil end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or Muerto(ped) or IsPedRagdoll(ped) then return nil end
    local yo = GetEntityCoords(ped)
    local cerca, cuanto, modoCerca = nil, nil, nil
    for _, p in ipairs(piezas) do
        if DoesEntityExist(p.entidad) then
            local modo = p.datos.cama and 'tumbado' or 'sentado'
            local c = Punto(p, modo)
            local d = #(vector3(yo.x - c.x, yo.y - c.y, 0.0))
            if d <= C.alcance and math.abs(yo.z - c.z) < 1.6 and (not cuanto or d < cuanto) then
                cerca, cuanto, modoCerca = p, d, modo
            end
        end
    end
    if not cerca or JuntoAAjena(yo) then return nil end

    local p = cerca
    if p.datos.atar then
        if atados[p.clave] then
            return { texto = T.soltar, hacer = function()
                Pedir('origen_housing:especiales:soltar', 'No se le puede soltar', casaActual, p.zona, p.id)
            end }
        end
        -- quien está esposado no ata a nadie
        local esposado = IsPedCuffed(ped) or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
        local objetivo = not esposado and EsposadoCerca(ped, yo) or nil
        if objetivo then
            return { texto = T.atar, prioridad = 58, dist = cuanto, hacer = function()
                Pedir('origen_housing:especiales:atar', 'No se le puede atar', casaActual, p.zona, p.id, objetivo)
            end }
        end
    end
    return { texto = modoCerca == 'tumbado' and T.tumbarse or T.sentarse, dist = cuanto, hacer = function() Usar(p, modoCerca) end }
end

CreateThread(function()
    local oferta, mirada = nil, 0
    while true do
        local espera = 400
        if atadoEn then
            Texto(nil)
        elseif uso then
            espera = 0
            Mantener()
            if uso then
                -- (la tecla se mira en el árbitro. Sentado, levantarse va antes que cualquier otra cosa a mano)
                Tecla.Ofrecer('especiales', { texto = T.levantarse, prioridad = 90, dist = 0.0, hacer = function()
                    Levantar()
                    Texto(nil)
                end })
            else
                Texto(nil)
            end
        elseif #piezas > 0 then
            local ahora = GetGameTimer()
            if ahora - mirada >= 300 then
                mirada = ahora
                oferta = Oferta()
            end
            if oferta then
                espera = 150
                local hacer = oferta.hacer
                Tecla.Ofrecer('especiales', { texto = oferta.texto, prioridad = oferta.prioridad or 45, dist = oferta.dist or 0.0, hacer = function()
                    oferta, mirada = nil, GetGameTimer()
                    hacer()
                end })
            else
                Texto(nil)
            end
        else
            oferta = nil
            Texto(nil)
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if atadoEn or (uso and uso.modo == 'tumbado') then FreezeEntityPosition(PlayerPedId(), false) end
    -- (sentado en el escenario de la silla o tumbado: de pie, que la silla puede no volver)
    if atadoEn or uso then ClearPedTasks(PlayerPedId()) end
end)
