--[[ ── El campamento y su panel ───────────────────────────────────────────────

     Tres NPC —el experto, la tienda y el comprador— abren el MISMO panel, cada
     uno por su pestaña. El panel es un menú lateral de la casa (skill
     `origen-riel`): el foco se suelta al instante al cerrar y el desmontaje
     espera a que acabe la animación. ]]

local abierto = false

-- ── Los NPC, solo cuando hay alguien cerca ────────────────────────────────

local function CrearNPC(cfg)
    local hash = GetHashKey(cfg.modelo)
    if not pcall(lib.requestModel, hash, 8000) then return nil end
    local c = cfg.coords
    local ped = CreatePed(4, hash, c.x, c.y, c.z - 1.0, c.w, false, false)
    SetModelAsNoLongerNeeded(hash)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_IMPATIENT', 0, true)
    return ped
end

local npcs = {}

for clave, cfg in pairs(Config.Campamento.Peds) do
    local c = cfg.coords
    local punto = lib.points.new({ coords = c.xyz, distance = 80.0 })
    local conTexto = false

    function punto:onEnter()
        if npcs[clave] then return end
        npcs[clave] = CrearNPC(cfg)
    end

    function punto:onExit()
        if npcs[clave] and DoesEntityExist(npcs[clave]) then DeleteEntity(npcs[clave]) end
        npcs[clave] = nil
        if conTexto then lib.hideTextUI() conTexto = false end
    end

    function punto:nearby()
        local cerca = self.currentDistance <= 2.2 and not abierto and not C.carga
        if cerca and not conTexto then
            conTexto = true
            lib.showTextUI('[E] ' .. cfg.texto, { position = 'left-center', icon = 'paw' })
        elseif not cerca and conTexto then
            conTexto = false
            lib.hideTextUI()
        end
        if cerca and IsControlJustReleased(0, 38) then
            conTexto = false
            lib.hideTextUI()
            AbrirPanel(cfg.seccion)
        end
    end
end

-- ── Abrir y cerrar ────────────────────────────────────────────────────────

--- Las piezas enteras que podrías entregar: las que estén junto al comprador.
local function Candidatos()
    local lista = {}
    local comprador = Config.Campamento.Peds.Comprador.coords.xyz
    if C.carga then lista[#lista + 1] = C.carga end
    for netId, p in pairs(C.presas) do
        if p.muerte and netId ~= C.carga then
            local ent = C.EntidadDe(netId)
            if ent and #(GetEntityCoords(ent) - comprador) <= 18.0 then lista[#lista + 1] = netId end
        end
    end
    return lista
end

function AbrirPanel(seccion)
    if abierto then return end
    abierto = true

    local datos = lib.callback.await('origen_hunting:panel', false, Candidatos())
    -- Cerrado mientras se esperaba (alejarse, el vigilante del foco): no se
    -- coge el raton para un panel que ya no toca.
    if not abierto then return end
    if not datos then
        abierto = false
        C.Aviso('Caza', 'El campamento no puede atenderte ahora.', 'error')
        return
    end

    datos.seccion = seccion
    C.panelAbierto = true
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'abrir', datos = datos })
end

function CerrarPanel()
    if not abierto then return end
    abierto = false
    C.panelAbierto = false

    SetNuiFocus(false, false)

    -- Sin pisar un panel que se haya vuelto a abrir en esos 280 ms.
    SetTimeout(280, function()
        if not abierto then SendNUIMessage({ accion = 'cerrar' }) end
    end)
