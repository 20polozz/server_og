--[[ QUIEN MANDA CADA AVISO

     Todo el servidor acaba aqui: `lib.notify`, `QBCore.Functions.Notify`,
     `exports.origen_notify:Notify` y el evento de red. Son unas mil llamadas
     repartidas por setenta recursos, y de esas solo ciento cuarenta y siete
     traian un titulo. Las demas llegaban peladas.

     Eso, mientras los avisos salian arriba en el medio, daba igual: una barra
     gris con una linea de texto no necesita firma. Pero ahora salen en el
     TELEFONO, y en un telefono todo lo que llega lo manda alguien. Un aviso sin
     remitente se lee como un fallo del movil.

     Asi que aqui se decide, para cada aviso, DE QUIEN ES.

     "Tienes mucha hambre, deberias comer algo."   ->  Smartband
     "Has recibido $450 por la ruta."              ->  Banco de Los Santos
     "Bomba detectada en tu vehiculo."             ->  Sistema del vehiculo
     "Has entrado de servicio como Taxista."       ->  Central de Taxis

     NO SE REESCRIBE EL TEXTO

     El cuerpo del aviso llega como lo escribio su recurso y sale igual. Aqui
     solo se pone la firma. Reescribir mil textos a mano seria un trabajo que
     se rompe en cuanto alguien actualice cualquier recurso; poner el remitente
     es una tabla que se lee de arriba abajo y se entiende de un vistazo.

     EL ORDEN IMPORTA

     1. Lo que traiga puesto el propio aviso (`remitente`). Manda.
     2. Las reglas de TEXTO. Son las finas: hambre, dinero, llaves, multas.
        Van primero porque el mismo recurso manda cosas de remitentes
        distintos: origen_newjobs paga nominas Y da instrucciones de ruta.
     3. El RECURSO que lo manda. La red de seguridad: cubre los ochocientos
        avisos sin titulo de un plumazo.
     4. Y si nada encaja, la ciudad.

     LO QUE NO ES UN MENSAJE

     Las herramientas de construccion —crear zonas, colocar props, subir
     imagenes— no las manda nadie: son un editor hablandole a un admin. Esas se
     quedan arriba en el medio, donde siempre. Estan en `EN_PANTALLA`.
]]

Remitentes = {}

-- ---------------------------------------------------------------------------
--  El catalogo: quien puede firmar un aviso
-- ---------------------------------------------------------------------------

--[[ `app` es de donde sale el ICONO y nada mas.

     El telefono pinta el icono de la aplicacion que se le diga y el titulo que
     se le pase. No abre esa aplicacion al tocar el aviso —los avisos del
     servidor no abren nada—, asi que 'clock' para la pulsera no significa que
     la pulsera sea el reloj: significa que se pinta con el icono del reloj,
     que es lo mas parecido a una pulsera que hay en el cajon. ]]
