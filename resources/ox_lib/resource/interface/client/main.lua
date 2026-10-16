--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@alias IconProp 'fas' | 'far' | 'fal' | 'fat' | 'fad' | 'fab' | 'fak' | 'fass'

local keepInput = IsNuiFocusKeepingInput()

function lib.setNuiFocus(allowInput, disableCursor)
    keepInput = IsNuiFocusKeepingInput()
    SetNuiFocus(true, not disableCursor)
    SetNuiFocusKeepInput(allowInput)
end

function lib.resetNuiFocus()
    --[[ ORIGEN (18/09): las teclas ANTES que el foco, y no se devuelve el
         KeepInput de antes. FiveM lleva un contador por recurso, no un si/no:
         soltar el foco con KeepInput encendido (lib.showMenu lo abre asi) lo
         descuadraba para toda la partida y las pantallas siguientes no le
         quitaban el raton al juego (cursor clavado en medio, camara girando
         detras). Quien quiera KeepInput con el foco puesto —el telefono— lo
         vuelve a poner el solo. ]]
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end

--[[ ORIGEN (07/10): la web de ox lleva el trozo «ORIGEN · marca» en su
     index.html (repinta el rosa de web/build/pegatina.css al naranja de
     Nación). Ese trozo pregunta la marca a su propio recurso con este
     callback; es el mismo que pone @origen_map/shared/tema.lua en los
     nuestros, que aquí no se carga para no meter más cosas en la librería.
     OJO: si se actualiza ox_lib, esto hay que volver a ponerlo. ]]
RegisterNUICallback('origen:marca:dame', function(_, cb)
    cb({ marca = GetConvar('origen:marca', 'origen') })
end)
