const center_x = 117.3;
const center_y = 172.8;
const scale_x = 0.02072;
const scale_y = 0.0205;

/*  Leaflet es prestado: lo sirve origen_map. Si el menú abre cuando origen_map
    todavía no está montado en el cliente (orden de arranque, o un
    `restart origen_map`), el <script> del index.html falla UNA vez y window.L
    no existe hasta reconectar. Antes este fichero usaba L al cargar y reventaba
    entero («L is not defined»), y con él mapFunctions y todo lo de abajo.
    Ahora lo que necesita L se prepara al usarlo, y si falta se vuelve a pedir
    (mismo arreglo que MapaGrande.vue de origen_inventory). */
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
var mapStatic
var CentralGroup

let central = [];

let Blips = {};

let Circles = {};

var Icons = {};

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

    mapStatic = L.tileLayer('https://cfx-nui-origen_map/html/teselas/styleAtlas/{z}/{x}/{y}.jpg', { minZoom: 0, maxZoom: 5, noWrap: true, id: 'styleAtlas map' })

    CentralGroup = L.layerGroup();
    Icons["Central"] = CentralGroup;
    return true;
}

prepararLeaflet();

// Sube en cada carga y en cada destrucción: un Leaflet que llega tarde solo
// monta el mapa si nadie lo ha cerrado o vuelto a pedir mientras tanto.
let turnoMapaCentral = 0;

var mapTerritorios
var mapCentral

let pendingblips = {}
let spawnPointsMeta = {}
let currentSelectedSpawn = null

window.currentSelectedSpawn = null

function setSelectedSpawn(index, focus = false) {
    const spawnMeta = spawnPointsMeta[index]
    if (!spawnMeta) return

    currentSelectedSpawn = spawnMeta
    window.currentSelectedSpawn = spawnMeta

    fetch("SelectSpawn", { x: spawnMeta.lng, y: spawnMeta.lat })

    if (!spawnMeta.option) {
        $(".btn-aparecer").html('Despertarse <i class="lni lni-angle-double-right"></i>').addClass("active").removeClass("first").addClass("location")
    } else {
        $(".btn-aparecer").html('Despertarse <i class="lni lni-angle-double-right"></i>').addClass("active").removeClass("location").addClass("first")
    }

    renderSpawnSpotlight({ name: spawnMeta.name, type: spawnMeta.type, lat: spawnMeta.lat, lng: spawnMeta.lng }, spawnMeta.totalSpawns, index)

    if (focus) {
        mapFunctions.setAlertFocus(index)
    }
}

function getSpawnTypeLabel(type) {
    if (type == "lastplace" || type == "esx_spawn" || type == "qb_spawn") return "Última ubicación";
    if (type == "house" || type == "apartment" || type == "first_apartment") return "Propiedad";
    if (type == "custom_place") return "Punto del servidor";
    return "Punto de aparición";
}

function renderSpawnSpotlight(spawnData = {}, total = null, index = null) {
    const playersOnline = ($("#players-online").text() || "").trim() || "--/--";
    const staffOnline = ($("#staff-online").text() || "").trim() || "--";
    const latency = ($("#server-latency").text() || "").trim() || "-- MS";
    const uptime = ($("#server-uptime").text() || "").trim() || "--";
    const weather = spawnData?.weather || spawnData?.currentWeather || spawnData?.serverWeather;

    $("#spawn-server-online").text(playersOnline);
    $("#spawn-server-staff").text(staffOnline);
    $("#spawn-server-latency").text(latency);
    $("#spawn-server-uptime").text(uptime);

    if (weather) {
        $("#spawn-server-note").text(`Condiciones actuales: ${String(weather).toUpperCase()}`);
    } else {
        $("#spawn-server-note").text("Información en tiempo real del servidor antes de despertar.");
    }
}

window.renderSpawnSpotlightFromElement = function (element) {
    const el = $(element);
    if (!el || !el.length) return;

    const lat = parseFloat(el.attr("y"));
    const lng = parseFloat(el.attr("x"));
    const name = el.find(".spawn-name").text().trim() || el.attr("name");
    const type = el.attr("type");
    renderSpawnSpotlight({ name, type, lat, lng });
}


