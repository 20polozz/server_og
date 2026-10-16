Config = {}

-- Distancia máxima en la que se puede interactuar con el barco o coche para coger el gancho
Config.InteractDistance = 3.0

-- Longitud inicial de la cuerda
Config.RopeLength = 40.0

-- Lista de modelos de barcos que tendrán la opción de remolque
Config.AllowedBoats = {
    [`predator`] = true,
    [`hvpolmav`] = true,
    [`buzzard`] = { offset = vector3(0.00, 0.00, -0.44) },
    [`buzzard2`] = { offset = vector3(0.00, 0.00, -0.44) },
    -- Añade aquí más nombres de spawn de barcos entre acentos graves (``)
}

-- Teclas de interacción (Valores por defecto para el primer inicio)
-- Los jugadores pueden personalizar sus teclas en Esc -> Ajustes -> Asignación de teclas -> FiveM
Config.Keys = {
    Interact = 'E',
    Cancel = 'G',
    Up = 'PAGEUP',
    Down = 'PAGEDOWN',
    Panel = 'H',
}
