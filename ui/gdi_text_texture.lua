-- ==========================================================
-- = DEPENDENCIES =
-- ==========================================================

local ffi = require('ffi');
local gdiText = require('ui.gdi_text');

-- ==========================================================
-- = GDI TEXT TEXTURE MODULE =
-- ==========================================================

local gdiTextTexture = {};

-- ==========================================================
-- = MODULE STATE =
-- ==========================================================

local objects = {};
local objectOrder = {};
local objectCount = 0;
local maxObjects = 256;

-- ==========================================================
-- = CACHE HELPERS =
-- ==========================================================

local function TouchKey(key)
    for i = #objectOrder, 1, -1 do
        if (objectOrder[i] == key) then
            table.remove(objectOrder, i);
            break;
        end
    end

    table.insert(objectOrder, key);
end

local function DestroyEntry(key)
    local entry = objects[key];

    if (entry == nil) then
        return;
    end

    local renderer = gdiText.GetGdi();

    if (renderer ~= nil and renderer.destroy_object ~= nil and entry.object ~= nil) then
        pcall(function ()
            renderer:destroy_object(entry.object);
        end);
    elseif (entry.object ~= nil and entry.object.set_visible ~= nil) then
        pcall(function ()
            entry.object:set_visible(false);
        end);
    end

    objects[key] = nil;
    objectCount = math.max(0, objectCount - 1);
end

local function TrimCache()
    while (objectCount > maxObjects and #objectOrder > 0) do
        local oldestKey = table.remove(objectOrder, 1);
        DestroyEntry(oldestKey);
    end
end

-- ==========================================================
-- = VALUE HELPERS =
-- ==========================================================

local function GetValue(value, fallback)
    if (type(value) == 'table') then
        value = value[1];
    end

    if (value == nil) then
        return fallback;
    end

    return value;
end

local function ClampColorChannel(value)
    value = tonumber(value) or 0;

    if (value <= 1) then
        value = value * 255;
    end

    return math.max(0, math.min(255, math.floor(value + 0.5)));
end

local function ToArgb(color, fallback)
    color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    if (type(color) == 'number') then
        return color;
    end

    local r = ClampColorChannel(color[1] or 1);
    local g = ClampColorChannel(color[2] or 1);
    local b = ClampColorChannel(color[3] or 1);
    local a = ClampColorChannel(color[4] or 1);

    return (a * 0x1000000) + (r * 0x10000) + (g * 0x100) + b;
end

local function BuildKey(text, options)
    return table.concat({
        tostring(text or ''),
        tostring(GetValue(options.fontFamily, 'Tahoma')),
        tostring(GetValue(options.fontSize, 12)),
        tostring(GetValue(options.fontFlags, 0)),
        tostring(ToArgb(options.color, { 1.0, 1.0, 1.0, 1.0 })),
        tostring(ToArgb(options.outlineColor, { 0.0, 0.0, 0.0, 1.0 })),
        tostring(GetValue(options.outlineEnabled, false) == true and GetValue(options.outlineSize, 1) or 0),
    }, '|');
end

-- ==========================================================
-- = TEXTURE HELPERS =
-- ==========================================================

local function GetObject(text, options)
    text = tostring(text or '');

    if (text == '') then
        return nil;
    end

    options = options or {};

    local key = BuildKey(text, options);
    local entry = objects[key];

    if (entry ~= nil) then
        TouchKey(key);
        return entry;
    end

    local renderer = gdiText.GetGdi();

    if (renderer == nil or renderer.create_object == nil) then
        return nil;
    end

    local ok, object = pcall(function ()
        return renderer:create_object({
            font_family = tostring(GetValue(options.fontFamily, 'Tahoma') or 'Tahoma'),
            font_alignment = 0,
            font_height = tonumber(GetValue(options.fontSize, 12)) or 12,
            font_flags = tonumber(GetValue(options.fontFlags, 0)) or 0,
            font_color = ToArgb(options.color, { 1.0, 1.0, 1.0, 1.0 }),
            outline_color = ToArgb(options.outlineColor, { 0.0, 0.0, 0.0, 1.0 }),
            outline_width = (GetValue(options.outlineEnabled, false) == true) and (tonumber(GetValue(options.outlineSize, 1)) or 1) or 0,
            text = text,
            visible = false,
            z_order = 0,
        });
    end);

    if (ok ~= true or object == nil) then
        return nil;
    end

    entry = {
        object = object,
        texture = nil,
        width = 0,
        height = 0,
    };
    objects[key] = entry;
    objectCount = objectCount + 1;
    TouchKey(key);
    TrimCache();

    return entry;
end

function gdiTextTexture.GetTexture(text, options)
    options = options or {};

    local entry = GetObject(text, options);

    if (entry == nil or entry.object == nil or entry.object.get_texture == nil) then
        if (tostring(GetValue(options.fontFamily, 'Tahoma')) ~= 'Arial' and options.disableFallback ~= true) then
            local fallbackOptions = {};

            for key, value in pairs(options) do
                fallbackOptions[key] = value;
            end

            fallbackOptions.fontFamily = 'Arial';
            fallbackOptions.disableFallback = true;

            return gdiTextTexture.GetTexture(text, fallbackOptions);
        end

        return nil, 0, 0;
    end

    if (entry.texture ~= nil and entry.width > 0 and entry.height > 0) then
        return tonumber(ffi.cast('uint32_t', entry.texture)), entry.width, entry.height;
    end

    local ok, texture, rect = pcall(function ()
        return entry.object:get_texture();
    end);

    if (ok ~= true or texture == nil or rect == nil) then
        if (tostring(GetValue(options.fontFamily, 'Tahoma')) ~= 'Arial' and options.disableFallback ~= true) then
            DestroyEntry(BuildKey(text, options));

            local fallbackOptions = {};

            for key, value in pairs(options) do
                fallbackOptions[key] = value;
            end

            fallbackOptions.fontFamily = 'Arial';
            fallbackOptions.disableFallback = true;

            return gdiTextTexture.GetTexture(text, fallbackOptions);
        end

        return nil, 0, 0;
    end

    entry.texture = texture;
    entry.width = tonumber(rect.right - rect.left) or 0;
    entry.height = tonumber(rect.bottom - rect.top) or 0;

    if ((entry.width <= 0 or entry.height <= 0) and tostring(GetValue(options.fontFamily, 'Tahoma')) ~= 'Arial' and options.disableFallback ~= true) then
        DestroyEntry(BuildKey(text, options));

        local fallbackOptions = {};

        for key, value in pairs(options) do
            fallbackOptions[key] = value;
        end

        fallbackOptions.fontFamily = 'Arial';
        fallbackOptions.disableFallback = true;

        return gdiTextTexture.GetTexture(text, fallbackOptions);
    end

    return tonumber(ffi.cast('uint32_t', texture)), entry.width, entry.height;
end

function gdiTextTexture.GetCacheStats()
    return objectCount, maxObjects;
end

function gdiTextTexture.Clear()
    local keys = {};

    for key, _ in pairs(objects) do
        table.insert(keys, key);
    end

    for _, key in ipairs(keys) do
        DestroyEntry(key);
    end

    objectOrder = {};
    objectCount = 0;
end

return gdiTextTexture;
