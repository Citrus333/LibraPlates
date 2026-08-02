return {
    ["npcs"] = {
        ["Chhaya"] = {
            ["_source"] = "npc",
            ["icon"] = "Merchant.png",
            ["type"] = "Standard Merchant",
        },
        ["Sahn"] = {
            ["_source"] = "npc",
            ["icon"] = "Ferry-Schedule.png",
            ["note"] = "Notes:\
Will report how long until the Ferry docks in Mhaura.",
            ["type"] = "Ferry Schedule",
        },
    },
    ["objects"] = {
        ["Cargo Ship Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
			["note"] = "Leads to the lower deck for shelter during sea weather and pirate attacks.",
            ["type"] = "Security Gate",
        },
        ["Door"] = {
            ["_source"] = "item",
            ["icon"] = "Door.png",
			["note"] = "Leads to the next room.\
* Use for shelter during pirate attacks.",
            ["type"] = "Security Gate",
        },
    },
}
