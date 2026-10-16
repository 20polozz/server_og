// =====================================================
// LOCKPICK MINIGAME - SIMPLIFIED
// =====================================================

let isActive = false;
let currentPin = 0;
let totalPins = 5;
let timePerPin = 5;
let timeLeft = 5;
let pinPosition = 0;
let pinDirection = 1;
let moveSpeed = 1;
let sweetSpotPosition = 50;
let sweetSpotSize = 30;
let timerInterval = null;
let moveInterval = null;
// Sube al empezar, al salir con Escape y cuando Lua cierra: una pausa (el
// medio segundo tras acertar o fallar) de otra partida no hace nada.
let partida = 0;

function tras(fn, ms) {
    const mia = partida;
    return setTimeout(() => {
        if (mia !== partida) return;
        fn();
    }, ms);
}

// =====================================================
// POST TO CLIENT
// =====================================================

function post(action, data = {}) {
    const resourceName = GetParentResourceName();
    
    
    return $.post(`https://${resourceName}/${action}`, JSON.stringify(data))
        .done(function(response) {
            
        })
        .fail(function(error) {
            console.error('[LOCKPICK DEBUG] POST FAILED ->', action, 'error:', error);
        });
}

function GetParentResourceName() {
    // Siempre devolver el nombre correcto del recurso
    const resourceName = 'origen_minijuegos';
    
    return resourceName;
}

// =====================================================
// LISTENER DE MENSAJES
// =====================================================

window.addEventListener('message', function(event) {
    const data = event.data;
    
    if (data.action === 'startLockpick') {
        startLockpick(data.config);
    } else if (data.action === 'closeLockpick') {
        // Lua la cierra (otra partida encima, o el raton soltado a la
        // fuerza): fuera sin mandar nada, que Lua ya ha contestado. Sin esto
        // `isActive` seguia en true y la partida nueva no llegaba a empezar.
        partida++;
        closeLockpick();
    }
});

// =====================================================
// INICIAR LOCKPICK
// =====================================================

function startLockpick(config) {
    if (isActive) return;
    
    totalPins = config.pins || 5;
    timePerPin = config.timePerPin || 5;
    sweetSpotSize = config.sweetSpotSize || 30;
    moveSpeed = config.moveSpeed || 1;
    
    currentPin = 0;
    timeLeft = timePerPin;
    pinPosition = 0;
    pinDirection = 1;
    isActive = true;
    partida++;
    $('.game-track').removeClass('success fail');
    
    $('#lockpick-container').fadeIn(300);
    
    generateProgressDots();
    startNewPin();
}

// =====================================================
// GENERAR PROGRESS DOTS
// =====================================================

function generateProgressDots() {
    const container = $('#progress-dots');
    container.empty();
    
    for (let i = 0; i < totalPins; i++) {
        const dot = $('<div class="progress-dot"></div>');
        if (i === 0) dot.addClass('active');
        container.append(dot);
    }
}

// =====================================================
// NUEVO PIN
// =====================================================

function startNewPin() {
    pinPosition = 0;
    pinDirection = 1;
    timeLeft = timePerPin;
    
    // Generar posición aleatoria del sweet spot
    sweetSpotPosition = Math.random() * (75 - 25) + 25;
    updateSweetSpot();
    
    updateUI();
    startPinMovement();
    startTimer();
}

// =====================================================
// MOVIMIENTO DEL PIN
// =====================================================

function startPinMovement() {
    if (moveInterval) clearInterval(moveInterval);
    
    moveInterval = setInterval(() => {
        pinPosition += (0.5 * moveSpeed * pinDirection);
        
        if (pinPosition >= 100) {
            pinPosition = 100;
            pinDirection = -1;
        } else if (pinPosition <= 0) {
            pinPosition = 0;
            pinDirection = 1;
        }
        
        $('#pin-indicator').css('left', pinPosition + '%');
        checkInZone();
        
    }, 20);
}

// =====================================================
// TIMER
// =====================================================

function startTimer() {
    if (timerInterval) clearInterval(timerInterval);
    
    timerInterval = setInterval(() => {
        timeLeft -= 0.1;
        
        if (timeLeft <= 0) {
            failPin();
        }
        
        updateTimer();
        
    }, 100);
}

