local function hideDeadHud()
    SendNUIMessage({
        action = 'hideDeadHud',
    })
end

local function showDeadHud(state, title, text)
    if not state then
        hideDeadHud()
        return
    end

    SendNUIMessage({
        action = 'showDeadHud',
        title = title,
        text = text,
    })
end

local function updateDeadHud(data)
    SendNUIMessage({
        action = 'updateDeadHud',
        data = data,
    })
end

exports('showDeadHud', showDeadHud)
exports('hideDeadHud', hideDeadHud)
exports('updateDeadHud', updateDeadHud)