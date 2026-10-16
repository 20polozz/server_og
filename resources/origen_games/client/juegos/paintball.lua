--[[ ── Paintball · el cliente ────────────────────────────────────────────────

     Carga la arena (su ymap), da el arma que dice el servidor, pinta la bola
     de los compañeros, enseña la vida y el cartel de pintado, y vuelve a sacar
     al jugador en su base cuando el servidor lo manda. El daño y la muerte son
     los de GTA (así se ven en todos los clientes); aquí solo se avisa de que
     ha muerto. Las pintadas y el arma las decide el servidor. ]]

local C = Config.Juegos.paintball
local V = C.Vida
local ID = 'paintball'

local M = {}
local st = {}

local NOMBRE = { rojo = 'Equipo rojo', azul = 'Equipo azul' }

local AVISOS_MUERTE = 3

local function Reset()
    st = { epoca = 1 }
end
Reset()

local function Activo() return Juego.activo and Juego.juego == ID end
local function Yo() return Juego.yo or {} end

--[[ ── La arena ─────────────────────────────────────────────────────────────── ]]
local function CargarArena(ymap)
    if st.ymap and st.ymap ~= ymap then RemoveIpl(st.ymap) end
    if type(ymap) == 'string' and ymap ~= '' then
        RequestIpl(ymap)
        st.ymap = ymap
    end
end

local function QuitarArena()
    if st.ymap then RemoveIpl(st.ymap) end
    st.ymap = nil
end

--- Mediodía y cielo despejado mientras se juega: de noche no se ve a nadie.
local function Cielo(poner)
    if poner then
        NetworkOverrideClockTime(12, 0, 0)
        SetWeatherTypeOvertimePersist('EXTRASUNNY', 1.0)
        SetRainLevel(0.0)
        st.cielo = true
    elseif st.cielo then
        NetworkClearClockTimeOverride()
        ClearOverrideWeather()
        ClearWeatherTypePersist()
        st.cielo = false
    end
end

--[[ ── El personaje ─────────────────────────────────────────────────────────── ]]
--[[ Recibe balas y golpes (los que el servidor deja pasar en su
     `weaponDamageEvent`), pero nada más: ni caídas, ni fuego, ni explosiones. ]]
