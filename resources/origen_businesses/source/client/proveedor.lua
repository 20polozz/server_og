--[[
    EL PROVEEDOR DE PIEZAS, DEL LADO DEL CLIENTE

    Abre el panel de admin a pantalla completa que fija el coste al por mayor de las piezas del
    taller. Se edita aqui y no en el panel del negocio a proposito: el coste al
    por mayor lo pone la administracion, no el jefe del taller, que si no se
    compraria las piezas a 1 y las facturaria al cliente a precio de catalogo.

    El reparto de abrir y cerrar es el mismo del panel de negocio, y no es
    intercambiable: el foco se suelta ANTES de animar y la NUI confirma que ha
    llegado a pintarse. Ver custom/client/panel_negocio.lua.
]]

local abierto = false
local nuiPintada = false

--[[ Cada apertura es una generacion. El desmontaje de la columna se manda 280
     ms despues de cerrar, y sin esto una apertura que llegue dentro de esos
     280 ms se comeria el desmontaje de la anterior: el panel recien abierto
     desapareceria solo. ]]
local generacion = 0

local function MandarNui(accion, datos)
    SendNUIMessage({ action = accion, data = datos })
end

--[[ El panel va a pantalla completa, como el resto de paneles de admin: fuera
     el HUD y el minimapa mientras esta abierto, y de vuelta al cerrar. ]]
local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera)
    pcall(function() exports.origen_hud:toggleHud(not fuera) end)
    if GetResourceState('origen_map') == 'started' then
        pcall(function() exports.origen_map:Apartar(fuera) end)
    end
end

local function CerrarPanel()
    --[[ El foco se suelta antes que nada y por fuera del guardia de abajo: con
         `abierto` ya en false --dos cierres seguidos, un eco de la NUI-- la
         pantalla se iria y el raton se quedaria en medio, con la camara sin
         responder. Quedarse sin panel se arregla volviendo a abrir; quedarse
         sin camara, no. ]]
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if not abierto then return end

    abierto = false
    HudFuera(false)

    --[[ 280 > los 260 que dura la transicion de salida: la columna se desmonta
         cuando ha acabado de recogerse, no cuando empieza. ]]
    local mia = generacion

    SetTimeout(280, function()
        if generacion ~= mia then return end
        MandarNui('proveedor:cerrar', {})
    end)
end

local function PedirCatalogo()
    CreateThread(function()
        local ok, result = pcall(function()
            return lib.callback.await('origen_businesses:cb:supplierCatalog', false)
        end)

        if not abierto then return end

        if not ok or type(result) ~= 'table' then
            print(('^1[origen_businesses] El catálogo del proveedor no contestó: %s^0'):format(tostring(result)))
            MandarNui('proveedor:error', { texto = 'No se pudo leer el catálogo del proveedor.' })
            return
        end

        if not result.success then
            MandarNui('proveedor:error', { texto = tostring(result.message or 'No se pudo leer el catálogo.') })
            return
        end

        MandarNui('proveedor:datos', { items = result.data or {}, rango = result.range })
    end)
end

local function AbrirPanel()
    if abierto then return end
    abierto = true
    generacion = generacion + 1

    --[[ `SetNuiFocusKeepInput` es un interruptor GLOBAL del cliente y se queda
         como lo dejo el ultimo que lo toco. Por eso se dice aqui que NO en vez
         de dar por hecho que esta apagado. ]]
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    HudFuera(true)

    MandarNui('proveedor:abrir', {})

    --[[ Mandar el mensaje no prueba nada: si la interfaz revienta al montarse,
         Vue desmonta el trozo roto sin decir nada y queda la pantalla en blanco
         con el foco cogido. Contesta cuando se ha pintado, y si no contesta se
         cierra y se suelta el foco. ]]
    nuiPintada = false
    local mia = generacion

    SetTimeout(1500, function()
        if generacion ~= mia or not abierto or nuiPintada then return end

        print('^1[origen_businesses]^0 El panel del proveedor no llegó a pintarse. Se cierra y se suelta el foco para no dejar el ratón preso.')
        CerrarPanel()
    end)
end

--[[ Si el vigilante comun suelta el raton a la fuerza, la columna se va con
     el: si no, quedaba pintada sin raton y con `abierto` en true, y no se
     podia volver a abrir. La generacion sube para que ningun temporizador de
     antes toque lo que venga despues. ]]
OrigenFoco.AlSoltar(function()
    if not abierto then return end
    abierto = false
    HudFuera(false)
    generacion = generacion + 1
    MandarNui('proveedor:cerrar', {})
end)

RegisterNetEvent('origen_businesses:client:openSupplierAdmin', function()
    AbrirPanel()
end)

--[[ Los nombres de los callback de NUI son direcciones y van sin tildes: el
     navegador codifica en la URL todo lo que no sea ASCII y RegisterNUICallback
     no lo encontraria. ]]
RegisterNUICallback('proveedorPintado', function(_, cb)
    nuiPintada = true
    PedirCatalogo()
    cb('ok')
end)

RegisterNUICallback('proveedorRefrescar', function(_, cb)
    if abierto then PedirCatalogo() end
    cb('ok')
end)

RegisterNUICallback('proveedorCerrar', function(_, cb)
    CerrarPanel()
    cb('ok')
end)

RegisterNUICallback('proveedorFijar', function(data, cb)
    if type(data) ~= 'table' then
        return cb({ success = false, message = 'Petición no válida.' })
    end

    local ok, result = pcall(function()
        return lib.callback.await('origen_businesses:cb:setSupplierPrice', false, {
            item = data.item,
            price = data.price
        })
    end)

    if not ok or type(result) ~= 'table' then
        return cb({ success = false, message = 'El servidor no contestó.' })
    end

    cb(result)
end)