local CATALOGO = {
    --- El cuerpo. Lo que llevas puesto en la muñeca y te mide.
    smartband    = { titulo = 'Smartband',              app = 'clock'       },

    --- Dinero.
    banco        = { titulo = 'Banco de Los Santos',    app = 'bank'        },
    facturas     = { titulo = 'Facturas',               app = 'invoices'    },
    multas       = { titulo = 'Multas de Tráfico',      app = 'fines'       },

    --- Trabajo.
    empleo       = { titulo = 'Oficina de Empleo',      app = 'mail'        },
    transportes  = { titulo = 'Central de Transportes', app = 'delivery'    },
    taxi         = { titulo = 'Central de Taxis',       app = 'taxi'        },
    negocio      = { titulo = 'Tu negocio',             app = 'invoices'    },

    --- Vehiculos.
    vehiculo     = { titulo = 'Sistema del vehículo',   app = 'vehicles'    },
    taller       = { titulo = 'Taller Mecánico',        app = 'vehicles'    },
    garaje       = { titulo = 'Garaje',                 app = 'vehicles'    },
    parking      = { titulo = 'Parking Municipal',      app = 'vehicles'    },
    dmv          = { titulo = 'Tráfico · DMV',          app = 'vehicles'    },
    concesion    = { titulo = 'Concesionario',          app = 'vehicles'    },
    gasolinera   = { titulo = 'Gasolinera',             app = 'vehicles'    },
    grua         = { titulo = 'Grúa',                   app = 'vehicles'    },

    --- Servicios de la ciudad.
    lspd         = { titulo = 'Central LSPD',           app = 'services'    },
    sams         = { titulo = 'SAMS',                   app = 'services'    },
    ayuntamiento = { titulo = 'Ayuntamiento',           app = 'services'    },
    prision      = { titulo = 'Penitenciaría',          app = 'services'    },
    metro        = { titulo = 'Metro de Los Santos',    app = 'map'         },
    emergencias  = { titulo = 'Emergencias',            app = 'services'    },

    --- Casa y cosas tuyas.
    inmobiliaria = { titulo = 'Inmobiliaria',           app = 'properties'  },
    tienda       = { titulo = 'Tienda',                 app = 'store'       },
    estudio      = { titulo = 'Estudio de Tatuajes',    app = 'ads'         },
    ropa         = { titulo = 'Probador',               app = 'store'       },

    --- Ocio.
    casino       = { titulo = 'Casino Diamond',         app = 'ads'         },
    club         = { titulo = 'Club Deportivo',         app = 'ads'         },
    caza         = { titulo = 'Club de Caza',           app = 'ads'         },
    pesca        = { titulo = 'Cofradía de Pescadores', app = 'ads'         },
    racing       = { titulo = 'Racing Hub',             app = 'ads'         },
    crew         = { titulo = 'Tu Crew',                app = 'ads'         },
    radio        = { titulo = 'Radio',                  app = 'music'       },
    galeria      = { titulo = 'Galería',                app = 'gallery'     },

    --- Los bajos fondos. Nadie firma con su nombre.
    contacto     = { titulo = 'Contacto',               app = 'darkchat'    },
    mercado      = { titulo = 'Mercado Negro',          app = 'blackmarket' },
    banda        = { titulo = 'Tu Banda',               app = 'darkchat'    },

    --- Cosas del propio movil y de la ciudad.
    telefono     = { titulo = 'Teléfono',               app = 'settings'    },
    ogn          = { titulo = 'OGN',                    app = 'ogn'         },
    admin        = { titulo = 'Administración',         app = 'settings'    },

    --- El que firma cuando no firma nadie mas.
    ciudad       = { titulo = 'Los Santos',             app = 'server'      },
}

-- ---------------------------------------------------------------------------
--  Sin tildes y en minusculas, para poder comparar
-- ---------------------------------------------------------------------------

--[[ Los textos del servidor estan escritos como se escribe en castellano: con
     tildes, con eñes y con mayusculas donde toca. Una regla que buscara
     "matricula" no encontraria "Matrícula", y escribir cada patron dos veces
     —con tilde y sin ella— seria una tabla el doble de larga y el doble de
     facil de equivocarse.

     UTF-8, byte a byte: en Lua un `string.lower` no toca las tildes. ]]
local TILDES = {
    ['á'] = 'a', ['é'] = 'e', ['í'] = 'i', ['ó'] = 'o', ['ú'] = 'u', ['ü'] = 'u',
    ['Á'] = 'a', ['É'] = 'e', ['Í'] = 'i', ['Ó'] = 'o', ['Ú'] = 'u', ['Ü'] = 'u',
    ['ñ'] = 'n', ['Ñ'] = 'n',
}

---@param texto string
---@return string
local function llano(texto)
    if type(texto) ~= 'string' then return '' end

    --- Minusculas primero: asi la tabla solo necesita el par de bytes en
    --- minuscula... salvo que `lower` no toca los multibyte, de ahi que esten
    --- las mayusculas acentuadas tambien en la tabla.
    return (texto:lower():gsub('\195[\128-\191]', function(par)
        return TILDES[par] or par
    end))
end

-- ---------------------------------------------------------------------------
--  1. Reglas de TEXTO — las finas
-- ---------------------------------------------------------------------------

--[[ Se leen EN ORDEN y gana la primera que encaje, asi que arriba va lo
     concreto y abajo lo general.

     Los patrones son de Lua, no expresiones regulares: `%d` es un digito y
     `%$` es un dolar literal. Se comparan contra el titulo y el cuerpo juntos,
     ya sin tildes y en minusculas. ]]
