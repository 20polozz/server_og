--[[ ── Herramientas para colocar la autoescuela (solo staff) ───────────────────

     /autopunto        copia al portapapeles dónde estás (o tu vehículo) como
                       vec4(x, y, z, rumbo), listo para pegar en config.lua.
     /autoruta         pinta el recorrido del examen tal como lo tiene el
                       config: una columna en cada punto y una raya entre
                       ellos, con el número y el límite de cada tramo.
     /autoplaza        pinta la plaza de aparcamiento del final.

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
    return lib.callback.await('origen_autoescuela:esStaff', false) == true
end

RegisterCommand('autopunto', function()
    if not EsStaff() then return end
    local ent = cache.vehicle or cache.ped
    local c = GetEntityCoords(ent)
    local z = c.z
    if not cache.vehicle then z = z - 1.0 end
    local txt = ('vec4(%.2f, %.2f, %.2f, %.2f)'):format(c.x, c.y, z, GetEntityHeading(ent))
    lib.setClipboard(txt)
    print('[autoescuela] ' .. txt)
    A.Aviso(txt .. ' copiado.', 'success', 8000)
end, false)

local ruta, plaza = false, false

local function Bucle()
    while ruta or plaza do
        if ruta then
            local prev
            for i, p in ipairs(Config.Ruta) do
                local z = (A.Suelo(p.pos.x, p.pos.y, p.pos.z + 5.0) or p.pos.z)
                DrawMarker(1, p.pos.x, p.pos.y, z - 0.5, 0, 0, 0, 0, 0, 0, 6.0, 6.0, 3.0,
                    p.stop and 220 or 216, p.stop and 221 or 27, p.stop and 224 or 85, 90, false, false, 2, false, nil, nil, false)
                local actual = vec3(p.pos.x, p.pos.y, z)
                if prev then DrawLine(prev.x, prev.y, prev.z + 1.0, actual.x, actual.y, actual.z + 1.0, 220, 221, 224, 255) end
                prev = actual
                local on, sx, sy = World3dToScreen2d(p.pos.x, p.pos.y, z + 3.0)
                if on then
                    Chapa(sx, sy, ('%d%s · %d'):format(i, p.stop and ' STOP' or '', math.floor(p.limite or Config.Limite)), 0.35, not p.stop)
                end
            end
        end
        if plaza then
            local c = Config.Aparcamiento
            local h = math.rad(c.rumbo)
            local fx, fy = -math.sin(h), math.cos(h)
            local dx, dy = fy, -fx
            local z = (A.Suelo(c.centro.x, c.centro.y, c.centro.z + 5.0) or c.centro.z) + 0.05
            local esq = {}
            for i, s in ipairs({ { 1, 1 }, { 1, -1 }, { -1, -1 }, { -1, 1 } }) do
                esq[i] = vec3(c.centro.x + fx * (c.largo / 2) * s[1] + dx * (c.ancho / 2) * s[2],
                              c.centro.y + fy * (c.largo / 2) * s[1] + dy * (c.ancho / 2) * s[2], z)
            end
            for i = 1, 4 do
                local a, b = esq[i], esq[i % 4 + 1]
                DrawLine(a.x, a.y, a.z, b.x, b.y, b.z, 216, 27, 85, 255)
            end
        end
        Wait(0)
    end
end

RegisterCommand('autoruta', function()
    if not EsStaff() then return end
    local habia = ruta or plaza
    ruta = not ruta
    A.Aviso(ruta and ('Recorrido a la vista (%d puntos).'):format(#Config.Ruta) or 'Recorrido oculto.', 'inform')
    if ruta and not habia then CreateThread(Bucle) end
end, false)

RegisterCommand('autoplaza', function()
    if not EsStaff() then return end
    local habia = ruta or plaza
    plaza = not plaza
    A.Aviso(plaza and 'Plaza a la vista.' or 'Plaza oculta.', 'inform')
    if plaza and not habia then CreateThread(Bucle) end
end, false)
