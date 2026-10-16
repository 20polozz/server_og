--[[ LA CARPETA `custom/`: TU CÓDIGO, SIN TOCAR EL DEL TELÉFONO

     Todo lo que hay aquí se queda **abierto** cuando el recurso se cifra, así
     que puedes leerlo y cambiarlo. Y como vive fuera del núcleo, una
     actualización del teléfono no se lo lleva por delante.

     ES LO QUE HAY QUE TOCAR, Y LO ÚNICO

     Si algo se puede cambiar desde aquí, cámbialo aquí. Editar el núcleo
     —cuando tengas acceso a él— significa rehacer ese cambio en cada
     actualización, y acordarte de cuál era.

     CÓMO FUNCIONA

     Cada función de `Custom` empieza devolviendo `nil`. Devolver `nil` quiere
     decir «no me meto, haz lo de siempre». En cuanto devuelves cualquier otra
     cosa, mandas tú.

     Esa es la diferencia entre esto y editar el núcleo: aquí puedes cambiar
     una sola cosa y dejar las otras cuarenta como estaban.

     DÓNDE VA CADA COSA

       custom/shared/    Esto: la tabla y la documentación. Se carga en los dos.
       custom/server/    Lo que decide o mueve datos: dinero, permisos, avisos.
       custom/client/    Lo que se ve o se oye en la pantalla del jugador.
]]

Custom = Custom or {}
