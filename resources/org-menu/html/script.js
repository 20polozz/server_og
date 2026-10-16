/*  ORIGEN · org-menu: el menu de opciones, en formato RIEL (columna y riel a
    la derecha, despegados del canto, que entran juntos deslizandose; piel
    pegatina).

    Lo que ve el Lua NO ha cambiado:
      - mensajes  openMenu { data = { {header, txt|text, icon, isMenuHeader,
                  disabled, hidden, params}, ... } }, updateMenu { option, key,
                  value }, closeMenu, hideMenu, showMenu
      - callbacks clickedButton (el indice de la opcion, desde 1) y closeMenu
      - cada opcion es un .button con id = su indice desde 0, como siempre.

    Se maneja SIN cursor: el Lua da el foco sin raton y deja andar
    (SetNuiFocus(true, false) + KeepInput). La rueda mueve la opcion
    señalada, el clic (caiga donde caiga) o Intro la eligen, y el clic
    derecho o Escape cierran. */

let buttonParams = [];
let selectedButtonIndex = 0;

/*  Los dos sonidos del riel, los del inventario. Sin audio la pantalla
    funciona igual, y el navegador rechaza el play() si aun no ha habido
    interaccion: es normal, no un fallo. */
const Sonido = (function () {
    function sonador(url, volumen) {
        let audio = null;
        return function () {
            try {
                if (!audio) { audio = new Audio(url); audio.volume = volumen; }
                audio.currentTime = 0;
                const p = audio.play();
                if (p && typeof p.catch === "function") p.catch(() => { });
            } catch (_) { }
        };
    }
    return {
        deslizar: sonador("./sonidos/slide.wav", 0.35),
        pulsar: sonador("./sonidos/click.wav", 0.3),
    };
})();

/*  ── La entrada y la salida ───────────────────────────────────────────────
    `abierto`: hay un menu cargado (aunque este escondido con hideMenu).
    `visible`: esta en pantalla. */
let abierto = false;
let visible = false;
let timerCierre = null;
let cierrePendiente = null;
// Las teclas cuyo keydown ha caido AQUI con el menu en pantalla. Sin esto, el
// keyup de un Intro o un Escape pulsado en otra pantalla (la que abrio esta)
// elegia o cerraba nada mas aparecer.
let armadas = {};

function mostrar() {
    const om = document.getElementById("om");
    clearTimeout(timerCierre);
    timerCierre = null;
    if (visible && om.classList.contains("esta-dentro")) return false;
    visible = true;
    om.classList.remove("apagado");
    // El frame siguiente, para que haya transicion en vez de un salto seco.
    void om.offsetWidth;
    requestAnimationFrame(() => {
        if (visible) om.classList.add("esta-dentro");
    });
    return true;
}

function recoger(limpiar) {
    const om = document.getElementById("om");
    visible = false;
    armadas = {};
    om.classList.remove("esta-dentro");
    clearTimeout(timerCierre);
    // 280 > los 260 del deslizamiento.
    timerCierre = setTimeout(() => {
        timerCierre = null;
        if (visible) return;
        om.classList.add("apagado");
        if (limpiar && !abierto) {
            $("#buttons").html("<div class='buttons-list'></div>");
            $("#om-cab").html("");
            buttonParams = [];
            selectedButtonIndex = 0;
        }
    }, 280);
}

/*  La señalada, otra vez donde toca (tras pintar, o tras esconder/mostrar una
    opcion con updateMenu). */
function senalar(desplazar) {
    const $activas = $(".button.active");
    $(".button.selected").removeClass("selected");
    if ($activas.length === 0) return;
    if (selectedButtonIndex > $activas.length - 1) selectedButtonIndex = $activas.length - 1;
    if (selectedButtonIndex < 0) selectedButtonIndex = 0;
    const el = $activas.eq(selectedButtonIndex).addClass("selected")[0];
    if (desplazar && el) {
        try { el.scrollIntoView({ block: "nearest" }); } catch (_) { el.scrollIntoView(false); }
    }
}

