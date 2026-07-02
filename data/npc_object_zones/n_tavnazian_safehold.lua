return {
    ["catseyeItem"] = {
    },
    ["catseyeNpc"] = {
        ["Cassie"] = {
            ["icon"] = "Event.png",
            ["location"] = "Tavnazian Safehold F-10, near the Auction House",
            ["note"] = "Grand Trials:\
* Offers no-cooldown trials to\
augment existing equipment.\
* Only one trial may be active at a\
time; speak to Cassie to cancel.\
* Can transfer NQ augments to HQ\
crafted items after the current\
trial is complete.",
            ["type"] = "Grand Trials",
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Franz"] = {
            ["icon"] = "Event.png",
            ["location"] = "Tavnazian Safehold H-8",
            ["note"] = "CatsEyeXI Augmenting:\
* Augments corresponding Dynamis\
items using Rank Points and stored\
currency.\
* Required currency is deducted\
from Freya, the NPC beside him.\
* Requires the matching essence\
from defeating the Arch zone boss\
once; check with !essences.",
            ["type"] = "Dynamis Augments",
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Freya"] = {
            ["icon"] = "Freya.png",
            ["location"] = "Tavnazian Safehold H-8, beside Franz",
            ["note"] = "CatsEyeXI Augmenting:\
* Stores currency used by Franz for\
Dynamis item augments.\
* Freya does not convert or break\
down currency.\
* Franz deducts the required\
currency from Freya during\
augmentation.",
            ["type"] = "Dynamis Currency Storage",
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
    },
    ["item"] = {
        ["Hieroglyphics"] = {
            ["icon"] = "Hieroglyphics.png",
            ["note"] = "Ancient geometric carvings etched directly into stone monuments. Examining the alien script uncovers historical archives or confirms dimensional travel clearances for Abyssea.",
            ["type"] = "Quest Node",
            ["zoneIds"] = {
                [1] = 26,
                [2] = 103,
                [3] = 118,
                [4] = 126,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Valkurm Dunes",
                [3] = "Buburimu Peninsula",
                [4] = "Qufim Island",
            },
        },
        ["Main Gate"] = {
            ["icon"] = "Door.png",
            ["note"] = "The massive iron-banded fortification gate protecting the safehold. Passing through this towering defensive archway leaves the underground shelter behind to transition you directly into the Lufaise Meadows.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Sewer Entrance"] = {
            ["icon"] = "Door.png",
            ["note"] = "A heavy iron-banded doorway framework locking off the underground aqueduct passages. Passing through this transitional archway leaves the residential sector behind to plunge you directly into the sewer grid.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Walnut Door"] = {
            ["icon"] = "Door.png",
            ["note"] = "A heavy wooden structural barrier partitioning the underground safehold. Turning the iron door handle coordinates your city navigation and uncovers localized story archives.",
            ["type"] = "Security Gate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Wooden Cabinet"] = {
            ["icon"] = "Box.png",
            ["note"] = "A polished wooden furniture piece integrated into the safehold's residential quarters. Searching the drawers uncovers dusty historical archives or updates active expansion side quest journals.",
            ["type"] = "Quest Node",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
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
        ["Aligi-Kufongi"] = {
            ["icon"] = "PastEventWatcher.png",
            ["note"] = "Notes:\
* Will change your Title for a fee or can give you a random title for free. * If you play in an Xbox 360 he will also unlock your achievements. *For a full list of titles you can revert to with this NPC, see Titles.",
            ["type"] = "Traveling Bard",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Angieurol"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Child",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Anteurephiaux"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* The Call of the Sea",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd floor in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Arquil"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Atarefaunet"] = {
            ["icon"] = "MissionNPC.png",
            ["note"] = "Involved in Quests:\
* The Tenshodo Showdown\
* Hitting the Marquisate\
* Signed in Blood\
* Tea with a Tonberry?\
* Apocalypse Nigh\
\
Involved in Missions:\
* San d'Oria Mission 2-3: Infiltrate Davoi\
* Bastok Mission 2-3: The Emissary\
* Promathia Mission 4-4: Slanderous Utterings\
* Promathia Mission 5-1: The Enduring Tumult of War\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance Path)\
* Promathia Mission 6-1: For Whom the Verse is Sung\
* Promathia Mission 6-3: More Questions than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-2: Flames in the Darkness\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 8-1: The Garden of Antiquity\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Mission",
            ["zoneIds"] = {
                [1] = 26,
                [2] = 230,
            },
            ["zones"] = {
                [1] = "Cutscenes only",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Bibokk-Molbukk"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Caiphimonride"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Top level in Tavnazian Safehold at",
            },
        },
        ["Calengeard"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Chemioue"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Petals for Parelbriaux\
\
Involved in Quests:\
* In Search of the Truth\
* Knocking on Forbidden Doors\
",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Cherukiki"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Missions:\
* Promathia Mission 2-1: An Invitation West\
* Promathia Mission 2-2: The Lost City\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-5: Ancient Vows\
* The Road Forks: The Road Forks\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance Path)\
* Promathia Mission 6-2: A Place to Return\
* Promathia Mission 6-3: More Questions than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 7-5: The Warrior's Path\
* Promathia Mission 8-1: The Garden of Antiquity\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Despachiaire"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* X Marks the Spot\
* Elderly Pursuits\
* Tango with a Tracker\
* Requiem of Sin\
\
Involved in Quests:\
* Secrets of Ovens Lost\
\
Involved in Missions:\
* Promathia Mission 2-2: The Lost City\
* Promathia Mission 2-4: An Eternal Melody\
* Promathia Mission 4-1: Sheltering Doubt\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 4-4: Slanderous Utterings\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance Path)\
* Promathia Mission 7-1: Chains and Bonds\
",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Dominec"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Eliot"] = {
            ["icon"] = "AuctionManager.png",
            ["note"] = "Notes:\
* Auction House services will not be available until after completing Darkness Named.",
            ["type"] = "Auction House",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Elysia"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Unforgiven",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Enaremand"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Behind the Smile\
* Knocking on Forbidden Doors",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Epinolle"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Go! Go! Gobmuffin!",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Equette"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* A Bitter Past\
* The Call of the Sea",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Evindigar"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Child",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Fardimant X Boncourge"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Quests:\
* Knocking on Forbidden Doors\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
                [2] = 27,
            },
            ["zones"] = {
                [1] = "Phomiuna Aqueducts",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Ferchinne"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Fly High",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Tavnazian Safehold (First Floor",
            },
        },
        ["Ferocious Artisan"] = {
            ["icon"] = "AuctionManager.png",
            ["note"] = "Notes:\
* Auction House services will not be available until after completing Darkness Named.",
            ["type"] = "Auction House",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Fouagine"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* In Search of the Truth",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd floor in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Frescheque"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* A Bitter Past",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd floor in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Gennoue"] = {
            ["icon"] = "WeatherChecker.png",
            ["note"] = "Notes:\
Reports weather for the following areas: *Tavnazian Archipelago *Riverne - Site #A01 *Riverne - Site #B01",
            ["type"] = "Weather Reporter",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "top floor in Tavnazian Safehold at",
            },
        },
        ["Geuselibel"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Guda"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Havillione"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Ironclad Gorilla"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Jonette"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Secrets of Ovens Lost",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Jovial Rat"] = {
            ["info"] = "This NPC will let you watch cut-scenes that you have seen in the Sealion's Den in the past, for 10 gil. }} {",
            ["note"] = "Notes:\
This NPC will let you watch cut-scenes that you have seen in the Sealion's Den in the past, for 10 gil.",
            ["type"] = "Past Event Watcher",
            ["zones"] = {
                [1] = "Sealion's Den",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Justinius"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Uninvited Guests\
\
Involved in Quests:\
* It's Raining Mannequins!\
\
Involved in Missions:\
* Promathia Mission 2-1: An Invitation West\
* Promathia Mission 2-2: The Lost City\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody\
* Promathia Mission 4-1: Sheltering Doubt\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 4-3: The Secrets of Worship\
* Promathia Mission 7-4: Calm Before the Storm\
",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Kokila"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Komalata"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Korbi-Marobi"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Kukki-Chebukki"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Missions:\
* Promathia Mission 2-1: An Invitation West\
* Promathia Mission 2-2: The Lost City\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-5: Ancient Vows\
* The Road Forks: The Road Forks\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance Path)\
* Promathia Mission 6-2: A Place to Return\
* Promathia Mission 6-3: More Questions than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 7-5: The Warrior's Path\
* Promathia Mission 8-1: The Garden of Antiquity\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Latteaune"] = {
            ["icon"] = "PastEventWatcher.png",
            ["note"] = "Notes:\
This NPC will let you watch cut-scenes that you have seen in the Tavnazian Safehold in the past, for 10 gil.",
            ["type"] = "Past Event Watcher",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Leporaitceau"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* The Call of the Sea",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Liphatte"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Makki-Chebukki"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Missions:\
* Promathia Mission 2-1: An Invitation West\
* Promathia Mission 2-2: The Lost City\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-5: Ancient Vows\
* The Road Forks: The Road Forks\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance Path)\
* Promathia Mission 6-2: A Place to Return\
* Promathia Mission 6-3: More Questions than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 7-5: The Warrior's Path\
* Promathia Mission 8-1: The Garden of Antiquity\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Masis"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Maturiri"] = {
            ["icon"] = "ItemDeliverer.png",
            ["note"] = "Notes:\
* Item delivery services will not be available until after completing Darkness Named.",
            ["type"] = "Item Deliverer",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Mazuro-Oozuro"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Melleupaux"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Top level in Tavnazian Safehold at",
            },
        },
        ["Mengrenaux"] = {
            ["icon"] = "MissionNPC.png",
            ["note"] = "Involved in Missions:\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody",
            ["type"] = "Mission Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Meret"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Notes:\
Sea Gods item acquisition. You must complete her friend Yurim's quest, In the Name of Science, before Meret will accept any trades. Absolute Virtue * Futsuno Mitama * Aureole * Raphael's Rod * Ninurta's Sash * Mars's Ring * Bellona's Ring * Minerva's Ring Jailer of Love *Novio Earring *Novia Earring Ix'aern (MNK) * Merciful Cape Ix'aern (DRK) *Altruistic Cape Ix'aern (DRG) *Astute Cape Virtue Stone Pouch * Aern Organ * Euvhi Organ * Hpemde Organ * Phuabo Organ * Xzomit Organ * Yovra Organ * Luminion Chip * Luminian Tissue",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Top level in Tavnazian Safehold at",
            },
        },
        ["Merol"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Migran"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Mildaurion"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Mission:\
* Chains of Promathia\
",
            ["type"] = "Mission Associate",
            ["zoneIds"] = {
                [1] = 24,
                [2] = 25,
                [3] = 26,
                [4] = 28,
                [5] = 36,
                [6] = 244,
            },
            ["zones"] = {
                [1] = "Lufaise Meadows",
                [2] = "Misareaux Coast",
                [3] = "Tavnazian Safehold",
                [4] = "Sacrarium",
                [5] = "Empyreal Paradox",
                [6] = "Upper Jeuno",
            },
        },
        ["Misseulieu"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Morangeart"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Starts Quests:\
* Bad Seed\
* Fire in the Sky\
* Bugard in the Clouds\
* Beloved of the Atlantes",
            ["type"] = "ENM Quest",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Nag'molada"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Mission:\
* Chains of Promathia\
",
            ["type"] = "Mission Associate",
            ["zoneIds"] = {
                [1] = 9,
                [10] = 25,
                [11] = 26,
                [12] = 27,
                [13] = 30,
                [14] = 31,
                [15] = 32,
                [16] = 33,
                [17] = 34,
                [18] = 35,
                [19] = 36,
                [2] = 13,
                [20] = 80,
                [21] = 84,
                [22] = 89,
                [23] = 98,
                [24] = 111,
                [25] = 175,
                [26] = 184,
                [27] = 243,
                [28] = 244,
                [29] = 245,
                [3] = 14,
                [4] = 17,
                [5] = 19,
                [6] = 21,
                [7] = 22,
                [8] = 23,
                [9] = 24,
            },
            ["zones"] = {
                [1] = "Phomiuna Aqueducts",
                [10] = "Misareaux Coast",
                [11] = "Tavnazian Safehold",
                [12] = "Sealion's Den",
                [13] = "Pso'Xja",
                [14] = "Monarch Linn",
                [15] = "Hall of Transference",
                [16] = "Grand Palace of Hu'Xzoi",
                [17] = "The Garden of Ru'Hmet",
                [18] = "Al'Taieu",
                [19] = "Empyreal Paradox",
                [2] = "Mine Shaft #2716",
                [20] = "Southern San d'Oria [S]",
                [21] = "Batallia Downs [S]",
                [22] = "Grauberg [S]",
                [23] = "Sauromugue Champaign [S]",
                [24] = "Beaucedine Glacier",
                [25] = "The Eldieme Necropolis [S]",
                [26] = "Lower Delkfutt's Tower",
                [27] = "Ru'Lude Gardens",
                [28] = "Upper Jeuno",
                [29] = "Lower Jeuno",
                [3] = "Riverne - Site #A01",
                [4] = "Spire of Holla",
                [5] = "Spire of Dem",
                [6] = "Spire of Mea",
                [7] = "Spire of Vahzl",
                [8] = "Promyvion - Vahzl",
                [9] = "Lufaise Meadows",
            },
        },
        ["Nery"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Nilerouche"] = {
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Nivorajean"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* Paradise, Salvation, and Maps",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Noam"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* In Search of the Truth",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Odeya"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* X Marks the Spot",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Ombelotte"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quest:\
* An Uninvited Guest\
* In the Mood for Love\
",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Ondieulix"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* In Search of the Truth\
* Petals for Parelbriaux",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Tavnazian Safehold Ground Level",
            },
        },
        ["Owain"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Starts Quests:\
* Tavnazian Terrors\
* Bibiki Bombardment\
",
            ["type"] = "Voidwatch",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Parelbriaux"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* X Marks the Spot\
* Petals for Parelbriaux\
\
Involved in Missions:\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody\
* Promathia Mission 4-3: The Secrets of Worship",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
                [2] = "Tavnazian Safehold Upper Level",
            },
        },
        ["Pradiulot"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* Unforgiven",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Prishe"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Quests:\
* Storms of Fate\
* Apocalypse Nigh\
* VW Op. 026: Tavnazian Terrors\
* VW Op. 004: Bibiki Bombardment\
* A Chocobo's Tale\
* In the Mood for Love\
* Hook, Line, and Sinker\
\
Involved in Missions:\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody\
* Promathia Mission 2-5: Ancient Vows\
* Promathia Mission 3-1: Call of the Wyrmking\
* Promathia Mission 3-2: Vessel Without a Captain\
* Promathia Mission 3-5: Darkness Named\
* Promathia Mission 4-1: Sheltering Doubt\
* Promathia Mission 4-3: The Secrets of Worship\
* Promathia Mission 4-4: Slanderous Utterings\
* Promathia Mission 5-1: The Enduring Tumult of War\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Where Messengers Gather (Ulmia's Path)\
* Promathia Mission 6-1: For Whom the Verse is Sung\
* Promathia Mission 6-3: More Questions Than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-2: Flames in the Darkness\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 7-5: The Warrior's Path\
* Promathia Mission 8-2: A Fate Decided\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Battle",
                [2] = "Cutscene",
                [3] = "Tavnazian Safehold",
            },
        },
        ["Quelveuiat"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* A Hard Day's Knight\
\
Involved in Quests:\
* The Search for Goldmane\
",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Raminey"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* A Bitter Past\
* In Search of the Truth",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd floor in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Ratonne"] = {
            ["icon"] = "ArmorStorer.png",
            ["note"] = "Notes:\
Stores lvl 24-60 AF, Relic, RSE and other gearsets.",
            ["type"] = "Armor Depository",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Main level in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Reaugettie"] = {
            ["icon"] = "Defender.png",
            ["type"] = "Defender",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Resauchamet"] = {
            ["icon"] = "Dialogue.png",
            ["note"] = "Notes:\
:Provides information about a character's Fomor Hate level. :\"You are an adventurer... I can smell the dark blood of the undead as it drips slowly from your soiled garments. Beware, my friend, for you are not alone in your journey. Lost spirits lurk in the shadows behind you, waiting for their chance to rob you of your soul. Hmmm...\" :1) \"You still have a fairly good head start, but they will not let up until they have found you and filled your heart with poison and pain.? :Fomors will not aggro. :2) ?They are close, It is only a matter of time before you have fallen within their reach.\" :Fomors will aggro. :3) \"Can you not feel the hands that reach up from the bottomless depths of hell? Can you not feel the gaze of a thousand eyes, glowing red with anger and hate?\" :Fomors will aggro. :4) \"The grip of evil is tightening on the very essence of what makes you who you are. Be forewarned, as it will not be long before you are confronted with a battle for more than just your life.\" :Fomors will aggro. \"Oh, poor child! May the light of the Dawn Goddess lead you from the pitch-black depths of darkness!\"",
            ["type"] = "Fomor Informant",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Risunela"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Senior Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Senvaleget"] = {
            ["icon"] = "AuctionManager.png",
            ["note"] = "Notes:\
* Auction House services will not be available until after completing Darkness Named.",
            ["type"] = "Auction House",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Shemmie"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Sueleen"] = {
            ["icon"] = "QuestNPC.png",
            ["note"] = "Involved in Missions:\
* Promathia Mission 7-2: Flames in the Darkness\
* Promathia Mission 7-4: Calm Before the Storm\
",
            ["type"] = "Quest NPC",
            ["zones"] = {
                [1] = "Sealion's Den",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Suzel"] = {
            ["icon"] = "ItemDeliverer.png",
            ["note"] = "Notes:\
* Item delivery services will not be available until after completing Darkness Named.",
            ["type"] = "Item Deliverer",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Swikastoq"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Tiruru"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Travonce"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* The Big One",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Tressia"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* In Search of the Truth\
* Petals for Parelbriaux\
\
Involved in Missions:\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "3rd floor in Tavnazian Safehold at",
                [2] = "Tavnazian Safehold",
            },
        },
        ["Ulmia"] = {
            ["icon"] = "Cutscene.png",
            ["note"] = "Involved in Quests:\
* Storms of Fate\
* Apocalypse Nigh\
\
Involved in Missions:\
* Promathia Mission 2-3: Distant Beliefs\
* Promathia Mission 2-4: An Eternal Melody\
* Promathia Mission 2-5: Ancient Vows\
* The Road Forks: The Road Forks\
* Promathia Mission 3-4: Tending Aged Wounds\
* Promathia Mission 3-5: Darkness Named\
* Promathia Mission 4-1: Sheltering Doubt\
* Promathia Mission 4-2: The Savage\
* Promathia Mission 4-3: The Secrets of Worship\
* Promathia Mission 4-4: Slanderous Utterings\
* Promathia Mission 5-1: The Enduring Tumult of War\
* Promathia Mission 5-2: Desires of Emptiness\
* Promathia Mission 5-3: Three Paths\
* Past Sins (Louverance's Path)\
* The Pursuit of Paradise (Tenzen's Path)\
* Where Messengers Gather (Ulmia's Path)\
* Promathia Mission 6-1: For Whom the Verse is Sung\
* Promathia Mission 6-2: A Place to Return\
* Promathia Mission 6-3: More Questions Than Answers\
* Promathia Mission 6-4: One to be Feared\
* Promathia Mission 7-1: Chains and Bonds\
* Promathia Mission 7-2: Flames in the Darkness\
* Promathia Mission 7-3: Fire in the Eyes of Men\
* Promathia Mission 7-4: Calm Before the Storm\
* Promathia Mission 7-5: The Warrior's Path\
* Promathia Mission 8-1: The Garden of Antiquity\
* Promathia Mission 8-2: A Fate Decided\
* Promathia Mission 8-3: When Angels Fall\
* Promathia Mission 8-4: Dawn\
",
            ["type"] = "Cutscene NPC",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Wazozo"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Yasuji"] = {
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Yurim"] = {
            ["icon"] = "QuestGiver.png",
            ["note"] = "Starts Quests:\
* In the Name of Science",
            ["type"] = "Quest Giver",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
        ["Zadant"] = {
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* In Search of the Truth",
            ["type"] = "Quest Associate",
            ["zoneIds"] = {
                [1] = 26,
            },
            ["zones"] = {
                [1] = "Tavnazian Safehold",
            },
        },
    },
}
