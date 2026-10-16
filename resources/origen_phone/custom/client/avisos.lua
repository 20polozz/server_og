--[[ CÓMO SE VE UN AVISO CUANDO EL TELÉFONO ESTÁ GUARDADO

     De serie asoma el propio móvil por abajo, con tu marco, tu fondo y tu hora.
     Esto es para servidores que prefieran otra cosa: su propio sistema de
     avisos, o nada.

     Solo afecta a lo que se ve **fuera** del teléfono. Con el móvil abierto, el
     aviso sale dentro como siempre — ahí no hay nada que decidir.
]]

--[[ Enseñar un aviso a tu manera.

     @param datos  table  { app, title, content, avatar, thumbnail }

     @return nil    -> que asome el teléfono, como de serie
     @return true   -> ya lo has enseñado tú; el teléfono no hace nada

     Ejemplo — usar el sistema de avisos del servidor en vez del móvil:

         function Custom.Aviso(datos)
             exports['origen_notify']:Notify({
                 title = datos.title,
                 description = datos.content,
                 duration = 5000,
             })

             return true
         end

     Ejemplo — que solo asome el móvil con lo importante, y lo demás por arriba:

         function Custom.Aviso(datos)
             if datos.app == 'phone' or datos.app == 'messages' then
                 return nil          --- una llamada o un mensaje, con el móvil
             end

             exports['origen_notify']:Notify({ description = datos.content })
             return true
         end
]]
---@param datos table
---@return boolean|nil
function Custom.Aviso(datos)
    return nil
end
