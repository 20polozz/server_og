/* ==========================================================================
   ORIGEN AUTOESCUELA · ADMIN PANEL & RECORDING HUD JS
   ========================================================================== */
/*  OJO: este fichero y admin.css viven en source-ui/public/assets a proposito.
    Antes estaban sueltos en ui/assets y el `vite build` (emptyOutDir) se los
    llevo por delante: el panel dejo de existir y abrirlo desde Scripts dejaba
    el raton preso sin nada en pantalla. En public/ Vite los copia a ui/ en
    cada compilacion. index.html los enlaza con ruta absoluta (/assets/...),
    que el build reescribe a ./assets/... */

(function () {
    let adminVisible = false;
    let hudVisible = false;
    let currentView = 'rutas'; // 'rutas' | 'carnets'
    let currentTab = 'todas';
    let routesList = [];
    let modalCreateOpen = false;
    // Solo en la plantilla de Origen: la ruta que espera confirmacion de
    // borrado (alli no hay confirm() del navegador) y si falta el nombre.
    let borrarPendiente = null;
    let nombreFalta = false;

    // Estado gestión y entrega de carnets
    let playersList = [];
    let playerFilter = 'todos'; // 'todos' | 'con_conducir' | 'sin_conducir' | 'con_vuelo' | 'sin_vuelo'
    let playerSearchQuery = '';
    let modalLicenseOpen = false;
    let selectedPlayerForLicense = null;
    let selectedLicenseType = 'conducir'; // 'conducir' | 'vuelo'
    let selectedLicenseLevel = 1; // 0..3
    let licenseSubmitting = false;

    // Elementos DOM
    let rootContainer = null;

    const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'origen_autoescuela';

    function postNui(callback, data = {}) {
        return fetch(`https://${resourceName}/${callback}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        }).then(r => r.json()).catch(() => ({}));
    }

    // Inicializar contenedor en el DOM
    function init() {
        rootContainer = document.getElementById('autoescuela-admin-container');
        if (!rootContainer) {
            rootContainer = document.createElement('div');
            rootContainer.id = 'autoescuela-admin-container';
            document.body.appendChild(rootContainer);
        }

        window.addEventListener('message', onMessage);
        window.addEventListener('keydown', onKey);
    }

    /*  ESC: primero lo que haya encima (el formulario de ruta nueva, el
        modal de entrega de carnet, el «¿borrar?» pendiente); si no hay nada, sale del panel. */
    function onKey(e) {
        if (e.key !== 'Escape' || !adminVisible) return;
        e.preventDefault();
        if (modalLicenseOpen) { modalLicenseOpen = false; selectedPlayerForLicense = null; renderAdmin(); return; }
        if (modalCreateOpen) { modalCreateOpen = false; nombreFalta = false; renderAdmin(); return; }
        if (borrarPendiente !== null) { borrarPendiente = null; renderAdmin(); return; }
        postNui('adminCerrar');
    }

    function onMessage(event) {
        const d = event.data || {};
        switch (d.accion) {
            case 'autoescuela:abrirAdmin':
                abrirAdmin();
                break;
            case 'autoescuela:cerrarAdmin':
                cerrarAdmin();
                break;
            case 'autoescuela:hudGrabacion:mostrar':
                mostrarHud(d.datos);
                break;
            case 'autoescuela:hudGrabacion:ocultar':
                ocultarHud();
                break;
            case 'autoescuela:hudGrabacion:actualizar':
                actualizarHud(d.datos || {});
                break;
        }
    }

    // =========================================================================
    // RENDERIZADO DEL PANEL ADMIN
    // =========================================================================

    function abrirAdmin() {
        adminVisible = true;
        modalCreateOpen = false;
        modalLicenseOpen = false;
        borrarPendiente = null;
        nombreFalta = false;
        renderAdmin();
        cargarRutas();
        cargarJugadores();
    }

    function cerrarAdmin() {
        adminVisible = false;
        modalCreateOpen = false;
        modalLicenseOpen = false;
        borrarPendiente = null;
        renderAdmin();
    }

    function cargarRutas() {
        postNui('admin:getRutas').then(res => {
            if (res && res.ok && Array.isArray(res.rutas)) {
                routesList = res.rutas;
            } else {
                routesList = [];
            }
            if (adminVisible && currentView === 'rutas') renderAdmin();
        });
    }

    function cargarJugadores() {
        return postNui('admin:getJugadores').then(res => {
            if (res && res.ok && Array.isArray(res.jugadores)) {
                playersList = res.jugadores;
            } else {
                playersList = [];
            }
            if (adminVisible && currentView === 'carnets') renderAdmin();
        });
    }

    function renderAdmin() {
        if (!rootContainer) return;

        if (!adminVisible) {
            const adminEl = document.getElementById('ae-admin-overlay-root');
            if (adminEl) adminEl.remove();
            return;
        }

        let adminEl = document.getElementById('ae-admin-overlay-root');
        if (!adminEl) {
            adminEl = document.createElement('div');
            adminEl.id = 'ae-admin-overlay-root';
            adminEl.className = 'ae-admin-overlay';
            rootContainer.appendChild(adminEl);
        }

        // Filtrar rutas según pestaña
        const filteredRoutes = routesList.filter(r => {
            if (currentTab === 'todas') return true;
            return r.carnet === currentTab;
        });

        // Contadores por categoría
        const countTodas = routesList.length;
        const countCoche = routesList.filter(r => r.carnet === 'coche').length;
        const countMoto = routesList.filter(r => r.carnet === 'moto').length;
        const countCamion = routesList.filter(r => r.carnet === 'camion').length;

        // La plantilla pegatina, en las dos marcas.
        if (esOrigen()) {
            adminEl.className = 'aep-raiz';
            adminEl.innerHTML = plantillaOrigen(filteredRoutes, { todas: countTodas, coche: countCoche, moto: countMoto, camion: countCamion });
            bindAdminEvents();
            return;
        }
        adminEl.className = 'ae-admin-overlay';

        const query = (playerSearchQuery || '').trim().toLowerCase();
        const filteredPlayers = playersList.filter(p => {
            if (query) {
                const idStr = String(p.id);
                const nameStr = (p.name || '').toLowerCase();
                const charStr = (p.charname || '').toLowerCase();
                const cidStr = (p.citizenid || '').toLowerCase();
                if (!idStr.includes(query) && !nameStr.includes(query) && !charStr.includes(query) && !cidStr.includes(query)) return false;
            }
            if (playerFilter === 'con_conducir') return (p.nivelConducir || 0) > 0;
            if (playerFilter === 'sin_conducir') return (p.nivelConducir || 0) === 0;
            if (playerFilter === 'con_vuelo') return (p.nivelVuelo || 0) > 0;
            if (playerFilter === 'sin_vuelo') return (p.nivelVuelo || 0) === 0;
            return true;
        });

        adminEl.innerHTML = `
            <div class="ae-admin-window">
                <!-- Header -->
                <div class="ae-admin-header">
                    <div class="ae-header-title-box">
                        <div class="ae-header-icon">
                            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="16" rx="2"/><line x1="7" y1="8" x2="17" y2="8"/><line x1="7" y1="12" x2="17" y2="12"/><line x1="7" y1="16" x2="12" y2="16"/>
                            </svg>
                        </div>
                        <div class="ae-header-titles">
                            <h1>AUTOESCUELA · PANEL DE ADMINISTRACIÓN</h1>
                            <p>${currentView === 'rutas' ? 'CIRCUITOS Y EXÁMENES PRÁCTICOS DE CONDUCCIÓN (COCHE · MOTO · CAMIÓN)' : 'GESTIÓN Y ENTREGA DIRECTA DE CARNETS DE CONDUCIR Y LICENCIAS DE VUELO'}</p>
                        </div>
                    </div>
                    <div class="ae-header-actions">
                        <div style="display:flex; gap:0.6vh; margin-right:1vh;">
                            <button class="ae-btn ${currentView === 'rutas' ? 'ae-btn-accent' : 'ae-btn-subtle'} ae-view-tab" data-view="rutas">CIRCUITOS</button>
                            <button class="ae-btn ${currentView === 'carnets' ? 'ae-btn-accent' : 'ae-btn-subtle'} ae-view-tab" data-view="carnets">ENTREGA CARNETS</button>
                        </div>
                        ${currentView === 'rutas' ? `
                            <button class="ae-btn ae-btn-accent" id="ae-btn-nueva-ruta">
                                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                                CREAR NUEVA RUTA
                            </button>
                        ` : `
                            <button class="ae-btn ae-btn-subtle" id="ae-btn-refrescar" title="Actualizar lista">
                                ACTUALIZAR
                            </button>
                            <button class="ae-btn ae-btn-accent" id="ae-btn-entrega-rapida">
                                ENTREGA POR ID
                            </button>
                        `}
                        <button class="ae-btn ae-btn-subtle" id="ae-btn-cerrar">
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                        </button>
                    </div>
                </div>

                ${currentView === 'rutas' ? `
                    <!-- Tabs -->
                    <div class="ae-tabs-bar">
                        <button class="ae-tab ${currentTab === 'todas' ? 'active' : ''}" data-tab="todas">TODAS (${countTodas})</button>
                        <button class="ae-tab ${currentTab === 'coche' ? 'active' : ''}" data-tab="coche">COCHE (${countCoche})</button>
                        <button class="ae-tab ${currentTab === 'moto' ? 'active' : ''}" data-tab="moto">MOTO (${countMoto})</button>
                        <button class="ae-tab ${currentTab === 'camion' ? 'active' : ''}" data-tab="camion">CAMIÓN (${countCamion})</button>
                    </div>

                    <!-- Cards Grid -->
                    <div class="ae-routes-scroll">
                        ${filteredRoutes.length === 0 ? `
                            <div class="ae-empty-box">
                                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="rgba(255,255,255,0.25)" stroke-width="1.5" style="margin-bottom: 1.5vh;"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
                                <h3>NO HAY RUTAS REGISTRADAS</h3>
                                <p>No se encontraron circuitos para este filtro. Crea un nuevo circuito conduciendo por la ciudad para añadirlo a los exámenes.</p>
                                <button class="ae-btn ae-btn-accent" id="ae-btn-empty-crear">CREAR PRIMERA RUTA</button>
                            </div>
                        ` : filteredRoutes.map(r => renderRouteCard(r)).join('')}
                    </div>
                ` : `
                    <!-- Tabs Jugadores -->
                    <div class="ae-tabs-bar" style="justify-content: space-between;">
                        <div style="display:flex; gap:0.8vh;">
                            <button class="ae-tab ae-player-filter ${playerFilter === 'todos' ? 'active' : ''}" data-player-filter="todos">TODOS (${playersList.length})</button>
                            <button class="ae-tab ae-player-filter ${playerFilter === 'con_conducir' ? 'active' : ''}" data-player-filter="con_conducir">CON CONDUCIR</button>
                            <button class="ae-tab ae-player-filter ${playerFilter === 'sin_conducir' ? 'active' : ''}" data-player-filter="sin_conducir">SIN CONDUCIR</button>
                            <button class="ae-tab ae-player-filter ${playerFilter === 'con_vuelo' ? 'active' : ''}" data-player-filter="con_vuelo">CON VUELO</button>
                            <button class="ae-tab ae-player-filter ${playerFilter === 'sin_vuelo' ? 'active' : ''}" data-player-filter="sin_vuelo">SIN VUELO</button>
                        </div>
                        <input type="text" class="ae-input" id="ae-input-buscar-jugador" placeholder="Buscar jugador..." value="${escapeHtml(playerSearchQuery)}" style="width:25vh; margin:0;" />
                    </div>

                    <!-- Cards Grid Jugadores -->
                    <div class="ae-routes-scroll">
                        ${filteredPlayers.length === 0 ? `
                            <div class="ae-empty-box">
                                <h3>NO SE ENCONTRARON JUGADORES</h3>
                                <p>No hay jugadores conectados que coincidan con el filtro actual.</p>
                            </div>
                        ` : filteredPlayers.map(j => renderPlayerCard(j)).join('')}
                    </div>
                `}
            </div>

            <!-- Modales -->
            ${modalCreateOpen ? renderCreateModal() : ''}
            ${modalLicenseOpen ? dialogoEntregarLicenciaOrigen() : ''}
        `;

        bindAdminEvents();
    }

    function renderRouteCard(r) {
        const puntos = Array.isArray(r.puntos) ? r.puntos : [];
        const stopsCount = puntos.filter(p => p.accion === 'stop' || p.stop).length;
        const girosIzq = puntos.filter(p => p.accion === 'giro_izq').length;
        const girosDer = puntos.filter(p => p.accion === 'giro_der').length;
        const emergencias = puntos.filter(p => p.accion === 'emergencia').length;
        const semaforos = puntos.filter(p => p.accion === 'semaforo').length;
        const parking = puntos.some(p => p.accion === 'aparcar') || !!r.plaza;

        const km = (r.distancia / 1000).toFixed(1);
        const estaActiva = r.activo === true || r.activo === 1 || r.activo === '1';

        return `
            <div class="ae-route-card" data-id="${r.id}">
                <div>
                    <div class="ae-card-header">
                        <div class="ae-card-title-box">
                            <span class="ae-badge ae-badge-${r.carnet}">${r.carnet.toUpperCase()}</span>
                            <div class="ae-card-title">${escapeHtml(r.nombre)}</div>
                        </div>
                        <button class="ae-status-btn ${estaActiva ? 'active' : 'inactive'}" data-action="toggle-status" data-id="${r.id}" data-activo="${estaActiva}" title="Clic para alternar estado">
                            <span class="ae-status-dot"></span>
                            <span>${estaActiva ? 'ACTIVA' : 'INACTIVA'}</span>
                        </button>
                    </div>

                    <div class="ae-card-desc">${r.descripcion ? escapeHtml(r.descripcion) : 'Sin descripción detallada.'}</div>

                    <div class="ae-card-stats">
                        <div class="ae-stat-item">
                            <span>PUNTOS:</span>
                            <span class="ae-stat-val">${puntos.length}</span>
                        </div>
                        <div class="ae-stat-item">
                            <span>DISTANCIA:</span>
                            <span class="ae-stat-val">${km} KM</span>
                        </div>
                        <div class="ae-stat-item">
                            <span>CREADO:</span>
                            <span class="ae-stat-val">${escapeHtml(r.creado_por || 'ADMIN')}</span>
                        </div>
                    </div>

                    <div class="ae-actions-breakdown">
                        ${stopsCount > 0 ? `<div class="ae-action-chip">🛑 ${stopsCount} STOPS</div>` : ''}
                        ${girosIzq > 0 ? `<div class="ae-action-chip">⬅️ ${girosIzq} GIROS IZQ</div>` : ''}
                        ${girosDer > 0 ? `<div class="ae-action-chip">➡️ ${girosDer} GIROS DER</div>` : ''}
                        ${semaforos > 0 ? `<div class="ae-action-chip">🚦 ${semaforos} SEMÁFOROS</div>` : ''}
                        ${emergencias > 0 ? `<div class="ae-action-chip">⚡ ${emergencias} FRENADA</div>` : ''}
                        ${parking ? `<div class="ae-action-chip">APARCAMIENTO</div>` : ''}
                    </div>
                </div>

                <div class="ae-card-footer">
                    <button class="ae-btn ${estaActiva ? 'ae-btn-subtle' : 'ae-btn-success'}" data-action="toggle-status" data-id="${r.id}" data-activo="${estaActiva}">
                        ${estaActiva ? `
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                            DESACTIVAR
                        ` : `
                            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="20 6 9 17 4 12"/></svg>
                            ACTIVAR
                        `}
                    </button>
                    <button class="ae-btn ae-btn-danger" data-action="delete" data-id="${r.id}">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                        ELIMINAR
                    </button>
                </div>
            </div>
        `;
    }

    function renderPlayerCard(j) {
        const infoConducir = obtenerInfoLicencia('conducir', j.nivelConducir || 0);
        const infoVuelo = obtenerInfoLicencia('vuelo', j.nivelVuelo || 0);
        const tieneConducir = (j.nivelConducir || 0) > 0;
        const tieneVuelo = (j.nivelVuelo || 0) > 0;

        return `
            <div class="ae-route-card ae-player-card" data-id="${j.id}">
                <div>
                    <div class="ae-card-header">
                        <div class="ae-card-title-box">
                            <span class="ae-badge ae-badge-coche">ID ${j.id}</span>
                            <div class="ae-card-title">${escapeHtml(j.charname || j.name)}</div>
                        </div>
                    </div>
                    <div class="ae-card-desc">Steam: ${escapeHtml(j.name)} · CID: ${escapeHtml(j.citizenid || 'N/A')}</div>
                    <div class="ae-card-stats" style="grid-template-columns: 1fr 1fr;">
                        <div class="ae-stat-item">
                            <span>CONDUCIR:</span>
                            <span class="ae-stat-val ${tieneConducir ? 'ae-val-ok' : ''}">${infoConducir.nombre}</span>
                        </div>
                        <div class="ae-stat-item">
                            <span>VUELO:</span>
                            <span class="ae-stat-val ${tieneVuelo ? 'ae-val-ok' : ''}">${infoVuelo.nombre}</span>
                        </div>
                    </div>
                </div>
                <div class="ae-card-footer">
                    <button class="ae-btn ae-btn-subtle ae-btn-licencia" data-id="${j.id}" data-tipo="conducir">
                        CARNÉ CONDUCIR
                    </button>
                    <button class="ae-btn ae-btn-accent ae-btn-licencia" data-id="${j.id}" data-tipo="vuelo">
                        LICENCIA VUELO
                    </button>
                </div>
            </div>
        `;
    }

    function renderCreateModal() {
        return `
            <div class="ae-modal-overlay" id="ae-modal-overlay">
                <div class="ae-modal-box">
                    <div class="ae-modal-header">
                        <h2>CREAR NUEVA RUTA DE EXAMEN</h2>
                        <button class="ae-btn ae-btn-subtle" id="ae-modal-cerrar">✕</button>
                    </div>

                    <div class="ae-form-group">
                        <label>NOMBRE DEL CIRCUITO</label>
                        <input type="text" class="ae-input" id="ae-input-nombre" placeholder="EJ: CIRCUITO CENTRO - VESPUCCI" maxlength="60" />
                    </div>

                    <div class="ae-form-group">
                        <label>TIPO DE CARNET DE CONDUCIR</label>
                        <div class="ae-radio-row">
                            <div class="ae-radio-pill selected" data-carnet="coche">COCHE</div>
                            <div class="ae-radio-pill" data-carnet="moto">MOTO</div>
                            <div class="ae-radio-pill" data-carnet="camion">CAMIÓN</div>
                        </div>
                    </div>

                    <div class="ae-form-group">
                        <label>DESCRIPCIÓN (OPCIONAL)</label>
                        <textarea class="ae-textarea" id="ae-input-desc" placeholder="Detalles de maniobras, rotondas, dificultad..."></textarea>
                    </div>

                    <div class="ae-info-box">
                        <strong>INSTRUCCIONES DE TRAZADO IC:</strong><br/>
                        Al confirmar, se cerrará el panel y entrarás en el modo de trazado montado en tu vehículo.<br/>
                        · <strong>[E]</strong> Colocar punto de control en la posición del vehículo.<br/>
                        · <strong>[G]</strong> Cambiar tipo de acción (STOP, giro intermitente, semáforo, etc.).<br/>
                        · <strong>[↑/↓]</strong> Ajustar límite de velocidad del tramo.<br/>
                        · <strong>[←/→]</strong> Ajustar radio del punto.<br/>
                        · <strong>[INTRO]</strong> Guardar y finalizar la ruta.
                    </div>

                    <div class="ae-modal-actions">
                        <button class="ae-btn ae-btn-subtle" id="ae-btn-modal-cancel">CANCELAR</button>
                        <button class="ae-btn ae-btn-accent" id="ae-btn-modal-start">COMENZAR TRAZADO (EN VEHÍCULO)</button>
                    </div>
                </div>
            </div>
        `;
    }

    function bindAdminEvents() {
        // Selector de vista (Circuitos vs Carnets)
        document.querySelectorAll('.ae-view-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                currentView = tab.dataset.view;
                if (currentView === 'carnets') {
                    cargarJugadores();
                } else {
                    cargarRutas();
                }
                renderAdmin();
            });
        });

        // Pestañas de circuitos
        document.querySelectorAll('.ae-tab[data-tab]').forEach(tab => {
            tab.addEventListener('click', () => {
                currentTab = tab.dataset.tab;
                renderAdmin();
            });
        });

        // Filtro de jugadores
        document.querySelectorAll('.ae-player-filter').forEach(btn => {
            btn.addEventListener('click', () => {
                playerFilter = btn.dataset.playerFilter;
                renderAdmin();
            });
        });

        // Buscador de jugadores
        const inputBuscar = document.getElementById('ae-input-buscar-jugador');
        if (inputBuscar) {
            inputBuscar.addEventListener('input', (e) => {
                playerSearchQuery = e.target.value;
                renderAdmin();
                const nuevoInput = document.getElementById('ae-input-buscar-jugador');
                if (nuevoInput) {
                    nuevoInput.focus();
                    const len = nuevoInput.value.length;
                    nuevoInput.setSelectionRange(len, len);
                }
            });
        }

        const btnLimpiar = document.getElementById('ae-btn-limpiar-busqueda');
        if (btnLimpiar) {
            btnLimpiar.addEventListener('click', () => {
                playerSearchQuery = '';
                renderAdmin();
            });
        }

        // Refrescar jugadores
        const btnRefrescar = document.getElementById('ae-btn-refrescar');
        if (btnRefrescar) {
            btnRefrescar.addEventListener('click', () => {
                cargarJugadores();
            });
        }

        // Botón Nueva Ruta
        const btnNueva = document.getElementById('ae-btn-nueva-ruta');
        if (btnNueva) {
            btnNueva.addEventListener('click', () => {
                modalCreateOpen = true;
                renderAdmin();
            });
        }

        const btnEmptyCrear = document.getElementById('ae-btn-empty-crear');
        if (btnEmptyCrear) {
            btnEmptyCrear.addEventListener('click', () => {
                modalCreateOpen = true;
                renderAdmin();
            });
        }

        // Entrega rápida de licencia por ID manual
        const abrirModalRapida = () => {
            selectedPlayerForLicense = null;
            selectedLicenseType = 'conducir';
            selectedLicenseLevel = 1;
            modalLicenseOpen = true;
            renderAdmin();
        };

        const btnRapida = document.getElementById('ae-btn-entrega-rapida');
        if (btnRapida) btnRapida.addEventListener('click', abrirModalRapida);
        const btnEmptyEntrega = document.getElementById('ae-btn-empty-entrega');
        if (btnEmptyEntrega) btnEmptyEntrega.addEventListener('click', abrirModalRapida);

        // Entrega directa desde tarjeta de jugador
        document.querySelectorAll('.ae-btn-licencia').forEach(btn => {
            btn.addEventListener('click', () => {
                const id = Number(btn.dataset.id);
                const tipo = btn.dataset.tipo || 'conducir';
                const p = playersList.find(x => x.id === id);
                if (p) {
                    selectedPlayerForLicense = p;
                    selectedLicenseType = tipo;
                    const nivelActual = tipo === 'vuelo' ? (p.nivelVuelo || 0) : (p.nivelConducir || 0);
                    selectedLicenseLevel = nivelActual < 3 ? (nivelActual + 1) : nivelActual;
                    modalLicenseOpen = true;
                    renderAdmin();
                }
            });
        });

        // Cerrar panel
        const btnCerrar = document.getElementById('ae-btn-cerrar');
        if (btnCerrar) {
            btnCerrar.addEventListener('click', () => {
                postNui('adminCerrar');
            });
        }

        // Toggle Activo
        document.querySelectorAll('[data-action="toggle-status"]').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const id = btn.dataset.id;
                const actual = btn.dataset.activo === 'true' || btn.dataset.activo === true || btn.dataset.activo === '1';
                btn.disabled = true;
                postNui('admin:toggleRuta', { id: id, activo: !actual }).then(() => {
                    cargarRutas();
                });
            });
        });

        // Eliminar ruta
        document.querySelectorAll('[data-action="delete"]').forEach(btn => {
            btn.addEventListener('click', () => {
                const id = btn.dataset.id;
                // En Origen se pregunta con un dialogo propio.
                if (esOrigen()) {
                    borrarPendiente = id;
                    renderAdmin();
                    return;
                }
                if (confirm('¿ESTÁS SEGURO DE QUE DESEAS ELIMINAR ESTA RUTA DE EXAMEN?')) {
                    postNui('admin:borrarRuta', { id: id }).then(() => {
                        cargarRutas();
                    });
                }
            });
        });

        // El dialogo de borrar (plantilla de Origen)
        const btnBorrarNo = document.getElementById('ae-btn-borrar-no');
        if (btnBorrarNo) {
            btnBorrarNo.addEventListener('click', () => {
                borrarPendiente = null;
                renderAdmin();
            });
        }
        const btnBorrarSi = document.getElementById('ae-btn-borrar-si');
        if (btnBorrarSi) {
            btnBorrarSi.addEventListener('click', () => {
                const id = borrarPendiente;
                borrarPendiente = null;
                btnBorrarSi.disabled = true;
                postNui('admin:borrarRuta', { id: id }).then(() => {
                    cargarRutas();
                });
            });
        }

        // Eventos del modal Crear Ruta
        if (modalCreateOpen) {
            let selectedCarnet = 'coche';

            const modalCerrar = document.getElementById('ae-modal-cerrar');
            if (modalCerrar) {
                modalCerrar.addEventListener('click', () => {
                    modalCreateOpen = false;
                    renderAdmin();
                });
            }

            const btnCancel = document.getElementById('ae-btn-modal-cancel');
            if (btnCancel) {
                btnCancel.addEventListener('click', () => {
                    modalCreateOpen = false;
                    renderAdmin();
                });
            }

            document.querySelectorAll('.ae-radio-pill').forEach(pill => {
                pill.addEventListener('click', () => {
                    document.querySelectorAll('.ae-radio-pill').forEach(p => p.classList.remove('selected'));
                    pill.classList.add('selected');
                    selectedCarnet = pill.dataset.carnet;
                });
            });

            const btnStart = document.getElementById('ae-btn-modal-start');
            if (btnStart) {
                btnStart.addEventListener('click', () => {
                    const nombre = (document.getElementById('ae-input-nombre').value || '').trim();
                    const desc = (document.getElementById('ae-input-desc').value || '').trim();

                    if (!nombre && esOrigen()) {
                        // Sin alert(): se marca el campo y se le da el foco.
                        const campo = document.getElementById('ae-input-nombre');
                        campo.classList.add('aep-campo__i--falta');
                        campo.focus();
                        return;
                    }
                    if (!nombre) {
                        alert('POR FAVOR, INTRODUCE UN NOMBRE PARA LA RUTA');
                        return;
                    }

                    postNui('admin:startRecording', {
                        nombre: nombre,
                        carnet: selectedCarnet,
                        descripcion: desc
                    }).then(res => {
                        if (res && res.ok) {
                            cerrarAdmin();
                        }
                    });
                });
            }
        }

        // Eventos del modal Entregar Licencia
        if (modalLicenseOpen) {
            document.querySelectorAll('.ae-tipo-pill').forEach(pill => {
                pill.addEventListener('click', () => {
                    selectedLicenseType = pill.dataset.tipo;
                    if (selectedPlayerForLicense) {
                        const nivelActual = selectedLicenseType === 'vuelo' ? (selectedPlayerForLicense.nivelVuelo || 0) : (selectedPlayerForLicense.nivelConducir || 0);
                        selectedLicenseLevel = nivelActual < 3 ? (nivelActual + 1) : nivelActual;
                    }
                    renderAdmin();
                });
            });

            document.querySelectorAll('.aep-nivel-opcion').forEach(opt => {
                opt.addEventListener('click', () => {
                    selectedLicenseLevel = Number(opt.dataset.nivel);
                    renderAdmin();
                });
            });

            const btnCancelLic = document.getElementById('ae-btn-licencia-cancel');
            if (btnCancelLic) {
                btnCancelLic.addEventListener('click', () => {
                    modalLicenseOpen = false;
                    selectedPlayerForLicense = null;
                    renderAdmin();
                });
            }

            const btnConfirmLic = document.getElementById('ae-btn-licencia-confirm');
            if (btnConfirmLic) {
                btnConfirmLic.addEventListener('click', () => {
                    let targetId = selectedPlayerForLicense ? selectedPlayerForLicense.id : null;
                    if (!targetId) {
                        const inputId = document.getElementById('ae-input-licencia-id');
                        targetId = inputId ? Number(inputId.value) : null;
                    }

                    if (!targetId || targetId <= 0) {
                        const inputId = document.getElementById('ae-input-licencia-id');
                        if (inputId) {
                            inputId.classList.add('aep-campo__i--falta');
                            inputId.focus();
                        }
                        return;
                    }

                    licenseSubmitting = true;
                    renderAdmin();

                    postNui('admin:entregarLicencia', {
                        target: targetId,
                        tipo: selectedLicenseType,
                        nivel: selectedLicenseLevel
                    }).then(res => {
                        licenseSubmitting = false;
                        modalLicenseOpen = false;
                        selectedPlayerForLicense = null;
                        cargarJugadores();
                    }).catch(() => {
                        licenseSubmitting = false;
                        renderAdmin();
                    });
                });
            }
        }
    }

    // =========================================================================
    // RENDERIZADO DEL RECORDING HUD (CONDUCIENDO)
    // =========================================================================

    function mostrarHud(datos) {
        hudVisible = true;
        let hudEl = document.getElementById('ae-hud-grabacion-root');
        if (!hudEl) {
            hudEl = document.createElement('div');
            hudEl.id = 'ae-hud-grabacion-root';
            hudEl.className = 'ae-record-hud';
            rootContainer.appendChild(hudEl);
        }
        actualizarHud(datos || {});
    }

    function ocultarHud() {
        hudVisible = false;
        const hudEl = document.getElementById('ae-hud-grabacion-root');
        if (hudEl) hudEl.remove();
    }

    function actualizarHud(datos) {
        if (!hudVisible) mostrarHud();
        const hudEl = document.getElementById('ae-hud-grabacion-root');
        if (!hudEl) return;

        const act = datos.accionId || 'normal';

        hudEl.innerHTML = `
            <div class="ae-record-header">
                <span class="ae-record-badge">${(datos.carnet || 'COCHE').toUpperCase()}</span>
                <span class="ae-record-title">${escapeHtml(datos.nombre || 'GRABANDO RUTA')}</span>
            </div>

            <div class="ae-actions-container">
                <div class="ae-actions-grid-title">
                    ELIGE ACCIÓN · [1 - 7] O [G]
                    <span>${datos.totalPuntos || 0} PUNTOS</span>
                </div>
                <div class="ae-actions-grid">
                    <div class="ae-action-btn ${act === 'normal' ? 'active act-normal' : ''}" data-accion="normal">
                        <span class="ae-act-num">1</span>
                        <span class="ae-act-name">NORMAL</span>
                    </div>
                    <div class="ae-action-btn ${act === 'stop' ? 'active act-stop' : ''}" data-accion="stop">
                        <span class="ae-act-num">2</span>
                        <span class="ae-act-name">STOP</span>
                    </div>
                    <div class="ae-action-btn ${act === 'giro_izq' ? 'active act-giro' : ''}" data-accion="giro_izq">
                        <span class="ae-act-num">3</span>
                        <span class="ae-act-name">G. IZQ</span>
                    </div>
                    <div class="ae-action-btn ${act === 'giro_der' ? 'active act-giro' : ''}" data-accion="giro_der">
                        <span class="ae-act-num">4</span>
                        <span class="ae-act-name">G. DER</span>
                    </div>
                    <div class="ae-action-btn ${act === 'semaforo' ? 'active act-semaforo' : ''}" data-accion="semaforo">
                        <span class="ae-act-num">5</span>
                        <span class="ae-act-name">SEMÁFORO</span>
                    </div>
                    <div class="ae-action-btn ${act === 'emergencia' ? 'active act-emergencia' : ''}" data-accion="emergencia">
                        <span class="ae-act-num">6</span>
                        <span class="ae-act-name">FRENADA</span>
                    </div>
                    <div class="ae-action-btn ${act === 'aparcar' ? 'active act-aparcar' : ''}" data-accion="aparcar" style="grid-column: span 2;">
                        <span class="ae-act-num">7</span>
                        <span class="ae-act-name">APARCAMIENTO</span>
                    </div>
                </div>

                <div class="ae-action-desc-highlight">
                    <strong>${escapeHtml(datos.accionLabel || 'PASO NORMAL')}:</strong> ${escapeHtml(datos.accionDesc || 'Paso estándar sin parada')}
                </div>
            </div>

            <div class="ae-record-params">
                <div class="ae-param-card">
                    <span class="ae-param-label">VEL. MÁXIMA</span>
                    <span class="ae-param-val">${datos.limite || 50} KM/H</span>
                </div>
                <div class="ae-param-card">
                    <span class="ae-param-label">RADIO PUNTO</span>
                    <span class="ae-param-val">${datos.radio || 12} M</span>
                </div>
            </div>

            <div class="ae-record-params">
                <div class="ae-param-card">
                    <span class="ae-param-label">DISTANCIA TOTAL</span>
                    <span class="ae-param-val">${miles(datos.distancia)} M</span>
                </div>
                <div class="ae-param-card">
                    <span class="ae-param-label">ÚLTIMO PUNTO DE CONTROL</span>
                    <span class="ae-param-val">#${datos.totalPuntos || 0}</span>
                </div>
            </div>

            <div class="ae-keys-guide">
                <div class="ae-key-row">
                    <span class="ae-key-badge">[1 - 7]</span>
                    <span class="ae-key-text">ACCIÓN DIRECTA</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[G]</span>
                    <span class="ae-key-text">MENÚ DE ACCIONES</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[E]</span>
                    <span class="ae-key-text">COLOCAR PUNTO</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[↑ / ↓]</span>
                    <span class="ae-key-text">LÍMITE VELOCIDAD</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[← / →]</span>
                    <span class="ae-key-text">RADIO DEL PUNTO</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[RETROCESO]</span>
                    <span class="ae-key-text">BORRAR ÚLTIMO</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[INTRO]</span>
                    <span class="ae-key-text">GUARDAR Y FINALIZAR</span>
                </div>
                <div class="ae-key-row">
                    <span class="ae-key-badge">[X]</span>
                    <span class="ae-key-text">CANCELAR</span>
                </div>
            </div>
        `;

        hudEl.querySelectorAll('.ae-action-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const accion = btn.dataset.accion;
                postNui('admin:setAccion', { accion: accion });
            });
        });
    }


    // =========================================================================
    // LA PLANTILLA DE ORIGEN (estilo «pegatina»)
    // =========================================================================
    /*  El mismo panel, con el armazon de todos los paneles de administracion
        de Origen: riel a la izquierda, cabecera con chapa + rotulo + brocha,
        zona gris perla con las rutas en tarjetas blancas y pie de cifras.
        Solo cambia el marcado: los ids y los data-* son los de siempre, asi
        que bindAdminEvents() sirve para las dos marcas. Lo pinta
        source-ui/src/assets/styles/pegatina.css (clases aep-*).
        05/10: Origen y Nación usan las dos esta plantilla (la misma interfaz,
        en Nación el repintado pone el naranja). La plantilla vieja de abajo
        queda sin uso. */

    function esOrigen() {
        return true;
    }

    function ico(d, t) {
        return `<svg width="${t || 18}" height="${t || 18}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
    }

    const ICO = {
        coche: '<path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/>',
        moto: '<circle cx="18.5" cy="17.5" r="3.5"/><circle cx="5.5" cy="17.5" r="3.5"/><circle cx="15" cy="5" r="1"/><path d="M12 17.5V14l-3-3 4-3 2 3h2"/>',
        camion: '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>',
        ruta: '<circle cx="6" cy="19" r="3"/><path d="M9 19h8.5a3.5 3.5 0 0 0 0-7h-11a3.5 3.5 0 0 1 0-7H15"/><circle cx="18" cy="5" r="3"/>',
        mas: '<path d="M5 12h14"/><path d="M12 5v14"/>',
        equis: '<path d="M18 6 6 18"/><path d="m6 6 12 12"/>',
        volver: '<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>',
        papelera: '<path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" x2="10" y1="11" y2="17"/><line x1="14" x2="14" y1="11" y2="17"/>',
        parar: '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>',
        encender: '<path d="M20 6 9 17l-5-5"/>',
        carnet: '<rect width="20" height="14" x="2" y="5" rx="2"/><circle cx="8" cy="12" r="2"/><path d="M14 9h4"/><path d="M14 13h4"/>',
        avion: '<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z"/>',
        usuario: '<path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>',
        recargar: '<path d="M21 12a9 9 0 0 0-9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/><path d="M3 12a9 9 0 0 0 9 9 9.75 9.75 0 0 0 6.74-2.74L21 16"/><path d="M16 21h5v-5"/>',
        prohibido: '<circle cx="12" cy="12" r="10"/><path d="m4.9 4.9 14.2 14.2"/>',
        buscar: '<circle cx="11" cy="11" r="8"/><path d="m21 21-4.3-4.3"/>',
        check: '<polyline points="20 6 9 17 4 12"/>',
    };

    const CARNES = { coche: 'Carné de coche', moto: 'Carné de moto', camion: 'Carné de camión' };

    const NIVELES_CONDUCIR = [
        { nivel: 0, nombre: 'Sin carné', desc: 'Revocar y retirar carné de conducir', icon: 'prohibido' },
        { nivel: 1, nombre: 'Coche (Clase B)', desc: 'Carné estándar de turismos y turismos ligeros', icon: 'coche' },
        { nivel: 2, nombre: 'Moto (Clase A)', desc: 'Habilita turismos + motocicletas', icon: 'moto' },
        { nivel: 3, nombre: 'Camión (Clase C)', desc: 'Habilita turismos + motos + camiones y pesados', icon: 'camion' }
    ];

    const NIVELES_VUELO = [
        { nivel: 0, nombre: 'Sin licencia', desc: 'Revocar y retirar licencia de piloto', icon: 'prohibido' },
        { nivel: 1, nombre: 'Básica (Clase C)', desc: 'Avionetas ligeras y avionetas monomotor', icon: 'avion' },
        { nivel: 2, nombre: 'Media (Clase B)', desc: 'Básica + Helicópteros y aviones bimotores', icon: 'avion' },
        { nivel: 3, nombre: 'Alta (Clase A)', desc: 'Todas las aeronaves, jets privados y reactores', icon: 'avion' }
    ];

    function obtenerInfoLicencia(tipo, nivel) {
        const lista = tipo === 'vuelo' ? NIVELES_VUELO : NIVELES_CONDUCIR;
        const num = Number(nivel) || 0;
        return lista.find(n => n.nivel === num) || lista[0];
    }

    function tarjetaOrigen(r) {
        const puntos = Array.isArray(r.puntos) ? r.puntos : [];
        const cuenta = (a) => puntos.filter(p => p.accion === a).length;
        const stops = puntos.filter(p => p.accion === 'stop' || p.stop).length;
        const aparca = puntos.some(p => p.accion === 'aparcar') || !!r.plaza;
        const km = ((Number(r.distancia) || 0) / 1000).toFixed(1).replace('.', ',');
        const activa = r.activo === true || r.activo === 1 || r.activo === '1';
        const maniobras = [
            [stops, 'stop', 'stops'], [cuenta('giro_izq'), 'giro izq.', 'giros izq.'], [cuenta('giro_der'), 'giro der.', 'giros der.'],
            [cuenta('semaforo'), 'semáforo', 'semáforos'], [cuenta('emergencia'), 'frenada', 'frenadas'],
        ].filter(m => m[0] > 0).map(m => `<span class="aep-chip"><b>${m[0]}</b> ${m[0] === 1 ? m[1] : m[2]}</span>`).join('');

        return `
            <article class="aep-ruta ${activa ? '' : 'aep-ruta--off'}" data-id="${r.id}">
                <header class="aep-ruta__cab">
                    <span class="aep-ruta__ico">${ico(ICO[r.carnet] || ICO.coche, 20)}</span>
                    <span class="aep-ruta__txt">
                        <span class="aep-ruta__n">${escapeHtml(r.nombre)}</span>
                        <span class="aep-ruta__m">${CARNES[r.carnet] || escapeHtml(r.carnet)}</span>
                    </span>
                    <span class="aep-chip ${activa ? 'aep-chip--on' : 'aep-chip--off'}">${activa ? 'Activa' : 'Parada'}</span>
                </header>
                <p class="aep-ruta__desc">${r.descripcion ? escapeHtml(r.descripcion) : 'Sin descripción.'}</p>
                <div class="aep-datos">
                    <span class="aep-dato"><i>Puntos</i><b>${puntos.length}</b></span>
                    <span class="aep-dato"><i>Distancia</i><b>${km} km</b></span>
                    <span class="aep-dato"><i>La trazó</i><b class="aep-dato__txt">${escapeHtml(r.creado_por || 'Admin')}</b></span>
                    <span class="aep-dato"><i>Se aparca al final</i><b class="aep-dato__txt">${aparca ? 'Sí' : 'No'}</b></span>
                </div>
                <div class="aep-maniobras">${maniobras || '<span class="aep-chip aep-chip--nada">Sin maniobras marcadas</span>'}</div>
                <footer class="aep-ruta__pie">
                    <button type="button" class="aep-btn aep-btn--chico" data-action="toggle-status" data-id="${r.id}" data-activo="${activa}">
                        ${ico(activa ? ICO.parar : ICO.encender, 15)}<span>${activa ? 'Desactivar' : 'Activar'}</span>
                    </button>
                    <button type="button" class="aep-btn aep-btn--chico aep-btn--rojo" data-action="delete" data-id="${r.id}">
                        ${ico(ICO.papelera, 15)}<span>Borrar</span>
                    </button>
                </footer>
            </article>
        `;
    }

    function tarjetaJugadorOrigen(j) {
        const infoConducir = obtenerInfoLicencia('conducir', j.nivelConducir || 0);
        const infoVuelo = obtenerInfoLicencia('vuelo', j.nivelVuelo || 0);
        const tieneConducir = (j.nivelConducir || 0) > 0;
        const tieneVuelo = (j.nivelVuelo || 0) > 0;

        return `
            <article class="aep-ruta aep-jugador" data-id="${j.id}" data-citizenid="${escapeHtml(j.citizenid)}">
                <header class="aep-ruta__cab">
                    <span class="aep-ruta__ico">${ico(ICO.usuario, 20)}</span>
                    <span class="aep-ruta__txt">
                        <span class="aep-ruta__n">${escapeHtml(j.charname || j.name)}</span>
                        <span class="aep-ruta__m">Steam: ${escapeHtml(j.name)} · CID: ${escapeHtml(j.citizenid || 'N/A')}</span>
                    </span>
                    <span class="aep-jugador__id">ID ${j.id}</span>
                </header>
                <div class="aep-datos aep-datos--jugador">
                    <div class="aep-lic-row">
                        <span class="aep-lic-row__label">${ico(ICO.coche, 15)} <span>Conducir</span></span>
                        <span class="aep-lic-tag ${tieneConducir ? 'aep-lic-tag--active' : 'aep-lic-tag--none'}">
                            ${tieneConducir ? `${infoConducir.nombre}` : 'Sin carné'}
                        </span>
                    </div>
                    <div class="aep-lic-row">
                        <span class="aep-lic-row__label">${ico(ICO.avion, 15)} <span>Vuelo</span></span>
                        <span class="aep-lic-tag ${tieneVuelo ? 'aep-lic-tag--active' : 'aep-lic-tag--none'}">
                            ${tieneVuelo ? `${infoVuelo.nombre}` : 'Sin licencia'}
                        </span>
                    </div>
                </div>
                <footer class="aep-ruta__pie">
                    <button type="button" class="aep-btn aep-btn--chico ae-btn-licencia" data-id="${j.id}" data-charname="${escapeHtml(j.charname || j.name)}" data-tipo="conducir">
                        ${ico(ICO.coche, 15)}<span>Carné Conducir</span>
                    </button>
                    <button type="button" class="aep-btn aep-btn--chico aep-btn--rosa ae-btn-licencia" data-id="${j.id}" data-charname="${escapeHtml(j.charname || j.name)}" data-tipo="vuelo">
                        ${ico(ICO.avion, 15)}<span>Licencia Vuelo</span>
                    </button>
                </footer>
            </article>
        `;
    }

    function dialogoCrearOrigen() {
        return `
            <div class="aep-dialogo" id="ae-modal-overlay">
                <div class="aep-dialogo__tarjeta">
                    <header class="aep-dialogo__cab">
                        <span class="aep-dialogo__t">Una ruta nueva</span>
                        <span class="aep-dialogo__s">Se traza conduciendo, punto a punto</span>
                    </header>
                    <div class="aep-dialogo__cuerpo">
                        <label class="aep-campo">
                            <span class="aep-campo__r">Nombre del circuito</span>
                            <input type="text" class="aep-campo__i ${nombreFalta ? 'aep-campo__i--falta' : ''}" id="ae-input-nombre" placeholder="Circuito centro · Vespucci" maxlength="60" />
                        </label>
                        <div class="aep-campo">
                            <span class="aep-campo__r">Para qué carné</span>
                            <div class="aep-tabs">
                                <button type="button" class="aep-tab ae-radio-pill selected" data-carnet="coche">${ico(ICO.coche, 15)}<span>Coche</span></button>
                                <button type="button" class="aep-tab ae-radio-pill" data-carnet="moto">${ico(ICO.moto, 15)}<span>Moto</span></button>
                                <button type="button" class="aep-tab ae-radio-pill" data-carnet="camion">${ico(ICO.camion, 15)}<span>Camión</span></button>
                            </div>
                        </div>
                        <label class="aep-campo">
                            <span class="aep-campo__r">Descripción (opcional)</span>
                            <textarea class="aep-campo__i aep-campo__i--area" id="ae-input-desc" placeholder="Maniobras, rotondas, dificultad..."></textarea>
                        </label>
                        <div class="aep-nota">
                            <span class="aep-rotulo">Cómo se traza</span>
                            <p class="aep-prosa">Al empezar se cierra el panel y trazas la ruta desde tu vehículo.</p>
                            <ul class="aep-teclas">
                                <li><kbd>E</kbd><span>Colocar un punto donde está el vehículo</span></li>
                                <li><kbd>G</kbd><span>Cambiar la acción (stop, giro, semáforo...)</span></li>
                                <li><kbd>↑ ↓</kbd><span>Límite de velocidad del tramo</span></li>
                                <li><kbd>← →</kbd><span>Radio del punto</span></li>
                                <li><kbd>Intro</kbd><span>Guardar y terminar</span></li>
                            </ul>
                        </div>
                    </div>
                    <footer class="aep-dialogo__pie">
                        <button type="button" class="aep-btn" id="ae-btn-modal-cancel">Cancelar</button>
                        <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-modal-start">Empezar a trazar</button>
                    </footer>
                </div>
            </div>
        `;
    }

    function dialogoBorrarOrigen() {
        const r = routesList.find(x => String(x.id) === String(borrarPendiente));
        return `
            <div class="aep-dialogo">
                <div class="aep-dialogo__tarjeta aep-dialogo__tarjeta--chica">
                    <header class="aep-dialogo__cab">
                        <span class="aep-dialogo__t">Borrar la ruta</span>
                        <span class="aep-dialogo__s">${r ? escapeHtml(r.nombre) : ''}</span>
                    </header>
                    <div class="aep-dialogo__cuerpo">
                        <p class="aep-prosa">Se borra para siempre y deja de salir en los exámenes. No se puede deshacer.</p>
                    </div>
                    <footer class="aep-dialogo__pie">
                        <button type="button" class="aep-btn" id="ae-btn-borrar-no">Cancelar</button>
                        <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-borrar-si">Borrar</button>
                    </footer>
                </div>
            </div>
        `;
    }

    function dialogoEntregarLicenciaOrigen() {
        const p = selectedPlayerForLicense;
        const infoActual = p ? (selectedLicenseType === 'vuelo' ? obtenerInfoLicencia('vuelo', p.nivelVuelo || 0) : obtenerInfoLicencia('conducir', p.nivelConducir || 0)) : null;
        const niveles = selectedLicenseType === 'vuelo' ? NIVELES_VUELO : NIVELES_CONDUCIR;

        return `
            <div class="aep-dialogo" id="ae-modal-overlay">
                <div class="aep-dialogo__tarjeta" style="width: calc(var(--peg-u) * 58);">
                    <header class="aep-dialogo__cab">
                        <span class="aep-dialogo__t">Entrega de Licencia</span>
                        <span class="aep-dialogo__s">
                            ${p ? `Jugador: <b>${escapeHtml(p.charname || p.name)}</b> (ID ${p.id} · CID: ${escapeHtml(p.citizenid || 'N/A')})` : 'Entrega directa de licencia por ID'}
                        </span>
                    </header>
                    <div class="aep-dialogo__cuerpo">
                        ${!p ? `
                            <label class="aep-campo">
                                <span class="aep-campo__r">ID del Jugador en el servidor</span>
                                <input type="number" class="aep-campo__i" id="ae-input-licencia-id" placeholder="Ej: 1" min="1" step="1" autofocus />
                            </label>
                        ` : ''}

                        <div class="aep-campo">
                            <span class="aep-campo__r">Tipo de Licencia</span>
                            <div class="aep-tabs">
                                <button type="button" class="aep-tab ae-tipo-pill ${selectedLicenseType === 'conducir' ? 'selected active' : ''}" data-tipo="conducir">
                                    ${ico(ICO.coche, 15)}<span>Carné de Conducir</span>
                                </button>
                                <button type="button" class="aep-tab ae-tipo-pill ${selectedLicenseType === 'vuelo' ? 'selected active' : ''}" data-tipo="vuelo">
                                    ${ico(ICO.avion, 15)}<span>Licencia de Vuelo</span>
                                </button>
                            </div>
                        </div>

                        ${p && infoActual ? `
                            <div class="aep-nota" style="margin-bottom: calc(var(--peg-u) * 1.5);">
                                <span class="aep-rotulo">Estado actual de ${escapeHtml(p.charname || p.name)}</span>
                                <p class="aep-prosa">
                                    Actualmente posee: <b>${infoActual.nombre}</b> ${infoActual.nivel > 0 ? `(Nivel ${infoActual.nivel})` : '(Sin licencia)'}
                                </p>
                            </div>
                        ` : ''}

                        <div class="aep-campo">
                            <span class="aep-campo__r">Nivel de Licencia a Establecer</span>
                            <div class="aep-niveles-lista">
                                ${niveles.map(n => `
                                    <div class="aep-nivel-opcion ${selectedLicenseLevel === n.nivel ? 'selected' : ''} ${n.nivel === 0 ? 'aep-nivel-opcion--quitar' : ''}" data-nivel="${n.nivel}">
                                        <span class="aep-nivel-opcion__ico">${ico(ICO[n.icon] || ICO.carnet, 18)}</span>
                                        <div class="aep-nivel-opcion__info">
                                            <span class="aep-nivel-opcion__t">${n.nombre}</span>
                                            <span class="aep-nivel-opcion__d">${n.desc}</span>
                                        </div>
                                        <span class="aep-nivel-opcion__check">
                                            ${selectedLicenseLevel === n.nivel ? ico(ICO.check, 18) : ''}
                                        </span>
                                    </div>
                                `).join('')}
                            </div>
                        </div>
                    </div>
                    <footer class="aep-dialogo__pie">
                        <button type="button" class="aep-btn" id="ae-btn-licencia-cancel" ${licenseSubmitting ? 'disabled' : ''}>Cancelar</button>
                        <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-licencia-confirm" ${licenseSubmitting ? 'disabled' : ''}>
                            ${licenseSubmitting ? 'Procesando...' : (selectedLicenseLevel === 0 ? 'Revocar Licencia' : 'Confirmar y Entregar')}
                        </button>
                    </footer>
                </div>
            </div>
        `;
    }

    function plantillaOrigen(rutas, n) {
        const activas = routesList.filter(r => r.activo === true || r.activo === 1 || r.activo === '1').length;

        // Búsqueda y filtrado de jugadores
        const query = (playerSearchQuery || '').trim().toLowerCase();
        const filteredPlayers = playersList.filter(p => {
            if (query) {
                const idStr = String(p.id);
                const nameStr = (p.name || '').toLowerCase();
                const charStr = (p.charname || '').toLowerCase();
                const cidStr = (p.citizenid || '').toLowerCase();
                if (!idStr.includes(query) && !nameStr.includes(query) && !charStr.includes(query) && !cidStr.includes(query)) {
                    return false;
                }
            }
            if (playerFilter === 'con_conducir') return (p.nivelConducir || 0) > 0;
            if (playerFilter === 'sin_conducir') return (p.nivelConducir || 0) === 0;
            if (playerFilter === 'con_vuelo') return (p.nivelVuelo || 0) > 0;
            if (playerFilter === 'sin_vuelo') return (p.nivelVuelo || 0) === 0;
            return true;
        });

        const countP = {
            todos: playersList.length,
            conConducir: playersList.filter(p => (p.nivelConducir || 0) > 0).length,
            sinConducir: playersList.filter(p => (p.nivelConducir || 0) === 0).length,
            conVuelo: playersList.filter(p => (p.nivelVuelo || 0) > 0).length,
            sinVuelo: playersList.filter(p => (p.nivelVuelo || 0) === 0).length,
        };

        const pestañaRuta = (id, texto, cuenta) =>
            `<button type="button" class="aep-tab ae-tab ${currentTab === id ? 'active' : ''}" data-tab="${id}"><span>${texto}</span><b>${cuenta}</b></button>`;
        const pestañaJugador = (filtro, texto, cuenta) =>
            `<button type="button" class="aep-tab ae-player-filter ${playerFilter === filtro ? 'active' : ''}" data-player-filter="${filtro}"><span>${texto}</span><b>${cuenta}</b></button>`;
        const celda = (rotulo, cifra) =>
            `<div class="aep-barra__celda"><span class="aep-barra__r">${rotulo}</span><span class="aep-barra__c">${cifra}</span></div>`;

        return `
            <div class="aep">
                <div class="aep-velo"></div>

                <nav class="aep-riel">
                    <span class="aep-riel__placa">${ico(currentView === 'rutas' ? ICO.ruta : ICO.carnet, 22)}</span>
                    <span class="aep-riel__medio"><span class="aep-riel__palabra">${nombreMarca()} Autoescuela</span></span>
                    <span class="aep-riel__pie ${currentView === 'rutas' ? (activas ? 'is-on' : '') : (playersList.length ? 'is-on' : '')}">
                        <i class="aep-riel__punto"></i>
                        <span class="aep-riel__estado">
                            ${currentView === 'rutas' ? `${activas} ${activas === 1 ? 'activa' : 'activas'}` : `${playersList.length} ${playersList.length === 1 ? 'jugador' : 'jugadores'}`}
                        </span>
                    </span>
                </nav>

                <div class="aep-marco">
                    <header class="aep-cab">
                        <div class="aep-cab__titulo">
                            <span class="aep-chapa">${currentView === 'rutas' ? 'Gestión de rutas' : 'Administración'}</span>
                            <h2 class="aep-h2" data-brocha="${currentView === 'rutas' ? 'Circuitos de examen' : 'Entrega de carnets'}">Autoescuela</h2>
                        </div>
                        <div class="aep-cab__der">
                            <div class="aep-tabs" style="margin-right: calc(var(--peg-u) * 1.5);">
                                <button type="button" class="aep-tab ae-view-tab ${currentView === 'rutas' ? 'active' : ''}" data-view="rutas">
                                    ${ico(ICO.ruta, 15)}<span>Circuitos</span>
                                </button>
                                <button type="button" class="aep-tab ae-view-tab ${currentView === 'carnets' ? 'active' : ''}" data-view="carnets">
                                    ${ico(ICO.carnet, 15)}<span>Carnets y Vuelo</span>
                                </button>
                            </div>
                            ${currentView === 'rutas' ? `
                                <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-nueva-ruta">${ico(ICO.mas, 17)}<span>Ruta nueva</span></button>
                            ` : `
                                <button type="button" class="aep-btn" id="ae-btn-refrescar" title="Actualizar lista de jugadores">${ico(ICO.recargar, 16)}<span>Actualizar</span></button>
                                <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-entrega-rapida">${ico(ICO.mas, 17)}<span>Entrega por ID</span></button>
                            `}
                            <button type="button" class="aep-btn aep-btn--chico" id="ae-btn-cerrar" title="Cerrar panel" style="margin-left: calc(var(--peg-u) * 0.8);">${ico(ICO.equis, 15)}</button>
                        </div>
                    </header>

                    ${currentView === 'rutas' ? `
                        <section class="aep-zona">
                            <div class="aep-zona__cab">
                                <div class="aep-tabs">
                                    ${pestañaRuta('todas', 'Todas', n.todas)}
                                    ${pestañaRuta('coche', 'Coche', n.coche)}
                                    ${pestañaRuta('moto', 'Moto', n.moto)}
                                    ${pestañaRuta('camion', 'Camión', n.camion)}
                                </div>
                            </div>
                            <div class="aep-zona__cuerpo">
                                ${rutas.length === 0 ? `
                                    <div class="aep-vacio">
                                        ${ico(ICO.ruta, 34)}
                                        <span class="aep-vacio__t">${routesList.length ? 'No hay rutas de este carné' : 'Todavía no hay ninguna ruta'}</span>
                                        <span class="aep-vacio__p">Se crean conduciendo por la ciudad: cada punto que colocas es una etapa del examen.</span>
                                        <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-empty-crear">${ico(ICO.mas, 17)}<span>Crear una ruta</span></button>
                                    </div>
                                ` : `<div class="aep-rejilla">${rutas.map(tarjetaOrigen).join('')}</div>`}
                            </div>
                        </section>

                        <div class="aep-barra">
                            ${celda('Rutas', n.todas)}
                            ${celda('Activas', activas)}
                            ${celda('De coche', n.coche)}
                            ${celda('De moto', n.moto)}
                            ${celda('De camión', n.camion)}
                        </div>
                    ` : `
                        <section class="aep-zona">
                            <div class="aep-zona__cab" style="justify-content: space-between; gap: calc(var(--peg-u) * 1.5);">
                                <div class="aep-tabs">
                                    ${pestañaJugador('todos', 'Todos', countP.todos)}
                                    ${pestañaJugador('con_conducir', 'Con Conducir', countP.conConducir)}
                                    ${pestañaJugador('sin_conducir', 'Sin Conducir', countP.sinConducir)}
                                    ${pestañaJugador('con_vuelo', 'Con Vuelo', countP.conVuelo)}
                                    ${pestañaJugador('sin_vuelo', 'Sin Vuelo', countP.sinVuelo)}
                                </div>
                                <div class="aep-buscador-wrap">
                                    ${ico(ICO.buscar, 15)}
                                    <input type="text" id="ae-input-buscar-jugador" placeholder="Buscar por ID, nombre o CID..." value="${escapeHtml(playerSearchQuery)}" />
                                    ${playerSearchQuery ? `<button type="button" class="aep-btn-limpiar" id="ae-btn-limpiar-busqueda">✕</button>` : ''}
                                </div>
                            </div>
                            <div class="aep-zona__cuerpo">
                                ${filteredPlayers.length === 0 ? `
                                    <div class="aep-vacio">
                                        ${ico(ICO.usuario, 34)}
                                        <span class="aep-vacio__t">${playersList.length ? 'No hay jugadores que coincidan con la búsqueda' : 'No hay jugadores conectados'}</span>
                                        <span class="aep-vacio__p">${playersList.length ? 'Prueba con otro término de búsqueda o cambia el filtro de licencias.' : 'Puedes entregar una licencia directamente escribiendo el ID del jugador.'}</span>
                                        <button type="button" class="aep-btn aep-btn--rosa" id="ae-btn-empty-entrega">${ico(ICO.mas, 17)}<span>Entrega directa por ID</span></button>
                                    </div>
                                ` : `<div class="aep-rejilla aep-rejilla--jugadores">${filteredPlayers.map(tarjetaJugadorOrigen).join('')}</div>`}
                            </div>
                        </section>

                        <div class="aep-barra">
                            ${celda('Conectados', countP.todos)}
                            ${celda('Con carné coche', countP.conConducir)}
                            ${celda('Sin carné coche', countP.sinConducir)}
                            ${celda('Con licencia vuelo', countP.conVuelo)}
                            ${celda('Sin licencia vuelo', countP.sinVuelo)}
                        </div>
                    `}
                </div>

                ${modalCreateOpen ? dialogoCrearOrigen() : ''}
                ${modalLicenseOpen ? dialogoEntregarLicenciaOrigen() : ''}
                ${borrarPendiente !== null ? dialogoBorrarOrigen() : ''}
            </div>
        `;
    }

    /*  Cifras con punto de miles (1.840 m). */
    function miles(n) {
        return String(Math.floor(Number(n) || 0)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
    }

    /*  «Origen Autoescuela» / «Nación Autoescuela»: la marca la pone el kit en
        <html data-marca> y vuelve a llegar con origen:marca:puesta. */
    function nombreMarca() {
        return document.documentElement.dataset.marca === 'nacion' ? 'Nación' : 'Origen';
    }
    window.addEventListener('message', (e) => {
        const d = e.data || {};
        if (d.accion === 'origen:marca:puesta' && adminVisible) renderAdmin();
    });

    function escapeHtml(str) {
        if (!str) return '';
        return String(str)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }

    // Arranque
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
