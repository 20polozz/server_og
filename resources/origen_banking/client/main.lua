--[[
    ABRIR Y CERRAR EL BANCO · y la ventanita de «¿con qué cuenta pagas?»

    El banco abre por AbrirBanco() y cierra por CerrarBanco(); el cajero tiene
    las suyas en client/puntos.lua. Todas esconden y devuelven el rastreador
    de misiones, que con la hoja del banco encima se transparentaba.
]]

--- Hay una pantalla del banco delante (el banco o el cajero).
IsInside = false

--- El rastreador de misiones y el logo de los avisos, fuera mientras se ve el banco.
local function HudFuera(fuera)
    TriggerEvent('qv2:suppressHud', fuera == true)
end

--- Un aviso con lo que contesta el servidor ({ success, message }).
function Avisar(result)
    if type(result) ~= 'table' or not result.message then return end
    lib.notify({
        title = result.success and 'Éxito' or 'Error',
        description = result.message,
        type = result.success and 'success' or 'error',
        position = 'top-right',
        duration = 5000,
    })
end

local abriendo = false

function AbrirBanco()
    if IsInside or abriendo then return end
    abriendo = true

    local data = lib.callback.await('origen_banking:cb:getManagementData', false)
    abriendo = false
    if not data then return end
    data.cid = Internal.GetPlayerIdentifier()

    IsInside = true
    HudFuera(true)
    SendNUIMessage({ action = 'openBankManager', data = data })
    SetNuiFocus(true, true)
end

function CerrarBanco()
    -- El foco primero: si algo falla después, lo peor es quedarse sin panel.
    SetNuiFocus(false, false)
    IsInside = false
    HudFuera(false)
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if IsInside then HudFuera(false) end
end)

--[[ ══ CON QUÉ CUENTA PAGAS ═══════════════════════════════════════════════

     La pide el servidor en mitad de un cobro (PayWithActiveAcc) cuando un
     script de compra cobra de banco y hay más de una cuenta con la que pagar.
     Aquí solo se enseña y se contesta el id elegido, o nada si se cancela:
     quien decide si vale es el servidor.

     El foco: FiveM pone delante la pantalla que lo coge y, al soltarlo, se lo
     devuelve a la que lo tenía antes (la tienda). Por eso se coge y se suelta
     sin mirar quién más está abierto. ]]

local pendiente = nil

--- Contesta a la pregunta abierta, si la hay. `id` nil es cancelar.
local function Contestar(id)
    if not pendiente then return end
    local p = pendiente
    pendiente = nil

    SendNUIMessage({ action = 'cerrarElegirCuenta' })
    -- Con el banco abierto detrás, el foco es suyo y se queda.
    if not IsInside then SetNuiFocus(false, false) end

    p:resolve(id)
end

lib.callback.register('origen_banking:client:elegirCuenta', function(datos)
    if pendiente or type(datos) ~= 'table' then return nil end

    pendiente = promise.new()
    local esta = pendiente

    SendNUIMessage({ action = 'elegirCuenta', data = datos })
    SetNuiFocus(true, true)

    --[[ Por si la pantalla no contesta nunca (una excepción en la NUI): se
         cancela sola. La NUI cuenta 30 s; esto es la red de debajo. ]]
    SetTimeout(40000, function()
        if pendiente == esta then Contestar(nil) end
    end)

    return Citizen.Await(esta)
end)

RegisterNUICallback('elegirCuentaRespuesta', function(data, cb)
    cb('ok')
    local id = type(data) == 'table' and type(data.id) == 'string' and data.id or nil
    Contestar(id)
end)

--[[ Raton soltado a la fuerza (vigilante de origen_map/shared/foco.lua o
     `soltarraton`). Sin esto IsInside se quedaba en true y ni el banco ni el
     cajero volvian a abrirse; la pregunta de la cuenta se da por cancelada.
     El cajero recoge lo suyo en client/puntos.lua. ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        Contestar(nil)
        if not IsInside then return end
        IsInside = false
        HudFuera(false)
        SendNUIMessage({ action = 'cerrarBanco' })
    end)
end

AddEventHandler('onResourceStop', function(recurso)
    if recurso ~= GetCurrentResourceName() then return end
    if pendiente then
        SetNuiFocus(false, false)
        pendiente:resolve(nil)
        pendiente = nil
    end
end)
