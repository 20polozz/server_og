if not GetResourceState('qb-core'):match('start') then return end
Bridge = Bridge or {}

---@param elements table
---@example 
--[[
    {
        {header = 'Menu', isMenuHeader = true},
        {header = 'Option 1', txt = 'Description 1', action = 'action', value = 'value'},
        {header = 'Option 2', txt = 'Description 2', action = 'action', value = 'value'},
        {header = 'Option 3', txt = 'Description 3', action = 'action', value = 'value'},
    }
]]
function Bridge.OpenMenu(elements)
    local menu = {}
    for _, v in ipairs(elements) do
        menu[_] = {}
        menu[_].header = v.header
        if  v.isMenuHeader then menu[_].isMenuHeader = true end
        if v.txt then menu[_].txt = v.txt end
        if v.icon then menu[_].icon = v.icon end
        if v.action then 
            menu[_].params = {}
            if v.action then menu[_].params.event = v.action end
            if v.isServer then menu[_].params.isServer = v.isServer end
            if v.value then menu[_].params.args = v.value end
        end
    end
    exports['org-menu']:openMenu(menu)
end 