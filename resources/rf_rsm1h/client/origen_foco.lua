--[[ ORIGEN (27/09): el Lua de este recurso va cifrado y no se puede tocar.
     Cuando el vigilante del raton (@origen_map/shared/foco.lua) le quita el
     foco a la fuerza —`soltarraton`, o la pagina sin nada delante— se le pide
     a la pagina que cierre lo que tenga abierto. El cierre de la tablet avisa
     a Lua por su camino normal (callback `close`), asi que el estado cifrado
     tambien queda cerrado. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        SendNUIMessage({ action = 'close' })
        SendNUIMessage({ action = 'lift:close' })
        SendNUIMessage({ action = 'phone:close' })
    end)
end
