if not GetResourceState('es_extended'):match('start') then return end
Bridge = Bridge or {}
ESX = exports['es_extended']:getSharedObject()

function Bridge.OpenMenu(elements)
    local menu = {}
    local menuTitle = elements[1].header
    elements[1] = nil
    for k,v in pairs(elements) do
        table.insert(menu, {
            label = v.header,
            args = v.value,
            event = v.action
        })
    end
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), "origen_inv", {
        title = menuTitle,
        align = 'bottom-right',
        elements = menu
    }, function(data, menu)
        TriggerEvent(data.current.event, data.current.args)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end