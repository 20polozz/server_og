/*  ORIGEN · org-input: el dialogo de escribir y elegir valores, en formato
    RIEL (columna y riel a la derecha, despegados del canto, que entran juntos
    deslizandose; piel pegatina).

    Lo que ve el Lua NO ha cambiado:
      - mensaje   { action = 'openMenu', data = { header, icon, submitText,
                    inputs = { { type, name, text, default, isRequired,
                    options, changeEvent } }, keepinput } }
      - mensaje   { action = 'closeMenu' }   (lo manda el vigilante del foco)
      - callback  buttonSubmit  { data = { [name] = valor } }
      - callback  closeMenu     (sin datos)
      - callback  changeEvent   { event, value }

    El reparto al cerrar es el del riel: el Lua suelta el foco en el mismo
    callback (buttonSubmit / closeMenu) y la pagina se recoge despues, a su
    ritmo. Nunca al reves: si el aviso esperase a la animacion, el raton se
    quedaria preso esos 260 ms. */

let formInputs = {};
let changeEvents = {};

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

/*  Los textos de boton que algun recurso de fuera manda en ingles (el de los
    cromos manda «Confirm»). Lo que el jugador ve va en español. */
const BOTONES = {
    confirm: "Confirmar",
    submit: "Enviar",
    send: "Enviar",
    accept: "Aceptar",
    ok: "Aceptar",
    save: "Guardar",
    done: "Hecho",
    continue: "Continuar",
};

function textoBoton(t) {
    if (t == null || t === "") return "Aceptar";
    const k = String(t).trim().toLowerCase();
    return BOTONES[k] || t;
}

/*  Para lo que va DENTRO de un atributo (value, name): las comillas lo
    cortarian. El navegador lo devuelve tal cual al leerlo, asi que los datos
    que vuelven al Lua son los mismos. Los textos visibles van sin escapar,
    como siempre: hay recursos que mandan algo de marcado. */
