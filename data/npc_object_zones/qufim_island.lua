return {
    ["npcs"] = {
        ["Chocobo"] = {
            ["_source"] = "npc",
            ["icon"] = "ChocoboRenter.png",
            ["type"] = "Rental Chocobo",
        },
        ["Echion"] = {
            ["_source"] = "npc",
            ["icon"] = "Scout.png",
            ["type"] = "Scout",
        },
        ["Jiwon"] = {
            ["_source"] = "npc",
            ["info"] = "Appears when Qufim is under weekly conquest-control by one of the three nations. :*Sells to and buys items from characters allied with the nation that has the weekly conquest-control of this region. :*All items which Standard Merchants normally buy, can be traded by all characters for regional influence points. The points are awarded to the trader's current Allegiance. :*Teleports players who have previously done a Supply Run for the specific region, to their Allegiance Teleport NPC in one of the three cities. For further information, see Outpost Vendor. ;Items sold: *Antidote 316gil *Echo Drops 800gil *Ether 4832gil *Eye Drops 2595gil *Potion 910gil",
            ["note"] = "Notes:\
Appears when Qufim is under weekly conquest-control by one of the three nations. :*Sells to and buys items from characters allied with the nation that has the weekly conquest-control of this region. :*All items which Standard Merchants normally buy, can be traded by all characters for regional influence points. The points are awarded to the trader's current Allegiance. :*Teleports players who have previously done a Supply Run for the specific region, to their Allegiance Teleport NPC in one of the three cities. For further information, see Outpost Vendor. ;Items sold: *Antidote 316gil *Echo Drops 800gil *Ether 4832gil *Eye Drops 2595gil *Potion 910gil",
            ["type"] = "Outpost Vendor",
        },
        ["Matica, R.K."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by San d'Oria ;Notes for characters only with San d'Oria as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Empress Band or Chariot Band :*Accepts Qufim Supplies for finishing Supply Quest ;Notes for characters only without San d'Oria as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
        ["Numumu, W.W."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by Windurst ;Notes for characters only with Windurst as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Empress Band or Chariot Band :*Accepts Qufim Supplies for finishing Supply Quest ;Notes for characters only without Windurst as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
        ["Pitoire, R.K."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by San d'Oria ;Notes for characters only with San d'Oria as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Empress Band or Chariot Band :*Accepts Qufim Supplies for finishing Supply Quest :*Accepts Garrison starting item Ram Leather Missive ;Notes for characters only without San d'Oria as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
        ["Sasa, I.M."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by Bastok ;Notes for characters only with Bastok as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Emperor Band, Empress Band or Chariot Band :*Accepts Qufim Supplies for finishing Supply Quest :*Accepts Garrison starting item Ram Leather Missive ;Notes for characters only without Bastok as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
        ["Singing Blade, I.M."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by Bastok ;Notes for characters only with Bastok as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Emperor Band, Empress Band or Chariot Band :*Accepts Qufim Supplies for finishing Supply Quest ;Notes for characters only without Bastok as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
        ["Tsonga-Hoponga, W.W."] = {
            ["_source"] = "npc",
            ["icon"] = "ConquestOverseer.png",
            ["note"] = "Notes:\
Appears, when Qufim is under weekly conquest-control by Windurst ;Notes for characters only with Windurst as current Allegiance: :*Casts Signet :*Choice of setting Home Point for free :*Recharges Empress Band, Chariot Band or Emperor Band :*Accepts Qufim Supplies for finishing Supply Quest :*Accepts Garrison starting item Ram Leather Missive ;Notes for characters only without Windurst as current Allegiance: :*Choice of setting Home Point for a fee - higher prices for higher Allegiance Ranks (Rank 10: 5600 gil) For further information see Conquest Overseer.",
            ["type"] = "Conquest Overseer",
        },
    },
    ["objects"] = {
        ["Beastmen's Banner"] = {
            ["_source"] = "item",
            ["icon"] = "BeastmenBanner.png",
            ["note"] = "A military standard planted deep within hostile territory. Securing this tactical marker advances your localized Expeditionary Force objectives and shifts continental conquest influence metrics.",
            ["type"] = "Quest Node",
        },
        ["Field Manual"] = {
            ["_source"] = "item",
            ["icon"] = "Dialogue.png",
            ["note"] = "A stationary training ledger podium stationed at military outposts. Reading the text lets you enlist in regional combat regimes, check training metrics, or purchase field enhancements.",
            ["type"] = "Training & Support",
			["worldOffsetY"] = 0.65,
        },
        ["Field Parchment"] = {
            ["_source"] = "item",
            ["icon"] = "Dialogue.png",
            ["note"] = "A blank magical scroll mounted near regional field manual locations. Binding your training orders to the parchment engages elite automated operations parameters or validates combat tracking.",
            ["type"] = "Training & Support",
        },
        ["Giant Footprint"] = {
            ["_source"] = "item",
            ["icon"] = "Footprint.png",
            ["note"] = "A massive tracking indentation pressed deeply into the frozen coastal crags. Studying the oversized imprint uncovers unique geological footprints or validates active regional hunt records.",
            ["type"] = "Quest Node",
        },
        ["Goblin Footprint"] = {
            ["_source"] = "item",
            ["icon"] = "Cutscene.png",
            ["note"] = "A small indention in the dirt storing dimensional memory data traces. Trading an overworld artifact or currency slip to the footprint triggers a vivid replay of historical region cutscenes.",
            ["type"] = "Memory Recall",
            ["worldOffsetY"] = 0,
        },
        ["Hieroglyphics"] = {
            ["_source"] = "item",
            ["icon"] = "Hieroglyphics.png",
            ["note"] = "Ancient geometric carvings etched directly into stone monuments. Examining the alien script uncovers historical archives or confirms dimensional travel clearances for Abyssea.",
            ["type"] = "Quest Node",
        },
        ["Luck Rune"] = {
            ["_source"] = "item",
            ["icon"] = "VoidwatchRift.png",
            ["note"] = "An ancient runic seal etched directly into the dimensional boundaries. Activating this mystic distortion aligns your spatial metrics, drawing forth high-tier Voidwatch campaign campaign operations.",
            ["type"] = "Transit Portal",
        },
        ["Mog-Tablet"] = {
            ["_source"] = "item",
            ["icon"] = "QuestNode.png",
            ["note"] = "A small, glowing tablet shard hidden across random corners of the world. Scouring the land to locate and recover all eleven missing stone relics unleashes world-wide exploration blessings for all adventurers.",
            ["type"] = "Quest Node",
        },
        ["Nightflowers"] = {
            ["_source"] = "item",
            ["icon"] = "FeyBlossoms.png",
            ["note"] = "A delicate cluster of midnight flora blooming under the starlight along the crags. Examining the rare petals satisfies precise regional gathering quotas and updates active wilderness research records.",
            ["type"] = "Quest Node",
        },
        ["Peculiar Footprints"] = {
            ["_source"] = "item",
            ["icon"] = "Footprint.png",
            ["note"] = "Faint, mysterious tracking grooves pressed into the dungeon mud or overworld soil layers. Studying the unusual marks uncovers hidden investigative records to advance active side quests.",
            ["type"] = "Quest Node",
        },
        ["Riftworn Pyxis"] = {
            ["_source"] = "item",
            ["icon"] = "TreasureCasket.png",
            ["note"] = "A locked extraplanar drop chest container materializing immediately post-combat across Voidwatch fields. Breaking its lock rewards your squad with combat currencies or temporary buffs.",
            ["type"] = "Loot Container",
        },
        ["Swirling Vortex"] = {
            ["_source"] = "item",
            ["icon"] = "VeridicalConflux.png",
            ["note"] = "A shimmering dimensional rift warping the overworld landscape layers. Stepping directly into the spatial void verifies your credentials to transition between high-tier battlefield instances.",
            ["type"] = "Transit Portal",
        },
        ["Transcendental Radiance"] = {
            ["_source"] = "item",
            ["icon"] = "VeridicalConflux.png",
            ["note"] = "A brilliant, pulsing cosmic rift hovering above the dimensional void. Stepping directly into the blinding aura checks your group alignment metrics to launch legendary master battlefield instances.",
            ["type"] = "Transit Portal",
        },
        ["Trodden Snow"] = {
            ["_source"] = "item",
            ["icon"] = "Snow.png",
            ["note"] = "A distinct patch of loose, packed ice revealing disturbed ground underneath. Sifting through the drift uncovers forgotten explorer cargo or registers crucial tracking metrics.",
            ["type"] = "Quest Node",
        },
        ["Undulating Confluence"] = {
            ["_source"] = "item",
            ["icon"] = "VeridicalConflux.png",
            ["note"] = "A shimmering, swirling vortex of spatial energy warping the overworld landscape. Stepping directly into the ripple accesses the regional teleportation grid to shift you instantly into Eschan domains.",
            ["type"] = "Transit Portal",
        },
    },
}
