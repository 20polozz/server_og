Internal.OpenClothingMenu = function(uniqueId, locationData)
    if Clothing and type(Clothing.OpenMenu) == 'function' then
        Clothing.OpenMenu()
    else
        warn('[origen_ilegalv2] No clothing bridge loaded — cannot open outfit menu.')
    end
end