/*  El rótulo a brocha bajo el título (08/10): el Lua puede pasar su frase en
    la cabecera (`brocha = "..."`); si no, va la genérica. Se escapa porque
    acaba dentro de un atributo. */
const BROCHA_GENERICA = "Tú eliges";
function brochaDe(item) {
    const f = (item && typeof item.brocha === "string" && item.brocha.trim()) || BROCHA_GENERICA;
    return f.replace(/&/g, "&amp;").replace(/"/g, "&quot;").replace(/</g, "&lt;");
}

/*  La cabecera: la opcion isMenuHeader, o una generica si no la hay. */
function pintarCabecera(item, index) {
    if (!item) {
        $("#om-cab").html(`
            <div class="title om-cab__in">
                <span class="om-cab__placa"><i class="fa-solid fa-list-ul"></i></span>
                <div class="text-content">
                    <span class="om-cab__k">Menú</span>
                    <span class="title-text" data-brocha="${brochaDe(null)}">Opciones</span>
                </div>
            </div>`);
        return;
    }
    const message = item.txt || item.text;
    const icon = item.icon || "fa-solid fa-list-ul";
    $("#om-cab").html(`
        <div class="title om-cab__in" id="${index}">
            <span class="om-cab__placa icon"><i class="${icon}"></i></span>
            <div class="text-content">
                <span class="om-cab__k">Menú</span>
                <span class="title-text" data-brocha="${brochaDe(item)}">${item.header != null ? item.header : ""}</span>
                ${message ? `<div class="subtitle">${message}</div>` : ""}
            </div>
        </div>`);
}

const MenuActions = {
    openMenu: function (data) {
        data = data.data || [];
        $("#buttons").html("<div class='buttons-list'></div>");
        buttonParams = [];

        let html = "";
        let cabecera = null;

        data.forEach((item, index) => {
            if (!item.hidden) {
                let header = item.header;
                let message = item.txt || item.text;
                let isMenuHeader = item.isMenuHeader;
                let isDisabled = item.disabled;
                // Sin icono, una flecha: si no, la chapa negra sale vacia.
                let icon = item.icon || "fa-solid fa-angle-right";
                if (!isMenuHeader) {
                    html += MenuActions.getButtonRender(header, message, index, isMenuHeader, isDisabled, icon);
                } else if (!cabecera) {
                    // La primera cabecera, arriba en la columna.
                    cabecera = { item, index };
                } else {
                    // Las siguientes (raras), como rotulo de grupo en su sitio.
                    html += MenuActions.getButtonRender(header, message, index, isMenuHeader, isDisabled, icon);
                }
                if (item.params) buttonParams[index] = item.params;
            }
        });

        pintarCabecera(cabecera && cabecera.item, cabecera && cabecera.index);
        $("#buttons .buttons-list").html(html);

        clearTimeout(cierrePendiente);
        cierrePendiente = null;
        abierto = true;
        const entra = mostrar();
        if (entra) {
            Sonido.deslizar();
            $("#buttons").scrollTop(0);
        }
        senalar(true);
    },

    updateMenu: function (data) {
        const $opt = $(`#${data.option - 1}`);

        switch (data.key) {
            case "header":
                $opt.find(".header, .title-text").html(data.value);
                break;
            case "txt": {
                const $txt = $opt.find(".text, .subtitle");
                if ($txt.length) {
                    $txt.html(data.value);
                } else if (data.value) {
                    if ($opt.hasClass("om-cab__in")) $opt.find(".text-content").append(`<div class="subtitle">${data.value}</div>`);
                    else $opt.find(".column").append(`<div class="text">${data.value}</div>`);
                }
                break;
            }
            case "icon":
                $opt.find(".icon").html(`<i class="${data.value}"></i>`);
                break;
            case "disabled":
                if (data.value) {
                    $opt.addClass("disabled").removeClass("active");
                } else {
                    $opt.removeClass("disabled").addClass("active");
                }
                senalar(false);
                break;
            case "hidden":
                if (data.value) {
                    $opt.removeClass("active");
                } else {
                    $opt.addClass("active");
                }
                senalar(false);
                break;
            default:
                break;
        }
    },

    /*  Recoger el menu (el Lua ya lo sabe: o lo pide el, o viene del callback
        closeMenu). Sin menu cargado no hace nada: hay recursos que llaman a
        closeMenu por si acaso, y sonaba el deslizar sin nada en pantalla. */
    closeMenu: function () {
        if (!abierto) return;
        abierto = false;
        /*  Un pelo de espera antes de recoger: al elegir una opcion el Lua
            cierra y, casi siempre en el mismo tick, abre el submenu. Asi ese
            salto se ve como un cambio de lista y no como salir y volver a
            entrar. 40 ms no se notan en un cierre de verdad. */
        clearTimeout(cierrePendiente);
        cierrePendiente = setTimeout(() => {
            cierrePendiente = null;
            if (abierto) return;
            if (visible) Sonido.deslizar();
            recoger(true);
        }, 40);
    },

    cancelMenu: function () {
        if (!abierto || !visible) return;
        $.post(`https://${GetParentResourceName()}/closeMenu`);
        selectedButtonIndex = 0;
        return MenuActions.closeMenu();
    },

    postData: function (id) {
        $.post(
            `https://${GetParentResourceName()}/clickedButton`,
            JSON.stringify(parseInt(id) + 1)
        );
        return true;
    },

    getButtonRender: function (header, message = null, id, isMenuHeader, isDisabled, icon) {
        if (isMenuHeader) {
            return `
                <div class="title om-grupo ${isDisabled ? "disabled" : "active"}" id="${id}">
                    <span class="title-text">${header != null ? header : ""}</span>
                    ${message ? `<div class="subtitle">${message}</div>` : ""}
                </div>`;
        }
        return `
            <div class="button ${isDisabled ? "disabled" : "active"}" id="${id}">
                <div class="icon"><i class="${icon}"></i></div>
                <div class="column">
                    <div class="header">${header != null ? header : ""}</div>
                    ${message ? `<div class="text">${message}</div>` : ""}
                </div>
            </div>`;
    },

    hideMenu: function () {
        if (!visible) return;
        recoger(false);
    },

    showMenu: function () {
        if (!abierto) return;
        if (mostrar()) Sonido.deslizar();
        senalar(true);
    },
};

window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data) return;
    const action = data.action;

    MenuActions[action] && MenuActions[action](data);
});

