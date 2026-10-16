--[[ ── Escondite · el cliente ───────────────────────────────────────────────

     Las teclas del prop y del cazador, el láser de copiar, el disparo, la
     pista y la ficha del HUD. El núcleo (client/core/partida.lua) ya lleva la
     entrada y la salida, la zona, el espectador y el reloj. ]]

local E = Config.Juegos.escondite
local T = E.Teclas
local ARMA = GetHashKey(E.Cazador.arma)
local ID = 'escondite'

local M = {}
local st = {}

local function Reset()
    st = {
        enfriamientos = { burla = 0, sonar = 0, ruido = 0, cambiar = 0, disparo = 0 },
        props = {},
    }
end
Reset()

local function Yo() return Juego.yo or {} end
local function EsProp() return Juego.rol == 'prop' and not Juego.eliminado end
local function EsCazador() return Juego.rol == 'cazador' and not Juego.eliminado end
local function Colocando() return Juego.fase == 'preparacion' or Juego.fase == 'colocacion' end
local function AOscuras() return EsCazador() and Colocando() and not Yo().infectado end

--[[ ── Ganchos del núcleo ─────────────────────────────────────────────────── ]]
function M.Empezar() Reset() end

function M.AntesDeRonda()
    Reset()
    Prop.Quitar()
    Prop.Congelar(false)
    OrigenMapa.Quitar('pista')
end

function M.Ronda(d)
    local datos = d.datos or {}
    st.prop = datos.prop
    st.cazadores = datos.cazadores
    st.colocacion = datos.colocacion

    if d.rol == 'prop' then
        Prop.Transformar(datos.prop)
        return false
    end

    -- El cazador espera a oscuras y quieto hasta la búsqueda.
    FreezeEntityPosition(PlayerPedId(), true)
    return true
end

function M.Fase(d)
    local ped = PlayerPedId()
    if d.fase == 'colocacion' then
        if AOscuras() then
            FreezeEntityPosition(ped, true)
            Core.Oscuro(true)
        end
    elseif d.fase == 'busqueda' then
        if EsProp() then
            Prop.Congelar(true)
            Core.Banner('Quieto', 'Empieza la caza', 'Ya no te puedes mover. Aguanta.', 2.6)
        elseif EsCazador() then
            FreezeEntityPosition(ped, false)
            Core.Oscuro(false)
            Core.DarArma(E.Cazador.arma)
            Core.Banner('¡A por ellos!', 'Sal a cazar', 'Cada disparo que no acierte te quita vida.', 2.6)
        end
    end
end

function M.FinRonda()
    Prop.Quitar()
    Prop.Congelar(false)
    st.pista = nil
    OrigenMapa.Quitar('pista')
end

function M.Eliminado()
    Prop.Quitar()
end

function M.Salir()
    Prop.Quitar()
    Prop.Congelar(false)
    OrigenMapa.Quitar('pista')
end
M.Restaurar = M.Salir

function M.Devuelto(d)
    local ped = PlayerPedId()
    SetEntityCoords(ped, d.x + 0.0, d.y + 0.0, d.z + 0.0, false, false, false, false)
    if d.quieto then
        if EsProp() then Prop.Congelar(true) else FreezeEntityPosition(ped, true) end
    end
    return true
end

function M.BlancoEspectador(fila)
    if fila.rol ~= 'prop' then return nil end
    for _, obj in ipairs(GetGamePool('CObject')) do
        if Entity(obj).state.escondite == fila.id then return obj end
    end
    return nil
end

--[[ ── Lo que llega del servidor ──────────────────────────────────────────── ]]
RegisterNetEvent('origen_games:escondite:c:modelo', function(ficha)
    if not Juego.activo or Juego.juego ~= ID or not EsProp() then return end
    local cambia = not st.prop or st.prop.modelo ~= ficha.modelo
    st.prop = ficha

    local copia = st.copiaPendiente
    st.copiaPendiente = nil
    if copia and copia.modelo == ficha.modelo and copia.rumbo then
        SetEntityHeading(PlayerPedId(), copia.rumbo)
    end

    Prop.Transformar(ficha)
    -- El servidor lo reenvía si no ve el objeto; eso no es un cambio de prop.
    if cambia then Core.Aviso('Ahora eres: ' .. (ficha.nombre or ficha.modelo), 'info') end
end)

