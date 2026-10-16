--[[
    SUCURSALES Y CAJEROS · lado cliente

    Monta en el mundo los puntos que manda el servidor (server/puntos.lua):
    un marcador en el suelo o un NPC detrás del mostrador, el aviso de «[E]» y
    el punto en el mapa. Un banco abre el banco entero; un cajero, la pantalla
    de sacar dinero.

    Y el modo «colocar» del panel de administración: el panel se esconde, el
    administrador se pone donde quiere el punto —mirando hacia donde tiene que
    mirar el NPC— y pulsa E.

    Al llegar una lista nueva se borra todo y se vuelve a montar. Es de bruto,
    pero un banco se mueve tres veces en la vida del servidor y así no hay que
    llevar la cuenta de qué NPC era de qué fila.
]]

local montados = {}

local function Texto(tipo, nombre)
    return ('[E] %s · %s'):format(tipo == 'cajero' and 'Cajero' or 'Banco', nombre)
end

--- Trae un modelo a memoria. nil si no existe en este cliente.
local function CargarModelo(nombre)
    local hash = joaat(nombre or '')
    if not IsModelInCdimage(hash) or not IsModelAPed(hash) then return nil end
    if HasModelLoaded(hash) then return hash end

    RequestModel(hash)
    local limite = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < limite do Wait(0) end
    return HasModelLoaded(hash) and hash or nil
end

local function Limpiar()
    for _, m in ipairs(montados) do
        if m.ped and DoesEntityExist(m.ped) then DeleteEntity(m.ped) end
        for _, zona in ipairs(m.zonas) do zona:remove() end
    end
    montados = {}
    lib.hideTextUI()
end

local function Abrir(punto)
    if punto.tipo == 'cajero' then AbrirCajero() else AbrirBanco() end
end

local function Montar(punto)
    local m = { zonas = {}, ped = nil }
    montados[#montados + 1] = m

    local donde = vec3(punto.x + 0.0, punto.y + 0.0, punto.z + 0.0)

    --[[ El NPC, solo con alguien cerca: aparece a 60 m y se borra al irte. Si
         estuvieran todos desde que entras ocuparían sitio en el pool de peds
         de GTA, que es de todo el servidor. ]]
    if punto.modo == 'npc' then
        m.zonas[#m.zonas + 1] = lib.points.new({
            coords = donde,
            distance = 60.0,
            onEnter = function()
                if m.ped and DoesEntityExist(m.ped) then return end

                local modelo = CargarModelo(punto.ped)
                if not modelo then
                    if not m.avisado then
                        m.avisado = true
                        print(('[origen_banking] «%s» tiene un NPC que no existe: %s'):format(punto.nombre, tostring(punto.ped)))
                    end
                    return
                end

                local ped = CreatePed(4, modelo, punto.x + 0.0, punto.y + 0.0, punto.z - 1.0, punto.h + 0.0, false, true)
                SetModelAsNoLongerNeeded(modelo)

                -- Mobiliario con cara: no se mueve, no se asusta, no se le puede pegar.
                FreezeEntityPosition(ped, true)
                SetEntityInvincible(ped, true)
                SetBlockingOfNonTemporaryEvents(ped, true)
                SetPedDiesWhenInjured(ped, false)
                SetPedCanRagdoll(ped, false)
                m.ped = ped
            end,
            onExit = function()
                if m.ped and DoesEntityExist(m.ped) then DeleteEntity(m.ped) end
                m.ped = nil
            end,
        })
    end

    --- Con NPC se habla desde más lejos: el mostrador está en medio.
    local alcance = punto.modo == 'npc' and 2.5 or 1.5

    m.zonas[#m.zonas + 1] = lib.points.new({
        coords = donde,
        distance = 12.0,
        nearby = function(self)
            if IsInside then return end

            -- El marcador, solo en los de punto: con NPC ya se ve dónde es.
            if punto.modo ~= 'npc' then
                local mk = Config.Marker
                DrawMarker(mk.type, punto.x, punto.y, punto.z - 0.15, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    mk.size.x, mk.size.y, mk.size.z, 216, 27, 85, 190,
                    mk.bobUpAndDown, mk.faceCamera, 2, mk.rotate, nil, nil, false)
            end

            local cerca = self.currentDistance <= alcance
            if cerca ~= m.aviso then
                m.aviso = cerca
                if cerca then lib.showTextUI(Texto(punto.tipo, punto.nombre)) else lib.hideTextUI() end
            end

            if cerca and IsControlJustReleased(0, 38) then
                m.aviso = false
                lib.hideTextUI()
                Abrir(punto)
            end
        end,
        onExit = function()
            if m.aviso then lib.hideTextUI() end
            m.aviso = false
        end,
    })
end

local function MontarTodos(lista)
    Limpiar()

    local enElMapa = {}
    for _, punto in ipairs(lista or {}) do
        Montar(punto)
        if punto.blip then
            enElMapa[#enElMapa + 1] = {
                x = punto.x, y = punto.y, z = punto.z,
                cat = 'banking',
                nombre = punto.nombre,
            }
        end
    end

    -- Reemplaza la tanda anterior: los que ya no están se van solos.
    OrigenMapa.PonerVarios('banco_puntos', enElMapa)
end

RegisterNetEvent('origen_banking:client:puntos', MontarTodos)

CreateThread(function()
    -- Al entrar (o al reiniciar el recurso con gente dentro) se pide la lista.
    while not LocalPlayer.state.isLoggedIn do Wait(1000) end
    MontarTodos(lib.callback.await('origen_banking:puntos', false))
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() then Limpiar() end
end)

