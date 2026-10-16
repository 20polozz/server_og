/*
    ORIGEN SOUNDS

    Elegir el motor que suena en el coche en el que estás. Dos secciones: el
    catálogo y, para lo que no está en él, escribir el nombre de audio a mano.

    La pantalla la pinta el juego de piezas de la tablet (ogn.css). Ver la
    skill origen-tablet.
*/

let currentSound = '';
let previewedSound = null;
let selectedSound = '';

let soundsList = [];
let categoriesList = [];
let activeCategory = 'all';
let activeScreen = 'catalogo';
let sinCoche = false;

const SECCIONES = [
    { id: 'catalogo', icon: 'lucide:grid-3x3', label: 'El catálogo de motores' },
    { id: 'mano', icon: 'lucide:keyboard', label: 'Escribirlo a mano' },
];

const $ = (id) => document.getElementById(id);

// Escape cierra, y no hay botón de cerrar: es la única puerta y ya se sabe.
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeMenu();
});

window.addEventListener('message', (event) => {
    if (event.data.action === 'openMenu') openMenu(event.data.data);
    if (event.data.action === 'updateCurrentSound') updateActiveLabel(event.data.data.currentSound);
});

function nuiFetch(endpoint, body) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(body),
    });
}

function closeMenu() {
    nuiFetch('closeMenu', {});
    $('app').style.display = 'none';
    previewedSound = null;
}

function openMenu(data) {
    soundsList = data.sounds || [];
    categoriesList = data.categories || [];
    activeCategory = 'all';
    activeScreen = 'catalogo';

    sinCoche = !!data.sinCoche;
    currentSound = data.currentSound || '';
    selectedSound = currentSound;

    $('veh-name').innerText = data.vehicleName || '';
    $('bar-coche').innerText = data.vehicleName || '—';
    $('btn-save-all').disabled = sinCoche;
    document.querySelector('.ogn-rail__state').innerText = sinCoche ? 'A pie' : 'En el coche';
    document.querySelector('.ogn-rail__foot').classList.toggle('is-on', !sinCoche);

    renderRail();
    updateActiveLabel(currentSound);
    renderFilters();
    renderCatalog();

    $('app').style.display = 'flex';
}

/* ── El raíl ──────────────────────────────────────────────────────────────
   El nombre de la sección sale FUERA, con el `top` calculado del botón:
   dentro del raíl lo recortaría todo lo que hay por encima. */
function renderRail() {
    const nav = $('rail-nav');
    nav.innerHTML = '';

    SECCIONES.forEach((s) => {
        const b = document.createElement('button');
        b.type = 'button';
        b.className = `ogn-rail__it${activeScreen === s.id ? ' is-on' : ''}`;
        b.innerHTML = `${activeScreen === s.id ? '<span class="ogn-rail__bar"></span>' : ''}<iconify-icon icon="${s.icon}" style="font-size:calc(1.7vh / var(--ogn-escala, 1))"></iconify-icon>`;

        b.addEventListener('click', () => {
            activeScreen = s.id;
            renderRail();
            renderScreen();
        });
        b.addEventListener('mouseenter', () => {
            const r = b.getBoundingClientRect();
            const tip = $('rail-tip');
            tip.innerText = s.label;
            tip.style.top = `${r.top + r.height / 2}px`;
            tip.hidden = false;
        });
        b.addEventListener('mouseleave', () => { $('rail-tip').hidden = true; });

        nav.appendChild(b);
    });
}

function renderScreen() {
    const enCatalogo = activeScreen === 'catalogo';
    $('pantalla-catalogo').hidden = !enCatalogo;
    $('pantalla-mano').hidden = enCatalogo;
    $('titulo-seccion').innerText = SECCIONES.find((s) => s.id === activeScreen).label;
    // El rótulo a brocha de debajo del título: solo lo pinta la pegatina (Origen).
    $('titulo-seccion').dataset.brocha = activeScreen === 'catalogo' ? 'A cada coche, su rugido' : 'El nombre, tal cual';
}

/* Cómo se llama lo que está puesto. Si el nombre de audio no está en el
   catálogo es que se escribió a mano, y entonces se enseña tal cual. */
function updateActiveLabel(sound) {
    currentSound = sound || '';
    const el = $('active-sound-label');

    if (!currentSound) {
        el.innerText = 'De fábrica';
    } else {
        const hallado = soundsList.find((s) => s.audio.toLowerCase() === currentSound.toLowerCase());
        el.innerText = hallado ? hallado.label : currentSound;
    }

    refrescarBarra();
}

