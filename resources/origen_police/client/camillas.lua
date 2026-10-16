--[[ ── Camillas: tumbarse, sentarse y levantarse con E (24/09) ─────────────

     Las camillas del hospital ya se configuran en el admin de police
     (Admin → camillas: `bedPoint` es donde queda tumbado el paciente, el mismo
     punto que usa origen_ambulancejob para el respawn). Hasta ahora solo
     servian para reaparecer; ahora cualquiera puede usarlas:

       de pie, a menos de DIST_USAR del punto  → [E] Tumbarse
       tumbado                                 → [E] Sentarse  (borde de la camilla)
       sentado                                 → [E] Levantarse

     Todo es local (animacion del propio ped, que el juego ya sincroniza): no
     hay evento de red que validar. La camilla se da por ocupada si hay otro
     ped encima del punto. Las anims de tumbarse y levantarse son las mismas
     que usa origen_ambulancejob al reaparecer.

     SIN PROBAR EN EL JUEGO: sobre todo el sentarse (anim y desplazamiento
     al borde, SENTADO_LADO / SENTADO_ALTO). ]]

local DIST_USAR = 1.6
local DIST_OCUPADA = 0.7
local SENTADO_LADO = 0.55     -- metros hacia el costado de la camilla
local SENTADO_ALTO = -0.05    -- ajuste de altura sentado

local TUMBADO = { dict = "timetable@tracy@sleep@", clip = "base" }
local SENTADO = { dict = "timetable@ron@ig_3_couch", clip = "base" }
local LEVANTARSE = { dict = "switch@franklin@bed", clip = "sleep_getup_rubeyes" }

local camillas = {}      -- { vector4 } sacadas de la config de camillas
local estado = nil       -- nil | "tumbado" | "sentado"
local camillaEnUso = nil
local ayudaPuesta = nil

local function num(p, k, i) return tonumber(p[k] or p[i]) end

local function CargarCamillas(config)
    local lista = {}
    if type(config) == "table" then
        for _, hospital in pairs(config) do
            local beds = type(hospital) == "table" and hospital.beds
            if type(beds) == "table" then
                for _, bed in pairs(beds) do
                    local p = type(bed) == "table" and bed.bedPoint
                    if type(p) == "table" or type(p) == "vector4" then
                        local x, y, z = num(p, "x", 1), num(p, "y", 2), num(p, "z", 3)
                        local w = num(p, "w", 4) or tonumber(p.h) or 0.0
                        if x and y and z then
                            lista[#lista + 1] = vector4(x + 0.0, y + 0.0, z + 0.0, w + 0.0)
                        end
                    end
                end
            end
        end
    end
    camillas = lista
end

-- Al guardar desde el admin el servidor lo manda a todos por estos dos.
RegisterNetEvent("origen_police:client:syncHospitalBedsAdmin", CargarCamillas)
RegisterNetEvent("origen_ambulancejob:client:syncHospitalBeds", CargarCamillas)

CreateThread(function()
    Wait(5000)
    FW_TriggerCallback("origen_police:admin:getHospitalBeds", CargarCamillas)
end)

local function Ayuda(texto)
    if ayudaPuesta == texto then return end
    ayudaPuesta = texto
    if not texto then
        if GetResourceState("origen_hud") == "started" then
            pcall(function() exports["origen_hud"]:hideControls() end)
        elseif lib then
            lib.hideTextUI()
        end
        return
    end
    if GetResourceState("origen_hud") == "started" then
        pcall(function() exports["origen_hud"]:setupControls({ { key = "E", text = texto } }) end)
    elseif lib then
        lib.showTextUI("[E] " .. texto, { position = "right-center", icon = "bed" })
    end
end

local function Ocupada(c, ped)
    local pool = GetGamePool("CPed")
    for i = 1, #pool do
        local otro = pool[i]
        if otro ~= ped and #(GetEntityCoords(otro) - c.xyz) < DIST_OCUPADA then
            return true
        end
    end
    return false
end

local function Tumbarse(ped, c)
    lib.requestAnimDict(TUMBADO.dict)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(ped, c.w)
    TaskPlayAnim(ped, TUMBADO.dict, TUMBADO.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(ped, true)
    estado, camillaEnUso = "tumbado", c
end

local function Sentarse(ped, c)
    lib.requestAnimDict(SENTADO.dict)
    -- Al borde: hacia el costado de la camilla, mirando hacia fuera.
    local rad = math.rad(c.w + 90.0)
    local x = c.x - math.sin(rad) * SENTADO_LADO
    local y = c.y + math.cos(rad) * SENTADO_LADO
    FreezeEntityPosition(ped, false)
    ClearPedTasksImmediately(ped)
    SetEntityCoords(ped, x, y, c.z + SENTADO_ALTO, false, false, false, false)
    SetEntityHeading(ped, c.w + 90.0)
    TaskPlayAnim(ped, SENTADO.dict, SENTADO.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(ped, true)
    estado = "sentado"
end

local function Levantarse(ped, c)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
    lib.requestAnimDict(LEVANTARSE.dict)
    TaskPlayAnim(ped, LEVANTARSE.dict, LEVANTARSE.clip, 1.0, 1.0, 2500, 8, -1, false, false, false)
    estado, camillaEnUso = nil, nil
end

CreateThread(function()
    while true do
        local espera = 1000
        local ped = PlayerPedId()

        if estado then
            espera = 0
            local c = camillaEnUso
            -- Si algo le saca (muerte, esposas, otra anim) se suelta sin mas.
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) or not c then
                FreezeEntityPosition(ped, false)
                estado, camillaEnUso = nil, nil
                Ayuda(nil)
            else
                Ayuda(estado == "tumbado" and "Sentarse" or "Levantarse")
                -- Que no se quede sin anim (un ClearPedTasks de otro script).
                local a = estado == "tumbado" and TUMBADO or SENTADO
                if not IsEntityPlayingAnim(ped, a.dict, a.clip, 3) then
                    TaskPlayAnim(ped, a.dict, a.clip, 2.0, 2.0, -1, 1, 0, false, false, false)
                end
                if IsControlJustReleased(0, 38) then
                    if estado == "tumbado" then Sentarse(ped, c) else Levantarse(ped, c); Ayuda(nil) end
                end
            end
        elseif #camillas > 0 and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) then
            local pos = GetEntityCoords(ped)
            local cerca, dist = nil, nil
            for i = 1, #camillas do
                local d = #(pos - camillas[i].xyz)
                if d < DIST_USAR and (not dist or d < dist) then cerca, dist = camillas[i], d end
                if d < 20.0 then espera = 250 end
            end

            if cerca and not IsNuiFocused() then
                espera = 0
                Ayuda("Tumbarse")
                if IsControlJustReleased(0, 38) and not Ocupada(cerca, ped) then
                    Tumbarse(ped, cerca)
                end
            else
                Ayuda(nil)
            end
        else
            Ayuda(nil)
        end

        Wait(espera)
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if estado then FreezeEntityPosition(PlayerPedId(), false) end
    if ayudaPuesta then Ayuda(nil) end
end)
