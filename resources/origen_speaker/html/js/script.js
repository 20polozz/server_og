function safeAddEventListener(elementId, event, callback) {
    const element = document.getElementById(elementId);
    if (element) {
        element.addEventListener(event, callback);
        return true;
    } else {
        return false;
    }
}

let player = null;
let playerReady = false;
let currentUrl = null;

let audioPlayers = {};

let speakerId = null;
let currentVolume = 50;
let myPlaylists = [];
let sharedPlaylists = [];
let currentPlaylist = null;
let currentSongs = [];
let isShuffleEnabled = false;
let isLoopEnabled = false;
let isCarRadio = false;
let vehiclePlate = null;
let currentVideoId = null;
let progressInterval = null;
let currentSongIndex = -1;
let isPlayingPlaylist = false;
let isPaused = false;
let isPlaying = false;
let currentProgress = 0;
let currentDuration = 240;

let hudEnabled = localStorage.getItem('hudEnabled') !== 'false';
let currentHudTitle = 'Sin música';

let modalAction = null;
let modalData = null;

function onYouTubeIframeAPIReady() {
    player = new YT.Player('youtubePlayer', {
        height: '0',
        width: '0',
        playerVars: {
            'controls': 0,
            'disablekb': 1,
            'fs': 0,
            'modestbranding': 1
        },
        events: {
            'onReady': onPlayerReady,
            'onStateChange': onPlayerStateChange,
            'onError': onPlayerError
        }
    });
}

function onPlayerReady(event) {
    playerReady = true;
    if (player) {
        player.setVolume(0);
        player.mute();
    }
}

function onPlayerStateChange(event) {
    if (event.data === YT.PlayerState.ENDED && isPlayingPlaylist) {
        playNextSong();
    }
}

function onPlayerError(event) {
    showNotification('error', 'Error al reproducir vídeo');
}

if (!window.YT) {
    const tag = document.createElement('script');
    tag.src = 'https://www.youtube.com/iframe_api';
    const firstScriptTag = document.getElementsByTagName('script')[0];
    firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);
}

document.getElementById('closeBtn').addEventListener('click', () => {
    if (isCarRadio) {
        closeSpeakerPanel();
    } else {
        removeSpeaker();
    }
});

document.querySelectorAll('.playlist-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        const tabName = tab.getAttribute('data-tab');

        // Las pestañas viven en el riel y se ven también con una lista
        // abierta: pulsar una vuelve primero de la vista de canciones.
        const songsView = document.getElementById('songsView');
        if (songsView && !songsView.classList.contains('hidden')) closeSongsView();

        document.querySelectorAll('.playlist-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');

        if (tabName === 'my') {
            document.getElementById('myPlaylistsTab').style.display = 'block';
            document.getElementById('sharedPlaylistsTab').style.display = 'none';
        } else if (tabName === 'shared') {
            document.getElementById('myPlaylistsTab').style.display = 'none';
            document.getElementById('sharedPlaylistsTab').style.display = 'block';
        }
    });
});

document.getElementById('playBtn').addEventListener('click', () => {
    const playBtn = document.getElementById('playBtn');
    const currentState = playBtn.getAttribute('data-state');

    if (currentState === 'pause') {
        pauseMusic();
    } else {
        if (isPaused && currentUrl) {
            resumeMusic();
        } else {
            const urlInput = document.getElementById('urlInput');
            const url = urlInput.value.trim();

            if (!url) {
                showNotification('error', 'Introduce una URL de YouTube');
                return;
            }

            if (!isValidYouTubeUrl(url)) {
                showNotification('error', 'URL de YouTube no válida');
                return;
            }

            isPlayingPlaylist = false;
            currentSongIndex = -1;

            playMusic(url);
            urlInput.value = '';
        }
    }
});

document.getElementById('stopBtn').addEventListener('click', () => {
    stopMusic();
});

document.getElementById('volumeSlider').addEventListener('input', (e) => {
    const volume = parseInt(e.target.value);
    setVolume(volume);
});

document.getElementById('addPlaylistBtn').addEventListener('click', () => {
    if (!currentUrl) return;
    openAddToPlaylistModal();
});

document.getElementById('createPlaylistBtn').addEventListener('click', () => {
    openCreatePlaylistModal();
});

document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const tab = btn.getAttribute('data-tab');
        switchTab(tab);
    });
});

const backBtn = document.getElementById('backBtn') || document.getElementById('backToPlaylistsBtn');
if (backBtn) {
    backBtn.addEventListener('click', () => {
        closeSongsView();
    });
}

const shuffleBtn = document.getElementById('shuffleBtn');
if (shuffleBtn) {
    shuffleBtn.addEventListener('click', () => {
        isShuffleEnabled = !isShuffleEnabled;
        shuffleBtn.classList.toggle('active', isShuffleEnabled);
        showNotification('success', isShuffleEnabled ? 'Aleatorio activado' : 'Aleatorio desactivado');
    });
}

const loopBtn = document.getElementById('loopBtn');
if (loopBtn) {
    loopBtn.addEventListener('click', () => {
        isLoopEnabled = !isLoopEnabled;
        loopBtn.classList.toggle('active', isLoopEnabled);
        showNotification('success', isLoopEnabled ? 'Bucle activado' : 'Bucle desactivado');
    });
}

const playAllBtn = document.getElementById('playAllBtn');
if (playAllBtn) {
    playAllBtn.addEventListener('click', () => {
        playAllSongs();
    });
}

document.getElementById('confirmPlaylistName').addEventListener('click', () => {
    confirmPlaylistNameAction();
});

document.getElementById('confirmSharePlaylist').addEventListener('click', () => {
    confirmSharePlaylist();
});

document.getElementById('urlInput').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') {
        document.getElementById('playBtn').click();
    }
});

const playlistImageInput = document.getElementById('playlistImageInput');
if (playlistImageInput) {
    playlistImageInput.addEventListener('input', (e) => {
        const url = e.target.value.trim();
        const imagePreview = document.getElementById('imagePreview');
        const imagePreviewContainer = document.getElementById('imagePreviewContainer');

        if (url && imagePreview && imagePreviewContainer) {
            imagePreview.src = url;
            imagePreviewContainer.style.display = 'block';

            imagePreview.onerror = () => {
                imagePreviewContainer.style.display = 'none';
            };
        } else if (imagePreviewContainer) {
            imagePreviewContainer.style.display = 'none';
        }
    });
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        const adminRadioPanel = document.getElementById('adminRadioPanel');
        if (adminRadioPanel && !adminRadioPanel.classList.contains('hidden')) {
            adminRadioPanel.classList.add('hidden');
            fetch(`https://${GetParentResourceName()}/closeAdminRadio`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            return;
        }

        const exploreModal = document.getElementById('explorePlaylistsModal');
        if (exploreModal && !exploreModal.classList.contains('hidden')) {
            closeExploreModal();
            return;
        }

        const anyModalOpen = Array.from(document.querySelectorAll('.modal')).some(modal => !modal.classList.contains('hidden'));

        if (anyModalOpen) {
            closeModal();
        } else {
            const songsView = document.getElementById('songsView');
            if (songsView && !songsView.classList.contains('hidden')) {
                closeSongsView();
            } else {
                closeSpeakerPanel();
            }
        }
    }
});

const explorePlaylistBtn = document.getElementById('explorePlaylistBtn');
if (explorePlaylistBtn) {
    explorePlaylistBtn.addEventListener('click', () => {
        openExploreModal();
    });
}

const exploreBackBtn = document.getElementById('exploreBackBtn');
if (exploreBackBtn) {
    exploreBackBtn.addEventListener('click', () => {
        closeExploreModal();
    });
}

const exploreSearchInput = document.getElementById('exploreSearchInput');
if (exploreSearchInput) {
    exploreSearchInput.addEventListener('input', (e) => {
        filterExplorePlaylists(e.target.value);
    });
}

const exploreSortSelect = document.getElementById('exploreSortSelect');
if (exploreSortSelect) {
    exploreSortSelect.addEventListener('change', (e) => {
        sortExplorePlaylists(e.target.value);
    });
}

