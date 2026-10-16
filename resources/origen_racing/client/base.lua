-- ============================================================
-- ORIGEN RACING - La base de la crew (Client)
-- ============================================================

--[[ La base de una crew es su casa de crew de origen_housing (ver
     server/base.lua). Aquí solo queda lo que pide la pestaña Base del panel
     de crew: leerla, marcar su entrada en el GPS y recoger el almacén viejo.
     El blip de la base lo pone client/crews.lua al cargar la crew. ]]

local function Avisar(texto, tipo)
    lib.notify({ title = 'Base de la crew', description = texto, type = tipo or 'inform', duration = 4500 })
end

--- El nombre de la calle de la entrada, para enseñarlo en el panel.
local function CalleDe(e)
    if type(e) ~= 'table' or not tonumber(e.x) then return nil end
    local ok, nombre = pcall(function()
        return GetStreetNameFromHashKey((GetStreetNameAtCoord(e.x + 0.0, e.y + 0.0, e.z + 0.0)))
    end)
    if ok and type(nombre) == 'string' and nombre ~= '' then return nombre end
    return nil
end

local function PedirBase(ligero)
    local ok, r = pcall(lib.callback.await, 'racing:base:getInfo', false, { ligero = ligero == true })
    if not ok or type(r) ~= 'table' then return { success = false, message = 'Sin respuesta del servidor' } end
    if r.base and r.base.entrada then r.base.calle = CalleDe(r.base.entrada) end
    return r
end

-- Lo usa client/crews.lua para el blip.
function PedirBaseDeCrew()
    return PedirBase(true)
end

RegisterNUICallback('racing:base:getInfo', function(_, cb)
    cb(PedirBase(false))
end)

-- «Marcar en el GPS»: la entrada de la casa de la crew.
RegisterNUICallback('racing:base:marcar', function(_, cb)
    local r = PedirBase(true)
    local e = r.success and r.base and r.base.entrada
    if not e then
        Avisar(r.success and 'Sin base: pide a un admin que cree la casa de tu crew en vuestro territorio'
            or (r.message or 'No se pudo leer la base'), 'error')
        cb({ success = false })
        return
    end
    SetNewWaypoint(e.x + 0.0, e.y + 0.0)
    Avisar('Entrada de la casa de la crew marcada en el GPS')
    cb({ success = true })
end)

-- «Recoger lo del almacén antiguo»: el servidor lo mira todo y te pasa al
-- inventario lo que te quepa. El almacén no se abre: el panel se queda.
RegisterNUICallback('racing:base:recogerAlmacen', function(_, cb)
    local ok, r = pcall(lib.callback.await, 'racing:base:recogerAlmacen', false)
    if not ok or type(r) ~= 'table' then r = { success = false, message = 'No se pudo recoger el almacén antiguo' } end
    Avisar(r.message or (r.success and 'Recogido' or 'No se pudo recoger el almacén antiguo'), r.success and 'success' or 'error')
    cb(r)
end)

-- ── Quien se quedó dentro del taller viejo ──────────────────────────────────
-- El interior del garaje de crew ya no existe: si al arrancar el recurso o al
-- entrar con el personaje estás ahí abajo, el servidor te saca.
local TALLER_VIEJO = vector3(1000.69, -3164.34, -38.91)

local function MirarTallerViejo()
    if #(GetEntityCoords(PlayerPedId()) - TALLER_VIEJO) < 40.0 then
        TriggerServerEvent('racing:base:salirDelTallerViejo')
    end
end

AddEventHandler('onClientResourceStart', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    CreateThread(function()
        Wait(3000)
        MirarTallerViejo()
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(5000)
        MirarTallerViejo()
    end)
end)
