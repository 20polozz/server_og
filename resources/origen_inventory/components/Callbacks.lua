--[[
    Origen Inventory - Advanced Callback System
    High-performance bidirectional RPC system with timeout management
    Author: Origen Development Team
]]

-- ===============================================
-- MODULE CONFIGURATION & CONSTANTS
-- ===============================================

local MODULE_CONFIG = {
    CALLBACK_TIMEOUT = 300000,          -- 5 minutes default timeout
    MAX_RETRY_ATTEMPTS = 3,             -- Maximum callback retry attempts
    KEY_GENERATION_ATTEMPTS = 100,      -- Max attempts to generate unique key
    VALIDATION_PREFIX = '__org_cb_%s',  -- Callback event prefix
    VALIDATION_EVENT = 'org_cb:validateCallback'
}

local ENVIRONMENT = {
    IS_SERVER = IsDuplicityVersion(),
    RESOURCE_NAME = GetCurrentResourceName()
}

-- ===============================================
-- TYPE DEFINITIONS
-- ===============================================

---@class CallbackKey
---@field event string The callback event name
---@field id number Random identifier
---@field playerId? number Player ID (server-side only)

---@class PendingCallback
---@field handler function Callback response handler
---@field timeout number Timeout timer ID
---@field attempts number Number of retry attempts

---@class CallbackManager
---@field pendingRequests table<string, PendingCallback>
---@field registeredHandlers table<string, string>
---@field eventTimers table<string, number>

-- ===============================================
-- UTILITY FUNCTIONS
-- ===============================================

local Utils = {}

---Generate a unique callback key
---@param event string
---@param playerId? number
---@return string|nil
function Utils.generateCallbackKey(event, playerId)
    local attempts = 0
    local key

    repeat
        attempts = attempts + 1
        local id = math.random(0, 100000)
        key = playerId and ('%s:%s:%s'):format(event, id, playerId) or ('%s:%s'):format(event, id)
    until not CallbackManager.pendingRequests[key] or attempts >= MODULE_CONFIG.KEY_GENERATION_ATTEMPTS

    return attempts < MODULE_CONFIG.KEY_GENERATION_ATTEMPTS and key or nil
end

---Validate function parameter
---@param func any
---@param argPosition number
---@return boolean
function Utils.validateFunction(func, argPosition)
    if not func then return true end -- Allow nil for await pattern

    local funcType = type(func)

    -- Handle callable tables (metatables with __call)
    if funcType == 'table' and getmetatable(func)?.__call then
        funcType = 'function'
    end

    if funcType ~= 'function' then
        error(("Expected argument %d to be 'function', received '%s'"):format(argPosition, funcType))
    end

    return true
end

