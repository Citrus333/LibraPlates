local defaults = {};

defaults.self = {
    name = {
        enabled = true,
        shortenName = 30,
        textSize = 10,
        color = { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = true,
        outlineColor = { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = 2,
        offsetX = 0,
        offsetY = -54,
        anchorTo = 'Plate',
        anchorPoint = 'Top',
    },
    hpBar = {
        enabled = true,
        width = 180,
        height = 12,
        color = { 0.90, 0.20, 0.20, 1.0 },
        backgroundColor = { 0.05, 0.05, 0.05, 0.85 },
        offsetX = 0,
        offsetY = -28,
    },
    mpBar = {
        enabled = true,
        width = 180,
        height = 8,
        color = { 0.45, 0.95, 0.35, 1.0 },
        backgroundColor = { 0.05, 0.05, 0.05, 0.85 },
        offsetX = 0,
        offsetY = -14,
    },
};

return defaults;
