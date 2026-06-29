local itemIcons = T{

-------------------------------------------------------------------------------
-- Al'Taieu Item's
-------------------------------------------------------------------------------
    ['Lumorian Gleam']      = { type = 'Organ Storage', icon = 'LumorianGleam.png', zones = { "Al'Taieu" }, location = 'Taieu H12', worldOffsetY = 0.25, note = 'stow and retrieve sea monster organs' },

-------------------------------------------------------------------------------
-- Attohwa Chasm Item's
-------------------------------------------------------------------------------
    ['Nyx\'s Essence']     = { type = 'Summit Quest Fight', icon = 'QuestionMark.png', zones = { "Attohwa Chasm" }, location = 'Attohwa Chasm, top of Parradamo Tor', worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Interact after placing all three beastmen offerings.\n* Starts the Nyx Animus alliance battle for Summit access.' },
    ['Orc\'s Essence']     = { type = 'Summit Offering Turn-in', icon = 'QuestionMark.png', zones = { "Attohwa Chasm" }, location = 'Attohwa Chasm, top of Parradamo Tor', worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to place the Orc Offering.\n* One set of offerings is enough per alliance.' },
    ['Quadav\'s Essence']  = { type = 'Summit Offering Turn-in', icon = 'QuestionMark.png', zones = { "Attohwa Chasm" }, location = 'Attohwa Chasm, top of Parradamo Tor', worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to place the Quadav Offering.\n* One set of offerings is enough per alliance.' },
    ['Yagudo\'s Essence']  = { type = 'Summit Offering Turn-in', icon = 'QuestionMark.png', zones = { "Attohwa Chasm" }, location = 'Attohwa Chasm, top of Parradamo Tor', worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to place the Yagudo Offering.\n* The final offering immediately spawns the boss sequence.' },

-------------------------------------------------------------------------------
-- Balga's Dias Item's
-------------------------------------------------------------------------------
    ['Dirt']               = { type = 'System Unlock Quest', icon = 'QuestionMark.png', zones = { "Balga's Dias", "Waughroon Shrine", "Horlais Peak" }, worldOffsetY = 0.25, note = 'Digging Up Dirt:\n* Inspect hidden Dirt inside BCNM rooms for Sebastian.\n* Used to unlock Domenic\'s BCNM teleports.' },

-------------------------------------------------------------------------------
-- Carpenters' Landing Item's
-------------------------------------------------------------------------------
    ['Crooked Trunk']      = { type = 'CW Storage Unlock', icon = 'QuestionMark.png', zones = { "Carpenters\' Landing" }, location = "Carpenters' Landing G-9, by collapsed bridge", worldOffsetY = 0.25, note = 'Boxed Up:\n* Inspect during Rusty Hammer\'s Ephemeral Box unlock quest.\n* Triggers the level 40 capped Treant fight, then inspect again.' },

-------------------------------------------------------------------------------
-- Castle Oztroja Item's
-------------------------------------------------------------------------------
    ['Yagudo Offering']    = { type = 'Summit Offering', icon = 'QuestionMark.png', zones = { "Castle Oztroja" }, worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to receive the Yagudo Offering for the Summit unlock quest.\n* Offering location changes every in-game hour.' },

-------------------------------------------------------------------------------
-- Crawlers' Nest Item's
-------------------------------------------------------------------------------
    ['Vantage Point']      = { type = 'HELM Unlock Quest', icon = 'QuestionMark.png', zones = { "Crawlers\' Nest" }, location = "Crawlers' Nest J-9, Map 1", worldOffsetY = 0.25, note = 'Thread Bare:\n* Investigate for Mathias.\n* Used to unlock harvesting in Crawlers\' Nest.' },

-------------------------------------------------------------------------------
-- Dangruf Wadi Item's
-------------------------------------------------------------------------------
    ['Brittle Rocks']      = { type = 'CW Intro Gather', icon = 'QuestionMark.png', zones = { "Dangruf Wadi" }, worldOffsetY = 0.25, note = 'A Crystal Prelude:\n* Bastokan gathering point.\n* Trade the Pickaxe from Iron Wolf to receive the quest material.' },

-------------------------------------------------------------------------------
-- East Ronfaure Item's
-------------------------------------------------------------------------------
    ['Large Hoofprint']    = { type = 'Novice Trial NM', icon = 'Footprint.png', zones = { "East Ronfaure" }, location = 'East Ronfaure I-9', worldOffsetY = 0.25, note = 'Novice Trials:\n* Trade Baked Apple x3 to spawn Rambling Ram.\n* Used by Serpette augment trials.' },
    ['Lost Present']       = { type = 'Holiday Event', icon = 'Box.png', zones = { "East Ronfaure", "South Gustaberg", "West Sarutabaruta" }, worldOffsetY = 0.25, note = 'Holiday Event:\n* Courier Helper objective.\n* Click the lost present in the field, then return to the Courier Helper for credit.' },

-------------------------------------------------------------------------------
-- East Sarutabaruta Item's
-------------------------------------------------------------------------------
    ['Glittering Gift']    = { type = 'Holiday Event', icon = 'QuestionMark.png', zones = { "East Sarutabaruta", "North Gustaberg", "West Ronfaure" }, worldOffsetY = 0.25, note = 'Holiday Event:\n* Clickable object left behind after defeating a Twinkle Treant.\n* Rewards a Special Present.\n* First present in each region can reward the nation tree furnishing.' },

-------------------------------------------------------------------------------
-- Fort Karugo-Narugo [S] Item's
-------------------------------------------------------------------------------
    ['Buried Note']        = { type = 'HELM Unlock Quest', icon = 'QuestionMark.png', zones = { "Fort Karugo-Narugo [S]" }, location = 'Fort Karugo-Narugo [S] E-8, west exit cliff', worldOffsetY = 0.25, note = 'Broken Bones:\n* Inspect to receive a crumpled note for Felyna.\n* Used to unlock excavation in Labyrinth of Onzozo.' },

-------------------------------------------------------------------------------
-- Gustav Tunnel Item's
-------------------------------------------------------------------------------
    ['Miner\'s Helmet']    = { type = 'HELM Unlock Quest', icon = 'QuestionMark.png', zones = { "Gustav Tunnel" }, location = 'Gustav Tunnel D-11', worldOffsetY = 0.25, note = 'Here Be Dragons:\n* Inspect to spawn Ore Melter for Khartes.\n* Used to unlock mining in Gustav Tunnel.' },

-------------------------------------------------------------------------------
-- King Ranperre's Tomb Item's
-------------------------------------------------------------------------------
    ['Loose Branch']       = { type = 'CW Intro Gather', icon = 'QuestionMark.png', zones = { "King Ranperre's Tomb" }, worldOffsetY = 0.25, note = 'A Crystal Prelude:\n* San d\'Orian gathering point.\n* Trade the Hatchet from Robineaux to receive the quest material.' },

-------------------------------------------------------------------------------
-- Konschtat Highlands Item's
-------------------------------------------------------------------------------
    ['Hume Footprint']     = { type = 'CW Early Gear', icon = 'Footprint.png', zones = { "Konschtat Highlands" }, location = 'Konschtat Highlands L-8', worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Starts quest: Head First.\n* Level 15 early gear quest.' },
    ['Lost Tongs']         = { type = 'Novice Trial NM', icon = 'QuestionMark.png', zones = { "Konschtat Highlands" }, location = 'Konschtat Highlands G-7', worldOffsetY = 0.25, note = 'Novice Trials:\n* Trade Bronze Ingot x3 to spawn Goblin Armorer.\n* Used by Scale Mail and Scale Cuisses augment trials.' },

-------------------------------------------------------------------------------
-- La Theine Plateau Item's
-------------------------------------------------------------------------------
    ['Crystal Anomaly']    = { type = 'CW Trust Fight', icon = 'QuestionMark.png', zones = { "La Theine Plateau", "Konschtat Highlands", "Tahrongi Canyon" }, worldOffsetY = 0.25, note = 'Matter of Trust I:\n* Inspect to begin the level 10 Crystal Weapon encounter.\n* Locations: La Theine L-8, Konschtat K-5, Tahrongi I-5.' },
    ['Lost Lockpick']      = { type = 'Novice Trial NM', icon = 'QuestionMark.png', zones = { "La Theine Plateau" }, location = 'La Theine Plateau C-5', worldOffsetY = 0.25, note = 'Novice Trials:\n* Trade Sheep Leather x3 to spawn Goblin Burglar.\n* Used by Doublet and Brais augment trials.' },

-------------------------------------------------------------------------------
-- Lower Jeuno Item's
-------------------------------------------------------------------------------
	['EXP Guide']          = { type = 'EXP Guide', icon = 'EXPGuide.png', zones = { "Lower Jeuno" }, zoneIds = { 245 }, location = 'Lower Jeuno Auction House', worldOffsetY = 0.25, note = 'CatsEyeXI:\n* Free warp book for Signet and Sanction EXP camps.\n* Unlocks after Near Death Experience from Andrus in Lufaise Meadows.\n* Trade 1 gil for a secret menu.\n* Crystal Warriors cannot use this book.' },
	['Golden Tiger'] = { type = 'Event', icon = 'Event.png', zones = { 'Lower Jeuno' }, zoneIds = { 245 }, worldOffsetY = 0.25, hidden = true },

-------------------------------------------------------------------------------
-- Lufaise Meadows Item's
-------------------------------------------------------------------------------
    ['Shredded Page']      = { type = 'EXP Guide Unlock', icon = 'QuestionMark.png', zones = { "Lufaise Meadows", "Batallia Downs (S)" }, worldOffsetY = 0.25, note = 'Near Death Experience / Blast to the Past:\n* Third missing page objective.\n* Spawns the level 60 sync NM for the EXP Guide unlock quest.' },
    ['Tattered Page']      = { type = 'EXP Guide Unlock', icon = 'QuestionMark.png', zones = { "Lufaise Meadows", "Batallia Downs (S)" }, worldOffsetY = 0.25, note = 'Near Death Experience / Blast to the Past:\n* Second missing page objective for the EXP Guide unlock quest.' },
    ['Torn Page']          = { type = 'EXP Guide Unlock', icon = 'QuestionMark.png', zones = { "Lufaise Meadows", "Batallia Downs (S)" }, worldOffsetY = 0.25, note = 'Near Death Experience / Blast to the Past:\n* First missing page objective for the EXP Guide unlock quest.' },

-------------------------------------------------------------------------------
-- Meriphataud Mountains Item's
-------------------------------------------------------------------------------
    ['Yagudo Tracks']      = { type = 'CW Arena Entry', icon = 'Footprint.png', zones = { "Meriphataud Mountains" }, location = 'Meriphataud Mountains K-8', worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Starts the level 50 Yagudo Arena after unlocking with Yagudo Outlaw.\n* Return to Yagudo Outlaw afterward to select a reward set.' },

-------------------------------------------------------------------------------
-- Monastic Cavern Item's
-------------------------------------------------------------------------------
    ['Orc Offering']       = { type = 'Summit Offering', icon = 'QuestionMark.png', zones = { "Monastic Cavern" }, worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to receive the Orc Offering for the Summit unlock quest.\n* Offering location changes every in-game hour.' },

-------------------------------------------------------------------------------
-- Norg Item's
-------------------------------------------------------------------------------
    ['Sinister Stash']     = { type = 'Doubloon Fish Daily', icon = 'Box.png', zones = { "Norg" }, worldOffsetY = 0.25, location = 'Norg H-8', note = 'CatsEyeXI:\n* Level 20+ daily fish turn-in in Norg (H-8), paired with Crooked Jones.\n* Used for the doubloon fishing daily and treasure hunt rewards.' },

-------------------------------------------------------------------------------
-- Provenance Item's
-------------------------------------------------------------------------------
    ['Campfire']           = { type = 'CW Crafting Buff', icon = 'QuestionMark.png', zones = { "Provenance" }, worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Trade a log while food is active for crafting bonuses.\n* Zoning out of Provenance removes the food buff.' },
    ['Crystal Guide']      = { type = 'CW Issue Recovery', icon = 'QuestionMark.png', zones = { "Provenance" }, worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Handles recovery services formerly handled by Carnelian.\n* Choose "Something isn\'t right..." to restore missed rewards, trusts, inventory slots, and titles.\n* Use before converting Unbreakable to Standard.' },
    ['Crystal Guide Book'] = { type = 'CW Issue Recovery', icon = 'QuestionMark.png', zones = { "Provenance" }, worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Handles recovery services formerly handled by Carnelian.\n* Choose "Something isn\'t right..." to restore missed rewards, trusts, inventory slots, and titles.\n* Use before converting Unbreakable to Standard.' },

-------------------------------------------------------------------------------
-- Qulun Dome Item's
-------------------------------------------------------------------------------
    ['Quadav Offering']    = { type = 'Summit Offering', icon = 'QuestionMark.png', zones = { "Qulun Dome" }, worldOffsetY = 0.25, note = 'Summit of the Stars:\n* Click to receive the Quadav Offering for the Summit unlock quest.\n* Offering location changes every in-game hour.' },

-------------------------------------------------------------------------------
-- Rabao Item's
-------------------------------------------------------------------------------
    ['Book of Mastery']    = { type = 'Adept Reforging', icon = 'QuestionMark.png', zones = { "Rabao" }, location = 'Rabao J-6, next to Adeptus', worldOffsetY = 0.25, note = 'Adept Reforging:\n* Cancels current Adept trial.\n* Transfers augments from augmented NQ armor to an unaugmented HQ version before the third trial.\n* The NQ armor is consumed during transfer.' },

-------------------------------------------------------------------------------
-- Ru'Lude Gardens Item's
-------------------------------------------------------------------------------
    ['Dragon Lore']        = { type = 'Dragonslaying Merit Storage', icon = 'QuestionMark.png', zones = { "Ru\'Lude Gardens" }, location = "Ru'Lude Gardens G-9", worldOffsetY = 0.25, note = 'Dragonslaying:\n* Stores merit points for later DKP pop item purchases.\n* Alternative merit storage to Sigmund in Mhaura.' },
    ['EXP Guide (S)']      = { type = 'EXP Guide (S)', icon = 'EXPGuideS.png', zones = { "Ru'Lude Gardens" }, location = "Ru'Lude Gardens, near the Mog House", worldOffsetY = 0.25, note = 'CatsEyeXI:\n* Free warp book for Sigil EXP camps.\n* Unlocks after Blast to the Past from Ash in Batallia Downs (S).\n* Trade 1 gil for a secret menu to Xarcabard (S) G-7 near Caracal.\n* Crystal Warriors may use this book.' },
    ['Faded Footprint']    = { type = 'CW Armor Quest', icon = 'Footprint.png', zones = { "Ru\'Lude Gardens" }, location = "Ru'Lude Gardens H-7", worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Level 30 armor quest: Empty Handed.\n* Rewards Shade Harness Set.' },

-------------------------------------------------------------------------------
-- Southern San d'Oria Item's
-------------------------------------------------------------------------------
    ['Ephemeral Box']      = { type = 'CW Material Storage', icon = 'EphemeralBox.png', zones = { "Southern San d\'Oria" }, worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Material and collectible storage for Crystal Warriors.\n* Unlocks additional wardrobe slots through the Boxed Up quest.' },

-------------------------------------------------------------------------------
-- Tahrongi Canyon Item's
-------------------------------------------------------------------------------
    ['Lost Needle']        = { type = 'Novice Trial NM', icon = 'QuestionMark.png', zones = { "Tahrongi Canyon" }, location = 'Tahrongi Canyon G-9', worldOffsetY = 0.25, note = 'Novice Trials:\n* Trade Cotton Thread x3 to spawn Goblin Tailor.\n* Used by Linen Robe and Linen Slops augment trials.' },
    ['Mithra Tracks']      = { type = 'CW Early Gear', icon = 'Footprint.png', zones = { "Tahrongi Canyon" }, location = 'Tahrongi Canyon J-8', worldOffsetY = 0.25, note = 'Crystal Warrior:\n* Starts quest: Likely Tails.\n* Level 15 early gear quest.' },

-------------------------------------------------------------------------------
-- The Sanctuary of Zi'Tah Item's
-------------------------------------------------------------------------------
    ['Pile of Stones']     = { type = 'Dragonslayer Intro', icon = 'MiningPoint.png', zones = { "The Sanctuary of Zi\'Tah" }, location = "The Sanctuary of Zi'Tah H-7", worldOffsetY = 0.25, note = 'Dragonslaying:\n* Trade a Pickaxe here during the Dragonslayer intro quest.\n* If nothing happens, return to Sigmund and exhaust dialogue.' },

-------------------------------------------------------------------------------
-- Toraimarai Canal Item's
-------------------------------------------------------------------------------
    ['Dangling Root']      = { type = 'CW Intro Gather', icon = 'QuestionMark.png', zones = { "Toraimarai Canal" }, worldOffsetY = 0.25, note = 'A Crystal Prelude:\n* Windurstian gathering point.\n* Trade the Sickle from Erudu-Faludu to receive the quest material.' },

-------------------------------------------------------------------------------
-- Upper Delkfutt's Tower Item's
-------------------------------------------------------------------------------
    ['Training Supplies']  = { type = 'Outpost Unlock Quest', icon = 'QuestionMark.png', zones = { "Upper Delkfutt's Tower" }, location = "Upper Delkfutt's Tower I-9, Map 1 tenth floor", worldOffsetY = 0.25, note = 'Up, Up and Away:\n* Quest object for Disarmed Knight.\n* Located in Porphyrion\'s room by the elevator, sometimes behind the secret chest.' },

-------------------------------------------------------------------------------
-- ZZZ (No zone) Item's
-------------------------------------------------------------------------------
    ['Gobbie Mystery Box'] = { type = 'Daily Box', icon = 'GobbieMysteryBox.png' },

};
return itemIcons;
