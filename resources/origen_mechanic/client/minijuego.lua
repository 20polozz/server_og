--[[ EL MINIJUEGO DEL TALLER

     Antes cada reparación tiraba del `lib.skillCheck` de ox_lib —el círculo
     con la letra—, que no es de la casa. Ahora se usan los de
     `origen_minijuegos`, que son los mismos que usan los robos y las
     habilidades, con el rótulo del trabajo que se está haciendo.

     Todo pasa por aquí para que las tres reparaciones (pieza, servicio y
     chapa) se comporten igual:

       · Se cierra lo que hubiera abierto ANTES de abrir el juego. El menú del
         punto del taller (`org-menu`) y un menú de ox_lib se quedaban encima
         del minijuego, robándole el ratón.
       · `sinAnim`: el personaje ya está con el capó abierto o soldando, y el
         juego no le corta la animación.
       · Si `origen_minijuegos` no está arrancado se vuelve al skillcheck de
         ox_lib, que es lo que había: sin el recurso, el taller sigue.

     Qué juego toca lo dice `Config.Repair.Minijuegos` (y la pieza concreta
     puede pedir otro en `Config.Repair.MinijuegoPorPieza`). ]]

--- Lo que tape el minijuego. Ninguno es obligatorio: se cierra lo que haya.
local function CerrarLoAbierto()
    pcall(function() lib.hideTextUI() end)
    pcall(function() lib.hideContext(false) end)
    if GetResourceState('org-menu') == 'started' then
        pcall(function() exports['org-menu']:closeMenu() end)
    end
    -- Un fotograma para que el menú suelte el foco antes de que el juego lo pida.
    Wait(50)
end

---@param cual table   { juego, dificultad, titulo } de Config.Repair.Minijuegos
---@param pieza string|nil  clave de la pieza, por si pide otro juego
---@param respaldo table    { skillCheck, inputs } de siempre, si no hay recurso
---@return boolean ganado
function Mechanic.Minijuego(cual, pieza, respaldo)
    CerrarLoAbierto()

    if type(cual) ~= 'table' or GetResourceState('origen_minijuegos') ~= 'started' then
        return lib.skillCheck(respaldo and respaldo.skillCheck or { 'easy', 'medium' },
            respaldo and respaldo.inputs or { 'w', 'a', 's', 'd' }) == true
    end

    --- Una pieza puede pedir otro juego (lo eléctrico no se taladra).
    local porPieza = pieza and Config.Repair.MinijuegoPorPieza and Config.Repair.MinijuegoPorPieza[pieza]
    if type(porPieza) == 'string' then porPieza = { juego = porPieza } end

    local juego = porPieza and porPieza.juego or cual.juego
    local dificultad = (porPieza and porPieza.dificultad) or cual.dificultad or 'medium'
    local titulo = (porPieza and porPieza.titulo) or cual.titulo

    --[[ El lanzador contesta por callback y aquí hace falta esperar el
         resultado en la misma línea, como hacía el skillcheck: una promesa. ]]
    local espera = promise.new()
    local lanzado = exports.origen_minijuegos:StartMinijuego(juego, dificultad, {
        titulo = titulo,
        sinAnim = true,
    }, function(exito)
        espera:resolve(exito == true)
    end)

    if lanzado == false then return false end

    return Citizen.Await(espera) == true
end
