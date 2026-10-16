// ========================================
// ORIGEN NETWORK - YOUTUBE PLAYER SYSTEM
// ========================================

let YOUTUBE_VIDEOS = [
    'dQw4w9WgXcQ', // Fallback video si no se cargan desde config
];

let player;
let currentVideoIndex = 0;
let videoIds = [];
let apiReady = false;
let videosLoaded = false;

// Cargar videos desde el mensaje NUI
function loadYoutubeVideosFromSetup(videos) {
    
    // Si es un string, convertir a array
    if (typeof videos === 'string') {
        videos = videos.split(',').map(id => id.trim()).filter(id => id.length > 0);
    }
    
    if (videos && Array.isArray(videos) && videos.length > 0) {
        // Limpiar IDs de espacios y asegurar que son strings válidos
        YOUTUBE_VIDEOS = videos.map(id => {
            if (typeof id === 'string') {
                return id.trim();
            } else if (typeof id === 'number') {
                return id.toString();
            } else {
                return String(id).trim();
            }
        }).filter(id => id.length > 0);
        
    } else {
        console.warn('[ORIGEN] No videos received from setup, using fallback');
    }
    videosLoaded = true;
    
    // Si la API ya está lista, inicializar el player
    if (apiReady) {
        initializePlayer();
    }
}

// Escuchar mensajes NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'setup' && data.youtubeVideos) {
        loadYoutubeVideosFromSetup(data.youtubeVideos);
    }
});

// Función para mezclar aleatoriamente el array de videos
function shuffleArray(array) {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
}

// Función para obtener el siguiente video aleatorio
function getNextRandomVideo() {
    if (videoIds.length === 0) {
        // Re-mezclar cuando se acaben los videos
        videoIds = shuffleArray(YOUTUBE_VIDEOS);
        currentVideoIndex = 0;
    }
    
    const videoId = videoIds[currentVideoIndex];
    currentVideoIndex++;
    
    if (currentVideoIndex >= videoIds.length) {
        currentVideoIndex = 0;
        videoIds = shuffleArray(YOUTUBE_VIDEOS);
    }
    
    return videoId;
}

// Esta función se llama automáticamente cuando la API de YouTube está lista
function onYouTubeIframeAPIReady() {
    apiReady = true;
    
    // Si los videos ya están cargados, inicializar el player
    if (videosLoaded) {
        initializePlayer();
    }
}

// Función para inicializar el player
function initializePlayer() {
    
    // Validar que tenemos videos
    if (!YOUTUBE_VIDEOS || YOUTUBE_VIDEOS.length === 0) {
        console.error('[ORIGEN] No videos available to play!');
        return;
    }
    
    // Inicializar array de videos mezclados
    videoIds = shuffleArray(YOUTUBE_VIDEOS);
    
    const firstVideoId = getNextRandomVideo();
    
    if (!firstVideoId || firstVideoId === 'undefined' || firstVideoId === 'null') {
        console.error('[ORIGEN] Invalid first video ID:', firstVideoId);
        return;
    }
    
    player = new YT.Player('youtube-player', {
        height: '100%',
        width: '100%',
        videoId: firstVideoId,
        playerVars: {
            'autoplay': 1,
            'controls': 0,
            'showinfo': 0,
            'modestbranding': 1,
            'loop': 0,
            'fs': 0,
            'cc_load_policy': 0,
            'iv_load_policy': 3,
            'autohide': 1,
            'mute': 1,
            'playsinline': 1,
            'rel': 0,
            'enablejsapi': 1
        },
        events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange,
            'onError': onPlayerError
        }
    });
}

// Cuando el player está listo
function onPlayerReady(event) {
    event.target.playVideo();
    event.target.mute();
    
    // Mostrar fade inicial
    showFade();
}

// Variables para controlar el timeout del resize y fade
let resizeTimeout = null;
let fadeTimeout = null;

// Función para mostrar/ocultar fade negro
function showFade() {
    const fadeElement = document.getElementById('video-fade');
    if (fadeElement) {
        fadeElement.classList.add('active');
    }
}

