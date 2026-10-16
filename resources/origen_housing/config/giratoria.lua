-- Plataformas giratorias de exposición (custom/client/giratoria.lua y
-- custom/server/giratoria.lua). Son muebles del catálogo (config/furniture.lua,
-- type = 'turntable'): a pie junto a una, la E la pone a girar o la para, con
-- el coche que tenga encima. Gira para todos los que están en la casa.
Config.Giratoria = {
    velocidad = 10.0,   -- grados por segundo
    ritmo = 1500,       -- ms mínimos entre dos órdenes del mismo jugador (lo mira el servidor)
    tope = 14.0,        -- lo más lejos de la plataforma que el servidor da por bueno
    margen = 1.5,       -- metros alrededor de la plataforma en los que sale la E
    -- Los modelos que giran. `radio` (opcional): en vez del que sale de la caja del modelo.
    modelos = {
        -- propias (origen_modelos/stream/casa_obra): disco de 6 cm con el canto en rampa
        ['origen_casa_giratoria_s'] = { radio = 2.30 },     -- un coche normal
        ['origen_casa_giratoria_m'] = { radio = 2.80 },     -- deportivos largos y todoterrenos
        ['origen_casa_giratoria_l'] = { radio = 3.50 },
        -- las del juego ya no están en el catálogo; las que queden puestas siguen girando
        ['vw_prop_vw_casino_podium_01a'] = {},
        ['xs_prop_arena_turntable_01a'] = {},
    },
}

function Config.Giratoria.Es(modelo)
    if type(modelo) == 'number' then
        for nombre in pairs(Config.Giratoria.modelos) do
            if joaat(nombre) == modelo then return nombre end
        end
        return nil
    end
    return type(modelo) == 'string' and Config.Giratoria.modelos[modelo] and modelo or nil
end
