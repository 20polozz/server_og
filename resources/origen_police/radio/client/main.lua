CreateThread(function()
    local PlayerData = FW_GetPlayerData(true)
    if PlayerData then
        LoadPlayer(PlayerData)
    end
end)

local haveRadio = false

CreateThread(function()
    while true do
        Wait(4000)
        local count = exports.origen_inventory:Search('count', 'radio')
        
        local detectedRadio = false
        if type(count) == 'number' and count > 0 then
            detectedRadio = true
        end

        if detectedRadio and not haveRadio then
            haveRadio = true
            TriggerEvent("origen_police:client:TakeDropRadio", true)
        end
        if not detectedRadio and haveRadio then
            haveRadio = false
            TriggerEvent("origen_police:client:TakeDropRadio", false)
        end
    end
end)