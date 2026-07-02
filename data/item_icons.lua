local itemIcons = T{
-- Mog Garden (Rearing Grounds)


["Bulging Crate"] = {
    type = "Feed Storage",
    icon = "Crate.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
},

    -------------------------------------------------------------------------------
    -- Multi-Zone
    -------------------------------------------------------------------------------
	
["Atomos"] = {
    type = "Cavernous Maw",
    icon = "CavernousMaw.png",
    zones = { "Beaucedine Glacier [S]", "Hall of Transference", "La Theine Plateau" },
    zoneIds = { 14, 102, 136 },
    note = "A massive spatial distortion and timeline gateway. Stepping into this gaping anomaly rips you through the fabric of time, depositing you into past eras or deep within the Halls of Transference.",
},

["Auroral Updraft"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Al'Taieu" },
    zoneIds = { 33 },
    note = "A shimmering reddish vertical beam of energy rising from the ruins of the Celestial Capital. Stepping directly into this light launches you upward to ascend into Sealion's Den or navigate between the geographical palace rings.",
},

["Aurum Strongbox"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "A high-tier gilded treasure repository manifested inside the fractured instances of the Walk of Echoes. Cracking this stubborn lock unlocks endgame currency and equipment upgrades to bolster your localized combat capabilities.",
},

["Backfilled Pit"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A concealed excavation site buried beneath the snowy cliffside ramparts of the past timeline. Digging into this loose dirt mound uncovers critical evidence needed to advance your active military campaign quests.",
},

["Banishing Gate #1"] = {
    type = "Security Gate",
    icon = "BanishingGate.png",
    zones = { "Garlaige Citadel", "Garlaige Citadel [S]" },
    zoneIds = { 200, 164 },
    note = "The first heavy barrier blockading the ancient subterranean fortress. You must have four adventurers stand on the surrounding floor pressure plates simultaneously, or utilize a specialized key item, to lift the door and advance.",
},

["Banishing Gate #2"] = {
    type = "Security Gate",
    icon = "BanishingGate.png",
    zones = { "Garlaige Citadel", "Garlaige Citadel [S]" },
    zoneIds = { 200, 164 },
    note = "The second defensive partition deeper inside the military ruins. Tripping the regional pressure weight sensors with a full party or bypass token raises the gate, allowing your squad to dive further into the dungeon vaults.",
},

["Banishing Gate #3"] = {
    type = "Security Gate",
    icon = "BanishingGate.png",
    zones = { "Garlaige Citadel", "Garlaige Citadel [S]" },
    zoneIds = { 200, 164 },
    note = "The final physical security checkpoint protecting the deepest recesses of the citadel. Coordinate with your allies on the localized floor mechanisms to trigger the heavy winches and open the pathway ahead.",
},

["Barnacled Box"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Valkurm Dunes" },
    zoneIds = { 103 },
    note = "A waterlogged, shell-encrusted chest washed up onto the shoreline. Prying it open unlocks hidden regional items, gil, or unique supplies to assist your low-level coastal leveling parties.",
},

["Beastmen's Banner"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Beaucedine Glacier", "Buburimu Peninsula", "Cape Teriggan", "Eastern Altepa Desert", "Jugner Forest", "Meriphataud Mountains", "Pashhow Marshlands", "Qufim Island", "Qulun Dome", "The Sanctuary of Zi'Tah", "Valkurm Dunes", "Xarcabard", "Yhoator Jungle", "Yuhtunga Jungle" },
    zoneIds = { 103, 104, 109, 111, 112, 113, 114, 118, 119, 121, 123, 124, 126, 148 },
    note = "A military standard planted deep within hostile territory. Securing this tactical marker advances your localized Expeditionary Force objectives and shifts continental conquest influence metrics.",
},

["Blockaded Path"] = {
    type = "Obstacle Node",
    icon = "BlockadedPath.png",
    zones = { "Kamihr Drifts" },
    zoneIds = { 267 },
    note = "A dense, impassable natural barrier choked by structural ice and mountain detritus. You must apply specialized logging skills or local survival tools to clear the passage and explore further into the frozen drifts.",
},

["Bloodstained Glove"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Foret de Hennetiel" },
    note = "A discarded, soil-caked piece of leather equipment left behind in the dense wilderness. Inspecting the gruesome stains uncovers clues tied to ongoing frontier investigations or localized storyline progression.",
},

["Blue Rafflesia"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Yuhtunga Jungle" },
    zoneIds = { 123 },
    note = "A rare, pungent tropical blossom thriving deep in the dense jungle undergrowth. Harvesting this exotic flora fulfills critical gathering quotas for active regional questlines.",
},

["Bottomless Box"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Tahrongi" },
    zoneIds = { 45 },
    note = "An enigmatic, dimensional coffer materializing out of the Abyssean static. Breaking past its ward reveals powerful temporal rewards, resistance gear, or specialized regional key items.",
},

["Brash Gate"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "A heavy, monolithic barrier blocking the shadow-drenched corridors of Ra'Kaznar. Activating the nearby ancient mechanism lifts the plate, allowing your party to plunge deeper into the dark underworld.",
},

["Brass Door"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Castle Oztroja", "Castle Oztroja [S]" },
    zoneIds = { 99, 151 },
    note = "A reinforced metallic portal locking off the elite chambers of the Yagudo hierarchy. Solving the surrounding lever puzzles or utilizing the correct passkey releases the latch to let you pass.",
},

["Brass Gong"] = {
    type = "Event Trigger",
    icon = "Chamberlain.png",
    zones = { "Navukgo Execution Chamber" },
    zoneIds = { 64 },
    note = "A massive metallic instrument hanging in the heart of the imperial battlefield arena. Striking its surface rings out across the chamber, sealing your fate and initiating challenging localized battlefield encounters.",
},

["Bridge"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Spire of Vahzl" },
    zoneIds = { 23 },
    note = "An ethereal pathway constructed from solidified crystalline energy. Stepping onto this shimmering span allows you to cross the dimensional void and access higher floors within the Spire.",
},

["Bridge Switch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A mechanical wall lever hidden within the seafaring staging grounds. Toggling this handle raises or lowers the structural floor spans, altering path layouts during regional operations.",
},

["Bulwark Gate"] = {
    type = "Security Gate",
    icon = "Gate.png",
    zones = { "Sauromugue Champaign [S]" },
    zoneIds = { 98 },
    note = "A reinforced military barricade blockading the strategic valley pass in the past timeline. Tripping the surrounding tactical levers unlatches the heavy framing to grant entry across the frontlines.",
},

["Buried Treasure"] = {
    type = "Loot Container",
    icon = "TreasureChest.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A concealed cache of valuable goods buried beneath the mineral dust of the silver mines. Unearthing this chest reveals rare resources, currency caches, or unique regional items.",
},

["Cage Door"] = {
    type = "Security Gate",
    icon = "Gate.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "An iron-barred barrier locking off a subterranean cell block. Tracking down the specialized reef skeleton key lets you unlock the latch to free captives or venture into the deeper grottos.",
},

["Cage Fence"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "The Colosseum" },
    zoneIds = { 71 },
    note = "A sturdy structural divider enclosing the arena combat pits. Activating the stadium control triggers drops the iron mesh, releasing combatants directly into the competitive ring.",
},

["Camp Remnants"] = {
    type = "Quest Node",
    icon = "Pioneer.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "The charred soot and ash of an abandoned coastal campsite. Sifting through the debris uncovers forgotten logs or lost investigator supplies tied to active tracking missions.",
},

["Cargo Crate"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "A weathered supply storage container abandoned amidst the Abyssean wasteland. Prying open its reinforced lid yields valuable consumables, localized quest objects, or tactical support gear.",
},

["Cargo Ship Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Open Sea Route to Al Zahbi", "Open Sea Route to Mhaura", "Ship Bound for Mhaura", "Ship Bound for Mhaura (Pirates)", "Ship Bound for Selbina", "Ship Bound for Selbina (Pirates)", "Silver Sea Route to Al Zahbi", "Silver Sea Route to Nashmau" },
    zoneIds = { 46, 47, 58, 59, 220, 221, 227, 228 },
    note = "The heavy wooden cabin door separating the main deck from the lower berths. Stepping through allows you to seek shelter from open-sea weather anomalies or retreat safely when high-seas pirate raids ambush your vessel.",
},

["Cast Bronze Gate"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Halvung", "Navukgo Execution Chamber" },
    zoneIds = { 62, 64 },
    note = "A massive metallic partition forged from heavy bronze in the subterranean volcanic fortress. Forcing this barrier open gives you access to the volcanic underworld or leads directly into the arena combat pits.",
},

["Cast Bronze Hatch"] = {
    type = "Security Gate",
    icon = "portcullis.png",
    zones = { "Halvung" },
    zoneIds = { 62 },
    note = "A reinforced metallic deck hatch blocking off the lower vents of the Troll stronghold. Releasing its heavy locks lets you drop into the searing geothermal tunnels hidden below.",
},

["Cavalry Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A fortified outpost door positioned along the defensive battlements of the past timeline. Clearing local military clearance protocols unlocks the framework, allowing your squad to move between garrison rings.",
},

["Cavalry Gate"] = {
    type = "Security Gate",
    icon = "Gate.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A heavy tactical barrier sealing the outer canyon approaches of the fort. Throwing the structural winches lifts the barricade to secure the perimeter or open a path for charging reinforcements.",
},

["Celestial Gate"] = {
    type = "Security Gate",
    icon = "VoidwatchRift.png",
    zones = { "The Celestial Nexus" },
    zoneIds = { 181 },
    note = "A brilliant cosmic barrier standing at the threshold of the ultimate dimensional arena. Pushing through this shimmering boundary transports you directly into final-tier boss confrontations.",
},

["Cermet Alcove"] = {
    type = "Quest Node",
    icon = "SealedWall.png",
    zones = { "Grand Palace of Hu'Xzoi" },
    zoneIds = { 34 },
    note = "A smooth crystalline recess carved directly into the ancient palace architecture. Examining this shimmering hollow uncovers dormant technology or unlocks quest progressions tied to the ancient Zilart bloodline.",
},

["Cermet Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chamber of Oracles", "Crawlers' Nest", "Dangruf Wadi", "Fei'Yin", "Garlaige Citadel", "Gusgen Mines", "King Ranperre's Tomb", "La'Loff Amphitheater", "Lower Delkfutt's Tower", "Maze of Shakhrami", "Ordelle's Caves", "Outer Horutoto Ruins", "Ranguemont Pass", "Sacrificial Chamber", "The Eldieme Necropolis", "The Shrine of Ru'Avitau", "Upper Delkfutt's Tower", "Ve'Lugannon Palace" },
    zoneIds = { 14, 102, 113, 121, 123, 125, 127, 158, 163, 166, 168, 177, 178, 180, 184, 190, 191, 193, 194, 195, 196, 197, 198, 200, 203, 204, 251 },
    note = "An enduring portal crafted from indestructible ancient composite materials. Activating its associated technological terminal or matching puzzle triggers parts the panels, granting passage into deep ruins.",
},

["Cermet Gate"] = {
    type = "Security Gate",
    icon = "portcullis.png",
    zones = { "Fei'Yin", "Hall of Transference" },
    zoneIds = { 14, 204 },
    note = "A monolithic security barrier separating ancient technological chambers. Overriding the localized control network shifts the smooth structure aside to clear your exploration path.",
},

["Cermet Grate"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Hall of The Gods" },
    zoneIds = { 251 },
    note = "A dense composite vent screen inset into the stone floors of the divine temple. Triggering the sanctuary mechanism releases the seal, providing access to long-forgotten testing chambers.",
},

["Cermet Headstone"] = {
    type = "Monument Landmark",
    icon = "CermetHeadstone.png",
    zones = { "La Theine Plateau", "Western Altepa Desert", "Yuhtunga Jungle", "Cape Teriggan", "The Sanctuary of Zi'Tah", "Behemoth's Dominion", "Cloister of Frost" },
    zoneIds = { 102, 113, 121, 123, 125, 127, 203 },
    note = "A polished, ancient stone pillar etched with mysterious archaic ruins. Offering specific elemental crystals or quest artifacts to this monument summons powerful entities or reveals hidden magical seals.",
},

["Chamnaet Spring"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Uleguerand Range" },
    zoneIds = { 5 },
    note = "A pure, freezing natural spring welling up through the jagged mountain glaciers. Dipping specialized quest vials into the crystal clear water captures unique regional elements needed for high-tier crafting or story trials.",
},

["Cheval River"] = {
    type = "Quest Node",
    icon = "River.png",
    zones = { "East Ronfaure" },
    zoneIds = { 101 },
    note = "The rushing waters of the Cheval River running through the Ronfaure woods. Peering down into the crystal-clear currents uncovers hidden items or advances localized questlines tied to the Kingdom of San d'Oria.",
},


["Chocobo Spoor"] = {
    type = "Quest Node",
    icon = "ChocoboTracks.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "Faint avian feathers and disrupted soil left behind in the Abyssean wasteland. Examining this trace evidence helps you track missing birds or maps out regional migratory routes.",
},


["Chocobo Tracks"] = {
    type = "Quest Node",
    icon = "ChocoboTracks.png",
    zones = { "La Theine Plateau" },
    zoneIds = { 102 },
    note = "Fresh, deep talon imprints pressed heavily into the grassy sod. Checking these prints allows you to hunt down rogue mounts or complete regional chocobo-breeding trial objectives.",
},


["Claw Mark"] = {
    type = "Quest Node",
    icon = "ChocoboTracks.png",
    zones = { "Ceizak Battlegrounds" },
    zoneIds = { 261 },
    note = "Deep, vicious gouges torn straight into the regional fauna. Investigating the destructive scoring reveals the size and nature of the localized apex predators threatening Adoulin's pioneers.",
},

["Clay"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Gusgen Mines" },
    zoneIds = { 196 },
    note = "A rich, malleable vein of natural mineral earth clinging to the damp mine walls. Gathering this raw material provides crucial ingredients for high-level pottery and crafting recipes.",
},

["Clone Ward"] = {
    type = "Quest Node",
    icon = "CloneWard.png",
    zones = { "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl" },
    zoneIds = { 215, 216, 217 },
    note = "An eerie, pulsing magical barrier fluctuating within the Abyssean voids. Disrupting this strange field unravels regional dimensional mysteries and advances your high-tier storyline progression.",
},

["Coastal Fishing Net"] = {
    type = "Harvest Point",
    icon = "Net.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "A massive maritime net cast directly into your personal beach waters. Hauling up the weighted ropes harvests a bounty of regional sea life, aquatic materials, and lost beachcombing treasure.",
},

["Collapsing Floor"] = {
    type = "Dungeon Switch",
    icon = "SewerLid.png",
    zones = { "Castle Oztroja [S]" },
    zoneIds = { 99 },
    note = "A loose, precarious stone trapdoor built into the past timeline fortress. Toggling the hidden trigger shifts the weight balance, dropping you straight down into the secure subterranean prisons below.",
},

["Colorful Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A brightly painted wooden gate standing along the fortress battlements. Satisfying the local military watch command slides the wooden bracing aside to grant entry through the garrison lines.",
},


["Compressed Snow"] = {
    type = "Quest Node",
    icon = "Snow.png",
    zones = { "Beaucedine Glacier [S]" },
    zoneIds = { 136 },
    note = "A dense, tightly packed drift blocking the freezing glacial valleys. Digging into the icy mass uncovers abandoned military supplies and unearths lost artifacts from the Crystal War era.",
},


["Congregation Site"] = {
    type = "Quest Node",
    icon = "CongregationSite.png",
    zones = { "Cirdas Caverns" },
    zoneIds = { 270 },
    note = "An clearing deep within the glowing subterranean caves. Surveying this bioluminescent hollow uncovers remnants of ancient beast gatherings or hidden clues regarding the underworld's ecosystem.",
},


["Contemplation Site"] = {
    type = "Quest Node",
    icon = "ContemplationSite.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A scenic, quiet overlook tucked away within the bustling city walls. Pausing here allows you to gather your thoughts, trigger historical lore cutscenes, or progress urban civic quests.",
},

["Corroded Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Pashhow Marshlands [S]" },
    zoneIds = { 90 },
    note = "A rusted, water-damaged iron barrier separating the swamp fortifications. Forcing open the weathered, squealing framework grants passage through the strategic wartime marsh choke points.",
},

["Corroded Gate"] = {
    type = "Security Gate",
    icon = "portcullis.png",
    zones = { "Beadeaux [S]", "Pashhow Marshlands [S]" },
    zoneIds = { 90, 92 },
    note = "A heavily rusted iron security partition separating the Quadav strongholds from the marshlands. Opening the creaking frame clears a tactical path across the active frontline zones.",
},

["Cracked Wall"] = {
    type = "Obstacle Node",
    icon = "SealedWall.png",
    zones = { "Inner Horutoto Ruins", "Outer Horutoto Ruins" },
    zoneIds = { 192, 194 },
    note = "A fragile masonry section cutting through the subterranean ruins. Striking the unstable brickwork shatters the barrier to reveal hidden chambers or bypass long labyrinth pathways.",
},

["Cradle of Rebirth"] = {
    type = "Quest Node",
    icon = "Cradle.png",
    zones = { "Attohwa Chasm" },
    zoneIds = { 7 },
    note = "An ancient, enigmatic hollow deeply connected to regional legend. Tracing the weathered contours of this site reveals lost history or updates active storyline quests.",
},

["Craggy Pillar"] = {
    type = "Quest Node",
    icon = "Pillar.png",
    zones = { "Castle Zvahl Keep" },
    zoneIds = { 162 },
    note = "A jagged, imposing stone spire rising within the dark fortress. Inspecting the corrupted crystalline veins running along the rock unlocks historical secrets or validates dark military campaigns.",
},

["Crawling Cave"] = {
    type = "Quest Node",
    icon = "Cave.png",
    zones = { "Kamihr Drifts" },
    zoneIds = { 267 },
    note = "A low, narrow structural fissure leading deep into the frozen mountain bedrock. Crawling into the dark opening advances your local exploration and maps uncharted sub-caverns.",
},

["Crematory Hatch"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Garlaige Citadel", "Garlaige Citadel [S]" },
    zoneIds = { 164, 200 },
    note = "A heavy furnace access portal set deep inside the subterranean military ruins. Unlocking the heat-warped seal gives you entry to hidden chambers or drop-down escape tunnels.",
},

["Crying Wind"] = {
    type = "Quest Node",
    icon = "Wind.png",
    zones = { "Abyssea - Grauberg" },
    zoneIds = { 254 },
    note = "A localized atmospheric draft whistling fiercely through the rocks. Listening closely to the howling currents guides you toward hidden anomalies or triggers spatial storyline events.",
},

["Crypt Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Batallia Downs [S]" },
    zoneIds = { 84 },
    note = "A rotting wooden portal barricading an underground tomb in the past timeline. Forcing the door open uncovers forgotten crypts and advances dark wartime operations.",
},

["Crystalline Field"] = {
    type = "Quest Node",
    icon = "CrystallineField.png",
    zones = { "Al'Taieu" },
    zoneIds = { 33 },
    note = "A flat, geometric expanse of alien crystalline matter. Stepping into the shimmering perimeter aligns your spiritual parameters and triggers cutscenes within the Celestial Capital.",
},

["Augural Conveyor"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Rala Waterways", "Cirdas Caverns", "Yorcia Weald", "Outer Ra'Kaznar" },
    zoneIds = { 258, 263, 270, 274 },
    note = "An ancient teleportation monument tying into the Adoulin waypoint network. Utilizing this humming device transports you directly into challenging Skirmish and Alluvion Skirmish battlefields.",
},

["Crystwater Spring"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Jugner Forest" },
    zoneIds = { 104 },
    note = "A bubbling natural spring pooling in the deep woods. Collecting the exceptionally pure water fulfills local alchemical trials or satisfies regional story conditions.",
},

["Babbling Brook"] = {
    type = "Quest Node",
    icon = "River.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "A clear stream cutting through the sacred land. Studying the pristine currents reveals hidden anomalies tied directly to your active Voracious Resurgence missions.",
},

["Barricade"] = {
    type = "Obstacle Node",
    icon = "BlockadedPath.png",
    zones = { "North Gustaberg [S]" },
    zoneIds = { 88 },
    note = "A crude military obstacle blocking the mountain valleys. Applying proper physical force or specific tools dismantles the debris, opening the wartime route for your squad.",
},

["Bestiary"] = {
    type = "Quest Node",
    icon = "Pawprint.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "A massive archived volume indexing the world's diverse fauna. Browsing through the text uncovers vital combat lore or unlocks scholarly library achievements.",
},

["Bibliomaniac's Lair"] = {
    type = "Quest Node",
    icon = "Cave.png",
    zones = { "Marjami Ravine" },
    zoneIds = { 266 },
    note = "A secluded cave shelter littered with weathered scrolls and historical texts. Searching the dusty hideout uncovers rare literature needed to fulfill Adoulin frontier research goals.",
},

["bigwinch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Davoi", "Fort Ghelsba" },
    zoneIds = { 141, 149 },
    note = "A heavy iron winch framework built into Orcish fortified encampments. Hauling on the mechanism handles heavy portcullis cables to drop tactical barricades or raise perimeter gates.",
},

	
["Clandestine Marking"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Ghelsba Outpost" },
    zoneIds = { 140 },
    note = "A hidden tracking checkpoint tucked safely inside the Orcish stronghold. Examining this subtle scratch mark allows you to safely recover a replacement infiltration costume kit if your disguise fails during local trials.",
},

["Delivery Crate"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A sturdy commercial cargo container placed within the Grand Palace grounds. Opening this box manages structural deliveries or retrieves specialized regional supplies for your active inventory.",
},

["Diaphanous Bitzer"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "An ancient, shimmering teleportation spire pulsing within the Sortie instance. Stepping onto this crystal platform warps you instantly between distinct sectors and dangerous wings of the subterranean labyrinth.",
},

["Diaphanous Bitzer #A"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary Area A warp hub. Presenting a specialized key item sheet lets you bypass sector walls to transport your entire alliance directly over to Area E.",
},

["Diaphanous Bitzer #B"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary Area B warp mechanism. Syncing your specialized key item records activates the crystalline array, pulling your battle group through the void into Area F.",
},

["Diaphanous Bitzer #C"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The localized Area C portal device. Feeding the necessary key item data into its magical core activates an emergency slipstream, shifting you straight into the hazards of Area G.",
},

["Diaphanous Bitzer #D"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The hidden Area D gateway. Matching your operational key items against its ancient ward unseals the terminal, warping your party directly into the deep chambers of Area H.",
},

["Diaphanous Device"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "An ancient, geometric relic humming silently inside the Sortie instance layers. Inspecting this monolithic structure lets you review active objectives or track total room clear goals.",
},

["Diaphanous Device #A"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Area A objective checkpoint. Interacting with this humming device evaluates your party's performance and validates active battle criteria completed inside the A wing.",
},

["Diaphanous Device #B"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Area B objective evaluation unit. Approaching this crystal apparatus updates your sub-zone records and tallies all combat conditions met inside the B wing.",
},

["Diaphanous Device #C"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Area C score validator. Gathering around this glowing focal point calculates your party's active milestones and registers unique currency rewards for your achievements in the C wing.",
},

["Diaphanous Device #D"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final Area D tracking pillar. Standing before this ancient console finalize your active metrics and triggers successful sector clearances for the deep D wing parameters.",
},

["Diaphanous Gadget"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A high-tech mechanical device built into the stone corridors of the Sortie instance. Manipulating the strange interfaces shifts localized gates or unlocks hidden doorways across the map.",
},

["Diaphanous Gadget #?"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A highly volatile mechanical device built into the stone corridors of the Sortie instance. Overriding its internal arrays processes variable layout parameters and triggers structural sector variations.",
},

["Diaphanous Gadget #A"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary mechanical interface for Sector A. Triggering its tech terminal satisfies regional conditions to open hidden stone pathways or manifest rare local armor lockboxes.",
},

["Diaphanous Gadget #B"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Sector B interaction device. Overriding this console fulfills localized trial goals, dropping heavy corridor partitions or revealing hidden prize coffers.",
},

["Diaphanous Gadget #C"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The regional controls for Sector C. Activating the ancient node updates your instance parameters to forge new pathways or spawn valuable augment material chests.",
},

["Diaphanous Gadget #D"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The structural security switch for Sector D. Manipulating its geometric layout alters regional walls and validates completion criteria for the upper-tier corridors.",
},

["Diaphanous Gadget #E"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Lower Tier Sector E automated interface. Overriding these deep subterranean circuits unlocks restrictive deep-level blast gates and manifests high-end boss reward boxes.",
},

["Diaphanous Gadget #F"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Lower Tier Sector F command mechanism. Interfacing with this ancient system unseals deep security partitions and handles objectives for advanced instance progression.",
},

["Diaphanous Gadget #G"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The Lower Tier Sector G processing unit. Activating its dark network opens secondary pathways and evaluates specific party configurations to drop rare artifact caches.",
},

["Diaphanous Gadget #H"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final Lower Tier Sector H apparatus. Activating this ultimate machinery unblocks restricted endgame routes and awards pristine structural upgrade items to your alliance.",
},


["Diary"] = {
    type = "Quest Node",
    icon = "ExplorerMoogle.png",
    zones = { "Southern San d'Oria" },
    zoneIds = { 230 },
    note = "A personal, leather-bound journal left open in a quiet residential bedroom. Reading through the dusty handwritten pages uncovers historical lore or advances localized kingdom storylines.",
},

["Dilapidated Gate"] = {
    type = "Security Gate",
    icon = "BlockadedPath.png",
    zones = { "Misareaux Coast", "Abyssea - Misareaux" },
    zoneIds = { 25, 216 },
    note = "A weathered, decaying wooden structure blocking the coastal valleys. Forcing open the splintered framework clears your route through regional boundary thresholds or tactical instances.",
},

["Displaced Block"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Castle Zvahl Keep [S]" },
    zoneIds = { 155 },
    note = "A misaligned stone brick inset within the dark stronghold walls. Pushing this heavy stone panel trips ancient locking gears to slide hidden doors aside or open alternative tactical routes.",
},

["Disturbed Dirt"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Zeruhn Mines" },
    zoneIds = { 172 },
    note = "A patch of loose, freshly shoveled soil along the dark mine tunnels. Digging into the debris reveals lost historical trinkets or advances localized miner questlines.",
},

["Disturbed Earth"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "East Sarutabaruta" },
    zoneIds = { 116 },
    note = "A small, mysterious mound of upturned soil. Unearthing this patch rewards you with hidden items or triggers event scenes when tracking regional Federation tasks.",
},

["Disused Well"] = {
    type = "Quest Node",
    icon = "Well.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "An ancient, dried-up stone water well located inside the Orcish village stronghold. Peer down into the dark cavity to unearth forgotten historical artifacts or advance specific San d'Orian temple quests.",
},

["Dock Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A heavy iron floor handle positioned right along the subterranean boat docks. Pulling this rusted lever powers up the automated transport vessel to ferry you across to the hidden sections of the mine.",
},

["Dormant Rampart"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Bhaflau Remnants" },
    zoneIds = { 75 },
    note = "An ancient, stone transport structure materializing deep inside the Imperial Remnants. Stepping into its field after clearing the surrounding automata allows your squad to advance up to the higher floors.",
},

["Dreamrose"] = {
    type = "Quest Node",
    icon = "Rose.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "A beautiful, rare desert flower blooming near Revelation Rock. Examining this exotic plant progresses your national missions and summons specific oasis guardians.",
},

["Drop Gate"] = {
    type = "Security Gate",
    icon = "portcullis.png",
    zones = { "Den of Rancor" },
    zoneIds = { 160 },
    note = "A massive, iron-reinforced vertical gate blocking off the sacrificial sacrificial halls. Overriding the nearby mechanisms lifts the heavy panel so you can dive into the deep temple caverns.",
},

["Dullness Crate"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Qu'Bia Arena" },
    zoneIds = { 206 },
    note = "A reward supply crate dropped onto the stone floor of the arena. Prying it open after a victorious battlefield confrontation distributes high-tier armor, materials, or weapon upgrade vouchers to your party.",
},

["Earthen Mound"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Ceizak Battlegrounds" },
    zoneIds = { 261 },
    note = "A patch of loose, freshly upturned soil hidden in the dense wilderness vegetation. Digging into the earth uncovers localized pioneer discoveries, validates geo-exploration goals, or advances regional side quests.",
},

["Earthly Concrescence"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "A swirling, unstable dimensional stone nexus pulsing near Ingress #1. Presenting a Mystical Canteen to this ethereal tear rips open the boundary, launching your alliance straight into the grueling Omen endgame instances.",
},

["Earthy Mound"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Abyssea - Grauberg" },
    zoneIds = { 254 },
    note = "A distinct patch of dirt contrasting against the harsh alternate-dimension crags. Sifting through this loose earth unravels complex spatial puzzles or marks critical progression markers for your Abyssean campaign.",
},

["East Plate"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A heavy stone floor switch operating the structural dungeon network. Stepping onto or activating this mechanism flips remote winches, dropping or raising the corresponding crypt gates across the catacombs.",
},

["Ebon Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Sauromugue Champaign [S]" },
    zoneIds = { 98 },
    note = "An ancient, shadow-drenched door standing silently along the past timeline valley pass. Forcing open this imposing barricade reveals deep historical archives and advances your national military campaign missions.",
},

["Ebon Panel"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Grand Palace of Hu'Xzoi", "The Garden of Ru'Hmet" },
    zoneIds = { 34, 35 },
    note = "A sleek, dark ancient interface inset into the crystalline palace walls. Overriding the foreign circuitry manipulates shifting room layouts or drops security forcefields inside the sky towers.",
},

["Ebony Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mamook", "Jade Sepulcher" },
    zoneIds = { 65, 67 },
    note = "A heavy, primitive wooden barrier protecting the inner sanctums of the beastman hierarchy. Bypassing its locks or presenting the correct structural token swings the frame open for deeper subterranean access.",
},

["Effigy of Sealing"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "An ancient stone statue standing as a solemn sentinel along the underworld corridors. Offering the proper regional relics to this monument unravels protective wards to unlock late-tier pioneer storylines.",
},

["Echo Disseminator"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "A strange tuning apparatus humming near the entrance of the fractured realm. Interfacing with this machine coordinates your active Voidstone inventory and prepares your squad for high-tier Voidwatch operations.",
},

["Egg Discovery Site"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "The Eldieme Necropolis [S]" },
    zoneIds = { 175 },
    note = "A hidden indentation tucked deep within the dark, damp catacombs. Searching this hollow uncovers rare biological remnants needed to fulfill past-timeline military requests or seasonal festive tasks.",
},

["Elevator"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Upper Delkfutt's Tower" },
    zoneIds = { 158 },
    note = "A massive moving platform built into the core of the ancient giant's tower. Stepping onto the deck initiates hydraulic lifts, transitioning your adventuring party between distinct vertical floors.",
},

["Elevator Button"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A polished mechanical wall apparatus situated inside the Grand Palace corridors. Activating this console signals the main palace lift, summoning transport to deliver you straight to the audience chambers.",
},

["Elevator Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Fort Ghelsba", "Palborough Mines", "Davoi" },
    zoneIds = { 141, 143, 149 },
    note = "A crude, weighted floor handle linked to regional lift structures. Throwing your weight against the iron bar engages industrial pulley networks, hauling up mechanical platforms across vertical stronghold tiers.",
},

["Emblazoned Reliquary"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun", "Reisenjima" },
    zoneIds = { 288, 289, 291 },
    note = "A majestic, floating celestial coffer hovering inside the Eschan domains. Accessing its shimmering interface coordinates Geas Fete arena entries, archives combat achievements, and distributes elite armor spoils.",
},

["Emerald Column"] = {
    type = "Quest Node",
    icon = "Pillar.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "A weathered column of moss-green stone enduring the harsh desert sun. Tracing the faded historical markings along the pillar validates geographical trials and updates expansion quest lines.",
},

["Engraved Tablet"] = {
    type = "Quest Node",
    icon = "Tablet.png",
    zones = { "Wajaom Woodlands", "Mount Zhayolm", "Caedarva Mire" },
    zoneIds = { 51, 61, 79 },
    note = "An ancient stone slab etched with complicated runic characters. Studying the crisp inscriptions coordinates critical translation stages and weapon trials required to forge ultimate Mythic armaments.",
},

["Enigmatic Sphere"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Spire of Holla", "Spire of Dem", "Spire of Mea", "Spire of Vahzl" },
    zoneIds = { 17, 19, 21, 23 },
    note = "A bizarre, floating metallic sphere vibrating with ancient temporal power. Interfacing with the cold surface bridges the physical world to transport your party into core Promathia expansion battlefields.",
},

["Ensorcelled Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ro'Maeve" },
    zoneIds = { 122 },
    note = "A massive sanctuary portal locked shut by glowing crimson runes. Disrupting the magical feedback unseals the stone frame, allowing you to pass into the heart of the abandoned temple.",
},


["Etched Rock"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima", "Reisenjima Sanctorium" },
    zoneIds = { 291, 293 },
    note = "A sacred, rune-carved stone monument nestled within the Reisenjima flora. Gathering your party at this focal point activates historical cutscenes and transports you into the challenging Reisenjima Sanctorium battlefields.",
},

["Eternal Ice"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Uleguerand Range" },
    zoneIds = { 5 },
    note = "A rare, pure frozen formation glistening on the high mountain shelves. Harvesting a shard of this permanent ice protects you from dangerous mountain drops, utilizing wind geysers to shoot you back up to safety.",
},

["Ethereal Ingress"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima Henge" },
    zoneIds = { 292 },
    note = "An ancient crystalline teleportation node floating in space. Channeling its magical currents manipulates regional travel networks to instantly warp your adventuring party across localized map sectors.",
},

["Ethereal Ingress #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The primary fast travel portal situated at the entrance plaza. This humming crystalline spire serves as your central sanctuary hub to access Curio Moogle trade networks, exchange currencies, or warp across the zone.",
},

["Ethereal Ingress #10"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "A high-tier crystalline waypoint floating in the deeper reaches of the realm. Tuning into its frequency links you to the regional fast travel matrix, granting an instant retreat or advance across active map sectors.",
},

["Ethereal Ingress #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The second crystalline fast travel nexus. Synchronizing your spiritual path with this floating rock bridges regional sector lines, instantly teleporting you through the shifting landscapes.",
},

["Ethereal Ingress #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The third localized crystalline travel monument. Activating the floating lattice matrix allows you to slip effortlessly through spatial barriers to arrive at targeted exploration points.",
},

["Ethereal Ingress #4"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The fourth fast travel energy point humming along the perimeter pathways. Stepping onto its base taps into the ancient world-warp grid to deliver your party directly into the middle sectors.",
},

["Ethereal Ingress #5"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The fifth specialized fast travel crystalline core. Interfacing with this ancient layout node provides an instant dimensional leap across the sacred hunting grounds.",
},

["Ethereal Ingress #6"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The sixth floating fast travel anchor. Harnessing the raw energy pulsing from its shell updates your coordinates and teleports you away from local dangers.",
},

["Ethereal Ingress #7"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The seventh high-tier crystalline travel waypoint. Activating this focal element lets you cross the zone instantly, connecting you directly to challenging perimeter territory.",
},

["Ethereal Ingress #8"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The eighth strategic fast travel node deep within the wilderness. Interfacing with the shining crystal structure expands your regional movement range across the active hunting rings.",
},

["Ethereal Ingress #9"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "The ninth specialized travel waypoint resting in the high-level hunting tiers. Linking your destination keys here lets you navigate through advanced areas without trekking through enemy territory.",
},

["Ethereal Spout"] = {
    type = "Quest Node",
    icon = "Spout.png",
    zones = { "Castle Oztroja [S]" },
    zoneIds = { 99 },
    note = "A localized, swirling cloud of mist hovering within the past timeline fortress corridors. Peering into the shifting vapor triggers vivid visions and advances specific wartime side campaigns.",
},

["Excavated Snow"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A distinct mound of shoveled snow revealing disturbed frozen ground underneath. Searching through the ice pile uncovers forgotten battlefield drops or updates active past-timeline campaigns.",
},

["Excavation Site"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Aydeewa Subterrane" },
    zoneIds = { 68 },
    note = "An active archaeological dig site hidden inside the glowing underground caverns. Sifting through the ancient dirt uncovers fragile relics, updates your excavation records, or fulfills exploration trials.",
},


["Fey Blossoms"] = {
    type = "Quest Node",
    icon = "FeyBlossoms.png",
    zones = { "Grauberg [S]" },
    zoneIds = { 89 },
    note = "A patch of glowing, mystical overworld blossoms growing in the past timeline. Studying the petals reveals deep spatial secrets and advances your military campaign questlines.",
},

["Fire Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Cloister of Flames" },
    zoneIds = { 207 },
    note = "A colossal, roaring elemental gemstone radiating intense heat. Tuning your spirit to this volcanic core opens the gateway to launch prime avatar battlefields and high-tier trials against Ifrit.",
},


["Firebloom Tree Root"] = {
    type = "Quest Node",
    icon = "Root.png",
    zones = { "Yuhtunga Jungle" },
    zoneIds = { 123 },
    note = "The massive, knotted roots of a prominent firebloom tree stretching deep into the soil. Searching around the base uncovers hidden jungle artifacts or triggers crucial regional storyline events.",
},


["Fish"] = {
    type = "Quest Node",
    icon = "Fish.png",
    zones = { "Abyssea - La Theine" },
    zoneIds = { 132 },
    note = "A shimmering aquatic creature caught in a localized temporal anomaly. Inspecting it unravels complex Abyssean spatial puzzles or triggers vital time extension rewards.",
},


