const bgm = document.getElementById("bgm");
bgm.volume = 0.3;

let isPlaying = true;

function toggleMusic() {
    if (isPlaying) {
        bgm.pause();
        isPlaying = false;
    } else {
        bgm.play();
        isPlaying = true;
    }
}

window.addEventListener("message", (event) => {
    const data = event.data;
    
    if (data.type === "toggleMusic") {
        toggleMusic();
    }
    
    if (data.type === "stopMusic") {
        let volume = bgm.volume;
        const fadeOut = setInterval(() => {
            volume -= 0.03;
            if (volume <= 0) {
                volume = 0;
                bgm.volume = volume;
                bgm.pause();
                clearInterval(fadeOut);
            } else {
                bgm.volume = volume;
            }
        }, 100);
    }
    
    if (data.type === "setVolume") {
        bgm.volume = data.volume;
    }
});