--[[
    LOS PERMISOS DEL NEGOCIO — FUENTE DE VERDAD

    Este archivo es la ÚNICA copia del mapa de equivalencias de permisos. Antes
    vivía triplicado: cliente, servidor y la NUI. Un permiso nuevo había que
    escribirlo tres veces y las tres copias ya habían divergido entre sí
    (`manage_inventory` admitía `management` en la NUI y no en Lua, y al revés
    con `inventory`).

    La copia de TypeScript de `ui/source/src/store/index.ts` no puede leer Lua:
    sigue existiendo, pero es un ESPEJO de este archivo. Al tocar aquí hay que
    tocar allí y volver a compilar la NUI.

    Donde las dos copias viejas discrepaban se ha tomado la unión: el servidor
    es quien decide y quedarse corto escondía botones que sí habrían
    funcionado.
]]

BusinessPermissions = BusinessPermissions or {}

--- Cada permiso y los permisos antiguos que también lo conceden.
BusinessPermissions.Aliases = {
    view_employees        = { 'view_employees', 'manage_employees', 'management', 'hire', 'fire', 'hire_employees', 'fire_employees' },
    hire_employees        = { 'hire_employees', 'manage_employees', 'hire', 'management' },
    fire_employees        = { 'fire_employees', 'manage_employees', 'fire', 'management' },
    manage_grades         = { 'manage_grades', 'manage_employees', 'management' },
    --[[ Sacar a otro de servicio. Antes el panel lo pedia como
         `manage_employees`, que NO es una clave de este mapa --solo un alias
         de otras--, asi que no lo tenia nadie: el boton salia apagado hasta
         para el jefe. Ahora es un permiso de verdad, que se puede dar por su
         nombre, y ademas lo conceden `manage_grades` y `management` para que
         el jefe y quien ya llevaba los rangos lo tengan sin tocar nada. ]]
    manage_duty           = { 'manage_duty', 'manage_grades', 'manage_employees', 'management' },
    --[[ Mirar las cámaras de seguridad del local (source/server/camaras.lua).
         Colocarlas es `manage_settings`, como cualquier otro punto. ]]
    view_cameras          = { 'view_cameras', 'management' },
    --[[ Hacer documentos: contratos, recibos, tarjetas, carnés
         (source/server/documentos.lua). ]]
    make_documents        = { 'make_documents', 'management' },
    --[[ Mandar en la central de avisos (source/server/central.lua): quitarle un
         aviso a otro, rechazarlo y decidir qué servicios ofrece el local.

         VER y COGER avisos NO está aquí a propósito: para eso basta con estar
         fichado. Si hiciera falta un permiso, el empleado recién contratado no
         podría atender a nadie hasta que el jefe se acordara de dárselo, y lo
         que se pierde mientras tanto es un cliente esperando una grúa. ]]
    manage_dispatch       = { 'manage_dispatch', 'manage_orders', 'orders', 'management' },
    --[[ Colgar carteles en el local y alquilar vallas de la ciudad
         (source/server/carteles.lua). Quien ya llevaba los anuncios también. ]]
    manage_signs          = { 'manage_signs', 'manage_announcements', 'management' },
    view_finances         = { 'view_finances', 'manage_balance', 'deposit_money', 'withdraw_money', 'deposit', 'withdraw', 'management' },
    manage_balance        = { 'manage_balance', 'deposit_money', 'withdraw_money', 'deposit', 'withdraw', 'management' },
    deposit_money         = { 'deposit_money', 'manage_balance', 'deposit', 'management' },
    withdraw_money        = { 'withdraw_money', 'manage_balance', 'withdraw', 'management' },
    manage_inventory      = { 'manage_inventory', 'inventory', 'management' },
    manage_prices         = { 'manage_prices', 'prices', 'management' },
    manage_orders         = { 'manage_orders', 'orders', 'management' },
    manage_invoices       = { 'manage_invoices', 'view_finances', 'manage_balance', 'management' },
    buy_vehicles          = { 'buy_vehicles', 'manage_settings', 'management' },
    use_vehicles          = { 'use_vehicles', 'buy_vehicles', 'management' },
    delete_vehicles       = { 'delete_vehicles', 'manage_settings', 'management' },
    toggle_business       = { 'toggle_business', 'management', 'manage_settings' },
    manage_settings       = { 'manage_settings', 'management' },
    manage_announcements  = { 'manage_announcements', 'management' },
    --[[ `use_wardrobe` no lo mira todavía ningún sitio, pero el panel admin ya
         lo deja marcar en un rango desde siempre. Está aquí para que no lo
         rechace la validación de puntos. ]]
    use_wardrobe          = { 'use_wardrobe', 'management' },
    repair_vehicles       = { 'repair_vehicles', 'management' },
    manage_work_orders    = { 'manage_work_orders', 'manage_orders', 'orders', 'management' },
    manage_service_prices = { 'manage_service_prices', 'manage_prices', 'prices', 'management' },
    manage_parts_stock    = { 'manage_parts_stock', 'manage_inventory', 'inventory', 'management' }
}

