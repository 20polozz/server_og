--[[ Los avisos del propio servidor, dentro del telefono.

     Lo que salia arriba en el medio —lo de `origen_notify`— pasa a salir en el
     movil, con el titulo del servidor y su icono, para que se sepa de un vistazo
     que eso no lo manda nadie: lo manda la ciudad.

     SE MUEVE, NO SE COPIA

     Sale en el telefono Y YA NO ARRIBA. Verlo en los dos sitios es leer dos
     veces lo mismo. Quien prefiera las dos, `Config.ServerNotifications.Replace`
     a false.

     PERO SOLO SI HAY TELEFONO

     Es la parte delicada. Si aqui se cogiera todo por costumbre, alguien sin
     movil encima —le acaban de robar, no se lo ha comprado, esta empezando— se
     quedaria sin ver un solo aviso del servidor y sin saber por que. Por eso lo
     que aqui no se coge sigue saliendo arriba como toda la vida.

     NO SE GUARDAN

     No cuentan como no leidas y no abren ninguna aplicacion: salen y se van.
     Guardar cada "has cobrado 40" en el centro de notificaciones lo llenaria de
     ruido en media hora.

     Y NO SUENAN DE SERIE

     De estos pasan decenas por sesion, y un tono cada vez cansa. Se enciende en
     `Config.ServerNotifications.Sound` para quien lo quiera.

     LOS DE AYUDA NO ENTRAN

     El "pulsa E para interactuar" va por otro camino —`DrawText`, en su propio
     fichero— y no pasa por aqui. Eso es una tecla que se puede pulsar ahora
     mismo, no algo que contarte: en el telefono no pinta nada.
]]

Servidor = {}

--- El ultimo aviso y cuando, para no repetirlo.
local ultimo, cuando = nil, 0

--[[ Por que se ha dicho que no, cada vez.

     Cinco motivos y desde fuera se ven todos igual: el aviso sale arriba en el
     medio y no en el telefono. Contarlos es la unica forma de saber cual es. ]]
local motivos = { cogidos = 0, apagado = 0, sinTelefono = 0, sinTexto = 0, tipo = 0, repetido = 0 }

--[[ El aviso que llega de fuera.

     Se le llama desde `origen_notify`, que es por donde pasan todos: sus dos
     exports, su evento de red y la llamada que intercepta. Un solo sitio.

     LO QUE DEVUELVE ES UNA RESPUESTA, NO UN "HA IDO BIEN"

     `true` quiere decir "de este me hago cargo yo", y con eso el de arriba en
     el medio se calla. `false` quiere decir "este no lo cojo", y entonces sale
     arriba como toda la vida.

     De ahi que no coger uno sea tan importante como cogerlo: quien no lleva
     telefono encima tiene que seguir viendo los avisos del servidor. Devolver
     `true` por costumbre lo dejaria ciego sin que nadie se enterara.

     Aguanta lo que le echen porque quien llama es otro recurso: si algun dia
     manda algo que no es una tabla, o un texto vacio, aqui no revienta nada. ]]
