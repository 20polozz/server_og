--[[ Trabajos comunitarios: la tercera salida que tiene el agente, junto a la
     Prisión Federal.

     Al condenado se le pone el uniforme y se le lleva a la zona. Allí le va
     saliendo un punto tras otro y en cada uno hace una tarea (barrer, soplar
     hojas, arreglar el jardín). Cuando ha hecho todas las tareas de la condena,
     queda libre y recupera su ropa.

     Lo cuenta todo el servidor (server/comunitarios.lua): cuántas tareas quedan,
     si estás de verdad en el punto, si has tardado lo que dura la tarea y si
     te has ido de la zona. El cliente solo pinta y pulsa. ]]

Config.Comunitarios = {
    -- Dónde se cumplen. El radio es para la fuga; los sitios de las tareas
    -- son los de `Puntos`, más abajo.
    Zona = {
        nombre = "Legion Square",
        centro = vector3(195.17, -933.77, 30.69),
        radio = 40.0,
    },

    -- Dónde aparece el condenado al empezar y cuando se le devuelve a la zona.
    Llegada = vector4(195.17, -933.77, 30.69, 140.0),

    -- A dónde se le lleva al terminar (o si un agente se la levanta): la
    -- puerta de Mission Row, la misma salida que usa Federal.
    Salida = vector4(480.9431, -977.4430, 27.9842, 3.83),

    -- Metros de más, fuera del radio, antes de contar que se ha ido.
    MargenFuga = 20.0,

    -- Tareas que se suman cada vez que se va de la zona.
    CastigoFuga = 5,

    -- Tope de tareas que puede poner un agente de una vez.
    MaxTareas = 100,

    -- Segundos que dura cada tarea.
    DuracionTarea = 10,

    -- Metros mínimos entre un punto y el siguiente: que tenga que andar.
    DistanciaEntrePuntos = 8.0,

    --[[ Los sitios de las tareas: { x, y, z del suelo, tipo de suelo }.

         Medidos en el juego el 21/09 (rayos desde arriba sobre una rejilla de
         3 m): suelo al aire libre, a la altura de la plaza, llano, con 2,4 m
         libres alrededor, fuera de la carretera, y con el material del suelo
         leído del propio juego. Después, 16 repartidos a 9 m como poco.

         Al azar dentro del radio salían sitios bajo los soportales y hasta
         en la azotea de un edificio. El servidor solo acepta los de esta
         lista. ]]
    Puntos = {
        { 223.17, -947.77, 29.09, "baldosa" },
        { 226.17, -905.77, 29.69, "baldosa" },
        { 199.17, -974.77, 29.09, "baldosa" },
        { 163.17, -959.77, 29.09, "baldosa" },
        { 208.17, -926.77, 29.69, "baldosa" },
        { 205.17, -893.77, 30.50, "baldosa" },
        { 160.17, -926.77, 29.11, "baldosa" },
        { 196.17, -950.77, 29.09, "baldosa" },
        { 193.17, -932.77, 29.69, "baldosa" },
        { 175.17, -923.77, 29.69, "baldosa" },
        { 208.17, -908.77, 29.69, "baldosa" },
        { 160.17, -911.77, 29.20, "baldosa" },
        { 187.17, -911.77, 29.69, "cesped" },
        { 178.17, -938.77, 29.09, "cesped" },
        { 172.17, -902.77, 29.69, "cesped" },
        { 181.17, -899.77, 29.69, "cesped" },
    },

    --[[ Lo que hay que hacer en cada punto. En el suelo aparece la basura
         (uno de los modelos de `basura`, al azar) y la tarea es quitarla: al
         acabar, desaparece. Así se ve qué se está haciendo y por qué.

         La animación y la herramienta son las de origen_anims (/broom,
         /leafblower), que ya se ven bien. Nada de escenarios del juego: el
         del conserje se queda quieto apoyado en la escoba y, al cortarlo, la
         deja tirada en el suelo. Aquí la herramienta la pone y la quita
         ox_lib. En el césped solo se recoge: barrer hierba no tiene sentido. ]]
    Trabajos = {
        {
            etiqueta = "Barrer",
            suelos = { baldosa = true },
            anim = { dict = "anim@amb@drug_field_workers@rake@male_a@base", clip = "base" },
            prop = { model = "prop_tool_broom", bone = 28422, pos = vec3(-0.01, 0.04, -0.03), rot = vec3(0.0, 0.0, 0.0) },
            basura = { "prop_rub_litter_03", "prop_rub_litter_03b", "prop_rub_litter_03c", "prop_rub_litter_04" },
        },
        {
            etiqueta = "Recoger la basura",
            suelos = { baldosa = true, cesped = true },
            anim = { dict = "random@domestic", clip = "pickup_low" },
            basura = { "prop_cs_rub_binbag_01", "prop_rub_binbag_01", "prop_rub_litter_01", "prop_rub_litter_02", "prop_rub_litter_05" },
        },
        {
            etiqueta = "Soplar la basura",
            suelos = { baldosa = true },
            anim = { dict = "amb@world_human_gardener_leaf_blower@base", clip = "base" },
            prop = { model = "prop_leaf_blower_01", bone = 28422, pos = vec3(0.0, 0.0, 0.0), rot = vec3(0.0, 0.0, 0.0) },
            basura = { "prop_rub_litter_03", "prop_rub_litter_03b", "prop_rub_litter_04" },
        },
    },

    --[[ El uniforme: { componente, prenda, textura }, con los números que da
         el juego (los mismos que SetPedComponentVariation).

         Camiseta blanca, chaleco reflectante amarillo, pantalón de trabajo y
         botas. Elegido el 21/09 con maniquíes en fila en el propio servidor:
         los números de otros trajes (el del constructor de 17mov) no valen
         aquí, porque la ropa añadida cambia la numeración y lo que no existe
         el juego lo deja en 0 sin avisar.

         1 máscara · 3 brazos · 4 pantalón · 5 mochila · 6 zapatos
         8 camiseta interior (aquí va el chaleco) · 9 antibalas · 10 dibujos
         11 camiseta de encima ]]
    Uniforme = {
        male = {
            { 1, 0, 0 },
            { 3, 0, 0 },
            { 4, 9, 0 },
            { 5, 0, 0 },
            { 6, 25, 0 },
            { 9, 0, 0 },
            { 10, 0, 0 },
            { 11, 1, 0 },
            { 8, 59, 0 },
        },
        female = {
            { 1, 0, 0 },
            { 3, 14, 0 },
            { 4, 3, 0 },
            { 5, 0, 0 },
            { 6, 25, 0 },
            { 9, 0, 0 },
            { 10, 0, 0 },
            { 11, 14, 0 },
            { 8, 36, 0 },
        },
    },

    -- Accesorios que se quitan con el uniforme (0 sombrero, 1 gafas).
    QuitarAccesorios = { 0, 1 },
}
