local unity = {
    npcs = {
        ['Urbiolaine'] = true,
        ['Igsli'] = true,
        ['Teldro-Kesdrodo'] = true,
        ['Yonolala'] = true,
        ['Nunaarl Bthtrogg'] = true,
    },

    eventIds = {
        [230] = 3529, -- Southern San d'Oria
        [235] = 598,  -- Bastok Markets
        [241] = 879,  -- Windurst Woods
        [256] = 5149, -- Western Adoulin
    },

    destinations = {
        { index = 0, name = 'East Ronfaure', region = 'Ronfaure', expansion = 'Original Areas' },
        { index = 1, name = 'South Gustaberg', region = 'Gustaberg', expansion = 'Original Areas' },
        { index = 2, name = 'East Sarutabaruta', region = 'Sarutabaruta', expansion = 'Original Areas' },
        { index = 3, name = 'La Theine Plateau', region = 'Zulkheim', expansion = 'Original Areas' },
        { index = 4, name = 'Konschtat Highlands', region = 'Gustaberg', expansion = 'Original Areas' },
        { index = 5, name = 'Tahrongi Canyon', region = 'Kolshushu', expansion = 'Original Areas' },
        { index = 6, name = 'Valkurm Dunes', region = 'Zulkheim', expansion = 'Original Areas' },
        { index = 7, name = 'Buburimu Peninsula', region = 'Kolshushu', expansion = 'Original Areas' },
        { index = 8, name = 'Qufim Island', region = 'Qufim', expansion = 'Original Areas' },
        { index = 9, name = 'Bibiki Bay', region = 'Kolshushu', expansion = 'Chains of Promathia' },
        { index = 10, name = "Carpenters' Landing", region = 'Norvallen', expansion = 'Chains of Promathia' },
        { index = 11, name = 'Yuhtunga Jungle', region = 'Elshimo Lowlands', expansion = 'Rise of the Zilart' },
        { index = 12, name = 'Lufaise Meadows', region = 'Tavnazia', expansion = 'Chains of Promathia' },
        { index = 13, name = 'Jugner Forest', region = 'Norvallen', expansion = 'Original Areas' },
        { index = 14, name = 'Pashhow Marshlands', region = 'Derfland', expansion = 'Original Areas' },
        { index = 15, name = 'Meriphataud Mountains', region = 'Aragoneu', expansion = 'Original Areas' },
        { index = 16, name = 'Eastern Altepa Desert', region = 'Kuzotz', expansion = 'Rise of the Zilart' },
        { index = 17, name = 'Yhoator Jungle', region = 'Elshimo Uplands', expansion = 'Rise of the Zilart' },
        { index = 18, name = "The Sanctuary of Zi'Tah", region = "Li'Telor", expansion = 'Rise of the Zilart' },
        { index = 19, name = 'Misareaux Coast', region = 'Tavnazia', expansion = 'Chains of Promathia' },
        { index = 20, name = 'Labyrinth of Onzozo', region = 'Kolshushu', expansion = 'Original Areas' },
        { index = 21, name = 'Bostaunieux Oubliette', region = 'Ronfaure', expansion = 'Original Areas' },
        { index = 22, name = 'Batallia Downs', region = 'Norvallen', expansion = 'Original Areas' },
        { index = 23, name = 'Rolanberry Fields', region = 'Derfland', expansion = 'Original Areas' },
        { index = 24, name = 'Sauromugue Champaign', region = 'Aragoneu', expansion = 'Original Areas' },
        { index = 25, name = 'Beaucedine Glacier', region = 'Fauregandi', expansion = 'Original Areas' },
        { index = 26, name = 'Xarcabard', region = 'Valdeaunia', expansion = 'Original Areas' },
        { index = 27, name = "Ro'Maeve", region = "Li'Telor", expansion = 'Rise of the Zilart' },
        { index = 28, name = 'Western Altepa Desert', region = 'Kuzotz', expansion = 'Rise of the Zilart' },
        { index = 29, name = 'Attohwa Chasm', region = 'Tavnazia', expansion = 'Chains of Promathia' },
        { index = 30, name = 'Garlaige Citadel', region = 'Aragoneu', expansion = 'Original Areas' },
        { index = 31, name = "Ifrit's Cauldron", region = 'Elshimo Uplands', expansion = 'Rise of the Zilart' },
        { index = 32, name = 'The Boyahda Tree', region = "Li'Telor", expansion = 'Rise of the Zilart' },
        { index = 33, name = 'Kuftal Tunnel', region = 'Vollbow', expansion = 'Rise of the Zilart' },
        { index = 34, name = 'Sea Serpent Grotto', region = 'Elshimo Lowlands', expansion = 'Rise of the Zilart' },
        { index = 35, name = 'Temple of Uggalepih', region = 'Elshimo Uplands', expansion = 'Rise of the Zilart' },
        { index = 36, name = 'Quicksand Caves', region = 'Kuzotz', expansion = 'Rise of the Zilart' },
        { index = 37, name = 'Wajaom Woodlands', region = 'Aht Urhgan', expansion = 'Treasures of Aht Urhgan' },
        -- Duplicate server entries with identical landing coordinates are intentionally omitted from the quick menu:
        -- 38 Lufaise Meadows, 46 Misareaux Coast, 50 The Boyahda Tree, 52 Wajaom Woodlands, 53 Mount Zhayolm.
        { index = 39, name = 'Cape Teriggan', region = 'Vollbow', expansion = 'Rise of the Zilart' },
        { index = 41, name = 'Uleguerand Range', region = 'Fauregandi', expansion = 'Chains of Promathia' },
        { index = 42, name = 'Den of Rancor', region = 'Elshimo Uplands', expansion = 'Rise of the Zilart' },
        { index = 43, name = "Fei'Yin", region = 'Fauregandi', expansion = 'Original Areas' },
        { index = 45, name = 'Alzadaal Undersea Ruins', region = 'Aht Urhgan', expansion = 'Treasures of Aht Urhgan' },
        { index = 47, name = 'Mount Zhayolm', region = 'Aht Urhgan', expansion = 'Treasures of Aht Urhgan' },
        { index = 48, name = 'Gustav Tunnel', region = 'Vollbow', expansion = 'Original Areas' },
        { index = 49, name = "Behemoth's Dominion", region = 'Qufim', expansion = 'Rise of the Zilart' },
        { index = 51, name = 'Valley of Sorrows', region = 'Vollbow', expansion = 'Rise of the Zilart' },
        { index = 54, name = 'Caedarva Mire', region = 'Aht Urhgan', expansion = 'Treasures of Aht Urhgan' },
        { index = 55, name = 'Aydeewa Subterrane', region = 'Aht Urhgan', expansion = 'Treasures of Aht Urhgan' },
    },
};

return unity;