["Fissure"] = {
    type = "Quest Node",
    icon = "Fissure.png",
    zones = { "Uleguerand Range" },
    zoneIds = { 5 },
    note = "A narrow, jagged mountain crevice slicing through the icy cliffside. Slipping into the crack lets you safely slide down hidden vertical layers or escape dangerous mountain drop-offs.",
},

["Flame of Fate"] = {
    type = "Quest Node",
    icon = "Flame.png",
    zones = { "Castle Zvahl Baileys" },
    zoneIds = { 161 },
    note = "A flickering mystical fire burning quietly in the dark outskirts of the fortress. Staring into the flame yields vital evidence needed to advance your active moogle expansion missions.",
},

["Flame Spout"] = {
    type = "Obstacle Node",
    icon = "Flame.png",
    zones = { "Ifrit's Cauldron" },
    zoneIds = { 205 },
    note = "An intermittent volcanic geyser erupting with searing lava. Timing your movements across the surrounding paths allows you to safely bypass the intense heat barriers blockading the corridors.",
},

["Flammen-Brenner"] = {
    type = "Quest Node",
    icon = "Flame.png",
    zones = { "Abdhaljs Isle-Purgonorgo" },
    zoneIds = { 44 },
    note = "The central structural team burner standing on the competitive island arena. Seizing flame elements from opponents lets you fuel and defend this pillar to secure victory during Brenner matches.",
},

["Flap"] = {
    type = "Quest Node",
    icon = "Door.png",
    zones = { "Castle Zvahl Baileys [S]" },
    zoneIds = { 138 },
    note = "A hidden structural hinge or crawlspace built into the beastman stronghold wall. Prying it open uncovers tactical reconnaissance files for the frontline military campaigns.",
},

["Flotsam"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "Washed-up maritime debris resting along your personal beach shoreline. Checking the sand diariamente lets you gather driftwood, lost cargo, and rare synthesis components to upgrade your island domain.",
},

["Fontis Xanira"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "The grand, rushing central fountain dominating the city plaza. Investigating the pristine waters reveals sacred clues needed to cure ancient curses or advance civic storyline paths.",
},

["Foreboding Presence"] = {
    type = "Quest Node",
    icon = "Wind.png",
    zones = { "Sih Gates" },
    zoneIds = { 268 },
    note = "A heavy, chilling atmospheric draft swirling through the subterranean caverns. Stepping into the freezing gloom updates your exploration records and advances late-tier pioneer missions.",
},

["Foreboding Vineprints"] = {
    type = "Quest Node",
    icon = "Root.png",
    zones = { "Foret de Hennetiel" },
    zoneIds = { 262 },
    note = "Crushed vegetation and deep structural tracking imprints left behind in the dense marsh forest. Following these tracks triggers vivid visions or validates vital wilderness survey tasks.",
},

["Fossil Rock"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Maze of Shakhrami" },
    zoneIds = { 198 },
    note = "A rich mineral outcropping filled with brittle fossilized remains. Striking the rocky surface with an equipped pickaxe extracts rare geological components or satisfies active gathering trials.",
},

["Fouled Sands"] = {
    type = "Quest Node",
    icon = "Sands.png",
    zones = { "Foret de Hennetiel" },
    zoneIds = { 262 },
    note = "A stretch of disturbed, slime-coated sand running along the coastal delta. Digging into the muck uncovers lost shoreline materials or advances localized research tasks.",
},


["Fragmented Nutshell"] = {
    type = "Quest Node",
    icon = "Nutshell.png",
    zones = { "Abyssea - Tahrongi" },
    zoneIds = { 45 },
    note = "The shattered remains of a gigantic tropical seed husk left in the wasteland. Sifting through the debris updates your Abyssean puzzle logs or secures valuable time extensions.",
},


["Fresh Snowfall"] = {
    type = "Quest Node",
    icon = "Snow.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A clean, powdery snowdrift piled high within the fractured alpine landscape. Searching through the drift uncovers frozen resources or progresses active regional side trials.",
},

["Fresh Snowmelt"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Batallia Downs [S]" },
    zoneIds = { 84 },
    note = "A localized pool of pure water melting from the glacial hillsides of the past timeline. Collecting this pristine runoff provides unique environmental ingredients needed for military campaign tasks.",
},


["Frigid Confluence"] = {
    type = "Quest Node",
    icon = "Snow.png",
    zones = { "Bostaunieux Oubliette" },
    zoneIds = { 167 },
    note = "A frosty atmospheric distortion freezing the stone floor of the hidden dungeon. Stepping into the cold mist aligns your spiritual parameters to unlock artifact attunements.",
},


["Grassy Mound"] = {
    type = "Quest Node",
    icon = "FeyBlossoms.png",
    zones = { "Abyssea - Misareaux" },
    zoneIds = { 216 },
    note = "A localized ground anomaly hidden in the Abyssean terrain. Sifting through the grass handles spatial puzzle metrics or checks dynamic quest parameters within the temporal zone.",
},


["Gravestone"] = {
    type = "Quest Node",
    icon = "Gravestone.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A weathered cemetery marker standing amidst the crypts. Brushing off the faded inscriptions triggers historical cutscenes or verifies critical quest item parameters.",
},

["Grimslight"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun", "Reisenjima" },
    zoneIds = { 288, 289, 291 },
    note = "An ethereal, pulsing fast-travel rift humming with extraplanar energy. Stepping into its radiance accesses the regional teleportation grid to shift you instantly between structural coordinates.",
},


["Groaning Pond"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A murky, bubbling swamp puddle resting deep inside the Orcish village. Peering into the thick water reveals dark cutscenes or validates hidden relics needed for San d'Orian temple trials.",
},

["Grounds Tome"] = {
    type = "Training Ledger",
    icon = "SurvivalGuide.png",
    zones = { "Lower Delkfutt's Tower", "King Ranperre's Tomb", "Dangruf Wadi", "Inner Horutoto Ruins", "Ordelle's Caves", "Outer Horutoto Ruins", "The Eldieme Necropolis", "Gusgen Mines", "Crawlers' Nest", "Garlaige Citadel", "Fei'Yin", "Quicksand Caves", "Ifrit's Cauldron", "Bostaunieux Oubliette", "Den of Rancor", "Ranguemont Pass", "Korroloka Tunnel", "Kuftal Tunnel", "Sea Serpent Grotto", "Ve'Lugannon Palace", "The Temple of Uggalepih", "Labyrinth of Onzozo", "The Boyahda Tree", "Gustav Tunnel", "The Shrine of Ru'Avitau", "Toraimarai Canal", "Upper Delkfutt's Tower", "Middle Delkfutt's Tower", "Zeruhn Mines" },
    zoneIds = { 153, 157, 158, 159, 160, 166, 167, 169, 172, 173, 174, 176, 177, 178, 184, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 204, 205, 208, 212, 213 },
    note = "A floating magical ledger hovering at key hunting outposts. Reading the text lets you enlist in Grounds of Valor combat regimes, secure experience multipliers, and claim defensive battle enhancements.",
},

["Handle"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Castle Oztroja [S]", "Castle Oztroja" },
    zoneIds = { 99, 151 },
    note = "A heavy wall handle inset near the stronghold security gates. Pulling this mechanism down either slides secret treasury walls aside or drops you down a hidden vertical pit trap.",
},


["Hanging Bridge"] = {
    type = "Obstacle Node",
    icon = "Bridge.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A fragile rope-and-plank span suspended over the seafaring staging grounds. Navigating its precarious structural framework triggers tactical path adjustments during specialized operations.",
},

["Hanging Cage"] = {
    type = "Quest Node",
    icon = "Cage.png",
    zones = { "Bastok Markets [S]", "Southern San d'Oria [S]" },
    zoneIds = { 87, 136 },
    note = "An iron cage suspended high above the public squares in the past timeline. Inspecting the rattling framework uncovers regional lore or coordinates festive holiday scripts.",
},

["Heroes' Gambit"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Xarcabard" },
    zoneIds = { 112 },
    note = "A localized dimensional tear manifest on the frozen tundra. Stepping into the spatial static tests your group's battle credentials and teleports your team straight into final Voracious Resurgence battlefields.",
},

["Hide Flap"] = {
    type = "barricaded Passage",
    icon = "Door.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A heavy leather hide curtain serving as a primitive Orcish doorway mechanism. Throwing back the flap operates concealed fortress pulleys to open barricaded security passages.",
},


["Hiding Place"] = {
    type = "Quest Node",
    icon = "SealedWall.png",
    zones = { "Cirdas Caverns" },
    zoneIds = { 270 },
    note = "A dark wall crevice or small floor depression tucked away within the glowing caverns. Reaching into the hollow triggers cryptic visions or validates active tracking objectives.",
},


["Frostbloom"] = {
    type = "Quest Node",
    icon = "FeyBlossoms.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A rare, crystal-encrusted frozen bloom growing within the alpine wastes. Gathering its petals updates your Abyssean exploration records or registers crucial time extension extensions.",
},

["Fruit"] = {
    type = "Quest Node",
    icon = "Fruit.png",
    zones = { "Mamook" },
    zoneIds = { 65 },
    note = "A basket of fresh wild vegetation left deep inside the beastman stronghold. Tampering with or offering items to the basket alters Mamool Ja tracking patterns or triggers localized instance challenges.",
},

["Hieroglyphics"] = {
    type = "Quest Node",
    icon = "Hieroglyphics.png",
    zones = { "Tavnazian Safehold", "Valkurm Dunes", "Buburimu Peninsula", "Qufim Island" },
    zoneIds = { 26, 103, 118, 126 },
    note = "Ancient geometric carvings etched directly into stone monuments. Examining the alien script uncovers historical archives or confirms dimensional travel clearances for Abyssea.",
},

["History"] = {
    type = "Quest Node",
    icon = "History.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "A massive archived volume resting on the quiet library shelves. Browsing through the dense script strings reveals deep historical data records concerning the lost Ulbuka continent.",
},

["Hoarfang"] = {
    type = "Quest Node",
    icon = "Column.png",
    zones = { "Beaucedine Glacier [S]" },
    zoneIds = { 136 },
    note = "A striking landmark ice column rising out of the past timeline tundra. Studying its frozen structure processes critical military campaign milestones to advance your active Bastok storyline.",
},

["Hollowed Pathway"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Kamihr Drifts", "Cirdas Caverns [U]" },
    zoneIds = { 271, 267 },
    note = "A dark, narrow fissure piercing through the frozen subterranean walls. Venturing into this opening launches the legendary battle instance against advanced regional adversaries.",
},

["Hostage Tent"] = {
    type = "Quest Node",
    icon = "Pioneer.png",
    zones = { "Marjami Ravine" },
    zoneIds = { 266 },
    note = "A fortified leather Velkk camp structure pitched deep in the ravine. Storming the outpost layout allows you to locate captured pioneers and progress frontier tactical expansion missions.",
},


["Ice Cage"] = {
    type = "Obstacle Node",
    icon = "BlockadedPath.png",
    zones = { "Leujaoam Sanctum" },
    zoneIds = { 69 },
    note = "A solid, freezing block of ice blocking the sanctum corridors. Striking or melting this frozen structural barrier shatters the frost, liberating the captured imperial soldiers trapped within.",
},

["Ice Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Cloister of Frost" },
    zoneIds = { 203 },
    note = "A colossal, flawless elemental gemstone radiating an absolute zero freeze. Syncing your essence with this ancient crystal lattice opens the gateway to launch prime avatar battlefields and high-tier trials against Shiva.",
},

["Illusory Image"] = {
    type = "Quest Node",
    icon = "Wind.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A shimmering, distorted atmospheric visual phenomenon warping the air of the chamber. Staring into the mirage pierces the spatial illusion, projecting ancient memories to advance your magical questlines.",
},

["Inconspicuous Barrel"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Western Adoulin", "Rala Waterways" },
    zoneIds = { 256, 258 },
    note = "A worn wooden storage barrel tucked away in town alleys or submerged within the sewer grids. Searching the container uncovers hidden contacts and secret patterns required to forge Rune Fencer Relic Armor.",
},

["Indescript Markings"] = {
    type = "Quest Node",
    icon = "Hieroglyphics.png",
    zones = { "Vunkerl Inlet [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Xarcabard" },
    zoneIds = { 83, 89, 90, 96, 97, 98, 112 },
    note = "Faint, weathered glyphs carved into remote rock faces across the past-timeline war zones. Studying these specific academic milestones tracks down missing military professors to claim specialized Scholar job Artifact Armor.",
},

["Infernal Transposer"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ra'Kaznar Inner Court" },
    zoneIds = { 276 },
    note = "An ancient technological console pulsing with volatile underworld energy. Overriding the machinery coordinates party parameters and breaches the gateway to launch your squad directly into Sinister Reign battle skirmishes.",
},

["Inlet of Whispers"] = {
    type = "Quest Node",
    icon = "Wind.png",
    zones = { "Dho Gates" },
    zoneIds = { 272 },
    note = "A secluded cave pathway worn smooth by shifting geological winds. Exploring the dark recess triggers a rush of echo fragments, updating active pioneer journals and advancing your continental storyline.",
},

["Institutions"] = {
    type = "Quest Node",
    icon = "SurvivalGuide.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "A massive archived tome resting on the library shelves. Browsing through the historical text strings reveals extensive civilization records and organizational structures regarding the untamed Ulbuka continent.",
},

["Jade Etui"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Buburimu Peninsula" },
    zoneIds = { 118 },
    note = "A small, ornate container hidden safely among the coastal rocks. Prying open the lock reveals unique regional relic fragments, validating active artifact gathering trials.",
},


["Jagged Cliff"] = {
    type = "Quest Node",
    icon = "Column.png",
    zones = { "Abyssea - La Theine" },
    zoneIds = { 132 },
    note = "A stark, unnatural rock face scarred by extraplanar static. Investigating the fractured cliffside helps you resolve Abyssean spatial puzzles or updates your active time extension parameters.",
},

["Jail Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Beadeaux" },
    zoneIds = { 147 },
    note = "A reinforced iron-barred barrier locking off the underground Quadav cells. Procuring a subterranean prison key releases the latch, allowing you to free captives or venture into deeper vault layers.",
},

["Jar"] = {
    type = "Quest Node",
    icon = "Jar.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A dusty clay pot left forgotten amidst the Orcish settlement. Sifting through the pottery contents uncovers hidden military cargo or validates specialized infiltration item checks.",
},


["Jazaraat's Headstone"] = {
    type = "Quest Node",
    icon = "Monument.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "A solemn stone burial monument rising above the damp marshlands. Offering an ancient weapon shell to this monument initiates dark spiritual attunements required to unlock legendary armaments.",
},

["Journey's End"] = {
    type = "Quest Node",
    icon = "CermetHeadstone.png",
    zones = { "Quicksand Caves" },
    zoneIds = { 208 },
    note = "An ancient stone structural waypoint resting deep inside the shifting desert ruins. Resting at this terminal updates your exploration parameters and handles localized seasonal holiday milestones.",
},


["Knightwell"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "West Ronfaure" },
    zoneIds = { 100 },
    note = "A historic stone water well enduring in the Ronfaure valleys. Peer into the deep masonry shaft to advance San d'Orian temple quests, fulfill active Trial of the Magians conditions, or exchange regional artifacts.",
},


["Knotty Oak"] = {
    type = "Quest Node",
    icon = "ColonizationReiveTargetObject.png",
    zones = { "La Theine Plateau" },
    zoneIds = { 102 },
    note = "An ancient, twisted oak tree trunk taking deep root along the grassy canyon plateaus. Searching the gnarled bark uncovers hidden regional materials or triggers critical storyline visions.",
},

["KS-01 Martello"] = {
    type = "Tactical Pump",
    icon = "Dialogue.png",
    zones = { "Abyssea - Konschtat" },
    zoneIds = { 15 },
    note = "A massive mechanical water purification apparatus stabilizing the localized environment. Feeding pure water vials into its engine replenishes your squad's vital temporal resistance meters deep inside the Abyssean void.",
},

["Lacuna Whorl"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Everbloom Hollow", "Ghoyu's Reverie", "Ruhotz Silvermines" },
    zoneIds = { 86, 93, 129 },
    note = "A shimmering, swirling vortex of spatial energy warping the cave atmosphere. Stepping directly into the rift acts as your structural escape portal or shifts your squad between dynamic layers of the Moblin Maze Mongers layouts.",
},

["Ladder of Liberty"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A sturdy structural escape ladder manifest inside the cell blocks of Moblin Maze Mongers. Scaling the rungs allows captured adventurers to successfully break free from isolated prison segments to regroup with their team.",
},

["Lantern"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Den of Rancor" },
    zoneIds = { 160 },
    note = "An ornate, unlit ritual pillar apparatus waiting deep inside the temple ruins. Offering a Paintbrush of Souls or lighting the wick unleashes sacred elemental currents, shifting heavy stone wall layouts across the caverns.",
},


["Large Animal Track"] = {
    type = "Quest Node",
    icon = "Pawprint.png",
    zones = { "Woh Gates" },
    zoneIds = { 273 },
    note = "A fresh, massive indentation pressed heavily into the subterranean floor mud. Investigating the scoring tracks down dangerous underground fauna and updates active pioneer hunting side quests.",
},

["Large Keyhole"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Sacrarium" },
    zoneIds = { 28 },
    note = "A massive lock mechanism sealing the heavy maze partitions. Coordinate with an allied party to turn complementary keys simultaneously within this apparatus to drop the structural walls blockading the dungeon chambers.",
},

["Large Stone Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Toraimarai Canal" },
    zoneIds = { 169 },
    note = "A monolithic slab of ancient masonry barring the flooded subterranean aqueducts. Overriding the nearby locking mechanism slides the heavy panel away to grant exploration passage.",
},

["Large Switch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A polished mechanical lever built into the laboratory walls. Throwing the heavy toggle handles manufacturing subroutines and advances high-tier Republic mission campaigns.",
},


["Leafy Patch"] = {
    type = "Quest Node",
    icon = "LeafyPatch.png",
    zones = { "Vunkerl Inlet [S]" },
    zoneIds = { 83 },
    note = "A small patch of thick shrubbery growing over hidden drops along the past-timeline riverbanks. Searching the overgrowth uncovers military supplies or clears regional side quest steps.",
},


["Legion Libretto"] = {
    type = "Quest Node",
    icon = "ConquestOverseer.png",
    zones = { "Maquette Abdhaljs-Legion A", "Maquette Abdhaljs-Legion B" },
    zoneIds = { 183, 287 },
    note = "An ornate podium ledger standing inside the battle antechamber. Interfacing with the script allows alliance leaders to override background acoustic fields and select custom battle themes for upcoming matches.",
},

["Legion Tome"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Rolanberry Fields", "Maquette Abdhaljs-Legion A", "Maquette Abdhaljs-Legion B" },
    zoneIds = { 110, 183, 287 },
    note = "An ancient text register resting on a dark stone pedestal. Trading your regional battle slips against its weathered pages verifies your group's metrics and teleports your entire alliance into the Legion arena.",
},

["Leviathan's Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A heavy architectural barrier partition sealing the deepest subterranean tombs. Solving the corresponding lever puzzles lifts the solid wall to grant deep exploration access.",
},


["Liber Daemonium"] = {
    type = "Quest Node",
    icon = "History.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "A massive archived volume resting securely on the library shelves. Browsing the ancient demonology records uncovers rare historical lore regarding fiends of the dark under-realms.",
},


["Library book"] = {
    type = "Quest Node",
    icon = "History.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A dusty academic tome filed away inside the magical laboratories. Pulling the text from the shelf uncovers rare research records to validate active Federation side quests.",
},

["Lightning Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Cloister of Storms" },
    zoneIds = { 202 },
    note = "A colossal, crackling elemental gemstone radiating fierce tracking electricity. Tuning your spiritual matrix to this ancient core breaches the gateway to launch prime avatar battlefields and high-tier trials against Ramuh.",
},

["Liseran Door: Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kamihr Drifts", "Woh Gates" },
    zoneIds = { 267, 273 },
    note = "An ancient structural gateway carving a threshold into the mountain drifts. Confronting this massive barrier unlatches the pathway to safely plunge your adventuring party into the depths of Outer Ra'Kaznar.",
},

["Liseran Door: Exit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "The heavy internal exit gateway anchoring the underworld fortress. Interfacing with this ancient layout mechanism departs the subterranean court layers and teleports you safely back to the overworld surface.",
},

["Living Cairn"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Rala Waterways [U]", "Yorcia Weald [U]", "Cirdas Caverns [U]" },
    zoneIds = { 259, 264, 271 },
    note = "A humming crystal pillar that materializes upon completing primary instance objectives. Tapping into its raw structural energy teleports your entire group directly into the next progressive floor tier of your active Alluvion Skirmish.",
},

["Locked Gate #A"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A heavy, reinforced barricade door separating the fractured corridors of the underworld. Overriding its restrictive parameters drops the partition to grant deeper progression inside the active Vagary instance.",
},

["Locked Gate #B"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary defensive wall blocking passage through the shifting trial rooms. Meeting localized area requirements releases the locking layout to let your squad advance into the next sector.",
},

["Locked Gate #C"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third heavy gate structure fortifying the dangerous instanced ruins. Clearing the surrounding baseline combat trials triggers the door mechanisms to swing the frame aside.",
},

["Locked Gate #D"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final structural locking boundary sealing the inner courtyard chambers. Overcoming the elite sector guardians triggers the winches, opening the path to face late-tier boss threats.",
},

["Lonely Evergreen"] = {
    type = "Quest Node",
    icon = "Tree.png",
    zones = { "Beaucedine Glacier" },
    zoneIds = { 111 },
    note = "A solitary, frost-laden pine tree weathering the brutal glacial winds. Searching the frozen roots uncovers buried regional relics or launches specialized artifact hunting side quests.",
},


["Loose Sand"] = {
    type = "Quest Node",
    icon = "Sands.png",
    zones = { "Attohwa Chasm" },
    zoneIds = { 7 },
    note = "An unstable, shifting desert slope piled against the jagged mountain cliffsides. Scrambling up through this loose terrain provides a vital path to navigate vertical map layers and complete wilderness surveys.",
},

["Lost Article"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ceizak Battlegrounds", "Yahse Hunting Grounds", "Foret de Hennetiel", "Cirdas Caverns", "Morimar Basalt Fields", "Marjami Ravine", "Kamihr Drifts", "Yorcia Weald", "Sih Gates", "Moh Gates", "Dho Gates", "Woh Gates" },
    zoneIds = { 260, 261, 262, 263, 265, 266, 270, 274, 267, 268, 269, 273 },
    note = "A discarded, mud-caked storage pack abandoned amidst the wilderness overgrowth. Recovering this missing cargo secures vital tracking metrics to fulfill your active Couriers' Coalition assignments.",
},

["Luck Rune"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Lufaise Meadows", "Batallia Downs", "Pashhow Marshlands", "Beaucedine Glacier", "Xarcabard", "Tahrongi Canyon", "Qufim Island" },
    zoneIds = { 24, 105, 109, 111, 112, 117, 126 },
    note = "An ancient runic seal etched directly into the dimensional boundaries. Activating this mystic distortion aligns your spatial metrics, drawing forth high-tier Voidwatch campaign campaign operations.",
},

["LuckRune"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Yuhtunga Jungle" },
    zoneIds = { 123 },
    note = "A regional variant of the ancient runic seal pulsing within the jungle undergrowth. Unlocking this spatial rift triggers powerful extraplanar rifts to test your party's combat limits.",
},


["Luminant"] = {
    type = "Quest Node",
    icon = "Flame.png",
    zones = { "Attohwa Chasm" },
    zoneIds = { 7 },
    note = "A swirling, supernatural wisp of brilliant light dancing at the pinnacle of Parradamo Tor. Reaching into the core captures elemental essences or unseals formidable regional adversaries.",
},

["Luminous Convergence"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "The Garden of Ru'Hmet" },
    zoneIds = { 35 },
    note = "A brilliant ancient machine humming in the center of the celestial sky palace layers. Interfacing with this technological console launches your group directly into critical Promathia storyline battlefields.",
},


["Lycopodium"] = {
    type = "Quest Node",
    icon = "HarvestPoint.png",
    zones = { "Batallia Downs [S]", "North Gustaberg [S]", "Batallia Downs", "North Gustaberg", "Garlaige Citadel [S]", "Garlaige Citadel" },
    zoneIds = { 84, 88, 105, 106, 164, 200 },
    note = "A friendly, stationary mandragora plant root embedded in the soil. Offering a fresh flower to this native flora manipulates past-timeline energy currents to bypass blocked regional thresholds.",
},


["Lycopodium Rootprint"] = {
    type = "Quest Node",
    icon = "HarvestPoint.png",
    zones = { "Abyssea - Tahrongi" },
    zoneIds = { 45 },
    note = "A faint vegetative tracking mark embedded into the dry wasteland ground. Studying this plant imprint coordinates localized spatial puzzles and claims crucial Abyssean time extension rewards.",
},

["Magic Gate of Horutoto"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A massive, sealed stone portal standing deep in the ruins. Opening this legendary structural barrier requires a coordinated group of distinct mages simultaneously activating the surrounding pressure plates.",
},


["Magicite"] = {
    type = "Quest Node",
    icon = "Pedestal.png",
    zones = { "Altar Room", "Monastic Cavern", "Qulun Dome", "Ru'Lude Gardens" },
    zoneIds = { 148, 150, 152, 243 },
    note = "Ancient, intensely humming crystalline fragments embedded within sacred altars. Interfacing with these stones completes vital country milestone records and extracts the raw energy required to advance your high-tier rank missions.",
},


["Magma Vein"] = {
    type = "Quest Node",
    icon = "Flame.png",
    zones = { "Moh Gates" },
    zoneIds = { 269 },
    note = "A searing, exposed lava outcropping fracturing the subterranean stone. Studying the molten flows maps out dynamic volcanic paths and updates active pioneer exploration logs.",
},

["Mahogany Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mamook", "Sacrificial Chamber", "Inner Horutoto Ruins" },
    zoneIds = { 65, 163, 192 },
    note = "A heavy, reinforced wooden partition barring deep structural labyrinth corridors. Presenting the matching regional keys releases the heavy iron latch so you can explore further ahead.",
},

["Main Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Tavnazian Safehold" },
    zoneIds = { 26 },
    note = "The massive iron-banded fortification gate protecting the safehold. Passing through this towering defensive archway leaves the underground shelter behind to transition you directly into the Lufaise Meadows.",
},


["Mandragora Warden ???"] = {
    type = "Quest Node",
    icon = "Root.png",
    zones = { "The Boyahda Tree" },
    zoneIds = { 153 },
    note = "A mysterious overworld rift site hidden amidst the giant tree roots. Offering rare battlefield trophies or checking your tracking parameters draws forth formidable localized adversaries.",
},

["Marble Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Toraimarai Canal", "Windurst Waters", "Heavens Tower" },
    zoneIds = { 94, 169, 238, 242 },
    note = "An elegant, polished stone barrier sealing executive chambers and canal networks. Verifying your current national mission clearance commands the ornate framework to part.",
},

["mateki"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Al Zahbi" },
    zoneIds = { 48 },
    note = "The sacred Astral Candescence relic anchored inside the hall. Guarding this priceless defensive mechanism from aggressive beastman invading forces keeps your city protections active.",
},

["Matter Diffusion Module"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "An ancient technological capsule manifesting at the end of grueling trials. Opening this repository distributes vital time extensions, battlefield experience, and high-end ancient currency items to your squad.",
},

["Maze Mongers Shopfront"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "The central structural counter mechanism situated inside the Chocobo Stables. Registering your custom vouchers at this station opens up customized layout parameters and teleports your party into Moblin Maze Mongers instances.",
},

["Medium Switch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A weighted lever apparatus set directly into the laboratory framing. Toggling the handle shifts manufacturing circuits to advance high-ranking Republic storyline events.",
},


["Memorian"] = {
    type = "Quest Node",
    icon = "Automaton.png",
    zones = { "Aht Urhgan Whitegate", "Chateau d'Oraguille", "Palborough Mines", "Rabao", "Windurst Walls", "Windurst Waters" },
    zoneIds = { 50, 143, 233, 238, 239, 247 },
    note = "A strange, magically animated doll standing as a hidden sentinel across various cities. Examining this eerie automaton tracks mysterious energy reactions to advance late-tier missions.",
},

["Memory Flux"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Promyvion - Dem", "Promyvion - Holla", "Promyvion - Mea", "Promyvion - Vahzl" },
    zoneIds = { 16, 18, 20, 22 },
    note = "A pulsing crystalline distortion manifesting inside the terrifying void of the Emptiness. Gazing into its depths tracks your spiritual records and launches arduous battlefield encounters.",
},


["Metallic Hodgepodge"] = {
    type = "Quest Node",
    icon = "Automaton.png",
    zones = { "Jugner Forest" },
    zoneIds = { 104 },
    note = "A pile of discarded metallic fragments and mineral scrap decaying in the forest woods. Searching the junk updates specialized crafting recipes or uncovers clues for regional side tasks.",
},

["Metalworks Entrance"] = {
    type = "Security Gate",
    icon = "Bastok Markets [S]",
    zoneIds = { 87 },
    note = "The heavy fortified archway sealing off the industrial sector in the past timeline. Passing through the massive frame moves you securely inside the fortified Metalworks district.",
},

["Mineral Vein"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "A rich subterranean rock outcropping exposed along your personal island cavern. Striking the ore vein with an equipped pickaxe extracts precious metals, raw gems, and crafting resources to bolster your island ranking.",
},

["Mineral Vein #3"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The tertiary geological outcropping in your private island cavern. Harvesting its mineral layers yields standard regional ore deposits, rare synthesis metals, and island cultivation experience.",
},

["Mineral Vein #4"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The quaternary geological rock face along the cavern walls. Utilizing a standard pickaxe on this stone harvests advanced industrial materials, elemental geodes, and specialized expansion items.",
},


["Mirror Pond"] = {
    type = "Quest Node",
    icon = "Pond.png",
    zones = { "Beaucedine Glacier" },
    zoneIds = { 111 },
    note = "The frozen, glassy surface of a pristine glacial pond. Clearing away the snow reveals crystal visions, triggering historical storyline memories or validating rare artifact gathering goals.",
},


["Mischief Marker"] = {
    type = "Quest Node",
    icon = "QuestNode.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A subtle, secretive carving etched directly into the city stone. Inspecting the mark unlocks hidden street-pioneer questlines or evaluates specialized holiday event tasks.",
},

["Mnemonic Pool"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ceizak Battlegrounds", "Yorcia Weald", "Kamihr Drifts", "Cirdas Caverns" },
    zoneIds = { 261, 263, 267, 270 },
    note = "A swirling dimensional vortex humming with ancient temporal frequencies. Interfacing with this energy pool checks your group alignment parameters to launch your alliance directly into Sinister Reign and Skirmish instances.",
},


["Moblin Idol"] = {
    type = "Quest Node",
    icon = "QuestNode.png",
    zones = { "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 93, 129 },
    note = "A bizarre, primitive structural totem pole constructed deep within the silver mines. Examining this tribal construct registers your current maze vouchers and unleashes challenging waves of maze monsters.",
},


["Mog-Tablet"] = {
    type = "Quest Node",
    icon = "QuestNode.png",
    zones = { "West Ronfaure", "East Ronfaure", "La Theine Plateau", "Valkurm Dunes", "Jugner Forest", "Batallia Downs", "Beaucedine Glacier", "North Gustaberg", "South Gustaberg", "Konschtat Highlands", "Rolanberry Fields", "Beaucedine Glacier", "Xarcabard", "Cape Teriggan", "Valley of Sorrows", "West Sarutabaruta", "East Sarutabaruta", "Tahrongi Canyon", "Buburimu Peninsula", "Meriphataud Mountains", "Sauromugue Champaign", "The Sanctuary of Zi'Tah", "Ro'Maeve", "Yuhtunga Jungle", "Yhoator Jungle", "Western Altepa Desert", "Eastern Altepa Desert", "Qufim Island", "Behemoth's Dominion" },
    zoneIds = { 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128 },
    note = "A small, glowing tablet shard hidden across random corners of the world. Scouring the land to locate and recover all eleven missing stone relics unleashes world-wide exploration blessings for all adventurers.",
},

["Monolith"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Shrine of Ru'Avitau", "Ve'Lugannon Palace" },
    zoneIds = { 177, 178 },
    note = "An ancient technological console standing as a pedestal in the sky palaces. Operating this device alters the polarity of colored security lasers, shifting yellow and blue light beam matrix barriers to unblock palace hallways.",
},

["Moon Spiral"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Full Moon Fountain" },
    zoneIds = { 170 },
    note = "A shimmering, moonlit distortion gateway warping the fountain waters. Presenting your battlefield credentials lets you breach the portal frame to launch prime avatar battlefields and high-tier trial instances against Fenrir.",
},

["Moongate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ro'Maeve" },
    zoneIds = { 122 },
    note = "A colossal, ancient stone security gate barring the sanctuary grounds. The towering framework commands itself to part strictly during specific in-game nighttime moon phases, or when forced open using a specialized passkey.",
},

["Mossy Stump"] = {
    type = "Quest Node",
    icon = "Stump.png",
    zones = { "Jugner Forest [S]" },
    zoneIds = { 82 },
    note = "A moss-covered tree stump decaying silently in the past-timeline woods. Searching the rotting hollow triggers vivid wartime cutscenes or registers vital military campaign materials.",
},


["Muggy Air"] = {
    type = "Quest Node",
    icon = "Wind.png",
    zones = { "The Boyahda Tree" },
    zoneIds = { 153 },
    note = "A heavy, humid atmospheric pocket hovering inside the giant hollow roots. Pausing inside this warm mist checks your active mission records to trigger hidden storyline events.",
},

["Mystic Retriever"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Empyreal Paradox", "Southern San d'Oria [S]", "Southern San d'Oria", "Port Bastok", "Windurst Woods", "Ru'Lude Gardens", "Port Jeuno", "Reisenjima", "Reisenjima Sanctorium" },
    zoneIds = { 36, 80, 230, 236, 241, 243, 246, 291, 293 },
    note = "A runic mechanism podium pulsating with dimensional energies. Interfacing with this console extracts rare pyroxene matrix fragments, adjusts your active high-tier campaign alignments, and purges obsolete operational records.",
},


["Mythralline Wellspring"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Wajaom Woodlands", "Bhaflau Thickets" },
    zoneIds = { 51, 52 },
    note = "A shimmering subaquatic water anomaly pooling quietly within the thicket brush. Investigating the source resolves exotic continental tracking puzzles and logs milestones for your mount's digging assignments.",
},

["Mythril Seam"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A rich metallic vein shimmering along the damp tunnel rock faces. Striking this outcrop with an equipped pickaxe extracts precious mythril ore, archives mining telemetry, and advances early Republic scenarios.",
},

["New-turned Earth"] = {
    type = "Quest Node",
    icon = "BackfilledPit.png",
    zones = { "Southern San d'Oria [S]", "Jugner Forest [S]", "La Vaule [S]" },
    zoneIds = { 136, 82, 85 },
    note = "A fresh patch of loose, shoveled soil breaking the wilderness sod in the past timeline. Excavating the mound uncovers hidden tactical items and fulfills dynamic gathering goals across the frontlines.",
},

["Nightflowers"] = {
    type = "Quest Node",
    icon = "FeyBlossoms.png",
    zones = { "Qufim Island" },
    zoneIds = { 126 },
    note = "A delicate cluster of midnight flora blooming under the starlight along the crags. Examining the rare petals satisfies precise regional gathering quotas and updates active wilderness research records.",
},

["Noetic Ascension"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ship Bound for Mhaura (Pirates)", "Rala Waterways [U]", "Yorcia Weald [U]", "Cirdas Caverns [U]", "Outer Ra'Kaznar [U]" },
    zoneIds = { 228, 259, 264, 271, 275 },
    note = "A glowing, ancient runic plate etched securely into the floor layouts. Stepping directly onto the active glyph opens an extraction slipstream, warping your entire squad safely out of the dangerous instance layers.",
},

["North Plate"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A heavy stone floor switch operating the catacomb layouts. Stepping onto or activating this mechanism slides remote gears to flip heavy security partitions across multiple subterranean floors.",
},

["Oak Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A fortified wooden barricade barring passage through the Orcish stronghold. Presenting a recognized crest or solving local security trials lifts the locking framework to let you pass.",
},

["Oaken Box"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "A heavy wooden storage chest left abandoned inside the military ruins. Prying open the reinforced lid uncovers lost military provisions or reveals gear records needed for artifact armor trials.",
},

["Oaken Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Norg" },
    zoneIds = { 252 },
    note = "A sturdy wooden door partitioning off the dark cavern corridors. Activating the threshold latch manages your movement through the pirate hub or initiates deep storyline scenarios.",
},

["Odin's Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A massive architectural barrier gate blockading the deepest chambers of the crypt ruins. Solving the master switch puzzles raises the monolithic slab to expand your subterranean exploration paths.",
},

["Oil Lamp"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "An iron wall lantern bracket fixed within the damp stone halls. Coordinating with an ally to pull corresponding lamps simultaneously trips secret weights, sliding back heavy masonry sections.",
},

["Old Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Grauberg [S]" },
    zoneIds = { 89 },
    note = "A decrepit, weathered wooden portal standing resilient against the valley elements. Forcing open the squealing frame advances past-timeline military operations and launches critical campaign cutscenes.",
},

