--[[ El médico ilegal: la ped, la tecla y la animación.

     Quién puede, cuánto cuesta y si hay policía cerca lo decide el servidor
     (server/medico.lua). Aquí se pone la ped donde diga la lista, se enseña
     la tecla a quien toca y se pinta al médico agachado sobre el caído.

     Solo reanima: a quien está de pie no le ofrece nada. ]]

local medicos = {}        -- [id] = datos que manda el servidor
local peds    = {}        -- [id] = ped creada
local puntos  = {}        -- [id] = lib.point
local ocupado = {}        -- [id] = true mientras atiende (no se le toca la postura)
local textoDe = nil       -- id del médico cuyo texto de ayuda está puesto
local textoPuesto = nil
local pidiendo = false

local VER       = 45.0    -- a qué distancia aparece la ped
local CERCA     = 2.5     -- de pie, para que salga la tecla
local CERCA_TIRADO = 5.0  -- tirado no se llega andando: vale donde te dejen
local TECLA_PAGAR  = 38   -- E, el que acompaña
local TECLA_TIRADO = 74   -- H: la E y la G las usa la pantalla de muerte

local REPOSO = 'WORLD_HUMAN_STAND_IMPATIENT'
local ATENDER = 'CODE_HUMAN_MEDIC_TEND_TO_DEAD'

local function Dinero(n)
    local s = tostring(math.floor(tonumber(n) or 0))
    local salida = s:reverse():gsub('(%d%d%d)', '%1.'):reverse()
    return (salida:gsub('^%.', '')) .. ' $'
end

local function Precio(m)
    return Dinero(m.price) .. (m.account == 'black_money' and ' en negro' or '')
end

local function QuitarTexto(id)
    if textoDe ~= nil and (id == nil or textoDe == id) then
        HelpText.HideHelpText()
        textoDe, textoPuesto = nil, nil
    end
end

local function PonerTexto(id, texto)
    if textoDe == id and textoPuesto == texto then return end
    HelpText.ShowHelpText(texto)
    textoDe, textoPuesto = id, texto
end

local function EstoyTirado()
    if LocalPlayer.state.dead == true then return true end
    if GetResourceState('origen_ambulancejob') == 'started' then
        local ok, muerto = pcall(function() return exports.origen_ambulancejob:isDead() end)
        if ok and muerto then return true end
    end
    return false
end

-- ── La ped ───────────────────────────────────────────────────────────────────

local function APuesto(id)
    local m, ped = medicos[id], peds[id]
    if not m or not ped or not DoesEntityExist(ped) then return end
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, m.pos_x, m.pos_y, m.pos_z, false, false, false, false)
    SetEntityHeading(ped, m.pos_h)
    FreezeEntityPosition(ped, true)
    TaskStartScenarioInPlace(ped, REPOSO, 0, true)
end

local function Crear(id)
    local m = medicos[id]
    if not m or (peds[id] and DoesEntityExist(peds[id])) then return end

    local modelo = joaat(m.ped_model or 's_m_m_doctor_01')
    if not IsModelInCdimage(modelo) then modelo = joaat("s_m_m_doctor_01") end
    if not pcall(lib.requestModel, modelo, 8000) then return end
    -- Mientras cargaba el modelo se puede haber salido del sitio o cambiado la lista.
    if not medicos[id] or (peds[id] and DoesEntityExist(peds[id])) then
        SetModelAsNoLongerNeeded(modelo)
        return
    end

    local ped = CreatePed(4, modelo, m.pos_x, m.pos_y, m.pos_z, m.pos_h, false, true)
    SetModelAsNoLongerNeeded(modelo)
    if not ped or ped == 0 then return end

    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCanRagdoll(ped, false)
    SetPedDiesWhenInjured(ped, false)
    peds[id] = ped
    APuesto(id)
end

local function Borrar(id)
    if peds[id] and DoesEntityExist(peds[id]) then DeleteEntity(peds[id]) end
    peds[id], ocupado[id] = nil, nil
    QuitarTexto(id)
end

-- ── A quién atiende ──────────────────────────────────────────────────────────

--- El caído más cercano al médico (que no sea yo), o nil.
local function CaidoJuntoA(m)
    local donde = vector3(m.pos_x, m.pos_y, m.pos_z)
    local yo = PlayerId()
    local mejor, mejorDist
    for _, jugador in ipairs(GetActivePlayers()) do
        if jugador ~= yo then
            local sid = GetPlayerServerId(jugador)
            local ped = GetPlayerPed(jugador)
            if sid and sid > 0 and ped ~= 0 and Player(sid).state.dead == true then
                local d = #(GetEntityCoords(ped) - donde)
                if d <= CERCA_TIRADO and (not mejorDist or d < mejorDist) then
                    mejor, mejorDist = sid, d
                end
            end
        end
    end
    return mejor
