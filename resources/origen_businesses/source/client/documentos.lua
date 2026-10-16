--[[
    LOS DOCUMENTOS DEL NEGOCIO — cliente

    · Desde el panel (pestaña Documentos): hacer uno, ver los emitidos.
    · Al usar el objeto: el servidor manda el documento y aquí se abre el
      visor, con el ratón, para leerlo, firmarlo si te toca o enseñarlo.
    · Si alguien te lo enseña: se abre sin coger el ratón ni el teclado (vas
      andando, conduciendo…) y se cierra con ⌫ o solo al rato.

    Todo lo que cuenta lo decide el servidor (source/server/documentos.lua);
    aquí solo se pasan las cosas y se pone la animación de enseñarlo.
]]

--- Cómo está abierto el visor: nil, 'propio' (con ratón) o 'ajeno' (sin).
local visor = nil
local ajenoHasta = 0

local function Aviso(texto, tipo)
    Custom.Notify({ title = 'Documentos', description = texto, type = tipo or 'error' })
end

local function Llamar(nombre, datos)
    local ok, res = pcall(function()
        return lib.callback.await('origen_businesses:cb:documentos:' .. nombre, false, datos)
    end)
    if not ok or type(res) ~= 'table' then
        return { success = false, message = 'No se pudo contactar con el servidor.' }
    end
    return res
end

local function CerrarVisor()
    if visor == 'propio' then SetNuiFocus(false, false) end
    visor = nil
    SendNUIMessage({ action = 'documento:cerrar' })
end

--[[ Si el vigilante comun suelta el raton a la fuerza con el visor propio
     delante, el visor se va con el: si no, quedaba a pantalla completa sin
     raton para cerrarlo. El ajeno no lleva raton y sigue a lo suyo. ]]
OrigenFoco.AlSoltar(function()
    if visor ~= 'propio' then return end
    visor = nil
    SendNUIMessage({ action = 'documento:cerrar' })
end)

-- ── Lo que pide el panel ──────────────────────────────────────────────────

RegisterNUICallback('documentos:crear', function(data, cb)
    cb(Llamar('crear', data))
end)

RegisterNUICallback('documentos:lista', function(data, cb)
    cb(Llamar('lista', data and data.businessId))
end)

--[[ La copia del negocio de uno de los emitidos. Se abre dentro del propio
     panel (el foco ya es suyo), solo para leer. ]]
RegisterNUICallback('documentos:verEmitido', function(data, cb)
    cb(Llamar('ver', data))
end)

-- ── El visor ──────────────────────────────────────────────────────────────

RegisterNetEvent('origen_businesses:documentos:aviso', function(texto)
    Aviso(texto, 'inform')
end)

RegisterNetEvent('origen_businesses:documentos:abrir', function(documento, opciones)
    if type(documento) ~= 'table' then return end
    opciones = type(opciones) == 'table' and opciones or {}

    if opciones.propio then
        visor = 'propio'
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
    else
        --[[ Te lo enseñan: sin robarte el ratón. Si ya estabas mirando uno
             tuyo con el ratón, no se te cambia por debajo. ]]
        if visor == 'propio' then return end
        visor = 'ajeno'
        ajenoHasta = GetGameTimer() + 25000
        Aviso(('%s te enseña un documento. ⌫ para cerrarlo.'):format(opciones.ensenadoPor or 'Alguien'), 'inform')

        CreateThread(function()
            while visor == 'ajeno' do
                if IsControlJustPressed(0, 177) or GetGameTimer() > ajenoHasta then
                    CerrarVisor()
                    break
                end
                Wait(0)
            end
        end)
    end

    SendNUIMessage({ action = 'documento:abrir', data = { documento = documento, opciones = opciones } })
end)

RegisterNUICallback('documento:cerrar', function(_, cb)
    cb('ok')
    CerrarVisor()
end)

RegisterNUICallback('documento:firmar', function(data, cb)
    cb(Llamar('firmar', data))
end)

--[[ Enseñarlo. El servidor busca a quien tengas al lado y se lo manda; aquí,
     si ha ido bien, se cierra el tuyo y se hace el gesto de enseñarlo. ]]
local function Gesto(formato)
    local ped = PlayerPedId()
    local tarjeta = formato == 'tarjeta'
    local dict = tarjeta and 'paper_1_rcm_alt1-8' or 'missfam4'
    local anim = tarjeta and 'player_one_dual-8' or 'base'
    local modelo = tarjeta and 'prop_franklin_dl' or 'p_amb_clipboard_01'

    local okA = pcall(lib.requestAnimDict, dict, 3000)
    local okM, hash = pcall(lib.requestModel, modelo, 3000)
    if not okA or not okM or not hash then return end

    local obj = CreateObject(hash, GetEntityCoords(ped), true, true, false)
    SetModelAsNoLongerNeeded(hash)
    if tarjeta then
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 57005), 0.10, 0.02, -0.03, -90.0, 170.0, 79.0, true, true, false, true, 1, true)
    else
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 36029), 0.16, 0.08, 0.1, -130.0, -50.0, 0.0, true, true, false, true, 1, true)
    end
    TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 50, 0, false, false, false)

    SetTimeout(4000, function()
        StopAnimTask(ped, dict, anim, 1.0)
        if DoesEntityExist(obj) then DeleteEntity(obj) end
        RemoveAnimDict(dict)
    end)
end

RegisterNUICallback('documento:ensenar', function(data, cb)
    local res = Llamar('ensenar', data)
    cb(res)
    if res.success then
        CerrarVisor()
        CreateThread(function() Gesto(data and data.formato) end)
    end
end)

-- ── En el inventario ─────────────────────────────────────────────────────

--[[ Al pasar el ratón por un documento, de qué negocio es. Con una clave
     propia: `displayMetadata` pinta la clave en TODOS los objetos que la
     lleven. ]]
CreateThread(function()
    while GetResourceState('origen_inventory') ~= 'started' do Wait(1000) end
    pcall(function()
        exports.origen_inventory:displayMetadata({ emisorNegocio = 'Emisor' })
    end)
end)

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if visor == 'propio' then SetNuiFocus(false, false) end
end)
