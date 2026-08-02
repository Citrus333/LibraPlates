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
	["Large Stone Door"] = {
		["_source"] = "item",
		["icon"] = "Door.png",
		["note"] = "Locked door.\
* Opens after meeting nearby requirements.",
		["type"] = "Security Gate",
	},
	["Marble Door"] = {
		["_source"] = "item",
		["icon"] = "Door.png",
		["note"] = "Locked door.\
* Opens after meeting nearby requirements.",
		["type"] = "Security Gate",
	},
	["Tome of Magic"] = {
		["_source"] = "item",
		["icon"] = "SurvivalGuide.png",
		["note"] = "Quest location:\
* Examine for quest progress.",
		["type"] = "Quest Node",
	},
	["Transporter"] = {
		["_source"] = "item",
		["icon"] = "VeridicalConflux.png",
		["note"] = "Transporter:\
	* Travel between areas.",
		["type"] = "Transit Portal",
	},
    },
}
