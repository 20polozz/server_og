
const center_x = 117.3;
const center_y = 172.8;
const scale_x = 0.02072;
const scale_y = 0.0205;


/*  Leaflet es prestado: lo sirve origen_map. Si esta NUI carga cuando
    origen_map todavía no está montado en el cliente (orden de arranque, o un
    `restart origen_map`), el <script> del index.html falla UNA vez y window.L
    no existe hasta reconectar. Antes este fichero usaba L al cargar y reventaba
    («L is not defined»). Ahora lo que necesita L se prepara al abrir el mapa, y
    si falta se vuelve a pedir (mismo arreglo que MapaGrande.vue de
    origen_inventory). */
const LEAFLET = 'https://cfx-nui-origen_map/html/leaflet/1.8.0/leaflet';
let pidiendoLeaflet = null;

function pedirLeafletUnaVez() {
    return new Promise((listo) => {
        const r = Date.now();
        // El css también: si el js falló, el css casi seguro que falló con él.
        const css = document.createElement('link');
        css.rel = 'stylesheet';
        css.href = `${LEAFLET}.css?r=${r}`;
        document.head.appendChild(css);

        const js = document.createElement('script');
        js.src = `${LEAFLET}.js?r=${r}`;
        js.onload = () => listo(!!window.L);
        js.onerror = () => { js.remove(); css.remove(); listo(false); };
        document.head.appendChild(js);
    });
}

// Reintenta unas cuantas veces: al conectar, origen_map puede tardar en montarse.
function pedirLeaflet() {
    if (window.L) return Promise.resolve(true);
    if (pidiendoLeaflet) return pidiendoLeaflet;
    pidiendoLeaflet = (async () => {
        for (let i = 0; i < 6; i++) {
            if (i) await new Promise((r) => setTimeout(r, 2000));
            if (window.L || await pedirLeafletUnaVez()) return true;
        }
        return false;
    })().finally(() => { pidiendoLeaflet = null; });
    return pidiendoLeaflet;
}

var CUSTOM_CRS
var mapDealerships

// Crea lo que depende de Leaflet la primera vez que hay L. Contesta si lo hay.
function prepararLeaflet() {
    if (CUSTOM_CRS) return true;
    if (!window.L) return false;

    CUSTOM_CRS = L.extend({}, L.CRS.Simple, {
        projection: L.Projection.LonLat,
        scale: function (zoom) {
            return Math.pow(2, zoom);
        },
        zoom: function (sc) {
            return Math.log(sc) / 0.6931471805599453;
        },
        distance: function (pos1, pos2) {
            var x_difference = pos2.lng - pos1.lng;
            var y_difference = pos2.lat - pos1.lat;
            return Math.sqrt(x_difference * x_difference + y_difference * y_difference);
        },
        transformation: new L.Transformation(scale_x, center_x, -scale_y, center_y),
        infinite: true
    });

    mapDealerships = L.tileLayer('./assets/mapStyles/{z}/{x}/{y}.jpg', {
        minZoom: 0,
        maxZoom: 5,
        noWrap: true,
        id: 'styleAtlas map'
    });
    return true;
}

prepararLeaflet();

let map

function initMap(dealerships = []) {
    if (!prepararLeaflet()) {
        pedirLeaflet().then((si) => {
            if (!si) {
                console.warn('[origen_dealership] Leaflet no está cargado: el mapa se queda vacío');
                return;
            }
            // Solo si la pestaña del mapa sigue abierta y nadie lo ha montado ya.
            if (!map && document.getElementById('map-container')) initMap(dealerships);
        });
        return;
    }

    if (map) {
        map.remove(); // más seguro que map = null
    }

    map = L.map('map-container', {
        crs: CUSTOM_CRS,
        minZoom: 1.5,
        maxZoom: 5,
        boxZoom: false,
        maxNativeZoom: 5,
        preferCanvas: true,
        layers: [mapDealerships],
        center: [0, 300],
        zoom: 1.5,
        zoomControl: false,
        maxBoundsViscosity: 1.0,
        tms: false,
        noWrap: true
    });

    setTimeout(() => {
        map.invalidateSize();
        var southWest = map.unproject([0, 8592], map.getMaxZoom());
        var northEast = map.unproject([8192, 0], map.getMaxZoom());
        var bounds = L.latLngBounds(southWest, northEast);
        map.setMaxBounds(bounds);
    }, 500);
        let storeIcon = L.divIcon({
            iconSize: [20, 20],
			iconAnchor: [10, 10],
			popupAnchor: [5, -5],
            className: 'store-marker',

            html: `<div class="marker-icon"></div>`,
        });

    dealerships.forEach(dealership => {
        // Uno sin coordenadas no se pinta, en vez de tumbar el mapa entero.
        if (!dealership.coords) return;
        const { x, y } = dealership.coords;
        const latLng = L.latLng(y, x);
        const marker = L.marker(latLng, {icon: storeIcon})
        marker.addTo(map)
        marker.bindPopup(`<b>${dealership.name}</b>`);
          marker.on('mouseover', function(e) {
            this.openPopup();
        })

        marker.on('mouseout', function(e) {
            this.closePopup();
        })
    });
}