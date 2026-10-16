--[[
    ============================================================
    UI SETTINGS
    ============================================================
    Controls how the gang menu is opened, closed, and how the
    territory map is displayed in the UI.
    ============================================================
--]]

Config.UI = {
    --[[ Sin tecla. Y ojo, que esta clave no la lee nadie: la que manda de
         verdad es Config.QuickMenu.Key, en config/interactions.lua, que ya
         esta a nil. Esta se quedo aqui con un 'F7' escrito y despistaba, que
         es peor que no estar. El menu de banda se abre desde el riel del
         inventario. ]]
    OpenKey = nil,

    -- Use a chat command to open the menu instead of a key
    UseCommand = false,
    CommandName = 'gangorg',

    -- Close the UI when ESC is pressed
    CloseOnEsc = true,

    -- Territory map display settings
    TerritoryMap = {
        Enable = true,

        -- true: show all territories on the map
        -- false: show only neutral and your own territories
        ShowAllTerritories = false,
    },
}
