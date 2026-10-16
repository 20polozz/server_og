--[[ ── Lo que llevas en las manos ─────────────────────────────────────────────

     La caja o el saco se pinta en TODOS los clientes a partir de la state bag
     `granjaCarga` del jugador que la lleva: cada uno pega un prop local a la
     mano de ese ped. Tu propio personaje, además, anda con los brazos
     cargados y no puede correr, saltar, pelear ni subirse a nada.

     Aquí van también las interacciones a pie con la carga:
       palé de la parcela     E dejar / coger       G llenar la regadera
       carro del tractor      E cargar / sacar      G descargar en la báscula
       báscula                E entregar
       en cualquier sitio     X soltar (vuelve al palé de su parcela) ]]

Manos = {}

local TECLA_E, TECLA_G, TECLA_X = 38, 47, 73

-- ── Los props de todos ────────────────────────────────────────────────────

local pegados = {}      -- [serverId] = { ent, ped, clave, dentro = {} }

--[[ Cada prop de manos que se crea queda apuntado aquí con su dueño. Antes el
     manejador de la state bag y el repaso de cada segundo podían crear a la vez
     el mismo prop (los dos esperan a que cargue el modelo): el segundo pisaba
     al primero en `pegados` y el primero se quedaba pegado a la mano para
     siempre, aunque el jugador ya no llevara nada. Ahora solo crea quien tiene
     el turno (`turno[sid]`), y el repaso borra cualquier prop apuntado que no
     sea el vigente. ]]
local creados = {}      -- [entidad] = serverId
local turno = {}        -- [serverId] = número de la última petición
local cargando = {}     -- [serverId] = true mientras se crea

local function BorrarEntidad(ent)
    creados[ent] = nil
    if ent and DoesEntityExist(ent) then
        DetachEntity(ent, false, false)
        DeleteEntity(ent)
    end
end

local function Soltar(sid)
    turno[sid] = (turno[sid] or 0) + 1
    local p = pegados[sid]
    if not p then return end
    for _, e in ipairs(p.dentro or {}) do BorrarEntidad(e) end
    BorrarEntidad(p.ent)
    pegados[sid] = nil
end

local function Clave(estado)
    return ('%s:%s:%.2f'):format(estado.tipo, tostring(estado.cultivo), tonumber(estado.lleno) or 0)
end

--- Lo que ese jugador lleva AHORA según su state bag (o nil).
local function Llevando(sid)
    local estado = Player(sid).state.granjaCarga
    if type(estado) == 'table' and estado.tipo then return estado end
    return nil
end

local function Pegar(sid, estado)
    local cfg = Config.Carga[estado.tipo]
    local jugador = GetPlayerFromServerId(sid)
    if not cfg or jugador == -1 or cargando[sid] then return end
    local ped = GetPlayerPed(jugador)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    local hash = GetHashKey(cfg.modelo)

    Soltar(sid)
    local mio = turno[sid]
    cargando[sid] = true
    local ok = Relleno.Cargar(hash)
    cargando[sid] = nil
    -- Mientras cargaba pudo soltarlo, cambiar de carga o crearlo otro: entonces
    -- este ya no vale.
    local ahora = Llevando(sid)
    if not ok or turno[sid] ~= mio or pegados[sid] or not ahora or Clave(ahora) ~= Clave(estado)
        or GetPlayerPed(jugador) ~= ped then
        return
    end

    local c = GetEntityCoords(ped)
    local ent = Rastro.Marcar(CreateObject(hash, c.x, c.y, c.z + 0.2, false, false, false))
    creados[ent] = sid
    SetEntityCollision(ent, false, false)
    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, cfg.hueso), cfg.pos.x, cfg.pos.y, cfg.pos.z,
        cfg.rot.x, cfg.rot.y, cfg.rot.z, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(hash)
    -- Apuntado ANTES de rellenar la caja: rellenar espera a otro modelo.
    local p = { ent = ent, ped = ped, dentro = {}, clave = Clave(estado) }
    pegados[sid] = p
    if estado.tipo == 'caja' then
        local dentro = Relleno.Llenar(ent, estado.cultivo, estado.lleno)
        if pegados[sid] == p then
            p.dentro = dentro
            for _, e in ipairs(dentro) do creados[e] = sid end
        else
            for _, e in ipairs(dentro) do if DoesEntityExist(e) then DeleteEntity(e) end end
        end
    end
