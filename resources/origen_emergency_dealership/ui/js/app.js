const ICONS = {
  enter: `
    <svg viewBox="0 0 24 24" width="24" height="24">
      <path d="M12 2L3 7v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-9-5zm0 3.3l6 3.33v4.67c0 4.12-2.73 7.94-6 9.17-3.27-1.23-6-5.05-6-9.17V8.63l6-3.33z"/>
      <path d="M12 7.5L9.5 9h5L12 7.5zm-3 3h6v4.5H9V10.5zm1.5 1.5v1.5h3V12h-3z"/>
    </svg>
  `,
  exit: `
    <svg viewBox="0 0 24 24" width="24" height="24">
      <path d="M10.09 15.59L11.5 17l5-5-5-5-1.41 1.41L12.67 11H3v2h9.67l-2.58 2.59zM19 3H5c-1.11 0-2 .9-2 2v4h2V5h14v14H5v-4H3v4c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2z"/>
    </svg>
  `,
  buy: `
    <svg viewBox="0 0 24 24" width="24" height="24">
      <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.85 7h10.29l1.04 3H5.81l1.04-3zM19 17H5v-4.66l.12-.34h13.77l.11.34V17z"/>
      <circle cx="7.5" cy="14.5" r="1.5"/>
      <circle cx="16.5" cy="14.5" r="1.5"/>
    </svg>
  `
};

const DEFAULT_CONFIGS = {
  enter: {
    tag: 'SISTEMA DE GESTIÓN DE FLOTA',
    title: 'GARAJE DEPARTAMENTAL',
    subtitle: 'ACCEDIENDO A LA FLOTA POLICIAL',
    message: 'Sincronizando vehículos de dotación, equipamiento reglamentario y plazas de exposición...',
    meta1Label: 'UBICACIÓN',
    meta1Val: 'MRPD · PLANTA INFERIOR',
    meta2Label: 'ESTADO',
    meta2Val: 'ACCESO AUTORIZADO',
    meta3Label: 'CUERPO',
    meta3Val: 'POLICÍA DE LOS SANTOS',
    tip: 'COMISARÍA MRPD · CUERPO POLICIAL DE LOS SANTOS',
    statusText: 'Cargando flota policial...'
  },
  exit: {
    tag: 'DESPLIEGUE OPERATIVO',
    title: 'GARAJE DEPARTAMENTAL',
    subtitle: 'REGRESANDO A PATRULLAJE',
    message: 'Guardando estado de la flota, cerrando asignación y regresando al exterior de comisaría...',
    meta1Label: 'DESTINO',
    meta1Val: 'LOS SANTOS · EXTERIOR MRPD',
    meta2Label: 'ESTADO',
    meta2Val: 'EN SERVICIO ACTIVO',
    meta3Label: 'CANAL RADIO',
    meta3Val: 'FRECUENCIA 1 POLICÍA',
    tip: 'COMISARÍA MRPD · PATRULLAJE ACTIVO SAN ANDREAS',
    statusText: 'Saliendo al exterior...'
  },
  buy: {
    tag: 'TRAMITACIÓN DE VEHÍCULO EN CURSO',
    title: 'CONCESIONARIO POLICIAL',
    subtitle: 'ENTREGA Y MATRICULACIÓN DE UNIDAD',
    message: 'Verificando fondos, matriculando bastidor en base de datos de tráfico y preparando vehículo en plaza exterior...',
    meta1Label: 'ASIGNACIÓN',
    meta1Val: 'OFICIAL DE SERVICIO',
    meta2Label: 'MATRÍCULA',
    meta2Val: 'GENERANDO PLACA SAPD',
    meta3Label: 'ENTREGA',
    meta3Val: 'PARKING EXTERIOR MRPD',
    tip: 'UNIDAD POLICIAL ASIGNADA · DISPONIBLE EN EL EXTERIOR',
    statusText: 'Matriculando y preparando entrega...'
  }
};

