-- ════════════════════════════════════════════════════════════════════
--  origen_screens · ajustes de las teles
-- ════════════════════════════════════════════════════════════════════

Config = Config or {}

-- La página que se abre DENTRO de cada tele (la DUI).
--
-- Vive en el recurso `origenweb` y no aquí por el guion bajo: la página de
-- Twitch exige `parent=<host de la página>` y responde con
-- «Content-Security-Policy: frame-ancestors https://<ese host>». Si el host es
-- «cfx-nui-origen_screens», Chromium da la fuente por inválida (en CSP un host
-- solo admite letras, cifras y guiones), la ignora, el permiso queda en
-- 'none' y el directo no carga. Comprobado en Chromium el 14/09/2026.
--
-- Si YouTube diera el «Error 153» también desde ahí, se puede servir el mismo
-- tele.html desde un dominio propio con HTTPS y poner su dirección aquí.
Config.Pagina = 'https://cfx-nui-origenweb/tele.html'
Config.PaginaAncho, Config.PaginaAlto = 1280, 720

-- Cuántas teles se reproducen A LA VEZ en cada jugador (cada una es un
-- navegador). Las demás, aunque estén encendidas, no pintan nada.
Config.MaxReproduciendo = 2

-- A qué distancia empieza a pintarse una tele encendida.
Config.DistanciaVer = 30.0
-- Pantallas de pared (las que dibuja un admin con dos esquinas): son grandes.
Config.DistanciaVerPared = 80.0

-- Sonido: pleno hasta `pleno` metros, en silencio a partir de `maximo`.
-- En otro interior que la tele, silencio siempre.
Config.Sonido = { pleno = 3.0, maximo = 14.0 }
Config.SonidoPared = { pleno = 15.0, maximo = 40.0 }

-- Desde dónde se puede usar el mando (lo comprueba el servidor).
Config.DistanciaMando = 8.0
-- A qué distancia de una tele de negocio aparece el aviso de [E].
Config.DistanciaInteraccion = 3.0

-- Ritmo por jugador (ms). Poner un enlace cuesta más que tocar el volumen.
Config.Ritmo = { poner = 4000, otro = 400, despertar = 1000 }

-- ── Modelos de tele y su render target ──────────────────────────────
-- El vídeo se pinta en la PROPIA pantalla del modelo. Todos los props que
-- comparten render target enseñan lo mismo: con dos teles «tvscreen» a la
-- vista, las dos ven la más cercana. Por eso el motor nunca reparte un mismo
-- render target a dos teles distintas.
--
-- Nombres sacados de la configuración de pmms (kibook/pmms, config.lua), que
-- es la lista de referencia en FiveM. Los marcados «sin comprobar» no se han
-- visto en el juego: si una tele sale en negro, prueba con /tele_rt.
Config.Modelos = {
    -- Catálogo de muebles de origen_housing
    prop_tv_flat_01 = 'tvscreen',
    prop_tv_flat_02 = 'tvscreen',
    prop_tv_flat_02b = 'tvscreen',
    prop_tv_flat_03 = 'tvscreen',
    prop_tv_flat_03b = 'tvscreen',
    prop_tv_flat_michael = 'tvscreen',
    prop_trev_tv_01 = 'tvscreen',
    prop_tv_02 = 'tvscreen',
    prop_tv_03 = 'tvscreen',
    apa_mp_h_str_avunitl_01_b = 'tvscreen',
    apa_mp_h_str_avunitl_04 = 'tvscreen',
    apa_mp_h_str_avunitm_01 = 'tvscreen',
    apa_mp_h_str_avunitm_03 = 'tvscreen',
    apa_mp_h_str_avunits_01 = 'tvscreen',
    apa_mp_h_str_avunits_04 = 'tvscreen',
    hei_heist_str_avunitl_03 = 'tvscreen',
    -- Muebles con tele propios del housing (pack «Detalles de casa», origen_housing/config/zpack_des.lua):
    -- la pantalla lleva la textura script_rt_tvscreen. Sin comprobar en el juego.
    origen_casa_des_tv_nogal = 'tvscreen',
    origen_casa_des_tv_industrial = 'tvscreen',
    origen_casa_des_tv_lacado = 'tvscreen',
    origen_casa_des_tv_lujo = 'tvscreen',
    -- Ídem, pack «Salón de diseño» (origen_housing/config/zpack_s2.lua). Sin comprobar en el juego.
    origen_casa_s2_tv_lamas = 'tvscreen',
    origen_casa_s2_tv_panel = 'tvscreen',
    origen_casa_s2_tv_caballete = 'tvscreen',
    origen_casa_s2_tv_retro = 'tvscreen',
    -- Ídem, pack «Retro años 80» (origen_housing/config/zpack_t5.lua): la tele de tubo. Sin comprobar en el juego.
    origen_casa_t5_tv_tubo = 'tvscreen',
    -- Ídem, pack «Estudio y directo» (origen_housing/config/zpack_o2.lua). Sin comprobar en el juego.
    origen_casa_o2_escritorio_streamer = 'tvscreen',
    origen_casa_o2_tele_pared = 'tvscreen',
    origen_casa_o2_tele_retro = 'tvscreen',
    -- Otros render targets: permiten una segunda y tercera tele distinta
    ex_prop_ex_tv_flat_01 = 'ex_tvscreen',
    sm_prop_smug_tv_flat_01 = 'tv_flat_01',
    xm_prop_x17_tv_flat_01 = 'tv_flat_01',
    -- Pantallas grandes del mapa (negocios, cines)
    v_ilev_cin_screen = 'cinscreen',
    prop_big_cin_screen = 'cinscreen',
    prop_huge_display_01 = 'big_disp',
    prop_huge_display_02 = 'big_disp',
    v_ilev_mm_screen = 'big_disp',
    v_ilev_mm_screen2 = 'tvscreen',
    v_ilev_lest_bigscreen = 'tvscreen',
    xs_prop_arena_bigscreen_01 = 'bigscreen_01',
    xs_prop_arena_screen_tv_01 = 'screen_tv_01',
    ch_prop_ch_tv_rt_01a = 'ch_tv_rt_01a',
    vw_prop_vw_cinema_tv_01 = 'tvscreen',
    gr_prop_gr_trailer_tv = 'gr_trailertv_01',
    gr_prop_gr_trailer_tv_02 = 'gr_trailertv_02',
    xm_prop_x17_tv_ceiling_01 = 'prop_x17_tv_ceiling_01', -- sin comprobar
}

-- Índice por hash (lo que devuelve GetEntityModel).
Config.ModelosPorHash = {}
for nombre, rt in pairs(Config.Modelos) do
    Config.ModelosPorHash[GetHashKey(nombre)] = { nombre = nombre, rt = rt }
end
