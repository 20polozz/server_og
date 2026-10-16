fx_version 'cerulean'
version '1.0.0'
game       'gta5'

this_is_a_map 'yes'

files {
    'audio/**/*.rel'
}

dependencies { 
    '/server:4960',     -- ⚠️PLEASE READ⚠️; Requires at least SERVER build 4960.
    '/gameBuild:2545',  -- ⚠️PLEASE READ⚠️; Requires at least GAME build 2545.
    'tstudio_zmapdata',  -- ⚠️PLEASE READ⚠️; Requires to be started before this resource.
}

-- Here you will include lines for each dat151 file
-- Cutting off the the line at .dat is intentional
--data_file 'AUDIO_GAMEDATA' 'audio/11D54B69_game.dat'

-- Al Dente's
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_aldentes/FE580F1A_game.dat'

-- Ammunation
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_ammunation/D5A57622_game.dat'

-- Bennys Luxury
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_bennys_luxury/915FBB78_game.dat'

-- Bennys Luxury Racetrack
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_bennys_racetrack/EA7BB406_game.dat'

-- Burgershot
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_burgershot/F2B01B7B_game.dat'

-- Impound
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_impound/93DA1F40_game.dat'

-- Jurassic Jackpot
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_jurassic_jackpot/E8139E0_game.dat'

-- Kebab King
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_kebabking/E3ABAA89_game.dat'

-- Laundromat
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_laundromat/89AD6DDA_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_laundromat/A32D396_game.dat'

-- Leapfrog
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_leapfrog/6ABD73F7_game.dat'

-- LSIA
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_lsia/704CD1C5_game.dat'

-- Opium Nights
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_opium_nights/997AEB4_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_opium_nights/CD1CB701_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_opium_nights/FECFF813_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_opium_nights/B45FE305_game.dat'

-- Paleto Bennys Workshop
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_paleto_bewo/67AEE5BD_game.dat'

-- Paleto Cardealer
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_paleto_cardealer/C7599380_game.dat'

-- Pearls Resort
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_pearls_resort/834D1151_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_pearls_resort/ABA3716C_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_pearls_resort/FB55DB2D_game.dat'

-- MRPD
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_mrpd/80D084B3_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_mrpd/EC10F679_game.dat'

-- Reds Tuner
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_redstuner/2EA0C864_game.dat'

-- Smokeys
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_smokeys/C132AAA0_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_smokeys/CC549F6D_game.dat'

-- Taxi
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_taxi/5D54ADFC_game.dat'

-- Tropical Height
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_tropical_heights/7B9DB0CC_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_tropical_heights/CAFDE1CC_game.dat'

-- VMC
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_vmc/7A510CA2_game.dat'
data_file 'AUDIO_GAMEDATA' 'audio/tstudio_vmc/D55F387A_game.dat'
dependency '/assetpacks'