-- Modelos propios del servidor (los props hechos en Blender), todos juntos.
-- Solo transmite modelos: quien los usa es cada script (origen_weed,
-- origen_businesses…). Van aparte de esos scripts a propósito: reiniciar un
-- recurso que transmite un modelo que el jugador tiene delante tumba el juego,
-- así los scripts se reinician sin miedo. Este NO se reinicia con gente
-- dentro: lo nuevo entra con el reinicio del servidor.
--
-- Un prop nuevo:
--   1. una carpeta en stream/ con sus .ydr, su .ytd y su .ytyp (una por
--      juego de props: el exportador de Blender vacía la suya al exportar)
--   2. su .ytyp en las dos listas de abajo
--   3. sus modelos en limpieza.lua
--
--   stream/maria_tendal    origen_tenderomaria            (origen_weed/fuente, grupo tendal)
--   stream/maria_cultivo   maceta, mesa, bidón, regadera  (origen_weed/fuente, grupo cultivo)
--                          y garrafa de abono
--   stream/movil_cargador  prop_phone_charger             (origen_businesses, punto de carga)
--   stream/casa_obra       losa, tabique y tabique con    (origen_housing/fuente/obra.py)
--                          puerta en cada material, y la
--                          escalera: piezas de obra de las casas
--   stream/carreras        banderas (tela), neumaticos,  (origen_racing/fuente/props)
--                          bolardo, cono, chevrons,
--                          Tecpro, barrera y torre LED:
--                          vela, valla, panel LED, bidones,
--                          paja, piano, carpa, hinchable
--                          y arco: la decoracion de los
--                          checkpoints y el lobby
--   stream/armero          banco de trabajo, torno,       (origen_ilegalv2, puntos de fabricacion)
--                          taladro de columna y esmeril
fx_version 'cerulean'
game 'gta5'

client_script 'limpieza.lua'

files {
    'stream/maria_tendal/origen_weed.ytyp',
    'stream/maria_cultivo/origen_weed_cultivo.ytyp',
    'stream/movil_cargador/prop_phone_charger.ytyp',
    'stream/casa_obra/origen_casa_kit.ytyp',
    'stream/casa_obra/origen_casa_escalera_l.ytyp',
    'stream/casa_obra/origen_casa_escaleras2.ytyp',
    'stream/casa_obra/origen_casa_poste.ytyp',
    'stream/casa_obra/origen_casa_alm.ytyp',
    'stream/casa_obra/origen_casa_rop.ytyp',
    'stream/casa_obra/origen_casa_barandas.ytyp',
    'stream/casa_obra/origen_casa_portones.ytyp',
    'stream/casa_obra/origen_casa_luces.ytyp',
    'stream/casa_obra/origen_casa_secretos.ytyp',
    'stream/casa_obra/origen_casa_pk_crw.ytyp',
    'stream/casa_obra/origen_casa_pk_oci.ytyp',
    'stream/casa_obra/origen_casa_pk_dor.ytyp',
    'stream/casa_obra/origen_casa_pk_ban.ytyp',
    'stream/casa_obra/origen_casa_pk_dec.ytyp',
    'stream/casa_obra/origen_casa_pk_sal.ytyp',
    'stream/casa_obra/origen_casa_pk_vip.ytyp',
    'stream/casa_obra/origen_casa_pk_ofi.ytyp',
    'stream/casa_obra/origen_casa_pk_coc.ytyp',
    'stream/casa_obra/origen_casa_pk_civ.ytyp',
    'stream/casa_obra/origen_casa_pk_des.ytyp',
    'stream/casa_obra/origen_casa_pk_t5.ytyp',
    'stream/casa_obra/origen_casa_pk_d2.ytyp',
    'stream/casa_obra/origen_casa_pk_t3.ytyp',
    'stream/casa_obra/origen_casa_pk_o2.ytyp',
    'stream/casa_obra/origen_casa_pk_t4.ytyp',
    'stream/casa_obra/origen_casa_pk_t1.ytyp',
    'stream/casa_obra/origen_casa_pk_t2.ytyp',
    'stream/casa_obra/origen_casa_pk_t6.ytyp',
    'stream/casa_obra/origen_casa_pk_p2.ytyp',
    'stream/casa_obra/origen_casa_pk_x2.ytyp',
    'stream/casa_obra/origen_casa_pk_k2.ytyp',
    'stream/casa_obra/origen_casa_pk_s2.ytyp',
    'stream/casa_obra/origen_casa_pk_a2.ytyp',
    'stream/casa_obra/origen_casa_m2.ytyp',
    'stream/casa_obra/origen_casa_esquinas.ytyp',
    'stream/carreras/origen_carreras.ytyp',
    'stream/armero/origen_armero_props.ytyp',
    'stream/armero/origen_armero_maquinas.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/maria_tendal/origen_weed.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/maria_cultivo/origen_weed_cultivo.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/movil_cargador/prop_phone_charger.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_kit.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_escalera_l.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_escaleras2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_poste.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_alm.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_rop.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_barandas.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_portones.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_luces.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_secretos.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_crw.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_oci.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_dor.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_ban.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_dec.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_sal.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_vip.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_ofi.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_coc.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_civ.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_des.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t5.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_d2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t3.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_o2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t4.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_t6.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_p2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_x2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_k2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_s2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_pk_a2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_m2.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/casa_obra/origen_casa_esquinas.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/carreras/origen_carreras.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/armero/origen_armero_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/armero/origen_armero_maquinas.ytyp'
