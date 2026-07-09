local campaignArbiters = {
    npcs = {
        ['Scarlette, C.A.'] = true,
        ['Scarlette_CA'] = true,
        ['Narkissa, C.A.'] = true,
        ['Narkissa_CA'] = true,
        ['Wenonah, C.A.'] = true,
        ['Wenonah_CA'] = true,
        ['Addison, C.A.'] = true,
        ['Addison_CA'] = true,
        ['Felicia, C.A.'] = true,
        ['Felicia_CA'] = true,
        ['Marius, C.A.'] = true,
        ['Marius_CA'] = true,
    },

    eventIds = {
        [80] = 458, -- Southern San d'Oria [S]: Scarlette, C.A. captured on CatsEye.
        [87] = 458, -- Bastok Markets [S]: Narkissa, C.A. uses the same Campaign Arbiter flow.
        [94] = 458, -- Windurst Waters [S]: Wenonah, C.A. uses the same Campaign Arbiter flow.
        [83] = 458, -- Vunkerl Inlet [S]: Felicia, C.A.
        [95] = 458, -- West Sarutabaruta [S]: Addison, C.A.
        [98] = 458, -- Sauromugue Champaign [S]: Marius, C.A.
    },

    destinations = {
        { index = 1, name = 'Xarcabard [S]' },
        { index = 2, name = 'Beaucedine Glacier [S]' },
        { index = 3, name = 'Batallia Downs [S]' },
        { index = 4, name = 'Rolanberry Fields [S]' },
        { index = 5, name = 'Sauromugue Champaign [S]' },
        { index = 6, name = 'Jugner Forest [S]' },
        { index = 7, name = 'Pashhow Marshlands [S]' },
        { index = 8, name = 'Meriphataud Mountains [S]' },
        { index = 9, name = 'Vunkerl Inlet [S]' },
        { index = 10, name = 'Grauberg [S]' },
        { index = 11, name = 'Fort Karugo-Narugo [S]' },
        { index = 12, name = 'East Ronfaure [S]' },
        { index = 13, name = 'North Gustaberg [S]' },
        { index = 14, name = 'West Sarutabaruta [S]' },
        { index = 15, name = "Southern San d'Oria [S]" },
        { index = 16, name = 'Bastok Markets [S]' },
        { index = 17, name = 'Windurst Waters [S]' },
        { index = 18, name = 'Garlaige Citadel [S]' },
        { index = 19, name = "Crawlers' Nest [S]" },
        { index = 20, name = 'The Eldieme Necropolis [S]' },
    },
};

return campaignArbiters;
