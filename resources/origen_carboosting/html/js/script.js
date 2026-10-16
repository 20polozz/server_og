const scroll = new Audio('./sounds/scroll.ogg');
const hover = new Audio('./sounds/hover.ogg');
const click = new Audio('./sounds/click.ogg');

scroll.volume = 0.1;
hover.volume = 0.05;
click.volume = 0.03;

const app = new Vue({
    el: '#app',
    data: function() {
        return {
            visible: false,
            lang: 'en',
            // La marca del servidor (origen o nacion): el nombre del riel de la gestion.
            marca: (window.__ognMarca && window.__ognMarca.de && window.__ognMarca.de()) || 'origen',
            translations: [],
            notifications: [],
            incomingContractPopup: {
                visible: false,
                contract: null,
                timeoutHandle: null,
                progressHandle: null,
                durationMs: 5000,
                startedAt: 0,
                remainingMs: 5000,
                lastTickAt: 0,
                progress: 100,
                mouseEnabled: false,
            },
            localTime: 0,
            serverInterval: null,
            isDragging: false,
            startX: 0,
            scrollLeft: 0,

            /*  El menu del jugador va en riel (07/10): `vista` es la seccion
                encendida de la barra y `ancho` si esta desplegado el panel
                grande. Vive en data y no se resetea al abrir: como el hub de
                carreras, la tablet se vuelve a abrir como se dejo. */
            riel: {
                vista: 'contratos',
                ancho: false,
            },
            /*  El riel COMPARTIDO (08/10): los menus de siempre —inventario,
                personaje, llaves…—, que manda Lua al abrir (de
                origen_inventory:GetRiel). Con el, las secciones van en las
                pestañas de la columna, como en el Racing Hub; vacio (sin
                inventario), las secciones vuelven a la barra. */
            rielCompartido: [],

            trackerUI: {
                visible: false,
                trackers: 0,
            },

            mainMenu: {
                visible: false,
                options: [
                    {
                        id: 'play',
                        icon: 'iconoir:play-solid',
                        action: function() {
                            app.navigateTo('mainBoosting');
                        }
                    },
                    {
                        id: 'ranking',
                        icon: 'solar:ranking-bold',
                        action: function() {
                            app.navigateTo('ranking');
                        }
                    },
                ],
                showHelp: null,
                messageHelp: null,
            },

            // Boosting
            mainBoosting: {
                transference: false,
                visible: false,
                profile: {
                    citizen: 0,
                    username: false,
                    image: '',
                    banner: '',
                    prestige: 0,
                    totalExperience: 0,
                    totalExperienceVehicle: 0,
                    totalExperienceProp: 0,
                    currentLevel: { rank: 'C', xp: 1000 },
                    nextLevel: { rank: 'D', requiredxp: 1000 },
                    currentLevelVehicle: { rank: 'C', xp: 1000 },
                    nextLevelVehicle: { rank: 'D', requiredxp: 1000 },
                    currentLevelProp: { rank: 'C', xp: 1000 },
                    nextLevelProp: { rank: 'D', requiredxp: 1000 },
                    coins: 0,
                },
                onDuty: false,
                contracts: [],
                savedContracts: [],
                contractHistory: [],
                boostingLeaderboard: []
            },

            market: {
                visible: false,
                list: []
            },

            createMenu: {
                visible: false,
                search: '',
                typeFilter: 'all',
                list: [],
                missionTemplates: [],
                spawnPoints: [],
                deliveryPoints: [],
                objectiveTypes: ['vehicle', 'prop'],

                categories: [],
                vehicleCategories: [],
                missionCategories: [],
                accessModes: ['public', 'gang_only', 'crew_only', 'specific_gang', 'specific_crew'],
                difficulty: [],
                weapons: [],
                vehicles: [],
                props: [],
                peds: [],
                minigames: [],
                minigameDifficulties: [],
                selects: {
                    vehicleOpen: false,
                    propOpen: false,
                    pedOpen: false,
                    npcWeaponOpen: false,
                    accessModeOpen: false,
                    minigameOpen: false,
                    minigameDifficultyOpen: false,
                    objectiveTypeOpen: false,
                    spawnPointOpen: false,
                    deliveryPointOpen: false,
                    vehicleQuery: '',
                    propQuery: '',
                    pedQuery: '',
                    npcWeaponQuery: '',
                    accessModeQuery: '',
                    minigameQuery: '',
                    minigameDifficultyQuery: '',
                    spawnPointQuery: '',
                    deliveryPointQuery: '',
                },
                difficultyIndex: 1,
                vinScratch: false,
                propRobable: true,
                propRequireDelivery: true,
                propLoseOnDeath: true,
                propLoseOnDisconnect: true,
                pointsEditor: {
                    visible: false,
                    selectedType: 'spawn',
                    selectedPointId: '',
                    name: '',
                    radius: 4,
                },
                newPointDialog: {
                    visible: false,
                    type: 'spawn',
                    name: '',
                }
            },

            ranking: {
                visible: false,
                search: '',
                // Por que se ordena la clasificacion (ver rankingCategorias).
                categoria: 'ogn',
                list: [],
            },

            modal: {
                id: null,
                waiting: false,
                currentData: null,
                editName: {
                    username: '',
                    restrictExit: false,
                },
                editProfile: {
                    image: '',
                    banner: '',
                },
                createContract: {
                    id: 0,
                    editing: false,
                    label: '',
                    category: 'C',
                    dificulty: 'Easy',
                    vehicle: '',
                    npcs: '',
                    npcWeapon: '',
                    minigame: '',
                    minigameDifficulty: 'auto',
                    missionType: 'vehicle',
                    objectiveType: 'vehicle',
                    objectiveModel: '',
                    propItemName: 'black_money',
                    propItemAmount: 1,
                    spawnPointId: '',
                    deliveryPointId: '',
                    pointEditorType: 'spawn',
                    accessMode: 'public',
                    requiredGang: '',
                    requiredCrew: '',
                    spawnRadius: '',
                    deliveryRadius: '',
                    stageRadius: '',
                    stageTimer: 0,
                    spawnPointLabel: '',
                    deliveryPointLabel: '',
                    description: '',
                    reward: '',
                    vin: '',
                    experience: '',
                    price: '',
                },
                sendContract: {
                    id: '',
                    price: '',
                },
                sendCoins: {
                    id: '',
                    amount: '',
                },
                adminGiveCoins: {
                    id: '',
                    amount: '',
                },
                sellContract: {
                    offerPrice: '',
                    target: '',
                },
                sellContractMarket: {
                    price: '',
                    duration: '',
                },
                deleteContract: {
                    id: 0,
                },
                buyContract: {
                    id: 0,
                },
                declineContract: {
                    id: 0,
                },
                selectedContract: null,
                settings: []
            },
            settingsViewType: 'vehicle',
        }
    },
    watch: {
        'modal.createContract.objectiveType': function(nextType) {
            if (!nextType) return;
            this.createMenu.selects.vehicleOpen = false;
            this.createMenu.selects.propOpen = false;
            this.createMenu.selects.pedOpen = false;
            this.createMenu.selects.objectiveTypeOpen = false;

            if (nextType === 'vehicle') {
                this.modal.createContract.objectiveModel = '';
                if (!this.modal.createContract.vehicle) {
                    this.modal.createContract.vehicle = this.createMenu.vehicles[0] || '';
                }
            } else if (nextType === 'prop') {
                this.modal.createContract.objectiveModel = this.createMenu.props[0] || '';
                this.createMenu.vinScratch = false;
                this.modal.createContract.vin = '';
                if (!this.modal.createContract.propItemName) {
                    this.modal.createContract.propItemName = 'black_money';
                }
                if (!(Number(this.modal.createContract.propItemAmount) > 0)) {
                    this.modal.createContract.propItemAmount = 1;
                }
            }
            const list = this.getCurrentCategoryList();
            if (list.length > 0 && !list.includes(this.modal.createContract.category)) {
                this.modal.createContract.category = list[0];
            }
        }
    },
    methods: {
        getRankProgress(missionType) {
            const isProp = missionType === 'prop';
            const profile = this.mainBoosting.profile || {};
            const totalXp = Number(isProp ? profile.totalExperienceProp : profile.totalExperienceVehicle) || 0;
            const currentLevel = isProp ? (profile.currentLevelProp || {}) : (profile.currentLevelVehicle || {});
            const nextLevel = isProp ? (profile.nextLevelProp || {}) : (profile.nextLevelVehicle || {});

            const currentFloor = Number(currentLevel.xp) || 0;
            const nextRequired = Number(nextLevel.requiredxp) || 0;
            const hasNextRank = nextRequired > currentFloor;

            const safeCurrentFloor = Math.max(0, currentFloor);
            const currentWithinRank = hasNextRank ? Math.max(0, totalXp - safeCurrentFloor) : Math.max(0, totalXp);
            const rankSpan = hasNextRank ? Math.max(1, nextRequired - safeCurrentFloor) : 1;
            const percent = hasNextRank
                ? Math.max(0, Math.min(100, Math.round((currentWithinRank / rankSpan) * 100)))
                : 100;
            const targetXp = hasNextRank ? nextRequired : Math.max(totalXp, safeCurrentFloor);
            const remainingXp = hasNextRank ? Math.max(0, nextRequired - totalXp) : 0;

            return {
                percent,
                currentXp: Math.max(0, totalXp),
                targetXp: Math.max(0, targetXp),
                remainingXp,
                nextRank: nextLevel.rank || null
            };
        },
        getMinigameLabel(minigameKey) {
            const labels = {
                StartLockpick: 'Ganzúa',
                StartHacking: 'Hackeo',
                StartCodeBreaker: 'Desbloqueo de Código',
                StartWirePuzzle: 'Puzzle de Cables',
                StartMinesweeper: 'Buscaminas',
                StartTimingCircles: 'Reflejos',
                StartVarHack: 'Interferencia',
                StartPowerGrid: 'Red Eléctrica',
            };
            return labels[minigameKey] || minigameKey;
        },
        getMinigameDifficultyLabel(difficultyKey) {
            const labels = {
                auto: 'Automático',
                easy: 'Fácil',
                medium: 'Media',
                hard: 'Difícil',
                extreme: 'Extrema',
            };
            return labels[difficultyKey] || difficultyKey;
        },
        getObjectiveTypeLabel(objectiveType) {
            const labels = {
                vehicle: 'Vehículo',
                prop: 'Prop',
            };
            return labels[objectiveType] || objectiveType;
        },
        getAccessModeLabel(accessMode) {
            const labels = {
                public: 'Quién puede aceptar: Todo el mundo',
                gang_only: 'Quién puede aceptar: Cualquier banda',
                crew_only: 'Quién puede aceptar: Cualquier crew',
                specific_gang: 'Quién puede aceptar: Solo una banda concreta',
                specific_crew: 'Quién puede aceptar: Solo una crew concreta',
            };
            return labels[accessMode] || accessMode;
        },
        isSelectOpen(type) {
            const map = {
                objectiveType: this.createMenu.selects.objectiveTypeOpen,
                vehicle: this.createMenu.selects.vehicleOpen,
                prop: this.createMenu.selects.propOpen,
                accessMode: this.createMenu.selects.accessModeOpen,
                npcWeapon: this.createMenu.selects.npcWeaponOpen,
                spawnPoint: this.createMenu.selects.spawnPointOpen,
                deliveryPoint: this.createMenu.selects.deliveryPointOpen,
                minigame: this.createMenu.selects.minigameOpen,
                minigameDifficulty: this.createMenu.selects.minigameDifficultyOpen,
            };
            if (Object.prototype.hasOwnProperty.call(this.createMenu.selects, `${type}Open`)) {
                return !!this.createMenu.selects[`${type}Open`];
            }
            return !!map[type];
        },
        getCurrentCategoryList() {
            if ((this.modal.createContract.objectiveType || 'vehicle') === 'vehicle') {
                return this.createMenu.vehicleCategories.length > 0 ? this.createMenu.vehicleCategories : this.createMenu.categories;
            }
            return this.createMenu.missionCategories;
        },
        fetchEvent: async function(event, data) {
            const resourceName = (typeof GetParentResourceName === 'function')
                ? GetParentResourceName()
                : 'origen_contracts';
            return fetch(`https://${resourceName}/${event}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(data)
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            });
        },

        triggerCallback: async function(name, data) {
            data.__name = name;
            return this.fetchEvent('TriggerCallback', data).then((response) => {
                return response;
            });
        },

        updateCategory(type) {
            const categories = this.getCurrentCategoryList();
            if (!categories || categories.length === 0) return;
            if (type === 'prev') {
                if (this.modal.createContract.category === categories[0]) {
                    this.modal.createContract.category = categories[categories.length - 1];
                } else {
                    this.modal.createContract.category = categories[categories.indexOf(this.modal.createContract.category) - 1];
                }
            } else if (type === 'next') {
                if (this.modal.createContract.category === categories[categories.length - 1]) {
                    this.modal.createContract.category = categories[0];
                } else {
                    this.modal.createContract.category = categories[categories.indexOf(this.modal.createContract.category) + 1];
                }
            }
        },

        refreshEditorPoints(autoSelectId, autoSelectKind) {
            this.triggerCallback('origen_missions:server:EditorGetPoints', {}).then((points) => {
                const normalizeList = (arr) => (arr || []).map((p) => ({
                    id: p.id,
                    name: p.name || '',
                    pointType: p.pointType || p.point_type || '',
                    coords: p.coords || { x: p.x, y: p.y, z: p.z, w: p.w || 0.0 },
                    radius: Number(p.radius || 4),
                    metadata: p.metadata || {}
                }));
                this.createMenu.spawnPoints = normalizeList(points.spawn || []);
                this.createMenu.deliveryPoints = normalizeList(points.delivery || []);
                this.createMenu.pointsEditor.selectedPointId = '';
                // Only auto-select when explicitly told to (after creating a new point)
                if (autoSelectId && autoSelectKind === 'spawn') {
                    this.modal.createContract.spawnPointId = String(autoSelectId);
                } else if (autoSelectId && autoSelectKind === 'delivery') {
                    this.modal.createContract.deliveryPointId = String(autoSelectId);
                }
            });
        },

        captureCurrentPositionForPoint() {
            this.fetchEvent('CapturePlayerPosition', {}).then((coords) => {
                if (!coords || coords.x === undefined) return;
                const type = this.modal.createContract.pointEditorType || 'spawn';
                const list = type === 'delivery' ? this.createMenu.deliveryPoints : this.createMenu.spawnPoints;
                const index = list.length + 1;
                this.createMenu.pointsEditor.name = `${type === 'delivery' ? 'ENTREGA' : (type === 'spawn' ? 'INICIO' : type.toUpperCase())} ${index}`;
                this.createMenu.pointsEditor._coords = coords;
            });
        },

        openNewPointDialog(kind) {
            this.createMenu.newPointDialog = { visible: true, type: kind, name: '' };
        },

        confirmNewPointDialog() {
            const name = (this.createMenu.newPointDialog.name || '').trim();
            if (!name) {
                this.sendNotification('error', this.t('notifications.error'), 'Escribe un nombre para el punto antes de colocarlo');
                return;
            }
            const kind = this.createMenu.newPointDialog.type;
            if (kind === 'spawn') {
                this.modal.createContract.spawnPointLabel = name;
            } else {
                this.modal.createContract.deliveryPointLabel = name;
            }
            this.createMenu.newPointDialog.visible = false;
            this.startInGamePointPlacement(kind);
        },

        startInGamePointPlacement(kind) {
            const isSpawn = kind === 'spawn';
            const objectiveType = this.modal.createContract.objectiveType || 'vehicle';
            if (objectiveType === 'vehicle' && !this.modal.createContract.vehicle) {
                this.sendNotification('error', this.t('notifications.error'), 'Primero selecciona el vehículo objetivo');
                return;
            }
            if (objectiveType === 'prop' && !this.modal.createContract.objectiveModel) {
                this.sendNotification('error', this.t('notifications.error'), 'Primero selecciona el modelo del objetivo');
                return;
            }
            const pointLabel = isSpawn ? this.modal.createContract.spawnPointLabel : this.modal.createContract.deliveryPointLabel;
            const cleanPointLabel = (pointLabel || '').trim();
            if (!cleanPointLabel) {
                this.sendNotification('error', this.t('notifications.error'), isSpawn
                    ? 'Pon un nombre para el punto de inicio antes de crearlo'
                    : 'Pon un nombre para el punto de entrega antes de crearlo');
                return;
            }
            const pointPool = isSpawn ? this.createMenu.spawnPoints : this.createMenu.deliveryPoints;
            const duplicated = (pointPool || []).find((point) => String(point.name || '').toLowerCase() === cleanPointLabel.toLowerCase());
            // If name already exists, warn but continue — user already confirmed the name via the dialog
            if (duplicated) {
                this.sendNotification('info', 'Nombre existente', `Se actualizará el punto "${cleanPointLabel}" con la nueva posición`);
            }
            const payload = {
                pointType: isSpawn ? 'spawn' : 'delivery',
                objectiveType,
                objectiveModel: objectiveType === 'vehicle'
                    ? (this.modal.createContract.vehicle || 'blista')
                    : (this.modal.createContract.objectiveModel || 'prop_box_wood01a'),
                radius: Number(isSpawn ? this.modal.createContract.spawnRadius : this.modal.createContract.deliveryRadius) || (isSpawn ? 6 : 12),
                name: cleanPointLabel,
                existingPointId: duplicated ? Number(duplicated.id || 0) : 0
            };
            const wasEditing = this.modal.createContract.editing;
            this.fetchEvent('StartPointPlacement', payload).then((result) => {
                // Reopen the contract modal (Lua closes modal.id on reopenCad)
                this.$nextTick(() => {
                    this.modal.id = 'create_contract';
                    this.modal.createContract.editing = wasEditing;
                });
                if (!result || !result.ok || !result.coords) return;
                this.createMenu.pointsEditor.name = payload.name;
                this.createMenu.pointsEditor.radius = Number(result.radius || payload.radius || 4);
                this.createMenu.pointsEditor._coords = result.coords;
                this.modal.createContract.pointEditorType = kind;
                this.createMenu.pointsEditor.selectedPointId = payload.existingPointId ? String(payload.existingPointId) : '';
                this.onCreatePoint(kind);
            });
        },

        onCreatePoint(autoSelectKind) {
            const coords = this.createMenu.pointsEditor._coords;
            if (!coords) {
                this.sendNotification('error', this.t('notifications.error'), 'Captura primero una posición');
                return;
            }
            // Clear immediately to prevent double-fire if called again before server responds
            this.createMenu.pointsEditor._coords = null;
            const pointType = this.modal.createContract.pointEditorType || 'spawn';
            const payload = {
                name: this.createMenu.pointsEditor.name || `Point ${Date.now()}`,
                pointType,
                coords: coords,
                radius: Number(this.createMenu.pointsEditor.radius) || 4
            };
            const existingPointId = Number(this.createMenu.pointsEditor.selectedPointId || 0);
            if (existingPointId > 0) {
                payload.id = existingPointId;
            }
            const isCreate = existingPointId === 0;
            const callbackName = isCreate
                ? 'origen_missions:server:EditorCreatePoint'
                : 'origen_missions:server:EditorUpdatePoint';
            this.triggerCallback(callbackName, payload).then((res) => {
                if (res && res.status) {
                    this.sendNotification('success', this.t('notifications.success'), isCreate ? 'Punto creado' : 'Punto actualizado');
                    this.createMenu.pointsEditor.selectedPointId = '';
                    // Determine which slot to auto-select after refreshing
                    const selectKind = autoSelectKind || pointType;
                    const selectId = isCreate ? res.id : existingPointId;
                    this.refreshEditorPoints(selectId, selectKind);
                    // If we came from point placement, assign to the correct field immediately
                    if (selectKind === 'spawn' && selectId) {
                        this.modal.createContract.spawnPointId = String(selectId);
                    } else if (selectKind === 'delivery' && selectId) {
                        this.modal.createContract.deliveryPointId = String(selectId);
                    }
                } else {
                    const msg = res && res.msg === 'duplicate_name'
                        ? 'Ya existe un punto con ese nombre para ese tipo'
                        : (isCreate ? 'No se pudo crear el punto' : 'No se pudo actualizar el punto');
                    this.sendNotification('error', this.t('notifications.error'), msg);
                }
            });
        },

        onDeletePoint() {
            const id = Number(this.createMenu.pointsEditor.selectedPointId || this.modal.createContract.spawnPointId || this.modal.createContract.deliveryPointId);
            if (!id) return;
            this.triggerCallback('origen_missions:server:EditorDeletePoint', { id }).then((res) => {
                if (res && res.status) {
                    this.sendNotification('success', this.t('notifications.success'), 'Punto eliminado');
                    this.createMenu.pointsEditor.selectedPointId = '';
                    if (String(this.modal.createContract.spawnPointId) === String(id)) {
                        this.modal.createContract.spawnPointId = '';
                    }
                    if (String(this.modal.createContract.deliveryPointId) === String(id)) {
                        this.modal.createContract.deliveryPointId = '';
                    }
                    this.refreshEditorPoints();
                } else {
                    this.sendNotification('error', this.t('notifications.error'), 'No se pudo eliminar el punto');
                }
            });
        },

        getNpcDifficultyLabel(difficultyValue) {
            const parsed = Number(difficultyValue);
            const index = Number.isFinite(parsed) ? parsed + 1 : 1;
            const key = `modal.admin_edit_contract.difficulties.${index}`;
            const translated = this.t(key);
            if (translated !== key) return translated;
            return this.t('modal.admin_edit_contract.difficulties.3');
        },

        toggleCustomSelect(type) {
            if (type === 'vehicle') {
                this.createMenu.selects.vehicleOpen = !this.createMenu.selects.vehicleOpen;
                if (this.createMenu.selects.vehicleOpen) {
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'prop') {
                this.createMenu.selects.propOpen = !this.createMenu.selects.propOpen;
                if (this.createMenu.selects.propOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'ped') {
                this.createMenu.selects.pedOpen = !this.createMenu.selects.pedOpen;
                if (this.createMenu.selects.pedOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'npcWeapon') {
                this.createMenu.selects.npcWeaponOpen = !this.createMenu.selects.npcWeaponOpen;
                if (this.createMenu.selects.npcWeaponOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.minigameDifficultyOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'accessMode') {
                this.createMenu.selects.accessModeOpen = !this.createMenu.selects.accessModeOpen;
                if (this.createMenu.selects.accessModeOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.minigameDifficultyOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'minigame') {
                this.createMenu.selects.minigameOpen = !this.createMenu.selects.minigameOpen;
                if (this.createMenu.selects.minigameOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameDifficultyOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'minigameDifficulty') {
                this.createMenu.selects.minigameDifficultyOpen = !this.createMenu.selects.minigameDifficultyOpen;
                if (this.createMenu.selects.minigameDifficultyOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'objectiveType') {
                this.createMenu.selects.objectiveTypeOpen = !this.createMenu.selects.objectiveTypeOpen;
                if (this.createMenu.selects.objectiveTypeOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'spawnPoint') {
                this.createMenu.selects.spawnPointOpen = !this.createMenu.selects.spawnPointOpen;
                if (this.createMenu.selects.spawnPointOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                }
            } else if (type === 'deliveryPoint') {
                this.createMenu.selects.deliveryPointOpen = !this.createMenu.selects.deliveryPointOpen;
                if (this.createMenu.selects.deliveryPointOpen) {
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.objectiveTypeOpen = false;
                    this.createMenu.selects.spawnPointOpen = false;
                }
            } else if (String(type).startsWith('settingsType')) {
                const key = `${type}Open`;
                this.$set(this.createMenu.selects, key, !this.createMenu.selects[key]);
            }
        },

        selectCustomOption(type, value) {
            if (type === 'vehicle') {
                this.modal.createContract.vehicle = value;
                this.createMenu.selects.vehicleOpen = false;
            } else if (type === 'prop') {
                this.modal.createContract.objectiveModel = value;
                this.createMenu.selects.propOpen = false;
            } else if (type === 'ped') {
                this.modal.createContract.objectiveModel = value;
                this.createMenu.selects.pedOpen = false;
            } else if (type === 'npcWeapon') {
                this.modal.createContract.npcWeapon = value;
                this.createMenu.selects.npcWeaponOpen = false;
            } else if (type === 'accessMode') {
                this.modal.createContract.accessMode = value;
                this.createMenu.selects.accessModeOpen = false;
            } else if (type === 'minigame') {
                this.modal.createContract.minigame = value;
                this.createMenu.selects.minigameOpen = false;
            } else if (type === 'minigameDifficulty') {
                this.modal.createContract.minigameDifficulty = value;
                this.createMenu.selects.minigameDifficultyOpen = false;
            } else if (type === 'objectiveType') {
                this.modal.createContract.objectiveType = value;
                this.modal.createContract.missionType = value;
                if (value === 'vehicle') {
                    this.modal.createContract.objectiveModel = this.modal.createContract.vehicle || (this.createMenu.vehicles[0] || '');
                } else if (value === 'prop') {
                    this.modal.createContract.objectiveModel = this.createMenu.props[0] || '';
                } else if (value === 'ped') {
                    this.modal.createContract.objectiveModel = this.createMenu.peds[0] || '';
                } else {
                    this.modal.createContract.objectiveModel = '';
                }
                this.createMenu.selects.vehicleOpen = false;
                this.createMenu.selects.propOpen = false;
                this.createMenu.selects.pedOpen = false;
                this.createMenu.selects.objectiveTypeOpen = false;
            } else if (type === 'spawnPoint') {
                this.modal.createContract.spawnPointId = value;
                this.createMenu.selects.spawnPointOpen = false;
            } else if (type === 'deliveryPoint') {
                this.modal.createContract.deliveryPointId = value;
                this.createMenu.selects.deliveryPointOpen = false;
            }
        },

        // Sistema de translate by Trendo

        // Cifras con punto de miles (1.840, 15.000). Lo que no sea numero se devuelve tal cual.
        n(valor) {
            const num = Number(valor);
            if (valor === null || valor === undefined || valor === '' || !Number.isFinite(num)) return valor;
            const signo = num < 0 ? '-' : '';
            const [ent, dec] = String(Math.abs(Math.round(num * 100) / 100)).split('.');
            return signo + ent.replace(/\B(?=(\d{3})+(?!\d))/g, '.') + (dec ? ',' + dec : '');
        },

        t(key, ...replaces) {
            const translation = this.translations['nui.' + key];
            return translation ? replaces.reduce((acc, replace) => acc.replace('%s', replace), translation) : key;
        },

        translationSystem() {           
            function flattenDict(obj, prefix = '', result = {}) {
                for (const [key, value] of Object.entries(obj)) {
                    const newKey = prefix ? `${prefix}.${key}` : key;
                    if (typeof value === 'object' && value !== null) {
                        flattenDict(value, newKey, result);
                    } else {
                        result[newKey] = value;
                    }
                }
                return result;
            }



            async function loadTranslations(lang) {
                let translations = {};
                try {
                    const response = await fetch(`../locales/${lang}.json`);
                    const rawTranslations = await response.json();
                    translations = flattenDict(rawTranslations);
                } catch (error) {
                    console.error(error);
                }
            
                return translations;
            }

            // Si el idioma no llega (Lua parado, banco de pruebas) se carga el espanol:
            // asi nunca salen las claves crudas en pantalla.
            const aplicar = (lang) => loadTranslations(lang || 'es').then(translations => {
                this.translations = translations;
            });
            Promise.resolve(this.fetchEvent('get_lang', {})).then(aplicar).catch(() => aplicar('es'));
        },

        updateHelp(index) {
            if (index === null) {
                this.mainMenu.showHelp = false;
                this.mainMenu.messageHelp = null;
                return;
            }

            this.mainMenu.messageHelp = this.t(`main.${index}.description`);
            setTimeout(() => {
                this.mainMenu.showHelp = true;
            }, 200);
        },        

        toggleMenu(state) {
            this.visible = state;
        },

        handleMouseDown(event) {
            const ref = this.$refs.contractsRef;
            this.isDragging = true;
            this.startX = event.pageX - ref.offsetLeft;
            this.scrollLeft = ref.scrollLeft;
        },
        handleMouseMove(event) {
            if (!this.isDragging) return;
            const ref = this.$refs.contractsRef;
            event.preventDefault();
            const x = event.pageX - ref.offsetLeft;
            const walk = (x - this.startX) * 1.5;
            ref.scrollLeft = this.scrollLeft - walk;
        },
        handleMouseUp() {
            this.isDragging = false;
        },

        handleMouseWheel(event) {
            const ref = this.$refs.contractsRef;
            ref.scrollLeft += event.deltaY;
        },

        handleKeyDown(event) {
            if (event.key === 'Escape') {
                if (this.serverInterval) {
                    clearInterval(this.serverInterval);
                    this.serverInterval = null;
                }
                this.toggleMenu(false);
                // Lua suelta el foco en 'close'; si el cursor del aviso quedara
                // marcado, la I siguiente lo apagaria en vez de encenderlo.
                this.incomingContractPopup.mouseEnabled = false;
                this.fetchEvent('close', {});
            }
        },
        handleOutsideClick(event) {
            if (!this.friends.visible || this.modal.id) return;
            
            const menu = this.$refs.menu;
            if (menu && !menu.contains(event.target)) {
                this.toggleFriends();
            }
        },

        /*  ── El riel del jugador ─────────────────────────────────────── */
        // Encender una seccion de la barra. En el panel grande, ademas, se
        // ensena la vista ancha que le toca (la tablet, el mercado o el ranking).
        rielIr(id) {
            this.riel.vista = id;
            this.rielAplicar();
        },
        rielAncho(valor) {
            this.riel.ancho = !!valor;
            this.rielAplicar();
        },
        // Las tres vistas anchas cuelgan de sus banderas de siempre: aqui se
        // ponen segun la seccion, sin pasar por navigateTo (que deja alguna
        // encendida al saltar de una a otra).
        rielAplicar() {
            if (this.createMenu.visible) return;
            const v = this.riel.vista;
            this.ranking.visible = v === 'ranking';
            this.market.visible = v === 'mercado';
            this.mainBoosting.visible = !this.ranking.visible && !this.market.visible;
        },
        // La cifra de una fila de la clasificacion, segun la categoria elegida.
        rankingCifra(user) {
            const v = this.rankingCategoria.de(user);
            return this.ranking.categoria === 'exito' ? String(Math.round(v * 10) / 10).replace('.', ',') : this.n(v);
        },
        /*  Saltar a otro menu desde el riel compartido: se recoge esto como
            con Escape, pero sin mandar 'close' — de cerrar la tablet y abrir
            el destino se encarga Lua (irDelRiel), para que no se crucen. */
        rielSaltar(b) {
            if (!b || b.actual) return;
            if (this.serverInterval) {
                clearInterval(this.serverInterval);
                this.serverInterval = null;
            }
            this.toggleMenu(false);
            this.incomingContractPopup.mouseEnabled = false;
            this.fetchEvent('irDelRiel', { id: b.id, tipo: b.tipo }).catch(() => {});
        },
        // Lo mismo que el Escape: cerrar y soltar el raton.
        cerrarTablet() {
            this.handleKeyDown({ key: 'Escape' });
        },

        navigateTo(menu) {
            // Los botones de la vista ancha (Clasificacion, Mercado, Volver)
            // mueven tambien la seccion encendida del riel.
            if (menu === 'ranking') this.riel.vista = 'ranking';
            else if (menu === 'market') this.riel.vista = 'mercado';
            else if (menu === 'mainBoosting' && (this.riel.vista === 'ranking' || this.riel.vista === 'mercado')) this.riel.vista = 'contratos';
            if (menu === 'mainMenu') menu = 'mainBoosting';
            if (menu == 'mainMenu') {
                this.mainMenu.visible = true;
                setTimeout(() => {
                    this.createMenu.visible = false;
                    this.mainBoosting.visible = false;
                    this.ranking.visible = false;
                }, 0);
            } else if (menu == 'mainBoosting') {
                this.mainBoosting.visible = true;  
                setTimeout(() => {
                    this.mainMenu.visible = false;
                    this.createMenu.visible = false;
                    this.ranking.visible = false;
                    this.market.visible = false;
                }, 0);
            } else if (menu == 'createMenu') {
                this.createMenu.visible = true;
                setTimeout(() => {
                    this.mainMenu.visible = false;
                    this.mainBoosting.visible = false;
                    this.ranking.visible = false;
                    this.market.visible = false;
                }, 0);
            } else if (menu == 'ranking') {
                this.ranking.visible = true;
                setTimeout(() => {
                    this.mainMenu.visible = false;
                    this.mainBoosting.visible = false;
                    this.createMenu.visible = false;
                    this.market.visible = false;
                }, 0);
            } else if (menu == 'market') {
                this.market.visible = true;
                setTimeout(() => {
                    this.mainBoosting.visible = false;
                }, 0);
            }
        },
        getDirection(menu) {
            if (menu === 'mainMenu')
                return 'hide-up';
            if (menu == 'mainBoosting')
                return this.createMenu.visible || this.ranking.visible || this.market.visible ? 'hide-bottom' : 'hide-up';
            if (menu == 'market')
                return this.mainBoosting.visible ? 'hide-bottom' : 'hide-up';
            if (menu == 'createMenu')
                return this.mainBoosting.visible ? 'hide-left' : 'hide-left';
            if (menu == 'ranking')
                return this.mainBoosting.visible ? 'hide-right' : 'hide-right';
        },
    
        // Modal

        getManageContractById(contractRef) {
            if (!Array.isArray(this.createMenu.list) || this.createMenu.list.length === 0) return null;
            const directById = this.createMenu.list.find((c) => Number(c.id) === Number(contractRef) || Number(c.ID) === Number(contractRef));
            if (directById) return directById;
            // Backward compatibility when an index is still passed from UI
            const idx = Number(contractRef);
            if (Number.isInteger(idx) && idx >= 0 && idx < this.createMenu.list.length) {
                return this.createMenu.list[idx];
            }
            return null;
        },

        openModal(id, ...args) {
            switch(id) {
                case "contractOffer":
                    this.modal.selectedContract = args[0];
                    break;
                case 'send_contract':
                    this.modal.selectedContract = this.getManageContractById(args[0]);
                    this.triggerCallback('origen_missions:server:EditorGetTemplates', {}).then((templates) => {
                        this.createMenu.missionTemplates = templates || [];
                    });
                    break;
                case 'delete_contract': // admin section
                    this.modal.selectedContract = this.getManageContractById(args[0]);
                    this.modal.deleteContract.id = this.modal.selectedContract ? this.modal.selectedContract.id : null;
                    break;
                case 'buyAuctionOffer':
                    this.modal.selectedContract = this.market.list.find(contract => contract.id === args[0]);
                    this.modal.selectedContract.price = args[1];
                    break;
                case 'buyContract':
                    this.modal.selectedContract = this.mainBoosting.contracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'cancelAuctionOffer':
                    this.modal.selectedContract = []
                    this.modal.selectedContract.id = args[0];
                    this.modal.selectedContract.index = this.mainBoosting.savedContracts.findIndex(contract => contract.uniqueID === args[0]);
                    break;
                case 'startContract':
                    this.modal.selectedContract = this.mainBoosting.savedContracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'cancelContract':
                    this.modal.selectedContract = this.mainBoosting.savedContracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'declineContract':
                    this.modal.selectedContract = this.mainBoosting.contracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'declineSavedContract':
                    this.modal.selectedContract = this.mainBoosting.savedContracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'sellContract':
                    this.modal.selectedContract = this.mainBoosting.savedContracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'sellContractMarket':
                    this.modal.selectedContract = this.mainBoosting.savedContracts[args[0]];
                    this.modal.selectedContract.index = args[0];
                    break;
                case 'changeName':
                    this.modal.editName.username = this.mainBoosting.profile.username || '';
                    break;
                case 'changeProfileImage':
                    this.modal.editProfile.image = this.mainBoosting.profile.image || '';
                    break;
                case 'changeProfileBanner':
                    this.modal.editProfile.banner = this.mainBoosting.profile.banner || '';
                    break;
                case 'create_contract':
                    this.modal.createContract.label = '';
                    this.modal.createContract.price = '';
                    this.modal.createContract.npcs = '';
                    this.modal.createContract.npcWeapon = this.createMenu.weapons[0] || '';
                    this.modal.createContract.vehicle = this.createMenu.vehicles[0] || '';
                    this.modal.createContract.objectiveType = 'vehicle';
                    this.modal.createContract.missionType = 'vehicle';
                    this.modal.createContract.objectiveModel = '';
                    this.modal.createContract.propItemName = 'black_money';
                    this.modal.createContract.propItemAmount = 1;
                    this.modal.createContract.minigame = this.createMenu.minigames[0] || '';
                    this.modal.createContract.minigameDifficulty = 'auto';
                    this.modal.createContract.accessMode = 'public';
                    this.modal.createContract.requiredGang = '';
                    this.modal.createContract.requiredCrew = '';
                    this.modal.createContract.spawnRadius = '';
                    this.modal.createContract.deliveryRadius = '';
                    this.modal.createContract.stageRadius = 8;
                    this.modal.createContract.stageTimer = 0;
                    this.modal.createContract.spawnPointId = '';
                    this.modal.createContract.deliveryPointId = '';
                    this.modal.createContract.spawnPointLabel = '';
                    this.modal.createContract.deliveryPointLabel = '';
                    this.modal.createContract.description = '';
                    this.modal.createContract.pointEditorType = 'spawn';
                    this.modal.createContract.editing = false;
                    this.modal.createContract.reward = '';
                    this.modal.createContract.experience = '';
                    this.modal.createContract.vin = '';
                    this.createMenu.difficultyIndex = 1;
                    this.createMenu.vinScratch = false;
                    this.createMenu.propRobable = false;
                    this.createMenu.propRequireDelivery = true;
                    this.createMenu.propLoseOnDeath = true;
                    this.createMenu.propLoseOnDisconnect = true;
                    this.createMenu.pointsEditor.name = '';
                    this.createMenu.pointsEditor.radius = 4;
                    this.createMenu.pointsEditor._coords = null;
                    this.createMenu.pointsEditor.selectedPointId = '';
                    this.createMenu.newPointDialog = { visible: false, type: 'spawn', name: '' };
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                    this.createMenu.selects.spawnPointQuery = '';
                    this.createMenu.selects.deliveryPointQuery = '';
                    break;
                case 'settings':
                    this.fetchEvent('GetRanks', {}).then((data) => {
                        this.modal.settings = (data || []).map((rank) => ({
                            ...rank,
                            missionType: rank.missionType || rank.mission_type || 'vehicle',
                            sortOrder: Number(rank.sortOrder || rank.rank_order || 1),
                            name: String(rank.name || '').trim()
                        })).sort((a, b) => {
                            const ta = (a.missionType || 'vehicle');
                            const tb = (b.missionType || 'vehicle');
                            if (ta === tb) return (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0);
                            return ta === 'vehicle' ? -1 : 1;
                        });
                        this.settingsViewType = 'vehicle';
                    });
                    break;
            }
            this.modal.id = id;
        },

        showConfirmModal() {
            if(this.modal.waiting) return false;
            switch (this.modal.id) {
                case 'settings':
                    if (!this.modal.settings || this.modal.settings.length === 0) return false;
                    const used = {};
                    for (let i = 0; i < this.modal.settings.length; i++) {
                        const rank = this.modal.settings[i];
                        const name = String(rank.name || '').trim();
                        const missionType = String(rank.missionType || 'vehicle') === 'prop' ? 'prop' : 'vehicle';
                        const sortOrder = Number(rank.sortOrder || 0);
                        if (!name || name.length > 24) return false;
                        const key = `${missionType}:${name.toLowerCase()}`;
                        if (used[key]) return false;
                        used[key] = true;
                        if (!Number.isFinite(sortOrder) || sortOrder < 1) return false;
                        if (!Number.isFinite(Number(rank.xp))) return false;
                        if (!Number.isFinite(Number(rank.percentage))) return false;
                        if (!Number.isFinite(Number(rank.tries))) return false;
                        if (!Number.isFinite(Number(rank.fails))) return false;
                        if (!Number.isFinite(Number(rank.max))) return false;
                        if (!Number.isFinite(Number(rank.minCops))) return false;
                        if (!Number.isFinite(Number(rank.hackxp))) return false;
                    }
                    return true;
                case 'changeName':
                    return this.modal.editName.username && this.modal.editName.username !== this.mainBoosting.profile.username;
                case 'changeProfileImage':
                    return this.modal.editProfile.image && this.modal.editProfile.image !== this.mainBoosting.profile.image;
                case 'changeProfileBanner':
                    return this.modal.editProfile.banner && this.modal.editProfile.banner !== this.mainBoosting.profile.banner;
                case 'create_contract':
                    if (!this.modal.createContract.label) return false;
                    if (!(Number(this.modal.createContract.price) > 0)) return false;
                    if (!(Number(this.modal.createContract.npcs) >= 0)) return false;
                    if (!this.modal.createContract.npcWeapon) return false;
                    if (!this.modal.createContract.objectiveType) return false;
                    if (!this.modal.createContract.spawnPointId) return false;
                    if (!this.modal.createContract.deliveryPointId) return false;
                    if (String(this.modal.createContract.spawnPointId) === String(this.modal.createContract.deliveryPointId)) return false;
                    if (this.modal.createContract.accessMode === 'specific_gang' && !this.modal.createContract.requiredGang) return false;
                    if (this.modal.createContract.accessMode === 'specific_crew' && !this.modal.createContract.requiredCrew) return false;
                    if (this.modal.createContract.objectiveType === 'vehicle' && !this.modal.createContract.vehicle) return false;
                    if (this.modal.createContract.objectiveType === 'prop' && !this.modal.createContract.objectiveModel) return false;
                    if (this.modal.createContract.objectiveType === 'prop' && this.createMenu.propRobable) {
                        if (!this.modal.createContract.propItemName || !String(this.modal.createContract.propItemName).trim()) return false;
                        if (!(Number(this.modal.createContract.propItemAmount) > 0)) return false;
                    }
                    if (this.modal.createContract.objectiveType === 'vehicle' && this.createMenu.vinScratch && !Number(this.modal.createContract.vin)) return false;
                    if (Number(this.modal.createContract.stageRadius) < 0) return false;
                    return true;
                case 'send_contract':
                    return Number(this.modal.sendContract.price) > 0 && Number(this.modal.sendContract.id) > 0
                case 'sellContract':
                    return Number(this.modal.sellContract.offerPrice) > 0 && Number(this.modal.sellContract.target) > 0;
                case 'sellContractMarket':
                    return Number(this.modal.sellContractMarket.price) > 0 && Number(this.modal.sellContractMarket.duration) > 0;
                case 'sendCoins':
                    return Number(this.modal.sendCoins.amount) > 0 && Number(this.modal.sendCoins.amount) <= this.mainBoosting.profile.coins && Number(this.modal.sendCoins.id) > 0 && this.modal.sendCoins.id !== this.mainBoosting.profile.source;
                case 'adminGiveCoins':
                    return Number(this.modal.adminGiveCoins.amount) > 0 && Number(this.modal.adminGiveCoins.id) > 0;
                default:
                    return true;
            }
        },
    
        onCancelModal() {
            switch(this.modal.id) {
                case 'startContract':
                    this.modal.selectedContract = null;
                    break;
                case 'cancelContract':
                    this.modal.selectedContract = null;
                    break;
                case 'declineContract':
                    this.modal.selectedContract = null;
                    break;
                case 'buyContract':
                    this.modal.selectedContract = null;
                    break;
                case 'create_contract':
                    this.modal.createContract.label = '';
                    this.modal.createContract.vehicle = '';
                    this.modal.createContract.npcs = '';
                    this.modal.createContract.npcWeapon = '';
                    this.createMenu.selects.vehicleOpen = false;
                    this.createMenu.selects.propOpen = false;
                    this.createMenu.selects.pedOpen = false;
                    this.createMenu.selects.npcWeaponOpen = false;
                    this.createMenu.selects.accessModeOpen = false;
                    this.createMenu.selects.minigameOpen = false;
                    this.createMenu.selects.minigameDifficultyOpen = false;
                    this.createMenu.selects.vehicleQuery = '';
                    this.createMenu.selects.propQuery = '';
                    this.createMenu.selects.pedQuery = '';
                    this.createMenu.selects.npcWeaponQuery = '';
                    this.createMenu.selects.accessModeQuery = '';
                    this.createMenu.selects.minigameQuery = '';
                    this.createMenu.selects.minigameDifficultyQuery = '';
                    this.modal.createContract.minigame = this.createMenu.minigames[0] || '';
                    this.modal.createContract.minigameDifficulty = 'auto';
                    this.modal.createContract.missionType = 'vehicle';
                    this.modal.createContract.objectiveType = 'vehicle';
                    this.modal.createContract.objectiveModel = '';
                    this.modal.createContract.propItemName = 'black_money';
                    this.modal.createContract.propItemAmount = 1;
                    this.modal.createContract.stageRadius = 8;
                    this.modal.createContract.stageTimer = 0;
                    this.modal.createContract.pointEditorType = 'spawn';
                    this.modal.createContract.accessMode = 'public';
                    this.modal.createContract.requiredGang = '';
                    this.modal.createContract.requiredCrew = '';
                    this.modal.createContract.spawnRadius = '';
                    this.modal.createContract.deliveryRadius = '';
                    this.modal.createContract.spawnPointLabel = '';
                    this.modal.createContract.deliveryPointLabel = '';
                    this.modal.createContract.description = '';
                    this.modal.createContract.spawnPointId = '';
                    this.modal.createContract.deliveryPointId = '';
                    this.createMenu.pointsEditor.name = '';
                    this.createMenu.pointsEditor.radius = 4;
                    this.createMenu.pointsEditor._coords = null;
                    this.createMenu.newPointDialog = { visible: false, type: 'spawn', name: '' };
                    this.createMenu.selects.spawnPointOpen = false;
                    this.createMenu.selects.deliveryPointOpen = false;
                    this.createMenu.selects.spawnPointQuery = '';
                    this.createMenu.selects.deliveryPointQuery = '';
                    this.createMenu.typeFilter = 'all';
                    this.modal.createContract.price = '';
                    this.modal.createContract.reward = '';
                    this.modal.createContract.experience = '';
                    this.modal.createContract.vin = '';
                    this.modal.createContract.category = this.getCurrentCategoryList()[0] || 'C';
                    this.modal.createContract.dificulty = 'Easy';
                    this.createMenu.difficultyIndex = 1;
                    this.createMenu.vinScratch = false;
                    this.createMenu.propRobable = true;
                    this.createMenu.propRequireDelivery = true;
                    this.createMenu.propLoseOnDeath = true;
                    this.createMenu.propLoseOnDisconnect = true;
                    break;
                case 'sellContract':
                    this.modal.sellContract.target = '';
                    this.modal.sellContract.offerPrice = '';
                    break;
                case 'sellContractMarket':
                    this.modal.sellContractMarket.price = '';
                    this.modal.sellContractMarket.duration = '';
                    break;
                case 'send_contract':
                    this.modal.sendContract.price = '';
                    this.modal.sendContract.id = '';
                    this.modal.selectedContract = null;
                    break;
                case 'changeName':
                    this.modal.editName.username = '';
                    break;
                case 'changeProfileImage':
                    this.modal.editProfile.image = '';
                    break;
                case 'changeProfileBanner':
                    this.modal.editProfile.banner = '';
                    break;
                case 'sendCoins':
                    this.modal.sendCoins.amount = '';
                    this.modal.sendCoins.id = '';
                    break;
                case 'adminGiveCoins':
                    this.modal.adminGiveCoins.amount = '';
                    this.modal.adminGiveCoins.id = '';
                    break;
            }

            this.modal.waiting = false;
            this.modal.createContract.editing = false;
            this.modal.id = null;
        },

        convertMsToTime(ms) {
            const minutos = Math.floor(ms / 60000);
            const segundos = Math.floor((ms % 60000) / 1000);
            return `${minutos.toString().padStart(2, '0')}:${segundos.toString().padStart(2, '0')}`;
        },

        convertSecondsToTime(seconds) {
            const horas = Math.floor(seconds / 3600);
            const minutos = Math.floor((seconds % 3600) / 60);
            const segundos = seconds % 60;
            return `${horas.toString().padStart(2, '0')}:${minutos.toString().padStart(2, '0')}:${segundos.toString().padStart(2, '0')}`;
        },

        initInterval() {
            if (this.serverInterval) return;
            this.serverInterval = setInterval(() => {
                for (const property in this.market.list) {
                    let timeleft = this.market.list[property].remainingTime - 1;
                    if (timeleft <= 0) {
                        timeleft = 0;
                    }
                    this.$set(this.market.list[property], 'remainingTime', timeleft);
                    this.$set(this.market.list[property], 'remainingCountdown', this.convertSecondsToTime(timeleft));
                }
                for (let i = this.mainBoosting.contracts.length - 1; i >= 0; i--) {
                    const contract = this.mainBoosting.contracts[i];
                    let timeleft = Number(contract.remainingTime || 0) - 1;
                    if (timeleft <= 0) {
                        this.mainBoosting.contracts.splice(i, 1);
                        continue;
                    }
                    this.$set(this.mainBoosting.contracts[i], 'remainingTime', timeleft);
                    this.$set(this.mainBoosting.contracts[i], 'remainingCountdown', this.convertSecondsToTime(timeleft));
                }
            }, 1000);
        },

        openNameModal(restrictClose) {
            this.modal.editName.restrictExit = restrictClose;
            this.openModal('changeName');
        },

        onRequestNameUpdate() {
            this.triggerCallback('origen_boosting:server:SetPlayerName', { name: this.modal.editName.username }).then((cb) => {
                if(cb === true) {
                    this.modal.waiting = true;
                    this.mainBoosting.profile.username = this.modal.editName.username;
                    this.onCancelModal();
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.name_already_in_use'));
                }
            });
        },

        openImageModal() {
            this.openModal('changeProfileImage');
        },

        openBannerModal() {
            this.openModal('changeProfileBanner');
        },

        onRequestProfileImageUpdate() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:SetProfileImage', { url: this.modal.editProfile.image }).then((cb) => {
                if (cb === true) {
                    this.mainBoosting.profile.image = this.modal.editProfile.image;
                    this.sendNotification('success', this.t('notifications.success'), 'Foto de perfil actualizada');
                    this.onCancelModal();
                } else {
                    this.sendNotification('error', this.t('notifications.error'), 'URL no válida o no se pudo guardar');
                    this.modal.waiting = false;
                }
            });
        },

        onRequestProfileBannerUpdate() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:SetProfileBanner', { url: this.modal.editProfile.banner }).then((cb) => {
                if (cb === true) {
                    this.mainBoosting.profile.banner = this.modal.editProfile.banner;
                    this.sendNotification('success', this.t('notifications.success'), 'Banner actualizado');
                    this.onCancelModal();
                } else {
                    this.sendNotification('error', this.t('notifications.error'), 'URL no válida o no se pudo guardar');
                    this.modal.waiting = false;
                }
            });
        },

        loadBoostingData(data) {
            if(data == null) return;
            this.mainBoosting.profile.username = data.name;
            this.mainBoosting.profile.image = data.image || this.mainBoosting.profile.image;
            this.mainBoosting.profile.banner = data.banner || this.mainBoosting.profile.banner;
            this.mainBoosting.profile.prestige = data.prestige || 0;
            this.mainBoosting.profile.totalExperience = Number(data.experience) || 0;
            this.mainBoosting.profile.totalExperienceVehicle = Number(data.experience_vehicle || data.experience || 0);
            this.mainBoosting.profile.totalExperienceProp = Number(data.experience_prop || 0);
            const rankVehicle = data.rankVehicle || data.rank || { actualRank: { name: 'D', xp: 0 }, nextRank: null };
            const rankProp = data.rankProp || data.rank || { actualRank: { name: 'D', xp: 0 }, nextRank: null };
            this.mainBoosting.profile.currentLevelVehicle.rank = rankVehicle.actualRank.name;
            this.mainBoosting.profile.currentLevelVehicle.xp = rankVehicle.actualRank.xp;
            this.mainBoosting.profile.nextLevelVehicle.rank = rankVehicle.nextRank ? rankVehicle.nextRank.name : null;
            this.mainBoosting.profile.nextLevelVehicle.requiredxp = rankVehicle.nextRank ? rankVehicle.nextRank.xp : 0;
            this.mainBoosting.profile.currentLevelProp.rank = rankProp.actualRank.name;
            this.mainBoosting.profile.currentLevelProp.xp = rankProp.actualRank.xp;
            this.mainBoosting.profile.nextLevelProp.rank = rankProp.nextRank ? rankProp.nextRank.name : null;
            this.mainBoosting.profile.nextLevelProp.requiredxp = rankProp.nextRank ? rankProp.nextRank.xp : 0;
            this.mainBoosting.profile.currentLevel = { ...this.mainBoosting.profile.currentLevelVehicle };
            this.mainBoosting.profile.nextLevel = { ...this.mainBoosting.profile.nextLevelVehicle };
            this.mainBoosting.profile.coins = data.coins;
            this.mainBoosting.savedContracts = [];
            this.mainBoosting.contractHistory = [];
            for(const key in data.saved) {
                this.mainBoosting.savedContracts.push(data.saved[key]);
            }
            for(const key in data.history) {
                this.mainBoosting.contractHistory.push(data.history[key]);
            }
        },

        loadOffers(data) {
            this.market.list = [];

            for (const key in data) {
                this.market.list.push({
                    id: data[key].id,
                    remainingTime: data[key].remainingTime,
                    seller: data[key].seller,
                    data: data[key].data,
                })
            }
        },

        // Gestion de contratos: cuantos hay de cada tipo (vehicle / prop).
        cuentaContratos(tipo) {
            return this.createMenu.list.filter(c => ((c.objectiveType || c.missionType || 'vehicle') === 'prop' ? 'prop' : 'vehicle') === tipo).length;
        },
        // WEAPON_PISTOL -> Pistol: el nombre interno del arma, legible en la tabla.
        armaLegible(arma) {
            if (!arma) return '—';
            const id = String(arma).replace(/^weapon_/i, '').toLowerCase();
            const ES = { pistol: 'Pistola', combatpistol: 'Pistola de combate', appistol: 'Pistola automática', stungun: 'Táser', pistol50: 'Pistola .50', snspistol: 'Pistola SNS', heavypistol: 'Pistola pesada', vintagepistol: 'Pistola antigua', flaregun: 'Pistola de bengalas', marksmanpistol: 'Pistola de tirador', revolver: 'Revólver', doubleaction: 'Revólver de doble acción', raypistol: 'Pistola de rayos', ceramicpistol: 'Pistola de cerámica', navyrevolver: 'Revólver naval', microsmg: 'Micro subfusil', smg: 'Subfusil', assaultsmg: 'Subfusil de asalto', combatpdw: 'PDW de combate', machinepistol: 'Pistola ametralladora', minismg: 'Mini subfusil', railgun: 'Cañón de riel', assaultrifle: 'Fusil de asalto', carbinerifle: 'Carabina', advancedrifle: 'Fusil avanzado', specialcarbine: 'Carabina especial', bullpuprifle: 'Fusil bullpup', compactrifle: 'Fusil compacto', militaryrifle: 'Fusil militar', heavyrifle: 'Fusil pesado', tacticalrifle: 'Fusil táctico', sniperrifle: 'Fusil de francotirador', heavysniper: 'Francotirador pesado', marksmanrifle: 'Fusil de tirador', precisionrifle: 'Fusil de precisión', pumpshotgun: 'Escopeta de corredera', sawnoffshotgun: 'Escopeta recortada', assaultshotgun: 'Escopeta de asalto', bullpupshotgun: 'Escopeta bullpup', musket: 'Mosquete', heavyshotgun: 'Escopeta pesada', dbshotgun: 'Escopeta de dos cañones', autoshotgun: 'Escopeta automática', combatshotgun: 'Escopeta de combate', bat: 'Bate', golfclub: 'Palo de golf', crowbar: 'Palanca', wrench: 'Llave inglesa', hammer: 'Martillo', bottle: 'Botella', dagger: 'Daga', hatchet: 'Hacha', knuckle: 'Puño americano', machete: 'Machete', switchblade: 'Navaja', battleaxe: 'Hacha de guerra', poolcue: 'Taco de billar', knife: 'Cuchillo', stone_hatchet: 'Hacha de piedra', rpg: 'Lanzacohetes', grenadelauncher: 'Lanzagranadas', minigun: 'Minigun', grenade: 'Granada', unarmed: 'Sin arma' };
            if (ES[id]) return ES[id];
            const s = id.replace(/_/g, ' ');
            return s.charAt(0).toUpperCase() + s.slice(1);
        },
        updateBoostingManageList() {
            return this.triggerCallback('origen_boosting:server:GetBoostinContracts', {}).then((cb) => {
                this.createMenu.list = cb || [];
                this.createMenu.list.forEach(contract => {
                    try {
                        contract.vehicle = JSON.parse(contract.vehicle);
                    } catch (e) {
                        contract.vehicle = [];
                    }
                });
                return this.triggerCallback('origen_missions:server:EditorGetTemplates', {}).then((templates) => {
                    this.createMenu.missionTemplates = templates || [];
                    const byKey = {};
                    for (const template of this.createMenu.missionTemplates) {
                        if (template && template.key) {
                            byKey[String(template.key)] = template;
                        }
                    }
                    this.createMenu.list.forEach((contract) => {
                        const template = byKey[`legacy_contract_${contract.id}`];
                        const firstStage = template && Array.isArray(template.stages) ? template.stages[0] : null;
                        const objectiveType = (
                            firstStage &&
                            firstStage.objective &&
                            firstStage.objective.objectiveType
                        ) || (template && template.missionType) || contract.missionType || 'vehicle';
                        contract.objectiveType = objectiveType === 'prop' ? 'prop' : 'vehicle';
                    });
                    return this.createMenu.list;
                });
            });
        },

        randomID() {
            const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
            let code = '';
            for (let i = 0; i < 6; i++) {
                code += characters.charAt(Math.floor(Math.random() * characters.length));
            }
            return code;
        },

        getPointOptionId(point, index, kind) {
            if (!point) return '';
            if (point.id !== undefined && point.id !== null) return String(point.id);
            return `${kind}_${index}`;
        },

        getPointOptionLabel(point, index, kind) {
            if (!point) return `Punto ${index + 1}`;
            if (point.name) return point.name;
            kind = kind === 'spawn' ? 'Inicio' : (kind === 'delivery' ? 'Entrega' : String(kind || 'Punto'));
            if (point.coords && point.coords.x !== undefined) {
                return `${kind.toUpperCase()} ${index + 1} (${Number(point.coords.x).toFixed(1)}, ${Number(point.coords.y).toFixed(1)})`;
            }
            if (point.x !== undefined) {
                return `${kind.toUpperCase()} ${index + 1} (${Number(point.x).toFixed(1)}, ${Number(point.y).toFixed(1)})`;
            }
            return `${kind.toUpperCase()} ${index + 1}`;
        },

        resolvePointById(points, selectedId, kind) {
            if (!points || points.length === 0) return null;
            for (let i = 0; i < points.length; i++) {
                const optionId = this.getPointOptionId(points[i], i, kind);
                if (String(optionId) === String(selectedId)) {
                    const point = points[i];
                    if (point.coords && point.coords.x !== undefined) {
                        return { x: Number(point.coords.x), y: Number(point.coords.y), z: Number(point.coords.z), w: Number(point.coords.w || 0) };
                    }
                    if (point.x !== undefined) {
                        return { x: Number(point.x), y: Number(point.y), z: Number(point.z), w: Number(point.w || 0) };
                    }
                }
            }
            const fallback = points[0];
            if (fallback.coords && fallback.coords.x !== undefined) {
                return { x: Number(fallback.coords.x), y: Number(fallback.coords.y), z: Number(fallback.coords.z), w: Number(fallback.coords.w || 0) };
            }
            if (fallback.x !== undefined) {
                return { x: Number(fallback.x), y: Number(fallback.y), z: Number(fallback.z), w: Number(fallback.w || 0) };
            }
            return null;
        },

        getPointById(points, selectedId, kind) {
            if (!points || points.length === 0) return null;
            for (let i = 0; i < points.length; i++) {
                const optionId = this.getPointOptionId(points[i], i, kind);
                if (String(optionId) === String(selectedId)) {
                    return points[i];
                }
            }
            return null;
        },

        buildTemplateFromContract(contractData) {
            const spawn = this.resolvePointById(this.createMenu.spawnPoints, this.modal.createContract.spawnPointId, 'spawn');
            const delivery = this.resolvePointById(this.createMenu.deliveryPoints, this.modal.createContract.deliveryPointId, 'delivery');
            const vehicleModel = Array.isArray(contractData.vehicle) ? (contractData.vehicle[0] || '') : contractData.vehicle;
            const objectiveType = this.modal.createContract.objectiveType || 'vehicle';
            let objectiveModel = '';
            if (objectiveType === 'vehicle') {
                objectiveModel = this.modal.createContract.vehicle || vehicleModel;
            } else if (objectiveType === 'prop') {
                objectiveModel = this.modal.createContract.objectiveModel || '';
            }
            const spawnPointId = Number(this.modal.createContract.spawnPointId) || null;
            const deliveryPointId = Number(this.modal.createContract.deliveryPointId) || null;
            const spawnPoint = this.getPointById(this.createMenu.spawnPoints, this.modal.createContract.spawnPointId, 'spawn');
            const deliveryPoint = this.getPointById(this.createMenu.deliveryPoints, this.modal.createContract.deliveryPointId, 'delivery');
            const spawnRadius = Number(this.modal.createContract.spawnRadius) || Number((spawnPoint && spawnPoint.radius) || 0) || 6;
            const deliveryRadius = Number(this.modal.createContract.deliveryRadius) || Number((deliveryPoint && deliveryPoint.radius) || 0) || 12;
            const stageRadius = Number(this.modal.createContract.stageRadius) || spawnRadius;
            const propMeta = {
                robable: !!this.createMenu.propRobable,
                requireDelivery: !!this.createMenu.propRequireDelivery,
                trackerEnabled: !!this.createMenu.propRobable,
                itemName: objectiveType === 'prop' ? (String(this.modal.createContract.propItemName || '').trim() || 'black_money') : '',
                itemAmount: objectiveType === 'prop' ? Math.max(1, Number(this.modal.createContract.propItemAmount) || 1) : 1,
                loseItemOnDeath: !!this.createMenu.propLoseOnDeath,
                loseItemOnDisconnect: !!this.createMenu.propLoseOnDisconnect
            };

            const stages = [
                {
                    id: 'stage_1',
                    label: 'Primary objective',
                    objective: {
                        objectiveType: objectiveType,
                        model: objectiveModel,
                        amount: 1,
                        radius: stageRadius,
                        interaction: 'interact',
                        shouldSpawn: true
                    },
                    spawn: {
                        pointId: spawnPointId,
                        fromConfigZone: spawnPointId ? null : 'spawn',
                        coords: spawn
                    },
                    successConditions: {
                        interaction: true
                    },
                    failConditions: {
                        onDeath: true
                    },
                    timers: {
                        stage: Number(this.modal.createContract.stageTimer) || 0
                    },
                    rewards: objectiveType === 'prop' && !propMeta.requireDelivery ? {
                        account: 'ogn',
                        amount: Number(contractData.reward) || 0,
                        experience: Number(contractData.experience) || 0
                    } : {
                        account: 'ogn',
                        amount: 0,
                        experience: 0
                    },
                    metadata: {
                        propStealMinigame: contractData.minigame || 'StartHacking',
                        propStealDifficulty: contractData.minigame_difficulty || 'auto',
                        propTrackerMinigame: 'StartHacking',
                        propTrackerDifficulty: contractData.minigame_difficulty || 'auto'
                    }
                }
            ];

            if (!(objectiveType === 'prop' && !propMeta.requireDelivery)) {
                stages.push({
                    id: 'stage_2',
                    label: 'Delivery',
                    objective: {
                        objectiveType: 'zone',
                        amount: 1,
                        radius: deliveryRadius,
                        interaction: 'deliver',
                        shouldSpawn: false
                    },
                    spawn: {
                        pointId: deliveryPointId,
                        fromConfigZone: deliveryPointId ? null : 'delivery',
                        coords: delivery
                    },
                    successConditions: {
                        interaction: true,
                        inZone: true
                    },
                    failConditions: {
                        onDeath: true
                    },
                    rewards: {
                        account: 'ogn',
                        amount: Number(contractData.reward) || 0,
                        experience: Number(contractData.experience) || 0
                    }
                });
            }

            return {
                key: contractData.id ? `legacy_contract_${contractData.id}` : `legacy_contract_runtime_${Date.now()}`,
                name: contractData.label,
                description: String(contractData.description || this.modal.createContract.description || '').trim(),
                missionType: objectiveType,
                category: contractData.category,
                price: Number(contractData.price) || 0,
                vinPrice: Number(contractData.vin) || 0,
                reward: Number(contractData.reward) || 0,
                experience: Number(contractData.experience) || 0,
                guards: Number(contractData.guards) || 0,
                difficulty: Number(contractData.difficulty) || 0,
                weapon: contractData.weapon,
                minigame: contractData.minigame || 'StartHacking',
                minigameDifficulty: contractData.minigame_difficulty || 'auto',
                metadata: {
                    access: {
                        mode: this.modal.createContract.accessMode || 'public',
                        gang: this.modal.createContract.requiredGang || '',
                        crew: this.modal.createContract.requiredCrew || ''
                    },
                    points: {
                        spawnName: this.modal.createContract.spawnPointLabel || (spawnPoint && spawnPoint.name ? spawnPoint.name : ''),
                        deliveryName: this.modal.createContract.deliveryPointLabel || (deliveryPoint && deliveryPoint.name ? deliveryPoint.name : '')
                    },
                    prop: propMeta
                },
                stages: stages
            };
        },
        
        //? Contract management
        onRequestCreateContract() {
            if (String(this.modal.createContract.spawnPointId) === String(this.modal.createContract.deliveryPointId)) {
                this.sendNotification('error', this.t('notifications.error'), 'Spawn y entrega no pueden ser el mismo punto');
                return;
            }
            const objectiveType = this.modal.createContract.objectiveType || 'vehicle';
            let legacyObjectiveModel = this.modal.createContract.vehicle || '';
            if (objectiveType === 'prop') {
                legacyObjectiveModel = this.modal.createContract.objectiveModel || '';
            }
            const contractData = {
                category: this.modal.createContract.category,
                missionType: objectiveType,
                difficulty: this.createMenu.difficultyIndex - 1,
                experience: Number(this.modal.createContract.experience),
                id: this.modal.createContract.id,
                label: this.modal.createContract.label,
                description: String(this.modal.createContract.description || '').trim(),
                guards: Number(this.modal.createContract.npcs),
                price: Number(this.modal.createContract.price),
                reward: Number(this.modal.createContract.reward),
                vehicle: JSON.stringify([legacyObjectiveModel]),
                vin: (objectiveType === 'vehicle' && this.createMenu.vinScratch) ? Number(this.modal.createContract.vin) : false,
                weapon: this.modal.createContract.npcWeapon,
                minigame: this.modal.createContract.minigame,
                minigame_difficulty: this.modal.createContract.minigameDifficulty,
            }
            const afterSave = () => {
                const persistedId = Number(contractData.id || 0);
                const templateSource = {
                    ...contractData,
                    id: persistedId,
                    objectiveType,
                    missionType: objectiveType,
                    vehicle: [legacyObjectiveModel]
                };
                const template = this.buildTemplateFromContract(templateSource);

                this.triggerCallback('origen_missions:server:EditorUpsertTemplate', { template }).then((res) => {
                    if (!(res && res.status)) {
                        this.sendNotification('error', this.t('notifications.error'), 'Contrato guardado, pero falló la plantilla de misión');
                    }
                    return this.updateBoostingManageList();
                }).finally(() => {
                    this.onCancelModal();
                });
            };
            if(this.modal.createContract.editing) {
                this.triggerCallback('origen_boosting:server:EditBoosting', contractData).then((updatedId) => {
                    contractData.id = Number(updatedId || contractData.id);
                    afterSave();
                });
                this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_edited'));
            }
            else {
                this.triggerCallback('origen_boosting:server:AddBoosting', contractData).then((newId) => {
                    contractData.id = Number(newId || 0);
                    afterSave();
                });
                this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_created'));
            }
        },

        editContract(contractRef) {
            const data = this.getManageContractById(contractRef);
            if (!data) {
                this.sendNotification('error', this.t('notifications.error'), this.t('contracts.contract_not_found') || 'No se encontro el contrato');
                return;
            }
            const applyTemplateMeta = (templates) => {
                const templateKey = `legacy_contract_${data.id}`;
                const template = (templates || []).find((item) => String(item.key) === String(templateKey));
                if (!template) return;

                const metadata = template.metadata || {};
                const prop = metadata.prop || {};
                const access = metadata.access || {};
                const points = metadata.points || {};
                const stages = template.stages || [];
                const spawnStage = stages[0] || null;
                const deliveryStage = stages.find((stage) => stage && stage.objective && stage.objective.objectiveType === 'zone' && stage.objective.interaction === 'deliver') || stages[1] || null;
                const objectiveType = (
                    spawnStage &&
                    spawnStage.objective &&
                    spawnStage.objective.objectiveType
                ) || template.missionType || data.missionType || data.objectiveType || 'vehicle';
                const isProp = objectiveType === 'prop';

                this.modal.createContract.objectiveType = isProp ? 'prop' : 'vehicle';
                this.modal.createContract.missionType = this.modal.createContract.objectiveType;
                if (isProp) {
                    this.modal.createContract.objectiveModel = String((spawnStage && spawnStage.objective && spawnStage.objective.model) || this.createMenu.props[0] || '');
                    this.createMenu.propRobable = prop.robable !== false;
                    this.createMenu.propRequireDelivery = prop.requireDelivery !== false;
                    this.createMenu.propLoseOnDeath = prop.loseItemOnDeath !== false;
                    this.createMenu.propLoseOnDisconnect = prop.loseItemOnDisconnect !== false;
                    this.modal.createContract.propItemName = String(prop.itemName || 'black_money');
                    this.modal.createContract.propItemAmount = Math.max(1, Number(prop.itemAmount) || 1);
                } else {
                    this.modal.createContract.objectiveModel = '';
                }

                this.modal.createContract.accessMode = access.mode || 'public';
                this.modal.createContract.requiredGang = access.gang || '';
                this.modal.createContract.requiredCrew = access.crew || '';
                this.modal.createContract.spawnPointLabel = points.spawnName || '';
                this.modal.createContract.deliveryPointLabel = points.deliveryName || '';

                if (spawnStage && spawnStage.spawn && spawnStage.spawn.pointId) {
                    this.modal.createContract.spawnPointId = String(spawnStage.spawn.pointId);
                }
                if (deliveryStage && deliveryStage.spawn && deliveryStage.spawn.pointId) {
                    this.modal.createContract.deliveryPointId = String(deliveryStage.spawn.pointId);
                }
            };

            this.modal.createContract.vehicle = Array.isArray(data.vehicle) ? (data.vehicle[0] || '') : '';
            this.modal.createContract.npcs = data.guards;
            this.modal.createContract.npcWeapon = data.weapon;
            this.modal.createContract.minigame = data.minigame || this.createMenu.minigames[0] || '';
            this.modal.createContract.minigameDifficulty = data.minigame_difficulty || 'auto';
            this.modal.createContract.reward = data.reward;
            this.modal.createContract.experience = data.experience;
            this.modal.createContract.category = data.category;
            this.modal.createContract.vin = data.vin;
            this.createMenu.difficultyIndex = data.difficulty + 1;
            this.createMenu.vinScratch = data.vin ? true : false;
            this.modal.createContract.id = data.id;
            this.modal.createContract.label = data.label;
            this.modal.createContract.price = data.price;
            this.modal.createContract.objectiveType = data.objectiveType || data.missionType || 'vehicle';
            this.modal.createContract.missionType = this.modal.createContract.objectiveType;
            this.modal.createContract.objectiveModel = '';
            this.modal.createContract.propItemName = 'black_money';
            this.modal.createContract.propItemAmount = 1;
            this.createMenu.propRobable = true;
            this.createMenu.propRequireDelivery = true;
            this.createMenu.propLoseOnDeath = true;
            this.createMenu.propLoseOnDisconnect = true;
            this.modal.createContract.spawnPointId = this.getPointOptionId(this.createMenu.spawnPoints[0], 0, 'spawn');
            this.modal.createContract.deliveryPointId = this.getPointOptionId(this.createMenu.deliveryPoints[0], 0, 'delivery');
            this.modal.createContract.accessMode = 'public';
            this.modal.createContract.requiredGang = '';
            this.modal.createContract.requiredCrew = '';
            this.modal.createContract.spawnPointLabel = '';
            this.modal.createContract.deliveryPointLabel = '';
            this.modal.createContract.description = String(data.description || '').trim();
            const categoryList = this.getCurrentCategoryList();
            if (!categoryList.includes(this.modal.createContract.category)) {
                this.modal.createContract.category = categoryList[0] || this.modal.createContract.category;
            }
            if (Array.isArray(this.createMenu.missionTemplates) && this.createMenu.missionTemplates.length > 0) {
                applyTemplateMeta(this.createMenu.missionTemplates);
            } else {
                this.triggerCallback('origen_missions:server:EditorGetTemplates', {}).then((templates) => {
                    this.createMenu.missionTemplates = templates || [];
                    applyTemplateMeta(this.createMenu.missionTemplates);
                });
            }
            // Don't use openModal() here — it would reset all fields we just populated
            this.modal.id = 'create_contract';
            this.modal.createContract.editing = true;
        },

        textToObject(text) {
            return text.split(',').map(item => item.trim());
        },

        objectToText(object, separator) {
            return object.join(separator);
        },

        onRequestSendContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:SendContract', {... this.modal.selectedContract, price: this.modal.sendContract.price, receiver: this.modal.sendContract.id}).then((cb) => {
                if(cb) {
                    this.triggerCallback('origen_missions:server:EditorUpsertTemplate', { template: this.buildTemplateFromContract(this.modal.selectedContract) });
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_sent'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.player_offline'));
                }
                this.onCancelModal();
            });
        },

        onRequestRemoveContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:RemoveBoosting', { id: this.modal.deleteContract.id }).then((cb) => {
                if (cb === true) {
                    this.updateBoostingManageList();
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_removed'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_deleted'));
                }
                this.onCancelModal();
            });
        },

        onRequestRefuseContractOffer() {
            this.modal.waiting = true;
            this.triggerCallback('origen_carboosting:cb:RefuseTempOffer', this.modal.selectedContract).then((cb) => {
                this.onCancelModal();
            });
        },

        //? Player contract management
        onRequestBuyContract(byOffer) {
            this.modal.waiting = true;
            if (byOffer) {
                this.triggerCallback('origen_carboosting:cb:BuyTempOffer', this.modal.selectedContract).then((cb) => {
                    if (cb.status === true) {
                        this.mainBoosting.profile.coins -= this.modal.selectedContract.price;
                        this.modal.selectedContract.offered = false;
                        this.modal.selectedContract.transfered = true;
                        this.mainBoosting.savedContracts.push(this.modal.selectedContract);
                        this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_bought'));
                    } else {
                        this.sendNotification('error', this.t('notifications.error'), cb.msg);
                    }
                    this.onCancelModal();
                });
            } else {
                this.modal.selectedContract.uniqueID = this.randomID();
                this.triggerCallback('origen_boosting:server:BuyContract', this.modal.selectedContract).then((cb) => {
                    if(cb === true) {
                        this.mainBoosting.profile.coins -= this.modal.selectedContract.price;
                        this.mainBoosting.contracts.splice(this.modal.selectedContract.index, 1);
                        this.mainBoosting.savedContracts.push(this.modal.selectedContract);
                        this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_bought'));
                    } else {
                        this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_bought'));
                    }
                    this.onCancelModal();
                });
            }
        },

        onRequestDeclineContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:DeclineContract', { id: this.modal.selectedContract.id }).then((cb) => {
                if(cb === true) {
                    this.mainBoosting.contracts.splice(this.modal.selectedContract.index, 1);
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_declined'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_declined'));
                }
                this.onCancelModal();
            });
        },

        onRequestStartContract(vin) {
            this.modal.waiting = true;
            this.modal.selectedContract.vinPrice = vin ? this.modal.selectedContract.vin : false;
            this.triggerCallback('origen_boosting:server:StartContract', this.modal.selectedContract).then((cb) => {
                if (cb.status) {
                    this.mainBoosting.savedContracts[this.modal.selectedContract.index].started = true;
                    this.toggleMenu(false);
                    this.fetchEvent('close', {});
                } else {
                    this.sendNotification('error', this.t('notifications.error'), cb.msg);
                }
                this.onCancelModal();
            });
        },

        onRequestCancelContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:CancelContract', {}).then((cb) => {
                if(cb === true) {
                    this.mainBoosting.savedContracts.splice(this.modal.selectedContract.index, 1);
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_canceled'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_canceled'));
                }
                this.onCancelModal();
            });
        },

        onRequestSellContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_carboosting:cb:SendTempOffer', {... this.modal.selectedContract, target: this.modal.sellContract.target, price: this.modal.sellContract.offerPrice}).then((cb) => {
                if (cb.status === true) {
                    this.$set(this.mainBoosting.savedContracts, this.modal.selectedContract.index, {...this.mainBoosting.savedContracts[this.modal.selectedContract.index], offered: true});

                    this.sendNotification('success', this.t('notifications.success'), cb.msg);
                } else {
                    this.sendNotification('error', this.t('notifications.error'), cb.msg);
                }
                this.onCancelModal();
            });
        },

        onRequestSellContractMarket() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:CreateMarketOffer', {... this.modal.selectedContract, price: this.modal.sellContractMarket.price, duration: this.modal.sellContractMarket.duration * 60}).then((cb) => {
                if(cb === true) {
                    this.mainBoosting.savedContracts[this.modal.selectedContract.index].auction = true;
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_listed'));
                }
                this.onCancelModal();
            });
        },

        onRequestCancelAuctionOffer() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:CancelMarketOffer', { id: this.modal.selectedContract.id }).then((cb) => {
                if(cb === true) {
                    this.mainBoosting.savedContracts[this.modal.selectedContract.index].auction = false;
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_removed'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_removed'));
                }
                this.onCancelModal();
            });
        },

        onRequestBuyAuctionOffer() {
            this.triggerCallback('origen_boosting:server:BuyMarketOffer', { id: this.modal.selectedContract.data.uniqueID }).then((cb) => {
                if(cb === true) {
                    this.modal.selectedContract.data.transfered = true;
                    this.mainBoosting.savedContracts.push(this.modal.selectedContract.data);
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_bought'));
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_bought'));
                }
                this.onCancelModal();
            });
        },

        onRequestDeclineSavedContract() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:DeclineSavedContract', { id: this.modal.selectedContract.uniqueID }).then((cb) => {
                if(cb !== true) return this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_deleted'));
                this.mainBoosting.savedContracts.splice(this.modal.selectedContract.index, 1);
                this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_deleted'));
                this.onCancelModal();
            });
        },

        onRequestSendCoins() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:SendCoins', { amount: Number(this.modal.sendCoins.amount), target: Number(this.modal.sendCoins.id) }).then((cb) => {
                if(cb === true) {
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.coins_sent', this.modal.sendCoins.amount));
                    this.mainBoosting.profile.coins -= this.modal.sendCoins.amount;
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.player_offline'));
                }
                this.onCancelModal();
            });
        },

        onRequestAdminGiveCoins() {
            this.modal.waiting = true;
            const amount = Number(this.modal.adminGiveCoins.amount);
            const target = Number(this.modal.adminGiveCoins.id);
            this.triggerCallback('origen_boosting:server:AdminGiveCoins', { amount, target }).then((cb) => {
                if (cb === true) {
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.coins_given', amount));
                    if (target === this.mainBoosting.profile.source) {
                        this.mainBoosting.profile.coins += amount;
                    }
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.player_offline'));
                }
                this.onCancelModal();
            });
        },

        onUpdateRanks() {
            this.modal.waiting = true;
            this.triggerCallback('origen_boosting:server:SetRanks', { data: this.modal.settings}).then((cb) => {
                if(cb === true) {
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.ranks_updated'));
                    this.createMenu.vehicleCategories = this.modal.settings.filter((rank) => (rank.missionType || 'vehicle') === 'vehicle').sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0)).map((rank) => rank.name);
                    this.createMenu.missionCategories = this.modal.settings.filter((rank) => (rank.missionType || 'vehicle') === 'prop').sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0)).map((rank) => rank.name);
                    this.createMenu.categories = [...this.createMenu.vehicleCategories];
                    const categoryList = this.getCurrentCategoryList();
                    if (!categoryList.includes(this.modal.createContract.category)) {
                        this.modal.createContract.category = categoryList[0] || this.modal.createContract.category;
                    }
                } else {
                    this.sendNotification('error', this.t('notifications.error'), this.t('notifications.ranks_not_updated'));
                }
                this.onCancelModal();
            });
        },
        addSettingRank() {
            if (!Array.isArray(this.modal.settings)) {
                this.modal.settings = [];
            }
            const missionType = (arguments[0] === 'prop') ? 'prop' : 'vehicle';
            const typeRows = this.modal.settings.filter((rank) => (rank.missionType || 'vehicle') === missionType);
            const index = typeRows.length + 1;
            this.modal.settings.push({
                name: `N${index}`,
                missionType,
                sortOrder: index,
                xp: 0,
                percentage: 0,
                tries: 0,
                fails: 0,
                max: 0,
                minCops: 0,
                hackxp: 0
            });
            this.normalizeTypeSortOrders(missionType);
        },
        getSettingRowsByType(missionType) {
            return (this.modal.settings || []).filter((rank) => (rank.missionType || 'vehicle') === missionType);
        },
        normalizeTypeSortOrders(missionType) {
            const rows = this.getSettingRowsByType(missionType)
                .sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
            for (let i = 0; i < rows.length; i++) {
                rows[i].sortOrder = i + 1;
            }
        },
        moveSettingRankByType(missionType, index, direction) {
            const rows = this.getSettingRowsByType(missionType)
                .sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
            const next = index + (direction === 'up' ? -1 : 1);
            if (next < 0 || next >= rows.length) return;
            const currentRow = rows[index];
            rows[index] = rows[next];
            rows[next] = currentRow;
            for (let i = 0; i < rows.length; i++) {
                rows[i].sortOrder = i + 1;
            }
        },
        removeSettingRankByType(missionType, index) {
            const rows = this.getSettingRowsByType(missionType)
                .sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
            if (rows.length <= 1) return;
            const target = rows[index];
            if (!target) return;
            const pos = this.modal.settings.indexOf(target);
            if (pos >= 0) {
                this.modal.settings.splice(pos, 1);
            }
            this.normalizeTypeSortOrders(missionType);
        },
        onSettingMissionTypeChange(item, missionType) {
            if (!item) return;
            item.missionType = missionType === 'prop' ? 'prop' : 'vehicle';
            this.normalizeTypeSortOrders('vehicle');
            this.normalizeTypeSortOrders('prop');
        },
        setSettingsViewType(type) {
            this.settingsViewType = type === 'prop' ? 'prop' : 'vehicle';
        },
        moveSettingRank(index, direction) {
            if (!Array.isArray(this.modal.settings)) return;
            const next = index + (direction === 'up' ? -1 : 1);
            if (next < 0 || next >= this.modal.settings.length) return;
            const current = this.modal.settings[index];
            this.$set(this.modal.settings, index, this.modal.settings[next]);
            this.$set(this.modal.settings, next, current);
            for (let i = 0; i < this.modal.settings.length; i++) {
                this.modal.settings[i].sortOrder = i + 1;
            }
        },
        removeSettingRank(index) {
            if (!Array.isArray(this.modal.settings)) return;
            if (this.modal.settings.length <= 1) return;
            this.modal.settings.splice(index, 1);
            for (let i = 0; i < this.modal.settings.length; i++) {
                this.modal.settings[i].sortOrder = i + 1;
            }
        },

        /*  Los avisos de la tablet salen por los de Origen (origen_notify),
            como en el resto del servidor (08/10): antes la tablet pintaba
            los suyos encima de la cabecera. Lua contesta `false` si
            origen_notify no esta, y entonces se pinta el de casa. */
        sendNotification(type, title, message) {
            this.fetchEvent('notificar', { type: type, title: title, message: message })
                .then((ok) => { if (ok !== true) this.avisoDeCasa(type, title, message); })
                .catch(() => this.avisoDeCasa(type, title, message));
        },
        avisoDeCasa(type, title, message) {
            this.notifications.push({

                type: type, // success, error, info
                title: title,
                message: message,
            });
            setTimeout(() => {
                this.notifications.shift();
            }, 3000);
        },
        playIncomingContractSound() {
            try {
                const AudioCtx = window.AudioContext || window.webkitAudioContext;
                if (!AudioCtx) return;
                const ctx = new AudioCtx();
                const now = ctx.currentTime;
                const playTone = (freq, start, duration, gainValue) => {
                    const osc = ctx.createOscillator();
                    const gain = ctx.createGain();
                    osc.type = 'triangle';
                    osc.frequency.setValueAtTime(freq, start);
                    gain.gain.setValueAtTime(0.0001, start);
                    gain.gain.exponentialRampToValueAtTime(gainValue, start + 0.02);
                    gain.gain.exponentialRampToValueAtTime(0.0001, start + duration);
                    osc.connect(gain);
                    gain.connect(ctx.destination);
                    osc.start(start);
                    osc.stop(start + duration + 0.02);
                };
                playTone(640, now, 0.16, 0.05);
                playTone(820, now + 0.18, 0.2, 0.045);
            } catch (_) {}
        },
        closeIncomingContractPopup() {
            if (this.incomingContractPopup.timeoutHandle) {
                clearTimeout(this.incomingContractPopup.timeoutHandle);
                this.incomingContractPopup.timeoutHandle = null;
            }
            if (this.incomingContractPopup.progressHandle) {
                clearInterval(this.incomingContractPopup.progressHandle);
                this.incomingContractPopup.progressHandle = null;
            }
            if (this.incomingContractPopup.mouseEnabled) {
                this.incomingContractPopup.mouseEnabled = false;
                this.fetchEvent('SetIncomingPopupFocus', { state: false });
            }
            this.incomingContractPopup.remainingMs = this.incomingContractPopup.durationMs;
            this.incomingContractPopup.lastTickAt = 0;
            this.incomingContractPopup.progress = 100;
            this.incomingContractPopup.visible = false;
            this.incomingContractPopup.contract = null;
        },
        showIncomingContractPopup(contract) {
            this.closeIncomingContractPopup();
            this.incomingContractPopup.contract = { ...contract };
            this.incomingContractPopup.visible = true;
            this.incomingContractPopup.startedAt = Date.now();
            this.incomingContractPopup.remainingMs = this.incomingContractPopup.durationMs;
            this.incomingContractPopup.lastTickAt = Date.now();
            this.incomingContractPopup.progress = 100;
            this.playIncomingContractSound();
            this.incomingContractPopup.progressHandle = setInterval(() => {
                if (!this.incomingContractPopup.visible) return;
                if (this.incomingContractPopup.mouseEnabled) {
                    this.incomingContractPopup.lastTickAt = Date.now();
                    return;
                }

                const now = Date.now();
                const delta = Math.max(0, now - (this.incomingContractPopup.lastTickAt || now));
                this.incomingContractPopup.lastTickAt = now;
                this.incomingContractPopup.remainingMs = Math.max(0, this.incomingContractPopup.remainingMs - delta);
                this.incomingContractPopup.progress = Math.max(
                    0,
                    Math.min(100, Math.round((this.incomingContractPopup.remainingMs / this.incomingContractPopup.durationMs) * 100))
                );

                if (this.incomingContractPopup.remainingMs <= 0) {
                    this.closeIncomingContractPopup();
                }
            }, 50);
        },
        onToggleIncomingPopupMouse() {
            if (!this.incomingContractPopup.visible || !this.incomingContractPopup.contract) return;
            const nextState = !this.incomingContractPopup.mouseEnabled;
            this.incomingContractPopup.mouseEnabled = nextState;
            this.incomingContractPopup.lastTickAt = Date.now();
            this.fetchEvent('SetIncomingPopupFocus', { state: nextState });
            this.sendNotification(
                'info',
                this.t('notifications.info'),
                nextState
                    ? 'Cursor activado para responder al encargo'
                    : 'Cursor oculto'
            );
        },
        onIncomingContractDecision(action) {
            const popupContract = this.incomingContractPopup.contract;
            if (!popupContract) return;
            const queueIndex = this.mainBoosting.contracts.findIndex((contract) => String(contract.id) === String(popupContract.id));
            const selectedContract = queueIndex >= 0
                ? { ...this.mainBoosting.contracts[queueIndex], index: queueIndex }
                : { ...popupContract, index: queueIndex };

            if (action === 'buy') {
                selectedContract.uniqueID = this.randomID();
                this.triggerCallback('origen_boosting:server:BuyContract', selectedContract).then((cb) => {
                    if (cb === true) {
                        this.mainBoosting.profile.coins -= selectedContract.price;
                        if (queueIndex >= 0) {
                            this.mainBoosting.contracts.splice(queueIndex, 1);
                        }
                        this.mainBoosting.savedContracts.push(selectedContract);
                        this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_bought'));
                    } else {
                        this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_bought'));
                    }
                });
            } else {
                this.triggerCallback('origen_boosting:server:DeclineContract', { id: selectedContract.id }).then((cb) => {
                    if (cb === true) {
                        if (queueIndex >= 0) {
                            this.mainBoosting.contracts.splice(queueIndex, 1);
                        }
                        this.sendNotification('success', this.t('notifications.success'), this.t('notifications.contract_declined'));
                    } else {
                        this.sendNotification('error', this.t('notifications.error'), this.t('notifications.contract_not_declined'));
                    }
                });
            }

            this.closeIncomingContractPopup();
        },
        onToggleDuty() {
            this.mainBoosting.onDuty = !this.mainBoosting.onDuty;
            this.triggerCallback('origen_boosting:server:SetDuty', { state: this.mainBoosting.onDuty });
            this.sendNotification('success', this.t('notifications.success'), this.mainBoosting.onDuty ? this.t('notifications.enter_duty') : this.t('notifications.exit_duty'));
        },
        onClickSound() {
            return;
        },
        onHoverSound() {
            return;
        },
        isSelfRankingUser(user) {
            if (!user || !this.mainBoosting.profile.username) return false;
            return String(user.name || '').toLowerCase() === String(this.mainBoosting.profile.username).toLowerCase();
        },
        getContractDescription(item) {
            if (item && item.description && String(item.description).trim() !== '') {
                return String(item.description).trim();
            }
            const isObjectMission = ((item && item.__type) || String(item && item.category || '').toUpperCase()) === 'OBJETO' || item?.missionType === 'prop';
            if (isObjectMission) {
                return 'Infíltrate en la zona, asegura el objetivo y extrae el paquete sin perder el control de la operación.';
            }
            return 'Localiza el vehículo marcado, neutraliza cualquier resistencia y entrégalo antes de que expire el rastreo.';
        }
    },
    computed: {
        // El riel sale con el menu del jugador; la gestion va a pantalla completa.
        rielPuesto() {
            return this.visible && !this.createMenu.visible;
        },
        rielSecciones() {
            const mb = this.mainBoosting;
            return [
                { id: 'contratos', icon: 'lucide:file-stack', label: 'Contratos', brocha: (mb.onDuty ? 'Esperando encargo' : 'Encargos frescos'), n: mb.contracts.length },
                { id: 'cartera', icon: 'lucide:folder-open', label: 'Cartera', brocha: 'Lo que es tuyo', n: mb.savedContracts.length },
                { id: 'mercado', icon: 'lucide:gavel', label: 'Mercado', brocha: 'Compra y vende', n: this.market.list.length },
                { id: 'perfil', icon: 'lucide:user-round', label: 'Perfil', brocha: 'Tu ficha', n: 0 },
                { id: 'ranking', icon: 'lucide:trophy', label: 'Ranking', brocha: 'La clasificación', n: 0 },
                { id: 'movimientos', icon: 'lucide:history', label: 'Movimientos', brocha: 'Lo que has hecho', n: mb.contractHistory.length },
            ];
        },
        rielSeccion() {
            return this.rielSecciones.find((s) => s.id === this.vistaCentro) || this.rielSecciones[0];
        },
        /*  En grande la ficha va siempre a la izquierda, asi que «Perfil»
            deja de ser una seccion: no sale en las pestañas y, si era la
            encendida, a la derecha se ven los contratos. */
        vistaCentro() {
            return (this.riel.ancho && this.riel.vista === 'perfil') ? 'contratos' : this.riel.vista;
        },
        pestanas() {
            return this.riel.ancho ? this.rielSecciones.filter((s) => s.id !== 'perfil') : this.rielSecciones;
        },
        displayQueueContracts() {
            return (this.mainBoosting.contracts || []).map((item) => ({
                ...item,
                __demo: false,
                __type: ((item.missionType === 'prop') || (String(item.category || '').toLowerCase().includes('obj'))) ? 'OBJETO' : 'VEHÍCULO',
            }));
        },
        displaySavedContracts() {
            return (this.mainBoosting.savedContracts || []).map((item) => ({
                ...item,
                __demo: false,
                __type: ((item.missionType === 'prop') || (String(item.category || '').toLowerCase().includes('obj'))) ? 'OBJETO' : 'VEHÍCULO',
            }));
        },
        playerStats() {
            return {
                completed: this.mainBoosting.contractHistory.length,
                started: this.mainBoosting.savedContracts.filter(contract => contract.started).length
            };
        },
        precioMedioContratos() {
            const l = this.createMenu.list;
            if (!l.length) return 0;
            return Math.round(l.reduce((a, c) => a + (Number(c.price) || 0), 0) / l.length);
        },
        filteredContracts() {
            const search = this.createMenu.search.toLowerCase();
            return this.createMenu.list.filter(item => {
                const labelMatch = item.label.toLowerCase().startsWith(search);
                const contractType = (item.objectiveType || item.missionType || 'vehicle') === 'prop' ? 'prop' : 'vehicle';
                const typeMatch = this.createMenu.typeFilter === 'all' || this.createMenu.typeFilter === contractType;
                return labelMatch && typeMatch;
            });
        },
        /*  Las categorias de la clasificacion (08/10). Antes la lista salia
            en el orden del servidor y solo se veian los OGN: uno con 24 OGN
            aparecia por debajo de varios con 0. */
        rankingCategorias() {
            return [
                { id: 'ogn', label: 'OGN', unidad: 'OGN', de: (u) => Number(u.ogn_earned) || 0 },
                { id: 'completados', label: 'Completados', unidad: 'hechos', de: (u) => Number(u.completed) || 0 },
                { id: 'exito', label: 'Éxito', unidad: '%', de: (u) => Number(u.success_rate) || 0 },
                { id: 'vehiculos', label: 'Vehículos', unidad: 'XP', de: (u) => Number(u.experience_vehicle || u.experience) || 0 },
                { id: 'objetos', label: 'Objetos', unidad: 'XP', de: (u) => Number(u.experience_prop) || 0 },
            ];
        },
        rankingCategoria() {
            return this.rankingCategorias.find((c) => c.id === this.ranking.categoria) || this.rankingCategorias[0];
        },
        filteredRanking() {
            const search = this.ranking.search.toLowerCase();
            const de = this.rankingCategoria.de;
            // Copia antes de ordenar (sort cambia la lista del sitio), y a
            // igualdad manda quien mas ha completado.
            return (this.ranking.list || [])
                .filter((item) => String(item.name || '').toLowerCase().includes(search))
                .slice()
                .sort((a, b) => (de(b) - de(a)) || ((Number(b.completed) || 0) - (Number(a.completed) || 0)));
        },
        vehicleSettingsRows() {
            return this.getSettingRowsByType('vehicle')
                .sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
        },
        propSettingsRows() {
            return this.getSettingRowsByType('prop')
                .sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0));
        },
        activeSettingsRows() {
            return this.settingsViewType === 'prop' ? this.propSettingsRows : this.vehicleSettingsRows;
        },
        rankingProgressPercent() {
            const currentXp = Number(this.mainBoosting.profile.currentLevel.xp) || 0;
            const requiredXp = Number(this.mainBoosting.profile.nextLevel.requiredxp) || 0;
            if (requiredXp <= 0) return 100;
            return Math.max(0, Math.min(100, Math.round((currentXp / requiredXp) * 100)));
        },
        vehicleRankProgress() {
            return this.getRankProgress('vehicle');
        },
        propRankProgress() {
            return this.getRankProgress('prop');
        },
        filteredVehicles() {
            const search = (this.createMenu.selects.vehicleQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.vehicles;
            return this.createMenu.vehicles.filter(vehicle => String(vehicle).toLowerCase().includes(search));
        },
        filteredProps() {
            const search = (this.createMenu.selects.propQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.props;
            return this.createMenu.props.filter(prop => String(prop).toLowerCase().includes(search));
        },
        filteredPeds() {
            const search = (this.createMenu.selects.pedQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.peds;
            return this.createMenu.peds.filter(ped => String(ped).toLowerCase().includes(search));
        },
        filteredWeapons() {
            const search = (this.createMenu.selects.npcWeaponQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.weapons;
            return this.createMenu.weapons.filter(weapon => String(weapon).toLowerCase().includes(search));
        },
        filteredAccessModes() {
            const search = (this.createMenu.selects.accessModeQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.accessModes;
            return this.createMenu.accessModes.filter(mode => this.getAccessModeLabel(mode).toLowerCase().includes(search));
        },
        filteredMinigames() {
            const search = (this.createMenu.selects.minigameQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.minigames;
            return this.createMenu.minigames.filter(minigame => {
                const key = String(minigame).toLowerCase();
                const label = String(this.getMinigameLabel(minigame)).toLowerCase();
                return key.includes(search) || label.includes(search);
            });
        },
        filteredMinigameDifficulties() {
            const search = (this.createMenu.selects.minigameDifficultyQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.minigameDifficulties;
            return this.createMenu.minigameDifficulties.filter(diff => {
                const key = String(diff).toLowerCase();
                const label = String(this.getMinigameDifficultyLabel(diff)).toLowerCase();
                return key.includes(search) || label.includes(search);
            });
        },
        filteredSpawnPoints() {
            const search = (this.createMenu.selects.spawnPointQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.spawnPoints;
            return this.createMenu.spawnPoints.filter((point, idx) => this.getPointOptionLabel(point, idx, 'spawn').toLowerCase().includes(search));
        },
        filteredDeliveryPoints() {
            const search = (this.createMenu.selects.deliveryPointQuery || '').toLowerCase().trim();
            if (!search) return this.createMenu.deliveryPoints;
            return this.createMenu.deliveryPoints.filter((point, idx) => this.getPointOptionLabel(point, idx, 'delivery').toLowerCase().includes(search));
        },
        countdownTime() {
            const minutes = Math.floor(this.countdown.time / 60);
            const remainingSeconds = this.countdown.time % 60;
            return `${minutes < 10 ? '0' : ''}${minutes}:${remainingSeconds < 10 ? '0' : ''}${remainingSeconds}`;
        },
    },
    mounted() {
        this.listener = window.addEventListener('message', (event) => {
            const item = event.data;
            if (item && item.accion === 'origen:marca:puesta') this.marca = item.marca || 'origen';
            switch (item.action) {
                case "openCad":
                    const openTarget = item.openTarget || 'mainBoosting';
                    const canOpenAdmin = !!(item.pData && item.pData.hasAdmin);

                    this.mainMenu.visible = false;
                    this.mainBoosting.visible = openTarget !== 'createMenu';
                    this.createMenu.visible = openTarget === 'createMenu' && canOpenAdmin;
                    this.ranking.visible = false;
                    this.market.visible = false;
                    this.modal.id = null;
                    // Sin perfil todavia: se pide el nombre nada mas abrir. Va DESPUES
                    // de limpiar el dialogo; antes iba arriba y la linea anterior lo
                    // cerraba al momento, asi que nunca llegaba a verse.
                    if (item.data == null) this.openNameModal(true);
                    this.loadBoostingData(item.data);
                    this.loadOffers(item.offers);
                    this.rielCompartido = Array.isArray(item.riel) ? item.riel : [];
                    if (this.riel.vista === 'cola') this.riel.vista = 'contratos';
                    this.mainBoosting.profile.citizen = item.citizen;
                    this.mainBoosting.profile.source = String(item.source);
                    this.mainBoosting.profile.coins = item.pData.coins;
                    this.mainBoosting.boostingLeaderboard = item.clasifications;
                    this.ranking.list = item.clasifications;

                    if (openTarget !== 'createMenu') this.rielAplicar();
                    if (openTarget === 'createMenu') {
                        if (canOpenAdmin) {
                            this.updateBoostingManageList();
                        } else {
                            this.createMenu.visible = false;
                            this.rielAplicar();
                            this.sendNotification('error', this.t('notifications.error'), 'No tienes permisos para abrir la gestión de contratos');
                        }
                    }
                    this.toggleMenu(true);
                    this.initInterval();
                    break;
                case "closeCad":
                    if (this.serverInterval) {
                        clearInterval(this.serverInterval);
                        this.serverInterval = null;
                    }
                    this.closeIncomingContractPopup();
                    this.toggleMenu(false);
                    break;
                case "toggleIncomingPopupCursor":
                    this.onToggleIncomingPopupMouse();
                    break;
                case "giveContract":
                    item.data.time = new Date(item.data.time * 1000).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false });
                    item.data.remainingTime = Number(item.data.remainingTime || 1800);
                    item.data.remainingCountdown = this.convertSecondsToTime(item.data.remainingTime);
                    this.mainBoosting.contracts.push(item.data);
                    this.showIncomingContractPopup(item.data);
                    if (!this.mainBoosting.visible) {
                        this.sendNotification('info', this.t('notifications.info'), this.t('notifications.contract_received'));
                    }
                    break;
                case "saveContract":
                    this.mainBoosting.savedContracts.push(item.data);
                    break;
                case "receiverTempOffer":
                    this.openModal('contractOffer', item.data);
                    break;
                case "removeContract":
                    var index = this.mainBoosting.savedContracts.findIndex(contract => contract.uniqueID === item.uniqueID);
                    this.mainBoosting.savedContracts.splice(index, 1);
                    this.mainBoosting.profile.coins += item.price;
                    this.sendNotification('success', this.t('notifications.info'), item.notify);
                    break;
                case "updateHacks":
                    this.trackerUI.visible = item.data;
                    this.trackerUI.trackers = item.data || 0;
                    break;
                case "offerExpired":
                    var index = this.mainBoosting.savedContracts.findIndex(contract => contract.uniqueID === item.uniqueID);
                    this.$set(this.mainBoosting.savedContracts, index, {...this.mainBoosting.savedContracts[index], offered: false});
                    this.sendNotification('info', this.t('notifications.info'), item.notify);
                    break;
                case "removeActiveOffer":
                    var index = this.market.list.findIndex(contract => contract.id === item.id);
                    if (item.isSeller) {
                        let contract = this.mainBoosting.savedContracts.findIndex(contract => contract.uniqueID === item.id);
                        this.mainBoosting.savedContracts.splice(contract, 1);
                        this.mainBoosting.profile.coins += this.market.list[index].data.price;
                    } else if (item.isBuyer) {
                        this.mainBoosting.profile.coins -= this.market.list[index].data.price;
                    }
                    this.market.list.splice(index, 1);
                    break
                case "addActiveOffer":
                    this.market.list.push({
                        id: item.data.id,
                        remainingTime: item.data.remainingTime,
                        seller: item.data.seller,
                        data: item.data.data,
                    })
                    break;
                case "receiveCoins":
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.coins_received', item.amount));
                    this.mainBoosting.profile.coins += item.amount;
                    break
                case "registerBonus":
                    this.sendNotification('success', this.t('notifications.success'), this.t('notifications.register_bonus', item.amount));
                    this.mainBoosting.profile.coins += item.amount;
                    break
                case "updateXP":
                    if (item.data && (item.data.rankVehicle || item.data.rank)) {
                        const rank = item.data.rankVehicle || item.data.rank;
                        this.mainBoosting.profile.totalExperience = Number(item.data.totalExperience) || 0;
                        this.mainBoosting.profile.totalExperienceVehicle = Number(item.data.totalExperienceVehicle || this.mainBoosting.profile.totalExperienceVehicle || 0);
                        this.mainBoosting.profile.totalExperienceProp = Number(item.data.totalExperienceProp || this.mainBoosting.profile.totalExperienceProp || 0);
                        this.mainBoosting.profile.currentLevel.rank = rank.actualRank.name;
                        this.mainBoosting.profile.currentLevel.xp = rank.actualRank.xp;
                        this.mainBoosting.profile.nextLevel.rank = rank.nextRank ? rank.nextRank.name : null;
                        this.mainBoosting.profile.nextLevel.requiredxp = rank.nextRank ? rank.nextRank.xp : 0;
                        this.mainBoosting.profile.currentLevelVehicle = { ...this.mainBoosting.profile.currentLevel };
                        this.mainBoosting.profile.nextLevelVehicle = { ...this.mainBoosting.profile.nextLevel };
                    }
                    if (item.data && item.data.rankProp) {
                        const rankProp = item.data.rankProp;
                        this.mainBoosting.profile.currentLevelProp.rank = rankProp.actualRank.name;
                        this.mainBoosting.profile.currentLevelProp.xp = rankProp.actualRank.xp;
                        this.mainBoosting.profile.nextLevelProp.rank = rankProp.nextRank ? rankProp.nextRank.name : null;
                        this.mainBoosting.profile.nextLevelProp.requiredxp = rankProp.nextRank ? rankProp.nextRank.xp : 0;
                    }
                    break;
                case "hackerXP":
                    if (item.amount && this.mainBoosting.profile.nextLevel.requiredxp > 0) {
                        this.mainBoosting.profile.currentLevel.xp = Math.min(
                            (this.mainBoosting.profile.currentLevel.xp || 0) + item.amount,
                            this.mainBoosting.profile.nextLevel.requiredxp
                        );
                        this.mainBoosting.profile.totalExperience = (this.mainBoosting.profile.totalExperience || 0) + item.amount;
                        this.mainBoosting.profile.totalExperienceVehicle = (this.mainBoosting.profile.totalExperienceVehicle || 0) + item.amount;
                        this.mainBoosting.profile.currentLevelVehicle = { ...this.mainBoosting.profile.currentLevel };
                        this.mainBoosting.profile.nextLevelVehicle = { ...this.mainBoosting.profile.nextLevel };
                    }
                    break;
            }
        });
        window.addEventListener('keydown', (event) => {
            // Escribiendo, la I es una letra; con la tablet abierta el raton ya
            // es suyo y conmutarlo desde aqui se lo quitaria.
            if (['INPUT', 'TEXTAREA'].includes(event.target.tagName) || this.visible) return;
            if ((event.key === 'i' || event.key === 'I') && this.incomingContractPopup.visible) {
                this.onToggleIncomingPopupMouse();
            }
        });

        window.addEventListener('keydown', this.handleKeyDown);

        this.translationSystem();
        this.fetchEvent('GetConfig', {}).then((cb) => {
            const rankSettings = cb.rankSettings || [];
            if (rankSettings.length > 0) {
                this.createMenu.vehicleCategories = rankSettings.filter((rank) => (rank.missionType || 'vehicle') === 'vehicle').sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0)).map((rank) => rank.name);
                this.createMenu.missionCategories = rankSettings.filter((rank) => (rank.missionType || 'vehicle') === 'prop').sort((a, b) => (Number(a.sortOrder) || 0) - (Number(b.sortOrder) || 0)).map((rank) => rank.name);
                this.createMenu.categories = [...this.createMenu.vehicleCategories];
            } else {
                this.createMenu.categories = cb.categories.map(category => category.name);
                this.createMenu.vehicleCategories = [...this.createMenu.categories];
                this.createMenu.missionCategories = cb.missionCategories || this.createMenu.missionCategories;
            }
            Object.assign(this.createMenu.difficulty, cb.difficulties);
            this.createMenu.weapons = cb.weapons;
            this.createMenu.vehicles = cb.vehicles || [];
            this.createMenu.props = cb.props || [];
            this.createMenu.peds = cb.peds || [];
            this.createMenu.spawnPoints = cb.spawnPoints || [];
            this.createMenu.deliveryPoints = cb.deliveryPoints || [];
            this.createMenu.minigames = cb.minigames || [];
            this.createMenu.minigameDifficulties = cb.minigameDifficulties || ['auto', 'easy', 'medium', 'hard', 'extreme'];
            this.modal.createContract.vehicle = this.createMenu.vehicles[0] || '';
            this.modal.createContract.objectiveModel = this.createMenu.props[0] || this.createMenu.peds[0] || '';
            this.modal.createContract.category = this.getCurrentCategoryList()[0] || this.modal.createContract.category;
            this.modal.createContract.npcWeapon = this.createMenu.weapons[0] || '';
            this.modal.createContract.minigame = this.createMenu.minigames[0] || '';
            this.modal.createContract.minigameDifficulty = 'auto';
            this.modal.createContract.spawnPointId = '';
            this.modal.createContract.deliveryPointId = '';
            this.mainMenu.transference = cb.transference;
            this.refreshEditorPoints();
        });
    },
    beforeDestroy() {
        window.removeEventListener('message', this.listener);
        window.removeEventListener('keydown', this.handleKeyDown);
    },
});