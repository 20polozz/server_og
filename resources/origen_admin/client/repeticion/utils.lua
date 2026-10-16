--[[ La repeticion: el sistema de grabacion por jugador (antes pr_screens)
     metido dentro del admin. Cada cliente guarda los ultimos segundos de lo
     que pasa a su alrededor; un staff lo pide desde la pestaña Espectar y lo
     reproduce con actores en su propio cliente.

     Todo va con prefijo Rep: el admin ya tiene su `Config` y sus globales, y
     el original los pisaba. La configuracion es Config.Repeticion. ]]
RepCfg = Config.Repeticion

RepUtils = {}

RepUtils.FLAGS = {
    dead = 1,
    ragdoll = 2,
    shooting = 4,
    aiming = 8,
    reloading = 16,
    jumping = 32,
    cover = 64,
    melee = 128,
    driveby = 256,
}

local RingBuffer = {}
RingBuffer.__index = RingBuffer

function RepUtils.createRingBuffer(size)
    return setmetatable({ data = {}, head = 0, count = 0, size = size }, RingBuffer)
end

function RingBuffer:push(value)
    self.head = self.head % self.size + 1
    self.data[self.head] = value

    if self.count < self.size then
        self.count = self.count + 1
    end
end

function RingBuffer:recyclableSlot()
    if self.count < self.size then return nil end

    return self.data[self.head % self.size + 1]
end

function RingBuffer:get(index)
    if index < 1 or index > self.count then return nil end

    local oldest = self.head - self.count + 1
    return self.data[(oldest + index - 2) % self.size + 1]
end

function RingBuffer:clear()
    self.data = {}
    self.head = 0
    self.count = 0
end

function RepUtils.lerp(a, b, t)
    return a + (b - a) * t
end

function RepUtils.lerpAngle(a, b, t)
    local diff = (b - a + 180.0) % 360.0 - 180.0
    return a + diff * t
end

function RepUtils.formatTime(ms)
    local totalSeconds = ms / 1000
    local minutes = math.floor(totalSeconds / 60)
    local seconds = totalSeconds % 60

    return ('%02d:%05.2f'):format(minutes, seconds)
end

--[[ Lo que se pinta encima de la repeticion va en la «pegatina» del servidor:
     papel gris claro, canto negro fino, sombra dura negra y rosa de acento,
     con la tinta negra y sin contorno. Nada de los colores ~x~ de GTA: cada
     texto lleva su color de aqui. ]]
RepUtils.COLOR = {
    fondo  = { 220, 221, 224, 255 },
    panel  = { 196, 198, 202, 255 },
    tinta  = { 0, 0, 0, 255 },
    tenue  = { 70, 72, 78, 255 },
    acento = { 216, 27, 85, 255 },
    blanco = { 255, 255, 255, 255 },
}

local FUENTE = 4   -- la condensada de GTA, la que usa el resto del servidor

--- Quita los ~x~ que pudieran venir dentro (un nombre de jugador, p. ej.).
function RepUtils.limpio(text)
    return (tostring(text or ''):gsub('~', ''))
end

function RepUtils.drawText(text, x, y, scale, center, color)
    local c = color or RepUtils.COLOR.tinta
    SetTextFont(FUENTE)
    SetTextScale(scale, scale)
    SetTextColour(c[1], c[2], c[3], c[4] or 255)

    if center then
        SetTextCentre(true)
    end

    SetTextEntry('STRING')
    AddTextComponentSubstringPlayerName(text)
    DrawText(x, y)
end

--- Ancho en pantalla (0..1) de un texto, para ajustar la chapa a lo que lleva.
function RepUtils.textWidth(text, scale)
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(text)
    SetTextFont(FUENTE)
    SetTextScale(scale, scale)
    return EndTextCommandGetWidth(true)
end

function RepUtils.drawRect(x, y, w, h, r, g, b, a)
    DrawRect(x, y, w, h, r, g, b, a)
end

--- Una pieza de pegatina centrada en (x, y): sombra dura abajo a la derecha,
--- canto negro fino y el relleno (fondo por defecto).
function RepUtils.card(x, y, w, h, fill)
    local f = fill or RepUtils.COLOR.fondo
    DrawRect(x + 0.0025, y + 0.0045, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(x, y, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(x, y, w, h, f[1], f[2], f[3], f[4] or 255)
end
