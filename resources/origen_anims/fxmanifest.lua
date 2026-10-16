fx_version 'cerulean'

game 'gta5'

lua54 'yes'
use_experimental_fxv2_oal 'yes'

version '1.9.9f'

dependencies {
    '/server:5848',
    '/onesync',
    'ox_lib'
}

ui_page 'html/index.html'

files {
    'locales/*.lua',
    'data/*.lua',
    'data/**/*.lua',
    'custom_emotes.lua',
    'anims.json',
    'html/index.html',
    'html/js/*.js',
    'html/css/*.css',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

server_scripts {
    'server/*.lua'
}

client_scripts {
    '@origen_map/shared/foco.lua',
    '@origen_map/shared/tema.lua',
    'client/*.lua',
    'compat/*.lua'
}

data_file 'DLC_ITYP_REQUEST' 'bzzz_foodpack.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_torch_fire001.ytyp'
data_file 'DLC_ITYP_REQUEST' 'natty_props_lollipops.ytyp'
data_file 'DLC_ITYP_REQUEST' 'scully_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'badges.ytyp'
data_file 'DLC_ITYP_REQUEST' 'lilflags_ytyp.ytyp'
data_file 'DLC_ITYP_REQUEST' 'prideprops_ytyp.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_food_icecream_pack.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_effect_cigarpack.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_murderpack.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_animal_fish002.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_food_dessert_a.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_give_gift.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_package_pizzahut.ytyp'
data_file 'DLC_ITYP_REQUEST' 'ultra_ringcase.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_food_xmas22.ytyp'
data_file 'DLC_ITYP_REQUEST' 'pprp_icefishing.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'pata_freevalentinesday.ytyp'
data_file 'DLC_ITYP_REQUEST' 'pata_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'kaykaymods_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'knjgh_pizzas.ytyp'
data_file 'DLC_ITYP_REQUEST' 'taymckenzienz_rpemotes.ytyp'
data_file 'DLC_ITYP_REQUEST' 'brummie_props.ytyp'
data_file 'DLC_ITYP_REQUEST' 'apple_1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'badge1.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bebekbus.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_cake_baby_001.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_cake_birthday_001.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_cake_casino001.ytyp'
data_file 'DLC_ITYP_REQUEST' 'bzzz_prop_cake_love_001.ytyp'
data_file 'DLC_ITYP_REQUEST' 'copbadge.ytyp'
data_file 'DLC_ITYP_REQUEST' 'pata_christmasfood.ytyp'
data_file 'DLC_ITYP_REQUEST' 'taymckenzienz_skateboards.ytyp'
