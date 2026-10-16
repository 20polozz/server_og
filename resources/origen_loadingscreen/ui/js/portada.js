/*  Pantalla de carga · portada ORIGEN NETWORK (16/09)

    Tres cosas:
      1. Recorta el nombre letra a letra y le da a cada una su inclinacion y
         su altura, para que el rotulo no parezca una fuente puesta y ya.
      2. Escucha lo que le cuenta FiveM mientras carga: el porcentaje
         (loadProgress) y en que paso va (initFunctionInvoking y compañia).
      3. Arranca la musica: la pone origen_loadingasset en un marco oculto.
         Pausarla con ESPACIO esta comentado a proposito.
*/
document.addEventListener('DOMContentLoaded', function () {
    // ── 1. El rotulo ────────────────────────────────────────────────────
    var marca = document.querySelector('.marca');
    if (marca) {
        var texto = marca.dataset.texto || 'ORIGEN NETWORK';
        /* Los desvios de cada letra. No son al azar en cada carga: al azar,
           una letra podia salir torcida de mas y el rotulo quedaba roto. Van
           escritos, como los del ejemplo. */
        var giros = [-1.6, 1.1, -0.7, 1.5, -1.2, 0.8, 0, -1.1, 1.4, -0.6, 1.2, -1.5, 0.9, -0.8];
        var altos = [2, -3, 1, -2, 3, -1, 0, -2, 2, -3, 1, 2, -2, 1];
        var escalas = [1.02, 0.99, 1.01, 1.03, 0.98, 1.02, 1, 1.01, 0.99, 1.03, 1.0, 1.02, 0.98, 1.01];

        marca.textContent = '';
        texto.split('').forEach(function (letra, i) {
            if (letra === ' ') {
                var aire = document.createElement('i');
                aire.className = 'aire';
                marca.appendChild(aire);
                return;
            }
            var s = document.createElement('span');
            s.textContent = letra;
            s.style.transform = 'rotate(' + (giros[i % giros.length]) + 'deg) translateY(' +
                (altos[i % altos.length]) + 'px) scaleY(' + (escalas[i % escalas.length]) + ')';
            marca.appendChild(s);
        });
    }

    // ── 2. Lo que cuenta FiveM ──────────────────────────────────────────
    var relleno = document.querySelector('.barra__fill');
    var paso = document.querySelector('.paso');
    var visto = 0;

    function progreso(p) {
        if (!relleno) return;
        // Nunca hacia atras: FiveM repite fracciones mas bajas entre fases.
        visto = Math.max(visto, Math.max(0, Math.min(100, p)));
        relleno.style.width = visto + '%';
    }

    function decir(t) {
        if (paso && t) paso.textContent = t;
    }

    var manos = {
        loadProgress: function (d) { progreso((d.loadFraction || 0) * 100); },
        startInitFunctionOrder: function () { decir('Preparando el juego'); },
        initFunctionInvoking: function (d) {
            var nombres = {
                INIT_CORE: 'Arrancando el juego',
                INIT_BEFORE_MAP_LOADED: 'Cargando el mapa',
                INIT_AFTER_MAP_LOADED: 'Colocando el mapa',
                INIT_SESSION: 'Entrando en la ciudad',
            };
            decir(nombres[d.type] || 'Cargando');
        },
        startDataFileEntries: function () { decir('Cargando los recursos de ORIGEN'); },
        performMappedDataFileEntry: function () { decir('Cargando los recursos de ORIGEN'); },
        onLogLine: function (d) {
            // Las lineas de registro son largas y tecnicas: solo la primera parte.
            if (d && typeof d.message === 'string') decir(d.message.slice(0, 90));
        },
        onDataFileEntry: function () { decir('Cargando los recursos de ORIGEN'); },
    };

    window.addEventListener('message', function (e) {
        var d = e.data || {};
        var f = manos[d.eventName];
        if (f) f(d);
    });

    if (!parent.document.getElementById('music-frame')) {
        var marco = parent.document.createElement('iframe');
        marco.id = 'music-frame';
        marco.src = window.location.href.replace('index', 'music');
        marco.style.display = 'none';
        parent.document.body.appendChild(marco);
    }

    var sonando = true;
    var pressedKeys = {};
    var comboActive = false;

    function alternarMusicaIntro() {
        try {
            var asset = window.parent.document.getElementsByName('origen_loadingasset')[0];
            if (asset && asset.contentWindow) {
                asset.contentWindow.postMessage({ action: 'toggleMusic' }, '*');
            }
        } catch (err) {}

        try {
            var musical = window.parent.document.getElementById('music-frame');
            if (musical && musical.contentWindow) {
                musical.contentWindow.postMessage({ type: 'toggleMusic' }, '*');
            }
        } catch (err) {}

        sonando = !sonando;
        var accion = document.getElementById('music-action');
        if (accion) accion.textContent = sonando ? 'pausar' : 'reproducir';
    }

    window.addEventListener('keydown', function (e) {
        var key = e.key ? e.key.toLowerCase() : '';
        var code = e.code || '';
        if (code) pressedKeys[code] = true;
        if (key) pressedKeys[key] = true;

        var isQ = pressedKeys['KeyQ'] || pressedKeys['q'];
        var isR = pressedKeys['KeyR'] || pressedKeys['r'];

        if (isQ && isR) {
            if (!comboActive) {
                comboActive = true;
                alternarMusicaIntro();
            }
        }
    });

    window.addEventListener('keyup', function (e) {
        var key = e.key ? e.key.toLowerCase() : '';
        var code = e.code || '';
        if (code) delete pressedKeys[code];
        if (key) delete pressedKeys[key];

        var isQ = pressedKeys['KeyQ'] || pressedKeys['q'];
        var isR = pressedKeys['KeyR'] || pressedKeys['r'];
        if (!isQ || !isR) {
            comboActive = false;
        }
    });

    window.addEventListener('blur', function () {
        pressedKeys = {};
        comboActive = false;
    });
});
