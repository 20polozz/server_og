RegisterNUICallback('gang:getQuickMenuActions', function(data, cb)
    local actions = {}
    
    for _, actionData in ipairs(Config.QuickMenu.Actions) do
        table.insert(actions, {
            id    = actionData.requiredPermission or actionData.id,
            label = locale:t(actionData.label),
            icon  = actionData.icon
        })
    end

    -- Inject radio permission so it appears in rank editor
    table.insert(actions, {
        id    = 'quick_radio',
        label = locale:t('quickmenu.radio.permission_label'),
        icon  = 'mdi:radio-handheld'
    })
    
    cb(actions)
end)

RegisterNetEvent('origen_gang:client:refreshData', function()
    TriggerServerEvent('origen_gang:server:getGangData')
end)