["Old Toolbox"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A rusted, iron-banded container forgotten along the mining tracks. Searching through the junk retrieves critical key items and logs exploration metrics for active regional tasks.",
},

["Ominous Pillar"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Castle Zvahl Keep" },
    zoneIds = { 162 },
    note = "A dark architectural obelisk anchoring a violent dimensional tear inside the keep. Activating its volatile energy core shifts your spiritual metrics to coordinate high-tier campaign operations.",
},

["Ominous Postern"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ra'Kaznar Turris" },
    zoneIds = { 277 },
    note = "An ancient, shadow-wrapped doorway barrier leading into the abyssal void. Forcing entry through this portal boundary transports your alliance directly into high-tier master battlefield instances.",
},

["Operating Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Halvung" },
    zoneIds = { 62 },
    note = "A heavy iron handle installed along the volcanic outpost walls. Throwing your weight against the lever triggers heavy winches to lower massive iron drawbridges across the boiling lava channels.",
},

["Ore Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Castle Zvahl Keep [S]", "Castle Zvahl Keep", "Throne Room", "Throne Room [S]", "Heavens Tower" },
    zoneIds = { 155, 156, 162, 165, 242 },
    note = "A massive dark iron barricade blocking off the inner sanctums of power. Presenting the proper key item tokens or satisfying baseline clearance protocols commands the heavy iron framing to open.",
},

["Ornamental Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Jade Sepulcher" },
    zoneIds = { 67 },
    note = "An intricately decorated doorway barrier partitioning off the sacred tomb chambers. Overriding its localized locking parameters slides the heavy panel away to grant access to deep battlefield sectors.",
},

["Ornamented Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Sea Serpent Grotto" },
    zoneIds = { 176 },
    note = "A heavy wooden barrier carved with beastman markings to seal away hidden reef pathways. Presenting rare regional coins or specialized tools unlatches the door framework to let you pass.",
},

-- needs review
["Ornate Block"] = {
    type = "Quest Node",
    icon = "OrnateBlock.png",
    zones = { "Castle Zvahl Baileys [S]" },
    zoneIds = { 138 },
    note = "A distinct, hand-carved stone block inset into the fortress masonry in the past timeline. Studying the geometric patterns verifies your tactical military progress and advances campaign storylines.",
},

["Ornate Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Walk of Echoes", "Quicksand Caves" },
    zoneIds = { 182, 208 },
    note = "An elegant, stylized structural partition sealing off forgotten ruins. Bypassing the security mechanisms unseals the entryway, allowing your squad to advance into late-tier level layouts.",
},

["Ornate Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "A heavy iron-grilled security barrier fence crossing the subterranean sewer network. Coordinating with your team to turn paired remote valve wheels lifts the gate to clear the path ahead.",
},

["Otherworldly Vortex"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "A swirling, unstable cosmic rift tearing through the fabric of the fractured timeline. Stepping directly into the temporal void verifies your alliance credentials and teleports you into high-tier master battlefield instances.",
},

["Outcropping"] = {
    type = "Quest Node",
    icon = "Boulder.png",
    zones = { "Gustav Tunnel" },
    zoneIds = { 212 },
    note = "A rough geographic rock protrusion jutting out from the cave walls. Searching the cracks and fissures uncovers hidden mining provisions, artifact gear records, or rare quest items.",
},

["Outpost Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Pashhow Marshlands" },
    zoneIds = { 109 },
    note = "A sturdy wooden perimeter fence gate securing the regional marshland garrison. Slipping past the timber framing allows you to freely cross outposts or tracks local tactical defense conditions.",
},


["Overgrown Grave"] = {
    type = "Quest Node",
    icon = "Gravestone.png",
    zones = { "Cirdas Caverns" },
    zoneIds = { 270 },
    note = "A moss-covered burial monument eroding silently within the glowing subterranean caves. Clearing the roots and examining the stone triggers vivid pioneer memories to advance your side quests.",
},


["Overgrown Mushrooms"] = {
    type = "Quest Node",
    icon = "FeyBlossoms.png",
    zones = { "Jugner Forest [S]" },
    zoneIds = { 82 },
    note = "A cluster of massive, mutated fungal outcroppings thriving in the past-timeline woods. Harvesting the rare spores satisfies complex gathering quotas and unlocks specialized historical storylines.",
},

["Overturned Soil"] = {
    type = "Transit Portal",
    icon = "Sands.png",
    zones = { "West Ronfaure", "La Theine Plateau", "Jugner Forest", "Batallia Downs", "South Gustaberg", "Konschtat Highlands", "Pashhow Marshlands", "Rolanberry Fields", "East Sarutabaruta", "Tahrongi Canyon", "Meriphataud Mountains", "Sauromugue Champaign" },
    zoneIds = { 100, 102, 104, 105, 107, 108, 109, 110, 116, 117, 119, 120 },
    note = "A localized patch of disturbed earth masking a violent spatial distortion. Channeling your temporary key items into the ground unseals an extraplanar rift to initiate high-tier Voidwatch operations.",
},

["Pellucid Afflusion"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Yorcia Weald" },
    zoneIds = { 263 },
    note = "A strange, shimmering water phenomenon pooling deep within the twisted wilderness woods. Looking into the clear liquid projects ancient forest memories and updates active pioneer survey records.",
},

["Perikia"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "An iron-gated cavern entrance anchoring the regional reef boundary thresholds. Passing through this dark opening leaves the mire behind to launch your alliance straight into instanced Assault operations.",
},

["Personages"] = {
    type = "Quest Node",
    icon = "History.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "A massive archived biographical volume resting securely on the library shelves. Browsing the genealogical text strings uncovers comprehensive historical lore regarding ancient continental nobility.",
},

["Perversion's Refuge"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A dark, localized dimensional tear pulsing deep within the quadav mines. Gathering your squad before the distortion verifies your credentials to plunge directly into final Voracious Resurgence battlefields.",
},

["Phosphorous Ward"] = {
    type = "Quest Node",
    icon = "QuestNode.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A faint, glowing runic boundary seal placed along the fortress walls in the past timeline. Studying the protective matrix confirms active campaign tasks and updates structural survey parameters.",
},

["Pincerstone"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Ru'Aun Gardens" },
    zoneIds = { 130 },
    note = "An ancient runic seal etched directly into the floating sanctuary stone. Activating this mystic focal point aligns your spatial metrics to initiate high-tier Voidwatch campaign operations.",
},

["Pond Dredger"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "A specialized freshwater dredge mechanism stationed at the edge of your personal pond. Utilizing the ropes pulls up rare subaquatic synthesis components, tracks pond rankings, and uncovers sunken island materials.",
},

["Port Storage"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A heavy structural cargo crate stored near the warehouse docks. Searching through its contents balances local supply manifests and registers delivery parameters for your active Couriers' Coalition assignments.",
},

["Portcullis"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Hazhalm Testing Grounds", "Southern San d'Oria [S]" },
    zoneIds = { 78, 136 },
    note = "A heavy drop-down iron security gate blockading the stone corridors. Tripping the regional winches or meeting instance requirements raises the iron teeth to open the path ahead.",
},

["Postern"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Wajaom Woodlands", "Bhaflau Thickets" },
    zoneIds = { 51, 52 },
    note = "A small iron service door embedded directly into the towering capital city walls. Unlatching this door lets you bypass the main grand gates to slide quietly into the dangerous surrounding wilderness.",
},

["Pot Hatch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Mamook", "Mamool Ja Training Grounds" },
    zoneIds = { 65, 66 },
    note = "A hidden structural floor grate doubling as a beastman trapdoor. Activating the latch drops your entire adventuring party down into the lower subterranean corridors of the stronghold.",
},

["Priming Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A reinforced iron water control grid gate tracking the city waterways. Operating the valve mechanism updates country side quests and uncovers local environmental archives.",
},

["Primordial Convergence"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Morimar Basalt Fields" },
    zoneIds = { 265 },
    note = "A violent, swirling volcanic distortion tearing through the volcanic fields. Gathering your alliance before the crack verifies your group parameters to launch massive regional wildskeeper battles.",
},

["Qe'Iov Gate"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Stellar Fulcrum" },
    zoneIds = { 179 },
    note = "An ancient, glowing magical energy gateway sealing the celestial chamber. Channeling your party's battle credentials unseals the ward, launching you directly into monumental endgame confrontations.",
},

["Qiqirn Mine"] = {
    type = "Obstacle Node",
    icon = "MiningPoint.png",
    zones = { "Periqia", "Leujaoam Sanctum" },
    zoneIds = { 56, 69 },
    note = "A hidden, highly volatile proximity explosive device buried beneath the soil. Disarming the ticking tactical mechanism clears a safe corridor for your alliance during dynamic combat operations.",
},

["Qo'Tav Gate"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Stellar Fulcrum" },
    zoneIds = { 179 },
    note = "A secondary cosmic gateway channeling ancient stellar energy. Presenting the required expansion key items grants your battle group safe transport into elite battlefield encounters.",
},

["Qu'Hau Spring"] = {
    type = "Quest Node",
    icon = "Spring.png",
    zones = { "Ro'Maeve" },
    zoneIds = { 122 },
    note = "A shimmering, mystical water spring pooling in the center of the abandoned temple ruins. Immersing specific artifacts into the glowing liquid triggers vivid visions and infuses rare quest items.",
},

["Radiant Aureole"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Spire of Holla", "Spire of Dem", "Spire of Mea", "Spire of Vahzl", "Apollyon" },
    zoneIds = { 17, 19, 21, 23, 38 },
    note = "A brilliant architectural ring of white light hovering above the battlefield. Stepping directly into the halo transports your entire alliance out of the dangerous instance layers back to safety.",
},

["Rampart Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Batallia Downs [S]", "Rolanberry Fields [S]", "Sauromugue Champaign [S]" },
    zoneIds = { 84, 91, 98 },
    note = "A heavily reinforced barricade door integrated straight into the past-timeline frontline fortifications. Throwing the heavy locking bracing shifts army navigation rules across the battlefield zones.",
},

["Rampart Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Batallia Downs [S]", "Rolanberry Fields [S]", "Sauromugue Champaign [S]" },
    zoneIds = { 84, 91, 98 },
    note = "A massive fortified archway threshold standing along the past-timeline border walls. Forcing open the heavy framing allows your party to securely navigate between tactical frontline zones.",
},


["Raptor's Food"] = {
    type = "Quest Node",
    icon = "RaptorsFood.png",
    zones = { "Batallia Downs" },
    zoneIds = { 105 },
    note = "A skeletal pile and carcass left decaying out on the plains. Offering required hunting components to this grizzly landmark advances your wildlife taming trials or specialized beast tracking sequences.",
},

["Rear Trap"] = {
    type = "Quest Node",
    icon = "Trap.png",
    zones = { "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl" },
    zoneIds = { 215, 216, 217 },
    note = "A hidden mechanical node concealed within the tactical Abyssean lattice. Resetting its internal configurations registers localized parameters and clears security tracking counters for your squad.",
},

["Refiner Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A heavy iron floor handle connected to the industrial machinery of the Quadav mines. Throwing your weight against the lever powers up the automated burners to fulfill active Republic mission milestones.",
},

["Refiner Lid"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "The heavy mechanical top hatch of the quadav ore refining vat. Opening this lid lets you drop harvested raw materials straight into the furnace systems to process core story assignments.",
},

["Regal Pawprints"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Beaucedine Glacier [S]", "Walk of Echoes", "Provenance" },
    zoneIds = { 136, 182, 222 },
    note = "A faint, glowing mystical tracking imprint pulsing with dimensional static. Tracking these extraplanar prints aligns your campaign parameters to coordinate high-tier Voidwatch operations.",
},

["Register of Deeds"] = {
    type = "Quest Node",
    icon = "Deed.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun", "Reisenjima" },
    zoneIds = { 288, 289, 291 },
    note = "A weathered, ancient stone monument logging regional accomplishments. Accessing the slate reviews your personal Domain Invasion contributions and tallies dragon battlefield clear thresholds.",
},

["Republic Ensign I"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The primary military standard planted inside the instance map. Securing this national flag validates required combat goals and registers score metrics during team match trials.",
},

["Republic Ensign II"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The secondary national military banner anchoring team match zones. Evaluating its condition tracks victory matrices across the instance runs.",
},

["Republic Ensign III"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The third localized military standard standing within the trial rooms. Synchronizing with this focal point marks specific completion requirements for your squad.",
},

["Republic Ensign IV"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The fourth tactical military banner monitoring challenge sectors. Overriding its parameters unrolls progress metrics for your active team instance run.",
},

["Republic Ensign V"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The fifth national military standard evaluating group parameters. Interfacing with the standard secures victory criteria inside Moblin Maze Mongers trials.",
},

["Republic Ensign VI"] = {
    type = "Quest Node",
    icon = "BeastmenBanner.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The final military banner guarding the inner challenge arena. Finalizing this marker completes the ultimate team match conditions to claim regional rewards.",
},

["Rickety Ladder"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "A worn structural wooden ladder built into the instance chambers. Scaling its rungs bypasses blocked pathways to clear vertical layer layouts and solve maze collection tasks.",
},

-- needs review
["Ritual Site"] = {
    type = "Quest Node",
    icon = "RitualSite.png",
    zones = { "Monastic Cavern" },
    zoneIds = { 150 },
    note = "An eerie environmental arrangement hidden deep within the beastman cavern. Searching the sacred circle updates active storyline milestones and triggers historic expansion cutscenes.",
},

["River Mouth"] = {
    type = "Quest Node",
    icon = "River.png",
    zones = { "Foret de Hennetiel" },
    zoneIds = { 262 },
    note = "The rushing coastal delta currents merging into the sea. Investigating this unique water anomaly registers environmental survey parameters and updates active frontier pioneer journals.",
},

["Riverbed"] = {
    type = "Quest Node",
    icon = "River.png",
    zones = { "Grauberg [S]" },
    zoneIds = { 89 },
    note = "A shallow silt patch submerged along the valley streams in the past timeline. Searching through the running currents uncovers hidden wartime provisions or recovers rare resource components.",
},

["Rock Slab"] = {
    type = "Quest Node",
    icon = "Boulder.png",
    zones = { "Talacca Cove" },
    zoneIds = { 57 },
    note = "A heavy, flat sea stone resting along the shoreline cave floor. Inspecting the surface unlocks secrets of the Corsair job tracks and updates advanced tactical side quests.",
},

["Rockwell"] = {
    type = "Quest Node",
    icon = "Boulder.png",
    zones = { "Maze of Shakhrami" },
    zoneIds = { 198 },
    note = "A rugged stone layout landmark caked in dust. Searching the cracks verifies active exploration paths to check your localized logs or yield rare collection materials.",
},

["Rocky Outcrop"] = {
    type = "Quest Node",
    icon = "Boulder.png",
    zones = { "Dho Gates" },
    zoneIds = { 272 },
    note = "A sharp subterranean rock protrusion fracturing the cavern wall. Investigating the stone face aligns pioneer exploration details to trigger critical continental cutscenes.",
},

["Rocky Perch"] = {
    type = "Quest Node",
    icon = "Boulder.png",
    zones = { "Beaucedine Glacier [S]" },
    zoneIds = { 136 },
    note = "A frozen high cliff ledge overlooking the valley fields in the past timeline. Scaling the rock allows you to harvest specialized frontline campaign resources or recover lost side quest artifacts.",
},

-- needs review
["Royal Sepulcher"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A sacred stone tomb hidden securely inside the dark sewer architecture. Clearing away the moss uncovers historic royalty records to unlock advanced high-tier missions.",
},

["Ru'Avitau Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Aun Gardens" },
    zoneIds = { 130 },
    note = "A massive ancient archway floating serenely above the sky gardens. Satisfying structural defense coordinates commands the heavy security portal to open, letting you pass into the palace interior.",
},

-- needs review
["Rubious Crystal"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Al'Taieu" },
    zoneIds = { 33 },
    note = "A shimmering crimson gemstone column hovering over the alien sea. Tuning into its rhythmic vibration archives core expansion milestones or grants unique celestial key items.",
},

["Ruby Column"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "An ancient runic seal embedded deep into a desert geological formation. Channeling your temporary tracking keys forces open a violent extraplanar rift to engage in elite high-tier campaign operations.",
},

["Rune of Release"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ilrusi Atoll", "Periqia", "Lebros Cavern", "Mamool Ja Training Grounds", "Leujaoam Sanctum" },
    zoneIds = { 55, 56, 63, 66, 69 },
    note = "A shimmering, golden runic plate materializing upon victory. Interfacing with the glyph tallies your imperial achievements and warps your entire alliance securely back to the staging docks.",
},

["Rune of Transfer"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "A glowing blue floor teleportation ring pulsing inside the dark tower. Stepping into the light logs your climbing progress tokens to warp your squad directly onto active investigation layouts.",
},

["Rune of Transfer ???"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "An unstable layout rift shifting positions within the research facility layers. Examining the distortion processes randomized floor milestones and evaluates performance metrics to claim elite armor upgrades.",
},

-- needs review
["San d'Orian Pursuivant"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Jugner Forest", "Pashhow Marshlands", "Meriphataud Mountains" },
    zoneIds = { 104, 109, 119 },
    note = "A prominent military flag signpost monitoring the regional boundaries. Reading the military log updates local conquest statistics and provides critical regional tracking records for Kingdom forces.",
},

-- needs review
["Murky Pond"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - La Theine" },
    zoneIds = { 132 },
    note = "A stagnant pool of thick water mirroring the distorted dimension. Searching the banks updates active temporal puzzles and claims crucial Abyssean time extension extensions.",
},

["Mushroom Patch"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Aydeewa Subterrane" },
    zoneIds = { 68 },
    note = "A thick cluster of subterranean fungal growths thriving in the damp underground tunnels. Gathering the glowing caps collects rare crafting ingredients and completes wilderness exploration trials.",
},

-- needs review
["Musty Well"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A crude stone well mechanism integrated into the silver mine shafts. Inspecting the framework alters maze layout configurations and assists you in solving localized collection assignments during instance runs.",
},

["Salaheem's Sentinels"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "The heavy entrance framework anchoring the mercenary agency headquarters. Stepping past this corporate threshold delivers you straight into the main office to handle promotion reviews or claim currency wages.",
},

["Scalable Area"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Morimar Basalt Fields", "Marjami Ravine", "Moh Gates", "Cirdas Caverns", "Dho Gates", "Woh Gates" },
    zoneIds = { 265, 266, 268, 269, 270, 272, 273 },
    note = "A steep, fractured cliff face or unstable rock wall splitting the wilderness layers. Utilizing your pioneer climbing masteries lets you scale the rough rock tiers to bypass blocked paths.",
},

-- needs review
["Scrape Mark"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yughott Grotto" },
    zoneIds = { 142 },
    note = "A deep scratch trail scored straight into the damp cavern floor stones. Studying the trailing grooves validates active regional hunt records and advances specific San d'Orian side quests.",
},

-- needs review
["Scrawled Writing"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Oldton Movalpolos" },
    zoneIds = { 11 },
    note = "Faint, hurried graffiti etched into the industrial tunnel masonry. Decoding the primitive script updates exploration logs and checks localized progress parameters inside the Moblin city.",
},

-- needs review
["Screaming Pond"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A blood-red swamp feature pooling within the dark heart of the Orc settlement. Surveying the grim waters updates active tracking journals and fulfills crucial artifact gathering requirements.",
},

-- needs review
["Scuff Mark"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - Grauberg" },
    zoneIds = { 254 },
    note = "A faint scuff mark left on the floor within the distorted mirrored dimension. Investigating the trace element unlocks localized temporal puzzles and registers your active Abyssean side quest criteria.",
},

["Sarcophagus"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "An ancient, heavy stone tomb resting in the damp crypts. Operating the stone lid shifts structural catacomb weight mechanisms to open gated passages or trigger eerie historical records.",
},

["Savage Scars"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Wajaom Woodlands", "Caedarva Mire" },
    zoneIds = { 51, 79 },
    note = "A jagged tear split into the ground matter. Activating this violent spatial distortion checks your temporary alignment relics to draw forth formidable extraplanar entities for Voidwatch operations.",
},

-- needs review
["Sandy Overlook"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ceizak Battlegrounds" },
    zoneIds = { 261 },
    note = "A high scenic cliff ledge offering an open view across the wilderness vegetation. Pausing along this boundary registers your frontier pioneer evaluations and updates active storyline paths.",
},

["Sapphire Column"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "An ancient runic seal crystal outcropping exposed in the parched sands. Directing your cosmic keys into the crystal grid forces open an extraplanar rift to engage high-tier battle challenges.",
},

-- needs review
["Seat of Gramk-Droog"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Marjami Ravine" },
    zoneIds = { 266 },
    note = "The massive, imposing tribal throne anchoring the core of the Velkk stronghold. Interfacing with this sovereign structure evaluates your combat achievements and advances regional wildskeeper storylines.",
},

-- needs review
["Secluded Spot"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "West Sarutabaruta" },
    zoneIds = { 115 },
    note = "A quiet, unassuming space tucked away in the savanna terrain. Searching the spot uncovers long-lost historical clues to update your active country side quest journals.",
},

["Seed Afterglow"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Lower Delkfutt's Tower", "Middle Delkfutt's Tower", "Upper Delkfutt's Tower", "Fei'Yin" },
    zoneIds = { 184, 157, 158, 204 },
    note = "A shimmering, residual cloud of temporal light distorting the air inside the ancient towers. Looking into the afterglow reviews ancient historical archives and updates advanced quest parameters.",
},

["Seed Crystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Stellar Fulcrum" },
    zoneIds = { 179 },
    note = "A massive crystalline structure floating silently above the grand chamber floor. Aligning your group parameters with its crystalline grid opens the gateway to launch elite finale battlefields.",
},

-- needs review
["Seed Fragment"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Lower Delkfutt's Tower", "Middle Delkfutt's Tower", "Upper Delkfutt's Tower", "Stellar Fulcrum" },
    zoneIds = { 184, 157, 158, 179 },
    note = "An ancient mineral element etched with faint runic geometries. Tapping into its raw energy validates your key progress items to advance core expansion storyline arcs across the tower tiers.",
},

-- needs review
["Shadow of Darkness"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Altar Room", "Monastic Cavern", "Qulun Dome", "Ru'Lude Gardens" },
    zoneIds = { 148, 150, 152, 243 },
    note = "A chilling, targetable pocket of absolute darkness pooling within the chamber. Stepping into the void processes classic Rank 5 country storylines to extract powerful magical energy fragments.",
},

["Shadowy Pillar"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Castle Zvahl Baileys" },
    zoneIds = { 161 },
    note = "A dark architectural obelisk anchoring a violent dimensional tear inside the castle outskirts. Channeling your temporary tracking records into its core coordinates high-tier campaign operations.",
},

["Shady Sconce"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Sea Serpent Grotto" },
    zoneIds = { 176 },
    note = "A concealed metal candle bracket mounted to the reef corridor wall. Activating the torch mechanism slides hidden stone partitions aside or verifies advanced key permissions.",
},

["Shami's Crate"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Port Jeuno" },
    zoneIds = { 246 },
    note = "A small wooden storage container resting beside the veteran seal collector. Opening this box lets you manage your beastmen seal inventory and trade for advanced battlefield trophies.",
},

-- needs review
["Shard of Sunlight"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria", "Bastok Mines", "Windurst Walls" },
    zoneIds = { 230, 234, 239 },
    note = "A brilliant elemental orb manifest temporarily inside the city squares. Touching the glowing sphere processes specialized seasonal parameters or checks localized holiday event goals.",
},

["Shed"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A small wooden supply building situated at the edge of the jungle outpost. Unlatching the timber door uncovers regional exploration files or updates advanced chocobo training tasks.",
},

["Shellfish"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Yahse Hunting Grounds" },
    zoneIds = { 260 },
    note = "A group of marine mollusks exposed along the coastal shoreline rocks. Gathering from this marine spot collects rare synthesis ingredients and completes advanced frontier side tasks.",
},

["Shimmering Pondweed"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Pashhow Marshlands [S]" },
    zoneIds = { 90 },
    note = "A glowing aquatic plant thriving within the marshland waters of the past timeline. Harvesting the botanical shoots yields rare past-timeline crafting components and fulfills critical side milestones.",
},

["Shiva's Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A massive architectural tomb barrier dividing the subterranean catacombs. Solving remote switch puzzles releases the heavy locking mechanism to slide the slab aside and clear your path.",
},

["Sliding Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Beadeaux [S]", "Beadeaux" },
    zoneIds = { 92, 147 },
    note = "A heavy stone security barrier dividing the Quadav strongholds. Unlatching the heavy framework shifts localized area layouts to allow your squad passage into deeper corridors.",
},

["Slot"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Bhaflau Remnants", "Zhayolm Remnants", "Arrapago Remnants", "Silver Sea Remnants" },
    zoneIds = { 73, 74, 75, 76 },
    note = "An industrial deposit terminal built into the ancient layout blocks. Feeding armor duplicate plates into this mechanisms sparks local energy surges to summon powerful adversaries during your instance runs.",
},

["Sluice Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A massive iron water control gate tracking the city aqueduct network. Turning the heavy manual valve wheel drains flooding sewer sections to unlock restricted underground chambers.",
},

["Socket"] = {
    type = "Quest Node",
    icon = "Dialogue.png",
    zones = { "Bhaflau Remnants", "Zhayolm Remnants", "Arrapago Remnants", "Silver Sea Remnants" },
    zoneIds = { 73, 74, 75, 76 },
    note = "A technological structural wall receptacle hidden within the ancient facility. Injecting rare cell cells into its circuitry shatters gear restrictions or draws out hidden targets during endgame runs.",
},

["Somnial Threshold"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Dynamis - San d'Oria", "Dynamis - Bastok", "Dynamis - Windurst", "Dynamis - Jeuno", "Dynamis - Beaucedine", "Dynamis - Xarcabard", "Dynamis - Valkurm", "Dynamis - Buburimu", "Dynamis - Qufim", "Dynamis - Tavnazia" },
    zoneIds = { 39, 40, 41, 42, 134, 135, 185, 186, 187, 188 },
    note = "An eerie spatial fracture node hovering inside the distorted mirror city zones. Stepping through the dark void evaluates your group metrics to warp your alliance directly across battle arenas.",
},

["Song Runes"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Valkurm Dunes", "Buburimu Peninsula" },
    zoneIds = { 103, 118 },
    note = "An ancient runic seal hidden away within the shifting coastal sands. Directing your cosmic tracking keys into the glyph forces open an extraplanar rift to engage high-tier battle operations.",
},

["Soothing Strongbox"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Everbloom Hollow", "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 86, 93, 129 },
    note = "A reinforced treasure chest materializing after a successful maze clear. Cracking the lock distributes gear pieces and allocations of experience to your participating squad.",
},

["Soul Pyre"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Western Adoulin", "Eastern Adoulin", "Rala Waterways", "Ceizak Battlegrounds", "Yahse Hunting Grounds", "Foret de Hennetiel", "Yorcia Weald", "Morimar Basalt Fields", "Marjami Ravine", "Kamihr Drifts", "Sih Gates", "Moh Gates", "Dho Gates", "Cirdas Caverns", "Woh Gates", "Outer Ra'Kaznar", "Ra'Kaznar Inner Court", "Ra'Kaznar Turris" },
    zoneIds = { 256, 257, 258, 260, 261, 262, 263, 265, 266, 267, 268, 269, 270, 272, 273, 274, 276, 277 },
    note = "A glowing extraction column manifesting immediately post-combat across the continent. Accessing its light yields lost items, recovery tokens, or temporary regional combat enhancements.",
},

["Sprightly Footsteps"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A faint, pulsing tracking distortion embedded into the volcanic ground. Interfacing with the cosmic grid forces open a violent extraplanar tear to engage in elite high-tier campaign operations.",
},

-- needs review
["Sprout"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Meriphataud Mountains [S]" },
    zoneIds = { 97 },
    note = "A small, delicate sapling fighting for life in the past-timeline mountain wastes. Inspecting its growth uncovers tactical environmental archives and advances wartime side campaigns.",
},

-- needs review
["Stalagmite"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Korroloka Tunnel", "Ordelle's Caves" },
    zoneIds = { 173, 193 },
    note = "A jagged mineral protrusion rising out from the damp cave floors. Searching its rock crevices uncovers forgotten mining provisions, gear records, or rare artifact components.",
},

["Stonehoused Adit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "North Gustaberg [S]" },
    zoneIds = { 88 },
    note = "The heavy structural entryway of a stone quarry mine in the past timeline. Passing through the threshold advances military campaigns and triggers specialized side quest events.",
},

-- needs review
["Strewn Carrion"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "Biological animal remains weathering out within the freezing mountain crags of Abyssea. Sifting the bones maps out temporal anomalies and unlocks vital time extension extensions.",
},

-- needs review
["Stripped Carcass"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Vunkerl Inlet [S]" },
    zoneIds = { 83 },
    note = "The skeletal remains of a local beast decomposing out along the past-timeline riverbanks. Searching the cage uncovers forgotten military gear needed to resolve active tracking lines.",
},

["Sturdy Pyxis"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 215, 216, 217, 218, 253, 254 },
    note = "A locked, extraplanar prize repository dropping immediately post-combat. Breaking its mathematical numeric lock code rewards your squad with combat items and temporary battlefield buffs.",
},

-- needs review
["Succulent Cactus"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A hardy desert botanical element growing in the past-timeline wastes. Searching its thick layers harvests unique regional crafting materials and advances your active military side campaigns.",
},

-- needs review
["Sunken Hollow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A distinct natural ground depression forming a hidden wilderness landmark. Stepping into the recess uncovers lost wartime archives and triggers critical historical campaign cutscenes.",
},

-- needs review
["Symphonic Curator"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Al Zahbi", "Aht Urhgan Whitegate", "Southern San d'Oria [S]", "Bastok Markets [S]", "Windurst Waters [S]", "Southern San d'Oria", "Northern San d'Oria", "Port San d'Oria", "Bastok Mines", "Bastok Markets", "Port Bastok", "Windurst Waters", "Windurst Walls", "Port Windurst", "Windurst Woods", "Ru'Lude Gardens", "Upper Jeuno", "Lower Jeuno", "Port Jeuno", "Western Adoulin", "Eastern Adoulin" },
    zoneIds = { 48, 50, 80, 87, 94, 230, 231, 232, 234, 235, 236, 238, 239, 240, 241, 243, 244, 245, 246, 256, 257 },
    note = "An ornate structural orchestrion terminal situated near local residential entrances. Interfacing with this podium lets you purchase, configure, and alter the background acoustic music scores for the municipal region.",
},

-- needs review
["Synthesis Focuser II"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Port Jeuno" },
    zoneIds = { 246 },
    note = "A highly complex crafting resonance device huming near elite merchant stalls. Activating its internal terminal processes legendary Escutcheon trials to test crystal fusion properties and upgrade master shields.",
},

["Tallow Candle"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "An ancient wax lighting pillar fixed within the dark crypt walls. Igniting the wick trips weight weights to draw back massive stone partitions across the catacomb floor layers.",
},

["Tahrongi Cacti"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Abyssea - Tahrongi", "Tahrongi Canyon" },
    zoneIds = { 45, 117 },
    note = "A prominent desert succulent growing out from the parched earth. Gathering from its thorny layers extracts specialized synthesis components or satisfies active regional side objectives.",
},

["Teetering Ladder"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A loose structural wooden ladder built into the instance shafts. Scaling its rungs bypasses blocked pathways to clear vertical layer layouts and solve maze collection tasks within your active run.",
},

["Teleporter"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A mechanical elevator platform designed to transition between deep excavation layers. Activating its internal control network activates the lift chains to transport your group up and down the mine shafts.",
},

["Teleporter2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "The secondary mechanical elevator apparatus built into the industrial tunnels. Throwing the power lever commands the platform to shift your adventuring party between distinct vertical layout tiers.",
},

-- needs review
["Tenmado"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "An ancient glass skylight window set into the overhead stone masonry. Looking up through the frame uncovers faded environmental records and validates advanced country mission progress.",
},

-- needs review
["Time Bomb"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]" },
    zoneIds = { 81, 82, 83, 84, 90, 91, 95, 96, 97 },
    note = "A highly volatile explosive device deployed on active past-timeline frontlines. Manipulating the ticking interface lets you disarm the device to update tactical battlefield parameters.",
},

-- needs review
["Timeworn Altar"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Grauberg [S]" },
    zoneIds = { 89 },
    note = "An ancient, moss-covered stone ritual pedestal standing in the wilderness layers. Searching the top slab tracks advanced expansion milestones and verifies key quest components.",
},

["Topaz Column"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "An ancient runic seal geological crystal formation outcropping from the dunes. Directing your cosmic keys into the crystal grid forces open an extraplanar rift to initiate high-tier battle challenges.",
},

-- needs review
["Toppled Cresset"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Vunkerl Inlet [S]" },
    zoneIds = { 83 },
    note = "A fallen metal torch beacon resting rusted on the past-timeline battlefield. Searching the wreckage retrieves forgotten military resources and completes critical expansion milestones.",
},

["Toraimarai Canal"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A heavy iron gate threshold sealing off the underground waterways. Passing through this player-selectable overworld landmark archway slides you down securely into the Toraimarai Canal network.",
},

-- needs review
["Tiger Bones"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sauromugue Champaign" },
    zoneIds = { 120 },
    note = "The bleached, skeletal remains of an ancient predator decaying on the plains. Investigating the bones uncovers hidden tracking records and processes milestones for specialized side tasks.",
},

["Towering Portcullis"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "A colossal iron drop gate blocking the entrance to the fractured space-time loops. Satisfying character level milestones lifts the heavy grate framework to launch instanced endgame battles.",
},

["Transporter"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Toraimarai Canal", "Heavens Tower" },
    zoneIds = { 169, 242 },
    note = "A high-fidelity spatial transport gateway floating inside elite municipal hubs. Stepping onto the active node triggers a rapid energy lift, teleporting your party up and down structural map layers.",
},

-- needs review
["Tree Hollow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria [S]" },
    zoneIds = { 136 },
    note = "A weathered aperture inside an ancient tree trunk in the past timeline. Searching the hollow reveals hidden military tracking resources and advances active frontline campaigns.",
},

-- needs review
["Triggered Bomb"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Everbloom Hollow" },
    zoneIds = { 86 },
    note = "A live mechanical hazard unit ticking within the maze corridors. Disarming or interacting with this device alters localized instance parameters to complete challenge objectives during your run.",
},

["Twilight Aureola"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Everbloom Hollow", "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 86, 93, 129 },
    note = "A shimmering architectural ring of twilight energy hovering above the floor. Stepping directly into the halo serves as a structural escape portal to transport your group safely out of the instance layers.",
},

-- needs review
["Twinkle Tree"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "West Sarutabaruta" },
    zoneIds = { 115 },
    note = "A glowing overworld tree pulsating with a faint light. Studying its branches uncovers deep historical archives and advances active country side quest lines.",
},

["Twinkling Presence"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Dynamis - Xarcabard" },
    zoneIds = { 135 },
    note = "A shimmering atmospheric light distortion flickering against the frozen void. Tuning your cosmic tracking elements into the light forces open an extraplanar rift to initiate high-tier campaign operations.",
},

-- needs review
["Twinkling Tree"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ceizak Battlegrounds" },
    zoneIds = { 261 },
    note = "A distinct botanical milestone anomaly glowing along the frontier pathways. Examining its luminous leaves registers pioneer geographic evaluations and updates active side tasks.",
},

["Unstable Displacement"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Riverne - Site #A01", "Riverne - Site #B01" },
    zoneIds = { 29, 30 },
    note = "A shimmering spatial dimensional tear warping the floating island atmospheres. Offering a massive dragon scale to the anomaly temporarily bridges fractured sky paths to let you advance across landmass layers.",
},

["Vegetation"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Leujaoam Sanctum" },
    zoneIds = { 69 },
    note = "A thick outcropping of wild botanical brush growing in the sanctum trenches. Foraging through the greenery gathers unique materials and satisfies strict collection parameters during imperial operations.",
},

["Veil"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Ceizak Battlegrounds", "Foret de Hennetiel", "Yorcia Weald", "Morimar Basalt Fields", "Marjami Ravine", "Kamihr Drifts" },
    zoneIds = { 261, 262, 263, 265, 266, 267 },
    note = "A shimmering wall of concentrated elemental energy sealing off the wilderness boundaries. Stepping into the barrier evaluates your group's battle credentials to teleport your entire alliance directly into legendary arena battles.",
},

["Velkk Cache"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Marjami Ravine" },
    zoneIds = { 266 },
    note = "A primitive structural beastman storage pile hidden deep within the ravine. Ransacking the stash uncovers rare regional loot items and verifies active pioneer side quest goals.",
},

["Vending Box"] = {
    type = "Merchant",
    icon = "Merchant.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "An automated mechanical vendor station manifest inside the tower foyer. Trading your accumulated instance tokens at this box purchases emergency medicine supplies and temporary tactical battlefield support gear.",
},

["Vertical Transit Device"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Outer Ra'Kaznar", "Ra'Kaznar Inner Court", "Ra'Kaznar Turris" },
    zoneIds = { 274, 276, 277 },
    note = "An ancient magical lift platform humming with deep underworld power. Standing on the circular plate engages the lift array, transitioning your party up and down dangerous underground map layers.",
},

["Vexing Sniffles"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "An ethereal runic seal atmospheric distortion drifting over the damp marshlands. Directing your cosmic tracking keys into the rift forces open an extraplanar tear to initiate high-tier campaign operations.",
},