local REGLAS_TEXTO = {
    --- EL CUERPO. Lo primero de todo: es lo que mas se repite en una sesion.
    { 'hambre',                      'smartband' },
    { 'famelic',                     'smartband' },
    --- `%f` es la frontera de palabra: "sed" suelto y no el de "sedan".
    { '%f[%w]sed%f[%W]',             'smartband' },
    { 'deberias beber',              'smartband' },
    { 'deshidrat',                   'smartband' },
    { 'estres',                      'smartband' },
    { 'sangrand',                    'smartband' },
    { 'hemorragia',                  'smartband' },
    { 'estas herid',                 'smartband' },
    { 'hueso roto',                  'smartband' },
    { 'fractura',                    'smartband' },
    { 'sobredosis',                  'smartband' },
    { 'resaca',                      'smartband' },
    { 'borrach',                     'smartband' },
    { 'intoxicad',                   'smartband' },
    --[[ "Inconsciente" a secas no, que ese lo dice tambien el aviso de auxilio
         que sale hacia los medicos —"Ciudadano inconsciente requiere
         asistencia"— y ese no lo manda tu pulsera, lo manda SAMS. Lo que va a
         la pulsera es cuando el inconsciente eres tu. ]]
    { 'estas inconsciente',          'smartband' },
    { 'sin aliento',                 'smartband' },
    { 'estamina',                    'smartband' },
    { 'te sientes',                  'smartband' },
    { 'relajad',                     'smartband' },
    { 'has subido a nivel',          'smartband' },
    { 'nivel subido',                'smartband' },

    --- DINERO. Cobros, pagos y todo lo que mueve el saldo.
    { 'has recibido %$',             'banco'     },
    --- Y la nomina de qbx_core, que mete "tu salario de" en medio y no casaba
    --- con la de arriba.
    { 'salario',                     'banco'     },
    { 'ingresad',                    'banco'     },
    { 'nomina',                      'banco'     },
    { 'paycheck',                    'banco'     },
    { 'transferencia',               'banco'     },
    { 'se te ha cobrado',            'banco'     },
    { 'se te han cobrado',           'banco'     },
    { 'has pagado',                  'banco'     },
    { 'saldo',                       'banco'     },
    { 'no tienes suficiente dinero', 'banco'     },
    { 'dinero sucio',                'contacto'  },
    { 'mercado negro',               'mercado'   },
    { 'factura',                     'facturas'  },
    { 'multa',                       'multas'    },

    --- MATRICULAS. La falsa no la pone Trafico, obviamente.
    { 'matricula falsa',             'contacto'  },
    { 'matricula',                   'dmv'       },
    { 'permiso de conducir',         'dmv'       },
    { 'licencia de conducir',        'dmv'       },

    --[[ EL COCHE.

         El orden dentro de este bloque es la mitad del trabajo, porque casi
         todo lo que le pasa a un coche menciona el motor: la bomba se pone en
         el motor, el nitro se instala en el motor y el sabotaje es del motor.
         Si 'motor' fuera lo primero se lo llevaria todo.

         Asi que primero lo que se instala a escondidas, luego lo que se hace
         en un taller, y 'motor' el ultimo, para lo que no sea ni una cosa ni
         la otra. ]]
    { 'combustible',                 'gasolinera'},
    { 'deposito lleno',              'gasolinera'},
    { 'gasolina',                    'gasolinera'},
    { 'repostar',                    'gasolinera'},
    { 'manguera',                    'gasolinera'},

    --- Lo de debajo del capo que no ha puesto ningun taller.
    { 'localizador',                 'contacto'  },
    { 'inhibidor',                   'contacto'  },
    { 'detector de radar',           'contacto'  },
    { 'pinchos',                     'contacto'  },
    { 'sabotaje',                    'contacto'  },
    { 'sabotead',                    'contacto'  },
    { 'bomba',                       'contacto'  },

    --- Lo que si.
    { 'antilag',                     'taller'    },
    { 'nitro',                       'taller'    },
    { 'oxido nitroso',               'taller'    },
    { 'botella',                     'taller'    },
    { 'jaula de seguridad',          'taller'    },
    { 'reparad',                     'taller'    },
    { 'reparacion',                  'taller'    },
    { 'grua',                        'grua'      },
    { 'remolcad',                    'grua'      },

    --- Y lo que avisa el propio coche.
    { 'cinturon',                    'vehiculo'  },
    { 'llaves',                      'vehiculo'  },
    { 'ruedas reventadas',           'vehiculo'  },
    { 'maletero',                    'vehiculo'  },
    { 'control de crucero',          'vehiculo'  },
    { 'volte',                       'vehiculo'  },
    { 'motor',                       'vehiculo'  },

    --- SERVICIOS.
    { 'lspd',                        'lspd'      },
    { 'policia',                     'lspd'      },
    { 'comisaria',                   'lspd'      },
    { 'esposad',                     'lspd'      },
    { 'detenid',                     'lspd'      },
    { 'sams',                        'sams'      },
    { 'ambulancia',                  'sams'      },
    { 'paramedic',                   'sams'      },
    { 'hospital',                    'sams'      },
    { 'prision',                     'prision'   },
    { 'carcel',                      'prision'   },
    { 'ayuntamiento',                'ayuntamiento' },
    { 'metro',                       'metro'     },

    --- CASA.
    { 'inmobiliar',                  'inmobiliaria' },
    { 'vivienda',                    'inmobiliaria' },
    { 'alquiler',                    'inmobiliaria' },

    --- TRABAJO.
    { 'taxista',                     'taxi'      },
}

