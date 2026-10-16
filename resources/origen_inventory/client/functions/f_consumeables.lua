--[[
    Origen Inventory - Consumables System
    Refactored for better organization and maintainability
]]

-- ===============================================
-- CONFIGURATION & CONSTANTS
-- ===============================================

local CONSUMABLE_TYPES = {
    EAT = 'eat',
    DRINK = 'drink',
    ALCOHOL = 'alcohol'
}

local PROGRESS_BAR_NAMES = {
    EAT = 'consume_eat',
    DRINK = 'consume_drink',
    ALCOHOL = 'consume_alcohol'
}

local DEFAULT_CONFIG = {
    props = {
        [CONSUMABLE_TYPES.EAT] = {
            model = 'prop_cs_burger_01',
            bone = 18905,
            coords = vec3(0.13, 0.05, 0.02),
            rotation = vec3(-50.0, 16.0, 60.0)
        },
        [CONSUMABLE_TYPES.DRINK] = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = vec3(0.12, 0.008, 0.03),
            rotation = vec3(240.0, -60.0, 0)
        },
        [CONSUMABLE_TYPES.ALCOHOL] = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = vec3(0.12, 0.008, 0.03),
            rotation = vec3(240.0, -60.0, 0)
        }
    },
    animations = {
        [CONSUMABLE_TYPES.EAT] = {
            animDict = "mp_player_inteat@burger",
            anim = "mp_player_int_eat_burger",
            flag = 49
        },
        [CONSUMABLE_TYPES.DRINK] = {
            animDict = "mp_player_intdrink",
            anim = "loop_bottle",
            flag = 49
        },
        [CONSUMABLE_TYPES.ALCOHOL] = {
            animDict = "mp_player_intdrink",
            anim = "loop_bottle",
            flag = 49
        }
    }
}

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

---Create control configuration for progress bar
---@param move boolean Disable movement
---@param car boolean Disable car movement
---@param mouse boolean Disable mouse
---@param combat boolean Disable combat
---@return table
function CreateControlConfig(move, car, mouse, combat)
    return {
        disableMovement = move,
        disableCarMovement = car,
        disableMouse = mouse,
        disableCombat = combat
    }
end

-- Early return if consumables are disabled
if not Config.UseInventoryComsumables then return end

---Fix animation format for different progress bar systems
---@param anim table Animation configuration
---@return table Formatted animation
local function formatAnimationForProgressBar(anim)
    local animation = {
        animDict = anim.animDict or anim.dict,
        anim = anim.anim or anim.clip,
        flags = anim.flags or anim.flag or 49
    }
    
    -- Compatibility with ox_lib
    if Config.Progressbar == 'ox_lib' then
        animation.dict = animation.animDict
        animation.clip = animation.anim
    end
    
    return animation
end

---Generate progress bar props configuration
---@param item string Item name
---@param consumableType string Type of consumable (eat/drink/alcohol)
---@return table Props configuration
local function generatePropsConfig(item, consumableType)
    local defaultProps = DEFAULT_CONFIG.props[consumableType]
    local itemProps = ConsumablesProps[item] or {}
    
    local props = {
        model = itemProps.model or defaultProps.model,
        bone = itemProps.bone or defaultProps.bone,
        coords = itemProps.pos or defaultProps.coords,
        rotation = itemProps.rot or defaultProps.rotation
    }
    
    -- Compatibility with ox_lib
    if Config.Progressbar == 'ox_lib' then
        props.pos = props.coords
        props.rot = props.rotation
    end
    
    return props
end

---Generate animation configuration for item
---@param item string Item name
---@param consumableType string Type of consumable
---@return table Animation configuration
local function generateAnimationConfig(item, consumableType)
    local defaultAnim = DEFAULT_CONFIG.animations[consumableType]
    local itemAnim = ConsumablesProps[item] or {}
    
    local animation = {
        animDict = itemAnim.animDict or defaultAnim.animDict,
        anim = itemAnim.anim or defaultAnim.anim,
        flags = itemAnim.flag or defaultAnim.flag
    }
    
    return formatAnimationForProgressBar(animation)
end

-- ===============================================
-- CONSUMABLE HANDLERS
-- ===============================================

local drunkDuration = 0
local isDrunk = false

