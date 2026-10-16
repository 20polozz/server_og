document.addEventListener("DOMContentLoaded", function () {
    const CONFIG = {
        slideDuration: 7000,
        transitionSpeed: 2000,
        loadingSpeed: 1000,
        coverflowEffect: {
            rotate: 30,
            stretch: 300,
            depth: 100,
            modifier: 1,
            slideShadows: false,
            perspective: 1200,
        },
        production: true,
        cardsEffect: {
            rotate: 10,
            perSlideperSlideOffset: 4,
            perSlideRotate: 2,
        },
        creativeEffect: {
            prev: {
                translate: [0, 0, -400],
                rotate: [0, 0, -8],
                opacity: 0,
                scale: 0.8,
            },
            next: {
                translate: [0, 0, 400],
                rotate: [0, 0, 8],
                opacity: 0,
                scale: 0.8,
            },
            perspective: true,
            transformEl: ".slide-inner",
        },
    };

    const tempImage = {
        background: "./img/tempimg.png",
        character: null,
    };

    let loadPercentage = 0;
    const progressFillLayer = document.querySelector(".progress-fill-layer");

    const video = document.getElementById('myVideo');

    /* Con fondo de imagen no hay <video> en la pagina. Sin esta comprobacion,
       video.play() lanzaba un TypeError y se llevaba por delante todo lo que
       viene despues: la barra de progreso y la musica. */
    function attemptPlayVideo() {
        if (!video) return;

        const playPromise = video.play();

        if (playPromise !== undefined) {
            playPromise.then(() => {
                console.log('Video reproducción iniciada con éxito');
            }).catch(error => {
                console.log('Error al reproducir el video:', error);
                setTimeout(attemptPlayVideo, 1000);
            });
        }
    }

    if (video) video.addEventListener('loadeddata', attemptPlayVideo);

    attemptPlayVideo();

    function updateProgress(percentage) {
        const clampedProgress = Math.max(0, Math.min(100, percentage));
        progressFillLayer.style.clipPath = `inset(0 ${100 - clampedProgress}% 0 0)`;
    }

    function createMusicIframe() {
        if (!parent.document.getElementById("music-frame")) {
            const musicFrame = parent.document.createElement("iframe");
            musicFrame.id = "music-frame";
            musicFrame.src = window.location.href.replace("index", "music");
            musicFrame.style.display = "none";
            parent.document.body.appendChild(musicFrame);
        }
    }
    createMusicIframe();

    let isMusicPlaying = true;
    const pressedKeys = {};
    let comboActive = false;

    function alternarMusica() {
        try {
            const asset = window.parent.document.getElementsByName('origen_loadingasset')[0];
            if (asset && asset.contentWindow) {
                asset.contentWindow.postMessage({ action: "toggleMusic" }, "*");
            }
        } catch (err) {}

        isMusicPlaying = !isMusicPlaying;

        const keyElement = document.getElementById("key");
        const actionElement = document.getElementById("music-action");
        if (keyElement && actionElement) {
            keyElement.textContent = "ESPACIO / Q+R";
            actionElement.textContent = isMusicPlaying ? "pausar" : "reproducir";
        }
    }

    window.addEventListener("keydown", (e) => {
        const key = e.key ? e.key.toLowerCase() : "";
        const code = e.code || "";
        if (code) pressedKeys[code] = true;
        if (key) pressedKeys[key] = true;

        if (e.code === "Space" || e.which === 32) {
            e.preventDefault();
            alternarMusica();
            return;
        }

        const isQ = pressedKeys["KeyQ"] || pressedKeys["q"];
        const isR = pressedKeys["KeyR"] || pressedKeys["r"];

        if (isQ && isR) {
            if (!comboActive) {
                comboActive = true;
                alternarMusica();
            }
        }
    });

    window.addEventListener("keyup", (e) => {
        const key = e.key ? e.key.toLowerCase() : "";
        const code = e.code || "";
        if (code) delete pressedKeys[code];
        if (key) delete pressedKeys[key];

        const isQ = pressedKeys["KeyQ"] || pressedKeys["q"];
        const isR = pressedKeys["KeyR"] || pressedKeys["r"];
        if (!isQ || !isR) {
            comboActive = false;
        }
    });

    window.addEventListener("blur", () => {
        for (const k in pressedKeys) delete pressedKeys[k];
        comboActive = false;
    });

    const handlers = {
        loadProgress(data) {
            loadPercentage = data.loadFraction * 100;
            updateProgress(loadPercentage);
        },
    };

    window.addEventListener("message", (e) =>
        (handlers[e.data.eventName] || (() => {}))(e.data)
    );
});