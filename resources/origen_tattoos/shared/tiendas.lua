--[[ Las tiendas ya no se quedan en el config: se guardan en la base de datos
     (origen_tattoos_tiendas) y se mueven desde el panel de admin, /tattooconfig
     o la tarjeta de la pestaña Scripts. Las de `Config.Stores` de _config.lua
     son solo la siembra de la primera vez.

     Cada tienda tiene cinco puntos:
       entrada   donde se pulsa E para abrir el catalogo
       silla     hasta donde camina el cliente antes de tumbarse
       cliente   donde queda tumbado mientras le tatuan
       espera    donde esta el tatuador cuando no hay nadie
       tatuando  donde se pone el tatuador para tatuar ]]

Config.Permiso = 'origen_tattoos'
Config.Comando = 'tattooconfig'

-- Ningun punto se aleja mas que esto de la entrada de su tienda.
Config.RadioTienda = 30.0
Config.TopeTiendas = 40

Config.ModeloTatuador = 'IG_DJSolMike'

Config.Anim = {
    cliente  = { dict = 'misstattoo_parlour@shop_ig_4', anim = 'customer_loop' },
    espera   = { dict = 'rcmnigel1a', anim = 'base' },
    tatuando = { dict = 'misstattoo_parlour@shop_ig_4', anim = 'tattooist_loop' },
}

Config.Puntos = { 'entrada', 'silla', 'cliente', 'espera', 'tatuando' }

--- De la fila guardada (`t.puntos[cual] = {x, y, z, h}`) a la forma que usa
--- el resto del recurso, con vectores: lo que llega por la red o de la base
--- son tablas, y `SetEntityCoords(ped, tabla)` no vale.
function TiendaParaElJuego(t)
    local p = t.puntos
    local function v4(c) return vector4(c.x + 0.0, c.y + 0.0, c.z + 0.0, (c.h or 0) + 0.0) end
    return {
        id = t.id,
        label = t.nombre,
        blip = t.blip ~= false,
        coords = vector3(p.entrada.x + 0.0, p.entrada.y + 0.0, p.entrada.z + 0.0),
        customer = {
            chair = v4(p.silla),
            coords = v4(p.cliente),
            anim = Config.Anim.cliente.anim,
            dict = Config.Anim.cliente.dict,
        },
        employee = {
            idle = { coords = v4(p.espera), anim = Config.Anim.espera.anim, dict = Config.Anim.espera.dict },
            tattoo = { coords = v4(p.tatuando), anim = Config.Anim.tatuando.anim, dict = Config.Anim.tatuando.dict },
            model = t.modelo or Config.ModeloTatuador,
        },
    }
end

--- Al reves: una tienda de `Config.Stores` (la siembra) a fila.
function TiendaParaGuardar(s, nombre)
    local function c(v) return { x = v.x, y = v.y, z = v.z, h = v.w } end
    return {
        nombre = nombre or s.label or 'Tatuajes',
        blip = s.blip ~= false,
        modelo = s.employee.model or Config.ModeloTatuador,
        puntos = {
            entrada = { x = s.coords.x, y = s.coords.y, z = s.coords.z },
            silla = c(s.customer.chair),
            cliente = c(s.customer.coords),
            espera = c(s.employee.idle.coords),
            tatuando = c(s.employee.tattoo.coords),
        },
    }
end