-- needs review
["Vicious Claw Marks"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ranguemont Pass" },
    zoneIds = { 166 },
    note = "Deep, violent scoring gouged directly into the mountain tunnel masonry. Studying the scratches uncovers trail archives and unearths lost artifacts to advance specialized side tasks.",
},

["Victory Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A towering iron imperial monument gate framework dominating the capital plaza. Studying its massive architectural engravings reveals historical archives concerning capital defenses and empire army victories.",
},

["Village Gateway"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "La Vaule [S]" },
    zoneIds = { 85 },
    note = "A heavily reinforced architectural fortification gate sealing the past-timeline orc fortress perimeter. Forcing your way through the barricade shifts your squad into deeper sectors of the enemy defense line.",
},

-- needs review
["Village Well"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A historic stone water well mechanism situated inside the orc encampment. Searching down the dark masonry shaft uncovers tracking clues and fulfills milestone requirements for San d'Orian quests.",
},

["Viscous Liquid"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Mamook", "Mamool Ja Training Grounds" },
    zoneIds = { 65, 66 },
    note = "A puddle of thick, gooey organic liquid pooling on the floor tiles. Examining the sticky substance trips hidden structural switches to slide open concealed doors or lower deep stronghold partitions.",
},

["Wall of Banishing"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A pulsing magical energy barrier sealing off the deepest recesses of the orc stronghold. Presenting a glowing crimson orb or similar protective artifact unseals the ward, letting you cross the defensive partition.",
},

["Wall of Dark Arts"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A pulsing magical barrier sealing the inner chambers of the Orc fortress. Presenting the proper dynamic passkeys neutralizes the defense runes to allow your squad passage.",
},

["Walnut Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Tavnazian Safehold" },
    zoneIds = { 26 },
    note = "A heavy wooden structural barrier partitioning the underground safehold. Turning the iron door handle coordinates your city navigation and uncovers localized story archives.",
},

["Warding Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A fortified defense portal safeguarding the frontline battlements in the past timeline. Throwing open this heavy wooden structure expands your movement range through the military perimeter.",
},

-- needs review
["Warhorse Hoofprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Wajaom Woodlands", "Bhaflau Thickets", "Mount Zhayolm", "Caedarva Mire" },
    zoneIds = { 51, 52, 61, 79 },
    note = "A deep stamp left in the mud by a charging military mount. Examining the unique tracking indentation retrieves evidence needed to advance your continental investigation journals.",
},

-- needs review
["Water in Space"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Full Moon Fountain", "Heavens Tower" },
    zoneIds = { 170, 242 },
    note = "A localized fluid distortion floating unnaturally in space. Touching the shimmering anomaly aligns your active scenario logs and initiates profound storyline visions.",
},

-- needs review
["Water of Whispers"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Dho Gates" },
    zoneIds = { 272 },
    note = "A peculiar water feature bubbling through the dark cave fissures. Studying the crystal currents logs pioneer geographic data and updates your frontier exploration records.",
},

["Water Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Cloister of Tides" },
    zoneIds = { 211 },
    note = "A colossal, flawless elemental gemstone radiating pure aquatic energy. Syncing your spirit with this crystalline heart opens the gateway to launch prime avatar battlefields and high-tier trials against Leviathan.",
},

-- needs review
["Waterfall Base"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "North Gustaberg" },
    zoneIds = { 106 },
    note = "The roaring spray where the mountain river drops into the valley floor. Searching the mist-drenched rocks uncovers hidden regional materials or satisfies active exploration goals.",
},

-- needs review
["Wailing Pond"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A muddy, stagnant pool tucked inside the defensive walls of the Orc settlement. Investigating the dark waters uncovers clues needed to fulfill specialized San d'Orian temple quests.",
},

-- needs review
["Waterfall Basin"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sea Serpent Grotto" },
    zoneIds = { 176 },
    note = "A deep underground stone basin gathering runoff from the cave ceilings. Searching the pool updates advanced tracking journals and progresses specific sea-pirate tasks out of Norg.",
},

["Watergrass"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Abyssea - Vunkerl" },
    zoneIds = { 217 },
    note = "A cluster of resilient swamp grass thriving within the Abyssean void reflection. Harvesting the aquatic shoots unravels regional spatial puzzles and claims crucial time extension rewards.",
},

-- needs review
["Waters of Oblivion"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ranguemont Pass" },
    zoneIds = { 166 },
    note = "A dark, chilling pool of water hidden inside the narrow mountain tunnels. Peer down into the glassy surface to recover lost artifact relics or update active explorer logs.",
},

-- needs review
["Waterways Overlook"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A strategic stone platform offering a broad view of the city aqueduct arches. Pausing at the railing registers your pioneer geographic metrics and advances advanced frontier side tasks.",
},

["Wavering Flux"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Yorcia Weald", "Cirdas Caverns" },
    zoneIds = { 263, 270 },
    note = "A localized spatial distortion shimmering silently along the path. Interfacing with the rift bridges regional boundaries to guide your movement during specialized pioneer assignments.",
},

-- needs review
["Weathered Boat"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Bibiki Bay" },
    zoneIds = { 4 },
    note = "A broken fishing skiff left rotting on the shoreline sands. Ransacking the splintered wood frames logs coastal exploration metrics and updates regional side quest lines.",
},

-- needs review
["Weathered Canvas"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Marjami Ravine" },
    zoneIds = { 266 },
    note = "A decayed, mud-caked canvas sheet draped over structural debris in the ravine. Pulling aside the cloth uncovers forgotten pioneer provisions or tracks active tracking goals.",
},

-- needs review
["Weathered Gravestone"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Batallia Downs" },
    zoneIds = { 105 },
    note = "A cracked stone burial monument enduring the harsh wind on the plains. Brushing the moss from the slate updates crucial nation mission metrics and triggers historical side cutscenes.",
},

["Web of Recollections"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Spire of Holla", "Spire of Dem", "Spire of Mea", "Spire of Vahzl" },
    zoneIds = { 17, 19, 21, 23 },
    note = "A massive structural web framework pulsing at the peak of the Promyvion towers. Forcing your way through the sticky threads updates your party metrics and transitions your alliance directly into the battle arena foyer.",
},

["Web of Regret"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Spire of Holla", "Spire of Dem", "Spire of Mea", "Spire of Vahzl" },
    zoneIds = { 17, 19, 21, 23 },
    note = "The twin structural thread web hanging in the tower heights. Interfacing with this alien mesh coordinates your expansion records to transport your squad safely into the arena threshold.",
},

["West Plate"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A heavy stone floor pressure plate linked to the catacomb security layout. Standing on the stone slabs engages remote mechanical pulley wires, sliding open massive stone partitions across multiple floors.",
},

-- needs review
["Wheel Rut"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A deep, frozen wagon carriage track imprint embedded heavily into the snow. Clearing away the ice reveals critical wartime evidence needed to advance your active past-timeline campaigns.",
},

["Wind Pillar"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Bearclaw Pinnacle" },
    zoneIds = { 6 },
    note = "A violent, howling snow gale vortex swirling furiously along the alpine cliffs. Stepping directly into the blizzard checks your battlefield group setups and teleports your team straight into instanced arena battlefields.",
},

["Wind Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Cloister of Gales" },
    zoneIds = { 201 },
    note = "A colossal, roaring emerald crystal formation radiating relentless wind current frequencies. Connecting your spiritual matrix to this ancient core breaches the gateway to launch prime avatar battlefields and high-tier trials against Garuda.",
},

-- needs review
["Windblown Loam"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yahse Hunting Grounds" },
    zoneIds = { 261 },
    note = "A localized patch of loose, wind-eroded soil revealing unusual sediment properties. Sifting the earth logs pioneer geographic data and uncovers paths for advanced wilderness side tasks.",
},

["Windurstian Bulwark"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "West Sarutabaruta [S]" },
    zoneIds = { 95 },
    note = "A heavy architectural fortification gateway standing tall along the past-timeline border defense lines. Passing past the timber bracing tracks your battle status and moves you through the nation's protective walls.",
},

-- needs review
["Windurstian Pursuivant"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Jugner Forest", "Pashhow Marshlands", "Meriphataud Mountains" },
    zoneIds = { 104, 109, 119 },
    note = "A prominent military flag signpost monitoring regional field control metrics. Examining the standard updates local conquest records and balances active survey details for Federation aligned tracking groups.",
},

["Wistaria Doors"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Giddeus" },
    zoneIds = { 145 },
    note = "A heavy, iron-strapped wooden barrier sealing off the elite inner quarters of the beastman outpost. Presenting a stolen stronghold passkey or coordinating actions with your squad commands the door framework to part.",
},

["Withered Petals"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A decay-stained ground anomaly masking a violent extraplanar rift. Directing your cosmic tracking relics into the distortion forces open a dimensional tear to engage in elite high-tier campaign operations.",
},

-- needs review
["Worn Book"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Temple of Uggalepih" },
    zoneIds = { 159 },
    note = "A decaying, mold-caked lore text resting on a forgotten library shelf deep in the temple. Flipping through the weathered pages uncovers cryptic civilization archives and updates historical side tasks.",
},

-- needs review
["Wreckage"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ilrusi Atoll" },
    zoneIds = { 55 },
    note = "The splintered remains of a shattered imperial ship rotting on the sand bars. Searching the structural debris tallies your exploration success metrics and updates active instanced operations logs.",
},

-- needs review
["Writhing Flame"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Oztroja [S]" },
    zoneIds = { 99 },
    note = "A brilliant ritual light burning within the dark corridors of the past-timeline fortress. Staring deep into the core validates your tactical military records and advances campaign timelines.",
},

["Yahse Wildflower"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Yahse Hunting Grounds" },
    zoneIds = { 261 },
    note = "A patch of vibrant tropical wildflowers blooming along the edge of the wilderness undergrowth. Gathering the rare petals harvests unique frontier crafting ingredients and registers your active quest parameters.",
},

["Zvahl Portcullis"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "The massive, iron-toothed drop-down security gate fortifying the grand entryway to Castle Zvahl in the past timeline. Tripping the heavy winches lifts the plate to pierce the Shadow Lord's primary defense lines.",
},

["Mineral Vein #2"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The secondary geological rock face exposed within your private island cavern. Striking this stone vein with an equipped pickaxe extracts metal ores, pristine gemstones, and regional raw materials.",
},

-- needs review
["Mithran Bivouac"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Meriphataud Mountains [S]" },
    zoneIds = { 97 },
    note = "A fortified structural campsite monument hidden along the past-timeline mountain ridges. Searching the supply lines uncovers critical frontline tokens or updates active Windurstian military campaigns.",
},

-- needs review
["Demonic Architrave"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "An ancient, shadow-wrapped stone framework towering over the lower underworld levels. Studying the architectural runes triggers powerful spatial visions to advance your active pioneer storyline.",
},

["Darkened Crevice"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Woh Gates" },
    zoneIds = { 273 },
    note = "An unassuming structural fissure cutting into the subterranean cave walls. Gathering your squad before this dark opening verifies your combat credentials to launch tactical expansion battlefields.",
},

-- needs review
["Daunting Emanation"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Morimar Basalt Fields" },
    zoneIds = { 265 },
    note = "A bizarre atmospheric anomaly pulsating with dense regional heat frequencies. Stepping near the energy distortion logs geographic exploration metrics and updates active pioneer side tasks.",
},

["Deathborne Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "A heavy, monolithic security partition sealing off the dark underworld corridors. Activating the surrounding ancient mechanisms slides the massive frame aside to grant deeper exploration access.",
},

["Decorative Bronze Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Halvung", "Navukgo Execution Chamber" },
    zoneIds = { 62, 64 },
    note = "An ornate metallic barrier forged by the subterranean beastman clans. Solving the local lock puzzles or presenting the correct garrison clearance keys opens the heavy path ahead.",
},

-- needs review
["Dark Fissure"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - La Theine" },
    zoneIds = { 132 },
    note = "A narrow ground fracture cracking the terrain within the distorted mirrored dimension. Investigating the rift resolves localized temporal puzzles and claims crucial spatial rewards.",
},

-- needs review
["Dark Miasma"] = {
    type = "Obstacle Node",
    icon = "Box.png",
    zones = { "Boneyard Gully", "Abyssea - Attohwa" },
    zoneIds = { 8, 215 },
    note = "A toxic cloud of dark environmental gas choking the ravine pathway. Utilizing a specialized filtering key item or regional counteragent neutralizes the vapor barrier to allow safe passage.",
},

["Dampsoil"] = {
    type = "Harvest Point",
    icon = "BackfilledPit.png",
    zones = { "Aydeewa Subterrane" },
    zoneIds = { 68 },
    note = "A fresh, mud-slick patch of earth hidden inside the bioluminescent underground caves. Digging into the fertile soil harvests rare regional crafting roots and completes active gathering trials.",
},

-- needs review
["Cryptexphere"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Monastic Cavern" },
    zoneIds = { 150 },
    note = "An ancient mechanical artifact sphere resting on a stone pedestal. Presenting specific beastman battle trophies to the device triggers a localized ambush to test your combat limits.",
},

["Crystal Receptor"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Pso'Xja" },
    zoneIds = { 9 },
    note = "An ancient crystalline terminal wall apparatus built into the uncapped tower. Channeling magical energy into the receptor materializes solid floor platforms below to let you navigate across the vertical gaps.",
},

-- needs review
["Brass Statue"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Oztroja" },
    zoneIds = { 151 },
    note = "An ancient, weathered idol standing as a sentinel deep inside the beastman stronghold. Studying its stone surfaces uncovers rotating security passwords required to unlock elite inner doors.",
},

["Brazier"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "The Eldieme Necropolis" },
    zoneIds = { 195 },
    note = "A massive stone torch column burning at a subterranean dead end. Stepping into the rising heat signals ancient transport weight mechanisms, teleporting your party up onto the isolated ridges of Batallia Downs.",
},

-- needs review
["Cushion"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "An elegant, silk-threaded seat rest placed in the imperial city quarters. Resting here allows you to review local mercantile archives, trigger urban cutscenes, or progress citizen side tasks.",
},

-- needs review
["Cutter"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A decayed maritime tool installation abandoned along the reef rocks. Foraging through the rusted frame uncovers forgotten coastal cargo and updates your active wilderness tracking logs.",
},

["Cyclopean Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Vunkerl Inlet [S]", "Abyssea - Vunkerl" },
    zoneIds = { 83, 217 },
    note = "A massive, weather-beaten structural gateway standing on the past-timeline battlefront. Forcing open the heavy wood-and-iron barrier unlocks deep layout corridors across the strategic valley paths.",
},

-- needs review
["Charred Firewood"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier [S]" },
    zoneIds = { 136 },
    note = "The soot-stained remains of an abandoned tactical campfire buried in the snowdrift. Searching the ash pile uncovers military dispatch remnants and updates your past-timeline campaign journal.",
},

-- needs review
["Chat Manual"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Bastok Mines", "Northern San d'Oria", "Windurst Walls" },
    zoneIds = { 231, 234, 239 },
    note = "A basic reference guidebook resting openly in city squares. Examining the pages details municipal communications history or fulfills early-tier tracking tasks for novice adventurers.",
},

["Avatar Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Pso'Xja" },
    zoneIds = { 9 },
    note = "A colossal ancient portal sealing the inner sanctums of the ruined towers. Overriding the crystalline security grids parts the monolithic barrier, allowing you to advance toward prime avatar testing chambers.",
},

-- needs review
["Aged Stump"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Leafallia" },
    zoneIds = { 281 },
    note = "A massive, moss-grown wood stump centering the quiet sanctuary hub. Studying the gnarled bark layers uncovers deep historical lore or validates your active expansion storyline trials.",
},

-- needs review
["Alluring Plant"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A strange bioluminescent floral growth thriving within the damp city sewer channels. Inspecting the glowing leaves triggers vivid pioneer memories or checks active wilderness research milestones.",
},

-- needs review
["Alpine Trail"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Kamihr Drifts" },
    zoneIds = { 267 },
    note = "A jagged geographic mountain track winding upward through the freezing glaciers. Studying the trail parameters logs pioneer mapping charts and updates your active wilderness survey records.",
},

-- needs review
["Parchment"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Temple of Uggalepih" },
    zoneIds = { 159 },
    note = "A fragile, ink-stained paper document forgotten on a dark sacrificial altar shelf. Deciphering the primitive script text strings reveals ritual history to advance specialized side tasks.",
},

["Hazy Rune"] = {
    type = "Transit Portal",
    icon = "VoidwatchRift.png",
    zones = { "Ranguemont Pass", "Inner Horutoto Ruins", "Outer Horutoto Ruins", "Ordelle's Caves", "King Ranperre's Tomb", "The Eldieme Necropolis", "Gusgen Mines", "Crawlers' Nest", "Maze of Shakhrami", "Garlaige Citadel", "Fei'Yin" },
    zoneIds = { 166, 192, 194, 193, 190, 195, 196, 163, 198, 200, 204 },
    note = "A shimmering, distorted runic seal etched directly into the dungeon walls. Directing your cosmic tracking keys into the glyph forces open an extraplanar rift to initiate Voidwatch operations.",
},

["Heavy Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "La Vaule [S]" },
    zoneIds = { 85 },
    note = "A thick wooden barrier sealing off the inner layouts of the orc fortress defenses. Presenting a stolen stronghold passkey or forcing the latch commands the frame to open.",
},

["Heavy Iron Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Garlaige Citadel [S]" },
    zoneIds = { 164 },
    note = "A reinforced metallic portal blockading the past-timeline underground fortress corridors. Tripping the surrounding weight plate triggers drops the frame aside to let your squad advance.",
},

["Heavy Iron Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bhaflau Thickets", "Arrapago Reef", "Mount Zhayolm", "Caedarva Mire", "Garlaige Citadel [S]" },
    zoneIds = { 52, 54, 61, 79, 164 },
    note = "A fortified metallic grate partitioning secure empire outposts and subterranean cells. Procuring a regional passkey or skeleton item unlatches the heavy frame so you can pass.",
},

["Heavy Sliding Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Beadeaux" },
    zoneIds = { 147 },
    note = "A monolithic stone security partition blockading the deep Quadav stronghold. Activating remote lever pulley systems commands the heavy masonry frame to slide open.",
},

["Heavy Stone Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "King Ranperre's Tomb" },
    zoneIds = { 190 },
    note = "A massive architectural slab of ancient tomb masonry barring deep burial vault corridors. Solving localized lever puzzles releases the latch to clear your exploration path.",
},

["Iron Bar Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Castle Zvahl Baileys", "Castle Zvahl Keep", "Heavens Tower" },
    zoneIds = { 138, 155, 161, 162, 242 },
    note = "A heavy iron-barred defensive partition blockading the inner dark fortresses. Presenting specialized key items or country mission clearance commands the framework to lift.",
},

["Iron Box"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Oldton Movalpolos" },
    zoneIds = { 11 },
    note = "A heavy, iron-banded storage trunk forgotten along the moblin mining tracks. Searching through the container retrieves critical key items and logs exploration metrics for active regional tasks.",
},

["Iron Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Maze of Shakhrami" },
    zoneIds = { 198 },
    note = "A heavy, rusted iron partition blocking off narrow mining corridors. Forcing the latch open slides the metal framework aside to give your party access to deep subterranean fossil paths.",
},

["Iron Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Arrapago Reef", "Misareaux Coast", "Periqia", "Phomiuna Aqueducts", "Sacrarium", "Sealion's Den", "Talacca Cove", "Beaucedine Glacier" },
    zoneIds = { 25, 27, 28, 32, 54, 56, 57, 111 },
    note = "A sturdy iron-barred defensive barrier blockading dungeon thresholds or reef paths. Solving localized lever puzzles or presenting specific key items lifts the grate to clear your exploration path.",
},

["Reinforced Gateway"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "La Vaule [S]" },
    zoneIds = { 85 },
    note = "A heavily armored archway threshold sealing the past-timeline Orc stronghold. Overriding its physical braces unlocks the frontlines to advance critical military campaign operations.",
},

["Reinforced Wooden Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Crawlers' Nest [S]" },
    zoneIds = { 171 },
    note = "A massive wooden barricade bound with metal straps inside the past-timeline tunnels. Operating the nearby mechanical triggers releases the latch to open up deeper investigation routes.",
},

["Reisen Crystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Reisenjima Sanctorium" },
    zoneIds = { 293 },
    note = "A colossal, glowing crystal focal point radiating immense spiritual energy inside the sanctuary. Directing your party parameters into its crystalline lattice launches elite late-tier expansion battlefields.",
},

-- needs review
["Relentless Storm"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A violent atmospheric phenomenon or rushing vortex echoing inside the dark aqueducts. Investigating the swirling currents uncovers critical pioneer tracking records or updates active city side tasks.",
},

["Reliquiarium Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Sacrarium" },
    zoneIds = { 28 },
    note = "An ornate, fortified sanctuary gate sealing away sacred reliquaries. Presenting rare cardinal key items unblocks the pathway corridors, allowing your squad to advance into late-tier level layouts.",
},

["Repair Trunk"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Abyssea - Attohwa", "Abyssea - Konschtat", "Abyssea - La Theine", "Abyssea - Misareaux", "Abyssea - Vunkerl" },
    zoneIds = { 15, 132, 215, 216, 217 },
    note = "A heavy tactical supply container manifest inside the Abyssean void. Breaking open the locking mechanics provides emergency provisioning items, armor components, or temporary battlefield buffs.",
},

-- needs review
["Wooden Cabinet"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Tavnazian Safehold" },
    zoneIds = { 26 },
    note = "A polished wooden furniture piece integrated into the safehold's residential quarters. Searching the drawers uncovers dusty historical archives or updates active expansion side quest journals.",
},

["Wooden Crates"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Garlaige Citadel [S]" },
    zoneIds = { 164 },
    note = "A stack of weathered wooden cargo containers abandoned inside the past-timeline fortress. Prying open the timber lids uncovers lost military provisions or hidden tracking relics.",
},

["Wooden Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Crawlers' Nest [S]", "Jugner Forest [S]", "Phomiuna Aqueducts", "Sacrarium", "Temple of Uggalepih" },
    zoneIds = { 27, 28, 82, 159, 171 },
    note = "A basic timber barrier partition sealing off fortress perimeters or ancient temple hallways. Forcing open the squealing wooden frame grants passage into deeper layout corridors.",
},

["Wooden Ladder"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "A sturdy structural ladder prop built into the subterranean sewer layouts. Scaling its rungs bypasses blocked pathways to clear vertical layer thresholds and solve maze collection tasks.",
},

-- needs review
["Wooden Shutter"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Northern San d'Oria" },
    zoneIds = { 231 },
    note = "A heavy timber window frame hinged to the municipal architecture. Interfacing with the latch uncovers neighborhood tracking clues or triggers localized background flavor cutscenes.",
},

["Iron Grille"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Castle Oztroja [S]" },
    zoneIds = { 99 },
    note = "A heavy iron-barred defensive partition blocking the past-timeline beastman stronghold tunnels. Tripping the remote lever puzzles lifts the frame to allow deeper exploration access.",
},

["Iron Portcullis"] = {
    type = "Security Gate",
    icon = "Portcullis.png",
    zones = { "Meriphataud Mountains [S]" },
    zoneIds = { 97 },
    note = "A heavy drop-down iron defensive barrier partitioning the mountain passes in the past timeline. Activating the remote winches raises the grid teeth to open a secure route across the frontlines.",
},

["Iron-framed Oak Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Gusgen Mines" },
    zoneIds = { 196 },
    note = "A reinforced wooden entryway bound in heavy metal framing to seal off deep mining shafts. Forcing the heavy latch open grants your party access into dangerous subterranean corridors.",
},

["Ironbound Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A thick, iron-reinforced wooden barrier blocking off wet coastal grottos. Finding and utilizing a specialized reef skeleton passkey releases the heavy lock to expand your exploration.",
},

["Ironbound Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate", "Beadeaux [S]" },
    zoneIds = { 50, 92 },
    note = "A reinforced structural gate guarding strategic city thresholds and beastman fortifications. Meeting localized clearance protocols swings the heavy frame aside to open the pathways.",
},

["Particle Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Grand Palace of Hu'Xzoi", "The Garden of Ru'Hmet" },
    zoneIds = { 34, 35 },
    note = "A high-fidelity forcefield barrier composed of condensed crystalline energy blocks inside the sky towers. Overriding its foreign circuitry shuts down the particle stream to allow safe passage.",
},

-- needs review
["Peculiar Bud"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Wajaom Woodlands" },
    zoneIds = { 51 },
    note = "An exotic, tightly wrapped botanical growth hidden in the dense woodland undergrowth. Examining its unique floral structure uncovers rare regional resources or updates active tracking lines.",
},

-- needs review
["Peculiar Fissure"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Palborough Mines" },
    zoneIds = { 143 },
    note = "A strange natural crack splitting the damp stone tunnels of the mine. Reaching down into the narrow crevice uncovers hidden mining cargo or satisfies active explorer logs.",
},

-- needs review
["Peculiar Glint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Zvahl Baileys [S]" },
    zoneIds = { 138 },
    note = "A mysterious, flashing light distortion shimmering against the past-timeline fortress stone. Investigating the glimmer uncovers hidden tactical military files to advance active campaign tasks.",
},

-- needs review
["Peculiar Plant"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "An unnatural, pulsing marshland botanical growth thriving in the damp fen muck. Studying its alien vegetation satisfies strict regional gathering quotas and unlocks advanced side quests.",
},

-- needs review
["Peculiar Rootprints"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "North Gustaberg [S]", "Rolanberry Fields [S]", "Meriphataud Mountains [S]" },
    zoneIds = { 88, 91, 97 },
    note = "Faint vegetative tracking marks pressed into the past-timeline battlefield dirt. Studying these unique botanical imprints coordinates localized exploration puzzles and advances wartime side campaigns.",
},

-- needs review
["Peculiar Seed"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A strange, oversized biological seed pod weathering the intense volcanic heat. Examining its shell reveals rare environmental components required to fulfill specialized Near East research goals.",
},

-- needs review
["Pedestal of Darkness"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A solemn stone podium etched with dark alignment runes inside the oracle chambers. Interfacing with its surface balances advanced storyline parameters or validates unique magicite attunement keys.",
},

-- needs review
["Pedestal of Earth"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "An ancient earthen-carved stone altar standing inside the oracle hall. Placing specific elemental offerings onto its surface handles ritual attunements or unlocks specialized magic trials.",
},

-- needs review
["Pedestal of Fire"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A heat-warped stone column radiating a subtle volcanic vibration inside the oracle sanctuary. Studying its charred inscriptions unlocks historic secrets or advances active country storylines.",
},

-- needs review
["Pedestal of Ice"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A frost-rimed stone altar chilling the air of the chamber. Checking its frozen geometries aligns your spiritual parameters to unlock artifact gear milestones or progress magical quests.",
},

-- needs review
["Pedestal of Light"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A polished stone pedestal catching celestial beams floating inside the oracle temple vaults. Resting your hands upon its surface updates advanced mission progress markers or triggers historic visions.",
},

-- needs review
["Pedestal of Lightning"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A crackling stone altar pulsing with a subtle storm frequency deep within the ruins. Interfacing with its runic matrix handles grueling recording subroutines and validates advanced weapon trials.",
},

-- needs review
["Pedestal of Water"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "A moisture-beaded stone column vibrating with fluid currents inside the oracle hall. Placing specific elemental offerings onto its surface handles ritual attunements or unlocks specialized magic trials.",
},

-- needs review
["Pedestal of Wind"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Chamber of Oracles" },
    zoneIds = { 168 },
    note = "An ancient stone altar channeled by whistling drafts inside the oracle sanctuary. Studying its worn engravings uncovers historic secrets, balancing your advanced storyline parameters.",
},

-- needs review
["Pephredo Hive"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Wajaom Woodlands" },
    zoneIds = { 51 },
    note = "A massive, pulsing insect comb clinging to the dense jungle trees. Foraging through its sticky structural layers satisfies strict regional gathering quotas and uncovers rare synthesis ingredients.",
},

-- needs review
["Perennial Snow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard" },
    zoneIds = { 112 },
    note = "A permanent, ice-crusted drift weathering the freezing mountain winds. Digging into the ancient mass uncovers abandoned military supplies and unearths lost artifacts from a bygone era.",
},

-- needs review
["Puddle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A stagnant pool of brackish marsh water collecting along the grotto floor stones. Studying the glassy ripples logs localized exploration metrics or updates active tracking journals.",
},

["Rune of Transfer #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "The primary blue floor teleportation circle pulsing inside the investigation tower. Stepping into the light reads your saved climbing progress tokens to warp your squad directly onto active investigation layouts.",
},

["Rune of Transfer #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "The secondary localized warp hub within the research layers. Synchronizing your spiritual path with its matrix bridges sector lines, instantly teleporting you through the shifting tower floors.",
},

["Rune of Transfer #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "The third floating floor lattice matrix. Activating its light allows you to slip effortlessly through spatial barriers to arrive at targeted investigation tiers.",
},

["Rune of Transfer #4"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "The fourth fast-travel energy point humming along the sector walkways. Tapping into its ancient world-warp grid delivers your adventuring party directly into the middle floors.",
},

["Rune of Transfer #5"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Nyzul Isle" },
    zoneIds = { 77 },
    note = "The fifth specialized travel waypoint resting in the advanced tower tiers. Linking your destination keys here lets you navigate through higher floor objectives with your alliance.",
},

["Runic Lamp"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Arrapago Remnants", "Bhaflau Remnants", "Nyzul Isle", "Silver Sea Remnants", "Zhayolm Remnants" },
    zoneIds = { 73, 74, 75, 76, 77 },
    note = "A magical lamp post operating the mechanical dungeon networks. Interfacing with the terminal shifts localized room layouts or toggles dynamic barrier conditions inside active instances.",
},

-- needs review
["Runic Overflow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Western Adoulin", "Foret de Hennetiel", "Marjami Ravine" },
    zoneIds = { 256, 262, 266 },
    note = "A pulsing magical leak escaping through cracks in the regional landmass. Studying the unstable runic energy updates active pioneer journals and advances advanced frontier side tasks.",
},

["Runic Seal"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bhaflau Thickets", "Arrapago Reef", "Mount Zhayolm", "Alzadaal Undersea Ruins", "Caedarva Mire" },
    zoneIds = { 52, 54, 61, 72, 79 },
    note = "A massive magical barrier gate blocking off secure empire vaults. Presenting recognized regional relics or satisfying clearance protocols commands the heavy runic seal to part.",
},

-- needs review
["Rusted Transmitter"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Cirdas Caverns [U]" },
    zoneIds = { 271 },
    note = "A decaying, mold-caked communication device abandoned inside the subterranean caves. Repairing its rusted circuits tracks your group's active instance milestones for frontier research goals.",
},

["Rusty Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Oldton Movalpolos" },
    zoneIds = { 11 },
    note = "A heavy, weighted iron floor handle installed along the industrial tunnels. Throwing your weight against the bar engages old pulley winches to alter layout pathways across the Moblin city.",
},

["Sandstone Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Quicksand Caves" },
    zoneIds = { 208 },
    note = "A massive masonry slab carving a threshold into the shifting desert ruins. Overriding its restrictive locking mechanism slides the heavy panel away to grant deep exploration access.",
},

-- needs review
["Sauce Barrel"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A seasoned wooden barrel tucked away in the warehouse docks. Searching the storage container uncovers hidden contacts and retrieves specialized regional culinary supplies.",
},

["Sealed Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "West Sarutabaruta [S]" },
    zoneIds = { 95 },
    note = "A reinforced wooden gateway blockading the past-timeline border fortifications. Satisfying military clearance protocols unseals the ward, letting you cross out into the frontline zones.",
},

-- needs review
["Seaprince's Tombstone"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "A solemn stone burial monument rising above the damp marshlands. Offering an ancient weapon shell to this monument initiates dark spiritual attunements required to unlock legendary armaments.",
},

["Secret Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Batallia Downs [S]" },
    zoneIds = { 84 },
    note = "A hidden, camouflaged structural passage carved straight into the past-timeline cliffsides. Unlatching the concealed framework grants your squad access into deep fortification layers.",
},

-- needs review
["Shredded Label"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 164, 171, 175 },
    note = "A torn, battle-worn piece of paper scrap fluttering in the past-timeline winds. Studying the fragmented military script updates your active frontline campaign logs and side trial milestones.",
},

-- needs review
["Shrouded Workroom"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "A dark, magic-shielded alcove hidden within the stone underworld layout blocks. Searching the dusty tables uncovers ancient technology fragments to advance your pioneer research goals.",
},

-- needs review
["Signpost"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - Tahrongi", "West Ronfaure", "East Ronfaure", "Valkurm Dunes", "Jugner Forest", "Konschtat Highlands", "Rolanberry Fields", "West Sarutabaruta", "East Sarutabaruta", "Tahrongi Canyon", "Buburimu Peninsula" },
    zoneIds = { 45, 100, 101, 103, 104, 108, 110, 115, 116, 117, 118 },
    note = "A weathered wooden marker standing along overworld road forks and Abyssean paths. Examining its faded geographical carvings coordinates your localized orientation and logs regional side tasks.",
},

-- needs review
["Signs of a Struggle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ceizak Battlegrounds" },
    zoneIds = { 261 },
    note = "Crushed wilderness vegetation and deep claw scoring marking a chaotic battlefield site. Investigating the disturbed soil uncovers pioneer clues and updates your active tracking journals.",
},

["Small Box"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Grauberg [S]" },
    zoneIds = { 89 },
    note = "A small, steel-banded storage container hidden in the past-timeline brush. Prying open its reinforced lid rewards your squad with lost military resources or unique regional item drops.",
},

["Small Keyhole"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Sacrarium" },
    zoneIds = { 28 },
    note = "A specialized locking lock built into the heavy maze partitions. Coordinate with an allied party to turn complementary sub-keys simultaneously to drop the structural maze walls.",
},

["Small Switch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A compact mechanical lever mounted to the laboratory wall circuits. Toggling the handle adjusts manufacturing parameters to advance active Republic rank mission milestones.",
},

["South Plate"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A heavy stone floor switch operating the catacomb layouts. Stepping onto or activating this mechanism slides remote gears to flip heavy security partitions across multiple floors.",
},

-- needs review
["Southeastern Pip"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier" },
    zoneIds = { 111 },
    note = "A distinct geometric stone node inset along the frozen cliff sides. Tracing the weathered markings validates advanced geographical trials and updates expansion quest lines.",
},

-- needs review
["Southwestern Pip"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier" },
    zoneIds = { 111 },
    note = "A twin geometric stone landmark enduring the harsh alpine weather. Examining its frozen surfaces uncovers forgotten trails or updates active artifact gathering paths.",
},

["Spatial Displacement"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Misareaux Coast", "Riverne - Site #A01", "Riverne - Site #B01", "Monarch Linn" },
    zoneIds = { 25, 29, 30, 31 },
    note = "A shimmering spatial distortion tearing through the floating sky tracks. Stepping directly into the rift bridges separate landmass layers to teleport your party into core expansion battlefields.",
},

-- needs review
["Speaking Tubes"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "The Colosseum" },
    zoneIds = { 71 },
    note = "An acoustic metal pipe apparatus fixed to the stadium architecture. Interfacing with the tube handles arena system logs, reviews competitive match records, or triggers localized flavor dialogues.",
},

-- needs review
["Speleological Handbook"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Everbloom Hollow", "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 86, 93, 129 },
    note = "A weathered text ledger compiling underground cave surveying guidelines. Reading the text helps you adjust maze layout configurations or satisfies localized collection tasks inside instanced runs.",
},

-- needs review
["Spell-worked Snow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A patch of packed ice pulsating with a faint magical warmth in the past timeline. Searching through the drift uncovers frozen military supplies and unearths lost artifacts to advance active campaigns.",
},

-- needs review
["Stale Draft"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sacrarium" },
    zoneIds = { 28 },
    note = "A heavy, chilling atmospheric draft whistling fiercely through the cracks of the stone dungeon wall. Pausing inside this air pocket updates active temporal puzzles and tracks your exploration logs.",
},

["Stone Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Pso'Xja", "Outer Horutoto Ruins" },
    zoneIds = { 9, 194 },
    note = "A massive architectural slab of ancient masonry barring deep burial vault corridors. Bypassing the security latch commands the stone framework to slide aside so your party can pass.",
},

["Stone Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Pso'Xja" },
    zoneIds = { 9 },
    note = "A towering, rune-carved stone security barrier partitioning the ancient tower levels. Solving localized puzzle conditions commands the heavy framework to part to clear your exploration path.",
},

["Stone Lid"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Altar Room" },
    zoneIds = { 152 },
    note = "The heavy stone cover of a subterranean ritual vault or altar mechanism. Sliding the lid shifts underlying pulley networks to open secret treasure passages or trigger historic campaign events.",
},

-- needs review
["Stone Picture Frame"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Temple of Uggalepih" },
    zoneIds = { 159 },
    note = "An ornate, moss-covered stone masonry frame inset into the ancient temple wall. Inspecting its hollow layout triggers vivid visions to advance your active side quest milestones.",
},

-- needs review
["Stone Plat"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ranguemont Pass" },
    zoneIds = { 166 },
    note = "A distinct, elevated flat stone platform built into the narrow mountain tunnel paths. Searching the stone edges uncovers forgotten mining provisions or records your active side quest parameters.",
},

-- needs review
["Stone Slab"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "The Eldieme Necropolis [S]" },
    zoneIds = { 175 },
    note = "A weathered stone slab resting over a dark crypt opening in the past timeline. Clearing the dirt uncovers lost military gear needed to resolve active tracking lines across the catacombs.",
},

