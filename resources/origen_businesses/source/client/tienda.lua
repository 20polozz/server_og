--[[ Tiendas como trabajo (30/09): caja registradora y clientes NPC.
     Lo que cuenta lo decide el servidor (source/server/tienda.lua); aquí se
     buscan las cajas (props) del negocio, se atiende la caja y se mueven los
     NPC de los que este cliente es el «dueño». ]]
local T = Config.Tienda

local MODELOS_CAJA = {}
for modelo in pairs(T.Cajas) do MODELOS_CAJA[#MODELOS_CAJA + 1] = modelo end

local cajas = {}           -- las cajas que se ven ahora: { obj, pos, rumbo, modelo, dependiente, cliente }
local huella = ''

local function EnTienda()
    local bid = LocalPlayer.state.isOnDuty
    if not bid then return nil end
    local business = Business.Get(tostring(bid))
    -- La registradora y los tickets pertenecen al sistema actual. En recetas
    -- se usa el TPV nuevo y no se deben abrir estas cajas ni generar NPC.
    if not business or business.productSystem == 'recipes'
        or not T.EsTienda(business, LocalPlayer.state.businessType) then return nil end
    return tostring(bid)
end

local function Dato(c)
    return { pos = { x = c.pos.x, y = c.pos.y, z = c.pos.z }, rumbo = c.rumbo, modelo = c.modelo }
end

local function Avisar(texto, tipo)
    lib.notify({ title = 'Tienda', description = texto, type = tipo or 'inform' })
end

-- ── Buscar las cajas ─────────────────────────────────────────────────────

CreateThread(function()
    while true do
        local bid = EnTienda()
        if not bid then
            cajas, huella = {}, ''
            Wait(2000)
        else
            local yo = GetEntityCoords(PlayerPedId())
            local vistas = {}
            for _, obj in ipairs(GetGamePool('CObject')) do
                local modelo = GetEntityModel(obj)
                if T.Cajas[modelo] then
                    local pos = GetEntityCoords(obj)
                    if #(pos - yo) < 25.0 then
                        local rumbo = GetEntityHeading(obj)
                        local dep, cli = T.PuestosCaja(modelo, pos, rumbo)
                        vistas[#vistas + 1] = { obj = obj, pos = pos, rumbo = rumbo, modelo = modelo, dependiente = dep, cliente = cli }
                    end
                end
            end
            -- Y las que el jefe ha puesto como punto (cajas que no son un prop)
            local negocio = Business.Get(bid)
            for _, p in pairs(negocio and negocio.points or {}) do
                if type(p) == 'table' and p.type == 'caja' then
                    local pos, rumbo = T.CajaDePunto(p.coords)
                    if pos and #(pos - yo) < 25.0 then
                        local dep, cli = T.PuestosCaja(T.PuntoCaja, pos, rumbo)
                        vistas[#vistas + 1] = { pos = pos, rumbo = rumbo, modelo = T.PuntoCaja, dependiente = dep, cliente = cli }
                    end
                end
            end
            table.sort(vistas, function(a, b) return a.pos.x + a.pos.y * 0.001 < b.pos.x + b.pos.y * 0.001 end)
            cajas = vistas
            local h = {}
            for i, c in ipairs(vistas) do h[i] = ('%.1f,%.1f'):format(c.pos.x, c.pos.y) end
            h = table.concat(h, ';')
            if h ~= huella and #vistas > 0 then
                local lista = {}
                for i, c in ipairs(vistas) do lista[i] = Dato(c) end
                TriggerServerEvent('origen_businesses:tienda:cajas', lista)
            end
            huella = h
            Wait(5000)
        end
    end
end)

-- ── La pantalla de la caja (ui: CajaTienda.vue) ──────────────────────────
--[[ El menú lateral de la casa, no los de ox_lib (el usuario, 30/09). El
     reparto de abrir y cerrar es el del proveedor (proveedor.lua): el foco se
     suelta ANTES de animar y la NUI confirma que ha llegado a pintarse. ]]

local ocupado = false      -- con la pantalla abierta no se enseña la tecla
local abierto = false
local nuiPintada = false
local generacion = 0
local cajaAbierta          -- la caja (props) que se está atendiendo
local ticketPendiente

local function MandarNui(accion, datos)
    SendNUIMessage({ action = accion, data = datos })
end

local function NpcEnCaja(c)
    local bid = EnTienda()
    local n = bid and GlobalState['origenTiendaNpc:' .. bid]
    return n and #(vec3(n.x, n.y, n.z) - c.pos) < 0.5 and n or nil
end

-- Teclear en la caja (antes la de rebuscar en un cubo). Probada en el personaje (30/09).
local ANIM = { Config.Tienda.Tareas.Anim.registradora.dict, Config.Tienda.Tareas.Anim.registradora.clip }

local function Animacion(activa)
    local ped = PlayerPedId()
    if activa then
        lib.requestAnimDict(ANIM[1])
        TaskPlayAnim(ped, ANIM[1], ANIM[2], 4.0, 4.0, -1, 49, 0, false, false, false)
    else
        StopAnimTask(ped, ANIM[1], ANIM[2], 2.0)
    end
end

local function CerrarPanel()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    Animacion(false)
    if not abierto then return end
    abierto = false
    ocupado = false
    cajaAbierta = nil
    local mia = generacion
    SetTimeout(280, function()
        if generacion ~= mia then return end
        MandarNui('tienda:cerrar', {})
    end)
end

-- Si administración cambia el negocio a recetas mientras alguien tiene la
-- caja o un ticket abierto, se cierra esta interfaz y se descarta ese ticket.
RegisterNetEvent('origen_businesses:client:reloadBusiness', function(data)
    if type(data) ~= 'table' or data.productSystem ~= 'recipes' then return end
    local bid = tostring(data.id or '')
    if ticketPendiente and tostring(ticketPendiente.businessId or '') == bid then
        ticketPendiente = nil
        if abierto and not cajaAbierta then CerrarPanel() end
    end
    if abierto and cajaAbierta and tostring(LocalPlayer.state.isOnDuty or '') == bid then
        CerrarPanel()
    end
end)

local function AbrirPanel(datos)
    if abierto then
        -- Ya en pantalla (otro ticket con el anterior abierto): se cambia en sitio
        MandarNui('tienda:datos', datos)
        return
    end
    abierto = true
    ocupado = true
    generacion = generacion + 1
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    MandarNui('tienda:abrir', datos)

    nuiPintada = false
    local mia = generacion
    SetTimeout(1500, function()
        if generacion ~= mia or not abierto or nuiPintada then return end
        print('^1[origen_businesses]^0 La caja de la tienda no llegó a pintarse. Se cierra y se suelta el foco.')
        CerrarPanel()
    end)
end

OrigenFoco.AlSoltar(function()
    if not abierto then return end
    abierto = false
    ocupado = false
    cajaAbierta = nil
    generacion = generacion + 1
    Animacion(false)
    MandarNui('tienda:cerrar', {})
end)

--- El empleado, detrás de la caja: lo que se vende y si hay un cliente esperando.
local function AbrirCaja(c)
    local r = lib.callback.await('origen_businesses:tienda:productos', false, Dato(c))
    if not r or not r.ok then return Avisar((r and r.mensaje) or 'No se puede abrir la caja ahora.', 'error') end
    cajaAbierta = c
    AbrirPanel({ modo = 'caja', negocio = r.negocio, productos = r.productos or {}, aviso = r.aviso,
        esperando = NpcEnCaja(c) ~= nil })

    -- Entra o se va el cliente de paso con la caja abierta
    CreateThread(function()
        local antes = NpcEnCaja(c) ~= nil
        while abierto and cajaAbierta == c do
            local ahora = NpcEnCaja(c) ~= nil
            if ahora ~= antes then
                antes = ahora
                MandarNui('tienda:datos', { esperando = ahora })
            end
            Wait(500)
        end
    end)
end

--- El cliente recibe el ticket (y /ticket lo vuelve a abrir mientras no caduque).
local function MostrarTicket()
    local t = ticketPendiente
    if not t or GetGameTimer() > t.hasta then ticketPendiente = nil return end
    local business = Business.Get(tostring(t.businessId or ''))
    if business and business.productSystem == 'recipes' then
        ticketPendiente = nil
        return
    end
    AbrirPanel({ modo = 'ticket', id = t.id, tienda = t.tienda, lineas = t.lineas, total = t.total,
        caduca = math.max(1, math.floor((t.hasta - GetGameTimer()) / 1000)) })
end

RegisterNetEvent('origen_businesses:tienda:ticket', function(t)
    if GetInvokingResource() then return end
    t.hasta = GetGameTimer() + (t.caduca or 45) * 1000
    ticketPendiente = t
    MostrarTicket()
end)

RegisterCommand('ticket', function() MostrarTicket() end, false)

--[[ Los nombres de los callback de NUI van sin tildes: son direcciones. ]]
RegisterNUICallback('tiendaPintado', function(_, cb)
    nuiPintada = true
    cb('ok')
end)

RegisterNUICallback('tiendaCerrar', function(_, cb)
    CerrarPanel()
    cb('ok')
end)

RegisterNUICallback('tiendaEmpezarCobro', function(_, cb)
    local c = cajaAbierta
    if not c then return cb({ ok = false, mensaje = 'La caja no está abierta.' }) end
    local r, err = lib.callback.await('origen_businesses:tienda:empezarCobro', false, Dato(c))
    if not r then return cb({ ok = false, mensaje = err }) end
    Animacion(true)
    cb({ ok = true, id = r.id, lineas = r.lineas, total = r.total })
end)

RegisterNUICallback('tiendaTerminarCobro', function(data, cb)
    local c = cajaAbierta
    Animacion(false)
    if not c or type(data) ~= 'table' then return cb({ ok = false }) end
    local ok, r = lib.callback.await('origen_businesses:tienda:terminarCobro', false, Dato(c), data.id, data.hecho == true)
    if ok then
        PlaySoundFrontend(-1, 'ROBBERY_MONEY_TOTAL', 'HUD_FRONTEND_CUSTOM_SOUNDSET', true)
        return cb({ ok = true, total = r })
    end
    cb({ ok = false, mensaje = r })
end)

RegisterNUICallback('tiendaEnviarTicket', function(data, cb)
    local c = cajaAbierta
    if not c or type(data) ~= 'table' then return cb({ ok = false }) end
    local ok, msg = lib.callback.await('origen_businesses:tienda:enviarTicket', false, Dato(c), data.pedido)
    cb({ ok = ok == true, mensaje = msg })
end)

RegisterNUICallback('tiendaPagar', function(data, cb)
    if type(data) ~= 'table' then return cb({ ok = false }) end
    ticketPendiente = nil
    local ok, msg = lib.callback.await('origen_businesses:tienda:pagarTicket', false, data.id, data.metodo)
    if ok then PlaySoundFrontend(-1, 'PURCHASE', 'HUD_LIQUOR_STORE_SOUNDSET', true) end
    cb({ ok = ok == true, mensaje = msg })
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and abierto then
        SetNuiFocus(false, false)
        Animacion(false)
    end
end)

-- ── La caja: marcador y tecla ────────────────────────────────────────────

CreateThread(function()
    local mostrando = false
    while true do
        local espera = 1000
        if EnTienda() and #cajas > 0 and not ocupado then
            local yo = GetEntityCoords(PlayerPedId())
            local cerca
            for _, c in ipairs(cajas) do
                local d = #(yo - vec3(c.dependiente.x, c.dependiente.y, c.dependiente.z + 1.0))
                if d < 8.0 then
                    espera = 0
                    -- Sin marcador en el suelo donde va el dependiente (el usuario,
                    -- 30/09: «no me gustan»): basta el texto de la E al acercarse
                    if NpcEnCaja(c) then
                        DrawMarker(2, c.cliente.x, c.cliente.y, c.cliente.z + 2.3, 0, 0, 0, 180.0, 0, 0, 0.25, 0.25, 0.25,
                            216, 27, 85, 200, true, true, 2, false, nil, nil, false)
                    end
                    if d < T.Distancias.caja then cerca = c end
                end
            end
            if cerca then
                if not mostrando then
                    lib.showTextUI('[E] Caja registradora', { icon = 'cash-register' })
                    mostrando = true
                end
                if IsControlJustReleased(0, 38) then
                    lib.hideTextUI(); mostrando = false
                    AbrirCaja(cerca)
                end
            elseif mostrando then
                lib.hideTextUI(); mostrando = false
            end
        elseif mostrando then
            lib.hideTextUI(); mostrando = false
        end
        Wait(espera)
    end
end)

-- ── Los NPC de los que este cliente es el dueño ──────────────────────────

local npcs = {}            -- id → { ped, bolsa, salida }

local function Plano(a, b)
    return #(vec2(a.x, a.y) - vec2(b.x, b.y))
end

--- Andar hasta un punto por la malla de navegación (con tope de tiempo).
local function Ir(ped, p, ms)
    TaskFollowNavMeshToCoord(ped, p.x, p.y, p.z + 1.0, 1.0, -1, 0.4, 0, 0.0)
    local fin = GetGameTimer() + (ms or 25000)
    while DoesEntityExist(ped) and GetGameTimer() < fin do
        if Plano(GetEntityCoords(ped), p) < 0.7 then return true end
        Wait(250)
    end
    return false
end

--- En una tienda sin planta: un sitio en la calle, a unos 14 m de la caja.
local function SitioFuera(caja)
    for i = 0, 7 do
        local a = math.rad(i * 45.0)
        local x, y = caja.x + math.cos(a) * 14.0, caja.y + math.sin(a) * 14.0
        local ok, p = GetSafeCoordForPed(x, y, caja.z + 1.0, true, 16)
        if ok and GetInteriorAtCoords(p.x, p.y, p.z) == 0 then return vec3(p.x, p.y, p.z - 1.0) end
    end
    return vec3(caja.x, caja.y, caja.z)
end

RegisterNetEvent('origen_businesses:tienda:npc', function(d)
    if GetInvokingResource() then return end
    local hash = joaat(d.modelo)
    lib.requestModel(hash, 10000)
    local ruta = d.ruta
    local inicio = ruta and ruta.fuera or SitioFuera(d.caja)
    local ped = CreatePed(4, hash, inicio.x, inicio.y, inicio.z + 1.0, 0.0, true, true)
    SetModelAsNoLongerNeeded(hash)
    if not ped or ped == 0 then return end
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedKeepTask(ped, true)
    SetPedCanBeTargetted(ped, false)
    local t = GetGameTimer() + 3000
    while not NetworkGetEntityIsNetworked(ped) and GetGameTimer() < t do Wait(50) end
    npcs[d.id] = { ped = ped, bolsa = d.bolsa, ruta = ruta, inicio = inicio }
    TriggerServerEvent('origen_businesses:tienda:npcCreado', d.id, NetworkGetNetworkIdFromEntity(ped))

    if ruta then
        Ir(ped, ruta.umbral, 15000)
        Ir(ped, ruta.dentro, 10000)
        for _, m in ipairs(ruta.mirar) do
            if not npcs[d.id] then return end
            Ir(ped, m.pos, 15000)
            SetEntityHeading(ped, m.pos.w)
            TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_WINDOW_SHOP_BROWSE', 0, true)
            Wait(m.seg * 1000)
            ClearPedTasks(ped)
        end
    end
    if not npcs[d.id] then return end
    Ir(ped, d.caja, 30000)
    --[[ Siempre en su sitio (30/09): la malla de navegación a veces lo deja a
         un par de metros del mostrador y el servidor no lo daba por llegado.
         El último tramo se le coloca, con los pies en el suelo de verdad. ]]
    if DoesEntityExist(ped) and Plano(GetEntityCoords(ped), d.caja) > 0.4 then
        local ok, suelo = GetGroundZFor_3dCoord(d.caja.x, d.caja.y, d.caja.z + 1.5, false)
        SetEntityCoords(ped, d.caja.x, d.caja.y, ok and suelo or (d.caja.z + 0.1), false, false, false, false)
    end
    SetEntityHeading(ped, d.caja.w)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    TriggerServerEvent('origen_businesses:tienda:npcEnCaja', d.id)
end)

RegisterNetEvent('origen_businesses:tienda:npcSalir', function(id, pagado)
    if GetInvokingResource() then return end
    local n = npcs[id]
    if not n or not DoesEntityExist(n.ped) then
        npcs[id] = nil
        TriggerServerEvent('origen_businesses:tienda:npcFin', id)
        return
    end
    local ped = n.ped
    ClearPedTasks(ped)
    if pagado then
        lib.requestAnimDict('mp_common')
        TaskPlayAnim(ped, 'mp_common', 'givetake1_a', 4.0, 4.0, 1500, 48, 0, false, false, false)
        Wait(1200)
        local hash = joaat(n.bolsa)
        lib.requestModel(hash, 5000)
        local p = GetEntityCoords(ped)
        n.obj = CreateObject(hash, p.x, p.y, p.z, true, true, false)
        SetModelAsNoLongerNeeded(hash)
        AttachEntityToEntity(n.obj, ped, GetPedBoneIndex(ped, 57005), 0.38, 0.0, -0.03, 0.0, 270.0, 60.0,
            true, true, false, true, 1, true)
    else
        lib.requestAnimDict('gestures@m@standing@casual')
        TaskPlayAnim(ped, 'gestures@m@standing@casual', 'gesture_damn', 4.0, 4.0, 1500, 48, 0, false, false, false)
        Wait(1200)
    end
    if n.ruta then
        Ir(ped, n.ruta.dentro, 20000)
        Ir(ped, n.ruta.umbral, 10000)
        Ir(ped, n.ruta.fuera, 10000)
    else
        Ir(ped, n.inicio, 25000)
    end
    Wait(1500)
    if n.obj and DoesEntityExist(n.obj) then DeleteEntity(n.obj) end
    if DoesEntityExist(ped) then DeleteEntity(ped) end
    npcs[id] = nil
    TriggerServerEvent('origen_businesses:tienda:npcFin', id)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, n in pairs(npcs) do
        if n.obj and DoesEntityExist(n.obj) then DeleteEntity(n.obj) end
        if n.ped and DoesEntityExist(n.ped) then DeleteEntity(n.ped) end
    end
end)