window.addEventListener('message', (event) => {
    const data = event.data;

    switch (data.action) {
        case 'openSpeaker':
            openSpeakerPanel(data.speakerId, data.isCarRadio, data.vehiclePlate, data.syncStatus);
            break;
        case 'closeSpeaker':
            // Lo cierra Lua (altavoz quitado): el foco ya lo solto alli, asi
            // que sin avisar de vuelta.
            document.getElementById('speaker-container').classList.add('hidden');
            speakerId = null;
            isCarRadio = false;
            vehiclePlate = null;
            showHudBanner();
            break;
        case 'updateNowPlaying':
            updateNowPlaying(data.title, data.videoId || currentVideoId);
            break;
        case 'updatePlaylists':
            updatePlaylists(data.myPlaylists, data.sharedPlaylists);
            break;
        case 'showNotification':
            showNotification(data.type, data.message);
            break;
        case 'playSong':
            break;
        case 'createSound':
            if (data.data) {
                createAudioPlayer(data.data.speakerId, data.data.videoId, data.data.volume, data.data.startSeconds || 0);
            }
            break;
        case 'destroySound':
            if (data.data) {
                destroyAudioPlayer(data.data.speakerId);
            }
            break;
        case 'set3DVolume':
            if (data.data) {
                set3DVolume(data.data.speakerId, data.data.volume);
            }
            break;
        case 'updateVolume':
            if (data.data) {
                const volume = data.data.volume;
                updateAudioPlayerVolume(data.data.speakerId, volume);

                if (data.data.speakerId === speakerId) {
                    const volumeSlider = document.getElementById('volumeSlider');
                    const volumeValue = document.getElementById('volumeValue');
                    if (volumeSlider) volumeSlider.value = volume;
                    if (volumeValue) volumeValue.textContent = `${volume}%`;
                }
            }
            break;
        case 'pauseSound':
            if (data.data) {
                pauseAudioPlayer(data.data.speakerId);
            }
            break;
        case 'resumeSound':
            if (data.data) {
                resumeAudioPlayer(data.data.speakerId);
            }
            break;
        case 'openAdminRadio':
            const adminPanel = document.getElementById('adminRadioPanel');
            if (adminPanel) {
                adminPanel.classList.remove('hidden');
                if (data.mode) {
                    document.querySelectorAll('input[name="mode"]').forEach(radio => {
                        radio.checked = (radio.value === data.mode);
                    });
                }

                if (data.radius) {
                    const radiusSlider = document.getElementById('radiusSlider');
                    const radiusValue = document.getElementById('radiusValue');
                    if (radiusSlider) radiusSlider.value = data.radius;
                    if (radiusValue) radiusValue.textContent = data.radius;
                }

                if (data.volume !== undefined) {
                    const volumeSlider = document.getElementById('adminVolumeSlider');
                    const volumeValue = document.getElementById('adminVolumeValue');
                    if (volumeSlider) volumeSlider.value = data.volume;
                    if (volumeValue) volumeValue.textContent = data.volume;
                }
                // El radio y la lista de oyentes solo salen en modo zona: al
                // abrir no se pintaban hasta cambiar de modo a mano.
                if (typeof adminCurrentMode !== 'undefined') {
                    adminCurrentMode = data.mode || 'zone';
                    if (typeof updateModeVisibility === 'function') updateModeVisibility();
                }
            } else {
            }
            break;
    }
});

function openSpeakerPanel(id, carRadio = false, plate = null, syncStatus = null) {
    speakerId = id;
    isCarRadio = carRadio;
    vehiclePlate = plate;

    const container = document.getElementById('speaker-container');
    const content = document.querySelector('.content');
    if (!container) {
        return;
    }

    const isSlaveSpeaker = syncStatus && syncStatus.synced && syncStatus.role === 'slave';
    if (isSlaveSpeaker) {
        if (content) content.classList.add('controls-disabled');
    } else {
        if (content) content.classList.remove('controls-disabled');
    }
    container.classList.remove('hidden');
    hideHudBanner();
    if (isPlaying && !isPaused) {
        updatePlayPauseButton('pause');
    } else {
        updatePlayPauseButton('play');
    }

    const titleElement = document.querySelector('.title-section .title span');
    if (titleElement) {
        if (isCarRadio) {
            titleElement.textContent = 'Radio del Coche';
        } else {
            titleElement.textContent = 'Música';
        }
    }

    const closeBtn = document.getElementById('closeBtn');
    if (closeBtn) {
        if (isCarRadio) {
            closeBtn.innerHTML = `
                <iconify-icon icon="lucide:x"></iconify-icon>
            `;
            closeBtn.classList.remove('danger');
        } else {
            closeBtn.innerHTML = `
                <iconify-icon icon="lucide:music"></iconify-icon>
            `;
            closeBtn.classList.add('danger');
        }
    }

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    fetch(`https://${GetParentResourceName()}/getPlaylists`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
        signal: controller.signal
    }).then(resp => {
        clearTimeout(timeoutId);
        if (!resp.ok) {
            throw new Error('Network response was not ok');
        }
        return resp.text();
    }).then(text => {
        if (!text || text.trim() === '') {
            return { myPlaylists: [], sharedPlaylists: [] };
        }
        return JSON.parse(text);
    }).then(resp => {
        if (resp && resp.myPlaylists && resp.sharedPlaylists) {
            updatePlaylists(resp.myPlaylists, resp.sharedPlaylists);
        } else {
            updatePlaylists([], []);
        }
    }).catch(err => {
        clearTimeout(timeoutId);
        updatePlaylists([], []);
    });

    const syncSection = document.getElementById('syncSection');
    const syncNotSynced = document.getElementById('syncNotSynced');
    const syncMaster = document.getElementById('syncMaster');
    const syncSlave = document.getElementById('syncSlave');

    if (syncSection) {
        if (isCarRadio) {
            syncSection.classList.add('hidden');
        } else {
            syncSection.classList.remove('hidden');
            if (syncStatus && syncStatus.synced) {
                if (syncStatus.role === 'master') {
                    syncNotSynced.classList.add('hidden');
                    syncMaster.classList.remove('hidden');
                    syncSlave.classList.add('hidden');

                    const slaveCount = syncStatus.slaves ? syncStatus.slaves.length : 0;
                    const syncMasterText = document.getElementById('syncMasterText');
                    if (syncMasterText) {
                        syncMasterText.textContent = `Sincronizado (${slaveCount})`;
                    }
                } else if (syncStatus.role === 'slave') {
                    syncNotSynced.classList.add('hidden');
                    syncMaster.classList.add('hidden');
                    syncSlave.classList.remove('hidden');
                }
            } else {
                syncNotSynced.classList.remove('hidden');
                syncMaster.classList.add('hidden');
                syncSlave.classList.add('hidden');
            }
        }
    }
}

function closeSpeakerPanel() {
    document.getElementById('speaker-container').classList.add('hidden');
    speakerId = null;
    isCarRadio = false;
    vehiclePlate = null;

    fetch(`https://${GetParentResourceName()}/closeSpeaker`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });

    showHudBanner();
}

function playMusic(url) {
    const videoId = extractVideoId(url);
    if (!videoId) {
        showNotification('error', 'URL de YouTube no válida');
        return;
    }

    currentUrl = url;
    currentVideoId = videoId;
    isPaused = false;
    isPlaying = true;

    currentProgress = 0;

    updateNowPlaying('Cargando...', videoId);
    updatePlayPauseButton('pause');
    fetch(`https://${GetParentResourceName()}/playMusic`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId, url })
    }).then(resp => resp.json()).then(resp => {
        startProgressAnimation();
    }).catch(err => {
        updateNowPlaying('Error al cargar canción');
        updatePlayPauseButton('play');
        isPaused = false;
        isPlaying = false;
    });
}

function pauseMusic() {
    if (!isPlaying) {
        return;
    }

    isPaused = true;
    isPlaying = false;

    updatePlayPauseButton('play');
    for (const speakerIdKey in audioPlayers) {
        pauseAudioPlayer(speakerIdKey);
    }
    pauseProgressAnimation();
    const equalizer = document.getElementById('equalizer');
    if (equalizer) {
        equalizer.classList.add('paused');
    }
}

function resumeMusic() {
    if (!isPaused || !currentUrl) {
        return;
    }

    isPaused = false;
    isPlaying = true;

    updatePlayPauseButton('pause');
    for (const speakerIdKey in audioPlayers) {
        resumeAudioPlayer(speakerIdKey);
    }
    startProgressAnimation();
    const equalizer = document.getElementById('equalizer');
    if (equalizer) {
        equalizer.classList.remove('paused');
    }
}