--[[ Y las FLOJAS, que van despues del recurso.

     "Turno finalizado" o "Has entrado de servicio" los dice todo el que tenga
     un trabajo, y cada trabajo tiene su central: el basurero lo oye de
     Transportes y el policia de la LSPD. Si estuvieran arriba con las demas,
     una palabra tan comun le quitaria el remitente bueno a media ciudad.

     Aqui abajo solo contestan cuando el recurso no ha sabido decir de quien
     es, que es justo para lo que sirven. ]]
local REGLAS_FLOJAS = {
    { 'de servicio',                 'empleo'    },
    { 'turno',                       'empleo'    },
    { 'contratad',                   'empleo'    },
    { 'despedid',                    'empleo'    },
}

-- ---------------------------------------------------------------------------
--  2. Reglas por RECURSO — la red de seguridad
-- ---------------------------------------------------------------------------

--[[ Aqui esta el grueso: los ochocientos avisos que llegan sin titulo. Si el
     texto no ha encajado con ninguna regla de arriba, el recurso que lo manda
     ya dice bastante de quien es.

     El valor puede ser un id del catalogo, o una funcion cuando un mismo
     recurso habla por varias bocas: `origen_newjobs` lleva siete trabajos
     distintos y cada uno tiene su central. ]]
local POR_RECURSO = {
    --- Los siete trabajos de origen_newjobs, por el titulo que ya traen.
    origen_newjobs = function(_, texto)
        if texto:find('taxi') then return 'taxi' end
        if texto:find('bus') or texto:find('parada') then return 'transportes' end
        if texto:find('camioner') or texto:find('remolque') then return 'transportes' end
        if texto:find('basur') then return 'transportes' end
        --- Mineria, carpinteria, granja avicola, oficina de trabajo.
        return 'empleo'
    end,

    --- El de las piezas del coche. Lo que se instala legal es del taller; lo
    --- que se instala a escondidas ya lo ha cogido una regla de texto.
    origen_plates          = 'taller',

    origen_racing = function(_, texto)
        if texto:find('crew') or texto:find('territorio') then return 'crew' end
        return 'racing'
    end,

    --- Dinero y papeles.
    origen_banking         = 'banco',
    origen_businesses      = 'negocio',
    origen_townhall        = 'ayuntamiento',

    --- Vehiculos.
    origen_garages         = 'garaje',
    org_parking            = 'parking',
    origen_dealership      = 'concesion',
    origen_carrental       = 'concesion',
    origen_fuel            = 'gasolinera',
    origen_boattow         = 'grua',
    origen_vehicleseats    = 'vehiculo',
    origen_vehiclesounds   = 'vehiculo',
    origen_vehicleclasses  = 'vehiculo',
    qbx_vehiclekeys        = 'vehiculo',
    qbx_seatbelt           = 'vehiculo',
    origen_customs         = 'taller',
    vehiclehandler         = 'taller',
    kq_link                = 'grua',

    --- Servicios.
    origen_police          = 'lspd',
    origen_ambulancejob    = 'sams',
    origen_wheelchair      = 'sams',
    origen_saspa           = 'prision',
    origen_metro           = 'metro',
    kq_emergency           = 'emergencias',
    policepepperspray      = 'lspd',
    origen_pems            = 'lspd',

    --- Casa y cosas tuyas.
    origen_housing         = 'inmobiliaria',
    origen_tattoos         = 'estudio',
    origen_clothing        = 'ropa',
    origen_prints          = 'galeria',
    origen_AlbumCards      = 'galeria',

    --- Ocio.
    origen_hunting         = 'caza',
    origen_fishing         = 'pesca',
    rcore_casino           = 'casino',
    origen_radio           = 'radio',
    origen_speaker         = 'radio',
    origen_minijuegos      = 'club',
    rcore_basketball       = 'club',
    rcore_bowling          = 'club',
    rcore_golf             = 'club',
    rcore_pingpong         = 'club',
    rcore_pool             = 'club',
    rcore_tennis           = 'club',

    --- Los bajos fondos.
    origen_blackmarket     = 'mercado',
    origen_robberies       = 'contacto',
    origen_weed            = 'contacto',
    origen_ilegalv2        = 'contacto',
    origen_carboosting     = 'contacto',
    origen_hostage         = 'contacto',
    origen_micro           = 'contacto',
    origen_graffiti        = 'contacto',
    origen_gangwars        = 'banda',
    headbag                = 'contacto',

    --[[ qbx_smallresources son veinte cosas en un mismo recurso: comida y
         drogas, teleports con codigo, control de crucero, cuentakilometros,
         placas falsas. Casi todo lo coge una regla de texto antes de llegar
         aqui; lo que queda es el editor de teleports, que es de admin. ]]
    qbx_smallresources = function(_, texto)
        if texto:find('configuracion')
            or texto:find('punto eliminado')
            or texto:find('pasaje eliminado')
        then
            return 'admin'
        end

        return 'ciudad'
    end,

    --- El movil, la ciudad y lo que no es de nadie.
    origen_phone           = 'telefono',
    origen_broadcast       = 'ogn',
    origen_quests          = 'ogn',
    origen_xp              = 'smartband',
    origen_habilidades     = 'smartband',
    origen_inventory       = 'smartband',
    origen_admin           = 'admin',
    origen_anticheat       = 'admin',
    qbx_core               = 'ciudad',
    origen_markers         = 'ciudad',
    -- Las zonas con reglas: los avisos de dentro («zona peatonal», «aqui no se
    -- saca nada») los firma la ciudad, que es de quien son las normas.
    origen_zones           = 'ciudad',
    origen_peds            = 'ciudad',
}

