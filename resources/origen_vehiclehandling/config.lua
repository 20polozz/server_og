Config = {}

Config.Debug = false

-- Default handling presets loaded on resource start.
Config.Vehicles = {
    -- ['Police'] = {
    --     ['hvaleutian'] = { maxSpeed = 220.0, driveForce = 0.35, gears = 6, shiftSpeed = 1.2 },
    -- },
}

Config.CheckInterval = 2000
Config.Hotkey = 'F4' -- Default key to open handling on current vehicle.
Config.FocusHotkey = 'LMENU' -- Default key to toggle NUI focus.

-- Active locale key.
Config.Locale = 'es'

-- Translation dictionary (store-ready).
Config.Locales = {
    en = {
        -- Generic
        confirm = 'Confirm',
        notice = 'Notice',
        close = 'Close',
        cancel = 'Cancel',
        save = 'Save',
        saveDb = 'Save DB',
        discard = 'Discard',
        searchModelPlaceholder = 'Search model...',
        noResults = 'No results',
        all = 'All',
        categories = 'Categories',
        model = 'Model',
        category = 'Category',
        actions = 'Actions',
        previous = 'Previous',
        next = 'Next',
        page = 'Page',
        currentCategory = 'Current category',
        undefined = 'Undefined',
        focusHint = 'Press G to toggle focus',
        focus = 'Focus',
        vehicles = 'Vehicles',
        draft = 'Draft',

        -- Lo que pide la barra de datos de abajo
        all = 'All',
        categories = 'Categories',
        shown = 'Shown',
        drafts = 'Unsaved',
        noFocus = 'No mouse',
        noVehicles = 'No vehicles yet',

        -- Main menu
        mainTitle = 'OGN Vehicle Handling',
        catalogue = 'Catalogue',
        newCategory = 'New Category',
        addVehicle = 'Add Vehicle',
        editVehicle = 'Edit Vehicle',
        liveHandling = 'Live Handling',

        -- Table headers
        maxSpeed = 'Max Speed',
        driveForce = 'Drive Force',
        shiftSpeed = 'Shift Speed',
        spawn = 'Spawn',
        edit = 'Edit',
        delete = 'Delete',

        -- Live editor
        liveTemp = 'LIVE TEMPORARY',
        menu = 'Menu',
        load = 'Load',
        exportMeta = 'Export Meta',
        saveChanges = 'Save Changes',
        editing = 'Editing',
        newEntry = 'New entry',
        modelSpawnName = 'Model (spawn name)',

        -- Las casillas (sus nombres y ayudas viven en shared/campos.lua)
        groupVehicle = 'Vehicle',
        editorHelp = 'Drag the bar or type the number. Live, the car changes instantly. Pink = changed from factory.',
        searchSetting = 'Find a setting: brakes, weight, drift…',
        noSettings = 'No setting matches that.',
        factory = 'Factory',
        backToFactory = 'Back to factory',
        changed = 'changed',
        settings = 'settings',
        advanced = 'Advanced',
        emptyKeepsFactory = 'Untouched',
        categorySelectPlaceholder = 'Select category...',
        categoryNewOption = '+ New category...',

        -- Modal: category
        createCategoryTitle = 'New Category',
        createCategoryLabel = 'Category name',
        createCategoryPlaceholder = 'e.g. Muscle, Drift, etc.',
        create = 'Create',

        -- Modal: vehicle
        addVehicleTitle = 'Add Vehicle',
        addVehicleLabel = 'Model (spawn name)',
        addVehiclePlaceholder = 'e.g. sultan',
        confirmAdd = 'Confirm',

        -- Alerts / confirmations
        mustSelectCategory = 'Select a category first to add a vehicle.',
        mustBeDriverToOpenLive = 'You must be driving as the driver to open Live Handling.',
        enterModelFirst = 'Type a model name first.',
        missingRequiredFields = 'Please complete required fields correctly.',
        missingRequiredForLive = 'Complete model, maxSpeed and driveForce to apply.',
        liveApplied = 'Changes were applied live to the current vehicle.',
        liveAppliedTitle = 'Live Edit',
        liveAppliedNotSaved = 'Applied live. Use "Save DB" to persist.',
        liveTempTitle = 'Live Temporary',
        liveSaveDbDone = 'Live handling saved to database.',
        saveDbTitle = 'DB Saved',
        discardLiveConfirm = 'Discard this temporary live session?',
        discardLiveTitle = 'Discard Live',
        deleteConfirm = 'Are you sure you want to delete handling for {model}?',
        deleteTitle = 'Delete Handling',
        metaCopied = '.meta data copied to clipboard.',
        metaTitle = 'Handling Exported',
        importMeta = 'Paste a meta',
        metaImportTitle = 'Paste a meta',
        metaImportLabel = 'The meta (Ctrl+V)',
        metaImportHelp = 'Works with what "Export Meta" gives or a whole handling.meta. It fills the fields; nothing is saved until you save.',
        metaImportConfirm = 'Apply',
        metaImportEmpty = 'There are no readable handling values in there.',
        metaImportDone = '{n} values set. Test it or save it as usual.',
        metaImportWhich = 'The meta had {total} vehicles: "{nombre}" was used.',
        invalidModel = 'Invalid model.',
        invalidModelSpawn = 'Invalid model for spawn.',
        vehicleDefaultsError = 'Could not fetch model defaults.',
        noLiveSession = 'There is no active live session.',
        liveSavedDb = 'Live handling saved to database.',
        liveDiscarded = 'Live session discarded.',
        commandUsageVhnew = 'Usage: /vhnew <model> [category]',
        mustBeDrivingForLive = 'You must be driving to start Live Handling.',
        mustBeDriverForLive = 'You must be the driver to start Live Handling.',
        vehicleClass = 'Vehicle Class: {class}',
        notInVehicle = 'You must be in a vehicle to use this command.',
    },
    es = {
        -- Lo general
        confirm = 'Hacerlo',
        notice = 'Aviso',
        close = 'Cerrar',
        cancel = 'Dejarlo',
        save = 'Guardar',
        saveDb = 'Guardarlo',
        discard = 'Tirarlo',
        searchModelPlaceholder = 'Buscar por nombre de spawn',
        noResults = 'Ningún coche se llama así',
        model = 'Modelo',
        category = 'De qué categoría',
        actions = 'Acciones',
        previous = 'Anterior',
        next = 'Siguiente',
        page = 'Página',
        currentCategory = 'Ahora está en',
        undefined = 'ninguna',
        focusHint = 'Pulsa G para coger o soltar el ratón',
        focus = 'Con el ratón',
        vehicles = 'Coches',
        draft = 'Sin guardar',

        -- Lo que pide la barra de datos de abajo
        all = 'Todos',
        categories = 'Categorías',
        shown = 'A la vista',
        drafts = 'Sin guardar',
        noFocus = 'Sin ratón',
        noVehicles = 'Todavía no hay coches',

        -- El catálogo
        mainTitle = 'Origen Manejo',
        catalogue = 'Catálogo',
        newCategory = 'Categoría nueva',
        addVehicle = 'Coche nuevo',
        editVehicle = 'Editar el coche',
        liveHandling = 'Tocarlo en vivo',

        -- Las columnas de cada coche
        maxSpeed = 'Punta',
        driveForce = 'Empuje',
        shiftSpeed = 'Cambio',
        spawn = 'Sacarlo y probarlo',
        edit = 'Editar',
        delete = 'Borrar',

        -- El editor
        liveTemp = 'En vivo, sin guardar',
        menu = 'Volver al catálogo',
        load = 'Traer los de fábrica',
        exportMeta = 'Copiar el meta',
        saveChanges = 'Guardar',
        editing = 'Editando',
        newEntry = 'Coche nuevo',
        modelSpawnName = 'Nombre de spawn',

        -- Las casillas (sus nombres y ayudas viven en shared/campos.lua)
        groupVehicle = 'Qué coche es',
        editorHelp = 'Mueve la barra o escribe el número. En vivo se nota en el coche al momento. Lo rosa es lo que has cambiado respecto a fábrica.',
        searchSetting = 'Busca un ajuste: frenos, peso, derrape…',
        noSettings = 'Ningún ajuste se llama así.',
        factory = 'Fábrica',
        backToFactory = 'Volver a fábrica',
        changed = 'cambiados',
        settings = 'ajustes',
        advanced = 'Avanzado',
        emptyKeepsFactory = 'Sin tocar',
        categorySelectPlaceholder = 'Elige una categoría…',
        categoryNewOption = 'Una nueva…',

        -- Diálogo: categoría nueva
        createCategoryTitle = 'Categoría nueva',
        createCategoryLabel = 'Cómo se llama',
        createCategoryPlaceholder = 'Muscle, drift…',
        create = 'Crearla',

        -- Diálogo: coche nuevo
        addVehicleTitle = 'Coche nuevo',
        addVehicleLabel = 'Nombre de spawn',
        addVehiclePlaceholder = 'sultan',
        confirmAdd = 'Sacarlo',

        -- Avisos y confirmaciones
        mustSelectCategory = 'Elige antes una categoría para meter el coche.',
        mustBeDriverToOpenLive = 'Para tocarlo en vivo tienes que ir conduciendo.',
        enterModelFirst = 'Escribe antes el nombre de spawn.',
        missingRequiredFields = 'Faltan datos o hay alguno mal puesto.',
        missingRequiredForLive = 'Para probarlo hace falta el modelo, la punta y el empuje.',
        liveApplied = 'Cambios puestos en el coche que llevas.',
        liveAppliedTitle = 'En vivo',
        liveAppliedNotSaved = 'Puesto en vivo. Pulsa «Guardarlo» para que se quede.',
        liveTempTitle = 'En vivo, sin guardar',
        liveSaveDbDone = 'Guardado: el coche se queda así.',
        saveDbTitle = 'Guardado',
        discardLiveConfirm = '¿Tiras los cambios que has probado en vivo?',
        discardLiveTitle = 'Tirar los cambios',
        deleteConfirm = '¿Borras el handling de {model}? Vuelve a ir como el de fábrica.',
        deleteTitle = 'Borrar el handling',
        metaCopied = 'El .meta está copiado: pégalo donde lo necesites.',
        metaTitle = 'Meta copiado',
        importMeta = 'Pegar un meta',
        metaImportTitle = 'Pegar un meta',
        metaImportLabel = 'El meta (Ctrl+V)',
        metaImportHelp = 'Vale lo que saca «Copiar el meta» o un handling.meta entero. Se rellenan las casillas; no se guarda hasta que le des a guardar.',
        metaImportConfirm = 'Ponerlo',
        metaImportEmpty = 'Ahí no hay ningún valor de handling que se pueda leer.',
        metaImportDone = 'Puestos {n} valores. Pruébalo o guárdalo como siempre.',
        metaImportWhich = 'El meta traía {total} coches: se ha cogido «{nombre}».',
        invalidModel = 'Ese modelo no existe.',
        invalidModelSpawn = 'Ese modelo no se puede sacar.',
        vehicleDefaultsError = 'No se han podido leer los valores de fábrica del modelo.',
        noLiveSession = 'No estás tocando ningún coche en vivo.',
        liveSavedDb = 'Guardado: el coche se queda así.',
        liveDiscarded = 'Cambios en vivo tirados.',
        commandUsageVhnew = 'Uso: /vhnew <modelo> [categoría]',
        mustBeDrivingForLive = 'Para tocarlo en vivo tienes que ir conduciendo.',
        mustBeDriverForLive = 'Para tocarlo en vivo tienes que ir al volante.',
        vehicleClass = 'Clase del vehículo: {class}',
        notInVehicle = 'Tienes que ir en un vehículo para usar esto.',
    }
}