function updatePlayPauseButton(state) {
    const playBtn = document.getElementById('playBtn');
    if (!playBtn) return;

    const iconPlay = playBtn.querySelector('.icon-play');
    const iconPause = playBtn.querySelector('.icon-pause');
    const btnText = playBtn.querySelector('.btn-text');

    if (state === 'pause') {
        iconPlay.style.display = 'none';
        iconPause.style.display = 'block';
        btnText.textContent = 'Pausar';
        playBtn.setAttribute('data-state', 'pause');
        playBtn.classList.add('playing');
    } else {
        iconPlay.style.display = 'block';
        iconPause.style.display = 'none';
        btnText.textContent = 'Reproducir';
        playBtn.setAttribute('data-state', 'play');
        playBtn.classList.remove('playing');
    }
}

function playMusicFromUrl(url) {
    return;
}

function stopMusic() {
    if (player && playerReady) {
        player.stopVideo();
    }

    currentUrl = null;
    currentVideoId = null;
    isPlayingPlaylist = false;
    currentSongIndex = -1;
    isPaused = false;
    isPlaying = false;

    updatePlayPauseButton('play');
    stopProgressAnimation();

    updateNowPlaying(null);

    fetch(`https://${GetParentResourceName()}/stopMusic`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId })
    });

    document.querySelectorAll('.song-item').forEach(item => {
        item.classList.remove('playing');
    });
}

function setVolume(volume) {
    currentVolume = volume;
    document.getElementById('volumeValue').textContent = `${volume}%`;

    fetch(`https://${GetParentResourceName()}/setVolume`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId, volume })
    });
}

function removeSpeaker() {
    stopMusic();

    // Primero quitarlo y luego cerrar: closeSpeaker borra currentSpeaker en
    // Lua y removeSpeaker llegaba sin altavoz que quitar.
    fetch(`https://${GetParentResourceName()}/removeSpeaker`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId })
    });

    closeSpeakerPanel();
}

function updateNowPlaying(title, videoId = null) {
    const currentInfo = document.getElementById('currentInfo');
    const equalizer = document.getElementById('equalizer');
    const progressContainer = document.getElementById('progressContainer');

    if (title && title !== 'Cargando...' && title !== 'Error al cargar canción') {
        currentInfo.innerHTML = `<div class="current-title">${escapeHtml(title)}</div>`;

        equalizer.classList.add('playing');
        equalizer.classList.remove('paused');
        progressContainer.style.display = 'block';

        updateHudBanner(title);
    } else if (title === 'Cargando...') {
        currentInfo.innerHTML = `<div class="current-title">${title} <span class="loading"></span></div>`;
        equalizer.classList.remove('playing');
        equalizer.classList.remove('paused');

        updateHudBanner(title);
    } else {
        currentInfo.innerHTML = `<div class="no-music">Sin música</div>`;
        equalizer.classList.remove('playing');
        equalizer.classList.remove('paused');
        progressContainer.style.display = 'none';
        stopProgressAnimation();

        updateHudBanner('Sin música');
        hideHudBanner();
    }
}

function startProgressAnimation() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }

    const progressFill = document.getElementById('progressFill');
    const currentTime = document.getElementById('currentTime');
    const totalTime = document.getElementById('totalTime');

    let progress = currentProgress;
    const duration = currentDuration;
    const interval = 1000;
    totalTime.textContent = formatTime(duration);

    const percentage = (progress / duration) * 100;
    progressFill.style.width = `${percentage}%`;
    currentTime.textContent = formatTime(progress);

    progressInterval = setInterval(() => {
        progress++;
        currentProgress = progress;
        const percentage = (progress / duration) * 100;

        if (percentage >= 100) {
            stopProgressAnimation();
            return;
        }

        progressFill.style.width = `${percentage}%`;
        currentTime.textContent = formatTime(progress);
    }, interval);
}

function pauseProgressAnimation() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }
}

function stopProgressAnimation() {
    if (progressInterval) {
        clearInterval(progressInterval);
        progressInterval = null;
    }

    currentProgress = 0;

    const progressFill = document.getElementById('progressFill');
    const currentTime = document.getElementById('currentTime');

    if (progressFill) progressFill.style.width = '0%';
    if (currentTime) currentTime.textContent = '0:00';
}

function formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

function switchTab(tab) {
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.remove('active');
        if (btn.getAttribute('data-tab') === tab) {
            btn.classList.add('active');
        }
    });

    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.remove('active');
        if (content.id === tab) {
            content.classList.add('active');
        }
    });
}

function updatePlaylists(my, shared) {
    myPlaylists = my || [];
    sharedPlaylists = shared || [];
    renderMyPlaylists();
    renderSharedPlaylists();
}

function renderMyPlaylists() {
    const listContainer = document.getElementById('myPlaylistsList');

    if (myPlaylists.length === 0) {
        listContainer.innerHTML = `
            <div class="empty-state">
                <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M8 12H32M8 20H32M8 28H24M8 36H24" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    <circle cx="36" cy="32" r="8" stroke="currentColor" stroke-width="2"/>
                </svg>
                <p class="title">No tienes listas</p>
                <p class="subtitle">Crea una usando el botón de arriba</p>
            </div>
        `;
        return;
    }

    const sortedPlaylists = [...myPlaylists].sort((a, b) => {
        if (a.isFavorite && !b.isFavorite) return -1;
        if (!a.isFavorite && b.isFavorite) return 1;
        return b.id - a.id;
    });

    listContainer.innerHTML = sortedPlaylists.map(playlist => `
        <div class="playlist-item">
            ${playlist.imageUrl ? `
                <div class="playlist-item-thumbnail">
                    <img src="${escapeHtml(playlist.imageUrl)}" alt="${escapeHtml(playlist.name)}" onerror="this.parentElement.style.display='none'">
                </div>
            ` : ''}
            <div class="playlist-item-content">
                <div class="playlist-item-header">
                    <div class="playlist-item-name">
                        ${playlist.isFavorite ? `
                            <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg" style="display: inline-block; vertical-align: middle; margin-right: calc(0.5vh / var(--ogn-escala, 1)); color: #d81b55;">
                                <path d="M12 2L15.09 8.26L22 9.27L17 14.14L18.18 21.02L12 17.77L5.82 21.02L7 14.14L2 9.27L8.91 8.26L12 2Z" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        ` : !playlist.imageUrl ? `
                            <svg width="16" height="16" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: inline-block; vertical-align: middle; margin-right: calc(0.5vh / var(--ogn-escala, 1)); opacity: 0.8;">
                                <path d="M4 6H12M4 10H12M4 14H8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                                <circle cx="15" cy="13" r="2.5" stroke="currentColor" stroke-width="1.5"/>
                                <path d="M15 10.5V4L17 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        ` : ''}
                        ${escapeHtml(playlist.name)}
                    </div>
                    <div class="playlist-item-badges">
                        <button class="playlist-action-btn-compact ${playlist.isFavorite ? 'favorite active' : 'favorite'}" onclick="toggleFavorite(${playlist.id})">
                            <iconify-icon icon="lucide:star" class="icon ${playlist.isFavorite ? 'active' : ''}"></iconify-icon>
                        </button>
                        <span class="playlist-item-badge ${playlist.isPublic ? 'public' : 'private'}" data-playlist-id="${playlist.id}" data-action="toggle-public" title="Pulsa para hacerla pública o privada">
                            ${playlist.isPublic ? 'PÚBLICA' : 'PRIVADA'}
                        </span>
                    </div>
                </div>
                <div class="playlist-item-info">
                    <div class="playlist-item-count">
                        <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M6 15L6 8M10 15L10 5M14 15L14 10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                        </svg>
                        <span>${playlist.songCount} ${playlist.songCount === 1 ? 'canción' : 'canciones'}</span>
                    </div>
                    ${playlist.likeCount > 0 ? `
                        <div class="playlist-item-count playlist-item-likes">
                            <svg viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                                <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z"/>
                            </svg>
                            <span>${playlist.likeCount} me gusta</span>
                        </div>
                    ` : ''}
                </div>
                <div class="playlist-item-actions">
                    <button class="playlist-action-btn" onclick="openPlaylist(${playlist.id}, '${escapeHtml(playlist.name)}', ${playlist.songCount})" title="Abrir lista">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 5H3m7 7H3m7 7H3m12-6.997a1 1 0 0 1 1.517-.859l4.997 2.997a1 1 0 0 1 0 1.718l-4.997 2.997a1 1 0 0 1-1.517-.86z" />
                        </svg>
                        Abrir
                    </button>
                    <button class="playlist-action-btn" onclick="renamePlaylist(${playlist.id}, '${escapeHtml(playlist.name)}', '${escapeHtml(playlist.imageUrl || '')}')" title="Renombrar">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" />
                        </svg>
                    </button>
                    <button class="playlist-action-btn" onclick="sharePlaylist(${playlist.id})" title="Compartir">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 2v13m4-9l-4-4l-4 4m-4 6v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8" />
                        </svg>
                    </button>
                    <button class="playlist-action-btn danger" onclick="deletePlaylist(${playlist.id}, '${escapeHtml(playlist.name)}')" title="Eliminar">
                        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
                            <path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 11v6m4-6v6m5-11v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M3 6h18M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                        </svg>
                    </button>
                </div>
            </div>
        </div>
    `).join('');
}

function renderSharedPlaylists() {
    const listContainer = document.getElementById('sharedPlaylistsList');

    if (sharedPlaylists.length === 0) {
        listContainer.innerHTML = `
            <div class="empty-state">
                <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M24 36C30.6274 36 36 30.6274 36 24C36 17.3726 30.6274 12 24 12C17.3726 12 12 17.3726 12 24C12 30.6274 17.3726 36 24 36Z" stroke="currentColor" stroke-width="2"/>
                    <path d="M24 8V12M24 36V40M8 24H12M36 24H40" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <p>Sin listas compartidas</p>
            </div>
        `;
        return;
    }

    listContainer.innerHTML = sharedPlaylists.map(playlist => `
        <div class="playlist-item shared" onclick="openPlaylist(${playlist.id}, '${escapeHtml(playlist.name)}', ${playlist.songCount}, true)">
            <div class="shared-playlist-header">
                <div class="playlist-item-name">${escapeHtml(playlist.name)}</div>
                <span class="playlist-item-badge">COMPARTIDA</span>
            </div>
            <div class="shared-playlist-info">
                <div class="playlist-item-count">
                    <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M6 15L6 8M10 15L10 5M14 15L14 10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                    <span>${playlist.songCount} ${playlist.songCount === 1 ? 'canción' : 'canciones'}</span>
                </div>
            </div>
        </div>
    `).join('');
}

function openPlaylist(playlistId, playlistName, songCount, isShared = false) {
    currentPlaylist = { id: playlistId, name: playlistName, songCount, isShared };

    const playlistNameEl = document.getElementById('currentPlaylistName');
    const playlistCountEl = document.getElementById('currentPlaylistCount');

    if (!playlistNameEl || !playlistCountEl) {
        return;
    }

    playlistNameEl.textContent = playlistName;
    playlistCountEl.textContent = `${songCount} ${songCount === 1 ? 'canción' : 'canciones'}`;

    fetch(`https://${GetParentResourceName()}/getPlaylistSongs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.songs) {
            currentSongs = resp.songs;
            renderSongs();
            showSongsView();
        }
    }).catch(err => {
        showNotification('error', 'Error al cargar la lista');
    });
}

