--[[ ── Herramientas para colocar la escuela (solo staff) ───────────────────────

     /vuelopunto      copia al portapapeles dónde estás (o tu aparato) como
                      vec4(x, y, z, rumbo), listo para pegar en config.lua.
     /vuelopista      pinta la pista tal como la tiene el config: eje, bordes,
                      cabeceras y las marcas de cada 100 m. Sirve para ver si
                      los extremos están bien medidos.
     /vueloruta <id>  pinta todos los puntos de un examen (basica,
                      media_avion, media_heli, alta) con una raya entre ellos,
                      para repasar el circuito volando. Sin id, lo apaga.

     Solo pintan en TU pantalla; no cambian nada para nadie. ]]

--[[ Rótulo «pegatina» en pantalla, centrado en (sx, sy): sombra dura,
     canto negro fino, pieza gris claro (rosa si acento) y tinta negra. ]]
local function Chapa(sx, sy, texto, escala, acento)
    texto = (tostring(texto or ''):gsub('~', ''))
    escala = escala or 0.35
    BeginTextCommandGetWidth('STRING')
    AddTextComponentSubstringPlayerName(texto)
    SetTextFont(4)
    SetTextScale(escala, escala)
    local w = EndTextCommandGetWidth(true) + 0.012
    local alto = GetRenderedCharacterHeight(escala, 4)
    local h = alto + 0.012
    DrawRect(sx + 0.0022, sy + 0.0040, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    DrawRect(sx, sy, w + 0.0015, h + 0.0027, 0, 0, 0, 255)
    if acento then
        DrawRect(sx, sy, w, h, 216, 27, 85, 255)
    else
        DrawRect(sx, sy, w, h, 220, 221, 224, 255)
    end
    SetTextFont(4)
    SetTextScale(escala, escala)
    SetTextColour(11, 11, 13, 255)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(texto)
    EndTextCommandDisplayText(sx, sy - alto * 0.62)
end


local function EsStaff()
    return lib.callback.await('origen_aviacion:esStaff', false) == true
end

RegisterCommand('vuelopunto', function()
    if not EsStaff() then return end
    local ent = cache.vehicle or cache.ped
    local c = GetEntityCoords(ent)
    local z = c.z
    if not cache.vehicle then z = z - 1.0 end
    local txt = ('vec4(%.1f, %.1f, %.1f, %.1f)'):format(c.x, c.y, z, GetEntityHeading(ent))
    lib.setClipboard(txt)
    print('[aviacion] ' .. txt)
    local d, l = Vuelo.AEjes(c)
    A.Aviso(('%s copiado. En ejes de pista: %.0f m a lo largo, %.0f m al lado.'):format(txt, d, l), 'success', 8000)
end, false)

local pista, ruta = false, nil

local function Linea(a, b, r, g, bl)
    DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, r, g, bl, 255)
end

local function Bucle()
    while pista or ruta do
        if pista then
            local w, L = Config.Pista.semiancho, Vuelo.P.L
            for _, l in ipairs({ -w, 0.0, w }) do
                Linea(Vuelo.EnPista(0.0, l) + vec3(0, 0, 0.5), Vuelo.EnPista(L, l) + vec3(0, 0, 0.5), l == 0.0 and 255 or 60, 220, 120)
            end
            for d = 0, math.floor(L), 100 do
                Linea(Vuelo.EnPista(d, -w) + vec3(0, 0, 0.5), Vuelo.EnPista(d, w) + vec3(0, 0, 0.5), 220, 221, 224)
            end
            for _, c in ipairs({ Config.Pista.este, Config.Pista.oeste }) do
                DrawMarker(1, c.x, c.y, c.z - 1.0, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 30.0, 216, 27, 85, 160, false, false, 2, false, nil, nil, false)
            end
        end
        if ruta then
            local prev
            for i, e in ipairs(ruta.etapas) do
                local p = e.pos
                if e.tipo == 'aterrizar' or e.tipo == 'toque' then p = Vuelo.EnPista((e.desde + e.hasta) / 2, 0.0) end
                if p then
                    local z = p.z
                    if e.tipo == 'aro' then
                        local top = GetHeightmapTopZForPosition(p.x + 0.0, p.y + 0.0)
                        z = e.agl and top + e.agl or math.max(p.z, top + (e.sobre or 60.0))
                        DrawMarker(6, p.x, p.y, z, 0, 0, 0, 0, 0, 0, e.radio * 2, e.radio * 2, e.radio * 2, 216, 27, 85, 120, false, true, 2, false, nil, nil, false)
                    else
                        DrawMarker(1, p.x, p.y, z - 1.0, 0, 0, 0, 0, 0, 0, (e.radio or 10) * 2, (e.radio or 10) * 2, 2.0, 60, 220, 120, 120, false, false, 2, false, nil, nil, false)
                    end
                    local actual = vec3(p.x, p.y, z)
                    if prev then Linea(prev, actual, 220, 221, 224) end
                    prev = actual
                    local on, sx, sy = World3dToScreen2d(p.x, p.y, z + 8.0)
                    if on then
                        Chapa(sx, sy, ('%d · %s'):format(i, e.tipo), 0.35, e.tipo == 'aro')
                    end
                end
            end
        end
        Wait(0)
    end
end

RegisterCommand('vuelopista', function()
    if not EsStaff() then return end
    pista = not pista
    A.Aviso(pista and 'Pista a la vista.' or 'Pista oculta.', 'inform')
    if pista and not ruta then CreateThread(Bucle) end
end, false)

RegisterCommand('vueloruta', function(_, args)
    if not EsStaff() then return end
    local id = args[1]
    local habia = pista or ruta
    ruta = id and Config.Examenes[id] or nil
    A.Aviso(ruta and ('Ruta de %s a la vista.'):format(ruta.nombre) or 'Ruta oculta.', 'inform')
    if ruta and not habia then CreateThread(Bucle) end
end, false)
