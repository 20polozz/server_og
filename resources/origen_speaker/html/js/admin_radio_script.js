function adminGetParentResourceName() {
    let resourceName = window.location.hostname;

    if (resourceName.startsWith('cfx-nui-')) {
        resourceName = resourceName.substring(8);
    }

    return resourceName;
}

const resourceName = adminGetParentResourceName();

function adminSafeAddEventListener(selector, event, handler, context = document) {
    const element = context.querySelector(selector);
    if (element) {
        element.addEventListener(event, handler);
    } else {
        console.warn(`Element not found: ${selector}`);
    }
}

let adminRadioOpen = false;
let adminCurrentMode = 'zone';
let adminCurrentRadius = 50;
let adminCurrentVolume = 50;
let adminCurrentUrl = '';
let adminCurrentVideoId = '';
let adminCurrentTitle = 'Sin canción';
let adminIsPlaying = false;
let adminIsPaused = false;
let adminCurrentProgress = 0;
let adminCurrentDuration = 0;
let adminProgressInterval = null;
let adminPlayersListening = [];

let adminMainPlayer = null;
let adminPlayerReady = false;

let adminAudioPlayers = {};

/* window.addEventListener('message', function (event) {
    const data = event.data;
    switch (data.action) {
        case 'openAdminRadio':
            openAdminRadioPanel(data);
            break;
        case 'closeAdminRadio':
            closeAdminRadioPanel();
            break;
        case 'updatePlayersListening':
            updatePlayersList(data.players);
            break;
        case 'updateAdminRadioHud':
            updateAdminRadioHud(data);
            break;
        case 'showAdminRadioHud':
            showAdminRadioHud();
            break;
        case 'hideAdminRadioHud':
            hideAdminRadioHud();
            break;
        case 'playMusicFromAdmin':
            playMusicFromAdmin(data);
            break;
        case 'stopMusicFromAdmin':
            stopMusicFromAdmin();
            break;
        case 'updateVolumeFromAdmin':
            updateVolumeFromAdmin(data.volume);
            break;
    }
}); */

window.addEventListener('message', function (event) {
    const data = event.data;

    if (data.action) {

        switch (data.action) {
            case 'updatePlayersListening':
                updatePlayersList(data.players);
                break;
            case 'updateAdminRadioHud':
                updateAdminRadioHud(data);
                break;
            case 'showAdminRadioHud':
                showAdminRadioHud();
                break;
            case 'hideAdminRadioHud':
                hideAdminRadioHud();
                break;
            case 'playMusicFromAdmin':
                playMusicFromAdmin(data);
                break;
            case 'pauseMusicFromAdmin':
                pauseMusicFromAdmin();
                break;
            case 'resumeMusicFromAdmin':
                resumeMusicFromAdmin();
                break;
            case 'stopMusicFromAdmin':
                stopMusicFromAdmin();
                break;
            case 'updateVolumeFromAdmin':
                updateVolumeFromAdmin(data.volume);
                break;
            case 'adminRadioPlayResponse':
                if (data.title) {
                    adminCurrentTitle = data.title;
                    const titleElem = document.getElementById('adminCurrentInfo');
                    if (titleElem) {
                        titleElem.innerHTML = `<div class="song-title">${adminCurrentTitle}</div>`;
                    }
                }
                break;
        }
    }
});

function openAdminRadioPanel(data = {}) {
    adminRadioOpen = true;
    const panel = document.getElementById('adminRadioPanel');
    panel.classList.remove('hidden');

    if (data.mode) adminCurrentMode = data.mode;
    if (data.radius) adminCurrentRadius = data.radius;
    if (data.volume) adminCurrentVolume = data.volume;

    document.querySelectorAll('input[name="mode"]').forEach(radio => {
        radio.checked = (radio.value === adminCurrentMode);
    });

    document.getElementById('radiusSlider').value = adminCurrentRadius;
    document.getElementById('radiusValue').textContent = adminCurrentRadius;

    document.getElementById('adminVolumeSlider').value = adminCurrentVolume;
    document.getElementById('adminVolumeValue').textContent = adminCurrentVolume;

    updateModeVisibility();

    // fetchPlaylists();
}