function cargarMapaCentral(option) {
    destruirMapaCentral();
    if (!prepararLeaflet()) {
        const turno = turnoMapaCentral;
        pedirLeaflet().then((si) => {
            if (!si) {
                console.warn('[origen_titlemenu] Leaflet no está cargado: el mapa de aparición se queda vacío');
                return;
            }
            if (turno === turnoMapaCentral && prepararLeaflet()) cargarMapaCentral(option);
        });
        return;
    }
    if (!mapCentral) {
        mapCentral = L.map('mapCentral', {
            crs: CUSTOM_CRS,
            minZoom: 1.5,
            maxZoom: 5,
            boxZoom: false,
            maxNativeZoom: 5,
            preferCanvas: true,
            layers: [mapStatic, Icons["Central"]],
            center: [1700, 300],
            zoom: 1.5,
            zoomControl: false,
            maxBoundsViscosity: 1.0,
            tms: false,
            noWrap: true
        });

        var southWest = mapCentral.unproject([0, 8592], mapCentral.getMaxZoom());
        var northEast = mapCentral.unproject([8192, 0], mapCentral.getMaxZoom());

        var bounds = L.latLngBounds(southWest, northEast);
        mapCentral.setMaxBounds(bounds);

        fetch("GetSpawns", { citizenid: selectedSlot.attr("citizenid") }).then((data) => {
            if (data && data.spawns) {
                if (window.renderSpawnOverview) {
                    window.renderSpawnOverview(data);
                }
                spawnPointsMeta = {}
                data.spawns.map((spawn, index) => {
                    createSpawnPoint(index, spawn.id, spawn.coordY, spawn.coordX, spawn.label, spawn.type, spawn.apartmentType, !data.hasApartment, data.spawns.length);
                });
                if (data.spawns.length) {
                    let defaultIndex = data.spawns.findIndex((spawn) => spawn.type == "lastplace" || spawn.type == "esx_spawn" || spawn.type == "qb_spawn")
                    if (defaultIndex < 0) defaultIndex = 0
                    setSelectedSpawn(defaultIndex, true)
                } else {
                    renderSpawnSpotlight();
                    $(".btn-aparecer").removeClass("active first location")
                    currentSelectedSpawn = null
                    window.currentSelectedSpawn = null
                }
            }
        });
        mapCentral.invalidateSize()
    }
}

function createSpawnPoint(i, id, lat, lng, name, type, apartmentType, option, totalSpawns = 1) {
    spawnPointsMeta[i] = { id, lat, lng, name, type, apartmentType, option, totalSpawns }
    addBlipAtCoords(i, lat, lng, type, option);
}

function destruirMapaCentral() {
    turnoMapaCentral++;
    spawnPointsMeta = {}
    currentSelectedSpawn = null
    window.currentSelectedSpawn = null
    renderSpawnSpotlight();
    mapFunctions.alerts = [];
    if (mapCentral) {
        mapCentral.remove();
        mapCentral = null;
        Blips = {};
        Icons["Central"].clearLayers();
    }
}

function addTerritorio(lat, lng, radius, name, percent, color) {
    territorios.push([lat, lng, radius,
        new L.circle([lat, lng], {
            radius: radius,
            opacity: .9,
            color: "transparent",
            fillColor: color || "#000000",
            fillOpacity: 0.5,
        }).addTo(Icons["Territories"]).on("click", function () {
            $(".gangs .info-mapa").html(`<h3>${name}</h3>`).toggleClass("show");
        })
        // .bindPopup("<b>"+name+"</b><br>Dominio "+percent+"%<br>Radio "+radius+"m")
    ]);
    let territory = territorios[currentViewTerritory]
    mapTerritorios.setView([territory[0], territory[1]], 5 - Math.floor(territory[2] / 200));
}


function clearTerritories() {
    for (let v of territorios)
        mapTerritorios.removeLayer(v[3]);

    territorios = []
}

