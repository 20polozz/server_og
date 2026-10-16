---@param boolean Hide or show visuals
Custom.HideVisuals = function(state)
    exports.origen_hud:toggleHud(not state)

    --[[ Fin de una creacion. Si origen_intro tiene una intro armada, que baje
         el telon YA: entre este punto y 'creationComplete' hay un
         SaveAppearance con ida y vuelta al servidor, y ese rato el jugador
         estaria mirando el estudio de creacion con la camara suelta. ]]
    if not state and GetResourceState('origen_intro') == 'started' then
        pcall(function() exports.origen_intro:telon() end)
    end
end