--[[ El catálogo: qué se le puede poner a un coche y cómo se llama cada cosa
     en los tres idiomas que hablan entre sí — el índice del GTA, el campo de
     las propiedades de ox_lib (lo que se guarda en `player_vehicles.mods`) y
     el nombre que lee el mecánico.

     Vive en shared porque el servidor construye con esto las propiedades que
     guarda, y el cliente con lo mismo aplica y enseña. Si una pieza estuviera
     escrita en dos sitios, algún día dirían cosas distintas. ]]

Catalogo = {}

--[[ Las zonas del coche. Son los puntos que se ven flotando sobre él y los
     grupos del menú. `huesos` son los candidatos, en orden: el primero que
     tenga el modelo marca el punto. Si no tiene ninguno, se usa `hueco`, una
     posición relativa a la caja del coche (x lateral, y longitudinal, z alto,
     de -1 a 1). `camara` dice desde dónde se mira: el ángulo alrededor del
     coche (0 = de frente), la altura en grados y la distancia relativa. ]]
Catalogo.Zonas = {
    { id = 'frontal', nombre = 'Frontal', icono = 'frontal',
      huesos = { 'bumper_f', 'bonnet' }, hueco = { 0.0, 0.95, -0.1 },
      camara = { angulo = 0, altura = 8, distancia = 0.95 } },
    { id = 'motor', nombre = 'Motor', icono = 'motor',
      huesos = { 'engine', 'bonnet' }, hueco = { 0.0, 0.6, 0.35 },
      camara = { angulo = 0, altura = 38, distancia = 0.8 }, abre = { 4 } },
    { id = 'lateral', nombre = 'Lateral', icono = 'lateral',
      huesos = { 'door_dside_f', 'door_dside_r' }, hueco = { -1.0, 0.0, -0.2 },
      camara = { angulo = 90, altura = 6, distancia = 1.0 } },
    { id = 'ruedas', nombre = 'Ruedas', icono = 'rueda',
      huesos = { 'wheel_lf', 'wheel_lr' }, hueco = { -1.0, 0.65, -0.6 },
      camara = { angulo = 62, altura = 4, distancia = 0.62 } },
    { id = 'techo', nombre = 'Techo', icono = 'techo',
      huesos = { 'roof', 'windscreen_r' }, hueco = { 0.0, -0.1, 1.0 },
      camara = { angulo = 30, altura = 42, distancia = 1.05 } },
    { id = 'trasera', nombre = 'Trasera', icono = 'trasera',
      huesos = { 'bumper_r', 'boot' }, hueco = { 0.0, -0.95, -0.1 },
      camara = { angulo = 180, altura = 10, distancia = 0.95 } },
    { id = 'escape', nombre = 'Escape', icono = 'escape',
      huesos = { 'exhaust', 'exhaust_2' }, hueco = { 0.4, -1.0, -0.55 },
      camara = { angulo = 160, altura = 4, distancia = 0.62 } },
    { id = 'interior', nombre = 'Interior', icono = 'interior',
      huesos = { 'seat_dside_f', 'steeringwheel' }, hueco = { -0.3, 0.15, 0.25 },
      camara = { interior = true }, abre = { 0, 1 } },
    { id = 'maletero', nombre = 'Maletero', icono = 'maletero',
      huesos = { 'boot' }, hueco = { 0.0, -0.8, 0.3 },
      camara = { angulo = 180, altura = 30, distancia = 0.8 }, abre = { 5 } },
    { id = 'luces', nombre = 'Luces', icono = 'luces',
      huesos = { 'headlight_l', 'headlight_r' }, hueco = { -0.6, 0.95, 0.0 },
      camara = { angulo = 25, altura = 6, distancia = 0.75 } },
}

--[[ Las piezas del motor de modificaciones del GTA (SetVehicleMod). `campo`
     es el nombre en las propiedades de ox_lib. `precio` es la clave de
     Config.Precios: si es una lista, se cobra por nivel. ]]