function addBlipAtCoords(i, lat, lng, type, option) {
    let markerClass = "spawn-marker-location";
    let markerIcon = '<i class="fa-solid fa-map-pin"></i>';
    if (type == "house" || type == "apartment" || type == "first_apartment") {
        markerClass = "spawn-marker-house";
        markerIcon = '<i class="fa-solid fa-house"></i>';
    }
    if (type == "lastplace" || type == "esx_spawn" || type == "qb_spawn") {
        markerClass = "spawn-marker-lastplace";
        markerIcon = '<i class="fa-solid fa-map-pin"></i>';
    }

    const icondata = L.divIcon({
        className: "spawn-map-marker-wrapper",
        iconSize: [34, 34],
        iconAnchor: [17, 17],
        popupAnchor: [0, -16],
        html: `<div class="spawn-map-marker ${markerClass}">${markerIcon}</div>`
    });

    central.push([i, new L.marker([lat, lng], {
        icon: icondata
    }).addTo(Icons["Central"]).on("click", function () {
        setSelectedSpawn(i, true);


        //     if($(".police .central .info-mapa").hasClass("show")){
        //         $(".police .central .info-mapa").toggleClass("show");
        //         setTimeout(()=>{

        //             mapFunctions.showCentralAlert(title, street, time, id);

        //         }, 300)
        //     } else {
        //         mapFunctions.showCentralAlert(title, street, time, id);


        //     }
        // })]);
        // mapCentral.setView([lat, lng]);
    })]);


}


function CreateBlip(map, blipid, coords, blip, name) {
    if (map) {

        //COMRPUEBA SI EL BLIP EXISTE Y SI EXISTE, LLAMA A LA FUNCIÓN PARA ACTUALIZARLO
        if (Blips[blipid]) {
            mapFunctions.updateBlip(blipid, coords, blip, name);
            return;
        }


        icondata = L.icon({
            iconUrl: blip,
            iconSize: [20, 20], // size of the icon
            iconAnchor: [0, 20], // point of the icon which will correspond to marker's location
            popupAnchor: [9, -16] // point from which the popup should open relative to the iconAnchor
        });

        Blips[blipid] = L.marker([coords.y, coords.x], { icon: icondata }).addTo(map).bindPopup("<b>" + name + "</b>");

    }
}

function CreateReferenceBlip(map, blipid, coords, blip, name, color) {
    if (map) {
        //COMRPUEBA SI EL BLIP EXISTE Y SI EXISTE, LLAMA A LA FUNCIÓN PARA ACTUALIZARLO
        if (Blips[blipid]) {
            mapFunctions.updateBlipRef(blipid, coords, blip, name, color);
            return;
        }

        // if (!icondata) {
        icondata = L.divIcon({
            iconSize: [20, 20], // size of the icon
            iconAnchor: [10, 10], // point of the icon which will correspond to marker's location
            popupAnchor: [5, -5], // point from which the popup should open relative to the iconAnchor
            html: `<div class="reference-blip" style="background-color: ${color}"><img src="${blip}"></div>`
        });
        // } else {
        //     icondata.iconUrl = icondata.iconUrl || 'https://i.imgur.com/lIqc9eG.png';
        //     icondata.iconSize = icondata.iconSize || [40, 40];
        //     icondata.iconAnchor = icondata.iconAnchor || [22, 94];
        //     icondata.popupAnchor = icondata.popupAnchor || [-3, -76];
        //     icondata = L.icon(icondata);
        // }

        Blips[blipid] = L.marker([coords.y + 5, coords.x + 5], { icon: icondata }).addTo(map).bindPopup("<b>" + name + "</b>");

    }
}




