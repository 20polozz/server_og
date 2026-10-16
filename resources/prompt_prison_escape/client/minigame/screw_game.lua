local Utils = require 'client.utils'
local CameraManager = require 'client.minigame.camera_manager'
local AnimationController = require 'client.minigame.animation_controller'
local config = require 'config.config_c'

local ScrewGame = {}
ScrewGame.__index = ScrewGame
ScrewGame.activeInstance = nil

---@param entity number
---@return table
function ScrewGame.new(entity)
    local self = setmetatable({}, ScrewGame)

    self.entity = entity
    self.isRunning = false
    self.isInMinigame = false
    self.cameraAlternate = false
    self.inControlRange = false

    self.camera = CameraManager.new(entity)
    self.animator = AnimationController.new(cache.ped)

    self.screwDriver = nil
    self.screwObject = nil

    return self
end

function ScrewGame:createObjects()
    local coords = GetEntityCoords(self.entity)

    lib.requestModel(config.toilet.screwDriverModel)
    self.screwDriver = CreateObject(config.toilet.screwDriverModel, coords.x, coords.y, coords.z - 10, config.toilet.useNetworkedObjects, true, false)
    if not DoesEntityExist(self.screwDriver) then
        lib.print.error('[ScrewGame] Failed to create screwdriver object')
        return false
    end
    SetEntityVisible(self.screwDriver, false, false)
    SetModelAsNoLongerNeeded(config.toilet.screwDriverModel)
    SetEntityCompletelyDisableCollision(self.screwDriver, false, true)
    lib.print.debug('[ScrewGame] Created screwdriver object:', self.screwDriver)

    lib.requestModel(config.toilet.screwModel)
    self.screwObject = CreateObject(config.toilet.screwModel, coords.x, coords.y, coords.z - 10, config.toilet.useNetworkedObjects, true, false)
    if not DoesEntityExist(self.screwObject) then
        lib.print.error('[ScrewGame] Failed to create screw object')
        return false
    end
    SetEntityVisible(self.screwObject, false, false)
    SetModelAsNoLongerNeeded(config.toilet.screwModel)
    SetEntityCompletelyDisableCollision(self.screwObject, false, true)
    lib.print.debug('[ScrewGame] Created screw object:', self.screwObject)

    return true
end

---@param screwIndex number
function ScrewGame:attachScrewdriver(screwIndex)
    if not DoesEntityExist(self.screwDriver) then
        lib.print.error('[ScrewGame] Cannot attach screwdriver - entity does not exist')
        return
    end

    SetEntityVisible(self.screwDriver, true, false)
    if screwIndex == 1 or screwIndex == 2 then
        AttachEntityToEntity(self.screwDriver, cache.ped, GetPedBoneIndex(cache.ped, 18905),
            0.13191204624002, 0.082048422891877, -0.00017189368813841,
            158.93643577607, -28.807547138067, -8.8622696090118,
            true, true, false, true, 1, true)
    else
        AttachEntityToEntity(self.screwDriver, cache.ped, GetPedBoneIndex(cache.ped, 57005),
            0.14447676481041, 0.083777311695066, -0.030584143861719,
            -8.9086513739403, 40.146033454762, 160.55496533153,
            true, true, false, true, 1, true)
    end
    lib.print.debug('[ScrewGame] Attached screwdriver for screw #' .. screwIndex)
end

---@param screwIndex number
---@param progress number
---@param rotation number
function ScrewGame:positionScrew(screwIndex, progress, rotation)
    if not DoesEntityExist(self.screwObject) then
        lib.print.error('[ScrewGame] Cannot position screw - entity does not exist')
        return
    end

    local screwOffset = config.toilet.screwOffsets[screwIndex]
    if not screwOffset then
        lib.print.error('[ScrewGame] Invalid screw offset index:', screwIndex)
        return
    end

    local isLeftSide = (screwIndex == 1 or screwIndex == 2)
    local entityRot = GetEntityRotation(self.entity)

    local adjustedOffset = vec3(
        screwOffset.screw.x + (isLeftSide and -progress or progress),
        screwOffset.screw.y,
        screwOffset.screw.z
    )

    local screwPos = GetOffsetFromEntityInWorldCoords(self.entity, adjustedOffset.x, adjustedOffset.y, adjustedOffset.z)
    SetEntityCoords(self.screwObject, screwPos.x, screwPos.y, screwPos.z, false, false, false, false)
    SetEntityRotation(self.screwObject, entityRot.x + rotation, entityRot.y + (isLeftSide and -90.0 or 90.0), entityRot.z, 2, true)
    SetEntityVisible(self.screwObject, true, false)
