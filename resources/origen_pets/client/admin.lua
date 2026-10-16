--[[ ── Mascotas · la tienda y el panel de administración ────────────────────

     Dos pantallas de la misma NUI, aparte del panel de mascotas:

       · la TIENDA, la columna del canto con el catálogo y sus precios;
       · el ADMIN, a pantalla completa, con el lenguaje de la tablet.

     El admin lo abre el panel de administración por su lista de scripts, con
     `openManagement()`, igual que el resto de recursos. ]]

local tiendaAbierta = false
local adminAbierto = false

--- Mientras se piden cuentas y experiencia la tienda aun no esta abierta, pero
--- una segunda E no puede abrir otra. Caduca sola por si el servidor no
--- contesta.
local abriendoHasta = 0

-- ── La tienda ─────────────────────────────────────────────────────────────

function AbrirPantallaTienda(titulo, catalogo, articulos)
    if tiendaAbierta or GetGameTimer() < abriendoHasta then return end
    abriendoHasta = GetGameTimer() + 5000

    --[[ Las cuentas van con la tienda, no en una llamada aparte al elegir
         perro: el saldo decide que puedes comprar, asi que tiene que estar en
         pantalla desde el primer momento. Si el banco no esta, llega vacio y la
         tienda lo dice en vez de dejar el boton muerto sin explicacion. ]]
    local cuentas = lib.callback.await('origen_pets:cuentas', false) or {}

    -- Y la experiencia, por lo mismo: las VIP se pagan con ella y hay que ver
    -- cuanta tienes antes de elegir, no despues de darle a comprar.
    local xp = lib.callback.await('origen_pets:xp', false) or { activo = false, xp = 0 }

    --[[ Abierta justo aqui, no antes de las dos esperas: con la marca puesta
         desde el principio, un cierre a la fuerza en medio la daba por
         abierta sin pantalla y la tienda ya no volvia a abrirse. ]]
    abriendoHasta = 0
    tiendaAbierta = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        accion = 'tienda',
        datos = {
            titulo = titulo,
            catalogo = catalogo,
            articulos = articulos or {},
            cuentas = cuentas,
            xp = xp,
        },
    })
end

--[[ Cerrar la tienda.

     El foco se suelta YA y el desmontaje espera a que acabe la animacion de
     salida. Al reves --esperar los dos-- el raton se queda presa 260 ms
     despues de que la tienda ya parezca cerrada, y si el aviso de la NUI no
     llega por lo que sea, preso del todo: la pantalla se ha ido pero la camara
     no vuelve. Soltar primero es lo que hace que eso no pueda pasar. ]]
local function CerrarTienda()
    if not tiendaAbierta then return end
    tiendaAbierta = false

    SetNuiFocus(false, false)

    -- El perro de muestra y su camara se van con la tienda.
    Aspecto.CerrarVista()

    -- 280 y no 260: la transicion de la NUI dura 260, y desmontar justo en el
    -- ultimo fotograma se ve como un corte.
    -- Si en esos 280 ms se ha vuelto a abrir, no se le desmonta la nueva.
    SetTimeout(280, function()
        if tiendaAbierta then return end
        SendNUIMessage({ accion = 'cerrarTienda' })
    end)
end

RegisterNUICallback('tiendaCerrar', function(_, cb)
    cb({})
    CerrarTienda()
end)

RegisterNUICallback('comprar', function(datos, cb)
    local r = lib.callback.await('origen_pets:comprar', false, {
        raza = datos and datos.raza,
        nombre = datos and datos.nombre,
        -- Con que se paga y, si es dinero, de que cuenta. El servidor lo
        -- vuelve a comprobar contra los precios de verdad.
        medio = datos and datos.medio,
        cuenta = datos and datos.cuenta,
        -- El aspecto elegido mirando el perro de muestra. Lo sabe este cliente
        -- y no la NUI: ella solo cuenta "la 3 de 5". El servidor lo recorta.
        aspecto = Aspecto.Elegido(datos and datos.raza),
    })

    TriggerEvent('QBCore:Notify', (r and r.mensaje) or 'No se pudo.', (r and r.ok) and 'success' or 'error')

    --[[ Con la compra hecha se cierra --ya tienes lo que venias a buscar-- pero
         cerrando desde AQUI la pantalla desaparecia de golpe, sin la animacion
         de salida. Se le dice a la NUI que ha ido bien y es ella la que llama a
         cerrar, que es el mismo camino que Escape y que el clic fuera. ]]
    cb({ ok = r and r.ok or false })
end)

