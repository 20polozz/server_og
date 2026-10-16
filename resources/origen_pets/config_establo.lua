--[[ ── El establo ───────────────────────────────────────────────────────────

     Donde se compran los caballos: la granja de los cobertizos largos de
     Grapeseed, la de las vacas, al sur del rancho O'Neil (alli vive una banda:
     el establo estuvo en su picadero y se movio el 15/10). Los caballos se
     exponen en fila delante del cobertizo largo, cada uno con su montura
     puesta y mirando al claro; en la punta de la fila hay un caballerizo con
     el catalogo entero.

     Los caballos expuestos son LOCALES (CreatePed sin red): cada cliente pinta
     los suyos al acercarse y los borra al irse. No ocupan sitio en el servidor
     ni se los puede llevar nadie.

     El cobro lo hace server/establo.lua, que vuelve a mirar el precio, el
     trabajo y la distancia: lo que diga el cliente no vale para nada. ]]
Config.Establo = {}

Config.Establo.Nombre = 'Establo de Grapeseed'

--[[ El centro de la fila, medido en el juego desde arriba (15/10): a 9 m del
     eje del cobertizo largo, hacia el claro. `rumbo` es hacia donde miran los
     caballos (al claro, nordeste); la fila corre perpendicular, a lo largo del
     cobertizo, con `separacion` metros entre caballo y caballo. ]]
Config.Establo.Centro = { x = 2252.9, y = 4921.2, z = 40.0 }
Config.Establo.Fila = { rumbo = 314.2, separacion = 3.6 }

-- El caballerizo: en la punta noroeste de la fila, mirando a los caballos.
Config.Establo.Caballerizo = { modelo = 'a_m_m_farmer_01', x = 2237.2, y = 4939.6, z = 40.0, h = 224.2 }

-- A que distancia aparece todo (caballos, heno, caballerizo) y se borra.
Config.Establo.Distancia = 90.0

-- Para comprar hay que estar aqui: el servidor lo comprueba con esta distancia
-- al centro de la fila.
Config.Establo.DistanciaCompra = 30.0

-- A cuanto de un caballo sale el [E] para verlo.
Config.Establo.DistanciaVer = 3.2

--[[ Los trabajos de la ley, por nombre de trabajo (qbx_core/shared/jobs.lua).
     `police` y `sapd` son policia; `sheriff` es el BCSD. ]]
Config.Establo.Oficios = {
    police  = 'Policía',
    sapd    = 'Policía',
    sheriff = 'Sheriff',
}

--[[ Si es true, los caballos de servicio SOLO los puede tener quien sea de ese
     trabajo (al resto le sale «Reservado»). Si es false, el resto los compra a
     su precio y a los de ese trabajo les salen gratis. ]]
Config.Establo.SoloOficio = true

--[[ ── Los caballos ─────────────────────────────────────────────────────────

     Uno por cada aspecto que trae el pack, revisados uno a uno en el juego
     (15/10, fotos de cada combinacion):

       a_c_horse_police  El caballo grande, siempre con silla. Pieza 0: manta
                         verde con estrella (sheriff, la de serie), azul con
                         placa (policia) y marron lisa; las dos ultimas las
                         pintamos (config_caballos.lua, Config.Caballos.Piezas).
       ft_ahorse         Cuarto de milla. La pieza 2 es la montura:
                         0/0 = manta «SHERIFF K-9», 0/1 = «POLICE K-9»,
                         0/2 = silla civil marron (nuestra), 1/0 = sin montura.
       ft_horse          Poni. Seis pelajes en la pieza 0; no lleva montura.

     `raza` es la clave de Config.Razas; `aspecto` es lo que se guarda con la
     mascota ({ pieza, drawable, textura }). `oficios` = a quien le sale gratis.
     `precio` en dolares; 0 = no se vende a quien no tenga el oficio. ]]
