--[[ ══════════════════════════════════════════════════════════════════════════
     EL PANEL DE ADMINISTRACIÓN

     A pantalla completa, con el lenguaje de la tablet. Lo abre origen_admin
     desde su lista de scripts con `openManagement()`, como el resto de los
     recursos de la casa.

     De aquí sale el modo de colocar: al elegir «poner una mesa» el panel se
     esconde, se coloca en el mundo, y al guardar o cancelar el panel vuelve
     solo. Es el único sitio del recurso donde una pantalla se cierra para que
     puedas mirar el juego, así que el camino de vuelta tiene que estar: un
     panel que no vuelve obliga a abrirlo otra vez desde el principio en cada
     mesa que se pone, y se ponen de veinte en veinte.
   ══════════════════════════════════════════════════════════════════════════ ]]

local abierto = false
local volviendo = false

local function Abrir(seccion)
    if abierto then return end
    local datos = lib.callback.await('origen_casino:admin:datos', false)
    if not datos or not datos.permiso then
        C.Aviso(Config.General.nombre, 'No tienes permiso para esto.', 'error')
        return
    end
    -- Mientras se esperaba al servidor se ha podido abrir otra pantalla
    -- (la caja, un juego): encima de ella, el primer cierre soltaria el
    -- raton de las dos.
    if abierto or C.pantalla then return end
    abierto = true
    C.pantalla = 'admin'
    C.Foco(true)
    C.Enviar('admin', { datos = datos, seccion = seccion })
end

local function Cerrar()
    if not abierto then return end
    abierto = false
    C.pantalla = nil
    C.Foco(false)
    C.Enviar('cerrarAdmin')
end

if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        C.Enviar('cerrarAdmin')
    end)
end

exports('openManagement', function() Abrir() end)

--- Volver al panel después de colocar. Lo llama client/colocar.lua.
function VolverAlPanel()
    if not volviendo then return end
    volviendo = false
    SetTimeout(200, function() Abrir('puntos') end)
end

-- ── Lo que manda el panel ─────────────────────────────────────────────────

--- Cerrar y, si el panel se abrió desde la pestaña Scripts del admin, volver
--- a ella. Ya no hay botón: es lo que hace ESC. origen_admin decide si vuelve
--- (solo si este panel salió de su lista); si no, ESC cierra y nada más.
local function CerrarYVolver()
    Cerrar()
    if GetResourceState('origen_admin') ~= 'started' then return end
    SetTimeout(80, function()
        pcall(function() exports['origen_admin']:ReturnToScripts() end)
    end)
end

RegisterNUICallback('adminCerrar', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminVolver', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminGuardar', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:guardar', false, d and d.seccion, d and d.valor) or { ok = false })
end)

RegisterNUICallback('adminRestablecer', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:restablecer', false, d and d.seccion) or { ok = false })
end)

RegisterNUICallback('adminRegistro', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:registro', false, d or {}) or { ok = false })
end)

RegisterNUICallback('adminPunto', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:punto', false, d and d.accion, d and d.datos) or { ok = false })
end)

RegisterNUICallback('adminJugador', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:jugador', false, d and d.accion, d and d.datos) or { ok = false })
end)

RegisterNUICallback('adminBote', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:bote', false, d or {}) or { ok = false })
end)

RegisterNUICallback('adminCarrera', function(d, cb)
    cb(lib.callback.await('origen_casino:admin:carrera', false, d and d.accion) or { ok = false })
end)

-- ── Colocar desde el panel ────────────────────────────────────────────────

RegisterNUICallback('adminColocar', function(d, cb)
    cb({ ok = true })
    local tipo = d and d.tipo
    if type(tipo) ~= 'string' then return end
    volviendo = true
    Cerrar()
    SetTimeout(150, function() Colocar(tipo, nil) end)
end)

RegisterNUICallback('adminMover', function(d, cb)
    cb({ ok = true })
    local punto = d and d.punto
    if type(punto) ~= 'table' or not punto.tipo then return end
    volviendo = true
    Cerrar()
    SetTimeout(150, function() Colocar(punto.tipo, punto) end)
end)

--[[ ── Traer del mapa ──────────────────────────────────────────────────

     Busca alrededor del admin los muebles de casino que ya trae el mapa
     (shared/mapas.lua) y los manda al servidor para que haga un punto de
     cada uno, sin mueble propio. Se busca en dos sitios: todos los objetos
     cargados, y además en cada sitio conocido de los mapas con muebles
     propios, por si el mueble no está en la lista de objetos. ]]
local RADIO_IMPORTAR = 90.0

local function Suelo(ent, hash)
    local p = GetEntityCoords(ent)
    local bajo = GetModelDimensions(hash)
    return p.x, p.y, p.z + ((bajo and bajo.z) or 0.0)
end