function hideFade() {
    const fadeElement = document.getElementById('video-fade');
    if (fadeElement) {
        fadeElement.classList.remove('active');
    }
}

// Función para actualizar el título del video
function updateVideoTitle() {
    if (player && player.getVideoData) {
        const videoData = player.getVideoData();
        const titleElement = document.getElementById('video-title');
        
        if (titleElement && videoData && videoData.title) {
            const title = videoData.title;
            // Limitar longitud del título si es muy largo
            const maxLength = 50;
            const displayTitle = title.length > maxLength 
                ? title.substring(0, maxLength) + '...' 
                : title;
            
            titleElement.textContent = displayTitle;
        }
    }
}

// Cuando cambia el estado del video
function onPlayerStateChange(event) {
    // Si el video terminó (estado 0), cargar el siguiente
    if (event.data === YT.PlayerState.ENDED) {
        
        // Fade in antes de cambiar video
        showFade();
        
        // Esperar 600ms (duración del fade) antes de cargar nuevo video
        setTimeout(() => {
            const nextVideo = getNextRandomVideo();
            player.loadVideoById(nextVideo);
        }, 600);
    }
    
    // Si el video está reproduciendo
    if (event.data === YT.PlayerState.PLAYING) {
        player.mute();
        
        // Actualizar título del video
        setTimeout(() => {
            updateVideoTitle();
        }, 500); // Esperar 500ms para que la API tenga los datos
        
        // Forzar tamaño grande al cargar nuevo video
        const playerElement = document.getElementById('youtube-player');
        if (playerElement) {
            // IMPORTANTE: Forzar tamaño 125% removiendo la clase
            playerElement.classList.remove('normal-size');
            
            // Forzar reflow para que el cambio se aplique inmediatamente
            void playerElement.offsetWidth;
            
            
            // Limpiar timeouts anteriores si existen
            if (resizeTimeout) {
                clearTimeout(resizeTimeout);
            }
            if (fadeTimeout) {
                clearTimeout(fadeTimeout);
            }
            
            // Fade out después de 1 segundo
            fadeTimeout = setTimeout(() => {
                hideFade();
            }, 1000);
            
            // Volver a tamaño normal (100%) después de 5 segundos
            resizeTimeout = setTimeout(() => {
                playerElement.classList.add('normal-size');
            }, 5000);
        }
    }
    
    // Si se carga un nuevo video (BUFFERING)
    if (event.data === YT.PlayerState.BUFFERING) {
        // Mantener fade durante buffering
        showFade();
        
        // Asegurar que el video vuelva a 125% cuando carga
        const playerElement = document.getElementById('youtube-player');
        if (playerElement) {
            playerElement.classList.remove('normal-size');
        }
    }
}

// Manejo de errores
function onPlayerError(event) {
    console.error('[ORIGEN] YouTube Player Error:', event.data);
    // Si hay un error, intentar con el siguiente video
    setTimeout(() => {
        const nextVideo = getNextRandomVideo();
        player.loadVideoById(nextVideo);
    }, 2000);
}

// Funciones para control externo del volumen
function setYouTubeVolume(volume) {
    if (player && player.setVolume) {
        // YouTube API espera un valor de 0-100
        player.setVolume(Math.min(100, Math.max(0, volume)));
    }
}

function muteYouTube() {
    if (player && player.mute) {
        player.mute();
    }
}

function unmuteYouTube() {
    if (player && player.unMute) {
        player.unMute();
    }
}

function stopYouTube() {
    if (player && player.stopVideo) {
        player.stopVideo();
    }
    if (resizeTimeout) {
        clearTimeout(resizeTimeout);
    }
    if (fadeTimeout) {
        clearTimeout(fadeTimeout);
    }
    hideFade();
}

// Exportar funciones globalmente
window.setYouTubeVolume = setYouTubeVolume;
window.muteYouTube = muteYouTube;
window.unmuteYouTube = unmuteYouTube;
window.stopYouTube = stopYouTube;