end

function ScrewGame:switchToAlternateCamera()
    if not self.isInMinigame or self.cameraAlternate then return end

    self.cameraAlternate = true

    self.camera:setCamera({
        vec3(0.0, 0.0, 1.0),
        vec3(0.0, 0.0, GetEntityHeading(self.entity) + 180.0)
    }, true, true)
    self.camera:activate(true, 300)
    lib.print.debug('[ScrewGame] Switched to alternate camera')
end

function ScrewGame:switchToScrewCamera()
    if not self.isInMinigame or not self.cameraAlternate then return end

    self.cameraAlternate = false

    local camOffset = config.toilet.screwOffsets[self.currentScrewIndex].cam
    self.camera:setCamera(camOffset, true)
    self.camera:activate(true, 300)
    lib.print.debug('[ScrewGame] Switched back to screw camera')
end

---@param screwIndex number
---@return boolean
function ScrewGame:handleScrewMinigame(screwIndex)
    local isLeftSide = (screwIndex == 1 or screwIndex == 2)

    self.isInMinigame = true
    self.currentScrewIndex = screwIndex
    self.cameraAlternate = false

    local camOffset = config.toilet.screwOffsets[screwIndex].cam
    self.camera:setCamera(camOffset, false)
    self.camera:activate(true, 1500)

    self:positionScrew(screwIndex, 0, 0)
    self:attachScrewdriver(screwIndex)

    self.animator:playScrewAnim(screwIndex)
    Wait(100)

    local animRange = {start = 0.25, finish = 0.75}
    self.inControlRange = false
    local wasPlaying = false
    local screwRotation = 0.0
    local screwProgress = 0.0

    SetEntityVisible(self.screwObject, true, false)
    lib.print.debug('[ScrewGame] Starting minigame loop for screw #' .. screwIndex)

    while self.isRunning do
        local currentTime = self.animator:getCurrentTime()
        local isInRange = self.animator:isInTimeRange(animRange.start, animRange.finish)

        -- También la versión "disabled": con el cursor puesto la X puede llegar como control desactivado
        if IsControlJustPressed(0, 73) or IsDisabledControlJustPressed(0, 73) then
            lib.print.debug('[ScrewGame] X pressed, cancelling')
            SetNuiFocus(false, false)
            self:cancelWithAnimation()
            self.isRunning = false
            return false
        end

        -- Si muere, lo esposan o lo separan del váter (2.5 = distancia de la interacción), se corta:
        -- el bucle solo salía con la X o al acabar, y el cursor quedaba preso
        local ped = cache.ped
        if IsEntityDead(ped) or IsPedCuffed(ped) or #(GetEntityCoords(ped) - GetEntityCoords(self.entity)) > 2.5 then
            lib.print.debug('[ScrewGame] Dead, cuffed or away from toilet, cancelling')
            SetNuiFocus(false, false)
            self:cancelWithAnimation()
            self.isRunning = false
            return false
        end

        if isInRange and not self.inControlRange then
            self.animator:setSpeed(0.0)
            self.inControlRange = true
            SetNuiFocus(false, true)
            lib.print.debug('[ScrewGame] Entered control range, cursor enabled')
        end

        if self.inControlRange then
            local isAimingAtScrew = Utils.IsCursorOnEntity(self.screwObject, 35.0)
            local isHoldingLMB = IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24)

            if isAimingAtScrew then
                SetEntityDrawOutline(self.screwObject, true)
                SetEntityDrawOutlineColor(220, 221, 224, 255) -- ORIGEN: pieza (antes amarillo)
                SetEntityDrawOutlineShader(1)
            else
                SetEntityDrawOutline(self.screwObject, false)
            end

            if isAimingAtScrew and isHoldingLMB then
                if not wasPlaying then
                    self.animator:setSpeed(1.0)
                    SetEntityDrawOutlineColor(216, 27, 85, 255) -- ORIGEN: rosa (antes verde)
                    wasPlaying = true
                    lib.print.debug('[ScrewGame] Started unscrewing from progress:', screwProgress)
                end

                screwProgress = screwProgress + 0.0001
                if isLeftSide then
                    screwRotation = screwRotation - 2.0
                else
                    screwRotation = screwRotation + 2.0
                end

                self:positionScrew(screwIndex, screwProgress, screwRotation)

                if currentTime >= animRange.finish then
                    lib.print.debug('[ScrewGame] Screw #' .. screwIndex .. ' fully unscrewed at progress:', screwProgress)
                    SetNuiFocus(false, false)
                    SetEntityDrawOutline(self.screwObject, false)
                    SetEntityVisible(self.screwObject, false, false)

                    if self.camera then
                        self.camera:destroy()
                        self.camera = nil
                    end

                    return true
                end
            else
                if wasPlaying then
                    self.animator:setSpeed(0.0)
                    if isAimingAtScrew then
                        SetEntityDrawOutlineColor(220, 221, 224, 255) -- ORIGEN: pieza (antes amarillo)
                    end
                    wasPlaying = false
                end
            end
        end

        Wait(0)
    end

    SetNuiFocus(false, false)
    SetEntityDrawOutline(self.screwObject, false)
    self.isInMinigame = false
    if self.camera then
        self.camera:destroy()
        self.camera = nil
    end

    return false
