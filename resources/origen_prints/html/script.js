const overlay = document.getElementById('image-overlay');
const img = document.getElementById('display-img');

window.addEventListener('message', (event) => {
    const data = event.data;

    if (data.action === "showImage") {
        img.src = data.url;
        overlay.classList.remove('hidden');
    } else if (data.action === "hideImage") {
        overlay.classList.add('hidden');
        img.src = '';
    }
});

const closeImage = () => {
    overlay.classList.add('hidden');
    img.src = '';
    
    // Notificar al server que cerramos
    fetch(`https://${GetParentResourceName()}/closeImage`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json; charset=UTF-8',
        },
        body: JSON.stringify({})
    });
};

// Cerrar con Escape
window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !overlay.classList.contains('hidden')) {
        closeImage();
    }
});

