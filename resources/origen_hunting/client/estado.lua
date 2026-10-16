--[[ ── El estado del cazador en este cliente ──────────────────────────────────

     Es un espejo: lo que manda es el servidor, que lo empuja con
     `origen_hunting:estado` cada vez que algo cambia (nivel, licencia,
     encargos, torneo). Aquí solo se guarda para pintar el HUD y para no
     preguntar lo mismo en cada fotograma. ]]

C = {
    activa = false,
    estado = {},
    estadoRecibido = 0,     -- GetGameTimer() de la última copia
    zona = nil,
    presas = {},            -- [netId] = presa conocida (propia o de otro)
    cebo = nil,             -- { coords, hasta, prop }
    carga = nil,            -- netId de la pieza a hombros
    panelAbierto = false,
    grupo = nil,            -- { miembros = { src, … }, lider }
}

local function Aviso(titulo, texto, tipo, duracion)
    lib.notify({ title = titulo, description = texto, type = tipo or 'inform', duration = duracion })
end
C.Aviso = Aviso

-- ── Las zonas en el mapa, solo con la jornada en marcha ───────────────────

local function PintarZonas(mostrar)
    if not mostrar then
        OrigenMapa.PonerVarios('zona', {})
        return
    end
    local puntos = {}
    for _, z in ipairs(Config.Zonas) do
        puntos[#puntos + 1] = {
            id = z.id,
            x = z.centro.x, y = z.centro.y, z = 0.0,
            cat = 'activities',
            icono = 'caza',
            nombre = 'Zona de caza: ' .. z.nombre,
            radio = z.radio + 0.0,
        }
    end
    OrigenMapa.PonerVarios('zona', puntos)
end

CreateThread(function()
    local c = Config.Campamento.Peds.Experto.coords
    OrigenMapa.Poner('campamento', {
        x = c.x, y = c.y, z = c.z,
        cat = 'activities',
        icono = 'caza',
        nombre = 'Campamento de caza',
    })
end)

-- ── Las zonas las manda el servidor (se editan desde el panel de admin) ────

local function ZonasDelServidor(lista)
    if type(lista) ~= 'table' or #lista == 0 then return end
    local nuevas = {}
    for i, z in ipairs(lista) do
        nuevas[i] = { id = z.id, nombre = z.nombre, centro = vec2(z.x + 0.0, z.y + 0.0), radio = z.radio + 0.0 }
    end
    for k in pairs(Config.Zonas) do Config.Zonas[k] = nil end
    for i, z in ipairs(nuevas) do Config.Zonas[i] = z end
    if C.activa then PintarZonas(true) end
end

AddStateBagChangeHandler('origen_hunting:zonas', 'global', function(_, _, valor)
    ZonasDelServidor(valor)
end)

CreateThread(function()
    ZonasDelServidor(GlobalState['origen_hunting:zonas'])
end)

-- ── El grupo ──────────────────────────────────────────────────────────────

RegisterNetEvent('origen_hunting:grupo', function(g)
    C.grupo = type(g) == 'table' and g or nil
end)

function C.MiGrupo(src)
    if not C.grupo or not src then return false end
    for _, m in ipairs(C.grupo.miembros or {}) do
        if m == src then return true end
    end
    return false
end

--[[ La invitación sale en un diálogo de ox_lib, que coge y suelta el foco él
     solo. Se cierra sola al caducar: una ventana que se queda puesta cuando ya
     no vale nada es peor que no verla. ]]
local invitacionAbierta = false

RegisterNetEvent('origen_hunting:grupo:invitacion', function(d)
    if type(d) ~= 'table' or invitacionAbierta then return end
    invitacionAbierta = true
    local dura = tonumber(d.dura) or 30
    SetTimeout(dura * 1000, function()
        if invitacionAbierta then lib.closeAlertDialog() end
    end)
    local r = lib.alertDialog({
        header = 'Partida de caza',
        content = ('**%s** (id %s) te invita a cazar en grupo.\n\nLo que vendáis en el campamento se reparte entre los que estéis cazando, y las piezas de cualquiera las podéis despellejar todos.')
            :format(tostring(d.de), tostring(d.id)),
        centered = true,
        cancel = true,
        labels = { confirm = 'Unirme', cancel = 'No, gracias' },
    })
    invitacionAbierta = false
    if r == nil then return end
    local res = lib.callback.await('origen_hunting:grupo:responder', false, r == 'confirm')
    if res and not res.ok and res.mensaje then Aviso('Grupo de caza', res.mensaje, 'error') end
end)

local function AlCambiarActiva(activa)
    if activa == C.activa then return end
    C.activa = activa
    PintarZonas(activa)
    if not activa then
        TriggerEvent('origen_hunting:finJornada')
    end
end

local function Recibir(e)
    if type(e) ~= 'table' then return end
    C.estado = e
    C.estadoRecibido = GetGameTimer()
    AlCambiarActiva(e.activa == true)
end

RegisterNetEvent('origen_hunting:estado', Recibir)

function C.Refrescar()
    Recibir(lib.callback.await('origen_hunting:estado', false))
end

CreateThread(function()
    while not LocalPlayer.state.isLoggedIn and not NetworkIsPlayerActive(PlayerId()) do Wait(1000) end
    Wait(2000)
    C.Refrescar()
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    SetTimeout(1500, C.Refrescar)
end)

