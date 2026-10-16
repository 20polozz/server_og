Config = Config or {}
Internal = {}
Custom = {}
IsServer = IsDuplicityVersion()

local Translations = {}

local ResourceManager = {
    Categories = {
        Framework = { 'qbx_core', 'qb-core', 'es_extended' },
        Inventory = { 'origen_inventory', 'qb-inventory', 'ox_inventory' }
    }
}

function ResourceManager:Initialize()
    for category, list in pairs(self.Categories) do
        Config[category] = self:Detect(list)
    end
end

function ResourceManager:Detect(list)
    for i = 1, #list do
        local resource = list[i]
        if GetResourceState(resource):find('start') then
            return resource
        end
    end
    return nil
end

ResourceManager:Initialize()

local FrameworkProvider = {
    Events = {
        ['qb-core'] = {
            load = 'QBCore:Client:OnPlayerLoaded',
            unload = 'QBCore:Client:OnPlayerUnload',
            job = 'QBCore:Client:OnJobUpdate'
        },
        ['qbx_core'] = {
            load = 'QBCore:Client:OnPlayerLoaded',
            unload = 'QBCore:Client:OnPlayerUnload',
            job = 'QBCore:Client:OnJobUpdate'
        },
        ['es_extended'] = {
            load = 'esx:playerLoaded',
            unload = 'esx:playerLogout',
            job = 'esx:setJob'
        }
    }
}

function FrameworkProvider:Setup()
    self.Name = Config.Framework
    self.Object = self:FetchObject()
    self:RegisterListeners()
end

function FrameworkProvider:FetchObject()
    if not self.Name then return nil end
    if self.Name == 'es_extended' then
        return exports['es_extended']:getSharedObject()
    end
    return exports['qb-core']:GetCoreObject()
end

function FrameworkProvider:RegisterListeners()
    local handlers = self.Events[self.Name]
    if not handlers then return end

    if handlers.load then
        RegisterNetEvent(handlers.load, function()
            TriggerServerEvent('origen_businesses:server:OnPlayerLoaded')
        end)
    end

    if handlers.unload then
        RegisterNetEvent(handlers.unload, function()
            TriggerServerEvent('origen_businesses:server:OnPlayerUnload')
        end)
    end
end

FrameworkProvider:Setup()
Framework = FrameworkProvider.Object

local Translator = {}

function Translator:Init()
    CreateThread(function()
        while not Config.Language do Wait(100) end
        self:Load(Config.Language)
    end)
end

function Translator:Load(lang)
    local resource = GetCurrentResourceName()
    local data = LoadResourceFile(resource, ('locales/%s.json'):format(lang)) or
    LoadResourceFile(resource, 'locales/en.json')
    if data then
        Translations = json.decode(data) or {}
    end
end

function Locale(key, ...)
    local text = Translations[key] or key
    if ... then
        return text:format(...)
    end
    return text
end

function GetTranslations()
    return Translations
end

Translator:Init()