/*  ── Elegir ──────────────────────────────────────────────────────────────── */
function elegirSenalada() {
    const target = $(".button.selected");
    if (target.length != 0 && !target.hasClass("title") && !target.hasClass("disabled")) {
        Sonido.pulsar();
        MenuActions.postData(target.attr("id"));
    }
}

/*  ── El teclado: Escape cierra, Intro elige ────────────────────────────── */
document.addEventListener("keydown", function (event) {
    if (abierto && visible) armadas[event.key] = true;
});

document.addEventListener("keyup", function (event) {
    const tecla = event.key;
    const armada = armadas[tecla] === true;
    delete armadas[tecla];
    if (!abierto || !visible || !armada) return;

    if (tecla == "Escape") {
        MenuActions.cancelMenu();
    } else if (tecla == "Enter") {
        elegirSenalada();
    }
});

/*  ── La rueda mueve la señalada ────────────────────────────────────────────
    Sin sonido: se repite muy rapido y seria un zumbido. */
$(document).on("wheel", function (e) {
    if (!abierto || !visible) return;
    const total = $(".button.active").length;
    if (e.originalEvent.deltaY < 0) {
        if (selectedButtonIndex > 0) {
            selectedButtonIndex--;
            senalar(true);
        }
    } else if (e.originalEvent.deltaY > 0) {
        if (selectedButtonIndex < total - 1) {
            selectedButtonIndex++;
            senalar(true);
        }
    }
});

/*  El clic, caiga donde caiga, elige la señalada (no hay cursor a la vista).
    El del silencio del riel no: ese es suyo. */
$(document).on("click", function (e) {
    if ($(e.target).closest(".js-silencio").length) return;
    if (!abierto || !visible) return;
    elegirSenalada();
});

document.addEventListener("mousedown", function (event) {
    if (event.button === 2) {
        MenuActions.cancelMenu();
    }
});
