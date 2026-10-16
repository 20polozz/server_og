--[[ ── Trabajar la tierra ─────────────────────────────────────────────────────

     A pie dentro de una parcela, la celda que tienes delante se resalta y la
     tarjeta de la derecha dice qué le pasa y qué puedes hacer:

       E        la acción principal (arar, sembrar, regar, cosechar, limpiar)
       G        abonar, o fumigar si tiene plaga
       ← →      elegir la semilla

     Cada acción: el servidor la aprueba (`empezar`), se hace la animación con
     su barra, y el servidor la vuelve a comprobar y la aplica (`terminar`). ]]

Campo = {}

local TECLA_E, TECLA_G, IZQ, DER = 38, 47, 174, 175

local semillaElegida = nil      -- id de cultivo
local apuntada = nil            -- { cfg, idx }
local ultimaTarjeta = ''
local ultimoEnvio = 0

-- ── La acción, de principio a fin ─────────────────────────────────────────

local TEXTOS = {
    arar = 'Arando', sembrar = 'Sembrando', regar = 'Regando', abonar = 'Abonando',
    fumigar = 'Fumigando', cosechar = 'Cosechando', limpiar = 'Limpiando', esparcir = 'Esparciendo heno',
}

--- Hace una acción sobre una celda. La usan las teclas.
function Campo.Ejecutar(accion, parcelaId, idx, extra)
    if G.ocupado then return false, 'ocupado' end
    local cfg = Granja.Parcela(parcelaId)
    if not cfg then return false, 'parcela' end
    G.ocupado = true

    local r = lib.callback.await('origen_farming:empezar', false, accion, parcelaId, idx, extra)
    if not r or not r.ok then
        G.ocupado = false
        if r and r.mensaje then G.Aviso(r.mensaje, 'error') end
        return false, r and r.mensaje
    end

    local pos = Granja.PosCelda(cfg, idx)
    TaskTurnPedToFaceCoord(cache.ped, pos.x + 0.0, pos.y + 0.0, cfg.centro.z + 0.0, 600)
    Wait(450)

    local a = Config.Acciones[accion] or {}
    local hecho = lib.progressCircle({
        duration = r.duracion or a.duracion or 2500,
        label = TEXTOS[accion] or 'Trabajando',
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true, sprint = true },
        anim = a.anim and { dict = a.anim.dict, clip = a.anim.clip, flag = 1 } or nil,
        prop = a.prop and { model = a.prop.model, bone = a.prop.bone, pos = a.prop.pos, rot = a.prop.rot } or nil,
    })

    if not hecho then
        lib.callback.await('origen_farming:cancelar', false)
        G.ocupado = false
        return false, 'cancelado'
    end

    local fin = lib.callback.await('origen_farming:terminar', false)
    ClearPedTasks(cache.ped)
    G.ocupado = false
    if not fin or not fin.ok then
        if fin and fin.mensaje then G.Aviso(fin.mensaje, 'error') end
        return false, fin and fin.mensaje
    end
    if fin.mochila then G.mochila = fin.mochila end
    if accion == 'cosechar' and fin.extra then
        G.Aviso(('+%d %s  %s'):format(fin.extra.unidades, fin.extra.nombre, Granja.Estrellas(fin.extra.calidad)), 'success')
    end
    ultimaTarjeta = ''
    return true
end

-- ── Qué se puede hacer con la celda ───────────────────────────────────────

local function Semillas()
    return G.mochila and G.mochila.semillas or {}
end

local function SemillaActual()
    local lista = Semillas()
    if #lista == 0 then return nil, 0 end
    for i, s in ipairs(lista) do
        if s.id == semillaElegida then return s, i end
    end
    semillaElegida = lista[1].id
    return lista[1], 1
end