["Storage Compartment"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Lufaise Meadows", "Misareaux Coast" },
    zoneIds = { 24, 25 },
    note = "A weathered wooden storage locker tucked away along the coastal valley cliffsides. Prying open its locked frame uncovers lost regional resources or retrieves unique campaign supplies.",
},

["Storage Container"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A reinforced wooden cargo box abandoned within the city aqueduct arches. Searching the container uncovers hidden contacts and retrieves specialized regional provisioning items.",
},

-- needs review
["Storage Hole"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A hidden wall cavity or hollow ground recess tucked inside the Orc settlement. Reaching into the dark space uncovers stolen military gear or validates active tracking requirements.",
},

["Storeroom Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Garlaige Citadel [S]" },
    zoneIds = { 164 },
    note = "A fortified wooden barricade partitioning the past-timeline underground fortress supply rooms. Unlatching the door frame grants your squad access to historical weapons rooms.",
},

-- needs review
["Streetlamp"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A gas-powered light post fixed to the city stonework. Interfacing with the terminal bracket handles streetlamp system logs or triggers localized background flavor cutscenes.",
},

["Sturdy Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Rolanberry Fields [S]" },
    zoneIds = { 91 },
    note = "A heavily reinforced wooden portal protecting the past-timeline frontline valley outpost. Forcing open the squealing frame allows your party to securely cross regional boundary thresholds.",
},

-- needs review
["Sunrise Beacon"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A tactical maritime signaling pillar anchoring the port city plaza. Reading the log updates your pioneer geographic data and uncovers files for active frontier research goals.",
},

["Supplies Crate"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Mamool Ja Training Grounds" },
    zoneIds = { 66 },
    note = "A heavy wooden military storage box left abandoned within the training yards. Prying open its reinforced lid recovers essential battlefield provisions and records tracking metrics during active instanced operations.",
},

-- needs review
["Suspicious Object"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria [S]", "Bastok Markets [S]", "Windurst Waters [S]" },
    zoneIds = { 80, 87, 94 },
    note = "An anomalous structural artifact concealed within the municipal squares of the past timeline. Investigating its placement uncovers hidden counter-intelligence notes to advance active campaign storylines.",
},

-- needs review
["Suspicious Overgrowth"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "A thick tangle of unnatural, pulsing flora choking the sacred ground. Foraging through the foliage uncovers hidden biological remnants to advance active Voracious Resurgence missions.",
},

-- needs review
["Suspicious Place"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yorcia Weald" },
    zoneIds = { 263 },
    note = "A shadowy, unsettling clearing tucked deep within the twisted wilderness woods. Pausing inside the area records vital pioneer geographic metrics to advance advanced frontier research goals.",
},

-- needs review
["Suspicious Roots"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yorcia Weald" },
    zoneIds = { 263 },
    note = "A cluster of mutated, gnarled roots breaking heavily through the forest sod. Searching the fissures uncovers rare biological samples to fulfill active pioneer tracking objectives.",
},

["Swirling Vortex"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Lufaise Meadows", "Misareaux Coast", "Al'Taieu", "Apollyon", "Valkurm Dunes", "Qufim Island" },
    zoneIds = { 24, 25, 33, 38, 103, 126 },
    note = "A shimmering dimensional rift warping the overworld landscape layers. Stepping directly into the spatial void verifies your credentials to transition between high-tier battlefield instances.",
},

-- needs review
["Tales' Beginning"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Lower Delkfutt's Tower", "Southern San d'Oria", "Northern San d'Oria", "Port San d'Oria", "Bastok Mines", "Bastok Markets", "Port Bastok", "Windurst Waters", "Windurst Walls", "Port Windurst", "Windurst Woods", "Lower Jeuno", "Port Jeuno", "Norg" },
    zoneIds = { 184, 230, 231, 232, 234, 235, 236, 238, 239, 240, 241, 245, 246, 252 },
    hidden = true,
    note = "A distinct magical marker manifest near prominent municipal gathering hubs. Interfacing with its surface reviews historical records and initiates localized storyline expansions.",
},

["Tales'Beginnin"] = {
    displayName = "Tales' Beginning",
    hidden = true,
},

-- needs review
["The Afflictor"] = {
    type = "Obstacle Node",
    icon = "Box.png",
    zones = { "Beadeaux" },
    zoneIds = { 147 },
    note = "A massive, corrupted ancient device radiating a debilitating curse across the Quadav stronghold. Activating the device without proper shielding key items inflicts severe ailments onto your party.",
},

-- needs review
["The Briars"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A dense thicket of thorny brambles blockading the aqueduct passages. Applying specialized cutting masteries or clearing out the roots updates active city side task logs.",
},

-- needs review
["The Mute"] = {
    type = "Obstacle Node",
    icon = "Box.png",
    zones = { "Beadeaux", "Qulun Dome" },
    zoneIds = { 147, 148 },
    note = "A companion ancient mechanism silencing magical echoes inside the beastman chambers. Interfacing with its core neutralizes or activates the regional layout barrier fields.",
},

["Tidal Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A massive iron-reinforced barrier door tracking the tidal reef currents. Turning the heavy manual valve wheel opens up deep structural pathways into restricted cavern layers.",
},

["Titan's Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Eldieme Necropolis [S]", "The Eldieme Necropolis" },
    zoneIds = { 175, 195 },
    note = "A colossal architectural tomb barrier sealing the deepest subterranean vaults. Solving remote switch puzzles raises the monolithic slab to grant deep exploration access.",
},

-- needs review
["Tombstone"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "King Ranperre's Tomb", "Chateau d'Oraguille" },
    zoneIds = { 190, 233 },
    note = "A weathered stone cemetery monument embedded with ancient noble crests. Brushing off the dust triggers historical cutscenes or verifies critical milestone items for the San d'Orian royal family lines.",
},

-- needs review
["Tome of Magic"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Temple of Uggalepih", "Toraimarai Canal" },
    zoneIds = { 159, 169 },
    note = "A dusty academic book filed away on long-forgotten laboratory shelves. Reading its cryptic handwriting uncovers ancient civilization records and updates active magical side quests.",
},

-- needs review
["Trail Markings"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier", "Xarcabard", "Southern San d'Oria", "Bastok Mines", "Windurst Walls", "Ru'Lude Gardens" },
    zoneIds = { 111, 112, 230, 234, 239, 243 },
    note = "Faint, hurried layout markings scratched into the overworld rock faces and city streets. Studying these tracking anchors details regional lore and coordinates active investigative trials.",
},

["Transcendental Radiance"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Empyreal Paradox", "Qufim Island", "Abyssea - Empyreal Paradox", "Desuetia - Empyreal Paradox" },
    zoneIds = { 36, 126, 255, 290 },
    note = "A brilliant, pulsing cosmic rift hovering above the dimensional void. Stepping directly into the blinding aura checks your group alignment metrics to launch legendary master battlefield instances.",
},

["Translocator #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "An ancient technological console pulsing within the fractured space-time loops. Interfacing with its crystalline grid opens a slipstream to teleport your squad instantly between distinct instance wings.",
},

["Translocator #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The secondary localized warp hub within the temporal research layers. Activating its light lattice matrix shifts your entire alliance across layout walls into advanced challenge rooms.",
},

["Translocator #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The third specialized travel waypoint resting in the advanced instance tiers. Synchronizing your destination keys here lets you navigate through higher floor sectors safely.",
},

-- needs review
["Trodden Snow"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Qufim Island" },
    zoneIds = { 126 },
    note = "A distinct patch of loose, packed ice revealing disturbed ground underneath. Sifting through the drift uncovers forgotten explorer cargo or registers crucial tracking metrics.",
},

["Trunk"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Riverne - Site #A01" },
    zoneIds = { 30 },
    note = "A reinforced wooden cargo box abandoned along the floating sky tracks. Prying open its splintered timber lid uncovers lost regional resources or unique campaign supplies.",
},

["Underbrush"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Vunkerl Inlet [S]" },
    zoneIds = { 83 },
    note = "A thick outcropping of wild botanical shrubbery growing over hidden drops in the past timeline. Foraging through the greenery gathers unique materials and satisfies strict collection parameters.",
},

-- needs review
["Underground Pool"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Fei'Yin" },
    zoneIds = { 204 },
    note = "A dark subterranean water basin pooling quietly beneath the frozen ruins. Looking into the clear liquid projects ancient fortress memories and updates active artifact gathering goals.",
},

["Underpass Hatch"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Batallia Downs [S]" },
    zoneIds = { 84 },
    note = "A reinforced metallic deck hatch blocking off the lower vents of the past-timeline fortifications. Releasing its heavy locks lets you drop into secure subterranean tunnels.",
},

["Undulating Confluence"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Misareaux Coast", "Qufim Island", "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 25, 126, 288, 289 },
    note = "A shimmering, swirling vortex of spatial energy warping the overworld landscape. Stepping directly into the ripple accesses the regional teleportation grid to shift you instantly into Eschan domains.",
},

["Provenance Crystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Provenance" },
    zoneIds = { 222 },
    note = "A high-fidelity dimensional crystalline anchor pulsing within the celestial battlefield domain. Stepping onto the crystal platform evaluates your battle parameters to transport you directly to advanced extraplanar challenges.",
},

["Provenance Protocrystal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Provenance" },
    zoneIds = { 222 },
    note = "The core elemental genesis crystal anchoring the apex arena layer. Synchronizing your squad records with its shimmering matrix launches endgame battlefield trials against legendary adversaries.",
},

["Painted Wooden Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Fort Karugo-Narugo [S]" },
    zoneIds = { 96 },
    note = "A brightly painted wooden gate standing along the fortress battlements of the past timeline. Satisfying the local military watch command slides the timber bracing aside to grant entry through the garrison lines.",
},

["Cell Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Garlaige Citadel [S]", "Bostaunieux Oubliette" },
    zoneIds = { 94, 164, 167 },
    note = "A reinforced iron-barred barrier locking off underground prison blocks or deep ruin vaults. Procuring specialized dungeon keys releases the heavy latch so you can explore further or free captives.",
},

["Sewer Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Tavnazian Safehold" },
    zoneIds = { 26 },
    note = "A heavy iron-banded doorway framework locking off the underground aqueduct passages. Passing through this transitional archway leaves the residential sector behind to plunge you directly into the sewer grid.",
},

["Sewer Lid"] = {
    type = "Security Gate",
    icon = "SewerLid.png",
    zones = { "Bostaunieux Oubliette" },
    zoneIds = { 167 },
    note = "A heavy, circular iron floor plate sealing off the lower aqueduct drainage shafts. Sliding the metallic lid open reveals drop-down tunnels leading into the dangerous underbelly of the dungeon layouts.",
},

["Wooden Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Garlaige Citadel [S]", "Bostaunieux Oubliette" },
    zoneIds = { 94, 164, 167 },
    note = "A sturdy timber barrier partition blockading subterranean dungeon pathways and municipal vaults. Turning the rusted handle swings the squealing frame aside to clear your exploration path.",
},

["Adder Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Southern San d'Oria [S]", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "La Vaule [S]", "Bastok Markets [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "Beadeaux [S]", "Windurst Waters [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Castle Oztroja [S]", "Beaucedine Glacier [S]", "Xarcabard [S]", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
    note = "A grand military campaign reward chest materializing across frontlines in the past timeline. Opening the lock distributes battlefield experience, regional items, or elite wartime currencies to your squad.",
},

["Aurum Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A high-tier gilded treasure repository manifested inside the fractured layers of the underworld. Breaking its stubborn wards rewards your alliance with endgame currencies and specialized augment materials.",
},

["Bison Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Southern San d'Oria [S]", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "La Vaule [S]", "Bastok Markets [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "Beadeaux [S]", "Windurst Waters [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Castle Oztroja [S]", "Beaucedine Glacier [S]", "Xarcabard [S]", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
    note = "A companion campaign treasure chest dropped onto tactical overworld battlefields. Opening this repository distributes elite armor supplies, munitions, and defensive tactical enhancements.",
},

["Capacious Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 93, 129 },
    note = "A heavy reward coffer appearing upon clearing instance challenges. Unlocking the reinforced framing awards your participating team with unique gear pieces and allocations of experience.",
},

["Casket"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Yuhtunga Jungle", "Yhoator Jungle", "Western Altepa Desert" },
    zoneIds = { 123, 124, 125 },
    note = "A weathered treasure chest half-buried along tropical forest pathways and desert dunes. Breaking past the lock reveals localized items, currency caches, or hidden regional materials.",
},

-- needs review
["Castoff Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yahse Hunting Grounds", "Foret de Hennetiel", "Morimar Basalt Fields", "Sih Gates", "Cirdas Caverns" },
    zoneIds = { 260, 262, 265, 268, 270 },
    note = "A distinct natural shoreline projection or river edge waypoint along the frontier pathways. Investigating the water edge logs pioneer mapping charts and updates your active wilderness survey records.",
},

["Celebratory Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Chateau d'Oraguille", "Metalworks", "Heavens Tower" },
    zoneIds = { 233, 237, 242 },
    note = "A stylized national festive coffer manifest within prominent sovereign audience chambers. Opening this repository distributes unique holiday cosmetics or registers custom server event milestones.",
},

["Cermet Portal"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Grand Palace of Hu'Xzoi", "The Garden of Ru'Hmet", "Fei'Yin" },
    zoneIds = { 34, 35, 204 },
    note = "An enduring ancient composite gate barring deep structural laboratory chambers. Presenting recognized regional relics or satisfying technological puzzle constraints commands the portal frame to part.",
},

["Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Maze of Shakhrami", "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]", "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 133, 189, 198, 275, 279, 298 },
    note = "A standard wooden repository found tucked away inside dungeon corridors or manifested throughout endgame battle sectors. Prying open its lid rewards your squad with regional supplies, maps, or unique currency components.",
},

["Chest #A1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary sector treasure box appearing in Sector A [INDEX]. Cracking its lock yields foundational item upgrades or basic instance-specific tokens for your alliance [INDEX].",
},

["Chest #A2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The second designated reward repository manifest along the Sector A pathways [INDEX]. Overcoming specific combat objectives unseals the chest frame to reveal pristine armor fragments.",
},

["Chest #A3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third tactical treasure box stationed deep inside Sector A rooms [INDEX]. Satisfying localized puzzle constraints rewards your squad with advanced material shards [INDEX].",
},

["Chest #A4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fourth specific prize cache appearing when your battle group completes rapid exploration targets within Sector A [INDEX]. Opening the lid reveals specialized development resources.",
},

["Chest #A5"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final localized milestone container dropped onto the stone floor tiers of Sector A [INDEX]. Accessing its interface claims valuable high-tier armor templates.",
},

["Chest #B1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The foundational reward repository unsealed inside the wings of Sector B [INDEX]. Searching the interior uncovers basic instance currencies and initial equipment upgrade scripts.",
},

["Chest #B2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary sector treasure box manifest inside Sector B combat rooms [INDEX]. Prying open the frame grants your party access to advanced artifact upgrade elements.",
},

["Chest #B3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third designated prize container appearing after your alliance fulfills distinct wave targets in Sector B [INDEX]. Ransacking the box claims advanced regional drop supplies.",
},

["Chest #B4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fourth specific reward chest materializing along the perimeter paths of Sector B [INDEX]. Breaking the lock code updates your squad with high-end instance tokens.",
},

["Chest #B5"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fifth specialized reward chest anchoring the terminal clearance loops of Sector B [INDEX]. Cracking the seal unrolls elite combat armor spoils for your whole squad.",
},

["Chest #C1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary milestone prize box dropped onto the corridor floor layouts of Sector C [INDEX]. Interfacing with the terminal claims baseline currency and sector equipment components.",
},

["Chest #C2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The second designated reward repository manifest across the trial chambers of Sector C [INDEX]. Meeting direct area targets unlocks the chest framework to reveal advanced tokens.",
},

["Chest #C3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third localized treasure box pulsing deep within Sector C sectors [INDEX]. Searching through the box rewards your squad with unique armor matrix pieces and pristine fragments.",
},

["Chest #C4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fourth specific prize repository materializing along the side paths of Sector C [INDEX]. Overriding the locking systems uncovers rare regional loot supplies.",
},

["Chest #C5"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fifth specialized milestone container unsealed at the end of Sector C corridors [INDEX]. Breaking past its ward uncovers late-tier equipment templates to bolster your gear parameters.",
},

["Chest #D1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The foundational treasure repository appearing upon fulfilling basic goals inside Sector D [INDEX]. Opening the lock distributes rare artifact upgrade materials and instance-specific tokens.",
},

["Chest #D2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary sector reward chest manifest along the Sector D trial chambers [INDEX]. Satisfying localized parameter conditions lifts the locking framework to reveal pristine armor matrices.",
},

["Chest #D3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third localized prize repository dropping post-combat within Sector D wings [INDEX]. Accessing its interface yields lost items, recovery tokens, or temporary regional combat enhancements.",
},

["Chest #D4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fourth specific prize repository materializing along the side paths of Sector D [INDEX]. Overriding the locking loops distributes high-tier equipment spoils to your entire party.",
},

["Chest #D5"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final localized milestone container dropped at the end of Sector D trial loops. Breaking its locking systems rewards your squad with late-tier equipment templates and unique currency components.",
},

["Chest #E"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A high-fidelity sector reward chest manifesting inside lower-tier Sector E. Cracking this stubborn lock unlocks advanced endgame currencies and elite armor fragments for your alliance.",
},

["Chest #F"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The foundational treasure repository appearing upon fulfilling lower-level Sector F combat goals. Searching the chest uncovers pristine synthesis metals and advanced armor elements.",
},

["Chest #G"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary deep-level reward coffer dropping post-combat within lower-tier Sector G corridors. Accessing its interface coordinates high-end armor spoils and temporal currency metrics.",
},

["Chest #H"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The ultimate baseline reward chest granted for clearing advanced trials deep inside lower-tier Sector H. Prying it open uncovers rare historical relics and pristine armor matrices.",
},

["Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Mamool Ja Training Grounds", "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 66, 279, 298 },
    note = "A heavy ornate repository found tucked away inside dungeon chambers or manifested throughout endgame battle sectors. Prying open its lid rewards your squad with regional supplies or unique currency components.",
},

["Coffer #A"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "A high-fidelity sector reward chest manifesting inside the Sortie instance layers. Cracking open this Sector A coffer yields specialized gear upgrade items and temporal currencies for your alliance.",
},

["Coffer #B"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary prize repository appearing upon completing basic target parameters inside Sector B. Opening the lock distributes rare artifact upgrade materials and instance-specific tokens.",
},

["Coffer #C"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The baseline reward container dropped onto the stone floors of Sector C. Interfacing with this box secures valuable temporal currencies and crucial components to build up your endgame sets.",
},

["Coffer #D"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The initial milestone reward chest granted for tracking and purging targets inside Sector D. Accessing the repository claims instant currency awards and vital progression enhancements.",
},

["Coffer #E"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary deep subterranean repository materializing inside lower-tier Sector E. Cracking this stubborn lock unlocks advanced endgame currencies and elite upgrade templates.",
},

["Coffer #F"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The foundational treasure repository appearing upon fulfilling lower-level Sector F combat goals. Searching the chest uncovers pristine synthesis metals and advanced armor elements.",
},

["Coffer #G"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary deep-level reward coffer dropping post-combat within lower-tier Sector G corridors. Accessing its interface coordinates high-end armor spoils and temporal currency metrics.",
},

["Coffer #H"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final lower-level bonus repository unsealed inside the deepest recesses of Sector H. Overcoming the master switch puzzles raises the locking mechanisms to claim final endgame rewards.",
},

["Conflux Surveyor"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Altepa", "Abyssea - Attohwa", "Abyssea - Grauberg", "Abyssea - Konschtat", "Abyssea - La Theine", "Abyssea - Misareaux", "Abyssea - Tahrongi", "Abyssea - Uleguerand", "Abyssea - Vunkerl" },
    zoneIds = { 15, 45, 132, 215, 216, 217, 218, 253, 254 },
    note = "A shimmering spatial distortion apparatus stationed at critical temporal hubs. Tuning into its rhythmic frequency coordinates your localized mapping data and teleports your party between active Abyssean sectors.",
},

["Coteaulepoint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Batallia Downs", "Chateau d'Oraguille" },
    zoneIds = { 105, 233 },
    note = "A localized spatial landmark structural point. Examining it checks dynamic progress flags or validates regional side tasks within the Kingdom's borders.",
},

["Coyote Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Southern San d'Oria [S]", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "La Vaule [S]", "Bastok Markets [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "Beadeaux [S]", "Windurst Waters [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Castle Oztroja [S]", "Beaucedine Glacier [S]", "Xarcabard [S]", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
    note = "A campaign battle chest materializing across frontlines in the past timeline. Opening the lock code rewards your squad with combat supplies, weapons components, or temporal campaign currencies.",
},

["Dhole Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Southern San d'Oria [S]", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "La Vaule [S]", "Bastok Markets [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "Beadeaux [S]", "Windurst Waters [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Castle Oztroja [S]", "Beaucedine Glacier [S]", "Xarcabard [S]", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
    note = "A tactical campaign prize repository manifest across past-timeline conflict fields. Breaking its seal rewards your participating alliance with specialized armor provisions and items components.",
},

["Dimensional Portal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "La Theine Plateau", "Konschtat Highlands", "Xarcabard", "Tahrongi Canyon", "Yhoator Jungle", "Al'Taieu", "Empyreal Paradox", "Jugner Forest [S]", "Pashhow Marshlands [S]", "Meriphataud Mountains [S]", "Eastern Altepa Desert", "Desuetia - Empyreal Paradox", "Reisenjima" },
    zoneIds = { 33, 36, 82, 90, 97, 102, 108, 112, 114, 117, 124, 290, 291 },
    note = "A swirling cosmic rift tearing through the overworld landscape. Stepping into the blinding light checks your alliance credentials to warp you directly across high-tier expansion battlefields.",
},

["Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Open Sea Route to Al Zahbi", "Open Sea Route to Mhaura", "Al Zahbi", "Aht Urhgan Whitegate", "Ship Bound for Mhaura", "Ship Bound for Mhaura (Pirates)", "Qulun Dome", "Ship Bound for Selbina", "Ship Bound for Selbina (Pirates)", "Silver Sea Route to Al Zahbi", "Silver Sea Route to Nashmau" },
    zoneIds = { 46, 47, 48, 50, 58, 59, 148, 220, 221, 227, 228 },
    note = "A standard portal separating regional compartments or ship cabins. Throwing open the wooden or iron framework handles room navigation or retreats your squad safely during pirate raids.",
},

["Door:\"Lion Springs\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria [S]", "Southern San d'Oria" },
    zoneIds = { 80, 230 },
    note = "The heavy timber entrance portal leading into the local tavern. Unlatching the frame advances city tracking investigations or triggers past-timeline cutscenes.",
},

["Door:Acolyte hostel"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Windurst Waters" },
    zoneIds = { 94, 238 },
    note = "A basic wooden barrier partitioning the religious residential layout blocks. Interfacing with the latch uncovers regional side quest details or updates local lore lines.",
},

["Door:Arrivals Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria", "Port Bastok", "Port Windurst", "Port Jeuno" },
    zoneIds = { 232, 236, 240, 246 },
    note = "The structural port checkpoint door separating international traffic. Passing past the framework manages airship terminal transit scripts or processes tracking goals.",
},

["Door:Arrivals Exit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria", "Port Bastok", "Port Windurst", "Port Jeuno" },
    zoneIds = { 232, 236, 240, 246 },
    note = "The heavy terminal gateway threshold exiting the arrivals deck. Shifting the latch moves you out into the public city port districts from travel layers.",
},

["Door:Audience Chamber"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks", "Ru'Lude Gardens" },
    zoneIds = { 237, 243 },
    note = "An elegant, massive portal archway guarding corporate laboratories and executive palace halls. Presenting country mission credentials triggers the frame to open.",
},

["Door:Blacksmiths' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria", "Metalworks", "Mhaura" },
    zoneIds = { 231, 237, 249 },
    note = "A heavy iron-banded door sealing off industrial forge yards. Operating the handle opens up advanced crafting synthesis areas and fulfills tracking tasks.",
},

["Door:Chocobo Stables"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria", "Bastok Mines", "Windurst Woods", "Upper Jeuno", "Lower Jeuno", "Port Jeuno" },
    zoneIds = { 230, 234, 241, 244, 245, 246 },
    note = "A basic timber sliding barrier sealing off regional mount stables. Unlatching the frame allows you to access transport paths, check vouchers, or purchase racing gear.",
},

["Door:Cid's Lab"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets [S]", "Metalworks" },
    zoneIds = { 87, 237 },
    note = "A reinforced door leading into the grand workshop engine rooms. Passing the frame tracks advanced Republic milestones or triggers past-timeline scenarios.",
},

["Door:Clerical Chamber"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "West Sarutabaruta [S]", "Heavens Tower" },
    zoneIds = { 95, 242 },
    note = "An ornate, stone security barrier separating administrative chambers and temple corridors. Verifying national mission clearance commands the framework to part.",
},

["Door:Departures Entrance"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria", "Port Bastok", "Port Windurst", "Port Jeuno" },
    zoneIds = { 232, 236, 240, 246 },
    note = "The localized security check portal blockading the departure docks. Passing through checks active boarding passes to grant access to transit lines.",
},

["Door:Departures Exit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria", "Port Bastok", "Port Windurst", "Port Jeuno" },
    zoneIds = { 232, 236, 240, 246 },
    note = "The heavy timber framework exiting the airship platform. Shifting the latch moves you off travel vessels to return securely into the terminal.",
},

["Door:Goldsmiths' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets", "Mhaura" },
    zoneIds = { 235, 249 },
    note = "An elegant wooden partition protecting artisan metalworking halls. Unlatching the door frame provides entry to claim advanced synthetic craft trials.",
},

["Door:M & P's Market"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno", "Kazham" },
    zoneIds = { 244, 250 },
    note = "A basic shopfront portal dividing market districts and trading counters. Interfacing with the latch updates urban tracking logs or triggers localized dialogue.",
},

["Door:Optistery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Windurst Waters" },
    zoneIds = { 94, 238 },
    note = "A dusty academic door hinged to the magical research academy. Pulling the handle uncovers rare library records or validates active Federation quests.",
},

["Door:Rhinostery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Windurst Waters" },
    zoneIds = { 94, 238 },
    note = "The heavy wooden entry barrier leading to the magical biological research laboratories. Pulling the handle uncovers rare library records or validates active Federation quest milestones.",
},

["Door:San d'Orian Consul"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks", "Windurst Woods" },
    zoneIds = { 237, 241 },
    note = "A secure portal archway partitioning off the foreign diplomatic embassy offices. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Trader's Home"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets", "Windurst Waters" },
    zoneIds = { 235, 238 },
    note = "A basic residential wooden door set into the city stonework layouts. Unlatching the frame allows you to enter merchant quarters to fulfill commercial delivery checks or urban side tasks.",
},

["Door:Weavers' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Woods", "Selbina" },
    zoneIds = { 241, 248 },
    note = "A standard wooden partition protecting artisan textile crafting halls. Activating the handle opens up advanced synthetic craft yards and checks active guild progression parameters.",
},

["Door:Windurstian Consul"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria", "Metalworks" },
    zoneIds = { 231, 237 },
    note = "A secure embassy entrance framework partitioning off Federation diplomatic chambers. Verifying your current national mission clearance commands the ornate frame to open.",
},

["Door_3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters [S]", "Full Moon Fountain", "Heavens Tower" },
    zoneIds = { 94, 170, 242 },
    note = "A specific structural door barrier protecting restricted interior rooms. Passing past the framework manages municipal layout navigation scripts or updates active storyline progression phases.",
},

["door_master"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos", "Ilrusi Atoll", "Periqia", "Lebros Cavern", "Leujaoam Sanctum", "Mamool Ja Training Grounds", "Everbloom Hollow", "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 12, 55, 56, 63, 66, 69, 86, 93, 129 },
    note = "A standardized structural door layout unit sealing off intense instanced challenge rooms or operations sectors. Overriding the nearby locking mechanism slides the heavy panel away to grant passage.",
},

-- needs review
["Driftlix"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Bastok Markets [S]", "North Gustaberg [S]" },
    zoneIds = { 87, 88 },
    note = "A distinct natural ground landmark protrusion or hidden object checkpoint found in past-timeline sectors. Examining it updates dynamic exploration logs or yields unique collection materials.",
},

["Eland Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Southern San d'Oria [S]", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "La Vaule [S]", "Bastok Markets [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "Beadeaux [S]", "Windurst Waters [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Castle Oztroja [S]", "Beaucedine Glacier [S]", "Xarcabard [S]", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep [S]", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "The Eldieme Necropolis [S]" },
    zoneIds = { 80, 81, 82, 83, 84, 85, 87, 88, 89, 90, 91, 92, 94, 95, 96, 97, 98, 99, 136, 137, 138, 155, 164, 171, 175 },
    note = "A grand campaign battle coffer materializing across frontlines in the past timeline. Opening the lock code rewards your squad with elite armor supplies, munitions, and temporal combat rewards.",
},

-- needs review
["Enigmatic Footprints #2"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria", "Bastok Mines", "Windurst Walls", "Ru'Lude Gardens" },
    zoneIds = { 230, 234, 239, 243 },
    note = "A set of faint, mysterious tracking indentations pressed into the municipal floor paths. Studying the unusual prints uncovers hidden investigative records to advance active side quests.",
},

["Eschan Portal #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The primary crystalline fast-travel gateway floating inside the Eschan domains. Tuning into its frequency links you to the regional teleportation grid, granting an instant leap across active map nodes.",
},

["Eschan Portal #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The secondary floating travel nexus embedded within the interplanar hunting rings. Stepping onto its base taps into the ancient world-warp grid to deliver your party directly into the middle sectors.",
},

["Eschan Portal #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The third localized crystalline travel monument pulsing with extraplanar energy. Activating the floating lattice matrix allows you to slip effortlessly through spatial barriers to arrive at targeted exploration points.",
},

["Eschan Portal #4"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The fourth fast-travel energy gateway humming along the perimeter pathways. Synchronizing your spiritual path with this floating rock bridges regional sector lines to warp you instantly across the landscape.",
},

["Eschan Portal #5"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The fifth specialized fast-travel crystalline core floating deep inside the dangerous hunting zones. Interfacing with this layout node provides an instant dimensional leap away from surrounding hazards.",
},

["Eschan Portal #6"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The sixth strategic travel waypoint resting in the advanced level tiers. Channeling its magical currents manipulates extraplanar networks to transport your adventuring party across localized map sectors.",
},

["Eschan Portal #7"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The seventh high-tier crystalline travel waypoint anchored near elite battle grounds. Linking your destination keys here lets you navigate through advanced areas without trekking through enemy territory.",
},

["Eschan Portal #8"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Zi'Tah", "Escha - Ru'Aun" },
    zoneIds = { 288, 289 },
    note = "The final crystalline fast-travel nexus anchoring the deepest reaches of the realm. Activating the floating lattice matrix allows you to cross the zone instantly, connecting you directly to challenging perimeter territory.",
},

["Ethereal Junction #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "A shimmering dimensional distortion residue light anomaly pulsing inside the Walk of Echoes. Gathering your party before the rift verifies your group parameters to launch high-tier battle encounters.",
},

["Ethereal Junction #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The secondary localized rift distortion pulsing inside the Walk of Echoes. Gathering your party before the anomaly verifies your alliance metrics to launch high-tier battle encounters.",
},

["Ethereal Junction #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The third specialized travel rift waypoint resting in the advanced instance tiers. Stepping directly into the distortion fields bridges separate timeline loops to launch deep battle trials.",
},

["Ethereal Junction #4"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The fourth fast-travel energy rift humming along the layout walkways. Synchronizing your spiritual parameters with the platform launches your group directly into intense endgame battle scenarios.",
},

["Ethereal Junction #5"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The fifth specialized spatial distortion core floating inside the fractured landscape. Interfacing with this ancient system node triggers a rapid energy slipstream to deliver you to advanced challenge rooms.",
},

["Ethereal Junction #6"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The sixth strategic travel waypoint anchoring high-level battle loops. Tapping into its ancient world-warp grid teleports your adventuring party safely across the fractured instance layouts.",
},

["Ethereal Junction #7"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The final crystalline travel monument unsealed at the end of the temporal loops. Aligning your group parameters with its crystalline grid opens the gateway to launch elite finale battlefields.",
},

["Gate #A1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The first heavy barrier door blockading the Sector A corridors of the underworld instance. Overriding its restrictive locking parameters drops the panel to grant deeper progression.",
},

["Gate #A2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The second designated security partition manifest along the Sector A pathways. Satisfying localized area parameters commands the heavy iron-reinforced framework to slide open.",
},

["Gate #A3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third heavy gate structure fortifying the Sector A chambers. Clearing the surrounding baseline combat trials triggers the remote winches to swing the frame aside.",
},

["Gate #B1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary defensive wall blockading the entrance to Sector B layout paths. Meeting direct area requirements unlatches the door framework to let your squad advance.",
},

["Gate #B2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary sector security barrier partition inside Sector B. Presenting the matching regional keys or tokens releases the heavy iron latch so you can explore further ahead.",
},

["Gate #B3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third localized gate structure guarding the shifting Sector B trial rooms. Overcoming the local security trials releases the locking framework to let you pass.",
},

["Gate #B4"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fourth specific defensive barrier fortifying the deep Sector B corridors. Throwing your weight against the nearby triggers engages the pully systems to lift the frame.",
},

["Gate #B5"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The fifth specialized gate barrier partition anchoring the intermediate loops of Sector B. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

["Gate #B6"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The final structural locking boundary sealing the inner Sector B courtyard chambers. Overcoming the elite sector guardians triggers the winches, opening the path ahead.",
},

["Gate #C1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The primary milestone security barrier separating ancient technological chambers in Sector C. Turning the manual door valves overrides the circuitry to grant entry.",
},

["Gate #C2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The second designated security partition manifest across the trial chambers of Sector C. Verifying your current challenge clearance commands the heavy stone frame to part.",
},

["Gate #C3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The third localized gate structure guarding the deep Sector C pathways. Finding and utilizing a specialized key item releases the heavy framework to let you pass.",
},

["Gate #D1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The foundational barrier door blocking the entrance to advanced Sector D layout paths. Meeting direct area requirements unlatches the door framework to let your squad advance.",
},

["Gate #D2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Outer Rakaznar [U1]", "Outer Rakaznar [U2]", "Outer Rakaznar [U3]" },
    zoneIds = { 133, 189, 275 },
    note = "The secondary milestone security partition blocking deep layouts of Sector D. Clearing nearby sector threats triggers remote mechanical winches to swing the heavy framework aside.",
},

["Gate of Darkness"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins", "Windurst Woods" },
    zoneIds = { 192, 241 },
    note = "A shadowy, magically sealed ancient archway gate blocking access to forbidden ruin tunnels. Overriding the negative alignment currents commands the heavy portal panels to part.",
},

["Gate Sentry"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "Xarcabard [S]", "Beaucedine Glacier [S]" },
    zoneIds = { 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 136, 137 },
    note = "A heavily armored defensive barrier guarding tactical checkpoints in the past timeline. Clearing military verification protocols commands the framework to unlatch across frontline borders.",
},

["Gate: Chocobo Circuit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chocobo Circuit", "Aht Urhgan Whitegate", "Southern San d'Oria", "Bastok Mines", "Windurst Woods", "Port Jeuno" },
    zoneIds = { 50, 70, 230, 234, 241, 246 },
    note = "A standard track boundary gate partitioning off the grand racing lanes. Interfacing with the terminal matches registration tokens to grant your character lane access.",
},

["Gate: Magical Gizmo"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins", "Outer Horutoto Ruins" },
    zoneIds = { 192, 194 },
    note = "A strange ancient composite portal locked shut by technical mechanisms inside the ruins. Activating adjacent elemental switches shifts the framework aside.",
},

["Gate: The Pit"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate", "The Colosseum" },
    zoneIds = { 50, 71 },
    note = "A sturdy iron-barred portcullis partition separating spectators from the combat pits. Triggering the arena console drops the gate to launch battle matches.",
},

["GoalPoint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef", "Halvung", "Mamook", "Aydeewa Subterrane", "Beadeaux", "Davoi", "Castle Oztroja", "Temple of Uggalepih", "Den of Rancor", "Ranguemont Pass", "Bostaunieux Oubliette", "Toraimarai Canal", "The Eldieme Necropolis", "Crawlers' Nest", "Garlaige Citadel", "Ifrit's Cauldron", "Kuftal Tunnel", "Gustav Tunnel" },
    zoneIds = { 54, 62, 65, 68, 147, 149, 151, 159, 160, 166, 167, 169, 174, 195, 197, 200, 205, 212 },
    note = "An ancient structural focal destination waypoint hidden deep inside sprawling dungeons. Reaching this layout node validates complex progression flags or completes server event tasks.",
},

