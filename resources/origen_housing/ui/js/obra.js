// La cinta de decorar y construir (custom/client/obra.lua) y la pestaña
// Construir del menú Decorar. La cinta solo pinta lo que le manda el cliente:
// no coge foco ni teclas.
//   { action: 'cinta', ver, categorias: [{nombre, icono}], categoria, cosas: [{img | icono, precio, nombre, on} | {hueco}],
//     desc,                                          qué hace la cosa elegida, en una frase (la ficha de la izquierda)
//     nombre, precio, favorito, cuenta, teclas: [{key, text}], gastado,
//     subs: [{nombre, n}], sub, pista,            los subgrupos del grupo, el de la cosa elegida y, si no hay, un renglón
//     variantes: [{nombre, img, on}], variantesDe,   los estilos de la herramienta (los pasa la R)
//     ayuda: {titulo, lineas: [], teclas: [[tecla, texto]]} | null,
//     busca: {activo, texto, n} | null }             con activo, la página escribe: cintaBusca {texto}, cintaBuscaFin {ok}
// (config/cinta.lua: grupos, subgrupos, nombres, teclas y ayuda)
(function () {
    const limpio = (t) => String(t == null ? '' : t).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
    // (con la moneda de la casa: « $», « $ negro» u « OGN», js/propietario.js)
    const dinero = (n) => Math.round(Number(n) || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.') + (window.OgnSufijoMoneda ? window.OgnSufijoMoneda() : ' $');

    let raiz = null;
    let firmaCats = '';
    function montar() {
        if (raiz) return raiz;
        raiz = document.createElement('div');
        raiz.className = 'cinta';
        raiz.hidden = true;
        raiz.setAttribute('data-foco-ignora', '');
        // (13/10, diseño B) A la izquierda, la FICHA de lo que se lleva: nombre, para qué sirve y sus
        // estilos. A la derecha, lo de siempre: grupos, subgrupos, las cosas (ahora con su nombre) y las teclas.
        raiz.innerHTML = '<div class="cinta-ayuda" hidden></div><div class="cinta-cuerpo">'
            + '<div class="cinta-ficha"><div class="cinta-ficha__cab"></div><p class="cinta-ficha__desc"></p><div class="cinta-ficha__extra"></div><div class="cinta-vars" hidden></div></div>'
            + '<div class="cinta-der"><div class="cinta-cats"></div>'
            + '<div class="cinta-subs"><div class="cinta-subs__zona"></div>'
            + '<label class="cinta-busca" hidden><i class="fas fa-magnifying-glass"></i><input type="text" maxlength="40" spellcheck="false" autocomplete="off"><span class="cinta-busca__n"></span></label>'
            + '<span class="cinta-lupa"><kbd class="cinta-tecla">Intro</kbd><span class="cinta-k">Buscar</span><kbd class="cinta-tecla">H</kbd><span class="cinta-k">Ayuda</span></span></div>'
            + '<div class="cinta-cosas"></div><div class="cinta-pie"></div></div></div>';
        document.body.appendChild(raiz);
        buscador(raiz);
        return raiz;
    }

    // ── El buscador ──
    // Solo mientras se escribe tiene la página el teclado (el cliente se lo da
    // sin ratón y se lo quita al acabar). Cada letra va al cliente, que
    // contesta con la cinta ya filtrada; Intro acepta y Esc cancela.
    let buscando = false;
    function avisar(nombre, datos) {
        try {
            const x = new XMLHttpRequest();
            x.open('POST', 'https://' + (typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'origen_housing') + '/' + nombre);
            x.setRequestHeader('Content-Type', 'application/json; charset=UTF-8');
            x.send(JSON.stringify(datos || {}));
        } catch (e) { /* fuera del juego (la maqueta) no hay a quién avisar */ }
    }
    function buscador(r) {
        const campo = r.querySelector('.cinta-busca input');
        campo.addEventListener('input', () => { if (buscando) avisar('cintaBusca', { texto: campo.value }); });
        campo.addEventListener('blur', () => { if (buscando) setTimeout(() => { if (buscando) campo.focus(); }, 30); });
        // En captura y sin dejar pasar nada: el resto de la página (el menú de
        // la casa) no tiene que enterarse de lo que se escribe aquí.
        const tecla = (e) => {
            if (!buscando) return;
            e.stopPropagation();
            if (e.type !== 'keydown') return;
            if (e.key === 'Enter' || e.key === 'Escape') {
                e.preventDefault();
                avisar('cintaBuscaFin', { ok: e.key === 'Enter', texto: campo.value });
            }
        };
        window.addEventListener('keydown', tecla, true);
        window.addEventListener('keyup', tecla, true);
    }
    function buscar(r, b) {
        const activo = !!(b && b.activo);
        const caja = r.querySelector('.cinta-busca');
        const campo = caja.querySelector('input');
        if (activo !== buscando) {
            buscando = activo;
            caja.hidden = !activo;
            r.querySelector('.cinta-subs__zona').hidden = activo;
            r.querySelector('.cinta-lupa').hidden = activo;
            if (activo) {
                campo.value = b.texto || '';
                setTimeout(() => campo.focus(), 30);
            } else {
                campo.blur();
            }
        }
        if (activo) {
            caja.querySelector('.cinta-busca__n').innerHTML = `<b>${Number(b.n) || 0}</b> ${Number(b.n) === 1 ? 'resultado' : 'resultados'}`
                + '<kbd class="cinta-tecla">Intro</kbd><span class="cinta-k">Aceptar</span><kbd class="cinta-tecla">Esc</kbd><span class="cinta-k">Cancelar</span>';
        }
    }

    // Los subgrupos del grupo elegido (flechas): se rehacen al cambiar de
    // grupo; al pasar de uno a otro solo cambia cuál va marcado.
    function subgrupos(r, d) {
        const zona = r.querySelector('.cinta-subs__zona');
        const subs = d.subs || [];
        const firma = subs.map((s) => s.nombre + ':' + s.n).join('|') + '#' + (d.pista || '');
        if (zona.dataset.firma !== firma) {
            zona.dataset.firma = firma;
            if (!subs.length) {
                zona.innerHTML = `<span class="cinta-pista">${limpio(d.pista || '')}</span>`;
            } else {
                const flechas = subs.length > 1;
                zona.innerHTML = (flechas ? '<kbd class="cinta-tecla">←</kbd>' : '') + '<div class="cinta-subs__via"><div class="cinta-subs__fila">'
                    + subs.map((s) => `<span class="cinta-sub">${limpio(s.nombre)}<em>${Number(s.n) || 0}</em></span>`).join('')
                    + '</div></div>' + (flechas ? '<kbd class="cinta-tecla">→</kbd>' : '');
            }
        }
        const via = zona.querySelector('.cinta-subs__via');
        if (!via) return;
        const fila = via.firstElementChild;
        let elegido = null;
        Array.from(fila.children).forEach((x, n) => {
            const si = n + 1 === d.sub;
            x.classList.toggle('cinta-sub--si', si);
            if (si) elegido = x;
        });
        // si no caben todos, la fila se corre lo justo para dejar el elegido hacia el centro
        const sobra = fila.scrollWidth - via.clientWidth;
        let x = 0;
        if (sobra > 0 && elegido) x = Math.max(0, Math.min(sobra, elegido.offsetLeft + elegido.offsetWidth / 2 - via.clientWidth / 2));
        fila.style.transform = `translateX(${-x}px)`;
    }

    // Las variantes de la herramienta que se lleva (las pasa la R): se ven
    // todas, con la que saldría marcada, antes de poner nada.
    function variantes(r, d) {
        const caja = r.querySelector('.cinta-vars');
        const lista = d.variantes || [];
        caja.hidden = !lista.length;
        if (!lista.length) return;
        caja.innerHTML = `<span class="cinta-vars__fila"><span class="cinta-vars__de"><kbd class="cinta-tecla">R</kbd><small>${limpio(d.variantesDe || 'Estilo')}</small></span>`
            + lista.map((v) => `<span class="cinta-var${v.on ? ' cinta-var--si' : ''}">${v.img ? `<img src="${limpio(v.img)}">` : ''}${limpio(v.nombre)}</span>`).join('') + '</span>';
    }

    // La ayuda (H): qué hace lo que se lleva, cómo se apunta y cómo se quita, y la chuleta de teclas
    function ayuda(r, a) {
        const caja = r.querySelector('.cinta-ayuda');
        caja.hidden = !a;
        if (!a) return;
        const iconos = ['fas fa-circle-info', 'fas fa-crosshairs', 'fas fa-eraser'];
        caja.innerHTML = `<header><i class="fas fa-circle-question"></i><b>${limpio(a.titulo)}</b><kbd class="cinta-tecla">H</kbd><span class="cinta-k">Cerrar</span></header>`
            + (a.lineas || []).map((l, n) => `<p><i class="${iconos[n] || 'fas fa-circle'}"></i><span>${limpio(l)}</span></p>`).join('')
            + '<div class="cinta-ayuda__teclas">' + (a.teclas || []).map((t) => `<span><kbd class="cinta-tecla">${limpio(t[0])}</kbd><span class="cinta-k">${limpio(t[1])}</span></span>`).join('') + '</div>';
    }

    function cinta(d) {
        const r = montar();
        if (!d.ver) { r.hidden = true; firmaCats = ''; buscar(r, null); return; }
        r.hidden = false;

        // Las categorías: una fila que se desliza para dejar la elegida a la vista.
        // Solo se rehace al cambiar de categoría (Q y E): si se rehiciera con
        // cada paso de rueda, la fila volvería a deslizarse desde el principio.
        const cats = d.categorias || [];
        const firma = cats.map((c) => c.nombre).join('|') + '#' + d.categoria;
        if (firma !== firmaCats) {
            const nueva = firmaCats.split('#')[0] !== firma.split('#')[0];
            firmaCats = firma;
            const caja = r.querySelector('.cinta-cats');
            if (nueva) {
                caja.innerHTML = '<kbd class="cinta-tecla">Q</kbd><div class="cinta-cats__via"><div class="cinta-cats__fila">'
                    + cats.map((c) => `<span class="cinta-cat"><i class="${limpio(c.icono || 'fas fa-couch')}"></i><span>${limpio(c.nombre)}</span></span>`).join('')
                    + '</div></div><kbd class="cinta-tecla">E</kbd>';
            }
            const via = caja.querySelector('.cinta-cats__via');
            const fila = via.firstElementChild;
            Array.from(fila.children).forEach((x, n) => x.classList.toggle('cinta-cat--si', n + 1 === d.categoria));
            // Se ven nueve pestañas enteras: la fila empieza siempre en el borde
            // de una, con la elegida hacia el centro.
            // de una, con la elegida hacia el centro. En proporción al ancho de
            // la fila y no en píxeles: así no se descuadra si cambia la pantalla.
            const primera = Math.max(0, Math.min(d.categoria - 5, cats.length - 9));
            fila.style.transform = `translateX(calc((100% + var(--hueco)) / 9 * ${-primera}))`;
        }

        subgrupos(r, d);
        buscar(r, d.busca);
        variantes(r, d);
        ayuda(r, d.ayuda);

        // Las cosas: la elegida en el centro, más grande y con su nombre encima
        const hay = (d.cosas || []).some((c) => c && !c.hueco);
        r.classList.toggle('cinta--vacia', !hay);
        const elegida = cats[d.categoria - 1] || {};
        r.querySelector('.cinta-cosas').innerHTML = !hay
            ? `<span class="cinta-vacio"><i class="${limpio(elegida.icono || 'fas fa-couch')}"></i><span>${limpio((d.busca && d.busca.activo) ? (String(d.busca.texto || '').trim().length < 2 ? 'Escribe al menos dos letras' : 'Nada con ese nombre') : (d.pista || 'Aquí no hay nada todavía'))}</span></span>`
            : (d.cosas || []).map((c) => {
            if (c.hueco) return '<span class="cinta-cosa cinta-cosa--hueco"></span>';
            const dentro = c.img ? `<img src="${limpio(c.img)}" onerror="this.src='./img/default.png'">` : `<i class="${limpio(c.icono || 'fas fa-cube')}"></i>`;
            const precio = c.precio ? `<b class="cinta-precio">${dinero(c.precio)}</b>` : '';
            // cada cosa lleva su nombre debajo (antes solo lo decía la elegida)
            const rotulo = `<span class="cinta-rot">${limpio(c.on ? d.nombre : (c.nombre || ''))}</span>`;
            return `<span class="cinta-cosa${c.on ? ' cinta-cosa--si' : ''}${c.img && !c.precio ? ' cinta-cosa--llena' : ''}"><span class="cinta-cosa__foto">${dentro}${precio}</span>${rotulo}</span>`;
        }).join('');

        // La ficha de la izquierda: lo que se lleva, en grande
        const actual = (d.cosas || []).find((c) => c && c.on) || {};
        const dibujo = actual.img ? `<img src="${limpio(actual.img)}" onerror="this.src='./img/default.png'">` : `<i class="${limpio(actual.icono || elegida.icono || 'fas fa-cube')}"></i>`;
        r.querySelector('.cinta-ficha__cab').innerHTML = `<span class="cinta-ficha__ico">${dibujo}</span><span class="cinta-ficha__tit"><b>${limpio(d.nombre)}</b>`
            + `<span class="cinta-ficha__datos">${d.favorito ? '<i class="fas fa-heart"></i>' : ''}${d.precio ? `<u>${dinero(d.precio)}</u>` : ''}${d.cuenta ? `<em>${limpio(d.cuenta)}</em>` : ''}</span></span>`;
        r.querySelector('.cinta-ficha__desc').textContent = hay ? (d.desc || '') : (d.pista || '');
        r.querySelector('.cinta-ficha__extra').innerHTML = '';

        const pie = r.querySelector('.cinta-pie');
        pie.innerHTML = '<div class="cinta-pie__via"><div class="cinta-pie__teclas">'
            + (d.teclas || []).map((t) => `<span class="cinta-tramo"><kbd class="cinta-tecla">${limpio(t.key)}</kbd><span class="cinta-k">${limpio(t.text)}</span></span>`).join('')
            + `</div></div><span class="cinta-dato"><small>Gastado</small><b>${dinero(d.gastado)}</b></span>`;
        encoger();
    }

    // Si las teclas (o los estilos de la R) no caben en su línea se encogen lo
    // justo: lo gastado no se sale del marco. Se repite cuando acaban de llegar
    // las tipografías: la primera vez que se abre la cinta aún se mide con la
    // letra de reserva, que es más ancha, y las teclas se quedaban diminutas
    // hasta el siguiente cambio. (packs.js lo llama también al añadir sus cifras.)
    function encoger() {
        if (!raiz || raiz.hidden) return;
        const via = raiz.querySelector('.cinta-pie__via');
        const teclas = via && via.firstElementChild;
        if (teclas) {
            teclas.style.zoom = '';
            const hueco = via.clientWidth;
            if (teclas.offsetWidth > hueco && hueco > 0) teclas.style.zoom = (hueco - 2) / teclas.offsetWidth;     // (2 px de holgura: el redondeo se comía la última letra)
        }
        const caja = raiz.querySelector('.cinta-vars');
        const fila = caja && !caja.hidden && caja.firstElementChild;
        if (fila) {
            fila.style.zoom = '';
            if (fila.offsetWidth > caja.clientWidth && caja.clientWidth > 0) fila.style.zoom = caja.clientWidth / fila.offsetWidth;
        }
    }
    window.OgnCintaEncoger = encoger;
    if (document.fonts) {
        if (document.fonts.addEventListener) document.fonts.addEventListener('loadingdone', encoger);
        if (document.fonts.ready && document.fonts.ready.then) document.fonts.ready.then(encoger);
    }

    // La pestaña Construir del menú Decorar (index.html): el cliente dice al
    // abrir el menú si la casa es de modalidad libre y con qué se construye.
    //   { action: 'obraMenu', menu: { herramientas, materiales } | null }
    function menu(d) {
        if (typeof app === 'undefined' || !app.furniture) return;
        app.furniture.obra = d.menu || null;
        if (!d.menu && app.furniture.selectedOption === 'obra') app.furniture.selectedOption = 'all';
    }

    window.addEventListener('message', (e) => {
        if (!e.data) return;
        if (e.data.action === 'cinta') cinta(e.data);
        else if (e.data.action === 'obraMenu') menu(e.data);
    });
})();
