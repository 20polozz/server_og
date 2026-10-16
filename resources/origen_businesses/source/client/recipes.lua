local endpoints = {
    getRecipeManager = 'origen_businesses:server:getRecipeManager',
    addRecipeItem = 'origen_businesses:server:addRecipeItem',
    removeRecipeItem = 'origen_businesses:server:removeRecipeItem',
    createRecipe = 'origen_businesses:server:createRecipe',
    deleteRecipe = 'origen_businesses:server:deleteRecipe',
    setRecipeMenuItem = 'origen_businesses:server:setRecipeMenuItem',
}

for endpoint, callbackName in pairs(endpoints) do
    RegisterNUICallback(endpoint, function(data, cb)
        cb(lib.callback.await(callbackName, false, data or {}))
    end)
end

RegisterNUICallback('craftRecipe', function(data, cb)
    data = data or {}
    if data.pointType ~= 'kitchen' then
        cb(lib.callback.await('origen_businesses:server:craftRecipe', false, data))
        return
    end

    -- El minijuego lee las teclas desde Lua, así que se libera el foco mientras
    -- se juega y se devuelve al panel cuando termina la cocción.
    SetNuiFocus(false, false)
    local ok, result = pcall(Cocina.CocinarReceta, data)
    SetNuiFocus(true, true)
    if not ok then
        print(('[origen_businesses] Error al cocinar receta nueva: %s'):format(result))
        cb({ ok = false, error = 'No se pudo terminar de cocinar.' })
        return
    end
    cb(result)
end)

RegisterNetEvent('origen_businesses:client:recipesChanged', function(businessId)
    SendNUIMessage({ action = 'recipesChanged', data = { businessId = tostring(businessId or '') } })
end)
