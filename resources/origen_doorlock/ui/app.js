function fetch(event, data) {
    return $.post('https://origen_doorlock/' + event, JSON.stringify(data)).promise();
}

function TriggerCallback(event, data) {
    data.trigger = event;
    return $.post('https://origen_doorlock/TriggerCallback', JSON.stringify(data)).promise();
}

let app = new Vue({
    el: '#app',
    data() {
        return {
            visible: true,
            // origen o nacion: lo pone el trozo «ORIGEN · marca» del index.html.
            marca: document.documentElement.dataset.marca || 'origen',
            modals: [],
            currentModal: null,
            translations: [],
            door: false,
            doorsPanel: {
                visible: false,
                doors: {
                    ['342']: {
                        name: 'Puerta de la casa',
                        type: 'normal',
                        state: 1,
                    },
                }
            },
            search: {
                value: '',
            },
            creation: {
                id: null,
                visible: false,
                name: '',
                distance: 1.5,
                rate: 1.0,
                autolock: 0,
                double: false,
                locked: false,
                lockpick: false,
                automatic: false,
                passcode: '',
                passcodeInput: '',
                group: {
                    enabled: false,
                    manual: false,
                    name: '',
                    grade: 0,
                },
                player: {
                    enabled: false,
                    identifier: '',
                },
                groups: [],
                players: [],
            },
            doorSelection: {
                active: false,
                validTarget: false,
                isDouble: false,
                firstSelected: false,
            },
            availableGroups: {
                jobs: {},
                gangs: {},
                businesses: {}
            },
            // Lo que se escribe para filtrar la lista de grupos del servidor.
            groupSearch: '',
            /* Que puerta se va a borrar. Antes se borraba a la primera
               pulsacion y sin preguntar. */
            borrando: null,
        }
    },

    computed: {
        nombreDeMarca: function () {
            return this.marca === 'nacion' ? 'Nación' : 'Origen';
        },

        // La rejilla se pinta desde aqui y no con v-for + v-if a la vez: asi
        // el recuento de abajo y el de la cabecera salen de la misma lista.
        visibleDoors: function () {
            const doors = this.doorsPanel.doors || {};
            const out = [];

            for (const key in doors) {
                const item = doors[key];
                if (!item) continue;
                if (!this.isMatchingSearch(item)) continue;
                out.push({ key: key, item: item });
            }

            return out;
        },

        tally: function () {
            const doors = this.doorsPanel.doors || {};
            let total = 0, open = 0, closed = 0;

            for (const key in doors) {
                const item = doors[key];
                if (!item) continue;
                total++;
                if (item.state == 0) { open++; } else { closed++; }
            }

            return { total: total, open: open, closed: closed };
        },

        /* Los trabajos, los negocios y las bandas, todos en una lista. El
           servidor los manda en tres sacos distintos, pero al elegir uno da
           igual de cual venga: lo que importa es encontrarlo escribiendo. */
        gruposDisponibles: function () {
            const salida = [];
            const sacos = [
                { clave: 'jobs', categoria: 'Trabajo' },
                { clave: 'businesses', categoria: 'Negocio' },
                { clave: 'gangs', categoria: 'Banda' },
            ];

            for (const saco of sacos) {
                const tabla = this.availableGroups[saco.clave] || {};
                for (const key in tabla) {
                    salida.push({ key: key, label: tabla[key], categoria: saco.categoria });
                }
            }

            return salida;
        },

        gruposFiltrados: function () {
            const q = String(this.groupSearch || '').toLowerCase().trim();
            if (!q) return this.gruposDisponibles;

            return this.gruposDisponibles.filter(function (g) {
                return String(g.key).toLowerCase().includes(q)
                    || String(g.label).toLowerCase().includes(q);
            });
        },

        // En las dobles hay que decir por cual va, o no se sabe si ha
        // registrado la primera.
        pickKicker: function () {
            if (!this.doorSelection.isDouble) return 'Selección de puerta';
            return this.doorSelection.firstSelected ? 'Puerta 2 de 2' : 'Puerta 1 de 2';
        },

        pickTitle: function () {
            if (this.doorSelection.isDouble && this.doorSelection.firstSelected) {
                return 'Selecciona la segunda puerta';
            }
            return 'Selecciona la puerta';
        },
    },

    methods: {
        /* Dos datos de la ficha de una puerta (solo se pintan en Origen, con
           la pegatina). Solo leen: no cambian nada de la puerta. */
        cierreDe: function (item) {
            const data = (item && item.data) || item || {};
            const s = Number(data.autolock || 0);
            return s > 0 ? s + ' s' : 'No';
        },

        accesoDe: function (item) {
            const data = (item && item.data) || item || {};
            const partes = [];
            const grupos = Object.keys(data.groups || {}).length;
            const personas = Object.keys(data.players || {}).length;
            if (grupos) partes.push(grupos + (grupos === 1 ? ' grupo' : ' grupos'));
            if (personas) partes.push(personas + (personas === 1 ? ' persona' : ' personas'));
            if (data.passcode) partes.push('código');
            return partes.length ? partes.join(' · ') : 'Sin asignar';
        },

        togglePanelMenu: function (state) {
            if (state) {

                fetch('getDoors', {}).then((data) => {
                    this.doorsPanel.doors = normalizarPuertas(data);
                    this.doorsPanel.visible = true;
                });

                // El servidor solo da los grupos a un admin, y al cargar la
                // pagina todavia no se sabe si lo es: se piden al abrir.
                TriggerCallback('origen_doorlock:server:getAvailableGroups', {}).then((data) => {
                    if (data) app.availableGroups = data;
                });
            } else {
                this.doorsPanel.visible = false;
                fetch('closeMenu').then((data) => { });
            }
        },

        editDoor: function (id) {
            let door = this.doorsPanel.doors[id];
            if (!door) return;

            let data = door.data || door;

            // Rellenar formulario con datos existentes
            this.creation.id = id;
            this.creation.name = door.name || data.name;
            this.creation.distance = data.maxDistance || 1.5;
            this.creation.rate = Number(data.rate || 1.0);
            this.creation.autolock = data.autolock || 0;
            this.creation.double = door.type == 'double' || data.type == 'double';
            this.creation.locked = data.locked == 1 || data.locked == true;
            this.creation.lockpick = data.lockpick == 1 || data.lockpick == true;
            this.creation.automatic = data.automatic || false;
            this.creation.passcodeInput = data.passcode || '';
            this.creation.passcode = !!data.passcode;

            // Reconstruir grupos para la UI
            this.creation.groups = [];
            if (data.groups) {
                for (let name in data.groups) {
                    this.creation.groups.push({
                        name: name,
                        grade: data.groups[name]
                    });
                }
            }
            this.creation.group.enabled = this.creation.groups.length > 0;

            // Reconstruir jugadores para la UI
            this.creation.players = [];
            if (data.players) {
                for (let identifier in data.players) {
                    this.creation.players.push({
                        identifier: identifier
                    });
                }
            }
            this.creation.player.enabled = this.creation.players.length > 0;

            this.creation.visible = true;
        },

        yaTieneGrupo: function (name) {
            return this.creation.groups.some(function (item) { return item.name == name; });
        },

        // Anadir uno de la lista: entra con rango 0, que luego se cambia en la
        // propia fila.
        addGroupByName: function (name) {
            if (!name || this.yaTieneGrupo(name)) return;
            this.creation.groups.push({ name: name, grade: 0 });
        },

        pedirBorrar: function (door) {
            this.borrando = door;
        },

        confirmarBorrar: function () {
            const door = this.borrando;
            this.borrando = null;
            if (door) this.deleteDoor(door.key);
        },

        markPosition: function (id) {
            id = parseInt(id);
            fetch('markPosition', { id: id }).then((data) => { });
        },

        deleteDoor: function (id) {
            id = parseInt(id);
            TriggerCallback('origen_doorlock:server:deleteDoor', { doorID: id }).then((data) => { });
            this.$delete(this.doorsPanel.doors, id);
        },

        createDoor: function () {
            this.creation.id = null;
            this.creation.name = '';
            this.creation.distance = 1.5;
            this.creation.rate = 1.0;
            this.creation.autolock = 0;
            this.creation.double = false;
            this.creation.locked = false;
            this.creation.lockpick = false;
            this.creation.automatic = false;
            this.creation.passcode = false;
            this.creation.passcodeInput = '';
            this.creation.groups = [];
            this.creation.players = [];
            this.creation.group.enabled = false;
            this.creation.group.name = '';
            this.creation.player.enabled = false;
            this.groupSearch = '';

            this.creation.visible = true;
        },

        addGroup: function (type) {
            if (type == 'group') {
                const name = this.creation.group.name;
                const grade = this.creation.group.grade;
                if (!name) return;

                if (this.creation.groups.find(item => item.name == name)) {
                    return;
                }

                this.creation.groups.push({
                    name: name,
                    grade: grade,
                });

                // El campo se vacia solo: si no, hay que borrarlo a mano para
                // escribir el siguiente.
                this.creation.group.name = '';
            } else if (type == 'player') {
                let identifier = this.creation.player.identifier;
                if (!identifier) return;

                TriggerCallback('origen_doorlock:server:getPlayerIdentifier', { playerTarget: identifier }).then((data) => {
                    if (data) {
                        identifier = data
                        if (app.creation.players.find(item => item.identifier == identifier)) {
                            return;
                        }

                        app.creation.players.push({
                            identifier: identifier,
                        });
                    }
                });

            }
        },

        removeGroup: function (name, type) {
            if (type == 'group') {
                const index = this.creation.groups.findIndex(item => item.name == name);
                if (index == -1) return;
                this.creation.groups.splice(index, 1);
            } else if (type == 'player') {
                const index = this.creation.players.findIndex(item => item.identifier == name);
                if (index == -1) return;
                this.creation.players.splice(index, 1);
            }
        },

        isMatchingSearch: function (item) {
            if (this.search.value == '') {
                return true
            }
            // Alguna puerta puede llegar sin nombre; sin esto la busqueda
            // revienta y la rejilla se queda en blanco.
            return String(item.name || '').toLowerCase().includes(this.search.value.toLowerCase())
        },

        closeModal: function () {
            this.creation.visible = false;
        },

        saveDoor: function () {

            if (!this.creation.name || this.creation.name == '') {
                return;
            }

            // Cerrar el modal
            this.creation.visible = false;

            // ── MODO EDICIÓN: solo actualizar datos, sin seleccionar puerta ──
            if (this.creation.id) {
                fetch('updateDoor', {
                    id: this.creation.id,
                    name: this.creation.name,
                    distance: this.creation.distance,
                    rate: this.creation.rate,
                    autolock: this.creation.autolock,
                    locked: this.creation.locked,
                    lockpick: this.creation.lockpick,
                    automatic: this.creation.automatic,
                    passcode: this.creation.passcode ? this.creation.passcodeInput : null,
                    groups: this.creation.groups,
                    players: this.creation.players,
                }).then((data) => { });
                return;
            }

            // ── MODO CREACIÓN: cerrar panel y pedir selección de puerta ──
            this.doorsPanel.visible = false;

            fetch('createDoor', {
                id: null,
                name: this.creation.name,
                distance: this.creation.distance,
                rate: this.creation.rate,
                autolock: this.creation.autolock,
                locked: this.creation.locked,
                lockpick: this.creation.lockpick,
                automatic: this.creation.automatic,
                passcode: this.creation.passcode ? this.creation.passcodeInput : null,
                groups: this.creation.groups,
                double: this.creation.double,
                players: this.creation.players,
            }).then((data) => { });
        },
    }
});

