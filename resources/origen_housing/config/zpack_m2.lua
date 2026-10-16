-- Packs de CONSTRUCCIÓN de la tanda m2 (13/10): diez packs temáticos de materiales
-- de pintar (suelos, paredes y techos) y uno de cristales de color.
--
-- Todo lo de estos packs se da de alta AQUÍ: los materiales se añaden a
-- Config.Obra.materiales (config/obra.lua se carga antes: orden alfabético) y a
-- su subgrupo de la cinta (Config.Cinta.materiales), y después se registran los
-- packs. No hay que tocar config/obra.lua ni config/cinta.lua.
--
--   · Texturas: origen_housing/fuente/texturas_m2.py (siempre del propio juego).
--   · Piezas (origen_casa_<pieza>_<id>, las mismas 13 de cada material; 5 los
--     cristales): origen_housing/fuente/obra_m2.py, sin Blender. Van en
--     origen_modelos/stream/casa_obra con origen_casa_m2.ytyp y un diccionario
--     por pack (origen_casa_txm_<pack>).
--   · Miniaturas: ui/img/obra/<id>.jpg. Hojas de muestra: fuente/render/materiales_m2_<pack>.png.
--
-- Cada material lleva su escala (2, 1 o 0,5 m por vuelta de la textura) para
-- que baldosas e hiladas casen de una celda a la siguiente: eso va en la UV de
-- sus piezas, aquí no hay nada que configurar.
-- Precio: `xp` de cada pack (mínimo 300, decisión del dueño). Si se quiere fijar
-- en config/zz_economia.lua (packs = { … }), manda lo de allí.
local O, P, T = Config.Obra, Config.Packs, Config.Cinta
if not (O and O.materiales and P and P.Registrar) then return end

local YA = {}
for _, m in ipairs(O.materiales) do YA[m.id] = true end

