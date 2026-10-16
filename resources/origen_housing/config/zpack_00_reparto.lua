-- Reparto inicial en packs de lo que ya había en las viviendas (13/10).
--
-- Se carga después de config/furniture.lua y config/packs.lua y antes que el
-- resto de config/zpack_*.lua (orden alfabético). Lo que no se nombra aquí ni
-- en otro zpack es del pack `base`, que tienen todas las casas.
--
-- En `base` queda lo esencial para construir y vivir:
--   · obra: excavar, pared, hueco de puerta, suelo entre plantas, escalera
--     recta (que sube y que baja) e imagen;
--   · pintar: los diez materiales de siempre y el cristal normal;
--   · muebles: todos los del juego del catálogo; de los propios, las cajas, la
--     taquilla, el baúl, la cómoda y la caja fuerte de almacenaje, y la
--     bombilla, el plafón, la lámpara de pie, la de mesa y el interruptor.
--     (La caja fuerte es del básico para que el almacenaje más grande —100 kg—
--     se pueda tener sin pack: los packs son cosméticos, no dan más capacidad.)
--
-- Los packs de muebles nuevos van cada uno en su config/zpack_<nombre>.lua con
-- Config.Packs.Registrar: no hay que tocar este fichero ni ningún otro para
-- que salgan en la cinta, en la creación de casas y en el menú de admin.

-- ── Ajustes de los packs ────────────────────────────────────────────────
-- Lo que la casa no tiene, en la cinta: true = se enseña al final de su
-- categoría, apagado, con candado y el nombre del pack (no se puede poner);
-- false = no se enseña.
Config.Packs.candado = true
-- Quién puede marcar packs al crear una casa y dárselos o quitárselos después
-- (/casacosmeticos): una acción de Config.Permissions. Quien crea casas sin este
-- permiso (la inmobiliaria) las crea solo con el pack básico.
Config.Packs.permiso = 'edit'
-- Las casas sin packs apuntados: solo el básico, sean de la modalidad que sean
-- ('todos' las abría enteras: valía mientras las de modalidad libre eran de pruebas).
Config.Packs.sinApuntar = { libre = 'base', normal = 'base' }
-- Muebles de un pack que tiene cualquier casa: para que ninguna categoría del
-- catálogo se quede sin nada que poner. Siguen saliendo en su categoría.
Config.Packs.basicos = {
    origen_casa_dec_ventana_jardin = true,
    origen_casa_dec_cortina_lino = true,
}

-- A quién se le da lo que se compra (lo usa DarPackComprado / DarPiezaComprada,
-- pensados para la tienda de XP, y el menú /casacosmeticos):
--   'casa'    a esa casa y nada más
--   'cuenta'  al dueño de la casa: vale en TODAS las casas de las que es dueño
-- Las dos vías funcionan siempre (DarPack / DarPackCuenta): una casa tiene lo
-- suyo más lo de la cuenta de su dueño.
Config.Packs.ambito = 'casa'
-- En qué grupo sale cada pack (en la tienda, en el panel de cosméticos y al
-- crear una casa): 'construccion', 'muebles', 'estancia' o 'tematico'. Manda
-- el `grupo` que declare el pack al registrarse; si no, lo que diga esta
-- tabla; si no, 'estancia' si su id empieza por `estancia`, 'construccion' si
-- trae herramientas, materiales o estilos de obra, y 'muebles' el resto.
Config.Packs.grupos = {
    banda = 'tematico', crews = 'tematico', civiles = 'tematico', familia = 'tematico', celebraciones = 'tematico',
    mansion = 'tematico', coleccionista = 'tematico', laboratorio = 'tematico', sotano = 'tematico',
    -- por estancia (revisión final, 13/10: antes caían todos en «Muebles» y el grupo «Estancias» salía vacío)
    salon_moderno = 'estancia', salon_clasico = 'estancia', dormitorio = 'estancia', dormitorio_lujo = 'estancia',
    cocina_moderna = 'estancia', cocina_rustica = 'estancia', electrodomesticos = 'estancia', bano = 'estancia', bano_lujo = 'estancia',
    oficina = 'estancia', tecnologia = 'estancia', estudio_musica = 'estancia', sala_de_juegos = 'estancia', bar_en_casa = 'estancia',
    gimnasio_casa = 'estancia', terraza = 'estancia', vestidor = 'estancia',
    -- (en «Muebles» quedan los que valen para toda la casa: iluminación, almacenaje, armería, ventanas, decoración, arte y plantas)
}
Config.Packs.gruposOrden = { 'construccion', 'muebles', 'estancia', 'tematico' }
Config.Packs.gruposNombre = { construccion = 'Construcción', muebles = 'Muebles', estancia = 'Estancias', tematico = 'Temáticos' }

