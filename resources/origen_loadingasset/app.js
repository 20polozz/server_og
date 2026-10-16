$(document).ready(function () {
    var musica = document.getElementById("musica");
    musica.loop = true;   // por si el atributo del HTML se pierde en una copia
    musica.volume = 0.5;

    /* Antes de sonar se pregunta al cliente si ya estamos jugando (client.lua):
       si esta página se recarga a mitad de partida, la música se quedaba en
       bucle para siempre. En la pantalla de carga no hay Lua que conteste, la
       petición falla o tarda y la música suena como siempre. */
    var decidido = false;
    function sonar() {
        if (decidido) return;
        decidido = true;
        musica.play();
    }
    setTimeout(sonar, 1500);
    try {
        fetch("https://" + GetParentResourceName() + "/enPartida", { method: "POST", body: "{}" })
            .then(function (r) { return r.json(); })
            .then(function (d) {
                if (decidido) {
                    if (d && d.jugando) { musica.pause(); musica.currentTime = 0; }
                    return;
                }
                if (d && d.jugando) { decidido = true; } else { sonar(); }
            })
            .catch(sonar);
    } catch (e) {
        sonar();
    }
});

    function toggleMusicSilencio() {
        var musica = document.getElementById("musica");
        if (!musica) return;
        if (musica.paused || musica.muted || musica.volume === 0) {
            musica.muted = false;
            if (musica.volume === 0) {
                musica.volume = parseFloat(localStorage.getItem("ori_vol")) || 0.5;
            }
            musica.play().catch(function () {});
        } else {
            musica.pause();
        }
    }

    /* ── Atajo de teclado: Q + R para silenciar / alternar la musica ──── */
    var pressedKeys = {};
    var comboActive = false;

    window.addEventListener("keydown", function (e) {
        var key = e.key ? e.key.toLowerCase() : "";
        var code = e.code || "";
        if (code) pressedKeys[code] = true;
        if (key) pressedKeys[key] = true;

        var isQ = pressedKeys["KeyQ"] || pressedKeys["q"];
        var isR = pressedKeys["KeyR"] || pressedKeys["r"];

        if (isQ && isR) {
            if (!comboActive) {
                comboActive = true;
                toggleMusicSilencio();
            }
        }
    });

    window.addEventListener("keyup", function (e) {
        var key = e.key ? e.key.toLowerCase() : "";
        var code = e.code || "";
        if (code) delete pressedKeys[code];
        if (key) delete pressedKeys[key];

        var isQ = pressedKeys["KeyQ"] || pressedKeys["q"];
        var isR = pressedKeys["KeyR"] || pressedKeys["r"];
        if (!isQ || !isR) {
            comboActive = false;
        }
    });

    window.addEventListener("blur", function () {
        pressedKeys = {};
        comboActive = false;
    });

    window.addEventListener("message", function (event) {
        if (event.data.action == "stopMusic") {
        var musica = document.getElementById("musica");
        $(musica).animate(
            { volume: 0 },
            3000,
            function () {
                /* Antes esto solo bajaba el volumen a 0. Con el bucle puesto la
                   pista seguiria dando vueltas en silencio para siempre, asi que
                   al acabar el fundido se para de verdad. */
                musica.volume = 0;
                musica.pause();
                musica.currentTime = 0;
            }
        );
    } else if (event.data.action == "changeVolume") {
        var musica = document.getElementById("musica");
        var vol = event.data.volume;
        musica.volume = vol;
    } else if (event.data.action == "normalizaMusicVolume") {
        var volume = localStorage.getItem("ori_vol") || 0.2;
        var musica = document.getElementById("musica");
        musica.volume = volume;
    } else if (event.data.action == "toggleMusic" || event.data.action == "muteMusic") {
        toggleMusicSilencio();
    }
});