end

AddStateBagChangeHandler('granjaCarga', nil, function(bagName, _, valor)
    local jugador = GetPlayerFromStateBagName(bagName)
    if not jugador or jugador == 0 then return end
    local sid = GetPlayerServerId(jugador)
    if type(valor) == 'table' and valor.tipo then
        if pegados[sid] and pegados[sid].clave == Clave(valor) then return end
        Soltar(sid)
        -- La state bag de este jugador aún no se ha escrito cuando llega el
        -- aviso: Pegar la vuelve a leer, así que se espera un tick.
        SetTimeout(0, function() Pegar(sid, valor) end)
    else
        Soltar(sid)
    end
end)

-- Repaso: el ped cambia al reaparecer, y quien entra en rango trae ya su
-- state bag puesta sin disparar el manejador.
CreateThread(function()
    while true do
        Wait(1000)
        for sid, p in pairs(pegados) do
            local jugador = GetPlayerFromServerId(sid)
            local ahora = jugador ~= -1 and Llevando(sid)
            if jugador == -1 or GetPlayerPed(jugador) ~= p.ped or not DoesEntityExist(p.ent)
                or not ahora or Clave(ahora) ~= p.clave then
                Soltar(sid)
            end
        end
        -- Cualquier prop de manos que no sea el vigente de su jugador, fuera.
        for ent, sid in pairs(creados) do
            local p = pegados[sid]
            local vigente = p and (p.ent == ent)
            if not vigente and p then
                for _, e in ipairs(p.dentro or {}) do if e == ent then vigente = true break end end
            end
            if not vigente then BorrarEntidad(ent) end
        end
        for _, jugador in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(jugador)
            local estado = Llevando(sid)
            if estado and not pegados[sid] and not cargando[sid] then
                CreateThread(function() Pegar(sid, estado) end)
            end
        end
    end
end)

-- ── Tu personaje cargado ──────────────────────────────────────────────────

