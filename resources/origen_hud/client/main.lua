-- Ocultar/mostrar el HUD cuando hay una carrera activa
AddEventHandler('origen_hud:setRacingMode', function(isRacing)
    -- Oculta/muestra el panel de stats del jugador
    SendNUIMessage({ action = 'toggleHud', data = { show = not isRacing } })
    -- Oculta/muestra el CarHud (velocímetro, combustible, etc.)
    SendNUIMessage({ action = 'updateVehState', key = 'visible', value = not isRacing })
end)

-- lib.addKeybind({
--     name = 'moveHud',
--     description = 'Move the HUD position',
--     defaultKey = 'F3',
--     onPressed = function(self)
--         SetNuiFocus(true, true)
--     end
-- })

--[[ 07/10: con el menu de Ajustes abierto (origen_ajustes lanza
     TriggerEvent('origen:ajustes', bool)) se aparta todo el HUD: lo hace
     ui/index.html con body.en-ajustes, sin tocar el estado de cada pieza. ]]
AddEventHandler('origen:ajustes', function(abierto)
    SendNUIMessage({ action = 'origen:ajustes', abierto = abierto == true })
end)

RegisterNUICallback('unfocus', function(data, cb)
    --[[ El App.vue lo manda con ESC o F3 cuando nadie mas se ha quedado la
         tecla. Lo unico de este recurso que coge el foco es el radial: si
         estaba abierto, se cierra entero (Cerrar suelta el foco y deja de
         bloquear la camara). Soltar solo el foco lo dejaba «abierto» en Lua
         sin raton: camara bloqueada y ESC que ya no abria nada (27/09). ]]
    if RadialCerrarDesdeFuera then RadialCerrarDesdeFuera() end
    if PanelesCerrarDesdeFuera then PanelesCerrarDesdeFuera() end
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    cb('ok')
end)