["Goblin Footprint"] = {
    type = "Memory Recall",
    icon = "Cutscene.png",
    zones = { "Abyssea - Empyreal Paradox", "Al Zahbi", "Al'Taieu", "Altar Room", "Alzadaal Undersea Ruins", "Arrapago Reef", "Aydeewa Subterrane", "Balga's Dais", "Batallia Downs", "Batallia Downs [S]", "Beadeaux", "Beadeaux [S]", "Bearclaw Pinnacle", "Beaucedine Glacier", "Beaucedine Glacier [S]", "Bhaflau Thickets", "Bibiki Bay", "Boneyard Gully", "Bostaunieux Oubliette", "Buburimu Peninsula", "Caedarva Mire", "Cape Teriggan", "Carpenters' Landing", "Castle Oztroja", "Castle Oztroja [S]", "Castle Zvahl Baileys", "Castle Zvahl Baileys [S]", "Castle Zvahl Keep", "Castle Zvahl Keep [S]", "Ceizak Battlegrounds", "Chamber of Oracles", "Cirdas Caverns", "Cloister of Flames", "Cloister of Frost", "Cloister of Gales", "Cloister of Storms", "Cloister of Tides", "Cloister of Tremors", "Crawlers' Nest", "Crawlers' Nest [S]", "Dangruf Wadi", "Davoi", "Desuetia - Empyreal Paradox", "Dho Gates", "Dragon's Aery", "East Ronfaure [S]", "East Sarutabaruta", "Empyreal Paradox", "Escha - Ru'Aun", "Escha - Zi'Tah", "Fei'Yin", "Feretory", "Foret de Hennetiel", "Fort Karugo-Narugo [S]", "Full Moon Fountain", "Garlaige Citadel", "Garlaige Citadel [S]", "Ghelsba Outpost", "Giddeus", "Grand Palace of Hu'Xzoi", "Grauberg [S]", "Gusgen Mines", "Gustav Tunnel", "Hall of The Gods", "Hall of Transference", "Halvung", "Hazhalm Testing Grounds", "Horlais Peak", "Ifrit's Cauldron", "Inner Horutoto Ruins", "Jade Sepulcher", "Jugner Forest", "Jugner Forest [S]", "Kamihr Drifts", "King Ranperre's Tomb", "Konschtat Highlands", "Korroloka Tunnel", "Kuftal Tunnel", "La Theine Plateau", "La Vaule [S]", "La'Loff Amphitheater", "Leafallia", "Lower Delkfutt's Tower", "Lufaise Meadows", "Mamook", "Marjami Ravine", "Maze of Shakhrami", "Meriphataud Mountains", "Meriphataud Mountains [S]", "Middle Delkfutt's Tower", "Mine Shaft #2716", "Misareaux Coast", "Mog Garden", "Moh Gates", "Monarch Linn", "Monastic Cavern", "Morimar Basalt Fields", "Mount Kamihr", "Mount Zhayolm", "Navukgo Execution Chamber", "North Gustaberg", "North Gustaberg [S]", "Oldton Movalpolos", "Ordelle's Caves", "Outer Horutoto Ruins", "Outer Ra'Kaznar", "Palborough Mines", "Pashhow Marshlands", "Pashhow Marshlands [S]", "Phomiuna Aqueducts", "Promyvion - Vahzl", "Provenance", "Pso'Xja", "Qu'Bia Arena", "Qufim Island", "Quicksand Caves", "Qulun Dome", "Ra'Kaznar Inner Court", "Ra'Kaznar Turris", "Ranguemont Pass", "Reisenjima", "Reisenjima Sanctorium", "Riverne - Site #A01", "Riverne - Site #B01", "Ro'Maeve", "Rolanberry Fields", "Rolanberry Fields [S]", "Ru'Aun Gardens", "Sacrarium", "Sacrificial Chamber", "Sauromugue Champaign", "Sauromugue Champaign [S]", "Sea Serpent Grotto", "Sih Gates", "South Gustaberg", "Spire of Dem", "Spire of Holla", "Spire of Mea", "Spire of Vahzl", "Stellar Fulcrum", "Tahrongi Canyon", "Talacca Cove", "Temple of Uggalepih", "The Boyahda Tree", "The Celestial Nexus", "The Eldieme Necropolis", "The Eldieme Necropolis [S]", "The Garden of Ru'Hmet", "The Sanctuary of Zi'Tah", "The Shrine of Ru'Avitau", "The Shrouded Maw", "Throne Room", "Throne Room [S]", "Toraimarai Canal", "Uleguerand Range", "Valkurm Dunes", "Valley of Sorrows", "Vunkerl Inlet [S]", "Wajaom Woodlands", "Walk of Echoes", "Waughroon Shrine", "West Ronfaure", "West Sarutabaruta", "West Sarutabaruta [S]", "Western Altepa Desert", "Woh Gates", "Xarcabard", "Xarcabard [S]", "Yahse Hunting Grounds", "Yorcia Weald", "Yughott Grotto", "Yuhtunga Jungle", "Zeruhn Mines" },
    worldOffsetY = 0.0,
    zoneIds = { 2, 4, 5, 6, 8, 9, 10, 11, 13, 14, 17, 19, 21, 22, 23, 24, 25, 27, 28, 29, 30, 31, 33, 34, 35, 36, 48, 51, 52, 54, 57, 61, 62, 64, 65, 67, 68, 72, 78, 79, 81, 82, 83, 84, 85, 88, 89, 90, 91, 92, 95, 96, 97, 98, 99, 100, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 115, 116, 117, 118, 119, 120, 121, 122, 123, 125, 126, 128, 130, 136, 137, 138, 139, 140, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 159, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 178, 179, 180, 181, 182, 184, 190, 191, 192, 193, 194, 195, 196, 197, 198, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 211, 212, 222, 251, 255, 260, 261, 262, 263, 265, 266, 267, 268, 269, 270, 272, 273, 274, 276, 277, 280, 281, 282, 285, 288, 289, 290, 291, 293 },
    note = "A small indention in the dirt storing dimensional memory data traces. Trading an overworld artifact or currency slip to the footprint triggers a vivid replay of historical region cutscenes.",
},

["Field Manual"] = {
    type = "Training & Support",
    icon = "Dialogue.png",
    zones = { "West Ronfaure", "East Ronfaure", "La Theine Plateau", "Valkurm Dunes", "Jugner Forest", "Batallia Downs", "Beaucedine Glacier", "North Gustaberg", "South Gustaberg", "Konschtat Highlands", "Rolanberry Fields", "Xarcabard", "Cape Teriggan", "Valley of Sorrows", "West Sarutabaruta", "East Sarutabaruta", "Tahrongi Canyon", "Buburimu Peninsula", "Meriphataud Mountains", "Sauromugue Champaign", "The Sanctuary of Zi'Tah", "Ro'Maeve", "Yuhtunga Jungle", "Yhoator Jungle", "Western Altepa Desert", "Eastern Altepa Desert", "Qufim Island", "Behemoth's Dominion", "Ru'Aun Gardens" },
    zoneIds = { 100, 101, 102, 103, 104, 105, 111, 106, 107, 108, 110, 112, 113, 128, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 114, 126, 127, 130 },
    note = "A stationary training ledger podium stationed at military outposts. Reading the text lets you enlist in regional combat regimes, check training metrics, or purchase field enhancements.",
},

["Field Parchment"] = {
    type = "Training & Support",
    icon = "Dialogue.png",
    zones = { "West Ronfaure", "East Ronfaure", "La Theine Plateau", "Valkurm Dunes", "Jugner Forest", "Batallia Downs", "Beaucedine Glacier", "North Gustaberg", "South Gustaberg", "Konschtat Highlands", "Rolanberry Fields", "Xarcabard", "Cape Teriggan", "Valley of Sorrows", "West Sarutabaruta", "East Sarutabaruta", "Tahrongi Canyon", "Buburimu Peninsula", "Meriphataud Mountains", "Sauromugue Champaign", "The Sanctuary of Zi'Tah", "Ro'Maeve", "Yuhtunga Jungle", "Yhoator Jungle", "Western Altepa Desert", "Eastern Altepa Desert", "Qufim Island", "Behemoth's Dominion", "Ru'Aun Gardens", "Pashhow Marshlands" },
    zoneIds = { 100, 101, 102, 103, 104, 105, 111, 106, 107, 108, 110, 112, 113, 128, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 114, 126, 127, 130, 109 },
    note = "A blank magical scroll mounted near regional field manual locations. Binding your training orders to the parchment engages elite automated operations parameters or validates combat tracking.",
},

-- needs review
["Guide Stone"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Upper Jeuno", "Lower Jeuno", "Port Jeuno" },
    zoneIds = { 244, 245, 246 },
    note = "A polished stone directory pillar positioned within municipal plazas. Examining its engraved surfaces updates your city exploration data or tracks regional orientation tasks.",
},

["Harvesting Point"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Attohwa Chasm", "Wajaom Woodlands", "Bhaflau Thickets", "Leujaoam Sanctum", "Grauberg [S]", "West Sarutabaruta [S]", "West Sarutabaruta", "Yuhtunga Jungle", "Yhoator Jungle", "Ghoyu's Reverie", "Giddeus", "Abyssea - Grauberg", "Yahse Hunting Grounds", "Ceizak Battlegrounds", "Foret de Hennetiel", "Yorcia Weald", "Sih Gates" },
    zoneIds = { 7, 51, 52, 69, 89, 95, 115, 123, 124, 129, 145, 254, 260, 261, 262, 263, 268 },
    note = "A thick cluster of native overworld botanical flora. Foraging through the greenery uncovers rare crafting items, gathers regional resources, and completes active gathering trials.",
},

["Legion Portal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Maquette Abdhaljs-Legion A", "Maquette Abdhaljs-Legion B" },
    zoneIds = { 183, 287 },
    note = "An elite spatial transport gateway bridging the staging chamber to the battlefield layers. Stepping onto the floating platform warps your entire alliance directly into Legion matches.",
},

["Lined Casket"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Altepa" },
    zoneIds = { 15, 218 },
    note = "A heavy, reinforced treasure box manifested deep inside the Abyssean void. Breaking open the locking mechanics provides emergency provisioning items, gear components, or temporary buffs.",
},

["Matrimonial Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Chateau d'Oraguille", "Metalworks", "Heavens Tower" },
    zoneIds = { 233, 237, 242 },
    note = "An ornate, locked ceremonial chest placed within prominent national audience chambers. Opening the coffer uncovers long-lost historical logs or reviews festive holiday scenarios.",
},

-- needs review
["Mawl'gofaur"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sauromugue Champaign [S]", "Metalworks", "Ru'Lude Gardens" },
    zoneIds = { 98, 237, 243 },
    note = "A distinct natural ground landmark or unique ancient monument. Examining it updates advanced storyline milestones or validates your tracking journals across high-tier content.",
},

-- needs review
["Peculiar Footprints"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Newton Movalpolos", "Wajaom Woodlands", "Arrapago Reef", "Mount Zhayolm", "Aydeewa Subterrane", "Caedarva Mire", "Batallia Downs", "Beaucedine Glacier", "Xarcabard", "Western Altepa Desert", "Qufim Island", "Palborough Mines", "Rala Waterways", "Kamihr Drifts", "Reisenjima" },
    zoneIds = { 12, 51, 54, 61, 68, 79, 105, 111, 112, 125, 126, 143, 258, 267, 291 },
    note = "Faint, mysterious tracking grooves pressed into the dungeon mud or overworld soil layers. Studying the unusual marks uncovers hidden investigative records to advance active side quests.",
},

-- needs review
["Point 1"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 93, 129 },
    note = "A designated structural checkpoint layout node found inside instance maps. Inspecting the marker verifies specialized collection tasks or tracks completion metrics during a run.",
},

-- needs review
["Point 2"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 93, 129 },
    note = "A secondary structural checkpoint layout node monitoring instance progress fields. Interfacing with its parameters triggers structural room variations or validates current voucher data.",
},

-- needs review
["Point 3"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines", "Ghoyu's Reverie" },
    zoneIds = { 93, 129 },
    note = "The final localized structural checkpoint marker anchoring the intermediate trial sectors. Finalizing the marker unrolls specific completion requirements for your active squad.",
},

-- needs review
["Rendezvous Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Promyvion - Dem", "Promyvion - Holla", "Promyvion - Mea", "Aht Urhgan Whitegate", "Northern San d'Oria", "Port Bastok", "Windurst Waters", "Ru'Lude Gardens" },
    zoneIds = { 16, 18, 20, 50, 231, 236, 238, 243 },
    note = "A designated strategic staging waypoint manifest within city districts or deep inside the void loops. Resting at this point handles mission registration checks or uncovers regional lore archives.",
},

-- needs review
["Resume Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sealion's Den", "Empyreal Paradox", "Aht Urhgan Whitegate", "Arrapago Reef", "Batallia Downs", "Xarcabard [S]", "Yughott Grotto", "Castle Oztroja", "Ru'Lude Gardens", "Ceizak Battlegrounds", "Kamihr Drifts", "Cirdas Caverns", "Ra'Kaznar Turris", "Reisenjima" },
    zoneIds = { 32, 36, 50, 54, 105, 137, 142, 151, 243, 261, 267, 270, 277, 291 },
    note = "A localized temporal checkpoint node hovering at key battle paths. Interfacing with the core validates your key item progress parameters to resume interrupted storyline battlefields.",
},

["Riftworn Pyxis"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Bibiki Bay", "Uleguerand Range", "Attohwa Chasm", "Lufaise Meadows", "Misareaux Coast", "Arrapago Reef", "Mount Zhayolm", "Mamook", "Aydeewa Subterrane", "Caedarva Mire", "East Ronfaure [S]", "Jugner Forest [S]", "Vunkerl Inlet [S]", "Batallia Downs [S]", "North Gustaberg [S]", "Grauberg [S]", "Pashhow Marshlands [S]", "Rolanberry Fields [S]", "West Sarutabaruta [S]", "Fort Karugo-Narugo [S]", "Meriphataud Mountains [S]", "Sauromugue Champaign [S]", "West Ronfaure", "East Ronfaure", "La Theine Plateau", "Valkurm Dunes", "Jugner Forest", "Batallia Downs", "North Gustaberg", "South Gustaberg", "Konschtat Highlands", "Pashhow Marshlands", "Rolanberry Fields", "Beaucedine Glacier", "Xarcabard", "Cape Teriggan", "West Sarutabaruta", "East Sarutabaruta", "Tahrongi Canyon", "Buburimu Peninsula", "Meriphataud Mountains", "Sauromugue Champaign", "The Sanctuary of Zi'Tah", "Ro'Maeve", "Yuhtunga Jungle", "Western Altepa Desert", "Qufim Island", "Behemoth's Dominion", "Ru'Aun Gardens", "The Boyahda Tree", "Temple of Uggalepih", "Garlaige Citadel [S]", "Crawlers' Nest [S]", "Kuftal Tunnel", "The Eldieme Necropolis [S]", "The Shrine of Ru'Avitau", "Ve'Lugannon Palace", "Lower Delkfutt's Tower", "King Ranperre's Tomb", "Gusgen Mines", "Ordelle's Caves", "Outer Horutoto Ruins", "The Eldieme Necropolis", "Maze of Shakhrami", "Garlaige Citadel", "Ifrit's Cauldron", "Quicksand Caves" },
    zoneIds = { 4, 5, 7, 24, 25, 54, 61, 65, 68, 79, 81, 82, 83, 84, 88, 89, 90, 91, 95, 96, 97, 98, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 115, 116, 117, 118, 119, 120, 121, 122, 123, 125, 126, 127, 130, 153, 159, 164, 171, 174, 175, 177, 178, 184, 190, 191, 193, 194, 195, 196, 197, 198, 200, 205, 208 },
    note = "A locked extraplanar drop chest container materializing immediately post-combat across Voidwatch fields. Breaking its lock rewards your squad with combat currencies or temporary buffs.",
},

["Shattered Telepoint"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Jugner Forest [S]", "Pashhow Marshlands [S]", "Meriphataud Mountains [S]", "La Theine Plateau", "Konschtat Highlands", "Xarcabard", "Eastern Altepa Desert", "Tahrongi Canyon", "Yhoator Jungle" },
    zoneIds = { 82, 90, 97, 102, 108, 112, 114, 117, 124 },
    note = "The cracked remains of an ancient floating teleportation gate tracking regional coordinates. Touching the stone pillars uncovers faded spatial archives and updates dimensional travel paths.",
},

["Switch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Sacrarium", "Lebros Cavern", "Everbloom Hollow", "Den of Rancor", "Inner Horutoto Ruins", "Outer Horutoto Ruins" },
    zoneIds = { 28, 63, 86, 160, 192, 194 },
    note = "A heavy mechanical toggling mechanism inset nearby security walls. Moving the device handles layout verification states or flips remote winches to open gated passages.",
},

["Telepoint"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Jugner Forest [S]", "Pashhow Marshlands [S]", "Meriphataud Mountains [S]", "La Theine Plateau", "Konschtat Highlands", "Xarcabard", "Eastern Altepa Desert", "Tahrongi Canyon", "Yhoator Jungle" },
    zoneIds = { 82, 90, 97, 102, 108, 112, 114, 117, 124 },
    note = "A massive floating crystalline gate tracking regional overworld coordinates. Touching the spire uncovers ancient layout records and links your destination path to the global teleportation grid.",
},

["Terminal Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Balga's Dais", "Horlais Peak", "Waughroon Shrine" },
    zoneIds = { 139, 144, 146 },
    note = "The primary prize repository appearing upon completing intense battlefield arena trials. Opening the reinforced chest distributes unique gear pieces and allocations of gil to your participating squad.",
},

-- needs review
["Torch Stand"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Oztroja [S]", "Castle Oztroja" },
    zoneIds = { 99, 151 },
    note = "A heavy iron wall bracket supporting a bright ancient flame inside the beastman stronghold. Interfacing with the sconce uncovers hidden structural records or verifies advanced quest checkpoints.",
},

["Veridical Conflux #00"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl" },
    zoneIds = { 215, 216, 217 },
    note = "The foundational spatial fast-travel node pulsing with extraplanar energy. Tuning into its frequency links you to the regional transport grid, granting an instant leap across Abyssean sectors.",
},

["Veridical Conflux #01"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The first designated warp monument anchoring the intermediate trial sectors. Stepping onto the floating lattice matrix allows you to slip effortlessly through spatial layout barriers.",
},

["Veridical Conflux #02"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The secondary localized travel waypoint resting in the advanced level tiers. Channeling its magical currents teleports your adventuring party instantly across the active landscape.",
},

["Veridical Conflux #03"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The third localized travel waypoint anchored near elite battle grounds. Synchronizing your spiritual parameters with the platform warps you instantly through the shifting sectors.",
},

["Veridical Conflux #04"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The fourth fast-travel energy gateway humming along the perimeter pathways. Interfacing with this ancient system node triggers a rapid slipstream to deliver you to targeted exploration zones.",
},

["Veridical Conflux #05"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The fifth specialized fast-travel crystalline core floating inside the dangerous hunting zones. Tapping into its ancient world-warp grid teleports your group directly away from surrounding hazards.",
},

["Veridical Conflux #06"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The sixth strategic travel waypoint anchoring high-level battle loops. Linking your destination keys here lets you navigate through advanced areas without walking through enemy territory.",
},

["Veridical Conflux #07"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The seventh high-tier crystalline travel waypoint unsealed inside the fractured landscape. Activating the floating lattice matrix allows you to slip effortlessly across the zone layouts.",
},

["Veridical Conflux #08"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Abyssea - Konschtat", "Abyssea - Tahrongi", "Abyssea - La Theine", "Walk of Echoes", "Abyssea - Attohwa", "Abyssea - Misareaux", "Abyssea - Vunkerl", "Abyssea - Altepa", "Abyssea - Uleguerand", "Abyssea - Grauberg" },
    zoneIds = { 15, 45, 132, 182, 215, 216, 217, 218, 253, 254 },
    note = "The eighth specialized travel waypoint resting in the advanced instance tiers. Aligning your group parameters with its crystalline grid opens the gateway to launch elite finale battlefields.",
},

["Veridical Conflux #1"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "An ancient technological warp hub pulsing within the past-timeline fractured timeline loops. Interfacing with its console opens a slipstream to teleport your squad instantly between wings.",
},

["Veridical Conflux #10"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes", "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 182, 279, 298 },
    note = "The tenth specialized travel rift waypoint resting in the advanced instance tiers. Synchronizing your destination keys here lets you navigate through higher floor sectors safely.",
},

["Veridical Conflux #11"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes", "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 182, 279, 298 },
    note = "The eleventh specialized travel rift waypoint anchoring high-level battle loops. Tapping into its ancient world-warp grid teleports your adventuring party safely across the fractured instance layouts.",
},

["Veridical Conflux #12"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes", "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 182, 279, 298 },
    note = "The twelfth crystalline travel monument unsealed at the end of the temporal loops. Aligning your group parameters with its crystalline grid opens the gateway to launch elite finale battlefields.",
},

["Veridical Conflux #2"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The second designated warp hub within the past-timeline research layers. Activating its light lattice matrix shifts your entire alliance across layout walls into advanced challenge rooms.",
},

["Veridical Conflux #3"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The third localized warp hub within the past-timeline research layers. Activating its light lattice matrix shifts your entire alliance across layout walls into advanced challenge rooms.",
},

["Veridical Conflux #4"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The fourth fast-travel energy gateway humming along the perimeter pathways. Interfacing with this ancient system node triggers a rapid slipstream to deliver you to targeted exploration zones.",
},

["Veridical Conflux #5"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The fifth specialized fast-travel crystalline core floating inside the dangerous hunting zones. Tapping into its ancient world-warp grid teleports your group directly away from surrounding hazards.",
},

["Veridical Conflux #6"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The sixth strategic travel waypoint anchoring high-level battle loops. Linking your destination keys here lets you navigate through advanced areas without walking through enemy territory.",
},

["Veridical Conflux #7"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The seventh high-tier crystalline travel waypoint unsealed inside the fractured landscape. Activating the floating lattice matrix allows you to slip effortlessly across the zone layouts.",
},

["Veridical Conflux #8"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The eighth specialized travel waypoint resting in the advanced instance tiers. Aligning your group parameters with its crystalline grid opens the gateway to launch elite finale battlefields.",
},

["Veridical Conflux #9"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes [P1]", "Walk of Echoes [P2]" },
    zoneIds = { 279, 298 },
    note = "The ninth specialized travel rift waypoint anchoring high-level battle loops. Tapping into its ancient world-warp grid teleports your adventuring party safely across the fractured instance layouts.",
},

-------------------------------------------------------------------------------
-- Abyssea - Attohwa
-------------------------------------------------------------------------------
["Supply Point"] = {
    type = "Loot Container",
    icon = "Crate.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "A localized inventory and provisions checkpoint manifest in the Abyssean wasteland. Inspecting its layout coordinates regional stock retrievals or processes tactical supply enhancements.",
},

-------------------------------------------------------------------------------
-- Abyssea - Uleguerand
-------------------------------------------------------------------------------
["Coal Casket"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A heavy iron-reinforced storage trunk exposed within the freezing mountain depths of Abyssea. Prying open its lid uncovers premium fuel supplies, crafting materials, or hidden temporal resources.",
},

["Fabric Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A weathered textile repository materializing within the sub-zero alpine wastes. Breaking past its lock rewards your squad with premium tailoring components and specialized upgrade items.",
},

-- needs review
["Impact Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A distinct natural ground indentation scarred by localized temporal static. Investigating the disturbed permafrost resolves Abyssean spatial puzzles and maps out your active exploration logs.",
},

["Lumber Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Abyssea - Uleguerand" },
    zoneIds = { 253 },
    note = "A reinforced wooden storage chest left abandoned inside the glacial valleys. Cracking the seal unrolls rare woodworking resources, raw timber components, or regional battlefield rewards.",
},

-------------------------------------------------------------------------------
-- Aht Urhgan Whitegate
-------------------------------------------------------------------------------
["Door: Automaton Workshop"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A sturdy wooden service door leading directly into the imperial puppet maintenance bay. Activating the latch allows you to step inside to repair your automaton components or progress specialized job trials.",
},

["Door: Chamber of Passage"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A secure portal partitioning the tactical transit hall. Passing past the framework manages your movement between corporate agency hubs or checks your mercenary clearance levels.",
},

["Door: Commissions Agency"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "The heavy entrance portal blockading the imperial currency exchange office. Throwing back the wood frame grants you access to check active vouchers or handle regional assault trade listings.",
},

["Door: Kokba Hostel"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A basic residential wooden door set into the bustling commercial district architecture. Interfacing with the handle uncovers localized mercenary tracking clues or triggers neighborhood flavor lines.",
},

["Door: Walahra Temple"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "An ornate wooden barrier protecting the sacred sanctuary chambers. Stepping through the threshold lets you offer imperial coins to secure ancient enhancements and clear magical trials.",
},

["Door_1ea"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A specific structural door partition separating regional city blocks. Passing through the frame manages urban layout navigation loops or transitions you into surrounding town squares.",
},

["Door_1eb"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "The secondary localized security gate embedded into the plaster city walls. Turning the handle commands the wooden framework to slide aside to help you bypass busy street paths.",
},

["Door_1ec"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "The third specific door barrier protecting a residential residential layout block. Shifting the latch updates your city exploration files or updates active urban side tasks.",
},

["Door_1ed"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "The fourth specific defensive barrier fortifying the city alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Gate: The Colosseum"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Aht Urhgan Whitegate" },
    zoneIds = { 50 },
    note = "A heavy iron-grilled security barrier fence section crossing into the arena grounds. Satisfying stadium registration checks drops the frame to allow entry into competitive match sectors.",
},

-------------------------------------------------------------------------------
-- Apollyon
-------------------------------------------------------------------------------
["Apollyon Coffer #1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Apollyon" },
    zoneIds = { 38 },
    note = "The primary floor tier prize box materializing post-combat within the instance. Cracking its lock rewards your alliance squad with ancient currency slips and unique gear upgrade items.",
},

["Apollyon Coffer #2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Apollyon" },
    zoneIds = { 38 },
    note = "The secondary designated reward chest spawned upon clearing localized target parameters. Prying open its locked frame awards your squad pristine armor fragments and shard resources.",
},

["Apollyon Coffer #3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Apollyon" },
    zoneIds = { 38 },
    note = "The third tactical treasure box stationed deep inside the challenge layers. Satisfying localized instance goals distributes rare artifact upgrade materials and crucial temporal rewards.",
},

["Apollyon Coffer #4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Apollyon" },
    zoneIds = { 38 },
    note = "The final milestone container dropped onto the stone floor tiers after a floor clear. Accessing its interface claims premium armor templates and ultimate loot components for your whole squad.",
},

-- needs review
["Apollyon Furnace"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Apollyon" },
    zoneIds = { 38 },
    note = "A glowing technological terminal podium manifest inside the instance layers. Interfacing with its volatile energy core compiles your team's tactical achievements or activates localized map exit mechanics.",
},

-------------------------------------------------------------------------------
-- Arrapago Reef
-------------------------------------------------------------------------------
-- needs review
["Apkallu Guide"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A localized spatial navigation marker deeply tied to regional avian tracking loops. Examining the node uncovers coastline archives or logs critical milestones for your active seafaring side quests.",
},

["door_1i0"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "A specific heavy wooden barrier door separating wet coastal grottos. Overriding its physical layout locking mechanisms slides the panel away to grant deeper reef access.",
},

["door_1i1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "The secondary localized security gate embedded into the damp stone reef corridors. Finding and utilizing a specialized skeleton passkey releases the heavy framework to open your path.",
},

-------------------------------------------------------------------------------
-- Aydeewa Subterrane
-------------------------------------------------------------------------------
-- needs review
["Final Survey Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Aydeewa Subterrane" },
    zoneIds = { 68 },
    note = "The ultimate geological tracking checkpoint hidden deep inside the bioluminescent underground caves. Investigating this unique site records your master pioneer records to complete advanced mapping lines.",
},

-- needs review
["Survey Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Aydeewa Subterrane" },
    zoneIds = { 68 },
    note = "A distinct archaeological checking waypoint nesting along the subterranean cavern floors. Studying the mineral patterns validates active mapping parameters or updates active exploration logs.",
},

-------------------------------------------------------------------------------
-- Bastok Markets
-------------------------------------------------------------------------------
["Door:\"Dragon's Claws\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "The heavy timber entrance portal leading into the local commercial shop layout. Turning the iron door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:Brunhilde Armourer"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "A basic wooden barrier door partitioning the artisan smithing merchant shop. Shifting the latch gives you access to browse equipment sets or progress commercial delivery checks.",
},

["Door:Carmelide's Jewelry"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "A refined shopfront portal protecting a jewelry boutique inside the trade district. Pulling the handle updates urban exploration files or updates active civic tasks.",
},

["Door:Harmodios's Music"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "The standard wood door frame partitioning the local music merchant rooms. Interfacing with the latch uncovers neighborhood tracking clues or triggers localized background flavor cutscenes.",
},

["Door:Mjoll's Goods"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "A basic wooden door hinged to the municipal trade stall layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Door:Sororo the Scribe"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Markets" },
    zoneIds = { 235 },
    note = "A simple residential door framework leading straight into the records office. Passing the frame tracks advanced Republic milestones or triggers urban scenario dialogues.",
},

-------------------------------------------------------------------------------
-- Bastok Mines
-------------------------------------------------------------------------------
["Door:\"Bat's Lair\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Mines" },
    zoneIds = { 234 },
    note = "The heavy timber entrance portal partitioning the deep mining tavern. Activating the handle manages your movement through the mining district layout or logs local story lines.",
},

["Door:Alchemists' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Mines" },
    zoneIds = { 234 },
    note = "A secure portal archway partitioning off the industrial chemical laboratories. Operating the handle opens up advanced crafting synthesis areas and checks active guild progression parameters.",
},

["Door:Boytz's Knickknacks"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Mines" },
    zoneIds = { 234 },
    note = "A basic merchant door set into the dark mining district tunnels. Unlatching the framework lets you slide quietly into the specialty retail vaults to fulfill delivery checks.",
},

["Door:Deegis's Armour"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bastok Mines" },
    zoneIds = { 234 },
    note = "A secure shopfront portal separating the armory showroom from the main streets. Verifying your transaction records commands the heavy wooden frame to open.",
},

-------------------------------------------------------------------------------
-- Beaucedine Glacier
-------------------------------------------------------------------------------
-- needs review
["Point of Interest"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier" },
    zoneIds = { 111 },
    note = "A localized geographic landmark or frozen overworld checkpoint. Investigating the snow-covered site uncovers forgotten records, triggers historic lore text, or advances regional side tasks.",
},

-------------------------------------------------------------------------------
-- Beaucedine Glacier [S]
-------------------------------------------------------------------------------
-- needs review
["Colossal Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Beaucedine Glacier [S]" },
    zoneIds = { 136 },
    note = "A massive tracking indentation pressed deeply into the past-timeline permafrost. Studying the gargantuan imprint reveals the movement of ancient beastman military forces or updates active campaign logs.",
},

-------------------------------------------------------------------------------
-- Bhaflau Thickets
-------------------------------------------------------------------------------
["Door_1g3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bhaflau Thickets" },
    zoneIds = { 52 },
    note = "A reinforced wooden service door blocking passage through imperial wilderness outposts. Overriding the mechanical layout locks slides the heavy panel away to clear your route through the thicket loops.",
},

["Door_1g4"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Bhaflau Thickets" },
    zoneIds = { 52 },
    note = "The secondary specific defensive barrier partition sealing off secure frontier paths. Finding and utilizing a specialized key item releases the heavy locking framework to let you pass.",
},

-------------------------------------------------------------------------------
-- Bibiki Bay
-------------------------------------------------------------------------------
["Logging Point"] = {
    type = "Logging Point",
    icon = "LoggingPoint.png",
    zones = { "Bibiki Bay" },
    zoneIds = { 4 },
    worldOffsetY = 1.2,
    note = "A mature timber outcropping rich with harvestable materials along the coastal delta. Applying an equipped logging hatchet extracts rare wood chunks, sap components, and regional synthesis ingredients.",
},

-------------------------------------------------------------------------------
-- Caedarva Mire
-------------------------------------------------------------------------------
["Door_276"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "The first heavy iron-reinforced barrier door partitioning wet marshland grottos and swamp tombs. Procuring the matching regional token unlatches the door framework so your squad can pass.",
},

["Door_277"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "The second designated security partition manifest along the dangerous swamp routes. Satisfying localized area conditions commands the heavy iron-reinforced framework to slide open.",
},

["Door_278"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "The third heavy gate structure fortifying the subterranean mire ruins. Clearing the surrounding baseline combat trials triggers the remote winches to swing the panel aside.",
},

["Door_279"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Caedarva Mire" },
    zoneIds = { 79 },
    note = "The final structural locking boundary sealing the inner marshland sanctuary chambers. Meeting direct area requirements unseals the entryway, allowing your squad to advance into deeper sectors.",
},

-------------------------------------------------------------------------------
-- Castle Zvahl Baileys
-------------------------------------------------------------------------------
-- needs review
["Switchstix"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Zvahl Baileys" },
    zoneIds = { 161 },
    note = "A hidden mechanical node or key structural contraption inside the dark fortress outskirts. Manipulating the mechanism handles tactical gate configurations or updates your active side quests.",
},

-- needs review
["Torch"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Castle Zvahl Baileys" },
    zoneIds = { 161 },
    note = "An unlit iron wall bracket fixed within the dark stronghold corridors. Igniting the wick satisfies active storyline missions, updates quest flags, or slides back secret doors.",
},

-------------------------------------------------------------------------------
-- Castle Zvahl Keep
-------------------------------------------------------------------------------
["Valhallan Rift"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Castle Zvahl Keep" },
    zoneIds = { 162 },
    note = "A swirling dimensional rift tearing through the dark throne corridors. Stepping directly into the spatial void verifies your battle credentials to launch high-tier master battlefield instances.",
},

-------------------------------------------------------------------------------
-- Celennia Memorial Library
-------------------------------------------------------------------------------
["Door: Back to Town"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Celennia Memorial Library" },
    zoneIds = { 284 },
    note = "The main exit archway threshold built into the archive facility. Passing through the heavy framework leaves the library behind to transition you directly back into the public city districts.",
},

-------------------------------------------------------------------------------
-- Chateau d'Oraguille
-------------------------------------------------------------------------------
["Door:Great Hall"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chateau d'Oraguille" },
    zoneIds = { 233 },
    note = "The massive ornate portal archway partitioning off the main state hall. Turning the heavy latch manages your royal audience navigation and uncovers Kingdom background records.",
},

["Door:Prince Regent's Rm"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chateau d'Oraguille" },
    zoneIds = { 233 },
    note = "A secure wooden barrier portal protecting the executive chambers of the Prince Regent. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Prince Royal's Rm"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chateau d'Oraguille" },
    zoneIds = { 233 },
    note = "A secure, iron-reinforced wooden door partitioning off the Prince Royal's chambers. Verifying your royal clearance commands the ornate framework to open.",
},

["Door:Royal Knight Qtrs"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chateau d'Oraguille" },
    zoneIds = { 233 },
    note = "A heavy timber door sealing off the private barracks of the Royal Knights. Operating the handle opens up the military compound area to fulfill active side quest delivery checks.",
},

["Door:Temple Knight Qtrs"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Chateau d'Oraguille" },
    zoneIds = { 233 },
    note = "A fortified wooden partition protecting the Temple Knights' quarters. Activating the handle opens up advanced tactical yards and checks active national storyline progression.",
},

-------------------------------------------------------------------------------
-- Davoi
-------------------------------------------------------------------------------
-- needs review
["!"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Davoi" },
    zoneIds = { 149 },
    note = "A striking, conspicuous exclamation checkpoint hidden deep within the Orc encampment. Searching this anomalous structural waypoint uncovers stolen military gear or validates active tracking requirements.",
},

-------------------------------------------------------------------------------
-- Eastern Adoulin
-------------------------------------------------------------------------------
["Door:"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Eastern Adoulin" },
    zoneIds = { 257 },
    note = "A basic residential door frame set into the city stonework layouts. Unlatching the frame allows you to enter municipal quarters to fulfill urban side tasks or check localized logs.",
},

["Door: Boarding House"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Eastern Adoulin" },
    zoneIds = { 257 },
    note = "A standard shopfront portal dividing the civic street layouts from the local lodging rooms. Shifting the latch moves you off public paths to enter residential travel layers.",
},

["Door:Research Chamber"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Eastern Adoulin" },
    zoneIds = { 257 },
    note = "A secure entrance framework partitioning off advanced pioneer research laboratories. Verifying your current challenge credentials commands the heavy wood frame to part.",
},

-------------------------------------------------------------------------------
-- Escha - Ru'Aun
-------------------------------------------------------------------------------
["Eschan Portal #10"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The tenth crystalline fast-travel waypoint floating in the higher tier rings of the realm. Tuning into its frequency links you to the regional transport grid, granting an instant leap across active map nodes.",
},

["Eschan Portal #11"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The eleventh specialized travel rift waypoint anchoring high-level hunting zones. Stepping onto its base taps into the ancient world-warp grid to deliver your party directly into the middle sectors.",
},

["Eschan Portal #12"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The twelfth crystalline travel monument pulsing with extraplanar energy. Activating the floating lattice matrix allows you to slip effortlessly through spatial layout barriers to arrive at targeted exploration points.",
},

["Eschan Portal #13"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The thirteenth fast-travel energy gateway humming along the celestial perimeter pathways. Synchronizing your spiritual path with this floating rock bridges regional sector lines to warp you instantly across the landscape.",
},

["Eschan Portal #14"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The fourteenth specialized fast-travel crystalline core floating deep inside the dangerous sky zones. Interfacing with this layout node provides an instant dimensional leap away from surrounding hazards.",
},

["Eschan Portal #15"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The fifteenth strategic travel waypoint resting in the advanced level tiers. Channeling its magical currents manipulates extraplanar networks to transport your adventuring party safely across the celestial island layouts.",
},

["Eschan Portal #9"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Escha - Ru'Aun" },
    zoneIds = { 289 },
    note = "The ninth crystalline fast-travel nexus anchoring the intermediate reaches of the realm. Activating the floating lattice matrix allows you to cross the sky zone instantly, connecting you directly to challenging perimeter territory.",
},

