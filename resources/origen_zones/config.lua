--[[
    ORIGEN ZONES · el catálogo

    Una zona es un trozo de mapa con reglas dentro. Las reglas se describen
    AQUÍ y en ningún otro sitio: el panel las pinta leyendo esta misma tabla
    —se la manda el servidor tal cual—, así que para añadir una regla nueva se
    toca este fichero y la función que la aplica, y nada más.

    Cada regla lleva:
        grupo       en qué apartado del panel sale
        rotulo      cómo se llama para quien la configura
        pista       una línea de qué hace
        icono       nombre de Lucide
        donde       'cliente' | 'servidor' | 'ambos'  ← quién la hace cumplir
        ajustes     los campos que salen debajo del interruptor

    Un ajuste puede ser:
        numero   { min, max, paso }
        si_no
        opcion   { opciones = { { v = ..., t = ... }, ... } }
        texto
        lista    (texto separado por comas; llega al Lua como tabla)
]]

Config = {}

-- Cómo se abre el panel
Config.Comando = 'zonas'
Config.Permiso = 'origen_zones' -- el id que mira origen_admin

-- Cada cuánto se mira dónde está la gente.
-- El cliente va rápido porque de él dependen los avisos; el servidor va más
-- lento porque solo necesita saberlo para lo que valida.
Config.Ritmo = {
    cliente = 300,
    servidor = 700,
}

Config.Depurar = false