-- Da de alta los materiales de un pack y devuelve sus ids.
--   { id, nombre, subgrupo de la cinta [, true si es cristal] }
-- Los cristales son `interior`: solo entre dos espacios de la casa (config/obra.lua).
local function Materiales(lista)
    local ids = {}
    for _, m in ipairs(lista) do
        if not YA[m[1]] then
            YA[m[1]] = true
            O.materiales[#O.materiales + 1] = { id = m[1], nombre = m[2], interior = m[4] or nil }
        end
        if T and T.materiales then T.materiales[m[1]] = m[3] end
        ids[#ids + 1] = m[1]
    end
    return ids
end

-- ── Loft industrial (9) ───────────────────────────────────────────────
P.Registrar({
    id = 'mat_industrial', nombre = 'Loft industrial', grupo = 'construccion', xp = 300,
    descripcion = 'Hormigón encofrado, chapa de acero, ladrillo pintado, rejilla y resina: nueve acabados para naves, lofts y talleres con mucho carácter.',
    materiales = Materiales({
        { 'hormigon_encofrado', 'Hormigón encofrado', 'Ladrillo y piedra' },
        { 'hormigon_tablilla', 'Hormigón de tablilla', 'Ladrillo y piedra' },
        { 'chapa_acero', 'Chapa de acero', 'Urbano y sucio' },
        { 'chapa_blanca', 'Chapa perfilada blanca', 'Urbano y sucio' },
        { 'ladrillo_blanco', 'Ladrillo pintado de blanco', 'Ladrillo y piedra' },
        { 'ladrillo_oscuro', 'Ladrillo oscuro', 'Ladrillo y piedra' },
        { 'rejilla_acero', 'Rejilla de acero', 'Suelos' },
        { 'resina_gris', 'Resina gris', 'Suelos' },
        { 'goma_tacos', 'Goma de tacos', 'Suelos' },
    }),
})

-- ── Zen japonés (9) ───────────────────────────────────────────────────
P.Registrar({
    id = 'mat_japones', nombre = 'Zen japonés', grupo = 'construccion', xp = 300,
    descripcion = 'Tatami, paneles shoji, listones de cedro, wengué, arce y basalto: lo justo para una casa de té, un dojo o un dormitorio en calma.',
    materiales = Materiales({
        { 'tatami', 'Tatami', 'Suelos' },
        { 'shoji', 'Panel shoji', 'Paredes lisas' },
        { 'wengue', 'Madera de wengué', 'Madera' },
        { 'listones_cedro', 'Listones de cedro', 'Madera' },
        { 'arce', 'Madera de arce', 'Madera' },
        { 'roble_ahumado', 'Roble ahumado', 'Madera' },
        { 'basalto', 'Basalto negro', 'Ladrillo y piedra' },
        { 'estuco_arena', 'Estuco de arena', 'Paredes lisas' },
        { 'mimbre', 'Esterilla de mimbre', 'Suelos' },
    }),
})

-- ── Casa de campo (9) ─────────────────────────────────────────────────
P.Registrar({
    id = 'mat_rustico', nombre = 'Casa de campo', grupo = 'construccion', xp = 300,
    descripcion = 'Sillería, muro de piedra, cal, terracota, tablones y ladrillo de tejar: el interior de un cortijo o de una cabaña de montaña.',
    materiales = Materiales({
        { 'silleria', 'Sillería de arenisca', 'Ladrillo y piedra' },
        { 'piedra_gris', 'Muro de piedra gris', 'Ladrillo y piedra' },
        { 'gres_rustico', 'Gres rústico', 'Suelos' },
        { 'encalado', 'Pared encalada', 'Paredes lisas' },
        { 'enfoscado_ocre', 'Enfoscado ocre', 'Paredes lisas' },
        { 'ladrillo_tejar', 'Ladrillo de tejar', 'Ladrillo y piedra' },
        { 'tablon_rancho', 'Tablón de rancho', 'Madera' },
        { 'tablon_pino', 'Tablón de pino', 'Madera' },
        { 'terracota_rustica', 'Terracota de cortijo', 'Suelos' },
    }),
})

-- ── Art déco y casino (11) ─────────────────────────────────────────────
P.Registrar({
    id = 'mat_casino', nombre = 'Art déco y casino', grupo = 'construccion', xp = 300,
    descripcion = 'Terciopelo granate, tapete verde, mármol verde, latón, mosaico dorado, damero y papeles en negro y oro: una sala de juego privada con todo su brillo.',
    materiales = Materiales({
        { 'terciopelo_granate', 'Terciopelo granate', 'Lujo' },
        { 'tapete_verde', 'Tapete verde', 'Lujo' },
        { 'marmol_verde', 'Mármol verde', 'Lujo' },
        { 'laton', 'Latón envejecido', 'Lujo' },
        { 'mosaico_oro', 'Mosaico dorado', 'Lujo' },
        { 'moqueta_casino', 'Moqueta de casino', 'Suelos' },
        { 'moqueta_greca', 'Moqueta de greca', 'Suelos' },
        { 'marmol_deco', 'Mármol déco', 'Lujo' },
        { 'damero_marmol', 'Damero de mármol', 'Lujo' },
        { 'papel_deco', 'Papel déco negro y oro', 'Lujo' },
        { 'papel_barroco', 'Papel barroco dorado', 'Lujo' },
    }),
})

-- ── Club nocturno (11) ─────────────────────────────────────────────────
P.Registrar({
    id = 'mat_club', nombre = 'Club nocturno', grupo = 'construccion', xp = 300,
    descripcion = 'Lacado negro, terciopelo morado, capitoné de cuero, paneles acústicos, gresite negro y papeles atrevidos: para el reservado, la sala de fiestas o el local de ensayo.',
    materiales = Materiales({
        { 'lacado_negro', 'Lacado negro', 'Lujo' },
        { 'terciopelo_morado', 'Terciopelo morado', 'Lujo' },
        { 'capitone', 'Capitoné de cuero', 'Lujo' },
        { 'panel_acustico', 'Panel acústico', 'Paredes lisas' },
        { 'gresite_negro', 'Gresite negro', 'Suelos' },
        { 'ladrillo_negro', 'Ladrillo negro', 'Ladrillo y piedra' },
        { 'papel_besos', 'Papel de besos', 'Paredes lisas' },
        { 'papel_palmeras', 'Papel de palmeras doradas', 'Lujo' },
        { 'papel_tigres', 'Papel de tigres', 'Lujo' },
        { 'rosa_cabaret', 'Rosa cabaret', 'Paredes lisas' },
        { 'geometrico_pop', 'Geométrico blanco y negro', 'Suelos' },
    }),
})

-- ── Mediterráneo (9) ──────────────────────────────────────────────────
P.Registrar({
    id = 'mat_mediterraneo', nombre = 'Mediterráneo', grupo = 'construccion', xp = 300,
    descripcion = 'Azulejo azul y blanco, baldosa hidráulica, terracota, estuco blanco, añil y albero: luz de patio andaluz y de casa junto al mar.',
    materiales = Materiales({
        { 'azulejo_azul', 'Azulejo azul y blanco', 'Suelos' },
        { 'hidraulico', 'Baldosa hidráulica', 'Suelos' },
        { 'olambrilla', 'Baldosa con olambrilla', 'Suelos' },
        { 'estuco_blanco', 'Estuco blanco', 'Paredes lisas' },
        { 'estuco_anil', 'Estuco añil', 'Paredes lisas' },
        { 'estuco_albero', 'Estuco albero', 'Paredes lisas' },
        { 'baldosin_terracota', 'Baldosín de terracota', 'Suelos' },
        { 'ladrillo_soleria', 'Ladrillo de solería', 'Suelos' },
        { 'azulejo_cobalto', 'Azulejo cobalto', 'Paredes lisas' },
    }),
})

-- ── Clínica y laboratorio (9) ─────────────────────────────────────────
P.Registrar({
    id = 'mat_clinica', nombre = 'Clínica y laboratorio', grupo = 'construccion', xp = 300,
    descripcion = 'Azulejo metro, baldosa blanca, linóleo, resina, panel sanitario y techo registrable: limpio y frío, para consultas, cocinas de obrador y laboratorios.',
    materiales = Materiales({
        { 'azulejo_metro', 'Azulejo metro blanco', 'Paredes lisas' },
        { 'baldosa_blanca', 'Baldosa blanca', 'Suelos' },
        { 'linoleo_azul', 'Linóleo azul', 'Suelos' },
        { 'linoleo_jaspeado', 'Linóleo jaspeado', 'Suelos' },
        { 'panel_sanitario', 'Panel sanitario', 'Paredes lisas' },
        { 'techo_registrable', 'Techo registrable', 'Paredes lisas' },
        { 'verde_quirofano', 'Verde quirófano', 'Paredes lisas' },
        { 'resina_blanca', 'Resina blanca', 'Suelos' },
        { 'terrazo_claro', 'Terrazo claro', 'Suelos' },
    }),
})

-- ── Infantil y pastel (10) ─────────────────────────────────────────────
P.Registrar({
    id = 'mat_pastel', nombre = 'Infantil y pastel', grupo = 'construccion', xp = 300,
    descripcion = 'Seis pinturas pastel, friso de lamas en blanco y en menta y moqueta mullida en rosa y celeste: para el cuarto de los niños, la sala de juegos o una casa de muñecas.',
    materiales = Materiales({
        { 'rosa_pastel', 'Rosa pastel', 'Paredes lisas' },
        { 'menta', 'Verde menta', 'Paredes lisas' },
        { 'lila', 'Lila', 'Paredes lisas' },
        { 'vainilla', 'Vainilla', 'Paredes lisas' },
        { 'celeste', 'Azul celeste', 'Paredes lisas' },
        { 'melocoton', 'Melocotón', 'Paredes lisas' },
        { 'friso_blanco', 'Friso de lamas blanco', 'Madera' },
        { 'friso_menta', 'Friso de lamas menta', 'Madera' },
        { 'moqueta_rosa', 'Moqueta rosa', 'Suelos' },
        { 'moqueta_celeste', 'Moqueta celeste', 'Suelos' },
    }),
})

-- ── Maderas nobles (12) ────────────────────────────────────────────────
P.Registrar({
    id = 'mat_madera', nombre = 'Maderas nobles', grupo = 'construccion', xp = 300,
    descripcion = 'Nogal, roble, ébano, haya, espiga, parquet Versalles, boiserie de caoba y tarimas de cerezo y decapada: doce maderas para vestir suelos y paredes.',
    materiales = Materiales({
        { 'nogal', 'Nogal en libro', 'Madera' },
        { 'roble', 'Roble natural', 'Madera' },
        { 'roble_claro', 'Roble claro', 'Madera' },
        { 'nogal_liso', 'Nogal', 'Madera' },
        { 'ebano', 'Ébano', 'Madera' },
        { 'haya', 'Tarima de haya', 'Madera' },
        { 'espiga_roble', 'Espiga de roble', 'Madera' },
        { 'parquet_versalles', 'Parquet Versalles', 'Madera' },
        { 'parquet_damas', 'Parquet de damas', 'Madera' },
        { 'boiserie_caoba', 'Boiserie de caoba', 'Madera' },
        { 'tarima_cerezo', 'Tarima de cerezo', 'Madera' },
        { 'tarima_decapada', 'Tarima decapada', 'Madera' },
    }),
})

-- ── Piedra natural (10) ────────────────────────────────────────────────
P.Registrar({
    id = 'mat_piedra', nombre = 'Piedra natural', grupo = 'construccion', xp = 300,
    descripcion = 'Granito gris y negro, travertino, ónix dorado, arenisca, terrazo veneciano y cuatro mármoles: rosado, emperador, brecha y Carrara en losas.',
    materiales = Materiales({
        { 'granito_gris', 'Granito gris', 'Ladrillo y piedra' },
        { 'granito_negro', 'Granito negro', 'Ladrillo y piedra' },
        { 'travertino', 'Travertino', 'Ladrillo y piedra' },
        { 'onix', 'Ónix dorado', 'Lujo' },
        { 'marmol_rosa', 'Mármol rosado', 'Lujo' },
        { 'marmol_carrara', 'Mármol de Carrara en losas', 'Lujo' },
        { 'marmol_emperador', 'Mármol emperador', 'Lujo' },
        { 'marmol_brecha', 'Mármol brecha', 'Lujo' },
        { 'arenisca', 'Arenisca', 'Ladrillo y piedra' },
        { 'terrazo_veneciano', 'Terrazo veneciano', 'Suelos' },
    }),
})

-- ── Cristales de color (7) ────────────────────────────────────────────
P.Registrar({
    id = 'cristales_color', nombre = 'Cristales de color', grupo = 'construccion', xp = 300,
    descripcion = 'Tabiques y suelos de cristal en verde botella, ámbar, rosa, violeta y rojo rubí, uno esmerilado a franjas y otro de cuarterones: luz de colores entre dos salas.',
    materiales = Materiales({
        { 'cristal_verde', 'Cristal verde botella', 'Cristales', true },
        { 'cristal_ambar', 'Cristal ámbar', 'Cristales', true },
        { 'cristal_rosa', 'Cristal rosa', 'Cristales', true },
        { 'cristal_violeta', 'Cristal violeta', 'Cristales', true },
        { 'cristal_rubi', 'Cristal rojo rubí', 'Cristales', true },
        { 'cristal_franjas', 'Cristal a franjas', 'Cristales', true },
        { 'cristal_cuarterones', 'Cristal de cuarterones', 'Cristales', true },
    }),
})
