--[[ Catalogo de widgets.

     La misma idea que el de aplicaciones: esta lista es la del SERVIDOR, y es
     la que decide quien puede tener cada widget. La interfaz trae sus dibujos y
     sus componentes, pero si un widget no esta aqui no se le ofrece a nadie.

     Hace falta que exista aqui —y no solo en la interfaz— porque los permisos
     se deciden en el servidor: sin esta lista, quien administra no tendria que
     marcar en el panel, y tocar el cliente bastaria para colarse en un widget
     que no te toca.

     fuente:  'propio' el telefono ya sabe llenarlo
              'fuera'  lo llena otro recurso con SetWidgetData

     El tamaño no esta aqui a proposito: es cosa de como se dibuja, y eso lo
     sabe la interfaz. Aqui solo esta lo que hace falta para decidir permisos.
]]

Widgets = Widgets or {}

Widgets.Catalogo = {
    { id = 'weather',     label = 'Reloj y clima',       fuente = 'propio' },
    { id = 'bank',        label = 'Banco',               fuente = 'propio' },
    { id = 'trabajo',     label = 'Trabajo y turno',     fuente = 'fuera'  },
    { id = 'emergencias', label = 'Llamada de emergencia', fuente = 'propio' },
    { id = 'multas',      label = 'Multas y facturas',   fuente = 'propio' },
    { id = 'garaje',      label = 'Garaje',              fuente = 'propio' },
    { id = 'negocio',     label = 'Negocio',             fuente = 'fuera'  },
    { id = 'facciones',   label = 'Facciones en servicio', fuente = 'propio' },
    { id = 'ruta',        label = 'Ruta GPS',            fuente = 'propio' },
    { id = 'radio',       label = 'Radio',               fuente = 'fuera'  },
    { id = 'anuncios',    label = 'Anuncios',            fuente = 'propio' },
    { id = 'battery',     label = 'Bateria',             fuente = 'propio' },
    { id = 'activity',    label = 'Pendiente',           fuente = 'propio' },
}
