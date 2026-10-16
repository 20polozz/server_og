/* ── Estado vital y parte medico ───────────────────────────────────────────

   Dos pantallas en una sola aplicacion de Vue 2:

     · #death-container   la columna de inconsciente, la que ves tu desde el
                          suelo. Tiene el raton puesto, asi que sus dos
                          acciones son botones de verdad.
     · #diagnosis-container  la ficha del paciente, la que abre un sanitario.

   El aguante de [G] se cuenta AQUI y no en Lua. Con el raton en la interfaz el
   juego ya no recibe las teclas, asi que `IsControlPressed` no se enteraba de
   nada; ademas asi el mismo contador vale para la tecla y para el boton. */
const RECURSO = (typeof GetParentResourceName !== 'undefined')
    ? GetParentResourceName()
    : 'origen_ambulancejob';

const AGUANTE_MS = 5000; // lo que hay que mantener [G] para reaparecer

/* Donde cae cada hueso en la silueta, en % de la imagen (img/silueta.webp,
   la misma del inventario, 533x800).

   El muñeco esta DE FRENTE, asi que tu lado derecho va a la izquierda del
   dibujo: es como se dibuja cualquier lamina de anatomia, y como lo ve el
   sanitario que se agacha a mirarte.

   Las claves son los `id` de data/body_parts.lua. Si alguna vez se añade un
   hueso alli y no aqui, esa lesion sale en la lista pero no en el dibujo: se
   pierde el punto, no la informacion. */
const ZONAS = {
    head:      [50, 7.5],
    neck:      [50, 14],
    shoulder:  [50, 18],
    rclavicle: [40, 17],
    lclavicle: [60, 17],
    ubdy:      [50, 24],
    lbdy:      [50, 35],
    '5lumbar': [50, 41],
    hip:       [50, 48],
    ruparm:    [32, 27],
    luparm:    [68, 27],
    rforearm:  [28.5, 40],
    lforearm:  [71.5, 40],
    rhand:     [26.5, 51],
    lhand:     [73.5, 51],
    rthigh:    [41.5, 59],
    lthigh:    [58.5, 59],
    rleg:      [40, 77.5],
    lleg:      [60, 77.5],
    rfoot:     [37, 93.5],
    lfoot:     [63, 93.5],
};

// El registro se corta solo por arriba cuando no cabe (ver style.css), pero
// no tiene sentido guardar mas de lo que puede llegar a verse.
const REGISTRO_MAX = 6;

// Las lesiones con ficha en la lista. Las demas siguen marcadas en la silueta.
const LESIONES_LISTA = 3;

// Lo que cabe en la nota que viaja con el aviso. Lua vuelve a cortarla.
const NOTA_MAX = 120;

/* El botiquin del sanitario: lo que se enseña y de que color va el cuadrito.
   Los nombres son los objetos de verdad (ver !INSTALLATION/items.lua); el
   recuento llega de Lua en `kit`. */
const BOTIQUIN = [
    { item: 'defibrillator', label: 'Desfibrilador', color: '#d81b55' },
    { item: 'bandage',       label: 'Vendas',        color: '#1f8f4e' },
    { item: 'icepack',       label: 'Hielo',         color: '#3d8bd9' },
    { item: 'suturekit',     label: 'Sutura',        color: '#d98700' },
    { item: 'tweezers',      label: 'Pinzas',        color: '#7a48ff' },
    { item: 'burncream',     label: 'Crema',         color: '#c9a227' },
];

// Apuntes que se guardan por paciente en "Lo que has hecho".
const HISTORIAL_MAX = 4;

// Lo que tarda en poder pedirse otro refuerzo. Lua lo vuelve a comprobar.
const REFUERZO_SEG = 60;

/* Las marcas de una silueta: crecen y cambian de color con la gravedad, asi
   que se ve donde esta lo gordo antes de leer un solo numero. La usan las dos
   pantallas. */
function marcasDe(lista, seleccion) {
    return lista
        .filter(l => ZONAS[l.bone])
        .map(l => {
            const [x, y] = ZONAS[l.bone];
            const v = Math.max(0, Math.min(100, l.value || 0));
            const on = l.bone === seleccion;
            const lado = Math.round(12 + (v / 100) * 10) + (on ? 6 : 0);
            return {
                bone: l.bone,
                estilo: {
                    left: x + '%',
                    top: y + '%',
                    width: lado + 'px',
                    height: lado + 'px',
                    background: v >= 80 ? '#d81b55' : v >= 40 ? '#d98700' : '#c9a227',
                    boxShadow: on ? '0 0 0 5px rgba(216, 27, 85, 0.28)' : '0 0 0 3px rgba(255, 255, 255, 0.8)'
                }
            };
        });
}

