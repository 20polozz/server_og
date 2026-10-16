function OverrideProximityRange(distance, bool)
    if Config.VoiceSystem == "pma-voice" then
        if distance ~= nil then
            exports["pma-voice"]:overrideProximityRange(distance, bool)
            return
        end
        exports["pma-voice"]:clearProximityOverride()
    end
end

function ToggleVoice(target, value, string)
    if Config.VoiceSystem == "pma-voice" then
        local numTarget = tonumber(target)
        if numTarget then
            exports["pma-voice"]:toggleVoice(numTarget, value, string or 'radio')
        end
    end
end

function PlayerTargets(radioFreqs, freqName)
    if Config.VoiceSystem == "pma-voice" then
        exports["pma-voice"]:playerTargets(radioFreqs)
    elseif Config.VoiceSystem == "saltychat" then
        exports["saltychat"]:SetRadioChanel(freqName or "", true)
    end
end

function SetRadioVolume(volume)
    if Config.VoiceSystem == "pma-voice" then
        exports["pma-voice"]:setRadioVolume(volume)
    end
end

function GetRadioVolume()
    if Config.VoiceSystem == "pma-voice" and GetResourceState("pma-voice") == "started" then
        local ok, vol = pcall(function()
            return exports["pma-voice"]:getRadioVolume()
        end)
        if ok and vol then
            return math.floor(vol + 0.5)
        end
    end
    return 50
end

function CanTalk()
    local PlayerData = FW_GetPlayerData()
    if PlayerData.metadata["isdead"] or PlayerData.metadata["inlaststand"] or PlayerData.metadata["ishandcuffed"] then
        return false
    end
    return true
end

-- Receptor del boost de volumen para el megáfono policial
-- El servidor nos avisa de que un compañero está usando el megáfono y debemos escucharle más alto
RegisterNetEvent("origen_police:megaphone:boost", function(megaphoneUserId, volume)
    if Config.VoiceSystem ~= "pma-voice" then return end
    -- volume = 2.5 cuando activo, -1.0 para resetear al valor por defecto
    MumbleSetVolumeOverrideByServerId(megaphoneUserId, volume)
end)