function renderSongs() {
    const songsList = document.getElementById('songsList');

    if (currentSongs.length === 0) {
        songsList.innerHTML = `
            <div class="empty-state">
                <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <circle cx="24" cy="24" r="18" stroke="currentColor" stroke-width="2"/>
                    <path d="M24 16V24L30 28" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <p>No hay canciones en esta lista</p>
            </div>
        `;
        return;
    }

    songsList.innerHTML = currentSongs.map((song, index) => `
        <div class="song-item" data-song-id="${song.id}" data-index="${index}">
            <div class="song-item-info">
                <div class="song-item-number">${index + 1}</div>
                <div class="song-item-title">${escapeHtml(song.title)}</div>
            </div>
            <div class="song-item-actions">
                <button class="icon-btn-sm play-btn" onclick="playSong(${index})">
                    <iconify-icon icon="lucide:play" class="icon"></iconify-icon>
                </button>
                ${!currentPlaylist.isShared ? `
                <button class="icon-btn-sm danger" onclick="removeSongFromPlaylist(${song.id})">
                    <iconify-icon icon="lucide:trash-2" class="icon"></iconify-icon>
                </button>
                ` : ''}
            </div>
        </div>
    `).join('');
}

function playSong(index) {
    if (index < 0 || index >= currentSongs.length) return;

    const song = currentSongs[index];
    currentSongIndex = index;
    isPlayingPlaylist = true;

    playMusic(song.url);

    document.querySelectorAll('.song-item').forEach((item, i) => {
        item.classList.toggle('playing', i === index);
    });
}

function playAllSongs() {
    if (currentSongs.length === 0) {
        showNotification('error', 'Sin canciones para reproducir');
        return;
    }

    if (isShuffleEnabled) {
        currentSongs = shuffleArray([...currentSongs]);
        renderSongs();
    }

    playSong(0);
    showNotification('success', 'Reproduciendo lista');
}

function playNextSong() {
    if (!isPlayingPlaylist || currentSongs.length === 0) return;

    let nextIndex = currentSongIndex + 1;

    if (nextIndex >= currentSongs.length) {
        nextIndex = 0;
    }

    playSong(nextIndex);
}

function removeSongFromPlaylist(songId) {
    fetch(`https://${GetParentResourceName()}/removeSongFromPlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ songId })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            currentSongs = currentSongs.filter(s => s.id !== songId);
            currentPlaylist.songCount--;
            document.getElementById('currentPlaylistCount').textContent = `${currentPlaylist.songCount} canciones`;
            renderSongs();
            showNotification('success', 'Canción eliminada');
            refreshPlaylists();
        } else {
            showNotification('error', resp.message || 'Error al eliminar canción');
        }
    }).catch(err => {
        showNotification('error', 'Error al eliminar canción');
    });
}

function showSongsView() {
    const songsView = document.getElementById('songsView');
    const myPlaylistsTab = document.getElementById('myPlaylistsTab');
    const sharedPlaylistsTab = document.getElementById('sharedPlaylistsTab');
    const playlistSection = document.querySelector('.playlist-section');
    const playlistContainer = document.querySelector('.playlist-container');

    if (songsView) {
        songsView.classList.remove('hidden');
        songsView.classList.add('active');
    }

    if (myPlaylistsTab) {
        myPlaylistsTab.style.display = 'none';
    }

    if (sharedPlaylistsTab) {
        sharedPlaylistsTab.style.display = 'none';
    }

    if (playlistSection) {
        playlistSection.classList.add('viewing-songs');
    }

    if (playlistContainer) {
        playlistContainer.classList.add('viewing-songs');
    }
}

function closeSongsView() {
    const songsView = document.getElementById('songsView');
    const myPlaylistsTab = document.getElementById('myPlaylistsTab');
    const sharedPlaylistsTab = document.getElementById('sharedPlaylistsTab');
    const playlistSection = document.querySelector('.playlist-section');
    const playlistContainer = document.querySelector('.playlist-container');

    if (songsView) {
        songsView.classList.add('hidden');
        songsView.classList.remove('active');
    }

    const activeTab = document.querySelector('.playlist-tab.active');
    if (activeTab) {
        const tabName = activeTab.getAttribute('data-tab');
        if (tabName === 'my' && myPlaylistsTab) {
            myPlaylistsTab.style.display = 'block';
        } else if (tabName === 'shared' && sharedPlaylistsTab) {
            sharedPlaylistsTab.style.display = 'block';
        }
    } else {
        if (myPlaylistsTab) {
            myPlaylistsTab.style.display = 'block';
        }
    }

    if (playlistSection) {
        playlistSection.classList.remove('viewing-songs');
    }

    if (playlistContainer) {
        playlistContainer.classList.remove('viewing-songs');
    }

    currentPlaylist = null;
    currentSongs = [];
    currentSongIndex = -1;
    isPlayingPlaylist = false;
}

function openCreatePlaylistModal() {
    modalAction = 'create';
    modalData = null;
    const modalTitle = document.getElementById('modalTitle');
    const playlistNameInput = document.getElementById('playlistNameInput');
    const playlistImageInput = document.getElementById('playlistImageInput');
    const imagePreviewContainer = document.getElementById('imagePreviewContainer');

    if (!modalTitle) {
        return;
    }
    if (!playlistNameInput) {
        return;
    }

    modalTitle.textContent = 'Crear Lista';
    playlistNameInput.value = '';
    playlistNameInput.placeholder = 'Nombre de la lista';

    if (playlistImageInput) {
        playlistImageInput.value = '';
        playlistImageInput.placeholder = 'URL de imagen (opcional)';
    }

    if (imagePreviewContainer) {
        imagePreviewContainer.style.display = 'none';
    }

    showModal('playlistNameModal');
}

function openRenamePlaylistModal(playlistId, currentName, currentImageUrl) {
    modalAction = 'rename';
    modalData = { playlistId };
    const playlistImageInput = document.getElementById('playlistImageInput');
    const imagePreview = document.getElementById('imagePreview');
    const imagePreviewContainer = document.getElementById('imagePreviewContainer');

    document.getElementById('modalTitle').textContent = 'Editar Lista';
    document.getElementById('playlistNameInput').value = currentName;
    document.getElementById('playlistNameInput').placeholder = 'Introduce nuevo nombre';

    if (playlistImageInput) {
        playlistImageInput.value = currentImageUrl || '';
    }

    if (currentImageUrl && imagePreview && imagePreviewContainer) {
        imagePreview.src = currentImageUrl;
        imagePreviewContainer.style.display = 'block';
    } else if (imagePreviewContainer) {
        imagePreviewContainer.style.display = 'none';
    }

    showModal('playlistNameModal');
}

function openAddToPlaylistModal() {
    if (myPlaylists.length === 0) {
        showNotification('error', 'Crea una lista primero');
        return;
    }

    const playlistsSelect = document.getElementById('playlistsSelect');
    if (!playlistsSelect) {
        return;
    }

    playlistsSelect.innerHTML = myPlaylists.map(playlist => `
        <div class="playlist-select-item" onclick="addCurrentSongToPlaylist(${playlist.id})">
            <div class="playlist-select-item-name">${escapeHtml(playlist.name)}</div>
            <div class="playlist-select-item-count">${playlist.songCount} ${playlist.songCount === 1 ? 'canción' : 'canciones'}</div>
        </div>
    `).join('');

    showModal('addToPlaylistModal');
}

function openSharePlaylistModal(playlistId) {
    modalData = { playlistId };
    document.getElementById('playerIdInput').value = '';
    showModal('sharePlaylistModal');
}

function showModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
        modal.classList.remove('hidden');
    }
}

function closeModal() {
    document.querySelectorAll('.modal').forEach(modal => modal.classList.add('hidden'));
    modalAction = null;
    modalData = null;
}

function confirmPlaylistNameAction() {
    const name = document.getElementById('playlistNameInput').value.trim();
    const imageUrl = document.getElementById('playlistImageInput').value.trim();

    if (!name) {
        showNotification('error', 'Introduce un nombre');
        return;
    }

    if (modalAction === 'create') {
        createPlaylist(name, imageUrl);
    } else if (modalAction === 'rename') {
        renamePlaylistConfirm(modalData.playlistId, name, imageUrl);
    }
}

function confirmSharePlaylist() {
    const playerId = parseInt(document.getElementById('playerIdInput').value);

    if (!playerId || playerId < 1) {
        showNotification('error', 'ID de jugador no válido');
        return;
    }

    sharePlaylistConfirm(modalData.playlistId, playerId);
}

function createPlaylist(name, imageUrl) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    fetch(`https://${GetParentResourceName()}/createPlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, imageUrl }),
        signal: controller.signal
    }).then(resp => {
        clearTimeout(timeoutId);
        if (!resp.ok) {
            throw new Error('Network response was not ok');
        }
        return resp.text();
    }).then(text => {
        if (!text || text.trim() === '') {
            return { success: false, message: 'Base de datos sin configurar. Mira la consola del servidor.' };
        }
        return JSON.parse(text);
    }).then(resp => {
        if (resp && resp.success) {
            showNotification('success', 'Lista creada');
            closeModal();
            refreshPlaylists();
        } else {
            showNotification('error', resp.message || 'Error de base de datos');
        }
    }).catch(err => {
        clearTimeout(timeoutId);
        showNotification('error', 'Función de listas no disponible');
        closeModal();
    });
}

