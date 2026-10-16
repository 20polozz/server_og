/*
 * ORIGEN: lo que el riel necesita y el panel del autor no trae.
 *  - Entrar y salir deslizándose: app.js llama a RF_ENTRAR al abrir y a RF_SALIR al
 *    cerrar (el aviso "close" al Lua sale al instante, así el foco se suelta ya).
 */
(function () {
    "use strict";

    // En el juego la página se sirve desde https://cfx-nui-<recurso>/ (también los iframes,
    // que no tienen GetParentResourceName)
    var enJuego = /^cfx-nui-/.test(location.hostname);
    var recurso = enJuego ? location.hostname.replace(/^cfx-nui-/, "") : "rf_rsm1h";
    window.RF_EN_JUEGO = enJuego;

    // LA MARCA (04/10): «origen» o «nacion» (setr origen:marca). Estas páginas no
    // llevan el trozo «ORIGEN · marca» del kit (repintaría el rosa a naranja y
    // en Nación el panel tiene que quedarse como está): aquí solo se apunta en
    // <html data-marca>, que es de lo que cuelga origen-pegatina.css (solo Origen).
    // Contesta @origen_map/shared/tema.lua. Con reintentos: la página puede nacer
    // antes de que el Lua haya puesto el callback.
    function ponerMarca(m) {
        if (typeof m === "string" && /^[\w-]+$/.test(m)) document.documentElement.dataset.marca = m;
    }
    if (!document.documentElement.dataset.marca) ponerMarca("origen");
    window.addEventListener("message", function (e) {
        var d = e.data || {};
        if (d.accion === "origen:marca") ponerMarca(d.marca);
    });
    if (enJuego) {
        var intentos = 0;
        var preguntarMarca = function () {
            fetch("https://" + recurso + "/origen:marca:dame", { method: "POST", body: "{}" })
                .then(function (r) { return r.json(); })
                .then(function (r) { if (r && r.marca) ponerMarca(r.marca); else throw new Error("sin marca"); })
                .catch(function () { if (++intentos < 6) setTimeout(preguntarMarca, 1500); });
        };
        try { preguntarMarca(); } catch (e) {}
    }
    // Las páginas en iframe copian también la de la página principal
    try {
        if (window.parent !== window && window.parent.document) {
            var madreM = window.parent.document.documentElement;
            var copiarM = function () { ponerMarca(madreM.dataset.marca); };
            copiarM();
            new MutationObserver(copiarM).observe(madreM, { attributes: true, attributeFilter: ["data-marca"] });
        }
    } catch (e) {}
    // Para verlo en el navegador: ?marca=nacion
    ponerMarca(new URLSearchParams(location.search).get("marca"));

    var salida = null;

    window.RF_ENTRAR = function (raiz) {
        clearTimeout(salida);
        raiz.classList.remove("dentro");
        // En el frame siguiente, para que haya transición desde fuera y no un salto
        requestAnimationFrame(function () {
            requestAnimationFrame(function () { raiz.classList.add("dentro"); });
        });
    };

    window.RF_SALIR = function (raiz) {
        clearTimeout(salida);
        raiz.classList.remove("dentro");
        salida = setTimeout(function () { raiz.classList.add("hidden"); }, 280);
    };
})();

// El aviso de tecla del ascensor/puertas (lift.html) sale por origen_notify:
// se esconde el del autor y se reenvía al Lua (client/origen_aviso.lua).
(function () {
    if (!document.getElementById || !/lift\.html$/.test(location.pathname)) return;
    var recurso = /^cfx-nui-/.test(location.hostname) ? location.hostname.replace(/^cfx-nui-/, "") : "rf_rsm1h";
    function avisar(d) {
        try {
            fetch("https://" + recurso + "/origenAviso", { method: "POST", body: JSON.stringify(d) }).catch(function () {});
        } catch (e) {}
    }
    window.addEventListener("message", function (e) {
        var o = e.data || {};
        if (typeof o.action !== "string" || o.action.indexOf("lift:") !== 0) return;
        var a = o.action.slice(5);
        if (a === "showHint") {
            var app = document.getElementById("app");
            if (app && app.classList.contains("open")) return;   // el autor tampoco lo enseña con el panel abierto
            var t = o.text || "Use Elevator";
            avisar({ mostrar: true, tecla: String(o.key || "E"), texto: (window.RF_ES && window.RF_ES(t)) || t });
        } else if (a === "hideHint" || a === "open") {
            avisar({ mostrar: false });
        }
    });
})();