function closeAdminRadioPanel() {
    adminRadioOpen = false;
    const panel = document.getElementById('adminRadioPanel');
    if (panel) {
        panel.classList.add('hidden');
    }

    const resName = (window.adminGetParentResourceName) ? adminGetParentResourceName() : 'origen_speaker';
    fetch(`https://${resName}/closeAdminRadio`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function startVoiceBroadcast() {
    const broadcastBtn = document.getElementById('adminBroadcastBtn');
    const broadcastStatus = document.getElementById('adminBroadcastStatus');
    const broadcastSubtitle = document.getElementById('adminBroadcastSubtitle');

    if (broadcastBtn) {
        broadcastBtn.setAttribute('data-broadcasting', 'true');
    }

    if (broadcastStatus) {
        broadcastStatus.classList.remove('hidden');
    }

    if (broadcastSubtitle) {
        broadcastSubtitle.textContent = 'Transmitiendo...';
    }

    const mode = document.querySelector('input[name="mode"]:checked')?.value || 'zone';
    const radius = parseInt(document.getElementById('radiusSlider')?.value || 50);

    const resName = (window.adminGetParentResourceName) ? adminGetParentResourceName() : 'origen_speaker';
    fetch(`https://${resName}/startVoiceBroadcast`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            mode: mode,
            radius: radius
        })
    });
}

function stopVoiceBroadcast() {
    const broadcastBtn = document.getElementById('adminBroadcastBtn');
    const broadcastStatus = document.getElementById('adminBroadcastStatus');
    const broadcastSubtitle = document.getElementById('adminBroadcastSubtitle');

    if (broadcastBtn) {
        broadcastBtn.setAttribute('data-broadcasting', 'false');
    }

    if (broadcastStatus) {
        broadcastStatus.classList.add('hidden');
    }

    if (broadcastSubtitle) {
        broadcastSubtitle.textContent = 'Mantén para transmitir';
    }

    const resName = (window.adminGetParentResourceName) ? adminGetParentResourceName() : 'origen_speaker';
    fetch(`https://${resName}/stopVoiceBroadcast`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function updateModeVisibility() {
    const radiusSection = document.getElementById('radiusSection');
    const playersListSection = document.getElementById('playersListSection');

    if (adminCurrentMode === 'zone') {
        radiusSection.classList.remove('hidden');
        playersListSection.classList.remove('hidden');
    } else {
        radiusSection.classList.add('hidden');
        playersListSection.classList.add('hidden');
    }
}

function onModeChange(mode) {
    adminCurrentMode = mode;
    updateModeVisibility();

    fetch(`https://${resourceName}/adminRadioChangeMode`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode: mode })
    });
}

function onRadiusChange(radius) {
    adminCurrentRadius = radius;
    document.getElementById('radiusValue').textContent = radius;

    fetch(`https://${resourceName}/adminRadioChangeRadius`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ radius: radius })
    });
}

function updatePlayersList(players) {
    adminPlayersListening = players || [];

    const playersCount = document.getElementById('playersCount');
    const playersList = document.getElementById('playersList');

    playersCount.textContent = adminPlayersListening.length;

    if (adminPlayersListening.length === 0) {
        playersList.innerHTML = `
            <div class="players-empty">
                <svg width="calc(5vh / var(--ogn-escala, 1))" height="calc(5vh / var(--ogn-escala, 1))" viewBox="0 0 24 24" fill="none" stroke="currentColor">
                    <circle cx="12" cy="12" r="10" stroke-width="2"/>
                    <path d="M12 8v8M8 12h8" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <span>Sin jugadores en rango</span>
            </div>
        `;
    } else {
        playersList.innerHTML = adminPlayersListening.map(player => `
            <div class="player-item">
                <span class="player-name">${player.name}</span>
                <span class="player-distance">${player.distance}m</span>
            </div>
        `).join('');
    }
}

