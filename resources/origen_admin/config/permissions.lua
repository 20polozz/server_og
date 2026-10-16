-- Permission list
-- "AdminMenu" -> Open the admin menu (HOME)

-- "AdminMenu:OpenUser" -> Open the user profile
-- "AdminMenu:ChangePriority" -> Change the priority queue
-- "AdminMenu:Spectate" -> Spectate a player
-- "AdminMenu:Screenshot" -> Request screenshot of the player
-- "AdminMenu:Bring" -> Bring a player
-- "AdminMenu:GoBack" -> Send a player back to where they were before being brought
-- "AdminMenu:TpTo" -> Tp to a player
-- "AdminMenu:Freeze" -> Freeze a player
-- "AdminMenu:Kill" -> kill a player
-- "AdminMenu:Revive" -> Revive a player
-- "AdminMenu:ChangeBucket" -> Change the bucket of a player
-- "AdminMenu:CleanInv" -> Clean the inventory of a player
-- "AdminMenu:Skin" -> Open the skin menu for a player
-- "AdminMenu:ChangePerms" -> Change the permissions of a player
-- "AdminMenu:AsignJob" -> Asign a job to a player
-- "AdminMenu:AsignGang" -> Asign a gang to a player
-- "AdminMenu:GiveItems" -> Give items to a player
-- "AdminMenu:SeeInv" -> See the inventory of a player
-- "AdminMenu:ManageMoney" -> Manage the money of a player
-- "AdminMenu:GiveProperty" -> Give a property to a player
-- "AdminMenu:GiveVehicle" -> Give a vehicle to a player
-- "AdminMenu:Ban" -> Ban a player
-- "AdminMenu:Unban" -> Unban a player
-- "AdminMenu:Kick" -> Kick a player
-- "AdminMenu:CK" -> CK a player
-- "AdminMenu:AddSanction" -> Add a sanction to a player
-- "AdminMenu:RemoveSanction" -> Remove a sanction from a player

-- "AdminMenu:Noclip" -> Toggle the noclip mode
-- "AdminMenu:SelfRevive" -> Revive yourself
-- "AdminMenu:Godmode" -> Toggle godmode
-- "AdminMenu:Invisible" -> Toggle invisible mode
-- "AdminMenu:SkinSelf" -> Open the skin menu for yourself
-- "AdminMenu:Blips" -> Enable the blips to see the players on the map
-- "AdminMenu:Tags" -> Enable the tags to see the players names
-- "AdminMenu:Tpm" -> Tp to a marker
-- "AdminMenu:CreateAnnounce" -> Create an announce
-- "AdminMenu:ReviveAll" -> Revive all the players
-- "AdminMenu:DeletePeds" -> Delete all the peds of the server
-- "AdminMenu:DeleteObjects" -> Delete all the objects of the server
-- "AdminMenu:DeleteVehicles" -> Delete all the vehicles of the server
-- "AdminMenu:ClearChat" -> Clean the chat for all the players
-- "AdminMenu:FixVehicle" -> Fix the vehicle you are in
-- "AdminMenu:TunningMenu" -> Open the tunning menu for the vehicle you are in
-- "AdminMenu:Refuel" -> Refuel the vehicle you are in
-- "AdminMenu:Unlock" -> Unlock the vehicle you are in
-- "AdminMenu:BoostVeh" -> Boost the vehicle you are in
-- "AdminMenu:Vector3" -> Copy the vector3 of the position you are in
-- "AdminMenu:Vector4" -> Copy the vector4 of the position you are in
-- "AdminMenu:Laser" -> Toggle the laser 

-- "AdminMenu:SeeReports" -> See the report list of the server
-- "AdminMenu:AcceptReports" -> Accept a report
-- "AdminMenu:DeleteReports" -> Delete a report

-- "AdminMenu:SeeOfflinePlayers" -> See the list of offline players
-- "AdminMenu:ChangeUserData" -> Change the name of a player

