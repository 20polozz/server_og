--[[
    CARTELES DEL LOCAL Y VALLAS PUBLICITARIAS

    Las dos cosas son lo mismo por debajo: un rectángulo pegado a una pared (o
    a la cara de una valla) sobre el que se pinta una página. La página es
    ui/build/lienzo.html, la misma que sirve de vista previa en el panel, así
    que lo que el jefe ve al editar es lo que sale en la calle.

    · CARTELES: los cuelga el negocio dentro de su local, desde la pestaña
      Carteles del panel, marcando dos esquinas en la pared. Llevan un menú
      (platos y precios) o una imagen pegada con Ctrl+V.

    · VALLAS: las da de alta un admin desde el panel de administración de
      negocios (sección Vallas), apuntando a las esquinas de una valla de la
      ciudad. Los negocios las alquilan por días desde la pestaña Publicidad y
      lo paga la caja del negocio. Ocupada = hay que esperar a que termine.

    Permiso de las dos: `manage_signs` («Carteles y publicidad»).
    Servidor: source/server/carteles.lua · Cliente: source/client/carteles.lua
]]

Config = Config or {}

Config.Carteles = {
    -- Cuántos carteles puede tener colgados un negocio.
    PorNegocio = 6,

    --[[ Dónde se pueden colgar: a esta distancia del punto de gestión del
         negocio (o dentro de su zona). El que cuelga tiene que estar en el
         local y a menos de `Alcance` metros de la pared. ]]
    RadioLocal = 40.0,
    Alcance = 10.0,

    -- Tamaño en metros. Por debajo no se lee; por encima es una valla.
    Tam = { minAncho = 0.4, maxAncho = 4.0, minAlto = 0.3, maxAlto = 3.0 },

    -- A qué distancia se pinta y cuántos navegadores a la vez como mucho.
    DistanciaVer = 30.0,
    MaxPintando = 4,

    -- El largo de un nombre de cartel y cuántas líneas lleva un menú.
    NombreMax = 32,
    LineasMax = 16,
}

Config.Vallas = {
    -- Días que se pueden alquilar de una vez, y el total que se puede acumular
    -- prorrogando (quien la tiene no puede quedársela para siempre).
    DiasMin = 1,
    DiasMax = 7,
    AcumuladoMax = 14,

    -- Cuántas vallas puede tener alquiladas a la vez un mismo negocio.
    PorNegocio = 3,

    -- Precio por día que propone el panel de admin al crear una valla.
    PrecioPorDefecto = 2500,
    PrecioMax = 1000000,

    -- Una valla se ve de lejos: distancia de pintado y navegadores a la vez.
    DistanciaVer = 220.0,
    MaxPintando = 3,

    -- Tamaño en metros de lo que marca el admin (las de GTA rondan 10 x 5).
    Tam = { minAncho = 1.0, maxAncho = 30.0, minAlto = 0.5, maxAlto = 15.0 },

    NombreMax = 40,
}

--[[ Los estilos de la plantilla. `id` es lo que se guarda; el aspecto vive en
     ui/source/public/lienzo.html. ]]
Config.Carteles.Temas = {
    { id = 'crema',   label = 'Crema' },
    { id = 'pizarra', label = 'Pizarra' },
    { id = 'neon',    label = 'Neón' },
    { id = 'madera',  label = 'Madera' },
    { id = 'rosa',    label = 'Origen' },
    { id = 'noche',   label = 'Noche' },
}

--[[ Las imágenes solo pueden venir de donde las deja origen_uploader: una
     dirección cualquiera es una puerta a enseñar cualquier cosa en la calle y
     a saber quién mira la valla (la página pide la imagen a ese servidor). ]]
Config.Carteles.ImagenValida = function(url)
    if type(url) ~= 'string' or #url > 300 then return false end
    return url:match('^https://[%w%-]+%.fivemanage%.com/[%w%-%._~/]+$') ~= nil
end

--[[ Las cuatro esquinas del rectángulo a partir de las dos que se marcan
     (abajo a la izquierda y arriba a la derecha) y la normal de la pared.
     Devuelve c1 (abajo izq.), c2 (abajo der.), c3 (arriba izq.), c4 (arriba
     der.), el ancho y el alto. Tablas {x,y,z} y no vector3: la usa también
     el servidor, que valida el tamaño con la misma cuenta que el cliente.

     El rectángulo sale siempre VERTICAL (lo "arriba" es el eje Z proyectado
     en la pared): una valla no está tumbada y así no se tuerce el texto por
     un clic un poco desviado. ]]
function Config.Carteles.Esquinas(p1, p2, n)
    local nx, ny, nz = n.x, n.y, n.z
    local ln = math.sqrt(nx * nx + ny * ny + nz * nz)
    if ln < 1e-6 then return nil end
    nx, ny, nz = nx / ln, ny / ln, nz / ln

    -- En pared: sin componente vertical en la normal, y "arriba" es Z.
    if math.abs(nz) > 0.7 then return nil end
    local lh = math.sqrt(nx * nx + ny * ny)
    nx, ny, nz = nx / lh, ny / lh, 0.0

    -- U: a lo largo de la pared (horizontal). V: arriba.
    local ux, uy, uz = -ny, nx, 0.0
    local vx, vy, vz = 0.0, 0.0, 1.0

    local dx, dy, dz = p2.x - p1.x, p2.y - p1.y, p2.z - p1.z
    local w = dx * ux + dy * uy
    local h = dz

    -- Se ordena para que c1 quede siempre abajo a la izquierda mirando de
    -- frente, se marque en el orden que se marque.
    local ox, oy, oz = p1.x, p1.y, p1.z
    if w < 0 then ox, oy, w = ox + ux * w, oy + uy * w, -w end
    if h < 0 then oz, h = oz + h, -h end

    -- Un pelo por delante de la pared para que no parpadee con ella.
    local sep = 0.03
    ox, oy, oz = ox + nx * sep, oy + ny * sep, oz + nz * sep

    local function P(a, b)
        return { x = ox + ux * a + vx * b, y = oy + uy * a + vy * b, z = oz + uz * a + vz * b }
    end
    return P(0, 0), P(w, 0), P(0, h), P(w, h), w, h
end