--- Las acciones de la celda: { principal, secundaria, aviso }
--- `mia`: la parcela es tuya o de tu equipo; `ajena`: es de otro (no se toca).
local function Acciones(cfg, idx, c, mia, ajena)
    local m = G.mochila or {}
    local carga = G.carga
    local principal, secundaria, aviso

    if not G.Jornada() then return nil, nil, 'Empieza la jornada en la cooperativa para trabajar la tierra.' end

    if ajena then
        return nil, nil, 'Esta parcela es de otro granjero: para trabajarla juntos, formad un equipo en la cooperativa.'
    end

    if c.e == 'yermo' then
        if carga and carga.tipo == 'paca' then
            principal = { accion = 'esparcir', tecla = 'E', texto = ('Esparcir heno (%d)'):format(carga.unidades or 0) }
        else
            aviso = 'Tierra sin trabajar: échale heno con el tractor o con una paca del acopio.'
        end
    elseif c.e == 'empajada' then
        principal = { accion = 'arar', tecla = 'E', texto = 'Arar a mano', apagada = not m.azada }
        aviso = m.azada and 'Pasa el rastrillo con el tractor o árala con la azada.'
            or 'Pasa el rastrillo con el tractor o compra una azada.'
    elseif c.e == 'arada' then
        local s = SemillaActual()
        principal = { accion = 'sembrar', tecla = 'E', texto = s and ('Sembrar ' .. s.nombre:lower()) or 'Sembrar',
            apagada = not s or (m.nivel or 1) < (s.nivel or 1), extra = s and s.id }
        if not s then aviso = 'No tienes semillas.' end
    elseif c.e == 'creciendo' then
        local r = m.regadera
        local riega = (G.parcelas[cfg.id].riego or 0) > 0
        principal = { accion = 'regar', tecla = 'E', texto = 'Regar',
            apagada = riega or not r or r.carga < 1 or (c.a or 0) > 95 }
        if c.pl then
            secundaria = { accion = 'fumigar', tecla = 'G', texto = 'Fumigar', apagada = (m.insecticida or 0) < 1 }
            aviso = 'Tiene plaga.'
        else
            secundaria = { accion = 'abonar', tecla = 'G', texto = 'Abonar', apagada = (m.abono or 0) < 1 or (c.ab or 0) > 60 }
        end
        if not aviso then
            if riega then aviso = 'Los aspersores la mantienen húmeda.'
            elseif not r then aviso = 'Enciende los aspersores en el depósito o riega con regadera.'
            elseif r.carga < 1 then aviso = 'Regadera vacía: llénala en el depósito, o enciende los aspersores.'
            elseif (c.a or 0) <= 0 then aviso = '¡Se está secando!'
            elseif (c.a or 0) < 25 then aviso = 'Le queda poca agua.' end
        end
    elseif c.e == 'lista' then
        local cult = Granja.Cultivo(c.c)
        local otra = carga and cult and carga.cultivo ~= cult.id
        local llena = carga and cult and carga.vol + cult.rinde[2] * (cult.volumen or 1) > carga.capacidad
        principal = { accion = 'cosechar', tecla = 'E', texto = 'Cosechar', apagada = otra or llena }
        if otra then aviso = 'Llevas otra cosa en las manos.'
        elseif llena then aviso = 'Lo que llevas está lleno: déjalo en el palé.' end
    elseif c.e == 'marchita' then
        principal = { accion = 'limpiar', tecla = 'E', texto = 'Limpiar' }
        aviso = 'Se ha echado a perder.'
    end

    if carga and principal and principal.accion ~= 'cosechar' and principal.accion ~= 'esparcir' then
        principal.apagada = true
        if secundaria then secundaria.apagada = true end
        aviso = 'Tienes las manos ocupadas.'
    end
    return principal, secundaria, aviso
end

-- ── La tarjeta ────────────────────────────────────────────────────────────