-- Store-ready permission controls.
Config.Permissions = {
    -- Keep origen_admin integration if available.
    UseOrigenAdmin = true,

    -- Allow QBCore/ESX permission fallback.
    UseFrameworkFallback = true,

    -- Allow ACE fallback (origen.vehiclehandling, admin, command).
    UseAceFallback = true,

    -- Rockstar/FiveM identifier whitelist.
    EnableLicenseWhitelist = true,
    AllowedLicenses = {
        -- Example:
        -- 'license:1234567890abcdef1234567890abcdef12345678',
        -- 'license2:1234567890abcdef1234567890abcdef12345678',
    }
}

-- Store-ready notification adapter.
-- provider: origen_notify | ox_lib | qbcore | esx | chat | custom
Config.Notify = {
    provider = 'origen_notify',
    title = 'Origen Manejo',
    duration = 5000
}

-- If provider = 'custom', define your own function here.
-- Expected signature:
-- Config.CustomNotify = function(message, msgType, duration, title)
--     -- message: string
--     -- msgType: 'success' | 'error' | 'info' | etc.
--     -- duration: number (ms)
--     -- title: string
-- end
--
-- Quick Store examples (uncomment one):
--
-- 1) origen_notify
-- Config.CustomNotify = function(message, msgType, duration, title)
--     TriggerEvent('origen_notify:SendNotification', {
--         title = title,
--         description = message,
--         type = msgType,
--         duration = duration
--     })
-- end
--
-- 2) ox_lib
-- Config.CustomNotify = function(message, msgType, duration, title)
--     if lib and lib.notify then
--         lib.notify({
--             title = title,
--             description = message,
--             type = msgType,
--             duration = duration
--         })
--     end
-- end
--
-- 3) QBCore
-- Config.CustomNotify = function(message, msgType, duration, title)
--     local QBCore = exports['qb-core']:GetCoreObject()
--     QBCore.Functions.Notify(('%s: %s'):format(title, message), msgType, duration)
-- end
--
-- 4) ESX
-- Config.CustomNotify = function(message, msgType, duration, title)
--     local ESX = exports['es_extended']:getSharedObject()
--     ESX.ShowNotification(('%s: %s'):format(title, message))
-- end
--
-- 5) chat (simple fallback)
-- Config.CustomNotify = function(message, msgType, duration, title)
--     TriggerEvent('chat:addMessage', {
--         color = { 255, 255, 255 },
--         multiline = true,
--         args = { title, message }
--     })
-- end

Config.CustomNotify = nil
