return {
    ["catseyeItem"] = {
    },
    ["catseyeNpc"] = {
        ["Curio Moogle"] = {
            ["icon"] = "CurioMoogle.png",
            ["note"] = "CatsEyeXI:\
* ACE curio shop near port-area Mog\
Houses.\
* Sells food, medicine, keys,\
trusts, and other utility items.\
* Some items require Rhapsody key\
items from Momiji.",
            ["type"] = "Curio Shop",
            ["zones"] = {
                [1] = "Port San d'Oria",
                [2] = "Port Bastok",
                [3] = "Port Windurst",
            },
        },
        ["Erbelie"] = {
            ["icon"] = "QuestNPC.png",
            ["location"] = "Port Windurst G-8",
            ["note"] = "Crystal Warrior:\
* Starts quests: Neck and Neck,\
Neck and Neck II.\
* Level 10 Windurst starting\
quests.",
            ["type"] = "CW Starting Quest",
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Puluki-Culuki"] = {
            ["icon"] = "QuestNPC.png",
            ["location"] = "Port Windurst B-4",
            ["note"] = "Crystal Warrior:\
* Starts quest: Rustling Feathers.\
* Level 5 Windurst starting quest.",
            ["type"] = "CW Starting Quest",
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sadoc"] = {
            ["icon"] = "Event.png",
            ["location"] = "Port Windurst L-6",
            ["note"] = "Novice Trials:\
* Starts no-cooldown equipment\
augment trials.\
* Can transfer completed NQ\
augments to crafted HQ versions.\
* Trials may be completed on any\
job.",
            ["type"] = "Novice Trials",
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
    },
    ["item"] = {
        ["Door:Arrivals Entrance"] = {
            ["icon"] = "Door.png",
            ["note"] = "The structural port checkpoint door separating international traffic. Passing past the framework manages airship terminal transit scripts or processes tracking goals.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 232,
                [2] = 236,
                [3] = 240,
                [4] = 246,
            },
            ["zones"] = {
                [1] = "Port San d'Oria",
                [2] = "Port Bastok",
                [3] = "Port Windurst",
                [4] = "Port Jeuno",
            },
        },
        ["Door:Arrivals Exit"] = {
            ["icon"] = "Door.png",
            ["note"] = "The heavy terminal gateway threshold exiting the arrivals deck. Shifting the latch moves you out into the public city port districts from travel layers.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 232,
                [2] = 236,
                [3] = 240,
                [4] = 246,
            },
            ["zones"] = {
                [1] = "Port San d'Oria",
                [2] = "Port Bastok",
                [3] = "Port Windurst",
                [4] = "Port Jeuno",
            },
        },
        ["Door:Departures Entrance"] = {
            ["icon"] = "Door.png",
            ["note"] = "The localized security check portal blockading the departure docks. Passing through checks active boarding passes to grant access to transit lines.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 232,
                [2] = 236,
                [3] = 240,
                [4] = 246,
            },
            ["zones"] = {
                [1] = "Port San d'Oria",
                [2] = "Port Bastok",
                [3] = "Port Windurst",
                [4] = "Port Jeuno",
            },
        },
        ["Door:Departures Exit"] = {
            ["icon"] = "Door.png",
            ["note"] = "The heavy timber framework exiting the airship platform. Shifting the latch moves you off travel vessels to return securely into the terminal.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 232,
                [2] = 236,
                [3] = 240,
                [4] = 246,
            },
            ["zones"] = {
                [1] = "Port San d'Oria",
                [2] = "Port Bastok",
                [3] = "Port Windurst",
                [4] = "Port Jeuno",
            },
        },
        ["Door:Doctor's Residence"] = {
            ["icon"] = "Door.png",
            ["note"] = "A basic residential wooden door set into the city stonework layouts. Unlatching the frame allows you to enter medical quarters to fulfill clinic delivery checks or urban side tasks.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Door:Orastery"] = {
            ["icon"] = "Door.png",
            ["note"] = "The heavy wooden entry barrier leading to the magical astronomical research towers. Pulling the handle uncovers rare library records or validates active Federation quest milestones.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Symphonic Curator"] = {
            ["icon"] = "Box.png",
            ["note"] = "An ornate structural orchestrion terminal situated near local residential entrances. Interfacing with this podium lets you purchase, configure, and alter the background acoustic music scores for the municipal region.",
            ["type"] = "Quest Node",
            ["zoneIds"] = {
                [1] = 48,
                [10] = 235,
                [11] = 236,
                [12] = 238,
                [13] = 239,
                [14] = 240,
                [15] = 241,
                [16] = 243,
                [17] = 244,
                [18] = 245,
                [19] = 246,
                [2] = 50,
                [20] = 256,
                [21] = 257,
                [3] = 80,
                [4] = 87,
                [5] = 94,
                [6] = 230,
                [7] = 231,
                [8] = 232,
                [9] = 234,
            },
            ["zones"] = {
                [1] = "Al Zahbi",
                [10] = "Bastok Markets",
                [11] = "Port Bastok",
                [12] = "Windurst Waters",
                [13] = "Windurst Walls",
                [14] = "Port Windurst",
                [15] = "Windurst Woods",
                [16] = "Ru'Lude Gardens",
                [17] = "Upper Jeuno",
                [18] = "Lower Jeuno",
                [19] = "Port Jeuno",
                [2] = "Aht Urhgan Whitegate",
                [20] = "Western Adoulin",
                [21] = "Eastern Adoulin",
                [3] = "Southern San d'Oria [S]",
                [4] = "Bastok Markets [S]",
                [5] = "Windurst Waters [S]",
                [6] = "Southern San d'Oria",
                [7] = "Northern San d'Oria",
                [8] = "Port San d'Oria",
                [9] = "Bastok Mines",
            },
        },
        ["Tales' Beginning"] = {
            ["hidden"] = true,
            ["icon"] = "Box.png",
            ["note"] = "A distinct magical marker manifest near prominent municipal gathering hubs. Interfacing with its surface reviews historical records and initiates localized storyline expansions.",
            ["type"] = "Quest Node",
            ["zoneIds"] = {
                [1] = 184,
                [10] = 240,
                [11] = 241,
                [12] = 245,
                [13] = 246,
                [14] = 252,
                [2] = 230,
                [3] = 231,
                [4] = 232,
                [5] = 234,
                [6] = 235,
                [7] = 236,
                [8] = 238,
                [9] = 239,
            },
            ["zones"] = {
                [1] = "Lower Delkfutt's Tower",
                [10] = "Port Windurst",
                [11] = "Windurst Woods",
                [12] = "Lower Jeuno",
                [13] = "Port Jeuno",
                [14] = "Norg",
                [2] = "Southern San d'Oria",
                [3] = "Northern San d'Oria",
                [4] = "Port San d'Oria",
                [5] = "Bastok Mines",
                [6] = "Bastok Markets",
                [7] = "Port Bastok",
                [8] = "Windurst Waters",
                [9] = "Windurst Walls",
            },
        },
    },
    ["npc"] = {
        ["Achieve Master"] = {
            ["icon"] = "GoalTracker.png",
            ["type"] = "Goal Tracker",
            ["zoneIds"] = {
                [1] = 1,
                [10] = 10,
                [100] = 101,
                [101] = 102,
                [102] = 103,
                [103] = 104,
                [104] = 105,
                [105] = 106,
                [106] = 107,
                [107] = 108,
                [108] = 109,
                [109] = 110,
                [11] = 11,
                [110] = 111,
                [111] = 112,
                [112] = 113,
                [113] = 114,
                [114] = 115,
                [115] = 116,
                [116] = 117,
                [117] = 118,
                [118] = 119,
                [119] = 120,
                [12] = 12,
                [120] = 121,
                [121] = 122,
                [122] = 123,
                [123] = 124,
                [124] = 125,
                [125] = 126,
                [126] = 127,
                [127] = 128,
                [128] = 129,
                [129] = 130,
                [13] = 13,
                [130] = 131,
                [131] = 132,
                [132] = 133,
                [133] = 134,
                [134] = 135,
                [135] = 136,
                [136] = 137,
                [137] = 138,
                [138] = 139,
                [139] = 140,
                [14] = 14,
                [140] = 141,
                [141] = 142,
                [142] = 143,
                [143] = 144,
                [144] = 145,
                [145] = 146,
                [146] = 147,
                [147] = 148,
                [148] = 149,
                [149] = 150,
                [15] = 15,
                [150] = 151,
                [151] = 152,
                [152] = 153,
                [153] = 154,
                [154] = 155,
                [155] = 156,
                [156] = 157,
                [157] = 158,
                [158] = 159,
                [159] = 160,
                [16] = 16,
                [160] = 161,
                [161] = 162,
                [162] = 163,
                [163] = 164,
                [164] = 165,
                [165] = 166,
                [166] = 167,
                [167] = 168,
                [168] = 169,
                [169] = 170,
                [17] = 17,
                [170] = 171,
                [171] = 172,
                [172] = 173,
                [173] = 174,
                [174] = 175,
                [175] = 176,
                [176] = 177,
                [177] = 178,
                [178] = 179,
                [179] = 180,
                [18] = 18,
                [180] = 181,
                [181] = 182,
                [182] = 183,
                [183] = 184,
                [184] = 185,
                [185] = 186,
                [186] = 187,
                [187] = 188,
                [188] = 189,
                [189] = 190,
                [19] = 19,
                [190] = 191,
                [191] = 192,
                [192] = 193,
                [193] = 194,
                [194] = 195,
                [195] = 196,
                [196] = 197,
                [197] = 198,
                [198] = 200,
                [199] = 201,
                [2] = 2,
                [20] = 20,
                [200] = 202,
                [201] = 203,
                [202] = 204,
                [203] = 205,
                [204] = 206,
                [205] = 207,
                [206] = 208,
                [207] = 209,
                [208] = 211,
                [209] = 212,
                [21] = 21,
                [210] = 213,
                [211] = 215,
                [212] = 216,
                [213] = 217,
                [214] = 218,
                [215] = 220,
                [216] = 221,
                [217] = 222,
                [218] = 223,
                [219] = 224,
                [22] = 22,
                [220] = 225,
                [221] = 226,
                [222] = 227,
                [223] = 228,
                [224] = 230,
                [225] = 231,
                [226] = 232,
                [227] = 233,
                [228] = 234,
                [229] = 235,
                [23] = 23,
                [230] = 236,
                [231] = 237,
                [232] = 238,
                [233] = 239,
                [234] = 240,
                [235] = 241,
                [236] = 242,
                [237] = 243,
                [238] = 244,
                [239] = 245,
                [24] = 24,
                [240] = 246,
                [241] = 247,
                [242] = 248,
                [243] = 249,
                [244] = 250,
                [245] = 251,
                [246] = 252,
                [247] = 253,
                [248] = 254,
                [249] = 255,
                [25] = 25,
                [250] = 256,
                [251] = 257,
                [252] = 258,
                [253] = 259,
                [254] = 260,
                [255] = 261,
                [256] = 262,
                [257] = 263,
                [258] = 264,
                [259] = 265,
                [26] = 26,
                [260] = 266,
                [261] = 267,
                [262] = 268,
                [263] = 269,
                [264] = 270,
                [265] = 271,
                [266] = 272,
                [267] = 273,
                [268] = 274,
                [269] = 275,
                [27] = 27,
                [270] = 276,
                [271] = 277,
                [272] = 279,
                [273] = 280,
                [274] = 281,
                [275] = 283,
                [276] = 284,
                [277] = 285,
                [278] = 287,
                [279] = 288,
                [28] = 28,
                [280] = 289,
                [281] = 290,
                [282] = 291,
                [283] = 292,
                [284] = 293,
                [285] = 294,
                [286] = 295,
                [287] = 296,
                [288] = 297,
                [289] = 298,
                [29] = 29,
                [290] = 299,
                [3] = 3,
                [30] = 30,
                [31] = 31,
                [32] = 32,
                [33] = 33,
                [34] = 34,
                [35] = 35,
                [36] = 36,
                [37] = 37,
                [38] = 38,
                [39] = 39,
                [4] = 4,
                [40] = 40,
                [41] = 41,
                [42] = 42,
                [43] = 43,
                [44] = 44,
                [45] = 45,
                [46] = 46,
                [47] = 47,
                [48] = 48,
                [49] = 50,
                [5] = 5,
                [50] = 51,
                [51] = 52,
                [52] = 53,
                [53] = 54,
                [54] = 55,
                [55] = 56,
                [56] = 57,
                [57] = 58,
                [58] = 59,
                [59] = 60,
                [6] = 6,
                [60] = 61,
                [61] = 62,
                [62] = 63,
                [63] = 64,
                [64] = 65,
                [65] = 66,
                [66] = 67,
                [67] = 68,
                [68] = 69,
                [69] = 70,
                [7] = 7,
                [70] = 71,
                [71] = 72,
                [72] = 73,
                [73] = 74,
                [74] = 75,
                [75] = 76,
                [76] = 77,
                [77] = 78,
                [78] = 79,
                [79] = 80,
                [8] = 8,
                [80] = 81,
                [81] = 82,
                [82] = 83,
                [83] = 84,
                [84] = 85,
                [85] = 86,
                [86] = 87,
                [87] = 88,
                [88] = 89,
                [89] = 90,
                [9] = 9,
                [90] = 91,
                [91] = 92,
                [92] = 93,
                [93] = 94,
                [94] = 95,
                [95] = 96,
                [96] = 97,
                [97] = 98,
                [98] = 99,
                [99] = 100,
            },
            ["zones"] = {
                [1] = "Abdhaljs Isle-Purgonorgo",
                [10] = "Abyssea - Uleguerand",
                [100] = "Full Moon Fountain",
                [101] = "Garlaige Citadel",
                [102] = "Garlaige Citadel [S]",
                [103] = "Ghelsba Outpost",
                [104] = "Ghoyu's Reverie",
                [105] = "Giddeus",
                [106] = "Grand Palace of Hu'Xzoi",
                [107] = "Grauberg [S]",
                [108] = "Gusgen Mines",
                [109] = "Gustav Tunnel",
                [11] = "Abyssea - Vunkerl",
                [110] = "Gwora-Throne Room",
                [111] = "Hall of The Gods",
                [112] = "Hall of Transference",
                [113] = "Halvung",
                [114] = "Hazhalm Testing Grounds",
                [115] = "Heavens Tower",
                [116] = "Horlais Peak",
                [117] = "Ifrit's Cauldron",
                [118] = "Ilrusi Atoll",
                [119] = "Inner Horutoto Ruins",
                [12] = "Aht Urhgan Whitegate",
                [120] = "Jade Sepulcher",
                [121] = "Jugner Forest",
                [122] = "Jugner Forest [S]",
                [123] = "Kamihr Drifts",
                [124] = "Kazham",
                [125] = "Kazham - Jeuno Airship",
                [126] = "King Ranperre's Tomb",
                [127] = "Konschtat Highlands",
                [128] = "Korroloka Tunnel",
                [129] = "Kuftal Tunnel",
                [13] = "Al Zahbi",
                [130] = "La Theine Plateau",
                [131] = "La Vaule [S]",
                [132] = "La'Loff Amphitheater",
                [133] = "Labyrinth of Onzozo",
                [134] = "Leafallia",
                [135] = "Lebros Cavern",
                [136] = "Leujaoam Sanctum",
                [137] = "Lower Delkfutt's Tower",
                [138] = "Lower Jeuno",
                [139] = "Lufaise Meadows",
                [14] = "Al'Taieu",
                [140] = "Mamook",
                [141] = "Mamool Ja Training Grounds",
                [142] = "Manaclipper",
                [143] = "Maquette Abdhaljs-Legion A",
                [144] = "Maquette Abdhaljs-Legion B",
                [145] = "Marjami Ravine",
                [146] = "Maze of Shakhrami",
                [147] = "Meriphataud Mountains",
                [148] = "Meriphataud Mountains [S]",
                [149] = "Metalworks",
                [15] = "Altar Room",
                [150] = "Mhaura",
                [151] = "Middle Delkfutt's Tower",
                [152] = "Mine Shaft #2716",
                [153] = "Misareaux Coast",
                [154] = "Mog Garden",
                [155] = "Moh Gates",
                [156] = "Monarch Linn",
                [157] = "Monastic Cavern",
                [158] = "Mordion Gaol",
                [159] = "Morimar Basalt Fields",
                [16] = "Alzadaal Undersea Ruins",
                [160] = "Mount Zhayolm",
                [161] = "Nashmau",
                [162] = "Navukgo Execution Chamber",
                [163] = "Newton Movalpolos",
                [164] = "Norg",
                [165] = "North Gustaberg",
                [166] = "North Gustaberg [S]",
                [167] = "Northern San d'Oria",
                [168] = "Nyzul Isle",
                [169] = "Oldton Movalpolos",
                [17] = "Apollyon",
                [170] = "Open Sea Route to Al Zahbi",
                [171] = "Open Sea Route to Mhaura",
                [172] = "Ordelle's Caves",
                [173] = "Outer Horutoto Ruins",
                [174] = "Outer Ra'Kaznar",
                [175] = "Outer Ra'Kaznar [U]",
                [176] = "Outer Rakaznar [U1]",
                [177] = "Outer Rakaznar [U2]",
                [178] = "Outer Rakaznar [U3]",
                [179] = "Palborough Mines",
                [18] = "Arrapago Reef",
                [180] = "Pashhow Marshlands",
                [181] = "Pashhow Marshlands [S]",
                [182] = "Periqia",
                [183] = "Phanauet Channel",
                [184] = "Phomiuna Aqueducts",
                [185] = "Port Bastok",
                [186] = "Port Jeuno",
                [187] = "Port San d'Oria",
                [188] = "Port Windurst",
                [189] = "Promyvion - Dem",
                [19] = "Arrapago Remnants",
                [190] = "Promyvion - Holla",
                [191] = "Promyvion - Mea",
                [192] = "Promyvion - Vahzl",
                [193] = "Provenance",
                [194] = "Pso'Xja",
                [195] = "Qu'Bia Arena",
                [196] = "Qufim Island",
                [197] = "Quicksand Caves",
                [198] = "Qulun Dome",
                [199] = "Ra'Kaznar Inner Court",
                [2] = "Abyssea - Altepa",
                [20] = "Attohwa Chasm",
                [200] = "Ra'Kaznar Turris",
                [201] = "Rabao",
                [202] = "Rala Waterways",
                [203] = "Rala Waterways [U]",
                [204] = "Ranguemont Pass",
                [205] = "Reisenjima",
                [206] = "Reisenjima Henge",
                [207] = "Reisenjima Sanctorium",
                [208] = "Riverne - Site #A01",
                [209] = "Riverne - Site #B01",
                [21] = "Aydeewa Subterrane",
                [210] = "Ro'Maeve",
                [211] = "Rolanberry Fields",
                [212] = "Rolanberry Fields [S]",
                [213] = "Ru'Aun Gardens",
                [214] = "Ru'Lude Gardens",
                [215] = "Ruhotz Silvermines",
                [216] = "Sacrarium",
                [217] = "Sacrificial Chamber",
                [218] = "San d'Oria - Jeuno Airship",
                [219] = "Sauromugue Champaign",
                [22] = "Balga's Dais",
                [220] = "Sauromugue Champaign [S]",
                [221] = "Sea Serpent Grotto",
                [222] = "Sealion's Den",
                [223] = "Selbina",
                [224] = "Ship Bound for Mhaura",
                [225] = "Ship Bound for Mhaura (Pirates)",
                [226] = "Ship Bound for Selbina",
                [227] = "Ship Bound for Selbina (Pirates)",
                [228] = "Sih Gates",
                [229] = "Silver Knife",
                [23] = "Bastok - Jeuno Airship",
                [230] = "Silver Sea Remnants",
                [231] = "Silver Sea Route to Al Zahbi",
                [232] = "Silver Sea Route to Nashmau",
                [233] = "South Gustaberg",
                [234] = "Southern San d'Oria",
                [235] = "Southern San d'Oria [S]",
                [236] = "Spire of Dem",
                [237] = "Spire of Holla",
                [238] = "Spire of Mea",
                [239] = "Spire of Vahzl",
                [24] = "Bastok Markets",
                [240] = "Stellar Fulcrum",
                [241] = "Tahrongi Canyon",
                [242] = "Talacca Cove",
                [243] = "Tavnazian Safehold",
                [244] = "Temenos",
                [245] = "Temple of Uggalepih",
                [246] = "The Ashu Talif",
                [247] = "The Boyahda Tree",
                [248] = "The Celestial Nexus",
                [249] = "The Colosseum",
                [25] = "Bastok Markets [S]",
                [250] = "The Eldieme Necropolis",
                [251] = "The Eldieme Necropolis [S]",
                [252] = "The Garden of Ru'Hmet",
                [253] = "The Sanctuary of Zi'Tah",
                [254] = "The Shrine of Ru'Avitau",
                [255] = "The Shrouded Maw",
                [256] = "Throne Room",
                [257] = "Throne Room [S]",
                [258] = "Toraimarai Canal",
                [259] = "Uleguerand Range",
                [26] = "Bastok Mines",
                [260] = "Upper Delkfutt's Tower",
                [261] = "Upper Jeuno",
                [262] = "Valkurm Dunes",
                [263] = "Valley of Sorrows",
                [264] = "Ve'Lugannon Palace",
                [265] = "Vunkerl Inlet [S]",
                [266] = "Wajaom Woodlands",
                [267] = "Walk of Echoes",
                [268] = "Walk of Echoes [P1]",
                [269] = "Walk of Echoes [P2]",
                [27] = "Batallia Downs",
                [270] = "Walk of Echoes P1",
                [271] = "Walk of Echoes P2",
                [272] = "Waughroon Shrine",
                [273] = "West Ronfaure",
                [274] = "West Sarutabaruta",
                [275] = "West Sarutabaruta [S]",
                [276] = "Western Adoulin",
                [277] = "Western Altepa Desert",
                [278] = "Windurst - Jeuno Airship",
                [279] = "Windurst Walls",
                [28] = "Batallia Downs [S]",
                [280] = "Windurst Waters",
                [281] = "Windurst Waters [S]",
                [282] = "Windurst Woods",
                [283] = "Woh Gates",
                [284] = "Xarcabard",
                [285] = "Xarcabard [S]",
                [286] = "Yahse Hunting Grounds",
                [287] = "Yhoator Jungle",
                [288] = "Yorcia Weald",
                [289] = "Yorcia Weald [U]",
                [29] = "Beadeaux",
                [290] = "Yughott Grotto",
                [291] = "Yuhtunga Jungle",
                [292] = "Zeruhn Mines",
                [293] = "Zhayolm Remnants",
                [3] = "Abyssea - Attohwa",
                [30] = "Beadeaux [S]",
                [31] = "Bearclaw Pinnacle",
                [32] = "Beaucedine Glacier",
                [33] = "Beaucedine Glacier [S]",
                [34] = "Behemoth's Dominion",
                [35] = "Bhaflau Remnants",
                [36] = "Bhaflau Thickets",
                [37] = "Bibiki Bay",
                [38] = "Boneyard Gully",
                [39] = "Bostaunieux Oubliette",
                [4] = "Abyssea - Empyreal Paradox",
                [40] = "Buburimu Peninsula",
                [41] = "Caedarva Mire",
                [42] = "Cape Teriggan",
                [43] = "Carpenters' Landing",
                [44] = "Castle Oztroja",
                [45] = "Castle Oztroja [S]",
                [46] = "Castle Zvahl Baileys",
                [47] = "Castle Zvahl Baileys [S]",
                [48] = "Castle Zvahl Keep",
                [49] = "Castle Zvahl Keep [S]",
                [5] = "Abyssea - Grauberg",
                [50] = "Ceizak Battlegrounds",
                [51] = "Celennia Memorial Library",
                [52] = "Chamber of Oracles",
                [53] = "Chateau d'Oraguille",
                [54] = "Chocobo Circuit",
                [55] = "Cirdas Caverns",
                [56] = "Cirdas Caverns [U]",
                [57] = "Cloister of Flames",
                [58] = "Cloister of Frost",
                [59] = "Cloister of Gales",
                [6] = "Abyssea - Konschtat",
                [60] = "Cloister of Storms",
                [61] = "Cloister of Tides",
                [62] = "Cloister of Tremors",
                [63] = "Crawlers' Nest",
                [64] = "Crawlers' Nest [S]",
                [65] = "Dangruf Wadi",
                [66] = "Davoi",
                [67] = "Den of Rancor",
                [68] = "Desuetia - Empyreal Paradox",
                [69] = "Dho Gates",
                [7] = "Abyssea - La Theine",
                [70] = "Diorama Abdhaljs-Ghelsba",
                [71] = "Dragon's Aery",
                [72] = "Dynamis - Bastok",
                [73] = "Dynamis - Beaucedine",
                [74] = "Dynamis - Buburimu",
                [75] = "Dynamis - Jeuno",
                [76] = "Dynamis - Qufim",
                [77] = "Dynamis - San d'Oria",
                [78] = "Dynamis - Tavnazia",
                [79] = "Dynamis - Valkurm",
                [8] = "Abyssea - Misareaux",
                [80] = "Dynamis - Windurst",
                [81] = "Dynamis - Xarcabard",
                [82] = "Dynamis-Bastok [D]",
                [83] = "Dynamis-Jeuno [D]",
                [84] = "Dynamis-San d'Oria [D]",
                [85] = "Dynamis-Windurst [D]",
                [86] = "East Ronfaure",
                [87] = "East Ronfaure [S]",
                [88] = "East Sarutabaruta",
                [89] = "Eastern Adoulin",
                [9] = "Abyssea - Tahrongi",
                [90] = "Eastern Altepa Desert",
                [91] = "Empyreal Paradox",
                [92] = "Escha - Ru'Aun",
                [93] = "Escha - Zi'Tah",
                [94] = "Everbloom Hollow",
                [95] = "Fei'Yin",
                [96] = "Feretory",
                [97] = "Foret de Hennetiel",
                [98] = "Fort Ghelsba",
                [99] = "Fort Karugo-Narugo [S]",
            },
        },
        ["Ada"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Aigneis"] = {
            ["icon"] = "AirshipTravelAgent.png",
            ["type"] = "Airship Travel",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Alizabe"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Aroro"] = {
            ["icon"] = "Merchant.png",
            ["note"] = "Notes:\
A young Tarutaru girl who sells black magic scrolls at Kususu's Hoodoos.",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Babubu"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Fishing Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Baladanzo"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Blank Card"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
There are multiples of this NPC, in various locations.",
            ["type"] = "Test NPC",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Boronene"] = {
            ["icon"] = "RoomRenters.png",
            ["note"] = "Notes:\
\"This is the gateway to Windurst's residential ares. Inside, there are Mog Houses available for use by Windurst.\" *Ask for an explanation of Mog Houses. \"A Mog House is you own personal apartment room, provided for you convenience. In you Mog House, you can carry out such activities as storing items, changing jobs, and healing HP and MP. Why don'taru head up to your Mog House and rest your little body-wody?\" *Nothing in particular. \"Well then, bye-bye and ta-taru!\"",
            ["type"] = "Residence Renter",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Breanainn"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Calixte"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Chakwaina"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Chapa-Cha"] = {
            ["icon"] = "Guard.png",
            ["note"] = "Notes:\
\"Beyond this gateway is the Windurst residential area, where you can stay in a Mog House or Rent-a-Room. If you need to hear an explanation, that's Boronene job. So pluck up the courage, and ask Boroene over there for all you need to knowy-wowy.\"",
            ["type"] = "Residential Guard",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Chipmy-Popmy"] = {
            ["icon"] = "MapMarker.png",
            ["note"] = "Starts Quests:\
* One Good Deed?\
\
Involved in Missions:\
* Promathia Mission 8-4: Dawn",
            ["type"] = "Map Quest",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Choyi Totlihpa"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Lure of the Wildcat (Windurst)",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Deeto-Yaato"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Degong"] = {
            ["icon"] = "GuildMerchant.png",
            ["type"] = "Guild Craftsman",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Dehn Harzhapan"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Escort for Hire (Windurst)",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Diegai"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Drozga"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Eight of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Eki Kamalabi"] = {
            ["icon"] = "AdventurersAssistant.png",
            ["note"] = "Notes:\
Offers Information on Linkshells: :(...Yeah, that's what I said! But you know what? Oh, wait. Hold on...) I'm sorry, can I help you? [You point at the item in her hand.] Oh, this? It's a magical shell called a Linkshell. You want to know about linkshells? Let me tell you all about them! :*\"What's a Linkshell?\": These magic shells are full of mysteries... You can get beautiful pearls from them. Some say these are some new form of shall shells, but... Even if you take out a pearl, they make more and more of them. Strange isn't it? What's more strange is that pearls taken from the same shell actually transmit sound, no matter how far apart they are! So, if you speak into one of the pearls, people who hold the other pearls or the shell they were made from can hear you! It's as if they were linked by an invisible thread... Huh. I guess that's why they have \"link\" in their names. So anyway, the shells are called linkshells, and the pearls linkpearls. :*\"What types of Linkshells are there?\": There are also many different types of linkshells. :*\"New linkshell.\": New linkshell are linkshells when you first buy them at the store. Once opened, they start making linkpearls and become the communications tool everyone's using. You can set the color and name of your linkshell when you open it. Make sure to set the ones you like because you can't change them afterwards! :*\"Linkshells.\": Linkshells are new linkshell that have been opened and function as a communication tool. You can make linkpearls and pearlsacks from these shells. They're like the party leader of an adventuring party. All items created by your linkshell retain the linkshell's color and name. Make the name something unique so that it's easy to remember. :*\"Linkpearls.\": Linkpearls are pearls that linkshells make. If you equip one, you can communicate with people who have the same linkpearls and the linkshell they were made from. They're like the party members in an adventuring party. :*\"Pearlsacks.\": A pearlsack is a bag full of linkpearls. You can make one by metamorphosing a linkpearl for that purpose. It won't have all the features of a linkshell, but you can take out an endless amount of linkpearls like a linkshell. You have to use a linkshell to make a pearlsack. The same goes if you want to turn it back into a linkpearl. They're like the party leaders of an alliance of adventuring parties. :*\"Back.\" :*\"How do you use them?\": You want to know how to use them? Where should I start? :*\"Where to get one.\": You can buy linkshells in shops. They're a little pricey, though. It might be best if you ask friends who want pearls to chip in. :*\"Assigning a color and name.\": A freshly bought new linkshell has neither a color nor a name. A linkshell becomes usable only after you've chosen its color and given it a name. Then you can use it to make linkpearls. You can combine different amount of blue, red, and green to make your shell's color. You can only use alphabet letters for the name, but you can use capital and lowercase letters anywhere you want. :*\"Making linkpearls.\": Linkpearls are make from linkshells. Making them is easy. Just equip your linkshell, then go to \"Linkshell\" in the menu and select \"Create Pearl\"! All linkpearls made this way retain the linkshell's color and name, so it's easy to tell who can hear you! You can make as many linkpearls as you want, whenever you want, so don't worry about making too many of them! You can also make linkpearls with a pearlsack the same way. Oh, and...you use your linkshell to make pearlsacks, too, but it's a little complicated so I'll tell you later. :*\"Equipping them.\": You have to equip a linkshell for it to have any effect. Go to \"Linkshell\" from the menu and choose the linkshell you want to equip, then select \"Equip\" and you're all ready to go. It's a little different from equipping weapons and armor. And you also can't equip more than one linkshell at a time. After you've done this, an icon that represents what you've equipped will appear beside your name. This is where the color you chose becomes visible. If someone \"checks\" you in this state, they will be able to see the name of the linkshell you have on. Follow the same steps to equip linkpearls and pearlsacks. :*\"Speaking into them.\": To speak into a linkshell, change you chat mode to \"linkshell,\" and whatever you say will be heard by everyone who has the same \"link.\" You can also type \"/linkshell\" and type your message. The shorter version is \"/l\" (lowercase \"L\" for \"linkshell\"). Ah, but of course, you have to have a linkshell, linkpearl, or pearlsack equipped first. Whatever you say will only be heard by people who have the linkshell, linkpearl, or pearlsack with the same link. So if you want to stop listening to your link, all you have to do is unequip your linkshell, linkpearl, or pearlsack. :*\"Metamorphosing a linkpearl.\": A linkshell can metamorphose other people's linkpearls and pearlsacks. Of sourse, it can only affect those that were made from the same linkshell. There are two types of metamorphoses, which are: 1: Make into sack / Make into pearl 2: Kick. Both need the target linkpearl or pearlsack to be equipped at the time. \"Make into sack / Make into pearl\" makes the target linkpearl into a pearlsack and vice-versa. It's useful if you want someone else to take care of handing out linkpearls in your place. \"Kick\" actually breaks the link with the target linkpearl or pearlsack and turns it into junk. Once kicked, the linkpearl will become broken and unusable... Only use this in extreme cases! Pearlsacks can also be used to \"kick\" but they can only affect linkpearls. :*\"Throwing them away.\": Linkshells, linkspearls, and pearlsacks are normal items, so they can be thrown away easily. But as normal items, you'll lose them permanently if you throw them away. It won't really matter if it's a linkpearl, but throwing away a linkshell is not a good idea! :*\"Back.\" :*\"Never mind.\": Oh, are you sure? Well, if you ever have any questions about linkshells you know where to find me! (So anyways, as I was saying...)",
            ["type"] = "Adventurer's Assistant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Enjojo"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Erabu-Fumulubu"] = {
            ["icon"] = "GuildMerchant.png",
            ["type"] = "Guild Craftsman",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Eugie"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Eya Bhithroh"] = {
            ["icon"] = "WeatherChecker.png",
            ["note"] = "Notes:\
Checks weather for the following locations: :* East Sarutabaruta :* West Sarutabaruta :* Tahrongi Canyon :* Buburimu Peninsula :* Meriphataud Mountains",
            ["type"] = "Weather Reporter",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Fabricius"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
* Supplies players with additional Traverser Stones. His stock is shared with Joachim. |",
            ["type"] = "Abyssea Support",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Abyssea",
                [2] = "Port Windurst",
            },
        },
        ["Fennella"] = {
            ["icon"] = "GuildworkersUnionRepresentative.png",
            ["type"] = "Guild Points",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Five of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Four of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Gold Skull"] = {
            ["icon"] = "MissionNPC.png",
            ["note"] = "Involved in Missions:\
* Bastok Mission 2-3: The Emissary",
            ["type"] = "Mission Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Goltata"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Wonder Wands",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Gomada-Vulmada"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Notes:\
*  Member of the Star Onion Brigade",
            ["type"] = "Star Onion Brigade",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Griffyth"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Guruna-Maguruna"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Hakkuru-Rinkuru"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Making Amends\
* Wonder Wands\
\
Involved in Missions:\
* Windurst Mission 1-1: The Horutoto Ruins Experiment\
* Windurst Mission 3-1: To Each His Own Right\
* Windurst Mission 6-1: Full Moon Fountain",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Hepo Pinulpe"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Hohbiba-Mubiba"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Honorio"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Janshura-Rashura"] = {
            ["icon"] = "Guard.png",
            ["note"] = "Starts Missions:\
* Windurst Missions\
",
            ["type"] = "Gate Guard",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Jolwa-Moowa"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Josef"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Josefina"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kameel"] = {
            ["icon"] = "AirshipTravelAgent.png",
            ["note"] = "Notes:\
Reports airship arrival and departure time.",
            ["type"] = "Airship Travel",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Khel Pahlhama"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Linkshell Dealer",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kohlo-Lakolo"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Starts Quests:\
* Truth, Justice, and the Onion Way!\
* Know One's Onions\
* Inspector's Gadget!\
* Onion Rings\
* Crying Over Onions\
* The Promise\
\
Involved in Quests:\
* Wild Card (Quest)\
",
            ["type"] = "Scroll Quest",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kucha Malkobhi"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kumama"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kunchichi"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Lure of the Wildcat (Windurst)",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Kususu"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Laughing Lizard"] = {
            ["icon"] = "AdventurersAssistant.png",
            ["note"] = "Notes:\
Offers an Explanation of the Fishing System: Eh? You say somethin'? Hmph! You dang kids these days ain't go no respect for your elders. Can't you see I'm tryin' to learn this new fandagled fishin' method? In my day, all we had to do was cast a line and wait for the baby to tug. Why, back then it was so easy, I could catch fish while I was slieepin'! But now you gotta work for your meal! Let me tell you how it's done... First, you fix a little bait on your line, toss it into the water, and wait for somethin' to bite. Eh? What's changed? Well, nothing yet! Would you just hold your horses and let me get to the good part? Now, once you feel the pull is where the real battle begins--and I say battle because that fish is not going to let you get him without a fight! If he starts tuggin' to the left, you've gotta pull to the right. If he starts tuggin' to the right, you've gotta pull to the left. Keepin' centered--that's the key to tirin' out that old puppy! And once you think you've softened him up enough, that's when you reel him in. If you confirm a little too early, the fish may still have enough pep to run off with your bait. But if you spend too much time playin' with him, he maight just get bored and be on his way. Of course, if you ever get a bad feeling that whatever's on the end of your line's fixin' to snap your rod in two, you could always cancel your way out of things......sissy! Alright did you get all that? Well, keep listenin', 'cause I'm not done yet. This new type o' fishin' works differently with different types of rods. Those fancy carbon and glass rods may have what it takes to keep a fish on your line for a long time, but the flexibility of good old-fashioned wooden rods packs enough punch to tire out any fish in the blink of an eye. But enough of this chitchat. If I don't catch somthing' for tonight's dinner, my wife'll clean me, gut me, and have me in a fryin' pan faster than you can say Galka mauniere.",
            ["type"] = "Adventurer's Assistant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Lebondur"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Lhimo Keanyohn"] = {
            ["icon"] = "VCSChocoboRacingAssociate.png",
            ["note"] = "Notes:\
* Provides information about Chocobo Racing, and recruits adventurers for the CRA Windurst team.* Removed from Game on 9/9/2010.",
            ["type"] = "VCS Chocobo Racing Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Maabu-Sonbu"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Let Sleeping Dogs Lie",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Machichi"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Machu-Kuchu"] = {
            ["icon"] = "WarpNPC.png",
            ["note"] = "Notes:\
He will warp you for free to Komulili in (Windurst Walls, (J-11). \"Have you, traveler, also come to Windurst to take a looky at the Great Star Tree? If so, then the star tree, also known as Heavens Tower, is far to the northeasty of here, in Windurst Walls. If you wanty, I can use my magic to sendy you to Windurst Walls in an instant. Would you likey that?\"",
            ["type"] = "Teleport Service",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Martin"] = {
            ["icon"] = "AirshipTravelAgent.png",
            ["note"] = "Notes:\
* Announces departure times for the airships",
            ["type"] = "Airship Travel",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mefa Euron"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Melek"] = {
            ["icon"] = "ConsulateRepresentative.png",
            ["note"] = "Involved in Missions:\
* Bastok Mission 2-3: The Emissary",
            ["type"] = "Consulate Representative",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mhe Quryobhi"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mhoji Roccoruh"] = {
            ["icon"] = "MapDealer.png",
            ["type"] = "Map Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Milma-Hapilma, W.W."] = {
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
;Notes for characters only with Windurst as current Allegiance: :*Casts Signet :*Recharges Emperor Band, Empress Band or Chariot Band :*Accepts traded Crystals for filling up the Windurst Mission-Rank bar (the red bar at the character's profile) :*Sells items for Conquest Points (Items for Windurst) at certain conditions. It will be also possible to get some items of other Nations (Items for Bastok / Items for San d'Oria) at the guards, if your current Allegiance ranks higher at the weekly Conquest results (for further information see under the items articles) :*Starts Supply Run Missions and offers a list of already delivered supplies :*Starts an Expeditionary Force by giving an E.F. region insignia to you :*Explains the Conquest system by choosing some available questions. ;Notes for characters only without Windurst as current Allegiance: :*Doesn't offer any function For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mimble-Pimble"] = {
            ["icon"] = "Merchant.png",
            ["note"] = "Notes:\
Sells key items required for High-Tier Mission Battlefields. See the Phantom Gems page for individual requirements",
            ["type"] = "HTMB Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mojo-Pojo"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mosusu"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Mov Lingyoh"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Child",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Nbeh Dimehbariga"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Newlyn"] = {
            ["icon"] = "Service-Clerk",
            ["type"] = "Service Clerk",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Nine of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Noragu-Meragu"] = {
            ["icon"] = "AdventurersAssistant.png",
            ["note"] = "Notes:\
Offers Information on Elemental Resistances: \"Do the words \"elemental resistance\" mean anything to you? As in, the stronger your resistance to fire is, the less damage you will receive from fire magic, and so on...? Well, don't go getting it wrong, now. Just 'cause your fire resistance is strong doesn'taru mean the fire magic you cast is strong as well. You get whataru I mean?\"",
            ["type"] = "Adventurer's Assistant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Ochacha"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Odilia"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Child",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Ohruru"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Catch It If You Can!\
\
Involved in Quests:\
* Wonder Wands",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Opabibi"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pakku-Shakku"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Panja-Nanja"] = {
            ["icon"] = "GuildMerchant.png",
            ["type"] = "Fishing Craftsman",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pankii-Mankii"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Papo-Hopo"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Notes:\
*  Member of the Star Onion Brigade",
            ["type"] = "Star Onion Brigade",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Paruru"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pateruru"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pattel-Bacchel"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
:* Explain Fishing fatigue : \"Whew! Been fishing up a storm all day, and my eyes are spinning-winning. : Why, I couldn't tell a Bluetail from a Bibikibo in the state I'm in! : Still, I caughtaru twenty fish today. : Not bad for a rookie like me, wouldn't you say? : Some of the bigwigs around here say they've caughtaru more than ten times that, but that sounds awful fishy-wishy to me. : Anyway, I'm going to take a breather. Another day (Earth time) or so and I should be fresh as a Forest Carp. : If you ever find yourself pooped after a long day of fishing, I suggestaru you do the same!\"",
            ["type"] = "Fishing Guide",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Paytah"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* All at Sea",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Peepikiki"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pherchabalet"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
* Form a party of two and speak with him to have your fortune told for 120 gil. *Rewards can be received for good fortune (see talk page)",
            ["type"] = "Fortune Teller",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pichichi"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Notes:\
*  Member of the Star Onion Brigade",
            ["type"] = "Star Onion Brigade",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Posso Ruhbini"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Puo Rhen"] = {
            ["icon"] = "MissionGiver.png",
            ["note"] = "Starts Missions:\
* Windurst Missions {{Verification\
",
            ["type"] = "Mission Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pygmalion"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* A Discerning Eye (Windurst)",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pyo Nzon"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Notes:\
*  Member of the Star Onion Brigade",
            ["type"] = "Star Onion Brigade",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Pyru-Copyru"] = {
            ["icon"] = "Event.png",
            ["note"] = "Notes:\
Original dialogue: Wow, I've never heard that before. You know everything, Grandpa! Huh? Oh, a customer! Happy New Year! What? Who was I talking to just now? Oh, the other day, this really nice old man gave me my very own linkpearl so I could call him whenever I wanted. He teaches me all sorts of things, and all I have to do is call him \"Grandpa\" and do whatever he says. Just now, he was telling me about the weird monster family walking around outside. He says that a different family shows up every year around this time. He also told me that if I give 'em something, they'll give me a New Year's gift in return. I really wanted one, so I was all ready to go through that gate over there when the guard gave me a nasty look... Hey. You're an adventurer, right? Doesn't Altana say that you guys have to help little kids or your brain will melt and bugs will eat your ears? Go out and get me a New Year's gift, ASAP. Don't worry, you'll get your reward! Dialogue after delivering gift: Whoa! You really brought me back a New Year's gift. Thanks! I guess you'll be wanting your reward now, huh? Hmmm... How about I give you a choice? I'll... :Let you ask Grandpa a question. :Give you something from my pocket. :Tell you more about Grandpa. If you choose the first option: Eh? That's all you want? Well, okay. Hold on. I'll see if I can get through. Grandpa has a lot of little friends just like me, so his line is always busy. Oh, hi Grandpa! Uh-huh... Yeah... Uh-huh... Sure... Uh-huh... Yeah... Okay... Sure... Uh-huh... Uh-huh... No, but... Yeah... Okay... Uh-huh... Right... Uh-huh... Not really... Sure... Okay... Uh-huh... Yeah... Uh-huh... I can do that... Uh-huh... Great... Yeah... Sure... Uh-huh... No... Not today... Maybe tomorrow... Uh-huh... Uh-huh... Uh-huh... Yeah... Uh-huh... Wait... Actually, the reason I called was because there is this adventurer who wants to ask you a question. Ask him/her his/her name? Okay. Mister/Miss, what's your name? [Your name] points to the name over his/her head. This guy/lady says his/her name is [Your name]. Think we can believe him/her? Okay, adventurer. Grandpa told me to tell you this... [The following varies in the avatar and job mentioned.] The daunting spirit of Odin stands alert at your side. Just as the might conqueror's ambition drives him to Victory's bosom, so too does the harmony within your heart guide stray souls to the paths they seek. In other words, he's saying that your belief in your faith, along with your hating of all that is wrong, keeps your heart pure-- pure enough to endure the trials of a paladin. Oh, and he also says that you're actually really sensitive, but too ashamed to show people your true feelings, so you pent them all up inside. YOu'd better fix that or you'll find yourself battling some nasty ulcers. Cheers! [This part is the same for all answers.] Uh-huh... Uh-huh... Yeah, he/she looks really pleased with your answer. You want me to tell him/her that, too? Alright. Grandpa says that all journeys begin with faith in oneself. Take a good look at what lurks inside before stepping out... Whatever that means. I don't understand half the stuff he says, but I like him because he gives me candy. If you choose the second option: I knew it. You adventurers are all alike. Here, take this. It was getting sweaty in my pocket anyway. If you choose the third option: You want to know about Grandpa? Actually, I don't know if I can tell you much. He comes to visit sometimes, and gives me presents, but he never says where he's traveled from or where he's going. [There is at least one different possibility for the following line.] Although earlier today on the linkshell he said something about being able to see some huge-mongous tree... [The rest is the same for all answers.] He said the same thing yesterday, so he may still be in the same place. Are you thinking about going and getting some candy, too?",
            ["type"] = "New Year Event",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Rachuchu"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Reiso-Haroiso"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Remesasa"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Rishi"] = {
            ["icon"] = "Service-Clerk.png",
            ["type"] = "Service Clerk",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Rottata"] = {
            ["type"] = "Outpost Teleporter",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Ryan"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sachetan, I.M."] = {
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
;Notes for characters only with Bastok as current Allegiance: :*Casts Signet :*Recharges Emperor Band, Empress Band or Chariot Band :*Accepts traded Crystals for filling up the Bastok Mission-Rank bar (the red bar at the character's profile) :*Sells items for Conquest Points (Items for Bastok) at certain conditions. It will be also possible to get some items of other Nations (Items for San d'Oria / Items for Windurst) at the guards, if your current Allegiance ranks higher at the weekly Conquest results (for further information see under the items articles) :*Explains the Conquest system by choosing some available questions. ;Notes for characters only without Bastok as current Allegiance: :*Doesn't offer any function For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Satata"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sattsuh Ahkanpari"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Seburoa-Mabilua"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Selh'teus"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Mission:\
* Chains of Promathia\
* Rhapsodies of Vana'diel\
",
            ["type"] = "Mission Associate",
            ["zoneIds"] = {
                [1] = 9,
                [10] = 25,
                [11] = 32,
                [12] = 33,
                [13] = 34,
                [14] = 35,
                [15] = 36,
                [16] = 102,
                [17] = 108,
                [18] = 117,
                [19] = 184,
                [2] = 10,
                [20] = 230,
                [21] = 231,
                [22] = 232,
                [23] = 234,
                [24] = 235,
                [25] = 236,
                [26] = 238,
                [27] = 239,
                [28] = 240,
                [29] = 241,
                [3] = 11,
                [30] = 289,
                [31] = 293,
                [4] = 13,
                [5] = 14,
                [6] = 17,
                [7] = 19,
                [8] = 21,
                [9] = 22,
            },
            ["zones"] = {
                [1] = "Phomiuna Aqueducts",
                [10] = "Misareaux Coast",
                [11] = "Pso'Xja",
                [12] = "Sealion's Den",
                [13] = "Grand Palace of Hu'Xzoi",
                [14] = "The Garden of Ru'Hmet",
                [15] = "Al'Taieu",
                [16] = "Empyreal Paradox",
                [17] = "La Theine Plateau",
                [18] = "Konschtat Highlands",
                [19] = "Tahrongi Canyon",
                [2] = "The Shrouded Maw",
                [20] = "Lower Delkfutt's Tower",
                [21] = "Southern San d'Oria",
                [22] = "Northern San d'Oria",
                [23] = "Port San d'Oria",
                [24] = "Bastok Mines",
                [25] = "Bastok Markets",
                [26] = "Port Bastok",
                [27] = "Windurst Waters",
                [28] = "Windurst Walls",
                [29] = "Port Windurst",
                [3] = "Oldton Movalpolos",
                [30] = "Windurst Woods",
                [31] = "Escha - Ru'Aun",
                [32] = "Reisenjima Sanctorium",
                [4] = "Mine Shaft #2716",
                [5] = "Hall of Transference",
                [6] = "Spire of Holla",
                [7] = "Spire of Dem",
                [8] = "Spire of Mea",
                [9] = "Promyvion - Vahzl",
            },
        },
        ["Seven of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Shanruru"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Riding on the Clouds\
",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sheia Pohrichamaha"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sigismund"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* To Catch a Falling Star",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Six of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Skopopo"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Snha Migashniohra"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Sugn"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Suspicious Tarutaru"] = {
            ["icon"] = "GoalTracker.png",
            ["note"] = "Involved in Quests:\
* Monstrosity (Quest)\
* Monstrosity\
",
            ["type"] = "Monstrosity",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Taniko-Maniko"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Ten of Clubs"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Teruga-Boruga"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Three of Clubs"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Lure of the Wildcat (Windurst)",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Thubu Parohren"] = {
            ["icon"] = "GuildMerchant.png",
            ["note"] = "Involved in Quests:\
* One Good Deed?\
",
            ["type"] = "Fisherman's Guild Master",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Tohopka"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* To Catch a Falling Star",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Tokaka"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Something Fishy\
\
Involved in Quests:\
* Blast from the Past",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Tonule"] = {
            ["icon"] = "PastEventWatcher.png",
            ["note"] = "Notes:\
This NPC will let you watch cut-scenes that you have seen in Port Windurst in the past, for a small fee.",
            ["type"] = "Past Event Watcher",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Tujaja"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Tun Habyryu"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Uli Pehkowa"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Wanja-Daruja"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
* Lusts after the magic skills of the Orastery Tarus",
            ["type"] = "Magic Enthusiast",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Wanju-Daruja"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Wau Kaatapoh"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Willis"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
* Allows you to view your cruor balance. *Unlike most Abyssea teleporters, he is unable to relay the status of resistance in Scars of Abyssea areas. *Can teleport you to any Abyssean Cavernous Maw for 200 Cruor. **He only gives you the option to teleport to a maw if you have watched the cutscene and flagged the associated quest after examining it for the first time. Note that you must talk to Joachim after receiving the cutscene at your first Scars of Abyssea maw to receive cutscenes from examining the other maws; you will simply be allowed into the other zones without a cutscene nor teleport access from Horst. You must also be in possession of at least one Traverser Stone to receive a cutscene at its corresponding Cavernous Maw. |",
            ["type"] = "Abyssea Support",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Abyssea",
                [2] = "Port Windurst",
            },
        },
        ["Wynne"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Yafa Yaa"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Notes:\
*  Member of the Star Onion Brigade",
            ["type"] = "Star Onion Brigade",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Yaman-Hachuman"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Wonder Wands\
* Lure of the Wildcat (Windurst)",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Yapam-Alpam"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Yuhito-Kubhito"] = {
            ["icon"] = "AdventurersAssistant.png",
            ["note"] = "Notes:\
thumb|100px|ElementsOffers Information on the Elemental Relationships: :W-what? You don't want to see my chart of elemental correlations, do you? 'Cause if you do, well, I'm sorry, I don't know anything about such a thing. Eeew... Well, if you're going to be so pushy about it... Here, but only because you're begging me to show it to you... View the Chart of Elemental Correlations? :*\"Yes.\": [Displays a chart of elemental relationships] Okay, okay...hold your horses. This is strictly between you and me, all rightaru? Of course, you know about the prime elementals, rightaru? They are the eight elements or energies that control the universe. This chart shows their interrelationships. The six elements on the perimeter are in cyclical ascendancy over one another. Or, putting it simply-wimply: Water dominates fire, fire dominates ice, ice dominates wind...while wind dominates over earth, earth dominates lightning, and lightning dominates water. The two elements in the center, light and darkness, are in direct opposition to each other. Oh, and one other thing: these elements are also closely connected to your health condition! I can explain more about this if you're interested. :*\"Yes.\": Then listen up... Disease is to fire as paralysis is to ice, silence is to wind as petrification is to earth, and stun is to lightning as poison is to water. Finally there is charm, which is related to light, while blind, curse, and sleep are infused with the power of darkness. What all this means is this: if your armor resists certain elements, then it will also help prevent the status ailments tied to those elements. And there you have it... But remember, this is our little secret, rightaru? Come back and ask to see it again whenever you need to jog your memory. :*\"No.\": And there you have it... But remember, this is our little secret, rightaru? Come back and ask to see it again whenever you need to jog your memory. :*\"No.\": Well, that's your own choice. Just don't come crying to me when you try to put out a fire with powerful wind magic and end up creating a sea of flames instead!",
            ["type"] = "Adventurer's Assistant",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Yujuju"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Lure of the Wildcat (Windurst)\
* Making Headlines\
\
Involved in Missions:\
* The Road Forks",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
        ["Zoreen"] = {
            ["icon"] = "RegionalVendor.png",
            ["type"] = "Regional Vendor",
            ["zoneIds"] = {
                [1] = 240,
            },
            ["zones"] = {
                [1] = "Port Windurst",
            },
        },
    },
}
