local bvsActiveConsumableToken = nil

RegisterNetEvent('origen_businesses:client:consumeCraftedItem', function(data)
    if type(data) ~= 'table' or type(data.token) ~= 'string' or bvsActiveConsumableToken then return end

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
        TriggerServerEvent('origen_businesses:server:finishCraftedConsumption', data.token, false)
        return
    end

    bvsActiveConsumableToken = data.token

    if GetResourceState('origen_inventory') == 'started' then
        pcall(function() exports.origen_inventory:CloseInventory() end)
    end

    local isFood = data.kind == 'food'
    local settings = Config.BusinessConsumables or {}
    local itemSettings = type(settings.Items) == 'table' and settings.Items[data.itemName] or {}
    local animation = type(itemSettings.Animation) == 'table' and itemSettings.Animation or {}
    local propModel = tostring(data.propModel or '')
    local propHash = propModel ~= '' and joaat(propModel) or 0
    -- ox_lib admite el modelo si cualquiera de las dos comprobaciones lo reconoce.
    -- Algunos props transmitidos por recursos externos no aparecen en cdimage,
    -- pero sí son modelos válidos; descartarlos aquí los reemplazaba por el genérico.
    if propModel == '' or (not IsModelInCdimage(propHash) and not IsModelValid(propHash)) then
        propModel = isFood and 'prop_cs_burger_01' or 'prop_ld_flow_bottle'
    end

    local completed = lib.progressBar({
        duration = math.max(1000, math.min(10000, math.floor(tonumber(data.duration) or 2500))),
        label = isFood and ('Comiendo %s'):format(data.label or 'producto') or ('Bebiendo %s'):format(data.label or 'producto'),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            combat = true,
        },
        anim = {
            dict = tostring(animation.dict or (isFood and 'mp_player_inteat@burger' or 'mp_player_intdrink')),
            clip = tostring(animation.clip or (isFood and 'mp_player_int_eat_burger' or 'loop_bottle')),
            flag = math.floor(tonumber(animation.flag) or 49),
        },
        prop = {
            model = propModel,
            bone = 18905,
            pos = isFood and vec3(0.13, 0.05, 0.02) or vec3(0.12, 0.008, 0.03),
            rot = isFood and vec3(-50.0, 16.0, 60.0) or vec3(240.0, -60.0, 0.0),
        },
    })

    local token = bvsActiveConsumableToken
    bvsActiveConsumableToken = nil
    TriggerServerEvent('origen_businesses:server:finishCraftedConsumption', token, completed == true)
end)

RegisterNetEvent('origen_businesses:client:applyCraftedStatus', function(kind, amount)
    amount = math.max(0, math.min(100, tonumber(amount) or 0))
    if amount <= 0 then return end

    if kind == 'food' then
        TriggerEvent('esx_status:add', 'hunger', amount * 10000)
    elseif kind == 'drink' then
        TriggerEvent('esx_status:add', 'thirst', amount * 10000)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or not bvsActiveConsumableToken then return end
    if lib and lib.cancelProgress then lib.cancelProgress() end
    bvsActiveConsumableToken = nil
end)
