if GetConvar('origen:marca', 'origen') ~= 'nacion' then return end

local MASK_COMPONENT = 1
local LOGIN_SETTLE_MS = 1500

local function waitForAppearance(timeout)
    local resource = Config.Peds.appearanceResource
    local deadline = GetGameTimer() + (timeout or Config.Peds.reloadTimeout)

    while GetResourceState(resource) ~= 'started' do
        if GetGameTimer() >= deadline then return false end
        Wait(100)
    end

    return true
end

local function waitForModel(model, timeout)
    local hash = joaat(model)
    local deadline = GetGameTimer() + timeout

    while GetEntityModel(PlayerPedId()) ~= hash do
        if GetGameTimer() >= deadline then return false end
        Wait(100)
    end

    return true
end

--- El flip en base de datos ya ocurrio antes de llegar aca, asi que un fallo silencioso
--- deja al jugador viendo un modelo distinto del que quedo guardado: se avisa para que
--- sepa que tiene que reconectar.
local function warnOutOfSync()
    TriggerEvent('ox_lib:notify', {
        description = Config.Textos.desincronizado,
        type = 'error',
        duration = 6000,
    })
end

--- Un ped que no es freemode puede quedar invisible despues de SetPlayerModel hasta que
--- cambia alguna variacion, y con packs de ropa pesados pasa siempre. Es el mismo truco
--- que usa origen_clothing en ReloadAppearanceData cuando recibe overrideModel.
local function forceVisible(ped)
    if GetNumberOfPedDrawableVariations(ped, MASK_COMPONENT) <= 1 then return end

    local drawable = GetPedDrawableVariation(ped, MASK_COMPONENT)
    local texture = GetPedTextureVariation(ped, MASK_COMPONENT)

    SetPedComponentVariation(ped, MASK_COMPONENT, drawable == 0 and 1 or 0, 0, 0)
    Wait(0)
    SetPedComponentVariation(ped, MASK_COMPONENT, drawable, texture, 0)
end

RegisterNetEvent('origen_peds:client:refreshAppearance', function(model)
    CreateThread(function()
        if type(model) ~= 'string' or not waitForAppearance() then
            warnOutOfSync()
            return
        end

        local ok, err = pcall(function()
            exports[Config.Peds.appearanceResource]:ReloadAppearanceData()
        end)

        if not ok then
            print(('[origen_peds] ReloadAppearanceData fallo: %s'):format(tostring(err)))
            warnOutOfSync()
            return
        end

        if not waitForModel(model, Config.Peds.reloadTimeout) then
            warnOutOfSync()
            return
        end

        if not Config.BaseModels[model] then
            forceVisible(PlayerPedId())
        end
    end)
end)

--- origen_clothing aplica la skin activa en este mismo evento, pero sin el truco de
--- visibilidad: se espera a que termine de poner el ped para aplicarlo encima.
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local model = lib.callback.await('origen_peds:getEquippedPed', false)
    if not model then return end

    if not waitForModel(model, Config.Peds.reloadTimeout) then return end

    Wait(LOGIN_SETTLE_MS)

    if GetEntityModel(PlayerPedId()) == joaat(model) then
        forceVisible(PlayerPedId())
    end
end)
