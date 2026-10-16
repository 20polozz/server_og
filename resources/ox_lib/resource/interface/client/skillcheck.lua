--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@type promise?
local skillcheck

---@alias SkillCheckDifficulity 'easy' | 'medium' | 'hard' | { areaSize: number, speedMultiplier: number }

--[[ ORIGEN (07/10): la prueba de habilidad sale en origen_minijuegos (la
     «Cámara acorazada»: anillos que giran y se paran con ESPACIO o CLIC
     cuando la muesca pasa por el cerrojo) y no en la web de ox_lib, que es
     oscura y no es de la casa; igual que lib.notify, lib.showTextUI,
     lib.registerContext, lib.inputDialog y lib.alertDialog ya van a lo
     nuestro. La API es la de ox: lib.skillCheck(difficulty, inputs) ->
     boolean, lib.skillCheckActive() y lib.cancelSkillCheck().

       · Cada tramo de ox (`'easy'`, `{ 'easy', 'medium' }`...) es un anillo;
         la anchura de la muesca y la velocidad salen del tramo MAS DIFICIL
         (el area mas pequeña y la velocidad mas alta). El juego pide minimo
         dos anillos: con un solo tramo se ponen dos con la muesca un 25 %
         mas ancha, para que no cueste mas que antes.
       · Un fallo y se pierde (como en ox), y un reloj corto (6 s + 4 s por
         anillo) para que quedarse quieto tambien sea perder.
       · `inputs` (las letras de ox) no se usa: el juego se para con ESPACIO,
         INTRO o clic.
       · sinAnim: quien pide la prueba ya tiene su animacion puesta (pescar,
         forzar, reparar) y el juego no se la corta.
       · Si origen_minijuegos no esta arrancado, o no conoce el juego, sale la
         web de ox de siempre.

     OJO: si se actualiza ox_lib, esto hay que volver a ponerlo. ]]

local JUEGO = 'boveda'
local enOrigen = false   -- la prueba en curso es de origen_minijuegos

--- Los numeros de la web de ox (web/src/features/skillcheck): area en grados
--- y multiplicador de velocidad.
local OX = {
    easy = { 50, 1.0 },
    medium = { 40, 1.5 },
    hard = { 25, 1.75 },
}

local function tope(v, min, max)
    return math.max(min, math.min(max, v))
end

---@return number area, number velocidad
local function tramo(d)
    if type(d) == 'table' then
        return tonumber(d.areaSize) or OX.medium[1], tonumber(d.speedMultiplier) or OX.medium[2]
    end
    local v = OX[d] or OX.medium
    return v[1], v[2]
end

local function AjustesDeOx(difficulty)
    --- Un tramo suelto (texto o { areaSize, speedMultiplier }) o una lista de tramos.
    local lista = difficulty
    if type(difficulty) ~= 'table' or difficulty.areaSize ~= nil or difficulty[1] == nil then
        lista = { difficulty }
    end

    local area, velocidad = math.huge, 0
    for i = 1, #lista do
        local a, v = tramo(lista[i])
        area = math.min(area, a)
        velocidad = math.max(velocidad, v)
    end

    local anillos = tope(#lista, 2, 7)
    --- El area de ox es de 360 grados con UN indicador; la muesca del anillo,
    --- algo menos de la mitad (easy 50 -> 22, hard 25 -> 11, como el juego).
    local margen = area * 0.45
    if #lista == 1 then margen = margen * 1.25 end

    return {
        anillos = anillos,
        margen = math.floor(tope(margen, 6, 30) + 0.5),
        velocidad = tope(0.4 + 0.45 * velocidad, 0.5, 2.0),
        acelera = 0,
        fallos = 0,
        tiempo = 6 + 4 * anillos,
        titulo = 'Prueba de habilidad',
        sinAnim = true,
    }
end

---@param difficulty SkillCheckDifficulity | SkillCheckDifficulity[]
---@return boolean? lanzado  nil si no se ha podido (se cae a la web de ox)
local function SkillCheckOrigen(difficulty)
    if GetResourceState('origen_minijuegos') ~= 'started' then return nil end

    local p = promise.new()
    skillcheck = p
    enOrigen = true

    --- El juego contesta por callback; el resultado que llegue de una prueba
    --- que ya no es la viva (cancelada, o pisada por otra) no cuenta.
    local listo = false
    local ok, lanzado = pcall(function()
        return exports.origen_minijuegos:StartMinijuego(JUEGO, 'medium', AjustesDeOx(difficulty), function(exito)
            if not listo or skillcheck ~= p then return end
            skillcheck = nil
            enOrigen = false
            p:resolve(exito == true)
        end)
    end)

    if ok and lanzado ~= false then
        listo = true
        return Citizen.Await(p)
    end

    skillcheck = nil
    enOrigen = false
    return nil
end

---@param difficulty SkillCheckDifficulity | SkillCheckDifficulity[]
---@param inputs string[]?
---@return boolean?
function lib.skillCheck(difficulty, inputs)
    if skillcheck then return end

    local resultado = SkillCheckOrigen(difficulty)
    if resultado ~= nil then return resultado end

    skillcheck = promise:new()

    lib.setNuiFocus(false, true)
    SendNUIMessage({
        action = 'startSkillCheck',
        data = {
            difficulty = difficulty,
            inputs = inputs
        }
    })

    return Citizen.Await(skillcheck)
end

function lib.cancelSkillCheck()
    if not skillcheck then
        error('No skillCheck is active')
    end

    if enOrigen then
        --[[ origen_minijuegos no tiene un export para cerrar un juego: se
             suelta el raton con el rescate del vigilante de foco, y su
             AlSoltar da la partida por fallada y cierra la pantalla. La
             respuesta se da aqui ya, como ox (false). ]]
        local p = skillcheck
        skillcheck = nil
        enOrigen = false
        TriggerEvent('origen:foco:soltar')
        p:resolve(false)
        return
    end

    SendNUIMessage({action = 'skillCheckCancel'})
end

---@return boolean
function lib.skillCheckActive()
    return skillcheck ~= nil
end

RegisterNUICallback('skillCheckOver', function(success, cb)
    cb(1)

    if skillcheck and not enOrigen then
        lib.resetNuiFocus()

        skillcheck:resolve(success)
        skillcheck = nil
    end
end)
