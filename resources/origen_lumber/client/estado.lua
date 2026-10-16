--[[ ── El estado del cliente ──────────────────────────────────────────────────

     Un espejo de lo que manda el servidor, nada más: los árboles trabajados
     (los que no están aquí están en pie) y los troncos sueltos. Llegan enteros
     al acercarse a la zona y uno a uno cuando algo cambia. ]]

L = {
    cid = nil,
    arboles = {},       -- [id] = vista del servidor + recibida (GetGameTimer)
    troncos = {},       -- [id] = vista del servidor + recibida
    yo = nil,           -- nivel, gasolina, plantones, pila
    panelAbierto = false,
    ocupado = false,    -- haciendo un paso con animación
    cerca = false,      -- en la zona del aserradero y los cuarteles
}

function L.Aviso(texto, tipo, duracion)
    lib.notify({ title = 'Aserradero', description = texto, type = tipo or 'inform', duration = duracion })
end

--[[ El aviso de tecla es SIEMPRE el de origen_notify (a la derecha): nada de
     la ayuda de GTA arriba a la izquierda. Cada módulo pide el suyo con su
     nombre y solo quita el suyo. Solo se manda a la NUI cuando cambia. ]]
local ayuda = { dueno = nil, huella = nil }

function L.Ayuda(dueno, tecla, texto, alt)
    local huella = tecla .. '|' .. texto .. '|' .. (alt and (alt[1] .. alt[2]) or '')
    if ayuda.dueno == dueno and ayuda.huella == huella then return end
    ayuda.dueno, ayuda.huella = dueno, huella
    pcall(function() exports.origen_notify:DrawText(tecla, texto, alt) end)
end

function L.QuitarAyuda(dueno)
    if ayuda.dueno == nil or (dueno and ayuda.dueno ~= dueno) then return end
    ayuda.dueno, ayuda.huella = nil, nil
    pcall(function() exports.origen_notify:HideText() end)
end

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and ayuda.dueno then
        pcall(function() exports.origen_notify:HideText() end)
    end
end)

--[[ Las tarjetas del HUD: solo una a la vez. Cada módulo manda la suya y
     esconde la suya; si otro módulo tiene una a la vista, la suya se queda
     esperando (el que la tiene la suelta al alejarse). ]]
local tarjeta = { tipo = nil, huella = nil }

function L.Nui(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

function L.Tarjeta(tipo, datos)
    if L.panelAbierto then return end
    if tarjeta.tipo and tarjeta.tipo ~= tipo then return end
    local huella = json.encode(datos)
    if tarjeta.tipo == tipo and tarjeta.huella == huella then return end
    tarjeta.tipo, tarjeta.huella = tipo, huella
    datos.visible = true
    L.Nui(tipo, datos)
end

function L.SinTarjeta(tipo)
    if tarjeta.tipo ~= tipo then return end
    tarjeta.tipo, tarjeta.huella = nil, nil
    L.Nui(tipo, { visible = false })
end

function L.EsconderTarjetas()
    if tarjeta.tipo then L.Nui(tarjeta.tipo, { visible = false }) end
    tarjeta.tipo, tarjeta.huella = nil, nil
end

function L.Jornada()
    return LocalPlayer.state.lumberJornada == true
end

function L.Herramienta()
    local h = LocalPlayer.state.lumberHerramienta
    return Config.Herramientas[h] and h or nil
end

function L.Arbol(id)
    return L.arboles[id] or { id = id, e = 'pie' }
end

function L.PedirYo()
    local r = lib.callback.await('origen_lumber:yo', false)
    if r then L.yo = r L.cid = r.cid end
    return L.yo
end

-- ── Lo que llega ──────────────────────────────────────────────────────────

local function GuardarArbol(vista)
    if type(vista) ~= 'table' or not vista.id then return end
    vista.recibida = GetGameTimer()
    if vista.e == 'pie' then L.arboles[vista.id] = nil else L.arboles[vista.id] = vista end
    TriggerEvent('origen_lumber:c:arbol', vista.id)
end

local function GuardarTronco(vista)
    if type(vista) ~= 'table' or not vista.id then return end
    if vista.borrado or vista.s == 'camion' then
        L.troncos[vista.id] = nil
    else
        vista.recibida = GetGameTimer()
        L.troncos[vista.id] = vista
    end
    TriggerEvent('origen_lumber:c:tronco', vista.id)
end

RegisterNetEvent('origen_lumber:arbol', GuardarArbol)
RegisterNetEvent('origen_lumber:tronco', GuardarTronco)

-- ── Cerca de la zona: pedirlo todo ────────────────────────────────────────

local ZONA = (function()
    local sx, sy, n = Config.Aserradero.centro.x, Config.Aserradero.centro.y, 1
    for _, c in ipairs(Config.Cuarteles) do sx, sy, n = sx + c.centro.x, sy + c.centro.y, n + 1 end
    return vec2(sx / n, sy / n)
end)()
L.Zona = ZONA

function L.Refrescar()
    local r = lib.callback.await('origen_lumber:estado', false)
    if not r then return false end
    L.cid = r.cid
    local antesA, antesT = L.arboles, L.troncos
    L.arboles, L.troncos = {}, {}
    for _, v in ipairs(r.arboles) do v.recibida = GetGameTimer() L.arboles[v.id] = v end
    for _, v in ipairs(r.troncos) do v.recibida = GetGameTimer() L.troncos[v.id] = v end
    for id in pairs(antesA) do if not L.arboles[id] then TriggerEvent('origen_lumber:c:arbol', id) end end
    for id in pairs(L.arboles) do TriggerEvent('origen_lumber:c:arbol', id) end
    for id in pairs(antesT) do if not L.troncos[id] then TriggerEvent('origen_lumber:c:tronco', id) end end
    for id in pairs(L.troncos) do TriggerEvent('origen_lumber:c:tronco', id) end
    return true
end

CreateThread(function()
    local ultima = 0
    while true do
        local pos = GetEntityCoords(cache.ped)
        local cerca = #(pos.xy - ZONA) <= 430.0
        if cerca ~= L.cerca then
            L.cerca = cerca
            TriggerEvent('origen_lumber:c:cerca', cerca)
            if not cerca then
                L.arboles, L.troncos = {}, {}
                ultima = 0
            end
        end
        -- Cerca: todo de nuevo cada 60 s (lo que cambia con el tiempo, como
        -- los rebrotes, se corrige así).
        if cerca and GetGameTimer() - ultima > 60000 then
            if L.Refrescar() then
                ultima = GetGameTimer()
                L.PedirYo()
            else
                ultima = GetGameTimer() - 55000
            end
        end
        Wait(cerca and 1000 or 3000)
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    if L.cerca then L.Refrescar() end
end)

--- Cambios del estado propio: la herramienta y la jornada.
AddStateBagChangeHandler('lumberHerramienta', ('player:%s'):format(cache.serverId), function()
    SetTimeout(0, function() TriggerEvent('origen_lumber:c:herramienta') end)
end)
