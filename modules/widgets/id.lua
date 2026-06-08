local imgui = require('imgui');
local defaults = require('config.widgets.id');
local textScale = require('core.text_scale');
local anchorControls = require('modules.widgets.anchor_controls');

local id = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemHovered ~= nil and imgui.IsMouseDown ~= nil) then
        return imgui.IsItemHovered() == true and imgui.IsMouseDown(0) == true;
    end

    return false;
end

local function DrawActionButton(label)
    if (imgui.Button ~= nil) then
        return imgui.Button(tostring(label)) == true;
    end

    return ClickText(tostring(label), { 1.0, 0.84, 0.0, 1.0 }) == true;
end

local function DrawToggle(label, value)
    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText((value == true) and 'On' or 'Off', valueColor) == true) then
        return not (value == true);
    end

    return value == true;
end

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = tonumber(step) or 1;

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(current));
    imgui.SameLine();

    if (ClickText('less', actionColor) == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (ClickText('more', actionColor) == true) then
        current = current + amount;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function ClampChannel(value)
    value = tonumber(value) or 0;
    if (value < 0) then return 0; end
    if (value > 1) then return 1; end
    return value;
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(ClampChannel(color[1]) * 255);
    local green = math.floor(ClampChannel(color[2]) * 255);
    local blue = math.floor(ClampChannel(color[3]) * 255);

    imgui.TextColored(color, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, tostring(red) .. '/' .. tostring(green) .. '/' .. tostring(blue));
    imgui.SameLine();

    if (ClickText('red-', actionColor) == true) then red = math.max(0, red - 5); end
    imgui.SameLine();
    if (ClickText('red+', actionColor) == true) then red = math.min(255, red + 5); end
    imgui.SameLine();
    if (ClickText('green-', actionColor) == true) then green = math.max(0, green - 5); end
    imgui.SameLine();
    if (ClickText('green+', actionColor) == true) then green = math.min(255, green + 5); end
    imgui.SameLine();
    if (ClickText('blue-', actionColor) == true) then blue = math.max(0, blue - 5); end
    imgui.SameLine();
    if (ClickText('blue+', actionColor) == true) then blue = math.min(255, blue + 5); end

    color[1] = red / 255;
    color[2] = green / 255;
    color[3] = blue / 255;
    color[4] = tonumber(color[4]) or 1.0;

    return color;
end

local function DrawAnchorCombo(idValue, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##id_anchor_' .. tostring(idValue), value) == true) then
            for _, choice in ipairs(choices or {}) do
                local selected = value == tostring(choice);

                if (imgui.Selectable(tostring(choice), selected) == true) then
                    value = tostring(choice);
                end

                if (selected == true and imgui.SetItemDefaultFocus ~= nil) then
                    imgui.SetItemDefaultFocus();
                end
            end

            imgui.EndCombo();
        end

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end
    else
        imgui.TextColored(valueColor, value);
    end

    if (value == 'None') then
        return 'Plate';
    end

    return value;
end

local function DrawAnchorControls(settings, context)
    anchorControls.Draw(settings, context, 'ID');
end

local function ApplyDefaults(settings)
    for key, value in pairs(defaults) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function Reset(settings)
    for key, value in pairs(defaults) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

function id.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    ApplyDefaults(settings);

    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'ID settings');
    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end
    DrawAnchorControls(settings, context);
    settings.offsetX = DrawNumber('Position X', settings.offsetX, -400, 400, 5);
    settings.offsetY = DrawNumber('Position Y', settings.offsetY, -400, 400, 5);
    settings.textSize = DrawNumber('Text size', textScale.NormalizeSetting(settings.textSize, defaults.textSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.useSmallFont = DrawToggle('Use small font', settings.useSmallFont);
    settings.color = DrawColor('Text color', settings.color);
    settings.outlineEnabled = DrawToggle('Text outline', settings.outlineEnabled);

    if (settings.outlineEnabled == true) then
        settings.outlineSize = DrawNumber('Outline size', settings.outlineSize, 0, 8, 1);
        settings.outlineColor = DrawColor('Outline color', settings.outlineColor);
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'ID box');
    settings.boxEnabled = DrawToggle('Box', settings.boxEnabled);

    if (settings.boxEnabled == true) then
        settings.boxBackgroundColor = DrawColor('Box color', settings.boxBackgroundColor);
        settings.boxDifficultyColorsEnabled = DrawToggle('Use difficulty box colors', settings.boxDifficultyColorsEnabled);

        if (settings.boxDifficultyColorsEnabled == true) then
            settings.boxTwColor = DrawColor('TW box', settings.boxTwColor);
            settings.boxEpColor = DrawColor('EP box', settings.boxEpColor);
            settings.boxDcColor = DrawColor('DC box', settings.boxDcColor);
            settings.boxEmColor = DrawColor('EM box', settings.boxEmColor);
            settings.boxTColor = DrawColor('T box', settings.boxTColor);
            settings.boxVtColor = DrawColor('VT box', settings.boxVtColor);
            settings.boxItColor = DrawColor('IT box', settings.boxItColor);
        end

        settings.boxSize = DrawNumber('Box size', settings.boxSize, 4, 160, 1);
        settings.cornerRadius = DrawNumber('Corner radius', settings.cornerRadius, 0, 40, 1);
        settings.boxBorderSize = DrawNumber('Border size', settings.boxBorderSize, 0, 20, 1);

        if ((tonumber(settings.boxBorderSize) or 0) > 0) then
            settings.boxBorderColor = DrawColor('Border color', settings.boxBorderColor);
        end
    end

    imgui.Separator();

    if (DrawActionButton('Reset ID position') == true) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end

    if (DrawActionButton('Reset ID settings') == true) then
        Reset(settings);
    end
end

return id;