function horaDeAhora() {
    const d = new Date();
    return String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
}

/* La columna va en px, como el inventario, y con el registro recogido al
   minimo necesita 1004 px de alto contando los margenes. Por debajo de eso
   encoge entera (zoom) en vez de cortarse por abajo. */
const ALTO_COLUMNA = 1004;

function ajustarEscala() {
    const escala = Math.min(1, window.innerHeight / ALTO_COLUMNA);
    document.documentElement.style.setProperty('--v-zoom', escala.toFixed(3));
}

const app = new Vue({
    el: '#app',
    data() {
        return {
            // Pantalla de inconsciente
            visible: false,

            // La camara suelta con [V]: el raton pasa al juego, asi que el
            // panel se aparta y aqui solo queda el aviso de como volver.
            vistaLibre: false,
            // Apartado mientras el radial de origen_hud esta abierto.
            apartado: false,
            remainingSeconds: 0,
            totalSeconds: 1,
            canRespawn: false,
            callCooldown: 0,
            holdProgress: 0,
            holdSeconds: 0,

            // El parte del propio herido: que zonas lleva tocadas y de que se
            // esta muriendo. Llega junto al reloj desde modules/death.
            injuries: [],
            killedBy: '',

            // Lo que ha ido pasando desde que caiste, con la hora. No es
            // informacion nueva: son los mismos datos de arriba anotados en el
            // momento en que cambiaron.
            registro: [],

            // Lo que rodea a la muerte: cuanto llevas en el suelo, quien hay de
            // guardia y donde estas. Es lo que viaja en el aviso al 911.
            downSeconds: 0,
            medics: 0,
            distressSent: false,
            street: '',
            crossing: '',
            zone: '',
            coords: '',

            // La lesion que se mira: se elige en la silueta o en la lista.
            seleccion: null,

            // Lo que el herido quiere contarle al sanitario. Viaja con el aviso.
            nota: '',

            // Ficha del paciente (sanitario)
            diagnosisVisible: false,
            currentTab: 'summary',
            patient: {
                targetId: 0,
                name: 'Ciudadano',
                isDead: false,
                health: null,        // vida en % (100 = sano); null si Lua no la manda
                killedBy: '',
                injuries: [],
                hasDefibrillator: false,
                hasFirstAid: false,  // vendas o botiquin, lo que piden los primeros auxilios
                hasStretcher: false, // una camilla al lado: sin ella no hay traslado
                downSeconds: null,   // cuanto lleva en el suelo, si el herido lo cuenta
                note: '',            // lo que escribio el herido al pedir auxilio
                kit: {}              // { objeto: cantidad } del botiquin del sanitario
            },
            seleccionMedico: null,

            // "Lo que has hecho", por paciente. Cada accion cierra el panel, asi
            // que se ve al volver a abrirlo sobre el mismo.
            historial: {},

            refuerzoEspera: 0,
            _refuerzo: null,

            _aguante: null // temporizador del [G]; no se pinta
        };
    },
    computed: {
        formattedTime() {
            return this.reloj(this.remainingSeconds);
        },
        downTime() {
            return this.reloj(this.downSeconds);
        },
        progressPercentage() {
            if (!this.totalSeconds || this.totalSeconds <= 0) return 100;
            const rem = Math.max(0, this.remainingSeconds || 0);
            const pct = (1 - (rem / this.totalSeconds)) * 100;
            return Math.max(0, Math.min(100, pct));
        },
        /* La lista se corta a cuatro. Lo que no cabe SIGUE marcado en la
           silueta, asi que se pierde el detalle pero no el donde; y sin recorte
           las lesiones empujan los botones fuera de la columna, que es lo unico
           que no puede faltar. */
        injuriesShown() {
            return this.injuries.slice(0, LESIONES_LISTA);
        },
        injuriesExtra() {
            return Math.max(0, this.injuries.length - LESIONES_LISTA);
        },

        // La barra de la cuenta atras (una pieza): se vacia segun corre.
        respawnPct() {
            if (this.canRespawn || !this.totalSeconds) return 0;
            const rem = Math.max(0, this.remainingSeconds || 0);
            return Math.min(100, (rem / this.totalSeconds) * 100);
        },

        resumenParte() {
            const n = this.injuries.length;
            const cuantas = n ? (n + (n === 1 ? ' lesión' : ' lesiones')) : '';
            return [cuantas, this.killedBy].filter(Boolean).join(' · ');
        },

        textoAuxilio() {
            if (this.callCooldown > 0) return 'Aviso enviado · podrás repetirlo en ' + this.reloj(this.callCooldown);
            if (this.distressSent) return 'Pulsa para repetir el aviso';
            return 'Manda tu posición al servicio de emergencias';
        },

        registroAlReves() {
            return this.registro.slice().reverse();
        },

        // Los puntos de la silueta. Crecen y cambian de color con la gravedad,
        // asi que se ve donde esta lo gordo antes de leer un solo numero.
        marcasCuerpo() {
            return marcasDe(this.injuries, this.seleccion);
        },

        // ── Ficha del paciente ────────────────────────────────────────────
        marcasPaciente() {
            return marcasDe(this.patient.injuries, this.seleccionMedico);
        },

        lesionMedico() {
            return this.patient.injuries.find(l => l.bone === this.seleccionMedico) || null;
        },

        // Cuatro cifras de verdad: nada de saturacion ni tension, que el juego
        // no las tiene.
        cifrasMedico() {
            const p = this.patient;
            const graves = p.injuries.filter(l => (l.value || 0) >= 40).length;
            return [
                // La vida: sin ella, a quien le faltaba media barra y no tenia
                // lesiones apuntadas le salia «Estable» como a uno sano.
                p.isDead || p.health === null
                    ? { lbl: 'Pulso', valor: p.isDead ? '0' : 'SÍ', nota: p.isDead ? 'Sin ritmo' : 'Estable', tono: p.isDead ? 'bad' : 'good' }
                    : { lbl: 'Vida', valor: p.health + ' %', nota: this.notaVida, tono: p.health >= 100 ? 'good' : (p.health < 50 ? 'bad' : '') },
                { lbl: 'En el suelo', valor: (p.isDead && p.downSeconds !== null) ? this.reloj(p.downSeconds) : '—', nota: p.isDead ? 'Inconsciente' : 'De pie', tono: '' },
                { lbl: 'Lesiones', valor: String(p.injuries.length), nota: p.injuries.length ? 'Por tratar' : 'Ninguna', tono: p.injuries.length ? 'bad' : 'good' },
                { lbl: 'Graves', valor: String(graves), nota: 'Del 40 % arriba', tono: graves ? 'bad' : '' }
            ];
        },

        // «Estable» solo si de verdad lo esta; si no, cuanto le falta.
        notaVida() {
            const v = this.patient.health;
            if (v === null) return 'Estable';
            if (v >= 100) return 'Sano';
            if (v >= 75) return 'Herido leve';
            if (v >= 40) return 'Herido';
            return 'Grave';
        },

        estadoPaciente() {
            const p = this.patient;
            if (p.isDead) return 'Inconsciente';
            if (p.health !== null && p.health < 100) return this.notaVida + ' · ' + p.health + ' %';
            return 'Estable';
        },

        pacienteSano() {
            const p = this.patient;
            return !p.isDead && (p.health === null || p.health >= 100) && !p.injuries.length;
        },

        kitMedico() {
            const kit = this.patient.kit || {};
            const lista = BOTIQUIN.map(b => Object.assign({ count: kit[b.item] || 0 }, b));
            // El botiquin completo solo sale si se lleva: casi nadie lo tiene.
            if (kit.medikit) lista.push({ item: 'medikit', label: 'Botiquín', color: '#26221a', count: kit.medikit });
            return lista;
        },

        puedeTrasladar() {
            return this.patient.isDead && this.patient.hasStretcher;
        },

        historialPaciente() {
            return this.historial[this.patient.targetId] || [];
        },

        historialAlReves() {
            return this.historialPaciente.slice().reverse();
        }
    },
    methods: {
        reloj(segundos) {
            const s = Math.max(0, segundos || 0);
            const m = Math.floor(s / 60);
            return `${m.toString().padStart(2, '0')}:${(s % 60).toString().padStart(2, '0')}`;
        },

        postNUI(endpoint, data = {}) {
            return fetch(`https://${RECURSO}/${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            }).catch(() => {});
        },

        // ── Pantalla de inconsciente ──────────────────────────────────────
        aplicarMuerte(data) {
            if (data.remainingSeconds !== undefined) this.remainingSeconds = data.remainingSeconds;
            if (data.totalSeconds !== undefined) this.totalSeconds = data.totalSeconds;
            if (data.canRespawn !== undefined) this.canRespawn = data.canRespawn;
            if (data.callCooldown !== undefined) this.callCooldown = data.callCooldown;
            if (data.downSeconds !== undefined) this.downSeconds = data.downSeconds;
            if (data.medics !== undefined) this.medics = data.medics;
            if (data.distressSent !== undefined) this.distressSent = !!data.distressSent;
            if (data.street !== undefined) this.street = data.street || '';
            if (data.crossing !== undefined) this.crossing = data.crossing || '';
            if (data.zone !== undefined) this.zone = data.zone || '';
            if (data.coords !== undefined) this.coords = data.coords || '';
            // El parte solo viaja cuando cambia; el resto de avisos llegan sin
            // el y la lista se queda como esta.
            if (data.injuries !== undefined) this.injuries = Array.isArray(data.injuries) ? data.injuries : [];
            if (data.killedBy !== undefined) this.killedBy = data.killedBy || '';
        },

        // Un apunte al registro, con la hora que marca el reloj del suelo.
        // `tono` pinta la hora: 'hot' lo que te pasa, 'ok' la ayuda.
        apuntar(texto, tono) {
            this.registro.push({ hora: this.downTime, texto, hot: tono === 'hot', ok: tono === 'ok' });
            if (this.registro.length > REGISTRO_MAX) this.registro.shift();
        },

        pedirAuxilio() {
            if (this.callCooldown > 0) return;
            this.callCooldown = 60;
            this.distressSent = true; // el aviso se da por salido; Lua confirma
            this.postNUI('deathCall', { nota: (this.nota || '').trim().slice(0, NOTA_MAX) });
        },

        /* Mientras se escribe la nota, Lua le quita las teclas al juego: con
           KeepInput encendido cada letra saldria tambien por abajo. */
        escribiendo(activo) {
            this.postNUI('deathEscribiendo', { activo: !!activo });
        },

        soltarNota() {
            const campo = this.$refs.nota;
            if (campo && document.activeElement === campo) campo.blur();
        },

        // El aguante: se cuenta con un intervalo propio para que la barra suba
        // aunque el juego este parado esperando a que sueltes.
        empezarAguante() {
            if (!this.canRespawn || this._aguante) return;

            const arranque = Date.now();
            this._aguante = setInterval(() => {
                const llevado = Date.now() - arranque;
                this.holdProgress = Math.min(100, Math.floor((llevado / AGUANTE_MS) * 100));
                this.holdSeconds = Math.max(0, Math.ceil((AGUANTE_MS - llevado) / 1000));

                if (llevado >= AGUANTE_MS) {
                    this.soltarAguante();
                    this.postNUI('deathRespawn');
                }
            }, 50);
        },

        soltarAguante() {
            if (this._aguante) {
                clearInterval(this._aguante);
                this._aguante = null;
            }
            this.holdProgress = 0;
            this.holdSeconds = 0;
        },

        // ── Ficha del paciente ────────────────────────────────────────────
        closeDiagnosis() {
            this.diagnosisVisible = false;
            this.postNUI('closeDiagnosis');
        },

        tieneObjeto(item) {
            return ((this.patient.kit || {})[item || 'bandage'] || 0) > 0;
        },

        apuntarMedico(texto, tono) {
            const id = this.patient.targetId;
            const lista = (this.historial[id] || []).concat([{ hora: horaDeAhora(), texto, tono: tono || '' }]);
            this.$set(this.historial, id, lista.slice(-HISTORIAL_MAX));
        },

        triggerRevive() {
            if (!this.patient.isDead || !this.patient.hasDefibrillator) return;
            this.apuntarMedico('Reanimación con desfibrilador', 'ok');
            this.postNUI('revivePatient', { targetId: this.patient.targetId });
        },

        triggerTreat(injury) {
            if (!injury || !this.tieneObjeto(injury.requiredItem)) return;
            this.apuntarMedico('Tratada: ' + (injury.label || 'lesión') + ' con ' + (injury.itemLabel || 'venda'), 'ok');
            this.postNUI('treatInjury', {
                targetId: this.patient.targetId,
                bone: injury.bone,
                cause: injury.cause
            });
        },

        triggerHeal() {
            if (!this.patient.hasFirstAid) return;
            this.apuntarMedico('Primeros auxilios', 'ok');
            this.postNUI('healPatient', { targetId: this.patient.targetId });
        },

        triggerTransport() {
            if (!this.puedeTrasladar) return;
            this.apuntarMedico('Subido a la camilla');
            this.postNUI('transportPatient', { targetId: this.patient.targetId });
        },

        triggerBackup() {
            if (this.refuerzoEspera > 0) return;
            this.apuntarMedico('Refuerzo pedido al SAMS', 'hot');
            this.postNUI('requestBackup', { targetId: this.patient.targetId });

            this.refuerzoEspera = REFUERZO_SEG;
            clearInterval(this._refuerzo);
            this._refuerzo = setInterval(() => {
                this.refuerzoEspera = Math.max(0, this.refuerzoEspera - 1);
                if (!this.refuerzoEspera) clearInterval(this._refuerzo);
            }, 1000);
        },

        // La mas grave primero: es la que se mira y la que se trata antes.
        ordenarLesiones(lista) {
            return (Array.isArray(lista) ? lista.slice() : [])
                .sort((a, b) => (b.value || 0) - (a.value || 0));
        },

        // ── Mensajes del cliente de Lua ───────────────────────────────────
        handleMessage(event) {
            const data = event.data;
            if (!data) return;

            if (data.action === 'showDeath' || data.action === 'updateDeath') {
                const acabaDeCaer = !this.visible;
                this.visible = true;
                this.aplicarMuerte(data);
                if (acabaDeCaer) {
                    // La cámara arranca girando. Se dice aquí porque [V] se
                    // puede haber pulsado mientras caías, antes de que esta
                    // pantalla existiera: Lua la reinicia al montar la cámara y
                    // el panel tiene que salir de acuerdo con ella.
                    this.vistaLibre = false;
                    this.registro = [];
                    this.nota = '';
                    this.apuntar('Has perdido el conocimiento', 'hot');
                }
            } else if (data.action === 'deathApartar') {
                this.apartado = !!data.apartado;
                if (this.apartado) {
                    this.soltarAguante();
                    this.soltarNota();
                }
            } else if (data.action === 'deathCamera') {
                this.vistaLibre = !!data.free;
                // Lo que manda la camara manda tambien el apartado: si el
                // raton se solto con el radial abierto, el aviso de [V] tiene
                // que verse aunque el radial no llegue a decir que se cerro.
                this.apartado = false;
                // Sin foco no llega el keyup de [G]: el aguante se quedaria
                // corriendo solo y acabaria reapareciendote sin pedirlo.
                if (this.vistaLibre) {
                    this.soltarAguante();
                    this.soltarNota();
                }
            } else if (data.action === 'hideDeath') {
                this.soltarNota();
                this.apartado = false;
                this.visible = false;
                this.nota = '';
                this.seleccion = null;
                this.vistaLibre = false;
                this.soltarAguante();
                this.injuries = [];
                this.killedBy = '';
                this.distressSent = false;
                this.downSeconds = 0;
                this.registro = [];
            }

            else if (data.action === 'openDiagnosis') {
                this.patient.targetId = data.targetId || 0;
                this.patient.name = data.patientName || ('Ciudadano #' + (data.targetId || ''));
                this.patient.isDead = !!data.isDead;
                this.patient.health = (typeof data.health === 'number') ? Math.max(0, Math.min(100, Math.round(data.health))) : null;
                this.patient.killedBy = data.killedBy || '';
                this.patient.injuries = this.ordenarLesiones(data.injuries);
                this.patient.hasDefibrillator = !!data.hasDefibrillator;
                this.patient.hasFirstAid = !!data.hasFirstAid;
                this.patient.hasStretcher = !!data.hasStretcher;
                this.patient.downSeconds = (typeof data.downSeconds === 'number' && data.downSeconds >= 0) ? data.downSeconds : null;
                this.patient.note = typeof data.note === 'string' ? data.note.slice(0, NOTA_MAX) : '';
                this.patient.kit = (data.kit && typeof data.kit === 'object') ? data.kit : {};
                this.seleccionMedico = this.patient.injuries.length ? this.patient.injuries[0].bone : null;
                this.currentTab = 'summary';
                this.diagnosisVisible = true;
            } else if (data.action === 'updateDiagnosis') {
                if (data.isDead !== undefined) this.patient.isDead = !!data.isDead;
                if (data.injuries !== undefined) {
                    this.patient.injuries = this.ordenarLesiones(data.injuries);
                    if (!this.patient.injuries.some(l => l.bone === this.seleccionMedico)) {
                        this.seleccionMedico = this.patient.injuries.length ? this.patient.injuries[0].bone : null;
                    }
                }
                if (data.hasDefibrillator !== undefined) this.patient.hasDefibrillator = !!data.hasDefibrillator;
            } else if (data.action === 'closeDiagnosis') {
                this.diagnosisVisible = false;
            }
        },

        // ── Teclado ───────────────────────────────────────────────────────
        handleKeyDown(e) {
            if (this.diagnosisVisible) {
                if (e.key === 'Escape') return this.closeDiagnosis();
                if (e.repeat) return;
                const t = (e.key || '').toLowerCase();
                if (t === 'h') return this.triggerTransport();
                if (t === 'r') return this.triggerBackup();
                return;
            }

            if (!this.visible || e.repeat) return;

            // Escribiendo la nota, las letras son letras y no atajos.
            if (e.target && e.target.tagName === 'INPUT') return;

            const tecla = (e.key || '').toLowerCase();
            if (tecla === 'e') this.pedirAuxilio();
            if (tecla === 'g') this.empezarAguante();
            // Junto al medico del hospital: que te atienda (Lua mira si esta cerca).
            if (tecla === 'h') this.postNUI('deathParamedico');

            /* [V] la escuchan a la vez el juego y la interfaz: con el raton
               puesto aqui no siempre llega abajo, y para volver de la vista
               libre esta pantalla ya no tiene teclado. Lua descarta la segunda
               si llegan las dos. */
            if (tecla === 'v') this.postNUI('deathFreeCam');
        },

        handleKeyUp(e) {
            if (!this.visible) return;
            if ((e.key || '').toLowerCase() === 'g') this.soltarAguante();
        }
    },
    /* El registro se escribe solo, mirando lo que ya llega. Asi no hay que
       acordarse de anotar en cada sitio que cambia algo, que es como se acaba
       con la mitad de los sucesos sin registrar. */
    watch: {
        distressSent(ahora, antes) {
            if (ahora && !antes) this.apuntar('Aviso enviado al servicio de emergencias', 'ok');
        },

        canRespawn(ahora, antes) {
            if (ahora && !antes && this.visible) this.apuntar('Ya puedes reaparecer en el hospital');
        },

        medics(ahora, antes) {
            if (!this.visible) return;
            if (ahora > 0 && antes === 0) this.apuntar('Hay sanitarios de guardia', 'ok');
            if (ahora === 0 && antes > 0) this.apuntar('No queda ningún sanitario de guardia', 'hot');
        },

        injuries(ahora, antes) {
            // La seleccion sigue a la lista: si la que se miraba ya no esta, la
            // primera, que es la mas grave.
            if (!ahora.some(l => l.bone === this.seleccion)) {
                this.seleccion = ahora.length ? ahora[0].bone : null;
            }

            if (!this.visible || !antes) return;

            const conocidas = new Set(antes.map(l => l.bone));
            const nuevas = ahora.filter(l => !conocidas.has(l.bone));
            if (!nuevas.length) return;

            /* Una linea por tanda y no una por hueso: las lesiones del golpe
               que te tumba llegan todas a la vez, y cuatro apuntes con la misma
               hora barren del registro todo lo demas. El detalle esta en la
               pestaña del parte, que es donde se va a buscar. */
            this.apuntar(nuevas.length === 1
                ? 'Lesión localizada: ' + (nuevas[0].label || 'zona sin identificar')
                : 'Localizadas ' + nuevas.length + ' lesiones nuevas', 'hot');
        }
    },
    mounted() {
        window.addEventListener('message', this.handleMessage);
        window.addEventListener('keydown', this.handleKeyDown);
        window.addEventListener('keyup', this.handleKeyUp);
        window.addEventListener('resize', ajustarEscala);
        ajustarEscala();
    },
    beforeDestroy() {
        window.removeEventListener('message', this.handleMessage);
        window.removeEventListener('keydown', this.handleKeyDown);
        window.removeEventListener('keyup', this.handleKeyUp);
        this.soltarAguante();
    }
});