-- ── La zona en la que estás ───────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(1000)
        local pos = GetEntityCoords(cache.ped)
        local zona = Caza.ZonaEn(pos.x, pos.y)
        if zona ~= C.zona then
            local antes = C.zona
            C.zona = zona
            if C.activa then
                if zona then
                    Aviso('Zona de caza', 'Entras en ' .. zona.nombre .. '. Los animales te huelen: ve agachado y con el viento de cara.', 'inform', 6000)
                elseif antes then
                    Aviso('Zona de caza', 'Sales de ' .. antes.nombre .. '.', 'inform')
                end
            end
        end
    end
end)

-- ── Torneos: los avisos llegan a todo el servidor ─────────────────────────

local function Minutos(n)
    return n == 1 and '1 minuto' or (n .. ' minutos')
end

RegisterNetEvent('origen_hunting:torneo', function(d)
    if type(d) ~= 'table' then return end
    local titulo, texto

    local nombre = d.nombre or 'Torneo de caza'
    local semanal = d.semanal or nombre ~= 'Torneo de caza'
    local inscripcion = (d.inscripcion or 0) > 0
        and (' Inscripción: $%s en el campamento de Paleto%s.'):format(Caza.Miles(d.inscripcion), d.abierta and ', ya abierta' or '')
        or ' Inicia tu jornada en el campamento de Paleto para entrar.'

    if d.tipo == 'pronto' then
        titulo = semanal and ('Se acerca la %s'):format(nombre) or nombre
        texto = ('Empieza %s y dura %d min.%s'):format(d.cuando or ('dentro de ' .. Minutos(d.minutos)), d.duracion or 30, inscripcion)
    elseif d.tipo == 'inicio' then
        titulo = semanal and ('¡Arranca la %s!'):format(nombre) or '¡Arranca el torneo de caza!'
        texto = ('%s · %d min. %s.%s%s'):format(d.modo, d.minutos or 30, d.detalle or '',
            d.objetivo and (' Objetivo: ' .. d.objetivo .. '.') or '',
            (d.bote or 0) > 0 and (' Bote: $%s.'):format(Caza.Miles(d.bote)) or '')
    elseif d.tipo == 'final' then
        titulo = nombre
        texto = ('Quedan %s.%s'):format(Minutos(d.minutos),
            d.lider and (' Va en cabeza ' .. d.lider .. '.') or ' Nadie ha puntuado todavía.')
    elseif d.tipo == 'cancelado' then
        titulo = nombre .. ': cancelado'
        texto = d.texto or 'Se ha cancelado.'
    elseif d.tipo == 'fin' then
        titulo = 'Fin: ' .. nombre
        if d.podio and #d.podio > 0 then
            local partes = {}
            for _, p in ipairs(d.podio) do
                partes[#partes + 1] = ('%dº %s (%d %s · $%s)'):format(p.puesto, p.nombre, p.puntos, d.unidad or 'pts', Caza.Miles(p.dinero))
            end
            texto = table.concat(partes, ' · ')
        else
            texto = 'Nadie ha puntuado. El próximo, más suerte.'
        end
    end

    if not titulo then return end
    -- Una notificacion normal, como la pesca: el cartel grande tapaba media pantalla.
    local tipo = (d.tipo == 'inicio' or d.tipo == 'fin') and 'success'
        or d.tipo == 'cancelado' and 'error' or 'inform'
    Aviso(titulo, texto, tipo, d.tipo == 'fin' and 12000 or 9000)

    if d.tipo == 'inicio' or d.tipo == 'fin' or d.tipo == 'cancelado' then
        SetTimeout(500, C.Refrescar)
    end
end)

--[[ El cartel dice cuánto ocupa arriba y los avisos de origen_notify bajan por
     debajo (se pisaban: los dos salen arriba en el medio). 0 = se ha ido. ]]
RegisterNUICallback('anuncioAltura', function(d, cb)
    cb({ ok = true })
    if GetResourceState('origen_notify') ~= 'started' then return end
    local px = math.floor(tonumber(d and d.px) or 0)
    pcall(function() exports.origen_notify:ApartarArriba(px) end)
end)

-- ── Pumas salvajes de GTA: fuera ─────────────────────────────────────────
--[[ Ver server/main.lua: un puma del juego que ataca a un jugador tumba el
     juego. El servidor los cancela al crearse; aquí, además, el juego de cada
     uno no los genera, y si alguno ya estaba (de antes de arrancar el recurso)
     se quita. Los de la caza son de misión y no se tocan. ]]
CreateThread(function()
    local pumas = { GetHashKey('a_c_mtlion'), GetHashKey('a_c_mtlion_02') }
    for _, m in ipairs(pumas) do SetPedModelIsSuppressed(m, true) end
    while true do
        for _, ped in ipairs(GetGamePool('CPed')) do
            local m = GetEntityModel(ped)
            if (m == pumas[1] or m == pumas[2]) and not IsEntityAMissionEntity(ped) then
                if NetworkGetEntityIsNetworked(ped) and not NetworkHasControlOfEntity(ped) then
                    NetworkRequestControlOfEntity(ped)
                else
                    SetEntityAsMissionEntity(ped, true, true)
                    DeleteEntity(ped)
                end
            end
        end
        Wait(2000)
    end
end)
