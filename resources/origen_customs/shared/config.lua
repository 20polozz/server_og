--[[ ORIGEN Customs · lo que se puede ajustar sin tocar código.

     El servidor es el único que decide con estos valores: los precios, los
     permisos y lo que se guarda en el coche se calculan aquí y nunca con lo
     que diga un cliente. ]]

Config = {}

Config.Depurar = false

--[[ ── Quién lo abre ────────────────────────────────────────────────────────
     Solo mecánicos: hay que estar DE SERVICIO en un negocio con punto de
     tuning, junto a ese punto y con el permiso del rango. El coche puede ser
     el que conduces o, si vas a pie, el más cercano al punto. ]]
Config.Acceso = {
    tipoPunto = 'tuning',
    permiso = 'repair_vehicles',
    -- Radio que valida el SERVIDOR entre el mecánico y el punto de tuning.
    radioPunto = 14.0,
    -- Distancia máxima entre el mecánico y el coche que tunea.
    radioCoche = 9.0,
    -- Con el coche parado en el punto, el cliente tiene que estar cerca para
    -- recibir el presupuesto.
    radioCliente = 12.0,
}

Config.Moneda = '$'

--[[ ── Precios ──────────────────────────────────────────────────────────────
     Precio base (multiplicador ×1). Encima se aplica el multiplicador de la
     clase del coche: un súper no cuesta lo mismo de pintar que un utilitario.
     Son la LISTA DE PARTIDA: la tabla `origen_customs_precios` manda, y se
     editan sin reiniciar desde origen_admin → Scripts → Origen Customs
     (permiso `origen_customs`) o con /admincustoms.

     Igual con el resto de esta config (clases, acceso, presupuesto, cámara y
     piezas bloqueadas): el panel guarda en `origen_customs_ajustes` y eso
     manda sobre lo de aquí. ]]
Config.Precios = {
    pieza = 450,          -- cualquier pieza estética (alerón, capó, faldones…)
    pinturaGTA = 350,     -- un color de la carta del juego
    pinturaRGB = 600,     -- color a medida
    acabado = 250,        -- cambiar solo el acabado (mate, metalizado, cromo…)
    perla = 400,
    colorLlantas = 250,
    colorInterior = 200,
    colorSalpicadero = 200,
    vinilo = 900,
    llantas = 800,
    tipoLlanta = 0,       -- cambiar de familia no cobra: cobra la llanta
    neumaticos = 350,     -- neumáticos de perfil personalizado
    humo = 300,
    xenon = 500,
    colorXenon = 150,
    neon = 400,           -- por cada lado encendido
    colorNeon = 200,
    tintado = 250,
    matricula = 150,
    extra = 0,
    bocina = 200,
    -- Rendimiento: un precio por nivel (índice 1 = nivel 1).
    motor = { 2500, 4500, 7500, 11000, 15000 },
    frenos = { 1500, 2800, 4500 },
    transmision = { 2000, 3500, 5500, 7500 },
    suspension = { 1200, 2200, 3200, 4500, 6000 },
    blindaje = { 3000, 5500, 8000, 11000, 15000 },
    turbo = 9000,
}

--[[ Multiplicador por clase de vehículo (GetVehicleClass). Los que no están
     valen 1.0. ]]
Config.MultiplicadorClase = {
    [0] = 0.8,   -- compactos
    [1] = 0.9,   -- sedanes
    [2] = 1.0,   -- SUV
    [3] = 1.0,   -- coupés
    [4] = 1.2,   -- muscle
    [5] = 1.6,   -- clásicos deportivos
    [6] = 1.5,   -- deportivos
    [7] = 2.4,   -- súper
    [8] = 0.7,   -- motos
    [9] = 1.2,   -- todoterreno
    [10] = 1.4,  -- industriales
    [11] = 1.1,  -- utilitarios
    [12] = 1.1,  -- furgonetas
    [22] = 1.6,  -- open wheel
}
Config.MultiplicadorTope = { min = 0.5, max = 4.0 }

--[[ ── El presupuesto ───────────────────────────────────────────────────────
     El mecánico monta el coche y le manda el total al cliente, que acepta y
     paga. Hasta entonces nada se guarda: si el cliente dice que no o se va,
     el coche vuelve a como estaba. ]]
Config.Presupuesto = {
    -- Segundos que tiene el cliente para contestar.
    caduca = 90,
    -- Cuenta con la que paga el cliente. `bank` pasa por origen_banking, que
    -- le pregunta con cuál de sus cuentas si tiene varias.
    cuenta = 'bank',
    -- Tope de líneas en un presupuesto: solo corta una petición inflada.
    maxLineas = 80,
}

--[[ ── Descuentos ───────────────────────────────────────────────────────────
     Lo que puede poner el mecánico en un presupuesto. El servidor rechaza
     cualquier otro porcentaje. `SinCobro` deja montar a coste cero (coches
     addon); el cliente tiene que aceptarlo igual y queda en el registro. ]]
Config.Descuentos = { 10, 15 }
Config.SinCobro = true

--[[ ── Cámara ───────────────────────────────────────────────────────────────
     Distancias en metros; se escalan con el tamaño del coche. ]]
Config.Camara = {
    distancia = 1.35,      -- × el radio del coche
    distanciaMin = 0.55,
    distanciaMax = 2.6,
    altura = 12.0,         -- grados sobre el horizonte al abrir
    suavizado = 0.14,      -- 0..1: cuánto se acerca a su objetivo cada fotograma
    sensibilidad = 0.22,   -- grados por píxel de arrastre
    fov = 42.0,
    girarSolo = 7.0,       -- grados por segundo en modo exposición
    -- La columna y el riel ocupan el tercio derecho: la cámara se corre de
    -- lado (× la distancia) para que el coche quede en el hueco libre.
    desplazar = 0.21,
}

-- Modelos que no dejan tocar alguna pieza (rompen el coche o salen bugueados).
-- Por NOMBRE de modelo: así se lee en el panel de admin, que lo edita.
Config.PiezasBloqueadas = {
    buffalo4 = { 5, 45 },
}

--- Las piezas bloqueadas de un modelo (por su hash).
function PiezasBloqueadasDe(modelo)
    for nombre, lista in pairs(Config.PiezasBloqueadas or {}) do
        if joaat(nombre) == modelo then return lista end
    end
    return nil
end
