-- Luces de las casas (custom/client/luces.lua y custom/server/luces.lua).
-- Cada lámpara son dos modelos de origen_modelos: `origen_casa_luz_<id>`
-- (encendida: lleva la luz y el emisivo dentro del modelo) y
-- `origen_casa_luz_<id>_off` (apagada). El mueble que se compra y se guarda es
-- siempre el encendido (catálogo: config/furniture.lua, categoría «Luces»);
-- apagada es cosa de cada cliente, que esconde el mueble y pone en su sitio el
-- modelo `_off`. Qué está apagado lo guarda el servidor en luces.json.
-- Las lámparas del juego del catálogo no entran aquí: siguen como estaban.
Config.Luces = {
    ritmo = 700,            -- ms mínimos entre dos pulsaciones del mismo jugador (lo mira el servidor)
    alcance = 1.4,          -- metros a los que sale la E de una lámpara de pie, de mesa o de pared
    alcanceInterruptor = 1.3,
    tope = 4.0,             -- lo más lejos del mueble que el servidor da por bueno
    radio = 12.0,           -- casas que no son de obra: el interruptor lleva las lámparas a esta distancia de él
    borde = 0.30,           -- casas de obra: un interruptor a menos de esto de una pared es de la sala de quien lo pulsa
    maxSala = 4000,         -- celdas que se recorren como mucho buscando la sala

    prefijo = 'origen_casa_luz_',

    -- Los interruptores: con la E encienden o apagan todas las lámparas de su sala.
    -- (Si algún día hace falta uno del juego mientras llega el propio, se añade aquí
    -- y en el catálogo.)
    interruptores = {
        ['origen_casa_luz_interruptor'] = true,
        ['origen_casa_luz_interruptor_ind'] = true,     -- de superficie, industrial
    },

    -- tipo: dónde va (techo, pared, pie, mesa, color). mano: se enciende y se apaga
    -- también con la E junto a ella; las de techo, solo con el interruptor.
    lamparas = {
        downlight       = { tipo = 'techo', nombre = 'Foco empotrado' },
        plafon          = { tipo = 'techo', nombre = 'Plafón' },
        fluorescente    = { tipo = 'techo', nombre = 'Fluorescente' },
        colgante        = { tipo = 'techo', nombre = 'Lámpara colgante' },
        arana           = { tipo = 'techo', nombre = 'Lámpara de araña' },
        industrial      = { tipo = 'techo', nombre = 'Campana industrial' },
        bombilla        = { tipo = 'techo', nombre = 'Bombilla' },
        panel_led       = { tipo = 'techo', nombre = 'Panel LED' },
        aplique         = { tipo = 'pared', nombre = 'Aplique', mano = true },
        aplique_moderno = { tipo = 'pared', nombre = 'Aplique moderno', mano = true },
        foco_pared      = { tipo = 'pared', nombre = 'Foco de pared', mano = true },
        pie             = { tipo = 'pie', nombre = 'Lámpara de pie', mano = true },
        mesa            = { tipo = 'mesa', nombre = 'Lámpara de mesa', mano = true },
        foco_obra       = { tipo = 'pie', nombre = 'Foco de obra', mano = true },
        neon_rosa       = { tipo = 'color', nombre = 'Neón rosa', mano = true },
        neon_azul       = { tipo = 'color', nombre = 'Neón azul', mano = true },
        neon_verde      = { tipo = 'color', nombre = 'Neón verde', mano = true },
        neon_rojo       = { tipo = 'color', nombre = 'Neón rojo', mano = true },
        neon_morado     = { tipo = 'color', nombre = 'Neón morado', mano = true },
        tira_calida     = { tipo = 'color', nombre = 'Tira de luz cálida', mano = true },
    },
}

local PORNOMBRE, PORHASH, INTERRUPTOR = {}, {}, {}
for id, l in pairs(Config.Luces.lamparas) do
    l.id = id
    l.modelo = Config.Luces.prefijo .. id
    l.apagada = l.modelo .. '_off'
    PORNOMBRE[l.modelo] = l
    PORHASH[joaat(l.modelo)] = l
end
for nombre in pairs(Config.Luces.interruptores) do
    INTERRUPTOR[nombre] = true
    INTERRUPTOR[joaat(nombre)] = true
end

--- Los datos de una lámpara nuestra por el modelo del mueble (nombre o hash), o nil.
function Config.Luces.Lampara(modelo)
    if type(modelo) == 'number' then return PORHASH[modelo] end
    return type(modelo) == 'string' and PORNOMBRE[modelo] or nil
end

--- ¿Es un interruptor ese modelo (nombre o hash)?
function Config.Luces.Interruptor(modelo)
    local t = type(modelo)
    return (t == 'string' or t == 'number') and INTERRUPTOR[modelo] == true
end