local P = Config.Packs
local TIPOS = { modelo = true, herramienta = true, material = true, estilo = true }

-- ── Piezas sueltas ──────────────────────────────────────────────────────
-- Además de packs enteros, una casa (o una cuenta) puede tener piezas
-- concretas: 'modelo:origen_casa_porton_madera', 'estilo:secretos:libreria',
-- 'herramienta:ascensor2', 'material:marmol'. La clave es tipo .. ':' .. id,
-- con los mismos tipos e ids que Config.Packs.PackDe.

--- La clave de una pieza suelta, o nil si el tipo no vale
function Config.Packs.Clave(que, id)
    if not TIPOS[que] or type(id) ~= 'string' or id == '' or #id > 80 then return nil end
    return que .. ':' .. id
end

--- ¿La tiene suelta? `acceso`: { packs = { [id] = true }, sueltas = { [clave] = true } }
function Config.Packs.Suelta(acceso, que, id)
    local s = type(acceso) == 'table' and acceso.sueltas
    return type(s) == 'table' and s[tostring(que) .. ':' .. tostring(id)] == true
end

--- ¿Puede usar eso? Sí si es del pack básico, si tiene su pack o si lo tiene suelto.
function Config.Packs.Permite(acceso, que, id)
    if type(acceso) ~= 'table' then return P.PackDe(que, id) == P.base end
    return P.Tiene(acceso.packs, que, id) or Config.Packs.Suelta(acceso, que, id)
end

