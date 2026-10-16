// De quién es una casa: particular, de una banda o de un crew
// (custom/client/propietario.lua y custom/server/propietario.lua). Dos cosas,
// las dos aparte de script.js:
//   1. En el formulario de crear y de editar una casa: «Tipo de propietario»
//      (Particular / De banda / De crew) y el desplegable con las bandas o los
//      crews que hay. script.js llama a OgnPropietario.alGuardar al guardar.
//   2. La cuenta de llaves («2/3», o «miembros: sin límite · de fuera 1/3»)
//      cuando cambia con el panel abierto.
//        { action: 'llavesResumen', id, llaves: { texto, propietario, … } }
(function () {
    const limpio = (t) => String(t == null ? '' : t).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
    const recurso = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'origen_housing';
    // (script.js declara su propia función `fetch`, que pisa la del navegador: aquí se va por XMLHttpRequest)
    const pedir = (nombre, datos) => new Promise((hecho) => {
        const x = new XMLHttpRequest();
        x.open('POST', `https://${recurso}/${nombre}`);
        x.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
        x.onload = () => { try { hecho(JSON.parse(x.responseText)); } catch (e) { hecho(false); } };
        x.onerror = () => hecho(false);
        x.send(JSON.stringify(datos || {}));
    });
    // (`app` es un `let` de script.js: se ve por su nombre, no cuelga de window)
    const laApp = () => (typeof app !== 'undefined' ? app : null);
    const t = (clave, defecto) => (laApp() && laApp().translations && laApp().translations[clave]) || defecto;

    const estilo = document.createElement('style');
    estilo.textContent = '.create-house .casa_propietario__tipos { flex-wrap: wrap; row-gap: 8px; }'
        + '.create-house .casa_propietario .option.is-off { opacity: .4; pointer-events: none; }'
        + '.create-house .casa_propietario__grupo { margin-top: 10px; cursor: pointer; }'
        + '.create-house .casa_propietario__nota { display: block; margin-top: 8px; }';
    (document.head || document.documentElement).appendChild(estilo);

    // ══ 1. El formulario ════════════════════════════════════════════════════
    let listas = null;

    function nota(uso) {
        const l = (listas && listas.llaves) || { particular: 3, deFuera: 3 };
        if (uso === 'banda') {
            return t('ownerGangDesc', 'Llaves sin límite para los miembros de la banda y %s para gente de fuera.').replace('%s', l.deFuera)
                + (listas && listas.territorio ? ' ' + t('ownerGangZoneDesc', 'La zona exterior será el territorio principal de la banda: no hay que dibujarla.') : '');
        }
        if (uso === 'crew') {
            return t('ownerCrewDesc', 'Llaves sin límite para los miembros del crew y %s para gente de fuera.').replace('%s', l.deFuera)
                + (listas && listas.territorio ? ' ' + t('ownerCrewZoneDesc', 'La zona exterior será el territorio de la crew: no hay que dibujarla.') : '');
        }
        return t('ownerPrivateDesc', 'Una casa particular admite %s llaves además de la del dueño.').replace('%s', l.particular);
    }

    function pintar(caja, uso, grupo, nombre) {
        caja.querySelectorAll('.casa_propietario__tipos .option').forEach((o) => o.classList.toggle('active', o.dataset.uso === uso));
        const sel = caja.querySelector('.casa_propietario__grupo');
        const lista = (uso === 'banda' ? listas.bandas : uso === 'crew' ? listas.crews : null) || [];
        if (uso === 'particular') {
            sel.style.display = 'none';
            sel.innerHTML = '';
        } else {
            // Una crew tiene una sola casa, que es su base: la que ya la tiene
            // sale marcada (salvo si lo que se edita es justo esa casa). El
            // servidor no deja ponerle otra.
            const editando = laApp() && laApp().creationData && laApp().creationData.id;
            const conBase = (g) => uso === 'crew' && g.base != null && String(g.base) !== String(editando);
            let html = `<option value="">${limpio(uso === 'banda' ? t('ownerPickGang', 'Elige la banda…') : t('ownerPickCrew', 'Elige el crew…'))}</option>`
                + lista.map((g) => `<option value="${limpio(g.id)}">${limpio(g.label)}${conBase(g) ? ' · ' + limpio(t('ownerCrewHasBase', 'ya tiene base')) : ''}</option>`).join('');
            // la que tenía la casa y ya no está en la lista: se enseña, para no cambiarla sin querer
            if (grupo != null && grupo !== '' && !lista.some((g) => String(g.id) === String(grupo))) {
                html += `<option value="${limpio(grupo)}">${limpio(nombre || grupo)} ${limpio(t('ownerGone', '(ya no existe)'))}</option>`;
            }
            sel.innerHTML = html;
            sel.value = grupo != null ? String(grupo) : '';
            sel.style.display = '';
        }
        caja.querySelector('.casa_propietario__nota').textContent = nota(uso);
    }

    function ponerEnElFormulario(forma) {
        if (forma.querySelector('.casa_propietario') || forma.dataset.propietario) return;
        const antes = forma.querySelector('.col-12.payment-method');
        if (!antes) return;
        forma.dataset.propietario = '1';
        // editando, script.js deja la casa en app.creationData
        const d = (laApp() && laApp().creationData && laApp().creationData.data) || {};
        const usoDe = (d.uso === 'banda' || d.uso === 'crew') && d.grupo != null ? d.uso : 'particular';
        pedir('propietarioListas').then((l) => {
            if (!forma.isConnected || forma.querySelector('.casa_propietario')) return;
            listas = l || { bandas: false, crews: false };
            const off = (lista, uso) => (!lista && usoDe !== uso ? ' is-off' : '');
            antes.insertAdjacentHTML('beforebegin', '<div class="mt-4 col-12 casa_propietario">'
                + `<h4>${limpio(t('ownerType', 'Tipo de propietario'))}</h4>`
                + `<span class="desc mb-2">${limpio(t('ownerTypeDesc', 'De quién es la casa. De ello depende cuántas llaves se pueden dar.'))}</span>`
                + '<div class="d-flex align-items-center justify-content-start mt-2 casa_propietario__tipos">'
                + `<div class="btn option" data-uso="particular"><i class="fa-solid fa-user"></i><span>${limpio(t('ownerPrivate', 'Particular'))}</span></div>`
                + `<div class="btn option${off(listas.bandas, 'banda')}" data-uso="banda" title="${listas.bandas ? '' : limpio(t('ownerUnavailable', 'No disponible ahora mismo'))}"><i class="fa-solid fa-people-group"></i><span>${limpio(t('ownerGang', 'De banda'))}</span></div>`
                + `<div class="btn option${off(listas.crews, 'crew')}" data-uso="crew" title="${listas.crews ? '' : limpio(t('ownerUnavailable', 'No disponible ahora mismo'))}"><i class="fa-solid fa-flag-checkered"></i><span>${limpio(t('ownerCrew', 'De crew'))}</span></div>`
                + '</div>'
                + '<select class="form-control w-100 casa_propietario__grupo" style="display: none;"></select>'
                + '<span class="desc casa_propietario__nota"></span>'
                + '</div>');
            pintar(forma.querySelector('.casa_propietario'), usoDe, usoDe === 'particular' ? null : d.grupo, d.grupoNombre);
        });
    }

    // El formulario lo monta script.js dentro de un diálogo: se mira cuándo aparece
    let mirando = false;
    const vigia = new MutationObserver(() => {
        if (mirando) return;
        mirando = true;
        requestAnimationFrame(() => {
            mirando = false;
            const forma = document.querySelector('.create-house');
            if (forma) ponerEnElFormulario(forma);
        });
    });
    document.addEventListener('DOMContentLoaded', () => vigia.observe(document.body, { childList: true, subtree: true }));
    if (document.body) vigia.observe(document.body, { childList: true, subtree: true });

    document.addEventListener('click', (e) => {
        const tipo = e.target.closest && e.target.closest('.casa_propietario__tipos .option');
        if (!tipo || !listas) return;
        pintar(tipo.closest('.casa_propietario'), tipo.dataset.uso, null, null);
    });

    // Lo llama script.js al guardar (crear y editar): deja el propietario en
    // `data` de la casa. Devuelve false si falta elegir la banda o el crew.
    // El servidor vuelve a mirar que exista y pone él el nombre.
    function alGuardar(data) {
        const caja = document.querySelector('.create-house .casa_propietario');
        if (!caja) {              // (las listas no han llegado: la casa se queda como estaba)
            if (!data.uso) data.uso = 'particular';
            return true;
        }
        const activo = caja.querySelector('.casa_propietario__tipos .option.active');
        const uso = (activo && activo.dataset.uso) || 'particular';
        if (uso === 'particular') {
            data.uso = 'particular';
            delete data.grupo;
            delete data.grupoNombre;
            return true;
        }
        const sel = caja.querySelector('.casa_propietario__grupo');
        if (!sel || !sel.value) {
            if (laApp()) laApp().sendNotification('error', t('error', 'Error'), uso === 'banda' ? t('ownerNeedGang', 'Elige de qué banda es la casa') : t('ownerNeedCrew', 'Elige de qué crew es la casa'));
            return false;
        }
        data.uso = uso;
        data.grupo = sel.value;
        return true;
    }
    window.OgnPropietario = { alGuardar };

    // ══ 1b. La moneda de la casa ════════════════════════════════════════════
    // En qué se paga en la casa en la que está el jugador (custom/client/moneda.lua):
    // 'dinero', 'negro' (casa de banda) u 'ogn' (casa de crew). Solo para pintar los
    // precios; cobra el servidor (custom/server/moneda.lua).
    //   { action: 'monedaCasa', moneda }
    let moneda = 'dinero';
    window.OgnSufijoMoneda = () => (moneda === 'negro' ? ' $ negro' : moneda === 'ogn' ? ' OGN' : ' $');
    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d || d.action !== 'monedaCasa') return;
        moneda = (d.moneda === 'negro' || d.moneda === 'ogn') ? d.moneda : 'dinero';
        const a = laApp();
        if (a) a.monedaCasa = moneda;
    });

    // ══ 2. La cuenta de llaves ══════════════════════════════════════════════
    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d || d.action !== 'llavesResumen' || !laApp()) return;
        const a = laApp();
        if (a.house && a.house.data && String(a.house.data.id) === String(d.id)) a.$set(a.house.data, 'llaves', d.llaves);
        if (a.houseList && a.houseList[d.id]) a.$set(a.houseList[d.id], 'llaves', d.llaves);
        if (a.selectedMapHouse && String(a.selectedMapHouse.id) === String(d.id)) a.$set(a.selectedMapHouse, 'llaves', d.llaves);
    });
})();
