Aviso = Aviso or {}

local visible = false
local ultimoEnvio = 0
local ultimoValor = -1

--- Sale a unos metros del relevo, no al llegar: la idea es que al jugador le de
--- tiempo a poner las manos, no enterarse cuando ya conduce.
function Aviso.Mostrar()
    if visible or not Config.Aviso.activo then return end
    visible = true
    ultimoValor = -1

    SendNUIMessage({
        accion  = 'aviso',
        mostrar = true,
        kicker  = Config.Aviso.kicker,
        titulo  = Config.Aviso.titulo,
        texto   = Config.Aviso.texto,
    })
end

--[[ Cuanto falta para el relevo, de 0 a 1.

     Va limitado a unos pocos envios por segundo y solo cuando el valor se mueve
     de verdad: SendNUIMessage serializa a JSON y cruza a CEF en cada llamada, y
     hacerlo en cada frame para mover una barra dos pixeles no compensa. La
     transicion CSS de 0.12s rellena los huecos. ]]
function Aviso.Progreso(valor)
    if not visible then return end

    local ahora = GetGameTimer()
    if ahora - ultimoEnvio < Config.Aviso.refresco then return end
    if math.abs(valor - ultimoValor) < 0.01 then return end

    ultimoEnvio = ahora
    ultimoValor = valor
    SendNUIMessage({ accion = 'progreso', valor = valor })
end

--- Aguanta que la llamen de mas: la intro puede acabar por varios caminos.
function Aviso.Ocultar()
    if not visible then return end
    visible = false
    SendNUIMessage({ accion = 'aviso', mostrar = false })
end
