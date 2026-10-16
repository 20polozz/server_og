Config = {}

Config.LiveryModType = 48
Config.EnforceInterval = 3000

Config.ScanPacks = true
Config.UseEncryptedParts = true
Config.PackResources = {}
Config.CacheDir = ''
Config.PartTextureCandidates = {
    '%s',
    '%s_livery%d',
    'tstudio_blank_liv',
    'tstudio_blank_liv_ng',
    'tstudio_liv_lspd',
    'tstudio_liv_lssd',
    'tstudio_liv_mrpd',
    'tstudio_liv_sahp',
    'tstudio_liv_bp',
    'tstudio_liv_ebh',
    'tstudio_liv_fz',
    'tstudio_liv_mws',
    'tstudio_liv_noose',
    '66fastback_livery%d',
    '66fastback_livery1',
    '66fastback_livery2',
    '66fastback_livery3',
}

Config.AssetBaseConvar = 'origen_livery_asset_base'
Config.HttpPrefix = '/origen_livery'

Config.StorageDir = 'data/liveries'
Config.SchemaPath = 'sql/origen_livery.sql'

-- FXServer drops any HTTP request body over 5 MiB without a status code, so the socket just
-- dies instead of returning 413. Stay well under it and reject oversize payloads client-side.
Config.MaxUploadBytes = 4194304
Config.MaxUrlLength = 2048

Config.ApplyCooldown = 5000
Config.MaxDesignsPerPlayer = 50
Config.TicketTTL = 60000

--[[ Quién puede usar /livery: el permiso de origen_admin que lo abre (se da a
     un grupo desde el panel de admin, «Editor de liveries»). Lo comprueba el
     servidor en cada evento; el cliente solo pregunta para no abrir la
     pantalla en balde. Vacío = cualquiera. Sin origen_admin arrancado, nadie. ]]
Config.Permiso = 'origen_livery'

Config.DuiSize = 2048

--[[ Las liveries se cargan solo para los coches que tienes cerca, no todas las
     del servidor: cada una es una página de navegador de 2048 px dentro del
     juego y no caben cientos.

     MaxDuis        cuántas a la vez como mucho; si hay más cerca, las más
                    lejanas esperan.
     LoadDistance   metros a los que un coche con livery empieza a cargarla.
     UnloadDelay    milisegundos que se queda cargada después de alejarse,
                    para no descargar y volver a cargar al dar la vuelta.
     ScanInterval   cada cuánto se mira qué coches hay alrededor. ]]
Config.MaxDuis = 8
Config.LoadDistance = 150.0
Config.UnloadDelay = 15000
Config.ScanInterval = 1000

--[[ El editor de la NUI (/livery → Abrir editor).

     ExportSize     lado en píxeles de la livery que sale del editor. La DUI la
                    pinta a Config.DuiSize, así que por encima de eso no gana.
     MaxImageChars  tope de la imagen en base64. origen_uploader rechaza más de
                    10.000.000, así que no se sube de ahí.
     MaxDocChars    tope del documento con las capas (va a la columna `doc`).
                    Por debajo del max_allowed_packet de la base de datos: con
                    MariaDB por defecto son 16 MB.
     LatentBps      ritmo del envío latente al guardar y al abrir. Una livery
                    ronda el medio mega en WEBP; un diseño con fotos, varios.
     SaveCooldown   milisegundos entre dos guardados del mismo jugador. ]]
Config.Editor = {
    ExportSize = 2048,
    MaxImageChars = 9000000,
    MaxDocChars = 8000000,
    LatentBps = 4000000,
    SaveCooldown = 8000,
}

Config.RequireApproval = false
Config.AdminGroup = 'group.admin'

Config.SlotIdPattern = '^mod:%d+$'
Config.ModelPattern = '^[%w_]+$'
Config.HashPattern = '^%x+$'
