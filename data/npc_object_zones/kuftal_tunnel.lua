return {
    ["npcs"] = {
        ["Hawk Nose"] = {
            ["_source"] = "npc",
            ["icon"] = "QuestAssociate.png",
            ["note"] = "Involved in Quests:\
* The Kuftal Tour",
            ["type"] = "Quest Associate",
        },
    },
		["objects"] = {
			["Door_Rock"] = {
				["_source"] = "item",
				["icon"] = "Door.png",
				["note"] = "Locked stone door.\
* Opens after meeting nearby requirements.",
				["type"] = "Security Gate",
			},
			["GoalPoint"] = {
				["_source"] = "item",
				["icon"] = "QuestNode.png",
				["note"] = "Quest objective:\
* Reach this location to progress.",
				["type"] = "Quest Node",
			},
			["Goblin Footprint"] = {
				["_source"] = "item",
				["icon"] = "Cutscene.png",
				["note"] = "Cutscene replay point.\
* Replay previously viewed story cutscenes.",
				["type"] = "Memory Recall",
				["worldOffsetY"] = 0,
			},
			["Grounds Tome"] = {
				["_source"] = "item",
				["icon"] = "SurvivalGuide.png",
				["note"] = "Grounds of Valor:\
* Start and manage training regimes.",
				["type"] = "Training Ledger",
			},
			["Riftworn Pyxis"] = {
				["_source"] = "item",
				["icon"] = "TreasureCasket.png",
				["note"] = "Voidwatch rewards:\
* Contains loot and temporary items.",
				["type"] = "Loot Container",
			},
		},
    },
}
