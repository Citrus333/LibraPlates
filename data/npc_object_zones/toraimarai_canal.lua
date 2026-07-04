return {
    ["npcs"] = {
        ["Erudu-Faludu"] = {
            ["_source"] = "catseye_npc",
            ["icon"] = "QuestNPC.png",
            ["note"] = "A Crystal Prelude:\
* Windurstian starter NPC.\
* Gives a Sickle, then asks for\
material from a Dangling Root.\
* Starts the intro NM encounter and\
warps you out after completion.",
            ["type"] = "CW Intro Quest",
        },
    },
    ["objects"] = {
        ["Dangling Root"] = {
            ["_source"] = "catseye_item",
            ["icon"] = "QuestionMark.png",
            ["note"] = "A Crystal Prelude:\
* Windurstian gathering point.\
* Trade the Sickle from Erudu-Faludu to receive the quest material.",
            ["type"] = "CW Intro Gather",
            ["worldOffsetY"] = 0.25,
        },
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
        ["Grounds Tome"] = {
            ["_source"] = "item",
            ["icon"] = "SurvivalGuide.png",
            ["note"] = "A floating magical ledger hovering at key hunting outposts. Reading the text lets you enlist in Grounds of Valor combat regimes, secure experience multipliers, and claim defensive battle enhancements.",
            ["type"] = "Training Ledger",
        },
        ["Large Stone Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "A monolithic slab of ancient masonry barring the flooded subterranean aqueducts. Overriding the nearby locking mechanism slides the heavy panel away to grant exploration passage.",
            ["type"] = "Security Gate",
        },
        ["Marble Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
            ["note"] = "An elegant, polished stone barrier sealing executive chambers and canal networks. Verifying your current national mission clearance commands the ornate framework to part.",
            ["type"] = "Security Gate",
        },
        ["Tome of Magic"] = {
            ["_source"] = "item",
            ["icon"] = "SurvivalGuide.png",
            ["note"] = "A dusty academic book filed away on long-forgotten laboratory shelves. Reading its cryptic handwriting uncovers ancient civilization records and updates active magical side quests.",
            ["type"] = "Quest Node",
        },
        ["Transporter"] = {
            ["_source"] = "item",
            ["icon"] = "VeridicalConflux.png",
            ["note"] = "A high-fidelity spatial transport gateway floating inside elite municipal hubs. Stepping onto the active node triggers a rapid energy lift, teleporting your party up and down structural map layers.",
            ["type"] = "Transit Portal",
        },
    },
}