Catalogo.Mods = {
    [0]  = { campo = 'modSpoilers',       nombre = 'Alerón',                 zona = 'trasera',  precio = 'pieza' },
    [1]  = { campo = 'modFrontBumper',    nombre = 'Paragolpes delantero',   zona = 'frontal',  precio = 'pieza' },
    [2]  = { campo = 'modRearBumper',     nombre = 'Paragolpes trasero',     zona = 'trasera',  precio = 'pieza' },
    [3]  = { campo = 'modSideSkirt',      nombre = 'Taloneras',              zona = 'lateral',  precio = 'pieza' },
    [4]  = { campo = 'modExhaust',        nombre = 'Escape',                 zona = 'escape',   precio = 'pieza' },
    [5]  = { campo = 'modFrame',          nombre = 'Jaula antivuelco',       zona = 'interior', precio = 'pieza' },
    [6]  = { campo = 'modGrille',         nombre = 'Parrilla',               zona = 'frontal',  precio = 'pieza' },
    [7]  = { campo = 'modHood',           nombre = 'Capó',                   zona = 'frontal',  precio = 'pieza' },
    [8]  = { campo = 'modFender',         nombre = 'Aletas',                 zona = 'lateral',  precio = 'pieza' },
    [9]  = { campo = 'modRightFender',    nombre = 'Aleta derecha',          zona = 'lateral',  precio = 'pieza' },
    [10] = { campo = 'modRoof',           nombre = 'Techo',                  zona = 'techo',    precio = 'pieza' },
    [11] = { campo = 'modEngine',         nombre = 'Motor',                  zona = 'rendimiento', precio = 'motor', nivel = true },
    [12] = { campo = 'modBrakes',         nombre = 'Frenos',                 zona = 'rendimiento', precio = 'frenos', nivel = true },
    [13] = { campo = 'modTransmission',   nombre = 'Transmisión',            zona = 'rendimiento', precio = 'transmision', nivel = true },
    [14] = { campo = 'modHorns',          nombre = 'Claxon',                 zona = 'sonido',   precio = 'bocina' },
    [15] = { campo = 'modSuspension',     nombre = 'Suspensión',             zona = 'rendimiento', precio = 'suspension', nivel = true },
    [16] = { campo = 'modArmor',          nombre = 'Blindaje',               zona = 'rendimiento', precio = 'blindaje', nivel = true },
    [19] = { campo = 'modSubwoofer',      nombre = 'Subwoofer',              zona = 'maletero', precio = 'pieza' },
    [25] = { campo = 'modPlateHolder',    nombre = 'Portamatrículas',        zona = 'trasera',  precio = 'pieza' },
    [26] = { campo = 'modVanityPlate',    nombre = 'Placa decorativa',       zona = 'frontal',  precio = 'pieza' },
    [27] = { campo = 'modTrimA',          nombre = 'Molduras interiores',    zona = 'interior', precio = 'pieza' },
    [28] = { campo = 'modOrnaments',      nombre = 'Adornos',                zona = 'interior', precio = 'pieza' },
    [29] = { campo = 'modDashboard',      nombre = 'Salpicadero',            zona = 'interior', precio = 'pieza' },
    [30] = { campo = 'modDial',           nombre = 'Relojes',                zona = 'interior', precio = 'pieza' },
    [31] = { campo = 'modDoorSpeaker',    nombre = 'Altavoces de puerta',    zona = 'interior', precio = 'pieza' },
    [32] = { campo = 'modSeats',          nombre = 'Asientos',               zona = 'interior', precio = 'pieza' },
    [33] = { campo = 'modSteeringWheel',  nombre = 'Volante',                zona = 'interior', precio = 'pieza' },
    [34] = { campo = 'modShifterLeavers', nombre = 'Palanca de cambios',     zona = 'interior', precio = 'pieza' },
    [35] = { campo = 'modAPlate',         nombre = 'Placa interior',         zona = 'interior', precio = 'pieza' },
    [36] = { campo = 'modSpeakers',       nombre = 'Altavoces',              zona = 'maletero', precio = 'pieza' },
    [37] = { campo = 'modTrunk',          nombre = 'Maletero',               zona = 'maletero', precio = 'pieza' },
    [38] = { campo = 'modHydrolic',       nombre = 'Hidráulica',             zona = 'maletero', precio = 'pieza' },
    [39] = { campo = 'modEngineBlock',    nombre = 'Bloque motor',           zona = 'motor',    precio = 'pieza' },
    [40] = { campo = 'modAirFilter',      nombre = 'Filtro de aire',         zona = 'motor',    precio = 'pieza' },
    [41] = { campo = 'modStruts',         nombre = 'Barras de torreta',      zona = 'motor',    precio = 'pieza' },
    [42] = { campo = 'modArchCover',      nombre = 'Cubrepasos',             zona = 'lateral',  precio = 'pieza' },
    [43] = { campo = 'modAerials',        nombre = 'Antenas',                zona = 'techo',    precio = 'pieza' },
    [44] = { campo = 'modTrimB',          nombre = 'Molduras exteriores',    zona = 'lateral',  precio = 'pieza' },
    [45] = { campo = 'modTank',           nombre = 'Depósito',               zona = 'trasera',  precio = 'pieza' },
    [46] = { campo = 'modWindows',        nombre = 'Ventanillas',            zona = 'lateral',  precio = 'pieza' },
    [47] = { campo = 'modDoorR',          nombre = 'Puertas',                zona = 'lateral',  precio = 'pieza' },
    [48] = { campo = 'modLivery',         nombre = 'Vinilo',                 zona = 'pintura',  precio = 'vinilo' },
    [49] = { campo = 'modLightbar',       nombre = 'Barra de luces',         zona = 'techo',    precio = 'pieza' },
}