function renamePlaylist(playlistId, currentName, currentImageUrl) {
    openRenamePlaylistModal(playlistId, currentName, currentImageUrl);
}

function renamePlaylistConfirm(playlistId, newName, imageUrl) {
    fetch(`https://${GetParentResourceName()}/renamePlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId, newName, imageUrl })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            showNotification('success', 'Lista renombrada');
            closeModal();
            refreshPlaylists();
        } else {
            showNotification('error', resp.message || 'Error al renombrar');
        }
    }).catch(err => {
        showNotification('error', 'Error al renombrar');
    });
}

function deletePlaylist(playlistId, name) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 5000);

    fetch(`https://${GetParentResourceName()}/deletePlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId }),
        signal: controller.signal
    })
        .then(resp => {
            clearTimeout(timeoutId);
            if (!resp.ok) {
                throw new Error(`Server returned error: ${resp.status}`);
            }
            return resp.json();
        })
        .then(resp => {
            if (resp && resp.success) {
                showNotification('success', 'Lista eliminada');
                refreshPlaylists();
            } else {
                showNotification('error', resp.message || 'Error al eliminar lista');
            }
        })
        .catch(err => {
            clearTimeout(timeoutId);
            showNotification('error', err.message || 'Error al eliminar lista');
        });
}

function sharePlaylist(playlistId) {
    openSharePlaylistModal(playlistId);
}

function sharePlaylistConfirm(playlistId, targetPlayerId) {
    fetch(`https://${GetParentResourceName()}/sharePlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId, targetPlayerId })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            showNotification('success', 'Lista compartida');
            closeModal();
        } else {
            showNotification('error', resp.message || 'Error al compartir lista');
        }
    }).catch(err => {
        showNotification('error', 'Error al compartir lista');
    });
}

function addCurrentSongToPlaylist(playlistId) {
    if (!currentUrl) {
        showNotification('error', 'Sin música reproduciéndose');
        closeModal();
        return;
    }

    let currentTitle = 'Loading...';
    const titleElement = document.querySelector('.current-title');
    if (titleElement && titleElement.textContent) {
        currentTitle = titleElement.textContent.trim();
    }

    if (currentTitle === 'Loading...' && currentVideoId) {
        currentTitle = `Loading... (${currentVideoId})`;
    }

    fetch(`https://${GetParentResourceName()}/addSongToPlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId, url: currentUrl, title: currentTitle })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            showNotification('success', 'Canción añadida a la lista');
            closeModal();
            refreshPlaylists();
        } else {
            showNotification('error', resp.message || 'Error al añadir canción');
        }
    }).catch(err => {
        showNotification('error', 'Error al añadir canción');
        closeModal();
    });
}

function refreshPlaylists() {
    fetch(`https://${GetParentResourceName()}/getPlaylists`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    }).then(resp => {
        if (!resp.ok) {
            throw new Error('Network response was not ok');
        }
        return resp.text();
    }).then(text => {
        if (!text || text.trim() === '') {
            return { myPlaylists: [], sharedPlaylists: [] };
        }
        return JSON.parse(text);
    }).then(resp => {
        if (resp && resp.myPlaylists && resp.sharedPlaylists) {
            updatePlaylists(resp.myPlaylists, resp.sharedPlaylists);
        } else {
            updatePlaylists([], []);
        }
    }).catch(err => {
        updatePlaylists([], []);
    });
}

function isValidYouTubeUrl(url) {
    const pattern = /^(https?:\/\/)?(www\.)?(youtube\.com|youtu\.be)\/.+$/;
    return pattern.test(url);
}

