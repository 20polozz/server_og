--[[ ── El estado del cliente ──────────────────────────────────────────────────

     Un espejo de lo que manda el servidor, nada más. Las parcelas cercanas
     llegan enteras al acercarse y celda a celda cuando algo cambia; entre
     medias, el crecimiento y el agua se extrapolan con lo que dijo el
     servidor (`v` y `g`), que es lo que ve el jugador en la tarjeta. ]]

G = {
    cid = nil,
    parcelas = {},      -- [id] = vista del servidor + recibida (GetGameTimer)
    acopios = {},       -- [id] = { cajas }
    mochila = nil,      -- semillas, herramientas
    carga = nil,        -- lo que llevas en las manos (vista del servidor)
    panelAbierto = false,
    ocupado = false,    -- haciendo una acción con barra
}

function G.Aviso(texto, tipo, duracion)
    lib.notify({ title = 'Granja', description = texto, type = tipo or 'inform', duration = duracion })
end

--[[ El aviso de acción (tecla + qué hace) es SIEMPRE el de origen_notify, a la
     derecha: nada de la ayuda de GTA arriba a la izquierda ni del textUI de
     ox_lib (lo pidió el usuario). Cada módulo lo pide con su nombre y solo
     quita el suyo: así el palé no borra el de la cooperativa en el mismo
     fotograma. Solo se manda a la NUI cuando cambia. ]]
local ayuda = { dueno = nil, huella = nil }

function G.Ayuda(dueno, tecla, texto, alt)
    local huella = tecla .. '|' .. texto .. '|' .. (alt and (alt[1] .. alt[2]) or '')
    if ayuda.dueno == dueno and ayuda.huella == huella then return end
    ayuda.dueno, ayuda.huella = dueno, huella
    pcall(function() exports.origen_notify:DrawText(tecla, texto, alt) end)
end

function G.QuitarAyuda(dueno)
    if ayuda.dueno == nil or (dueno and ayuda.dueno ~= dueno) then return end
    ayuda.dueno, ayuda.huella = nil, nil
    pcall(function() exports.origen_notify:HideText() end)
end

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() and ayuda.dueno then
        pcall(function() exports.origen_notify:HideText() end)
    end
end)

