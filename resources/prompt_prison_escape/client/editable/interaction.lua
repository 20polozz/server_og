local config = require 'config.config_c'
local inUse = false
local interaction
local toiletHash = {joaat('prompt_prison_toilet_withscrew'), joaat('prompt_prison_toilet')}

if config.interaction == 'ox_target' and GetResourceState('ox_target') == 'started' then
    interaction = 'ox_target'
elseif config.interaction == 'qb-target' and GetResourceState('qb-target') == 'started' then
    interaction = 'qb-target'
elseif config.interaction == 'textUI' then
    interaction = 'textUI'
elseif config.interaction == 'custom' then
    interaction = 'custom'
elseif config.interaction == 'auto' then
    if GetResourceState('ox_target') == 'started' then
        interaction = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        interaction = 'qb-target'
    else
        interaction = 'textUI'
    end
else
    lib.print.error('Invalid interaction type in config: ' .. config.interaction)
    return
end

local inventory
if GetResourceState('origen_inventory') == 'started' then
    inventory = 'origen_inventory'
elseif GetResourceState('qb-inventory') == 'started' then
    inventory = 'qb-inventory'
end

function itemCheck()
    if not config.requiredItem or config.requiredItem == '' then
        return true
    end

    if inventory == 'origen_inventory' then
        return exports.origen_inventory:Search('count', config.requiredItem) > 0
    elseif inventory == 'qb-inventory' then
        return exports['qb-inventory']:HasItem(config.requiredItem)
    end

    return true
end

return {
    ---@param onUse function(entity: number)
    setup = function(onUse)
        inUse = true
        if interaction == 'ox_target' then
            exports.ox_target:addModel(toiletHash, {
                {
                    icon = 'fa-solid fa-toilet',
                    label = locale('interaction_label'),
                    onSelect = function(data)
                        onUse(data.entity)
                    end,
                    items = config.requiredItem ~= '' and config.requiredItem or nil,
                },
            })
            lib.print.debug('ox_target interaction set up')
        elseif interaction == 'qb-target' then
            exports['qb-target']:AddTargetModel(toiletHash, {
                options = {
                    {
                        type = 'client',
                        event = 'prompt_prison_escape:startInteraction',
                        icon = 'fa-solid fa-toilet',
                        label = locale('interaction_label'),
                        action = function(entity)
                            onUse(entity)
                        end,
                        item = config.requiredItem ~= '' and config.requiredItem or nil,
                    },
                },
                distance = 2.5,
            })
            lib.print.debug('qb-target interaction set up')
        elseif interaction == 'textUI' then
            local nearbyEntity = nil
            local isShowingUI = false

            CreateThread(function()
                while inUse do
                    if not itemCheck() then
                        if isShowingUI then
                            lib.hideTextUI()
                            isShowingUI = false
                            nearbyEntity = nil
                            lib.print.debug('[Interaction] Hiding textUI, item requirement not met')
                        end
                        Wait(1000)
                        goto continue
                    end
                    local coords = GetEntityCoords(cache.ped)
                    local foundEntity = nil

                    for _, ent in pairs(lib.getNearbyObjects(coords, 2.0)) do
                        if lib.table.contains(toiletHash, GetEntityModel(ent.object)) then
                            foundEntity = ent.object
                            break
                        end
                    end

                    if foundEntity then
                        if not isShowingUI then
                            lib.showTextUI('[E] ' .. locale('interaction_label'))
                            isShowingUI = true
                            lib.print.debug('[Interaction] Showing textUI for entity:', foundEntity)
                        end
                        nearbyEntity = foundEntity
                    else
                        if isShowingUI then
                            lib.hideTextUI()
                            isShowingUI = false
                            nearbyEntity = nil
                            lib.print.debug('[Interaction] Hiding textUI, entity out of range')
                        end
                    end

                    Wait(200)
                    ::continue::
                end

                if isShowingUI then
                    lib.hideTextUI()
                    isShowingUI = false
                end
            end)

            CreateThread(function()
                while inUse do
                    if nearbyEntity and isShowingUI then
                        if IsControlJustPressed(0, 38) then
                            lib.hideTextUI()
                            isShowingUI = false
                            lib.print.debug('[Interaction] E pressed, triggering interaction with entity:', nearbyEntity)
                            onUse(nearbyEntity)
                        end
                        Wait(0)
                    else
                        Wait(100)
                    end
                end
            end)

            lib.print.debug('textUI interaction set up')
        elseif interaction == 'custom' then
            -- Add your custom interaction setup here
        end
    end,

    cleanup = function()
        inUse = false
        if interaction == 'ox_target' then
            exports.ox_target:removeModel(toiletHash)
            lib.print.debug('ox_target interaction cleaned up')
        elseif interaction == 'qb-target' then
            exports['qb-target']:RemoveTargetModel(toiletHash)
            lib.print.debug('qb-target interaction cleaned up')
        elseif interaction == 'textUI' then
            lib.print.debug('textUI interaction cleaned up')
        elseif interaction == 'custom' then
            -- Add your custom interaction cleanup here
        end
    end
}