local function Tarjeta(cfg, idx, c, mia, principal, secundaria, aviso)
    local v = G.parcelas[cfg.id]
    local ajena = v.cid ~= nil and not mia
    local fila, col = Granja.FilaColumna(cfg, idx)
    local cult = Granja.Cultivo(c.c)
    local estado = c.e
    local restante = -1
    if c.e == 'creciendo' and (c.v or 0) > 0 then restante = math.ceil((1 - (c.p or 0)) / c.v) end

    local acciones = {}
    for _, a in ipairs({ principal, secundaria }) do
        if a then acciones[#acciones + 1] = { tecla = a.tecla, texto = a.texto, apagada = a.apagada or nil } end
    end

    local semilla
    if c.e == 'arada' and mia then
        local s = SemillaActual()
        if s then semilla = { nombre = s.nombre, cantidad = s.cantidad, otras = #Semillas() - 1 } end
    end

    return {
        visible = true,
        parcela = cfg.nombre,
        ajena = not mia,
        libre = v.cid == nil,
        dueno = ajena and (v.dueno ~= '' and v.dueno or 'otro granjero') or nil,
        robo = false,
        fila = fila + 1, columna = col + 1,
        estado = estado,
        cultivo = cult and { id = cult.id, nombre = cult.nombre } or nil,
        progreso = c.e == 'lista' and 1 or (c.p or 0),
        vel = c.v or 0,
        restante = restante,
        agua = c.a or 0,
        gasto = c.g or 0,
        abono = c.ab or 0,
        plaga = c.pl == true,
        calidad = c.q or 1,
        cansada = c.cn == true,
        cosechas = c.k or 0,
        semilla = semilla,
        regadera = G.mochila and G.mochila.regadera or nil,
        acciones = acciones,
        aviso = aviso,
    }
end

local function EsconderTarjeta()
    if ultimaTarjeta ~= 'nada' then
        ultimaTarjeta = 'nada'
        G.Nui('celda', { visible = false })
    end
end

-- ── Qué celda miras ───────────────────────────────────────────────────────

local function Apuntar()
    local ped = cache.ped
    if IsPedInAnyVehicle(ped, false) or IsPedDeadOrDying(ped, true) then return nil end
    local delante = GetOffsetFromEntityInWorldCoords(ped, 0.0, 1.0, 0.0)
    local pos = GetEntityCoords(ped)
    for _, cfg in ipairs(Config.Parcelas) do
        if G.parcelas[cfg.id] and Granja.DentroDe(cfg, pos.x, pos.y, 1.2) and math.abs(pos.z - cfg.centro.z) < 10.0 then
            local idx = Granja.CeldaEn(cfg, delante.x, delante.y) or Granja.CeldaEn(cfg, pos.x, pos.y)
            if idx then return cfg, idx end
        end
    end
    return nil
end

local ROSA = { 216, 27, 85, 150 }
local GRIS = { 255, 255, 255, 130 }
local AMBAR = { 240, 180, 41, 130 }

CreateThread(function()
    local mochilaPedida = 0
    while true do
        local espera = 500
        if G.cerca and not G.panelAbierto then
            local cfg, idx = Apuntar()
            if cfg then
                espera = 0
                apuntada = { cfg = cfg, idx = idx }
                local v = G.parcelas[cfg.id]
                local mia = G.EsMia(v)
                local ajena = v.cid ~= nil and not mia
                local c = G.Celda(cfg.id, idx)

                if G.Jornada() and GetGameTimer() - mochilaPedida > 10000 then
                    mochilaPedida = GetGameTimer()
                    CreateThread(G.PedirMochila)
                end

                Plantas.Resaltar(cfg, idx, mia and ROSA or (ajena and AMBAR or GRIS))
                local principal, secundaria, aviso = Acciones(cfg, idx, c, mia, ajena)

                -- La tarjeta solo se manda si cambia algo (o cada 2 s para
                -- corregir la extrapolación).
                if not G.ocupado then
                    local datos = Tarjeta(cfg, idx, c, mia, principal, secundaria, aviso)
                    local huella = json.encode({ datos.estado, datos.parcela, idx, datos.acciones, datos.aviso,
                        datos.semilla, datos.plaga, datos.calidad, datos.regadera, c.v, c.ab, math.floor((c.p or 0) * 20) })
                    if huella ~= ultimaTarjeta or GetGameTimer() - ultimoEnvio > 2000 then
                        ultimaTarjeta = huella
                        ultimoEnvio = GetGameTimer()
                        G.Nui('celda', datos)
                    end
                else
                    EsconderTarjeta()
                end

                if G.Jornada() and not G.ocupado then
                    if c.e == 'arada' then
                        local lista = Semillas()
                        if #lista > 1 and (IsControlJustReleased(0, IZQ) or IsControlJustReleased(0, DER)) then
                            local _, i = SemillaActual()
                            i = IsControlJustReleased(0, DER) and (i % #lista) + 1 or ((i - 2) % #lista) + 1
                            semillaElegida = lista[i].id
                            PlaySoundFrontend(-1, 'NAV_LEFT_RIGHT', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                        end
                    end
                    if principal and not principal.apagada and IsControlJustReleased(0, TECLA_E) then
                        CreateThread(function() Campo.Ejecutar(principal.accion, cfg.id, idx, principal.extra) end)
                    elseif secundaria and not secundaria.apagada and IsControlJustReleased(0, TECLA_G) then
                        CreateThread(function() Campo.Ejecutar(secundaria.accion, cfg.id, idx, secundaria.extra) end)
                    end
                end
            else
                apuntada = nil
                EsconderTarjeta()
            end
        else
            apuntada = nil
            EsconderTarjeta()
        end
        Wait(espera)
    end
end)

function Campo.Apuntada() return apuntada end
