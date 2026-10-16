Config.Language = 'es'

Config.Drawtext = 'qb-core' -- Draw text library

Config.Debug = false -- Enable debug mode

Config.GroupPermissions = { --? Groups that can use the commands
    'god',
    'admin',
    'superadmin',
}

Config.Commands = 'doors' --? Command to open the menu

Config.Input = 'org-input' -- Input system: 'ox_lib' or 'qb-input'

-- SECURITY: Webhook URLs moved to config/server/logs.lua (server-only)
Config.Logs = Config.Logs or {}

---------------------------------------------------------
--------------------------CORE---------------------------
---------------------------------------------------------
Config.GetCustomCoreObject = function()
    return nil -- Return your core object here
end

---------------------------------------------------------
-------------------------GANZUA--------------------------
---------------------------------------------------------
--[[ Forzar puertas con ganzua.

     Se ganzua una puerta que tenga marcado «Ganzuado» en el panel (/doors).
     El item lo gestiona qbx_consumables (lockpick / advancedlockpick) y avisa
     con el evento local 'lockpicks:UseLockpick'; lo escucha server/ganzua.lua,
     que busca la puerta, lanza el minijuego de origen_minijuegos y, al acabar,
     vuelve a comprobarlo todo antes de abrir (distancia, item, puerta, ritmo). ]]
Config.Ganzua = {
    activo = true,

    -- Item de cada tipo de ganzua y dificultad del minijuego (easy, medium, hard, extreme)
    normal   = { item = 'lockpick',         dificultad = 'medium' },
    avanzada = { item = 'advancedlockpick', dificultad = 'easy' },

    -- Pines de cada dificultad (los de origen_minijuegos/config.lua). Cada pin
    -- dura al menos medio segundo de animacion, asi que un resultado antes de
    -- pines x segundosPorPin no lo ha jugado nadie.
    pines = { easy = 3, medium = 4, hard = 5, extreme = 6 },
    segundosPorPin = 0.4,

    margenDistancia  = 1.0, -- metros de mas sobre la distancia de la puerta
    tiempoMaximo     = 60,  -- segundos para acabar el minijuego
    esperaEntreIntentos = 5, -- segundos entre un intento y el siguiente

    fallosMaximos    = 3,   -- fallos seguidos en la misma puerta...
    bloqueoTrasFallos = 120, -- ...y segundos sin poder volver a intentarlo

    -- % de que la ganzua se rompa al fallar
    probRomper = { normal = 25, avanzada = 10 },

    --[[ Puertas de servicio. Aunque alguien marque «Ganzuado», una puerta que
         pertenezca a un trabajo de estos tipos (comisaria, hospital...) no se
         fuerza. Los tipos salen de qbx_core/shared/jobs.lua. ]]
    protegerPuertasDeServicio = true,
    tiposProtegidos  = { leo = true, ems = true },
    gruposProtegidos = { police = true, sheriff = true, sapd = true, fib = true, saspa = true, ambulance = true },
}
