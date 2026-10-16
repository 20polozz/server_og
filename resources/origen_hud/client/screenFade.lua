local function DoScreenFadeOut(time)
    SetNuiZindex(99999)
    SendNUIMessage({
        action = 'DoScreenFadeOut',
        time = time or 1000,
    })
end

local function DoScreenFadeIn(time)
    SendNUIMessage({
        action = 'DoScreenFadeIn',
        time = time or 1000,
    })
    CreateThread(function()
        Wait(time or 1000)
        SetNuiZindex(0)
    end)
end

exports('DoScreenFadeOut', DoScreenFadeOut) -- exports.origen_hud:DoScreenFadeOut()
exports('DoScreenFadeIn', DoScreenFadeIn) -- exports.origen_hud:DoScreenFadeIn()

-- Los comandos /fadeout y /fadein de prueba se quitaron (07/10): ponian el
-- telon negro a pantalla completa y podia usarlos cualquiera.