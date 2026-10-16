const s_click = new Audio('./sounds/click.mp3');
const s_over = new Audio('./sounds/over.wav');
const s_transition = new Audio('./sounds/transition.ogg');
const s_unlock = new Audio('./sounds/unlock.mp3');
const s_pop = new Audio('./sounds/pop.mp3');
const alarm = new Audio('./sounds/alarm.mp3');

s_click.volume = 0.1;
s_over.volume = 0.1;
s_transition.volume = 0.2;
s_unlock.volume = 1;
s_pop.volume = 0.3;
alarm.volume = 0.0;

/* ══ Los dos sonidos del riel ════════════════════════════════════════════
   Los mismos WAV que el inventario y el menú de inicio, con sus volúmenes
   calibrados allí. Van aparte de los de arriba a propósito: aquellos son de
   las pantallas del recurso y estos, del menú lateral.
   Ver .claude/skills/origen-riel/SKILL.md */
function sonador(url, volumen) {
    var audio = null;

    return function () {
        try {
            if (!audio) { audio = new Audio(url); audio.volume = volumen; }
            audio.currentTime = 0;
            /*  El navegador rechaza la promesa si todavía no ha habido
                interacción con la página. Es un caso normal, no un fallo. */
            var p = audio.play();
            if (p && p.catch) p.catch(function () { });
        } catch (e) { /* Sin audio la pantalla funciona igual. */ }
    };
}

const Sonido = {
    deslizar: sonador('./sounds/slide.wav', 0.35),
    pulsar: sonador('./sounds/click.wav', 0.3),
};

function fetch(event, data) {
    return $.post('https://origen_housing/' + event, JSON.stringify(data)).promise();
}

function exportEvent(script, event, data) {
    return $.post('https://' + script + '/' + event, JSON.stringify(data)).promise();
}

function TriggerCallback(event, data) {
    data.trigger = event;
    return $.post('https://origen_housing/TriggerCallback', JSON.stringify(data)).promise();
}

/* ══ El desplegable propio ═══════════════════════════════════════════════
   Nunca un <select> nativo: Chromium lo pinta con el tema de Windows —claro,
   en ingles y con la fuente del sistema— encima del juego.
   Ver .claude/skills/origen-tablet/SKILL.md */
Vue.component('ogn-select', {
    props: {
        value: { default: '' },
        options: { type: Array, default: function () { return []; } },
        placeholder: { type: String, default: 'Elige' },
    },

    data: function () {
        return { abierto: false, sitio: null };
    },

    computed: {
        elegido: function () {
            var self = this;
            var hallado = this.options.find(function (o) { return o.value === self.value; });
            return hallado ? hallado.label : this.placeholder;
        },
    },

    methods: {
        /* Donde cae la lista. El kit la pinta `position: fixed` SIN
           coordenadas, contando con que el componente se las ponga desde el
           rect del control; sin eso se queda en su posicion estatica y, en
           cuanto el formulario se desplaza, aparece fuera de la pantalla: el
           desplegable se abria y no salia nada.

           Se abre hacia arriba si no cabe debajo, que si no el ultimo campo
           de un formulario deja su lista fuera de la vista.
           Ver .claude/skills/origen-tablet/SKILL.md */
        medir: function () {
            var control = this.$el && this.$el.querySelector('.ogn-select__control');
            if (!control) return;

            var r = control.getBoundingClientRect();
            var alto = Math.min(window.innerHeight * 0.32, this.options.length * 44 + 8);
            var hueco = window.innerHeight * 0.005;
            var arriba = r.bottom + hueco + alto > window.innerHeight && r.top - hueco - alto > 0;

            /* Ni cabe debajo ni encima —una lista larga en una pantalla baja—:
               se queda debajo pero pegada al canto, dentro de la vista. Salirse
               por abajo se ve igual que no abrirse. */
            var top = r.bottom + hueco;
            if (!arriba) {
                top = Math.max(hueco, Math.min(top, window.innerHeight - hueco - alto));
            }

            this.sitio = {
                left: r.left + 'px',
                width: r.width + 'px',
                top: arriba ? '' : top + 'px',
                bottom: arriba ? (window.innerHeight - r.top + hueco) + 'px' : '',
            };
        },

        /* La lista no se mueve sola: hay que volver a medirla al rodar
           cualquier caja de la pagina —el `true` recoge tambien el scroll de
           dentro de una zona— y al cambiar el tamaño. */
        enganchar: function () {
            window.addEventListener('scroll', this.medir, true);
            window.addEventListener('resize', this.medir);
        },

        desenganchar: function () {
            window.removeEventListener('scroll', this.medir, true);
            window.removeEventListener('resize', this.medir);
        },

        cerrar: function () {
            this.abierto = false;
            this.desenganchar();
        },

        alternar: function () {
            this.abierto = !this.abierto;

            if (!this.abierto) return this.desenganchar();

            var self = this;
            this.$nextTick(function () {
                self.medir();
                self.enganchar();
            });
        },

        elegir: function (opcion) {
            this.$emit('input', opcion.value);
            this.cerrar();
        },

        /* Se cierra al pulsar fuera. En `mousedown` y no en `click`: con click,
           elegir una opcion de otro desplegable abierto cerraba este despues de
           que el otro ya hubiera reaccionado. */
        fuera: function (ev) {
            if (!this.abierto) return;
            if (this.$el.contains(ev.target)) return;
            this.cerrar();
        },
    },

    mounted: function () {
        document.addEventListener('mousedown', this.fuera);
    },

    beforeDestroy: function () {
        document.removeEventListener('mousedown', this.fuera);
        this.desenganchar();
    },

    template: [
        '<div class="ogn-select">',
        '  <button type="button" class="ogn-select__control"',
        '    :class="{ \'ogn-select__control--on\': abierto }" @click="alternar">',
        '    <span class="ogn-select__value">{{ elegido }}</span>',
        '    <i class="fas fa-chevron-down"></i>',
        '  </button>',
        '  <div class="ogn-select__panel" v-if="abierto" :style="sitio">',
        '    <button type="button" class="ogn-select__option" v-for="o in options" :key="String(o.value)"',
        '      :class="{ \'ogn-select__option--on\': o.value === value }" @click="elegir(o)">',
        '      {{ o.label }}',
        '    </button>',
        '    <span class="ogn-select__vacio" v-if="!options.length">Sin opciones</span>',
        '  </div>',
        '</div>',
    ].join('\n'),
});

