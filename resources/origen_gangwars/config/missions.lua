Config.TimeMissions = {
    daily = 4,
    weekly = 4,
}

Config.Missions = {
    ['kill_5'] = {
        kills = 5,
        rewards = {
            experience = 5,
        },
        title = 'Kill 5 players',
        description = 'Eliminate 5 players using any weapon. Plan your moves carefully and stay alert to survive while completing this mission.',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'kill',
        }
    },
    ['kill_15'] = {
        kills = 15,
        rewards = {
            experience = 15,
        },
        title = 'Kill 15 players',
        description = 'Take out 15 players in a single match. Show no mercy and stay on top!',
        settings = {
            any_party = false,
            team = true,
            win = false,
            weapon = 'weapon_smg',
            headshot = false,
            type_mission = 'daily',
            type = 'kill',
        }
    },
    ['headshot_10'] = {
        kills = 10,
        rewards = {
            experience = 20,
        },
        title = '10 Headshots',
        description = 'Land 10 headshots to prove your accuracy and precision in combat.',
        settings = {
            any_party = false,
            team = false,
            win = false,
            weapon = 'weapon_rifle',
            headshot = true,
            type_mission = 'daily',
            type = 'headshot',
        }
    },
    ['kill_25_team'] = {
        kills = 25,
        rewards = {
            experience = 30,
        },
        title = 'Team Kill 25 players',
        description = 'Work together with your team to eliminate 25 enemies and dominate the battlefield.',
        settings = {
            any_party = false,
            team = true,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'kill',
        }
    },
    ['weekly_kill_150'] = {
        kills = 150,
        rewards = {
            experience = 50,
        },
        title = 'Kill 150 players',
        description = 'Eliminate 150 players over the course of the week. Patience and skill will lead to success.',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'weekly',
            type = 'kill',
        }
    },
    ['weekly_headshot_50'] = {
        kills = 50,
        rewards = {
            experience = 70,
        },
        title = '50 Headshots',
        description = 'Achieve 50 headshots within the week. Prove you are a master marksman.',
        settings = {
            any_party = false,
            team = false,
            win = false,
            weapon = 'weapon_sniper',
            headshot = true,
            type_mission = 'weekly',
            type = 'headshot',
        }
    },
    ['weekly_team_200'] = {
        kills = 200,
        rewards = {
            experience = 100,
        },
        title = 'Team Kill 200 players',
        description = 'Collaborate with your team to take down 200 enemies over the week. Coordination is key.',
        settings = {
            any_party = false,
            team = true,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'weekly',
            type = 'kill',
        }
    },
    ['kill_melee_10'] = {
        kills = 10,
        rewards = {
            experience = 25,
        },
        title = 'Kill 10 with melee weapons',
        description = 'Eliminate 10 enemies using only melee weapons. Get up close and personal!',
        settings = {
            any_party = false,
            team = false,
            win = false,
            weapon = 'weapon_knife',
            headshot = false,
            type_mission = 'daily',
            type = 'kill',
        }
    },
    ['weekly_random_300'] = {
        kills = 300,
        rewards = {
            experience = 150,
        },
        title = 'Kill 300 players',
        description = 'Take down 300 players this week. Only the strongest will complete this mission!',
        settings = {
            any_party = true,
            team = true,
            win = true,
            weapon = false,
            headshot = false,
            type_mission = 'weekly',
            type = 'kill',
        }
    },

    ['survive_no_damage'] = {
        rewards = {
            experience = 20,
        },
        title = 'Survive without taking damage',
        description = 'Complete a match without receiving any damage. Stay cautious and avoid all confrontations.',
        settings = {
            any_party = false,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'survive',
        }
    },
    ['win_no_damage_dealt'] = {
        rewards = {
            experience = 25,
        },
        title = 'Win without dealing damage',
        description = 'Win a match without dealing any damage. Strategy and patience will lead you to victory.',
        settings = {
            any_party = false,
            team = false,
            win = true,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'win',
        }
    },
    ['walk_400_meters'] = {
        rewards = {
            experience = 15,
        },
        title = 'Walk 400 meters',
        description = 'Travel 400 meters on foot in a single match. Keep moving to achieve this mission.',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            distance = 400,
            type = 'walk',
        }
    },
    ['survive_top_3'] = {
        rewards = {
            experience = 30,
        },
        title = 'Survive to Top 3',
        description = 'Survive until only 3 players remain. Outsmart your opponents to make it this far.',
        settings = {
            any_party = false,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'survive',
        }
    },
    ['daily_no_damage'] = {
        rewards = {
            experience = 80,
        },
        title = 'Survive 3 matches without damage',
        description = 'Survive a total of 3 matches without taking any damage throughout the week. Keep your guard up!',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'survive',
        }
    },
    ['weekly_no_damage'] = {
        rewards = {
            experience = 200,
        },
        title = 'Survive 15 matches without damage',
        description = 'Survive a total of 15 matches without taking any damage throughout the week. Keep your guard up!',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'weekly',
            type = 'survive',
        }
    },
    ['weekly_stealth_win'] = {
        rewards = {
            experience = 100,
        },
        title = 'Win without being detected',
        description = 'Win a match without being spotted by enemies during combat. Silence and strategy are your allies.',
        settings = {
            any_party = false,
            team = false,
            win = true,
            weapon = false,
            headshot = false,
            type_mission = 'weekly',
            type = 'win',
        }
    },
    ['play_5_matches'] = {
        rewards = {
            experience = 15,
        },
        title = 'Play 5 matches',
        description = 'Participate in 5 matches regardless of outcome. Just keep playing!',
        settings = {
            any_party = true,
            team = false,
            win = false,
            weapon = false,
            headshot = false,
            type_mission = 'daily',
            type = 'play',
            matches = 5,
        }
    },
}