--[[ ── El estado del cliente ──────────────────────────────────────────────────

     Un espejo de lo que manda el servidor, nada más: las rocas (con su veta
     y sus golpes), los bloques de voladura, los pedruscos que no van en una
     caja, las carretillas y las cargas puestas. Llegan enteros al acercarse
     a la cantera y uno a uno cuando algo cambia. ]]

L = {
    cid = nil,
    rocas = {},         -- [id] = vista del servidor + recibida
    bloques = {},       -- [id] = vista
    pedruscos = {},     -- [id] = vista
    carretillas = {},   -- [cid] = vista
    cargas = {},        -- [id] = { tipo, objetivo, i, pos, c }
    yo = nil,
    panelAbierto = false,
    ocupado = false,
    cerca = false,
}

function L.Aviso(texto, tipo, duracion)
    lib.notify({ title = 'Cantera', description = texto, type = tipo or 'inform', duration = duracion })
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

--[[ Las tarjetas del HUD: solo una a la vez. ]]
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
    return LocalPlayer.state.minaJornada == true
end

function L.Herramienta()
    local h = LocalPlayer.state.minaHerramienta
    return Config.Herramientas[h] and h or nil
end

function L.Mano()
    local m = LocalPlayer.state.minaMano
    return Config.Materiales[m] and m or nil
end

function L.Empuja()
    return LocalPlayer.state.minaEmpuja or nil
end

function L.Cargas()
    return math.floor(tonumber(LocalPlayer.state.minaCargas) or 0)
end

function L.Nivel()
    return L.yo and L.yo.nivel or 1
end

function L.Roca(id)
    return L.rocas[id]
end

function L.PedirYo()
    local r = lib.callback.await('origen_mining:yo', false)
    if r then L.yo = r L.cid = r.cid end
    return L.yo
end

-- ── Lo que llega ──────────────────────────────────────────────────────────

local function Guardar(tabla, evento, clave)
    return function(vista)
        if type(vista) ~= 'table' or vista[clave] == nil then return end
        local id = vista[clave]
        if vista.borrado or vista.borrada or (tabla == 'pedruscos' and vista.s == 'camion') then
            L[tabla][id] = nil
        else
            vista.recibida = GetGameTimer()
            L[tabla][id] = vista
        end
        TriggerEvent('origen_mining:c:' .. evento, id, vista)
    end
end

RegisterNetEvent('origen_mining:roca', Guardar('rocas', 'roca', 'id'))
RegisterNetEvent('origen_mining:bloque', Guardar('bloques', 'bloque', 'id'))
RegisterNetEvent('origen_mining:pedrusco', Guardar('pedruscos', 'pedrusco', 'id'))
RegisterNetEvent('origen_mining:carretilla', Guardar('carretillas', 'carretilla', 'cid'))
RegisterNetEvent('origen_mining:carga', Guardar('cargas', 'carga', 'id'))

-- ── Cerca de la cantera: pedirlo todo ─────────────────────────────────────

local ZONA = Config.Mina.centro.xy
L.Zona = ZONA

function L.Refrescar()
    local r = lib.callback.await('origen_mining:estado', false)
    if not r then return false end
    L.cid = r.cid
    local function Llenar(tabla, lista, clave, evento)
        local antes = L[tabla]
        L[tabla] = {}
        for _, v in ipairs(lista or {}) do
            v.recibida = GetGameTimer()
            L[tabla][v[clave]] = v
        end
        for id in pairs(antes) do if not L[tabla][id] then TriggerEvent('origen_mining:c:' .. evento, id) end end
        for id, v in pairs(L[tabla]) do TriggerEvent('origen_mining:c:' .. evento, id, v) end
    end
    Llenar('rocas', r.rocas, 'id', 'roca')
    Llenar('bloques', r.bloques, 'id', 'bloque')
    Llenar('pedruscos', r.pedruscos, 'id', 'pedrusco')
    Llenar('carretillas', r.carretillas, 'cid', 'carretilla')
    Llenar('cargas', r.cargas, 'id', 'carga')
    return true
end

CreateThread(function()
    local ultima = 0
    while true do
        local pos = GetEntityCoords(cache.ped)
        local cerca = #(pos.xy - ZONA) <= 450.0
        if cerca ~= L.cerca then
            L.cerca = cerca
            TriggerEvent('origen_mining:c:cerca', cerca)
            if not cerca then
                L.rocas, L.bloques, L.pedruscos, L.carretillas, L.cargas = {}, {}, {}, {}, {}
                ultima = 0
            end
        end
        -- Cerca: todo de nuevo cada 60 s (lo que cambia con el tiempo, como
        -- las rocas que se reponen, se corrige así).
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
