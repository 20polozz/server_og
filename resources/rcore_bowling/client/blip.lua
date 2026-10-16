--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

local blips = {}

CreateThread(function()
    local coords = Config.Blips or {
		vector3(-149.44, -258.21, 44.14), -- breze bowling map
		-- vector3(749.92, -776.68, 26.33), -- gabz bowling map
    }

    for i, c in pairs(coords) do
        local blip = 'bolera_' .. tostring(i)
        OrigenMapa.Poner(blip, {
            x = c.x, y = c.y, z = c.z,
            cat = 'activities',
            icono = 'bolos',
            nombre = Config.Text.BLIP,
        })

        table.insert(blips, blip)
    end
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() == name then
        for _, b in pairs(blips) do
            OrigenMapa.Quitar(b)
        end
    end
end)