function extractVideoId(url) {
    const patterns = [
        /(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?#]+)/,
        /youtube\.com\/embed\/([^&\n?#]+)/,
        /youtube\.com\/v\/([^&\n?#]+)/
    ];

    for (const pattern of patterns) {
        const match = url.match(pattern);
        if (match && match[1]) {
            return match[1];
        }
    }

    return null;
}

let allPublicPlaylists = [];
let filteredPlaylists = [];

function openExploreModal() {
    const modal = document.getElementById('explorePlaylistsModal');
    if (modal) {
        modal.classList.remove('hidden');
        fetchPublicPlaylists();
    }
}

function closeExploreModal() {
    const modal = document.getElementById('explorePlaylistsModal');
    if (modal) {
        modal.classList.add('hidden');
    }
}

function fetchPublicPlaylists() {
    const container = document.getElementById('explorePlaylists');

    container.innerHTML = `
        <div class="explore-loading">
            <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="24" cy="24" r="18" stroke="currentColor" stroke-width="2" opacity="0.3"/>
                <path d="M24 6C14.059 6 6 14.059 6 24" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                    <animateTransform attributeName="transform" type="rotate" from="0 24 24" to="360 24 24" dur="1s" repeatCount="indefinite"/>
                </path>
            </svg>
            <p>Cargando listas públicas...</p>
        </div>
    `;

    fetch(`https://${GetParentResourceName()}/getPublicPlaylists`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
        .then(resp => resp.json())
        .then(resp => {
            if (resp && resp.playlists) {
                allPublicPlaylists = resp.playlists;
                filteredPlaylists = [...allPublicPlaylists];
                renderExplorePlaylists();
            } else {
                showExploreEmpty('No se encontraron listas públicas');
            }
        })
        .catch(err => {
            showExploreEmpty('Error al cargar listas');
        });
}

function renderExplorePlaylists() {
    const container = document.getElementById('explorePlaylists');

    if (filteredPlaylists.length === 0) {
        showExploreEmpty('Ninguna lista coincide con tu búsqueda');
        return;
    }

    container.innerHTML = `
        <div class="explore-playlists-grid">
            ${filteredPlaylists.map(playlist => `
                <div class="explore-playlist-card">
                    <!-- Thumbnail -->
                    <div class="explore-card-thumbnail">
                        ${playlist.imageUrl ? `
                            <img src="${escapeHtml(playlist.imageUrl)}" alt="${escapeHtml(playlist.name)}" onerror="this.style.display='none'; this.nextElementSibling.style.display='flex';">
                            <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg" style="display: none; width: calc(8vh / var(--ogn-escala, 1)); height: calc(8vh / var(--ogn-escala, 1)); stroke: var(--text-secondary); opacity: 0.2;">
                                <path d="M4 6H12M4 10H12M4 14H8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                                <circle cx="15" cy="13" r="2.5" stroke="currentColor" stroke-width="1.5"/>
                                <path d="M15 10.5V4L17 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        ` : `
                            <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                                <path d="M4 6H12M4 10H12M4 14H8" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
                                <circle cx="15" cy="13" r="2.5" stroke="currentColor" stroke-width="1.5"/>
                                <path d="M15 10.5V4L17 5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        `}
                    </div>
                    
                    <div class="explore-card-content">
                        <div class="explore-card-title">${escapeHtml(playlist.name)}</div>
                        
                        <div class="explore-card-creator">
                            Por <strong>${escapeHtml(playlist.createdByName || 'Desconocido')}</strong>
                        </div>
                        
                        <div class="explore-card-stats">
                            <div class="explore-stat likes" title="Me gusta">
                                <svg viewBox="0 0 20 20" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z"/>
                                </svg>
                                ${playlist.likeCount || 0}
                            </div>
                            <div class="explore-stat songs" title="Canciones">
                                <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M6 15L6 8M10 15L10 5M14 15L14 10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                                </svg>
                                ${playlist.songCount}
                            </div>
                            ${playlist.importCount > 0 ? `
                                <div class="explore-stat imports" title="Importaciones">
                                    <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                                        <path d="M10 3V13M10 13L6 9M10 13L14 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                    </svg>
                                    ${playlist.importCount}
                                </div>
                            ` : ''}
                        </div>
                        
                        <div class="explore-card-actions">
                            <button class="explore-action-btn ${playlist.isLiked ? 'liked' : ''}" onclick="likePlaylist(${playlist.id})" title="${playlist.isLiked ? 'Quitar me gusta' : 'Me gusta'}">
                                <svg viewBox="0 0 20 20" fill="${playlist.isLiked ? 'currentColor' : 'none'}" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M3.172 5.172a4 4 0 015.656 0L10 6.343l1.172-1.171a4 4 0 115.656 5.656L10 17.657l-6.828-6.829a4 4 0 010-5.656z" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                                ${playlist.isLiked ? 'TE GUSTA' : 'ME GUSTA'}
                            </button>
                            <button class="explore-action-btn primary" onclick="importPublicPlaylist(${playlist.id}, '${escapeHtml(playlist.name)}')" title="Importar Lista">
                                <svg viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
                                    <path d="M10 3V13M10 13L6 9M10 13L14 9M3 17H17" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                                </svg>
                                IMPORTAR
                            </button>
                        </div>
                    </div>
                </div>
            `).join('')}
        </div>
    `;
}

function showExploreEmpty(message) {
    const container = document.getElementById('explorePlaylists');
    container.innerHTML = `
        <div class="explore-empty">
            <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                <circle cx="24" cy="24" r="18" stroke="currentColor" stroke-width="2"/>
                <path d="M24 16V26M24 30H24.01" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
            </svg>
            <p>${message}</p>
        </div>
    `;
}

function filterExplorePlaylists(searchTerm) {
    if (!searchTerm || searchTerm.trim() === '') {
        filteredPlaylists = [...allPublicPlaylists];
    } else {
        const term = searchTerm.toLowerCase();
        filteredPlaylists = allPublicPlaylists.filter(playlist =>
            playlist.name.toLowerCase().includes(term) ||
            (playlist.createdByName && playlist.createdByName.toLowerCase().includes(term))
        );
    }

    const sortSelect = document.getElementById('exploreSortSelect');
    if (sortSelect) {
        sortExplorePlaylists(sortSelect.value);
    } else {
        renderExplorePlaylists();
    }
}

function sortExplorePlaylists(sortType) {
    switch (sortType) {
        case 'popular':
            filteredPlaylists.sort((a, b) => b.importCount - a.importCount);
            break;
        case 'songs':
            filteredPlaylists.sort((a, b) => b.songCount - a.songCount);
            break;
        case 'recent':
        default:
            filteredPlaylists.sort((a, b) => b.id - a.id);
            break;
    }

    renderExplorePlaylists();
}

function previewPublicPlaylist(playlistId) {
    fetch(`https://${GetParentResourceName()}/getPlaylistSongs`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    })
        .then(resp => resp.json())
        .then(songs => {
            if (songs && songs.length > 0) {
                const playlist = filteredPlaylists.find(p => p.id === playlistId);
                const songsList = songs.map((song, index) =>
                    `${index + 1}. ${escapeHtml(song.title)}`
                ).join('\n');

                showNotification('success', `"${playlist.name}" contiene ${songs.length} canciones`);
            } else {
                showNotification('error', 'Esta lista está vacía');
            }
        })
        .catch(err => {
            showNotification('error', 'Error al cargar la lista');
        });
}

function importPublicPlaylist(playlistId, playlistName) {

    fetch(`https://${GetParentResourceName()}/importPlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    })
        .then(resp => resp.json())
        .then(resp => {
            if (resp && resp.success) {
                showNotification('success', `Lista "${playlistName}" importada correctamente!`);
                const playlist = filteredPlaylists.find(p => p.id === playlistId);
                if (playlist) {
                    playlist.importCount++;
                    renderExplorePlaylists();
                }
                refreshPlaylists();
            } else {
                showNotification('error', resp.message || 'Error al importar lista');
            }
        })
        .catch(err => {
            showNotification('error', 'Error al importar lista');
        });
}

function likePlaylist(playlistId) {

    fetch(`https://${GetParentResourceName()}/likePlaylist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    })
        .then(resp => resp.json())
        .then(resp => {
            if (resp && resp.success) {
                const playlist = filteredPlaylists.find(p => p.id === playlistId);
                if (playlist) {
                    if (resp.liked) {
                        playlist.likeCount++;
                        playlist.isLiked = true;
                        showNotification('success', '¡Te gusta esta lista!');
                    } else {
                        playlist.likeCount--;
                        playlist.isLiked = false;
                        showNotification('success', 'Ya no te gusta esta lista');
                    }
                    renderExplorePlaylists();
                }
            } else {
                showNotification('error', resp.message || 'Error al dar me gusta');
            }
        })
        .catch(err => {
            showNotification('error', 'Error al dar me gusta');
        });
}

function toggleFavorite(playlistId) {

    fetch(`https://${GetParentResourceName()}/toggleFavorite`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    })
        .then(resp => resp.json())
        .then(resp => {
            if (resp && resp.success) {
                const playlist = myPlaylists.find(p => p.id === playlistId);
                if (playlist) {
                    playlist.isFavorite = resp.isFavorite;
                    if (resp.isFavorite) {
                        showNotification('success', 'Añadido a favoritos');
                    } else {
                        showNotification('success', 'Eliminado de favoritos');
                    }
                    renderMyPlaylists();
                }
            } else {
                showNotification('error', resp.message || 'Error al actualizar favorito');
            }
        })
        .catch(err => {
            showNotification('error', 'Error al actualizar favorito');
        });
}

function togglePublic(playlistId) {

    const playlist = myPlaylists.find(p => p.id === playlistId);

    fetch(`https://${GetParentResourceName()}/togglePublic`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ playlistId })
    })
        .then(resp => {
            return resp.json();
        })
        .then(resp => {

            if (resp && resp.success) {
                if (resp.isPublic) {
                    showNotification('success', 'La lista ahora es pública');
                } else {
                    showNotification('success', 'La lista ahora es privada');
                }

                refreshPlaylists();
            } else {
                showNotification('error', resp.message || 'Error al cambiar visibilidad');
            }
        })
        .catch(err => {
            showNotification('error', 'Error al cambiar visibilidad');
        });
}

window.previewPublicPlaylist = previewPublicPlaylist;
window.importPublicPlaylist = importPublicPlaylist;
window.likePlaylist = likePlaylist;
window.toggleFavorite = toggleFavorite;
window.togglePublic = togglePublic;

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function shuffleArray(array) {
    const newArray = [...array];
    for (let i = newArray.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [newArray[i], newArray[j]] = [newArray[j], newArray[i]];
    }
    return newArray;
}

function showNotification(type, message) {
    fetch(`https://${GetParentResourceName()}/showNotification`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type, message })
    });
}

