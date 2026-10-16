--[[ ═══════════════════════════════════════════════════════════════════════
     Las categorias de puntos del mapa

     UN solo sitio donde se dice que categorias hay, como se llaman y con que
     dibujo se pintan. Antes esta tabla estaba copiada en cuatro ficheros
     —origen_map, origen_pausemenu, origen_inventory y el propio
     origen_blipmanager— y cada copia se fue por su lado: una categoria nueva
     salia en un mapa y en los otros no.

     Se carga como shared_script para que la vean el cliente de este recurso y,
     por el export `Categorias`, los otros dos mapas de Leaflet.

     El `icono` NO es de ninguna libreria: es una clave de la tabla DIBUJOS que
     cada interfaz tiene en su fichero (html/mapa.js aqui para el minimapa, y
     source-ui/src/components/mapa/MapaGrande.vue en origen_inventory para el
     mapa grande). Si se añade un icono nuevo hay que dibujarlo en las dos, con
     la misma cadena: el menu de pausa, que tenia la tercera copia, ya no existe.
     Un punto puede traer su propio `icono` y pisar el de su categoria; una
     clave que no este dibujada sale como `edificio`.
   ═══════════════════════════════════════════════════════════════════════ ]]

OrigenMapCategorias = {
    { id = 'garages',     label = 'Garajes',      icono = 'coche' },
    { id = 'banking',     label = 'Bancos',       icono = 'dinero' },
    { id = 'shops',       label = 'Tiendas',      icono = 'cesta' },
    { id = 'public',      label = 'Servicios',    icono = 'edificio' },
    { id = 'housing',     label = 'Viviendas',    icono = 'casa' },
    { id = 'illegal',     label = 'Ilegal',       icono = 'calavera' },
    { id = 'racing',      label = 'Carreras',     icono = 'bandera' },
    { id = 'activities',  label = 'Ocio',         icono = 'ocio' },
    { id = 'mascotas',    label = 'Mascotas',     icono = 'huella' },
    { id = 'telefonos',   label = 'Telefonos',    icono = 'movil' },

    --[[ Las que antes no existian como categoria porque se colaban dentro de
         otra por el numero de su sprite. Ahora que cada recurso dice a que
         categoria pertenece, pueden tener la suya. ]]
    { id = 'trabajos',    label = 'Trabajos',     icono = 'maletin' },
    { id = 'gasolineras', label = 'Gasolineras',  icono = 'gasolina' },
    { id = 'emergencias', label = 'Emergencias',  icono = 'cruz' },
    { id = 'locales',     label = 'Locales',      icono = 'local' },
    { id = 'misiones',    label = 'Misiones',     icono = 'persona' },
    { id = 'avisos',      label = 'Avisos',       icono = 'sirena' },
    { id = 'referencias', label = 'Unidades',     icono = 'escudo' },
    { id = 'eventos',     label = 'Eventos',      icono = 'estrella' },
}

--- El singular de cada categoria, para cuando de un punto no se sabe el nombre.
--- "Tiendas Vespucci" suena a lista; "Tienda Vespucci" suena a sitio.
OrigenMapSingular = {
    garages     = 'Garaje',
    banking     = 'Banco',
    shops       = 'Tienda',
    public      = 'Servicio',
    housing     = 'Vivienda',
    illegal     = 'Punto ilegal',
    racing      = 'Carrera',
    activities  = 'Ocio',
    mascotas    = 'Tienda de mascotas',
    telefonos   = 'Tienda de telefonos',
    trabajos    = 'Trabajo',
    gasolineras = 'Gasolinera',
    emergencias = 'Emergencias',
    locales     = 'Local',
    misiones    = 'Mision',
    avisos      = 'Aviso',
    referencias = 'Unidad',
    eventos     = 'Evento',
}
