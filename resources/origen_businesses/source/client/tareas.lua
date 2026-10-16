--[[ Tareas del turno en las tiendas (30/09): reponer, limpiar neveras, fregar y
     sacar la basura. Lo que cuenta lo decide el servidor
     (source/server/tareas.lua); aquí se ve la lista, se va al sitio, se pulsa
     E, se hace la animación y se lleva la caja o la bolsa.

     Nada pintado en el suelo (el usuario, 30/09: «estos blips del suelo no me
     gustan»): una flechita flotando a media altura sobre cada tarea. ]]
local T = Config.Tienda
local TA = T.Tareas
local A = TA.Anim

--- Estas animaciones también las usa la vista previa al colocar un punto.
function TareasAnimar(ped, clave)
    local a = A[clave]
    if not a then return end
    if a.escenario then
        TaskStartScenarioInPlace(ped, a.escenario, 0, true)
        return
    end
    lib.requestAnimDict(a.dict)
    TaskPlayAnim(ped, a.dict, a.clip, 4.0, 4.0, -1, 1, 0, false, false, false)
end

function TareasAnimando(ped, clave)
    local a = A[clave]
    if not a then return true end
    if a.escenario then return IsPedUsingScenario(ped, a.escenario) end
    return IsEntityPlayingAnim(ped, a.dict, a.clip, 3)
end

-- En Nación solo dejamos cargadas las animaciones de vista previa; no se
-- registran HUD, interacciones ni objetos de las tareas de turno.
if not TA.Habilitadas then return end

local datos = false        -- lo último que ha mandado el servidor
local ocupado = false
local bolsaTarea           -- la tarea de basura cuya bolsa llevo
local texto                -- lo que dice ahora el aviso de la E
local distContenedor       -- con la bolsa en la mano: metros al cubo más cercano (false si no hay)

local function Avisar(t, tipo)
    lib.notify({ title = 'Tienda', description = t, type = tipo or 'inform' })
end

--- El aviso de abajo: con la tecla si hay algo que hacer; sin ella, si es una pista.
local function Texto(t, tecla)
    local clave = t and (t .. (tecla and '|E' or ''))
    if clave == texto then return end
    texto = clave
    if not t then Custom.HideText()
    elseif tecla then Custom.DrawText(t, 'E')
    else lib.showTextUI(t) end
end

local function EnTienda()
    local bid = LocalPlayer.state.isOnDuty
    if not bid then return false end
    return T.EsTienda(Business.Get(tostring(bid)), LocalPlayer.state.businessType)
end

-- ── La lista en pantalla (ui: TareasTienda.vue) ──────────────────────────

local ultimoEnvio = ''

local function MandarLista()
    if not datos or not EnTienda() then
        if ultimoEnvio ~= 'fuera' then
            SendNUIMessage({ action = 'tareas:datos', data = { visible = false } })
            ultimoEnvio = 'fuera'
        end
        return
    end
    local yo = GetEntityCoords(PlayerPedId())
    local mio = GetPlayerServerId(PlayerId())
    local lista = {}
    for _, t in ipairs(datos.tareas or {}) do
        lista[#lista + 1] = {
            id = t.id, label = t.label, icono = t.icono, paga = t.paga,
            estado = (t.de == mio and 'mia') or (t.de and 'otro') or 'libre',
            metros = math.floor(#(yo - vec3(t.x, t.y, t.z + 1.0)) + 0.5),
        }
    end
    table.sort(lista, function(a, b) return a.metros < b.metros end)
    local d = {
        visible = true, negocio = datos.negocio, tareas = lista, cobrado = datos.cobrado or 0,
        tope = datos.tope or TA.Tope.dinero, llevo = datos.llevo or false,
        contenedor = distContenedor,
    }
    local j = json.encode(d)
    if j ~= ultimoEnvio then
        SendNUIMessage({ action = 'tareas:datos', data = d })
        ultimoEnvio = j
    end
end

RegisterNetEvent('origen_businesses:tareas:lista', function(d)
    if GetInvokingResource() then return end
    datos = d
    if not d then bolsaTarea = nil end
    MandarLista()
end)

-- Al entrar de servicio (o al reiniciar el recurso ya de servicio)
CreateThread(function()
    Wait(2000)
    if EnTienda() then lib.callback('origen_businesses:tareas:pedir', false, function() end) end
end)

-- ── Lo que se lleva en las manos (la caja o la bolsa) ────────────────────
--[[ Se pinta en la mano de todos los que lo llevan (state bag tiendaLleva),
     para que los compañeros también lo vean. Objeto local, sin red. ]]
local enMano = {}          -- serverId → { ent, que }

local function Quitar(sid)
    local m = enMano[sid]
    if m and DoesEntityExist(m.ent) then DeleteEntity(m.ent) end
    enMano[sid] = nil
end

local function Poner(sid, ped, que)
    local m = enMano[sid]
    if m and m.que == que and DoesEntityExist(m.ent) then return end
    Quitar(sid)
    local a = que == 'caja' and A.caja or A.bolsa
    local hash = joaat(a.prop)
    if not lib.requestModel(hash, 5000) then return end
    local c = GetEntityCoords(ped)
    local ent = CreateObject(hash, c.x, c.y, c.z, false, false, false)
    SetModelAsNoLongerNeeded(hash)
    SetEntityCollision(ent, false, false)
    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, a.hueso), a.pos.x, a.pos.y, a.pos.z, a.rot.x, a.rot.y, a.rot.z,
        true, true, false, true, 1, true)
    enMano[sid] = { ent = ent, que = que }