$(function () {
    // La marca llega tarde si la convar se lee después de cargar la página.
    window.addEventListener('message', function (event) {
        const d = event.data;
        if (d && d.accion === 'origen:marca:puesta' && d.marca) app.marca = d.marca;
    });

    window.addEventListener('message', function (event) {
        var item = event.data;
        if (item.action == 'playSound') {
            playAudio(item);
        } else if (item.action == 'openMenu') {
            app.togglePanelMenu(item.state);
        } else if (item.action == 'updateDoors') {
            app.doorsPanel.doors = normalizarPuertas(item.doors);
        } else if (item.action == 'restoreCreationData') {
            // Restaurar los datos del formulario de creación
            app.creation.name = item.data.name || '';
            app.creation.distance = item.data.distance || 1.5;
            app.creation.rate = Number(item.data.rate || 1.0);
            app.creation.autolock = item.data.autolock || 0;
            app.creation.locked = item.data.locked || false;
            app.creation.lockpick = item.data.lockpick || false;
            app.creation.automatic = item.data.automatic || false;
            app.creation.double = item.data.double || false;
            app.creation.passcodeInput = item.data.passcode || '';
            app.creation.groups = item.data.groups || [];
            app.creation.players = item.data.players || [];

            // Abrir el modal de creación
            app.creation.visible = true;
        } else if (item.action == 'showDoorSelection') {
            app.doorSelection.active = true;
            app.doorSelection.isDouble = item.isDouble || false;
            app.doorSelection.firstSelected = item.firstSelected || false;
            app.doorSelection.validTarget = false;
        } else if (item.action == 'hideDoorSelection') {
            app.doorSelection.active = false;
            app.doorSelection.validTarget = false;
            app.doorSelection.firstSelected = false;
        } else if (item.action == 'updateDoorSelection') {
            app.doorSelection.validTarget = item.validTarget || false;
            app.doorSelection.firstSelected = item.firstSelected || false;
        }
    });
});