--[[ El perro de muestra. La tienda avisa al elegir raza (o al soltarla, con
     clave nil) y al pasar de opcion en una pieza; aqui se pone en el juego y
     se le devuelve cuantas opciones hay de cada cosa. ]]
RegisterNUICallback('verRaza', function(datos, cb)
    if not tiendaAbierta then return cb({ opciones = {} }) end
    cb(Aspecto.VerRaza(datos and datos.clave or nil))
end)

RegisterNUICallback('aspecto', function(datos, cb)
    if not tiendaAbierta then return cb({ opciones = {} }) end
    cb(Aspecto.Cambiar(tonumber(datos and datos.pieza), datos and datos.indice))
end)

-- ── El panel de administración ────────────────────────────────────────────

local function DatosAdmin()
    return lib.callback.await('origen_pets:admin:datos', false)
end

local function AbrirAdmin()
    if adminAbierto then return end

    local datos = DatosAdmin()

    if not datos or not datos.permiso then
        TriggerEvent('QBCore:Notify', 'No tienes permiso para esto.', 'error')
        return
    end

    adminAbierto = true
    SetNuiFocus(true, true)
    SendNUIMessage({ accion = 'admin', datos = datos })
end

exports('openManagement', AbrirAdmin)

local function CerrarAdmin()
    if not adminAbierto then return end
    adminAbierto = false

    SetNuiFocus(false, false)
    SendNUIMessage({ accion = 'cerrarAdmin' })
end

--[[ Volver al panel de admin, que es de donde se viene. Lo hacen todos los
     paneles de script del servidor: el suyo se cierra y reabre el admin en su
     pestaña de scripts. Ya no hay botón: es lo que hace ESC. origen_admin
     solo vuelve si este panel se abrió desde su pestaña Scripts; si no, ESC
     cierra y nada más. ]]
local function CerrarYVolver()
    CerrarAdmin()

    if GetResourceState('origen_admin') ~= 'started' then return end
    SetTimeout(80, function()
        pcall(function() exports['origen_admin']:ReturnToScripts() end)
    end)
end

RegisterNUICallback('adminVolver', function(_, cb)
    cb({})
    CerrarYVolver()
end)

RegisterNUICallback('adminCerrar', function(_, cb)
    cb({})
    CerrarYVolver()
end)

--[[ Si el vigilante comun (@origen_map/shared/foco.lua) suelta el raton a la
     fuerza, la tienda y el admin se cierran del todo: las marcas a false para
     poder volver a abrirlos, y en la tienda el perro de muestra y su camara
     fuera (CerrarTienda ya llama a Aspecto.CerrarVista). ]]
if OrigenFoco then
    OrigenFoco.AlSoltar(function()
        if tiendaAbierta then CerrarTienda() end
        abriendoHasta = 0
        if adminAbierto then CerrarAdmin() end
    end)
end

RegisterNUICallback('adminGuardarRaza', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:guardarRaza', false, datos) or { ok = false })
end)

RegisterNUICallback('adminBorrarRaza', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:borrarRaza', false, datos) or { ok = false })
end)

RegisterNUICallback('adminGuardarArticulo', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:guardarArticulo', false, datos) or { ok = false })
end)

RegisterNUICallback('adminBorrarArticulo', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:borrarArticulo', false, datos) or { ok = false })
end)

-- Las mascotas de la gente: quitar, cambiar de raza y curar.
--- Con codigo de spawn se mira aqui que el modelo exista: el servidor no
--- tiene el juego para saberlo, y una raza con un modelo que no esta no saldria.
RegisterNUICallback('adminDarMascota', function(datos, cb)
    local codigo = type(datos) == 'table' and tostring(datos.codigo or '') or ''
    if type(datos) == 'table' and tostring(datos.raza or '') == '' then
        local hash = joaat(codigo)
        if codigo == '' or not (IsModelInCdimage(hash) and IsModelAPed(hash)) then
            return cb({ ok = false, mensaje = ('«%s» no es un modelo de animal que tenga el servidor.'):format(codigo) })
        end
    end
    cb(lib.callback.await('origen_pets:admin:darMascota', false, datos) or { ok = false })
end)

RegisterNUICallback('adminQuitarMascota', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:quitarMascota', false, datos) or { ok = false })
end)