local function Buscar()
    local yo = GetEntityCoords(cache.ped)
    local vistos, lista = {}, {}

    local vanilla = {}
    for modelo, tipo in pairs(Mapas.Vanilla) do vanilla[joaat(modelo)] = { tipo = tipo, nombre = modelo } end
    local propios = {}
    for _, mapa in ipairs(Mapas.Propios) do
        if mapa.mesa then propios[joaat(mapa.mesa)] = { mapa = mapa, que = 'mesa' } end
        if mapa.rueda then propios[joaat(mapa.rueda)] = { mapa = mapa, que = 'rueda' } end
    end

    local function Anadir(ent)
        if vistos[ent] or not DoesEntityExist(ent) then return end
        vistos[ent] = true
        local hash = GetEntityModel(ent)
        local v, pr = vanilla[hash], propios[hash]
        if not v and not pr then return end
        local x, y, z = Suelo(ent, hash)
        if #(vector3(x, y, z) - yo) > RADIO_IMPORTAR then return end
        local h = GetEntityHeading(ent)

        if v then
            local tipo = Catalogo.Tipo(v.tipo)
            local d = { tipo = v.tipo, x = x, y = y, z = z, h = h, ajustes = { sinProp = true } }
            -- De otra variante que la del catálogo: se cambia por la del catálogo.
            if tipo and tipo.modelo and joaat(tipo.modelo) ~= hash then d.ajustes.modeloMapa = hash end
            lista[#lista + 1] = d
        elseif pr.que == 'mesa' then
            lista[#lista + 1] = { tipo = Mapas.TipoEn(pr.mapa, x, y, z), x = x, y = y, z = z, h = h,
                                  ajustes = { sinProp = true, modeloMapa = hash } }
        elseif pr.que == 'rueda' and not pr.mapa.ruedaSitio then
            -- La rueda propia del mapa se esconde y se pone la nuestra en su sitio
            -- (si el mapa tiene sitio fijo para ella, va abajo, la encuentre o no).
            lista[#lista + 1] = { tipo = 'rueda', x = x, y = y, z = z, h = h,
                                  ajustes = { modeloMapa = hash, quitarMapa = true } }
        end
    end

    for _, ent in ipairs(GetGamePool('CObject')) do Anadir(ent) end

    for _, mapa in ipairs(Mapas.Propios) do
        if mapa.mesa then
            for _, s in ipairs(mapa.sitios or {}) do
                local ent = GetClosestObjectOfType(s.x, s.y, s.z, 2.0, joaat(mapa.mesa), false, false, false)
                if ent ~= 0 then Anadir(ent) end
            end
        end
        --[[ La rueda propia del mapa va aunque no se encuentre: otro script
             (rcore) puede haberla borrado y no vuelve hasta que el mapa se
             recarga. Se pone la nuestra en su sitio y se esconde la del mapa. ]]
        if mapa.rueda and mapa.ruedaSitio and GetResourceState(mapa.recurso or '') == 'started' then
            local r = mapa.ruedaSitio
            if #(vector3(r.x, r.y, r.z) - yo) < RADIO_IMPORTAR then
                lista[#lista + 1] = { tipo = 'rueda', x = r.x, y = r.y, z = r.z, h = r.h,
                                      ajustes = { modeloMapa = joaat(mapa.rueda), quitarMapa = true } }
            end
        end
        -- Lo que el mapa no trae como mueble (la caja), si el admin está ahí.
        for _, e in ipairs(mapa.extras or {}) do
            if #(vector3(e.x, e.y, e.z) - yo) < RADIO_IMPORTAR and GetResourceState(mapa.recurso or '') == 'started' then
                lista[#lista + 1] = { tipo = e.tipo, x = e.x, y = e.y, z = e.z, h = e.h, nombre = e.nombre }
            end
        end
    end
    return lista
end

Mapas.Buscar = Buscar

RegisterNUICallback('adminImportar', function(_, cb)
    local lista = Buscar()
    if #lista == 0 then
        cb({ ok = false, mensaje = 'No hay muebles de casino cerca. Ponte dentro del casino del mapa.' })
        return
    end
    cb(lib.callback.await('origen_casino:admin:punto', false, 'importar', { lista = lista }) or { ok = false })
end)

--- Ir a ver una mesa: marca el sitio en el mapa y cierra el panel.
RegisterNUICallback('adminIr', function(d, cb)
    cb({ ok = true })
    local x, y = tonumber(d and d.x), tonumber(d and d.y)
    if not x or not y then return end
    SetNewWaypoint(x, y)
    C.Aviso(Config.General.nombre, 'Marcado en el mapa.', 'inform')
end)

--- Teletransportarse a una mesa. Solo desde el panel, que ya pide permiso.
RegisterNUICallback('adminTeletransporte', function(d, cb)
    cb({ ok = true })
    local x, y, z = tonumber(d and d.x), tonumber(d and d.y), tonumber(d and d.z)
    if not x or not y or not z then return end
    Cerrar()
    SetEntityCoords(cache.ped, x, y, z + 1.0, false, false, false, false)
end)

--- Las coordenadas de donde está el admin, para poner algo sin colocarlo.
RegisterNUICallback('adminAqui', function(_, cb)
    local p = GetEntityCoords(cache.ped)
    cb({
        x = math.floor(p.x * 100) / 100,
        y = math.floor(p.y * 100) / 100,
        z = math.floor(p.z * 100) / 100,
        h = math.floor(GetEntityHeading(cache.ped) * 10) / 10,
    })
end)

RegisterCommand('casinoadmin', function()
    Abrir()
end, false)

AddEventHandler('onResourceStop', function(recurso)
    if recurso == GetCurrentResourceName() and abierto then C.Foco(false) end
end)