Config.Establo.Caballos = {
    {
        id = 'patrulla_sheriff', raza = 'caballo_policia', aspecto = { { 0, 0, 0 } },
        nombre = 'Caballo de patrulla · Sheriff',
        detalle = 'Silla con manta verde y estrella',
        precio = 75000, oficios = { 'sheriff' },
    },
    {
        id = 'patrulla_policia', raza = 'caballo_policia', aspecto = { { 0, 0, 1 } },
        nombre = 'Caballo de patrulla · Policía',
        detalle = 'Silla con manta azul y placa',
        precio = 75000, oficios = { 'police', 'sapd' },
    },
    {
        id = 'caballo_silla', raza = 'caballo_policia', aspecto = { { 0, 0, 2 } },
        nombre = 'Caballo ensillado',
        detalle = 'Silla con manta marrón, sin insignias',
        precio = 45000,
    },
    {
        id = 'k9_sheriff', raza = 'caballo_sheriff', aspecto = { { 2, 0, 0 } },
        nombre = 'Cuarto de milla · Sheriff',
        detalle = 'Montura «Sheriff K-9»',
        precio = 60000, oficios = { 'sheriff' },
    },
    {
        id = 'k9_policia', raza = 'caballo_sheriff', aspecto = { { 2, 0, 1 } },
        nombre = 'Cuarto de milla · Policía',
        detalle = 'Montura «Police K-9»',
        precio = 60000, oficios = { 'police', 'sapd' },
    },
    {
        id = 'cuarto_milla', raza = 'caballo_sheriff', aspecto = { { 2, 0, 2 } },
        nombre = 'Cuarto de milla',
        detalle = 'Silla de cuero marrón, sin insignias',
        precio = 40000,
    },
    { id = 'poni_bayo',      raza = 'poni', aspecto = { { 0, 0, 0 } }, nombre = 'Poni bayo',            detalle = 'Pelaje bayo, crin negra',    precio = 18000 },
    { id = 'poni_alazan',    raza = 'poni', aspecto = { { 0, 0, 1 } }, nombre = 'Poni alazán',          detalle = 'Pelaje alazán',              precio = 18000 },
    { id = 'poni_negro',     raza = 'poni', aspecto = { { 0, 0, 2 } }, nombre = 'Poni negro',           detalle = 'Pelaje negro entero',        precio = 20000 },
    { id = 'poni_ruano',     raza = 'poni', aspecto = { { 0, 0, 3 } }, nombre = 'Poni ruano',           detalle = 'Pelaje gris pardo',          precio = 18000 },
    { id = 'poni_appaloosa', raza = 'poni', aspecto = { { 0, 0, 4 } }, nombre = 'Poni appaloosa',       detalle = 'Blanco con manchas',         precio = 24000 },
    { id = 'poni_leopardo',  raza = 'poni', aspecto = { { 0, 0, 5 } }, nombre = 'Poni appaloosa oscuro', detalle = 'Manchado, cabeza negra',    precio = 24000 },
}

--[[ Lo que ambienta el corro, ademas de lo que ya trae el rancho: a cada
     caballo, un poco de heno delante. `delante` y `lado` en metros respecto al
     caballo; `h` se suma a su rumbo. ]]
Config.Establo.Atrezo = {
    { modelo = 'prop_haybale_01', delante = 1.9, lado = -0.9, h = 90.0 },
}

-- Y alrededor del caballerizo: sacos de pienso y un cubo. Sin mesa ni heno
-- apilado: se pisaban (15/10), y el rancho ya trae su heno.
Config.Establo.AtrezoFijo = {
    { modelo = 'prop_feed_sack_01',  x = 2235.4, y = 4941.6, z = 40.0, h = 10.0 },
    { modelo = 'prop_feed_sack_02',  x = 2236.2, y = 4942.3, z = 40.0, h = 80.0 },
    { modelo = 'prop_bucket_02a',    x = 2239.0, y = 4941.0, z = 40.0, h = 0.0 },
}
