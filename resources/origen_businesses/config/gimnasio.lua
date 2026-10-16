--[[ El negocio de tipo GIMNASIO (09/10).

     Un negocio como los demas (plantilla, caja, almacen, tienda...) que ademas
     coloca maquinas de entrenar desde Ajustes. Las maquinas no son puntos del
     negocio: son aparatos de origen_gym, con su catalogo, sus posturas y su
     entrenamiento, enlazados a este negocio. Aqui solo se decide quien puede
     tocarlas (el permiso «Ajustes») y se le pasa a origen_gym, que es quien
     guarda y quien comprueba el sitio.

     La membresia tambien es de origen_gym (Config.Negocio alli): el jefe pone
     el precio y los dias; se compra en la propia maquina y el dinero entra en
     la caja del negocio. Los empleados entrenan sin ella. ]]

Config.Gimnasio = {
    -- Tipos de negocio que son un gimnasio.
    Tipos = { gym = true },
    --[[ Cuantas maquinas caben lo pone la administracion en «Cuantos puntos
         caben» del panel de admin, como cualquier otro punto: es la clave
         `Punto` de available_points. Vale para CUALQUIER tipo de negocio (un
         hotel con su sala de maquinas). Un negocio de tipo gimnasio al que
         nadie le ha puesto numero tiene `PorDefecto`; con 0, ninguna. ]]
    Punto = 'maquina_gym',
    PorDefecto = 25,
}

Config.BusinessBlips['gym'] = { id = 311, color = 0, scale = 0.6 }

function Config.Gimnasio.Es(tipo)
    return Config.Gimnasio.Tipos[tipo or ''] == true
end

--- Cuantas maquinas puede poner un negocio. 0 es que no puede.
function Config.Gimnasio.Tope(tipo, available_points)
    local puesto = type(available_points) == 'table' and available_points[Config.Gimnasio.Punto]
    if type(puesto) == 'table' then puesto = puesto.max end
    puesto = tonumber(puesto)
    if puesto then return math.max(0, math.floor(puesto)) end
    return Config.Gimnasio.Es(tipo) and Config.Gimnasio.PorDefecto or 0
end