-- "AdminMenu:Chat" -> See the admin chat and send messages

-- "AdminMenu:SeeBans" -> See the list of bans

-- AdminMenu:ALL -> All the permissions, MAKE SURE TO SET THIS PERMISSION AT THE FIRST POSITION OF THE PERMISSIONS LIST

Config.AvailablePermissions = {
    { id = "all", label = "Todos los permisos" },
    { id = "AdminMenu", label = "Menú Admin" }, -- Funcionando
    { id = "AdminMenu:GestionStaff", label = "Gestionar Staff" }, -- Funcionando
    { id = "AdminMenu:OpenUser", label = "Abrir Usuario" }, -- Funcionando
    { id = "AdminMenu:Spectate", label = "Observar Jugador" }, -- Funcionando
    { id = "AdminMenu:Bring", label = "Traer Jugador" }, -- Funcionando
    { id = "AdminMenu:GoBack", label = "Devolver Jugador" }, -- Funcionando
    { id = "AdminMenu:TpTo", label = "Teletransportarse a Jugador" }, -- Funcionando
    { id = "AdminMenu:Freeze", label = "Congelar Jugador" }, -- Funcionando
    { id = "AdminMenu:Revive", label = "Revivir Jugador" }, -- Funcionando
    { id = "AdminMenu:ChangeBucket", label = "Cambiar Bucket" }, -- Funcionando
    { id = "AdminMenu:Crash", label = "Crash Jugador" }, -- FUNCIONA
    { id = "AdminMenu:ChangePerms", label = "Cambiar Permisos" }, -- Funcionando
    { id = "AdminMenu:GiveItems", label = "Dar Items" }, -- Funciona
    { id = "AdminMenu:SeeInv", label = "Ver Inventario" }, -- Funciona
    { id = "AdminMenu:ManageMoney", label = "Gestionar Dinero" }, -- Funciona
    { id = "AdminMenu:ManageXP", label = "Gestionar EXP" }, -- Funciona
    { id = "AdminMenu:GiveVehicle", label = "Dar Vehículo" }, -- Funciona
    { id = "AdminMenu:Ban", label = "Banear" }, -- Funciona
    { id = "AdminMenu:Unban", label = "Desbanear" }, -- Funciona
    { id = "AdminMenu:Kick", label = "Expulsar" }, -- Funciona
    { id = "AdminMenu:CK", label = "CK" }, -- Funciona
    { id = "AdminMenu:AddSanction", label = "Agregar Sanción" }, -- Funciona
    { id = "AdminMenu:RemoveSanction", label = "Remover Sanción" }, -- Funciona
    { id = "AdminMenu:Noclip", label = "Noclip" }, -- Funciona
    { id = "AdminMenu:SelfRevive", label = "Auto Revivir" }, -- Funciona
    { id = "AdminMenu:Godmode", label = "Modo Dios" }, -- Funciona
    { id = "AdminMenu:Invisible", label = "Invisible" }, -- Funciona
    { id = "AdminMenu:SkinSelf", label = "Cambiar Skin Propio" }, -- Funciona
    { id = "AdminMenu:Blips", label = "Blips" }, -- Funciona
    { id = "AdminMenu:Tags", label = "Tags" }, -- Funciona
    { id = "AdminMenu:Tpm", label = "TPM" }, -- Funciona
    { id = "AdminMenu:CreateAnnounce", label = "Crear Anuncio" }, -- Funciona
    { id = "AdminMenu:ReviveAll", label = "Revivir Todos" }, -- Funciona
    { id = "AdminMenu:DeletePeds", label = "Eliminar Peds" }, -- Funciona
    { id = "AdminMenu:DeleteObjects", label = "Eliminar Objetos" }, -- Funciona
    { id = "AdminMenu:DeleteVehicles", label = "Eliminar Vehículos" }, -- Funciona
    { id = "AdminMenu:ClearChat", label = "Limpiar Chat" }, -- Funciona
    { id = "AdminMenu:FixVehicle", label = "Reparar Vehículo" }, -- Funciona
    { id = "AdminMenu:TunningMenu", label = "Menú Tuning" }, -- Funciona
    { id = "AdminMenu:Refuel", label = "Repostar" }, -- Funciona
    { id = "AdminMenu:Unlock", label = "Desbloquear" }, -- Funciona
    { id = "AdminMenu:BoostVeh", label = "Boost Vehículo" }, -- Funciona
    { id = "AdminMenu:SitVehicle", label = "Entrar a Vehículo" }, -- Funciona
    { id = "AdminMenu:Vector3", label = "Copiar Vector3" }, -- Funciona
    { id = "AdminMenu:Vector4", label = "Copiar Vector4" }, -- Funciona
    { id = "AdminMenu:Laser", label = "Láser" }, -- Funciona
    { id = "AdminMenu:FixUI", label = "Reiniciar UI (Fix Notis)" }, -- Funciona
    { id = "AdminMenu:SeeReports", label = "Ver Reportes" }, -- Funciona
    { id = "AdminMenu:AcceptReports", label = "Aceptar Reportes" }, -- Funciona
    { id = "AdminMenu:DeleteReports", label = "Eliminar Reportes" }, -- Funciona
    { id = "AdminMenu:SeeOfflinePlayers", label = "Ver Jugadores Offline" }, -- Funciona
    { id = "AdminMenu:ChangeUserData", label = "Cambiar Datos de Usuario" }, -- Funciona
    { id = "AdminMenu:Chat", label = "Chat Admin" }, -- Funciona
    { id = "AdminMenu:SeeBans", label = "Ver Baneos" }, -- Funciona
    { id = "AdminMenu:SeeLogs", label = "Ver Logs" }, -- Funciona
    { id = "Comando:car", label = "Comando: car" }, -- Funciona
    { id = "Comando:dv", label = "Comando: dv" }, -- Funciona
    { id = "Comando:tp", label = "Comando: tp" }, -- Funciona
    { id = "Comando:tpm", label = "Comando: tpm" }, -- Funciona
    { id = "Comando:setjob", label = "Comando: setjob" }, -- Funciona
    { id = "Comando:setjob_police", label = "Comando: setjob (Policía y Tablet)" },
    { id = "Comando:logout", label = "Comando: logout" }, -- Funciona
    { id = "Comando:revive", label = "Comando: revive" }, -- Funciona
    { id = "Comando:kill", label = "Comando: kill" }, -- Funciona
    { id = "Comando:aheal", label = "Comando: aheal" }, -- Funciona
    { id = "Comando:darkit", label = "Comando: darkit" }, -- FUNCIONA
    { id = "Comando:skin", label = "Comando: skin" }, -- FUNCIONA
    { id = "Comando:darped", label = "Comando: darped (Entregar Peds)" }, -- FUNCIONA
    { id = "AdminMenu:ManageQueue", label = "Gestionar Cola" }, -- Funciona
    { id = "AdminMenu:ChangePriority", label = "Cambiar Prioridad" }, -- Funciona
    { id = "AdminMenu:ManageGroups", label = "Gestionar Grupos" }, -- Funciona
    { id = "AdminMenu:Settings", label = "Ajustes del Panel" }, -- Funciona
    { id = "AdminMenu:Devoluciones", label = "Gestionar Devoluciones" },
    { id = "AdminMenu:Ban", label = "Banear Jugador" }, -- Funciona
    { id = "AdminMenu:Kick", label = "Expulsar Jugador" }, -- Funciona
    { id = "AdminMenu:KickAll", label = "Expulsar a Todos (Kickall)" }, -- Funciona
    { id = "AdminMenu:Unban", label = "Desbanear Jugador" }, -- Funciona
    { id = "origen_hub", label = "Acceso al Hub" }, -- Funciona
    { id = "origen_housing", label = "Gestionar Housing" }, -- Funciona
    { id = "origen_quests", label = "Gestionar Quests" }, -- Funciona
    { id = "origen_dealership", label = "Gestionar Concesionarios" }, -- Funciona
    { id = "origen_clothing", label = "Gestionar Clothing" }, -- Funciona
    { id = "origen_doorlock", label = "Gestionar Doorlock" }, -- Funciona
    { id = "origen_geohunt", label = "Gestionar GeoHunt" },
    { id = "origen_fuel", label = "Gestionar Fuel" }, -- Funciona
    { id = "origen_ilegal", label = "Gestionar Ilegal" }, -- Funciona
    { id = "origen_police", label = "Gestionar Police" }, -- Funciona
    { id = "origen_comservice", label = "Gestionar Servicio Comunitario" },
    { id = "origen_businesses", label = "Gestionar Negocios" }, -- Funciona
    { id = "origen_garages", label = "Gestionar Garajes" }, -- Funciona
    { id = "origen_inventory", label = "Gestionar Inventario" }, -- Funciona
    { id = "origen_robberies", label = "Gestionar Robos" }, -- Funciona
    { id = "origen_banking", label = "Gestionar Banco" }, -- Funciona
    { id = "origen_blackmarket", label = "Gestionar Mercado Negro" }, -- Funciona
    { id = "origen_carboosting", label = "Gestionar Car Boosting" }, -- Funciona
    { id = "origen_racing", label = "Gestionar Racing Hub" }, -- Funciona
    { id = "origen_gangwars", label = "Gestionar Gang Wars" }, -- Funciona
    { id = "origen_zones", label = "Gestionar Zonas" }, -- Funciona
    { id = "origen_gym", label = "Gestionar Gimnasios" }, -- NUEVO
    { id = "origen_mision", label = "Gestionar Encargos" }, -- NUEVO
    { id = "origen_tattoos", label = "Gestionar Tatuajes" }, -- NUEVO
    { id = "origen_vehiclehandling", label = "Gestionar el manejo de vehículos" }, -- Funciona
    { id = "origen_vehiclesounds",   label = "Gestionar Sonidos de Motor" }, -- Funciona
    { id = "origen_vehicleseats",    label = "Gestionar Asientos" }, -- NUEVO
    { id = "qbx_smallresources", label = "Gestionar Teleports" }, -- Funciona
    { id = "origen_graffiti", label = "Gestionar Graffitis" }, -- NUEVO
    { id = "origen_propplacer", label = "Gestionar Propplacer" }, -- NUEVO
    { id = "origen_pets", label = "Gestionar Mascotas" }, -- NUEVO
    { id = "origen_hunting", label = "Gestionar Caza" }, -- NUEVO
    { id = "origen_customs", label = "Gestionar Taller de Tuning" }, -- NUEVO
    { id = "origen_autoescuela", label = "Gestionar Autoescuela" }, -- NUEVO
    { id = "origen_casino", label = "Gestionar Casino" }, -- NUEVO
    { id = "origen_bingo", label = "Gestionar Bingo" }, -- NUEVO
    { id = "origen_vipsystem", label = "Gestionar VIP" }, -- NUEVO
    { id = "AdminMenu:Weather", label = "Clima (Abrir Pestaña)" },
    { id = "AdminMenu:SetTime", label = "Clima (Cambiar Hora)" },
    { id = "AdminMenu:SetWeather", label = "Clima (Cambiar Clima)" },
    { id = "AdminMenu:FreezeTime", label = "Clima (Congelar Hora)" },
    { id = "AdminMenu:FreezeWeather", label = "Clima (Congelar Clima)" },
    { id = "AdminMenu:SetBlackout", label = "Clima (Apagón)" },
    { id = "Comando:setammo", label = "Comando: setammo" },
    { id = "Comando:infammo", label = "Comando: infammo" },
    { id = "Comando:admincustom", label = "Comando: admincustom (Taller)" },
    { id = "Comando:adminproveedor", label = "Comando: adminproveedor (Precios del proveedor de piezas)" },
    { id = "Comando:ganchooffset", label = "Comando: ganchooffset (Medir el gancho del remolque de barcos)" },
    { id = "Comando:screenshot", label = "Comando: screenshot y stopscreenshot (Fotos de las prendas)" },
    { id = "Comando:esposar", label = "Comando: esposar (Admin)" },
    { id = "Comando:desesposar", label = "Comando: desesposar (Admin)" },
    { id = "Comando:addxp", label = "Comando: addxp" },
    { id = "Comando:removexp", label = "Comando: removexp" },
    { id = "Comando:gastarxp", label = "Comando: gastarxp" },
    { id = "Comando:refundxp", label = "Comando: refundxp" },
    { id = "Comando:getxp", label = "Comando: getxp" },
    { id = "Comando:fishingstats", label = "Comando: fishingstats" },
    { id = "origen_uploader", label = "Gestionar Uploader" },
    { id = "Comando:maxdriving", label = "Comando: maxdriving (Conducción al 100%)" },
    { id = "Comando:openinv", label = "Comando: openinv (Abrir Inventarios)" },
    { id = "Comando:stats", label = "Comando: stats" },
    { id = "AdminMenu:SeeStats", label = "Estadísticas (Ver Pestaña)" },
    { id = "Comando:godveh", label = "Comando: godveh (Invencibilidad Vehículo)" },
    { id = "Comando:arnes", label = "Comando: arnes (Arnés Administrativo)" },
    { id = "Comando:givekeys", label = "Comando: givekeys (Darse Llaves)" },
    { id = "Comando:givecar",  label = "Comando: givecar (Traspasar Vehículo)" },
    { id = "Comando:ocultar",  label = "Comando: /ocultar (Anonimato Chat)" },

    { id = "Comando:TransferGarage", label = "Transferir Vehículo al Garage" },
    { id = "Comando:GiveHouseKey",   label = "Comando: givehousekey (Dar llave de casa)" },
    { id = "Comando:RemoveHouseKey", label = "Comando: removehousekey (Quitar llave de casa)" },
    { id = "Comando:PhoneVerified",  label = "Comando: phoneverified (Verificar cuenta lb-phone)" },
    { id = "Comando:PhonePassword",  label = "Comando: phonepassword (Cambiar contraseña lb-phone)" },
    { id = "Comando:fixcar", label = "Comando: /fixcar (Reparar Vehículo)" },
    { id = "Comando:tpmp", label = "Comando: /tpmp (TP a Marcador de Mapa)" },
    { id = "Comando:bolsa", label = "Comando: /bolsa (Bolsa en la cabeza)" },
    { id = "casino", label = "Gestionar Casino" },
    { id = "origen_games", label = "Gestionar Origen Games (zonas y puntos)" },
    { id = "origen_livery", label = "Editor de liveries (/livery)" },
    { id = "origen_render", label = "Editor del mapa e interiores (/render)" },
    { id = "fivem_conflicttool", label = "Conflictos de mapas (/conflicttool)" },
    -- ===== ANTICHEAT =====
    { id = "AdminMenu:Anticheat",  label = "Anticheat (Ver Pestaña)" },
    { id = "Anticheat:Exempt",    label = "Anticheat: Exención (Sin checks)" },

    -- ===== ACCIONES SOBRE MIEMBROS DEL STAFF =====
    { id = "AdminMenu:Staff:All",          label = "Staff: Afectar a Todo el Staff (Acceso Total)" },
    { id = "AdminMenu:Staff:Spectate",     label = "Staff: Observar / Espectear a Staff" },
    { id = "AdminMenu:Staff:Bring",        label = "Staff: Traer a Staff (/bring)" },
    { id = "AdminMenu:Staff:Goto",         label = "Staff: Teletransporte a Staff (/goto)" },
    { id = "AdminMenu:Staff:SeeInv",       label = "Staff: Ver / Abrir Inventario a Staff" },
    { id = "AdminMenu:Staff:ClearInv",     label = "Staff: Vaciar Inventario a Staff" },
    { id = "AdminMenu:Staff:Screen",       label = "Staff: Ver Pantalla en Vivo a Staff" },
    { id = "AdminMenu:Staff:Screenshot",   label = "Staff: Captura de Pantalla a Staff" },
    { id = "AdminMenu:Staff:Revive",       label = "Staff: Revivir a Staff" },
    { id = "AdminMenu:Staff:Freeze",       label = "Staff: Congelar a Staff" },
    { id = "AdminMenu:Staff:Kill",         label = "Staff: Matar a Staff" },
    { id = "AdminMenu:Staff:Kick",         label = "Staff: Expulsar a Staff (/kick)" },
    { id = "AdminMenu:Staff:Ban",          label = "Staff: Banear a Staff (/ban)" },
    { id = "AdminMenu:Staff:Warn",         label = "Staff: Sancionar / Warn a Staff" },
    { id = "AdminMenu:Staff:GiveItems",    label = "Staff: Dar / Quitar Items a Staff" },
    { id = "AdminMenu:Staff:ManageMoney",  label = "Staff: Dar / Quitar Dinero a Staff" },
    { id = "AdminMenu:Staff:GiveVehicle",  label = "Staff: Dar Vehículos a Staff" },
    { id = "AdminMenu:Staff:GiveProperty", label = "Staff: Asignar Casas a Staff" },
    { id = "AdminMenu:Staff:ChangeBucket", label = "Staff: Cambiar Dimensión a Staff" },
    { id = "AdminMenu:Staff:Skin",         label = "Staff: Forzar Menú Skin a Staff" },
    { id = "AdminMenu:Staff:SetJob",       label = "Staff: Cambiar Trabajo / Banda a Staff" },
    { id = "AdminMenu:Staff:ManageXP",     label = "Staff: Modificar XP a Staff" },
    { id = "AdminMenu:Staff:CK",           label = "Staff: CK / Wipe a Staff" },
    { id = "AdminMenu:Staff:ChangePerms",  label = "Staff: Cambiar Permisos a Staff" },
    { id = "AdminMenu:Staff:Crash",        label = "Staff: Crashear a Staff" },
}