RegisterNetEvent('origen_games:escondite:c:infectado', function(d)
    if not Juego.activo or Juego.juego ~= ID then return end
    Juego.rol = 'cazador'
    st.prop = nil
    Prop.Quitar()
    Prop.Congelar(false)
    SetEntityVisible(PlayerPedId(), true, false)
    Core.DarArma(E.Cazador.arma)
    Core.Banner('Te ha cazado ' .. (d.por or 'alguien'), 'Ahora cazas tú', 'Tienes arma. Encuentra a los que quedan.', 3.5)
end)

RegisterNetEvent('origen_games:escondite:c:sonar', function(d)
    if not Juego.activo or Juego.juego ~= ID then return end
    st.enfriamientos.sonar = Core.Ahora() + d.enfriamiento * 1000
    local texto = d.cuantos == 0 and ('Sonar: nada a menos de %d m.'):format(d.radio)
        or d.cuantos == 1 and ('Sonar: hay 1 prop a menos de %d m.'):format(d.radio)
        or ('Sonar: hay %d props a menos de %d m.'):format(d.cuantos, d.radio)
    Core.Aviso(texto, d.cuantos > 0 and 'caza' or 'info')
end)

RegisterNetEvent('origen_games:escondite:c:ruido', function(d)
    if not Juego.activo or Juego.juego ~= ID then return end
    st.enfriamientos.ruido = Core.Ahora() + d.enfriamiento * 1000
    Core.Aviso('Ruido lanzado: los props cercanos han sonado.', 'info')
end)

RegisterNetEvent('origen_games:escondite:c:pista', function(d)
    if not Juego.activo or Juego.juego ~= ID then return end
    st.pista = { x = d.x, y = d.y, z = d.z, radio = d.radio, hasta = Core.Ahora() + d.duracion * 1000 }
    OrigenMapa.Poner('pista', {
        x = d.x, y = d.y, z = d.z, radio = d.radio,
        cat = 'activities', icono = 'juego', nombre = 'Pista: hay un prop por aquí', pulso = true,
    })
    Core.Aviso('Pista: hay un prop dentro de la zona marcada.', 'caza')
    SetTimeout(d.duracion * 1000, function() OrigenMapa.Quitar('pista') end)
end)

RegisterNetEvent('origen_games:escondite:c:huir', function(d)
    if not Juego.activo or Juego.juego ~= ID or not EsProp() then return end
    st.huyendoHasta = Core.Ahora() + d.segundos * 1000
    Prop.Congelar(false)
    Core.Aviso(('¡Corre! Tienes %d segundos para cambiar de sitio.'):format(d.segundos), 'caza')
    SetTimeout(d.segundos * 1000, function()
        if Juego.activo and EsProp() and Juego.fase == 'busqueda' then
            st.huyendoHasta = nil
            Prop.Congelar(true)
        end
    end)
end)

--[[ ── El cazador: a qué ha dado ───────────────────────────────────────────── ]]

--- Los props de la partida que ve este cliente, con su centro y su tamaño.
local function RefrescarProps()
    local lista = {}
    local yo = Core.Yo()
    for _, obj in ipairs(GetGamePool('CObject')) do
        local id = Entity(obj).state.escondite
        if id and id ~= yo then
            local minimo, maximo = GetModelDimensions(GetEntityModel(obj))
            SetEntityCanBeDamaged(obj, false)
            lista[#lista + 1] = {
                obj = obj,
                id = id,
                ped = Core.PedDe(id) or 0,
                cx = (minimo.x + maximo.x) * 0.5,
                cy = (minimo.y + maximo.y) * 0.5,
                cz = (minimo.z + maximo.z) * 0.5,
                radio = math.max(maximo.x - minimo.x, maximo.y - minimo.y, maximo.z - minimo.z) * 0.5,
            }
        end
    end
    st.props = lista
end