end

function ScrewGame:selectScrew(unscrewed)
    local p = promise.new()
    local menuData = {
        {
            header = locale('select_screw.title'),
            isMenuHeader = true,
            icon = "fas fa-tools"
        }
    }

    for i = 1, 4 do
        local isUnscrewed = lib.table.contains(unscrewed, i)
        table.insert(menuData, {
            header = locale('select_screw.options.' .. i),
            txt = isUnscrewed and "Ya desatornillado" or "Pendiente por desatornillar",
            icon = isUnscrewed and "fas fa-check-circle" or "fas fa-circle",
            disabled = isUnscrewed,
            params = {
                handler = function()
                    p:resolve(i)
                end
            }
        })
    end

    table.insert(menuData, {
        header = locale('select_screw.cancel'),
        icon = "fas fa-times",
        params = {
            handler = function()
                p:resolve(nil)
            end
        }
    })

    exports['org-menu']:openMenu(menuData)

    local menuClosed = false
    local handler = AddEventHandler('org-menu:client:menuClosed', function()
        if not menuClosed then
            menuClosed = true
            p:resolve(nil)
        end
    end)

    local result = Citizen.Await(p)
    RemoveEventHandler(handler)
    menuClosed = true
    return result
end

local keybind = lib.addKeybind({
    name = 'prison_cam_switch',
    description = 'Fuga: cambiar la cámara',
    defaultKey = 'R',
    onPressed = function(self)
        if ScrewGame.activeInstance then
            ScrewGame.activeInstance:switchToAlternateCamera()
        end
    end,
    onReleased = function(self)
        if ScrewGame.activeInstance then
            ScrewGame.activeInstance:switchToScrewCamera()
        end
    end
})

