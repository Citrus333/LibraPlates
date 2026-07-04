return {
    ["npcs"] = {
        ["Destin"] = {
            ["_source"] = "npc",
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quest:\
* The Weight of Evidence\
* The Heir to the Light\
",
            ["type"] = "Quest Associate",
        },
        ["Ranperre"] = {
            ["_source"] = "npc",
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Mission:\
* The Voracious Resurgence\
",
            ["type"] = "Mission Associate",
        },
        ["Robineaux"] = {
            ["_source"] = "catseye_npc",
            ["icon"] = "QuestNPC.png",
            ["note"] = "A Crystal Prelude:\
* San d'Orian starter NPC.\
* Gives a Hatchet, then asks for material from a Loose Branch.\
* Starts the intro NM encounter and warps you out after completion.",
            ["type"] = "CW Intro Quest",
        },
    },
    ["objects"] = {
        ["Cermet Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "An enduring portal crafted from indestructible ancient composite materials. Activating its associated technological terminal or matching puzzle triggers parts the panels, granting passage into deep ruins.",
            ["type"] = "Security Gate",
        },
        ["Goblin Footprint"] = {
            ["_source"] = "item",
            ["icon"] = "Cutscene.png",
            ["note"] = "A small indention in the dirt storing dimensional memory data traces. Trading an overworld artifact or currency slip to the footprint triggers a vivid replay of historical region cutscenes.",
            ["type"] = "Memory Recall",
            ["worldOffsetY"] = 0,
        },
        ["Grounds Tome"] = {
            ["_source"] = "item",
            ["icon"] = "SurvivalGuide.png",
            ["note"] = "A floating magical ledger hovering at key hunting outposts. Reading the text lets you enlist in Grounds of Valor combat regimes, secure experience multipliers, and claim defensive battle enhancements.",
            ["type"] = "Training Ledger",
        },
        ["Hazy Rune"] = {
            ["_source"] = "item",
            ["icon"] = "VoidwatchRift.png",
            ["note"] = "A shimmering, distorted runic seal etched directly into the dungeon walls. Directing your cosmic tracking keys into the glyph forces open an extraplanar rift to initiate Voidwatch operations.",
            ["type"] = "Transit Portal",
        },
        ["Heavy Stone Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "A massive architectural slab of ancient tomb masonry barring deep burial vault corridors. Solving localized lever puzzles releases the latch to clear your exploration path.",
            ["type"] = "Security Gate",
        },
        ["Loose Branch"] = {
            ["_source"] = "catseye_item",
            ["icon"] = "QuestionMark.png",
            ["note"] = "A Crystal Prelude:\
* San d'Orian gathering point.\
* Trade the Hatchet from Robineaux to receive the quest material.",
            ["type"] = "CW Intro Gather",
            ["worldOffsetY"] = 0.25,
        },
        ["Riftworn Pyxis"] = {
            ["_source"] = "item",
            ["icon"] = "TreasureCasket.png",
            ["note"] = "A locked extraplanar drop chest container materializing immediately post-combat across Voidwatch fields. Breaking its lock rewards your squad with combat currencies or temporary buffs.",
            ["type"] = "Loot Container",
        },
        ["Tombstone"] = {
            ["_source"] = "item",
            ["icon"] = "Gravestone.png",
            ["note"] = "A weathered stone cemetery monument embedded with ancient noble crests. Brushing off the dust triggers historical cutscenes or verifies critical milestone items for the San d'Orian royal family lines.",
            ["type"] = "Quest Node",
        },
    },
}
