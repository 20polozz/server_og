Config = Config or {}

local ResourceManager = {}
ResourceManager.__index = ResourceManager

function ResourceManager.new()
    local self = setmetatable({}, ResourceManager)
    self.resource_name = GetCurrentResourceName()
    self.version = GetResourceMetadata(GetCurrentResourceName(), 'version', 0) or '1.0.0'
    self.detected_resources = {}
    return self
end

function ResourceManager:checkResourceState(resource)
    return GetResourceState(resource) == 'starting' or GetResourceState(resource) == 'started'
end

function ResourceManager:detectFramework()
    local frameworks = {
        { name = 'esx', resource = 'es_extended' },
        { name = 'qbcore', resource = 'qb-core' },
        { name = 'qbx_core', resource = 'qbx_core' }
    }
    
    for _, framework in ipairs(frameworks) do
        if self:checkResourceState(framework.resource) then
            self.detected_resources.framework = framework.name
            return framework.name
        end
    end
    
    return '^1No framework resource found^0'
end

function ResourceManager:detectClothing()
    local clothing_systems = {
        { name = 'origen_clothing', resource = 'origen_clothing' },
        { name = 'qb-clothing', resource = 'qb-clothing' },
        { name = 'codem-appearance', resource = 'codem-appearance' },
        { name = 'skinchanger', resource = 'skinchanger' },
        { name = 'fivem-appearance', resource = 'fivem-appearance' },
        { name = 'illenium-appearance', resource = 'illenium-appearance' },
        { name = 'rcore_clothing', resource = 'rcore_clothing' }
    }
    
    for _, clothing in ipairs(clothing_systems) do
        if self:checkResourceState(clothing.resource) then
            self.detected_resources.clothing = clothing.name
            return clothing.name
        end
    end
    
    return '^1No clothing resource found^0'
end

function ResourceManager:detectApartment()
    local apartment_systems = {
        { name = 'qb-apartments', resource = 'qb-apartments' },
        { name = '0r-apartment-v2', resource = '0r-apartment-v2' },
        { name = '0r_motels', resource = '0r_motels' }
    }
    
    for _, apartment in ipairs(apartment_systems) do
        if self:checkResourceState(apartment.resource) then
            self.detected_resources.apartment = apartment.name
            return apartment.name
        end
    end
    
    return 'default'
end

function ResourceManager:detectAll()
    local framework = Config.Framework or self:detectFramework()
    local clothing = Config.ClothSystem or self:detectClothing()
    local apartment = Config.Apartment or self:detectApartment()
    
    -- Qbox se detecta como 'qbx_core', pero casi todo el recurso compara contra
    -- 'qbcore': FW_CreateCallback, FW_TriggerCallback y los shims de client/init
    -- y server/init solo tienen rama para "qbcore" y "esx". Con 'qbx_core' no se
    -- registraba NINGUN callback de servidor, asi que el boton Continuar de la
    -- creacion de personaje se quedaba esperando una respuesta que no llegaba
    -- nunca. La lista de personajes si cargaba porque esa consulta si contempla
    -- 'qbx_core' (server/server.lua:66), y por eso el fallo no se veia antes.
    -- Se normaliza aqui: para el resto del codigo la familia qb es una sola.
    -- exports['qb-core'] sigue funcionando porque qbx_core declara
    -- provide 'qb-core' y su puente qb viene activado por defecto.
    if framework == 'qbx_core' then framework = 'qbcore' end

    Config.Framework = framework
    Config.ClothSystem = clothing
    Config.Apartment = apartment
    
    if Config.Framework == 'qbcore' then 
        QBCore = exports['qb-core']:GetCoreObject()
    end
    
    Config.UseQBOX = false
    if self:checkResourceState('qbx_core') then
        -- Config.Framework = 'qbx_core'
        Config.UseQBOX = true
    end
    
    return {
        framework = framework,
        clothing = clothing,
        apartment = apartment
    }
end

function ResourceManager:printInfo()
    local detected = self:detectAll()
end

local resourceManager = ResourceManager.new()
resourceManager:printInfo()