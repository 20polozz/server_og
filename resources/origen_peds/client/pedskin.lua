local function OpenSkinMenu()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local targetModel = GetHashKey("xanudog")

    if model ~= targetModel then
        -- Optional: Add a notification if they don't have the ped
        -- exports['origen_notify']:ShowNotification('No tienes la ped xanudog puesta', 'error')
        return
    end

    local menu = {
        {
            header = "COLORES DE SKIN",
            isMenuHeader = true,
            icon = "fa-solid fa-dog"
        }
    }

    -- Find the max textures for Drawable 0 across all components
    local maxTextures = 0
    for c = 0, 11 do
        local tCount = GetNumberOfPedTextureVariations(ped, c, 0)
        if tCount > maxTextures then
            maxTextures = tCount
        end
    end
    
    for j = 0, maxTextures - 1 do
        table.insert(menu, {
            header = "Color " .. (j + 1),
            txt = "Cambiar a la variación de color " .. j,
            icon = "fa-solid fa-palette",
            params = {
                isAction = true,
                event = function()
                    -- Apply to ALL components to ensure everything changes
                    for c = 0, 11 do
                       if GetNumberOfPedDrawableVariations(ped, c) > 0 then
                           if GetNumberOfPedTextureVariations(ped, c, 0) > j then
                               SetPedComponentVariation(ped, c, 0, j, 0)
                           end
                       end
                    end
                end
            }
        })
    end

    exports['org-menu']:openMenu(menu)
end

RegisterCommand('pedskin', function()
    OpenSkinMenu()
end, false)

-- Opcional: Sugerencia de comando
TriggerEvent('chat:addSuggestion', '/pedskin', 'Cambiar el color de skin de la ped xanudog')
