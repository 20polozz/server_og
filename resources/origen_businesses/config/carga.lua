--[[ Punto de carga del móvil en los negocios (30/09).

     El usuario: «un punto en los negocios que sea punto de carga; ahí se abre
     una interfaz, como dejar el móvil cargando, que tarde en cargarse al 100
     unos 5 min y que cada vez que la abra vea cuánto lleva».

     Decidido con él: el móvil SE QUEDA en el cargador (sale del inventario con
     su número y todo, y se recoge después). Desde el 30/09 (noche) la batería
     de origen_phone está encendida: el punto empieza en la batería que traía
     el móvil y al recogerlo se le pone la que ha cargado. ]]
Config.Carga = {
    Huecos = 4,              -- móviles a la vez en cada punto
    Minutos = 5,             -- de 0 a 100 %
    Alcance = 2.5,           -- m al punto para abrirlo, dejar y recoger
    Max = 2,                 -- puntos de carga por negocio sin que lo abra la administración
    --[[ Móvil olvidado (01/10, el usuario: «si nunca se saca, ese hueco queda
         bloqueado»): a los Olvido minutos de estar al 100 % sale del cargador
         a objetos perdidos. El hueco queda libre y su dueño lo recoge en
         CUALQUIER punto de carga. ]]
    Olvido = 30,

    -- El móvil de origen_phone (config/config.lua de ese recurso)
    Item = 'ognphone',
    MetaNumero = 'ognPhoneNumber',
    -- Donde se apunta la carga de un móvil SIN ESTRENAR (sin número todavía):
    -- origen_phone la lee al estrenarlo (Phones.Create)
    MetaBateria = 'ognBattery',

    --[[ El poste de carga (04/10, el usuario: «ya que tiene prop, quita el
         círculo del suelo y el blip ese volando, y usa ese prop»). Modelo
         propio, recurso [assets]/[props]/origen_modelos: 0,33 × 0,56 ×
         1,28 m, con el origen en la base. Cada cliente pinta el suyo
         (source/client/carga.lua) y solo los que tiene cerca. ]]
    Prop = 'prop_phone_charger',
    DistanciaProp = 60.0,    -- m a los que aparece el poste (se va 10 m más allá)
}
