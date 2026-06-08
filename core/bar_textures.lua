local textureLoader = require('core.texture_loader');

local barTextures = {};
local options = T{
    'Solid',
    'Aluminium',
    'Button',
    'Gloss Dark',
    'Soft Gray',
    'Gradient Light',
    'Metal Sheet',
    'Minimalist',
    'Stone Light',
};
local files = {
    ['Aluminium'] = 'bar_aluminium.png',
    ['Button'] = 'bar_button.png',
    ['Gloss Dark'] = 'bar_gloss_dark.png',
    ['Soft Gray'] = 'bar_soft_gray.png',
    ['Gradient Light'] = 'bar_gradient_light.png',
    ['Metal Sheet'] = 'bar_metal_sheet.png',
    ['Minimalist'] = 'bar_minimalist.png',
    ['Stone Light'] = 'bar_stone_light.png',
};
local cache = {};

function barTextures.GetOptions()
    return options;
end

function barTextures.GetTextureId(style)
    local fileName = files[tostring(style or 'Solid')];

    if (fileName == nil) then
        return nil;
    end

    if (cache[fileName] ~= nil) then
        return cache[fileName];
    end

    local path = addon.path .. '\\assets\\images\\widget-bars\\' .. fileName;
    cache[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return cache[fileName];
end

return barTextures;