local function Pruebas()
    local ped = PlayerPedId()
    SetEntityProofs(ped, false, true, true, true, false, true, true, true)
    SetPedSuffersCriticalHits(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedDropsWeaponsWhenDead(ped, false)
end

local function Muerto(ped)
    return IsEntityDead(ped) or IsPedDeadOrDying(ped, true) or IsPedFatallyInjured(ped)
end

local function Curar(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedBloodDamage(ped)
    ResetPedVisibleDamage(ped)
    ClearPedLastWeaponDamage(ped)
end

--- Lo levanta donde se le diga, o donde está si no se dice.
local function Resucitar(s)
    local ped = PlayerPedId()
    local x, y, z, h
    if s then
        x, y, z, h = s.x + 0.0, s.y + 0.0, s.z + 0.0, (s.h or 0.0) + 0.0
    else
        local c = GetEntityCoords(ped)
        x, y, z, h = c.x, c.y, c.z, GetEntityHeading(ped)
    end
    NetworkResurrectLocalPlayer(x, y, z, h, true, false)
    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    Curar(ped)
    st.avisos, st.proximoAviso = nil, nil
    return ped
end

--- Vida de GTA a 0-100 (un jugador muere al bajar de 100).
local function VidaNativa(ped)
    local max = GetEntityMaxHealth(ped)
    if max <= 100 then return V.maxima end
    return Util.Acotar((GetEntityHealth(ped) - 100) / (max - 100) * V.maxima, 0, V.maxima)
end

local function Armar()
    if not st.arma then return end
    local ped = PlayerPedId()
    local hash = GetHashKey(st.arma)
    if not HasPedGotWeapon(ped, hash, false) then
        RemoveAllPedWeapons(ped, true)
        GiveWeaponToPed(ped, hash, 250, false, true)
    end
    SetCurrentPedWeapon(ped, hash, true)
    SetPedInfiniteAmmo(ped, true, hash)
end

local function QuitarPintado()
    if st.efecto then
        AnimpostfxStop('DeathFailOut')
        st.efecto = false
    end
    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)
end

--[[ ── Lo que manda el servidor ───────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:paintball:c:impacto', function(d)
    if not Activo() then return end
    Nui.Enviar('sonido', { tipo = 'acierto', volumen = (type(d) == 'table' and d.cabeza) and 0.6 or 0.3, pan = 0.0 })
end)

RegisterNetEvent('origen_games:paintball:c:pintado', function(d)
    if not Activo() or type(d) ~= 'table' then return end
    st.vida = 0
    st.muertoHasta = Core.Ahora() + (tonumber(d.segundos) or V.reaparecer) * 1000
    st.por = d.por
    st.motivo = d.motivo
    st.avisos, st.proximoAviso = nil, nil

    -- Pintado sin bala (zona, caída) con el personaje en pie: también cae.
    local ped = PlayerPedId()
    if not Muerto(ped) then SetEntityHealth(ped, 0) end

    AnimpostfxPlay('DeathFailOut', 0, false)
    st.efecto = true
    Core.Destello('fallo')
end)

RegisterNetEvent('origen_games:paintball:c:reaparecer', function(d)
    if not Activo() or type(d) ~= 'table' or type(d.spawn) ~= 'table' then return end
    local ronda = Juego.ronda
    st.arma = d.arma or st.arma
    st.armaNombre = d.nombre or st.armaNombre
    st.vida = V.maxima
    st.epoca = tonumber(d.epoca) or st.epoca
    st.protegidoHasta = Core.Ahora() + V.proteccion * 1000

    CreateThread(function()
        DoScreenFadeOut(150)
        Wait(180)
        if not Activo() or Juego.ronda ~= ronda then return Core.Oscuro(false) end
        QuitarPintado()
        local s = d.spawn

        if Muerto(PlayerPedId()) then
            Resucitar(s)
        else
            Core.Teletransportar(s.x + 0.0, s.y + 0.0, s.z + 0.0, s.h)
        end
        st.muertoHasta = nil

        if not Activo() or Juego.ronda ~= ronda then return Core.Oscuro(false) end

        local ped = PlayerPedId()
        ClearPedTasksImmediately(ped)
        Curar(ped)
        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        ResetEntityAlpha(ped)

        Pruebas()
        Armar()
        DoScreenFadeIn(250)
    end)
end)

RegisterNetEvent('origen_games:paintball:c:arma', function(d)
    if not Activo() or type(d) ~= 'table' or not d.arma then return end
    st.arma = d.arma
    st.armaNombre = d.nombre
    if not st.muertoHasta then
        RemoveAllPedWeapons(PlayerPedId(), true)
        Armar()
    end
    Core.Banner('¡Subís de arma!', d.nombre or '', 'Tu equipo pasa a la siguiente arma de la lista.', 2.0)
    Core.Sonido('corona')
end)

--[[ ── Los ganchos del núcleo ──────────────────────────────────────────────── ]]
function M.Empezar()
    Reset()
end

function M.AntesDeRonda(d)
    QuitarPintado()
    local datos = d.datos or {}
    CargarArena(datos.ymap)
    Cielo(true)
end

function M.Ronda(d)
    local datos = d.datos or {}
    st.equipo = datos.equipo
    st.arma = datos.arma
    st.armaNombre = datos.armaNombre
    st.vida = V.maxima
    st.epoca = tonumber(datos.epoca) or 1
    st.protegidoHasta = nil

    local ped = PlayerPedId()
    if Muerto(ped) then ped = Resucitar() end
    st.muertoHasta = nil
    ClearPedTasksImmediately(ped)
    Curar(ped)
    Pruebas()
    Armar()
end

function M.Fase(d)
    if d.fase == 'juego' then
        Pruebas()
        Armar()
    end
end

function M.FinRonda()
    QuitarPintado()
    st.muertoHasta = nil
end

function M.Final()
    QuitarPintado()
    st.muertoHasta = nil
end

function M.Salir()
    QuitarPintado()
    local ped = PlayerPedId()
    if Muerto(ped) then ped = Resucitar() end
    SetPedInfiniteAmmo(ped, false, st.arma and GetHashKey(st.arma) or 0)
    SetPedSuffersCriticalHits(ped, true)
    SetPedCanRagdoll(ped, true)
    QuitarArena()
    Cielo(false)
    Reset()
end

M.Restaurar = M.Salir

--[[ ── Cada fotograma ─────────────────────────────────────────────────────────── ]]
local function BolaCompaneros()
    if not st.equipo then return end
    local yo = Core.Yo()
    for _, fila in ipairs(Juego.marcador or {}) do
        if fila.id ~= yo and fila.equipo == st.equipo and fila.vivo then
            local ped = Core.PedDe(fila.id)
            if ped then
                local c = GetPedBoneCoords(ped, 31086, 0.0, 0.0, 0.0)
                DrawMarker(28, c.x, c.y, c.z + 0.45, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.07, 0.07, 0.07, 60, 230, 120, 200, false, true, 2, false, nil, nil, false)
            end
        end
    end
end

function M.Frame()
    local ped = PlayerPedId()
    local jugando = Juego.fase == 'juego'

    -- Ni disparar antes de tiempo ni pintado.
    if not jugando or st.muertoHasta then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 140, true)
        DisableControlAction(0, 141, true)
        DisableControlAction(0, 142, true)
    end

    -- Siempre con su arma en la mano.
    if (jugando or Juego.fase == 'preparacion') and st.arma and not st.muertoHasta and not IsEntityDead(ped) and not IsPedRagdoll(ped) and not IsPedFalling(ped) and not IsPedClimbing(ped) then
        if GetSelectedPedWeapon(ped) ~= GetHashKey(st.arma) then Armar() end
    end

    BolaCompaneros()
end

--[[ Al morir solo se avisa: el servidor confirma, decide quién pintó y manda
     volver a salir. Se repite por si el aviso se pierde; la época evita que
     un aviso tardío cuente dos veces. ]]
local function AvisarMuerte()
    local ahora = Core.Ahora()
    if ahora < (st.proximoAviso or 0) then return end
    if (st.avisos or 0) >= AVISOS_MUERTE then
        Resucitar()
        Pruebas()
        Armar()
        return
    end
    st.avisos = (st.avisos or 0) + 1
    st.proximoAviso = ahora + (st.avisos >= AVISOS_MUERTE and 3000 or 1000)
    TriggerServerEvent('origen_games:paintball:s:muerto', st.epoca)
end

function M.Lento()
    local ped = PlayerPedId()

    if not Muerto(ped) then
        if not st.muertoHasta then
            local vida = VidaNativa(ped)
            if vida < (st.vida or V.maxima) then Core.Destello('golpe') end
            st.vida = vida
        end
        return
    end

    if st.muertoHasta then return end
    if Juego.fase == 'juego' then
        st.vida = 0
        AvisarMuerte()
    else
        Resucitar()
        Pruebas()
    end
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
function M.Ficha()
    local yo = Yo()
    local equipo = st.equipo or yo.equipo
    if not equipo then return nil end

    local vida = math.max(0, math.floor(st.vida or 0))
    local ficha = {
        tono = equipo == 'rojo' and 'rojo' or 'azul',
        icono = 'paintball',
        rol = NOMBRE[equipo],
        nombre = st.armaNombre or yo.armaNombre or 'Paintball',
        puntos = yo.puntos or 0,
        vida = { tipo = 'barra', etiqueta = 'Vida', pct = math.floor(vida / V.maxima * 100), cifra = tostring(vida), mal = vida <= 35 },
    }

    if Juego.modo == 'armas' then
        local nivel, niveles = tonumber(yo.nivel) or 1, tonumber(yo.niveles) or #C.Escalera
        ficha.renglon = ('Arma %d de %d · %d/%d pintadas'):format(nivel, niveles, tonumber(yo.cuenta) or 0, tonumber(yo.necesita) or 0)
    else
        local p = yo.pintadas or {}
        ficha.renglon = ('Rojos %d · Azules %d'):format(tonumber(p.rojo) or 0, tonumber(p.azul) or 0)
    end

    if st.muertoHasta then
        ficha.vida = { tipo = 'barra', etiqueta = 'Pintado', pct = 0, cifra = Core.Resta(st.muertoHasta) .. ' s', mal = true }
    elseif st.protegidoHasta and Core.Ahora() < st.protegidoHasta then
        ficha.renglon = 'Protegido al salir'
    end

    return ficha
end

function M.Cartel()
    if Juego.fase == 'preparacion' then
        local equipo = st.equipo or Yo().equipo
        return {
            k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = equipo and NOMBRE[equipo] or 'Paintball',
            m = Juego.modo == 'armas' and 'Juego de armas: subid de arma pintando.' or ('Todos con %s. Gana el equipo que más pinte.'):format(st.armaNombre or 'la misma arma'),
            cifra = Core.Resta(Juego.finFase),
        }
    end

    if st.muertoHasta then
        local k = st.por and ('Te ha pintado ' .. st.por) or (st.motivo == 'zona' and 'Te has salido de la arena' or 'Te has caído')
        return { tipo = 'fuera', k = k, t = '¡Pintado!', m = 'Vuelves a salir desde tu base.', cifra = Core.Resta(st.muertoHasta) }
    end
    return nil
end

RegistrarJuego(ID, M)