function ScrewGame:start()
    lib.print.debug('[ScrewGame] Starting screw minigame')
    self.isRunning = true
    ScrewGame.activeInstance = self

    if not self:createObjects() then
        lib.print.error('[ScrewGame] Failed to create objects, aborting')
        self:cleanup()
        return
    end

    local offset = GetOffsetFromEntityInWorldCoords(self.entity, 0.0, -0.5, 0.55)

    SetEntityCoordsNoOffset(cache.ped, offset.x, offset.y, offset.z, false, false, false)
    SetEntityHeading(cache.ped, GetEntityHeading(self.entity))

    local totalDuration = GetAnimDuration('promt@jail_3', 'jail_enter_ped') * 1000

    lib.playAnim(cache.ped, 'promt@jail_3', 'jail_enter_ped', 8.0, -8.0, -1, 2)
    Wait(2000)
    self:attachScrewdriver(1)
    Wait(totalDuration - 2000)

    AttachEntityToEntity(cache.ped, self.entity, 0, 0.0, 0.0, 0.55, 0.0, 0.0, 0.0, false, false, true, false, 2, true)

    local allCompleted = false
    local unscrewed = lib.callback.await('prompt_prison_escape:getUnscrewedState', 500) or {}
    lib.print.debug('[ScrewGame] Loaded unscrewed state from server:', json.encode(unscrewed))

    while self.isRunning and #unscrewed < 4 do
        local screwIndex = self:selectScrew(unscrewed)
        if not screwIndex then
            lib.print.debug('[ScrewGame] User cancelled screw selection')
            self:cancelWithAnimation()
            self.isRunning = false
            break
        end

        lib.print.debug('[ScrewGame] Selected screw #' .. screwIndex .. ', already unscrewed:', json.encode(unscrewed))

        AttachEntityToEntity(cache.ped, self.entity, 0, 0.0, 0.0, 0.55, 0.0, 0.0, -180.0, false, false, true, false, 2, true)
        exports.origen_hud:setupControls({
            { key = 'LCLICK', text = 'Destornillar' },
            { key = 'R', text = 'Cámara' },
            { key = 'X', text = 'Cancelar' }
        })
        -- pcall: si el minijuego revienta, se sale del bucle y cleanup() suelta el cursor
        local ok, completed = pcall(self.handleScrewMinigame, self, screwIndex)
        if not ok then
            lib.print.error('[ScrewGame] Error en el minijuego:', completed)
            completed = false
        end
        exports.origen_hud:hideControls()

        SetNuiFocus(false, false)
        if self.camera then
            self.camera:destroy()
            self.camera = nil
        end

        if not completed then
            break
        end

        local saved = lib.callback.await('prompt_prison_escape:unscrewProgress', 500, screwIndex)
        if not saved then
            lib.print.error('[ScrewGame] Failed to save screw progress on server')
            break
        end

        table.insert(unscrewed, screwIndex)
        lib.print.debug('[ScrewGame] Screw #' .. screwIndex .. ' completed. Total:', #unscrewed .. '/4')

        if #unscrewed < 4 then
            self.camera = CameraManager.new(self.entity)
        end
    end

    if #unscrewed >= 4 then
        if self.screwObject and DoesEntityExist(self.screwObject) then
            SetEntityDrawOutline(self.screwObject, false)
        end

        if self.screwDriver and DoesEntityExist(self.screwDriver) then
            DeleteEntity(self.screwDriver)
            self.screwDriver = nil
        end

        exports.origen_hud:setupControls({
            { key = 'E', text = 'Escapar' },
            { key = 'X', text = 'Cancelar' }
        })

        while self.isRunning do
            if IsControlJustPressed(0, 38) then
                exports.origen_hud:hideControls()
                lib.print.debug('[ScrewGame] Starting exit sequence')
                self:playExitSequence()
                allCompleted = true
                break
            elseif IsControlJustPressed(0, 73) then
                exports.origen_hud:hideControls()
                lib.print.warn('[ScrewGame] User cancelled escape')
                self:cancelWithAnimation()
                self.isRunning = false
                break
            end
            Wait(0)
        end
    else
        if self.screwObject and DoesEntityExist(self.screwObject) then
            SetEntityDrawOutline(self.screwObject, false)
        end

        if self.screwDriver and DoesEntityExist(self.screwDriver) then
            DeleteEntity(self.screwDriver)
            self.screwDriver = nil
        end
    end

    if allCompleted then
        lib.callback.await('prompt_prison_escape:completeEscape', 500)
    else
        lib.callback.await('prompt_prison_escape:stopSitting', 500)
    end

    self:cleanup()
    lib.print.debug('[ScrewGame] Cleaned up and finished')
end

function ScrewGame:playExitSequence()
    SetNuiFocus(false, false)

    if self.camera then
        self.camera:destroy()
        self.camera = nil
    end

    DetachEntity(cache.ped, true, false)

    local entHeading = GetEntityHeading(self.entity)
    local entityStartCoords = GetEntityCoords(self.entity)

    local animOffset = GetOffsetFromEntityInWorldCoords(self.entity, 0.0, 0.0, 0.55)
    SetEntityCoordsNoOffset(cache.ped, animOffset.x, animOffset.y, animOffset.z, false, false, false)
    SetEntityHeading(cache.ped, entHeading - 173.0)
    lib.playAnim(cache.ped, 'promt@jail_4', 'jail_exit_open_ped')

    Wait(4000)

    local targetPos = GetOffsetFromEntityInWorldCoords(self.entity, -0.5, 0.0, 0.0)
    local totalOffsetX = targetPos.x - entityStartCoords.x
    local totalOffsetY = targetPos.y - entityStartCoords.y

    local duration = 2000
    local stepTime = 25
    local steps = duration / stepTime

    for i = 1, steps do
        local progress = i / steps
        SetEntityCoords(self.entity,
            entityStartCoords.x + (totalOffsetX * progress),
            entityStartCoords.y + (totalOffsetY * progress),
            entityStartCoords.z,
            false, false, false)
        Wait(stepTime)
    end

    local targetExitPos = GetOffsetFromEntityInWorldCoords(self.entity, 0.5, 1.5, 0.0)
    Wait(GetAnimDuration('promt@jail_4', 'jail_exit_open_ped') * 1000 - 7000)
    targetPos = GetOffsetFromEntityInWorldCoords(self.entity, 0.5, -1.0, 0.0)
    SetEntityCoordsNoOffset(cache.ped, targetPos.x, targetPos.y, targetPos.z, false, false, false)
    lib.playAnim(cache.ped, 'promt@jail_5', 'jail_exit_ped')
    SetEntityHeading(cache.ped, entHeading)
    SetEntityCollision(self.entity, false, false)

    Wait(GetAnimDuration('promt@jail_5', 'jail_exit_ped') * 1000)
    SetEntityCoordsNoOffset(cache.ped, targetExitPos.x, targetExitPos.y, targetExitPos.z, false, false, false)
    SetEntityHeading(cache.ped, entHeading + 180.0)
    SetEntityCollision(self.entity, true, true)

    local totalCloseDuration = GetAnimDuration('prompt@jail', 'jail_exit_close') * 1000

    lib.playAnim(cache.ped, 'prompt@jail', 'jail_exit_close')
    Wait(2500)

    local currentEntityCoords = GetEntityCoords(self.entity)
    local targetPos = GetOffsetFromEntityInWorldCoords(self.entity, 0.5, 0.0, 0.0)
    local totalOffsetX = targetPos.x - currentEntityCoords.x
    local totalOffsetY = targetPos.y - currentEntityCoords.y

    local duration = 2000
    local stepTime = 25
    local steps = duration / stepTime

    for i = 1, steps do
        local progress = i / steps
        SetEntityCoords(self.entity,
            currentEntityCoords.x + (totalOffsetX * progress),
            currentEntityCoords.y + (totalOffsetY * progress),
            currentEntityCoords.z,
            false, false, false)
        Wait(stepTime)
    end
    Wait(totalCloseDuration - 2500 - 2000)
end

function ScrewGame:cancelWithAnimation()
    SetNuiFocus(false, false)

    if self.camera then
        self.camera:destroy()
        self.camera = nil
    end

    DetachEntity(cache.ped, true, false)

    local entHeading = GetEntityHeading(self.entity)
    local animOffset = GetOffsetFromEntityInWorldCoords(self.entity, 0.0, 0.0, 0.55)
    SetEntityCoordsNoOffset(cache.ped, animOffset.x, animOffset.y, animOffset.z, false, false, false)
    SetEntityHeading(cache.ped, entHeading - 173.0)

    local totalDuration = GetAnimDuration('promt@jail_2', 'jail_enter_off_ped') * 1000
    lib.playAnim(cache.ped, 'promt@jail_2', 'jail_enter_off_ped')
    Wait(1000)

    if self.screwDriver and DoesEntityExist(self.screwDriver) then
        DeleteEntity(self.screwDriver)
        self.screwDriver = nil
    end
    Wait(totalDuration - 1000)
end

function ScrewGame:stop()
    self.isRunning = false
end


function ScrewGame:cleanup()
    self.isRunning = false
    self.isInMinigame = false
    if ScrewGame.activeInstance == self then
        ScrewGame.activeInstance = nil
    end

    SetNuiFocus(false, false)

    if self.screwDriver and DoesEntityExist(self.screwDriver) then
        DeleteEntity(self.screwDriver)
        self.screwDriver = nil
    end

    if self.screwObject and DoesEntityExist(self.screwObject) then
        SetEntityDrawOutline(self.screwObject, false)
        DeleteEntity(self.screwObject)
        self.screwObject = nil
    end

    if self.camera then
        self.camera:destroy()
        self.camera = nil
    end

    DetachEntity(cache.ped, true, false)

    if self.animator then
        self.animator:stop()
        self.animator = nil
    end
end

return ScrewGame