-- ---------------------------------------------------------------------------
--  3. Lo que NO va al telefono
-- ---------------------------------------------------------------------------

--[[ Un editor de zonas diciendo "Point #3 added" no lo manda nadie: es una
     herramienta hablandole al admin que la esta usando, con el raton en la
     mano y mirando el mapa. En el telefono se leeria como un mensaje de la
     ciudad escrito en ingles y sin sentido.

     Estos siguen saliendo arriba en el medio, que es donde siempre han estado
     y donde hacen falta: pegados a lo que estas haciendo. ]]
local EN_PANTALLA = {
    origen_uploader        = true,   -- subir imagenes al panel
    origen_propplacer      = true,   -- colocar props a mano
    origen_titlemenu       = true,   -- editor del menu de inicio
    origen_screens         = true,   -- editor de pantallas 3D
    origen_loadingasset    = true,
    origen_vehiclehandling = true,   -- editor de handling
    origen_secs            = true,
    ox_lib                 = true,   -- creador de zonas
    origen_notify          = true,
}

--[[ Y los avisos que son una TECLA, vengan de donde vengan.

     "Pulsa Y para aceptar o N para rechazar" con un contador de cinco segundos
     no es un mensaje: es una pregunta que se contesta ahora. En el telefono
     llega tarde por definicion. ]]
local ES_UNA_TECLA = {
    'pulsa %[?%w+%]? para',
    'presiona %[?%w+%]? para',
    'manten %[',
    '%[e%]',
    'para aceptar o',
    'para rechazar',
}

-- ---------------------------------------------------------------------------
--  Resolver
-- ---------------------------------------------------------------------------

--[[ Titulos que no aportan nada al cuerpo.

     Cuando un aviso trae titulo propio y ese titulo dice algo —"Bomba
     Detectada", "Ruta Finalizada"— se conserva metiendolo delante del cuerpo,
     porque ahi esta la mitad de la informacion. Pero "Error", "Aviso" o el
     nombre del recurso no son informacion: son relleno que ensuciaria el
     mensaje. ]]
