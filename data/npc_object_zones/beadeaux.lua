return {
    ["npcs"] = {
        ["Evrard"] = {
            ["_source"] = "npc",
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quest:\
* The Rescue\
",
            ["type"] = "Quest Associate",
        },
        ["Haggleblix"] = {
            ["_source"] = "npc",
            ["icon"] = "Merchant.png",
            ["note"] = "Notes:\
You must have a Vial of Shrouded Sand",
            ["type"] = "Goblin Peddler",
        },
        ["Serafin"] = {
            ["_source"] = "npc",
            ["icon"] = "Dialogue.png",
            ["type"] = "Citizen",
        },
    },
    ["objects"] = {
        ["GoalPoint"] = {
            ["_source"] = "item",
            ["icon"] = "QuestNode.png",
            ["note"] = "An ancient structural focal destination waypoint hidden deep inside sprawling dungeons. Reaching this layout node validates complex progression flags or completes server event tasks.",
            ["type"] = "Quest Node",
        },
        ["Goblin Footprint"] = {
            ["_source"] = "item",
            ["icon"] = "Cutscene.png",
            ["note"] = "A small indention in the dirt storing dimensional memory data traces. Trading an overworld artifact or currency slip to the footprint triggers a vivid replay of historical region cutscenes.",
            ["type"] = "Memory Recall",
            ["worldOffsetY"] = 0,
        },
        ["Heavy Sliding Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "A monolithic stone security partition blockading the deep Quadav stronghold. Activating remote lever pulley systems commands the heavy masonry frame to slide open.",
            ["type"] = "Security Gate",
        },
        ["Jail Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "A reinforced iron-barred barrier locking off the underground Quadav cells. Procuring a subterranean prison key releases the latch, allowing you to free captives or venture into deeper vault layers.",
            ["type"] = "Security Gate",
        },
        ["Sliding Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "A heavy stone security barrier dividing the Quadav strongholds. Unlatching the heavy framework shifts localized area layouts to allow your squad passage into deeper corridors.",
            ["type"] = "Security Gate",
        },
        ["The Afflictor"] = {
            ["_source"] = "item",
            ["icon"] = "Afflictor.png",
            ["note"] = "A massive, corrupted ancient device radiating a debilitating curse across the Quadav stronghold. Activating the device without proper shielding key items inflicts severe ailments onto your party.",
            ["type"] = "Inflicts Curse",
        },
        ["The Mute"] = {
            ["_source"] = "item",
            ["icon"] = "Mute.png",
            ["note"] = "A companion ancient mechanism silencing magical echoes inside the beastman chambers. Interfacing with its core neutralizes or activates the regional layout barrier fields.",
            ["type"] = "Inflicts Silence",
        },
    },
}
