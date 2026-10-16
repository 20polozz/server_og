-- Types of stores: clothes, vip, exclusiva, tattoos, barber, masks
Config.StoreTypes = {
    clothes = {
        blip = {
            sprite = 73,
            color = 4,
            scale = 0.7,
            name = "Tienda de ropa",
        },
        label = "Tienda de ropa",
    },
    barber = {
        blip = {
            sprite = 71,
            color = 4,
            scale = 0.7,
            name = "Barbería",
        },
        label = "Barbería",
    },
    tattoos = {
        blip = {
            sprite = 75,
            color = 4,
            scale = 0.7,
            name = "Tatuajes",
        },
        label = "Tienda de tatuajes",
    },
    --- Solo la ropa marcada como VIP en /gestionropa, y solo para quien tenga
    --- el rango de Discord de Config.Vip (o sea admin). Ver server/vip.lua.
    vip = {
        blip = {
            sprite = 73,
            color = 5,          -- dorado en los mapas de origen_map (OrigenMapa.Color)
            icono = 'corona',   -- el dibujo en el minimapa y en el mapa del inventario
            scale = 0.7,
            name = "Tienda VIP",
        },
        label = "Tienda VIP",
    },
    --- Ropa que se paga con XP y tiene stock por color. Ver server/exclusiva.lua.
    exclusiva = {
        blip = {
            sprite = 73,
            color = 83,         -- morado en los mapas de origen_map (OrigenMapa.Color)
            icono = 'gema',     -- el dibujo en el minimapa y en el mapa del inventario
            scale = 0.7,
            name = "Tienda exclusiva",
        },
        label = "Tienda exclusiva",
    },
    masks = {
        blip = {
            sprite = 362,
            color = 4,
            scale = 0.7,
            name = "Tienda de máscaras",
        },
        label = "Tienda de máscaras",
    },
}