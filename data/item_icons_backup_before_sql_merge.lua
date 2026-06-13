local itemIcons = T{

    -------------------------------------------------------------------------------
    -- Multi-Zone
    -------------------------------------------------------------------------------
    ['Auction Counter']          = { type = 'Auction House', icon = 'AuctionManager.png', zones = {"Bastok Mines", "Bastok Markets", "Southern San d'Oria", "Port San d'Oria", "Windurst Woods", "Windurst Walls", "Lower Jeuno", "Ru'Lude Gardens", "Aht Urhgan Whitegate", "Western Adoulin", "Eastern Adoulin" }, worldOffsetY = -0.50 },
    ['Synergy Furnace']          = { type = 'Synergy Furnace', icon = 'craft_01.png', zones = { "Bastok Markets", "Port Bastok", "Northern San d'Oria", "Southern San d'Oria", "Port Windurst", "Windurst Waters", "Upper Jeuno", "Lower Jeuno", "Port Jeuno" }, worldOffsetY = 0.20 },

    -------------------------------------------------------------------------------
    -- Lower Jeuno
    -------------------------------------------------------------------------------
    ['Door:Othon\'s Garments']   = { type = 'Garments Shop', icon = 'Door.png', zones = { "Lower Jeuno" } },

    -------------------------------------------------------------------------------
    -- Northern San d'Oria
    -------------------------------------------------------------------------------
    ['Chat Manual']              = { type = 'Tutorial', icon = 'TutorialNPC.png', zones = { "Northern San d'Oria" }, worldOffsetY = 0.50 },
    ['Door:Bastokan Consul']     = { type = 'Consulate', icon = 'Door.png', zones = { "Northern San d'Oria" } },
    ['Door:Jeunoan Consul']      = { type = 'Consulate', icon = 'Door.png', zones = { "Northern San d'Oria" } },
    ['Door:Manuscript Room']     = { type = 'Manuscript Room', icon = 'MissionNPC.png', zones = { "Northern San d'Oria" } },
    ['Door:Papal Chambers']      = { type = 'Papal Chambers', icon = 'Door.png', zones = { "Northern San d'Oria" } },
    ['Door:Reliquary']           = { type = 'Reliquary', icon = 'Door.png', zones = { "Northern San d'Oria" } },
    ['Door. Chantry']            = { type = 'Chantry', icon = 'Door.png', zones = { "Northern San d'Oria" } },
    ['Odyssean Passage']         = { type = 'Odyssey Entry', icon = 'Event.png', zones = { "Northern San d'Oria" } },

    -------------------------------------------------------------------------------
    -- Southern San d'Oria
    -------------------------------------------------------------------------------
    ['???']                      = { type = 'Hidden Object', icon = 'QuestionMark.png', zones = { "Southern San d'Oria" }, worldOffsetY = 0.20 },
    ['Crystal Crunch']           = { type = 'Crystal Exchange', icon = 'CrystalCrunch.png', zones = { "Southern San d'Oria" }, worldOffsetY = 0.60 },
    ['Door:Count\'s Manor']      = { type = 'Residence', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Door:Helbort\'s Blades']   = { type = 'Weapon Shop', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Door:House']               = { type = 'Residence', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Door:Raimbroy\'s Grocery'] = { type = 'Grocery Shop', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Door:Rosel\'s Armour']     = { type = 'Armor Shop', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Door:Tanners\' Guild']     = { type = 'Leathercraft Guild', icon = 'GuildMerchant.png', zones = { "Southern San d'Oria" } },
    ['Door:Taumila\'s Sundries'] = { type = 'General Store', icon = 'Door.png', zones = { "Southern San d'Oria" } },
    ['Enigmatic Footprints #1']  = { type = 'Cutscene Replay', icon = 'Cutscene.png', zones = { "Southern San d'Oria" }, worldOffsetY = 0.0 },
    ['Mystic Retriever']         = { type = 'Reward Retrieval', icon = 'Reward.png', zones = { "Southern San d'Oria" }, worldOffsetY = 0.50 },
    ['Well']                     = { type = 'Fresh Water', icon = 'QuestionMark.png', zones = { "Southern San d'Oria" }, worldOffsetY = 0.0 },

    -------------------------------------------------------------------------------
    -- Misc
    -------------------------------------------------------------------------------
    ['Bag']                      = { type = 'Bag', icon = 'Bag.png' },
    ['Barrel']                   = { type = 'Barrel', icon = 'Barrel.png' },
    ['Bookshelf']                = { type = 'Bookshelf', icon = 'Bookshelf.png' },
    ['Box']                      = { type = 'Box', icon = 'Box.png' },
    ['Burning Circle']           = { type = 'Burning Circle', icon = 'BurningCircle.png' },
    ['Clamming Point']           = { type = 'Clamming Point', icon = 'ClammingPoint.png' },
    ['Cavernous Maw']            = { type = 'Cavernous Maw', icon = 'CavernousMaw.png' },
    ['Crate']                    = { type = 'Crate', icon = 'Crate.png' },
    ['Ergon Locus']              = { type = 'Ergon Locus', icon = 'ErgonLocus.png' },
    ['Ethereal Junction']        = { type = 'Ethereal Junction', icon = 'EtherealJunction.png' },
    ['Excavation Point']         = { type = 'Excavation Point', icon = 'ExcavationPoint.png' },
    ['Faded Footprint']          = { type = 'Faded Footprint', icon = 'Footprint.png' },
    ['Fish Trap']                = { type = 'Fish Trap', icon = 'FishTrap.png' },
    ['Footprint']                = { type = 'Footprint', icon = 'Footprint.png' },
    ['Geomagnetic Fount']        = { type = 'Geomagnetic Fount', icon = 'GeomagneticFount.png' },
    ['Harvest Point']            = { type = 'Harvest Point', icon = 'HarvestPoint.png' },
    ['Home Point #1']            = { type = 'Home Point', icon = 'HomePoint1.png', worldOffsetZ = -1.5, offsetX = 40 },
    ['Home Point #2']            = { type = 'Home Point', icon = 'HomePoint2.png', offsetY = -210, offsetX = 55 },
    ['Home Point #3']            = { type = 'Home Point', icon = 'HomePoint3.png', offsetY = -210, offsetX = 55 },
    ['Home Point #4']            = { type = 'Home Point', icon = 'HomePoint4.png', offsetY = -210, offsetX = 55 },
    ['Home Point #5']            = { type = 'Home Point', icon = 'HomePoint5.png', offsetY = -210, offsetX = 55 },
    ['Home Point #6']            = { type = 'Home Point', icon = 'HomePoint6.png', offsetY = -210, offsetX = 55 },
['Logging Point'] = {
    type = '',
    icon = 'LoggingPoint.png',
    zones = { 'Bibiki Bay' },
    zoneIds = { 4 },
    worldOffsetY = 1.2,
},
    ['Mining Point']             = { type = 'Mining Point', icon = 'MiningPoint.png' },
    ['Monument']                 = { type = 'Monument', icon = 'Monument.png' },
    ['Nyzul Isle Staging Point'] = { type = 'Nyzul Isle Staging Point', icon = 'NyzulIsleStagingPoint.png' },
    ['Planar Rift']              = { type = 'Planar Rift', icon = 'PlanarRift.png' },
    ['Proto-Waypoint']           = { type = 'Proto-Waypoint', icon = 'ProtoWaypoint.png' },
    ['Runic Portal']             = { type = 'Runic Portal', icon = 'RunicPortal.png' },
    ['Sack']                     = { type = 'Sack', icon = 'Sack.png' },
    ['Shimmering Circle']        = { type = 'Shimmering Circle', icon = 'ShimmeringCircle.png' },
    ['Signpost']                 = { type = 'Signpost', icon = 'Signpost.png' },
    ['Strange Apparatus']        = { type = 'Strange Apparatus', icon = 'StrangeApparatus.png' },
    ['Sturdy Pyxis']             = { type = 'Sturdy Pyxis', icon = 'SturdyPyxis.png' },
    ['Survival Guide']           = { type = 'Survival Guide', icon = 'SurvivalGuide.png' },
    ['Treasure Casket']          = { type = 'Treasure Casket', icon = 'TreasureCasket.png' },
    ['Treasure Chest']           = { type = 'Treasure Chest', icon = 'TreasureChest.png' },
    ['Treasure Coffer']          = { type = 'Treasure Coffer', icon = 'TreasureCoffer.png' },
    ['Veridical Conflux']        = { type = 'Veridical Conflux', icon = 'VeridicalConflux.png' },
    ['Waypoint']                 = { type = 'Waypoint', icon = 'Waypoint.png' },
    ['Door: Amchuchu\'s Laboratory']    = { type = "Door", icon = "Dialogue.png", zones = { "Western Adoulin" }, note = "Starts Quests:\n* Vegetable Vegetable EvolutionVegetable Vegetable RevolutionVegetable Vegetable Crisis" },
    ['Door: Svenja\'s Manor']           = { type = "Door", icon = "Dialogue.png", zones = { "Western Adoulin" }, note = "Starts Quests:\n* Flowers for SvenjaDo Not Go Into the Light" },

    };

return itemIcons;
