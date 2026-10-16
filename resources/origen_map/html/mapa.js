/*  origen_map — el minimapa de Leaflet.

    Tres ideas y ya:

    1. Leaflet se mueve LO MENOS POSIBLE. Llamar a setView por fotograma le
       hace rehacer la cuenta de las teselas 60 veces por segundo, y eso es
       justo lo que hunde los fps. En vez de eso el mapa se ancla en un punto y
       solo se recoloca cuando te alejas del ancla; entre medias, el
       movimiento suave lo hace un translate de CSS, que es una capa y no toca
       el DOM.

    2. El giro es CSS. Leaflet no sabe girar. Se gira el contenedor entero y el
       lienzo se hace mas grande que la caja para que al girar las esquinas
       sigan viendo mapa.

    3. Lo que llega del juego se interpola. El cliente manda 15 posiciones por
       segundo; pintar solo esas se veria a saltos. Se guarda de donde vienes y
       a donde vas y se pinta lo de en medio en cada fotograma.  */

(function () {
    'use strict';

    /*  La misma transformacion que el mapa del menu de pausa. Si un dia se
        recalibra alli, hay que tocarla aqui: son las mismas cuatro cifras.  */
    const CENTRO_X = 117.3;
    const CENTRO_Y = 172.8;
    const ESCALA_X = 0.02072;
    const ESCALA_Y = 0.0205;

    /*  Las teselas, del disco de este recurso y no de gtamap.xyz (17/09). Esa
        web es un Apache de un particular sin CDN: a quien se le caia, le iba
        lenta o se la bloqueaba el antivirus o el proveedor (los .xyz se
        bloquean mucho) le salia el mapa en negro con los puntos encima. Son
        las mismas 2730 imagenes (atlas y satelite, zoom 0-5) bajadas una a una,
        y las usan todos los mapas del servidor. */
    const TESELAS = 'https://cfx-nui-origen_map/html/teselas/styleAtlas/{z}/{x}/{y}.jpg';

    /*  Cuanto te puedes alejar del ancla (en pixeles de pantalla) antes de
        mover a Leaflet de verdad. Cuanto mas alto, menos trabajo hace Leaflet;
        demasiado alto y el lienzo se queda corto por un lado al girar.  */
    const SALTO_ANCLA = 60;

    /*  Los tres zooms. No son numeros redondos porque lo que importa es
        cuantos METROS entran en la caja: 4,0 son ~460 m de ancho, 4,4 unos 340
        y 4,8 unos 250.  */
    const ZOOMS = { lejos: 4.0, normal: 4.4, cerca: 4.8 };
    let ZOOM = ZOOMS.normal;

    /*  El tamaño de la caja, como multiplicador de la medida que tiene el
        marco de origen_hud. No se toca el ancho y el alto por separado: la
        proporcion es la del marco y cambiarla dejaria el mapa fuera de el.  */
    /*  Seis medidas (14/09): con cuatro, la mas pequeña (0,8) seguia siendo
        mucha caja en un monitor de 1080, sobre todo la redonda.  */
    const TAMANOS = { mini: 0.6, pequeno: 0.72, mediano: 0.86, normal: 1, grande: 1.22, enorme: 1.45 };

    /*  Un color por categoria: en un minimapa no da tiempo a leer el dibujo,
        lo que distingue una marca de otra de un vistazo es el color. El dibujo
        esta para cuando ya has mirado.

        La misma paleta que el mapa de Ciudad del inventario, para que una
        gasolinera sea del mismo color en los dos sitios.  */
    const COLORES = {
        garages:    '#3b9dff',   // azul
        banking:    '#f0c33c',   // ambar
        shops:      '#d1218e',   // magenta
        public:     '#8fa3b8',   // gris azulado
        housing:    '#a97bff',   // violeta
        illegal:    '#ff8a2b',   // naranja
        racing:     '#2ee6a8',   // verde
        activities: '#5ad2e8',   // cian
        mascotas:   '#ffb3c7',   // rosa palo
        telefonos:  '#b9f36b',   // verde lima: no se parece a ninguno de arriba

        /*  Las categorias que aparecieron al pasar del rastreo de sprites al
            registro de puntos. Antes no existian: un trabajo o una gasolinera
            se colaban dentro de "Servicios" porque lo unico que se sabia de
            ellos era el numero de su blip.  */
        trabajos:    '#ffd166',  // amarillo de chaleco
        gasolineras: '#7ee081',  // verde de surtidor
        emergencias: '#ff6b6b',  // rojo suave, distinto del de aviso
        locales:     '#c8a0ff',  // lila
        misiones:    '#ffffff',  // blanco: un sitio de mision destaca sin color
        eventos:     '#ffe066',  // amarillo claro

        /*  Lo de origen_police. Dos colores que no se parecen a ninguno de
            arriba a proposito: en un mapa lleno de chinchetas, un aviso tiene
            que cantar a la primera y una unidad tiene que distinguirse del
            aviso al que va.

            Van los dos nombres —singular y plural— porque el minimapa los
            llamaba de una forma y el mapa grande de otra, y ahora los dos
            leen del mismo registro.  */
        aviso:       '#ff3355',  // rojo de sirena
        avisos:      '#ff3355',
        referencia:  '#2f6bff',  // azul de unidad
        referencias: '#2f6bff',
    };

    /*  Cuales van a la capa que el ajuste de iconos no apaga.  */
    const esDePolicia = (cat) => cat === 'aviso' || cat === 'avisos'
        || cat === 'referencia' || cat === 'referencias';

    /*  Siluetas rellenas y no contornos: a 9 px una linea de menos de un pixel
        no se ve. Son los mismos dibujos que el mapa del menu de pausa.  */
    const DIBUJOS = {
        coche: '<path d="M3 13.4l1.5-4.6A2.3 2.3 0 0 1 6.7 7.2h6.6a2.3 2.3 0 0 1 2.2 1.6l1.5 4.6v2.5a.9.9 0 0 1-.9.9h-1.2a.9.9 0 0 1-.9-.9v-.6H5.9v.6a.9.9 0 0 1-.9.9H3.8a.9.9 0 0 1-.9-.9z"/>',
        dinero: '<path fill-rule="evenodd" d="M2.4 5.2h15.2a1 1 0 0 1 1 1v7.6a1 1 0 0 1-1 1H2.4a1 1 0 0 1-1-1V6.2a1 1 0 0 1 1-1zm7.6 2.4a2.4 2.4 0 1 0 0 4.8 2.4 2.4 0 0 0 0-4.8z"/>',
        cesta: '<path fill-rule="evenodd" d="M5.4 6.4v-.7a4.6 4.6 0 0 1 9.2 0v.7h2.2l-1 9.5a1.4 1.4 0 0 1-1.4 1.3H5.6a1.4 1.4 0 0 1-1.4-1.3l-1-9.5zm2.2 0h4.8v-.7a2.4 2.4 0 0 0-4.8 0z"/>',
        edificio: '<path fill-rule="evenodd" d="M3.6 2.8h12.8v14.4H3.6zM6 5.4h2.4v2.4H6zm5.6 0H14v2.4h-2.4zM6 9.8h2.4v2.4H6zm5.6 0H14v2.4h-2.4zM8.6 14.2h2.8v3H8.6z"/>',
        casa: '<path fill-rule="evenodd" d="M10 2.2 18.8 9.1h-2.6v8.2H3.8V9.1H1.2zM8.7 12h2.6v5.3H8.7z"/>',
        /*  Viviendas: la casa en venta lleva su cartel y el hotel una cama. La casa
            TUYA y el hotel donde TIENES habitacion usan estos mismos dibujos pero
            en rosa (lo pone origen_housing): asi se ve de un vistazo que es tuyo. */
        casa_venta: '<path fill-rule="evenodd" d="M8 2.6 15 8.1h-2.1v2.5H9.6a1.4 1.4 0 0 0-1.4 1.4v5H3V8.1H1zM6.9 12.3h2.2v4.7H6.9z"/><path fill-rule="evenodd" d="M11 11.6h7a1 1 0 0 1 1 1v3.8a1 1 0 0 1-1 1h-7a1 1 0 0 1-1-1v-3.8a1 1 0 0 1 1-1zm1.6 1.9v1.6h3.8v-1.6z"/><path d="M13.9 9.2h1.2v2.4h-1.2z"/>',
        hotel: '<path d="M2.2 4.4a1 1 0 0 1 2 0v6h13.6a1 1 0 0 1 1 1v5.2a1 1 0 0 1-2 0v-1.8H4.2v1.8a1 1 0 0 1-2 0z"/><circle cx="7.1" cy="7.7" r="1.95"/><path d="M10 5.9h5.6a2.2 2.2 0 0 1 2.2 2.2v1.5H10z"/>',
        calavera: '<path fill-rule="evenodd" d="M10 2.2a6.6 6.6 0 0 0-4.2 11.7v2.2a1.4 1.4 0 0 0 1.4 1.4h5.6a1.4 1.4 0 0 0 1.4-1.4v-2.2A6.6 6.6 0 0 0 10 2.2zM7.5 8a1.7 1.7 0 1 1 0 3.4A1.7 1.7 0 0 1 7.5 8zm5 0a1.7 1.7 0 1 1 0 3.4A1.7 1.7 0 0 1 12.5 8z"/>',
        bandera: '<path d="M4.3 2.3a1 1 0 0 1 1 1v14.4a1 1 0 1 1-2 0V3.3a1 1 0 0 1 1-1z"/><path d="M6.6 3.5h9.2a.7.7 0 0 1 .58 1.1L14.5 7.3l1.88 2.7a.7.7 0 0 1-.58 1.1H6.6z"/>',
        ocio: '<path d="M3.2 3.2h13.6a.7.7 0 0 1 .53 1.16L10.9 11.5v4.1h2.7a.9.9 0 1 1 0 1.8H6.4a.9.9 0 1 1 0-1.8h2.7v-4.1L2.67 4.36A.7.7 0 0 1 3.2 3.2z"/>',
        huella: '<path d="M10 11.4c2.5 0 4.6 1.7 4.6 3.9 0 1.6-1.3 2.5-2.9 2.5-.7 0-1.2-.15-1.7-.15s-1 .15-1.7.15c-1.6 0-2.9-.9-2.9-2.5 0-2.2 2.1-3.9 4.6-3.9z"/><ellipse cx="5.6" cy="8.4" rx="1.7" ry="2.2"/><ellipse cx="14.4" cy="8.4" rx="1.7" ry="2.2"/><ellipse cx="8.4" cy="4.4" rx="1.6" ry="2.1"/><ellipse cx="11.6" cy="4.4" rx="1.6" ry="2.1"/>',
        // El establo de origen_pets: cabeza de caballo.
        caballo: '<path fill-rule="evenodd" d="M12.4 2.3l1.3 2.1c2.3 1 3.7 3.4 3.7 6.2v7.2a.9.9 0 0 1-.9.9H9.6a.9.9 0 0 1-.8-1.3l1.6-3.1c-.9-.2-1.8-.7-2.5-1.4l-2.2 1.2a1.7 1.7 0 0 1-2.2-.5l-.9-1.3a1.7 1.7 0 0 1 .3-2.2l4.6-4.4c.6-.6 1.4-1 2.2-1.1zM11.2 7.1a.8.8 0 1 0 0 1.6.8.8 0 0 0 0-1.6z"/>',
        movil: '<path fill-rule="evenodd" d="M6.4 1.8h7.2a1.9 1.9 0 0 1 1.9 1.9v12.6a1.9 1.9 0 0 1-1.9 1.9H6.4a1.9 1.9 0 0 1-1.9-1.9V3.7a1.9 1.9 0 0 1 1.9-1.9zm1.5 1.9a.55.55 0 0 0 0 1.1h4.2a.55.55 0 0 0 0-1.1zM10 14.3a1.15 1.15 0 1 0 0 2.3 1.15 1.15 0 0 0 0-2.3z"/>',
        chincheta: '<path fill-rule="evenodd" d="M10 1.6A6.4 6.4 0 0 0 3.6 8c0 4.6 5.5 9.9 5.73 10.12a.96.96 0 0 0 1.34 0C10.9 17.9 16.4 12.6 16.4 8A6.4 6.4 0 0 0 10 1.6zm0 4.1a2.3 2.3 0 1 1 0 4.6 2.3 2.3 0 0 1 0-4.6z"/>',
        local: '<path d="M3.4 3h13.2l1.55 4.15a.7.7 0 0 1-.65.95H2.5a.7.7 0 0 1-.65-.95z"/><path fill-rule="evenodd" d="M3.7 9.6h12.6v7.6H3.7zm2.5 1.9v3.4h3.4v-3.4z"/>',
        estrella: '<path d="M10 1.8l2.45 5.1 5.45.73-3.98 3.83 1.02 5.44L10 14.27l-4.94 2.63 1.02-5.44L2.1 7.63l5.45-.73z"/>',
        /*  Los dos de origen_police: una sirena para el aviso y un escudo para
            la unidad. Siluetas rellenas, como el resto.  */
        sirena: '<path d="M10 2.2a4.4 4.4 0 0 0-4.4 4.4v4.2h8.8V6.6A4.4 4.4 0 0 0 10 2.2z"/><path d="M3.6 12.4h12.8a1 1 0 0 1 1 1v2.2a1 1 0 0 1-1 1H3.6a1 1 0 0 1-1-1v-2.2a1 1 0 0 1 1-1z"/>',
        escudo: '<path fill-rule="evenodd" d="M10 1.8l6.6 2.6v5.2c0 4-2.8 7.3-6.6 8.6-3.8-1.3-6.6-4.6-6.6-8.6V4.4zm0 3.6a2 2 0 1 0 0 4 2 2 0 0 0 0-4z"/>',
        compartido: '<path d="M7.5 9.7a3.15 3.15 0 1 0 0-6.3 3.15 3.15 0 0 0 0 6.3z"/><path d="M7.5 11a5.9 5.9 0 0 0-5.65 4.2.92.92 0 0 0 .88 1.2h9.54a.92.92 0 0 0 .88-1.2A5.9 5.9 0 0 0 7.5 11z"/><path d="M14.4 9.3a2.6 2.6 0 1 0 0-5.2 2.6 2.6 0 0 0 0 5.2z"/><path d="M14.4 10.5c-.52 0-1.02.07-1.5.2a7.6 7.6 0 0 1 1.94 3.4c.1.4.11.8.05 1.17h3.1a.9.9 0 0 0 .87-1.16 4.65 4.65 0 0 0-4.46-3.61z"/>',

        /*  Los que hicieron falta al pasar del rastreo de sprites al registro.
            Son los mismos dibujos que el mapa del menu de pausa: si aqui se
            cambia uno, hay que cambiarlo alli tambien.  */
        persona: '<path d="M10 3.2a3.4 3.4 0 1 0 0 6.8 3.4 3.4 0 0 0 0-6.8z"/><path d="M10 11.2a6.4 6.4 0 0 0-6.2 4.75.95.95 0 0 0 .92 1.25h10.56a.95.95 0 0 0 .92-1.25A6.4 6.4 0 0 0 10 11.2z"/>',
        maletin: '<path fill-rule="evenodd" d="M8 2.6h4a1.8 1.8 0 0 1 1.8 1.8v.9h2.7a1.5 1.5 0 0 1 1.5 1.5v8.1a1.5 1.5 0 0 1-1.5 1.5H3.5A1.5 1.5 0 0 1 2 14.9V6.8a1.5 1.5 0 0 1 1.5-1.5h2.7v-.9A1.8 1.8 0 0 1 8 2.6zm0 2.7h4v-.9H8z"/>',
        gasolina: '<path fill-rule="evenodd" d="M3 3.6A1.6 1.6 0 0 1 4.6 2h5A1.6 1.6 0 0 1 11.2 3.6V17.4H3zm1.9 1.1v3.1h4.4V4.7z"/><path d="M12.4 5.9l1.5 1.5a1.6 1.6 0 0 1 .47 1.13v4.36a.92.92 0 0 0 1.84 0V8.06a3 3 0 0 0-.88-2.12l-2.2-2.2-1.06 1.07 1.07 1.06a.55.55 0 1 1-.74.03z"/>',
        cruz: '<path d="M8.1 2.4h3.8v5.7h5.7v3.8h-5.7v5.7H8.1v-5.7H2.4V8.1h5.7z"/>',
        /*  Ocio: que cada actividad tenga su dibujo. Con la copa para todas no se
            distinguia el tenis del golf. `copa` es el mismo trazo que `ocio`: la
            categoria se sigue llamando asi, y un bar pide la copa por su nombre. */
        tenis: '<path fill-rule="evenodd" d="M16.02 3.98A5.4 4.5 -45 1 0 8.38 11.62A5.4 4.5 -45 1 0 16.02 3.98zM14.67 5.33A3.5 2.6 -45 1 0 9.73 10.27A3.5 2.6 -45 1 0 14.67 5.33z"/><path d="M10.08 10.62L15.02 5.68A.5 .5 0 0 0 14.32 4.98L9.38 9.92A.5 .5 0 0 0 10.08 10.62z"/><path d="M10.01 6.31L13.69 9.99A.5 .5 0 0 0 14.39 9.29L10.71 5.61A.5 .5 0 0 0 10.01 6.31z"/><path d="M7.59 10.79L2.49 15.89A1.15 1.15 0 0 0 4.11 17.51L9.21 12.41A1.15 1.15 0 0 0 7.59 10.79z"/><path d="M2.1 4.4A2.3 2.3 0 0 1 6.7 4.4A2.3 2.3 0 0 1 2.1 4.4z"/>',
        baloncesto: '<path d="M4.1 4.74A7.9 7.9 0 0 0 2.12 9.4L5.78 9.4A9 9 0 0 0 4.1 4.74zM15.9 4.74A7.9 7.9 0 0 1 17.88 9.4L14.22 9.4A9 9 0 0 1 15.9 4.74zM4.1 15.26A7.9 7.9 0 0 1 2.12 10.6L5.78 10.6A9 9 0 0 1 4.1 15.26zM15.9 15.26A7.9 7.9 0 0 0 17.88 10.6L14.22 10.6A9 9 0 0 0 15.9 15.26zM4.98 3.9A7.9 7.9 0 0 1 9.4 2.12L9.4 9.4L6.98 9.4A10.2 10.2 0 0 0 4.98 3.9zM15.02 3.9A7.9 7.9 0 0 0 10.6 2.12L10.6 9.4L13.02 9.4A10.2 10.2 0 0 1 15.02 3.9zM4.98 16.1A7.9 7.9 0 0 0 9.4 17.88L9.4 10.6L6.98 10.6A10.2 10.2 0 0 1 4.98 16.1zM15.02 16.1A7.9 7.9 0 0 1 10.6 17.88L10.6 10.6L13.02 10.6A10.2 10.2 0 0 0 15.02 16.1z"/>',
        golf: '<path d="M6.25 3L6.25 15.2A.95 .95 0 0 0 8.15 15.2L8.15 3A.95 .95 0 0 0 6.25 3z"/><path d="M8.1 2.2L15.8 5.3L8.1 8.4z"/><path d="M2.2 16.3C2.2 15.2 4.6 14.5 7.2 14.5C9.8 14.5 12.2 15.2 12.2 16.3C12.2 17.4 9.8 18.1 7.2 18.1C4.6 18.1 2.2 17.4 2.2 16.3z"/><path d="M13 13.4A2.4 2.4 0 0 1 17.8 13.4A2.4 2.4 0 0 1 13 13.4z"/>',
        bolos: '<path d="M6 1.8C7.2 1.8 8.1 2.8 8.1 4C8.1 5.2 7.1 6 7 7.1C8.2 8.5 9 10.4 9 12.4C9 14.3 8.4 16.2 7.8 17.8L4.2 17.8C3.6 16.2 3 14.3 3 12.4C3 10.4 3.8 8.5 5 7.1C4.9 6 3.9 5.2 3.9 4C3.9 2.8 4.8 1.8 6 1.8z"/><path fill-rule="evenodd" d="M10 13.4A4.2 4.2 0 0 1 18.4 13.4A4.2 4.2 0 0 1 10 13.4zM12.25 11.6A.85 .85 0 0 1 13.95 11.6A.85 .85 0 0 1 12.25 11.6zM14.55 11.3A.85 .85 0 0 1 16.25 11.3A.85 .85 0 0 1 14.55 11.3z"/>',
        caza: '<path d="M7.1 9.4L12.9 9.4C13.1 12 12.1 14.6 11.3 16.7A1.35 1.35 0 0 1 8.7 16.7C7.9 14.6 6.9 12 7.1 9.4z"/><path d="M7.4 10.2C6.2 9.2 4.2 9.1 2.8 10C3.8 11.6 5.8 12.2 7.3 11.6z"/><path d="M12.6 10.2C13.8 9.2 15.8 9.1 17.2 10C16.2 11.6 14.2 12.2 12.7 11.6z"/><path d="M9.38 9.27L6.38 2.27A.85 .85 0 0 0 4.82 2.93L7.82 9.93A.85 .85 0 0 0 9.38 9.27z"/><path d="M7.04 4.64L3.24 3.44A.8 .8 0 0 0 2.76 4.96L6.56 6.16A.8 .8 0 0 0 7.04 4.64z"/><path d="M6.88 4.78L8.88 2.38A.75 .75 0 0 0 7.72 1.42L5.72 3.82A.75 .75 0 0 0 6.88 4.78z"/><path d="M10.62 9.27L13.62 2.27A.85 .85 0 0 1 15.18 2.93L12.18 9.93A.85 .85 0 0 1 10.62 9.27z"/><path d="M12.96 4.64L16.76 3.44A.8 .8 0 0 1 17.24 4.96L13.44 6.16A.8 .8 0 0 1 12.96 4.64z"/><path d="M13.12 4.78L11.12 2.38A.75 .75 0 0 1 12.28 1.42L14.28 3.82A.75 .75 0 0 1 13.12 4.78z"/>',
        pesca: '<path fill-rule="evenodd" d="M18.2 10C16.4 6.5 13.7 5 10.9 5C8.4 5 6.4 6.5 5.2 8.1L2 5.4L2.9 10L2 14.6L5.2 11.9C6.4 13.5 8.4 15 10.9 15C13.7 15 16.4 13.5 18.2 10zM13.25 9A1.05 1.05 0 0 1 15.35 9A1.05 1.05 0 0 1 13.25 9z"/>',
        /*  Origen Games: cada juego con su dibujo (el derbi usa `coche` y el paintball `paintball`). */
        cono: '<path d="M8.5 2.2h3l1.05 3.9h-5.1zM7.05 7.6h5.9l1.1 4.1H5.95zM5.5 13.2h9l.95 3.3H4.55z"/><path d="M2.4 17.1h15.2a.8.8 0 0 1 0 1.6H2.4a.8.8 0 0 1 0-1.6z"/>',
        patata: '<path fill-rule="evenodd" d="M6.6 3.5c3-2.3 8.1-1.9 10.1 1.5 2.1 3.5 1.2 8.7-1.8 11-3 2.4-8.3 2.1-10.1-1.1C3.1 11.8 3.7 5.7 6.6 3.5zM6.8 8.2a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0zM11.2 6.6a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0zM10.6 12a1.1 1.1 0 1 0 2.2 0a1.1 1.1 0 1 0-2.2 0z"/>',
        corona: '<path d="M2.2 5.6l4.3 3.9L10 2.9l3.5 6.6 4.3-3.9-1.7 9.5H3.9z"/><path d="M3.9 16.5h12.2v1.9H3.9z"/>',
        mascara: '<path fill-rule="evenodd" d="M1.8 6.2C4.4 5 7.2 4.8 10 6c2.8-1.2 5.6-1 8.2.2.3 4.4-1.4 7.8-4.6 8.2-1.6.2-2.6-.9-3.6-2.2-1 1.3-2 2.4-3.6 2.2-3.2-.4-4.9-3.8-4.6-8.2zM4.5 9.1a2.1 1.35 0 1 0 4.2 0a2.1 1.35 0 1 0-4.2 0zM11.3 9.1a2.1 1.35 0 1 0 4.2 0a2.1 1.35 0 1 0-4.2 0z"/>',
        paintball: '<path fill-rule="evenodd" d="M2 10A8 8 0 0 1 18 10A8 8 0 0 1 2 10zM4.4 10A5.6 5.6 0 0 1 15.6 10A5.6 5.6 0 0 1 4.4 10zM6.8 10A3.2 3.2 0 0 1 13.2 10A3.2 3.2 0 0 1 6.8 10z"/>',
        casino: '<path fill-rule="evenodd" d="M5.4 2.4L14.6 2.4A3 3 0 0 1 17.6 5.4L17.6 14.6A3 3 0 0 1 14.6 17.6L5.4 17.6A3 3 0 0 1 2.4 14.6L2.4 5.4A3 3 0 0 1 5.4 2.4zM4.95 6.5A1.55 1.55 0 0 1 8.05 6.5A1.55 1.55 0 0 1 4.95 6.5zM11.95 6.5A1.55 1.55 0 0 1 15.05 6.5A1.55 1.55 0 0 1 11.95 6.5zM8.45 10A1.55 1.55 0 0 1 11.55 10A1.55 1.55 0 0 1 8.45 10zM4.95 13.5A1.55 1.55 0 0 1 8.05 13.5A1.55 1.55 0 0 1 4.95 13.5zM11.95 13.5A1.55 1.55 0 0 1 15.05 13.5A1.55 1.55 0 0 1 11.95 13.5z"/>',
        gimnasio: '<path d="M5.1 4.6L6.1 4.6A1 1 0 0 1 7.1 5.6L7.1 14.4A1 1 0 0 1 6.1 15.4L5.1 15.4A1 1 0 0 1 4.1 14.4L4.1 5.6A1 1 0 0 1 5.1 4.6z"/><path d="M14.9 4.6L13.9 4.6A1 1 0 0 0 12.9 5.6L12.9 14.4A1 1 0 0 0 13.9 15.4L14.9 15.4A1 1 0 0 0 15.9 14.4L15.9 5.6A1 1 0 0 0 14.9 4.6z"/><path d="M2.5 7L4 7A.9 .9 0 0 1 4.9 7.9L4.9 12.1A.9 .9 0 0 1 4 13L2.5 13A.9 .9 0 0 1 1.6 12.1L1.6 7.9A.9 .9 0 0 1 2.5 7z"/><path d="M17.5 7L16 7A.9 .9 0 0 0 15.1 7.9L15.1 12.1A.9 .9 0 0 0 16 13L17.5 13A.9 .9 0 0 0 18.4 12.1L18.4 7.9A.9 .9 0 0 0 17.5 7z"/><path d="M6.5 8.8L13.5 8.8L13.5 11.2L6.5 11.2z"/>',
        tatuaje: '<path d="M17.07 2.65L17.35 2.93A2.2 2.2 0 0 1 17.35 6.04L14.24 9.15A2.2 2.2 0 0 1 11.13 9.15L10.85 8.87A2.2 2.2 0 0 1 10.85 5.76L13.96 2.65A2.2 2.2 0 0 1 17.07 2.65z"/><path d="M10.35 7.81L12.19 9.65L8.94 12.05L7.95 11.06z"/><path d="M8.27 11.1L8.9 11.73L6.61 13.39z"/><path d="M4.4 12.6C4.4 12.6 6.6 15.1 6.6 16.2A2.2 2.2 0 0 1 2.2 16.2C2.2 15.1 4.4 12.6 4.4 12.6z"/>',
        juego: '<path fill-rule="evenodd" d="M6.2 5.2L13.8 5.2C16.2 5.2 17.4 7 17.9 9.6L18.3 12.6C18.6 14.8 17 16 15.4 15.2C14.4 14.7 13.7 13.4 12.7 13.1L7.3 13.1C6.3 13.4 5.6 14.7 4.6 15.2C3 16 1.4 14.8 1.7 12.6L2.1 9.6C2.6 7 3.8 5.2 6.2 5.2zM5.6 7.2L6.8 7.2L6.8 8.6L8.2 8.6L8.2 9.8L6.8 9.8L6.8 11.2L5.6 11.2L5.6 9.8L4.2 9.8L4.2 8.6L5.6 8.6zM11.9 10.1A1 1 0 0 1 13.9 10.1A1 1 0 0 1 11.9 10.1zM13.9 8.1A1 1 0 0 1 15.9 8.1A1 1 0 0 1 13.9 8.1z"/>',
        copa: '<path d="M3.2 3.2h13.6a.7.7 0 0 1 .53 1.16L10.9 11.5v4.1h2.7a.9.9 0 1 1 0 1.8H6.4a.9.9 0 1 1 0-1.8h2.7v-4.1L2.67 4.36A.7.7 0 0 1 3.2 3.2z"/>',
        /*  Trabajos: el maletin dice "aqui se trabaja", no de que. El taxi es el
            coche de siempre con el cartel encima, para que no se confunda con un garaje. */
        autobus: '<path fill-rule="evenodd" d="M5.6 2L14.4 2A2.2 2.2 0 0 1 16.6 4.2L16.6 13.2A2.2 2.2 0 0 1 14.4 15.4L5.6 15.4A2.2 2.2 0 0 1 3.4 13.2L3.4 4.2A2.2 2.2 0 0 1 5.6 2zM6 4L14 4A.8 .8 0 0 1 14.8 4.8L14.8 8.6A.8 .8 0 0 1 14 9.4L6 9.4A.8 .8 0 0 1 5.2 8.6L5.2 4.8A.8 .8 0 0 1 6 4zM5.55 12.5A1.05 1.05 0 0 1 7.65 12.5A1.05 1.05 0 0 1 5.55 12.5zM12.35 12.5A1.05 1.05 0 0 1 14.45 12.5A1.05 1.05 0 0 1 12.35 12.5z"/><path d="M5.2 14.4L6.6 14.4A.8 .8 0 0 1 7.4 15.2L7.4 17.2A.8 .8 0 0 1 6.6 18L5.2 18A.8 .8 0 0 1 4.4 17.2L4.4 15.2A.8 .8 0 0 1 5.2 14.4z"/><path d="M13.4 14.4L14.8 14.4A.8 .8 0 0 1 15.6 15.2L15.6 17.2A.8 .8 0 0 1 14.8 18L13.4 18A.8 .8 0 0 1 12.6 17.2L12.6 15.2A.8 .8 0 0 1 13.4 14.4z"/>',
        avion: '<path d="M10 1.4c.62 0 1.12.5 1.12 1.12V7.1l6.28 3.6v1.6l-6.28-1.86v3.9l1.9 1.35v1.42L10 15.98l-3.02 1.03v-1.42l1.9-1.35v-3.9L2.6 12.3v-1.6l6.28-3.6V2.52c0-.62.5-1.12 1.12-1.12z"/>',
        taxi: '<path d="M3 14.4l1.5-4.6A2.3 2.3 0 0 1 6.7 8.2h6.6a2.3 2.3 0 0 1 2.2 1.6l1.5 4.6v2.5a.9.9 0 0 1-.9.9h-1.2a.9.9 0 0 1-.9-.9v-.6H5.9v.6a.9.9 0 0 1-.9.9H3.8a.9.9 0 0 1-.9-.9z"/><path d="M7.8 2.4L12.2 2.4A.8 .8 0 0 1 13 3.2L13 5.4A.8 .8 0 0 1 12.2 6.2L7.8 6.2A.8 .8 0 0 1 7 5.4L7 3.2A.8 .8 0 0 1 7.8 2.4z"/>',
        camion: '<path d="M2.4 3.4L10.8 3.4A.8 .8 0 0 1 11.6 4.2L11.6 12.4A.8 .8 0 0 1 10.8 13.2L2.4 13.2A.8 .8 0 0 1 1.6 12.4L1.6 4.2A.8 .8 0 0 1 2.4 3.4z"/><path fill-rule="evenodd" d="M12.6 6.2L15.4 6.2C15.9 6.2 16.3 6.4 16.6 6.8L18.1 9.2C18.3 9.5 18.4 9.8 18.4 10.2L18.4 13.2L12.6 13.2zM13.8 7.4L15.2 7.4L16.6 9.8L13.8 9.8z"/><path d="M2.9 15.4A2.3 2.3 0 0 1 7.5 15.4A2.3 2.3 0 0 1 2.9 15.4z"/><path d="M12.5 15.4A2.3 2.3 0 0 1 17.1 15.4A2.3 2.3 0 0 1 12.5 15.4z"/>',
        arbol: '<path d="M10 1.6L14.6 7.4L12.6 7.4L16.6 11.8L14.4 11.8L17.8 15.4L11.3 15.4L11.3 18.4L8.7 18.4L8.7 15.4L2.2 15.4L5.6 11.8L3.4 11.8L7.4 7.4L5.4 7.4z"/>',
        /*  La granja (origen_farming): el tractor para la cooperativa y el brote para las parcelas.  */
        tractor: '<path fill-rule="evenodd" d="M3.4 2.6h5.4a.8.8 0 0 1 .8.8v5.8H3.4zM4.8 4h3.4v3.4H4.8z"/><path d="M9.6 7.6h6.8a1 1 0 0 1 1 1v3.4H9.6zM12.6 4.2h1.2v3.4h-1.2z"/><path fill-rule="evenodd" d="M1.8 13.8a4.2 4.2 0 1 0 8.4 0a4.2 4.2 0 1 0-8.4 0zM4.5 13.8a1.5 1.5 0 1 0 3 0a1.5 1.5 0 1 0-3 0z"/><path fill-rule="evenodd" d="M12.8 15.4a2.6 2.6 0 1 0 5.2 0a2.6 2.6 0 1 0-5.2 0zM14.5 15.4a.9.9 0 1 0 1.8 0a.9.9 0 1 0-1.8 0z"/>',
        brote: '<path d="M9.2 8.5h1.6v6.3H9.2z"/><path d="M9.6 9.4C6.9 9.8 3.4 8.6 2.6 4.4c3.9-.6 6.9 1.2 7 5z"/><path d="M10.4 7.6c.2-3.4 2.8-5.6 7-5.2-.4 4.1-3.4 5.8-7 5.2z"/><path d="M2.4 16.2c1.6-1.6 4.6-2.2 7.6-2.2s6 .6 7.6 2.2a.9.9 0 0 1-.64 1.54H3.04a.9.9 0 0 1-.64-1.54z"/>',
        pico: '<path d="M12.97 5.33L3.35 14.95A1.2 1.2 0 0 0 5.05 16.65L14.67 7.03A1.2 1.2 0 0 0 12.97 5.33z"/><path d="M4.77 3.35C12.69 -.89 20.89 7.31 16.65 15.23C16.51 10 10 3.49 4.77 3.35z"/>',
        pollo: '<path d="M2.6 4.2C2 7.5 2.2 10.6 3.4 12.6C4.8 15 7.4 15.8 10 15.8C13.4 15.8 16 13.8 16 10.6C16 9 15.2 7.6 14.4 6.8L11.8 6.4C11.2 8.6 9.4 9.2 7.6 8.6C6 8.1 4.6 5.8 2.6 4.2z"/><path fill-rule="evenodd" d="M11.2 5.4A2.4 2.4 0 0 1 16 5.4A2.4 2.4 0 0 1 11.2 5.4zM13.5 5A.7 .7 0 0 1 14.9 5A.7 .7 0 0 1 13.5 5z"/><path d="M10.95 3.5A.95 .95 0 0 1 12.85 3.5A.95 .95 0 0 1 10.95 3.5z"/><path d="M12.4 2.6A1 1 0 0 1 14.4 2.6A1 1 0 0 1 12.4 2.6z"/><path d="M14 3.2A.9 .9 0 0 1 15.8 3.2A.9 .9 0 0 1 14 3.2z"/><path d="M15.6 4.5L18.2 5.6L15.6 6.6z"/><path d="M14.65 7.8A.85 .85 0 0 1 16.35 7.8A.85 .85 0 0 1 14.65 7.8z"/><path d="M7.65 15L7.65 17.9A.65 .65 0 0 0 8.95 17.9L8.95 15A.65 .65 0 0 0 7.65 15z"/><path d="M10.85 15L10.85 17.9A.65 .65 0 0 0 12.15 17.9L12.15 15A.65 .65 0 0 0 10.85 15z"/>',
        /*  Los del rancho de origen_farming (21/09): cada corral con su animal
            y cada entrega con lo que se entrega. Antes los cinco corrales
            pedian 'parcela', que no existe, y salian todos con el edificio.  */
        vaca: '<path d="M5.6 4.6C4.2 4.2 3.4 2.8 3.6 1.4C4.4 2.5 5.6 2.9 6.9 3.1z"/><path d="M14.4 4.6C15.8 4.2 16.6 2.8 16.4 1.4C15.6 2.5 14.4 2.9 13.1 3.1z"/><ellipse cx="3.5" cy="7.1" rx="2.5" ry="1.25" transform="rotate(-18 3.5 7.1)"/><ellipse cx="16.5" cy="7.1" rx="2.5" ry="1.25" transform="rotate(18 16.5 7.1)"/><path d="M5.9 4.9Q10 2.6 14.1 4.9L13.5 11.6H6.5z"/><path fill-rule="evenodd" d="M10 10.1c3 0 4.7 1.6 4.7 3.7S13 17.7 10 17.7s-4.7-1.8-4.7-3.9 1.7-3.7 4.7-3.7zM7.9 12.9a.95 .95 0 1 0 0 1.9.95 .95 0 0 0 0-1.9zm4.2 0a.95 .95 0 1 0 0 1.9.95 .95 0 0 0 0-1.9z"/>',
        cerdo: '<path d="M3.6 2.8L8.4 5.2L4.4 8.4z"/><path d="M16.4 2.8L11.6 5.2L15.6 8.4z"/><path fill-rule="evenodd" d="M3 11a7 7 0 1 0 14 0a7 7 0 1 0-14 0zM6.4 12.7a3.6 2.5 0 1 0 7.2 0a3.6 2.5 0 1 0-7.2 0zM7.2 12.7a2.8 1.75 0 1 0 5.6 0a2.8 1.75 0 1 0-5.6 0zM8.3 12.7a.55 .9 0 1 0 1.1 0a.55 .9 0 1 0-1.1 0zM10.6 12.7a.55 .9 0 1 0 1.1 0a.55 .9 0 1 0-1.1 0zM6.8 8.5a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0zM11.4 8.5a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0z"/>',
        conejo: '<ellipse cx="7.2" cy="5" rx="1.75" ry="4.3" transform="rotate(-11 7.2 5)"/><ellipse cx="12.8" cy="5" rx="1.75" ry="4.3" transform="rotate(11 12.8 5)"/><path fill-rule="evenodd" d="M4.3 13.3a5.7 5 0 1 0 11.4 0a5.7 5 0 1 0-11.4 0zM7.1 12.2a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0zM11.1 12.2a.9 .9 0 1 0 1.8 0a.9 .9 0 1 0-1.8 0zM9.2 14.5h1.6L10 15.5z"/>',
        leche: '<path d="M7 1.6h6a.6 .6 0 0 1 .6.6v1a.6 .6 0 0 1-.6.6H7a.6 .6 0 0 1-.6-.6v-1a.6 .6 0 0 1 .6-.6z"/><path fill-rule="evenodd" d="M7.6 4.4h4.8v2l2.2 2.3v8.3a1.4 1.4 0 0 1-1.4 1.4H6.8a1.4 1.4 0 0 1-1.4-1.4V8.7l2.2-2.3zM5.4 11h9.2v1.6H5.4z"/>',
        huevo: '<path d="M10 1.8c3.4 0 6 5 6 9.2 0 3.9-2.6 6.6-6 6.6s-6-2.7-6-6.6c0-4.2 2.6-9.2 6-9.2z"/>',
        basura: '<path d="M8.2 1.8L11.8 1.8A.6 .6 0 0 1 12.4 2.4L12.4 3.8A.6 .6 0 0 1 11.8 4.4L8.2 4.4A.6 .6 0 0 1 7.6 3.8L7.6 2.4A.6 .6 0 0 1 8.2 1.8z"/><path d="M3.6 3.6L16.4 3.6A.8 .8 0 0 1 17.2 4.4L17.2 5.4A.8 .8 0 0 1 16.4 6.2L3.6 6.2A.8 .8 0 0 1 2.8 5.4L2.8 4.4A.8 .8 0 0 1 3.6 3.6z"/><path fill-rule="evenodd" d="M4.2 7.4L15.8 7.4L14.8 17.2C14.75 17.8 14.3 18.2 13.7 18.2L6.3 18.2C5.7 18.2 5.25 17.8 5.2 17.2zM8 9.4L8 9.4A.7 .7 0 0 1 8.7 10.1L8.7 15.3A.7 .7 0 0 1 8 16L8 16A.7 .7 0 0 1 7.3 15.3L7.3 10.1A.7 .7 0 0 1 8 9.4zM12 9.4L12 9.4A.7 .7 0 0 1 12.7 10.1L12.7 15.3A.7 .7 0 0 1 12 16L12 16A.7 .7 0 0 1 11.3 15.3L11.3 10.1A.7 .7 0 0 1 12 9.4z"/>',
        paquete: '<path d="M10 1.6L17.6 5.5L10 9.4L2.4 5.5z"/><path d="M2.4 6.9L9.35 10.45L9.35 18.2L2.4 14.6z"/><path d="M17.6 6.9L10.65 10.45L10.65 18.2L17.6 14.6z"/>',
        /*  Vehiculos y servicios. El ayuntamiento lleva columnas para no confundirse
            con `edificio`, que es el de cualquier servicio. */
        parking: '<path fill-rule="evenodd" d="M5.2 2.2L14.8 2.2A3 3 0 0 1 17.8 5.2L17.8 14.8A3 3 0 0 1 14.8 17.8L5.2 17.8A3 3 0 0 1 2.2 14.8L2.2 5.2A3 3 0 0 1 5.2 2.2zM6.7 5L10.6 5A3.3 3.3 0 0 1 10.6 11.6L9.1 11.6L9.1 15L6.7 15zM9.1 7.2L10.5 7.2A1.1 1.1 0 0 1 10.5 9.4L9.1 9.4z"/>',
        llave: '<path fill-rule="evenodd" d="M3.85 16.15A4.3 4.3 0 0 1 9.93 10.07A4.3 4.3 0 0 1 3.85 16.15zM5.05 14.95A1.6 1.6 0 0 1 7.31 12.69A1.6 1.6 0 0 1 5.05 14.95z"/><path d="M8.44 9.86L15.09 3.21L16.79 4.91L16.22 5.47L17.92 7.17L16.65 8.44L14.95 6.75L14.24 7.45L15.37 8.59L14.1 9.86L12.97 8.73L10.14 11.56z"/>',
        taller: '<path d="M11.66 6.29L14.66 3.29A4.2 4.2 0 1 0 16.71 5.34L13.71 8.34z"/><path d="M10.35 7.53L3.71 14.17A1.5 1.5 0 0 0 5.83 16.29L12.47 9.65A1.5 1.5 0 0 0 10.35 7.53z"/>',
        rayo: '<path d="M12 1.6L4.2 11.4L9.2 11.4L8 18.4L15.8 8.4L10.8 8.4z"/>',
        ayuntamiento: '<path d="M10 1.8L18.2 5.9L18.2 7.3L1.8 7.3L1.8 5.9z"/><path d="M3.5 8.5L4.8 8.5A.3 .3 0 0 1 5.1 8.8L5.1 14.2A.3 .3 0 0 1 4.8 14.5L3.5 14.5A.3 .3 0 0 1 3.2 14.2L3.2 8.8A.3 .3 0 0 1 3.5 8.5z"/><path d="M7.4 8.5L8.7 8.5A.3 .3 0 0 1 9 8.8L9 14.2A.3 .3 0 0 1 8.7 14.5L7.4 14.5A.3 .3 0 0 1 7.1 14.2L7.1 8.8A.3 .3 0 0 1 7.4 8.5z"/><path d="M11.3 8.5L12.6 8.5A.3 .3 0 0 1 12.9 8.8L12.9 14.2A.3 .3 0 0 1 12.6 14.5L11.3 14.5A.3 .3 0 0 1 11 14.2L11 8.8A.3 .3 0 0 1 11.3 8.5z"/><path d="M15.2 8.5L16.5 8.5A.3 .3 0 0 1 16.8 8.8L16.8 14.2A.3 .3 0 0 1 16.5 14.5L15.2 14.5A.3 .3 0 0 1 14.9 14.2L14.9 8.8A.3 .3 0 0 1 15.2 8.5z"/><path d="M2.2 15.6L17.8 15.6A.4 .4 0 0 1 18.2 16L18.2 17.6A.4 .4 0 0 1 17.8 18L2.2 18A.4 .4 0 0 1 1.8 17.6L1.8 16A.4 .4 0 0 1 2.2 15.6z"/>',
        /*  Tiendas, por lo que venden. */
        camiseta: '<path d="M7.1 2.6C7.5 4 8.6 4.9 10 4.9C11.4 4.9 12.5 4 12.9 2.6L18.4 5.3L16.5 9.6L14.7 8.8L14.7 17.4L5.3 17.4L5.3 8.8L3.5 9.6L1.6 5.3z"/>',
        /*  La tienda exclusiva de ropa (origen_clothing, tipo `exclusiva`). La VIP usa `corona`. */
        gema: '<path fill-rule="evenodd" d="M1.8 7.2 5.5 2.6h9l3.7 4.6L10 17.8zM3.9 7.1h12.2l-.8 1.2H4.7zM8.2 3.7h3.6l1.1 2.4H7.1z"/>',
        tijeras: '<path fill-rule="evenodd" d="M2.3 14.3A3.3 3.3 0 0 1 8.9 14.3A3.3 3.3 0 0 1 2.3 14.3zM4 14.3A1.6 1.6 0 0 1 7.2 14.3A1.6 1.6 0 0 1 4 14.3z"/><path fill-rule="evenodd" d="M17.7 14.3A3.3 3.3 0 0 0 11.1 14.3A3.3 3.3 0 0 0 17.7 14.3zM16 14.3A1.6 1.6 0 0 0 12.8 14.3A1.6 1.6 0 0 0 16 14.3z"/><path d="M7.2 11.4L15.6 1.8L9.6 12.8z"/><path d="M12.8 11.4L4.4 1.8L10.4 12.8z"/>',
        pistola: '<path fill-rule="evenodd" d="M2.4 4.4L17.4 4.4C17.85 4.4 18.2 4.75 18.2 5.2L18.2 9C18.2 9.4 18 9.7 17.6 9.9L16.9 10.2L17.9 16.6C18 17.2 17.6 17.6 17 17.6L13.9 17.6C13.4 17.6 13 17.3 12.9 16.8L12.3 13.8L9.6 13.8C8.6 13.8 7.8 13 7.8 12L7.8 10L2.4 10C2 10 1.6 9.6 1.6 9.2L1.6 5.2C1.6 4.75 1.95 4.4 2.4 4.4zM9.4 10.6L11.9 10.6L12.2 12.4L10 12.4C9.6 12.4 9.4 12.1 9.4 11.8z"/>',
        spray: '<path d="M4.4 9.4C4.4 7.4 5.8 6.2 7.8 6.2C9.8 6.2 11.2 7.4 11.2 9.4L11.2 17C11.2 17.7 10.7 18.2 10 18.2L5.6 18.2C4.9 18.2 4.4 17.7 4.4 17z"/><path d="M6.8 2.4L8.8 2.4A.6 .6 0 0 1 9.4 3L9.4 4.6A.6 .6 0 0 1 8.8 5.2L6.8 5.2A.6 .6 0 0 1 6.2 4.6L6.2 3A.6 .6 0 0 1 6.8 2.4z"/><path d="M12.7 3.8A1.1 1.1 0 0 1 14.9 3.8A1.1 1.1 0 0 1 12.7 3.8z"/><path d="M15.8 2.8A1.1 1.1 0 0 1 18 2.8A1.1 1.1 0 0 1 15.8 2.8z"/><path d="M15.8 6A1.1 1.1 0 0 1 18 6A1.1 1.1 0 0 1 15.8 6z"/><path d="M13.1 7.6A1.1 1.1 0 0 1 15.3 7.6A1.1 1.1 0 0 1 13.1 7.6z"/>',
        /*  Ilegal y encargos. La diana es `paintball`: no hay otra aparte. */
        mira: '<path fill-rule="evenodd" d="M3.5 10A6.5 6.5 0 0 1 16.5 10A6.5 6.5 0 0 1 3.5 10zM5.3 10A4.7 4.7 0 0 1 14.7 10A4.7 4.7 0 0 1 5.3 10z"/><path d="M9.1 2L9.1 6.4A.9 .9 0 0 0 10.9 6.4L10.9 2A.9 .9 0 0 0 9.1 2z"/><path d="M9.1 13.6L9.1 18A.9 .9 0 0 0 10.9 18L10.9 13.6A.9 .9 0 0 0 9.1 13.6z"/><path d="M2 10.9L6.4 10.9A.9 .9 0 0 0 6.4 9.1L2 9.1A.9 .9 0 0 0 2 10.9z"/><path d="M13.6 10.9L18 10.9A.9 .9 0 0 0 18 9.1L13.6 9.1A.9 .9 0 0 0 13.6 10.9z"/><path d="M8.6 10A1.4 1.4 0 0 1 11.4 10A1.4 1.4 0 0 1 8.6 10z"/>',
        exclamacion: '<path fill-rule="evenodd" d="M2 10A8 8 0 0 1 18 10A8 8 0 0 1 2 10zM8.85 5.2L8.85 11A1.15 1.15 0 0 0 11.15 11L11.15 5.2A1.15 1.15 0 0 0 8.85 5.2zM8.65 14.4A1.35 1.35 0 0 1 11.35 14.4A1.35 1.35 0 0 1 8.65 14.4z"/>',
    };

    /*  Sobre un fondo claro el dibujo tiene que ir oscuro. Se mira el brillo
        del color en vez de llevar una lista aparte, asi un color nuevo en
        COLORES ya viene con su tinta puesta.  */
    const tinta = (hex) => {
        const n = parseInt(hex.slice(1), 16);
        const brillo = ((n >> 16) * 299 + ((n >> 8) & 255) * 587 + (n & 255) * 114) / 1000;
        return brillo > 150 ? 'rgba(8,8,12,0.92)' : '#fff';
    };

    /*  Lo cerca que esta una chincheta se dice con el TAMAÑO.

        En un minimapa todo esta a la misma distancia visual, y lo que quieres
        saber conduciendo es que tienes al lado, no que hay en el borde. Al
        acercarte crece y al alejarte se encoge.

        La curva es al cuadrado y no recta a proposito: con una recta, la mitad
        del crecimiento se lo comen los metros lejanos, donde no te importa. Al
        cuadrado casi no pasa nada hasta que estas encima, que es cuando la
        cosa empieza a merecer un vistazo.  */
    const CERCA = { min: 0.78, max: 1.5 };

    const tamañoPor = (metros, radio) => {
        if (metros == null) return 1;
        const t = Math.max(0, Math.min(1, 1 - metros / radio));
        return CERCA.min + (CERCA.max - CERCA.min) * t * t;
    };

    const escalaRefPor = (metros, radio) => {
        if (metros == null) return 1;
        const t = Math.max(0, Math.min(1, 1 - metros / radio));
        return 0.88 + 0.16 * t;
    };

    const caja = document.getElementById('caja');
    const elAlertas = document.getElementById('alertasNecesidades');

    /*  Lo que sube el minimapa para dejar sitio a la linea de comida y agua
        (estilo.css, .necesidades): su alto mas un hueco de 4,5 u. En px y
        medido, no en calc, porque el arrastre de «Posicionar» lo necesita en
        cifras para descontarlo. 0 con la linea escondida. */
    let necSube = 0;
    const medirNecSube = () => {
        const redonda = caja.classList.contains('redonda');
        /*  En la redonda, con el mapa a la vista, comida y agua van en el aro
            (las piezas de los lados del bisel) y la linea de abajo sobra. Si
            el mapa no esta (a pie con «solo en vehiculo»), vuelve la linea.  */
        const enAro = redonda && !caja.hidden && !caja.classList.contains('saliendo');
        if (elAlertas) elAlertas.classList.toggle('en-aro', enAro);
        let n = 0;
        if (elAlertas && !elAlertas.hidden && !enAro && !elAlertas.classList.contains('quitada')) {
            // El hueco son 4,5 u; la linea mide 232 u (en las dos formas: en
            // la redonda solo sale sin el mapa, con su ancho de siempre).
            const u = elAlertas.offsetWidth / 232;
            n = Math.round(elAlertas.offsetHeight + u * 4.5);
        }
        if (elAlertas) elAlertas.classList.toggle('redonda', redonda);
        if (n === necSube) return;
        necSube = n;
        document.documentElement.style.setProperty('--nec-sube', `${n}px`);
    };
    // Ya no hay nada que mover al entrar o salir el mapa: la linea va siempre
    // en la esquina y es el mapa el que se sube. Se queda para no tocar los
    // sitios que la llaman.
    const actualizarPosicionAlertas = () => {};

    /*  Poner y quitar la caja, con su animacion.

        No basta con `hidden`: al quitarla hay que dejarla puesta lo que dura la
        salida y esconderla despues, o no se ve irse. Y hay que poder cancelar
        esa espera, porque montarse y bajarse deprisa —o un semaforo en el que
        entras y sales del coche— manda los dos avisos casi juntos: sin
        cancelar, la caja aparecia y la escondia el temporizador de la salida
        anterior, dejandola invisible con el mapa encendido.

        Duracion de la salida ligada a la del CSS: si se cambia alla, aqui hay
        que subirla tambien. Se deja un margen de 20 ms para que la caja no
        desaparezca justo en el ultimo fotograma de la animacion. */
    const SALIDA_MS = 320;
    let citaOcultar = null;

    /*  Cada vez que se pide poner o quitar la caja sube este numero. Las
        esperas de fotograma comprueban al despertar si su peticion sigue siendo
        la ultima: sin esto, montarse y bajarse en dos fotogramas dejaba una
        espera vieja quitando el punto de partida DESPUES de que la caja ya se
        estuviera yendo, y la caja se volvia a encender sola.  */
    let peticion = 0;

    /*  Dos fotogramas, y no un reflow a mano.

        Para que haya transicion, el navegador tiene que haber PINTADO el punto
        de partida. Con la caja saliendo de `display:none`, forzar el calculo de
        estilos en el mismo golpe no basta —probado dentro del juego: la caja
        saltaba a opacidad 1 sin transicion ninguna—. Esperando a que pase un
        fotograma de verdad, y luego al siguiente, la transicion arranca sola.  */
    const trasDosFotogramas = (fn) => requestAnimationFrame(() => requestAnimationFrame(fn));

    const ponerCaja = (si) => {
        if (citaOcultar) { clearTimeout(citaOcultar); citaOcultar = null; }
        const mia = ++peticion;

        if (si) {
            actualizarPosicionAlertas(true);
            /*  Si ya esta puesta y no se esta yendo, no hay nada que hacer.

                Esto no sobra: el cliente llego a mandar el aviso de encendido en
                CADA fotograma, y sin esta salida cada aviso volvia a poner el
                punto de partida de la entrada — la caja se quedaba en opacidad
                0 para siempre, o sea invisible. Aquello se arreglo en el Lua,
                pero la interfaz no puede quedarse a merced de que quien le
                habla se comporte: repetir "ponte" tiene que ser inofensivo.  */
            if (!caja.hidden && !caja.classList.contains('saliendo')) {
                /*  Salvo una cosa (03/10): si este "ponte" repetido llega
                    ANTES de los dos fotogramas del primero, le ha cambiado el
                    numero de peticion y aquel ya no quita `fuera`. La caja se
                    quedaba puesta y con opacidad 0: sin minimapa hasta el
                    siguiente apagar y encender. Visto al reiniciar el recurso
                    con el jugador dentro de un coche. Lo quita este.  */
                if (caja.classList.contains('fuera')) {
                    trasDosFotogramas(() => {
                        if (mia !== peticion) return;
                        caja.classList.remove('fuera');
                    });
                }
                return;
            }

            /*  Este orden es el que se probo dentro del juego y el que funciona:
                PRIMERO se pone a la vista y DESPUES se le da el punto de
                partida. Al reves —marcarlo mientras todavia esta en
                `display:none`— el navegador se encuentra el punto de partida y
                el de llegada en el mismo golpe y no transiciona nada.  */
            caja.classList.remove('saliendo');
            /*  Una bajada que llego mientras la caja se iba: su limpieza estaba
                apuntada para cuando acabara de irse, y se ha vuelto a pedir
                antes. Se hace ahora, a oscuras. */
            if (cocheAlOcultar) { cocheAlOcultar = false; limpiarCoche(); }
            caja.hidden = false;
            caja.classList.add('fuera');
            cajaPuestaEn = performance.now();
            // La linea de comida y agua, al sitio que le toca con la caja puesta.
            medirNecSube();

            /*  A pie la calle entra un pelo despues que la caja. Y si en ese
                rato llega el coche --que es lo normal: el aviso del coche va
                detras del del minimapa--, la calle no llega a verse nunca y
                no hay un parpadeo de la calle antes de la velocidad. */
            if (!enCoche) {
                caja.classList.add('sitio-llega');
                clearTimeout(citaSitio);
                citaSitio = setTimeout(() => {
                    if (!enCoche) caja.classList.remove('sitio-llega');
                }, CALLE_TRAS_CAJA_MS);
            }

            trasDosFotogramas(() => {
                if (mia !== peticion) return;
                caja.classList.remove('fuera');   // y que se vaya a su sitio
            });
            return;
        }

        actualizarPosicionAlertas(false);
        if (caja.hidden) return;

        caja.classList.add('saliendo', 'fuera');

        citaOcultar = setTimeout(() => {
            if (mia !== peticion) return;
            caja.hidden = true;
            caja.classList.remove('saliendo', 'fuera');
            citaOcultar = null;
            // Y con la caja ya ida.
            medirNecSube();
            if (cocheAlOcultar) { cocheAlOcultar = false; limpiarCoche(); }
            for (const entry of domReferencias.values()) {
                if (entry.el && entry.el.parentNode) {
                    entry.el.parentNode.removeChild(entry.el);
                }
            }
            domReferencias.clear();
        }, SALIDA_MS + 20);
    };

    const giro = document.getElementById('giro');
    const pan = document.getElementById('pan');
    const elCalle = document.getElementById('calle');
    const elZona = document.getElementById('zona');
    /*  ── La cinta de la brujula ─────────────────────────────────────────

        Cuantos grados caben de lado a lado de la cinta. Con el diseño claro
        la cinta ya no ocupa todo el ancho —comparte franja con el rumbo y los
        grados—, y 100 es lo que lleva OrigenMinimap.vue: en ese hueco siguen
        cabiendo dos rumbos a la vista, que es lo que hace falta para saber
        hacia donde vas girando.  */
    const GRADOS_A_LA_VISTA = 100;

    /*  Una marca cada 22,5 grados: letra en los ocho rumbos y un punto en los
        de en medio. Los cuatro cardinales van marcados aparte porque se pintan
        mas presentes que los intermedios.  */
    const PASO_MARCA = 22.5;
    const RUMBOS = {
        0: 'N', 45: 'NE', 90: 'E', 135: 'SE',
        180: 'S', 225: 'SO', 270: 'O', 315: 'NO',
    };
    const CARDINALES = { 0: 1, 90: 1, 180: 1, 270: 1 };
    const OCHO = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];

    const elCinta = document.getElementById('cinta');
    const elCardinal = document.getElementById('cardinal');
    let ultimoCardinal = null;

    /*  Tres vueltas enteras puestas en fila. Desplazando siempre sobre la del
        medio quedan 360 grados de sobra a cada lado, asi que por mucho que
        gires nunca se ve donde se acaba la cinta. Se construye UNA vez.  */
    const VUELTAS = 3;

    const cintaPista = document.getElementById('cintaPista');
    const elGrados = document.getElementById('grados');

    /*  ── El bisel: la brujula de la forma REDONDA ───────────────────────

        En la redonda la brujula no es una franja recta: es un arco de papel
        que abraza el circulo por arriba, como el bisel de un reloj, con las
        marcas colocadas SOBRE la curva (pedido del usuario el 14/09: «en vez
        de recta, con la forma redonda del minimapa»).

        Un solo SVG con su centro en el del circulo. Las 16 marcas estan
        repartidas en una vuelta entera y lo que gira es el grupo: UNA
        escritura por fotograma, como la cinta. Una mascara deja verlas solo
        en el tramo de arriba y las funde hacia los extremos, donde van fijos
        el rumbo (izquierda, rosa) y los grados (derecha), igual que en la
        franja recta. Las unidades del SVG son `u`: 260 de lado.  */
    const NS = 'http://www.w3.org/2000/svg';
    const BISEL_R = 120;          // radio del centro de la franja
    const BISEL_ANCHO = 21;       // grueso de la franja
    const BISEL_ARCO = 52;        // tramo de la calle: de 180-52 a 180+52
    /*  El aro son CUATRO piezas (25/09): la brujula arriba (±60), la calle
        abajo (120-240) y, en los lados, el agua (71,5-108,5) a la derecha y la
        comida (251,5-288,5) a la izquierda. El remate redondo de cada franja
        sobresale su medio grueso (10,5 u, unos 5 grados), asi que con 11,5
        grados entre pieza y pieza queda la misma junta de ~3 u que tenian las
        dos medias lunas de antes.  */
    const BISEL_PIEZAS = [[-60, 60], [71.5, 108.5], [120, 240], [251.5, 288.5]];
    /*  Comida y agua: un surco fino dentro de su pieza, de abajo arriba, con
        el icono en la punta de arriba.  */
    const NEC_ARCO = { agua: [104, 84, 76.5], comida: [256, 276, 283.5] };
    const BISEL_MARCAS = 44;      // las marcas se ven entre -44 y +44

    const arcoPath = (r, desde, hasta) => {
        const p = (g) => {
            const a = (g - 90) * Math.PI / 180;
            return `${(r * Math.cos(a)).toFixed(2)} ${(r * Math.sin(a)).toFixed(2)}`;
        };
        return `M ${p(desde)} A ${r} ${r} 0 0 1 ${p(hasta)}`;
    };

    /*  El mismo arco recorrido en el otro sentido: el texto que va sobre una
        linea se escribe hacia donde avanza, y por abajo tiene que avanzar de
        izquierda a derecha para no salir boca abajo.  */
    const arcoAlReves = (r, desde, hasta) => {
        const p = (g) => {
            const a = (g - 90) * Math.PI / 180;
            return `${(r * Math.cos(a)).toFixed(2)} ${(r * Math.sin(a)).toFixed(2)}`;
        };
        return `M ${p(desde)} A ${r} ${r} 0 0 0 ${p(hasta)}`;
    };

    const bisel = document.createElementNS(NS, 'svg');
    bisel.setAttribute('class', 'bisel');
    bisel.setAttribute('viewBox', '-130 -130 260 260');
    bisel.setAttribute('aria-hidden', 'true');
    bisel.innerHTML =
        '<defs>'
        + '<linearGradient id="biselFundido" gradientUnits="userSpaceOnUse" x1="-100" y1="0" x2="100" y2="0">'
        + '<stop offset="0" stop-color="#fff" stop-opacity="0"/>'
        + '<stop offset="0.22" stop-color="#fff" stop-opacity="1"/>'
        + '<stop offset="0.78" stop-color="#fff" stop-opacity="1"/>'
        + '<stop offset="1" stop-color="#fff" stop-opacity="0"/>'
        + '</linearGradient>'
        + '<mask id="biselMascara" maskUnits="userSpaceOnUse" x="-130" y="-130" width="260" height="260">'
        + `<path d="${arcoPath(BISEL_R, -BISEL_MARCAS, BISEL_MARCAS)}" fill="none" stroke="url(#biselFundido)" stroke-width="${BISEL_ANCHO}"/>`
        + '</mask>'
        + '</defs>'
        /*  El aro casi entero (14/09): con los arcos cortos, arriba la brujula
            y abajo la calle, los huecos de los lados dejaban el mapa con cara
            de huevo. Ahora son dos medias lunas que llegan hasta los lados y
            se tocan dejando una junta fina: la brujula hace limite con la
            calle, pero se leen como dos piezas.  */
        + BISEL_PIEZAS.map(([a, b]) =>
            `<path class="bisel__canto" d="${arcoPath(BISEL_R, a, b)}" stroke-width="${BISEL_ANCHO + 1.5}"/>`
            + `<path class="bisel__franja" d="${arcoPath(BISEL_R, a, b)}" stroke-width="${BISEL_ANCHO}"/>`).join('')
        /*  Comida (izquierda) y agua (derecha), cada una en su pieza. El surco
            del agua va de abajo arriba, o sea contra el reloj: arcoAlReves.  */
        + '<g class="bisel__nec" id="biselNec">'
        + `<path class="bisel__surco" d="${arcoPath(BISEL_R, NEC_ARCO.comida[0], NEC_ARCO.comida[1])}"/>`
        + `<path class="bisel__carga" id="biselComida" pathLength="100" d="${arcoPath(BISEL_R, NEC_ARCO.comida[0], NEC_ARCO.comida[1])}"/>`
        + `<g class="bisel__nec-ico" transform="rotate(${NEC_ARCO.comida[2]}) translate(0 ${-BISEL_R}) rotate(${-NEC_ARCO.comida[2]}) translate(-6 -6) scale(0.5)"><path d="M7 3v18"/><path d="M4 3v5a3 3 0 0 0 6 0V3"/><path d="M17 21V3c-2 0-3.5 3-3.5 7s1.5 4 3.5 4"/></g>`
        + `<path class="bisel__surco" d="${arcoAlReves(BISEL_R, NEC_ARCO.agua[0], NEC_ARCO.agua[1])}"/>`
        + `<path class="bisel__carga" id="biselAgua" pathLength="100" d="${arcoAlReves(BISEL_R, NEC_ARCO.agua[0], NEC_ARCO.agua[1])}"/>`
        + `<g class="bisel__nec-ico" transform="rotate(${NEC_ARCO.agua[2]}) translate(0 ${-BISEL_R}) rotate(${-NEC_ARCO.agua[2]}) translate(-6 -6) scale(0.5)"><path d="M12 3s6 6.5 6 11a6 6 0 0 1-12 0c0-4.5 6-11 6-11z"/></g>`
        + '</g>'
        + '<g mask="url(#biselMascara)"><g class="bisel__marcas"></g></g>'
        + `<path class="bisel__aguja" d="M -4.2 ${-BISEL_R - BISEL_ANCHO / 2 - 1.5} L 4.2 ${-BISEL_R - BISEL_ANCHO / 2 - 1.5} L 0 ${-BISEL_R - BISEL_ANCHO / 2 + 5} Z"/>`
        + `<text class="bisel__rumbo" transform="rotate(${-53}) translate(0 ${-BISEL_R})">N</text>`
        + `<text class="bisel__grados" transform="rotate(${53}) translate(0 ${-BISEL_R})">--°</text>`

        /*  Y ABAJO, la calle: sobre el mismo aro,
            con la calle y el barrio escritos sobre la curva (pedido del
            usuario el 14/09, «lo mismo con la calle, y redondearla»). La linea
            del texto va de izquierda a derecha pasando por abajo —al reves que
            el reloj—: asi las letras quedan derechas y no boca abajo.  */
        + `<path id="biselCalleLinea" fill="none" d="${arcoAlReves(BISEL_R, 180 + BISEL_ARCO, 180 - BISEL_ARCO)}"/>`
        + '<text class="bisel__sitio"><textPath href="#biselCalleLinea" startOffset="50%">'
        + '<tspan class="bisel__calle"></tspan><tspan class="bisel__zona" dx="6"></tspan>'
        + '</textPath></text>';

    const biselMarcas = bisel.querySelector('.bisel__marcas');
    const biselNec = bisel.querySelector('#biselNec');
    const biselComida = bisel.querySelector('#biselComida');
    const biselAgua = bisel.querySelector('#biselAgua');
    biselNec.classList.add('sin-dato');
    const biselRumbo = bisel.querySelector('.bisel__rumbo');
    const biselGrados = bisel.querySelector('.bisel__grados');
    const biselPorRumbo = {};
    const biselSitio = bisel.querySelector('.bisel__sitio');
    const biselCalle = bisel.querySelector('.bisel__calle');
    const biselZona = bisel.querySelector('.bisel__zona');

    /*  Lo que cabe escrito en el arco de abajo, en unidades del SVG: el arco
        entero mide 2·pi·120·(104/360) ≈ 218, y se dejan los dos redondeos de
        los extremos. Un nombre mas largo se estrecha hasta caber —como un
        rotulo condensado— en vez de salirse del papel.  */
    const BISEL_SITIO_MAX = 190;

    function encajarSitio() {
        if (!caja.classList.contains('redonda')) return;
        biselSitio.removeAttribute('textLength');
        biselSitio.removeAttribute('lengthAdjust');
        let largo = 0;
        try { largo = biselSitio.getComputedTextLength(); } catch (e) { largo = 0; }
        if (largo > BISEL_SITIO_MAX) {
            biselSitio.setAttribute('textLength', String(BISEL_SITIO_MAX));
            biselSitio.setAttribute('lengthAdjust', 'spacingAndGlyphs');
        }
    }

    for (let a = 0; a < 360; a += PASO_MARCA) {
        const t = document.createElementNS(NS, 'text');
        const rotulo = RUMBOS[a];
        t.setAttribute('class', 'bisel__m'
            + (CARDINALES[a] ? ' bisel__m--cardinal' : '')
            + (rotulo ? '' : ' bisel__m--punto'));
        t.setAttribute('transform', `rotate(${a}) translate(0 ${-BISEL_R})`);
        t.textContent = rotulo || '·';
        biselMarcas.appendChild(t);
        if (rotulo) biselPorRumbo[rotulo] = t;
    }

    document.querySelector('.ventana').appendChild(bisel);
    let biselUltimo = null;

    /*  El tamaño real de la caja. Se lee del elemento y no de los tokens del
        CSS porque el jugador puede escalarla desde los ajustes del mapa grande.

        Se recalcula solo cuando cambia. La comparacion es mas barata que la
        lectura que evita, y evitarla importa: pedir clientWidth obliga al
        navegador a rehacer la maquetacion, y hacerlo por fotograma es de las
        pocas formas de que un mapa como este llegue a costar algo.  */
    let cajaW = 0;
    let pxPorGrado = 0;

    /*  El ultimo entero escrito, para no repetir la misma cifra por fotograma. */
    let ultimoGrado = null;

    /*  Coloca las marcas. Solo se llama cuando la caja cambia de ancho: la
        cinta se estira con ella, asi que las posiciones son en pixeles y hay
        que rehacerlas. Son 72 elementos y pasa una vez, no por fotograma.  */
    const rehacerCinta = () => {
        pxPorGrado = cajaW / GRADOS_A_LA_VISTA;

        const trozos = [];
        for (let v = 0; v < VUELTAS; v++) {
            for (let a = 0; a < 360; a += PASO_MARCA) {
                const rotulo = RUMBOS[a];
                const clases = 'cinta__m'
                    + (CARDINALES[a] ? ' cinta__m--cardinal' : '');

                trozos.push(
                    `<span class="${clases}" style="left:${((v * 360 + a) * pxPorGrado).toFixed(1)}px">`
                    + (rotulo || '·')
                    + '</span>');
            }
        }

        cintaPista.innerHTML = trozos.join('');
    };

    /*  Lo que se mide es la CINTA, no la caja: desde el diseño claro la cinta
        comparte franja con el rumbo y los grados, y con el ancho de la caja
        la aguja dejaba de caer sobre el grado al que miras.  */
    const medirCaja = () => {
        if (elCinta.clientWidth === cajaW) return;

        cajaW = elCinta.clientWidth;
        rehacerCinta();
    };

    const elFpsNui = document.getElementById('fpsNui');
    const elFpsJuego = document.getElementById('fpsJuego');
    const elRuta = document.getElementById('ruta');
    const elDestinoKm = document.getElementById('destinokm');
    const elDestinoKmTxt = document.getElementById('destinokmTxt');
    const elSobreDist = document.getElementById('sobreDist');
    const elSitioDist = document.getElementById('sitioDist');
    const raiz = document.documentElement;
    const elVentana = document.querySelector('.ventana');
    const elCapaRefs = document.getElementById('capaRefs');

    /*  ── Comida y agua ────────────────────────────────────────────────
        La tarjeta de abajo a la izquierda (index.html, .necesidades). Siete
        celdas, las mismas que los medidores del coche (con diez, a este ancho
        salian puntitos). Se redondea hacia arriba: con un 3 % queda una
        encendida, que es lo que dice «casi nada» y no «nada». */
    const elNecComida = document.getElementById('alertaComida');
    const elNecAgua = document.getElementById('alertaAgua');
    const elNecComidaVal = document.getElementById('alertaComidaVal');
    const elNecAguaVal = document.getElementById('alertaAguaVal');

    const NEC_BAJO = 25;
    const NEC_CRITICO = 10;

    const cifraNec = (v) => (typeof v === 'number' && Number.isFinite(v))
        ? Math.max(0, Math.min(100, Math.round(v))) : null;

    const pintarNec = (el, elVal, v) => {
        if (!el) return;
        el.classList.toggle('bajo', v <= NEC_BAJO);
        if (elVal) elVal.textContent = `${v}%`;
        el.style.setProperty('--p', v / 100);
        const celdas = el.querySelectorAll('.nec__celdas i');
        const on = Math.ceil(v / 100 * celdas.length);
        celdas.forEach((c, n) => c.classList.toggle('on', n < on));
    };

    /*  `muerto` la quita entera: encima de la pantalla de Estado vital no pinta
        nada, y los valores de un muerto no dicen nada util. Sin cifras
        todavia (recien entrado) tampoco se enseña: mejor nada que un 100 %
        inventado. */
    /*  Los dibujos del cielo (accion 'cielo'), trazo de 1,8 en 24 × 24. */
    const CIELOS = {
        sol: '<circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/>',
        luna: '<path d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5z"/>',
        nubes: '<path d="M6.5 19h11a4.5 4.5 0 0 0 .7-8.95A6 6 0 0 0 6.7 8.6 5.2 5.2 0 0 0 6.5 19z"/>',
        lluvia: '<path d="M7 14h10a4 4 0 0 0 .6-7.95A5.5 5.5 0 0 0 7.2 5.1 4.5 4.5 0 0 0 7 14z"/><path d="M8 17l-1 3M12 17l-1 3M16 17l-1 3"/>',
        tormenta: '<path d="M7 14h10a4 4 0 0 0 .6-7.95A5.5 5.5 0 0 0 7.2 5.1 4.5 4.5 0 0 0 7 14z"/><path d="M12.5 13l-2.5 4h3l-2 4"/>',
        niebla: '<path d="M4 9h16M3 13h18M5 17h14"/>',
        nieve: '<path d="M12 3v18M4.2 7.5l15.6 9M4.2 16.5l15.6-9"/><path d="M10 4.5l2 1.5 2-1.5M10 19.5l2-1.5 2 1.5"/>',
    };

    const actualizarNecesidades = (comida, agua, muerto) => {
        if (!elAlertas) return;

        actualizarPosicionAlertas(!caja.hidden && !caja.classList.contains('saliendo'));

        const c = cifraNec(comida);
        const a = cifraNec(agua);

        if (muerto || c === null || a === null) {
            biselNec.classList.add('sin-dato');
            elAlertas.hidden = true;
            medirNecSube();
            return;
        }

        pintarNec(elNecComida, elNecComidaVal, c);
        pintarNec(elNecAgua, elNecAguaVal, a);
        // Y en el aro de la redonda.
        biselNec.classList.remove('sin-dato');
        biselComida.style.strokeDashoffset = 100 - c;
        biselAgua.style.strokeDashoffset = 100 - a;
        biselComida.classList.toggle('bajo', c <= NEC_BAJO);
        biselAgua.classList.toggle('bajo', a <= NEC_BAJO);
        elAlertas.classList.toggle('critico', Math.min(c, a) <= NEC_CRITICO);
        elAlertas.hidden = false;
        // Tambien cuando ya estaba a la vista: el tamaño del minimapa cambia
        // el de la linea, y esto llega cada segundo.
        medirNecSube();
    };
    window.actualizarNecesidades = actualizarNecesidades;

    const formatearDistancia = (m) => {
        if (m == null || !Number.isFinite(m)) return '';
        if (m < 1000) return `${Math.round(m)} m`;
        return `${(m / 1000).toFixed(1)} km`;
    };

    const actualizarDistanciaDestino = (dist) => {
        if (dist == null || dist < 15) {
            if (elDestinoKm) elDestinoKm.hidden = true;
            if (elSobreDist) elSobreDist.hidden = true;
            if (elSitioDist) elSitioDist.hidden = true;
            return;
        }
        const txt = formatearDistancia(dist);
        if (elDestinoKmTxt) elDestinoKmTxt.textContent = txt;
        if (elDestinoKm) elDestinoKm.hidden = false;
        if (elSobreDist) {
            elSobreDist.textContent = txt;
            elSobreDist.hidden = false;
        }
        if (elSitioDist) {
            elSitioDist.textContent = txt;
            elSitioDist.hidden = false;
        }
    };

    let mapa = null;
    let capaRuta = null;
    let capaRastro = null;
    let capaBlips = null;
    let capaPolicia = null;
    let marcaDestino = null;

    /*  Las marcas puestas, por clave. Cada 700 ms llega la lista entera, pero
        casi todas son las mismas de antes: rehacerlas todas seria tirar y
        volver a montar setenta trozos de HTML siete veces cada cinco segundos.
        Se comparan y solo se toca lo que cambia.  */
    const marcas = new Map();
    /*  Los circulos de los puntos con radio (zonas), por la misma clave. */
    const circulos = new Map();
    const domReferencias = new Map();

    /*  De donde viene y a donde va: entre estos dos se interpola.  */
    /*  r es el rumbo de la CAMARA (gira el mapa) y h el del personaje (gira
        la flecha del centro). Van los dos interpolados, cada uno por su lado.  */
    const desde = { x: 0, y: 0, r: 0, h: 0, t: 0 };
    const hasta = { x: 0, y: 0, r: 0, h: 0, t: 0 };

    const elYo = document.getElementById('yo');
    let ultimoGiroYo = null;
    let hayPosicion = false;

    let ancla = null;          // el punto donde esta centrado Leaflet
    let fpsJuego = 0;
    let puntosRuta = 0;

    /*  ── El sistema de coordenadas ──────────────────────────────────────  */
    const crearCRS = (L) => L.extend({}, L.CRS.Simple, {
        transformation: new L.Transformation(ESCALA_X, CENTRO_X, -ESCALA_Y, CENTRO_Y),
    });

    /*  En este CRS un latLng es [y del mundo, x del mundo].  */
    const aLatLng = (x, y) => [y, x];

    /*  ── Interpolacion angular ──────────────────────────────────────────

        Entre 350 y 10 grados hay 20, no 340: sin esto el mapa daria una vuelta
        entera cada vez que cruzas el norte.  */
    const mezclarAngulo = (a, b, t) => {
        let d = ((b - a + 540) % 360) - 180;
        return a + d * t;
    };

    /*  ── Montar ─────────────────────────────────────────────────────────  */
    const montar = () => {
        const L = window.L;
        if (!L || mapa) return;

        mapa = L.map('lienzo', {
            crs: crearCRS(L),
            zoom: ZOOM,
            minZoom: 0,
            maxZoom: 5,
            zoomControl: false,
            attributionControl: false,
            /*  Canvas y no SVG: la ruta puede tener cientos de puntos, y en
                SVG eso son cientos de nodos del DOM que el navegador tiene que
                recalcular cada vez que el mapa se mueve.  */
            preferCanvas: true,
            /*  Nada de interaccion: es una calcomania, no un mapa que se
                maneje. Cada uno de estos apagados es un puñado de escuchas de
                eventos que no se registran.  */
            dragging: false,
            touchZoom: false,
            scrollWheelZoom: false,
            doubleClickZoom: false,
            boxZoom: false,
            keyboard: false,
            inertia: false,
            zoomAnimation: false,
            fadeAnimation: false,
            markerZoomAnimation: false,
        });

        L.tileLayer(TESELAS, {
            minZoom: 0,
            maxZoom: 5,
            noWrap: true,
            updateWhenIdle: false,
            keepBuffer: 3,
        }).addTo(mapa);

        capaRastro = L.polyline([], {
            color: '#ffffff',
            weight: 2,
            opacity: 0.35,
            interactive: false,
        }).addTo(mapa);

        /*  Debajo de la ruta y del rastro: la ruta es lo que estas siguiendo
            ahora y tiene que ganar siempre.  */
        capaBlips = L.layerGroup().addTo(mapa);

        /*  Lo de origen_police va en su propia capa, y no es un capricho: el
            ajuste "Los iconos → Ocultos" quita las chinchetas de tiendas y
            garajes, que es ruido, pero un aviso de policia o la unidad a la
            que sigues no son ruido. Esta capa no la quita ese ajuste.  */
        capaPolicia = L.layerGroup().addTo(mapa);

        /*  La ruta vive en un grupo y no en dos lineas fijas: cada estilo
            necesita un numero distinto de capas —una, tres, o una linea mas
            quince chevrones— asi que se tira y se rehace al cambiar.  */
        capaRuta = L.layerGroup().addTo(mapa);

        mapa.setView(aLatLng(0, 0), ZOOM);
    };

    /*  ══ Los estilos de la linea de la ruta ════════════════════════════

        Por que ninguno usa dashArray contando desde el principio:

        dashArray mide el patron DESDE EL PRIMER PUNTO de la linea, y el primer
        punto de esta ruta eres tu. Al avanzar, el origen del patron avanza
        contigo, asi que todos los trozos se deslizan hacia atras -- y como el
        trazado se rehace cada segundo, encima saltan. Eso es lo que se veia
        raro: no era el estilo, era desde donde se cuenta.

        Los que llevan trozos los cuentan DESDE EL DESTINO, que no se mueve. La
        linea se dibuja del reves y el patron queda clavado al mundo: al
        avanzar solo se come el trozo de tu lado, como en un navegador de
        verdad.  */

    /*  El color de la linea: el rosa de la pegatina (#d81b55), el mismo de
        todo el servidor (antes un rosa medio #e0074f, de la familia vieja).

        Aqui ponia el carmin del tema negro (#c2153f). El medio es mas
        luminoso y mas saturado que aquel, asi que la ruta gana contraste
        sobre el mapa oscuro; y se queda por debajo del vivo a proposito por
        dos razones: el estilo «nucleo» pinta una veta clara (#ff7aa6) por el
        centro de la linea, que sobre el vivo se perderia, y las dos marcas de
        punto —tu flecha y la chincheta del destino— van en el vivo para que
        se lean POR ENCIMA del camino y no se confundan con el.  */
    const ORO = '#d81b55';          // el rosa medio de la casa
    const FILO = '#1b0208';         // el oscuro del refuerzo

    /*  El grosor, en un solo sitio: cinco estilos usando los mismos numeros a
        mano eran cinco sitios donde afinar y cuatro donde olvidarse.

        El filo es casi el doble que la linea a proposito: lo que se ve de el
        es lo que sobresale por los lados, asi que la diferencia ENTRE los dos
        es el borde. Con 5,5 y 3 quedan 1,25 px de filo por cada lado, que a
        este tamaño es una linea de contorno y no un segundo trazo.  */
    const GRUESO = { filo: 5.5, linea: 3, nucleo: 1.1 };

    /*  Cada estilo recibe la linea ya en coordenadas del mapa y mete lo que
        quiera en el grupo. Devolver capas sueltas en vez de tocar variables
        globales es lo que permite cambiar de estilo sin acordarse de limpiar
        nada.  */
    const ESTILOS = {
        /*  0. Neon. La de serie desde el 01/10: ENTERA, sin trozos, y con mas
            cuerpo que la solida. Cuatro capas: un halo rosa ancho y casi
            transparente que la despega del mapa aunque caiga sobre una zona
            clara, el filo oscuro, el rosa y una veta casi blanca por el
            centro. Se lee de un vistazo conduciendo, que es para lo que esta. */
        neon: (L, g, linea) => {
            const base = { lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false };
            L.polyline(linea, { ...base, color: ORO, weight: GRUESO.filo + 6, opacity: 0.2 }).addTo(g);
            L.polyline(linea, { ...base, color: FILO, weight: GRUESO.filo + 1.5, opacity: 0.85 }).addTo(g);
            L.polyline(linea, { ...base, color: ORO, weight: GRUESO.linea + 1.6, opacity: 1 }).addTo(g);
            L.polyline(linea, { ...base, color: '#ffd6e2', weight: GRUESO.nucleo + 0.3, opacity: 0.95 }).addTo(g);
        },

        /*  Ribete. La de los navegadores de coche: el color con un borde
            blanco limpio y una sombra fina por fuera. Sobre el mapa claro el
            blanco la recorta mejor que cualquier filo oscuro.  */
        ribete: (L, g, linea) => {
            const base = { lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false };
            L.polyline(linea, { ...base, color: FILO, weight: GRUESO.filo + 3, opacity: 0.35 }).addTo(g);
            L.polyline(linea, { ...base, color: '#ffffff', weight: GRUESO.filo + 1.2, opacity: 1 }).addTo(g);
            L.polyline(linea, { ...base, color: ORO, weight: GRUESO.linea + 0.6, opacity: 1 }).addTo(g);
        },

        /*  Bloque. Gruesa y plana, del rosa de la casa, con el canto oscuro justo:
            la mas facil de ver de reojo, al estilo arcade del resto del HUD.  */
        bloque: (L, g, linea) => {
            const base = { lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false };
            // Afinada el 01/10: a 8,7 y 6 px se comia la calle entera.
            L.polyline(linea, { ...base, color: FILO, weight: GRUESO.filo + 0.3, opacity: 0.9 }).addTo(g);
            L.polyline(linea, { ...base, color: '#d81b55', weight: GRUESO.linea + 0.6, opacity: 1 }).addTo(g);
        },

        /*  Cable. Fina y precisa: un hilo casi blanco dentro de una funda
            rosa. Tapa menos mapa que ninguna; para quien quiere ver las
            calles de debajo.  */
        cable: (L, g, linea) => {
            const base = { lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false };
            L.polyline(linea, { ...base, color: FILO, weight: GRUESO.filo, opacity: 0.55 }).addTo(g);
            L.polyline(linea, { ...base, color: ORO, weight: GRUESO.linea + 0.4, opacity: 1 }).addTo(g);
            L.polyline(linea, { ...base, color: '#ffffff', weight: GRUESO.nucleo + 0.2, opacity: 1 }).addTo(g);
        },

        /*  Degradado. Entera, y cambia de tono con la distancia: el rosa de
            la casa (#d81b55) lo que tienes delante, el rosa hondo (#b3123f)
            lo que queda lejos. Dice de un vistazo que parte de la ruta es la
            inmediata. Los dos extremos son los de la pegatina, que la marca
            conoce y pasa a su naranja en Nación; los de en medio los repinta
            por fórmula.  */
        degradado: (L, g, linea) => {
            const base = { lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false };
            L.polyline(linea, { ...base, color: FILO, weight: GRUESO.filo + 1.2, opacity: 0.85 }).addTo(g);
            const COLORES = ['#d81b55', '#cf1951', '#c5164b', '#bc1445', '#b3123f'];
            const paso = Math.ceil(linea.length / COLORES.length);
            // De lejos a cerca: lo de delante se pinta lo ultimo y queda encima.
            for (let t = COLORES.length - 1; t >= 0; t--) {
                const trozo = linea.slice(t * paso, (t + 1) * paso + 1);
                if (trozo.length > 1) L.polyline(trozo, { ...base, color: COLORES[t], weight: GRUESO.linea + 1.2, opacity: 1 }).addTo(g);
            }
        },

        /*  1. Solida con filo. La de toda la vida, la de GTA y la de cualquier
            navegador: una linea oscura ancha debajo y el color encima. Sin
            patron no hay nada que se pueda deslizar, asi que es la unica que
            no puede verse rara pase lo que pase.  */
        solida: (L, g, linea) => {
            L.polyline(linea, { color: FILO, weight: GRUESO.filo, opacity: 0.8, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
            L.polyline(linea, { color: ORO, weight: GRUESO.linea, opacity: 1, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
        },

        /*  2. Con nucleo. Tres capas: filo, color y una veta clara por el
            centro. Es lo que hace que una linea parezca una carretera y no un
            trazo de rotulador -- el mismo truco con el que el mapa dibuja las
            autopistas.  */
        nucleo: (L, g, linea) => {
            L.polyline(linea, { color: FILO, weight: GRUESO.filo + 0.5, opacity: 0.8, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
            L.polyline(linea, { color: ORO, weight: GRUESO.linea + 0.8, opacity: 1, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
            L.polyline(linea, { color: '#ff7aa6', weight: GRUESO.nucleo, opacity: 0.85, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
        },

        /*  3. Con chevrones. Linea entera y flechas encima cada pocos puntos,
            apuntando hacia donde vas. Es lo que usa Google Maps y dice una
            cosa que ninguna linea dice sola: el SENTIDO.

            Los chevrones NO se contragiran: tienen que apuntar por donde va la
            carretera, y la carretera gira con el mapa.  */
        chevrones: (L, g, linea) => {
            L.polyline(linea, { color: FILO, weight: GRUESO.filo, opacity: 0.8, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
            L.polyline(linea, { color: ORO, weight: GRUESO.linea, opacity: 1, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);

            /*  Contados desde el DESTINO para que no se deslicen al avanzar, y
                solo en el tramo cercano: mas alla no se ven y serian quince
                marcas de balde.  */
            const CADA = 9;
            const TOPE = 14;
            let puestos = 0;

            for (let i = linea.length - 1 - CADA; i > 0 && puestos < TOPE; i -= CADA) {
                const a = linea[i];
                const b = linea[i - 1];
                /*  El angulo en pantalla, no en el mundo: la y del mapa crece
                    hacia el norte y la de la pantalla hacia abajo, y sin darle
                    la vuelta las flechas saldrian del reves.  */
                const ang = Math.atan2(a[0] - b[0], b[1] - a[1]) * 180 / Math.PI;

                L.marker(a, {
                    interactive: false, keyboard: false, zIndexOffset: 800,
                    icon: L.divIcon({
                        className: '', iconSize: [0, 0], iconAnchor: [0, 0],
                        html: `<span class="mm-chevron" style="transform:rotate(${ang}deg)"></span>`,
                    }),
                }).addTo(g);
                puestos++;
            }
        },

        /*  Las dos segmentadas («trozos» y «carril») se retiraron el 01/10:
            no tienen que salirle a nadie. Abajo, al elegir estilo, cualquier
            nombre que ya no exista cae en la de serie.  */

        /*  5. Solida que se apaga a lo lejos. Cuatro tramos con menos opacidad
            segun se alejan, para que la ruta no termine de golpe: el corte
            donde deja de haber trazado deja de verse porque ahi ya casi no hay
            linea. El unico estilo que ademas tapa ese problema.  */
        desvanecida: (L, g, linea) => {
            const TRAMOS = 4;
            const paso = Math.ceil(linea.length / TRAMOS);

            for (let t = 0; t < TRAMOS; t++) {
                // Un punto de solape, o se ven costuras entre tramo y tramo.
                const trozo = linea.slice(t * paso, Math.min(linea.length, (t + 1) * paso + 1));
                if (trozo.length < 2) continue;

                const o = 1 - t * 0.22;
                L.polyline(trozo, { color: FILO, weight: GRUESO.filo, opacity: 0.8 * o, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
                L.polyline(trozo, { color: ORO, weight: GRUESO.linea, opacity: o, lineCap: 'round', lineJoin: 'round', smoothFactor: 1, interactive: false }).addTo(g);
            }
        },
    };

    let estilo = 'bloque';   // la de serie: la eligio el usuario el 01/10
    let ultimaLinea = null;

    const pintarRuta = () => {
        const L = window.L;
        if (!capaRuta || !L) return;

        capaRuta.clearLayers();
        if (!ultimaLinea || ultimaLinea.length < 2) return;

        (ESTILOS[estilo] || ESTILOS.bloque)(L, capaRuta, ultimaLinea);
    };

    /*  ══ La ruta, recortada por donde vas ══════════════════════════════

        El trazado llega del juego dos veces por segundo y empieza donde
        estabas AL LEERLO. Entre una lectura y la siguiente el coche sigue
        andando, asi que la raya arrancaba por detras de la flecha y daba un
        salto con cada lectura (04/10).

        Aqui se sabe donde estas a cada fotograma, asi que la raya se recorta
        sola: se busca el punto del trazado mas cercano a ti —entre los
        primeros, que es donde puedes estar— y la linea empieza ahi. Lo que
        ya has pasado no se pinta.

        Si el trazado queda lejos (te has salido de la ruta) no se recorta
        nada: la raya se queda entera hasta que el juego mande la nueva.  */
    let rutaJuego = null;            // el trazado tal como llego: [[x, y], ...]
    let rutaCorte = null;            // por donde se corto la ultima vez
    let rutaRecorteT = 0;

    const RECORTE_CADA_MS = 70;      // unas 14 veces por segundo: de sobra
    const RECORTE_MIRAR = 60;        // los primeros tramos; mas alla no estas
    const RECORTE_LEJOS = 40;        // metros: de ahi en adelante, fuera de ruta
    const RECORTE_MINIMO = 1.2;      // metros que hay que avanzar para repintar

    const recortarRuta = (x, y, forzar) => {
        if (!rutaJuego || rutaJuego.length < 2) return;

        let mejor = Infinity, mi = 0, mx = 0, my = 0;
        const tope = Math.min(rutaJuego.length - 1, RECORTE_MIRAR);

        for (let i = 0; i < tope; i++) {
            const a = rutaJuego[i], b = rutaJuego[i + 1];
            const dx = b[0] - a[0], dy = b[1] - a[1];
            const largo = dx * dx + dy * dy;
            let t = largo > 0 ? ((x - a[0]) * dx + (y - a[1]) * dy) / largo : 0;
            t = t < 0 ? 0 : (t > 1 ? 1 : t);
            const px = a[0] + dx * t, py = a[1] + dy * t;
            const d = (px - x) * (px - x) + (py - y) * (py - y);
            // «<=»: a igual distancia gana el tramo de mas adelante.
            if (d <= mejor) { mejor = d; mi = i; mx = px; my = py; }
        }

        const fuera = mejor > RECORTE_LEJOS * RECORTE_LEJOS;
        if (fuera) { mi = 0; mx = rutaJuego[0][0]; my = rutaJuego[0][1]; }

        if (!forzar && rutaCorte
            && Math.abs(rutaCorte.x - mx) < RECORTE_MINIMO
            && Math.abs(rutaCorte.y - my) < RECORTE_MINIMO) return;

        rutaCorte = { x: mx, y: my };

        const linea = [aLatLng(mx, my)];
        for (let i = mi + 1; i < rutaJuego.length; i++) linea.push(aLatLng(rutaJuego[i][0], rutaJuego[i][1]));

        ultimaLinea = linea;
        pintarRuta();
    };

    /*  ── El bucle de pintado ────────────────────────────────────────────  */
    let ultimoCuadro = performance.now();
    let acumulado = 0;
    let cuadros = 0;

    const pintar = (ahora) => {
        requestAnimationFrame(pintar);

        /*  Los fps del propio CEF. Van aparte de los del juego: si estos caen
            y los del juego no, el problema es el mapa; si caen los dos, es el
            coste de tener el CEF pintando.  */
        const dt = ahora - ultimoCuadro;
        ultimoCuadro = ahora;

        /*  Un fotograma de mas de un cuarto de segundo no es un fotograma
            lento: es que el navegador ha estado parado —pestaña en segundo
            plano, una captura, el juego cargando—. Contarlo hunde la media y
            hace creer que el mapa cuesta lo que no cuesta.  */
        if (dt < 250) {
            acumulado += dt;
            cuadros++;
        }

        if (acumulado >= 500 && cuadros > 0) {
            elFpsNui.textContent = Math.round((cuadros * 1000) / acumulado);
            acumulado = 0;
            cuadros = 0;
        }

        if (!mapa || !hayPosicion) return;

        /*  Donde estas AHORA, entre el aviso anterior y el ultimo.

            Se pinta un intervalo POR DETRAS del ultimo aviso, a proposito: asi
            siempre hay dos posiciones entre las que interpolar y el movimiento
            sale continuo. A 30 avisos por segundo ese retraso son 33 ms, que no
            se ven; lo que si se ve —y era el fallo— es ir a saltos al ritmo de
            los avisos mientras el juego va a 200 y pico fotogramas.  */
        const tramo = Math.max(1, hasta.t - desde.t);
        const t = Math.max(0, Math.min(1, (ahora - tramo - desde.t) / tramo));

        const x = desde.x + (hasta.x - desde.x) * t;
        const y = desde.y + (hasta.y - desde.y) * t;
        const r = mezclarAngulo(desde.r, hasta.r, t);
        const h = mezclarAngulo(desde.h, hasta.h, t);

        // La raya de la ruta empieza donde estas ahora, no donde se leyo.
        if (rutaJuego && ahora - rutaRecorteT >= RECORTE_CADA_MS) {
            rutaRecorteT = ahora;
            recortarRuta(x, y, false);
        }

        /*  Leaflet solo se entera cuando te has ido lejos del ancla.  */
        if (!ancla) {
            ancla = { x, y };
            mapa.setView(aLatLng(x, y), ZOOM, { animate: false });
        } else {
            const p = mapa.latLngToContainerPoint(aLatLng(x, y));
            const c = mapa.getSize().divideBy(2);
            const dx = p.x - c.x;
            const dy = p.y - c.y;

            if (Math.abs(dx) > SALTO_ANCLA || Math.abs(dy) > SALTO_ANCLA) {
                ancla = { x, y };
                mapa.setView(aLatLng(x, y), ZOOM, { animate: false });
                pan.style.transform = 'translate3d(0,0,0)';
            } else {
                /*  translate3d y no translate: fuerza al navegador a tratarlo
                    como una capa propia y no repintar el mapa entero.  */
                pan.style.transform = `translate3d(${-dx}px, ${-dy}px, 0)`;
            }
        }

        /*  El rumbo de GTA es 0 al norte y crece hacia el oeste. Girando el
            mapa esos mismos grados en el sentido del reloj, lo que tienes
            delante queda arriba.  */
        giro.style.transform = `rotate(${r}deg)`;

        /*  La flecha del centro apunta a donde MIRA EL PERSONAJE, no a donde
            mira la camara: el mapa gira con la camara (r) y el personaje va
            por su lado (h), asi que en pantalla la flecha queda a r - h, y
            solo coincide con «arriba» cuando miras hacia donde andas. Es lo
            que hace el radar de GTA. Se escribe solo cuando cambia la decima:
            quieto y sin tocar el raton no se toca el DOM.  */
        const giroYo = Math.round(((r - h) % 360) * 10) / 10;
        if (giroYo !== ultimoGiroYo) {
            ultimoGiroYo = giroYo;
            elYo.style.setProperty('--giro-yo', `${giroYo}deg`);
        }

        /*  Las marcas viven dentro del contenedor que gira, asi que sin esto
            saldrian del reves en cuanto te dieras la vuelta. Se contragiran
            con una variable de CSS heredada y no tocando marca por marca: es
            UNA escritura por fotograma en vez de setenta.  */
        raiz.style.setProperty('--contragiro', `${-r}deg`);

        /*  Referencias policiales: se actualizan en cada fotograma para que roten
            suavemente con la cámara y se mantengan en el borde si se alejan. */
        actualizarPosicionesReferencias(x, y, r);

        /*  ── La cinta de la brujula ─────────────────────────────────────

            El rumbo de BRUJULA, no el de GTA: alli el 0 tambien es el norte
            pero crece hacia el OESTE, asi que el este saldria 270 en vez de 90.
            Se le da la vuelta una vez y de ahi salen la cinta y la cifra.  */
        medirCaja();

        const brujula = (((360 - r) % 360) + 360) % 360;

        /*  Se desplaza la pista para que el grado al que miras caiga bajo el
            indice, que esta clavado en el centro.

            Sobre la vuelta DEL MEDIO —de ahi el +360—: asi quedan 360 grados
            de cinta a cada lado y nunca se llega a ver donde se acaba.  */
        cintaPista.style.transform =
            `translate3d(${(cajaW / 2 - (360 + brujula) * pxPorGrado).toFixed(1)}px, 0, 0)`;

        // El bisel de la redonda: el grupo gira para dejar arriba lo que miras.
        biselMarcas.setAttribute('transform', `rotate(${(-brujula).toFixed(2)})`);

        /*  La cifra, solo cuando cambia el entero. Girando despacio el rumbo se
            mueve en decimas y esto se escribiria en todos los fotogramas para
            poner lo mismo, y escribir en el DOM obliga al navegador a rehacer
            el texto aunque ponga lo de antes.  */
        const grados = Math.round(brujula) % 360;

        if (grados !== ultimoGrado) {
            ultimoGrado = grados;
            elGrados.textContent = `${grados}°`;
            biselGrados.textContent = `${grados}°`;

            // La letra del rumbo cambia aun menos: solo al cruzar un sector.
            const cardinal = OCHO[Math.round(brujula / 45) % 8];
            if (cardinal !== ultimoCardinal) {
                ultimoCardinal = cardinal;
                elCardinal.textContent = cardinal;
                biselRumbo.textContent = cardinal;
                // Y en el bisel, la marca de ese rumbo se enciende.
                if (biselUltimo) biselUltimo.classList.remove('on');
                biselUltimo = biselPorRumbo[cardinal] || null;
                if (biselUltimo) biselUltimo.classList.add('on');
            }
        }
    };

    const SPRITE_URLS = {
        '61':  'https://docs.fivem.net/blips/radar_hospital.png',
        '408': 'https://docs.fivem.net/blips/radar_capture_the_flag.png',
        '43':  'https://docs.fivem.net/blips/radar_police_heli.png',
        '1':   'https://docs.fivem.net/blips/radar_level.png',
        '67':  'https://docs.fivem.net/blips/radar_security_van.png',
        '623': 'https://docs.fivem.net/blips/radar_pickup_dtb_blast_decrease.png',
        '102': 'https://docs.fivem.net/blips/radar_comedy_club.png',
        '226': 'https://docs.fivem.net/blips/radar_gang_vehicle_bikers.png',
        '38':  'https://docs.fivem.net/blips/radar_raceflag.png',
        '496': 'https://docs.fivem.net/blips/radar_production_weed.png',
        '442': 'https://docs.fivem.net/blips/radar_beast.png',
        '669': 'https://docs.fivem.net/blips/radar_arena_zr380.png',
        '741': 'https://docs.fivem.net/blips/radar_drone_controls.png',
        '210': 'https://docs.fivem.net/blips/radar_franklin_family_grey.png',
        '780': 'https://docs.fivem.net/blips/radar_docks_export.png',
        '110': 'https://docs.fivem.net/blips/radar_gun_shop.png',
    };

    const COLOR_HEXES = {
        '11': '#8dcea7',
        '12': '#70a8ae',
        '30': '#29a5b8',
        '40': '#4c4c4c',
        '5':  '#eec64e',
        '41': '#f29d9d',
        '1':  '#e03232',
        '29': '#4561ab',
        '3':  '#5db6e5',
        '46': '#ecf029',
        '25': '#0c7b56',
        '15': '#6ac4bf',
        '18': '#97cae9',
        '28': '#cda80c',
        '85': '#3d3d3d',
        '82': '#a4ccaa',
        '34': '#ed8ca1',
        '2':  '#71cb71',
        '83': '#A854F2',
        '50': '#896ce2',
        '26': '#7ac3fe',
        '76': '#782323',
        '24': '#bbd65b',
        '0':  '#ffffff',
    };

    let ultimaRefYoClave = '';

    /*  Tamaño de las referencias de policia (accion 'refEscala'): lo elige el
        agente en los ajustes de origen_police. El CSS escala con la variable. */
    let refEscala = 1;

    const actualizarYo = (ref) => {
        if (!elYo) return;
        const clave = ref ? `${ref.sprite}:${ref.color}:${ref.hex}:${ref.url}` : 'default';
        if (clave === ultimaRefYoClave) return;
        ultimaRefYoClave = clave;

        if (ref && (ref.url || ref.sprite)) {
            const spriteKey = String(ref.sprite || '');
            const colorKey = String(ref.color || '');
            const bg = ref.hex || COLOR_HEXES[colorKey] || '#2f6bff';
            const imgUrl = ref.url || SPRITE_URLS[spriteKey] || 'https://docs.fivem.net/blips/radar_level.png';
            elYo.className = 'yo yo--ref';
            elYo.innerHTML = `
                <div class="yo-ref" style="--fondo-ref: ${bg};">
                    <div class="yo-ref__circulo">
                        <img src="${imgUrl}" class="yo-ref__img" alt="${ref.label || 'REF'}" />
                    </div>
                    <div class="yo-ref__puntero"></div>
                </div>
            `;
        } else {
            elYo.className = 'yo';
            elYo.innerHTML = `
                <svg viewBox="0 0 24 24" width="20" height="20">
                    <path d="M12 2 L19 21 L12 16.5 L5 21 Z"
                          fill="#fff" stroke="#0b0b0d" stroke-width="2.6"
                          stroke-linejoin="round" paint-order="stroke fill"/>
                </svg>
            `;
        }
    };

    /*  ── Referencias policiales de compañeros: capa overlay y fijación en borde ── */
    const actualizarDatosReferencias = (puntos) => {
        if (!elCapaRefs) return;
        const vivos = new Set();

        for (const p of puntos) {
            if (!p || p.x == null || p.y == null) continue;
            const clave = p.source ? `ref:${p.source}` : `ref:${p.x}:${p.y}`;
            vivos.add(clave);

            const colorKey = String(p.color || '');
            const color = (p.color && String(p.color).startsWith('#'))
                ? p.color
                : (COLOR_HEXES[colorKey] || '#2f6bff');

            const spriteKey = String(p.sprite || '');
            const sUrl = p.spriteUrl || p.url || SPRITE_URLS[spriteKey] || 'https://docs.fivem.net/blips/radar_level.png';
            const nombre = p.nombre || '';

            let entry = domReferencias.get(clave);
            if (!entry) {
                const el = document.createElement('div');
                el.className = 'mm-ref-pin';
                el.innerHTML = `
                    <div class="mm-ref-pin__b" style="--fondo:${color}" title="${nombre}">
                        <img src="${sUrl}" class="mm-ref-icon" alt="ref" />
                    </div>
                    <div class="mm-ref-pin__puntero"></div>
                `;
                elCapaRefs.appendChild(el);

                entry = {
                    el,
                    b: el.querySelector('.mm-ref-pin__b'),
                    img: el.querySelector('.mm-ref-icon'),
                    puntero: el.querySelector('.mm-ref-pin__puntero'),
                    x: p.x,
                    y: p.y,
                    color,
                    sUrl,
                    nombre,
                    isClamped: false,
                };
                domReferencias.set(clave, entry);
            } else {
                entry.x = p.x;
                entry.y = p.y;
                if (entry.color !== color) {
                    entry.color = color;
                    entry.b.style.setProperty('--fondo', color);
                }
                if (entry.sUrl !== sUrl) {
                    entry.sUrl = sUrl;
                    entry.img.src = sUrl;
                }
                if (entry.nombre !== nombre) {
                    entry.nombre = nombre;
                    entry.b.title = nombre;
                }
            }
        }

        for (const [clave, entry] of domReferencias) {
            if (!vivos.has(clave)) {
                if (entry.el && entry.el.parentNode) {
                    entry.el.parentNode.removeChild(entry.el);
                }
                domReferencias.delete(clave);
            }
        }
    };

    const actualizarPosicionesReferencias = (yoX, yoY, r) => {
        if (!elCapaRefs || domReferencias.size === 0 || !mapa) return;

        const vW = elVentana ? elVentana.clientWidth : cajaW;
        const vH = elVentana ? elVentana.clientHeight : cajaH;
        if (!vW || !vH) return;

        const centerX = vW / 2;
        const centerY = vH / 2;
        const esRedonda = caja.classList.contains('redonda');

        const pinRadio = 13;
        const margen = pinRadio * refEscala + 3;

        const pYo = mapa.latLngToContainerPoint(aLatLng(yoX, yoY));
        const rad = (r * Math.PI) / 180;
        const cosR = Math.cos(rad);
        const sinR = Math.sin(rad);

        for (const entry of domReferencias.values()) {
            const pComp = mapa.latLngToContainerPoint(aLatLng(entry.x, entry.y));
            const deltaX = pComp.x - pYo.x;
            const deltaY = pComp.y - pYo.y;

            // Rotar conforme al giro del minimapa
            const screenDx = deltaX * cosR - deltaY * sinR;
            const screenDy = deltaX * sinR + deltaY * cosR;

            let finalX = centerX + screenDx;
            let finalY = centerY + screenDy;
            let isClamped = false;

            if (esRedonda) {
                const R = Math.min(vW, vH) / 2;
                const maxDist = Math.max(10, R - margen);
                const dist = Math.sqrt(screenDx * screenDx + screenDy * screenDy);

                if (dist > maxDist) {
                    const ratio = maxDist / (dist || 1);
                    finalX = centerX + screenDx * ratio;
                    finalY = centerY + screenDy * ratio;
                    isClamped = true;
                }
            } else {
                const limX = Math.max(10, (vW / 2) - margen);
                const limY = Math.max(10, (vH / 2) - margen);

                const absX = Math.abs(screenDx);
                const absY = Math.abs(screenDy);

                if (absX > limX || absY > limY) {
                    const ratio = Math.min(
                        absX > 0 ? limX / absX : 1,
                        absY > 0 ? limY / absY : 1
                    );
                    finalX = centerX + screenDx * ratio;
                    finalY = centerY + screenDy * ratio;
                    isClamped = true;
                }
            }

            entry.el.style.transform = `translate3d(${(finalX - pinRadio).toFixed(1)}px, ${(finalY - pinRadio).toFixed(1)}px, 0)`;

            if (isClamped) {
                const rot = (Math.atan2(screenDy, screenDx) * 180 / Math.PI) + 90;
                entry.el.style.setProperty('--rot', `${rot.toFixed(1)}deg`);
            }

            if (entry.isClamped !== isClamped) {
                entry.isClamped = isClamped;
                entry.el.classList.toggle('mm-ref-pin--clamped', isClamped);
            }
        }
    };

    /*  ── El HUD del coche (diseño «HUD carplay») ────────────────────────
        Llega diez veces por segundo mientras vas en un coche (client/main.lua,
        accion 'coche'). Cada pieza se toca solo si su valor ha cambiado: la
        mayoría de los avisos no cambian nada y reescribir el texto igualmente
        obligaría al navegador a rehacerlo.  */
    const elConduccion = document.getElementById('conduccion');
    const elTestigos = document.getElementById('testigos');
    const elSobre = document.getElementById('sobre');
    const elSobreCalle = document.getElementById('sobreCalle');
    const elSobreZona = document.getElementById('sobreZona');
    const elVel = document.getElementById('vel');
    const elKm = document.getElementById('km');
    const elCuentaKm = document.getElementById('cuentakm');
    const elMarcha = document.getElementById('marcha').firstElementChild;
    const elCinturon = document.getElementById('tCinturon');
    const elLuces = document.getElementById('tLuces');
    const elNos = document.getElementById('nos');

    /*  En la forma REDONDA los km y los testigos (cinturon, luces) no van
        sobre el mapa: en los hombros del circulo quedaban colgando sueltos.
        Solo salen en coche, asi que se mudan a una fila fina DENTRO de la
        tarjeta del coche. En la cuadrada vuelven a su esquina de la ventana,
        al sitio exacto de donde salieron. Se mueven los mismos nodos: todo lo
        que los actualiza sigue apuntando a ellos.  */
    const elPieCoche = document.createElement('div');
    elPieCoche.className = 'conduccion__pie';
    const sitioKm = { padre: elCuentaKm.parentNode, antes: elCuentaKm.nextSibling };
    const sitioTestigos = { padre: elTestigos.parentNode, antes: elTestigos.nextSibling };

    function colocarTestigos(redonda) {
        if (redonda) {
            elPieCoche.appendChild(elCuentaKm);
            elPieCoche.appendChild(elTestigos);
            if (elPieCoche.parentNode !== elConduccion) elConduccion.appendChild(elPieCoche);
        } else {
            sitioKm.padre.insertBefore(elCuentaKm, sitioKm.antes && sitioKm.antes.parentNode === sitioKm.padre ? sitioKm.antes : null);
            sitioTestigos.padre.insertBefore(elTestigos, sitioTestigos.antes && sitioTestigos.antes.parentNode === sitioTestigos.padre ? sitioTestigos.antes : null);
            if (elPieCoche.parentNode) elPieCoche.parentNode.removeChild(elPieCoche);
        }
    }

    const CELDAS = 7;

    const medidor = (id) => {
        const el = document.getElementById(id);
        const celdas = el.querySelector('.medidor__celdas');
        for (let i = 0; i < CELDAS; i++) celdas.appendChild(document.createElement('i'));
        return { el, celdas: [...celdas.children], v: el.querySelector('.medidor__v'), ant: null };
    };
    const mGas = medidor('mGas');
    const mMotor = medidor('mMotor');
    const mCoche = medidor('mCoche');

    const ponerMedidor = (m, pct, bajo) => {
        const n = Math.max(0, Math.min(100, Math.round(pct || 0)));
        const clave = n + (bajo ? 'b' : '');
        if (m.ant === clave) return;
        m.ant = clave;
        const llenas = Math.round(n / 100 * CELDAS);
        m.celdas.forEach((c, i) => c.classList.toggle('on', i < llenas));
        m.el.classList.toggle('bajo', !!bajo);
        m.v.textContent = n + '%';
        // Para el diseño en piezas, donde el medidor es una barra que se llena.
        m.el.style.setProperty('--p', n / 100);
    };

    /*  ── La cápsula de la REDONDA (25/09) ─────────────────────────────
        Los mismos datos que la tarjeta de la cuadrada, pintados en la
        cápsula que sale del círculo hacia la derecha (index.html, #capsula).
        Se escribe en las dos siempre: es barato y así cambiar de forma yendo
        en coche no deja ninguna de las dos con cifras viejas.  */
    const CAP_RPM = 18;
    const capVel = document.getElementById('capVel');
    const capMarcha = document.getElementById('capMarcha');
    const capKmCaja = document.getElementById('capKmCaja');
    const capKm = document.getElementById('capKm');
    const capRpm = document.getElementById('capRpm');
    for (let i = 0; i < CAP_RPM; i++) {
        const seg = document.createElement('i');
        if (i >= CAP_RPM - 3) seg.className = 'roja';
        capRpm.appendChild(seg);
    }
    const capSegs = [...capRpm.children];
    const capBarra = (id) => {
        const el = document.getElementById(id);
        return { el, i: el.querySelector('.cap-pista i'), v: el.querySelector('.cap-v') };
    };
    const capGas = capBarra('capGas');
    const capMotor = capBarra('capMotor');
    const capChapa = capBarra('capChapa');
    const capNos = capBarra('capNos');
    const capCinturon = document.getElementById('capCinturon');
    const capLuces = document.getElementById('capLuces');
    const capEncendido = document.getElementById('capEncendido');

    const ponerCapBarra = (b, pct, bajo) => {
        const n = Math.max(0, Math.min(100, Math.round(pct || 0)));
        b.i.style.width = n + '%';
        b.v.textContent = n + '%';
        b.v.classList.toggle('bajo', !!bajo);
    };

    let enCoche = false;
    const ant = {};
    const cambia = (k, v) => { if (ant[k] === v) return false; ant[k] = v; return true; };

    /*  ── Subir y bajar del coche, con su coreografia ──────────────────────

        Las clases y el porque de cada una estan en estilo.css («La entrada y
        la salida del coche»). Aqui va el orden, que es lo que no se ve en el
        CSS:

          SUBIR  con la caja entrando: el piso cambia ya, sin fundir la altura
                 --la caja entera esta apareciendo, nadie ve el salto-- y las
                 piezas se posan escalonadas mientras la caja aterriza.
                 Con la caja ya puesta (el ajuste «siempre»): la calle se funde,
                 la altura crece de 25 a 46 u y las piezas se posan.
          BAJAR  con la caja yendose (lo normal): nada, se limpia a oscuras
                 cuando acaba de irse. Cambiar el piso mientras se desvanece
                 seria un segundo movimiento encima del primero.
                 Con la caja puesta: las piezas se recogen, la altura baja y la
                 calle vuelve.

        Los tiempos van ligados al CSS. `pedidoCoche` hace con las esperas lo
        mismo que `peticion` con las de la caja: subir y bajar deprisa no puede
        dejar a medias una espera vieja.  */
    const CALLE_TRAS_CAJA_MS = 380;   // mas que lo que tarda en llegar el aviso del coche
    const CAJA_ASENTADA_MS = 380;     // antes de esto la caja cuenta como "entrando"
    const SITIO_SALE_MS = 160;        // .caja.sitio-sale
    const RECOGER_MS = 210;           // las piezas en su punto de partida
    const PISO_MS = 460;              // .piso
    const LLEGADA_MS = 1100;          // el ultimo retardo (0,72 s) mas su transicion

    const piso = document.getElementById('piso');
    let cajaPuestaEn = 0;
    let citaSitio = null;
    let citaCoche = null;
    let citaPiso = null;
    let pedidoCoche = 0;
    let cocheAlOcultar = false;

    const cajaAsentada = () =>
        !caja.hidden && !caja.classList.contains('saliendo') &&
        performance.now() - cajaPuestaEn > CAJA_ASENTADA_MS;

    /*  Cambia el piso fundiendo la altura: se fija la de ahora en pixeles, se
        hace el cambio, se mide la nueva y se va hacia ella. `auto` no
        transiciona, por eso se pasa por pixeles y se suelta al acabar.  */
    const cambiarPiso = (cambio) => {
        clearTimeout(citaPiso);
        const antes = piso.getBoundingClientRect().height;
        piso.style.height = '';
        cambio();
        const despues = piso.getBoundingClientRect().height;
        piso.style.height = antes + 'px';
        piso.classList.add('cambiando');
        trasDosFotogramas(() => { piso.style.height = despues + 'px'; });
        citaPiso = setTimeout(() => {
            piso.style.height = '';
            piso.classList.remove('cambiando');
        }, PISO_MS + 60);
    };

    const ponerPiezasCoche = () => {
        caja.classList.add('en-coche');
        elConduccion.hidden = false;
        elTestigos.hidden = false;
        elSobre.hidden = false;
        caja.classList.remove('sitio-sale', 'sitio-llega');
    };

    const limpiarCoche = () => {
        caja.classList.remove('en-coche', 'coche-dentro', 'llegando', 'sitio-sale');
        elConduccion.hidden = true;
        elTestigos.hidden = true;
        elCuentaKm.hidden = true;
        elSobre.hidden = true;
        elNos.hidden = true;
    };

    const subirAlCoche = () => {
        const mio = ++pedidoCoche;
        clearTimeout(citaCoche);
        clearTimeout(citaSitio);
        cocheAlOcultar = false;
        caja.classList.remove('coche-dentro');
        caja.classList.add('llegando');

        const posar = () => {
            trasDosFotogramas(() => {
                if (mio !== pedidoCoche) return;
                caja.classList.add('coche-dentro');
            });
            citaCoche = setTimeout(() => {
                if (mio === pedidoCoche) caja.classList.remove('llegando');
            }, LLEGADA_MS);
        };

        if (!cajaAsentada() || caja.classList.contains('en-coche')) {
            ponerPiezasCoche();
            posar();
            return;
        }

        caja.classList.add('sitio-sale');
        citaCoche = setTimeout(() => {
            if (mio !== pedidoCoche) return;
            cambiarPiso(ponerPiezasCoche);
            posar();
        }, SITIO_SALE_MS);
    };

    const bajarDelCoche = () => {
        const mio = ++pedidoCoche;
        clearTimeout(citaCoche);

        if (caja.hidden) { limpiarCoche(); return; }
        if (caja.classList.contains('saliendo')) { cocheAlOcultar = true; return; }

        caja.classList.remove('llegando', 'coche-dentro');
        citaCoche = setTimeout(() => {
            if (mio !== pedidoCoche) return;
            cambiarPiso(() => {
                limpiarCoche();
                caja.classList.add('sitio-llega');
            });
            trasDosFotogramas(() => {
                if (mio === pedidoCoche) caja.classList.remove('sitio-llega');
            });
        }, RECOGER_MS);
    };

    const pintarCapsula = (c) => {
        if (cambia('capVel', c.velocidad)) capVel.textContent = Math.max(0, c.velocidad || 0);
        if (cambia('capMarcha', c.marcha)) capMarcha.textContent = c.marcha || 'N';
        if (cambia('capKm', c.km)) {
            capKmCaja.hidden = c.km == null;
            if (c.km != null) capKm.textContent = String(c.km).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
        }
        /*  Revoluciones: GetVehicleCurrentRpm va de 0,2 (ralenti) a 1. Sin el
            dato (cliente viejo) la tira se queda apagada.  */
        const encendidas = c.rpm == null ? 0 : Math.round(Math.max(0, Math.min(1, c.rpm)) * CAP_RPM);
        if (cambia('capRpm', encendidas)) capSegs.forEach((sg, i) => sg.classList.toggle('on', i < encendidas));

        if (cambia('capGas', c.gasolina)) ponerCapBarra(capGas, c.gasolina, (c.gasolina || 0) <= 25);
        if (cambia('capMotor', c.motor)) {
            capMotor.el.hidden = c.motor == null;
            if (c.motor != null) ponerCapBarra(capMotor, c.motor, c.motor <= 50);
        }
        if (cambia('capChapa', c.carroceria)) ponerCapBarra(capChapa, c.carroceria, (c.carroceria ?? 100) <= 50);

        if (cambia('capCinturon', c.cinturon)) {
            capCinturon.hidden = c.cinturon == null;
            capCinturon.classList.toggle('mal', c.cinturon === false);
        }
        if (cambia('capLuces', !!c.luces)) capLuces.classList.toggle('apagado', !c.luces);
        if (cambia('capEncendido', c.encendido)) {
            capEncendido.hidden = c.encendido == null;
            capEncendido.classList.toggle('apagado', c.encendido === false);
        }
        const nos = c.nos == null ? null : Math.max(0, Math.min(100, c.nos));
        if (cambia('capNos', nos)) {
            capNos.el.hidden = nos == null;
            if (nos != null) ponerCapBarra(capNos, nos, false);
        }
        if (cambia('capNosActivo', !!c.nosActivo)) capNos.el.classList.toggle('activo', !!c.nosActivo);
        if (cambia('capNosBloq', !!c.nosBloqueado)) capNos.el.classList.toggle('bloqueado', !!c.nosBloqueado);
    };

    const pintarCoche = (c) => {
        const si = !!c;
        if (si !== enCoche) {
            enCoche = si;
            if (si) subirAlCoche();
            else { bajarDelCoche(); for (const k in ant) delete ant[k]; mGas.ant = mMotor.ant = mCoche.ant = null; }
        }
        if (!si) return;

        if (cambia('vel', c.velocidad)) elVel.textContent = Math.max(0, c.velocidad || 0);
        if (cambia('km', c.km)) {
            elKm.textContent = c.km == null ? '' : `${String(c.km).replace(/\B(?=(\d{3})+(?!\d))/g, ' ')} km`;
            // Sin dato no hay chapa vacía en la esquina del mapa.
            elCuentaKm.hidden = c.km == null;
        }
        if (cambia('marcha', c.marcha)) elMarcha.textContent = c.marcha || 'N';
        pintarCapsula(c);

        ponerMedidor(mGas, c.gasolina, (c.gasolina || 0) <= 25);
        /*  El motor en rosa desde la mitad: por debajo de 500 vehiclehandler
            ya le recorta la potencia, y a 0 el coche no anda. Si no llega el
            dato (una versión vieja del cliente), el medidor no se enseña en vez
            de marcar un 0 % falso. */
        mMotor.el.hidden = c.motor == null;
        if (c.motor != null) ponerMedidor(mMotor, c.motor, c.motor <= 50);
        ponerMedidor(mCoche, c.carroceria, (c.carroceria ?? 100) <= 50);

        // Cinturón: null = este vehículo no lleva, y no se pinta.
        if (cambia('cinturon', c.cinturon)) {
            elCinturon.hidden = c.cinturon == null;
            elCinturon.classList.toggle('ok', c.cinturon === true);
            elCinturon.classList.toggle('mal', c.cinturon === false);
        }
        if (cambia('luces', !!c.luces)) elLuces.classList.toggle('encendida', !!c.luces);

        // Nitroso: solo si el coche lleva botella.
        const nos = c.nos == null ? null : Math.max(0, Math.min(100, c.nos));
        if (cambia('nos', nos)) {
            elNos.hidden = nos == null;
            if (nos != null) elNos.style.backgroundImage = `linear-gradient(90deg,#0b0b0d 0%,#0b0b0d ${nos}%,transparent ${nos}%)`;
        }
        if (cambia('nosActivo', !!c.nosActivo)) elNos.classList.toggle('activo', !!c.nosActivo);
        if (cambia('nosBloqueado', !!c.nosBloqueado)) elNos.classList.toggle('bloqueado', !!c.nosBloqueado);
    };

    /*  ── Donde esta la caja, y el modo de colocarla ──────────────────────

        La posicion llega en PROPORCION de pantalla (client/main.lua, «La
        posicion de la caja»): `x` desde el canto izquierdo y `y` desde el de
        abajo, de 0 a 1. Es el mismo ancla que usa el CSS (left y bottom), asi
        que la caja sigue creciendo hacia arriba al subir al coche. `null` es la
        de serie: se quitan las variables y manda estilo.css.

        LA CAJA NUNCA SE SALE DE LA PANTALLA, y eso se decide aqui y no al
        guardar: lo que mide cambia sin que nadie la mueva --el tamaño de los
        ajustes, el piso del coche que la hace crecer, otra resolucion-- y una
        posicion que cabia puede dejar de caber. Se guarda donde el jugador la
        puso y se ENCAJA cada vez que se pinta, con la medida de ese momento.

        Se mide con offsetWidth y offsetHeight, que no cuentan el `scale` de la
        entrada (.caja.fuera): con getBoundingClientRect la caja se encajaria
        con el tamaño que tiene a mitad de animacion.

        El modo de colocarla copia la sensacion del dispatch de la policia
        (MiniDispatch.vue): se agarra por cualquier sitio, se suelta donde
        quieras y se confirma. Se escucha con mousedown y mousemove en
        `window`, como alli, que es lo que ya se sabe que funciona en el CEF. */
    const elPosicionar = document.createElement('div');
    elPosicionar.className = 'posicionar';
    elPosicionar.hidden = true;
    elPosicionar.innerHTML =
        '<i class="posicionar__acento"></i>'
        + '<span class="posicionar__t">Arrastra el minimapa</span>'
        + '<span class="posicionar__teclas">'
        + '<span><kbd>ENTER</kbd>confirmar</span>'
        + '<span><kbd>ESC</kbd>cancelar</span>'
        + '<span><kbd>R</kbd>de serie</span>'
        + '</span>'
        + '<span class="posicionar__botones">'
        + '<button type="button" class="posicionar__b" data-hace="cancelar"><span>Cancelar</span></button>'
        + '<button type="button" class="posicionar__b posicionar__b--rosa" data-hace="confirmar"><span>Confirmar</span></button>'
        + '</span>';
    document.body.appendChild(elPosicionar);

    let posGuardada = null;    // la que dice el juego
    let posActual = null;      // la que se pinta: la guardada, o la que se esta moviendo
    let posicionando = false;

    /* Para el vigilante del raton (@origen_map/shared/foco.lua): el minimapa
       siempre pinta, y lo unico de esta pagina que coge el raton es colocarlo. */
    window.__origenFocoVisto = function () { return posicionando; };
    let arrastre = null;       // desde donde se agarro: raton y caja, en pixeles

    const MARGEN_AVISO = 10;   // entre el aviso y la caja, y contra el canto

    /*  Solo vale un objeto con dos numeros finitos entre 0 y 1. Lo demas, a la
        de serie: una posicion rara no puede dejar la caja fuera de la vista.  */
    const posicionValida = (p) => {
        if (!p || typeof p !== 'object') return null;
        const x = Number(p.x), y = Number(p.y);
        if (!Number.isFinite(x) || !Number.isFinite(y)) return null;
        if (x < 0 || x > 1 || y < 0 || y > 1) return null;
        return { x, y };
    };

    const redondear = (n) => Math.round(n * 10000) / 10000;

    /*  De proporcion a pixeles, ya encajada con lo que mide la caja AHORA.  */
    const encajar = (p) => {
        const w = window.innerWidth, h = window.innerHeight;
        const libreX = Math.max(0, w - caja.offsetWidth);
        // La caja va subida lo que mide la linea de comida y agua: el grupo
        // entero tiene que caber.
        const libreY = Math.max(0, h - caja.offsetHeight - necSube);
        return {
            left: Math.min(libreX, Math.max(0, p.x * w)),
            bottom: Math.min(libreY, Math.max(0, p.y * h)),
        };
    };

    /*  El aviso va pegado a la caja: encima si cabe, y si no, debajo. Uno fijo
        en mitad de la pantalla acababa tapado justo por la caja que estas
        moviendo en cuanto la llevabas alli.  */
    const colocarAviso = () => {
        if (elPosicionar.hidden) return;
        const w = window.innerWidth, h = window.innerHeight;
        const aw = elPosicionar.offsetWidth, ah = elPosicionar.offsetHeight;
        const arriba = caja.offsetTop, alto = caja.offsetHeight;

        let top = arriba - MARGEN_AVISO - ah;
        if (top < MARGEN_AVISO) top = arriba + alto + MARGEN_AVISO;
        top = Math.min(Math.max(MARGEN_AVISO, top), Math.max(MARGEN_AVISO, h - ah - MARGEN_AVISO));

        const left = Math.min(Math.max(MARGEN_AVISO, caja.offsetLeft), Math.max(MARGEN_AVISO, w - aw - MARGEN_AVISO));

        elPosicionar.style.left = `${left}px`;
        elPosicionar.style.top = `${top}px`;
    };

    const pintarPosicion = () => {
        if (!posActual) {
            caja.style.removeProperty('--caja-x');
            caja.style.removeProperty('--caja-y');
            raiz.style.removeProperty('--caja-x');
            raiz.style.removeProperty('--caja-y');
        } else {
            const e = encajar(posActual);
            caja.style.setProperty('--caja-x', `${e.left}px`);
            caja.style.setProperty('--caja-y', `${e.bottom}px`);
            raiz.style.setProperty('--caja-x', `${e.left}px`);
            raiz.style.setProperty('--caja-y', `${e.bottom}px`);
        }
        colocarAviso();
    };

    /*  Lo que mide la caja cambia sola (tamaño, piso del coche) y la ventana
        tambien: se vuelve a encajar. Escribir left y bottom no le cambia el
        tamaño, asi que el observador no se llama a si mismo.  */
    if (window.ResizeObserver) new ResizeObserver(pintarPosicion).observe(caja);
    window.addEventListener('resize', pintarPosicion);

    const alJuegoPosicion = (nombre, datos) => {
        /*  Fuera del juego (en un navegador): se cuenta por consola lo que
            se habria mandado, para poder comprobarlo.  */
        if (!window.invokeNative) { console.info(`[origen_map] ${nombre}`, datos); return; }
        const recurso = window.GetParentResourceName ? window.GetParentResourceName() : 'origen_map';
        fetch(`https://${recurso}/${nombre}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(datos || {}),
        }).catch(() => {});
    };

    const entrarAPosicionar = () => {
        if (posicionando) return;
        posicionando = true;
        posActual = posGuardada;
        raiz.classList.add('posicionando');
        caja.classList.add('posicionando');
        elPosicionar.hidden = false;
        pintarPosicion();
        // La caja puede estar saliendo de display:none en este mismo golpe.
        requestAnimationFrame(colocarAviso);
    };

    const salirDePosicionar = () => {
        posicionando = false;
        arrastre = null;
        raiz.classList.remove('posicionando');
        caja.classList.remove('posicionando', 'arrastrando');
        elPosicionar.hidden = true;
    };

    /*  Confirmar manda lo que se ve, ya encajado: si el jugador la ha pegado
        al canto, se guarda pegada al canto y no un poco fuera.  */
    const confirmarPosicion = () => {
        if (!posicionando) return;
        const p = posActual ? { x: redondear(posActual.x), y: redondear(posActual.y) } : null;
        salirDePosicionar();
        posGuardada = p;
        posActual = p;
        pintarPosicion();
        alJuegoPosicion('posicionHecha', p || { x: null, y: null });
    };

    const cancelarPosicion = () => {
        if (!posicionando) return;
        salirDePosicionar();
        posActual = posGuardada;
        pintarPosicion();
        alJuegoPosicion('posicionCancelada', {});
    };

    /*  La R la devuelve a la esquina, pero sin confirmar: se ve donde queda y
        todavia se puede cancelar o volver a moverla.  */
    const posicionDeSerie = () => {
        if (!posicionando) return;
        posActual = null;
        pintarPosicion();
    };

    caja.addEventListener('mousedown', (e) => {
        if (!posicionando || e.button !== 0) return;
        e.preventDefault();
        /*  Desde donde esta pintada ahora, tambien si es la de serie: la de
            serie no tiene cifras, son las del CSS.  */
        arrastre = {
            x: e.clientX,
            y: e.clientY,
            left: caja.offsetLeft,
            // Lo que se guarda es la esquina del grupo, no la de la caja, que
            // va subida sobre la linea de comida y agua.
            bottom: window.innerHeight - caja.offsetTop - caja.offsetHeight - necSube,
        };
        caja.classList.add('arrastrando');
    });

    window.addEventListener('mousemove', (e) => {
        if (!posicionando || !arrastre) return;
        const w = window.innerWidth, h = window.innerHeight;
        const left = arrastre.left + (e.clientX - arrastre.x);
        const bottom = arrastre.bottom - (e.clientY - arrastre.y);
        // Se encaja YA, y no solo al pintar: si no, pasado el canto habria
        // que desandar lo que sobra antes de que la caja volviera a moverse.
        const e2 = encajar({ x: left / w, y: bottom / h });
        posActual = { x: e2.left / w, y: e2.bottom / h };
        pintarPosicion();
    });

    const soltarArrastre = () => {
        if (!arrastre) return;
        arrastre = null;
        caja.classList.remove('arrastrando');
    };
    window.addEventListener('mouseup', soltarArrastre);
    window.addEventListener('blur', soltarArrastre);

    elPosicionar.addEventListener('click', (e) => {
        const b = e.target.closest('[data-hace]');
        if (!b) return;
        if (b.dataset.hace === 'confirmar') confirmarPosicion();
        else cancelarPosicion();
    });

    window.addEventListener('keydown', (e) => {
        if (!posicionando || e.repeat) return;
        if (e.key === 'Enter') { e.preventDefault(); confirmarPosicion(); }
        else if (e.key === 'Escape') { e.preventDefault(); cancelarPosicion(); }
        else if (e.key === 'r' || e.key === 'R') { e.preventDefault(); posicionDeSerie(); }
    });

    /*  ── Lo que llega del juego ─────────────────────────────────────────  */
    window.addEventListener('message', (ev) => {
        const d = ev.data || {};

        /*  Entrar y salir del modo. La salida la manda Lua cuando ha acabado
            por su lado (confirmar o cancelar ya salen aqui antes de avisarle)
            o cuando le quitan el raton a la fuerza: entonces se vuelve a la
            guardada sin avisar a nadie.  */
        if (d.accion === 'posicionar') {
            if (d.activo) { entrarAPosicionar(); return; }
            if (posicionando) {
                salirDePosicionar();
                posActual = posGuardada;
                pintarPosicion();
            }
            return;
        }

        if (d.accion === 'ajustes') {
            const a = d.ajustes || {};

            /*  Solo si viene: un aviso sin `posicion` (uno que manda solo el
                tamaño) no la toca. `false` es la de serie.  */
            if ('posicion' in a) {
                posGuardada = posicionValida(a.posicion);
                if (!posicionando) { posActual = posGuardada; pintarPosicion(); }
            }

            if (ESTILOS[a.linea]) { estilo = a.linea; pintarRuta(); }

            if (TAMANOS[a.tamano]) {
                raiz.style.setProperty('--caja-escala', TAMANOS[a.tamano]);
                if (mapa) requestAnimationFrame(() => mapa.invalidateSize());
            }

            /*  La forma: la misma caja, cuadrada o redonda (estilo.css, «La
                forma redonda»). Solo si viene, como la posicion. La ventana
                cambia de medida, asi que Leaflet tiene que volver a medirse o
                se quedaria con el centro del tamaño viejo; la cinta y el
                encaje contra los cantos se miden solos.  */
            /*  08/10: el usuario quiere SOLO el cuadrado, para siempre. Aunque
                venga «redondo» guardado de antes, se pinta cuadrado.  */
            if (a.forma === 'redondo' || a.forma === 'cuadrado') {
                const redonda = false;
                if (caja.classList.contains('redonda') !== redonda) {
                    caja.classList.toggle('redonda', redonda);
                    medirNecSube();
                    colocarTestigos(redonda);
                    if (redonda) requestAnimationFrame(encajarSitio);
                    if (mapa) requestAnimationFrame(() => mapa.invalidateSize());
                }
            }

            if (ZOOMS[a.zoom] && mapa && ZOOMS[a.zoom] !== ZOOM) {
                ZOOM = ZOOMS[a.zoom];
                ancla = null;
            }

            /*  Comida y agua fuera: la linea y el surco del aro. Solo si
                viene, como la forma. El minimapa baja a la esquina al no
                tener que dejarle sitio (medirNecSube la cuenta como oculta). */
            if (a.necesidades === 'si' || a.necesidades === 'no') {
                const fuera = a.necesidades === 'no';
                if (elAlertas) elAlertas.classList.toggle('quitada', fuera);
                biselNec.classList.toggle('quitada', fuera);
                medirNecSube();
            }

            if (capaBlips) capaBlips[a.iconos === 'no' ? 'remove' : 'addTo'](mapa);
            if (capaRastro) capaRastro.setStyle({ opacity: a.rastro === 'si' ? 0.35 : 0 });

            return;
        }

        if (d.accion === 'estiloRuta') {
            if (ESTILOS[d.estilo]) { estilo = d.estilo; pintarRuta(); }
            return;
        }

        if (d.accion === 'voz') {
            const v = document.getElementById('necVoz');
            if (v) {
                v.classList.toggle('hablando', !!d.hablando);
                v.classList.toggle('radio', !!d.radio);
                v.dataset.nivel = String(d.nivel || 2);
            }
            return;
        }
        if (d.accion === 'actualizarNecesidades') {
            actualizarNecesidades(d.comida, d.agua, d.muerto);
            return;
        }

        if (d.accion === 'apartar') {
            if (elAlertas) elAlertas.classList.toggle('apartado', !!d.apartado);
            return;
        }

        /*  El cielo de la brujula (diseño en piezas): lo manda el cliente
            cada pocos segundos. Un icono por clave; lo que no se conoce se
            queda con el que habia. */
        if (d.accion === 'cielo') {
            const el = document.getElementById('cielo');
            const svg = CIELOS[d.icono];
            if (el && svg && el.dataset.icono !== d.icono) {
                el.dataset.icono = d.icono;
                el.innerHTML = `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${svg}</svg>`;
            }
            return;
        }

        if (d.accion === 'pausa') {
            if (elAlertas) elAlertas.classList.toggle('pausa', !!d.pausa);
            // 07/10: con la pausa o el menu de Ajustes, fuera TODO el HUD.
            document.body.classList.toggle('en-pausa', !!d.pausa);
            return;
        }

        /*  El cardinal que manda el cliente ya no se pinta aqui: el rumbo lo
            dice la brujula de arriba, calculado en cada fotograma. Sin calle
            —campo, monte, agua— la zona pasa a ser el rotulo grande, que es
            mejor que dejar la barra vacia.  */
        if (d.accion === 'sitio') {
            const calle = (d.calle || '').trim();
            const zona = (d.zona || '').trim();
            elCalle.textContent = calle || zona;
            elZona.textContent = calle ? zona : '';
            // En coche, la misma calle va encima del mapa.
            elSobreCalle.textContent = calle || zona;
            elSobreZona.textContent = calle ? zona : '';
            // Y en el arco de abajo de la redonda.
            biselCalle.textContent = calle || zona;
            biselZona.textContent = calle ? zona : '';
            encajarSitio();
            return;
        }

        if (d.accion === 'coche') {
            pintarCoche(d.coche || null);
            return;
        }

        if (d.accion === 'medida') {
            document.getElementById('medida').hidden = !d.ver;
            return;
        }

        if (d.accion === 'estado') {
            ponerCaja(d.encendido);
            if (d.encendido) {
                montar();
                requestAnimationFrame(() => mapa && mapa.invalidateSize());
            } else {
                actualizarDistanciaDestino(null);
            }
            return;
        }

        if (d.accion === 'yo') {
            desde.x = hayPosicion ? hasta.x : d.x;
            desde.y = hayPosicion ? hasta.y : d.y;
            desde.r = hayPosicion ? hasta.r : d.rumbo;
            /*  Un cliente viejo no manda `mira`: entonces la flecha va con el
                mapa, como antes, en vez de quedarse clavada al norte.  */
            const mira = (d.mira === undefined || d.mira === null) ? d.rumbo : d.mira;
            desde.h = hayPosicion ? hasta.h : mira;
            desde.t = hasta.t;

            hasta.x = d.x;
            hasta.y = d.y;
            hasta.r = d.rumbo;
            hasta.h = mira;
            hasta.t = performance.now();

            hayPosicion = true;
            fpsJuego = d.fps || 0;
            elFpsJuego.textContent = fpsJuego || '--';

            actualizarYo(d.referencia);
            return;
        }

        if (d.accion === 'ruta') {
            if (!capaRuta) return;
            const p = d.puntos;
            if (marcaDestino) { mapa.removeLayer(marcaDestino); marcaDestino = null; }

            if (d.destino) {
                const L = window.L;
                marcaDestino = L.marker(aLatLng(d.destino[0], d.destino[1]), {
                    interactive: false,
                    keyboard: false,
                    zIndexOffset: 900,
                    icon: L.divIcon({
                        className: '',
                        iconSize: [0, 0],
                        iconAnchor: [0, 0],
                        html: '<span class="mm-destino"><span class="mm-destino__pulso"></span>'
                            + '<span class="mm-destino__pin">'
                            + '<svg viewBox="0 0 20 20" fill="currentColor" stroke="none">'
                            + DIBUJOS.chincheta + '</svg></span></span>',
                    }),
                }).addTo(mapa);
            }

            if (!p || !p.length) {
                rutaJuego = null;
                ultimaLinea = null;
                puntosRuta = 0;
                pintarRuta();
            } else {
                rutaJuego = p;
                puntosRuta = p.length;
                /*  Recortada desde ya, con la ultima posicion que se conoce:
                    pintarla entera y recortarla al fotograma siguiente seria
                    el mismo salto que se queria quitar.  */
                if (hayPosicion) {
                    recortarRuta(hasta.x, hasta.y, true);
                } else {
                    ultimaLinea = p.map(([x, y]) => aLatLng(x, y));
                    pintarRuta();
                }
            }
            elRuta.textContent = puntosRuta ? puntosRuta : '--';
            if (d.distancia !== undefined) {
                actualizarDistanciaDestino(d.destino ? d.distancia : null);
            } else if (!d.destino) {
                actualizarDistanciaDestino(null);
            }
            return;
        }

        if (d.accion === 'distancia') {
            actualizarDistanciaDestino(d.distancia);
            return;
        }

        if (d.accion === 'blips') {
            if (!capaBlips) return;
            const L = window.L;
            const vivos = new Set();

            const RADIO = Math.max(120, ...(d.puntos || []).map((p) => p[4] || 0));

            for (const item of (d.puntos || [])) {
                const [x, y, cat, icono, dist, nombre, estado, tinte, radio, spriteUrl, spriteId, pulso] = item;
                if (cat === 'referencia' || cat === 'referencias') continue;
                const clave = `${x}:${y}:${cat}`;
                vivos.add(clave);

                /*  Un punto con radio es una zona: el círculo va debajo de la
                    chincheta, en metros del juego (el CRS mide en coordenadas).
                    Se guarda aparte porque la chincheta se reutiliza entre
                    refrescos y el círculo tiene que irse con ella. */
                if (radio && !circulos.has(clave)) {
                    const tono = tinte || COLORES[cat] || '#d8d5da';
                    circulos.set(clave, L.circle(aLatLng(x, y), {
                        radius: Number(radio),
                        color: tono,
                        weight: 2,
                        opacity: 0.8,
                        fillColor: tono,
                        fillOpacity: 0.08,
                        interactive: false,
                    }).addTo(capaBlips));
                }

                const ya = marcas.get(clave);
                if (ya) {
                    const el = ya.getElement();
                    const b = el && el.querySelector('.mm-pin__b');
                    if (b) b.style.setProperty('--escala', tamañoPor(dist, RADIO));
                    continue;
                }

                let color = tinte || COLORES[cat] || '#d8d5da';
                const apagado = estado === 'cerrado' ? ';opacity:.45' : '';

                const htmlContent = `<span class="mm-pin${pulso ? ' late' : ''}"><span class="mm-pin__b" `
                    + `style="--fondo:${color};color:${tinta(color)};--escala:${tamañoPor(dist, RADIO)}${apagado}">`
                    + '<svg viewBox="0 0 20 20" fill="currentColor" stroke="none">'
                    + (DIBUJOS[icono] || DIBUJOS.edificio)
                    + '</svg></span></span>';

                const m = L.marker(aLatLng(x, y), {
                    interactive: false,
                    keyboard: false,
                    icon: L.divIcon({
                        className: '',
                        iconSize: [15, 20],
                        iconAnchor: [7.5, 20],
                        html: htmlContent,
                    }),
                }).addTo(esDePolicia(cat) ? capaPolicia : capaBlips);

                marcas.set(clave, m);
            }

            for (const [clave, m] of marcas) {
                if (!vivos.has(clave)) {
                    capaBlips.removeLayer(m);
                    if (capaPolicia) capaPolicia.removeLayer(m);
                    marcas.delete(clave);
                }
            }
            for (const [clave, c] of circulos) {
                if (!vivos.has(clave)) {
                    capaBlips.removeLayer(c);
                    circulos.delete(clave);
                }
            }
            return;
        }

        if (d.accion === 'refEscala') {
            refEscala = Number(d.escala) > 0 ? Number(d.escala) : 1;
            document.documentElement.style.setProperty('--ref-escala', String(refEscala));
            return;
        }

        if (d.accion === 'referencias') {
            actualizarDatosReferencias(d.puntos || []);
            return;
        }

        if (d.accion === 'rastro') {
            if (!capaRastro) return;
            const p = d.puntos || [];
            capaRastro.setLatLngs(p.map(([x, y]) => aLatLng(x, y)));
        }
    });

    requestAnimationFrame(pintar);

    /*  ── Avisar de que ya estamos ───────────────────────────────────────

        El cliente manda el estado con SendNUIMessage, y eso a una pagina que
        todavia no ha cargado no se encola: se pierde. Su primer aviso sale en
        el primer fotograma del recurso, muchisimo antes de que esta pagina
        exista, y despues solo vuelve a mandarlo cuando el estado CAMBIA. Si en
        ese momento estabas montado en un coche, el mapa no aparecia hasta que
        te bajabas y volvias a subir.

        Con esto la pagina pide el estado en cuanto puede pintarlo. Fuera del
        juego —en un navegador— no hay a quien pedirselo,
        asi que ni se intenta.  */
    if (window.invokeNative) {
        const recurso = window.GetParentResourceName ? window.GetParentResourceName() : 'origen_map';
        fetch(`https://${recurso}/listo`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: '{}',
        }).catch(() => {});
    }
})();
