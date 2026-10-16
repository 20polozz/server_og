Config = Config or {}
Custom = Custom or {}
ORIGENVIPS = ORIGENVIPS or {}
ORIGENVIPS.Internal = ORIGENVIPS.Internal or {}
ORIGENVIPS.Classes = ORIGENVIPS.Classes or {}
ORIGENVIPS.Database = ORIGENVIPS.Database or {}
ORIGENVIPS.Managers = ORIGENVIPS.Managers or {}

local isServer = IsDuplicityVersion()
local resourceName = GetCurrentResourceName()

if isServer then
    ORIGENVIPS.Internal.DatabaseReady = false
    ORIGENVIPS.Internal.BootstrapReady = false

    function ORIGENVIPS.Internal:WaitForDatabase()
        while not self.DatabaseReady do
            Wait(100)
        end
    end

    while not MySQL do
        Wait(100)
    end

    MySQL.ready(function()
        if not Inventory then
            print(('^1[%s] NO INVENTORY BRIDGE LOADED — check your inventory resource^0'):format(resourceName))
        end
    end)

end
