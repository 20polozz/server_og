--[[ De quién es una casa y cuántas llaves admite (custom/server/propietario.lua).

     Al crear (o editar) una casa se elige el tipo de propietario:
       · 'particular'  la de siempre.
       · 'banda'       de una banda de origen_ilegalv2 (data.grupo = id de la banda).
       · 'crew'        de un crew de origen_racing     (data.grupo = id del crew).
     Una casa sin `data.uso` (todas las de antes) es particular.

     Las llaves se cuentan SIN el dueño: él no gasta ninguna.
       · Particular: `llaves.particular` llaves.
       · De banda o de crew: sin límite para quien sea miembro de esa banda o
         crew, y `llaves.deFuera` para los demás. Quien deja el grupo pasa a
         contar como «de fuera»: si con él se supera el tope, pierde la llave.
     A las casas que ya tenían más llaves de la cuenta no se les quita ninguna:
     solo no se pueden dar más. ]]
Config.Propietario = {
    llaves = {
        particular = 3,     -- casa particular (además del dueño)
        deFuera = 3,        -- casa de banda/crew: gente que no es del grupo (además del dueño)
        -- Tope técnico de llaves por casa, cuenten o no (la lista entera viaja
        -- a los clientes en cada cambio). Sustituye a Config.LimitOfKeyHolders.
        topeTecnico = 250,
    },

    -- Cada cuánto se repasa quién sigue en la banda o en el crew (segundos).
    -- También se repasa la casa justo antes de dar una llave.
    revision = {
        alArrancar = 30,
        cada = 600,
    },

    --[[ Casa de banda: va DENTRO del territorio PRINCIPAL de su banda, el de
         origen (origen_gangs.base_territory_id), que se le pone a la banda en
         el panel de admin de bandas.
           · La zona exterior (donde se pueden poner muebles fuera) es ese
             territorio entero. No se dibuja nunca.
           · La entrada de la casa (y su punto de garaje) solo se puede poner
             dentro de su polígono, sin margen. Lo mira el servidor al crear y
             al editar; el cliente pinta el contorno mientras se coloca.
           · Una banda sin territorio principal no puede tener casa de banda.
         Casa de crew: IGUAL, con el territorio que se le dibuja y se le da a la
         crew en el panel de admin de crews de origen_racing (ficha de la crew →
         «Territorio de la casa»; export GetCrewTerritory). Ese territorio solo
         sirve para esto: no se captura ni sale en el mapa de territorios.
         Una crew sin territorio no puede tener casa de crew. ]]
    territorio = {
        -- false: las casas de banda y de crew se quedan como las demás (zona
        -- dibujada a mano y entrada donde se quiera). Solo para apagar la regla.
        activo = true,
        -- Alto de la zona (metros, mitad hacia arriba y mitad hacia abajo
        -- desde la entrada): los territorios se dibujan en el mapa, sin altura.
        grosor = 600.0,
        -- Los muebles de fuera se cargan hasta el vértice más lejano del
        -- territorio más este margen (en vez de Config.RenderDistance).
        margenRender = 60.0,
        -- El contorno que se pinta mientras se coloca la entrada: cuánto sube
        -- y cuánto baja el muro desde donde está quien la coloca (metros).
        muroArriba = 40.0,
        muroAbajo = 80.0,
    },

    -- En qué se paga lo que se compra para la casa (muebles, obra, imágenes,
    -- mejoras, estilo, cupos): particular, dinero de siempre; de banda, dinero
    -- negro (este objeto del inventario, 1 $ = 1); de crew, OGN (`factor` OGN
    -- por cada dólar del precio). custom/server/moneda.lua
    cobro = {
        negro = { item = 'black_money' },
        ogn = { factor = 1 },
    },

    -- De dónde salen las bandas y los crews. Housing no depende de ninguno:
    -- si no están arrancados, la opción sale desactivada y nadie cuenta como miembro.
    recursos = {
        bandas = 'origen_ilegalv2',
        crews = 'origen_racing',
    },
}
