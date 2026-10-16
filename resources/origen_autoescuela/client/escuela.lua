--[[ ── La instructora y su panel ──────────────────────────────────────────────

     Una NPC junto a los hangares de Sandy. Con E se abre el panel: los tres
     niveles, qué falta de cada uno, lo que cuesta, la licencia que tienes y
     el duplicado. Desde el panel se empieza el teórico o el práctico. ]]

local npc = nil
local MARCA = 'origen_autoescuela'
DecorRegister(MARCA, 3)

CreateThread(function()
    local c = Config.Escuela.npc.coords
    OrigenMapa.Poner('escuela', {
        x = c.x, y = c.y, z = c.z,
        cat = Config.Mapa.categoria, icono = Config.Mapa.icono,
        nombre = Config.Mapa.nombre,
    })
end)

local function CrearNPC()
    local cfg = Config.Escuela.npc
    local hash = GetHashKey(cfg.modelo)
    if not A.Cargar(hash) then return nil end
    local c = cfg.coords
    -- En el MLO de Nación la consulta de suelo puede devolver la altura del
    -- techo. Sus coordenadas ya traen la altura correcta del piso interior.
    local z = c.z
    if GetConvar('origen:marca', 'origen') ~= 'nacion' then
        z = A.Suelo(c.x, c.y, c.z) or c.z
    end
    local ped = CreatePed(4, hash, c.x, c.y, z, c.w, false, false)
    SetModelAsNoLongerNeeded(hash)
    DecorSetInt(ped, MARCA, 1)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    if cfg.escenario then TaskStartScenarioInPlace(ped, cfg.escenario, 0, true) end
    return ped
end

local function Borrar(ent)
    if ent and DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

--- Rehacer la NPC (el editor la mueve).
function A.RehacerNPC()
    Borrar(npc)
    npc = nil
end

CreateThread(function()
    local conTexto = false
    while true do
        local espera = 1000
        local c = Config.Escuela.npc.coords
        local d = #(GetEntityCoords(cache.ped) - c.xyz)
        if d < 70.0 and not npc then
            npc = CrearNPC()
        elseif d >= 70.0 and npc then
            Borrar(npc)
            npc = nil
        end
        if d < 15.0 then espera = 0 end
        local cerca = d <= 2.4 and not A.panel and not A.teorico and not cache.vehicle and not A.practico
        if cerca and not conTexto then
            conTexto = true
            A.Ayuda('npc', 'E', 'Hablar con el instructor')
        elseif not cerca and conTexto then
            conTexto = false
            A.QuitarAyuda('npc')
        end
        if cerca and IsControlJustReleased(0, 38) then
            conTexto = false
            A.QuitarAyuda('npc')
            A.AbrirPanel()
        end
        Wait(espera)
    end
end)

-- ── El panel ──────────────────────────────────────────────────────────────

function A.AbrirPanel()
    if A.panel then return end
    A.panel = true
    local r = lib.callback.await('origen_autoescuela:panel', false)
    if not r or not r.ok then
        A.panel = false
        if r and r.mensaje then A.Aviso(r.mensaje, 'error') end
        return
    end
    A.Nui('panel', r.datos)
    SetNuiFocus(true, true)
    if npc and DoesEntityExist(npc) then
        TaskTurnPedToFaceEntity(npc, cache.ped, 1500)
    end
end

--[[ Cerrar desde Lua (no desde la pantalla): se suelta el foco YA y el
     mensaje va después, que es lo que hace que el ratón no se quede preso si
     la NUI no contesta. ]]
function A.CerrarPanel()
    if not A.panel then return end
    A.panel = false
    SetNuiFocus(false, false)
    SetTimeout(280, function() A.Nui('cerrar') end)
end

if OrigenFoco and OrigenFoco.AlSoltar then
    -- Si el vigilante suelta el ratón a la fuerza, el panel ya no está.
    OrigenFoco.AlSoltar(function()
        A.panel = false
        A.teorico = false
    end)
end

--[[ La pantalla se está cerrando sola (Escape, clic fuera, botón o porque
     el examen empieza): el foco se suelta ya; ella se desmonta al acabar su
     animación. ]]
RegisterNUICallback('cerrar', function(_, cb)
    cb({})
    A.panel, A.teorico = false, false
    SetNuiFocus(false, false)
end)

--- La pantalla pide los datos otra vez (al terminar el teórico).
RegisterNUICallback('panel', function(_, cb)
    cb(lib.callback.await('origen_autoescuela:panel', false) or { ok = false })
end)

RegisterNUICallback('duplicado', function(_, cb)
    local r = lib.callback.await('origen_autoescuela:duplicado', false)
    cb(r or { ok = false })
    if r and r.ok then
        A.Aviso(r.mensaje, 'success', 8000)
    end
end)

RegisterNUICallback('teorico', function(d, cb)
    local r = lib.callback.await('origen_autoescuela:teorico:empezar', false, d and d.nivel)
    cb(r or { ok = false })
    -- Solo si el panel sigue abierto: cerrado mientras se esperaba, el
    -- examen ya no tiene pantalla donde hacerse.
    if r and r.ok and A.panel then A.teorico = true end
end)

RegisterNUICallback('practico', function(d, cb)
    local r = lib.callback.await('origen_autoescuela:practico:empezar', false, d and d.examen)
    cb(r or { ok = false })
    -- La pantalla se cierra ella (y con su animación); aquí solo se vuela.
    if r and r.ok then A.EmpezarPractico(r) end
end)

AddEventHandler('onResourceStop', function(r)
    if r ~= GetCurrentResourceName() then return end
    Borrar(npc)
    for _, ped in ipairs(GetGamePool('CPed')) do
        if DecorExistOn(ped, MARCA) and not IsPedAPlayer(ped) then Borrar(ped) end
    end
end)
