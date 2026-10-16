// Packs, piezas sueltas y tamaño de las casas (custom/client/packs.lua y
// custom/server/packs.lua). Tres cosas, las tres aparte de script.js y obra.js:
//   1. En la cinta de decorar y construir (obra.js la pinta; esto va DESPUÉS y
//      solo le añade): el candado de lo que la casa no tiene, lo que le queda
//      a la casa según su tamaño y, en «Gastado», lo que lleva cobrado la obra.
//        { action: 'cintaExtra', contador: { tamano, celdas: [n, max], piezas, muebles, objetos? } | false, gastado }
//        y en cada cosa de { action: 'cinta' }: candado = 'Pack …'
//   2. Al crear una casa: el tamaño (modalidad Libre) y los packs con los que nace.
//   3. El panel de admin «Vivienda: cosméticos», a pantalla completa.
//        { action: 'cosmeticos', ver, casa, posibles, ambito }
(function () {
    const limpio = (t) => String(t == null ? '' : t).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
    const miles = (n) => Math.round(Number(n) || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    // (con la moneda de la casa: « $», « $ negro» u « OGN», js/propietario.js)
    const dinero = (n) => miles(n) + (window.OgnSufijoMoneda ? window.OgnSufijoMoneda() : ' $');
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

    // ══ 1. La cinta ═════════════════════════════════════════════════════════
    let extra = { contador: false, gastado: 0 };
    let ultima = null;      // el último mensaje 'cinta' que pintó obra.js

    function tope(nombre, par) {
        if (!par) return '';
        const queda = Math.max(0, (Number(par[1]) || 0) - (Number(par[0]) || 0));
        const clase = queda <= 0 ? ' cinta-tope--agotado' : (queda / Math.max(1, Number(par[1]) || 1) < 0.15 ? ' cinta-tope--aviso' : '');
        return `<span class="cinta-tope${clase}"><small>${nombre}</small><b>${miles(queda)}</b></span>`;
    }

    function pie() {
        const r = document.querySelector('.cinta');
        if (!r || r.hidden) return;
        const p = r.querySelector('.cinta-pie');
        const dato = p && p.querySelector('.cinta-dato');
        if (!dato) return;
        const viejo = p.querySelector('.cinta-topes');
        if (viejo) viejo.remove();
        const c = extra.contador;
        if (c) {
            let objetos = '';
            if (c.objetos) {
                const lleno = Number(c.objetos[0]) >= Number(c.objetos[1]);
                objetos = `<span class="cinta-tope ${lleno ? 'cinta-tope--agotado' : 'cinta-tope--aviso'}"><small>Objetos</small><b>${miles(c.objetos[0])}/${miles(c.objetos[1])}</b></span>`;
            }
            dato.insertAdjacentHTML('beforebegin', `<span class="cinta-topes" title="Lo que le queda a la casa"><em>${c.objetos ? 'Quedan' : limpio(c.tamano || '') + ' · quedan'}</em>`
                + tope('Celdas', c.celdas) + tope('Piezas', c.piezas) + tope('Muebles', c.muebles) + objetos + '</span>');
        }
        const cifra = dato.querySelector('b');
        if (cifra) cifra.textContent = dinero((Number(ultima && ultima.gastado) || 0) + (Number(extra.gastado) || 0));
        // las teclas se vuelven a encoger lo justo: ahora tienen menos sitio (obra.js)
        if (window.OgnCintaEncoger) window.OgnCintaEncoger();
    }

    function candados(d) {
        const r = document.querySelector('.cinta');
        if (!r || r.hidden) return;
        const cosas = r.querySelectorAll('.cinta-cosas > .cinta-cosa');
        (d.cosas || []).forEach((c, n) => {
            const caja = cosas[n];
            if (!c || !c.candado || !caja) return;
            caja.classList.add('cinta-cosa--candado');
            caja.insertAdjacentHTML('beforeend', '<i class="fas fa-lock cinta-candado"></i>');
            const nombre = c.on && r.querySelector('.cinta-ficha__extra');
            if (nombre) nombre.insertAdjacentHTML('beforeend', `<u class="cinta-pack"><i class="fas fa-lock"></i>${limpio(c.candado)}</u>`);
        });
    }

    // ══ 2. Crear una casa ═══════════════════════════════════════════════════
    let catalogo = null;

    function detalleTamano(t) {
        if (!t) return '';
        return `${limpio(t.descripcion || '')} · ${miles(t.celdas)} celdas, ${miles(t.piezas)} piezas y ${miles(t.muebles)} muebles`;
    }

    function ponerEnElFormulario(forma) {
        if (forma.querySelector('.obra_tamanos') || forma.dataset.packs) return;
        const tipos = forma.querySelector('.house_types');
        if (!tipos) return;       // (editando una casa que ya existe no se elige: para eso está el panel de cosméticos)
        forma.dataset.packs = '1';
        pedir('packsCatalogo').then((c) => {
            if (!c || !forma.isConnected || forma.querySelector('.obra_tamanos')) return;
            catalogo = c;
            const elegido = c.tamano;
            let html = '<div class="mt-4 col-12 obra_tamanos" style="display: none;"><h4>Tamaño de la casa</h4>'
                + '<span class="desc mb-2">Cuánto se podrá excavar, construir y amueblar. Se puede cambiar después desde el panel de cosméticos.</span>'
                + '<div class="d-flex align-items-center justify-content-start mt-2 obra_tamanos__lista">'
                + (c.tamanos || []).map((t) => `<div class="btn option${t.id === elegido ? ' active' : ''}" data-tam="${limpio(t.id)}"><i class="fa-solid fa-ruler-combined"></i><span>${limpio(t.nombre)}</span></div>`).join('')
                + `</div><span class="desc obra_tamanos__det">${detalleTamano((c.tamanos || []).find((t) => t.id === elegido))}</span></div>`;
            if ((c.packs || []).length) {
                const grupos = (c.grupos || []).slice();
                c.packs.forEach((p) => { if (grupos.indexOf(p.grupo) < 0) grupos.push(p.grupo); });
                html += '<div class="mt-4 col-12 casa_packs"><h4>Packs de contenido</h4>'
                    + '<span class="desc mb-2">Lo que trae esta casa además de lo básico. Los demás se consiguen después en la tienda.</span>';
                grupos.forEach((g) => {
                    const suyos = c.packs.filter((p) => p.grupo === g);
                    if (!suyos.length) return;
                    html += `<h5 class="mt-3">${limpio(g)}</h5><div class="d-flex align-items-center justify-content-start casa_packs__lista">`
                        + suyos.map((p) => `<div class="btn option" data-pack="${limpio(p.id)}" title="${limpio(p.descripcion || '')}"><i class="fa-solid fa-box-open"></i><span>${limpio(p.nombre)}</span><em>${miles(p.piezas)}</em></div>`).join('')
                        + '</div>';
                });
                html += '</div>';
            }
            const tras = forma.querySelector('.int_categories') || tipos;
            tras.insertAdjacentHTML('afterend', html);
            const activo = tipos.querySelector('.option.active');
            if (activo && activo.getAttribute('type') === 'libre') forma.querySelector('.obra_tamanos').style.display = '';
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
        const tipo = e.target.closest && e.target.closest('.house_types .option');
        if (tipo) {
            const caja = document.querySelector('.create-house .obra_tamanos');
            if (caja) caja.style.display = tipo.getAttribute('type') === 'libre' ? '' : 'none';
            return;
        }
        const tam = e.target.closest && e.target.closest('.obra_tamanos .option');
        if (tam) {
            tam.parentElement.querySelectorAll('.option').forEach((x) => x.classList.toggle('active', x === tam));
            const det = tam.closest('.obra_tamanos').querySelector('.obra_tamanos__det');
            const t = catalogo && (catalogo.tamanos || []).find((x) => x.id === tam.dataset.tam);
            if (det) det.textContent = detalleTamano(t).replace(/&amp;/g, '&');
            return;
        }
        const pack = e.target.closest && e.target.closest('.casa_packs .option');
        if (pack) pack.classList.toggle('active');
    });

    // Lo llama SaveHouse (script.js) al guardar una casa nueva: deja en sus datos el tamaño y los packs marcados
    window.OgnPacks = {
        alGuardar(datos, libre) {
            if (!datos) return;
            const tam = document.querySelector('.create-house .obra_tamanos .option.active');
            datos.tamano = libre ? ((tam && tam.dataset.tam) || (catalogo && catalogo.tamano) || undefined) : undefined;
            datos.packs = Array.from(document.querySelectorAll('.create-house .casa_packs .option.active')).map((x) => x.dataset.pack);
        },
    };

    // ══ 3. El panel «Vivienda: cosméticos» ══════════════════════════════════
    const C = { raiz: null, vista: 'casas', texto: '', lista: null, casa: null, registro: null, posibles: {}, ambito: 'casa', aCuenta: false, tipo: 'material', filtro: '', aviso: '', espera: null };

    function montarPanel() {
        if (C.raiz) return C.raiz;
        C.raiz = document.createElement('div');
        C.raiz.className = 'cosm';
        C.raiz.hidden = true;
        C.raiz.innerHTML = '<div class="cosm-panel"><nav class="cosm-rail"></nav><section class="cosm-main">'
            + '<header class="cosm-cab"><span class="cosm-placa"><i class="fas fa-gem"></i></span>'
            + '<div class="cosm-cab__txt"><h1>Vivienda: cosméticos</h1><p>Tamaño, packs y piezas sueltas de cada casa. Solo se consiguen por XP: aquí se dan y se quitan a mano.</p></div>'
            + '<label class="cosm-busca"><i class="fas fa-magnifying-glass"></i><input type="text" maxlength="60" spellcheck="false" autocomplete="off" placeholder="Número de casa, nombre o dueño"></label></header>'
            + '<div class="cosm-cuerpo"></div><footer class="cosm-cifras"></footer></section></div>';
        document.body.appendChild(C.raiz);
        C.raiz.querySelector('.cosm-cab .cosm-busca input').addEventListener('input', (e) => {
            C.texto = e.target.value;
            clearTimeout(C.espera);
            C.espera = setTimeout(() => { C.vista = 'casas'; C.casa = null; buscar(); }, 300);
        });
        C.raiz.addEventListener('click', alPulsar);
        // el filtro de las piezas que se pueden dar: solo se rehace la lista, para no perder el cursor
        C.raiz.addEventListener('input', (e) => {
            if (!e.target.matches('.cosm-filtro')) return;
            C.filtro = e.target.value;
            const caja = C.raiz.querySelector('.cosm-posibles');
            if (caja) caja.innerHTML = posibles();
        });
        return C.raiz;
    }

    function buscar() {
        pedir('cosmeticosBuscar', { texto: C.texto }).then((r) => { C.lista = r || { casas: [], hay: 0, cifras: {} }; pintarPanel(); });
    }

    function abrirCasa(id) {
        pedir('cosmeticosCasa', { id: id }).then((r) => {
            if (!r) { C.aviso = 'Esa casa no existe'; C.casa = null; C.vista = 'casas'; } else { C.casa = r; C.vista = 'casa'; C.aCuenta = C.ambito === 'cuenta' && !!r.dueno; }
            pintarPanel();
        });
    }

    function orden(o) {
        if (!C.casa) return;
        o.cuenta = o.cuenta === undefined ? C.aCuenta : o.cuenta;
        pedir('cosmeticosOrden', { id: C.casa.id, orden: o }).then((r) => {
            if (!r) return;
            C.casa = r.casa || C.casa;
            C.aviso = r.motivo || '';
            pintarPanel();
        });
    }

    function alPulsar(e) {
        const b = e.target.closest('[data-que]');
        if (!b) return;
        const que = b.dataset.que;
        C.aviso = '';
        if (que === 'vista') {
            C.vista = b.dataset.v;
            C.casa = null;
            if (C.vista === 'registro') pedir('cosmeticosRegistro').then((r) => { C.registro = r || []; pintarPanel(); });
            else buscar();
            pintarPanel();
        } else if (que === 'casa') {
            abrirCasa(b.dataset.id);
        } else if (que === 'volver') {
            C.vista = 'casas'; C.casa = null; buscar();
        } else if (que === 'destino') {
            C.aCuenta = b.dataset.v === 'cuenta'; pintarPanel();
        } else if (que === 'tamano') {
            orden({ accion: 'tamano', valor: b.dataset.id, cuenta: false });
        } else if (que === 'pack') {
            // lo que ya tiene se quita de donde esté; lo que no, se da a donde diga «Destino»
            const p = (C.casa.lista || []).find((x) => x.id === b.dataset.id);
            if (!p) return;
            if (p.casa) orden({ accion: 'pack', valor: p.id, dar: false, cuenta: false });
            else if (p.cuenta) orden({ accion: 'pack', valor: p.id, dar: false, cuenta: true });
            else orden({ accion: 'pack', valor: p.id, dar: true });
        } else if (que === 'quitarPieza') {
            const corte = b.dataset.id.indexOf(':');
            orden({ accion: 'pieza', tipo: b.dataset.id.slice(0, corte), valor: b.dataset.id.slice(corte + 1), dar: false, cuenta: b.dataset.cuenta === '1' });
        } else if (que === 'tipo') {
            C.tipo = b.dataset.v; C.filtro = ''; pintarPanel();
        } else if (que === 'darPieza') {
            orden({ accion: 'pieza', tipo: C.tipo, valor: b.dataset.id, dar: true });
        }
    }

    function fichaCasa(c) {
        return `<button class="cosm-ficha" data-que="casa" data-id="${limpio(c.id)}"><span class="cosm-ficha__n">${limpio(c.id)}</span>`
            + `<b>${limpio(c.nombre || 'Sin nombre')}</b>`
            + `<small>${c.dueno ? limpio(c.duenoNombre ? c.duenoNombre + ' · ' + c.dueno : c.dueno) : 'Sin dueño'}</small>`
            + `<span class="cosm-ficha__pie">${c.libre ? `<i class="cosm-chapa cosm-chapa--rosa">${limpio(c.tamano || 'Libre')}</i>` : '<i class="cosm-chapa">Módulo</i>'}`
            + `<i class="cosm-chapa">${miles(c.packs)} ${Number(c.packs) === 1 ? 'pack' : 'packs'}</i>${c.sueltas ? `<i class="cosm-chapa">${miles(c.sueltas)} ${Number(c.sueltas) === 1 ? 'suelta' : 'sueltas'}</i>` : ''}</span></button>`;
    }

    // Las piezas del tipo elegido que casan con lo escrito y que la casa aún no tiene sueltas
    function posibles() {
        const lista = (C.posibles && C.posibles[C.tipo]) || [];
        const tiene = {};
        ((C.casa && C.casa.piezas) || []).forEach((p) => { tiene[p.clave] = true; });
        const busca = C.filtro.trim().toLowerCase();
        const salen = lista.filter((p) => !tiene[C.tipo + ':' + p.id]
            && (!busca || (p.nombre + ' ' + p.id + ' ' + p.pack).toLowerCase().indexOf(busca) >= 0));
        return (salen.slice(0, 48).map((p) => `<button class="cosm-suelta cosm-suelta--dar" data-que="darPieza" data-id="${limpio(p.id)}" title="${limpio(p.id)}">`
            + `<i class="fas fa-plus"></i>${limpio(p.nombre)}<em>${limpio(p.pack)}</em></button>`).join('')
            || '<span class="cosm-nota">Nada casa con eso.</span>')
            + (salen.length > 48 ? `<span class="cosm-nota">…y ${salen.length - 48} más: escribe para afinar.</span>` : '');
    }

    function vistaCasa(c) {
        let h = `<div class="cosm-tira"><button class="cosm-boton" data-que="volver"><i class="fas fa-arrow-left"></i> Casas</button>`
            + `<div class="cosm-tira__t"><b>Casa ${limpio(c.id)} · ${limpio(c.nombre || '')}</b><small>${c.dueno ? 'Dueño: ' + limpio(c.duenoNombre ? c.duenoNombre + ' · ' + c.dueno : c.dueno) : 'Sin dueño'}</small></div>`;
        if (c.dueno) {
            h += '<div class="cosm-destino"><small>Lo que des va a</small>'
                + `<button class="cosm-boton${!C.aCuenta ? ' on' : ''}" data-que="destino" data-v="casa">Esta casa</button>`
                + `<button class="cosm-boton${C.aCuenta ? ' on' : ''}" data-que="destino" data-v="cuenta" title="Vale en todas las casas de su dueño">La cuenta del dueño</button></div>`;
        }
        h += '</div>';
        if (C.aviso) h += `<p class="cosm-aviso"><i class="fas fa-triangle-exclamation"></i> ${limpio(C.aviso)}</p>`;

        if (c.libre) {
            h += '<h2 class="cosm-rotulo">Tamaño</h2><div class="cosm-rejilla cosm-rejilla--4">'
                + (c.tamanos || []).map((t) => `<button class="cosm-ficha${t.id === c.tamanoId ? ' on' : ''}" data-que="tamano" data-id="${limpio(t.id)}"><b>${limpio(t.nombre)}</b>`
                    + `<small>${limpio(t.descripcion || '')}</small><span class="cosm-ficha__pie"><i class="cosm-chapa">${miles(t.celdas)} celdas</i><i class="cosm-chapa">${miles(t.piezas)} piezas</i>`
                    + `<i class="cosm-chapa">${miles(t.muebles)} muebles</i>${t.xp ? `<i class="cosm-chapa cosm-chapa--xp">${miles(t.xp)} XP</i>` : ''}</span></button>`).join('')
                + '</div>';
            if (c.uso && c.limites) {
                h += `<p class="cosm-nota">Ahora mismo: ${miles(c.uso.celdas)} de ${miles(c.limites.celdas)} celdas · ${miles(c.uso.piezas)} de ${miles(c.limites.piezas)} piezas · ${miles(c.uso.muebles)} de ${miles(c.limites.muebles)} muebles. Lo que tenga de más se queda: solo deja de poder crecer.</p>`;
            }
        }

        const grupos = (c.grupos || []).slice();
        (c.lista || []).forEach((p) => { if (grupos.indexOf(p.grupo) < 0) grupos.push(p.grupo); });
        grupos.forEach((g) => {
            const suyos = (c.lista || []).filter((p) => p.grupo === g);
            if (!suyos.length) return;
            const tiene = suyos.filter((p) => p.casa || p.cuenta).length;
            const piezas = suyos.reduce((n, p) => n + (Number(p.piezas) || 0), 0);
            h += `<h2 class="cosm-rotulo">Packs · ${limpio(g)} <em>${tiene} de ${suyos.length} · ${miles(piezas)} piezas</em></h2><div class="cosm-rejilla">`
                + suyos.map((p) => `<button class="cosm-ficha${(p.casa || p.cuenta) ? ' on' : ''}" data-que="pack" data-id="${limpio(p.id)}"><b>${limpio(p.nombre)}</b>`
                    + `<small>${limpio(p.descripcion || '')}</small><span class="cosm-ficha__pie"><i class="cosm-chapa">${miles(p.piezas)} piezas</i>`
                    + `${p.xp ? `<i class="cosm-chapa cosm-chapa--xp">${miles(p.xp)} XP</i>` : ''}`
                    + `${p.casa ? '<i class="cosm-chapa cosm-chapa--negra">En la casa</i>' : ''}${p.cuenta ? '<i class="cosm-chapa cosm-chapa--negra">En la cuenta</i>' : ''}</span></button>`).join('')
                + '</div>';
        });

        h += `<h2 class="cosm-rotulo">Piezas sueltas <em>${(c.piezas || []).length}</em></h2><div class="cosm-sueltas">`
            + ((c.piezas || []).map((p) => `<span class="cosm-suelta">${limpio(p.nombre)}${p.cuenta && !p.casa ? ' <em>cuenta</em>' : ''}`
                + `<button data-que="quitarPieza" data-id="${limpio(p.clave)}" data-cuenta="${p.cuenta && !p.casa ? 1 : 0}" title="Quitar"><i class="fas fa-xmark"></i></button></span>`).join('')
                || '<span class="cosm-nota">Esta casa no tiene piezas sueltas.</span>')
            + '</div><h2 class="cosm-rotulo">Dar una pieza suelta <em>algo concreto de un pack, sin dar el pack entero</em></h2><div class="cosm-dar">'
            + [['material', 'Materiales'], ['estilo', 'Estilos'], ['herramienta', 'Herramientas'], ['modelo', 'Muebles']]
                .map((t) => `<button class="cosm-boton${t[0] === C.tipo ? ' on' : ''}" data-que="tipo" data-v="${t[0]}">${t[1]}</button>`).join('')
            + `<label class="cosm-busca cosm-busca--corta"><i class="fas fa-magnifying-glass"></i><input class="cosm-filtro" type="text" maxlength="40" spellcheck="false" autocomplete="off" placeholder="Filtrar" value="${limpio(C.filtro)}"></label></div>`
            + `<div class="cosm-sueltas cosm-posibles">${posibles()}</div>`;
        return h;
    }

    function pintarPanel() {
        const r = montarPanel();
        r.querySelector('.cosm-rail').innerHTML = [['casas', 'fa-house', 'Casas'], ['registro', 'fa-clipboard-list', 'Registro']]
            .map((v) => `<button class="cosm-rail__b${(C.vista === v[0] || (v[0] === 'casas' && C.vista === 'casa')) ? ' on' : ''}" data-que="vista" data-v="${v[0]}"><i class="fas ${v[1]}"></i><span>${v[2]}</span></button>`).join('')
            + '<span class="cosm-rail__esc"><kbd>Esc</kbd>Cerrar</span>';
        const cuerpo = r.querySelector('.cosm-cuerpo');
        if (C.vista === 'casa' && C.casa) {
            cuerpo.innerHTML = vistaCasa(C.casa);
        } else if (C.vista === 'registro') {
            cuerpo.innerHTML = '<h2 class="cosm-rotulo">Registro <em>lo último que se ha dado y quitado</em></h2><div class="cosm-registro">'
                + ((C.registro || []).map((a) => `<div><time>${limpio(a.fecha)}</time><b>${limpio(a.quien)}</b><span>${limpio(a.accion)} <u>${limpio(a.que)}</u> → ${limpio(a.destino)}</span></div>`).join('')
                    || '<span class="cosm-nota">Aún no hay nada apuntado.</span>') + '</div>';
        } else {
            const l = C.lista || { casas: [], hay: 0 };
            cuerpo.innerHTML = (C.aviso ? `<p class="cosm-aviso"><i class="fas fa-triangle-exclamation"></i> ${limpio(C.aviso)}</p>` : '')
                + `<h2 class="cosm-rotulo">Casas <em>${miles(l.hay)}${l.hay > l.casas.length ? ' · se ven las primeras ' + l.casas.length + ': afina la búsqueda' : ''}</em></h2>`
                + '<div class="cosm-rejilla">' + (l.casas.map(fichaCasa).join('') || '<span class="cosm-nota">Ninguna casa casa con eso.</span>') + '</div>';
        }
        const cf = (C.lista && C.lista.cifras) || {};
        r.querySelector('.cosm-cifras').innerHTML = [['Casas', cf.casas], ['Con dueño', cf.conDueno], ['De modalidad libre', cf.libres], ['Packs', cf.packs]]
            .map((x) => `<span><b>${miles(x[1])}</b><small>${x[0]}</small></span>`).join('')
            + `<span class="cosm-cifras__amb"><small>Lo comprado va a</small><b>${C.ambito === 'cuenta' ? 'la cuenta' : 'la casa'}</b></span>`;
    }

    function cerrarPanel() {
        if (!C.raiz || C.raiz.hidden) return;
        C.raiz.hidden = true;
        pedir('cosmeticosCerrar');
    }

    function cosmeticos(d) {
        const r = montarPanel();
        if (!d.ver) { r.hidden = true; return; }
        C.posibles = d.posibles || {};
        C.ambito = d.ambito || 'casa';
        C.vista = 'casas'; C.casa = null; C.aviso = ''; C.texto = ''; C.filtro = '';
        r.querySelector('.cosm-cab .cosm-busca input').value = '';
        r.hidden = false;
        pintarPanel();
        buscar();
        if (d.casa) abrirCasa(d.casa);
    }

    // Escape cierra (y no le llega al resto de la interfaz, que escucha el keyup)
    let cerrando = false;
    window.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && C.raiz && !C.raiz.hidden) { e.stopPropagation(); cerrando = true; cerrarPanel(); }
    }, true);
    window.addEventListener('keyup', (e) => {
        if (e.key === 'Escape' && cerrando) { e.stopPropagation(); cerrando = false; }
    }, true);

    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d) return;
        if (d.action === 'cinta') {
            if (d.ver) { ultima = d; candados(d); pie(); }
        } else if (d.action === 'cintaExtra') {
            extra = { contador: d.contador || false, gastado: Number(d.gastado) || 0 };
            pie();
        } else if (d.action === 'cosmeticos') {
            cosmeticos(d);
        }
    });
})();
