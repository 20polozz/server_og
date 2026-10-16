--[[ ── Origen Games · mirar la partida ──────────────────────────────────────

     Quien queda fuera de la ronda sigue la partida con una cámara detrás de
     los que siguen vivos. Es una cámara de guion, no el modo espectador de
     GTA: ese lo vigila el anticheat.

     El personaje se aparca invisible, quieto y muy por encima de la zona: no
     estorba a nadie y su voz de proximidad no llega abajo, así que un
     eliminado no puede cantar a los demás dónde está nadie.

     Cada juego puede decir a qué entidad se mira de cada jugador (el objeto de
     un prop, el coche del derbi) con el gancho `BlancoEspectador(fila)`. ]]

Espectador = { activo = false }

local cam
local indice = 1
local zona

local function Vivos()
    local lista = {}
    local yo = GetPlayerServerId(PlayerId())
    for _, fila in ipairs((Juego and Juego.marcador) or {}) do
        if fila.vivo and fila.id ~= yo then lista[#lista + 1] = fila end
    end
    return lista
end

local function Blanco(fila)
    local juego = Juego and JuegosCliente[Juego.juego]
    if juego and juego.BlancoEspectador then
        local ok, ent = pcall(juego.BlancoEspectador, fila)
        if ok and ent and ent ~= 0 and DoesEntityExist(ent) then return ent end
    end

    local jugador = GetPlayerFromServerId(fila.id)
    if jugador == -1 then return nil end
    local ped = GetPlayerPed(jugador)
    if not ped or ped == 0 then return nil end
    -- Si va en un vehículo se mira el vehículo: la cámara detrás de un
    -- personaje sentado se mete dentro del coche.
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then return veh end
    return ped
end

function Espectador.Empezar(z)
    if Espectador.activo then return end
    Espectador.activo = true
    zona = z

    local ped = PlayerPedId()
    SetEntityVisible(ped, false, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, z.x, z.y, z.z + 120.0, false, false, false, false)

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, z.x, z.y, z.z + 30.0)
    PointCamAtCoord(cam, z.x, z.y, z.z)
    RenderScriptCams(true, true, 400, true, true)

    CreateThread(function()
        local cacheBlanco, cacheId, siguienteBusqueda = nil, nil, 0
        while Espectador.activo do
            local vivos = Vivos()

            if IsControlJustPressed(0, Config.Teclas.siguiente.control) then indice = indice + 1 end
            if IsControlJustPressed(0, Config.Teclas.anterior.control) then indice = indice - 1 end

            if #vivos == 0 then
                SetCamCoord(cam, zona.x, zona.y, zona.z + 35.0)
                PointCamAtCoord(cam, zona.x, zona.y, zona.z)
                SetFocusPosAndVel(zona.x, zona.y, zona.z, 0.0, 0.0, 0.0)
                Juego.mirandoA = nil
            else
                if indice > #vivos then indice = 1 end
                if indice < 1 then indice = #vivos end
                local fila = vivos[indice]

                -- Buscar la entidad cuesta; se hace cada medio segundo.
                if cacheId ~= fila.id or GetGameTimer() > siguienteBusqueda then
                    cacheBlanco = Blanco(fila)
                    cacheId = fila.id
                    siguienteBusqueda = GetGameTimer() + 500
                end

                if cacheBlanco and DoesEntityExist(cacheBlanco) then
                    local detras = GetOffsetFromEntityInWorldCoords(cacheBlanco, 0.0, -6.0, 2.8)
                    SetCamCoord(cam, detras.x, detras.y, detras.z)
                    PointCamAtEntity(cam, cacheBlanco, 0.0, 0.0, 0.3, true)
                    SetFocusPosAndVel(detras.x, detras.y, detras.z, 0.0, 0.0, 0.0)
                end
                Juego.mirandoA = fila.nombre
            end

            Wait(0)
        end
    end)
end

function Espectador.Parar()
    if not Espectador.activo then return end
    Espectador.activo = false

    if cam then
        RenderScriptCams(false, true, 300, true, true)
        DestroyCam(cam, false)
        cam = nil
    end
    ClearFocus()

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    if Juego then Juego.mirandoA = nil end
end
