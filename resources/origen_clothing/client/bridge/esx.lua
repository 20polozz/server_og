if Config.Framework ~= 'esx' then return end

local multicharacterCallbacks = {}

RegisterNetEvent('esx_skin:openSaveableMenu', function(submitCb, cancelCb)
    debugger("esx_skin:openSaveableMenu triggered")
    multicharacterCallbacks.submit = submitCb
    multicharacterCallbacks.cancel = cancelCb
    
    -- Abrir el menú de creación de personaje
    TriggerEvent("origen_clothing:openClothingMenu", "creation")
end)

RegisterNetEvent("skinchanger:loadSkin", function(skin, cb)
    local skin = lib.callback.await("origen_clothing:getAppearance")
    if next(skin) then
        ReloadAppearanceData(false, true)
    end
    if cb then cb() end
end)

function GetMulticharacterCallbacks()
    return multicharacterCallbacks
end

function ClearMulticharacterCallbacks()
    multicharacterCallbacks = {}
end