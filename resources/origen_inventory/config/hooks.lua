local Thread = CreateThread
local IS_SERVER = IsDuplicityVersion()

if not IS_SERVER then
    Thread(function()
        Wait(1000)

        exports.origen_inventory:registerHook('worldpoint-interact-in', function(payload)
            -- Payload structure:
            -- type: string
            -- id: string
            -- location: vector3
            -- label: string
        end)

        exports.origen_inventory:registerHook('worldpoint-interact-out', function(payload)
            -- Payload structure:
            -- type: string
            -- id: string
            -- location: vector3
            -- label: string
        end)
    end)
end



if not IS_SERVER then return end



-- This is a example of how to use hooks in the inventory system.
-- You can register hooks to listen to certain events happening in the inventory,
-- and modify the payload or cancel the action altogether.

--- This thread is just for testing purposes, you must use hooks on another resources of preference.
Thread(function()
    Wait(1000) -- Wait for inventory to be ready

    exports.origen_inventory:registerHook('createItem', function(payload)
        -- print(json.encode(payload, { indent = true })) -- Un comment to see the payload data

        local metadata = payload.metadata
        local item = payload.item

        if item.name == 'cartera' and not metadata.bagId then
            local rndId = math.random(100000, 999999) 
            metadata.bagId = rndId
        elseif item.name == 'paperbag' and not metadata.bagId then
            local rndId = math.random(1000, 9999) -- Maybe a better unique id generation method is needed (this random method is just for testing)
            metadata.bagId = rndId
        end

        return metadata -- Make sure you return the metadata table
    end)

    exports.origen_inventory:registerHook('swapItems', function(payload)
        local toInventory = payload.toInventory and tostring(payload.toInventory)
        
        -- Si están metiendo algo a la cartera
        if toInventory and toInventory:match('^cartera%-') then
            local item = payload.fromSlot
            if item and item.name then
                local allowedItems = {
                    ['id_card'] = true,
                    ['driver_license'] = true,
                    ['vehicle_papers'] = true,
                    ['licencia_card'] = true,
                    ['seguro_medico'] = true,
                    ['certificado'] = true,
                    ['licenciacaza_card'] = true,
                    ['licenciapesca_card'] = true,
                    ['licenciaarma_card'] = true,
                    ['licencia_piloto'] = true,
                    ['licencia_conducir'] = true,
                    -- Los de los negocios (origen_businesses): tarjetas, carnés y papeles.
                    ['tarjeta_negocio'] = true,
                    ['documento_negocio'] = true,
                    ['cash'] = true,
                }
                
                -- Si el ítem no está en la lista de permitidos, bloquea el movimiento
                if not allowedItems[item.name] then
                    return false
                end
            end
        end
        return true
    end)
end)
