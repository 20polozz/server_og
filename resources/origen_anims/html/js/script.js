/* Menu de animaciones. Vue 2 por CDN, sin compilar.

   Lo que se guarda y donde:
   · favoritas e historial, en localStorage (solo le importan a la NUI),
   · bucle, velocidad y bindeos, en el cliente (KVP): es Lua quien los
     aplica y quien escucha las teclas, asi que la NUI solo los pinta y
     avisa cuando cambian. Llegan con `setAjustes` al cargar. */

// Lo que hay que mantener pulsado «Borrar bindeos».
const BORRAR_MS = 1200;

/* De la tecla que da el navegador al codigo de tecla virtual de Windows, que
   es lo que leen los IsRawKey* del cliente. Para letras, cifras, teclado
   numerico y F1-F12 el keyCode del navegador ya ES ese codigo. */
function leerTecla(e) {
    const c = e.code || '';
    let etiqueta = null;

    if (/^Key[A-Z]$/.test(c)) etiqueta = c.slice(3);
    else if (/^Digit\d$/.test(c)) etiqueta = c.slice(5);
    else if (/^Numpad\d$/.test(c)) etiqueta = 'N' + c.slice(6);
    else if (/^F([1-9]|1[0-2])$/.test(c)) etiqueta = c;
    else if (c === 'Space') etiqueta = 'ESP';
    else if (/^Arrow/.test(c)) etiqueta = { ArrowUp: '↑', ArrowDown: '↓', ArrowLeft: '←', ArrowRight: '→' }[c];

    if (!etiqueta || !e.keyCode) return null;
    return { key: etiqueta, vk: e.keyCode };
}

/* Del 1 al 7 de arriba son los huecos del inventario (origen_inventory,
   client/commands.lua): con un bindeo ahi, se usaria el objeto a la vez que
   la animacion. Las del propio recurso (menu, parar, manos arriba...) las
   añade el cliente con `takenKeys`. */
const TECLAS_INVENTARIO = ['1', '2', '3', '4', '5', '6', '7'];

