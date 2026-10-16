--[[ ══ El enganche con la creacion de personaje ═════════════════════════════

     origen_titlemenu arma la intro justo antes de abrir la ropa y la lanza
     cuando la creacion ha terminado. Nada de esto se dispara solo: sin un
     armar() previo, este fichero no hace absolutamente nada.

     Hace falta la bandera porque 'origen_clothing:client:creationComplete'
     tambien salta al usar /skin, y ahi no hay ninguna intro que lanzar. ]]

local armado  = false
local lanzado = false

local function Lanzar()
    if not armado or lanzado then return end
    lanzado = true
    armado  = false
    CreateThread(function() Intro.Empezar() end)
end

exports('armar', function()
    armado  = true
    lanzado = false
end)

exports('desarmar', function()
    armado  = false
    lanzado = false
end)

exports('lanzar', Lanzar)

--[[ origen_clothing llama a esto desde su propio hilo, asi que no se le puede
     bloquear: Telon.Bajar espera a que la pantalla cubra. Va en un hilo
     aparte. ]]
exports('telon', function()
    if not armado then return end
    CreateThread(Telon.Bajar)
end)

exports('activa', function()
    return Intro.activo == true
end)

--[[ Red de seguridad, no el camino normal.

     El camino normal es PostSpawnPlayer(), que corre unos frames despues de
     esto, cuando origen_clothing ya ha resuelto su promesa y ha ejecutado sus
     propios callbacks; lanzar aqui seria pelearse con ellos.

     Pero si EndPedCreation fallara entre este aviso y ese resolve,
     PostSpawnPlayer no llegaria nunca y el jugador se quedaria plantado en el
     estudio de creacion para siempre. De ahi el plazo de gracia. ]]
AddEventHandler('origen_clothing:client:creationComplete', function()
    if not armado then return end
    CreateThread(function()
        Wait(2000)
        if armado and not lanzado then
            print('^3[origen_intro] PostSpawnPlayer no llego; se lanza por el aviso de creacion.^0')
            Lanzar()
        end
    end)
end)