function G.Nui(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

--- ¿Es mía esta parcela? (el servidor lo vuelve a mirar)
function G.EsMia(vista)
    -- Tuya o de tu equipo (client/equipo.lua).
    return vista ~= nil and vista.cid ~= nil and G.cid ~= nil and Equipo.Mismo(vista.cid, G.cid)
end

--- ¿Estoy de jornada? La marca la pone el servidor en mi state bag.
function G.Jornada()
    return LocalPlayer.state.granjaJornada == true
end

--- Una celda con el crecimiento y el agua extrapolados a ahora.
function G.Celda(parcelaId, idx)
    local v = G.parcelas[parcelaId]
    if not v then return nil end
    -- La tierra dura no viaja: una celda que no llega es tierra sin trabajar.
    local c = v.celdas[idx]
    if not c then return { e = 'yermo' } end
    local dt = (GetGameTimer() - (v.recibidas and v.recibidas[idx] or v.recibida)) / 1000
    local r = {}
    for k, val in pairs(c) do r[k] = val end
    if c.e == 'creciendo' then
        r.p = math.min(1.0, (c.p or 0) + (c.v or 0) * dt)
        r.a = math.max(0, (c.a or 0) - (c.g or 0) * dt)
        if (c.a or 0) > 0 and r.a <= 0 then r.v = 0 end
    end
    return r
end

function G.Fase(c)
    if c.e == 'lista' then return 'lista' end
    if c.e ~= 'creciendo' then return nil end
    return (c.p or 0) < 0.35 and 'brote' or 'crece'
end

-- ── Lo que llega del servidor ─────────────────────────────────────────────

local function Guardar(vista)
    vista.celdas = vista.celdas or {}
    vista.recibida = GetGameTimer()
    vista.recibidas = {}
    G.parcelas[vista.id] = vista
    TriggerEvent('origen_farming:c:parcela', vista.id)
end

RegisterNetEvent('origen_farming:parcela', function(vista)
    if type(vista) ~= 'table' or not Granja.Parcela(vista.id) then return end
    Guardar(vista)
end)

RegisterNetEvent('origen_farming:acopio', function(vista)
    if type(vista) ~= 'table' or not Granja.Acopio(vista.id) then return end
    G.acopios[vista.id] = vista
    TriggerEvent('origen_farming:c:acopio', vista.id)
end)

RegisterNetEvent('origen_farming:celda', function(parcelaId, idx, celda)
    local v = G.parcelas[parcelaId]
    if not v or type(celda) ~= 'table' then return end
    v.celdas[idx] = celda.e ~= 'yermo' and celda or nil
    v.recibidas = v.recibidas or {}
    v.recibidas[idx] = GetGameTimer()
    TriggerEvent('origen_farming:c:celda', parcelaId, idx)
end)

RegisterNetEvent('origen_farming:carga', function(vista)
    G.carga = vista
    TriggerEvent('origen_farming:c:carga')
end)

function G.PedirMochila()
    local m = lib.callback.await('origen_farming:mochila', false)
    if m then G.mochila = m end
    return G.mochila
end

-- ── Cerca de la finca: pedir las parcelas ─────────────────────────────────

--- El centro de la finca, para saber si estamos cerca de algo.
local centroFinca, radioFinca = vec2(0, 0), 0.0
do
    local sx, sy = 0.0, 0.0
    for _, p in ipairs(Config.Parcelas) do sx, sy = sx + p.centro.x, sy + p.centro.y end
    centroFinca = vec2(sx / #Config.Parcelas, sy / #Config.Parcelas)
    for _, p in ipairs(Config.Parcelas) do
        radioFinca = math.max(radioFinca, Granja.Plano(p.centro, centroFinca) + p.radio)
    end
end

G.cerca = false

CreateThread(function()
    local ultimaPeticion = 0
    while true do
        local pos = GetEntityCoords(cache.ped)
        local cerca = Granja.Plano(pos, centroFinca) <= radioFinca + Config.DistanciaVer
        if cerca ~= G.cerca then
            G.cerca = cerca
            TriggerEvent('origen_farming:c:cerca', cerca)
        end
        -- Cerca: se refresca todo cada 45 s (lo que no cambia de estado, como
        -- el agua que baja, se corrige así).
        if cerca and GetGameTimer() - ultimaPeticion > 45000 then
            ultimaPeticion = GetGameTimer()
            local r = lib.callback.await('origen_farming:parcelas', false)
            if r then
                G.cid = r.cid
                for _, vista in ipairs(r.parcelas) do Guardar(vista) end
                for _, a in ipairs(r.acopios or {}) do
                    G.acopios[a.id] = a
                    TriggerEvent('origen_farming:c:acopio', a.id)
                end
                G.PedirMochila()
            else
                ultimaPeticion = GetGameTimer() - 40000
            end
        elseif not cerca and next(G.parcelas) then
            G.parcelas = {}
            G.acopios = {}
            TriggerEvent('origen_farming:c:olvidar')
            ultimaPeticion = 0
        end
        Wait(cerca and 1000 or 3000)
    end
end)

--- Forzar un refresco (al volver de la cooperativa, tras alquilar...).
function G.Refrescar()
    local r = lib.callback.await('origen_farming:parcelas', false)
    if r then
        G.cid = r.cid
        for _, vista in ipairs(r.parcelas) do Guardar(vista) end
        for _, a in ipairs(r.acopios or {}) do
            G.acopios[a.id] = a
            TriggerEvent('origen_farming:c:acopio', a.id)
        end
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    G.Refrescar()
end)
