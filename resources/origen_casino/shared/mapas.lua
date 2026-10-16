--[[ ══════════════════════════════════════════════════════════════════════════
     LOS MAPAS DE CASINO: qué muebles traen y para qué sirve cada uno

     Un mapa de casino ya trae sus mesas, sus máquinas y su rueda. En vez de
     poner muebles nuevos encima, el panel («Traer del mapa») busca los que hay
     alrededor del admin y crea un punto por cada uno, SIN mueble propio: los
     asientos, el crupier, las cartas y los rodillos se montan sobre el del
     mapa.

     Hay tres casos:

       · Un mueble del casino de GTA tal cual (una tragaperras, una mesa de
         blackjack…): se usa como está.
       · Un mueble de GTA de otra variante que la del catálogo (la ruleta
         `_01` en vez de la `_01b`): se CAMBIA en el juego por la del catálogo
         (CreateModelSwap), que es la que tiene los huesos y las medidas.
       · Un mueble propio del mapa (la mesa de Jurassic Jackpot): igual, se
         cambia por la mesa de GTA que toca en ese sitio. Qué juego es cada una
         lo dice la lista de `sitios` de abajo, sacada de la configuración que
         usaba rcore_casino para este mismo mapa.

     La rueda propia de un mapa no sirve para girar: se esconde y se pone la
     nuestra en su sitio.
   ══════════════════════════════════════════════════════════════════════════ ]]

Mapas = {}

--- Muebles de GTA que se reconocen solos: el modelo y el tipo del catálogo.
Mapas.Vanilla = {
    vw_prop_casino_slot_01a = 'slot_diamante', vw_prop_casino_slot_01b = 'slot_diamante',
    vw_prop_casino_slot_02a = 'slot_fortuna', vw_prop_casino_slot_02b = 'slot_fortuna',
    vw_prop_casino_slot_03a = 'slot_impulso', vw_prop_casino_slot_03b = 'slot_impulso',
    vw_prop_casino_slot_04a = 'slot_tesoro', vw_prop_casino_slot_04b = 'slot_tesoro',
    vw_prop_casino_slot_05a = 'slot_galaxia', vw_prop_casino_slot_05b = 'slot_galaxia',
    vw_prop_casino_slot_06a = 'slot_leon', vw_prop_casino_slot_06b = 'slot_leon',
    vw_prop_casino_slot_07a = 'slot_estrella', vw_prop_casino_slot_07b = 'slot_estrella',
    vw_prop_casino_slot_08a = 'slot_fuego', vw_prop_casino_slot_08b = 'slot_fuego',
    vw_prop_casino_blckjack_01 = 'blackjack', vw_prop_casino_blckjack_01b = 'blackjack',
    vw_prop_casino_3cardpoker_01b = 'pokertres',
    vw_prop_casino_3cardpoker_01 = 'holdem',
    vw_prop_casino_roulette_01 = 'ruleta', vw_prop_casino_roulette_01b = 'ruleta',
    vw_prop_vw_luckywheel_01a = 'rueda',
}

--[[ Los mapas con muebles propios. Cada uno: los modelos suyos y, por sitio,
     qué juego va en cada mesa. Un mueble propio que no esté en la lista de
     sitios se trata como `porDefecto`. ]]
Mapas.Propios = {
    {
        nombre = 'Jurassic Jackpot (tstudio)',
        recurso = 'tstudio_jurassic_jackpot',
        -- Los muebles del mapa y en qué se convierten.
        mesa = 'johanni_jurassic_asset_blckjack_01b',
        rueda = 'johanni_jurassic_asset_lucky_wheel',
        porDefecto = 'blackjack',
        --[[ Sacado de rcore_casino (client/main/casino.lua, MapType 11): en cada
             sitio cambiaba la mesa del mapa por esta. Las dos de la planta de
             arriba (z 45) son del despacho. ]]
        sitios = {
            { x = -242.84, y = -909.23, z = 31.31, tipo = 'blackjack' },
            { x = -237.60, y = -912.90, z = 31.32, tipo = 'blackjack' },
            { x = -264.80, y = -913.40, z = 45.20, tipo = 'blackjack' },
            { x = -261.50, y = -917.00, z = 31.30, tipo = 'ruleta' },
            { x = -257.00, y = -905.60, z = 31.30, tipo = 'ruleta' },
            { x = -241.80, y = -924.30, z = 31.30, tipo = 'ruleta' },
            { x = -252.00, y = -905.80, z = 31.30, tipo = 'pokertres' },
            { x = -258.00, y = -916.10, z = 31.30, tipo = 'holdem' },
        },
        -- Lo que el mapa no trae como mueble y rcore ponía a mano.
        extras = {
            { tipo = 'caja', x = -263.37, y = -913.20, z = 31.31, h = 34.0, nombre = 'Caja' },
        },
        -- La rueda de rcore iba aquí; la nuestra se pone en el mismo sitio.
        ruedaSitio = { x = -247.98, y = -906.78, z = 31.32, h = 340.0 },
    },
}

--- El tipo que le toca a un mueble propio en un sitio.
function Mapas.TipoEn(mapa, x, y, z)
    local mejor, dist = nil, 1.6
    for _, s in ipairs(mapa.sitios or {}) do
        local d = math.sqrt((s.x - x) ^ 2 + (s.y - y) ^ 2 + (s.z - z) ^ 2)
        if d < dist then mejor, dist = s.tipo, d end
    end
    return mejor or mapa.porDefecto
end