function playAudio(data) {
    let soundId = data.sound;
    let volume = data.volume || 0.2;

    const sound = new Audio('sounds/' + soundId + '.ogg');
    sound.volume = volume;
    sound.play();
}

$(document).on('keydown', this.handleKeydown);

/* Escape cierra lo de encima, no todo a la vez: antes cerraba el panel y el
   formulario de golpe, asi que al salir de un formulario te quedabas fuera. */
function handleKeydown(e) {
    if (e.keyCode !== 27) return;

    if (app.borrando) {
        app.borrando = null;
    } else if (app.creation.visible) {
        app.closeModal();
    } else {
        app.togglePanelMenu(false);
    }
}

$(document).ready(() => {
    fetch('getTraslations', {}).then((data) => {
        app.translations = data.translations;
    });

    TriggerCallback('origen_doorlock:server:getAvailableGroups', {}).then((data) => {
        if (data) {
            app.availableGroups = data;
        }
    });
});

// app.createDoor();

/* El servidor manda las puertas como {id, name, data} (la clase Door de
   server/door.lua), y si los ids van seguidos desde 1 la tabla llega como
   lista empezando en 0. Aquí se deja un objeto por id real, con los campos de
   data arriba (type, locked...) y el estado como lo lee la rejilla
   (state 0 = abierta). Se guarda data para editar. */
function normalizarPuertas(raw) {
    const out = {};
    if (!raw || typeof raw !== 'object') return out;

    for (const key in raw) {
        const door = raw[key];
        if (!door || typeof door !== 'object') continue;

        const data = (door.data && typeof door.data === 'object') ? door.data : door;
        const id = door.id != null ? door.id : key;
        const cerrada = data.locked == 1 || data.locked === true;

        out[id] = Object.assign({}, data, {
            id: id,
            name: door.name || data.name || ('Puerta ' + id),
            type: data.type || door.type || 'normal',
            state: cerrada ? 1 : 0,
            data: data,
        });
    }

    return out;
}
