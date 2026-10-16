// origen_vehicleseats | ui/script.js

let currentModel = "";
let seatsList = [];
let activeSeatId = null; // null if creating a new one

// Current offset & rotation state in memory
let currentOffset = { x: 0.0, y: -1.5, z: 0.5 };
let currentRotation = { x: 0.0, y: 0.0, z: 0.0 };

// Animation dictionary mapping presets to FiveM anims
const animPresets = {
    sit_normal: { dict: 'amb@world_human_picnic@female@base', anim: 'base' },
    trunk_sit: { dict: 'amb@world_human_picnic@male@base', anim: 'base' },
    sunbathe_back: { dict: 'amb@world_human_sunbathe@male@back@idle_a', anim: 'idle_a' },
    sunbathe_front: { dict: 'amb@world_human_sunbathe@male@front@idle_a', anim: 'idle_a' },
    kneeling: { dict: 'amb@world_human_bum_wash@male@low@idle_a', anim: 'idle_a' }
};

// ── Particle Generator for premium theme background ──
function initBackgroundParticles() {
    // El creador va ahora en riel, sin fondo: no hay particulas que pintar.
    const container = document.getElementById("particles-container");
    if (!container) return;
    container.innerHTML = "";
    const particleCount = 20;

    for (let i = 0; i < particleCount; i++) {
        const particle = document.createElement("div");
        particle.className = "particle";

        // Random sizes and positions
        const size = Math.random() * 8 + 3; // calc(3vh / var(--ogn-escala, 1)) to calc(11vh / var(--ogn-escala, 1))
        particle.style.width = "calc(" + size + "vh / var(--ogn-escala, 1))";
        particle.style.height = "calc(" + size + "vh / var(--ogn-escala, 1))";
        particle.style.left = Math.random() * 100 + "%";
        particle.style.top = Math.random() * 100 + "%";

        // Staggered float animations
        particle.style.animationDelay = Math.random() * -20 + "s";
        particle.style.animationDuration = (Math.random() * 15 + 15) + "s";

        container.appendChild(particle);
    }
}

// Helper to make API post requests
function post(url, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${url}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify(data)
    }).then(resp => resp.json()).catch(err => console.error("NUI Fetch error:", err));
}

// ── Riel: entrar, la edicion abierta y el texto de las filas ──
const app = () => document.getElementById("creator-app");

// La edicion va en la misma columna, bajo la lista; con ella abierta el pie
// cambia a «Guardar» / «Cancelar».
function mostrarEditor(si) {
    const ed = document.getElementById("editor-column");
    ed.hidden = !si;
    app().classList.toggle("editando", !!si);
    if (si) requestAnimationFrame(() => ed.scrollIntoView({ block: "nearest", behavior: "smooth" }));
}

