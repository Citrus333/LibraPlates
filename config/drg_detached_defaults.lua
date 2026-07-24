local defaults = {
    enabled = true,
    width = 500,
    height = 229,
    offsetX = 0,
    offsetY = 0,
    texture = 'None',
    drgArtworkOpacity = 100,
    color = { 0.0, 0.0, 0.0, 0.0 },
    borderColor = { 0.0, 0.0, 0.0, 0.0 },
    borderSize = 0,
};

local function Copy(value)
    if type(value) ~= 'table' then
        return value;
    end

    local result = {};
    for key, child in pairs(value) do
        result[key] = Copy(child);
    end
    return result;
end

return {
    Get = function()
        return Copy(defaults);
    end,
};