function GetParentResourceName() {
    const hostname = window.location.hostname;

    if (hostname.startsWith('cfx-nui-')) {
        const resourceName = hostname.replace('cfx-nui-', '');
        return resourceName;
    }

    const resourceName = hostname === '' ? 'origen_speaker' : hostname.split('.')[0];
    return resourceName;
}

let syncGroups = {};
let timeSyncInterval = null;

function startTimeSync() {
    if (timeSyncInterval) return;

    timeSyncInterval = setInterval(() => {
        const groups = {};

        for (const [speakerId, playerData] of Object.entries(audioPlayers)) {
            if (playerData.ready && playerData.videoId) {
                if (!groups[playerData.videoId]) {
                    groups[playerData.videoId] = [];
                }
                groups[playerData.videoId].push({ speakerId, playerData });
            }
        }

        for (const [videoId, playerGroup] of Object.entries(groups)) {
            if (playerGroup.length > 1) {
                let masterTime = 0;
                let masterPlayer = null;

                for (const { speakerId, playerData } of playerGroup) {
                    try {
                        const currentTime = playerData.player.getCurrentTime();
                        if (currentTime > masterTime) {
                            masterTime = currentTime;
                            masterPlayer = speakerId;
                        }
                    } catch (e) {
                    }
                }

                if (masterPlayer && masterTime > 0) {
                    let syncedCount = 0;

                    for (const { speakerId, playerData } of playerGroup) {
                        if (speakerId !== masterPlayer) {
                            try {
                                const currentTime = playerData.player.getCurrentTime();
                                const timeDiff = Math.abs(currentTime - masterTime);

                                if (timeDiff > TIME_SYNC_THRESHOLD) {
                                    playerData.player.seekTo(masterTime, true);
                                    syncedCount++;
                                }
                            } catch (e) {
                            }
                        }
                    }

                    if (syncedCount > 0) {
                    }
                }
            }
        }
    }, 0);
}

function stopTimeSync() {
    if (timeSyncInterval) {
        clearInterval(timeSyncInterval);
        timeSyncInterval = null;
    }
}

function createAudioPlayer(speakerId, videoId, volume, startSeconds = 0) {

    if (audioPlayers[speakerId]) {
        destroyAudioPlayer(speakerId);
    }

    const playerDiv = document.createElement('div');
    playerDiv.id = `audio-player-${speakerId}`;
    playerDiv.style.display = 'none';
    document.body.appendChild(playerDiv);

    const entrada = {
        div: playerDiv,
        videoId: videoId,
        baseVolume: volume,
        currentVolume: volume,
        player: null,
        ready: false
    };
    audioPlayers[speakerId] = entrada;

    /* ¿Sigue siendo este el reproductor de ese altavoz? Entre crearlo y que
       YouTube conteste puede haberse quitado o sustituido por otra canción;
       sin esta comprobación, el viejo arrancaba igual y sonaban dos. */
    const vigente = () => audioPlayers[speakerId] === entrada;

    /* La radio del coche pasa de canción en el servidor y necesita saber
       cuánto dura el vídeo. Se cuenta una vez; en onReady a veces aún da 0,
       así que se reintenta cuando empieza a sonar. */
    let duracionContada = false;
    const contarDuracion = (yt) => {
        if (duracionContada || !String(speakerId).startsWith('vehicle_')) return;
        let duracion = 0;
        try { duracion = yt.getDuration(); } catch (e) { }
        if (!(duracion > 0)) return;
        duracionContada = true;
        fetch(`https://${GetParentResourceName()}/soundDuration`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ speakerId: speakerId, videoId: videoId, duracion: duracion })
        }).catch(() => { });
    };

    // Si la API de YouTube aun no ha cargado (recien arrancado el recurso) se
    // reintenta un rato; antes se rendia a la primera y ese coche no sonaba.
    let intentos = 0;
    const arrancar = () => {
        if (!vigente()) return;
        if (typeof YT === 'undefined' || typeof YT.Player !== 'function') {
            if (++intentos < 50) setTimeout(arrancar, 200);
            return;
        }
        {
            try {
                const ytPlayer = new YT.Player(playerDiv, {
                    height: '0',
                    width: '0',
                    videoId: videoId,
                    playerVars: {
                        'autoplay': 1,
                        'controls': 0,
                        'showinfo': 0,
                        'modestbranding': 1,
                        'loop': 1,
                        'playlist': videoId
                    },
                    events: {
                        'onReady': function (event) {
                            if (!vigente()) {
                                try { event.target.destroy(); } catch (e) { }
                                return;
                            }
                            entrada.player = event.target;
                            entrada.ready = true;
                            event.target.setVolume(entrada.currentVolume || 0);
                            if (startSeconds > 1) {
                                // El vídeo se repite: pasado su final, se sigue por la vuelta que toque.
                                let destino = startSeconds;
                                try {
                                    const duracion = event.target.getDuration();
                                    if (duracion > 0) destino = startSeconds % duracion;
                                } catch (e) { }
                                if (destino > 1) event.target.seekTo(destino, true);
                            }

                            startTimeSync();

                            contarDuracion(event.target);

                            try {
                                const videoData = event.target.getVideoData();
                                const title = videoData && videoData.title;
                                if (!title) return;

                                entrada.title = title;

                                fetch(`https://${GetParentResourceName()}/updateSongTitle`, {
                                    method: 'POST',
                                    headers: { 'Content-Type': 'application/json' },
                                    body: JSON.stringify({
                                        speakerId: speakerId,
                                        title: title,
                                        videoId: videoId
                                    })
                                }).catch(err => {
                                });
                            } catch (e) {
                            }
                        },
                        /* YouTube no deja reproducirlo: 2 id no válido, 5 fallo del
                           reproductor, 100 no existe o es privado, 101/150 su autor
                           no deja insertarlo, 153 falta la cabecera de origen. Se
                           quita este reproductor y se cuenta al Lua, que avisa por
                           el servidor a quien lo puso. */
                        'onError': function (event) {
                            if (!vigente()) return;
                            const codigo = event ? event.data : null;
                            destroyAudioPlayer(speakerId);
                            fetch(`https://${GetParentResourceName()}/soundError`, {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ speakerId: speakerId, videoId: videoId, codigo: codigo })
                            }).catch(() => { });
                        },
                        'onStateChange': function (event) {
                            if (event.data === YT.PlayerState.PLAYING && vigente()) {
                                contarDuracion(event.target);
                            }
                            if (event.data === YT.PlayerState.ENDED && isPlayingPlaylist) {
                                if (speakerId === currentSpeaker || speakerId === currentVehicleRadio) {
                                    playNextSong();
                                }
                            }
                        }
                    }
                });
            } catch (e) {
            }
        }
    };
    setTimeout(arrancar, 100);
}

function destroyAudioPlayer(speakerId) {
    if (audioPlayers[speakerId]) {
        const playerData = audioPlayers[speakerId];

        if (playerData.player && playerData.ready) {
            try {
                playerData.player.stopVideo();
                playerData.player.destroy();
            } catch (e) {
            }
        }

        // The YT API replaces the original div with an iframe, so playerData.div might be detached.
        // We MUST find the element by ID and remove it.
        const elId = `audio-player-${speakerId}`;
        const domEl = document.getElementById(elId);
        if (domEl && domEl.parentNode) {
            domEl.parentNode.removeChild(domEl);
        } else if (playerData.div && playerData.div.parentNode) {
            playerData.div.parentNode.removeChild(playerData.div);
        }

        delete audioPlayers[speakerId];

        if (Object.keys(audioPlayers).length === 0) {
            stopTimeSync();
        }
    }
}

