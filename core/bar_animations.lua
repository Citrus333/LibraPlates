local textureLoader = require('core.texture_loader');

local barAnimations = {};
local options = T{
    'Important',
    'Pandemic',
};
local files = {
    Important = 'important.png',
    Pandemic = 'pandemic.png',
};
local cache = {};

function barAnimations.GetOptions()
    return options;
end

function barAnimations.GetTextureId(style)
    local fileName = files[tostring(style or 'Important')];

    if (fileName == nil) then
        return nil;
    end

    if (cache[fileName] ~= nil) then
        return cache[fileName];
    end

    cache[fileName] = textureLoader.ToTextureId(textureLoader.Load(
        addon.path .. '\\assets\\images\\widget-bars\\animations\\' .. fileName
    ));

    return cache[fileName];
end

return barAnimations;
