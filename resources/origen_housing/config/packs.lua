-- Packs de contenido de las viviendas.
--
-- Un pack es un lote de contenido que una casa tiene o no tiene: muebles del
-- catálogo, herramientas de obra, materiales de pintar y estilos. Al crear una
-- casa se decide qué packs lleva; después se le pueden añadir (y el día de
-- mañana, venderse por XP). El pack `base` lo tienen todas.
--
-- Este fichero se carga después de config/furniture.lua (orden alfabético) y
-- antes de los config/zpack_*.lua, que son los que registran contenido:
--
--   Config.Packs.Registrar({
--       id = 'cocina_pro', nombre = 'Cocina profesional',
--       descripcion = 'Electrodomésticos de acero que se abren de verdad',
--       xp = 0,                                 -- precio en XP (0 = aún sin precio); lo fija config/zz_economia.lua
--       categorias = {                          -- muebles, por categoría del catálogo (se crea si no existe)
--           ['Cocina'] = {
--               { model = 'origen_cas_coc_nevera', price = 4500, nombre = 'Frigorífico americano' },
--           },
--       },
--       iconos = { ['Cocina'] = 'fas fa-utensils' },   -- solo para categorías nuevas
--       animados = {                            -- muebles con partes que se mueven (custom/*/almacenajes.lua)
--           ['origen_cas_coc_nevera'] = {
--               uso = 'E',                      -- 'E': se abre y se cierra con la E · 'almacen' · 'ropero': al usarlo
--               texto = { 'Abrir', 'Cerrar' },
--               partes = { { modelo = 'origen_cas_coc_nevera_puerta', pos = { 0.45, -0.35, 0.0 }, modo = 'gira', eje = 'z', angulo = 110.0, ms = 600 } },
--           },
--       },
--       herramientas = { 'ascensor2' },         -- ids de HERRAMIENTAS de la cinta (custom/client/obra.lua)
--       materiales = { 'marmol' },              -- ids de Config.Obra.materiales
--       estilos = { barandillas = { 'forja' }, secretos = { 'libreria' }, trampillas = { 'madera' } },
--   })
--
-- Lo que no está en ningún pack es del pack `base`.
Config.Packs = {
    base = 'base',
    lista = {},         -- id → pack
    orden = {},         -- ids en el orden en que se registraron
    deModelo = {},      -- nombre de modelo → id de pack
    deHerramienta = {}, -- id de herramienta de obra → id de pack
    deMaterial = {},    -- id de material → id de pack
    deEstilo = {},      -- 'barandillas:forja' → id de pack
}

-- Muebles con partes que se mueven, de cualquier pack (lo lee custom/*/almacenajes.lua)
Config.Animados = Config.Animados or {}

local P = Config.Packs

local function Categoria(etiqueta, icono)
    for _, cat in ipairs(Config.Furniture) do
        if cat.label == etiqueta then return cat end
    end
    local cat = { label = etiqueta, icon = icono or 'fas fa-cube', items = {} }
    Config.Furniture[#Config.Furniture + 1] = cat
    return cat
end

function Config.Packs.Registrar(pack)
    if type(pack) ~= 'table' or type(pack.id) ~= 'string' then return end
    local ya = P.lista[pack.id]
    if not ya then
        -- (grupo, opcional: 'tematico', 'estancia' o 'construccion'; sin él lo deduce Config.Packs.Grupo, config/zpack_00_reparto.lua)
        ya = { id = pack.id, nombre = pack.nombre or pack.id, descripcion = pack.descripcion or '', xp = pack.xp or 0, grupo = pack.grupo, modelos = {} }
        P.lista[pack.id] = ya
        P.orden[#P.orden + 1] = pack.id
    end
    for etiqueta, items in pairs(pack.categorias or {}) do
        local cat = Categoria(etiqueta, pack.iconos and pack.iconos[etiqueta])
        for _, it in ipairs(items) do
            if type(it) == 'table' and type(it.model) == 'string' and not P.deModelo[it.model] then
                -- (los de Config.Packs.basicos entran en el catálogo pero no en el pack: los tiene cualquier casa)
                local basico = P.basicos and P.basicos[it.model] == true
                if not basico then it.pack = pack.id end
                cat.items[#cat.items + 1] = it
                -- por si el índice del housing (init.lua) ya se hubiera llenado
                if __indexFurniture and not __indexFurniture[it.model] then __indexFurniture[it.model] = it end
                if basico then
                    P.deModelo[it.model] = P.base
                else
                    P.deModelo[it.model] = pack.id
                    ya.modelos[#ya.modelos + 1] = it.model
                end
            end
        end
    end
    for modelo, a in pairs(pack.animados or {}) do Config.Animados[modelo] = a end
    for _, id in ipairs(pack.herramientas or {}) do P.deHerramienta[id] = pack.id end
    for _, id in ipairs(pack.materiales or {}) do P.deMaterial[id] = pack.id end
    for grupo, ids in pairs(pack.estilos or {}) do
        for _, id in ipairs(ids) do P.deEstilo[grupo .. ':' .. id] = pack.id end
    end
end

--- Asigna a un pack muebles que YA están en el catálogo (config/furniture.lua),
--- por modelo, sin moverlos de categoría.
function Config.Packs.Asignar(id, modelos)
    local pack = P.lista[id]
    if not pack then return end
    for _, modelo in ipairs(modelos) do
        if not P.deModelo[modelo] and not (P.basicos and P.basicos[modelo]) then
            P.deModelo[modelo] = id
            pack.modelos[#pack.modelos + 1] = modelo
        end
    end
end

--- El pack al que pertenece algo: PackDe('modelo', 'origen_casa_luz_pie'),
--- PackDe('herramienta', 'ascensor'), PackDe('material', 'marmol'),
--- PackDe('estilo', 'barandillas:forja'). `base` si no está en ninguno.
function Config.Packs.PackDe(que, id)
    local t = que == 'modelo' and P.deModelo or que == 'herramienta' and P.deHerramienta or que == 'material' and P.deMaterial or P.deEstilo
    return t[id] or P.base
end

--- ¿Tiene una casa (su tabla de packs: { [id] = true }) acceso a eso?
function Config.Packs.Tiene(packsDeLaCasa, que, id)
    local pack = Config.Packs.PackDe(que, id)
    return pack == P.base or (type(packsDeLaCasa) == 'table' and packsDeLaCasa[pack] == true)
end

Config.Packs.Registrar({ id = 'base', nombre = 'Básico', descripcion = 'Lo que trae cualquier casa' })
