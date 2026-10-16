--[[ El panel de administracion, del lado del cliente.

     Es una pantalla aparte del telefono, no una aplicacion suya: quien
     administra puede no llevar ningun aparato encima. Ocupa toda la pantalla y
     se abre con foco de raton normal, sin el `SetNuiFocusKeepInput` con el que
     se abre el telefono: aqui nadie quiere seguir andando mientras dibuja una
     zona de cobertura en un mapa.

     Tambien vive aqui lo que el servidor manda cuando alguien cambia un ajuste,
     porque le llega a **todos** los jugadores, no solo a quien administra.
]]

local abierto = false

--- Lo que el servidor dice que vale ahora mismo. Lo pide el telefono al abrir.
AjustesDelServidor = nil

local Cerrar

--[[ ESC: cerrar y, si el panel se abrio desde la pestaña Scripts de
     origen_admin, volver a ella. origen_admin solo vuelve si este panel salio
     de su lista; abierto con el comando, ESC cierra y nada mas. ]]
local function CerrarYVolver()
    if not abierto then return end
    Cerrar()
    if GetResourceState('origen_admin') ~= 'started' then return end
    SetTimeout(80, function()
        pcall(function() exports['origen_admin']:ReturnToScripts() end)
    end)
end

--[[ Escape leido desde aqui, por si la pagina no contesta.

     El panel se abre SIN KeepInput, asi que el juego no ve ninguna tecla y el
     unico Escape era el de la propia pagina (views/Admin.vue), que solo cierra
     si ella cree que el panel esta abierto. Si el 'admin:open' se pierde —la
     pagina aun cargando justo despues de reiniciar el recurso— el foco
     quedaba puesto sin nada en pantalla y sin tecla que lo quitara.

     IsRawKeyReleased lee la tecla en crudo, sin pasar por los controles del
     juego. SIN PROBAR EN EL JUEGO que llegue con la NUI quedandose el teclado;
     si no llegara, no cambia nada y queda `soltarraton` en F8 (ver AlSoltar
     abajo). Cerrar dos veces no hace nada la segunda. ]]
local function VigilarEscape()
    if not IsRawKeyReleased then return end

    CreateThread(function()
        while abierto do
            if IsRawKeyReleased(27) then
                CerrarYVolver()
                break
            end
            Wait(0)
        end
    end)
end

--- Abre el panel.
local function Abrir(datos)
    if abierto then return end

    --[[ El telefono, fuera antes.

         Comparten pagina y el foco es por recurso: con el telefono abierto, el
         panel heredaba su KeepInput (escribir en el panel movia al personaje) y
         al cerrar el panel se soltaba el foco del telefono tambien, dejandolo
         pintado sin raton. ]]
    if Phone and Phone.open then Phone.Close() end

    abierto = true

    --- Sin teclas para el juego, con cursor; y si la tienda estaba abierta, se cierra.
    Foco.Panel('admin', true)

    --- La marca (origen | nacion): el panel se abre sin telefono, y sin ella
    --- la pagina no sabe que estilo ponerse. `origen:marca` es `setr`.
    if type(datos) ~= 'table' then datos = {} end
    datos.marca = GetConvar('origen:marca', 'origen')

    Nui.Send('admin:open', datos)
    VigilarEscape()
end

--- Y lo cierra.
Cerrar = function()
    if not abierto then return end

    abierto = false

    Foco.Panel('admin', false)
    Nui.Send('admin:close', {})
end

CerrarAdmin = Cerrar
AbrirAdmin = Abrir

Foco.AlCerrar('admin', function() Cerrar() end)

--[[ Si la red de seguridad suelta el foco a la fuerza (`soltarraton`), el
     panel se da por cerrado. Sin esto `abierto` seguia en true y el panel ya
     no se podia volver a abrir hasta reiniciar el recurso. ]]
if OrigenFoco and OrigenFoco.AlSoltar then
    OrigenFoco.AlSoltar(function()
        if not abierto then return end
        abierto = false
        Foco.admin = false
        Nui.Send('admin:close', {})
    end)
end

RegisterNetEvent('origen_phone:cl:openAdmin', Abrir)

--[[ La puerta desde el hub de administracion.

     El panel de origen_admin abre el de cada recurso llamando a
     exports[recurso]:openManagement(). Aqui no se puede abrir sin mas: la
     pantalla necesita los ajustes que solo tiene el servidor, y el permiso se
     comprueba alli. Asi que se le pide al servidor lo mismo que le pide el
     comando, y el responde con el evento de arriba. ]]
exports('openManagement', function()
    TriggerServerEvent('origen_phone:sv:openAdmin')
end)

Nui.On('adminClose', function()
    CerrarYVolver()
    return true
end)

Nui.On('adminTeleport', function(params)
    if params and tonumber(params.x) and tonumber(params.y) then
        local ped = PlayerPedId()
        SetEntityCoords(ped, params.x + 0.0, params.y + 0.0, (params.z or 0.0) + 0.0, false, false, false, false)
        return true
    end
    return false
end)

--[[ Coger un punto del mapa donde esta el jugador.

     Para poner un punto de carga donde uno esta plantado, que es como se ponen
     de verdad: se va al sitio, se mira que quede bien y se guarda. Dar las
     coordenadas a mano es pedirle a alguien que las saque de otro sitio. ]]
Nui.On('adminHere', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)

    -- Colocar 1.5m delante del jugador, pegado al suelo y encarado hacia él
    local targetX = coords.x + fwd.x * 1.5
    local targetY = coords.y + fwd.y * 1.5
    local bien, alto = GetGroundZFor_3dCoord(targetX, targetY, coords.z + 1.0, false)
    local sueloZ = bien and alto or (coords.z - 1.0)

    local rawZone = GetNameOfZone(targetX, targetY, sueloZ)
    local label = GetLabelText(rawZone)
    if not label or label == 'NULL' or label == '' then
        label = (rawZone and rawZone ~= '') and rawZone or 'Punto de carga'
    end

    return {
        x = math.floor(targetX * 1000) / 1000,
        y = math.floor(targetY * 1000) / 1000,
        z = math.floor(sueloZ * 1000) / 1000,
        h = (GetEntityHeading(ped) + 180.0) % 360.0,
        label = label,
    }
end)

--[[ Los ajustes cambiados, en caliente.

     Le llega a todo el mundo en cuanto alguien toca el panel. Se guardan aqui y
     se le pasan a la interfaz: si el telefono esta abierto, lo ve al momento; y
     si no, se los encontrara al abrirlo. ]]
RegisterNetEvent('origen_phone:cl:settings', function(ajustes)
    AjustesDelServidor = ajustes
    Nui.Send('serverSettings', ajustes)
end)

--[[ Le han cambiado el numero desde el panel.

     El telefono tiene el numero viejo metido en memoria y en la interfaz, asi
     que hay que cerrarlo: al volver a abrirlo arranca con el nuevo. Cerrarlo es
     mas honesto que intentar cambiarlo por dentro, donde el numero esta en
     todas partes. ]]
RegisterNetEvent('origen_phone:cl:numberChanged', function()
    if Phone and Phone.Close then Phone.Close() end
end)
