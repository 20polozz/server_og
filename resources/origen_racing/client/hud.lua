-- ========================================
-- CLIENTE: HUD DE CARRERA
-- ========================================

-- NOTA: El HUD se gestiona completamente desde racing.lua vía SendNUIMessage.
-- Los eventos de red racing:initHUD / racing:updateHUD / racing:closeHUD y el
-- HUDThread basado en ellos han sido eliminados porque el servidor nunca los emite.
-- El sistema activo es: initRaceHUD → updateRaceHUD → closeRaceHUD (SendNUIMessage).

-- (Aqui iban DrawNativeHUD y DrawHUDText, un HUD con texto nativo de
-- reserva al que nadie llamaba: el HUD de carrera es la NUI.)

-- NOTA: FormatTime (ms) está definida en racing.lua (cargado antes)

-- ========================================
-- EXPORTS
-- ========================================

--[[ Antes devolvian dos variables de este fichero que no cambiaba nadie: el
     HUD siempre «apagado» y siempre en la posicion 1 de 1. Ahora dicen lo que
     hay de verdad, preguntandoselo a racing.lua. ]]
exports('IsHUDActive', function() return EnCarrera() == true end)
exports('GetHUDData', function() return DatosHudCarrera() end)