local TITULOS_VACIOS = {
    ['error'] = true, ['aviso'] = true, ['atencion'] = true, ['info'] = true,
    ['exito'] = true, ['correcto'] = true, ['success'] = true, ['warning'] = true,
    ['notificacion'] = true, ['sistema'] = true, ['servidor'] = true,
    ['sin acceso'] = true, ['denegado'] = true, ['no disponible'] = true,
    ['sin permiso'] = true, ['cancelled'] = true, ['test'] = true,
}

---@param texto string  ya en llano
---@return boolean
local function esUnaTecla(texto)
    for i = 1, #ES_UNA_TECLA do
        if texto:find(ES_UNA_TECLA[i]) then return true end
    end

    return false
end

--[[ El remitente de un aviso.

     @param datos    table   el aviso tal cual sale del recurso
     @param recurso  string? quien ha llamado, si se sabe

     @return table|nil  { titulo, app, cuerpo } — o nil si esto no es un
                        mensaje y tiene que salir arriba en el medio. ]]
---@param datos table
---@param recurso string|nil
---@return table|nil
function Remitentes.De(datos, recurso)
    if type(datos) ~= 'table' then return nil end

    local cuerpo = datos.description or datos.text or datos.content
    if type(cuerpo) ~= 'string' or cuerpo:gsub('%s', '') == '' then return nil end

    local titulo = type(datos.title) == 'string' and datos.title or ''
    local texto  = llano(titulo .. ' ' .. cuerpo)

    --- Una tecla que se pulsa ahora no es un mensaje. Se queda arriba.
    if esUnaTecla(texto) then return nil end

    --- Y las herramientas del editor tampoco.
    if recurso and EN_PANTALLA[recurso] then return nil end

    -- ── 1. Lo que traiga puesto el aviso ─────────────────────────────────────
    local id = type(datos.remitente) == 'string' and datos.remitente or nil

    -- ── 2. Las reglas de texto ───────────────────────────────────────────────
    if not id then
        for i = 1, #REGLAS_TEXTO do
            if texto:find(REGLAS_TEXTO[i][1]) then
                id = REGLAS_TEXTO[i][2]
                break
            end
        end
    end

    -- ── 3. El recurso ────────────────────────────────────────────────────────
    if not id and recurso then
        local suyo = POR_RECURSO[recurso]

        if type(suyo) == 'function' then
            local ok, devuelto = pcall(suyo, datos, texto)
            id = ok and devuelto or nil
        else
            id = suyo
        end
    end

    -- ── 4. Las reglas flojas, que no pisan al recurso ────────────────────────
    if not id then
        for i = 1, #REGLAS_FLOJAS do
            if texto:find(REGLAS_FLOJAS[i][1]) then
                id = REGLAS_FLOJAS[i][2]
                break
            end
        end
    end

    -- ── 5. Y si no, la ciudad ────────────────────────────────────────────────
    local firma = CATALOGO[id or 'ciudad'] or CATALOGO.ciudad

    --[[ El titulo propio, delante del cuerpo, cuando dice algo.

         Se tira si es relleno ("Error"), si es el nombre del recurso, o si el
         cuerpo ya lo repite: "Matricula" + "Matricula actualizada: XYZ" se
         leeria dos veces. ]]
    local suyo = llano(titulo)

    if titulo ~= ''
        and not TITULOS_VACIOS[suyo]
        and not suyo:find('origen_', 1, true)
        and not llano(cuerpo):find(suyo, 1, true)
        and #titulo < 40
    then
        --- Sin puntuacion duplicada: "Ruta Finalizada. Has completado..."
        cuerpo = titulo:gsub('%s*[%.:!]%s*$', '') .. '. ' .. cuerpo
    end

    return { titulo = firma.titulo, app = firma.app, cuerpo = cuerpo }
end

--- Para mirarlo desde consola sin esperar a que pase algo.
--- Uso:  ognotify_remitente <texto...>
RegisterCommand('ognotify_remitente', function(_, args)
    local texto = table.concat(args, ' ')
    local firma = Remitentes.De({ description = texto ~= '' and texto or 'prueba' })

    if not firma then
        print('^3[origen_notify] Ese aviso NO va al telefono: sale arriba en el medio.^7')
        return
    end

    print(('^2[origen_notify] %s^7 · app=%s'):format(firma.titulo, firma.app))
    print(('  %s'):format(firma.cuerpo))
end, false)
