local DoesEntityExist = DoesEntityExist
local DeletePed       = DeletePed
local CreateThread    = CreateThread

player                = {}
player.injuries       = {}

local hospitals       = lib.load("data.hospitals")
local emsJobs         = lib.load("config").emsJobs
local clothingScript  = lib.load("config").clothingScript
local debug           = lib.load("config").debug
local useOrigenPolicePoints = lib.load("config").useOrigenPolicePoints

local function createZones()
    for index, hospital in pairs(hospitals) do
        local cfg = hospital

        -- El punto del mapa no es uno de los puntos de trabajo que lleva
        -- origen_police (que solo marca comisarias, FIB y prision): con el
        -- ajuste puesto, el hospital no salia en el mapa.
        if cfg.blip.enable then
            utils.createBlip(cfg.blip)
        end

        lib.zones.box({
            name = 'origen_hospital:' .. index,
            coords = cfg.zone.pos,
            size = cfg.zone.size,
            clothes = (not useOrigenPolicePoints and clothingScript) and cfg.clothes,
            debug = debug,
            rotation = 0.0,
            onEnter = function(self)
                if not useOrigenPolicePoints then
                    initGarage(cfg.garage, emsJobs)

                    if self.clothes then
                        initClothes(self.clothes, emsJobs)
                    end
                end

                initParamedic()
            end,
            onExit = function(self)
                for k, v in pairs(peds) do
                    if DoesEntityExist(v) then
                        DeletePed(v)
                    end
                end
                peds = {}

                unloadGarage()
                if unloadClothes then unloadClothes() end
                if unloadParamedic then unloadParamedic() end
            end
        })
    end
end


CreateThread(createZones)

