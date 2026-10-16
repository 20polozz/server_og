-- Place any of your custom animations in here and keep a backup of this file for future updates.
return {
    Walks = {},
    Scenarios = {},
    Expressions = {},
    Emotes = {
        {
            Label = 'Yoga en el río',
            Command = 'yoga',
            Animation = 'mrwitt',
            Dictionary = 'mrwitt@yoga_am_flussufer_f',
            Nuevo = true,
            Options = {
                Flags = { Loop = true }
            }
        },
        {
            Label = 'Brazo estirado',
            Command = 'higharm',
            Animation = 'mrwitt',
            Dictionary = 'mrwitt@extended_arm_height_f',
            Nuevo = true,
            Options = {
                Flags = { Loop = true }
            }
        },
        {
            Label = 'Salto al aire',
            Command = 'leap',
            Animation = 'mrwitt',
            Dictionary = 'mrwitt@female_leap_flight_f',
            Nuevo = true,
            Options = {
                Flags = { Loop = true }
            }
        },
        {
            Label = 'Chica cantando',
            Command = 'singing',
            Animation = 'mrwitt',
            Dictionary = 'mrwitt@singing_girl_f',
            Nuevo = true,
            Options = {
                Flags = { Loop = true }
            }
        },
        {
            Label = 'Mujer en el banco',
            Command = 'benchsit',
            Animation = 'mrwitt',
            Dictionary = 'mrwitt@woman_on_park_bench_f',
            Nuevo = true,
            Options = {
                Flags = { Loop = true }
            }
        },
    },
    PropEmotes = {
    },
    ConsumableEmotes = {},
    DanceEmotes = {},
    SynchronizedEmotes = {
            {
                Label = 'Foto Filtrada',
                Command = 'leakedphoto',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@leaked_picture_scene_m',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'leakedphoto2',
                    },
                },
                
            },
            {
                Label = 'Foto Filtrada (Acompañante)',
                Command = 'leakedphoto2',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@leaked_picture_scene_f',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'leakedphoto',
                        Placement = {
                            vector3(0.180000, 0.180000, 0.000000),
                            vector3(0.000000, 0.000000, 0.000000),
                        },
                    },
                },
            },
            {
                Label = 'Momento Casco',
                Command = 'helmetmoment',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@beautiful_helmet_moment_m',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'helmetmoment2',
                    },
                },
                
            },
            {
                Label = 'Momento Casco (Acompañante)',
                Command = 'helmetmoment2',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@beautiful_helmet_moment_f',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'helmetmoment',
                        Placement = {
                            vector3(-0.040000, 0.860000, 0.000000),
                            vector3(0.000000, 0.000000, 180.000000),
                        },
                    },
                },
            },
            {
                Label = 'Cogidos de la Mano',
                Command = 'holdhands',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@hand_holding_couples_m',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'holdhands2',
                    },
                },
                
            },
            {
                Label = 'Cogidos de la Mano (Acompañante)',
                Command = 'holdhands2',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@hand_holding_couples_f',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'holdhands',
                        Placement = {
                            vector3(-0.370000, -0.120000, 0.000000),
                            vector3(0.000000, 0.000000, 0.000000),
                        },
                    },
                },
            },
            {
                Label = 'Cariño en el Banco',
                Command = 'benchlove',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@couple_bank_affection_m',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'benchlove2',
                    },
                },
                
            },
            {
                Label = 'Cariño en el Banco (Acompañante)',
                Command = 'benchlove2',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@couple_bank_affection_f',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'benchlove',
                        Placement = {
                            vector3(-0.408000, 0.550000, 0.440000),
                            vector3(0.000000, 0.000000, 0.000000),
                        },
                    },
                },
            },
            {
                Label = 'Pose Juntos',
                Command = 'posetogether',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@calvin_klein_photo_pose_m',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'posetogether2',
                    },
                },
                
            },
            {
                Label = 'Pose Juntos (Acompañante)',
                Command = 'posetogether2',
                Nuevo = true,
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@calvin_klein_photo_pose_f',
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'posetogether',
                        Placement = {
                            vector3(-0.010000, 0.790000, 0.560000),
                            vector3(-30.000000, 0.000000, 0.000000),
                        },
                    },
                },
            },
            {
                Label = 'Besos en la Playa',
                Command = 'beachkiss',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@beach_kneeling_kisses_f_r',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'beachkiss2',
                    },
                },
                
            },
            {
                Label = 'Besos en la Playa (Acompañante)',
                Command = 'beachkiss2',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@beach_kneeling_kisses_f_l',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'beachkiss',
                        Placement = {
                            vector3(0.000000, 0.480000, 0.490000),
                            vector3(0.500000, 0.000000, 180.500000),
                        },
                    },
                },
            },
            {
                Label = 'Lectura bajo el árbol',
                Command = 'treebook',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@book_joy_under_treesf1',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'treebook2',
                    },
                },
                
            },
            {
                Label = 'Lectura bajo el árbol (Acompañante)',
                Command = 'treebook2',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@book_joy_under_trees_f',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'treebook',
                        Placement = {
                            vector3(0.870000, 0.320000, 0.710000),
                            vector3(0.000000, 90.000000, 0.500000),
                        },
                    },
                },
            },
            {
                Label = 'Abrazo Cercano',
                Command = 'closeness',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@embrace_of_closeness_male',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'closeness2',
                    },
                },
                SkipRequest = true
            },
            {
                Label = 'Abrazo Cercano (Acompañante)',
                Command = 'closeness2',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@embrace_of_closeness_female',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'closeness',
                        Placement = {
                            vector3(-0.420000, -0.280000, 0.050000),
                            vector3(-2.000000, 0.000000, -42.000000),
                        },
                    },
                },
            },
            {
                Label = 'Conexión Rural',
                Command = 'rural',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@rural_connection01',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        OtherAnimation = 'rural2',
                    },
                },
                SkipRequest = true
            },
            {
                Label = 'Conexión Rural (Acompañante)',
                Command = 'rural2',
                Animation = 'mrwitt',
                Dictionary = 'mrwitt@rural_connection',
                Nuevo = true,
                Options = {
                    Flags = {
                        Loop = true,
                    },
                    Shared = {
                        Attach = true,
                        Bone = 0,
                        OtherAnimation = 'rural',
                        Placement = {
                            vector3(0.750000, 0.260000, 0.000000),
                            vector3(0.000000, 0.000000, 18.000000),
                        },
                    },
                },
            },
    },
    AnimalEmotes = {}
}