local function ApplyDrunkEffect(duration)
    drunkDuration = drunkDuration + duration
    if isDrunk then return end
    isDrunk = true
    
    CreateThread(function()
        local playerPed = PlayerPedId()
        
        RequestAnimSet("MOVE_M@DRUNK@SLIGHTLYDRUNK")
        while not HasAnimSetLoaded("MOVE_M@DRUNK@SLIGHTLYDRUNK") do
            Wait(10)
        end
        
        SetPedMovementClipset(playerPed, "MOVE_M@DRUNK@SLIGHTLYDRUNK", true)
        SetTimecycleModifier("spectator5")
        SetPedMotionBlur(playerPed, true)
        SetPedIsDrunk(playerPed, true)
        ShakeGameplayCam("DRUNK_SHAKE", 1.5)
        
        while drunkDuration > 0 do
            Wait(1000)
            drunkDuration = drunkDuration - 1
        end
        
        isDrunk = false
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        ResetPedMovementClipset(playerPed, 0)
        SetPedIsDrunk(playerPed, false)
        SetPedMotionBlur(playerPed, false)
        StopGameplayCamShaking(true)
    end)
end


---Generic consumable handler
---@param item string Item name
---@param consumableType string Type of consumable
---@param statusType string Status to modify (hunger/thirst/alcohol)
---@param configTable table Configuration table for the consumable type
---@param timeout number|nil Custom timeout (uses item config if not provided)
---@param uses number|nil Number of uses (for food items)
local function handleConsumable(item, consumableType, statusType, configTable, timeout, uses)
    if not item then 
        debugger('^1[CONSUMABLES ERROR]^7 No item provided')
        return 
    end
    
    local itemLabel = Items(item)?.label or item
    local localeKey = consumableType == CONSUMABLE_TYPES.EAT and 'notify.Eating' or 'notify.Drinking'
    local duration = timeout
    local controls = CreateControlConfig(false, false, false, true)
    local animation = generateAnimationConfig(item, consumableType)
    local props = generatePropsConfig(item, consumableType)
    local progressBarName = PROGRESS_BAR_NAMES[consumableType:upper()] or 'consume_generic'
    
    Bridge.ProgressBar(
        progressBarName,
        locale:t(localeKey, itemLabel),
        duration,
        controls,
        animation,
        props,
        function(success)
            if success then
                -- Handle item removal for food with uses system
                if consumableType == CONSUMABLE_TYPES.EAT and uses == 0 then
                    InventoryUI.Notify('remove', Items(item).name)
                elseif consumableType ~= CONSUMABLE_TYPES.EAT then
                    InventoryUI.Notify('remove', Items(item).name)
                end
                
                -- Add status effect
                local statusValue = configTable[item]
                if statusValue then
                    Bridge.AddStatus(statusType, statusValue)
                    if statusType == 'alcohol' then
                        ApplyDrunkEffect(statusValue)
                    end
                end
                
                -- Special handling for alcohol
                if consumableType == CONSUMABLE_TYPES.ALCOHOL then
                    return true
                end
            else
                Bridge.Notify(locale:t('notify.Cancel'))
                if consumableType == CONSUMABLE_TYPES.ALCOHOL then
                    return false
                end
            end
        end
    )
end

