--[[ Con que sistemas de fuera habla el telefono.

     El telefono no guarda dinero, ni coches, ni casas. Los enseña. Cada una de
     esas cosas vive en otro recurso, y este fichero es el unico sitio donde se
     dice CUAL y COMO se le pregunta.

     Esta separado del resto de la configuracion a proposito. Lo de `config.lua`
     son decisiones de un servidor —cuanto cuesta un taxi, cuanto dura la
     bateria—; esto es fontaneria: que recurso tiene el dinero. Quien instala el
     telefono en un servidor con otro banco toca aqui y nada mas.

     COMO SE CAMBIA UN SISTEMA POR OTRO

     Cada bloque trae el nombre del recurso y el nombre de cada export que se le
     llama. Si el recurso nuevo tiene exports equivalentes, basta con cambiar los
     nombres. Si no los tiene, hay dos salidas:

       1. Escribir un recurso puente de veinte lineas que los exponga con estos
          nombres. Es lo mas limpio y no toca el telefono.
       2. Cambiar el adaptador en `server/bridges.lua`, que es donde vive la
          traduccion de "lo que devuelve ese recurso" a "lo que espera el
          telefono".

     Y SI NO HAY NINGUNO

     Cada aplicacion que depende de un sistema de fuera dice que no hay servicio
     cuando ese recurso no esta arrancado, en vez de fingir. Un banco que enseña
     un saldo inventado es peor que un banco que dice que esta caido.
]]

Config.Integrations = {}

--[[ EL BANCO -----------------------------------------------------------

     De aqui salen el saldo, los movimientos y las transferencias, y por aqui
     pasa TODO el dinero que mueve el telefono: comprar en el tablon, pagar un
     taxi, cobrar un reparto.

     Los exports de origen_banking devuelven { success = bool, message = str },
     no un booleano suelto. Si el banco que pongas devuelve otra cosa, hay que
     tocar `Succeeded` en `server/api/bank.lua`: darlo por bueno con un
     `if resultado then` deja pasar los pagos que han fallado, que es la peor
     forma de fallar que hay aqui —cobrar y no entregar. ]]
Config.Integrations.Banking = {
    resource = 'origen_banking',

    --- (citizenid) -> lista de cuentas a las que llega esa persona.
    accounts = 'GetAccountsInfoByCitizenId',

    --- (source, importe, motivo) -> cobra de su cuenta por defecto.
    charge = 'PayFromDefaultAcc',

    --- (source, importe, motivo) -> ingresa en su cuenta por defecto.
    deposit = 'ReceiveToDefaultAcc',
}

--[[ EL GARAJE ----------------------------------------------------------

     La aplicacion solo LEE: dice donde quedo cada coche y como esta. Sacarlo y
     guardarlo sigue siendo cosa de ir al garaje, que es lo que tiene sentido en
     rol y lo que evita que el telefono sea un mando a distancia de vehiculos.

     Hay dos caminos y se prueban en este orden:

       1. Si el recurso tiene un export que devuelva los vehiculos de un
          personaje, se usa ese. Es lo preferible: el recurso sabe cosas que la
          tabla no cuenta.
       2. Si no, se leen de la tabla de siempre. Los nombres de columna de abajo
          son los de qb/qbx, que es lo que usa casi todo el mundo.

     Con un garaje de esquema raro, lo sano es el camino 1: un export propio de
     diez lineas en vez de retorcer los nombres de aqui. ]]
Config.Integrations.Garage = {
    resource = 'origen_garages',

    --[[ (citizenid) -> lista de vehiculos. Vacio para usar la tabla.

         Se espera una lista de tablas con, al menos: plate, y a poder ser
         label/vehicle, garage, state, fuel, engine, body y depotprice. Lo que
         falte se enseña como desconocido en vez de inventarselo. ]]
    listVehicles = nil,

    --- El otro camino: la tabla y sus columnas.
    table = 'player_vehicles',
    columns = {
        owner = 'citizenid',
        plate = 'plate',
        fakeplate = 'fakeplate',
        model = 'vehicle',
        label = 'label',
        garage = 'garage',
        state = 'state',
        fuel = 'fuel',
        engine = 'engine',
        body = 'body',
        depotPrice = 'depotprice',
    },

    --[[ Que significa cada numero de `state`.

         En qb/qbx: 0 fuera, 1 guardado, 2 en el deposito. Un garaje que use
         otros numeros los mapea aqui y la aplicacion no se entera. ]]
    states = { [0] = 'out', [1] = 'stored', [2] = 'impounded' },
}

--[[ LAS PROPIEDADES ----------------------------------------------------

     Las casas del personaje: las suyas y aquellas de las que tiene llave. La
     aplicacion enseña donde estan y quien mas entra; abrir la puerta sigue
     siendo cosa de estar delante de ella.

     Igual que el garaje, dos caminos: los exports del recurso si los tiene, y
     si no la tabla. origen_housing los tiene, asi que de serie va por ahi. ]]
Config.Integrations.Housing = {
    resource = 'origen_housing',

    --- (citizenid) -> las casas de esa persona.
    ownedHouses = 'getOwnedHouses',

    --- (id) -> una casa concreta, con sus llaves y su sitio.
    getHouse = 'getHouse',

    --- (_, citizenid, houseId) -> si esa persona tiene llave de esa casa.
    hasKey = 'hasKey',

    --- El camino de la tabla, para un recurso que no tenga exports.
    table = 'origen_housing',
    columns = {
        id = 'id',
        owner = 'citizenid',
        name = 'name',
        --- Estos dos vienen como JSON: dentro van el precio, el sitio y las llaves.
        data = 'data',
        positions = 'positions',
        holders = 'holders',
    },
}
