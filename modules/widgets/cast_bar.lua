local imgui = require('imgui');
local barTextures = require('core.bar_textures');
local textScale = require('core.text_scale');
local anchorControls = require('modules.widgets.anchor_controls');
local uiTooltip = require('core.ui_tooltip');

local castBar = {};
local unpackTable = table.unpack or unpack;
local labelColor = { 0.92, 0.92, 0.90, 1.0 };
local valueColor = { 0.65, 0.90, 1.0, 1.0 };
local actionColor = { 1.0, 0.84, 0.0, 1.0 };
local tableFlags = (_G.ImGuiTableFlags_SizingFixedFit or 0) + (_G.ImGuiTableFlags_BordersInnerH or 0);
local DrawChoice = nil;
local DrawColor = nil;
local DrawBarTextureChoice = nil;
local gridColumnWidth = 125;
local numericFieldWidth = 58;
local comboFieldWidth = 108;
local function DrawSectionHeader(label)
    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.18);
    end

    imgui.TextColored(actionColor, tostring(label or ''));

    if (imgui.SetWindowFontScale ~= nil) then
        imgui.SetWindowFontScale(1.0);
    end
end

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

local function DrawLabeledToggleRow(rowId, toggleLabel, value)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##cast_bar_toggle_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, toggleLabel);
            imgui.TableNextColumn();
            value = DrawToggle('##' .. rowId, value);
            imgui.EndTable();
        end
        return value;
    end

    return DrawToggle(toggleLabel, value);
end

local function DrawNumber(label, value, minValue, maxValue, step)
    local current = tonumber(value) or 0;
    local amount = 1;

    imgui.TextColored(labelColor, label);
    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('-##cast_bar_' .. label .. '_minus') == true) then
        current = current - amount;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { tostring(math.floor(current + 0.5)) };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(70);
        end

        imgui.InputText('##cast_bar_' .. label .. '_input', ref, 16);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        current = tonumber(ref[1]) or current;
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('+##cast_bar_' .. label .. '_plus') == true) then
        current = current + amount;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawNumberControl(id, value, minValue, maxValue)
    local current = tonumber(value) or 0;

    if (imgui.Button ~= nil and imgui.Button('-##cast_bar_' .. id .. '_minus') == true) then
        current = current - 1;
    end

    imgui.SameLine();

    if (imgui.InputText ~= nil) then
        local ref = { tostring(math.floor(current + 0.5)) };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(numericFieldWidth);
        end

        imgui.InputText('##cast_bar_' .. id .. '_input', ref, 16);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        current = tonumber(ref[1]) or current;
    else
        imgui.TextColored(valueColor, tostring(current));
    end

    imgui.SameLine();

    if (imgui.Button ~= nil and imgui.Button('+##cast_bar_' .. id .. '_plus') == true) then
        current = current + 1;
    end

    if (minValue ~= nil and current < minValue) then current = minValue; end
    if (maxValue ~= nil and current > maxValue) then current = maxValue; end

    return current;
end

local function DrawTextInput(id, value, maxLength)
    local current = tostring(value or '');

    if (imgui.InputText ~= nil) then
        local ref = { current };

        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(comboFieldWidth);
        end

        imgui.InputText('##cast_bar_' .. id, ref, tonumber(maxLength) or 64);

        if (imgui.PopItemWidth ~= nil) then
            imgui.PopItemWidth();
        end

        return tostring(ref[1] or current);
    end

    imgui.TextColored(valueColor, current);
    return current;
end