-- Las tres que se encienden o apagan (ToggleVehicleMod) en vez de tener opciones.
Catalogo.Interruptores = {
    [18] = { campo = 'modTurbo',        nombre = 'Turbo',            precio = 'turbo' },
    [20] = { campo = 'modSmokeEnabled', nombre = 'Humo de ruedas',   precio = 'humo' },
    [22] = { campo = 'modXenon',        nombre = 'Faros de xenón',   precio = 'xenon' },
}

--[[ Familias de llantas (SetVehicleWheelType). `motos` = 6 solo para motos;
     las demás no se ofrecen en una moto. ]]
Catalogo.TiposLlanta = {
    { id = 0,  nombre = 'Deportivas' },
    { id = 1,  nombre = 'Muscle' },
    { id = 2,  nombre = 'Lowrider' },
    { id = 3,  nombre = 'SUV' },
    { id = 4,  nombre = 'Todoterreno' },
    { id = 5,  nombre = 'Tuner' },
    { id = 6,  nombre = 'Moto', motos = true },
    { id = 7,  nombre = 'Alta gama' },
    { id = 8,  nombre = "Benny's originales" },
    { id = 9,  nombre = "Benny's a medida" },
    { id = 10, nombre = 'Monoplaza' },
    { id = 11, nombre = 'Calle' },
    { id = 12, nombre = 'Circuito' },
}

Catalogo.Tintados = {
    { id = 0, nombre = 'Sin tintar' },
    { id = 4, nombre = 'Suave' },
    { id = 3, nombre = 'Humo claro' },
    { id = 2, nombre = 'Humo oscuro' },
    { id = 1, nombre = 'Negro total' },
    { id = 5, nombre = 'Limusina' },
    { id = 6, nombre = 'Verde' },
}

Catalogo.Matriculas = {
    { id = 0, nombre = 'Azul sobre blanco I' },
    { id = 3, nombre = 'Azul sobre blanco II' },
    { id = 4, nombre = 'Azul sobre blanco III' },
    { id = 1, nombre = 'Amarillo sobre negro' },
    { id = 2, nombre = 'Amarillo sobre azul' },
    { id = 5, nombre = 'North Yankton' },
}

-- 0-12 son los colores de xenón del juego; -1 = el blanco de serie.
Catalogo.XenonMax = 12

--[[ Acabados de pintura (paintType de SetVehicleModColor_1). El cromo y el
     metal cepillado solo se ven bien con color de la carta, por eso los
     marca `soloCarta`. ]]
Catalogo.Acabados = {
    { id = 0, clave = 'normal',      nombre = 'Clásico' },
    { id = 1, clave = 'metalizado',  nombre = 'Metalizado' },
    { id = 2, clave = 'perlado',     nombre = 'Perlado' },
    { id = 3, clave = 'mate',        nombre = 'Mate' },
    { id = 4, clave = 'metal',       nombre = 'Metal cepillado', soloCarta = true },
    { id = 5, clave = 'cromo',       nombre = 'Cromo',            soloCarta = true },
}

-- Rango de índices de color de la carta del juego (en b3095 llega a 242).
Catalogo.ColorMax = 242

--- ¿El índice de una pieza existe en el catálogo?
function Catalogo.Mod(indice)
    return Catalogo.Mods[tonumber(indice) or -99]
end

function Catalogo.Zona(id)
    for i = 1, #Catalogo.Zonas do
        if Catalogo.Zonas[i].id == id then return Catalogo.Zonas[i] end
    end
end
