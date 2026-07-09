local outpostTeleporters = {
    npcs = {
        ['Jeanvirgaud'] = true,
        ['Conrad'] = true,
        ['Rottata'] = true,
    },

    eventIds = {
        [231] = 716, -- Northern San d'Oria: Jeanvirgaud
        [234] = 581, -- Bastok Mines: Conrad
        [240] = 552, -- Port Windurst: Rottata
    },

    destinations = {
        { region = 0, name = 'Ronfaure', zone = 'West Ronfaure', expansion = 'Original Areas', level = 10, gil = 100 },
        { region = 1, name = 'Zulkheim', zone = 'Valkurm Dunes', expansion = 'Original Areas', level = 10, gil = 100 },
        { region = 2, name = 'Norvallen', zone = 'Jugner Forest', expansion = 'Original Areas', level = 15, gil = 150 },
        { region = 3, name = 'Gustaberg', zone = 'North Gustaberg', expansion = 'Original Areas', level = 10, gil = 100 },
        { region = 4, name = 'Derfland', zone = 'Pashhow Marshlands', expansion = 'Original Areas', level = 15, gil = 150 },
        { region = 5, name = 'Sarutabaruta', zone = 'West Sarutabaruta', expansion = 'Original Areas', level = 10, gil = 100 },
        { region = 6, name = 'Kolshushu', zone = 'Buburimu Peninsula', expansion = 'Original Areas', level = 10, gil = 100 },
        { region = 7, name = 'Aragoneu', zone = 'Meriphataud Mountains', expansion = 'Original Areas', level = 15, gil = 150 },
        { region = 8, name = 'Fauregandi', zone = 'Beaucedine Glacier', expansion = 'Original Areas', level = 35, gil = 350 },
        { region = 9, name = 'Valdeaunia', zone = 'Xarcabard', expansion = 'Original Areas', level = 40, gil = 400 },
        { region = 10, name = 'Qufim Island', zone = 'Qufim Island', expansion = 'Original Areas', level = 15, gil = 150 },
        { region = 11, name = "Li'Telor", zone = "The Sanctuary of Zi'Tah", expansion = 'Rise of the Zilart', level = 25, gil = 250 },
        { region = 12, name = 'Kuzotz', zone = 'Eastern Altepa Desert', expansion = 'Rise of the Zilart', level = 30, gil = 300 },
        { region = 13, name = 'Vollbow', zone = 'Cape Teriggan', expansion = 'Rise of the Zilart', level = 50, gil = 500 },
        { region = 14, name = 'Elshimo Lowlands', zone = 'Yuhtunga Jungle', expansion = 'Rise of the Zilart', level = 25, gil = 250 },
        { region = 15, name = 'Elshimo Uplands', zone = 'Yhoator Jungle', expansion = 'Rise of the Zilart', level = 35, gil = 350 },
        { region = 16, name = "Tu'Lia", zone = "Ru'Aun Gardens", expansion = 'Rise of the Zilart', level = 70, gil = 500 },
        { region = 17, name = 'Movalpolos', zone = 'Oldton Movalpolos', expansion = 'Chains of Promathia', level = 25, gil = 250 },
        { region = 18, name = 'Tavnazian Archipelago', zone = 'Lufaise Meadows', expansion = 'Chains of Promathia', level = 30, gil = 300 },
    },
};

return outpostTeleporters;