end

local function Pedir(id, paciente)
    if pidiendo then return end
    pidiendo = true
    local res = lib.callback.await('origen_gang:medico:pedir', false, id, paciente)
    pidiendo = false

    if not res or not res.ok then
        Notify.SendNotify(res and res.motivo or 'El médico no te atiende ahora.', 'error')
        return
    end
    Notify.SendNotify(('El médico se pone a ello. Aguanta %d segundos.'):format(res.dura or 15), 'info')
end

local function Punto(id)
    local m = medicos[id]
    local donde = vector3(m.pos_x, m.pos_y, m.pos_z)
    local punto = lib.points.new({ coords = donde, distance = VER, medicoId = id })

    local caido, miradoEn = nil, 0

    function punto:onEnter()
        CreateThread(function() Crear(self.medicoId) end)
    end

    function punto:onExit()
        Borrar(self.medicoId)
    end

    function punto:nearby()
        local actual = medicos[self.medicoId]
        if not actual then return end
        local dist = self.currentDistance or 999.0

        if ocupado[self.medicoId] then
            QuitarTexto(self.medicoId)
            return
        end

        if EstoyTirado() then
            if dist <= CERCA_TIRADO then
                PonerTexto(self.medicoId, ('[H] Que te levante el médico · %s'):format(Precio(actual)))
                if IsDisabledControlJustPressed(0, TECLA_TIRADO) or IsControlJustPressed(0, TECLA_TIRADO) then
                    CreateThread(function() Pedir(self.medicoId, nil) end)
                end
            else
                QuitarTexto(self.medicoId)
            end
            return
        end

        if dist > CERCA then
            QuitarTexto(self.medicoId)
            return
        end

        -- Buscar al caído no hace falta cada fotograma.
        local ahora = GetGameTimer()
        if ahora - miradoEn > 500 then
            caido, miradoEn = CaidoJuntoA(actual), ahora
        end

        if caido then
            PonerTexto(self.medicoId, ('[E] Pagar al médico para que levante al herido · %s'):format(Precio(actual)))
            if IsControlJustReleased(0, TECLA_PAGAR) then
                local a = caido
                CreateThread(function() Pedir(self.medicoId, a) end)
            end
        else
            PonerTexto(self.medicoId, ('Médico: solo atiende a quien llega tirado · %s'):format(Precio(actual)))
        end
    end

    puntos[id] = punto
end

local function Vaciar()
    for id, punto in pairs(puntos) do
        punto:remove()
        Borrar(id)
    end
    medicos, puntos, peds, ocupado = {}, {}, {}, {}
    QuitarTexto()
end

local function Poner(lista)
    Vaciar()
    for _, m in ipairs(lista or {}) do
        local id = tonumber(m.id)
        if id then
            -- Lo que viene de la base puede llegar entero, y los natives de
            -- coordenadas lo leen como 0.
            m.pos_x, m.pos_y, m.pos_z, m.pos_h = m.pos_x + 0.0, m.pos_y + 0.0, m.pos_z + 0.0, (m.pos_h or 0) + 0.0
            medicos[id] = m
            Punto(id)
        end
    end
end

-- ── La animación ─────────────────────────────────────────────────────────────

--[[ El médico va hasta el caído, se agacha sobre él lo que dure y vuelve a su
     sitio. La ped es de cada cliente (no es de red), así que cada uno que la
     tenga a la vista pinta lo mismo por su cuenta. ]]