CreateThread(function()
    local anim = Config.Carga.caja.anim
    while true do
        if G.carga then
            local ped = cache.ped
            if not IsEntityPlayingAnim(ped, anim.dict, anim.clip, 3) and not G.ocupado then
                lib.requestAnimDict(anim.dict)
                TaskPlayAnim(ped, anim.dict, anim.clip, 4.0, 4.0, -1, 49, 0, false, false, false)
            end
            DisableControlAction(0, 21, true)   -- correr
            DisableControlAction(0, 22, true)   -- saltar
            DisableControlAction(0, 23, true)   -- subir a un vehículo
            DisableControlAction(0, 24, true)   -- atacar
            DisableControlAction(0, 25, true)   -- apuntar
            DisableControlAction(0, 44, true)   -- cubrirse
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            if IsPedDeadOrDying(ped, true) or IsPedInAnyVehicle(ped, false) then
                lib.callback.await('origen_farming:tirar', false)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

AddEventHandler('origen_farming:c:carga', function()
    if not G.carga then
        local anim = Config.Carga.caja.anim
        if IsEntityPlayingAnim(cache.ped, anim.dict, anim.clip, 3) then
            StopAnimTask(cache.ped, anim.dict, anim.clip, 1.0)
        end
    end
end)

-- ── La tarjeta de la carga ────────────────────────────────────────────────

local ultimaCarga = ''
function Manos.Tarjeta(acciones)
    local c = G.carga
    local datos
    if c and not G.panelAbierto then
        datos = {
            visible = true, tipo = c.tipo, nombre = c.nombre, unidades = c.unidades,
            capacidad = c.capacidad, calidades = c.calidades, acciones = acciones or {},
        }
    else
        datos = { visible = false }
    end
    local huella = json.encode(datos)
    if huella ~= ultimaCarga then
        ultimaCarga = huella
        G.Nui('carga', datos)
    end
end

-- ── Interacciones a pie ───────────────────────────────────────────────────

local ocupado = false

local function Hacer(fn)
    if ocupado then return end
    ocupado = true
    CreateThread(function()
        local ok, err = pcall(fn)
        if not ok then print('[granja] ' .. tostring(err)) end
        ocupado = false
    end)
end

local function Respuesta(r, bien)
    if not r then return end
    if r.mensaje then G.Aviso(r.mensaje, r.ok and 'success' or 'error')
    elseif r.ok and bien then G.Aviso(bien, 'success') end
end

--- El palé de acopio que tienes al lado (los acopios son de todos).
--- Devuelve la configuración y cuántas cajas tiene.
local function PaleCerca(pos)
    for _, a in ipairs(Config.Acopios) do
        if Granja.Plano(pos, a.pos) <= Config.Carga.distancia - 0.8 and math.abs(pos.z - a.pos.z) < 8.0 then
            local v = G.acopios[a.id]
            return a, v and #v.cajas or 0
        end
    end
    return nil
end

local function GrifoCerca(pos)
    for _, g in ipairs(Config.Cooperativa.grifos) do
        if Granja.Plano(pos, g) <= 2.5 and math.abs(pos.z - g.z) < 4.0 then return true end
    end
    return false
end

--- La camioneta de la cooperativa que tienes a mano: a menos de 2,5 m de su
--- parte de atrás, que es por donde se carga.
local function CarroCerca(pos)
    local mejor, mejorD, mejorEnt
    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local est = Entity(veh).state.granjaVehiculo
        if est and est.tipo == 'camioneta' then
            local min = GetModelDimensions(GetEntityModel(veh))
            local atras = GetOffsetFromEntityInWorldCoords(veh, 0.0, min.y, 0.0)
            local d = #(atras - pos)
            if d < 2.5 and (not mejorD or d < mejorD) then
                mejor, mejorD, mejorEnt = NetworkGetNetworkIdFromEntity(veh), d, veh
            end
        end
    end
    return mejor, mejorEnt
end

--- El depósito de un acopio: la válvula del riego de tus parcelas de esa
--- franja y el agua para la regadera. Devuelve el acopio y cuántas parcelas
--- tuyas riega.
local function ValvulaCerca(pos)
    for _, a in ipairs(Config.Acopios) do
        if Granja.Plano(pos, a.deposito) <= 1.7 and math.abs(pos.z - a.deposito.z) < 8.0 then
            local mias = 0
            for _, cfg in ipairs(Config.Parcelas) do
                if cfg.acopio == a.id and G.EsMia(G.parcelas[cfg.id]) then mias = mias + 1 end
            end
            return a, mias
        end
    end
    return nil
end

local function EnBascula(coords, extra)
    local b = Config.Cooperativa.bascula
    return Granja.Plano(coords, b.coords) <= b.radio + (extra or 0) and math.abs(coords.z - b.coords.z) < 8.0
end

--[[ El aro de la báscula, pegado al suelo. Antes era un marker plano a
     `coords.z - 1.0` y el terreno del cruce está más alto: quedaba enterrado y
     la gente no encontraba dónde entregar la cosecha. Ahora cada tramo del aro
     va a la altura real del suelo (medida una vez) y encima flota una flecha. ]]
local aro, aroZ
local TRAMOS = 36

local function MedirAro()
    local b = Config.Cooperativa.bascula
    local function Suelo(x, y)
        local ok, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, b.coords.z + 15.0, false)
        if not ok or math.abs(z - b.coords.z) > 15.0 then return nil end
        return z + 0.08
    end
    local zc = Suelo(b.coords.x, b.coords.y)
    if not zc then return false end
    local puntos = {}
    for i = 0, TRAMOS do
        local a = i / TRAMOS * 2 * math.pi
        local cx, cy = math.cos(a), math.sin(a)
        local fuera = { b.coords.x + cx * b.radio, b.coords.y + cy * b.radio }
        local dentro = { b.coords.x + cx * (b.radio - 0.45), b.coords.y + cy * (b.radio - 0.45) }
        puntos[i] = {
            fuera = vec3(fuera[1], fuera[2], Suelo(fuera[1], fuera[2]) or zc),
            dentro = vec3(dentro[1], dentro[2], Suelo(dentro[1], dentro[2]) or zc),
        }
    end
    aro, aroZ = puntos, zc
    return true
end

