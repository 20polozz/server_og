--[[ La tienda VIP (server/vip.lua).

     Una tienda de tipo `vip` solo vende la ropa que un admin haya metido en
     la VIP desde /gestionropa, y esa ropa deja de salir en las tiendas
     normales. Entra quien tenga alguno de estos roles en el Discord de
     Origen; los admins de origen_clothing entran siempre.

     Este fichero lo descargan los clientes: aqui solo van los ids de los
     roles, nunca el token del bot (ese vive en origen_admin). ]]

Config.Vip = {
    --- Ids de los roles de Discord que dan acceso, como texto.
    RolesDiscord = {
        '1549477819271348274', -- Clothing
    },

    --- Al ENTRAR en la tienda se pregunta siempre a Discord, sin cache: quien
    --- ha perdido el rol ya no entra. Al pagar vale la ultima respuesta si es
    --- de hace menos de estos minutos.
    MinutosDeCache = 5,

    MensajeSinAcceso = 'Esta tienda es solo para VIP de Origen.',
}
