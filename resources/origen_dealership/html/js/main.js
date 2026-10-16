/* ══════════════════════════════════════════════════════════════════════
   El desplegable de la tablet, para Vue 2.

   Nunca un <select> nativo: Chromium lo pinta con el tema de Windows —claro,
   en ingles y con la fuente del sistema—. Esta pieza es la misma que usan los
   recursos de Vue 3 (components/ogn/OgnSelect.vue), con las mismas clases de
   ogn.css. Ver la skill origen-tablet.

   La lista se cuelga del propio control y no de <body>: aqui no hay ninguna
   caja con `overflow: hidden` que la recorte, y teletransportarla en Vue 2
   pide un plugin.
   ══════════════════════════════════════════════════════════════════════ */
Vue.component('ogn-select', {
    props: {
        value: { default: '' },
        options: { type: Array, default: function () { return []; } },
        label: { type: String, default: '' },
        placeholder: { type: String, default: 'Elige' },
    },

    data: function () {
        return { abierto: false };
    },

    computed: {
        elegido: function () {
            var self = this;
            var hallado = this.options.find(function (o) { return o.value === self.value; });
            return hallado ? hallado.label : this.placeholder;
        },
    },

    methods: {
        alternar: function () {
            this.abierto = !this.abierto;
        },

        elegir: function (opcion) {
            this.$emit('input', opcion.value);
            this.abierto = false;
        },

        /* Se cierra al pulsar fuera. En `mousedown` y no en `click`: con click,
           elegir una opcion de otro desplegable abierto cerraba este despues de
           que el otro ya hubiera reaccionado. */
        fuera: function (ev) {
            if (!this.abierto) return;
            if (this.$el.contains(ev.target)) return;
            this.abierto = false;
        },
    },

    mounted: function () {
        document.addEventListener('mousedown', this.fuera);
    },

    beforeDestroy: function () {
        document.removeEventListener('mousedown', this.fuera);
    },

    template: [
        '<div class="ogn-select">',
        '  <span class="ogn-select__label" v-if="label">{{ label }}</span>',
        '  <button type="button" class="ogn-select__control"',
        '    :class="{ \'ogn-select__control--on\': abierto }" @click="alternar">',
        '    <span class="ogn-select__value">{{ elegido }}</span>',
        '    <i data-lucide="chevron-down"></i>',
        '  </button>',
        '  <div class="ogn-select__panel" v-if="abierto">',
        '    <button type="button" class="ogn-select__option" v-for="o in options" :key="String(o.value)"',
        '      :class="{ \'ogn-select__option--on\': o.value === value }" @click="elegir(o)">',
        '      {{ o.label }}',
        '    </button>',
        '    <span class="ogn-select__vacio" v-if="!options.length">Sin opciones</span>',
        '  </div>',
        '</div>',
    ].join('\n'),
});

