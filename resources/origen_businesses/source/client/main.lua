Citizen.CreateThread(function()
    if Internal.IsPlayerLoaded() then
        Wait(2500)
        TriggerServerEvent('origen_businesses:server:OnPlayerLoaded')
    end
end)

RegisterNetEvent('origen_businesses:client:notify', function(data)
    Custom.Notify(data)
end)

RegisterNetEvent('origen_businesses:client:loadBusinesses', function()
    Wait(10000)
    local businesses = lib.callback.await('origen_businesses:cb:getBusinesses', false)
    for _, businessData in pairs(businesses) do
        Business.New(businessData)
    end
end)

RegisterNetEvent('origen_businesses:client:reloadBusiness', function(data)
    Business.Reload(data)
end)

RegisterNetEvent('origen_businesses:client:deleteBusiness', function(id)
    local business = Business.Get(id)
    if business then
        business:Delete()
    end
end)

RegisterNetEvent('origen_businesses:client:globalBusinessState', function(data)
    if not data then return end

    local stateText = data.isOpen and 'ABIERTO' or 'CERRADO'
    local colorType = data.isOpen and 'success' or 'inform'
    local notifyTitle = tostring((data.title and data.title ~= '' and data.title) or (data.label or 'Negocio'))
    local notifyDescription = tostring((data.description and data.description ~= '' and data.description) or ('El local ahora esta %s'):format(stateText))

    Custom.Notify({
        title = notifyTitle,
        description = notifyDescription,
        type = colorType
    })
end)

-- Global y no local: la leen `unfocus`, `openBusinessAsAdmin` y
-- `restoreFocus`, que viven en nui.lua. Dice si el panel de admin esta delante.
AdminNegociosAbierto = false

--[[ Quién manda en el sistema de tuneo. Lo pregunta origen_admin, que llevaba
     su propia copia de `Config.TunningSystem`: dos fuentes de verdad que había
     que acordarse de mover a la vez. Aquí porque es este recurso el que abre el
     taller en el juego. ]]
function GetTuningSystem()
    local tuning = Config and Config.Tuning
    local system = type(tuning) == 'table' and tuning.System or nil
    if type(system) ~= 'string' or system == '' then return nil end
    return system
end

exports('GetTuningSystem', GetTuningSystem)

--[[ El panel de admin. Lo abre el hub de origen_admin (Scripts →
     Origen Businesses) y, con Config.Debug, el comando `bu`.

     Antes estaba ademas /testopenadmin, sin permiso, para cualquiera. Quien
     decide lo que se puede hacer sigue siendo el servidor, en cada callback;
     esta pregunta solo evita dar el raton y una pantalla vacia a quien no es
     admin. Si no lo es y venia del hub, se le devuelve alli. ]]
exports('openManagement', function()
    CreateThread(function()
        if not lib.callback.await('origen_businesses:cb:adminPuedes', false) then
            Custom.Notify({
                title = 'Negocios',
                description = 'No tienes permiso para administrar los negocios.',
                type = 'error'
            })
            if GetResourceState('origen_admin') == 'started' then
                pcall(function() exports['origen_admin']:ReturnToScripts() end)
            end
            return
        end

        AdminNegociosAbierto = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'openAdminPanel'
        })
    end)
end)

if Config.Debug then
    RegisterCommand('bu', function()
        exports.origen_businesses:openManagement()
    end, false)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if type(StopBusinessPanelTabletAnim) == 'function' then
        StopBusinessPanelTabletAnim()
    end
    -- Parar el recurso con un panel abierto dejaba el raton preso.
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)

RegisterNetEvent('origen_businesses:client:openTabletMenu', function(businesses)
    if #businesses == 1 then
        local business = Business.Get(businesses[1].id)
        if business then
            business:OpenManagement()
        end
    else
        local menu = {
            {
                header = 'Mis Negocios',
                isMenuHeader = true,
                icon = 'fa-solid fa-tablet-screen-button'
            }
        }
        for i = 1, #businesses do
            local businessId = businesses[i].id
            table.insert(menu, {
                header = businesses[i].label,
                txt = 'Gestión de ' .. businesses[i].label,
                icon = 'fa-solid fa-building',
                params = {
                    handler = function()
                        local business = Business.Get(businessId)
                        if business then
                            business:OpenManagement()
                        end
                    end
                }
            })
        end
        exports['org-menu']:openMenu(menu)
    end
end)