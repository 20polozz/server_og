Config.ReportPredefinedText = [[
🕛Fecha ~ Hora 
🚗
__
| Descripción del caso y del de cómo procede el operativo |

Número de sujetos:

Descripción de los sujetos:

Tipo de armas que portan: 

Número de rehenes: 

Procedimiento que se sigue: 

 Objetos incautados:
 | Agente:  RANGO Y NOMBRE |Sujeto: NOMBRE, APELLIDOS Y CID |Objetos retirados: 

 Zona de recogida de evidencias:
 Declaración de testigos:

Pendientes: | Sólo si queda pendiente algo, como contactar con algún testigo |

 MANDO: |  |
 NEGOCIADOR: | |
RESPONSABLE DEL INFORME: | |

En caso de que se requieran unidades especialistas
 | Rango, Nombre y DIVISIÓN |

]]
Config.DenunciaPredefinedText = [[
🕛Fecha ~ Hora
__
| Descripción de la denuncia y hechos ocurridos |

Número de sujetos implicados:

Descripción de los sujetos:

Tipo de armas que portan (si aplica): 

Objetos sustraídos/afectados:
 | Denunciante: NOMBRE Y APELLIDOS | 

 Declaración del denunciante / testigos:

Pendientes: | Sólo si queda pendiente algo, como contactar con algún testigo |

RESPONSABLE DE LA DENUNCIA: | |

]]

Config.MedicalReportPredefinedText = [[
🕛Fecha ~ Hora
__
FECHA Y HORA DE LA ATENCIÓN: 
NOMBRE DEL PACIENTE: 
DIAGNÓSTICO:
PROCEDIMIENTO:

MEDICACIÓN RECETADA:
SEGUIMIENTO A FUTURO:

]]

Config.Tags = {
    ['default'] = { -- The default tags of report if there isn't specific tags for a job
        "Altercado",
        "Armas de fuego",
        "Caso abierto",   -- Mismo que la traducción "OpenCase"
        "Caso cerrado",   -- Mismo que la traducción "CaseClosed"
        "Caso nulo",      -- Mismo que la traducción "NullCase"
        "FIB",            -- Special Shared Tag
        "SAPD",           -- Special Shared Tag
        "Maltrato animal",
        "Delito de seguridad vial",
        "Delito contra el medio ambiente",
        "Falsificación de documentos",
        "Drogas",
        "Informe de calidad",
        "Tentativa de homicidio",
        "Tentativa de homicidio (agente)",
        "Operativo policial",
        "Robo de importación",
        "Robo de vehículo",
        "Robo mayor",
        "Robo menor",
        "Secuestro",
        "Secuestro (agente)",
        "Denuncia",
        "Denuncia Tramitada",
        "Denuncia Rechazada",
        "Denuncia Cerrada",
        "Denuncia Resuelta"
    },
    ['police'] = 'default',
    ['sheriff'] = 'default',
    ['sapd'] = 'default',
    ['fib'] = 'default',
    ['ambulance'] = {
        "Urgencia médica",
        "Cita médica",
    }
}

-- DONT TOUCH ANYTHING BELOW THIS LINE
local targetTranslations = Translations or Config.Translations

if targetTranslations and targetTranslations.DivisionsData then
    local divisionsToAdd = {}
    for _, data in pairs(targetTranslations.DivisionsData) do
        if data.category == 'police' or data.category == 'sheriff' or data.category == 'sapd' then
            table.insert(divisionsToAdd, "Division: " .. data.name)
        end
    end
    table.sort(divisionsToAdd, function(a, b)
        return a:lower() < b:lower()
    end)
    for i = #divisionsToAdd, 1, -1 do
        table.insert(Config.Tags['default'], 1, divisionsToAdd[i])
    end
end

for k, v in pairs(Config.Tags) do
    if type(v) == 'string' then
        Config.Tags[k] = Config.Tags[v]
    end
end

if targetTranslations then
    targetTranslations.ReportTags = Config.Tags
end