end

CreateThread(function()
    while true do
        local vistos = {}
        local yo = GetEntityCoords(PlayerPedId())
        for _, id in ipairs(GetActivePlayers()) do
            local sid = GetPlayerServerId(id)
            local que = Player(sid).state.tiendaLleva
            local ped = GetPlayerPed(id)
            if que and ped ~= 0 and #(GetEntityCoords(ped) - yo) < 80.0 then
                vistos[sid] = true
                -- Mientras hace una tarea con las manos, la caja se esconde
                if not (id == PlayerId() and ocupado) then Poner(sid, ped, que) else Quitar(sid) end
            end
        end
        for sid in pairs(enMano) do
            if not vistos[sid] then Quitar(sid) end
        end

        -- Andar con ello: la animación de llevar, si se ha cortado
        local que = LocalPlayer.state.tiendaLleva
        if que and not ocupado then
            local a = que == 'caja' and A.caja or A.bolsa
            local ped = PlayerPedId()
            if not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
                lib.requestAnimDict(a.dict)
                TaskPlayAnim(ped, a.dict, a.clip, 4.0, 4.0, -1, a.flag, 0, false, false, false)
            end
        elseif not que then
            local ped = PlayerPedId()
            if IsEntityPlayingAnim(ped, A.caja.dict, A.caja.clip, 3) then StopAnimTask(ped, A.caja.dict, A.caja.clip, 2.0) end
            if IsEntityPlayingAnim(ped, A.bolsa.dict, A.bolsa.clip, 3) then StopAnimTask(ped, A.bolsa.dict, A.bolsa.clip, 2.0) end
        end
        Wait(400)
    end
end)

-- ── Hacer una tarea ──────────────────────────────────────────────────────

local function Barra(t, extra)
    local op = {
        duration = math.floor(TA.Tipos[t.tipo].seg * 1000),
        label = TA.Tipos[t.tipo].label,
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
    }
    for k, v in pairs(extra or {}) do op[k] = v end
    return lib.progressBar(op)
end

local function Hacer(t)
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local ok, err = lib.callback.await('origen_businesses:tareas:empezar', false, t.id)
    if not ok then
        ocupado = false
        if err then Avisar(err, 'error') end
        return
    end

    local ped = PlayerPedId()
    SetEntityHeading(ped, GetHeadingFromVector_2d(t.x - GetEntityCoords(ped).x, t.y - GetEntityCoords(ped).y))
    local hecho
    local a = A[t.tipo == 'papelera' and 'coger' or t.tipo]
    if a.escenario then
        -- Fregona y trapo: el escenario trae su objeto en la mano
        TaskStartScenarioInPlace(ped, a.escenario, 0, true)
        hecho = Barra(t)
        ClearPedTasks(ped)
    else
        hecho = Barra(t, { anim = { dict = a.dict, clip = a.clip, flag = a.flag } })
    end

    if not hecho then
        TriggerServerEvent('origen_businesses:tareas:dejar', t.id)
        ocupado = false
        return
    end

    local bien, pago, fase = lib.callback.await('origen_businesses:tareas:terminar', false, t.id)
    ocupado = false
    if not bien then
        if pago then Avisar(pago, 'error') end
        return
    end
    if fase == 'bolsa' then
        bolsaTarea = t.id
        Avisar('Llévala a un contenedor de la calle.', 'inform')
    elseif (pago or 0) > 0 then
        Avisar(('%s: +%d $'):format(TA.Tipos[t.tipo].label, pago), 'success')
    end
end

local function CogerCaja()
    if ocupado then return end
    ocupado = true
    Texto(nil)
    local hecho = lib.progressBar({
        duration = math.floor(TA.Trastienda.seg * 1000), label = 'Coger una caja', canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = { dict = A.cogerCaja.dict, clip = A.cogerCaja.clip, flag = A.cogerCaja.flag },
    })
    if hecho then
        local ok, err = lib.callback.await('origen_businesses:tareas:caja', false)
        if not ok and err then Avisar(err, 'error') end
    end
    ocupado = false
end

