local MODEL_NAME = 'cuervo_ballasc'
local MODEL_HASH = joaat(MODEL_NAME)

local function loadModel(timeoutMs)
    local inCdImage = IsModelInCdimage(MODEL_HASH)
    local valid = IsModelValid(MODEL_HASH)
    print(('[PEDS53_TEXTURE_FIXED] modelo=%s hash=%s cdimage=%s valid=%s'):format(
        MODEL_NAME,
        MODEL_HASH,
        tostring(inCdImage),
        tostring(valid)
    ))

    if not inCdImage or not valid then
        return false
    end

    RequestModel(MODEL_HASH)
    local deadline = GetGameTimer() + timeoutMs
    while not HasModelLoaded(MODEL_HASH) and GetGameTimer() < deadline do
        Wait(0)
    end

    return HasModelLoaded(MODEL_HASH)
end

local function printComponentCounts(ped)
    for _, componentId in ipairs({ 0, 3, 4 }) do
        local drawables = GetNumberOfPedDrawableVariations(ped, componentId)
        print(('[PEDS53_TEXTURE_FIXED] componente=%s drawables=%s'):format(componentId, drawables))
    end
end

RegisterCommand('ped_ballasc', function()
    if not loadModel(10000) then
        print('[PEDS53_TEXTURE_FIXED] ERROR: el modelo no se pudo cargar.')
        return
    end

    SetPlayerModel(PlayerId(), MODEL_HASH)
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SetModelAsNoLongerNeeded(MODEL_HASH)
    printComponentCounts(ped)
    print('[PEDS53_TEXTURE_FIXED] PED aplicada correctamente.')
end, false)

RegisterCommand('test_ballasc', function()
    if not loadModel(10000) then
        print('[PEDS53_TEXTURE_FIXED] ERROR: el modelo no se pudo cargar.')
        return
    end

    local playerPed = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 1.5, 1.5, 0.0)
    local ped = CreatePed(4, MODEL_HASH, coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, false)
    SetPedDefaultComponentVariation(ped)
    SetModelAsNoLongerNeeded(MODEL_HASH)
    printComponentCounts(ped)
    print(('[PEDS53_TEXTURE_FIXED] NPC creado: handle=%s existe=%s'):format(
        ped,
        tostring(DoesEntityExist(ped))
    ))
end, false)

RegisterCommand('diagnostico_ballasc', function()
    local ped = PlayerPedId()
    print(('[PEDS53_TEXTURE_FIXED] jugador=%s modelo_actual=%s esperado=%s'):format(
        ped,
        GetEntityModel(ped),
        MODEL_HASH
    ))
    printComponentCounts(ped)
end, false)
