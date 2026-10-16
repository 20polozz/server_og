RegisterKeyMapping('+radiotalk_radio', 'Radio: hablar', 'keyboard', RadioConfig.DefaultKey)
if not Config.BindSystem then 
    RegisterCommand("r_open_radio", function()
        TriggerEvent("key-5")
    end)

    RegisterKeyMapping('+r_keybind_broadcast', 'Radio: hablar a todas las frecuencias de la categoría', 'keyboard', RadioConfig.DefaultBroadcastKey)

    --[[ La radio ya NO se abre con una tecla.

         La Z esta cogida en el servidor y abrir la radio sin querer al andar
         era constante. La radio se abre desde donde tiene sentido --el item, o
         el menu-- no desde una tecla suelta.

         Se quita el RegisterKeyMapping entero y no solo la tecla por defecto:
         una vez que FiveM ha registrado un atajo, la tecla se le queda guardada
         al jugador en su config local, asi que cambiar el valor de por defecto
         no se la quita a nadie que ya haya entrado. Sin mapping registrado, lo
         que tengan guardado deja de disparar nada.

         El comando `r_open_radio` se queda: sirve para que alguien se la ponga
         a mano si quiere, y para poder llamarla desde otro recurso.
    RegisterKeyMapping('r_open_radio', 'Radio: abrir', 'keyboard', RadioConfig.DefaultOpenRadioKey)
    ]]
end

RegisterCommand("+radiotalk_radio", function()
    StartTalkRadio()
end)

RegisterCommand("-radiotalk_radio", function()
    StopTalkRadio()
end)

local function getPlayerInFrec(frec, playerID)
    local players = {}
    for k, v in pairs(Config.BindFreqs) do
        if v.categoria == frec and k ~= playerID then
            table.insert(players, k)
        end
    end
    return players
end

function BroadCastAllFreqs()
    local playerID = GetPlayerServerId(PlayerId())
    if Config.BindFreqs[playerID] and Config.BindFreqs[playerID].owner then
        local frec = Config.BindFreqs[playerID].categoria
        local players = getPlayerInFrec(frec, playerID)
        StartTalkRadio(players)
    end
end

RegisterCommand("+r_keybind_radio", function(_, args)
    if args[1] and Radio.Binds[args[1]] then
        if Radio.Binds[args[1]] == 'key-3' then
            BroadCastAllFreqs()
        elseif Radio.Binds[args[1]] == 'key-1' then
            StartTalkRadio()
        else
            TriggerEvent(Radio.Binds[args[1]])
        end
    end
end)

RegisterCommand("-r_keybind_radio", function(_, args)
    if not Config.BindSystem then return end
    StopTalkRadio()
end)

if not Config.BindSystem then return end

RegisterCommand("+r_keybind_broadcast", function(_, args)
    BroadCastAllFreqs()
end)

RegisterCommand("-r_keybind_broadcast", function(_, args)
    StopTalkRadio()
end)

RegisterCommand("-r_keybind_broadcast", function(_, args)
    StopTalkRadio()
end)