---@param datos table
---@return boolean seHaceCargo
function Servidor.Aviso(datos)
    local ajustes = Config.ServerNotifications

    if not ajustes or ajustes.Enabled == false then
        motivos.apagado = motivos.apagado + 1
        return false
    end

    if type(datos) ~= 'table' then return false end

    --[[ Sin telefono, ni tocarlo.

         Es el caso que hay que cuidar: si aqui se dijera que si, alguien sin
         movil encima —le acaban de robar, no se lo ha comprado, esta empezando—
         se quedaria sin ver un solo aviso del servidor y sin saber por que. ]]
    if not Phone.awake then
        motivos.sinTelefono = motivos.sinTelefono + 1
        return false
    end

    --- Lo que se lee. Sin texto no hay aviso que enseñar.
    local texto = datos.description or datos.text or datos.content
    if type(texto) ~= 'string' or texto:gsub('%s', '') == '' then
        motivos.sinTexto = motivos.sinTexto + 1
        return false
    end

    --[[ Solo los tipos que se quieran.

         Vacio o sin poner = todos, que es lo normal. Sirve para dejar fuera los
         'success' de cobrar dinero, que son los que mas se repiten. ]]
    local tipos = ajustes.Types
    if type(tipos) == 'table' and next(tipos) ~= nil then
        local suyo = datos.type or 'primary'

        if not tipos[suyo] then
            motivos.tipo = motivos.tipo + 1
            return false
        end
    end

    --[[ El mismo aviso dos veces seguidas, no.

         Hay recursos que mandan el mismo texto en dos sitios del mismo codigo,
         y con el telefono asomando por abajo eso se ve. Arriba en el medio se
         apilaban y no se notaba. ]]
    local ahora = GetGameTimer()
    local espera = ajustes.Cooldown or 1500

    --- Se hace cargo igual: es que lo tira a proposito, no que no lo quiera.
    if texto == ultimo and (ahora - cuando) < espera then
        motivos.repetido = motivos.repetido + 1
        return true
    end

    ultimo, cuando = texto, ahora

    --[[ El titulo que traiga, y el del servidor solo si no trae ninguno.

         Los avisos vienen con el suyo —"[ASIGNACION-LSPD] Cadete ...", "Banco
         de Los Santos", "Central"— y machacarlo con una palabra fija es tirar
         justo lo que dice de que va. ]]
    local titulo = datos.title

    if type(titulo) ~= 'string' or titulo:gsub('%s', '') == '' then
        titulo = Locale.Say('notification_server')
    end

    --[[ Y el icono del remitente, cuando lo trae.

         `origen_notify` firma cada aviso antes de mandarlo —la pulsera, el
         banco, la central de tu trabajo— y dice con que icono se pinta. Sin
         eso, cincuenta remitentes distintos saldrian todos con la antena de la
         ciudad y el titulo seria lo unico que los diferenciara.

         El de la ciudad sigue siendo el de reserva: para lo que no lleva firma
         —un aviso de un recurso que llama al telefono por su cuenta— la antena
         es exactamente lo que toca. ]]
    local app = datos.app

    if type(app) ~= 'string' or app == '' then app = 'server' end

    exports[GetCurrentResourceName()]:ShowNotification({
        app = app,
        title = titulo,
        content = texto,
        --- De estos pasan decenas por sesion: un tono cada vez cansa.
        silent = ajustes.Sound ~= true,
    })

    --[[ Se hace cargo, salvo que este puesto para copiar en vez de mover: en
         ese caso se dice que no y sale tambien arriba en el medio. ]]
    motivos.cogidos = motivos.cogidos + 1

    return ajustes.Replace ~= false
end

--- Como va la cosa, para el informe.
---@return string
function Servidor.Cuenta()
    return ('cogidos=%d | no: apagado=%d sin-telefono=%d sin-texto=%d tipo=%d repetido=%d')
        :format(motivos.cogidos, motivos.apagado, motivos.sinTelefono,
            motivos.sinTexto, motivos.tipo, motivos.repetido)
end

--- Y como se le llama desde fuera.
exports('ShowServerNotification', Servidor.Aviso)

--[[ Tambien por evento, por si el recurso de avisos no puede llamar exports.

     Es de red a proposito: asi el servidor puede mandar un aviso de ciudad a
     alguien sin que ese aviso sea de ninguna aplicacion. ]]
RegisterNetEvent('origen_phone:cl:serverNotify', function(datos)
    Servidor.Aviso(type(datos) == 'table' and datos or { description = tostring(datos) })
end)

--[[ POR QUE ESE AVISO HA SALIDO ARRIBA EN EL MEDIO

     La pregunta se hace sola en cuanto uno ve un aviso donde no lo esperaba, y
     desde fuera los cinco motivos se ven exactamente igual. Los contadores ya
     estaban —`Servidor.Cuenta`— pero solo salian de rebote en el informe de la
     voz, que no es donde uno los va a buscar.

     Uso:  ogphone_avisos

     Lo normal, y con diferencia, es `sin-telefono`: al morir se suelta el
     aparato y hasta que se vuelve a enganchar —unos segundos— los avisos salen
     arriba, que es justo lo que hay que hacer para que nadie se quede sin
     verlos. Lo mismo los primeros segundos de sesion. ]]
RegisterCommand('ogphone_avisos', function()
    local ajustes = Config.ServerNotifications or {}

    print('^5── Avisos del servidor ──────────────────────────────^7')
    print(('  enganchado a la red : %s'):format(
        Phone.awake and '^2si^7' or '^1no — por eso salen arriba en el medio^7'))
    print(('  encendido           : %s'):format(
        ajustes.Enabled == false and '^1no^7' or '^2si^7'))
    print(('  mueve o copia       : %s'):format(
        ajustes.Replace == false and 'copia — salen en los dos sitios' or 'mueve'))
    print(('  %s'):format(Servidor.Cuenta()))
    print('^5─────────────────────────────────────────────────────^7')
end, false)