---Handle callback execution with error handling
---@param callback function
---@param ... any
---@return boolean success, any result, ...
function Utils.safeCallbackExecution(callback, ...)
    local success, result, extra = pcall(callback, ...)

    if not success then
        if result then
            print(('^1SCRIPT ERROR: %s^0\n%s'):format(result,
                Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
        end
        return false
    end

    return success, result, extra
end

---Check if event is rate-limited
---@param event string
---@param delay number|false|nil
---@return boolean
function Utils.checkEventTimer(event, delay)
    if not delay or type(delay) ~= 'number' or delay <= 0 then
        return true
    end

    local currentTime = GetGameTimer()
    local lastEventTime = CallbackManager.eventTimers[event] or 0

    if lastEventTime > currentTime then
        return false
    end

    CallbackManager.eventTimers[event] = currentTime + delay
    return true
end

-- ===============================================
-- CALLBACK MANAGER
-- ===============================================

CallbackManager = {
    pendingRequests = {},
    registeredHandlers = {},
    eventTimers = {}
}

---Create response handler for pending callback
---@param key string
---@param callback function|nil
---@param promise any|nil
---@return function
function CallbackManager:createResponseHandler(key, callback, promise)
    return function(response, ...)
        -- Clean up pending request
        local pendingCallback = self.pendingRequests[key]
        if pendingCallback then
            if pendingCallback.timeout then
                ClearTimeout(pendingCallback.timeout)
            end
            self.pendingRequests[key] = nil
        end

        -- Handle invalid callback response
        if response == 'cb_invalid' then
            local errorMsg = ("Callback '%s' does not exist"):format(key:match("^([^:]+)"))

            if promise then
                return promise:reject(errorMsg)
            else
                error(errorMsg)
            end
        end

        local responseData = { response, ... }

        -- Handle promise-based response
        if promise then
            return promise:resolve(responseData)
        end

        -- Handle callback-based response
        if callback and type(callback) == 'function' then
            callback(table.unpack(responseData))
        end
    end
end

---Register timeout for callback
---@param key string
---@param timeoutMs number
---@param promise any|nil
function CallbackManager:registerTimeout(key, timeoutMs, promise)
    local timeoutId = SetTimeout(timeoutMs, function()
        local pendingCallback = self.pendingRequests[key]
        if pendingCallback then
            self.pendingRequests[key] = nil

            local errorMsg = ("Callback event '%s' timed out after %dms"):format(key, timeoutMs)
            if promise then
                promise:reject(errorMsg)
            else
                error(errorMsg)
            end
        end
    end)

    if self.pendingRequests[key] then
        self.pendingRequests[key].timeout = timeoutId
    end
end

---Clean up resources for stopped resource
---@param resourceName string
function CallbackManager:cleanupResource(resourceName)
    for callbackName, resource in pairs(self.registeredHandlers) do
        if resource == resourceName then
            self.registeredHandlers[callbackName] = nil
        end
    end
end

-- ===============================================
-- SERVER-SIDE IMPLEMENTATION
-- ===============================================

local ServerCallbacks = {}

if ENVIRONMENT.IS_SERVER then

    ---Initialize server-side callback system
    function ServerCallbacks.initialize()
        local callbackEvent = MODULE_CONFIG.VALIDATION_PREFIX:format(ENVIRONMENT.RESOURCE_NAME)

        RegisterNetEvent(callbackEvent, function(key, ...)
            local responseHandler = CallbackManager.pendingRequests[key]
            if responseHandler and responseHandler.handler then
                responseHandler.handler(...)
            end
        end)
    end

    ---Trigger client callback with validation
    ---@param event string
    ---@param playerId number
    ---@param callback function|false|nil
    ---@param ... any
    ---@return any
    function ServerCallbacks.triggerClient(event, playerId, callback, ...)
        -- Validate player exists
        assert(DoesPlayerExist(playerId --[[@as string]]),
               ("Target player ID '%s' does not exist"):format(playerId))

        -- Generate unique callback key
        local key = Utils.generateCallbackKey(event, playerId)
        if not key then
            error("Failed to generate unique callback key after maximum attempts")
        end

        -- Setup promise for await pattern
        local promise = (not callback or type(callback) ~= 'function') and promise.new()

        -- Create and register response handler
        local responseHandler = CallbackManager:createResponseHandler(key, callback, promise)
        CallbackManager.pendingRequests[key] = {
            handler = responseHandler,
            attempts = 0
        }

        -- Send validation and trigger events
        TriggerClientEvent(MODULE_CONFIG.VALIDATION_EVENT, playerId, event, ENVIRONMENT.RESOURCE_NAME, key)
        TriggerClientEvent(MODULE_CONFIG.VALIDATION_PREFIX:format(event), playerId, ENVIRONMENT.RESOURCE_NAME, key, ...)

        -- Handle promise-based await
        if promise then
            CallbackManager:registerTimeout(key, MODULE_CONFIG.CALLBACK_TIMEOUT, promise)
            return table.unpack(Citizen.Await(promise))
        end
    end

    ---Register server-side callback handler
    ---@param name string
    ---@param handler function
    function ServerCallbacks.register(name, handler)
        local eventName = MODULE_CONFIG.VALIDATION_PREFIX:format(name)

        -- Register callback as valid
        CallbackSystem.setValidCallback(name, true)

        RegisterNetEvent(eventName, function(resource, key, ...)
            local success, result, extra = Utils.safeCallbackExecution(handler, source, ...)
            TriggerClientEvent(MODULE_CONFIG.VALIDATION_PREFIX:format(resource), source, key, success and result or false, extra)
        end)
    end

    -- Initialize server callbacks
    ServerCallbacks.initialize()
end

-- ===============================================
-- CLIENT-SIDE IMPLEMENTATION
-- ===============================================

local ClientCallbacks = {}

if not ENVIRONMENT.IS_SERVER then

    ---Initialize client-side callback system
    function ClientCallbacks.initialize()
        local callbackEvent = MODULE_CONFIG.VALIDATION_PREFIX:format(ENVIRONMENT.RESOURCE_NAME)

        RegisterNetEvent(callbackEvent, function(key, ...)
            if source == '' then return end -- Ignore invalid sources

            local responseHandler = CallbackManager.pendingRequests[key]
            if responseHandler and responseHandler.handler then
                responseHandler.handler(...)
            end
        end)
    end

    ---Trigger server callback with rate limiting
    ---@param event string
    ---@param delay number|false|nil
    ---@param callback function|false|nil
    ---@param ... any
    ---@return any
    function ClientCallbacks.triggerServer(event, delay, callback, ...)
        -- Check rate limiting
        if not Utils.checkEventTimer(event, delay) then
            return
        end

        -- Generate unique callback key
        local key = Utils.generateCallbackKey(event)
        if not key then
            error("Failed to generate unique callback key after maximum attempts")
        end

        -- Setup promise for await pattern
        local promise = not callback and promise.new()

        -- Create and register response handler
        local responseHandler = CallbackManager:createResponseHandler(key, callback, promise)
        CallbackManager.pendingRequests[key] = {
            handler = responseHandler,
            attempts = 0
        }

        -- Send validation and trigger events
        TriggerServerEvent(MODULE_CONFIG.VALIDATION_EVENT, event, ENVIRONMENT.RESOURCE_NAME, key)
        TriggerServerEvent(MODULE_CONFIG.VALIDATION_PREFIX:format(event), ENVIRONMENT.RESOURCE_NAME, key, ...)

        -- Handle promise-based await
        if promise then
            CallbackManager:registerTimeout(key, MODULE_CONFIG.CALLBACK_TIMEOUT, promise)
            return table.unpack(Citizen.Await(promise))
        end
    end

    ---Register client-side callback handler
    ---@param name string
    ---@param handler function
    function ClientCallbacks.register(name, handler)
        local eventName = MODULE_CONFIG.VALIDATION_PREFIX:format(name)

        -- Register callback as valid
        CallbackSystem.setValidCallback(name, true)

        RegisterNetEvent(eventName, function(resource, key, ...)
            local success, result, extra = Utils.safeCallbackExecution(handler, ...)
            TriggerServerEvent(MODULE_CONFIG.VALIDATION_PREFIX:format(resource), key, success and result or false, extra)
        end)
    end

    -- Initialize client callbacks
    ClientCallbacks.initialize()
end

-- ===============================================
-- UNIFIED CALLBACK SYSTEM API
-- ===============================================

CallbackSystem = {}

---Create callback system interface
---@param triggerFunction function
---@param registerFunction function
---@return table
local function createCallbackInterface(triggerFunction, registerFunction)
    local interface = setmetatable({}, {
        __call = function(_, event, ...)
            local args = { ... }

            -- Validate callback function if provided
            if ENVIRONMENT.IS_SERVER then
                -- Server: (event, playerId, callback, ...)
                Utils.validateFunction(args[2], 3)
                if not args[2] then
                    warn(("Callback event '%s' has no callback function - will await instead\nConsider using CallbackSystem.await"):format(event))
                end
            else
                -- Client: (event, delay, callback, ...)
                Utils.validateFunction(args[2], 3)
                if not args[2] then
                    warn(("Callback event '%s' has no callback function - will await instead\nConsider using CallbackSystem.await"):format(event))
                end
            end

            return triggerFunction(event, ...)
        end
    })

    ---Await callback response (promise-based)
    function interface.await(event, ...)
        if ENVIRONMENT.IS_SERVER then
            -- Server: (event, playerId, ...)
            return triggerFunction(event, ...)
        end
        return triggerFunction(event, false, ...)
    end

    ---Register callback handler
    function interface.register(name, handler)
        return registerFunction(name, handler)
    end

    return interface
end

-- Create appropriate interface based on environment
if ENVIRONMENT.IS_SERVER then
    CallbackSystem = createCallbackInterface(ServerCallbacks.triggerClient, ServerCallbacks.register)
else
    CallbackSystem = createCallbackInterface(ClientCallbacks.triggerServer, ClientCallbacks.register)
end

-- ===============================================
-- CALLBACK VALIDATION SYSTEM
-- ===============================================

---Set callback validity for resource management
---@param callbackName string
---@param isValid boolean
function CallbackSystem.setValidCallback(callbackName, isValid)
    local invokingResource = GetInvokingResource() or ENVIRONMENT.RESOURCE_NAME
    local currentOwner = CallbackManager.registeredHandlers[callbackName]

    if currentOwner then
        if not isValid then
            CallbackManager.registeredHandlers[callbackName] = nil
            return
        end

        if currentOwner == invokingResource then
            return -- Already owned by same resource
        end

        -- Prevent callback override
        local errorMsg = ("Resource '%s' attempted to override callback '%s' owned by resource '%s'")
                        :format(invokingResource, callbackName, currentOwner)
        return print(('^1SCRIPT ERROR: %s^0\n%s'):format(errorMsg,
            Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString()) or ''))
    end

    -- Sin print: es una linea por callback registrado en cada arranque, y no
    -- dice nada que no se sepa. El aviso de override de aqui arriba se queda,
    -- que ese si es un problema.
    CallbackManager.registeredHandlers[callbackName] = invokingResource
end

---Check if callback is valid for current resource
---@param callbackName string
---@return boolean
function CallbackSystem.isCallbackValid(callbackName)
    local owner = CallbackManager.registeredHandlers[callbackName]
    local currentResource = GetInvokingResource() or ENVIRONMENT.RESOURCE_NAME
    return owner == currentResource
end

-- ===============================================
-- EVENT HANDLERS
-- ===============================================

-- Handle resource cleanup
AddEventHandler('onResourceStop', function(stoppedResource)
    if stoppedResource == ENVIRONMENT.RESOURCE_NAME then return end
    CallbackManager:cleanupResource(stoppedResource)
end)

-- Handle callback validation
RegisterNetEvent(MODULE_CONFIG.VALIDATION_EVENT, function(callbackName, invokingResource, key)
    if CallbackManager.registeredHandlers[callbackName] then return end

    local responseEvent = MODULE_CONFIG.VALIDATION_PREFIX:format(invokingResource)

    if ENVIRONMENT.IS_SERVER then
        TriggerClientEvent(responseEvent, source, key, 'cb_invalid')
    else
        TriggerServerEvent(responseEvent, key, 'cb_invalid')
    end
end)

-- ===============================================
-- EXPORT INTERFACE
-- ===============================================

-- Export unified interface
Callbacks = CallbackSystem