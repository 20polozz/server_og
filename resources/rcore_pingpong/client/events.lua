-- this function is called when the local game is started
function GameStarted(coords)
    if RefreshControls then RefreshControls() end
end

-- this function is called when the local game is ended
function GameEnded(coords)
    if HideControls then HideControls() end
end

