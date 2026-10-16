--[[ EL MINIJUEGO DEL ASALTO

     Antes era el `lib.skillCheck` de ox_lib —el circulo con la letra—, que no
     es de la casa. Ahora es uno de `origen_minijuegos`, los mismos que usan
     el taller, los robos y las habilidades, con su rotulo. Cual, en
     `Config.Raid.minijuego`.

     Si `origen_minijuegos` no esta arrancado (o la config no dice cual) se
     vuelve al skillcheck de siempre: sin ese recurso, el asalto sigue.

     Se cierra lo que hubiera abierto antes (texto de ayuda, menu de ox_lib,
     org-menu): se quedaba encima del minijuego robandole el raton. ]]

local function CerrarLoAbierto()
    pcall(function() lib.hideTextUI() end)
    pcall(function() lib.hideContext(false) end)
    if GetResourceState('org-menu') == 'started' then
        pcall(function() exports['org-menu']:closeMenu() end)
    end
    -- Un fotograma para que el menu suelte el foco antes de que el juego lo pida.
    Wait(50)
end

local function SkillCheckDeOxLib()
    return lib.skillCheck(
        {'easy', 'easy', {areaSize = 60, speedMultiplier = 2}, 'hard'},
        {'w', 'a', 's', 'd'}
    ) == true
end

Custom.RaidSkillcheck = function()
    local cual = Config.Raid and Config.Raid.minijuego

    if type(cual) ~= 'table' or not cual.juego or GetResourceState('origen_minijuegos') ~= 'started' then
        return SkillCheckDeOxLib()
    end

    CerrarLoAbierto()

    --[[ El lanzador contesta por callback y aqui hace falta el resultado en
         la misma linea, como hacia el skillcheck: una promesa. `sinAnim`: la
         patada ya la pone house.lua y el juego no se la corta. ]]
    local espera = promise.new()
    local ok, lanzado = pcall(function()
        return exports.origen_minijuegos:StartMinijuego(cual.juego, cual.dificultad or 'easy', {
            titulo = cual.titulo,
            sinAnim = true,
        }, function(exito)
            espera:resolve(exito == true)
        end)
    end)

    -- El export fallo o no conoce ese juego (clave mal puesta en la config):
    -- el de siempre, para no dejar el asalto sin prueba.
    if not ok or lanzado == false then return SkillCheckDeOxLib() end

    return Citizen.Await(espera) == true
end