--[[ No se fía de dónde pega la bala de GTA: el objeto del prop va sin
     colisión mientras se mueve y el disparo lo atravesaría. Se traza la línea
     de la mira y se mira qué prop queda más cerca de ella, sin pared delante.
     El servidor vuelve a comprobar que ese prop exista, esté vivo y a tiro. ]]
local function Disparar()
    local ped = PlayerPedId()
    local cam = GetFinalRenderedCamCoord()
    local dir = Core.Direccion(GetFinalRenderedCamRot(2))
    local alcance = E.Cazador.alcance + 15.0
    local hasta = cam + dir * alcance

    local prueba = StartExpensiveSynchronousShapeTestLosProbe(cam.x, cam.y, cam.z,
        hasta.x, hasta.y, hasta.z, 1, ped, 7)
    local _, toca, punto = GetShapeTestResult(prueba)
    local pared = (toca == 1) and #(punto - cam) or alcance

    local mejor, mejorT
    for _, p in ipairs(st.props) do
        if DoesEntityExist(p.obj) then
            local centro = GetOffsetFromEntityInWorldCoords(p.obj, p.cx, p.cy, p.cz)
            local v = centro - cam
            local t = v.x * dir.x + v.y * dir.y + v.z * dir.z
            if t > 0.0 and t <= pared + p.radio then
                local d = #(centro - (cam + dir * t))
                if d <= math.max(0.35, p.radio * 0.9) and (not mejorT or t < mejorT) then
                    mejor, mejorT = p, t
                end
            end
        end
    end

    TriggerServerEvent('origen_games:escondite:s:disparo', mejor and mejor.id or false)
end

--[[ ── Cada fotograma ─────────────────────────────────────────────────────── ]]
local function Pulsada(tecla) return IsDisabledControlJustPressed(0, tecla.control) end