let app = new Vue({
    el: '#app',
    data() {
        return {
            visible: true,
            translations: [],
            swiper: null,
            modals: [],
            currentModal: null,
            /*  Cuántos cuadros de jQuery abiertos van como MENÚ PEQUEÑO
                (OpenModal con `chico`): mientras haya alguno, «Tu vivienda»
                se aparta (esta-tapado). */
            modalChico: 0,
            selectedKeyPlayers: [],

            gizmoMode: false,
            selectedShell: null,
            selectedExterior: null,

            allowedExtensions: [],

            controlsHelp: {
                visible: false,
                title: false,
                keysData: [],
            },

            info: {
                visible: false,
                text: '',
            },

            menu: {
                preview: {
                    visible: false,
                    title: '',
                    items: [],
                    path: '',
                    hidden: false,
                    itemLength: 0,
                },
                management: false,
                houses: {
                    visible: false,
                    list: {},
                }
            },

            furniture: {
                visible: false,
                minimized: false,
                defaultPrice: null,
                selectedOption: 'all',
                obra: null,          // herramientas y materiales de construir, en las casas de modalidad libre
                obraMaterial: 1,
                mode: 'normal',
                action: 'move',
                selectCategory: null,
                currentObject: false,
                selectedEntity: false,
                isMoving: false,
                categories: [],
                items: [],

                buyedItems: {},
                selectedObject: null,
            },

            loading: false,

            search: {
                house: {
                    value: '',
                },
                management: {
                    value: '',
                },
            },

            notifications: [],

            /*  La marca del servidor (origen o nacion) para el nombre del riel
                de los menus pequeños: «Origen Viviendas» / «Nación Viviendas».
                La pone el trozo «ORIGEN · marca» del index.html. */
            marca: document.documentElement.dataset.marca || 'origen',

            iteminfo: {
                title: '',
                price: 0,
                extra: ``, // html
            },

            exteriors: [],

            shells: {
                small: [],

                medium: [],

                big: [],
            },

            ipls: [],

            stages: [],

            houseList: [],

            house: {
                visible: false,
                swiper: null,
                data: [],
                currentTab: 'cameras',
                upgrades: {},
                doors: {},

                doorLimit: null,
                currentUpgrade: null,
            },

            creationData: {
                name: '',
                doors: [],
                data: {
                    price: 0,
                    number: 0,
                    type: 'shell',
                    interior_category: false,
                    allowVehicles: false,
                    hideBlip: false,
                    model: '',
                },
                positions: {},
                settings: {},
                construction: {
                    enabled: false,
                    model: '',
                    time: 0,
                    stage: 0,
                    coords: [],
                },
                exterior: [],
                useGarage: false,
            },

            buyMenu: false,

            /*  El panel de tu vivienda (menu lateral, 15/09): la seccion que
                enseña estrecho, si esta ampliado y la pregunta del pie. */
            /*  El menu de muebles: solo si esta ampliado. */
            muebles: {
                ancho: false,
            },

            vivienda: {
                seccion: 'llaves',
                ancho: false,
                confirmando: null,      // { mejora } | { estilo }
            },

            /*  La compra de una casa, en menu lateral (15/09). `casa` monta el
                panel; `confirmando` pone la pregunta en el pie en vez de abrir
                un cuadro encima; `saliendo` retiene el panel lo que dura la
                animacion de salida. */
            compra: {
                casa: null,
                garaje: null,
                confirmando: false,
                saliendo: false,
            },

            compraMueble: {
                visible: false,
                model: '',
                label: '',
                price: 0,
                priceText: '',
                paymentMethod: 'cash',
            },

            carrito: [],
            modalCarrito: false,
            carritoMetodoPago: 'cash',
            // En qué se paga en la casa en la que está: 'dinero', 'negro' (banda) u
            // 'ogn' (crew). Solo para pintar: cobra el servidor (custom/server/moneda.lua).
            // La pone js/propietario.js con { action: 'monedaCasa' }.
            monedaCasa: 'dinero',
            comprandoCarrito: false,

            mloBaseLimits: { stash: 3, wardrobe: 3 },
            mloSlotPrice: 5000,

            nuevoPuntoMlo: {
                visible: false,
                type: 'stash',
                name: 'Almacén',
            },

            upgrades: {
                visible: false,
                interval: null,
                title: '',
                item: '',
                info: {
                    visible: false,
                    title: '',
                    text: '',
                    position: 0,
                }
            },

            colors: {
                red: [255, 0, 0],
                green: [0, 255, 0],
                blue: [0, 0, 255],
                yellow: [255, 255, 0],
                orange: [255, 165, 0],
                purple: [128, 0, 128],
                pink: [255, 192, 203],
                white: [255, 255, 255],
                black: [0, 0, 0],
                brown: [165, 42, 42],
                cyan: [0, 255, 255],
                gray: [128, 128, 128],
                lime: [0, 255, 0],
                magenta: [255, 0, 255],
                olive: [128, 128, 0],
                silver: [192, 192, 192],
                teal: [0, 128, 128],
                gold: [255, 215, 0],
            },
            currentLight: null,

            isEditingName: false,
            editedName: '',

            isEditingURL: null,
            newUrl: '',

            elevator: {
                visible: false,
                currentFloor: null,
                floors: [],
            },

            currentPage: 1,
            itemsPerPage: 10,

            /* El nombre de la seccion del riel al pasar el raton, y a que
               altura sale. Ver el metodo `pista`. */
            pistaTexto: null,
            pistaY: 0,
            selectedMapHouse: null,

            hotels: {
                view: 'housing',
                list: {},
                selected: null,
                rooms: {},
                ipls: {},
                creating: false,
                editing: false,
                autoRenewSelected: false,

                /*  Lo elegido en el panel de la habitacion: el plazo que se
                    va a alquilar y la seccion del riel. La seccion se guarda
                    como "lo que pulso el jugador" y no como "la que se ve":
                    quien decide la que se ve es `habitacionTab`, que la
                    descarta sola si deja de existir. */
                opcionElegida: null,
                tabElegida: null,
                saliendoHabitacion: false,
                confirmandoHabitacion: null,
                creationData: {
                    name: '',
                    coords: { x: 0, y: 0, z: 0 },
                    reception_coords: { x: 0, y: 0, z: 0 },
                    blip: {
                        enabled: true,
                        sprite: 475,
                        color: 46,
                    },
                    rental_options: [],
                    auto_renew_available: true,
                    rooms: [],
                },
                roomCreationData: {
                    room_number: '',
                    door_coords: { x: 0, y: 0, z: 0, w: 0 },
                    interior_ipl: '',
                    stash_data: { slots: 50, weight: 100000 },
                },

                /*  ── El mostrador ────────────────────────────────────────
                    Lo que ve el jugador al pulsar E en recepción: un menú
                    lateral de los del servidor, riel y columna.

                    `filtro` es la sección del riel; `room`, la habitación
                    que se está mirando dentro de la columna —con null, lo
                    que hay en la columna es la lista—; `opcion`, el plazo
                    elegido antes de confirmar.

                    `abierto` y `saliendo` llevan la entrada y la salida: el
                    panel se queda montado los 280 ms que dura la salida, y
                    `saliendo` evita que dos Escape seguidos lancen dos
                    cierres. Ver .claude/skills/origen-riel/SKILL.md */
                reception: {
                    abierto: false,
                    saliendo: false,
                    hotel: null,
                    rooms: [],
                    filtro: 'todas',
                    room: null,
                    opcion: null,
                    confirmando: null,
                },
            },
        }
    },

    computed: {
        nombreDeMarca() {
            return this.marca === 'nacion' ? 'Nación' : 'Origen';
        },
        /*  «Mis casas» llega como objeto o como lista segun el Lua. */
        numeroDeMisCasas() {
            const l = this.menu.houses.list;
            return l ? Object.keys(l).length : 0;
        },
        /*  Hay un menu pequeño en pantalla: suena al abrirse, como los demas. */
        hayMenuPequeno() {
            return !!(this.modalCarrito || this.compraMueble.visible || this.nuevoPuntoMlo.visible || this.menu.houses.visible);
        },
        totalCarrito() {
            if (!this.carrito || !this.carrito.length) return 0;
            return this.carrito.reduce((acc, it) => acc + (Number(it.price) || 0), 0);
        },
        /*  ── El armazon del panel de la casa ──────────────────────────

            Las pestañas de Mejoras y Camaras eran una tira de pastillas
            flotando en mitad de la columna del medio. Son la navegacion de
            esta pantalla, asi que van al riel, que es donde va la navegacion
            en todos los paneles del servidor.

            La de mejoras solo existe en las casas de interior con estilos:
            en las demas no hay nada que enseñar ahi. */
        /*  Las secciones del riel de tu vivienda, con su contador. */
        seccionesVivienda() {
            const d = this.house.data;
            if (!d) return [];
            const t = this.translations;
            const cuenta = (o) => Object.values(o || {}).filter(Boolean).length;
            const mejoras = Object.values(this.house.upgrades || {});
            const s = [
                { id: 'llaves', icono: 'fa-key', nombre: t.keysManagement || 'Llaves', n: Object.values(d.holders || {}).filter((h) => h && h.name).length },
                { id: 'puertas', icono: 'fa-door-open', nombre: t.doors || 'Puertas', n: cuenta(d.doors) },
                { id: 'mejoras', icono: 'fa-shield-halved', nombre: t.upgrades || 'Mejoras', n: mejoras.filter((m) => m && !m.locked).length + '/' + mejoras.length },
                { id: 'luces', icono: 'fa-lightbulb', nombre: t.lights || 'Luces', n: d.lightsCount || 0 },
                { id: 'cuadros', icono: 'fa-image', nombre: t.personalizeBoard || 'Cuadros', n: d.boardsCount || 0 },
                { id: 'camaras', icono: 'fa-video', nombre: t.cameras || 'Cámaras', n: cuenta(d.cameras) },
            ];
            if (d.data && d.data.type === 'mlo') {
                const puntosCount = Object.keys(d.positions && d.positions.points || {}).length;
                s.push({ id: 'puntos', icono: 'fa-location-dot', nombre: 'Puntos MLO', n: puntosCount });
            }
            // Entradas (custom/client/entradas.lua): dónde aparece quien entra, a pie y con vehículo
            if (d.entradas) s.push({ id: 'entradas', icono: 'fa-right-to-bracket', nombre: 'Entradas' });      // (fa-door-open ya es el de Puertas)
            if (this.tieneEstilosLaCasa) s.push({ id: 'estilo', icono: 'fa-paint-roller', nombre: t.upgradesBtn || 'Estilo' });
            return s;
        },

        nombreDeSeccionVivienda() {
            const s = this.seccionesVivienda.find((x) => x.id === this.vivienda.seccion);
            return s ? s.nombre : '';
        },

        tieneEstilosLaCasa() {
            const d = this.house.data;
            return !!(d && d.data && d.data.type === 'ipl' && d.data.style && this.ipls[d.data.model]);
        },

        avisoVivienda() {
            const c = this.vivienda.confirmando;
            if (!c) return '';
            if (c.estilo !== undefined) {
                const e = this.tieneEstilosLaCasa && this.ipls[this.house.data.data.model].list[c.estilo];
                return (e ? e.label + ' · ' + this.precio(e.price) + ' — ' : '') + (this.translations.houseupgraadeInfo || '');
            }
            const m = this.house.upgrades[c.mejora];
            return (m ? m.label + ' · ' + this.precio(m.price) + ' — ' : '') + (this.translations.buyUpgradeDesc || '');
        },

        seccionesDeLaCasa() {
            const d = this.house.data;
            if (!d) return [];

            const secciones = [];
            if (d.data && d.data.type === 'ipl' && d.data.style && this.ipls[d.data.model]) {
                secciones.push({
                    id: 'upgrades',
                    icono: 'fa-paint-roller',
                    nombre: this.translations.upgradesBtn || 'Mejoras',
                });
            }
            secciones.push({
                id: 'cameras',
                icono: 'fa-video',
                nombre: this.translations.cameras || 'Cámaras',
            });
            return secciones;
        },

        /*  Las cifras del pie de la casa. Debajo de las columnas quedaba una
            franja de pantalla vacia, y todo esto habia que contarlo a ojo
            mirando las listas. */
        cifrasDeLaCasa() {
            const d = this.house.data;
            if (!d) return [];

            const llaves = Object.values(d.holders || {}).filter((h) => h && h.name).length;
            const puertas = Object.values(d.doors || {}).filter(Boolean).length;

            /* `locked` es «todavia se compra»; lo adquirido es lo que no lo
               esta. Ver la ficha de mejoras de la columna derecha. */
            const mejoras = Object.values(this.house.upgrades || {});
            const compradas = mejoras.filter((m) => m && !m.locked).length;

            return [
                { k: this.translations.keys || 'Llaves', v: String(llaves) },
                { k: this.translations.lights || 'Luces', v: String(d.lightsCount || 0) },
                { k: this.translations.boards || 'Cuadros', v: String(d.boardsCount || 0) },
                { k: this.translations.doors || 'Puertas', v: puertas + ' / ' + (this.house.doorLimit || 0) },
                { k: this.translations.upgradesBtn || 'Mejoras', v: compradas + ' / ' + mejoras.length },
            ];
        },

        /*  ── El armazon de la tablet ──────────────────────────────────

            Las secciones son el riel del canto izquierdo, no unas pastillas
            en la cabecera: es la navegacion del panel y va donde va en todos
            los paneles del servidor. Ver la skill origen-tablet. */
        seccionesDelRiel() {
            return [
                { id: 'housing', icono: 'fa-home',  nombre: this.translations.housing || 'Viviendas' },
                { id: 'hotels',  icono: 'fa-hotel', nombre: this.translations.hotelLabel || 'Hoteles' },
                { id: 'map',     icono: 'fa-map',   nombre: this.translations.map || 'Mapa' },
            ];
        },

        /* 'list' es un alias historico de 'housing'. */
        seccionActual() {
            return this.hotels.view === 'list' ? 'housing' : this.hotels.view;
        },

        /*  El antetitulo dice DONDE estas —en que panel— y el titulo dice QUE
            seccion es. Puestos los dos a decir la seccion salia «HOUSING /
            HOUSING», que es el mismo dato dos veces con dos cuerpos de letra
            distintos. */
        anteTituloPanel() {
            return 'Gestión de vivienda';
        },

        tituloPanel() {
            if (this.hotels.creating) return this.tituloDelFormulario;
            if (this.seccionActual === 'hotels') return this.translations.hotelLabel || 'Hoteles';
            if (this.seccionActual === 'map') return this.translations.map || 'Mapa';
            return this.translations.housing || 'Viviendas';
        },

        /*  Las cifras del pie. Solo lo que se puede contar de verdad: nada de
            rellenar la barra con celdas que digan cero para siempre. */
        cifrasDelPie() {
            const hoteles = Object.values(this.hotels.list || {}).filter(Boolean);
            let habitaciones = 0;
            let alquiladas = 0;
            for (const h of hoteles) {
                if (!h.stats) continue;
                habitaciones += Number(h.stats.total) || 0;
                alquiladas += Number(h.stats.rented) || 0;
            }

            const casas = Object.values(this.houseList || {}).filter(Boolean);
            const conDueno = casas.filter((c) => c && c.citizenid).length;

            /* Rotulos propios y no los de las secciones: «HOUSING 3» no dice
               que son tres viviendas, dice el nombre de una pestaña. */
            return [
                { k: this.translations.statHouses || 'Viviendas', v: String(casas.length) },
                { k: this.translations.statOwned || 'Con dueño', v: conDueno + ' / ' + casas.length },
                { k: this.translations.statHotels || 'Hoteles', v: String(hoteles.length) },
                { k: this.translations.statRooms || 'Habitaciones', v: habitaciones ? (alquiladas + ' / ' + habitaciones) : '0' },
            ];
        },

        /*  Que estas editando, para la franja de arriba. En el formulario se
            esconden la busqueda y las secciones, y esa franja se quedaba
            vacia de lado a lado sin decir de que hotel era el formulario. */
        tituloDelFormulario() {
            if (this.hotels.view === 'room_creation') {
                return this.translations.newRoom || 'Habitación nueva';
            }
            if (this.hotels.editing) {
                const nombre = (this.hotels.creationData && this.hotels.creationData.name) || '';
                const rotulo = this.translations.editingHotel || 'Editando';
                return nombre ? (rotulo + ' · ' + nombre) : rotulo;
            }
            return this.translations.newHotel || 'Hotel nuevo';
        },

        /* Los interiores, para el desplegable propio: llegan como un objeto y
           el componente pide una lista de {value, label}. */
        opcionesInterior() {
            const ipls = this.hotels && this.hotels.ipls ? this.hotels.ipls : {};
            return Object.keys(ipls).map((clave) => ({ value: clave, label: ipls[clave].label }));
        },

        /*  ── El mostrador ────────────────────────────────────────────────

            Las dos cifras de la cabecera: cuántas habitaciones tiene el
            hotel y cuántas quedan libres. */
        cifrasDeLaRecepcion() {
            const rooms = this.hotels.reception.rooms || [];
            return {
                total: rooms.length,
                libres: rooms.filter(function (r) { return r.status === 'available'; }).length,
            };
        },

        /*  Las secciones del riel. Cada una lleva su contador en el globito:
            una pestaña que no dice cuánto hay dentro obliga a entrar para
            averiguarlo. */
        seccionesDeRecepcion() {
            const rooms = this.hotels.reception.rooms || [];
            const t = this.translations;

            const secciones = [
                { id: 'todas', icono: 'fa-bed', nombre: t.allRooms || 'Todas', n: rooms.length },
                { id: 'libres', icono: 'fa-door-open', nombre: t.freeRooms || 'Libres', n: rooms.filter(function (r) { return r.status === 'available'; }).length },
                { id: 'ocupadas', icono: 'fa-door-closed', nombre: t.occupiedRooms || 'Ocupadas', n: rooms.filter(function (r) { return r.status !== 'available'; }).length },
            ];

            /*  La tuya solo sale si la tienes: una sección que siempre marca
                cero no dice nada y ocupa un botón. */
            const mias = rooms.filter(function (r) { return r.mine; });
            if (mias.length) {
                secciones.push({ id: 'mia', icono: 'fa-key', nombre: t.yours || 'Tuya', n: mias.length });
            }

            return secciones;
        },

        /*  ── El panel de la habitacion, en la puerta ─────────────────

            Es el mismo menu lateral que el mostrador, abierto en la puerta
            en vez de en recepcion, asi que las secciones van al riel igual
            que alli. Lo que se enseña depende de quien mira:

              - libre: el plazo que se quiere alquilar;
              - tuya: la puerta, el contrato y lo que puedes hacer con ella;
              - de otro: la puerta, y solo si esta abierta. Si esta cerrada
                no hay ninguna seccion y el cuerpo dice lo unico que hay que
                decir, que esta ocupada. */
        seccionesDeLaHabitacion() {
            const r = this.hotels.roomCreationData;
            if (!r) return [];

            const t = this.translations;

            if (r.status === 'available') {
                return [{ id: 'alquilar', icono: 'fa-key', nombre: t.rentalOptions }];
            }

            if (this.soyElInquilino) {
                return [
                    { id: 'puerta', icono: 'fa-lock', nombre: t.doorAccess },
                    { id: 'alquiler', icono: 'fa-file-invoice-dollar', nombre: t.rentalDetails },
                    { id: 'acciones', icono: 'fa-sliders', nombre: t.roomActions },
                ];
            }

            /*  Con la puerta abierta se puede entrar aunque no sea tuya; con
                el pestillo echado no hay nada que ofrecer. */
            if (r.door_locked == 0) {
                return [{ id: 'puerta', icono: 'fa-door-open', nombre: t.enter }];
            }

            return [];
        },

        /*  La seccion que se ve. Sale de lo que pulso el jugador, pero SOLO
            si sigue existiendo: al echar el pestillo o al dejar la
            habitacion, la seccion en la que estabas desaparece, y sin esto
            el cuerpo se quedaba en blanco sin nada que lo explicara. */
        habitacionTab() {
            const secciones = this.seccionesDeLaHabitacion;
            if (!secciones.length) return null;

            const elegida = this.hotels.tabElegida;
            const sigue = secciones.some(function (s) { return s.id === elegida; });

            return sigue ? elegida : secciones[0].id;
        },

        /*  `rented_by` solo llega cuando la habitacion es de quien mira: el
            cliente lo borra para los demas. Ver Nui.OpenRoomDetailPanel. */
        soyElInquilino() {
            const r = this.hotels.roomCreationData;
            return !!(r && r.status === 'rented' && r.rented_by);
        },

        /*  El renglon de la cabecera. Dice de un vistazo en que estado esta
            la habitacion, que es lo que se viene a mirar a una puerta. */
        subtituloDeLaHabitacion() {
            const r = this.hotels.roomCreationData;
            if (!r) return '';

            const t = this.translations;

            /*  Libre: lo que se quiere saber de un vistazo es cuanto cuesta
                lo mas barato, no que hay opciones —eso ya lo dice la lista
                que hay debajo—. */
            if (r.status === 'available') {
                const opciones = (this.hotels.selected && this.hotels.selected.rental_options) || [];
                if (!opciones.length) return t.available;

                const barato = opciones.reduce(function (a, b) { return b.price < a.price ? b : a; });
                return (t.fromPrice || 'Desde') + ' ' + this.precio(barato.price);
            }

            if (this.soyElInquilino) return t.expires + ' ' + this.formatDate(r.expires_at);

            /*  De otro: el estado del pestillo, que es lo unico que le afecta
                a quien esta delante. Que esta ocupada ya lo dice el cuerpo, y
                escrito dos veces en la misma pantalla se lee como un fallo. */
            return r.door_locked == 0 ? t.open : t.closed;
        },

        /*  Sin plazo elegido el boton no dice un precio que todavia no hay:
            dice que falta elegir. */
        textoDelBotonDeAlquiler() {
            const o = this.hotels.opcionElegida;
            const t = this.translations;

            if (!o) return t.selectPlan || 'Elige un plazo';
            return (t.rentRoomTitle || 'Alquilar') + ' · ' + this.precio(o.price);
        },

        /*  El botón del pie dice con qué se va a pagar antes de pulsarlo.
            Sin plazo elegido no se apaga en gris: se queda de borde
            diciendo qué falta, porque no es un botón roto, es un botón que
            todavía no tiene a qué aplicarse. */
        textoDelBotonAlquilar() {
            const o = this.hotels.reception.opcion;
            if (!o) return this.translations.selectPlan || 'Elige un plazo';
            return (this.translations.rentRoomTitle || 'Alquilar') + ' · ' + this.precio(o.price);
        },

        habitacionesDeRecepcion() {
            const rooms = this.hotels.reception.rooms || [];
            const filtro = this.hotels.reception.filtro;

            if (filtro === 'libres') return rooms.filter(function (r) { return r.status === 'available'; });
            if (filtro === 'ocupadas') return rooms.filter(function (r) { return r.status !== 'available'; });
            if (filtro === 'mia') return rooms.filter(function (r) { return r.mine; });
            return rooms;
        },

        totalPages() {
            return Math.ceil(this.filteredHouses.length / this.porPagina());
        },
        filteredHouses() {
            const search = this.search.management.value;
            if (!search) return Object.values(this.houseList).filter(item => item !== null && item !== undefined);
            return Object.values(this.houseList).filter(
                item => item !== null &&
                    item !== undefined &&
                    (item.name.toLowerCase().includes(search.toLowerCase()) ||
                        (item.citizenid && item.citizenid.toLowerCase().includes(search.toLowerCase())) ||
                        (item.data && item.data.type && item.data.type.toLowerCase().includes(search.toLowerCase())) ||
                        (item.data && item.data.location && item.data.location.toLowerCase().includes(search.toLowerCase())))
            );
        },
        paginatedHouses() {
            const total = this.totalPages;
            let page = this.currentPage;
            if (page > total && total > 0) {
                Vue.nextTick(() => { this.currentPage = total; });
                page = total;
            }
            if (page == 0 && this.filteredHouses.length > 0) {
                Vue.nextTick(() => { this.currentPage = 1; });
                page = 1;
            }
            const start = (page - 1) * this.porPagina();
            const end = start + this.porPagina();
            return this.filteredHouses.slice(start, end);
        },
        paginatedHotels() {
            const search = this.search.management.value;
            const filteredHotels = Object.values(this.hotels.list).filter(hotel => {
                if (!hotel) return false;
                if (!search) return true;
                return hotel.name.toLowerCase().includes(search.toLowerCase()) ||
                    (hotel.coords.x + ', ' + hotel.coords.y).includes(search);
            });
            return filteredHotels;
        },
    },

    methods: {
        /*  El nombre de la sección del riel, al pasar el ratón.

            Sale FUERA del riel para no tener que ensancharlo, y va `fixed`
            con el `top` sacado del botón: colgada del botón la recortaría el
            `overflow` de la navegación. Ver la skill origen-tablet. */
        pista: function (texto, evento) {
            if (!texto) { this.pistaTexto = null; return; }
            const r = evento && evento.currentTarget && evento.currentTarget.getBoundingClientRect();
            this.pistaY = r ? Math.round(r.top + r.height / 2) : 0;
            this.pistaTexto = texto;
        },

        setDefaultImage: function (event) {
            event.target.src = './img/default.png';
        },
        getImageUrl: function (name) {
            if (!this.house.data || !this.ipls[this.house.data.data.model]) return;

            if (this.ipls[this.house.data.data.model]) {
                return './img/ipls/' + this.ipls[this.house.data.data.model].prefix + '_' + name + '.png';
            }

            return './img/ipls/' + this.house.data.data.model + '_' + name + '.png';
        },
        isValidImageUrl(url) {
            const pattern = new RegExp(`\\.(${this.allowedExtensions.join('|')})$`, 'i');
            try {
                new URL(url);
                return pattern.test(url);
            } catch (_) {
                return false;
            }
        },

        copyClipboard: function (text) {
            const input = document.createElement('input');
            input.value = text;
            document.body.appendChild(input);
            input.select();
            document.execCommand('copy');
            document.body.removeChild(input);
        },

        createHouse: function (house) {
            this.resetCreationData();
            this.OpenModal(
                house ? app.translations.editHouse : app.translations.createHouse,
                `
                <div class="row mb-4 create-house">
                    <div class="col-12">
                        <h5 class="mt-4">${app.translations.houseName}</h5>
                        <input type="text" class="form-control w-100 input-house-name" placeholder="${app.translations.name}">
                    </div>
                    <div class="col-6">
                        <h5 class="mt-4">${app.translations.houseNumber}</h5>
                        <input type="number" min="000" max="999" class="form-control w-100 input-house-number" placeholder="${app.translations.number}">
                    </div>
                    <div class="col-6">
                        <h5 class="mt-4">${app.translations.housePrice}</h5>
                        <input type="number" class="form-control w-100 input-house-price" placeholder="${app.translations.price}">
                    </div>`+
                (house ? '' : `
                        <h4 class="mt-4">${app.translations.houseType}</h4>
                        <div class="col-12 d-flex align-items-center justify-content-start house_types mt-2">
                            <div class="btn option" type="shell">
                                <i class="fa fa-house-chimney-window"></i>
                                <span>Módulo</span>
                            </div>
                            <div class="btn option" type="libre">
                                <i class="fa-solid fa-cubes"></i>
                                <span>Libre</span>
                            </div>
                            <div class="btn option" type="ipl">
                                <i class="fa-solid fa-tent-arrows-down"></i>
                                <span>IPL</span>
                            </div>
                            <div class="btn option" type="mlo">
                                <i class="fa-solid fa-house"></i>
                                <span>MLO</span>
                            </div>
                        </div>
                        <div class="mt-4 col-12 int_categories">
                            <h4>${app.translations.interiors}</h4>
                            <span class="desc mb-2">${app.translations.defineInterior}</span>
                            <div class="d-flex align-items-center justify-content-start interior_categories mt-2">
                                <div class="btn option active" type="small">
                                    <i class="fa-solid fa-box-open"></i>
                                    <span>${app.translations.small}</span>
                                </div>
                                <div class="btn option" type="medium">
                                    <i class="fa-solid fa-house"></i>
                                    <span>${app.translations.medium}</span>
                                </div>
                                <div class="btn option" type="big">
                                    <i class="fa-solid fa-house-medical"></i>
                                    <span>${app.translations.big}</span>
                                </div>
                            </div>
                        </div>
                    `) + `
                    <div class="mt-4 col-12 payment-method">
                        <h4>${app.translations.paymentMethod}</h4>
                        <span class="desc">${app.translations.paymentMethodDesc}</span>
                        <div class="d-flex align-items-center justify-content-start payment-method mt-2">
                            ${Object.keys(app.paymentMethods).map((method) => `
                                <div class="btn option ${method == 'cash' ? 'active' : ''}" type="${method}">
                                    <i class="${app.paymentIcon(method)}"></i>
                                    <span>${app.translations[method] || method}</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                    ` + (!house ? `
                        <div class="construction-content mt-4">
                            <h4>${app.translations.constructionOptions}</h4>
                            <div class="col-12 mt-3">
                                <div class="check">
                                    <label class="switch">
                                        <input type="checkbox" class="check-construction">
                                        <span class="slider round"></span>
                                    </label>
                                </div>
                            </div>
                            <div class="construction-options" style="display: none;">
                                <div class=" mt-3 ">
                                    <div class="row">
                                        <div class="col-12">
                                            <div class="box-option">
                                                <i class="fa-solid fa-clock"></i>
                                                <input type="number" min="000" max="999" class="w-100 input-construction-time" placeholder="${app.translations.time}">
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    ` : '') + `

                    <div class="row mt-4">
                        <div class="col-6">
                            <h4>${app.translations.useGarage}</h4>
                            <span class="desc">${app.translations.useGarageDesc}</span>
                            <div class="check mt-2">
                                <label class="switch">
                                    <input type="checkbox" class="check-use-garage">
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>
                        <div class="col-6">
                            <h4>${app.translations.hideOnMap}</h4>
                            <span class="desc">${app.translations.hideOnMapDesc}</span>
                            <div class="check mt-2">
                                <label class="switch">
                                    <input type="checkbox" class="check-blip">
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>
                    </div>

                    <div class="col-6 allow-vehicles mt-4">
                        <h4>${app.translations.allowVehicles}</h4>
                        <span class="desc mb-2">${app.translations.allowVehiclesDesc}</span>
                        <div class="check mt-2">
                            <label class="switch">
                                <input type="checkbox" class="check-allowvehicles">
                                <span class="slider round"></span>
                            </label>
                        </div>
                    </div>

                    <div class="row mt-4" style="display: ${house ? 'flex' : 'none'}">
                        <div class="col-4 reposition-zone">
                            <h4>${app.translations.repositionZone}</h4>
                            <span class="desc mb-2">${app.translations.repositionZoneDesc}</span>
                            <div class="check mt-2">
                                <label class="switch">
                                    <input type="checkbox" class="check-reposition-zone">
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>

                        <div class="col-4 reposition-entry-point">
                            <h4>${app.translations.repositionEntryPoint}</h4>
                            <span class="desc mb-2">${app.translations.repositionEntryPointDesc}</span>
                            <div class="check mt-2">
                                <label class="switch">
                                    <input type="checkbox" class="check-reposition-entry-point">
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>

                        <div class="col-4 reposition-garage-point">
                            <h4>${app.translations.repositionGaragePoint}</h4>
                            <span class="desc mb-2">${app.translations.repositionGaragePointDesc}</span>
                            <div class="check mt-2">
                                <label class="switch">
                                    <input type="checkbox" class="check-reposition-garage-point">
                                    <span class="slider round"></span>
                                </label>
                            </div>
                        </div>
                    </div>

                    ` + (house ? `
                        <div class="col-12 mt-4 holder-list">
                            <div class="d-flex align-items-center justify-content-between">
                                <div class="d-flex flex-column">
                                    <h4>${app.translations.holderList}${house.llaves && house.llaves.texto ? ' · ' + house.llaves.texto : ''}</h4>
                                    <span class="desc mb-2">${app.translations.holderListDesc}</span>
                                </div>
                                <button class="btn-action danger" onclick="app.deleteAllHolders('${house.id}')">
                                    <i class="fas fa-trash"></i>
                                    <span>${app.translations.removeAll}</span>
                                </button>
                            </div>
                            ` + (house.holders && Object.entries(house.holders) ? `                           
                                <div class="holders-container mt-3">
                                    ${(() => {
                            const sortedHolders = Object.entries(house.holders).sort((a, b) => {
                                if (a[1].owner) return -1;
                                if (b[1].owner) return 1;
                                return 0;
                            });

                            return sortedHolders.map(([citizenid, data]) => `
                                            <div class="holder-item d-flex align-items-center justify-content-between mb-2">
                                                <div class="d-flex align-items-center">
                                                    <i class="fas ${data.owner ? 'fa-crown' : 'fa-user'} me-2"></i>
                                                    <span class="holder-name">${data.name} - ${citizenid}</span>
                                                </div>
                                                <button class="btn-action danger" onclick="app.deleteHolder('${house.id}', '${citizenid}')">
                                                    <i class="fas fa-trash"></i>
                                                </button>
                                            </div>
                                        `).join('');
                        })()}
                                </div>
                            ` : '') + `
                        </div>
                    ` : '') + `
                </div>
                `,
                `<button class="btn-modal" onclick='app.SaveHouse(${house ? true : false})'>${house ? app.translations.save : app.translations.accept}</button>`,
                app.translations.close,
                70
            );

            $(".check-construction").trigger('change');
            $('.house_types .btn.option').removeClass('active');
            $(`.house_types .btn.option[type="${house?.data?.type || this.creationData.data.type}"]`).addClass('active');

            if (house) {
                $('.input-house-name').val(house.name)
                $('.input-house-number').val(house.data.number)
                $('.input-house-price').val(house.data.price)
                $(".check-construction").prop('checked', house.construction.enabled);
                $('.interior_categories .btn.option').removeClass('active');
                $('.payment-method .btn.option').removeClass('active');
                $('.payment-method .btn.option[type=' + house.data.paymentMethod + ']').addClass('active');
                $('.interior_categories .btn.option[type=' + (house.data.interior_category) + ']').addClass('active');
                if (house.construction.enabled) {
                    $(".check-construction").trigger('change');
                    $('.input-construction-time').val(house.construction.time)
                }
                $(".check-use-garage").prop('checked', house.garage == 'none' ? false : true);
                $(".check-blip").prop('checked', house.data.hideBlip);
                $(".check-allowvehicles").prop('checked', house.data.allowVehicles);
                this.creationData = house
            }
        },

        deleteHolder: function (houseID, citizenid) {
            TriggerCallback('origen_housing:server:editHolders', { houseID: houseID, citizenid: citizenid, action: 'delete' }).then((data) => {
                if (data === true) {
                    this.sendNotification('success', app.translations.holderDeleted, '', true);
                    this.CloseModal();
                    this.createHouse(this.houseList[houseID]);
                    // Scroll to bottom of the modal
                    setTimeout(() => {
                        const modal = document.querySelector('.modal-body');
                        modal.scrollTo({
                            top: modal.scrollHeight,
                            behavior: 'smooth'
                        });
                    }, 500);
                }
            });
        },

        deleteAllHolders: function (houseID) {
            TriggerCallback('origen_housing:server:editHolders', { houseID: houseID, action: 'deleteAll' }).then((data) => {
                if (data === true) {
                    this.sendNotification('success', app.translations.allHoldersDeleted, '', true);
                    this.CloseModal();
                }
            });
        },

        SaveHouse: function (house) {
            const name = $('.input-house-name').val();
            const price = parseFloat($('.input-house-price').val());
            const number = parseInt($('.input-house-number').val());
            // «Libre» es un módulo cuyo interior excava el jugador (config/obra.lua):
            // para el resto del housing es una casa de módulo con el ancla por modelo.
            const elegido = $('.create-house .house_types .option.active').attr('type');
            const libre = elegido === 'libre';
            const type = libre ? 'shell' : elegido;
            const interior_category = libre ? 'small' : ((type === 'shell' && $('.create-house .interior_categories .option.active').attr('type')) || false);
            const construction = (type !== 'mlo' && $('.check-construction').prop('checked')) || false;
            const construction_time = parseFloat($('.input-construction-time').val()) || 0;
            const doors = [];
            const vehicles = (type !== 'mlo' && $('.check-allowvehicles').prop('checked')) || false;
            const hideBlip = $('.check-blip').prop('checked');
            const minTime = Object.keys(this.stages).length
            const useGarage = $('.check-use-garage').prop('checked');
            const paymentMethod = $('.create-house .payment-method .option.active').attr('type');

            if (!house) {
                this.creationData.positions = {};
                this.creationData.exterior = {};
            }

            if (!name) {
                this.sendNotification('error', this.translations.error, this.translations.notyHouseNameNeed);
                return;
            }

            if (isNaN(price) || price < 0) {
                this.sendNotification('error', this.translations.error, this.translations.notyHousePriceNeed);
                return;
            }

            if (isNaN(number) || number < 0) {
                this.sendNotification('error', this.translations.error, this.translations.notyHouseNumberNeed);
                return;
            }

            if (construction) {
                if (isNaN(construction_time) || construction_time < minTime) {
                    this.sendNotification('error', this.translations.error, this.translations.notyHouseConstructionTimeNeed.replace('%s', minTime));
                    return;
                }
                this.creationData.construction.time = construction_time;
            }

            // de quién es la casa (particular, de banda, de crew), al crear y al editar: js/propietario.js
            if (window.OgnPropietario && !window.OgnPropietario.alGuardar(this.creationData.data)) return;

            if (!house) {
                this.creationData.data.interior_category = interior_category;
                this.creationData.data.type = type;
                this.creationData.data.libre = libre;
                if (libre) this.creationData.data.model = 'origen_casa_ancla';
                // el tamaño (modalidad Libre) y los packs con los que nace la casa: js/packs.js
                if (window.OgnPacks) window.OgnPacks.alGuardar(this.creationData.data, libre);

                this.creationData.doors = doors;
                this.creationData.construction.enabled = construction;
            }

            this.creationData.name = name;
            this.creationData.data.price = price;
            this.creationData.data.number = number;
            this.creationData.data.paymentMethod = paymentMethod;
            this.creationData.data.allowVehicles = vehicles;
            this.creationData.data.hideBlip = hideBlip;
            this.creationData.useGarage = useGarage;

            if (house) {
                const reposition = {
                    zone: $('.check-reposition-zone').prop('checked'),
                    entryPoint: $('.check-reposition-entry-point').prop('checked'),
                    garagePoint: $('.check-reposition-garage-point').prop('checked')
                }

                this.menu.management = false;
                this.CloseModal();
                fetch('close', {});

                TriggerCallback('origen_housing:server:editHouse', { house: this.creationData, reposition: reposition, houseID: this.creationData.id }).then((data) => {
                    if (data === true) {
                        this.sendNotification('success', this.translations.notyHouseEditedTitle, this.translations.notyHouseEditedMessage, true);
                    } else {
                        this.sendNotification('error', this.translations.error, data.message, true);
                    }
                });
                return;
            }

            this.menu.management = false;
            this.CloseModal();
            if (type == 'mlo') {
                TriggerCallback('origen_housing:server:createHouse', { house: this.creationData }).then((data) => {
                    if (data === true) {
                        this.sendNotification('success', this.translations.notyHouseCreatedTitle, this.translations.notyHouseCreatedMessage, true);
                    } else {
                        this.sendNotification('error', this.translations.error, data.message, true);
                    }
                });
            } else if (type == 'ipl' && !construction) {
                TriggerCallback('origen_housing:server:createHouse', { house: this.creationData }).then((data) => {
                    if (data === true) {
                        this.sendNotification('success', this.translations.notyHouseCreatedTitle, this.translations.notyHouseCreatedMessage, true);
                    } else {
                        this.sendNotification('error', this.translations.error, data.message, true);
                    }
                });
            } else {
                if (construction) {
                    this.previewOptions(this.exteriors, 'exteriors', app.translations.selectExterior, true);
                } else {
                    if (!house) {
                        let items = [];
                        let path = '';
                        let title = '';
                        switch (type) {
                            case 'shell':
                                const shellCategories = interior_category || 'small';
                                path = 'shell';
                                title = app.translations.selectShell;
                                items = this.shells[shellCategories];
                                break;
                        }

                        this.previewOptions(items, path, title);
                    } else {
                        TriggerCallback('origen_housing:server:createHouse', { house: this.creationData }).then((data) => {
                            if (data === true) {
                                this.sendNotification('success', this.translations.notyHouseCreatedTitle, this.translations.notyHouseCreatedMessage, true);
                            } else {
                                this.sendNotification('error', this.translations.error, data.message, true);
                            }
                        });
                    }
                }
            }
        },

        resetCreationData: function () {
            this.creationData = {
                name: '',
                doors: [],
                data: {
                    price: 0,
                    number: 0,
                    type: 'shell',
                    interior_category: false,
                    allowVehicles: false,
                    hideBlip: false,
                    model: '',
                },
                positions: {},
                settings: {},
                construction: {
                    enabled: false,
                    model: '',
                    time: 0,
                    stage: 0,
                    coords: [],
                },
                exterior: [],
                useGarage: false,
            };
        },

        /*  ══ La compra de una casa ════════════════════════════════════════

            Antes eran dos cuadros centrados, uno encima del otro: la ficha y
            la pregunta de «¿seguro?». Ahora es un menu lateral de los del
            servidor, con las clases `rp-` de la recepcion del hotel (ver
            index.html), y la pregunta va en el pie del mismo panel, como
            «Abandonar» en la habitacion. Ver .claude/skills/origen-riel/SKILL.md

            Todos los cierres pasan por `cerrarCompra`: Escape, el clic fuera,
            el boton y la compra hecha. El foco se suelta YA (closeBuyHouse) y
            el panel se desmonta a los 280 ms, cuando acaba de irse. */
        buyHouse: function (house, garage) {
            this.buyMenu = true;
            this.compra.casa = house;
            this.compra.garaje = garage || null;
            this.compra.confirmando = false;
            this.compra.saliendo = false;
            Sonido.deslizar();
        },

        cerrarCompra: function () {
            if (this.compra.saliendo || !this.compra.casa) return;
            this.compra.saliendo = true;
            this.buyMenu = false;

            Sonido.deslizar();
            this.closeBuyHouse();

            setTimeout(() => {
                //  Si en estos 280 ms se ha abierto otra casa, `buyHouse` ha
                //  bajado la bandera: lo que hay ahora es el panel nuevo.
                if (!this.compra.saliendo) return;
                this.compra.casa = null;
                this.compra.garaje = null;
                this.compra.confirmando = false;
                this.compra.saliendo = false;
            }, 280);
        },

        closeBuyHouse: function () {
            fetch('closeBuyHouse', {});
        },

        pedirCompra: function () {
            Sonido.pulsar();
            this.compra.confirmando = true;
        },

        cancelarCompra: function () {
            Sonido.pulsar();
            this.compra.confirmando = false;
        },

        confirmarCompra: function () {
            const casa = this.compra.casa;
            if (!casa) return;
            TriggerCallback('origen_housing:server:buyHouse', { houseID: casa.id }).then((data) => {
                if (data === true) {
                    this.sendNotification('success', this.translations.buyHouseSuccess, '', true);
                    this.cerrarCompra();
                } else {
                    this.sendNotification('error', this.translations.error, data && data.message, false);
                    this.compra.confirmando = false;
                }
            });
        },

        /*  Visitar: Lua suelta el foco y mete al jugador en la casa; aqui solo
            se recoge el panel. */
        visitarCasa: function () {
            const casa = this.compra.casa;
            if (!casa) return;
            fetch('visitHouse', { houseID: casa.id });
            this.cerrarCompra();
        },

        markPosition: function (houseID, event) {
            event.stopPropagation();
            fetch('markHousePosition', {
                id: houseID
            }).then((data) => {
                if (data) {
                    this.sendNotification('success', app.translations.markPosition, '', true);
                } else {
                    this.sendNotification('error', app.translations.errorMarkPosition, '', true);
                }
            })
        },

        togglePreviewOpacity: function (state) {
            this.menu.preview.hidden = state;
        },

        previewOptions: function (items, path, title) {
            if (!items) return;
            this.menu.preview.visible = true;
            this.menu.preview.items = items;
            this.menu.preview.title = title;
            this.menu.preview.path = path;
            this.menu.preview.itemLength = typeof items === 'object' ? Object.keys(items).length : items.length;

            if (this.swiper) {
                this.swiper.destroy();
            }

            if (path == 'exteriors' || path == 'shell') {
                this.ControlsNotify([
                    { key: 'E', text: this.translations.view },
                    { key: 'ENTER', text: this.translations.confirm }
                ])
            }

            this.$nextTick(() => {
                this.swiper = new Swiper('.creation-selector .slider-preview', {
                    freeMode: false,
                    autoplay: false,
                    slidesPerView: this.menu.preview.itemLength > 3 ? 3 : 1,
                    spaceBetween: 10,
                    centeredSlides: false,
                    mousewheel: true,
                    speed: 500,
                    keyboard: {
                        enabled: true,
                        onlyInViewport: true,
                        pageUpDown: false,
                    },
                    grabCursor: true,
                    loop: this.menu.preview.itemLength > 3 ? true : false,
                    navigation: {
                        nextEl: '.next',
                        prevEl: '.prev',
                    },
                });

                const navButtons = document.querySelectorAll('.creation-selector .arrow');
                navButtons.forEach(button => {
                    button.addEventListener('click', function () {
                        this.blur();
                        document.querySelector('.creation-selector .slider-preview').blur();
                    });
                });

                const startIndex = 1;
                const startItem = this.menu.preview.items[1];

                if (path == 'shell') {
                    $('.creation-selector .slider-preview .swiper-slide.slide-' + startIndex).addClass('selected');
                    this.selectedShell = startItem.model;
                } else if (path == 'exteriors') {
                    $('.creation-selector .slider-preview .swiper-slide.slide-' + startIndex).addClass('selected');
                    this.selectedExterior = startItem.model;
                }

                this.swiper.on('slideChange', () => {
                    const realIndex = (this.swiper.realIndex + 1) % this.swiper.slides.length;
                    $('.creation-selector .slider-preview .swiper-slide').removeClass('selected');
                    $('.creation-selector .slider-preview .swiper-slide.slide-' + realIndex).addClass('selected');

                    const item = this.menu.preview.items[realIndex];

                    if (!item) {
                        return;
                    }

                    if (path == 'shell') {
                        if (!this.selectedShell) {
                            this.selectedShell = item.model;
                        } else if (this.selectedShell != item.model) {
                            this.selectedShell = item.model;
                        }
                    } else if (path == 'exteriors') {
                        if (!this.selectedExterior) {
                            this.selectedExterior = item.model;
                        } else if (this.selectedExterior != item.model) {
                            this.selectedExterior = item.model;
                        }
                    }
                });

                this.swiper.on('keyPress', (_, keyCode) => {
                    if (keyCode == 13) {
                        this.controlsHelp.visible = false;
                        if (!this.menu.preview.visible || !this.swiper) return;
                        let realIndex = this.swiper.realIndex;

                        if (this.menu.preview.itemLength > 3) {
                            realIndex = (this.swiper.realIndex + 1) % this.swiper.slides.length;
                        }

                        const item = this.menu.preview.items[realIndex];

                        if (!item) return;

                        switch (this.menu.preview.path) {
                            case 'exteriors':
                                this.closePreview();
                                this.creationData.construction.model = item.model;
                                fetch('startConstructionPlacement', {
                                    house: this.creationData
                                }).then((data) => {
                                    const constructionCoords = data.constructionCoords;
                                    const polyzoneCoords = data.polyzoneCoords;
                                    const entryCoords = data.entryCoords;
                                    const garageCoords = data.garageCoords;
                                    this.creationData.construction.coords = constructionCoords;
                                    this.creationData.exterior = polyzoneCoords;
                                    this.creationData.positions.entry = entryCoords;

                                    if (this.creationData.useGarage) {
                                        this.creationData.positions.garage = garageCoords;
                                    }

                                    if (this.creationData.data.type === 'shell' && !this.creationData.data.libre) {
                                        this.previewOptions(this.shells[this.creationData.data.interior_category], 'shell', this.translations.selectShell);
                                        return;
                                    } else {
                                        TriggerCallback('origen_housing:server:createHouse', { house: this.creationData }).then((data) => {
                                            if (data === true) {
                                                this.sendNotification('success', this.translations.notyHouseCreatedTitle, this.translations.notyHouseCreatedMessage, true);
                                            } else {
                                                this.sendNotification('error', this.translations.error, data.message, true);
                                            }
                                        });
                                    }
                                });
                                break;
                            case 'shell':
                                this.creationData.data.model = item.model;
                                this.closePreview();
                                TriggerCallback('origen_housing:server:createHouse', { house: this.creationData }).then((data) => {
                                    if (data === true) {
                                        this.sendNotification('success', this.translations.notyHouseCreatedTitle, this.translations.notyHouseCreatedMessage, true);
                                    } else {
                                        this.sendNotification('error', this.translations.error, data.message, true);
                                    }
                                });
                                break;
                        }
                    } else if (keyCode == 69) {
                        if (this.selectedShell) {
                            fetch('previewShell', { model: this.selectedShell });
                            this.selectedShell = null;
                        } else if (this.selectedExterior) {
                            fetch('previewExterior', { model: this.selectedExterior });
                            this.selectedExterior = null;
                        }
                    }
                });
            });
        },
        closePreview: function () {
            setTimeout(() => {
                if (this.swiper) {
                    this.swiper.destroy();
                    this.swiper = null;
                }
            }, 500);
            this.menu.preview.visible = false;
            this.menu.preview.items = [];
            this.menu.preview.title = '';
        },
        /*  Abrir y cerrar el panel de administracion.

            El `creating` manda sobre todo lo demas. Este metodo tambien lo
            llama el cliente para quitar el panel de en medio mientras colocas
            un punto con el laser (startHotelEntrancePlacement en
            client/nui.lua): se va con state=false y vuelve con state=true, y
            entremedias TU FORMULARIO SIGUE ABIERTO.

            Antes se reponia la vista a 'housing' en las dos ramas sin mirar
            eso, asi que al volver del laser quedaba `creating = true` con la
            vista de casas: se pintaban a la vez la rejilla de fichas, su
            paginador y el formulario, uno encima de otro, y no habia forma de
            seguir rellenando. */
        ToggleManagement: function (state) {
            if (state) {
                this.visible = true;
                if (!this.hotels.creating
                    && (this.hotels.view === 'room_detail' || this.hotels.view === 'map')) {
                    this.hotels.view = 'housing';
                    this.hotels.selected = null;
                    this.hotels.roomCreationData = null;
                }
                this.selectedMapHouse = null;
                this.menu.management = true;
                s_transition.currentTime = '0';
                s_transition.play();
            } else {
                this.menu.management = false;
                this.selectedMapHouse = null;
                if (!this.hotels.creating) this.hotels.view = 'housing';
            }
        },
        ControlsNotify: function (keys, title) {
            this.controlsHelp.visible = true;
            this.controlsHelp.keysData = keys;
            this.controlsHelp.title = title ? title : false;
        },
        /*  TODOS los avisos van a origen_notify, los del servidor y los de
            aqui (07/10). Antes, sin `custom`, se pintaban en una pila propia
            dentro de esta NUI, con otro aspecto y en otro sitio que los del
            resto del servidor. El callback de Lua (client/nui.lua,
            sendNotification) los pasa a origen_notify con su titulo. El
            cuarto argumento se queda por compatibilidad y ya no cambia nada. */
        sendNotification: function (type, title, message) {
            fetch('sendNotification', {
                type: type || 'info',
                title: title || '',
                message: message || '',
            });
        },
        /*  `chico` ({ icono, k, sub }): el cuadro sale como MENÚ PEQUEÑO
            (skill origen-dialogo, css/chico.css) en vez de centrado con velo:
            columna y riel a media altura a la derecha, «Tu vivienda» se
            aparta mientras está abierto (`modalChico`, esta-tapado) y los
            botones del pie van en rejilla de dos (el primero que se pase con
            `es-ancha`, a lo ancho). Mismo `id`, mismo CloseModal y el mismo
            contenido: lo que lee el contenido con jQuery no cambia. Para los
            diálogos del JUGADOR (dar llave, puerta); los del admin siguen
            centrados sobre su panel. */
        OpenModal: function (title, content, footerButtons, closeText, width, chico) {
            const id = this.modals.length + 1;
            this.modals.push(id);
            if (chico) {
                this.modalChico++;
                $('.modals').append(`
                <div class="c-modal oc oc-jq" data-id="${id}">
                    <div class="oc-velo" onclick="app.CloseModal(${id})"></div>
                    <div class="oc-caja">
                        <section class="oc-col">
                            <header class="oc-cab">
                                <span class="oc-cab__placa"><i class="fas ${chico.icono || 'fa-house'}"></i></span>
                                <div class="oc-cab__txt">
                                    <span class="oc-cab__k">${chico.k || 'Tu vivienda'}</span>
                                    <h2 class="oc-cab__t">${title}</h2>
                                    ${chico.sub ? `<span class="oc-cab__sub">${chico.sub}</span>` : ''}
                                </div>
                            </header>
                            <div class="oc-cuerpo">
                                ${content}
                            </div>
                            <footer class="oc-pie">
                                <div class="rp-acciones">
                                    <button class="rp-btn" onclick="app.CloseModal(${id})"><kbd class="rp-kbd">ESC</kbd><span>${closeText}</span></button>
                                    ${footerButtons}
                                </div>
                            </footer>
                        </section>
                        <aside class="oc-riel">
                            <span class="oc-riel__marca"><i class="fas ${chico.icono || 'fa-house'}"></i></span>
                            <span class="oc-riel__pie">${this.nombreDeMarca} Viviendas</span>
                        </aside>
                    </div>
                </div>
                `);
                Sonido.deslizar();
                //  Entra desde el canto: un fotograma con la caja fuera y luego dentro.
                requestAnimationFrame(() => requestAnimationFrame(() => {
                    $(`.c-modal.oc-jq[data-id='${id}']`).addClass('esta-dentro');
                }));
                return id;
            }
            $('.modals').append(`
                <div class="c-modal fadeIn" data-id="${id}">
                    <div class="modal-block" onclick="if (event.target === this) { app.CloseModal(${id}); }">
                        <div class="modal-content scale-in-2" style="width: ${width ? 'calc(' + width + 'vh / var(--ogn-escala, 1))' : 'max-content'
                }">
                            <div class="modal-header">

                                <h2 class="title">${title}</h2>
                            </div>
                            <div class="modal-body">
                                ${content}
                            </div>
                            <div class="modal-footer">
                                ${footerButtons}
                                <button class="btn-cancel" onclick='app.CloseModal(${id})'>${closeText}</button>
                            </div>
                        </div>
                    </div>
                </div>
            `);
            return id;
        },
        CloseModal: function (id) {
            //  Los pequeños salen por el canto (esta-dentro fuera) y «Tu
            //  vivienda» vuelve a la vez.
            const chicos = id ? $(`.c-modal.oc-jq[data-id='${id}']`) : $('.c-modal.oc-jq');
            if (chicos.length) {
                chicos.removeClass('esta-dentro');
                this.modalChico = Math.max(0, this.modalChico - chicos.filter(':not(.oc-saliendo)').length);
                chicos.addClass('oc-saliendo');
                Sonido.deslizar();
            }
            if (!id) {
                $('.c-modal .modal-block .modal-content').removeClass('scale-in-2').addClass('scale-out-2');
                $('.c-modal').removeClass('fadeIn').fadeOut(500, function () {
                    $(this).remove();
                    $('.o-modal').hide()
                    app.modals = [];
                });

                if (this.buyMenu) {
                    this.closeBuyHouse();
                    this.buyMenu = false;
                }
            } else {
                $(`.c-modal[data-id='${id}']`).find('.modal-content').removeClass('scale-in-2').addClass('scale-out-2');
                $(`.c-modal[data-id='${id}']`).removeClass('fadeIn').fadeOut(500, function () {
                    $(this).remove();
                    app.modals.splice(app.modals.findIndex((item) => item == id), 1);
                    if ($('.c-modal').length === 0) {
                        $('.o-modal').hide();
                        app.modals = [];
                    }
                });
            }

            if (this.currentModal === 'buyHouse' && this.buyMenu) {
                this.closeBuyHouse();
                this.buyMenu = false;
            } else if (this.currentModal === 'buyHouseConfirm' && this.buyMenu) {
                this.currentModal = 'buyHouse';
            } else if (this.currentModal == 'confirmBuyFurniture') {
                fetch('cancelFurniturePurchase', {});
                this.currentModal = null;
                this.furniture.selectedEntity = false;
            }
        },

        deleteHouse: function (id) {

            this.currentModal = 'deleteHouse';
            this.OpenModal(
                app.translations.confirmDeleteHouseTitle,
                `<p style="font-size: calc(1.7vh / var(--ogn-escala, 1));">${app.translations.confirmDeleteHouse}</p>`,
                `<button class="btn-modal" onclick="confirmDelete()">${this.translations.confirm}</button>`,
                this.translations.Close,
                50
            );

            window.confirmDelete = function () {
                TriggerCallback('origen_housing:server:deleteHouse', { id: id }).then((data) => {
                    if (data === true) {
                        app.sendNotification('success', app.translations.notyHouseDeletedTitle, app.translations.notyHouseDeletedMessage, true);
                        Vue.delete(app.houseList, id);
                        if (app.selectedMapHouse && app.selectedMapHouse.id === id) {
                            app.selectedMapHouse = null;
                        }
                        if (app.hotels.view === 'map') {
                            app.renderMapHouses();
                        }
                        app.CloseModal();
                    } else {
                        app.sendNotification('error', app.translations.notyHouseDeleteError, data.message, true);
                    }
                });
            };
        },

        changeHouseTab: function (tab) {
            if (tab == this.house.currentTab) return;
            this.house.currentTab = tab;
            this.loadHouseSwiper();
        },

        /*  Los carruseles (Swiper) de estilos y camaras eran del panel a
            pantalla completa. El menu lateral pinta listas, asi que aqui solo
            se destruye el que quedara vivo. */
        loadHouseSwiper: function () {
            if (this.house.swiper) {
                this.house.swiper.destroy();
                this.house.swiper = null;
            }
        },

        /* ── Tu vivienda, en menu lateral ─────────────────────────────── */
        /*  Apartado «Entradas»: el menú se cierra y se sigue en el juego (el
            sitio se elige andando hasta él). Lo atiende custom/client/entradas.lua. */
        entradaAccion: function (que) {
            Sonido.pulsar();
            fetch('entradasAccion', { que: que, id: this.house.data.id });
        },

        irDeVivienda: function (id) {
            Sonido.pulsar();
            this.vivienda.seccion = id;
            this.vivienda.confirmando = null;
            //  Ampliado se ven todas: el riel lleva a la suya.
            if (this.vivienda.ancho) {
                this.$nextTick(() => {
                    const el = document.querySelector('.vv-cuerpo [data-sec="' + id + '"]');
                    if (el) el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
                });
            }
        },

        alternarAnchoVivienda: function () {
            Sonido.deslizar();
            this.vivienda.ancho = !this.vivienda.ancho;
        },

        cerrarVivienda: function () {
            this.vivienda.confirmando = null;
            this.showHousePanel({ state: false });
            this.upgrades.info.visible = false;
        },

        pedirMejora: function (key) {
            const m = this.house.upgrades[key];
            if (!m || !m.locked) return;
            Sonido.pulsar();
            this.vivienda.confirmando = { mejora: key };
        },

        elegirEstilo: function (index) {
            if (!this.tieneEstilosLaCasa) return;
            const e = this.ipls[this.house.data.data.model].list[index];
            if (!e || e.name == this.house.data.data.style) return;
            Sonido.pulsar();
            this.house.currentUpgrade = this.house.currentUpgrade === index ? null : index;
            //  Ampliado no hay boton de comprar en el pie: se pregunta ya.
            if (this.vivienda.ancho && this.house.currentUpgrade !== null) this.pedirEstilo();
        },

        pedirEstilo: function () {
            if (this.house.currentUpgrade === null) return;
            this.vivienda.confirmando = { estilo: this.house.currentUpgrade };
        },

        cancelarVivienda: function () {
            Sonido.pulsar();
            this.vivienda.confirmando = null;
        },

        confirmarVivienda: function () {
            const c = this.vivienda.confirmando;
            if (!c) return;
            const id = this.house.data.id;

            if (c.estilo !== undefined) {
                this.vivienda.confirmando = null;
                this.buyHouseUpgrade();
                return;
            }

            const upgrade = c.mejora;
            TriggerCallback('origen_housing:server:buyUpgrade', { upgrade: upgrade, houseID: id }).then((data) => {
                this.vivienda.confirmando = null;
                if (data === true) {
                    this.sendNotification('success', this.translations.buyUpgradeSuccess);
                    this.buyUpgrade(true, upgrade);
                    this.house.upgrades[upgrade].locked = false;
                } else {
                    this.sendNotification('error', this.translations.error, data && data.message);
                }
            });
        },

        showHousePanel: function (data) {
            s_transition.currentTime = '0';
            s_transition.play();

            if (data.state) {
                if (this.menu.houses.visible) {
                    this.ToggleHousesMenu(false, false, false);
                }

                this.house.visible = true;
                this.house.data = data.data;
                this.house.currentUpgrade = null;
                this.vivienda.confirmando = null;
                this.currentLight = null;

                this.house.data.emptyCameras = Math.max(0, 10 - Object.keys(this.house.data.cameras).length);

                this.house.data.lightsCount = Object.keys(this.house.data.lights).length;
                this.house.data.boardsCount = Object.keys(this.house.data.boards).length;

                this.house.data.emptyLights = Math.max(0, 5 - this.house.data.lightsCount);
                this.house.data.emptyBoards = Math.max(0, 6 - this.house.data.boardsCount);

                for (const key in this.house.upgrades) {
                    if (this.house.data.settings.upgrades[key]) {
                        this.house.upgrades[key].locked = false;
                    } else {
                        this.house.upgrades[key].locked = true;
                    }
                }

                if (this.house.data.data.type === 'ipl' && this.house.data.data.style && this.ipls[this.house.data.data.model]) {
                    this.house.currentTab = 'upgrades';
                }

                this.loadHouseSwiper();
            } else {
                this.house.visible = false;
                //  Con `sinSoltar` Lua ya ha soltado el foco y va a abrir otra
                //  pantalla (los muebles): el eco llegaria tarde y se lo quitaria.
                if (!data.sinSoltar) fetch('close', {});
                this.CloseModal();
                this.buyUpgrade(false);
                this.notifications = [];
                this.currentUpgrade = null;
                setTimeout(() => {
                    if (this.house.visible) return;
                    if (this.house.swiper) {
                        this.house.swiper.destroy();
                        this.house.swiper = null;
                    }
                }, 500);
            }
        },

        deleteKey: function (citizenid) {
            const id = this.house.data.id;
            TriggerCallback('origen_housing:server:deleteKey', { citizenid: citizenid, houseID: id }).then((data) => {
                if (data === true) {
                    this.sendNotification('success', app.translations.deleteKey);
                    this.$delete(this.house.data.holders, citizenid);
                } else {
                    this.sendNotification('error', this.translations.error, data && data.message);
                }
            });
        },

        getEligibleNearbyPlayers: function () {
            const holders = (this.house && this.house.data && this.house.data.holders) || {};
            const eligible = [];
            (this.cercanos || []).forEach((player, i) => {
                if (player && player.citizenid && !holders[player.citizenid]) {
                    eligible.push({ player: player, index: i });
                }
            });
            return eligible;
        },

        loadNearbyPlayers: async function () {
            const data = await TriggerCallback('origen_housing:server:getNearbyPlayers', {});
            this.cercanos = Array.isArray(data) ? data : [];
            this.selectedKeyPlayers = [];
            return this.renderNearbyPlayersHtml();
        },

        renderNearbyPlayersHtml: function () {
            const eligible = this.getEligibleNearbyPlayers();
            const escapar = (t) => $('<div>').text(t == null ? '' : String(t)).html();

            if (eligible.length === 0) {
                return `
                    <div class="col-12 mt-2">
                        <div class="box-option" style="cursor: default; opacity: 0.75; justify-content: center;">
                            <i class="fa-solid fa-user-slash"></i>
                            <span style="margin-left: calc(1vh / var(--ogn-escala, 1));">${this.translations.noNearbyPlayers || 'No hay jugadores cercanos'}</span>
                        </div>
                    </div>
                `;
            }

            const allSelected = eligible.length > 0 && this.selectedKeyPlayers.length === eligible.length;
            let html = `
                <div class="col-12 nearby-selection-bar">
                    <span class="nearby-selected-count">
                        <span id="key-players-count">${this.selectedKeyPlayers.length}</span> seleccionados
                    </span>
                    <button type="button" class="btn-select-all" onclick="app.toggleSelectAllKeyPlayers()">
                        <i class="fa-solid fa-check-double"></i>
                        <span id="btn-select-all-text">${allSelected ? 'Deseleccionar todos' : 'Seleccionar todos'}</span>
                    </button>
                </div>
            `;

            for (const item of eligible) {
                const i = item.index;
                const player = item.player;
                const isSelected = this.selectedKeyPlayers.includes(i);
                html += `
                    <div class="col-12 mt-2">
                        <div class="box-option nearby-player-option ${isSelected ? 'selected active' : ''}" data-index="${i}" onclick="app.toggleKeyPlayerSelection(${i})">
                            <div class="d-flex align-items-center gap-2" style="pointer-events: none;">
                                <span class="player-check-icon">
                                    <i class="${isSelected ? 'fa-solid fa-square-check' : 'fa-regular fa-square'}"></i>
                                </span>
                                <i class="fa-solid fa-user"></i>
                                <span class="player-name">${escapar(player.name)}</span>
                            </div>
                            <span class="player-id-badge" style="pointer-events: none;">ID: ${player.id}</span>
                        </div>
                    </div>
                `;
            }

            return html;
        },

        toggleKeyPlayerSelection: function (i) {
            if (!Array.isArray(this.selectedKeyPlayers)) this.selectedKeyPlayers = [];
            const idx = this.selectedKeyPlayers.indexOf(i);
            if (idx > -1) {
                this.selectedKeyPlayers.splice(idx, 1);
            } else {
                this.selectedKeyPlayers.push(i);
            }
            this.updateNearbyPlayersSelectionUI();
        },

        toggleSelectAllKeyPlayers: function () {
            if (!Array.isArray(this.selectedKeyPlayers)) this.selectedKeyPlayers = [];
            const eligible = this.getEligibleNearbyPlayers();
            if (eligible.length > 0 && this.selectedKeyPlayers.length === eligible.length) {
                this.selectedKeyPlayers = [];
            } else {
                this.selectedKeyPlayers = eligible.map(item => item.index);
            }
            this.updateNearbyPlayersSelectionUI();
        },

        updateNearbyPlayersSelectionUI: function () {
            const count = (this.selectedKeyPlayers || []).length;
            const eligible = this.getEligibleNearbyPlayers();
            const allSelected = eligible.length > 0 && count === eligible.length;

            $('#key-players-count').text(count);
            $('#btn-key-count').text(count);
            $('#btn-select-all-text').text(allSelected ? 'Deseleccionar todos' : 'Seleccionar todos');

            $('.nearby-player-option').each((_, el) => {
                const i = Number($(el).attr('data-index'));
                const isSelected = (this.selectedKeyPlayers || []).includes(i);
                if (isSelected) {
                    $(el).addClass('selected active');
                    $(el).find('.player-check-icon i').removeClass('fa-regular fa-square').addClass('fa-solid fa-square-check');
                } else {
                    $(el).removeClass('selected active');
                    $(el).find('.player-check-icon i').removeClass('fa-solid fa-square-check').addClass('fa-regular fa-square');
                }
            });

            //  Sin nadie elegido el botón se apaga (rp-confirmar:disabled).
            $('#btn-give-keys').prop('disabled', count === 0);
        },

        addKeyModal: async function () {
            this.selectedKeyPlayers = [];
            const nearbyPlayers = await this.loadNearbyPlayers();

            //  Menú PEQUEÑO junto a «Tu vivienda» (07/10): antes, cuadro centrado.
            this.OpenModal(
                this.translations.addKeyLabel || 'Dar llave',
                `<div class="nearby-players oc-cercanos">${nearbyPlayers}</div>`,
                `
                <button class="rp-btn" onclick="app.reloadNearbyPlayers()">
                    <i class="fa-solid fa-rotate-right"></i><span>${this.translations.reload || 'Recargar'}</span>
                </button>
                <button class="rp-confirmar es-ancha" id="btn-give-keys" onclick="app.confirmGiveSelectedKeys()" disabled>
                    <i class="fa-solid fa-key"></i> Dar llaves (<span id="btn-key-count">0</span>)
                </button>
                `,
                this.translations.Close || 'Cerrar',
                55,
                { icono: 'fa-key', k: 'Tu vivienda', sub: 'Elige a quién de los que tienes cerca' }
            );
            this.updateNearbyPlayersSelectionUI();
        },

        reloadNearbyPlayers: async function () {
            const nearbyPlayers = await this.loadNearbyPlayers();
            if (!nearbyPlayers) return;

            const container = document.querySelector('.nearby-players');
            if (container) {
                container.innerHTML = nearbyPlayers;
            }
            this.updateNearbyPlayersSelectionUI();
        },

        confirmGiveSelectedKeys: function () {
            if (!this.selectedKeyPlayers || this.selectedKeyPlayers.length === 0) {
                this.sendNotification('error', this.translations.error || 'Error', 'Selecciona al menos un jugador');
                return;
            }

            const selected = this.selectedKeyPlayers
                .map(i => (this.cercanos || [])[i])
                .filter(Boolean);

            if (selected.length === 0) {
                this.sendNotification('error', this.translations.error || 'Error', 'Selecciona al menos un jugador');
                return;
            }

            const targets = selected.map(p => ({
                targetID: p.id,
                citizenid: p.citizenid,
                name: p.name
            }));

            TriggerCallback('origen_housing:server:giveKey', {
                houseID: this.house.data.id,
                targets: targets
            }).then((res) => {
                if (res === true || (res && res.status === true)) {
                    this.sendNotification('success', this.translations.addKey || 'Llaves entregadas');
                    if (!this.house.data.holders) this.$set(this.house.data, 'holders', {});
                    if (res && res.added) {
                        Object.keys(res.added).forEach((cid) => {
                            this.$set(this.house.data.holders, cid, res.added[cid]);
                        });
                    } else {
                        selected.forEach((p) => {
                            this.$set(this.house.data.holders, p.citizenid, {
                                name: p.name,
                                owner: false,
                            });
                        });
                    }
                    this.CloseModal();
                } else {
                    this.sendNotification('error', this.translations.error || 'Error', res ? res.message : 'No se pudo entregar la llave');
                }
            });
        },

        addKeyCercano: function (i) {
            const player = (this.cercanos || [])[i];
            if (player) this.addKey(player.citizenid, player.name, player.id);
        },

        addKey: function (citizenid, name, targetID) {
            TriggerCallback('origen_housing:server:giveKey', {
                citizenid: citizenid, name: name, houseID: this.house.data.id, targetID: targetID
            }).then((data) => {
                if (data === true || (data && data.status === true)) {
                    this.sendNotification('success', this.translations.addKey || 'Llave entregada');
                    if (!this.house.data.holders) this.$set(this.house.data, 'holders', {});
                    this.$set(this.house.data.holders, citizenid, {
                        name: name,
                        owner: false,
                    });
                    this.CloseModal();
                } else {
                    this.sendNotification('error', this.translations.error, data && data.message);
                }
            });
        },

        openChangeOwnerModal: function (house) {
            if (!house) return;
            const currentOwner = house.citizenid || 'Sin dueño';
            this.OpenModal(
                'Cambiar propietario',
                `
                <div class="change-owner-modal flex-column d-flex gap-3">
                    <p style="font-size: calc(1.3vh / var(--ogn-escala, 1)); color: var(--ogn-t2);">
                        Propietario actual: <strong>${currentOwner}</strong>
                    </p>
                    <div class="form-group">
                        <label class="ogn-label">ID de Jugador (Server ID) o CitizenID / DNI</label>
                        <input type="text" id="input-new-owner" class="form-control mt-1" placeholder="Ej: 1 o ABC12345">
                    </div>
                </div>
                `,
                `
                <div class="d-flex align-items-center gap-2">
                    <button class="btn-modal" onclick="confirmChangeOwner('${house.id}')">Asignar Propietario</button>
                    ${house.citizenid ? `<button class="btn-modal btn-danger" onclick="confirmRemoveOwner('${house.id}')">Quitar propietario</button>` : ''}
                </div>
                `,
                'Cancelar',
                45
            );

            window.confirmChangeOwner = (houseID) => {
                const target = $('#input-new-owner').val() ? $('#input-new-owner').val().trim() : '';
                if (!target) {
                    app.sendNotification('error', app.translations.error || 'Error', 'Introduce un ID de jugador o CitizenID');
                    return;
                }
                TriggerCallback('origen_housing:server:changeOwner', { houseID: houseID, target: target }).then((res) => {
                    if (res && (res === true || res.status === true)) {
                        app.sendNotification('success', app.translations.success || 'Éxito', 'Propietario cambiado correctamente');
                        app.CloseModal();
                        if (app.selectedMapHouse && app.selectedMapHouse.id == houseID) {
                            app.selectedMapHouse.citizenid = res.citizenid || target;
                        }
                    } else {
                        app.sendNotification('error', app.translations.error || 'Error', res ? res.message : 'No se pudo cambiar el propietario');
                    }
                });
            };

            window.confirmRemoveOwner = (houseID) => {
                TriggerCallback('origen_housing:server:changeOwner', { houseID: houseID, target: '' }).then((res) => {
                    if (res && (res === true || res.status === true)) {
                        app.sendNotification('success', app.translations.success || 'Éxito', 'Propietario eliminado correctamente');
                        app.CloseModal();
                        if (app.selectedMapHouse && app.selectedMapHouse.id == houseID) {
                            app.selectedMapHouse.citizenid = null;
                        }
                    } else {
                        app.sendNotification('error', app.translations.error || 'Error', res ? res.message : 'Error al quitar propietario');
                    }
                });
            };
        },

        openAddMapKeyModal: function (house) {
            if (!house) return;
            this.OpenModal(
                'Dar llave',
                `
                <div class="add-key-modal flex-column d-flex gap-3">
                    <p style="font-size: calc(1.3vh / var(--ogn-escala, 1)); color: var(--ogn-t2);">
                        Casa: <strong>${house.name} (#${house.data.number})</strong>
                    </p>
                    <div class="form-group">
                        <label class="ogn-label">ID de Jugador (Server ID) o CitizenID / DNI</label>
                        <input type="text" id="input-key-target" class="form-control mt-1" placeholder="Ej: 5 o XYZ98765">
                    </div>
                </div>
                `,
                `<button class="btn-modal" onclick="confirmGiveMapKey('${house.id}')">Dar Llave</button>`,
                'Cancelar',
                45
            );

            window.confirmGiveMapKey = (houseID) => {
                const target = $('#input-key-target').val() ? $('#input-key-target').val().trim() : '';
                if (!target) {
                    app.sendNotification('error', app.translations.error || 'Error', 'Introduce un ID o CitizenID');
                    return;
                }

                const isServerID = !isNaN(target);
                const data = {
                    houseID: houseID,
                    targetID: isServerID ? target : null,
                    citizenid: isServerID ? null : target,
                    name: target
                };

                TriggerCallback('origen_housing:server:giveKey', data).then((res) => {
                    if (res === true || (res && res.status === true)) {
                        app.sendNotification('success', app.translations.addKey || 'Llave entregada');
                        app.CloseModal();
                    } else {
                        app.sendNotification('error', app.translations.error || 'Error', res ? res.message : 'No se pudo entregar la llave');
                    }
                });
            };
        },

        deleteMapHouseKey: function (houseID, citizenid) {
            TriggerCallback('origen_housing:server:deleteKey', { citizenid: citizenid, houseID: houseID }).then((data) => {
                if (data === true || (data && data.status === true)) {
                    this.sendNotification('success', app.translations.deleteKey || 'Llave eliminada');
                    if (this.selectedMapHouse && this.selectedMapHouse.holders && this.selectedMapHouse.holders[citizenid]) {
                        this.$delete(this.selectedMapHouse.holders, citizenid);
                    }
                } else {
                    this.sendNotification('error', app.translations.error || 'Error', data ? data.message : '');
                }
            });
        },


        toggleLock: function (doorID) {
            const houseID = this.house.data.id;
            TriggerCallback('origen_housing:server:toggleLock', { doorID: doorID, houseID: houseID }).then((data) => {
                if (data.status === true) {
                    const state = data.locked ? app.translations.locked : app.translations.unlocked;
                    this.sendNotification('success', app.translations.door + ' ' + state, app.translations.toggleDoor.replace('%s', state));
                    this.house.data.doors[doorID].locked = !this.house.data.doors[doorID].locked;
                } else {
                    this.sendNotification('error', this.translations.error, data.message);
                }
            });
        },

        deleteDoor: function (doorID) {
            const houseID = this.house.data.id;

            TriggerCallback('origen_housing:server:deleteDoor', {
                doorID: doorID,
                houseID: houseID
            }).then((data) => {
                if (data === true) {
                    this.house.data.doors[doorID] = null;
                    delete this.house.data.doors[doorID];
                } else {
                    this.sendNotification('error', this.translations.error, data.message);
                }
            });
        },

        selectDoorType: function (type, el) {
            const container = el ? $(el).closest('.create-door, .edit-door') : $('.create-door, .edit-door');
            const parent = el ? $(el).closest('.door_types') : $('.door_types');
            parent.find('.btn.option').removeClass('active');
            if (el) {
                $(el).closest('.btn.option').addClass('active');
            } else {
                parent.find(`.btn.option[type="${type}"]`).addClass('active');
            }
            const distInput = container.find('.input-door-distance');
            if (distInput.length) {
                const currentVal = parseFloat(distInput.val());
                if (type === 'garage' && (isNaN(currentVal) || currentVal === 2.0)) {
                    distInput.val('3.5');
                } else if ((type === 'normal' || type === 'double') && (isNaN(currentVal) || currentVal === 3.5)) {
                    distInput.val('2.0');
                }
            }
        },

        /*  El formulario de una puerta (añadir y editar), para el menú
            PEQUEÑO. Las clases que lee la lógica no cambian: `.create-door` /
            `.edit-door`, `.input-door-name`, `.door_types .btn.option[type]`
            con `active` en la elegida e `.input-door-distance`. */
        formularioDePuerta: function (clase, nombre, tipo, distancia) {
            const t = app.translations;
            const escapar = (v) => $('<div>').text(v == null ? '' : String(v)).html().replace(/"/g, '&quot;');
            const opcion = (id, icono, texto) => `
                    <div class="btn option btn-sound ${tipo === id ? 'active' : ''}" type="${id}" onclick="app.selectDoorType('${id}', this)">
                        <i class="${icono}"></i>
                        <span>${texto}</span>
                    </div>`;
            return `
                <div class="${clase} oc-puerta">
                    <div class="rp-campo-grupo">
                        <span class="rp-metodo-etq">${t.doorName || 'Nombre de la puerta'}</span>
                        <input type="text" class="vv-campo w-100 input-door-name" value="${escapar(nombre)}" placeholder="${t.name || 'Nombre'}">
                    </div>
                    <div class="rp-campo-grupo">
                        <span class="rp-metodo-etq">${t.doorType || 'Tipo de puerta'}</span>
                        <div class="door_types oc-tipos">${opcion('normal', 'fa fa-door-closed', t.normal || 'Normal')}${opcion('double', 'fa fa-door-open', t.double || 'Doble')}${opcion('garage', 'fa-solid fa-warehouse', t.garage || 'Garaje')}
                        </div>
                    </div>
                    <div class="rp-campo-grupo">
                        <span class="rp-metodo-etq">${t.doorDistance || 'Distancia de apertura'}</span>
                        <div class="oc-distancia">
                            <input type="number" step="0.5" min="1.0" max="15.0" class="vv-campo input-door-distance" value="${Number(distancia).toFixed(1)}">
                            <span>${t.distanceMeters || 'metros'} (de 1 a 15 m)</span>
                        </div>
                    </div>
                </div>
            `;
        },

        createDoor: function () {
            fetch('canCreateDoor', { houseID: this.house.data.id }).then((data) => {
                if (data === true) {
                    //  Menú PEQUEÑO junto a «Tu vivienda» (07/10): antes, cuadro centrado.
                    this.currentModal = this.OpenModal(
                        app.translations.addDoor || 'Añadir puerta',
                        this.formularioDePuerta('create-door', '', 'normal', 2.0),
                        `<button class="rp-confirmar" onclick="SaveDoor()"><i class="fas fa-check"></i> ${app.translations.confirm || 'Confirmar'}</button>`,
                        this.translations.Close || 'Cerrar',
                        52,
                        { icono: 'fa-door-closed', k: 'Tu vivienda', sub: 'Ponle nombre, elige el tipo y luego apunta a la puerta.' }
                    );

                    window.SaveDoor = function () {
                        const name = $('.create-door .input-door-name').val();
                        const type = $('.create-door .door_types .option.active').attr('type') || 'normal';
                        let distance = parseFloat($('.create-door .input-door-distance').val());
                        if (isNaN(distance) || distance < 0.5) distance = type === 'garage' ? 3.5 : 2.0;
                        if (distance > 30.0) distance = 30.0;

                        if (!name || name.trim().length < 3) {
                            app.sendNotification('error', app.translations.error || 'Error', app.translations.enterName || 'Debes introducir un nombre válido para la puerta.');
                            return;
                        }

                        fetch('createDoor', { name: name.trim(), type: type, distance: distance }).then((data) => {
                            if (data) {
                                app.CloseModal(app.currentModal);
                            } else {
                                app.sendNotification('error', app.translations.error || 'Error', app.translations.errorCreateDoor || 'Error al crear la puerta');
                            }
                        });
                    };
                } else {
                    app.sendNotification('error', app.translations.error || 'Error', app.translations.errorCreateDoor || 'Error al crear la puerta');
                }
            });
        },

        editDoor: function (doorID) {
            const door = this.house.data.doors && this.house.data.doors[doorID];
            if (!door) return;

            const currentType = door.type || 'normal';
            const currentDistance = door.distance != null ? parseFloat(door.distance) : (currentType === 'garage' ? 3.5 : 2.0);
            //  Menú PEQUEÑO junto a «Tu vivienda» (07/10): antes, cuadro centrado.
            this.currentModal = this.OpenModal(
                app.translations.editDoor || 'Editar puerta',
                this.formularioDePuerta('edit-door', door.name || '', currentType, currentDistance),
                `
                <button class="rp-btn" onclick="ReassignDoor('${doorID}')" title="Volver a apuntar a la puerta en el juego"><i class="fa-solid fa-crosshairs"></i><span>${app.translations.reassign || 'Reasignar'}</span></button>
                <button class="rp-confirmar es-ancha" onclick="UpdateDoor('${doorID}')"><i class="fas fa-check"></i> ${app.translations.save || 'Guardar'}</button>
                `,
                this.translations.Close || 'Cerrar',
                54,
                { icono: 'fa-door-open', k: 'Tu vivienda', sub: door.name ? $('<div>').text(door.name).html() : '' }
            );

            window.UpdateDoor = (id) => {
                const name = $('.edit-door .input-door-name').val();
                const type = $('.edit-door .door_types .option.active').attr('type') || currentType;
                let distance = parseFloat($('.edit-door .input-door-distance').val());
                if (isNaN(distance) || distance < 0.5) distance = type === 'garage' ? 3.5 : 2.0;
                if (distance > 30.0) distance = 30.0;

                if (!name || name.trim().length < 3) {
                    app.sendNotification('error', app.translations.error || 'Error', app.translations.enterName || 'Debes introducir un nombre válido para la puerta.');
                    return;
                }

                TriggerCallback('origen_housing:server:updateDoor', {
                    houseID: this.house.data.id,
                    doorID: id,
                    name: name.trim(),
                    type: type,
                    distance: distance
                }).then((data) => {
                    if (data === true || (data && data.status === true)) {
                        if (!this.house.data.doors[id]) this.$set(this.house.data.doors, id, {});
                        this.$set(this.house.data.doors[id], 'name', name.trim());
                        this.$set(this.house.data.doors[id], 'type', type);
                        this.$set(this.house.data.doors[id], 'distance', distance);
                        app.sendNotification('success', app.translations.doorUpdated || 'Puerta actualizada correctamente');
                        app.CloseModal(app.currentModal);
                    } else {
                        app.sendNotification('error', app.translations.error || 'Error', (data && data.message) || 'Error al actualizar la puerta');
                    }
                });
            };

            window.ReassignDoor = (id) => {
                const name = $('.edit-door .input-door-name').val() || door.name;
                const type = $('.edit-door .door_types .option.active').attr('type') || currentType;
                let distance = parseFloat($('.edit-door .input-door-distance').val());
                if (isNaN(distance) || distance < 0.5) distance = type === 'garage' ? 3.5 : 2.0;
                if (distance > 30.0) distance = 30.0;

                fetch('reassignDoor', {
                    doorID: id,
                    name: name.trim(),
                    type: type,
                    distance: distance
                }).then((data) => {
                    if (data) {
                        app.CloseModal(app.currentModal);
                    } else {
                        app.sendNotification('error', app.translations.error || 'Error', app.translations.errorCreateDoor || 'No se pudo iniciar la reasignación');
                    }
                });
            };
        },

        useCamera: function (cameraID) {
            const houseID = this.house.data.id;

            if (!houseID || !cameraID) return;

            fetch('useCamera', { cameraID: cameraID, houseID: houseID })
        },

        // Furniture
        toggleFurnitureMenu: function (state, force) {
            if (state) {
                app.currentModal = null;
                this.furniture.selectCategory = null;
                //  Lua borra el mueble a medio elegir (backCategory): que no
                //  quede su nombre y Enter/clic intenten comprar algo que ya
                //  no existe.
                this.furniture.currentObject = false;
                this.furniture.minimized = false;
                this.furniture.action = 'move';
                fetch('backCategory', {});
                this.furniture.selectedEntity = false;
            }
            this.furniture.visible = state;

            if (!state && !force) {
                this.furniture.selectCategory = null;
                this.furniture.minimized = false;
                this.furniture.selectedEntity = false;
            }
        },

        editObject: function (index) {
            event.stopPropagation();
            fetch('onActionObject', {
                action: 'edit',
                id: index,
            }).then((entity) => {
                this.furniture.selectedEntity = entity;
                this.furniture.isMoving = true;
                s_pop.currentTime = '0';
                s_pop.play();
            });
        },
        deleteObject: function (index) {
            event.stopPropagation();
            fetch('onActionObject', {
                action: 'delete',
                id: index,
            });
        },

        selectObject: function (index) {
            this.furniture.selectedObject = index
            fetch('onActionObject', {
                action: 'select',
                id: index,
            });
        },

        /*  Cerrar el menu de muebles por el mismo camino que Escape. */
        cerrarMuebles: function () {
            this.toggleFurnitureMenu(false);
            fetch('closeFurniture', {});
            this.furniture.isMoving = false;
            this.gizmoMode = false;
            if (this.carrito.length > 0) {
                this.carrito = [];
                this.modalCarrito = false;
            }
        },

        openFurnitureMenu: function () {
            fetch('openFurnitureMenu', {});
        },

        // Construir (casas de modalidad libre): el menú se aparta y se sigue en el juego
        obraElegir: function (id) {
            fetch('obraHerramienta', { herramienta: id, material: this.furniture.obraMaterial });
        },

        toggleFurnitureMode: function () {
            if (!this.furniture.visible) return;

            this.furniture.mode = this.furniture.mode === 'gizmo' ? 'mouse' : 'gizmo';

            fetch('toggleFurnitureMode', { mode: this.furniture.mode });
        },

        backCategory: function () {
            this.furniture.selectCategory = null;
            this.furniture.currentObject = false;
            this.furniture.minimized = false;
            this.furniture.action = 'move';

            fetch('backCategory', {});
        },

        selectFurnitureCategory: function (category) {

            if (this.furniture.selectCategory === category) {
                this.furniture.selectCategory = null;
                this.furniture.currentObject = false;
                this.furniture.minimized = false;
                this.furniture.action = 'move';
                fetch('backCategory', {});
                return;
            }
            this.furniture.selectCategory = category;
            this.furniture.minimized = true;
            this.furniture.action = 'create';
            fetch('selectCategory', {});
        },
        spawnObject: function (model) {
            this.furniture.action = 'create';
            fetch('spawnObject', { model: model })
                .then((spawned) => {
                    this.furniture.currentObject = spawned || model;
                });
        },
        startPlacement: function () {
            this.furniture.action = 'create';
            this.furniture.isMoving = true;
            fetch('startPlacement', {}).then((ok) => {
                if (ok === false) {
                    this.furniture.currentObject = false;
                    this.furniture.isMoving = false;
                    return;
                }
                this.furniture.isMoving = true;
                this.toggleFurnitureMenu(false, true);
            });
        },
        confirmBuyFurniture: function () {
            let object = this.furniture.currentObject;
            if (!object && this.furniture.selectedObject) {
                object = this.furniture.selectedObject;
            }
            if (!object && this.furniture.selectedEntity) {
                object = typeof this.furniture.selectedEntity === 'string' ? this.furniture.selectedEntity : (this.furniture.selectedEntity.model || null);
            }
            if (!object) {
                return;
            }
            let item = null;
            let category = null;

            if (this.furniture.items) {
                if (this.furniture.selectCategory !== null && this.furniture.selectCategory !== undefined && this.furniture.items[this.furniture.selectCategory]) {
                    const cat = this.furniture.items[this.furniture.selectCategory];
                    if (cat && cat.items) {
                        item = cat.items.find((it) => it.model === object);
                        if (item) category = cat;
                    }
                }
                if (!item) {
                    for (const cat of Object.values(this.furniture.items)) {
                        if (cat && cat.items) {
                            item = cat.items.find((it) => it.model === object);
                            if (item) {
                                category = cat;
                                break;
                            }
                        }
                    }
                }
            }

            let priceNum = 0;
            let priceStr = app.translations.free || 'Gratis';
            if (item && item.price !== undefined && item.price !== null) {
                priceNum = Number(item.price) || 0;
            } else if (this.furniture.defaultPrice > 0) {
                priceNum = Number(this.furniture.defaultPrice) || 0;
            }

            if (priceNum > 0) {
                priceStr = this.precio(priceNum);
            }

            const itemLabel = (item && (item.label || item.name)) || object;

            fetch('addToCart', {
                model: object,
            }).then((res) => {
                if (res && res.status) {
                    this.carrito.push({
                        cartId: res.cartId,
                        id: res.id,
                        model: object,
                        label: itemLabel,
                        price: priceNum,
                        priceText: priceStr,
                        category: category ? (category.label || '') : ''
                    });

                    this.furniture.currentObject = false;
                    this.furniture.selectedEntity = false;
                    this.furniture.isMoving = false;
                    this.toggleFurnitureMenu(true);
                    this.sendNotification('info', 'Carrito', `${itemLabel} añadido al carrito (${this.carrito.length})`);
                } else {
                    this.sendNotification('error', 'Error', 'No se pudo colocar el mueble en el carrito');
                }
            });
        },

        abrirCarrito: function () {
            this.modalCarrito = true;
        },

        eliminarDelCarrito: function (cartId) {
            fetch('removeCartItem', { cartId: cartId }).then(() => {
                this.carrito = this.carrito.filter(it => it.cartId !== cartId);
            });
        },

        vaciarCarrito: function () {
            fetch('clearCart', {}).then(() => {
                this.carrito = [];
                this.sendNotification('info', 'Carrito', 'Se ha vaciado el carrito');
            });
        },

        confirmarPagoCarrito: function () {
            if (this.carrito.length === 0) return;
            this.comprandoCarrito = true;
            fetch('checkoutCart', {
                paymentMethod: this.carritoMetodoPago || 'cash'
            }).then((res) => {
                this.comprandoCarrito = false;
                if (res && res.status) {
                    if (res.partial) {
                        this.sendNotification('warning', 'Compra Parcial', `Fondos insuficientes: Se han colocado ${res.countBought} de ${res.countBought + res.countRejected} muebles (los primeros seleccionados). Total pagado: ${this.precio(res.totalCost || 0)}`);
                    } else {
                        this.sendNotification('success', 'Compra realizada', `Se han comprado y colocado ${res.countBought} muebles por ${this.precio(res.totalCost || 0)}`);
                    }
                    this.carrito = [];
                    this.modalCarrito = false;
                } else {
                    const msg = (res && res.message === 'sinNegro') ? 'No tienes suficiente dinero negro para comprar ningún mueble.'
                        : (res && res.message === 'sinOGN') ? 'No tienes suficientes OGN para comprar ningún mueble.'
                        : (res && res.message === 'sinDinero')
                        ? 'No tienes suficiente dinero en ' + (this.carritoMetodoPago === 'cash' ? 'efectivo' : 'el banco') + ' para comprar ningún mueble.'
                        : ((res && res.message) || 'Error al procesar el pago del carrito');
                    this.sendNotification('error', 'Error', msg);
                }
            }).catch(() => {
                this.comprandoCarrito = false;
            });
        },

        confirmarPagoMueble: function () {
            const method = this.compraMueble.paymentMethod || 'cash';
            fetch('confirmBuyFurniture', { paymentMethod: method }).then((data) => {
                if (data === true) {
                    this.compraMueble.visible = false;
                    this.furniture.currentObject = false;
                    this.sendNotification('success', this.translations.success || 'Éxito', 'Mueble comprado y colocado correctamente');
                } else {
                    const msg = (data && data.message) || (data === 'sinDinero' ? 'No tienes suficiente dinero' : 'Error al realizar el pago');
                    this.sendNotification('error', this.translations.error || 'Error', msg);
                }
            });
        },

        cancelarCompraMueble: function () {
            this.compraMueble.visible = false;
            fetch('cancelFurniturePurchase', {});
            this.furniture.currentObject = false;
        },

        contarPuntosMlo: function (tipo) {
            if (!this.house.data || !this.house.data.positions || !this.house.data.positions.points) return 0;
            let count = 0;
            for (const pt of Object.values(this.house.data.positions.points)) {
                if (pt && pt.type === tipo) count++;
            }
            return count;
        },

        limitePuntosMlo: function (tipo) {
            const pos = this.house.data && this.house.data.positions;
            if (pos && pos.limits && pos.limits[tipo] !== undefined && pos.limits[tipo] !== null) {
                return Number(pos.limits[tipo]) || 3;
            }
            if (this.mloBaseLimits && this.mloBaseLimits[tipo] !== undefined) {
                return Number(this.mloBaseLimits[tipo]) || 3;
            }
            return 3;
        },

        comprarHuecoMlo: function (tipo) {
            if (!tipo || !this.house.data || !this.house.data.id) return;
            const label = tipo === 'stash' ? 'Almacén' : 'Vestidor';
            fetch('buyMloPointSlot', {
                type: tipo,
            }).then((res) => {
                if (res && res.status) {
                    if (!this.house.data.positions) this.$set(this.house.data, 'positions', {});
                    if (!this.house.data.positions.limits) this.$set(this.house.data.positions, 'limits', {});
                    this.$set(this.house.data.positions.limits, tipo, res.newLimit || (this.limitePuntosMlo(tipo) + 1));
                    this.sendNotification('success', 'Cupo ampliado', `Has adquirido un espacio extra de ${label}. Límite actual: ${this.limitePuntosMlo(tipo)}`);
                } else {
                    this.sendNotification('error', 'Error', (res && res.message) || 'No se pudo ampliar el cupo');
                }
            });
        },

        abrirMenuNuevoPuntoMlo: function () {
            const stashCount = this.contarPuntosMlo('stash');
            const stashLim = this.limitePuntosMlo('stash');
            const defaultType = stashCount < stashLim ? 'stash' : 'wardrobe';
            this.nuevoPuntoMlo = {
                visible: true,
                type: defaultType,
                name: defaultType === 'stash' ? 'Almacén' : 'Vestidor',
            };
        },

        seleccionarTipoPuntoMlo: function (tipo) {
            this.nuevoPuntoMlo.type = tipo;
            if (tipo === 'stash') {
                if (!this.nuevoPuntoMlo.name || this.nuevoPuntoMlo.name === 'Vestidor' || this.nuevoPuntoMlo.name === 'Armario' || this.nuevoPuntoMlo.name === 'Descanso') {
                    this.nuevoPuntoMlo.name = 'Almacén';
                }
            } else if (tipo === 'wardrobe') {
                if (!this.nuevoPuntoMlo.name || this.nuevoPuntoMlo.name === 'Almacén' || this.nuevoPuntoMlo.name === 'Descanso') {
                    this.nuevoPuntoMlo.name = 'Vestidor';
                }
            }
        },

        iniciarColocacionPuntoMlo: function () {
            if (!this.nuevoPuntoMlo.name || !this.nuevoPuntoMlo.name.trim()) {
                this.sendNotification('error', 'Error', 'Debes introducir un nombre para el punto');
                return;
            }

            const tipo = this.nuevoPuntoMlo.type;
            const currentCount = this.contarPuntosMlo(tipo);
            const currentLimit = this.limitePuntosMlo(tipo);
            if (currentCount >= currentLimit) {
                const label = tipo === 'stash' ? 'almacenes' : 'vestidores';
                this.sendNotification('error', 'Límite alcanzado', `Has alcanzado el límite de ${currentLimit} ${label}. Adquiere un espacio adicional para continuar.`);
                return;
            }

            const nombre = this.nuevoPuntoMlo.name.trim();
            this.nuevoPuntoMlo.visible = false;

            fetch('startMloPointPlacement', {
                type: tipo,
                name: nombre,
            }).then((ok) => {
                if (ok === false) {
                    this.sendNotification('error', 'Error', 'No se pudo iniciar la colocación del punto');
                }
            });
        },

        eliminarPuntoMlo: function (pointId) {
            if (!pointId || !this.house.data || !this.house.data.id) return;
            fetch('deleteMloPoint', {
                pointId: pointId
            }).then((res) => {
                if (res && res.status) {
                    if (this.house.data.positions && this.house.data.positions.points) {
                        this.$delete(this.house.data.positions.points, pointId);
                    }
                    this.sendNotification('success', 'Éxito', 'Punto eliminado correctamente');
                } else {
                    this.sendNotification('error', 'Error', (res && res.message) || 'Error al eliminar punto');
                }
            });
        },

        // Upgrades

        tryBuyUpgrade: function (upgrade) {
            this.pedirMejora(upgrade);
        },

        buyUpgrade: function (state, upgrade, title) {
            if (state) {
                this.upgrades.item = upgrade;
                if (upgrade !== 'house' && !this.house.upgrades[upgrade].locked) {
                    return;
                }

                this.upgrades.visible = true;
                this.upgrades.interval = setInterval(() => {
                    confetti({
                        particleCount: 2,
                        angle: 50,
                        spread: 360,
                        origin: { x: 0, y: 0.5 },
                        colors: ['#d81b55', '#dcdde0'],
                    });
                    confetti({
                        particleCount: 2,
                        angle: 150,
                        spread: 360,
                        origin: { x: 1, y: 0.5 },
                        colors: ['#d81b55', '#dcdde0']
                    });
                }, 20);
                if (upgrade === 'house') {
                    this.upgrades.title = title;
                } else {
                    this.upgrades.title = this.house.upgrades[upgrade].label;
                }

                if (upgrade === 'cameras' && this.house.currentTab === 'cameras') {
                    this.loadHouseSwiper();
                }

                s_unlock.currentTime = '0';
                s_unlock.play();
            } else {
                if (this.upgrades.interval) {
                    confetti.reset();
                    clearInterval(this.upgrades.interval);
                }
                this.upgrades.visible = false;
                this.upgrades.item = '';
                this.upgrades.title = '';
            }
        },

        buyHouseUpgrade: function () {
            if (this.house.currentUpgrade === null) return;
            const houseID = this.house.data.id
            const style = this.house.currentUpgrade;
            TriggerCallback('origen_housing:server:buyHouseUpgrade', { houseID: houseID, style: style }).then((data) => {
                if (data.status === true) {
                    this.house.data.data.style = data.style;
                    this.sendNotification('success', app.translations.buyHouseUpgradeSuccess);
                } else {
                    this.sendNotification('error', this.translations.error, data.message);
                }
            });
        },

        openLightMenu: function (id, event) {
            if (!this.house.data.lights[id]) return;
            this.currentLight = id;
        },

        toggleLight: function (id, event) {
            event.stopPropagation();
            const houseID = this.house.data.id;
            if (!houseID) return;
            this.house.data.lights[id].state = !this.house.data.lights[id].state;
            TriggerCallback('origen_housing:server:UpdateLight', { houseID: houseID, lightID: id, state: this.house.data.lights[id].state });
        },

        closeLightMenu: function () {
            this.currentLight = null;
            this.isEditingName = false;
            this.editedName = '';
        },

        selectColor: function (color) {
            this.house.data.lights[this.currentLight].color = color;
        },

        isColorSelected(color) {
            return this.house.data.lights[this.currentLight].color.every((value, index) => value === color[index]);
        },

        saveLightChanges: function () {
            const houseID = this.house.data.id;
            if (!houseID) return;

            const color = this.house.data.lights[this.currentLight].color;
            const opacity = this.house.data.lights[this.currentLight].opacity;
            const state = this.house.data.lights[this.currentLight].state;
            const label = this.editedName !== '' ? this.editedName : false;

            if (label && label.length < 5) {
                this.sendNotification('error', this.translations.error, app.translations.notyHouseNameNeedLength);
                return;
            }

            TriggerCallback('origen_housing:server:UpdateLight', {
                houseID: houseID,
                lightID: this.currentLight,
                color: color,
                opacity: opacity,
                state: state,
                label: label
            }).then((data) => {
                if (data === true) {
                    this.sendNotification('success', app.translations.lightUpdated);
                    if (label) {
                        this.house.data.lights[this.currentLight].label = label;
                    }
                } else {
                    this.sendNotification('error', this.translations.error, data.message);
                }
            });
        },

        startEditingName: function () {
            this.editedName = this.house.data.lights[this.currentLight].label;
            this.isEditingName = true;
        },

        finishEditingName: function () {
            this.isEditingName = false;
        },

        handleBlur(id) {
            this.saveBoardUrl(id);
        },
        saveBoardUrl(id, event) {
            const houseID = this.house.data.id;
            if (!houseID) return;

            if (event && event.type === 'keyup') {
                event.target.blur();
                return;
            }

            const item = this.house.data.boards[id];

            if (!item) return;

            if (this.newUrl == item.url || !isNaN(this.newUrl)) {
                this.isEditingURL = null;
                return;
            }

            if (this.isValidImageUrl(this.newUrl)) {
                TriggerCallback('origen_housing:server:UpdateBoard', {
                    houseID: houseID,
                    boardID: id,
                    url: this.newUrl
                }).then((data) => {
                    if (data === true) {
                        this.sendNotification('success', app.translations.boardUpdated);
                        item.url = this.newUrl;
                    } else {
                        this.sendNotification('error', this.translations.error, data.message);
                    }
                    this.newUrl = '';
                });
            } else {
                this.sendNotification('error', app.translations.invalidUrl, app.translations.enterValidUrl);
                this.newUrl = '';
            }
            this.isEditingURL = null;
        },

        PlayAlarm: function () {
            alarm.loop = true;
            alarm.play();
        },
        UpdateAlarm: function (volume) {
            if (volume > 1) volume = 0.7;
            if (volume < 0.015) volume = 0;

            alarm.volume = volume;
        },
        StopAlarm: function () {
            alarm.pause();
            alarm.currentTime = 0;
        },

        ToggleHousesMenu: function (state, houses, focus) {
            if (!state) {
                this.menu.houses.visible = false;
                if (focus) {
                    fetch('close', {});
                }
                return;
            }

            if (state && this.menu.houses.visible && Object.keys(houses).length == 0) {
                return;
            }

            this.menu.houses.visible = true;
            this.menu.houses.list = houses;

            if (!focus) {
                setTimeout(() => {
                    if (Object.keys(this.menu.houses.list).length > 0) return;

                    this.menu.houses.visible = false;
                }, 3000);
            }
        },

        loadHouse: function (houseID) {
            fetch('loadHouse', {
                id: houseID
            });
        },

        toggleElevator: function (data) {
            this.elevator.visible = data.state;

            if (data.state) {
                this.elevator.floors = data.data.floors;
                this.elevator.currentFloor = data.data.floor;
            }
        },

        selectFloor: function (floor) {
            this.elevator.currentFloor = floor;
            fetch('selectFloor', {
                floor: floor
            });
        },

        handleOnKeyUp: function (event) {
            event.preventDefault();
            event.stopPropagation();

            if (event.which == 27) {
                /*  Un diálogo pequeño de jQuery (dar llave, puerta) encima de
                    «Tu vivienda»: Escape lo cierra a él, no al menú. */
                const chico = $('.c-modal.oc-jq:not(.oc-saliendo)').last();
                if (chico.length) {
                    this.CloseModal(Number(chico.attr('data-id')));
                    return;
                }
                if (this.modalCarrito) {
                    this.modalCarrito = false;
                    return;
                } else if (this.compraMueble && this.compraMueble.visible) {
                    this.cancelarCompraMueble();
                    return;
                } else if (this.nuevoPuntoMlo && this.nuevoPuntoMlo.visible) {
                    this.nuevoPuntoMlo.visible = false;
                    return;
                } else if (this.menu.management) {
                    this.ToggleManagement(false);
                    this.CloseModal();
                    fetch('closeMenu', {});
                } else if (this.house.visible) {
                    if (this.upgrades.visible) {
                        this.buyUpgrade(false);
                    } else if (this.vivienda.confirmando) {
                        this.cancelarVivienda();
                    } else if (this.currentLight !== null) {
                        this.closeLightMenu();
                    } else {
                        this.cerrarVivienda();
                    }
                } else if (this.furniture.visible || this.furniture.isMoving) {
                    //  Tambien moviendo un mueble (el menu esta escondido):
                    //  antes Escape no hacia nada y no habia forma de salir.
                    this.cerrarMuebles();
                } else if (this.buyMenu) {
                    //  Con la pregunta en el pie, Escape la retira; cerrar el
                    //  panel entero desde ahi seria contestar por ti.
                    if (this.compra.confirmando) {
                        this.cancelarCompra();
                    } else {
                        this.cerrarCompra();
                    }
                } else if (this.menu.houses.visible) {
                    this.ToggleHousesMenu(false, false, true);
                } else if (this.hotels.view === 'reception') {
                    /*  Con una pregunta en el pie, Escape la retira; cerrar
                        el panel entero desde ahí sería contestar por ti. */
                    if (this.hotels.reception.confirmando) {
                        this.cancelarConfirmacion();
                    } else {
                        this.cerrarRecepcion();
                    }
                } else if (this.hotels.view === 'room_detail') {
                    /*  Con una pregunta en el pie, Escape la retira; cerrar
                        el panel entero desde ahi seria contestar por ti. */
                    if (this.hotels.confirmandoHabitacion) {
                        this.cancelarEnLaHabitacion();
                        return;
                    }

                    /*  Por `cerrarHabitacion` y no cerrando a mano: Escape,
                        el clic fuera y el boton tienen que salir por el
                        mismo sitio, o uno de los tres se queda sin
                        animacion el dia que se toque. */
                    this.cerrarHabitacion();
                } else if (this.elevator.visible) {
                    this.cerrarAscensor();
                }
            } else if (event.which == 13) {
                if (this.furniture.isMoving) {
                    this.confirmBuyFurniture();
                }
            } else if (event.which == 20) {
                if (!this.furniture.visible) return;

                fetch('toggleFurnitureFocus', {});
            }
        },

        handleOnKeyDown: function (event) {
            if (event.which == 72) {
                if (!this.gizmoMode) return;
                fetch('toggleFurnitureModeh');
            }
        },

        /* Casas por pagina: en la pegatina caben tres filas de cinco. Igual
           en Origen y en Nacion (05/10: la misma interfaz). */
        porPagina() {
            return 15;
        },

        prevPage() {
            if (this.currentPage > 1) {
                this.currentPage--;
            }
        },

        nextPage() {
            if (this.currentPage < this.totalPages) {
                this.currentPage++;
            }
        },

        setView: function (view) {
            this.hotels.view = view;
            if (view === 'hotels') {
                this.loadHotelsData();
            } else if (view === 'map') {
                this.initAdminMap();
            }
        },

        initAdminMap: function () {
            this.$nextTick(() => {
                const L = window.L;
                if (!L) return;

                /*  Al cerrar el menu, el v-if del #app destruye el contenedor del mapa,
                    pero la instancia de Leaflet sigue apuntando al nodo muerto. */
                if (this.adminMap && !document.body.contains(this.adminMap.getContainer())) {
                    this.adminMap.remove();
                    this.adminMap = null;
                    this.adminMapMarkers = [];
                }

                if (!this.adminMap) {
                    const scale_x = 0.02072;
                    const scale_y = 0.0205;
                    const center_x = 117.3;
                    const center_y = 172.8;

                    const CUSTOM_CRS = L.extend({}, L.CRS.Simple, {
                        projection: L.Projection.LonLat,
                        scale(zoom) {
                            return Math.pow(2, zoom);
                        },
                        zoom(scale) {
                            return Math.log(scale) / 0.6931471805599453;
                        },
                        distance(pos1, pos2) {
                            const x_difference = pos2.lng - pos1.lng;
                            const y_difference = pos2.lat - pos1.lat;
                            return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
                        },
                        transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y),
                        infinite: true
                    });

                    const tileLayer = L.tileLayer('https://cfx-nui-origen_map/html/teselas/styleAtlas/{z}/{x}/{y}.jpg', {
                        minZoom: 0,
                        maxZoom: 5,
                        noWrap: true,
                        id: 'gta-map'
                    });

                    this.adminMap = L.map('housing-admin-map', {
                        crs: CUSTOM_CRS,
                        minZoom: 1.5,
                        maxZoom: 5,
                        boxZoom: false,
                        layers: [tileLayer],
                        preferCanvas: true,
                        center: [0, 0],
                        zoom: 1.5,
                        zoomControl: false,
                        attributionControl: false,
                        maxBoundsViscosity: 1.0
                    });

                    L.control.zoom({ position: 'bottomright' }).addTo(this.adminMap);

                    const southWest = this.adminMap.unproject([0, 8592], this.adminMap.getMaxZoom());
                    const northEast = this.adminMap.unproject([8192, 0], this.adminMap.getMaxZoom());
                    const bounds = L.latLngBounds(southWest, northEast);
                    this.adminMap.setMaxBounds(bounds);

                    this.mapIconAvailable = L.divIcon({
                        className: 'map-house-marker marker-available',
                        html: '<div class="marker-circle"><i class="fas fa-home"></i></div>',
                        iconSize: [30, 30],
                        iconAnchor: [15, 15]
                    });

                    this.mapIconRented = L.divIcon({
                        className: 'map-house-marker marker-rented',
                        html: '<div class="marker-circle"><i class="fas fa-key"></i></div>',
                        iconSize: [30, 30],
                        iconAnchor: [15, 15]
                    });
                }

                setTimeout(() => {
                    if (this.adminMap) {
                        this.adminMap.invalidateSize();
                    }
                }, 200);

                this.renderMapHouses();
            });
        },

        renderMapHouses: function () {
            const L = window.L;
            if (!L || !this.adminMap) return;

            if (this.adminMapMarkers) {
                this.adminMapMarkers.forEach(marker => marker.remove());
            }
            this.adminMapMarkers = [];

            Object.values(this.houseList).forEach(house => {
                if (!house || !house.positions || !house.positions.entry) return;

                const coords = house.positions.entry;
                if (typeof coords.x !== 'number' || typeof coords.y !== 'number') return;

                const isRented = !!house.citizenid;
                const marker = L.marker([coords.y, coords.x], {
                    icon: isRented ? this.mapIconRented : this.mapIconAvailable
                }).addTo(this.adminMap);

                marker.on('click', () => {
                    this.selectedMapHouse = house;
                });

                this.adminMapMarkers.push(marker);
            });
        },

        /*  Cuantos dias dura una opcion de alquiler, en singular o plural.
            La plantilla ponia el numero y la palabra «DIAS» sin mirar, y para
            el alquiler diario salia «1 DIAS». */
        duracionEnDias: function (segundos) {
            const dias = Math.round((Number(segundos) || 0) / 86400);
            const palabra = dias === 1
                ? (this.translations.day || 'día')
                : (this.translations.days || 'días');
            return dias + ' ' + palabra.toLowerCase();
        },

        toggleHotelsView: function () {
            // Mantener para compatibilidad, pero ahora usa setView
            this.setView(this.hotels.view === 'hotels' ? 'housing' : 'hotels');
        },

        loadHotelsData: function () {
            fetch('getHotelsData', {}).then((data) => {
                this.hotels.list = data;
            });

            fetch('getHotelIPLs', {}).then((data) => {
                this.hotels.ipls = data;
            });
        },

        openHotelCreation: function () {
            if (!this.hotels.ipls || Object.keys(this.hotels.ipls).length === 0) {
                fetch('getHotelIPLs', {}).then((data) => {
                    this.hotels.ipls = data;
                });
            }

            this.hotels.creating = true;
            this.hotels.editing = false;
            this.hotels.selected = null;
            this.hotels.creationData = {
                name: '',
                coords: { x: 0, y: 0, z: 0 },
                reception_coords: { x: 0, y: 0, z: 0 },
                blip: {
                    enabled: true,
                    sprite: 475,
                    color: 46,
                },
                rental_options: [
                    { type: this.translations.daily, price: 500, duration: 86400 },
                    { type: this.translations.weekly, price: 3000, duration: 604800 },
                    { type: this.translations.monthly, price: 10000, duration: 2592000 },
                ],
                auto_renew_available: true,
                rooms: [],
            };
        },

        editHotel: function (hotelID) {
            const hotel = this.hotels.list[hotelID];
            if (!hotel) return;

            this.hotels.creating = true;
            this.hotels.editing = true;
            this.hotels.selected = hotelID;
            const datos = JSON.parse(JSON.stringify(hotel));

            //  Un hotel creado antes de que existiera la recepcion no trae el
            //  campo, y uno al que se le quito lo trae vacio. En los dos casos
            //  el formulario necesita el cero para enseñar el boton de
            //  colocarla, y ponerlo antes de asignar es lo que hace que Vue lo
            //  vigile.
            if (!this.tieneRecepcion(datos)) {
                datos.reception_coords = { x: 0, y: 0, z: 0 };
            }

            this.hotels.creationData = datos;

            if (hotel.rooms) {
                if (Array.isArray(hotel.rooms)) {
                    this.hotels.creationData.existingRooms = hotel.rooms;
                } else {
                    this.hotels.creationData.existingRooms = Object.values(hotel.rooms);
                }
            } else {
                this.hotels.creationData.existingRooms = [];
            }

            this.hotels.roomCreationData = {
                room_number: '',
                door_coords: { x: 0, y: 0, z: 0, w: 0 },
                interior_ipl: '',
                stash_data: { slots: 50, weight: 100000 },
            };
        },

        saveHotel: function () {
            if (!this.hotels.creationData.name) {
                this.sendNotification('error', this.translations.error, this.translations.hotelNameRequired);
                return;
            }

            if (this.hotels.creationData.coords.x === 0) {
                this.sendNotification('error', this.translations.error, this.translations.setEntranceCoords);
                return;
            }

            if (this.hotels.editing) {
                fetch('updateHotel', {
                    hotelID: this.hotels.selected,
                    data: this.hotels.creationData
                }).then((result) => {
                    if (result.status) {
                        this.sendNotification('success', this.translations.success, this.translations.hotelUpdatedSuccess);
                        this.hotels.creating = false;
                        this.hotels.editing = false;
                        this.hotels.selected = null;
                        setTimeout(() => {
                            this.loadHotelsData();
                        }, 500);
                    } else {
                        this.sendNotification('error', this.translations.error, result.message);
                    }
                });
            } else {
                fetch('createHotel', this.hotels.creationData).then((result) => {
                    if (result.status) {
                        this.sendNotification('success', this.translations.success, this.translations.hotelCreatedSuccess);
                        this.hotels.creating = false;
                        setTimeout(() => {
                            this.loadHotelsData();
                        }, 500);
                    } else {
                        this.sendNotification('error', this.translations.error, result.message);
                    }
                });
            }
        },

        cancelHotelCreation: function () {
            this.hotels.creating = false;
            this.hotels.editing = false;
            this.hotels.selected = null;
        },

        deleteHotel: function (hotelID) {
            this.OpenModal(
                this.translations.deleteHotelTitle,
                this.translations.confirmDeleteHotel,
                '<button class="btn-confirm" onclick="app.confirmDeleteHotel(' + hotelID + ')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        confirmDeleteHotel: function (hotelID) {
            fetch('deleteHotel', { hotelID: hotelID }).then((result) => {
                if (result.status) {
                    this.sendNotification('success', this.translations.success, this.translations.hotelDeletedSuccess);
                    setTimeout(() => {
                        this.loadHotelsData();
                    }, 500);
                } else {
                    this.sendNotification('error', this.translations.error, result.message);
                }
            });
            this.CloseModal();
        },

        /*  ── La puerta es opcional ───────────────────────────────────────
            Una habitación puede no tener puerta en el mundo: se alquila y se
            entra desde la recepción del hotel. Lo que no puede es quedarse
            sin puerta Y sin recepción, porque entonces se alquilaría algo a
            lo que no se puede llegar. */
        tienePuerta: function (datos) {
            const c = datos && datos.door_coords;
            return !!(c && c.x && !(c.x === 0 && c.y === 0 && c.z === 0));
        },

        puedeCrearHabitacion: function (hotelID) {
            if (this.tienePuerta(this.hotels.roomCreationData)) return true;

            /*  Al editar un hotel que ya existe, lo que manda es lo que hay
                en el formulario: puede que le acaben de poner la recepción y
                todavía no esté guardada en la lista. */
            const hotel = this.hotels.creationData && this.hotels.creationData.id === hotelID
                ? this.hotels.creationData
                : ((this.hotels.list && this.hotels.list[hotelID]) || this.hotels.creationData);

            if (this.tieneRecepcion(hotel)) return true;

            this.sendNotification('error', this.translations.error, this.translations.noDoorNoReception);
            return false;
        },

        quitarPuerta: function () {
            this.$set(this.hotels.roomCreationData, 'door_coords', { x: 0, y: 0, z: 0, w: 0 });
            this.sendNotification('success', this.translations.success, this.translations.doorRemoved);
        },

        addRoomToHotel: function () {
            if (!this.hotels.roomCreationData.room_number || !this.hotels.roomCreationData.interior_ipl) {
                this.sendNotification('error', this.translations.error, this.translations.roomNumberInteriorRequired);
                return;
            }

            if (!this.puedeCrearHabitacion(this.hotels.creationData.id)) return;

            this.hotels.creationData.rooms.push(JSON.parse(JSON.stringify(this.hotels.roomCreationData)));

            this.hotels.roomCreationData = {
                room_number: '',
                door_coords: { x: 0, y: 0, z: 0, w: 0 },
                interior_ipl: '',
                stash_data: { slots: 50, weight: 100000 },
            };

            this.sendNotification('success', this.translations.success, this.translations.roomAddedToHotel);
        },

        removeRoomFromHotel: function (index) {
            this.hotels.creationData.rooms.splice(index, 1);
        },

        createRoomForExistingHotel: function (hotelID) {
            if (!this.hotels.roomCreationData.room_number) {
                this.sendNotification('error', this.translations.error, this.translations.roomNumberRequired);
                return;
            }

            if (!this.hotels.roomCreationData.interior_ipl) {
                this.sendNotification('error', this.translations.error, this.translations.interiorIPLRequired);
                return;
            }

            /*  La puerta ya no es obligatoria: una habitación puede vivir
                solo en la recepción. Lo que no puede es quedarse sin
                ninguna de las dos. */
            if (!this.puedeCrearHabitacion(hotelID)) return;

            const iplData = this.hotels.ipls[this.hotels.roomCreationData.interior_ipl];
            if (!iplData) {
                this.sendNotification('error', this.translations.error, this.translations.invalidInteriorIPL);
                return;
            }

            fetch('createHotelRoom', {
                hotel_id: hotelID,
                room_number: this.hotels.roomCreationData.room_number,
                door_coords: this.hotels.roomCreationData.door_coords,
                interior_ipl: this.hotels.roomCreationData.interior_ipl,
                spawn_coords: iplData.spawn,
                wardrobe_coords: iplData.wardrobe || null,
                stash_coords: iplData.stash || null,
                stash_data: this.hotels.roomCreationData.stash_data
            }).then((result) => {
                if (result.status) {
                    this.sendNotification('success', this.translations.success, this.translations.roomCreatedSuccess);

                    this.hotels.roomCreationData = {
                        room_number: '',
                        door_coords: { x: 0, y: 0, z: 0, w: 0 },
                        interior_ipl: '',
                        stash_data: { slots: 50, weight: 100000 },
                    };

                    setTimeout(() => {
                        this.loadHotelsData();
                        setTimeout(() => {
                            this.editHotel(hotelID);
                        }, 100);
                    }, 500);
                } else {
                    this.sendNotification('error', this.translations.error, result.message);
                }
            });
        },

        confirmCreateRoom: function (hotelID) {
            if (!this.hotels.roomCreationData.room_number) {
                this.sendNotification('error', this.translations.error, this.translations.roomNumberRequired);
                return;
            }

            if (!this.hotels.roomCreationData.interior_ipl) {
                this.sendNotification('error', this.translations.error, this.translations.interiorIPLRequired);
                return;
            }

            /*  La puerta ya no es obligatoria: una habitación puede vivir
                solo en la recepción. Lo que no puede es quedarse sin
                ninguna de las dos. */
            if (!this.puedeCrearHabitacion(hotelID)) return;

            const iplData = this.hotels.ipls[this.hotels.roomCreationData.interior_ipl];
            if (!iplData) {
                this.sendNotification('error', this.translations.error, this.translations.invalidInteriorIPL);
                return;
            }

            fetch('createHotelRoom', {
                hotel_id: hotelID,
                room_number: this.hotels.roomCreationData.room_number,
                door_coords: this.hotels.roomCreationData.door_coords,
                interior_ipl: this.hotels.roomCreationData.interior_ipl,
                spawn_coords: iplData.spawn,
                wardrobe_coords: iplData.wardrobe || null,
                stash_coords: iplData.stash || null,
                stash_data: this.hotels.roomCreationData.stash_data
            }).then((result) => {
                if (result.status) {
                    this.sendNotification('success', this.translations.success, this.translations.roomCreatedSuccess);
                    this.hotels.view = 'hotels';
                    this.hotels.creating = false;
                    setTimeout(() => {
                        this.loadHotelsData();
                    }, 500);
                } else {
                    this.sendNotification('error', this.translations.error, result.message);
                }
            });
        },

        cancelRoomCreation: function () {
            this.hotels.view = 'hotels';
            this.hotels.creating = false;
            this.hotels.selected = null;
        },

        adminEvictRoom: function (roomID) {
            this.OpenModal(
                this.translations.evictRoomTitle,
                this.translations.confirmEvictRoom,
                '<button class="btn-confirm" onclick="app.confirmAdminEvictRoom(' + roomID + ')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        confirmAdminEvictRoom: function (roomID) {
            const currentHotelID = this.hotels.selected;
            fetch('adminEvictHotelRoom', { roomID: roomID }).then((result) => {
                if (result.status) {
                    this.sendNotification('success', this.translations.success, this.translations.roomEvictedSuccess);
                    setTimeout(() => {
                        this.loadHotelsData();
                        if (currentHotelID) {
                            setTimeout(() => {
                                this.editHotel(currentHotelID);
                            }, 100);
                        }
                    }, 500);
                } else {
                    this.sendNotification('error', this.translations.error, result.message);
                }
            });
            this.CloseModal();
        },

        deleteHotelRoom: function (roomID) {
            this.OpenModal(
                this.translations.deleteRoomTitle,
                this.translations.confirmDeleteRoom,
                '<button class="btn-confirm" onclick="app.confirmDeleteRoom(' + roomID + ')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        confirmDeleteRoom: function (roomID) {
            const currentHotelID = this.hotels.selected;
            fetch('deleteHotelRoom', { roomID: roomID }).then((result) => {
                if (result.status) {
                    this.sendNotification('success', this.translations.success, this.translations.roomDeletedSuccess);
                    setTimeout(() => {
                        this.loadHotelsData();
                        if (currentHotelID) {
                            setTimeout(() => {
                                this.editHotel(currentHotelID);
                            }, 100);
                        }
                    }, 500);
                } else {
                    this.sendNotification('error', this.translations.error, result.message);
                }
            });
            this.CloseModal();
        },

        /*  Lo que se pinta de una habitación en la lista y en su ficha.
            Son cuatro formas de decir lo mismo —icono, renglón, pastilla y
            clase— y viven juntas para que no se desparejen: que la pastilla
            diga «libre» y el icono sea una puerta cerrada es el tipo de
            fallo que solo se ve en partida. */
        iconoDeEstado: function (room) {
            if (room.mine) return 'fa-key';
            return room.status === 'available' ? 'fa-door-open' : 'fa-door-closed';
        },

        claseDeEstado: function (room) {
            return room.mine ? 'es-mia' : room.status;
        },

        etiquetaDeEstado: function (room) {
            const t = this.translations;
            if (room.mine) return t.yours;
            return room.status === 'available' ? t.available : t.rented;
        },

        textoDeEstado: function (room) {
            const t = this.translations;

            if (room.mine) return room.expires_at ? this.formatDate(room.expires_at) : t.yours;
            if (room.status !== 'available') return t.occupiedRoom;

            /*  Lo barato que sale es lo que decide si te interesa, así que
                va en la lista y no dos clics más adentro. */
            const opciones = (this.hotels.reception.hotel && this.hotels.reception.hotel.rental_options) || [];
            if (!opciones.length) return t.available;

            const barato = opciones.reduce(function (a, b) { return b.price < a.price ? b : a; });
            return (t.fromPrice || 'Desde') + ' ' + this.precio(barato.price);
        },

        textoDeCaducidad: function (room) {
            return room.mine && room.expires_at ? this.formatDate(room.expires_at) : '—';
        },

        nombreDelPlazo: function (tipo) {
            const t = this.translations;
            if (tipo === 'daily') return t.daily;
            if (tipo === 'weekly') return t.weekly;
            if (tipo === 'monthly') return t.monthly;
            return tipo;
        },

        diasDelPlazo: function (option) {
            return (option.duration / 86400).toFixed(0);
        },

        /*  Con punto de miles y el simbolo detras: 150.000 $ (07/10).   */
        precio: function (n) {
            return this.miles(n) + (this.monedaCasa === 'negro' ? ' $ negro' : this.monedaCasa === 'ogn' ? ' OGN' : ' $');
        },

        miles: function (n) {
            return String(Math.round(Math.abs(Number(n) || 0))).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
        },

        /*  ══ El icono de cada forma de pago ════════════════════════════
            Todas salian con el simbolo del dolar, y la experiencia no es
            dinero, asi que cada metodo lleva el suyo.                    */
        paymentIcon: function (method) {
            const icons = {
                cash: 'fa-dollar-sign',
                bank: 'fa-building-columns',
                xp: 'fa-star',
                negro: 'fa-sack-dollar',     // casa de banda: dinero negro
                ogn: 'fa-coins',             // casa de crew: OGN
            };
            return 'fa-solid ' + (icons[method] || 'fa-dollar-sign');
        },

        /*  El precio de una casa, escrito como se paga: "5.000 $" si va en
            dinero, "5.000 XP" si el admin la puso a experiencia, y por su
            tipo: "5.000 $ negro" la de banda y "5.000 OGN" la de crew
            (custom/server/moneda.lua; esas mandan sobre el método).        */
        precioCasa: function (house) {
            const price = (house && house.data && house.data.price) || 0;
            const uso = house && house.data && house.data.uso;
            if (uso === 'banda') return this.miles(price) + ' $ negro';
            if (uso === 'crew') return this.miles(price) + ' OGN';
            if (house && house.data && house.data.paymentMethod === 'xp') {
                return this.miles(price) + (document.documentElement.dataset.marca === 'nacion' ? ' Farm XP' : ' XP');
            }
            return this.precio(price);
        },

        entrarDesdeRecepcion: function (roomID) {
            Sonido.pulsar();
            fetch('enterHotelRoomFromPanel', { roomID: roomID });
            this.cerrarRecepcion();
        },

        /*  ══ El mostrador ═══════════════════════════════════════════════
            El jugador pulsa E en recepción y ve de golpe todas las
            habitaciones del hotel con su estado, sin recorrer el pasillo
            probando puertas. Pinchar una cambia lo que hay en la columna;
            el riel se queda quieto, que es de lo que va un menú lateral. */
        irDeRecepcion: function (id) {
            Sonido.pulsar();
            this.hotels.reception.filtro = id;
            this.hotels.reception.room = null;
            this.hotels.reception.opcion = null;
            this.hotels.reception.confirmando = null;
        },

        abrirHabitacionDeRecepcion: function (room) {
            Sonido.pulsar();
            this.hotels.reception.room = room;
            this.hotels.reception.opcion = null;
            this.hotels.reception.confirmando = null;
            this.hotels.autoRenewSelected = false;
        },

        volverALaLista: function () {
            Sonido.pulsar();
            this.hotels.reception.room = null;
            this.hotels.reception.opcion = null;
            this.hotels.reception.confirmando = null;
        },

        cancelarConfirmacion: function () {
            Sonido.pulsar();
            this.hotels.reception.confirmando = null;
        },

        confirmarAbandono: function () {
            const room = this.hotels.reception.room;
            if (!room) return;

            Sonido.pulsar();
            this.hotels.reception.confirmando = null;
            this.confirmEvictRoom(room.id);
        },

        /*  El plazo se elige y se confirma abajo, en vez de alquilar de un
            clic: el precio se paga de verdad y un clic suelto sobre una
            tarjeta es fácil de dar sin querer.

            OJO CON EL NOMBRE: se llamaba `elegirPlazo`, igual que el del panel
            de la habitación de más abajo. En un objeto de métodos el segundo
            pisa al primero, así que pulsar un plazo en el mostrador lo
            apuntaba en `hotels.opcionElegida` —la del otro panel— y el botón
            se quedaba en «Elige un plazo» para siempre: no se podía alquilar
            desde recepción (17/09). */
        elegirPlazoRecepcion: function (opcion) {
            Sonido.pulsar();
            this.hotels.reception.opcion = this.hotels.reception.opcion === opcion ? null : opcion;
        },

        alquilarDesdeRecepcion: function () {
            const r = this.hotels.reception;
            if (!r.room || !r.opcion) return;

            Sonido.pulsar();
            this.executeRentRoom(r.room.id, r.opcion.type);
        },

        /*  ── El panel de la habitacion ───────────────────────────── */

        /*  Cambiar de seccion en el riel. Suena una sola vez aunque el clic
            cambie dos cosas: el sonido va en la funcion que hace el cambio,
            no en cada sitio desde el que se llama. */
        /*  Desde el 07/10 la habitación es un menú PEQUEÑO sin pestañas:
            las secciones que tocan van seguidas en la columna. */
        tieneSeccionHabitacion: function (id) {
            return this.seccionesDeLaHabitacion.some(function (s) { return s.id === id; });
        },

        /*  Cerrar el ascensor: Escape y el clic fuera, por el mismo sitio. */
        cerrarAscensor: function () {
            if (!this.elevator.visible) return;
            this.toggleElevator({ state: false });
            fetch('close', {});
        },

        irDeLaHabitacion: function (id) {
            if (id === this.habitacionTab) return;
            Sonido.pulsar();
            this.hotels.tabElegida = id;
        },

        /*  Elegir plazo NO cobra: se elige aqui y se confirma en el pie.
            Volver a pulsar el mismo lo suelta. */
        elegirPlazo: function (option) {
            Sonido.pulsar();
            const ya = this.hotels.opcionElegida;
            this.hotels.opcionElegida = (ya && ya.type === option.type) ? null : option;
        },

        /*  Alquilar sin dialogo: el boton del pie ya dice el plazo y el
            precio, asi que preguntarlo otra vez en un cuadro centrado es
            preguntar dos veces lo mismo. Igual que en el mostrador. */
        alquilarLaHabitacion: function () {
            const o = this.hotels.opcionElegida;
            if (!o) return;

            Sonido.pulsar();
            this.executeRentRoom(this.hotels.roomCreationData.id, o.type);
        },

        /*  Retirar la pregunta del pie sin contestarla. */
        cancelarEnLaHabitacion: function () {
            Sonido.pulsar();
            this.hotels.confirmandoHabitacion = null;
        },

        /*  Cerrar la habitacion, por los tres caminos: Escape, el clic fuera
            y la accion que termina el trabajo.

            El foco se suelta YA y el desmontaje espera los 280 ms de la
            animacion. Al reves, el raton se queda preso mientras la pantalla
            ya parece cerrada; y si el aviso no llegara nunca, se queda preso
            del todo y solo se sale reconectando.
            Ver .claude/skills/origen-riel/SKILL.md

            Ni esto ni quien lo llama toca `visible`: esa es la del resto del
            recurso (avisos, ascensor, muebles, gizmo...), y apagarla aqui la
            dejaba apagada para siempre, porque solo el panel de admin la
            vuelve a encender. */
        cerrarHabitacion: function () {
            if (this.hotels.saliendoHabitacion) return;
            this.hotels.saliendoHabitacion = true;

            Sonido.deslizar();
            fetch('close', {});

            setTimeout(() => {
                //  Si en estos 280 ms se ha vuelto a abrir una puerta,
                //  `openRoomDetailPanel` ha bajado la bandera: lo que hay
                //  ahora es el panel nuevo y no se toca.
                if (!this.hotels.saliendoHabitacion) return;
                this.hotels.view = '';
                this.hotels.selected = null;
                this.hotels.roomCreationData = null;
                this.hotels.autoRenewSelected = false;
                this.hotels.opcionElegida = null;
                this.hotels.tabElegida = null;
                this.hotels.confirmandoHabitacion = null;
                this.hotels.saliendoHabitacion = false;
            }, 280);
        },

        cerrarRecepcion: function () {
            const r = this.hotels.reception;
            if (r.saliendo) return;

            r.saliendo = true;
            r.abierto = false;
            Sonido.deslizar();

            /*  El foco se suelta YA y el desmontaje espera. Al revés, el
                ratón se queda preso los 280 ms en los que la pantalla ya
                parece cerrada; y si el aviso no llegara nunca, se queda
                preso del todo y solo se sale reconectando.
                Ver .claude/skills/origen-riel/SKILL.md */
            fetch('close', {});

            setTimeout(() => {
                //  Igual que en la puerta: si el mostrador se ha vuelto a
                //  abrir entretanto, `openHotelReception` ha bajado la
                //  bandera y esto ya no es de este cierre.
                if (!r.saliendo) return;
                this.hotels.view = '';
                this.hotels.autoRenewSelected = false;
                r.hotel = null;
                r.rooms = [];
                r.room = null;
                r.opcion = null;
                r.filtro = 'todas';
                r.confirmando = null;
                r.saliendo = false;
            }, 280);
        },

        /*  Después de alquilar, renovar o dejar una habitación, la lista que
            se está mirando ya no dice la verdad. Se vuelve a pedir sin
            cerrar el panel: cerrarlo dejaría al jugador plantado delante del
            mostrador sin saber si ha ido bien. */
        refrescarRecepcion: function () {
            const r = this.hotels.reception;
            if (!r.hotel) return;

            fetch('refreshReception', { hotelID: r.hotel.id }).then((data) => {
                if (!data) {
                    this.cerrarRecepcion();
                    return;
                }

                r.hotel = data.hotel;
                r.rooms = data.rooms || [];
                r.opcion = null;
                r.confirmando = null;
                this.hotels.autoRenewSelected = false;

                /*  Si se estaba mirando una habitación se sigue mirando la
                    misma, ya con lo que acaba de pasar dentro: es la forma
                    de ver que el alquiler ha entrado. */
                if (r.room) {
                    const id = r.room.id;
                    r.room = r.rooms.filter(function (x) { return x.id === id; })[0] || null;
                }
            });
        },

        /*  El punto de recepción en el formulario de administración. Es
            opcional: quitarlo es dejarlo en cero, que es como este panel
            representa «sin poner» para todas las coordenadas. */
        setReceptionCoords: function () {
            fetch('startHotelReceptionPlacement', {}).then((result) => {
                if (result && result.success) {
                    this.hotels.creationData.reception_coords = result.coords;
                    this.sendNotification('success', this.translations.success, this.translations.receptionPoint);
                } else {
                    this.sendNotification('error', this.translations.cancel, this.translations.cancel);
                }
            });
        },

        quitarRecepcion: function () {
            this.$set(this.hotels.creationData, 'reception_coords', { x: 0, y: 0, z: 0 });
            this.sendNotification('success', this.translations.success, this.translations.receptionRemoved);
        },

        tieneRecepcion: function (datos) {
            const c = datos && datos.reception_coords;
            return !!(c && c.x && !(c.x === 0 && c.y === 0 && c.z === 0));
        },

        setHotelCoords: function () {
            fetch('startHotelEntrancePlacement', {}).then((result) => {
                if (result && result.success) {
                    this.hotels.creationData.coords = result.coords;
                    this.sendNotification('success', this.translations.success, this.translations.success);
                } else {
                    this.sendNotification('error', this.translations.cancel, this.translations.cancel);
                }
            });
        },

        setRoomDoorCoords: function () {
            fetch('startHotelDoorPlacement', {}).then((result) => {
                if (result && result.success) {
                    this.hotels.roomCreationData.door_coords = result.coords;
                    this.sendNotification('success', this.translations.success, this.translations.success);
                } else {
                    this.sendNotification('error', this.translations.cancel, this.translations.cancel);
                }
            });
        },

        rentRoom: function (roomID, rentalType) {
            this.OpenModal(
                this.translations.rentRoomTitle,
                this.translations.rentRoomConfirm,
                '<button class="btn-confirm" onclick="app.confirmRentRoom(' + roomID + ', \'' + rentalType + '\')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        confirmRentRoom: function (roomID, rentalType) {
            fetch('rentHotelRoom', {
                roomID: roomID,
                rental_type: rentalType,
                auto_renew: false
            }).then((result) => {
                if (result.status) {
                    this.hotels.view = '';
                    fetch('close', {});
                }
            });
            this.CloseModal();
        },

        renewRoom: function (roomID) {
            fetch('renewHotelRoom', { roomID: roomID }).then((result) => {
                if (result.status) {
                    if (this.hotels.view === 'reception') {
                        this.refrescarRecepcion();
                        return;
                    }

                    this.cerrarHabitacion();
                }
            });
        },

        evictRoom: function (roomID) {
            if (!roomID) {
                console.error("evictRoom: roomID is undefined");
                return;
            }

            /*  En el mostrador la pregunta se hace DENTRO de la columna, no
                en el diálogo centrado del panel de administración: ese trae
                su velo sobre toda la pantalla y su propio lenguaje, y al
                lado del riel se lee como si hubiera saltado otro programa.
                Ver .claude/skills/origen-riel/SKILL.md */
            if (this.hotels.view === 'reception') {
                Sonido.pulsar();
                this.hotels.reception.confirmando = 'abandonar';
                return;
            }

            /*  Y en la puerta igual, desde que este panel es un menu lateral:
                el dialogo centrado trae su velo sobre toda la pantalla y su
                propio lenguaje, y al lado del riel se leia como si hubiera
                saltado otro programa. */
            if (this.hotels.view === 'room_detail') {
                Sonido.pulsar();
                this.hotels.confirmandoHabitacion = 'abandonar';
                return;
            }

            this.OpenModal(
                this.translations.abandonRoomTitle,
                this.translations.abandonRoomConfirm,
                '<button class="btn-confirm" onclick="app.confirmEvictRoom(' + roomID + ')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        confirmEvictRoom: function (roomID) {
            fetch('evictHotelRoom', { roomID: roomID }).then((result) => {
                if (result.status) {
                    if (this.hotels.view === 'reception') {
                        this.refrescarRecepcion();
                        return;
                    }

                    this.cerrarHabitacion();
                }
            });
            this.CloseModal();
        },

        toggleAutoRenew: function (roomID, event) {
            const autoRenew = event.target.checked;
            fetch('setHotelRoomAutoRenew', {
                roomID: roomID,
                autoRenew: autoRenew
            }).then((result) => {
                if (result.status) {
                    //  La ficha del mostrador pinta el estado, asi que
                    //  tiene que enterarse de que ha cambiado.
                    if (this.hotels.reception.room && this.hotels.reception.room.id === roomID) {
                        this.hotels.reception.room.auto_renew = autoRenew ? 1 : 0;
                    }

                    this.sendNotification('success', this.translations.success, autoRenew ? this.translations.autoRenewalEnabled : this.translations.autoRenewalDisabled, true);
                } else {
                    this.sendNotification('error', this.translations.error, result.message, true);
                }
            });
        },

        toggleDoorLock: function (roomID) {
            fetch('toggleHotelRoomDoorLock', { roomID: roomID }).then((result) => {
                if (!result.status) return;

                /*  El cerrojo se toca desde dos sitios —la ficha de la
                    puerta y la del mostrador— y son dos objetos distintos.
                    Se actualiza el que corresponda, no el que hubiera. */
                if (this.hotels.roomCreationData && this.hotels.roomCreationData.id === roomID) {
                    this.hotels.roomCreationData.door_locked = result.door_locked;
                }

                if (this.hotels.reception.room && this.hotels.reception.room.id === roomID) {
                    this.hotels.reception.room.door_locked = result.door_locked;
                }
            });
        },

        confirmRentRoom: function (option) {
            const roomNumber = this.hotels.roomCreationData.room_number;
            const autoRenewText = this.hotels.autoRenewSelected ? '<br><small style="color: var(--ogn-t3)">' + this.translations.autoRenewEnabledDesc + '</small>' : '';

            const translatedType = option.type === 'daily' ? this.translations.daily : option.type === 'weekly' ? this.translations.weekly : option.type === 'monthly' ? this.translations.monthly : option.type;
            this.OpenModal(
                this.translations.rentRoomTitle + ' ' + roomNumber,
                this.translations.rentRoomDesc + '<br><br><strong>' + translatedType + '</strong> - $' + option.price + ' (' + (option.duration / 86400).toFixed(0) + ' ' + this.translations.days + ')' + autoRenewText,
                '<button class="btn-confirm" onclick="app.executeRentRoom(' + this.hotels.roomCreationData.id + ', \'' + option.type + '\')">' + this.translations.confirm + '</button>',
                this.translations.cancel,
                50
            );
        },

        executeRentRoom: function (roomID, rentalType) {
            fetch('rentHotelRoom', {
                roomID: roomID,
                rental_type: rentalType,
                auto_renew: this.hotels.autoRenewSelected
            }).then((result) => {
                if (result.status) {
                    //  Si se vino del mostrador, la cola sigue delante: se
                    //  vuelve a la lista ya al dia en vez de cerrarlo todo.
                    if (this.hotels.view === 'reception') {
                        this.refrescarRecepcion();
                        return;
                    }

                    this.cerrarHabitacion();
                }
            });
            this.CloseModal();
        },

        rentRoomFromPanel: function (roomID, rentalType) {
            fetch('rentHotelRoom', {
                roomID: roomID,
                rental_type: rentalType,
                auto_renew: this.hotels.autoRenewSelected
            }).then((result) => {
                if (result.status) {
                    this.hotels.view = 'list';
                    this.hotels.autoRenewSelected = false;
                    fetch('close', {});
                }
            });
        },

        enterRoomFromPanel: function (roomID) {
            /*  Por `cerrarHabitacion` y no cerrando a mano: entrar es la
                accion que termina el trabajo, y tiene que salir por el mismo
                sitio que Escape. Cerrada a pelo, la pantalla desaparecia de
                golpe mientras las otras tres formas se deslizaban.
                Ver .claude/skills/origen-riel/SKILL.md */
            Sonido.pulsar();
            fetch('enterHotelRoomFromPanel', { roomID: roomID });
            this.cerrarHabitacion();
        },

        getRemainingTime: function (item) {
            if (!item.data || !item.data.rentExpires) return null;
            const expireTimestamp = item.data.rentExpires;
            const currentTimestamp = Date.now() / 1000;
            const remainingSeconds = expireTimestamp - currentTimestamp;

            if (remainingSeconds <= 0) return 'Expired';

            const days = Math.floor(remainingSeconds / 86400);
            const hours = Math.floor((remainingSeconds % 86400) / 3600);

            if (days > 0) {
                return `${days}d ${hours}h`;
            } else {
                const minutes = Math.floor((remainingSeconds % 3600) / 60);
                return `${hours}h ${minutes}m`;
            }
        },

        /*  La caducidad llega de dos sitios con dos formas distintas: de la
            base de datos como texto ('2026-09-10 14:00:00') y de la memoria
            del servidor como segundos UNIX, que es lo que devuelve
            os.time(). Sin distinguirlos, los segundos se leen como
            milisegundos y todo caduca en enero de 1970 —que es justo lo que
            salía en la ficha de la habitación recién alquilada, hasta el
            siguiente reinicio—. */
        formatDate: function (valor) {
            if (!valor) return '—';

            let date;

            if (typeof valor === 'number') {
                /*  Nada por debajo de 10^11 puede ser milisegundos: serían
                    los años setenta. Así que son segundos. */
                date = new Date(valor < 100000000000 ? valor * 1000 : valor);
            } else {
                //  MySQL da un espacio donde el estándar quiere una T.
                date = new Date(String(valor).replace(' ', 'T'));
            }

            if (isNaN(date.getTime())) return '—';

            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const year = date.getFullYear();
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            return `${day}/${month}/${year} ${hours}:${minutes}`;
        },
    },
    watch: {
        hayMenuPequeno(abierto) {
            if (abierto) Sonido.deslizar();
        },
        /*  Si «Tu vivienda» se cierra con un diálogo pequeño suyo encima
            (dar llave, puerta), el diálogo se va con ella. */
        'house.visible'(v) {
            if (!v && this.modalChico > 0) this.CloseModal();
        },
    },
    mounted() {
        window.addEventListener('message', (e) => {
            const d = e.data;
            if (d && d.accion === 'origen:marca:puesta' && d.marca) this.marca = d.marca;
        });
        this.listener = window.addEventListener('message', (event) => {
            const item = event.data;
            switch (item.action) {
                case 'toggleManagement':
                    this.houseList = item.houseList;
                    this.ToggleManagement(item.state);
                    break;
                case 'updateManagement':
                    if (this.menu.management) {
                        this.houseList = item.houseList;
                        if (this.selectedMapHouse && this.houseList && this.houseList[this.selectedMapHouse.id]) {
                            this.selectedMapHouse = this.houseList[this.selectedMapHouse.id];
                        }
                    }
                    break;
                case 'toggleHouseMenu':
                    this.showHousePanel(item);
                    break;
                case 'controls':
                    if (!item || !item.keys) {
                        this.controlsHelp.visible = false;
                        return
                    }
                    this.ControlsNotify(item.keys, item.title);
                    break;
                case 'preview':
                    if (item.show) {
                        let items = [];
                        switch (item.type) {
                            case 'exteriors':
                                items = this.exteriors;
                                break;
                        }
                        this.previewOptions(items, item.path, item.title);
                    } else {
                        this.closePreview();
                    }
                    break;
                case 'setLoading':
                    this.loading = item.state;
                    break;
                case 'setInfo':
                    this.info.visible = item.state;
                    if (item.text) {
                        this.info.text = item.text;
                    }
                    break;
                case 'buyHouse':
                    this.buyHouse(item.data, item.garage);
                    break;
                case 'toggleFurnitureMenu':
                    this.toggleFurnitureMenu(item.state);

                    if (item.furniture) {
                        this.furniture.buyedItems = item.furniture;
                    }
                    break;
                /*  El raton se ha soltado a la fuerza (OrigenFoco.AlSoltar):
                    fuera todo lo que se vea, sin pedirle nada mas a Lua,
                    que ya ha recogido su parte. */
                case 'forzarCierre':
                    if (this.buyMenu) this.cerrarCompra();
                    //  Cerrar la pregunta de compra de un mueble le pide a Lua
                    //  reabrir el menu (cancelFurniturePurchase), que coge el
                    //  foco: aqui no.
                    if (this.currentModal === 'confirmBuyFurniture') this.currentModal = null;
                    this.CloseModal();
                    if (this.upgrades.visible) this.buyUpgrade(false);
                    if (this.menu.management) this.ToggleManagement(false);
                    if (this.house.visible) this.showHousePanel({ state: false, sinSoltar: true });
                    this.furniture.visible = false;
                    this.furniture.isMoving = false;
                    this.furniture.selectedEntity = false;
                    this.furniture.currentObject = false;
                    this.gizmoMode = false;
                    if (this.menu.houses.visible) this.ToggleHousesMenu(false, false, false);
                    if (this.hotels.view === 'reception') this.cerrarRecepcion();
                    else if (this.hotels.view === 'room_detail') this.cerrarHabitacion();
                    if (this.elevator.visible) this.toggleElevator({ state: false });
                    break;
                case 'toggleFurnitureMoving':
                    this.furniture.isMoving = item.state;
                    break;

                case 'toggleGizmoMode':
                    this.gizmoMode = item.state || !this.gizmoMode;
                    break;

                case 'addedToCartFromGizmo':
                    let gzModel = item.model;
                    let gzCat = (this.furniture.items && this.furniture.selectCategory !== null && this.furniture.items[this.furniture.selectCategory]) || null;
                    let gzItem = gzCat && gzCat.items ? gzCat.items.find((it) => it.model === gzModel) : null;
                    if (!gzItem && this.furniture.items) {
                        for (const cat of Object.values(this.furniture.items)) {
                            if (cat && cat.items) {
                                const found = cat.items.find((it) => it.model === gzModel);
                                if (found) {
                                    gzItem = found;
                                    gzCat = cat;
                                    break;
                                }
                            }
                        }
                    }
                    let gzPriceNum = 0;
                    let gzPriceStr = app.translations.free || 'Gratis';
                    if (gzItem && gzItem.price !== undefined && gzItem.price !== null) {
                        gzPriceNum = Number(gzItem.price) || 0;
                    } else if (this.furniture.defaultPrice > 0) {
                        gzPriceNum = Number(this.furniture.defaultPrice) || 0;
                    }
                    if (gzPriceNum > 0) {
                        gzPriceStr = this.precio(gzPriceNum);
                    }
                    let gzLabel = (gzItem && (gzItem.label || gzItem.name)) || gzModel;

                    this.carrito.push({
                        cartId: item.cartId,
                        id: item.id,
                        model: gzModel,
                        label: gzLabel,
                        price: gzPriceNum,
                        priceText: gzPriceStr,
                        category: gzCat ? (gzCat.label || '') : ''
                    });
                    this.furniture.currentObject = false;
                    this.furniture.selectedEntity = false;
                    this.furniture.isMoving = false;
                    this.sendNotification('info', 'Carrito', `${gzLabel} añadido al carrito (${this.carrito.length})`);
                    break;

                case 'togglePreviewOpacity':
                    this.togglePreviewOpacity(item.state);

                    if (this.menu.preview.visible) {
                        this.ControlsNotify([
                            { key: 'E', text: this.translations.view },
                            { key: 'ENTER', text: this.translations.confirm }
                        ])
                    }
                    break;

                case 'playAlarm':
                    this.PlayAlarm();
                    break;

                case 'updateAlarm':
                    this.UpdateAlarm(item.volume);
                    break;

                case 'stopAlarm':
                    this.StopAlarm();
                    break;

                case 'toggleHousesMenu':
                    this.ToggleHousesMenu(item.show, item.houses, item.focus);
                    break;
                case 'confirmFurniturePlacement':
                    if (this.furniture.isMoving || this.furniture.action === 'create' || this.furniture.currentObject) {
                        this.confirmBuyFurniture();
                    }
                    break;
                case 'updateFurnitureData':
                    this.furniture.selectedEntity = item.entity;
                    this.furniture.isMoving = true;
                    break;
                case 'toggleElevator':
                    this.toggleElevator(item);
                    break;
                case 'openHotelReception':
                    this.hotels.reception.hotel = item.hotel;
                    this.hotels.reception.rooms = item.rooms || [];
                    this.hotels.reception.filtro = 'todas';
                    this.hotels.reception.room = null;
                    this.hotels.reception.opcion = null;
                    this.hotels.reception.confirmando = null;
                    this.hotels.reception.saliendo = false;
                    this.hotels.autoRenewSelected = false;
                    this.hotels.view = 'reception';
                    this.hotels.reception.abierto = true;
                    Sonido.deslizar();
                    break;

                case 'openRoomDetailPanel':
                    this.hotels.view = 'room_detail';
                    this.hotels.selected = item.hotel;
                    this.hotels.roomCreationData = item.room;
                    /*  Limpio: lo elegido en la habitacion de antes no vale
                        para esta, y la seccion la decide `habitacionTab`. */
                    this.hotels.opcionElegida = null;
                    this.hotels.tabElegida = null;
                    this.hotels.confirmandoHabitacion = null;
                    this.hotels.autoRenewSelected = false;
                    this.hotels.saliendoHabitacion = false;
                    Sonido.deslizar();
                    break;
            }
        });

        window.addEventListener('keyup', this.handleOnKeyUp);
        window.addEventListener('keydown', this.handleOnKeyDown);

        fetch('getAllData', {}).then((data) => {
            this.exteriors = data.exteriors;
            this.shells = data.shells;
            this.ipls = data.ipls;
            this.translations = data.translations;
            this.furniture.categories = data.furnitureCategories;
            this.furniture.items = data.furnitureItems;
            this.house.upgrades = data.upgrades;
            this.house.doorLimit = data.doorLimit;
            this.allowedExtensions = data.allowedExtensions;
            this.stages = data.stages;
            this.furniture.defaultPrice = data.defaultPrice;
            this.paymentMethods = data.paymentMethods;
            if (data.mloBaseLimits) this.mloBaseLimits = data.mloBaseLimits;
            if (data.mloSlotPrice) this.mloSlotPrice = data.mloSlotPrice;
        });
    },
    beforeDestroy() {
        window.removeEventListener('message', this.listener);
        window.removeEventListener('keyup', this.handleOnKeyUp);
        window.removeEventListener('keydown', this.handleOnKeyDown);
    },
});

$(document).on('mouseenter', '.btn-sound', function () {
    s_over.currentTime = '0';
    s_over.play();
});

$(document).on('click', '.btn-sound', function () {
    s_click.currentTime = '0';
    s_click.play();
});

$(document).on('click', '.house_types .btn.option', function () {
    const this_ = $(this);
    let type = this_.attr('type');
    $('.house_types .btn.option').removeClass('active');
    $(`.house_types .btn.option[type="${type}"]`).addClass('active');
    if (type == 'mlo') {
        $('.construction-content').hide(150);
        $('.allow-vehicles').addClass('disabled');
        $('.check-allowvehicles').prop('checked', false).prop('disabled', true);
        $('.int_categories').hide(150);
    } else if (type == 'ipl' || type == 'libre') {
        $('.construction-content').show(150);
        $('.allow-vehicles').removeClass('disabled');
        $('.check-allowvehicles').prop('disabled', false);
        $('.int_categories').hide(150);
    } else {
        $('.construction-content').show(150);
        $('.allow-vehicles').removeClass('disabled');
        $('.check-allowvehicles').prop('disabled', false);
        $('.int_categories').show(150);
    }
});

$(document).on('click', '.door_types .btn.option', function () {
    const this_ = $(this);
    let type = this_.attr('type');
    this_.closest('.door_types').find('.btn.option').removeClass('active');
    this_.closest('.door_types').find(`.btn.option[type="${type}"]`).addClass('active');
});

$(document).on('click', '.creation_types .btn.option', function () {
    const this_ = $(this);
    let type = this_.attr('type');
    $('.creation_types .btn.option').removeClass('active');
    $(`.creation_types .btn.option[type="${type}"]`).addClass('active');
});

$(document).on('click', '.interior_categories .btn.option', function () {
    const this_ = $(this);
    let type = this_.attr('type');
    $('.interior_categories .btn.option').removeClass('active');
    $(`.interior_categories .btn.option[type="${type}"]`).addClass('active');
});

$(document).on('click', '.payment-method .btn.option', function () {
    const this_ = $(this);
    let type = this_.attr('type');
    $('.payment-method .btn.option').removeClass('active');
    $(`.payment-method .btn.option[type="${type}"]`).addClass('active');
});

$(document).on("change", ".check-construction", function () {
    if ($(this).is(":checked")) {
        $(".construction-options").show(150);
    } else {
        $(".construction-options").hide(150);
    }
});

$(document).on('mousedown', function (e) {
    if ($(".furniture:hover, .mb-zona:hover").length) return;

    if (e.which == 1) {
        if (app.currentModal) return;
        if (app.furniture.isMoving && (app.furniture.selectedEntity || app.furniture.currentObject || app.furniture.action === 'create')) {
            if (app.furniture.action === 'create' || app.furniture.currentObject) {
                app.confirmBuyFurniture();
            } else if (app.furniture.action === 'move') {
                fetch('onClick', { action: 'update' }).then((data) => {
                    if (data) {
                        app.furniture.selectedEntity = false;
                        app.furniture.isMoving = false;
                        app.furniture.currentObject = false;

                        fetch('cancelFurniturePurchase', {});
                    }
                });
            }
            app.gizmoMode = false;
            s_pop.currentTime = '0';
            s_pop.play();
        } else {
            fetch('onClick', {}).then((data) => {
                if (!data) return;
                app.furniture.selectedEntity = data;
                app.furniture.isMoving = true;
                s_pop.currentTime = '0';
                s_pop.play();
            });
        }
    }
});

$(document).on('mousemove', function (e) {
    if (app.furniture.isMoving) {
        fetch('onMove', {});
    }

    if ($(".furniture:hover").length) return;
    if (app.furniture.action == 'create') return;

    if (app.furniture.visible) fetch('onHover', {});
});

$(document).on("wheel", function (event) {
    if (!app.furniture.isMoving) {
        return;
    }

    fetch('onRotate', { direction: event.originalEvent.deltaY > 0 ? 'left' : 'right' });
});

$(document).on('mouseenter', '.upgrade', function (e) {
    e.preventDefault();
    const upgrade = $(this).data('upgrade');


    if (!app.house.upgrades[upgrade].locked) {
        return;
    }

    if (!app.upgrades.info.visible) {
        app.upgrades.info.visible = true;
    }

    if (app.house.upgrades[upgrade]) {
        app.upgrades.info.title = app.house.upgrades[upgrade].label;
        app.upgrades.info.text = app.house.upgrades[upgrade].description;
    }

    app.upgrades.info.position = $(this).offset().top + 'px';
});

$(document).on('mouseleave', '.upgrade', function (e) {
    e.preventDefault();

    if (app.upgrades.info.visible) {
        app.upgrades.info.visible = false;
    }
})