local function Tirar(contenedor)
    if ocupado or not bolsaTarea then return end
    ocupado = true
    Texto(nil)
    local ped = PlayerPedId()
    TaskTurnPedToFaceCoord(ped, contenedor.x, contenedor.y, contenedor.z, 600)
    Wait(600)
    lib.requestAnimDict(A.tirar.dict)
    TaskPlayAnim(ped, A.tirar.dict, A.tirar.clip, 4.0, 4.0, A.tirar.ms, A.tirar.flag, 0, false, false, false)
    Wait(A.tirar.ms)
    local bien, pago = lib.callback.await('origen_businesses:tareas:terminar', false, bolsaTarea,
        { x = contenedor.x, y = contenedor.y, z = contenedor.z })
    ocupado = false
    if not bien then
        if pago then Avisar(pago, 'error') end
        return
    end
    bolsaTarea = nil
    if (pago or 0) > 0 then Avisar(('Sacar la basura: +%d $'):format(pago), 'success') end
end

-- ── Los contenedores de la calle (para la bolsa) ─────────────────────────

local contenedores = {}    -- los cercanos, se buscan cada 2 s mientras llevas la bolsa

CreateThread(function()
    while true do
        if LocalPlayer.state.tiendaLleva == 'bolsa' then
            local yo = GetEntityCoords(PlayerPedId())
            local lista = {}
            for _, obj in ipairs(GetGamePool('CObject')) do
                if TA.Contenedores[GetEntityModel(obj)] then
                    local p = GetEntityCoords(obj)
                    if #(p - yo) < TA.ContenedorMax then lista[#lista + 1] = p end
                end
            end
            contenedores = lista
            Wait(2000)
        else
            contenedores = {}
            Wait(1500)
        end
    end
end)

-- ── El bucle: flechas, la E y la lista ───────────────────────────────────

local function Flecha(x, y, z, r, g, b)
    DrawMarker(2, x, y, z, 0.0, 0.0, 0.0, 180.0, 0.0, 0.0, 0.18, 0.18, 0.18, r, g, b, 190, true, true, 2, false, nil, nil, false)
end

CreateThread(function()
    local ultimaLista = 0
    while true do
        local espera = 800
        if datos and EnTienda() then
            local ped = PlayerPedId()
            local yo = GetEntityCoords(ped)
            local mio = GetPlayerServerId(PlayerId())
            local lleva = LocalPlayer.state.tiendaLleva
            local aviso, accion

            if lleva == 'bolsa' then
                -- Con la bolsa: el contenedor más cercano de fuera
                espera = 0
                local mejor, dmin
                for _, c in ipairs(contenedores) do
                    local d = #(c - yo)
                    if not dmin or d < dmin then mejor, dmin = c, d end
                end
                distContenedor = dmin and math.floor(dmin + 0.5) or false
                if mejor then
                    Flecha(mejor.x, mejor.y, mejor.z + 1.6, 0, 0, 0)
                    if dmin < 2.6 then aviso, accion = 'Tirar la bolsa', function() Tirar(mejor) end end
                end
            else
                distContenedor = nil
                for _, t in ipairs(datos.tareas or {}) do
                    local p = vec3(t.x, t.y, t.z + 1.0)
                    local d = #(p - yo)
                    if d < 25.0 then
                        espera = 0
                        if not t.de or t.de == mio then
                            Flecha(t.x, t.y, t.z + 1.25, 216, 27, 85)
                            if d < TA.Distancia and not aviso then
                                if t.tipo == 'estanteria' and datos.trastienda and lleva ~= 'caja' then
                                    aviso = 'Coge antes una caja en la trastienda'
                                elseif t.tipo ~= 'estanteria' and lleva then
                                    aviso = 'Deja antes lo que llevas'
                                else
                                    aviso, accion = ('%s · %d $'):format(t.label, t.paga), function() Hacer(t) end
                                end
                            end
                        end
                    end
                end
                -- La trastienda, si hay algo que reponer y no llevas nada
                local tr = datos.trastienda
                if tr and not lleva and not aviso then
                    local hay = false
                    for _, t in ipairs(datos.tareas or {}) do if t.tipo == 'estanteria' and not t.de then hay = true break end end
                    if hay then
                        local d = #(vec3(tr.x, tr.y, tr.z + 1.0) - yo)
                        if d < 25.0 then
                            espera = 0
                            Flecha(tr.x, tr.y, tr.z + 1.25, 220, 221, 224)
                            if d < TA.Distancia then aviso, accion = 'Coger una caja', CogerCaja end
                        end
                    end
                end
            end

            if ocupado then aviso = nil end
            Texto(aviso, accion ~= nil)
            if accion and not ocupado and IsControlJustReleased(0, 38) then
                CreateThread(accion)
            end

            if GetGameTimer() - ultimaLista > 1000 then
                ultimaLista = GetGameTimer()
                MandarLista()
            end
        else
            Texto(nil)
            if datos and not EnTienda() then datos = false end
            MandarLista()
        end
        Wait(espera)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for sid in pairs(enMano) do Quitar(sid) end
    if texto then Custom.HideText() end
end)