if GetConvar('origen:marca', 'origen') == 'nacion' then
    for i = #Config.AvailablePermissions, 1, -1 do
        local id = Config.AvailablePermissions[i].id
        -- origen_pets SI esta en Nacion desde el 13/10 (es el sistema de mascotas de los dos).
        if id == 'origen_mision' then table.remove(Config.AvailablePermissions, i) end
    end
end

Config.Permissions = {
    -- Los permisos se gestionan desde el panel de admin con grupos personalizados (BD: origen_admin_groups)
    -- Si necesitas un grupo por defecto, descomenta:
    -- ["god"] = { "all" }
}

Config.UserPermission = "user" -- Group of user without permissions

-- DON'T TOUCH ABOVE THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
Config.HighPermissions = {}

local groupsWithPermissions = {}
for group, permissions in pairs(Config.Permissions) do
    if table.concat(permissions, ","):find("all") then
        table.insert(groupsWithPermissions, { group = group, count = math.huge })
    else
        local count = #permissions
        table.insert(groupsWithPermissions, { group = group, count = count })
    end
end
table.sort(groupsWithPermissions, function(a, b)
    return a.count > b.count
end)
Config.HighPermissions = {}
for _, groupInfo in ipairs(groupsWithPermissions) do
    table.insert(Config.HighPermissions, groupInfo.group)
end

-- Fallback: si Config.HighPermissions está vacío, usar Config.PermissionList
if #Config.HighPermissions == 0 and Config.PermissionList then
    for _, group in ipairs(Config.PermissionList) do
        table.insert(Config.HighPermissions, group)
    end
end