local function handleRegularConsumable(itemInfo)
    if not itemInfo or not itemInfo.name then
        debugger('^1[CONSUMABLES ERROR]^7 Invalid item information provided')
        return false
    end

    local client = itemInfo.client
    local itemLabel = itemInfo.label
    local localeNotification = 'Consumiendo...'
    local duration = client and client.usetime or 2500
    
    if duration < 100 then
        duration = duration * 1000
    end
    
    local controls = CreateControlConfig(false, false, false, true)
    -- local animation = client.anim and formatAnimationForProgressBar({
    --     dict = client.anim.dict,
    --     clip = client.anim.clip,
    --     flags = client.anim.flags
    -- }) or false
    local animation = false

    if not animation then
        if client.status and (client.status.hunger or client.status.thirst) then

            if client.status.hunger and client.status.hunger > 0 then
                ---@diagnostic disable-next-line: cast-local-type
                animation = formatAnimationForProgressBar({
                    dict = "mp_player_inteat@burger",
                    clip = "mp_player_int_eat_burger",
                    flags = 49
                })
            elseif client.status.thirst and client.status.thirst > 0 then
                ---@diagnostic disable-next-line: cast-local-type
                animation = formatAnimationForProgressBar({
                    dict = "mp_player_intdrink",
                    clip = "loop_bottle",
                    flags = 49
                })
            end
        end
    end

    local props = client.prop or false
    
    if not props and client.status and (client.status.hunger or client.status.thirst) then
        if client.status.hunger and client.status.hunger > 0 then
            ---@diagnostic disable-next-line: cast-local-type
            props = {
                model = 'prop_cs_burger_01',
                bone = 18905,
                coords = vec3(0.13, 0.05, 0.02),
                rotation = vec3(-50.0, 16.0, 60.0)
            }
        elseif client.status.thirst and client.status.thirst > 0 then
            ---@diagnostic disable-next-line: cast-local-type
            props = {
                model = 'prop_ld_flow_bottle',
                bone = 18905,
                coords = vec3(0.12, 0.008, 0.03),
                rotation = vec3(240.0, -60.0, 0)
            }
        end
        
        if Config.Progressbar == 'ox_lib' then
            ---@diagnostic disable-next-line: need-check-nil
            props.pos = props.coords
            ---@diagnostic disable-next-line: need-check-nil
            props.rot = props.rotation
        end
    end
    local progressBarName = 'consume_generic'
    
    Bridge.ProgressBar(
        progressBarName,
        locale:t(localeNotification, itemLabel),
        duration,
        controls,
        animation,
        props,
        function(success)
            if success then
                if client.status then
                    for status, value in pairs(client.status) do
                        if value > 0 then
                            Bridge.AddStatus(status, value)
                            if status == 'alcohol' then
                                ApplyDrunkEffect(value)
                            end
                        end
                    end
                end
                
                --- Terminado: el servidor ya no tiene que guardarlo por si acaso.
                TriggerServerEvent('origen_inventory:consumables:server:Terminado')

                return true
            else
                --[[ Cortado a medias: que devuelva lo que ya se habia gastado.

                     El objeto se quita antes de la animacion para que no se
                     pueda usar dos veces a la vez, asi que al cortarse se
                     quedaba gastado sin llenar el hambre ni la sed. ]]
                TriggerServerEvent('origen_inventory:consumables:server:Cancelado')

                Bridge.Notify(locale:t('notify.Cancel'))
                return false
            end
        end
    )

    return true
end

-- ===============================================
-- PUBLIC CONSUMABLE FUNCTIONS
-- ===============================================

---Handle eating items
---@param item string Item name
---@param _ any Unused parameter for compatibility
---@param timeout number|nil Custom timeout (uses item config if not provided)
---@param uses number|nil Number of uses remaining
function Eat(item, _, timeout, uses)
    return handleConsumable(item, CONSUMABLE_TYPES.EAT, 'hunger', Config.ConsumablesEat, timeout, uses)
end

---Handle drinking items
---@param item string Item name
---@param _ any Unused parameter for compatibility
---@param timeout number|nil Custom timeout (uses item config if not provided)
function Drink(item, _, timeout, uses)
    return handleConsumable(item, CONSUMABLE_TYPES.DRINK, 'thirst', Config.ConsumablesDrink, timeout, uses)
end

---Handle alcohol consumption
---@param item string Item name
---@param _ any Unused parameter for compatibility
---@param timeout number|nil Custom timeout (uses item config if not provided)
function DrinkAlcohol(item, _, timeout, uses)
    return handleConsumable(item, CONSUMABLE_TYPES.ALCOHOL, 'alcohol', Config.ConsumablesAlcohol, timeout, uses)
end

function ConsumeRegular(itemInfo)
    return handleRegularConsumable(itemInfo)
end

-- ===============================================
-- EXPORTS & EVENT HANDLERS
-- ===============================================

-- Export functions for external use
exports('Eat', Eat)
exports('Drink', Drink)
exports('DrinkAlcohol', DrinkAlcohol)

-- Register network events
RegisterNetEvent('origen_inventory:consumables:client:Eat', Eat)
RegisterNetEvent('origen_inventory:consumables:client:Drink', Drink)
RegisterNetEvent('origen_inventory:consumables:client:DrinkAlcohol', DrinkAlcohol)
RegisterNetEvent('origenInv:consumables:consumeItem', ConsumeRegular)

-- ===============================================
-- BACKWARD COMPATIBILITY
-- ===============================================

-- Legacy function exports for compatibility
exports('controls', CreateControlConfig)
exports('progress_animation_fix', formatAnimationForProgressBar)