function adminPlayMusic() {
    const urlInput = document.getElementById('adminUrlInput');
    const url = urlInput.value.trim();

    if (!url) {
        console.warn('No URL provided');
        return;
    }

    const videoId = adminExtractYouTubeID(url);
    if (!videoId) {
        console.warn('Invalid YouTube URL');
        return;
    }

    adminCurrentUrl = url;
    adminCurrentVideoId = videoId;
    adminCurrentTitle = 'Cargando...';
    adminIsPlaying = true;
    adminIsPaused = false;
    adminCurrentProgress = 0;

    adminUpdateNowPlaying();
    adminUpdatePlayPauseButton('playing');

    fetch(`https://${resourceName}/adminRadioPlay`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            videoId: videoId,
            url: url,
            volume: adminCurrentVolume,
            mode: adminCurrentMode,
            radius: adminCurrentRadius
        })
    }).then(resp => resp.json()).then(data => {
        if (data.title) {
            adminCurrentTitle = data.title;
            const titleElem = document.getElementById('adminCurrentInfo');
            if (titleElem) {
                titleElem.innerHTML = `<div class="song-title">${adminCurrentTitle}</div>`;
            }
        }
    }).catch(err => console.error('Error playing music:', err));

    if (adminPlayerReady && adminMainPlayer) {
        adminMainPlayer.loadVideoById(videoId);
        adminMainPlayer.setVolume(adminCurrentVolume);
        adminMainPlayer.playVideo();
    }
}