function M.Frame(ahora)
    local ped = PlayerPedId()
    local fase = Juego.fase
    local en = st.enfriamientos
    local yo = Yo()

    DisableControlAction(0, T.cambiar.control, true)
    DisableControlAction(0, T.burla.control, true)
    DisableControlAction(0, T.huir.control, true)
    DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true)
    DisableControlAction(0, 142, true)
    DisableControlAction(0, 44, true)

    if not (EsCazador() and fase == 'busqueda') then
        DisablePlayerFiring(PlayerId(), true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 257, true)
    end

    if EsProp() then
        if Colocando() then
            -- El láser: cada fotograma, para que la línea no vaya a saltos.
            local info = Prop.Apuntar()
            Prop.DibujarLaser(info)
            if info.ficha and not (st.prop and info.ficha.modelo == st.prop.modelo) then
                st.copiable = {
                    nombre = info.ficha.nombre, tamano = info.ficha.tamano, modelo = info.ficha.modelo,
                    hash = info.hash, punto = info.punto, rumbo = GetEntityHeading(info.ent),
                }
            else
                st.copiable = nil
            end

            DisableControlAction(0, T.copiar.control, true)
            if Pulsada(T.cambiar) and (yo.cambios or 0) > 0 and ahora > en.cambiar then
                en.cambiar = ahora + 800
                TriggerServerEvent('origen_games:escondite:s:cambiar')
            end
            if Pulsada(T.copiar) and st.copiable and (yo.cambios or 0) > 0 and ahora > en.cambiar then
                en.cambiar = ahora + 800
                local p = st.copiable.punto
                -- Al convertirse, se pone con la orientación del objeto copiado.
                st.copiaPendiente = { modelo = st.copiable.modelo, rumbo = st.copiable.rumbo }
                TriggerServerEvent('origen_games:escondite:s:copiar', st.copiable.hash, p.x, p.y, p.z)
            end
        else
            st.copiable = nil
        end

        if (fase == 'colocacion' or fase == 'busqueda') and Pulsada(T.burla) and ahora > en.burla then
            en.burla = ahora + E.Burlas.enfriamiento * 1000
            TriggerServerEvent('origen_games:escondite:s:burla', E.Burlas.tipos[math.random(#E.Burlas.tipos)])
        end

        if fase == 'busqueda' then
            if Pulsada(T.huir) and (yo.huidas or 0) > 0 and not st.huyendoHasta then
                TriggerServerEvent('origen_games:escondite:s:huir')
            end
            if Prop.Congelado() then DisableControlAction(0, 22, true) end
        end

        if IsDisabledControlPressed(0, T.girarIzq.control) then Prop.Girar(2.5) end
        if IsDisabledControlPressed(0, T.girarDer.control) then Prop.Girar(-2.5) end
        DisableControlAction(0, T.girarIzq.control, true)
        DisableControlAction(0, T.girarDer.control, true)
    else
        st.copiable = nil
    end

    if EsCazador() and fase == 'busqueda' then
        if Pulsada(T.cambiar) and ahora > en.sonar then
            en.sonar = ahora + 1000
            TriggerServerEvent('origen_games:escondite:s:sonar')
        end
        if Pulsada(T.huir) and ahora > en.ruido then
            en.ruido = ahora + 1000
            TriggerServerEvent('origen_games:escondite:s:ruido')
        end

        if IsPedShooting(ped) and ahora > en.disparo then
            en.disparo = ahora + E.Cazador.cadencia
            Disparar()
        end

        if GetSelectedPedWeapon(ped) ~= ARMA and (st.revisarArma or 0) < ahora then
            st.revisarArma = ahora + 500
            if not HasPedGotWeapon(ped, ARMA, false) then GiveWeaponToPed(ped, ARMA, 250, false, true) end
            SetCurrentPedWeapon(ped, ARMA, true)
            SetPedInfiniteAmmoClip(ped, true)
        end

        -- El personaje invisible de un prop no puede ser una pared.
        for _, p in ipairs(st.props) do
            if p.ped ~= 0 then SetEntityNoCollisionEntity(ped, p.ped, true) end
        end
    end

    -- El cazador de la ronda, a oscuras mientras los props se esconden.
    if Juego.activo and AOscuras() then
        if not IsScreenFadedOut() and not IsScreenFadingOut() then DoScreenFadeOut(0) end
    end

    local pista = st.pista
    if pista then
        if ahora > pista.hasta then
            st.pista = nil
        else
            DrawMarker(1, pista.x, pista.y, pista.z - 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                pista.radio * 2.0, pista.radio * 2.0, 6.0, 240, 180, 41, 60, false, false, 2, false, nil, nil, false)
        end
    end
end

function M.Lento()
    if EsCazador() then RefrescarProps() end
end

--[[ ── El HUD ─────────────────────────────────────────────────────────────── ]]
local TAMANOS = { pequeno = 'Pequeño', mediano = 'Mediano', grande = 'Grande' }

local function Carga(hasta, total)
    local quedan = Core.Resta(hasta)
    if quedan <= 0 or total <= 0 then return nil, quedan end
    return 1 - quedan / total, quedan
end

function M.Ficha()
    if Juego.eliminado then return nil end
    local yo = Yo()
    local en = st.enfriamientos
    local fase = Juego.fase

    if Juego.rol == 'cazador' then
        local acciones = {}
        if fase == 'busqueda' then
            local cargaS, quedanS = Carga(en.sonar, E.Herramientas.sonar.enfriamiento)
            local cargaR, quedanR = Carga(en.ruido, E.Herramientas.ruido.enfriamiento)
            acciones = {
                { id = 'disparar', tecla = 'Clic', nombre = 'Disparar', extra = ('−%d si fallas'):format(E.Cazador.fallo) },
                { id = 'sonar', tecla = T.cambiar.texto, nombre = 'Sonar', extra = quedanS > 0 and (quedanS .. 's') or nil, apagada = quedanS > 0, carga = cargaS },
                { id = 'ruido', tecla = T.huir.texto, nombre = 'Ruido', extra = quedanR > 0 and (quedanR .. 's') or nil, apagada = quedanR > 0, carga = cargaR },
            }
        end
        local vivos = 0
        for _, c in ipairs(Juego.contadores or {}) do
            if c.k == 'Props' then vivos = c.v end
        end
        local max = yo.vidaMax or E.Cazador.vida
        local vida = yo.vida or max
        return {
            tono = 'caza', icono = 'cazador',
            rol = yo.infectado and 'Cazador · infectado' or 'Cazador',
            nombre = fase == 'busqueda' and 'A por ellos' or 'A oscuras',
            renglon = fase == 'busqueda' and (vivos .. ' props escondidos') or 'Los props se esconden',
            puntos = yo.puntos or 0,
            vida = { tipo = 'barra', etiqueta = 'Vida', pct = max > 0 and math.floor(vida / max * 100) or 0, cifra = tostring(vida) },
            acciones = acciones,
        }
    end

    local p = st.prop or {}
    local acciones = {}
    if Colocando() then
        acciones[#acciones + 1] = { id = 'cambiar', tecla = T.cambiar.texto, nombre = 'Otro prop', extra = tostring(yo.cambios or 0), apagada = not ((yo.cambios or 0) > 0) }
        acciones[#acciones + 1] = { id = 'copiar', tecla = T.copiar.texto, nombre = st.copiable and ('Copiar ' .. st.copiable.nombre) or 'Copiar', apagada = not st.copiable or not ((yo.cambios or 0) > 0) }
    end
    if fase ~= 'preparacion' then
        local cargaB, quedanB = Carga(en.burla, E.Burlas.enfriamiento)
        acciones[#acciones + 1] = { id = 'burla', tecla = T.burla.texto, nombre = 'Burla', extra = quedanB > 0 and (quedanB .. 's') or nil, apagada = quedanB > 0, carga = cargaB }
    end
    if fase == 'busqueda' then
        local corre = st.huyendoHasta and Core.Resta(st.huyendoHasta) or 0
        acciones[#acciones + 1] = { id = 'huir', tecla = T.huir.texto, nombre = corre > 0 and ('¡Corre! ' .. corre .. 's') or 'Huir', extra = tostring(yo.huidas or 0), apagada = not ((yo.huidas or 0) > 0) and corre == 0 }
    end
    acciones[#acciones + 1] = { id = 'girar', tecla = T.girarIzq.texto .. ' ' .. T.girarDer.texto, nombre = 'Girar' }

    local dano = E.Cazador.dano
    local vidaMax = yo.vidaMax or p.vidaMax or 0
    local vida = yo.vida or p.vida or 0

    return {
        tono = 'prop', icono = 'prop',
        rol = 'Prop',
        nombre = p.nombre or 'Prop',
        renglon = (TAMANOS[p.tamano] or '') .. ' · ' .. (Prop.Congelado() and 'quieto' or 'puedes moverte'),
        puntos = yo.puntos or 0,
        vida = {
            tipo = 'golpes', etiqueta = 'Aguantas',
            total = math.max(1, math.ceil(vidaMax / dano)),
            quedan = math.max(0, math.ceil(vida / dano)),
        },
        acciones = acciones,
        -- Lo que el láser tiene delante, en grande sobre la mira.
        pista = Colocando() and st.copiable and { tecla = T.copiar.texto, texto = 'Copiar', destacado = st.copiable.nombre, detalle = TAMANOS[st.copiable.tamano] } or nil,
    }
end

function M.Cartel()
    if AOscuras() then
        return {
            k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = 'Eres el cazador',
            cifra = Core.Resta(Juego.finFase),
            formato = 'reloj',
            m = 'Los props se están escondiendo. En cuanto acabe el tiempo, sal a buscarlos.',
        }
    end
    if EsProp() and Juego.fase == 'preparacion' then
        local caza = st.cazadores and #st.cazadores > 0 and table.concat(st.cazadores, ', ') or 'alguien'
        local tiempo = st.colocacion or 0
        return {
            k = ('Ronda %d de %d'):format(Juego.ronda or 0, Juego.rondas or 0),
            t = 'Eres: ' .. ((st.prop and st.prop.nombre) or 'un prop'),
            m = ('Caza %s. Tienes %d:%02d para esconderte.'):format(caza, math.floor(tiempo / 60), tiempo % 60),
        }
    end
    return nil
end

function M.Fondo()
    if AOscuras() then return 'cazador' end
    if EsProp() and Juego.fase == 'preparacion' then return 'prop' end
    return nil
end

RegistrarJuego(ID, M)
