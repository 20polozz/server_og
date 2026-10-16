--[[ ── El panel ────────────────────────────────────────────────────────────────

     Se abre con /zonas o desde el panel de administración, y es el único sitio
     desde donde se crean zonas. Nada de lo que manda comprueba el permiso aquí:
     eso lo hace el servidor en cada callback, porque esto vive en la máquina de
     quien lo abre.

     Un solo sitio toca SetNuiFocus. El vigilante del ratón —foco.lua, que viene
     en el fxmanifest— suelta el ratón solo si la página se queda en blanco por
     lo que sea. ]]

local abierto = false
local desdeElHub = false

local function Abrir(zonas, catalogo)
    abierto = true

    SendNUIMessage({
        accion = 'abrir',
        zonas = zonas,
        catalogo = catalogo,
        bordes = Mapa.VeBordes(),
    })

    if desdeElHub then
        -- El hub tarda en apartarse: si se coge el ratón antes, la pantalla de
        -- carga se queda con él y no se puede pulsar nada.
        CreateThread(function()
            Wait(2800)
            if abierto then SetNuiFocus(true, true) end
        end)
    else
        SetNuiFocus(true, true)
    end
end

local function Cerrar()
    if not abierto then return end
    abierto = false

    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'cerrar' })

    if desdeElHub then
        desdeElHub = false
        if GetResourceState('origen_admin') == 'started' then
            exports['origen_admin']:ReturnToScripts()
        end
    end
end

RegisterNetEvent('origen_zones:panel', function(zonas, catalogo)
    Abrir(zonas, catalogo)
end)

RegisterCommand(Config.Comando, function()
    desdeElHub = false
    TriggerServerEvent('origen_zones:abrirPanel')
end, false)

-- Como lo abre el panel de administración. Con el callback, que contesta
-- también cuando dice que no: con el evento, un «no» no llegaba y desdeElHub
-- se quedaba en true (el /zonas siguiente tardaba 2,8 s en dar el ratón y al
-- cerrar devolvía al admin).
exports('openManagement', function()
    CreateThread(function()
        local r = lib.callback.await('origen_zones:panel:abrir', false)
        if not r or not r.ok then
            desdeElHub = false
            -- El hub ya se aparto: que vuelva, o el jugador se queda sin nada.
            if GetResourceState('origen_admin') == 'started' then
                exports['origen_admin']:ReturnToScripts()
            end
            return
        end
        desdeElHub = true
        Abrir(r.zonas, r.catalogo)
    end)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- LO QUE PIDE LA PANTALLA
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNUICallback('cerrar', function(_, cb)
    Cerrar()
    cb('ok')
end)

RegisterNUICallback('lista', function(_, cb)
    cb(lib.callback.await('origen_zones:panel:lista', false) or { ok = false })
end)

RegisterNUICallback('guardar', function(datos, cb)
    cb(lib.callback.await('origen_zones:panel:guardar', false, datos) or { ok = false })
end)

RegisterNUICallback('borrar', function(datos, cb)
    cb(lib.callback.await('origen_zones:panel:borrar', false, datos.id) or { ok = false })
end)

RegisterNUICallback('encender', function(datos, cb)
    cb(lib.callback.await('origen_zones:panel:encender', false, datos) or { ok = false })
end)

local function Dos(n)
    return math.floor(n * 100 + 0.5) / 100
end

RegisterNUICallback('dondeEstoy', function(_, cb)
    local c = GetEntityCoords(PlayerPedId())
    cb({ x = Dos(c.x), y = Dos(c.y), z = Dos(c.z) })
end)

-- Encender o apagar el borde pintado en el suelo. Se queda encendido al cerrar
-- el panel a propósito: es para pasearse por la zona y ver dónde cae.
RegisterNUICallback('bordes', function(datos, cb)
    cb({ ok = true, bordes = Mapa.Bordes(datos and datos.si) })
end)

-- Ir a una zona para verla desde dentro. Cierra el panel: si no, se acaba
-- teletransportado con el ratón preso y sin saber dónde.
RegisterNUICallback('irA', function(datos, cb)
    local x, y = tonumber(datos.x), tonumber(datos.y)
    if not x or not y then
        cb({ ok = false })
        return
    end

    Cerrar()

    local ped = PlayerPedId()
    local entidad = ped
    if IsPedInAnyVehicle(ped, false) then
        local coche = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(coche, -1) == ped then entidad = coche end
    end

    local hay, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, 1000.0, false)
    SetEntityCoords(entidad, x + 0.0, y + 0.0, (hay and z or 40.0) + 1.0, false, false, false, false)

    cb({ ok = true })
end)

-- Escape lo cierra: lo manda la propia página, que es quien sabe si hay un
-- diálogo abierto por encima.
RegisterNUICallback('escape', function(_, cb)
    Cerrar()
    cb('ok')
end)
