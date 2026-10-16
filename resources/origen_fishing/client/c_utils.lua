Utils = {}

--[[ El aviso grande de la actividad («Actividad iniciada»). Antes lo pintaba
     la NUI de este recurso con su propio cartel; ahora va por origen_notify,
     como el resto de avisos del servidor. `state` dice si es bueno o malo. ]]
Utils.DisplaySplashText = function(state, title, text, waitTime, playSound)
    if playSound ~= nil and playSound == true then
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    end

    exports.origen_notify:Notify({
        title = title,
        description = text,
        type = state == false and 'error' or 'success',
        duration = math.floor((tonumber(waitTime) or 5) * 1000)
    })
end

Utils.SecondsToClock = function(seconds)
    local seconds = tonumber(math.abs(math.floor(seconds)))

    if seconds <= 0 then
        return "00:00";
    else
        local mins = string.format("%02.f", math.floor(seconds/60));
        local secs = string.format("%02.f", math.floor(seconds - mins *60));
        return mins..":"..secs
    end
end

Utils.ShowNotification = function(message, notifyType, time)
    lib.notify({
        title = 'Pesca',
        description = message,
        type = notifyType or 'inform',
        duration = time or 5000
    })
end