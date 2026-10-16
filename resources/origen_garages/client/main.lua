-- Export para furniture
local function toggleFurnitureMenu(state)
    if state == nil then
        state = false
    end
    if Furniture then
        Furniture:ToggleMenu(state)
    else
        debugger('Furniture object not available')
    end
end
exports('toggleFurnitureMenu', toggleFurnitureMenu)