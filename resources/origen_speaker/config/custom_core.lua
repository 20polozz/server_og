return {
    useCustomCore = false, -- If true, the script will use the custom core
    events = {
        load = 'custom:playerLoaded', -- Change this to your custom event
        unload = 'custom:playerLogout', -- Change this to your custom event
    },

    GetCustomCoreObject = function()
        return nil -- Return your core object here
    end,
}