const app = new Vue({
    el: '#app',
    data: function () {
        return {
            marca: document.documentElement.dataset.marca || 'origen',
            translations: {},
            translationsLoaded: false,
            modals: [],
            currentModal: null,
            visible: false,
            currentEditingVehicle: null,
            dealershipInfo: null,
            cameraControls: {
                zoom: 1.0,
                minZoom: 0.66,
                maxZoom: 3.0,
                rotation: 0,
                height: 1.5,
                minHeight: -2.0,
                maxHeight: 5.0,
                isDragging: false,
                lastX: 0,
                lastY: 0,
                sensitivity: 0.05,
                heightSensitivity: 0.02,
                autoRotateEnabled: true,
                autoRotateSpeed: 12.0,
                hasManualControl: false
            }, testDriving: false, currentEditingCategory: null,
            autoRotateFrameId: null,
            searchQuery: '',
            selectedCategory: 'all_categories',
            selectedVehicle: null,
            /* La columna del concesionario (index.html, .dp): pestaña abierta,
               buscador, la firma de compra con su método y los dos colores
               que se ven en la muestra. */
            dpTab: 'list',
            dpBusqueda: '',
            dpFirma: false,
            dpMetodo: null,
            dpColores: { primario: '#c40b78', secundario: '#7a034a' },
            comprando: false,
            currentVehiclePrice: 0,
            currentVehicleFinancing: false,
            testDriveTimeRemaining: 0,
            testDriveTimer: null,
            sortBy: 'name',
            sortOrder: 'asc',
            priceFilter: {
                min: null,
                max: null,
                active: false
            },
            financingConfig: {
                enabled: true,
                timeUnit: 'days',
                maxPeriods: 7,
                interestRate: 5.0
            }, financingModal: {
                visible: false,
                vehicleName: '',
                vehiclePrice: 0,
                initialPayment: 0,
                options: [],
                selectedOption: null
            }, addVehicleModal: {
                visible: false,
                searchQuery: '',
                selectedVehicle: null,
                isEditing: false,
                editingVehicle: null,
                form: {
                    category: '',
                    model: '',
                    label: '',
                    price: 0,
                    xp: 0,
                    image: '',
                    class: 'A',
                    financing: false,
                    paymentMethods: {
                        cash: false,
                        bank: false,
                        xp: false,
                        company: false
                    },
                    prices: {
                        cash: 0,
                        bank: 0,
                        xp: 0,
                        company: 0
                    },
                    stockEnabled: false,
                    stock: 10
                }
            },
            exhibitorConfigModal: {
                visible: false,
                currentExhibitorIndex: null,
                selectedVehicles: [],
                availableVehicles: [],
                searchQuery: '',
                fixedVehicleModel: '',
                rotateEnabled: false,
                interactable: true,
                allowPurchase: true,
                allowTestDrive: true
            },
            dealershipMenu: {
                visible: false,
                currentVehicleLabel: null,
                currentVehicleStats: [],
                dealershipStock: {
                    sports_classics: {
                        label: 'Sports Classics',
                        categoryStock: []
                    }
                }
            },
            filteredVehicles: [],
            creatorMode: {
                active: false,
                stages: [],
                currentStage: '',
                activeTab: 'cars_exhibitor',
                tabs: [
                    { id: 'cars_exhibitor', labelKey: 'ui.admin_panel.exhibition_tab', icon: 'car', active: true },
                    { id: 'car_testdrive', labelKey: 'ui.admin_panel.test_drive_tab', icon: 'traffic-cone', active: false },
                    { id: 'car_delivery', labelKey: 'ui.admin_panel.delivery_tab', icon: 'package', active: false },
                    { id: 'car_preview', labelKey: 'ui.admin_panel.preview_tab', icon: 'eye', active: false },
                    { id: 'npcs', labelKey: 'ui.admin_panel.npcs_tab', icon: 'user', active: false },
                    { id: 'markers', labelKey: 'ui.admin_panel.markers_tab', icon: 'map-pin', active: false }
                ],
                points: {
                    cars_exhibitor: [],
                    car_testdrive: [],
                    car_delivery: [],
                    car_preview: [],
                    npcs: [],
                    markers: []
                }
            },
            adminPanel: {
                visible: false,
                tabs: {
                    'stock': {
                        id: 'stock',
                        name: 'Concesionarios',
                        icon: 'box',
                        active: true,
                    },
                    'map': {
                        id: 'map',
                        name: 'Mapa',
                        icon: 'map',
                        active: false,
                    }
                },
                activeDealershipTab: 'general',
                dealershipTabs: [
                    { id: 'general', label: this.T ? this.T('ui.admin.general') : 'General', icon: 'settings', active: true },
                    { id: 'vehicles', label: this.T ? this.T('ui.admin.vehicles') : 'Vehículos', icon: 'car', active: false },
                    { id: 'locations', label: this.T ? this.T('ui.admin.locations') : 'Ubicaciones', icon: 'map-pin', active: false }
                ],
                activeLocationTab: 'cars_exhibitor',
                locationTabs: [
                    { id: 'cars_exhibitor', labelKey: 'ui.admin_panel.exhibition_tab', icon: 'car', active: true },
                    { id: 'car_testdrive', labelKey: 'ui.admin_panel.test_drive_tab', icon: 'traffic-cone', active: false },
                    { id: 'car_delivery', labelKey: 'ui.admin_panel.delivery_tab', icon: 'package', active: false },
                    { id: 'car_preview', labelKey: 'ui.admin_panel.preview_tab', icon: 'eye', active: false },
                    { id: 'npcs', labelKey: 'ui.admin_panel.npcs_tab', icon: 'user', active: false },
                    { id: 'markers', labelKey: 'ui.admin_panel.markers_tab', icon: 'map-pin', active: false }
                ],
                dealershipManagement: {
                    visible: true,
                    defaultGTAVehicles: [],
                    selectedDealership: undefined,
                    dealerships: [

                    ],
                }
            },
            showFilters: false,
            rightPanelExpanded: false,
            previewEntryPending: false,
            notifications: [],
            dealerCache: {},
            vehiclesReady: true,
            // Las fotos automáticas (client/fotos.lua). `fotos` es la foto de
            // cada modelo según el servidor: { adder: 'https://...' }.
            photoGen: {
                available: false,
                running: false,
                cancelling: false,
                current: 0,
                total: 0,
                model: '',
                single: '',
                fotos: {},
                output: null
            },
            loadingVehicleStats: false,
            expandedCategories: {}, // Objeto para manejar el estado de expansión de categorías
        }
    }, methods: {
        loadTranslations() {
            return new Promise((resolve, reject) => {
                fetch(`https://${GetParentResourceName()}/getTranslations`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({})
                })
                    .then(response => {
                        return response.json();
                    })
                    .then(data => {
                        this.translations = data || {};
                        this.translationsLoaded = true;
                        this.updateAdminPanelTranslations();
                        resolve(this.translations);
                    })
                    .catch(error => {
                        this.translations = {};
                        this.translationsLoaded = false;
                        reject(error);
                    });
            });
        },

        updateAdminPanelTranslations() {
            if (this.translationsLoaded) {
                this.adminPanel.tabs.stock.name = this.T('ui.admin.dealerships');
                this.adminPanel.tabs.map.name = this.T('ui.admin.map');

                this.adminPanel.dealershipTabs[0].label = this.T('ui.admin.general');
                this.adminPanel.dealershipTabs[1].label = this.T('ui.admin.vehicles');
                this.adminPanel.dealershipTabs[2].label = this.T('ui.admin.locations');

                this.dealershipMenu.dealershipStock.sports_classics.label = this.T('ui.admin.sports_classics');
            }
        },

        T(key, ...args) {
            if (!this.translationsLoaded) {
                return key;
            }

            let translation = this.translations['ui.' + key] || this.translations[key];

            if (!translation) {
                if (key.startsWith('ui.')) {
                    translation = this.translations[key.substring(3)];
                }
                if (!translation) {
                    return key;
                }
            }

            if (this.marca === 'nacion' && typeof translation === 'string') {
                translation = translation.replace(/Experienc(?:e|ia)(?: \(XP\))?|(?<!Farm )\bXP\b/g, 'Farm XP');
            }

            if (args.length > 0) {
                let result = translation;
                args.forEach((arg, index) => {
                    result = result.replace('%s', arg).replace(new RegExp(`\\{${index}\\}`, 'g'), arg);
                });
                return result;
            }

            return translation;
        },

        setSortBy(sortType) {
            if (this.sortBy === sortType) {
                this.toggleSortDirection();
            } else {
                this.sortBy = sortType;
                this.sortOrder = 'asc';
            }
        },

        toggleSortDirection() {
            this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
        },

        applyPriceFilter() {
            // Los campos devuelven texto: comparados tal cual, "500" > "10000"
            // es verdad, se daban la vuelta y no salía ningún coche.
            const aNumero = (v) => (v === null || v === '' || isNaN(Number(v))) ? null : Number(v);
            let min = aNumero(this.priceFilter.min);
            let max = aNumero(this.priceFilter.max);

            if (min !== null && max !== null && min > max) {
                [min, max] = [max, min];
            }

            this.priceFilter.min = min;
            this.priceFilter.max = max;
            this.priceFilter.active = (min !== null && min >= 0) || (max !== null && max >= 0);
        },

        clearPriceFilter() {
            this.priceFilter.min = null;
            this.priceFilter.max = null;
            this.priceFilter.active = false;
        },

        saveDealerState() {
            if (!this.dealershipInfo || !this.dealershipInfo.id) return;

            const dealerId = this.dealershipInfo.id;
            this.dealerCache[dealerId] = {
                selectedCategory: this.selectedCategory,
                selectedVehicle: this.selectedVehicle ? this.selectedVehicle.model : null,
                cameraControls: {
                    zoom: this.cameraControls.zoom,
                    rotation: this.cameraControls.rotation,
                    height: this.cameraControls.height
                },
                searchQuery: this.searchQuery,
                sortBy: this.sortBy,
                sortOrder: this.sortOrder,
                priceFilter: { ...this.priceFilter },
                showFilters: this.showFilters,
                timestamp: Date.now()
            };
        },

        loadDealerState() {
            if (!this.dealershipInfo || !this.dealershipInfo.id) return false;

            const dealerId = this.dealershipInfo.id;
            const cachedState = this.dealerCache[dealerId];

            if (cachedState && cachedState.timestamp) {
                const cacheAge = Date.now() - cachedState.timestamp;
                if (cacheAge > 3600000) {
                    delete this.dealerCache[dealerId];
                    return false;
                }

                this.$set(this, 'selectedCategory', cachedState.selectedCategory);
                this.searchQuery = cachedState.searchQuery || '';
                this.sortBy = cachedState.sortBy || 'name';
                this.sortOrder = cachedState.sortOrder || 'asc';
                this.showFilters = cachedState.showFilters || false;

                if (cachedState.priceFilter) {
                    this.priceFilter = { ...cachedState.priceFilter };
                }

                if (cachedState.cameraControls) {
                    this.cameraControls.zoom = cachedState.cameraControls.zoom || 1.0;
                    this.cameraControls.rotation = cachedState.cameraControls.rotation || 0;
                    this.cameraControls.height = cachedState.cameraControls.height || 1.0;
                }

                return true;
            }

            return false;
        },

        findCachedVehicle() {
            if (!this.dealershipInfo || !this.dealershipInfo.id) return null;

            const dealerId = this.dealershipInfo.id;
            const cachedState = this.dealerCache[dealerId];

            if (cachedState && cachedState.selectedVehicle) {
                const category = this.dealershipMenu.dealershipStock[cachedState.selectedCategory];
                if (category && category.categoryStock) {
                    const vehicle = category.categoryStock.find(v => v.model === cachedState.selectedVehicle);
                    if (vehicle) {
                        return { vehicle, category: cachedState.selectedCategory };
                    }
                }

                for (const categoryKey in this.dealershipMenu.dealershipStock) {
                    const category = this.dealershipMenu.dealershipStock[categoryKey];
                    if (category && category.categoryStock) {
                        const vehicle = category.categoryStock.find(v => v.model === cachedState.selectedVehicle);
                        if (vehicle) {
                            return { vehicle, category: categoryKey };
                        }
                    }
                }
            }

            return null;
        },

        selectFirstAvailableVehicle() {
            let firstVehicle = null;
            let firstCategory = null;

            // Se saltan los agotados: dmSelectVehicle no los coge, y si el primero
            // lo estaba no se pedía vista previa ni llegaba nunca previewReady.
            for (const categoryKey in this.dealershipMenu.dealershipStock) {
                const category = this.dealershipMenu.dealershipStock[categoryKey];
                if (category && category.categoryStock && Array.isArray(category.categoryStock) && category.categoryStock.length > 0) {
                    const disponible = category.categoryStock.find(v => !(v.stockEnabled && v.stock <= 0));
                    if (disponible) {
                        firstVehicle = disponible;
                        firstCategory = categoryKey;
                        break;
                    }
                }
            }

            if (firstVehicle) {
                this.$set(this, 'selectedCategory', firstCategory);
                this.dmSelectVehicle(firstVehicle);
            } else {
                this.$set(this, 'selectedVehicle', null);
                this.currentVehicleLabel = null;
            }
        },
        selectVehicleByModel(model) {
            if (!model) {
                this.selectFirstAvailableVehicle();
                return;
            }

            for (const categoryKey in this.dealershipMenu.dealershipStock) {
                const category = this.dealershipMenu.dealershipStock[categoryKey];
                if (!category || !Array.isArray(category.categoryStock)) continue;

                const vehicle = category.categoryStock.find(v => v.model === model);
                if (vehicle) {
                    this.$set(this, 'selectedCategory', categoryKey);
                    this.dmSelectVehicle(vehicle);
                    return;
                }
            }

            this.selectFirstAvailableVehicle();
        },
        initializeCarrouselScroll() {
            this.setupCarrouselScroll();
            setTimeout(() => {
                this.setupCarrouselScroll();
            }, 100);
        }, setupCarrouselScroll() {
            const carrousel = document.querySelector('.vehicle-carrousel');
            if (carrousel && !carrousel.hasAttribute('data-wheel-scroll')) {
                carrousel.setAttribute('data-wheel-scroll', 'true');

                let lastScrollTime = 0;

                carrousel.addEventListener('wheel', (e) => {
                    e.preventDefault();
                    e.stopPropagation();

                    const now = Date.now();
                    if (now - lastScrollTime < 16) return;
                    lastScrollTime = now;

                    const scrollAmount = e.deltaY * 0.6;
                    carrousel.scrollLeft += scrollAmount;

                }, { passive: false });
            }
        },

        fetchEvent: async function (event, data) {
            return fetch(`https://${GetParentResourceName()}/` + event, {

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

        /* ── La columna del concesionario ─────────────────────────────── */

        /* A, S y X van en rosa, B en ámbar y el resto en papel: la chapa dice
           de un vistazo lo buena que es la clase. */
        dpClase(cls) {
            const c = String(cls || '').toUpperCase();
            if (c === 'S' || c === 'A' || c === 'X' || c === 'S+') return 'a';
            if (c === 'B') return 'b';
            return 'c';
        },

        dpSinFoto(ev) {
            if (ev && ev.target) ev.target.style.display = 'none';
        },

        dpNombreTono(hex) {
            const t = this.dpTonos.find((x) => x.hex === String(hex || '').toLowerCase());
            return t ? t.nombre : 'De fábrica';
        },

        /* Precio ↑, Precio ↓, Clase y Nombre, uno detras de otro. */
        dpCiclarOrden() {
            const orden = [['price', 'asc'], ['price', 'desc'], ['class', 'asc'], ['name', 'asc']];
            const i = orden.findIndex(([k, o]) => k === this.sortBy && o === this.sortOrder);
            const [k, o] = orden[(i + 1) % orden.length];
            this.sortBy = k;
            this.sortOrder = o;
        },

        dpAbrirFirma() {
            if (!this.dpPuedeComprar) return;
            const primero = this.dpPago.metodos[0];
            this.dpMetodo = primero ? primero.id : null;
            this.dpFirma = true;
        },

        dpFirmar() {
            if (!this.dpMetodo || this.comprando) return;
            if (this.dpMetodo === 'financing') {
                this.dpFirma = false;
                this.showFinancingModal();
                return;
            }
            const metodo = this.dpMetodo;
            this.dpFirma = false;
            this.purchaseVehicle(metodo);
        },

        /* Salir por el mismo camino que ESC: cierra lo de arriba o el concesionario. */
        dpSalir() {
            this.handleKeyDown({ key: 'Escape' });
        },

        purchaseVehicleModal() {
            if (!this.canPurchaseCurrent) {
                this.notify('error', 'La compra esta desactivada para este coche de exhibicion');
                return;
            }

            const hasFinancing = this.currentVehicleFinancing;
            const vehiclePrice = parseInt(this.currentVehiclePrice) || 0;
            const vehicleXP = this.selectedVehicle ? parseInt(this.selectedVehicle.xp) || 0 : 0;

            const hasPaymentMethodsDefined = this.selectedVehicle && this.selectedVehicle.paymentMethods;

            let paymentMethods;
            let vehiclePrices;

            if (hasPaymentMethodsDefined) {
                paymentMethods = this.selectedVehicle.paymentMethods;
                vehiclePrices = this.selectedVehicle.prices || {
                    cash: vehiclePrice,
                    bank: vehiclePrice,
                    xp: vehicleXP
                };
            } else {
                const hasCashPrice = vehiclePrice > 0;
                const hasXPPrice = vehicleXP > 0;

                paymentMethods = {
                    cash: hasCashPrice,
                    bank: hasCashPrice,
                    xp: hasXPPrice
                };

                vehiclePrices = {
                    cash: vehiclePrice,
                    bank: vehiclePrice,
                    xp: vehicleXP
                };
            }


            const isPaymentMethodValid = (method) => {
                if (!paymentMethods[method]) return false;
                const methodPrice = parseInt(vehiclePrices[method]) || 0;
                return methodPrice >= 0;
            };

            const stockEnabled = this.selectedVehicle.stockEnabled || false;
            const currentStock = stockEnabled ? (this.selectedVehicle.stock || 0) : null;
            const isOutOfStock = stockEnabled && currentStock <= 0;

            const validCashPayment = isPaymentMethodValid('cash') && !isOutOfStock;
            const validBankPayment = isPaymentMethodValid('bank') && !isOutOfStock;
            const validXPPayment = isPaymentMethodValid('xp') && !isOutOfStock;
            const validCompanyPayment = isPaymentMethodValid('company') && !isOutOfStock;


            const onlyXPPayment = validXPPayment && !validCashPayment && !validBankPayment;
            const showFinancing = hasFinancing && this.financingConfig.enabled !== false && !onlyXPPayment && (validCashPayment || validBankPayment);

            let paymentMethodsHTML = '';

            if (validCashPayment) {
                const cashPrice = parseInt(vehiclePrices.cash) || vehiclePrice || 0;
                paymentMethodsHTML += `
                <button class="payment-method-btn cash" onclick="app.purchaseVehicle('cash')">
                    <div class="payment-icon">
                        <i data-lucide="banknote"></i>
                    </div>
                    <div class="payment-info">
                        <span class="payment-name">${this.T('ui.payment_methods.cash')}</span>
                        <span class="payment-desc">$${cashPrice.toLocaleString('de-DE')}</span>
                    </div>
                </button>
            `;
            }

            if (validBankPayment) {
                const bankPrice = parseInt(vehiclePrices.bank) || vehiclePrice || 0;
                paymentMethodsHTML += `
                <button class="payment-method-btn bank" onclick="app.purchaseVehicle('bank')">
                    <div class="payment-icon">
                        <i data-lucide="building-2"></i>
                    </div>
                    <div class="payment-info">
                        <span class="payment-name">${this.T('ui.payment_methods.bank_transfer')}</span>
                        <span class="payment-desc">$${bankPrice.toLocaleString('de-DE')}</span>
                    </div>
                </button>
            `;
            }

            if (validXPPayment) {
                const xpPrice = parseInt(vehiclePrices.xp) || vehicleXP || 0;
                paymentMethodsHTML += `
                <button class="payment-method-btn xp" onclick="app.purchaseVehicle('xp')">
                    <div class="payment-icon">
                        <i data-lucide="star"></i>
                    </div>
                    <div class="payment-info">
                        <span class="payment-name">${this.T('ui.payment_methods.experience')}</span>
                        <span class="payment-desc">${xpPrice} ${this.nombreXP}</span>
                    </div>
                </button>
            `;
            }

            if (showFinancing) {
                paymentMethodsHTML += `
                <button class="payment-method-btn financing" onclick="app.showFinancingModal()">
                    <div class="payment-icon">
                        <i data-lucide="calendar-days"></i>
                    </div>
                    <div class="payment-info">
                        <span class="payment-name">${this.T('ui.payment_methods.financing')}</span>
                        <span class="payment-desc">${this.T('ui.payment_methods.monthly_payments')}</span>
                    </div>
                </button>
            `;
            }

            // validCompanyPayment ya descuenta el «sin stock»: con isPaymentMethodValid
            // el botón de empresa salía también en un coche agotado.
            if (validCompanyPayment) {
                const companyPrice = parseInt(vehiclePrices.company) || vehiclePrice || 0;
                paymentMethodsHTML += `
                <button class="payment-method-btn company" onclick="app.purchaseVehicle('company')">
                    <div class="payment-icon">
                        <i data-lucide="building"></i>
                    </div>
                    <div class="payment-info">
                        <span class="payment-name">${this.T('ui.payment_methods.company')}</span>
                        <span class="payment-desc">$${companyPrice.toLocaleString('de-DE')}</span>
                    </div>
                </button>
            `;
            }

            this.OpenModal(this.T('ui.payment_methods.purchase_vehicle'),
                `
            <div class="purchase-modal-container">
                <!-- Sección de información del vehículo -->
                <div class="vehicle-info-section">
                    <div class="vehicle-header">
                        <div class="vehicle-icon">
                            <i data-lucide="car"></i>
                        </div>
                        <div class="vehicle-details">
                            <h3 class="vehicle-name">${this.currentVehicleLabel}</h3>
                            <p class="vehicle-model">${this.selectedVehicle ? this.selectedVehicle.model : ''}</p>
                            <div class="vehicle-price">
                                ${this.getVehiclePriceDisplay(validCashPayment, validBankPayment, validXPPayment, validCompanyPayment, vehiclePrices)}
                            </div>
                            ${stockEnabled ? `
                                <div class="vehicle-stock ${isOutOfStock ? 'out-of-stock' : 'in-stock'}">
                                    <i data-lucide="${isOutOfStock ? 'x-circle' : 'package'}"></i>
                                    <span>${isOutOfStock ? this.T('ui.payment_methods.out_of_stock') : `${this.T('ui.payment_methods.stock_label')} ${currentStock}`}</span>
                                </div>
                            ` : ''}
                        </div>
                    </div>
                </div>

                <!-- Sección de métodos de pago -->
                <div class="payment-section">
                    <div class="section-title">
                        <i data-lucide="credit-card"></i>
                        <span>${this.T('ui.payment_methods.available_payment_methods')}</span>
                    </div>
                    <div class="payment-methods-grid">
                        ${paymentMethodsHTML || (isOutOfStock ?
                    `<div class="no-payment-methods">
                                <i data-lucide="x-circle"></i>
                                <span>${this.T('ui.payment_methods.vehicle_no_stock')}</span>
                            </div>` :
                    `<div class="no-payment-methods">
                                <i data-lucide="alert-circle"></i>
                                <span>${this.T('ui.payment_methods.no_payment_methods')}</span>
                            </div>`
                )}
                    </div>
                </div>
            </div>
            `,
                ``,
                'Cancelar',
                65,
            )

            setTimeout(() => {
                if (typeof lucide !== 'undefined') {
                    lucide.createIcons();
                }
            }, 100);
        },

        getVehiclePriceDisplay(validCash, validBank, validXP, validCompany, prices) {
            const availablePrices = [];

            if (validCash) {
                const cashPrice = parseInt(prices.cash) || 0;
                if (cashPrice >= 0) {
                    availablePrices.push(`$${cashPrice.toLocaleString('de-DE')}`);
                }
            }

            if (validXP) {
                const xpPrice = parseInt(prices.xp) || 0;
                if (xpPrice > 0) {
                    availablePrices.push(`${xpPrice} ${this.nombreXP}`);
                }
            }

            if (validCompany) {
                const companyPrice = parseInt(prices.company) || 0;
                if (companyPrice >= 0) {
                    availablePrices.push(`$${companyPrice.toLocaleString('de-DE')} (${this.T('ui.payment_methods.company')})`);
                }
            }

            if (availablePrices.length === 0) {
                return this.T('ui.payment_methods.not_available');
            } else if (availablePrices.length === 1) {
                return availablePrices[0];
            } else {
                return availablePrices.join(' / ');
            }
        },

        showFinancingModal() {
            const timeUnit = this.financingConfig.timeUnit;
            const maxPeriods = this.financingConfig.maxPeriods;
            const interestRate = this.financingConfig.interestRate;
            const vehiclePrice = this.currentVehiclePrice;

            // Las mismas cuentas que hace el servidor (server/financing.lua):
            // primero se cobra la entrada y los plazos van sobre lo que queda.
            // Antes aquí se calculaban sobre el precio entero y sin entrada, y
            // el jugador veía unas cifras y le cobraban otras.
            const porcentajeEntrada = Number(this.financingConfig.payInitialPercentage) || 0;
            const entrada = porcentajeEntrada > 0 ? Math.floor(vehiclePrice * porcentajeEntrada / 100) : 0;
            const financiado = vehiclePrice - entrada;

            this.financingModal.vehicleName = this.currentVehicleLabel;
            this.financingModal.vehiclePrice = vehiclePrice;
            this.financingModal.initialPayment = entrada;
            this.financingModal.selectedOption = null;
            this.financingModal.options = [];

            for (let i = 1; i <= maxPeriods; i++) {
                const totalInterestRate = interestRate * i;
                const totalWithInterest = financiado + (financiado * totalInterestRate / 100);

                this.financingModal.options.push({
                    period: i,
                    timeUnit: timeUnit,
                    monthlyPayment: Math.floor(totalWithInterest / i),
                    totalAmount: Math.floor(totalWithInterest),
                    interestRate: totalInterestRate
                });
            }

            this.financingModal.visible = true;

            this.$nextTick(() => {
                if (typeof lucide !== 'undefined') {
                    lucide.createIcons();
                }
            });
        },

        selectFinancingOption(index) {
            this.financingModal.selectedOption = index;
        }, closeFinancingModal() {
            this.financingModal.visible = false;
            this.financingModal.selectedOption = null;
        }, confirmFinancingPurchase() {
            if (this.financingModal.selectedOption === null) {
                return;
            }

            const selectedOption = this.financingModal.options[this.financingModal.selectedOption];

            // Los colores no se mandan: leía `.coloris.instance2/3`, que ya no
            // existen, y sin tono elegido el coche salía rosa. Lua usa los que
            // el jugador pulsó en la paleta (vehicleColors) o deja los de fábrica.
            if (this.financiando) {
                return;
            }
            this.financiando = true;

            this.fetchEvent('financing:financeVehicle', {
                vehicle: this.selectedVehicle,
                periods: selectedOption.period,
                dealershipId: this.dealershipInfo.id,
                monthlyPayment: selectedOption.monthlyPayment,
                totalAmount: selectedOption.totalAmount,
                interestRate: selectedOption.interestRate
            }).then(data => {
                this.financiando = false;
                this.CloseModal()
                if (data && data.success) {
                    this.closeDealershipMenu();
                } else {
                    // Sin esto el servidor decía «no tienes para la entrada» y
                    // el jugador no veía nada: solo se cerraba el diálogo.
                    showNotification((data && data.message) || this.T('notifications.unknown_error'), 'error', 5000);
                }
            }).catch(() => {
                this.financiando = false;
                this.CloseModal();
            });
            this.closeFinancingModal();
        },

        confirmFinancing() {
            this.confirmFinancingPurchase();
        },

        showAddVehicleModal() {

            if (!this.adminPanel.visible || !this.adminPanel.dealershipManagement.selectedDealership) {
                return;
            }
            this.addVehicleModal.visible = true;
            this.addVehicleModal.searchQuery = '';
            this.addVehicleModal.form = {
                category: '',
                model: '',
                label: '',
                price: 0,
                xp: 0,
                image: '',
                class: 'A',
                financing: false,
                // `company` tiene que estar desde el principio: añadida luego
                // con una asignación, Vue 2 no se entera, el interruptor no se
                // encendía y un coche solo para empresas no se podía confirmar.
                paymentMethods: {
                    cash: false,
                    bank: false,
                    xp: false,
                    company: false
                },
                prices: {
                    cash: 0,
                    bank: 0,
                    xp: 0,
                    company: 0
                },
                stockEnabled: false,
                stock: 10
            };
            this.addVehicleModal.selectedVehicle = null;
        }, closeAddVehicleModal() {
            this.addVehicleModal.visible = false;
            this.addVehicleModal.isEditing = false;
            this.addVehicleModal.editingVehicle = null;
            this.currentEditingVehicle = null;
            this.currentEditingCategory = null;
        },

        getCurrentDealershipStock() {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            return dealership ? dealership.stock : {};
        },

        selectDefaultVehicle(vehicle) {
            this.addVehicleModal.selectedVehicle = vehicle.model;
            this.addVehicleModal.form.model = vehicle.model;
            this.addVehicleModal.form.label = vehicle.label;
            this.addVehicleModal.form.image = this.getVehicleImageUrl(vehicle.model);
        }, handleVehicleImageError(event) {
            const placeholder = 'https://placehold.co/200x120/333/fff?text=No+Image';
            if (event.target.src !== placeholder) {
                event.target.src = placeholder;
            }
        }, confirmAddVehicle() {
            if (!this.isAddVehicleFormValid) {
                return;
            }

            const form = this.addVehicleModal.form;

            if (this.addVehicleModal.isEditing) {
                this.updateVehicle(form);
            } else {
                const antes = this.contarCoches();
                this.AddVehicle();
                // Si AddVehicle sale sin añadir (categoría que ya no existe…),
                // el diálogo se queda abierto en vez de cerrarse como si nada.
                if (this.contarCoches() > antes) {
                    this.closeAddVehicleModal();
                } else {
                    this.notify('error', 'No se ha podido añadir el coche');
                }
            }
        },

        contarCoches() {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership || !dealership.stock) return 0;
            return Object.values(dealership.stock).reduce((n, c) => n + ((c && c.categoryStock) ? c.categoryStock.length : 0), 0);
        },

        updateVehicle(form) {
            const cashEnabled = form.paymentMethods?.cash || false;
            const xpEnabled = form.paymentMethods?.xp || false;
            const cashPrice = parseInt(form.prices?.cash) || 0;
            const xpPrice = parseInt(form.prices?.xp) || 0;

            const paymentMethods = {
                cash: cashEnabled,
                bank: cashEnabled,
                xp: xpEnabled,
                company: form.paymentMethods?.company || false
            };

            const prices = {
                cash: cashPrice,
                bank: cashPrice,
                xp: xpPrice,
                company: parseInt(form.prices?.company) || 0
            };

            const stockEnabled = form.stockEnabled || false;
            const stockAmount = stockEnabled ? parseInt(form.stock) || 0 : null;

            const finalImage = form.image && form.image.trim() !== ''
                ? form.image.trim()
                : `./assets/vehicles/${form.model.trim()}.png`;

            const updatedVehicleData = {
                category: form.category,
                model: form.model.trim(),
                label: form.label.trim(),
                price: cashEnabled ? cashPrice : 0,
                xp: xpEnabled ? xpPrice : 0,
                image: finalImage,
                class: form.class,
                financing: form.financing,
                paymentMethods: paymentMethods,
                prices: prices,
                stockEnabled: stockEnabled,
                stock: stockAmount
            };

            this.updateVehicleInStock(this.addVehicleModal.editingVehicle, updatedVehicleData, this.currentEditingCategory);
        },

        getTimeUnitText(timeUnit, count) {
            if (timeUnit === 'weeks') {
                return count === 1 ? this.T('ui.admin_panel.week') : this.T('ui.admin_panel.weeks');
            } else if (timeUnit === 'months') {
                return count === 1 ? this.T('ui.admin_panel.month') : this.T('ui.admin_panel.months');
            } else {
                return count === 1 ? this.T('ui.admin_panel.day') : this.T('ui.admin_panel.days');
            }
        },


        purchaseVehicle(method) {
            let vehicleModel = this.selectedVehicle.model;
            let vehicleLabel = this.currentVehicleLabel;

            let firstColor = $('#primaryColorPicker').val() || '#c40b78';
            let secondaryColor = $('#secondaryColorPicker').val() || '#7a034a';
            // Colores procesados para el vehículo

            if (!firstColor || !secondaryColor) {
                firstColor = '#c40b78';
                secondaryColor = '#7a034a';
            }

            const rgbMatch = firstColor && typeof firstColor === 'string' ? firstColor.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/) : null;
            const rgbMatch2 = secondaryColor && typeof secondaryColor === 'string' ? secondaryColor.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/) : null;

            if (!vehicleModel || !vehicleLabel) {
                return;
            }

            // Un doble clic en el método de pago lanzaba dos compras.
            if (this.comprando) {
                return;
            }
            this.comprando = true;

            // Ya no se cierra el concesionario antes de comprar: lo recoge Lua
            // si la compra sale bien, y si sale mal la vista previa sigue ahí.
            if (firstColor && typeof firstColor === 'string' && firstColor.startsWith('#')) {
                const hex = firstColor.replace('#', '');
                const r = parseInt(hex.substring(0, 2), 16);
                const g = parseInt(hex.substring(2, 4), 16);
                const b = parseInt(hex.substring(4, 6), 16);
                firstColor = { r, g, b };

            } else {
                if (rgbMatch) {
                    const r = parseInt(rgbMatch[1]);
                    const g = parseInt(rgbMatch[2]);
                    const b = parseInt(rgbMatch[3]);
                    firstColor = { r, g, b };
                }
            }

            if (secondaryColor && typeof secondaryColor === 'string' && secondaryColor.startsWith('#')) {
                const hex = secondaryColor.replace('#', '');
                const r = parseInt(hex.substring(0, 2), 16);
                const g = parseInt(hex.substring(2, 4), 16);
                const b = parseInt(hex.substring(4, 6), 16);
                secondaryColor = { r, g, b };
            } else {
                if (rgbMatch2) {
                    const r = parseInt(rgbMatch2[1]);
                    const g = parseInt(rgbMatch2[2]);
                    const b = parseInt(rgbMatch2[3]);
                    secondaryColor = { r, g, b };
                }
            }
            const vehicleData = {
                dealershipId: this.dealershipInfo.id,
                vehicleModel: vehicleModel,
                paymentMethod: method,
                primaryColor: firstColor,
                secondaryColor: secondaryColor
            };

            this.fetchEvent('origen_dealerships:ui:purchaseVehicle', vehicleData).then((result) => {
                this.comprando = false;
                this.CloseModal()
                if (!result || !result.success) {
                    this.fetchEvent('maintainNuiFocus', {});
                    showNotification((result && result.message) || this.T('notifications.unknown_error'), 'error', 5000);
                } else {
                    this.closeDealershipMenu();
                }
            }).catch(() => {
                this.comprando = false;
                this.CloseModal();
                this.fetchEvent('maintainNuiFocus', {});
            })


        },

        testDriveVehicle() {
            if (!this.canTestDriveCurrent) {
                this.notify('error', 'La prueba de manejo esta desactivada para este coche de exhibicion');
                return;
            }

            this.stopTestDriveTimer();

            let vehicleModel = this.selectedVehicle.model;
            let vehicleLabel = this.currentVehicleLabel;

            if (!vehicleModel || !vehicleLabel) {
                return;
            }

            if (!this.dealershipInfo || !this.dealershipInfo.settings || !this.dealershipInfo.settings.allowTestDrive) {
                this.notify('error', this.T('ui.payment_methods.test_drive_not_allowed'));
                return;
            }

            // Obtener colores con validación
            let firstColor = $('.coloris.instance2').val() || '#000000';
            let secondaryColor = $('.coloris.instance3').val() || '#000000';

            // Colores configurados correctamente

            // Validar que los colores no sean null o undefined
            if (!firstColor || typeof firstColor !== 'string') {
                firstColor = '#000000';
            }
            if (!secondaryColor || typeof secondaryColor !== 'string') {
                secondaryColor = '#000000';
            }

            // Procesar primer color
            let processedFirstColor = { r: 0, g: 0, b: 0 };
            if (firstColor && typeof firstColor === 'string' && firstColor.startsWith('#')) {
                const hex = firstColor.replace('#', '');
                if (hex.length === 6) {
                    processedFirstColor = {
                        r: parseInt(hex.substring(0, 2), 16),
                        g: parseInt(hex.substring(2, 4), 16),
                        b: parseInt(hex.substring(4, 6), 16)
                    };
                }
            } else {
                const rgbMatch = firstColor && typeof firstColor === 'string' ? firstColor.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/) : null;
                if (rgbMatch) {
                    processedFirstColor = {
                        r: parseInt(rgbMatch[1]),
                        g: parseInt(rgbMatch[2]),
                        b: parseInt(rgbMatch[3])
                    };
                }
            }

            // Procesar segundo color
            let processedSecondaryColor = { r: 0, g: 0, b: 0 };
            if (secondaryColor && typeof secondaryColor === 'string' && secondaryColor.startsWith('#')) {
                const hex = secondaryColor.replace('#', '');
                if (hex.length === 6) {
                    processedSecondaryColor = {
                        r: parseInt(hex.substring(0, 2), 16),
                        g: parseInt(hex.substring(2, 4), 16),
                        b: parseInt(hex.substring(4, 6), 16)
                    };
                }
            } else {
                const rgbMatch2 = secondaryColor && typeof secondaryColor === 'string' ? secondaryColor.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/) : null;
                if (rgbMatch2) {
                    processedSecondaryColor = {
                        r: parseInt(rgbMatch2[1]),
                        g: parseInt(rgbMatch2[2]),
                        b: parseInt(rgbMatch2[3])
                    };
                }
            }


            this.CloseModal();
            // El catálogo se esconde YA: el 'close' suelta el foco y la cámara
            // enseguida, y hasta que contestaba la prueba se quedaba pintado sin
            // ratón.
            this.closeDealershipMenu();
            this.fetchEvent('close', { silent: true });

            this.fetchEvent('origen_dealerships:ui:testDriveVehicle', {
                dealershipId: this.dealershipInfo.id,
                model: vehicleModel,
                label: vehicleLabel,
                firstColor: processedFirstColor,
                secondaryColor: processedSecondaryColor
            }).then((result) => {
                if (!result || !result.success) {
                    this.testDriving = false
                    // El 'close' de arriba ya soltó el foco y la cámara: si el
                    // menú sigue a la vista, queda un catálogo que no se puede usar.
                    this.closeDealershipMenu();
                } else {
                    if (this.dealershipMenu.visible) {
                        this.dealershipMenu.visible = false
                    }
                    this.testDriving = true
                    this.CloseModal()
                    this.startTestDriveTimer(result.timer || 60000)
                }
            }).catch(() => {
                // Sin respuesta no hay prueba: que no se quede marcada.
                this.testDriving = false
            })

        },

        startTestDriveTimer(duration) {
            this.testDriveTimeRemaining = duration;
            this.testDriveTimer = setInterval(() => {
                this.testDriveTimeRemaining -= 1000;

                if (this.testDriveTimeRemaining <= 0) {
                    this.stopTestDriveTimer();
                    this.testDriving = false;
                }
            }, 1000);
        },

        stopTestDriveTimer() {
            if (this.testDriveTimer) {
                clearInterval(this.testDriveTimer);
                this.testDriveTimer = null;
            }
            this.testDriveTimeRemaining = 0;
        },

        resetNUIState() {
            if (this.modals && this.modals.length > 0) {
                this.CloseModal();
            }

            this.selectedVehicle = null;
            this.currentVehiclePrice = 0;
            this.currentVehicleFinancing = false;
            this.currentVehicleLabel = '';

            this.searchQuery = '';
            this.selectedCategory = 'all_categories';

            this.financingModal = {
                visible: false,
                vehicleName: '',
                vehiclePrice: 0,
                periods: 1,
                interestRate: 5.0,
                totalCost: 0,
                monthlyPayment: 0
            };

            this.currentEditingVehicle = null;
            this.currentEditingCategory = null;

            this.cameraControls = {
                zoom: 1.0,
                minZoom: 0.5,
                maxZoom: 3.0,
                rotation: 0,
                height: 1.0,
                minHeight: -2.0,
                maxHeight: 5.0,
                isDragging: false,
                lastX: 0,
                lastY: 0,
                sensitivity: 0.05,
                heightSensitivity: 0.02,
                autoRotateEnabled: true,
                autoRotateSpeed: 12.0,
                hasManualControl: false
            };

            setTimeout(() => {
                $('.c-modal').remove();
                $('.o-modal').hide();
                this.modals = [];

                $('.coloris').val('#000000');
                $('.coloris.instance2').val('#000000');
                $('.coloris.instance3').val('#000000');

                if (window.Coloris && typeof window.Coloris.close === 'function') {
                    window.Coloris.close();
                }

                $('.clr-picker').remove();
                $('.clr-overlay').remove();

            }, 100);

        },

        cleanupDOM() {
            $('.c-modal').remove();
            $('.o-modal').hide();
            $('.clr-picker').remove();
            $('.clr-overlay').remove();

            if (window.Coloris && typeof window.Coloris.close === 'function') {
                window.Coloris.close();
            }

            this.modals = [];

        },

        formatTimeRemaining(milliseconds) {
            if (milliseconds <= 0) return '00:00';

            const seconds = Math.floor(milliseconds / 1000);
            const minutes = Math.floor(seconds / 60);
            const remainingSeconds = seconds % 60;

            return `${minutes.toString().padStart(2, '0')}:${remainingSeconds.toString().padStart(2, '0')}`;
        },

        getTimerClass() {
            if (this.testDriveTimeRemaining <= 10000) {
                return 'danger';
            } else if (this.testDriveTimeRemaining <= 30000) {
                return 'warning';
            }
            return '';
        },

        dmSelectVehicle(vehicle) {
            if (vehicle.model == (this.selectedVehicle ? this.selectedVehicle.model : null)) {
                return
            };

            if (vehicle.stockEnabled && vehicle.stock <= 0) {
                return;
            }

            this.selectedVehicle = vehicle;
            this.currentVehicleLabel = vehicle.label
            this.currentVehiclePrice = vehicle.price || false;
            this.currentVehicleXP = vehicle.xp || false;
            this.currentVehicleFinancing = vehicle.financing || false;

            this.resetCameraControls();

            this.$nextTick(() => {
                this.initializeCameraControls();
                // Reinicializar Coloris para los nuevos elementos del color picker
                this.initializeColorPickers();
            });

            this.fetchEvent('origen_dealerships:ui:changeVehiclePreview', {
                model: vehicle.model,
                zoom: this.cameraControls.zoom,
                rotation: this.cameraControls.rotation
            }).then((result) => {
                this.loadingVehicleStats = true;
                this.dealershipMenu.currentVehicleStats = null;
                const start3 = Date.now();
                this.dealershipMenu.currentVehicleStats = [
                    { label: 'Potencia', value: result.power },
                    { label: 'Velocidad punta', value: result.high_speed },
                    { label: 'Aceleración', value: result.acceleration * 100 },
                    { label: 'Frenado', value: result.braking * 100 }
                ];
                this.loadingVehicleStats = false;
                this.notifyPreviewReadyIfNeeded();
            });
        },

        initializeCameraControls() {
            this.removeCameraControls();

            // En un exhibidor no hay cámara que girar: el coche está en el
            // mundo. Montarlos arrancaba la autorrotación y mandaba a Lua una
            // docena de updateCameraControls por segundo para nada.
            if (this.dealershipInfo && this.dealershipInfo.liveInspect) return;

            const scroller = document.querySelector('.vehicle-scroller');
            if (!scroller) return;

            scroller.style.position = 'fixed';
            scroller.style.top = '0';
            scroller.style.left = '0';
            scroller.style.width = 'calc(100vw / var(--ogn-escala, 1))';
            scroller.style.height = 'calc(100vh / var(--ogn-escala, 1))';
            scroller.style.zIndex = '1';
            scroller.style.pointerEvents = 'none';
            scroller.style.cursor = 'grab';

            this.boundHandleZoom = this.handleZoom.bind(this);
            this.boundHandleMouseDown = this.handleMouseDown.bind(this);
            this.boundHandleMouseMove = this.handleMouseMove.bind(this);
            this.boundHandleMouseUp = this.handleMouseUp.bind(this);
            this.boundHandleMouseHover = this.handleMouseHover.bind(this);

            document.addEventListener('wheel', this.boundHandleZoom, { passive: false });
            document.addEventListener('mousedown', this.boundHandleMouseDown);
            document.addEventListener('mousemove', this.boundHandleMouseMove);
            document.addEventListener('mouseup', this.boundHandleMouseUp);

            document.addEventListener('mousemove', this.boundHandleMouseHover);

            scroller.dataset.cameraControlsActive = 'true';
            this.startAutoRotate();
        },

        removeCameraControls() {
            const scroller = document.querySelector('.vehicle-scroller');
            this.stopAutoRotate();

            if (this.boundHandleZoom) {
                document.removeEventListener('wheel', this.boundHandleZoom);
            }
            if (this.boundHandleMouseDown) {
                document.removeEventListener('mousedown', this.boundHandleMouseDown);
            }
            if (this.boundHandleMouseMove) {
                document.removeEventListener('mousemove', this.boundHandleMouseMove);
            }
            if (this.boundHandleMouseUp) {
                document.removeEventListener('mouseup', this.boundHandleMouseUp);
            }
            if (this.boundHandleMouseHover) {
                document.removeEventListener('mousemove', this.boundHandleMouseHover);
            }

            if (scroller) {
                scroller.dataset.cameraControlsActive = 'false';
            }
        },

        startAutoRotate() {
            this.stopAutoRotate();

            if (!this.dealershipMenu.visible || !this.cameraControls.autoRotateEnabled) return;
            if (this.dealershipInfo && this.dealershipInfo.liveInspect) return;

            let lastTs = performance.now();
            let lastSyncTs = 0;

            const tick = (ts) => {
                if (!this.dealershipMenu.visible || !this.cameraControls.autoRotateEnabled) {
                    this.stopAutoRotate();
                    return;
                }

                const deltaSeconds = (ts - lastTs) / 1000;
                lastTs = ts;

                if (!this.cameraControls.isDragging) {
                    this.cameraControls.rotation =
                        (this.cameraControls.rotation - (this.cameraControls.autoRotateSpeed * deltaSeconds)) % 360;
                    if (this.cameraControls.rotation < 0) this.cameraControls.rotation += 360;

                    if ((ts - lastSyncTs) >= 80) {
                        this.fetchEvent('origen_dealerships:ui:updateCameraControls', {
                            zoom: this.cameraControls.zoom,
                            rotation: this.cameraControls.rotation,
                            height: this.cameraControls.height,
                            speed: 0.05
                        }).catch(() => { });
                        lastSyncTs = ts;
                    }
                }

                this.autoRotateFrameId = requestAnimationFrame(tick);
            };

            this.autoRotateFrameId = requestAnimationFrame(tick);
        },

        stopAutoRotate() {
            if (this.autoRotateFrameId) {
                cancelAnimationFrame(this.autoRotateFrameId);
                this.autoRotateFrameId = null;
            }
        },

        disableAutoRotateByUser() {
            if (!this.cameraControls.autoRotateEnabled) return;
            this.cameraControls.autoRotateEnabled = false;
            this.cameraControls.hasManualControl = true;
            this.stopAutoRotate();
        },

        notifyPreviewReadyIfNeeded() {
            if (!this.previewEntryPending) return;
            this.previewEntryPending = false;
            this.fetchEvent('origen_dealerships:ui:previewReady', {});
        },

        closeDealershipMenu() {
            if (this.dealershipMenu.visible) {
                this.saveDealerState();

                this.dealershipMenu.visible = false;
                this.dpFirma = false;
                this.removeCameraControls();
                document.body.style.cursor = '';
                this.cameraControls.isDragging = false;
                this.resetCameraControls();
            }
        },


        isInteractiveElement(element) {
            if (!element) return false;

            let currentElement = element;
            while (currentElement && currentElement !== document.body) {
                if (['BUTTON', 'INPUT', 'SELECT', 'TEXTAREA', 'A'].includes(currentElement.tagName)) {
                    return true;
                }

                const classList = currentElement.classList;
                // La columna del concesionario entera: ni se arrastra la
                // camara ni hace zoom con la rueda encima de ella.
                if (classList.contains('dp')) {
                    return true;
                }
                if (classList.contains('btn') ||
                    classList.contains('category') ||
                    classList.contains('vehicle-card') ||
                    classList.contains('action-btn') ||
                    classList.contains('color-picker') ||
                    classList.contains('dealership-tab-item') ||
                    classList.contains('vehicle-categories')) {
                    return true;
                }

                if (currentElement.hasAttribute('onclick') ||
                    currentElement.hasAttribute('@click') ||
                    currentElement.style.cursor === 'pointer') {
                    return true;
                }

                if (classList.contains('dealership-container') ||
                    classList.contains('vehicle-scroller')) {
                    return false;
                }

                currentElement = currentElement.parentElement;
            }

            return false;
        },

        handleZoom(event) {
            if (!this.dealershipMenu.visible) return;

            if (this.isInteractiveElement(event.target)) {
                return;
            }

            event.preventDefault();
            event.stopPropagation();
            this.disableAutoRotateByUser();

            const delta = event.deltaY;
            const zoomSpeed = 0.1;

            if (delta < 0) {
                this.cameraControls.zoom = Math.min(
                    this.cameraControls.maxZoom,
                    this.cameraControls.zoom + zoomSpeed
                );
            } else {
                this.cameraControls.zoom = Math.max(
                    this.cameraControls.minZoom,
                    this.cameraControls.zoom - zoomSpeed
                );
            }

            this.updateCamera();
        },

        handleMouseDown(event) {
            if (!this.dealershipMenu.visible) return;

            if (event.button !== 0) return;

            if (this.isInteractiveElement(event.target)) {
                return;
            }

            this.disableAutoRotateByUser();
            this.cameraControls.isDragging = true;
            this.cameraControls.lastX = event.clientX;
            this.cameraControls.lastY = event.clientY;

            document.body.style.cursor = 'grabbing';

            event.preventDefault();
            event.stopPropagation();
        },

        handleMouseMove(event) {
            if (!this.cameraControls.isDragging) return;

            const deltaX = event.clientX - this.cameraControls.lastX;
            const deltaY = event.clientY - this.cameraControls.lastY;

            this.cameraControls.rotation += deltaX * this.cameraControls.sensitivity;

            this.cameraControls.height = Math.max(this.cameraControls.minHeight,
                Math.min(this.cameraControls.maxHeight, this.cameraControls.height));

            if (this.cameraControls.rotation > 360) {
                this.cameraControls.rotation -= 360;
            } else if (this.cameraControls.rotation < 0) {
                this.cameraControls.rotation += 360;
            }

            this.cameraControls.lastX = event.clientX;
            this.cameraControls.lastY = event.clientY;

            this.fetchEvent('origen_dealerships:ui:updateCameraControls', {
                zoom: this.cameraControls.zoom,
                rotation: this.cameraControls.rotation,
                height: this.cameraControls.height,
                speed: 0.15
            }).catch(error => {
            });

            event.preventDefault();
            event.stopPropagation();
        },

        handleMouseUp() {
            if (this.cameraControls.isDragging) {
                this.cameraControls.isDragging = false;

                document.body.style.cursor = '';
            }
        },

        handleMouseHover(event) {
            if (!this.dealershipMenu.visible) return;

            if (this.cameraControls.isDragging) return;

            if (this.isInteractiveElement(event.target)) {
                document.body.style.cursor = '';
            } else {
                document.body.style.cursor = 'grab';
            }
        },

        updateCamera() {
            if (this.cameraUpdateThrottle) {
                clearTimeout(this.cameraUpdateThrottle);
            }

            this.cameraUpdateThrottle = setTimeout(() => {
                this.fetchEvent('origen_dealerships:ui:updateCameraControls', {
                    zoom: this.cameraControls.zoom,
                    rotation: this.cameraControls.rotation,
                    speed: 0.08
                }).catch(error => {
                });
            }, 16);
        },

        resetCameraControls() {
            this.cameraControls.zoom = 1.0;
            this.cameraControls.rotation = 0;
            this.cameraControls.height = 1.5;
            this.cameraControls.autoRotateEnabled = true;
            this.cameraControls.hasManualControl = false;
            if (this.dealershipMenu.visible) {
                this.startAutoRotate();
            }
        },

        selectVehicle(vehicle) {
        },

        /* Todas las cifras con 'de-DE': el CEF va en en-US y sin locale salía
           «$185,000»; así sale «$185.000», con punto de miles, como en español. */
        formatPrice(price) {
            return price.toLocaleString('de-DE');
        },

        /* «Origen» o «Nación» para el nombre del riel del menú pequeño: la
           marca la deja el trozo «ORIGEN · marca» en <html data-marca>. */
        casaNombre() {
            return document.documentElement.dataset.marca === 'nacion' ? 'Nación' : 'Origen';
        },

        getVehicleListPrice(vehicle) {
            const hasPaymentMethods = vehicle.paymentMethods;
            const vehiclePrice = parseInt(vehicle.price) || 0;
            const vehicleXP = parseInt(vehicle.xp) || 0;

            const prices = [];

            if (hasPaymentMethods) {
                if (hasPaymentMethods.cash && vehiclePrice > 0) {
                    const cashPrice = parseInt(vehicle.prices?.cash) || vehiclePrice;
                    prices.push(`$${cashPrice.toLocaleString('de-DE')}`);
                }
                if (hasPaymentMethods.xp && vehicleXP > 0) {
                    const xpPrice = parseInt(vehicle.prices?.xp) || vehicleXP;
                    prices.push(`${xpPrice} ${this.nombreXP}`);
                }
                if (hasPaymentMethods.company) {
                    const companyPrice = parseInt(vehicle.prices?.company) || 0;
                    if (companyPrice > 0) {
                        prices.push(`$${companyPrice.toLocaleString('de-DE')} (${this.T('ui.payment_methods.company')})`);
                    }
                }
            } else {
                if (vehiclePrice > 0) {
                    prices.push(`$${vehiclePrice.toLocaleString('de-DE')}`);
                }
                if (vehicleXP > 0) {
                    prices.push(`${vehicleXP} ${this.nombreXP}`);
                }
            }

            return prices.length > 0 ? prices.join(' / ') : 'N/A';
        },

        getVehicleImageUrl(vehicleModel, customImage = null) {
            const foto = this.fotoDe(vehicleModel);
            if (foto) {
                return foto;
            }
            if (customImage && customImage.trim() !== '') {
                return customImage.trim();
            }
            return `https://docs.fivem.net/vehicles/${vehicleModel}.webp`;
        },

        // ══ Fotos automáticas ═══════════════════════════════════════════
        // Traído de la versión de la tienda. Lua saca la captura contra la
        // caja verde, aquí se recorta el fondo en un canvas y la foto vuelve
        // a Lua para subirla a fivemanage. Lo que queda en `vehicle.img` es
        // esa dirección, y es la que ven los jugadores en el catálogo.

        fotoDe(model) {
            if (!model) return null;
            return this.photoGen.fotos[String(model).toLowerCase()] || null;
        },

        vehicleImageSrc(vehicle) {
            if (!vehicle) return '';
            return this.fotoDe(vehicle.model) || vehicle.img || '';
        },

        getDealershipModels(dealership) {
            const models = [];
            if (!dealership || !dealership.stock) return models;

            for (const categoryKey in dealership.stock) {
                for (const vehicle of dealership.stock[categoryKey].categoryStock || []) {
                    const model = vehicle.model ? String(vehicle.model).toLowerCase() : '';
                    if (model && !models.includes(model)) models.push(model);
                }
            }
            return models;
        },

        // Los modelos que todavía no enseñan su foto automática: los que no la
        // tienen, y los que la tienen (sacada desde otro concesionario) pero
        // su ficha sigue apuntando a otra imagen.
        fotosPendientes(dealership) {
            const pendientes = [];
            if (!dealership || !dealership.stock) return pendientes;

            for (const categoryKey in dealership.stock) {
                for (const vehicle of dealership.stock[categoryKey].categoryStock || []) {
                    const model = vehicle.model ? String(vehicle.model).toLowerCase() : '';
                    if (!model || pendientes.includes(model)) continue;

                    const foto = this.fotoDe(model);
                    if (!foto || vehicle.img !== foto) pendientes.push(model);
                }
            }
            return pendientes;
        },

        async refreshPhotoCapabilities() {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership) return;

            try {
                const result = await this.fetchEvent('origen_dealerships:ui:getPhotoCapabilities', {
                    models: this.getDealershipModels(dealership)
                });

                this.photoGen.available = !!(result && result.available);
                this.$set(this.photoGen, 'fotos', Object.assign({}, this.photoGen.fotos, (result && result.fotos) || {}));
                this.$set(this.photoGen, 'output', (result && result.output) || null);
            } catch (e) {
                this.photoGen.available = false;
            }

            this.$nextTick(() => lucide.createIcons());
        },

        // Pone en cada ficha la foto de su modelo. Devuelve si cambió alguna.
        aplicarFotos(dealership) {
            let cambios = false;
            if (!dealership || !dealership.stock) return cambios;

            for (const categoryKey in dealership.stock) {
                for (const vehicle of dealership.stock[categoryKey].categoryStock || []) {
                    const foto = this.fotoDe(vehicle.model);
                    if (foto && vehicle.img !== foto) {
                        this.$set(vehicle, 'img', foto);
                        cambios = true;
                    }
                }
            }
            return cambios;
        },

        // rehacer = true vuelve a sacar también las que ya estaban.
        async startPhotoGeneration(rehacer = false) {
            if (this.photoGen.running) return;

            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership) return;

            const models = this.getDealershipModels(dealership)
                .filter((model) => rehacer || !this.fotoDe(model));

            if (!models.length) {
                if (this.aplicarFotos(dealership)) {
                    this.Save(null, false);
                    this.notify('success', 'Fotos puestas en todos los coches');
                } else {
                    this.notify('info', 'Todos los coches ya tienen su foto');
                }
                return;
            }

            await this.runPhotoGeneration(models, dealership);
        },

        async startExtraPhotoGeneration(rehacer = false) {
            if (this.photoGen.running) return;

            let extra;
            try {
                extra = await this.fetchEvent('origen_dealerships:ui:getExtraPhotoModels', {});
            } catch (e) {
                this.notify('error', 'No se han podido leer los coches de emergencias');
                return;
            }

            this.$set(this.photoGen, 'fotos', Object.assign({}, this.photoGen.fotos, (extra && extra.fotos) || {}));

            const models = ((extra && extra.models) || []).filter((model) => rehacer || !this.fotoDe(model));
            if (!models.length) {
                this.notify('info', 'Todos los coches de emergencias ya tienen su foto');
                return;
            }

            await this.runPhotoGeneration(models, null);
        },

        async startSinglePhotoGeneration(model) {
            if (this.photoGen.running) return;

            const limpio = String(model || '').trim().toLowerCase();
            if (!/^[\w-]{1,64}$/.test(limpio)) {
                this.notify('error', 'Escribe el nombre del modelo, por ejemplo onx_polbuff');
                return;
            }

            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            const antes = this.fotoDe(limpio);
            await this.runPhotoGeneration([limpio], dealership);
            if (this.fotoDe(limpio) !== antes) this.photoGen.single = '';
        },

        async runPhotoGeneration(models, dealership) {
            if (!this.photoGen.available) {
                this.notify('error', 'Hace falta screencapture y origen_uploader para sacar fotos');
                return;
            }

            this.photoGen.running = true;
            this.photoGen.cancelling = false;
            this.photoGen.current = 0;
            this.photoGen.total = models.length;
            this.photoGen.model = '';

            try {
                const result = await this.fetchEvent('origen_dealerships:ui:generateVehicleImages', { models });

                (result && result.generated || []).forEach((foto) => {
                    this.$set(this.photoGen.fotos, foto.model, foto.url);
                });

                if (this.aplicarFotos(dealership)) {
                    this.Save(null, false);
                }

                if (!result || !result.success) {
                    const motivos = {
                        screenshot_basic_missing: 'Hace falta screencapture para sacar fotos',
                        uploader_missing: 'Hace falta origen_uploader para subir las fotos',
                        busy: 'Ya se están sacando fotos'
                    };
                    this.notify('error', motivos[result && result.error] || 'No se han podido sacar las fotos');
                    return;
                }

                const hechas = (result.generated || []).length;
                const fallidas = (result.failed || []).length;

                if (result.cancelled) {
                    this.notify('info', `Cancelado: ${hechas} fotos sacadas`);
                } else if (fallidas) {
                    this.notify('error', `${hechas} fotos sacadas, ${fallidas} fallaron: ${result.failed.join(', ')}`);
                } else {
                    this.notify('success', `${hechas} fotos sacadas`);
                }
            } catch (e) {
                this.notify('error', 'No se han podido sacar las fotos');
            } finally {
                this.photoGen.running = false;
                this.photoGen.cancelling = false;
                this.photoGen.model = '';
                this.$nextTick(() => {
                    this.fetchEvent('maintainNuiFocus', {});
                    lucide.createIcons();
                });
            }
        },

        async handleRawVehiclePhoto(model, dataUri) {
            let processed = null;

            try {
                processed = await this.processVehiclePhoto(dataUri);
            } catch (e) {
                processed = null;
            }

            await this.fetchEvent('origen_dealerships:ui:saveVehicleImage', {
                model: model,
                image: processed || ''
            });
        },

        loadImage(src) {
            return new Promise((resolve, reject) => {
                const img = new Image();
                img.onload = () => resolve(img);
                img.onerror = () => reject(new Error('decode failed'));
                img.src = src;
            });
        },

        photoOutputOptions() {
            return Object.assign({
                width: 512,
                height: 320,
                padding: 16,
                removeBackground: true,
                chromaTolerance: 0.3,
                chromaToleranceEdge: 0.39,
                minGreenDominance: 8,
                subjectMinRatio: 0.005,
                subjectGapRatio: 0.03
            }, this.photoGen.output || {});
        },

        async processVehiclePhoto(dataUri) {
            const options = this.photoOutputOptions();
            const source = await this.loadImage(dataUri);

            const canvas = document.createElement('canvas');
            canvas.width = source.naturalWidth;
            canvas.height = source.naturalHeight;

            const ctx = canvas.getContext('2d', { willReadFrequently: true });
            ctx.drawImage(source, 0, 0);

            let bounds = { minX: 0, minY: 0, width: canvas.width, height: canvas.height };

            if (options.removeBackground) {
                const frame = ctx.getImageData(0, 0, canvas.width, canvas.height);
                bounds = this.removePhotoBackground(frame, options);
                if (!bounds) return null;
                ctx.putImageData(frame, 0, 0);
            }

            return this.normalizePhoto(canvas, bounds, options);
        },

        removePhotoBackground(frame, options) {
            this.keyOutBackdrop(frame, options);

            const bounds = this.keepPhotoSubject(frame, options);
            if (!bounds) return null;

            this.despillPhotoEdges(frame);

            return bounds;
        },

        // Un píxel es fondo cuando su EQUILIBRIO de color se parece al verde de
        // la caja; el brillo no cuenta, así la sombra de la caja se corta y un
        // coche verde no. Dos umbrales: el estricto vale en toda la foto (limpia
        // parabrisas y techos abiertos) y el suelto solo crece desde fondo ya
        // cortado (el verde lavado de las ventanillas), así que nunca llega al
        // interior de un coche verde.
        keyOutBackdrop(frame, options) {
            const { width, height, data } = frame;
            const total = width * height;

            const key = this.samplePhotoBackdrop(frame);
            const keySum = key[0] + key[1] + key[2] || 1;
            const keyR = key[0] / keySum;
            const keyG = key[1] / keySum;

            const minDominance = options.minGreenDominance;

            const distance = (o) => {
                const r = data[o], g = data[o + 1], b = data[o + 2];
                if (g - Math.max(r, b) < minDominance) return Infinity;

                const sum = r + g + b || 1;
                return Math.max(Math.abs(r / sum - keyR), Math.abs(g / sum - keyG));
            };

            // Cada píxel entra en la cola una vez como mucho
            const stack = new Int32Array(total);
            let top = 0;

            for (let i = 0; i < total; i++) {
                if (distance(i * 4) <= options.chromaTolerance) {
                    data[i * 4 + 3] = 0;
                    stack[top++] = i;
                }
            }

            const edgeTolerance = options.chromaToleranceEdge;

            const absorb = (index) => {
                if (data[index * 4 + 3] === 0) return;
                if (distance(index * 4) > edgeTolerance) return;

                data[index * 4 + 3] = 0;
                stack[top++] = index;
            };

            while (top > 0) {
                const index = stack[--top];
                const x = index % width;
                const y = (index - x) / width;

                if (x > 0) absorb(index - 1);
                if (x < width - 1) absorb(index + 1);
                if (y > 0) absorb(index - width);
                if (y < height - 1) absorb(index + width);
            }
        },

        // El juego pinta sus avisos en la captura (el de descarga de assets).
        // Recortar a todo lo que sobrevive estiraría la foto del coche hasta
        // ese texto, así que solo se quedan las piezas grandes o pegadas al coche.
        keepPhotoSubject(frame, options) {
            const { width, height, data } = frame;
            const total = width * height;

            const label = new Int32Array(total).fill(-1);
            const stack = new Int32Array(total);
            const areas = [];
            const boxes = [];

            for (let seed = 0; seed < total; seed++) {
                if (data[seed * 4 + 3] === 0 || label[seed] !== -1) continue;

                const id = areas.length;
                let top = 0;
                let area = 0;
                let minX = width, maxX = -1, minY = height, maxY = -1;

                label[seed] = id;
                stack[top++] = seed;

                while (top > 0) {
                    const index = stack[--top];
                    const x = index % width;
                    const y = (index - x) / width;

                    area++;
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;

                    if (x > 0 && data[(index - 1) * 4 + 3] !== 0 && label[index - 1] === -1) {
                        label[index - 1] = id; stack[top++] = index - 1;
                    }
                    if (x < width - 1 && data[(index + 1) * 4 + 3] !== 0 && label[index + 1] === -1) {
                        label[index + 1] = id; stack[top++] = index + 1;
                    }
                    if (y > 0 && data[(index - width) * 4 + 3] !== 0 && label[index - width] === -1) {
                        label[index - width] = id; stack[top++] = index - width;
                    }
                    if (y < height - 1 && data[(index + width) * 4 + 3] !== 0 && label[index + width] === -1) {
                        label[index + width] = id; stack[top++] = index + width;
                    }
                }

                areas.push(area);
                boxes.push({ minX, maxX, minY, maxY });
            }

            if (!areas.length) return null;

            // Una captura con ruido puede dar decenas de miles de piezas: nada de spread
            let largest = 0, largestId = 0;
            for (let i = 0; i < areas.length; i++) {
                if (areas[i] > largest) { largest = areas[i]; largestId = i; }
            }

            const gap = Math.round(Math.max(width, height) * options.subjectGapRatio);
            const main = boxes[largestId];
            const keep = boxes.map((box, id) => {
                if (id === largestId) return true;
                if (areas[id] < largest * options.subjectMinRatio) return false;

                return box.minX <= main.maxX + gap && box.maxX >= main.minX - gap
                    && box.minY <= main.maxY + gap && box.maxY >= main.minY - gap;
            });

            let minX = width, maxX = -1, minY = height, maxY = -1;

            for (let id = 0; id < areas.length; id++) {
                if (!keep[id]) continue;
                const box = boxes[id];
                if (box.minX < minX) minX = box.minX;
                if (box.maxX > maxX) maxX = box.maxX;
                if (box.minY < minY) minY = box.minY;
                if (box.maxY > maxY) maxY = box.maxY;
            }

            for (let i = 0; i < total; i++) {
                const id = label[i];
                if (id !== -1 && !keep[id]) data[i * 4 + 3] = 0;
            }

            if (maxX < minX || maxY < minY) return null;

            return { minX, minY, width: maxX - minX + 1, height: maxY - minY + 1 };
        },

        // El píxel que queda pegado a uno cortado trae un borde verde de la caja
        despillPhotoEdges(frame) {
            const { width, height, data } = frame;

            for (let y = 0; y < height; y++) {
                for (let x = 0; x < width; x++) {
                    const index = y * width + x;
                    if (data[index * 4 + 3] === 0) continue;

                    const neighbourCut = (x > 0 && data[(index - 1) * 4 + 3] === 0)
                        || (x < width - 1 && data[(index + 1) * 4 + 3] === 0)
                        || (y > 0 && data[(index - width) * 4 + 3] === 0)
                        || (y < height - 1 && data[(index + width) * 4 + 3] === 0);

                    if (!neighbourCut) continue;

                    const o = index * 4;
                    const cap = Math.max(data[o], data[o + 2]);
                    if (data[o + 1] > cap) data[o + 1] = cap;
                }
            }
        },

        samplePhotoBackdrop(frame) {
            const { width, height, data } = frame;
            const spots = [
                0,
                width - 1,
                (height - 1) * width,
                (height - 1) * width + (width - 1)
            ];

            let r = 0, g = 0, b = 0;
            spots.forEach((index) => {
                const o = index * 4;
                r += data[o];
                g += data[o + 1];
                b += data[o + 2];
            });

            return [Math.round(r / spots.length), Math.round(g / spots.length), Math.round(b / spots.length)];
        },

        // Todas las fotos del mismo tamaño, para que la rejilla quede pareja
        normalizePhoto(sourceCanvas, bounds, options) {
            const outWidth = options.width;
            const outHeight = options.height;
            const padding = options.padding;

            const out = document.createElement('canvas');
            out.width = outWidth;
            out.height = outHeight;

            const ctx = out.getContext('2d');
            ctx.imageSmoothingEnabled = true;
            ctx.imageSmoothingQuality = 'high';

            const scale = Math.min(
                (outWidth - padding * 2) / bounds.width,
                (outHeight - padding * 2) / bounds.height
            );

            const drawWidth = Math.max(1, Math.round(bounds.width * scale));
            const drawHeight = Math.max(1, Math.round(bounds.height * scale));

            ctx.drawImage(
                sourceCanvas,
                bounds.minX, bounds.minY, bounds.width, bounds.height,
                Math.round((outWidth - drawWidth) / 2),
                Math.round((outHeight - drawHeight) / 2),
                drawWidth, drawHeight
            );

            return out.toDataURL('image/png');
        },

        handleVehicleImageLoadError(event, vehicleModel) {
            if (event.target.dataset.fallbackAttempted) {
                event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDMwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjBGMEYwIi8+CjxwYXRoIGQ9Ik0xNTAgMTAwTDEyMCA4MEwxODAgODBMMTUwIDEwMFoiIGZpbGw9IiNDQ0MiLz4KPHN2Zz4K';
                return;
            }

            const currentSrc = event.target.src;

            if (currentSrc.includes('docs.fivem.net')) {
                event.target.dataset.fallbackAttempted = 'true';
                event.target.src = `./assets/vehicles/${vehicleModel}.png`;
            } else {
                event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDMwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjBGMEYwIi8+CjxwYXRoIGQ9Ik0xNTAgMTAwTDEyMCA4MEwxODAgODBMMTUwIDEwMFoiIGZpbGw9IiNDQ0MiLz4KPHN2Zz4K';
            }
        },

        OpenModal: function (title, content, footerButtons, closeText, width) {
            const id = this.modals.length + 1;
            this.modals.push(id);
            $('.modals').append(`
                <div class="c-modal fadeIn" data-id="${id}">
                    <div class="modal-block">
                        <div class="modal-content scale-in-2" style="width: ${width ? 'calc(' + width + 'vh / var(--ogn-escala, 1))' : 'max-content'
                }">
                            <div class="modal-header">

                                <h2 class="title">${title}</h2>
                            </div>
                            <div class="modal-body">
                                ${content}
                            </div>
                            <div class="modal-footer">
                                ${footerButtons}
                                <button class="btn-cancel" onclick='app.CloseModal(${id})'>${closeText}</button>
                            </div>
                        </div>
                    </div>
                </div>
            `);

            // Aquí se volvía a montar la paleta de colores, pero ningún diálogo
            // lleva paleta: solo sumaba escuchadores y ahora, además, borraría
            // el tono marcado al abrir la compra.
            return id;
        },
        CloseModal: function (id) {
            if (!id) {
                $('.c-modal .modal-block .modal-content').removeClass('scale-in-2').addClass('scale-out-2');
                $('.c-modal').removeClass('fadeIn').fadeOut(500, function () {
                    $(this).remove();
                    $('.o-modal').hide()
                    app.modals = [];
                });

            } else {
                $(`.c-modal[data-id='${id}']`).find('.modal-content').removeClass('scale-in-2').addClass('scale-out-2');
                $(`.c-modal[data-id='${id}']`).removeClass('fadeIn').fadeOut(500, function () {
                    $(this).remove();
                    app.modals.splice(app.modals.findIndex((item) => item == id), 1);
                    if ($('.c-modal').length === 0) {
                        $('.o-modal').hide();
                        app.modals = [];
                    }
                });
            }
        },

        closeAdminMenu() {
            this.adminPanel.visible = false
            this.CloseModal()
            this.fetchEvent('close', { silent: true })
        },
        hideAdminForPlacement() {
            this.adminPanel.visible = false
            this.CloseModal()
        },

        getStageLabel(stage) {
            const labels = {
                'car_exhibitor': 'Exhibidor',
                'car_testdrive': 'Prueba de Manejo',
                'car_delivery': 'Entrega de Vehículo',
                'car_preview': 'Previsualizacion de vehiculo',
                'npc': 'NPC',
                'markers': 'Marcadores'
            };
            return labels[stage] || stage;
        },

        setCreatorTab(tabId) {
            this.creatorMode.tabs.forEach(tab => {
                tab.active = false;
            });

            const selectedTab = this.creatorMode.tabs.find(tab => tab.id === tabId);
            if (selectedTab) {
                selectedTab.active = true;
                this.creatorMode.activeTab = tabId;
                this.creatorMode.currentStage = tabId;

                this.fetchEvent('changeCreatorTab', { tab: tabId });
            }
        },

        getTabCounter(tabId) {
            const maxCounts = {
                'car_testdrive': 1,
                'car_delivery': 1,
                'car_preview': 1,
                'npcs': 1
            };

            const count = this.creatorMode.points[tabId] ? this.creatorMode.points[tabId].length : 0;
            const maxCount = maxCounts[tabId];

            return maxCount ? `${count}/${maxCount}` : count.toString();
        },

        getActiveTabLabel() {
            const activeTab = this.creatorMode.tabs.find(tab => tab.active);
            return activeTab ? activeTab.label : 'N/A';
        },

        formatCoords(point) {
            if (!point) return 'N/A';
            return `${Math.round(point.x)}, ${Math.round(point.y)}, ${Math.round(point.z)}`;
        },

        deleteCreatorPoint(type, index) {
            if (this.creatorMode.points[type] && this.creatorMode.points[type][index]) {
                this.creatorMode.points[type].splice(index, 1);

                this.fetchEvent('deleteCreatorPoint', {
                    type: type,
                    index: index
                });
            }
        },

        nextCreatorTab() {
            const currentIndex = this.creatorMode.tabs.findIndex(tab => tab.active);
            const nextIndex = (currentIndex + 1) % this.creatorMode.tabs.length;
            this.setCreatorTab(this.creatorMode.tabs[nextIndex].id);
        },

        previousCreatorTab() {
            const currentIndex = this.creatorMode.tabs.findIndex(tab => tab.active);
            const previousIndex = currentIndex === 0 ? this.creatorMode.tabs.length - 1 : currentIndex - 1;
            this.setCreatorTab(this.creatorMode.tabs[previousIndex].id);
        },

        editDealership(dealerId) {
            if (this.adminPanel.dealershipManagement.selectedDealership === dealerId) {
                this.adminPanel.dealershipManagement.selectedDealership = undefined;
            } else {
                const dealership = this.getDealershipById(dealerId);
                if (dealership) {
                    if (dealership.blipConfig) {
                        this.$set(dealership, 'blipConfig', {
                            sprite: parseInt(dealership.blipConfig.sprite) || 326,
                            color: parseInt(dealership.blipConfig.color) || 3,
                            scale: parseFloat(dealership.blipConfig.scale) || 0.8
                        });
                    } else {
                        this.$set(dealership, 'blipConfig', {
                            sprite: 326,
                            color: 3,
                            scale: 0.8
                        });
                    }
                }
                this.adminPanel.dealershipManagement.selectedDealership = dealerId;
                if (this.adminPanel.activeDealershipTab === 'vehicles') {
                    this.refreshPhotoCapabilities();
                }
            }
        },

        confirmDeleteDealership(dealership) {
            this.OpenModal(this.T('ui.admin.deleting') + ' ' + (dealership.name || dealership.id).toUpperCase(), `
                    <h2>${this.T('ui.admin.are_you_sure')} ${(dealership.name || dealership.id).toUpperCase()}?</h2>
                    <p>${this.T('ui.admin.this_will_permanently')}</p>
                
            `,
                `<button class="btn-modal" onclick="app.deleteDealershipConfirm('${dealership.id}')">${this.T('ui.admin.confirm')}</button>`,
                this.T('ui.admin.close'),
                50)
        },

        deleteDealership(dealership) {
            this.OpenModal(this.T('ui.admin.deleting') + ' ' + dealership.name, `
                    <h2> ${this.T('ui.admin.are_you_sure')} ${dealership.name}? </h2>
                    <p> ${this.T('ui.admin.this_will_permanently')} </p>
                
            `,
                `<button class="btn-modal" onclick="app.deleteDealershipConfirm('${dealership.id}')">${this.T('ui.admin.confirm')}</button>`,
                this.T('ui.admin.close'),
                50)
        },
        tpDealership(dealership) {
            let Dealership = this.getDealershipById(dealership);
            if (!Dealership || !Dealership.coords) {
                return;
            }
            // fetchEvent devuelve una promesa nativa: el .done de jQuery que
            // había aquí lanzaba un TypeError (el viaje se hacía igual).
            this.fetchEvent('origen_dealerships:ui:teleport', {
                coords: Dealership.coords
            })
        },

        spawnVehicle(vehicle) {
            this.fetchEvent('origen_dealerships:ui:spawnVehicle', {
                vehicle: vehicle
            })
            this.closeAdminMenu()
        },

        deleteDealershipConfirm(dealership) {
            this.fetchEvent('origen_dealerships:ui:deleteDealership', {
                dealership: dealership
            })
                .then((result) => {
                    if (!result) {
                        return;
                    }

                    const dealerships = this.adminPanel.dealershipManagement.dealerships;
                    const index = dealerships.findIndex(d => d.id === dealership);

                    if (index !== -1) {
                        dealerships.splice(index, 1);
                    }

                    this.CloseModal();
                    this.adminPanel.dealershipManagement.selectedDealership = undefined;

                })
                .catch((error) => {
                });
        },

        // Lo que llega de Lua, al formato del panel. Lo usan openAdmin y
        // refreshDealerships: el segundo no normalizaba el stock, y un `stocks = {}`
        // de la base llegaba como array, la categoría nueva se añadía sobre ese
        // array y JSON.stringify la tiraba al guardar.
        formatearConcesionario(dealership) {
            let coords = dealership.coords;
            if (!coords || (Array.isArray(coords) && coords.length === 0)) {
                coords = dealership.markers && dealership.markers.length > 0 ?
                    {
                        x: dealership.markers[0].x,
                        y: dealership.markers[0].y,
                        z: dealership.markers[0].z
                    } :
                    {
                        x: 0,
                        y: 0,
                        z: 0
                    };
            }

            // Normalizar stock para asegurar que categoryStock sean arrays apropiados
            const normalizedStock = {};
            if (dealership.stock && typeof dealership.stock === 'object') {
                Object.keys(dealership.stock).forEach(categoryKey => {
                    const category = dealership.stock[categoryKey];
                    if (category && typeof category === 'object') {
                        normalizedStock[categoryKey] = {
                            label: category.label || categoryKey,
                            categoryStock: [],
                            job: category.job || ""
                        };

                        // Convertir categoryStock a array apropiado si existe
                        if (category.categoryStock) {
                            if (Array.isArray(category.categoryStock)) {
                                // Ya es un array, pero asegurar que no tenga huecos
                                normalizedStock[categoryKey].categoryStock = category.categoryStock.filter(vehicle =>
                                    vehicle && typeof vehicle === 'object' && vehicle.model
                                );
                            } else if (typeof category.categoryStock === 'object') {
                                // Es un objeto, convertir a array
                                const vehicleArray = [];
                                Object.keys(category.categoryStock).forEach(key => {
                                    const vehicle = category.categoryStock[key];
                                    if (vehicle && typeof vehicle === 'object' && vehicle.model) {
                                        vehicleArray.push(vehicle);
                                    }
                                });
                                normalizedStock[categoryKey].categoryStock = vehicleArray;
                            }
                        }
                    }
                });
            }

            return {
                id: dealership.id,
                name: dealership.name,
                description: dealership.description || '',
                coords: coords,
                car_delivery: dealership.car_delivery || [],
                car_preview: dealership.car_preview || [],
                car_testdrive: dealership.car_testdrive || [],
                cars_exhibitor: dealership.cars_exhibitor || [],
                markers: dealership.markers || [],
                npcs: dealership.npcs || [],
                stock: normalizedStock,
                settings: {
                    allowFinancing: dealership.settings?.allowFinancing ?? true,
                    allowTestDrive: dealership.settings?.allowTestDrive ?? true,
                    testDriveTime: dealership.settings?.testDriveTime ?? 5,
                    allowCatalog: dealership.settings?.allowCatalog ?? true,
                vipOnly: dealership.settings?.vipOnly === true
                },
                blipConfig: {
                    sprite: parseInt(dealership.blipConfig?.sprite) || 326,
                    color: parseInt(dealership.blipConfig?.color) || 3,
                    scale: parseFloat(dealership.blipConfig?.scale) || 0.8
                }
            };
        },

        Save(dealerId, showNotification = false) {
            // Solo el concesionario que se está tocando: al mandarlos todos, el
            // servidor reescribía el stock de los demás con la copia del panel
            // y devolvía las unidades vendidas desde que se abrió.
            const id = dealerId || this.adminPanel.dealershipManagement.selectedDealership || false;

            // isFiltering y filteredStock son de la búsqueda del panel: no van a la base.
            const datos = JSON.parse(JSON.stringify(this.adminPanel.dealershipManagement.dealerships,
                (clave, valor) => (clave === 'isFiltering' || clave === 'filteredStock') ? undefined : valor));

            this.fetchEvent('origen_dealerships:ui:saveAll', {
                dealerId: id,
                data: datos
            }).then((result) => {

                if (result === undefined || result === null) {
                    return;
                }

                if (typeof result !== 'object') {
                    return;
                }

                // Ya no se pide forceUpdate: el servidor reparte los datos a todos al guardar.
                if (result && result.success) {
                    if (showNotification) {
                        this.notify('success', this.T('notifications.dealership_saved'));
                    }
                } else {
                    const errorMsg = result?.error || this.T('notifications.unknown_error');
                    this.notify('error', this.T('notifications.error_saving') + ': ' + errorMsg);
                }
            }).catch((error) => {
                this.notify('error', this.T('notifications.connection_error'));
            });
        },


        deleteVehicle(vehicle, vehicleID, categoryKey) {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);

            // Con la búsqueda puesta, el índice que llega es el de la lista
            // filtrada, y deleteVehicleConfirm lo usa sobre la lista entera:
            // buscar «comet» y borrar el Comet se llevaba otro coche. Se busca
            // su sitio de verdad.
            const lista = (dealership && dealership.stock[categoryKey] && dealership.stock[categoryKey].categoryStock) || [];
            vehicleID = lista.indexOf(vehicle);
            if (vehicleID === -1) {
                vehicleID = lista.findIndex(v => v && v.model === vehicle.model);
            }
            if (vehicleID === -1) {
                return;
            }
            this.OpenModal(this.T('ui.admin.deleting') + ' ' + vehicle.label, `
                    <h2> ${this.T('ui.admin.are_you_sure')} ${vehicle.label}? </h2>
                    <p> ${this.T('ui.admin.this_will_permanently')} </p>
                
            `,
                `<button class="btn-modal" onclick="app.deleteVehicleConfirm(${vehicleID}, '${categoryKey}','${dealership.id}' )">${this.T('ui.admin.confirm_spanish')}</button>`,
                this.T('ui.admin.close_spanish'),
                50)
        },

        deleteVehicleConfirm(vehicleID, categoryKey, dealershipId) {
            const dealership = this.getDealershipById(dealershipId || this.adminPanel.dealershipManagement.selectedDealership);

            if (!dealership || !dealership.stock) {
                return;
            }

            if (!dealership.stock[categoryKey]) {
                return;
            }

            if (!dealership.stock[categoryKey].categoryStock) {
                return;
            }

            if (typeof vehicleID === 'number' && vehicleID >= 0 && vehicleID < dealership.stock[categoryKey].categoryStock.length) {
                dealership.stock[categoryKey].categoryStock.splice(vehicleID, 1);

                if (dealership.stock[categoryKey].isFiltering && dealership.stock[categoryKey].filteredStock) {
                    this.$delete(dealership.stock[categoryKey], 'filteredStock');
                    this.$set(dealership.stock[categoryKey], 'isFiltering', false);
                }

                this.Save(null, true);
            } else {
            }

            this.CloseModal();
        },
        createDealership() {
            const uniqueId = 'dealership_' + Date.now();
            const newDealership = {
                id: uniqueId,
                name: this.T ? this.T('ui.admin.new_dealership') : 'Nuevo concesionario',
                description: '',
                coords: {
                    x: 0,
                    y: 0,
                    z: 0
                },
                car_delivery: [],
                car_preview: [],
                car_testdrive: [],
                cars_exhibitor: [],
                markers: [],
                npcs: [],
                stock: {
                    default_category: {
                        label: this.T ? this.T('ui.admin.default_category') : 'Categoría por defecto',
                        categoryStock: []
                    }
                },
                settings: {
                    allowFinancing: true,
                    allowTestDrive: true,
                    testDriveTime: 5,
                    allowCatalog: true,
                    vipOnly: false
                },
                blipConfig: {
                    sprite: 326,
                    color: 3,
                    scale: 0.8
                }
            };
            this.adminPanel.dealershipManagement.dealerships.push(newDealership);
            this.adminPanel.dealershipManagement.selectedDealership = uniqueId;

            this.Save(null, false);

            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        saveDealershipInfo() {
            this.Save(null, true)
        },

        addNewCategory() {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);

            const categoryKey = 'category_' + Date.now();

            this.$set(dealership.stock, categoryKey, {
                label: this.T ? this.T('ui.admin.new_category') : 'Nueva categoría',
                categoryStock: [],
                job: ''
            });


            this.Save(null, true);
        },

        deleteCategory(categoryKey) {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            this.$delete(dealership.stock, categoryKey);

            this.Save(null, true);
        },

        editVehicle(vehicle, categoryKey) {

            this.currentEditingVehicle = vehicle;
            this.currentEditingCategory = categoryKey;

            const cashPrice = vehicle.prices?.cash || vehicle.price || 0;
            const xpPrice = vehicle.prices?.xp || parseInt(vehicle.xp) || 0;
            const companyPrice = vehicle.prices?.company || 0;

            this.addVehicleModal.form = {
                category: categoryKey,
                model: vehicle.model,
                label: vehicle.label,
                price: vehicle.price,
                xp: vehicle.xp,
                image: vehicle.img,
                class: vehicle.class,
                financing: vehicle.financing,
                paymentMethods: {
                    cash: vehicle.paymentMethods?.cash || false,
                    bank: false,
                    xp: vehicle.paymentMethods?.xp || false,
                    company: vehicle.paymentMethods?.company || false
                },
                prices: {
                    cash: cashPrice,
                    bank: 0,
                    xp: xpPrice,
                    company: companyPrice
                },
                stockEnabled: vehicle.stockEnabled || false,
                // ?? y no ||: un coche agotado (0) se reponía a 10 al editarlo.
                stock: vehicle.stock ?? 10
            };

            this.addVehicleModal.isEditing = true;
            this.addVehicleModal.editingVehicle = vehicle;
            this.addVehicleModal.visible = true;
        },

        AddVehicle() {
            const category = this.addVehicleModal.form.category;

            const vehicleModel = this.addVehicleModal.form.model;
            const vehicleLabel = this.addVehicleModal.form.label;
            const vehiclePrice = parseFloat(this.addVehicleModal.form.price) || 0;
            const vehicleXP = parseFloat(this.addVehicleModal.form.xp) || 0;
            const vehicleImage = this.addVehicleModal.form.image;
            const vehicleClass = this.addVehicleModal.form.class;
            const financingEnabled = this.addVehicleModal.form.financing;
            const cashEnabled = this.addVehicleModal.form.paymentMethods?.cash || false;
            const xpEnabled = this.addVehicleModal.form.paymentMethods?.xp || false;
            const cashPrice = parseInt(this.addVehicleModal.form.prices?.cash) || 0;
            const xpPrice = parseInt(this.addVehicleModal.form.prices?.xp) || 0;

            const paymentMethods = {
                cash: cashEnabled,
                bank: cashEnabled,
                xp: xpEnabled,
                company: this.addVehicleModal.form.paymentMethods?.company || false
            };

            const prices = {
                cash: cashPrice,
                bank: cashPrice,
                xp: xpPrice,
                company: parseInt(this.addVehicleModal.form.prices?.company) || 0
            };

            const stockEnabled = this.addVehicleModal.form.stockEnabled || false;
            const stockAmount = stockEnabled ? parseInt(this.addVehicleModal.form.stock) || 0 : null;

            if (!vehicleModel || !vehicleModel.trim()) {
                return;
            }

            if (!vehicleLabel || !vehicleLabel.trim()) {
                return;
            }

            const finalImage = vehicleImage && vehicleImage.trim() !== ''
                ? vehicleImage.trim()
                : `./assets/vehicles/${vehicleModel.trim()}.png`;

            const vehicleData = {
                category: category,
                model: vehicleModel.trim(),
                label: vehicleLabel.trim(),
                price: cashEnabled ? cashPrice : 0,
                xp: xpEnabled ? xpPrice : 0,
                image: finalImage,
                class: vehicleClass,
                financing: financingEnabled,
                paymentMethods: paymentMethods,
                prices: prices,
                stockEnabled: stockEnabled,
                stock: stockAmount
            };

            this.saveVehicleToStock(vehicleData);
        },

        saveVehicleToStock(vehicleData) {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);

            if (!dealership || !dealership.stock) {
                return;
            }

            if (!dealership.stock[vehicleData.category]) {
                return;
            }

            const newVehicle = {
                label: vehicleData.label,
                model: vehicleData.model,
                img: vehicleData.image,
                stock: vehicleData.stockEnabled ? vehicleData.stock : null,
                stockEnabled: vehicleData.stockEnabled || false,
                price: vehicleData.price,
                xp: vehicleData.xp,
                class: vehicleData.class,
                financing: vehicleData.financing || false,
                paymentMethods: vehicleData.paymentMethods || { cash: false, bank: false, xp: false, company: false },
                prices: vehicleData.prices || { cash: 0, bank: 0, xp: 0, company: 0 }
            };

            if (!dealership.stock[vehicleData.category].categoryStock) {
                this.$set(dealership.stock[vehicleData.category], 'categoryStock', []);
            }

            dealership.stock[vehicleData.category].categoryStock.push(newVehicle);

            this.CloseModal();

            this.Save(null, true)
        },

        updateVehicleInStock(originalVehicle, updatedVehicleData, originalCategory) {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);

            if (!dealership || !dealership.stock) {
                return;
            }

            if (originalCategory !== updatedVehicleData.category) {
                if (dealership.stock[originalCategory] && dealership.stock[originalCategory].categoryStock) {
                    const originalIndex = dealership.stock[originalCategory].categoryStock.findIndex(v =>
                        v.model === originalVehicle.model && v.label === originalVehicle.label
                    );

                    if (originalIndex !== -1) {
                        dealership.stock[originalCategory].categoryStock.splice(originalIndex, 1);
                    }
                }

                if (!dealership.stock[updatedVehicleData.category]) {
                    return;
                }

                if (!dealership.stock[updatedVehicleData.category].categoryStock) {
                    this.$set(dealership.stock[updatedVehicleData.category], 'categoryStock', []);
                }

                const newVehicle = {
                    label: updatedVehicleData.label,
                    model: updatedVehicleData.model,
                    img: updatedVehicleData.image,
                    stock: updatedVehicleData.stockEnabled ? updatedVehicleData.stock : (originalVehicle.stockEnabled ? originalVehicle.stock : null),
                    stockEnabled: updatedVehicleData.stockEnabled || false,
                    price: updatedVehicleData.price,
                    xp: updatedVehicleData.xp,
                    class: updatedVehicleData.class,
                    financing: updatedVehicleData.financing || false,
                    paymentMethods: updatedVehicleData.paymentMethods || { cash: false, bank: false, xp: false },
                    prices: updatedVehicleData.prices || { cash: 0, bank: 0, xp: 0 }
                };

                dealership.stock[updatedVehicleData.category].categoryStock.push(newVehicle);

            } else {
                if (dealership.stock[originalCategory] && dealership.stock[originalCategory].categoryStock) {
                    const vehicleIndex = dealership.stock[originalCategory].categoryStock.findIndex(v =>
                        v.model === originalVehicle.model && v.label === originalVehicle.label
                    );

                    if (vehicleIndex !== -1) {
                        const updatedVehicle = {
                            label: updatedVehicleData.label,
                            model: updatedVehicleData.model,
                            img: updatedVehicleData.image,
                            stock: updatedVehicleData.stockEnabled ? updatedVehicleData.stock : (originalVehicle.stockEnabled ? originalVehicle.stock : null),
                            stockEnabled: updatedVehicleData.stockEnabled || false,
                            price: updatedVehicleData.price,
                            xp: updatedVehicleData.xp,
                            class: updatedVehicleData.class,
                            financing: updatedVehicleData.financing || false,
                            paymentMethods: updatedVehicleData.paymentMethods || { cash: false, bank: false, xp: false },
                            prices: updatedVehicleData.prices || { cash: 0, bank: 0, xp: 0 }
                        };

                        this.$set(dealership.stock[originalCategory].categoryStock, vehicleIndex, updatedVehicle);
                    } else {
                        return;
                    }
                }
            }
            this.closeAddVehicleModal();
            this.Save(null, true)
        },

        searchVehicles() {
            if (!this.adminPanel.dealershipManagement.selectedDealership) return;

            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership) return;

            if (!this.searchQuery.trim()) {
                this.resetVehicleFiltering();
                return;
            }

            const query = this.searchQuery.toLowerCase().trim();
            const currentDealership = this.adminPanel.dealershipManagement.selectedDealership;

            Object.keys(dealership.stock).forEach(categoryKey => {
                const category = dealership.stock[categoryKey];

                category.filteredStock = category.categoryStock.filter(vehicle => {
                    return vehicle.label.toLowerCase().includes(query) ||
                        vehicle.model.toLowerCase().includes(query);
                });

                this.$set(category, 'isFiltering', true);

                // Expandir automáticamente las categorías que tienen resultados de búsqueda
                if (category.filteredStock.length > 0) {
                    const key = `${currentDealership}_${categoryKey}`;
                    this.$set(this.expandedCategories, key, true);
                }
            });

            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        clearSearch() {
            this.searchQuery = '';
            this.resetVehicleFiltering();
        },

        resetVehicleFiltering() {
            if (!this.adminPanel.dealershipManagement.selectedDealership) return;

            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership) return;

            Object.keys(dealership.stock).forEach(categoryKey => {
                const category = dealership.stock[categoryKey];
                this.$delete(category, 'filteredStock');
                this.$set(category, 'isFiltering', false);
            });

            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        getDealershipById(id) {
            return this.adminPanel.dealershipManagement.dealerships.find(d => d.id === id);
        },

        // Métodos para manejar categorías expandibles
        toggleCategoryExpansion(categoryKey) {
            const currentDealership = this.adminPanel.dealershipManagement.selectedDealership;
            const key = `${currentDealership}_${categoryKey}`;

            this.$set(this.expandedCategories, key, !this.expandedCategories[key]);

            // Refrescar iconos de Lucide después de cambiar el estado
            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        isCategoryExpanded(categoryKey) {
            const currentDealership = this.adminPanel.dealershipManagement.selectedDealership;
            const key = `${currentDealership}_${categoryKey}`;

            // Por defecto, expandir la primera categoría si no hay estado guardado
            if (this.expandedCategories[key] === undefined) {
                const dealership = this.getDealershipById(currentDealership);
                if (dealership && dealership.stock) {
                    const categories = Object.keys(dealership.stock);
                    const isFirstCategory = categories.indexOf(categoryKey) === 0;
                    return isFirstCategory;
                }
                return false;
            }

            return this.expandedCategories[key];
        },

        // Método para expandir todas las categorías (útil para búsquedas)
        expandAllCategories() {
            const currentDealership = this.adminPanel.dealershipManagement.selectedDealership;
            const dealership = this.getDealershipById(currentDealership);

            if (dealership && dealership.stock) {
                Object.keys(dealership.stock).forEach(categoryKey => {
                    const key = `${currentDealership}_${categoryKey}`;
                    this.$set(this.expandedCategories, key, true);
                });
            }
        },

        // Método para colapsar todas las categorías
        collapseAllCategories() {
            const currentDealership = this.adminPanel.dealershipManagement.selectedDealership;
            const dealership = this.getDealershipById(currentDealership);

            if (dealership && dealership.stock) {
                Object.keys(dealership.stock).forEach(categoryKey => {
                    const key = `${currentDealership}_${categoryKey}`;
                    this.$set(this.expandedCategories, key, false);
                });
            }
        },

        setTabActive(tab_id) {
            for (let key in this.adminPanel.tabs) {
                this.adminPanel.tabs[key].active = false;
            }

            if (this.adminPanel.tabs[tab_id]) {
                this.adminPanel.tabs[tab_id].active = true;
            }

            if (tab_id === 'map') {
                this.Save()
                setTimeout(() => {
                    if (map) {
                        map.remove();
                        map = null;
                    }
                    initMap(this.adminPanel.dealershipManagement.dealerships);
                }, 100);
            } else {
                if (map) {
                    map.remove();
                    map = null;
                }
            }

        },

        setDealershipTab(tabId) {
            this.adminPanel.dealershipTabs.forEach(tab => {
                tab.active = false;
            });

            const selectedTab = this.adminPanel.dealershipTabs.find(tab => tab.id === tabId);
            if (selectedTab) {
                selectedTab.active = true;
                this.adminPanel.activeDealershipTab = tabId;

                if (tabId === 'vehicles') {
                    this.vehiclesReady = false;
                    this.$nextTick(() => {
                        this.vehiclesReady = true;
                    });
                    this.refreshPhotoCapabilities();
                }
            }

            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        setLocationTab(tabId) {
            this.adminPanel.locationTabs.forEach(tab => {
                tab.active = false;
            });

            const selectedTab = this.adminPanel.locationTabs.find(tab => tab.id === tabId);
            if (selectedTab) {
                selectedTab.active = true;
                this.adminPanel.activeLocationTab = tabId;
            }

            this.$nextTick(() => {
                lucide.createIcons();
            });
        },

        getLocationCounter(dealership, tabId) {
            const maxCounts = {
                'car_testdrive': 1,
                'car_delivery': 1,
                'car_preview': 1,
                'npcs': 1
            };

            const locations = dealership[tabId] || [];
            const count = locations.length;
            const maxCount = maxCounts[tabId];

            return maxCount ? `${count}/${maxCount}` : count.toString();
        },

        formatLocationCoords(location) {
            if (!location) return 'N/A';
            return `${Math.round(location.x)}, ${Math.round(location.y)}, ${Math.round(location.z)}`;
        },

        teleportToLocation(location) {
            if (location && location.x !== undefined && location.y !== undefined && location.z !== undefined) {
                this.fetchEvent('origen_dealerships:ui:teleport', {
                    coords: location
                });
            }
        },

        deleteLocation(dealership, locationType, index) {
            if (dealership[locationType] && dealership[locationType][index]) {
                dealership[locationType].splice(index, 1);
                this.Save(null, true);
            }
        },

        setupLocationCoords(dealership, locationType) {
            this.hideAdminForPlacement();
            this.fetchEvent('prepareLocationPlacement', {})
                .then(() => {
                    this.fetchEvent('setupIndividualLocation', {
                        dealershipId: dealership.id,
                        locationType: locationType,
                        currentData: {
                            cars_exhibitor: dealership.cars_exhibitor || [],
                            car_testdrive: dealership.car_testdrive || [],
                            car_delivery: dealership.car_delivery || [],
                            car_preview: dealership.car_preview || [],
                            npcs: dealership.npcs || [],
                            markers: dealership.markers || []
                        }
                    });
                })
                .catch(() => {
                    this.fetchEvent('setupIndividualLocation', {
                        dealershipId: dealership.id,
                        locationType: locationType,
                        currentData: {
                            cars_exhibitor: dealership.cars_exhibitor || [],
                            car_testdrive: dealership.car_testdrive || [],
                            car_delivery: dealership.car_delivery || [],
                            car_preview: dealership.car_preview || [],
                            npcs: dealership.npcs || [],
                            markers: dealership.markers || []
                        }
                    });
                });
        },

        handleKeyDown(event) {
            /* E compra (o firma, con la firma abierta) y G prueba el coche.
               Nunca mientras se escribe en el buscador ni con la financiacion
               o un dialogo abierto encima. */
            const escribiendo = event.target && ['INPUT', 'TEXTAREA'].includes(event.target.tagName) && event.target.type !== 'hidden';
            if (this.dealershipMenu.visible && !escribiendo && !event.repeat && !this.financingModal.visible && !$('.c-modal').length) {
                const tecla = String(event.key || '').toLowerCase();
                if (tecla === 'e') {
                    if (this.dpFirma) this.dpFirmar(); else this.dpAbrirFirma();
                    return;
                }
                if (tecla === 'g' && !this.dpFirma && this.selectedVehicle && this.canTestDriveCurrent) {
                    this.testDriveVehicle();
                    return;
                }
            }

            // Con la financiación abierta, Intro confirma el plazo elegido.
            if (this.financingModal.visible && event.key === 'Enter' && !event.repeat && !escribiendo) {
                event.preventDefault();
                this.confirmFinancingPurchase();
                return;
            }

            if (event.key === 'Escape') {
                if (this.dpFirma) {
                    this.dpFirma = false;
                    return;
                }
                // Escape cierra lo de más arriba y nada más. Antes cerraba el
                // concesionario entero aunque solo hubiera abierta la
                // financiación o una confirmación, y dejaba los diálogos del
                // admin abiertos para la próxima vez que se abriera el panel.
                if (this.financingModal.visible) {
                    this.closeFinancingModal();
                    return;
                }
                if ($('.c-modal').length) {
                    this.CloseModal();
                    return;
                }
                if (this.exhibitorConfigModal.visible) {
                    this.closeExhibitorConfigModal();
                    return;
                }
                if (this.addVehicleModal.visible) {
                    this.closeAddVehicleModal();
                    return;
                }

                const wasDealershipVisible = this.dealershipMenu.visible;
                const isLiveInspect = this.dealershipInfo?.liveInspect === true;
                this.adminPanel.visible = false
                if (this.dealershipMenu.visible) {
                    this.closeDealershipMenu();
                }

                this.CloseModal()
                this.fetchEvent('close', { silent: !wasDealershipVisible || isLiveInspect });
            }

            if (this.creatorMode.active) {
                if (event.key === 'Tab') {
                    event.preventDefault();
                    if (event.shiftKey) {
                        this.previousCreatorTab();
                    } else {
                        this.nextCreatorTab();
                    }
                }
            }
        },
        handlePrimaryColorChange(color) {
            let r, g, b;

            // Convertir hex a RGB
            if (color.startsWith('#')) {
                const hex = color.replace('#', '');
                r = parseInt(hex.substring(0, 2), 16);
                g = parseInt(hex.substring(2, 4), 16);
                b = parseInt(hex.substring(4, 6), 16);
            } else {
                // Si ya es RGB
                const rgbMatch = color.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
                if (rgbMatch) {
                    r = parseInt(rgbMatch[1]);
                    g = parseInt(rgbMatch[2]);
                    b = parseInt(rgbMatch[3]);
                }
            }

            if (r !== undefined && g !== undefined && b !== undefined) {
                this.fetchEvent('origen_dealerships:ui:changePrimary', { r, g, b });
            }
        },


        // Métodos para el modal de configuración de exhibidores
        configureExhibitorVehicles(index) {
            this.exhibitorConfigModal.currentExhibitorIndex = index;
            this.exhibitorConfigModal.selectedVehicles = [];
            this.exhibitorConfigModal.fixedVehicleModel = '';
            this.exhibitorConfigModal.rotateEnabled = false;
            this.exhibitorConfigModal.interactable = true;
            this.exhibitorConfigModal.allowPurchase = true;
            this.exhibitorConfigModal.allowTestDrive = true;

            // Obtener vehículos disponibles del concesionario actual
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (dealership && dealership.stock) {
                this.exhibitorConfigModal.availableVehicles = [];

                Object.values(dealership.stock).forEach(category => {
                    if (category.categoryStock && Array.isArray(category.categoryStock)) {
                        category.categoryStock.forEach(vehicle => {
                            if (vehicle.model && vehicle.label) {
                                this.exhibitorConfigModal.availableVehicles.push({
                                    model: vehicle.model,
                                    label: vehicle.label,
                                    class: vehicle.class || 'A',
                                    img: vehicle.image || 'https://via.placeholder.com/60x60?text=Car'
                                });
                            }
                        });
                    }
                });
            }

            // Cargar vehículos ya configurados para este exhibidor
            if (this.creatorMode.points.cars_exhibitor[index] &&
                this.creatorMode.points.cars_exhibitor[index].allowedVehicles) {
                this.exhibitorConfigModal.selectedVehicles = [...this.creatorMode.points.cars_exhibitor[index].allowedVehicles];
            }
            if (this.creatorMode.points.cars_exhibitor[index]) {
                const exhibitor = this.creatorMode.points.cars_exhibitor[index];
                this.exhibitorConfigModal.fixedVehicleModel = exhibitor.fixedVehicleModel || '';
                this.exhibitorConfigModal.rotateEnabled = exhibitor.rotateEnabled === true;
                this.exhibitorConfigModal.interactable = exhibitor.interactable !== false;
                this.exhibitorConfigModal.allowPurchase = exhibitor.allowPurchase !== false;
                this.exhibitorConfigModal.allowTestDrive = exhibitor.allowTestDrive !== false;
            }

            this.exhibitorConfigModal.visible = true;
        },

        // Método para configurar vehículos desde la lista de ubicaciones
        configureExhibitorVehiclesFromList(dealership, index) {
            this.exhibitorConfigModal.currentExhibitorIndex = index;
            this.exhibitorConfigModal.selectedVehicles = [];
            this.exhibitorConfigModal.fixedVehicleModel = '';
            this.exhibitorConfigModal.rotateEnabled = false;
            this.exhibitorConfigModal.interactable = true;
            this.exhibitorConfigModal.allowPurchase = true;
            this.exhibitorConfigModal.allowTestDrive = true;

            // Obtener vehículos disponibles del concesionario
            if (dealership && dealership.stock) {
                this.exhibitorConfigModal.availableVehicles = [];

                Object.values(dealership.stock).forEach(category => {
                    if (category.categoryStock && Array.isArray(category.categoryStock)) {
                        category.categoryStock.forEach(vehicle => {
                            if (vehicle.model && vehicle.label) {
                                this.exhibitorConfigModal.availableVehicles.push({
                                    model: vehicle.model,
                                    label: vehicle.label,
                                    class: vehicle.class || 'A',
                                    img: vehicle.img || vehicle.image || 'https://via.placeholder.com/60x60?text=Car'
                                });
                            }
                        });
                    }
                });
            }

            // Cargar vehículos ya configurados para este exhibidor
            if (dealership.cars_exhibitor && dealership.cars_exhibitor[index] &&
                dealership.cars_exhibitor[index].allowedVehicles) {
                this.exhibitorConfigModal.selectedVehicles = [...dealership.cars_exhibitor[index].allowedVehicles];
            }
            if (dealership.cars_exhibitor && dealership.cars_exhibitor[index]) {
                const exhibitor = dealership.cars_exhibitor[index];
                this.exhibitorConfigModal.fixedVehicleModel = exhibitor.fixedVehicleModel || '';
                this.exhibitorConfigModal.rotateEnabled = exhibitor.rotateEnabled === true;
                this.exhibitorConfigModal.interactable = exhibitor.interactable !== false;
                this.exhibitorConfigModal.allowPurchase = exhibitor.allowPurchase !== false;
                this.exhibitorConfigModal.allowTestDrive = exhibitor.allowTestDrive !== false;
            }

            // Forzar actualización del DOM
            this.$nextTick(() => {
                this.exhibitorConfigModal.visible = true;

                // Inicializar iconos de Lucide después de mostrar el modal
                this.$nextTick(() => {
                    if (typeof lucide !== 'undefined' && lucide.createIcons) {
                        lucide.createIcons();
                    }
                });
            });
        },

        closeExhibitorConfigModal() {
            this.exhibitorConfigModal.visible = false;
            this.exhibitorConfigModal.currentExhibitorIndex = null;
            this.exhibitorConfigModal.selectedVehicles = [];
            this.exhibitorConfigModal.availableVehicles = [];
            this.exhibitorConfigModal.searchQuery = '';
            this.exhibitorConfigModal.fixedVehicleModel = '';
            this.exhibitorConfigModal.rotateEnabled = false;
            this.exhibitorConfigModal.interactable = true;
            this.exhibitorConfigModal.allowPurchase = true;
            this.exhibitorConfigModal.allowTestDrive = true;
        },

        selectAllVehicles() {
            this.exhibitorConfigModal.selectedVehicles = [...this.exhibitorConfigModal.availableVehicles.map(v => v.model)];
        },

        selectAllFilteredVehicles() {
            const filteredModels = this.filteredExhibitorVehicles.map(v => v.model);
            const currentSelected = [...this.exhibitorConfigModal.selectedVehicles];

            filteredModels.forEach(model => {
                if (!currentSelected.includes(model)) {
                    currentSelected.push(model);
                }
            });

            this.exhibitorConfigModal.selectedVehicles = currentSelected;
        },

        clearAllVehicles() {
            this.exhibitorConfigModal.selectedVehicles = [];
        },

        isVehicleSelected(model) {
            return this.exhibitorConfigModal.selectedVehicles.includes(model);
        },

        toggleVehicleSelection(model) {
            const index = this.exhibitorConfigModal.selectedVehicles.indexOf(model);
            if (index > -1) {
                this.exhibitorConfigModal.selectedVehicles.splice(index, 1);
            } else {
                this.exhibitorConfigModal.selectedVehicles.push(model);
            }
        },

        saveExhibitorConfig() {

            if (this.exhibitorConfigModal.currentExhibitorIndex !== null) {
                const exhibitorIndex = this.exhibitorConfigModal.currentExhibitorIndex;
                const selectedVehicles = [...new Set(this.exhibitorConfigModal.selectedVehicles)];
                const fixedVehicleModel = selectedVehicles.length === 1 ? selectedVehicles[0] : '';

                const currentDealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);

                if (this.creatorMode.active && this.creatorMode.points.cars_exhibitor && this.creatorMode.points.cars_exhibitor[exhibitorIndex]) {
                    if (!this.creatorMode.points.cars_exhibitor[exhibitorIndex].allowedVehicles) {
                        this.$set(this.creatorMode.points.cars_exhibitor[exhibitorIndex], 'allowedVehicles', []);
                    }
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].allowedVehicles = selectedVehicles;
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].fixedVehicleModel = fixedVehicleModel;
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].rotateEnabled = !!this.exhibitorConfigModal.rotateEnabled;
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].interactable = !!this.exhibitorConfigModal.interactable;
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].allowPurchase = !!this.exhibitorConfigModal.allowPurchase;
                    this.creatorMode.points.cars_exhibitor[exhibitorIndex].allowTestDrive = !!this.exhibitorConfigModal.allowTestDrive;
                } else if (currentDealership && currentDealership.cars_exhibitor && currentDealership.cars_exhibitor[exhibitorIndex]) {
                    if (!currentDealership.cars_exhibitor[exhibitorIndex].allowedVehicles) {
                        this.$set(currentDealership.cars_exhibitor[exhibitorIndex], 'allowedVehicles', []);
                    }
                    currentDealership.cars_exhibitor[exhibitorIndex].allowedVehicles = selectedVehicles;
                    currentDealership.cars_exhibitor[exhibitorIndex].fixedVehicleModel = fixedVehicleModel;
                    currentDealership.cars_exhibitor[exhibitorIndex].rotateEnabled = !!this.exhibitorConfigModal.rotateEnabled;
                    currentDealership.cars_exhibitor[exhibitorIndex].interactable = !!this.exhibitorConfigModal.interactable;
                    currentDealership.cars_exhibitor[exhibitorIndex].allowPurchase = !!this.exhibitorConfigModal.allowPurchase;
                    currentDealership.cars_exhibitor[exhibitorIndex].allowTestDrive = !!this.exhibitorConfigModal.allowTestDrive;
                }

                this.Save(null, true);

                this.closeExhibitorConfigModal();
            }
        },

        handleImageError(event) {
            // via.placeholder.com ya no existe: su error volvía a llamar aquí y
            // pedía la imagen otra vez, dos veces por segundo y para siempre.
            // Un dibujo en data: no puede fallar, y aun así se corta a la primera.
            if (event.target.dataset.sinFoto) return;
            event.target.dataset.sinFoto = '1';
            event.target.src = 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMzAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDMwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CjxyZWN0IHdpZHRoPSIzMDAiIGhlaWdodD0iMjAwIiBmaWxsPSIjRjBGMEYwIi8+CjxwYXRoIGQ9Ik0xNTAgMTAwTDEyMCA4MEwxODAgODBMMTUwIDEwMFoiIGZpbGw9IiNDQ0MiLz4KPHN2Zz4K';
        },

        handleSecondaryColorChange(color) {
            let r, g, b;

            if (color.startsWith('#')) {
                const hex = color.replace('#', '');
                r = parseInt(hex.substring(0, 2), 16);
                g = parseInt(hex.substring(2, 4), 16);
                b = parseInt(hex.substring(4, 6), 16);
            } else {
                const rgbMatch = color.match(/rgb\((\d+),\s*(\d+),\s*(\d+)\)/);
                if (rgbMatch) {
                    r = parseInt(rgbMatch[1]);
                    g = parseInt(rgbMatch[2]);
                    b = parseInt(rgbMatch[3]);
                }
            }

            if (r !== undefined && g !== undefined && b !== undefined) {
                this.fetchEvent('origen_dealerships:ui:changeSecondary', { r, g, b });
            }
        },
        toggleFilters() {
            this.showFilters = !this.showFilters;
        },
        notify(type = 'info', message = '') {
            if (window.showNotification) {
                window.showNotification(message, type);
            }
        },

        initializeColorPickers() {
            setTimeout(() => {
                const primaryColorInput = document.getElementById('primaryColorPicker');
                const secondaryColorInput = document.getElementById('secondaryColorPicker');

                this.dpColores = { primario: '#c40b78', secundario: '#7a034a' };

                if (primaryColorInput && secondaryColorInput) {
                    // Los cambios de color se escuchan en mounted, una sola vez.
                    primaryColorInput.value = '#c40b78';
                    secondaryColorInput.value = '#7a034a';

                    // El coche vuelve de fábrica: que la paleta no siga marcando
                    // un tono que ya no lleva.
                    document.querySelectorAll('.de-paleta .de-tono--on').forEach((b) => {
                        b.classList.remove('de-tono--on');
                    });

                    primaryColorInput.style.pointerEvents = 'auto';
                    secondaryColorInput.style.pointerEvents = 'auto';
                    primaryColorInput.style.cursor = 'pointer';
                    secondaryColorInput.style.cursor = 'pointer';
                }
            }, 100);
        },
    }, computed: {
        nombreXP() {
            return this.marca === 'nacion' ? 'Farm XP' : 'XP';
        },

        /* ── Lo que pide el armazon de la tablet ──────────────────────────
           Las cifras de la barra de abajo y los rotulos que cambian segun
           donde estes. Ver la skill origen-tablet. */

        listaDeConcesionarios() {
            return this.adminPanel.dealershipManagement.dealerships || [];
        },

        totalConcesionarios() {
            return this.listaDeConcesionarios.length;
        },

        totalCategorias() {
            return this.listaDeConcesionarios.reduce(
                (t, d) => t + Object.keys(d.stock || {}).length, 0);
        },

        totalCoches() {
            return this.listaDeConcesionarios.reduce((total, d) => {
                return total + Object.values(d.stock || {}).reduce(
                    (t, cat) => t + ((cat.categoryStock || []).length), 0);
            }, 0);
        },

        totalExhibidores() {
            return this.listaDeConcesionarios.reduce(
                (t, d) => t + ((d.cars_exhibitor || []).length), 0);
        },

        /* Las categorias del concesionario que se esta tocando, en la forma
           que pide el desplegable. */
        opcionesDeCategoria() {
            const stock = this.getCurrentDealershipStock() || {};
            return Object.keys(stock).map((clave) => ({ value: clave, label: stock[clave].label }));
        },

        opcionesDeClase() {
            return ['S+', 'S', 'A', 'B', 'C', 'D'].map((c) => ({ value: c, label: 'Clase ' + c }));
        },

        tituloDeLaSeccion() {
            return this.adminPanel.tabs.map.active ? 'El mapa' : 'Los concesionarios';
        },

        /* Los seis tipos de punto. El creador y la pestaña de puntos del
           concesionario enseñan lo mismo de cada uno, asi que la descripcion,
           la etiqueta y si solo cabe uno viven aqui y no repetidas en seis
           bloques de plantilla iguales. */
        tiposDePunto() {
            return {
                cars_exhibitor: {
                    titulo: this.T('ui.admin_panel.exhibition_vehicles'),
                    pie: this.T('ui.admin_panel.exhibition_points_description'),
                    etiqueta: 'Exhibidor',
                    unico: false,
                },
                car_testdrive: {
                    titulo: this.T('ui.admin_panel.test_drive_point_full'),
                    pie: this.T('ui.admin_panel.test_drive_location_description'),
                    etiqueta: this.T('ui.admin.test_point'),
                    unico: true,
                },
                car_delivery: {
                    titulo: this.T('ui.admin_panel.delivery_point'),
                    pie: this.T('ui.admin_panel.delivery_point_purchased'),
                    etiqueta: this.T('ui.admin.delivery_point'),
                    unico: true,
                },
                car_preview: {
                    titulo: this.T('ui.admin.preview_point'),
                    pie: this.T('ui.admin_panel.preview_point_description'),
                    etiqueta: this.T('ui.admin.preview_point'),
                    unico: true,
                },
                npcs: {
                    titulo: this.T('ui.admin.npc_seller'),
                    pie: this.T('ui.admin_panel.npc_description'),
                    etiqueta: this.T('ui.admin.npc_seller'),
                    unico: true,
                },
                markers: {
                    titulo: this.T('ui.admin.additional_markers'),
                    pie: this.T('ui.admin_panel.markers_description'),
                    etiqueta: this.T('ui.admin.marker'),
                    unico: false,
                },
            };
        },

        puntoActual() {
            return this.tiposDePunto[this.adminPanel.activeLocationTab]
                || this.tiposDePunto.cars_exhibitor;
        },

        creatorDescripcion() {
            const tipo = this.tiposDePunto[this.creatorMode.activeTab];
            return tipo ? tipo.pie : '';
        },

        creatorEtiqueta() {
            const tipo = this.tiposDePunto[this.creatorMode.activeTab];
            return tipo ? tipo.etiqueta : '';
        },

        currentCategoryVehicles() {
            if (this.selectedCategory === 'all_categories') {
                const allVehicles = [];
                Object.values(this.dealershipMenu.dealershipStock || {}).forEach(category => {
                    if (category.categoryStock && Array.isArray(category.categoryStock)) {
                        allVehicles.push(...category.categoryStock);
                    }
                });
                return allVehicles;
            }

            if (this.selectedCategory && this.dealershipMenu.dealershipStock[this.selectedCategory]) {
                return this.dealershipMenu.dealershipStock[this.selectedCategory].categoryStock;
            }

            return [];
        },

        filteredByPriceVehicles() {
            const vehicles = [...this.currentCategoryVehicles];

            if (!this.priceFilter.active) {
                return vehicles;
            }

            return vehicles.filter(vehicle => {
                const price = vehicle.price || 0;
                const min = this.priceFilter.min === '' || this.priceFilter.min === null ? null : Number(this.priceFilter.min);
                const max = this.priceFilter.max === '' || this.priceFilter.max === null ? null : Number(this.priceFilter.max);

                if (min !== null && max === null) {
                    return price >= min;
                }

                if (min === null && max !== null) {
                    return price <= max;
                }

                if (min !== null && max !== null) {
                    return price >= min && price <= max;
                }

                return true;
            });
        },

        sortedVehicles() {
            const vehicles = [...this.filteredByPriceVehicles];

            return vehicles.sort((a, b) => {
                let valueA, valueB;

                switch (this.sortBy) {
                    case 'name':
                        valueA = a.label.toLowerCase();
                        valueB = b.label.toLowerCase();
                        break;
                    case 'price':
                        valueA = a.price;
                        valueB = b.price;
                        break;
                    case 'xp':
                        valueA = a.xp;
                        valueB = b.xp;
                        break;
                    case 'class':
                        valueA = a.class;
                        valueB = b.class;
                        break;
                    default:
                        return 0;
                }

                if (this.sortOrder === 'asc') {
                    if (valueA < valueB) return -1;
                    if (valueA > valueB) return 1;
                    return 0;
                } else {
                    if (valueA > valueB) return -1;
                    if (valueA < valueB) return 1;
                    return 0;
                }
            });
        }, filteredDefaultVehicles() {
            const defaultVehicles = this.adminPanel.dealershipManagement.defaultGTAVehicles || [];
            if (!this.addVehicleModal.searchQuery) {
                return defaultVehicles;
            }

            const query = this.addVehicleModal.searchQuery.toLowerCase();
            return defaultVehicles.filter(vehicle =>
                vehicle.label.toLowerCase().includes(query) ||
                vehicle.model.toLowerCase().includes(query)
            );
        },

        sortedDefaultVehicles() {
            const vehicles = [...this.filteredDefaultVehicles];

            return vehicles.sort((a, b) => {
                let valueA, valueB;

                switch (this.sortBy) {
                    case 'name':
                        valueA = a.label.toLowerCase();
                        valueB = b.label.toLowerCase();
                        break;
                    case 'price':
                        valueA = a.label.toLowerCase();
                        valueB = b.label.toLowerCase();
                        break;
                    default:
                        valueA = a.label.toLowerCase();
                        valueB = b.label.toLowerCase();
                }

                if (this.sortOrder === 'asc') {
                    if (valueA < valueB) return -1;
                    if (valueA > valueB) return 1;
                    return 0;
                } else {
                    if (valueA > valueB) return -1;
                    if (valueA < valueB) return 1;
                    return 0;
                }
            });
        },

        isAddVehicleFormValid() {
            const form = this.addVehicleModal.form;
            // Precio mayor que 0: con >= 0 el formulario empezaba válido con el
            // precio a 0 y el coche salía a la venta gratis.
            const hasCashPayment = form.paymentMethods?.cash && Number(form.prices?.cash) > 0;
            const hasBankPayment = form.paymentMethods?.bank && Number(form.prices?.bank) > 0;
            const hasXPPayment = form.paymentMethods?.xp && Number(form.prices?.xp) > 0;
            const hasCompanyPayment = form.paymentMethods?.company && Number(form.prices?.company) > 0;

            if (form.stockEnabled) {
                const stock = parseInt(form.stock) || 0;
                if (stock < 0) {
                    return false;
                }
            }

            return form.category &&
                form.model && String(form.model).trim() &&
                form.label && String(form.label).trim() &&
                form.class &&
                form.paymentMethods &&
                (hasCashPayment || hasBankPayment || hasXPPayment || hasCompanyPayment);
        },

        isPriceFilterValid() {
            const min = this.priceFilter.min;
            const max = this.priceFilter.max;

            const hasValidMin = min !== null && min !== '' && min >= 0;
            const hasValidMax = max !== null && max !== '' && max >= 0;

            if (hasValidMin && hasValidMax) {
                return parseFloat(min) <= parseFloat(max);
            }

            return hasValidMin || hasValidMax;
        },
        existingVehicleModels() {
            const dealership = this.getDealershipById(this.adminPanel.dealershipManagement.selectedDealership);
            if (!dealership || !dealership.stock) return [];
            let models = [];
            Object.values(dealership.stock).forEach(category => {
                if (category.categoryStock && Array.isArray(category.categoryStock)) {
                    models.push(...category.categoryStock.map(v => v.model.toLowerCase()));
                }
            });
            return models;
        },

        filteredExhibitorVehicles() {
            if (!this.exhibitorConfigModal.searchQuery) {
                return this.exhibitorConfigModal.availableVehicles;
            }

            const query = this.exhibitorConfigModal.searchQuery.toLowerCase();
            return this.exhibitorConfigModal.availableVehicles.filter(vehicle =>
                vehicle.label.toLowerCase().includes(query) ||
                vehicle.model.toLowerCase().includes(query) ||
                vehicle.class.toLowerCase().includes(query)
            );
        },
        /* ── La columna del concesionario ─────────────────────────────── */
        dpTonos() {
            return [
                { hex: '#0d0d0f', nombre: 'Negro' },
                { hex: '#f4f1f6', nombre: 'Blanco' },
                { hex: '#c40b78', nombre: 'Rosa OGN' },
                { hex: '#7a034a', nombre: 'Granate' },
                { hex: '#2f7fe0', nombre: 'Azul' },
                { hex: '#3ce6a4', nombre: 'Menta' },
                { hex: '#f0b429', nombre: 'Ámbar' },
                { hex: '#ff4d5e', nombre: 'Rojo' },
                { hex: '#8a6a3a', nombre: 'Bronce' },
                { hex: '#5a5a66', nombre: 'Grafito' },
            ];
        },
        dpRanuras() {
            return [
                { id: 'primario', label: 'Principal', campo: 'primaryColorPicker' },
                { id: 'secundario', label: 'Secundario', campo: 'secondaryColorPicker' },
            ];
        },
        dpPestanas() {
            const l = [];
            if (this.catalogEnabled) l.push({ id: 'list', label: 'Catálogo' });
            l.push({ id: 'specs', label: 'Ficha' });
            if (!(this.dealershipInfo && this.dealershipInfo.liveInspect)) l.push({ id: 'color', label: 'Color' });
            return l;
        },
        dpTituloPestana() {
            const t = this.dpPestanas.find((x) => x.id === this.dpTab);
            return t ? t.label : '';
        },
        dpMetaPestana() {
            if (this.dpTab === 'list') {
                const total = this.dpCategorias.length ? this.dpCategorias[0].n : 0;
                return `${this.dpLista.length} de ${total} modelos`;
            }
            if (this.dpTab === 'color') return `${this.dpTonos.length} colores`;
            return this.selectedVehicle ? `Clase ${this.selectedVehicle.class}` : '';
        },
        dpCategorias() {
            const stock = this.dealershipMenu.dealershipStock || {};
            let total = 0;
            const l = Object.keys(stock).map((key) => {
                const n = (stock[key].categoryStock || []).length;
                total += n;
                return { key, label: stock[key].label || key, n };
            });
            const todas = this.T('ui.admin_panel.all_categories');
            return [{ key: 'all_categories', label: (todas && todas.indexOf('admin_panel.') === -1) ? todas : 'Todas las categorías', n: total }].concat(l);
        },
        dpLista() {
            const q = String(this.dpBusqueda || '').trim().toLowerCase();
            if (!q) return this.sortedVehicles;
            return this.sortedVehicles.filter((v) =>
                String(v.label || '').toLowerCase().includes(q) || String(v.model || '').toLowerCase().includes(q));
        },
        dpOrdenLabel() {
            if (this.sortBy === 'price') return this.sortOrder === 'asc' ? 'Precio ↑' : 'Precio ↓';
            if (this.sortBy === 'class') return 'Clase';
            if (this.sortBy === 'xp') return this.nombreXP;
            return 'Nombre';
        },
        dpCategoriaDelCoche() {
            const v = this.selectedVehicle;
            if (!v) return '';
            const stock = this.dealershipMenu.dealershipStock || {};
            const key = Object.keys(stock).find((k) => (stock[k].categoryStock || []).some((c) => c.model === v.model));
            return key ? (stock[key].label || key) : '';
        },
        dpSubtitulo() {
            const v = this.selectedVehicle;
            if (!v) return (this.dealershipInfo && this.dealershipInfo.name) || 'Elige un modelo del catálogo';
            // El modelo solo si dice algo que no diga ya el nombre.
            const modelo = String(v.model || '').toLowerCase() === String(v.label || '').toLowerCase() ? '' : v.model;
            return [this.dpCategoriaDelCoche, modelo, 'clase ' + v.class].filter(Boolean).join(' · ');
        },
        /* Las stats vienen de las nativas sin normalizar: se recortan a 0-100
           para que la barra no se salga. */
        dpStats() {
            return (this.dealershipMenu.currentVehicleStats || []).map((s) => ({
                k: s.label,
                v: Math.max(0, Math.min(100, Math.round(Number(s.value) || 0))),
            }));
        },
        dpDatos() {
            const v = this.selectedVehicle;
            if (!v) return [];
            const stat = (i) => (this.dpStats[i] ? this.dpStats[i].v : '—');
            return [
                { k: 'Potencia', v: stat(0), u: '/100' },
                { k: 'Punta', v: stat(1), u: '/100' },
                { k: 'Stock', v: v.stockEnabled ? v.stock : '∞', u: '', clase: v.stockEnabled && v.stock <= 0 ? 'dp-mal' : '' },
                { k: 'Plazos', v: v.financing ? 'Sí' : 'No', u: '', clase: v.financing ? 'dp-bien' : '' },
            ];
        },
        dpHoja() {
            const v = this.selectedVehicle;
            if (!v) return [];
            const pm = v.paymentMethods || {};
            const formas = [
                pm.cash && 'efectivo', pm.bank && 'banco', pm.xp && this.nombreXP, pm.company && 'empresa',
            ].filter(Boolean).join(', ');
            return [
                { k: 'Modelo', v: v.model },
                { k: 'Categoría', v: this.dpCategoriaDelCoche || '—' },
                { k: 'Clase', v: v.class },
                { k: 'Stock', v: v.stockEnabled ? String(v.stock) : 'sin límite' },
                { k: 'Financiación', v: v.financing ? 'disponible' : 'no' },
                { k: 'Se paga con', v: formas || '—' },
            ];
        },
        /* Los mismos métodos que ofrecia purchaseVehicleModal, en datos. */
        dpPago() {
            const v = this.selectedVehicle;
            const vacio = { metodos: [], agotado: false };
            if (!v) return vacio;
            const precio = parseInt(v.price) || 0;
            const xp = parseInt(v.xp) || 0;
            const pm = v.paymentMethods || { cash: precio > 0, bank: precio > 0, xp: xp > 0 };
            const precios = v.prices || { cash: precio, bank: precio, xp: xp };
            const agotado = !!v.stockEnabled && (v.stock || 0) <= 0;
            if (agotado) return { metodos: [], agotado: true };

            const dinero = (n) => '$' + (parseInt(n) || 0).toLocaleString('de-DE');
            const m = [];
            if (pm.cash) m.push({ id: 'cash', label: this.T('ui.payment_methods.cash') || 'Efectivo', precio: dinero(precios.cash || precio) });
            if (pm.bank) m.push({ id: 'bank', label: this.T('ui.payment_methods.bank_transfer') || 'Banco', precio: dinero(precios.bank || precio) });
            if (pm.xp) m.push({ id: 'xp', label: this.T('ui.payment_methods.experience') || (this.marca === 'nacion' ? 'Farm XP' : 'Experiencia'), precio: (parseInt(precios.xp) || xp) + ' ' + this.nombreXP });
            if (pm.company) m.push({ id: 'company', label: this.T('ui.payment_methods.company') || 'Empresa', precio: dinero(precios.company || precio) });
            const soloXp = pm.xp && !pm.cash && !pm.bank;
            if (v.financing && this.financingConfig && this.financingConfig.enabled !== false && !soloXp && (pm.cash || pm.bank)) {
                m.push({ id: 'financing', label: this.T('ui.payment_methods.financing') || 'Financiación', precio: 'a plazos' });
            }
            return { metodos: m, agotado: false };
        },
        dpPrecioMetodo() {
            const m = this.dpPago.metodos.find((x) => x.id === this.dpMetodo);
            return m ? m.precio : '—';
        },
        dpPuedeComprar() {
            return !!this.selectedVehicle && this.canPurchaseCurrent && this.dpPago.metodos.length > 0;
        },
        dpTextoComprar() {
            if (!this.selectedVehicle) return 'Comprar';
            if (!this.canPurchaseCurrent) return 'No se vende';
            if (this.dpPago.agotado) return 'Agotado';
            return 'Comprar';
        },
        dpAviso() {
            const v = this.selectedVehicle;
            if (!v) return '';
            if (!this.canPurchaseCurrent) return 'Este coche es de exposición: puedes mirarlo, pero no se vende aquí.';
            if (this.dpPago.agotado) return 'No queda ninguno en este concesionario. Prueba con otro modelo o vuelve más tarde.';
            if (this.dpPago.metodos.length === 0) return this.T('ui.payment_methods.no_payment_methods');
            return '';
        },

        catalogEnabled() {
            return this.dealershipInfo?.settings?.allowCatalog !== false && this.dealershipInfo?.allowCatalog !== false;
        },
        canPurchaseCurrent() {
            if (this.dealershipInfo?.interactionType !== 'exhibitor') return true;
            return this.dealershipInfo?.exhibitorAccess?.allowPurchase !== false;
        },
        canTestDriveCurrent() {
            if (this.dealershipInfo?.interactionType !== 'exhibitor') return true;
            return this.dealershipInfo?.exhibitorAccess?.allowTestDrive !== false;
        },
    },
    mounted() {

        this.vehiclesReady = true;

        this.loadTranslations().then(() => {
        }).catch(error => {
        });

        this.fetchEvent('getConfig', {}).then(data => {
            this.financingConfig = data.FinancingConfig;
        });

        this.dealerCache = {};

        this.initializeCameraControls();



        this.initializeCarrouselScroll();
        this.listener = window.addEventListener('message', (event) => {
            const data = event.data;

            if (data && data.accion === 'origen:marca:puesta') {
                this.marca = data.marca || 'origen';
                return;
            }

            // El Lua ha perdido el ratón a la fuerza (vigilante de foco): se
            // esconde todo lo que hubiera, o se queda pintado sin ratón ni Escape.
            if (data.action === 'forceClose') {
                if (this.financingModal && this.financingModal.visible) this.closeFinancingModal();
                if (this.exhibitorConfigModal && this.exhibitorConfigModal.visible) this.closeExhibitorConfigModal();
                if (this.addVehicleModal && this.addVehicleModal.visible) this.closeAddVehicleModal();
                this.dpFirma = false;
                this.CloseModal();
                this.closeDealershipMenu();
                if (this.adminPanel) this.adminPanel.visible = false;
            }

            if (data.action == 'closeTestDrive') {
                this.testDriving = false;
                this.stopTestDriveTimer();

                this.resetNUIState();
            }

            if (data.action == 'openDealership') {
                if (this.testDriving) {
                    this.resetNUIState();
                }

                this.cleanupDOM();
                this.previewEntryPending = true;

                this.$set(this.dealershipMenu, 'visible', true);

                this.dealershipInfo = data.dealershipMenu.dealershipInfo;
                // La columna empieza en el catálogo (o en la ficha si no hay catálogo).
                this.dpTab = this.catalogEnabled ? 'list' : 'specs';
                this.dpBusqueda = '';
                this.dpFirma = false;

                if (data.dealershipMenu && data.dealershipMenu.dealershipStock) {
                    this.$set(this.dealershipMenu, 'dealershipStock', data.dealershipMenu.dealershipStock);

                    Object.keys(data.dealershipMenu.dealershipStock).forEach(categoryId => {
                        const category = data.dealershipMenu.dealershipStock[categoryId];
                    });
                }
                if (data.dealershipMenu && data.dealershipMenu.dealershipInfo) {
                    this.$set(this.dealershipMenu, 'dealershipInfo', data.dealershipMenu.dealershipInfo);
                }

                if (this.dealershipInfo?.liveInspect) {
                    this.previewEntryPending = false;
                    this.loadingVehicleStats = false;
                    this.removeCameraControls();

                    const selectedCategory = this.dealershipInfo.selectedCategory || Object.keys(this.dealershipMenu.dealershipStock || {})[0] || 'all_categories';
                    const selectedVehicle = this.dealershipInfo.selectedVehicle || null;

                    this.$set(this, 'selectedCategory', selectedCategory);
                    this.$set(this, 'selectedVehicle', selectedVehicle);
                    this.currentVehicleLabel = selectedVehicle?.label || null;
                    this.currentVehiclePrice = selectedVehicle?.price || 0;
                    this.currentVehicleXP = selectedVehicle?.xp || 0;
                    this.currentVehicleFinancing = selectedVehicle?.financing || false;
                    this.$set(this.dealershipMenu, 'currentVehicleStats', this.dealershipInfo.currentVehicleStats || []);

                    this.$nextTick(() => {
                        this.initializeColorPickers();
                    });
                    return;
                }

                // closeDealershipMenu no limpia el coche elegido: al reabrir con el
                // mismo, dmSelectVehicle salía sin pedir vista previa y el juego
                // se quedaba esperando un previewReady que no llegaba (negro y cursor).
                this.selectedVehicle = null;

                const stateLoaded = this.loadDealerState();
                const focusVehicleModel = this.dealershipInfo?.focusVehicleModel;

                if (focusVehicleModel) {
                    this.selectVehicleByModel(focusVehicleModel);
                } else if (stateLoaded) {
                    const cachedVehicleData = this.findCachedVehicle();

                    if (cachedVehicleData) {
                        this.$set(this, 'selectedCategory', cachedVehicleData.category);
                        this.$set(this, 'selectedVehicle', cachedVehicleData.vehicle);
                        this.currentVehicleLabel = cachedVehicleData.vehicle.label;

                        this.$nextTick(() => {
                            this.fetchEvent('origen_dealerships:ui:changeVehiclePreview', {
                                model: cachedVehicleData.vehicle.model,
                                zoom: this.cameraControls.zoom,
                                rotation: this.cameraControls.rotation
                            }).then((result) => {
                                this.loadingVehicleStats = true;
                                this.dealershipMenu.currentVehicleStats = null;
                                const start4 = Date.now();
                                this.dealershipMenu.currentVehicleStats = [
                                    { label: 'Potencia', value: result.power },
                                    { label: 'Velocidad punta', value: result.high_speed },
                                    { label: 'Aceleración', value: result.acceleration * 100 },
                                    { label: 'Frenado', value: result.braking * 100 }
                                ];
                                this.loadingVehicleStats = false;
                                this.notifyPreviewReadyIfNeeded();
                            });
                        });
                    } else {
                        this.selectFirstAvailableVehicle();
                    }
                } else {
                    this.selectFirstAvailableVehicle();
                }

                // Si no se eligió ningún coche (todo agotado, o el enfocado lo
                // está), no se pide vista previa y previewReady no saldría nunca:
                // se manda ya para que el juego quite el negro. Con coche elegido
                // lo manda la respuesta de changeVehiclePreview, como siempre.
                this.$nextTick(() => {
                    if (this.previewEntryPending && !this.selectedVehicle) {
                        this.notifyPreviewReadyIfNeeded();
                    }
                });

                this.initializeCarrouselScroll();

                this.$nextTick(() => {
                    if (this.dealershipMenu.visible) {
                        this.initializeCameraControls();
                        this.initializeColorPickers();
                    }
                });
            }


            if (data.action === 'vehiclePhotoProgress') {
                this.photoGen.current = data.current || 0;
                this.photoGen.total = data.total || 0;
                this.photoGen.model = data.model || '';
            }

            if (data.action === 'vehiclePhotoCancelling') {
                this.photoGen.cancelling = true;
            }

            if (data.action === 'processVehiclePhoto') {
                this.handleRawVehiclePhoto(data.model, data.image);
            }

            if (data.action === 'openAdmin') {
                this.adminPanel.visible = true;

                this.adminPanel.dealershipManagement.defaultGTAVehicles = data.vehicles;

                if (data.dealerships && Array.isArray(data.dealerships)) {
                    const formattedDealerships = data.dealerships.map(d => this.formatearConcesionario(d));

                    this.$set(this.adminPanel.dealershipManagement, 'dealerships', formattedDealerships);
                }
            }


            if (data.action === "updateStages" || data.action === "startCreator") {

                this.creatorMode.active = true;
                this.creatorMode.stages = data.stages || [];

                const activeTabId = data.currentStage || 'cars_exhibitor';
                this.setCreatorTab(activeTabId);

                this.$nextTick(() => {
                    lucide.createIcons();
                });
            }


            if (data.action === "updatePoints") {
                this.creatorMode.points = data.data;
            }

            if (data.action === "dealershipCreated") {
                this.creatorMode.active = false;
            }

            if (data.action === "dealershipCancelled" || data.action === "creatorDisabled") {
                this.creatorMode.active = false;
            }

            if (data.action === "refreshDealerships") {
                if (data.dealerships && Array.isArray(data.dealerships)) {
                    const formattedDealerships = data.dealerships.map(d => this.formatearConcesionario(d));

                    this.$set(this.adminPanel.dealershipManagement, 'dealerships', formattedDealerships);
                }
            }

            if (data.action === "individualLocationMode") {
                this.creatorMode.active = true;
                this.creatorMode.stages = [data.currentStage];
                this.setCreatorTab(data.locationType);
                this.creatorMode.points = data.data;
                this.$nextTick(() => {
                    lucide.createIcons();
                });
            }

            if (data.action === "individualLocationFinished" || data.action === "individualLocationCancelled") {
                this.creatorMode.active = false;
                if (!data.onlyCreator) {
                    this.adminPanel.visible = true;
                }

                this.$nextTick(() => {
                    this.fetchEvent('maintainNuiFocus', {});
                });
            }
        });

        window.addEventListener('keydown', this.handleKeyDown);

        this.boundLocationsWheelHandler = (event) => {
            const target = event.target;
            if (!target || typeof target.closest !== 'function') return;

            const locationsList = target.closest('.locations-list');
            if (!locationsList) return;

            if (locationsList.scrollHeight <= locationsList.clientHeight) return;

            event.preventDefault();
            event.stopPropagation();
            locationsList.scrollTop += event.deltaY;
        };
        document.addEventListener('wheel', this.boundLocationsWheelHandler, {
            passive: false,
            capture: true
        });

        // La paleta de colores del coche, escuchada una sola vez y desde arriba:
        // el panel del coche se monta y desmonta con v-if y un escuchador
        // pegado al campo se perdía (o se duplicaba al volver a pegarlo).
        document.addEventListener('change', (event) => {
            const id = event.target && event.target.id;
            if (id === 'primaryColorPicker') {
                this.handlePrimaryColorChange(event.target.value);
            } else if (id === 'secondaryColorPicker') {
                this.handleSecondaryColorChange(event.target.value);
            }
        });

        lucide.createIcons();
        Coloris({
            themeMode: 'dark',
            alpha: false,
            theme: 'pill',
            el: '.coloris',
            margin: 2,
            format: 'rgb',
            focusInput: true,
            onChange: (color, input) => {
                if (input.classList.contains('instance2')) {
                    this.handlePrimaryColorChange(color);
                } else if (input.classList.contains('instance3')) {
                    this.handleSecondaryColorChange(color);
                }
            }
        });



        const carrousel = document.querySelector('.vehicle-carrousel');
        if (!carrousel) return;

        carrousel.addEventListener('wheel', function (e) {
            if (e.deltaY !== 0) {
                e.preventDefault();
                carrousel.scrollBy({
                    left: e.deltaY * 10,
                    behavior: 'smooth'
                });
            }
        }, {
            passive: false
        });

        let isDown = false;
        let startX;
        let scrollLeft;

        carrousel.addEventListener('mousedown', (e) => {
            isDown = true;
            startX = e.pageX - carrousel.offsetLeft;
            scrollLeft = carrousel.scrollLeft;
        });

        carrousel.addEventListener('mouseup', () => {
            isDown = false;
        });

        carrousel.addEventListener('mouseleave', () => {
            isDown = false;
        }); carrousel.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();

            const x = e.pageX - carrousel.offsetLeft;
            const walk = (x - startX) * 2;
            carrousel.scrollLeft = scrollLeft - walk;
        });


    },
    updated() {
        // Solo lo que hace falta en cada repintado. Aquí también se volvía a
        // llamar a Coloris (ya no hay ningún campo `.coloris`) y se añadía OTRO
        // escuchador de rueda a document en cada repintado sin quitar el
        // anterior: durante una prueba de manejo el temporizador repinta cada
        // segundo, así que se sumaba uno por segundo. Ahora se pone una vez en
        // mounted.
        lucide.createIcons();
        this.initializeCarrouselScroll();
    },

    beforeDestroy() {
        window.removeEventListener('message', this.listener);
        window.removeEventListener('keydown', this.handleKeyDown);
        this.stopTestDriveTimer();

        if (this.cameraUpdateThrottle) {
            clearTimeout(this.cameraUpdateThrottle);
        }

        this.removeCameraControls();

        if (this.boundLocationsWheelHandler) {
            document.removeEventListener('wheel', this.boundLocationsWheelHandler, true);
            this.boundLocationsWheelHandler = null;
        }
    },

    watch: {
        'addVehicleModal.form.prices.cash': {
            handler(newValue) {
                if (newValue > 0) {
                    this.addVehicleModal.form.price = newValue;
                }
            }
        },

        'addVehicleModal.form.prices.xp': {
            handler(newValue) {
                if (newValue > 0) {
                    this.addVehicleModal.form.xp = newValue;
                }
            }
        },
        sortedVehicles() {
            this.vehiclesReady = false;
            this.$nextTick(() => {
                this.vehiclesReady = true;
            });
        },
    }

})

/* Los avisos de la pantalla van a origen_notify, como los del resto del
   servidor: la NUI se lo pide al cliente de Lua por el callback `notificar`
   (client/main.lua) y él llama al export con el título «Concesionario».
   Antes era una caja propia arriba en el centro, con otro aspecto. */
function showNotification(message, type = 'info', duration = 5000) {
    if (!message) return;
    fetch(`https://${GetParentResourceName()}/notificar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ description: String(message), type: type, duration: duration })
    }).catch(() => {});
}

window.showNotification = showNotification;