function escapar(t) {
    return String(t == null ? "" : t).replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

const nombresPostura = {
    sit_normal: "Sentado normal",
    trunk_sit: "Sentado en el maletero",
    sunbathe_back: "Tumbado boca arriba",
    sunbathe_front: "Tumbado boca abajo",
    kneeling: "De rodillas",
    custom: "Animación personalizada"
};

function pintarCuenta() {
    const n = seatsList.length;
    document.getElementById("seats-count").innerHTML = `<b>${n}</b> ${n === 1 ? "asiento" : "asientos"}`;
}

// Close NUI
function closeCreator() {
    app().classList.remove("esta-dentro", "colocando");
    app().style.display = "none";
    post("closeCreator");
}

// ── El panel de gestion (iframe) ──
// Todo lo que manda el Lua se le reenvia (asi le llega tambien la marca); se
// muestra mientras esta abierto.
const gestion = document.getElementById("gestion");
window.addEventListener("message", function(event) {
    const data = event.data || {};
    if (event.source === gestion.contentWindow) return;
    // El vigilante del raton lo contesta esta pagina (el iframe cuenta como
    // visible): si contestara tambien el iframe oculto, soltaria el raton.
    if (data.accion === "origen:foco:mira") return;
    if (data.a === "gestion") gestion.style.display = "block";
    else if (data.a === "cerrar") gestion.style.display = "none";
    try { gestion.contentWindow.postMessage(data, "*"); } catch (e) {}
});

// ── Message Listeners ──
window.addEventListener("message", function(event) {
    const data = event.data;

    if (data.action === "openCreator") {
        currentModel = data.modelName;
        seatsList = data.seats || [];
        activeSeatId = null;

        // Populate titles
        document.getElementById("vehicle-title").innerText = currentModel;
        // Abierto desde el panel de gestion: «Volver» en vez de «Cerrar».
        app().classList.toggle("desde-gestion", !!data.desdeGestion);
        
        // Render seat config list
        renderSeatsList();
        
        // Hide editor on start
        mostrarEditor(false);
        document.getElementById("confirm-modal").style.display = "none";

        // Entra deslizandose desde la derecha
        const el = app();
        el.classList.remove("esta-dentro", "colocando");
        el.style.display = "flex";
        void el.offsetWidth;
        requestAnimationFrame(() => el.classList.add("esta-dentro"));
    }
    
    else if (data.action === "setUIVisibility") {
        // Con el gizmo moviendo el asiento: la columna se aparta y las
        // teclas salen en la barra de abajo. Al acabar, vuelve.
        app().classList.toggle("colocando", !data.visible);
    }

    else if (data.action === "updateGizmoCoords") {
        if (data.offset && data.rotation) {
            updateCoordsDisplay(data.offset, data.rotation);
        }
    }
});

// Render the left-hand seat configuration items
function renderSeatsList() {
    const container = document.getElementById("seats-list-container");
    container.innerHTML = "";
    pintarCuenta();

    if (seatsList.length === 0) {
        container.innerHTML = `
            <div class="empty-inline">
                <b>Sin asientos</b>
                Este coche no tiene asientos propios. Añade el primero abajo.
            </div>
        `;
        return;
    }

    seatsList.forEach((seat, i) => {
        const item = document.createElement("div");
        item.className = "list-item";
        item.id = `seat-item-${seat.id}`;
        item.onclick = () => selectSeat(seat.id);

        const sub = [nombresPostura[seat.preset] || "Animación", seat.allowMoving ? "En marcha" : null, seat.openTrunk ? "Abre el maletero" : null]
            .filter(Boolean).join(" · ");
        item.innerHTML = `
            <span class="item-num">${i + 1}</span>
            <div class="item-left">
                <span class="item-title">${escapar(seat.name)}</span>
                <span class="item-sub">${escapar(sub)}</span>
            </div>
            <div class="item-actions">
                <div class="action-icon action-delete" title="Quitar" onclick="deleteSeat(event, ${seat.id})">
                    <span class="iconify" data-icon="lucide:trash-2"></span>
                </div>
            </div>
        `;
        if (seat.id === activeSeatId) item.classList.add("active");

        container.appendChild(item);
    });
}

// ── Selection and Form Handling ──

function selectSeat(seatId) {
    activeSeatId = seatId;
    
    // Highlight list item
    const items = document.querySelectorAll(".list-item");
    items.forEach(i => i.classList.remove("active"));
    const selectedItem = document.getElementById(`seat-item-${seatId}`);
    if (selectedItem) selectedItem.classList.add("active");

    const seat = seatsList.find(s => s.id === seatId);
    if (!seat) return;

    // Load form details
    document.getElementById("editor-title").innerText = "Editando: " + seat.name;
    document.getElementById("seat-name-input").value = seat.name;
    document.getElementById("anim-preset-select").value = seat.preset;
    
    if (seat.preset === "custom") {
        document.getElementById("custom-anim-row").style.display = "grid";
        document.getElementById("custom-dict-input").value = seat.animDict;
        document.getElementById("custom-name-input").value = seat.animName;
    } else {
        document.getElementById("custom-anim-row").style.display = "none";
    }

    document.getElementById("toggle-motion").checked = seat.allowMoving;
    document.getElementById("toggle-trunk").checked = seat.openTrunk;

    // Update internal and HTML offset variables
    updateCoordsDisplay(seat.offset, seat.rotation);

    // Make editor column visible
    mostrarEditor(true);

    // Play Live Preview
    triggerLivePreview();
}

function openNewSeatForm() {
    activeSeatId = null;

    // Reset list highlighting
    const items = document.querySelectorAll(".list-item");
    items.forEach(i => i.classList.remove("active"));

    // Default form details
    document.getElementById("editor-title").innerText = "Nuevo asiento";
    document.getElementById("seat-name-input").value = "";
    document.getElementById("anim-preset-select").value = "sit_normal";
    document.getElementById("custom-anim-row").style.display = "none";
    document.getElementById("custom-dict-input").value = "";
    document.getElementById("custom-name-input").value = "";
    document.getElementById("toggle-motion").checked = false;
    document.getElementById("toggle-trunk").checked = false;

    // Default starting coords (behind vehicle, slightly floating)
    updateCoordsDisplay({ x: 0.0, y: -1.5, z: 0.5 }, { x: 0.0, y: 0.0, z: 0.0 });

    mostrarEditor(true);

    // Play Live Preview
    triggerLivePreview();
}

function cancelEditor() {
    activeSeatId = null;
    mostrarEditor(false);
    const items = document.querySelectorAll(".list-item");
    items.forEach(i => i.classList.remove("active"));
    post("stopPreview");
}

// ── Preset change events ──
function onPresetChange() {
    const val = document.getElementById("anim-preset-select").value;
    if (val === "custom") {
        document.getElementById("custom-anim-row").style.display = "grid";
    } else {
        document.getElementById("custom-anim-row").style.display = "none";
    }
    triggerLivePreview();
}

// Update UI text display of current coordinate offsets
function updateCoordsDisplay(offset, rotation) {
    currentOffset = offset;
    currentRotation = rotation;

    document.getElementById("coord-x").innerText = offset.x.toFixed(2);
    document.getElementById("coord-y").innerText = offset.y.toFixed(2);
    document.getElementById("coord-z").innerText = offset.z.toFixed(2);
    document.getElementById("coord-rx").innerText = rotation.x.toFixed(0);
    document.getElementById("coord-ry").innerText = rotation.y.toFixed(0);
    document.getElementById("coord-rz").innerText = rotation.z.toFixed(0);
}

// Build active animation package data from inputs
function getAnimationData() {
    const preset = document.getElementById("anim-preset-select").value;
    let animDict = "";
    let animName = "";

    if (preset === "custom") {
        animDict = document.getElementById("custom-dict-input").value.trim();
        animName = document.getElementById("custom-name-input").value.trim();
    } else {
        animDict = animPresets[preset].dict;
        animName = animPresets[preset].anim;
    }

    return { preset, animDict, animName };
}

// Send live preview refresh request to client
function triggerLivePreview() {
    const animData = getAnimationData();
    if (!animData.animDict || !animData.animName) return;

    post("previewSeat", {
        offset: currentOffset,
        rotation: currentRotation,
        animDict: animData.animDict,
        animName: animData.animName,
        openTrunk: document.getElementById("toggle-trunk").checked
    });
}

// Trigger interactive Gizmo placing mode
function triggerGizmoAdjustment() {
    const animData = getAnimationData();
    if (!animData.animDict || !animData.animName) return;

    const nombre = document.getElementById("seat-name-input").value.trim();
    document.getElementById("barra-titulo").innerText = nombre ? "Colocar · " + nombre : "Colocar asiento";

    post("startGizmo", {
        offset: currentOffset,
        rotation: currentRotation,
        animDict: animData.animDict,
        animName: animData.animName
    }).then(result => {
        if (result && result.success) {
            updateCoordsDisplay(result.offset, result.rotation);
        }
    });
}

// ── CRUD Actions ──

// Premium Integrated Modal Controller
let confirmCallback = null;

function showCustomConfirm(title, message, isConfirm, callback) {
    document.getElementById("confirm-modal-title").innerText = title;
    document.getElementById("confirm-modal-message").innerText = message;

    const cancelBtn = document.getElementById("confirm-modal-cancel-btn");
    const confirmBtn = document.getElementById("confirm-modal-confirm-btn");

    if (isConfirm) {
        cancelBtn.style.display = "block";
        confirmBtn.innerText = "Eliminar";
        confirmBtn.classList.add("peligro");
    } else {
        cancelBtn.style.display = "none";
        confirmBtn.innerText = "Entendido";
        confirmBtn.classList.remove("peligro");
    }

    confirmCallback = callback;
    document.getElementById("confirm-modal").style.display = "flex";
}

function closeConfirmModal(accepted) {
    document.getElementById("confirm-modal").style.display = "none";
    if (confirmCallback) {
        confirmCallback(accepted);
        confirmCallback = null;
    }
}

function saveSeat() {
    const name = document.getElementById("seat-name-input").value.trim();
    if (!name) {
        return showCustomConfirm("Falta un dato", "Ponle un nombre al asiento.", false);
    }

    const animData = getAnimationData();
    if (!animData.animDict || !animData.animName) {
        return showCustomConfirm("Falta un dato", "Falta la animación: elige una o rellena sus datos.", false);
    }

    const payload = {
        id: activeSeatId, // null if new
        name: name,
        preset: animData.preset,
        animDict: animData.animDict,
        animName: animData.animName,
        offset: currentOffset,
        rotation: currentRotation,
        allowMoving: document.getElementById("toggle-motion").checked,
        openTrunk: document.getElementById("toggle-trunk").checked
    };

    post("saveSeat", payload).then(res => {
        if (res && res.success) {
            seatsList = res.seats || [];
            renderSeatsList();
            activeSeatId = null;
            mostrarEditor(false);
        }
    });
}

function deleteSeat(event, seatId) {
    // Prevent selection callback triggering on click
    event.stopPropagation();

    showCustomConfirm("Eliminar asiento", "¿Seguro que quieres eliminar este asiento? No se puede deshacer.", true, function(confirmed) {
        if (!confirmed) return;

        post("deleteSeat", { seatId: seatId }).then(res => {
            if (res && res.success) {
                seatsList = res.seats || [];
                renderSeatsList();
                activeSeatId = null;
            mostrarEditor(false);
            }
        });
    });
}

// Handle ESC or Backspace closing
window.addEventListener("keydown", function(event) {
    if (event.key === "Escape") {
        closeCreator();
    }
});
