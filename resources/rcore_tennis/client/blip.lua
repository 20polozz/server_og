--[[ NOTA DE ORIGEN: este recurso ya no crea blips del juego.

     Los puntos se registran en origen_map, que es de donde los leen los tres
     mapas del servidor (el minimapa, el del menu de pausa y la pestaña de
     Ciudad del inventario). El ayudante que lo hace se carga desde el
     fxmanifest: '@origen_map/shared/marcar.lua'.

     Es un recurso de terceros: si llega una version nueva, este cambio hay que
     volver a hacerlo. ]]

local blips = {}

CreateThread(function()
    AddTextEntry('R_TEN_BL', Config.Translation.BLIP or 'Tennis')
    for i, tennisCourt in pairs(TennisCourts) do
        if tennisCourt.showBlip then
            local blip = 'pista_' .. tostring(i)
            OrigenMapa.Poner(blip, {
                x = tennisCourt.courtCenter.x, y = tennisCourt.courtCenter.y, z = tennisCourt.courtCenter.z,
                cat = 'activities',
                icono = 'tenis',
                nombre = Config.Translation.BLIP or 'Tenis',
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
