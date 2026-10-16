Config.Language = 'es' -- Language to use for the script (en, es, fr, it)

Config.CustomNotify = false -- If true, the script will use the custom notify.

Config.CommandName = 'toggleChat' -- Name of the command to toggle the chat.

--[[ Lo que el jugador puede tocar del chat.

     Un grupo en false no sale apagado en el panel: no sale. El color se queda
     apagado a proposito --el color de cada canal es lo que dice de que es cada
     linea, y dejar cambiarlo es dejar que se rompa esa lectura--. ]]
Config.AllowEdit = {
    color = false,      -- El color del chat. APAGADO a proposito, ver arriba.
    position = true,    -- En que esquina se queda.
    size = true,        -- Lo grande que se ve todo.
    opacity = true,     -- Cuanto tapa el fondo de los mensajes.
    messages = true,    -- Cuantos mensajes se ven a la vez.
    channels = true,    -- Que canales se ven: rol, ooc, avisos, sistema.
    timestamps = true,  -- La hora en cada linea.
    sound = true,       -- Si el chat suena.
}

Config.ShowEmojisOption = true -- If true, the chat will show the emojis option.

Config.DefaultColor = '#d81b55f2' -- Default color of the chat.

Config.ShowServerPrints = false -- If true, the script will show server prints.

---------------------------------------------------------
--------------------------DEBUG--------------------------
---------------------------------------------------------

Config.Debug = false -- Enable debug mode