---@diagnostic disable: duplicate-set-field
if GetResourceState('origen_clothing') == 'missing' then return end

Clothing = Clothing or {}

---Opens the outfit menu via origen_clothing's export.
---'openOutfitMenu' calls Outfit.OpenMenu() which opens the 'outfit' type (saved outfits),
---NOT 'clothing' type (the full character creator).
function Clothing.OpenMenu()
    local ok, err = pcall(function()
        exports['origen_clothing']:openOutfitMenu()
    end)
    if not ok then
        warn('[origen_ilegalv2] clothing bridge: openOutfitMenu failed — ' .. tostring(err))
    end
end

---This will get the name of the in use resource.
---@return string
Clothing.GetResourceName = function()
    return 'origen_clothing'
end
