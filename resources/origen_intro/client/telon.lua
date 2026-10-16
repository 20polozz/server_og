Telon = Telon or {}

--[[ ══ El telon ══════════════════════════════════════════════════════════════

     No es el fundido nativo: es la pantalla de carga de Origen -- logotipo,
     "Origen Network", los ocho tramos y "Cargando el servidor" -- que ya vive
     en origen_hud y se pone con sus exports.

     Aqui NO se replica. El lockup esta duplicado a mano entre
     origen_hud/source-ui/src/views/LoadingScreen.vue y
     origen_titlemenu/source-ui/src/components/Transicion.vue porque son dos
     apps de Vue que se compilan por separado y no hay forma de importar de una
     a otra. Una tercera copia seria una tercera cosa que se desincroniza: los
     dos ficheros ya avisan de que eso paso una vez. Llamando al export, esta
     pantalla hereda cualquier cambio que hagan alli.

     Ojo con el fundido nativo: son capas distintas y no se tocan. El telon es
     NUI y va por encima del juego, asi que tapa un fundido nativo que siga
     puesto -- pero al quitarlo aparecería ese negro. Por eso Bajar() limpia el
     nativo detras, ya con la pantalla cubierta. ]]

local puesto = false
local desde = 0

local function Hud(metodo, ms)
    if GetResourceState('origen_hud') ~= 'started' then return false end
    local ok, err = pcall(function() exports['origen_hud'][metodo](exports['origen_hud'], ms) end)
    if not ok then
        print(('^1[origen_intro] No se ha podido mover el telon (%s): %s^0'):format(metodo, tostring(err)))
    end
    return ok
end

--- Baja el telon y no vuelve hasta que cubre del todo.
function Telon.Bajar()
    if puesto then
        -- Ya lo bajo el enganche unos frames antes: se espera lo que le quede
        -- de entrada en vez de seguir de largo con la pantalla a medio cubrir.
        local resto = Config.Telon.entrada - (GetGameTimer() - desde)
        if resto > 0 then Wait(resto) end
        return
    end

    puesto = true
    desde = GetGameTimer()

    local ms = Config.Telon.entrada

    if not Hud('DoScreenFadeOut', ms) then
        -- Sin origen_hud no hay pantalla de carga, pero el jugador no se puede
        -- quedar viendo el teletransporte: el fundido nativo hace de suplente.
        DoScreenFadeOut(ms)
        local hasta = GetGameTimer() + ms + 500
        while not IsScreenFadedOut() and GetGameTimer() < hasta do Wait(0) end
        return
    end

    Wait(ms)

    -- Ya cubiertos: se limpia el negro nativo que traiga la creacion, o
    -- asomaria al levantar el telon.
    DoScreenFadeIn(0)
end

--- Espera a que el telon haya estado el minimo en pantalla. Sin esto, cuando
--- todo va rapido la pantalla de carga es un parpadeo y se lee como un fallo.
function Telon.EsperarMinimo()
    if not puesto then return end
    local minimo = Config.Telon.minimo
    while (GetGameTimer() - desde) < minimo do
        Wait(50)
    end
end

--- Levanta el telon. Aguanta que la llamen de mas.
function Telon.Subir()
    if not puesto then return end
    puesto = false

    local ms = Config.Telon.salida

    if not Hud('DoScreenFadeIn', ms) then
        DoScreenFadeIn(ms)
        Wait(ms)
        return
    end

    Wait(ms)
end

--- Para las salidas de emergencia y el reinicio del resource: sin esperas y
--- levantando tambien el fundido nativo, por si el suplente fue el que actuo.
function Telon.Cortar()
    puesto = false
    Hud('DoScreenFadeIn', 0)
    DoScreenFadeIn(0)
end
