local imgui = require('imgui');
local textScale = require('core.text_scale');

local aoeRange = {};
local defaults = require('config.widgets.aoe_range');
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local headerColor = { 1.0, 0.84, 0.0, 1.0 };
local colorEditFlags = (_G.ImGuiColorEditFlags_NoAlpha or 0) + (_G.ImGuiColorEditFlags_NoInputs or 0);

local function DrawHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(headerColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end

local function DrawCheckbox(label, value)
    if (imgui.Checkbox ~= nil) then
        local ref = { value == true };

        if (imgui.Checkbox(label, ref) == true) then
            return ref[1] == true;
        end

        return ref[1] == true;
    end

    imgui.TextColored(labelColor, label);
    imgui.SameLine();
    imgui.TextColored(valueColor, value == true and 'On' or 'Off');
    return value == true;
end

local function DrawNumberControl(id, value, minValue, maxValue)
    local current = math.floor((tonumber(value) or 0) + 0.5);

    if (imgui.Button ~= nil and imgui.Button('-##aoe_range_' .. id .. '_minus') == true) then
        current = current - 1;
    end

    imgui.SameLine();

    if (imgui.PushItemWidth ~= nil) then
        imgui.PushItemWidth(95);
    end

    if (imgui.InputText ~= nil) then
        local ref = { tostring(current) };

        if (imgui.InputText('##aoe_range_' .. id, ref, 16) == true) then
            current = tonumber(ref[1]) or current;
        end
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    if (imgui.PopItemWidth ~= nil) then
        imgui.PopItemWidth();
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('+##aoe_range_' .. id .. '_plus') == true) then
        current = current + 1;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawColorControl(id, color)
    local current = color or { 1.0, 1.0, 1.0, 1.0 };

    if (imgui.ColorEdit4 ~= nil) then
        imgui.ColorEdit4('##aoe_range_' .. tostring(id), current, colorEditFlags);
    else
        imgui.TextColored(valueColor, 'color');
    end

    return current;
end

function aoeRange.DrawSettings(settings)
    if (settings == nil) then
        return;
    end

    if (settings.enabled == nil) then settings.enabled = defaults.enabled; end
    if (settings.fontSize == nil) then settings.fontSize = defaults.fontSize; end
    if (settings.fontColor == nil) then settings.fontColor = defaults.fontColor; end
    if (settings.iconEnabled == nil) then settings.iconEnabled = defaults.iconEnabled; end
    if (settings.iconSize == nil) then settings.iconSize = defaults.iconSize; end
    if (settings.iconOffsetX == nil) then settings.iconOffsetX = defaults.iconOffsetX; end
    if (settings.iconOffsetY == nil) then settings.iconOffsetY = defaults.iconOffsetY; end
    if (settings.iconAnchorTo == nil) then settings.iconAnchorTo = defaults.iconAnchorTo; end
    if (settings.iconAnchorPoint == nil) then settings.iconAnchorPoint = defaults.iconAnchorPoint; end

    DrawHeader('AOE range');
    settings.enabled = DrawCheckbox('Use AOE name style', settings.enabled);

    if (settings.enabled ~= true) then
        return;
    end

    imgui.TextColored(labelColor, 'Font size');
    imgui.SameLine();
    settings.fontSize = DrawNumberControl('font_size', settings.fontSize, textScale.GetMinVisualSize(), 40);

    imgui.SameLine();
    imgui.TextColored(labelColor, 'Font color');
    imgui.SameLine();
    settings.fontColor = DrawColorControl('font_color', settings.fontColor);

    DrawHeader('Icon');
    settings.iconEnabled = DrawCheckbox('Show icon', settings.iconEnabled);
    if (settings.iconEnabled == true) then
        imgui.SameLine();
        imgui.TextColored(labelColor, 'Icon size');
        imgui.SameLine();
        settings.iconSize = DrawNumberControl('icon_size', settings.iconSize, 4, 128);

        imgui.TextColored(labelColor, 'Position X');
        imgui.SameLine();
        settings.iconOffsetX = DrawNumberControl('icon_x', settings.iconOffsetX, -500, 500);

        imgui.SameLine();
        imgui.TextColored(labelColor, 'Position Y');
        imgui.SameLine();
        settings.iconOffsetY = DrawNumberControl('icon_y', settings.iconOffsetY, -500, 500);
    end

end

return aoeRange;
