/*
 * ORIGEN: traducción al español del NUI de rf_rsm1h.
 * El Lua viene cifrado, así que la traducción se hace aquí:
 *  - RF_ES_LOCALE pisa las claves de idioma que manda el Lua (app.js y phone-bridge.js lo mezclan al abrir).
 *  - Un observador cambia en el DOM los textos que el panel escribe en inglés a mano.
 * Se carga en index, phone, lift, cam y screen. Si el autor actualiza html/, hay que volver a meterlo.
 */
(function () {
    "use strict";

    // Claves de idioma del panel (las que usa r("clave") en app.js)
    window.RF_ES_LOCALE = {
        nav_home: "Inicio", nav_rooms: "Estancias", nav_devices: "Dispositivos", nav_settings: "Ajustes",
        tab_hub: "Central", tab_support: "Soporte", tab_security: "Seguridad",
        more_options: "Más opciones", now_playing: "Sonando", temperature: "Temperatura", humidity: "Humedad",
        next_weather: "Después:", open: "Abrir", closed: "Cerrado", close: "Cerrar", lowered: "bajada",
        up: "Subir", down: "Bajar", raised: "Subida", at_bottom: "Bajada", scenes: "Escenas",
        all_blinds: "Todas las persianas de la casa", blinds: "Persianas", lights: "Luces",
        open_all: "Abrir todo", close_all: "Cerrar todo", closed_l: "cerradas", opening: "Abriendo",
        closing: "Cerrando", open_l: "Abierta", shut_l: "Cerrada", part_way: "a medias",
        all_at_stop: "Todas paradas", floors: "Plantas", half: "Media", raise_all: "Subir todas",
        lower_all: "Bajar todas", no_security: "No hay dispositivos de seguridad",
        no_security_h: "Añade cámaras, cerraduras o alarmas a esta propiedad en config.lua.",
        support_title: "Información del sistema", settings_unit: "Unidad de temperatura",
        settings_close: "Cerrar panel", connected: "Conectado", devices_count: "dispositivos",
        speakers: "altavoces", playing: "Sonando", off: "Apagado", nothing_playing: "No suena nada",
        view_camera: "Ver cámara",
        eq_note: "Se aplica a tus archivos y enlaces directos. Las fuentes marcadas como 2D suenan fuera del motor de audio.",
        volume: "Volumen", muted: "Silenciado", screen_off: "Pantalla apagada", screen_off_btn: "Apagar pantalla",
        screen_on_btn: "Encender pantalla", subtitles: "Subtítulos", pause: "Pausa", skip_ad: "Saltar anuncio",
        no_signal: "SIN SEÑAL", paste_url: "Pega un enlace", play: "Reproducir",
        screen_hint: "Enlace de YouTube, Twitch o vídeo directo. Los archivos suenan en 3D; YouTube y Twitch solo bajan con la distancia.",
        doors: "Puertas", locked_l: "cerradas", lock_all: "Cerrar todas", unlock_all: "Abrir todas",
        privacy: "Privacidad", enter_code: "Introduce tu código", wrong_code: "Código incorrecto",
        privacy_locked: "Las cámaras son privadas", privacy_locked_h: "Introduce tu código para verlas.",
        back: "Volver", too_many: "Demasiados intentos, espera", running: "En marcha", speed: "Velocidad",
        height: "Altura", all_up: "Todo arriba", all_down: "Todo abajo", radio: "Radio", room: "Estancia",
        station: "Emisora", audio: "Audio", source: "Fuente", eq: "Ecualizador", low: "Graves", mid: "Medios",
        high: "Agudos", sec_files: "Archivos subidos", sec_link: "Enlace",
        sec_files_h: "3D completo desde cada altavoz de la zona, y se aplica el ecualizador.",
        sec_link_h: "Un enlace directo de audio, igual. YouTube solo baja con la distancia.",
        enter_url: "Pega un enlace", add_url: "Añadir", your_files: "Archivos",
        url_hint: "Un enlace de YouTube, un enlace directo a un audio o una emisora.",
        checking: "Comprobando el enlace...", no_tracks: "Sin archivos", no_tracks_h: "Añade audios a html/audio.",
        media: "Multimedia", screens: "Pantallas", elevators: "Ascensores", access: "Acceder",
        awaiting_service: "Esperando servicio", change_code: "Cambiar código", checking_code: "Comprobando…",
        enter_new: "Introduce el nuevo código del panel", enter_owner: "Introduce el código del dueño",
        media_control: "Multimedia", motion: "Movimiento", motion_last: "Último", motion_off: "Apagado",
        motion_watching: "Vigilando", muted_l: "Silencio", new_code: "Código nuevo", off_l: "Apagado",
        on_l: "Encendido", owner_code: "Código del dueño", panel_code: "Código del panel",
        privacy_lock: "Bloquear ya", set: "Guardar", showcase: "Exposición", sound_l: "Sonido",
        sweep: "Barrido"
    };

    // Textos sueltos que el NUI escribe en inglés sin pasar por las claves
    var FRASES = {
        // navegación y secciones
        "home": "Inicio", "rooms": "Estancias", "devices": "Dispositivos", "settings": "Ajustes",
        "hub": "Central", "support": "Soporte", "security": "Seguridad", "cameras": "Cámaras", "cams": "Cámaras",
        "doors": "Puertas", "media": "Multimedia", "blinds": "Persianas", "elevator": "Ascensor",
        "elevators": "Ascensores", "lights": "Luces", "screens": "Pantallas", "audio": "Audio", "radio": "Radio",
        "scenes": "Escenas", "privacy": "Privacidad", "motion": "Movimiento", "passkey": "Clave",
        "media control": "Multimedia", "system information": "Información del sistema",
        "more options": "Más opciones", "temperature": "Temperatura", "temperature unit": "Unidad de temperatura",
        "humidity": "Humedad", "close panel": "Cerrar panel", "connected": "Conectado", "panel sounds": "Sonidos del panel",
        "phone": "Móvil", "lift": "Ascensor", "camera": "Cámara",
        // estados
        "open": "Abrir", "opening": "Abriendo", "closed": "Cerrada", "closing": "Cerrando", "shut": "Cerrada",
        "locked": "Cerrada", "unlocked": "Abierta", "lock": "Cerrar", "unlock": "Abrir",
        // avisos de tecla (los manda el Lua cifrado a lift.html; los que falten se añaden aquí)
        "lock door": "Cerrar puerta", "unlock door": "Abrir puerta", "open door": "Abrir puerta",
        "close door": "Cerrar puerta", "open panel": "Abrir panel", "use panel": "Usar panel",
        "wall pad": "Panel", "open gate": "Abrir portón", "close gate": "Cerrar portón",
        "call elevator": "Llamar al ascensor", "call lift": "Llamar al ascensor",
        "on": "Encendido", "off": "Apagado", "idle": "En espera", "moving": "En marcha", "running": "En marcha",
        "ready": "Listo", "online": "En línea", "connecting": "Conectando", "paused": "En pausa",
        "playing": "Sonando", "muted": "Silenciado", "sound": "Sonido", "raised": "Subida", "raising": "Subiendo",
        "lowered": "Bajada", "lowering": "Bajando", "half": "Media", "live": "EN DIRECTO", "rec": "REC",
        "no service": "Sin servicio", "awaiting service": "Esperando servicio", "no signal": "SIN SEÑAL",
        "not on screen": "NO ESTÁ EN PANTALLA", "twitch not supported": "TWITCH NO ES COMPATIBLE",
        "nothing playing": "No suena nada", "now playing": "Sonando", "no files": "Sin archivos",
        "no blinds": "Sin persianas", "no link set": "Sin enlace", "idle screen": "Pantalla en reposo",
        "all at a stop": "Todas paradas", "screen off": "Pantalla apagada", "screen on": "Encender pantalla",
        "idle · doors open": "En espera · puertas abiertas", "moving · doors closed": "En marcha · puertas cerradas",
        "cameras are private": "Las cámaras son privadas", "enter your code to view them.": "Introduce tu código para verlas.",
        "no security devices installed": "No hay dispositivos de seguridad",
        "camera feed": "Imagen de la cámara", "watching": "Vigilando", "last": "Último",
        // botones
        "open all": "Abrir todo", "close all": "Cerrar todo", "lock all": "Cerrar todas", "unlock all": "Abrir todas",
        "raise all": "Subir todas", "lower all": "Bajar todas", "all up": "Todo arriba", "all down": "Todo abajo",
        "up": "Subir", "down": "Bajar", "close": "Cerrar", "back": "Volver", "clear": "Borrar", "cancel": "Cancelar",
        "change": "Cambiar", "change code": "Cambiar código", "set": "Guardar", "add": "Añadir", "access": "Acceder",
        "next": "Siguiente", "play": "Reproducir", "pause": "Pausa", "skip ad": "Saltar anuncio",
        "subtitles": "Subtítulos", "lock now": "Bloquear ya", "view camera": "Ver cámara", "auto pan": "Barrido auto",
        "sweep": "Barrido", "use elevator": "Usar ascensor", "enter": "Intro", "esc": "Esc",
        "or click away": "o pulsa fuera", "select": "elegir", "go": "ir",
        // códigos
        "enter your code": "Introduce tu código", "enter your 4-digit code": "Introduce tu código de 4 cifras",
        "enter the new panel code": "Introduce el nuevo código del panel",
        "enter the owner code": "Introduce el código del dueño", "wrong code": "Código incorrecto",
        "too many tries, wait": "Demasiados intentos, espera", "checking…": "Comprobando…",
        "pin code": "Código PIN", "panel code": "Código del panel", "owner code": "Código del dueño",
        "new code": "Código nuevo", "•••• · 4 digits": "•••• · 4 cifras",
        // audio y pantallas
        "volume": "Volumen", "station": "Emisora", "source": "Fuente", "room": "Estancia", "eq": "Ecualizador",
        "low": "Graves", "mid": "Medios", "high": "Agudos", "speed": "Velocidad", "height": "Altura",
        "floors": "Plantas", "files": "Archivos", "your files": "Archivos", "uploaded files": "Archivos subidos",
        "link": "Enlace", "enter url": "Pega un enlace", "paste a link": "Pega un enlace",
        "checking that link...": "Comprobando el enlace...", "showcase": "Exposición",
        "every blind in the house": "Todas las persianas de la casa", "next:": "Después:",
        "a youtube link, a direct link to an audio file, or a stream.": "Un enlace de YouTube, un enlace directo a un audio o una emisora.",
        "full 3d from every speaker in the zone, and the eq applies.": "3D completo desde cada altavoz de la zona, y se aplica el ecualizador.",
        "a direct audio link gets the same. youtube plays distance-only.": "Un enlace directo de audio, igual. YouTube solo baja con la distancia.",
        "applies to your files and direct links. sources marked 2d play outside the audio engine.": "Se aplica a tus archivos y enlaces directos. Las fuentes marcadas como 2D suenan fuera del motor de audio.",
        "hls playlists are not supported. use a direct file or stream.": "Las listas HLS no son compatibles. Usa un archivo directo o una emisora.",
        "could not find a file id in that drive link.": "No se encuentra el archivo en ese enlace de Drive.",
        "that has no audio file extension. it will still be tried, but it needs to serve audio directly.": "No tiene extensión de audio. Se intentará igualmente, pero tiene que servir el audio directamente.",
        "the youtube player could not load. is youtube.com reachable from this client?": "El reproductor de YouTube no carga. ¿Llega este cliente a youtube.com?",
        // tiempo
        "clouds": "Nublado", "rain": "Lluvia", "thunder": "Tormenta", "night": "Noche", "clear sky": "Despejado",
        "mon": "Lun", "tue": "Mar", "wed": "Mié", "thu": "Jue", "fri": "Vie", "sat": "Sáb", "sun": "Dom",
        "monday": "Lunes", "tuesday": "Martes", "wednesday": "Miércoles", "thursday": "Jueves",
        "friday": "Viernes", "saturday": "Sábado", "sunday": "Domingo",
        // estancias y dispositivos del mapeado
        "bathroom": "Baño", "bedroom": "Dormitorio", "north bedroom": "Dormitorio norte",
        "south bedroom": "Dormitorio sur", "east bedroom": "Dormitorio este", "west bedroom": "Dormitorio oeste",
        "living room": "Salón", "lounge": "Sala de estar", "office": "Despacho", "studio": "Estudio",
        "recording studio": "Estudio de grabación", "recording booth": "Cabina de grabación",
        "theater room": "Sala de cine", "wine cellar": "Bodega", "warm room": "Sala cálida", "club": "Club",
        "terrace": "Terraza", "patio": "Patio", "north patio": "Patio norte", "south patio": "Patio sur",
        "east patio": "Patio este", "west patio": "Patio oeste", "exterior": "Exterior",
        "entrance": "Entrada", "main entrance": "Entrada principal", "north entrance": "Entrada norte",
        "west entrance": "Entrada oeste", "garage entrance": "Entrada del garaje", "main gate": "Portón principal",
        "hidden door": "Puerta oculta", "garage": "Garaje", "garages": "Garajes", "guest garage": "Garaje de invitados",
        "boat garage": "Garaje del barco", "boat house": "Casa del barco", "west dock": "Muelle oeste",
        "vehicle garage 1": "Garaje de vehículos 1", "vehicle garage 2": "Garaje de vehículos 2",
        "vehicle elevator": "Ascensor de vehículos", "vehicle lift": "Ascensor de vehículos",
        "passenger lift": "Ascensor", "vehicle display": "Expositor de vehículos",
        "interior display": "Expositor interior", "terrace display": "Expositor de la terraza",
        "light display": "Espectáculo de luces", "interior ramp": "Rampa interior",
        "terrace ramps": "Rampas de la terraza", "water feature": "Fuente", "dock screen": "Pantalla del muelle",
        "main floor": "Planta principal", "main hub": "Central",
        "north east view": "Vista noreste", "north west view": "Vista noroeste",
        "south east view": "Vista sureste", "south west view": "Vista suroeste"
    };

    // Textos con números o nombres dentro
    var PATRONES = [
        [/^Floor (\d+)$/i, "Planta $1"],
        [/^Door (\d+)$/i, "Puerta $1"],
        [/^Garage (\d+)$/i, "Garaje $1"],
        [/^CAM (\d+)$/, "CÁM $1"],
        [/^(\d+) speakers?$/i, "$1 altavoces"],
        [/^(\d+) devices?$/i, "$1 dispositivos"],
        [/^(\d+) live$/i, "$1 en directo"],
        [/^tap to view$/i, "toca para ver"],
        [/^(\d+) part way$/i, "$1 a medias"],
        [/^(\d+) \/ (\d+) closed$/i, "$1 / $2 cerradas"],
        [/^(.+) idle$/i, function (m, a) { return (traducir(a) || a) + " en espera"; }],
        [/^(.+) moving$/i, function (m, a) { return (traducir(a) || a) + " en marcha"; }],
        [/^Going to (.+)$/i, function (m, a) { return "Subiendo a " + (traducir(a) || a); }],
        [/^Looks (N|S|E|W|NE|NW|SE|SW|NNE|NNW|SSE|SSW|ENE|ESE|WNW|WSW)$/, function (m, a) {
            return "Mira al " + a.replace(/W/g, "O");
        }]
    ];

    function mayusculas(s) { return s === s.toUpperCase() && s !== s.toLowerCase(); }

    function traducirTrozo(t) {
        var d = FRASES[t.toLowerCase()];
        if (d) return mayusculas(t) && t.length > 1 ? d.toUpperCase() : d;
        for (var i = 0; i < PATRONES.length; i++) {
            if (PATRONES[i][0].test(t)) return t.replace(PATRONES[i][0], PATRONES[i][1]);
        }
        return null;
    }

    // Traduce un texto entero o por trozos separados por « · »
    function traducir(texto) {
        var t = texto.trim();
        if (!t || !/[A-Za-z]/.test(t)) return null;
        var entero = traducirTrozo(t);
        if (entero != null) return entero;
        if (t.indexOf(" · ") < 0 && t.indexOf(" · ") < 0) return null;
        var trozos = t.split(" · "), cambiado = false;
        for (var i = 0; i < trozos.length; i++) {
            // dentro de «Sábado · Clear · 27°C» es el tiempo, no el botón de borrar
            var x = /^clear$/i.test(trozos[i].trim()) ? "Despejado" : traducirTrozo(trozos[i].trim());
            if (x != null) { trozos[i] = x; cambiado = true; }
        }
        return cambiado ? trozos.join(" · ") : null;
    }
    window.RF_ES = traducir;

    var SALTAR = { SCRIPT: 1, STYLE: 1, TEXTAREA: 1, INPUT: 1, NOSCRIPT: 1 };

    function nodoTexto(n) {
        var p = n.parentNode;
        if (!p || SALTAR[p.nodeName]) return;
        var v = n.nodeValue, x = traducir(v);
        if (x == null || x === v.trim()) return;
        var ini = v.match(/^\s*/)[0], fin = v.match(/\s*$/)[0];
        n.nodeValue = ini + x + fin;
    }

    var ATRIBUTOS = ["placeholder", "title", "aria-label"];

    function elemento(el) {
        for (var i = 0; i < ATRIBUTOS.length; i++) {
            var a = el.getAttribute && el.getAttribute(ATRIBUTOS[i]);
            if (a) { var x = traducir(a); if (x != null && x !== a) el.setAttribute(ATRIBUTOS[i], x); }
        }
    }

    function recorrer(raiz) {
        if (raiz.nodeType === 3) return nodoTexto(raiz);
        if (raiz.nodeType !== 1 || SALTAR[raiz.nodeName] || raiz.id === "yt-host") return;
        elemento(raiz);
        var w = document.createTreeWalker(raiz, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT, null);
        var n;
        while ((n = w.nextNode())) {
            if (n.nodeType === 3) nodoTexto(n); else elemento(n);
        }
    }

    function arrancar() {
        document.documentElement.lang = "es";
        recorrer(document.body || document.documentElement);
        new MutationObserver(function (lista) {
            for (var i = 0; i < lista.length; i++) {
                var m = lista[i];
                if (m.type === "characterData") nodoTexto(m.target);
                else if (m.type === "attributes") elemento(m.target);
                else for (var j = 0; j < m.addedNodes.length; j++) recorrer(m.addedNodes[j]);
            }
        }).observe(document.documentElement, {
            childList: true, subtree: true, characterData: true,
            attributes: true, attributeFilter: ATRIBUTOS
        });
    }

    if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", arrancar);
    else arrancar();
})();
