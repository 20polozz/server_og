Bridge = Bridge or {}
Bridge.Menu = Bridge.Menu or {}

local menuType = Config.Menu or 'auto'

if menuType == 'auto' then
    if GetResourceState('org-menu') == 'started' then menuType = 'org-menu'
    elseif GetResourceState('qb-menu') == 'started' then menuType = 'qb-menu'
    elseif GetResourceState('ox_lib') == 'started' then menuType = 'ox_lib'
    else menuType = 'qb-menu' end
end

local function QBToOxMenu(menu)
    local oxMenu = {
        id = 'origen_AlbumCards_menu',
        title = "Menú",
        options = {},
    }
    for i, v in ipairs(menu) do
        if v.isMenuHeader then
            oxMenu.title = v.header
        else
            local option = {
                title = v.header,
                description = v.txt,
                icon = v.icon,
                onSelect = function()
                    if v.params then
                        if v.params.isServer then
                            TriggerServerEvent(v.params.event, v.params.args)
                        else
                            TriggerEvent(v.params.event, v.params.args)
                        end
                    end
                end
            }
            table.insert(oxMenu.options, option)
        end
    end
    return oxMenu
end

function origenalbumcards_OpenMenu(data)
    if menuType == 'org-menu' then
        exports['org-menu']:openMenu(data)
    elseif menuType == 'qb-menu' then
        exports['qb-menu']:openMenu(data)
    elseif menuType == 'ox_lib' then
        local oxData = QBToOxMenu(data)
        if lib then
            lib.registerContext(oxData)
            lib.showContext(oxData.id)
        else
            exports.ox_lib:registerContext(oxData)
            exports.ox_lib:showContext(oxData.id)
        end
    end
end

Bridge.Menu.Open = origenalbumcards_OpenMenu
