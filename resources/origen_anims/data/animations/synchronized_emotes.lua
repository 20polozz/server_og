return {
    {
        Label = 'Baseball',
        Command = 'sbaseball',
        Animation = 'baseball_a_player_a',
        Dictionary = 'anim@arena@celeb@flat@paired@no_props@',
        Options = {
            Shared = {
                OtherAnimation = 'sbaseballthrow',
            },
        },
    },
    {
        Label = 'Baseball Throw',
        Command = 'sbaseballthrow',
        Animation = 'baseball_a_player_b',
        Dictionary = 'anim@arena@celeb@flat@paired@no_props@',
        Options = {
            Shared = {
                OtherAnimation = 'sbaseball',
            },
        },
    },
    {
        Label = 'Bro',
        Command = 'sbro',
        Animation = 'hugs_guy_a',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Shared = {
                FrontOffset = 1.14,
                OtherAnimation = 'sbro2',
            },
        },
    },
    {
        Label = 'Bro 2',
        Command = 'sbro2',
        Animation = 'hugs_guy_b',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Shared = {
                FrontOffset = 1.14,
                OtherAnimation = 'sbro',
            },
        },
    },
    {
        Label = 'Carry',
        Command = 'scarry',
        Animation = 'fin_c2_mcs_1_camman',
        Dictionary = 'missfinale_c2mcs_1',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'scarried',
            },
        },
        SkipRequest = true
    },
    {
        Label = 'Carried',
        Command = 'scarried',
        Animation = 'firemans_carry',
        Dictionary = 'nm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 40269,
                OtherAnimation = 'scarry',
                Placement = {
                    vector3(-0.140000, 0.150000, 0.140000),
                    vector3(0.000000, -59.000000, -4.500000),
                },
            },
        },
    },
    {
        Label = 'Carry 2',
        Command = 'carry2',
        Animation = 'idle',
        Dictionary = 'anim@heists@box_carry@',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                Bone = 40269,
                OtherAnimation = 'scarried2',
            },
        },
        SkipRequest = true
    },
    {
        Label = 'Carried 2',
        Command = 'scarried2',
        Animation = 'base',
        Dictionary = 'amb@code_human_in_car_idles@generic@ps@base',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 28252,
                OtherAnimation = 'carry2',
                Placement = {
                    vector3(0.350000, 0.150000, -0.150000),
                    vector3(-42.500000, -22.500000, 22.500000),
                },
            },
        },
    },
    {
        Label = 'Carry 3',
        Command = 'scarry3',
        Animation = 'couplepose1cmg_clip',
        Dictionary = 'couplepose1cmg@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'carried3',
            },
        },
    },
    {
        Label = 'Carried 3',
        Command = 'carried3',
        Animation = 'couplepose2cmg_clip',
        Dictionary = 'couplepose2cmg@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'scarry3',
                Placement = {
                    vector3(0.010000, 0.344000, -0.010000),
                    vector3(180.000000, 180.000000, -1.999900),
                },
            },
        },
    },
    {
        Label = 'Carry Big Dog',
        Command = 'scbdog',
        Animation = 'idle',
        Dictionary = 'anim@heists@box_carry@',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'scbdog2',
            },
        },
    },
    {
        Label = 'Big Dog Carried',
        Command = 'scbdog2',
        Animation = 'sleep_in_kennel',
        Dictionary = 'creatures@rottweiler@amb@sleep_in_kennel@',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'scbdog',
                Placement = {
                    vector3(-0.100000, 0.650000, 0.430000),
                    vector3(0.000000, 0.000000, -100.000000),
                },
            },
        },
    },
    {
        Label = 'Couple Drinking (Wine Glasses)',
        Command = 'scoupleanim',
        Animation = 'action_var_01_bank_manager',
        Dictionary = 'anim@scripted@robbery@tun_prep_uni_ig1_couple@',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 60309,
                    Name = 'p_wine_glass_s',
                    Placement = {
                        vector3(-0.050000, -0.010000, -0.170000),
                        vector3(0.000000, 0.000000, 0.000000),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'scoupleanim2',
            },
        },
    },
    {
        Label = 'Couple Drinking F (Wine Glasses)',
        Command = 'scoupleanim2',
        Animation = 'action_var_01_female',
        Dictionary = 'anim@scripted@robbery@tun_prep_uni_ig1_couple@',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 28422,
                    Name = 'p_wine_glass_s',
                    Placement = {
                        vector3(0.000000, 0.000000, 0.000000),
                        vector3(0.000000, 0.000000, 0.000000),
                    },
                },
            },
            Shared = {
                FrontOffset = 0.11,
                OtherAnimation = 'scoupleanim',
                SideOffset = -0.04125,
            },
        },
    },
    {
        Label = 'Give CPR',
        Command = 'scprs',
        Animation = 'cpr_pumpchest',
        Dictionary = 'mini@cpr@char_a@cpr_str',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'scprs2',
            },
        },
    },
    {
        Label = 'Get CPR',
        Command = 'scprs2',
        Animation = 'cpr_pumpchest',
        Dictionary = 'mini@cpr@char_b@cpr_str',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'scprs',
                Placement = {
                    vector3(0.350000, 0.800000, 0.000000),
                    vector3(0.000000, 0.000000, 270.000000),
                },
            },
        },
    },
    {
        Label = 'Give CPR 2',
        Command = 'scprs3',
        Animation = 'cpr_loop_paramedic',
        Dictionary = 'missheistfbi3b_ig8_2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'scprs4',
            },
        },
    },
    {
        Label = 'Get CPR 2',
        Command = 'scprs4',
        Animation = 'cpr_loop_victim',
        Dictionary = 'missheistfbi3b_ig8_2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'scprs3',
                Placement = {
                    vector3(0.350000, 0.650000, 0.000000),
                    vector3(0.000000, 0.000000, 270.000000),
                },
            },
        },
    },
    {
        Label = 'Give',
        Command = 'sgive',
        Animation = 'givetake1_a',
        Dictionary = 'mp_common',
        Options = {
            Duration = 2000,
            Flags = {
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sgive2',
            },
        },
    },
    {
        Label = 'Give 2',
        Command = 'sgive2',
        Animation = 'givetake1_b',
        Dictionary = 'mp_common',
        Options = {
            Duration = 2000,
            Flags = {
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sgive',
            },
        },
    },
    -- {
    --     Label = 'Give Blowjob',
    --     Command = 'sgiveblowjob',
    --     Animation = 'pimpsex_hooker',
    --     Dictionary = 'misscarsteal2pimpsex',
    --     Options = {
    --         Duration = 30000,
    --         Shared = {
    --             FrontOffset = 0.63,
    --             OtherAnimation = 'sreceiveblowjob',
    --         },
    --     },
    --     NSFW = true,
    -- },
    {
        Label = 'Handshake',
        Command = 'shandshake',
        Animation = 'handshake_guy_a',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Duration = 3000,
            Flags = {
                Move = true,
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'shandshake2',
            },
        },
    },
    {
        Label = 'Handshake 2',
        Command = 'shandshake2',
        Animation = 'handshake_guy_b',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Duration = 3000,
            Flags = {
                Move = true,
            },
            Shared = {
                OtherAnimation = 'shandshake',
            },
        },
    },
    {
        Label = 'Headbutt',
        Command = 'sheadbutt',
        Animation = 'plyr_takedown_front_headbutt',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'sheadbutted',
            },
        },
    },
    {
        Label = 'Headbutted',
        Command = 'sheadbutted',
        Animation = 'victim_takedown_front_headbutt',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'sheadbutt',
            },
        },
    },
    {
        Label = 'Hug Pose Tippy Toes',
        Command = 'hugtip',
        Animation = 'friendship007',
        Dictionary = 'littlespoon@friendship007',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'hugtip2',
            },
        },
    },
    {
        Label = 'Hug Pose Tippy Toes 2',
        Command = 'hugtip2',
        Animation = 'friendship008',
        Dictionary = 'littlespoon@friendship008',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'hugtip',
            },
        },
    },
    {
        Label = 'Take hostage',
        Command = 'shostage',
        Animation = 'perp_idle',
        Dictionary = 'anim@gangops@hostage@',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'shostage2',
            },
        },
    },
    {
        Label = 'Be hostage',
        Command = 'shostage2',
        Animation = 'victim_idle',
        Dictionary = 'anim@gangops@hostage@',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'shostage',
                Placement = {
                    vector3(-0.300000, 0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Hug',
        Command = 'shug',
        Animation = 'kisses_guy_a',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Duration = 5000,
            Shared = {
                FrontOffset = 1.05,
                OtherAnimation = 'shug2',
            },
        },
    },
    {
        Label = 'Hug 2',
        Command = 'shug2',
        Animation = 'kisses_guy_b',
        Dictionary = 'mp_ped_interaction',
        Options = {
            Duration = 5000,
            Shared = {
                FrontOffset = 1.18,
                OtherAnimation = 'shug',
            },
        },
    },
    {
        Label = 'Hug Romantic 1',
        Command = 'shug3',
        Animation = 'chad_armsaround_chad',
        Dictionary = 'misscarsteal2chad_goodbye',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.52,
                OtherAnimation = 'shug4',
                SideOffset = -0.05,
            },
        },
    },
    {
        Label = 'Hug Romantic 2',
        Command = 'shug4',
        Animation = 'chad_armsaround_girl',
        Dictionary = 'misscarsteal2chad_goodbye',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.52,
                OtherAnimation = 'shug3',
                SideOffset = -0.05,
            },
        },
    },
    {
        Label = 'Kiss',
        Command = 'skiss',
        Animation = 'cs_lestercrest_3_dual-20',
        Dictionary = 'hs3_ext-20',
        Options = {
            Duration = 10000,
            Shared = {
                FrontOffset = 0.08,
                OtherAnimation = 'skiss2',
            },
        },
    },
    {
        Label = 'Kiss 2',
        Command = 'skiss2',
        Animation = 'csb_georginacheng_dual-20',
        Dictionary = 'hs3_ext-20',
        Options = {
            Duration = 10000,
            Shared = {
                FrontOffset = 0.08,
                OtherAnimation = 'skiss',
            },
        },
    },
    {
        Label = 'Kiss 3',
        Command = 'skiss3',
        Animation = 'cs_lestercrest_3_dual-19',
        Dictionary = 'hs3_ext-19',
        Options = {
            Duration = 10000,
            Shared = {
                FrontOffset = 0.08,
                OtherAnimation = 'skiss4',
            },
        },
    },
    {
        Label = 'Kiss 4',
        Command = 'skiss4',
        Animation = 'csb_georginacheng_dual-19',
        Dictionary = 'hs3_ext-19',
        Options = {
            Duration = 10000,
            Shared = {
                FrontOffset = 0.08,
                OtherAnimation = 'skiss3',
            },
        },
    },
    {
        Label = 'Lift Me',
        Command = 'sliftme',
        Animation = 'couplepose1pack1anim2_clip',
        Dictionary = 'couplepose1pack1anim2@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sliftme2',
            },
        },
    },
    {
        Label = 'Lift Me 2',
        Command = 'sliftme2',
        Animation = 'couplepose1pack1anim1_clip',
        Dictionary = 'couplepose1pack1anim1@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sliftme',
                Placement = {
                    vector3(0.002000, 0.287000, 0.250000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Lift Me 3',
        Command = 'sliftme3',
        Animation = 'couplepose2pack1anim2_clip',
        Dictionary = 'couplepose2pack1anim2@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sliftme4',
            },
        },
    },
    {
        Label = 'Lift Me 4',
        Command = 'sliftme4',
        Animation = 'couplepose2pack1anim1_clip',
        Dictionary = 'couplepose2pack1anim1@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sliftme3',
                Placement = {
                    vector3(0.010000, 0.480000, 0.530000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Lift Me 5',
        Command = 'sliftme5',
        Animation = 'couplepose3pack1anim2_clip',
        Dictionary = 'couplepose3pack1anim2@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sliftme6',
            },
        },
    },
    {
        Label = 'Lift Me 6',
        Command = 'sliftme6',
        Animation = 'couplepose3pack1anim1_clip',
        Dictionary = 'couplepose3pack1anim1@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sliftme5',
                Placement = {
                    vector3(-0.212000, -0.540000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Piggy Back',
        Command = 'spback',
        Animation = 'mxclip_a',
        Dictionary = 'mx@piggypack_a',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'spback2',
            },
        },
    },
    {
        Label = 'Piggy Back 2',
        Command = 'spback2',
        Animation = 'mxanim_b',
        Dictionary = 'mx@piggypack_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'spback',
                Placement = {
                    vector3(0.020000, -0.439900, 0.420000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Piggy Back 3',
        Command = 'spback3',
        Animation = 'piggyback_c_player_a',
        Dictionary = 'anim@arena@celeb@flat@paired@no_props@',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'spback2',
            },
        },
    },
    {
        Label = 'Piggy Back 4',
        Command = 'spback4',
        Animation = 'piggyback_c_player_b',
        Dictionary = 'anim@arena@celeb@flat@paired@no_props@',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'spback',
                Placement = {
                    vector3(0.000000, -0.700000, 0.400000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Punch',
        Command = 'spunch',
        Animation = 'plyr_takedown_rear_lefthook',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'spunched',
            },
        },
    },
    {
        Label = 'Punched',
        Command = 'spunched',
        Animation = 'victim_takedown_front_cross_r',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'spunch',
            },
        },
    },
    -- {
    --     Label = 'Receive Blowjob',
    --     Command = 'sreceiveblowjob',
    --     Animation = 'pimpsex_punter',
    --     Dictionary = 'misscarsteal2pimpsex',
    --     Options = {
    --         Duration = 30000,
    --         Shared = {
    --             FrontOffset = 0.63,
    --             OtherAnimation = 'sgiveblowjob',
    --         },
    --     },
    --     NSFW = true,
    -- },
    {
        Label = 'Search',
        Command = 'ssearch',
        Animation = 'police',
        Dictionary = 'custom@police',
        Options = {
            Flags = {
                Move = true,
            },
            Shared = {
                OtherAnimation = 'ssearch2',
            },
        },
    },
    {
        Label = 'Be searched',
        Command = 'ssearch2',
        Animation = 'a2_pose',
        Dictionary = 'missfam5_yoga',
        Options = {
            Flags = {
                Move = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'ssearch',
                Placement = {
                    vector3(0.000000, 0.500000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Slap',
        Command = 'sslap',
        Animation = 'plyr_takedown_front_slap',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Duration = 2000,
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sslapped',
            },
        },
    },
    {
        Label = 'Slap 2',
        Command = 'sslap2',
        Animation = 'plyr_takedown_front_backslap',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Duration = 2000,
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sslapped2',
            },
        },
    },
    {
        Label = 'Slapped',
        Command = 'sslapped',
        Animation = 'victim_takedown_front_slap',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'sslap',
            },
        },
    },
    {
        Label = 'Slapped 2',
        Command = 'sslapped2',
        Animation = 'victim_takedown_front_backslap',
        Dictionary = 'melee@unarmed@streamed_variations',
        Options = {
            Shared = {
                OtherAnimation = 'sslap2',
            },
        },
    },
    {
        Label = 'Stick Up',
        Command = 'sstickup',
        Animation = 'biker_02_stickup_loop',
        Dictionary = 'random@countryside_gang_fight',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sstickupscared',
            },
        },
    },
    {
        Label = 'Stickup Scared',
        Command = 'sstickupscared',
        Animation = 'handsup_base',
        Dictionary = 'missminuteman_1ig_2',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'sstickup',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata1F',
        Command = 'pbauth1',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@bachata1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth2',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata1M',
        Command = 'pbauth2',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@bachata1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth1',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata2F',
        Command = 'pbauth3',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@bachata2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth4',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata2M',
        Command = 'pbauth4',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@bachata2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth3',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata3F',
        Command = 'pbauth5',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@bachata3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth6',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata3M',
        Command = 'pbauth6',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@bachata3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth5',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata4F',
        Command = 'pbauth7',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@bachata4',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth8',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Bachata4M',
        Command = 'pbauth8',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@bachata4',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth7',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa1F',
        Command = 'pbauth9',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@salsa1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth10',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa1M',
        Command = 'pbauth10',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@salsa1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth9',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa2F',
        Command = 'pbauth11',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@salsa2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth12',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa2M',
        Command = 'pbauth12',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@salsa2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth11',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa3F',
        Command = 'pbauth13',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@salsa3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth14',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Salsa3M',
        Command = 'pbauth14',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@salsa3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth13',
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Kompa1F',
        Command = 'pbauth15',
        Animation = 'pandora_fem',
        Dictionary = 'pandora@authenticv1@kompa1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'pbauth16',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = '[PB] AuthenticV1 - Kompa1M',
        Command = 'pbauth16',
        Animation = 'pandora_male',
        Dictionary = 'pandora@authenticv1@kompa1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pbauth15',
            },
        },
    },
    {
        Label = 'Punish Ear Pull Together 1',
        Command = 'ppunishf',
        Animation = 'pazeee@punish@f@clip',
        Dictionary = 'pazeee@punish@f@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.8,
                OtherAnimation = 'ppunishg',
                SideOffset = 0.025,
            },
        },
    },
    {
        Label = 'Punish Ear Pull Together 2',
        Command = 'ppunishg',
        Animation = 'pazeee@punish@g@clip',
        Dictionary = 'pazeee@punish@g@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.8,
                OtherAnimation = 'ppunishf',
                SideOffset = 0.025,
            },
        },
    },
    {
        Label = 'Punish Squat Carry 1',
        Command = 'ppunishx',
        Animation = 'pazeee@punish@x@clip',
        Dictionary = 'pazeee@punish@x@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishy',
            },
        },
    },
    {
        Label = 'Punish Squat Carry 2 Coach',
        Command = 'ppunishy',
        Animation = 'pazeee@punish@y@clip',
        Dictionary = 'pazeee@punish@y@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishx',
                Placement = {
                    vector3(0.400000, -0.230000, -0.200000),
                    vector3(0.000000, 0.000000, -20.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Push Up Sit 1',
        Command = 'ppunishz',
        Animation = 'pazeee@punish@z@clip',
        Dictionary = 'pazeee@punish@z@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishza',
            },
        },
    },
    {
        Label = 'Punish Push Up Sit 2 Coach',
        Command = 'ppunishza',
        Animation = 'pazeee@punish@za@clip',
        Dictionary = 'pazeee@punish@za@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishz',
                Placement = {
                    vector3(-0.080000, -0.110000, 0.000000),
                    vector3(180.000000, 180.000000, -79.900000),
                },
            },
        },
    },
    {
        Label = 'Punish Push Up Serious 1',
        Command = 'ppunishzb',
        Animation = 'pazeee@punish@zb@clip',
        Dictionary = 'pazeee@punish@zb@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzc',
            },
        },
    },
    {
        Label = 'Punish Push Up Serious 2 Coach Angry',
        Command = 'ppunishzc',
        Animation = 'pazeee@punish@zc@clip',
        Dictionary = 'pazeee@punish@zc@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishzb',
                Placement = {
                    vector3(-0.140000, -0.150000, 0.000000),
                    vector3(0.000000, 0.000000, -79.900000),
                },
            },
        },
    },
    {
        Label = 'Punish Push Up One Hand 1',
        Command = 'ppunishzd',
        Animation = 'pazeee@punish@zd@clip',
        Dictionary = 'pazeee@punish@zd@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishze',
            },
        },
    },
    {
        Label = 'Punish Push Up One Hand 2 Chill Coach ^^',
        Command = 'ppunishze',
        Animation = 'pazeee@punish@ze@clip',
        Dictionary = 'pazeee@punish@ze@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishzd',
                Placement = {
                    vector3(-0.440000, -0.180000, -0.030000),
                    vector3(0.000000, 0.000000, -79.900000),
                },
            },
        },
    },
    {
        Label = 'Punish Crawl Carry 1',
        Command = 'ppunishzf',
        Animation = 'pazeee@punish@zf@clip',
        Dictionary = 'pazeee@punish@zf@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzg',
            },
        },
    },
    {
        Label = 'Punish Crawl Carry 2 Coach',
        Command = 'ppunishzg',
        Animation = 'pazeee@punish@zg@clip',
        Dictionary = 'pazeee@punish@zg@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24817,
                OtherAnimation = 'ppunishzf',
                Placement = {
                    vector3(-0.050000, -0.100000, -0.050000),
                    vector3(0.000000, 0.000000, -85.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Spirit 1',
        Command = 'ppunishzh',
        Animation = 'pazeee@punish@zh@clip',
        Dictionary = 'pazeee@punish@zh@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzi',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Spirit 2 Coach',
        Command = 'ppunishzi',
        Animation = 'pazeee@punish@zi@clip',
        Dictionary = 'pazeee@punish@zi@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.110000, 0.020000, -0.020000),
                        vector3(-58.430000, 79.580000, 17.220000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzh',
                Placement = {
                    vector3(-0.030000, -0.060000, 0.000000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Enjoy Riding 1',
        Command = 'ppunishzj',
        Animation = 'pazeee@punish@zj@clip',
        Dictionary = 'pazeee@punish@zj@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzk',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Enjoy Riding 2 Coach',
        Command = 'ppunishzk',
        Animation = 'pazeee@punish@zk@clip',
        Dictionary = 'pazeee@punish@zk@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzj',
                Placement = {
                    vector3(0.000000, -0.100000, 0.000000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Cool Right 1',
        Command = 'ppunishzl',
        Animation = 'pazeee@punish@zl@clip',
        Dictionary = 'pazeee@punish@zl@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzm',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Cool Right 2 Coach',
        Command = 'ppunishzm',
        Animation = 'pazeee@punish@zm@clip',
        Dictionary = 'pazeee@punish@zm@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.110000, 0.020000, -0.020000),
                        vector3(-58.430000, 79.580000, 17.220000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzl',
                Placement = {
                    vector3(-0.020000, -0.050000, 0.000000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Cool Left 1',
        Command = 'ppunishzn',
        Animation = 'pazeee@punish@zn@clip',
        Dictionary = 'pazeee@punish@zn@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzo',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Cool Left 2 Coach',
        Command = 'ppunishzo',
        Animation = 'pazeee@punish@zo@clip',
        Dictionary = 'pazeee@punish@zo@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 18905,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.080000, 0.000000, 0.030000),
                        vector3(-107.400000, -12.820000, -8.050000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzn',
                Placement = {
                    vector3(-0.020000, -0.060000, -0.020000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Stand 1',
        Command = 'ppunishzp',
        Animation = 'pazeee@punish@zp@clip',
        Dictionary = 'pazeee@punish@zp@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzq',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Stand 2 Coach',
        Command = 'ppunishzq',
        Animation = 'pazeee@punish@zq@clip',
        Dictionary = 'pazeee@punish@zq@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 18905,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.080000, 0.000000, 0.030000),
                        vector3(-107.400000, -12.820000, -8.050000),
                    },
                },
                {
                    Bone = 57005,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.110000, 0.020000, -0.020000),
                        vector3(-58.430000, 79.580000, 17.220000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 24817,
                OtherAnimation = 'ppunishzp',
                Placement = {
                    vector3(0.040000, -0.850000, 0.100000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Flag Hold Giant Together 1',
        Command = 'flagzzc',
        Animation = 'pazeee@flagzzc@clip',
        Dictionary = 'pazeee@flagzzc@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'stt_prop_flagpole_1a',
                    Placement = {
                        vector3(-0.790000, -1.130000, -0.420000),
                        vector3(-69.052000, 12.424000, -35.135000),
                    },
                },
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'flagzzd',
            },
        },
    },
    {
        Label = 'Flag Hold Giant Together 2',
        Command = 'flagzzd',
        Animation = 'pazeee@flagzzd@clip',
        Dictionary = 'pazeee@flagzzd@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'flagzzd',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Stand Serious 1',
        Command = 'ppunishzr',
        Animation = 'pazeee@punish@zr@clip',
        Dictionary = 'pazeee@punish@zr@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzs',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Stand Serious 2 Coach',
        Command = 'ppunishzs',
        Animation = 'pazeee@punish@zs@clip',
        Dictionary = 'pazeee@punish@zs@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 18905,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.080000, 0.000000, 0.030000),
                        vector3(-107.400000, -12.820000, -8.050000),
                    },
                },
                {
                    Bone = 57005,
                    Name = 'w_me_stonehatchet',
                    Placement = {
                        vector3(0.110000, 0.020000, -0.020000),
                        vector3(-58.430000, 79.580000, 17.220000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 24817,
                OtherAnimation = 'ppunishzr',
                Placement = {
                    vector3(-0.020000, -0.550000, 0.130000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Facing Back 1',
        Command = 'ppunishzt',
        Animation = 'pazeee@punish@zt@clip',
        Dictionary = 'pazeee@punish@zt@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzu',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Facing Back 2 Coach',
        Command = 'ppunishzu',
        Animation = 'pazeee@punish@zu@clip',
        Dictionary = 'pazeee@punish@zu@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzt',
                Placement = {
                    vector3(0.080000, -0.090000, -0.050000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Player 1 To Player 2',
        Command = 'ppunishzu1',
        Animation = 'pazeee@punish@zu1@clip',
        Dictionary = 'pazeee@punish@zu1@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzx',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Don\'t Press This',
        Command = 'ppunishzx',
        Animation = 'pazeee@punish@zx@clip',
        Dictionary = 'pazeee@punish@zx@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'ppunishzu1',
                Placement = {
                    vector3(0.000000, -0.260000, -0.090000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Hog Rider Player 3 To Player 1',
        Command = 'ppunishzv',
        Animation = 'pazeee@punish@zv@clip',
        Dictionary = 'pazeee@punish@zv@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzw',
            },
        },
    },
    {
        Label = 'Punish Hog Rider Don\'t Press This',
        Command = 'ppunishzw',
        Animation = 'pazeee@punish@zw@clip',
        Dictionary = 'pazeee@punish@zw@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24816,
                OtherAnimation = 'ppunishzv',
                Placement = {
                    vector3(0.200000, -0.100000, 0.000000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Pull With Shovel Right 1',
        Command = 'ppunishzzp',
        Animation = 'pazeee@punish@zzp@clip',
        Dictionary = 'pazeee@punish@zzp@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Props = {
                {
                    Bone = 24817,
                    Name = 'prop_tool_shovel4',
                    Placement = {
                        vector3(-1.400000, -0.610000, -0.810000),
                        vector3(-25.690000, 84.302000, 25.430000),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'ppunishzzq',
            },
        },
    },
    {
        Label = 'Punish Pull With Shovel Right 2',
        Command = 'ppunishzzq',
        Animation = 'pazeee@punish@zzq@clip',
        Dictionary = 'pazeee@punish@zzq@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24817,
                OtherAnimation = 'ppunishzzp',
                Placement = {
                    vector3(-1.290000, -0.640000, -0.870000),
                    vector3(0.000000, 0.000000, -20.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Pull With Shovel Left 1',
        Command = 'ppunishzzr',
        Animation = 'pazeee@punish@zzr@clip',
        Dictionary = 'pazeee@punish@zzr@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Props = {
                {
                    Bone = 24818,
                    Name = 'prop_tool_shovel4',
                    Placement = {
                        vector3(-1.650000, -0.470000, 0.500000),
                        vector3(-10.000000, 90.000000, 0.000000),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'ppunishzzs',
            },
        },
    },
    {
        Label = 'Punish Pull With Shovel Left 2',
        Command = 'ppunishzzs',
        Animation = 'pazeee@punish@zzs@clip',
        Dictionary = 'pazeee@punish@zzs@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishzzr',
                Placement = {
                    vector3(-1.560000, -0.590000, 0.560000),
                    vector3(0.000000, 0.000000, -25.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Slap Slow Hard 1',
        Command = 'ppunishzzt',
        Animation = 'pazeee@punish@zzt@clip',
        Dictionary = 'pazeee@punish@zzt@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.85,
                OtherAnimation = 'ppunishzzu',
            },
        },
    },
    {
        Label = 'Punish Slap Slow Hard 2',
        Command = 'ppunishzzu',
        Animation = 'pazeee@punish@zzu@clip',
        Dictionary = 'pazeee@punish@zzu@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'ppunishzzt',
            },
        },
    },
    {
        Label = 'Punish Slap Fast 1',
        Command = 'ppunishzzv',
        Animation = 'pazeee@punish@zzv@clip',
        Dictionary = 'pazeee@punish@zzv@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'ppunishzzw',
            },
        },
    },
    {
        Label = 'Punish Slap Fast 2',
        Command = 'ppunishzzw',
        Animation = 'pazeee@punish@zzw@clip',
        Dictionary = 'pazeee@punish@zzw@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.9,
                OtherAnimation = 'ppunishzzv',
            },
        },
    },
    {
        Label = 'Punish Pull Someone Ear 1',
        Command = 'ppunishzzx',
        Animation = 'pazeee@punish@zzx@clip',
        Dictionary = 'pazeee@punish@zzx@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzzy',
            },
        },
    },
    {
        Label = 'Punish Pull Someone Ear 2',
        Command = 'ppunishzzy',
        Animation = 'pazeee@punish@zzy@clip',
        Dictionary = 'pazeee@punish@zzy@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishzzx',
                Placement = {
                    vector3(-1.120000, 0.080000, -0.500000),
                    vector3(0.000000, 0.000000, -25.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Pull People Tantrum Behind 1',
        Command = 'ppunishzzz',
        Animation = 'pazeee@punish@zzz@clip',
        Dictionary = 'pazeee@punish@zzz@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'ppunishzzza',
            },
        },
    },
    {
        Label = 'Punish Pull People Tantrum Behind 2',
        Command = 'ppunishzzza',
        Animation = 'pazeee@punish@zzza@clip',
        Dictionary = 'pazeee@punish@zzza@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'ppunishzzz',
                Placement = {
                    vector3(-1.140000, -0.270000, -0.040000),
                    vector3(-180.000000, -180.000000, 10.000000),
                },
            },
        },
    },
    {
        Label = 'Punish Massage 1',
        Command = 'ppunishzzzb',
        Animation = 'pazeee@punish@zzzb@clip',
        Dictionary = 'pazeee@punish@zzzb@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.55,
                OtherAnimation = 'ppunishzzzc',
            },
        },
    },
    {
        Label = 'Punish Massage 2',
        Command = 'ppunishzzzc',
        Animation = 'pazeee@punish@zzzc@clip',
        Dictionary = 'pazeee@punish@zzzc@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.6,
                OtherAnimation = 'ppunishzzzb',
            },
        },
    },
    {
        Label = 'Punish Kicked 1',
        Command = 'ppunishzzzd',
        Animation = 'pazeee@punish@zzzd@clip',
        Dictionary = 'pazeee@punish@zzzd@animations',
        Options = {
            Shared = {
                FrontOffset = 0.7,
                OtherAnimation = 'ppunishzzze',
                SideOffset = 0.4,
            },
        },
    },
    {
        Label = 'Punish Kicked 2',
        Command = 'ppunishzzze',
        Animation = 'pazeee@punish@zzze@clip',
        Dictionary = 'pazeee@punish@zzze@animations',
        Options = {
            Shared = {
                FrontOffset = 0.7,
                OtherAnimation = 'ppunishzzzd',
                SideOffset = 0.4,
            },
        },
    },
    {
        Label = 'Punish Hit Hand Pole Front 1',
        Command = 'ppunishzzzf',
        Animation = 'pazeee@punish@zzzf@clip',
        Dictionary = 'pazeee@punish@zzzf@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'prop_scaffold_pole',
                    Placement = {
                        vector3(0.130000, 0.060000, -0.020000),
                        vector3(-90.000000, 0.000000, -44.999000),
                    },
                },
            },
            Shared = {
                FrontOffset = 1.1,
                OtherAnimation = 'ppunishzzzg',
                SideOffset = -0.7,
            },
        },
    },
    {
        Label = 'Punish Hit Hand Pole Front 2',
        Command = 'ppunishzzzg',
        Animation = 'pazeee@punish@zzzg@clip',
        Dictionary = 'pazeee@punish@zzzg@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 1.1,
                OtherAnimation = 'ppunishzzzf',
                SideOffset = -0.7,
            },
        },
    },
    {
        Label = 'Punish Hit Hand Pole Behind 1',
        Command = 'ppunishzzzh',
        Animation = 'pazeee@punish@zzzh@clip',
        Dictionary = 'pazeee@punish@zzzh@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'prop_scaffold_pole',
                    Placement = {
                        vector3(0.100000, 0.060000, 0.000000),
                        vector3(-90.000000, 0.000000, -30.000000),
                    },
                },
            },
            Shared = {
                FrontOffset = 0.85,
                OtherAnimation = 'ppunishzzzi',
                SideOffset = 0.3,
            },
        },
    },
    {
        Label = 'Punish Hit Hand Pole Behind 2',
        Command = 'ppunishzzzi',
        Animation = 'pazeee@punish@zzzi@clip',
        Dictionary = 'pazeee@punish@zzzi@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 1,
                OtherAnimation = 'ppunishzzzh',
                SideOffset = 0.3,
            },
        },
    },
    {
        Label = 'Punish Hit Back Pole 1',
        Command = 'ppunishzzzj',
        Animation = 'pazeee@punish@zzzj@clip',
        Dictionary = 'pazeee@punish@zzzj@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'prop_scaffold_pole',
                    Placement = {
                        vector3(0.110000, 0.060000, -0.010000),
                        vector3(-78.491000, 5.725000, -29.490000),
                    },
                },
            },
            Shared = {
                FrontOffset = 1.15,
                OtherAnimation = 'ppunishzzzk',
                SideOffset = -0.1,
            },
        },
    },
    {
        Label = 'Punish Hit Back Pole 2',
        Command = 'ppunishzzzk',
        Animation = 'pazeee@punish@zzzk@clip',
        Dictionary = 'pazeee@punish@zzzk@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 1.15,
                OtherAnimation = 'ppunishzzzj',
                SideOffset = -0.1,
            },
        },
    },
    {
        Label = 'Punish Hit Butt Pole 1',
        Command = 'ppunishzzzl',
        Animation = 'pazeee@punish@zzzl@clip',
        Dictionary = 'pazeee@punish@zzzl@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 57005,
                    Name = 'prop_scaffold_pole',
                    Placement = {
                        vector3(0.100000, 0.030000, -0.020000),
                        vector3(-65.252000, 30.898000, -23.800000),
                    },
                },
            },
            Shared = {
                FrontOffset = 0.95,
                OtherAnimation = 'ppunishzzzm',
                SideOffset = -0.25,
            },
        },
    },
    {
        Label = 'Punish Hit Butt Pole 2',
        Command = 'ppunishzzzm',
        Animation = 'pazeee@punish@zzzm@clip',
        Dictionary = 'pazeee@punish@zzzm@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                FrontOffset = 0.95,
                OtherAnimation = 'ppunishzzzl',
                SideOffset = -0.25,
            },
        },
    },
    {
        Label = 'Buss Wine Female',
        Command = 'bussawinef',
        Animation = 'bussawinef_clip',
        Dictionary = 'sakec@bussawine_v1_f',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'bussawinem',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Buss Wine Male',
        Command = 'bussawinem',
        Animation = 'bussawinem_clip',
        Dictionary = 'sakec@bussawine_v1_m',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'bussawinef',
            },
        },
    },
    {
        Label = 'Fortnite Outwest',
        Command = 'pfoutwest',
        Animation = 'pazeee@fournite@outwest@clip',
        Dictionary = 'pazeee@fournite@outwest@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfoutwest',
            },
        },
    },
    {
        Label = 'Fortnite Rollie',
        Command = 'pfrollie',
        Animation = 'pazeee@fournite@rollie@clip',
        Dictionary = 'pazeee@fournite@rollie@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfrollie',
            },
        },
    },
    {
        Label = 'Fortnite Thesquabble',
        Command = 'pfthesquabble',
        Animation = 'pazeee@fournite@thesquabble@clip',
        Dictionary = 'pazeee@fournite@thesquabble@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfthesquabble',
            },
        },
    },
    {
        Label = 'Fortnite Billybounce',
        Command = 'pfbillybounce',
        Animation = 'pazeee@fournite@billybounce@clip',
        Dictionary = 'pazeee@fournite@billybounce@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfbillybounce',
            },
        },
    },
    {
        Label = 'Fortnite Maximumbounce',
        Command = 'pfmaximumbounce',
        Animation = 'pazeee@fournite@maximumbounce@clip',
        Dictionary = 'pazeee@fournite@maximumbounce@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfmaximumbounce',
            },
        },
    },
    {
        Label = 'Fortnite Stuck',
        Command = 'pfstuck',
        Animation = 'pazeee@fournite@stuck@clip',
        Dictionary = 'pazeee@fournite@stuck@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfstuck',
            },
        },
    },
    {
        Label = 'Fortnite Socks',
        Command = 'pfsocks',
        Animation = 'pazeee@fournite@socks@clip',
        Dictionary = 'pazeee@fournite@socks@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfsocks',
            },
        },
    },
    {
        Label = 'Fortnite Pullup',
        Command = 'pfpullup',
        Animation = 'pazeee@fournite@pullup@clip',
        Dictionary = 'pazeee@fournite@pullup@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfpullup',
            },
        },
    },
    {
        Label = 'Fortnite Chickenwingit',
        Command = 'pfchickenwingit',
        Animation = 'pazeee@fournite@chickenwingit@clip',
        Dictionary = 'pazeee@fournite@chickenwingit@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfchickenwingit',
            },
        },
    },
    {
        Label = 'Fortnite Savage',
        Command = 'pfsavage',
        Animation = 'pazeee@fournite@savage@clip',
        Dictionary = 'pazeee@fournite@savage@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfsavage',
            },
        },
    },
    {
        Label = 'Fortnite Imdiamond',
        Command = 'pfimdiamond',
        Animation = 'pazeee@fournite@imdiamond@clip',
        Dictionary = 'pazeee@fournite@imdiamond@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfimdiamond',
            },
        },
    },
    {
        Label = 'Fortnite Itsdynamite',
        Command = 'pfitsdynamite',
        Animation = 'pazeee@fournite@itsdynamite@clip',
        Dictionary = 'pazeee@fournite@itsdynamite@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfitsdynamite',
            },
        },
    },
    {
        Label = 'Fortnite Toosieslide',
        Command = 'pftoosieslide',
        Animation = 'pazeee@fournite@toosieslide@clip',
        Dictionary = 'pazeee@fournite@toosieslide@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pftoosieslide',
            },
        },
    },
    {
        Label = 'Fortnite Therenegade',
        Command = 'pftherenegade',
        Animation = 'pazeee@fournite@therenegade@clip',
        Dictionary = 'pazeee@fournite@therenegade@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pftherenegade',
            },
        },
    },
    {
        Label = 'Fortnite Dontstartnow',
        Command = 'pfdontstartnow',
        Animation = 'pazeee@fournite@dontstartnow@clip',
        Dictionary = 'pazeee@fournite@dontstartnow@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfdontstartnow',
            },
        },
    },
    {
        Label = 'Fortnite Ambitious',
        Command = 'pfambitious',
        Animation = 'pazeee@fournite@ambitious@clip',
        Dictionary = 'pazeee@fournite@ambitious@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfambitious',
            },
        },
    },
    {
        Label = 'Fortnite Lunarparty',
        Command = 'pflunarparty',
        Animation = 'pazeee@fournite@lunarparty@clip',
        Dictionary = 'pazeee@fournite@lunarparty@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pflunarparty',
            },
        },
    },
    {
        Label = 'Fortnite Hitit',
        Command = 'pfhitit',
        Animation = 'pazeee@fournite@hitit@clip',
        Dictionary = 'pazeee@fournite@hitit@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfhitit',
            },
        },
    },
    {
        Label = 'Fortnite Nocure',
        Command = 'pfnocure',
        Animation = 'pazeee@fournite@nocure@clip',
        Dictionary = 'pazeee@fournite@nocure@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfnocure',
            },
        },
    },
    {
        Label = 'Fortnite Clickclickflash',
        Command = 'pfclickclickflash',
        Animation = 'pazeee@fournite@clickclickflash@clip',
        Dictionary = 'pazeee@fournite@clickclickflash@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfclickclickflash',
            },
        },
    },
    {
        Label = 'Fortnite Wannaseeme',
        Command = 'pfwannaseeme',
        Animation = 'pazeee@fournite@wannaseeme@clip',
        Dictionary = 'pazeee@fournite@wannaseeme@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfwannaseeme',
            },
        },
    },
    {
        Label = 'Fortnite Headbanger',
        Command = 'pfheadbanger',
        Animation = 'pazeee@fournite@headbanger@clip',
        Dictionary = 'pazeee@fournite@headbanger@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Ptfx = {
                Asset = 'core',
                Bone = 31086,
                CanHold = true,
                Name = 'fire_wrecked_train',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                    1.25,
                },
                Wait = 200,
            },
            Shared = {
                OtherAnimation = 'pfheadbanger',
            },
        },
    },
    {
        Label = 'Fortnite Rage',
        Command = 'pfrage',
        Animation = 'pazeee@fournite@rage@clip',
        Dictionary = 'pazeee@fournite@rage@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 28422,
                    Name = 'v_ilev_fos_mic',
                    Placement = {
                        vector3(0.130000, -0.140000, -0.240000),
                        vector3(-70.000000, 15.000000, 0.000000),
                    },
                },
            },
            Ptfx = {
                Asset = 'core',
                AttachToProp = true,
                CanHold = true,
                Name = 'fire_petroltank_car',
                Placement = {
                    vector3(-0.650000, 0.050000, 1.000000),
                    vector3(-270.000000, 90.000000, 0.000000),
                    2.5,
                },
                Wait = 200,
            },
            Shared = {
                OtherAnimation = 'pfrage',
            },
        },
    },
    {
        Label = 'Fortnite Bigdawgs',
        Command = 'pfbigdawgs',
        Animation = 'pazeee@fournite@bigdawgs@clip',
        Dictionary = 'pazeee@fournite@bigdawgs@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'pfbigdawgs',
            },
        },
    },
    {
        Label = 'Fortnite Bigdawgs Move',
        Command = 'pfbigdawgsmove',
        Animation = 'pazeee@fournite@bigdawgsmove@clip',
        Dictionary = 'pazeee@fournite@bigdawgsmove@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Ptfx = {
                Asset = 'core',
                CanHold = true,
                Name = 'exp_grd_train',
                Placement = {
                    vector3(0.000000, 0.200000, -0.900000),
                    vector3(0.000000, 0.000000, 0.000000),
                    0.25,
                },
                Wait = 200,
            },
            Shared = {
                OtherAnimation = 'pfbigdawgsmove',
            },
        },
    },
    {
        Label = 'Lanisha Anim - Good Head - ‍',
        Command = 'gta304',
        Animation = 'mrwitt_lanisha1',
        Dictionary = 'mrwittlanisha1@female_nsfw1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta305',
                Placement = {
                    vector3(0.000000, 0.600000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Good Head',
        Command = 'gta305',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'mrwittlanisha@male_nsfw1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta304',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Anal Doggy - ‍',
        Command = 'gta302',
        Animation = 'lanisha',
        Dictionary = 'doggy6@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta303',
                Placement = {
                    vector3(0.000000, -0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Anal Doggy',
        Command = 'gta303',
        Animation = 'lanisha',
        Dictionary = 'doggy6m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta302',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Rough Doggy 2 - ‍',
        Command = 'gta300',
        Animation = 'lanisha',
        Dictionary = 'normaldoggyf@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta301',
                Placement = {
                    vector3(0.000000, -0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Rough Doggy 2',
        Command = 'gta301',
        Animation = 'lanisha',
        Dictionary = 'fastdoggym@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta300',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Rough Doggy 1 - ‍',
        Command = 'gta298',
        Animation = 'lanisha',
        Dictionary = 'fastdoggyf@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta299',
                Placement = {
                    vector3(0.000000, -0.200000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Rough Doggy 1',
        Command = 'gta299',
        Animation = 'lanisha',
        Dictionary = 'fastdoggym@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta298',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Chair Fuck 2 - ‍',
        Command = 'gta296',
        Animation = 'lanisha',
        Dictionary = 'chairfuck2@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta297',
                Placement = {
                    vector3(0.000000, -0.200000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Chair Fuck 2',
        Command = 'gta297',
        Animation = 'lanisha',
        Dictionary = 'chairfuck2@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta296',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Wall Cuffed - ‍',
        Command = 'gta294',
        Animation = 'lanisha',
        Dictionary = 'walltie@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta295',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Wall Cuffed',
        Command = 'gta295',
        Animation = 'lanisha',
        Dictionary = 'walltie@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta294',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Desky Fuck - ‍',
        Command = 'gta292',
        Animation = 'lanisha',
        Dictionary = 'overdesk@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta293',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Desky Fuck',
        Command = 'gta293',
        Animation = 'lanisha',
        Dictionary = 'overdesk@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta292',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Scissors - ‍',
        Command = 'gta284',
        Animation = 'lanisha',
        Dictionary = 'lesbian7@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta285',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Scissors',
        Command = 'gta285',
        Animation = 'lanisha',
        Dictionary = 'lesbian7@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta284',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl 2 - ‍',
        Command = 'gta282',
        Animation = 'lanisha',
        Dictionary = 'cowgirlupdate2@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta283',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl 2',
        Command = 'gta283',
        Animation = 'lanisha',
        Dictionary = 'cowgirl5m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta282',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian 2 - ‍',
        Command = 'gta280',
        Animation = 'lanisha',
        Dictionary = 'lesbian6@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta281',
                Placement = {
                    vector3(0.000000, 0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian 2',
        Command = 'gta281',
        Animation = 'lanisha',
        Dictionary = 'lesbian6@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta280',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Fingering - ‍',
        Command = 'gta278',
        Animation = 'lanisha',
        Dictionary = 'lesbian5@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta279',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Fingering',
        Command = 'gta279',
        Animation = 'lanisha',
        Dictionary = 'lesbian5@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta278',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Pinned Down Fast - ‍',
        Command = 'gta276',
        Animation = 'lanisha',
        Dictionary = 'tied@lanishafast',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta277',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Pinned Down Fast',
        Command = 'gta277',
        Animation = 'lanisha',
        Dictionary = 'tied@lanishafastm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta276',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Pinned Down Slow - ‍',
        Command = 'gta274',
        Animation = 'lanisha',
        Dictionary = 'tied@lanishaslow',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta275',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Pinned Down Slow',
        Command = 'gta275',
        Animation = 'lanisha',
        Dictionary = 'tiedm@lanishaslow',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta274',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground&Pound V5 Fast - ‍',
        Command = 'gta272',
        Animation = 'lanisha',
        Dictionary = 'groundv6@lanisha5fast2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta273',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground&Pound V5 Fast',
        Command = 'gta273',
        Animation = 'lanisha',
        Dictionary = 'groundv6@lanisha5fast',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta272',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground&Pound V5 Slow - ‍',
        Command = 'gta270',
        Animation = 'lanisha',
        Dictionary = 'groundv6@lanisha5slowf',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta271',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground&Pound V5 Slow',
        Command = 'gta271',
        Animation = 'lanisha',
        Dictionary = 'groundv6@lanisha5slowm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta270',
            },
        },
        NSFW = true,
    },
    {
        Label = '69 - ‍',
        Command = 'gta268',
        Animation = 'lanisha',
        Dictionary = '69@lanishaf',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta269',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = '69',
        Command = 'gta269',
        Animation = 'lanisha',
        Dictionary = '69@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta268',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian 69 - ‍',
        Command = 'gta266',
        Animation = 'lanisha',
        Dictionary = 'lesbian69@lanishafix',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta267',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian 69',
        Command = 'gta267',
        Animation = 'lanisha',
        Dictionary = 'lesbian69@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta266',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Pleasure - ‍',
        Command = 'gta264',
        Animation = 'lanisha',
        Dictionary = 'lespleasure@lanisha2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta265',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Pleasure',
        Command = 'gta265',
        Animation = 'lanisha',
        Dictionary = 'lespleasure@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta264',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Eat Pussy - ‍',
        Command = 'gta262',
        Animation = 'lanisha',
        Dictionary = 'lesbo2@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta263',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Eat Pussy',
        Command = 'gta263',
        Animation = 'lanisha',
        Dictionary = 'lesbo2fix@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta262',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Beat it up - ‍',
        Command = 'gta260',
        Animation = 'lanisha',
        Dictionary = 'theride@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta261',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Beat it up',
        Command = 'gta261',
        Animation = 'lanisha',
        Dictionary = 'theridem@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta260',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Back It Up - ‍',
        Command = 'gta258',
        Animation = 'lanisha',
        Dictionary = 'backitup@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta259',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Back It Up',
        Command = 'gta259',
        Animation = 'lanisha',
        Dictionary = 'backitupm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta258',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl V4 Reverse - ‍',
        Command = 'gta254',
        Animation = 'lanisha',
        Dictionary = 'cowgirl3f@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta255',
                Placement = {
                    vector3(0.000000, -0.500000, -0.050000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl V4 Reverse',
        Command = 'gta255',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@cowgirlreversem',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta254',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl V4 - ‍',
        Command = 'gta250',
        Animation = 'lanisha',
        Dictionary = 'cowgirl3f@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta251',
                Placement = {
                    vector3(0.000000, 0.070000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Cowgirl V4',
        Command = 'gta251',
        Animation = 'lanisha',
        Dictionary = 'cowgirl3m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta250',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground & Twerk - ‍',
        Command = 'gta248',
        Animation = 'lanisha',
        Dictionary = 'pronetwerkf@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta249',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground & Twerk',
        Command = 'gta249',
        Animation = 'lanisha',
        Dictionary = 'pronetwerk@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta248',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Table Missionary - ‍',
        Command = 'gta246',
        Animation = 'lanisha',
        Dictionary = 'deskfuckf2@lanisha2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta247',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Table Missionary',
        Command = 'gta247',
        Animation = 'lanisha',
        Dictionary = 'officefuckm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta246',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Pole Oral - ‍',
        Command = 'gta244',
        Animation = 'lanisha',
        Dictionary = 'poleoral@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta245',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lesbian Pole Oral',
        Command = 'gta245',
        Animation = 'lanisha',
        Dictionary = 'poleoral3@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta244',
            },
        },
        NSFW = true,
    },
    {
        Label = 'BDSM 1 - ‍',
        Command = 'gta242',
        Animation = 'lanisha',
        Dictionary = 'katelynbdsm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta243',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'BDSM 1',
        Command = 'gta243',
        Animation = 'lanisha',
        Dictionary = 'mkatelynbdsm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta242',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground & Pound V6 - ‍',
        Command = 'gta240',
        Animation = 'lanisha',
        Dictionary = 'groundv6@lanisha5',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta241',
                Placement = {
                    vector3(0.000000, -0.100000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Ground & Pound V6',
        Command = 'gta241',
        Animation = 'lanisha',
        Dictionary = 'groundv6m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta240',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Beat Dat Pussy Up - ‍',
        Command = 'gta238',
        Animation = 'lanisha',
        Dictionary = 'beatitup@lanisha2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta239',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Beat Dat Pussy Up',
        Command = 'gta239',
        Animation = 'lanisha',
        Dictionary = 'beatitupm@lanisha2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta238',
            },
        },
        NSFW = true,
    },
    {
        Label = 'DoggyTabe - ‍',
        Command = 'gta236',
        Animation = 'lanisha',
        Dictionary = 'doggytable@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta237',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'DoggyTabe',
        Command = 'gta237',
        Animation = 'lanisha',
        Dictionary = 'mdoggytable@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta236',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Face Sitting - ‍',
        Command = 'gta234',
        Animation = 'lanisha',
        Dictionary = 'facesittingf3@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta235',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Face Sitting',
        Command = 'gta235',
        Animation = 'lanisha',
        Dictionary = 'facesitting@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta234',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Heels on - DoggyStyle 2 - ‍',
        Command = 'gta232',
        Animation = 'lanisha',
        Dictionary = 'doggy2f@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta233',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Heels on - DoggyStyle 2',
        Command = 'gta233',
        Animation = 'lanisha',
        Dictionary = 'doggym2@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta232',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Heels on - DoggyStyle - ‍',
        Command = 'gta230',
        Animation = 'lanisha',
        Dictionary = 'd0ggy@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta231',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Heels on - DoggyStyle',
        Command = 'gta231',
        Animation = 'lanisha',
        Dictionary = 'doggym@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta230',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Punish me 2 - ‍',
        Command = 'gta228',
        Animation = 'lanisha',
        Dictionary = 'tied@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta229',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Punish Her 2',
        Command = 'gta229',
        Animation = 'lanisha',
        Dictionary = 'tiedm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta228',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Punish me - ‍',
        Command = 'gta226',
        Animation = 'lanisha',
        Dictionary = 'bdsm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta227',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Punish Her',
        Command = 'gta227',
        Animation = 'lanisha',
        Dictionary = 'bdsmm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta226',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Eat my Ass - ‍',
        Command = 'gta224',
        Animation = 'lanisha',
        Dictionary = 'eatmyass@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta225',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Eat Her Ass',
        Command = 'gta225',
        Animation = 'lanisha',
        Dictionary = 'eatmyassm@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta224',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Throw Me On Da Table 2 - ‍',
        Command = 'gta222',
        Animation = 'lanisha',
        Dictionary = 'desk3@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta223',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Throw her On Da Table 2',
        Command = 'gta223',
        Animation = 'lanisha',
        Dictionary = 'desk2m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta222',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Throw Me On Da Table - ‍',
        Command = 'gta220',
        Animation = 'lanisha',
        Dictionary = 'desk2@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Ptfx = {
                Asset = 'scr_ba_club',
                CanHold = true,
                Name = 'scr_ba_club_champagne_spray',
                Placement = {
                    vector3(0.000000, -0.100000, 0.000000),
                    vector3(20.000000, 0.000000, 180.000000),
                    0.4,
                },
                Wait = 1,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta221',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Throw her On Da Table',
        Command = 'gta221',
        Animation = 'lanisha',
        Dictionary = 'desk2m@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta220',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Twerk on Da Dick - ‍',
        Command = 'gta136',
        Animation = 'ratchettwerk01',
        Dictionary = 'satocratchettwerk01',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta137',
                Placement = {
                    vector3(0.000000, 0.300000, 0.000000),
                    vector3(-10.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Let her Twerk on you',
        Command = 'gta137',
        Animation = 'lanisha',
        Dictionary = 'lanisha@malewatch',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta136',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Make Him Nut - ‍',
        Command = 'gta134',
        Animation = 'lanisha_animations',
        Dictionary = 'lanisha@busthisnut',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta135',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(-10.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Nut in her butt',
        Command = 'gta135',
        Animation = 'lanisha',
        Dictionary = 'lanisha@malewatch',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta134',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Anal Wall Fuck - ‍',
        Command = 'gta132',
        Animation = 'lanisha',
        Dictionary = 'lanisha@wallf',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta133',
                Placement = {
                    vector3(0.000000, 0.000000, -0.100000),
                    vector3(-10.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Anal Wall Fuck',
        Command = 'gta133',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@deskm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta132',
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - R Ground & Pound v5 - ‍',
        Command = 'gta130',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundpound6',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta131',
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - R Ground & Pound v5',
        Command = 'gta131',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@groundpoundm5',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta130',
                Placement = {
                    vector3(0.000000, -0.010100, -0.097000),
                    vector3(3.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Ground & Pound v5 - ‍',
        Command = 'gta128',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundpound5',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta129',
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Ground & Pound v5',
        Command = 'gta129',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@groundpoundm5',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta128',
                Placement = {
                    vector3(0.000000, -0.010100, -0.090000),
                    vector3(5.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Chair Fuck Reverse - ‍',
        Command = 'gta126',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@femaleride2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta127',
                Placement = {
                    vector3(0.000000, -0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Chair Fuck Reverse',
        Command = 'gta127',
        Animation = 'lanisha',
        Dictionary = 'lanisha@maleride2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta126',
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Chair Fuck - ‍',
        Command = 'gta124',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@femaleride',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta125',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'No Heels Required - Chair Fuck',
        Command = 'gta125',
        Animation = 'lanisha',
        Dictionary = 'lanisha@maleride',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta124',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Bend Over Fuck - ‍',
        Command = 'gta122',
        Animation = 'lanisha',
        Dictionary = 'lanisha@deskf',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta123',
                Placement = {
                    vector3(0.000000, 0.000000, -0.050000),
                    vector3(-20.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Bend Over Fuck',
        Command = 'gta123',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@deskm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta122',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Cowgirl Bounce - ‍',
        Command = 'gta120',
        Animation = 'lanisha',
        Dictionary = 'lanisha@cowgirlreverse1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta121',
                Placement = {
                    vector3(0.000000, -0.200000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Cowgirl Bounce',
        Command = 'gta121',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@cowgirlreversem',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta120',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Cowgirl Bounce Reverse - ‍',
        Command = 'gta118',
        Animation = 'lanisha',
        Dictionary = 'lanisha@cowgirlreverse1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta119',
                Placement = {
                    vector3(0.000000, -0.095000, -0.090000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Cowgirl Bounce Reverse',
        Command = 'gta119',
        Animation = 'lanisha1',
        Dictionary = 'lanisha@cowgirlreversem',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta118',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Bed Finger Fuck',
        Command = 'gta116',
        Animation = 'mrwitt_lanisha1',
        Dictionary = 'mrwitt@nsfw_38_male1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta117',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Missionary Pinned down - ‍',
        Command = 'gta117',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'mrwitt@nsfw_38_female1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta116',
                Placement = {
                    vector3(0.000000, 0.050000, -0.070000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Missionary Pinned down - ‍',
        Command = 'gta114',
        Animation = 'lanisha',
        Dictionary = 'lanisha@missionaryfemale',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta115',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Missionary Pinned down',
        Command = 'gta115',
        Animation = 'lanisha',
        Dictionary = 'lanisha@missionarymale',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta114',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(5.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Ground & Pound Anal - ‍',
        Command = 'gta112',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundtwerk2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta113',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Ground & Pound Anal',
        Command = 'gta113',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundtwerk2m',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta112',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(5.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Bust that nut - ‍',
        Command = 'gta110',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundtwerk',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta111',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Bust that nut',
        Command = 'gta111',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundtwerkm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta110',
                Placement = {
                    vector3(0.000000, 0.000000, -0.070000),
                    vector3(5.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Ground & Pound v4 - ‍',
        Command = 'gta108',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundpound4',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta109',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Ground & Pound v4',
        Command = 'gta109',
        Animation = 'lanisha',
        Dictionary = 'lanisha@groundpound4m',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta108',
                Placement = {
                    vector3(0.000000, 0.000000, -0.070000),
                    vector3(5.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Reverse Riding Pose 1 - ‍',
        Command = 'gta106',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'mrwitt@nsfw_20_female1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta107',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Reverse Riding Pose 1',
        Command = 'gta107',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'mrwitt@nsfw_20_male1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta106',
                Placement = {
                    vector3(0.045000, -0.200000, 0.100000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Anal 2 ‍',
        Command = 'gta104',
        Animation = 'mrwitt_lanisha1',
        Dictionary = 'lanisha@nsfw8',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta105',
                Placement = {
                    vector3(0.000000, 0.500000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Anal 2',
        Command = 'gta105',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'lanisha@nsfw7',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta104',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Anal ‍',
        Command = 'gta102',
        Animation = 'mrwitt_lanisha1',
        Dictionary = 'lanisha@nsfw6',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta103',
                Placement = {
                    vector3(0.000000, 0.400000, -0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Anal',
        Command = 'gta103',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'lanisha@nsfw5',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta102',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Missionary Balls Deep ‍',
        Command = 'gta100',
        Animation = 'mrwitt_lanisha1',
        Dictionary = 'lanisha@nsfw3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta101',
                Placement = {
                    vector3(0.000000, 0.300000, -0.100000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Missionary Balls Deep',
        Command = 'gta101',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'lanisha@nsfw1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta100',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Finger Fuck ‍',
        Command = 'gta98',
        Animation = 'mrwitt_animation',
        Dictionary = 'lanisha@lesbianreciever',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta99',
                Placement = {
                    vector3(0.100000, 0.600000, -0.100000),
                    vector3(-10.000000, 15.000000, 176.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Finger Fuck',
        Command = 'gta99',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'lanisha@lesbiangiver',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta98',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Missionary ‍',
        Command = 'gta96',
        Animation = 'mrwitt_lanisha',
        Dictionary = 'missionaryfemale@lanisha',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'gta97',
                Placement = {
                    vector3(0.100000, -0.200000, -0.100000),
                    vector3(0.000000, 0.000000, 185.000000),
                },
            },
        },
        NSFW = true,
    },
    {
        Label = 'Lanisha Anim - Rough Missionary',
        Command = 'gta97',
        Animation = 'mirwiit_lanisha',
        Dictionary = 'missionary@lanisha1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'gta96',
            },
        },
        NSFW = true,
    },
    {
        Label = 'Kiss 8(Male)',
        Command = 'kiss15',
        Animation = 'kissmale8',
        Dictionary = 'genesismods_kissme@kissmale8',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kiss16',
                Placement = {
                    vector3(-0.560000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 8(Female)',
        Command = 'kiss16',
        Animation = 'kissfemale8',
        Dictionary = 'genesismods_kissme@kissfemale8',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kiss15',
            },
        },
    },
    {
        Label = 'Kiss 9(Male)',
        Command = 'kiss17',
        Animation = 'kissmale9',
        Dictionary = 'genesismods_kissme@kissmale9',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kiss18',
                Placement = {
                    vector3(0.350000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 9(Female)',
        Command = 'kiss18',
        Animation = 'kissfemale9',
        Dictionary = 'genesismods_kissme@kissfemale9',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kiss17',
            },
        },
    },
    {
        Label = 'Kiss 10(Male)',
        Command = 'kiss19',
        Animation = 'kissmale10',
        Dictionary = 'genesismods_kissme@kissmale10',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kiss20',
                Placement = {
                    vector3(0.380000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 10(Female)',
        Command = 'kiss20',
        Animation = 'kissfemale10',
        Dictionary = 'genesismods_kissme@kissfemale10',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kiss19',
            },
        },
    },
    {
        Label = 'Kiss 5',
        Command = 'kiss5',
        Animation = 'tigerle_couple_kissing1a',
        Dictionary = 'tigerle@custom@couple@kissing1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kiss6',
            },
        },
    },
    {
        Label = 'Kiss 6',
        Command = 'kiss6',
        Animation = 'tigerle_couple_kissing1b',
        Dictionary = 'tigerle@custom@couple@kissing1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kiss5',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'kiss7',
        Animation = 'tigerle_couple_kissing2a',
        Dictionary = 'tigerle@custom@couple@kissing2a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kiss8',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'kiss8',
        Animation = 'tigerle_couple_kissing2b',
        Dictionary = 'tigerle@custom@couple@kissing2b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kiss7',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'cuddleet',
        Animation = 'tigerle_couple_cuddle1a',
        Dictionary = 'tigerle@custom@couple@cuddle1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'cuddleet2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'cuddleet2',
        Animation = 'tigerle_couple_cuddle1b',
        Dictionary = 'tigerle@custom@couple@cuddle1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'cuddleet',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'cuddleet3',
        Animation = 'tigerle_couple_cuddleno2a',
        Dictionary = 'tigerle@custom@couple@cuddle@no2a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'cuddleet4',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'cuddleet4',
        Animation = 'tigerle_couple_cuddleno2b',
        Dictionary = 'tigerle@custom@couple@cuddle@no2b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'cuddleet3',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'layying',
        Animation = 'tigerle_couple_laying1a',
        Dictionary = 'tigerle@custom@couple@laying1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'layying2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'layying2',
        Animation = 'tigerle_couple_laying1b',
        Dictionary = 'tigerle@custom@couple@laying1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'layying',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'sitting',
        Animation = 'tigerle_couple_sittingonbench_no1a',
        Dictionary = 'tigerle@custom@couple@sittingonbench@no1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitting2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'sitting2',
        Animation = 'tigerle_couple_sittingonbench_no1b',
        Dictionary = 'tigerle@custom@couple@sittingonbench@no1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'sitting',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'cuddleet5',
        Animation = 'tigerle_couple_standcuddle_a',
        Dictionary = 'tigerle@custom@couple@standcuddle_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'cuddleet6',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'cuddleet6',
        Animation = 'tigerle_couple_standcuddle_b',
        Dictionary = 'tigerle@custom@couple@standcuddle_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'cuddleet5',
                Placement = {
                    vector3(0.000000, 0.350000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'standingg',
        Animation = 'tigerle_couple_standing_a',
        Dictionary = 'tigerle@custom@couple@standing_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'standingg2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'standingg2',
        Animation = 'tigerle_couple_standing_b',
        Dictionary = 'tigerle@custom@couple@standing_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'standingg',
                Placement = {
                    vector3(0.100000, 0.300000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'titanic',
        Animation = 'tigerle_pose_titanic1a',
        Dictionary = 'tigerle@custom@pose@titanic1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'titanic2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'titanic2',
        Animation = 'tigerle_pose_titanic1b',
        Dictionary = 'tigerle@custom@pose@titanic1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'titanic',
                Placement = {
                    vector3(0.100000, 0.300000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss 7',
        Command = 'bfff',
        Animation = 'tigerle_pose_bff1a',
        Dictionary = 'tigerle@custom@pose@bff1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'bfff2',
            },
        },
    },
    {
        Label = 'Kiss 8',
        Command = 'bfff2',
        Animation = 'tigerle_pose_bff1b',
        Dictionary = 'tigerle@custom@pose@bff1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'bfff',
                Placement = {
                    vector3(0.700000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Chair Pose NEW',
        Command = 'sitchairposem',
        Animation = 'fm_couple1_f_clip',
        Dictionary = 'myu@fm_couple1_1',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 0,
                    Name = 'hei_heist_stn_chairstrip_01',
                    Placement = {
                        vector3(-0.040000, -0.120000, -0.600000),
                        vector3(-180.000000, -180.000000, 9.099900),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'sitchairposef',
            },
        },
    },
    {
        Label = 'Sit Chair Pose NEW',
        Command = 'sitchairposef',
        Animation = 'fm_couple1_m_clip',
        Dictionary = 'myu@fm_couple1_2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitchairposem',
                Placement = {
                    vector3(0.000000, 1.200000, 0.350000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Pose',
        Command = 'sitposem',
        Animation = 'coupleshoulderm_clip NEW',
        Dictionary = 'coupleshoulderm@sarahdiehexe',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitposef',
            },
        },
    },
    {
        Label = 'Sit Pose NEW',
        Command = 'sitposef',
        Animation = 'coupleshoulderf_clip',
        Dictionary = 'coupleshoulderf@sarahdiehexe',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitposem',
                Placement = {
                    vector3(-0.600000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Ass Pose NEW',
        Command = 'assposem',
        Animation = 'ass_clip',
        Dictionary = 'ass@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'assposef',
            },
        },
    },
    {
        Label = 'Ass Pose NEW',
        Command = 'assposef',
        Animation = 'ass1_clip',
        Dictionary = 'ass1@animation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'assposem',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.500000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Side By Side Pose NEW',
        Command = 'sidebysm',
        Animation = 'banner_01_clip',
        Dictionary = 'banner_01@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sidebysf',
            },
        },
    },
    {
        Label = 'Side By Side Pose NEW',
        Command = 'sidebysf',
        Animation = 'banner_02_clip',
        Dictionary = 'banner_02@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sidebysm',
                Placement = {
                    vector3(0.480000, -0.100000, 0.000000),
                    vector3(2.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Hot Love Pose NEW',
        Command = 'hotsitm',
        Animation = 'mx@couple1_a_clip',
        Dictionary = 'mx@couple1_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'hotsitf',
            },
        },
    },
    {
        Label = 'Sit Hot Love Pose NEW',
        Command = 'hotsitf',
        Animation = 'mx@couple1_b_clip',
        Dictionary = 'mx@couple1_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'hotsitm',
                Placement = {
                    vector3(0.000000, 0.550000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Hot Love Pose1 NEW',
        Command = 'hotsitm2',
        Animation = 'mx@couple2_a_clip',
        Dictionary = 'mx@couple2_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'hotsitf2',
            },
        },
    },
    {
        Label = 'Sit Hot Love Pose2 NEW',
        Command = 'hotsitf2',
        Animation = 'mx@couple2_b_clip',
        Dictionary = 'mx@couple2_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'hotsitm2',
                Placement = {
                    vector3(0.000000, 0.550000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Carry Pose1 NEW',
        Command = 'lovecrrym',
        Animation = 'mx@couple4_a_clip',
        Dictionary = 'mx@couple4_a',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'lovecrryf',
            },
        },
    },
    {
        Label = 'Love Carry Pose1 NEW',
        Command = 'lovecrryf',
        Animation = 'mx@couple4_b_clip',
        Dictionary = 'mx@couple4_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovecrrym',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Chair Love2 NEW',
        Command = 'sitchrlv2m',
        Animation = 'benchm_clip',
        Dictionary = 'benchm@spider',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitchrlv2f',
            },
        },
    },
    {
        Label = 'Sit Chair Love2 NEW',
        Command = 'sitchrlv2f',
        Animation = 'benchf_clip',
        Dictionary = 'benchf@spider',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitchrlv2m',
                Placement = {
                    vector3(0.000000, 0.390000, 0.360000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Bike Pose NEW',
        Command = 'sitbikepm',
        Animation = 'bikefistmale_clip',
        Dictionary = 'bikefistmale@joker',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitbikepf',
            },
        },
    },
    {
        Label = 'Sit Bike Pose NEW',
        Command = 'sitbikepf',
        Animation = 'bikefistfemale_clip',
        Dictionary = 'bikefistfemale@joker',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitbikepm',
            },
        },
    },
    {
        Label = 'Sit Love Rock NEW',
        Command = 'sitloverockm',
        Animation = 'couple46_clip',
        Dictionary = 'chocoholic@couple46',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitloverockf',
            },
        },
    },
    {
        Label = 'Sit Love Rock NEW',
        Command = 'sitloverockf',
        Animation = 'couple45_clip',
        Dictionary = 'chocoholic@couple45',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitloverockm',
                Placement = {
                    vector3(0.170000, 0.350000, 0.150000),
                    vector3(0.000000, 0.000000, 30.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Chair Love3 NEW',
        Command = 'sitchairlove3m',
        Animation = 'couple47_v3_clip',
        Dictionary = 'chocoholic@couple47_v3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitchairlove3f',
            },
        },
    },
    {
        Label = 'Sit Chair Love3 NEW',
        Command = 'sitchairlove3f',
        Animation = 'couple48_v3_clip',
        Dictionary = 'chocoholic@couple48_v3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitchairlove3m',
                Placement = {
                    vector3(0.000000, 0.850000, 0.300000),
                    vector3(-5.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Walk With Love1 NEW',
        Command = 'walklove1m',
        Animation = 'couple50_clip',
        Dictionary = 'chocoholic@couple50',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'walklove1f',
            },
        },
    },
    {
        Label = 'Walk With Love1 NEW',
        Command = 'walklove1f',
        Animation = 'couple49_clip',
        Dictionary = 'chocoholic@couple49',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'walklove1m',
                Placement = {
                    vector3(-0.340000, -0.190000, 0.000000),
                    vector3(0.000000, 0.000000, 5.000000),
                },
            },
        },
    },
    {
        Label = 'Kissing Love1 NEW',
        Command = 'kisslovpose1m',
        Animation = 'couple51_clip',
        Dictionary = 'chocoholic@couple51',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kisslovpose1f',
            },
        },
    },
    {
        Label = 'Kissing Love1 NEW',
        Command = 'kisslovpose1f',
        Animation = 'couple52_clip',
        Dictionary = 'chocoholic@couple52',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'kisslovpose1m',
                Placement = {
                    vector3(0.000000, 0.300000, -0.100000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Kissing Love Pose2 NEW',
        Command = 'kissinglv2m',
        Animation = 'couple54_clip',
        Dictionary = 'chocoholic@couple54',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kissinglv2f',
            },
        },
    },
    {
        Label = 'Kissing Love Pose2 NEW',
        Command = 'kissinglv2f',
        Animation = 'couple53_clip',
        Dictionary = 'chocoholic@couple53',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'kissinglv2m',
                Placement = {
                    vector3(0.000000, 0.280000, -0.080000),
                    vector3(0.000000, 0.000000, 50.000000),
                },
            },
        },
    },
    {
        Label = 'Kissing Love Pose4 NEW',
        Command = 'kissinglvpose4m',
        Animation = 'couple55_clip',
        Dictionary = 'chocoholic@couple55',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kissinglvpose4f',
            },
        },
    },
    {
        Label = 'Kissing Love Pose4 NEW',
        Command = 'kissinglvpose4f',
        Animation = 'couple56_clip',
        Dictionary = 'chocoholic@couple56',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'kissinglvpose4m',
                Placement = {
                    vector3(0.000000, 0.320000, -0.050000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Kissing Wall Love2 NEW',
        Command = 'kissinglvpose2m',
        Animation = 'wand_pose_01_clip',
        Dictionary = 'wand_pose_01@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kissinglvpose2f',
            },
        },
    },
    {
        Label = 'Kissing Wall Love2 NEW',
        Command = 'kissinglvpose2f',
        Animation = 'wand_pose_02_clip',
        Dictionary = 'wand_pose_02@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'kissinglvpose2m',
                Placement = {
                    vector3(-0.140000, -0.200000, 0.000000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Love Walking Pose 3 NEW',
        Command = 'lovewalkpose3m',
        Animation = 'couple57_clip',
        Dictionary = 'chocoholic@couple57',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovewalkpose3f',
            },
        },
    },
    {
        Label = 'Love Walking Pose 3 NEW',
        Command = 'lovewalkpose3f',
        Animation = 'couple58_clip',
        Dictionary = 'chocoholic@couple58',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovewalkpose3m',
                Placement = {
                    vector3(-0.980000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Walking Love 4 NEW',
        Command = 'walklove4m',
        Animation = 'couple59_clip',
        Dictionary = 'chocoholic@couple59',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'walklove4f',
            },
        },
    },
    {
        Label = 'Walking Love 4 NEW',
        Command = 'walklove4f',
        Animation = 'couple60_clip',
        Dictionary = 'chocoholic@couple60',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'walklove4m',
                Placement = {
                    vector3(0.000000, 0.240000, 1.200000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Love Pose 5 NEW',
        Command = 'sitlovepose5m',
        Animation = 'couple61_clip',
        Dictionary = 'chocoholic@couple61',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitlovepose5f',
            },
        },
    },
    {
        Label = 'Sit Love Pose 5 NEW',
        Command = 'sitlovepose5f',
        Animation = 'couple62_clip',
        Dictionary = 'chocoholic@couple62',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitlovepose5m',
                Placement = {
                    vector3(-0.200000, 0.500000, 0.000000),
                    vector3(118.000000, -215.000000, 210.000000),
                },
            },
        },
    },
    {
        Label = 'On The Foot Love Pose 1 NEW',
        Command = 'footloveposem',
        Animation = 'couple63_clip',
        Dictionary = 'chocoholic@couple63',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'footloveposef',
            },
        },
    },
    {
        Label = 'On The Foot Love Pose 1 NEW',
        Command = 'footloveposef',
        Animation = 'couple64_clip',
        Dictionary = 'chocoholic@couple64',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'footloveposem',
                Placement = {
                    vector3(0.000000, 0.090000, 0.480000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'On The Foot Love Pose 3 NEW',
        Command = 'footlovepose3m',
        Animation = 'schoko3_clip',
        Dictionary = 'schoko3@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'footlovepose3f',
            },
        },
    },
    {
        Label = 'On The Foot Love Pose 3 NEW',
        Command = 'footlovepose3f',
        Animation = 'schoko4_clip',
        Dictionary = 'schoko4@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'footlovepose3m',
                Placement = {
                    vector3(0.000000, 0.850000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Love Pose 6 NEW',
        Command = 'sitlovepose6m',
        Animation = 'schoko7_clip',
        Dictionary = 'schoko7@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitlovepose6f',
            },
        },
    },
    {
        Label = 'Sit Love Pose 6 NEW',
        Command = 'sitlovepose6f',
        Animation = 'schoko8_clip',
        Dictionary = 'schoko8@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitlovepose6m',
                Placement = {
                    vector3(0.000000, 0.000000, 0.700000),
                    vector3(-7.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Love Pose 7 NEW',
        Command = 'sitlovepose7m',
        Animation = 'couplem4_clip',
        Dictionary = 'couplem4@spider',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitlovepose7f',
            },
        },
    },
    {
        Label = 'Sit Love Pose 7 NEW',
        Command = 'sitlovepose7f',
        Animation = 'couple4_clip',
        Dictionary = 'couple4@spider',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitlovepose7m',
                Placement = {
                    vector3(0.000000, 0.550000, 0.380000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Wall Love Pose 2 NEW',
        Command = 'wallocepose2m',
        Animation = 'couple_wall_01_clip',
        Dictionary = 'couple_wall_01@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'wallocepose2f',
            },
        },
    },
    {
        Label = 'Wall Love Pose 2 NEW',
        Command = 'wallocepose2f',
        Animation = 'couple_wall_02_clip',
        Dictionary = 'couple_wall_02@sharror',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'wallocepose2m',
                Placement = {
                    vector3(0.820000, -0.210000, 0.030000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Love Pose 8 NEW',
        Command = 'sitlovepose8m',
        Animation = 'couplebench_m_clip',
        Dictionary = 'couplebench_m@gengaranimation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitlovepose8f',
            },
        },
    },
    {
        Label = 'Sit Love Pose 8 NEW',
        Command = 'sitlovepose8f',
        Animation = 'couplebench_f_clip',
        Dictionary = 'couplebench_f@gengaranimation',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitlovepose8m',
                Placement = {
                    vector3(-1.450000, 0.810000, 0.350000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Sit Love Pose 9 NEW',
        Command = 'sitlovepose9m',
        Animation = 'm_couple_01_clip',
        Dictionary = 'anim@male_couple_01',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitlovepose9f',
            },
        },
    },
    {
        Label = 'Sit Love Pose 9 NEW',
        Command = 'sitlovepose9f',
        Animation = 'f_couple_01_clip',
        Dictionary = 'anim@female_couple_01',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitlovepose9m',
                Placement = {
                    vector3(0.000000, 0.470000, 0.800000),
                    vector3(-15.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 4 NEW',
        Command = 'lovepose4m',
        Animation = 'm_couple_02_clip',
        Dictionary = 'anim@male_couple_02',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose4f',
            },
        },
    },
    {
        Label = 'Love Pose 4 NEW',
        Command = 'lovepose4f',
        Animation = 'f_couple_02_clip',
        Dictionary = 'anim@female_couple_02',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose4m',
                Placement = {
                    vector3(-0.500000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 7 NEW',
        Command = 'lovepose7m',
        Animation = 'm_couple_03_clip',
        Dictionary = 'anim@male_couple_03',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose7f',
            },
        },
    },
    {
        Label = 'Love Pose 7 NEW',
        Command = 'lovepose7f',
        Animation = 'f_couple_03_clip',
        Dictionary = 'anim@female_couple_03',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose7m',
                Placement = {
                    vector3(0.000000, 0.130000, 0.000000),
                    vector3(0.000000, 0.000000, 95.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 8 NEW',
        Command = 'lovepose8m',
        Animation = 'm_couple_03_b_clip',
        Dictionary = 'anim@male_couple_03_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose8f',
            },
        },
    },
    {
        Label = 'Love Pose 8 NEW',
        Command = 'lovepose8f',
        Animation = 'f_couple_03_b_clip',
        Dictionary = 'anim@female_couple_03_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose8m',
                Placement = {
                    vector3(0.000000, 0.130000, 0.000000),
                    vector3(0.000000, 0.000000, 95.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 9 NEW',
        Command = 'lovepose9m',
        Animation = 'm_couple_04_clip',
        Dictionary = 'anim@male_couple_04',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose9f',
            },
        },
    },
    {
        Label = 'Love Pose 9 NEW',
        Command = 'lovepose9f',
        Animation = 'f_couple_04_clip',
        Dictionary = 'anim@female_couple_04',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 28422,
                    Name = 'prop_phone_ing_03',
                    Placement = {
                        vector3(0.100000, 0.030000, 0.000000),
                        vector3(70.000000, 20.000000, -180.000000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose9m',
                Placement = {
                    vector3(0.000000, 0.260000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 10 NEW',
        Command = 'lovepose10m',
        Animation = 'm_couple_05_clip',
        Dictionary = 'anim@male_couple_05',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 60309,
                    Name = 'prop_phone_ing_03',
                    Placement = {
                        vector3(0.140000, 0.040000, 0.010000),
                        vector3(10.000000, 112.000000, -180.000000),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'lovepose10f',
            },
        },
    },
    {
        Label = 'Love Pose 10 NEW',
        Command = 'lovepose10f',
        Animation = 'f_couple_05_clip',
        Dictionary = 'anim@female_couple_05',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 60309,
                    Name = 'prop_phone_ing_03',
                    Placement = {
                        vector3(0.080000, 0.019000, 0.030000),
                        vector3(30.000000, 98.000000, -160.000000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose10m',
                Placement = {
                    vector3(0.000000, 0.900000, -0.300000),
                    vector3(-90.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 11 NEW',
        Command = 'lovepose11m',
        Animation = 'm_couple_06_clip',
        Dictionary = 'anim@male_couple_06',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose11f',
            },
        },
    },
    {
        Label = 'Love Pose 11 NEW',
        Command = 'lovepose11f',
        Animation = 'f_couple_06_clip',
        Dictionary = 'anim@female_couple_06',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose11m',
                Placement = {
                    vector3(0.000000, 0.620000, -0.140000),
                    vector3(-50.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 12 NEW',
        Command = 'lovepose12m',
        Animation = 'm_couple_07_clip',
        Dictionary = 'anim@male_couple_07',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose12f',
            },
        },
    },
    {
        Label = 'Love Pose 12 NEW',
        Command = 'lovepose12f',
        Animation = 'f_couple_07_clip',
        Dictionary = 'anim@female_couple_07',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 6286,
                    Name = 'prop_phone_ing_03',
                    Placement = {
                        vector3(0.120000, 0.016000, -0.034000),
                        vector3(0.000000, 90.000000, -180.000000),
                    },
                },
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose12m',
                Placement = {
                    vector3(0.000000, 0.720000, 0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 13 NEW',
        Command = 'lovepose13m',
        Animation = 'fm_couple2_m_clip',
        Dictionary = 'myu@fm_couple2_2',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose13f',
            },
        },
    },
    {
        Label = 'Love Pose 13 NEW',
        Command = 'lovepose13f',
        Animation = 'fm_couple2_f_clip',
        Dictionary = 'myu@fm_couple2_1',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose13m',
                Placement = {
                    vector3(0.560000, 0.100000, -0.150000),
                    vector3(0.000000, 0.000000, 95.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 14 NEW',
        Command = 'lovepose14m',
        Animation = 'm_engagement_clip',
        Dictionary = 'm_engagement@d3vilros3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose14f',
            },
        },
    },
    {
        Label = 'Love Pose 14 NEW',
        Command = 'lovepose14f',
        Animation = 'f_engagement_clip',
        Dictionary = 'f_engagement@d3vilros3',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose14m',
                Placement = {
                    vector3(-0.100000, 0.320000, 0.000000),
                    vector3(0.000000, 0.000000, 189.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 15 NEW',
        Command = 'lovepose15m',
        Animation = 'mx@couple6_2_a_clip',
        Dictionary = 'mx@couple6_2_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose15f',
            },
        },
    },
    {
        Label = 'Love Pose 15 NEW',
        Command = 'lovepose15f',
        Animation = 'mx@couple6_2_b_clip',
        Dictionary = 'mx@couple6_2_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose15m',
                Placement = {
                    vector3(-0.120000, 0.300000, -0.100000),
                    vector3(28.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 16 NEW',
        Command = 'lovepose16m',
        Animation = 'mx@couple6_3_a_clip',
        Dictionary = 'mx@couple6_3_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose16f',
            },
        },
    },
    {
        Label = 'Love Pose 16 NEW',
        Command = 'lovepose16f',
        Animation = 'mx@couple6_3_b_clip',
        Dictionary = 'mx@couple6_3_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose16m',
                Placement = {
                    vector3(0.520000, 0.250000, 0.050000),
                    vector3(13.500000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 17 NEW',
        Command = 'lovepose17m',
        Animation = 'mx@pack4.1_a_clip',
        Dictionary = 'mx@pack4.1_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose17f',
            },
        },
    },
    {
        Label = 'Love Pose 17 NEW',
        Command = 'lovepose17f',
        Animation = 'mx@pack4.1_b_clip',
        Dictionary = 'mx@pack4.1_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose17m',
                Placement = {
                    vector3(0.520000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 18 NEW',
        Command = 'lovepose18m',
        Animation = 'mx@couple4.2_a_clip',
        Dictionary = 'mx@couple4.2_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose18f',
            },
        },
    },
    {
        Label = 'Love Pose 18 NEW',
        Command = 'lovepose18f',
        Animation = 'mx@couple4.2_b_clip',
        Dictionary = 'mx@couple4.2_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose18m',
                Placement = {
                    vector3(0.000000, 0.310000, -0.020000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 19 NEW',
        Command = 'lovepose19m',
        Animation = 'mx@couple4.3_a_clip',
        Dictionary = 'mx@couple4.3_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose19f',
            },
        },
    },
    {
        Label = 'Love Pose 19 NEW',
        Command = 'lovepose19f',
        Animation = 'mx@couple4.3_b_clip',
        Dictionary = 'mx@couple4.3_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose19m',
                Placement = {
                    vector3(0.480000, 0.020000, -0.020000),
                    vector3(0.000000, 0.000000, 152.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 20 NEW',
        Command = 'lovepose20m',
        Animation = 'mx@couple4.4_a_clip',
        Dictionary = 'mx@couple4.4_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose20f',
            },
        },
    },
    {
        Label = 'Love Pose 20 NEW',
        Command = 'lovepose20f',
        Animation = 'mx@couple4.4_b_clip',
        Dictionary = 'mx@couple4.4_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose20m',
                Placement = {
                    vector3(0.000000, 1.470000, 0.700000),
                    vector3(0.100000, 0.500000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 21 NEW',
        Command = 'lovepose21m',
        Animation = 'mx@couple4.5_a_clip',
        Dictionary = 'mx@couple4.5_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose21f',
            },
        },
    },
    {
        Label = 'Love Pose 21 NEW',
        Command = 'lovepose21f',
        Animation = 'mx@couple4.5_b_clip',
        Dictionary = 'mx@couple4.5_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose21m',
                Placement = {
                    vector3(0.000000, 0.300000, 0.160000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Love Pose 21 NEW',
        Command = 'lovepose22m',
        Animation = 'couplemale_leancar_clip',
        Dictionary = 'couplemale_leancar@joker',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'lovepose22f',
            },
        },
    },
    {
        Label = 'Love Pose 21 NEW',
        Command = 'lovepose22f',
        Animation = 'couplefemale_leancar_clip',
        Dictionary = 'couplefemale_leancar@joker',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'lovepose22m',
                Placement = {
                    vector3(-0.200000, 0.320000, 0.100000),
                    vector3(0.000000, 0.000000, 180.000000),
                },
            },
        },
    },
    {
        Label = 'Propose 001a',
        Command = 'propose001a',
        Animation = 'propose_001a',
        Dictionary = 'dollie_mods@propose_001a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'propose001b',
            },
        },
    },
    {
        Label = 'Propose 001b',
        Command = 'propose001b',
        Animation = 'propose_001b',
        Dictionary = 'dollie_mods@propose_001b',
        Options = {
            Flags = {
                Loop = true,
            },
            Props = {
                {
                    Bone = 64064,
                    Name = 'pata_freevalentinesday',
                    Placement = {
                        vector3(-0.010000, 0.250000, -0.100000),
                        vector3(-49.000000, 50.437300, 20.000000),
                    },
                },
            },
            Shared = {
                OtherAnimation = 'propose001a',
            },
        },
    },
    {
        Label = 'Carry Me Cute',
        Command = 'carrymecute',
        Animation = 'amnilka_couple_mal_002',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'carrymecute2',
            },
        },
    },
    {
        Label = 'Carry Me Cute 2',
        Command = 'carrymecute2',
        Animation = 'amnilka_couple_fem_002',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'carrymecute',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Shoulder Covering Eyes',
        Command = 'pcarrya1',
        Animation = 'pcarrya1clip',
        Dictionary = 'pcarrya1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarrya2',
            },
        },
    },
    {
        Label = 'PCarry 2 Shoulder Covering Eyes',
        Command = 'pcarrya2',
        Animation = 'pcarrya2clip',
        Dictionary = 'pcarrya2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarrya1',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Struggle Behind',
        Command = 'pcarryb1',
        Animation = 'pcarryb1clip',
        Dictionary = 'pcarryb1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryb2',
            },
        },
    },
    {
        Label = 'PCarry 2 Struggle Behind',
        Command = 'pcarryb2',
        Animation = 'pcarryb2clip',
        Dictionary = 'pcarryb2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryb1',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Dead Behind',
        Command = 'pcarryc1',
        Animation = 'pcarryc1clip',
        Dictionary = 'pcarryc1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryc2',
            },
        },
    },
    {
        Label = 'PCarry 2 Dead Behind',
        Command = 'pcarryc2',
        Animation = 'pcarryc2clip',
        Dictionary = 'pcarryc2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryc1',
                Placement = {
                    vector3(-0.360000, 0.000000, -0.020000),
                    vector3(0.000000, 0.000000, -10.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Firemans Shoulder',
        Command = 'pcarryd1',
        Animation = 'pcarryd1clip',
        Dictionary = 'pcarryd1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryd2',
            },
        },
    },
    {
        Label = 'PCarry 2 Firemans Shoulder',
        Command = 'pcarryd2',
        Animation = 'pcarryd2clip',
        Dictionary = 'pcarryd2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryd1',
                Placement = {
                    vector3(-0.120000, -0.150000, -0.050000),
                    vector3(0.000000, 0.000000, -3.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Standing Shoulder',
        Command = 'pcarrye1',
        Animation = 'pcarrye1clip',
        Dictionary = 'pcarrye1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarrye2',
            },
        },
    },
    {
        Label = 'PCarry 2 Standing Shoulder',
        Command = 'pcarrye2',
        Animation = 'pcarrye2clip',
        Dictionary = 'pcarrye2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarrye1',
                Placement = {
                    vector3(1.230000, 0.020000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Meditation Feet On Head',
        Command = 'pcarryf1',
        Animation = 'pcarryf1clip',
        Dictionary = 'pcarryf1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryf2',
            },
        },
    },
    {
        Label = 'PCarry 2 Meditation Feet On Head',
        Command = 'pcarryf2',
        Animation = 'pcarryf2clip',
        Dictionary = 'pcarryf2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryf1',
                Placement = {
                    vector3(1.230000, 0.020000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Superman',
        Command = 'pcarryg1',
        Animation = 'pcarryg1clip',
        Dictionary = 'pcarryg1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryg2',
            },
        },
    },
    {
        Label = 'PCarry 2 Superman',
        Command = 'pcarryg2',
        Animation = 'pcarryg2clip',
        Dictionary = 'pcarryg2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryg1',
                Placement = {
                    vector3(0.850000, -0.120000, -0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Shoulder Back',
        Command = 'pcarryh1',
        Animation = 'pcarryh1clip',
        Dictionary = 'pcarryh1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryh2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Shoulder Back',
        Command = 'pcarryh2',
        Animation = 'pcarryh2clip',
        Dictionary = 'pcarryh2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryh1',
                Placement = {
                    vector3(-0.130000, -0.130000, -0.050000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Bird',
        Command = 'pcarryi1',
        Animation = 'pcarryi1clip',
        Dictionary = 'pcarryi1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryi2',
            },
        },
    },
    {
        Label = 'PCarry 2 Bird',
        Command = 'pcarryi2',
        Animation = 'pcarryi2clip',
        Dictionary = 'pcarryi2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryi1',
                Placement = {
                    vector3(0.700000, -0.330000, 0.000000),
                    vector3(0.000000, 0.000000, -15.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Woohoo',
        Command = 'pcarryj1',
        Animation = 'pcarryj1clip',
        Dictionary = 'pcarryj1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryj2',
            },
        },
    },
    {
        Label = 'PCarry 2 Woohoo',
        Command = 'pcarryj2',
        Animation = 'pcarryj2clip',
        Dictionary = 'pcarryj2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryj1',
                Placement = {
                    vector3(0.350000, -0.490000, 0.000000),
                    vector3(0.000000, 0.000000, -30.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Sad Curl Up',
        Command = 'pcarryk1',
        Animation = 'pcarryk1clip',
        Dictionary = 'pcarryk1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryk2',
            },
        },
    },
    {
        Label = 'PCarry 2 Sad Curl Up',
        Command = 'pcarryk2',
        Animation = 'pcarryk2clip',
        Dictionary = 'pcarryk2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryk1',
                Placement = {
                    vector3(0.060000, 0.100000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Sad Front',
        Command = 'pcarryl1',
        Animation = 'pcarryl1clip',
        Dictionary = 'pcarryl1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryl2',
            },
        },
    },
    {
        Label = 'PCarry 2 Sad Front',
        Command = 'pcarryl2',
        Animation = 'pcarryl2clip',
        Dictionary = 'pcarryl2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryl1',
                Placement = {
                    vector3(0.050000, 0.070000, 0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Standing Upside Down',
        Command = 'pcarrym1',
        Animation = 'pcarrym1clip',
        Dictionary = 'pcarrym1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarrym2',
            },
        },
    },
    {
        Label = 'PCarry 2 Standing Upside Down',
        Command = 'pcarrym2',
        Animation = 'pcarrym2clip',
        Dictionary = 'pcarrym2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarrym1',
                Placement = {
                    vector3(1.820000, 0.150000, -0.020000),
                    vector3(0.000000, 0.000000, 5.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Salute',
        Command = 'pcarryn1',
        Animation = 'pcarryn1clip',
        Dictionary = 'pcarryn1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryn2',
            },
        },
    },
    {
        Label = 'PCarry 2 Salute',
        Command = 'pcarryn2',
        Animation = 'pcarryn2clip',
        Dictionary = 'pcarryn2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryn1',
                Placement = {
                    vector3(1.230000, 0.020000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Arrogant',
        Command = 'pcarryo1',
        Animation = 'pcarryo1clip',
        Dictionary = 'pcarryo1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryo2',
            },
        },
    },
    {
        Label = 'PCarry 2 Arrogant',
        Command = 'pcarryo2',
        Animation = 'pcarryo2clip',
        Dictionary = 'pcarryo2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryo1',
                Placement = {
                    vector3(0.550000, 0.010000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Dab',
        Command = 'pcarryp1',
        Animation = 'pcarryp1clip',
        Dictionary = 'pcarryp1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryp2',
            },
        },
    },
    {
        Label = 'PCarry 2 Dab',
        Command = 'pcarryp2',
        Animation = 'pcarryp2clip',
        Dictionary = 'pcarryp2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryp1',
                Placement = {
                    vector3(0.550000, 0.010000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Bull Meditation',
        Command = 'pcarryq1',
        Animation = 'pcarryq1clip',
        Dictionary = 'pcarryq1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryq2',
            },
        },
    },
    {
        Label = 'PCarry 2 Bull Meditation',
        Command = 'pcarryq2',
        Animation = 'pcarryq2clip',
        Dictionary = 'pcarryq2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryq1',
                Placement = {
                    vector3(-0.200000, -0.500000, 0.000000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Shy Shoulder',
        Command = 'pcarryr1',
        Animation = 'pcarryr1clip',
        Dictionary = 'pcarryr1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryr2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Shy Shoulder',
        Command = 'pcarryr2',
        Animation = 'pcarryr2clip',
        Dictionary = 'pcarryr2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryr1',
                Placement = {
                    vector3(-0.070000, -0.100000, -0.280000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 2 Sleep Over Head',
        Command = 'pcarrys1',
        Animation = 'pcarrys1clip',
        Dictionary = 'pcarrys1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarrys2',
            },
        },
    },
    {
        Label = 'PCarry 2 Sleep Over Head',
        Command = 'pcarrys2',
        Animation = 'pcarrys2clip',
        Dictionary = 'pcarrys2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarrys1',
                Placement = {
                    vector3(0.880000, 0.000000, -0.080000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Riding Motorcycle',
        Command = 'pcarryt1',
        Animation = 'pcarryt1clip',
        Dictionary = 'pcarryt1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryt2',
            },
        },
    },
    {
        Label = 'PCarry 2 Riding Motorcycle',
        Command = 'pcarryt2',
        Animation = 'pcarryt2clip',
        Dictionary = 'pcarryt2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryt1',
                Placement = {
                    vector3(0.520000, 0.030000, -0.010000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Sit Shoulder',
        Command = 'pcarryu1',
        Animation = 'pcarryu1clip',
        Dictionary = 'pcarryu1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryu2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Sit Shoulder',
        Command = 'pcarryu2',
        Animation = 'pcarryu2clip',
        Dictionary = 'pcarryu2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryu1',
                Placement = {
                    vector3(0.290000, 0.040000, -0.220000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Pull Head Back',
        Command = 'pcarryv1',
        Animation = 'pcarryv1clip',
        Dictionary = 'pcarryv1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryv2',
            },
        },
    },
    {
        Label = 'PCarry 2 Pull Head Back',
        Command = 'pcarryv2',
        Animation = 'pcarryv2clip',
        Dictionary = 'pcarryv2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryv1',
                Placement = {
                    vector3(-0.340000, -0.180000, 0.150000),
                    vector3(0.000000, 0.000000, 50.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Disgusting',
        Command = 'pcarryw1',
        Animation = 'pcarryw1clip',
        Dictionary = 'pcarryw1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryw2',
            },
        },
    },
    {
        Label = 'PCarry 2 Disgusting',
        Command = 'pcarryw2',
        Animation = 'pcarryw2clip',
        Dictionary = 'pcarryw2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 28422,
                OtherAnimation = 'pcarryw1',
                Placement = {
                    vector3(0.000000, -0.140000, -0.410000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Caught',
        Command = 'pcarryx1',
        Animation = 'pcarryx1clip',
        Dictionary = 'pcarryx1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryx2',
            },
        },
    },
    {
        Label = 'PCarry 2 Caught',
        Command = 'pcarryx2',
        Animation = 'pcarryx2clip',
        Dictionary = 'pcarryx2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 28422,
                OtherAnimation = 'pcarryx1',
                Placement = {
                    vector3(0.250000, -0.200000, 0.130000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Torture',
        Command = 'pcarryy1',
        Animation = 'pcarryy1clip',
        Dictionary = 'pcarryy1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryy2',
            },
        },
    },
    {
        Label = 'PCarry 2 Torture',
        Command = 'pcarryy2',
        Animation = 'pcarryy2clip',
        Dictionary = 'pcarryy2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 28422,
                OtherAnimation = 'pcarryy1',
                Placement = {
                    vector3(0.240000, -0.560000, 0.750000),
                    vector3(0.000000, 0.000000, -160.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Bazoka',
        Command = 'pcarryz1',
        Animation = 'pcarryz1clip',
        Dictionary = 'pcarryz1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryz2',
            },
        },
    },
    {
        Label = 'PCarry 2 Bazoka',
        Command = 'pcarryz2',
        Animation = 'pcarryz2clip',
        Dictionary = 'pcarryz2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 57005,
                OtherAnimation = 'pcarryz1',
                Placement = {
                    vector3(0.020000, 0.190000, -0.220000),
                    vector3(0.000000, 0.000000, -79.999000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Drunk Behind',
        Command = 'pcarryza1',
        Animation = 'pcarryza1clip',
        Dictionary = 'pcarryza1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryza2',
            },
        },
    },
    {
        Label = 'PCarry 2 Drunk Behind',
        Command = 'pcarryza2',
        Animation = 'pcarryza2clip',
        Dictionary = 'pcarryza2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryza1',
                Placement = {
                    vector3(-0.560000, 0.030000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Peek High',
        Command = 'pcarryzb1',
        Animation = 'pcarryzb1clip',
        Dictionary = 'pcarryzb1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzb2',
            },
        },
    },
    {
        Label = 'PCarry 2 Peek High',
        Command = 'pcarryzb2',
        Animation = 'pcarryzb2clip',
        Dictionary = 'pcarryzb2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzb1',
                Placement = {
                    vector3(1.943000, -0.010000, -0.024000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Meditation Master',
        Command = 'pcarryzc1',
        Animation = 'pcarryzc1clip',
        Dictionary = 'pcarryzc1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzc2',
            },
        },
    },
    {
        Label = 'PCarry 2 Meditation Master',
        Command = 'pcarryzc2',
        Animation = 'pcarryzc2clip',
        Dictionary = 'pcarryzc2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzc1',
                Placement = {
                    vector3(1.160000, 0.020000, -0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Strongman',
        Command = 'pcarryzd1',
        Animation = 'pcarryzd1clip',
        Dictionary = 'pcarryzd1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzd2',
            },
        },
    },
    {
        Label = 'PCarry 2 Strongman',
        Command = 'pcarryzd2',
        Animation = 'pcarryzd2clip',
        Dictionary = 'pcarryzd2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzd1',
                Placement = {
                    vector3(0.590000, 0.010000, -0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Piggyback',
        Command = 'pcarryze1',
        Animation = 'pcarryze1clip',
        Dictionary = 'pcarryze1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryze2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Piggyback',
        Command = 'pcarryze2',
        Animation = 'pcarryze2clip',
        Dictionary = 'pcarryze2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryze1',
                Placement = {
                    vector3(0.180000, -0.020000, -0.020000),
                    vector3(0.000000, 0.000000, -10.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Piggyback Run',
        Command = 'pcarryzf1',
        Animation = 'pcarryzf1clip',
        Dictionary = 'pcarryzf1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzf2',
            },
        },
    },
    {
        Label = 'PCarry 2 Piggyback Run',
        Command = 'pcarryzf2',
        Animation = 'pcarryzf2clip',
        Dictionary = 'pcarryzf2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzf1',
                Placement = {
                    vector3(-0.210000, -0.270000, -0.020000),
                    vector3(0.000000, 0.000000, -90.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Pulling Hands Back',
        Command = 'pcarryzg1',
        Animation = 'pcarryzg1clip',
        Dictionary = 'pcarryzg1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzg2',
            },
        },
    },
    {
        Label = 'PCarry 2 Pulling Hands Back',
        Command = 'pcarryzg2',
        Animation = 'pcarryzg2clip',
        Dictionary = 'pcarryzg2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzg1',
                Placement = {
                    vector3(-0.150000, -0.670000, -0.010000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Pole',
        Command = 'pcarryzh1',
        Animation = 'pcarryzh1clip',
        Dictionary = 'pcarryzh1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzh2',
            },
        },
    },
    {
        Label = 'PCarry 2 Pole',
        Command = 'pcarryzh2',
        Animation = 'pcarryzh2clip',
        Dictionary = 'pcarryzh2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzh1',
                Placement = {
                    vector3(-0.110000, 0.120000, -0.270000),
                    vector3(0.000000, 0.000000, -10.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Front',
        Command = 'pcarryzi1',
        Animation = 'pcarryzi1clip',
        Dictionary = 'pcarryzi1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzi2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Front',
        Command = 'pcarryzi2',
        Animation = 'pcarryzi2clip',
        Dictionary = 'pcarryzi2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzi1',
                Placement = {
                    vector3(0.100000, 0.250000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Caress Head',
        Command = 'pcarryzj1',
        Animation = 'pcarryzj1clip',
        Dictionary = 'pcarryzj1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzj2',
            },
        },
    },
    {
        Label = 'PCarry 2 Caress Head',
        Command = 'pcarryzj2',
        Animation = 'pcarryzj2clip',
        Dictionary = 'pcarryzj2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzj1',
                Placement = {
                    vector3(0.270000, 0.010000, -0.060000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Scared',
        Command = 'pcarryzk1',
        Animation = 'pcarryzk1clip',
        Dictionary = 'pcarryzk1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzk2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Scared',
        Command = 'pcarryzk2',
        Animation = 'pcarryzk2clip',
        Dictionary = 'pcarryzk2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzk1',
                Placement = {
                    vector3(-0.200000, 0.010000, 0.100000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Bag',
        Command = 'pcarryzl1',
        Animation = 'pcarryzl1clip',
        Dictionary = 'pcarryzl1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzl2',
            },
        },
    },
    {
        Label = 'PCarry 2 Bag',
        Command = 'pcarryzl2',
        Animation = 'pcarryzl2clip',
        Dictionary = 'pcarryzl2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzl1',
                Placement = {
                    vector3(0.040000, 0.060000, -0.030000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Bag Flip',
        Command = 'pcarryzm1',
        Animation = 'pcarryzm1clip',
        Dictionary = 'pcarryzm1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzm2',
            },
        },
    },
    {
        Label = 'PCarry 2 Bag Flip',
        Command = 'pcarryzm2',
        Animation = 'pcarryzm2clip',
        Dictionary = 'pcarryzm2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzm1',
                Placement = {
                    vector3(-0.120000, 0.050000, -0.020000),
                    vector3(0.000000, 0.000000, -15.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Hug Back Flip',
        Command = 'pcarryzn1',
        Animation = 'pcarryzn1clip',
        Dictionary = 'pcarryzn1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzn2',
            },
        },
    },
    {
        Label = 'PCarry 2 Hug Back Flip',
        Command = 'pcarryzn2',
        Animation = 'pcarryzn2clip',
        Dictionary = 'pcarryzn2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzn1',
                Placement = {
                    vector3(-0.210000, 0.050000, -0.020000),
                    vector3(0.000000, 0.000000, -15.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Sit & Wave Over Head',
        Command = 'pcarryzo1',
        Animation = 'pcarryzo1clip',
        Dictionary = 'pcarryzo1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzo2',
            },
        },
    },
    {
        Label = 'PCarry 2 Sit & Wave Over Head',
        Command = 'pcarryzo2',
        Animation = 'pcarryzo2clip',
        Dictionary = 'pcarryzo2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzo1',
                Placement = {
                    vector3(1.190000, -0.020000, -0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Cute Punch Head',
        Command = 'pcarryzp1',
        Animation = 'pcarryzp1clip',
        Dictionary = 'pcarryzp1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzp2',
            },
        },
    },
    {
        Label = 'PCarry 2 Cute Punch Head',
        Command = 'pcarryzp2',
        Animation = 'pcarryzp2clip',
        Dictionary = 'pcarryzp2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzp1',
                Placement = {
                    vector3(0.450000, -0.160000, -0.030000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Superhero',
        Command = 'pcarryzq1',
        Animation = 'pcarryzq1clip',
        Dictionary = 'pcarryzq1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzq2',
            },
        },
    },
    {
        Label = 'PCarry 2 Superhero',
        Command = 'pcarryzq2',
        Animation = 'pcarryzq2clip',
        Dictionary = 'pcarryzq2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzq1',
                Placement = {
                    vector3(0.270000, 0.540000, -0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Shoulder Leg Cross Head',
        Command = 'pcarryzr1',
        Animation = 'pcarryzr1clip',
        Dictionary = 'pcarryzr1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzr2',
            },
        },
    },
    {
        Label = 'PCarry 2 Shoulder Leg Cross Head',
        Command = 'pcarryzr2',
        Animation = 'pcarryzr2clip',
        Dictionary = 'pcarryzr2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzr1',
                Placement = {
                    vector3(0.600000, -0.090000, 0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Can\'t Breath',
        Command = 'pcarryzs1',
        Animation = 'pcarryzs1clip',
        Dictionary = 'pcarryzs1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzs2',
            },
        },
    },
    {
        Label = 'PCarry 2 Can\'t Breath',
        Command = 'pcarryzs2',
        Animation = 'pcarryzs2clip',
        Dictionary = 'pcarryzs2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzs1',
                Placement = {
                    vector3(-0.030000, -0.180000, 0.020000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Firemans Back',
        Command = 'pcarryzt1',
        Animation = 'pcarryzt1clip',
        Dictionary = 'pcarryzt1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzt2',
            },
        },
    },
    {
        Label = 'PCarry 2 Firemans Back',
        Command = 'pcarryzt2',
        Animation = 'pcarryzt2clip',
        Dictionary = 'pcarryzt2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzt1',
                Placement = {
                    vector3(-0.330000, 0.000000, -0.040000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Happy Behind',
        Command = 'pcarryzu1',
        Animation = 'pcarryzu1clip',
        Dictionary = 'pcarryzu1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzu2',
            },
        },
    },
    {
        Label = 'PCarry 2 Happy Behind',
        Command = 'pcarryzu2',
        Animation = 'pcarryzu2clip',
        Dictionary = 'pcarryzu2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzu1',
                Placement = {
                    vector3(-0.290000, -0.300000, -0.020000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Happy Swing',
        Command = 'pcarryzv1',
        Animation = 'pcarryzv1clip',
        Dictionary = 'pcarryzv1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzv2',
            },
        },
    },
    {
        Label = 'PCarry 2 Happy Swing',
        Command = 'pcarryzv2',
        Animation = 'pcarryzv2clip',
        Dictionary = 'pcarryzv2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzv1',
                Placement = {
                    vector3(-0.040000, -0.720000, -0.600000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Piggyback Head',
        Command = 'pcarryzw1',
        Animation = 'pcarryzw1clip',
        Dictionary = 'pcarryzw1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzw2',
            },
        },
    },
    {
        Label = 'PCarry 2 Piggyback Head',
        Command = 'pcarryzw2',
        Animation = 'pcarryzw2clip',
        Dictionary = 'pcarryzw2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzw1',
                Placement = {
                    vector3(0.320000, -0.220000, -0.020000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Pose Over Head',
        Command = 'pcarryzx1',
        Animation = 'pcarryzx1clip',
        Dictionary = 'pcarryzx1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzx2',
            },
        },
    },
    {
        Label = 'PCarry 2 Pose Over Head',
        Command = 'pcarryzx2',
        Animation = 'pcarryzx2clip',
        Dictionary = 'pcarryzx2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzx1',
                Placement = {
                    vector3(0.430000, -0.860000, 0.000000),
                    vector3(0.000000, 0.000000, -80.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Piggyback Hold Head',
        Command = 'pcarryzy1',
        Animation = 'pcarryzy1clip',
        Dictionary = 'pcarryzy1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzy2',
            },
        },
    },
    {
        Label = 'PCarry 2 Piggyback Hold Head',
        Command = 'pcarryzy2',
        Animation = 'pcarryzy2clip',
        Dictionary = 'pcarryzy2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzy1',
                Placement = {
                    vector3(0.060000, -0.070000, -0.020000),
                    vector3(0.000000, 0.000000, -20.000000),
                },
            },
        },
    },
    {
        Label = 'PCarry 1 Heart Power',
        Command = 'pcarryzz1',
        Animation = 'pcarryzz1clip',
        Dictionary = 'pcarryzz1@animations',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'pcarryzz2',
            },
        },
    },
    {
        Label = 'PCarry 2 Heart Power',
        Command = 'pcarryzz2',
        Animation = 'pcarryzz2clip',
        Dictionary = 'pcarryzz2@animations',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'pcarryzz1',
                Placement = {
                    vector3(1.110000, 0.210000, -0.780000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'BFF Pose',
        Command = 'bff',
        Animation = 'm_couple_03_b_clip',
        Dictionary = 'anim@male_couple_03_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'bffb',
            },
        },
    },
    {
        Label = 'BFF Pose 2',
        Command = 'bffb',
        Animation = 'f_couple_03_b_clip',
        Dictionary = 'anim@female_couple_03_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'bff',
                Placement = {
                    vector3(0.010000, 0.130000, 0.000000),
                    vector3(0.000000, 0.000000, 76.000000),
                },
            },
        },
    },
    {
        Label = 'Sit With Me',
        Command = 'sitwithmepose',
        Animation = 'amnilka_couple_mal_003',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'sitwithmepose2',
            },
        },
    },
    {
        Label = 'Sit With Me Please?',
        Command = 'sitwithmepose2',
        Animation = 'amnilka_couple_fem_003',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'sitwithmepose',
                Placement = {
                    vector3(0.354000, 0.511000, 0.831000),
                    vector3(0.000000, 0.000000, -2.800000),
                },
            },
        },
    },
    {
        Label = 'Hug Pose',
        Command = 'hugpose',
        Animation = 'amnilka_couple_mal_001',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'hugpose2',
            },
        },
    },
    {
        Label = 'Hug Pose With Me?',
        Command = 'hugpose2',
        Animation = 'amnilka_couple_fem_001',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'hugpose',
                Placement = {
                    vector3(0.140000, 0.250000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Cute Pic Pose',
        Command = 'cutepicpose',
        Animation = 'amnilka_couple_mal_004',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'cutepicpose2',
            },
        },
    },
    {
        Label = 'Cute Pic Pose 2',
        Command = 'cutepicpose2',
        Animation = 'amnilka_couple_fem_004',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'cutepicpose',
                Placement = {
                    vector3(0.270000, 0.120000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Couple Heart Hands',
        Command = 'couplehhands',
        Animation = 'amnilka_couple_mal_005',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'couplehhands2',
            },
        },
    },
    {
        Label = 'Couple Heart Hands 2',
        Command = 'couplehhands2',
        Animation = 'amnilka_couple_fem_005',
        Dictionary = 'amnilka@photopose@couple@couplefirst',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'couplehhands',
                Placement = {
                    vector3(-0.123000, 0.474000, 0.000000),
                    vector3(0.000000, 0.000000, 94.000000),
                },
            },
        },
    },
    {
        Label = 'Couple Wedding Pose 1A',
        Command = 'couplewed1a',
        Animation = 'wedding1a',
        Dictionary = 'EnchantedBrwny@wedding1a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'couplewed1b',
            },
        },
    },
    {
        Label = 'Couple Wedding Pose 1B',
        Command = 'couplewed1b',
        Animation = 'wedding1b',
        Dictionary = 'EnchantedBrwny@wedding1b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'couplewed1a',
                Placement = {
                    vector3(0.030000, 1.000000, 0.020000),
                    vector3(0.000000, 0.000000, 130.000000),
                },
            },
        },
    },
    {
        Label = 'Couple Wedding Pose 2A',
        Command = 'couplewed2a',
        Animation = 'wedding2b',
        Dictionary = 'EnchantedBrwny@wedding2b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'couplewed2b',
            },
        },
    },
    {
        Label = 'Couple Wedding Pose 2B',
        Command = 'couplewed2b',
        Animation = 'wedding2a',
        Dictionary = 'EnchantedBrwny@wedding2a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'couplewed2a',
                Placement = {
                    vector3(0.010000, 0.250000, 0.000000),
                    vector3(0.000000, 0.000000, -88.900000),
                },
            },
        },
    },
    {
        Label = 'Carry Small Dog 2',
        Command = 'csdog3',
        Animation = 'base',
        Dictionary = 'hooman@hugging_little_doggy',
        Options = {
            Flags = {
                Loop = true,
                Move = true,
            },
            Shared = {
                OtherAnimation = 'csdog4',
            },
        },
    },
    {
        Label = 'Small Dog Carried 2',
        Command = 'csdog4',
        Animation = 'base',
        Dictionary = 'little_doggy@hugging_hooman',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 24818,
                OtherAnimation = 'csdog3',
                Placement = {
                    vector3(-0.950000, 0.160000, -0.150000),
                    vector3(3.700000, 75.000000, -161.900000),
                },
            },
        },
    },
    {
        Label = 'Kiss Cute - Neck (Male)',
        Command = 'kisscuteneck',
        Animation = 'kissmale8',
        Dictionary = 'genesismods_kissme@kissmale8',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kisscuteneck2',
                Placement = {
                    vector3(-0.560000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss Cute - Neck (Female)',
        Command = 'kisscuteneck2',
        Animation = 'kissfemale8',
        Dictionary = 'genesismods_kissme@kissfemale8',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kisscuteneck',
            },
        },
    },
    {
        Label = 'Kiss Cute Cheek (Male)',
        Command = 'kisscutecheek',
        Animation = 'kissmale9',
        Dictionary = 'genesismods_kissme@kissmale9',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kisscutecheek2',
                Placement = {
                    vector3(0.350000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss Cute Cheek (Female)',
        Command = 'kisscutecheek2',
        Animation = 'kissfemale9',
        Dictionary = 'genesismods_kissme@kissfemale9',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kisscutecheek',
            },
        },
    },
    {
        Label = 'Kiss Forehead (Male)',
        Command = 'kisscutefh',
        Animation = 'kissmale10',
        Dictionary = 'genesismods_kissme@kissmale10',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'kisscutefh2',
                Placement = {
                    vector3(0.380000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss Cute Lips (Female)',
        Command = 'kisslips',
        Animation = 'couple13_clip',
        Dictionary = 'chocoholic@couple13',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'kisslips2',
                Placement = {
                    vector3(0.160000, 0.270000, 0.000000),
                    vector3(0.000000, 0.000000, 130.000000),
                },
            },
        },
    },
    {
        Label = 'Kiss Cute Lips (Male)',
        Command = 'kisslips2',
        Animation = 'couple14_clip',
        Dictionary = 'chocoholic@couple14',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kisslips',
            },
        },
    },
    {
        Label = 'Kiss Forehead (Female)',
        Command = 'kisscutefh2',
        Animation = 'kissfemale10',
        Dictionary = 'genesismods_kissme@kissfemale10',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'kisscutefh',
            },
        },
    },
    {
        Label = 'Hold Me',
        Command = 'holdme',
        Animation = 'mx_couple5_1_a_clip',
        Dictionary = 'mx_couple5_1_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'holdmeb',
            },
        },
    },
    {
        Label = 'Be Held',
        Command = 'holdmeb',
        Animation = 'mx_couple5_1_b_clip',
        Dictionary = 'mx_couple5_1_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'holdme',
                Placement = {
                    vector3(-0.020000, 0.240000, -0.010000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Hold Me 2',
        Command = 'holdmec',
        Animation = 'mx_couple5_2_a_clip',
        Dictionary = 'mx_couple5_2_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'holdmed',
            },
        },
    },
    {
        Label = 'Be Held 2',
        Command = 'holdmed',
        Animation = 'mx_couple5_2_b_clip',
        Dictionary = 'mx_couple5_2_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'holdmec',
                Placement = {
                    vector3(-0.120000, 0.360000, -0.010000),
                    vector3(0.000000, 0.000000, -180.000000),
                },
            },
        },
    },
    {
        Label = 'Hold Me 3',
        Command = 'holdmee',
        Animation = 'mx_couple5_3_a_clip',
        Dictionary = 'mx_couple5_3_a',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'holdmef',
            },
        },
    },
    {
        Label = 'Be Held 3',
        Command = 'holdmef',
        Animation = 'mx_couple5_3_b_clip',
        Dictionary = 'mx_couple5_3_b',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                Bone = 0,
                OtherAnimation = 'holdmee',
                Placement = {
                    vector3(0.040000, 0.210000, -0.030000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Rhythm 1 [F]',
        Command = 'wc_rhythm_01a',
        Animation = 'pandora01_f',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'wc_rhythm_01a',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Rhythm 1 [M]',
        Command = 'wc_rhythm_01b',
        Animation = 'pandora01_m',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'wc_rhythm_01b',
            },
        },
    },
    {
        Label = 'Rhythm 2 [F]',
        Command = 'wc_rhythm_02a',
        Animation = 'pandora02_f',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'wc_rhythm_02a',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Rhythm 2 [M]',
        Command = 'wc_rhythm_02b',
        Animation = 'pandora02_m',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'wc_rhythm_02b',
            },
        },
    },
    {
        Label = 'Rhythm 4 [F]',
        Command = 'wc_rhythm_04a',
        Animation = 'pandora04_f',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                Attach = true,
                OtherAnimation = 'wc_rhythm_04a',
                Placement = {
                    vector3(0.000000, 0.000000, 0.000000),
                    vector3(0.000000, 0.000000, 0.000000),
                },
            },
        },
    },
    {
        Label = 'Rhythm 4 [M]',
        Command = 'wc_rhythm_04b',
        Animation = 'pandora04_m',
        Dictionary = 'whitecustom@rhythm',
        Options = {
            Flags = {
                Loop = true,
            },
            Shared = {
                OtherAnimation = 'wc_rhythm_04b',
            },
        },
    },
}