// /rsmh abre el panel lateral en vez del «móvil» del autor. El Lua (cifrado) le
// manda al móvil lo mismo que al panel, con «phone:» delante; aquí se intercepta
// antes que app.js y se le pasa al panel sin el prefijo. Los dos llaman al Lua
// con los mismos callbacks (close, tryCode, setDevice…), así que no hay más que hacer.
// Para volver al móvil del autor: RF_MOVIL_COMO_PANEL = false.
(function () {
    // Solo por el nombre de la página: en FiveM index.html ya va dentro de un marco
    // (y con frameElement accesible), así que mirar el marco no distingue nada
    if (!/(^\/$|index\.html$)/.test(location.pathname)) return;
    window.RF_MOVIL_COMO_PANEL = true;
    var PANEL_ENTIENDE = {
        open: 1, close: 1, device: 1, deviceValue: 1, doors: 1, codeResult: 1, codeChanged: 1,
        privacyLapsed: 1, camMotion: 1, lift: 1, radio: 1, env: 1
    };
    function pasar(datos) {
        window.dispatchEvent(new MessageEvent("message", { data: datos }));
    }
    window.addEventListener("message", function (e) {
        var o = e.data || {};
        if (!window.RF_MOVIL_COMO_PANEL || typeof o.action !== "string" || o.action.indexOf("phone:") !== 0) return;
        e.stopImmediatePropagation();   // que app.js no enseñe el móvil
        var a = o.action.slice(6);
        if (a === "devices") {
            // El móvil recibe la lista entera; el panel, uno a uno
            (o.devices || []).forEach(function (d) {
                pasar({ action: "device", id: d.id, from: d.value || 0, to: d.value || 0, elapsed: 0 });
            });
            return;
        }
        if (!PANEL_ENTIENDE[a]) return;
        pasar(Object.assign({}, o, { action: a }));
    });
})();

// PEGATINA (04/10): el rótulo a brocha de debajo de «Control Casa». Dice el estado
// («Cerrada» con el teclado del código delante, «Abierta» en el inicio) o el nombre
// de la sección. Solo deja el texto en data-brocha del título; quien lo pinta es
// origen-pegatina.css, así que en Nación no sale nada.
(function () {
    if (!/(^\/$|index\.html$)/.test(location.pathname)) return;
    function poner() {
        var titulo = document.getElementById("hdrProperty");
        var cuerpo = document.getElementById("content");
        if (!titulo || !cuerpo) return;
        var candado = cuerpo.querySelector(".lockscreen");
        var clase = candado && candado.getAttribute("data-kind");
        var activo = document.querySelector(".nav-item.is-active");
        var vista = activo && activo.getAttribute("data-view");
        var nombre = activo && activo.querySelector("span");
        var texto;
        if (clase === "device") texto = "Cerrada";
        else if (clase === "newcode" || clase === "owner") texto = "Código";
        else if (!vista || vista === "home") texto = "Abierta";
        else texto = (nombre && nombre.textContent.trim()) || "Abierta";
        texto = texto.charAt(0).toUpperCase() + texto.slice(1).toLowerCase();
        if (titulo.getAttribute("data-brocha") !== texto) titulo.setAttribute("data-brocha", texto);
    }
    document.addEventListener("DOMContentLoaded", function () {
        var cuerpo = document.getElementById("content");
        var riel = document.getElementById("nav");
        if (!cuerpo || !riel) return;
        new MutationObserver(poner).observe(cuerpo, { childList: true });
        new MutationObserver(poner).observe(riel, { subtree: true, attributes: true, attributeFilter: ["class"] });
        poner();
    });
})();