let currentProgress = 0;
let progressInterval = null;

const elScreen = document.getElementById('loading-screen');
const elTag = document.getElementById('ls-tag');
const elIconBox = document.getElementById('ls-icon-box');
const elTitle = document.getElementById('ls-title');
const elSubtitle = document.getElementById('ls-subtitle');
const elMessage = document.getElementById('ls-message');
const elMeta1Label = document.getElementById('ls-meta1-label');
const elMeta1Val = document.getElementById('ls-meta1-val');
const elMeta2Label = document.getElementById('ls-meta2-label');
const elMeta2Val = document.getElementById('ls-meta2-val');
const elMeta3Label = document.getElementById('ls-meta3-label');
const elMeta3Val = document.getElementById('ls-meta3-val');
const elStatusText = document.getElementById('ls-status-text');
const elPercent = document.getElementById('ls-percent');
const elProgressBar = document.getElementById('ls-progress-bar');
const elTip = document.getElementById('ls-tip');

function setProgress(val) {
  currentProgress = Math.min(100, Math.max(0, val));
  elPercent.textContent = `${Math.round(currentProgress)}%`;
  elProgressBar.style.width = `${currentProgress}%`;
}

function startSimulatedProgress() {
  if (progressInterval) clearInterval(progressInterval);
  setProgress(5);
  
  progressInterval = setInterval(() => {
    if (currentProgress < 35) {
      setProgress(currentProgress + (Math.random() * 8 + 6));
    } else if (currentProgress < 75) {
      setProgress(currentProgress + (Math.random() * 5 + 3));
    } else if (currentProgress < 92) {
      setProgress(currentProgress + (Math.random() * 2 + 1));
    }
  }, 120);
}

function stopSimulatedProgress() {
  if (progressInterval) {
    clearInterval(progressInterval);
    progressInterval = null;
  }
}

function showLoading(payload) {
  const type = payload?.type || 'enter';
  const defaults = DEFAULT_CONFIGS[type] || DEFAULT_CONFIGS.enter;

  elTag.textContent = payload?.tag || defaults.tag;
  elTitle.textContent = payload?.title || defaults.title;
  elSubtitle.textContent = payload?.subtitle || defaults.subtitle;
  elMessage.textContent = payload?.message || defaults.message;

  elMeta1Label.textContent = payload?.meta1Label || defaults.meta1Label;
  elMeta1Val.textContent = payload?.meta1Val || defaults.meta1Val;
  elMeta2Label.textContent = payload?.meta2Label || defaults.meta2Label;
  elMeta2Val.textContent = payload?.meta2Val || defaults.meta2Val;
  elMeta3Label.textContent = payload?.meta3Label || defaults.meta3Label;
  elMeta3Val.textContent = payload?.meta3Val || defaults.meta3Val;

  elTip.textContent = payload?.tip || defaults.tip;
  elStatusText.textContent = payload?.statusText || defaults.statusText;

  elIconBox.innerHTML = ICONS[type] || ICONS.enter;

  elScreen.classList.remove('is-hidden');
  elScreen.setAttribute('aria-hidden', 'false');

  startSimulatedProgress();
}

function hideLoading() {
  stopSimulatedProgress();
  setProgress(100);
  elStatusText.textContent = '¡COMPLETADO!';

  setTimeout(() => {
    elScreen.classList.add('is-hidden');
    elScreen.setAttribute('aria-hidden', 'true');
    setTimeout(() => {
      setProgress(0);
    }, 400);
  }, 260);
}

window.addEventListener('message', (event) => {
  const data = event.data;
  if (!data || !data.action) return;

  switch (data.action) {
    case 'showLoading':
      showLoading(data);
      break;
    case 'updateProgress':
      if (typeof data.percent === 'number') {
        setProgress(data.percent);
      }
      if (data.statusText) {
        elStatusText.textContent = data.statusText;
      }
      break;
    case 'hideLoading':
      hideLoading();
      break;
  }
});
