(function () {
    'use strict';

    var aviso  = document.getElementById('aviso');
    var kicker = document.getElementById('kicker');
    var titulo = document.getElementById('titulo');
    var texto  = document.getElementById('texto');
    var barra  = document.getElementById('barra');

    function mostrar(datos) {
        kicker.textContent = datos.kicker || '';
        titulo.textContent = datos.titulo || '';
        texto.textContent  = datos.texto || '';
        barra.style.width  = '0%';

        // La clase se quita y se vuelve a poner en el frame siguiente para que
        // la animacion de entrada se reinicie si el aviso sale dos veces
        // seguidas (una intro abortada y relanzada, por ejemplo).
        aviso.classList.remove('esta-dentro');
        requestAnimationFrame(function () {
            aviso.classList.add('esta-dentro');
        });
    }

    function ocultar() {
        aviso.classList.remove('esta-dentro');
    }

    function progreso(valor) {
        var v = Math.max(0, Math.min(1, valor || 0));
        barra.style.width = (v * 100).toFixed(1) + '%';
    }

    window.addEventListener('message', function (evento) {
        var datos = evento.data || {};

        if (datos.accion === 'aviso') {
            return datos.mostrar ? mostrar(datos) : ocultar();
        }

        if (datos.accion === 'progreso') {
            return progreso(datos.valor);
        }
    });
}());