RegisterNUICallback('adminCambiarMascota', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:cambiarMascota', false, datos) or { ok = false })
end)

RegisterNUICallback('adminCurarMascota', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:curarMascota', false, datos) or { ok = false })
end)

--[[ La imagen no viaja en la llamada que pide subirla.

     Cfx recomienda no pasar de ~50 KB por evento; un base64 mayor no da error,
     se PIERDE, y el panel se queda en "Subiendo" para siempre. Por eso los
     bytes van antes por el envio latente del uploader --PrepararSubida-- y aqui
     solo cruza el resguardo con el que recogerlos.

     El fichero llega desde la NUI pegado con Ctrl+V: el <input type="file"> de
     FiveM abre el explorador una sola vez por partida (fallo abierto de Cfx), y
     despues no vuelve a abrirse aunque se reinicie el recurso. ]]
RegisterNUICallback('adminSubirImagen', function(datos, cb)
    if GetResourceState('origen_uploader') ~= 'started' then
        return cb({ ok = false, mensaje = 'El servicio de imágenes no está disponible.' })
    end

    local resguardo, motivo = exports['origen_uploader']:PrepararSubida(
        datos and datos.nombre, datos and datos.base64)

    if not resguardo then
        return cb({ ok = false, mensaje = motivo or 'No se pudo enviar la imagen.' })
    end

    cb(lib.callback.await('origen_pets:admin:subirImagen', false, {
        resguardo = resguardo,
        nombre = datos and datos.nombre,
        para = datos and datos.para,
    }) or { ok = false })
end)

RegisterNUICallback('adminGuardarTienda', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:guardarTienda', false, datos) or { ok = false })
end)

RegisterNUICallback('adminBorrarTienda', function(datos, cb)
    cb(lib.callback.await('origen_pets:admin:borrarTienda', false, datos) or { ok = false })
end)

--[[ Coger las coordenadas de donde estás.

     Es lo que ahorra el viaje de ir al sitio, apuntar los números a mano y
     volver a escribirlos: se pone uno donde quiere la tienda y pulsa. La altura
     se baja un metro porque el ped se planta en el suelo y el jugador se mide
     desde la cintura. ]]
--[[ Sin tilde en el nombre, y es lo que lo tenia roto.

     La interfaz llama a estos callbacks con un fetch a
     https://<recurso>/<nombre>, y el navegador codifica en la URL todo lo que
     no sea ASCII: la "i" con tilde viajaba como %C3%AD. RegisterNUICallback
     busca el nombre literal, asi que no casaba con nada y la peticion se
     quedaba sin respuesta -- el boton "Coger de donde estoy" no rellenaba
     nada y no habia error en ninguna consola.

     Los nombres de callback son direcciones, no texto para leer: van en ASCII
     aunque el resto del recurso este en castellano. ]]
RegisterNUICallback('adminAqui', function(_, cb)
    local coords = GetEntityCoords(cache.ped)

    cb({
        x = tonumber(('%.2f'):format(coords.x)),
        y = tonumber(('%.2f'):format(coords.y)),
        z = tonumber(('%.2f'):format(coords.z)),
        h = tonumber(('%.2f'):format(GetEntityHeading(cache.ped))),
    })
end)

--- Ir a una tienda para verla, sin salir del panel.
RegisterNUICallback('adminIr', function(datos, cb)
    cb({})
    if not datos then return end

    SetEntityCoords(cache.ped, datos.x + 0.0, datos.y + 0.0, datos.z + 0.0, false, false, false, false)
end)

--[[ Los suministros no cierran la tienda: pienso y agua se compran de varios en
     varios, y cerrar despues de cada uno obligaria a volver a entrar. Se
     refresca el saldo, que es lo unico que cambia en pantalla. ]]
RegisterNUICallback('comprarArticulo', function(datos, cb)
    local r = lib.callback.await('origen_pets:comprarArticulo', false, {
        id = datos and datos.id,
        veces = datos and datos.veces,
        medio = datos and datos.medio,
        cuenta = datos and datos.cuenta,
    })

    TriggerEvent('QBCore:Notify', (r and r.mensaje) or 'No se pudo.', (r and r.ok) and 'success' or 'error')

    cb({
        ok = r and r.ok or false,
        cuentas = lib.callback.await('origen_pets:cuentas', false) or {},
        xp = lib.callback.await('origen_pets:xp', false) or { activo = false, xp = 0 },
    })
end)
