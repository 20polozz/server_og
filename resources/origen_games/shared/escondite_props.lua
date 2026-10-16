--[[ ── Escondite · el catálogo de props ─────────────────────────────────────

     Todo aquello en lo que se puede convertir un jugador. Sirve para dos cosas:

       1. El sorteo. Cada ubicación elige un trozo de esta lista (un parque no
          tiene neveras); si no elige nada, sortea entre todos.
       2. La copia. Un prop puede convertirse en un objeto del mapa que esté
          mirando, pero SOLO si ese objeto está aquí. Lo comprueba el servidor:
          sin la lista, bastaría con mandar el modelo de una pelota de golf
          para ser invisible.

     El tamaño decide la vida (Config.Props.vida). Un modelo que no exista en
     la versión del juego del cliente no rompe nada: el cliente avisa y el
     servidor sortea otro y no vuelve a darlo. ]]

Catalogo = {
    -- ── Pequeños: un disparo ──────────────────────────────────────────────
    { modelo = 'prop_roadcone02a', nombre = 'Cono', tamano = 'pequeno' },
    { modelo = 'prop_mp_cone_02', nombre = 'Cono de obra', tamano = 'pequeno' },
    { modelo = 'prop_gnome1', nombre = 'Gnomo', tamano = 'pequeno' },
    { modelo = 'prop_gnome2', nombre = 'Gnomo sentado', tamano = 'pequeno' },
    { modelo = 'prop_bskball_01', nombre = 'Balón', tamano = 'pequeno' },
    { modelo = 'prop_boombox_01', nombre = 'Radiocasete', tamano = 'pequeno' },
    { modelo = 'prop_tool_box_04', nombre = 'Caja de herramientas', tamano = 'pequeno' },
    { modelo = 'prop_cs_street_binbag_01', nombre = 'Bolsa de basura', tamano = 'pequeno' },
    { modelo = 'prop_rub_binbag_01', nombre = 'Bolsa de basura', tamano = 'pequeno' },
    { modelo = 'prop_beer_box_01', nombre = 'Caja de cervezas', tamano = 'pequeno' },
    { modelo = 'prop_ld_suitcase_01', nombre = 'Maleta', tamano = 'pequeno' },
    { modelo = 'prop_paper_box_02', nombre = 'Caja de cartón', tamano = 'pequeno' },
    { modelo = 'prop_cs_package_01', nombre = 'Paquete', tamano = 'pequeno' },
    { modelo = 'prop_fire_exting_1a', nombre = 'Extintor', tamano = 'pequeno' },
    { modelo = 'prop_pot_plant_01a', nombre = 'Maceta', tamano = 'pequeno' },
    { modelo = 'prop_ghettoblast_02', nombre = 'Altavoz portátil', tamano = 'pequeno' },
    { modelo = 'prop_microwave_1', nombre = 'Microondas', tamano = 'pequeno' },
    { modelo = 'prop_tv_03', nombre = 'Televisor viejo', tamano = 'pequeno' },
    { modelo = 'prop_speaker_01', nombre = 'Bafle', tamano = 'pequeno' },
    { modelo = 'prop_air_conelight', nombre = 'Baliza', tamano = 'pequeno' },
    { modelo = 'prop_wheel_tyre', nombre = 'Neumático', tamano = 'pequeno' },

    -- ── Medianos: dos disparos ────────────────────────────────────────────
    { modelo = 'prop_bin_01a', nombre = 'Papelera', tamano = 'mediano' },
    { modelo = 'prop_bin_05a', nombre = 'Papelera', tamano = 'mediano' },
    { modelo = 'prop_bin_07d', nombre = 'Cubo de basura', tamano = 'mediano' },
    { modelo = 'prop_bin_08a', nombre = 'Cubo de basura', tamano = 'mediano' },
    { modelo = 'prop_recyclebin_03_a', nombre = 'Contenedor de reciclaje', tamano = 'mediano' },
    { modelo = 'prop_barrier_work05', nombre = 'Valla de obra', tamano = 'mediano' },
    { modelo = 'prop_barrier_work06a', nombre = 'Valla de obra', tamano = 'mediano' },
    { modelo = 'prop_barrier_work01a', nombre = 'Barrera', tamano = 'mediano' },
    { modelo = 'prop_mp_barrier_02', nombre = 'Barrera', tamano = 'mediano' },
    { modelo = 'prop_box_wood01a', nombre = 'Caja de madera', tamano = 'mediano' },
    { modelo = 'prop_barrel_02a', nombre = 'Barril', tamano = 'mediano' },
    { modelo = 'prop_fire_hydrant_1', nombre = 'Boca de riego', tamano = 'mediano' },
    { modelo = 'prop_postbox_01a', nombre = 'Buzón', tamano = 'mediano' },
    { modelo = 'prop_news_disp_02a', nombre = 'Expositor de periódicos', tamano = 'mediano' },
    { modelo = 'prop_parknmeter_01', nombre = 'Parquímetro', tamano = 'mediano' },
    { modelo = 'prop_chair_04a', nombre = 'Silla', tamano = 'mediano' },
    { modelo = 'prop_chair_05', nombre = 'Silla', tamano = 'mediano' },
    { modelo = 'prop_off_chair_01', nombre = 'Silla de oficina', tamano = 'mediano' },
    { modelo = 'prop_skid_chair_02', nombre = 'Silla plegable', tamano = 'mediano' },
    { modelo = 'prop_sol_chair', nombre = 'Silla de playa', tamano = 'mediano' },
    { modelo = 'prop_table_03', nombre = 'Mesa', tamano = 'mediano' },
    { modelo = 'prop_wheelbarrow02a', nombre = 'Carretilla', tamano = 'mediano' },
    { modelo = 'prop_outdoor_fan_01', nombre = 'Ventilador', tamano = 'mediano' },
    { modelo = 'prop_watercooler_dark', nombre = 'Fuente de agua', tamano = 'mediano' },
    { modelo = 'prop_printer_01', nombre = 'Impresora', tamano = 'mediano' },
    { modelo = 'prop_fib_plant_01', nombre = 'Planta', tamano = 'mediano' },
    { modelo = 'prop_exercisebike', nombre = 'Bici estática', tamano = 'mediano' },
    { modelo = 'prop_weight_bench_02', nombre = 'Banco de pesas', tamano = 'mediano' },
    { modelo = 'prop_surf_board_01', nombre = 'Tabla de surf', tamano = 'mediano' },
    { modelo = 'prop_consign_02a', nombre = 'Cartel de obra', tamano = 'mediano' },
    { modelo = 'prop_shredder_01', nombre = 'Destructora', tamano = 'mediano' },
    { modelo = 'prop_tea_trolly', nombre = 'Carrito', tamano = 'mediano' },
    { modelo = 'prop_bbq_1', nombre = 'Barbacoa', tamano = 'mediano' },
    { modelo = 'prop_toilet_01', nombre = 'Váter', tamano = 'mediano' },
    { modelo = 'prop_elecbox_01a', nombre = 'Caja eléctrica', tamano = 'mediano' },
    { modelo = 'prop_boxpile_07d', nombre = 'Pila de cajas', tamano = 'mediano' },

    -- ── Grandes: tres disparos ────────────────────────────────────────────
    { modelo = 'prop_bench_01a', nombre = 'Banco', tamano = 'grande' },
    { modelo = 'prop_dumpster_01a', nombre = 'Contenedor', tamano = 'grande' },
    { modelo = 'prop_dumpster_02a', nombre = 'Contenedor', tamano = 'grande' },
    { modelo = 'prop_skip_01a', nombre = 'Contenedor de escombros', tamano = 'grande' },
    { modelo = 'prop_vend_soda_01', nombre = 'Máquina de refrescos', tamano = 'grande' },
    { modelo = 'prop_vend_snak_01', nombre = 'Máquina de aperitivos', tamano = 'grande' },
    { modelo = 'prop_vend_fridge01', nombre = 'Nevera de bebidas', tamano = 'grande' },
    { modelo = 'prop_atm_01', nombre = 'Cajero', tamano = 'grande' },
    { modelo = 'prop_fridge_01', nombre = 'Frigorífico', tamano = 'grande' },
    { modelo = 'prop_cementmixer_01a', nombre = 'Hormigonera', tamano = 'grande' },
    { modelo = 'prop_pooltable_02', nombre = 'Mesa de billar', tamano = 'grande' },
    { modelo = 'prop_table_tennis', nombre = 'Mesa de ping-pong', tamano = 'grande' },
    { modelo = 'prop_yacht_lounger', nombre = 'Tumbona', tamano = 'grande' },
    { modelo = 'prop_t_sofa_02', nombre = 'Sofá', tamano = 'grande' },
    { modelo = 'prop_office_desk_01', nombre = 'Escritorio', tamano = 'grande' },
    { modelo = 'prop_cabinet_01b', nombre = 'Armario', tamano = 'grande' },
    { modelo = 'prop_tourist_map_01', nombre = 'Mapa turístico', tamano = 'grande' },
    { modelo = 'prop_dj_deck_01', nombre = 'Mesa de DJ', tamano = 'grande' },
    { modelo = 'prop_protest_table_01', nombre = 'Mesa plegable', tamano = 'grande' },
    { modelo = 'prop_weight_rack_01', nombre = 'Estante de pesas', tamano = 'grande' },
}

--- Del modelo (nombre) a su ficha.
CatalogoPorModelo = {}

--- Del hash SIN signo a su ficha. GetEntityModel y joaat pueden devolver el
--- mismo modelo con signo o sin él según quién los llame, así que se guarda
--- siempre sin signo y se normaliza al buscar.
CatalogoPorHash = {}

function HashSinSigno(h)
    h = tonumber(h) or 0
    if h < 0 then h = h + 4294967296 end
    return math.floor(h)
end

for _, p in ipairs(Catalogo) do
    CatalogoPorModelo[p.modelo] = p
    CatalogoPorHash[HashSinSigno(GetHashKey(p.modelo))] = p
end