-------------------------------------------------------------------------------
-- Fei'Yin
-------------------------------------------------------------------------------
-- needs review
["Dry Fountain"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Fei'Yin" },
    zoneIds = { 204 },
    note = "A weathered, stone water structure pooling with ancient dust instead of water. Searching the dried basin uncovers forgotten historical relics or triggers critical visions within the frozen ruins.",
},

-------------------------------------------------------------------------------
-- Garlaige Citadel
-------------------------------------------------------------------------------
["Door Lock#1"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The first specialized wall console anchoring the citadel security network. Operating this terminal coordinates with allied nodes to lift corresponding heavy metal blocking gates across the tunnels.",
},

["Door Lock#2"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The secondary security locking mechanism fixed within the subterranean military layout. Activating its internal mechanisms slides remote gates open to let your squad advance into deeper corridors.",
},

["Door Lock#3"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The third specific security locking bracket mounted to the citadel stone framing. Toggling this handle shifts mechanical weights to lower heavy iron portcullis barriers.",
},

["Door Lock#4"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The fourth specific security mechanism built into the ancient fortress layers. Overriding its restrictive circuitry drops the final partition to grant access to restricted vaults.",
},

["Switch#1"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The primary floor pressure plate or wall switch operating the citadel layout. Standing on the stone slabs engages remote pulley wires, sliding open massive banishing gate partitions.",
},

["Switch#2"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The secondary floor switch plate mechanism hidden near the tunnel intersections. Stepping onto or activating this mechanism slides remote gears to flip heavy security partitions across multiple floors.",
},

["Switch#3"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The third localized mechanical switch monitoring dungeon sectors. Moving the device handles layout verification states or flips remote winches to open gated passages.",
},

["Switch#4"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Garlaige Citadel" },
    zoneIds = { 200 },
    note = "The final localized structural switch panel anchoring the intermediate trial sectors. Finalizing this marker unblocks restrictive blast gates to expand your subterranean exploration paths.",
},

-------------------------------------------------------------------------------
-- Ghoyu's Reverie
-------------------------------------------------------------------------------
-- needs review
["Point 10"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The tenth localized structural checkpoint marker anchoring the advanced instance layouts. Inspecting the marker verifies specialized collection tasks or tracks completion metrics during a run.",
},

-- needs review
["Point 4"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The fourth structural checkpoint layout node monitoring instance progress fields. Interfacing with its parameters triggers structural room variations or validates current voucher data.",
},

-- needs review
["Point 5"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The fifth specialized structural checkpoint marker hidden inside the instance maps. Inspecting the marker verifies specialized collection tasks or tracks completion metrics during a run.",
},

-- needs review
["Point 6"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The sixth strategic structural checkpoint layout node monitoring instance progress fields. Interfacing with its parameters triggers structural room variations or validates current voucher data.",
},

-- needs review
["Point 7"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The seventh high-tier structural checkpoint marker anchoring the intermediate trial sectors. Finalizing the marker unrolls specific completion requirements for your active squad.",
},

-- needs review
["Point 8"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The eighth specialized structural checkpoint layout node found inside instance maps. Inspecting the marker verifies specialized collection tasks or tracks completion metrics during a run.",
},

-- needs review
["Point 9"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "The ninth specialized structural checkpoint marker anchoring the intermediate trial sectors. Finalizing the marker unrolls specific completion requirements for your active squad.",
},

["Survival Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Ghoyu's Reverie" },
    zoneIds = { 129 },
    note = "A reinforced treasure chest materializing after a successful maze clear. Cracking the lock distributes unique gear pieces, weapon matrices, and allocations of experience to your participating squad.",
},

-------------------------------------------------------------------------------
-- Giddeus
-------------------------------------------------------------------------------
["Worn Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Giddeus" },
    zoneIds = { 145 },
    note = "A weathered, moss-grown treasure box forgotten within the damp beastman tunnels. Prying open the splintered timber lid uncovers localized supplies, currency caches, or hidden regional materials.",
},

-------------------------------------------------------------------------------
-- GM Home
-------------------------------------------------------------------------------
-- needs review
["MD_POINT"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "GM Home" },
    zoneIds = { 210 },
    note = "An absolute layout development data coordinate tracking node injected inside the developer map layer. Interfacing with the core validates diagnostic scripts or checks server alignment parameters.",
},

-------------------------------------------------------------------------------
-- Grand Palace of Hu'Xzoi
-------------------------------------------------------------------------------
["Gate of the Gods"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Grand Palace of Hu'Xzoi" },
    zoneIds = { 34 },
    note = "A massive ancient portal archway blockading the crystalline celestial palace layers. Overriding its foreign circuitry shuts down the security field boundaries to allow your squad passage.",
},

-------------------------------------------------------------------------------
-- Gusgen Mines
-------------------------------------------------------------------------------
["Lever"] = {
    type = "Dungeon Switch",
    icon = "Lever.png",
    zones = { "Gusgen Mines" },
    zoneIds = { 196 },
    note = "A heavy iron floor handle fixed along the haunted mining tracks. Throwing your weight against the lever engages old pulley networks to shift track coordinates and open layout pathways.",
},

-------------------------------------------------------------------------------
-- Hall of Transference
-------------------------------------------------------------------------------
["Large Apparatus"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Hall of Transference" },
    zoneIds = { 14 },
    note = "A colossal ancient technological machine humming with dimensional warp energies. Channeling your alliance parameters into the console triggers a rapid slipstream to teleport you directly into the crags of Promyvion.",
},

-------------------------------------------------------------------------------
-- Halvung
-------------------------------------------------------------------------------
-- needs review
["Light Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Halvung" },
    zoneIds = { 62 },
    note = "A localized pocket of luminous atmospheric energy shimmering along the boiling volcanic pathways. Inspecting the glowing anomaly uncovers rare minerals or advances advanced continental side quests.",
},

-------------------------------------------------------------------------------
-- Heavens Tower
-------------------------------------------------------------------------------
["Door:Starway Stairway"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Heavens Tower" },
    zoneIds = { 242 },
    note = "An elegant wooden security partition guarding the spiral ascent of the temple tower. Passing past the framework coordinates your vertical movement through the executive administrative layers.",
},

["Door:Vestal Chamber"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Heavens Tower" },
    zoneIds = { 242 },
    note = "An ornate stone security barrier sealing off the high sanctuary of the Star Sybil. Verifying your current national mission clearance commands the intricate frame to part.",
},

-------------------------------------------------------------------------------
-- Inner Horutoto Ruins
-------------------------------------------------------------------------------
-- needs review
["Black Circle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A localized structural sigil floor pattern embedded into the ancient ruins. Standing upon its dark perimeter checks your magical parameter alignments or coordinates hidden Federation mission milestones.",
},

-- needs review
["Center Circle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "The focal ancient seal platform anchoring the subterranean laboratory chambers. Stepping into the central focal node validates specialized magic trials or updates active country side quest parameters.",
},

["Gate of Earth"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A massive elemental stone security portal blocking the subterranean ruin corridors. Presenting the matching regional tablet unlatches the masonry frame so your party can pass.",
},

["Gate of Fire"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A heavy architectural barrier gate sealed with intense volcanic runes. Overriding the heat-warped security grid commands the stone framework to slide open.",
},

["Gate of Ice"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A frost-rimed stone partition blockading deep structural vault layouts. Finding and utilizing a specialized key item releases the heavy locking framework to let you pass.",
},

["Gate of Light"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "An elegant, glowing magical energy gateway sealing executive rooms. Satisfying structural defense coordinates commands the intricate portal panels to part.",
},

["Gate of Thunder"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A fortified stone gateway pulsing with a subtle storm frequency deep within the ruins. Clearing the surrounding baseline combat trials triggers the remote winches to swing the panel aside.",
},

["Gate of Water"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A monolithic slab of ancient masonry barring the flooded subterranean aqueduct channels. Overriding the nearby locking mechanism slides the heavy panel away to grant exploration passage.",
},

["Gate of Wind"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A heavy ancient stone structural barrier gate channeled by whistling drafts. Meeting direct area requirements unseals the entryway, allowing your squad to advance into deeper sectors.",
},

-- needs review
["Red Circle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A crimson ancient geometric engraving etched directly into the chamber stone. Inspecting its unique runic geometries aligns your parameters to unlock advanced side tasks.",
},

["Sealed Portal"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A massive, ancient masonry slab locked tight by glowing historical seals. Disrupting the magical feedback unseals the heavy framework, allowing you to pass into hidden chambers.",
},

-- needs review
["White Circle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Inner Horutoto Ruins" },
    zoneIds = { 192 },
    note = "A polished, luminous stone floor sigil situated within the damp ruins. Pausing along its perimeter registers your magic metrics and advances advanced Federation storyline phases.",
},

-------------------------------------------------------------------------------
-- Jugner Forest [S]
-------------------------------------------------------------------------------
-- needs review
["Elegant Footprints"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Jugner Forest [S]" },
    zoneIds = { 82 },
    note = "A set of faint, sophisticated tracking prints pressed into the past-timeline wilderness sod. Studying the tracks uncovers hidden investigative records to advance your frontline campaigns.",
},

-- needs review
["Riftborer Verokgok"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Jugner Forest [S]" },
    zoneIds = { 82 },
    note = "A bizarre atmospheric anomaly node or unique structural checking point manifest in the deep woods. Examining the core tracks your military campaign milestones and updates active side stories.",
},

-------------------------------------------------------------------------------
-- Kazham
-------------------------------------------------------------------------------
["Door:Celodehki's B&B"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A sturdy wooden entrance portal leading into the local lodging house. Turning the heavy latch coordinates your town navigation and uncovers neighborhood background records.",
},

["Door:Mihgo's Res."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A basic residential wooden door partitioning off private chieftain quarters. Interfacing with the handle uncovers localized tribal tracking clues or advances advanced expansion side quests.",
},

["Door:Pakhroib's Res."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A standard timber door set into the thatched village architecture layouts. Unlatching the frame allows you to enter resident quarters to fulfill delivery checks or urban side tasks.",
},

["Door:Posbei's Gear"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A basic wooden barrier door partitioning the outfitter shop layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Door:Ryuhkowa's Merch."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A simple merchant door framework leading straight into the trading post. Shifting the latch gives you access to browse equipment sets or progress commercial delivery checks.",
},

["Door:Wahcondalo's Res."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A basic residential door frame set into the village timber layouts. Passing the frame tracks advanced jungle milestones or triggers localized scenario dialogues.",
},

["Door_7"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "A specific structural door barrier protecting restricted interior rooms. Passing past the framework manages municipal layout navigation scripts or updates active storyline progression phases.",
},

["Door_8"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "The secondary localized security gate embedded into the jungle village walls. Turning the handle commands the wooden framework to slide aside to help you bypass busy street paths.",
},

["Door_a"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "The third specific door barrier protecting a residential residential layout block. Shifting the latch updates your city exploration files or updates active urban side tasks.",
},

["Door_b"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "The fourth specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_c"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kazham" },
    zoneIds = { 250 },
    note = "The fifth specialized gate barrier partition anchoring the intermediate loops of the outpost. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

-------------------------------------------------------------------------------
-- Kuftal Tunnel
-------------------------------------------------------------------------------
["Door_Rock"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Kuftal Tunnel" },
    zoneIds = { 174 },
    note = "A massive architectural slab of ancient stone masonry barring deep subterranean cavern corridors. Solving localized puzzle conditions commands the heavy rock framework to slide open.",
},

-------------------------------------------------------------------------------
-- Leafallia
-------------------------------------------------------------------------------
-- needs review
["Drifting Feather"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Leafallia" },
    zoneIds = { 281 },
    note = "A shimmering, mystical down feather floating weightlessly in the quiet sanctuary air. Reaching out to touch the anomaly uncovers sacred forest lore strings or updates active expansion story lines.",
},

-- needs review
["Heroic Footprints"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Leafallia" },
    zoneIds = { 281 },
    note = "A set of prominent, glowing tracking indentations pressed cleanly into the sanctuary grass floors. Studying the tracks uncovers hidden legendary records to advance late-tier pioneer missions.",
},

-------------------------------------------------------------------------------
-- Lower Jeuno
-------------------------------------------------------------------------------
["Beastiary Book"] = {
    type = "Monster log",
    icon = "Book.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    worldOffsetY = 0.60,
    note = "A thick archived volume resting on a display pedestal. Browsing through the biological text sheets reveals extensive monster data logs, tracking records, and evolutionary charts.",
},

["Door:\"Goblins' Goblet\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "The heavy timber entrance portal leading into the local Goblin-run tavern. Turning the door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:\"Merry Minstrel\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A standard wood door frame partitioning the local tavern and performance rooms. Interfacing with the latch uncovers neighborhood tracking clues or triggers localized background flavor cutscenes.",
},

["Door:\"Neptune's Spire\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "The massive wood entryway leading straight into the local corporate inn layout. Stepping through the framework manages city navigation scripts or updates active storyline progression phases.",
},

["Door:Aldo's Room"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A secure private wooden door set into the back of the merchant headquarters. Unlatching the framework tracks advanced national milestones or triggers critical expansion cutscenes.",
},

["Door:Chamber of Commerce"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A grand portal archway guarding the municipal trading house and administrative halls. Presenting commerce credentials or city clearance triggers the heavy frame to open.",
},

["Door:Gems by Kshama"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "An elegant wooden partition protecting the fine gemstone boutique. Unlatching the door frame provides entry to check active synthetic craft trials or browse regional inventory maps.",
},

["Door:Merchant's House"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A basic residential wooden door set into the city stonework layouts. Unlatching the frame allows you to enter merchant quarters to fulfill commercial delivery checks or urban side tasks.",
},

["Door:Muckvix's Junk Shop"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A basic wooden barrier door partitioning the specialty retail junk shop. Shifting the latch gives you access to search through old materials or progress early-tier tracking tasks.",
},

["Door:Othon's Garments"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A simple merchant door framework leading straight into the textile retail shop. Shifting the latch gives you access to browse apparel sets or progress commercial delivery checks.",
},

["Door:Tenshodo H.Q."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A heavily reinforced wooden door partitioning off the secret outlaw network headquarters. Sliding back the viewing slit uncovers covert operation records or checks active black market progression parameters.",
},

["Door:Waag-Deeg's Magic"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Lower Jeuno" },
    zoneIds = { 245 },
    note = "A dusty academic door frame set into the arcane retail shop. Pulling the handle uncovers rare research logs or validates active magical quest milestones.",
},

-------------------------------------------------------------------------------
-- Mamook
-------------------------------------------------------------------------------
-- needs review
["Toad's Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Mamook" },
    zoneIds = { 65 },
    note = "A faint amphibian tracking mark embedded into the mud of the beastman stronghold. Studying the unique track logs advanced exploration data and updates your active investigative journals.",
},

-------------------------------------------------------------------------------
-- Metalworks
-------------------------------------------------------------------------------
["Door:Aide's Office"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A basic wooden door frame set into the administrative palace corridors. Unlatching the frame allows you to enter office spaces to check military records or fulfill rank mission milestones.",
},

["Door:Cannonry"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A heavy iron-banded door sealing off the garrison artillery testing yards. Operating the handle opens up advanced weapons areas and checks active defense progression parameters.",
},

["Door:Cermet Refinery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A secure portal archway partitioning off the industrial metal processing chambers. Verifying your industrial clearance commands the heavy stone framework to part.",
},

["Door:Conference Room"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A standard wooden partition protecting the military strategy chambers. Shifting the latch moves you off public corridors to enter executive meeting layers.",
},

["Door:Cornelia's Room"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A secure private wooden door leading into the grand workshop living quarters. Unlatching the framework tracks advanced Republic milestones or triggers critical scenario dialogues.",
},

["Door:Craftsmen's Eatery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A simple merchant door framework leading straight into the foundry dining quarters. Shifting the latch gives you access to browse culinary recipes or progress commercial delivery checks.",
},

["Door:Darksteel Forge"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A heavy iron door frame set into the heavy industrial forge yards. Pulling the handle uncovers advanced smithing logs or validates active fabrication quest milestones.",
},

["Door:Dept. of Industry"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A grand portal archway guarding the main industrial ministry and design halls. Presenting development credentials or department clearance triggers the heavy frame to open.",
},

["Door:Gunpowder Room"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "A heavily reinforced wooden door partitioning off the high-security munitions vaults. Sliding back the frame uncovers explosive recipe charts or validates active tactical survey parameters.",
},

["Door:President's Office"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "An elegant, massive portal archway guarding the supreme executive office chambers. Presenting presidential clearance or high-ranking mission credentials triggers the frame to open.",
},

["Door:Presidential Suite"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Metalworks" },
    zoneIds = { 237 },
    note = "An ornate stone security barrier sealing off the executive palace guest rooms. Verifying your high-ranking diplomatic clearance commands the intricate frame to part.",
},

-------------------------------------------------------------------------------
-- Mhaura
-------------------------------------------------------------------------------
["Door:\"Sailors' Stay\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mhaura" },
    zoneIds = { 249 },
    note = "The heavy timber entrance portal leading into the port town inn. Turning the iron door handle coordinates your city navigation and uncovers local background records.",
},

["Door:Governor's House"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mhaura" },
    zoneIds = { 249 },
    note = "A secure portal archway partitioning off the local administrative office chambers. Passing through the threshold tracks municipal missions and handles localized storyline developments.",
},

["Door:Orlando's Antiques"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mhaura" },
    zoneIds = { 249 },
    note = "A basic wooden barrier door partitioning the antique retail shop. Shifting the latch gives you access to search for rare antiquities or progress commercial delivery checks.",
},

-------------------------------------------------------------------------------
-- Moh Gates
-------------------------------------------------------------------------------
["Molten Rift"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Moh Gates" },
    zoneIds = { 269 },
    note = "A searing, swirling volcanic dimensional rift fracturing the subterranean stone walls. Gathering your alliance before the crack verifies your group parameters to launch high-tier battle skirmishes.",
},

-------------------------------------------------------------------------------
-- Mount Zhayolm
-------------------------------------------------------------------------------
["Door_1p4"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A secure wooden service door blocking passage through volcanic mountain outposts. Overriding its restrictive locking parameters drops the panel to grant deeper access.",
},

["Gates of Halvung"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A monolithic slab of ancient volcanic stone masonry barring the entrance to the beastman stronghold. Solving localized puzzle conditions commands the heavy framework to part to clear your exploration path.",
},

-------------------------------------------------------------------------------
-- Nashmau
-------------------------------------------------------------------------------
["Door_1h0"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Nashmau" },
    zoneIds = { 53 },
    note = "A standard wooden barrier door partitioning the regional settlement layout blocks. Unlatching the frame allows you to enter city sectors to fulfill delivery checks or urban side tasks.",
},

["Door_1h1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Nashmau" },
    zoneIds = { 53 },
    note = "The secondary localized security gate embedded into the plaster city walls. Turning the handle commands the wooden framework to slide aside to help you bypass busy street paths.",
},

-------------------------------------------------------------------------------
-- Newton Movalpolos
-------------------------------------------------------------------------------
["door_00"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The first specific structural door barrier protecting restricted interior layout blocks of the Moblin city. Bypassing the security latch commands the framework to open.",
},

["door_01"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The second designated security partition manifest along the industrial tunnel pathways. Satisfying localized area parameters commands the heavy wooden framework to slide open.",
},

["door_02"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The third localized gate structure guarding the shifting trial rooms. Overcoming the local security trials releases the locking framework to let you pass.",
},

["door_03"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The fourth specific defensive barrier fortifying the deep industrial corridors. Throwing your weight against the nearby triggers engages the pully systems to lift the frame.",
},

["door_04"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The fifth specialized gate barrier partition anchoring the intermediate loops of the complex. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

["door_05"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The sixth strategic security partition blockading the deep Moblin stronghold. Activating remote lever pulley systems commands the heavy frame to open.",
},

["door_06"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The seventh specific door barrier protecting a residential layout block. Shifting the latch updates your city exploration files or updates active urban side tasks.",
},

["door_07"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The eighth specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["door_08"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The final structural locking boundary sealing the inner courtyard chambers. Overcoming the elite sector guardians triggers the winches, opening the path ahead.",
},

["door_09"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "A reinforced iron-banded door sealing off advanced manufacturing sectors of the Moblin city. Shifting the latch moves you off travel paths to enter specialized workspace layers.",
},

["door_10"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "A compact mechanical sliding door built into the industrial tunnels. Turning the heavy handle coordinates your city navigation and uncovers underground background records.",
},

["door_11"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The final specific defensive barrier fortifying the deep industrial corridors. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Furnace Hatch"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Newton Movalpolos" },
    zoneIds = { 12 },
    note = "The heavy mechanical top hatch of the underground furnace machinery. Opening this lid lets you drop harvested raw materials straight into the burner systems to process core story assignments.",
},

-------------------------------------------------------------------------------
-- Norg
-------------------------------------------------------------------------------
["Door_2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Norg" },
    zoneIds = { 252 },
    note = "A basic residential wooden door partitioning the outlaw cavern hub rooms. Activating the threshold latch manages your movement through the pirate settlement or initiates deep storyline scenarios.",
},

-------------------------------------------------------------------------------
-- Northern San d'Oria
-------------------------------------------------------------------------------
-- needs review
["Chat Manual"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Northern San d'Oria" },
    note = "A basic reference guidebook resting openly in city squares. Examining the pages details municipal communications history or fulfills early-tier tracking tasks for novice adventurers.",
},

["Door. Chantry"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "A secure portal archway partitioning off the cathedral sanctuary rooms. Presenting your religious credentials or national mission tokens commands the heavy frame to part.",
},

["Door:\"Phoenix Perch\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    zoneIds = { 231 },
    note = "The heavy timber entrance portal leading into the local commercial tavern. Turning the iron door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:Bastokan Consul"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "A secure portal archway partitioning off the foreign diplomatic embassy offices. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Carpenters' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    zoneIds = { 231 },
    note = "A standard wooden partition protecting artisan woodworking crafting halls. Activating the handle opens up advanced synthetic craft yards and checks active guild progression parameters.",
},

["Door:Jeunoan Consul"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "A secure embassy entrance framework partitioning off the grand duchy diplomatic chambers. Verifying your current national mission clearance commands the ornate frame to open.",
},

["Door:Justi's Furniture"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    zoneIds = { 231 },
    note = "A basic wooden barrier door partitioning the specialty furniture retail shop. Shifting the latch gives you access to search through old materials or progress early-tier tracking tasks.",
},

["Door:Manuscript Room"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "A secure wooden barrier portal protecting the archive repository. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Papal Chambers"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "An ornate stone security barrier sealing off the high sanctuary offices. Verifying your high-ranking diplomatic clearance commands the intricate frame to part.",
},

["Door:Reliquary"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    note = "An ornate, fortified sanctuary gate sealing away sacred reliquaries. Presenting rare cardinal key items unblocks the pathway corridors, allowing your squad to advance into late-tier level layouts.",
},

["Door:Royal Armoury"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Northern San d'Oria" },
    zoneIds = { 231 },
    note = "A heavily reinforced wooden door partitioning off the high-security weapons vaults. Sliding back the frame uncovers armor recipe charts or validates active tactical survey parameters.",
},

["Odyssean Passage"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Northern San d'Oria" },
    note = "A shimmering dimensional rift warping the city pathways. Stepping directly into the spatial void verifies your battle credentials to transition your alliance between advanced endgame instances.",
},

-------------------------------------------------------------------------------
-- Outer Ra'Kaznar
-------------------------------------------------------------------------------
-- needs review
["Meeting Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Outer Ra'Kaznar" },
    zoneIds = { 274 },
    note = "A distinct natural ground landmark or unique ancient monument inside the underworld. Examining it updates advanced storyline milestones or validates your tracking journals across high-tier content.",
},

-------------------------------------------------------------------------------
-- Periqia
-------------------------------------------------------------------------------
["Door_1k1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The first specific structural door barrier protecting restricted interior layout blocks of the seafaring staging grounds. Bypassing the security latch commands the framework to open.",
},

["Door_1k2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The second designated security partition manifest along the industrial tunnel pathways of the instance. Satisfying localized area parameters commands the heavy wooden framework to slide open.",
},

["Door_1k3"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The third localized gate structure guarding the shifting trial rooms. Overcoming the local security trials releases the locking framework to let your party pass.",
},

["Door_1k4"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The fourth specific defensive barrier fortifying the deep industrial corridors. Throwing your weight against the nearby triggers engages the pully systems to lift the frame.",
},

["Door_1k5"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The fifth specialized gate barrier partition anchoring the intermediate loops of the complex. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

["Door_1k6"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The sixth strategic security partition blockading the deep staging area. Activating remote lever pulley systems commands the heavy frame to open.",
},

["Door_1k7"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The seventh specific door barrier protecting an isolated residential layout block. Shifting the latch updates your instance exploration files or checks active tactical tasks.",
},

["Door_1k8"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The eighth specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_1k9"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The ninth specialized gate partition anchoring intermediate loops of the active run. Overcoming elite sector guardians triggers the winches, opening the path ahead.",
},

["Door_1ka"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A reinforced iron-banded door sealing off advanced operation sectors of the naval staging grounds. Shifting the latch moves you off travel paths to enter specialized workspace layers.",
},

["Door_1kb"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A compact mechanical sliding door built into the industrial tunnels. Turning the heavy handle coordinates your map navigation and uncovers underground background records.",
},

["Door_1kc"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The twelfth designated security partition manifest across the trial chambers of the instance. Verifying your current challenge clearance commands the heavy wood frame to part.",
},

["Door_1kd"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The thirteenth specific door barrier protecting a residential layout block. Finding and utilizing a specialized key item releases the heavy framework to let you pass.",
},

["Door_1ke"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The fourteenth specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_1kf"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The fifteenth specialized gate barrier partition anchoring the intermediate loops of the active run. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

["Door_1kg"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The sixteenth strategic security partition blockading the deep staging area. Activating remote lever pulley systems commands the heavy frame to open.",
},

["Door_1kh"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The seventeenth specific door barrier protecting an isolated residential layout block. Shifting the latch updates your instance exploration files or checks active tactical tasks.",
},

["Door_1ki"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The eighteenth specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_1kj"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The nineteenth specialized gate partition anchoring intermediate loops of the active run. Overcoming elite sector guardians triggers the winches, opening the path ahead.",
},

["Door_1kk"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A reinforced iron-banded door sealing off advanced operation sectors of the naval staging grounds. Shifting the latch moves you off travel paths to enter specialized workspace layers.",
},

["Door_1kl"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A compact mechanical sliding door built into the industrial tunnels. Turning the heavy handle coordinates your map navigation and uncovers underground background records.",
},

["Door_1km"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A reinforced iron-banded door sealing off advanced operation sectors of the naval staging grounds. Shifting the latch moves you off travel paths to enter specialized workspace layers.",
},

["Door_1kn"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A compact mechanical sliding door built into the industrial tunnels. Turning the heavy handle coordinates your map navigation and uncovers underground background records.",
},

["Door_1ko"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The designated security partition manifest across the trial chambers of the instance. Verifying your current challenge clearance commands the heavy wood frame to part.",
},

["Door_1kp"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specific door barrier protecting a residential layout block. Finding and utilizing a specialized key item releases the heavy framework to let your party pass.",
},

["Door_1kq"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_1kr"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specialized gate barrier partition anchoring the intermediate loops of the active run. Satisfying direct area conditions triggers the door mechanics to swing the panel aside.",
},

["Door_1ks"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The strategic security partition blockading the deep staging area. Activating remote lever pulley systems commands the heavy frame to open.",
},

["Door_1kt"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specific door barrier protecting an isolated residential layout block. Shifting the latch updates your instance exploration files or checks active tactical tasks.",
},

["Door_1ku"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specific defensive barrier fortifying the outpost alley partitions. Unlatching the door frame provides entry to search for hidden quest items or advance active story arcs.",
},

["Door_1kv"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "The specialized gate partition anchoring intermediate loops of the active run. Overcoming elite sector guardians triggers the winches, opening the path ahead.",
},

["Door_1kw"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Periqia" },
    zoneIds = { 56 },
    note = "A reinforced iron-banded door sealing off advanced operation sectors of the naval staging grounds. Shifting the latch moves you off travel paths to enter specialized workspace layers.",
},

-------------------------------------------------------------------------------
-- Phomiuna Aqueducts
-------------------------------------------------------------------------------
["Door_0rc"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "A heavy, moisture-beaded security portal partition blockading the damp subterranean sewer channels. Bypassing the locking latch commands the stone framework to slide open.",
},

["Door_0rd"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "The secondary localized stone barrier blocking deep aqueduct corridors. Turning the remote valve gears overrides the locking framework to let your party pass.",
},

["Door_0rk"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "A sturdy stone gate structure protecting ancient vaulted laboratories. Coordinating with your team to trip nearby switch weights unlatches the door frame so you can advance.",
},

["Door_0rl"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Phomiuna Aqueducts" },
    zoneIds = { 27 },
    note = "The final structural barrier door sealing off restricted sewer chambers. Presenting specialized library or key item credentials commands the heavy stonework panel away.",
},

-------------------------------------------------------------------------------
-- Port Bastok
-------------------------------------------------------------------------------
["Door:\"Steaming Sheep\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Bastok" },
    zoneIds = { 236 },
    note = "The heavy timber entrance portal leading into the local port tavern. Turning the iron door handle coordinates your town navigation and uncovers neighborhood background records.",
},

["Door:Galvin's Gear"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Bastok" },
    zoneIds = { 236 },
    note = "A basic wooden barrier door partitioning the outfitter shop layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Door:Warehouse 1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Bastok" },
    zoneIds = { 236 },
    note = "A fortified wooden door framework partitioning off high-security harbor warehouses. Presenting commercial shipping manifests commands the frame to swing open.",
},

["Door:Warehouse 2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Bastok" },
    zoneIds = { 236 },
    note = "The companion storage room gateway threshold exiting the harbor lanes. Shifting the latch lets you enter supply vaults to check delivery parameters or retrieve quest items.",
},

-------------------------------------------------------------------------------
-- Port Jeuno
-------------------------------------------------------------------------------
["Door:Jeuno Duty-Free"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Jeuno" },
    zoneIds = { 246 },
    note = "An elegant shopfront portal dividing the port paths from the high-end retail counters. Interfacing with the latch coordinates your city movement or uncovers municipal background records.",
},

["Shami's Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Port Jeuno" },
    zoneIds = { 246 },
    note = "A sturdy wooden coffer resting near the veteran seal collector. Opening this container handles your inventory balances or lets you track and organize custom currency items.",
},

["Shami's Coffer"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Port Jeuno" },
    zoneIds = { 246 },
    note = "A heavy iron-banded prize repository positioned on the port docks. Interfacing with its secure framing processes rare trophy exchanges, seals conversions, or advanced token claims.",
},

-------------------------------------------------------------------------------
-- Port San d'Oria
-------------------------------------------------------------------------------
["Door:\"Rusty Anchor\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria" },
    zoneIds = { 232 },
    note = "The heavy timber entrance portal leading into the bustling harbor tavern. Turning the iron door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:Cargo Room A"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria" },
    zoneIds = { 232 },
    note = "A fortified wooden door framework partitioning off secure harbor warehouses. Presenting commercial shipping manifests commands the frame to swing open for trade checks.",
},

["Door:Cargo Room B"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria" },
    zoneIds = { 232 },
    note = "The companion storage room gateway threshold exiting the harbor lanes. Shifting the latch lets you enter supply vaults to check delivery parameters or retrieve quest items.",
},

["Door:Regine's Magicmart"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port San d'Oria" },
    zoneIds = { 232 },
    note = "A dusty academic door frame set into the arcane retail shop. Pulling the handle uncovers rare research logs or validates active magical quest milestones.",
},

-------------------------------------------------------------------------------
-- Port Windurst
-------------------------------------------------------------------------------
["Door:Doctor's Residence"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Windurst" },
    zoneIds = { 240 },
    note = "A basic residential wooden door set into the city stonework layouts. Unlatching the frame allows you to enter medical quarters to fulfill clinic delivery checks or urban side tasks.",
},

["Door:Orastery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Port Windurst" },
    zoneIds = { 240 },
    note = "The heavy wooden entry barrier leading to the magical astronomical research towers. Pulling the handle uncovers rare library records or validates active Federation quest milestones.",
},

-------------------------------------------------------------------------------
-- Qufim Island
-------------------------------------------------------------------------------
-- needs review
["Giant Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Qufim Island" },
    zoneIds = { 126 },
    note = "A massive tracking indentation pressed deeply into the frozen coastal crags. Studying the oversized imprint uncovers unique geological footprints or validates active regional hunt records.",
},

-------------------------------------------------------------------------------
-- Quicksand Caves
-------------------------------------------------------------------------------
-- needs review
["Fountain of Kings"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Quicksand Caves" },
    zoneIds = { 208 },
    note = "An ancient stone font tucked away inside the shifting desert ruins. Peer down into the architectural water basin to validate progressive milestone keys or process rare item infusions.",
},

-------------------------------------------------------------------------------
-- Rala Waterways
-------------------------------------------------------------------------------
-- needs review
["Tomato Vantage Point"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A unique structural viewpoint structure within the damp city aqueduct arches. Pausing at this platform railing registers your pioneer geographic metrics and updates active side tasks.",
},

-------------------------------------------------------------------------------
-- Ru'Lude Gardens
-------------------------------------------------------------------------------
["Door:Archduke's House"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A secure embassy entrance framework partitioning off the grand grand duchy executive palace halls. Verifying your high-ranking mission credentials triggers the frame to open.",
},

["Door:Bastokan Emb."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A secure portal archway partitioning off the foreign Republic diplomatic embassy offices. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Bedchamber"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "An elegant wooden security partition guarding the inner private chambers. Passing past the framework coordinates your vertical movement through the executive palace layers.",
},

["Door:Dining Hall"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A standard wooden partition protecting the palatial dining hall layers. Shifting the latch moves you off public corridors to enter executive meeting layers.",
},

["Door:Guard Post"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A basic wooden door frame set into the high-security palace corridors. Unlatching the frame allows you to enter office spaces to check military records or fulfill rank mission milestones.",
},

["Door:Living Quarters"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A secure private wooden door leading into the palace living layouts. Unlatching the framework tracks advanced milestones or triggers critical scenario dialogues.",
},

["Door:San d'Orian Emb."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A secure portal archway partitioning off the foreign Kingdom diplomatic embassy offices. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Windurstian Emb."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A secure embassy entrance framework partitioning off Federation diplomatic chambers. Verifying your current national mission clearance commands the ornate frame to open.",
},

["Splintery Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Ru'Lude Gardens" },
    zoneIds = { 243 },
    note = "A rough wooden storage container resting within the palace upper tiers. Prying open its splintered timber lid uncovers localized supplies, holiday rewards, or hidden event materials.",
},

-------------------------------------------------------------------------------
-- Ruhotz Silvermines
-------------------------------------------------------------------------------
["Irksome Chest"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A reinforced treasure box materializing after an instance combat trial. Cracking the lock distributes unique gear pieces and allocations of experience to your participating squad.",
},

["Ladder of Passage"] = {
    type = "Dungeon Switch",
    icon = "Ladder.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A sturdy structural wooden ladder built into the instance shafts. Scaling its rungs bypasses blocked pathways to clear vertical layer layouts and solve maze collection tasks within your active run.",
},

-- needs review
["Lamp of Compassion"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "An unlit lighting pillar apparatus hidden within the mine layout corridors. Interfacing with the terminal bracket handles maze system logs or triggers localized background flavor cutscenes.",
},

-- needs review
["Point1"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A designated structural checkpoint layout node found inside instance maps. Inspecting the marker verifies specialized collection tasks or tracks completion metrics during a run.",
},

-- needs review
["Point2"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A secondary structural checkpoint layout node monitoring instance progress fields. Interfacing with its parameters triggers structural room variations or validates current voucher data.",
},

-- needs review
["Point3"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "The third localized structural checkpoint marker anchoring the intermediate trial sectors. Finalizing the marker unrolls specific completion requirements for your active squad.",
},

["Switchlox"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A hidden mechanical node or unique structural contraption inside the maze paths. Manipulating the mechanism handles tactical gate configurations or updates your active side tasks.",
},

-- needs review
["Well of Charity"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A historic stone water well mechanism integrated into the silver mine shafts. Inspecting the framework alters maze layout configurations and assists you in solving localized collection assignments during instance runs.",
},

-- needs review
["Well of Humility"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A secondary stone well apparatus tracking instance progress metrics. Searching down the dark masonry shaft uncovers tracking clues and fulfills milestone requirements for active trials.",
},

-- needs review
["Well of Passage"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "A specialized structural well monitoring destination pathways across the maze layout. Interfacing with its parameters triggers structural room variations or validates current voucher data.",
},

-- needs review
["Well of Vigilance"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ruhotz Silvermines" },
    zoneIds = { 93 },
    note = "The final stone well mechanism anchoring the intermediate trial sectors. Finalizing this marker unblocks restrictive barriers to expand your subterranean instance exploration paths.",
},

-------------------------------------------------------------------------------
-- Selbina
-------------------------------------------------------------------------------
["Door:Fishermen's Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Selbina" },
    zoneIds = { 248 },
    note = "The heavy timber entrance portal leading into the port town maritime guild hall. Turning the door handle coordinates your city navigation and uncovers local crafting records.",
},

["Door:Mayor's Residence"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Selbina" },
    zoneIds = { 248 },
    note = "A secure portal archway partitioning off the local administrative mayoral estate. Passing through the threshold tracks municipal missions and handles localized storyline developments.",
},