function refrescarBarra() {
    const hallado = soundsList.find((s) => s.audio.toLowerCase() === (selectedSound || '').toLowerCase());
    $('bar-elegido').innerText = selectedSound ? (hallado ? hallado.label : selectedSound) : 'De fábrica';

    const probando = soundsList.find((s) => s.audio.toLowerCase() === (previewedSound || '').toLowerCase());
    $('bar-probando').innerText = previewedSound ? (probando ? probando.label : previewedSound) : 'Nada';
}

function renderFilters() {
    const container = $('category-filters');
    container.innerHTML = '';

    categoriesList.forEach((cat) => {
        const btn = document.createElement('button');
        btn.type = 'button';
        btn.className = `ogn-tabs__tab${activeCategory === cat.id ? ' ogn-tabs__tab--on' : ''}`;
        btn.innerText = cat.label;
        btn.addEventListener('click', () => {
            activeCategory = cat.id;
            renderFilters();
            renderCatalog();
        });
        container.appendChild(btn);
    });
}

function renderCatalog() {
    const container = $('sounds-list');
    container.innerHTML = '';

    // A pie no hay coche al que cambiarle el motor: se dice aqui mismo.
    if (sinCoche) {
        $('cuenta-motores').innerText = '';
        container.innerHTML = `
            <div class="ogn-empty">
                <iconify-icon class="ogn-empty__icon" icon="lucide:car-front" style="font-size:calc(3.4vh / var(--ogn-escala, 1))"></iconify-icon>
                <p class="ogn-empty__text">Súbete al volante de un coche</p>
                <p class="ogn-empty__sub">El sonido se cambia al modelo del coche que conduces. Cierra, sube a uno y vuelve a abrir.</p>
            </div>`;
        return;
    }

    const list = activeCategory === 'all'
        ? soundsList
        : soundsList.filter((s) => s.category === activeCategory);

    $('cuenta-motores').innerText = `${list.length} motores`;

    if (!list.length) {
        container.innerHTML = `
            <div class="ogn-empty">
                <iconify-icon class="ogn-empty__icon" icon="lucide:volume-x" style="font-size:calc(3.4vh / var(--ogn-escala, 1))"></iconify-icon>
                <p class="ogn-empty__text">No hay motores de este tipo</p>
            </div>`;
        return;
    }

    list.forEach((sound) => {
        const elegido = selectedSound.toLowerCase() === sound.audio.toLowerCase();
        const sonando = previewedSound === sound.audio;

        const card = document.createElement('div');
        card.className = `vs-motor${elegido ? ' vs-motor--on' : ''}`;
        card.innerHTML = `
            <span class="vs-motor__cab">
                <span class="vs-motor__ico"><iconify-icon icon="lucide:zap"></iconify-icon></span>
                <span class="vs-motor__n">${sound.label}</span>
            </span>
            <span class="vs-motor__d">${sound.description || ''}</span>
            <span class="vs-motor__a">${sound.audio}</span>
            <span class="vs-motor__pie">
                <button class="ogn-btn ogn-btn--quiet" data-oir>
                    <iconify-icon icon="${sonando ? 'lucide:square' : 'lucide:play'}"></iconify-icon>
                    <span>${sonando ? 'Parar' : 'Oírlo'}</span>
                </button>
                <button class="ogn-btn ogn-btn--quiet" data-elegir ${elegido ? 'disabled' : ''}>
                    <span>${elegido ? 'Elegido' : 'Elegirlo'}</span>
                </button>
            </span>`;

        card.querySelector('[data-oir]').addEventListener('click', (e) => {
            e.stopPropagation();
            togglePreview(sound.audio);
        });

        if (!elegido) {
            card.querySelector('[data-elegir]').addEventListener('click', (e) => {
                e.stopPropagation();
                selectedSound = sound.audio;
                renderCatalog();
                refrescarBarra();
            });
        }

        container.appendChild(card);
    });
}

function togglePreview(audioName) {
    if (previewedSound === audioName) {
        previewedSound = null;
        nuiFetch('resetPreview', {});
    } else {
        previewedSound = audioName;
        nuiFetch('previewSound', { audioName });
    }
    renderCatalog();
    refrescarBarra();
}

$('btn-apply-custom').addEventListener('click', () => {
    const val = $('custom-sound-name').value.trim();
    if (!val) return;
    selectedSound = val;
    togglePreview(val);
});

$('btn-restore-original').addEventListener('click', () => {
    nuiFetch('restoreOriginalSound', {}).then((r) => r.json()).then((ok) => {
        if (!ok) return;
        currentSound = '';
        selectedSound = '';
        previewedSound = null;
        updateActiveLabel('');
        renderCatalog();
    });
});

$('btn-save-all').addEventListener('click', () => {
    nuiFetch('saveVehicleSoundChanges', { audioName: selectedSound }).then((r) => r.json()).then((ok) => {
        if (!ok) return;
        currentSound = selectedSound;
        previewedSound = null;
        updateActiveLabel(currentSound);
        renderCatalog();
    });
});