--[[ ══ EL CAJERO ═══════════════════════════════════════════════════════════

     Un cajero no es el banco: se elige cuenta y se saca dinero. Antes las
     máquinas abrían el banco entero y la pantalla del cajero no la abría
     nadie (ni tenía a quién pedirle el dinero). ]]

local enCajero = false

function AbrirCajero()
    if IsInside or enCajero then return end

    local data = lib.callback.await('origen_banking:cb:getManagementData', false)
    if not data then return end

    local cuentas = {}
    for _, c in ipairs(data.accounts or {}) do
        -- Solo las que dejan sacar: en una de mirar, el cajero no sirve de nada.
        if c.myPermission == 'manager' or c.myPermission == 'operator' then
            cuentas[#cuentas + 1] = {
                id = c.id,
                accountNumber = c.id,
                label = c.name,
                balance = c.balance,
                isDefault = c.default == true or c.default == 1,
                type = c.type,
            }
        end
    end

    enCajero = true
    IsInside = true
    TriggerEvent('qv2:suppressHud', true)
    SendNUIMessage({ action = 'openAtm', data = { accounts = cuentas } })
    SetNuiFocus(true, true)
end

local function CerrarCajero()
    if not enCajero then return end
    enCajero = false
    SetNuiFocus(false, false)
    IsInside = false
    TriggerEvent('qv2:suppressHud', false)
end

-- Raton soltado a la fuerza: el cajero se cierra y se puede volver a usar.
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not enCajero then return end
        enCajero = false
        IsInside = false
        TriggerEvent('qv2:suppressHud', false)
        SendNUIMessage({ action = 'cerrarCajero' })
    end)
end

RegisterNUICallback('cerrarCajero', function(_, cb)
    CerrarCajero()
    cb('ok')
end)

RegisterNUICallback('withdraw', function(data, cb)
    local result = lib.callback.await('origen_banking:server:WithdrawFromAccount', false, data)
    Avisar(result)
    cb(result or { success = false })
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and enCajero then
        SetNuiFocus(false, false)
        TriggerEvent('qv2:suppressHud', false)
    end
end)

--[[ ══ COLOCAR UN PUNTO (panel de administración) ═════════════════════════

     El panel se esconde y suelta el ratón; el administrador camina hasta el
     sitio y pulsa E. Se guarda donde está y hacia dónde mira: el NPC se
     planta ahí mirando igual. Retroceso cancela. Al acabar, el panel vuelve
     tal como estaba, con el formulario a medias. ]]

local colocando = false

--- La barra de teclas de origen_hud (abajo al centro) mientras se coloca un punto.
local function TeclasColocar(ver)
    if GetResourceState('origen_hud') ~= 'started' then return end
    if ver then
        exports.origen_hud:setupControls({
            { key = 'E', text = 'Poner aquí' },
        })
    else
        exports.origen_hud:hideControls()
    end
end

RegisterNUICallback('adminColocar', function(datos, cb)
    cb('ok')
    if colocando then return end
    colocando = true

    local esNpc = type(datos) == 'table' and datos.modo == 'npc'

    SendNUIMessage({ action = 'adminOcultar', data = { oculto = true } })
    SetNuiFocus(false, false)
    -- Instrucciones de colocar en el mundo: la barra de teclas de abajo al centro.
    TeclasColocar(true)

    CreateThread(function()
        local resultado = nil

        while colocando do
            Wait(0)

            local ped = cache.ped
            local pos = GetEntityCoords(ped)
            local h = GetEntityHeading(ped)

            -- El sitio en el suelo, y una flecha hacia donde mirará el NPC.
            DrawMarker(25, pos.x, pos.y, pos.z - 0.97, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.9, 0.9, 0.9, 216, 27, 85, 170, false, false, 2, false, nil, nil, false)
            if esNpc then
                local delante = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.9, -0.95)
                DrawMarker(2, delante.x, delante.y, delante.z, 0.0, 0.0, 0.0, 90.0, h, 0.0,
                    0.35, 0.35, 0.35, 216, 27, 85, 200, false, false, 2, false, nil, nil, false)
            end

            -- Que la E no dispare nada más mientras tanto.
            DisableControlAction(0, 38, true)

            if IsDisabledControlJustReleased(0, 38) then
                resultado = {
                    x = tonumber(('%.2f'):format(pos.x)),
                    y = tonumber(('%.2f'):format(pos.y)),
                    z = tonumber(('%.2f'):format(pos.z)),
                    h = tonumber(('%.2f'):format(h)),
                }
                colocando = false
            elseif IsControlJustReleased(0, 177) then
                colocando = false
            end
        end

        TeclasColocar(false)
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({ action = 'adminOcultar', data = { oculto = false } })
        SendNUIMessage({ action = 'adminPuntoColocado', data = resultado })
    end)
end)

--- Ir a un punto para verlo, sin salir del panel.
RegisterNUICallback('adminIrPunto', function(datos, cb)
    cb('ok')
    if type(datos) ~= 'table' or not tonumber(datos.x) then return end
    SetEntityCoords(cache.ped, datos.x + 0.0, datos.y + 0.0, datos.z + 0.0, false, false, false, false)
    if tonumber(datos.h) then SetEntityHeading(cache.ped, datos.h + 0.0) end
end)

RegisterNUICallback('adminPedsDeBanco', function(_, cb)
    cb(Config.PedsDeBanco or {})
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and colocando then
        colocando = false
        TeclasColocar(false)
    end
end)