let app = new Vue({
    el: '#app',
    data: {
        visible: false,
        filters: {
            All: { id: 'Todas', icon: 'mdi:filter-variant' },
            Walks: { id: 'Caminar', icon: 'mdi:walk' },
            Scenarios: { id: 'Escenarios', icon: 'mdi:human-white-cane' },
            Expressions: { id: 'Expresiones', icon: 'mdi:face-man-shimmer' },
            Emotes: { id: 'Gestos', icon: 'mdi:human-greeting-variant' },
            PropEmotes: { id: 'Con objeto', icon: 'mdi:hiking' },
            ConsumableEmotes: { id: 'Consumibles', icon: 'mdi:food' },
            DanceEmotes: { id: 'Bailes', icon: 'mdi:dance-ballroom' },
            SynchronizedEmotes: { id: 'Pareja', icon: 'mdi:account-multiple' },
            AnimalEmotes: { id: 'Animales', icon: 'mdi:dog' },
        },
        views: ['Todas', 'Favoritas', 'Recientes'],
        speedOptions: [0.5, 1, 1.5],

        anims: {},
        porComando: {},
        selectedFilter: 'All',
        view: 'Todas',
        searchTerm: '',

        allFilteredAnims: [],
        displayedAnims: [],
        currentPage: 0,
        itemsPerPage: 50,

        favorites: [],
        history: [],

        // Lo que manda el cliente
        bindsOk: true,
        binds: [],
        loop: false,
        speed: 1,
        stopKey: 'X',
        takenKeys: [],
        now: null,         // { name, cmd } o null

        borrando: 0,        // de 0 a 1 mientras se mantiene «Borrar bindeos»
        pick: null,        // hueco que espera una animacion de la lista
        capture: null,      // hueco que espera una tecla
        aviso: '',
    },
    computed: {
        seccion() {
            if (this.view !== 'Todas') return this.view;
            const f = this.filters[this.selectedFilter];
            return f ? f.id : '';
        },
        totalAnims() {
            return this.allFilteredAnims.length;
        },
        totalTodas() {
            return Object.values(this.anims).reduce((n, l) => n + l.length, 0);
        },
        speedLabel() {
            return this.speed + 'x';
        },
        bindHint() {
            if (this.aviso) return this.aviso;
            if (this.capture !== null) return 'Pulsa una tecla · ESC cancela';
            if (this.pick !== null) return 'Elige una animación de la lista';
            return 'Clic en la tecla o en el hueco';
        },
        hayBinds() {
            return this.binds.some(b => b.cmd);
        },
    },
    watch: {
        selectedFilter() { this.updateFilteredAnims(true); },
        view() { this.updateFilteredAnims(true); },
        searchTerm() { this.updateFilteredAnims(true); },
    },
    methods: {
        // El nombre de la casa del pie del riel: «Nación» con la marca nacion.
        casaNombre() {
            return document.documentElement.dataset.marca === 'nacion' ? 'Nación' : 'Origen';
        },

        fetchEvent(event, data) {
            return fetch('https://origen_anims/' + event, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(data || {}),
            })
                .then(r => {
                    if (!r.ok) throw new Error('Network response was not ok');
                    return r.json();
                })
                .catch(err => console.error('[fetchEvent] Error in ' + event + ':', err));
        },

        closeMenu() {
            this.pick = null;
            this.cancelCapture();
            this.fetchEvent('close');
        },

        handleKeyDown(e) {
            if (this.capture !== null) {
                this.onCaptureKey(e);
                return;
            }
            // Alt solo en el navegador activa su "barra de menu" y la pagina
            // puede quedarse sin teclado; aqui no sirve para nada.
            if (e.key === 'Alt') { e.preventDefault(); return; }
            if (e.key !== 'Escape') return;
            // Que el Lua sepa que el Escape llega (si no, cierra el solo).
            this.fetchEvent('escVisto');
            // ESC deshace lo que este a medias antes de cerrar.
            if (this.pick !== null) { this.pick = null; return; }
            this.closeMenu();
        },

        handleKeyUp(e) {
            if (e.key === 'Alt') e.preventDefault();
        },

        /* Mientras el buscador tiene el foco, las teclas no pasan al juego. */
        handleMouse(state) {
            this.fetchEvent('toggleSearch', { state });
        },

        setFilter(key) {
            this.selectedFilter = key;
            if (this.$refs.lista) this.$refs.lista.scrollTop = 0;
        },

        setView(v) {
            this.view = v;
            if (this.$refs.lista) this.$refs.lista.scrollTop = 0;
        },

        /* ── Lista ───────────────────────────────────────────────── */
        loadAnimations(data) {
            const mapa = {};
            const anims = {};
            Object.keys(data || {}).forEach(cat => {
                anims[cat] = (data[cat] || []).filter(Boolean).map(a => {
                    const x = Object.assign({}, a, { _cat: cat });
                    mapa[x.Command] = x;
                    return x;
                });
            });
            this.anims = anims;
            this.porComando = mapa;
            this.updateFilteredAnims(true);
        },

        /* Favoritas e historial se guardan como {Command, Label}; aqui se
           cambian por la animacion de verdad, que trae su categoria y lo que
           haya cambiado desde que se guardaron. */
        resolver(lista) {
            return lista.map(a => this.porComando[a.Command]).filter(Boolean);
        },

        updateFilteredAnims(reset) {
            let out;
            if (this.view === 'Favoritas') out = this.resolver(this.favorites);
            else if (this.view === 'Recientes') out = this.resolver(this.history);
            else out = Object.values(this.anims).flat();

            if (this.selectedFilter !== 'All') out = out.filter(a => a._cat === this.selectedFilter);

            const q = this.searchTerm.trim().toLowerCase();
            if (q) {
                out = out.filter(a =>
                    (a.Label || '').toLowerCase().includes(q) ||
                    (a.Command || '').toLowerCase().includes(q));
            }

            this.allFilteredAnims = out;
            if (reset) {
                this.currentPage = 0;
                this.displayedAnims = [];
                this.loadMoreAnims();
            } else {
                // Sin volver arriba: una favorita quitada desaparece en su sitio.
                this.displayedAnims = out.slice(0, Math.max(this.currentPage, 1) * this.itemsPerPage);
            }
        },

        handleScroll(e) {
            const el = e.target;
            if (el.scrollHeight - el.scrollTop - el.clientHeight < 100) this.loadMoreAnims();
        },

        loadMoreAnims() {
            const start = this.currentPage * this.itemsPerPage;
            if (start >= this.allFilteredAnims.length) return;
            this.displayedAnims.push(...this.allFilteredAnims.slice(start, start + this.itemsPerPage));
            this.currentPage++;
        },

        /* ── Usar ────────────────────────────────────────────────── */
        playAnimation(anim) {
            if (this.pick !== null) {
                this.assignBind(this.pick, anim);
                return;
            }
            this.addToHistory(anim);
            this.fetchEvent('playAnimation', { anim: this.limpia(anim) });
        },

        previewAnimation(anim) {
            if (!anim.Dictionary) return;
            this.fetchEvent('previewAnimation', { anim: this.limpia(anim) });
            this.closeMenu();
        },

        stop() {
            this.fetchEvent('stop');
        },

        /* Sin la marca de categoria que se le pone al cargar: el cliente
           recibe la animacion tal cual se la mando. */
        limpia(anim) {
            const x = Object.assign({}, anim);
            delete x._cat;
            return x;
        },

        toggleLoop() {
            this.loop = !this.loop;
            this.fetchEvent('setLoop', { state: this.loop });
        },

        setSpeed(s) {
            this.speed = s;
            this.fetchEvent('setSpeed', { speed: s });
        },

        /* ── Favoritas e historial ───────────────────────────────── */
        isFavorite(anim) {
            return this.favorites.some(f => f.Command === anim.Command);
        },

        toggleFavorite(anim) {
            const i = this.favorites.findIndex(f => f.Command === anim.Command);
            if (i > -1) this.favorites.splice(i, 1);
            else this.favorites.push({ Command: anim.Command, Label: anim.Label });
            this.guardar('anim_favorites', this.favorites);
            if (this.view === 'Favoritas') this.updateFilteredAnims(false);
        },

        addToHistory(anim) {
            const resto = this.history.filter(h => h.Command !== anim.Command);
            this.history = [{ Command: anim.Command, Label: anim.Label }, ...resto].slice(0, 16);
            this.guardar('anim_history', this.history);
            if (this.view === 'Recientes') this.updateFilteredAnims(false);
        },

        guardar(clave, valor) {
            try { localStorage.setItem(clave, JSON.stringify(valor)); } catch (e) { /* sin sitio */ }
        },

        leer(clave, porDefecto) {
            try {
                const v = JSON.parse(localStorage.getItem(clave));
                return v == null ? porDefecto : v;
            } catch (e) {
                return porDefecto;
            }
        },

        /* ── Bindeos ─────────────────────────────────────────────── */
        bindAnim(i) {
            this.cancelCapture();
            this.pick = this.pick === i ? null : i;
        },

        bindKey(i) {
            this.pick = null;
            if (this.capture === i) { this.cancelCapture(); return; }
            this.aviso = '';
            this.capture = i;
            // Que la tecla que se pulse no la reciba tambien el juego.
            this.handleMouse(false);
        },

        cancelCapture() {
            if (this.capture === null) return;
            this.capture = null;
            this.handleMouse(true);
        },

        onCaptureKey(e) {
            e.preventDefault();
            if (e.key === 'Escape') { this.cancelCapture(); return; }

            const t = leerTecla(e);
            if (!t) return; // mayus, control... se espera a otra
            if (TECLAS_INVENTARIO.includes(t.key) || this.takenKeys.includes(t.key)) {
                this.aviso = 'La ' + t.key + ' ya está cogida · prueba otra';
                return;
            }

            const i = this.capture;
            // La que ya estuviera en otro hueco se queda sin tecla.
            this.binds = this.binds.map((b, j) => {
                if (j === i) return Object.assign({}, b, t);
                if (b.vk === t.vk) return Object.assign({}, b, { key: '—', vk: null });
                return b;
            });
            this.aviso = '';
            this.cancelCapture();
            this.saveBinds();
        },

        assignBind(i, anim) {
            this.$set(this.binds, i, Object.assign({}, this.binds[i], { cmd: anim.Command, label: anim.Label }));
            this.pick = null;
            this.saveBinds();
        },

        clearBind(i) {
            this.$set(this.binds, i, Object.assign({}, this.binds[i], { cmd: null, label: null }));
            this.pick = null;
            this.cancelCapture();
            this.saveBinds();
        },

        saveBinds() {
            this.fetchEvent('setBinds', { binds: this.binds });
        },

        /* Mantener para borrar: la barra se llena en BORRAR_MS y al llegar
           al final se vacian los seis huecos. Soltar antes no borra nada. Las
           teclas se quedan: lo que se borra es que animacion lleva cada una. */
        empezarBorrar() {
            if (!this.hayBinds || this.borrarTimer) return;
            this.pick = null;
            this.cancelCapture();
            const inicio = Date.now();
            // setInterval y no requestAnimationFrame: ese se congela con la
            // pagina oculta.
            this.borrarTimer = setInterval(() => {
                this.borrando = Math.min((Date.now() - inicio) / BORRAR_MS, 1);
                if (this.borrando < 1) return;
                this.soltarBorrar();
                this.binds = this.binds.map(b => Object.assign({}, b, { cmd: null, label: null }));
                this.saveBinds();
            }, 16);
        },

        soltarBorrar() {
            clearInterval(this.borrarTimer);
            this.borrarTimer = null;
            this.borrando = 0;
        },

        setAjustes(d) {
            this.bindsOk = d.bindsOk !== false;
            this.loop = !!d.loop;
            this.speed = Number(d.speed) || 1;
            if (d.stopKey) this.stopKey = String(d.stopKey).toUpperCase();
            this.takenKeys = (d.takenKeys || []).filter(Boolean).map(k => String(k).toUpperCase());
            // Lua manda los huecos vacios sin `cmd`; aqui se les da forma fija.
            this.binds = (d.binds || []).map(b => ({
                key: b.key || '—',
                vk: b.vk || null,
                cmd: b.cmd || null,
                label: b.label || null,
            }));
        },
    },
    mounted() {
        this.favorites = this.leer('anim_favorites', []).filter(f => f && f.Command);
        this.history = this.leer('anim_history', []).filter(h => h && h.Command);

        this.onMessage = (event) => {
            const item = event.data || {};
            switch (item.action) {
                case 'setVisible':
                    this.visible = item.state !== undefined ? !!item.state : !this.visible;
                    if (!this.visible) { this.pick = null; this.capture = null; this.aviso = ''; this.soltarBorrar(); }
                    break;
                case 'setAnimations':
                    this.loadAnimations(item.data);
                    break;
                case 'setAjustes':
                    this.setAjustes(item);
                    break;
                case 'setPlaying':
                    this.now = item.name ? { name: item.name, cmd: item.cmd } : null;
                    break;
            }
        };
        window.addEventListener('message', this.onMessage);
        window.addEventListener('keydown', this.handleKeyDown);
        window.addEventListener('keyup', this.handleKeyUp);

        this.fetchEvent('loadNui');
    },
    destroyed() {
        window.removeEventListener('message', this.onMessage);
        window.removeEventListener('keydown', this.handleKeyDown);
        window.removeEventListener('keyup', this.handleKeyUp);
    },
});

window.app = app;
