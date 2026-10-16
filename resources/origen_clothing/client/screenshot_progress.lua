local screenshotStartTime = 0
local screenshotInProgress = false

RegisterNetEvent('origen_clothing_screenshot:progressStart', function(data)
    screenshotStartTime = GetGameTimer()
    screenshotInProgress = true
    SendNUIMessage({
        action = 'screenshotProgressStart',
        data = {
            total = data.total,
            current = 0
        }
    })
end)

local COMPONENT_NAMES = {
    [1] = 'Máscaras',
    [3] = 'Torsos',
    [4] = 'Pantalones',
    [5] = 'Mochilas',
    [6] = 'Calzado',
    [7] = 'Cuello',
    [8] = 'Camisetas',
    [9] = 'Chalecos',
    [10] = 'Calcomanías',
    [11] = 'Chaquetas',
    [1000] = 'Sombreros',
    [1001] = 'Gafas',
    [1002] = 'Pendientes',
    [1006] = 'Relojes',
    [1007] = 'Pulseras'
}

RegisterNetEvent('origen_clothing_screenshot:progressUpdate', function(data)
    if not screenshotInProgress then return end
    
    local elapsed = (GetGameTimer() - screenshotStartTime) / 1000
    local timePerPhoto = data.current > 0 and (elapsed / data.current) or 0
    local remaining = (data.total - data.current) * timePerPhoto
    
    local collection = data.collection
    if collection == 'none' or collection == '' then
        collection = 'Colección base'
    end
    
    local componentName = COMPONENT_NAMES[data.component] or 'Desconocido'
    
    SendNUIMessage({
        action = 'screenshotProgressUpdate',
        data = {
            current = data.current,
            total = data.total,
            percentage = math.floor((data.current / data.total) * 100),
            elapsed = math.floor(elapsed),
            estimated = math.floor(remaining),
            collection = collection,
            component = data.component,
            componentName = componentName
        }
    })
end)

RegisterNetEvent('origen_clothing_screenshot:progressEnd', function(data)
    screenshotInProgress = false
    SendNUIMessage({
        action = 'screenshotProgressEnd',
        data = {
            cancelled = data.cancelled
        }
    })
end)

