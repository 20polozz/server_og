--[[ ── El teórico en pantalla ──────────────────────────────────────────────────

     La página enseña las preguntas que mandó el servidor (sin la respuesta) y
     al terminar —o al cerrar, o al acabarse el tiempo— entrega lo marcado.
     La nota la pone el servidor. ]]

RegisterNUICallback('entregar', function(d, cb)
    if not A.teorico then return cb({ ok = false }) end
    local r = lib.callback.await('origen_autoescuela:teorico:entregar', false, d and d.respuestas or {})
    A.teorico = false
    cb(r or { ok = false })
end)

-- La nota y la vuelta al menú se quedan en la misma columna del riel: no
-- hace falta nada más por aquí.
