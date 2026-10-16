-- origen_admin | shared permissions handler
--[[
    exports['origen_admin']:HasPermission(permission)
    
    CLIENT:
        permission: string - El permiso a verificar
        Verifica si el jugador local tiene el permiso especificado
        Ejemplo: exports['origen_admin']:HasPermission('AdminMenu:Teleport')
    
    SERVER:
        sourceOrGroup: number|string - Source del jugador o nombre del grupo
        permission: string - El permiso a verificar
        Verifica si el jugador/grupo tiene el permiso especificado
        Ejemplo: exports['origen_admin']:HasPermission(source, 'AdminMenu:Teleport')
        Ejemplo: exports['origen_admin']:HasPermission('admin', 'AdminMenu:Teleport')
]]

local isServer = IsDuplicityVersion()

if isServer then
    lib.callback.register('origen_admin:hasPermission', function(source, permission)
        if not source or source <= 0 or (IsAdminModeDisabled and IsAdminModeDisabled(source)) then
            return false
        end

        -- Directo y no por export, por lo mismo que en HasPermission (abajo).
        local group
        if GetAdmin then
            group = GetAdmin(source)
        else
            group = exports['origen_admin']:GetAdmin(source)
        end

        if not group then group = 'user' end
        if group == 'god' then return true end
        
        local permissions = (cachedGroups and cachedGroups[group] and cachedGroups[group].permissions) or Config.Permissions[group]
        
        if not permissions then return false end
        
        for _, perm in ipairs(permissions) do
            if perm == 'all' or perm == permission then
                return true
            end
        end
        
        return false
    end)

    function HasPermission(sourceOrGroup, permission)
        local group = nil
        local src = tonumber(sourceOrGroup)
        if src then
            if src > 0 and IsAdminModeDisabled and IsAdminModeDisabled(src) then
                return false
            end
            --[[ GetAdmin se llama directo y no por su export.

                 Antes era exports['origen_admin']:GetAdmin(src) desde el propio
                 origen_admin: cada llamada salia del recurso y volvia a entrar,
                 serializando ida y vuelta, cuando la funcion esta en este mismo
                 estado de Lua. HasPermission se llama ~111 veces por segundo
                 (el anticheat pregunta por cada jugador en cada vuelta) y en el
                 perfil del 16/09, con ~300 jugadores, esta funcion sumaba 35 ms
                 de los 81 de ese hilo.

                 El resultado es el mismo: GetAdmin ya guarda por jugador quien
                 es admin y quien no (admins/notAdmins en server/admins.lua) y
                 SetAdmin/ClearAdmin/ForceSetAdmin lo rehacen al cambiar el
                 rango. Si por lo que sea GetAdmin no existe aun (este fichero
                 carga antes que server/), se usa el export como antes. ]]
            if GetAdmin then
                group = GetAdmin(src)
            else
                group = exports['origen_admin']:GetAdmin(src)
            end
        else
            group = sourceOrGroup
        end

        if not group then group = 'user' end
        if group == 'god' then return true end
        
        local permissions = (cachedGroups and cachedGroups[group] and cachedGroups[group].permissions) or Config.Permissions[group]
        
        if not permissions then return false end
        
        for _, perm in ipairs(permissions) do
            if perm == 'all' or perm == permission then
                return true
            end
        end
        
        return false
    end

    exports("HasPermission", HasPermission)

    --[[ ¿Es staff, este o no de servicio? Desde el servicio de staff (06/10)
         HasPermission da false a quien esta fuera de servicio, y el boton de
         Admin del riel del inventario desaparecia: sin el no habia por donde
         abrir el menu rapido para ENTRAR en servicio. Esto mira solo el rango,
         sin el servicio, y sirve para enseñar el boton; los permisos de verdad
         siguen pasando por HasPermission. ]]
    lib.callback.register('origen_admin:esStaff', function(source)
        if not source or source <= 0 then return false end
        local group = GetAdmin and GetAdmin(source) or exports['origen_admin']:GetAdmin(source)
        if not group or group == 'user' then return false end
        return HasPermission(group, 'AdminMenu')
    end)
else
    function HasPermission(permission)
        return lib.callback.await('origen_admin:hasPermission', false, permission)
    end

    exports("HasPermission", HasPermission)

    -- Ver el callback del servidor: rango de staff sin mirar el servicio.
    exports("EsStaff", function()
        return lib.callback.await('origen_admin:esStaff', false) == true
    end)
end
