--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

local blips = {}

CreateThread(function()
    for i, hoopData in pairs(BasketballHoops) do
        if not hoopData.hideBlip then
            local blip = 'canasta_' .. tostring(i)
            OrigenMapa.Poner(blip, {
                x = hoopData.pos.x, y = hoopData.pos.y, z = hoopData.pos.z,
                cat = 'activities',
                icono = 'baloncesto',
                nombre = Config.Text.BLIP or 'Baloncesto',
            })

            table.insert(blips, blip)
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if GetCurrentResourceName() == name then
        for _, b in pairs(blips) do
            OrigenMapa.Quitar(b)
        end
    end
end)
