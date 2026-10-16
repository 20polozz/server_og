--[[ La misma página es pantalla de carga y ui_page, así que sigue cargada toda
     la partida. Si se recarga a mitad (reinicio del recurso, caída del CEF),
     arrancaría la música en bucle y nadie la pararía: un jugador en la granja
     se encontró con la música de la carga sonando sin fin.
     La página pregunta antes de sonar; si ya estamos jugando, calla. ]]

RegisterNUICallback('enPartida', function(_, cb)
    cb({ jugando = not GetIsLoadingScreenActive() and NetworkIsPlayerActive(PlayerId()) })
end)
