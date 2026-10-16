HotBar = {}

if Config.UI.Hotbar then
    local hbOpen = true
    local hbKey = Config.HotbarOpenKey or 'TAB'
    RegisterCommand('origen_hotbar', function() 
        hbOpen = not hbOpen
        HotBar.Toggle(hbOpen)
    end, false)
    RegisterKeyMapping('origen_hotbar', 'Inventario: ver los accesos rápidos', 'keyboard', hbKey)
end


HotBar.Toggle = function(visible)
    if Inventory.locked then return end
    if not Config.UI.Hotbar then return end
    SendNUIMessage({
        action = 'toggle_hotbar',
        data = visible
    })
end
exports('ToggleHotBar', HotBar.Toggle)