function adminPauseMusic() {
    adminIsPaused = true;
    adminIsPlaying = false;

    adminUpdatePlayPauseButton('paused');
    adminPauseProgressAnimation();

    const equalizer = document.getElementById('adminEqualizer');
    if (equalizer) equalizer.classList.add('paused');

    fetch(`https://${resourceName}/adminRadioPause`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    if (adminMainPlayer) {
        adminMainPlayer.pauseVideo();
    }
}

function adminResumeMusic() {
    adminIsPaused = false;
    adminIsPlaying = true;

    adminUpdatePlayPauseButton('playing');
    adminStartProgressAnimation(adminCurrentProgress, adminCurrentDuration);

    const equalizer = document.getElementById('adminEqualizer');
    if (equalizer) equalizer.classList.remove('paused');

    fetch(`https://${resourceName}/adminRadioResume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    if (adminMainPlayer) {
        adminMainPlayer.playVideo();
    }
}

function adminStopMusic() {
    adminIsPlaying = false;
    adminIsPaused = false;
    adminCurrentVideoId = '';
    adminCurrentTitle = 'Sin canción';
    adminCurrentProgress = 0;
    adminCurrentDuration = 0;

    adminUpdateNowPlaying();
    adminUpdatePlayPauseButton('stopped');
    adminStopProgressAnimation();

    fetch(`https://${resourceName}/adminRadioStop`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    if (adminMainPlayer) {
        adminMainPlayer.stopVideo();
    }
}

function adminSetVolume(volume) {
    adminCurrentVolume = volume;
    document.getElementById('adminVolumeValue').textContent = volume;

    fetch(`https://${resourceName}/adminRadioSetVolume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ volume: volume })
    });

    if (adminMainPlayer) {
        adminMainPlayer.setVolume(volume);
    }
}

function adminUpdateNowPlaying() {
    const titleElement = document.getElementById('adminCurrentInfo');
    const equalizer = document.getElementById('adminEqualizer');

    if (titleElement) {
        if (adminIsPlaying || adminIsPaused) {
            titleElement.innerHTML = `<div class="song-title">${adminCurrentTitle}</div>`;
        } else {
            titleElement.innerHTML = '<div class="no-music">Sin música</div>';
        }
    }

    if (equalizer) {
        if (adminIsPlaying) {
            equalizer.classList.remove('paused');
            adminStartProgressAnimation(0, 0);
        } else {
            equalizer.classList.add('paused');
            adminStopProgressAnimation();
        }
    }
}

function adminUpdatePlayPauseButton(state) {
    const playBtn = document.getElementById('adminPlayBtn');
    if (!playBtn) return;

    const playIcon = playBtn.querySelector('.icon-play');
    const pauseIcon = playBtn.querySelector('.icon-pause');

    playBtn.setAttribute('data-state', state);

    if (state === 'playing') {
        if (playIcon) playIcon.style.display = 'none';
        if (pauseIcon) pauseIcon.style.display = 'inline-block';
        playBtn.title = 'Pausar';
    } else {
        if (playIcon) playIcon.style.display = 'inline-block';
        if (pauseIcon) pauseIcon.style.display = 'none';
        playBtn.title = 'Reproducir';
    }
}

function adminStartProgressAnimation(startTime = 0, duration = 0) {
    adminStopProgressAnimation();

    if (adminMainPlayer && adminPlayerReady) {
        duration = adminMainPlayer.getDuration();
        startTime = adminMainPlayer.getCurrentTime();
    }

    adminCurrentDuration = duration;
    adminCurrentProgress = startTime;

    const progressContainer = document.getElementById('adminProgressContainer');
    const currentTimeElem = document.getElementById('adminCurrentTime');
    const totalTimeElem = document.getElementById('adminTotalTime');
    const progressFill = document.getElementById('adminProgressFill');

    if (progressContainer) progressContainer.style.display = 'block';
    if (totalTimeElem) totalTimeElem.textContent = adminFormatTime(duration);

    adminProgressInterval = setInterval(() => {
        if (adminMainPlayer && adminPlayerReady && adminIsPlaying) {
            adminCurrentProgress = adminMainPlayer.getCurrentTime();
            adminCurrentDuration = adminMainPlayer.getDuration();

            const percentage = (adminCurrentProgress / adminCurrentDuration) * 100;
            if (progressFill) progressFill.style.width = `${percentage}%`;
            if (currentTimeElem) currentTimeElem.textContent = adminFormatTime(adminCurrentProgress);
        }
    }, 1000);
}

function adminPauseProgressAnimation() {
    if (adminProgressInterval) {
        clearInterval(adminProgressInterval);
        adminProgressInterval = null;
    }
}

function adminStopProgressAnimation() {
    if (adminProgressInterval) {
        clearInterval(adminProgressInterval);
        adminProgressInterval = null;
    }

    adminCurrentProgress = 0;
    adminCurrentDuration = 0;

    const progressContainer = document.getElementById('adminProgressContainer');
    const progressFill = document.getElementById('adminProgressFill');
    const currentTimeElem = document.getElementById('adminCurrentTime');
    const totalTimeElem = document.getElementById('adminTotalTime');

    if (progressContainer) progressContainer.style.display = 'none';
    if (progressFill) progressFill.style.width = '0%';
    if (currentTimeElem) currentTimeElem.textContent = '0:00';
    if (totalTimeElem) totalTimeElem.textContent = '0:00';
}

function adminFormatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function updateAdminRadioHud(data) {
    const titleElem = document.getElementById('adminRadioHudTitle');
    const progressFill = document.querySelector('.hud-progress-fill');

    if (data.title) {
        titleElem.textContent = data.title;
    }

    if (data.progress !== undefined && data.duration !== undefined && data.duration > 0) {
        const percentage = (data.progress / data.duration) * 100;
        progressFill.style.width = `${percentage}%`;
    }
}

function showAdminRadioHud() {
    const hud = document.getElementById('adminRadioHud');
    hud.classList.remove('hidden');
}

function hideAdminRadioHud() {
    const hud = document.getElementById('adminRadioHud');
    hud.classList.add('hidden');
}

function playMusicFromAdmin(data) {
    const videoId = data.videoId;
    // 0 es un volumen valido: es el que llega con el modo streamer puesto.
    const volume = data.volume ?? 50;
    const mode = data.mode || 'zone';

    if (adminIsPlaying && adminCurrentVideoId === videoId) {
        // I am the admin who started this, I already have adminMainPlayer playing
    } else {
        adminCreateAudioPlayer('admin_broadcast', videoId, volume, mode);
    }

    if (data.title) {
        updateAdminRadioHud({ title: data.title, progress: 0, duration: 0 });
    }
    showAdminRadioHud();
}

function pauseMusicFromAdmin() {
    if (adminAudioPlayers['admin_broadcast']) {
        adminAudioPlayers['admin_broadcast'].player.pauseVideo();
    }
    const hud = document.getElementById('adminRadioHud');
    if (hud) hud.classList.add('paused');
}

function resumeMusicFromAdmin() {
    if (adminAudioPlayers['admin_broadcast']) {
        adminAudioPlayers['admin_broadcast'].player.playVideo();
    }
    const hud = document.getElementById('adminRadioHud');
    if (hud) hud.classList.remove('paused');
}

function stopMusicFromAdmin() {
    adminDestroyAudioPlayer('admin_broadcast');
    hideAdminRadioHud();
}

function updateVolumeFromAdmin(volume) {
    if (adminAudioPlayers['admin_broadcast']) {
        adminAudioPlayers['admin_broadcast'].baseVolume = volume;
        adminAudioPlayers['admin_broadcast'].player.setVolume(volume);
    }
}

function adminCreateAudioPlayer(playerId, videoId, volume, mode) {
    adminDestroyAudioPlayer(playerId);
    const container = document.getElementById('adminAudioPlayers');
    const playerDiv = document.createElement('div');
    playerDiv.id = `admin-player-${playerId}`;
    container.appendChild(playerDiv);

    const player = new YT.Player(playerDiv.id, {
        height: '1',
        width: '1',
        videoId: videoId,
        playerVars: {
            'autoplay': 1,
            'controls': 0,
            'disablekb': 1,
            'fs': 0,
            'modestbranding': 1,
            'playsinline': 1
        },
        events: {
            'onReady': (event) => {
                event.target.setVolume(volume);
                event.target.playVideo();
            },
            'onStateChange': (event) => {
                if (event.data === YT.PlayerState.PLAYING) {
                    setInterval(() => {
                        if (adminAudioPlayers[playerId]) {
                            const progress = adminAudioPlayers[playerId].player.getCurrentTime();
                            const duration = adminAudioPlayers[playerId].player.getDuration();
                            updateAdminRadioHud({ progress, duration });
                        }
                    }, 1000);
                }
            }
        }
    });

    adminAudioPlayers[playerId] = {
        player: player,
        videoId: videoId,
        baseVolume: volume,
        mode: mode
    };
}

function adminDestroyAudioPlayer(playerId) {
    if (adminAudioPlayers[playerId]) {
        try {
            adminAudioPlayers[playerId].player.destroy();
        } catch (e) {
            console.warn('Error destroying player:', e);
        }

        const playerDiv = document.getElementById(`admin-player-${playerId}`);
        if (playerDiv) {
            playerDiv.remove();
        }

        delete adminAudioPlayers[playerId];
    }
}

function adminExtractYouTubeID(url) {
    const regExp = /^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*/;
    const match = url.match(regExp);
    return (match && match[7].length === 11) ? match[7] : null;
}

/* function fetchPlaylists() {
    fetch(`https://${resourceName}/getPlaylists`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => resp.json()).then(data => {
        if (data.success && data.myPlaylists) {
            renderMyPlaylists(data.myPlaylists);
        }
    });
} */