-- Los grupos del panel, en el orden en que salen.
Config.Grupos = {
    { clave = 'trafico',   rotulo = 'Tráfico y movimiento', icono = 'lucide:car' },
    { clave = 'seguridad', rotulo = 'Seguridad',            icono = 'lucide:shield' },
    { clave = 'acceso',    rotulo = 'Quién entra',          icono = 'lucide:door-open' },
    { clave = 'ambiente',  rotulo = 'Ambiente',             icono = 'lucide:cloud-sun' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- LAS REGLAS
-- ═══════════════════════════════════════════════════════════════════════════

Config.Reglas = {

    -- ── Tráfico y movimiento ────────────────────────────────────────────
    {
        clave = 'sin_trafico',
        grupo = 'trafico',
        rotulo = 'Sin coches de NPC',
        pista = 'El juego deja de soltar tráfico dentro de la zona',
        icono = 'lucide:car-front',
        donde = 'cliente',
        ajustes = {
            { clave = 'aparcados', tipo = 'si_no', rotulo = 'También los aparcados',
              pista = 'Los que el juego deja en la acera tampoco salen', porDefecto = true },
            { clave = 'limpiar', tipo = 'si_no', rotulo = 'Barrer los que ya estén',
              pista = 'Al entrar se llevan los que hubiera, si no lleva nadie dentro', porDefecto = false },
        },
    },
    {
        clave = 'sin_peatones',
        grupo = 'trafico',
        rotulo = 'Sin peatones de NPC',
        pista = 'Ni gente andando ni los corrillos de las escenas',
        icono = 'lucide:user-x',
        donde = 'cliente',
        ajustes = {
            { clave = 'limpiar', tipo = 'si_no', rotulo = 'Barrer los que ya estén',
              pista = 'Al entrar se llevan los que hubiera', porDefecto = false },
        },
    },
    {
        clave = 'velocidad',
        grupo = 'trafico',
        rotulo = 'Límite de velocidad',
        pista = 'Dentro no se pasa de la marca',
        icono = 'lucide:gauge',
        donde = 'cliente',
        ajustes = {
            { clave = 'kmh', tipo = 'numero', rotulo = 'Máximo (km/h)', porDefecto = 30, min = 5, max = 250, paso = 5 },
            { clave = 'modo', tipo = 'opcion', rotulo = 'Qué se hace con quien corre', porDefecto = 'frenar',
              opciones = {
                  { v = 'frenar', t = 'El coche no puede ir más deprisa' },
                  { v = 'avisar', t = 'Solo se le avisa' },
              } },
            { clave = 'emergencias', tipo = 'si_no', rotulo = 'También a emergencias',
              pista = 'Policía y sanitarios tampoco se libran', porDefecto = false },
        },
    },
    {
        clave = 'sin_conducir',
        grupo = 'trafico',
        rotulo = 'Prohibido entrar en coche',
        pista = 'Se aparca fuera y se entra andando',
        icono = 'lucide:circle-parking-off',
        donde = 'cliente',
        ajustes = {
            { clave = 'sacar', tipo = 'si_no', rotulo = 'Bajarle del coche',
              pista = 'Si no, solo se le avisa', porDefecto = false },
            { clave = 'emergencias', tipo = 'si_no', rotulo = 'También a emergencias', porDefecto = false },
        },
    },
    {
        clave = 'sin_bajarse',
        grupo = 'trafico',
        rotulo = 'Prohibido bajarse del coche',
        pista = 'Zona de paso: se cruza conduciendo',
        icono = 'lucide:car-taxi-front',
        donde = 'cliente',
        ajustes = {},
    },
    {
        clave = 'altura_vuelo',
        grupo = 'trafico',
        rotulo = 'Altura mínima de vuelo',
        pista = 'Ni helicópteros ni avionetas por debajo de la marca',
        icono = 'lucide:plane',
        donde = 'cliente',
        ajustes = {
            { clave = 'metros', tipo = 'numero', rotulo = 'Altura sobre el suelo (m)', porDefecto = 150, min = 10, max = 1500, paso = 10 },
            { clave = 'empujar', tipo = 'si_no', rotulo = 'Empujarle hacia arriba',
              pista = 'Si no, solo se le avisa', porDefecto = false },
            { clave = 'emergencias', tipo = 'si_no', rotulo = 'También a emergencias', porDefecto = false },
        },
    },

    -- ── Seguridad ───────────────────────────────────────────────────────
    {
        clave = 'sin_armas',
        grupo = 'seguridad',
        rotulo = 'Sin armas',
        pista = 'Dentro no se saca nada; quien lo intente se queda desarmado',
        icono = 'lucide:shield-off',
        donde = 'ambos',
        ajustes = {
            { clave = 'trabajos', tipo = 'lista', rotulo = 'Trabajos que se libran',
              pista = 'Separados por comas', porDefecto = { 'police', 'sheriff', 'ambulance' } },
            { clave = 'avisar', tipo = 'si_no', rotulo = 'Avisar al intentarlo', porDefecto = true },
        },
    },
    {
        clave = 'zona_segura',
        grupo = 'seguridad',
        rotulo = 'Zona segura',
        pista = 'Aquí no se mata a nadie. Lo comprueba el servidor, no el cliente',
        icono = 'lucide:heart-pulse',
        donde = 'ambos',
        ajustes = {
            { clave = 'melee', tipo = 'si_no', rotulo = 'Tampoco a puñetazos', porDefecto = true },
            { clave = 'desde_fuera', tipo = 'si_no', rotulo = 'Ni disparando desde fuera',
              pista = 'Protege también al que está dentro cuando le tiran desde la calle de al lado',
              porDefecto = true },
            { clave = 'avisar', tipo = 'si_no', rotulo = 'Avisar al entrar', porDefecto = true },
        },
    },
    {
        clave = 'sin_busqueda',
        grupo = 'seguridad',
        rotulo = 'Sin nivel de búsqueda',
        pista = 'La policía del juego no viene aquí',
        icono = 'lucide:badge-x',
        donde = 'cliente',
        ajustes = {
            { clave = 'limpiar', tipo = 'si_no', rotulo = 'Quitar el que ya traiga',
              pista = 'Si no, solo se congela mientras esté dentro', porDefecto = true },
        },
    },
    {
        clave = 'sin_explosiones',
        grupo = 'seguridad',
        rotulo = 'Sin explosiones ni fuego',
        pista = 'Lo corta el servidor: nada de granadas, pegatinas ni incendios',
        icono = 'lucide:flame-kindling',
        donde = 'servidor',
        ajustes = {
            { clave = 'fuego', tipo = 'si_no', rotulo = 'También el fuego suelto', porDefecto = true },
        },
    },

    -- ── Quién entra ─────────────────────────────────────────────────────
    {
        clave = 'acceso',
        grupo = 'acceso',
        rotulo = 'Solo entra quien deba',
        pista = 'Por trabajo o por banda. Lo comprueba el servidor',
        icono = 'lucide:door-open',
        donde = 'ambos',
        ajustes = {
            { clave = 'trabajos', tipo = 'lista', rotulo = 'Trabajos que pueden entrar',
              pista = 'Separados por comas. En blanco, ninguno por trabajo', porDefecto = { 'police' } },
            { clave = 'bandas', tipo = 'lista', rotulo = 'Bandas que pueden entrar',
              pista = 'Separadas por comas', porDefecto = {} },
            { clave = 'que_hago', tipo = 'opcion', rotulo = 'Con quien no debería estar', porDefecto = 'avisar',
              opciones = {
                  { v = 'avisar', t = 'Avisarle y dejarlo ahí' },
                  { v = 'echar', t = 'Sacarle fuera de la zona' },
              } },
            { clave = 'mensaje', tipo = 'texto', rotulo = 'Lo que se le dice',
              porDefecto = 'Este sitio no es para ti.' },
        },
    },

    -- ── Ambiente ────────────────────────────────────────────────────────
    {
        clave = 'clima',
        grupo = 'ambiente',
        rotulo = 'Hora y clima propios',
        pista = 'Dentro siempre hace el tiempo que tú digas',
        icono = 'lucide:cloud-sun',
        donde = 'cliente',
        ajustes = {
            { clave = 'tiempo', tipo = 'opcion', rotulo = 'Qué tiempo hace', porDefecto = 'ninguno',
              opciones = {
                  { v = 'ninguno', t = 'El que toque fuera' },
                  { v = 'EXTRASUNNY', t = 'Sol de justicia' },
                  { v = 'CLEAR', t = 'Despejado' },
                  { v = 'CLOUDS', t = 'Nublado' },
                  { v = 'OVERCAST', t = 'Cubierto' },
                  { v = 'RAIN', t = 'Lluvia' },
                  { v = 'THUNDER', t = 'Tormenta' },
                  { v = 'FOGGY', t = 'Niebla' },
                  { v = 'SMOG', t = 'Bruma sucia' },
                  { v = 'XMAS', t = 'Nieve' },
                  { v = 'HALLOWEEN', t = 'Noche de brujas' },
              } },
            { clave = 'hora', tipo = 'numero', rotulo = 'Hora que marca el reloj',
              pista = 'De 0 a 23. Con −1 se deja la del servidor', porDefecto = -1, min = -1, max = 23, paso = 1 },
        },
    },
    {
        clave = 'sin_sirenas',
        grupo = 'ambiente',
        rotulo = 'Sin sirenas',
        pista = 'Las luces siguen; el ruido no',
        icono = 'lucide:volume-x',
        donde = 'cliente',
        ajustes = {
            { clave = 'alrededor', tipo = 'si_no', rotulo = 'También las de los coches de al lado',
              porDefecto = true },
        },
    },
}

-- Índice por clave, que es como se busca casi siempre.
Config.ReglaPorClave = {}
for _, regla in ipairs(Config.Reglas) do
    Config.ReglaPorClave[regla.clave] = regla
end

-- Los ajustes de una regla tal y como salen de fábrica.
function Config.AjustesDeFabrica(clave)
    local regla = Config.ReglaPorClave[clave]
    if not regla then return {} end

    local salida = {}
    for _, campo in ipairs(regla.ajustes) do
        if type(campo.porDefecto) == 'table' then
            local copia = {}
            for i, v in ipairs(campo.porDefecto) do copia[i] = v end
            salida[campo.clave] = copia
        else
            salida[campo.clave] = campo.porDefecto
        end
    end
    return salida
end

-- ═══════════════════════════════════════════════════════════════════════════
-- LOS BLIPS QUE PUEDE LLEVAR UNA ZONA EN EL MAPA
-- ═══════════════════════════════════════════════════════════════════════════

Config.Blips = {
    { v = 0,   t = 'Sin marca' },
    { v = 487, t = 'Zona' },
    { v = 364, t = 'Aviso' },
    { v = 175, t = 'Prohibido' },
    { v = 402, t = 'Peatonal' },
    { v = 198, t = 'Velocidad' },
    { v = 310, t = 'Seguro' },
    { v = 568, t = 'Ambiente' },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- LOS ENCHUFES CON EL RESTO DEL SERVIDOR
-- ═══════════════════════════════════════════════════════════════════════════

if IsDuplicityVersion() then
    -- Quién puede tocar el panel.
    function Config.EsAdmin(source)
        if GetResourceState('origen_admin') == 'started' then
            local ok = exports['origen_admin']:HasPermission(source, Config.Permiso)
            if ok then return true end
        end

        local core = exports['qb-core'] and exports['qb-core']:GetCoreObject()
        if core and core.Functions and core.Functions.HasPermission then
            if core.Functions.HasPermission(source, 'admin') then return true end
            if core.Functions.HasPermission(source, 'god') then return true end
        end

        return IsPlayerAceAllowed(source, 'command.' .. Config.Comando)
    end

    -- El trabajo y la banda de alguien, que es lo que miran `acceso` y
    -- `sin_armas`. Si el framework no contesta, se devuelve nada y la regla
    -- trata a ese jugador como a uno de la calle.
    function Config.QuienEs(source)
        local ficha = { trabajo = nil, banda = nil }

        local ok, player = pcall(function()
            return exports.qbx_core:GetPlayer(source)
        end)

        if ok and player and player.PlayerData then
            ficha.trabajo = player.PlayerData.job and player.PlayerData.job.name or nil
            ficha.banda = player.PlayerData.gang and player.PlayerData.gang.name or nil
        end

        if GetResourceState('origen_ilegalv2') == 'started' then
            local ok2, banda = pcall(function()
                return exports.origen_ilegalv2:GetPlayerGang(source)
            end)
            if ok2 and banda then ficha.banda = banda end
        end

        return ficha
    end

    function Config.Avisar(source, texto, tipo)
        if GetResourceState('origen_notify') == 'started' then
            TriggerClientEvent('origen_notify:SendNotification', source, {
                description = texto,
                type = tipo or 'info',
                duration = 4000,
            })
        else
            TriggerClientEvent('origen_zones:aviso', source, texto, tipo)
        end
    end
end
