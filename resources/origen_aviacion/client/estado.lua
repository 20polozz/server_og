--[[ ── Lo común del cliente ──────────────────────────────────────────────────── ]]

A = {
    panel = false,      -- el panel de la instructora abierto
    teorico = false,    -- el teórico en pantalla
    practico = nil,     -- la sesión del práctico en curso (client/practico.lua)
}

function A.Aviso(texto, tipo, duracion)
    lib.notify({ title = Config.Corto, description = texto, type = tipo or 'inform', duration = duracion })
end

function A.Nui(accion, datos)
    SendNUIMessage({ accion = accion, datos = datos })
end

--[[ El aviso de tecla es SIEMPRE el de origen_notify (a la derecha), como en
     el resto de trabajos. Cada módulo pide el suyo y solo quita el suyo. ]]
local ayuda = { dueno = nil, huella = nil }

function A.Ayuda(dueno, tecla, texto)
    local huella = tecla .. '|' .. texto
    if ayuda.dueno == dueno and ayuda.huella == huella then return end
    ayuda.dueno, ayuda.huella = dueno, huella
    pcall(function() exports.origen_notify:DrawText(tecla, texto) end)
end

function A.QuitarAyuda(dueno)
    if ayuda.dueno == nil or (dueno and ayuda.dueno ~= dueno) then return end
    ayuda.dueno, ayuda.huella = nil, nil
    pcall(function() exports.origen_notify:HideText() end)
end

function A.Cargar(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local fin = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < fin do Wait(20) end
    return HasModelLoaded(hash)
end

function A.Suelo(x, y, z)
    local ok, sz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, (z or 100.0) + 5.0, false)
    return ok and sz or nil
end

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    pcall(function() exports.origen_notify:HideText() end)
    SetNuiFocus(false, false)
end)
