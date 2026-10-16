--[[
    Como se reparten los codigos de radio en el menu rapido.

    La tabla `origen_police_radio_codes` guarda el codigo, lo que se canta y si
    levanta un aviso, pero NO a que se refiere. Sin eso, la pantalla solo puede
    enseñar una lista larga y plana: treinta codigos seguidos donde da lo mismo
    buscar "voy a comisaria" que "vehiculo robado".

    Aqui se dice a que apartado va cada uno. Es config y no base de datos a
    proposito: el panel de administracion no tiene donde meter este dato, y un
    apartado nuevo no vale un ALTER TABLE. Se toca este fichero, `refresh` y
    `restart origen_police`.

    Reglas:
      · Un codigo que no este en ninguna lista cae en su apartado por
        `action_type` —contar tu estado (rpol) o levantar algo a la central
        (dispatch)— y, si tampoco, en "Otros". Nunca desaparece.
      · Las urgencias no se ponen aqui: se sacan solas a la cabecera de la
        pantalla, que es donde tienen que estar.
      · Los nombres de los codigos son los de la columna `label`, tal cual,
        con sus puntos y sus mayusculas.
]]

Config = Config or {}

Config.RadioCodeGroups = {
    {
        title = 'Tu estado',
        codes = { '10.8', '10.10', 'Cod 7', 'Cod 2', '6-Adam', '10.22', '10.98', '10-97' },
    },
    {
        title = 'Aviso y posición',
        codes = { '10-20', '10-22', '10.6', '10-46', 'Cambio Jurisdiccion' },
    },
    {
        title = 'Vehículos',
        codes = { '254-V', '487-V', 'Veh 488', 'Veh 487', 'Veh Alt' },
    },
}