local function PintarBascula(conCosecha)
    if not aro and not MedirAro() then return end
    local b = Config.Cooperativa.bascula
    local al = conCosecha and 200 or 90
    for i = 0, TRAMOS - 1 do
        local p, q = aro[i], aro[i + 1]
        -- Visto desde arriba en sentido antihorario: dentro → fuera → fuera siguiente → dentro siguiente.
        DrawPoly(p.dentro.x, p.dentro.y, p.dentro.z, p.fuera.x, p.fuera.y, p.fuera.z, q.fuera.x, q.fuera.y, q.fuera.z, 216, 27, 85, al)
        DrawPoly(p.dentro.x, p.dentro.y, p.dentro.z, q.fuera.x, q.fuera.y, q.fuera.z, q.dentro.x, q.dentro.y, q.dentro.z, 216, 27, 85, al)
    end
    if conCosecha then
        DrawMarker(0, b.coords.x, b.coords.y, aroZ + 2.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            0.9, 0.9, 0.9, 216, 27, 85, 190, true, false, 2, true, nil, nil, false)
    end
end

-- Si se sale de la zona se vuelve a medir al volver (el suelo puede no estar cargado la primera vez).
AddEventHandler('origen_farming:c:cerca', function(cerca)
    if not cerca then aro, aroZ = nil, nil end
end)

function Manos.LlenarRegadera()
    local r = lib.callback.await('origen_farming:llenarEmpezar', false)
    if not r or not r.ok then return Respuesta(r) end
    local a = Config.Acciones.llenar
    local hecho = lib.progressCircle({
        duration = r.duracion, label = 'Llenando la regadera', position = 'bottom', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = a.anim.dict, clip = a.anim.clip, flag = 1 },
    })
    ClearPedTasks(cache.ped)
    if not hecho then return end
    local fin = lib.callback.await('origen_farming:llenarTerminar', false)
    if fin and fin.ok then
        if fin.mochila then G.mochila = fin.mochila end
        G.Aviso('Regadera llena.', 'success')
    else
        Respuesta(fin)
    end
end

function Manos.DescargarCarro(netId)
    local r = lib.callback.await('origen_farming:descargarEmpezar', false, netId)
    if not r or not r.ok then return Respuesta(r) end
    local hecho = lib.progressCircle({
        duration = r.duracion, label = 'Descargando en la báscula', position = 'bottom', canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
    })
    ClearPedTasks(cache.ped)
    if not hecho then return end
    Respuesta(lib.callback.await('origen_farming:descargarTerminar', false))
end

