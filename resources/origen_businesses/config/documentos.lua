--[[
    LOS DOCUMENTOS DEL NEGOCIO

    Desde la pestaña Documentos del panel, quien tenga «Hacer documentos»
    (`make_documents`, el jefe siempre) rellena una plantilla, la firma
    dibujándola con el ratón y se lleva el papel al inventario. Son gratis.

    Dos formatos, dos objetos del inventario:
      hoja      documento_negocio   contrato, recibo, documento libre
      tarjeta   tarjeta_negocio     tarjeta de visita, carné de empleado

    El objeto solo lleva el `docId`: lo que pone el documento, las firmas y
    quién lo hizo viven en la tabla origen_businesses_documentos, así que no
    se falsifica tocando la metadata. Al usarlo se abre para leerlo.

    Los que llevan DOS FIRMAS (el contrato siempre; el libre si se marca) salen
    firmados solo por el negocio. Se le pasa el papel a la otra parte (Dar, en
    el inventario) y al usarlo le sale para firmar; el nombre de quien firma lo
    pone el servidor, no se escribe. Ver source/server/documentos.lua.

    Cada campo: key, label, tipo ('texto' una línea | 'largo' varias),
    max (caracteres), obligatorio, y un ejemplo para el hueco vacío.
]]

Config = Config or {}

Config.Documentos = {
    Plantillas = {
        {
            id = 'contrato', formato = 'hoja', icono = 'lucide:file-signature',
            label = 'Contrato de trabajo', titulo = 'Contrato de trabajo',
            dosFirmas = true,
            campos = {
                { key = 'trabajador', label = 'Trabajador', tipo = 'texto', max = 60, obligatorio = true, ejemplo = 'Nombre y apellidos' },
                { key = 'puesto',     label = 'Puesto',     tipo = 'texto', max = 40, obligatorio = true, ejemplo = 'Cocinero' },
                { key = 'sueldo',     label = 'Sueldo',     tipo = 'texto', max = 30, ejemplo = '450 $ por nómina' },
                { key = 'horario',    label = 'Horario',    tipo = 'texto', max = 60, ejemplo = 'De tarde, de lunes a viernes' },
                { key = 'duracion',   label = 'Duración',   tipo = 'texto', max = 40, ejemplo = 'Indefinido' },
                { key = 'clausulas',  label = 'Cláusulas',  tipo = 'largo', max = 1500, ejemplo = 'Lo que se compromete cada parte' },
            },
        },
        {
            id = 'recibo', formato = 'hoja', icono = 'lucide:receipt-text',
            label = 'Recibo', titulo = 'Recibo',
            campos = {
                { key = 'concepto', label = 'Concepto', tipo = 'texto', max = 80, obligatorio = true, ejemplo = 'Reparación del motor' },
                { key = 'importe',  label = 'Importe',  tipo = 'texto', max = 30, obligatorio = true, ejemplo = '1.200 $' },
                { key = 'cliente',  label = 'Cliente',  tipo = 'texto', max = 60, ejemplo = 'A nombre de quién' },
                { key = 'notas',    label = 'Notas',    tipo = 'largo', max = 600 },
            },
        },
        {
            id = 'libre', formato = 'hoja', icono = 'lucide:file-text',
            label = 'Documento libre', titulo = 'Documento',
            -- Se puede pedir la firma de la otra parte (una compraventa, un acuerdo…).
            dosFirmasOpcional = true,
            campos = {
                { key = 'cuerpo', label = 'Texto', tipo = 'largo', max = 2500, obligatorio = true, ejemplo = 'Lo que quieras que ponga' },
            },
        },
        {
            id = 'tarjeta', formato = 'tarjeta', icono = 'lucide:id-card',
            label = 'Tarjeta de visita', titulo = 'Tarjeta de visita',
            -- Una tarjeta de visita no se firma, y se hacen varias de golpe.
            sinFirma = true, copias = 20,
            campos = {
                { key = 'nombre',   label = 'Nombre',   tipo = 'texto', max = 40, obligatorio = true, ejemplo = 'Nombre en grande' },
                { key = 'cargo',    label = 'Cargo',    tipo = 'texto', max = 40, ejemplo = 'Encargada' },
                { key = 'telefono', label = 'Teléfono', tipo = 'texto', max = 20, ejemplo = '555-0142' },
                { key = 'lema',     label = 'Lema',     tipo = 'texto', max = 60, ejemplo = 'Las mejores hamburguesas de Vespucci' },
            },
        },
        {
            id = 'carne', formato = 'tarjeta', icono = 'lucide:badge',
            label = 'Carné de empleado', titulo = 'Carné de empleado',
            campos = {
                { key = 'nombre', label = 'Nombre',       tipo = 'texto', max = 40, obligatorio = true, ejemplo = 'Nombre y apellidos' },
                { key = 'puesto', label = 'Puesto',       tipo = 'texto', max = 40, obligatorio = true, ejemplo = 'Camarero' },
                { key = 'numero', label = 'Nº empleado',  tipo = 'texto', max = 16, ejemplo = '0042' },
            },
        },
    },

    TituloMax = 60,
    -- Tope de una firma como PNG en base64. Una firma real ronda 5–15 KB; un
    -- evento de red no debe pasar de ~50 KB (ver origen-subir-imagenes).
    FirmaMax = 45000,
    -- Segundos entre dos documentos del mismo jugador, y entre dos «enseñar».
    Ritmo = 4,
    -- A cuántos metros tiene que estar alguien para enseñarle un documento.
    DistanciaEnsenar = 3.0,
    -- Cuántos documentos emitidos enseña la lista del panel.
    Lista = 25,
}

--- La plantilla con ese id, o nil.
function Config.Documentos.Plantilla(id)
    for _, p in ipairs(Config.Documentos.Plantillas) do
        if p.id == id then return p end
    end
    return nil
end

--- El objeto del inventario de un formato.
function Config.Documentos.Objeto(formato)
    return formato == 'tarjeta' and 'tarjeta_negocio' or 'documento_negocio'
end