["Door:Shepherd's Muster"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Selbina" },
    zoneIds = { 248 },
    note = "A standard wooden barrier door partitioning the local seaside tavern. Shifting the latch gives you access to search for hidden tracking clues or progress urban delivery checks.",
},

-------------------------------------------------------------------------------
-- Southern San d'Oria
-------------------------------------------------------------------------------
-- needs review
["???"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria" },
    worldOffsetY = 0.20,
    note = "An anonymous, hidden overworld waypoint node hidden among the city alleys. Examining it checks dynamic progress flags or validates secret quest retrieval tasks.",
},

-- needs review
["Crystal Crunch"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria" },
    worldOffsetY = 0.60,
    note = "A localized municipal crystal exchange mechanism pedestal. Interfacing with its matrix ledger reviews server trade balances and processes elemental clusters.",
},

["Door:Count's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "An elegant, massive portal archway guarding the high-ranking noble estate chambers. Presenting proper aristocratic credentials or mission clearances commands the intricate framework to part.",
},

["Door:Helbort's Blades"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A simple merchant door framework leading straight into the weapon retail shop. Shifting the latch gives you access to browse armament sets or progress commercial delivery checks.",
},

["Door:House"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A basic residential wooden door set into the city stonework layouts. Unlatching the frame allows you to enter citizen quarters to fulfill delivery parameters or urban side tasks.",
},

["Door:Raimbroy's Grocery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A standard shopfront portal dividing the civic street layouts from the food retail room. Shifting the latch moves you off public paths to browse raw cooking synthesis ingredients.",
},

["Door:Rosel's Armour"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A basic wooden barrier door partitioning the defensive apparel retail shop. Shifting the latch gives you access to check active armor trade manifests or advance urban side tasks.",
},

["Door:Tanners' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A heavy iron-banded door sealing off leathercraft processing yards. Operating the handle opens up advanced crafting synthesis areas and checks active guild progression parameters.",
},

["Door:Taumila's Sundries"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria" },
    note = "A basic wooden door frame set into the general mercantile trade layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Enigmatic Footprints #1"] = {
    type = "Memory Recall",
    icon = "Cutscene.png",
    zones = { "Southern San d'Oria" },
    worldOffsetY = 0.0,
    note = "A distinct trace indentation pressed cleanly into the city pavement stonework. Interfacing with the footprint reviews historical campaign logs or replays localized story cutscenes.",
},

-- needs review
["Mystic Retriever"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria" },
    worldOffsetY = 0.50,
    note = "A runic mechanism podium console managing campaign operations metrics. Interfacing with the terminal processes high-tier reward alignments or purges unwanted operation logs.",
},

-- needs review
["Well"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Southern San d'Oria" },
    worldOffsetY = 0.0,
    note = "A historic stone water well mechanism integrated into the municipal plaza. Searching down the dark masonry shaft uncovers tracking clues or fulfills milestone requirements for side tasks.",
},

-------------------------------------------------------------------------------
-- Southern San d'Oria [S]
-------------------------------------------------------------------------------
["Door Lion\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Southern San d'Oria [S]" },
    zoneIds = { 80 },
    note = "The heavy timber entrance portal leading into the local past-timeline tavern. Turning the door handle coordinates your frontline city navigation and uncovers warfront logs.",
},

-------------------------------------------------------------------------------
-- Temenos
-------------------------------------------------------------------------------
["Temenos Coffer #1"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "The primary floor tier prize box materializing post-combat within the Limbus instance. Cracking its lock rewards your alliance squad with ancient currency slips and unique gear upgrade items.",
},

["Temenos Coffer #2"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "The secondary designated reward chest spawned upon clearing localized target parameters. Prying open its locked frame awards your squad pristine armor fragments and shard resources.",
},

["Temenos Coffer #3"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "The third tactical treasure box stationed deep inside the challenge layers. Satisfying localized instance goals distributes rare artifact upgrade materials and crucial temporal rewards.",
},

["Temenos Coffer #4"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "The final milestone container dropped onto the stone floor tiers after a floor clear. Accessing its interface claims premium armor templates and ultimate loot components for your whole squad.",
},

-- needs review
["Temenos Furnace"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Temenos" },
    zoneIds = { 37 },
    note = "A glowing technological terminal podium manifest inside the instance layers. Interfacing with its volatile energy core compiles your team's tactical achievements or activates localized map exit mechanics.",
},

-------------------------------------------------------------------------------
-- Temple of Uggalepih
-------------------------------------------------------------------------------
["Old Casket"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Temple of Uggalepih" },
    zoneIds = { 159 },
    note = "A weathered treasure chest half-buried along the ancient temple pathways. Breaking past the lock reveals localized items, currency caches, or hidden regional materials required for artifact trials.",
},

-------------------------------------------------------------------------------
-- The Ashu Talif
-------------------------------------------------------------------------------
["Door: Cargo Hold"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Ashu Talif" },
    zoneIds = { 60 },
    note = "The heavy timber portal barrier locking off the lower storage hold of the imperial ghost ship. Forcing the latch open grants your party access into restricted subterranean ship compartments during pirate raid battlefields.",
},

["Door: Great Cabin"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Ashu Talif" },
    zoneIds = { 60 },
    note = "An elegant, iron-strapped wooden barrier sealing off the main captain quarters. Turning the door handle coordinates your battlefield navigation and triggers critical expansion story event cutscenes.",
},

["Gate: Lifeboat"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "The Ashu Talif" },
    zoneIds = { 60 },
    note = "A structural perimeter barrier gate rigged to the side ship decks. Interfacing with its mechanics unseals the escape slipstream, allowing your squad to deport safely from high-tier instanced battles.",
},

-------------------------------------------------------------------------------
-- The Shrouded Maw
-------------------------------------------------------------------------------
-- needs review
["Memento Circle"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "The Shrouded Maw" },
    zoneIds = { 10 },
    note = "A localized ancient sigil floor pattern embedded into the dark battlefield platform grounds. Stepping into its runic boundary matrix evaluates your group milestones to trigger profound storyline visions.",
},

-------------------------------------------------------------------------------
-- Uleguerand Range
-------------------------------------------------------------------------------
-- needs review
["Rabbit Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Uleguerand Range" },
    zoneIds = { 5 },
    note = "A faint animal tracking mark embedded heavily into the alpine snow drifts. Studying the soft paw scores coordinates specialized tracking loops and claims crucial side quest items.",
},

-------------------------------------------------------------------------------
-- Upper Jeuno
-------------------------------------------------------------------------------
["Door:\"Durable Shields\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno" },
    zoneIds = { 244 },
    note = "A basic wooden barrier door partitioning the protective apparel retail shop layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Door:\"Marble Bridge\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno" },
    zoneIds = { 244 },
    note = "The heavy timber entrance portal leading into the local commercial tavern. Turning the iron door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:Goddess Temple"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno" },
    zoneIds = { 244 },
    note = "An ornate wooden barrier protecting the high cathedral chambers. Stepping through the grand threshold lets you offer municipal records to secure unique enhancements or clear national rank missions.",
},

["Door:Infirmary"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno" },
    zoneIds = { 244 },
    note = "A basic residential wooden door set into the clinic walls. Unlatching the frame allows you to enter medical quarters to fulfill emergency clinic delivery checks or urban side tasks.",
},

["Door:Viette's Weapons"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Upper Jeuno" },
    zoneIds = { 244 },
    note = "A simple merchant door framework leading straight into the weapon retail shop. Shifting the latch gives you access to browse armament sets or progress commercial delivery checks.",
},

-------------------------------------------------------------------------------
-- Wajaom Woodlands
-------------------------------------------------------------------------------
-- needs review
["Leypoint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Wajaom Woodlands" },
    zoneIds = { 51 },
    note = "A pulsing, extraplanar environmental energy anomaly outcropping from the dense jungle roots. Tuning into its frequency coordinates pioneer geographic records or unseals formidable regional adversaries.",
},

-------------------------------------------------------------------------------
-- Walk of Echoes
-------------------------------------------------------------------------------
["Veridical Conflux #09"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "The ninth specialized travel rift waypoint anchoring high-level battle loops. Tapping into its ancient world-warp grid teleports your adventuring party safely across the fractured instance layouts.",
},

["Veridical Conflux #13"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "The thirteenth fast-travel energy gateway humming along the perimeter pathways. Synchronizing your spiritual path with this matrix bridges regional sector lines to warp you instantly across the landscape.",
},

["Veridical Conflux #14"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "The fourteenth specialized fast-travel crystalline core floating deep inside the dangerous sky zones. Interfacing with this layout node provides an instant dimensional leap away from surrounding hazards.",
},

["Veridical Conflux #15"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Walk of Echoes" },
    zoneIds = { 182 },
    note = "The fifteenth strategic travel waypoint resting in the advanced level tiers. Channeling its magical currents manipulates extraplanar networks to transport your adventuring party safely across the instance layouts.",
},

-------------------------------------------------------------------------------
-- Western Adoulin
-------------------------------------------------------------------------------
["Door: Amchuchu's Laboratory"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    note = "The heavy workshop door frame leading straight into the inventor lab. Interfacing with the latch uncovers pioneering research files or triggers extensive Adoulin side quest lines.",
},

["Door: Depository"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A secure storage portal partition blockading the city archive facility vaults. Verifying your pioneer clearance tokens unblocks the framework to let you retrieve quest items.",
},

["Door: Svenja's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "An elegant, massive portal archway guarding the high noble estate chambers. Presenting proper aristocratic credentials unseals the ward, letting you cross to launch localized side campaigns.",
},

["Door:Hospital"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "A standard wooden barrier door partitioning the port city clinic layout blocks. Unlatching the frame allows you to enter medical quarters to fulfill advanced pioneer side tasks.",
},

["Door:Svenja's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "The secondary specific duplicate portal framework guarding the high noble estate grounds. Shifting the latch moves you off public paths to launch targeted local side campaigns.",
},

-------------------------------------------------------------------------------
-- Windurst Walls
-------------------------------------------------------------------------------
["Door:House of the Hero"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A secure stone portal archway sealing off the legendary historical landmark dwelling. Passing through the threshold tracks advanced national rank missions and handles localized storyline developments.",
},

["Door:Koru-Moru's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "An ornate wooden barrier door partitioning the private estate of the Ministry of Oral History. Activating the threshold latch manages your town navigation and uncovers advanced expansion side quests.",
},

["Door:Shantotto's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A heavily reinforced wooden portal guarding the notorious manor chambers of the Ministry of Magic. Verifying your high-ranking mission credentials triggers the frame to open.",
},

["Door:Yoran-Oran's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A secure private wooden door set into the plaster residential walls. Unlatching the frame allows you to enter research quarters to fulfill academy delivery checks or urban side tasks.",
},

["Door:Zonpa-Zippa's Manor"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A standard wooden partition protecting artisan magical engineering halls. Activating the handle opens up advanced synthetic craft yards and checks active guild progression parameters.",
},

["Door_5"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A specific structural door barrier protecting a residential residential layout block. Shifting the latch updates your city exploration files or updates active urban side tasks.",
},

-- needs review
["Horuni-Mawoni"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Windurst Walls" },
    zoneIds = { 239 },
    note = "A distinct natural ground landmark or unique ancient monument inside the residential district. Examining it updates advanced storyline milestones or validates your tracking journals.",
},

-------------------------------------------------------------------------------
-- Windurst Waters
-------------------------------------------------------------------------------
["Door:\"Rarab Tail\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "The heavy timber entrance portal leading into the local port tavern. Turning the iron door handle coordinates your city navigation and uncovers neighborhood background records.",
},

["Door:\"Timbre Timbers\""] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A standard shopfront portal dividing the civic street layouts from the timber retail room. Shifting the latch moves you off public paths to browse raw woodworking synthesis ingredients.",
},

["Door:Aurastery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "The heavy wooden entry barrier leading to the magical astronomical research towers. Pulling the handle uncovers rare library records or validates active Federation quest milestones.",
},

["Door:Baren-Moren Hatter"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A basic wooden barrier door partitioning the apparel retail shop layout blocks. Unlatching the door frame provides entry to check active trade manifests or advance urban side tasks.",
},

["Door:Culinarians' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A heavy iron-banded door sealing off professional kitchen processing yards. Operating the handle opens up advanced crafting synthesis areas and checks active guild progression parameters.",
},

["Door:Ensasa's Catalysts"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A simple merchant door framework leading straight into the alchemy retail shop. Shifting the latch gives you access to browse chemical sets or progress commercial delivery checks.",
},

["Door:Federal Magic Res."] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A secure portal archway partitioning off the industrial magical processing chambers. Verifying your industrial clearance commands the heavy stone framework to part.",
},

["Door:Hostelry Room #1"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A specific structural door barrier protecting a residential lodging room. Passing past the framework manages your movement between corporate agency hubs or checks your travel layers.",
},

["Door:Hostelry Room #2"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "The companion lodging room gateway threshold exiting the public inn lanes. Shifting the latch lets you enter supply vaults to check delivery parameters or retrieve quest items.",
},

["Door:Tarutaru Times"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Waters" },
    zoneIds = { 238 },
    note = "A simple merchant door framework leading straight into the printing office. Shifting the latch gives you access to browse regional publication logs or progress commercial delivery checks.",
},

-------------------------------------------------------------------------------
-- Windurst Woods
-------------------------------------------------------------------------------
["Door:Boneworkers' Guild"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Woods" },
    zoneIds = { 241 },
    note = "A heavy wooden door panel sealing off the professional bone carving workshops. Operating the handle opens up advanced crafting synthesis areas and checks active guild progression parameters.",
},

["Door:Manustery"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Woods" },
    zoneIds = { 241 },
    note = "The heavy wooden entry barrier leading to the magical automaton and puppet development towers. Pulling the handle uncovers rare library records or validates active Federation quest milestones.",
},

["Door:Nchaa's Good Goods"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Windurst Woods" },
    zoneIds = { 241 },
    note = "A simple merchant door framework leading straight into the specialty retail shop. Shifting the latch gives you access to browse gear sets or progress commercial delivery checks.",
},

-------------------------------------------------------------------------------
-- Xarcabard [S]
-------------------------------------------------------------------------------
-- needs review
["Compact Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A small, condensed tracking mark pressed heavily into the past-timeline snow. Clearing away the ice reveals critical wartime evidence needed to advance your active military campaigns.",
},

["Forbidding Portal"] = {
    type = "Transit Portal",
    icon = "VeridicalConflux.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A dark architectural gate frame anchoring an ominous dimensional tear on the frozen frontlines. Activating its cold energy matrix verifies your battle credentials to launch high-tier campaign operations.",
},

-- needs review
["Rally Point: Blue"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A designated tactical staging waypoint manifest on the past-timeline battlefield. Interfacing with this coordinates marker evaluates your group's deployment logs and tracks active side goals.",
},

-- needs review
["Rally Point: Green"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A secondary strategic staging waypoint monitoring frontline force distributions. Searching the surroundings uncovers lost military provisions or records your active side quest parameters.",
},

-- needs review
["Rally Point: Red"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "The final localized tactical staging waypoint anchoring the combat sectors. Finalizing this marker unblocks restrictive warfront parameters to advance critical campaign storylines.",
},

-- needs review
["Sunken Footprint"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A deep track depression frozen heavily into the wasteland permafrost. Studying the deep deformation details regional tactical history and coordinates active investigative trials.",
},

-------------------------------------------------------------------------------
-- Yorcia Weald
-------------------------------------------------------------------------------
-- needs review
["Occultist Footprints"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yorcia Weald" },
    zoneIds = { 263 },
    note = "A set of faint, sophisticated tracking prints pressed into the dark forest sod. Studying the unusual marks uncovers hidden investigative records to advance your pioneer research goals.",
},

["Well-Kept Cache"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Yorcia Weald" },
    zoneIds = { 263 },
    note = "A secure, iron-banded treasure coffer hidden deep within the twisted wilderness woods. Prying open its reinforced lid uncovers lost pioneer resources or unique regional item drops.",
},

-- needs review
["Abandoned Mineshaft"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Sauromugue Champaign [S]" },
    zoneIds = { 98 },
    note = "A decaying timber structure blockading an old mine entryway in the past timeline. Searching the debris uncovers forgotten military gear needed to resolve active tracking lines.",
},

["Acid-eaten Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Mount Zhayolm" },
    zoneIds = { 61 },
    note = "A corroded metal barrier door heavily damaged by volcanic gases. Forcing open the squealing frame allows your party to securely cross regional boundary thresholds into deeper outpost tunnels.",
},

-- needs review
["Ahmibi Watchtower"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Bhaflau Thickets" },
    zoneIds = { 52 },
    note = "A prominent tactical military signaling tower tracking the surrounding thickets. Inspecting its layout coordinates regional stock retrievals or processes mercenary tracking milestones.",
},

["Airship Door"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Sealion's Den" },
    zoneIds = { 32 },
    note = "A reinforced metallic portal blockading an old airship vessel cabin. Overriding its physical layout locking mechanisms slides the heavy panel away to grant exploration passage.",
},

-- needs review
["Altar"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Monastic Cavern" },
    zoneIds = { 150 },
    note = "A solemn stone podium etched with old alignment runes inside the beastman cavern. Interfacing with its surface balances advanced storyline parameters or validates unique attunement keys.",
},

-- needs review
["Altar of Ashes"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Ifrit's Cauldron" },
    zoneIds = { 205 },
    note = "A charred, heat-warped stone altar standing inside the volcanic tunnels. Placing specific elemental offerings onto its surface handles ritual attunements or unlocks specialized magic trials.",
},

-- needs review
["Altar of Offerings"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Giddeus" },
    zoneIds = { 145 },
    note = "A moss-covered stone sacrificial altar hidden deep within the beastman outpost corridors. Searching the top slab tracks advanced expansion milestones and verifies key quest components.",
},

-- needs review
["Altar of Rancor"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Den of Rancor" },
    zoneIds = { 160 },
    note = "An ancient ritual pedestal chilling the air of the dark cavern layout blocks. Checking its stone geometries aligns your spiritual parameters to unlock artifact gear milestones or progress magical quests.",
},

["Altepa Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Altepa Desert" },
    zoneIds = { 125 },
    note = "A massive architectural masonry block gate sealing off the deepest desert ruins. Solving remote switch weight matrix puzzles raises the monolithic slab to expand your exploration paths.",
},

-- needs review
["Ambuscade Tome"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Mhaura" },
    zoneIds = { 249 },
    note = "A thick, magically radiating encyclopedia book filed away near the battle staging docks. Interfacing with this logbook registers your combat records and manages instanced arena battle challenges.",
},

["Amchuchu's Laboratory"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Western Adoulin" },
    zoneIds = { 256 },
    note = "The heavy entrance portal framework anchoring the inventor's lab headquarters. Stepping past this threshold delivers you straight into the main office to handle pioneering research reviews.",
},

["Ancient Lockbox"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Leujaoam Sanctum", "Mamool Ja Training Grounds", "Periqia", "Lebros Cavern", "Ilrusi Atoll", "The Ashu Talif" },
    zoneIds = { 55, 56, 60, 63, 66, 69 },
    note = "A reinforced treasure casket materializing post-combat upon a successful instance clear. Cracking the lock distributes unique gear pieces and allocations of tactical imperial rewards to your squad.",
},

["Ancient Magical Gizmo"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Inner Horutoto Ruins", "Outer Horutoto Ruins" },
    zoneIds = { 192, 194 },
    note = "A strange ancient composite portal locked shut by technical mechanisms inside the ruins. Activating adjacent elemental switches shifts the underlying layout components aside.",
},

-- needs review
["Animal Spoor"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Xarcabard [S]" },
    zoneIds = { 137 },
    note = "A set of faint, frozen tracking remnants pressed into the past-timeline snow wastes. Searching the trace evidence uncovers migratory beast logs and updates active wilderness hunting goals.",
},

["Anomaly Trigger #1"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The primary technological anomaly switch embedded within the underworld layout. Overriding its volatile tech circuits satisfies localized challenge goals to shift heavy corridor gates or manifest rare armor lockboxes across the map layout.",
},

["Anomaly Trigger #2"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The secondary localized anomaly switch monitoring instance progress fields. Interfacing with its parameters triggers structural room variations or validates current challenge tracking.",
},

["Anomaly Trigger #3"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The third localized mechanical switch monitoring dungeon sectors. Moving the device handles layout verification states or flips remote winches to open gated passages.",
},

["Anomaly Trigger #4"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The fourth specific technological locking bracket mounted to the stone framing. Toggling this handle shifts mechanical weights to lower heavy iron portcullis barriers.",
},

["Anomaly Trigger #5"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The fifth specialized mechanical switch panel anchoring the intermediate trial sectors. Finalizing this marker unblocks restrictive blast gates to expand your subterranean instance exploration paths.",
},

["Anomaly Trigger #6"] = {
    type = "Dungeon Switch",
    icon = "Switch.png",
    zones = { "Outer Ra'Kaznar [U]" },
    zoneIds = { 275 },
    note = "The final localized structural switch operating the underworld layouts. Activating this mechanism slides remote gears to flip heavy security partitions across multiple floors.",
},

-- needs review
["Ansgar"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Vunkerl Inlet [S]" },
    zoneIds = { 83 },
    note = "A distinct natural ground landmark or unique ancient monument in the past timeline. Examining it updates advanced frontline campaign milestones or validates your tracking journals.",
},

-- needs review
["Antican Curule Aedilis"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "La Theine Plateau", "Castle Zvahl Keep" },
    zoneIds = { 102, 162 },
    note = "An ancient, beastman-carved stone monument embedded with cryptic markings. Brushing off the dust triggers historical cutscenes or verifies critical milestone items across the overworld.",
},

["Antiquated Sluice Gate"] = {
    type = "Security Gate",
    icon = "Door.png",
    zones = { "Rala Waterways" },
    zoneIds = { 258 },
    note = "A massive iron water control gate tracking the city aqueduct network. Turning the heavy manual valve wheel drains flooding sewer sections to unlock restricted underground chambers.",
},

-- needs review
["AP Master Debug"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Abyssea - Altepa", "Abyssea - Attohwa", "Abyssea - Grauberg", "Abyssea - Konschtat", "Abyssea - La Theine", "Abyssea - Misareaux", "Abyssea - Tahrongi", "Abyssea - Uleguerand", "Abyssea - Vunkerl" },
    zoneIds = { 15, 45, 132, 215, 216, 217, 218, 253, 254 },
    note = "An absolute development data coordinate tracking node injected inside the dimension mirror. Interfacing with the core validates diagnostic scripts or checks server alignment parameters.",
},

-- needs review
["Apkallu Interpreter"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Mine Shaft #2716", "Arrapago Reef" },
    zoneIds = { 13, 54 },
    note = "A localized spatial navigation marker deeply tied to regional avian tracking loops. Examining the node uncovers coastal archives or logs critical milestones for your active seafaring side quests.",
},

-- needs review
["Apkallu_A"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "The primary specific spatial milestone tracking node hidden along the reef rocks. Investigating the point updates your active wilderness research records or triggers exotic bird cutscenes.",
},

-- needs review
["Apkallu_B"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef" },
    zoneIds = { 54 },
    note = "The secondary specific spatial milestone tracking node embedded along the damp reef channels. Studying the surroundings uncovers hidden coastal clues to advance your active side tasks.",
},

["Arboreal Grove"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The primary grove of harvestable trees planted within your personal island sanctuary. Interfacing with the timber lets you gather logging resources, raw lumber components, and island cultivation experience.",
},

["Arboreal Grove #2"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The secondary grove layout outcropping along your private island paths. Foraging through the rich timber yields standard regional wood logs, rare sap items, and island ranking metrics.",
},

["Arboreal Grove #3"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The tertiary timber grove face inside your personal island garden. Clearing the brush and foraging the branches extracts specialized synthesis wood layers and advanced cultivation items.",
},

["Arboreal Grove #4"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    zones = { "Mog Garden" },
    zoneIds = { 280 },
    note = "The quaternary timber grove boundary lining your private island property walls. Utilizing standard logging tools harvests advanced industrial wood materials, elemental geodes, and specialized expansion items.",
},

["Armoury Crate"] = {
    type = "Loot Container",
    icon = "TreasureCasket.png",
    zones = { "Bearclaw Pinnacle", "Boneyard Gully", "The Shrouded Maw", "Mine Shaft #2716", "Monarch Linn", "Talacca Cove", "Navukgo Execution Chamber", "Jade Sepulcher", "Bhaflau Remnants", "Zhayolm Remnants", "Arrapago Remnants", "Silver Sea Remnants", "Nyzul Isle", "Hazhalm Testing Grounds", "La Vaule [S]", "Beadeaux [S]", "Castle Oztroja [S]", "Balga's Dais", "Qu'Bia Arena", "Horlais Peak", "Waughroon Shrine", "Throne Room", "Sacrificial Chamber", "Throne Room [S]", "Chamber of Oracles", "Throne Room" },
    zoneIds = { 6, 8, 10, 13, 31, 57, 64, 67, 73, 74, 75, 76, 77, 78, 85, 92, 99, 139, 140, 144, 146, 156, 163, 165, 168, 206 },
    note = "A reinforced storage chest appearing upon victory in battlefield instances or remnants sectors. Prying open the heavy lid drops specialized weapons, armor components, or unique instance progression resources for your squad.",
},

-- needs review
["Ars Monstrum"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Yorcia Weald [U]" },
    zoneIds = { 264 },
    note = "A mysterious, ancient compilation book found deep within the instanced skirmish layers. Reading its pages reveals forbidden monstrosity lore to advance specialized tracking objectives.",
},

-- needs review
["Aspirants' Grounds"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Reisenjima" },
    zoneIds = { 291 },
    note = "A prominent sacred clearing or spatial boundary checkpoint anchoring the regional trails. Pausing along its perimeter registers your trial parameters to advance active Voracious Resurgence missions.",
},

-- needs review
["Astral Glimmer"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Hazhalm Testing Grounds" },
    zoneIds = { 78 },
    note = "A shimmering, extraplanar energy distortion drifting inside the cold imperial testing labs. Touching the pulsing rift updates active investigative logs or processes specialized side quests.",
},

-- needs review
["Astral Plinth"] = {
    type = "Quest Node",
    icon = "Box.png",
    zones = { "Arrapago Reef", "Halvung", "Mamook" },
    zoneIds = { 54, 62, 65 },
    note = "An ancient, stone ritual platform etched with celestial runic geometries. Placing proper key items or boss trophies onto its surface handles ritual attunements or unlocks specialized magic trials.",
},

["AT-01 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The primary mystical fuel tower anchoring the regional temporal matrix. Interfacing with the tower structure consumes its active energy parameters to replenish your squad's active Abyssean time extensions.",
},

["AT-02 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The secondary localized fuel station tracking lattice energy levels. Accessing the terminal lets you monitor internal fuel levels or siphon critical resource buffs to survive the distorted dimension.",
},

["AT-03 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The third localized magical fuel node standing within the parched wastes. Channeling your regional keys into its framework siphons crucial energy reserves to stall the dimension's decay.",
},

["AT-04 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The fourth fast-travel fuel pillar humming along the perimeter canyons. Interfacing with the system allows you to check active matrix levels or secure defensive tactical enhancements.",
},

["AT-05 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The fifth specialized energy core siphoning power across the parched sands. Activating its internal mechanisms distributes vital resource metrics to expand your temporal safety window.",
},

["AT-06 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The sixth strategic fuel monument monitoring local area lattice thresholds. Connecting your tracking details to the core reveals nearby temporal distortions and updates active side goals.",
},

["AT-07 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The seventh high-tier tactical fuel mechanism anchored deep within the crags. Overriding its restrictive controls extracts advanced battlefield support matrices for your whole squad.",
},

["AT-08 Martello"] = {
    type = "Fuel Station",
    icon = "Martello.png",
    zones = { "Abyssea - Attohwa" },
    zoneIds = { 215 },
    note = "The eighth and final specialized fuel tower monitoring the deepest reaches of the zone. Satisfying its operational parameters restores supreme spatial stability to help you navigate surrounding hazards.",
},

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
["Bag"] = {
    type = "Bag",
    icon = "Bag.png",
    note = "A soft cloth or leather sack left on the ground. Searching inside uncovers discarded regional items, crafting components, or hidden explorer gear.",
},

["Barrel"] = {
    type = "Barrel",
    icon = "Barrel.png",
    note = "A reinforced wooden storage cask stationed near docks or outposts. Prying open the lid reveals stored regional provisions, liquid synthesis components, or hidden side quest supplies.",
},

["Bookshelf"] = {
    type = "Bookshelf",
    icon = "Bookshelf.png",
    note = "A heavy wooden library framework packed with weathered volumes. Browsing the dusty shelves reveals ancient historical archives, genealogical text strings, and cryptic background lore.",
},

["Box"] = {
    type = "Box",
    icon = "Box.png",
    note = "A simple timber layout container abandoned in the environment. Investigating the frame uncovers localized supplies, checks dynamic progress flags, or validates early-tier tasks.",
},

["Burning Circle"] = {
    type = "Burning Circle",
    icon = "BurningCircle.png",
    note = "A glowing elemental ring of fire pulsing with dangerous energy. Stepping directly into the active glyph checks your alliance credentials to transport your party into instanced battlefield arenas.",
},

["Cavernous Maw"] = {
    type = "Cavernous Maw",
    icon = "CavernousMaw.png",
    note = "A massive stone monument caked in temporal distortion static. Entering the jagged opening shatters temporal boundaries to warp you directly across different time periods of the world map.",
},

["Clamming Point"] = {
    type = "Clamming Point",
    icon = "ClammingPoint.png",
    note = "A rich marine deposit exposed along the coastal shoreline sands. Foraging through the wet mud extracts rare shellfish, precious black pearls, and specialized coastal synthesis ingredients.",
},

["Crate"] = {
    type = "Crate",
    icon = "Crate.png",
    note = "A heavy wooden cargo container left near warehouses or mining tracks. Searching through its interior provides emergency provisioning items, armor components, or temporary battlefield blocks.",
},

["Ergon Locus"] = {
    type = "Ergon Locus",
    icon = "ErgonLocus.png",
    note = "A powerful focal point of natural geological energy humming in the wilderness fields. Tuning into its frequency logs pioneer mapping data and updates your frontier exploration records.",
},

["Ethereal Junction"] = {
    type = "Ethereal Junction",
    icon = "EtherealJunction.png",
    note = "A shimmering dimensional rift distortion residue light anomaly. Gathering your party before the anomaly verifies your alliance metrics to launch high-tier battle encounters.",
},

["Excavation Point"] = {
    type = "Excavation Point",
    icon = "ExcavationPoint.png",
    note = "A loose patch of gravelly soil or mineral outcropping. Striking the spot with an equipped bone pickaxe extracts ancient fossil remnants, bone matrices, and unique crafting components.",
},

["Excav. Point"] = {
    type = "Excavation Point",
    icon = "ExcavationPoint.png",
    note = "A shorthand localized geological excavation node. Digging into the loose debris uncovers ancient artifacts, raw ores, and logs exploration metrics for active regional tasks.",
},

["Faded Footprint"] = {
    type = "Faded Footprint",
    icon = "Footprint.png",
    note = "A faint tracking mark barely visible in the overworld dirt. Studying the weathered indentation uncovers hidden investigative records to advance your active side tasks.",
},

["Fish Trap"] = {
    type = "Fish Trap",
    icon = "FishTrap.png",
    note = "A submerged wicker cage mechanism installed along coastal reef boundaries. Checking the mesh pulls up rare aquatic synthesis components, fresh fish, and hidden island materials.",
},

["Footprint"] = {
    type = "Footprint",
    icon = "Footprint.png",
    note = "A distinct tracking imprint pressed cleanly into the layout floor. Inspecting the print uncovers hidden investigative data trails or progresses specialized side quest paths.",
},

["Geomagnetic Fount"] = {
    type = "Geomagnetic Fount",
    icon = "GeomagneticFount.png",
    note = "A pulsing crystalline fast-travel monument anchored to the regional ley lines. Interfacing with its energy lattice uncovers spatial archives and unlocks fast travel travel lines.",
},

["Harvest Point"] = {
    type = "Harvest Point",
    icon = "HarvestPoint.png",
    note = "A thick cluster of native overworld botanical flora. Foraging through the greenery uncovers rare crafting items, gathers regional resources, and completes active gathering trials.",
},

["Mining Point"] = {
    type = "Mining Point",
    icon = "MiningPoint.png",
    note = "A rich mineral vein shimmering along damp tunnel rock faces. Striking this outcrop with an equipped pickaxe extracts precious metallic ore, pristine gems, and archives mining telemetry.",
},

["Monument"] = {
    type = "Monument",
    icon = "Monument.png",
    note = "A weathered, ancient stone monument logging regional accomplishments. Accessing the slate reviews historical logs, updates country missions, or triggers side cutscenes.",
},

["Nyzul Isle Staging Point"] = {
    type = "Nyzul Isle Staging Point",
    icon = "NyzulIsleStagingPoint.png",
    note = "An elite imperial fast-travel gateway floating inside municipal hubs. Stepping onto the active node triggers a rapid energy lift, teleporting your party directly to the research facility layers.",
},

["Planar Rift"] = {
    type = "Planar Rift",
    icon = "PlanarRift.png",
    note = "A violent extraplanar rift tearing through the overworld landscape. Channeling your temporary alignment keys forces open a spatial distortion to engage in high-tier Voidwatch operations.",
},

["Proto-Waypoint"] = {
    type = "Proto-Waypoint",
    icon = "ProtoWaypoint.png",
    note = "A high-fidelity prototype crystalline fast-travel terminal built into the city architecture. Turning the terminal valve coordinates your movements to warp you across frontier networks.",
},

["Runic Portal"] = {
    type = "Runic Portal",
    icon = "RunicPortal.png",
    note = "A massive magical teleportation gateway sealing the imperial border thresholds. Satisfying the local checkpoint guards commands the runic field boundaries to open for rapid squad transport.",
},

["Sack"] = {
    type = "Sack",
    icon = "Sack.png",
    note = "A cloth supply sack forgotten along the roadside. Searching the bundle uncovers lost regional resources, crafting components, or hidden campaign supplies.",
},

["Shimmering Circle"] = {
    type = "Shimmering Circle",
    icon = "ShimmeringCircle.png",
    note = "An ethereal runic teleportation circle pulsing inside the investigation tower layers. Stepping into the light reads your saved climbing progress tokens to warp your squad directly onto targeted floor layouts.",
},

["Signpost"] = {
    type = "Signpost",
    icon = "Signpost.png",
    note = "A weathered wooden marker standing along overworld road forks. Examining its faded geographical carvings coordinates your localized orientation and logs regional side tasks.",
},

["Strange Apparatus"] = {
    type = "Strange Apparatus",
    icon = "StrangeApparatus.png",
    note = "A highly complex technological machine humming with ancient power. Feeding specialized metal chips into its circuitry unseals advanced item modifications or draws out hidden targets.",
},

["Sturdy Pyxis"] = {
    type = "Sturdy Pyxis",
    icon = "SturdyPyxis.png",
    note = "A locked, extraplanar prize repository dropping immediately post-combat. Breaking its mathematical numeric lock code rewards your squad with combat items and temporary battlefield buffs.",
},

["Survival Guide"] = {
    type = "Survival Guide",
    icon = "SurvivalGuide.png",
    note = "A book manual podium stationed at critical outposts. Reading the text lets you enroll in training regimes or consume small gil allowances to teleport instantly between regional guides.",
},

["Treasure Casket"] = {
    type = "Treasure Casket",
    icon = "TreasureCasket.png",
    note = "A standard drop treasure box materializing after defeating regional enemies. Breaking past the lock reveals localized items, currency caches, or temporary battlefield enhancements.",
},

["Treasure Chest"] = {
    type = "Treasure Chest",
    icon = "TreasureChest.png",
    note = "A standard wooden repository found tucked away inside dungeon corridors. Prying open its lid rewards your squad with regional supplies, maps, or unique currency components.",
},

["Treasure Coffer"] = {
    type = "Treasure Coffer",
    icon = "TreasureCoffer.png",
    note = "A heavy ornate repository found hidden deep inside dungeon chambers. Finding and utilizing a specialized key item releases the heavy framework to let you pass or claim artifact gear.",
},

["Veridical Conflux"] = {
    type = "Veridical Conflux",
    icon = "VeridicalConflux.png",
    note = "A shimmering spatial fast-travel node pulsing with extraplanar energy. Tuning into its frequency links you to the regional transport grid, granting an instant leap across Abyssean sectors.",
},

["Waypoint"] = {
    type = "Waypoint",
    icon = "Waypoint.png",
    note = "A crystalline travel waypoint anchored near elite city centers. Interfacing with this network coordinates your movements and handles advanced frontier movement across the continent.",
},

};

itemIcons['Home Point #1'] = { displayName = 'Home Point', type = '#1', icon = 'HomePoint1.png', worldOffsetY = -1 };
itemIcons['Home Point #2'] = { displayName = 'Home Point', type = '#2', icon = 'HomePoint2.png', worldOffsetY = -1 };
itemIcons['Home Point #3'] = { displayName = 'Home Point', type = '#3', icon = 'HomePoint3.png', worldOffsetY = -1 };
itemIcons['Home Point #4'] = { displayName = 'Home Point', type = '#4', icon = 'HomePoint4.png', worldOffsetY = -1 };
itemIcons['Home Point #5'] = { displayName = 'Home Point', type = '#5', icon = 'HomePoint5.png', worldOffsetY = -1 };

return itemIcons;