--- El rótulo de cada permiso, en el orden en que se enseñan en los paneles.
BusinessPermissions.Labels = {
    { key = 'view_employees',        label = 'Ver empleados' },
    { key = 'hire_employees',        label = 'Contratar empleados' },
    { key = 'fire_employees',        label = 'Despedir empleados' },
    { key = 'manage_grades',         label = 'Gestionar rangos' },
    { key = 'manage_duty',           label = 'Sacar de servicio' },
    { key = 'view_cameras',          label = 'Ver cámaras' },
    { key = 'make_documents',        label = 'Hacer documentos' },
    { key = 'manage_dispatch',       label = 'Mandar en la central' },
    { key = 'manage_signs',          label = 'Carteles y publicidad' },
    { key = 'view_finances',         label = 'Ver finanzas' },
    { key = 'manage_balance',        label = 'Gestionar la caja' },
    { key = 'deposit_money',         label = 'Depositar dinero' },
    { key = 'withdraw_money',        label = 'Retirar dinero' },
    { key = 'manage_inventory',      label = 'Gestionar inventario' },
    { key = 'manage_prices',         label = 'Cambiar precios' },
    { key = 'manage_orders',         label = 'Hacer pedidos' },
    { key = 'manage_invoices',       label = 'Emitir facturas' },
    { key = 'buy_vehicles',          label = 'Comprar vehículos de empresa' },
    { key = 'use_vehicles',          label = 'Sacar y guardar vehículos de empresa' },
    { key = 'delete_vehicles',       label = 'Borrar vehículos de empresa' },
    { key = 'toggle_business',       label = 'Abrir y cerrar el negocio' },
    { key = 'manage_settings',       label = 'Configuración avanzada' },
    { key = 'manage_announcements',  label = 'Gestionar anuncios' },
    { key = 'use_wardrobe',          label = 'Usar el ropero' },
    { key = 'repair_vehicles',       label = 'Reparar vehículos' },
    { key = 'manage_work_orders',    label = 'Gestionar órdenes de trabajo' },
    { key = 'manage_service_prices', label = 'Editar tarifas del taller' },
    { key = 'manage_parts_stock',    label = 'Gestionar stock de piezas' }
}

--[[ Todo nombre de permiso que el sistema reconoce, los actuales y los
     antiguos. Para validar lo que llega de fuera: un permiso inventado deja el
     punto o el rango inservible sin decir por qué. ]]
BusinessPermissions.Valid = {}

for key, aliases in pairs(BusinessPermissions.Aliases) do
    BusinessPermissions.Valid[key] = true
    for i = 1, #aliases do
        BusinessPermissions.Valid[aliases[i]] = true
    end
end

--- Todos los permisos que valen para conceder `permission`.
function BusinessPermissions.Candidates(permission)
    local candidates = { permission }
    local aliases = BusinessPermissions.Aliases[permission]
    if aliases then
        for i = 1, #aliases do
            candidates[#candidates + 1] = aliases[i]
        end
    end
    return candidates
end
