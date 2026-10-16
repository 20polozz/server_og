function ClearInv(source)
    if  Config.Inventory == "qs-inventory" or 
        Config.Inventory == "origen_inventory" or 
        Config.Inventory == "codem-inventory" or 
        Config.Inventory == "ox_inventory" or
        Config.Inventory == "qb-inventory" then 
        ExecuteCommand("clearinv "..source)
    else
        -- ls-inventory: Can't find function or command to clear items in docs
        print("Inventory system not supported for this action")
    end
end

function SeeInv(source)
    if Config.Inventory == "origen_inventory" then
        ExecuteCommand("seeinv "..source)
    elseif Config.Inventory == "qs-inventory" then 
        ExecuteCommand("openinventorytarget "..source)
    elseif Config.Inventory == "codem-inventory" then
        ExecuteCommand("openinventoryplayer "..source)
    elseif Config.Inventory == "ox_inventory" then
        ExecuteCommand("viewinv "..source)
    else
        -- If there's no inventory support for client side, go to server to check if there's any implementation there
        TriggerServerEvent("origen_admin:server:open_otherinv", source)
    end
end