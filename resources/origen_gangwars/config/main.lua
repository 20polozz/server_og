Config.Language = 'es' -- Language to use for the script

Config.BlacklistURLs = {
    'google',
    'imgur',
    'discord',
}

Config.AllowedExtensions = {
    'png',
    'jpg'
}

-- Configuración de sistemas custom
Config.CustomInventory = false -- No usar custom, usa origen_inventory
Config.CustomNotify = true -- Usar custom notify (origen_notify)
Config.CustomAmbulance = false
Config.CustomGangSystem = false

---------------------------------------------------------
--------------------------DEBUG--------------------------
---------------------------------------------------------

Config.Debug = false -- Enable debug mode

Config.DatabaseStructureCheck = true -- Check the database structure on start

---------------------------------------------------------
--------------------------ADMIN--------------------------
---------------------------------------------------------

-- Función para verificar si un jugador es admin
Config.IsAdmin = function(source)
    -- Verificar ACE permissions (consola del servidor)
    if IsPlayerAceAllowed(source, 'command') then
        return true
    end
    
    -- Usar sistema de origen_admin (PREFERIDO)
    if GetResourceState('origen_admin') == 'started' then
        local hasOrigenAdmin, isAdmin = pcall(function()
            return exports['origen_admin']:CheckAdmin(source)
        end)
        
        if hasOrigenAdmin and isAdmin then
            return true
        end
    end
    
    return false
end