-- ============================================================
-- ORIGEN POLICE — CONFIGURACIÓN DE SINCRONIZACIÓN CON DISCORD
-- ============================================================
-- Sincroniza rangos, divisiones y licencias en tiempo real entre
-- la tablet policial/sanitaria y Discord.
--
-- SOPORTA DISCORDS INDEPENDIENTES:
--   - Servidor de Discord Policial (police, sheriff, sapd)
--   - Servidor de Discord Médico / Sanitario (ambulance, ems, sams)
-- ============================================================

Config = Config or {}

Config.DiscordSync = {
    -- Habilitar o deshabilitar la integración global con Discord
    Enabled = true,

    -- Sincronizar automáticamente roles cuando un agente/médico entra al servidor
    SyncOnPlayerLoaded = true,

    -- ========================================================
    -- 1. DEPARTAMENTO POLICIAL (LSPD / Sheriff / SAPD / SASPA / FIB)
    -- ========================================================
    ['police'] = {
        -- ID del Servidor de Discord de Policía (Guild ID)
        GuildId = "718506945031700591",

        -- Token del bot en el servidor policial (con permiso 'Manage Roles')
        BotToken = "MTQ0NDA4ODcxNTA2MzQ2NDEzMw.G05sGG.e5Ctz9E4ocm9xcOGpeK-PMfqPecKmECnjt7aks",

        -- Webhook para auditoría y logs policiales (Opcional, dejar "" si no se usa)
        WebhookUrl = "",

        -- Rol base al pertenecer a cada cuerpo (otorgado al contratar, retirado al despedir)
        BaseJobRoles = {
            ['police']  = "", -- Ej: "123456789012345678" (Rol de LSPD)
            ['sheriff'] = "", -- Ej: "123456789012345678" (Rol de Sheriff / BCSO)
            ['sapd']    = "", -- Ej: "123456789012345678" (Rol de SAPD / Estatal)
        },

        -- Roles de Discord por Rango / Grado policial
        JobRoles = {
            ['police'] = {
                ['0']  = "", -- Dispatch
                ['1']  = "", -- Cadete
                ['2']  = "", -- Oficial I
                ['3']  = "", -- Oficial II
                ['4']  = "", -- Oficial III
                ['5']  = "", -- Oficial III+
                ['6']  = "", -- Detective I
                ['7']  = "", -- Detective II
                ['8']  = "", -- Sargento I
                ['9']  = "", -- Detective III
                ['10'] = "", -- Sargento II
                ['11'] = "", -- Teniente I
                ['12'] = "", -- Teniente II
                ['13'] = "", -- Capitan I
                ['14'] = "", -- Capitan II
                ['15'] = "", -- Comandante
            },
            ['sheriff'] = {
                ['0']  = "", -- Dispatch
                ['1']  = "", -- Deputy Sheriff Trainee
                ['2']  = "", -- Deputy Sheriff
                ['3']  = "", -- Deputy Sheriff I
                ['4']  = "", -- Deputy Sheriff II
                ['5']  = "", -- Bonus Deputy Sheriff
                ['6']  = "", -- Detective I
                ['7']  = "", -- Detective II
                ['8']  = "", -- Sargento I
                ['9']  = "", -- Detective III
                ['10'] = "", -- Sargento II
                ['11'] = "", -- Teniente I
                ['12'] = "", -- Teniente II
                ['13'] = "", -- Capitan I
                ['14'] = "", -- Capitan II
                ['15'] = "", -- Sheriff
            },
            ['sapd'] = {
                ['0'] = "", -- Jefa Supervisora SAPD
                ['1'] = "", -- Jefe Adjunto SAPD
                ['2'] = "", -- Director SAPD
            },
        },

        -- Roles de Discord por Escala de Mando / Jerarquía
        -- (Se otorgan y retiran automáticamente según la categoría del rango)
        EscalaRoles = {
            ['mando']        = "", -- Escala de Mando SAPD / Jefatura (Jefe Policía, Adjunto, Supervisor / Sheriff)
            ['ejecutiva']    = "", -- Escala Ejecutiva (Sargentos I/II, Tenientes, Capitanes)
            ['detectives']   = "", -- Escala de Detectives (Detective II, Detective III)
            ['basica_plus']  = "", -- Escala Básica + (Oficial III, Oficial III+, Detective I, Bonus Deputy, Deputy II)
            ['basica']       = "", -- Escala Básica (Oficial I, Oficial II, Deputy Sheriff, Deputy Sheriff I)
            ['academia']     = "", -- Academia (Cadetes, Deputy Sheriff Trainee, Dispatch)
        },

        -- Asignación de Grado a Escala (se auto-detecta por nombre si no se especifica)
        GradeEscalas = {
            ['police'] = {
                ['0']  = "academia",    -- Dispatch
                ['1']  = "academia",    -- Cadete
                ['2']  = "basica",      -- Oficial I
                ['3']  = "basica",      -- Oficial II
                ['4']  = "basica_plus", -- Oficial III
                ['5']  = "basica_plus", -- Oficial III+
                ['6']  = "basica_plus", -- Detective I
                ['7']  = "detectives",  -- Detective II
                ['8']  = "ejecutiva",   -- Sargento I
                ['9']  = "detectives",  -- Detective III
                ['10'] = "ejecutiva",   -- Sargento II
                ['11'] = "ejecutiva",   -- Teniente I
                ['12'] = "ejecutiva",   -- Teniente II
                ['13'] = "ejecutiva",   -- Capitan I
                ['14'] = "ejecutiva",   -- Capitan II
                ['15'] = "mando",       -- Comandante
            },
            ['sheriff'] = {
                ['0']  = "academia",    -- Dispatch
                ['1']  = "academia",    -- Deputy Sheriff Trainee
                ['2']  = "basica",      -- Deputy Sheriff
                ['3']  = "basica",      -- Deputy Sheriff I
                ['4']  = "basica_plus", -- Deputy Sheriff II
                ['5']  = "basica_plus", -- Bonus Deputy Sheriff
                ['6']  = "basica_plus", -- Detective I
                ['7']  = "detectives",  -- Detective II
                ['8']  = "ejecutiva",   -- Sargento I
                ['9']  = "detectives",  -- Detective III
                ['10'] = "ejecutiva",   -- Sargento II
                ['11'] = "ejecutiva",   -- Teniente I
                ['12'] = "ejecutiva",   -- Teniente II
                ['13'] = "ejecutiva",   -- Capitan I
                ['14'] = "ejecutiva",   -- Capitan II
                ['15'] = "mando",       -- Sheriff
            },
            ['sapd'] = {
                ['0'] = "mando",       -- Jefa Supervisora SAPD
                ['1'] = "mando",       -- Jefe Adjunto SAPD
                ['2'] = "mando",       -- Director SAPD
            }
        },

        -- Roles de Discord por División policial
        DivisionRoles = {
            ['EJEC_LSPD'] = "", -- Ejecutiva LSPD
            ['EJEC_BCSD'] = "", -- Ejecutiva BCSD
            ['METRO']     = "", -- Metropolitan Division
            ['SAHP']      = "", -- San Andreas Highway Patrol
            ['DB']        = "", -- Detective Bureau
            ['ASD']       = "", -- Air Support Division
            ['RTD']       = "", -- Recruitment & Training
            ['IAA']       = "", -- Asuntos Internos
            ['RS']        = "", -- Reinserción Social
            ['RRPP']      = "", -- Relaciones Públicas
            ['SWAT']      = "", -- SWAT
            ['K9']        = "", -- Unidad K9
        },

        -- Roles de Discord por Licencia policial
        LicenseRoles = {
            ['driver']   = "", -- Conducción
            ['weapon']   = "", -- Armas
            ['business'] = "", -- Negocios
            ['hunting']  = "", -- Caza
            ['fishing']  = "", -- Pesca
            ['pilot']    = "", -- Piloto
            ['tactical'] = "", -- Táctica
        },
    },

    -- ========================================================
    -- 2. DEPARTAMENTO SANITARIO (Ambulance / EMS / SAMS / Hospital)
    -- ========================================================
    ['ambulance'] = {
        -- ID del Servidor de Discord de Médicos / SAMUR (Guild ID)
        GuildId = "", -- Pon aquí el ID del servidor de Discord de Médicos

        -- Token del bot en el servidor de Médicos (puede ser el mismo si el bot está invitado en ambos servidores, o uno distinto)
        BotToken = "MTQ0NDA4ODcxNTA2MzQ2NDEzMw.G05sGG.e5Ctz9E4ocm9xcOGpeK-PMfqPecKmECnjt7aks",

        -- Webhook para auditoría y logs sanitarios (Opcional, dejar "" si no se usa)
        WebhookUrl = "",

        -- Rol base de Sanitario / Médico
        BaseJobRoles = {
            ['ambulance'] = "", -- Ej: "123456789012345678" (Rol de SAMS / Médico)
        },

        -- Roles de Discord por Rango / Grado sanitario
        JobRoles = {
            ['ambulance'] = {
                ['0'] = "", -- Médico en Prácticas
                ['1'] = "", -- Paramédico
                ['2'] = "", -- Médico Cirujano
                ['3'] = "", -- Jefe de Guardia
                ['4'] = "", -- Director Médico
            },
        },

        -- Roles de Discord por Escala Médica
        EscalaRoles = {
            ['mando']        = "", -- Dirección Médica / Jefatura de Guardia
            ['medica']       = "", -- Escala Médica (Médicos Cirujanos, Especialistas)
            ['basica']       = "", -- Escala Básica (Paramédicos, Técnicos)
            ['academia']     = "", -- Alumnos / Prácticas
        },

        -- Asignación de Grado a Escala sanitaria
        GradeEscalas = {
            ['ambulance'] = {
                ['0'] = "academia",
                ['1'] = "basica",
                ['2'] = "medica",
                ['3'] = "mando",
                ['4'] = "mando",
            }
        },

        -- Roles de Discord por División sanitaria
        DivisionRoles = {
            ['URG']     = "", -- Urgencias
            ['AIR_EMS'] = "", -- Rescate Aéreo Sanitario
            ['PSIQ']    = "", -- Psiquiatría
            ['RRPP']    = "", -- Relaciones Públicas Sanidad
        },

        -- Roles de Discord por Licencia sanitaria
        LicenseRoles = {
            ['cirugia']   = "", -- Habilitación Quirúrgica
            ['pilot_ems'] = "", -- Piloto de Helicóptero Médico
        },
    },
}