--- Qué trae un pack: { modelos, herramientas, materiales, estilos, total }
function Config.Packs.Contenido(id)
    local pack = P.lista[id]
    local r = { modelos = pack and #pack.modelos or 0, herramientas = 0, materiales = 0, estilos = 0 }
    for _, de in pairs(P.deHerramienta) do if de == id then r.herramientas = r.herramientas + 1 end end
    for _, de in pairs(P.deMaterial) do if de == id then r.materiales = r.materiales + 1 end end
    for _, de in pairs(P.deEstilo) do if de == id then r.estilos = r.estilos + 1 end end
    r.total = r.modelos + r.herramientas + r.materiales + r.estilos
    return r
end

--- El grupo de un pack: 'construccion', 'muebles', 'estancia' o 'tematico'
function Config.Packs.Grupo(id)
    local pack = P.lista[id]
    if pack and type(pack.grupo) == 'string' and pack.grupo ~= '' then return pack.grupo end
    if P.grupos[id] then return P.grupos[id] end
    if tostring(id):sub(1, 8) == 'estancia' then return 'estancia' end
    local c = Config.Packs.Contenido(id)
    if c.herramientas + c.materiales + c.estilos > 0 then return 'construccion' end
    return 'muebles'
end

--- Cómo se le dice a la gente un grupo ('construccion' → «Construcción»)
function Config.Packs.NombreGrupo(grupo)
    return P.gruposNombre[grupo] or (tostring(grupo):sub(1, 1):upper() .. tostring(grupo):sub(2))
end

--- Cómo se le dice al jugador una pieza suelta por su clave ('material:marmol' → «Material: Mármol blanco»)
function Config.Packs.NombrePieza(clave)
    local que, id = tostring(clave):match('^(%a+):(.+)$')
    if que == 'material' then
        for _, m in ipairs(Config.Obra and Config.Obra.materiales or {}) do
            if m.id == id then return 'Material: ' .. m.nombre end
        end
    elseif que == 'estilo' then
        local grupo, e = id:match('^(%a+):(.+)$')
        local lista = grupo == 'barandillas' and Config.Obra and Config.Obra.barandillas
            or grupo == 'secretos' and Config.Secretos and Config.Secretos.estilos.borde
            or grupo == 'trampillas' and Config.Secretos and Config.Secretos.estilos.suelo or {}
        for _, x in ipairs(lista or {}) do
            if x.id == e then return (grupo == 'barandillas' and 'Barandilla: ' or grupo == 'secretos' and 'Puerta secreta: ' or 'Trampilla: ') .. x.nombre end
        end
    elseif que == 'modelo' then
        local item = __indexFurniture and __indexFurniture[id]
        return 'Mueble: ' .. (item and (item.label or item.nombre) or id)
    elseif que == 'herramienta' then
        -- (por su nombre de la cinta, no por su id: «Ascensor de cabina», no «ascensor2»)
        local nombres = Config.Cinta and Config.Cinta.nombresHerramienta
        return 'Herramienta: ' .. (nombres and nombres[id] or id)
    end
    return tostring(clave)
end

-- Los modelos de una categoría del catálogo que cumplen `vale` (todos, sin él)
local function DeCategoria(etiqueta, vale)
    local r = {}
    for _, cat in ipairs(Config.Furniture or {}) do
        if cat.label == etiqueta then
            for _, it in ipairs(cat.items or {}) do
                if type(it.model) == 'string' and (not vale or vale(it.model)) then r[#r + 1] = it.model end
            end
        end
    end
    return r
end

local function Ids(lista, salvo)
    local r = {}
    for _, e in ipairs(lista or {}) do
        if not (salvo and salvo[e.id]) then r[#r + 1] = e.id end
    end
    return r
end

local function Juntar(...)
    local r = {}
    for _, lista in ipairs({ ... }) do
        for _, v in ipairs(lista) do r[#r + 1] = v end
    end
    return r
end

-- ── Materiales ──────────────────────────────────────────────────────────
P.Registrar({
    id = 'materiales_urbanos', nombre = 'Materiales urbanos',
    descripcion = 'Paredes y suelos gastados para guaridas, almacenes y pisos francos: ladrillo viejo, bloque, chapa, humedad, azulejo sucio…',
    materiales = { 'ladrillo_viejo', 'ladrillo_cal', 'bloque', 'humedad', 'desconchado', 'chapa_oxido', 'tablones',
        'cemento_aceite', 'azulejo', 'linoleo', 'moqueta_sucia', 'chapa_lagrimada' },
})

P.Registrar({
    id = 'materiales_lujo', nombre = 'Materiales de lujo',
    descripcion = 'Mármol blanco y negro, parquet en espiga, microcemento, papel pintado y pizarra',
    materiales = { 'marmol', 'marmol_negro', 'parquet_oscuro', 'microcemento', 'papel', 'pizarra' },
})

P.Registrar({
    id = 'cristales', nombre = 'Cristales',
    descripcion = 'Tabiques y suelos de cristal ahumado, mate, azul, bronce, negro y acanalado',
    materiales = { 'cristal_ahumado', 'cristal_mate', 'cristal_azul', 'cristal_bronce', 'cristal_negro', 'cristal_acanalado' },
})

-- ── Obra ────────────────────────────────────────────────────────────────
-- De cada herramienta hay una versión que tiene cualquier casa (del básico):
-- la escalera recta, el ascensor abierto, la barandilla de acero, el hueco de
-- garaje, la pared falsa y el suelo falso. Lo demás, con su pack.
P.Registrar({
    id = 'escaleras', nombre = 'Escaleras',
    descripcion = 'Escaleras en L, de caracol (compacta y amplia) y de mano',
    herramientas = { 'subeL', 'bajaL', 'escala', 'caracol' },
})

P.Registrar({
    id = 'ascensores', nombre = 'Ascensores',
    descripcion = 'Ascensor de cabina con puertas, de una a cuatro celdas y hasta cinco plantas',
    herramientas = { 'ascensor2' },
})

P.Registrar({
    id = 'barandillas', nombre = 'Barandillas',
    descripcion = 'Barandillas para altillos, huecos y escaleras: cristal, forja, madera, piedra, barrotes…',
    estilos = { barandillas = Ids(Config.Obra and Config.Obra.barandillas, { acero = true }) },
})

-- Garaje: los huecos anchos, el montacoches y, del catálogo, las puertas de
-- garaje (las del juego y los portones propios), los elevadores de taller y
-- las plataformas giratorias.
do
    local garajes = Config.Obra and Config.Obra.garajes or {}
    P.Registrar({
        id = 'garaje', nombre = 'Garaje y taller',
        descripcion = 'Hueco de puerta doble, portones, montacoches, elevadores de taller y plataformas giratorias de exposición',
        herramientas = { 'puerta2', 'montacoches' },
    })
    P.Asignar('garaje', Juntar(
        DeCategoria('Puertas', function(modelo) return garajes[joaat(modelo)] == true end),
        DeCategoria('Taller y exposición')))
end

-- Secretos: puertas secretas y trampillas (con el suelo falso), los
-- disparadores a distancia y la caja fuerte tras un cuadro. La puerta secreta
-- y la trampilla más sencillas, la pared falsa y el suelo falso, son del básico:
-- las tiene cualquier casa. El resto de estilos, con el pack.
do
    local estilos = Config.Secretos and Config.Secretos.estilos or {}
    P.Registrar({
        id = 'secretos', nombre = 'Pasos secretos',
        descripcion = 'Puertas ocultas tras una librería, un armario o un espejo, suelos falsos, trampillas, disparadores y caja fuerte tras un cuadro',
        estilos = { secretos = Ids(estilos.borde, { pared = true }), trampillas = Ids(estilos.suelo, { suelo = true }) },
    })
    P.Asignar('secretos', DeCategoria('Secretos'))
end

-- ── Muebles propios ─────────────────────────────────────────────────────
-- Iluminación: todas las lámparas propias menos las básicas.
do
    local basicas = { origen_casa_luz_bombilla = true, origen_casa_luz_plafon = true, origen_casa_luz_pie = true,
        origen_casa_luz_mesa = true, origen_casa_luz_interruptor = true }
    P.Registrar({
        id = 'iluminacion', nombre = 'Iluminación',
        descripcion = 'Focos empotrados, apliques, lámparas colgantes y de araña, paneles LED, tiras de luz y neones de colores, todos con su interruptor',
    })
    P.Asignar('iluminacion', DeCategoria('Luces', function(modelo)
        return modelo:sub(1, 16) == 'origen_casa_luz_' and not basicas[modelo]
    end))
end

-- Almacenaje: los propios menos los básicos (cajas, taquilla, baúl, cómoda y caja fuerte).
-- REVISIÓN FINAL (13/10): la caja fuerte pasa al básico. Era, con el armero, el único
-- almacenaje de 100 kg que se podía comprar, y los dos estaban en este pack: quien no
-- lo tuviera se quedaba en 50 kg, y eso es ventaja, no cosmético (la tienda promete
-- que «guardan lo mismo que cualquier otro»). Con ella en el básico, cualquier casa
-- llega a la capacidad máxima con dinero del juego y el pack vende solo aspecto.
do
    local basicos = { origen_casa_alm_cajas = true, origen_casa_alm_taquilla = true, origen_casa_alm_baul = true, origen_casa_alm_comoda = true,
        origen_casa_alm_caja_fuerte = true }
    P.Registrar({
        id = 'almacenaje', nombre = 'Almacenaje',
        descripcion = 'Armero de dos puertas, arcón militar, aparador de roble, congelador de arcón, carro de herramientas y maleta de aluminio: puertas, tapas y cajones que se abren de verdad',
    })
    P.Asignar('almacenaje', DeCategoria('Almacenaje', function(modelo)
        return modelo:sub(1, 16) == 'origen_casa_alm_' and not basicos[modelo]
    end))
end

-- Sótano: las dos categorías de guarida, con sentarse, tumbarse y atar a la silla.
P.Registrar({
    id = 'sotano', nombre = 'Sótano y celda',
    descripcion = 'Sala de interrogatorio, celda con barrotes, colchones y herramientas: sillas en las que sentar y atar a un esposado',
})
P.Asignar('sotano', Juntar(DeCategoria('Sótano'), DeCategoria('Sótano: celda y herramientas')))