CreateThread(function()
    while true do
        local espera = 500
        local ped = cache.ped
        local pos = GetEntityCoords(ped)
        local acciones = {}
        -- El aviso de acción de este fotograma: { tecla, texto, alt }
        local aviso

        -- La báscula ya no está en la cooperativa (28/09: patio de los silos,
        -- a ~300 m): también cuenta estar junto a ella.
        local cercaDeAlgo = G.cerca or Granja.Plano(pos, Config.Cooperativa.centro) < 80.0
            or Granja.Plano(pos, Config.Cooperativa.bascula.coords) < 40.0
        if cercaDeAlgo and not G.panelAbierto and not IsPedInAnyVehicle(ped, false) and not G.ocupado then
            espera = 0
            local carga = G.carga
            local paleCfg, paleV = PaleCerca(pos)
            local carroNet, carroEnt = CarroCerca(pos)
            local bascula = EnBascula(pos, 1.0)

            if carga then
                -- Con las manos llenas las teclas van en la tarjeta de la carga.
                acciones[#acciones + 1] = { tecla = 'X', texto = 'Soltar' }
                if bascula then
                    acciones[#acciones + 1] = { tecla = 'E', texto = 'Entregar en la báscula' }
                    if IsControlJustReleased(0, TECLA_E) then
                        Hacer(function() Respuesta(lib.callback.await('origen_farming:entregar', false)) end)
                    end
                elseif carroNet then
                    acciones[#acciones + 1] = { tecla = 'E', texto = 'Cargar en la camioneta' }
                    if IsControlJustReleased(0, TECLA_E) then
                        Hacer(function() Respuesta(lib.callback.await('origen_farming:cargarCarro', false, carroNet)) end)
                    end
                elseif paleCfg and carga.tipo ~= 'paca' then
                    local lleno = paleV >= Config.Carga.paleMax
                    acciones[#acciones + 1] = { tecla = 'E', texto = ('Dejar en el acopio (%d/%d)'):format(paleV,
                        Config.Carga.paleMax), apagada = lleno or nil }
                    if not lleno and IsControlJustReleased(0, TECLA_E) then
                        Hacer(function() Respuesta(lib.callback.await('origen_farming:dejarPale', false, paleCfg.id)) end)
                    end
                end
                if IsControlJustReleased(0, TECLA_X) then
                    Hacer(function() Respuesta(lib.callback.await('origen_farming:tirar', false)) end)
                end
            else
                if carroNet then
                    local cajas = Entity(carroEnt).state.granjaCajas or {}
                    if #cajas > 0 then
                        local alt
                        if EnBascula(GetEntityCoords(carroEnt), 4.0) then
                            alt = { 'G', 'Descargar todo en la báscula' }
                            if IsControlJustReleased(0, TECLA_G) then Hacer(function() Manos.DescargarCarro(carroNet) end) end
                        end
                        aviso = { 'E', ('Sacar caja de la camioneta (%d)'):format(#cajas), alt }
                        if IsControlJustReleased(0, TECLA_E) then
                            Hacer(function() Respuesta(lib.callback.await('origen_farming:sacarCarro', false, carroNet)) end)
                        end
                    end
                elseif ValvulaCerca(pos) then
                    -- El depósito: E el riego de tus parcelas de la franja, G la regadera.
                    local vCfg, mias = ValvulaCerca(pos)
                    local r = G.mochila and G.mochila.regadera
                    local llenar = r and r.carga < r.max and { 'G', ('Llenar regadera (%d/%d)'):format(r.carga, r.max) } or nil
                    if mias > 0 then
                        aviso = { 'E', ('Encender riego de tus parcelas · %s · %s c/u'):format(Granja.Duracion(Config.Riego.duracion), Granja.Dinero(Config.Riego.precio)), llenar }
                        if IsControlJustReleased(0, TECLA_E) then
                            Hacer(function() Respuesta(lib.callback.await('origen_farming:valvula', false, vCfg.id)) end)
                        end
                    else
                        aviso = llenar
                    end
                    if llenar and IsControlJustReleased(0, TECLA_G) then Hacer(Manos.LlenarRegadera) end
                elseif paleCfg then
                    -- El acopio: E coger una caja (si hay), G comprar una paca de heno.
                    local paca = { 'G', ('Coger paca de heno · %s'):format(Granja.Dinero(Config.Carga.paca.precio)) }
                    if paleV > 0 then
                        aviso = { 'E', ('Coger caja del acopio (%d)'):format(paleV), paca }
                        if IsControlJustReleased(0, TECLA_E) then
                            Hacer(function() Respuesta(lib.callback.await('origen_farming:cogerPale', false, paleCfg.id)) end)
                        end
                    else
                        aviso = paca
                    end
                    if IsControlJustReleased(0, TECLA_G) then
                        Hacer(function() Respuesta(lib.callback.await('origen_farming:cogerPaca', false, paleCfg.id)) end)
                    end
                elseif GrifoCerca(pos) then
                    local r = G.mochila and G.mochila.regadera
                    if r and r.carga < r.max then
                        aviso = { 'G', ('Llenar regadera (%d/%d)'):format(r.carga, r.max) }
                        if IsControlJustReleased(0, TECLA_G) then Hacer(Manos.LlenarRegadera) end
                    end
                end
            end

            -- La báscula se ve siempre desde cerca; con cosecha encima, más fuerte y con la flecha.
            if Granja.Plano(pos, Config.Cooperativa.bascula.coords) < 60.0 then
                PintarBascula((carga and carga.tipo ~= 'paca') or carroNet ~= nil)
            end
        end

        Manos.Tarjeta(acciones)

        if aviso and not G.carga then
            G.Ayuda('manos', aviso[1], aviso[2], aviso[3])
        else
            G.QuitarAyuda('manos')
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for sid in pairs(pegados) do Soltar(sid) end
    for ent in pairs(creados) do BorrarEntidad(ent) end
end)