end

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`): sin esto `abierto` se quedaba en true y ningun NPC del
     campamento volvia a abrir el panel. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        C.panelAbierto = false
        SendNUIMessage({ accion = 'cerrar' })
    end)
end

exports('EstaAbierto', function() return abierto end)

-- Alejarse con el panel abierto lo cierra: todo lo de dentro exige estar aquí.
CreateThread(function()
    while true do
        Wait(1000)
        if abierto and #(GetEntityCoords(cache.ped) - Config.Campamento.centro) > Config.Campamento.radio then
            CerrarPanel()
        end
    end
end)

-- ── Lo que pide la pantalla ───────────────────────────────────────────────

RegisterNUICallback('cerrar', function(_, cb)
    CerrarPanel()
    cb({ ok = true })
end)

RegisterNUICallback('jornada', function(d, cb)
    local activar = d and d.activar == true
    local r = lib.callback.await('origen_hunting:jornada', false, activar)
    if r and r.ok then
        C.Aviso('Caza', activar
            and 'Jornada en marcha. Las zonas de caza están en tu mapa.'
            or 'Has terminado la jornada de caza.', activar and 'success' or 'inform')
    end
    cb(r or { ok = false })
end)

RegisterNUICallback('licencia', function(_, cb)
    local r = lib.callback.await('origen_hunting:licencia', false)
    if r and r.ok then
        C.Aviso('Licencia de Caza', 'Has recibido tu tarjeta física de la licencia de caza con vigencia actualizada.', 'success')
    end
    cb(r or { ok = false })
end)

CreateThread(function()
    Wait(2000)
    if GetResourceState('origen_inventory') == 'started' then
        pcall(function()
            exports.origen_inventory:displayMetadata({
                holderName = 'Titular',
                duration = 'Vigencia',
                expira = 'Expira',
                addedBy = 'Emisor',
            })
        end)
    end
end)

RegisterNUICallback('comprar', function(d, cb)
    cb(lib.callback.await('origen_hunting:comprar', false, d and d.item, d and d.cantidad) or { ok = false })
end)

RegisterNUICallback('vender', function(d, cb)
    cb(lib.callback.await('origen_hunting:vender', false, d and d.slots or {}) or { ok = false })
end)

RegisterNUICallback('entregar', function(d, cb)
    local netId = d and tonumber(d.netId)
    local r = lib.callback.await('origen_hunting:entregar', false, netId)
    if r and r.ok and C.carga == netId then C.Soltar(false) end
    if r and r.ok then r.enteras = {} end
    cb(r or { ok = false })
end)

RegisterNUICallback('cobrarEncargo', function(d, cb)
    cb(lib.callback.await('origen_hunting:cobrarEncargo', false, d and d.id) or { ok = false })
end)

RegisterNUICallback('cobrarTorneo', function(_, cb)
    cb(lib.callback.await('origen_hunting:cobrarTorneo', false) or { ok = false })
end)

RegisterNUICallback('inscribirse', function(_, cb)
    cb(lib.callback.await('origen_hunting:inscribirse', false) or { ok = false })
end)

RegisterNUICallback('grupoInvitar', function(d, cb)
    cb(lib.callback.await('origen_hunting:grupo:invitar', false, d and tonumber(d.id)) or { ok = false })
end)

RegisterNUICallback('grupoResponder', function(d, cb)
    cb(lib.callback.await('origen_hunting:grupo:responder', false, d and d.aceptar == true) or { ok = false })
end)

RegisterNUICallback('grupoSalir', function(_, cb)
    cb(lib.callback.await('origen_hunting:grupo:salir', false) or { ok = false })
end)

RegisterNUICallback('grupoEchar', function(d, cb)
    cb(lib.callback.await('origen_hunting:grupo:echar', false, d and tonumber(d.id)) or { ok = false })
end)

RegisterNUICallback('grupoEstado', function(_, cb)
    cb({ ok = true, grupo = lib.callback.await('origen_hunting:grupo:estado', false) })
end)

--- Los jugadores que tienes cerca, para invitar sin tener que preguntar ids.
RegisterNUICallback('grupoCerca', function(_, cb)
    local lista = {}
    local yo = GetEntityCoords(cache.ped)
    for _, id in ipairs(GetActivePlayers()) do
        if id ~= cache.playerId then
            local d = #(GetEntityCoords(GetPlayerPed(id)) - yo)
            if d <= 30.0 then
                lista[#lista + 1] = { id = GetPlayerServerId(id), metros = math.floor(d) }
            end
        end
    end
    table.sort(lista, function(a, b) return a.metros < b.metros end)
    cb({ ok = true, cerca = lista })
end)

RegisterNUICallback('marcarZona', function(d, cb)
    local zona = d and Caza.ZonaPorId(d.id)
    if zona then
        SetNewWaypoint(zona.centro.x, zona.centro.y)
        C.Aviso('Caza', 'Ruta marcada a ' .. zona.nombre .. '.', 'success')
    end
    cb({ ok = zona ~= nil })
end)

RegisterNUICallback('refrescar', function(_, cb)
    cb(lib.callback.await('origen_hunting:panel', false, Candidatos()) or { ok = false })
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    if abierto then SetNuiFocus(false, false) end
    for _, ped in pairs(npcs) do
        if DoesEntityExist(ped) then DeleteEntity(ped) end
    end
end)