function set3DVolume(speakerId, volume) {
    if (audioPlayers[speakerId]) {
        const playerData = audioPlayers[speakerId];
        const ytVolume = Math.max(0, Math.min(100, volume * 100));
        playerData.currentVolume = ytVolume;

        if (playerData.ready) {
            try {
                playerData.player.setVolume(ytVolume);
            } catch (e) {
            }
        }
    }
}

function updateAudioPlayerVolume(speakerId, volume) {
    if (audioPlayers[speakerId]) {
        audioPlayers[speakerId].baseVolume = volume;
    }
}

function pauseAudioPlayer(speakerId) {
    if (audioPlayers[speakerId] && audioPlayers[speakerId].ready) {
        try {
            audioPlayers[speakerId].player.pauseVideo();
        } catch (e) {
        }
    }
}

function resumeAudioPlayer(speakerId) {
    if (audioPlayers[speakerId] && audioPlayers[speakerId].ready) {
        try {
            audioPlayers[speakerId].player.playVideo();
        } catch (e) {
        }
    }
}

let selectedSyncSpeakers = [];
let currentMasterSpeaker = null;

function updateSyncStatus() {
    if (!speakerId) return;


    fetch(`https://${GetParentResourceName()}/getSyncStatus`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId: speakerId })
    }).then(resp => resp.json()).then(status => {
        const syncSection = document.getElementById('syncSection');
        const syncNotSynced = document.getElementById('syncNotSynced');
        const syncMaster = document.getElementById('syncMaster');
        const syncSlave = document.getElementById('syncSlave');
        const content = document.querySelector('.content');

        if (!syncSection) return;

        if (status.synced && status.role === 'master') {
            syncNotSynced.classList.add('hidden');
            syncMaster.classList.remove('hidden');
            syncSlave.classList.add('hidden');

            const slaveCount = status.slaves ? status.slaves.length : 0;
            const syncMasterText = document.getElementById('syncMasterText');
            if (syncMasterText) {
                syncMasterText.textContent = `Sincronizado (${slaveCount})`;
            }

            if (content) content.classList.remove('controls-disabled');

        } else if (status.synced && status.role === 'slave') {
            syncNotSynced.classList.add('hidden');
            syncMaster.classList.add('hidden');
            syncSlave.classList.remove('hidden');

            if (content) content.classList.add('controls-disabled');

        } else {
            syncNotSynced.classList.remove('hidden');
            syncMaster.classList.add('hidden');
            syncSlave.classList.add('hidden');

            if (content) content.classList.remove('controls-disabled');
        }
    });
}

function openSyncModal() {
    if (!speakerId) return;

    currentMasterSpeaker = speakerId;
    selectedSyncSpeakers = [];

    fetch(`https://${GetParentResourceName()}/getNearbySpeakers`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ speakerId: speakerId })
    }).then(resp => resp.json()).then(resp => {
        const modal = document.getElementById('syncSpeakersModal');
        const speakersList = document.getElementById('syncSpeakersList');

        if (!modal || !speakersList) return;

        const speakers = resp.speakers || [];

        if (speakers.length === 0) {
            speakersList.innerHTML = `
                <div class="sync-empty-state">
                    <svg viewBox="0 0 48 48" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <circle cx="24" cy="24" r="18" stroke="currentColor" stroke-width="2"/>
                        <path d="M24 16V24L30 28" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                    <p>No hay altavoces cerca</p>
                </div>
            `;
        } else {
            speakersList.innerHTML = speakers.map(speaker => `
                <div class="sync-speaker-item" data-speaker-id="${speaker.id}" onclick="toggleSyncSpeaker('${speaker.id}')">
                    <div class="sync-speaker-checkbox"></div>
                    <div class="sync-speaker-info">
                        <div class="sync-speaker-name">Altavoz #${speaker.id.split('_')[1] || '?'}</div>
                        <div class="sync-speaker-distance">${speaker.distance}m</div>
                    </div>
                </div>
            `).join('');
        }

        modal.classList.remove('hidden');
    }).catch(err => {
        showNotification('error', 'Error al buscar altavoces cercanos');
    });
}

function toggleSyncSpeaker(speakerId) {
    const item = document.querySelector(`.sync-speaker-item[data-speaker-id="${speakerId}"]`);
    if (!item) return;

    const isSelected = item.classList.contains('selected');

    if (isSelected) {
        // Deselect
        item.classList.remove('selected');
        selectedSyncSpeakers = selectedSyncSpeakers.filter(id => id !== speakerId);
    } else {
        // Select
        item.classList.add('selected');
        selectedSyncSpeakers.push(speakerId);
    }
}

function confirmSync() {
    if (selectedSyncSpeakers.length === 0) {
        showNotification('error', 'Elige al menos un altavoz');
        return;
    }

    if (!currentMasterSpeaker) return;

    fetch(`https://${GetParentResourceName()}/createSyncGroup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            masterId: currentMasterSpeaker,
            slaveIds: selectedSyncSpeakers
        })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            showNotification('success', resp.message || 'Altavoces sincronizados');
            closeSyncModal();

            setTimeout(() => {
                updateSyncStatus();
            }, 300);
        } else {
            showNotification('error', resp.message || 'Error al sincronizar');
        }
    }).catch(err => {
        showNotification('error', 'Error al sincronizar');
    });
}

function unsyncSpeakers() {
    if (!speakerId) return;

    fetch(`https://${GetParentResourceName()}/removeSyncGroup`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ masterId: speakerId })
    }).then(resp => resp.json()).then(resp => {
        if (resp && resp.success) {
            showNotification('success', resp.message || 'Altavoces desincronizados');

            setTimeout(() => {
                updateSyncStatus();
            }, 300);
        } else {
            showNotification('error', resp.message || 'Error al desincronizar');
        }
    }).catch(err => {
        showNotification('error', 'Error al desincronizar');
    });
}

function closeSyncModal() {
    const modal = document.getElementById('syncSpeakersModal');
    if (modal) {
        modal.classList.add('hidden');
        selectedSyncSpeakers = [];
        currentMasterSpeaker = null;
    }
}

function updateHudBanner(title) {
    currentHudTitle = title || 'Sin música';
    const hudTitleEl = document.getElementById('hudTitle');
    if (hudTitleEl) {
        hudTitleEl.textContent = currentHudTitle;
    }
}

function showHudBanner() {
    if (!hudEnabled) return;

    const hudBanner = document.getElementById('now-playing-hud');
    const speakerContainer = document.getElementById('speaker-container');

    if (hudBanner && speakerContainer && currentHudTitle !== 'Sin música') {
        const isMenuOpen = !speakerContainer.classList.contains('hidden');

        if (!isMenuOpen) {
            hudBanner.classList.remove('hidden');
        }
    }
}

function hideHudBanner() {
    const hudBanner = document.getElementById('now-playing-hud');
    if (hudBanner) {
        hudBanner.classList.add('hidden');
    }
}

function toggleHudEnabled(enabled) {
    hudEnabled = enabled;
    localStorage.setItem('hudEnabled', enabled);

    if (!enabled) {
        hideHudBanner();
    } else {
        showHudBanner();
    }
}

function initializeHudToggle() {
    const hudToggle = document.getElementById('hudToggle');
    if (hudToggle) {
        hudToggle.checked = hudEnabled;
        hudToggle.addEventListener('change', (e) => {
            toggleHudEnabled(e.target.checked);
        });
    }
}

document.addEventListener('DOMContentLoaded', () => {
    initializeHudToggle();
});

safeAddEventListener('openSyncBtn', 'click', openSyncModal);
safeAddEventListener('unsyncBtn', 'click', unsyncSpeakers);
safeAddEventListener('confirmSyncBtn', 'click', confirmSync);
safeAddEventListener('cancelSyncBtn', 'click', closeSyncModal);
document.addEventListener('click', function (e) {
    const badge = e.target.closest('[data-action="toggle-public"]');
    if (badge) {
        const playlistId = parseInt(badge.getAttribute('data-playlist-id'));
        const currentClass = badge.className;
        const currentText = badge.textContent;

        if (playlistId && !isNaN(playlistId)) {
            e.preventDefault();
            e.stopPropagation();
            togglePublic(playlistId);
        }
    }
}, true);

window.openPlaylist = openPlaylist;
window.renamePlaylist = renamePlaylist;
window.sharePlaylist = sharePlaylist;
window.deletePlaylist = deletePlaylist;
window.playSong = playSong;
window.removeSongFromPlaylist = removeSongFromPlaylist;
window.closeModal = closeModal;
window.toggleSyncSpeaker = toggleSyncSpeaker;