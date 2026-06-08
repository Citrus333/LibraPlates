local imgui = require('imgui');
local barTextures = require('core.bar_textures');
local textScale = require('core.text_scale');
local anchorControls = require('modules.widgets.anchor_controls');

local castBar = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };

local function ClickText(label, color)
    imgui.TextColored(color or valueColor, label);

    if (imgui.IsItemClicked ~= nil and imgui.IsItemClicked(0) == true) then
        return true;
    end

    if (imgui.IsItemActive ~= nil and imgui.IsItemActive() == true) then
        if (imgui.IsMouseDown == nil or imgui.IsMouseDown(0) == true) then
            return true;
        end
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
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return ref[1] == true;
    end

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

    if (imgui.SliderInt ~= nil) then
        local ref = { math.floor(current + 0.5) };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        imgui.SliderInt(label, ref, minValue or -1000, maxValue or 1000);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        current = tonumber(ref[1]) or current;

        if (step ~= nil and step > 1) then
            current = math.floor((current / amount) + 0.5) * amount;
        end

        return math.max(minValue or current, math.min(maxValue or current, current));
    end

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

local function DrawChoice(label, value, options)
    local current = tostring(value or options[1]);

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo(label, current) == true) then
            for _, option in ipairs(options) do
                local selected = option == current;

                if (imgui.Selectable(tostring(option), selected) == true) then
                    current = option;
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

        return current;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (ClickText(current, valueColor) ~= true) then
        return current;
    end

    for index, option in ipairs(options) do
        if (option == current) then
            return options[(index % #options) + 1];
        end
    end

    return options[1];
end

local function DrawAnchorCombo(label, current, choices)
    local value = tostring(current or 'Plate');

    if (value == 'Plate') then
        value = 'None';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(230);
        end

        if (imgui.BeginCombo('##cast_bar_anchor_' .. label, value) == true) then
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
        imgui.TextColored(labelColor, label);
        imgui.SameLine();
        imgui.TextColored(valueColor, value);
    end

    if (value == 'None') then
        return 'Plate';
    end

    return value;
end

local function DrawAnchorControls(settings, context)
    anchorControls.Draw(settings, context, 'Cast bar');
end

local function ClampColorChannel(value)
    value = tonumber(value) or 0;
    if (value < 0) then return 0; end
    if (value > 1) then return 1; end
    return value;
end

local function DrawColor(label, color)
    color = color or { 1.0, 1.0, 1.0, 1.0 };
    color[4] = tonumber(color[4]) or 1.0;

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4(label, color, (_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0));
        return color;
    end

    local red = math.floor(ClampColorChannel(color[1]) * 255);
    local green = math.floor(ClampColorChannel(color[2]) * 255);
    local blue = math.floor(ClampColorChannel(color[3]) * 255);

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

    return color;
end

local function ApplyDefaults(settings, defaults)
    for key, value in pairs(defaults or {}) do
        if (settings[key] == nil) then
            settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
        end
    end
end

local function ResetSettings(settings, defaults)
    for key, value in pairs(defaults or {}) do
        settings[key] = type(value) == 'table' and { unpackTable(value) } or value;
    end
end

function castBar.DrawSettings(settings, context)
    if (settings == nil) then
        return;
    end

    local defaults = context ~= nil and context.defaults or {};

    ApplyDefaults(settings, defaults);

    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Cast bar settings');
    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end
    DrawAnchorControls(settings, context);
    settings.width = DrawNumber('Width', settings.width, 20, 600, 5);
    settings.height = DrawNumber('Height', settings.height, 2, 80, 1);
    settings.texture = DrawChoice('Texture', settings.texture, barTextures.GetOptions());
    settings.offsetX = DrawNumber('Position X', settings.offsetX, -400, 400, 5);
    settings.offsetY = DrawNumber('Position Y', settings.offsetY, -400, 400, 5);
    settings.color = DrawColor('Bar color', settings.color);
    settings.backgroundColor = DrawColor('Background color', settings.backgroundColor);
    settings.borderSize = DrawNumber('Border size', settings.borderSize, 0, 20, 1);

    if ((tonumber(settings.borderSize) or 0) > 0) then
        settings.borderColor = DrawColor('Border color', settings.borderColor);
    end

    imgui.Separator();
    imgui.TextColored({ 1.0, 0.84, 0.0, 1.0 }, 'Spell name');
    settings.showSpellName = DrawToggle('Show spell name', settings.showSpellName ~= false);
    settings.textOffsetX = DrawNumber('Spell name X', settings.textOffsetX, -400, 400, 5);
    settings.textOffsetY = DrawNumber('Spell name Y', settings.textOffsetY, -400, 400, 5);
    settings.useSmallFont = DrawToggle('Use small font', settings.useSmallFont);
    settings.fontSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.fontSize, defaults.fontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.textColor = DrawColor('Font color', settings.textColor);
    settings.textOutlineEnabled = DrawToggle('Text outline', settings.textOutlineEnabled);

    if (settings.textOutlineEnabled == true) then
        settings.textOutlineSize = DrawNumber('Outline size', settings.textOutlineSize, 0, 8, 1);
        settings.textOutlineColor = DrawColor('Outline color', settings.textOutlineColor);
    end

    imgui.Separator();

    if (DrawActionButton('Reset Cast bar position') == true) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end

    if (DrawActionButton('Reset Cast bar settings') == true) then
        ResetSettings(settings, defaults);
    end
end

return castBar;
