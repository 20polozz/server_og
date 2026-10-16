--[[ ── Los puntos que se pueden mover en el juego ─────────────────────────────

     El editor (`/aserraderoeditor`) mueve estos sitios y los guarda en
     `shared/puntos.json`, que se lee al arrancar y pisa lo que hay en
     config.lua. Así el patio se coloca a ojo, dentro del juego, sin tocar
     código: lo que se guarda son solo coordenadas.

     Cada punto dice cómo se lee y cómo se escribe sobre Config. `rumbo` a
     false significa que ese sitio solo tiene posición (no mira a ningún
     lado). ]]

local A = Config.Aserradero

--- La lista, en el orden en que sale en el editor.
Lumber.Sitios = {
    { id = 'ped_encargado', nombre = 'NPC: encargado (jornada, hacha y camión)', rumbo = true,
      leer = function() return A.Peds.Encargado.coords end,
      poner = function(v) A.Peds.Encargado.coords = v end },

    { id = 'descarga', nombre = 'Bahía de entrega del camión', rumbo = true,
      leer = function() return A.descarga.coords end,
      poner = function(v) A.descarga.coords = v end },

    { id = 'rampa', nombre = 'Hacia dónde ruedan los troncos al entregar', rumbo = false,
      leer = function() return A.rampa end,
      poner = function(v) A.rampa = v end },

    { id = 'salida1', nombre = 'Salida del camión 1', rumbo = true,
      leer = function() return A.salidas[1] end,
      poner = function(v) A.salidas[1] = v end },

    { id = 'salida2', nombre = 'Salida del camión 2', rumbo = true,
      leer = function() return A.salidas[2] end,
      poner = function(v) A.salidas[2] = v end },

    { id = 'salida3', nombre = 'Salida del camión 3', rumbo = true,
      leer = function() return A.salidas[3] end,
      poner = function(v) A.salidas[3] = v end },

    { id = 'devolver', nombre = 'Sitio donde se deja el camión', rumbo = false,
      leer = function() return A.devolver.coords end,
      poner = function(v) A.devolver.coords = v end },
}

-- 28/09: las máquinas de la línea de sierra y sus carteles (Config.Linea).
if Config.Linea then
    local L = Config.Linea
    local nombres = {
        { 'grua', 'Máquina: grúa pórtico' }, { 'parque', 'Máquina: parque de troncos' },
        { 'descortezadora', 'Máquina: descortezadora' }, { 'sierra', 'Máquina: sierra de cinta' },
        { 'apiladora', 'Máquina: apiladora' }, { 'secadero', 'Máquina: secadero' },
        { 'cinta', 'Máquina: cinta al secadero' },
    }
    for _, n in ipairs(nombres) do
        Lumber.Sitios[#Lumber.Sitios + 1] = { id = 'maq_' .. n[1], nombre = n[2], rumbo = true, maquina = n[1],
            leer = function() return L.maquinas[n[1]] end,
            poner = function(v) L.maquinas[n[1]] = v end }
    end
    for i, d in ipairs(L.decorado or {}) do
        if d[1]:find('^origen_') then
            Lumber.Sitios[#Lumber.Sitios + 1] = { id = 'deco_' .. i, nombre = 'Cartel: ' .. d[1]:gsub('^origen_as_', ''), rumbo = true,
                leer = function() return L.decorado[i][2] end,
                poner = function(v) L.decorado[i][2] = v end }
        end
    end
end

Lumber.SitioPorId = {}
for _, p in ipairs(Lumber.Sitios) do Lumber.SitioPorId[p.id] = p end

--- Lo que hay ahora en Config, listo para guardar.
function Lumber.SitiosAhora()
    local t = {}
    for _, p in ipairs(Lumber.Sitios) do
        local v = p.leer()
        if v then
            t[p.id] = { x = v.x + 0.0, y = v.y + 0.0, z = v.z + 0.0, w = p.rumbo and (v.w or 0.0) + 0.0 or nil }
        end
    end
    return t
end

--- Pisa Config con lo guardado (lo llaman el arranque y el editor).
function Lumber.AplicarSitios(t)
    if type(t) ~= 'table' then return 0 end
    local n = 0
    for id, v in pairs(t) do
        local p = Lumber.SitioPorId[id]
        if p and tonumber(v.x) and tonumber(v.y) and tonumber(v.z) then
            if p.rumbo then
                p.poner(vec4(v.x + 0.0, v.y + 0.0, v.z + 0.0, (tonumber(v.w) or 0.0) + 0.0))
            else
                p.poner(vec3(v.x + 0.0, v.y + 0.0, v.z + 0.0))
            end
            n = n + 1
        end
    end
    return n
end

-- Al arrancar: si hay puntos guardados, mandan ellos.
local guardado = LoadResourceFile(GetCurrentResourceName(), 'shared/puntos.json')
if guardado then
    local ok, t = pcall(json.decode, guardado)
    if ok then Lumber.AplicarSitios(t) end
end