const mapFunctions = {
    policeSources: [],
    showCentralAlert: (title, street, time, id) => {
        $(".police .central .info-mapa .info-data .info-title").html(title)
        $(".police .central .info-mapa .info-data .id-label .label").html(id)

        $(".police .central .info-mapa .info-data .location-label .location").html(street)
        // $(".police .central .info-mapa .info-data .time-label .time").html(time)
        $(".police .central .info-mapa").toggleClass("show");
        // $(".police .central .info-mapa").html(`<h3>${title}</h3> <div>${message}</div>`).toggleClass("show");
    },
    setBlipFocus: (blipid) => {
        if (Blips[blipid]) {
            Blips[blipid].openPopup();
            // mapCentral.setView(Blips[blipid].getLatLng());
            // mapCentral.setZoom(5);

            mapCentral.setView(Blips[blipid].getLatLng(), 5);

        }
    },

    setAlertFocus: (alertid) => {


        central.map(alert => {
            if (alert[0] == parseInt(alertid)) {
                // mapCentral.panTo(alert[1].getLatLng(), { animate: true });
                // mapCentral.setZoom(5);
                mapCentral.setView(alert[1].getLatLng(), 5);
            }
        });


    },


    destroyBlip: (blipid) => {
        if (Blips[blipid]) {
            mapCentral.removeLayer(Blips[blipid]);
            delete Blips[blipid];
        }

    },

    updateBlip: (blipid, coords, blip, name) => {
        if (Blips[blipid]) {
            Blips[blipid].setLatLng([coords.y, coords.x]);
            Blips[blipid].setIcon(L.icon({
                iconUrl: blip,
                iconSize: [20, 20], // size of the icon
                iconAnchor: [0, 20], // point of the icon which will correspond to marker's location
                popupAnchor: [9, -16] // point from which the popup should open relative to the iconAnchor
            }));
            Blips[blipid].bindPopup("<b>" + name + "</b>");
        }
    },
    updateBlipRef: (blipid, coords, blip, name, color) => {
        if (Blips[blipid]) {
            Blips[blipid].setLatLng([coords.y + 5, coords.x - 5]);
            Blips[blipid].setIcon(L.divIcon({
                iconSize: [20, 20], // size of the icon
                iconAnchor: [10, 10], // point of the icon which will correspond to marker's location
                popupAnchor: [5, -5], // point from which the popup should open relative to the iconAnchor
                html: `<div class="reference-blip" style="background-color: ${color}"><img src="${blip}"></div>`
            }));
            Blips[blipid].bindPopup("<b>" + name + "</b>");
        }
    },
    checkPoliceSources: (data) => {

        //comprueba si data existe. Si existe, comprueba si data y policeSources son iguales. Si algún elemento no coincide, lo muestra en un console.log

        if (data) {
            mapFunctions.policeSources.forEach((element) => {
                if (!data.includes(element)) {
                    mapFunctions.destroyBlip(element);
                }
            });
            mapFunctions.policeSources = data;
        }
    },

    CreateCircle: (map, id, coords, radius, color1, color2, type) => {
        if (map) {

            //COMRPUEBA SI EL BLIP EXISTE  Y SI EXISTE, LLAMA A LA FUNCIÓN PARA ACTUALIZARLO
            if (Circles[id]) {
                // mapFunctions.updateCircle(id, coords, radius, color1, color2, type);
                mapFunctions.destroyCircle(id);
                // return;
            }
            let circle = new L.circle([coords.y, coords.x], {
                radius: radius,
                opacity: .9,
                color: color1,
                fillColor: color2,
                fillOpacity: 0.5,
            }).addTo(map).bindPopup("<b>" + type + "</b>");

            //AÑADE EL CIRCULO A CIRCLES
            Circles[id] = circle;



        }
    },

    updateCircle: (id, coords, radius, color1, color2, type) => {
        if (Circles[id]) {
            Circles[id].setLatLng([coords.y, coords.x]);
            Circles[id].setRadius(radius);
            Circles[id].setStyle({ color: color1, fillColor: color2 });
            Circles[id].bindPopup("<b>" + type + "</b>");
        }
    },

    destroyCircle: (id) => {
        if (Circles[id]) {
            mapCentral.removeLayer(Circles[id]);
            delete Circles[id];
        }
    },

    destroyAlertBlip: id => {

        central.map((alert, i) => {
            if (alert[0] == id) {
                mapCentral.removeLayer(alert[1]);
                delete central[i];
                if (centralFunctions.alerts.length == 0) {
                    $(".police .tab .central .tabla-dispatch tbody").html(`
                    <tr>
                        <td colspan="4" class="text-muted text-center no-alerts">No se han recibido avisos.</td>
                    </tr>
                    `);
                }
            }

        });
    }


}

$(document).on("click", ".police .tab .central .info-mapa .close-button", function () {
    $(".police .central .info-mapa").toggleClass("show");
});