RegisterNetEvent('origen_gang:client:medico:atiende', function(id, paciente, dura)
    id, dura = tonumber(id), tonumber(dura) or 15
    local ped = id and peds[id]
    if not ped or not DoesEntityExist(ped) or ocupado[id] then return end

    local jugador = GetPlayerFromServerId(tonumber(paciente) or -1)
    local herido = jugador ~= -1 and GetPlayerPed(jugador) or 0
    if herido == 0 or not DoesEntityExist(herido) then return end

    ocupado[id] = true
    QuitarTexto(id)
    local fin = GetGameTimer() + dura * 1000

    CreateThread(function()
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped)

        -- Hasta él, como mucho cuatro segundos; si no llega, se le pone al lado.
        local destino = GetEntityCoords(herido)
        TaskGoStraightToCoord(ped, destino.x, destino.y, destino.z, 1.0, 4000, 0.0, 0.6)
        local tope = GetGameTimer() + 4000
        while GetGameTimer() < tope and peds[id] == ped and DoesEntityExist(ped)
            and #(GetEntityCoords(ped) - destino) > 1.3 do
            Wait(100)
        end
        if peds[id] ~= ped or not DoesEntityExist(ped) then ocupado[id] = nil return end

        if DoesEntityExist(herido) then TaskTurnPedToFaceEntity(ped, herido, 600) end
        Wait(600)
        if peds[id] ~= ped or not DoesEntityExist(ped) then ocupado[id] = nil return end
        TaskStartScenarioInPlace(ped, ATENDER, 0, true)

        while GetGameTimer() < fin and peds[id] == ped and DoesEntityExist(ped) do Wait(200) end
        if peds[id] ~= ped or not DoesEntityExist(ped) then ocupado[id] = nil return end

        ClearPedTasks(ped)
        Wait(1800)
        if peds[id] == ped and DoesEntityExist(ped) then
            local m = medicos[id]
            if m then
                TaskGoStraightToCoord(ped, m.pos_x, m.pos_y, m.pos_z, 1.0, 5000, m.pos_h, 0.3)
                local vuelta = GetGameTimer() + 5000
                while GetGameTimer() < vuelta and peds[id] == ped and DoesEntityExist(ped)
                    and #(GetEntityCoords(ped) - vector3(m.pos_x, m.pos_y, m.pos_z)) > 1.2 do
                    Wait(150)
                end
            end
            if peds[id] == ped then APuesto(id) end
        end
        ocupado[id] = nil
    end)
end)

-- ── Carga ────────────────────────────────────────────────────────────────────

RegisterNetEvent('origen_gang:client:medicos:lista', function(lista)
    Poner(lista)
end)

local function Cargar()
    local lista = lib.callback.await('origen_gang:medico:lista', false)
    Poner(lista or {})
end

AddEventHandler('onResourceStart', function(recurso)
    if GetCurrentResourceName() ~= recurso then return end
    if not Framework.GetIsPlayerLoaded() then return end
    Wait(4000)
    Cargar()
end)

AddEventHandler('origen:Client:OnPlayerLoaded', function()
    Wait(3500)
    Cargar()
end)

AddEventHandler('origen:Client:OnPlayerUnload', function()
    Vaciar()
end)

AddEventHandler('onResourceStop', function(recurso)
    if GetCurrentResourceName() ~= recurso then return end
    Vaciar()
end)

-- ── El panel de admin ────────────────────────────────────────────────────────

RegisterNUICallback('admin:medicos:lista', function(_, cb)
    cb(lib.callback.await('origen_gang:admin:medicos:lista', false) or { success = false, medicos = {} })
end)

RegisterNUICallback('admin:medicos:guardar', function(datos, cb)
    cb(lib.callback.await('origen_gang:admin:medicos:guardar', false, datos) or { success = false })
end)

RegisterNUICallback('admin:medicos:encender', function(datos, cb)
    cb(lib.callback.await('origen_gang:admin:medicos:encender', false, datos) or { success = false })
end)

RegisterNUICallback('admin:medicos:borrar', function(datos, cb)
    cb(lib.callback.await('origen_gang:admin:medicos:borrar', false, datos) or { success = false })
end)

local colocando = false

--- Colocar la ped: el mismo motor que las tiendas y los sitios de banda
--- (Placement.Start), con la ped de muestra. El panel se cierra mientras y el
--- servidor lo vuelve a abrir al acabar.
RegisterNUICallback('admin:medicos:colocar', function(datos, cb)
    local id = tonumber(datos and datos.id)
    if colocando or not id then
        cb({ success = false })
        return
    end

    local modelo = (datos.ped_model and datos.ped_model ~= '') and datos.ped_model or 's_m_m_doctor_01'
    colocando = true

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeAdminPanel' })
    cb({ success = true })

    Placement.Start({
        ped_model    = modelo,
        label_rotate = locale:t('ui.rotate_npc'),
    }, function(res)
        colocando = false

        if res then
            local guardado = lib.callback.await('origen_gang:admin:medicos:colocar', false, {
                id = id, x = res.x, y = res.y, z = res.z, h = res.h,
            })
            if guardado and guardado.success then
                Notify.SendNotify('Médico colocado.', 'success')
            else
                Notify.SendNotify(locale:t('notify.admin_position_save_error'), 'error')
            end
        else
            Notify.SendNotify(locale:t('notify.admin_placement_cancelled'), 'error')
        end

        TriggerServerEvent('origen_gang:server:requestAdminPanel')
    end)
end)