function attr(v) {
    return String(v)
        .replace(/&/g, "&amp;")
        .replace(/"/g, "&quot;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
}

function esRequerido(item) {
    return item.isRequired == "true" || item.isRequired ? "required" : "";
}

/*  ── La entrada y la salida ─────────────────────────────────────────────── */
let abierto = false;
let enviando = false;
let timerCierre = null;
// Las teclas cuyo keydown ha caido AQUI con el dialogo abierto. Sin esto, el
// keyup de un Intro o un Escape pulsado en otra pantalla (la que abrio esta)
// confirmaba o cancelaba nada mas aparecer.
let armadas = {};

function mostrar() {
    const oi = document.getElementById("oi");
    clearTimeout(timerCierre);
    timerCierre = null;
    oi.classList.remove("apagado");
    // El frame siguiente, para que el navegador vea el punto de partida y
    // haya transicion en vez de un salto seco.
    void oi.offsetWidth;
    requestAnimationFrame(() => {
        if (abierto) oi.classList.add("esta-dentro");
    });
}

function recoger() {
    const oi = document.getElementById("oi");
    oi.classList.remove("esta-dentro");
    clearTimeout(timerCierre);
    // 280 > los 260 del deslizamiento.
    timerCierre = setTimeout(() => {
        timerCierre = null;
        if (abierto) return;
        oi.classList.add("apagado");
        $("#org-input-form").html("");
    }, 280);
}

const MenuActions = {
    openMenu: function (data) {
        if (data == null || data == "") {
            return null;
        }

        const yaDentro = abierto && document.getElementById("oi").classList.contains("esta-dentro");

        formInputs = {};
        changeEvents = {};
        enviando = false;
        armadas = {};

        // ── Cabecera: el icono y el titulo que manda quien abre.
        const icon = data.icon || "fa-solid fa-align-center";
        $(".oi-cab__placa").html(`<i class="${attr(icon)}"></i>`);
        $(".oi-cab__t").html(data.header != null ? data.header : "Formulario");
        // El rótulo a brocha bajo el título (08/10): el Lua puede pasar el suyo
        // (`brocha = "..."`); si no, el genérico. jQuery lo pone como atributo,
        // sin pasar por HTML.
        $(".oi-cab__t").attr("data-brocha", (typeof data.brocha === "string" && data.brocha.trim()) || "Dime algo");

        // ── El cuerpo: un bloque por entrada, en el orden en que llegan.
        const form = [];
        (data.inputs || []).forEach((item) => {
            switch (item.type) {
                case "text":
                    form.push(this.renderTextInput(item));
                    break;
                case "password":
                    form.push(this.renderPasswordInput(item));
                    break;
                case "number":
                    form.push(this.renderNumberInput(item));
                    break;
                case "radio":
                    form.push(this.renderRadioInput(item));
                    break;
                case "select":
                    form.push(this.renderSelectInput(item));
                    break;
                case "checkbox":
                    form.push(this.renderCheckboxInput(item));
                    break;
                default:
                    form.push(`<p class="label oi-nota">${item.text != null ? item.text : ""}</p>`);
            }

            if (item.changeEvent) {
                changeEvents[item.name] = item.changeEvent;
            }
        });

        $("#org-input-form").html(form.join(""));
        $("#submit span").text(textoBoton(data.submitText));
        $("#org-input-form").scrollTop(0);

        abierto = true;
        if (!yaDentro) {
            Sonido.deslizar();
            mostrar();
        }

        // El cursor en el primer campo de escribir: abrir y teclear. Con
        // keepinput no, que ahi las teclas son tambien del personaje.
        if (!data.keepinput) {
            setTimeout(() => {
                if (!abierto) return;
                const primero = document.querySelector(
                    "#org-input-form input[type='text'], #org-input-form input[type='number'], #org-input-form input[type='password']"
                );
                if (primero) {
                    try { primero.focus({ preventScroll: true }); } catch (_) { primero.focus(); }
                }
            }, 60);
        }
    },

    renderTextInput: function (item) {
        return this.renderCampo(item, "text");
    },

    renderPasswordInput: function (item) {
        return this.renderCampo(item, "password");
    },

    renderNumberInput: function (item) {
        try {
            return this.renderCampo(item, "number");
        } catch (err) {
            console.log(err);
            return "";
        }
    },

    /*  Un campo de escribir: el rotulo arriba (con el campo ya escrito, un
        texto de ayuda dentro desaparece y no se sabe que era) y el aviso
        debajo, que solo se ve si falta. */
    renderCampo: function (item, tipo) {
        const { text, name } = item;
        formInputs[name] = item.default !== undefined ? item.default : "";
        const defaultValue = item.default !== undefined ? `value="${attr(item.default)}"` : "";
        const rotulo = text != null && text !== "" ? `<span class="oi-rotulo">${text}</span>` : "";
        const paso = tipo === "number" ? 'step="any" inputmode="decimal"' : "";
        return `
            <label class="oi-campo">
                ${rotulo}
                <input type="${tipo}" class="form-control" name="${attr(name)}" ${defaultValue} ${paso} ${esRequerido(item)} spellcheck="false" />
                <span class="oi-aviso">Rellena este campo</span>
            </label>`;
    },

    renderRadioInput: function (item) {
        const { options, name, text } = item;
        formInputs[name] = options[0].value;

        let div = `<div class="form-input-group oi-grupo">`;
        if (text != null && text !== "") div += `<div class="form-group-title oi-pregunta">${text}</div>`;
        div += '<div class="input-group oi-opciones">';
        options.forEach((option, index) => {
            const marcada = item.default ? item.default == option.value : index == 0;
            div += `
                <label for="radio_${attr(name)}_${index}" class="radio-label oi-opcion${marcada ? " on" : ""}">
                    <input type="radio" id="radio_${attr(name)}_${index}" name="${attr(name)}" value="${attr(option.value)}" ${marcada ? "checked" : ""}>
                    <span class="oi-marca oi-marca--radio"></span>
                    <span class="radio-text oi-opcion__txt">${option.text}</span>
                </label>`;
        });
        div += "</div></div>";
        return div;
    },

    renderCheckboxInput: function (item) {
        const { options, name, text } = item;

        let div = `<div class="form-input-group oi-grupo">`;
        if (text != null && text !== "") div += `<div class="form-group-title oi-pregunta">${text}</div>`;
        div += '<div class="input-group-chk oi-opciones">';
        options.forEach((option, index) => {
            div += `
                <label for="chk_${attr(name)}_${index}" class="checkbox-label oi-opcion${option.checked ? " on" : ""}">
                    <input type="checkbox" id="chk_${attr(name)}_${index}" name="${attr(name)}" value="${attr(option.value)}" ${option.checked ? "checked" : ""}>
                    <span class="oi-marca oi-marca--casilla"></span>
                    <span class="checkbox-text oi-opcion__txt">${option.text}</span>
                </label>`;
            formInputs[option.value] = option.checked ? "true" : "false";
        });
        div += "</div></div>";
        return div;
    },

    renderSelectInput: function (item) {
        const { options, name, text } = item;
        formInputs[name] = options[0].value;

        let opciones = "";
        options.forEach((option) => {
            const isDefaultValue = item.default == option.value;
            opciones += `<option value="${attr(option.value)}" ${isDefaultValue ? "selected" : ""}>${option.text}</option>`;
            if (isDefaultValue) {
                formInputs[name] = option.value;
            }
        });

        const rotulo = text != null && text !== "" ? `<span class="select-title oi-rotulo">${text}</span>` : "";
        return `
            <label class="select-wrapper oi-campo">
                ${rotulo}
                <span class="select-container oi-select">
                    <select class="form-select" name="${attr(name)}" title="${attr(text != null ? text : "")}">${opciones}</select>
                </span>
            </label>`;
    },

    /*  Recoger la pantalla (sin avisar al Lua: o ya lo sabe porque viene de
        un callback, o es el quien lo pide). */
    closeMenu: function () {
        if (!abierto) return;
        abierto = false;
        Sonido.deslizar();
        formInputs = {};
        changeEvents = {};
        armadas = {};
        if (document.activeElement && document.activeElement.blur) document.activeElement.blur();
        recoger();
    },

    cancelMenu: function () {
        if (!abierto) return;
        $.post(`https://${GetParentResourceName()}/closeMenu`);
        return MenuActions.closeMenu();
    },

    postData: function (id) {
        $.post(
            `https://${GetParentResourceName()}/clickedButton`,
            JSON.stringify(parseInt(id) + 1)
        );
        return true;
    },

    hideMenu: function () {
        document.getElementById("oi").classList.remove("esta-dentro");
    },

    showMenu: function () {
        if (abierto) mostrar();
    },

    doChangeEvent: function (event, value) {
        $.post(`https://${GetParentResourceName()}/changeEvent`, JSON.stringify({
            event, value
        }));
    }
};

/*  ── Lo que pasa dentro del formulario ───────────────────────────────────── */

// Los cambios: los mismos datos y los mismos changeEvent de siempre.
$("#org-input-form").on("change", function (event) {
    const $t = $(event.target);

    if ($t.attr("type") == "radio" || $t.attr("type") == "checkbox") {
        // La fila elegida se marca con una clase: el CEF del juego (103) no
        // tiene :has(), asi que no se puede pintar desde el CSS solo.
        const nombre = $t.attr("name");
        $(this).find(`input[name="${CSS.escape(nombre)}"]`).each(function () {
            $(this).closest(".oi-opcion").toggleClass("on", this.checked);
        });
        Sonido.pulsar();
    }

    if ($t.attr("type") == "checkbox") {
        const value = $t.is(":checked") ? "true" : "false";
        formInputs[$t.attr("value")] = value;

        if (changeEvents[$t.attr("value")]) {
            MenuActions.doChangeEvent(changeEvents[$t.attr("value")], formInputs[$t.attr("value")]);
        }
    } else {
        formInputs[$t.attr("name")] = $t.val();

        if (changeEvents[$t.attr("name")]) {
            MenuActions.doChangeEvent(changeEvents[$t.attr("name")], formInputs[$t.attr("name")]);
        }
    }
});

// Al escribir en un campo que faltaba, el aviso se va.
$("#org-input-form").on("input", ".form-control", function () {
    if (this.value !== "") $(this).closest(".oi-campo").removeClass("falta");
});

/*  Confirmar. Sin la burbuja del navegador (sale en el idioma del sistema y
    con otro estilo): los obligatorios vacios se marcan aqui. */
document.getElementById("org-input-form").noValidate = true;

$("#org-input-form").on("submit", function (event) {
    if (event != null) {
        event.preventDefault();
    }
    if (!abierto || enviando) return;

    let primeroQueFalta = null;
    $(this).find(".form-control[required]").each(function () {
        const falta = String(this.value).trim() === "";
        $(this).closest(".oi-campo").toggleClass("falta", falta);
        if (falta && !primeroQueFalta) primeroQueFalta = this;
    });
    if (primeroQueFalta) {
        primeroQueFalta.focus();
        return;
    }

    // Capturar todos los valores actuales del formulario antes de enviar
    const formData = {};
    $(this).find("input, select").each(function () {
        const name = $(this).attr("name");
        const type = $(this).attr("type");
        if (name) {
            if (type === "checkbox") {
                formData[name] = $(this).is(":checked") ? "true" : "false";
            } else if (type === "radio") {
                if ($(this).is(":checked")) formData[name] = $(this).val();
            } else {
                formData[name] = $(this).val();
            }
        }
    });

    enviando = true;
    Sonido.pulsar();

    // El aviso va ya: el Lua suelta el foco en el callback. La pagina se
    // recoge a la vez, sin esperar la respuesta.
    $.post(
        `https://${GetParentResourceName()}/buttonSubmit`,
        JSON.stringify({ data: formData })
    );
    MenuActions.closeMenu();
});

$("#oi-cancelar").on("click", function () {
    MenuActions.cancelMenu();
});

/*  ── Los mensajes del Lua ────────────────────────────────────────────────── */
window.addEventListener("message", (event) => {
    if (!event.data) return;
    const data = event.data.data;
    const action = event.data.action;

    MenuActions[action] && MenuActions[action](data);
});

/*  ── El teclado: Escape cancela, Intro confirma ───────────────────────────── */
document.addEventListener("keydown", function (event) {
    if (abierto) armadas[event.key] = true;
});

document.addEventListener("keyup", function (event) {
    const tecla = event.key;
    const armada = armadas[tecla] === true;
    delete armadas[tecla];
    if (!abierto || !armada) return;

    if (tecla == "Escape") {
        MenuActions.cancelMenu();
    } else if (tecla == "Enter") {
        // En un desplegable Intro es para elegir, no para enviar.
        const t = event.target;
        if (t && (t.tagName === "SELECT" || t.tagName === "TEXTAREA")) return;
        $("#org-input-form").trigger("submit");
    }
});
