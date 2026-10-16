--[[ ══ Los relojes de la intro ═══════════════════════════════════════════════

     Los topes de tiempo salen de la ruta, no de constantes fijas.

     Un trayecto de 350 m y uno de 4 km no pueden compartir el mismo reloj: con
     un tope pensado para el corto, el largo se cancela a medio camino; con uno
     pensado para el largo, un coche atascado en el corto tarda minutos en
     detectarse.

     La base es el tiempo teorico -- distancia entre velocidad de crucero -- y
     sobre el se aplican factores, porque la realidad siempre tarda mas:
     arrancar, frenar en las curvas, rodear algo.

     Cliente y servidor cargan este fichero y calculan lo mismo, asi que no hay
     que mandar los tiempos por la red ni pueden desincronizarse. ]]

Ritmo = {}

local function Acotar(valor, minimo, maximo)
    if valor < minimo then return minimo end
    if valor > maximo then return maximo end
    return valor
end

--- Distancia en plano del trayecto, en metros.
function Ritmo.Distancia(ruta)
    if not ruta or not ruta.spawn or not ruta.destino then return 0.0 end
    local dx = ruta.destino.x - ruta.spawn.x
    local dy = ruta.destino.y - ruta.spawn.y
    return math.sqrt(dx * dx + dy * dy)
end

--- Lo que duraria el viaje si nada se torciera, en ms.
function Ritmo.Teorico(ruta)
    local velocidad = Config.Conduccion.velocidad
    if not velocidad or velocidad <= 0.0 then return 0.0 end
    return (Ritmo.Distancia(ruta) / velocidad) * 1000.0
end

--[[ Los tres relojes de una ruta:

       camara   -- suelo de la caida. Si el coche se atasca, el plano se
                   completa igual pasado este tiempo. Queda POR ENCIMA de lo que
                   dura el viaje de verdad: si quedara por debajo, la camara
                   tocaria suelo con el coche todavia lejos del destino.
       cliente  -- la paciencia del vigilante antes de forzar la llegada.
       servidor -- por si el cliente se cuelga sin llegar a desconectar. Siempre
                   el ultimo en saltar. ]]
function Ritmo.De(ruta)
    local R = Config.Ritmo
    local base = Ritmo.Teorico(ruta)

    local camara  = Acotar(base * R.factorCamara + R.margen, R.minimo, R.maximo)
    local cliente = Acotar(base * R.factorTope + R.margen, camara + 10000, R.maximo)

    return {
        distancia = Ritmo.Distancia(ruta),
        teorico   = base,
        camara    = math.floor(camara),
        cliente   = math.floor(cliente),
        servidor  = math.floor(cliente + R.colchonServidor),
    }
end

--- Una linea legible para los logs. Lo primero que se mira cuando una ruta
--- nueva se comporta raro.
function Ritmo.Resumen(ruta)
    local r = Ritmo.De(ruta)
    return ('%s: %.0f m, ~%.0f s de viaje | camara %.0f s, vigilante %.0f s, servidor %.0f s')
        :format(tostring(ruta.etiqueta or '?'), r.distancia, r.teorico / 1000,
            r.camara / 1000, r.cliente / 1000, r.servidor / 1000)
end