local function DrawPairedNumberRow(rowId, leftLabel, leftId, leftValue, leftMin, leftMax, rightLabel, rightId, rightValue, rightMin, rightMax)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local nextLeft = leftValue;
        local nextRight = rightValue;

        if (imgui.BeginTable('##cast_bar_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, leftLabel);
            imgui.TableNextColumn();
            nextLeft = DrawNumberControl(leftId, leftValue, leftMin, leftMax);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, rightLabel);
            imgui.TableNextColumn();
            nextRight = DrawNumberControl(rightId, rightValue, rightMin, rightMax);
            imgui.EndTable();
        end

        return nextLeft, nextRight;
    end

    local nextLeft = DrawNumber(leftLabel, leftValue, leftMin, leftMax, 1);
    imgui.SameLine();
    local nextRight = DrawNumber(rightLabel, rightValue, rightMin, rightMax, 1);
    return nextLeft, nextRight;
end

local function DrawColorTextureRow(rowId, fillColor, backgroundColor, texture)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local nextFill = fillColor;
        local nextBackground = backgroundColor;
        local nextTexture = texture;

        if (imgui.BeginTable('##cast_bar_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Fill color');
            imgui.TableNextColumn();
            nextFill = DrawColor('##fill_color', fillColor);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'BG color');
            imgui.TableNextColumn();
            nextBackground = DrawColor('##bg_color', backgroundColor);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Texture');
            imgui.TableNextColumn();
            nextTexture = DrawBarTextureChoice(texture, 'texture', comboFieldWidth);

            imgui.EndTable();
        end

        return nextFill, nextBackground, nextTexture;
    end

    return DrawColor('Fill color', fillColor), DrawColor('BG color', backgroundColor), DrawBarTextureChoice(texture, 'texture', comboFieldWidth);
end

local function DrawBorderRow(rowId, borderColor, borderSize)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        local nextBorderColor = borderColor;
        local nextBorderSize = borderSize;

        if (imgui.BeginTable('##cast_bar_' .. rowId, 4, tableFlags)) then
            imgui.TableSetupColumn('##color_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##color_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##size_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##size_control', 0, gridColumnWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Border color');
            imgui.TableNextColumn();
            nextBorderColor = DrawColor('##border_color', borderColor);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Border size');
            imgui.TableNextColumn();
            nextBorderSize = DrawNumberControl('border_size', borderSize, 0, 20);
            imgui.EndTable();
        end

        return nextBorderColor, nextBorderSize;
    end

    return DrawColor('Border color', borderColor), DrawNumber('Border size', borderSize, 0, 20, 1);
end

local function DrawTextSettingsRows(settings, defaults)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##cast_bar_text_settings', 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Font size');
            imgui.TableNextColumn();
            settings.fontSize = DrawNumberControl('font_size', textScale.NormalizeSetting(settings.fontSize, defaults.fontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize());
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Font color');
            imgui.TableNextColumn();
            settings.textColor = DrawColor('##font_color', settings.textColor);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Outline size');
            imgui.TableNextColumn();
            settings.textOutlineSize = DrawNumberControl('outline_size', settings.textOutlineSize, 0, 8);
            settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Outline color');
            imgui.TableNextColumn();
            settings.textOutlineColor = DrawColor('##outline_color', settings.textOutlineColor);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position X');
            imgui.TableNextColumn();
            settings.textOffsetX = DrawNumberControl('text_offset_x', settings.textOffsetX, -400, 400);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position Y');
            imgui.TableNextColumn();
            settings.textOffsetY = DrawNumberControl('text_offset_y', settings.textOffsetY, -400, 400);

            imgui.EndTable();
        end

        return;
    end

    settings.fontSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.fontSize, defaults.fontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.textColor = DrawColor('Font color', settings.textColor);
    settings.textOutlineSize = DrawNumber('Outline size', settings.textOutlineSize, 0, 8, 1);
    settings.textOutlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0;
    settings.textOutlineColor = DrawColor('Outline color', settings.textOutlineColor);
    settings.textOffsetX = DrawNumber('Position X', settings.textOffsetX, -400, 400, 1);
    settings.textOffsetY = DrawNumber('Position Y', settings.textOffsetY, -400, 400, 1);
end

local function DrawInterruptBarSettingsRows(settings, defaults)
    settings.interruptBarEnabled = true;
    settings.interruptColorEnabled = true;
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##cast_bar_interrupt_color', 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);
            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Interrupt bar');
            imgui.TableNextColumn();
            settings.interruptedColor = DrawColor('##interrupt_color', settings.interruptedColor or defaults.interruptedColor);
            imgui.EndTable();
        end
    else
        settings.interruptedColor = DrawColor('Interrupt bar', settings.interruptedColor or defaults.interruptedColor);
    end
end

local function SyncInterruptTextStyle(settings)
    settings.interruptUseSmallFont = settings.useSmallFont == true;
    settings.interruptFontSize = settings.fontSize;
    settings.interruptTextColor = settings.textColor;
    settings.interruptTextOutlineSize = settings.textOutlineSize;
    settings.interruptTextOutlineEnabled = settings.textOutlineEnabled == true;
    settings.interruptTextOutlineColor = settings.textOutlineColor;
end

local function DrawInterruptTextSettingsRows(settings, defaults, compact)
    if (settings.interruptBarEnabled ~= true) then
        return;
    end

    settings.interruptTextEnabled = true;

    if (compact == true) then
        SyncInterruptTextStyle(settings);

        if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
            if (imgui.BeginTable('##cast_bar_interrupt_compact_settings', 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);

                imgui.TableNextRow();
                imgui.TableNextColumn();
                imgui.TextColored(labelColor, 'Interrupt text');
                imgui.TableNextColumn();
                settings.interruptedText = DrawTextInput('interrupt_text', settings.interruptedText or defaults.interruptedText or 'Interrupted', 64);
                imgui.TableNextColumn();
                imgui.TableNextColumn();

                imgui.EndTable();
            end

            return;
        end

        settings.interruptedText = DrawTextInput('interrupt_text', settings.interruptedText or defaults.interruptedText or 'Interrupted', 64);
        return;
    end

    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##cast_bar_interrupt_settings', 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Interrupt text');
            imgui.TableNextColumn();
            settings.interruptedText = DrawTextInput('interrupt_text', settings.interruptedText or defaults.interruptedText or 'Interrupted', 64);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Use small font');
            imgui.TableNextColumn();
            settings.interruptUseSmallFont = DrawToggle('##InterruptUseSmallFont', settings.interruptUseSmallFont == true);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Font size');
            imgui.TableNextColumn();
            settings.interruptFontSize = DrawNumberControl('interrupt_font_size', textScale.NormalizeSetting(settings.interruptFontSize, defaults.interruptFontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize());
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Font color');
            imgui.TableNextColumn();
            settings.interruptTextColor = DrawColor('##interrupt_font_color', settings.interruptTextColor or defaults.interruptTextColor);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Outline size');
            imgui.TableNextColumn();
            settings.interruptTextOutlineSize = DrawNumberControl('interrupt_outline_size', settings.interruptTextOutlineSize, 0, 8);
            settings.interruptTextOutlineEnabled = (tonumber(settings.interruptTextOutlineSize) or 0) > 0;
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Outline color');
            imgui.TableNextColumn();
            settings.interruptTextOutlineColor = DrawColor('##interrupt_outline_color', settings.interruptTextOutlineColor or defaults.interruptTextOutlineColor);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position X');
            imgui.TableNextColumn();
            settings.interruptTextOffsetX = DrawNumberControl('interrupt_text_offset_x', settings.interruptTextOffsetX, -400, 400);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position Y');
            imgui.TableNextColumn();
            settings.interruptTextOffsetY = DrawNumberControl('interrupt_text_offset_y', settings.interruptTextOffsetY, -400, 400);

            imgui.EndTable();
        end
        return;
    end

    settings.interruptedText = DrawTextInput('interrupt_text', settings.interruptedText or defaults.interruptedText or 'Interrupted', 64);
    settings.interruptUseSmallFont = DrawToggle('Use small font', settings.interruptUseSmallFont == true);
    settings.interruptFontSize = DrawNumber('Font size', textScale.NormalizeSetting(settings.interruptFontSize, defaults.interruptFontSize), textScale.GetMinVisualSize(), textScale.GetMaxVisualSize(), 1);
    settings.interruptTextColor = DrawColor('Font color', settings.interruptTextColor or defaults.interruptTextColor);
    settings.interruptTextOutlineSize = DrawNumber('Outline size', settings.interruptTextOutlineSize, 0, 8, 1);
    settings.interruptTextOutlineEnabled = (tonumber(settings.interruptTextOutlineSize) or 0) > 0;
    settings.interruptTextOutlineColor = DrawColor('Outline color', settings.interruptTextOutlineColor or defaults.interruptTextOutlineColor);
    settings.interruptTextOffsetX = DrawNumber('Position X', settings.interruptTextOffsetX, -400, 400, 1);
    settings.interruptTextOffsetY = DrawNumber('Position Y', settings.interruptTextOffsetY, -400, 400, 1);
end

local function DrawSpellIconRows(settings)
    if (imgui.BeginTable ~= nil and imgui.TableSetupColumn ~= nil) then
        if (imgui.BeginTable('##cast_bar_spell_icon_settings', 4, tableFlags)) then
            imgui.TableSetupColumn('##left_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##left_control', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_label', 0, gridColumnWidth);
            imgui.TableSetupColumn('##right_control', 0, gridColumnWidth);

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Icon size');
            imgui.TableNextColumn();
            settings.spellIconSize = DrawNumberControl('spell_icon_size', settings.spellIconSize, 6, 256);
            imgui.TableNextColumn();
            imgui.TableNextColumn();

            imgui.TableNextRow();
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position X');
            imgui.TableNextColumn();
            settings.spellIconOffsetX = DrawNumberControl('spell_icon_offset_x', settings.spellIconOffsetX, -400, 400);
            imgui.TableNextColumn();
            imgui.TextColored(labelColor, 'Position Y');
            imgui.TableNextColumn();
            settings.spellIconOffsetY = DrawNumberControl('spell_icon_offset_y', settings.spellIconOffsetY, -400, 400);

            imgui.EndTable();
        end

        return;
    end

    settings.spellIconSize = DrawNumber('Icon size', settings.spellIconSize, 6, 256, 1);
    settings.spellIconOffsetX = DrawNumber('Position X', settings.spellIconOffsetX, -400, 400, 1);
    settings.spellIconOffsetY = DrawNumber('Position Y', settings.spellIconOffsetY, -400, 400, 1);
end

DrawChoice = function(label, value, options)
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

DrawColor = function(label, color)
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

    if (ClickText('red-', actionColor) == true) then red = math.max(0, red - 1); end
    imgui.SameLine();
    if (ClickText('red+', actionColor) == true) then red = math.min(255, red + 1); end
    imgui.SameLine();
    if (ClickText('green-', actionColor) == true) then green = math.max(0, green - 1); end
    imgui.SameLine();
    if (ClickText('green+', actionColor) == true) then green = math.min(255, green + 1); end
    imgui.SameLine();
    if (ClickText('blue-', actionColor) == true) then blue = math.max(0, blue - 1); end
    imgui.SameLine();
    if (ClickText('blue+', actionColor) == true) then blue = math.min(255, blue + 1); end

    color[1] = red / 255;
    color[2] = green / 255;
    color[3] = blue / 255;

    return color;
end

local function DrawBarTexturePreviewTooltip(style)
    if (imgui.IsItemHovered == nil or imgui.IsItemHovered() ~= true) then
        return;
    end

    local textureId = barTextures.GetTextureId(style);

    if (
        textureId ~= nil and
        imgui.BeginTooltip ~= nil and
        imgui.EndTooltip ~= nil and
        imgui.Image ~= nil
    ) then
        imgui.BeginTooltip();
        imgui.Text(tostring(style or ''));
        imgui.Image(textureId, { 220, 32 }, { 0, 0 }, { 1, 1 });
        imgui.EndTooltip();
    elseif (imgui.SetTooltip ~= nil) then
        imgui.SetTooltip(tostring(style or ''));
    end
end

DrawBarTextureChoice = function(value, id, width)
    local options = barTextures.GetOptions();
    local current = tostring(value or options[1] or 'Solid');
    local currentAllowed = false;

    for _, option in ipairs(options) do
        if (option == current) then
            currentAllowed = true;
            break;
        end
    end

    if (currentAllowed ~= true) then
        current = options[1] or 'Solid';
    end

    if (imgui.BeginCombo ~= nil and imgui.Selectable ~= nil) then
        if (imgui.PushItemWidth ~= nil) then
            imgui.PushItemWidth(width or 170);
        end

        local comboOpen = imgui.BeginCombo('##cast_bar_' .. tostring(id or 'texture'), current) == true;
        DrawBarTexturePreviewTooltip(current);

        if (comboOpen == true) then
            for _, option in ipairs(options) do
                local selected = option == current;

                if (imgui.Selectable(tostring(option), selected) == true) then
                    current = option;
                end
                DrawBarTexturePreviewTooltip(option);

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

    return DrawChoice('Texture', value, options);
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
    local boxed = context ~= nil and context.boxed == true;

    ApplyDefaults(settings, defaults);

    if (context == nil or context.hideActive ~= true) then
        settings.enabled = DrawToggle('Active', settings.enabled);
    end

    if (context == nil or context.skipPlacement ~= true) then
        DrawAnchorControls(settings, context);
    end

    if (context ~= nil and context.onlyPlacement == true) then
        return;
    end

    local function DrawPanel(label, render, first)
        if (boxed == true and _G.LibraPlatesSettingsDrawBoxedPanel ~= nil) then
            _G.LibraPlatesSettingsDrawBoxedPanel(label, render, first);
            return;
        end

        if (first ~= true) then
            imgui.Separator();
        elseif (boxed ~= true) then
            imgui.Separator();
        end

        DrawSectionHeader(label);
        render();
    end

    DrawPanel('Bar Settings', function()
        settings.width, settings.height = DrawPairedNumberRow('size', 'Width', 'width', settings.width, 20, 600, 'Height', 'height', settings.height, 2, 80);
        if (anchorControls.IsCollapsedChild(settings) == true) then
            anchorControls.DrawSpacing(settings, 'cast_bar_position', gridColumnWidth, gridColumnWidth, gridColumnWidth);
        else
            settings.offsetX, settings.offsetY = DrawPairedNumberRow('position', 'Position X', 'offset_x', settings.offsetX, -400, 400, 'Position Y', 'offset_y', settings.offsetY, -400, 400);
        end
        settings.color, settings.backgroundColor, settings.texture = DrawColorTextureRow('colors_texture', settings.color, settings.backgroundColor, settings.texture);
        settings.borderColor, settings.borderSize = DrawBorderRow('border', settings.borderColor, settings.borderSize);
        DrawInterruptBarSettingsRows(settings, defaults);
    end, true);

    DrawPanel('Text Settings', function()
        settings.showSpellName = DrawLabeledToggleRow('show_spell_name', 'Show name', settings.showSpellName ~= false);

        if (settings.showSpellName ~= false) then
            settings.useSmallFont = true;
            DrawTextSettingsRows(settings, defaults);
        end

        DrawInterruptTextSettingsRows(settings, defaults, boxed);
    end);

    DrawPanel('Spell Icon', function()
        settings.showSpellIcon = DrawLabeledToggleRow('show_spell_icon', 'Show icon', settings.showSpellIcon);

        if (settings.showSpellIcon == true) then
            DrawSpellIconRows(settings);
        end
    end);

    if (boxed == true) then
        imgui.Spacing();
        imgui.Spacing();
    else
        imgui.Separator();
    end

    if (DrawActionButton('Reset Cast bar position') == true) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end

    if (DrawActionButton('Reset Cast bar settings') == true) then
        ResetSettings(settings, defaults);
    end
end

return castBar;