function updateTimer() {
    const timerElement = $('#timer');
    timerElement.text(Math.max(0, timeLeft).toFixed(1));
    
    // Cambiar color según tiempo restante
    timerElement.removeClass('warning danger');
    if (timeLeft < 2) {
        timerElement.addClass('danger');
    } else if (timeLeft < 3) {
        timerElement.addClass('warning');
    }
}

// =====================================================
// SWEET SPOT
// =====================================================

function updateSweetSpot() {
    const leftPosition = sweetSpotPosition - (sweetSpotSize / 2);
    $('#sweet-spot').css({
        'left': leftPosition + '%',
        'width': sweetSpotSize + '%'
    });
}

function checkInZone() {
    const spotStart = sweetSpotPosition - (sweetSpotSize / 2);
    const spotEnd = sweetSpotPosition + (sweetSpotSize / 2);
    
    if (pinPosition >= spotStart && pinPosition <= spotEnd) {
        $('#pin-indicator').addClass('in-zone');
    } else {
        $('#pin-indicator').removeClass('in-zone');
    }
}

function isInZone() {
    const spotStart = sweetSpotPosition - (sweetSpotSize / 2);
    const spotEnd = sweetSpotPosition + (sweetSpotSize / 2);
    return (pinPosition >= spotStart && pinPosition <= spotEnd);
}

// =====================================================
// ACTUALIZAR UI
// =====================================================

function updateUI() {
    $('#current-pin').text(currentPin + 1);
    $('#total-pins').text(totalPins);
    $('#total-pins-2').text(totalPins);
    $('#completed-pins').text(currentPin);
    
    $('.progress-dot').each(function(index) {
        $(this).removeClass('active completed');
        if (index < currentPin) {
            $(this).addClass('completed');
        } else if (index === currentPin) {
            $(this).addClass('active');
        }
    });
}

// =====================================================
// BLOQUEAR PIN
// =====================================================

function lockPin() {
    if (!isActive) return;
    
    
    
    
    
    if (isInZone()) {
        successPin();
    } else {
        failPin();
    }
}

// =====================================================
// ÉXITO
// =====================================================

function successPin() {
    
    
    clearInterval(moveInterval);
    clearInterval(timerInterval);
    
    $('.game-track').addClass('success');
    
    tras(() => {
        $('.game-track').removeClass('success');
        
        currentPin++;
        
        
        
        if (currentPin >= totalPins) {
            
            completeLockpick(true);
        } else {
            
            startNewPin();
        }
    }, 500);
}

// =====================================================
// FALLO
// =====================================================

function failPin() {
    
    
    clearInterval(moveInterval);
    clearInterval(timerInterval);
    
    $('.game-track').addClass('fail');
    
    tras(() => {
        $('.game-track').removeClass('fail');
        
        completeLockpick(false);
    }, 500);
}

// =====================================================
// COMPLETAR
// =====================================================

function completeLockpick(success) {
    
    
    isActive = false;
    
    
    // Limpiar intervalos inmediatamente
    if (moveInterval) clearInterval(moveInterval);
    if (timerInterval) clearInterval(timerInterval);
    
    
    // Enviar resultado al cliente (esto libera el focus del ratón)
    post('lockpickResult', { success: success });
    
    
    // Ocultar el NUI casi inmediatamente
    tras(() => {
        
        $('#lockpick-container').fadeOut(200);
    }, 100);
}

// =====================================================
// CERRAR
// =====================================================

function closeLockpick() {
    if (moveInterval) clearInterval(moveInterval);
    if (timerInterval) clearInterval(timerInterval);
    
    isActive = false;
    currentPin = 0;
    pinPosition = 0;
    
    $('#lockpick-container').stop(true, true).hide();
    $('.game-track').removeClass('success fail');
}

// =====================================================
// TECLAS
// =====================================================

$(document).keydown(function(e) {
    if (!isActive) return;
    
    if (e.key === ' ' || e.keyCode === 32) {
        
        e.preventDefault();
        lockPin();
    }
    
    if (e.key === 'Escape' || e.keyCode === 27) {
        
        e.preventDefault();
        
        if (isActive) {
            clearInterval(moveInterval);
            clearInterval(timerInterval);
            isActive = false;
            partida++;
            
            
            // Enviar al cliente (esto libera el focus inmediatamente)
            post('closeLockpick');
            
            
            // Ocultar NUI
            $('#lockpick-container').hide();
        }
    }
});

// =====================================================
// INIT
// =====================================================

$(document).ready(function() {
    
    
    
});
