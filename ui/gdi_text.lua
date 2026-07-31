-- ==========================================================
-- = DEPENDENCIES =
-- ==========================================================

-- No external dependencies are loaded at file load time.
-- The GDI font renderer is required lazily so the addon can fall back safely.

-- ==========================================================
-- = GDI TEXT MODULE =
-- ==========================================================

local gdiText = {};

-- ==========================================================
-- = MODULE STATE =
-- ==========================================================

local gdi = nil;
local gdiLoadAttempted = false;
local frameId = 0;
local objects = {};

-- ==========================================================
-- = GDI LOADING =
-- ==========================================================

local function GetGdi()
    if (gdiLoadAttempted == true) then
        return gdi;
    end

    gdiLoadAttempted = true;

    local ok, result = pcall(function ()
        return require('submodules.gdifonts.include');
    end);

    if (ok ~= true or result == nil) then
        print('[LibraPlates] GDI text renderer failed to load.');
        return nil;
    end

    gdi = result;

    if (gdi.set_auto_render ~= nil) then
        pcall(function ()
            gdi:set_auto_render(true);
        end);
    end

    return gdi;
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

-- ==========================================================
-- = OBJECT HELPERS =
-- ==========================================================

local function GetObject(key, settings)
    key = tostring(key or '');

    if (key == '') then
        return nil;
    end

    local entry = objects[key];

    if (entry ~= nil and entry.object ~= nil) then
        return entry;
    end

    local renderer = GetGdi();

    if (renderer == nil or renderer.create_object == nil) then
        return nil;
    end

    local ok, object = pcall(function ()
        return renderer:create_object(settings);
    end);

    if (ok ~= true or object == nil) then
        print('[LibraPlates] GDI text renderer could not create a text object.');
        return nil;
    end

    entry = {
        object = object,
        lastFrame = frameId,
    };
    objects[key] = entry;

    return entry;
end

local function SetIfAvailable(object, methodName, value)
    if (object ~= nil and object[methodName] ~= nil) then
        pcall(function ()
            object[methodName](object, value);
        end);
    end
end

-- ==========================================================
-- = FRAME LIFECYCLE =
-- ==========================================================

function gdiText.BeginFrame()
    frameId = frameId + 1;
end

function gdiText.EndFrame()
    for _, entry in pairs(objects) do
        if (
            entry ~= nil and
            entry.object ~= nil and
            entry.lastFrame ~= frameId and
            entry.object.set_visible ~= nil
        ) then
            pcall(function ()
                entry.object:set_visible(false);
            end);
        end
    end
end

-- ==========================================================
-- = TEXT DRAWING =
-- ==========================================================

function gdiText.DrawCenteredText(text, options)
    text = tostring(text or '');

    if (text == '') then
        return false;
    end

    options = options or {};

    local fontSize = tonumber(GetValue(options.fontSize, 12)) or 12;
    local outlineEnabled = (GetValue(options.outlineEnabled, false) == true);
    local outlineSize = tonumber(GetValue(options.outlineSize, 1)) or 1;
    local outlineWidth = outlineEnabled and outlineSize or 0;
    local fontFamily = tostring(GetValue(options.fontFamily, 'Tahoma') or 'Tahoma');
    local color = ToArgb(options.color, { 1.0, 1.0, 1.0, 1.0 });
    local outlineColor = ToArgb(options.outlineColor, { 0.0, 0.0, 0.0, 1.0 });
    local key = tostring(options.key or text);

    local alignment = tonumber(options.alignment) or 0;

    local entry = GetObject(key, {
        font_family = fontFamily,
        font_alignment = alignment,
        font_height = fontSize,
        font_color = color,
        outline_color = outlineColor,
        outline_width = outlineWidth,
        text = text,
        visible = false,
        z_order = tonumber(options.zOrder) or 9000,
    });

    if (entry == nil or entry.object == nil) then
        return false;
    end

    local object = entry.object;

    pcall(function ()
        SetIfAvailable(object, 'set_text', text);
        SetIfAvailable(object, 'set_font_family', fontFamily);
        SetIfAvailable(object, 'set_font_alignment', alignment);
        SetIfAvailable(object, 'set_font_height', fontSize);
        SetIfAvailable(object, 'set_font_color', color);
        SetIfAvailable(object, 'set_outline_color', outlineColor);
        SetIfAvailable(object, 'set_outline_width', outlineWidth);
        SetIfAvailable(object, 'set_z_order', tonumber(options.zOrder) or 9000);
    end);

    local width = 0;
    local height = fontSize;

    if (object.get_text_size ~= nil) then
        pcall(function ()
            width, height = object:get_text_size();
        end);
    end

    local x = tonumber(options.screenX);
    local y = tonumber(options.screenY);

    if (x == nil) then
        x = (tonumber(options.screenCenterX) or 0) - math.floor((tonumber(width) or 0) / 2);
    end

    if (y == nil) then
        y = (tonumber(options.screenCenterY) or 0) - math.floor((tonumber(height) or fontSize) / 2);
    end

    SetIfAvailable(object, 'set_position_x', x);
    SetIfAvailable(object, 'set_position_y', y);
    SetIfAvailable(object, 'set_visible', true);

    entry.lastFrame = frameId;

    return true, width, height;
end

-- ==========================================================
-- = OBJECT VISIBILITY =
-- ==========================================================

function gdiText.Hide(key)
    local entry = objects[tostring(key or '')];

    if (entry ~= nil and entry.object ~= nil and entry.object.set_visible ~= nil) then
        pcall(function ()
            entry.object:set_visible(false);
        end);
    end
end

function gdiText.Destroy(key)
    local entry = objects[tostring(key or '')];

    if (entry == nil or entry.object == nil) then
        return;
    end

    if (gdi ~= nil and gdi.destroy_object ~= nil) then
        pcall(function ()
            gdi:destroy_object(entry.object);
        end);
    elseif (entry.object.set_visible ~= nil) then
        pcall(function ()
            entry.object:set_visible(false);
        end);
    end

    objects[tostring(key or '')] = nil;
end

-- ==========================================================
-- = CLEANUP =
-- ==========================================================

function gdiText.Shutdown()
    local keys = {};

    for key, _ in pairs(objects) do
        table.insert(keys, key);
    end

    for _, key in ipairs(keys) do
        gdiText.Destroy(key);
    end

    if (gdi ~= nil and gdi.set_auto_render ~= nil) then
        pcall(function ()
            gdi:set_auto_render(false);
        end);
    end

    objects = {};
    frameId = 0;
    gdi = nil;
    gdiLoadAttempted = false;
end

gdiText.GetGdi = GetGdi;

return gdiText;