/* function renderMyPlaylists(playlists) {
    const container = document.getElementById('adminMyPlaylists');

    if (!playlists || playlists.length === 0) {
        container.innerHTML = '<div class="players-empty"><span>Aún no hay listas</span></div>';
        return;
    }

    container.innerHTML = playlists.map(playlist => `
        <div class="player-item" onclick="playAdminPlaylist(${playlist.id})">
            <span class="player-name">${playlist.name}</span>
            <span class="player-distance">${playlist.songCount || 0} songs</span>
        </div>
    `).join('');
} */

function playAdminPlaylist(playlistId) {
    fetch(`https://${resourceName}/getPlaylistSongs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId: playlistId })
    }).then(resp => resp.json()).then(data => {
        if (data.success && data.songs && data.songs.length > 0) {
            const firstSong = data.songs[0];
            document.getElementById('adminUrlInput').value = firstSong.url;
            adminPlayMusic();
        }
    });
}

window.playAdminPlaylist = playAdminPlaylist;

let YTReady = false;

function adminInitYouTubePlayer() {
    YTReady = true;

    const adminMainPlayerDiv = document.createElement('div');
    adminMainPlayerDiv.id = 'admin-main-player';
    document.getElementById('adminAudioPlayers').appendChild(adminMainPlayerDiv);

    adminMainPlayer = new YT.Player('admin-main-player', {
        height: '1',
        width: '1',
        playerVars: {
            'autoplay': 0,
            'controls': 0
        },
        events: {
            'onReady': (event) => {
                adminPlayerReady = true;
            }
        }
    });
}

if (typeof window.onYouTubeIframeAPIReady === 'function') {
    const originalOnYouTubeIframeAPIReady = window.onYouTubeIframeAPIReady;
    window.onYouTubeIframeAPIReady = function () {
        originalOnYouTubeIframeAPIReady();
        adminInitYouTubePlayer();
    };
} else {
    window.onYouTubeIframeAPIReady = adminInitYouTubePlayer;
}

document.addEventListener('DOMContentLoaded', function () {
    const adminCloseBtn = document.getElementById('adminCloseBtn');
    if (adminCloseBtn) {
        adminCloseBtn.addEventListener('click', function () {
            closeAdminRadioPanel();
        });
    }

    document.querySelectorAll('input[name="mode"]').forEach(radio => {
        radio.addEventListener('change', (e) => onModeChange(e.target.value));
    });

    adminSafeAddEventListener('#radiusSlider', 'input', (e) => onRadiusChange(parseInt(e.target.value)));

    adminSafeAddEventListener('#adminVolumeSlider', 'input', (e) => adminSetVolume(parseInt(e.target.value)));

    adminSafeAddEventListener('#adminPlayBtn', 'click', () => {
        const state = document.getElementById('adminPlayBtn').getAttribute('data-state');
        if (state === 'playing') {
            adminPauseMusic();
        } else if (state === 'paused') {
            adminResumeMusic();
        } else {
            adminPlayMusic();
        }
    });

    adminSafeAddEventListener('#adminStopBtn', 'click', adminStopMusic);

    adminSafeAddEventListener('#adminAddToPlaylistBtn', 'click', () => { });

    const broadcastBtn = document.getElementById('adminBroadcastBtn');
    if (broadcastBtn) {
        let isHolding = false;

        broadcastBtn.addEventListener('mousedown', () => {
            isHolding = true;
            startVoiceBroadcast();
        });

        broadcastBtn.addEventListener('mouseup', () => {
            if (isHolding) {
                isHolding = false;
                stopVoiceBroadcast();
            }
        });

        broadcastBtn.addEventListener('mouseleave', () => {
            if (isHolding) {
                isHolding = false;
                stopVoiceBroadcast();
            }
        });
    }

    adminSafeAddEventListener('#adminUrlInput', 'keypress', (e) => {
        if (e.key === 'Enter') {
            adminPlayMusic();
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && adminRadioOpen) {
            closeAdminRadioPanel();
        }
    });
});

const style = document.createElement('style');
style.textContent = `
    #adminProgressBar .progress-fill::before {
        width: var(--progress, 0%);
    }
`;
document.head.appendChild(style);
// La barra de cifras del panel (plantilla de admin): lee lo que ya enseña el
// panel —modo, radio, volumen y oyentes— mientras está abierto.
(function () {
    const poner = (id, v) => { const e = document.getElementById(id); if (e && e.textContent !== v) e.textContent = v; };
    setInterval(() => {
        const panel = document.getElementById('adminRadioPanel');
        if (!panel || panel.classList.contains('hidden')) return;
        const modo = document.querySelector('input[name="mode"]:checked')?.value || 'zone';
        poner('spBarModo', modo === 'private' ? 'Privado' : 'Zona');
        poner('spBarRadio', modo === 'private' ? '—' : (document.getElementById('radiusValue')?.textContent || '0') + ' m');
        poner('spBarVolumen', (document.getElementById('adminVolumeValue')?.textContent || '0').replace(/\s*%/, '') + ' %');
        poner('spBarOyentes', modo === 'private' ? '—' : (document.getElementById('playersCount')?.textContent || '0'));
    }, 400);
})();
