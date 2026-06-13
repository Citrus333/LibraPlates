local itemIcons = T{

    ['!'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Davoi' },
        zoneIds = { 149 },
        note = 'Needs Review.',
    },

    ['???'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Empyreal Paradox', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Altar Room', 'Alzadaal Undersea Ruins', 'Apollyon', 'Arrapago Reef', 'Attohwa Chasm', 'Aydeewa Subterrane', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Batallia Downs', 'Batallia Downs [S]', 'Beadeaux', 'Beadeaux [S]', 'Bearclaw Pinnacle', 'Beaucedine Glacier', 'Beaucedine Glacier [S]', 'Behemoth\\'s Dominion', 'Bhaflau Thickets', 'Bibiki Bay', 'Boneyard Gully', 'Bostaunieux Oubliette', 'Buburimu Peninsula', 'Caedarva Mire', 'Cape Teriggan', 'Carpenters\\' Landing', 'Castle Oztroja', 'Castle Oztroja [S]', 'Castle Zvahl Baileys', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Celennia Memorial Library', 'Chamber of Oracles', 'Chateau d\\'Oraguille', 'Chocobo Circuit', 'Cirdas Caverns', 'Cloister of Flames', 'Cloister of Frost', 'Cloister of Gales', 'Cloister of Storms', 'Cloister of Tides', 'Cloister of Tremors', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Dangruf Wadi', 'Davoi', 'Den of Rancor', 'Desuetia - Empyreal Paradox', 'Dho Gates', 'Diorama Abdhaljs-Ghelsba', 'Dragon\\'s Aery', 'Dynamis - Bastok', 'Dynamis - Beaucedine', 'Dynamis - Buburimu', 'Dynamis - Jeuno', 'Dynamis - Qufim', 'Dynamis - San d\\'Oria', 'Dynamis - Tavnazia', 'Dynamis - Valkurm', 'Dynamis - Windurst', 'Dynamis - Xarcabard', 'East Ronfaure', 'East Ronfaure [S]', 'East Sarutabaruta', 'Eastern Adoulin', 'Eastern Altepa Desert', 'Empyreal Paradox', 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah', 'Everbloom Hollow', 'Fei\\'Yin', 'Foret de Hennetiel', 'Fort Karugo-Narugo [S]', 'Full Moon Fountain', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Ghelsba Outpost', 'Ghoyu\\'s Reverie', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Grauberg [S]', 'Gusgen Mines', 'Gustav Tunnel', 'Hall of The Gods', 'Hall of Transference', 'Halvung', 'Hazhalm Testing Grounds', 'Heavens Tower', 'Horlais Peak', 'Ifrit\\'s Cauldron', 'Ilrusi Atoll', 'Inner Horutoto Ruins', 'Jade Sepulcher', 'Jugner Forest', 'Jugner Forest [S]', 'Kamihr Drifts', 'Kazham', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Korroloka Tunnel', 'Kuftal Tunnel', 'La Theine Plateau', 'La Vaule [S]', 'Labyrinth of Onzozo', 'Leafallia', 'Leujaoam Sanctum', 'Lower Delkfutt\\'s Tower', 'Lower Jeuno', 'Lufaise Meadows', 'Mamook', 'Marjami Ravine', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Metalworks', 'Mhaura', 'Middle Delkfutt\\'s Tower', 'Mine Shaft #2716', 'Misareaux Coast', 'Mog Garden', 'Moh Gates', 'Monarch Linn', 'Monastic Cavern', 'Morimar Basalt Fields', 'Mount Kamihr', 'Mount Zhayolm', 'Nashmau', 'Navukgo Execution Chamber', 'Newton Movalpolos', 'Norg', 'North Gustaberg', 'North Gustaberg [S]', 'Northern San d\\'Oria', 'Nyzul Isle', 'Oldton Movalpolos', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Outer Ra\\'Kaznar', 'Palborough Mines', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Phomiuna Aqueducts', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Promyvion - Dem', 'Promyvion - Holla', 'Promyvion - Mea', 'Promyvion - Vahzl', 'Provenance', 'Pso\\'Xja', 'Qu\\'Bia Arena', 'Qufim Island', 'Quicksand Caves', 'Qulun Dome', 'Ra\\'Kaznar Inner Court', 'Ra\\'Kaznar Turris', 'Rabao', 'Rala Waterways', 'Ranguemont Pass', 'Reisenjima', 'Reisenjima Sanctorium', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Ruhotz Silvermines', 'Sacrarium', 'Sacrificial Chamber', 'San d\\'Oria - Jeuno Airship', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'Sea Serpent Grotto', 'Sealion\\'s Den', 'Selbina', 'Sih Gates', 'South Gustaberg', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Spire of Dem', 'Spire of Holla', 'Spire of Mea', 'Spire of Vahzl', 'Stellar Fulcrum', 'Tahrongi Canyon', 'Talacca Cove', 'Tavnazian Safehold', 'Temenos', 'Temple of Uggalepih', 'The Ashu Talif', 'The Boyahda Tree', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Garden of Ru\\'Hmet', 'The Sanctuary of Zi\\'Tah', 'The Shrine of Ru\\'Avitau', 'Throne Room', 'Throne Room [S]', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Valkurm Dunes', 'Valley of Sorrows', 'Ve\\'Lugannon Palace', 'Vunkerl Inlet [S]', 'Wajaom Woodlands', 'Walk of Echoes', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Adoulin', 'Western Altepa Desert', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Woh Gates', 'Xarcabard', 'Xarcabard [S]', 'Yahse Hunting Grounds', 'Yhoator Jungle', 'Yorcia Weald', 'Yughott Grotto', 'Yuhtunga Jungle' },
        zoneIds = { 2, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 45, 48, 50, 51, 52, 53, 54, 55, 57, 60, 61, 62, 64, 65, 67, 68, 69, 70, 72, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 132, 134, 135, 136, 137, 138, 139, 140, 142, 143, 145, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 163, 164, 165, 166, 167, 168, 169, 170, 171, 173, 174, 175, 176, 177, 178, 179, 182, 184, 185, 186, 187, 188, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 211, 212, 213, 215, 216, 217, 218, 222, 223, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 260, 261, 262, 263, 265, 266, 267, 268, 269, 270, 272, 273, 274, 276, 277, 280, 281, 282, 284, 288, 289, 290, 291, 293 },
        note = 'Needs Review.',
    },

    ['Adder Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Batallia Downs [S]', 'Beadeaux [S]', 'Beaucedine Glacier [S]', 'Castle Oztroja [S]', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Crawlers\\' Nest [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'La Vaule [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Southern San d\\'Oria [S]', 'The Eldieme Necropolis [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Windurst Waters [S]', 'Xarcabard [S]' },
        zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
        note = 'Needs Review.',
    },

    ['Apkallu Guide'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef' },
        zoneIds = { 54 },
        note = 'Needs Review.',
    },

    ['Apollyon Coffer #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Apollyon' },
        zoneIds = { 38 },
        note = 'Needs Review.',
    },

    ['Apollyon Coffer #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Apollyon' },
        zoneIds = { 38 },
        note = 'Needs Review.',
    },

    ['Apollyon Coffer #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Apollyon' },
        zoneIds = { 38 },
        note = 'Needs Review.',
    },

    ['Apollyon Coffer #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Apollyon' },
        zoneIds = { 38 },
        note = 'Needs Review.',
    },

    ['Apollyon Furnace'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Apollyon' },
        zoneIds = { 38 },
        note = 'Needs Review.',
    },

    ['Auction Counter'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Bastok Markets', 'Bastok Mines', 'Eastern Adoulin', 'Lower Jeuno', 'Port San d\\'Oria', 'Ru\\'Lude Gardens', 'Southern San d\\'Oria', 'Western Adoulin', 'Windurst Walls', 'Windurst Woods' },
        zoneIds = { 50, 230, 232, 234, 235, 239, 241, 243, 245, 256, 257 },
        note = 'Needs Review.',
    },

    ['Aurum Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Bison Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Batallia Downs [S]', 'Beadeaux [S]', 'Beaucedine Glacier [S]', 'Castle Oztroja [S]', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Crawlers\\' Nest [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'La Vaule [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Southern San d\\'Oria [S]', 'The Eldieme Necropolis [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Windurst Waters [S]', 'Xarcabard [S]' },
        zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
        note = 'Needs Review.',
    },

    ['Black Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['BOX'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Phomiuna Aqueducts' },
        zoneIds = { 27 },
        note = 'Needs Review.',
    },

    ['BOX2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens', 'Spire of Vahzl' },
        zoneIds = { 23, 243 },
        note = 'Needs Review.',
    },

    ['Burning Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Balga\\'s Dais', 'Horlais Peak', 'Qu\\'Bia Arena', 'Waughroon Shrine' },
        zoneIds = { 139, 144, 146, 206 },
        note = 'Needs Review.',
    },

    ['Capacious Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie', 'Ruhotz Silvermines' },
        zoneIds = { 93, 129 },
        note = 'Needs Review.',
    },

    ['Casket'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Western Altepa Desert', 'Yhoator Jungle', 'Yuhtunga Jungle' },
        zoneIds = { 123, 124, 125 },
        note = 'Needs Review.',
    },

    ['Casket #A1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #A2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #B1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #B2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #C1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #C2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #D1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #D2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #E1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #E2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #F1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #F2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #G1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #G2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #H1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Casket #H2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Castoff Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Cirdas Caverns', 'Foret de Hennetiel', 'Morimar Basalt Fields', 'Sih Gates', 'Yahse Hunting Grounds' },
        zoneIds = { 260, 262, 265, 268, 270 },
        note = 'Needs Review.',
    },

    ['Cavernous Maw'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Empyreal Paradox', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Batallia Downs', 'Batallia Downs [S]', 'Buburimu Peninsula', 'East Ronfaure', 'East Ronfaure [S]', 'Grauberg [S]', 'Jugner Forest', 'Jugner Forest [S]', 'Konschtat Highlands', 'La Theine Plateau', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'North Gustaberg', 'North Gustaberg [S]', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'South Gustaberg', 'Tahrongi Canyon', 'Valkurm Dunes', 'Walk of Echoes', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Xarcabard', 'Xarcabard [S]' },
        zoneIds = { 15, 45, 81, 82, 84, 88, 89, 90, 91, 95, 97, 98, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 112, 115, 117, 118, 119, 120, 132, 137, 182, 215, 216, 217, 218, 253, 254, 255 },
        note = 'Needs Review.',
    },

    ['Celebratory Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille', 'Heavens Tower', 'Metalworks' },
        zoneIds = { 233, 237, 242 },
        note = 'Needs Review.',
    },

    ['Center Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Cermet Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Fei\\'Yin', 'Grand Palace of Hu\\'Xzoi', 'The Garden of Ru\\'Hmet' },
        zoneIds = { 34, 35, 204 },
        note = 'Needs Review.',
    },

    ['Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Maze of Shakhrami', 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 133, 189, 198, 275, 279, 298 },
        note = 'Needs Review.',
    },

    ['Chest #A1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #A2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #A3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #A4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #A5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #B1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #B2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #B3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #B4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #B5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #C1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #C2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #C3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #C4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #C5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #D1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #D2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #D3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #D4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #D5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #E'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #F'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #G'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Chest #H'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Clamming Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bibiki Bay' },
        zoneIds = { 4 },
        note = 'Needs Review.',
    },

    ['Coal Casket'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Uleguerand' },
        zoneIds = { 253 },
        note = 'Needs Review.',
    },

    ['Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mamool Ja Training Grounds', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 66, 279, 298 },
        note = 'Needs Review.',
    },

    ['Coffer #A'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #B'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #C'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #D'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #E'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #F'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #G'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Coffer #H'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Colossal Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Beaucedine Glacier [S]' },
        zoneIds = { 136 },
        note = 'Needs Review.',
    },

    ['Compact Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Conflux Surveyor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl' },
        zoneIds = { 15, 45, 132, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Coteaulepoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Batallia Downs', 'Chateau d\\'Oraguille' },
        zoneIds = { 105, 233 },
        note = 'Needs Review.',
    },

    ['Coyote Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Batallia Downs [S]', 'Beadeaux [S]', 'Beaucedine Glacier [S]', 'Castle Oztroja [S]', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Crawlers\\' Nest [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'La Vaule [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Southern San d\\'Oria [S]', 'The Eldieme Necropolis [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Windurst Waters [S]', 'Xarcabard [S]' },
        zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
        note = 'Needs Review.',
    },

    ['Dhole Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Batallia Downs [S]', 'Beadeaux [S]', 'Beaucedine Glacier [S]', 'Castle Oztroja [S]', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Crawlers\\' Nest [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'La Vaule [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Southern San d\\'Oria [S]', 'The Eldieme Necropolis [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Windurst Waters [S]', 'Xarcabard [S]' },
        zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
        note = 'Needs Review.',
    },

    ['Dimensional Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Al\\'Taieu', 'Desuetia - Empyreal Paradox', 'Eastern Altepa Desert', 'Empyreal Paradox', 'Jugner Forest [S]', 'Konschtat Highlands', 'La Theine Plateau', 'Meriphataud Mountains [S]', 'Pashhow Marshlands [S]', 'Reisenjima', 'Tahrongi Canyon', 'Xarcabard', 'Yhoator Jungle' },
        zoneIds = { 33, 36, 82, 90, 97, 102, 108, 112, 114, 117, 124, 290, 291 },
        note = 'Needs Review.',
    },

    ['Door'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Open Sea Route to Al Zahbi', 'Open Sea Route to Mhaura', 'Qulun Dome', 'Ship Bound for Mhaura', 'Ship Bound for Mhaura (Pirates)', 'Ship Bound for Selbina', 'Ship Bound for Selbina (Pirates)', 'Silver Sea Route to Al Zahbi', 'Silver Sea Route to Nashmau' },
        zoneIds = { 46, 47, 48, 50, 58, 59, 148, 220, 221, 227, 228 },
        note = 'Needs Review.',
    },

    ['Door Lion"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria [S]' },
        zoneIds = { 80 },
        note = 'Needs Review.',
    },

    ['Door Lock#1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Door Lock#2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Door Lock#3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Door Lock#4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['door_00'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_01'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_02'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_03'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_04'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_05'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_06'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_07'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_08'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_09'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_09i'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09j'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09k'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09l'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09m'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09n'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09o'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09p'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09q'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09s'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09t'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09u'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09v'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09w'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09x'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09y'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_09z'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['Door_0rc'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Phomiuna Aqueducts' },
        zoneIds = { 27 },
        note = 'Needs Review.',
    },

    ['Door_0rd'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Phomiuna Aqueducts' },
        zoneIds = { 27 },
        note = 'Needs Review.',
    },

    ['Door_0rk'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Phomiuna Aqueducts' },
        zoneIds = { 27 },
        note = 'Needs Review.',
    },

    ['Door_0rl'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Phomiuna Aqueducts' },
        zoneIds = { 27 },
        note = 'Needs Review.',
    },

    ['Door_0sb'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sc'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sd'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0se'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sf'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sg'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sh'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0si'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sj'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sk'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sl'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sm'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sn'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0so'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sp'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sq'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0sr'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0ss'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['Door_0su'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Sacrarium' },
        zoneIds = { 28 },
        note = 'Needs Review.',
    },

    ['door_10'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['door_11'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['Door_1ea'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door_1eb'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door_1ec'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door_1ed'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door_1g3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bhaflau Thickets' },
        zoneIds = { 52 },
        note = 'Needs Review.',
    },

    ['Door_1g4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bhaflau Thickets' },
        zoneIds = { 52 },
        note = 'Needs Review.',
    },

    ['Door_1h0'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Nashmau' },
        zoneIds = { 53 },
        note = 'Needs Review.',
    },

    ['Door_1h1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Nashmau' },
        zoneIds = { 53 },
        note = 'Needs Review.',
    },

    ['door_1i0'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef' },
        zoneIds = { 54 },
        note = 'Needs Review.',
    },

    ['door_1i1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef' },
        zoneIds = { 54 },
        note = 'Needs Review.',
    },

    ['Door_1k1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1k9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ka'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kb'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kc'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kd'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ke'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kf'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kg'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kh'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ki'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kj'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kk'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kl'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1km'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kn'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ko'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kp'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kq'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kr'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ks'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kt'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1ku'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kv'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1kw'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Periqia' },
        zoneIds = { 56 },
        note = 'Needs Review.',
    },

    ['Door_1p4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mount Zhayolm' },
        zoneIds = { 61 },
        note = 'Needs Review.',
    },

    ['Door_1z0'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1z9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1za'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zb'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zc'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zd'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1ze'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zf'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zg'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zh'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zi'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zj'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zk'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zl'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zm'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zn'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zo'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zp'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zq'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zr'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zs'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zt'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zu'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zv'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zw'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zx'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zy'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_1zz'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Norg' },
        zoneIds = { 252 },
        note = 'Needs Review.',
    },

    ['Door_276'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Caedarva Mire' },
        zoneIds = { 79 },
        note = 'Needs Review.',
    },

    ['Door_277'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Caedarva Mire' },
        zoneIds = { 79 },
        note = 'Needs Review.',
    },

    ['Door_278'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Caedarva Mire' },
        zoneIds = { 79 },
        note = 'Needs Review.',
    },

    ['Door_279'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Caedarva Mire' },
        zoneIds = { 79 },
        note = 'Needs Review.',
    },

    ['Door_3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Full Moon Fountain', 'Heavens Tower', 'Windurst Waters [S]' },
        zoneIds = { 94, 170, 242 },
        note = 'Needs Review.',
    },

    ['Door_5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Door_7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door_8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door_a'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door_b'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door_c'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['door_i90'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i91'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i92'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i93'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i9o'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i9p'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['door_i9q'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Pso\\'Xja' },
        zoneIds = { 9 },
        note = 'Needs Review.',
    },

    ['Door_jz0'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jz9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jza'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jzb'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['Door_jzc'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Colosseum' },
        zoneIds = { 71 },
        note = 'Needs Review.',
    },

    ['door_master'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Everbloom Hollow', 'Ghoyu\\'s Reverie', 'Ilrusi Atoll', 'Lebros Cavern', 'Leujaoam Sanctum', 'Mamool Ja Training Grounds', 'Newton Movalpolos', 'Periqia', 'Ruhotz Silvermines' },
        zoneIds = { 12, 55, 56, 63, 66, 69, 86, 93, 129 },
        note = 'Needs Review.',
    },

    ['Door_Rock'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kuftal Tunnel' },
        zoneIds = { 174 },
        note = 'Needs Review.',
    },

    ['Door:'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Eastern Adoulin' },
        zoneIds = { 257 },
        note = 'Needs Review.',
    },

    ['Door: Automaton Workshop'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door: Back to Town'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Celennia Memorial Library' },
        zoneIds = { 284 },
        note = 'Needs Review.',
    },

    ['Door: Boarding House'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Eastern Adoulin' },
        zoneIds = { 257 },
        note = 'Needs Review.',
    },

    ['Door: Cargo Hold'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Ashu Talif' },
        zoneIds = { 60 },
        note = 'Needs Review.',
    },

    ['Door: Chamber of Passage'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door: Commissions Agency'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door: Depository'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Western Adoulin' },
        zoneIds = { 256 },
        note = 'Needs Review.',
    },

    ['Door: Great Cabin'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Ashu Talif' },
        zoneIds = { 60 },
        note = 'Needs Review.',
    },

    ['Door: Kokba Hostel'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door: Walahra Temple'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Door:"Bat\\'s Lair"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines' },
        zoneIds = { 234 },
        note = 'Needs Review.',
    },

    ['Door:"Dragon\\'s Claws"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:"Durable Shields"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Upper Jeuno' },
        zoneIds = { 244 },
        note = 'Needs Review.',
    },

    ['Door:"Goblins\\' Goblet"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:"Lion Springs"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]' },
        zoneIds = { 80, 230 },
        note = 'Needs Review.',
    },

    ['Door:"Marble Bridge"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Upper Jeuno' },
        zoneIds = { 244 },
        note = 'Needs Review.',
    },

    ['Door:"Merry Minstrel"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:"Neptune\\'s Spire"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:"Phoenix Perch"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:"Rarab Tail"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:"Rusty Anchor"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port San d\\'Oria' },
        zoneIds = { 232 },
        note = 'Needs Review.',
    },

    ['Door:"Sailors\\' Stay"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mhaura' },
        zoneIds = { 249 },
        note = 'Needs Review.',
    },

    ['Door:"Steaming Sheep"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok' },
        zoneIds = { 236 },
        note = 'Needs Review.',
    },

    ['Door:"Timbre Timbers"'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Acolyte hostel'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters', 'Windurst Waters [S]' },
        zoneIds = { 94, 238 },
        note = 'Needs Review.',
    },

    ['Door:Aide\\'s Office'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Alchemists\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines' },
        zoneIds = { 234 },
        note = 'Needs Review.',
    },

    ['Door:Aldo\\'s Room'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Archduke\\'s House'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Arrivals Entrance'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst' },
        zoneIds = { 232, 236, 240, 246 },
        note = 'Needs Review.',
    },

    ['Door:Arrivals Exit'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst' },
        zoneIds = { 232, 236, 240, 246 },
        note = 'Needs Review.',
    },

    ['Door:Audience Chamber'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Ru\\'Lude Gardens' },
        zoneIds = { 237, 243 },
        note = 'Needs Review.',
    },

    ['Door:Aurastery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Baren-Moren Hatter'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Bastokan Consul'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria', 'Port Windurst' },
        zoneIds = { 231, 240 },
        note = 'Needs Review.',
    },

    ['Door:Bastokan Emb.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Bedchamber'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Blacksmiths\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Mhaura', 'Northern San d\\'Oria' },
        zoneIds = { 231, 237, 249 },
        note = 'Needs Review.',
    },

    ['Door:Boneworkers\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Woods' },
        zoneIds = { 241 },
        note = 'Needs Review.',
    },

    ['Door:Boytz\\'s Knickknacks'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines' },
        zoneIds = { 234 },
        note = 'Needs Review.',
    },

    ['Door:Brunhilde Armourer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:Cannonry'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Cargo Room A'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port San d\\'Oria' },
        zoneIds = { 232 },
        note = 'Needs Review.',
    },

    ['Door:Cargo Room B'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port San d\\'Oria' },
        zoneIds = { 232 },
        note = 'Needs Review.',
    },

    ['Door:Carmelide\\'s Jewelry'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:Carpenters\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:Celodehki\\'s B&B'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:Cermet Refinery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Chamber of Commerce'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Chocobo Stables'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines', 'Lower Jeuno', 'Port Jeuno', 'Southern San d\\'Oria', 'Upper Jeuno', 'Windurst Woods' },
        zoneIds = { 230, 234, 241, 244, 245, 246 },
        note = 'Needs Review.',
    },

    ['Door:Cid\\'s Lab'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Metalworks' },
        zoneIds = { 87, 237 },
        note = 'Needs Review.',
    },

    ['Door:Clerical Chamber'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Heavens Tower', 'West Sarutabaruta [S]' },
        zoneIds = { 95, 242 },
        note = 'Needs Review.',
    },

    ['Door:Conference Room'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Cornelia\\'s Room'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Count\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Craftsmen\\'s Eatery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Culinarians\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Darksteel Forge'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Deegis\\'s Armour'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines' },
        zoneIds = { 234 },
        note = 'Needs Review.',
    },

    ['Door:Departures Entrance'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst' },
        zoneIds = { 232, 236, 240, 246 },
        note = 'Needs Review.',
    },

    ['Door:Departures Exit'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst' },
        zoneIds = { 232, 236, 240, 246 },
        note = 'Needs Review.',
    },

    ['Door:Dept. of Industry'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Dining Hall'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Doctor\\'s Residence'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Windurst' },
        zoneIds = { 240 },
        note = 'Needs Review.',
    },

    ['Door:Ensasa\\'s Catalysts'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Federal Magic Res.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Fishermen\\'s Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Selbina' },
        zoneIds = { 248 },
        note = 'Needs Review.',
    },

    ['Door:Galvin\\'s Gear'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok' },
        zoneIds = { 236 },
        note = 'Needs Review.',
    },

    ['Door:Gems by Kshama'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Goddess Temple'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Upper Jeuno' },
        zoneIds = { 244 },
        note = 'Needs Review.',
    },

    ['Door:Goldsmiths\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets', 'Mhaura' },
        zoneIds = { 235, 249 },
        note = 'Needs Review.',
    },

    ['Door:Governor\\'s House'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mhaura' },
        zoneIds = { 249 },
        note = 'Needs Review.',
    },

    ['Door:Great Hall'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille' },
        zoneIds = { 233 },
        note = 'Needs Review.',
    },

    ['Door:Guard Post'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Gunpowder Room'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Harmodios\\'s Music'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:Helbort\\'s Blades'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Hospital'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Western Adoulin' },
        zoneIds = { 256 },
        note = 'Needs Review.',
    },

    ['Door:Hostelry Room #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Hostelry Room #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:House'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets', 'Bastok Mines', 'Port Bastok', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Upper Jeuno', 'Windurst Waters' },
        zoneIds = { 80, 230, 234, 235, 236, 238, 244 },
        note = 'Needs Review.',
    },

    ['Door:House of the Hero'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Door:Infirmary'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Upper Jeuno' },
        zoneIds = { 244 },
        note = 'Needs Review.',
    },

    ['Door:Jeuno Duty-Free'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Jeuno' },
        zoneIds = { 246 },
        note = 'Needs Review.',
    },

    ['Door:Jeunoan Consul'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Northern San d\\'Oria', 'Windurst Walls' },
        zoneIds = { 231, 237, 239 },
        note = 'Needs Review.',
    },

    ['Door:Justi\\'s Furniture'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:Koru-Moru\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Door:Living Quarters'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:M & P\\'s Market'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham', 'Upper Jeuno' },
        zoneIds = { 244, 250 },
        note = 'Needs Review.',
    },

    ['Door:Manuscript Room'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:Manustery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Woods' },
        zoneIds = { 241 },
        note = 'Needs Review.',
    },

    ['Door:Mayor\\'s Residence'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Selbina' },
        zoneIds = { 248 },
        note = 'Needs Review.',
    },

    ['Door:Merchant\\'s House'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Mihgo\\'s Res.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:Mjoll\\'s Goods'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:Muckvix\\'s Junk Shop'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Nchaa\\'s Good Goods'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Woods' },
        zoneIds = { 241 },
        note = 'Needs Review.',
    },

    ['Door:Optistery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters', 'Windurst Waters [S]' },
        zoneIds = { 94, 238 },
        note = 'Needs Review.',
    },

    ['Door:Orastery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Windurst' },
        zoneIds = { 240 },
        note = 'Needs Review.',
    },

    ['Door:Orlando\\'s Antiques'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mhaura' },
        zoneIds = { 249 },
        note = 'Needs Review.',
    },

    ['Door:Othon\\'s Garments'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Pakhroib\\'s Res.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:Papal Chambers'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria', 'Sacrarium' },
        zoneIds = { 28, 231 },
        note = 'Needs Review.',
    },

    ['Door:Posbei\\'s Gear'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:President\\'s Office'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Presidential Suite'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks' },
        zoneIds = { 237 },
        note = 'Needs Review.',
    },

    ['Door:Prince Regent\\'s Rm'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille' },
        zoneIds = { 233 },
        note = 'Needs Review.',
    },

    ['Door:Prince Royal\\'s Rm'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille' },
        zoneIds = { 233 },
        note = 'Needs Review.',
    },

    ['Door:Raimbroy\\'s Grocery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Regine\\'s Magicmart'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port San d\\'Oria' },
        zoneIds = { 232 },
        note = 'Needs Review.',
    },

    ['Door:Reliquary'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:Research Chamber'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Eastern Adoulin' },
        zoneIds = { 257 },
        note = 'Needs Review.',
    },

    ['Door:Rhinostery'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters', 'Windurst Waters [S]' },
        zoneIds = { 94, 238 },
        note = 'Needs Review.',
    },

    ['Door:Rosel\\'s Armour'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Royal Armoury'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Northern San d\\'Oria' },
        zoneIds = { 231 },
        note = 'Needs Review.',
    },

    ['Door:Royal Knight Qtrs'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille' },
        zoneIds = { 233 },
        note = 'Needs Review.',
    },

    ['Door:Ryuhkowa\\'s Merch.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:San d\\'Orian Consul'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Windurst Woods' },
        zoneIds = { 237, 241 },
        note = 'Needs Review.',
    },

    ['Door:San d\\'Orian Emb.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Shantotto\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Door:Shepherd\\'s Muster'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Selbina' },
        zoneIds = { 248 },
        note = 'Needs Review.',
    },

    ['Door:Sororo the Scribe'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets' },
        zoneIds = { 235 },
        note = 'Needs Review.',
    },

    ['Door:Starway Stairway'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Heavens Tower' },
        zoneIds = { 242 },
        note = 'Needs Review.',
    },

    ['Door:Svenja\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Western Adoulin' },
        zoneIds = { 256 },
        note = 'Needs Review.',
    },

    ['Door:Tanners\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Tarutaru Times'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Waters' },
        zoneIds = { 238 },
        note = 'Needs Review.',
    },

    ['Door:Taumila\\'s Sundries'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria' },
        zoneIds = { 230 },
        note = 'Needs Review.',
    },

    ['Door:Temple Knight Qtrs'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille' },
        zoneIds = { 233 },
        note = 'Needs Review.',
    },

    ['Door:Tenshodo H.Q.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Trader\\'s Home'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets', 'Windurst Waters' },
        zoneIds = { 235, 238 },
        note = 'Needs Review.',
    },

    ['Door:Vestal Chamber'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Heavens Tower' },
        zoneIds = { 242 },
        note = 'Needs Review.',
    },

    ['Door:Viette\\'s Weapons'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Upper Jeuno' },
        zoneIds = { 244 },
        note = 'Needs Review.',
    },

    ['Door:Waag-Deeg\\'s Magic'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno' },
        zoneIds = { 245 },
        note = 'Needs Review.',
    },

    ['Door:Wahcondalo\\'s Res.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Kazham' },
        zoneIds = { 250 },
        note = 'Needs Review.',
    },

    ['Door:Warehouse 1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok' },
        zoneIds = { 236 },
        note = 'Needs Review.',
    },

    ['Door:Warehouse 2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Bastok' },
        zoneIds = { 236 },
        note = 'Needs Review.',
    },

    ['Door:Weavers\\' Guild'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Selbina', 'Windurst Woods' },
        zoneIds = { 241, 248 },
        note = 'Needs Review.',
    },

    ['Door:Windurstian Consul'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Northern San d\\'Oria' },
        zoneIds = { 231, 237 },
        note = 'Needs Review.',
    },

    ['Door:Windurstian Emb.'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Door:Yoran-Oran\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Door:Zonpa-Zippa\\'s Manor'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Drifting Feather'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Leafallia' },
        zoneIds = { 281 },
        note = 'Needs Review.',
    },

    ['Driftlix'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'North Gustaberg [S]' },
        zoneIds = { 87, 88 },
        note = 'Needs Review.',
    },

    ['Dry Fountain'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Fei\\'Yin' },
        zoneIds = { 204 },
        note = 'Needs Review.',
    },

    ['Eland Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Markets [S]', 'Batallia Downs [S]', 'Beadeaux [S]', 'Beaucedine Glacier [S]', 'Castle Oztroja [S]', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep [S]', 'Crawlers\\' Nest [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'La Vaule [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Southern San d\\'Oria [S]', 'The Eldieme Necropolis [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Windurst Waters [S]', 'Xarcabard [S]' },
        zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
        note = 'Needs Review.',
    },

    ['Elegant Footprints'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Jugner Forest [S]' },
        zoneIds = { 82 },
        note = 'Needs Review.',
    },

    ['Enigmatic Footprints #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines', 'Ru\\'Lude Gardens', 'Southern San d\\'Oria', 'Windurst Walls' },
        zoneIds = { 230, 234, 239, 243 },
        note = 'Needs Review.',
    },

    ['Enigmatic Footprints #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Bastok Mines', 'Ru\\'Lude Gardens', 'Southern San d\\'Oria', 'Windurst Walls' },
        zoneIds = { 230, 234, 239, 243 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #10'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #11'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #12'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #13'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #14'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #15'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah' },
        zoneIds = { 288, 289 },
        note = 'Needs Review.',
    },

    ['Eschan Portal #9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Escha - Ru\\'Aun' },
        zoneIds = { 289 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Alzadaal Undersea Ruins', 'Attohwa Chasm', 'Aydeewa Subterrane', 'Batallia Downs', 'Beaucedine Glacier', 'Behemoth\\'s Dominion', 'Bibiki Bay', 'Bostaunieux Oubliette', 'Buburimu Peninsula', 'Caedarva Mire', 'Cape Teriggan', 'Carpenters\\' Landing', 'Den of Rancor', 'East Ronfaure', 'East Sarutabaruta', 'Eastern Altepa Desert', 'Fei\\'Yin', 'Garlaige Citadel', 'Gustav Tunnel', 'Halvung', 'Ifrit\\'s Cauldron', 'Jugner Forest', 'Konschtat Highlands', 'Kuftal Tunnel', 'La Theine Plateau', 'Labyrinth of Onzozo', 'Lufaise Meadows', 'Meriphataud Mountains', 'Misareaux Coast', 'Mount Zhayolm', 'Pashhow Marshlands', 'Qufim Island', 'Quicksand Caves', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ro\\'Maeve', 'Rolanberry Fields', 'Sauromugue Champaign', 'Sea Serpent Grotto', 'South Gustaberg', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Sanctuary of Zi\\'Tah', 'Uleguerand Range', 'Valkurm Dunes', 'Valley of Sorrows', 'Wajaom Woodlands', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]', 'Western Altepa Desert', 'Xarcabard', 'Yhoator Jungle', 'Yuhtunga Jungle' },
        zoneIds = { 2, 4, 5, 7, 24, 25, 29, 30, 51, 61, 62, 68, 72, 79, 101, 102, 103, 104, 105, 107, 108, 109, 110, 111, 112, 113, 114, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 153, 159, 160, 167, 174, 176, 200, 204, 205, 208, 212, 213, 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Ethereal Junction #7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Excavation Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Attohwa', 'Abyssea - Tahrongi', 'Attohwa Chasm', 'Korroloka Tunnel', 'Maze of Shakhrami', 'Tahrongi Canyon' },
        zoneIds = { 7, 45, 117, 173, 198, 215 },
        note = 'Needs Review.',
    },

    ['Fabric Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Uleguerand' },
        zoneIds = { 253 },
        note = 'Needs Review.',
    },

    ['Final Survey Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aydeewa Subterrane' },
        zoneIds = { 68 },
        note = 'Needs Review.',
    },

    ['Forbidding Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Fountain of Kings'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Quicksand Caves' },
        zoneIds = { 208 },
        note = 'Needs Review.',
    },

    ['Furnace Hatch'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Newton Movalpolos' },
        zoneIds = { 12 },
        note = 'Needs Review.',
    },

    ['Gate #A1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #A2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #A3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #B6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #C1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #C2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #C3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #D1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate #D2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Rakaznar [U1]', 'Outer Rakaznar [U2]', 'Outer Rakaznar [U3]' },
        zoneIds = { 133, 189, 275 },
        note = 'Needs Review.',
    },

    ['Gate of Darkness'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins', 'Windurst Woods' },
        zoneIds = { 192, 241 },
        note = 'Needs Review.',
    },

    ['Gate of Earth'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of Fire'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of Ice'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of Light'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of the Gods'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Grand Palace of Hu\\'Xzoi' },
        zoneIds = { 34 },
        note = 'Needs Review.',
    },

    ['Gate of Thunder'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of Water'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate of Wind'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Gate Sentry'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Batallia Downs [S]', 'Beaucedine Glacier [S]', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Grauberg [S]', 'Jugner Forest [S]', 'Meriphataud Mountains [S]', 'North Gustaberg [S]', 'Pashhow Marshlands [S]', 'Rolanberry Fields [S]', 'Sauromugue Champaign [S]', 'Vunkerl Inlet [S]', 'West Sarutabaruta [S]', 'Xarcabard [S]' },
        zoneIds = { 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 136, 137 },
        note = 'Needs Review.',
    },

    ['gate_test'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Gwora-Throne Room' },
        zoneIds = { 299 },
        note = 'Needs Review.',
    },

    ['Gate: Chocobo Circuit'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Bastok Mines', 'Chocobo Circuit', 'Port Jeuno', 'Southern San d\\'Oria', 'Windurst Woods' },
        zoneIds = { 50, 70, 230, 234, 241, 246 },
        note = 'Needs Review.',
    },

    ['Gate: Lifeboat'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Ashu Talif' },
        zoneIds = { 60 },
        note = 'Needs Review.',
    },

    ['Gate: Magical Gizmo'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins', 'Outer Horutoto Ruins' },
        zoneIds = { 192, 194 },
        note = 'Needs Review.',
    },

    ['Gate: The Colosseum'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate' },
        zoneIds = { 50 },
        note = 'Needs Review.',
    },

    ['Gate: The Pit'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'The Colosseum' },
        zoneIds = { 50, 71 },
        note = 'Needs Review.',
    },

    ['Gates of Halvung'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mount Zhayolm' },
        zoneIds = { 61 },
        note = 'Needs Review.',
    },

    ['Geomagnetic Fount'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Attohwa Chasm', 'Beadeaux', 'Castle Oztroja', 'Castle Zvahl Keep', 'Crawlers\\' Nest', 'Dangruf Wadi', 'Davoi', 'Garlaige Citadel', 'Gusgen Mines', 'Gustav Tunnel', 'Inner Horutoto Ruins', 'Jugner Forest', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Korroloka Tunnel', 'La Theine Plateau', 'Labyrinth of Onzozo', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Monastic Cavern', 'North Gustaberg', 'Oldton Movalpolos', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Palborough Mines', 'Pashhow Marshlands', 'Quicksand Caves', 'Ranguemont Pass', 'Riverne - Site #B01', 'Sea Serpent Grotto', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Eldieme Necropolis', 'Toraimarai Canal', 'Uleguerand Range', 'West Ronfaure', 'West Sarutabaruta', 'Yughott Grotto' },
        zoneIds = { 5, 7, 11, 29, 100, 102, 104, 106, 108, 109, 115, 117, 119, 142, 143, 147, 149, 150, 151, 153, 159, 162, 166, 169, 173, 176, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 208, 212, 213 },
        note = 'Needs Review.',
    },

    ['Giant Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Qufim Island' },
        zoneIds = { 126 },
        note = 'Needs Review.',
    },

    ['GoalPoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef', 'Aydeewa Subterrane', 'Beadeaux', 'Bostaunieux Oubliette', 'Castle Oztroja', 'Crawlers\\' Nest', 'Davoi', 'Den of Rancor', 'Garlaige Citadel', 'Gustav Tunnel', 'Halvung', 'Ifrit\\'s Cauldron', 'Kuftal Tunnel', 'Mamook', 'Ranguemont Pass', 'Temple of Uggalepih', 'The Eldieme Necropolis', 'Toraimarai Canal' },
        zoneIds = { 54, 62, 65, 68, 147, 149, 151, 159, 160, 166, 167, 169, 174, 195, 197, 200, 205, 212 },
        note = 'Needs Review.',
    },

    ['Goblin Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Empyreal Paradox', 'Al Zahbi', 'Al\\'Taieu', 'Altar Room', 'Alzadaal Undersea Ruins', 'Arrapago Reef', 'Aydeewa Subterrane', 'Balga\\'s Dais', 'Batallia Downs', 'Batallia Downs [S]', 'Beadeaux', 'Beadeaux [S]', 'Bearclaw Pinnacle', 'Beaucedine Glacier', 'Beaucedine Glacier [S]', 'Bhaflau Thickets', 'Bibiki Bay', 'Boneyard Gully', 'Bostaunieux Oubliette', 'Buburimu Peninsula', 'Caedarva Mire', 'Cape Teriggan', 'Carpenters\\' Landing', 'Castle Oztroja', 'Castle Oztroja [S]', 'Castle Zvahl Baileys', 'Castle Zvahl Baileys [S]', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Chamber of Oracles', 'Cirdas Caverns', 'Cloister of Flames', 'Cloister of Frost', 'Cloister of Gales', 'Cloister of Storms', 'Cloister of Tides', 'Cloister of Tremors', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Dangruf Wadi', 'Davoi', 'Desuetia - Empyreal Paradox', 'Dho Gates', 'Dragon\\'s Aery', 'East Ronfaure [S]', 'East Sarutabaruta', 'Empyreal Paradox', 'Escha - Ru\\'Aun', 'Escha - Zi\\'Tah', 'Fei\\'Yin', 'Feretory', 'Foret de Hennetiel', 'Fort Karugo-Narugo [S]', 'Full Moon Fountain', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Ghelsba Outpost', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Grauberg [S]', 'Gusgen Mines', 'Gustav Tunnel', 'Hall of The Gods', 'Hall of Transference', 'Halvung', 'Hazhalm Testing Grounds', 'Horlais Peak', 'Ifrit\\'s Cauldron', 'Inner Horutoto Ruins', 'Jade Sepulcher', 'Jugner Forest', 'Jugner Forest [S]', 'Kamihr Drifts', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Korroloka Tunnel', 'Kuftal Tunnel', 'La Theine Plateau', 'La Vaule [S]', 'La\\'Loff Amphitheater', 'Leafallia', 'Lower Delkfutt\\'s Tower', 'Lufaise Meadows', 'Mamook', 'Marjami Ravine', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Middle Delkfutt\\'s Tower', 'Mine Shaft #2716', 'Misareaux Coast', 'Mog Garden', 'Moh Gates', 'Monarch Linn', 'Monastic Cavern', 'Morimar Basalt Fields', 'Mount Kamihr', 'Mount Zhayolm', 'Navukgo Execution Chamber', 'North Gustaberg', 'North Gustaberg [S]', 'Oldton Movalpolos', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Outer Ra\\'Kaznar', 'Palborough Mines', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Phomiuna Aqueducts', 'Promyvion - Vahzl', 'Provenance', 'Pso\\'Xja', 'Qu\\'Bia Arena', 'Qufim Island', 'Quicksand Caves', 'Qulun Dome', 'Ra\\'Kaznar Inner Court', 'Ra\\'Kaznar Turris', 'Ranguemont Pass', 'Reisenjima', 'Reisenjima Sanctorium', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Sacrarium', 'Sacrificial Chamber', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'Sea Serpent Grotto', 'Sih Gates', 'South Gustaberg', 'Spire of Dem', 'Spire of Holla', 'Spire of Mea', 'Spire of Vahzl', 'Stellar Fulcrum', 'Tahrongi Canyon', 'Talacca Cove', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Celestial Nexus', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Garden of Ru\\'Hmet', 'The Sanctuary of Zi\\'Tah', 'The Shrine of Ru\\'Avitau', 'The Shrouded Maw', 'Throne Room', 'Throne Room [S]', 'Toraimarai Canal', 'Uleguerand Range', 'Valkurm Dunes', 'Valley of Sorrows', 'Vunkerl Inlet [S]', 'Wajaom Woodlands', 'Walk of Echoes', 'Waughroon Shrine', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Altepa Desert', 'Woh Gates', 'Xarcabard', 'Xarcabard [S]', 'Yahse Hunting Grounds', 'Yorcia Weald', 'Yughott Grotto', 'Yuhtunga Jungle', 'Zeruhn Mines' },
        zoneIds = { 2, 4, 5, 6, 8, 9, 10, 11, 13, 14, 17, 19, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31, 33, 34, 35, 36, 48, 51, 52, 54, 57, 61, 62, 64, 65, 67, 68, 72, 78, 79, 81, 82, 83, 84, 85, 88, 89, 90, 91, 92, 95, 96, 97, 98, 99, 100, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 115, 116, 117, 118, 119, 120, 121, 122, 123, 125, 126, 128, 130, 136, 137, 138, 139, 140, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 159, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 178, 179, 180, 181, 182, 184, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 211, 212, 222, 251, 255, 260, 261, 262, 263, 265, 266, 267, 268, 269, 270, 272, 273, 274, 276, 277, 280, 281, 282, 285, 288, 289, 290, 291, 293 },
        note = 'Needs Review.',
    },

    ['Guide Stone'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Lower Jeuno', 'Port Jeuno', 'Upper Jeuno' },
        zoneIds = { 244, 245, 246 },
        note = 'Needs Review.',
    },

    ['Harvesting Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Grauberg', 'Attohwa Chasm', 'Bhaflau Thickets', 'Ceizak Battlegrounds', 'Foret de Hennetiel', 'Ghoyu\\'s Reverie', 'Giddeus', 'Grauberg [S]', 'Leujaoam Sanctum', 'Sih Gates', 'Wajaom Woodlands', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Yahse Hunting Grounds', 'Yhoator Jungle', 'Yorcia Weald', 'Yuhtunga Jungle' },
        zoneIds = { 7, 51, 52, 69, 89, 95, 115, 123, 124, 129, 145, 254, 260, 261, 262, 263, 268 },
        note = 'Needs Review.',
    },

    ['Heroic Footprints'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Leafallia' },
        zoneIds = { 281 },
        note = 'Needs Review.',
    },

    ['Home Point #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Attohwa Chasm', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Bhaflau Thickets', 'Caedarva Mire', 'Cape Teriggan', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Den of Rancor', 'Eastern Adoulin', 'Fei\\'Yin', 'Foret de Hennetiel', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Kazham', 'Leafallia', 'Lower Jeuno', 'Marjami Ravine', 'Metalworks', 'Mhaura', 'Misareaux Coast', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Nashmau', 'Newton Movalpolos', 'Norg', 'Northern San d\\'Oria', 'Palborough Mines', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Pso\\'Xja', 'Qufim Island', 'Quicksand Caves', 'Ra\\'Kaznar Inner Court', 'Rabao', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Selbina', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Tavnazian Safehold', 'The Boyahda Tree', 'The Garden of Ru\\'Hmet', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Western Adoulin', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Xarcabard [S]', 'Yorcia Weald', 'Yughott Grotto' },
        zoneIds = { 5, 7, 9, 12, 25, 26, 29, 30, 33, 34, 35, 48, 50, 52, 53, 61, 79, 80, 87, 94, 113, 126, 130, 137, 142, 143, 145, 153, 155, 158, 160, 162, 169, 178, 204, 205, 208, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 241, 243, 244, 245, 246, 247, 248, 249, 250, 252, 256, 257, 261, 262, 263, 265, 266, 267, 276, 281 },
        note = 'Needs Review.',
    },

    ['Home Point #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Attohwa Chasm', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Bhaflau Thickets', 'Caedarva Mire', 'Cape Teriggan', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Den of Rancor', 'Eastern Adoulin', 'Fei\\'Yin', 'Foret de Hennetiel', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Kazham', 'Leafallia', 'Lower Jeuno', 'Marjami Ravine', 'Metalworks', 'Mhaura', 'Misareaux Coast', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Nashmau', 'Newton Movalpolos', 'Norg', 'Northern San d\\'Oria', 'Palborough Mines', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Pso\\'Xja', 'Qufim Island', 'Quicksand Caves', 'Ra\\'Kaznar Inner Court', 'Rabao', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Selbina', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Tavnazian Safehold', 'The Boyahda Tree', 'The Garden of Ru\\'Hmet', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Western Adoulin', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Xarcabard [S]', 'Yorcia Weald', 'Yughott Grotto' },
        zoneIds = { 5, 7, 9, 12, 25, 26, 29, 30, 33, 34, 35, 48, 50, 52, 53, 61, 79, 80, 87, 94, 113, 126, 130, 137, 142, 143, 145, 153, 155, 158, 160, 162, 169, 178, 204, 205, 208, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 241, 243, 244, 245, 246, 247, 248, 249, 250, 252, 256, 257, 261, 262, 263, 265, 266, 267, 276, 281 },
        note = 'Needs Review.',
    },

    ['Home Point #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Attohwa Chasm', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Bhaflau Thickets', 'Caedarva Mire', 'Cape Teriggan', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Den of Rancor', 'Eastern Adoulin', 'Fei\\'Yin', 'Foret de Hennetiel', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Kazham', 'Leafallia', 'Lower Jeuno', 'Marjami Ravine', 'Metalworks', 'Mhaura', 'Misareaux Coast', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Nashmau', 'Newton Movalpolos', 'Norg', 'Northern San d\\'Oria', 'Palborough Mines', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Pso\\'Xja', 'Qufim Island', 'Quicksand Caves', 'Ra\\'Kaznar Inner Court', 'Rabao', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Selbina', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Tavnazian Safehold', 'The Boyahda Tree', 'The Garden of Ru\\'Hmet', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Western Adoulin', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Xarcabard [S]', 'Yorcia Weald', 'Yughott Grotto' },
        zoneIds = { 5, 7, 9, 12, 25, 26, 29, 30, 33, 34, 35, 48, 50, 52, 53, 61, 79, 80, 87, 94, 113, 126, 130, 137, 142, 143, 145, 153, 155, 158, 160, 162, 169, 178, 204, 205, 208, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 241, 243, 244, 245, 246, 247, 248, 249, 250, 252, 256, 257, 261, 262, 263, 265, 266, 267, 276, 281 },
        note = 'Needs Review.',
    },

    ['Home Point #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Attohwa Chasm', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Bhaflau Thickets', 'Caedarva Mire', 'Cape Teriggan', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Den of Rancor', 'Eastern Adoulin', 'Fei\\'Yin', 'Foret de Hennetiel', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Kazham', 'Leafallia', 'Lower Jeuno', 'Marjami Ravine', 'Metalworks', 'Mhaura', 'Misareaux Coast', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Nashmau', 'Newton Movalpolos', 'Norg', 'Northern San d\\'Oria', 'Palborough Mines', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Pso\\'Xja', 'Qufim Island', 'Quicksand Caves', 'Ra\\'Kaznar Inner Court', 'Rabao', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Selbina', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Tavnazian Safehold', 'The Boyahda Tree', 'The Garden of Ru\\'Hmet', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Western Adoulin', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Xarcabard [S]', 'Yorcia Weald', 'Yughott Grotto' },
        zoneIds = { 5, 7, 9, 12, 25, 26, 29, 30, 33, 34, 35, 48, 50, 52, 53, 61, 79, 80, 87, 94, 113, 126, 130, 137, 142, 143, 145, 153, 155, 158, 160, 162, 169, 178, 204, 205, 208, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 241, 243, 244, 245, 246, 247, 248, 249, 250, 252, 256, 257, 261, 262, 263, 265, 266, 267, 276, 281 },
        note = 'Needs Review.',
    },

    ['Home Point #5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Al Zahbi', 'Al\\'Taieu', 'Attohwa Chasm', 'Bastok Markets', 'Bastok Markets [S]', 'Bastok Mines', 'Bhaflau Thickets', 'Caedarva Mire', 'Cape Teriggan', 'Castle Zvahl Keep', 'Castle Zvahl Keep [S]', 'Ceizak Battlegrounds', 'Den of Rancor', 'Eastern Adoulin', 'Fei\\'Yin', 'Foret de Hennetiel', 'Giddeus', 'Grand Palace of Hu\\'Xzoi', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Kazham', 'Leafallia', 'Lower Jeuno', 'Marjami Ravine', 'Metalworks', 'Mhaura', 'Misareaux Coast', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Nashmau', 'Newton Movalpolos', 'Norg', 'Northern San d\\'Oria', 'Palborough Mines', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Pso\\'Xja', 'Qufim Island', 'Quicksand Caves', 'Ra\\'Kaznar Inner Court', 'Rabao', 'Riverne - Site #A01', 'Riverne - Site #B01', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Selbina', 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]', 'Tavnazian Safehold', 'The Boyahda Tree', 'The Garden of Ru\\'Hmet', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Uleguerand Range', 'Upper Delkfutt\\'s Tower', 'Upper Jeuno', 'Western Adoulin', 'Windurst Walls', 'Windurst Waters', 'Windurst Waters [S]', 'Windurst Woods', 'Xarcabard [S]', 'Yorcia Weald', 'Yughott Grotto' },
        zoneIds = { 5, 7, 9, 12, 25, 26, 29, 30, 33, 34, 35, 48, 50, 52, 53, 61, 79, 80, 87, 94, 113, 126, 130, 137, 142, 143, 145, 153, 155, 158, 160, 162, 169, 178, 204, 205, 208, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 241, 243, 244, 245, 246, 247, 248, 249, 250, 252, 256, 257, 261, 262, 263, 265, 266, 267, 276, 281 },
        note = 'Needs Review.',
    },

    ['Horuni-Mawoni'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Windurst Walls' },
        zoneIds = { 239 },
        note = 'Needs Review.',
    },

    ['Impact Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Uleguerand' },
        zoneIds = { 253 },
        note = 'Needs Review.',
    },

    ['Irksome Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Ladder of Passage'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Lamp of Compassion'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Large Apparatus'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Hall of Transference' },
        zoneIds = { 14 },
        note = 'Needs Review.',
    },

    ['Legion Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Maquette Abdhaljs-Legion A', 'Maquette Abdhaljs-Legion B' },
        zoneIds = { 183, 287 },
        note = 'Needs Review.',
    },

    ['Lever'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Gusgen Mines' },
        zoneIds = { 196 },
        note = 'Needs Review.',
    },

    ['Leypoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Wajaom Woodlands' },
        zoneIds = { 51 },
        note = 'Needs Review.',
    },

    ['Light Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Halvung' },
        zoneIds = { 62 },
        note = 'Needs Review.',
    },

    ['Lined Casket'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Konschtat' },
        zoneIds = { 15, 218 },
        note = 'Needs Review.',
    },

    ['Logging Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Buburimu Peninsula', 'Caedarva Mire', 'Carpenters\\' Landing', 'Ceizak Battlegrounds', 'East Ronfaure', 'East Ronfaure [S]', 'Fort Karugo-Narugo [S]', 'Ghelsba Outpost', 'Ghoyu\\'s Reverie', 'Jugner Forest', 'Jugner Forest [S]', 'Lufaise Meadows', 'Mamook', 'Misareaux Coast', 'Yahse Hunting Grounds', 'Yhoator Jungle', 'Yorcia Weald', 'Yuhtunga Jungle' },
        zoneIds = { 2, 24, 25, 65, 79, 81, 82, 96, 101, 104, 118, 123, 124, 129, 132, 140, 216, 260, 261, 263 },
        note = 'Needs Review.',
    },

    ['Lumber Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Uleguerand' },
        zoneIds = { 253 },
        note = 'Needs Review.',
    },

    ['Matrimonial Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chateau d\\'Oraguille', 'Heavens Tower', 'Metalworks' },
        zoneIds = { 233, 237, 242 },
        note = 'Needs Review.',
    },

    ['Mawl\\'gofaur'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Metalworks', 'Ru\\'Lude Gardens', 'Sauromugue Champaign [S]' },
        zoneIds = { 98, 237, 243 },
        note = 'Needs Review.',
    },

    ['MD_POINT'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'GM Home' },
        zoneIds = { 210 },
        note = 'Needs Review.',
    },

    ['Meeting Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Outer Ra\\'Kaznar' },
        zoneIds = { 274 },
        note = 'Needs Review.',
    },

    ['Memento Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'The Shrouded Maw' },
        zoneIds = { 10 },
        note = 'Needs Review.',
    },

    ['Mining Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Cirdas Caverns', 'Dho Gates', 'Ghoyu\\'s Reverie', 'Gusgen Mines', 'Halvung', 'Ifrit\\'s Cauldron', 'Kamihr Drifts', 'Leujaoam Sanctum', 'Marjami Ravine', 'Moh Gates', 'Morimar Basalt Fields', 'Mount Zhayolm', 'Newton Movalpolos', 'North Gustaberg [S]', 'Oldton Movalpolos', 'Outer Ra\\'Kaznar', 'Palborough Mines', 'Ruhotz Silvermines', 'Sih Gates', 'Woh Gates', 'Yughott Grotto', 'Zeruhn Mines' },
        zoneIds = { 11, 12, 61, 62, 69, 88, 93, 129, 142, 143, 172, 196, 205, 265, 266, 267, 268, 269, 270, 272, 273, 274 },
        note = 'Needs Review.',
    },

    ['Molten Rift'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Moh Gates' },
        zoneIds = { 269 },
        note = 'Needs Review.',
    },

    ['Monument'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'North Gustaberg', 'North Gustaberg [S]' },
        zoneIds = { 88, 106 },
        note = 'Needs Review.',
    },

    ['Occultist Footprints'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Yorcia Weald' },
        zoneIds = { 263 },
        note = 'Needs Review.',
    },

    ['Odyssean Passage'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Feretory', 'Leafallia', 'Northern San d\\'Oria', 'Pashhow Marshlands', 'Port Bastok', 'Port Windurst' },
        zoneIds = { 109, 231, 236, 240, 281, 285 },
        note = 'Needs Review.',
    },

    ['Old Casket'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temple of Uggalepih' },
        zoneIds = { 159 },
        note = 'Needs Review.',
    },

    ['Peculiar Footprints'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef', 'Aydeewa Subterrane', 'Batallia Downs', 'Beaucedine Glacier', 'Caedarva Mire', 'Kamihr Drifts', 'Mount Zhayolm', 'Newton Movalpolos', 'Palborough Mines', 'Qufim Island', 'Rala Waterways', 'Reisenjima', 'Wajaom Woodlands', 'Western Altepa Desert', 'Xarcabard' },
        zoneIds = { 12, 51, 54, 61, 68, 79, 105, 111, 112, 125, 126, 143, 258, 267, 291 },
        note = 'Needs Review.',
    },

    ['Planar Rift'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef', 'Attohwa Chasm', 'Aydeewa Subterrane', 'Batallia Downs', 'Batallia Downs [S]', 'Beaucedine Glacier', 'Behemoth\\'s Dominion', 'Bibiki Bay', 'Buburimu Peninsula', 'Caedarva Mire', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Dangruf Wadi', 'East Ronfaure', 'East Ronfaure [S]', 'East Sarutabaruta', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Gusgen Mines', 'Ifrit\\'s Cauldron', 'Jugner Forest', 'Jugner Forest [S]', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Kuftal Tunnel', 'La Theine Plateau', 'Lower Delkfutt\\'s Tower', 'Lufaise Meadows', 'Mamook', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Misareaux Coast', 'Mount Zhayolm', 'North Gustaberg', 'North Gustaberg [S]', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Provenance', 'Qufim Island', 'Quicksand Caves', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'South Gustaberg', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Sanctuary of Zi\\'Tah', 'The Shrine of Ru\\'Avitau', 'Uleguerand Range', 'Valkurm Dunes', 'Ve\\'Lugannon Palace', 'Vunkerl Inlet [S]', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Altepa Desert', 'Yuhtunga Jungle' },
        zoneIds = { 4, 5, 7, 24, 25, 54, 61, 65, 68, 79, 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 115, 116, 117, 118, 119, 120, 121, 122, 123, 125, 126, 127, 130, 153, 159, 164, 171, 174, 175, 177, 178, 184, 190, 191, 193, 194, 195, 196, 197, 198, 200, 205, 208, 222 },
        note = 'Needs Review.',
    },

    ['Point 1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie', 'Ruhotz Silvermines' },
        zoneIds = { 93, 129 },
        note = 'Needs Review.',
    },

    ['Point 10'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie', 'Ruhotz Silvermines' },
        zoneIds = { 93, 129 },
        note = 'Needs Review.',
    },

    ['Point 3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie', 'Ruhotz Silvermines' },
        zoneIds = { 93, 129 },
        note = 'Needs Review.',
    },

    ['Point 4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point 9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Point of Interest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Beaucedine Glacier' },
        zoneIds = { 111 },
        note = 'Needs Review.',
    },

    ['Point1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Point2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Point3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Proto-Waypoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mhaura', 'Norg', 'Rabao', 'Ru\\'Lude Gardens', 'Selbina' },
        zoneIds = { 243, 247, 248, 249, 252 },
        note = 'Needs Review.',
    },

    ['Rabbit Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Uleguerand Range' },
        zoneIds = { 5 },
        note = 'Needs Review.',
    },

    ['Rally Point: Blue'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Rally Point: Green'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Rally Point: Red'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Red Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Rendezvous Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Northern San d\\'Oria', 'Port Bastok', 'Promyvion - Dem', 'Promyvion - Holla', 'Promyvion - Mea', 'Ru\\'Lude Gardens', 'Windurst Waters' },
        zoneIds = { 16, 18, 20, 50, 231, 236, 238, 243 },
        note = 'Needs Review.',
    },

    ['Resume Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Arrapago Reef', 'Batallia Downs', 'Castle Oztroja', 'Ceizak Battlegrounds', 'Cirdas Caverns', 'Empyreal Paradox', 'Kamihr Drifts', 'Ra\\'Kaznar Turris', 'Reisenjima', 'Ru\\'Lude Gardens', 'Sealion\\'s Den', 'Xarcabard [S]', 'Yughott Grotto' },
        zoneIds = { 32, 36, 50, 54, 105, 137, 142, 151, 243, 261, 267, 270, 277, 291 },
        note = 'Needs Review.',
    },

    ['Riftborer Verokgok'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Jugner Forest [S]' },
        zoneIds = { 82 },
        note = 'Needs Review.',
    },

    ['Riftworn Pyxis'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Arrapago Reef', 'Attohwa Chasm', 'Aydeewa Subterrane', 'Batallia Downs', 'Batallia Downs [S]', 'Beaucedine Glacier', 'Behemoth\\'s Dominion', 'Bibiki Bay', 'Buburimu Peninsula', 'Caedarva Mire', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Dangruf Wadi', 'East Ronfaure', 'East Ronfaure [S]', 'East Sarutabaruta', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Gusgen Mines', 'Ifrit\\'s Cauldron', 'Jugner Forest', 'Jugner Forest [S]', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Kuftal Tunnel', 'La Theine Plateau', 'Lower Delkfutt\\'s Tower', 'Lufaise Meadows', 'Mamook', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Misareaux Coast', 'Mount Zhayolm', 'North Gustaberg', 'North Gustaberg [S]', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Qufim Island', 'Quicksand Caves', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'South Gustaberg', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Sanctuary of Zi\\'Tah', 'The Shrine of Ru\\'Avitau', 'Uleguerand Range', 'Valkurm Dunes', 'Ve\\'Lugannon Palace', 'Vunkerl Inlet [S]', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Altepa Desert', 'Yuhtunga Jungle' },
        zoneIds = { 4, 5, 7, 24, 25, 54, 61, 65, 68, 79, 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 115, 116, 117, 118, 119, 120, 121, 122, 123, 125, 126, 127, 130, 153, 159, 164, 171, 174, 175, 177, 178, 184, 190, 191, 193, 194, 195, 196, 197, 198, 200, 205, 208 },
        note = 'Needs Review.',
    },

    ['Runic Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Alzadaal Undersea Ruins', 'Arrapago Reef', 'Bhaflau Thickets', 'Caedarva Mire', 'Mount Zhayolm' },
        zoneIds = { 50, 52, 54, 61, 72, 79 },
        note = 'Needs Review.',
    },

    ['Sealed Portal'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Shami\\'s Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Jeuno' },
        zoneIds = { 246 },
        note = 'Needs Review.',
    },

    ['Shami\\'s Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Port Jeuno' },
        zoneIds = { 246 },
        note = 'Needs Review.',
    },

    ['Shattered Telepoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Eastern Altepa Desert', 'Jugner Forest [S]', 'Konschtat Highlands', 'La Theine Plateau', 'Meriphataud Mountains [S]', 'Pashhow Marshlands [S]', 'Tahrongi Canyon', 'Xarcabard', 'Yhoator Jungle' },
        zoneIds = { 82, 90, 97, 102, 108, 112, 114, 117, 124 },
        note = 'Needs Review.',
    },

    ['Shimmering Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Chamber of Oracles', 'Hall of The Gods', 'La\\'Loff Amphitheater' },
        zoneIds = { 168, 180, 251 },
        note = 'Needs Review.',
    },

    ['Splintery Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ru\\'Lude Gardens' },
        zoneIds = { 243 },
        note = 'Needs Review.',
    },

    ['Strange Apparatus'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Crawlers\\' Nest', 'Dangruf Wadi', 'Fei\\'Yin', 'Garlaige Citadel', 'Gusgen Mines', 'King Ranperre\\'s Tomb', 'Maze of Shakhrami', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'The Eldieme Necropolis' },
        zoneIds = { 190, 191, 193, 194, 195, 196, 197, 198, 200, 204 },
        note = 'Needs Review.',
    },

    ['Sunken Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Xarcabard [S]' },
        zoneIds = { 137 },
        note = 'Needs Review.',
    },

    ['Supply Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Attohwa' },
        zoneIds = { 215 },
        note = 'Needs Review.',
    },

    ['Survey Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aydeewa Subterrane' },
        zoneIds = { 68 },
        note = 'Needs Review.',
    },

    ['Survival Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ghoyu\\'s Reverie' },
        zoneIds = { 129 },
        note = 'Needs Review.',
    },

    ['Survival Guide'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Arrapago Reef', 'Aydeewa Subterrane', 'Bastok Markets [S]', 'Bastok Mines', 'Batallia Downs', 'Batallia Downs [S]', 'Beadeaux', 'Beaucedine Glacier', 'Beaucedine Glacier [S]', 'Behemoth\\'s Dominion', 'Bibiki Bay', 'Bostaunieux Oubliette', 'Buburimu Peninsula', 'Caedarva Mire', 'Cape Teriggan', 'Carpenters\\' Landing', 'Castle Oztroja', 'Castle Zvahl Baileys', 'Castle Zvahl Baileys [S]', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Dangruf Wadi', 'Davoi', 'Dragon\\'s Aery', 'East Ronfaure [S]', 'Eastern Adoulin', 'Eastern Altepa Desert', 'Fort Ghelsba', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Gusgen Mines', 'Gustav Tunnel', 'Halvung', 'Ifrit\\'s Cauldron', 'Inner Horutoto Ruins', 'Jugner Forest', 'Jugner Forest [S]', 'Kazham', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Korroloka Tunnel', 'Kuftal Tunnel', 'La Theine Plateau', 'Labyrinth of Onzozo', 'Lower Delkfutt\\'s Tower', 'Lufaise Meadows', 'Mamook', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Misareaux Coast', 'Nashmau', 'Norg', 'North Gustaberg', 'North Gustaberg [S]', 'Northern San d\\'Oria', 'Oldton Movalpolos', 'Ordelle\\'s Caves', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Phomiuna Aqueducts', 'Port Windurst', 'Qufim Island', 'Rabao', 'Ranguemont Pass', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Ru\\'Lude Gardens', 'Sacrarium', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'Sea Serpent Grotto', 'Southern San d\\'Oria [S]', 'Tahrongi Canyon', 'Tavnazian Safehold', 'Temple of Uggalepih', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Sanctuary of Zi\\'Tah', 'Toraimarai Canal', 'Valkurm Dunes', 'Valley of Sorrows', 'Vunkerl Inlet [S]', 'Wajaom Woodlands', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Altepa Desert', 'Windurst Waters [S]', 'Xarcabard', 'Yhoator Jungle', 'Yuhtunga Jungle', 'Zeruhn Mines' },
        zoneIds = { 2, 4, 11, 24, 25, 26, 27, 28, 50, 51, 53, 54, 62, 65, 68, 79, 80, 81, 82, 83, 84, 87, 88, 89, 90, 91, 94, 95, 96, 97, 98, 100, 102, 103, 104, 105, 106, 108, 109, 110, 111, 112, 113, 114, 115, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 130, 136, 138, 141, 147, 149, 151, 154, 159, 161, 164, 166, 167, 169, 171, 172, 173, 174, 175, 176, 184, 190, 191, 192, 193, 195, 196, 197, 198, 200, 205, 212, 213, 231, 234, 240, 243, 247, 250, 252, 257 },
        note = 'Needs Review.',
    },

    ['Switch'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Den of Rancor', 'Everbloom Hollow', 'Inner Horutoto Ruins', 'Lebros Cavern', 'Outer Horutoto Ruins', 'Sacrarium' },
        zoneIds = { 28, 63, 86, 160, 192, 194 },
        note = 'Needs Review.',
    },

    ['Switch#1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Switch#2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Switch#3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Switch#4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Garlaige Citadel' },
        zoneIds = { 200 },
        note = 'Needs Review.',
    },

    ['Switchlox'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Switchstix'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Castle Zvahl Baileys' },
        zoneIds = { 161 },
        note = 'Needs Review.',
    },

    ['Synergy Furnace'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Bastok Markets', 'Bastok Mines', 'Chocobo Circuit', 'GM Home', 'Kazham', 'Lower Jeuno', 'Metalworks', 'Northern San d\\'Oria', 'Port Bastok', 'Port Jeuno', 'Port San d\\'Oria', 'Port Windurst', 'Rabao', 'Southern San d\\'Oria', 'Tavnazian Safehold', 'Upper Jeuno', 'Windurst Walls', 'Windurst Waters' },
        zoneIds = { 26, 50, 70, 210, 230, 231, 232, 234, 235, 236, 237, 238, 239, 240, 244, 245, 246, 247, 250 },
        note = 'Needs Review.',
    },

    ['Telepoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Eastern Altepa Desert', 'Jugner Forest [S]', 'Konschtat Highlands', 'La Theine Plateau', 'Meriphataud Mountains [S]', 'Pashhow Marshlands [S]', 'Tahrongi Canyon', 'Xarcabard', 'Yhoator Jungle' },
        zoneIds = { 82, 90, 97, 102, 108, 112, 114, 117, 124 },
        note = 'Needs Review.',
    },

    ['Temenos Coffer #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temenos' },
        zoneIds = { 37 },
        note = 'Needs Review.',
    },

    ['Temenos Coffer #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temenos' },
        zoneIds = { 37 },
        note = 'Needs Review.',
    },

    ['Temenos Coffer #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temenos' },
        zoneIds = { 37 },
        note = 'Needs Review.',
    },

    ['Temenos Coffer #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temenos' },
        zoneIds = { 37 },
        note = 'Needs Review.',
    },

    ['Temenos Furnace'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Temenos' },
        zoneIds = { 37 },
        note = 'Needs Review.',
    },

    ['Terminal Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Balga\\'s Dais', 'Horlais Peak', 'Waughroon Shrine' },
        zoneIds = { 139, 144, 146 },
        note = 'Needs Review.',
    },

    ['Toad\\'s Footprint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Mamook' },
        zoneIds = { 65 },
        note = 'Needs Review.',
    },

    ['Tomato Vantage Point'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Rala Waterways' },
        zoneIds = { 258 },
        note = 'Needs Review.',
    },

    ['Torch'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Castle Zvahl Baileys' },
        zoneIds = { 161 },
        note = 'Needs Review.',
    },

    ['Torch Stand'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Castle Oztroja', 'Castle Oztroja [S]' },
        zoneIds = { 99, 151 },
        note = 'Needs Review.',
    },

    ['Treasure Casket'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Batallia Downs', 'Beaucedine Glacier', 'Behemoth\\'s Dominion', 'Bostaunieux Oubliette', 'Buburimu Peninsula', 'Cape Teriggan', 'Crawlers\\' Nest', 'Dangruf Wadi', 'Den of Rancor', 'East Ronfaure', 'East Sarutabaruta', 'Eastern Altepa Desert', 'Fei\\'Yin', 'Garlaige Citadel', 'Gusgen Mines', 'Gustav Tunnel', 'Ifrit\\'s Cauldron', 'Inner Horutoto Ruins', 'Jugner Forest', 'King Ranperre\\'s Tomb', 'Konschtat Highlands', 'Korroloka Tunnel', 'Kuftal Tunnel', 'La Theine Plateau', 'Labyrinth of Onzozo', 'Lower Delkfutt\\'s Tower', 'Maze of Shakhrami', 'Meriphataud Mountains', 'Middle Delkfutt\\'s Tower', 'North Gustaberg', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Pashhow Marshlands', 'Qufim Island', 'Quicksand Caves', 'Ranguemont Pass', 'Ro\\'Maeve', 'Rolanberry Fields', 'Ru\\'Aun Gardens', 'Sauromugue Champaign', 'Sea Serpent Grotto', 'South Gustaberg', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Eldieme Necropolis', 'The Sanctuary of Zi\\'Tah', 'The Shrine of Ru\\'Avitau', 'Toraimarai Canal', 'Upper Delkfutt\\'s Tower', 'Valkurm Dunes', 'Valley of Sorrows', 'Ve\\'Lugannon Palace', 'West Ronfaure', 'West Sarutabaruta', 'Western Altepa Desert', 'Xarcabard', 'Yhoator Jungle', 'Yuhtunga Jungle', 'Zeruhn Mines' },
        zoneIds = { 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 130, 153, 157, 158, 159, 160, 166, 167, 169, 172, 173, 174, 176, 177, 178, 184, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 204, 205, 208, 212, 213 },
        note = 'Needs Review.',
    },

    ['Treasure Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Alzadaal Undersea Ruins', 'Beadeaux', 'Castle Oztroja', 'Castle Zvahl Baileys', 'Castle Zvahl Keep', 'Crawlers\\' Nest', 'Dangruf Wadi', 'Davoi', 'Fei\\'Yin', 'Fort Ghelsba', 'Garlaige Citadel', 'Giddeus', 'Gusgen Mines', 'Inner Horutoto Ruins', 'King Ranperre\\'s Tomb', 'Labyrinth of Onzozo', 'Maze of Shakhrami', 'Middle Delkfutt\\'s Tower', 'Oldton Movalpolos', 'Ordelle\\'s Caves', 'Outer Horutoto Ruins', 'Palborough Mines', 'Pso\\'Xja', 'Ru\\'Aun Gardens', 'Sacrarium', 'Sea Serpent Grotto', 'The Boyahda Tree', 'The Eldieme Necropolis', 'Upper Delkfutt\\'s Tower', 'Yughott Grotto' },
        zoneIds = { 9, 11, 28, 72, 130, 141, 142, 143, 145, 147, 149, 151, 153, 157, 158, 161, 162, 176, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 204, 213 },
        note = 'Needs Review.',
    },

    ['Treasure Coffer'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Aht Urhgan Whitegate', 'Bastok Markets', 'Bastok Mines', 'Batallia Downs', 'Batallia Downs [S]', 'Beadeaux', 'Beaucedine Glacier', 'Behemoth\\'s Dominion', 'Buburimu Peninsula', 'Cape Teriggan', 'Castle Oztroja', 'Castle Zvahl Baileys', 'Cirdas Caverns [U]', 'Crawlers\\' Nest', 'Crawlers\\' Nest [S]', 'Den of Rancor', 'East Ronfaure', 'East Ronfaure [S]', 'East Sarutabaruta', 'Eastern Adoulin', 'Eastern Altepa Desert', 'Fort Karugo-Narugo [S]', 'Garlaige Citadel', 'Garlaige Citadel [S]', 'Grauberg [S]', 'Ifrit\\'s Cauldron', 'Jugner Forest', 'Jugner Forest [S]', 'Konschtat Highlands', 'Kuftal Tunnel', 'La Theine Plateau', 'Lower Jeuno', 'Meriphataud Mountains', 'Meriphataud Mountains [S]', 'Monastic Cavern', 'Newton Movalpolos', 'North Gustaberg', 'North Gustaberg [S]', 'Outer Ra\\'Kaznar [U]', 'Pashhow Marshlands', 'Pashhow Marshlands [S]', 'Port Jeuno', 'Port San d\\'Oria', 'Qufim Island', 'Quicksand Caves', 'Rala Waterways [U]', 'Ro\\'Maeve', 'Rolanberry Fields', 'Rolanberry Fields [S]', 'Ru\\'Aun Gardens', 'Sauromugue Champaign', 'Sauromugue Champaign [S]', 'Sea Serpent Grotto', 'South Gustaberg', 'Southern San d\\'Oria', 'Tahrongi Canyon', 'Temple of Uggalepih', 'The Boyahda Tree', 'The Eldieme Necropolis', 'The Eldieme Necropolis [S]', 'The Sanctuary of Zi\\'Tah', 'Toraimarai Canal', 'Upper Jeuno', 'Valkurm Dunes', 'Valley of Sorrows', 'Ve\\'Lugannon Palace', 'Vunkerl Inlet [S]', 'Walk of Echoes', 'West Ronfaure', 'West Sarutabaruta', 'West Sarutabaruta [S]', 'Western Adoulin', 'Western Altepa Desert', 'Windurst Walls', 'Windurst Waters', 'Windurst Woods', 'Xarcabard', 'Yhoator Jungle', 'Yorcia Weald [U]', 'Yuhtunga Jungle' },
        zoneIds = { 12, 50, 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 130, 147, 150, 151, 153, 159, 160, 161, 164, 169, 171, 174, 175, 176, 177, 182, 195, 197, 200, 205, 208, 230, 232, 234, 235, 238, 239, 241, 244, 245, 246, 256, 257, 259, 264, 271, 275 },
        note = 'Needs Review.',
    },

    ['Valhallan Rift'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Castle Zvahl Keep' },
        zoneIds = { 162 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Grauberg [S]', 'Pashhow Marshlands [S]', 'Rabao', 'Selbina', 'Walk of Echoes', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]', 'Xarcabard [S]' },
        zoneIds = { 89, 90, 137, 182, 247, 248, 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #00'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Attohwa', 'Abyssea - Misareaux', 'Abyssea - Vunkerl' },
        zoneIds = { 215, 216, 217 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #01'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #02'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #03'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #04'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #05'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #06'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #07'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #08'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Abyssea - Altepa', 'Abyssea - Attohwa', 'Abyssea - Grauberg', 'Abyssea - Konschtat', 'Abyssea - La Theine', 'Abyssea - Misareaux', 'Abyssea - Tahrongi', 'Abyssea - Uleguerand', 'Abyssea - Vunkerl', 'Walk of Echoes' },
        zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #09'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes' },
        zoneIds = { 182 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #1'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #10'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 182, 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #11'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 182, 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #12'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes', 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 182, 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #13'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes' },
        zoneIds = { 182 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #14'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes' },
        zoneIds = { 182 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #15'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes' },
        zoneIds = { 182 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #2'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #3'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #4'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #5'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #6'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #7'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #8'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Veridical Conflux #9'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Walk of Echoes [P1]', 'Walk of Echoes [P2]' },
        zoneIds = { 279, 298 },
        note = 'Needs Review.',
    },

    ['Waypoint'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ceizak Battlegrounds', 'Eastern Adoulin', 'Foret de Hennetiel', 'Kamihr Drifts', 'Lower Jeuno', 'Marjami Ravine', 'Morimar Basalt Fields', 'Western Adoulin', 'Yahse Hunting Grounds', 'Yorcia Weald' },
        zoneIds = { 245, 256, 257, 260, 261, 262, 263, 265, 266, 267 },
        note = 'Needs Review.',
    },

    ['Well'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Southern San d\\'Oria', 'Southern San d\\'Oria [S]' },
        zoneIds = { 80, 230 },
        note = 'Needs Review.',
    },

    ['Well of Charity'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Well of Humility'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Well of Passage'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Well of Vigilance'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Ruhotz Silvermines' },
        zoneIds = { 93 },
        note = 'Needs Review.',
    },

    ['Well-Kept Cache'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Yorcia Weald' },
        zoneIds = { 263 },
        note = 'Needs Review.',
    },

    ['White Circle'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Inner Horutoto Ruins' },
        zoneIds = { 192 },
        note = 'Needs Review.',
    },

    ['Worn Chest'] = {
        type = 'Object',
        icon = 'QuestionMark.png',
        zones = { 'Giddeus' },
        zoneIds = { 145 },
        note = 'Needs Review.',
    },

};

return itemIcons;
