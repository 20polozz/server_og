local config = {}

-- this is the maximum distance that interacts will render the indicator sprite (little cirlce)
-- recommend keeping this pretty low for optimization
config.maxInteractDistance = 5.0

-- {0-255, 0-255, 0-255, 0-255}; el mismo recurso usa el acento de cada servidor.
if GetConvar('origen:marca', 'origen') == 'nacion' then
    config.themeColor = { 253, 138, 35, 255 }
else
    config.themeColor = { 216, 27, 85, 255 } -- el rosa de la casa (#d81b55)
end

--- texture dictionary and texture name for the sprite used to show non active interactions.
config.IndicatorSprite = { dict = 'shared', txt = 'emptydot_32' }

-- boolean true/false use a keybind to show and hide the interactions
config.useShowKeyBind = false

-- string default key mapping for the show interactions keybind
config.defaultShowKeyBind = 'LMENU'

-- "hold" | "toggle" sets the behavior of the show interactions key bind
config.showKeyBindBehavior = 'toggle'

return config
