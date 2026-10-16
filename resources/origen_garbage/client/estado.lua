--[[ ── El estado del cliente ──────────────────────────────────────────────────

     Un espejo de lo que manda el servidor: lo vaciado cerca (cubos sin
     bolsas y bolsas del suelo que ya no están), más los avisos de tecla y las
     tarjetas del HUD. ]]

L = {
    cid = nil,
    yo = nil,             -- { cid, nivel, pago }
    vaciados = {},        -- [clave] = { q, x, y, z, h, e, hasta = GetGameTimer() en que se llena }
    panelAbierto = false,
    ocupado = false,      -- haciendo un paso con animación
}

function L.Aviso(texto, tipo, duracion)
    lib.notify({ title = 'Basuras', description = texto, type = tipo or 'inform', duration = duracion })
end

--[[ El aviso de tecla es SIEMPRE el de origen_notify (a la derecha): nada de
     la ayuda de GTA. Cada módulo pide el suyo con su nombre y solo quita el
     suyo. Solo se manda a la NUI cuando cambia. ]]
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
     esconde la suya. ]]
local tarjeta = { tipo = nil, huella = nil }

function L.Nui(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

function L.Tarjeta(tipo, datos)
    if L.panelAbierto then return end
    if tarjeta.tipo and tarjeta.tipo ~= tipo then L.Nui(tarjeta.tipo, { visible = false }) end
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
    return LocalPlayer.state.basuraJornada == true
end

function L.ConBolsa()
    return LocalPlayer.state.basuraBolsa == true
end

function L.PedirYo()
    local r = lib.callback.await('origen_garbage:yo', false)
    if r then L.yo = r L.cid = r.cid end
    return L.yo
end

-- ── Lo vaciado ────────────────────────────────────────────────────────────

--[[ Las bolsas sueltas que alguien ha cogido desaparecen para todos los que
     las ven (CreateModelHide en su sitio) hasta que se reponen. Los cubos y
     contenedores se quedan: solo cambia que están vacíos. ]]
local escondidas = {}   -- [clave] = { x, y, z, h }

local function Esconder(k, v)
    if escondidas[k] then return end
    CreateModelHide(v.x + 0.0, v.y + 0.0, v.z + 0.0, 0.6, v.h, true)
    escondidas[k] = { x = v.x, y = v.y, z = v.z, h = v.h }
end

local function Mostrar(k)
    local e = escondidas[k]
    if not e then return end
    RemoveModelHide(e.x + 0.0, e.y + 0.0, e.z + 0.0, 0.6, e.h, false)
    escondidas[k] = nil
end

local function Guardar(v)
    if type(v) ~= 'table' or type(v.k) ~= 'string' then return end
    if v.lleno then
        L.vaciados[v.k] = nil
        Mostrar(v.k)
        return
    end
    v.hasta = GetGameTimer() + (tonumber(v.r) or 0) * 1000
    L.vaciados[v.k] = v
    if v.e and v.q <= 0 then Esconder(v.k, v) end
end

RegisterNetEvent('origen_garbage:vaciado', function(v)
    if GetInvokingResource() then return end
    Guardar(v)
end)

--- Lo vaciado de una clave, o nil si está lleno.
function L.Vaciado(k)
    local v = L.vaciados[k]
    if v and GetGameTimer() >= v.hasta then
        L.vaciados[k] = nil
        Mostrar(k)
        return nil
    end
    return v
end

--- Todo lo vaciado alrededor (al trabajar, cada poco).
function L.Refrescar()
    local lista = lib.callback.await('origen_garbage:cerca', false)
    if type(lista) ~= 'table' then return false end
    for _, v in ipairs(lista) do Guardar(v) end
    return true
end

CreateThread(function()
    local ultima = 0
    while true do
        -- De jornada: lo de alrededor cada 20 s (los cambios llegan solos; esto
        -- corrige lo que pasó lejos antes de llegar).
        if L.Jornada() and GetGameTimer() - ultima > 20000 then
            if L.Refrescar() then ultima = GetGameTimer() end
        end
        -- Lo que ya se ha repuesto.
        local ahora = GetGameTimer()
        for k, v in pairs(L.vaciados) do
            if ahora >= v.hasta then
                L.vaciados[k] = nil
                Mostrar(k)
            end
        end
        Wait(2000)
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    for k in pairs(escondidas) do Mostrar(k) end
end)
