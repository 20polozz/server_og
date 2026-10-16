local function ShowProgress(duration, label)
    SendNUIMessage({
        action = 'showProgress',
        duration = duration,
        label = label
    })
end

exports('ShowProgress', ShowProgress)

local function HideProgress()
    SendNUIMessage({
        action = 'cancelProgress'
    })
end

exports('HideProgress', HideProgress)

RegisterNuiCallback('finishProgress', function(data, cb)
    exports.origen_inventory:FinishProgress()

    cb('ok')
end)